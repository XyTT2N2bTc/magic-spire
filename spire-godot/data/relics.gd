extends RefCounted

const MODIFIER_LIMITS={"battle_turn_reserve":10,"battle_opening_focus":10,"reward_card_options":1,"elite_entry_mana":100,"boss_entry_mana":100,"prison_entry_mana":100,"pickup_mana_full":1,"pressure_reduction_percent":100,"max_energy":10,"keep_hand":1,"turn_end_pressure_loss":100,"turn_start_pressure":100,"combat_retention_layers":10,"unspent_turn_mana":100,"pressure_guard_turns":10,"unrestricted_items":1,"shop_flask_mana":100,"capacity":10,"battle_mana":100,"low_mana_end_restore":100,"restraint_mana":100,"preparation_turns":10,"strength":10,"dexterity":10,"leg_dexterity":10,"opening_draw":10,"opening_energy":10,"opening_charge":10,"turn_draw":10,"opening_mana":100,"retain_energy":1,"pickup_mana_max":100,"pickup_mana":100,"mana_energy_step":100,"turn_energy_step":100,"single_hand_cast":1,"soften_locked_strain":1,"always_wall":1}

const RARITIES={"common":"普通","uncommon":"罕见","rare":"稀有","boss":"Boss","special":"特殊"}
const BOSS_POOL=["gourd_flask","tattoo_sticker","cursed_blindfold","nesting_doll","binding_pyramid","shining_lamp","cursed_plate_lock"]
const FALLBACK="rolling_log"

