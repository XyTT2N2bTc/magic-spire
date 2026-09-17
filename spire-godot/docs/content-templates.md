# 内容编写模板：供其他 AI 接手

自身技能牌的双面可配置`balance_mana_pressure:true`，用于将自身当前魔力与快感直接均分；沿原卡牌事务及Pressure的统一过载处理。不计临时魔力／魔瓶，不调用耗魔触发；资源上限照常生效。命运同担为现有示例，卡面和图鉴文案仍登记在balance.gd。

2026-09-10：[卡牌类型／稀有度／能力牌源码模板](card-framework.md)支持双面能力、法术修正与跨回合出牌计数的群体伤害。卡牌仍需内部注册，不能直接放入JSON内容包；开信刀play通过periodic配置接入既有能力生命周期。

2026-09-09补充：普通生成名单含绳索类或皮带类时，底层自动加入合法链接绳，无需逐池重复填写。链接与其他第三优先级目标一起抽取，必须已有合法两端；限定上锁、部位或位置的效果继续复核其要求。事件install_random可冻结并提交实际链接，不重抽已经公开的两端。眼部各类装备共享最多2件容量。复合与特殊装备仍使用各自池和工厂。

核对日期：2026-09-07。先读[生成规则](content-generation.md)，再选本页对应模板；实现接口见[内容扩展接口](content-extension.md)。拘束结构以[装备设计](equipment-design.md)为完整依据。

2026-09-07：**可直接放入游戏的五类 JSON 模板已完成**，见 [内容包说明](../content/README.md) 与 `content/templates/`。按那里格式填写，放进 `content/packs/` 后重启新局即可。

本文以下保留的是高级设计表和内部注册表示例，不是可直接加载的完整内容文件；涉及复合结构、链接、新行为等超出内容包范围的设计仍需补底层实现。不要把以下片段直接复制到 packs。所有 `sample_` ID 都是未登记样例，本批不会将它们加入游戏。

标成“需要补逻辑”的内容不得当作已支持配置。例子的数值仅演示格式，正式新增前要结合目标难度确定。

## A. 每项内容必填的交接表

```text
内容 ID：英文 snake_case，稳定不复用
日常名称：
家族：普通拘束具 / 复合拘束具 / 链接 / 特殊部位装备 / 道具 / 遗物 / 敌人 / 遭遇 / 事件
状态：设计草稿 / 仅练习 / 正式生成（本次明确选一种）
玩法目的：玩家会面对什么选择，增加哪一种已有玩法变化
规则来源：用户已确认要求、项目文档章节

复用的现有机制：
新增机制及需要改动的执行处：没有则写“无”
定义位置：
生成来源与排除来源：必须具体到注册表、池或调用处
抽取时机、随机域、结果保存位置：
合法目标与不足时处理：无目标 / 满容量 / 重复持有 / 阶段不符
持续状态与终止条件：

界面：名称、位置、费用、关键数值、可用或不可用原因
结果：成功 / 失败 / 部分进展 / 到期 / 失去目标的具体提示
教程：名词解释，简短、日常、与真实规则一致
素材：资源键、现有占位资源、后续替换点
存档：新字段、合法值、恢复后的下一步；没有新增字段也检查新 ID 引用
验收：最小正例、最近反例、边界、原子回滚、随机重放、实际 UI
不在本次范围：
```

**生成来源必须写全。** 例如“只在新事件中出现”不是一句承诺：普通模板可能进入警卫的全表查询，事件定义也会进入塔路全表抽取。没有隔离入口时，应先补来源过滤，或把草稿留在文档。

## B. 普通拘束具模板

### B1. 设计表

```text
类型 ID / 日常名称：
材料：从 rope/leather/tape/plastic/cloth 中选择现有材料
等级：允许哪些 grade，最低 min_grade；对应等级材料版本必须存在
最大耐久：普通级别由 Equipment.maximum 取得，不单写另一张数值表
初始紧度：由来源选 1/2/3 档，耐久比为 40%/80%/100%

规则槽 slots：
精准位置：允许哪些真实 points；安装是否指定 point
左右：成对普通覆盖 / 已有单侧结构（不能仅凭名称变成单侧）
容量：复用原点容量；若更改必须单独说明规则变更
层级与封闭：是否被现有套体挡住，如何判定外层
是否固定躯干：否 / 是（现仅身后；额外触及限制保留）

支持方法：strain / slip / manual / lock 各填 true 或 false
实时条件：手是否够到、精细动作、外层、姿态、墙面／工具等
不能滑脱原因：结构禁止还是紧度导致，二者不能混写
附加效果：优先复用既有材料／部位规则；新增效果列出执行点
损坏／滑脱成功后：移除单件、清理依附链接与效果

生成：敌人专用模板池 / 警卫通用池 / 事件配方 / 监狱 / 练习
来源差异：各自等级、紧度、锁状态、精准安装点
验收：来源能选到；错误槽拒绝；满点拒绝；层级合法；伤害与清理正确
```

### B2. 现有字段例子

合入 `data/equipment.gd:TEMPLATES` 的一个条目：

```json
{
  "sample_ankle_belt": {
    "name": "窄皮带",
    "material": "leather",
    "slots": ["ankle"],
    "strain": true,
    "slip": true,
    "manual": true,
    "lock": true,
    "min_grade": 1
  }
}
```

