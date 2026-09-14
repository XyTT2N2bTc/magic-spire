extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const P=preload("res://core/pressure.gd")

static func flat_mana_cost(t) -> void:
 var g=Game.new(42)
 for limit in [100.0,130.0]:
  for ratio in [0.0,0.4,0.4001,0.7,0.99,1.0]:
   t.check(P.magic_multiplier(limit*ratio,limit)==1.0,"MANA disabled surcharge stays one at every pressure threshold and maximum")
 t.check(not g.B.PRESSURE_MAGIC_SURCHARGE_ENABLED and is_equal_approx(P.magic_multiplier(91,130,true),1.25),"MANA advanced curve remains available with explicit backend opt-in")
 for value in [0,40,70,99]:
  g.state.pressure=value
  var before=g.export_snapshot()
  for type in g.Cards.Rules.SPECS:
   for free in [false,true]:
    t.check(g.Cards.face_mana(g,type,free)==g.Cards.Rules.face_mana_base(type,free,g.B.SPELL_COST),"MANA every card face uses its own base cost at pressure "+str(value)+" "+type)
  t.check(g._mana_cost(10)==10 and g.get_view().pressure.magic_multiplier==1 and not g.get_view().pressure.detail.contains("施法魔力消耗"),"MANA shared spell cost and status projection disable surcharge")
  t.check(g.export_snapshot()==before,"MANA cost and card previews leave all state unchanged")
 g.state.pressure=75;g.state.temporary_mana=4;g.state.mana=6
 var target=g.add_fixture("ankle",8,10,true);var card=t.grant_fixture_card(g,"unlock")
 var c=t.find_action(g,"card",{"uid":card.uid,"target":target.id,"free":false})
 t.check(c.valid and c.mana==10 and c.mana_payment.temporary_mana==4 and c.mana_payment.mana==6 and g.cast_view(g.Cards.cast_profile(g,"unlock")).chance==0.25,"MANA exact base balance can cast at high pressure while success probability stays reduced")
 var before=g.export_snapshot()
 t.check(not g.dispatch(c.id,g.state.version-1).ok and g.state==before,"MANA stale flat-cost candidate remains atomic")
 g.state.sure_cast=true;c=t.find_action(g,"card",{"uid":card.uid,"target":target.id,"free":false})
 t.check(g.dispatch(c.id,g.state.version).ok and g.state.mana==0 and g.state.temporary_mana==0 and not g._equipment(target.id).locked,"MANA formal success pays exact base cost from original pools")