static var TYPES={
 "witch_amulet":{"rarity":"special","character_id":"witch","name":"魔女护符","detail":"战斗中每回合开始时，获得1层魔力预备。","modifiers":{"battle_turn_reserve":1}},
 "witch_noodles":{"rarity":"common","character_id":"witch","name":"辣椒炒肉拌面","detail":"战斗开始时，获得2层精神集中。","modifiers":{"battle_opening_focus":2}},
 "gourd_flask":{"rarity":"boss","name":"葫芦酒壶","detail":"拾取时，将一张「般若汤-其一」加入卡组。","modifiers":{},"pickup_cards":["hannya_1"]},
 "shrimp_paste":{"rarity":"uncommon","name":"虾滑","detail":"拾起时，魔力上限＋12，恢复12魔力。","modifiers":{"pickup_mana_max":12,"pickup_mana":12}},
 "magnifying_glass":{"rarity":"rare","name":"放大镜","detail":"选择奖励牌时，可供选择的牌增加1张。拾起时，同一窗口中已生成的奖励牌不受影响。","modifiers":{"reward_card_options":1}},
 "axe_amulet":{"rarity":"uncommon","name":"斧护符","detail":"进入精英房、Boss房或监狱时，恢复20魔力。","modifiers":{"elite_entry_mana":20,"boss_entry_mana":20,"prison_entry_mana":20}},
 "oune_hand":{"rarity":"uncommon","name":"欧内的手","detail":"拾取时，将1张没有“消耗”的「魔术手」加入卡组。","modifiers":{},"pickup_cards":["magic_hand_gift"]},
 "m_donalds":{"rarity":"uncommon","name":"M当劳","detail":"商店限定，仅可用魔瓶购买。拾取时，魔力上限＋10，并回满自身魔力。","shop_only":true,"shop_payment":"flask","modifiers":{"pickup_mana_max":10,"pickup_mana_full":1}},
 "tattoo_sticker":{"rarity":"boss","name":"纹身贴","detail":"最大能量＋1。拾取时，将2张「淫纹」加入卡组。","modifiers":{"max_energy":1}},
 "cursed_blindfold":{"rarity":"boss","name":"诅咒眼罩","detail":"最大能量＋1。拾起时，佩戴一件不可取下的眼罩。","modifiers":{"max_energy":1}},
 "cursed_plate_lock":{"rarity":"boss","name":"诅咒平板锁","detail":"能量上限＋1。拾取时，强制佩戴紧度3档的高级平板锁；跳蛋每场只在前6回合生效，高潮后快感保留系数最高10。击败下一个Boss获得专属钥匙，自动解锁并取下整件；此前无法解除。","modifiers":{"max_energy":1}},
 "nesting_doll":{"rarity":"boss","name":"套娃","detail":"拾取时，随机出现普通、罕见、稀有遗物各1件，可分别领取或跳过。","modifiers":{}},
 "binding_pyramid":{"rarity":"boss","name":"缚纹金字塔","detail":"回合结束时，不再丢弃手牌。","modifiers":{"keep_hand":1}},
 "shining_lamp":{"rarity":"boss","name":"闪耀的灯球","detail":"最大能量＋1。拾取时，魔力上限－50。","modifiers":{"max_energy":1}},
 "ice_heart":{"rarity":"common","name":"冰心诀","detail":"回合结束时，快感－3。","modifiers":{"turn_end_pressure_loss":3}},
 "magic_blood":{"rarity":"rare","name":"魔血","detail":"力量＋3。回合开始时，快感＋5。","modifiers":{"strength":3,"turn_start_pressure":5}},
 "turtle_shell":{"rarity":"rare","name":"乌龟壳","detail":"能量、蓄力、临时魔力的跨战斗保留上限各增加2层：额外能量最多3点、蓄力最多4层、临时魔力最多30点。","modifiers":{"combat_retention_layers":2}},
 "olihakimi":{"rarity":"uncommon","name":"奥利哈基米","detail":"回合结束时，若本回合未消耗魔力，恢复8魔力。","modifiers":{"unspent_turn_mana":8}},
 "green_bird":{"rarity":"rare","name":"绿色小鸟","detail":"每场战斗前6回合，快感不会超过当前快感上限－1。","modifiers":{"pressure_guard_turns":6}},
 "braised_eggplant":{"rarity":"rare","name":"红烧鱼香茄子","detail":"拾取时，魔力上限＋20，恢复20魔力。","modifiers":{"pickup_mana_max":20,"pickup_mana":20}},
 "tentacle_friend":{"rarity":"rare","name":"触手朋友","detail":"使用道具不受身体、姿势和触及限制。切割、尖锐类工具随身即可视为已固定，对全身生效。药剂仍受口部影响；次数、材料与有效目标要求不变。","modifiers":{"unrestricted_items":1}},
 "spicy_rice_noodles":{"rarity":"common","name":"爆炒麻辣米线","detail":"战斗开始时，获得2层蓄力。","modifiers":{"opening_charge":2}},
 "flyer":{"rarity":"common","name":"传单","detail":"进入商店时，魔瓶补充20点魔力。","modifiers":{"shop_flask_mana":20}},
 "kings_gift_revised":{"rarity":"rare","name":"成王之礼精装修订重置版","detail":"每场战斗第7回合结束时，对所有敌人造成77点固定伤害。","modifiers":{},"trigger":{"event":"turn_end","scope":"battle","phase":"battle","round":7,"op":"fixed_enemy_damage","amount":77}},
 "rolling_log":{"rarity":"special","name":"滚木","detail":"没有效果。","modifiers":{},"collectible":true},
 "marble":{"rarity":"uncommon","name":"西兰花","detail":"战后整备或牢房探索结束时，若魔力不超过上限的50%，恢复20魔力。休息结束不触发。","modifiers":{"low_mana_end_restore":20}},
 "marble_stone":{"rarity":"rare","name":"大理石","detail":"所有来源的快感增长×0.6。","modifiers":{"pressure_reduction_percent":40}},
 "graduate_certificate":{"rarity":"uncommon","name":"优秀学员毕业证书","detail":"「用力！」和「顾涌！」的卡面基础伤害＋4。","modifiers":{},"card_base_bonuses":{"strain":4,"slip":4}},
 "little_pig":{"rarity":"rare","name":"一只小猪","detail":"始终视为贴墙。操作环境工具仍需靠近。","modifiers":{"always_wall":1}},
 "small_gem":{"rarity":"common","name":"小宝石","detail":"战斗第1回合，额外获得1能量。","modifiers":{"opening_energy":1}},
 "desire_cube":{"rarity":"rare","name":"欲望魔方","detail":"每被施加一件拘束具，恢复5魔力。复合装备整件计1次。","modifiers":{"restraint_mana":5}},
 "happy_fa":{"rarity":"uncommon","name":"开心小fa","detail":"每累计3个玩家回合，获得1能量。进度跨战斗保留。","modifiers":{"turn_energy_step":3}},
 "casting_manual":{"rarity":"rare","name":"施法动作教程","detail":"只需一只手的手掌和手指自由，即可满足手部施法条件。","modifiers":{"single_hand_cast":1}},
 "enchanters_needle_case":{"rarity":"rare","name":"魅纹师的针匣","detail":"每回合开始时，额外抽1张牌。","modifiers":{"turn_draw":1}},
 "softened_buckle":{"rarity":"rare","name":"软化扣环","detail":"上锁拘束具的挣扎伤害倍率提高至×0.75。","modifiers":{"soften_locked_strain":1}},
 "mana_earring":{"rarity":"rare","name":"魔力耳坠","detail":"每场战斗中，每累计消耗20魔力，获得1能量。","modifiers":{"mana_energy_step":20}},
 "ready_backpack":{"rarity":"common","name":"准备背包","detail":"战斗第1回合，额外抽2张牌。","modifiers":{"opening_draw":2}},
 "smooth_stockings":{"rarity":"uncommon","name":"光滑的丝袜","detail":"腿部、脚踝及足部灵巧＋2。","modifiers":{"leg_dexterity":2}},
 "donut":{"rarity":"rare","name":"甜甜圈","detail":"未使用的能量保留到下一回合。","modifiers":{"retain_energy":1}},
 "small_sigil":{"rarity":"common","name":"小刻印","detail":"战斗开始时，恢复5魔力。","modifiers":{"opening_mana":5}},
 "martial_book":{"rarity":"common","name":"体术书","detail":"力量＋1。","modifiers":{"strength":1}},
 "strawberry":{"rarity":"common","name":"草莓","detail":"拾取时，魔力上限＋6，恢复6魔力。","modifiers":{"pickup_mana_max":6,"pickup_mana":6}},
 "break_bracer":{"rarity":"uncommon","trigger":{"event":"strain_destroyed","scope":"turn","op":"charge","amount":1},"name":"断缚护腕","detail":"挣扎直接使一个目标归零后，行动结束获得1层蓄力；每玩家回合1次，连带移除不算。","modifiers":{}},
 "silk_ring":{"rarity":"uncommon","trigger":{"event":"card_slipped","scope":"turn","op":"draw","amount":1},"name":"游丝指环","detail":"每回合首次通过卡牌滑脱使拘束具降档或解除，行动结束抽1张牌。","modifiers":{}},
 "turn_ribbon":{"rarity":"common","trigger":{"event":"fell","scope":"turn","phase":"battle","op":"posture_discount","from":"lie","to":"sit","amount":1},"name":"回身缎带","detail":"战斗中并腿踢击后躺下时，本回合下一次躺→坐少花1能量，最低0；每玩家回合1次。","modifiers":{}},
 "ember_crystal":{"rarity":"rare","trigger":{"event":"paid_cast","scope":"turn","op":"guarantee","amount":1},"name":"余烬晶石","detail":"每回合首次耗魔施法必定成功。","modifiers":{}},
 "ember":{"rarity":"common","name":"余烬护符","detail":"战后整备结束时，恢复10魔力。休息结束不触发。","modifiers":{"battle_mana":10.0}},
 "toolbox":{"rarity":"common","name":"折叠工具匣","detail":"随身道具容量＋1。","modifiers":{"capacity":1}},
 "hourglass":{"rarity":"uncommon","name":"整备沙漏","detail":"战后整备延长1回合。","modifiers":{"preparation_turns":1}}}
