extends RefCounted

const B=preload("res://data/balance.gd")
const Space=preload("res://core/prison_space.gd")
const ACTIVE_DISCOVERIES=["shard","saw","vent"]
const HIGH_SECURITY_ASSEMBLIES=[["glove","long","cross"],["leg","toes","straight"]]

# Intake and inspection share this source declaration; Application owns selection,
# batch counting and legal replacement. Special equipment remains a separate source.
static func equipment_spec(g, count: int, replace: bool=false) -> Dictionary:
 var rule=B.PRISON_SECURITY[g.state.security]
 return {"pool":"ordinary","templates":g.Equipment.TEMPLATES.keys().filter(func(id):return not g.Equipment.TEMPLATES[id].slots.is_empty()),"composites":g.EquipmentOffers.assembly_specs() if rule.composites else [],"grade":rule.grade,"tier":rule.tier,"count":count,"replace":replace}

static func equipment_label(g) -> String:
 var rule=B.PRISON_SECURITY[g.state.security]
 return "%s%s档%s拘束具" % [g.Equipment.GRADES[rule.grade],["","一","二","三"][rule.tier],"普通或复合" if rule.composites else "普通"]

static func toy_spec(g, count: int, replace: bool=false) -> Dictionary:
 var rule=B.PRISON_SECURITY[g.state.security]
 return {"pool":"special","templates":g.SpecialEquipment.prison_pool(rule.grade,g.state.security>=3,g.state.get("chastity_locks_enabled",false)),"grade":rule.grade,"tier":rule.tier,"count":count,"replace":replace}

static func toy_label(g) -> String:
 var rule=B.PRISON_SECURITY[g.state.security]
 return "%s性玩具%s" % [g.Equipment.GRADES[rule.grade],"（含飞机杯）" if g.state.security>=3 else ""]

static func refill_batteries(g) -> Array:
 var charged=[]
 for item in g.state.special_equipment:
  var maximum=int(g.SpecialEquipment.TYPES[item.type].duration)
  if maximum<=0: continue
  item.remaining=maximum
  charged.append(item.id)
 return charged

static func initial(g) -> Dictionary:
 var pool=ACTIVE_DISCOVERIES.duplicate()
 for i in range(pool.size()-1,0,-1):
  var j=g._random_index("prison",i+1)
  var swap=pool[i]; pool[i]=pool[j]; pool[j]=swap
 return {"active":true,"left":B.PRISON_INTERVALS[mini(B.PRISON_INTERVALS.size()-1,g.state.security-1)],"turn":0,"stage":"","missing":[],"baseline":g.state.capture.baseline.duplicate(),"special_missing":[],"special_baseline":g.state.capture.special_baseline.duplicate(),"discovery_pool":ACTIVE_DISCOVERIES.duplicate(),"discoveries":pool,"found":[],"vent_hits":0,"vent_tick":-1,"door_open":false,"key":false,"resisting":false,"checks":0,"report":""}

static func discoverable(p: Dictionary) -> Array:
 return p.discoveries.duplicate()

# Scenario initialization only; all subsequent actions use the ordinary prison pipeline.
static func start_practice(g) -> void:
 g.state.security=1;g.state.room="prison";g.state.wall="rough";g.state.wall_distance=0
 g.state.posture="lie"
 g.state.rooms.append({"id":"prison","name":"牢房","kind":"prison","wall":"rough","next":[],"floor":-1,"lane":0.5})
 var baseline=g.equipment_targets().map(func(e):return e.id)
 g.state.capture={"by":"牢房练习","security":1,"retained":baseline.duplicate(),"added":[],"links":[],"retained_special":[],"special_added":[],"special_baseline":[],"confiscated":0,"baseline":baseline}
 enter(g)
 g.RelicEffects._mana_hook(g,"prison_entry_mana","进入监狱")
 g._emit("event","你躺在墙边，手腕与大腿各有一件装备。先检查身上的装备，也可以开始探索牢房。")

