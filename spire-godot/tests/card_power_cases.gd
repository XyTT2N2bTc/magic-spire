extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Save=preload("res://tests/persistence_cases.gd")

static func give(t,g) -> Dictionary:
 g._gain_card("fire_mastery")
 return t.hand_card(g,"fire_mastery")

static func fire(t,g) -> Dictionary:
 return t.find_action(g,"attack",{"type":"fireball","enemy":g.state.enemies[0].id})

static func run(t) -> void:
 stacking(t)
 preload("res://tests/card_music_cases.gd").run(t)
 preload("res://tests/restraint_embrace_cases.gd").run(t)
 preload("res://tests/card_text_cases.gd").run(t)
 preload("res://tests/mana_search_cases.gd").run(t)
 preload("res://tests/echo_cast_cases.gd").run(t)
 preload("res://tests/wildfire_descent_cases.gd").run(t)
 preload("res://tests/adaptability_cases.gd").run(t)
 preload("res://tests/fire_dynamics_cases.gd").run(t)
 preload("res://tests/flame_flourish_cases.gd").run(t)
 preload("res://tests/letter_opener_cases.gd").run(t)
 preload("res://tests/binding_enthusiast_cases.gd").run(t)
 var g=Game.new(42)
 var card=give(t,g)
 var c=t.find_action(g,"card",{"uid":card.uid,"free":false})
 var before=g.export_snapshot()
 t.check(c.valid and c.cost==2 and c.mana==0 and c.payload.self_target,"POWER self-target two-energy candidate")
 g.get_view();g.candidates()
 t.check(g.state==before and not g.dispatch(c.id,g.state.version-1).ok and g.state==before,"POWER preview and stale submission preserve state")
 g.state.energy=1;before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state==before,"POWER insufficient energy refuses atomically")
 g.state.energy=3
 var result=t.action(g,"card",{"uid":card.uid,"free":false})
 t.check(result.ok and g.state.energy==1 and g.state.mana==100 and g.state.powers[0].uid==card.uid and g.validate()=="","POWER actual play conserves card in ability zone and pays only energy")
 t.check(result.card_feedback.any(func(e):return e.kind=="play_power" and e.uid==card.uid) and g.get_view().statuses.any(func(e):return e.id=="power_fire_mastery_bound"),"POWER feedback and status reflect committed ability")
 t.check(fire(t,g).payload.damage==g.B.FIREBALL,"POWER free fingers no longer add gesture damage")
 var duplicate=give(t,g);before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":duplicate.uid,"free":false}).ok and g.state==before,"POWER duplicate refuses without discarding or paying")
 g._install_template("mouth_band","mouth",24.0,24.0,false,"fixture",3,0)
 g.add_fixture("fingers",8)
 g.state.posture="lie";g.state.pressure=75
 var profile=g.Cards.cast_profile(g,"fireball")
 t.check(is_equal_approx(g.cast_view(profile).chance,0.25) and g.cast_view(g.Cards.cast_profile(g,"ease")).chance==0 and fire(t,g).valid,"POWER only fireball ignores mouth equipment; pressure chance remains")
 var restored=Save.roundtrip(t,g,"active power")
 if restored!=null:
  Save.step_both(t,g,restored,"attack",{"type":"fireball","enemy":g.state.enemies[0].id})
  t.check(g.state.powers.size()==1 and g.state.rng.magic==1,"POWER survives casting and uses original random domain")
 g.state.mana=0;before=g.export_snapshot()
 t.check(not t.action(g,"attack",{"type":"fireball","enemy":g.state.enemies[0].id}).ok and g.state==before,"POWER does not bypass magic cost")
 g.state.mana=100;g.state.pressure=0;g.state.energy=3
 g._discard_end();g._draw(5)
 t.check(g.state.powers.size()==1 and not g.state.hand.any(func(x):return x.uid==card.uid) and g.validate()=="","POWER remains out of turn discard and reshuffle")
 var damaged=g.export_snapshot();damaged.powers.append(damaged.hand.pop_back());before=g.export_snapshot()
 t.check(not g.restore_snapshot(damaged).ok and g.state==before,"POWER damaged zone refuses restore atomically")
 for enemy in g.state.enemies: enemy.hp=1
 while g.state.phase=="battle":
  if g.BasicAttacks.usage(g,"fireball").remaining==0:
   t.action(g,"end")
   if g.state.phase!="battle": break
  g.state.energy=3;g.state.mana=100
  var target=g.state.enemies.filter(func(e):return not e.gone)[0]
  var shot=t.action(g,"attack",{"type":"fireball","enemy":target.id})
  t.check(shot.ok,"POWER finish encounter through real fireball")
  if not shot.ok: break
 t.check(g.state.phase=="reward" and g.state.powers.any(func(x):return x.uid==card.uid) and g.validate()=="","POWER victory preserves the active ability")
 t.check(t.action(g,"reward",{"type":"skip"}).ok and t.action(g,"finish_prepare").ok and g.state.powers.is_empty() and g.state.discard.any(func(x):return x.uid==card.uid),"POWER preparation end returns physical power card to discard")
 g=Game.new(42);card=give(t,g);t.action(g,"card",{"uid":card.uid,"free":false})
 g.Guard.capture(g,g.state.enemies[0])
 t.check(g.state.powers.is_empty() and g.validate()=="","POWER capture also clears battle ability")
 g=Game.new(42,true,"equipment");card=give(t,g);before=g.export_snapshot()
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state.powers.size()==1 and g.validate()=="","POWER bound face works during special battle")

 # Registry categories drive every acquisition list and projected face.
 for type in g.Cards.Rules.SPECS:
  var spec=g.Cards.Rules.SPECS[type]
  var face=preload("res://data/encyclopedia.gd").card(type)
  t.check(face.card_type==spec.card_type and face.rarity==spec.rarity and face.single_face==g.Cards.Rules.single_face(type),"CARD classification and single face projection "+type)
  t.check((type in g.Cards.Rules.REWARDS)==(spec.rarity in ["common","uncommon","rare"] and not spec.get("reward_excluded",false)),"CARD reward membership follows rarity and explicit gift exclusion "+type)