static var REWARDS=["witch_noodles","shrimp_paste","magnifying_glass","axe_amulet","oune_hand","marble_stone","ice_heart","magic_blood","turtle_shell","olihakimi","green_bird","braised_eggplant","tentacle_friend","spicy_rice_noodles","flyer","kings_gift_revised","marble","graduate_certificate","little_pig","small_gem","desire_cube","happy_fa","casting_manual","mana_earring","ready_backpack","smooth_stockings","donut","small_sigil","martial_book","strawberry","toolbox","hourglass","break_bracer","silk_ring","turn_ribbon","ember_crystal"]

static func trigger(id: String) -> Dictionary:
 return TYPES[id].get("trigger",{})

static func can_gain(ids: Array, id: String) -> bool:
 return id not in ids or TYPES[id].get("collectible",false)

static func shop_pool() -> Array:
 return REWARDS+TYPES.keys().filter(func(id):return TYPES[id].get("shop_only",false) and id not in REWARDS)

static func is_reward(id: String, source: String="normal") -> bool:
 return id==FALLBACK or id in (shop_pool() if source=="shop" else REWARDS) or id in BOSS_POOL

static func shop_reason(spec: Dictionary) -> String:
 if not spec.get("shop_only",false) is bool: return "商店限定标记必须为布尔值。"
 if spec.get("shop_only",false) and spec.rarity not in ["common","uncommon","rare"]: return "商店限定遗物需要普通、罕见或稀有品质。"
 if spec.has("shop_payment") and (not spec.get("shop_only",false) or spec.shop_payment not in ["self","flask"]): return "指定付款来源需要商店限定遗物及有效来源。"
 return ""

