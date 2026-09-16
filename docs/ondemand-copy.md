# 文案路由与按需投影接口契约（收口 → 按需）

规划者契约（planner contract），2026-09-15。本文档有两部分，**顺序即人的裁定**：

- **第一阶段（§11）文案路由收口**：不同功能的文案收到同一处路由（类别 + 参数），生产者不再各自拼整段字符串。
  它是结构改进，**不承诺省时**；按需（延迟渲染）只是路由的一个能力，不是第一步。
- **第二阶段（§1–§10）按需投影**：View 只带界面固有集合，其余在真正显示时才经路由取。
- **前置批 B0（§4.1）不变**：三处"缺键即崩"的取用点先安全化，收口与按需都要它。

执行顺序：**B0 → §11 收口（R0…R6）→ §4 按需（B1…B3）**。两阶段都不改判定、随机、存档、快照与可见文案。

供实现者、清洗者、加固者、验收者只读消费；内部实现以代码为准，接口语义以本文件为准。
本文件不写执行结果：通过／失败／未执行只登记到 docs/verification.md。
本文件按**交接材料**写：批次名在文内自解释，接手方不需要会话语境（§11.6）。

与另两份契约的分工：

- `docs/response-pipeline.md`（已冻结实现）：UI 输入 → 提交 → 落地。本片不动 `_submit`／`commit`／
  `present`／`render`、节键、候选资格与提交语义。唯一事实修订是 UI 新增只读调用（§10 第 3 条）。
- `docs/equipment-query-seam.md`（B1–B3 已落地，B4–B9 进行中）：装备只读查询接缝。其 §0.3／§9 把
  "文案与投影的按需化"押后为独立一片，即本片。**本片实现必须排在邻接表片 B4–B9 之后；
  两片不得并发修改 `core/`**（两片都碰 `core/game.gd`、`core/game_view.gd`）。

## 0. 领域、现状事实与人的裁定

### 0.1 领域

一次 `get_view()` 里为**玩家看得见的文字**所做的投影（卡面文案、候选详情），以及 UI 在真正显示时才
取用这些文字的只读路径。不含规则判定、随机、存档、快照。

### 0.2 已核实事实（本片据此写，落地前不改这些事实）

> 行号约定：本文行号捕获于 2026-09-15；`core/game.gd` 在邻接表片（`docs/equipment-query-seam.md`）
> 与本片收口／按需阶段推进期间会移动（例：`func _candidate` 捕获时 `:1667`、同日已 `:1685`；
> `get_view` 捕获时 `:2805`、同日已 `:2948`）。**函数名是稳定锚点**，行号以落地时仓库为准，
> 动手前用 `rg` 复算（§10 第 7 条给了命令）。

成本（headless，26 件 battle，一次完整 View 93–114ms；与 pristine 批不可直接比）：

| 分项 | 耗时 | 次数 |
| --- | --- | --- |
| `card_texts` 全量注册牌型循环 | 25.0ms（26.8%） | 83 型；`face_texts` 9.3ms/103、`cast_view` 1.4ms/212、`cast_profile` 1.2ms/210 |
| 候选 `detail` 文案 | 18.9ms | 130 条（≈145µs／条，self 86µs 为纯字符串拼装） |
| `worn_count(g)` | — | 每次 View 约 166 次（`core/card_effects.gd:388` 与 `:400` 各一次）；手牌通常只有 5 张 |
| `escape_preview` | 13.9ms | 本片不做；其按需化**已判归装备片后续批次（未排期）**（见 §10 第 8 条） |

构造点：`core/game_view.gd:293-305`（`card_texts` 全量循环）、`:288-291`（`deck_list`）、
`:294-299`（`card_instances`）；候选详情在 `core/card_effects.gd:653-730`（`target_candidate`／
`Cards.candidates`）经 `core/game.gd:1667-1695`（`_candidate`）拼装。

**界面测绘：显示一张卡面的入口（实测 10 条，全部汇入 `ui/main.gd:851 _card` / `:912 _display_card`）**

| 入口 | 位置 | 牌型来源 | 归属 |
| --- | --- | --- | --- |
| 手牌 | `ui/main.gd:1002-1005` | `view.hand` 行 + `card_texts` + `card_instances` | **S**（`state.hand` 的 type／uid） |
| 保留行 | `ui/main.gd:1280-1283` | `Catalog.card` + 两投影 | **S**（手牌行 type） |
| 幽灵卡（抽／弃、打出） | `ui/card_motion.gd:65` | `Catalog.card` + 两投影 | **现场补算**（事件驱动，投影期不可知；抽牌时该牌已进手牌 → 落在 S） |
| 奖励三选一 | `ui/reward_screen.gd:103-105` | `Catalog.card` + `card_texts`（**uid 伪造、无实例**） | **S**（`state.reward_options`；候选见 `core/game.gd:1770-1771`） |
| 出发选牌 | `ui/departure_screen.gd:22-24` | `Catalog.card` + 两投影 | **S**（`core/departure.gd:141` 面板条目／候选 `payload.type`） |
| 事件卡选项 | `ui/event_screen.gd:117-118` | `Catalog.card` + 两投影 | **S**（`view.room_event` 选择项 type；`payload.type` 为兜底） |
| **商店买卡** | `ui/shop_screen.gd:46-47,78` | **`offer.type`（`view.shop.stock` 行；候选 payload 只有 `{kind,op,index}`，没有 type）** | **S**（`view.shop.stock` 中 `kind=="card"` 的 `type`）——**只扫候选 payload 会漏掉这一条** |
| 商店去卡 | `ui/shop_screen.gd:154-156` | `view.deck_cards` 取 type | §1.3 全量入口 |
| 牌堆浏览 | `ui/deck_browser.gd:22-24,89` | `Catalog.card` + **显式两投影 + 再走 `_display_card` 二次合并（三重）** | §1.3 全量入口 |
| 图鉴 | `ui/encyclopedia.gd:138` | **纯静态目录**（`live_state=false`） | 不进 S，本片不改显示来源 |

`live_state` 是 static/live 的单点开关：默认 true，图鉴显式 false（`ui/main.gd:851-855,912-916`）。

**投影字段消费点（实测）**：`view.card_texts` 3 处 UI（`ui/main.gd:854`、`ui/main.gd:2051`、`ui/deck_browser.gd:23`）+ 13 个测试行；
`view.card_instances` 2 处 UI（`ui/main.gd:855`、`ui/deck_browser.gd:24`）+ 1 个测试行；
`view.deck_list` UI **0 处**、全仓仅 `tests/graduate_certificate_cases.gd:35`。

**平行入口与重复实现（实测，供实现者避坑；本片不改这些，但不得假装它们不存在）**

- 同一"face_texts → face_costs → metadata"四步有**两份组装**：`data/encyclopedia.gd:38-44`（`Catalog.card`）与
  `core/game_view.gd:302-305`；费用同样双源：静态 `Rules.energy_label`（`data/card_rules.gd:204`）与实时
  `Cards.energy_label(g,…)`（`core/card_effects.gd:370`）。
- `ui/deck_browser.gd:22-24` 的显式合并与 `:89` `_display_card` 内部合并是**三重合并**，且它用合并后的
  `face_costs`／`cost`／`type_tags`／`rarity` 做筛选与排序——去掉任何一层都会改筛选行为，**本片不得动**。
- `card_instances` 只收录 `damage_growth`／`hannya_stage`（`core/game_view.gd:297`），消费方对任意 uid 都用
  `.get` 读取、缺失静默为空——按需化后"缺失"必须走 §3 helper，不能继续静默。