static func high_security(g) -> String:
 # Same existing equipment, highest grade/tightness; no capacity or closure exception.
 for setup in HIGH_SECURITY_ASSEMBLIES:
  g._install_assembly(setup[0],setup[1],"prison_high_security",3,3,{},setup[2])
 for slot in g.B.SLOTS:
  var template=g.Equipment.default_template(slot)
  for i in range(g.Equipment.capacity(slot)*g.Equipment.points(slot).size()):
   if g._installation_reason(template,slot,3)!="": break
   if g._install_template(template,slot,g.Equipment.maximum(3),g.Equipment.maximum(3),false,"prison_high_security",3).is_empty(): return "高安全监室的追加装备未能完整安装。"
 for e in g.equipment_targets():
  if e.has("shoulders"):
   e.shoulders.grade=3;e.shoulders.variant=0
  e.grade=3;e.variant=0;e.maximum=g.Equipment.maximum(3);e.durability=e.maximum
  e.locked=g.Equipment.allows(e,"lock")
  g._refresh_equipment(e)
 # Three-tier upgrades may create shoulder pieces after the original target list.
 # Their factory supplies the upgraded grade/durability; finalize their locks too.
 for e in g.Shoulders.pieces(g): e.locked=g.Equipment.allows(e,"lock")
 if not g.B.SLOTS.all(func(slot):return not g.equipment_at(slot).is_empty()): return "高安全监室仍有未被覆盖的部位。"
 g.state.capture.terminal_equipment=g.equipment_targets().map(func(e):return e.id)
 return ""

static func enter(g) -> String:
 if g.state.security>=5:
  var issue=high_security(g)
  if issue!="": return issue
  g.state.phase="prison_end"
  g.state.enemies=[]
  g.room_data("prison").name="高安全监室"
  g._emit("event","警戒度达到5，移入高安全监室。原装备结构与链接保留，全部提升至高级、三档；依照部位容量和结构补齐已有类型，可上锁的全部上锁。本次逃脱结束，可以检查最终装备或重新开始。")
  return ""
 g.RelicEffects.begin_combat(g)
 g.state.prison=initial(g)
 g.state.prison.space=Space.initial(g)
 g.state.posture="lie";g.state.wall_distance=0
 # A new imprisonment restores the permanent deck; inspection itself only restores exhaust.
 g._reset_piles()
 g.state.enemies=[]
 g.room_data("prison").name="牢房"
 begin_turn(g)
 return ""

static func begin_turn(g) -> void:
 g.state.phase="prison"
 g.state.prison.turn+=1
 g.state.heavy_used=false
 g._begin_player_turn()
 g._emit("event","牢房第%d回合，距离巡视还有%d回合。可挣脱、探索或处理出口。" % [g.state.prison.turn,g.state.prison.left])

static func end_turn(g) -> void:
 if g.state.prison.key:
  begin_turn(g)
  return
 g.state.prison.left-=1
 if g.state.prison.left>0:
  begin_turn(g)
  return
 g.state.phase="inspection"; g.state.prison.stage="arrival"
 # Keep the next-turn penalty while the non-turn inspection is on screen.
 g.state.overloaded=false; g.state.overload_count=0; g.state.energy=0
 g._emit("event","狱警来到门前。可以接受检查，或立即反抗。")

static func add(out: Array, g, action: String, label: String, detail: String, cost: int=0, reason: String="", extra: Dictionary={}) -> void:
 var payload={"kind":"prison","action":action}
 payload.merge(extra)
 g._candidate(out,payload,label,detail,cost,0,reason,"","prison")