static func calm_mouth(t) -> void:
 for template in ["mouth_band","mouth_tape"]:
  for grade in [1,2,3]:
   for tightness in [1,2,3]:
    var g=Game.new(42);g.state.pressure=90
    var maximum=g.Equipment.maximum(grade)
    var mouth=g._install_template(template,"mouth",maximum*([0.4,0.8,1.0][tightness-1]),maximum,false,"fixture",grade)
    t.check(not mouth.is_empty() and g.validate()=="","CALM mouth fixture uses a real graded restraint")
    var expected=20-4*(grade+tightness-1)
    var before=g.export_snapshot();var c=t.find_action(g,"calm")
    t.check(g.state==before and c.detail.contains("快感－%d" % expected) and c.detail.contains("下回合能量＋1"),"CALM preview reads the same reduction and full deferred energy without mutation")
    t.check(not g.dispatch(c.id,g.state.version-1).ok and g.state==before,"CALM stale mouth preview refuses without changing any state")
    if expected==0:
     t.check(not c.valid and c.reason.contains("高级、紧度3档") and not g.dispatch(c.id,g.state.version).ok and g.state==before,"CALM complete mouth block refuses without payment or deferred energy")
    else:
     t.check(g.dispatch(c.id,g.state.version).ok and g.state.pressure==90-expected and g.state.energy==2 and g.state.next_energy==1,"CALM all grades and tightness levels reduce only pressure relief, never deferred energy")
     t.check(g.state.mana==before.mana and g.state.tick==before.tick and g.state.rng==before.rng and g.state.equipment==before.equipment and g.state.hand==before.hand,"CALM mouth penalty introduces no spell roll, turn, mana, equipment or card mutation")
     t.check(g.state.logs.any(func(row):return row.text.contains("深呼吸：快感降低%d" % expected) and row.text.contains("下回合能量＋1")),"CALM log records actual relief and full energy reward")
 var g=Game.new(42);g.state.pressure=90
 var mouth=g._install_template("mouth_band","mouth",20,20,false,"fixture",3)
 var blocked=t.find_action(g,"calm");var version=g.state.version
 t.check(t.action(g,"manual",{"target":mouth.id}).ok and g.equipment_at("mouth").is_empty(),"CALM formal removal frees the mouth")
 var before=g.export_snapshot()
 t.check(not g.dispatch(blocked.id,version).ok and g.state==before and t.find_action(g,"calm").detail.contains("快感－20"),"CALM removal invalidates old preview and restores full relief")
 g._install_template("eye_leather","eyes",20,20,true,"fixture",3)
 t.check(P.calm(g).reduction==20,"CALM other body slots and locks do not cause mouth attenuation")
 mouth=g._install_template("mouth_band","mouth",20,20,true,"fixture",3)
 mouth.durability=16
 t.check(P.calm(g).reduction==4 and t.find_action(g,"calm").valid,"CALM tightness dropping from three to two re-enables the action even while locked")
 g.state.pressure=1
 t.check(t.action(g,"calm").ok and g.state.pressure==0 and g.state.next_energy==1,"CALM attenuated relief clamps at zero while still granting full deferred energy")
 var restored=preload("res://tests/persistence_cases.gd").roundtrip(t,g,"mouth-attenuated deep breath")
 t.check(restored!=null and P.calm(restored).reduction==4 and restored.state.next_energy==1,"CALM saved physical mouth state reproduces relief and deferred reward")

static func calm_next_energy(t) -> void:
 var g=Game.new(42)
 g.state.pressure=60
 var tick=g.state.tick;var mana=g.state.mana;var version=g.state.version
 var before=g.export_snapshot()
 var offered=t.find_action(g,"calm")
 t.check(offered.valid and offered.detail.contains("下回合能量＋1") and g.state==before,"CALM preview exposes deferred energy without awarding it")
 t.check(t.action(g,"calm").ok and g.state.energy==2 and g.state.next_energy==1 and g.state.pressure==40 and g.state.tick==tick,"CALM pays now and reserves energy without advancing the turn")
 t.check(t.action(g,"calm").ok and g.state.energy==1 and g.state.next_energy==2 and g.state.pressure==20,"CALM repeated successful uses stack deferred energy")
 before=g.export_snapshot()
 var limited=t.find_action(g,"calm")
 t.check(g.state.calm_uses==2 and not limited.valid and limited.reason.contains("已使用2次") and limited.detail.contains("剩余0／2次") and not g.dispatch(limited.id,g.state.version).ok and g.state==before,"CALM third use is blocked despite remaining energy and pressure, without payment or mutation")
 t.check(not g.dispatch(offered.id,version).ok and g.state==before,"CALM stale submission cannot duplicate its energy reward")
 var restored=preload("res://tests/persistence_cases.gd").roundtrip(t,g,"deep breath deferred energy")
 for game in [g,restored]:
  t.check(game.state.calm_uses==2 and not t.action(game,"calm").ok,"CALM saving cannot restore spent uses in the same turn")
  t.check(t.action(game,"end").ok and game.state.energy==5 and game.state.next_energy==0 and game.state.mana==mana,"CALM next player round consumes the full reserve exactly once")
  t.check(game.state.calm_uses==0 and P.calm(game).remaining==2,"CALM next player round restores both uses")
  t.check(t.action(game,"end").ok and game.state.energy==3,"CALM bonus does not repeat on later rounds")
 g=Game.new(42);g.state.pressure=1;g.state.energy=0
 before=g.export_snapshot()
 t.check(not t.action(g,"calm").ok and g.state==before,"CALM insufficient energy cannot grant a reserve")
 g.state.energy=1
 t.check(t.action(g,"calm").ok and g.state.pressure==0 and g.state.energy==0 and g.state.next_energy==1,"CALM less than 20 pressure still grants the full one energy")
 g.state.energy=1;before=g.export_snapshot()
 t.check(not t.action(g,"calm").ok and g.state==before,"CALM zero pressure retains its existing disabled rule and cannot farm energy")
 P.gain(g,100,"测试干扰")
 t.check(t.action(g,"end").ok and g.state.energy==3 and g.state.next_energy==0 and g.state.overload_energy==0,"CALM reserve offsets the original next-turn overload penalty")
 g=Game.new(42,true,"pressure")
 t.check(t.action(g,"calm").ok and t.action(g,"end").ok and g.state.phase=="rest" and g.state.energy==4 and g.state.next_energy==0,"CALM noncombat player turns consume the same reserve")
 t.check(g.state.calm_uses==0 and P.calm(g).remaining==2,"CALM rest uses the same turn reset")