这里不写实例耐久、随机权重或当前锁状态。来源通过正式安装工厂提供 grade、初始耐久／最大耐久、locked、source 与可选精准位置。实际名称会按普通命名函数加部位前缀，因此模板 name 不必再写“脚踝”。

这个例子复用皮带方法与材料；它一旦注册就可能被通用普通选装枚举。要让浮游皮带也生成它，另改对应 `install_pool/final_pool`，并验证两阶段等级与槽合法。想新增独立肩部普通件或新品级，属于部位／数据校验扩展，不是仅改本条目。

## C. 复合拘束具模板

### C1. 设计表

```text
family / variant / straps：
名称 / 最低等级：
根的真实覆盖 coverage：
关闭的部位 closed：
可生成组合：是否加入 Composites.GENERATION，哪些来源继续筛选

逐组件填写一行：
part ID | 日常名称 | 已有 template | coverage | contact | points | side | independent

每组件的来源初始值：grade、tier、locked（默认继承还是明确覆盖）
共享关系：哪些部位实际指向同一组件，不能重复计算耐久
结构条件：先处理哪些组件，才允许滑脱或拆除套体
局部损坏：套体归零后其他组件移除还是留下，为什么
外层／封闭：哪些后装物品被禁止，哪些真实内层可以保留
链接依附：可以接到哪一件真实组件，组件消失时怎样清理
手部与工具接触：按哪个真实接触位置检查，展示位置是否不同

安装原子性：任一部位容量／结构失败则整件不安装
验证：完整安装、逐组件解除、拆套留带、封闭边界、链接清理、恢复后继续
```

### C2. 对应现有接口

`data/composites.gd:spec` 返回 `kind/variant/straps/name/coverage/closed/parts/minimum`；组件使用 `part(label, template, coverage, contact, independent=false)` 构建，需要时加真实 `points/side`。

现有组合可直接参考：

```json
{
  "family": "glove",
  "variant": "long",
  "straps": "cross",
  "grade": 2,
  "tier": 2
}
```

这段是**内部安装参数说明，不是可自动导入的新模板**。正式安装对应 `_install_assembly("glove", "long", source, 2, 2, overrides, "cross")`。新 family 还需实现 spec、校验、结构解除与状态／目标投影；不要把上例复制改名就认定有新结构。

手套肩带虽显示在肩部，当前组件接触仍沿已有结构定义；展示迁到颈部栏不改规则。套体与肩带分别可选；同一套体跨部位显示也只算一个真实组件。

## D. 链接模板

```text
链接类型与名称：
材质／等级／初始耐久：沿既有链接定义
端A：真实装备或组件 ID 的选择条件
端B：真实装备或组件 ID 的选择条件
允许的端部组合：对照 data/links.gd，不能仅判断“部位挨着”
哪一端的滑脱受阻：
本体可用解除方法与接触来源：
共享耐久：两端展示同一 link ID
端部解除后的清理：
生成来源及没有完整两端时的处理：
验收：两端去重、端部失效、解链接不删装备、删端部清链接、原子失败
```

复用 `_install_link`，不往两端各塞一件普通绳。新连接规则应扩展 `data/links.gd` 与共用目标／清理逻辑，不另造一套独立端点库存。

## E. 特殊部位装备模板

### E1. 设计表

```text
type / 日常名称：
区域与允许子槽：逐项列 ID，不能只写“位置2”
同槽容量：读取 CAPACITIES；是否需要改变现有容量（默认不改）
固定 grade / maximum / 初始 ratio：

触发类别：能量被动 / 有限回合 / 混合
energy_gain：每次正能量支付增长多少
turn_gain：每玩家回合开始增长多少
duration：回合增长的次数；纯能量被动为0
到期结果：纯回合移除；混合保留能量被动
逐件性：多个实例独立触发、独立耐久、独立剩余次数

methods：从现有方法 ID 选择
tools：允许哪些已注册工具
environments：从 wall（墙壁类）/sharp（尖锐类）/hook（挂钩类）选择，统一登记在 data/environments.gd；声明后仍需真实来源与接触，尖锐工具还需匹配 tools 白名单
damage_factor：复用目标伤害乘区，不重写伤害公式
触及不足：无手时哪些真实环境能提供解除条件
移除结果：立刻停止本件后续触发与占位

正式来源：当前没有通用来源，默认仅练习
若接入敌人／事件：新增操作、合法方案、公开代价、执行与快照校验分别在哪
美术：按真实子槽／实例显示，不从普通肢体受限等级选图
验收：同槽逐件、满容量、不同类型同槽、正能量一次、零费、回合边界、混合到期、破坏后停止
```

区域完整清单及容量：`special_1_a:1`；`special_2_a:2, special_2_b:2, special_2_c:2, special_2_d:1`；`special_3_a:1, special_3_b:1`。

### E2. 同一 type 的两表例子

先合入 `data/special_equipment.gd:TYPES`：

```json
{
  "sample_pulse_module": {
    "name": "脉冲模块",
    "energy_gain": 3.0,
    "turn_gain": 2.0,
    "duration": 3,
    "wear_text": "她将「{name}」贴到对应部位，收紧固定带后打开了开关。"
  }
}
```

