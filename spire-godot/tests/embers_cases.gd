extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Cards=preload("res://tests/curse_cases.gd")

static func play(t,g,type: String,free: bool) -> Dictionary:
 var card=Cards.give(g,type)
 return t.action(g,"card",{"uid":card.uid,"free":free})

static func run(t) -> void:
 for sample in [[5.0,1,0.0],[9.9,1,4.9],[10.0,2,0.0]]:
  var g=Game.new(42);g._discard_end();g.state.mana=sample[0];g.state.energy=0
  var card=Cards.give(g,"embers")
  var c=t.find_action(g,"card",{"uid":card.uid,"free":false})
  var before=g.export_snapshot();g.get_view()
  t.check(c.cost==0 and c.mana==5 and g.state==before,"EMBERS preview only requires base payment and does not draw")
  t.check(g.dispatch(c.id,g.state.version).ok and g.state.hand.size()==sample[1] and is_equal_approx(g.state.mana,sample[2]) and g.state.energy==0,"EMBERS optional fixed payment follows remaining balance including fractional boundary")
 var g=Game.new(42);g._discard_end();g.state.mana=5;g.state.temporary_mana=5;g.state.energy=0
 g.RelicEffects.gain(g,"mana_earring");g.state.combat.mana_spent=15
 t.check(play(t,g,"embers",false).ok and g.state.hand.size()==2 and g.state.mana==0 and g.state.temporary_mana==0 and g.state.energy==1,"EMBERS temporary mana pays first; extra self payment triggers existing mana relic")
 g=Game.new(42);g._discard_end();g.state.energy=20
 for enemy in g.state.enemies: enemy.hp=200;enemy.max_hp=200
 t.check(play(t,g,"fire_mastery",true).ok and play(t,g,"fire_dynamics",true).ok and play(t,g,"embers",true).ok,"EMBERS fire damage and area powers combine")
 var enhanced=g.BasicAttacks.fireball_damage(g)
 t.check(enhanced==(g.B.FIREBALL_ASSISTED+4)*2 and g.get_view().statuses.any(func(s):return s.name=="余火"),"EMBERS adds before multiplication and exposes a real status")
 var duplicate=Cards.give(g,"embers");var before=g.export_snapshot()
 t.check(not t.action(g,"card",{"uid":duplicate.uid,"free":true}).ok and g.state==before,"EMBERS duplicate same-source preparation rejects without payment")
 g.state.pressure=99
 var c=t.find_action(g,"attack",{"type":"fireball"})
 var rng=g.state.rng.magic
 while g._random_index("magic",g.B.CAST_ROLL_STEPS)<g.cast_view(g.Cards.cast_profile(g,"fireball")).winning_rolls: rng=g.state.rng.magic
 g.state.rng.magic=rng
 t.check(g.dispatch(c.id,g.state.version).ok and g._magic_failed and "embers_free" in g.state.card_buffs,"EMBERS failed fireball preserves preparation")
 g.state.pressure=0
 var hp=g.state.enemies.map(func(e):return e.hp)
 t.check(t.action(g,"attack",{"type":"fireball"}).ok and range(hp.size()).all(func(i):return g.state.enemies[i].hp==hp[i]-enhanced) and "embers_free" not in g.state.card_buffs and g.BasicAttacks.fireball_damage(g)==g.B.FIREBALL_ASSISTED*2,"EMBERS whole successful area cast gains bonus once then clears it")
 g=Game.new(42);g._discard_end();g.state.energy=20
 play(t,g,"flame_flourish",false);play(t,g,"embers",true)
 var target=g.add_fixture("thigh",60,60,true)
 c=t.find_action(g,"attack",{"type":"fireball","target":target.id})
 t.check(c.payload.damage==(g.B.FIREBALL_ASSISTED+4)*0.5 and g.dispatch(c.id,g.state.version).ok and "embers_free" not in g.state.card_buffs,"EMBERS equipment fireball uses half enhanced damage and also consumes preparation")
 for free in [false,true]:
  g=Game.new(42);g._discard_end();g.state.pressure=99
  var card=Cards.give(g,"embers")
  c=t.find_action(g,"card",{"uid":card.uid,"free":free})
  rng=g.state.rng.magic
  while g._random_index("magic",g.B.CAST_ROLL_STEPS)<g.cast_view(g.Cards.cast_profile(g,"embers")).winning_rolls: rng=g.state.rng.magic
  g.state.rng.magic=rng;before=g.export_snapshot()
  t.check(g.dispatch(c.id,g.state.version).ok and g._magic_failed and g.state.hand==before.hand and g.state.mana==before.mana-c.mana and g.state.card_buffs==before.card_buffs,"EMBERS failed either face keeps card and grants no draw, extra payment or damage preparation")
