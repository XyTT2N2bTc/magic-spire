extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const LiveGame=preload("res://core/game.gd")
const Catalog=preload("res://core/content_catalog.gd")
const Events=preload("res://tests/event_cases.gd")
const EnemyCases=preload("res://tests/enemy_cases.gd")
const SaveCases=preload("res://tests/persistence_cases.gd")

static func run(t) -> void:
 var g=Game.new(42)
 var baseline=Catalog.tables(g)
 var input=Catalog.read_directory("res://content/templates")
 t.check(input.errors.is_empty() and input.documents.size()==5,"PACK five on-disk UTF8 JSON templates")
 if input.documents.size()!=5: return
 for document in input.documents:
  var single=Catalog.compile(g,[document])
  t.check(single.ok,"PACK each template works alone: "+document.file+" "+str(single.errors))
 var result=Catalog.compile(g,input.documents)
 t.check(result.ok and Catalog.tables(g)==baseline,"PACK staging is read-only and templates resolve: "+str(result.errors))
 if not result.ok: return
 var shuffled=input.documents.duplicate(true);shuffled.reverse()
 t.check(Catalog.compile(g,shuffled).tables==result.tables,"PACK file order does not change definitions")
 var invalids=[]
 var concise_event=input.documents.filter(func(d):return d.data.kind=="event")[0].duplicate(true)
 concise_event.data.choices[0].detail=""
 var concise_result=Catalog.compile(g,[concise_event])
 t.check(concise_result.ok and concise_result.tables.event[concise_event.data.id].choices[0].detail=="" and Catalog.tables(g)==baseline,"PACK explicit empty event detail survives loading without changing rules or registries")
 var conditional_event=concise_event.duplicate(true)
 conditional_event.data.choices[0].availability={"kind":"no_chastity_lock","reason":"平板锁封住了肉棒，无法使用这项服务。"}
 var conditional_result=Catalog.compile(g,[conditional_event])
 t.check(conditional_result.ok and conditional_result.tables.event[conditional_event.data.id].choices[0].availability==conditional_event.data.choices[0].availability and Catalog.tables(g)==baseline,"PACK event choice accepts one validated state-dependent availability condition")
 for invalid_availability in [null,{},false,{"kind":"unknown","reason":"无法选择。"},{"kind":"no_chastity_lock","reason":""},{"kind":"no_chastity_lock","reason":"[invalid]"},{"kind":"no_chastity_lock","reason":"无法选择。","extra":true}]:
  var bad=concise_event.duplicate(true);bad.data.choices[0].availability=invalid_availability;invalids.append(bad)
 var animated_event=concise_event.duplicate(true)
 animated_event.data.choices[0].effects=[{"op":"install_random","templates":["rope"],"count":1,"grade":1,"tier":2,"locked":false,"allow_links":false,"wear_style":"animated"}]
 t.check(Catalog.compile(g,[animated_event]).ok and Catalog.tables(g)==baseline,"PACK random restraint installation accepts the reusable animated wear style")
 for invalid_style in ["unknown",0,false]:
  var bad=animated_event.duplicate(true);bad.data.choices[0].effects[0].wear_style=invalid_style;invalids.append(bad)
 for invalid_detail in [null,0,false,"   ","[invalid]","x".repeat(1201)]:
  var bad=concise_event.duplicate(true);bad.data.choices[0].detail=invalid_detail;invalids.append(bad)
 var unspent=input.documents.filter(func(d):return d.data.kind=="relic")[0].duplicate(true)
 unspent.data.modifiers={"unspent_turn_mana":8}
 t.check(Catalog.compile(g,[unspent]).ok,"PACK unspent-turn mana hook supported")
 unspent.data.modifiers.unspent_turn_mana=101
 t.check(not Catalog.compile(g,[unspent]).ok,"PACK unspent-turn mana hook is bounded")
 var helper=input.documents.filter(func(d):return d.data.kind=="relic")[0].duplicate(true)
 var gift_relic=helper.duplicate(true)
 gift_relic.data.modifiers={};gift_relic.data.pickup_cards=["magic_hand_gift"]
 var gift_result=Catalog.compile(g,[gift_relic])
 t.check(gift_result.ok and gift_result.tables.relic[gift_relic.data.id].pickup_cards==["magic_hand_gift"] and Catalog.tables(g)==baseline,"PACK pickup gift cards compile without altering current tables")
 for cards in [[],"magic_hand_gift",["missing_card"],["tease"],[false]]:
  var bad=gift_relic.duplicate(true);bad.data.pickup_cards=cards;invalids.append(bad)
 var shop_relic=helper.duplicate(true)
 shop_relic.data.rarity="uncommon";shop_relic.data.shop_only=true;shop_relic.data.shop_payment="flask"
 shop_relic.data.modifiers={"pickup_mana_max":10,"pickup_mana_full":1}
 var shop_result=Catalog.compile(g,[shop_relic])
 t.check(shop_result.ok and shop_result.tables.relic[shop_relic.data.id].shop_payment=="flask" and shop_relic.data.id not in shop_result.tables.rewards,"PACK shop-exclusive payment and full-mana pickup preserve their source restriction")
 for changes in [{"shop_only":"true"},{"shop_payment":"both"},{"shop_only":false},{"modifiers":{"pickup_mana_full":2}}]:
  var bad=shop_relic.duplicate(true);bad.data.merge(changes,true);invalids.append(bad)
 helper.data.modifiers={"unrestricted_items":1}
 t.check(Catalog.compile(g,[helper]).ok,"PACK unrestricted item flag supported")
 helper.data.modifiers.unrestricted_items=2
 t.check(not Catalog.compile(g,[helper]).ok,"PACK unrestricted item flag rejects non-boolean magnitude")
 var flyer=input.documents.filter(func(d):return d.data.kind=="relic")[0].duplicate(true)
 flyer.data.modifiers={"shop_flask_mana":20}
 t.check(Catalog.compile(g,[flyer]).ok,"PACK generic shop flask mana modifier accepted")
 flyer.data.modifiers.shop_flask_mana=101
 t.check(not Catalog.compile(g,[flyer]).ok,"PACK shop flask mana rejects out-of-range amount")
 var collectible=input.documents.filter(func(d):return d.data.kind=="relic")[0].duplicate(true)
 collectible.data.modifiers={};collectible.data.rarity="special";collectible.data.collectible=true
 var collectible_result=Catalog.compile(g,[collectible])
 t.check(collectible_result.ok and collectible_result.tables.relic[collectible.data.id].collectible and collectible.data.id not in collectible_result.tables.rewards,"PACK special no-effect collectibles use shared loader without entering normal pool")
 for changes in [{"collectible":"true"},{"rarity":"common"},{"modifiers":{"strength":1}},{"card_base_bonuses":{"strain":4}}]:
  var bad=collectible.duplicate(true);bad.data.merge(changes,true);invalids.append(bad)
 var card_relic=input.documents.filter(func(d):return d.data.kind=="relic")[0].duplicate(true)
 card_relic.data.modifiers={};card_relic.data.card_base_bonuses={"strain":4,"slip":4}
 var card_result=Catalog.compile(g,[card_relic])
 t.check(card_result.ok and card_result.tables.relic[card_relic.data.id].card_base_bonuses=={"strain":4,"slip":4} and Catalog.tables(g)==baseline,"PACK targeted card-base relic uses shared read-only loader")
 for bonuses in [{},{"missing":4},{"panic":4},{"strain":0},{"strain":101},{"strain":1.5},{"strain":"4"},[]]:
  var bad=card_relic.duplicate(true);bad.data.card_base_bonuses=bonuses;invalids.append(bad)
 var triggered=input.documents.filter(func(d):return d.data.kind=="relic")[0].duplicate(true)
 triggered.data.modifiers={}
 triggered.data.trigger={"event":"magic_paid","scope":"battle","phase":"battle","op":"mana","ratio":0.25}
 var compiled_trigger=Catalog.compile(g,[triggered])
 t.check(compiled_trigger.ok and compiled_trigger.tables.relic[triggered.data.id].trigger.ratio==0.25 and Catalog.tables(g)==baseline,"PACK generic relic trigger compiles without mutation")
 t.check(compiled_trigger.tables.relic[triggered.data.id].rarity==triggered.data.rarity,"PACK relic rarity survives compilation")
 var missing_rarity=triggered.duplicate(true);missing_rarity.data.erase("rarity");invalids.append(missing_rarity)
 var volley=triggered.duplicate(true)
 volley.data.trigger={"event":"turn_end","scope":"battle","phase":"battle","round":7.0,"op":"fixed_enemy_damage","amount":77.0}
 var volley_result=Catalog.compile(g,[volley])
 t.check(volley_result.ok and volley_result.tables.relic[volley.data.id].trigger.round==7 and Catalog.tables(g)==baseline,"PACK configured seventh-turn fixed damage compiles through existing relic template")
 for changes in [{"round":0},{"round":7.5},{"scope":"turn"},{"phase":"rest"},{"event":"fell"}]:
  var bad=volley.duplicate(true);bad.data.trigger.merge(changes,true);invalids.append(bad)
 var bad_rarity=triggered.duplicate(true);bad_rarity.data.rarity="legendary";invalids.append(bad_rarity)
 for changes in [{"op":"unknown"},{"ratio":1.5},{"extra":true},{"event":"unknown"},{"amount":2}]:
  var bad=triggered.duplicate(true);bad.data.trigger.merge(changes,true);invalids.append(bad)
 for document in input.documents:
  var bad=document.duplicate(true);bad.data.extra_unsupported=true;invalids.append(bad)
 var duplicate=input.documents[0].duplicate(true)
 var duplicates=input.documents.duplicate(true);duplicates.append(duplicate)
 t.check(not Catalog.compile(g,duplicates).ok and Catalog.tables(g)==baseline,"PACK duplicate rejects entire batch without registry mutation")
 for changes in [{"enemy_sources":["missing_enemy"]},{"slots":["mouth"]},{"slots":["wrist","wrist"]},{"base_template":"glove_body"}]:
  var bad=input.documents.filter(func(d):return d.data.kind=="restraint")[0].duplicate(true)
  bad.data.merge(changes,true);invalids.append(bad)
 for changes in [{"energy_gain":-1},{"duration":1.5},{"turn_gain":0},{"design":{"grade":4}},{"design":{"slots":["wrist"]}}]:
  var bad=input.documents.filter(func(d):return d.data.kind=="special_equipment")[0].duplicate(true)
  bad.data.merge(changes,true);invalids.append(bad)
 var missing_wear=input.documents.filter(func(d):return d.data.kind=="special_equipment")[0].duplicate(true)
 missing_wear.data.erase("wear_text");invalids.append(missing_wear)
 var unnamed_wear=input.documents.filter(func(d):return d.data.kind=="special_equipment")[0].duplicate(true)
 unnamed_wear.data.wear_text="把这件玩具戴好。";invalids.append(unnamed_wear)
 for changes in [{"modifiers":{"magic_refund":0.5}},{"modifiers":{"capacity":1.5}},{"modifiers":{}}]:
  var bad=input.documents.filter(func(d):return d.data.kind=="relic")[0].duplicate(true)
  bad.data.merge(changes,true);invalids.append(bad)
 for changes in [{"strength":0},{"strength":3},{"strength":1.5},{"hp":0},{"hp":3.5},{"encounter":{"rank":"elite","grade":1}},{"strength":1,"base_enemy":"invented"}]:
  var bad=input.documents.filter(func(d):return d.data.kind=="enemy")[0].duplicate(true)
  bad.data.merge(changes,true);invalids.append(bad)
 for effect in [{"op":"arbitrary_script"},{"op":"relic","type":"missing"},{"op":"flask_mana_gain","amount":101},{"op":"random_amount","effect":"flask_mana_gain","minimum":60,"maximum":30},{"op":"random_amount","effect":"relic","minimum":30,"maximum":60},{"op":"mana_max_loss","amount":0},{"op":"mana_restore_full","amount":1},{"op":"install","template":"rope","slot":"wrist","grade":1.5,"tier":1,"locked":false},{"op":"tool","type":"saw","ignored":true},{"op":"special_install","type":"shaft_ring_low","slot":"wrist"}]:
  var bad=input.documents.filter(func(d):return d.data.kind=="event")[0].duplicate(true)
  bad.data.choices[0].effects=[effect];invalids.append(bad)
 var bad_encounter=input.documents.filter(func(d):return d.data.kind=="event")[0].duplicate(true)
 bad_encounter.data.choices[0].effects=[]
 bad_encounter.data.choices[0].encounter={"id":"missing_encounter","requires_defeat":true,"victory_effects":[{"op":"card","type":"panic"}],"victory_report":"战斗结束。","result_status":"success"}
 invalids.append(bad_encounter)
 var bad_victory_effect=input.documents.filter(func(d):return d.data.kind=="event")[0].duplicate(true)
 bad_victory_effect.data.choices[0].effects=[]
 bad_victory_effect.data.choices[0].encounter={"id":"belt_solo","requires_defeat":true,"victory_effects":[{"op":"arbitrary_script"}],"victory_report":"战斗结束。","result_status":"success"}
 invalids.append(bad_victory_effect)
 var bad_item_rewards=input.documents.filter(func(d):return d.data.kind=="event")[0].duplicate(true)
 bad_item_rewards.data.choices[0].effects=[]
 bad_item_rewards.data.choices[0].item_rewards=[{"id":"potion","pool":["missing_item"]}]
 invalids.append(bad_item_rewards)
 var duplicate_item_groups=input.documents.filter(func(d):return d.data.kind=="event")[0].duplicate(true)
 duplicate_item_groups.data.choices[0].effects=[]
 duplicate_item_groups.data.choices[0].item_rewards=[{"id":"same","pool":["mana_potion"]},{"id":"same","pool":["draw_scroll"]}]
 invalids.append(duplicate_item_groups)
 var bad_refusal=input.documents.filter(func(d):return d.data.kind=="event")[0].duplicate(true)
 bad_refusal.data.allow_refuse="false";invalids.append(bad_refusal)
 var bad_hidden=input.documents.filter(func(d):return d.data.kind=="event")[0].duplicate(true)
 bad_hidden.data.choices[0].hide_when_unavailable="true";invalids.append(bad_hidden)
 for selector in [{"kind":"restraint","count":0},{"kind":"card","include_special":false},{"kind":"restraint","exclude_curses":true}]:
  var bad=input.documents.filter(func(d):return d.data.kind=="event")[0].duplicate(true)
  bad.data.choices[0].selector=selector
  bad.data.choices[0].effects=[{"op":"remove_restraints","targets":"$selected"}]
  invalids.append(bad)
 var bad_multi_effect=input.documents.filter(func(d):return d.data.kind=="event")[0].duplicate(true)
 bad_multi_effect.data.choices[0].selector={"kind":"restraint","count":2}
 bad_multi_effect.data.choices[0].effects=[{"op":"remove_restraints","targets":["invented"]}]
 invalids.append(bad_multi_effect)
 for document in input.documents:
  for field in document.data:
   for invalid_value in [null,[],{},true]:
    var bad=document.duplicate(true);bad.data[field]=invalid_value
    # Empty design is a valid optional override; templates do not supply it.
    var rejected=Catalog.compile(g,[bad])
    t.check(not rejected.ok and Catalog.tables(g)==baseline,"PACK wrong field type: "+document.data.kind+"."+field+" "+str(invalid_value))
 for bad in invalids:
  var failed=Catalog.compile(g,[bad])
  t.check(not failed.ok and failed.tables.is_empty() and str(failed.errors).contains(bad.file) and Catalog.tables(g)==baseline,"PACK invalid field/reference fails closed: "+str(bad.data))
 # Corrupt JSON and nested file ordering exercise the same disk reader used at startup.
 var folder="user://content_case_"+str(Time.get_ticks_usec())
 DirAccess.make_dir_recursive_absolute(folder+"/nested")
 var file=FileAccess.open(folder+"/broken.json",FileAccess.WRITE);file.store_string("{ broken");file.close()
 var disk=Catalog.read_directory(folder)
 t.check(disk.errors.size()==1 and str(disk.errors).contains("broken.json"),"PACK malformed JSON reports filename/line")
 DirAccess.remove_absolute(folder+"/broken.json")
 file=FileAccess.open(folder+"/nested/good.json",FileAccess.WRITE);file.store_string(JSON.stringify(input.documents[0].data));file.close()
 disk=Catalog.read_directory(folder)
 t.check(disk.errors.is_empty() and disk.documents.size()==1 and Catalog.compile(g,disk.documents).ok,"PACK nested drop-in file reads and validates")
 var old_report=Catalog.report.duplicate(true);var old_loaded=Catalog.loaded
 Catalog.loaded=false;Catalog.ensure(g,folder)
 t.check(Catalog.report.ok and Catalog.report.files==1 and Catalog.tables(g)!=baseline,"PACK bootstrap reads and atomically installs actual files")
 var bootstrapped=Catalog.tables(g);Catalog.ensure(g,folder)
 t.check(Catalog.tables(g)==bootstrapped,"PACK repeated Game creation never registers duplicates")
 Catalog.commit(g,baseline)
 file=FileAccess.open(folder+"/broken.json",FileAccess.WRITE);file.store_string("{}");file.close()
 Catalog.loaded=false;Catalog.ensure(g,folder)
 t.check(not Catalog.report.ok and Catalog.tables(g)==baseline,"PACK one malformed record prevents entire bootstrap batch")
 DirAccess.remove_absolute(folder+"/broken.json")
 Catalog.report=old_report;Catalog.loaded=old_loaded
 DirAccess.remove_absolute(folder+"/nested/good.json");DirAccess.remove_absolute(folder+"/nested");DirAccess.remove_absolute(folder)

 # Independent content references resolve after the entire batch is staged.
 var documents=input.documents.duplicate(true)
 var event=documents.filter(func(d):return d.data.kind=="event")[0].data
 event.choices[0].effects.append({"op":"relic","type":"example_spare_pocket"})
 event.choices[0].effects.append({"op":"install","template":"example_soft_belt","slot":"ankle","grade":1,"tier":1,"locked":false})
 var restraint=documents.filter(func(d):return d.data.kind=="restraint")[0].data
 restraint.enemy_sources.append("example_patrol_rope")
 restraint.slots.append("upper_arm")
 event.choices.append({"id":"arm_fit","label":"安装大臂皮带","reward":"none","effects":[{"op":"install","template":"example_soft_belt","slot":"upper_arm","grade":3,"tier":3,"locked":false}]})
 result=Catalog.compile(g,documents)
 t.check(result.ok,"PACK cross-file references compile without ordering requirements")
 if not result.ok: return
 Catalog.commit(g,result.tables)
 var found_event=false;var found_enemy=false;var found_special=false
 for seed_value in range(24):
  var live=LiveGame.new(seed_value)
  t.check(live.state.rooms==LiveGame.new(seed_value).state.rooms,"PACK normal tower remains seeded deterministic")
  for room in live.state.rooms:
   if room.kind!="event": continue
   live.state.room=room.id
   live.Events.start(live)
   found_event=found_event or room.event=="example_travel_cache"
   found_special=found_special or room.event=="example_vibration_ring_arrival"
  found_enemy=found_enemy or live.Enemies.FirstFloor.roll(live).any(func(m):return m.type=="example_patrol_rope")
 t.check(found_event and found_special and found_enemy,"PACK authored events and special sources occur on arrival; enemies join real encounters")
 t.check("example_spare_pocket" in g.Relics.REWARDS and "example_soft_belt" in g.Enemies.TYPES.belt.install_pool,"PACK sources join real reward and enemy pools")

 g=Game.new(42);Events.arrive(g,"example_travel_cache")
 var before=g.export_snapshot();g.get_view();g.candidates()
 t.check(g.state==before,"PACK imported event previews do not mutate state/RNG")
 var c=t.find_action(g,"event",{"action":"choose","choice":"take_tool"})
 t.check(c.valid and c.detail.contains("支付5") and c.detail.contains("备用口袋"),"PACK all costs/rewards projected before choosing")
 t.check(not g.dispatch(c.id,g.state.version-1).ok and g.state==before,"PACK stale event command is atomic")
 t.check(g.dispatch(c.id,g.state.version).ok,"PACK imported event executes through formal transaction")
 t.check(g.state.mana==95 and g.state.items[0].type=="saw" and "example_spare_pocket" in g.state.relics and g.state.equipment[0].template=="example_soft_belt","PACK event actually pays/grants/installs")
 t.check(g.item_capacity()==4 and g.escape_preview(g.state.equipment[0],"strain",5).damage>0,"PACK relic modifier and restraint escape participate in rules")
 SaveCases.roundtrip(t,g,"imported event, equipment and relic")
 var saved=g.export_snapshot()
 Catalog.commit(g,baseline)
 var without=Game.new(42);before=without.export_snapshot()
 t.check(not without.restore_snapshot(saved).ok and without.state==before,"PACK missing definitions reject restore without dropping equipment")
 Catalog.commit(g,result.tables)
 g=Game.new(42);g.state.mana=4;Events.arrive(g,"example_travel_cache");before=g.export_snapshot()
 c=t.find_action(g,"event",{"action":"choose","choice":"take_tool"})
 t.check(not c.valid and not g.dispatch(c.id,g.state.version).ok and g.state==before,"PACK insufficient payment prevents all rewards atomically")

 g=Game.new(42);Events.arrive(g,"example_vibration_ring_arrival")
 t.check(t.action(g,"event",{"action":"choose","choice":"equip"}).ok and g.state.special_equipment.size()==1,"PACK special acquired by normal event command")
 t.check(g.state.room_event.report.contains("试制硅胶柱身震动环") and g.state.room_event.report.contains("沿着龟头缓缓套到柱身中段") and g.state.special_equipment[0].remaining==3,"PACK special acquisition uses authored reusable wear prose and accurate duration")
 SaveCases.roundtrip(t,g,"imported special event effect")
 g.state.room="entrance";g._start_battle()
 t.check(g.state.special_equipment[0].remaining==2 and is_equal_approx(g.state.pressure,1.2),"PACK special applies inherited shaft sensitivity on real player turn start")
 t.check(t.action(g,"attack",{"type":"heavy"}).ok and is_equal_approx(g.state.pressure,3.0),"PACK special energy effect triggers once for multi-energy action")
 t.action(g,"end");t.action(g,"end")
 t.check(g.state.special_equipment.size()==1 and g.state.special_equipment[0].remaining==0,"PACK powered special remains installed after its battery expires")
 before=g.export_snapshot();var amount=g.state.pressure
 g._tick_special("energy")
 t.check(g.state.pressure==amount,"PACK expired imported special no longer applies an energy-paid pulse")
 g.state=before
 Events.arrive(g,"example_vibration_ring_arrival");before=g.export_snapshot()
 c=t.find_action(g,"event",{"action":"choose","choice":"equip"})
 t.check(not c.valid and not g.dispatch(c.id,g.state.version).ok and g.state==before,"PACK special occupied slot rejects duplicate without mutation")
 SaveCases.roundtrip(t,g,"expired imported special")

 g=Game.new(42);Events.arrive(g,"example_travel_cache")
 t.check(t.action(g,"event",{"action":"choose","choice":"arm_fit"}).ok,"PACK high-tier arm variant installs by formal event")
 t.check(g.state.equipment[0].shoulders.pieces.size()==2 and g.Shoulders.eligible(g.state.equipment[0]) and g.Binding.present(g.state.equipment[0]),"PACK ordinary variant inherits shoulder pair and torso attachment rules")
 t.check(g.Shoulders.slip_reason(g,g.state.equipment[0])!="" and g.validate()=="","PACK imported shoulder pair blocks body slip through original rules")
 SaveCases.roundtrip(t,g,"imported arm restraint and automatic shoulders")
 var installed=false
 for seed_value in range(16):
  g=EnemyCases.encounter("example_patrol_rope_encounter",seed_value)
  t.check(g.state.enemies[0].name=="巡游绳索" and g.state.enemies[0].hp==16,"PACK enemy uses authored name and health")
  t.check(t.action(g,"end").ok and g.state.equipment.size()==1,"PACK new enemy executes inherited behavior")
  installed=installed or g.state.equipment[0].template=="example_soft_belt"
 t.check(installed,"PACK new enemy actually installs new restraint from authored pool")
 SaveCases.roundtrip(t,g,"imported enemy intent")
 Catalog.commit(g,baseline)
 t.check(Catalog.tables(g)==baseline,"PACK tests restore all registries")
