extends RefCounted

const TYPES={"skill":"技能","magic":"魔法","power":"能力","curse":"诅咒","status":"状态"}
const RARITIES={"basic":"基础","common":"普通","uncommon":"罕见","rare":"稀有","curse":"诅咒","status":"状态"}
const UPPER_BODY_SLOTS=["eyes","mouth","neck","shoulder","upper_arm","forearm","wrist","palm","fingers"]

# Mechanical card definitions. Display templates in balance.gd read these values.
static var BUFFS={
 "prepared_chant":{"name":"预备咏唱","duration":"turn","cast_minimum":1.0,"detail":"本回合施法成功率固定为100%。"},
 "reuse_free":{"name":"魔路精通·自由","duration":"battle","failure_conversion":{"temporary_only":true,"refund":0.0,"energy":1,"zero_cost_limit":2},"exclusive_group":"reuse","detail":"本次耗魔全部由临时魔力支付时，施法失败不返还魔力，改为获得1能量。0费牌每回合最多触发2次。两面互斥。唯一。"},
 "reuse_bound":{"name":"魔路精通·拘束","duration":"battle","min_levels":{"arms":2,"legs":2},"failure_conversion":{"refund":1.0,"energy":1,"zero_cost_limit":2,"unlimited_min_levels":{"arms":3,"legs":3}},"exclusive_group":"reuse","detail":"上身、腿部束缚等级均≥2时，施法失败返还100%耗魔并获得1能量；0费牌每回合最多触发2次。两者均≥3时取消该次数限制，条件实时检测。两面互斥。唯一。"},
 "resonance_bound":{"name":"共鸣·拘束","duration":"battle","worn_mana_reduction":0.05,"detail":"每佩戴一件拘束具，魔法耗魔降低5%，最低0。随当前件数变化；复合拘束算1件，连接绳不计。固定兑换与追加付款不减免。"},
 "resonance_free":{"name":"共鸣·自由","duration":"battle","stackable":true,"turn_start_effects":[{"op":"evasion","amount":1}],"detail":"回合开始时，获得1层闪避。可叠加。"},
 "practiced_free":{"name":"熟练而已·熟手","duration":"battle","card_cast_bonus":0.03,"detail":"每成功打出另一张牌，本回合施法成功率额外＋3个百分点。回合开始清零。唯一。"},
 "practiced_bound":{"name":"熟练而已·稳手","duration":"battle","cast_minimum":0.75,"magic_card_traction":1,"detail":"施法成功率最低75%；每次使用魔法牌，额外牵扯1次（按1能量），无论成败。唯一。"},
 "hannya_level_1":{"name":"般若汤","duration":"battle","hannya_level":1,"attributes":{"strength":1,"dexterity":1},"detail":"般若汤1级：力量＋1、灵巧＋1。各级奖励本场仅一次。"},
 "hannya_level_2":{"name":"般若汤","duration":"battle","hannya_level":2,"attributes":{"strength":2,"dexterity":2},"detail":"般若汤2级：力量＋2、灵巧＋2。各级奖励本场仅一次。"},
 "hannya_level_3":{"name":"般若汤","duration":"battle","hannya_level":3,"attributes":{"strength":3,"dexterity":3},"detail":"般若汤3级：力量＋3、灵巧＋3。各级奖励本场仅一次。"},
 "hannya_level_4":{"name":"般若汤","duration":"battle","hannya_level":4,"attributes":{"strength":4,"dexterity":4},"detail":"般若汤4级：力量＋4、灵巧＋4。各级奖励本场仅一次。"},
 "hannya_short_strike":{"name":"般若汤·短打","duration":"battle","hidden":true,"detail":"近身短打基础伤害＋2，连击每段基础伤害＋1。"},
 "hannya_justice":{"name":"般若汤·飞踢","duration":"battle","hidden":true,"detail":"正义飞踢费用＋1，获得打断，与坐姿踢击及并腿踢击共用3回合冷却。"},

 "magic_hand_free":{"name":"魔术手","duration":"battle","attacks":["strike","heavy"],"attack_uses":2,"stack_uses":true,"ignore_restraints":true,"detail":"接下来2次手部体术按自由态发动，忽略拘束限制与减益；包括肘击、近身短打及其连击。每次完整攻击消耗1次，姿势、费用与次数限制照常。每次使用增加2次，剩余次数可累计。"},
 "light_as_swallow_bound":{"name":"身轻如燕","duration":"battle","card_damage_type":"slip","damage_multiplier":2.0,"detail":"下一次卡牌滑脱伤害×2。"},
 "breath_control_free":{"name":"运气","duration":"next_attack","attacks":["strike","heavy","kick"],"energy_discount":1,"detail":"下一次体术费用－1，最低0。"},
 "restraint_embrace_free":{"name":"拘束之拥·自由","duration":"battle","stackable":true,"restraint_draw":{"event":"released","next_turn":false,"amount":1,"energy":1},"detail":"每挣脱1件拘束具，抽1张牌，恢复1能量。抽牌与回能均可叠加。"},
 "restraint_embrace_bound":{"name":"拘束之拥·拘束","duration":"battle","stackable":true,"restraint_draw":{"event":"worn","next_turn":true,"amount":1},"detail":"每被佩戴1件拘束具，下回合抽1张牌。可叠加。"},
 "infusion_free":{"name":"灌注·手部","duration":"next_attack","attacks":["strike","heavy"],"interrupt":true,"detail":"下一次手部体术附加1层打断，包括肘击和近身短打。不与自带打断叠加。"},
 "infusion_bound":{"name":"灌注·腿部","duration":"next_attack","attacks":["heavy","kick"],"interrupt":true,"detail":"下一次腿部体术附加1层打断，包括近身短打和各类踢击。不与自带打断叠加。"},
 "ready_to_strike_free":{"name":"蓄势待发","duration":"next_attack","attacks":["strike","heavy","kick"],"energy_discount":1,"detail":"下一次体术费用－1，最低0。"},
 "mana_circuit_free":{"name":"魔力回路·能量","duration":"battle","stackable":true,"mana_spent":{"step":30,"effects":[{"op":"energy","amount":1}]},"detail":"每累计消耗30魔力，恢复1能量。计入临时魔力。"},
 "mana_circuit_bound":{"name":"魔力回路·蓄力","duration":"battle","stackable":true,"mana_spent":{"step":20,"effects":[{"op":"charge","amount":1}]},"detail":"每累计消耗20魔力，获得1层蓄力。计入临时魔力。"},
 "echo_cast_bound":{"name":"余势复演·拘束","duration":"battle","stack_uses":true,"replay":{"kind":"card","distinct_faces":true},"detail":"下一张成功打出的拘束面牌，每层额外释放一次；双面效果相同的牌不适用。免费复放，只作用原目标，目标失效则跳过。"},
 "echo_cast_free":{"name":"余势复演·火球","duration":"battle","stack_uses":true,"replay":{"kind":"attack","spell":"fireball"},"detail":"下一次火球术每层免费额外施放一次，不占使用次数；只作用原目标，目标失效则跳过。每次施法各自判定成功率。"},
 "embers_free":{"name":"余火","duration":"turn","spell":"fireball","attack":"fireball","base_bonus":4.0,"detail":"本回合火球术基础伤害＋4。同源不叠加。"},
 "wildfire_descent":{"name":"猛火下山","duration":"battle","stackable":true,"spell":"fireball","spell_use_effects":[{"op":"draw","amount":1}],"detail":"本场每使用一次火球术，抽1张牌。可叠加。"},
 "adaptability_bound":{"name":"灵活变通·挣扎","duration":"battle","stackable":true,"turn_start_effects":[{"op":"charge","amount":1}],"detail":"每回合开始时，获得1层蓄力。可叠加。"},
 "adaptability_free":{"name":"灵活变通·自由","duration":"battle","stackable":true,"turn_start_effects":[{"op":"reserve_mana","amount":1}],"detail":"每回合开始时，获得5点临时魔力。可叠加。"},
 "fire_dynamics_bound":{"name":"火动力学·稳燃","duration":"battle","spell":"fireball","chance_bonus":0.30,"detail":"火球术施法成功率＋30%。"},
 "fire_dynamics_free":{"name":"火动力学·扩散","duration":"battle","spell":"fireball","all_enemies":true,"detail":"火球术对全体敌人造成伤害，每次施法只判定一次成功率。"},
 "letter_opener_bound":{"name":"开信刀play·挣扎","duration":"battle","stackable":true,"periodic":{"card_type":"skill","count":3,"target":"outer_equipment","damage_type":"strain","base":3.0},"detail":"每使用3张技能牌，对全部最外层拘束具造成3点挣扎伤害，只乘适用倍率。跨回合累计。可叠加。"},
 "letter_opener_free":{"name":"开信刀play·自由","duration":"battle","stackable":true,"periodic":{"card_type":"skill","count":3,"target":"enemies","damage_type":"physical","base":5.0},"detail":"每使用3张技能牌，对所有敌人造成5点伤害。跨回合累计。可叠加。"},
 "flame_flourish_bound":{"name":"炫火·自解","duration":"battle","spell":"fireball","equipment_damage_factor":0.5,"detail":"火球术可对选中的最外层拘束具使用，造成当前火球术一半的魔法伤害。与对敌人施法共用次数。"},
 "flame_flourish_free":{"name":"炫火·连发","duration":"battle","stackable":true,"spell":"fireball","extra_uses":1,"detail":"每回合火球术可用次数＋1。可叠加。"},
 "fire_mastery_bound":{"name":"火焰精通·无拘施法","duration":"battle","spell":"fireball","ignore_body":true,"disable_gesture":true,"detail":"火球术无视身体限制，不获得手势加成。"},
 "fire_mastery_free":{"name":"火焰精通·烈焰","duration":"battle","attack":"fireball","damage_multiplier":2.0,"detail":"火球术伤害×2。"},
 "strong_elbow_free":{"name":"强力肘击","duration":"next_attack","attack":"strike","damage_multiplier":2.0,"detail":"下一次完整肘击伤害×2，多段形态的每一击均生效。"},
 "binding_enthusiast":{"name":"紧缚爱好","duration":"battle","stackable":true,"worn_attributes":{"strength":1,"dexterity":1},"bound_card_pressure":10,"detail":"当前每佩戴1件拘束具或性玩具，力量与灵巧＋1；每成功打出1张拘束面牌，固定增加10快感。装备变化后立即重算。可叠加。"},
 "henshin_free":{"name":"henshin","duration":"battle","attack":"all","damage_multiplier":2.0,"detail":"自身造成的全部伤害×2，不可叠加；包括对拘束具与行动触发的被动伤害。"}}