static func source(id: String, timing: String, amount: float, equipment: String="", room: String="") -> Dictionary:
 return {"id":id,"name":"测试干扰","timing":timing,"amount":amount,"equipment":equipment,"room":room}

static func free_cooling(t) -> void:
 for phase in ["battle","prepare","rest","prison"]:
  var g=Game.new(42,true,"prison_test") if phase=="prison" else Game.new(42)
  if phase=="prepare": g._start_preparation()
  elif phase=="rest": g._start_rest();g._begin_rest()
  for target in g.action_targets():
   target.locked=false;g._apply_manual_release(target,0.0)
  g._cleanup();g.state.pressure_sources=[];g.state.relics=[];g.state.pressure=10
  for enemy in g.state.enemies: enemy.intent.delayed=true
  var before=g.export_snapshot();g.get_view();g.candidates()
  t.check(g.state==before and not g.dispatch("missing",g.state.version).ok and g.state==before,"FREE COOLING queries and refused actions do not advance time")
  t.check(t.action(g,"end").ok and g.state.pressure==8,"FREE COOLING actual turn lowers two exactly once: "+phase)
 for kind in ["eyes","mouth","wrist","special","composite"]:
  var g=Game.new(42);g.state.pressure=10
  if kind=="special": g._install_special("negative_plate_lock_medium","special_2_a")
  elif kind=="composite": g._install_assembly("glove","short","fixture",2,2,{},"straight")
  else: g.add_fixture(kind,4,10)
  for enemy in g.state.enemies: enemy.intent.delayed=true
  t.check(t.action(g,"end").ok and g.state.pressure==10 and P.free_relief(g)==0,"FREE COOLING any worn root blocks relief: "+kind)
 var g=Game.new(42,true,"guard")
 g.CaptureBind.apply_bind(g,g.state.enemies[0])
 t.check(g.action_targets().is_empty() and P.free_relief(g)==0,"FREE COOLING capture alone is not complete freedom")
 g=Game.new(42);g.state.pressure=10;g.state.relics=["ice_heart","marble_stone"]
 for enemy in g.state.enemies: enemy.intent.delayed=true
 t.check(t.action(g,"end").ok and g.state.pressure==5,"FREE COOLING adds to relic cooling without growth multiplier")
 g=Game.new(42);g.state.pressure=1.5
 for enemy in g.state.enemies: enemy.intent.delayed=true
 t.check(t.action(g,"end").ok and g.state.pressure==0,"FREE COOLING fractional remainder stops at zero")

