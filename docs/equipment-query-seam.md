# 装备只读查询接缝接口契约（查询 → 索引 → 作用域）

规划者契约（planner contract），2026-09-15。冻结"装备只读查询接缝"的接口语义、返回值政策、
作用域生命周期与 oracle 协议，供实现者、清洗者、加固者、验收者只读消费；
内部实现以代码为准，接口语义以本文件为准。本文件不写执行结果：
通过／失败／未执行只登记到 docs/verification.md。

与 docs/response-pipeline.md 的分工：那份是"UI 输入 → 提交 → 落地"的接缝，其实现已被人冻结。
本片不动 UI 响应路径、节键、`present`／`render`、`dispatch` 的调用点与候选资格，
只改 core 侧装备查询的取数方式。两片互不阻塞。

## 0. 领域、现状事实、既有约束与非目标

领域：core 内对"普通件／复合组件／独立链接／特殊件／肩部件／躯干连接"的只读查询在
**一次只读调用内**的复用。三个接缝：

- 接缝 A（查询 ↔ 索引）：`game.gd:4 _equipment_read` 与 §1 的全部查询接口。
- 接缝 B（调用方 ↔ 作用域）：`_begin_equipment_read()`／`_equipment_read=previous` 的进出点（§3）。
- 接缝 C（投影 ↔ 索引）：`game_view.gd:104 equipment_entry` 的只读复用（§2）。

### 0.1 已核实现状（契约据此写，落地前不改这些事实）

> 行号约定：本文行号捕获于 2026-09-15；`core/game.gd` 在本片 B1–B9 与文案收口／按需片
> （`docs/ondemand-copy.md`）推进期间会移动（`get_view` 捕获时 `:2805`，同日已到 `:2948`）。
> 函数名与接口名是稳定锚点，行号以落地时仓库为准，动手前用 `rg` 复算。

成本结构（本片实测，夹具 0／12／26 件普通装备，composites／links／special 均为 0）：

- battle 相位：候选 6.5／24.9／75.1 ms；完整 View 31.0／53.4／114.1 ms（0／12／26 件）。
- 候选条数只从 86 涨到 182（2.1×），单候选成本从 76µs 涨到 413µs（5.4×）。
- departure 相位：候选只有 6 条且几乎不随件数变（0.24／0.29／0.40 ms），但 View 仍 28.7 → 53.0 ms；
  **departure:0 的 28.7 ms 是与件数无关的固定底价**（`card_texts` 全量注册牌型，
  属 response-pipeline §6.1 的越界待批项，不是本片目标）。
- 调用计数（battle 候选阶段 0／12／26）：`equipment_at` 431／677／1194；`_equipment` 86／370／905；
  `physical_pieces` 20／80／150；`escape_preview` 0／60／228（26 件时 `_build_escape_preview` 131 次真算）；
  `cast_view` 38／…／212（视图阶段）。
- 同一场景三次重跑波动 1.2–1.9×：**只有调用计数是确定的**，耗时只能说结构与量级。
- 原始数据与哈希：`build/equipment-layers-20260915/counters.json`（每个场景带 `candidates_sha256`／
  `view_sha256`，`samples=15`、`warmups=2`）。该次为 counter 模式，使用带计数器插桩的临时源码；
  同目录 `pristine/game.gd`、`pristine/game_view.gd` 与当前源码逐字节相同，但"插桩不改变结果"
  未经独立复核（§8 因此要求开局复算基线）。

现有容器 `core/game.gd:4 _equipment_read`（八项 = `state` 身份 + 六个边／结果容器 + `escapes`）：

| 键 | 填充点 | 读时 |
| --- | --- | --- |
| `slots{部位→件[]}` | `equipment_at:638` | `.duplicate()`（`:639`） |
| `ids{id→件}` | `_equipment:613`（由 `action_targets()` 组装） | `.get()` **不复制**（`:614`，唯一例外） |
| `pieces`（节点并集） | `physical_pieces:648` | `.duplicate()`（`:644`） |
| `stacks{id→[]}` | `_stack_items:1316` | `.duplicate()`（`:1317`） |
| `casts[profile→结果]` | `cast_view:2094` | 深拷贝；**实际是 Array，键为完整 profile 字典** |
| `equipment_views{id→entry}` | `core/game_view.gd:108` | `.duplicate(true)` 深拷贝 |
| `escapes{id→[条目]}` | `escape_preview:1441` | `.duplicate(true)`；全参数相等才复用（不在"六键"清单内，但同属该字典，本片不得改其语义） |

四类缺口（人的切分，已核对）：

1. 读一次给一份复印件：`slots`／`pieces`／`stacks`／`casts`／`equipment_views` 五处 `.duplicate`。
2. 覆盖不全——以下**从未进表**，每次调用真扫：`links_at:872`、`targets_at("shoulder"):663`、
   `link_anchors:653`、`equipment_targets:656`、`action_targets:660`（内含 `Binding.connections`，
   后者遍历全部 `state.equipment`）、`Shoulders.pieces`（`core/shoulder_links.gd:10-14`）、
   `capacity_used:717`、`_query_stack_items` 内那次 filter（`:1325`）。
3. 作用域窄——只被 `candidates():1572` 与 `get_view():2805` 打开；作用域外的调用点见 §3 两张表。
4. 键太细——`casts` 用完整 profile；`slots` 只装被问过的部位（每个新部位重扫一次全表）。

只问存在性／计数的调用点（改内部取数即可，语义不动）：`occupied(slot)`（`game.gd:910-912`）全仓 37 处
（`game.gd` 16 处）、`hand_blocked(slot,side)`（`:914-915`）、`core/prison.gd:176/424`
（`B.SLOTS.all(func(slot): not g.equipment_at(slot).is_empty())`，12 次复制换一个布尔）、
`capacity_used:714`、`_capacity_issue:705`、`_point_count:1200`。

图的结构保证（决定物化可以很简单）：深度 1、无任意链——`data/equipment.gd:252`（普通件禁止携带
coverage／root_id／parent_id／shoulder_host）、`data/composites.gd:78-81`（组件 id 必须等于
`root.id+"_"+part`，各字段与 spec 逐字段相等）、`core/torso_binding.gd:59-62`（固缚 id 必须是
`"binding_"+宿主.id`）。但**运行期无任何环守卫**：`_outer:1289`、`_effective_ratio:1310`、
`_query_stack_items→_stack_items`、`equipment_entry→_equipment_name`（`game_view.gd:121/124`）
都是无守卫递归，今天安全只因数据形状保证深度为 1。本片不得加深递归，也不得靠递归兜底。

头号风险（必须遵守）：`dispatch` 里 `state=state.duplicate(true)`（`game.gd:1987`）之后
**在原地继续修改同一对象**，`state.version` 到收尾 `:2045` 才 +1。因此**不得做"按 state 身份自动跟随"
的缓存**，否则提交过程中会拿到过期表；只允许显式作用域（进开出去），见 §3。