const REWARD_RATES={"normal":{"rare":3,"uncommon":37},"elite":{"rare":10,"uncommon":40},"boss":{"rare":100,"uncommon":0}}
const RARE_OFFSET_INITIAL=-5
const RARE_OFFSET_MAX=40
const FOLLOW_THROUGH_REGIONS={"head":["eyes","mouth","neck"],"arms":["shoulder","upper_arm","forearm","wrist","palm","fingers"],"legs":["thigh","calf","ankle","foot","toes"]}
const FOLLOW_THROUGH_SLOTS=FOLLOW_THROUGH_REGIONS.head+FOLLOW_THROUGH_REGIONS.arms+FOLLOW_THROUGH_REGIONS.legs
const FOLLOW_THROUGH_TEXT="顺延：目标未解除时继续攻击原件；解除后，剩余段数依次转向同一指定部位、同一大部位的其他部位、同一大片区域的最外层拘束具。同一级有多个可选目标时随机选择，无目标则结束，不跨区域。"
const MAGIC_HAND={"card_type":"magic","rarity":"uncommon","cost":1,"mana_cost":20.0,"mode":"lower","hits":3,"follow_through":true,"follow_through_scope":"body","target_slots":FOLLOW_THROUGH_SLOTS,"cast_free":true,"casting":{"parts":["mouth"],"multiplier":1.0},"free_effects":[{"op":"buff","buff":"magic_hand_free"}]}
const HANNYA_MANA_GAIN=5.0
const HANNYA_REWARDS={
 1:{"free":"近身短打基础伤害＋2，连击每段基础伤害＋1。般若汤-其二加入弃牌堆。","bound":"正义飞踢费用＋1，获得打断，与坐姿踢击及并腿踢击共用3回合冷却。般若汤-其二加入弃牌堆。","discard":"hannya_2"},
 2:{"free":"0费消耗／虚无的身轻如燕加入手牌；般若汤-其三加入弃牌堆。","bound":"0费消耗／虚无的身轻如燕加入手牌；般若汤-其三加入弃牌堆。","hand":"hannya_swallow","discard":"hannya_3"},
 3:{"free":"0费消耗／虚无的灌注加入手牌；般若汤-其四加入弃牌堆。","bound":"0费消耗／虚无的灌注加入手牌；般若汤-其四加入弃牌堆。","hand":"hannya_infusion","discard":"hannya_4"},
 4:{"free":"虚无的完美henshin加入手牌；好汤喝够饮饮饮饮加入弃牌堆。","bound":"虚无的完美henshin加入手牌；好汤喝够饮饮饮饮加入弃牌堆。","hand":"hannya_henshin","discard":"good_soup"}}

