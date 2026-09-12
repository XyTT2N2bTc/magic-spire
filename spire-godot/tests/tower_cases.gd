extends RefCounted

const Tower=preload("res://data/tower.gd")
const Game=preload("res://core/game.gd")
const EventData=preload("res://data/room_events.gd")

static func run(t) -> void:
 preload("res://tests/departure_cases.gd").run(t)
 var current=Game.new(42)
 var unopened=current.state.rooms.filter(func(room):return room.get("pool","")=="ordinary")[0]
 var description_state=current.state.duplicate(true)
 var description=current.room_description(unopened)
 t.check(description=="普通战斗。" and current.state==description_state,"TOWER room description stays concise without drawing enemies")
 var event_pool=EventData.pool()
 t.check("tailor" not in EventData.TYPES and "locksmith" not in EventData.TYPES,"TOWER retired tailor and locksmith definitions are fully removed")
 t.check("binding_cleric" in event_pool and "succubus_three_games" in event_pool and "succubus_magic_pawnshop" in event_pool and "enchanters_empty_studio" in event_pool and "smuggled_mana_potions" in event_pool and "floating_belt_cluster" in event_pool and "alchemist_tasting_stall" in event_pool and "abandoned_storeroom" in event_pool and "bound_dream_guest_room" in event_pool and "mysterious_woman_statue" in event_pool and "maze_survey_team" in event_pool,"TOWER current authored events remain eligible for normal generation")
 elite_classification(t)
 route_contract_cases(t)
 merged_departure_cases(t)
 travel_cases(t)
 var signatures={}
 var elite_groups={}
 var seeds=t.seed_values("tower_graph")
 for seed in seeds:
  var rooms=Tower.generate(seed)
  for r in rooms:
   if r.get("encounter","") in Tower.FirstFloor.ELITE_ENCOUNTERS: elite_groups[r.encounter]=true
  var by_id={}
  var incoming={}
  var legal=true
  for room in rooms:
   if by_id.has(room.id): legal=false
   by_id[room.id]=room
  for room in rooms:
   if room.next.is_empty() and room.id!="exit": legal=false
   for target in room.next:
    if not by_id.has(target) or by_id[target].floor!=room.floor+1: legal=false
    incoming[target]=incoming.get(target,0)+1
  for room in rooms:
   if room.id!="entrance" and not incoming.has(room.id): legal=false
  t.check(legal and rooms.size()>=26 and by_id.exit.floor==16,"TOWER seeded graph has unique reachable ascending rooms and one exit beyond summit")
  t.check(JSON.stringify(rooms)==JSON.stringify(Tower.generate(seed)),"TOWER seed repeats topology and room types")
  t.check(rooms.filter(func(r):return r.floor==8).all(func(r):return r.kind=="treasure"),"TOWER ninth floor always treasure")
  t.check(rooms.filter(func(r):return r.floor==14).all(func(r):return r.kind=="rest"),"TOWER final floor always rest")
  t.check(rooms.filter(func(r):return r.floor<5).all(func(r):return r.kind!="rest" and r.get("encounter","") not in Tower.FirstFloor.ELITE_ENCOUNTERS),"TOWER no early elite/rest")
  t.check(rooms.filter(func(r):return r.floor==13).all(func(r):return r.kind!="rest"),"TOWER no rest just before guaranteed final rest")
  t.check(rooms.filter(func(r):return r.kind=="event").all(func(r):return not r.has("event")),"TOWER event identities remain undrawn until arrival")
  t.check(rooms.filter(func(r):return r.floor==1).all(func(r):return incoming.get(r.id,0)==1),"TOWER first-floor converging edges are pruned")
  var types={}
  for r in rooms: types[r.id]="elite" if r.get("encounter","") in Tower.FirstFloor.ELITE_ENCOUNTERS else r.kind
  var transitions=true
  for r in rooms:
   for target in r.next:
    if r.floor>=0 and r.floor<14 and absf(by_id[target].lane-r.lane)>1.0/6.0+0.0001: transitions=false
    if types[r.id] in ["rest","elite","shop"] and types[target]==types[r.id]: transitions=false
  t.check(transitions,"TOWER adjacent lanes and no consecutive restricted rooms")
  # No crossing edges in the generated section: ordering must be preserved between rows.
  var crossings=false
  for a in rooms:
   if a.floor<0 or a.floor>=14: continue
   for b in rooms:
    if a.floor!=b.floor or a.lane>=b.lane: continue
    for a_to in a.next:
     for b_to in b.next:
      if by_id[a_to].lane>by_id[b_to].lane: crossings=true
  t.check(not crossings,"TOWER generated branches never cross")
  signatures[JSON.stringify(rooms)]=true
 t.check(elite_groups.has("heap_family") and elite_groups.has("guard_solo"),"TOWER real elite generation reaches both families without fixing first entry")
 t.check(signatures.size()>20 if t.exhaustive else signatures.size()==seeds.size(),"TOWER selected seeds produce varied branching layouts")
 var g=Game.new(42)
 var before=JSON.stringify(g.state)
 var projected=g.route_view()
 projected[-1].next.append("entrance")
 projected[0].lane=0.99
 t.check(JSON.stringify(g.state)==before,"TOWER inspection cannot mutate frozen graph")
 t.finish_room(g)
 t.check(not t.action(g,"depart",{"room":"exit"}).ok,"TOWER long route cannot skip to exit")
 var rng_before=JSON.stringify(g.state.rng)
 var rooms_before=JSON.stringify(g.state.rooms)
 for i in range(3): g.get_view()
 t.check(JSON.stringify(g.state.rng)==rng_before and JSON.stringify(g.state.rooms)==rooms_before,"TOWER previews do not reroll content or topology")

