extends RefCounted
const Game=preload("res://tests/game_fixture.gd")

static func run(t) -> void:
 arrest_next_turn(t)
 var g=Game.new(42)
 var before=g.state.duplicate(true)
 t.check(g.EnemyPlans.can_affect_equipment(g,g.state.enemies[0]),"SATURATION free capacity keeps a charging enemy relevant")
 t.check(g.state==before,"SATURATION availability leaves state and random counters unchanged")
 # Fill one actual enemy's complete pool using the shared installer.
 g.state.enemies.clear()
 g._spawn_enemies("rope_solo")
 var enemy=g.state.enemies[0]
 var spec=g.EnemyPlans.application(g.Enemies.TYPES.rope.install_pool,2,3)
 for i in range(200):
  if not g.Application.execute(g,spec,enemy.id).ok: break
 var piece=g.physical_pieces().filter(func(p):return p.template=="rope")[0]
 piece.durability=piece.maximum*0.7
 before=g.state.duplicate(true)
 t.check(not g.Application.can_apply(g,spec,enemy.id),"SATURATION fixture has no remaining installation positions")
 t.check(g.EnemyPlans.can_affect_equipment(g,enemy) and not g._finish_if_saturated(),"SATURATION reinforcement alone keeps battle running")
 t.check(g.state==before,"SATURATION reinforcement check is read-only")
 # Complete every legal reinforcement (including dependent shoulder restoration).
 for i in range(200):
  var targets=g.EnemyPlans.targets(g,enemy,"tighten")
  if targets.is_empty(): break
  g._enemy_operation(enemy,{"kind":"tighten","target":targets[0].id,"tier":3,"text":"加固"})
 t.check(not g.EnemyPlans.can_affect_equipment(g,enemy),"SATURATION fully installed and reinforced source has no remaining operation")
 var count=g.state.reward_count
 var hp=enemy.hp
 t.check(g._finish_if_saturated() and g.state.phase=="reward","SATURATION complete saturation enters reward")
 t.check(enemy.gone and not enemy.defeated and enemy.hp==hp,"SATURATION departure is not a defeat or damage")
 t.check(g.state.reward_count==count+1 and not g._finish_if_saturated() and g.state.reward_count==count+1,"SATURATION reward is issued only once")
 t.check(g.state.logs.back().data.get("battle_end","")=="saturated" and g.validate()=="","SATURATION result copy and final state are valid")
 # Locks use their own legal targets; unrelated low-tightness equipment does not count as reinforcement.
 g=Game.new(42)
 g.state.enemies.clear();g._spawn_enemies("lock_solo")
 enemy=g.state.enemies[0]
 piece=g._install_template("belt","wrist",4,10,false,"fixture")
 t.check(g.EnemyPlans.can_affect_equipment(g,enemy),"SATURATION an unlocked target keeps a lock enemy active")
 piece.locked=true
 t.check(not g.EnemyPlans.can_affect_equipment(g,enemy),"SATURATION lock source cannot borrow reinforcement capability")
 g._append_enemies([{"type":"rope","grade":1}])
 t.check(g.state.enemies.size()==2 and not g._finish_if_saturated(),"SATURATION another living enemy's capacity keeps the encounter running")
 g.state.enemies.back().gone=true
 enemy.intent={"kind":"lock","text":"上锁","delayed":false}
 before=g.state.duplicate(true)
 t.check(not g.dispatch("forged",g.state.version).ok and g.state==before,"SATURATION rejected commands cannot end battles")
 t.check(t.action(g,"end").ok and g.state.phase=="reward","SATURATION formal turn boundary ends battle before a targetless enemy action")
 # Saturated initial encounters finish without pretending a lock has been defeated.
 g=Game.new(42)
 g.state.room_encounters.entrance="lock_solo"
 g._start_battle()
 t.check(g.state.phase=="reward" and not g.state.enemies[0].defeated,"SATURATION encounter entry checks the current enemy roster")

