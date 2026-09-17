extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const GameCore=preload("res://core/game.gd")
const Rewards=preload("res://tests/reward_cases.gd")
const Guard=preload("res://core/guard.gd")

# docs/ondemand-copy.md §5.1: frozen docs/equipment-query-seam.md §8.2 hashes recomputed with
# unmodified source on 2026-09-15 (candidates_sha256, view_sha256) for the §5.5 fixtures.
const COPY_BASELINE={
 "battle:0":["bf8d97d58f3be03b42cb65ee5b36afebca335f25e496fbb3301db3285fcc46fe","e2b375c5019c2ccae9d088a5050b9ee445d199f74c0e524e9e63cd2bc6ccfb4a"],
 "battle:12":["c07e59259326f1ec2e380bcc1d7f2ed8e9b05e8442f16b3bb288133ff2b9a6df","81f7796e55826b580131762445db711651815b83b7bb0a9ab89560971ccb2f32"],
 "battle:26":["361c37774a2901bb985926fe0ce4dd9bb4f1c2e7b349d6fb39dca2a9f59d91d8","f7401077920a93d96b699052708a19597ffaa02496c0925b4578aee61469fc06"],
 "departure:0":["74b735a41f761e8bae611d38bffc58b103c40f1d534ba086f00bc30f2dd9fc3c","472f1bd7efbd2271be1e720ffff59d284d43081eb4a41362fe49d0a2362933cd"],
 "departure:12":["74b735a41f761e8bae611d38bffc58b103c40f1d534ba086f00bc30f2dd9fc3c","c0d28042a3cfefcf74c4ec3a6df1b28ccad66dee8ab9e576ccee83ca832dc150"],
 "departure:26":["74b735a41f761e8bae611d38bffc58b103c40f1d534ba086f00bc30f2dd9fc3c","92ce21c9462bcdb8cdbd8b78793d78f61f398a3260fb1a0fe5c1701e94b336a7"],
}

static func ids_for(values: Array) -> Array:
 return values.map(func(e):return e.get("id",""))

# docs/transition-pipeline.md §5 的测试侧只读助手：读进程内迁移日志（生产代码不带计数器）。
static func transition_log(g) -> Array:
 var log=g.get("_transition_log")
 return log.duplicate() if log is Array else []

static func transition_delta(g, before: Array) -> Array:
 var log=transition_log(g)
 return log.slice(before.size()) if log.size()>=before.size() else log

static func transition_kinds(delta: Array, prefix: String) -> Array:
 return delta.filter(func(kind):return String(kind).begins_with(prefix))

# docs/transition-pipeline.md §4：闭环 check 的扫描面。四组模式各自的正则；注释按 `#` 之后截断，
# `==` 以 `[^=]` 排除。返回 {counts: {"文件|函数|组": 次数}, sites: {key: ["文件:行:函数", ...]}}。
const TRANSITION_PATTERNS={
 "room":"(?:g\\.)?state\\.room\\s*=[^=]",
 "phase":"(?:g\\.)?state\\.phase\\s*=[^=]",
 "battle_end":"_finish_battle\\(|_finish_if_saturated\\(|_battle_end_reason\\(",
 "tower_restart":"_restart_tower\\(",
}

static func transition_core_files() -> Array:
 var result=[]
 var pending=["res://core"]
 while not pending.is_empty():
  var directory=String(pending.pop_back())
  var handle=DirAccess.open(directory)
  if handle==null: continue
  for name in handle.get_files():
   if String(name).ends_with(".gd"): result.append(directory+"/"+name)
  for name in handle.get_directories(): pending.append(directory+"/"+name)
 result.sort()
 return result

static func transition_scan() -> Dictionary:
 var compiled={}
 for group in TRANSITION_PATTERNS:
  var regex=RegEx.new()
  regex.compile(TRANSITION_PATTERNS[group])
  compiled[group]=regex
 var counts={};var sites={}
 var declaration=RegEx.new()
 declaration.compile("^\\s*(?:static\\s+)?func\\s+([A-Za-z_][A-Za-z0-9_]*)")
 for path in transition_core_files():
  var file=FileAccess.open(path,FileAccess.READ)
  if file==null: continue
  var lines=file.get_as_text().split("\n")
  var current="<file>"
  for index in range(lines.size()):
   var raw=String(lines[index])
   var code=raw.split("#")[0]
   var declared=declaration.search(code)
   if declared!=null: current=declared.get_string(1)
   for group in compiled:
    for hit in compiled[group].search_all(code):
     var key=path+"|"+current+"|"+group
     counts[key]=int(counts.get(key,0))+1
     if not sites.has(key): sites[key]=[]
     sites[key].append(path+":"+str(index+1)+":"+current)
 return {"counts":counts,"sites":sites}

# docs/transition-pipeline.md §4／§5 场景 07：写入点双向比对——扫描集 ⊆ 声明表 且 表内每一点都被
# 扫到；表外或未命中都打印 `文件:行:函数`。表内每项＝(文件, 函数, 组, 行数)。
# ③ 的 8 个函数＝契约 §1 的"8 个语义入口"（13 个引用点保留为同一批函数；收束后一个位点由
# "判定一行＋执行一行"两行承载，故行数大于 13，函数集不变）。
const TRANSITION_SITES=[
 {"file":"res://core/game.gd","func":"_apply_transition","group":"room","count":1},
 {"file":"res://core/game.gd","func":"_apply_transition","group":"phase","count":1},
 {"file":"res://core/game.gd","func":"_battle_end_reason","group":"battle_end","count":1},
 {"file":"res://core/game.gd","func":"_finish_battle","group":"battle_end","count":1},
 {"file":"res://core/game.gd","func":"_finish_if_saturated","group":"battle_end","count":4},
 {"file":"res://core/game.gd","func":"_start_round","group":"battle_end","count":2},
 {"file":"res://core/game.gd","func":"_enemy_phase","group":"battle_end","count":4},
 {"file":"res://core/game.gd","func":"dispatch","group":"battle_end","count":3},
 {"file":"res://core/game.gd","func":"_execute","group":"battle_end","count":2},
 {"file":"res://core/game.gd","func":"_end_turn","group":"battle_end","count":2},
 {"file":"res://core/game.gd","func":"_restart_tower","group":"tower_restart","count":1},
 {"file":"res://core/demo_exit.gd","func":"continue_run","group":"tower_restart","count":1},
 {"file":"res://core/prison.gd","func":"return_to_tower","group":"tower_restart","count":1},
 {"file":"res://core/prison.gd","func":"completed_turn","group":"tower_restart","count":1},
]
const TRANSITION_BATTLE_END_FUNCTIONS=["_battle_end_reason","_end_turn","_enemy_phase","_execute","_finish_battle","_finish_if_saturated","_start_round","dispatch"]

