extends RefCounted
const Assess=preload("res://core/equipment_replacement_assess.gd")

# Game-internal, synchronous atomic group. The caller owns permission, costs,
# ready-stack consumption, action feedback and the enclosing version increment.
# Never persist a plan or expose its snapshots as a player command.
# A failed plan is always Assess.failure: one shape, one builder. This module keeps
# no local failure literal, so the contract cannot drift in two places.
static func plan(g, requests: Array, source: String, protected_ids: Array=[]) -> Dictionary:
 var original=g.state
 var feedback=g._resource_feedback
 g._resource_feedback=null
 g.state=original.duplicate(true)
 var result=_plan(g,requests,source,protected_ids)
 # Factories can displace equipment without explicit removal units in a direct plan.
 if result.ok and (result.removed+result.lost_links).any(func(id):return id in protected_ids):
  result=Assess.failure("本次不能替换刚安装的装备或附属件。")
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
 if not prepared.get("ok",false): return Assess.failure(prepared.get("reason","替换方案没有通过检查。"))
 if prepared.get("expectedVersion",-1)!=g.state.version or prepared.get("_before",{})!=g.state:
  return Assess.failure("装备或行动状态已更新，需要重新检查替换方案。")
 if not prepared.get("requests") is Array or not prepared.get("source") is String:
  return Assess.failure("替换方案缺少安装规格或来源。")
 # Recompute rather than trusting a mutable preview or a caller-supplied state.
 var fresh=plan(g,prepared.requests,prepared.source,prepared.get("protected_ids",[]))
 if not fresh.ok: return Assess.failure(fresh.reason)
 for key in ["_after","removed","installed","lost_links","comparisons"]:
  if fresh.get(key)!=prepared.get(key): return Assess.failure("替换方案的预演结果已改变，需要重新检查。")
 _commit_changes(g,fresh._after)
 return {"ok":true,"reason":"","removed":fresh.removed.duplicate(),"installed":fresh.installed.duplicate(true),"lost_links":fresh.lost_links.duplicate(),"comparisons":fresh.comparisons.duplicate(true)}

# Some captures explicitly replace every removable special item covered by one
# prescribed device. This remains a replacement transaction: cursed items are
# an absolute boundary, cleanup owns dependent pieces and links, and the normal
# special factory owns the incoming item.
static func force_special(g, type: String, tier: int, source: String) -> Dictionary:
 if not g.SpecialEquipment.DESIGNS.has(type) or tier not in [1,2,3]: return Assess.failure("指定的特殊装备不合法。")
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
 if blocking.any(g.SpecialEquipment.is_cursed_plate): return Assess.failure(g.SpecialEquipment.CURSED_PLATE_REASON)
 var old_targets=g.action_targets().duplicate(true)
 for item in blocking:
  item.durability=0.0
 if not blocking.is_empty(): g._cleanup(false)
 var installed=g._install_special(type,coverage[0],tier)
 if installed.is_empty(): return Assess.failure("清理可替换装备后仍无法佩戴指定装备。")
 if g.SpecialEquipment.validate(g.state.special_equipment)!="" or g._capacity_issue(g.physical_pieces())!="": return Assess.failure("替换后的特殊装备结构不合法。")
 var live=g.action_targets().map(func(item):return item.id)
 var removed=old_targets.filter(func(item):return item.id not in live and item.template!="link_rope").map(func(item):return item.id)
 var lost_links=old_targets.filter(func(item):return item.id not in live and item.template=="link_rope").map(func(item):return item.id)
 return {"ok":true,"reason":"","removed":removed,"installed":[installed],"lost_links":lost_links,"comparisons":[]}

static func _install(g, r: Dictionary, source: String) -> Dictionary:
 # Argument derivation is Assess.factory_args: only the "which factory" dispatch stays here.
 var args=Assess.factory_args(g,r)
 match args.get("kind",""):
  "install": return g._install_template(args.template,args.slot,args.durability,args.maximum,args.locked,source,args.grade,args.layer,args.variant,args.point)
  "assembly": return g._install_assembly(args.family,args.variant,source,args.grade,args.tier,args.parts,args.straps,args.get("attached_to",""))
  "special_install": return g._install_special(args.type,args.slot,args.tier)
 return {}