static func candidates(g, out: Array) -> void:
 if g.state.phase=="captured":
  add(out,g,"enter","进入牢房" if g.state.security<5 else "查看终局","保留入狱结果。"+("开始抽牌并启动巡视倒计时。" if g.state.security<5 else "警戒度5，普通逃脱流程结束。"))
  return
 if g.state.phase=="inspection":
  var stage=g.state.prison.stage
  var text={"arrival":["inspect","接受检查","狱警核对入狱清单；只降低耐久不算缺少装备。"],"result":["accept","接受检查结果","处罚一次性执行，期间不能插入操作；完成后恢复消耗牌。"],"done":["resume","继续牢房回合","巡视重新计时，正常补能和抽牌。"]}[stage]
  add(out,g,text[0],text[1],text[2])
  add(out,g,"resist","反抗狱警","与魅魔警卫战斗；保留当前牌堆，暂停巡视。胜利获得牢门钥匙，失败再次入狱。")
  return
 if g.state.phase!="prison": return
 var p=g.state.prison
 Space.candidates(g,out)
 var kick=g.kick_profile()
 var reason=""
 if "vent" not in p.found: reason="先探索找到通风口。"
 elif p.vent_hits>=B.PRISON_VENT_HITS: reason="格栅已经打开。"
 elif not Space.at(g,"vent"): reason="需要先到通风口前。"
 elif g.state.posture!="sit": reason="需要坐姿才能踢到墙脚的格栅。"
 elif kick.reason!="": reason=kick.reason
 elif p.vent_tick==g.state.tick: reason="本回合已经踢过格栅。"
 add(out,g,"vent_kick","踢击通风口","合法坐姿踢击一次推进1次，共需%d次；每回合一次。" % B.PRISON_VENT_HITS,1,reason)
 add(out,g,"vent_exit","从通风口逃离","格栅开启后即可离开；不检查站姿移动速度。",0,"先发现并踢开通风口格栅。" if p.vent_hits<B.PRISON_VENT_HITS else ("需要先到通风口前。" if not Space.at(g,"vent") else capacity_reason(g)))
 add(out,g,"key","使用牢门钥匙","钥匙不占道具容量；开门后可直接逃离，不检查行动速度。",0,"需要先击败巡视狱警，取得专用钥匙。" if not p.key else ("需要先到牢门前。" if not Space.at(g,"door") else ("牢门已经打开。" if p.door_open else "")))
 reason="牢门仍然上锁；可用手中的术式解锁牌，或击败狱警取得钥匙。" if not p.door_open else ""
 if reason=="" and not Space.at(g,"door"): reason="需要先到牢门前。"
 if reason=="" and not p.key and g.movement_profile().speed<1: reason="自行开锁逃离需要行动速度至少1；请先站起。"
 if reason=="": reason=capacity_reason(g)
 add(out,g,"door_exit","离开牢门","自行开锁后速度须至少1；狱警钥匙路线不检查速度。点击离开时重新判定。",0,reason)
 for card in g.state.hand:
  if g.Cards.Rules.SPECS[card.type].mode!="unlock": continue
  reason="牢门已经打开。" if p.door_open else ("需要先到牢门前。" if not Space.at(g,"door") else g.Cards.body_reason(g,card.type))
  var payload={"kind":"prison","action":"unlock","uid":card.uid,"type":card.type,"target":"prison_door","slot":"wrist","mode":"unlock","free":false}
  g._candidate(out,payload,g.B.CARD_NAMES[card.type]+" · 牢门","打出这张牌打开牢门；临时魔力优先抵扣耗魔。"+("随后可选择另一把外露锁。" if g.Cards.Rules.SPECS[card.type].get("hits",1)>1 else ""),g.Cards.Rules.energy_cost(card.type),g._mana_cost(B.SPELL_COST),reason,"","prison")

static func capacity_reason(g) -> String:
 return "随身道具超出容量，请在道具栏使用或放弃多出的工具。" if g.carried_items()>g.item_capacity() else ""

