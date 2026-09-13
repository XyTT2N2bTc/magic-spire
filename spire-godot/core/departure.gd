extends RefCounted
const Data=preload("res://data/departure.gd")

static func start(g, cursed_plate_start: bool=false) -> void:
 if cursed_plate_start:
  g.state.relics.erase("ember")
  g.RelicEffects.gain(g,"cursed_plate_lock")
 var rng=RandomNumberGenerator.new();rng.seed=int(g.state.seed)^0x4e454f57
 var options=[]
 for i in range(3 if cursed_plate_start else 4):
  var group=Data.GROUPS[i]
  options.append(freeze(g,group[rng.randi_range(0,group.size()-1)],rng))
 g.state.departure={"options":options,"stage":"choose","selected":"","capacity_bonus":0,"result":"","cursed_plate_start":cursed_plate_start}
 g.state.phase="departure"
 g._emit("event","抵达第0层。选择一项开局奖励，或直接出发。")

static func freeze(g, id: String, rng) -> Dictionary:
 var entry={"id":id,"cards":[],"changes":{},"relics":[],"potion":"","curse":""}
 match id:
  "uncommon","rare_card":
   entry.cards=g.reward_offer(g.Cards.Rules.UNCOMMON if id=="uncommon" else g.Cards.Rules.RARE,"fixed",rng,3)
  "transform":
   var pool=g.Cards.Rules.COMMON+g.Cards.Rules.UNCOMMON
   for card in g.state.deck:
    if g.Cards.Rules.SPECS[card.type].rarity=="basic": entry.changes[card.uid]=pool[rng.randi_range(0,pool.size()-1)]
  "potion":
   var pool=g.Tools.TYPES.keys().filter(func(type):return g.Tools.TYPES[type].get("category","")=="potion")
   entry.potion=pool[rng.randi_range(0,pool.size()-1)]
  "curse":
   var pool=g.Cards.Rules.SPECS.keys().filter(func(type):return g.Cards.Rules.SPECS[type].card_type=="curse")
   entry.curse=pool[rng.randi_range(0,pool.size()-1)]
 var tiers={"common_relic":["common"],"rare_relic":["rare"],"basics":["common","uncommon"],"wrist":["uncommon"],"boss":["boss"]}.get(id,[])
 for tier in tiers: entry.relics.append(g.RelicRewards.offer(g,tier,rng,entry.relics))
 return entry

static func selected(g) -> Dictionary:
 for entry in g.state.departure.options:
  if entry.id==g.state.departure.selected: return entry
 return {}

static func reason(g, entry: Dictionary) -> String:
 match entry.id:
  "rare_card":
   if g.state.mana_max<=10: return "魔力上限必须大于10。"
  "rare_relic":
   if g.state.mana<40: return "需要至少40点自身魔力。"
  "boss":
   if "ember" not in g.state.relics: return "已经失去初始遗物「余烬护符」。"
  "wrist":
   var issue=g.Application._request_reason(g,Data.WRIST)
   if issue!="": return issue
 for relic in entry.relics:
  if not g.Relics.can_gain(g.state.relics,relic): return "已经拥有「%s」。" % g.Relics.TYPES[relic].name
  var issue=g.RelicEffects.gain_reason(g,relic)
  if issue!="": return issue
 return ""