static func _plan(g, requests: Array, source: String, protected_ids: Array) -> Dictionary:
 var normalized=Assess.normalize(g,requests)
 if not normalized.ok: return normalized
 var specs=normalized.requests
 var before=g.state.duplicate(true)
 var mandatory_result=Assess.mandatory(g,before.special_equipment,specs,protected_ids)
 if not mandatory_result.ok: return mandatory_result
 var mandatory=mandatory_result.units
 var mandatory_ids=mandatory.map(func(unit):return unit.id)
 var direct=_trial(g,before,specs,source,[]) if mandatory.is_empty() else Assess.failure("同族旧装备需要先完成替换。")
 if direct.ok: return direct
 # Factory-made prototypes, solely for capacity demand and comparison geometry.
 # This scratch state is discarded, including any factory RNG and emitted text.
 g.state=before.duplicate(true)
 g.state.equipment=[];g.state.composites=[];g.state.special_equipment=[];g.state.links=[]
 var new_pieces=[]
 var prototypes=[]
 for r in specs:
  var item=_install(g,r,source)
  if item.is_empty(): return Assess.failure("本组安装规格本身不合法，或新装备之间存在冲突。")
  new_pieces.append_array(Assess.pieces(item))
  prototypes.append(item)
 for unit in mandatory:
  var old=unit.pieces[0]
  var family=g.SpecialEquipment.exclusive_family(old.type)
  var incoming=new_pieces.filter(func(piece):return g.SpecialEquipment.is_special(piece) and g.SpecialEquipment.exclusive_family(piece.type)==family)
  if incoming.is_empty() or Assess.comparison_value(g,incoming[0])<Assess.comparison_value(g,old): return Assess.failure("同族新装备的品质不足，不能替换现有装备。")
 var demand=Assess.counts(g,new_pieces)
 g.state=before.duplicate(true)
 var existing=Assess.counts(g,g.physical_pieces()+g.state.special_equipment)
 var deficit=Assess.deficit(g,demand,existing,new_pieces,mandatory)
 var units=Assess.units(g,g.state.equipment,g.state.special_equipment,g.state.composites,deficit)
 units=Assess.removable(g,units,protected_ids,mandatory_ids)
 # Even the weakest eligible values, with no lost-link penalty or whole-root
 # restriction, must pass the SAME assignment rule. This is only an optimistic
 # rejection bound; actual minimal sets and complete trials remain authoritative.
 if not Assess.comparison_possible(g,units+mandatory,deficit,prototypes):
  return Assess.failure("最外层没有满足本次容量、强度比较和完整覆盖要求的替换方案。")
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
 return best if not best.is_empty() else Assess.failure("最外层没有满足本次容量、强度比较和完整覆盖要求的替换方案。")

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
  if item.is_empty(): return Assess.failure("安装位置、容量或装备结构不满足本次要求。")
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
 if comparison.is_empty(): return Assess.failure("新装备未通过替换强度或完整覆盖检查。")
 var lost=transfer.lost+shoulder_losses
 g.state.links.append_array(transfer.kept)
 for link in impacted:
  if link.id in lost: g._emit("event",link.name+"无法接到新装备，随替换解除。",{"replacement_link":link.id})
 g._cleanup(false)
 # Validate the equipment domain without requiring an enclosing enemy/event
 # action to have finished updating its own transient phase state.
 for e in g.state.equipment:
  if g.Equipment.validate(e)!="" or g.Binding.validate(g,e)!="": return Assess.failure("替换后的普通装备结构未通过检查。")
 for root in g.state.composites:
  if g.Composites.validate(root)!="": return Assess.failure("替换后的复合装备结构未通过检查。")
 if g.Shoulders.validate(g)!="" or g.SpecialEquipment.validate(g.state.special_equipment)!="" or g._capacity_issue(g.physical_pieces())!="": return Assess.failure("替换后的装备占位或依附关系未通过检查。")
 for link in g.state.links:
  if g.Links.validate(link,g.link_anchors(),g.state.links)!="": return Assess.failure("替换后的链接结构未通过检查。")
 if not units.is_empty() and Assess.same_loadout(before,g.state): return Assess.failure("替换后装备没有变化。")
 return {"ok":true,"reason":"","requests":specs,"removed":removed,"installed":installed.duplicate(true),"lost_links":lost,"comparisons":comparison.rows,"score":comparison.score,"_after":g.state.duplicate(true)}

# Test-facing adapter, kept for the two existing link scenarios that call this
# historical (g, links, anchors) shape (tests/replacement_cases.gd::
# equivalent_link_transfers, ::partially_lost_transfers). One unconditional
# delegate: Assess.transfer_options stays the only implementation.
static func _transfer(g, links: Array, anchors: Array) -> Array:
 return Assess.transfer_options(g,links,anchors,g.link_anchors(),g.state.links)
