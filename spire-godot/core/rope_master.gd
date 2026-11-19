extends RefCounted

# Encounter-local control; installations, payments and cleanup use Game's seams.
const MASTER="rope_master"
const ASSISTANT="rope_assistant"
const STATUS="art_submission"
const HOGTIE="art_hogtie"
const LIMIT=24
const OPENING_STOCK=48
const ACTIONS={"art_intro":"隆重介绍","art_domain":"领域展开","art_sweep":"看我手速","art_tighten":"收紧！","art_tightest":"收到最紧！","art_refill":"补充绳索","art_weave":"编织绳网","art_enchant":"绳索附魔","art_admire":"欣赏作品并指指点点","art_seal":"我已探明","art_grief":"悲伤逆流成河","art_revive":"复活吧我的助理","art_prepare":"跃跃欲试","art_status":"硬上弓","art_patch":"查漏补缺","art_respect":"你必须尊重艺术","art_play":"调弄","art_rest":"手累了歇会","art_help":"我来帮忙"}
const OPENING=["art_intro","art_domain","art_sweep","art_tighten","art_tightest","art_refill"]
const CYCLE=["art_weave","art_enchant","art_tighten","art_admire"]

static func master(g) -> Dictionary:
 if g.state.phase!="battle": return {}
 for e in g.state.enemies:
  if e.type==MASTER and not e.gone: return e
 return {}

static func assistant(g) -> Dictionary:
 for e in g.state.enemies:
  if e.type==ASSISTANT and not e.gone: return e
 return {}

static func initialize(g, e: Dictionary) -> void:
 if e.type==MASTER:
  e.rope_art={"stock":OPENING_STOCK,"refill":false,"grief":false,"revive":false,"deaths":0,"domain":false,"seal":false,"total":0,"values":{},"seen50":false,"seen75":false,"previous":0,"drunk":0,"submission":0,"active":0,"drain":0,"desire":0,"hogtie":"","hogtie_pending":0}
  for item in g.action_targets(): track(g,item)
 elif e.type==ASSISTANT:
  e.rope_helper={"born":g.state.round,"rest":-1,"respect":false,"owner":master(g).get("id","")}

static func is_rope(item: Dictionary) -> bool:
 return item.get("material","")=="rope"

# QX2″ (rev3.3 plan-delta §3.2): the transaction's installed members are accounted by their join
# hooks after the commit replay, so this announcement only writes off what left. The removed and
# lost-link entries are bare ids -- the records are no longer on live state.
static func replaced(g, result: Dictionary) -> void:
 var boss=master(g)
 if boss.is_empty(): return
 account(g,result.get("removed",[])+result.get("lost_links",[]),true)

# One accounting batch (rev3.2 §3.1): the ledger is written only through here and then through
# `track`, which stays the one per-record primitive. Every nested member is handed over as a record
# the caller resolved while it was still reachable; a bare id is a removal of a member already gone.
static func account(g, records: Array, removed: bool=false) -> void:
 if master(g).is_empty(): return
 for record in records:
  if typeof(record)==TYPE_STRING: track(g,{"id":String(record)},true)
  else: track(g,record,removed)

# The closure of one record (rev3.2 §3.1): the record itself, its components, its linked torso
# connection, both shoulder pieces and the reinforcement strap it owns. One definition for additions,
# removals, the tier hook and the debug reconciliation, so a nested member is never half-counted.
static func closure(g, record: Dictionary) -> Array:
 var records=[record]
 for piece in record.get("components",[]): records.append(piece)
 var binding=record.get("binding",{})
 if not binding.is_empty() and String(binding.get("kind",""))=="linked": records.append(binding)
 for strap in Dictionary(record.get("shoulders",{})).get("pieces",[]): records.append(strap)
 var id=String(record.get("id",""))
 if id!="" and g.SpecialEquipment.supports_reinforcement(record):
  for item in g.state.special_equipment:
   if String(item.get("owner_id",""))==id: records.append(item)
 return records