static var SPECS=_with_hannya({
 "self_binding":{"card_type":"skill","rarity":"uncommon","cost":0,"x_cost":true,"mode":"self","self_binding":{"templates":["rope","cord","belt","fine_belt","tape","cable_tie"],"slots":FOLLOW_THROUGH_REGIONS.legs,"tighten_per_x":2,"mana_per_x":15},"self_faces":{"bound":{},"free":{}}},
 "prepared_chant":{"card_type":"magic","rarity":"common","cost":1,"mode":"self","casting":{"parts":["mouth"],"multiplier":1.0},"self_faces":{"bound":{"cast":true,"mana_cost":10.0,"buff":"prepared_chant"},"free":{"cast":true,"mana_cost":10.0,"buff":"prepared_chant"}}},
 "reuse":{"card_type":"power","rarity":"uncommon","cost":1,"mode":"power","self_faces":{"free":{"buff":"reuse_free"},"bound":{"energy_cost":1,"buff":"reuse_bound"}}},
 "confluence":{"card_type":"skill","rarity":"common","cost":0,"mode":"self","self_faces":{"bound":{"worn_resource":{"resource":"turn_strength","divisor":2}},"free":{"worn_resource":{"resource":"mana","divisor":1}}}},
 "resonance":{"card_type":"power","rarity":"uncommon","cost":1,"mode":"power","self_faces":{"bound":{"buff":"resonance_bound"},"free":{"buff":"resonance_free"}}},
 "practiced":{"card_type":"power","rarity":"rare","cost":2,"mode":"power","self_faces":{"bound":{"buff":"practiced_bound"},"free":{"buff":"practiced_free"}}},
 "siphon_strength":{"card_type":"magic","rarity":"rare","cost":1,"mode":"self","casting":{"parts":["hand"],"multiplier":1.0},"self_faces":{"bound":{"cast":true,"exhaust_hand_batch":{"exclude_type":"magic","effects":[{"op":"charge","amount":1}]}},"free":{"cast":true,"exhaust_hand_batch":{"include_type":"magic","mana_gain":10.0}}}},
 "shared_fate":{"card_type":"skill","rarity":"uncommon","cost":0,"mode":"self","self_faces":{"bound":{"balance_mana_pressure":true},"free":{"balance_mana_pressure":true}}},
 "magic_hand":MAGIC_HAND.duplicate(true),
 "magic_hand_gift":MAGIC_HAND.merged({"reward_excluded":true,"encyclopedia_hidden":true}).duplicate(true),
 "leverage":{"card_type":"skill","rarity":"common","cost":1,"mode":"strain","damage_type":"strain","base":0.0,"worn_damage":{"per_item":2,"include_special":false},"free_max_levels":{"arms":0},"free_effects":[{"op":"evasion","amount":1},{"op":"charge","amount":1}]},
 "light_as_swallow":{"card_type":"skill","rarity":"rare","cost":1,"mode":"self","free_max_levels":{"legs":0},"self_faces":{"bound":{"buff":"light_as_swallow_bound"},"free":{"effects":[{"op":"evasion","amount":2}]}}},
 "breath_control":{"card_type":"skill","rarity":"common","cost":2,"mode":"slip","damage_type":"slip","base":8.0,"hits":2,"exhaust_hand":true,"free_slots":["mouth"],"free_effects":[{"op":"charge","amount":1},{"op":"buff","buff":"breath_control_free"}]},
 "restraint_embrace":{"card_type":"power","rarity":"uncommon","cost":1,"mode":"power","self_faces":{"bound":{"buff":"restraint_embrace_bound"},"free":{"energy_cost":1,"buff":"restraint_embrace_free"}}},
 "infusion":{"card_type":"magic","rarity":"rare","cost":1,"mode":"self","casting":{"parts":["none"],"multiplier":1.0},"self_faces":{"bound":{"cast":true,"energy_cost":1,"mana_cost":10.0,"buff":"infusion_bound"},"free":{"cast":true,"mana_cost":20.0,"buff":"infusion_free"}}},
 "siphon":{"card_type":"magic","rarity":"common","cost":0,"mode":"self","casting":{"parts":["mouth"],"multiplier":1.0},"free_max_levels":{"legs":0},"self_faces":{"bound":{"mana_gain":5.0},"free":{"cast":true,"energy_cost":1,"mana_gain":10.0,"effects":[{"op":"draw","amount":2}]}}},
 "concentration":{"card_type":"skill","rarity":"uncommon","cost":1,"mode":"strain","damage_type":"strain","base":6,"bound_modes":["strain","slip"],"damage_growth":3},
 "mana_circuit":{"card_type":"power","rarity":"rare","cost":2,"mode":"power","free_max_levels":{"arms":0,"legs":0},"self_faces":{"bound":{"buff":"mana_circuit_bound"},"free":{"buff":"mana_circuit_free"}}},
 "ready_to_strike":{"card_type":"magic","rarity":"common","cost":1,"mode":"self","casting":{"parts":["mouth"],"multiplier":1.0},"self_faces":{"bound":{"cast":true,"mana_cost":10.0,"exhaust_hand":true,"effects":[{"op":"charge","amount":3}]},"free":{"cast":true,"mana_cost":10.0,"exhaust_hand":true,"buff":"ready_to_strike_free"}}},
 "crossed_legs":{"card_type":"skill","rarity":"common","cost":1,"mode":"slip","damage_type":"slip","base":8.0,"target_slots":FOLLOW_THROUGH_REGIONS.legs,"hit_effects":[{"op":"draw","amount":1}],"free_effects":[{"op":"draw","amount":1}],"free_energy_discount":1,"free_max_levels":{"legs":1}},
 "mana_search":{"card_type":"skill","rarity":"common","cost":1,"mode":"self","free_max_levels":{"arms":0},"self_faces":{"bound":{"effects":[{"op":"draw","amount":1,"filter":{"tag":"magic"}}]},"free":{"effects":[{"op":"draw","amount":2,"filter":{"tag":"magic"}}]}}},
 "pot_of_greed":{"card_type":"skill","rarity":"uncommon","cost":0,"mode":"self","self_faces":{"bound":{"effects":[{"op":"draw","amount":2}]},"free":{"effects":[{"op":"draw","amount":2}]}}},
 "repeated_strain":{"card_type":"skill","rarity":"common","cost":1,"mode":"strain","damage_type":"strain","base":1.0,"hits":5,"follow_through":true,"target_slots":FOLLOW_THROUGH_SLOTS,"free_effects":[{"op":"charge","amount":2}]},
 "echo_cast":{"card_type":"skill","rarity":"uncommon","cost":1,"mode":"self","self_faces":{"bound":{"buff":"echo_cast_bound"},"free":{"buff":"echo_cast_free"}}},
 "embers":{"card_type":"magic","rarity":"common","cost":0,"mode":"self","casting":{"parts":["hand"],"multiplier":1.0},"self_faces":{"bound":{"cast":true,"mana_cost":6.0,"requires_successful_spell":"fireball","effects":[{"op":"draw","amount":1}],"optional_draw":{"mana_cost":6.0,"count":1}},"free":{"cast":true,"mana_cost":6.0,"buff":"embers_free"}}},
 "wildfire_descent":{"card_type":"power","type_tags":["magic","power"],"rarity":"uncommon","cost":1,"mode":"power","casting":{"parts":["mouth"],"multiplier":1.0},"self_faces":{"bound":{"buff":"wildfire_descent","cast":true,"mana_cost":10.0},"free":{"buff":"wildfire_descent","cast":true,"mana_cost":10.0}}},
 "boar_emperor_blaze":{"card_type":"skill","rarity":"rare","cost":3,"mode":"strain","damage_type":"strain","base":6.0,"hits":5,"follow_through":true,"target_slots":FOLLOW_THROUGH_SLOTS,"free_effects":[{"op":"charge","amount":5}]},
 "adaptability":{"card_type":"power","rarity":"uncommon","cost":1,"mode":"power","self_faces":{"bound":{"buff":"adaptability_bound"},"free":{"buff":"adaptability_free"}}},
 "rekindle":{"card_type":"magic","rarity":"common","cost":1,"mode":"self","casting":{"parts":["hand"],"multiplier":1.0},"self_faces":{"bound":{"cast":true,"mana_cost":10.0,"refresh_spell":"fireball"},"free":{"cast":true,"mana_cost":10.0,"refresh_spell":"fireball"}}},
 "fire_dynamics":{"card_type":"power","rarity":"rare","cost":2,"bound_energy_discount":1,"mode":"power","self_faces":{"bound":{"buff":"fire_dynamics_bound"},"free":{"buff":"fire_dynamics_free"}}},
 "fire_control":{"card_type":"skill","rarity":"common","cost":1,"mode":"self","free_max_levels":{"arms":1},"self_faces":{"bound":{"effects":[{"op":"reserve_mana","amount":2}]},"free":{"requires_hand":true,"spell_base_bonus":{"spell":"fireball","amount":2}}}},
 "letter_opener":{"card_type":"power","rarity":"uncommon","cost":1,"mode":"power","self_faces":{"bound":{"buff":"letter_opener_bound"},"free":{"buff":"letter_opener_free"}}},
 "mana_invocation":{"card_type":"magic","rarity":"common","cost":1,"mode":"self","casting":{"parts":["none"],"multiplier":1.0},"self_faces":{"bound":{"cast":true,"mana_gain":20.0},"free":{"cast":true,"mana_gain":20.0}}},
 "strong_elbow":{"card_type":"skill","rarity":"common","cost":1,"mode":"strain","damage_type":"strain","base":8.0,"target_slots":["upper_arm","forearm"],"free_effects":[{"op":"buff","buff":"strong_elbow_free"}],"hit_effects":[{"op":"draw","amount":1}]},
 "pleasure_conversion":{"card_type":"skill","rarity":"rare","cost":0,"mode":"self","self_faces":{"bound":{"pressure_energy":20},"free":{"pressure_energy":20}}},
 "mana_conversion":{"card_type":"magic","rarity":"uncommon","cost":0,"mode":"self","casting":{"parts":["none"],"multiplier":1.0},"fixed_mana_cost":true,"self_faces":{"bound":{"cast":true,"mana_cost":10.0,"energy_gain":1},"free":{"cast":true,"energy_cost":1,"mana_gain":10.0}}},
 "mana_surge":{"card_type":"magic","rarity":"common","cost":0,"mode":"self","casting":{"parts":["none"],"multiplier":1.0},"self_faces":{"bound":{"cast":true,"mana_cost":5.0,"effects":[{"op":"charge","amount":2}]},"free":{"cast":true,"mana_cost":0.0,"effects":[{"op":"reserve_mana","amount":2}]}}},
 "henshin":{"play_music":"rain_love","card_type":"magic","rarity":"rare","cost":2,"mode":"self","casting":{"parts":["none"],"multiplier":1.0},"self_faces":{"bound":{"cast":true,"energy_cost":1,"mana_cost":40.0,"release_all":true},"free":{"cast":true,"energy_cost":2,"mana_cost":40.0,"buff":"henshin_free"}}},
 "flame_flourish":{"card_type":"power","rarity":"uncommon","cost":1,"mode":"power","self_faces":{"bound":{"buff":"flame_flourish_bound"},"free":{"buff":"flame_flourish_free"}}},
 "fire_mastery":{"card_type":"power","rarity":"rare","cost":2,"bound_energy_discount":1,"mode":"power","self_faces":{"bound":{"buff":"fire_mastery_bound"},"free":{"buff":"fire_mastery_free"}}},
 "binding_enthusiast":{"card_type":"power","rarity":"rare","cost":3,"mode":"power","self_faces":{"bound":{"buff":"binding_enthusiast"},"free":{"buff":"binding_enthusiast"}}},
 "strain":{"card_type":"skill","rarity":"basic","free_effects":[{"op":"charge","amount":1}],"cost":1,"mode":"strain","damage_type":"strain","base":6.0},
 "slip":{"card_type":"skill","rarity":"basic","free_effects":[{"op":"next_energy","amount":1}],"cost":1,"mode":"slip","damage_type":"slip","base":6.0},
 "brace":{"card_type":"skill","rarity":"common","free_effects":[{"op":"charge","amount":2}],"hit_effects":[{"op":"charge","amount":1}],"cost":1,"mode":"strain","damage_type":"strain","base":4.0},
 "inch":{"card_type":"skill","rarity":"common","free_effects":[{"op":"draw","amount":1},{"op":"retain","amount":1}],"lowered_effects":[{"op":"draw","amount":1}],"cost":1,"mode":"slip","damage_type":"slip","base":5.0},
 "ease":{"card_type":"magic","rarity":"basic","free_effects":[{"op":"reserve_mana","amount":2}],"cost":1,"mode":"lower","casting":{"parts":["mouth"],"multiplier":1.0}},
 "unlock":{"card_type":"magic","rarity":"uncommon","free_effects":[{"op":"reserve_mana","amount":2}],"cost":1,"bound_energy_discount":1,"mode":"unlock","casting":{"parts":["hand"],"multiplier":1.0}},
 "magic_slip":{"card_type":"magic","rarity":"basic","free_effects":[{"op":"reserve_mana","amount":1},{"op":"draw","amount":1}],"cost":0,"mode":"magic_slip","damage_type":"slip","base":5.0,"cast_free":true,"free_mana_cost":0.0,"casting":{"parts":["mouth"],"multiplier":1.0}},
 "focus":{"card_type":"skill","rarity":"uncommon","cost":1,"mode":"self","self_faces":{"bound":{"effects":[{"op":"charge","amount":1},{"op":"draw","amount":1}]},"free":{"effects":[{"op":"retain","amount":1,"draw_after":1}]}}},
 "tear":{"card_type":"skill","rarity":"uncommon","free_effects":[{"op":"charge","amount":1},{"op":"next_energy","amount":1}],"destroyed_effects":[{"op":"energy","amount":"refund"}],"cost":2,"mode":"strain","damage_type":"strain","base":9.0,"refund":1},
 "chain":{"card_type":"skill","rarity":"uncommon","free_effects":[{"op":"charge","amount":2},{"op":"draw","amount":2}],"cost":2,"mode":"strain","damage_type":"strain","base":4.0,"hits":3,"follow_through":true,"target_slots":FOLLOW_THROUGH_SLOTS},
 "peel":{"card_type":"skill","rarity":"uncommon","free_effects":[{"op":"next_energy","amount":1},{"op":"retain","all":true}],"cost":2,"mode":"slip","damage_type":"slip","base":4.0,"hits":3,"follow_through":true,"target_slots":FOLLOW_THROUGH_SLOTS},
 "double_unlock":{"reward_excluded":true,"encyclopedia_hidden":true,"card_type":"magic","rarity":"uncommon","free_effects":[{"op":"reserve_mana","amount":1}],"cost":1,"mode":"unlock","casting":{"parts":["hand","mouth"],"multiplier":1.0},"hits":2},
 "panic":{"card_type":"curse","rarity":"curse","cost":1,"mode":"none"},
 "sensitive":{"card_type":"curse","rarity":"curse","cost":0,"mode":"none","hand_modifiers":{"pleasure_multiplier":1.2}},
 "lewd_mark":{"card_type":"curse","rarity":"curse","cost":0,"mode":"none","hand_modifiers":{"energy_pressure":4.0}},
 "tease":{"card_type":"status","rarity":"status","cost":0,"mode":"none","end_turn_pressure":5.0},
 "tease_plus":{"card_type":"status","rarity":"status","cost":0,"mode":"none","end_turn_pressure":8.0}})