static func travel_cases(t) -> void:
 var g=Game.new(42)
 t.check(t.action(g,"departure",{"op":"skip"}).ok,"TRAVEL explicitly finishes opening before route logging")
 var next=g.room_data(g.state.room).next[0]
 t.check(t.action(g,"depart",{"room":next}).ok,"TRAVEL logging departure")
 t.check(t.action(g,"travel_step").ok,"TRAVEL logging arrival")
 var messages=g.get_view().travel_log
 t.check(messages.size()>=2 and messages[0].turn==0 and messages.back().turn==1,"TRAVEL departure and arrival have actual movement turn stamps")
 var state_before=g.export_snapshot();g.get_view();g.get_view()
 t.check(g.export_snapshot()==state_before,"TRAVEL message projection is read only")

static func departure_fixture(phase: String):
 var g=Game.new(42)
 var kind={"prepare":"battle","pack":"battle","rest":"rest","shop":"shop","treasure":"treasure","event":"event"}[phase]
 g.state.room=g.state.rooms.filter(func(r):return r.kind==kind and not r.next.is_empty())[0].id
 if phase=="event":
  preload("res://tests/event_cases.gd").arrive(g,"smuggled_mana_potions")
  var choice=g.candidates().filter(func(c):return c.payload.get("choice","")=="credit")[0]
  g.dispatch(choice.id,g.state.version)
 elif phase in ["shop","treasure"]: g.Services.start(g)
 elif phase=="rest": g._start_rest();g._begin_rest()
 else:
  g._start_preparation()
  if phase=="pack":
   for i in range(4): g._gain_tool("shard")
   g._discard_end();g._finish_preparation()
   while g.carried_items()>g.item_capacity():
    var discard=g.candidates().filter(func(c):return c.payload.kind=="item_discard" and c.valid)[0]
    g.dispatch(discard.id,g.state.version)
 return g

static func merged_departure_cases(t) -> void:
 for phase in ["prepare","rest","shop","treasure","event","pack"]:
  var g=departure_fixture(phase)
  var target=g.room_data(g.state.room).next[0]
  var before=g.export_snapshot()
  var twin=Game.new(42);twin.state=before.duplicate(true)
  var exit_action=g._route_exit_candidate(g._phase_candidates())
  var departures=g.candidates().filter(func(c):return c.payload.kind=="depart" and c.payload.room==target)
  t.check(g.state.phase==phase and not exit_action.is_empty() and departures.size()==1 and departures[0].valid,"DEPART finished room offers one-step outgoing node: "+phase)
  var projected=g.get_view().route.filter(func(r):return r.id==target)[0]
  t.check(projected.status=="available" and projected.entry_reason=="" and g.export_snapshot()==before,"DEPART route availability is read only before leaving: "+phase)
  t.check(not t.action(g,"depart",{"room":"entrance"}).ok and not t.action(g,"depart",{"room":"exit"}).ok and g.export_snapshot()==before,"DEPART invalid route cannot discard cards or finish room: "+phase)
  t.check(twin.dispatch(exit_action.id,twin.state.version).ok and t.action(twin,"depart",{"room":target}).ok,"DEPART original two-command reference remains valid: "+phase)
  t.check(g.dispatch(departures[0].id,before.version).ok and g.state.phase=="travel" and g.state.journey.target==target,"DEPART one click completes room and starts chosen journey: "+phase)
  t.check(g.state.version==before.version+1 and g.state.travel_turns==before.travel_turns and g.state.completed_rooms.has(before.room),"DEPART combined operation commits once without an extra turn: "+phase)
  var combined=g.export_snapshot();var split=twin.export_snapshot()
  for key in ["version","logs"]: combined.erase(key);split.erase(key)
  t.check(combined==split,"DEPART preserves original rewards, cleanup, powers, cards, items, resources and RNG: "+phase)
  var after=g.export_snapshot()
  t.check(not g.dispatch(departures[0].id,before.version).ok and g.export_snapshot()==after,"DEPART repeated stale click cannot repeat cleanup or journey: "+phase)
 var g=departure_fixture("prepare")
 for i in range(4): g._gain_tool("shard")
 var target=g.room_data(g.state.room).next[0]
 var before=g.export_snapshot()
 t.check(g.room_entry_reason(g.room_data(target)).contains("超出容量") and not t.action(g,"depart",{"room":target}).ok and g.export_snapshot()==before,"DEPART over-capacity inventory blocks completion and travel atomically")
 g=departure_fixture("prepare");target=g.room_data(g.state.room).next[0]
 g.state.overloaded=true
 before=g.export_snapshot()
 t.check(not t.action(g,"depart",{"room":target}).ok and g.export_snapshot()==before,"DEPART overload cannot escape the pending forced turn")
 g=departure_fixture("event");target=g.room_data(g.state.room).next[0]
 g.state.room_event.prepare_pending=true
 before=g.export_snapshot()
 t.check(not t.action(g,"depart",{"room":target}).ok and g.export_snapshot()==before,"DEPART event victory still enters its preparation before route departure")
 g=Game.new(42,true);g._start_preparation()
 t.check(not g.candidates().any(func(c):return c.payload.kind=="depart"),"DEPART practice does not become a tower shortcut")

