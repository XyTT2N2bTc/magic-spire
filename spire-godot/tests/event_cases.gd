extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Data=preload("res://data/room_events.gd")

# Arrival fixture chooses a real event room. All choices use versioned commands.
static func arrive(g, id: String) -> void:
 g._discard_end()
 var room=g.state.rooms.filter(func(r):return r.kind=="event")[0]
 room.event=id;room.name=g.Events.Data.TYPES[id].name
 g.state.room=room.id
 g.Events.start(g,id)

static func choose(t,g,id: String) -> Dictionary:
 return t.action(g,"event",{"action":"choose","choice":id})

# docs/event-pipeline-unification.md §10 scenario 01: the compiled registry entry is the
# single author form, and the projection keeps the same visible fields as the baseline.
static func event_definition_single_form(t) -> void:
 var g=Game.new(42)
 var declaration_keys=["allow_refuse","unavailable","relic_gate","random_freeze","outcome_draw","frozen_form","empty_node"]
 var visible_keys=["id","name","intro","stage","report","hint","selections","page_id","result_status"]
 t.check(Data.TYPES.size()==12,"EVENT DEFINITION twelve authored events compile into the single node form")
 var single_count=0
 var multi_count=0
 for id in Data.TYPES.keys():
  var spec=Data.TYPES[id]
  t.check(spec.has("start_node") and spec.nodes is Array and not spec.nodes.is_empty(),"EVENT DEFINITION definition exposes start_node and nodes "+id)
  for legacy in ["choices","stages","start_stage","allow_refuse"]:
   t.check(not spec.has(legacy),"EVENT DEFINITION definition drops the legacy key "+legacy+" "+id)
  var nodes=spec.nodes
  if nodes.size()==1: single_count+=1
  else: multi_count+=1
  for entry in nodes:
   t.check(declaration_keys.all(func(key):return entry.has(key)),"EVENT DEFINITION every node declares the full policy set "+id+"/"+str(entry.get("id","")))
   t.check(entry.choices is Array and not entry.choices.is_empty() and entry.choices.size()<=6,"EVENT DEFINITION node keeps1—6 options "+id+"/"+str(entry.get("id","")))
   if nodes.size()==1:
    t.check(entry.id=="choice" and not entry.has("title") and not entry.has("intro"),"EVENT DEFINITION single node uses the sentinel id without stage copy "+id)
   else:
    t.check(entry.id not in ["choice","reward","result","battle","loot","keys"] and entry.has("title") and entry.has("intro"),"EVENT DEFINITION staged node keeps its id and stage copy "+id+"/"+str(entry.get("id","")))
  var view={}
  var walk=Game.new(42)
  arrive(walk,id)
  view=walk.get_view().room_event
  t.check(view.keys().all(func(key):return key in visible_keys) and visible_keys.all(func(key):return view.has(key)),"EVENT DEFINITION projection keeps the frozen visible fields "+id)
  t.check(view.id==id and view.stage==walk.state.room_event.stage and view.name.contains(spec.name),"EVENT DEFINITION projection identity matches the entered definition "+id)
  t.check(view.intro==spec.intro or walk.state.room_event.get("flow",false),"EVENT DEFINITION single-node introduction stays byte-identical "+id)
 t.check(single_count==8 and multi_count==4,"EVENT DEFINITION eight single-node and four multi-node events registered")