行号修正（按此定位，勿按旧行号找错函数）：

- 人的清单写"`_outer_cover_at:1201`"：`game.gd:1201` 实为 `_point_count`（点→件计数，属 §1／§4 的点边）；
  `_outer_cover_at` 在 `:1300`，它走 `equipment_at(slot)`（即 `{部位:件}` 边）。两者都进本片，但不是同一处。
- `casts` 实际是 Array（`[{profile,result}]`）而非 `{profile:结果}`，"改稳定键"含义见 §4。

### 0.2 既有约束的落实位置

| AGENTS.md／子模块约束 | 本契约的落实 |
| --- | --- |
| 不跨提交缓存规则结果 | §3 作用域只在只读调用内，退出即释放；§13 算未完成 |
| 查询索引与完整参数相等的预览只在一次只读调用内复用 | §3 协议原样沿用；§11 场景 2 断言"每作用域每边建表 ≤1 次" |
| 临时状态隔离，预览输入与返回容器隔离复制 | §2 返回值政策；`_equipment_read_active()` 身份判定原样保留 |
| 派生状态从真实实例计算，不维护会失同步的副本 | §2 "索引内部只读共享、边界复制一次"；§6 自检失败即作废索引 |
| 正式执行重新计算 | §3 豁免表中的写管线一律 live；`dispatch` 路径不开作用域 |
| UI 不读不写 `game.state` | 本片不改 UI；`get_view`／`candidates` 的**输出契约在本片范围内**不变（View 字段形状的后续收窄由 `docs/ondemand-copy.md` 持有授权，见该文件 §1.2） |
| 不按译文／名称／颜色识别对象 | §1 全部按稳定 id 与结构字段；§6 不猜不修 |
| 不加运行时依赖、不建第二套内核 | §9 非目标；不新增文件、不新增第三方依赖 |

### 0.3 非目标（本片不做）

- 不改规则数值、候选资格与 candidate ID 构造、费用、顺序、事务、回合、随机域、事件、日志／叙事。
- 不改存档语义、快照格式、迁移与 `SaveStore` 行为；`restore`／`write_game` 的校验路径见 §7。
- 不动 UI 响应路径与节键：`ui/main.gd`、`present`／`render`／`commit`、`ui/action_index.gd`、
  `ui/target_queries.gd` 一行不改；不新增 UI 可见行为、文案、动画。
- 不新建文件、不新增第三方依赖、不新建看板或流程文件；Gherkin 落在既有 `tests/*_cases.gd`。
- 不新增"每次调用都跑全图遍历"的路径：全图遍历只允许出现在**作用域入口的建表**里，每次作用域一次；
  不新增计时钩子、计数器或开关到生产源码。
- **不做文案与投影的按需化**（`card_texts` 按需、候选 `detail` 复用、`escape_preview` 命中率）：
  已由人裁定拆为独立契约《文案路由与按需投影》`docs/ondemand-copy.md`（先收口文案路由，后按需投影），本片不得实现；
  其中 `escape_preview` 的按需化**已由协调者裁决（2026-09-15）归入本片后续批次、未排期**
  （理由：它是只读查询而非文案，本片的索引／作用域基建正好服务它；成本实测 13.9ms／228 次调用、131 次真算）。
  **排期确认前本片与 ondemand-copy 片都不得实现**；两文件保持"未承接／未排期"的一致表述
  （见 §10 实测成本分布、§9）。
- 不以耗时数字或"应该更快"作完成判据与收益宣称（§10：收益上限约 7%；§13）。

## 1. 接口清单与语义（本片唯一必须原样保持的东西）

"来源集合"的拼装顺序 = 返回数组顺序；顺序是接口的一部分：`_equipment_name`（`game.gd:626`）用
`equipment_at(target.slot).find(target)`／`_stack_items(target)` 生成"第 N 条／第 N 件"，
候选与详情直接消费该名称；任何重排都会改玩家可见文本。

| 接口 | 来源集合（顺序） | 过滤条件 | 返回容器 | 元素 |
| --- | --- | --- | --- | --- |
| `physical_pieces():643` | `state.equipment` 原序 → `state.composites[*].components`（root 序、组件序）→ `Shoulders.pieces(self)`（`state.equipment` 原序 × `host.shoulders.pieces` 原序） | **无**（不看耐久、不看覆盖） | 新数组 | 权威实例 |
| `equipment_at(slot):635` | `physical_pieces()` | `slot in Equipment.coverage(e)` ∧ `e.durability>0` | 新数组（命中索引时 `.duplicate()`） | 权威实例 |
| `targets_at("shoulder"):663` | `physical_pieces()` | `Equipment.is_shoulder(e)` ∧ `e.durability>0`；**不走 coverage**（含复合肩带 `glove_strap` 与 `shoulder_host` 件） | 新数组 | 权威实例 |
| `targets_at(特殊槽):664` | `state.special_equipment` → `links_at(slot)` | 特殊件：`SpecialEquipment.occupies(e,slot)`，**无耐久过滤**；绳：`durability>0` ∧ `slot in link.slots` | 新数组 | 权威实例 |
| `targets_at(普通槽):665-670` | `equipment_at(slot)` → 覆盖该槽且活跃的复合组件（`slot in Composites.definition(root).coverage` ∧ `Composites.active(root)`，排除 `is_shoulder`，按**引用**去重 `has(e)`）→ `links_at(slot)` → `Binding.connections(self)` 中 `e.slot==slot` | 同左 | 新数组 | 权威实例 |
| `links_at(slot):872` | `state.links` | `durability>0` ∧ `slot in link.slots` | 新数组 | 权威实例 |
| `link_anchors():652` | `physical_pieces()` → `state.special_equipment` | 特殊件：`Links.is_crotch_anchor`，**无耐久过滤** | 新数组 | 权威实例 |
| `equipment_targets():655` | `physical_pieces()` → `state.links` | 无（**链接不看耐久**） | 新数组 | 权威实例 |
| `action_targets():659` | `equipment_targets()` → `state.special_equipment` → `Binding.connections(self)` | 连接：`Binding.present(e)` ∧ `kind=="linked"`（一体式不入列，`torso_binding.gd:11-13`） | 新数组 | 权威实例 |
| `_equipment(id):607` | `action_targets()` | id 相等，**首个命中** | **同一实例引用，不复制**（唯一例外） | 权威实例 |
| `_composite(id):672` | `state.composites` | `root.id==id` | 同一实例引用 | 权威实例 |
| `occupied(slot):910` | `equipment_at(slot)` | `palm`／`fingers`：`hand_blocked(slot,"left") and hand_blocked(slot,"right")`；其余：非空 | bool | — |
| `hand_blocked(slot,side):914` | `equipment_at(slot)` | `e.get("side","") in ["",side]` | bool | — |
| `capacity_used(slot):714` | `physical_pieces()` | `point in Equipment.capacity_points(e)`，对 `Equipment.points(slot)` 逐点计数取 `max` | int | — |
| `_point_count(point):1200` | `physical_pieces()` | `point in Equipment.capacity_points(e)` | int | — |
| `_capacity_issue(pieces):705` | **入参数组**（不保证是权威件集合） | 逐点计数 > `_capacity(slot)` | String（原因或空） | — |
| `_stack_items(target):1314` | 见 `_query_stack_items:1320` | `parent_id` 递归；特殊件按 `occupied_slots` 交集；`coverage` 空或 `link_rope` → `[target]`；否则 `Equipment.overlaps` ∧（非独立件或同 id 或不同 root） | 新数组／索引副本 | 权威实例 |
| `Shoulders.pieces(g):10` | `state.equipment` 中带 `shoulders` 的宿主 | 无（耐久过滤在 `attached`） | 新数组 | 权威实例 |
| `Shoulders.attached(g,host):16` | `host.shoulders.pieces`（`glove_body` 宿主改取 `root.components`） | `is_shoulder` ∧ `durability>0.000001` | 新数组 | 权威实例 |
| `Binding.connections(g):27` | `state.equipment` | `present(e)` ∧ `binding.kind=="linked"` | 新数组 | 权威实例 |
| `cast_view(profile):2089` | 索引 `casts` | 键 = 规范化 profile（§4） | 深拷贝 | 结果字典 |
| `equipment_entry(g,e,slot):game_view.gd:104` | 索引 `equipment_views` | 仅当 `is_same(e, _equipment(e.id))`（非权威实例绕开复用） | 深拷贝 + 覆盖 `slot` | 显示行 |