static func route_contract_cases(t) -> void:
 var g=Game.new(42)
 var source=g.state.rooms.filter(func(r):return r.floor==0)[0]
 g.state.room=source.id;g.state.phase="map";g.state.completed_rooms=[source.id];g.state.energy=0
 var view=g.route_view()
 var current=view.filter(func(r):return r.id==source.id)[0]
 var allowed=current.paths.filter(func(p):return p.status=="available").map(func(p):return p.to)
 var choices=g.candidates().filter(func(c):return c.payload.kind=="depart" and c.valid).map(func(c):return c.payload.room)
 t.check(allowed==choices and view.filter(func(r):return r.status=="available").all(func(r):return r.id in allowed),"ROUTE visible active lines exactly match formal departures")
 var unrelated=g.state.rooms.filter(func(r):return r.floor==source.floor+1 and r.id not in source.next)[0]
 var before=g.export_snapshot()
 t.check(g.room_entry_reason(unrelated).contains("没有地图连线") and not t.action(g,"depart",{"room":unrelated.id}).ok and g.export_snapshot()==before,"ROUTE adjacent unconnected branch cannot move or spend resources")
 t.check(not t.action(g,"depart",{"room":"exit"}).ok and not t.action(g,"depart",{"room":"entrance"}).ok and g.export_snapshot()==before,"ROUTE skip and return attempts are atomic")
 t.check(t.action(g,"depart",{"room":source.next[0]}).ok,"ROUTE actual visible edge departs")
 var valid_save=g.export_snapshot()
 g.state.journey.target=unrelated.id
 before=g.export_snapshot()
 var blocked=t.find_action(g,"travel_step")
 t.check(not blocked.valid and blocked.reason.contains("没有地图连线") and not g.dispatch(blocked.id,g.state.version).ok and g.export_snapshot()==before,"ROUTE invalidated edge blocks travel before time pressure or passive changes")
 var restored=Game.new(7)
 t.check(not restored.restore_snapshot(before).ok and restored.restore_snapshot(valid_save).ok,"ROUTE restore rejects off-route journey and accepts real edge")

static func elite_classification(t) -> void:
 var g=Game.new(42)
 var encounters=g.Enemies.ENCOUNTERS.duplicate(true)
 var pools=g.Enemies.FirstFloor.POOLS.duplicate(true)
 g.Enemies.ENCOUNTERS.test_elite=encounters.guard_solo.duplicate(true)
 g.Enemies.FirstFloor.POOLS.strong=["belt_tie"]
 var fights=g.state.rooms.filter(func(room):return room.kind=="battle" and room.has("encounter_choices"))
 if fights.size()>=4:
  for index in range(3):
   g.state.completed_rooms.append(fights[index].id)
   g.state.room_encounters[fights[index].id]="test_elite" if index==2 else "rope_solo"
  var current=fights[3]
  current.encounter_choices={"weak":"rope_solo","strong":"belt_tie"}
  current.erase("encounter_selected")
  g.state.room=current.id
  g._start_battle()
  t.check(current.encounter_selected=="weak","TOWER any elite ID is excluded from ordinary battle count")
  g.state.room_encounters[fights[2].id]="rope_solo"
  current.erase("encounter_selected")
  g._start_battle()
  t.check(current.encounter_selected=="strong","TOWER third ordinary battle reaches configured strong threshold")
 else:
  t.check(false,"TOWER classification fixture requires four ordinary rooms")
 g.Enemies.ENCOUNTERS=encounters
 g.Enemies.FirstFloor.POOLS=pools