# Debug-only full reconciliation (rev3.2 §3.5): recompute every rope instance of the body with the
# same formula `track` uses and compare the result with the ledger. "" means they agree; the release
# build never calls this.
static func account_issue(g) -> String:
 var boss=master(g)
 if boss.is_empty(): return ""
 var r=boss.rope_art
 var expected={}
 var total=0
 var hogtie=""
 for item in g.action_targets():
  var value=0
  if is_rope(item) and float(item.get("durability",0.0))>0.000001: value=g.RestraintValue.from_profile(item.grade,g.equipment_tier(item))
  if value<=0: continue
  expected[String(item.id)]=value
  total+=value
  if String(item.get("template",""))==HOGTIE: hogtie=String(item.id)
 if int(r.total)!=total: return "总值 %d，重算 %d" % [int(r.total),total]
 for id in expected:
  if int(r.values.get(id,0))!=int(expected[id]): return "%s=%d，重算 %d" % [id,int(r.values.get(id,0)),int(expected[id])]
 for id in r.values:
  if not expected.has(String(id)): return "%s 已不在身上" % id
 if String(r.hogtie)!=hogtie: return "驷马缚 %s，重算 %s" % [String(r.hogtie),hogtie]
 return ""

# Existing installation/damage/cleanup visits deliver only the changed instance. QX2″ routes every
# write through `account`; `initialize` is the other caller (the battle-entry full count).
static func track(g, item: Dictionary, removed: bool=false) -> void:
 if g._sandbox_depth>0: return
 var e=master(g)
 if e.is_empty() or not e.has("rope_art"): return
 var r=e.rope_art
 var old=int(r.values.get(item.id,0))
 var value=0 if removed or not is_rope(item) or item.durability<=0.000001 else g.RestraintValue.from_profile(item.grade,g.equipment_tier(item))
 r.total+=value-old
 if value==0: r.values.erase(item.id)
 else: r.values[item.id]=value
 if item.get("template","")==HOGTIE: r.hogtie=item.id if value>0 else ""

static func locked(g, item: Dictionary) -> bool:
 var e=master(g)
 return not e.is_empty() and e.rope_art.seal and is_rope(item)

static func floor_value(g, item: Dictionary, after: float) -> float:
 return maxf(0.00001,after) if locked(g,item) else after

# J6 (QX2″ rev3.3 plan-delta §2.4, §4.2): the presentation of the piece the master just applied -- he
# pays its value from the stock and the log names it, in the same order the pre-Q5″ loop used but now
# before the settle point. Only a top-level application presents: nested members (binding, straps,
# components) are booked by J3 and named by their own copy, and nothing presents outside the scope.
static func joined(g, record: Dictionary) -> void:
 if g._art_scope.is_empty(): return
 var scope: Dictionary=g._art_scope.back()
 var boss: Dictionary=scope.get("boss",{})
 if boss.is_empty() or master(g).is_empty(): return
 # The presentation is part of every application the scope covers; the price is paid only when the
 # caller's own caller is the master (the hogtie branch passes `own` for its own value instead).
 if bool(scope.get("own",false)):
  boss.rope_art.stock-=g.RestraintValue.from_profile(record.grade,g.equipment_tier(record))
 g._emit("event",boss.name+"施加了"+record.name+"。",{"enemy_action":{"enemy_id":boss.id,"actor":boss.name,"sequence":g.state.logs.size(),"kind":String(scope.get("kind","apply")),"slots":g.Equipment.coverage(record)}})

static func hogtied(g) -> bool:
 var e=master(g)
 return not e.is_empty() and e.rope_art.hogtie!=""

static func bound(g) -> bool:
 var e=master(g)
 return not e.is_empty() and e.rope_art.domain

static func active_value(g, key: String) -> int:
 var e=master(g)
 return int(e.rope_art[key]) if not e.is_empty() and e.rope_art.domain and e.rope_art.total>0 else 0

static func target_reason(g, e: Dictionary, all_targets: bool) -> String:
 if e.type==ASSISTANT and not all_targets and g.state.round<=e.rope_helper.born+3: return "绳艺助理暂时不能被单体选中。"
 return ""

