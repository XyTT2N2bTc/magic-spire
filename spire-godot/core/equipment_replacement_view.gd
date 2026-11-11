extends RefCounted
# Read-only device view for the replacement judgment (D12): derived containers, identity counters
# and a local binding counter copy. A record the trial must change is copied first (copy-on-write);
# the binding draw advances only the view's own counters. Rules stay in their owners; this module
# only orchestrates preview builders, shared predicates and the cleanup skeleton (O3: same live
# order, no live-only side effect; allowed edges data/* and the core predicate modules only).
static func live(g, seed_value: int, counters: Dictionary) -> Dictionary:
 return {"equipment":g.state.equipment.duplicate(),"composites":g.state.composites.duplicate(),
  "special_equipment":g.state.special_equipment.duplicate(),"links":g.state.links.duplicate(),
  "next_equipment":int(g.state.next_equipment),"next_composite":int(g.state.next_composite),
  "seed":seed_value,"counters":counters}
# Prototype view: four empty containers with the live counters and ids.
static func empty(g, seed_value: int, counters: Dictionary) -> Dictionary:
 return {"equipment":[],"composites":[],"special_equipment":[],"links":[],
  "next_equipment":int(g.state.next_equipment),"next_composite":int(g.state.next_composite),
  "seed":seed_value,"counters":counters}
# Copy one view record before a field change; a root is copied with its components.
static func own(view: Dictionary, record: Dictionary) -> Dictionary:
 for key in ["equipment","special_equipment","links"]:
  var container=view[key]
  for i in range(container.size()):
   if is_same(container[i],record):
    var copy=record.duplicate(true);container[i]=copy;return copy
 for i in range(view.composites.size()):
  var root=view.composites[i]
  if is_same(root,record):
   var copy=root.duplicate(true);view.composites[i]=copy;return copy
  for k in range(root.components.size()):
   if is_same(root.components[k],record):
    var owned=root.duplicate(true);view.composites[i]=owned;return owned.components[k]
 return record.duplicate(true)
# T2-T5: park affected links, zero the removed units, run the cleanup; returns the parked links.
static func after_removal(g, view: Dictionary, units: Array) -> Array:
 var removed_ids=[]
 for unit in units:
  for piece in unit.pieces: removed_ids.append(piece.id)
  var target=g._equipment_in(view,unit.id)
  for shoulder in g.Shoulders.attached_in(g,view,target):
   if shoulder.id not in removed_ids: removed_ids.append(shoulder.id)
 var impacted=g.state.links.filter(func(link):return link.ends.any(func(id):return id in removed_ids))
 view.links=view.links.filter(func(link):return not impacted.any(func(old):return old.id==link.id))
 for unit in units: own(view,g._equipment_in(view,unit.id)).durability=0.0
 if not units.is_empty(): cleanup(g,view)
 return impacted
# Preview dispatch for one normalized request; args is the shared factory argument record.
static func install(g, view: Dictionary, args: Dictionary, source: String) -> Dictionary:
 match args.get("kind",""):
  "install":
   var placement=g._prepare_installation_in(view,args.template,args.slot,args.grade,args.locked,args.point,args.layer)
   if placement.reason!="": return {}
   var e=g._template_piece(view.next_equipment,args.template,args.slot,args.durability,args.maximum,args.locked,source,args.grade,placement.layer,args.variant,placement.points)
   if g.Equipment.validate(e)!="": return {}
   view.next_equipment+=1;view.equipment.append(e);refresh(g,view,e);return e
  "assembly":
   var root=g._plan_assembly_in(view,args.family,args.variant,source,args.grade,args.tier,args.parts,args.straps,args.attached_to)
   if root.is_empty(): return {}
   for e in view.equipment.duplicate():
    if g.Binding.cancels(g,e,root.components): own(view,e).erase("binding")
   view.composites.append(root);view.next_composite+=1;return root
  "special_install":
   if g._special_install_reason_in(view,args.type,args.slot)!="": return {}
   var item=g._special_piece(view.next_equipment,args.type,args.tier)
   view.next_equipment+=1;view.special_equipment.append(item)
   if g.SpecialEquipment.supports_reinforcement(item) and g.tier(item.durability,item.maximum)==3: attach(g,view,item)
   return item
 return {}
# The _refresh_equipment orchestration on a view: mouth-band naming, the shared binding record
# (drawn from the local counter) and the tier-three shoulder pair. Feedback and events belong to
# the live factory and stay out.
static func refresh(g, view: Dictionary, e: Dictionary) -> void:
 if e.template=="mouth_band":
  e.name=g.Equipment.name_for(e.template,e.slot,e.grade,e.variant);e.slip_allowed=not g.Equipment.has_mouth_harness(e)
 var binding=g.Binding.resolve(g,e,func(domain,size):return g._random_draw(view.seed,domain,view.counters,size))
 if not binding.is_empty(): e.binding=binding
 if g.tier(e.durability,e.maximum)!=3 or not g.Shoulders.eligible(e): return
 if not e.has("shoulders"): e.shoulders={"template":e.template,"grade":e.grade,"variant":e.variant,"source":e.source,"pieces":[]}
 for side in ["left","right"]:
  if e.shoulders.pieces.any(func(strap):return strap.side==side and strap.durability>0.000001): continue
  e.shoulders.pieces.append(g.Shoulders.pair_pieces(g,e,side))
