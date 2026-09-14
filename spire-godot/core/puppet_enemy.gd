extends RefCounted

# Encounter-local summon and hit reaction; installation and damage stay on Game's
# existing transaction paths. The prepared payload is equipment, not a second actor inventory.
static func owned(g, master: Dictionary) -> Dictionary:
 for enemy in g.state.enemies:
  if not enemy.gone and enemy.get("puppet_owner","")==master.id: return enemy
 return {}

static func plan(e: Dictionary) -> Dictionary:
 var kind="puppet_awaken" if e.stage==1 else ["puppet_mend","puppet_composite","puppet_special"][(e.stage-2)%3]
 return {"kind":kind,"text":{"puppet_awaken":"引敌缚咒","puppet_mend":"缝补玩偶","puppet_composite":"复合装束","puppet_special":"暗藏机关"}[kind],"delayed":false}

static func summon(g, master: Dictionary) -> void:
 if not owned(g,master).is_empty(): return
 var doll=g._append_enemies([{"type":"puppet","grade":2}])[0]
 doll.puppet_security_bonus=g.Prison.health_bonus(g,g.state)
 doll.puppet_owner=master.id;doll.puppet_awakened=false;doll.puppet_prepared={};doll.puppet_mends=0
 doll.acted_round=g.state.round;doll.intent=g._plan(doll)
 g._emit("event",master.name+"带着一个%s点生命的玩偶登场。" % g.number(doll.hp),{"summoned":{"enemy":doll.id,"owner":master.id}})

static func execute(g, master: Dictionary, intent: Dictionary) -> void:
 var doll=owned(g,master)
 if doll.is_empty():
  g._emit("event",master.name+"的玩偶已经离场，这次动作落空。")
  return
 match intent.kind:
  "puppet_awaken":
   doll.puppet_awakened=true
   g._emit("event",master.name+"赋予玩偶「引敌缚咒」。",{"puppet_awakened":doll.id})
  "puppet_mend":
   var previous=doll.max_hp
   doll.puppet_mends+=1;doll.max_hp+=5;doll.hp=doll.max_hp
   g._emit("event",master.name+"缝补玩偶，生命上限%s→%s，并恢复至满血。" % [g.number(previous),g.number(doll.max_hp)],{"puppet_mend":{"enemy":doll.id,"before":previous,"maximum":doll.max_hp}})
  "puppet_special","puppet_composite":
   var special=intent.kind=="puppet_special"
   var selected
   if special:
    var probe={"pool":"special","templates":g.Enemies.TYPES[master.type].special_pool,"grade":2,"tier":3,"count":1,"replace":true}
    var concrete=g.Application.choose(g,probe,master.id,"enemy")
    if concrete.is_empty():
     g._emit("event",master.name+"没有找到还能佩戴的额外装束，这次准备落空。")
     return
    selected=concrete.type
   else:
    var choices=g.EquipmentOffers.assembly_specs().filter(func(row):return g.Composites.spec(row.family,row.variant,row.straps).minimum<=2)
    selected=choices[g._random_index("enemy",choices.size())]
   var prepared={"kind":"apply","pool":"special" if special else "composite","templates":[selected],"grade":2,"tier":3 if special else 2,"count":1,"replace":true,"locked":false,"final":false,"delayed":false,"text":"玩偶的额外装束"}
   doll.puppet_prepared[prepared.pool]=prepared
   g._emit("event",master.name+"为玩偶准备了"+prepared_name(g,prepared)+"。",{"puppet_prepared":{"enemy":doll.id,"pool":prepared.pool}})

static func prepared_name(g, prepared: Dictionary) -> String:
 var selected=prepared.templates[0]
 var name=g.SpecialEquipment.TYPES[selected].name if prepared.pool=="special" else g.Composites.spec(selected.family,selected.variant,selected.straps).name
 return "中级%d档%s" % [prepared.tier,name]

static func ordinary(g, doll: Dictionary) -> Dictionary:
 var request=g.EnemyPlans.application(g.Enemies.TYPES[doll.type].install_pool,2,2)
 request.replace=true;request.shoulders=true
 return request

static func taunt_reason(g, target: Dictionary, all_targets: bool) -> String:
 if all_targets or target.get("puppet_awakened",false): return ""
 for doll in g.state.enemies:
  if not doll.gone and doll.get("puppet_awakened",false): return "玩偶正在嘲讽，单体攻击必须选择玩偶。"
 return ""