消费方可以信任：返回值与上表逐项一致；返回的件是当前权威实例（不是副本）；
返回的数组可以排序／清空而不影响其它调用。消费方不得：按名称／译文／图片识别对象；
把返回容器当作索引的一部分长期持有；写权威实例（只有正式管线写）。

"无耐久过滤"的四处（`targets_at` 特殊件分支、`equipment_targets`／`action_targets` 的链接、
`link_anchors` 的股绳锚、`equipment_targets` 整体）必须原样保留——它们决定了徒手解除与
监狱终局清单的范围，收紧或放松都会改候选。

## 2. 返回值政策

- **索引内部只读共享**：索引里存的数组／字典在作用域内只读，任何查询不得把索引内部容器
  直接交给调用方，也不得让调用方写它。
- **只在真正需要的边界复制一次**（现状即此，本片不改）：`equipment_at`／`physical_pieces`／
  `_stack_items`／`escape_preview`／`cast_view`／`equipment_entry` 在返回处
  `.duplicate()`／`.duplicate(true)`；本片新增的边（点→件、根→组件、宿主→肩、连接、绳、锚、
  `targets`／`actions` 清单）一律沿用同一政策：**索引里存一份，返回时复制一份**，同一作用域内
  只复制不重算。
- **例外一（保留）：`_equipment(id)` 返回权威实例引用**。它是规则层拿实例的通道
  （`_equipment(target.id).durability=…`、替换、清理、投影）。因此：
  "调用方不得写共享结果"**对返回容器成立、对装备实例不成立**；装备实例只能由正式管线写。
  实现者不得因为"看起来像查询"而给它加 `.duplicate()`——那会让写入落到副本上，
  候选与视图仍绿而状态不变。
- **非缓存（重新填表）路径继续返回隔离副本**：没有作用域时，各查询走 live 实现
  （`filter`／`map` 新数组），返回值仍与 §1 一致。任何路径都不得把索引容器直接返回。
- 与既有"返回容器隔离复制"规则的关系：那条规则约束的是**返回值边界**，不是"每次查询都必须重算"。
  本片合并的是同一只读调用内的重复取数，边界不动。现有断言
  `tests/architecture_cases.gd:127-129`（取回数组可清空而不损坏索引）与
  `:180-196`（预览结果／输入改写不污染复用）即该规则的既有检查，必须继续通过。

## 3. 生命周期、失效与作用域入口

协议（既有、不改签名；`game.gd:8-14`）：

- 进入：`var previous=_begin_equipment_read()`。无活跃作用域时创建（含 `state` 身份与各边容器）；
  已有作用域时返回同一容器，即**嵌套安全**。
- 退出：`_equipment_read=previous`，必须在同一次调用**所有出口**执行。
- 活跃判定：`_equipment_read_active()` = `_equipment_read` 非空 ∧ `is_same(_equipment_read.state,state)`。
- **作用域 = 只读事务**：作用域内不得（a）给 `state.equipment`／`state.composites`／`state.links`／
  `state.special_equipment` 增删成员，或改这些边依赖的字段（`durability`、`coverage`、`points`、
  `layer`、`root_id`、`shoulder_host`、`parent_id`、`binding`、`locked`）；（b）替换 `state`。
  违反即过期表，而身份判定**不会发现**（原地修改不改身份）。
- 进出纪律：单出口函数可包全身；多出口函数（`match`、早退）只包住只读子块（三行局部作用域）
  或把只读子块提为私有函数；不得把作用域跨过写动作，也不得用 `return` 跳过释放。
- 禁止自动跟随 `state`：缓存只在显式作用域里存在。理由（后来者不必重新论证）：
  `dispatch:1987 state=state.duplicate(true)` 之后在**同一对象上原地继续修改**，`:2045` 才 +1 版本；
  任何"state 变了就重建"的自动跟随都会在提交中途重建出一份**尚未完成、且此后不再变身份**的中间表，
  并把它当权威继续用。正式管线一律 live；只读投影只在显式作用域内建表。
- 也不得把 `version` 当缓存键或失效键（AGENTS 既有禁令），不得跨调用保留任何索引内容。

### 3.1 必须新开作用域的入口（读-only，各开一次；批 B9 一次落地）

下表第 1–9 项落在 `core/game.gd` 之外，随 §15 第 2 条的授权生效；若人只批
`core/game.gd` + `core/game_view.gd`，B9 只含第 10 项（`Game._prepare_assembly`，在 `game.gd` 内），
其余各项维持"作用域外调用点"现状（**不落地 ≠ 豁免**，它们仍是本契约点名的未接入口）。

