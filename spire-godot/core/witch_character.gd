extends RefCounted

# Character-local definitions are registered under distinct ids. Original specs,
# buffs and reward arrays are never rewritten when selecting a character.
const ID="witch"
const PARTS=["hand","mouth","legs","mind"]
const NAMES={"hand":"手部","mouth":"嘴部","legs":"腿部","mind":"精神"}
const CHANGED=["strain","magic_hand","magic_hand_gift","magic_slip","siphon","ready_to_strike","mana_search","mana_invocation","mana_surge","adaptability","mana_conversion","focus","mana_circuit","pleasure_conversion"]
const REMOVED=["leverage","crossed_legs","repeated_strain","embers","rekindle","fire_control","strong_elbow","brace","echo_cast","wildfire_descent","flame_flourish","unlock","tear","chain","infusion","fire_dynamics","fire_mastery","double_unlock"]
const STARTER=["slip","slip","slip","slip","witch_strain","witch_strain","witch_strain","witch_magic_hand","witch_key","witch_preparation","witch_accumulation"]
static var registered=false

static func active(g) -> bool:
 return g.state.get("character_id","original")==ID

static func initialize(g) -> void:
 g.state.character_id=ID
 g.state.witch_charges={"hand":0,"mouth":0,"legs":0,"mind":0}
 g.state.witch_focus=0

