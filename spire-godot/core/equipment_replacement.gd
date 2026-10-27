extends RefCounted
const Assess=preload("res://core/equipment_replacement_assess.gd")

# Game-internal, synchronous atomic group. The caller owns permission, costs,
# ready-stack consumption, action feedback and the enclosing version increment.
# Never persist a plan or expose its snapshots as a player command.
static func plan(g, requests: Array, source: String, protected_ids: Array=[]) -> Dictionary:
 var original=g.state
 var feedback=g._resource_feedback
 g._resource_feedback=null
 g.state=original.duplicate(true)
 var result=_plan(g,requests,source,protected_ids)
 # Factories can displace equipment without explicit removal units in a direct plan.
 if result.ok and (result.removed+result.lost_links).any(func(id):return id in protected_ids):
  result=_fail("本次不能替换刚安装的装备或附属件。")
 g.state=original
 g._resource_feedback=feedback
 result.expectedVersion=original.version
 if result.ok:
  result.requests=result.requests.duplicate(true)
  result.source=source
  result.protected_ids=protected_ids.duplicate()
  result._before=original.duplicate(true)
 return result

static func execute(g, prepared: Dictionary) -> Dictionary:
 if not prepared.get("ok",false): return _fail(prepared.get("reason","替换方案没有通过检查。"))
 if prepared.get("expectedVersion",-1)!=g.state.version or prepared.get("_before",{})!=g.state:
  return _fail("装备或行动状态已更新，需要重新检查替换方案。")
 if not prepared.get("requests") is Array or not prepared.get("source") is String:
  return _fail("替换方案缺少安装规格或来源。")
 # Recompute rather than trusting a mutable preview or a caller-supplied state.
 var fresh=plan(g,prepared.requests,prepared.source,prepared.get("protected_ids",[]))
 if not fresh.ok: return _fail(fresh.reason)
 for key in ["_after","removed","installed","lost_links","comparisons"]:
  if fresh.get(key)!=prepared.get(key): return _fail("替换方案的预演结果已改变，需要重新检查。")
 _commit_changes(g,fresh._after)
 return {"ok":true,"reason":"","removed":fresh.removed.duplicate(),"installed":fresh.installed.duplicate(true),"lost_links":fresh.lost_links.duplicate(),"comparisons":fresh.comparisons.duplicate(true)}

# Some captures explicitly replace every removable special item covered by one
# prescribed device. This remains a replacement transaction: cursed items are
# an absolute boundary, cleanup owns dependent pieces and links, and the normal
# special factory owns the incoming item.
static func force_special(g, type: String, tier: int, source: String) -> Dictionary:
 if not g.SpecialEquipment.DESIGNS.has(type) or tier not in [1,2,3]: return _fail("指定的特殊装备不合法。")
 var original=g.state
 var feedback=g._resource_feedback
 g._resource_feedback=null
 g.state=original.duplicate(true)
 var result=_force_special_live(g,type,tier,source)
 var after=g.state.duplicate(true) if result.ok else {}
 g.state=original
 g._resource_feedback=feedback
 if not result.ok: return result
 _commit_changes(g,after)
 return result

# Both replacement policies commit only changed fields. Keep unchanged enclosing
# enemy/event references alive and never expose trial containers as authority.
static func _commit_changes(g, after: Dictionary) -> void:
 for key in after:
  if g.state.get(key)!=after[key]:
   var value=after[key]
   g.state[key]=value.duplicate(true) if value is Array or value is Dictionary else value

static func _force_special_live(g, type: String, tier: int, source: String) -> Dictionary:
 var coverage=g.SpecialEquipment.DESIGNS[type].slots
 var blocking=g.state.special_equipment.filter(func(item):return not g.SpecialEquipment.is_reinforcement(item) and g.SpecialEquipment.occupied_slots(item).any(func(slot):return slot in coverage))
 if blocking.any(g.SpecialEquipment.is_cursed_plate): return _fail(g.SpecialEquipment.CURSED_PLATE_REASON)
 var old_targets=g.action_targets().duplicate(true)
 for item in blocking:
  item.durability=0.0
 if not blocking.is_empty(): g._cleanup(false)
 var installed=g._install_special(type,coverage[0],tier)
 if installed.is_empty(): return _fail("清理可替换装备后仍无法佩戴指定装备。")
 if g.SpecialEquipment.validate(g.state.special_equipment)!="" or g._capacity_issue(g.physical_pieces())!="": return _fail("替换后的特殊装备结构不合法。")
 var live=g.action_targets().map(func(item):return item.id)
 var removed=old_targets.filter(func(item):return item.id not in live and item.template!="link_rope").map(func(item):return item.id)
 var lost_links=old_targets.filter(func(item):return item.id not in live and item.template=="link_rope").map(func(item):return item.id)
 return {"ok":true,"reason":"","removed":removed,"installed":[installed],"lost_links":lost_links,"comparisons":[]}

