extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Tower=preload("res://data/tower.gd")

# Room-boundary fixture only; existing full-route tests traverse the entire climb.
# Subsequent rest, travel, combat, rewards, imprisonment and escape use formal commands.
static func before_room(g, target: String) -> void:
 var parent=g.state.rooms.filter(func(r):return target in r.next)[0]
 g._discard_end()
 g.state.room=parent.id
 if parent.kind=="rest": g._start_rest();g._begin_rest()
 else:
  g.state.phase="map";g.state.completed_rooms=[parent.id];g.state.energy=0

static func travel(t,g,target: String) -> void:
 t.check(t.action(g,"depart",{"room":target}).ok,"PROGRESSION actual adjacent departure "+target)
 var steps=0
 while g.state.phase=="travel" and steps<12:
  t.check(t.action(g,"travel_step").ok,"PROGRESSION formal travel step")
  steps+=1

static func run(t) -> void:
 preload("res://tests/demo_exit_cases.gd").run(t)
 for seed in range(12):
  var g=Game.new(seed)
  var rooms=g.state.rooms
  var elite_rooms=rooms.filter(func(r):return r.get("encounter","")=="guard_solo")
  t.check(elite_rooms.all(func(r):return r.floor>=5 and not r.has("pool")),"PROGRESSION elites appear after opening floors outside ordinary pools")
  var summit=g.room_data("summit")
  t.check(summit.boss and summit.kind=="battle" and summit.requires_defeat and g.state.room_encounters.summit in g.Enemies.FirstFloor.SUMMIT_ENCOUNTERS and summit.floor==15,"PROGRESSION summit uses one registered first-floor boss encounter")
  t.check(rooms.filter(func(r):return "exit" in r.next).map(func(r):return r.id)==["summit"] and g.room_data("exit").requires_clear=="summit","PROGRESSION every graph route to exit passes summit")
  t.check(g.route_view().filter(func(r):return r.id=="summit")[0].icon=="boss" and elite_rooms.all(func(e):return g.route_view().filter(func(r):return r.id==e.id)[0].icon=="elite"),"PROGRESSION map distinguishes elites from summit using actual room role")

 var g=Game.new(42)
 g.state.room_encounters.summit="six_bind_solo";g.room_data("summit").encounter="six_bind_solo";g.room_data("summit").name="塔顶 · 六缚"
 before_room(g,"summit")
 var marker=g._install_template("rope","ankle",4,10,false,"fixture")
 g.state.mana=42;g.state.pressure=17
 var equipment=JSON.stringify(g.state.equipment)
 t.action(g,"finish_rest")
 var rest_id=g.state.room
 var before=JSON.stringify(g.state)
 t.check(not t.action(g,"depart",{"room":"exit"}).ok and JSON.stringify(g.state)==before,"PROGRESSION cannot skip summit from final rest")
 t.check(g.room_entry_reason(g.room_data("exit")).contains("塔顶首领"),"PROGRESSION unavailable exit explains actual boss prerequisite")
 travel(t,g,"summit")
 t.check(g.state.phase=="battle" and g.state.enemies.size()==1 and g.state.enemies[0].hp==220 and g.state.enemies[0].type=="six_bind" and not g.state.practice,"PROGRESSION final room starts one full-health 六缚 in real run")
 t.check(JSON.stringify(g.state.equipment)==equipment and g.state.mana==42 and g.state.pressure==17 and g.state.traversed_edges.has([rest_id,"summit"]),"PROGRESSION rest departure and summit travel preserve gear/resources without battle-ending rewards")
 var first=g.state.enemies[0].id
 var damage=t.find_action(g,"attack",{"type":"strike","enemy":first}).payload.damage
 t.action(g,"attack",{"type":"strike","enemy":first})
 t.check(g._enemy(first).hp==220-damage and g.state.phase=="battle","PROGRESSION actual attack damage affects the real boss")
 # Shorten remaining HP to isolate reward/exit integration, not enemy balance.
 g._enemy(first).hp=1
 t.action(g,"attack",{"type":"strike","enemy":first})
 t.check(g.state.phase=="reward" and g.state.reward_count==1 and g.state.mana==42 and g.state.prison.is_empty(),"PROGRESSION boss defeat grants one reward while deferring end-of-session mana, with no prison key")
 t.check(g.state.reward_options.size()==3 and g.state.reward_options.all(func(id):return g.Cards.Rules.SPECS[id].rarity=="rare") and g.state.boss_relic_options.size()==3 and g.state.boss_relic_options.all(func(id):return g.Relics.TYPES[id].rarity=="boss"),"PROGRESSION actual boss kill freezes three rare cards and three boss relic choices")
 t.check(not t.action(g,"depart",{"room":"exit"}).ok,"PROGRESSION reward phase cannot skip preparation to exit")
 var reward_version=g.state.version
 t.action(g,"reward",{"type":g.state.reward_options[0]})
 t.action(g,"reward",{"type":"skip"})
 t.check(g.state.deck.size()==11 and g.state.phase=="prepare" and not g.state.completed_rooms.has("summit"),"PROGRESSION summit reward joins permanent deck before ordinary preparation")
 t.check(not g.dispatch("old_action",reward_version).ok,"PROGRESSION prior reward version cannot be reused")
 for i in range(4):g._gain_tool("shard")
 t.action(g,"finish_prepare")
 t.check(g.state.phase=="pack" and g.state.mana==52 and not g.state.combat.active and not g.state.completed_rooms.has("summit"),"PROGRESSION preparation pays ending mana once before the inventory capacity gate")
 t.finish_packing(g)
 t.check(g.state.phase=="map" and g.state.mana==52 and g.state.completed_rooms.has("summit") and g.room_entry_reason(g.room_data("exit"))=="","PROGRESSION packing does not repay ending mana and opens the exit only after actual reward/preparation")
 var rewards=g.state.reward_count;var mana=g.state.mana
 travel(t,g,"exit")
 t.check(g.state.phase=="cleared" and g.state.reward_count==rewards and g.state.mana==mana and g.state.pressure==17 and not g._equipment(marker.id).is_empty(),"PROGRESSION exit completes climb without extra reward/heal or clearing restraints")
 before=JSON.stringify(g.state)
 t.check(g.candidates().filter(func(c):return c.payload.kind!="item_discard").size()==2 and not t.action(g,"reward",{"type":g.state.reward_options[0]}).ok and JSON.stringify(g.state)==before,"PROGRESSION exit choices cannot replay rewards")

 # A hand-edited/invalid travel state cannot bypass the prerequisite at arrival either.
 g=Game.new(42)
 g.state.phase="travel";g.state.room="summit";g.state.energy=0
 g.state.journey={"from":"summit","target":"exit","total":1,"remaining":1,"speed":5.0,"mode":"正常步行"}
 before=JSON.stringify(g.state)
 t.check(not t.action(g,"travel_step").ok and JSON.stringify(g.state)==before,"PROGRESSION arrival revalidates boss prerequisite and rolls back entire forged travel")

 for target in [g.state.rooms.filter(func(r):return r.get("encounter","")=="guard_solo")[0].id,"summit"]:
  g=Game.new(42)
  if target=="summit": g.state.room_encounters.summit="six_bind_solo";g.room_data("summit").encounter="six_bind_solo"
  before_room(g,target);t.action(g,"finish_rest");travel(t,g,target)
  var old_route=JSON.stringify(g.state.rooms)
  var old_ids=g.state.enemies.map(func(e):return e.id)
  var old_reward=g.state.reward_count
  # Prepare an imminent capture; normal shared enemy phase must stop immediately after it.
  for e in g.state.enemies:
   e.intent={"kind":"capture","text":"执行收押","delayed":false}
  if target!="summit": g.state.guard_bind={"progress":100.0,"sources":{"guard":{"enemy":g.state.enemies[0].id,"energy":0}}}
  t.action(g,"end")
  t.check(g.state.phase=="captured" and g.state.security==1 and g.state.reward_count==old_reward and not g.state.completed_rooms.has(target),"PROGRESSION elite/summit loss enters prison once without marking node won")
  t.action(g,"prison",{"action":"enter"})
  # Seed arrival geometry; actual travel has its own exploration suite.
  preload("res://tests/exploration_fixture.gd").collect(t,g)
  preload("res://tests/exploration_fixture.gd").at_site(g,"vent")
  if not t.find_action(g,"posture",{"dest":"sit","wall":false}).valid:t.action(g,"end")
  t.action(g,"posture",{"dest":"sit","wall":false})
  for i in range(3):
   if not t.find_action(g,"prison",{"action":"vent_kick"}).valid:t.action(g,"end")
   t.check(t.action(g,"prison",{"action":"vent_kick"}).ok,"PROGRESSION real seated vent kick after tower loss")
   if i<2:t.action(g,"end")
  while g.carried_items()>g.item_capacity():t.action(g,"item_discard",{"item":g.state.items[0].id})
  t.check(t.action(g,"prison",{"action":"vent_exit"}).ok and g.state.phase=="map" and g.state.room=="prison_start","PROGRESSION tower loss exits into prison route")
  # Traverse the new exit challenge using the existing navigation fight fixture.
  g.state.equipment=[];g.state.composites=[];g.state.links=[];g.state.special_equipment=[];g.state.pressure=0;g.state.posture="stand"
  travel(t,g,"prison_rest");t.action(g,"rest_begin");t.action(g,"finish_rest");travel(t,g,"prison_gate")
  preload("res://tests/route_driver.gd").shorten_persistent_enemies(g)
  var attack=preload("res://tests/route_driver.gd").attack(g)
  t.check(not attack.is_empty() and g.dispatch(attack.id,g.state.version).ok and g.state.phase=="reward","PROGRESSION exit challenge must be defeated before tower return")
  t.action(g,"reward",{"type":"skip"})
  t.finish_packing(g)
  t.check(g.state.security==1 and g.state.completed_rooms.is_empty() and old_route!=JSON.stringify(g.state.rooms) and not g.room_entry_reason(g.room_data("exit")).is_empty(),"PROGRESSION rebuilt tower includes fresh locked summit and preserves security")
  before=JSON.stringify(g.state)
  t.check(g.state.tower_start_pending and not t.action(g,"depart",{"room":"summit"}).ok and JSON.stringify(g.state)==before,"PROGRESSION prison return cannot select summit before a legal floor-ten-or-eleven start")
  var starts=g.state.rooms.filter(func(room):return room.floor in [9,10] and room.kind in ["battle","event","shop"])
  t.check(not starts.is_empty(),"PROGRESSION rebuilt tower offers a legal prison-return start")
  if starts.is_empty(): return
  var battles=starts.filter(func(room):return room.kind=="battle")
  var start=starts[0] if battles.is_empty() else battles[0]
  t.check(t.action(g,"depart",{"room":start.id}).ok and not g.state.tower_start_pending and g.state.room==start.id and g.state.security==1,"PROGRESSION formal start selection clears the pending choice and preserves security")
  # The start choice is now committed; isolate the summit boundary as above.
  before_room(g,"summit");t.action(g,"finish_rest");travel(t,g,"summit")
  t.check(g.state.enemies.size()==1 and g.state.enemies[0].id not in old_ids and g.state.enemies[0].hp==220 and g.state.security==1,"PROGRESSION rebuilt summit creates a new boss instance without clearing safety history")