- **View 外的平行文案生产入口**（不经 `get_view` 直接产文案，属同一重复生成问题）：
  `core/game.gd:1777`（奖励卡候选）、`core/room_services.gd:41`（商店 offer 详情）、
  `core/room_events.gd:600`（事件奖励卡候选）、`core/witch_expansion.gd:94`（事件日志）、
  `core/card_effects.gd:606`（**候选 `detail()` 内直接调 `face_text`，与 `face_texts` 对同一张牌重复生成**）。
- 候选 `detail` 唯一写入点是 `core/game.gd:1695`（在 `_candidate:1667` 内）；表达式点**实测 86 个**：
  `_candidate` 直接调用 71（`core/game.gd` 40 + 其余模块 31）+ 3 个转发包装的调用点 15
  （`Prison.add` 9：`core/prison.gd` 内 7 + `core/prison_space.gd` 2；`target_candidate` 3；
  `paid_candidate` 3）。包装定义：`core/prison.gd:220`、`core/card_effects.gd:653`、`core/room_services.gd:52`。
  只 grep `_candidate` 会漏掉包装那 15 处；测绘初稿的 92／16 含 `_route_exit_candidate` 这类同名子串与定义行
  （复算命令与脚本见 §10 第 7 条、§11.3）。

**候选 `detail` 的 UI 取用点（实测，按是否真显示分列）**

| 类别 | 位置 |
| --- | --- |
| 真显示 | `ui/main.gd:709`（基本行动栏 summary 兜底）、`:1294`（`_action_row`）、`:1311`（`_card_target`）、`:1538`／`:1553`（紧凑行动／工具目标）、`:2059-2061`（拖放落点效果）；`ui/event_screen.gd:83/96/103-104/121`；`ui/departure_screen.gd:46`（值经 `core/departure.gd:141` 从候选复制） |
| tooltip | `ui/main.gd:735/847/1122/1534`、`ui/drag_targets.gd:74`、`ui/keyboard_input.gd:171`、`ui/quick_release_bar.gd:155`、`ui/release_details.gd:53`、`ui/mana_flask.gd:23` |

### 0.3 人的裁定（2026-09-15）

原话："这就没什么要想的了，按需就好。"本片只做"按需构建文案"这一条路，并排除：

- **不做跨提交缓存**：`card_texts` 含费用、施法概率、可达性，属规则结果，撞"不跨提交缓存规则结果"硬线。
- **不做 delta／状态脏跟踪**：会引入第二个真相源，违反"派生状态从真实实例计算、不维护会失同步的副本"，
  且回滚与读档都要跟着处理。
- **不做惰性代理**：不得让 View 变成不可逐字段比对的对象。
- **不给 `get_view` 加"显示需求"参数**：那等于让 UI 指示投影内容，边界会糊。

### 0.4 硬边界（违反即未完成）

- 按需只影响投影内容：不改判定、随机、存档、快照格式、候选资格与候选 ID、`dispatch` 语义、事务与回合。
- 不新增常驻缓存：跨调用保留的任何投影内容都算违规；同一次只读调用内的复用不受此限。
- View 仍是纯数据、可逐字段比对：不出现惰性对象、函数值或引用外部状态的占位。
- 不改任何玩家可见文案本身：按需取回的字符串必须与旧路径逐字节相同。
- 不新增第三方依赖；除经人批的 `core/copy_router.gd`（§10 第 5 条）外不新增生产源码文件。
- 收口阶段（§11）不重命名、不重排、不做风格统一、不夹带措辞改动；原入口一律保留为薄别名（§11.6）。
- 不动 `escape_preview`：其作用域内的命中率复用属装备查询片（`docs/equipment-query-seam.md` §1／§3），
  其**按需化已判归装备片后续批次（未排期）**（见 §10 第 8 条）；不动 UI 响应路径与节键。

## 1. 三个入口与一个生成函数

### 1.1 生成函数（唯一实现）

`core/card_effects.gd`：`static func text_entry(g, type: String, uid: String = "") -> Dictionary`
——正文 = 现 `core/game_view.gd:302-305` 的四步（`face_texts` → `face_costs` → `merge(metadata)` →
可能的 `casting`）。判据：全仓只有这一处构造这四步；§1.2／§1.3／§1.4 三条路径都必须经由它。

### 1.2 入口一：`get_view().card_texts` = 界面固有显示集合 S

S 按 §0.2 的"显示一张卡面的入口"**逐条取源再取并集**；只允许用本次 View 已经算出的数据正向投影，
**不得为收集 S 新增规则查询**（允许把纯投影局部量提前算出，只为取类型；不得给 `get_view` 加参数）：

| 来源 | 取值 |
| --- | --- |
| 手牌 | `state.hand` 每张牌的 `type`（uid 变体走 `card_instances`） |
| 保留行 | 同手牌 |
| 奖励三选一 | `state.reward_options` |
| 休息选牌 | `state.rest_cards`（候选见 `core/game.gd:1732-1735`） |
| 出发选牌 | departure 面板条目 `type`／候选 `payload.type`（`core/departure.gd:141`） |
| 事件卡选项 | `view.room_event` 卡牌选择项的 `type`（`ui/event_screen.gd:117`；`payload.type` 为兜底） |
| **商店买卡** | `view.shop.stock` 中 `kind=="card"` 行的 `type`（`core/room_services.gd:218`、`ui/shop_screen.gd:46-47`） |
| 其余会显示卡面的候选 | 候选 `payload.type`：`payload.has("type")` 且值 ∈ `Cards.Rules.SPECS`（注册卡牌），非卡牌（attack／item／relic／tool）被注册表过滤掉 |

- **反例（测绘已证实，必须写进实现）**：商店买卡的候选 payload 只有 `{"kind":"service","op":"take","index":…}`
  （`core/room_services.gd:72-79`），**没有 `type`**；只扫候选 payload 会漏掉这个牌型，表现为商店卡面缺失
  （缺失而非降级）。S 必须覆盖 §0.2 中"归属 = S"的每一条入口。
- 不计入 S（走 §1.3）：抽／弃／牌堆整摞、能力区、牌堆浏览、商店去卡；图鉴不进 S（§0.2）。
- 幽灵卡（打出）不在 S（投影期不可知），走 §3 现场补算并留记录。
- 新增显示入口时必须同步补 S 的推导；判据是 §5.3 的 `ui.projection_misses` 为空（幽灵卡除外）。

`card_instances`：只保留 `state.hand` 中命中现判据（`core/game_view.gd:297`：`damage_growth`／
`hannya_stage`）的 uid。
`deck_list`（`:288-291`）：**移出 View**——全仓无 UI 读取点，仅 `tests/graduate_certificate_cases.gd:35`；
改由 §1.3 提供同值数据（范围确认见 §10 第 4 条）。
除键集合收窄外，`card_texts`／`card_instances` 的条目内容与键序不变。

### 1.3 入口二（全量，独立于 `get_view`）

`game.live_card_text_set(cards: Array) -> Dictionary`

- 输入：`cards=[{"type":String,"uid":String}]`（`uid` 可缺省）。
- 返回：`{"texts":{type:entry},"instances":{uid:entry}}`，每项按 §1.1 现算，容器全部新建。
- 消费方：牌堆浏览（`ui/main.gd:1841-1844`、`ui/deck_browser.gd:23-24`）、商店去卡
  （`ui/shop_screen.gd:154-156`）、测试 oracle（§5）。图鉴的显示来源不改（保持 `live_state=false`）。
- 不得经 `get_view` 参数化实现；`get_view` 不得调用它（只共享 §1.1 生成函数）。

### 1.4 入口三（单条，显示时补算）

`game.live_card_text(type: String, uid: String = "") -> Dictionary`——对任意注册牌型（含
`encyclopedia_hidden`）都必须返回条目；同键内容与 §1.2、§1.3 逐字段相等。