| # | 入口 | 位置 | 作用域包住什么 | 判据／注 |
| --- | --- | --- | --- | --- |
| 1 | `EnemyPlans.targets` | `core/enemy_plans.gd:254` | 全函数（单出口） | 只读筛选；候选文案的敌人计划目标 |
| 2 | `Contact.workspace` | `core/contact.gd:55` | 全函数 | 只读槽位表；内部多次 `occupied`／`physical_pieces` |
| 3 | `EquipmentOffers.preferred` | `core/equipment_offers.gd:26` | 全函数 | 只读排序；`_fills_empty` 逐件判定 |
| 4 | `EquipmentOffers.for_pool`／`ordinary`／`links` | `core/equipment_offers.gd:70` 起 | 各自只读体 | 被 `first_floor_enemy_pools`／事件／敌人池反复调用 |
| 5 | `SelfBinding.tighten_targets`（含 `capacity()`） | `core/self_binding.gd:39` | 全函数（叶） | 只读；推演期换 state 时身份判定自动绕开（既有断言 `architecture_cases.gd:131-133`） |
| 6 | `RoomEvents.selector_values` | `core/room_events.gd:215` | `"restraint"` 分支的只读块 | 只读显示项 |
| 7 | `RoomEvents.compile` | `core/room_events.gd:337` | **只包** `targets=` 过滤表达式 | `locked_assembly` 分支会换 state（`:347-348`），不得包全函数 |
| 8 | `Prison.high_security` | `core/prison.gd:176` | 尾部只读块（`B.SLOTS.all(...)` + `equipment_targets()` 快照） | 前半段在写装备（`:170-174`），不得包全身 |
| 9 | `Prison.validate` | `core/prison.gd:424` | 该只读块 | 若已在 `Game.validate` 之下的嵌套调用，则为空操作 |
| 10 | `Game._prepare_assembly` | `core/game.gd:720` | 规划段（`_assembly_reason:700`、层序循环 `:728`、`_capacity_issue:739`） | 只读规划；真正写入在其后的 `_install_assembly` |

作用域不得加在叶查询上（`equipment_at`／`physical_pieces`／`_equipment`／`capacity_used`／
`_point_count`／`links_at`／…）：它们跟随外层作用域；自带作用域只会造成"每次查询重建一次"。
`candidates():1572` 与 `get_view():2805` 的现有进出保持不变。

### 3.2 明确豁免（不得开作用域）

| 入口 | 位置 | 理由 |
| --- | --- | --- |
| `Prison.intake_equipment` | `core/prison.gd:82/90` | 循环内读后写：`_refresh_equipment` 可新增肩带，作用域跨写即过期 |
| `SlipMotion.apply` | `core/slip_motion.gd:28` | 正式施加滑脱，读后写 |
| `RoomEvents.freeze_effects` | `core/room_events.gd:137` | 循环内逐次读后写 |
| `Shoulders.cleanup` | `core/shoulder_links.gd:67` | 迭代中 `erase` 肩带成员 |
| `Game.validate` | `core/game.gd:2780` | 存档／读档守卫，按 §7 保持从原始 state 现算；且未测得瓶颈 |
| `EquipmentReplacement` 收尾校验 | `core/equipment_replacement.gd:342` | 替换管线内的读后写收尾 |
| `data/first_floor_enemy_pools.gd:27 eligible` | 数据层 | 已决（人裁）：保持 live，数据层不得调用 core 的读作用域进出（§15 第 3 条）；其收益经 §3.1 第 4 项（`EquipmentOffers.for_pool` 等 core 侧自带作用域）间接到达，不需要动 `data/` |

豁免不是"可以不看"：这是契约判据（读后写／多出口／存档守卫），清洗者与加固者不得
"顺手补上"作用域；加了即 §13 的未完成项。

## 4. 键空间

边名可用实现者的命名，但必须与本表 1:1 对应，且**只沿"构建方向"由权威容器正向投影**
（不得反向搜索 `root_id`／`shoulder_host` 来"发现"成员）。

| 边 | 键 | 值（有序） | 构建方向 | 消费方 |
| --- | --- | --- | --- | --- |
| 件集合 `pieces` | — | 物理件数组 | `state.equipment` → 各 `root.components` → 各 `host.shoulders.pieces` | `physical_pieces`、其它边的来源 |
| 部位→件 `slots` | 槽 ID（所有件的 `coverage` 槽 + `"shoulder"` + 特殊槽） | 件数组（件集合顺序） | 由件集合按 `Equipment.coverage` 正向投影，**入口一次物化全量**（不再"问到哪个槽才填哪个"）；未登记的槽 = 已知空，直接返回空数组，不重扫 | `equipment_at`／`occupied`／`hand_blocked`／`targets_at`／`_outer_cover_at` |
| id→件 `ids` | 装备 id | 件（引用） | 由 §1 的 `action_targets()` 组合结果正向投影 | `_equipment` |
| 点→件（容量） | 点 ID | 件数组 | 由件集合按 `Equipment.capacity_points` 正向投影 | `capacity_used`／`_point_count`／`_capacity_issue`（仅权威件集合时） |
| 点→件（物理） | 点 ID | 件数组 | 由件集合按 `Equipment.physical_points` 正向投影 | `_outer_cover_at` 的 `point not in physical_points(e)`、触及／覆盖类判定 |
| 根→组件 | `root.id` | 组件数组（root 序） | 由 `state.composites[]` 正向投影 | `targets_at` 复合分支、`_stack_items`、显示 |
| 部位→绳 | 槽 ID | 绳数组（`state.links` 原序） | 由 `state.links` 按 `slots` 正向投影 | `links_at`／`targets_at` |
| 宿主→肩部件 | 宿主 id | `host.shoulders.pieces`（原序）；`glove_body` 宿主取 `root.components` 中 `is_shoulder` 件；`durability>0.000001` 过滤只属于 `attached` | 由 `state.equipment` 正向投影 | `Shoulders.pieces`／`attached` |
| 连接 | — | 连接件数组（`state.equipment` 原序） | 由 `state.equipment` 的 `binding.kind=="linked"` 正向投影 | `action_targets`／`targets_at`／`Binding.filter_points` 的输入 |
| 目标清单 | — | 有序数组 | 按 §1 拼装顺序组合上述边 | `link_anchors`／`equipment_targets`／`action_targets` |
| `stacks`／`escapes`／`casts`／`equipment_views` | 见下 | 结果副本 | 维持现状填充点 | 预览／显示复用 |

`casts` 改稳定键的规则：

- 键 = 规范化序列化（键名排序、递归处理嵌套容器、数值 int/float 同值归一）后的字符串，
  **不得丢字段**：现状比较的是整个 profile（`parts`、`multiplier`、`chance_bonus`、`body_free`、
  `paid_cast`、`toe_route` 及将来新增字段），全部必须进键。
- 语义要求：`键相等 ⇔ 现状 profile == profile`（相等必命中、不等必不命中）。
  宁可少命中（多算一次，走 live 结果），**不可错命中**。键里不得放目标 id、卡牌名、
  译文或实例身份来"猜等价"。
- 结果与输入仍隔离深拷贝；退出作用域即释放；不得跨调用保留。
- 现有断言 `tests/architecture_cases.gd:189-196`（等 profile 只算一次、输入／结果改写不污染）必须保持。

## 5. 谓词与计数接口

判据统一为：**只允许改"怎么取到件集合"，不允许改过滤条件、过滤顺序或返回类型**；§1 表即它们的规范。

