extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Save=preload("res://tests/persistence_cases.gd")

static func encounter(witch: bool=false, seed_value: int=42):
 var g=Game.new(seed_value,false,"equipment",true,false,25,false,false,"witch" if witch else "original")
 g.state.room_encounters.entrance="iron_man_solo"
 g._start_battle()
 return g

static func enemy(g, type: String) -> Dictionary:
 return g.state.enemies.filter(func(e):return e.type==type)[0]

static func run(t) -> void:
 var g=encounter()
 var iron=enemy(g,"iron_man")
 var box=enemy(g,"binding_box")
 var drone=enemy(g,"iron_drone")
 t.check(iron.hp==150 and box.hp==50 and drone.hp==50 and iron.intent.kind=="bind_apply" and drone.intent.kind=="idle","IRON encounter starts with approved health and opening intents")
 t.check(iron.iron_support_ids.has(box.id) and iron.iron_support_ids.has(drone.id) and g.validate()=="","IRON boss owns both support identities in a valid state")

 var witch=encounter(true)
 t.check(enemy(witch,"iron_man").hp==195 and enemy(witch,"binding_box").hp==65 and enemy(witch,"iron_drone").hp==65,"IRON witch encounter multiplies exactly the three boss members by 1.3")

 var plate_game=encounter(false,43)
 var ordinary_plate=plate_game._install_special("negative_plate_lock_medium","special_2_a",3)
 plate_game.IronMan.apply_capture_equipment(plate_game,enemy(plate_game,"iron_man"))
 t.check(not ordinary_plate.is_empty() and not plate_game.state.special_equipment.any(func(item):return item.id==ordinary_plate.id) and plate_game.state.special_equipment.any(func(item):return item.type=="urethral_full_cup_medium"),"IRON capture replaces an ordinary plate lock with the approved urethral cup")

 var cursed_game=encounter(false,44)
 cursed_game.RelicEffects.gain(cursed_game,"cursed_plate_lock")
 var cursed_id=cursed_game.state.special_equipment.filter(cursed_game.SpecialEquipment.is_cursed_plate)[0].id
 cursed_game.IronMan.apply_capture_equipment(cursed_game,enemy(cursed_game,"iron_man"))
 var cursed_toys=cursed_game.state.special_equipment.filter(func(item):return item.id!=cursed_id and not cursed_game.SpecialEquipment.is_reinforcement(item))
 t.check(cursed_game.state.special_equipment.any(func(item):return item.id==cursed_id) and cursed_toys.size()==4 and not cursed_game.state.special_equipment.any(func(item):return item.type=="urethral_full_cup_medium"),"IRON cursed plate remains worn and redirects capture equipment to four other medium toys")

 var witch_equipment_before=witch.state.special_equipment.size()
 witch.IronMan.apply_capture_equipment(witch,enemy(witch,"iron_man"))
 t.check(witch.state.special_equipment.size()==witch_equipment_before+4 and not witch.state.special_equipment.any(func(item):return item.type=="urethral_full_cup_medium"),"IRON witch capture installs four medium toys instead of the urethral cup")

 t.check(t.action(g,"end").ok,"IRON opening enemy phase resolves through formal turn end")
 iron=enemy(g,"iron_man");drone=enemy(g,"iron_drone")
 var cup=g.state.special_equipment.filter(func(item):return item.type=="urethral_full_cup_medium")
 t.check(cup.size()==1 and g.tier(cup[0].durability,cup[0].maximum)==3 and g.CaptureBind.has_bind(g,"iron_man") and g.state.posture=="sit","IRON opening capture installs the tier-three urethral cup and combines posture restrictions")
 var energy_source=g.state.guard_bind.sources.iron_man
 var pressure=g.state.pressure
 var remaining=cup[0].remaining
 g.CaptureBind.energy_spent(g,2)
 t.check(energy_source.energy==2 and g.state.pressure==pressure,"IRON two spent energy only stores remainder")
 g.CaptureBind.energy_spent(g,1)
 var tapes=g.state.equipment.filter(func(item):return item.template in g.IronMan.TAPE_POOL)
 t.check(energy_source.energy==0 and not tapes.is_empty() and g.state.guard_bind.progress>=65 and cup[0].remaining==remaining-1,"IRON shared third energy triggers tape, capture gain and one remote battery drain")
 t.check(g.physical_pieces().any(func(item):return item.locked),"IRON living drone locks a restraint in the same three-energy trigger")

 var stimulation=encounter(false,45)
 t.check(t.action(stimulation,"end").ok,"IRON stimulation fixture resolves its opening capture")
 var stimulation_cup=stimulation.state.special_equipment.filter(func(item):return item.type=="urethral_full_cup_medium")[0]
 stimulation_cup.remaining=1
 var stimulation_log=stimulation.state.logs.size()
 stimulation._apply_traction(3,false,0)
 var stimulation_hits=stimulation.state.logs.slice(stimulation_log).filter(func(log):return String(log.data.get("source","")).contains(stimulation_cup.name))
 t.check(stimulation_hits.size()==3 and stimulation_cup.remaining==0,"IRON one-charge battery receives normal, capture and drone stimulation before drone drain")

 var reinforcement=encounter(false,46)
 var ordinary=reinforcement.add_fixture("wrist",4)
 var composite_root=reinforcement._install_assembly("leg","upper","fixture",2,1)
 var composite_before=composite_root.components.map(func(item):return item.durability)
 reinforcement.EnemyPlans.execute_tighten_budget(reinforcement,enemy(reinforcement,"iron_man"),{"budget":1})
 t.check(ordinary.durability>4 and composite_root.components.map(func(item):return item.durability)==composite_before,"IRON reinforcement budget only tightens ordinary restraints, never composite components")

 g.CaptureBind.damage_bind(g,100,"测试挣脱")
 t.check(not g.CaptureBind.has_bind(g) and iron.intent.kind=="iron_stunned" and iron.iron_stun_turns==1 and iron.iron_armor_break_turns==2,"IRON removing capture schedules one idle action and two armor-break turns")
 t.check(g.Enemies.damage_multiplier(g,"iron_man","physical")==1.0,"IRON armor break removes mechanical damage reduction")
 iron.intent.delayed=true
 var delayed_one=t.action(g,"end")
 iron=enemy(g,"iron_man")
 t.check(delayed_one.ok and iron.iron_armor_break_turns==1,"IRON interrupted idle still consumes the first armor-break turn")
 iron.intent.delayed=true
 var delayed_two=t.action(g,"end")
 iron=enemy(g,"iron_man")
 t.check(delayed_two.ok and iron.iron_armor_break_turns==0 and g.Enemies.damage_multiplier(g,"iron_man","physical")==0.5,"IRON repeated interruption cannot extend the two-turn armor break")

 iron.iron_enhancements=4
 iron.iron_stun_turns=0
 iron.stage=23
 var restraints=g.IronMan.plan(g,iron)
 iron.stage=24
 var composite=g.IronMan.plan(g,iron)
 t.check(restraints.kind=="iron_restraints" and restraints.grade==3 and restraints.tier==3 and restraints.count==5 and restraints.reinforce==6,"IRON four upgrades accumulate grade, tightness, ordinary count and six reinforcement tiers")
 t.check(composite.kind=="iron_composite" and composite.special==2 and composite.locks==3,"IRON third and fourth upgrade groups accumulate two special installs and three locks")
 iron.intent=g.EnemyPlans.build(g,iron)

 var saved=Save.roundtrip(t,g,"iron boss capture break and upgrades")
 t.check(saved.validate()=="" and enemy(saved,"iron_man").iron_enhancements==4,"IRON snapshot preserves boss-specific counters")
 var invalid=saved.export_snapshot()
 var invalid_iron=invalid.enemies.filter(func(e):return e.type=="iron_man")[0]
 invalid_iron.iron_stun_turns=0
 invalid_iron.intent={"kind":"iron_stunned","text":"机械减伤失效 · 发呆","delayed":false}
 var stable=saved.export_snapshot()
 t.check(not saved.restore_snapshot(invalid).ok and saved.export_snapshot()==stable,"IRON snapshot atomically rejects an intent that contradicts its stage and stun counter")
 invalid=saved.export_snapshot()
 invalid_iron=invalid.enemies.filter(func(e):return e.type=="iron_man")[0]
 invalid_iron.iron_enhancements=5
 t.check(not saved.restore_snapshot(invalid).ok and saved.export_snapshot()==stable,"IRON snapshot atomically rejects an enhancement count that contradicts its stage")

 g=encounter(false,17);iron=enemy(g,"iron_man");box=enemy(g,"binding_box");drone=enemy(g,"iron_drone")
 g._damage_enemy(iron,999,"magic","测试终结")
 t.check(iron.gone and box.gone and drone.gone and box.hp==0 and drone.hp==0,"IRON defeat immediately stops both supports regardless of their health")

 var summit_seen={}
 for seed_value in range(64):
  var tower=Game.new(seed_value)
  summit_seen[tower.state.room_encounters.summit]=true
 t.check(summit_seen.has("six_bind_solo") and summit_seen.has("iron_man_solo") and summit_seen.size()==2,"IRON first-floor boss pool can draw both Six Bind and Iron Man")