static func transition_write_sites_are_pinned(t) -> void:
 var scan=transition_scan()
 var counts=scan.counts
 var sites=scan.sites
 var table={}
 for entry in TRANSITION_SITES:
  table[String(entry.file)+"|"+String(entry.func)+"|"+String(entry.group)]=int(entry.count)
 var keys=counts.keys()
 keys.sort()
 var outside=[]
 for key in keys:
  if not table.has(key): outside.append(str(sites[key]))
 t.check(outside.is_empty(),"ARCH transition scan finds no write site outside the pinned table: "+str(outside))
 var missing=[]
 for key in table:
  var found=int(counts.get(key,0))
  if found!=table[key]: missing.append(key+" expected "+str(table[key])+" found "+str(found)+" "+str(sites.get(key,[])))
 t.check(missing.is_empty(),"ARCH every pinned transition write site is scanned at its declared size: "+str(missing))
 var owners=[]
 for key in keys:
  if not String(key).ends_with("|battle_end"): continue
  var owner=String(key).split("|")[1]
  if owner not in owners: owners.append(owner)
 owners.sort()
 t.check(owners==TRANSITION_BATTLE_END_FUNCTIONS,"ARCH every battle-end decision lives in the eight declared entries: "+str(owners))
 t.check(int(counts.get("res://core/game.gd|_apply_transition|room",0))==1 and int(counts.get("res://core/game.gd|_apply_transition|phase",0))==1,"ARCH state.phase and state.room have exactly one write site each: "+str([counts.get("res://core/game.gd|_apply_transition|room",0),counts.get("res://core/game.gd|_apply_transition|phase",0)]))

# docs/save-fixed-points.md §2：进度固定点集合＝声明表里标了 checkpoint 列的 kind（固定清单，
# 多标一个或少标一个都红），且每个 checkpoint 名字都必须出现在 CHECKPOINT_PRIORITY 里。
const SAVE_CHECKPOINT_KINDS={
 "battle_end_captured":"battle_end",
 "battle_end_saturated":"battle_end",
 "battle_end_victory":"battle_end",
 "floor_enter":"floor",
 "prepare_end":"prepare_end",
}

static func save_checkpoint_kinds_are_pinned(t) -> void:
 var declared={}
 var wrong=[]
 for kind in GameCore.TRANSITIONS:
  var point=String(GameCore.TRANSITIONS[kind].get("checkpoint",""))
  if point=="": continue
  declared[kind]=point
  if point not in ["battle_end","prepare_end","floor"]: wrong.append(kind+"->"+point)
 t.check(wrong.is_empty(),"ARCH every declared fixed point uses a legal checkpoint name: "+str(wrong))
 var missing=[]
 for kind in SAVE_CHECKPOINT_KINDS:
  if not declared.has(kind) or declared[kind]!=SAVE_CHECKPOINT_KINDS[kind]: missing.append(kind+"->"+str(declared.get(kind,"<missing>")))
 var extra=[]
 for kind in declared:
  if not SAVE_CHECKPOINT_KINDS.has(kind): extra.append(kind+"->"+declared[kind])
 t.check(missing.is_empty(),"ARCH every pinned fixed-point kind stays declared with its own checkpoint name: "+str(missing))
 t.check(extra.is_empty(),"ARCH no transition kind beyond the three fixed points is marked as one: "+str(extra))
 t.check(declared.size()==SAVE_CHECKPOINT_KINDS.size(),"ARCH the fixed-point declaration set keeps the pinned size: "+str(declared.size()))
 var names=[]
 for kind in declared:
  if not names.has(declared[kind]): names.append(declared[kind])
 names.sort()
 var priority=Array(GameCore.CHECKPOINT_PRIORITY).duplicate()
 priority.sort()
 t.check(names==priority,"ARCH the simultaneous-hit priority resolves exactly the declared checkpoint names: "+str(names)+"/"+str(priority))

# docs/event-pipeline-dependency-spec.md §1／§4.2: the event modules preload exactly the
# declared registry edges; one edge more or less fails, and no core file may reach ui/.
static func event_dependency_edges_pinned(t) -> void:
 var expected={"res://core/room_events.gd":["res://data/room_events.gd","res://data/relics.gd"],"res://core/content_catalog.gd":[],"res://core/snapshot.gd":["res://data/phases.gd"]}
 var pattern=RegEx.new()
 pattern.compile("preload\\(\"res://[^\"]+\"\\)")
 for path in expected:
  var file=FileAccess.open(path,FileAccess.READ)
  t.check(file!=null,"ARCH event module is readable for its dependency edges "+path)
  if file==null: continue
  var found=[]
  for hit in pattern.search_all(file.get_as_text()):
   var target=hit.get_string().trim_prefix("preload(\"").trim_suffix("\")")
   if target not in found: found.append(target)
  found.sort()
  var want=expected[path].duplicate();want.sort()
  t.check(found==want,"ARCH event dependency edges pinned "+path+": "+str(found))
 var ui_pattern=RegEx.new()
 ui_pattern.compile("ui/")
 for path in expected:
  var file=FileAccess.open(path,FileAccess.READ)
  if file==null: continue
  t.check(ui_pattern.search(file.get_as_text())==null,"ARCH core event module never names ui/ "+path)

# docs/event-pipeline-dependency-spec.md §4.2: nodes and options are reachable only through
# definition／node／node_ids; legacy keys return empty instead of raising.
static func event_definition_accessors_only(t) -> void:
 var g=Game.new(42)
 var events=g.Events
 var legacy_keys=["stages","start_stage","choices"]
 t.check(events.definition("no_such_event_for_accessor_check").is_empty() and events.definition("").is_empty(),"ARCH definition accessor returns empty for unknown ids")
 t.check(events.node({},"choice").is_empty() and events.node_ids({}).is_empty(),"ARCH node accessors tolerate an empty definition")
 t.check(not events.definition("floating_belt_cluster").is_empty(),"ARCH definition accessor resolves a shipped event")
 for id in g.Events.Data.TYPES:
  var spec=events.definition(id)
  t.check(spec==g.Events.Data.TYPES[id] and spec.has("start_node") and spec.nodes is Array and not spec.nodes.is_empty(),"ARCH definition accessor returns the authored node form "+id)
  for legacy in legacy_keys:
   t.check(spec.get(legacy)==null,"ARCH compiled definition exposes no legacy key "+legacy+" "+id)
   t.check(events.node(spec,legacy).is_empty(),"ARCH node accessor returns empty for the legacy key "+legacy+" "+id)
  var ids=events.node_ids(spec)
  t.check(ids.size()==spec.nodes.size() and spec.start_node in ids and ids.all(func(node_id):return node_id is String and node_id!=""),"ARCH node_ids enumerates every authored node "+id)
  for node_id in ids:
   var entry=events.node(spec,node_id)
   t.check(not entry.is_empty() and entry.id==node_id and entry.choices is Array and not entry.choices.is_empty(),"ARCH node accessor returns the authored node "+id+"/"+node_id)
  t.check(events.node(spec,"no_such_node_"+id).is_empty(),"ARCH node accessor returns empty for an unknown node id "+id)

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

# docs/event-pipeline-unification.md §10 scenario 05 / dependency spec §4.2: the state
# condition kinds come from one declaration, and the three consumers agree on them.
static func event_condition_kinds_share_one_declaration(t) -> void:
 var g=Game.new(42)
 var events=g.Events
 var kinds=events.condition_kinds()
 t.check(kinds.size()==2 and "has_relic" in kinds and "no_chastity_lock" in kinds,"EVENT KINDS declaration table lists the supported state conditions")
 for kind in kinds:
  var entry={"kind":kind,"reason":"条件不成立。"}
  if kind=="has_relic": entry.type="softened_buckle"
  t.check(events.condition_issue(g,entry,{"relic":g.Relics.TYPES})=="","EVENT KINDS content validation accepts the declared fields: "+kind)
  t.check(events.condition_saved_fields(kind)==["kind","reason"]+Array(events.CONDITIONS[kind].required),"EVENT KINDS save key set derives from the declaration: "+kind)
  var probe=events.condition_probe(g,entry)
  t.check(probe is bool,"EVENT KINDS runtime evaluation answers every declared kind: "+kind)
 var unknown={"kind":"unknown_condition","reason":"条件不成立。"}
 t.check(events.condition_issue(g,unknown,{"relic":g.Relics.TYPES})!="","EVENT KINDS content validation rejects an unknown kind")
 var saved=g.state.room_event.duplicate(true)
 g.state.room_event={"id":"binding_cleric","stage":"service","options":[{"id":"probe","label":"夹具","detail":"","reward":"none","effects":[],"conditions":[{"kind":"unknown_condition","reason":"条件不成立。","mode":"optional"}]}],"refs":{},"values":{},"report":"","reward":[],"winner":-1,"relic":"","flow":true,"held":{},"cleanup_effects":[],"next_stage":"","result_status":"neutral"}
 t.check(g.validate()!="" or g.Snapshot.check(g.export_snapshot(),g)!="","EVENT KINDS save validation rejects an unknown kind")
 g.state.room_event=saved

