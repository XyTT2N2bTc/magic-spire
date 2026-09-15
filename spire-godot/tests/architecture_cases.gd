extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Rewards=preload("res://tests/reward_cases.gd")

class UncachedGame extends "res://tests/game_fixture.gd":
 func _begin_equipment_read() -> Dictionary:
  return {}

class PreviewCountingGame extends "res://tests/game_fixture.gd":
 var escape_builds=0
 var cast_builds=0
 func _build_escape_preview(target: Dictionary, mode: String, base: float, assist_profiles: Array=[], passive: bool=false, area_effect: bool=false, continuation: bool=false, splash: bool=false) -> Dictionary:
  escape_builds+=1
  return super._build_escape_preview(target,mode,base,assist_profiles,passive,area_effect,continuation,splash)
 func _build_cast_view(profile: Dictionary) -> Dictionary:
  cast_builds+=1
  return super._build_cast_view(profile)

# Test-side counters for "each edge materializes at most once per scope"; production has none.
class IndexCountingGame extends "res://tests/game_fixture.gd":
 var piece_builds=0
 var slot_builds=0
 var id_builds=0
 var capacity_builds=0
 var physical_builds=0
 func _materialize_physical_pieces() -> Array:
  piece_builds+=1
  return super._materialize_physical_pieces()
 func _materialize_slot_edge(pieces: Array) -> Dictionary:
  slot_builds+=1
  return super._materialize_slot_edge(pieces)
 func _materialize_id_edge() -> Dictionary:
  id_builds+=1
  return super._materialize_id_edge()
 func _materialize_capacity_points(pieces: Array) -> Dictionary:
  capacity_builds+=1
  return super._materialize_capacity_points(pieces)
 func _materialize_physical_points(pieces: Array) -> Dictionary:
  physical_builds+=1
  return super._materialize_physical_points(pieces)

static func containers(value, path: String, out: Array) -> void:
 if value is Dictionary:
  out.append({"value":value,"path":path})
  for key in value: containers(value[key],path+"."+str(key),out)
 elif value is Array:
  out.append({"value":value,"path":path})
  for i in range(value.size()): containers(value[i],path+"["+str(i)+"]",out)

static func shared(view: Dictionary, authority: Dictionary) -> String:
 var visible=[];var sources=[]
 containers(view,"view",visible);containers(authority,"authority",sources)
 for entry in visible:
  for source in sources:
   if is_same(entry.value,source.value): return entry.path+" -> "+source.path
 return ""

static func run(t) -> void:
 tool_registry_boundary(t)
 equipment_read_batches(t)
 index_materializes_once_per_scope(t)
 index_id_edge_parity(t)
 index_self_check_falls_back(t)
 var images=preload("res://data/equipment_images.gd")
 var missing=[]
 for family in images.MATERIALS:
  for file in images.MATERIALS[family]:
   if not ResourceLoader.exists("res://assets/ui/equipment/"+file+".png"): missing.append(file)
 for file in images.TEMPLATES.values():
  if not ResourceLoader.exists("res://assets/ui/equipment/"+file+".png"): missing.append(file)
 t.check(missing.is_empty(),"ARCH all registered legacy equipment images exist: "+str(missing))
 var initial=Game.new(42,false,"equipment",false)
 t.check(initial.state.rng.size()==initial.B.RNG_SALTS.size() and initial.B.RNG_SALTS.keys().all(func(domain):return initial.state.rng.get(domain)==0),"ARCH initialization creates exactly the registered random domains with zero counters")
 card_identity(t)
 current_effect_boundaries(t)
 instance_effect_boundaries(t)
 for kind in ["equipment","component_links","prison_test","succubus_three_games","trader_solo","drone_solo","binding_box_solo"]:
  var g=Game.new(42,true,kind)
  if kind in ["drone_solo","binding_box_solo"]:
   t.check(t.action(g,"end").ok and g.CaptureBind.has_bind(g),"ARCH formal enemy turn establishes source-bound capture "+kind)
  projection_contract(t,g,kind)
 var g=Rewards.setup()
 var target=g.add_fixture("thigh",4)
 var id=target.id
 var focus=Rewards.give(t,g,"focus")
 t.check(Rewards.play(t,g,focus,"thigh",id).ok and g.state.charge==1,"ARCH real focus card grants shared charge")
 var before=g.export_snapshot()
 t.check(t.action(g,"manual",{"target":id}).ok,"ARCH release uses formal candidate")
 t.check(g._equipment(id).is_empty() and g.state.charge==1,"ARCH deleted ordinary target preserves unrelated charge")
 t.check(g.state.energy==before.energy-1 and g.state.mana==before.mana and g.state.rng==before.rng,"ARCH manual cleanup pays once and preserves unrelated resource and random domains")
 var settled=g.export_snapshot()
 g._cleanup()
 t.check(g.export_snapshot()==settled,"ARCH cleanup reaches a fixed point without repeated events")