static func candidates(g) -> Array:
 var out=[];var d=g.state.departure
 if d.stage=="choose":
  for entry in d.options:
   g._candidate(out,{"kind":"departure","op":"choose","option":entry.id},Data.CATEGORIES[out.size()],Data.OPTIONS[entry.id],0,0,reason(g,entry),"","reward")
  g._candidate(out,{"kind":"departure","op":"skip"},"直接出发","放弃本次开局奖励。",0,0,"","","flow")
 elif d.stage=="card":
  var entry=selected(g)
  if entry.id in ["remove","transform"]:
   for card in g.state.deck:
    if entry.id=="transform" and not entry.changes.has(card.uid): continue
    g._candidate(out,{"kind":"departure","op":"card","uid":card.uid,"type":card.type},g.B.CARD_NAMES[card.type],Data.OPTIONS[entry.id],0,0,reason(g,entry),"","reward")
  else:
   for type in entry.cards:
    g._candidate(out,{"kind":"departure","op":"card","type":type},g.B.CARD_NAMES[type],Data.OPTIONS[entry.id],0,0,reason(g,entry),"","reward")
 else:
  g._candidate(out,{"kind":"departure","op":"finish"},"出发  ›","选择第一层的入口。",0,0,"","","flow")
 return out

static func execute(g, p: Dictionary) -> String:
 var d=g.state.departure
 if p.op in ["skip","finish"]:
  if p.op=="skip": d.selected="skip";d.result="放弃开局奖励。"
  d.stage="done";g.state.phase="map"
  g._emit("event","开始攀塔。选择第一层的入口。")
  return ""
 if p.op=="choose":
  d.selected=p.option
  if p.option in Data.PICKERS:
   d.stage="card"
   g._emit("event","选择了%s，请选择一张牌。" % Data.OPTIONS[p.option])
   return ""
 var entry=selected(g);var issue=reason(g,entry)
 if issue!="": return issue
 var result=Data.OPTIONS[entry.id]
 match entry.id:
  "remove":
   var old=g.Cards.remove_permanent(g,p.uid)
   if old=="": return "所选卡牌已经不在卡组中。"
   result="移除了「%s」。" % g.B.CARD_NAMES[old]
  "transform":
   var type=entry.changes[p.uid]
   for zone in ["deck"]+g.Cards.ZONES:
    for card in g.state[zone]:
     if card.uid==p.uid: card.type=type
   result="「%s」变化为「%s」。" % [g.B.CARD_NAMES[p.type],g.B.CARD_NAMES[type]]
  "uncommon","rare_card":
   if entry.id=="rare_card": g.state.mana_max-=10;g.state.mana=minf(g.state.mana,g.state.mana_max)
   g._gain_card(p.type)
   result=("魔力上限－10。\n" if entry.id=="rare_card" else "")+"获得「%s」。" % g.B.CARD_NAMES[p.type]
  "flask": g.state.flask_mana+=40
  "mana": g.state.mana_max+=10;g.state.mana=minf(g.state.mana+10,g.state.mana_max)
  "potion":
   d.capacity_bonus=1;g._gain_tool(entry.potion)
   result="道具容量＋1，获得「%s」。" % g.Tools.TYPES[entry.potion].name
  "rare_relic": g.state.mana-=40
  "curse":
   g._gain_card(entry.curse);g.state.flask_mana+=100
   result="加入诅咒「%s」，魔瓶获得100点魔力。" % g.B.CARD_NAMES[entry.curse]
  "basics": g._gain_card("strain");g._gain_card("slip")
  "wrist":
   var applied=g.Application.execute_concrete(g,Data.WRIST,"departure")
   if not applied.ok: return applied.reason
  "boss": g.state.relics.erase("ember")
 for relic in entry.relics:
  g.RelicEffects.gain(g,relic)
  result+="\n获得「%s」。" % g.Relics.TYPES[relic].name
 d.stage="done";d.result=result
 g._emit("event",result)
 return ""

static func panel(g, actions: Array) -> Dictionary:
 var d=g.state.departure
 var rows=[]
 for c in actions:
  if c.payload.kind!="departure": continue
  rows.append({"action_id":c.id,"label":c.label,"detail":c.detail,"reason":c.reason,"valid":c.valid,"type":c.payload.get("type",""),"uid":c.payload.get("uid",""),"op":c.payload.op})
 var invitation="三选一，也可以直接出发。\n初始遗物已替换为「诅咒平板锁」。" if d.get("cursed_plate_start",false) else "四选一，也可以直接出发。"
 return {"active":true,"layout":"departure","title":"选择一张牌" if d.stage=="card" else ("准备出发" if d.stage=="done" else "第0层 · 出发"),"destination":Data.OPTIONS[d.selected] if d.stage=="card" else (d.result if d.stage=="done" else invitation),"continue_id":"","continue_label":"","extra_ids":[],"rows":[],"entries":rows,"stage":d.stage}