### 1.5 候选 `detail` 按需

**组范围（本片只做这一组）**：`core/card_effects.gd:667-730` `Cards.candidates` → `target_candidate`
产出的 **card 目标候选组**（`payload.kind=="card"`：自由面／冲开捕缚／多段目标），即实测 18.9ms／130 条的全部。
其余组（attack／calm／flow／posture／wall／retain／route／reward／rest_service／service／prison／item／
event／departure）保持预生成；理由与代价见 §9 假设 3。

- `core/game.gd:1667-1695` `_candidate` 内的 detail 组装抽成同一函数（eager 路径与新入口共用）。
- 新入口：`game.candidate_detail(candidate: Dictionary) -> String`；对**当前 View 的候选**必须逐字节
  等于旧 `candidate.detail`。
- card 目标候选的字典**不再带 `detail` 键**；其余组照旧带。
- 写路径不读 detail（`core/game.gd:2096-2138` 只用 `payload`／`cost`／`mana_payment`／`valid`／`reason`），
  候选 ID = `JSON.stringify(payload)`（`:1695`）不变。
- 表达式点与包装（§0.2 实测 86）：本组由 `target_candidate`（`core/card_effects.gd:653`）唯一产出；
  `_candidate` 的其余表达式点（`core/game.gd` 40 + 其余模块 31）与另两个转发包装
  （`Prison.add`、`paid_candidate`）保持预生成，本片不得改它们的 detail 组装与传参。
- 不得改 detail 的文案与可见性规则（含 `ui/main.gd:802-814` 的短原因映射、`_action_row` 的显示条件）。

## 2. 接口清单与语义

| 接口 | 输入 | 返回 | 谁能调 | 信任依据 |
| --- | --- | --- | --- | --- |
| `get_view().card_texts` | — | S 键的条目（纯数据，可逐字段比对） | 全部只读消费方 | 与 §1.4 同键条目逐字段相等 |
| `get_view().card_instances` | — | hand uid 的条目 | 同上 | 同上 |
| `game.live_card_text(type, uid="")` | 任意注册 type | 全新 Dictionary | UI 显示边界、测试 | §6 场景 1 |
| `game.live_card_text_set(cards)` | `[{type,uid}]` | 全新 `{texts,instances}` | 牌堆浏览、商店去卡、测试 | §6 场景 4 |
| `game.candidate_detail(c)` | 当前 View 的候选 | String | UI 显示边界、测试 | §6 场景 5 |

共同语义：

- 只读：不写 `state`、不推进随机、不改 `state.version`、不产生日志与事件、不进存档与快照。
- 返回隔离：每次调用返回新容器；调用方可以改写返回值，不影响 View 与后续调用。
- 判定按字段比对，不按 JSON 字符串顺序；`texts`／`instances` 的键序不影响语义。
- 陈旧输入：`candidate_detail` 只对"当前 View 的候选"承诺与投影一致；对陈旧候选（旧 `ActionIndex` 的
  `old_action`）允许按当前 state 重算，显示点按 §3 记录，不承诺与旧投影相同。

## 3. 安全网（缺失即补算并留记录）

- 取用点唯一 helper（都在 `ui/main.gd`）：
  - `card_entry(type, uid="") -> Dictionary`：命中 `view.card_texts`／`view.card_instances` 即用；
    未命中 → `game.live_card_text(type,uid)` 并在 `ui.projection_misses` 追加记录。
  - `detail_of(candidate) -> String`：`candidate.detail` 存在即用；缺失 → `game.candidate_detail(candidate)` 并记录。
- 除这两个 helper 外，UI 全仓不得直接读 `view.card_texts[…]`、`view.card_instances[…]`、`c.detail`；
  含 `ui/drag_targets.gd:74` 这种 `.get("brief", c.detail)` 的**预求值**写法（GDScript 会先算默认参数，缺键即崩）。
- 记录：`ui.projection_misses`，元素 `{"point":String,"key":String,"view_version":int}`；每
  (point,key,view_version) 至多一条；**清空时机是"`ui.view` 被替换（新 View 赋值）"，不是"version 数字变化"**；
  `view_version` 只是诊断标签，**不得当缓存键或失效键**（既有禁令见 `docs/response-pipeline.md` §4.1 与
  `docs/equipment-query-seam.md` §3），也不得据它判定任何渲染内容的新旧；
  不渲染、不进日志／存档／快照、不做成计数器。
- 允许的"没省到"：`ui/card_motion.gd:65` 的打出／抽牌幽灵卡（该 type 在投影时不保证在 S 内）。
- 禁止：静默空白、静默回落到目录基础文本（现 `ui/main.gd:854` 的 `.get(type,{})` 正是该风险）、
  用 helper 存第二份跨调用缓存。

## 4. 分批（每批一个 oracle 判据，可独立完工）

执行顺序：**B0（前置，§4.1）→ §11 收口（R0…R6）→ 本表的 B1…B3（按需）**。本表只覆盖按需阶段；
收口阶段的批次与判据见 §11.5。每批单独跑该批套件与该批 UI 套件；不得把前一阶段或前一批的绿色
拼进下一批的结论。

| 批 | 改动 | 该批 oracle（§5） | 红了怎么归因 |
| --- | --- | --- | --- |
| B0 前置（接入点先行） | §1.1 生成函数 + §1.4 单条入口 + §3 helper／记录上线；**只改**三处会崩的取用点（§4.1）；S 与候选 detail 此时**不收窄** | §5.1 的 B0 判据（View 与旧基线**原样全等**，含 6 哈希）+ 场景 0（缺键不崩） | 与基线不同 → 生成函数或 helper 改写走样，回到该取用点比对 |
| B1 固有集合 | §1.2 S 收窄 + `card_instances` 收窄 | 场景 1（卡面部分）+ 场景 3（`card_texts`／`card_instances` 部分） | 先看差异键是否 ∈ S：∈ S 而值不同 → 生成函数或 S 推导错；∉ S 且被删 → 收窄越界；∈ 应显示来源却不在 S → §1.2 漏源（如商店买卡） |
| B2 全量入口 | §1.3 `live_card_text_set` + `deck_list` 移出 + 三个消费方迁移 | 场景 4 | 键集合差异 → 调用方 rows 组装错；同键不同值 → 生成函数错 |
| B3 detail 按需 | §1.5 + `game.candidate_detail` + `detail_of` 铺到全部候选 detail 取用点 | 场景 5 + 场景 3（候选部分） | 打印首个差异路径（候选 id／payload.kind）即归属；某 kind 报错 → 该 kind 未走共用组装函数 |

每批单独跑该批套件与该批 UI 套件，红了按本表"归因"列先分类再改代码。

### 4.1 B0 必改的三处（现在是"缺键即崩"，不是降级）

| # | 位置 | 现状 | B0 后的要求 |
| --- | --- | --- | --- |
| 1 | `ui/main.gd:2051` | 唯一无 `.get` 的硬索引：`view.card_texts[c.payload.type].face_names[…]` | 走 `card_entry()`；缺键补算并记录；缺到无法补算时保留原文案回退，**不报错、不空白** |
| 2 | `ui/main.gd:709`、`ui/main.gd:1534`、`ui/drag_targets.gd:74` | `c.get("brief", c.detail.trim_suffix("。"))` 型：**默认参数立即求值**，即使 `brief` 存在也会先碰 `detail`（`drag_targets.gd:74` 同型且已预求值） | 改为先判 `brief`，再走 `detail_of()`；可见文案逐字段不变 |
| 3 | `ui/main.gd:1179` | 直接读 `view.hand` 行的 `face_names[…]`，把 metadata 合并结果当**第二份卡面文案**用 | 走 `card_entry()`（或等价安全取用）；可见文案逐字段不变 |