static func tool_registry_boundary(t) -> void:
 var catalog=preload("res://data/field_tools.gd")
 var tools=Game.Tools
 for field in ["TYPES","DROP_POOL","HEIGHTS","OPERATOR_HEIGHTS","POINT_HEIGHTS"]:
  t.check(is_same(tools[field],catalog[field]),"ARCH tool rules inherit the original registry without a mutable duplicate: "+field)
 var names=catalog.new().get_method_list().map(func(method):return method.name)
 t.check(not "install_reason" in names and not "target_contact" in names and not "description" in names,"ARCH item catalog does not expose state-dependent tool queries")
 t.check(catalog.HEIGHTS.is_read_only() and tools.HEIGHTS.is_read_only() and catalog.HEIGHTS.keys().all(func(mount):return tools.mount_label(mount)==catalog.mount_label(mount)),"ARCH inherited height definitions stay read-only and expose the same labels")

static func card_identity(t) -> void:
 for damage in ["type","orphan","duplicate"]:
  var g=Rewards.setup()
  var candidate=g.candidates().filter(func(c):return c.valid)[0]
  var clean=g.export_snapshot()
  match damage:
   "type": g.state.deck[0].type="panic" if g.state.deck[0].type!="panic" else "sensitive"
   "orphan": g.state.deck[0].uid="card_missing"
   "duplicate": g.state.deck[0]=g.state.deck[1].duplicate(true)
  var damaged=g.export_snapshot()
  t.check(g.validate()!="","ARCH equal card counts cannot hide mismatched physical identity "+damage)
  t.check(not g.dispatch(candidate.id,g.state.version).ok and g.export_snapshot()==damaged,"ARCH invalid card identity rejects action before payment "+damage)
  g.state=clean
  t.check(not g.restore_snapshot(damaged).ok and g.export_snapshot()==clean,"ARCH same card invariant rejects restore atomically "+damage)

static func projection_contract(t, g, label: String) -> void:
 var before=g.state.duplicate(true)
 var view=g.get_view()
 var candidates=g.candidates()
 var targets=g.action_targets();var target_ids={}
 for target in targets: target_ids[target.id]=true
 t.check(target_ids.size()==targets.size() and targets.all(func(target):return is_same(target,g._equipment(target.id))),"ARCH action target identities are unique and resolve to canonical objects "+label)
 var reference=UncachedGame.new(42)
 reference.state=before.duplicate(true)
 t.check(view==reference.get_view() and candidates==reference.candidates(),"ARCH indexed and live equipment queries produce identical full projections "+label)
 t.check(g._equipment_read.is_empty(),"ARCH read batch releases all equipment references "+label)
 t.check(g.state==before,"ARCH preview preserves all state and random domains "+label)
 var alias=shared(view,{"state":g.state,"equipment":g.Equipment.TEMPLATES,"special":g.SpecialEquipment.TYPES,"regions":g.SpecialEquipment.REGIONS,"cards":g.Cards.Rules.SPECS,"buffs":g.Cards.Rules.BUFFS,"relics":g.Relics.TYPES,"enemies":g.Enemies.TYPES,"attacks":g.BasicAttacks.TYPES,"body_groups":g.Equipment.PANEL_GROUPS,"shop_copy":g.Services.ShopCopy.PERFORMANCES})
 t.check(alias=="","ARCH view has no writable references to state or registries "+label+": "+alias)
 var ids={}
 for candidate in candidates: ids[candidate.id]=true
 t.check(ids.size()==candidates.size() and candidates.map(func(c):return c.id)==view.candidates.map(func(c):return c.id),"ARCH distinct stable candidate identities survive repeat projection "+label)