static func _with_hannya(specs: Dictionary) -> Dictionary:
 for stage in range(1,5):
  specs["hannya_%d" % stage]={"card_type":"skill","rarity":"rare","cost":1,"mode":"self","reward_excluded":true,"drinking":true,"hannya_stage":stage,"self_faces":{"bound":{},"free":{}}}
  specs["hannya_%d" % stage].encyclopedia_hidden=stage>1
 specs.hannya_2.play_music="mandarin_duck_play"
 specs.hannya_2.play_music_text="打出时自动播放鸳鸯戏。"
 specs.good_soup={"card_type":"skill","rarity":"rare","cost":1,"mode":"self","reward_excluded":true,"drinking":true,"self_faces":{"bound":{"mana_gain":10.0},"free":{"mana_gain":10.0}}}
 specs.good_soup.encyclopedia_hidden=true
 for pair in [["hannya_swallow","light_as_swallow"],["hannya_infusion","infusion"],["hannya_henshin","henshin"]]:
  var variant=specs[pair[1]].duplicate(true)
  variant.cost=0;variant.reward_excluded=true;variant.art_source=pair[1];variant.encyclopedia_hidden=true
  for side in variant.self_faces: variant.self_faces[side].erase("energy_cost")
  if pair[0]=="hannya_infusion":
   variant.self_faces.bound.mana_cost=10.0;variant.self_faces.free.mana_cost=10.0
  if pair[0]=="hannya_henshin":
   variant.self_faces.bound.mana_cost=20.0;variant.self_faces.free.mana_cost=20.0
   variant.self_faces.free.energy_cost=2
  specs[pair[0]]=variant
 return specs