判据：**可见文案逐字段不变 + 缺键不再崩**。构造夹具用测试侧复制的 View（删掉指定 `card_texts` 键／去掉
card 组候选的 `detail`），渲染对应节，断言无引擎错误、文本 == 基线期望、`ui.projection_misses` 有具名记录。

## 5. oracle（三条，必须换判据）

旧基线（`docs/equipment-query-seam.md` §8.2 的 6 个 `view_sha256`／`candidates_sha256`）在按需落地后
**立即失效**，不得再当"整体相等"用；本片改判：

### 5.1 基线复算（开工第一步）+ B0 判据

未改源码、§5.5 夹具，复算 6 个哈希；一致才作为配对基线，不一致以复算值为准并记录差异（不得改基线迁就实现）。
同时把 6 个 View 的**完整 JSON** 落到 `build/ondemand-copy-<date>/baseline/`（mask 判定需要原始值，哈希不够）。

**B0 判据（此时 S 与候选 detail 都未收窄）**：新 View 与基线 View **逐字段全等**（可直接用旧
`view_sha256`／`candidates_sha256` 当判据，不需要 mask）；另加"缺键不崩"构造夹具（§4.1）：
测试侧复制 View、删除指定 `card_texts` 键或 card 组候选的 `detail`，渲染 `ui/main.gd:709/1179/1534/2051`
与 `ui/drag_targets.gd:74` 涉及的节，断言无引擎错误、文本 == 基线期望、`ui.projection_misses` 有具名记录。

### 5.2 判据① 按需 == 全量

- 卡面（**三路相等**）：对**全部注册牌型** `type`：`game.live_card_text(type)` 与
  `game.live_card_text_set([{type}]).texts[type]` 逐字段相等；`type ∈ S` 时还必须与 `view.card_texts[type]`
  逐字段相等。
- **实例字段是包含关系，不是相等关系**（实测差异恒定）：`game.live_card_text(type,uid)` 是四步
  （`face_texts → face_costs → merge(metadata) → casting`），而 `view.card_instances[uid]` 是两步
  （`face_texts(uid) + metadata(uid)`）。因此断言写成：`view.card_instances[uid]` 的**每个字段与
  `live_card_text(type,uid)` 的同名字段逐项相等**，且两者键集合之差**只允许** `face_costs`（恒有）与
  `casting`（仅施法牌）两个**新增键**；**不得要求整字典相等**。
- **`card_instances` 维持现状不动**：不为了补齐 `face_costs`／`casting` 去做无收益的改动，也不去撞 §5.1 的全等基线。
  实现侧断言（`tests/architecture_cases.gd`）已按上面两句写，措辞不得改回"相等"。
- 候选：对基线 View 的**每个**候选：`game.candidate_detail(c)` 与基线 `c.detail` 逐字节相等
  （card 组走新入口，其余组走 eager 值；两者都必须相等，同时证明共用组装函数没走样）。

### 5.3 判据② 端到端不缺失

对 §0.2 的每个"可见"显示点，在真实夹具下断言渲染文本 == 由基线 View 推出的期望文本，且
`ui.projection_misses` 为空；幽灵卡按 §3 允许一条具名记录，但文本必须是实时值。
覆盖路径至少：手牌卡面、保留行、奖励三选一、休息选牌、事件卡选项、出发选牌、拖放落点提示（含
`ui/main.gd:2051` 的右键切换提示）、身体详情里的选中卡详情与 `_action_row`、牌堆浏览、商店去卡、打出幽灵卡。

### 5.4 判据③ 被显示子集与旧基线一致（mask 定义）

mask 只按**显式键集合**删除，不得按"新视图有什么就比什么"：

- `card_texts`：删除键 ∉ S；保留键必须与基线逐字段相等。
- `card_instances`：删除 key ∉ 手牌 uid；保留 key 必须与基线逐字段相等。
- `candidates[*].detail`：删除 card 组候选的 `detail`；其余候选的 `detail` 必须与基线逐字节相等。
- `deck_list`：整键删除（B2 后）。
- 删除键集合必须**恰好等于**声明的期望集合（多一个或少一个即失败）。

判定：`sha256(JSON.stringify(mask(new_view))) == sha256(JSON.stringify(mask(baseline_view)))`，
且逐字段比对无差异；两个 mask 用同一份声明集合，声明集合必须打印在 oracle 日志里。

### 5.5 夹具与产物

夹具沿用 `docs/equipment-query-seam.md` §8.1 的 battle／departure × 0／12／26 件序列（在既有测试文件内
具名构造，不新建夹具文件）；基线脚本、baseline JSON、oracle 日志只放已忽略的 `build/ondemand-copy-<date>/`，
用完删除，入库的只有摘要。

**基线可复现性（返工用，勿省）**：mask 判据要的是基线 View 的**原始值**，哈希不够。
摘要里必须记录：①开工时 HEAD 的 commit id；②基线捕获脚本在该 commit 下的路径；③声明集合与 6 个哈希。
文件删除后若需重取基线，用该 commit 的临时 worktree 重跑同一脚本（不得改基线迁就实现，也不得把
`build/` 内容入库）。同一条也适用于装备片的 §8.2 基线（其哈希可由同一 commit 复算）。

## 6. Gherkin（场景名 → 既有分类的具名 check）

不新建流程文件、不新建看板；用具名函数加入既有 case 文件，复用现有夹具与真实输入助手。
场景 0 属前置批 B0（§4.1），场景 1–6 属按需批 B1–B3；收口批的场景见 §11.5。

0. `copy_missing_key_never_crashes`（`tests/display_ui_cases.gd`（`display`）、
   `tests/target_sidebar_ui_cases.gd`（`targeting`））
   - Given 测试侧复制的 View（删掉指定 `card_texts` 键、去掉 card 组候选的 `detail`；不改 `game`）；
   - When 渲染 `ui/main.gd:709/1179/1534/2051` 与 `ui/drag_targets.gd:74` 涉及的节；
   - Then 无引擎错误、文本 == 基线期望、`ui.projection_misses` 有具名记录（不是静默空白）。
1. `copy_fixed_set_matches_full_entry`（`tests/card_text_cases.gd`，经 `tests/card_power_cases.gd:21` 运行，
   规则分类 `card_power`）
   - Given 全部注册牌型 + §5.5 夹具；
   - When 对每个 type 取 `live_card_text`／`live_card_text_set`／`view.card_texts`；
   - Then 三者逐字段相等；∈ S 的 type 全部在场，∉ S 的 type 不在 `view.card_texts`；状态、随机、version 不变。
2. `copy_projection_masked_baseline`（`tests/architecture_cases.gd`，规则分类 `architecture`）
   - Given §5.1 的基线 JSON 与 §5.4 的声明集合；
   - When 对 6 个夹具取新 View 并 apply mask；
   - Then 与基线 mask 哈希相同、逐字段无差异、删除键集合恰好等于声明集合。
3. `copy_display_points_have_no_misses`（`tests/display_ui_cases.gd`（`display`）、
   `tests/target_sidebar_ui_cases.gd`（`targeting`）、`tests/keyboard_ui_cases.gd`（`keyboard`））
   - Given 战斗夹具（0／12／26 件）与鼠标／键盘真实输入；
   - When 手牌翻面与打出、拖牌看落点提示、键盘悬浮候选；
   - Then 卡面与详情文本 == 基线期望；`ui.projection_misses` 为空（幽灵卡按 §3 计一条具名记录）。