# docs/event-pipeline-unification.md §10 scenario 13: every read path is read-only.
static func event_probe_and_projection_readonly(t) -> void:
 for id in ["floating_belt_cluster","binding_cleric","succubus_three_games"]:
  var g=Game.new(42)
  g.Events.start(g,id)
  var before=g.export_snapshot()
  var rng=g.state.rng.duplicate(true)
  var logs=g.state.logs.size()
  var version=g.state.version
  g.get_view();g.candidates()
  for option in g.state.room_event.options:
   g.Events.evaluate_option(g,g.Events.request_for(g,option,"candidate"))
   g.Events.evaluate_option(g,g.Events.request_for(g,option,"probe"))
  g.Events.selector_values(g,{"kind":"restraint"})
  g.Events.selector_values(g,{"kind":"card"})
  t.check(g.export_snapshot()==before and g.state.rng==rng and g.state.logs.size()==logs and g.state.version==version,"EVENT READONLY projection and evaluation do not mutate: "+id)

# docs/event-pipeline-dependency-spec.md §4.2: one evaluation entry owns the decisions, so
# re-reading candidates never re-freezes and matches a direct entry call.
static func event_single_evaluation_entry(t) -> void:
 for id in ["floating_belt_cluster","binding_cleric","succubus_three_games","mysterious_woman_statue","enchanters_empty_studio"]:
  var g=Game.new(42)
  g.Events.start(g,id)
  if g.state.room_event.stage=="result": continue
  var before=g.export_snapshot()
  var candidates=g.candidates().filter(func(c):return c.payload.get("action","")=="choose")
  t.check(g.export_snapshot()==before,"EVENT ENTRY candidate support never freezes or consumes random: "+id)
  for candidate in candidates:
   var option=g.state.room_event.options.filter(func(o):return o.id==candidate.payload.get("choice",""))
   if option.is_empty(): continue
   var result=g.Events.evaluate_option(g,g.Events.request_for(g,option[0],"candidate"))
   t.check(candidate.valid==(result.decision=="generated") and (result.reason=="" or candidate.get("reason","")!=""),"EVENT ENTRY candidate support matches the single entry: "+id+"/"+str(candidate.payload.get("choice","")))

static func run(t) -> void:
 event_dependency_edges_pinned(t)
 transition_write_sites_are_pinned(t)
 save_checkpoint_kinds_are_pinned(t)
 event_condition_kinds_share_one_declaration(t)
 event_probe_and_projection_readonly(t)
 event_single_evaluation_entry(t)
 event_definition_accessors_only(t)
 tool_registry_boundary(t)
 equipment_read_batches(t)
 index_materializes_once_per_scope(t)
 index_id_edge_parity(t)
 index_predicate_parity(t)
 index_entry_parity(t)
 index_self_check_falls_back(t)
 copy_projection_masked_baseline(t)
 copy_single_entry_matches_projection(t)
 copy_route_bytes_unchanged(t)
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
 # Count only this window: earlier read-only entries (plan/offer/contact calls) legitimately
 # opened and released scopes of their own during construction.
 g.piece_builds=0;g.slot_builds=0;g.id_builds=0;g.capacity_builds=0;g.physical_builds=0
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

# Batch B8 (§11 scenario 4): presence and count predicates keep their §5 values on the indexed
# read path, including the hand truth table and the non-authoritative capacity argument.
static func index_predicate_parity(t) -> void:
 var cases=[]
 var single=Game.new(42)
 single.state.equipment.clear()
 single.add_fixture("palm",4,10).side="left"
 cases.append({"label":"single-sided palm","game":single,"slot":"palm","occupied":false,"left":true,"right":false})
 var both=Game.new(42)
 both.state.equipment.clear()
 both.add_fixture("palm",4,10).side="left"
 both.add_fixture("fingers",4,10).side="right"
 cases.append({"label":"separate hand sides","game":both,"slot":"palm","occupied":false,"left":true,"right":false})
 var sideless=Game.new(42)
 sideless.state.equipment.clear()
 sideless.add_fixture("fingers",4,10)
 cases.append({"label":"side-less hand piece","game":sideless,"slot":"fingers","occupied":true,"left":true,"right":true})
 for kind in ["component_links","special_equipment","shoulder_links"]:
  cases.append({"label":kind,"game":Game.new(42,true,kind)})
 for entry in cases:
  var g=entry.game
  var reference=UncachedGame.new(42);reference.state=g.state.duplicate(true)
  var before=g.export_snapshot()
  var previous=g._begin_equipment_read()
  var parity=true
  for slot in g.B.SLOTS:
   parity=parity and g.occupied(slot)==reference.occupied(slot)
   for side in ["left","right"]: parity=parity and g.hand_blocked(slot,side)==reference.hand_blocked(slot,side)
   parity=parity and g.capacity_used(slot)==reference.capacity_used(slot)
  for point in g.Equipment.ANATOMY: parity=parity and g._point_count(point)==reference._point_count(point)
  parity=parity and g._capacity_issue(g.physical_pieces())==reference._capacity_issue(reference.physical_pieces())
  parity=parity and g._capacity_issue(g.physical_pieces()+g.state.equipment.duplicate())==reference._capacity_issue(reference.physical_pieces()+reference.state.equipment.duplicate())
  parity=parity and g._capacity_issue(g.state.equipment.slice(0,1))==reference._capacity_issue(reference.state.equipment.slice(0,1))
  if entry.has("slot"):
   parity=parity and g.occupied(entry.slot)==entry.occupied and g.hand_blocked(entry.slot,"left")==entry.left and g.hand_blocked(entry.slot,"right")==entry.right
  g._equipment_read=previous
  t.check(parity and g.export_snapshot()==before and g._equipment_read.is_empty(),"INDEX predicate parity with the live path "+entry.label)
 var dense=Game.new(42)
 dense.state.equipment.clear()
 for slot in dense.B.SLOTS: dense.add_fixture(slot,7,10)
 var dense_reference=UncachedGame.new(42);dense_reference.state=dense.state.duplicate(true)
 var dense_scope=dense._begin_equipment_read()
 var doubled=dense._capacity_issue(dense.physical_pieces()+dense.state.equipment.duplicate())
 t.check(doubled!="" and doubled==dense_reference._capacity_issue(dense_reference.physical_pieces()+dense_reference.state.equipment.duplicate()),"INDEX non-authoritative capacity argument keeps its live reason text: "+doubled)
 t.check(dense.capacity_used("wrist")==dense_reference.capacity_used("wrist") and dense.occupied("wrist") and dense.hand_blocked("wrist","left"),"INDEX dense counts and presence match the live path")
 dense._equipment_read=dense_scope