static func damage(g, doll: Dictionary, dealt: float, damage_type: String, label: String, details: Dictionary) -> bool:
 if not doll.has("puppet_owner"): return false
 var master=g._enemy(doll.puppet_owner)
 if master.is_empty() or master.gone: return false
 if dealt<=0: return true
 var absorbed=minf(dealt,maxf(0,doll.hp-1))
 var transfer=dealt-absorbed
 doll.hp-=absorbed
 var record={"damage":dealt,"damage_type":damage_type,"enemy":doll.id,"puppet_damage":{"absorbed":absorbed,"transferred":transfer,"owner":master.id}}
 record.merge(details)
 g._emit("mechanical","%s命中%s，承受%s伤害，剩余%s；%s点溢出伤害转给%s。" % [label,doll.name,g.number(dealt),g.number(doll.hp),g.number(transfer),master.name],record)
 if doll.puppet_awakened: g._enemy_operation(doll,ordinary(g,doll))
 if details.get("attack",false):
  var prepared=doll.puppet_prepared.values().duplicate(true)
  doll.puppet_prepared.clear()
  for request in prepared:
   g._emit("event","玩偶的"+prepared_name(g,request)+"被触发。")
   g._enemy_operation(doll,request)
 # The transferred amount has already been calculated: no second damage multiplier.
 if transfer>0: g._damage_enemy(master,transfer,"fixed","玩偶转移",{"puppet_transfer":doll.id})
 return true

static func dismiss(g, master: Dictionary) -> void:
 for doll in g.state.enemies:
  if doll.gone or doll.get("puppet_owner","")!=master.id: continue
  doll.gone=true;doll.hp=0;doll.intent={};doll.puppet_awakened=false;doll.puppet_prepared.clear()
  g._emit("event",master.name+"倒下，失去操纵的玩偶也随之散落。",{"puppet_dismissed":doll.id})

static func description(g, doll: Dictionary) -> String:
 var text="生命不会低于1，溢出伤害全额转给玩偶师。"
 if doll.get("puppet_awakened",false): text+="单体攻击必须选择玩偶；每次受伤施加一件中级2档拘束具，多段逐段触发。"
 for prepared in doll.get("puppet_prepared",{}).values(): text+="下一次攻击额外施加"+prepared_name(g,prepared)+"。"
 return text

static func validate(g, enemies: Array, health_scale: float=1.0) -> String:
 var owners=[]
 for doll in enemies:
  var is_doll=g.Enemies.TYPES[doll.type].behavior=="puppet"
  if not is_doll:
   for key in ["puppet_owner","puppet_awakened","puppet_prepared","puppet_mends"]:
    if doll.has(key): return "该敌人不应保存玩偶记录。"
   continue
  if not g.Snapshot.fields(doll,"puppet_owner:s puppet_awakened:b puppet_prepared:d puppet_mends:i"): return "玩偶记录不完整。"
  var masters=enemies.filter(func(e):return e.id==doll.puppet_owner and g.Enemies.TYPES[e.type].behavior=="puppeteer")
  if masters.size()!=1 or doll.puppet_owner in owners: return "玩偶的操纵者或召唤数量不正确。"
  owners.append(doll.puppet_owner)
  var bonus=doll.get("puppet_security_bonus",0.0)
  if not (bonus is float or bonus is int) or not is_finite(float(bonus)) or bonus<0 or bonus>120: return "玩偶的安全等级生命加成不正确。"
  if doll.puppet_mends<0 or doll.max_hp!=10*health_scale+bonus+5*doll.puppet_mends: return "玩偶的缝补生命上限不正确。"
  if not doll.gone and (masters[0].gone or doll.hp<1): return "玩偶的保护或操纵者状态不正确。"
  if doll.gone and (doll.puppet_awakened or not doll.puppet_prepared.is_empty()): return "离场玩偶不能保留生效装束。"
  for pool in doll.puppet_prepared:
   var p=doll.puppet_prepared[pool]
   if pool not in ["special","composite"] or not g.Snapshot.intent(p,g) or p.kind!="apply" or p.pool!=pool or p.grade!=2 or p.tier!=(3 if pool=="special" else 2) or p.count!=1 or not p.get("replace",false) or p.templates.size()!=1: return "玩偶准备的装备规格不正确。"
   if pool=="special" and p.templates[0] not in g.Enemies.TYPES[masters[0].type].special_pool: return "玩偶准备的特殊装备不在中级池中。"
   if pool=="composite" and (not p.templates[0] is Dictionary or p.templates[0] not in g.EquipmentOffers.assembly_specs()): return "玩偶准备的复合装备不存在。"
 return ""
