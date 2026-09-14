extends RefCounted

const B=preload("res://data/balance.gd")
const Data=preload("res://data/pressure_sources.gd")
const TIMINGS={"turn_start":"玩家回合开始","turn_end":"玩家回合结束","strain":"挣扎后","slip":"滑脱后","posture":"改变姿态后","travel":"移动一回合后"}

static func calm(g) -> Dictionary:
 var severity=0
 for piece in g.equipment_at("mouth"):
  var tightness=g.tier(piece.durability,piece.maximum)
  if tightness>0: severity=maxi(severity,piece.grade+tightness)
 var multiplier=B.CALM_MOUTH_MULTIPLIERS[severity]
 var remaining=maxi(0,B.CALM_USES_PER_TURN-g.state.calm_uses)
 var reason="本回合深呼吸已使用%d次。" % B.CALM_USES_PER_TURN if remaining==0 else ("嘴部拘束为高级、紧度3档，无法深呼吸。" if multiplier==0 else "")
 return {"reduction":B.CALM_REDUCTION*multiplier,"remaining":remaining,"reason":reason}

static func free_relief(g) -> float:
 return B.FREE_PRESSURE_RELIEF if g.action_targets().is_empty() and not g.CaptureBind.has_bind(g) else 0.0

static func relax(g) -> void:
 var loss=minf(g.state.pressure,free_relief(g))
 if loss<=0: return
 var before=g.state.pressure
 g.state.pressure-=loss
 g._emit("event","身体完全自由，快感降低%s点。" % g.number(loss),{"free_pressure_relief":true,"pressure_before":before,"pressure_after":g.state.pressure,"loss":loss})

static func maximum(g) -> float:
 var result=75.0 if g.Character.active(g) else B.PRESSURE_MAX
 for item in g.state.special_equipment:
  if g.SpecialEquipment.is_chastity(item) and item.durability>0:
   result+=(int(item.grade)+g.tier(item.durability,item.maximum))*5
 return result

static func stage(value: float, limit: float=B.PRESSURE_MAX) -> int:
 return 0 if value<=0 else (1 if value<=limit*0.4 else (2 if value<=limit*0.8 else 3))

static func magic_multiplier(value: float, limit: float=B.PRESSURE_MAX, enabled: bool=B.PRESSURE_MAGIC_SURCHARGE_ENABLED) -> float:
 # Retained for advanced rules; live callers use the disabled default.
 if not enabled: return 1.0
 var x=clampf((value/limit-0.4)/0.6,0.0,1.0)
 return 1.0+B.PRESSURE_MAGIC_SURCHARGE*x*x*(3.0-2.0*x)

static func cast_chance(value: float, limit: float=B.PRESSURE_MAX) -> float:
 var x=clampf((value/limit-B.CAST_SAFE_PRESSURE)/(1.0-B.CAST_SAFE_PRESSURE),0.0,1.0)
 return pow(1.0-x,B.CAST_FALLOFF_POWER)

static func active(g, source: Dictionary) -> bool:
 if source.has("enemy"):
  if g.state.phase!="battle" or source.encounter!=g.state.encounter: return false
  if not g.state.enemies.any(func(e):return e.id==source.enemy and not e.gone): return false
 if source.room!="" and g.state.phase=="travel": return false
 if source.equipment!="":
  var e=g._equipment(source.equipment)
  if e.is_empty() or e.durability<=0: return false
 return source.room=="" or source.room==g.state.room

static func tick(g, timing: String) -> void:
 for source in g.state.pressure_sources.duplicate():
  if source.timing!=timing or not active(g,source): continue
  gain(g,source.amount,source.name)
  if source.has("remaining"):
   source.remaining-=1
   if source.remaining==0:
    g.state.pressure_sources.erase(source)
    g._emit("event",source.name+"已经结束。")
 g.RelicEffects.pressure_tick(g,timing)

static func attach(g, definition: String, equipment: String="", enemy: String="") -> void:
 var spec=Data.TYPES[definition]
 var id=definition+":"+(equipment if equipment!="" else enemy)
 var existing=g.state.pressure_sources.filter(func(s):return s.id==id)
 if not existing.is_empty():
  if spec.has("duration"): existing[0].remaining=maxi(existing[0].remaining,spec.duration)
  return
 var source={"id":id,"definition":definition,"name":spec.name,"timing":spec.timing,"amount":spec.amount,"equipment":equipment,"room":""}
 if enemy!="":
  source.name=g.state.enemies.filter(func(e):return e.id==enemy)[0].name+"的"+spec.name
  source.enemy=enemy;source.encounter=g.state.encounter;source.remaining=spec.duration
 g.state.pressure_sources.append(source)
 g._emit("event",source.name+"开始生效。")