# Batch B9 (§11 scenario 5): every §3.1 outer entry opens and releases its own scope and answers
# exactly like the index-off reference; entries that swap state still leave no scope behind.
static func index_entry_parity(t) -> void:
 var g=IndexCountingGame.new(42)
 g.add_fixture("wrist",4,10)
 g.add_fixture("thigh",8,10)
 var reference=UncachedGame.new(42);reference.state=g.state.duplicate(true)
 var before=g.export_snapshot()
 var enemy=reference.state.enemies[0]
 # Each entry opens exactly one scope and releases it before returning.
 var opened=g.piece_builds
 var parity=ids_for(g.EnemyPlans.targets(g,enemy,"tighten"))==ids_for(reference.EnemyPlans.targets(reference,enemy,"tighten")) and g._equipment_read.is_empty() and g.piece_builds==opened+1
 opened=g.piece_builds
 parity=parity and ids_for(g.EnemyPlans.targets(g,enemy,"lock"))==ids_for(reference.EnemyPlans.targets(reference,enemy,"lock")) and g._equipment_read.is_empty() and g.piece_builds==opened+1
 opened=g.piece_builds
 parity=parity and g.Contact.workspace(g,"cut")==reference.Contact.workspace(reference,"cut") and g._equipment_read.is_empty() and g.piece_builds==opened+1
 opened=g.piece_builds
 parity=parity and g.Contact.workspace(g,"manual")==reference.Contact.workspace(reference,"manual") and g._equipment_read.is_empty() and g.piece_builds==opened+1
 opened=g.piece_builds
 var options=g.EquipmentOffers.ordinary(g)
 parity=parity and options==reference.EquipmentOffers.ordinary(reference) and g._equipment_read.is_empty() and g.piece_builds==opened+1
 opened=g.piece_builds
 parity=parity and g.EquipmentOffers.preferred(g,options)==reference.EquipmentOffers.preferred(reference,options) and g._equipment_read.is_empty() and g.piece_builds==opened+1
 opened=g.piece_builds
 parity=parity and g.EquipmentOffers.for_pool(g,2,["rope","belt"])==reference.EquipmentOffers.for_pool(reference,2,["rope","belt"]) and g._equipment_read.is_empty() and g.piece_builds==opened+1
 opened=g.piece_builds
 parity=parity and g.EquipmentOffers.links(g,2)==reference.EquipmentOffers.links(reference,2) and g._equipment_read.is_empty() and g.piece_builds==opened+1
 opened=g.piece_builds
 parity=parity and ids_for(g.Cards.SelfBinding.tighten_targets(g))==ids_for(reference.Cards.SelfBinding.tighten_targets(reference)) and g._equipment_read.is_empty() and g.piece_builds==opened+1
 opened=g.piece_builds
 parity=parity and g.Cards.SelfBinding.capacity(g)==reference.Cards.SelfBinding.capacity(reference) and g._equipment_read.is_empty() and g.piece_builds==opened+1
 opened=g.piece_builds
 parity=parity and g.Events.selector_values(g,{"kind":"restraint"})==reference.Events.selector_values(reference,{"kind":"restraint"}) and g._equipment_read.is_empty() and g.piece_builds==opened+1
 opened=g.piece_builds
 parity=parity and g.Events.selector_values(g,{"kind":"card"})==reference.Events.selector_values(reference,{"kind":"card"}) and g._equipment_read.is_empty() and g.piece_builds==opened
 opened=g.piece_builds
 parity=parity and g._prepare_assembly("glove","short","fixture")==reference._prepare_assembly("glove","short","fixture") and g._equipment_read.is_empty() and g.piece_builds==opened+1
 t.check(parity and g.export_snapshot()==before and g._equipment_read.is_empty(),"INDEX read-only entries answer like the live reference, open one scope each and release it")
 var compiled=g.Events.compile(g,"tighten_or_medium")
 var compiled_reference=reference.Events.compile(reference,"tighten_or_medium")
 t.check(compiled==compiled_reference and g.export_snapshot()==reference.export_snapshot() and g._equipment_read.is_empty(),"INDEX event compilation advances the same random domain and releases its scope")
 var captured=Game.new(42,true,"guard")
 captured.state.security=5
 Guard.capture(captured,captured.state.enemies[0])
 var prison_reference=UncachedGame.new(42);prison_reference.state=captured.state.duplicate(true)
 var opened_prison=captured._equipment_read
 var entered=captured.Prison.enter(captured)
 var entered_reference=prison_reference.Prison.enter(prison_reference)
 t.check(entered==entered_reference and captured.export_snapshot()==prison_reference.export_snapshot() and captured._equipment_read.is_empty() and is_same(opened_prison,captured._equipment_read), "INDEX high security entry matches the live reference and releases its tail scope")
 var prison_validate=captured.validate()
 var prison_validate_reference=prison_reference.validate()
 t.check(prison_validate==prison_validate_reference and captured.Prison.validate(captured)==prison_reference.Prison.validate(prison_reference) and captured._equipment_read.is_empty(),"INDEX nested prison validation agrees with the live reference")

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

# docs/ondemand-copy.md §5.5: the six fixture sequence, constructed by name in this file.
static func copy_baseline_fixture(phase: String, count: int):
 var g=Game.new(42) if phase=="battle" else GameCore.new(42)
 if count>=12:
  for slot in g.B.SLOTS: g.add_fixture(slot,7,10)
 if count==26:
  for slot in g.B.SLOTS: g.add_fixture(slot,7,10)
  for slot in ["upper_arm","wrist","thigh"]: g.add_fixture(slot,7,10)
 return g

# §5.4 mask: delete only the declared keys, and report what was actually removed so the caller
# can demand "exactly the declared set, no more and no fewer".
static func copy_masked_projection(view: Dictionary, candidates: Array, declared: Dictionary) -> Dictionary:
 var removed={"card_texts":[],"card_instances":[],"candidate_detail":[]}
 for key in declared.card_texts:
  if view.card_texts.has(key): view.card_texts.erase(key);removed.card_texts.append(key)
 for key in declared.card_instances:
  if view.card_instances.has(key): view.card_instances.erase(key);removed.card_instances.append(key)
 for candidate in candidates:
  if declared.candidate_detail.has(candidate.id) and candidate.has("detail"):
   candidate.erase("detail");removed.candidate_detail.append(candidate.id)
 return removed

