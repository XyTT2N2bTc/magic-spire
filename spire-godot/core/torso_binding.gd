extends RefCounted

# Attached lifecycle; this helper is only called by the existing game pipeline.
const SLOTS=["upper_arm","forearm","wrist"]
const NAMES={"linked":"躯干固缚·连接式","integrated":"躯干固缚·一体式"}
const MAXIMUM={1:10.0,2:16.0,3:24.0}

static func eligible(e: Dictionary) -> bool:
 return e.get("slot","") in SLOTS and not e.has("root_id") and not e.has("parent_id") and e.get("template","") not in ["link_rope","special"]

static func present(e: Dictionary) -> bool:
 var b=e.get("binding",{})
 return not b.is_empty() and (b.kind=="integrated" or b.durability>0.000001)

static func refresh(g, e: Dictionary) -> void:
 if not eligible(e) or g.tier(e.durability,e.maximum)!=3: return
 var old=e.get("binding",{})
 var kind=old.kind if not old.is_empty() else (["linked","integrated"][g._random_index("binding",2)])
 if kind=="integrated": e.binding={"kind":kind}
 else:
  e.binding={"kind":kind,"id":"binding_"+e.id,"parent_id":e.id,"template":"torso_connection","name":NAMES[kind],"slot":e.slot,"points":g.Equipment.physical_points(e).duplicate(),"layer":e.layer,"grade":e.grade,"variant":e.variant,"material":e.material,"locked":false,"maximum":MAXIMUM[e.grade],"durability":MAXIMUM[e.grade],"source":e.source}
 g._emit("event",e.name+"形成了"+NAMES[kind]+"，将手臂固定在身后。",{"torso_binding":{"target":e.id,"kind":kind,"refreshed":not old.is_empty()}})

static func active(g, e: Dictionary) -> bool:
 return present(e) and g._outer(e)

static func connections(g) -> Array:
 var result=[]
 for e in g.state.equipment:
  if present(e) and e.binding.kind=="linked": result.append(e.binding)
 return result

static func filter_points(g, original: Array) -> Array:
 var block_thigh=false
 var block_special=false
 for e in g.state.equipment:
  if not active(g,e): continue
  block_thigh=true
  if e.slot in ["forearm","wrist"]: block_special=true
 var blocked=g.Equipment.points("thigh") if block_thigh else []
 if block_special: blocked+=g.SpecialEquipment.REGIONS[2].slots
 return original.filter(func(point):return point not in blocked)

static func cancel_for_assembly(g, pieces: Array) -> void:
 for e in g.state.equipment:
  if not e.has("binding") or not pieces.any(func(p):return g.Equipment.overlaps(e,p)): continue
  if present(e): g._emit("event","为穿戴复合拘束具，先解开了"+e.name+"上的躯干固缚。",{"torso_binding":{"target":e.id,"cancelled":true}})
  e.erase("binding")

static func can_tighten(e: Dictionary) -> bool:
 return e.durability<e.maximum or (eligible(e) and e.has("binding") and not present(e))

static func validate(g, e: Dictionary) -> String:
 if not e.has("binding"): return ""
 if not MAXIMUM.has(e.get("grade",0)): return "躯干固缚的装备等级不正确。"
 var b=e.binding
 if not eligible(e) or not b is Dictionary or b.get("kind","") not in NAMES: return "躯干固缚所属部位或形式不正确。"
 if b.kind=="integrated": return "" if b.size()==1 else "一体式固缚不能拥有独立耐久。"
 var expected={"id":"binding_"+e.id,"parent_id":e.id,"template":"torso_connection","name":NAMES.linked,"slot":e.slot,"points":g.Equipment.physical_points(e),"layer":e.layer,"grade":e.grade,"variant":e.variant,"material":e.material,"locked":false,"maximum":MAXIMUM[e.grade],"source":e.source}
 if b.size()!=expected.size()+2: return "连接式固缚记录不完整。"
 for key in expected:
  if b.get(key)!=expected[key]: return "连接式固缚与所属装备不一致。"
 if typeof(b.get("durability")) not in [TYPE_INT,TYPE_FLOAT]: return "连接式固缚耐久不正确。"
 if not is_finite(b.durability) or b.durability<0 or b.durability>b.maximum: return "连接式固缚耐久不正确。"
 return ""

static func state_issue(g) -> String:
 for e in g.state.equipment:
  var issue=validate(g,e)
  if issue!="": return issue
 return ""

static func text(g, e: Dictionary) -> String:
 if not present(e): return ""
 var label=NAMES[e.binding.kind]
 if not active(g,e): return label+"：被外层覆盖，暂不生效。"
 return label+"：手不能触及大腿"+("和双穴区域" if e.slot in ["forearm","wrist"] else "")+"；降档后仍保留。"