再合入同文件 `DESIGNS`：

```json
{
  "sample_pulse_module": {
    "grade": 2,
    "maximum": 20.0,
    "ratio": 0.8,
    "slots": ["special_2_a", "special_2_b"],
    "methods": ["strain", "slip", "magic_slip", "lower", "focus", "cut", "hook"],
    "tools": ["shard", "saw"],
    "environments": ["wall", "sharp", "hook"],
    "damage_factor": 1.0
  }
}
```

此例为混合类型：一次支付2能量也只增长3；之后每次玩家回合开始增长2，共3次；到期仍保留支付能量增长3的被动。完整触发时机复用原管线，不新增定时器。初始耐久16/20，对应二档。

只有获准的规则流程内部才能调用 `Game._install_special(type, slot)`。JSON 内容包会自动生成安装事件，显式事件也可用 `special_install`；手工添加内部定义仍须明确取得入口。不要增加 `durability` 到 TYPES，或手工写假的实例 ID；也不要恢复无耐久方案。

## F. 道具与遗物模板

### F1. 道具设计表与字段

```text
type / 名称：
operation：cut / unlock / escape / buff，或明确标记“新增操作需实现”
buff额外字段：category（potion / scroll）、effect（mana / energy / charge / draw / reserve_mana / sure_cast / slip_boost）、amount；使用 core/consumables.gd 的资格、实际数值与效果描述。target_scope=body_group使用Equipment.panel_groups中的完整分组；unrestricted_use=true豁免身体／姿势条件；mouth_reduction=false豁免药剂口部减效。未声明时沿原规则。
uses / damage / materials：
手持资格与目标接触：复用 FieldTools 与 Contact
安装方式：复用 carry/hand_wall/foot_wall；新安装位必须有接触规则
容量：使用既有容量查询
生成入口：战后掉落 / 商店 / 休息 / 事件 / 监狱发现 / 练习逐一明确。战后池单独登记 data/field_tools.gd::DROP_POOL，不因注册到TYPES就自动掉落。
价格：若进商店，登记 Data.TOOLS 和 PRICES
无次数、满背包、离房未取回：各自结果
验收：取得、使用扣次、安装和重新打开、取回、清理、存档
```

合入 `data/field_tools.gd:TYPES` 的切割变体：

已实现分组药剂：`lubricant_potion / 润滑油`，operation=buff、category=potion、effect=slip_boost、amount=2、target_scope=body_group、unrestricted_use=true、mouth_reduction=false、uses=3、damage=0、materials=[]。随身占1格；不可安装，空组可选，用尽清理。战后DROP_POOL与商店TOOLS中登记，PRICES=15。状态按类型＋分组唯一保存，战斗或整备结束清除；正常／魔法／自动滑脱统一结算，不另造伤害接口。案例由consumables分类的body_consumable_cases及consumable_ui_cases覆盖。

```json
{
  "sample_cutter": {
    "name": "简易切割片",
    "uses": 2,
    "damage": 4.0,
    "materials": ["rope", "leather"],
    "operation": "cut"
  }
}
```

如需在商店出现，还需给 `data/room_services.gd:TOOLS` 追加 `sample_cutter`，并在 `PRICES` 登记经确认的价格。不要把 price 写在道具条目后期待商店自动读到。显示资源复用现有查找表，新增名称不自动产生新图标。

### F2. 遗物设计表与字段

奥利哈基米（olihakimi）：罕见一般遗物，modifiers={"unspent_turn_mana":8}。该hook接受1—100整数，玩家回合结束且未实际支付魔力时恢复对应数值并封顶；战斗、牢房、休息、整备共用。combat.mana_used独立于耳坠余数，正式付款后保持true，恢复魔力不会撤销；回合开始重置。零费施法、魔瓶转移不算付款；失败但付费的施法算。仅触发实际回合结束，不将战胜敌人离场另算一次回合结束。

`pressure_guard_turns`（1—10整数）：本场前N回合快感上限99，倍率后截断且不储存超额。绿色小鸟使用6，稀有一般遗物；复用统一combat.turn，计数不从拾取时重新开始。图标剩余回合与资源保护说明使用只读投影。


红烧鱼香茄子（braised_eggplant）：稀有一般遗物，复用 `modifiers: {"pickup_mana_max":20,"pickup_mana":20}`。取得时先增加魔力上限，再恢复魔力；无需新增触发接口。


触手朋友（tentacle_friend）：稀有一般遗物，modifiers={"unrestricted_items":1}。取消道具的身体／姿势／触及限制，药剂及魔瓶取出仍读口部减效公式。带trigger_damage_types的工具随身时视为固定，全身为可触及范围；不修改真实mount，保留容量、次数、材料、外层遮挡与目标方法资格。工具加成只复用原对应伤害牌触发，不开放新的直接切割路线。通用flag仅接受整数1。

`opening_charge`（1—10整数）：每场战斗、牢房、休息和整备开始时增加已有蓄力层数。例：普通遗物爆炒麻辣米线，`modifiers: {"opening_charge":2}`。复用begin_combat，不在拾取时追溯，也不在普通换回合或巡视恢复时重复触发。