static func register(g) -> void:
 if registered: return
 registered=true
 var rules=g.Cards.Rules
 rules.CAST_PART_NAMES["mind"]="精神"
 rules.CAST_PART_NAMES["legs"]="腿部"
 for part in PARTS:
  rules.FIXED_MAGIC["witch_"+part]={"parts":[part],"multiplier":1.0}
 for original in CHANGED:
  var id="witch_"+original
  var spec=rules.SPECS[original].duplicate(true)
  spec.character_id=ID;spec.art_type=original;spec.encyclopedia_hidden=true
  if spec.has("self_faces"):
   for side in ["bound","free"]:
    var face=spec.self_faces[side]
    if face.has("buff"):
     var buff_id="witch_"+face.buff
     if not rules.BUFFS.has(buff_id): rules.BUFFS[buff_id]=rules.BUFFS[face.buff].duplicate(true)
     face.buff=buff_id
  rules.SPECS[id]=spec
  g.B.CARD_NAMES[id]=g.B.CARD_NAMES[original]
  g.B.CARD_INFO[id]=g.B.CARD_INFO[original].duplicate(true)
  if g.B.CARD_TRAITS.has(original): g.B.CARD_TRAITS[id]=g.B.CARD_TRAITS[original].duplicate(true)
 var s=rules.SPECS
 s.witch_strain.free_effects=[{"op":"witch_focus","amount":1}]
 for id in ["witch_magic_hand","witch_magic_hand_gift"]:
  s[id].free_effects=[{"op":"buff","buff":"witch_hand_freedom"}]
 rules.BUFFS.witch_hand_freedom={"name":"魔术手","duration":"battle","attack_uses":2,"stack_uses":true,"witch_hand":true,"detail":"下2次手部基础动作忽略拘束条件。每次完整动作消耗1次，次数可累计；仍判定施法成功率。"}
 s.witch_magic_slip.free_effects[0].amount=2
 s.witch_siphon.self_faces.bound.mana_gain=10.0
 s.witch_ready_to_strike.self_faces.bound.effects=[{"op":"witch_focus","amount":3}]
 rules.BUFFS.witch_ready_to_strike_free={"name":"蓄势待发","duration":"battle","attack_uses":1,"witch_discount":2,"detail":"下次基础动作费用－2，最低0。"}
 s.witch_mana_search.cost=0;s.witch_mana_search.card_type="magic"
 s.witch_mana_search.casting={"parts":["mind"],"multiplier":1.0}
 for face in s.witch_mana_search.self_faces.values(): face.cast=true;face.mana_cost=5.0
 g.B.CARD_TRAITS.witch_mana_search={"exhaust":true}
 for face in s.witch_mana_invocation.self_faces.values(): face.effects=[{"op":"reserve_mana","amount":2}]
 s.witch_mana_surge.self_faces.bound.effects=[{"op":"witch_focus","amount":2}]
 rules.BUFFS.witch_adaptability_bound.turn_start_effects=[{"op":"witch_focus","amount":1}]
 rules.BUFFS.witch_adaptability_bound.detail="回合开始时，精神集中1。可叠加。"
 rules.BUFFS.witch_adaptability_free.turn_start_effects=[{"op":"reserve_mana","amount":2}]
 rules.BUFFS.witch_adaptability_free.detail="回合开始时，获得2层魔力预备。可叠加。"
 s.witch_mana_conversion.self_faces.bound.mana_cost=20.0
 s.witch_mana_conversion.self_faces.bound.energy_gain=2
 s.witch_mana_conversion.self_faces.free.mana_gain=20.0
 s.witch_focus.self_faces.bound.effects[0]={"op":"witch_focus","amount":1}
 rules.BUFFS.witch_mana_circuit_bound.mana_spent.effects=[{"op":"witch_focus","amount":1}]
 rules.BUFFS.witch_mana_circuit_bound.detail="每累计消耗20魔力，精神集中1。计入临时魔力，可叠加。"
 for face in s.witch_pleasure_conversion.self_faces.values(): face.pressure_energy=15
 _basic(g,"witch_key","魔法钥匙",{"card_type":"magic","cost":1,"mode":"unlock","cast_free":true,"free_mana_cost":0.0,"mana_cost":0.0,"casting":{"parts":["mind"],"multiplier":1.0},"free_effects":[{"op":"reserve_mana","amount":4}]},["魔法","开锁1。","{free_effects}",""],"unlock")
 _basic(g,"witch_preparation","施法预备",{"card_type":"magic","cost":1,"mode":"self","casting":{"parts":["mind"],"multiplier":1.0},"self_faces":{"bound":{"cast":true,"mana_cost":20.0,"effects":[{"op":"reserve_mana","amount":4},{"op":"witch_focus","amount":2}]},"free":{"cast":true,"mana_cost":20.0,"effects":[{"op":"reserve_mana","amount":4},{"op":"witch_focus","amount":2}]}}},["魔法","{effects}","{effects}",""],"prepared_chant")
 rules.BUFFS.witch_accumulation={"name":"魔力积蓄","duration":"battle","stackable":true,"witch_mana_damage":0.01,"detail":"每有1点自身魔力，造成的伤害提高1%。不计临时魔力，可叠加。"}
 _basic(g,"witch_accumulation","魔力积蓄",{"card_type":"power","cost":3,"mode":"power","self_faces":{"bound":{"buff":"witch_accumulation"},"free":{"buff":"witch_accumulation"}}},["能力","{buff}","{buff}",""],"mana_circuit")
 # Text stays character-local as well as the execution data.
 for id in ["witch_adaptability","witch_mana_circuit"]:
  g.B.CARD_INFO[id][1]="{bound_buff}";g.B.CARD_INFO[id][2]="{self_free_buff}"
 g.B.CARD_INFO.witch_strain[2]="{free_effects}"
 g.B.CARD_INFO.witch_mana_search=["魔法","{bound_effects}","{self_free_effects}",""]
 g.B.CARD_INFO.witch_mana_invocation=["魔法","{mana_gain}{bound_effects}","{mana_gain}{self_free_effects}",""]
 g.B.CARD_INFO.witch_pleasure_conversion=["技能","每15快感获得1能量。","每15快感获得1能量。",""]

static func _basic(g, id: String, name: String, spec: Dictionary, info: Array, art: String) -> void:
 info[1]=info[1].replace("{effects}","{bound_effects}").replace("{buff}","{bound_buff}")
 info[2]=info[2].replace("{effects}","{self_free_effects}").replace("{buff}","{self_free_buff}")
 spec.rarity="basic";spec.character_id=ID;spec.reward_excluded=true;spec.encyclopedia_hidden=true;spec.art_type=art
 g.Cards.Rules.SPECS[id]=spec;g.B.CARD_NAMES[id]=name;g.B.CARD_INFO[id]=info

static func card_id(g, type: String) -> String:
 return "witch_"+type if active(g) and type in CHANGED else type