static func exhaust(g, enemy: Dictionary) -> void:
 # Use the same real installation/replacement and reinforcement operations.
 # The bound is a test guard, never a rule or a scripted arrest threshold.
 for step in range(400):
  var progressed=false
  for plan in g.EnemyPlans.installation_intents(g,enemy):
   var spec=g.EnemyPlans.application_spec(g,enemy,plan)
   if not g.Application.can_apply(g,spec,enemy.id): continue
   g._enemy_operation(enemy,plan);progressed=true
  var targets=g.EnemyPlans.targets(g,enemy,"tighten")
  # Only sources that really reinforce use this helper's reinforcement pass.
  if g.Enemies.behavior(enemy.type) in ["six_bind","guard","drone","binding_box"] and not targets.is_empty():
   g._enemy_operation(enemy,{"kind":"tighten","target":targets[0].id,"tier":3,"text":"加固","delayed":false});progressed=true
  if not progressed: return

static func arrest_next_turn(t) -> void:
 var g=Game.new(42)
 g.state.enemies.clear();g._spawn_enemies("drone_solo")
 var enemy=g.state.enemies[0]
 exhaust(g,enemy)
 t.check(not g.EnemyPlans.can_affect_equipment(g,enemy),"ARREST drone fixture exhausts real installation and reinforcement capacity")
 var before=g.export_snapshot()
 t.check(not g._finish_if_saturated() and g.state==before,"ARREST mechanical saturation never grants victory or immediately captures")
 var target=g.state.equipment.filter(func(e):return e.template=="tape")[0]
 target.durability=target.maximum*0.8
 enemy.intent={"kind":"tighten","target":target.id,"tier":3,"text":"加固","delayed":false}
 t.check(g.EnemyPlans.can_affect_equipment(g,enemy),"ARREST a final real reinforcement still delays arrest")
 var round=g.state.round;var rewards=g.state.reward_count
 t.check(t.action(g,"end").ok and g.state.phase=="battle" and g.state.round==round+1,"ARREST completing the last reinforcement gives the next player turn")
 enemy=g._enemy(enemy.id)
 t.check(enemy.intent.kind=="capture" and not g.CaptureBind.has_bind(g),"ARREST announces capture without requiring an existing capture bar")
 before=g.export_snapshot();g.get_view();g.candidates()
 t.check(g.state==before,"ARREST reading the capture announcement is pure")
 var restored=preload("res://tests/persistence_cases.gd").roundtrip(t,g,"saturated capture announcement")
 t.check(restored.state.enemies[0].intent.kind=="capture","ARREST current snapshot preserves the announced action")
 t.check(t.action(g,"end").ok and g.state.phase=="captured" and g.state.reward_count==rewards,"ARREST next enemy turn follows real imprisonment without rewards")
 t.check(g.state.capture.by==enemy.name and g.validate()=="","ARREST records the actual captor and valid prison result")
 g=Game.new(42);g.state.enemies.clear();g._spawn_enemies("drone_solo")
 enemy=g.state.enemies[0];exhaust(g,enemy)
 var ally=g._append_enemies([{"type":"rope","grade":1}])[0]
 before=g.export_snapshot()
 t.check(g.EnemyPlans.can_affect_equipment(g,ally) and g._plan(enemy).kind!="capture","ARREST another living enemy's actual equipment space postpones arrest")
 t.check(g.state.equipment==before.equipment,"ARREST planning cannot install equipment")
 ally.gone=true
 t.check(g._plan(enemy).kind=="capture","ARREST gone allies do not keep a saturated battle open")
 var box=Game.new(42);box.state.enemies.clear();box._append_enemies([{"type":"binding_box","grade":2}])
 var source=box.state.enemies[0]
 var plans=box.EnemyPlans.installation_intents(box,source)
 t.check(plans.filter(func(p):return p.pool=="composite").size()==source.carried_indices.size(),"ARREST box repertoire includes actual remaining carried composites")
 source.carried_indices.clear()
 t.check(box.EnemyPlans.installation_intents(box,source).all(func(p):return p.pool!="composite"),"ARREST consumed box inventory does not create phantom replacement capacity")