传单（flyer）：普通一般遗物，说明“进入商店时，魔瓶补充20点魔力。”；modifiers={"shop_flask_mana":20}，进入REWARDS。shop_flask_mana为1—100整数，由商店首次初始化调用共享魔力遗物hook，目标为无上限魔瓶，不改自身魔力或手动存入次数。每间商店一次，重开界面不补发，在店内取得从下一间商店生效；不显示累计计数器。

指定回合末全体固定伤害复用现有trigger对象：`{"event":"turn_end","scope":"battle","phase":"battle","round":7,"op":"fixed_enemy_damage","amount":77}`。round与amount为1—100整数；该效果限战斗指定玩家回合结束、每场一次。案例为稀有kings_gift_revised／成王之礼精装修订重置版，已加入REWARDS。敌人目标在触发时冻结，直接走共享敌人伤害及分裂／击败处理，fixed不受倍率；不放入跨行动待发放队列，不自行重复写敌人血量或胜利。回合和已使用标记复用现有状态，图标计数由RelicEffects.counter投影。

特殊收藏遗物使用rarity=special、collectible=true、空modifiers，以及明确无效果的detail。不得附带trigger或card_base_bonuses，也不进入一般REWARDS。拾取可重复、持有表仅保留一个ID，relic_counters记录数量，统一counter投影以goal=0表示持有份数。内置rolling_log／滚木作为Relics.FALLBACK，抽中品质池耗尽时发放；不消耗其他品质库存。无存档迁移。


`low_mana_end_restore`（1—100整数）：仅战斗／牢房探索场次结束时，若当前魔力≤当前上限50%，恢复指定数量并封顶。统一end_combat中先于battle_mana结算，阶段与门槛在此hook内固定，不由UI或持有顺序决定。案例：罕见`marble`／西兰花，`modifiers: {"low_mana_end_restore":20}`，已加入REWARDS。巡视暂停不触发，探索转为反抗战斗时才结束并触发；休息与整备排除。

可选通用字段`card_base_bonuses`按稳定卡牌ID声明基础伤害加值，每项为1—100整数，只接受具有base的真实卡牌。例如罕见遗物“优秀学员毕业证书”：`modifiers: {}`、`card_base_bonuses: {"strain":4,"slip":4}`。Cards.base_damage在全部伤害倍率之前统一加值，卡面通过同一函数生成；自由面、属性与原始卡牌模板不变。不同来源加值相加，同一遗物重复拾取不叠加。可单独使用，也可与modifiers／trigger组合；未知卡牌、无基础伤害卡牌、空对象及越界／非整数值由同一内容加载器原子拒绝。

`always_wall`（整数1）：持有期间始终满足贴墙效果判定。案例：稀有`little_pig`／一只小猪，`modifiers: {"always_wall":1}`，加入REWARDS。Game.at_wall处理效果，Game.wall_contact处理真实墙面接触；不得改写wall_distance或跳过具体工具／挂钩的安装位置、距离及使用条件。状态投影按持有来源显示，无独立buff计数。

`opening_energy`（1—10整数）：每场第一个玩家回合正常补能后额外获得指定能量，战斗／牢房／休息／整备共用。案例：普通遗物`small_gem`／小宝石，`modifiers: {"opening_energy":1}`，加入REWARDS。复用现有first_turn，不在拾取时补发、不新增计数；独立图案登记到ui/relic_icon的ART。

新增可复用修饰项`restraint_mana`（1—100整数）：每成功安装一件拘束具立即恢复指定魔力，封顶当前上限，不限阶段。普通件、独立链接、复合根、特殊装备各计一次；组件、锁与加固不计。实际案例`desire_cube`／欲望魔方／稀有，`modifiers: {"restraint_mana":5}`，已加入REWARDS。安装工厂共用原魔力触发器，替换预演与失败沿原事务回滚；不要在敌人、事件或UI重复发放。

已实现案例：`happy_fa`／开心小fa／罕见，`modifiers: {"turn_energy_step":3}`，每3个真实玩家回合开始额外＋1能量。跨场次保留，拿到时从0计，新游戏清零；加入REWARDS，重复授予不重置。战斗、整备、休息、牢房共用入口，地图与零回合操作排除。由RelicEffects.begin_turn执行、counter投影，ui/relic_icon统一右下角数字；不得在某张遗物卡或页面中单独数回合。该hook接受1—100整数，不同遗物分别累计。

```text
ID / 名称 / 简短规则说明：
稀有度 rarity：common 普通 / uncommon 罕见 / rare 稀有（必填）
被动数值 hook 或已有触发类型：
触发时机与条件：以真实行动结果判定
次数边界：每行动 / 每玩家回合 / 每战斗
多段：何时记一次、何时发放挂起收益
失效或清理：
随机来源：是否加入 REWARDS；与初始装备分开
重复持有：沿已有禁止规则
验收：取得后真实生效、次数不重复、跨房／存档、UI说明与实际一致
```

`data/relics.gd:TYPES` 中复用容量 hook 的例子：

```json
{
  "sample_storage_badge": {
    "rarity": "common",
    "name": "收纳徽章",
    "detail": "随身道具容量增加1。身体限制仍会减少容量。",
    "modifiers": {"capacity": 1}
  }
}
```

随机获取需另加 `REWARDS`。若设计“解除某组件后抽牌”，不要杜撰 modifiers 键；应接 `core/relic_effects.gd` 的行动结果、次数记账与统一收益发放。

