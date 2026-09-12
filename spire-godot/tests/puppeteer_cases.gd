extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Save=preload("res://tests/persistence_cases.gd")

static func doll(g) -> Dictionary:
 return g.Puppets.owned(g,g.state.enemies[0])

static func start(t, awaken: bool=true):
 var g=Game.new(42,true,"puppeteer_solo")
 t.check(t.action(g,"end").ok,"PUPPET summon through the real enemy turn")
 if awaken: t.check(t.action(g,"end").ok,"PUPPET second turn activates the hit response and taunt")
 return g

static func run(t) -> void:
 var g=start(t,false)
 var master_id=g.state.enemies[0].id
 t.check(g.Enemies.TYPES.puppeteer.hp==96 and g.Enemies.TYPES.puppeteer.humanoid and g.Enemies.TYPES.puppet.humanoid and "puppeteer_solo" in g.Enemies.FirstFloor.ELITE_ENCOUNTERS,"PUPPET elite registration, health and both humanoid types")
 var id=doll(g).id
 var before=g.export_snapshot()
 g.candidates();g.get_view()
 t.check(g.state==before and doll(g).hp==10 and not doll(g).puppet_awakened and doll(g).stage==1,"PUPPET summon has innate protection and read-only preview, no early taunt")
 g._damage_enemy(g._enemy(id),12,"physical","测试伤害")
 t.check(g._enemy(id).hp==1 and g._enemy(master_id).hp==93 and g.state.equipment.is_empty(),"PUPPET innate floor forwards exactly three excess damage without an early reaction")
 t.check(t.find_action(g,"attack",{"type":"strike","enemy":master_id}).valid,"PUPPET master remains targetable until awakening")
 var twin=Save.roundtrip(t,g,"puppet before awakening")
 Save.step_both(t,g,twin,"end")
 t.check(doll(g).puppet_awakened and doll(g).stage==1,"PUPPET awakened summon never takes an action")
 var blocked=t.find_action(g,"attack",{"type":"strike","enemy":master_id})
 before=g.export_snapshot()
 t.check(not blocked.valid and blocked.reason.contains("嘲讽") and not g.dispatch(blocked.id,g.state.version).ok and g.state==before,"PUPPET taunt rejects direct master attacks without payment or state change")
 t.check(t.find_action(g,"attack",{"type":"kick","form":1,"enemy":master_id}).valid,"PUPPET taunt does not block area attacks")
 var health=g._enemy(master_id).hp
 t.check(t.action(g,"attack",{"type":"strike","form":1,"enemy":id}).ok,"PUPPET real two-hit attack")
 t.check(g._enemy(master_id).hp==health-8 and g._enemy(id).hp==1 and g.physical_pieces().size()==2 and g.physical_pieces().all(func(e):return e.grade==2 and g.tier(e.durability,e.maximum)==2),"PUPPET two hits at one HP each transfer and install once")

 g=start(t)
 master_id=g.state.enemies[0].id;id=doll(g).id
 t.check(t.action(g,"end").ok and doll(g).max_hp==15 and doll(g).hp==15,"PUPPET third turn now increases maximum by five and fully heals")
 t.check(t.action(g,"end").ok and doll(g).puppet_prepared.keys()==["composite"],"PUPPET fourth turn freezes a composite without equipping the player")
 t.check(t.action(g,"end").ok and doll(g).puppet_prepared.has("special") and g.state.special_equipment.is_empty() and g.state.composites.is_empty(),"PUPPET fifth turn freezes a medium tier-three special without premature installation")
 twin=Save.roundtrip(t,g,"both puppet prepared payloads")
 var prepared=doll(g).puppet_prepared.duplicate(true)
 g._damage_enemy(g._enemy(id),1,"fixed","遗物")
 t.check(doll(g).puppet_prepared==prepared and g.physical_pieces().size()==1,"PUPPET positive non-attack damage reacts but keeps the next-attack payloads")
 before=g.export_snapshot()
 g._damage_enemy(g._enemy(id),0,"fixed","零伤害")
 t.check(g.state==before,"PUPPET zero damage creates no hit reaction")
 t.check(t.action(g,"attack",{"type":"strike","enemy":id}).ok and doll(g).puppet_prepared.is_empty(),"PUPPET next successful attack consumes both prepared slots")
 t.check(g.state.special_equipment.size()==1 and g.state.special_equipment[0].grade==2 and g.tier(g.state.special_equipment[0].durability,g.state.special_equipment[0].maximum)==3,"PUPPET special payload actually installs at medium tier three")
 t.check(g.state.composites.size()==1 and g.state.composites[0].components.all(func(piece):return piece.grade==2 and g.tier(piece.durability,piece.maximum)==2),"PUPPET composite payload uses real components and tier two")
 t.check(t.action(g,"end").ok and doll(g).max_hp==20 and doll(g).hp==20,"PUPPET sixth turn repeats the new mend-composite-special cycle")
 t.check(g.validate()=="","PUPPET reacted and mended encounter retains valid state")
 var good=twin.export_snapshot()
 for key in ["puppet_owner","puppet_mends","puppet_prepared"]:
  var bad=good.duplicate(true)
  var target=bad.enemies.filter(func(e):return e.type=="puppet")[0]
  if key=="puppet_owner": target[key]="enemy_missing"
  elif key=="puppet_mends": target[key]=-1
  else: target[key].special.tier=2
  t.check(not twin.restore_snapshot(bad).ok and twin.state==good,"PUPPET corrupted "+key+" is rejected atomically")
 Save.step_both(t,twin,Save.roundtrip(t,twin,"ready puppet deterministic hit"),"attack",{"type":"fireball","enemy":id})

 g=start(t);master_id=g.state.enemies[0].id;id=doll(g).id
 g._enemy(id).hp=1;g._enemy(master_id).hp=3
 t.check(t.action(g,"attack",{"type":"strike","form":1,"enemy":id}).ok and g.state.enemies.all(func(e):return e.gone),"PUPPET lethal transfer dismisses the puppet during the hit sequence")
 t.check(g.state.phase=="reward" and g.state.reward_count==1 and g.physical_pieces().size()==1,"PUPPET no post-death second hit, one reaction and one room reward")
 t.check(g.get_view().statuses.all(func(s):return not s.id.begins_with("puppet_")),"PUPPET death removes protection, taunt and prepared status")

 g=start(t);master_id=g.state.enemies[0].id;id=doll(g).id
 var sweep_damage=float(g.BasicAttacks.TYPES.kick[1].damage)
 health=g._enemy(master_id).hp
 t.check(t.action(g,"attack",{"type":"kick","form":1,"enemy":master_id}).ok and g._enemy(master_id).hp==health-sweep_damage and doll(g).hp==10-sweep_damage and g.physical_pieces().size()==1,"PUPPET actual area attack hits master and doll while taunted, reacting once")
 g=start(t,false);master_id=g.state.enemies[0].id
 g._enemy(master_id).hp=1
 t.check(t.action(g,"attack",{"type":"strike","enemy":master_id}).ok and g.state.phase=="reward" and g.state.reward_count==1,"PUPPET direct defeat before awakening also dismisses the summon and rewards once")

 # Explicit special tightness must survive both original and replacement factories.
 g=Game.new(42)
 var type=g.Enemies.TYPES.puppeteer.special_pool[0]
 var design=g.SpecialEquipment.DESIGNS[type]
 g._install_special(type.replace("_medium","_low"),design.slots[0])
 var applied=g.Application.execute(g,{"pool":"special","templates":[type],"grade":2,"tier":3,"count":1,"replace":true},"fixture")
 t.check(applied.ok and g.state.special_equipment.size()==1 and g.state.special_equipment[0].type==type and g.tier(g.state.special_equipment[0].durability,g.state.special_equipment[0].maximum)==3 and g.validate()=="","PUPPET explicit tier three survives legal special replacement")