static func _fail(reason: String) -> Dictionary:
 return {"ok":false,"reason":reason,"removed":[],"installed":[],"lost_links":[],"comparisons":[]}

static func _install(g, r: Dictionary, source: String) -> Dictionary:
 match r.kind:
  "install":
   var maximum=g.Equipment.maximum(r.grade)
   return g._install_template(r.template,r.slot,maximum*[0.0,0.4,0.8,1.0][r.tier],maximum,r.locked,source,r.grade,r.get("layer",-1),r.variant,r.point)
  "assembly": return g._install_assembly(r.family,r.variant,source,r.grade,r.tier,r.parts,r.straps,r.get("attached_to",""))
  "special_install": return g._install_special(r.type,r.slot,r.get("tier",0))
 return {}

static func _loadout_records(snapshot: Dictionary) -> Array:
 var records=[]
 for item in snapshot.equipment+snapshot.special_equipment+snapshot.links+snapshot.composites:
  var record=item.duplicate(true)
  records.append_array(record.get("components",[]))
  record.erase("components")
  if record.get("binding",{}).has("id"):
   records.append(record.binding)
   record.binding={"kind":record.binding.kind}
  if record.has("shoulders"):
   records.append_array(record.shoulders.pieces)
   record.shoulders.erase("pieces")
   record.shoulders.erase("source")
  records.append(record)
 return records

static func _record_facts(record: Dictionary) -> Dictionary:
 var facts=record.duplicate(true)
 # Identity and provenance alone do not make a fresh copy different equipment.
 for key in ["id","source","root_id","parent_id","shoulder_host","attached_to","ends"]: facts.erase(key)
 return facts

static func _same_loadout(before: Dictionary, after: Dictionary) -> bool:
 var old_records=_loadout_records(before)
 var new_records=_loadout_records(after)
 if old_records.size()!=new_records.size(): return false
 var unmatched=old_records.duplicate()
 var identity={}
 for record in new_records:
  var facts=_record_facts(record)
  var index=unmatched.find_custom(func(old):return _record_facts(old)==facts)
  if index<0: return false
  identity[record.id]=unmatched[index].id
  unmatched.remove_at(index)
 # Keep the complete attachment/link graph, normalizing only regenerated IDs.
 var expected=old_records.duplicate(true)
 for record in expected: record.erase("source")
 for record in new_records:
  record.erase("source")
  for key in ["id","root_id","parent_id","shoulder_host","attached_to"]:
   if record.has(key): record[key]=identity.get(record[key],record[key])
  if record.has("ends"): record.ends=record.ends.map(func(id):return identity.get(id,id))
  var index=expected.find(record)
  if index<0: return false
  expected.remove_at(index)
 return true

