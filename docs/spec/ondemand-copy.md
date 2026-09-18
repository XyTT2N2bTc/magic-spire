# 玩家可见文案：路由收口与按需投影契约

本文件是现行契约，分两阶段，**顺序即裁定**：先把不同功能的文案收口到同一处路由（类别 + 参数），
再做按需投影（View 只带界面固有集合，其余在真正显示时才经路由取）。
供实现者、清洗者、加固者、验收者只读消费：内部实现以代码为准，接口语义以本文件为准。
本文件不写执行结果；通过／失败／未执行只登记在验证记录（`docs/record/verification.md`）。

路径约定：不带 `spire-godot/` 前缀的源码、测试与工具路径（`core/`、`ui/`、`data/`、`tests/`、`tools/`、`build/`）
均相对 `spire-godot/`；`docs/` 相对仓库根。

## 域

- 一次 `get_view()` 里为**玩家看得见的文字**所做的投影（卡面文案、候选详情），
  以及 UI 在真正显示时才取用这些文字的只读路径。
- 不含：规则判定、随机、存档与快照、候选资格与候选 ID、`dispatch` 语义、事务与回合。
- 与另两份契约的分工：`docs/spec/response-pipeline.md`（UI 输入 → 提交 → 落地）不动 `_submit`／`commit`／
  `present`／`render`、节键与候选资格；`docs/spec/equipment-query-seam.md` 拥有装备只读查询与 `escape_preview`
  （其按需化判归装备片后续批次、**未排期**，本片不得实现）。本片不改 UI 响应路径与节键。

## 接口

### 唯一生成函数（三路共用）

- `core/card_effects.gd` 的 `static func text_entry(g, type: String, uid: String = "") -> Dictionary`：
  条目正文 = 四步 `face_texts` → `face_costs` → `merge(metadata)` → 可能的 `casting`。
- 判据：全仓只有这一处构造这四步；下面三条路径都必须经由它。

### 三个只读入口

| 接口 | 输入 | 返回 | 谁能调 |
| --- | --- | --- | --- |
| `get_view().card_texts` | — | 界面固有显示集合 **S** 的条目（纯数据，可逐字段比对） | 全部只读消费方 |
| `get_view().card_instances` | — | `state.hand` 中命中既有判据（`damage_growth`／`hannya_stage`）的 uid 条目 | 同上 |
| `Game.live_card_text(type, uid="")` | 任意注册牌型（含 `encyclopedia_hidden`） | 全新 Dictionary，与 S 同键条目逐字段相等 | UI 显示边界、测试 |
| `Game.live_card_text_set(cards)` | `cards=[{"type":String,"uid":String}]`（uid 可缺省） | 全新 `{"texts":{type:entry},"instances":{uid:entry}}` | 牌堆浏览、商店去卡、测试 |
| `Game.candidate_detail(candidate)` | 当前 View 的候选 | String，与旧 `candidate.detail` 逐字节相等 | UI 显示边界、测试 |

- 共同语义：只读（不写 `state`、不推进随机、不改 `state.version`、不产日志与事件、不进存档与快照）；
  每次调用返回**新容器**，调用方可以改写返回值且不影响 View 与后续调用；判定按字段比对，不按 JSON 字符串顺序。
- 陈旧输入：`candidate_detail` 只对「当前 View 的候选」承诺与投影一致；对陈旧候选（旧 `ActionIndex` 的
  `old_action`）允许按当前 state 重算，显示点按其记录，不承诺与旧投影相同。
- `deck_list` 已移出 View（全仓无 UI 读取点）；同值数据由 `live_card_text_set` 提供。
  `card_texts`／`card_instances` 除键集合收窄外，条目内容与键序不变。

### 按需的候选详情

- 组范围**只做 card 目标候选组**（`payload.kind=="card"`：自由面／冲开捕缚／多段目标，由 `target_candidate` 产出）：
  该组候选字典**不再带 `detail` 键**，显示时经 `Game.candidate_detail` 现算；
  其余组（attack／calm／flow／posture／wall／retain／route／reward／rest_service／service／prison／item／
  event／departure）保持预生成 `detail`。
- 写路径不读 detail（`dispatch` 只用 `payload`／`cost`／`mana_payment`／`valid`／`reason`）；
  候选 ID = `JSON.stringify(payload)` 不变；`_candidate` 内 detail 的组装抽成共用函数，eager 路径与新入口共用。
- 不得改 detail 的文案与可见性规则（含短原因映射与行动行的显示条件）。