# §5.4 mask protocol in its on-demand form: the declared display set is recomputed here from the
# display entrances §1.2 lists (independent of View.build), and the narrowed projection must contain
# exactly that set, in registry order, with unchanged entries. The byte-for-byte comparison against the
# frozen baseline JSON stays in the build-directory oracle, which is the only place that has it.
static func copy_projection_masked_baseline(t) -> void:
 print("COPY MASK DECLARATION "+JSON.stringify({"card_texts":"S complement","card_instances":"non-hand uids","candidate_detail":"card group","view_keys":["deck_list"]}))
 for phase in ["battle","departure"]:
  for count in [0,12,26]:
   var key="%s:%d" % [phase,count]
   var g=copy_baseline_fixture(phase,count)
   var pieces=g.physical_pieces().size()
   t.check(pieces==count and g.state.equipment.size()==count and g.state.links.is_empty() and g.state.composites.is_empty() and g.state.special_equipment.is_empty() and g.validate()=="","COPY §5.5 fixture sequence holds for "+key)
   var candidates=g.candidates()
   var view=g.get_view()
   var shown=copy_display_set(g,candidates)
   var missing=shown.keys().filter(func(type):return not view.card_texts.has(type))
   var extra=view.card_texts.keys().filter(func(type):return not shown.has(type))
   t.check(missing.is_empty() and extra.is_empty(),"COPY card_texts holds exactly the display set S "+key+": missing="+str(missing.slice(0,3))+" extra="+str(extra.slice(0,3)))
   var registry=g.Cards.Rules.SPECS.keys()
   var order=view.card_texts.keys()
   var positions=order.map(func(type):return registry.find(type))
   var sorted_positions=positions.duplicate()
   sorted_positions.sort()
   t.check(positions==sorted_positions and view.card_texts.size()<registry.size(),"COPY narrowed card_texts keeps registry key order without every type "+key)
   var entry_mismatch=order.filter(func(type):return view.card_texts[type]!=g.live_card_text(type))
   t.check(entry_mismatch.is_empty(),"COPY narrowed entries still equal the single read entry "+key+": "+str(entry_mismatch.slice(0,3)))
   var hand_uids=g.state.hand.map(func(card):return card.uid)
   var foreign=view.card_instances.keys().filter(func(uid):return not hand_uids.has(uid))
   t.check(foreign.is_empty(),"COPY card_instances only carries hand uids "+key+": "+str(foreign.slice(0,3)))
   t.check(not view.has("deck_list"),"COPY deck_list left the View "+key)

# 独立重算 S（§1.2 的显示入口），供 mask 声明与 View 断言比对。
static func copy_display_set(g, candidates: Array) -> Dictionary:
 var shown={}
 for card in g.state.hand: shown[card.type]=true
 for type in g.state.reward_options: shown[type]=true
 for type in g.state.rest_cards: shown[type]=true
 for candidate in candidates:
  var type=String(candidate.payload.get("type",""))
  if g.Cards.Rules.SPECS.has(type): shown[type]=true
 for row in g.Services.view(g).get("stock",[]):
  if row.get("kind","")=="card": shown[String(row.get("type",""))]=true
 for selection in g.Events.view(g).get("selections",[]):
  if selection.get("kind","")!="card": continue
  for option in selection.get("options",[]):
   var selected=option.get("selected",{})
   var type=String(selected.get("type",option.get("type","")))
   if g.Cards.Rules.SPECS.has(type): shown[type]=true
 return shown

# §5.2 card half while the set is not narrowed yet: every registered type is still projected, the
# single entry equals that projection field by field, the hand instance rows answer the same way and
# each call hands back an isolated container without touching state or the turn version.
static func copy_single_entry_matches_projection(t) -> void:
 var g=copy_baseline_fixture("battle",12)
 preload("res://tests/curse_cases.gd").give(g,"hannya_1")
 var before=g.state.duplicate(true)
 var view=g.get_view()
 var mismatched=[]
 for type in g.Cards.Rules.SPECS:
  if view.card_texts.has(type) and g.live_card_text(type)!=view.card_texts[type]: mismatched.append(type)
 t.check(mismatched.is_empty() and not view.card_texts.is_empty(),"COPY single entry equals the projected card text for every displayed type: "+str(mismatched.slice(0,5)))
 # §5.2 按需 == 全量：全部注册牌型在三个入口上逐字段相等；S 内的键必须在视图里，S 外的键不得出现。
 var full_mismatch=[]
 var shown=copy_display_set(g,g.candidates())
 for type in g.Cards.Rules.SPECS:
  var single=g.live_card_text(type)
  if single!=g.live_card_text_set([{"type":type}]).texts.get(type,{}): full_mismatch.append("set "+type)
  if view.card_texts.has(type)!=shown.has(type): full_mismatch.append("scope "+type)
  elif shown.has(type) and view.card_texts[type]!=single: full_mismatch.append("value "+type)
 t.check(full_mismatch.is_empty(),"COPY single entry, full entry and the projected entry agree for every registered type: "+str(full_mismatch.slice(0,5)))
 var instances=[];var extra={}
 for card in g.state.hand:
  if not view.card_instances.has(card.uid): continue
  var entry=g.live_card_text(card.type,card.uid)
  var stored=view.card_instances[card.uid]
  for key in stored:
   if not entry.has(key) or entry[key]!=stored[key]: instances.append(card.uid+"#"+str(key))
  var added=entry.keys().filter(func(key):return not stored.has(key))
  added.sort()
  extra[card.uid]=added
  # The projected instance row carries the two-step pair; the single entry is the four-step entry
  # (§1.1), so its only additions may be the face costs and, for casting cards, the cast block.
  if not ("face_costs" in added) or not added.all(func(key):return key in ["casting","face_costs"]): instances.append(card.uid+"#extra"+str(added))
 t.check(instances.is_empty() and not view.card_instances.is_empty(),"COPY single entry keeps every projected instance field and adds only the face costs and casting of its own four-step entry: "+str(instances.slice(0,3))+" "+str(extra))
 var fresh=g.live_card_text("strain")
 fresh.face_effects.bound="changed"
 t.check(g.live_card_text("strain").face_effects.bound!="changed","COPY single entry returns a fresh container on every call")
 t.check(g.state==before and g.state.version==view.version,"COPY single entry leaves state, random domains and turn version unchanged")