static func incompatible(g, value: Variant) -> bool:
 if value is Array:
  return value.any(func(v):return incompatible(g,v))
 if not value is Dictionary: return false
 if value.get("op","")=="charge": return true
 if value.has("attacks") or value.has("attack_filters") or value.has("replay") or value.has("spell") or value.has("requires_successful_spell") or value.has("refresh_spell") or value.has("spell_base_bonus"): return true
 if value.has("buff") and incompatible(g,g.Cards.Rules.BUFFS[value.buff]): return true
 return value.values().any(func(v):return incompatible(g,v))

static func allowed_card(g, type: String) -> bool:
 if not active(g): return not type.begins_with("witch_")
 var original=type.trim_prefix("witch_")
 if original in REMOVED or original.begins_with("hannya") or original=="good_soup": return false
 var resolved=card_id(g,type)
 return g.Cards.Rules.SPECS.has(resolved) and not incompatible(g,g.Cards.Rules.SPECS[resolved])

static func pool(g, types: Array) -> Array:
 if not active(g): return types
 var result=[]
 for type in types:
  var id=card_id(g,type)
  if allowed_card(g,id) and id not in result: result.append(id)
 return result

static func has_slot(g, slot: String) -> bool:
 return not active(g) or not slot.begins_with("special_2")

static func profile(g, part: String) -> Dictionary:
 if part=="hand" and g.state.card_buffs.has("witch_hand_freedom"): return {"parts":["mind"],"multiplier":1.0}
 return {"parts":[part],"multiplier":g.B.BODY_DAMAGE[g.level("legs")] if part=="legs" else 1.0}

static func attack_candidates(g, out: Array) -> void:
 for enemy in g.state.enemies:
  if enemy.gone: continue
  for part in PARTS:
   var n=int(g.state.witch_charges[part])
   for form in [0,1]:
    var charge=form==0
    var cost=1 if charge or part!="mouth" else 2
    var mana=5.0 if charge or part!="mouth" else 10.0
    if part=="legs" and not charge: mana=0.0
    var reason=""
    if not charge and part=="legs" and n<4: reason="需要至少4层腿部蓄力，当前%d层。" % n
    var casting=g.cast_view(profile(g,part))
    if casting.reason!="": reason=casting.reason
    elif casting.chance<=0: reason="当前施法成功率为0%。"
    var all_targets=part=="mouth" and not charge
    if not charge and reason=="": reason=g.Puppets.taunt_reason(g,enemy,all_targets)
    var names={"hand":["火焰箭","烈焰箭","炎枪术"],"mouth":["吹雪","冰风","暴风雪"],"mind":["思维侵入","思维扰乱","思维破坏"],"legs":["魔女飞踹！","魔女飞踹！","魔女飞踹！"]}
    var label=NAMES[part]+("蓄力" if part=="legs" else "施法蓄力") if charge else names[part][2 if n>=4 else (1 if n>=2 else 0)]
    var hits=1 if part=="legs" else n+1
    var base={"hand":8.0,"mouth":6.0,"mind":6.0,"legs":1.0}[part]
    var focus=0 if charge or part=="legs" else g.state.witch_focus
    var damage=0.0 if charge else base+focus
    var discount=2 if g.state.card_buffs.has("witch_ready_to_strike_free") else 0
    var detail="获得1层%s蓄力。当前%d层。" % [NAMES[part],n] if charge else ("%s伤害%s×%d。消耗1层%s蓄力。" % ["全体" if all_targets else "",g.number(damage),hits,NAMES[part]])
    if part=="legs" and not charge: detail="伤害1，打断。消耗1层腿部蓄力。"
    if focus>0: detail+="本次各段魔法伤害＋%d，消耗全部精神集中。" % focus
    var p={"kind":"attack","type":"witch_"+part,"part":part,"form":form,"charge_action":charge,"enemy":enemy.id,"all":all_targets,"hits":hits,"damage":damage,"damage_type":"physical" if part=="legs" else "magic","interrupt":part=="legs" and not charge,"fall":false,"witch_action":true}
    g._candidate(out,p,label,detail,maxi(0,cost-discount),g._mana_cost(mana),reason,"","attack")
    out.back().casting=casting
    out.back().brief="蓄力 %d → %d" % [n,n+1] if charge else ("全体 " if all_targets else "")+g.number(damage*damage_multiplier(g))+" × %d" % hits
    out.back().brief_tags="当前%d层" % n