## G. 敌人及遭遇模板

### G1. 个体设计表

```text
type / 名称 / hp / order / visual：
behavior：guard / restraint / attachment / dispenser，或新行为需实现
strength：弱怪允许1或2，仅后台使用，不自动缩放其他属性
定位：弱怪 / 强怪搭配 / 精英，为什么
阶段1：计划、目标来源、失败替代、是否离场
阶段2：
阶段3：
最终阶段：

装备模板池、等级、紧度、材质版本如何选择：
本来合法的目标被解除时：保留什么、允许换什么、无目标怎么办
打断：延后原计划，是否有既有特殊例外
可观察性：哪些是未来计划，哪些是已经发生的事实
多实例：ID独立，不能共享私有计数或最终目标
压力／持续状态：复用具名来源与清理，不由显示文字触发
胜利／离场：复用原战斗终止与共用奖励
验收：全部阶段、打断续局、失效重定向、重复实例、蒙眼、存档、行动反馈
```

### G2. 材质怪数据例子

优先使用可直接导入的 `content/templates/enemy.json`。直接新增基础定义时可参考：

```json
{
  "sample_rope": {
    "name": "巡游绳索", "hp": 24, "strength": 1, "order": 12,
    "behavior": "restraint", "visual": "rope",
    "install_pool": ["rope", "cord"], "final_pool": ["rope", "cord"]
  }
}
```

复用“初级2档施加→加固或补施加→准备→中级2档附着”四步骤；不添加无人读取的actions数组。口球attachment固定口部且初级2档；玩具箱dispenser须另声明已存在的特殊装备type名单special_pool。

### G3. 遭遇与生成池

个体放入TYPES后，单独登记ENCOUNTERS的rank和members，再按设计加入第一幕弱池。弱怪strength允许1或2，前台隐藏；生命、装备品质和紧度仍各自定义。强怪组合清单由FirstFloor.POOLS.strong统一登记，每组总强度4，按组合ID排除上一组；组合练习不自动加入。新增强怪组合需在data/enemies.gd的ENCOUNTERS登记并加入FirstFloor.POOLS.strong；本次未扩展JSON单体模板为组合编辑器。具体怪物的步骤、专用池与现有组合见[第一幕敌人设定](first-floor-enemy-library.md)。

新 behavior 的交接必须列出：`EnemyPlans.build/resolve`、`Game`执行、`Snapshot.intent`、`IntentView`、文案与反馈、阶段与重放案例。只有模板和立绘不算完成新 AI。

## H. 事件模板

### H1. 设计表

```text
事件 ID / 名称 / 一句话场景介绍：
目的：玩家为什么愿意承担风险，收益为什么值得
来源：当前 TYPES 全表参与塔路抽取；若限制出现条件，单列需要新增的生成逻辑
进入时条件：哪些合法目标会决定是否有某选项
随机：进入固定哪些结果，选择后才抽哪些奖励

逐选项填写：
稳定 ID / 按钮短句：
收益：
代价与风险：具体目标、等级、紧度、锁、资源、概率
recipe 或完整效果列表：二选一
执行顺序与同批引用：
没有合法目标或没有奖励时：
成功 / 失败 / 取消选牌后：

离开：按节点声明；`allow_refuse:true`自动追加付费离开，必须完成交易时写`false`；其他自定义费用仍需先扩展通用规则
结构：`start_node`＋`nodes`；单节点用哨兵`choice`，多节点按 H4 写各阶段节点
后续阶段：只指向数组中的后续阶段、result或跨事件对象{"event","node"}；是否带公开加权结果
链语义：跨事件跳转的对象形态与延续／并集／环拒绝是否都写清
批量生成：是否使用install_random／tighten_random，哪些模板与数量
暂存与收尾：hold_special的key／slots，以及cleanup_effects中的restore_held
不可穿插的行动：
存档：选项、具体代价、refs、秘密结果、奖励选择均能恢复
文案：选择前必须知道什么，什么要保持隐藏，结果说清实际变化
验收：各分支、代价原子性、重复点击、无目标、空遗物池、奖励容量、隐藏结果与重放
```

### H2. 只用已有配方的例子

完整可复制文件是`content/templates/event.json`（单节点）与`content/templates/event_multistage.json.disabled`（多节点）；字段与节点声明的含义见`content/README.md` §3，本节不复制第二份完整 JSON。只用现有配方时，单个选项就是下面这个形状：

```json
{"id": "try_one", "label": "试一件，换普通牌", "recipe": "free_basic", "reward": "common"}
```

`recipe`与`effects`至少要有一个，或只写`outcomes`；两者不能同时出现。配方默认展示实际生成的部位／装备代价。`allow_refuse:true`的节点会自动追加`refuse`付费离开选项，不要在`choices`里再写同名条目；写`false`则必须完成一项选择。显式效果选项需在不可执行时完全隐藏，可设置`hide_when_unavailable:true`；接受后奖励牌才抽取并保存。

快感写成效果`{"op": "pressure", "amount": 10}`，不是选项字段；事件风险需一起确认。不使用 `exit_mode/weight/once_per_run/requirements` 等未实现字段。若事件要禁止离开或自定义离开惩罚，应先扩展真实流程，不能靠隐藏按钮绕过状态规则。