### 文案路由（收口阶段）

- 生产者侧：`_candidate(out, payload, label, copy, cost, mana, reason, risk, group)` 的第 4 参 `copy`
  既可以是今天的 `String`（**直传通道**，行为与今天逐字节相同），也可以是 descriptor
  `{"kind":String,"args":Dictionary,"fallback":String}`；三个转发包装 `Prison.add`、`target_candidate`、
  `paid_candidate` **签名原样不动**，其文案参数同样接受 String 或 descriptor。
- 路由侧（`core/copy_router.gd`，全 static）：
  - `text(g, copy) -> String`：`copy` 是 String → 原样返回；是 descriptor → 按 `kind` 分派到注册的 builder；
  - `categories() -> Array[String]`：可枚举的类别清单（测试与接手方据此核对覆盖）；
  - builder 由模块自带并在路由注册（**不要求把中文搬到路由文件**）：已存在的 8 个 detail 构建函数
    （`Cards.detail`／`Services.detail`／`SelfBinding.detail`／`Hannya.detail`／`Splash.detail`／
    `BasicAttacks.cost_description`／`relic_effects.posture_detail`／`card_splash.detail`）原地保留；
  - 共享片段只放实测确认的横切流程，当前只有 `two_face(type)`（两面拼接）。
- 消费者侧：UI 不直连路由、不 preload `core/copy_router.gd`；只经上面的 `Game` 只读入口，再由显示侧 helper 取用。

### 显示侧取用 helper

- 取用点唯一 helper（都在 `ui/main.gd`）：
  - `card_entry(type, uid="") -> Dictionary`：命中 `view.card_texts`／`view.card_instances` 即用；
    未命中 → `game.live_card_text(type,uid)` 并追加 `ui.projection_misses` 记录；
  - `detail_of(candidate) -> String`：`candidate.detail` 存在即用；缺失 → `game.candidate_detail(candidate)` 并记录。
- 除这两个 helper 外，UI 全仓不得直接读 `view.card_texts[…]`、`view.card_instances[…]`、`c.detail`；
  含 `c.get("brief", c.detail…)` 这种**预求值**写法（GDScript 会先算默认参数，缺键即崩）。

## 输入域

### S（界面固有显示集合）的取源

S 按下列显示入口**逐条取源再取并集**；只允许用本次 View 已经算出的数据正向投影，
**不得为收集 S 新增规则查询**，也不得给 `get_view` 加「显示需求」参数：

| 来源 | 取值 |
| --- | --- |
| 手牌 | `state.hand` 每张牌的 `type`（uid 变体走 `card_instances`） |
| 保留行 | 同手牌 |
| 奖励三选一 | `state.reward_options` |
| 休息选牌 | `state.rest_cards` |
| 出发选牌 | departure 面板条目 `type`／候选 `payload.type` |
| 事件卡选项 | `view.room_event` 卡牌选择项的 `type`（候选 `payload.type` 为兜底） |
| **商店买卡** | `view.shop.stock` 中 `kind=="card"` 行的 `type` |
| 其余会显示卡面的候选 | 候选 `payload.type`：`payload.has("type")` 且值 ∈ `Cards.Rules.SPECS`，非卡牌（attack／item／relic／tool）被注册表过滤 |

- **反例（必须写进实现）**：商店买卡的候选 payload 只有 `{"kind":"service","op":"take","index":…}`，
  **没有 `type`**；只扫候选 payload 会漏掉这个牌型，表现为商店卡面缺失（缺失而非降级）。
- 不计入 S、走全量入口：抽／弃／牌堆整摞、能力区、牌堆浏览、商店去卡；图鉴不进 S（保持 `live_state=false`）。
- 幽灵卡（打出）不在 S（投影期不可知），现场补算并留记录。
- 新增显示入口时必须同步补 S 的推导；判据是 `ui.projection_misses` 为空（幽灵卡除外）。

### descriptor 与类别

- descriptor 用「类别（kind）+ 参数（args）」，由路由按 kind 分派渲染；**不选「模板 id + 参数」**：
  实测 43 个内联字面量彼此不同、全 core 片段级重复仅约 3%，做模板库等于把作者写好的整句重写成模板，
  改动面最大、结构收益最小，且最容易破坏逐字节判据。