static func execute(g, c: Dictionary) -> String:
 var action=c.payload.action
 if action=="enter": return enter(g)
 var p=g.state.prison
 match action:
  "explore":
   return Space.execute(g,c.payload)
  "vent_kick":
   p.vent_hits+=1; p.vent_tick=g.state.tick
   g._consume_charge()
   g._emit("event","你坐着踢向通风口格栅，进度%d/%d。%s" % [p.vent_hits,B.PRISON_VENT_HITS,"格栅已打开，可以逃离。" if p.vent_hits>=B.PRISON_VENT_HITS else "格栅尚未打开，下回合可再踢一次。"])
  "unlock": g.Cards.play(g,c)
  "key":
   p.door_open=true
   g._emit("event","你用狱警留下的钥匙打开牢门，可以直接逃离。")
  "vent_exit","door_exit": escape(g,action)
  "inspect":
   var current=g.equipment_targets().map(func(e):return e.id)
   p.missing=p.baseline.filter(func(id):return id not in current)
   var current_special=g.state.special_equipment.map(func(e):return e.id)
   p.special_missing=p.special_baseline.filter(func(id):return id not in current_special)
   p.stage="result"
   var findings=[]
   if not p.missing.is_empty(): findings.append("拘束清单少了%d件：将补装%d件%s；保留的原装备收紧到三档。" % [p.missing.size(),p.missing.size()+B.PRISON_VIOLATION_EXTRA,equipment_label(g)])
   if not p.special_missing.is_empty(): findings.append("性玩具清单少了%d件：将补装%d件%s。" % [p.special_missing.size(),p.special_missing.size()+1,toy_label(g)])
   if findings.is_empty(): findings.append("装备与性玩具清单齐全，不因耐久下降收紧。已安装在墙面的工具会被发现并没收。")
   findings.append("检查结束时会补满仍佩戴性玩具的电池。")
   p.report="".join(findings)
   g._emit("event",p.report)
  "accept":
   var equipment_violation=not p.missing.is_empty()
   var toy_violation=not p.special_missing.is_empty()
   var violation=equipment_violation or toy_violation
   var outcome={"count":0,"installed":[],"removed":[],"lost_links":[]}
   var requested=p.missing.size()+B.PRISON_VIOLATION_EXTRA if equipment_violation else 0
   if equipment_violation:
    var original_ids=g.equipment_targets().map(func(e):return e.id)
    outcome=g.Application.execute(g,equipment_spec(g,requested,true),"prison","prison")
    # Compare actual worn strength first. Only then tighten the surviving old
    # pieces; fresh roots keep their security profile and factory attachments.
    for id in original_ids:
     var e=g._equipment(id)
     if e.is_empty(): continue
     e.durability=e.maximum
     g._refresh_equipment(e)
   var toy_outcome={"count":0,"installed":[],"removed":[],"lost_links":[]}
   var toy_requested=p.special_missing.size()+1 if toy_violation else 0
   if toy_violation: toy_outcome=g.Application.execute(g,toy_spec(g,toy_requested,true),"prison","prison")
   var confiscated=0
   for item in g.state.items.duplicate():
    if violation or item.mount!="carry": g.state.items.erase(item); confiscated+=1
   p.baseline=g.equipment_targets().map(func(e):return e.id)
   p.special_baseline=g.state.special_equipment.map(func(e):return e.id)
   var restored=g.state.exhaust.size()
   for card in g.state.exhaust: card.retain_until=-1
   g.state.discard.append_array(g.state.exhaust); g.state.exhaust=[]
   var recharged=refill_batteries(g)
   p.checks+=1; p.stage="done"
   var summary=""
   if equipment_violation:
    summary="补装%d/%d件%s，替下%d件旧装备或组件；原有装备已收紧。" % [outcome.count,requested,equipment_label(g),outcome.removed.size()]
    if outcome.get("evaded",0)>0: summary+="闪避抵消了%d件。" % outcome.evaded
    if outcome.count+outcome.get("evaded",0)<requested: summary+="其余%d件没有满足容量、结构与强度要求的位置。" % [requested-outcome.count-outcome.get("evaded",0)]
   if toy_violation:
    summary+="补装%d/%d件%s，替下%d件旧装备或组件。" % [toy_outcome.count,toy_requested,toy_label(g),toy_outcome.removed.size()]
    if toy_outcome.get("evaded",0)>0: summary+="闪避抵消了%d件。" % toy_outcome.evaded
    if toy_outcome.count+toy_outcome.get("evaded",0)<toy_requested: summary+="其余%d件没有满足容量与强度要求的位置。" % [toy_requested-toy_outcome.count-toy_outcome.get("evaded",0)]
   p.report="检查完成："+summary+"没收%d件道具，%d张消耗牌回到弃牌堆。已重新登记%d件装备与组件、%d件性玩具；%d件有电池的性玩具已经充满。" % [confiscated,restored,p.baseline.size(),p.special_baseline.size(),recharged.size()]
   g._emit("event",p.report,{"inspection":{"missing":p.missing.duplicate(),"requested":requested,"installed":outcome.installed.map(func(e):return e.id),"removed":outcome.removed.duplicate(),"lost_links":outcome.lost_links.duplicate(),"registered":p.baseline.size(),"special_missing":p.special_missing.duplicate(),"special_requested":toy_requested,"special_installed":toy_outcome.installed.map(func(e):return e.id),"special_removed":toy_outcome.removed.duplicate(),"special_registered":p.special_baseline.size(),"recharged":recharged,"confiscated":confiscated,"restored":restored}})
  "resume":
   p.left=B.PRISON_INTERVALS[g.state.security-1]; p.stage=""; p.missing=[];p.special_missing=[]
   begin_turn(g)
  "resist":
   g.RelicEffects.end_combat(g)
   g.RelicEffects.begin_combat(g)
   p.resisting=true
   g.state.wall_distance=g._initial_wall_distance(true)
   g.state.phase="battle"; g.state.round=0; g.state.encounter+=1
   g.state.kick_last=-10; g.state.heavy_used=false
   g.RelicEffects.clear_temporary(g)
   g.Pressure.clear_penalties(g)
   g._spawn_enemies("guard_solo")
   g._emit("event","你反抗巡视狱警，战斗开始。巡视暂停，消耗牌不会因反抗自动恢复。")
   g._start_round()
 return ""

static func won(g) -> void:
 if not g.state.prison.get("resisting",false): return
 g.state.prison.resisting=false; g.state.prison.key=true
 g._emit("event","击败巡视狱警，获得牢门钥匙；不占道具容量。奖励与整备后返回牢房，巡视继续暂停。")

static func after_preparation(g) -> bool:
 if is_exit_battle(g):
  return_to_tower(g)
  return true
 if not g.state.prison.get("active",false) or not g.state.prison.get("key",false): return false
 g.RelicEffects.begin_combat(g)
 g.state.prepare_left=0; g.state.rest_left=0
 g.state.enemies=[]
 g.state.wall_distance=Space.wall_distance(g.state.prison.space.position)
 begin_turn(g)
 return true