static func equipment_read_batches(t) -> void:
 equipment_projection_batches(t)
 preview_read_batches(t)
 var g=Game.new(42)
 g.state.equipment.clear()
 for i in range(3):
  for slot in g.B.SLOTS: g.add_fixture(slot,7,10)
 var reference=UncachedGame.new(42);reference.state=g.state.duplicate(true)
 var before=g.export_snapshot()
 t.check(g.validate()=="" and g.physical_pieces().size()>20,"ARCH dense equipment fixture respects formal capacities")
 t.check(g.get_view()==reference.get_view() and g.candidates()==reference.candidates(),"ARCH dense indexed queries preserve every candidate, value and visible text")
 t.check(g.state==before and g._equipment_read.is_empty(),"ARCH dense reads leave state, random cursors and query lifetime unchanged")
 var target=g.equipment_at("wrist")[0]
 target.durability=2
 reference.state=g.state.duplicate(true)
 t.check(g.get_view()==reference.get_view(),"ARCH new read observes changed equipment even without a version increment")
 var previous=g._begin_equipment_read()
 var members=g.equipment_at("wrist");members.clear()
 t.check(not g.equipment_at("wrist").is_empty(),"ARCH sorting or clearing a returned query array cannot corrupt the index")
 var original=g.state;g.state=original.duplicate(true);g.state.equipment.clear()
 t.check(g.equipment_at("wrist").is_empty() and g._equipment(target.id).is_empty(),"ARCH speculative replacement state bypasses the outer read index")
 g.state=original
 t.check(g._equipment(target.id)==target and not g.equipment_at("wrist").is_empty(),"ARCH returning from speculation restores the original query context")
 g._equipment_read=previous
 g=Game.new(42);g._discard_end();g.state.energy=2
 preload("res://tests/curse_cases.gd").give(g,"self_binding")
 projection_contract(t,g,"self-binding speculative installation")

# Batch B1 (§11 scenario 2): each edge materializes at most once per scope and never outside one.
static func index_materializes_once_per_scope(t) -> void:
 var g=IndexCountingGame.new(42)
 g.state.equipment.clear()
 for slot in g.B.SLOTS: g.add_fixture(slot,7,10)
 var before=g.export_snapshot()
 var previous=g._begin_equipment_read()
 t.check(g.piece_builds==1 and g.slot_builds==1 and g.id_builds==1 and g.capacity_builds==1 and g.physical_builds==1,"INDEX entry materializes the piece set and every edge once per scope")
 for slot in g.B.SLOTS: g.equipment_at(slot)
 for step in range(3): g.physical_pieces()
 var ids=g.physical_pieces().map(func(e):return e.id)
 for id in ids: g._equipment(id)
 for slot in g.B.SLOTS: g.capacity_used(slot)
 for point in g.Equipment.ANATOMY: g._point_count(point)
 t.check(g.piece_builds==1 and g.slot_builds==1 and g.id_builds==1 and g.capacity_builds==1 and g.physical_builds==1,"INDEX repeated slot, id and point queries inside one scope never rebuild an edge")
 var members=g.equipment_at("wrist");members.clear();members.append({})
 t.check(not g.equipment_at("wrist").is_empty(),"INDEX clearing a materialized slot answer cannot corrupt the edge")
 var built=g.piece_builds;var slot_builds=g.slot_builds;var id_builds=g.id_builds
 var capacity_builds=g.capacity_builds;var physical_builds=g.physical_builds
 g._equipment_read=previous
 t.check(g._equipment_read.is_empty(),"INDEX read scope releases its materialized edges")
 for step in range(3):
  g.equipment_at("wrist");g.physical_pieces()
 for id in ids: g._equipment(id)
 for slot in g.B.SLOTS: g.capacity_used(slot)
 for point in g.Equipment.ANATOMY: g._point_count(point)
 t.check(g.piece_builds==built and g.slot_builds==slot_builds and g.id_builds==id_builds and g.capacity_builds==capacity_builds and g.physical_builds==physical_builds,"INDEX queries without a scope never build an edge table")
 t.check(g.export_snapshot()==before,"INDEX materialization leaves state, logs and random cursors unchanged")

