extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Store=preload("res://core/save_store.gd")

static func same(a: Dictionary, b: Dictionary) -> bool:
 var aa=a.duplicate(true);var bb=b.duplicate(true)
 aa.erase("version");bb.erase("version")
 if aa!=bb:
  print("SAVE DIFF "+difference(aa,bb))
 return aa==bb

static func difference(a,b,where: String="state") -> String:
 if a is Dictionary and b is Dictionary:
  for key in a:
   if not b.has(key): return where+" missing "+str(key)
   if a[key]!=b[key]: return difference(a[key],b[key],where+"."+str(key))
  return where+" dictionary key/container types differ"
 if a is Array and b is Array:
  if a.size()!=b.size(): return where+" array size differs"
  for i in range(a.size()):
   if a[i]!=b[i]: return difference(a[i],b[i],where+"["+str(i)+"]")
  return where+" array container types differ"
 return where+": "+str(a)+" ("+str(typeof(a))+") vs "+str(b)+" ("+str(typeof(b))+")"

static func roundtrip(t, g, label: String):
 var before=g.export_snapshot()
 var packed=Store.pack(before)
 var result=Store.unpack(packed)
 t.check(result.ok,"SAVE readable "+label+": "+result.get("error",""))
 if not result.ok: return null
 var restored=g.get_script().new(0,false,"equipment",false)
 t.check(restored.restore_snapshot(result.snapshot).ok and same(before,restored.state),"SAVE exact restore "+label)
 t.check(g.state==before and restored.state.version>before.version,"SAVE readonly export and renewed version "+label)
 var old=restored.export_snapshot()
 restored.get_view();restored.candidates()
 t.check(restored.state==old,"SAVE restored projection readonly "+label)
 return restored

static func step_both(t,g,h,kind: String,extra: Dictionary={}) -> void:
 if h==null: return
 var a=t.action(g,kind,extra);var b=t.action(h,kind,extra)
 t.check(a.ok and b.ok and same(g.state,h.state),"SAVE next formal action matches uninterrupted run %s; live=%s restored=%s" % [kind,a,b])

static func revision_boundary(t) -> void:
 var g=Game.new(42)
 var before=g.export_snapshot()
 for revision in [null,Game.Snapshot.REVISION-1,Game.Snapshot.REVISION+1,"2"]:
  var saved=before.duplicate(true)
  if revision==null: saved.erase("save_revision")
  else: saved.save_revision=revision
  var restored=g.restore_snapshot(saved)
  var packed=Store.unpack(Store.pack(saved))
  t.check(not restored.ok and restored.get("code")=="version" and not packed.ok and packed.get("code")=="version","SAVE disk and direct restore reject unsupported revision without migration "+str(revision))
  t.check(g.export_snapshot()==before,"SAVE incompatible revision never partially restores "+str(revision))
 var prison=Game.new(42,true,"prison_test")
 var stable=prison.export_snapshot()
 for missing_pool in [true,false]:
  var invalid=stable.duplicate(true)
  if missing_pool: invalid.prison.erase("discovery_pool")
  else: invalid.prison.discovery_pool.append("return_seal");invalid.prison.discoveries.append("return_seal")
  t.check(not prison.restore_snapshot(invalid).ok and prison.export_snapshot()==stable,"SAVE obsolete discovery shapes rejected without filling defaults")

static func map_drawings(t) -> void:
 var g=Game.new(42);var snapshot=g.export_snapshot()
 var marks={"tower":[PackedVector2Array([Vector2(-0.1,0.5),Vector2(0.9,1.05)])],"prison":[]}
 var packed=Store.pack(snapshot,marks);var decoded=Store.unpack(packed)
 t.check(decoded.ok and decoded.map_drawings==marks and decoded.snapshot==snapshot and g.state==snapshot,"SAVE annotations roundtrip separately from game state with exact graph coordinates")
 var envelope=JSON.parse_string(packed)
 envelope.map_drawings="{}"
 t.check(not Store.unpack(JSON.stringify(envelope)).ok,"SAVE checksum protects map annotations together with gameplay")
 envelope.map_drawings=JSON.stringify({"tower":[[["broken",0]]]})
 envelope.checksum=(envelope.payload+envelope.map_drawings).sha256_text()
 t.check(not Store.unpack(JSON.stringify(envelope)).ok,"SAVE malformed annotation coordinates reject before loading")
 envelope.erase("map_drawings");envelope.checksum=envelope.payload.sha256_text()
 decoded=Store.unpack(JSON.stringify(envelope))
 t.check(decoded.ok and decoded.map_drawings.is_empty() and decoded.snapshot==snapshot,"SAVE current-format file without annotations remains readable")

