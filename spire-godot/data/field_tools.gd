extends RefCounted

# Prototype amounts; the posture/contact table follows the new game's design.
const Environments=preload("res://data/environments.gd")
const Contact=preload("res://core/contact.gd")
const TYPES={
 "lubricant_potion":{"name":"润滑油","category":"potion","operation":"buff","effect":"slip_boost","target_scope":"body_group","unrestricted_use":true,"mouth_reduction":false,"amount":2,"uses":3,"damage":0.0,"materials":[]},
 "mana_potion":{"name":"魔力药剂","category":"potion","operation":"buff","effect":"mana","amount":20,"uses":1,"damage":0.0,"materials":[]},
 "energy_potion":{"name":"活力药剂","category":"potion","operation":"buff","effect":"energy","amount":2,"uses":1,"damage":0.0,"materials":[]},
 "charge_potion":{"name":"蓄势药剂","category":"potion","operation":"buff","effect":"charge","amount":2,"uses":1,"damage":0.0,"materials":[]},
 "draw_scroll":{"name":"应变卷轴","category":"scroll","operation":"buff","effect":"draw","amount":3,"uses":1,"damage":0.0,"materials":[]},
 "mana_scroll":{"name":"节魔卷轴","category":"scroll","operation":"buff","effect":"reserve_mana","amount":2,"uses":1,"damage":0.0,"materials":[]},
 "casting_scroll":{"name":"定咒卷轴","category":"scroll","operation":"buff","effect":"sure_cast","amount":1,"uses":1,"damage":0.0,"materials":[]},
 "return_seal":{"name":"传送符","category":"scroll","uses":1,"damage":0.0,"materials":[],"operation":"escape"},
 "picks":{"name":"便携开锁针","uses":2,"damage":0.0,"materials":[],"operation":"unlock"},
 "shard":{"environment_class":"sharp","trigger_damage_types":["strain","slip"],"mouth_install":true,"name":"尖锐的小石片","uses":3,"damage":5.0,"materials":["leather","rope","tape"]},
 "saw":{"environment_class":"sharp","trigger_damage_types":["strain","slip"],"mouth_install":true,"name":"锈掉的锯条","uses":2,"damage":7.0,"materials":["leather","rope","tape","plastic"]}
}

const DROP_POOL=["mana_potion","energy_potion","charge_potion","draw_scroll","mana_scroll","casting_scroll","shard","saw","lubricant_potion"]
const DROP_INITIAL=40
const DROP_STEP=10

static func operation(type: String) -> String:
 return TYPES[type].get("operation","cut")

# Shared read-only item facts, available even outside an action phase.
static func description(g, type: String) -> String:
 if operation(type)=="buff": return g.Consumables.description(g,type)
 return effect_description(type,TYPES[type].damage*g.Cards.damage_multiplier(g,"equipment"),assisted(g))

static func effect_description(type: String, damage: float, assisted: bool=false) -> String:
 var spec=TYPES[type]
 var lines: Array[String]=[]
 match operation(type):
  "cut":
   lines.append("切割：每次造成%s点真实伤害%s。" % [(str(int(damage)) if is_equal_approx(damage,roundf(damage)) else "%.2f" % damage),"（基础%s）" % str(spec.damage) if damage!=spec.damage else ""])
   lines.append("无视紧度、锁和堆叠减伤。适用材料："+"、".join(spec.materials.map(func(material):return preload("res://data/equipment.gd").MATERIAL_NAMES[material]))+"。")
   lines.append("目标须外露且可触及。" if not assisted else "触手朋友：固定工具对全身有效，无身体、姿态或触及限制。")
  "unlock":
   lines.append("开锁：解除1把装备锁或牢门锁，不削减装备耐久。")
   lines.append("需要手腕、手指自由并能触及目标；牢门须站姿或坐姿。" if not assisted else "触手朋友：无需满足身体、姿态和触及条件。")
  "escape":
   lines.append("逃离：直接离开当前牢房，进入监狱外部路线。")
   lines.append("仅安全等级1—4的牢房行动回合可用，使用后背包须不超量。")
   if not assisted: lines.append("手指或脚趾任一部位自由即可使用。")
 lines.append("每次消耗1次使用次数，不耗能量或魔力。")
 if not spec.get("trigger_damage_types",[]).is_empty(): lines.append("安装1能量，取回免费，均不扣次数。")
 return "\n".join(lines)

static func assisted(g) -> bool:
 return g.Relics.value(g.state.relics,"unrestricted_items")>0

static func is_fixed(g, item: Dictionary) -> bool:
 return item.mount!="carry" or (assisted(g) and not TYPES[item.type].get("trigger_damage_types",[]).is_empty())

static func mount_name(g, item: Dictionary) -> String:
 return "触手固定" if item.mount=="carry" and is_fixed(g,item) else MOUNTS[item.mount]

