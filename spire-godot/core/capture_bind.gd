extends RefCounted

# Shared bar and source effects. Enemy action cycles remain in their own planners.
const BIND_TARGET="guard_bind"
const BIND_MAXIMUM=100.0
const BIND_GAIN=10.0

static func kind(g, enemy: Dictionary) -> String:
 return g.Enemies.TYPES[enemy.type].get("capture_kind","")

static func has_bind(g, source_kind: String="") -> bool:
 return g.state.phase=="battle" and not g.state.guard_bind.is_empty() and (source_kind=="" or g.state.guard_bind.sources.has(source_kind))

static func movement_reason(g) -> String:
 return "被捕缚时无法移动，先解除捕缚。" if has_bind(g) else ""

static func fixed_posture(g) -> String:
 if not has_bind(g): return ""
 for source in g.state.guard_bind.sources.values():
  var enemy=g._enemy(source.enemy)
  var pose=g.Enemies.TYPES[enemy.type].get("capture_pose","")
  if pose!="": return pose
 return ""

static func posture_reason(g, destination: String) -> String:
 var fixed=fixed_posture(g)
 if fixed!="" and destination!=fixed: return "捕缚将你固定为%s，先解除捕缚。" % g.B.POSE_NAMES[fixed]
 if has_bind(g,"guard") and g.state.posture+">"+destination not in ["lie>sit","sit>stand"]: return "捕缚生效时只能依次从躺姿坐起、再由坐姿站起，不能反向切换。"
 return ""

static func clear_bind(g) -> void:
 g.state.guard_bind={}
 for enemy in g.state.enemies:
  if kind(g,enemy)!="": enemy.guard.bind_ready=false

static func apply_bind(g, enemy: Dictionary) -> void:
 var source_kind=kind(g,enemy)
 enemy.guard.bind_ready=false
 if has_bind(g,source_kind):
  g._emit("event",enemy.name+"的同类捕缚已经生效，没有重复叠加。")
  return
 var initial=float(g.Enemies.TYPES[enemy.type].capture_start)
 var amount=initial*0.5 if has_bind(g) else initial
 if not has_bind(g): g.state.guard_bind={"progress":0.0,"sources":{}}
 g.state.guard_bind.sources[source_kind]={"enemy":enemy.id,"energy":0}
 enemy.guard.cycle_step=0
 var before=float(g.state.guard_bind.progress)
 g.state.guard_bind.progress=minf(BIND_MAXIMUM,before+amount)
 if fixed_posture(g)!="": g.state.posture=fixed_posture(g)
 g._emit("event",enemy.name+"施加捕缚，进度增加%s，现为%s/100。" % [g.number(g.state.guard_bind.progress-before),g.number(g.state.guard_bind.progress)]+("你被固定为%s。" % g.B.POSE_NAMES[fixed_posture(g)] if fixed_posture(g)!="" else ""),{"guard_bind":{"action":"apply","source":enemy.id,"before":before,"value":g.state.guard_bind.progress}})
 observe(g)

static func gain_bind(g, amount: float, source: String) -> void:
 if not has_bind(g) or amount<=0: return
 var before=float(g.state.guard_bind.progress)
 g.state.guard_bind.progress=minf(BIND_MAXIMUM,before+amount)
 g._emit("event",source+"使捕缚进度增加%s，现为%s/100。" % [g.number(g.state.guard_bind.progress-before),g.number(g.state.guard_bind.progress)],{"guard_bind":{"action":"gain","before":before,"value":g.state.guard_bind.progress}})
 observe(g)

static func damage_bind(g, amount: float, source: String) -> void:
 if not has_bind(g) or amount<=0: return
 var before=float(g.state.guard_bind.progress)
 var dealt=minf(before,amount)
 g.state.guard_bind.progress=maxf(0.0,before-amount)
 g._emit("mechanical",source+"削减%s点捕缚进度：%s → %s。" % [g.number(dealt),g.number(before),g.number(g.state.guard_bind.progress)],{"guard_bind":{"action":"damage","before":before,"damage":dealt,"value":g.state.guard_bind.progress}})
 if g.state.guard_bind.progress<=0:
  clear_bind(g)
  g._emit("event","捕缚已挣开。")
 observe(g)

static func damage_multiplier(g) -> float:
 for item in g.action_targets():
  if g.SpecialEquipment.is_special(item) or g.Equipment.coverage(item).any(func(slot):return slot not in ["eyes","mouth"]): return 1.0
 return 2.0

static func energy_spent(g, amount: int, guard_effect: bool=false) -> void:
 if amount<=0: return
 if guard_effect: g.Guard.energy_spent(g)
 if not has_bind(g,"drone"): return
 var source=g.state.guard_bind.sources.drone
 source.energy+=amount
 var enemy=g._enemy(source.enemy)
 while source.energy>=2:
  source.energy-=2
  g._enemy_operation(enemy,g.EnemyPlans.application(g.Enemies.TYPES[enemy.type].install_pool,1,2))
  gain_bind(g,BIND_GAIN,enemy.name+"的捕缚")