| 接口 | 改后取数 | 必须保持 |
| --- | --- | --- |
| `occupied(slot)` | 读 `{部位:件}` 边 | 手部特例不得用"数组非空"替代：一条 `side="left"` 的件 → `occupied("palm")==false` 且 `hand_blocked("palm","left")==true`；左右各一条 → `true`；`side=""` 的件两侧全挡 |
| `hand_blocked(slot,side)` | 同一条边 | `side in ["",侧]`；返回 bool |
| `capacity_used(slot)` | `{点:件}` 的计数 | 对 `Equipment.points(slot)` 取 `max`；无点 → 0 |
| `_point_count(point)` | 同一条边 | 返回 int |
| `_capacity_issue(pieces)` | **入参不是权威件集合时必须现算**（如 `:739` 的 `physical_pieces()+root.components`） | 原因文本与阈值不变；"能否用索引"的判据必须显式，不得靠逐元素相等去猜 |

## 6. 构建期自检（不猜、不修、可归因）

只沿 §4 的"构建方向"建边；四项检查任一失败 → **整个作用域的索引作废**，该次调用余下的查询
全部按 live 重建路径回答，并留一条可见记录：

1. 组件归属：`component.root_id == root.id`，且该组件确实在该 `root.components` 中。
2. 肩部件宿主：`piece.shoulder_host` 能解析到件集合内的宿主，且该宿主的 `shoulders.pieces` 确实列出该件。
3. 引用唯一：同一物理件在件集合中出现两次，或 `{id:件}` 出现两个不同实例同一 id。
4. 连接宿主：连接式固缚的 `binding.parent_id` 能解析到件集合内的宿主（`game_view.gd:124`、
   `torso_binding.gd:59` 依赖该解析）。

- "不猜不修"：不得就地改写 `root_id`／`shoulder_host`／id 来"让它一致"，也不得跳过坏边继续用其余边
  （跳过会静默改变结果）。
- 可见记录：每次作用域最多一条，含检查编号、边名、涉事 id；写在游戏实例上的独立诊断列表，
  **不得**写进 `_equipment_read`（`tests/architecture_cases.gd:103/122/157/204` 与
  `tests/equipment_ui_cases.gd:56` 断言它读写后为空），不进玩家日志／存档／UI，不做成计数器。
- 记录不改变返回值：作废后该次调用所有查询结果必须等于"无索引"参照（§8 的 `UncachedGame`）。

## 7. 验证的边界

- **不重写验证逻辑**：`Game.validate`（`game.gd:2674` 起）、`Prison.validate`、`Composites.validate`、
  `Links.validate`、`Shoulders.validate_host`、`SpecialEquipment.validate`、`Snapshot.check` 的判定与文本
  一行不改。
- **独立路径（不得依赖索引）**：存档／读档的"从原始 state 现算"路径由 `core/save_store.gd` 承担——
  存档前的 `write_game:134` 调 `game.validate()`；读档前的 `unpack:93-95` 用全新探针
  `Game.new(0,…)` 走 `restore_snapshot`（`game.gd:2820` 内再调 `validate()`）。两处都在无作用域下调用。
  另有 `Game.validate` 保持 live（本片不接索引）与 `UncachedGame`（`_begin_equipment_read()` 返回 `{}`，
  `tests/architecture_cases.gd:5-7`）。读档／存档前的完整性判断必须能在索引关闭时得出同样结论。
- **索引不得成为验证的唯一输入**：每条边都必须同时保留 live 实现（现算代码不删），
  且架构套件里始终存在 index-on／index-off 的成对断言（§11）。
- 保留的既有断言（不得删、不得弱化）：`tests/architecture_cases.gd` 的
  `equipment_read_batches`（`:111-137`）、`equipment_projection_batches`（`:139-160`）、
  `preview_read_batches`（`:162-204`）全部 check；`tests/equipment_ui_cases.gd:56`。

## 8. oracle 与分批

### 8.1 夹具（可复现序列；件数必须断言）

```
battle   : tests/game_fixture.gd.new(42)      # 稳定遭遇夹具
departure: core/game.gd.new(42)               # 出货开局，departure 相位
0 件 : 不加
12 件: for slot in B.SLOTS: add_fixture(slot,7,10)
26 件: 再做一遍 12 件，然后 for slot in ["upper_arm","wrist","thigh"]: add_fixture(slot,7,10)
```

落地时必须断言：`physical_pieces().size() == state.equipment.size() == 0/12/26`，
`links == composites == special == 0`，`validate()==""`；与记录不符即夹具问题，先修夹具再看结果。

### 8.2 基线（行为 oracle，配对）

| 夹具 | `candidates_sha256` | `view_sha256` |
| --- | --- | --- |
| battle:0 | `bf8d97d58f3be03b42cb65ee5b36afebca335f25e496fbb3301db3285fcc46fe` | `e2b375c5019c2ccae9d088a5050b9ee445d199f74c0e524e9e63cd2bc6ccfb4a` |
| battle:12 | `c07e59259326f1ec2e380bcc1d7f2ed8e9b05e8442f16b3bb288133ff2b9a6df` | `81f7796e55826b580131762445db711651815b83b7bb0a9ab89560971ccb2f32` |
| battle:26 | `361c37774a2901bb985926fe0ce4dd9bb4f1c2e7b349d6fb39dca2a9f59d91d8` | `f7401077920a93d96b699052708a19597ffaa02496c0925b4578aee61469fc06` |
| departure:0 | `74b735a41f761e8bae611d38bffc58b103c40f1d534ba086f00bc30f2dd9fc3c` | `472f1bd7efbd2271be1e720ffff59d284d43081eb4a41362fe49d0a2362933cd` |
| departure:12 | 同 departure:0 | `c0d28042a3cfefcf74c4ec3a6df1b28ccad66dee8ab9e576ccee83ca832dc150` |
| departure:26 | 同 departure:0 | `92ce21c9462bcdb8cdbd8b78793d78f61f398a3260fb1a0fe5c1701e94b336a7` |

- 口径：`JSON.stringify` 后 sha256；**对字典顺序敏感**，只作快速指纹，
  **判定以逐字段比对为准**（`==` 深比较 + 首个差异路径）；六个数与 `counters.json` 同源。
- "插桩不改变结果"未经独立复核：切片开始时必须用**未改源码**复算这 6 个哈希并记录；
  一致才作为配对基线，不一致以复算值为准并记录差异（不得改基线去迁就实现）。
- 三路比对缺一不可：`当前（索引开）` == `当前（索引关／UncachedGame）` == `冻结基线`。
- **跨契约有效期**：上表 6 个哈希是**整份 View** 的指纹。若在 `docs/ondemand-copy.md`（按需投影）
  落地之后才重跑本片判据，`view_sha256`／`candidates_sha256` 的"整份相等"**不再成立**，必须改用该片的
  mask 判据（其 §5.4）与重算基线（其 §5.1）；两片都不得把对方批次或对方版本的通过拼进自己的结论。
  本片自己的完成判据以本片落地时的冻结版本为准。