static func target_contact(g, target: Dictionary, operation_id: String) -> Dictionary:
 if assisted(g):
  return Contact.evaluate(g,target,{"points":reach(g,{"mount":"carry"})})
 return {"reason":Contact.reason(g,target,operation_id),"slots":Contact.usable_slots(g,target,operation_id)}

static func escape_reason(g) -> String:
 if g.state.phase!="prison" or g.state.security>=5: return "传送符只能在一至四级牢房的可行动回合使用，巡视和战斗中不能使用。"
 var scroll_reason=g.Consumables.scroll_reason(g)
 if scroll_reason!="": return scroll_reason
 if g.carried_items()-1>g.item_capacity(): return "用掉传送符后，剩余道具仍超出容量；请先使用或放弃多出的道具。"
 return ""

static func unlock_reason(g, target: Dictionary={}) -> String:
 if g.cursed_plate(target): return g.SpecialEquipment.CURSED_PLATE_REASON
 if not assisted(g) and (g.occupied("fingers") or g.occupied("wrist")): return "开锁针需要手腕和手指自由，才能稳定握持并拨动锁芯。"
 if target.is_empty():
  return "拨动牢门锁芯需要站姿或坐姿。" if g.state.posture=="lie" and not assisted(g) else ""
 if not target.locked: return "这件装备没有锁。"
 return target_contact(g,target,"unlock").reason
# Fixed world heights; posture changes reach, never the installed height.
const MOUNTS={"carry":"随身","foot_wall":"墙缝一","hand_wall":"墙缝二","high_wall":"墙缝三"}
const HEIGHTS={"foot_wall":{"name":"低位","height":0.2,"range":"离地0—0.4米"},"hand_wall":{"name":"中位","height":0.8,"range":"离地大于0.4—1米"},"high_wall":{"name":"高位","height":1.4,"range":"离地大于1—1.6米"}}
const HOOK_MOUNT="hand_wall"
const OPERATOR_NAMES={"hand":"手指","foot":"脚趾","mouth":"嘴部","helper":"触手朋友"}
const OPERATOR_HEIGHTS={
 "stand":{"hand":["hand_wall","high_wall"],"mouth":["high_wall"],"foot":["foot_wall"]},
 "sit":{"hand":["foot_wall","hand_wall"],"mouth":["hand_wall"],"foot":["foot_wall"]},
 "lie":{"hand":["foot_wall"],"mouth":["foot_wall"],"foot":["foot_wall","hand_wall","high_wall"]}}
const POINT_HEIGHTS={
 "stand":{"high_wall":["shoulder","upper_arm_top","above_elbow"],"hand_wall":["above_elbow","below_elbow","mid_forearm","wrist","palm_left","palm_right","fingers_left","fingers_right","thigh_root","mid_thigh"],"foot_wall":["above_knee","below_knee","mid_calf","ankle","foot","toes"]},
 "sit":{"high_wall":[],"hand_wall":["shoulder","upper_arm_top","above_elbow","below_elbow","mid_forearm","wrist","palm_left","palm_right","fingers_left","fingers_right"],"foot_wall":["below_elbow","mid_forearm","wrist","palm_left","palm_right","fingers_left","fingers_right","thigh_root","mid_thigh","above_knee","below_knee","mid_calf","ankle","foot","toes"]},
 "lie":{"high_wall":["ankle","foot","toes"],"hand_wall":["below_knee","mid_calf","ankle","foot","toes"],"foot_wall":["shoulder","upper_arm_top","above_elbow","below_elbow","mid_forearm","wrist","palm_left","palm_right","fingers_left","fingers_right","thigh_root","mid_thigh","above_knee","below_knee","mid_calf","ankle","foot","toes"]}}

# Presentation groups complete regions only; partial reach retains the precise point names.
static func part_names(g, points: Array) -> String:
 var names=[]
 for slot in ["eyes","mouth","neck","shoulder"]+g.B.ARM_SLOTS+g.B.LEG_SLOTS:
  var all_points=Contact.E.points(slot)
  var matching=all_points.filter(func(point):return point in points)
  if matching.is_empty(): continue
  if matching.size()==all_points.size(): names.append(g.B.SLOT_NAMES[slot])
  else:
   for point in matching: names.append(Contact.E.POINT_NAMES.get(point,g.B.SLOT_NAMES[slot]))
 for region in g.SpecialEquipment.REGIONS:
  if region.slots.any(func(point):return point in points): names.append(region.name)
 return "、".join(names)

static func contact_text(g, mount: String, cutting: bool=true) -> String:
 if assisted(g) and cutting: return "可接触部位：全身。"
 var parts=part_names(g,reach(g,{"mount":mount}) if cutting else height_points(g,mount))
 return "当前姿势没有部位能接触这里。" if parts=="" else "可接触部位："+parts+"。"