static var FIXED_MAGIC={"fireball":{"parts":["mouth"],"multiplier":1.0}}
static var CAST_PART_NAMES={"mouth":"嘴部","hand":"手部","none":"无"}

static func cast_profile(type: String) -> Dictionary:
 return SPECS[type].get("casting",{}) if SPECS.has(type) else FIXED_MAGIC.get(type,{})

static func face_casts(type: String, free: bool) -> bool:
 var spec=SPECS[type]
 if spec.has("self_faces"): return spec.self_faces["free" if free else "bound"].get("cast",false)
 return spec.has("casting") and (not free or spec.get("cast_free",false))

static func face_mana_base(type: String, free: bool, spell_cost: float) -> float:
 var spec=SPECS[type]
 if spec.has("self_faces"): return float(spec.self_faces["free" if free else "bound"].get("mana_cost",0))
 if free and spec.has("free_mana_cost"): return float(spec.free_mana_cost)
 return float(spec.get("mana_cost",spell_cost)) if face_casts(type,free) else 0.0

const COMMON=["prepared_chant","confluence","leverage","breath_control","siphon","ready_to_strike","crossed_legs","mana_search","repeated_strain","embers","brace","inch","strong_elbow","mana_surge","mana_invocation","fire_control","rekindle"]
const UNCOMMON=["self_binding","reuse","resonance","shared_fate","magic_hand","flame_flourish","wildfire_descent","restraint_embrace","pot_of_greed","concentration","focus","tear","chain","peel","unlock","mana_conversion","letter_opener","adaptability","echo_cast"]
const RARE=["siphon_strength","practiced","light_as_swallow","infusion","mana_circuit","boar_emperor_blaze","fire_mastery","binding_enthusiast","pleasure_conversion","henshin","fire_dynamics"]
const REWARDS=COMMON+UNCOMMON+RARE

static func unique_face(type: String, free: bool) -> bool:
 var spec=SPECS[type]
 var face=spec.get("self_faces",{}).get("free" if free else "bound",{})
 var ids=[]
 if face.has("buff"): ids.append(face.buff)
 for effect in face.get("effects",[])+spec.get("free_effects" if free else "hit_effects",[]):
  if effect.op=="buff": ids.append(effect.buff)
 return ids.any(func(id):return not BUFFS[id].get("stackable",false) and not BUFFS[id].get("stack_uses",false))

static func follow_through_region(slot: String) -> String:
 for region in FOLLOW_THROUGH_REGIONS:
  if slot in FOLLOW_THROUGH_REGIONS[region]: return region
 return ""

static func single_face(type: String) -> bool:
 return SPECS[type].mode=="none"

static func matches_draw_filter(type: String, filter: Dictionary) -> bool:
 return not filter.has("tag") or filter.tag in type_tags(type)

static func type_tags(type: String, free: Variant=null) -> Array:
 if free!=null:
  var face=SPECS[type].get("self_faces",{}).get("free" if free else "bound",{})
  if face.has("card_type"): return [face.card_type]
 return SPECS[type].get("type_tags",[SPECS[type].card_type]).duplicate()

static func draw_label(filter: Dictionary) -> String:
 if filter.get("tag","")=="magic": return "魔力牌"
 return TYPES[filter.tag]+"牌" if filter.has("tag") else "牌"

static func exhausts(type: String, free: bool, traits: Dictionary) -> bool:
 return traits.get("exhaust",false) or SPECS[type].get("self_faces",{}).get("free" if free else "bound",{}).get("exhaust",false)

static func energy_cost(type: String, free: bool=false) -> int:
 var spec=SPECS[type]
 var side="free" if free else "bound"
 var extra=int(spec.get("self_faces",{}).get(side,{}).get("energy_cost",0))
 return maxi(0,spec.cost+extra-int(spec.get(side+"_energy_discount",0)))

static func energy_label(type: String) -> String:
 return "X" if SPECS[type].get("x_cost",false) else str(SPECS[type].cost)