static func run(t) -> void:
 forced_loop_exit(t)
 free_cooling(t)
 flat_mana_cost(t)
 climax_card_practice(t)
 calm_mouth(t)
 calm_next_energy(t)
 formal_sources(t)
 for pair in [[0,0],[40,1],[40.01,2],[80,2],[80.01,3],[99.99,3]]:
  t.check(P.stage(pair[0])==pair[1],"PRESSURE exact stage boundary")
 t.check(P.magic_multiplier(0,100,true)==1 and P.magic_multiplier(40,100,true)==1 and P.magic_multiplier(100,100,true)==1.5,"PRESSURE dormant advanced cost curve retains its original anchors")
 var last=1.0
 for value in range(41,100):
  var mult=P.magic_multiplier(value,100,true)
  t.check(mult>=last and mult<1.5,"PRESSURE monotonic cost without discontinuity")
  last=mult
 var g=Game.new(42,true,"pressure")
 var old=JSON.stringify(g.state)
 var view=g.get_view()
 view.pressure.sources[0].name="changed"
 t.check(JSON.stringify(g.state)==old and g.state.pressure==70 and g.state.pressure_sources.size()==2,"PRESSURE complete practice and independent read-only source projection")
 var initial_mana=g.state.mana
 var card=t.hand_card(g,"ease")
 var cost=g._mana_cost(10)
 t.check(g.get_view().hand.filter(func(c):return c.type=="ease")[0].bound.contains(g.number(cost)),"PRESSURE visible spell card matches current formal mana cost")
 g.state.temporary_mana=5
 t.check(is_equal_approx(g._mana_cost(10),cost),"PRESSURE gross cost does not change with temporary mana balance")
 var free=t.find_action(g,"card",{"uid":card.uid,"free":true})
 t.check(not free.valid and free.reason.contains("休息房") and free.mana==0,"PRESSURE free magic remains free but rest still forbids free effects")
 t.check(t.action(g,"calm").ok and g.state.pressure==50 and g.state.energy==2 and g.state.next_energy==1 and g.state.mana==initial_mana,"PRESSURE actual calm spends current energy and reserves one for next turn")
 old=JSON.stringify(g.state)
 var stale=t.find_action(g,"calm")
 var version=g.state.version
 t.action(g,"calm")
 old=JSON.stringify(g.state)
 t.check(not g.dispatch(stale.id,version).ok and JSON.stringify(g.state)==old,"PRESSURE stale calm candidate rejects without second reduction")

 g=Game.new(42,true,"pressure")
 var belt=g.state.equipment[0].id
 card=t.hand_card(g,"strain")
 var c=t.find_action(g,"card",{"uid":card.uid,"slot":"wrist","target":belt})
 var damage=c.payload.preview.damage
 t.check(t.action(g,"card",{"uid":card.uid,"slot":"wrist","target":belt}).ok and g.state.pressure==90,"PRESSURE strain source triggers once after real damage")
 t.check(is_equal_approx(g._equipment(belt).durability,12.8-damage),"PRESSURE does not alter escape damage")
 card=t.hand_card(g,"strain")
 t.check(t.action(g,"card",{"uid":card.uid,"slot":"wrist","target":belt}).ok and g.state.overloaded and g.state.pressure==10 and g.state.mana==80,"PRESSURE second strain immediately overloads with remainder")
 var climax_view=g.get_view()
 t.check(climax_view.climax.cue=="climax.narration.normal" and climax_view.climax.text.begins_with("你的") and climax_view.speech.cue=="hero.climax.normal.clear","PRESSURE committed climax projects second-person narration separately from spoken dialogue")
 t.check(g.state.energy==0 and g.state.hand.is_empty() and g.candidates().filter(func(c):return c.payload.kind not in ["flask","item_discard"]).size()==1 and g.candidates()[0].payload.kind=="end","PRESSURE no card, ordinary tool, posture or early exit after interruption")
 old=JSON.stringify(g.state)
 t.check(not g.dispatch(c.id,g.state.version).ok and JSON.stringify(g.state)==old,"PRESSURE interrupted card cannot be submitted again")
 t.check(t.action(g,"end").ok and g.state.pressure==35 and g.state.energy==2 and g.state.rest_left==5 and not g.state.overloaded,"PRESSURE finish interrupted rest once, end pulse once and apply next penalty once")
 t.action(g,"end")
 t.check(g.state.energy==3 and g.state.pressure==60 and g.state.overload_energy==0,"PRESSURE energy penalty is consumed, pressure carries into following round")

 g=Game.new(42,true,"pressure")
 belt=g.state.equipment[0].id
 t.check(t.action(g,"hook",{"target":belt}).ok and t.action(g,"hook",{"target":belt}).ok and g.state.pressure_sources.size()==2 and g.state.pressure==70,"PRESSURE ordinary belt removal does not erase independent room sources")
 t.check(g.get_view().pressure.sources[0].name==g.state.pressure_sources[0].name and g.state.pressure_sources[0].room==g.state.room and g.state.pressure_sources[0].equipment=="","PRESSURE UI describes actual room source without equipment dependency")
 g.state.pressure=99
 P.gain(g,251,"多段脉冲")
 t.check(g.state.pressure==50 and g.state.overload_count==3 and g.state.overload_energy==3 and g.state.mana==40,"PRESSURE one gain can overload three times and stacks all penalties")
 P.gain(g,160,"追加脉冲")
 t.check(g.state.pressure==10 and g.state.overload_count==5 and g.state.overload_energy==5 and g.state.mana==0,"PRESSURE already interrupted turn still accepts further pulses")
 g.state.next_energy=1
 g.state.pressure_sources=[]
 t.action(g,"end")
 t.check(g.state.energy==0 and not g.state.overloaded and g.state.overload_energy==0,"PRESSURE next energy bonuses offset stacked penalty with zero floor")
 t.action(g,"end")
 t.check(g.state.energy==3,"PRESSURE unused penalty never leaks into later rounds")

 g=Game.new(42,true,"pressure_battle")
 t.check(g.state.phase=="battle" and g.state.enemies.all(func(e):return e.intent.pressure==65) and g.get_view().enemies.all(func(e):return e.intent_icons.any(func(icon):return icon.kind=="debuff")),"PRESSURE battle practice has actual publicly frozen skills")
 t.action(g,"end")
 t.check(g.state.pressure==98 and g.state.mana==80 and g.state.energy==2 and g.state.round==2 and g.state.enemies.all(func(e):return e.stage==2),"PRESSURE free cooling precedes both first-order enemies and prevents the second overload")
 g=Game.new(42,true,"pressure_battle")
 g.state.posture="lie"
 g.state.pressure=70
 g._start_round()
 t.check(g.state.overloaded and g.state.pressure==0 and g.state.overload_count==2 and g.state.overload_energy==2 and g.state.energy==0,"PRESSURE last-order enemies interrupt this player turn before any action")
 t.check(g.state.enemies.all(func(e):return e.stage==2),"PRESSURE first overload does not cancel second enemy")
 t.action(g,"end")
 t.check(g.state.enemies.all(func(e):return e.stage==3) and g.state.round==3 and g.state.overload_total==3,"PRESSURE last-order continue does not execute previous enemy phase twice")
 g=Game.new(42,true,"pressure_battle")
 var enemy=g.state.enemies[0]
 g.state.round=2
 g.state.card_buffs.append("infusion_bound") # Interruption fixture; the card itself has separate casting tests.
 t.action(g,"attack",{"type":"kick","form":2,"enemy":enemy.id})
 t.action(g,"end")
 t.check(g.state.pressure==33 and g.state.overload_total==1 and g.state.enemies[0].stage==1 and g.state.enemies[1].stage==2,"PRESSURE interrupt delays skill and attachment together")
 g=Game.new(42,true,"pressure_battle")
 g.state.pressure_sources=[]
 var guard=0
 while g.state.phase=="battle" and guard<8:
  t.check(t.action(g,"end").ok,"PRESSURE complete practice encounter")
  guard+=1
 t.check(g.state.phase=="reward" and g.state.reward_count==1 and g.state.overloaded and g.state.overload_energy>0,"PRESSURE victory keeps next-turn penalty and rewards once")
 var penalty=g.state.overload_energy
 var remaining=g.state.pressure
 var mana=g.state.mana
 t.action(g,"reward",{"type":"skip"})
 t.check(g.state.phase=="prepare" and g.state.energy==maxi(0,3-penalty) and not g.state.overloaded and g.state.overload_energy==0 and g.state.pressure==remaining and g.state.mana==mana,"PRESSURE first preparation turn consumes carried penalty once")

 while g.carried_items()>g.item_capacity(): t.check(t.action(g,"item_discard",{"item":g.state.items[0].id}).ok,"PRESSURE practice resolves actual reward overflow before leaving")
 t.action(g,"finish_prepare")
 t.check(g.state.phase=="cleared" and g.state.pressure==remaining,"PRESSURE battle practice ends without tower progression")

 for timing in ["turn_start","posture","slip"]:
  g=Game.new(42,true,"equipment")
  g.state.pressure_sources=[source("timed",timing,20)]
  if timing=="turn_start": t.action(g,"end")
  elif timing=="posture": t.action(g,"posture",{"dest":"sit","wall":false})
  else: t.action(g,"hook",{"target":g.equipment_at("wrist")[0].id})
  t.check(g.state.pressure==20,"PRESSURE explicit timing pulses once "+timing)
 g=Game.new(42)
 g.state.pressure_sources=[source("pose","posture",100)]
 t.action(g,"posture",{"dest":"sit","wall":false})
 t.action(g,"end")
 t.check(g.state.round==2 and g.state.overload_total==1,"PRESSURE posture finishes before forced turn and preserves next round")
 g=Game.new(42)
 g.state.pressure=90; g.state.mana=3
 P.gain(g,20,"脉冲")
 t.check(g.state.mana==0 and g.state.pressure==10 and g.validate()=="","PRESSURE magic loss saturates at zero without changing penalty count")
 P.clear_penalties(g)
 g.state.phase="map"; g.state.room="entrance"; g.state.energy=0
 g.state.pressure_sources=[source("travel","travel",100),source("room","travel",100,"","entrance")]
 t.action(g,"depart",{"room":"east"})
 t.action(g,"travel_step")
 t.check(g.state.overload_total==2 and g.state.overload_energy==0 and g.state.pressure==8,"PRESSURE travel resolves global source then free cooling while room source stops")
 g=Game.new(42,true,"pressure")
 g.state.pressure_sources[0].amount=-1
 old=JSON.stringify(g.state)
 t.check(not t.action(g,"calm").ok and JSON.stringify(g.state)==old,"PRESSURE invalid source rejects whole command with no resource/log change")