static func plan(g, e: Dictionary) -> Dictionary:
 var kind=""
 if e.type==MASTER:
  var r=e.rope_art
  if r.domain and r.total>=100: return {"kind":"capture","text":"执行收押","delayed":false}
  if r.grief: kind="art_grief"
  elif r.revive: kind="art_revive"
  elif r.refill: kind="art_refill"
  elif e.stage<=6: kind=OPENING[e.stage-1]
  else:
   kind=CYCLE[(e.stage-7)%4]
   if e.stage==18: kind="art_seal"
 else:
  var boss=master(g)
  if boss.is_empty(): kind="art_rest"
  elif plan(g,boss).kind=="art_refill": kind="art_help"
  elif e.rope_helper.rest==g.state.round: kind="art_rest"
  else: kind=["art_prepare","art_status","art_patch","art_respect"][e.stage-1] if e.stage<=4 else "art_play"
 return {"kind":kind,"text":ACTIONS[kind],"delayed":false}

static func finish_turn(g, e: Dictionary, intent: Dictionary) -> bool:
 if e.type not in [MASTER,ASSISTANT]: return true
 if intent.kind in ["art_grief","art_revive","art_rest","art_help"]: return false
 if intent.kind=="art_refill" and e.stage!=6: return false
 return intent.kind!="capture"

static func summon(g, boss: Dictionary) -> void:
 if not assistant(g).is_empty(): return
 var helper=g._append_enemies([{"type":ASSISTANT,"grade":2}])[0]
 helper.rope_helper.owner=boss.id
 helper.acted_round=g.state.round
 helper.intent=plan(g,helper)
 g._emit("event",boss.name+"召唤了绳艺助理。")

static func spec(grade: int, tier: int, links: bool=false) -> Dictionary:
 return {"pool":"ordinary","templates":["link_rope"] if links else ["rope","cord"],"grade":grade,"tier":tier,"count":1,"replace":true,"allow_links":links}

# A budget fallback changes quality before tightness; legality stays in Application.
static func install(g, e: Dictionary, request: Dictionary) -> bool:
 var own=e.type==MASTER
 var current=request.duplicate(true)
 if own:
  var budget=e.rope_art.stock
  while g.RestraintValue.from_profile(current.grade,current.tier)>budget and current.grade>1: current.grade-=1
  while g.RestraintValue.from_profile(current.grade,current.tier)>budget and current.tier>1: current.tier-=1
  if g.RestraintValue.from_profile(current.grade,current.tier)>budget:
   e.rope_art.refill=true
   return false
  if current.pool=="special":
   current.templates=current.templates.filter(func(id):return g.SpecialEquipment.DESIGNS[id].grade==current.grade)
 var result={}
 # 甲 (rev3.3 §4.1): the application raises the art scope, so its top-level hook presents the piece,
 # pays for it and observes -- the nested members' hooks do neither.
 g._art_scope.append({"boss":e,"own":own,"kind":String(e.intent.get("kind","apply"))})
 result=g.Application.execute(g,current,e.id)
 g._art_scope.pop_back()
 if own and e.rope_art.stock<2: e.rope_art.refill=true
 return result.ok

static func ordinary(g, e: Dictionary, grade: int, tier: int, extra: Dictionary={}) -> bool:
 var request=spec(grade,tier);request.merge(extra,true)
 # Explicit all-empty sweeps never replace the just-installed earlier positions.
 if g.Application.can_apply(g,request,e.id): return install(g,e,request)
 var link=spec(grade,tier,true)
 if g.Application.can_apply(g,link,e.id): return install(g,e,link)
 for item in g.action_targets():
  if is_rope(item) and g.equipment_tier(item)<3:
   g._reinforce_equipment(item);return true
 return false