static func overload(g, count: int) -> void:
 if count>0 and has_bind(g,"guard"): gain_bind(g,float(count)*BIND_GAIN,"高潮")

static func turn_start(g) -> void:
 if not has_bind(g): return
 for source in g.state.guard_bind.sources.values():
  var enemy=g._enemy(source.enemy)
  var spec=g.Enemies.TYPES[enemy.type]
  if not enemy.gone and spec.get("capture_turn_install",false):
   g._enemy_operation(enemy,g.EnemyPlans.application(spec.capture_pool,2,2))
   gain_bind(g,BIND_GAIN,enemy.name+"的捕缚")

# Empty means keep the already announced ordinary intent (and its interruption).
static func required_intent(g, enemy: Dictionary) -> String:
 var source_kind=kind(g,enemy)
 if source_kind=="": return ""
 if has_bind(g) and g.state.guard_bind.progress>=BIND_MAXIMUM: return "capture"
 if source_kind=="guard" and enemy.stage==1: return "guard_sequence"
 if not has_bind(g,source_kind):
  return "bind_apply" if enemy.guard.bind_ready or (source_kind!="guard" and enemy.stage==1) else "bind_prepare"
 return ""

static func observe(g) -> void:
 if g.state.phase!="battle": return
 if has_bind(g):
  for source_kind in g.state.guard_bind.sources.keys():
   var source=g.state.guard_bind.sources[source_kind]
   var enemy=g._enemy(source.enemy)
   if not enemy.is_empty() and enemy.gone:
    g.state.guard_bind.sources.erase(source_kind)
    g._emit("event",enemy.name+"离场，它的捕缚效果随之解除。")
  if g.state.guard_bind.sources.is_empty(): clear_bind(g)
 if fixed_posture(g)!="": g.state.posture=fixed_posture(g)
 for enemy in g.state.enemies:
  if enemy.gone or kind(g,enemy)=="": continue
  var expected=required_intent(g,enemy)
  var current=enemy.intent.get("kind","")
  if (expected!="" and current!=expected) or (expected=="" and current in ["bind_prepare","bind_apply","capture"]): enemy.intent=g._plan(enemy)

static func view(g) -> Dictionary:
 if not has_bind(g): return {}
 var descriptions=[];var names=[]
 if has_bind(g,"guard"): descriptions.append("警卫捕缚：只能躺姿→坐姿→站姿，每次切换使捕缚＋10；花能量和快感达到上限时触发警卫效果。")
 if has_bind(g,"drone"): descriptions.append("无人机捕缚：固定为站姿；每累计消耗2能量，施加1件初级2档胶带并使捕缚＋10。当前累计%d/2能量。" % g.state.guard_bind.sources.drone.energy)
 if has_bind(g,"binding_box"): descriptions.append("拘束盒捕缚：固定为坐姿；每个玩家回合开始，施加1件中级2档皮革拘束具，并使捕缚＋10。")
 for source in g.state.guard_bind.sources.values(): names.append(g._enemy(source.enemy).name)
 var detail="被捕缚时无法移动，先解除捕缚。挣扎／滑脱牌可直接削减进度；除眼罩、口球外没有其他拘束具时伤害翻倍，不受环境加成。上身受限至少按1级计算。同种捕缚不叠加；新种类增加其初始值的一半。降至0全部解除，达到100后下一敌方回合执行收押。"
 return {"name":"捕缚","value":g.state.guard_bind.progress,"maximum":BIND_MAXIMUM,"source":"、".join(names),"text":"捕缚进度 %s/100" % g.number(g.state.guard_bind.progress),"detail":detail+"\n"+"\n".join(descriptions)}

static func validate(g) -> String:
 var bind=g.state.guard_bind
 if bind.is_empty(): return ""
 if not g.Snapshot.fields(bind,"progress:n sources:d") or g.state.phase!="battle" or bind.progress<=0 or bind.progress>BIND_MAXIMUM or bind.sources.is_empty(): return "捕缚进度记录不完整。"
 for source_kind in bind.sources:
  var source=bind.sources[source_kind]
  if not g.Snapshot.fields(source,"enemy:s energy:i") or source.energy<0 or source.energy>=2: return "捕缚能量记录不合法。"
  var enemy=g._enemy(source.enemy)
  if enemy.is_empty() or enemy.gone or kind(g,enemy)!=source_kind: return "捕缚缺少存活的对应来源。"
  if source_kind!="drone" and source.energy!=0: return "此捕缚不累计能量。"
 if fixed_posture(g)!="" and g.state.posture!=fixed_posture(g): return "固定捕缚与当前姿态不一致。"
 return ""