static func distinct_faces(type: String) -> bool:
 var spec=SPECS[type]
 if spec.has("self_binding"): return true
 if spec.has("hannya_stage"): return spec.hannya_stage==1
 if single_face(type): return false
 if not spec.has("self_faces"): return true
 var faces=spec.self_faces.duplicate(true)
 for face in faces.values():
  if face.has("buff"):
   face.buff=BUFFS[face.buff].duplicate(true)
   face.buff.erase("name");face.buff.erase("detail")
 return faces.bound!=faces.free

static func classification(type: String) -> Dictionary:
 var spec=SPECS[type]
 return {"card_type":spec.card_type,"type_tags":type_tags(type),"rarity":spec.rarity,"type_name":"／".join(type_tags(type).map(func(tag):return TYPES[tag])),"rarity_name":"初始" if spec.get("starting_card",false) else RARITIES[spec.rarity]}

static func damage(type: String) -> bool:
 return damage_type(type)!=""

static func free_effect(type: String, second: bool) -> bool:
 return second and not SPECS[type].has("bound_modes")

static func face_mode(type: String, second: bool=false) -> String:
 return SPECS[type].bound_modes[1 if second else 0] if SPECS[type].has("bound_modes") else SPECS[type].mode

static func face_name(type: String, second: bool=false) -> String:
 return ("拘束2" if second else "拘束1") if SPECS[type].has("bound_modes") else ("自由" if second else "拘束")

static func damage_type(type: String, second: bool=false) -> String:
 if SPECS[type].has("bound_modes"): return face_mode(type,second)
 return SPECS[type].get("damage_type","")

const EFFECT_GROUPS=["free_effects","hit_effects","lowered_effects","destroyed_effects"]
const RESERVE_MANA_VALUE=5
const EFFECT_OPS=["evasion","buff","charge","next_energy","reserve_mana","energy","draw","retain","witch_focus"]

static func amount(effect: Dictionary, spec: Dictionary) -> int:
 var value=effect.get("amount",0)
 return int(spec.get(value,0) if value is String else value)

static func worn_gain(face: Dictionary, count: int) -> int:
 return int(count/int(face.worn_resource.divisor)) if face.has("worn_resource") else 0

static func hand_batch_matches(type: String, batch: Dictionary) -> bool:
 return batch.include_type in type_tags(type) if batch.has("include_type") else batch.exclude_type not in type_tags(type)

static func hand_batch_type_text(batch: Dictionary) -> String:
 return TYPES[batch.include_type] if batch.has("include_type") else "非"+TYPES[batch.exclude_type]