static func run(t) -> void:
 preload("res://tests/event_draw_cases.gd").run(t)
 event_definition_single_form(t)
 var g=Game.new(42)
 # Content registrations fail here rather than silently choosing another behavior.
 for id in g.Enemies.TYPES:
  var spec=g.Enemies.TYPES[id]
  t.check(spec.hp>0 and spec.behavior in ["restraint","dispenser","attachment","lock","guard","humanoid","sequence","six_bind","binding_box","drone","puppeteer","puppet"] and spec.visual in ["rope","belt","tape","cable_tie","toybox","silencer","lock","guard","rope_mass","rope_heap","belt_mass","belt_heap","trader","versatile","mixed_bundle","rope_serpent","ominous_circle","six_bind","binding_box","drone","puppeteer","puppet"],"CONTENT enemy behavior and visual registered "+id)
  if spec.has("special_pool"): t.check(not spec.special_pool.is_empty() and spec.special_pool.all(func(type):return g.SpecialEquipment.DESIGNS.has(type)),"CONTENT enemy special pool resolves "+id)
  if spec.behavior=="attachment": t.check(spec.attachment_slot in ["eyes","mouth"] and spec.attachment_pool.all(func(template):return spec.attachment_slot in g.Equipment.TEMPLATES[template].slots),"CONTENT attachment pool matches declared body region "+id)
  for field in ["install_pool","final_pool","attachment_pool"]:
   if spec.has(field): t.check(not spec[field].is_empty() and spec[field].all(func(template):return g.Equipment.TEMPLATES.has(template)),"CONTENT enemy equipment pools resolve "+id+field)
 for configuration in g.Composites.GENERATION:
  t.check(not g.Composites.spec(configuration[0],configuration[1],configuration[2]).is_empty(),"CONTENT composite generation uses defined structures")
 for encounter in g.Enemies.ENCOUNTERS.values():
  t.check(encounter.members.all(func(m):return g.Enemies.TYPES.has(m.type) and m.grade in [1,2,3]),"CONTENT encounters use real templates and grades")
 for pool in g.Enemies.FirstFloor.POOLS.values(): t.check(pool.all(func(id):return g.Enemies.ENCOUNTERS.has(id)),"CONTENT encounter pool references resolve")
 for spec in Data.TYPES.values():
  if spec.nodes.size()==1:
   var choices=spec.nodes[0].choices
   t.check(spec.start_node=="choice" and choices.all(func(c):return (c.has("effects") or c.get("recipe","") in ["free_basic","tighten_or_medium","locked_assembly"]) and c.reward in ["none","common","uncommon","rare","relic"]),"CONTENT single-node event recipes, effects and rewards registered")
  else:
   t.check(spec.nodes.size()>=2,"CONTENT multi-node event definitions remain registered")
 for pool in Data.CARD_POOLS.values(): t.check(pool.size()>=3 and pool.all(func(id):return g.B.CARD_NAMES.has(id)),"CONTENT event card rewards are playable definitions")
 t.check(Data.CARD_POOLS.common==g.Cards.Rules.COMMON and Data.CARD_POOLS.uncommon==g.Cards.Rules.UNCOMMON and Data.CARD_POOLS.rare==g.Cards.Rules.RARE,"CONTENT event card pools match the three visible rarities")
 t.check(g.Events.reward_text("common").contains("普通牌") and g.Events.reward_text("uncommon").contains("罕见牌") and g.Events.reward_text("rare").contains("稀有牌"),"CONTENT event reward copy names each real rarity")
 for spec in g.Relics.TYPES.values(): t.check(spec.modifiers.keys().all(func(h):return h in g.Relics.MODIFIER_LIMITS),"CONTENT relic hooks registered")

 var active=Data.pool()
 t.check(active.has("binding_cleric") and active.has("succubus_three_games") and active.has("succubus_magic_pawnshop") and active.has("enchanters_empty_studio") and active.has("smuggled_mana_potions") and active.has("floating_belt_cluster") and active.has("alchemist_tasting_stall") and active.has("abandoned_storeroom") and active.has("bound_dream_guest_room") and active.has("mysterious_woman_statue") and active.has("maze_survey_team"),"EVENT current authored events remain in the normal pool")
 for seed_value in range(12):
  g=Game.new(seed_value)
  t.check(g.state.rooms.filter(func(r):return r.kind=="event").all(func(r):return not r.has("event")) and g.state.event_seen.is_empty(),"EVENT generating rooms does not draw or consume event identities")
  var domain=g.state.rng.duplicate(true)
  arrive(g,"binding_cleric")
  var before=JSON.stringify(g.state)
  var view=g.get_view()
  g.candidates();g.route_view();g.EquipmentOffers.options(g)
  t.check(JSON.stringify(g.state)==before,"EVENT offers, projection and equipment probes do not mutate")
  t.check(g.state.rng.deck==domain.deck and g.state.rng.enemy==domain.enemy and g.state.rng.equipment==domain.equipment,"EVENT random domain remains independent of deck, enemies and equipment")
  t.check(view.room_event.id=="binding_cleric" and g.state.room_event.options.size()==3,"EVENT current authored event exposes its frozen legal choices")

 # A late effect failure rolls back earlier effects, ids, logs and resources.
 g=Game.new(3);arrive(g,"binding_cleric")
 var restore=g.state.room_event.options.filter(func(option):return option.id=="restore")[0]
 var original=restore.effects.duplicate(true)
 restore.effects.append({"op":"unsupported"})
 var rejected=g.export_snapshot()
 t.check(not choose(t,g,"restore").ok and g.export_snapshot()==rejected,"EVENT unsupported late effect rejects the whole transaction")
 restore.effects=original
 var mana_before=g.state.mana
 t.check(choose(t,g,"restore").ok and g.state.mana>=mana_before and g.state.equipment.size()==2,"EVENT valid current choice commits its frozen batch")

 g=Game.new(5);g._gain_card("panic")
 var curse=g.state.discard.pop_back();g.state.hand.append(curse)
 t.check(t.action(g,"card",{"uid":curse.uid}).ok,"EVENT granted panic still plays through the normal candidate")
 t.check(g.state.exhaust.any(func(c):return c.uid==curse.uid) and g.state.deck.size()==11,"EVENT played panic exhausts without permanent deletion")
 g._reset_piles()
 t.check(g.state.exhaust.is_empty() and g.state.draw.any(func(c):return c.uid==curse.uid),"EVENT curse restores next battle")

 g=Game.new(6);g._gain_tool("picks");var tool=g.state.items[0]
 var target=g.add_fixture("thigh",8,10,true)
 var durability=target.durability;var energy=g.state.energy
 t.check(t.action(g,"item_use",{"item":tool.id,"target":target.id}).ok and not g._equipment(target.id).locked and g._equipment(target.id).durability==durability and g.state.energy==energy and g._item(tool.id).uses==1,"EVENT existing picks remain a normal zero-cost unlocking tool")
 t.check(not t.action(g,"item_install",{"item":tool.id}).ok,"EVENT picks cannot install as a cutting tool")