- departure 的候选哈希三档相同，是"候选不随件数变"的既有特性：候选哈希变了就是回归，
  即使 View 哈希偶然相同。
- 基线捕获脚本只放已忽略的 `build/<topic>-<date>/`，用完删除；不入库、不留运行时钩子。

### 8.3 分批（每批只加一类边，跑完该批一次 oracle 比对，红了可归因）

新增 check 统一用 `INDEX` 前缀，落在该套件既有的 case 文件里（套件名 ↔ 文件见 `tests/test_game.gd` 的 `SUITES`）。

| 批 | 边／改动 | 该批命令（`-TimeoutSeconds 600`） | 该批也要过的具名 check |
| --- | --- | --- | --- |
| B1 | 部位→件 + 件集合全量物化（§4 首两行） | `-Suite equipment` | `INDEX slot edge parity`（`tests/equipment_cases.gd`） |
| B2 | id→件 | `-Suite architecture` | `INDEX id edge parity`（`tests/architecture_cases.gd`） |
| B3 | 点→件（容量、物理） | `-Suite equipment_complete` | `INDEX point edge parity`（`tests/equipment_complete_cases.gd`） |
| B4 | 根→组件 | `-Suite composites` | `INDEX root edge parity`（`tests/composite_cases.gd`） |
| B5 | 部位→绳、锚、目标清单 | `-Suite links` | `INDEX link edge parity`（`tests/link_cases.gd`） |
| B6 | 宿主→肩部件 | `-Suite shoulder` | `INDEX host edge parity`（`tests/shoulder_cases.gd`） |
| B7 | 连接 | `-Suite torso_binding` | `INDEX connection edge parity`（`tests/torso_binding_cases.gd`） |
| B8 | 谓词／计数（§5 全部） | `-Suite architecture,equipment` | `INDEX predicate parity`（architecture + equipment 各一条） |
| B9 | §3.1 的外层入口作用域 | `-Suite architecture,prison,events`→见注 | `INDEX entry parity`（`tests/architecture_cases.gd`） |

注：`contact` 不是独立套件名（只作为 `-Impact` 的跨域标签）；B9 用
`-Suite architecture,prison,events`（触及 `EnemyPlans`／`Contact`／`EquipmentOffers`／`SelfBinding`
的检查落在既有实例与套件里，如 `equipment`、`enemies`、`installation_priority`、`status`）。

B9 是人的八批之后新增的一批：作用域只改"何时建表"，混进边批无法归因；
若人要求严格八批，则把 B9 的 check 并入各边套件，但同一 oracle 协议不变。

另注（§10 实测）：那 6.5ms 查询层全部发生在**已有作用域**的 `candidates`／`get_view` 内，
B9 的作用是结构一致性（一份真值）与漂移保护，不是那 ≈7% 的来源；
分批顺序与每批 oracle 协议不因 §10 的归因改变。

## 9. 非目标（与 §0.3 同义，供实现者自查）

规则数值／候选资格／候选 ID／费用／顺序／事务／回合／随机；存档与快照语义；
UI 响应路径与节键；文案与本地化；运行时依赖与新文件；每次调用都跑的全图遍历；
计时钩子与计数器进生产源码；"应该更快"式宣称。

**另：文案与投影的按需化**（`card_texts` 按需、候选 `detail` 复用、`escape_preview` 命中率）
已由人裁定拆为独立契约：`docs/ondemand-copy.md`（先收口、后按需），本片不得实现——那正是 §10 实测里真正的成本所在。
其中 `escape_preview` 的按需化**已由协调者裁决（2026-09-15）归入本片后续批次、未排期**（§0.3｜§10 结论），
排期确认前任何一片都不得实现。

## 10. 函数级归因（已补齐）与收益上限

**领域**：仅 headless、仅 26 件、仅 battle 相位。夹具复用 `build/equipment-layers-20260915/` 同一套，
复算 `candidates_sha256=361c37774a2901bb985926fe0ce4dd9bb4f1c2e7b349d6fb39dca2a9f59d91d8`
与基线一致（夹具未漂）；7 轮采样、第 6 轮离群、取中位。
插桩批 wall（候选 47–60ms、view ≈93ms）与 pristine 批**不可直接比**，下面只做同批内占比。

候选阶段（`Cards.candidates` 累计 45.0ms）：

| 分项 | 耗时 | 次数／备注 |
| --- | --- | --- |
| 逐目标 `target_candidate` | 30.4ms | 其中 `detail` 文案拼装 self 11.2ms／130 次（≈86µs/条） |
| `escape_preview` | 13.9ms | 228 次调用、131 次真算（≈100µs/次） |
| `_candidate` | 9.1ms | 182 次；其中 id 行 3.8ms（`JSON.stringify` 22µs/次占 98%，`sha256_text` 3.2µs/次） |
| **查询层合计** | **6.5ms** | `equipment_at` 1194 次 2.4ms、`action_targets` 1.7ms、`targets_at` 1.5ms、`_equipment` 1.4ms、`links_at` 0.16ms、`physical_pieces` 0.27ms |
| 费用／施法 | ≈1.1ms | — |
| `magic_card_traction` | 0.63ms | — |
| `active_buffs` | 0.87ms | — |

view 阶段（本批 wall 93.2ms）：

| 分项 | 耗时 | 占比 |
| --- | --- | --- |
| `View.build` 内 `g.candidates()` | 50.9ms | 54.6% |
| `card_texts` 83 牌型循环 | 25.0ms | 26.8%（其中 `face_texts` 9.3ms／103 次） |
| bodies／部位投影 | 2.6ms | `equipment_entry` 1.6ms |
| `ReleaseView.preview` | 2.4ms | — |
| `hand` | 2.1ms | — |
| 分组／区域 | 2.5ms | — |
| 其余未插桩 | ≈8ms | — |

**结论（防后来者误判，不得反着写）：**

- **本片（装备只读查询接缝）的收益上限约 7%**：26 件 battle 的一次完整 View（93–114ms）里，
  全部装备查询合计 6.5ms（6.5 ÷ 93–114 ≈ 5.7%–7.0%）。物化邻接表是**正确性与结构的改进**
  （一份真值、少一层重复扫描、红了可归因），**不是卡顿的解药**；
  任何"能显著提速"的表述都不许写。
- **真正的成本在别处**（同一批次实测）：文案与投影合计 25.0 + 18.9 = 43.9ms（≈93.2ms 的 47%，
  其中 `card_texts` 25.0ms、候选 `detail` 18.9ms），另有 `escape_preview` 13.9ms。
  该方向（`card_texts` 按需、候选 `detail` 复用、`escape_preview` 命中率）已由人裁定拆为独立契约
  `docs/ondemand-copy.md`（先收口文案路由、后按需投影；其中 `escape_preview` 按需化已判归本片后续批次、
  未排期），本片不得顺手做（§0.3／§9 非目标）。
- 本片仍然不以耗时数字作完成判据或收益宣称；完成判据只用 §8 的相等性与 §11 场景 2 的
  "每作用域每边建表 ≤1 次"（测试侧包装计数，生产源码不带计数器）。