static func consume_buff(g, id: String) -> void:
 if id not in g.state.card_buffs: return
 g.state.card_buff_uses[id]=int(g.state.card_buff_uses.get(id,1))-1
 if g.state.card_buff_uses[id]<=0:
  g.state.card_buffs.erase(id);g.state.card_buff_uses.erase(id)

static func execute(g, c: Dictionary) -> void:
 var p=c.payload
 # The casting profile is frozen in the candidate, before consuming modifiers.
 var success=g._cast_magic(c)
 consume_buff(g,"witch_ready_to_strike_free")
 if p.part=="hand": consume_buff(g,"witch_hand_freedom")
 if not success: return
 if p.charge_action:
  g.state.witch_charges[p.part]+=1
  g._emit("event","%s蓄力＋1，当前%d层。" % [NAMES[p.part],g.state.witch_charges[p.part]],{"witch_charge":{"part":p.part,"amount":1}})
  return
 g.state.witch_charges[p.part]=maxi(0,g.state.witch_charges[p.part]-1)
 if p.part!="legs": g.state.witch_focus=0
 var targets=g.state.enemies.filter(func(e):return not e.gone) if p.all else [g._enemy(p.enemy)]
 for hit in range(p.hits):
  for enemy in targets:
   if enemy.is_empty() or enemy.gone: continue
   g._damage_enemy(enemy,p.damage,p.damage_type,c.label,{"hit":hit+1,"hits":p.hits,"attack":true,"witch":true})
   if p.interrupt and not enemy.gone and not enemy.intent.is_empty() and not enemy.intent.get("delayed",false):
    enemy.intent.delayed=true
    g._emit("event",enemy.name+"的动作被打断。",{"interrupt":{"enemy":enemy.id,"cancelled":enemy.intent.get("cancel_on_interrupt",false)}})

static func damage_multiplier(g) -> float:
 if not active(g): return 1.0
 var stacks=0
 for card in g.state.powers:
  if card.type=="witch_accumulation": stacks+=int(card.get("power_stacks",1))
 return 1.0+g.state.mana*0.01*stacks

static func evade(g, requests: Array, source: String) -> bool:
 if not active(g): return false
 var parts=[]
 for request in requests:
  var slots=[request.get("slot","")]
  if request.get("kind","")=="assembly": slots=g.B.ARM_SLOTS if request.family=="glove" else g.B.LEG_SLOTS
  for slot in slots:
   var part="mouth" if slot=="mouth" else ("hand" if slot in g.B.ARM_SLOTS else ("legs" if slot in g.B.LEG_SLOTS else ""))
   if part!="" and part not in parts: parts.append(part)
 for part in parts:
  if g.state.witch_charges[part]>0:
   g.state.witch_charges[part]-=1
   g._emit("event","消耗1层%s蓄力，抵消这次拘束。" % NAMES[part],{"witch_evasion":{"part":part,"source":source}})
   return true
 return false

static func clear(g) -> void:
 if not active(g): return
 for part in PARTS: g.state.witch_charges[part]=0
 g.state.witch_focus=0

static func validate(g, s: Dictionary) -> String:
 if s.get("character_id","original") not in ["original",ID]: return "角色记录不正确。"
 if s.get("character_id","original")!=ID:
  if s.deck.any(func(card):return str(card.type).begins_with("witch_")): return "卡组中含有其他角色的专属卡牌。"
  return ""
 if not s.get("witch_charges") is Dictionary or s.witch_charges.size()!=4: return "部位蓄力记录不完整。"
 for part in PARTS:
  if not s.witch_charges.get(part) is int or s.witch_charges[part]<0: return "部位蓄力层数不正确。"
 if not s.get("witch_focus") is int or s.witch_focus<0: return "精神集中层数不正确。"
 if s.special_equipment.any(func(e):return g.SpecialEquipment.occupied_slots(e).any(func(slot):return slot.begins_with("special_2"))): return "该角色没有这件装备所需的身体部位。"
 return ""
