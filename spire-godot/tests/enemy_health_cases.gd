extends RefCounted
const Game=preload("res://tests/game_fixture.gd")

static func run(t) -> void:
 var health={"gag":24,"rope":30,"tape":30,"cable_tie":30,"lock":28,"mixed_bundle":56,"rope_serpent":60,"trader":56,"versatile":60,"guard":90,"puppeteer":96,"belt":30,"toybox":30,"small_circle":30,"ominous_circle":40,"drone":32,"binding_box":64,"rope_mass":48,"belt_mass":48,"rope_heap":96,"belt_heap":96,"puppet":10,"six_bind":220}
 for cycle in range(3):
  var g=Game.new(42);g.state.demo_cycle=cycle;g.state.enemies=[]
  var factor=[1.0,1.5,2.0][cycle]
  for type in health:
   var enemy=g._append_enemies([{"type":type,"grade":1}])[0]
   t.check(enemy.hp==health[type]*factor and enemy.max_hp==health[type]*factor,"HEALTH shared spawn uses approved base and cycle multiplier: "+type+" cycle "+str(cycle))
 var g=Game.new(42,true,"rope_solo");var id=g.state.enemies[0].id
 for i in range(2): t.check(t.action(g,"attack",{"type":"fireball","enemy":id}).ok,"HEALTH weak rope accepts two ordinary fireballs")
 t.check(g._enemy(id).hp==6 and not g._enemy(id).gone and g.state.energy==2 and g.state.mana==80,"HEALTH thirty-HP weak rope survives two twelve-damage fireballs")
 g=Game.new(42,true,"rope_serpent_solo");id=g.state.enemies[0].id
 for type in ["fireball","fireball","heavy"]: t.check(t.action(g,"attack",{"type":type,"enemy":id}).ok,"HEALTH ideal opening uses formal attack: "+type)
 t.check(g._enemy(id).hp==18 and g.state.energy==0,"HEALTH sixty-HP serpent survives the forty-two-damage three-energy opening")