## 11. Gherkin（场景名 → 既有分类的具名 check）

不新建流程文件；用具名函数加入既有 case 文件，复用现有夹具与真实输入助手。
以下 Given／When／Then 即实现与门禁的验收合同；未落地即未完成。

1. `equipment_index_edge_parity`（`tests/architecture_cases.gd`，规则分类 `architecture`）
   - Given §8.1 的 6 个夹具、`UncachedGame` 参照、§8.2 冻结基线；
   - When 逐项调用 §1 的每个查询（全槽位 `equipment_at`／`targets_at`（含 `"shoulder"` 与特殊槽）、
     `physical_pieces`、`links_at`、`link_anchors`、`equipment_targets`、`action_targets`、
     每件 `_equipment(id)`、`capacity_used`、`_point_count`、`occupied`／`hand_blocked` 全槽位×两侧）；
   - Then 与参照逐字段相等、数组顺序相等；`candidates()`／`get_view()` 与绝对基线相等
     （hash 相等且字段比对无差异）；`state` 与随机游标不变；退出后 `_equipment_read.is_empty()`。

2. `equipment_index_materializes_once_per_scope`（`architecture`；测试侧计数包装，仿
   `PreviewCountingGame`）
   - Given 同一作用域内对同一边的不同键各查一次（12 个槽位、多个 id、多个点）；
   - When 对比有作用域／无作用域两种调用；
   - Then 建表次数 ≤1（每边每次作用域）、查询期间无重扫；无作用域时不建表（live 每次现算）；
     清空或排序任一返回值不影响后续查询（既有 :127-129 断言的扩展）。

3. `equipment_index_self_check_falls_back`（`architecture`）
   - Given 三种破坏夹具：组件 `root_id` 与根不一致、肩带 `shoulder_host` 指向不存在的宿主、
     两条不同实例共用同一 id；
   - When 各调一次 `get_view()` 与 `candidates()`；
   - Then 结果等于无索引参照；每次作用域恰好一条具名记录（检查编号 + 涉事 id）；
     `_equipment_read` 为空；状态、日志、存档无变化。

4. `equipment_index_predicates_unchanged`（`architecture`）
   - Given 单手侧别件、`side=""` 件、`palm`／`fingers` 混合、复合／链接／特殊件夹具；
   - When 对比索引开／关的 `occupied`／`hand_blocked`／`capacity_used`／`_point_count`／
     `_capacity_issue`（含非权威入参数组，如 `physical_pieces()+root.components`）；
   - Then 逐项相等（含 §5 的手部真值表与原因文本）。

5. `equipment_index_scope_entries_release`（`architecture`）
   - Given §3.1 的每个入口各有可构造夹具；
   - When 逐个调用入口（含嵌套调用 `Prison.validate`）；
   - Then 每个调用后 `_equipment_read` 为空、`state` 未变、返回值与索引关闭时一致。

6. `equipment_index_entry_parity`（`architecture`）
   - When 对同一夹具分别以索引开／关运行 `EnemyPlans.targets`、`Contact.workspace`、
     `EquipmentOffers.preferred`／`for_pool`、`SelfBinding.tighten_targets`／`capacity`、
     `RoomEvents.selector_values`／`compile`、`Prison.high_security`／`validate`、`Game._prepare_assembly`；
   - Then 返回的 id 序列／槽位表／顺序／原因文本逐项相等。

7. 边上取样（每批一条，落在对应套件）：
   - `equipment`：部位→件与"第 N 条"名称（同一槽多个同模板件、复合组件共享槽）；
   - `equipment_complete`：点→件与容量（长短单腿套、`capacity_points` 为空模板）；
   - `composites`：根→组件与 `targets_at` 的复合拼接顺序（活跃／失效根、按引用去重）；
   - `links`：绳／锚／目标清单的耐久过滤差异（0 耐久绳、耐久 0 的端部件、股绳锚）；
   - `shoulder`：宿主→肩部件与 `attached` 的 0.000001 过滤、`glove_body` 宿主的组件来源；
   - `torso_binding`：连接清单只含"连接式"，一体式不入 `action_targets`／`targets_at`。
   每条均：Given 该家族夹具，When 索引开／关各查一次，Then 逐项与顺序相等。

8. `equipment_index_cast_keys_exact`（`architecture`）
   - Given 等价但键序不同的两个 profile、仅一个字段不同的两个 profile；
   - When 同一作用域内依次查询；
   - Then 等价者只算一次、不同者各自不命中；结果与无索引参照相等；退出后无残留。

## 12. 验收程序（validator 用；agent 可运行）

宿主入口：`tests/test_game.gd` + `tools/check.ps1`；界面证据用 `tests/ui_smoke.gd`，
操作必须是真实 viewport 输入（复用既有 `move_mouse`／`mouse_button`／`flip`／`start_drag`／
`release_target` 等助手）。测试存档隔离（`ui.persistence_enabled=false`）；不默认截图。

1. 范围预检（不算通过）：
   `& tools/check.ps1 -Suite architecture,equipment,equipment_complete,links,composites,shoulder,torso_binding,casting,prison,events,slip_motion -ListOnly`
   → 输出 `PLAN ONLY:` 且列出上述套件；缺一即范围问题。
2. 规则门：
   `& tools/check.ps1 -Suite architecture,equipment,equipment_complete,links,composites,shoulder,torso_binding,casting,prison,events,slip_motion -TimeoutSeconds 900`
   → 退出码 0；输出含 `RULE SCOPE:`、每个 `SUITE RESULT: PASS <name>`、`PASS: N assertions`；
   `summary.json` 的 `status=passed` 且 `before==after` 指纹（`source_changed` 不算通过）。
3. 界面只读证据：
   `& tools/check.ps1 -UI -Suite architecture -UISuite equipment_complete,body_layout,shoulder,torso_binding -TimeoutSeconds 900`
   → 退出码 0、`UI PASS: N assertions`；不默认截图。
4. 人的路径证明（判据是套件布尔 check，按顺序操作界面）：
   - 战斗中开身体栏 → 点开一件普通件详情：位置／耐久／紧度文本与 View 一致；
   - 点开一件带肩带的件：肩带条数与"连接至/依附于"文本与 `Shoulders.attached` 一致；
   - 点开复合组件与链接绳：位置文本、"遗留外带"标记与 `targets_at` 范围一致；
   - 真实打出一张会损坏装备的牌：详情耐久/紧度随实际状态更新（不得停留在旧值）；
   - 进入地图／事件／监室各一次：不因作用域泄漏而卡住或改变状态（读档一次通过校验）。
5. 归属判定：失败原因分"实现代码／测试脚本／环境／程序本身"；原因不确定就保持未分类上报，
   不自动改产品代码。
6. 证据：`build/checks/<id>/check-rules.log`、`check-ui.log`、`summary.json`；
   结果与域写 docs/verification.md（validator 负责，不在本文件宣称通过）。