# A frozen option carries its own state condition into the save, so every kind must
# keep its exact key set and an unknown or extra-keyed condition must never load.
static func event_conditions(t) -> void:
 var events=preload("res://tests/event_cases.gd")
 var g=Game.new(42)
 g.state.relics.append("softened_buckle")
 events.arrive(g,"floating_belt_cluster")
 var index=-1
 for i in range(g.state.room_event.options.size()):
  if g.state.room_event.options[i].get("id","")=="leave": index=i
 t.check(index>=0 and g.state.room_event.options[index].availability.kind=="has_relic","SAVE held-relic option keeps its own condition")
 if index<0: return
 var restored=roundtrip(t,g,"event option condition")
 if restored!=null:
  t.check(restored.state.room_event.options.any(func(option):return option.get("availability",{}).get("type","")=="softened_buckle"),"SAVE held-relic condition survives the roundtrip")
 var before=g.export_snapshot()
 for broken in [
  {"kind":"unknown_condition","reason":"条件不成立。"},
  {"kind":"has_relic","reason":"条件不成立。"},
  {"kind":"has_relic","type":"softened_buckle","reason":"条件不成立。","extra":true},
  {"kind":"has_relic","type":"unregistered_relic","reason":"条件不成立。"},
  {"kind":"no_chastity_lock","type":"softened_buckle","reason":"条件不成立。"},
 ]:
  var saved=before.duplicate(true)
  saved.room_event.options[index].availability=broken.duplicate(true)
  t.check(not g.restore_snapshot(saved).ok and g.export_snapshot()==before,"SAVE malformed option condition rejected atomically "+JSON.stringify(broken))