4. `copy_full_entry_equals_baseline`（`tests/interface_ui_cases.gd`，UI 分类 `interface`，复用既有
   `deck_browser` 助手 `:303`；规则侧同场景落在 `tests/card_text_cases.gd`）
   - Given 卡组／抽牌堆／弃牌堆／能力区与商店去卡夹具；
   - When 打开牌堆浏览与去卡服务；
   - Then 每张卡显示文本 == 基线 `card_texts`／`card_instances` 对应值；`live_card_text_set` 与基线逐字段相等；
     `ui.projection_misses` 为空。
5. `copy_candidate_detail_on_demand`（`tests/architecture_cases.gd`；UI 侧 `tests/target_sidebar_ui_cases.gd`）
   - Given 基线 View 的全部候选；
   - When 逐个 `game.candidate_detail(c)`，再在界面显示 card 组详情；
   - Then 与基线 `detail` 逐字节相等；card 组候选字典无 `detail` 键且界面文本不变；写路径未受影响
     （`dispatch` 成功一次、候选 ID 与基线一致）。
6. `copy_ghost_fallback_recorded`（`tests/display_ui_cases.gd`，UI 分类 `display`）
   - Given 打出一张会飞出的牌；
   - When 幽灵卡生成；
   - Then 文本为实时值、`ui.projection_misses` 恰有一条具名记录、不进存档／快照、View 内不出现该记录。
7. `copy_route_bytes_unchanged`（`tests/architecture_cases.gd`，规则分类 `architecture`；收口批 R0–R6 的批判据）
   - Given §5.5 夹具与基线 View 的全部候选；
   - When 逐个候选分别走三条路取文案：①迁移前的直传字符串（生产者未迁移时）②descriptor 经
     `core/copy_router.gd` 渲染 ③基线 View 里冻结的 `detail`；
   - Then 三条路逐字节相等；`copy_router.categories()` 覆盖该批已迁移的类别且无未知 kind；
     未迁移生产者走直传通道，行为与基线一致；`copy_router_failures` 为空；
     红时按 §11.5 的四类归因（文本内容／候选数量顺序／缺 detail／未知 kind）先分类再改代码。

## 7. 验收程序（validator 用；agent 可运行）

宿主入口：`tests/test_game.gd` + `tools/check.ps1`；界面证据用 `tests/ui_smoke.gd`，操作必须是真实 viewport
输入（复用既有 `move_mouse`／`mouse_button`／`flip`／`start_drag`／`release_target` 等助手）。
测试存档隔离（`ui.persistence_enabled=false`）；不默认截图。

1. 范围预检（不算通过）：
   `& tools/check.ps1 -Suite card_power,architecture,casting,card_growth -Impact -ListOnly`
   `& tools/check.ps1 -UIOnly -UISuite display,targeting,keyboard,interface,card_power,card_growth,shoulder,torso_binding -ListOnly`
   → 输出 `PLAN ONLY:` 且列出上述分类；缺一即范围问题。
2. 规则门：`& tools/check.ps1 -Suite card_power,architecture,casting,card_growth -Impact -TimeoutSeconds 900`
   → 目标判据：退出码 0；输出含 `RULE SCOPE:`、每个 `SUITE RESULT: PASS <name>`、`PASS: N assertions`；
   `summary.json` 的 `status=passed` 且 `before==after` 指纹（`source_changed` 不算通过）。
   **既有阻塞项豁免写法**：若失败集**恰好等于**§8 表中的两项既有阻塞项（`card_power` 的 5 条 `witch_*`、
   UI 的 `shoulder` 2 条 + `torso_binding` 1 条），则记录为"本片判据通过 + 既有阻塞项未通过"：
   退出码与 `status` 允许为红，但必须在证据里给出阻塞项的日志 id，并证明本片新增／迁移的断言与其余套件全绿。
   失败集多出任何一条，即本片未完成。**不得**为此把 `card_power` 从命令里删掉。
3. 界面门：
   `& tools/check.ps1 -UI -Suite architecture -UISuite display,targeting,keyboard,interface,card_power,card_growth,shoulder,torso_binding -TimeoutSeconds 900`
   → 判据同第 2 条（同样适用既有阻塞项豁免写法）。`shoulder`／`torso_binding` 是**故意列进来**的：
   它们正是 §8 表里 3 条既有 UI 阻塞项的所在套件，列上才能把"确实红在哪、红在谁身上"写进证据，
   而不是把红的套件从门里拿掉；本片涉及的 `display`／`targeting`／`keyboard`／`interface` 必须全绿。
   不默认截图。
4. 人的路径证明（判据是套件布尔 check，按顺序操作界面）：
   - 战斗中打出／翻面手牌：卡面文本与实时装备状态一致，幽灵卡文本为实时值；
   - 打开卡组一览：每张牌文本与手中同型牌一致；商店去卡显示的牌文本与牌堆一致；
   - 拖牌到身体：落点提示与选中卡详情文本与改动前一致；键盘悬浮同一候选：tooltip 一致；
   - 奖励三选一／休息选牌／事件卡选项／出发选牌：卡面文本与基线一致；
   - 商店买卡：卡面文本与实时装备一致（该牌型不在候选 payload 里，是 §1.2 的已知漏项回归点）；
   - 图鉴：文本未变（`live_state=false` 保持），且打开图鉴不产生 `projection_misses`；
   - 人为缺键（测试侧复制 View 后删键）：基本行动栏、身体详情右键切换提示、工具目标卡片、拖牌提示
     不报错、不空白，走补算并留下记录。
5. 归属判定：失败原因分"实现代码／测试脚本／环境／程序本身"；原因不确定就保持未分类上报，不自动改产品代码。
6. 证据：`build/checks/<id>/check-rules.log`、`check-ui.log`、`summary.json`；结果与域写 `docs/verification.md`
   （validator 负责，不在本文件宣称通过）。

## 8. 完成定义（Definition of Done）

命令（每批一次 + 收尾一次，不无故重复；每个阶段各自收尾，不得用前一阶段的绿色拼后一阶段）：

```powershell
# 前置批 B0 与收口批 R0…R6：该批涉及的模块套件（§11.5 表列出的套件名）
& tools/check.ps1 -Suite <该批模块套件> -TimeoutSeconds 600
# 按需批 B1…B3
& tools/check.ps1 -Suite <B1…B3 的批套件> -TimeoutSeconds 600
# 两阶段各自的收尾门（收口阶段收尾也要跑这两条；含既有阻塞项所在套件，见下）
& tools/check.ps1 -Suite card_power,architecture,casting,card_growth -Impact -TimeoutSeconds 900
& tools/check.ps1 -UI -Suite architecture -UISuite display,targeting,keyboard,interface,card_power,card_growth,shoulder,torso_binding -TimeoutSeconds 900
```

必过的场景：§6 的 0–7 全部具名 check（场景 0 = B0，场景 7 = 收口批）；收口批另加 §11.5 的
`copy_route_bytes_unchanged`（逐候选逐字节）与"路由直传通道 = 原路径"检查；被本片触及的既有断言
（`tests/card_text_cases.gd` 全类型读取、`tests/casting_cases.gd:200`、`tests/hannya_ui_cases.gd:29/34`、
`tests/card_power_ui_cases.gd:656`、`tests/encyclopedia_ui_cases.gd:221/224`、
`tests/concentration_cases.gd:33`、`tests/graduate_certificate_cases.gd:35`，以及 tests 中全部
`.detail` 读取）按 §2 的新入口 1:1 迁移后仍通过，期望值与断言语义不变。

**既有阻塞项（在 HEAD、未改源码即失败；本片必须如实登记为未通过／未验证，不得据此改写、放宽或删除任何断言，
也不得把"整片绿"当成完成条件）**

