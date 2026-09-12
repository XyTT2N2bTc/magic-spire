extends RefCounted

static func start(g, source: String) -> void:
 var entries=[]
 for rarity in g.RelicRewards.TIERS:
  entries.append({"type":g.RelicRewards.offer(g,rarity),"rarity":rarity,"status":"pending"})
 g.state.relic_bundle={"source":source,"entries":entries}

static func candidates(g) -> Array:
 var out=[]
 for i in range(g.state.relic_bundle.entries.size()):
  var entry=g.state.relic_bundle.entries[i]
  if entry.status!="pending": continue
  var reason=g.RelicEffects.gain_reason(g,entry.type)
  if not g.Relics.can_gain(g.state.relics,entry.type): reason="已经拥有这件遗物。"
  g._candidate(out,{"kind":"relic_bundle","op":"claim","index":i},"领取「"+g.Relics.TYPES[entry.type].name+"」",g.Relics.TYPES[entry.type].detail,0,0,reason,"","reward")
  g._candidate(out,{"kind":"relic_bundle","op":"skip","index":i},"跳过","放弃这件遗物，其他两件仍可领取。",0,0,"","","reward")
 g._candidate(out,{"kind":"relic_bundle","op":"finish"},"返回奖励","未领取的遗物将被放弃。",0,0,"","","reward")
 return out

static func execute(g, p: Dictionary) -> void:
 if p.op=="finish":
  var count=g.state.relic_bundle.entries.filter(func(entry):return entry.status=="pending").size()
  if count>0: g._emit("event","放弃套娃中剩余的%d件遗物。" % count)
  g.state.relic_bundle={}
  return
 var entry=g.state.relic_bundle.entries[p.index]
 entry.status="claimed" if p.op=="claim" else "skipped"
 if p.op=="claim": g.RelicEffects.gain(g,entry.type)
 else: g._emit("event","跳过「"+g.Relics.TYPES[entry.type].name+"」。")

static func panel(g, actions: Array) -> Dictionary:
 var entries=[]
 for i in range(g.state.relic_bundle.entries.size()):
  var saved=g.state.relic_bundle.entries[i]
  var entry=g.Relics.view([saved.type])[0]
  entry.index=i;entry.status=saved.status
  entry.rarity_label=g.Relics.RARITIES[saved.rarity]
  var matches=actions.filter(func(c):return c.payload.get("kind","")=="relic_bundle" and c.payload.get("index",-1)==i)
  entry.claim_id="";entry.skip_id="";entry.reason=""
  for c in matches:
   if c.payload.op=="claim": entry.claim_id=c.id;entry.reason=c.reason
   else: entry.skip_id=c.id
  entries.append(entry)
 var exits=actions.filter(func(c):return c.payload.get("kind","")=="relic_bundle" and c.payload.op=="finish")
 return {"active":true,"layout":"relic_bundle","title":g.Relics.TYPES[g.state.relic_bundle.source].name,"destination":"三件遗物可分别领取或跳过。","continue_id":exits[0].id,"continue_label":"返回奖励  ›","extra_ids":[],"rows":[],"entries":entries}

static func validate(g, state: Dictionary) -> String:
 var bundle=state.get("relic_bundle")
 if not bundle is Dictionary: return "遗物待领取记录不完整。"
 if bundle.is_empty(): return ""
 if bundle.size()!=2 or bundle.get("source","")!="nesting_doll" or bundle.source not in state.relics or not bundle.get("entries") is Array or bundle.entries.size()!=3: return "套娃奖励记录不正确。"
 var seen=[]
 for i in range(3):
  var entry=bundle.entries[i]
  if not entry is Dictionary or entry.size()!=3 or entry.get("rarity","")!=g.RelicRewards.TIERS[i] or entry.get("status","") not in ["pending","claimed","skipped"]: return "套娃遗物领取状态不正确。"
  var id=entry.get("type","")
  if id not in g.Relics.TYPES or id not in state.relic_seen: return "套娃遗物来源不正确。"
  if id!=g.Relics.FALLBACK:
   if id not in g.Relics.REWARDS or g.Relics.TYPES[id].rarity!=entry.rarity or id in seen: return "套娃遗物品质或重复记录不正确。"
   if (id in state.relics)!=(entry.status=="claimed"): return "套娃遗物持有记录与领取状态不符。"
  elif entry.status=="claimed" and id not in state.relics: return "套娃遗物领取记录缺少已获遗物。"
  seen.append(id)
 return ""