static func formal_sources(t) -> void:
 var Save=preload("res://tests/persistence_cases.gd")
 var g=Game.new(42)
 var before=g.state.duplicate(true)
 g.get_view();g.candidates();g.EquipmentOffers.options(g)
 t.check(g.state==before,"SOURCE view and generation probes are read-only")
 var restored
 g=Game.new(42,true,"guard")
 for turn in range(5):
  t.check(t.action(g,"end").ok and g.state.pressure==0 and g.state.pressure_sources.is_empty(),"SOURCE guard ordinary rounds create no pressure")
 restored=Save.roundtrip(t,g,"guard without pressure source")
 Save.step_both(t,g,restored,"end")

static func climax_card_practice(t) -> void:
 var g=Game.new(42,true,"climax_card")
 t.check(g.validate()=="" and g.state.phase=="battle" and g.state.pressure==99 and g.state.enemies.size()==1,"CLIMAX PRACTICE starts a valid ordinary battle at 99 pressure")
 t.check(g.state.special_equipment.size()==1 and g.state.special_equipment[0].type=="urethral_rod_low","CLIMAX PRACTICE wears one existing energy-triggered special equipment")
 var cards=g.state.hand.filter(func(card):return card.type=="strain")
 t.check(not cards.is_empty() and g.state.deck.filter(func(deck_card):return deck_card.uid==cards[-1].uid).size()==1,"CLIMAX PRACTICE draws one ordinary strain card through the normal opening path")
 var card=cards[-1];var before=g.export_snapshot()
 var choice=t.find_action(g,"card",{"uid":card.uid,"free":true})
 t.check(choice.valid and choice.cost==1 and choice.mana==0 and g.get_view().practice_options.any(func(row):return row.id=="climax_card" and row.node=="Practice_climax_card") and g.state==before,"CLIMAX PRACTICE uses a readonly ordinary paid card candidate")
 var stale=g.dispatch(choice.id,g.state.version-1)
 t.check(not stale.ok and g.state==before,"CLIMAX PRACTICE stale submission cannot trigger special equipment or climax")
 var result=g.dispatch(choice.id,g.state.version)
 t.check(result.ok and g.state.overloaded and g.state.overload_total==1 and g.state.overload_count==1 and g.state.pressure==5,"CLIMAX PRACTICE paid card triggers the existing special equipment and one formal climax")
 t.check(g.state.energy==0 and g.state.mana==before.mana-g.B.OVERLOAD_MANA and g.state.overload_energy==g.B.OVERLOAD_ENERGY and g.state.special_equipment[0].type=="urethral_rod_low","CLIMAX PRACTICE uses normal interruption, mana loss, weakness and keeps the real equipment")
 var actions=g.candidates().filter(func(candidate):return candidate.payload.kind not in ["flask","item_discard"])
 t.check(actions.size()==2 and actions.any(func(c):return c.payload.kind=="end") and actions.any(func(c):return c.payload.kind=="surrender") and result.get("music_feedback",[]).is_empty(),"CLIMAX PRACTICE keeps continue and surrender while ordinary actions stay blocked")
 var normal=Game.new(42)
 t.check(normal.state.pressure==0 and normal.state.special_equipment.is_empty(),"CLIMAX PRACTICE setup never enters a normal run")


