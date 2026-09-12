extends RefCounted
const Game=preload("res://tests/game_fixture.gd")

# Start at the already-cleared summit boundary; all choices use formal dispatch.
static func exit_fixture(g) -> void:
 g.state.phase="cleared";g.state.room="exit"
 g.state.completed_rooms=["summit","exit"];g.state.enemies=[];g.state.energy=0

static func run(t) -> void:
 var g=Game.new(42)
 exit_fixture(g)
 var a=preload("res://tests/link_cases.gd").at(g,"thigh_root")
 var b=preload("res://tests/link_cases.gd").at(g,"mid_thigh")
 g._install_link(a.id,b.id,8,"fixture")
 g._install_assembly("arm","long","fixture",2,2)
 g._install_special("crotch_rope_low","special_3_a")
 g.state.mana_max=150.0;g.state.mana=13.0
 var deck=g.state.deck.duplicate(true);var relics=g.state.relics.duplicate()
 var saved=g.export_snapshot();var twin=Game.new(7)
 t.check(twin.restore_snapshot(saved).ok,"DEMO exit snapshot restores pending choices")
 var old_seed=g.state.seed
 var c=t.find_action(g,"demo_continue")
 t.check(not g.dispatch(c.id,g.state.version-1).ok and g.state==saved,"DEMO stale continuation rolls back without clearing equipment")
 t.check(g.dispatch(c.id,g.state.version).ok and t.action(twin,"demo_continue").ok,"DEMO continue commits through original command pipeline")
 var actual=g.export_snapshot();var restored=twin.export_snapshot()
 actual.erase("version");restored.erase("version")
 t.check(actual==restored and g.state.seed!=old_seed and g.state.room=="tower_bottom" and g.state.demo_cycle==1,"DEMO continuation creates reproducible fresh tower and advances one cycle")
 t.check(g.state.deck==deck and g.state.relics==relics and g.state.mana==150 and g.state.mana_max==150 and g.action_targets().is_empty() and g.state.composites.is_empty() and g.state.links.is_empty() and g.state.special_equipment.is_empty(),"DEMO preserves progression, removes all equipment structures and fills actual mana maximum")
 t.check(g.validate()=="" and twin.restore_snapshot(g.export_snapshot()).ok,"DEMO continued run validates and restores")
 var before=g.export_snapshot()
 t.check(not g.dispatch(c.id,saved.version).ok and g.state==before,"DEMO continuation cannot be replayed")
 for cycle in [1,2]:
  if cycle==2:
   exit_fixture(g)
   t.check(t.action(g,"demo_continue").ok,"DEMO second continuation opens final cycle")
  var scale=1.5 if cycle==1 else 2.0
  g.state.enemies=[]
  var boss=g._append_enemies([{"type":"six_bind","grade":2}])[0]
  t.check(boss.hp==220*scale and boss.max_hp==220*scale,"DEMO boss health uses normal base, not compounded previous health")
  var heap=g._append_enemies([{"type":"rope_heap","grade":2}])[0]
  var basis=heap.hp/2
  g._split_enemy(heap,basis)
  var children=g.state.enemies.filter(func(e):return e.get("spawned_from","")==heap.id)
  t.check(children.size()==3 and children[0].max_hp==basis and children[1].max_hp==ceilf(basis/2),"DEMO split inheritance is not scaled twice")
  var custom=g._append_enemies([{"type":"rope","grade":1,"hp":10}])[0]
  t.check(custom.max_hp==10*scale,"DEMO custom encounter health also scales")
  var master=g._append_enemies([{"type":"puppeteer","grade":2}])[0]
  g.Puppets.execute(g,master,{"kind":"puppet_summon"})
  var doll=g.Puppets.owned(g,master)
  g.Puppets.execute(g,master,{"kind":"puppet_mend"})
  t.check(doll.max_hp==10*scale+5 and g.Puppets.validate(g,g.state.enemies,scale)=="","DEMO summon base scales while fixed healing remains five")
 exit_fixture(g)
 t.check(g.candidates().filter(func(c):return c.payload.kind!="item_discard").size()==1 and g.candidates()[0].payload.kind=="demo_end","DEMO third exit offers only end")
 t.check(not t.action(g,"demo_continue").ok and t.action(g,"demo_end").ok and g.state.demo_finished and g.candidates().is_empty(),"DEMO final end closes run without a fourth cycle")
 var result=twin.restore_snapshot(g.export_snapshot())
 t.check(result.ok,"DEMO finished run persists: "+str(result))
 before=twin.export_snapshot()
 for cycle in [-1,3,1.5]:
  var bad=before.duplicate(true);bad.demo_cycle=cycle
  t.check(not twin.restore_snapshot(bad).ok and twin.state==before,"DEMO corrupt cycle rejected atomically")

 g=Game.new(42)
 g.state.relic_seen=g.Relics.REWARDS.duplicate()
 var relic=g.RelicRewards.offer(g,"boss")
 t.check(g.Relics.TYPES[relic].rarity=="boss" and relic not in g.state.relics,"DEMO boss draws only its own unowned relic pool")
 g.state.relics=g.Relics.BOSS_POOL.duplicate()
 t.check(g.RelicRewards.offer(g,"boss")==g.Relics.FALLBACK,"DEMO exhausted boss pool uses rolling log")