# Batch B1 (§11 scenario 3): an inconsistent graph voids the whole scope, records one named issue
# and answers every later query in that scope from the live path.
static func index_self_check_falls_back(t) -> void:
 var root=Game.new(42,true,"component_links")
 root.state.composites[0].components[0].root_id=root.state.composites[1].id
 var host=Game.new(42,true,"shoulder_links")
 var special=host._install_special("nipple_clamp_medium","special_1_a")
 host.state.equipment[0].shoulders.pieces[0].shoulder_host=special.id
 var twin=Game.new(42,true,"shoulder_links")
 twin.state.equipment.append(twin.state.equipment[0].duplicate(true))
 for damage in [{"label":"component root mismatch","game":root,"check":1},{"label":"shoulder host outside the piece set","game":host,"check":2},{"label":"two instances sharing one id","game":twin,"check":3}]:
  var g=damage.game
  var reference=UncachedGame.new(42);reference.state=g.state.duplicate(true)
  var before=g.export_snapshot()
  var recorded=g._equipment_index_issues.size()
  var view=g.get_view()
  var candidates=g.candidates()
  t.check(view==reference.get_view() and candidates==reference.candidates(),"INDEX damaged graph answers exactly like the live reference "+damage.label)
  var issues=g._equipment_index_issues
  t.check(issues.size()==recorded+2 and issues[-1].check==damage.check and issues[-1].edge!="" and issues[-1].id!="","INDEX one named record per voided scope "+damage.label+": "+str(issues))
  t.check(g._equipment_read.is_empty() and g.export_snapshot()==before,"INDEX fallback leaves no scope, state, log or save change "+damage.label)
 var dangling=Game.new(42,true,"shoulder_links")
 var piece=dangling.state.equipment[0].shoulders.pieces[0]
 piece.shoulder_host="missing_host"
 var live_reference=UncachedGame.new(42);live_reference.state=dangling.state.duplicate(true)
 var dangling_before=dangling.export_snapshot()
 var recorded=dangling._equipment_index_issues.size()
 var dangling_scope=dangling._begin_equipment_read()
 # The live projection aborts on a dangling shoulder host, so this fixture compares leaf queries only.
 var parity=dangling.physical_pieces()==live_reference.physical_pieces() and dangling.equipment_at(piece.slot)==live_reference.equipment_at(piece.slot) and dangling._equipment_name(piece)==live_reference._equipment_name(live_reference._equipment(piece.id))
 t.check(parity and dangling._equipment_index_issues.size()==recorded+1 and dangling._equipment_index_issues[-1].check==2,"INDEX dangling shoulder host voids the scope before display code reads it")
 dangling._equipment_read=dangling_scope
 t.check(dangling._equipment_read.is_empty() and dangling.export_snapshot()==dangling_before,"INDEX dangling host fallback leaves no scope or state change")