# Feedback 1847ba708526785c2322abae5cdd7561: explicit unlimited-mode fixture.
static func forced_loop_fixture():
 var g=Game.new(3440322309,false,"equipment",true,true,25,false,true)
 g.RelicEffects.gain(g,"cursed_plate_lock")
 g.RelicEffects.gain(g,"ice_heart")
 g.state.room_encounters[g.state.room]="mixed_pair"
 g.room_data(g.state.room).erase("enemy_members")
 g.state.posture="lie"
 g._start_battle()
 g.state.mana=0;g.state.chastity_climax_factor=24
 g.state.pressure=P.maximum(g)-1
 P.gain(g,1,"fixture",true)
 return g

static func forced_loop_exit(t) -> void:
 var g=forced_loop_fixture()
 t.check(g.validate()=="" and g.state.overloaded and g.state.energy==0 and g.state.enemies.size()==2,"FEEDBACK forced loop uses a valid two-enemy unlimited-mode state")
 for i in range(3):
  var round_before=g.state.round
  var stages=g.state.enemies.map(func(enemy):return enemy.stage)
  t.check(t.action(g,"end").ok and g.state.round==round_before+1 and g.state.overloaded and g.state.energy==0,"FEEDBACK continue advances a new round and reproduces repeated interruption")
  t.check(g.state.enemies[0].stage==stages[0]+1 and g.state.enemies[1].stage==stages[1]+1,"FEEDBACK each enemy acts once per continued round")
 var exits=g.candidates().filter(func(c):return c.payload.kind=="surrender")
 t.check(exits.size()==1 and exits[0].valid,"FEEDBACK interrupted battle keeps its formal surrender exit")
 if not exits.is_empty():
  var before=g.export_snapshot();var exit=exits[0]
  t.check(not g.dispatch(exit.id,g.state.version-1).ok and g.state==before,"FEEDBACK stale forced-loop surrender rolls back")
  t.check(g.dispatch(exit.id,g.state.version).ok and g.state.phase=="prison" and g.state.security==1 and g.validate()=="","FEEDBACK surrender exits the interrupted battle through actual intake")
  before=g.export_snapshot()
  t.check(not g.dispatch(exit.id,g.state.version).ok and g.state==before,"FEEDBACK repeated surrender cannot apply a second intake")
 g=forced_loop_fixture()
 for enemy in g.state.enemies.duplicate(): g._damage_enemy(enemy,9999,"magic","fixture")
 g._finish_battle()
 t.check(t.action(g,"reward",{"type":"skip"}).ok and g.state.phase=="prepare" and g.state.overloaded,"FEEDBACK reward enters interrupted preparation")
 var stages=g.state.enemies.map(func(enemy):return enemy.stage)
 var count=g.state.prepare_left
 for i in range(count):
  t.check(t.action(g,"end").ok,"FEEDBACK preparation continuation commits")
  t.check(g.state.prepare_left==count-i-1 and g.state.enemies.map(func(enemy):return enemy.stage)==stages,"FEEDBACK preparation countdown decreases without dead enemies acting")
 t.check(g.state.phase=="map" and not g.state.overloaded and g.state.room in g.state.completed_rooms,"FEEDBACK repeated interruption cannot freeze preparation completion")

 g=forced_loop_fixture();g.state.security=4
 var exit=t.find_action(g,"surrender")
 t.check(exit.valid and g.dispatch(exit.id,g.state.version).ok and g.state.phase=="prison_end" and g.state.security==5,"FEEDBACK screenshot security-four surrender reaches the existing terminal state")