# §6 scenario 7 in its R0 form and §11.5 R0: no producer is migrated in this batch, so the direct
# string channel must return every producer string byte for byte, the candidate entry must equal the
# projected detail, the registered kinds must render exactly like their own builders, and the router
# must record nothing until something really is unknown.
static func copy_route_bytes_unchanged(t) -> void:
 var router=preload("res://core/copy_router.gd")
 var catalog=preload("res://data/encyclopedia.gd")
 t.check(router.categories()==["card.catalog","card.face","card.face_text","card.target","card.two_face","consumables.description","demo_exit.continue","demo_exit.end","departure.description","departure.finish","departure.skip","event.choice","event.prepare","event.reward_skip","game.attack","game.attack_release","game.calm","game.depart","game.end_climax","game.end_turn","game.finish_pack","game.finish_prepare","game.finish_rest","game.hook","game.item_cut","game.item_discard","game.item_door_lock","game.item_escape","game.item_install","game.item_retrieve","game.item_unlock","game.manual_collar","game.manual_release","game.manual_retrieve","game.posture","game.posture_wall","game.rest_begin","game.rest_card","game.rest_flask","game.rest_rare","game.retain","game.retain_skip","game.reward_flask","game.reward_item","game.reward_item_skip","game.reward_other","game.reward_relic","game.reward_skip","game.reward_skip_category","game.status_toggle","game.surrender","game.travel_step","game.wall_move","mana_flask.deposit","mana_flask.withdraw","prison.door_exit","prison.enter","prison.inspection","prison.key","prison.resist","prison.unlock_door","prison.vent_exit","prison.vent_kick","prison_space.explore_blind","prison_space.explore_site","relic_bundle.claim","relic_bundle.finish","relic_bundle.skip","service.leave","service.offer","service.release_job","service.remove_card","witch.attack","witch.card_log"],"COPY ROUTER enumerates its registered categories: "+str(router.categories()))
 for phase in ["battle","departure"]:
  for count in [0,12,26]:
   var key="%s:%d" % [phase,count]
   var g=copy_baseline_fixture(phase,count)
   var before=g.state.duplicate(true)
   var candidates=g.candidates()
   var direct=[];var projected=[]
   for candidate in candidates:
    # B3: the card group carries no detail; the on-demand entry is the value to compare everywhere.
    var detail=g.candidate_detail(candidate)
    if router.text(g,detail)!=detail: direct.append(candidate.payload.get("kind","")+"#"+candidate.id)
    if candidate.payload.get("kind","")=="card":
     if candidate.has("detail"): projected.append("stray "+candidate.id)
    elif detail!=candidate.detail: projected.append(candidate.payload.get("kind","")+"#"+candidate.id)
   t.check(direct.is_empty(),"COPY direct string channel returns the producer text unchanged "+key+": "+str(direct.slice(0,3)))
   t.check(projected.is_empty(),"COPY candidate_detail returns the projected detail for every candidate "+key+": "+str(projected.slice(0,3)))
   t.check(g.copy_router_failures.is_empty() and g.state==before,"COPY routing records no failure and changes no state "+key)
 var sample=copy_baseline_fixture("battle",12)
 var reference=sample.candidates()
 var stripped=reference.duplicate(true)
 var card_group=0
 var recomputed=[]
 for i in range(stripped.size()):
  if reference[i].payload.get("kind","")!="card": continue
  card_group+=1
  if reference[i].has("detail"): recomputed.append("stray "+reference[i].id)
  if sample.candidate_detail(reference[i])=="": recomputed.append("empty "+reference[i].id)
 t.check(card_group>0 and recomputed.is_empty(),"COPY card candidates recompute on demand and carry no projected detail: "+str(recomputed.slice(0,3)))
 var g2=copy_baseline_fixture("battle",12)
 var g2_before=g2.state.duplicate(true)
 var kind_mismatch=[];var fragment_mismatch=[]
 for type in g2.Cards.Rules.SPECS:
  var args={"type":type}
  if router.entry(g2,{"kind":"card.face","args":args,"fallback":{}})!=g2.Cards.text_entry(g2,type): kind_mismatch.append("card.face "+type)
  if router.entry(g2,{"kind":"card.catalog","args":args,"fallback":{}})!=catalog.card(type): kind_mismatch.append("card.catalog "+type)
  if router.two_face(g2,type)!=g2.Cards.face_text(g2,type,false)+"\n"+g2.Cards.face_text(g2,type,true): fragment_mismatch.append(type)
 t.check(kind_mismatch.is_empty(),"COPY ROUTER registered kinds render exactly like their own builders: "+str(kind_mismatch.slice(0,3)))
 t.check(fragment_mismatch.is_empty(),"COPY ROUTER two_face fragment equals the producer expression: "+str(fragment_mismatch.slice(0,3)))
 var failures=g2.copy_router_failures.size()
 var fallback=router.text(g2,{"kind":"missing.kind","args":{},"fallback":"保留原文案"})
 t.check(fallback=="保留原文案" and g2.copy_router_failures.size()==failures+1 and g2.copy_router_failures[-1].kind=="missing.kind","COPY ROUTER unknown kind returns its fallback and records it")
 var blank=router.text(g2,{"kind":"missing.kind","args":{}})
 t.check(blank=="" and g2.copy_router_failures.size()==failures+2,"COPY ROUTER unknown kind without a fallback returns an empty string and still records it")
 var refused=router.text(g2,{"kind":"card.face","args":{"type":"strain"},"fallback":"回退"})
 t.check(refused=="回退" and g2.copy_router_failures.size()==failures+3 and g2.copy_router_failures[-1].stage=="result","COPY ROUTER refuses a dictionary result on the string entry and records it")
 t.check(router.failures(g2).size()==failures+3 and g2.state==g2_before,"COPY ROUTER diagnostics stay on the instance and never touch state")
 copy_migrated_kinds(t,router)