## 13. 完成定义（Definition of Done）

命令（每批一次 + 收尾一次，不无故重复）：

```powershell
& tools/check.ps1 -Suite <B1…B9 的批套件> -TimeoutSeconds 600
& tools/check.ps1 -Suite architecture,equipment,equipment_complete,links,composites,shoulder,torso_binding,casting,prison,events,slip_motion -TimeoutSeconds 900
& tools/check.ps1 -UI -Suite architecture -UISuite equipment_complete,body_layout,shoulder,torso_binding -TimeoutSeconds 900
```

必过的场景：§11 的 1–8 全部具名 check；`tests/architecture_cases.gd` 的
`equipment_read_batches`／`equipment_projection_batches`／`preview_read_batches` 与
`tests/equipment_ui_cases.gd:56` 原断言不变且通过。

必有的证据：每批一次的 oracle 比对记录（6 夹具 × 三路比对结论，hash + 字段比对），
收尾两份 check 日志 + `summary.json`（status=passed、指纹稳定），基线捕获脚本与
`build/` 数据未入库、已删除或留在忽略目录。

算未完成（任一）：

- 任一必跑套件未执行、失败、未知或被跳过；`summary.json` 为 `source_changed`／`failed`／`plan`；
- 用旧版本的通过拼接最终结论；删／弱化既有断言换取绿灯；
- 只报 hash 不报字段比对，或哈希不一致仍宣布通过；
- 索引成为验证的唯一输入（`UncachedGame` 对照被绕过或删除）；`Game.validate`／存档路径接了索引；
- 作用域泄漏（调用后 `_equipment_read` 非空）、给 §3.2 豁免入口加了作用域；
- 自检"就地修正"或跳过坏边继续用；`_equipment(id)` 被改成返回副本；
- 改动规则数值／候选资格／存档／随机／文案／UI 响应路径／节键；新增运行时依赖或新增文件；
- 实现 §0.3 押后、现由 `docs/ondemand-copy.md` 承接的"文案与投影按需化"
  （`card_texts` 按需、候选 `detail` 复用）——在装备片里做即越界；
  另：`escape_preview` 按需化已判归本片后续批次但**未排期**，未排期就做同样越界（§0.3｜§10 结论）；
- 以耗时或"应该更快"作完成判据，或用查询调用次数减少推导"显著提速"式结论。

## 14. 假设与最可能爆掉的假设

1. **最可能爆：`只读入口` 的判定错。** `RoomEvents.compile` 的 `locked_assembly` 分支会换 state
   （`:347-348`），`SelfBinding`／`RoomEvents`／`Prison` 会在推演或半途状态下被调用。
   若在这些函数全身开作用域，会出现"换 state 后索引错误复活"或"跨写拿到过期表"——
   表现为 oracle 红或玩家可见文本错。缓解：§3.1 表逐行的"包住什么"、§3.2 豁免、
   §11 场景 5"每次调用后 `_equipment_read` 为空且 `state` 未变"。
2. **`_equipment(id)` 的引用语义被"顺手复制"**：它看起来像其它查询。一旦复制，
   规则层的实例写入落到副本上，候选与视图仍绿而状态不变。缓解：§2 例外一 + 场景 1 的
   `is_same` 断言（现有 `architecture_cases.gd:133` 可扩展）。
3. **`{部位:件}` 全量物化的成本假设**：入场一次 O(件 × 覆盖)。若某夹具覆盖槽极多
   （拘束衣／长单手套），建表可能比按需过滤贵。缓解：B1 后用同一协议对比调用计数；
   必要时退化为"按需填充 + 已知空闲槽记忆"，但语义不变。
4. **顺序假设**：所有边以件集合顺序为准；`_equipment_name` 的"第 N 条／第 N 件"依赖它。
   `_installation_points:1197` 的排序只依赖 `_point_count` 的数值，不依赖点内顺序。
5. **夹具可复现假设**：§8.1 的序列必须复现出 0／12／26 件与 `validate()==""`；
   复现不出时**以字段比对为准并记录夹具差异**，不得修改基线或改夹具去凑哈希。
6. **耗时不是本片判据**（§10 已补齐：收益上限约 7%）：不得用"调用次数减少"推导"帧更快"。
7. **数据层假设（已决）**：`data/first_floor_enemy_pools.gd` 保持 live，
   数据层不得调用 core 的读作用域进出（§3.2、§15 第 3 条）。

## 15. 范围问题（状态截至 2026-09-15 的修订）

1. **已完成**：`spire-godot/AGENTS.md` 文档入口表已加
   `| 装备只读查询 | docs/equipment-query-seam.md |`（协调者执行；指引门禁
   `PASS: 2 instruction files`、退出码 0，该文件 125 行／7830 字节，上限 500 行／10000 字节）。
   （2026-09-16 注：`spire-godot/AGENTS.md` 已在 `ee9c54c` 合并进仓库根 `AGENTS.md`，该路径不再存在；
   本条为历史记录，勿按原路径查文件。）
2. **待人批（已由协调者转人）**：授权范围——本片需 `core/game.gd`、`core/game_view.gd`、
   `core/enemy_plans.gd`、`core/contact.gd`、`core/equipment_offers.gd`、`core/self_binding.gd`、
   `core/room_events.gd`、`core/prison.gd`（8 个 core 文件，仅加作用域进出或改内部取数），
   并在既有 `tests/*_cases.gd` 追加具名 check。
   若人只批 `core/game.gd` + `core/game_view.gd`：**B9 标记为不可落地**，§3.1 第 1–9 项不实施，
   B9 只含第 10 项（`Game._prepare_assembly`，在 `game.gd` 内）；§3.2 的豁免判定维持不变
   （不落地 ≠ 豁免，这些入口仍是本契约点名的"作用域外调用点"）。
   影响：B1–B8 与 oracle 协议不受影响——§10 实测的 6.5ms 查询层全部发生在已有作用域的
   `candidates`／`get_view` 内，**不损失已测得的收益**；损失的是"一份真值"的结构一致性
   （这些入口继续各扫一次）与未来漂移保护。
3. **已决（人裁）**：`data/first_floor_enemy_pools.gd:27` **保持 live**；数据层不得调用 core 的
   读作用域进出。收益经 §3.1 第 4 项（`EquipmentOffers.for_pool` 等 core 侧自带作用域）间接到达，
   不需要动 `data/`。
4. **已决（人裁）**：`Game.validate` **保持 live**；存档／读档的"从原始 state 现算"独立路径由
   `core/save_store.gd` 承担（`write_game:134` 与 `unpack:93-95`，§7 已写明）。
5. **已关闭**：函数级归因已补齐（§10）；本片不以耗时数字作完成判据。
6. **已决（人裁）**：夹具序列落在**既有测试文件内**以具名构造落地，不新建夹具文件；
   §8.1 的序列即其规范。