- 明令禁止：不得为了「统一」把整段中文搬进中央模板库，不得顺手改措辞。
- 两份卡面组装与费用双源**不合并**：静态 `Catalog.card`（`Rules.energy_label` + `B.card_metadata`）与
  实时 `Cards.text_entry`（`Cards.energy_label` + `Cards.metadata`）继续并存；允许且仅允许的收口是
  实时路径集中到 `text_entry` 并登记为路由类别（`kind="card.face"` 实时、`kind="card.catalog"` 静态）——
  **入口一处可见，实现仍是两份**。图鉴的 `live_state=false` 与既有反向断言原样保留。

### 复用准入线（现行结论）

- **复用必须附可证失效规则；无证明即禁止。** 这条适用于跨提交／跨调用保留投影内容、增量更新与惰性求值：
  任何复用都要给出可验证的失效条件与检查；给不出即不得实现。
- 现行明确保留的做法：core 只读调用内的装备显示行复用与 `face_texts` 合批；UI 跨操作持有的 `ui.view`
  与其显示态（属投影，不是核心缓存）。
- 现行明确禁止：用 `version` 当缓存键或失效键；用译文、颜色、名称、图片识别玩法对象；
  把 `version` 当渲染内容新旧的判据。
- 不得新增没有可证失效规则的常驻缓存；不得让 View 变成不可逐字段比对的对象（不出现惰性对象、函数值或引用外部状态的占位）；
  不得给 `get_view` 加显示需求参数。

## 失败语义

- **三态必须区分，不得混同**：
  1. 直传通道（String）→ 原样返回，行为与今天一致；
  2. descriptor 命中 builder → 返回该 builder 的字符串；
  3. **未知 kind／无效 builder／结果类型不符** → 追加一条 `copy_router_failures` 记录
     （游戏实例上的独立诊断列表：含 kind、入口、失败点与涉事 descriptor；**不进 `state`／不进 View／
     不进存档／不渲染／不做成计数器**），返回 descriptor 自带的 `fallback`（迁移期生产者必须提供）；
     没有 `fallback` 时返回空值**并记录**，绝不允许「空白且无记录」。
- **语言限制（按 GDScript 事实写，勿写成「捕获异常」）**：GDScript 无异常捕获，builder 内部的引擎错误会
  中断调用栈，无法实现「捕获 builder 抛错」。第三态只覆盖**可判定的失败**；真正的引擎错误由测试套件
  当作失败处理，不再是静默空值。该措辞与 `core/copy_router.gd` 头部注释保持一致。
- **缺失即补算并留记录**：显示点只能经 helper 取用；未命中时补算并记录，**不报错、不空白**。
  禁止静默空白、静默回落到目录基础文本、用 helper 存没有可证失效规则的第二份跨调用缓存。
- 记录：`ui.projection_misses`，元素 `{"point":String,"key":String,"view_version":int}`；每
  (point,key,view_version) 至多一条；**清空时机是「`ui.view` 被替换」**，不是「version 数字变化」；
  `view_version` 只是诊断标签，不得当缓存键或失效键，也不得据它判定渲染内容的新旧；
  不渲染、不进日志／存档／快照、不做成计数器。允许的「没省到」：打出的幽灵卡（该 type 投影时不保证在 S 内）。
- 收口阶段（结构调整、行为不变）的交接约束：**不重命名、不重排、不做风格统一**；
  原入口作为薄别名保留（走直传通道，行为与今天一致）；迁移必须可中断——任意批次做完后代码都要能跑、能测；
  不顺手改文案措辞、不改判定、不合并「看起来重复但行为不同」的入口
  （牌堆浏览的三重合并去掉会改筛选排序行为，不得动）。
- 算未完成（任一）：出现未附可证失效规则的复用（含 UI 侧第二份文案副本、惰性对象）、
  给 `get_view` 加显示需求参数；显示点绕过 helper 直读投影字段；缺失时静默空白或静默回落目录基础文本；
  收口阶段的重命名／重排／风格统一／措辞改动；新增生产源码文件（`core/copy_router.gd` 除外）或第三方依赖；
  改判定／随机／存档／快照／候选资格／候选 ID／可见文案；实现 `escape_preview` 按需化或改 UI 响应路径与节键；
  以耗时数字或「应该更快」作完成判据；把既有断言删掉或弱化换取绿灯。

## 证据入口

### oracle 三条（必须换判据）

按需落地后，旧「整份 View 哈希相等」不再是判据，改判：