# §11.5 R1/R2/R3: every migrated kind must render exactly like the producer expression it replaced.
# The descriptor carries a sentinel fallback, so a fallback return (unknown kind, invalid builder or a
# wrong result type) shows up as a mismatch instead of hiding behind identical text.
static func copy_migrated_kinds(t,router) -> void:
 var sentinel="COPY-SENTINEL"
 var flask=copy_baseline_fixture("battle",0)
 flask.state.mana=50.0;flask.state.flask_mana=8.0;flask.state.flask_deposits=1
 t.check(router.text(flask,{"kind":"mana_flask.deposit","args":{"amount":10.0,"remaining":1},"fallback":sentinel})==copy_candidate(flask,"flask","deposit").get("detail",""),"COPY R1 mana_flask.deposit renders like the deposit candidate")
 t.check(router.text(flask,{"kind":"mana_flask.withdraw","args":{"drawn":8.0,"restored":8.0},"fallback":sentinel})==copy_candidate(flask,"flask","withdraw").get("detail",""),"COPY R1 mana_flask.withdraw renders like the withdraw candidate")
 var exit_game=copy_baseline_fixture("battle",0)
 preload("res://tests/demo_exit_cases.gd").exit_fixture(exit_game)
 t.check(router.text(exit_game,{"kind":"demo_exit.end","args":{},"fallback":sentinel})==copy_candidate(exit_game,"demo_end","").get("detail",""),"COPY R1 demo_exit.end renders like the exit candidate")
 t.check(router.text(exit_game,{"kind":"demo_exit.continue","args":{"next_cycle":1},"fallback":sentinel})==copy_candidate(exit_game,"demo_continue","").get("detail",""),"COPY R1 demo_exit.continue renders like the continuation candidate")
 t.check(flask.copy_router_failures.is_empty() and exit_game.copy_router_failures.is_empty(),"COPY R1 migrated kinds are all registered and record no failure")
 # R2: 三处两面拼接改走共享片段，产出的候选必须逐字节等于 two_face。
 var reward_game=copy_baseline_fixture("battle",0)
 reward_game.state.phase="reward";reward_game.state.reward_options=["strain","brace"];reward_game.state.reward_claimed={}
 var event_game=copy_baseline_fixture("battle",0)
 event_game.state.phase="event"
 preload("res://core/room_events.gd").start(event_game,preload("res://data/room_events.gd").pool()[0])
 event_game.state.room_event.stage="reward";event_game.state.room_event.reward=["strain","brace"]
 var shop_game=GameCore.new(42,true,"shop")
 var stock=shop_game.room_data(shop_game.state.room).stock
 stock.append({"kind":"card","type":"strain","price":40,"taken":false})
 var two_face_mismatch=[];var two_face_seen={"reward":0,"event":0,"service":0}
 for candidate in reward_game.candidates():
  if candidate.payload.get("kind","")!="reward" or candidate.payload.get("category","")!="card": continue
  two_face_seen.reward+=1
  if candidate.detail!=router.two_face(reward_game,String(candidate.payload.type)): two_face_mismatch.append("reward "+candidate.id)
 for candidate in event_game.candidates():
  if candidate.payload.get("kind","")!="event" or candidate.payload.get("action","")!="reward" or candidate.payload.get("type","")=="skip": continue
  two_face_seen.event+=1
  if candidate.detail!=router.two_face(event_game,String(candidate.payload.type)): two_face_mismatch.append("event "+candidate.id)
 for candidate in shop_game.candidates():
  if candidate.payload.get("kind","")!="service" or candidate.payload.get("op","")!="take": continue
  var offer=stock[int(candidate.payload.index)]
  if offer.kind!="card": continue
  two_face_seen.service+=1
  if candidate.detail!=router.two_face(shop_game,String(offer.type)): two_face_mismatch.append("service "+candidate.id)
 t.check(two_face_seen.reward>0 and two_face_seen.event>0 and two_face_seen.service>0 and two_face_mismatch.is_empty(),"COPY R2 reward, event and shop card texts use the shared two-face fragment: "+JSON.stringify(two_face_seen)+" "+str(two_face_mismatch.slice(0,3)))
 # R3a: card 目标候选经路由的渲染加上共用组装，必须逐字节等于包装产出的值。
 var target_game=copy_baseline_fixture("battle",12)
 var target_mismatch=[];var target_seen=0
 for candidate in target_game.candidates():
  if candidate.payload.get("kind","")!="card": continue
  target_seen+=1
  var base=router.text(target_game,{"kind":"card.target","args":{"payload":candidate.payload},"fallback":sentinel})
  var assembled=target_game._candidate_detail(base,candidate.payload,target_game.Cards.magic_card_traction(target_game,candidate.payload),candidate.mana_payment)
  if assembled!=target_game.candidate_detail(candidate): target_mismatch.append(candidate.id)
 t.check(target_seen>0 and target_mismatch.is_empty() and target_game.copy_router_failures.is_empty(),"COPY R3a card.target renders like the wrapper for every card candidate: "+str(target_seen)+" "+str(target_mismatch.slice(0,3)))
 # R3b: paid_candidate 的三个站点经路由渲染必须逐字节等于候选值。
 var paid_mismatch=[];var paid_seen={"offer":0,"release":0,"remove":0}
 for candidate in shop_game.candidates():
  if candidate.payload.get("kind","")!="service" or candidate.payload.get("op","")!="take": continue
  paid_seen.offer+=1
  if router.text(shop_game,{"kind":"service.offer","args":{"offer":stock[int(candidate.payload.index)]},"fallback":sentinel})!=candidate.detail: paid_mismatch.append("offer "+candidate.id)
 var release_game=GameCore.new(42,true,"shop")
 release_game.add_fixture("wrist",8,10)
 var release_jobs=release_game.Services.release_jobs(release_game)
 var release_candidate=copy_candidate(release_game,"service","release")
 paid_seen.release+=1
 if release_jobs.is_empty() or router.text(release_game,{"kind":"service.release_job","args":{"job":release_jobs[0]},"fallback":sentinel})!=release_candidate.get("detail",""): paid_mismatch.append("release")
 var remove_game=GameCore.new(42,true,"shop")
 remove_game.state.shop_removals=3
 var remove_candidate=copy_candidate(remove_game,"service","remove")
 paid_seen.remove+=1
 if remove_candidate.is_empty() or router.text(remove_game,{"kind":"service.remove_card","args":{},"fallback":sentinel})!=remove_candidate.get("detail",""): paid_mismatch.append("remove")
 t.check(paid_seen.offer>0 and paid_mismatch.is_empty(),"COPY R3b service.offer, release_job and remove_card render like the paid candidates: "+JSON.stringify(paid_seen)+" "+str(paid_mismatch.slice(0,3)))
 # R3c: Prison.add 的九个站点经路由渲染必须逐字节等于候选值。
 var prison_mismatch=[];var prison_seen=0
 for entry in [["captured","prison.enter","enter",{}],["inspection","prison.inspection","inspect",{}],["inspection","prison.resist","resist",{}],["room","prison.vent_kick","vent_kick",{}],["room","prison.vent_exit","vent_exit",{}],["room","prison.key","key",{}],["room","prison.door_exit","door_exit",{}],["blind","prison_space.explore_blind","explore",{}]]:
  var g=copy_baseline_fixture("battle",0)
  g.state.security=2
  match entry[0]:
   "captured": g.state.phase="captured"
   "inspection": g.state.phase="inspection";g.state.prison.stage="arrival"
   "room": g=GameCore.new(42,true,"prison_test")
   "blind": g=GameCore.new(42,true,"prison_test");g.add_fixture("eyes",4)
  var candidate=copy_candidate(g,"prison",entry[2])
  prison_seen+=1
  var args=entry[3]
  match entry[1]:
   "prison.enter": args={"security":g.state.security}
   "prison.inspection": args={"stage":g.state.prison.stage}
   "prison_space.explore_site": args={"distance":g.wall_movement_profile().distance,"cost":g.wall_movement_profile().cost}
  if candidate.is_empty() or router.text(g,{"kind":entry[1],"args":args,"fallback":sentinel})!=candidate.get("detail",""): prison_mismatch.append(entry[1]+"/"+entry[0])
 var explore_game=GameCore.new(42,true,"prison_test")
 var explore_candidate=copy_candidate(explore_game,"prison","explore")
 prison_seen+=1
 var explore_args={"distance":explore_game.wall_movement_profile().distance,"cost":explore_game.wall_movement_profile().cost}
 if explore_candidate.is_empty() or router.text(explore_game,{"kind":"prison_space.explore_site","args":explore_args,"fallback":sentinel})!=explore_candidate.get("detail",""): prison_mismatch.append("prison_space.explore_site/room")
 t.check(prison_seen==9 and prison_mismatch.is_empty(),"COPY R3c all nine Prison.add sites render like their candidates: "+str(prison_mismatch.slice(0,3)))
 copy_r4_sites(t,router,sentinel)
 copy_r6_sites(t,router,sentinel)
 copy_candidate_detail_on_demand(t)