### H3. 明确效果的最小例子

以下是节点`choices`中的**一个完整条目**，只使用已经能预告并执行的安装效果：

```json
{
  "id": "accept_ankle_belt",
  "label": "佩戴脚踝皮带，换普通牌",
  "effects": [
    {"op": "install", "template": "belt", "slot": "ankle", "grade": 1, "tier": 1, "locked": false}
  ],
  "reward": "common"
}
```

此例无精准分段选择；不加 point 或 variant 假装生效。需要“在某个大腿分段安装指定材质”时，先把字段接进配方／效果、执行器、预告、快照与测试。

连续效果可由安装的 `ref` 保存本批新实例，再用 `ref_target` 引用；但现有选择前／结果说明的引用支持尚不完整，详见[效果支持范围](content-generation.md)。不要直接写一个带引用的多效果事件而漏测预告和读档。

### H4. 多阶段事件

完整可复制文件见`content/templates/event_multistage.json.disabled`。它使用通用节点、加权结果、批量随机安装／收紧和事件结束归还接口，不包含任何按事件名分支的代码。

- `nodes`按顺序列2—12个节点（上限12），`start_node`必须引用其中一个；每个节点只能转向数组里靠后的节点或`result`。
- 每个节点必须写全`id/title/intro/allow_refuse/unavailable/relic_gate/random_freeze/outcome_draw/frozen_form/empty_node/choices`，取值见`content/README.md` §3。起始节点必须允许付费离开，或包含一个无条件、无效果且直达结果页的免费离开选项；后续节点可以禁止中途退出。
- 每个选项可把`effects`、`recipe`与`outcomes`组合使用，但`effects`与`recipe`不能同时出现。`outcomes`需2—8项`weight/effects`，并在选项上提供不泄密的公开`detail`。
- 选项可填写`show_pressure_sources:true`，按冻结效果顺序把每个`pressure.source`放到结果正文前；该选项必须实际包含至少一个带`source`的快感效果。
- 选项／随机结果可用`report_variants`替换结果正文，`pressure`效果可用`source_variants`替换动作正文。每项填写`when:{kind:"equipped_special_family",value:"已登记family"}`和`text`；进入事件／阶段时读取真实在身装备并冻结正文。它只解决同一机械结果在不同佩戴状态下的叙述差分，不得改变效果、概率、资格或奖励。
- `install_random`与`tighten_random`只存在于作者数据；普通事件在进房时、多阶段事件在进入对应阶段时冻结为普通`install`或`tighten_to`效果，保存与提交不重新选目标。`install_random.allow_links`默认为真；写成假时严格只生成普通单件。
- `random_amount`同样只存在于作者数据；填写现有数值效果`effect`及包含上下限的`minimum/maximum`，进入事件或阶段时冻结为一个定值效果。它不能包装卡牌、遗物、装备或脚本。
- `hold_special`按精准特殊部位暂存无连接的现有性玩具；同一`key`必须在顶层`cleanup_effects`恰好归还。暂存记录保留完整实例，不重建类型、剩余次数或编号。
- 跨事件跳转把`next`写成对象`{"event":"已登记事件id","node":"该事件的节点id"}`：提交后同一个`room_event`实例改写为目标事件的`id`与`stage`，不新建实例也不经过地图，形成事件链。链语义：`values`计数与`held`暂存在整条链上继续共享、暂存`key`必须整条链唯一（跨定义重复或`cleanup_effects`引用别的定义的`key`会让整包拒绝，运行期的“同一保管位置不能重复使用”只是第二道守卫）；`cleanup_effects`取整条链的并集并按`key`去重，离开时各执行一次；`chain`键只在真的发生跨事件跳转时写入，记录已经走过的事件id（抵达时没有这个键），链上经过的目标事件都会加入`event_seen`；事件携带的遗物按目标事件的定义重算，目标没有遗物奖励选项或遗物池为空时置空，不会发出来源事件的遗物。跳转目标必须已登记，事件不能引用自身；回到链上已经走过的事件会被拒绝——选项保留但不可用，原因文案为“这段事件已经走过，不能再回头。”。链能力已可用，但当前 12 份迁移内容都没有使用，E0 基线只覆盖单定义事件。
- 状态条件有两类拼写：规范拼写`conditions`（1—8条数组，每条`{kind, mode, reason, …}`）与兼容拼写`availability`（单个条件对象，可与`hide_when_unavailable:true`配套）；两种拼写在同一选项互斥，新内容优先用`conditions`。
- `mode`的`optional`＝显示但禁用（保留按钮并显示`reason`），`hidden`＝不生成（不进`room_event.options`也不出候选）。全部条目按 AND 判断，**任一`hidden`命中即隐藏**，只有`optional`命中时列出全部命中条目，`reason`**按声明顺序**换行连接。
- 选项级`unavailable`（`hide`／`disable`）给出未被显式`mode`约束的条目的默认模式，与`hide_when_unavailable`互斥；完整优先级见`content/README.md` §3。
- `selector`可从卡组或当前真实拘束具生成选项，并用`$selected`把稳定实例ID传给`transform_card/remove_card/ease_restraint`；显示文案可用`{name}/{slot}/{type}`。
- `counter`只写本事件内的非负整数；选项的`when`用`equals/minimum/maximum`读取该计数，从而组合筹码、累计胜场和分档兑现。`when`也可改填一个`selector`并比较当前可选数量，例如`{"selector":{"kind":"restraint"},"equals":0}`只在没有可选拘束具时显示后备选项；计数与选择器不能混填。
- `special_install_random`从已登记类型中冻结一件与当前装备及暂存装备都兼容的性玩具，不能静默覆盖原装备。
- 每种性玩具必须提供独立的`wear_text`，恰好包含一次`{name}`。所有事件的安装结果复用这段正文并代入准确装备名；禁止用“中级性玩具”等泛称替代具体名称。
- 普通单件拘束具不在各事件重复维护佩戴正文；事件按真实部位读取`data/equipment.gd::WEAR_TEXTS`并代入具体装备名。新增普通可安装部位时必须先补齐这组正文。
- `special_install_random`的`fallback`可省略；省略后若没有空余位置，整项选择不生成。写了`fallback`才执行作者明确声明的后备结果。
- 封闭演出中仅为描写而暂时取下、随后装回性玩具时，只写正文，不改装备状态；确实需要让空位参与后续规则时才使用`hold_special/restore_held`。
- 随机结果、无合法目标、暂存装备、读档续选、旧版本候选和离场收尾都必须纳入验收。未知`op`会令整个内容包拒绝，不能用故事名或事件ID充当新机制。