# Batch B2 (§8.3): the materialized id edge answers like the live lookup over every target
# family and keeps the authoritative instance reference (§2 exception one).
static func index_id_edge_parity(t) -> void:
 for kind in ["plain","component_links","shoulder_links","torso_binding","special_equipment"]:
  var g=Game.new(42,true,kind) if kind!="plain" else Game.new(42)
  if kind=="plain":
   for slot in ["wrist","ankle","thigh"]: g.add_fixture(slot,7,10)
  var reference=UncachedGame.new(42);reference.state=g.state.duplicate(true)
  var before=g.export_snapshot()
  var targets=reference.action_targets()
  var previous=g._begin_equipment_read()
  var indexed={}
  for target in targets: indexed[target.id]=g._equipment(target.id)
  var parity=not targets.is_empty()
  for target in targets:
   parity=parity and not indexed[target.id].is_empty() and indexed[target.id]==target
  parity=parity and g._equipment("missing_id").is_empty()
  g._equipment_read=previous
  for target in targets:
   parity=parity and is_same(indexed[target.id],g._equipment(target.id))
  t.check(parity and g.export_snapshot()==before and g._equipment_read.is_empty(),"INDEX id edge parity with the live path "+kind)
 var plain=Game.new(42)
 var piece=plain.add_fixture("thigh",7,10)
 var scope=plain._begin_equipment_read()
 plain._equipment(piece.id).durability=3
 plain._equipment_read=scope
 t.check(plain.state.equipment.filter(func(e):return e.id==piece.id)[0].durability==3,"INDEX id edge writes through to the authoritative instance, never to a copy")

static func equipment_projection_batches(t) -> void:
 var g=Game.new(42,true,"jacket")
 var target=g.physical_pieces().filter(func(e):return e.template=="jacket_body")[0]
 var slots=g.Equipment.coverage(target)
 var before=g.export_snapshot()
 var previous=g._begin_equipment_read()
 var first=g.View.equipment_entry(g,target,slots[0])
 first.description="changed";first.slot="changed";first.extra={"changed":true}
 var second=g.View.equipment_entry(g,target,slots[-1])
 var reference=UncachedGame.new(42);reference.state=g.state.duplicate(true)
 t.check(second==reference.View.equipment_entry(reference,reference._equipment(target.id),slots[-1]),"ARCH shared equipment description retains the requested body slot without leaked annotations")
 t.check(g._equipment_read.equipment_views.size()==1 and not second.has("extra"),"ARCH cross-slot equipment projection builds one isolated base row")
 var copied=target.duplicate(true);copied.durability=1
 t.check(g.View.equipment_entry(g,copied,slots[0])==reference.View.equipment_entry(reference,copied,slots[0]),"ARCH copied equipment object bypasses canonical display reuse")
 var original=g.state;g.state=original.duplicate(true);g._equipment(target.id).durability=1
 reference.state=g.state.duplicate(true)
 t.check(g.View.equipment_entry(g,g._equipment(target.id),slots[0])==reference.View.equipment_entry(reference,reference._equipment(target.id),slots[0]),"ARCH temporary state cannot reuse the outer equipment description")
 g.state=original;g._equipment_read=previous
 t.check(g.export_snapshot()==before and g._equipment_read.is_empty(),"ARCH equipment display batch does not retain state references or mutate gameplay")
 target.durability=1
 reference.state=g.state.duplicate(true)
 t.check(g.get_view()==reference.get_view(),"ARCH subsequent full projection observes changed durability without a version increment")