static func validate(g, s: Dictionary) -> String:
 var d=s.get("departure")
 if not d is Dictionary: return "开局选择记录不完整。"
 if d.is_empty(): return "开局选择记录缺失。" if s.phase=="departure" else ""
 var custom=d.get("cursed_plate_start",false)
 if not custom is bool: return "定制开局记录不正确。"
 if custom and s.phase=="departure" and (not s.chastity_locks_enabled or "cursed_plate_lock" not in s.relics or "ember" in s.relics): return "定制开局遗物记录不正确。"
 if not g.Snapshot.fields(d,"options:a stage:s selected:s capacity_bonus:i result:s") or d.options.size()!=(3 if custom else 4) or d.stage not in ["choose","card","done"] or d.capacity_bonus not in [0,1]: return "开局选择记录不正确。"
 for i in range(d.options.size()):
  var e=d.options[i]
  if not g.Snapshot.fields(e,"id:s cards:z changes:d relics:z potion:s curse:s") or e.id not in Data.GROUPS[i]: return "开局选项分类不正确。"
  if e.id in ["uncommon","rare_card"]:
   var pool=g.Cards.Rules.UNCOMMON if e.id=="uncommon" else g.Cards.Rules.RARE
   if e.cards.size()!=3 or not e.cards.all(func(id):return id in pool) or e.cards[0]==e.cards[1] or e.cards[0]==e.cards[2] or e.cards[1]==e.cards[2]: return "开局奖励牌不正确。"
  elif not e.cards.is_empty(): return "开局选项不应含有奖励牌。"
  if e.id=="transform":
   if e.changes.is_empty(): return "变化结果缺失。"
   for uid in e.changes:
    if not uid is String or e.changes[uid] not in g.Cards.Rules.COMMON+g.Cards.Rules.UNCOMMON: return "变化结果不正确。"
  elif not e.changes.is_empty(): return "开局选项不应含有变化结果。"
  var tiers={"common_relic":["common"],"rare_relic":["rare"],"basics":["common","uncommon"],"wrist":["uncommon"],"boss":["boss"]}.get(e.id,[])
  if e.relics.size()!=tiers.size(): return "开局遗物数量不正确。"
  for j in range(tiers.size()):
   if e.relics[j] not in g.Relics.TYPES or e.relics[j] not in s.relic_seen or g.Relics.TYPES[e.relics[j]].rarity!=tiers[j]: return "开局遗物品质不正确。"
  if e.id=="potion":
   if e.potion not in g.Tools.TYPES or g.Tools.TYPES[e.potion].get("category","")!="potion": return "开局药剂不正确。"
  elif e.potion!="": return "开局选项不应含有药剂。"
  if e.id=="curse":
   if e.curse not in g.Cards.Rules.SPECS or g.Cards.Rules.SPECS[e.curse].card_type!="curse": return "开局诅咒不正确。"
  elif e.curse!="": return "开局选项不应含有诅咒。"
 var ids=d.options.map(func(e):return e.id)
 if d.stage=="choose" and (d.selected!="" or d.capacity_bonus!=0): return "尚未选择开局奖励。"
 if d.stage=="card" and (d.selected not in ids or d.selected not in Data.PICKERS or d.capacity_bonus!=0): return "开局选牌记录不正确。"
 if d.stage=="done" and d.selected not in ids+["skip"]: return "开局领取记录不正确。"
 if d.capacity_bonus!=(1 if d.stage=="done" and d.selected=="potion" else 0): return "开局道具容量记录不正确。"
 return ""
