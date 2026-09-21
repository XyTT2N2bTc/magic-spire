extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const LiveGame=preload("res://core/game.gd")

static func run(t) -> void:
 practice_descriptions(t)
 var health={"gag":24,"rope":30,"tape":30,"cable_tie":30,"lock":28,"mixed_bundle":56,"rope_serpent":60,"trader":56,"versatile":60,"guard":90,"puppeteer":96,"belt":30,"toybox":30,"small_circle":30,"ominous_circle":40,"drone":32,"binding_box":64,"rope_mass":48,"belt_mass":48,"rope_heap":96,"belt_heap":96,"puppet":15,"six_bind":200}
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

static func practice_descriptions(t) -> void:
 var health_text=RegEx.new();health_text.compile("(\\d+)生命")
 for kind in ["iron_man_solo","puppeteer_solo","binding_box_solo","drone_solo","mixed_bundle_solo","mixed_pair","rope_serpent_solo","small_circle_solo","versatile_solo"]:
  var game=LiveGame.new(42,true,kind)
  var before=game.export_snapshot()
  var spec=game.Tower.practice_spec(kind)
  var match=health_text.search(spec.description)
  t.check(match!=null and int(match.get_string(1))==game.state.enemies[0].max_hp,"PRACTICE COPY health matches the real initialized encounter: "+kind)
  t.check(game.export_snapshot()==before,"PRACTICE COPY reading the description preserves state and randomness: "+kind)
  var type=game.state.enemies[0].type
  var original=game.Enemies.TYPES[type].hp
  # A temporary registry change proves descriptions follow balancing, not a copied literal.
  game.Enemies.TYPES[type].hp=original+7
  var changed=LiveGame.new(42,true,kind)
  var updated=health_text.search(changed.Tower.practice_spec(kind).description)
  t.check(updated!=null and int(updated.get_string(1))==changed.state.enemies[0].max_hp and changed.state.enemies[0].max_hp==original+7,"PRACTICE COPY registry edits update both spawned health and freshly read text: "+kind)
  game.Enemies.TYPES[type].hp=original