static func preview_read_batches(t) -> void:
 var g=PreviewCountingGame.new(42)
 g.state.equipment.clear();g.state.relics=[]
 var target=g.add_fixture("thigh",7,10)
 g.add_fixture("thigh",5,10)
 var reference=UncachedGame.new(42);reference.state=g.state.duplicate(true)
 var before=g.export_snapshot()
 var previous=g._begin_equipment_read()
 var profiles=g.HandAssist.profiles(g)
 var equivalent=true
 for mode in ["strain","slip","magic_slip"]:
  for base in [7.0,7.000000000001]:
   for flags in range(16):
    var arguments=[target,mode,base,profiles,bool(flags&1),bool(flags&2),bool(flags&4),bool(flags&8)]
    var expected=reference.escape_preview(reference._equipment(target.id),mode,base,profiles,bool(flags&1),bool(flags&2),bool(flags&4),bool(flags&8))
    equivalent=equivalent and g.callv("escape_preview",arguments)==expected and g.callv("escape_preview",arguments)==expected
 t.check(equivalent,"ARCH preview reuse preserves mode, full precision base and every passive/area/continuation/splash combination")
 t.check(g.escape_builds==96,"ARCH identical full-argument previews calculate once within the read batch")
 var preview=g.escape_preview(target,"strain",7,profiles)
 preview.assist.hands.clear();preview.assist.bonus=-999;preview.position.factor=-999
 t.check(g.escape_preview(target,"strain",7,profiles)==reference.escape_preview(reference._equipment(target.id),"strain",7,profiles),"ARCH nested result edits cannot poison a reused escape preview")
 var original_profiles=profiles.duplicate(true)
 profiles[0].points.clear();profiles[0].assist_factor=0.25
 t.check(g.escape_preview(target,"strain",7,profiles)==reference.escape_preview(reference._equipment(target.id),"strain",7,profiles),"ARCH changed nested hand profiles do not reuse earlier assistance")
 t.check(g.escape_preview(target,"strain",7,original_profiles)==reference.escape_preview(reference._equipment(target.id),"strain",7,original_profiles),"ARCH reused input arrays cannot rewrite an earlier preview key")
 var copy=target.duplicate(true);copy.durability=1
 t.check(g.escape_preview(copy,"slip",7)==reference.escape_preview(copy,"slip",7),"ARCH copied target with the same ID bypasses canonical preview reuse")
 var cast_profiles=[{"parts":["mouth"],"multiplier":1.0},{"parts":["hand","mouth"],"multiplier":1.0},{"parts":["hand"],"multiplier":1.0,"body_free":true},{"parts":["mouth"],"multiplier":0.5},{"parts":["mouth"],"multiplier":1.0,"chance_bonus":0.1},{"parts":["mouth"],"multiplier":1.0,"paid_cast":false}]
 equivalent=true
 for profile in cast_profiles:
  equivalent=equivalent and g.cast_view(profile)==reference.cast_view(profile) and g.cast_view(profile)==reference.cast_view(profile)
 t.check(equivalent and g.cast_builds==cast_profiles.size(),"ARCH casting reuses only equal complete profiles including routes, free-body, multiplier, bonus and payment")
 var casting=g.cast_view(cast_profiles[0]);casting.factors.append({"invalid":true});casting.chance=-1
 cast_profiles[0].parts.append("hand")
 t.check(g.cast_view(cast_profiles[0])==reference.cast_view(cast_profiles[0]) and g.cast_view()==reference.cast_view(),"ARCH casting input and output mutations cannot poison another route")
 var original=g.state;g.state=original.duplicate(true);g.state.pressure=80;g._equipment(target.id).durability=1
 reference.state=g.state.duplicate(true)
 var temporary=g._begin_equipment_read()
 t.check(g.cast_view()==reference.cast_view() and g.escape_preview(g._equipment(target.id),"slip",7)==reference.escape_preview(reference._equipment(target.id),"slip",7),"ARCH nested speculative state gets its own cast and escape previews")
 g._equipment_read=temporary;g.state=original;reference.state=original.duplicate(true)
 t.check(g.cast_view()==reference.cast_view() and g.escape_preview(target,"strain",7,original_profiles)==reference.escape_preview(reference._equipment(target.id),"strain",7,original_profiles),"ARCH original previews survive temporary state restoration")
 g._equipment_read=previous
 t.check(g.export_snapshot()==before and g._equipment_read.is_empty(),"ARCH preview batch leaves no state/RNG writes or retained results")
 g.state.pressure=80;target.durability=1;reference.state=g.state.duplicate(true)
 t.check(g.cast_view()==reference.cast_view() and g.escape_preview(target,"slip",7)==reference.escape_preview(reference._equipment(target.id),"slip",7),"ARCH subsequent live read observes resource and durability changes without version increment")
 for kind in ["component_links","shoulder_links","torso_binding","special_equipment"]:
  g=PreviewCountingGame.new(42,true,kind)
  reference.state=g.state.duplicate(true)
  t.check(g.get_view()==reference.get_view(),"ARCH preview reuse preserves composite/link/special projection "+kind)
  for step in range(2):
   var available=g.candidates().filter(func(c):return c.valid and c.payload.kind=="card")
   if available.is_empty(): break
   var candidate=available[0]
   var outcome=g.dispatch(candidate.id,g.state.version)
   var expected=reference.dispatch(candidate.id,reference.state.version)
   t.check(outcome==expected and outcome.ok and g.export_snapshot()==reference.export_snapshot(),"ARCH preview reuse preserves actual payment, RNG and cleanup across sequential card commits "+kind+"/"+str(step))

