extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const TYPE="cursed_plate_lock"

static func run(t) -> void:
 var g=Game.new(42)
 g._install_special("negative_vibrator_lock_catheter_high","special_2_a",3)
 g.RelicEffects.gain(g,TYPE)
 var locks=g.state.special_equipment.filter(g.SpecialEquipment.is_chastity)
 t.check(locks.size()==1 and locks[0].type==TYPE and locks[0].locked and g.tier(locks[0].durability,locks[0].maximum)==3 and g.max_energy()==4,"CURSED PLATE pickup replaces occupied lock and grants energy")
 if locks.size()!=1 or locks[0].type!=TYPE: return
 var lock=locks[0];var original=lock.duplicate(true)
 g._apply_equipment_damage(lock,999,"magic_slip");g._apply_manual_release(lock,0);g._cleanup()
 t.check(lock==original and g.escape_preview(lock,"magic_slip",999,[],false,true).damage==0,"CURSED PLATE rejects manual, area and slip removal")
 t.check(g.Tools.unlock_reason(g,lock).contains("专属钥匙"),"CURSED PLATE ordinary tools report dedicated key requirement")
 t.check(g.candidates().filter(func(c):return c.payload.get("target","")==lock.id).all(func(c):return not c.valid and c.reason.contains("专属钥匙")),"CURSED PLATE all targeted actions are blocked")
 var blocked=g.candidates().filter(func(c):return c.payload.get("target","")==lock.id)
 if not blocked.is_empty():
  var unchanged=g.export_snapshot()
  t.check(not g.dispatch(blocked[0].id,g.state.version).ok and g.state==unchanged,"CURSED PLATE invalid submit changes no resources, logs or equipment")
 var replacement=g.Application.Replacement.plan(g,[{"kind":"special_install","type":"negative_vibrator_lock_catheter_high","slot":"special_2_a","tier":3}],"enemy")
 t.check(not replacement.ok and g._equipment(lock.id)==original,"CURSED PLATE cannot be replaced")
 g._gain_card("henshin");var card=t.hand_card(g,"henshin")
 t.check(t.action(g,"card",{"uid":card.uid,"free":false}).ok and g._equipment(lock.id)==original,"CURSED PLATE henshin preserves lock")
 for i in range(12): g._tick_special("turn_start")
 t.check(g._equipment(lock.id).remaining==0 and g.SpecialEquipment.gain(g._equipment(lock.id),"turn_start")>0,"CURSED PLATE duration remains infinite")
 var snapshot=g.export_snapshot();var restored=Game.new(3)
 t.check(restored.restore_snapshot(snapshot).ok,"CURSED PLATE active curse roundtrips")
 var bad=snapshot.duplicate(true);bad.special_equipment=[]
 var before=restored.export_snapshot()
 t.check(not restored.restore_snapshot(bad).ok and restored.state==before,"CURSED PLATE missing lock rejects atomically")
 for boundary in ["normal","saturated","boss"]:
  g=Game.new(42);g.RelicEffects.gain(g,TYPE)
  if boundary!="normal": g.state.room="summit";g._start_battle()
  for enemy in g.state.enemies.duplicate(): g._damage_enemy(enemy,99999,"magic","测试")
  g._finish_battle(boundary=="saturated")
  var released=boundary=="boss"
  t.check(g.state.cursed_plate_released==released and g.state.special_equipment.any(g.SpecialEquipment.is_chastity)!=released,"CURSED PLATE key only follows an actual Boss defeat: "+boundary)
  if released:
   t.check(g.state.special_equipment.is_empty() and g.max_energy()==4 and g.state.logs.any(func(row):return row.data.get("cursed_plate_key",{}).get("used",false)),"CURSED PLATE key automatically removes whole item and strap, retaining energy")
   t.check(restored.restore_snapshot(g.export_snapshot()).ok,"CURSED PLATE released state roundtrips")
   var count=g.state.logs.filter(func(row):return row.data.has("cursed_plate_key")).size()
   g.state.phase="battle";g._finish_battle()
   t.check(count==1 and g.state.logs.filter(func(row):return row.data.has("cursed_plate_key")).size()==count,"CURSED PLATE later Bosses do not drop another key")
 g=Game.new(42)
 t.check(TYPE not in g.SpecialEquipment.prison_pool(3,true,true) and TYPE not in g.SpecialEquipment.generation_pool(g.SpecialEquipment.TYPES.keys(),true),"CURSED PLATE never enters ordinary or prison generation pools")
 g.RelicEffects.gain(g,TYPE)
 g.state.phase="shop"
 var jobs=g.Services.release_jobs(g).filter(func(job):return job.name=="诅咒平板锁")
 t.check(jobs.size()==1 and jobs[0].reason==g.SpecialEquipment.CURSED_PLATE_REASON,"CURSED PLATE shop shows dedicated-key restriction and never permits removal")
 g=Game.new(42)
 var ordinary=g._install_special("negative_vibrator_lock_catheter_high","special_2_a",3)
 t.check(not g.cursed_plate(ordinary) and g.SpecialEquipment.TYPES[ordinary.type].duration==8,"CURSED PLATE original powered lock retains finite duration and normal unlock rules")
 ordinary.locked=false
 g._apply_equipment_damage(ordinary,1,"magic_slip");g._cleanup()
 t.check(g._equipment(ordinary.id).is_empty(),"CURSED PLATE ordinary unlocked lock still releases with positive slip damage")
