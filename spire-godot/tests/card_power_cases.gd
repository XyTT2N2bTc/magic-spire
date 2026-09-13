extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Save=preload("res://tests/persistence_cases.gd")

static func give(t,g) -> Dictionary:
 g._gain_card("fire_mastery")
 return t.hand_card(g,"fire_mastery")

static func fire(t,g) -> Dictionary:
 return t.find_action(g,"attack",{"type":"fireball","enemy":g.state.enemies[0].id})

static func run(t) -> void:
 reuse(t)
 preload("res://tests/resonance_cases.gd").run(t)
 preload("res://tests/cumulative_cards_cases.gd").run(t)
 preload("res://tests/practiced_cases.gd").run(t)
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
 t.check(c.valid and c.cost==1 and c.mana==0 and c.payload.self_target,"POWER self-target one-energy candidate")
 g.get_view();g.candidates()
 t.check(g.state==before and not g.dispatch(c.id,g.state.version-1).ok and g.state==before,"POWER preview and stale submission preserve state")
 g.state.energy=0;before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":card.uid,"free":false}).ok and g.state==before,"POWER insufficient energy refuses atomically")
 g.state.energy=3
 var result=t.action(g,"card",{"uid":card.uid,"free":false})
 t.check(result.ok and g.state.energy==2 and g.state.mana==100 and g.state.powers[0].uid==card.uid and g.validate()=="","POWER actual play conserves card in ability zone and pays only energy")
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
     var energy=g.state.energy
     t.check(helper.play(t,g,"slip",false,{"target":target.id}).ok and g._equipment(target.id).is_empty() and g.state.hand.size()==count+2,"STACK release draws twice")
     t.check(g.state.energy==energy+1,"STACK two embrace copies recover two energy after paying one for slip")
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