static func current_effect_boundaries(t) -> void:
 var g=Game.new(42)
 g._discard_end();g.state.energy=30;g.state.relics=[];g.state.flask_mana=20
 for entry in [["echo_cast",false],["adaptability",false],["fire_control",false],["echo_cast",true]]:
  var card=preload("res://tests/curse_cases.gd").give(g,entry[0])
  t.check(t.action(g,"card",{"uid":card.uid,"free":entry[1]}).ok,"ARCH current effect uses formal card transaction "+entry[0])
 t.check(g.state.powers.size()==1 and g.state.powers[0].power_stacks==2 and g.state.temporary_mana==10 and "echo_cast_free" in g.state.card_buffs and g.validate()=="","ARCH fixture combines doubled power, temporary mana and pending replay")
 projection_contract(t,g,"active powers and split payment")
 g.RelicEffects.end_combat(g)
 g._start_rest()
 t.check(g.state.phase=="rest_choice" and not g.state.combat.active and g.state.temporary_mana==10 and g.state.powers.is_empty() and g.state.card_buffs.is_empty(),"ARCH rest choice retains temporary mana while clearing abilities and pending replay")
 projection_contract(t,g,"frozen rest choices")
 t.check(t.action(g,"rest_begin").ok and g.state.combat.active,"ARCH rest begins through its formal command")
 projection_contract(t,g,"new rest session")

static func instance_effect_boundaries(t) -> void:
 var f=preload("res://tests/concentration_cases.gd").setup()
 var g=f.g
 t.check(t.action(g,"card",{"uid":f.card.uid,"target":f.target.id,"free":true}).ok,"ARCH second bound face grows through the formal action")
 projection_contract(t,g,"physical card growth on second bound face")
 var checkpoint=g.restart_snapshot()
 var before=g.export_snapshot()
 var exposed=g.restart_snapshot()
 exposed.hand.clear();exposed.rng.clear()
 t.check(g.restart_snapshot()==checkpoint and g.export_snapshot()==before,"ARCH external restart snapshot cannot alter checkpoint or current state")
 g=Rewards.setup()
 var card=Rewards.give(t,g,"strain")
 t.check(t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state.charge==1,"ARCH preparation grants charge through the real card")
 t.check(t.action(g,"status_toggle",{"status":"charge","enabled":true}).ok,"ARCH charge mode uses the common command boundary")
 projection_contract(t,g,"prepared charge and all-stack mode")

 g=Game.new(42,true,"shop")
 t.check(t.action(g,"service",{"op":"take","index":0,"payment":"self"}).ok,"ARCH shop transaction freezes its actual payment source")
 projection_contract(t,g,"shop result and presentation registry")