static func run(t) -> void:
 map_drawings(t)
 preload("res://tests/scene_restart_cases.gd").run(t,same)
 revision_boundary(t)
 event_conditions(t)
 t.check(Game.Snapshot.Phases.DEFINITIONS.values().all(func(stage):return stage.name!="" and stage.caption!=""),"SAVE every accepted phase has a homepage summary label")
 var sample_draw=Game.new(42)
 var unchanged=sample_draw.export_snapshot()
 for field in ["draw_serial","draw_free","point"]:
  var invalid=unchanged.duplicate(true)
  if field=="point": invalid.enemies[0].intent.point=123
  else: invalid.hand[0][field]="invalid"
  t.check(not sample_draw.restore_snapshot(invalid).ok and sample_draw.export_snapshot()==unchanged,"SAVE malformed draw/position field rejected atomically "+field)
 var g=Game.new(9223372036854775806)
 var h=roundtrip(t,g,"64-bit seed")
 step_both(t,g,h,"end")
 for kind in g.Tower.all_practices():
  var sample=Game.new(42,true,kind)
  roundtrip(t,sample,"practice "+kind)
 g=Game.new(42)
 var stale=g.candidates()[0];var version=g.state.version;var snapshot=g.export_snapshot()
 t.check(g.restore_snapshot(snapshot).ok and not g.dispatch(stale.id,version).ok,"SAVE old drag version invalid after in-place restore")
 for i in range(4): t.action(g,"end")
 h=roundtrip(t,g,"reward")
 step_both(t,g,h,"reward",{"type":g.state.reward_options[0]})
 step_both(t,g,h,"reward",{"type":"skip"})
 h=roundtrip(t,g,"prepare");step_both(t,g,h,"finish_prepare")
 h=roundtrip(t,g,"map");step_both(t,g,h,"depart",{"room":"west"})
 h=roundtrip(t,g,"travel");step_both(t,g,h,"travel_step")

 var Rewards=preload("res://tests/reward_cases.gd")
 g=Rewards.setup()
 var a=g.add_fixture("wrist",8,10,true);g.add_fixture("wrist",8,10,true);var c=g.add_fixture("wrist",8,10,true)
 var card=Rewards.give(t,g,"double_unlock")
 Rewards.play(t,g,card,"wrist",a.id)
 h=roundtrip(t,g,"pending second unlock")
 step_both(t,g,h,"chain",{"target":c.id})
 g=Rewards.setup();card=Rewards.give(t,g,"focus");Rewards.play(t,g,card,"thigh")
 t.check(g.state.pending_retain,"SAVE selective retain fixture enters a real pending choice")
 h=roundtrip(t,g,"pending selected retain and follow-up draw")
 step_both(t,g,h,"retain",{"uid":g.state.hand[0].uid})
 g=Rewards.setup();g.state.relics.append("break_bracer")
 a=g.add_fixture("wrist",1);g.add_fixture("wrist",1);c=g.add_fixture("wrist",1)
 card=Rewards.give(t,g,"chain")
 h=roundtrip(t,g,"before automatic removal and relic benefits")
 step_both(t,g,h,"card",{"uid":card.uid,"target":a.id})
 t.check(g.state.card_chain.is_empty() and g.state.charge==1,"SAVE automatic removals settle once-per-turn relic benefit")

 g=Game.new(42);preload("res://tests/event_cases.gd").arrive(g,"binding_cleric")
 h=roundtrip(t,g,"current event choice")
 step_both(t,g,h,"event",{"action":"choose","choice":"leave_free"})
 h=roundtrip(t,g,"current event result")
 step_both(t,g,h,"event",{"action":"leave"})

 g=Game.new(42,true,"pressure");g.Pressure.gain(g,160,"测试脉冲")
 h=roundtrip(t,g,"overload");step_both(t,g,h,"end")
 g=Game.new(42,true,"guard");preload("res://tests/guard_cases.gd").ready(g);t.action(g,"end")
 h=roundtrip(t,g,"captured");step_both(t,g,h,"prison",{"action":"enter"})
 h=roundtrip(t,g,"cell");step_both(t,g,h,"end")
 preload("res://tests/prison_cases.gd").inspect(t,g)
 h=roundtrip(t,g,"inspection");step_both(t,g,h,"prison",{"action":"inspect"})
 h=roundtrip(t,g,"inspection result");step_both(t,g,h,"prison",{"action":"accept"})
 h=roundtrip(t,g,"inspection complete");step_both(t,g,h,"prison",{"action":"resist"})
 h=roundtrip(t,g,"resistance battle");step_both(t,g,h,"end")
 g=Game.new(42,true,"guard");g.state.security=4;g.Guard.capture(g,g.state.enemies[0]);t.action(g,"prison",{"action":"enter"})
 roundtrip(t,g,"security five ending")
 g=preload("res://tests/prison_cases.gd").intake(t)
 preload("res://tests/prison_cases.gd").clear_fixture(g)
 for i in range(3): t.action(g,"prison",{"action":"explore"})
 g._gain_tool("return_seal") # Preserve existing-item support; absent from generation.
 var seal=g.state.items.filter(func(i):return i.type=="return_seal")[0]
 h=roundtrip(t,g,"retained return seal and frozen cell pool")
 step_both(t,g,h,"item_use",{"item":seal.id,"target":"hero"})
 roundtrip(t,g,"special item escape to regenerated tower")
 g=Game.new(42,true,"equipment");t.action(g,"finish_rest");roundtrip(t,g,"practice completed")
 g=Rewards.setup()
 for i in range(4): g._gain_tool("picks")
 t.action(g,"finish_prepare")
 h=roundtrip(t,g,"over-capacity packing");step_both(t,g,h,"item_discard",{"item":g.state.items[0].id})
 g=Rewards.setup();a=g.add_fixture("thigh",4,10,true);c=g.add_fixture("ankle",4,10,true)
 card=Rewards.give(t,g,"double_unlock");Rewards.play(t,g,card,"thigh",a.id)
 h=roundtrip(t,g,"second magic lock");step_both(t,g,h,"chain",{"target":c.id})

 # Corrupt shapes, ids, references, versions and checksums must reject without mutation.
 g=Game.new(42)
 var clean=g.export_snapshot()
 for domain in g.B.RNG_SALTS:
  for damage in ["missing","fractional","negative"]:
   var bad=clean.duplicate(true)
   match damage:
    "missing": bad.rng.erase(domain)
    "fractional": bad.rng[domain]=0.5
    "negative": bad.rng[domain]=-1
   t.check(not g.restore_snapshot(bad).ok and g.state==clean,"SAVE registered random domain rejects invalid counters atomically "+domain+" "+damage)
 var unknown_domain=clean.duplicate(true)
 unknown_domain.rng.unregistered_domain=0
 t.check(not g.restore_snapshot(unknown_domain).ok and g.state==clean,"SAVE unregistered random domains reject without changing the live state")
 g.state=clean.duplicate(true)
 for change in ["missing","phase","cards","rng","enemy","enemy_kind","id","reference","nan"]:
  var bad=clean.duplicate(true)
  match change:
   "missing": bad.erase("mana")
   "phase": bad.phase="unknown"
   "cards": bad.hand[0].type="missing"
   "rng": bad.rng.deck="broken"
   "enemy": bad.enemies[0].intent={"kind":"install"}
   "enemy_kind": bad.enemies[0].intent={"kind":"unknown","text":"invalid","delayed":false}
   "id": bad.next_card=1
   "reference": bad.rooms[0].next=["missing_room"]
   "nan": bad.mana=NAN
  t.check(not g.restore_snapshot(bad).ok and g.state==clean,"SAVE corrupted state atomically rejected "+change)
 var envelope=JSON.parse_string(Store.pack(clean));envelope.payload+="x"
 t.check(not Store.unpack(JSON.stringify(envelope)).ok,"SAVE checksum detects truncated or changed payload")
 envelope=JSON.parse_string(Store.pack(clean));envelope.format=999
 t.check(not Store.unpack(JSON.stringify(envelope)).ok,"SAVE unknown format rejected")
 t.check(not Store.unpack("{bad").ok,"SAVE broken outer JSON rejected without engine error")

 var store=Store.new("res://build/save-tests-"+str(Time.get_ticks_usec()))
 t.check(not store.read_slot("tower").ok,"SAVE missing file handled")
 t.check(store.write_game(g).ok,"SAVE first real write")
 var first=FileAccess.get_file_as_string(store.path("tower"))
 var first_scene=store.read_slot("tower").snapshot
 t.action(g,"end")
 t.check(store.write_game(g).ok and FileAccess.get_file_as_string(store.path("tower")+".bak")==first,"SAVE next atomic write preserves previous valid backup")
 var newest=store.read_slot("tower")
 t.check(newest.ok and not newest.backup and newest.snapshot==g.restart_snapshot(),"SAVE latest full state reads exactly")
 var file=FileAccess.open(store.path("tower"),FileAccess.WRITE);file.store_string("broken");file.close()
 var recovered=store.read_slot("tower")
 t.check(recovered.ok and recovered.backup and recovered.snapshot==first_scene,"SAVE damaged primary recovers previous valid state")
 t.check(store.write_game(g).ok and store.read_slot("tower").snapshot==g.restart_snapshot(),"SAVE subsequent save repairs primary without losing valid backup")
 var tower_bytes=FileAccess.get_file_as_string(store.path("tower"))
 t.check(store.write_game(Game.new(42,true,"component_links")).ok and FileAccess.get_file_as_string(store.path("tower"))==tower_bytes and store.read_slot("practice").ok,"SAVE practice slot never overwrites tower")
 var escaped=preload("res://tests/prison_cases.gd").intake(t)
 preload("res://tests/prison_cases.gd").clear_fixture(escaped)
 preload("res://tests/exploration_fixture.gd").at_site(escaped,"door");escaped.state.posture="stand"
 card=t.grant_fixture_card(escaped,"unlock")
 t.action(escaped,"prison",{"action":"unlock","uid":card.uid})
 t.action(escaped,"prison",{"action":"door_exit"})
 t.check(not escaped.state.practice and escaped.state.phase=="map" and escaped.state.save_slot=="practice","SAVE practice-origin escape keeps its save identity")
 t.check(store.write_game(escaped).ok and FileAccess.get_file_as_string(store.path("tower"))==tower_bytes,"SAVE escaped practice tower still cannot overwrite formal run")
 roundtrip(t,escaped,"escaped practice tower")
 var blocked=Store.new(store.path("tower"))
 t.check(not blocked.write_game(g).ok and FileAccess.get_file_as_string(store.path("tower"))==tower_bytes,"SAVE write failure retains original save and live game")
 envelope=JSON.parse_string(tower_bytes);envelope.format=999
 file=FileAccess.open(store.path("tower"),FileAccess.WRITE);file.store_string(JSON.stringify(envelope));file.close()
 t.check(not store.read_slot("tower").ok and store.read_slot("tower").error.contains("版本不兼容"),"SAVE newer primary never silently falls back to old backup")
 var incompatible=FileAccess.get_file_as_string(store.path("tower"))
 t.check(not store.write_game(g).ok and FileAccess.get_file_as_string(store.path("tower"))==incompatible,"SAVE incompatible file appearing mid-session cannot be overwritten automatically")
 t.check(store.write_game(Game.new(42),true).ok and store.read_slot("tower").ok,"SAVE explicit new run can replace incompatible primary")