| 阻塞项 | 证据 | 归因 | 本片处理 |
| --- | --- | --- | --- |
| `card_power` 5 条 `witch_*` 断言在 HEAD 即失败 | 协调者复跑日志 `20260915T163500673-34468`（5 失败／1781），命中 `tests/card_power_cases.gd:85` 的 `CARD reward membership follows rarity and explicit gift exclusion`；**该日志尚未登记进 `docs/verification.md`，落地时须补登记** | `core/witch_expansion.gd` 的 `REWARDS` 与 `rules.SPECS.rarity`（根因在卡池注册，非本片引入，本片不修） | 登记为未通过；本片自有的具名 check 单独出结论 |
| `shoulder` UI 2 条 + `torso_binding` UI 1 条在 HEAD 即失败 | `docs/verification.md` 装备片条目：`20260915T160616347-54344`（19 项、2 错）、`20260915T160711923-52452`（11 项、1 错：`BIND UI attachment and independent durability are visible`） | `ui/release_details.gd:35-38`（v0.17 `e635bf5` 起；既有 UI 文案渲染 vs 测试期望，公共提交上同样复现，归属未定） | 同上；不得因它是 UI 文案问题就顺手改渲染或改期望 |

- 完成判据改为：**§6 场景 0–7 与该批被触及模块的断言全部通过**；上表两项按"既有阻塞项／未通过"写进
  `docs/verification.md`（含日志 id），并在总结里明确它们是**先于本片存在**的失败；
  `-Suite card_power` 的套件结论在这些断言修好前**允许为红**，但本片新增／迁移的断言不得在其中。
- 禁止：把阻塞项从必跑命令里删掉、把 `summary.json` 的失败说成通过、修改或删除红断言换取绿灯、
  或在报告里宣称完整回归。

必有的证据：§5.1 基线复算记录（6 哈希 + baseline JSON）、每批一次的 oracle 比对记录
（按需：三条判据 + mask 声明集合；收口：逐候选逐字节 + 该批模块的差异路径）、收尾两份 check 日志 +
`summary.json`；`summary.json` 判读按 §7 第 2 条：`status=passed` 最好，含既有阻塞项时为
`status=failed` 但失败集必须恰好等于 §8 的两项（另标注"本片判据通过 + 既有阻塞项未通过"）；
`source_changed`／`plan` 不算通过；`build/` 数据未入库。

算未完成（任一）：

- 任一必跑套件未执行、未知或被跳过；`summary.json` 为 `source_changed`／`plan`；
  或为 `failed` 而失败集**不止**上表两项既有阻塞项（即本片引入的失败混在里面）；
  把既有阻塞项当成通过、或把它们从必跑命令里删掉；
- 用旧版本的通过拼接最终结论；删／弱化既有断言换取绿灯；把"全类型等价"断言直接删除而不是迁到
  `live_card_text_set`；
- 出现跨调用缓存（含 UI 侧第二份文案副本）、惰性对象，或给 `get_view` 加显示需求参数；
- 显示点绕过 helper 直读投影字段；缺失时静默空白或静默回落目录基础文本；
- **收口阶段的重命名、重排、风格统一、措辞改动**（§11.6 第 1、5 条），或把原入口签名改成不可直传；
  收口批次做完后代码不能跑、不能测（§11.6 第 3 条）；
- 新增生产源码文件（§11.6 允许的路由模块除外）或第三方依赖；改判定／随机／存档／快照／候选资格／
  候选 ID／可见文案；
- 实现 `escape_preview` 按需化（未经授权：已判归装备片后续批次、未排期，见 §10 第 8 条）或改 UI 响应路径与节键；
- 以耗时数字或"应该更快"作完成判据；宣称完整回归。

## 9. 假设与最可能爆掉的假设

1. **最可能爆：S 漏掉一个真实显示点。** 已经实测出一例：**商店买卡的候选 payload 没有 `type`**
   （`core/room_services.gd:72-79`），牌型只在 `view.shop.stock` 行上，只扫候选会漏（缺失而非降级）。
   幽灵卡是已知第二例（§3 允许记录）。缓解：§1.2 的"按显示入口逐条取源"+ §3 helper 唯一入口 +
   `ui.projection_misses` + §5.3 端到端判据；出现未登记记录即 S 漏项。
2. **陈旧候选的文本会变。** 旧路径把 `detail` 冻在候选里，按需入口按当前 state 重算；测试里 `old_action`
   （陈旧 `ActionIndex`）显示路径可能因此得到不同文本。缓解：§2 明确不承诺陈旧一致 + §5.3 只对当前 View 断言；
   受影响测试逐处改判据（不得删断言）。
3. **把"收口范围"误当成"按需范围"。** 收口（§11）按模块覆盖全部 86 个 detail 表达式点（结构调整、行为不变）；
   按需（§4 B3）只让 card 目标组不再预生成 `detail`。若顺手把全部候选改成按需，等于一次推入
   tests 的 98 行 `.detail` 迁移，并撞上假设 2；属重新切分，不是本片。
4. **`deck_list` 移出**是 View 字段形状变化（唯一读取方是 `tests/graduate_certificate_cases.gd:35`）。
   若人不同意移出：B2 只加全量入口、`deck_list` 保留原样（收益变小，三条判据不变）。
5. **`worn_count` 不做去重**：固定集合落地后其调用量随按需同比例下降；单独去重要改
   `face_texts`／`metadata`／`base_damage` 签名且收益未单独测量，列为后续独立项，不在本片。
6. **测试迁移面（数字以复算命令为准）**：`tests` 中 `.detail` 命中 **98 行／45 文件**
   （`rg -c '\.detail' tests/` 求和；按出现次数 114），`view.card_texts` 13 行、`view.card_instances` 1 行、
   `view.deck_list` 1 行；迁移即同一函数、同一期望值换入口，禁止借迁移改弱期望。
7. **收口不省时。** 收口批的判据只有逐字节相等与结构可枚举；不得以耗时或"调用次数减少"宣称收益。
   收益路径是按需批（§11.1）。
8. **顺序假设**：B0 → 收口（§11）→ 按需（§4），且三段都与邻接表片串行；
   `core/game.gd`／`core/game_view.gd`／`core/card_effects.gd` 被多片重碰，并发即不可归因。

## 10. 范围问题（待协调者转人）

1. **授权文件**
   - 前置批 B0 与按需批（§4）：core `core/game.gd`、`core/game_view.gd`、`core/card_effects.gd`；
     ui `ui/main.gd`、`ui/drag_targets.gd`、`ui/keyboard_input.gd`、`ui/release_details.gd`、
     `ui/quick_release_bar.gd`、`ui/mana_flask.gd`、`ui/deck_browser.gd`、`ui/shop_screen.gd`。
   - 收口批（§11）：上列 core 三个模块 + 含 detail 表达式点的 `core/departure.gd`、`core/room_events.gd`、
     `core/relic_bundle.gd`、`core/room_services.gd`、`core/demo_exit.gd`、`core/mana_flask.gd`、
     `core/prison.gd`、`core/prison_space.gd`、`core/consumables.gd`、`core/witch_character.gd`、
     `core/witch_expansion.gd`，**以及新增的 `core/copy_router.gd`（已授权并落地，R0 `7f1c748`；见第 5 条）**。
   - tests：既有 `tests/*_cases.gd` 追加具名 check 与 §8 的迁移。
2. **新增只读入口**：`game.live_card_text`、`game.live_card_text_set`、`game.candidate_detail`
   三个公有只读方法 + `Cards.text_entry` 静态生成函数；不改已有接口签名。
   **现状（2026-09-15）**：`live_card_text`（B0 `cc5e8f0`）与 `candidate_detail`（R0 `7f1c748`）已授权并落地；
   `live_card_text_set` 未落地（属按需批 B2）。落地后须同步 `docs/response-pipeline.md` §0 事实行（已写好豁免写法）。
