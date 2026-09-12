extends RefCounted
const CaptureBind=preload("res://core/capture_bind.gd")
const Game=preload("res://tests/game_fixture.gd")
const Guard=preload("res://core/guard.gd")

static func bind(g, enemy: Dictionary, progress: float=50.0) -> void:
 g.state.guard_bind={"progress":progress,"sources":{"guard":{"enemy":enemy.id,"energy":0}}}
 enemy.guard.bind_ready=false

static func ready(g) -> void:
 var enemy=g.state.enemies.filter(func(e):return g.Enemies.behavior(e.type)=="guard")[0]
 bind(g,enemy,100.0)
 enemy.stage=4
 enemy.intent=Guard.build(g,enemy)

static func run(t) -> void:
 var g=Game.new(42,true,"guard")
 var e=g.state.enemies[0]
 var pool=g.Enemies.TYPES.guard.visual_pool
 t.check(e.visual_variant in pool and g.get_view().enemies[0].visual_variant==e.visual_variant,"GUARD generated portrait variant is projected from stable enemy state")
 var duplicate_found=false
 for seed in range(12):
  var sample=Game.new(seed,true,"double_guard")
  var variants=sample.state.enemies.map(func(enemy):return enemy.visual_variant)
  t.check(variants.size()==2 and variants.all(func(variant):return variant in pool),"GUARD each paired guard independently draws a registered portrait "+str(seed))
  if variants[0]==variants[1]: duplicate_found=true
 t.check(duplicate_found,"GUARD independent portrait draws explicitly allow duplicate results")
 var fixed_variant=e.visual_variant
 t.check(e.type=="guard" and e.hp==90 and e.intent.kind=="guard_sequence" and e.intent.operations.size()==3,"GUARD opening publishes three fixed applications")
 t.check(e.intent.operations.map(func(op):return op.required_slots[0])==["wrist","mouth","ankle"] and e.intent.operations.all(func(op):return op.grade==2 and op.tier==2 and op.replace),"GUARD opening fixes wrist mouth ankle at medium tier two")
 t.check(t.action(g,"end").ok and g.occupied("wrist") and g.occupied("mouth") and g.occupied("ankle") and g._enemy(e.id).intent.kind=="bind_prepare" and g._enemy(e.id).visual_variant==fixed_variant,"GUARD opening uses real application factory and keeps its generated portrait")
 t.check(t.action(g,"end").ok and g._enemy(e.id).guard.bind_ready and g._enemy(e.id).intent.kind=="bind_apply" and g.state.guard_bind.is_empty(),"GUARD preparation consumes one full enemy action")
 t.check(t.action(g,"end").ok and g.state.guard_bind.progress==50.0 and g.level("arms")>=1 and g._enemy(e.id).intent.kind=="apply" and g._enemy(e.id).intent.count==2,"GUARD bind starts at fifty and enters two-restraint cycle")

 e=g._enemy(e.id)
 e.guard.cycle_step=1;e.intent=Guard.build(g,e)
 t.check(e.intent.kind=="bind_gain","GUARD second cycle step publishes bind gain")
 t.check(t.action(g,"end").ok and g.state.guard_bind.progress==60.0 and g._enemy(e.id).guard.cycle_step==2,"GUARD bind gain advances the cycle")
 e=g._enemy(e.id)
 e.intent=Guard.build(g,e)
 t.check((e.intent.kind=="apply" and e.intent.pool=="composite") or (e.intent.kind=="equipment_batch" and e.intent.tighten and e.intent.count==2 and e.intent.tier==3),"GUARD third cycle step chooses composite or total-six reinforcement fallback")
 var fallback=Guard.reinforcement(g,e)
 t.check(fallback.kind=="equipment_batch" and fallback.tighten and fallback.count==2 and fallback.tier==3,"GUARD unavailable composite fallback represents two tier-three reinforcements totaling six")

 g=Game.new(7,true,"guard")
 e=g.state.enemies[0]
 bind(g,e,100.0)
 e.stage=4;e.intent={"kind":"bind_gain","text":"捕缚进度＋10","delayed":false}
 t.check(t.action(g,"end").ok and g._enemy(e.id).intent.kind=="capture" and g.state.phase=="battle","GUARD full bind schedules capture for the next enemy action")
 var mana=g.state.mana
 t.check(t.action(g,"end").ok and g.state.phase=="captured" and g.state.security==1 and g.state.mana==mana and g.state.guard_bind.is_empty() and g.state.reward_count==0,"GUARD capture clears bind and enters prison without battle reward")

 g=Game.new(9,true,"guard")
 e=g.state.enemies[0]
 g.state.equipment.clear();g.state.composites.clear();g.state.links.clear()
 bind(g,e)
 var strain=t.hand_card(g,"strain")
 var candidate=t.find_action(g,"card",{"uid":strain.uid,"target":CaptureBind.BIND_TARGET})
 t.check(not candidate.is_empty() and candidate.valid and candidate.payload.preview.damage==12.0 and candidate.payload.preview.environment_true==0.0,"GUARD bind takes doubled full card damage with no non-head restraint and no wall bonus")
 t.check(t.action(g,"card",{"uid":strain.uid,"target":CaptureBind.BIND_TARGET}).ok and g.state.guard_bind.progress==38.0 and g.state.pressure in [6.0,10.0,15.0],"GUARD paid bind attack also stimulates one random special position with sensitivity")

 g=Game.new(10,true,"guard")
 e=g.state.enemies[0]
 bind(g,e)
 g._install_template("rope","wrist",8,10,false,"fixture")
 strain=t.hand_card(g,"strain")
 candidate=t.find_action(g,"card",{"uid":strain.uid,"target":CaptureBind.BIND_TARGET})
 t.check(candidate.payload.preview.damage==6.0,"GUARD any non-head restraint removes the damage doubling")
 e.stage=4
 CaptureBind.damage_bind(g,50.0,"测试")
 t.check(g.state.guard_bind.is_empty() and not CaptureBind.has_bind(g) and e.intent.kind=="bind_prepare","GUARD zero progress immediately replaces the old cycle intent with preparation")

 g=Game.new(14,true,"guard")
 e=g.state.enemies[0]
 bind(g,e,95.0);e.stage=4;e.intent=Guard.application(Guard.ordinary_templates(),2)
 CaptureBind.gain_bind(g,10.0,"测试推进")
 CaptureBind.observe(g)
 t.check(g.state.guard_bind.progress==100.0 and e.intent.kind=="capture","GUARD reaching full progress replaces the pending cycle with the next capture action")

 g=Game.new(11,true,"guard")
 e=g.state.enemies[0]
 bind(g,e)
 g.state.posture="stand"
 var down=t.find_action(g,"posture",{"dest":"sit","wall":false})
 t.check(not down.valid and down.reason.contains("不能反向切换"),"GUARD bind blocks standing to sitting")
 g.state.posture="lie"
 var up=t.find_action(g,"posture",{"dest":"sit","wall":false})
 var before=g.state.guard_bind.progress
 t.check(up.valid and g.dispatch(up.id,g.state.version).ok and g.state.posture=="sit" and g.state.guard_bind.progress==before+10.0,"GUARD bind permits lie to sit and adds ten progress")

 g=Game.new(12,true,"double_guard")
 var first=g.state.enemies[0]
 var second=g.state.enemies[1]
 bind(g,first)
 CaptureBind.apply_bind(g,second)
 t.check(g.state.guard_bind.progress==50.0 and g.state.guard_bind.sources.guard.enemy==first.id,"GUARD bind is nonstacking across two guards")
 first.hp=1;second.hp=1
 t.check(t.action(g,"attack",{"type":"strike","enemy":first.id}).ok and g.state.phase=="battle","GUARD defeating one of two guards does not end battle")
 t.check(t.action(g,"attack",{"type":"strike","enemy":second.id}).ok and g.state.phase=="reward" and g.state.guard_bind.is_empty(),"GUARD battle victory clears bind and grants one reward")

 g=Game.new(13,true,"guard")
 e=g.state.enemies[0]
 bind(g,e,95.0)
 g.state.pressure=95.0
 g.Pressure.gain(g,10.0,"测试刺激")
 t.check(g.state.guard_bind.progress==100.0 and g.state.overload_count==1 and e.intent.kind=="capture","GUARD each climax adds ten bind progress and schedules capture")
 t.check(g.validate()=="","GUARD new state and cycle remain valid")