# The tier-three reinforcement strap of a new special piece (no feedback, no event).
static func attach(g, view: Dictionary, owner: Dictionary) -> Dictionary:
 var existing=view.special_equipment.filter(func(item):return g.SpecialEquipment.reinforcement_matches(item,owner))
 if not existing.is_empty(): return existing[0]
 var type=g.SpecialEquipment.reinforcement_type(owner)
 if type=="": return {}
 owner.reinforcement_state="active"
 var strap=g._reinforcement_strap(view.next_equipment,type,owner.id)
 view.next_equipment+=1;view.special_equipment.append(strap);return strap
# O3 view skeleton: same order and shared predicates as Removal.settle, no live-only side effect.
# Shoulders' crossed flag is durability-derived on a valid piece. The link anchors are read once
# before the link pass, exactly as the live settle reads them.
static func cleanup(g, view: Dictionary) -> void:
 for host in view.equipment:
  if not host.has("shoulders"): continue
  var lost=host.shoulders.pieces.filter(func(strap):return g.Shoulders.released_with_host(host,strap)).map(func(strap):return strap.id)
  if lost.is_empty(): continue
  var owned=own(view,host);owned.shoulders=owned.shoulders.duplicate(true)
  owned.shoulders.pieces=owned.shoulders.pieces.filter(func(strap):return not strap.id in lost)
 for item in view.special_equipment.duplicate():
  if not g._released(item): continue
  if g.SpecialEquipment.is_reinforcement(item):
   var owner=g._equipment_in(view,item.owner_id)
   if not owner.is_empty() and g.SpecialEquipment.supports_reinforcement(owner): own(view,owner).reinforcement_state="removed"
  view.special_equipment.erase(item)
  for strap in view.special_equipment.duplicate():
   if g._strap_follows(item,strap): view.special_equipment.erase(strap)
 for strap in view.special_equipment.duplicate():
  if g._strap_orphaned(strap,view.special_equipment): view.special_equipment.erase(strap)
 for i in range(view.equipment.size()-1,-1,-1):
  if g._piece_released(view.equipment[i]): view.equipment.remove_at(i)
 for root in view.composites.duplicate():
  var body=g._composite_body(root)
  if g._root_head_orphaned(root,g._equipment_in(view,root.attached_to)):
   view.composites.erase(root);continue
  if not body.is_empty() and g._released(body):
   var owned=own(view,root);owned.components=owned.components.filter(func(e):return g._component_kept(e))
   if owned.components.is_empty(): view.composites.erase(owned)
   continue
  var released=root.components.filter(func(e):return g._released(e)).map(func(e):return e.id)
  if released.is_empty(): continue
  var kept=own(view,root);kept.components=kept.components.filter(func(e):return not e.id in released)
  if kept.components.is_empty(): view.composites.erase(kept)
 var anchors=g.link_anchors_in(view)
 for link in view.links.duplicate():
  if g._released(link) or g._link_anchor_lost(link,anchors): view.links.erase(link)
# Flattened loadout records for identity comparison: a composite carries its components, a
# binding its generated record, a host its straps; identity/provenance are stripped.
static func loadout_records(snapshot: Dictionary) -> Array:
 var records=[]
 for item in snapshot.equipment+snapshot.special_equipment+snapshot.links+snapshot.composites:
  var record=item.duplicate(true);records.append_array(record.get("components",[]));record.erase("components")
  if record.get("binding",{}).has("id"):
   records.append(record.binding);record.binding={"kind":record.binding.kind}
  if record.has("shoulders"):
   records.append_array(record.shoulders.pieces);record.shoulders.erase("pieces");record.shoulders.erase("source")
  records.append(record)
 return records
static func record_facts(record: Dictionary) -> Dictionary:
 var facts=record.duplicate(true)
 for key in ["id","source","root_id","parent_id","shoulder_host","attached_to","ends"]: facts.erase(key)
 return facts
static func same_loadout(before: Dictionary, after: Dictionary) -> bool:
 var old_records=loadout_records(before);var new_records=loadout_records(after)
 if old_records.size()!=new_records.size(): return false
 var unmatched=old_records.duplicate();var identity={}
 for record in new_records:
  var facts=record_facts(record)
  var index=unmatched.find_custom(func(old):return record_facts(old)==facts)
  if index<0: return false
  identity[record.id]=unmatched[index].id;unmatched.remove_at(index)
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