3. **文档修订（协调者／规划者执行；现状已就位，落地时只剩一处同步）**：
   - `docs/response-pipeline.md`：§0 现状行已改为**部分既成事实**（B0／R0 两个入口 + `live_card_text_set` 仍为预告）
     并保留"不属 `get_view` 白名单、不得经 `get_view` 参数化"；§2.2 已加"**新入口不属于白名单**"；
     §6.1 的"越界待批"已改指向本契约；§5 第 3 条已标**已完成**（AGENTS 三行索引、126 行／7896 字节）。
     本片落地后只需再把 `live_card_text_set` 从句中"未落地"挪进"已落地"。
   - `docs/equipment-query-seam.md`：§0.3／§9／§10 结论／§13 算未完成已把"押后"改为**指向本文件**，
     并注明 `escape_preview` 按需化**已判归装备片后续批次（未排期）**；§8.2 已加"跨契约有效期"说明
     （其整份 View 哈希在本片落地后改用本片 mask 判据）。
   - `spire-godot/AGENTS.md` 文档入口表的那一行已由协调者加入
     （现行文字：`| 玩家可见文案的收口与按需 | docs/ondemand-copy.md |`），以仓库现状为准，勿重复添加。
     （2026-09-16 注：`spire-godot/AGENTS.md` 已在 `ee9c54c` 合并进仓库根 `AGENTS.md`，该路径不再存在。）
4. **待人确认**：`deck_list` 是否移出 View（§9 假设 4）；按需批 B3 组范围是否只做 card 组（§9 假设 3）；
   收口批是否按 §11.5 的模块顺序执行（人已定"先收口"，顺序待确认）。
5. **已决（协调者 2026-09-15）：允许新增 `core/copy_router.gd`，且已随 R0 落地（`7f1c748`）。**
   原冲突（旧 §0.4"不新增生产源码文件" vs"不要为了不新增文件把路由塞进已经很大的 `core/game.gd`"）
   按后者处理：§0.4 的措辞已改为"除 `core/copy_router.gd`（经人批）外不新增"，本项不再是待批项；
   后续只允许在该文件上增删类别与片段，不得再新增文件。
6. **实现顺序**：邻接表片 B4–B9 完成之后 → B0 → §11 收口 → §4 按需；本片代码不得与邻接表片并发修改 `core/`。
7. **测绘数字的复算（供协调者核对，勿按旧数字下令）**：候选 detail 表达式点实测 **86**
   （`_candidate` 直接调用 71 + 包装调用 15：`Prison.add` 9、`target_candidate` 3、`paid_candidate` 3）；
   测绘初稿的 92／16 含 `_route_exit_candidate` 这类同名子串与包装定义行。View 外直产实测 5 处，
   其中 `core/game.gd` 的 face_text 双调用在 **:1777**（测绘初稿写 :1771）。
   复算命令：`rg -n '(?<![A-Za-z0-9_])_candidate\(' core/`、`rg -n 'Prison\.add\(|^\s*add\(out' core/prison*.gd`、
   `rg -n 'target_candidate\(|paid_candidate\(' core/`、`rg -n 'face_text' core/*.gd`（脚本留档见 §5.5 的 build 目录）。
8. **已决（协调者 2026-09-15）：`escape_preview` 按需化归入装备片后续批次，未排期。** 理由：它是只读查询
   （不是文案），装备片的索引／作用域基建正好服务它；成本已实测 13.9ms（228 次调用、131 次真算）。
   本片与装备片现存契约都写成"**未承接 / 未排期**"的一致表述（装备片 §0.3／§9／§10 结论／§13 已同步），
   不再留成"无人承接"的空洞；两片在排期确认前都不得实现。

## 11. 文案路由收口（第一阶段；先于按需）

### 11.1 目标与性质

人的要求：**"文案先收口，不同功能的文案收到同一处路由，再谈按需。"**
性质：结构改进——生产者不再各自拼整段字符串，而是提交"这是哪类文案 + 参数"；消费侧经同一处取。
**按需（延迟渲染）只是路由的一个能力，不是第一步。** 收口批不承诺省时（§9 假设 7），
判据只有"逐字节相等 + 类别可枚举 + 未迁移者行为不变"。

### 11.2 路由接口

**生产者侧**（原签名不动，只改"第 N 个参数可以传什么"）：

- `_candidate(out, payload, label, copy, cost, mana, reason, risk, group)`：第 4 参 `copy` 既可以是今天的
  `String`（**直传通道**，行为与今天逐字节相同），也可以是 descriptor `{"kind":String,"args":Dictionary,
  "fallback":String}`。
- 三个转发包装 `Prison.add`（`core/prison.gd:220`）、`target_candidate`（`core/card_effects.gd:653`）、
  `paid_candidate`（`core/room_services.gd:52`）**签名原样不动**；它们的文案参数同样接受 String 或 descriptor。

**路由侧**（新增 `core/copy_router.gd`，全 static；是否新增见 §10 第 5 条）：

- `text(g, copy) -> String`：`copy` 是 String → 原样返回；是 descriptor → 按 `kind` 分派到注册的 builder。
- `categories() -> Array[String]`：可枚举的类别清单（测试与接手方据此核对覆盖）。
- builder 的登记方式：模块自带 builder 并在路由注册（**不要求把中文搬到路由文件**）；已存在的
  `Cards.detail`／`Services.detail`／`SelfBinding.detail`／`Hannya.detail`／`Splash.detail`／
  `BasicAttacks.cost_description`／`relic_effects.posture_detail`／`card_splash.detail` 等 8 个
  detail 构建函数原地保留，作为对应 kind 的 builder。
- 共享片段（只放实测确认的横切流程）：`two_face(type)`＝两面拼接（现有 3 处，见 §11.3）。

**消费者侧**：UI 不直连路由、不 preload `core/copy_router.gd`；只经 §2 的 `Game` 只读入口
（`live_card_text`／`live_card_text_set`／`candidate_detail`），再由 §3 的 helper 取用。

**失败／缺失的三态（必须区分，不得混同）**：

1. 直传通道（String）→ 原样返回，行为与今天一致；
2. descriptor 命中 builder → 返回该 builder 的字符串；
3. **未知 kind／无效 builder／结果类型不符** → 追加一条 `copy_router_failures` 记录（游戏实例上的独立诊断列表：
   含 kind、入口、失败点与涉事 descriptor；**不进 `state`／不进 View／不进存档／不渲染／不做成计数器**），
   返回 descriptor 自带的 `fallback`（迁移期生产者必须提供）；没有 `fallback` 时返回空值**并记录**，
   绝不允许"空白且无记录"。
**语言限制（按 GDScript 事实写，勿写成"捕获异常"）**：GDScript **无异常捕获**，builder 内部的引擎错误会
中断调用栈，**无法实现"捕获 builder 抛错"**。因此第三态只覆盖**可判定的失败**（未知 kind／无效 builder／
结果类型不符）；真正的引擎错误由测试套件当作失败处理，不再是静默空值。
该说明与 `core/copy_router.gd` 头部注释必须保持同一措辞（当前实现即此，见该文件头部"失败三态"段）。

### 11.3 descriptor 选型与实测依据

实测（脚本 `build/ondemand-copy-20260915/measure_copy.py`、`measure_repetition.py`，命令见 §10 第 7 条）：