# §11.5 R4: the direct call sites of the remaining modules render through the router as well.
static func copy_r4_sites(t,router,sentinel: String) -> void:
 var r4_mismatch=[];var r4_seen=0
 var choose=GameCore.new(42)
 var choose_candidate=copy_candidate(choose,"departure","choose")
 r4_seen+=1
 if choose_candidate.is_empty() or router.text(choose,{"kind":"departure.description","args":{"entry_id":String(choose_candidate.payload.get("option",""))},"fallback":sentinel})!=choose_candidate.get("detail",""): r4_mismatch.append("departure.description")
 r4_seen+=1
 if router.text(choose,{"kind":"departure.skip","args":{},"fallback":sentinel})!=copy_candidate(choose,"departure","skip").get("detail",""): r4_mismatch.append("departure.skip")
 r4_seen+=1
 if router.text(choose,{"kind":"departure.finish","args":{},"fallback":sentinel})!="选择第一层的入口。": r4_mismatch.append("departure.finish")
 var event_game=copy_baseline_fixture("battle",0)
 event_game.state.phase="event"
 preload("res://core/room_events.gd").start(event_game,preload("res://data/room_events.gd").pool()[0])
 var event_candidate=copy_candidate(event_game,"event","choose")
 r4_seen+=1
 if event_candidate.is_empty() or router.text(event_game,{"kind":"event.choice","args":{"option_id":String(event_candidate.payload.get("choice",""))},"fallback":sentinel})!=event_candidate.get("detail",""): r4_mismatch.append("event.choice")
 event_game.state.room_event.stage="result"
 var prepare_args={"prepare":bool(event_game.state.room_event.get("prepare_pending",false))}
 r4_seen+=1
 if router.text(event_game,{"kind":"event.prepare","args":prepare_args,"fallback":sentinel})!=copy_candidate(event_game,"event","leave").get("detail",""): r4_mismatch.append("event.prepare")
 var bundle_game=copy_baseline_fixture("battle",0)
 preload("res://core/relic_bundle.gd").start(bundle_game,"reward")
 var bundle_claim=copy_candidate(bundle_game,"relic_bundle","claim")
 r4_seen+=1
 if bundle_claim.is_empty() or router.text(bundle_game,{"kind":"relic_bundle.claim","args":{"relic_id":String(bundle_game.state.relic_bundle.entries[0].type)},"fallback":sentinel})!=bundle_claim.get("detail",""): r4_mismatch.append("relic_bundle.claim")
 r4_seen+=1
 if router.text(bundle_game,{"kind":"relic_bundle.skip","args":{},"fallback":sentinel})!=copy_candidate(bundle_game,"relic_bundle","skip").get("detail",""): r4_mismatch.append("relic_bundle.skip")
 r4_seen+=1
 if router.text(bundle_game,{"kind":"relic_bundle.finish","args":{},"fallback":sentinel})!=copy_candidate(bundle_game,"relic_bundle","finish").get("detail",""): r4_mismatch.append("relic_bundle.finish")
 var treasure_game=GameCore.new(42,true,"shop")
 treasure_game.room_data(treasure_game.state.room).kind="treasure"
 var treasure_stock=treasure_game.room_data(treasure_game.state.room).stock
 var treasure_candidate=copy_candidate(treasure_game,"service","take")
 var treasure_offer=treasure_stock[int(treasure_candidate.get("payload",{}).get("index",-1))] if not treasure_candidate.is_empty() else {}
 r4_seen+=1
 if treasure_candidate.is_empty() or router.text(treasure_game,{"kind":"service.offer","args":{"offer":treasure_offer},"fallback":sentinel})!=treasure_candidate.get("detail",""): r4_mismatch.append("service.offer/treasure")
 r4_seen+=1
 if router.text(treasure_game,{"kind":"service.leave","args":{},"fallback":sentinel})!=copy_candidate(treasure_game,"service","leave").get("detail",""): r4_mismatch.append("service.leave")
 var item_game=copy_baseline_fixture("battle",0)
 item_game.state.equipment.clear();item_game.add_fixture("wrist",8,10)
 item_game._gain_tool("mana_potion")
 var use_candidate={}
 for candidate in item_game.candidates():
  if candidate.payload.get("kind","")=="item_use" and candidate.payload.get("target","")=="hero": use_candidate=candidate;break
 r4_seen+=1
 if use_candidate.is_empty() or router.text(item_game,{"kind":"consumables.description","args":{"item_type":String(item_game._item(String(use_candidate.payload.get("item",""))).type)},"fallback":sentinel})!=use_candidate.get("detail",""): r4_mismatch.append("consumables.description")
 var witch_game=Game.new(42,false,"equipment",true,false,25,false,false,"witch")
 var witch_candidate={}
 for candidate in witch_game.candidates():
  if candidate.payload.get("kind","")=="attack" and candidate.payload.get("charge_action",false): witch_candidate=candidate;break
 r4_seen+=1
 if witch_candidate.is_empty():
  r4_mismatch.append("witch.attack")
 else:
  var witch_args={"part":witch_candidate.payload.get("part",""),"charge":true,"stacks":int(witch_game.state.witch_charges[String(witch_candidate.payload.get("part",""))]),"damage":float(witch_candidate.payload.get("damage",0.0)),"hits":int(witch_candidate.payload.get("hits",1)),"all_targets":bool(witch_candidate.payload.get("all",false)),"focus":0}
  var witch_assembled=witch_game._candidate_detail(router.text(witch_game,{"kind":"witch.attack","args":witch_args,"fallback":sentinel}),witch_candidate.payload,witch_game.Cards.magic_card_traction(witch_game,witch_candidate.payload),witch_candidate.mana_payment)
  if witch_assembled!=witch_candidate.detail: r4_mismatch.append("witch.attack")
 var door_game=GameCore.new(42,true,"prison_test")
 preload("res://tests/curse_cases.gd").give(door_game,"unlock")
 var door_candidate=copy_candidate(door_game,"prison","unlock")
 r4_seen+=1
 if door_candidate.is_empty() or router.text(door_game,{"kind":"prison.unlock_door","args":{"type":String(door_candidate.payload.get("type",""))},"fallback":sentinel})!=door_candidate.get("detail",""): r4_mismatch.append("prison.unlock_door")
 t.check(r4_seen==13 and r4_mismatch.is_empty(),"COPY R4 the remaining direct call sites render like their candidates: "+str(r4_mismatch.slice(0,4)))

# §11.5 R6: the two producers outside the View route their text through the router as well.
static func copy_r6_sites(t,router,sentinel: String) -> void:
 var cards=copy_baseline_fixture("battle",0)
 var face_mismatch=[];var face_seen=0
 for type in cards.Cards.Rules.SPECS:
  for side in [false,true]:
   face_seen+=1
   var args={"type":type,"free":side,"uid":""}
   if router.text(cards,{"kind":"card.face_text","args":args,"fallback":sentinel})!=cards.Cards.face_text(cards,type,side): face_mismatch.append(type+"#"+str(side))
 t.check(face_seen>0 and face_mismatch.is_empty(),"COPY R6 card.face_text renders like the module expression for every type and face: "+str(face_mismatch.slice(0,3)))
 var witch=Game.new(42,false,"equipment",true,false,25,false,false,"witch")
 preload("res://tests/curse_cases.gd").give(witch,"witch_patience")
 for candidate in witch.candidates():
  if String(candidate.payload.get("type",""))=="witch_patience" and candidate.valid:
   witch.dispatch(candidate.id,witch.state.version)
   break
 var logged=""
 for row in witch.state.logs:
  if String(row.get("data",{}).get("witch_card",""))!="": logged=String(row.get("text",""))
 var log_matched=false
 for type in witch.Cards.Rules.SPECS:
  for side in [false,true]:
   var log_args={"type":type,"free":side}
   if router.text(witch,{"kind":"witch.card_log","args":log_args,"fallback":sentinel})==logged and logged!="": log_matched=true
 t.check(log_matched,"COPY R6 witch.card_log renders like the emitted card log: "+logged)

# docs/ondemand-copy.md §6 场景 5（copy_candidate_detail_on_demand）：card 组不带 detail、按需入口
# 逐字节等于包装产出的值，其余组保持预生成；候选 ID 仍由 payload 决定，写路径不受影响。
static func copy_candidate_detail_on_demand(t) -> void:
 var g=copy_baseline_fixture("battle",12)
 var before=g.state.duplicate(true)
 var candidates=g.candidates()
 var mismatch=[];var card_group=0
 for candidate in candidates:
  var detail=g.candidate_detail(candidate)
  if candidate.payload.get("kind","")=="card":
   card_group+=1
   if candidate.has("detail"): mismatch.append("stray "+candidate.id)
   if detail=="": mismatch.append("empty "+candidate.id)
  elif detail!=candidate.detail: mismatch.append("eager "+candidate.payload.get("kind","")+"#"+candidate.id)
  if candidate.id!=JSON.stringify(candidate.payload).sha256_text().substr(0,24): mismatch.append("id "+candidate.id)
 t.check(card_group>0 and mismatch.is_empty(),"COPY scenario 5 card details are on demand and ids stay payload derived: "+str(mismatch.slice(0,3)))
 var played=0
 for candidate in candidates:
  if candidate.payload.get("kind","")!="card" or not candidate.valid: continue
  t.check(g.dispatch(candidate.id,g.state.version).ok and g.state.version>0,"COPY scenario 5 a card candidate still commits through dispatch")
  played+=1
  break
 t.check(played==1 and g.state!=before,"COPY scenario 5 write path unaffected by on-demand detail")

static func copy_candidate(g, kind: String, op: String) -> Dictionary:
 for candidate in g.candidates():
  if candidate.payload.get("kind","")!=kind: continue
  if op!="" and candidate.payload.get("action",candidate.payload.get("op",""))!=op: continue
  return candidate
 return {}
