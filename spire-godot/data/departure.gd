extends RefCounted

const GROUPS=[["remove","transform","uncommon"],["flask","mana","common_relic","potion"],["rare_card","rare_relic","curse","basics","wrist"],["boss"],["desire_cube_pro_max"]]
const CATEGORIES=["卡牌","资源／遗物","代价交换","初始遗物交换","欲望魔方 Pro Max"]
const RELIC_TIERS={"common_relic":["common"],"rare_relic":["rare"],"basics":["common","uncommon"],"wrist":["uncommon"],"boss":["boss"]}
const FIXED_RELICS={"desire_cube_pro_max":["desire_cube_pro_max"]}
const OPTIONS={
 "remove":"移除1张牌。",
 "transform":"变化1张基础牌，随机变为普通或罕见牌。",
 "uncommon":"从3张罕见牌中选择1张。",
 "flask":"魔瓶获得40点魔力。",
 "mana":"魔力上限＋10，并恢复10点魔力。",
 "common_relic":"获得1件随机普通遗物。",
 "potion":"道具容量＋1，获得1瓶随机药剂。",
 "rare_card":"魔力上限－10，从3张稀有牌中选择1张。",
 "rare_relic":"失去40点自身魔力，获得1件随机稀有遗物。",
 "curse":"加入1张随机诅咒，魔瓶获得100点魔力。",
 "basics":"加入「用力！」和「顾涌！」各1张，获得随机普通、罕见遗物各1件。",
 "wrist":"佩戴中级、紧度3、无锁的手腕绳索，获得1件随机罕见遗物。",
 "boss":"失去初始遗物「余烬护符」，获得1件随机Boss遗物。",
 "desire_cube_pro_max":"失去你的初始遗物，获得「欲望魔方 Pro Max」。"
}
const PICKERS=["remove","transform","uncommon","rare_card"]
const WRIST={"kind":"install","template":"rope","slot":"wrist","grade":2,"tier":3,"locked":false}