static func sweep(g, e: Dictionary, grade: int) -> void:
 var empty=g.B.ARM_SLOTS+g.B.LEG_SLOTS
 empty=empty.filter(func(slot):return not g.occupied(slot))
 for slot in empty:
  ordinary(g,e,grade,1,{"slot":slot,"replace":false,"free_slots":true})
 if not g.state.special_equipment.any(func(item):return g.SpecialEquipment.TYPES[item.type].family=="crotch_rope"):
  install(g,e,{"pool":"special","templates":["crotch_rope_low","crotch_rope_medium","crotch_rope_high"].filter(func(id):return g.SpecialEquipment.DESIGNS[id].grade==grade),"grade":grade,"tier":1,"count":1,"replace":true})

static func execute(g, e: Dictionary, intent: Dictionary) -> void:
 match intent.kind:
  "art_intro","art_revive":
   summon(g,e)
   e.rope_art.revive=false
  "art_domain":
   e.rope_art.domain=true
   g.state.guard_bind={"progress":0.0,"sources":{MASTER:{"enemy":e.id,"energy":0}}}
   for where in [{"slot":"wrist"},{"slot":"forearm","point":"below_elbow"}]:
    ordinary(g,e,2,2,where if not g.occupied(where.slot) else {})
   observe(g)
  "art_sweep","art_patch": sweep(g,e,2 if e.type==MASTER else 1)
  "art_tighten","art_tightest":
   # Each tightening observes through its own tier hook (T), so the loop needs no trailing observation
   # and a crossing mid-round applies the hogtie before the remaining pieces are tightened (D18).
   for item in g.action_targets():
    if is_rope(item) and g.equipment_tier(item)<3: g._reinforce_equipment(item)
  "art_refill":
   e.rope_art.stock=e.rope_art.stock+12 if assistant(g).is_empty() else maxi(LIMIT,e.rope_art.stock)
   e.rope_art.refill=false
   g._emit("event","绳索补充至%d/%d。" % [e.rope_art.stock,LIMIT])
   if e.rope_art.hogtie_pending>0: hogtie(g,e,e.rope_art.hogtie_pending)
  "art_weave":
   for i in range(2):
    var profile=g.RestraintValue.profiles(3)[g._random_index("enemy",2)]
    ordinary(g,e,profile.grade,profile.tier)
   ordinary(g,e,1,1,{"templates":["link_rope"],"allow_links":true})
  "art_enchant":
   var choices=["active","drain","desire"]
   var fresh=choices.filter(func(key):return e.rope_art[key]==0)
   if not fresh.is_empty(): choices=fresh
   var selected=choices[g._random_index("enemy",choices.size())]
   e.rope_art[selected]+=1
   g._emit("event",{"active":"活性绳索","drain":"吸魔绳索","desire":"情欲绳索"}[selected]+"＋1。")
  "art_admire":
   pressure(g,3.0,g.SpecialEquipment.slots().filter(func(slot):return slot!="special_2_d"),e.name)
  "art_seal":
   e.rope_art.seal=true
   g._emit("event","本场战斗中，全部绳索拘束具无法解除，紧度最低为1档。")
  "art_grief":
   e.rope_art.grief=false;e.rope_art.revive=e.rope_art.deaths==1
   g._emit("event",e.name+"本回合不行动。")
  "art_prepare": g._emit("event","绳艺助理准备加入状态牌。")
  "art_status":
   var card=g._gain_temporary_card(STATUS)
   g.state.discard.erase(card);g.state.draw.append(card)
   g._shuffle(g.state.draw)
   install(g,e,{"pool":"ordinary","templates":["mouth_band"],"grade":3,"tier":2,"count":1,"replace":true,"allow_links":false})
  "art_respect": e.rope_helper.respect=true
  "art_play": pressure(g,6.0,["special_1_a","special_1_b"],e.name)
  "art_rest","art_help": g._emit("event",e.name+"本回合不行动。")

# Aggregate before adding pressure: flat modifiers and climax settle once.
static func pressure(g, amount: float, slots: Array, source: String) -> void:
 var valid=slots.filter(func(slot):return not (g.Character.active(g) and slot.begins_with("special_2")))
 var total=0.0
 for slot in valid: total+=amount*g.Pressure.source_multiplier(g,[slot])
 if total>0: g.Pressure.gain(g,total/g.Pressure.gain_multiplier(g),source)