### H5. 所有事件的界面约定

- 成功／失败必须显著区分：有输赢的选择在对应结果中明确填写`result_status: success/failure`，通过正式提交保存后再显示大字与不同颜色的结果横条。普通推进、领取和离开等没有输赢含义的动作使用`neutral`（“已完成”）。禁止按对白关键词、奖励数量或支付代价猜结果，也不能提前在选项投影中泄露冻结结果。结果标记随存档保存，点击阅读“继续”后不带入下一页。

- 每次选择产生的结果先单独显示，下面只放“继续”；点击后再显示当前阶段的正文与正式选项，不能把结果堆在下一段正文后面。每页只显示本次结果，历史保留在日志。最终离场页直接显示结果与离开选项，不重复播放开场。
- “继续”是本地阅读翻页，不提交游戏命令、不重复结算、不修改版本或随机。切换信息窗口与重绘保留已读状态；重新载入游戏可再次阅读当前结果，但不能重复领取奖励。事件不设置独立人物对白接口，已编写的对话直接留在事件正文中。

- 事件工作区采用左图右文：左上保留事件立绘位置，未提供图片时保持统一占位；右上为标题与可独立滚动的正文，右下为少量主选项。主选项通常2—4项，不把卡组或装备逐件铺满主界面。
- `selector.kind=card/restraint`沿同一`source_choice`收成一个主入口，点击打开统一二级窗口。选卡与奖励复用完整卡面，重复牌按真实uid各自显示；选择拘束具显示真实部位、耐久、紧度和锁。
- 二级窗口中选定具体对象才提交原候选及打开时版本；关闭、Esc、翻面和滚动不支付、不改卡、不推进阶段或重抽结果。概率、代价和具体不可用原因仍须可见。
- 普通事件、多阶段事件与练习使用同一界面，不为个别事件复制专属窗口。文案与插画不得承担规则判断，未提供插画不阻止已有事件游玩。

## I. 每类最小验收矩阵

| 家族 | 最小成功 | 最近失败／边界 | 关联完整性 |
|---|---|---|---|
| 普通拘束具 | 指定来源安装到合法精准点 | 错误槽、满点、封闭区、非法锁／等级 | 损伤、层级、辅助、解除及链接清理 |
| 复合物／链接 | 完整结构与两端合法 | 某组件失败整件回滚、端点失效 | 局部解除、真实残留、同目标去重、恢复后继续 |
| 特殊装备 | 允许子槽逐件安装与解除 | 同槽满容量、白名单不符、无手无环境 | 正能量一次、零费不触发、限时到期、混合保留、破坏停止 |
| 道具／遗物 | 正式取得后真实使用／生效 | 容量、次数、目标、重复遗物 | 安装重开、离房清理、次数边界、恢复不补发 |
| 敌人 | 完整阶段与实际目标 | 原目标消失、无替代、打断 | 实例独立、计划冻结、蒙眼、离场与反馈 |
| 事件 | 每个奖励与代价分支 | 无目标、无遗物、支付不足、重复提交 | 预告完整、秘密不泄露、奖励保存、费用不退、容量整理 |

所有分类共同检查：相同种子重放；旧版本候选与伪造目标拒绝；失败不改资源、牌、编号、随机或日志；正式保存／恢复后下一步一致。新增测试沿现有套件及直接交叉范围登记，检查命令见生成规则末节。

## J. 可直接交给其他 AI 的任务说明