static func collectible_reason(spec: Dictionary) -> String:
 if not spec.get("collectible",false) is bool: return "收藏遗物标记必须为布尔值。"
 if not spec.get("collectible",false): return ""
 if spec.rarity!="special" or not spec.modifiers.is_empty() or spec.has("trigger") or spec.has("card_base_bonuses"): return "可重复收藏的特殊遗物不能附带效果。"
 return ""

static func card_base_bonus(ids: Array, type: String) -> float:
 var total=0.0
 for id in ids: total+=TYPES[id].get("card_base_bonuses",{}).get(type,0.0)
 return total

static func card_bonuses_reason(bonuses, cards: Dictionary) -> String:
 if not bonuses is Dictionary or bonuses.is_empty(): return "卡牌基础加成需要至少一个卡牌与数值。"
 for type in bonuses:
  if not cards.has(type) or not cards[type].has("base"): return "卡牌基础加成需要具有基础伤害的卡牌。"
  var amount=bonuses[type]
  if not (amount is int or amount is float): return "卡牌基础加成必须为1—100整数。"
  if not is_finite(float(amount)) or amount<1 or amount>100 or floorf(amount)!=amount: return "卡牌基础加成必须为1—100整数。"
 return ""

static func trigger_reason(spec) -> String:
 if not spec is Dictionary or spec.is_empty(): return "遗物触发配置不能为空。"
 for key in spec:
  if key not in ["event","scope","phase","op","amount","ratio","from_tier","to_tier","from","to","round"]: return "未知遗物触发字段。"
 if spec.get("event","") not in ["strain_destroyed","card_slipped","magic_paid","fell","turn_end","paid_cast"] or spec.get("scope","") not in ["turn","battle"]: return "遗物触发事件或周期不正确。"
 if spec.has("phase") and spec.phase not in ["battle","prepare","rest","prison"]: return "遗物触发阶段不正确。"
 if spec.get("op","") not in ["charge","draw","mana","posture_discount","fixed_enemy_damage","guarantee"]: return "遗物触发效果不正确。"
 if (spec.op=="guarantee" or spec.event=="paid_cast") and (spec.op!="guarantee" or spec.event!="paid_cast" or spec.scope!="turn" or spec.get("amount",0)!=1): return "必定施法需要每回合首次耗魔施法触发。"
 if spec.has("round") and (spec.event!="turn_end" or not spec.round is int or spec.round<1 or spec.round>100): return "指定回合需要回合结束触发和1—100整数。"
 if spec.op=="fixed_enemy_damage" and (spec.event!="turn_end" or spec.scope!="battle" or spec.get("phase","")!="battle" or not spec.has("round")): return "全体固定伤害需要指定战斗回合结束，每场一次。"
 if spec.op=="mana":
  if spec.event!="magic_paid" or spec.has("amount") or not (spec.get("ratio") is int or spec.get("ratio") is float): return "魔力返还需要支付事件和返还比例。"
  if not is_finite(float(spec.ratio)) or spec.ratio<=0 or spec.ratio>1: return "魔力返还比例必须大于0且不超过1。"
 elif not spec.get("amount") is int or spec.amount<1 or spec.has("ratio"): return "遗物效果数量必须为正整数。"
 for key in ["from_tier","to_tier"]:
  if spec.has(key) and (spec.event!="card_slipped" or not spec[key] is int or spec[key] not in [1,2,3]): return "滑脱档位条件不正确。"
 if spec.op=="posture_discount":
  if spec.event!="fell" or spec.scope!="turn" or spec.get("from","") not in ["stand","sit","lie"] or spec.get("to","") not in ["stand","sit","lie"]: return "姿态减免配置不正确。"
 elif spec.has("from") or spec.has("to"): return "只有姿态减免支持起止姿态。"
 return ""

static func value(ids: Array, hook: String) -> float:
 var total=0.0
 for id in ids: total+=TYPES[id].modifiers.get(hook,0.0)
 return total

static func view(ids: Array) -> Array:
 return ids.map(func(id):return {"id":id,"name":TYPES[id].name,"detail":TYPES[id].detail,"rarity":TYPES[id].rarity,"rarity_name":RARITIES[TYPES[id].rarity]})

static func pickup_cards_reason(cards, specs: Dictionary) -> String:
 if not cards is Array or cards.is_empty() or cards.size()>10: return "拾取赠牌需要1—10张卡牌。"
 for type in cards:
  if not type is String or not specs.has(type) or specs[type].get("card_type","")=="status": return "拾取赠牌需要有效的永久卡牌。"
 return ""