static func _plan(g, requests: Array, source: String, protected_ids: Array) -> Dictionary:
 var normalized=Assess.normalize(g,requests)
 if not normalized.ok: return normalized
 var specs=normalized.requests
 var before=g.state.duplicate(true)
 var mandatory=[]
 var mandatory_ids=[]
 for request in specs:
  if request.kind!="special_install": continue
  var family=g.SpecialEquipment.exclusive_family(request.type)
  for item in before.special_equipment:
   if g.SpecialEquipment.exclusive_family(item.type)!=family or item.id in mandatory_ids: continue
   if g.cursed_plate(item): return _fail(g.SpecialEquipment.CURSED_PLATE_REASON)
   if item.id in protected_ids: return _fail("同一批次刚安装的特殊装备不能再次被替换。")
   mandatory.append({"id":item.id,"pieces":[item.duplicate(true)],"counts":Assess.counts(g,[item]),"composite":false})
   mandatory_ids.append(item.id)
 var direct=_trial(g,before,specs,source,[]) if mandatory.is_empty() else _fail("同族旧装备需要先完成替换。")
 if direct.ok: return direct
 # Factory-made prototypes, solely for capacity demand and comparison geometry.
 # This scratch state is discarded, including any factory RNG and emitted text.
 g.state=before.duplicate(true)
 g.state.equipment=[];g.state.composites=[];g.state.special_equipment=[];g.state.links=[]
 var new_pieces=[]
 var prototypes=[]
 for r in specs:
  var item=_install(g,r,source)
  if item.is_empty(): return _fail("本组安装规格本身不合法，或新装备之间存在冲突。")
  new_pieces.append_array(Assess.pieces(item))
  prototypes.append(item)
 for unit in mandatory:
  var old=unit.pieces[0]
  var family=g.SpecialEquipment.exclusive_family(old.type)
  var incoming=new_pieces.filter(func(piece):return g.SpecialEquipment.is_special(piece) and g.SpecialEquipment.exclusive_family(piece.type)==family)
  if incoming.is_empty() or Assess.comparison_value(g,incoming[0])<Assess.comparison_value(g,old): return _fail("同族新装备的品质不足，不能替换现有装备。")
 var demand=Assess.counts(g,new_pieces)
 g.state=before.duplicate(true)
 var existing=Assess.counts(g,g.physical_pieces()+g.state.special_equipment)
 var mandatory_counts={}
 for unit in mandatory:
  for point in unit.counts: mandatory_counts[point]=mandatory_counts.get(point,0)+unit.counts[point]
 var deficit={}
 for point in demand:
  var capacity=g.SpecialEquipment.capacity(point) if point in g.SpecialEquipment.slots() else g._capacity(g.Links.point_slot(point))
  for piece in new_pieces:
   if point not in g.SpecialEquipment.slots() and point in g.Equipment.capacity_points(piece):
    capacity=mini(capacity,g.Equipment.capacity(g.Links.point_slot(point),piece.template)+demand[point]-1)
  var extra=existing.get(point,0)-mandatory_counts.get(point,0)+demand[point]-capacity
  if extra>0: deficit[point]=extra
 var units=Assess.units(g,g.state.equipment,g.state.special_equipment,g.state.composites,deficit)
 units=units.filter(func(unit):return not unit.pieces.any(func(piece):return g.cursed_eyes(piece) or g.cursed_plate(piece) or piece.id in protected_ids or piece.id in mandatory_ids))
 # Even the weakest eligible values, with no lost-link penalty or whole-root
 # restriction, must pass the SAME assignment rule. This is only an optimistic
 # rejection bound; actual minimal sets and complete trials remain authoritative.
 if not _comparison_possible(g,units+mandatory,deficit,prototypes):
  return _fail("最外层没有满足本次容量、强度比较和完整覆盖要求的替换方案。")
 var search={"minimum":units.size()+1,"sets":[],"seen":{}}
 Assess.sets(units,deficit,[],search)
 var best={}
 for chosen in search.sets:
  var selected=mandatory.duplicate(true)
  for i in chosen: selected.append(units[i])
  if not best.is_empty():
   var minimum_score=0
   for unit in selected:
    for piece in unit.pieces:
     minimum_score+=Assess.comparison_value(g,piece)*Assess.capacity_points(g,piece).filter(func(point):return point in deficit).size()
   # Losing links can only add to this score. Equal scores retain the first
   # complete plan, exactly as before, so these sets cannot improve the result.
   if minimum_score>=best.score: continue
  var attempt=_trial(g,before,specs,source,selected,deficit)
  if attempt.ok and (attempt.removed+attempt.lost_links).any(func(id):return id in protected_ids): continue
  if attempt.ok and (best.is_empty() or attempt.score<best.score): best=attempt
 return best if not best.is_empty() else _fail("最外层没有满足本次容量、强度比较和完整覆盖要求的替换方案。")

static func _comparison_possible(g, units: Array, deficit: Dictionary, installed: Array) -> bool:
 var rows=[]
 for point in deficit:
  var values=[]
  for unit in units:
   for piece in unit.pieces:
    if point in Assess.capacity_points(g,piece): values.append(Assess.comparison_value(g,piece))
  values.sort()
  if values.size()<deficit[point]: return false
  for i in range(deficit[point]): rows.append({"point":point,"old_value":values[i],"composite":false})
 return Assess.assign(g,rows,installed,{},0,{},{},[]).ok