static func definition_reason(spec: Dictionary) -> String:
 if spec.has("self_binding"):
  var rule=spec.self_binding
  if not spec.get("x_cost",false) or spec.mode!="self" or not rule is Dictionary: return "自缚需要X费自身技能配置。"
  if rule.get("tighten_per_x")!=2 or rule.get("mana_per_x")!=15 or rule.get("slots")!=FOLLOW_THROUGH_REGIONS.legs or rule.get("templates")!=["rope","cord","belt","fine_belt","tape","cable_tie"]: return "自缚的收紧、回魔或腿部装备配置不正确。"
 if spec.has("x_cost") and (spec.x_cost!=true or spec.cost!=0 or spec.mode!="self"): return "X费卡需要零占位费用和自身效果。"
 if spec.has("reward_excluded") and not spec.reward_excluded is bool: return "卡牌随机奖励资格需要布尔配置。"
 if spec.has("encyclopedia_hidden") and not spec.encyclopedia_hidden is bool: return "卡牌图鉴展示设置需要布尔配置。"
 if spec.has("cast_free") and (not spec.cast_free is bool or not spec.has("casting") or spec.has("self_faces")): return "自由面施法需要有效施法配置。"
 if spec.has("free_mana_cost") and (not (spec.free_mana_cost is int or spec.free_mana_cost is float) or not is_finite(float(spec.free_mana_cost)) or spec.free_mana_cost<0 or not spec.get("cast_free",false)): return "自由面魔力费用需要有效施法配置和非负数值。"
 if spec.has("mana_cost") and (not (spec.mana_cost is int or spec.mana_cost is float) or not is_finite(float(spec.mana_cost)) or spec.mana_cost<0 or not spec.has("casting") or spec.has("self_faces")): return "卡牌魔力费用不正确。"
 if spec.has("worn_damage"):
  var scaling=spec.worn_damage
  if not scaling is Dictionary or not scaling.get("per_item") is int or scaling.per_item<=0 or not scaling.get("include_special") is bool or spec.get("damage_type","")=="": return "佩戴数量伤害需要正整数倍率、特殊装备计数规则和伤害类型。"
 if spec.has("exhaust_hand") and (not spec.exhaust_hand is bool or spec.mode not in ["strain","slip","magic_slip"]): return "目标卡牌的手牌消耗需要布尔配置。"
 if spec.has("free_slots") and (not spec.free_slots is Array or spec.free_slots.is_empty() or spec.free_slots.any(func(slot):return slot not in UPPER_BODY_SLOTS+FOLLOW_THROUGH_REGIONS.legs)): return "卡牌自由部位条件不正确。"
 if spec.has("bound_modes"):
  if not spec.bound_modes is Array or spec.bound_modes.size()!=2 or spec.bound_modes.any(func(mode):return mode not in ["strain","slip"]) or spec.has("self_faces") or spec.has("casting"): return "双拘束面需要两种挣扎或滑脱效果。"
 if spec.has("damage_growth") and (not spec.damage_growth is int or spec.damage_growth<=0 or spec.get("damage_type","")==""): return "卡牌成长需要正整数增量和伤害效果。"
 if spec.get("card_type","") not in TYPES or spec.get("rarity","") not in RARITIES: return "卡牌缺少有效的类型或稀有度。"
 if spec.has("drinking") and (spec.drinking!=true or spec.mode!="self" or spec.card_type!="skill" or spec.has("casting")): return "饮用牌必须是无施法的自身技能牌。"
 if spec.has("hannya_stage") and (not spec.hannya_stage is int or spec.hannya_stage not in HANNYA_REWARDS or not spec.get("drinking",false)): return "般若汤阶段或饮用配置不正确。"
 var tags=spec.get("type_tags",[spec.card_type])
 if not tags is Array or spec.card_type not in tags or tags.any(func(tag):return tag not in TYPES or tags.count(tag)!=1): return "卡牌类型词条不正确。"
 if spec.has("casting") and "magic" not in tags: return "施法卡牌缺少魔法词条。"
 if (spec.card_type=="curse")!=(spec.rarity=="curse"): return "诅咒牌需要独立的诅咒分类。"
 if (spec.card_type=="status")!=(spec.rarity=="status"): return "状态牌需要独立的状态分类。"
 if (spec.card_type=="power")!=(spec.mode=="power"): return "能力牌需要能力出牌方式。"
 if spec.mode in ["self","power"]:
  var faces=spec.get("self_faces",{})
  if not faces is Dictionary or faces.size()!=2: return "自身卡牌的双面效果不完整。"
  for side in ["bound","free"]:
   if not faces.get(side) is Dictionary: return "卡牌缺少对应牌面。"
   var face=faces[side]
   if spec.mode=="power" and (not face.has("buff") or face.keys().any(func(key):return key not in ["buff","cast","mana_cost","energy_cost"])): return "能力牌的每个牌面需要一个持续增益及可选的施法费用。"
   if face.has("exhaust") and (not face.exhaust is bool or spec.mode!="self"): return "牌面消耗需要技能或魔法自身效果的布尔配置。"
   if face.has("cast") and (not face.cast is bool or (face.cast and spec.get("casting",{}).get("parts",[]).is_empty())): return "施法牌面需要有效的施法条件。"
   if face.has("buff") and face.buff not in BUFFS: return "卡牌增益没有登记。"
   if face.has("exhaust_hand") and (not face.exhaust_hand is bool or spec.mode!="self"): return "指定消耗手牌需要自身牌面的布尔配置。"
   if face.has("refresh_spell") and face.refresh_spell not in FIXED_MAGIC: return "刷新次数需要已登记的法术。"
   if face.has("requires_successful_spell") and face.requires_successful_spell not in FIXED_MAGIC: return "施法前置需要已登记的法术。"
   if face.has("requires_hand") and not face.requires_hand is bool: return "手部使用条件必须为布尔值。"
   if face.has("exhaust_hand_batch"):
    var batch=face.exhaust_hand_batch
    if spec.mode!="self" or face.get("exhaust_hand",false) or not batch is Dictionary: return "批量消耗手牌需要自身牌面的效果配置。"
    if batch.has("include_type")==batch.has("exclude_type") or batch.get("include_type",batch.get("exclude_type","")) not in TYPES: return "批量消耗手牌需要一个有效的包含或排除类型。"
    if batch.keys().any(func(key):return key not in ["include_type","exclude_type","mana_gain","effects"]): return "批量消耗手牌包含未知效果。"
    if batch.has("mana_gain") and (not (batch.mana_gain is int or batch.mana_gain is float) or not is_finite(float(batch.mana_gain)) or batch.mana_gain<=0): return "每张手牌恢复魔力必须为正数。"
   if face.has("balance_mana_pressure") and (not face.balance_mana_pressure is bool or spec.mode!="self"): return "资源均分需要自身牌面的布尔配置。"
   if face.has("optional_draw"):
    var extra=face.optional_draw
    if not extra is Dictionary or not (extra.get("mana_cost") is float or extra.get("mana_cost") is int) or not is_finite(float(extra.mana_cost)) or extra.mana_cost<=0 or not extra.get("count") is int or extra.count<1 or extra.count>10: return "追加抽牌需要正数魔力费用及1—10张牌。"
   if face.has("spell_base_bonus"):
    var bonus=face.spell_base_bonus
    if not bonus is Dictionary or bonus.get("spell","") not in FIXED_MAGIC or not bonus.get("amount") is int or bonus.amount<1 or bonus.amount>100: return "永久法术加伤需要已登记的法术及1—100整数。"
   if face.has("worn_resource"):
    var gain=face.worn_resource
    if spec.mode!="self" or not gain is Dictionary or gain.keys().any(func(key):return key not in ["resource","divisor"]) or gain.get("resource","") not in ["mana","turn_strength"] or not gain.get("divisor") is int or gain.divisor<1: return "佩戴件数收益需要合法资源及正整数除数。"
   for key in ["mana_cost","mana_gain","energy_cost","energy_gain","pressure_energy"]:
    if face.has(key) and (not (face[key] is int or face[key] is float) or not is_finite(float(face[key])) or face[key]<0): return "卡牌资源数值不正确。"
   if face.has("pressure_energy") and face.pressure_energy<=0: return "能量转换需要正数快感间隔。"
   if face.has("free_slots"):
    if not face.free_slots is Array or face.free_slots.is_empty() or face.free_slots.any(func(slot):return slot not in ["eyes","mouth","neck","shoulder","upper_arm","forearm","wrist","palm","fingers","thigh","calf","ankle","foot","toes"]): return "卡牌自由部位条件不正确。"
 if spec.has("free_energy_discount") and (not spec.free_energy_discount is int or spec.free_energy_discount<0): return "自由面减费必须是非负整数。"
 if spec.has("free_max_levels"):
  var limits=spec.free_max_levels
  if not limits is Dictionary or limits.is_empty() or limits.keys().any(func(region):return region not in ["arms","legs"] or not limits[region] is int or limits[region]<0 or limits[region]>4): return "自由面需要有效的身体区域束缚等级上限。"
 if not spec.get("hits",1) is int or spec.get("hits",1)<1: return "卡牌段数必须是正整数。"
 if spec.has("follow_through"):
  if not spec.follow_through is bool or spec.mode not in ["strain","slip","lower"] or spec.get("hits",1)<2 or not spec.has("target_slots") or spec.target_slots.any(func(slot):return slot not in FOLLOW_THROUGH_SLOTS): return "顺延需要多段挣扎／滑脱／降紧及已划分区域的目标部位。"
 if spec.has("follow_through_scope") and (not spec.get("follow_through",false) or spec.follow_through_scope not in ["region","body"]): return "顺延范围必须为同区域或全身。"
 var effect_groups=EFFECT_GROUPS.map(func(group):return spec.get(group,[]))
 if spec.mode in ["self","power"]:
  for face in spec.self_faces.values():
   effect_groups.append(face.get("effects",[]))
   effect_groups.append(face.get("exhaust_hand_batch",{}).get("effects",[]))
   if face.has("buff"):
    var buff=BUFFS[face.buff]
    if buff.has("exclusive_group") and (spec.mode!="power" or not buff.exclusive_group is String or buff.exclusive_group==""): return "互斥能力需要有效的互斥组。"
    if buff.has("failure_conversion"):
     var conversion=buff.failure_conversion
     if spec.mode!="power" or not conversion is Dictionary or conversion.get("refund",-1.0) not in [0.0,1.0] or conversion.get("energy")!=1 or conversion.get("zero_cost_limit")!=2: return "失败转换的返还、能量或次数配置不正确。"
     if conversion.has("temporary_only") and not conversion.temporary_only is bool: return "临时魔力付款条件需要布尔配置。"
     var levels=conversion.get("unlimited_min_levels",{})
     if not levels is Dictionary or levels.keys().any(func(region):return region not in ["arms","legs"] or not levels[region] is int or levels[region]<0 or levels[region]>3): return "不限次数的身体等级条件不正确。"
    if buff.has("stack_uses") and (not buff.stack_uses is bool or not (buff.has("attack_uses") or buff.has("replay"))): return "累计次数需要攻击次数或复放配置。"
    if buff.has("stackable") and (not buff.stackable is bool or spec.mode!="power"): return "能力叠加需要布尔配置。"
    for key in ["card_cast_bonus","cast_minimum"]:
     if buff.has(key) and ((key=="card_cast_bonus" and spec.mode!="power") or not (buff[key] is int or buff[key] is float) or not is_finite(float(buff[key])) or buff[key]<=0 or buff[key]>1): return "施法能力需要0至1之间的正数。"
    if buff.has("magic_card_traction") and (spec.mode!="power" or not buff.magic_card_traction is int or buff.magic_card_traction!=1): return "魔法牌额外牵扯按1能量触发。"
    if buff.has("worn_mana_reduction") and (spec.mode!="power" or not (buff.worn_mana_reduction is float or buff.worn_mana_reduction is int) or not is_finite(float(buff.worn_mana_reduction)) or buff.worn_mana_reduction<=0 or buff.worn_mana_reduction>1): return "每件拘束的耗魔减免需要0至1之间的正数。"
    if buff.has("worn_attributes"):
     var attributes=buff.worn_attributes
     if spec.mode!="power" or not attributes is Dictionary or attributes.is_empty() or attributes.keys().any(func(key):return key not in ["strength","dexterity"] or not attributes[key] is int or attributes[key]<=0 or attributes[key]>100): return "动态装备属性需要有效的力量或灵巧整数加值。"
    if buff.has("bound_card_pressure") and (spec.mode!="power" or not buff.bound_card_pressure is int or buff.bound_card_pressure<=0 or buff.bound_card_pressure>100): return "拘束面快感触发需要1—100的固定整数。"
    if buff.has("mana_spent"):
     var meter=buff.mana_spent
     if spec.mode!="power" or not meter is Dictionary or not meter.get("step") is int or meter.step<=0 or not meter.get("effects") is Array or meter.effects.is_empty(): return "耗魔触发需要正整数阈值和效果列表。"
     effect_groups.append(meter.effects)
    if buff.has("restraint_draw"):
     var trigger=buff.restraint_draw
     if spec.mode!="power" or not trigger is Dictionary or trigger.get("event","") not in ["worn","released"] or not trigger.get("next_turn") is bool or not trigger.get("amount") is int or trigger.amount<1: return "装备触发抽牌需要有效时机和正整数张数。"
     if trigger.has("energy") and (trigger.event!="released" or trigger.next_turn or not trigger.energy is int or trigger.energy<1): return "挣脱回能需要即时触发的正整数能量。"
    if buff.has("replay"):
     var replay=buff.replay
     if not replay is Dictionary or replay.get("kind","") not in ["card","attack"] or (replay.kind=="card" and replay.get("distinct_faces")!=true) or (replay.kind=="attack" and replay.get("spell","") not in FIXED_MAGIC): return "复放增益需要有效的卡牌或法术条件。"
    effect_groups.append(buff.get("turn_start_effects",[]))
    effect_groups.append(buff.get("spell_use_effects",[]))
    if buff.has("spell_use_effects") and buff.get("spell","") not in FIXED_MAGIC: return "法术使用触发需要已登记的法术。"
 for effects in effect_groups:
  if not effects is Array: return "卡牌附加效果必须是列表。"
  for effect in effects:
   if not effect is Dictionary or effect.get("op","") not in EFFECT_OPS: return "卡牌附加效果类型不正确。"
   if effect.op=="buff" and effect.get("buff","") not in BUFFS: return "卡牌增益没有登记。"
   if effect.has("filter"):
    var filter=effect.filter
    if effect.op!="draw" or not filter is Dictionary or filter.size()!=1 or filter.get("tag","") not in TYPES: return "定向抽牌条件不正确。"
   var value=effect.get("amount",0)
   if value is String: value=spec.get(value,null)
   if effect.has("all") and (effect.op!="retain" or effect.all!=true or effect.has("amount")): return "全部保留不能同时指定选牌数量。"
   if not value is int or value<0 or (effect.op=="retain" and value==0 and not effect.get("all",false)): return "卡牌附加效果数量不正确。"
   if not effect.get("draw_after",0) is int or effect.get("draw_after",0)<0: return "保留后的抽牌数不正确。"
 var modifiers=spec.get("hand_modifiers",{})
 if not modifiers is Dictionary: return "手牌持续加成必须是属性表。"
 for key in modifiers:
  if key not in ["strength","dexterity","pleasure_multiplier","energy_pressure"] or not (modifiers[key] is int or modifiers[key] is float) or not is_finite(float(modifiers[key])): return "手牌持续加成属性不正确。"
  if key=="pleasure_multiplier" and modifiers[key]<=0: return "手牌快感倍率必须大于零。"
  if key=="energy_pressure" and modifiers[key]<=0: return "手牌能量刺激必须大于零。"
 if spec.has("end_turn_pressure") and (not (spec.end_turn_pressure is int or spec.end_turn_pressure is float) or not is_finite(float(spec.end_turn_pressure)) or spec.end_turn_pressure<=0): return "回合末快感值必须大于零。"
 return ""