static func target_parts(g, target: Dictionary) -> String:
 if g.SpecialEquipment.is_special(target): return g.SpecialEquipment.location_name(target)
 var points=[]
 for contact in Contact.target_contacts(g,target): points.append_array([contact.point] if contact.has("point") else Contact.contacts(contact.target,contact.slot))
 return part_names(g,points)

static func contact_reason(g, target: Dictionary, item: Dictionary) -> String:
 if item.mount=="carry" or assisted(g): return target_contact(g,target,"cut").reason
 var result=Contact.evaluate(g,target,{"points":reach(g,item)})
 if result.code=="out_of_reach": return "当前姿势下，"+target_parts(g,target)+"碰不到这里的工具。"
 return result.reason

static func reach(g, item: Dictionary) -> Array:
 if assisted(g):
  var points=Contact.E.ANATOMY.duplicate();points.append_array(g.SpecialEquipment.slots());return points
 return height_points(g,item.mount).filter(func(point):return point not in ["eyes","mouth","neck"])

static func height_points(g, mount_id: String) -> Array:
 var result=POINT_HEIGHTS[g.state.posture].get(mount_id,[]).duplicate()
 if mount_id=={"stand":"high_wall","sit":"hand_wall","lie":"foot_wall"}[g.state.posture]: result.append_array(["eyes","mouth","neck"])
 var pose=g.state.posture
 for index in range(3):
  var mount=("high_wall" if index==0 else "hand_wall") if pose=="stand" else ("hand_wall" if pose=="sit" and index==0 else "foot_wall")
  if mount_id==mount: result.append_array(g.SpecialEquipment.REGIONS[index].slots)
 return result

static func operator_profile(g, mount: String, type: String) -> Dictionary:
 var result=[];var issues=[]
 if not HEIGHTS.has(mount): return {"operators":[],"reason":"这里没有对应的工具安装位置。"}
 if assisted(g): return {"operators":["helper"],"reason":""}
 var pose=g.state.posture
 var ranges=OPERATOR_HEIGHTS[pose]
 # Bound arms can still pinch nearby; they cannot raise the hands into the upper band.
 if mount in ranges.hand:
  if g.occupied("fingers"): issues.append("手指受限，夹不住工具")
  elif g.level("arms")!=0 and mount!=("hand_wall" if pose=="stand" else "foot_wall"): issues.append("双臂受限，手够不到这里")
  else: result.append("hand")
 if mount in ranges.foot:
  if g.occupied("toes"): issues.append("脚趾受限，夹不住工具")
  elif g.level("legs")>2: issues.append("双腿受限超过二级，不能用脚趾送取工具")
  else: result.append("foot")
 if mount in ranges.mouth and TYPES.get(type,{}).get("mouth_install",false):
  if g.occupied("mouth"): issues.append("嘴部被占用")
  else: result.append("mouth")
 var reason=""
 if result.is_empty(): reason="当前姿势够不到"+MOUNTS[mount]+"。" if issues.is_empty() else "；".join(issues)+"。"
 return {"operators":result,"reason":reason}

static func install_operators(g, mount: String, type: String) -> Array:
 return operator_profile(g,mount,type).operators

static func operator_reason(g, mount: String, type: String) -> String:
 return operator_profile(g,mount,type).reason

static func same_installation_point(g, item: Dictionary, mount: String) -> bool:
 if item.mount!=mount: return false
 if g.state.prison.get("active",false): return item.get("prison_position",[])==g.Prison.Space.attachment_position(g)
 return true

static func install_reason(g, mount: String, type: String) -> String:
 if not HEIGHTS.has(mount): return "这里没有对应的工具安装位置。"
 if g.state.wall=="none": return "当前房间没有可安装工具的墙缝。"
 if not g.wall_contact(): return "需要先靠到墙边，才能安装工具。"
 var issue=operator_reason(g,mount,type)
 if issue!="": return issue
 if g.state.items.any(func(i):return same_installation_point(g,i,mount)): return "这条墙缝已经装有工具。"
 return ""

static func retrieve_reason(g, item: Dictionary) -> String:
 if assisted(g): return ""
 var issue=g.Prison.Space.mounted_reason(g,item)
 if issue!="": return issue
 if not g.wall_contact(): return "需要先靠到墙边，才能取回工具。"
 return operator_reason(g,item.mount,item.type)

static func installation_points(g) -> Array:
 var points=[]
 if not g.wall_contact(): return points
 for mount in HEIGHTS:
  var occupants=g.state.items.filter(func(i):return same_installation_point(g,i,mount))
  points.append({"mount":mount,"short_label":MOUNTS[mount],"occupant":"" if occupants.is_empty() else TYPES[occupants[0].type].name})
 return points