static func _trial(g, before: Dictionary, specs: Array, source: String, units: Array, deficit: Dictionary={}) -> Dictionary:
 g.state=before.duplicate(true)
 var old_targets=g.action_targets().duplicate(true)
 var removed_ids=[]
 for unit in units:
  for piece in unit.pieces: removed_ids.append(piece.id)
  var target=g._equipment(unit.id)
  for shoulder in g.Shoulders.attached(g,target):
   if shoulder.id not in removed_ids: removed_ids.append(shoulder.id)
 var impacted=before.links.filter(func(link):return link.ends.any(func(id):return id in removed_ids))
 # Temporarily park affected links so cleanup cannot falsely announce a loss
 # for a link that the complete replacement will legally retain.
 g.state.links=g.state.links.filter(func(link):return not impacted.any(func(old):return old.id==link.id))
 for unit in units: g._equipment(unit.id).durability=0.0
 if not units.is_empty(): g._cleanup(false)
 var installed=[]
 for r in specs:
  var item=_install(g,r,source)
  if item.is_empty(): return _fail("安装位置、容量或装备结构不满足本次要求。")
  installed.append(item)
 var new_anchors=[]
 for item in installed: new_anchors.append_array(Assess.pieces(item))
 var transfers=Assess.transfer_options(g,impacted,new_anchors,g.link_anchors(),g.state.links)
 var shoulder_losses=[]
 var live=g.action_targets().map(func(e):return e.id)
 var removed=old_targets.filter(func(e):return e.id not in live and e.template!="link_rope").map(func(e):return e.id)
 # Shoulder ids embed their owner under the current authoritative validator.
 # They cannot legally move to a new owner while retaining identity.
 for e in old_targets:
  if e.id in removed and g.Equipment.is_shoulder(e): shoulder_losses.append(e.id)
 var transfer={};var comparison={}
 for option in transfers:
  var checked=Assess.compare(g,units,installed,deficit,before.links,option.lost+shoulder_losses)
  if checked.ok and (comparison.is_empty() or checked.score<comparison.score):
   transfer=option;comparison=checked
 if comparison.is_empty(): return _fail("新装备未通过替换强度或完整覆盖检查。")
 var lost=transfer.lost+shoulder_losses
 g.state.links.append_array(transfer.kept)
 for link in impacted:
  if link.id in lost: g._emit("event",link.name+"无法接到新装备，随替换解除。",{"replacement_link":link.id})
 g._cleanup(false)
 # Validate the equipment domain without requiring an enclosing enemy/event
 # action to have finished updating its own transient phase state.
 for e in g.state.equipment:
  if g.Equipment.validate(e)!="" or g.Binding.validate(g,e)!="": return _fail("替换后的普通装备结构未通过检查。")
 for root in g.state.composites:
  if g.Composites.validate(root)!="": return _fail("替换后的复合装备结构未通过检查。")
 if g.Shoulders.validate(g)!="" or g.SpecialEquipment.validate(g.state.special_equipment)!="" or g._capacity_issue(g.physical_pieces())!="": return _fail("替换后的装备占位或依附关系未通过检查。")
 for link in g.state.links:
  if g.Links.validate(link,g.link_anchors(),g.state.links)!="": return _fail("替换后的链接结构未通过检查。")
 if not units.is_empty() and _same_loadout(before,g.state): return _fail("替换后装备没有变化。")
 return {"ok":true,"reason":"","requests":specs,"removed":removed,"installed":installed.duplicate(true),"lost_links":lost,"comparisons":comparison.rows,"score":comparison.score,"_after":g.state.duplicate(true)}

# Test-facing adapter, kept for the two existing link scenarios that call this
# historical (g, links, anchors) shape (tests/replacement_cases.gd::
# equivalent_link_transfers, ::partially_lost_transfers). One unconditional
# delegate: Assess.transfer_options stays the only implementation.
static func _transfer(g, links: Array, anchors: Array) -> Array:
 return Assess.transfer_options(g,links,anchors,g.link_anchors(),g.state.links)