1. **按需 == 全量**：对全部注册牌型 `type`：`live_card_text(type)` 与 `live_card_text_set([{type}]).texts[type]`
   逐字段相等；`type ∈ S` 时还必须与 `view.card_texts[type]` 逐字段相等。
   **实例字段是包含关系，不是相等关系**：`view.card_instances[uid]` 的每个字段与 `live_card_text(type,uid)`
   的同名字段逐项相等，键集合之差只允许 `face_costs`（恒有）与 `casting`（仅施法牌）两个新增键；
   不得要求整字典相等，也不为补齐这两键去做无收益的改动。
   候选：对基线 View 的每个候选，`candidate_detail(c)` 与基线 `c.detail` 逐字节相等。
2. **端到端不缺失**：对每个可见显示点，在真实夹具下渲染文本 == 由基线 View 推出的期望文本，且
   `ui.projection_misses` 为空（幽灵卡允许一条具名记录，文本必须是实时值）。
   覆盖路径至少：手牌卡面、保留行、奖励三选一、休息选牌、事件卡选项、出发选牌、拖放落点提示（含右键切换提示）、
   身体详情里的选中卡详情与行动行、牌堆浏览、商店去卡、打出幽灵卡。
3. **被显示子集与旧基线一致（mask 定义）**：mask 只按**显式键集合**删除，不按「新视图有什么就比什么」：
   `card_texts` 删键 ∉ S；`card_instances` 删 key ∉ 手牌 uid；`candidates[*].detail` 删 card 组候选的 `detail`；
   `deck_list` 整键删除。保留键必须与基线逐字段相等，删除键集合必须**恰好等于**声明的期望集合
   （多一个或少一个即失败）。判定 = mask 后哈希相等且逐字段无差异，两个 mask 用同一份声明集合，
   声明集合必须打印在 oracle 日志里。

- 基线：开工第一步用未改源码与装备片同一夹具复算并记录（含完整 JSON，mask 判定需要原始值，哈希不够）；
  不一致以复算值为准并记录差异，不得改基线迁就实现。摘要必须记录开工 HEAD 的 commit id、
  基线捕获脚本在该 commit 下的路径、声明集合与哈希；文件删除后若需重取，用该 commit 的临时 worktree 重跑。
- B0 前置（接入点先行，S 与候选 detail 此时不收窄）：新 View 与基线 View 逐字段全等，
  另加「缺键不崩」构造夹具（测试侧复制 View、删除指定 `card_texts` 键或 card 组候选的 `detail`，
  渲染各取用点，断言无引擎错误、文本 == 基线期望、`ui.projection_misses` 有具名记录）。

### 具名 check 与命令

不新建流程文件、不新建看板；用具名函数加入既有 case 文件，复用现有夹具与真实输入助手：

0. `copy_missing_key_never_crashes`（`display`、`targeting`）：缺键夹具渲染不崩、有记录。
1. `copy_fixed_set_matches_full_entry`（`card_power`，经 `tests/card_text_cases.gd`）：三路逐字段相等；
   ∈ S 的 type 在场、∉ S 的不在；状态、随机、version 不变。
2. `copy_projection_masked_baseline`（`architecture`）：mask 后与基线相等，删除键集合恰好等于声明集合。
3. `copy_display_points_have_no_misses`（`display`／`targeting`／`keyboard`）：真实输入下文本与基线一致、
   `ui.projection_misses` 为空（幽灵卡按上文）。
4. `copy_full_entry_equals_baseline`（`interface`）：牌堆浏览与商店去卡的每张卡文本与基线一致。
5. `copy_candidate_detail_on_demand`（`architecture` + `targeting`）：逐候选逐字节相等；card 组候选字典无
   `detail` 键；写路径未受影响（真实提交一次，候选 ID 与基线一致）。
6. `copy_ghost_fallback_recorded`（`display`）：文本为实时值、恰有一条具名记录、不进存档／快照／View。
7. `copy_route_bytes_unchanged`（`architecture`，收口批判据）：每个候选的三条路（迁移前直传字符串、
   descriptor 经 `core/copy_router.gd` 渲染、基线 View 的冻结 `detail`）逐字节相等；
   `copy_router.categories()` 覆盖该批已迁移类别且无未知 kind；未迁移生产者走直传通道行为不变；
   `copy_router_failures` 为空。红时按四类归因：文本内容／候选数量顺序／缺 detail／未知 kind。

```powershell
& tools/check.ps1 -Suite card_power,architecture,casting,card_growth -Impact -TimeoutSeconds 900
& tools/check.ps1 -UI -Suite architecture -UISuite display,targeting,keyboard,interface,card_power,card_growth,shoulder,torso_binding -TimeoutSeconds 900
```