```text
只在当前独立 spire-godot 项目工作，先阅读其 AGENTS.md、docs/content-generation.md、
docs/content-templates.md，以及与本项直接有关的 game-design/equipment-design 章节。
不要使用旁边旧网页项目的代码、规则管线或测试框架。

本次要增加的内容：<粘贴上面的已填写设计表>
获准的范围：<仅写设计 / 练习验证 / 正式加入指定来源>

先核实每个字段是否有现有执行代码。区分可复用的数据变体与需要实现的新机制；
对缺少消费者的字段不要宣称已支持。模板 ID 与实例 ID 分开，中文只用于显示。
沿 Game.dispatch 的候选、版本复核、原子结算和清理执行，不让 UI 直接改状态。
生成必须说明来源、合法目标、随机域、冻结时机、无目标回退及存档，保持预览只读。
普通、复合、链接、特殊部位装备分别用原工厂，不能为了统一而抹掉结构或容量差异。

实现机械逻辑后补齐简洁说明、具体不可用原因、实际行动结果、状态和教程；
叙事使用现有文案接口，本任务不要求扩写成人内容。
按真实影响补现有规则/窗口案例，合并直接交叉套件，不另起框架或默认跑全项目。
最终报告：实际改动、正式或练习来源、验证范围/结果/日志、仍未实现的部分。
不要只提交注册表、占位卡片或截图就宣布功能完成，也不要擅自加入未获准的生成池。
```

## 躯干固缚附加状态

手臂普通单件设计只声明部位、等级、材料与初始整数紧度，不手填运行时binding或伪造独立躯干装备。三档由正式安装／加固流程触发随机连接式或一体式，生成与存档边界见equipment-design第7.1节。连接耐久暂定10／16／24，可独立平衡；刷新保留原形式。


### 移动／探索类事件补充字段

- 完成类型：付费室内位移／实际跨房移动回合／成功探索／非移动。
- 被动触发点：主动作完成后；跨房须在新房入口前。
- 失败、取消、零位移：不触发；探索成功即使免费仍触发。
- 接入：只调用共享SlipMotion.apply，不复制倍率、目标随机或扣耐久。
- 验证：费用一次、各点随机、真实ID去重、外层不穿透、免疫不重抽、失败回滚与日志；具体规则见game-design第4.2B节。

## 2026-09-07：肩部附加拘束设计表（已实现）

必填：基础拘束类型、品质、自动／额外来源、原件引用及实际大臂位置、左右肩目标。生成保存每侧独立耐久、紧度、交叉历史、活动状态；每件最多一对。交叉历史不能仅从当前2档反推，且不能共用单条交叉耐久。解除方法继承基础类型后明确覆盖“无挣扎”及交叉滑脱封锁。

权威细则见 equipment-design.md 第7.2A节。

肩部实现：普通原件用嵌套肩部配对记录，左右实际物理目标进入统一装备查询；单手套保留复合根并使用left/right组件，旧cross共享组件存档拒绝恢复，需重新开始对应练习。额外施加通过正式肩部专用入口与警卫计划提供，不向普通模板slots添加shoulder。


2026-09-07 范围修正：所有紧度3档触发的额外添加机制只适用于普通单件拘束具，包括额外肩部拘束及躯干固缚。复合拘束具仅按原有结构保留和处理自带组件；单手套套体升到3档不新增或补回已解除的肩带，也不因此生成可加固目标。复合肩带现有的左右独立耐久、滑脱数量修正和自身交叉状态规则保持不变。


2026-09-09补充：遗物modifier新增力量／灵巧、腿足灵巧、首回合抽牌、开场回魔、剩余能量保留、拾取时上限／魔力和耗魔换能。字段、数值范围及特殊战斗语义以content/README.md第4节为准；模板仍通过原注册器、拾取入口与存档校验。

2026-09-10卡牌源码模板新增follow_through=true：复用多段挣扎的base／hits与free_effects，按指定精准部位→左栏大部位→原大片区域自动顺延，关键词、目标优先级及card_target随机域统一维护。详见card-framework.md“顺延”；仍不支持外部卡牌JSON。

`pressure_reduction_percent`（1—100整数）：持有时将所有来源正向快感增长乘以（1－该值／100），与其他遗物逐件相乘；包括固定快感。新稀有大理石marble_stone使用40；手牌敏感倍率仍只作用于非固定来源。快感降低量不受影响。

商店限定遗物使用`shop_only: true`，不加入一般REWARDS，由Relics.shop_pool在shop源合并。可选`shop_payment: flask|self`约束付款来源；只给商店限定遗物使用。内容包与内置定义共用校验、抽取和候选，不按名称分支。`pickup_mana_full: 1`表示拾取时按新魔力上限恢复全部自身魔力，先于恢复应用pickup_mana_max。示例M当劳：罕见、shop_only=true、shop_payment=flask、modifiers={pickup_mana_max:10,pickup_mana_full:1}，共用罕见65价格和原品质概率。
卡牌即时效果`{"op":"evasion","amount":2}`通过既有effects添加闪避层数；由Application在合法施加时消耗，不能写入安装工厂或候选查询。独立下一次卡牌滑脱增益参照light_as_swallow_bound，使用card_damage_type=slip和damage_multiplier，沿card_buffs保存，本场结束清除。

### 拾取时赠牌

遗物可用 `pickup_cards: ["magic_hand_gift"]` 在拾取时将指定永久牌加入卡组及当前弃牌堆。列表须有1—10项，每项须为已登记卡牌ID，不能是临时状态牌；可以与modifiers、trigger并用，也可单独作为拾取效果。欧内的手赠送的magic_hand_gift与普通magic_hand共享规则，但没有消耗特性且不进入随机奖励／商店卡池。