static func unavailable(g) -> bool:
 return g.Character.active(g) or g.state.special_equipment.any(func(item):return g.SpecialEquipment.is_chastity(item) or g.SpecialEquipment.TYPES.get(item.get("type",""),{}).get("family","") in g.SpecialEquipment.CUP_FAMILIES)

static func played(g, p: Dictionary, success: bool) -> void:
 if p.get("replay",false) or g.state.phase!="battle": return
 var desire=active_value(g,"desire")
 if desire>0: g.Pressure.gain(g,float(desire),"情欲绳索")
 if not success or p.get("target","")=="" or g._equipment(p.target).is_empty(): return
 var helper=assistant(g)
 if helper.is_empty() or not helper.rope_helper.respect or helper.rope_helper.rest==g.state.round: return
 var boss=master(g)
 if boss.is_empty() or plan(g,boss).kind=="art_refill": return
 pressure(g,15.0 if unavailable(g) else 5.0,["special_3_a"] if unavailable(g) else ["special_2_a","special_2_b","special_2_c"],helper.name)

static func drawn(g, card: Dictionary) -> void:
 var boss=master(g)
 if card.type==STATUS and not boss.is_empty() and not assistant(g).is_empty():
  boss.rope_art.submission+=1
  g._emit("event","不可反抗＋1。")

static func card_damage(g, item: Dictionary, amount: float) -> float:
 if amount<=0 or g.state.play.is_empty(): return amount
 var card=g.state.play[0]
 var boss=master(g)
 if boss.is_empty(): return amount
 var r=boss.rope_art
 if not card.has("art_block"):
  if r.submission>0: r.submission-=1;card.art_block="all"
  elif is_rope(item) and r.drunk>0: r.drunk-=1;card.art_block="rope"
 if card.get("art_block","")=="all" or (card.get("art_block","")=="rope" and is_rope(item)): return 0.0
 return amount

static func turn_end(g) -> void:
 var amount=minf(g.state.mana,5.0*active_value(g,"drain"))
 if amount>0:
  g.state.mana-=amount
  g._emit("event","吸魔绳索消耗%s自身魔力。" % g.number(amount))

static func climax(g) -> void:
 var helper=assistant(g)
 if not helper.is_empty(): helper.rope_helper.rest=g.state.round+1

static func death(g, e: Dictionary) -> void:
 if e.type==MASTER:
  for helper in g.state.enemies:
   if helper.type==ASSISTANT and not helper.gone: helper.gone=true;helper.hp=0;helper.intent={}
  clear_cards(g)
 elif e.type==ASSISTANT:
  clear_cards(g)
  var boss=master(g)
  if boss.is_empty(): return
  boss.rope_art.submission=0;boss.rope_art.deaths+=1;boss.rope_art.grief=true
  boss.intent=plan(g,boss)
  var protected=[]
  for i in range(2):
   var profile=g.RestraintValue.profiles(4)[g._random_index("enemy",3)]
   var before=g.state.special_equipment.map(func(item):return item.id)
   install(g,e,{"pool":"special","templates":g.SpecialEquipment.prison_pool(profile.grade,true,false),"grade":profile.grade,"tier":profile.tier,"count":1,"replace":true,"protected_ids":protected})
   for item in g.state.special_equipment:
    if item.id not in before: protected.append(item.id)

static func clear_cards(g) -> void:
 for zone in ["deck"]+g.Cards.ZONES:
  g.state[zone]=g.state[zone].filter(func(card):return card.type!=STATUS)