- 判读：退出码 0；输出含 `RULE SCOPE:`、每个 `SUITE RESULT: PASS <name>`、`PASS: N assertions`；
  `summary.json` 的 `status=passed` 且 `before==after` 指纹（`source_changed`／`plan` 不算通过）。
- **既有阻塞项豁免写法**：失败集**恰好等于**既有两项阻塞项（`card_power` 的 5 条 `witch_*`；UI 的
  `shoulder` 2 条 + `torso_binding` 1 条）时，记录为「本片判据通过 + 既有阻塞项未通过」：
  退出码与 `status` 允许为红，但必须在证据里给出阻塞项日志 id，并证明本片新增／迁移的断言与其余套件全绿。
  失败集多出任何一条即未完成；**不得**把 `card_power` 从命令里删掉，也不得修改或删除红断言换取绿灯。
- 被触及的既有断言（`tests/card_text_cases.gd` 全类型读取、`tests/casting_cases.gd`、
  `tests/hannya_ui_cases.gd`、`tests/card_power_ui_cases.gd`、`tests/encyclopedia_ui_cases.gd`、
  `tests/concentration_cases.gd`、`tests/graduate_certificate_cases.gd` 及 tests 中全部 `.detail` 读取）
  按新入口 1:1 迁移后仍通过，期望值与断言语义不变。
- 人的路径证明（判据是套件布尔 check）：战斗中打出／翻面手牌、卡组一览、商店去卡、拖牌到身体与键盘悬浮、
  奖励三选一／休息选牌／事件卡选项／出发选牌、商店买卡（S 的已知回归点）、图鉴不产生 `projection_misses`、
  人为缺键不报错不空白。
- 证据：`build/checks/<id>/check-rules.log`、`check-ui.log`、`summary.json`；
  基线脚本、baseline JSON 与 oracle 日志只放已忽略的 `build/ondemand-copy-<date>/`，用完删除，入库的只有摘要。

## 分批（每批一个 oracle 判据，可独立完工）

执行顺序 **B0 前置 → 收口批 R0…R6 → 按需批 B1…B3**；每批单独跑该批套件与该批 UI 套件，
不得把前一阶段或前一批的绿色拼进下一批的结论。

| 批 | 改动 | 该批判据 |
| --- | --- | --- |
| B0 前置 | 生成函数 + 单条入口 + helper／记录上线；只改三处「缺键即崩」的取用点（硬索引、预求值的 `get(detail)`、把 metadata 合并当第二份卡面文案用）；S 与候选 detail 不收窄 | B0 判据（全等 + 缺键不崩） |
| B1 固有集合 | S 收窄 + `card_instances` 收窄 | 判据①（卡面部分）+ 判据③ |
| B2 全量入口 | `live_card_text_set` + `deck_list` 移出 + 三个消费方迁移 | 判据③（全量入口部分） |
| B3 detail 按需 | card 组 detail 按需 + `candidate_detail` + `detail_of` 铺到全部取用点 | 判据①（候选部分）+ 判据③ |
| R0 路由骨架 | 路由模块 + `_candidate` 第 4 参接受 descriptor；不迁任何生产者 | 全 View 与基线逐字段全等 |
| R1–R6 收口 | 依次：小模块 pilot → 两面拼接片段 → 三个转发包装（一次一个）→ 其余模块 → `core/game.gd` 直呼（最后做，与其它片重碰）→ View 外直产 | `copy_route_bytes_unchanged` + 未迁移模块行为不变 + 该批模块套件 |

红了先归因再改代码：先看差异是文本内容、候选数量／顺序、缺 detail，还是 `copy_router_failures` 出现未知 kind
（后者是批次漏注册类别，不是产品缺陷）。

## 成本位置（收益在哪）

- 一次完整 View 的文案与投影成本约占其 47%：`card_texts` 全量注册牌型循环 25.0 ms（26.8%，
  含 `face_texts` 9.3 ms／103 次）与候选 `detail` 18.9 ms（130 条）；`worn_count(g)` 每次 View 约 166 次调用
  （手牌通常只有 5 张）；`escape_preview` 13.9 ms 属装备片（未排期）。
- 收益路径是按需批；**收口批不承诺省时**，其判据只有逐字节相等与类别可枚举；
  不得以耗时或「调用次数减少」宣称收益。`worn_count` 不做单独去重（要改 `face_texts`／`metadata`／
  `base_damage` 签名且收益未单独测量）。