static func reuse(t) -> void:
 var Cards=preload("res://tests/curse_cases.gd")
 var Rules=preload("res://data/card_rules.gd")
 t.check("reuse" in Rules.UNCOMMON and Rules.energy_cost("reuse",true)==1 and Rules.energy_cost("reuse",false)==2 and Rules.unique_face("reuse",true) and Rules.unique_face("reuse",false),"REUSE uncommon reward, asymmetric costs and both unique faces")
 # Positive, nearest counterexamples and exact two-level boundary.
 for levels in [[0,0],[1,2],[2,1],[2,2]]:
  var g=Game.new(42);g._discard_end();g.state.energy=30;g.state.equipment.clear()
  if levels[0]>0: g.add_fixture("wrist" if levels[0]==2 else "upper_arm",8)
  if levels[1]>0: g.add_fixture("ankle" if levels[1]==2 else "thigh",8)
  var card=Cards.give(g,"reuse")
  var c=t.find_action(g,"card",{"uid":card.uid,"free":false})
  var before=g.export_snapshot();g.get_view();g.candidates()
  var allowed=levels==[2,2]
  t.check(c.valid==allowed and g.state==before,"REUSE both regions required at exact level two: "+str(levels))
  t.check(not g.dispatch(c.id,g.state.version-1).ok and g.state==before,"REUSE stale play preserves resources, piles and random state")
  if not allowed:
   t.check(c.reason.contains("束缚等级需≥2") and not g.dispatch(c.id,g.state.version).ok and g.state==before,"REUSE blocked play reports missing region and rolls back")
  else:
   t.check(g.dispatch(c.id,g.state.version).ok and g.state.energy==28 and g.state.powers.size()==1 and g.state.rng.magic==0,"REUSE activation pays two without a spell roll")
 # Each source is refunded to its own pool, without stacking percentages.
 for faces in [[],[true],[false],[true,false]]:
  for temporary in [0.0,4.0,30.0]:
   var g=Game.new(42);g._discard_end();g.state.equipment.clear();g.state.relics=[];g.state.energy=30
   g.add_fixture("wrist",8);g.add_fixture("ankle",8)
   for free in faces: t.check(Cards.play(t,g,"reuse",free).ok,"REUSE activates each distinct face")
   g.state.pressure=75;g.state.mana=50;g.state.temporary_mana=temporary
   var cursor=g.state.rng.get("magic",0)
   while g._random_index("magic",g.B.CAST_ROLL_STEPS)<g.cast_view().winning_rolls: cursor=g.state.rng.magic
   g.state.rng.magic=cursor
   var c=fire(t,g);var before=g.export_snapshot()
   var permanent_rate=0.8 if false in faces else 0.5
   var temporary_rate=0.8 if not faces.is_empty() else 0.5
   t.check(g.dispatch(c.id,g.state.version).ok and g._magic_failed,"REUSE real paid spell fails")
   var spell=g.state.logs.filter(func(row):return row.data.has("spell")).back().data.spell
   t.check(is_equal_approx(g.state.mana,before.mana-c.mana_payment.mana*(1-permanent_rate)) and is_equal_approx(g.state.temporary_mana,before.temporary_mana-c.mana_payment.temporary_mana*(1-temporary_rate)),"REUSE separate refund pools for "+str(faces)+" temporary="+str(temporary))
   t.check(is_equal_approx(spell.mana_refund.mana,c.mana_payment.mana*permanent_rate) and is_equal_approx(spell.mana_refund.temporary_mana,c.mana_payment.temporary_mana*temporary_rate) and g.state.energy==before.energy-c.cost and g.state.flask_mana==before.flask_mana,"REUSE structured log matches refunds, energy remains spent and flask untouched")
 var g=Game.new(42);g._discard_end();g.state.energy=30;g.state.equipment.clear()
 var wrist=g.add_fixture("wrist",8);g.add_fixture("ankle",8)
 Cards.play(t,g,"reuse",true);Cards.play(t,g,"reuse",false)
 for free in [true,false]:
  var card=Cards.give(g,"reuse");var before=g.export_snapshot()
  t.check(not t.action(g,"card",{"uid":card.uid,"free":free}).ok and g.state==before,"REUSE same face unique rejects duplicate without payment")
 g._equipment(wrist.id).durability=0;g._cleanup()
 t.check(g.Cards.failure_refund_rates(g)=={"mana":0.5,"temporary_mana":0.8} and g.get_view().statuses.any(func(row):return row.id=="power_reuse_bound" and row.value.contains("未生效")),"REUSE removal immediately pauses bound refund and preserves free refund")
 g.add_fixture("wrist",8)
 t.check(g.Cards.failure_refund_rates(g)=={"mana":0.8,"temporary_mana":0.8},"REUSE re-equipping restores eighty percent refund without replaying the power")
 var palm=g.add_fixture("palm",8)
 t.check(g.level("arms")==3 and g.level("legs")==2 and g.Cards.failure_refund_rates(g).mana==0.8,"REUSE only upper level three does not upgrade refund")
 var foot=g.add_fixture("foot",8)
 t.check(g.level("arms")==3 and g.level("legs")==3 and g.Cards.failure_refund_rates(g)=={"mana":1.0,"temporary_mana":1.0},"REUSE both regions at three immediately upgrade to full refund")
 g.state.pressure=99;g.state.mana=50;g.state.temporary_mana=4
 var full=fire(t,g);var full_before=g.export_snapshot()
 t.check(g.dispatch(full.id,g.state.version).ok and g._magic_failed and g.state.mana==full_before.mana and g.state.temporary_mana==full_before.temporary_mana and g.state.energy==full_before.energy-full.cost,"REUSE live three-three failure returns both entire payments but never energy")
 g._equipment(palm.id).durability=0;g._cleanup()
 t.check(g.level("arms")==2 and g.level("legs")==3 and g.Cards.failure_refund_rates(g).mana==0.8,"REUSE only lower level three and downgrade immediately use eighty percent")
 g.add_fixture("palm",8)
 var restored=Game.new(0)
 t.check(restored.restore_snapshot(g.export_snapshot()).ok and restored.Cards.failure_refund_rates(restored)==g.Cards.failure_refund_rates(g),"REUSE current save restores both faces and live eligibility")
 g.state.pressure=0;g.state.mana=50;g.state.temporary_mana=4
 var c=fire(t,g);var before=g.export_snapshot()
 t.check(g.dispatch(c.id,g.state.version).ok and not g._magic_failed and is_equal_approx(g.state.mana,before.mana-c.mana_payment.mana) and is_equal_approx(g.state.temporary_mana,before.temporary_mana-c.mana_payment.temporary_mana),"REUSE successful spell gets no failure refund")
 g.Cards.end_powers(g)
 t.check(g.state.powers.is_empty() and g.Cards.failure_refund_rates(g)=={"mana":0.5,"temporary_mana":0.5},"REUSE effect expires with the existing battle power lifecycle")