| 观测 | 数值 |
| --- | --- |
| 候选 detail 表达式点 | 86（`_candidate` 直呼 71 + 包装调用 15） |
| 第 4 参形态 | 内联字面量 43（纯字面量 26／字面量加拼接 13／字面量＋表达式 4）、call_expr 15、variable 11、other 2 |
| 43 个内联字面量之间的复用 | **0**（43 个彼此不同的模板） |
| 全 core 字符串片段 | 1824 段，其中在 ≥2 处出现的 **60 段（≈3%）**，多为校验／日志文本 |
| 唯一成体系的跨点重复 | 两面拼接 `face_text(bound)+"\n"+face_text(free)` **3 处**（`core/game.gd:1777`、`core/room_events.gd:600`、`core/room_services.gd:41`） |
| 追加式条件分支 | `out.back().<field>=` **12 处**（`core/game.gd` 4、`core/status_view.gd` 5、`core/witch_character.gd` 3） |

**结论：descriptor 用"类别（kind）+ 参数（args）"，由路由按 kind 分派渲染；不选"模板 id + 参数"。** 依据：

1. **模板词汇表不存在**：43/43 内联字面量各不相同，全 core 片段级重复仅 ≈3%。做模板库等于把作者写好的
   整句重写成模板，改动面最大、结构收益最小，且最容易破坏逐字节判据（§11.6 第 5 条）。
2. **现有 detail 已是"整句 + 状态条件"**：12 处追加式改写 + 大量实参内三元；模板化会把条件塞进参数，
   可读性更差。
3. **真正可共享的是流程片段**，不是句子：只有两面拼接是实测到的跨点重复，抽一个片段函数即可覆盖；
   其余待实测确认再抽，禁止凭"看起来像"合并。
4. **分派式让 8 个既有 detail 构建函数原地可复用**，符合"替他整理入口、不重写他的代码"的交接口径（§11.6）。

明令禁止的另一种理解：不得为了"统一"把整段中文搬进中央模板库，也不得顺手改措辞。

### 11.4 两份卡面组装与费用双源的处置

- 现状两份：`data/encyclopedia.gd:38-44`（`Catalog.card`：静态 `Rules.energy_label`
  `data/card_rules.gd:204` + `B.card_metadata` 无实例）与 `core/game_view.gd:302-305`（实时
  `Cards.energy_label(g,…)` `core/card_effects.gd:370` + `Cards.metadata(g,type,uid)`）。
- **结论：本片不合并两份实现**。合并需要一个"静态模式"分支，会改图鉴文本，撞
  `tests/encyclopedia_ui_cases.gd:221,224` 的反向断言与"图鉴 static 语义不得改变"。
- **允许且仅允许的收口**：实时路径的卡面构造集中到 `Cards.text_entry`（§1.1）并登记为路由类别
  （`kind="card.face"` 实时、`kind="card.catalog"` 静态）；**入口在一处可见，实现仍是两份**，且本文件
  明确写出"两份、双源"的事实，避免接手方误以为已合并。
- 图鉴：`ui/encyclopedia.gd:138` 的 `live_state=false` 与那两条反向断言原样保留（§11.6 第 5 条）。

### 11.5 收口迁移分批（每批一个模块／一个片段，各自可独立回退）

| 批 | 范围 | 该批判据（oracle） | 该批要跑的套件 |
| --- | --- | --- | --- |
| R0 路由骨架 | 新增 `core/copy_router.gd` + `_candidate` 第 4 参接受 descriptor；**不迁任何生产者** | 全 View 与基线逐字段全等（含候选 detail 逐字节） | `architecture` |
| R1 pilot | `core/mana_flask.gd`(2) + `core/demo_exit.gd`(2) | `copy_route_bytes_unchanged`（全部候选 detail 逐字节）+ 未迁移模块行为不变 | 该模块的覆盖套件（判定法：在 `tests/*_cases.gd` 里 grep 模块名；R1 预期 `status`、`tower`） |
| R2 两面拼接片段 | `core/game.gd:1777`、`core/room_events.gd:600`、`core/room_services.gd:41`（同一片段，三处一起） | 三处字符串逐字节 + `two_face` 只此一处实现 | `rewards`、`events`、`services` |
| R3 转发包装 | `target_candidate`(3) → `paid_candidate`(3) → `Prison.add`(9)，一次一个 | 该包装产出的候选逐字节 + 数量与顺序不变 | `casting`、`services`、`prison` |
| R4 其余模块 | `core/departure.gd`(5)、`core/room_events.gd`(4)、`core/relic_bundle.gd`(3)、`core/room_services.gd`(3)、`core/consumables.gd`(1)、`core/witch_character.gd`(1)、`core/prison.gd`(2 直呼) | 同上 | 各自套件（`exploration`／`events`、`relics`、`shop_release`、`consumables`、`witch_character`、`prison`） |
| R5 `core/game.gd` 直呼 40 处 | 最大、且与邻接表片／按需片重碰，**最后做** | 同上 | `core`／`basic_attacks`／`pressure` 等受影响套件 |
| R6 View 外直产 | `core/witch_expansion.gd:94`、`core/card_effects.gd:606`（另两处已随 R2） | 事件日志文本与候选 detail 逐字节 | `witch_character`、`casting` |

**红了怎么归因（每批同一套，按此顺序判）**：

1. 差异是**文本内容** → 该批 builder 没有按原样搬运（先查是否夹带了措辞改动）；
2. 差异是**候选数量／顺序** → 该批改了调用次数或参数（例如 `target_candidate` 的 choices 展开）；
3. 差异是**某些候选没有 detail** → 直传通道判定错（String 被当 descriptor，或反之）；
4. `copy_router_failures` 出现未知 kind → 该批漏注册类别（不是产品缺陷，是批次未完成）。

### 11.6 交接约束（人补充；与收口同批生效）

1. **不重命名、不重排、不做风格统一。** 原有函数名与位置一律保持：`_candidate`、`Prison.add`、
   `target_candidate`、`paid_candidate`、`Catalog.card`、`Cards.face_text*` 等全部原样；只**新增**路由层与迁移点。
2. **原入口作为薄别名保留。** 迁移完成后 `_candidate(payload, detail: String)` 这类原签名仍然可用
   （走直传通道，行为与今天一致）；新路径是**可选的第二条路**，不得要求所有调用点一次改完，
   也不得让未迁移的生产者行为发生任何变化。
3. **迁移必须可中断。** 任意批次做完后代码都要能跑、能测；"过渡期共存"是真实可用状态，不是纸面设计
   （交还说明见 §11.7）。
4. **契约按交接材料写。** 每个新接口都要有"原来是什么、为什么加、怎么退回原样"；文档不写只有内部含义的
   批次号：本文的 `B0`／`B1…B3`（按需阶段）与 `R0…R6`（收口阶段）都在文内自解释，接手方不需要会话语境。
5. **不夹带。** 不顺手改文案措辞、不改判定、不合并"看起来重复但行为不同"的入口——测绘已确认
   `ui/deck_browser.gd:22-24` 的三重合并去掉会动筛选排序行为，本片不得动它。

### 11.7 "只迁了一半就交还"（接手方说明模板）

- **哪些边已收口**：以 `core/copy_router.gd` 的 `categories()` 为准（可枚举），并对照本文件 §11.5 各批的
  完成记录（结果登记在 `docs/verification.md`，不写在本文件）。
- **哪些仍是原路**：未收口的生产者按 §11.6 第 2 条继续直传字符串，行为与今天一致；按需阶段的
  B1–B3（§4）**不因收口未完成而阻塞**，但只有已收口的模块才能被按需化。
- **怎么继续**：读 §11.2 接口 → 按 §11.5 顺序挑下一个未完成模块 → 跑该批套件与逐字节判据 →
  红了按 §11.5 的四类归因。
- **怎么退回原样**：把该批生产者改回直传字符串（删掉 descriptor 构造），删除该 kind 的注册；
  其余批次不受影响（每批独立可回退）。
- 不得把"未迁完"报成"收口完成"，也不得用收口宣称收益（§9 假设 7）。