static func hogtie(g, boss: Dictionary, grade: int) -> void:
 var old=g._equipment(boss.rope_art.hogtie)
 if not old.is_empty():
  var next_grade=maxi(old.grade,grade)
  var cost=maxi(0,next_grade+2-g.RestraintValue.from_profile(old.grade,g.equipment_tier(old)))
  if cost>boss.rope_art.stock:
   boss.rope_art.hogtie_pending=maxi(boss.rope_art.hogtie_pending,grade)
   boss.rope_art.refill=true
   return
  boss.rope_art.stock-=cost
  g._write_quality(old,next_grade)
  old.name=g.Equipment.name_for(HOGTIE,"wrist",next_grade)
 else:
  var cost=g.RestraintValue.from_profile(grade,2)
  if cost>boss.rope_art.stock:
   boss.rope_art.hogtie_pending=maxi(boss.rope_art.hogtie_pending,grade)
   boss.rope_art.refill=true
   return
  var request={"kind":"install","template":HOGTIE,"slot":"wrist","point":"","grade":grade,"tier":2,"variant":0,"locked":false,"source":boss.id}
  # 甲: the scope pays the new hogtie's value through J6 before J7 observes, so the stock read by a
  # second threshold crossing is already charged; this branch only checks the budget above.
  g._art_scope.append({"boss":boss,"own":true,"kind":String(boss.intent.get("kind","apply"))})
  var result=g.Application.execute_concrete(g,request,boss.id,true)
  g._art_scope.pop_back()
  if not result.ok: return
 boss.rope_art.hogtie_pending=0

static func observe(g) -> void:
 if g._sandbox_depth>0: return
 var boss=master(g)
 if boss.is_empty(): return
 var r=boss.rope_art
 if not r.domain: return
 if g._rope_observing: return
 g._rope_observing=true
 # Each pass consumes a distinct crossing; installations may cause the next one.
 for iteration in range(8):
  var before=r.previous;var value=mini(100,r.total)
  r.previous=value
  g.state.guard_bind={"progress":float(value),"sources":{MASTER:{"enemy":boss.id,"energy":0}}}
  var crossed50=not r.seen50 and value>=50
  var crossed75=not r.seen75 and value>=75
  if crossed50: r.seen50=true;r.drunk+=2
  if crossed75: r.seen75=true;r.drunk+=2
  if before<90 and value>=90: r.drunk+=2
  if crossed50: hogtie(g,boss,2)
  if before<80 and value>=80: hogtie(g,boss,3)
  if mini(100,r.total)==value: break
 if hogtied(g): g.state.posture="lie";g.state.order="last"
 g._rope_observing=false

static func description(e: Dictionary) -> String:
 if e.type==MASTER:
  return "绳索%d/24。成功施加消耗绳索；捕缚值随当前绳索拘束值变化。50／75及重跨90获得醉绳；50／重跨80施加驷马缚。完成第三轮后绳索不能解除。" % e.rope_art.stock
 return "召唤后的前三回合不可单体选中；群攻有效。死亡清除状态牌与不可反抗。首次死亡后复活一次。"

static func validate(g, e: Dictionary) -> String:
 if e.type==MASTER:
  if not g.Snapshot.fields(e,"rope_art:d"): return "绳艺大师记录缺失。"
  var r=e.rope_art
  if not g.Snapshot.fields(r,"stock:i refill:b grief:b revive:b deaths:i domain:b seal:b total:i values:d seen50:b seen75:b previous:i drunk:i submission:i active:i drain:i desire:i hogtie:s hogtie_pending:i"): return "绳艺大师记录不完整。"
  for key in ["stock","deaths","total","previous","drunk","submission","active","drain","desire","hogtie_pending"]:
   if r[key]<0: return "绳艺大师计数不能为负。"
  if r.deaths>2 or r.previous>100 or r.hogtie_pending>3: return "绳艺大师阶段记录不合法。"
  for value in r.values.values():
   if not value is int or value<=0 or value>6: return "绳索拘束值记录不合法。"
 elif e.type==ASSISTANT:
  if not g.Snapshot.fields(e,"rope_helper:d") or not g.Snapshot.fields(e.rope_helper,"born:i rest:i respect:b owner:s"): return "绳艺助理记录不完整。"
 elif e.has("rope_art") or e.has("rope_helper"): return "非绳艺敌人携带专属记录。"
 return ""