static func escape(g, route: String) -> void:
 g.RelicEffects.end_combat(g)
 g._leave_mounted_tools()
 g.Pressure.clear_penalties(g)
 g.state.prison={};g.state.capture={}
 g.state.practice=false
 g.state.map_region="prison"
 g.state.pressure_sources=g.state.pressure_sources.filter(func(s):return s.room=="")
 g.state.rooms=g.Tower.prison_route(g.state.security)
 g.state.room_encounters={"prison_gate":"guard_solo"}
 g.state.room="prison_start";g.state.wall="normal";g.state.wall_distance=1
 g.state.room_event={};g.state.completed_rooms=[];g.state.traversed_edges=[];g.state.journey={}
 g.state.enemies=[];g.state.phase="map";g.state.energy=0
 g._emit("event",("传送符将你带离牢房。" if route=="return_seal" else ("你爬出通风口，离开牢房。" if route=="vent_exit" else "你穿过牢门，离开牢房。"))+"来到监狱出发点。前方是休息点和出口精英战，出口由%d名魅魔警卫把守。" % g.state.security)

static func is_exit_battle(g) -> bool:
 return g.state.map_region=="prison" and g.state.room=="prison_gate"

static func return_to_tower(g) -> void:
 g._restart_tower()

static func validate(g) -> String:
 if g.state.capture.has("terminal_equipment"):
  if g.state.phase!="prison_end" or g.state.security!=5 or g.state.capture.terminal_equipment!=g.equipment_targets().map(func(e):return e.id): return "高安全终局装备清单不完整。"
  if not g.B.SLOTS.all(func(slot):return not g.equipment_at(slot).is_empty()): return "高安全终局存在未覆盖部位。"
  for e in g.equipment_targets():
   if e.grade!=3 or e.maximum!=g.Equipment.maximum(3) or e.durability!=e.maximum or e.locked!=g.Equipment.allows(e,"lock"): return "高安全终局装备必须为高级三档，并锁住所有可上锁处。"
 if g.state.phase=="prison_end" and not g.state.capture.has("terminal_equipment"): return "高安全终局缺少装备清单。"
 var p=g.state.prison
 if g.state.phase in ["prison","inspection"] and not p.get("active",false): return "牢房流程缺少入狱记录。"
 if p.is_empty(): return ""
 var space_issue=Space.validate(g)
 if space_issue!="": return space_issue
 if p.left<0 or p.left>B.PRISON_INTERVALS[mini(B.PRISON_INTERVALS.size()-1,g.state.security-1)] or p.vent_hits<0 or p.vent_hits>B.PRISON_VENT_HITS: return "巡视或通风口进度不合法。"
 var discovery_ids=p.discoveries+p.found
 var expected=p.get("discovery_pool",[])
 if expected!=ACTIVE_DISCOVERIES: return "牢房发现池与当前版本不符。"
 if discovery_ids.size()!=expected.size() or not expected.all(func(id):return discovery_ids.count(id)==1): return "牢房发现重复或缺失。"
 if p.vent_hits>0 and "vent" not in p.found: return "尚未发现通风口，不能有踢击进度。"
 if g.state.phase=="inspection" and (p.stage not in ["arrival","result","done"] or g.state.energy!=0): return "巡视阶段不合法。"
 if p.resisting and g.state.phase!="battle": return "反抗必须处于战斗阶段。"
 return ""

static func view(g) -> Dictionary:
 if g.state.phase=="prison_end":
  if g.state.capture.has("terminal_equipment"):
   return {"terminal_text":"高安全监室：装备已经补齐。共%d件装备与组件，全部高级、三档（%s/%s耐久），可上锁处全部上锁。本局已经结束，可在左侧逐件检查。" % [g.equipment_targets().size(),g.number(g.Equipment.maximum(3)),g.number(g.Equipment.maximum(3))]}
  return {"terminal_text":"本局已经结束，可以查看最终装备或重新开始。"}
 var p=g.state.prison
 if p.is_empty(): return {"equipment_rule":equipment_label(g),"toy_rule":toy_label(g)} if g.state.phase=="captured" else {}
 return {"space":Space.view(g),"active":p.active,"left":p.left,"turn":p.turn,"stage":p.stage,"remaining":discoverable(p).size(),"found":p.found.duplicate(),"vent_hits":p.vent_hits,"vent_total":B.PRISON_VENT_HITS,"door_open":p.door_open,"key":p.key,"report":p.report,"checks":p.checks,"paused":p.key or p.resisting,"equipment_rule":equipment_label(g),"toy_rule":toy_label(g)}