static func describe(g, s: Dictionary) -> String:
 var ending="；解除"+g._equipment(s.equipment).name+"后停止。" if s.equipment!="" else ("；离开本房间后停止。" if s.room!="" else "；持续生效。")
 if s.has("remaining"): ending="；剩余%d次，施加者被击倒、离场或战斗结束后停止。" % s.remaining
 var slots=[]
 if s.equipment!="":
  var equipment=g._equipment(s.equipment)
  if not equipment.is_empty(): slots=g.SpecialEquipment.occupied_slots(equipment)
 return TIMINGS[s.timing]+"：快感＋"+g.number(s.amount*source_multiplier(g,slots))+ending

static func escape_timing(payload: Dictionary) -> String:
 if payload.kind=="hook": return "slip"
 if payload.kind in ["card","chain"] and not payload.free:
  var mode=preload("res://data/card_rules.gd").SPECS[payload.type].mode
  if mode=="strain": return "strain"
  if mode in ["slip","magic_slip","lower"]: return "slip"
 return ""

static func action_risk(g, payload: Dictionary) -> String:
 if g.state.pressure_sources.is_empty(): return ""
 var timings=[escape_timing(payload)]
 if payload.kind=="posture":
  timings.append("posture")
 elif payload.kind=="end": timings.append("turn_end")
 var amount=0.0
 for s in g.state.pressure_sources:
  if s.timing not in timings or not active(g,s): continue
  var slots=[]
  if s.equipment!="":
   var equipment=g._equipment(s.equipment)
   if not equipment.is_empty(): slots=g.SpecialEquipment.occupied_slots(equipment)
  amount+=s.amount*source_multiplier(g,slots)
 return "本次行动后，仍存在的刺激最多增加%s快感。" % g.number(amount) if amount>0 else ""

static func gain_multiplier(g, fixed: bool=false) -> float:
 var multiplier=1.0 if fixed else g.Cards.hand_multiplier(g,"pleasure_multiplier")
 multiplier*=g.Character.Expansion.pressure_multiplier(g)
 for id in g.state.relics:
  multiplier*=1.0-g.Relics.TYPES[id].modifiers.get("pressure_reduction_percent",0.0)/100.0
 return multiplier

static func source_multiplier(g, source_slots: Array=[], fixed: bool=false) -> float:
 var multiplier=gain_multiplier(g,fixed)
 for lock in g.state.special_equipment:
  if not g.SpecialEquipment.is_chastity(lock) or lock.durability<=0: continue
  if source_slots.any(func(slot):return slot in g.SpecialEquipment.occupied_slots(lock)): continue
  multiplier*=1.0+0.05*(int(lock.grade)+g.tier(lock.durability,lock.maximum))
 return multiplier

static func gain(g, amount: float, source: String, fixed: bool=false, source_slots: Array=[]) -> void:
 if amount<=0: return
 var base=amount
 var multiplier=source_multiplier(g,source_slots,fixed)
 amount*=multiplier
 var old=g.state.pressure
 var total=g.RelicEffects.cap_pressure(g,old+amount)
 var actual=total-old
 var limit=maximum(g)
 var count=int(floor((total+0.0000001)/limit))
 g.state.pressure=maxf(0.0,total-count*limit)
 g._emit("event",source+"使快感增加%s。" % g.number(actual),{"pressure_before":old,"base_gain":base,"gain_multiplier":multiplier,"gain":actual,"source":source,"fixed_gain":fixed})
 _apply_overloads(g,count)

static func balance_mana(g) -> void:
 var before={"mana":g.state.mana,"pressure":g.state.pressure}
 var average=(before.mana+before.pressure)/2.0
 # Redistribution sets current values; it is neither a gain multiplier nor a spell payment.
 g.state.mana=minf(g.state.mana_max,average)
 var total=g.RelicEffects.cap_pressure(g,average)
 var limit=maximum(g)
 var count=int(floor((total+0.0000001)/limit))
 g.state.pressure=maxf(0.0,total-count*limit)
 g._emit("event","均分后：快感%s，魔力%s。" % [g.number(total),g.number(g.state.mana)],{"resource_balance":{"before":before,"average":average,"mana":g.state.mana,"pressure":total}})
 if g.state.mana<average:
  g._emit("event","魔力已达上限，保留%s魔力。" % g.number(g.state.mana))
 _apply_overloads(g,count)