static func effect_text(effect: Dictionary, spec: Dictionary, compact: bool=false) -> String:
 var value=amount(effect,spec)
 if effect.op=="witch_focus": return "精神集中%d" % value
 if effect.op=="buff" and BUFFS[effect.buff].get("witch_hand",false): return "下2次手部基础动作忽略拘束条件"
 if effect.op=="retain" and effect.get("all",false): return "保留全部手牌"+("，随后抽%d张" % effect.draw_after if effect.get("draw_after",0)>0 else "")
 if compact:
  if effect.op=="buff" and BUFFS[effect.buff].get("ignore_restraints",false): return "下%d次手部体术无视拘束限制与减益" % BUFFS[effect.buff].attack_uses
  match effect.op:
   "draw": return ("检索"+TYPES[effect.filter.tag] if effect.has("filter") else "抽牌")+str(value)
   "retain": return "保留%d" % value+("，随后抽牌%d" % effect.draw_after if effect.get("draw_after",0)>0 else "")
   "charge": return "蓄力%d" % value
   "reserve_mana": return "获得%d层魔力预备" % value
   "energy": return "能量＋%d" % value
 match effect.op:
  "buff": return "获得「"+BUFFS[effect.buff].name+"」："+BUFFS[effect.buff].detail
  "draw": return "抽%d张%s" % [value,draw_label(effect.get("filter",{}))]
  "retain": return "至多保留%d张牌" % value+("，随后抽%d张" % effect.draw_after if effect.get("draw_after",0)>0 else "")
  "energy": return "返还%d能量" % value
  "evasion": return "获得%d层闪避" % value
  "charge": return "获得%d层蓄力" % value
  "reserve_mana": return "获得%d点临时魔力" % (value*RESERVE_MANA_VALUE)
  _: return "下回合能量＋%d" % value



static func effect_details(spec: Dictionary, compact: bool=false) -> String:
 var result=""
 for group in ["hit_effects","lowered_effects","destroyed_effects"]:
  for effect in spec.get(group,[]):
   result+="\n"+({"hit_effects":"随后","lowered_effects":"降档且未解除：","destroyed_effects":"解除目标："} if compact else {"hit_effects":"随后","lowered_effects":"使目标降档且未解除时，","destroyed_effects":"直接解除所选目标时，"})[group]+effect_text(effect,spec,compact)+"。"
 return result