static func stacking(t) -> void:
 var helper=preload("res://tests/curse_cases.gd")
 for type in ["wildfire_descent","binding_enthusiast","restraint_embrace","adaptability","letter_opener","flame_flourish"]:
  for free in [false,true]:
   if type=="flame_flourish" and not free: continue
   var g=Game.new(42);g._discard_end();g.state.energy=30
   for copy in range(2):
    var card=helper.give(g,type)
    var c=t.find_action(g,"card",{"uid":card.uid,"free":free})
    var before=g.export_snapshot();g.get_view();g.candidates()
    t.check(c.valid and g.state==before and not g.dispatch(c.id,g.state.version-1).ok and g.state==before,"STACK read-only and stale copy "+type)
    t.check(g.dispatch(c.id,g.state.version).ok,"STACK repeated paid activation "+type)
   var id=g.Cards.Rules.SPECS[type].self_faces["free" if free else "bound"].buff
   t.check(g.Cards.buff_stacks(g,id)==2 and g.state.powers.size()==2 and g.validate()=="","STACK two physical powers remain valid "+id)
   t.check(g.Cards.Rules.BUFFS[id].detail.contains("可叠加"),"STACK status explains repeatable effect "+id)
   if type=="wildfire_descent":
    var count=g.state.hand.size()
    t.check(t.action(g,"attack",{"type":"fireball","enemy":g.state.enemies[0].id}).ok and g.state.hand.size()==count+2,"STACK fireball draws two cards")
   elif type=="adaptability":
    var mana=g.state.temporary_mana;var charge=g.state.charge
    t.check(t.action(g,"end").ok and g.state.temporary_mana==mana+(10 if free else 0) and g.state.charge==charge+(0 if free else 2),"STACK turn-start grants twice")
   elif type=="binding_enthusiast":
    var target=g.add_fixture("eyes",20,20)
    t.check(g.Cards.power_attribute_modifier(g,"strength")==2 and g.Cards.power_attribute_modifier(g,"dexterity")==2,"STACK worn attributes double")
    var pressure=g.state.pressure
    t.check(helper.play(t,g,"pleasure_conversion",false).ok and g.state.pressure==pressure+20,"STACK bound-card pressure doubles too")
    g._equipment(target.id).durability=0;g._cleanup()
    t.check(g.Cards.power_attribute_modifier(g,"strength")==0,"STACK removal recomputes all layers")
   elif type=="restraint_embrace":
    var target=g.add_fixture("ankle",1)
    if free:
     var count=g.state.hand.size()
     t.check(helper.play(t,g,"slip",false,{"target":target.id}).ok and g._equipment(target.id).is_empty() and g.state.hand.size()==count+2,"STACK release draws twice")
    else:
     t.check(g.Cards.pending_draw(g,id)==2,"STACK wear schedules two draws")
     g.Cards.begin_turn(g)
     t.check(g.Cards.pending_draw(g,id)==0 and g.state.logs.filter(func(log):return log.data.get("power_draw",{}).get("requested",0)==1).size()==2,"STACK both scheduled draws delivered once")
   elif type=="letter_opener":
    var target=g.add_fixture("ankle",60,60)
    var hp=g.state.enemies[0].hp
    var damage=g.escape_preview(target,"strain",3,[],false,true).damage
    for i in range(3): t.check(helper.play(t,g,"pleasure_conversion",true).ok,"STACK counted skill")
    t.check(g.state.powers.all(func(card):return card.power_progress==0),"STACK each opener has its own counter")
    if free:
     t.check(g.state.enemies[0].hp==hp-10,"STACK both opener enemy damage effects apply")
    else:
     var hits=g.state.logs.filter(func(log):return log.data.get("power_damage",{}).get("target","")==target.id)
     t.check(hits.size()==2 and is_equal_approx(hits[0].data.power_damage.preview.damage,damage) and hits[0].data.power_damage.after==hits[1].data.power_damage.before and g._equipment(target.id).durability==hits[1].data.power_damage.after,"STACK both opener equipment waves apply in order using current target multipliers")
   else:
    t.check(g.BasicAttacks.usage(g,"fireball").limit==4,"STACK two flourish powers add two maximum casts")
   g.Cards.end_powers(g)
   t.check(g.state.powers.is_empty() and id not in g.Cards.active_buffs(g),"STACK all layers expire together "+id)