static func scripted_climax(g, source: String) -> Dictionary:
 # Scripted scenes share the ordinary climax body/equipment rules, but they are
 # resolved like room events even when the surrounding phase is prison/rest.
 # This keeps the semen-bound mana loss immediate and avoids creating a combat
 # interruption or the two-turn slip-ejaculation penalty.
 var mana_before=float(g.state.mana)
 var total_before=int(g.state.overload_total)
 var log_before=g.state.logs.size()
 _apply_overloads(g,1,true)
 if g.state.logs.size()>log_before:
  g.state.logs[-1].data.scripted_climax={"source":source,"count":1}
 return {"count":int(g.state.overload_total)-total_before,"mana_before":mana_before,"mana_lost":mana_before-float(g.state.mana),"mana_after":float(g.state.mana)}

static func _apply_overloads(g, count: int, scripted: bool=false) -> void:
 if count==0: return
 g.Character.clear(g,false)
 g.Character.lose_focus(g,count,"高潮")
 var slip_ejaculation=g.state.special_equipment.any(func(item):return g.SpecialEquipment.is_chastity(item) and item.durability>0) and g.state.special_equipment.any(func(item):return item.durability>0 and (g.SpecialEquipment.catheter(item) or (not g.SpecialEquipment.is_reinforcement(item) and "special_2_d" in g.SpecialEquipment.occupied_slots(item))))
 g.CaptureBind.overload(g,count)
 var climax_equipment_released=g._climax_special_slip(count)
 var mana_before=g.state.mana
 var deferred_mana=not scripted and g.state.phase!="event" and (g.state.slip_ejaculation_turns>0 or (slip_ejaculation and g.state.phase in ["battle","prepare","rest","prison"]))
 var lost=0.0 if deferred_mana else minf(mana_before,count*B.OVERLOAD_MANA)
 g.state.mana-=lost
 g.state.overload_total+=count
 if not scripted and g.state.phase in ["battle","prepare","rest","prison"]:
  if slip_ejaculation:
   g.state.slip_ejaculation_turns=maxi(g.state.slip_ejaculation_turns,2)
   g.state.slip_ejaculation_force_last=true
  else: g.state.overload_energy+=count*B.OVERLOAD_ENERGY
  g.state.overload_count+=count
  g.state.overloaded=true
  g.state.energy=0
  if not g.state.card_chain.is_empty():
   g.Cards.cancel_chain(g)
   g._emit("event","高潮打断了剩余卡牌效果。")
  g._discard_end()
 var locks=g.state.special_equipment.filter(func(item):return g.SpecialEquipment.is_chastity(item) and item.durability>0)
 if not locks.is_empty():
  var lock=locks[0]
  var sum=int(lock.grade)+g.tier(lock.durability,lock.maximum)
  var masochist=bool(g.state.get("cursed_plate_masochist_mode",false))
  var used_factor=g.state.chastity_climax_factor+count-1
  if not masochist: used_factor=mini(used_factor,g.SpecialEquipment.CHASTITY_CLIMAX_FACTOR_LIMIT)
  g.state.pressure=minf(maximum(g)-0.000001,float(sum*used_factor))
  g.state.chastity_climax_factor+=count
  if not masochist: g.state.chastity_climax_factor=mini(g.state.chastity_climax_factor,g.SpecialEquipment.CHASTITY_CLIMAX_FACTOR_LIMIT)
 if climax_equipment_released: g._cleanup()
 g._emit("event",("滑精" if slip_ejaculation else "高潮")+"%d次，损失%s魔力，快感回落至%s。" % [count,g.number(lost),g.number(g.state.pressure)],{"overloads":count,"mana_before":mana_before,"mana_lost":lost,"mana_after":g.state.mana,"remainder":g.state.pressure,"energy_penalty":g.state.overload_energy,"slip_ejaculation":slip_ejaculation,"scripted":scripted})

static func settle_maximum(g, source: String) -> void:
 g.state.pressure=g.RelicEffects.cap_pressure(g,g.state.pressure)
 var limit=maximum(g)
 if g.state.pressure<limit: return
 var total=g.state.pressure
 var count=int(floor((total+0.0000001)/limit))
 g.state.pressure=maxf(0.0,total-count*limit)
 g._emit("event",source+"使快感超过新的上限。",{"pressure_limit":limit,"overloads":count})
 _apply_overloads(g,count)

static func clear_penalties(g) -> void:
 g.state.calm_uses=0
 g.state.overloaded=false
 g.state.overload_count=0
 g.state.overload_energy=0
 g.state.slip_ejaculation_turns=0
 g.state.slip_ejaculation_force_last=false

static func cleanup(g) -> void:
 for s in g.state.pressure_sources.duplicate():
  if (s.equipment!="" and g._equipment(s.equipment).is_empty()) or (s.has("enemy") and not active(g,s)) or (s.room!="" and (s.room!=g.state.room or g.state.phase=="travel")):
   g.state.pressure_sources.erase(s)
   g._emit("event",s.name+"结束。")

static func validate(g) -> String:
 if not g.Snapshot.fields(g.state,"calm_uses:i") or g.state.calm_uses<0 or g.state.calm_uses>B.CALM_USES_PER_TURN: return "本回合深呼吸次数不正确。"
 var limit=maximum(g)
 if not is_finite(g.state.pressure) or g.state.pressure<0 or g.state.pressure>=limit: return "快感必须处于零至高潮阈值以下。"
 if g.state.overload_energy<0 or g.state.overload_count<0 or g.state.overload_total<0: return "高潮次数或下回合乏力记录不合法。"
 if g.state.overloaded and (not g.RelicEffects.keeps_combat_state(g) or g.state.energy!=0): return "高潮期间不能保留可用行动能量。"
 var ids=[]
 for s in g.state.pressure_sources:
  if s.has("remaining") or s.has("enemy") or s.has("encounter"):
   if not s.get("remaining") is int or s.remaining<=0 or not s.get("enemy") is String or not s.get("encounter") is int or not active(g,s): return "限时刺激来源的持续次数或施加者不合法。"
  if s.has("definition"):
   if not Data.TYPES.has(s.definition): return "刺激来源定义不存在。"
   var spec=Data.TYPES[s.definition]
   if s.timing!=spec.timing or s.amount!=spec.amount or (spec.has("duration") and (not s.has("remaining") or s.remaining>spec.duration)): return "刺激来源与公开定义不一致。"
  if s.id in ids or s.name=="" or not TIMINGS.has(s.timing) or not is_finite(s.amount) or s.amount<=0: return "刺激来源、时机或数值不合法。"
  ids.append(s.id)
  if s.equipment!="" and g._equipment(s.equipment).is_empty(): return "持续刺激缺少所依附的装备。"
  if s.room!="" and g.room_data(s.room).is_empty(): return "刺激来源所在房间不存在。"
 return ""

static func view(g, special_regions: Array) -> Dictionary:
 var sources=[]
 var guard=g.RelicEffects.pressure_guard(g)
 if guard!="": sources.append({"name":g.Relics.TYPES[guard].name,"text":"本回合快感值最多为%s。" % g.number(maximum(g)-1.0)})
 var multiplier=gain_multiplier(g)
 var limit=maximum(g)
 for s in g.state.pressure_sources:
  if not active(g,s): continue
  sources.append({"name":s.name,"text":describe(g,s)})
 var special_ids=[]
 for region in special_regions:
  for item in region.items:
   for equipment in item.equipment:
    if equipment.id in special_ids: continue
    special_ids.append(equipment.id)
    sources.append({"name":equipment.name+" · "+g.SpecialEquipment.location_name(g._equipment(equipment.id)),"text":equipment.text})
 return {"value":g.state.pressure,"maximum":limit,"stage":stage(g.state.pressure,limit),"magic_multiplier":magic_multiplier(g.state.pressure,limit),"gain_multiplier":multiplier,"overloaded":g.state.overloaded and g.state.phase in g.RelicEffects.COMBAT_PHASES,"count":g.state.overload_count,"energy_penalty":g.state.overload_energy,"sources":sources,
  "text":"快感 %s / %s · %s" % [g.number(g.state.pressure),g.number(limit),["平静","微热","兴奋","临界"][stage(g.state.pressure,limit)]],
  "detail":"快感增长倍率：×%s。快感达到%s立即高潮，通常损失%s魔力。滑精时免除这笔损失，后续两回合开始时各损失%s魔力。\n未佩戴任何拘束具、链接或特殊装备且未被捕缚时，每回合结束快感降低%s点，最低为0。" % [g.number(multiplier),g.number(limit),g.number(B.OVERLOAD_MANA),g.number(B.SLIP_EJACULATION_MANA),g.number(B.FREE_PRESSURE_RELIEF)]}
