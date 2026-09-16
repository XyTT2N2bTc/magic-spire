# 事件管线统一契约（定义形态 → 单求值入口 → 事件链）

规划者契约（planner contract），2026-09-16。冻结本片要动的事件定义形态、求值入口、
节点与事件链模型、存档表示与显式声明清单；内部实现以代码为准，接口语义以本文件为准。
本文件不写执行结果：通过／失败／未执行只登记到 `docs/verification.md`。

**状态：`needs-human-review`（理由见 §15）。** 实现者在本片人审通过前不得开工。

行号捕获于 commit `3bfec7e`；**函数名与稳定 id 才是锚点**，动手前用 `rg` 复算。

## 协调者记录（2026-09-16）

- 本契约已交付并落库。规划者标记 `needs-human-review`，**人审记录尚未产生**：按角色规则，
  实现者不得开工，本片停在此关口，不得以"协调者建议"代替人审。
- 协调者建议（供人裁定，尚未生效）：R1 保留冻结选项双布局＋显式声明；R5 校验取并集并逐条登记；
  R8 不落地迁移脚本、设计留档；R2／R3／R4／R6／R7／R9／R10／R11／R12 按 §13 推荐执行。
- 已核实的既有缺陷（**不属本片范围，待排期**）：`content_catalog.gd:308` 阶段选项的
  `_availability()` 漏传 `data`，`has_relic` 写在阶段选项上永远无法通过校验；
  阶段 id 保留字清单缺 `battle`／`loot`（两者是运行时阶段哨兵值）。

## 0. 领域、裁决与不变量

领域（只在这里动）：

| 范围 | 文件 |
| --- | --- |
| 事件定义、生成、求值、执行、投影、校验 | `spire-godot/core/room_events.gd` |
| 内容编译与校验 | `spire-godot/core/content_catalog.gd` |
| 事件进度与选项存档校验 | `spire-godot/core/snapshot.gd`（事件段，含定义访问；约 379–428 行） |
| 外部内容 | `spire-godot/content/packs/*.json`、`content/templates/event*.json*` |
| 测试与判据宿主 | `spire-godot/tests/{event_cases,event_flow_cases,event_ui_cases,event_draw_cases,content_cases,persistence_cases,architecture_cases}.gd` |
| 启动链迁移脚本（**只在设计里写，本片不改**） | `release/开始游戏.vbs` → `spire-godot/tools/launch.ps1` |

非目标（本片不做）：`core/game.gd` 提交管线、`ui/`（含 `ui/event_screen.gd`）、文案路由、
装备查询索引、E4 战斗桥行为（`begin_battle`／`finish_battle`／`room_encounters` 借用）、
E6 玩家可见政策（漂浮皮带群持有扣环时的隐藏行为维持现状）、全量回归与打包。

人已裁五条（2026-09-16，直接按此设计，不再列为待裁）：

1. 普通事件（`choices`）与多阶段事件（`stages`）合并为**一种定义形态与一条生成／执行管线**。
2. 内容必须合并：外部 JSON 合并成一种事件形态，允许变更内容包 schema；12 份现有内容迁移。
3. **投影不动**：`room_events.view`、`game_view`、`get_view().room_event` 的可见字段与语义不变。
4. 旧档迁移允许，走启动期脚本；不要求游戏本体读旧存档。
5. 分流指向事件＝事件节点与事件链：路由目标统一为事件／节点 id；同一定义内的阶段即节点，
   跳转到另一个事件是同一机制，跨事件跳转形成事件链。

### 0.1 语义不变量（本片的硬判据）

**合并的是格式与管线，不是语义。** 12 份内容的玩家可见行为保持不变：哪些选项出现、哪些显示但禁用、
冻结后的效果、报告与结果文案、以及同一 seed 下 `event` 域随机抽取序列与计数。

可执行判据（E0，本片每一批都必须全绿）：

```powershell
# 在 spire-godot/ 下执行；基线只读，禁止 --write=
& <Godot console 可执行文件> --headless --path . --script res://build/event-oracle-20260916/event_oracle.gd -- --baseline=build/event-oracle-20260916/baseline.json
# 判据：退出码 0 且最后一行 EVENT RESULT: PASS (94 scenarios, 0 failures)
```

94 个场景逐场景比较 `candidates`／`view`／`options`／`snapshot`／`rng`（外加 `stage`／`phase`／
`validate`／`dispatch`／`error` 的明文值）。**任何红项都是需要解决或显式人裁的差异，不得默认为
"合并的正常结果"。** 基线摘要：`1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da`（单次约 10 秒）。

### 0.2 本片对"语义不变"的解释（必须写进实现）

E0 冻结的不只是玩家可见文本，还包括**运行期数据布局**：`snapshot` 摘要覆盖整个 `state`（含
`room_event` 与冻结选项），`options` 摘要覆盖 `room_event.options` 的 JSON 文本（**键序也算**）。
因此本片的统一发生在"作者形态 + 求值入口"，**不在冻结产物**。由此产生三条实现约束：

1. 冻结选项的字段布局按现状保留（见 §2.4 的 `frozen_form`），不得顺手统一；
2. 普通非选择器选项的冻结结果＝作者选项对象本身，迁移时**不得增删键、不得改键序**（§8.2）；
3. `room_event` 的键集合与键序保持不变（`flow`／`next_stage` 等兼容键继续写入，见 §6.1）。

## 1. 现状事实（契约据此写；落地前不改这些事实）

### 1.1 两条构建器实际是三条冻结路径

| 路径 | 触发 | 冻结结果形态 | 证据 |
| --- | --- | --- | --- |
| P1 原地（in_place） | 普通事件的非选择器选项 | `choice_definition.duplicate(true)` 后**就地**替换 `report`／`effects`／（可选）`item_rewards`／`detail`；键与键序＝作者对象 | `room_events.gd:54-65` |
| P2 分阶段（staged） | 普通事件的选择器选项、以及**全部**多阶段选项 | 新建固定字段序字典：`id, source_choice, label, reward, effects, next, report`，再按需 `show_pressure_sources`／`availability`／`item_rewards`／`detail`／`result_status`／`selected` | `room_events.gd:248-277,297-317` |
| P3 拒绝（refuse） | 节点声明 `allow_refuse` | `refusal(g)` 固定对象（含 `next:"result"`） | `room_events.gd:66,69-70,313` |

**推论**：`freeze_choice` 已经是普通选择器与多阶段共用的函数；本片剩下的工作是让 P1 与 P2
由同一入口按**显式声明**选择布局，而不是按"走哪条代码路径"。

### 1.2 求值顺序与随机消耗顺序（现状，必须逐项保持）

普通事件（`start`，逐选项）：

1. `reward=="relic" and available.is_empty()` → 丢弃（**冻结前**，不消耗随机）；
2. 有 `selector` → 每个 selection 调 `freeze_choice`：`outcomes` 加权抽取 → 合并效果 →
   `$selected` 替换 → `remove_restraints.targets` 归一 → `recipe` 编译 → `freeze_effects` →
   构建选项（含 `item_rewards`、`detail`）；
3. 无 `selector` → `effects`（或 `recipe` 编译）；`recipe` 编译为空且无 `effects` → 丢弃；
4. 效果 `resolve_effect_copy`；
5. 含生成器（`install_random`／`tighten_random`／`special_install_random`／`random_amount`）→ `freeze_effects`
   （失败即丢弃，**消耗随机**）；否则挂原始效果、**不消耗随机**；
6. `item_rewards` 冻结（消耗随机）；
7. `detail` 解析；
8. `hide_when_unavailable` 且 `probe_choice!=""` → 丢弃（探测本身不消耗随机）。

多阶段事件（`enter_stage`，逐选项）：

1. `when` 不满足 → 丢弃；
2. 有 `selector` → **先抽一次** `outcomes`，再把同一 outcome 复制给每个 selection；
3. `freeze_choice`（**无条件** `freeze_effects`）→ 失败即返回 `{}`（丢弃）；
4. 冻结后 `choice.reward=="relic" and room_event.relic==""` → 丢弃；
5. 节点级：`allow_refuse` → 追加 `refusal`；`options` 为空 → 返回"这一阶段没有能够执行的选项。"

**随机关键词**：`weighted`／`compile`／`freeze_effects`／`freeze_item_rewards` 的调用次序决定
`state.rng.event` 计数；`RelicRewards.offer` 用 `relic` 域、在 `start` 里按定义级 `offers_relic` 判定
调用一次。三者都不得改序、改次数、改判据。

### 1.3 资格四通道现值

| 通道 | 现状位置 | 现状语义 |
| --- | --- | --- |
| `condition_met`（`when`） | `room_events.gd:242-246` | 只服务多阶段；不满足即整条消失；只读事件计数或 selector 数量 |
| `availability_issue` | `:581-591` | 按 `kind` 硬编码 `no_chastity_lock`／`has_relic`；保留选项、给原因、`reason_surface="secondary"` |
| `hide_when_unavailable` 探测 | `:64`（普通）＋`probe_choice` `:573-579` | 普通显式声明时整条消失；多阶段**无条件**经冻结失败达到同样效果 |
| 遗物池闸门 | `:45`（普通，冻结前）／`:307,311`（多阶段，冻结后） | 普通按"遗物池为空"；多阶段按"本事件没有冻结到遗物" |

### 1.4 丢弃点现值（`docs/event-structure.md` §7.2 的 9 处＋1 处静默）

| # | 现状位置 | 现状原因 | 表现 |
| --- | --- | --- | --- |
| 1 | `start:45` | 遗物池为空（普通） | 静默丢弃 |
| 2 | `start:52` | `recipe` 编译为空（普通） | 静默丢弃 |
| 3 | `start:59` | 随机效果冻结失败（普通） | 静默丢弃 |
| 4 | `start:64` | `hide_when_unavailable` 探测失败（普通） | 静默丢弃 |
| 5 | `freeze_choice:261` | `recipe` 编译为空（共用） | 返回 `{}` |
| 6 | `freeze_choice:264` | 冻结失败（多阶段／普通选择器） | 返回 `{}` |
| 7 | `enter_stage:302` | `when` 不满足 | 静默丢弃 |
| 8 | `enter_stage:307,311` | 冻结后奖励遗物未被冻结 | 静默丢弃 |
| 9 | `enter_stage:314` | 节点没有任何可执行选项（唯一报错处） | 返回 issue |
| 10 | `start:47-49`／`freeze_choice` 外层 | `selector` 展开为空（两条路径都静默） | 零选项入列 |

### 1.5 定义形态现值与已知漂移

- 普通：顶层 `intro`＋`choices`＋`allow_refuse`；多阶段：`intro`＋`start_stage`＋`stages`＋
  `cleanup_effects`；两套白名单、两套默认值、两套 `effects` 上限（8／12）。
- 死代码：`start:53` 的选项级 `pressure`／`pressure_source` 分支，两套白名单都不收该字段，
  12 份内容 0 处命中、测试 0 处构造 → 不可达。
- 阶段 id 保留字只挡 `choice/keys/reward/result`，未挡 `battle`／`loot`（与事件战斗／道具奖励
  的 sentinel 阶段同名会撞 `snapshot` 校验）→ 现有内容未触发，属未验证风险。
- 多阶段选项校验调用 `_availability(choice.availability)` **未传 `data`**（`content_catalog.gd:308`），
  而 `has_relic` 分支要读 `data.relic`；12 份内容里 `has_relic` 只出现在普通选项，
  因此该组合**从未被内容或测试覆盖**（未验证路径，不是已证实的失败）。

## 2. 统一后的定义形态（内容包 schema）

### 2.1 定义级字段（`kind:"event"`）

| 字段 | 必填 | 说明 |
| --- | --- | --- |
| `schema_version` | 是 | 事件升为 **2**（其他 kind 仍为 1）；见 §13 R4 |
| `kind` / `id` / `name` / `intro` / `pool` | 是（`pool` 可选，默认 true） | 与现状一致 |
| `start_node` | 是 | 起始节点 id；普通事件固定为 `choice` |
| `nodes` | 是 | 节点数组，1–12 项，顺序＝作者顺序（迁移时保留原阶段顺序） |
| `cleanup_effects` | 可选 | 与现状一致（定义级，≤8 项，只接受 `restore_held`） |

顶层不再有 `choices`／`stages`／`allow_refuse`；两者同时出现或残留一律拒绝（迁移完整性判据）。

### 2.2 节点级字段

| 字段 | 必填 | 取值／现值 | 对应现状 |
| --- | --- | --- | --- |
| `id` | 是 | 稳定 id。**单节点定义必须用 `choice`**（普通事件的唯一 sentinel 节点）；**多节点定义禁用** `choice`／`reward`／`result`／`battle`／`loot`／`keys`（sentinel 与战斗／道具奖励阶段占用） | 阶段 id |
| `title` / `intro` | 多阶段必填；普通节点**不得出现**（键缺失，不是空串） | 与现状一致；`view` 的拼接按"键存在"判定，保证普通事件 `intro` 逐字节不变 | `stages[].title/intro` |
| `allow_refuse` | 是 | **必填、无默认**：普通＝原顶层值（8 份全是 `false`）；多阶段＝该阶段现值（仅 `succubus_three_games.wager_card` 为 `true`） | `start:66`（默认 true）／`enter_stage:313`（默认 false） |
| `unavailable` | 是 | `"hide"`／`"disable"`：普通节点＝`disable`；多阶段节点＝`hide` | 隐式差异 (a) |
| `relic_gate` | 是 | `"pool"`／`"claimed"`：普通＝`pool`（冻结前查池）；多阶段＝`claimed`（冻结后查本事件冻结的遗物） | 隐式差异 (b) |
| `random_freeze` | 是 | `"generators"`／`"always"`：普通＝`generators`；多阶段＝`always` | 隐式差异 (c1) |
| `outcome_draw` | 是 | `"option"`／`"selection"`：全部＝`option`（选择器外抽一次再复制） | 隐式差异 (c2) |
| `frozen_form` | 是 | `"in_place"`／`"staged"`：普通＝`in_place`；多阶段＝`staged` | 隐式差异 (f)，E0 冻结 |
| `empty_node` | 是 | `"allow"`／`"fail"`：普通＝`allow`（保持零候选）；多阶段＝`fail`（返回具名 issue） | 隐式差异 (e) |
| `choices` | 是 | 1–6 项 | 与现状一致 |

### 2.3 选项级字段（合并后的唯一清单）

新增／统一的字段：

| 字段 | 取值 | 说明 |
| --- | --- | --- |
| `unavailable` | `"hide"`／`"disable"` | 可选覆盖节点默认；与 `hide_when_unavailable` 同时出现且冲突即拒绝 |
| `hide_when_unavailable` | 布尔 | **兼容拼写**，等价 `unavailable:"hide"`；只为冻结产物键集而保留（见 §0.2、§13 R2） |
| `outcome_draw` | `"option"`／`"selection"` | 可选覆盖；只在有 `outcomes` 时有效 |
| `when` | `{counter|selector, equals/minimum/maximum}` | 与现状一致，但校验与求值都走同一声明入口 |
| `availability` | `{kind, ...}` | 与现状一致；kind 集合由 §5 的单一声明派生 |
| `next` | `"result"`／节点 id／`{"event":"<id>","node":"<id>"}` | 缺省 `"result"`；跨事件形态见 §3.2 |
| `encounter`／`item_rewards`／`selector`／`outcomes`／`recipe`／`effects`／`report`／`report_variants`／`detail`／`result_status`／`show_pressure_sources` | 不变 | 白名单合并后，普通与多阶段**都可使用全部字段**（能力不再按结构分家） |

删除：选项级 `pressure`／`pressure_source`（死分支，无内容、无测试可达）。

### 2.4 编译后注册表形态

`Data.TYPES[id]` **就是**作者形态（同一份定义，不做第二套内部结构）。禁止再出现
`definition.choices`／`definition.stages`／`definition.start_stage` 三种并行访问：统一走
`Events.definition(id)`／`Events.node(definition, node_id)`／`Events.node_ids(definition)`。

### 2.5 校验规则合并取值

| 规则 | 现状普通 | 现状多阶段 | 合并后（取并集，只放宽不收紧） |
| --- | --- | --- | --- |
| `recipe` 与 `effects` | 必须且只能一个 | 不能同时出现 | 不能同时出现；允许只有 `outcomes` |
| `effects` 上限 | 8 | 12 | 12（`outcome.effects` 另计 12） |
| 空 `effects` | 只允许无奖励离开／战斗选项 | 允许任何 reward | 允许（含带 reward）；不得作为"未填效果"的默认 |
| `hold_special`／`restore_held` | 禁止 | 允许 | 允许（保持 key 唯一＋cleanup 配平） |
| 奖励选项的 `next` | 无 `next` | 必须 `"result"` | 带 reward 的选项必须结束事件（`"result"`） |
| 节点 id 保留字 | — | `choice/keys/reward/result` | 单节点必须 `choice`；多节点追加 `battle`／`loot` 禁用（sentinel 占用） |
| `allow_refuse` | 顶层默认 true | 每阶段默认 false | 节点必填、无默认 |
| `start_node` 免费出口 | — | 必须可离开 | 保持（起始节点 `allow_refuse:true` 或无条件免费离开选项） |

以上只影响新内容准入；12 份迁移内容在两种取值下都合法（已在 §8.1 逐项核对）。

## 3. 节点与事件链模型

### 3.1 节点即阶段

- 运行期 `state.room_event.stage` 就是当前节点 id；sentinel 值 `choice`（普通事件的唯一节点）、
  `reward`、`result`、`battle`、`loot` 沿用现状语义。
- 普通事件的节点 id 固定为 `choice`：`view`／`validate`／`snapshot` 的既有阶段集合因此逐字不变
  （普通 `["choice","reward","result"]`，多阶段 `["reward","result"]+node_ids`）。
- `Events.node_ids(definition)` 是唯一的节点枚举入口（替换 `flow_stage`／`definition.stages`）。

### 3.2 `next` 的统一形态

`next` 指向三种目标，均由**同一个解析入口**（`Events.next_target`）解释：

1. `"result"`：结束事件（sentinel）；
2. `"<node_id>"`：同一定义内的后继节点；定义内**只能向后**（保持现状校验，不引入倒退与环）；
3. `{"event":"<id>","node":"<node_id>"}`：跨事件跳转，形成事件链。

### 3.3 链的运行时表示与不变量

| 项 | 规则 |
| --- | --- |
| 实例容器 | 同一次进入仍只有一个 `room_event`；跳转时重写 `id` 与 `stage`，不新建实例 |
| 计数 `values` | 链上共享（计数跨事件继续累加） |
| 暂存 `held` | 链上共享；暂存 key 在整条链上唯一 |
| `cleanup_effects` | 链上**并集**（按 `key` 去重）；离开（`leave`）时按并集逐条执行一次 |
| `room.event` | 保持抵达时抽取的 id（`history_issue` 与 `event_seen` 判据不变） |
| `event_seen` | 链上目标事件加入 `event_seen`（不得被本局再次抽到） |
| `flow` 镜像 | 每次跳转按当前定义是否有 >1 个节点重写（兼容键，见 §6.1） |
| 新键 `chain` | **只在真的发生跨事件跳转时**写入：`chain:[event_id,...]`（抵达即不含该键） |
| 环 | 目标事件已在当前实例 `chain` 中 → 该选项在候选阶段 `disabled`，gate=`chain_loop`；静态校验另拒绝"事件引用自身" |

### 3.4 安全规则

- 同一定义内的 `next` 保持现状校验（不倒退、不循环、必须已声明）；
- 跨事件跳转的目标必须已登记，且目标定义必须是多节点或普通形态都合法；
- 事件链**不得**出现在 12 份迁移内容里（E0 只覆盖单定义事件；链只在夹具与专门场景使用）。

## 4. 单一求值入口（资格通道整合）

### 4.1 接口

```gdscript
# 唯一求值入口：任何"这条选项现在是什么状态"的判断都走这里
# request={"definition":Dictionary,"node":String,"choice":Dictionary,
#          "selected":<empty|Dictionary|Array>,"purpose":"arrival"|"candidate"|"probe"|"execute"}
# 返回 {"decision":String,"gate":String,"reason":String,"option":Dictionary}
static func evaluate_option(g, request: Dictionary) -> Dictionary

# 节点级构建／推进：普通与多阶段共用
static func enter_node(g, node_id: String) -> String   # "" = 成功；否则具名 issue（替换 enter_stage）
```

- 生成侧：`start`（起始节点）与 `execute`／`probe` 的节点推进都调用 `enter_node`；
  `enter_node` 内部对每个作者选项调用 `evaluate_option`。
- 消费侧：`candidates`（`purpose:"candidate"`）、`probe`／`probe_choice`（`purpose:"probe"`）、
  `execute`（`purpose:"execute"`）都从同一入口取"决定＋具名原因"，不再各自重算资格。
- 入口**只读**（与 `probe` 同款：状态副本＋恢复），唯一写状态的分支是 `enter_node` 在
  `purpose=="arrival"` 时把冻结选项写入 `state.room_event`。

### 4.2 结果词汇与具名 gate

`decision`：

| 值 | 含义 | 现状对应 |
| --- | --- | --- |
| `generated` | 已生成且当前可执行 | 冻结成功且候选 `valid` |
| `dropped` | **未生成**（结构性闸门，冻结前） | 1／2／5／10 与 `when` 不满足 |
| `hidden` | 生成后被**隐藏**（策略或探测判定） | 3／4／6／8 与多阶段的隐式隐藏 |
| `disabled` | 生成但**禁用**（保留按钮、带原因） | 普通事件保留 `availability`／效果不可行时的候选 |

`gate` 具名清单（全部具名，无静默丢弃）：

| gate | 现状出处 |
| --- | --- |
| `condition_unmet` | `enter_stage:302` |
| `relic_pool_empty` | `start:45`（`relic_gate:"pool"`） |
| `relic_already_offered` | `enter_stage:307,311`（`relic_gate:"claimed"`） |
| `selector_empty` | `start:47-49`／selector 展开为空 |
| `recipe_empty` | `start:52`／`freeze_choice:261` |
| `freeze_failed` | `start:59`／`freeze_choice:264`（`random_freeze`） |
| `availability_unmet` | `availability_issue` |
| `probe_failed` | `probe_choice` 的效果探测失败 |
| `encounter_invalid` | `probe_choice` 的战斗记录或胜利效果探测 |
| `validate_failed` | `probe` 末尾 `g.validate()` |
| `node_empty` | `enter_stage:314`（节点级） |
| `chain_loop` | 新增（§3.3） |

`reason` 一律为**现状字符串原文**（候选原因、`reason_surface`、issue 文案），不得改写措辞。

### 4.3 求值顺序（按声明参数化，必须与 §1.2 等价）

```
evaluate_option(purpose):
  0. when 不满足                    → dropped(condition_unmet)
  1. relic_gate=="pool" 且名义 reward=="relic" 且遗物池为空 → dropped(relic_pool_empty)
  2. 有 selector:
       selections=selector_selections(...)；为空 → dropped(selector_empty)
       outcome_draw=="option" 且有 outcomes → weighted() 抽一次
       逐 selection: freeze_one() → （claimed 闸门见 3）
     无 selector: freeze_one()
  3. relic_gate=="claimed" 且冻结后 reward=="relic" 且 room_event.relic=="" → hidden(relic_already_offered)
  4. 按选项策略 unavailable=="hide" 时：probe_choice(...) 非空 → hidden(首个具名 gate)
     策略 "disable" 时不在这里丢弃（留给候选阶段给原因）
freeze_one():
  a. 有 outcomes 且 outcome_draw=="selection" → weighted() 抽一次（每 selection 一次）
  b. recipe → compile()；为空 → dropped(recipe_empty)
  c. 效果合并／$selected 替换／remove_restraints 归一（顺序同 `freeze_choice`）
  d. random_freeze=="always" 或效果含生成器 → freeze_effects()；issue → hidden(freeze_failed)
  e. 按 frozen_form 组装（in_place＝作者对象就地更新；staged＝固定字段序）
  f. item_rewards 冻结 → detail 解析 → result_status/selected 落位
```

**顺序是判据的一部分**：第 1 步在冻结前、第 3 步在冻结后，正是 `relic_gate` 声明的语义；
把任一闸门挪位会改变 `event` 域消耗 → E0 红。

### 4.4 各 purpose 的检查清单（必须逐项等价，不得多不得少）

| purpose | 执行到哪一步 | 现状依据 |
| --- | --- | --- |
| `arrival` | 全部（含 4 步的 hide 丢弃），并把结果写入 `room_event.options` | `start`／`enter_stage` |
| `candidate` | 第 4 步的探测结果只影响 `valid/reason`；不写状态 | `append_choice_candidate`→`probe_choice` |
| `probe` | 同 `candidate`，另在"有后继节点且 reward=="none""时探测后继节点（现状的 `flow` 分支由 `next!="result"` 取代） | `probe:566` |
| `execute` | **只**复核 `availability`（现状如此，不得改成全量探测，否则拒绝文案会变） | `execute:641` |

`reason_surface="secondary"` 的判定改为 `evaluation.gate=="availability_unmet"`，不再二次调用
`availability_issue`（同一结果，去掉一处平行真相）。

### 4.5 trace（debug 开关）

- 落点：`g.event_trace_enabled`（默认 `false`）＋`g.event_trace`（数组），
  与 `g.copy_router_failures` 同一模式：**不进 `state`／不进 View／不进存档／不渲染／不做成计数器**。
- 条目：`{"event","node","source_choice","option_id","decision","gate","reason","purpose"}`。
- 每次 `start` 在启用时清空；`enter_node`／`evaluate_option`／`probe_choice` 写入；测试显式开启后断言。
- 硬约束：开启与关闭时 `candidates`／`view`／`options`／`snapshot`／`rng` 摘要必须相同
  （用 E0 跑两遍证明）；release 默认关闭，运行不产出。
- 不新增 `game.event_diagnostics()`（先前未授权），不加 View 字段。

## 5. 状态条件种类的单一声明

### 5.1 声明表与三处派生

单一声明落在 `core/room_events.gd`（不新增文件、不新增依赖边）：

```gdscript
# 唯一声明：一种状态条件一行；新增条件只改这里
static var CONDITIONS={
  "no_chastity_lock":{"required":[],"optional":[],"check":Callable,"probe":Callable},
  "has_relic":{"required":["type"],"optional":[],"check":Callable,"probe":Callable},
}
```

三处派生（都读同一张表，禁止再写 kind 字面量）：

| 消费者 | 派生接口 | 现状平行真相 |
| --- | --- | --- |
| 内容校验 | `Events.condition_issue(g, availability, data) -> String` | `content_catalog._availability`（且多阶段路径漏传 `data`） |
| 运行时求值 | `Events.condition_probe(g, availability) -> bool`（被 `evaluate_option` 第 4 步调用） | `availability_issue` 内的 `match` |
| 存档校验 | `Events.condition_saved_fields(kind) -> Array`（＝`["kind","reason"]+required`） | `snapshot.gd:389-397` 手写键集 |

配套：`Events.condition_kinds() -> Array` 给测试枚举；`condition_issue` 校验未登记 kind 时返回
与现状一致的拒绝文案（"尚未支持这种状态条件。"）。

### 5.2 验收点：新增条件只改一处

- `condition_kinds()` 的集合，必须与内容校验能接受的集合、存档校验能接受的集合、运行时能求值的
  集合**三者相等**；测试对每个 kind 各跑一遍"编译通过＋求值有结果＋存档往返通过"，并对未知 kind
  跑一遍三者一致拒绝。
- 回归对照：`tests/persistence_cases.gd:event_conditions`（`has_relic` 往返＋5 类畸形拒绝）保持通过；
  `tests/content_cases.gd` 的 `has_relic` 正例与三类反例保持通过。
- 撤销任一消费者的派生（回到手写列表）必须让这条用例变红——这是本条判据的"反向对照"。

## 6. 存档表示

### 6.1 不变量：`room_event` 与冻结选项逐字节不变

`room_event` 的键集合与键序、冻结选项的字段布局都**保持不变**（`flow`、`next_stage`、`held`、
`values`、`cleanup_effects`、`refs`、`reward`、`winner`、`relic` 继续原样写入）。
`flow` 与 `next_stage` 在新实现里降级为**兼容镜像**：`flow` 仍按定义节点数（>1）写入，
`next_stage` 仍写 `""`（现状从未赋值），但**不再有任何运行分支读它们**（`probe`／`candidates`／
`execute`／`validate` 的分支由 `next` 的声明形态与 `node_ids` 取代）。

### 6.2 新增键只在链实际发生时出现

`chain` 只在跨事件跳转后出现（§3.3），12 份迁移内容与 E0 夹具都不产生它。

### 6.3 事件段存档校验改为按"选项自身形态"判定

- 基础形状（`id/label/detail/reward/effects`＋`result_status`）保持；
- **新增**：`option.has("next")` 时要求 `next:s`／`report:s` 且 `source_choice∈declared`
  （`declared`＝该节点选项 id ＋ 节点 `allow_refuse` 时的 `refuse`）——
  由 `flow` 标志分支改为按选项键判定；`staged` 选项都有 `next`，`in_place` 选项都没有，
  因此现状两种内容的结论不变；
- 节点集合判定用 `node_ids(definition)` 替换 `definition.stages`；
- `values`／`held`／`cleanup_effects` 的检查保持（两种形态的实例本来就都带这些键）。

### 6.4 启动期迁移脚本（形态与集成点，须人审）

**推荐结论：本片不需要迁移脚本。** 因为 §6.1 保持存档形态不变，旧档由新代码直接读取；
强行迁移没有可迁移的差异，只增加误写风险。下面是"若人选了会改变存档形态的选项（§13 R1）"
时必须落地的设计，供人审：

- 位置：`spire-godot/tools/migrate_saves.gd`（`SceneTree` 脚本，用引擎解析 `user://saves/`）＋
  可选 `tools/migrate.ps1` 包装（复用 `find-godot.ps1` 的引擎定位）。
- 触发时机：`tools/launch.ps1` 启动游戏**之前**串行执行一次；游戏本体不读旧格式。
  检查／测试路径不触发（测试用隔离目录）。
- 幂等：逐槽按文件内容判定（目标格式标记写入 `payload`），不依赖全局标记文件；
  已迁移文件直接跳过；**不降级**（新格式遇到旧代码即现状的"不兼容"提示）。
- 失败与备份：先复制 `<slot>.json` → `<slot>.json.premigrate`，再走 temp→校验→rename 的原子替换
  （复用 `core/save_store.gd:133` 的写法）；任一步失败保留原文件、写 `<slot>.json.migration-failed`
  记录、**不阻塞游戏启动**（游戏按现有"版本不兼容"路径提示并从主界面开始新局）。
- 验收：迁移一个真实旧档后，`-Suite persistence` 与读档继续路径通过；重复运行两次结果相同；
  人为损坏一份存档时原文件保持可读。

## 7. 模块切分、接口与依赖规范草案

### 7.1 模块与接口

| 模块 | 小接口 | 内部（藏） |
| --- | --- | --- |
| 事件定义 | `Events.definition(id)`、`Events.node(definition,node_id)`、`Events.node_ids(definition)` | 节点查找、sentinel 集合 |
| 事件求值 | `Events.evaluate_option(g, request)`、`Events.condition_kinds()/condition_issue()/condition_saved_fields()` | 声明表、探测副本、gate 命名、trace |
| 事件管线 | `Events.start(g,id)`、`Events.enter_node(g,node_id)`、`Events.execute(g,c)`、`Events.probe(g,…)` | 冻结、RNG 顺序、节点推进、链路由 |
| 事件投影 | `Events.view(g)`、`Events.candidates(g,out)` | 分组身份、intro 拼接 |
| 内容编译 | `ContentCatalog.compile/_definition/_references` | 单一形态校验、引用解析 |
| 存档校验 | `Snapshot.check`（事件段） | 形状、键集、链字段 |

保持不变的既有接口：`start`／`view`／`candidates`／`execute`／`validate`／`history_issue`／
`probe`／`probe_choice`／`availability_issue`／`selector_values`／`freeze_effects`／`apply_effects`／
`describe`／`describe_result`／战斗桥与道具奖励入口。重命名只允许一处：`enter_stage` → `enter_node`
（外部调用点只有测试，同批更新；**不得**保留同名别名）。

### 7.2 允许依赖方向（本片不变）

`data/* → core/room_events → core/game → core/game_view → ui/*`；`core/content_catalog → data/*`
（经 `g.*` 注册表）；`core/snapshot → core/room_events`（经 `g.Events.*`，**无新增 preload**）。
禁令：core 不得 preload ui；事件模块不得新增 preload 到装备／战斗模块之外的边；
`view` 不得新增只读字段；测试不得成为生产依赖。

### 7.3 文件与行数

- 本仓**没有源码行数门禁**：`docs/agent-guide.md`（2026-09-16 条目）已声明删除
  `tools/check_agents.py`、其单测与 `.github/workflows/agents.yml`；现存检查不读取 `.gd` 行数。
  模块规范只有"新增文件须有明确职责边界；大文件按职责拆，不按行数硬拆"。
- 因此**本片不新增 core 文件**（`room_events.gd` 现状 890 行、`content_catalog.gd` 509 行，
  增长量在本片范围内可控，且拆分既有文件属 E5，先前未授权）。
- 若人坚持 500 行硬线：最小清单为 `core/event_conditions.gd`（§5 的声明表与三处派生，约 80 行）
  与 `core/event_options.gd`（§4 的求值入口＋冻结管线＋trace，约 250 行），允许依赖
  `data/room_events`、`core/room_events`（回调方向需再定），**但这仍需先拆既有 890 行文件**，
  建议另开切片（原 E5）。

### 7.4 依赖规范草案（cleaner／架构分类执行）

1. 事件相关模块的 `preload` 集合不得超出 `data/room_events.gd`、`data/relics.gd`、
   `data/card_rules.gd`、`core/*`（不含 `ui/`）；
2. `core/` 不得出现 `ui/` 字样（现状检查保持）；
3. 事件定义访问只经 `definition/node/node_ids` 三个接口：`core/` 内不得再出现
   `\.stages`／`start_stage`／`\.choices` 直读（普通节点的 `choices` 只允许出现在 `node` 返回值上）；
4. 状态条件 kind 只允许在 `CONDITIONS` 声明表内出现字面量；三处消费者的 kind 集合必须相等
   （由 §5.2 的用例执行，不靠源码扫描）。

## 8. 内容迁移（12 份＋模板）

### 8.1 映射规则（逐字段，机械可执行）

普通 8 份（`abandoned_storeroom`、`alchemist_tasting_stall`、`bound_dream_guest_room`、
`enchanters_empty_studio`、`floating_belt_cluster`、`maze_survey_team`、`smuggled_mana_potions`、
`succubus_magic_pawnshop`）：

1. 顶层 `intro/name/id/pool` 保留；
2. 新建 `start_node:"choice"` 与单元素 `nodes`；节点写 `id:"choice"`、
   `allow_refuse:<原顶层值>`、`unavailable:"disable"`、`relic_gate:"pool"`、
   `random_freeze:"generators"`、`outcome_draw:"option"`、`frozen_form:"in_place"`、`empty_node:"allow"`；
3. 节点**不写** `title`／`intro`（键缺失）；
4. `choices` 原样搬入节点：**逐项不增删键、不改键序、不改值**（§8.2）；
5. 删除原顶层 `choices`／`allow_refuse`。

多阶段 4 份（`binding_cleric`、`bound_adventurer_relic`、`mysterious_woman_statue`、
`succubus_three_games`）：

1. 顶层 `intro/name/id/pool/cleanup_effects` 保留；
2. `start_stage` → `start_node`；`stages` → `nodes`，顺序不变；
3. 每个节点补 `allow_refuse:<原值>`、`unavailable:"hide"`、`relic_gate:"claimed"`、
   `random_freeze:"always"`、`outcome_draw:"option"`、`frozen_form:"staged"`、`empty_node:"fail"`；
4. `choices` 及选项字段原样保留（可选键可自由增删，staged 布局不回声作者对象）。

模板：`content/templates/event.json`（升 schema 2、单节点）与
`content/templates/event_multistage.json.disabled`（升 schema 2、多节点＋声明字段）。
生成来源：`content_catalog._definition` 里为 `special_equipment` 生成的内置到达事件
（`data.event[e.id+"_arrival"]`）也必须改名成节点形态，并显式写 `allow_refuse:true`
（原实现依赖顶层默认 true，否则玩家可见行为会变）。

### 8.2 digest 安全约束（写进实现与迁移脚本）

- 普通事件的 17 个非选择器选项：作者对象即冻结产物 → **键集合、键序、值三者都必须与今天逐字节相同**；
  JSON 重排（`sort_keys`）、格式化工具、顺手补键都会让 `options`／`snapshot` 摘要变红；
- 6 处 `hide_when_unavailable:true` 位置与取值保持不变（兼容拼写，§13 R2）；
- `report_variants`／`selector`／`availability`／`encounter`／`item_rewards` 等作者键
  在 in_place 路径上会原样留在冻结产物里，迁移不得删除；
- 多阶段／选择器选项进入 staged 布局，作者键不回声，但**产出字段的取值**必须一致
  （`next` 缺省 `"result"`、`report`／`result_status`／`detail` 的解析结果不变）。

### 8.3 文档影响清单（本片只登记，不改这些文件）

| 文档 | 需要的变更 |
| --- | --- |
| `spire-godot/content/README.md` §3 事件（97–175 行） | 唯一作者手册：nodes/start_node、节点声明表、选项字段合并清单、schema 2、跨事件 `next`；`has_relic` 键集说明保留 |
| `spire-godot/content/templates/event.json`、`event_multistage.json.disabled` | 见 §8.1（模板本身要在本片迁移） |
| `spire-godot/content/packs/README.txt` | 无字段说明，通常不需要改（落地时复核） |
| `docs/content-templates.md` | §H 事件模板、H4 多阶段、H5 界面约定、§497 行测试表：字段与形态改为单一形态 |
| `docs/content-generation.md` | §7 事件生成与结算（242／275／279／285／289／291／295 行等）：两形态合并后的描述与"必须填写的声明" |
| `docs/content-extension.md` | 事件流程段（133–150 行）与内容表（124 行）的事件行 |
| `docs/event-structure.md` | §4 的 E1–E3 计划被本片吸收；§1 结构地图与 §7.2 的丢弃点编号需在落地后同步（**跨片越界，须协调者另派**） |
| `docs/verification.md` | 只登记结果（validator 负责） |
| 根 `AGENTS.md` 文档入口表 | 若本契约要进入口，由协调者按 `global-agent-baseline` 处理 |

另注：协调者简报与 `docs/response-pipeline.md` §5 引用的 `spire-godot/AGENTS.md` 在 HEAD 不存在
（根 `AGENTS.md` 仍写"Godot 入口见 spire-godot/AGENTS.md"）；根指引的"CI 检查指引行数"一节也
已被 `docs/agent-guide.md` 的 2026-09-16 条目废止。**这两处属指引维护缺口，报告给协调者，
不在本片修**。

## 9. 分批（一个切片，四批；每批都以 E0 全绿收口）

| 批 | 范围 | 判据 |
| --- | --- | --- |
| B1 定义形态归一 | 定义级 `nodes/start_node` 落地；内容 12 份＋模板＋生成来源迁移；`content_catalog` 单一形态校验；`view`／`validate`／`snapshot`／测试夹具改走 `definition/node/node_ids`；`enter_stage`→`enter_node`（行为仍按现状两条分支） | E0 全绿 ＋ `-Suite event_flow,events,content,architecture -Impact` ＋ `check-content.ps1` |
| B2 声明与单入口 | 节点／选项声明写入内容；一线管：单 `evaluate_option`＋单 `enter_node` 覆盖普通与多阶段；四通道收敛；删除死分支与平行真相 | E0 全绿 ＋ 同上 ＋ 新具名 check（§10 的 03–05／12–13） |
| B3 具名丢弃与 trace | gate 命名全覆盖（含 `selector_empty`／`node_empty`）；`g.event_trace`＋开关；测试断言；release 不产出 | E0 全绿（开关开／关各跑一遍）＋ `persistence` 断言 trace 不进存档 |
| B4 事件链路由 | `next` 支持 `{"event","node"}`；`chain` 条件键；环守卫；夹具与用例 | E0 全绿 ＋ 链用例 ＋ `architecture`／`persistence` |

每批单独跑该批判据；**不得把前一批的绿色拼进下一批**。B1 与 B2 之间代码必须可跑可测
（现状两条分支仍在，只是由节点形态驱动）。

## 10. Gherkin（场景名 → 既有分类的具名 check）

不新建流程文件、不新建看板；用具名函数加入既有 case 文件，复用 `tests/game_fixture.gd` 与
`tests/event_cases.gd.arrive`。

01. `event_definition_single_form`（`tests/event_cases.gd`，`events`）
    Given 12 份迁移后的内容包；When 编译并逐个进入；Then `Data.TYPES[id]` 只含 `nodes/start_node`，
    无顶层 `choices/stages/allow_refuse`，且每个节点含 §2.2 全部声明键；`view().room_event` 的
    字段与基线一致。
02. `event_option_policies_match_current_behaviour`（`tests/event_flow_cases.gd`，`event_flow`）
    Given 每份内容的每个节点／选项；When 读取声明；Then 声明值与 §2.2／§2.3 现值表逐项相等
    （普通节点 `disable/pool/generators/option/in_place/allow`；多阶段节点 `hide/claimed/always/option/staged/fail`）。
03. `event_gate_names_are_total`（`tests/event_cases.gd`，`events`）
    Given 开启 trace；When 逐事件构建选项、构建候选、提交；Then 每个作者选项至少出现一条 trace，
    `decision∈{generated,dropped,hidden,disabled}`，且每条丢弃／隐藏都带 §4.2 的具名 gate
    （含 `selector_empty`）；候选数组、View、随机计数与关闭 trace 时逐字节相同。
04. `event_hidden_relic_option_traced`（`tests/event_flow_cases.gd`，`event_flow`）
    Given 已持有 `softened_buckle` 的漂浮皮带群；When 构建选项；Then 【硬闯】缺席且 trace 记录
    `source_choice=fight`＋具名 gate，候选集合与 E0 基线一致（E6 政策维持现状）。
05. `event_condition_kinds_share_one_declaration`（`tests/architecture_cases.gd`，`architecture`：
    规则侧；`tests/content_cases.gd` 与 `tests/persistence_cases.gd` 各出对应断言）
    Given `Events.condition_kinds()`；When 逐 kind 造最小合法 `availability`（普通选项与阶段选项各一次）；
    Then 内容编译通过、运行时求值返回非空、存档往返通过且键集＝`condition_saved_fields(kind)`；
    未知 kind 在三处一致拒绝；三处 kind 集合相等。
06. `event_stage_available_condition_validates`（`tests/content_cases.gd`，`content`）
    Given 阶段选项声明 `has_relic`；When 编译；Then 通过（覆盖 `_availability` 漏传 `data` 的现状缺口），
    未登记遗物／缺 `type`／多余键仍拒绝。
07. `event_definition_form_rejects_legacy_shape`（`tests/content_cases.gd`，`content`）
    Given 同时含 `choices` 与 `stages`、缺 `start_node`、节点缺任一声明键、节点 id 用 `battle`／`loot`、
    `recipe` 与 `effects` 同填；When 编译；Then 逐例拒绝且整包不登记（`Catalog.tables(g)` 不变）。
08. `event_unified_option_capabilities`（`tests/event_flow_cases.gd`，`event_flow`）
    Given 夹具把 `encounter`／`item_rewards`／`hide_when_unavailable` 写在阶段选项、
    把 `when`／`outcomes` 写在普通选项；When 编译并执行；Then 全部生效（能力不再按结构分家），
    且 12 份内容的行为不变。
09. `event_node_empty_policy_kept`（`tests/event_cases.gd`，`events`）
    Given 普通夹具节点的全部选项被丢弃；When 构建；Then 节点保持零候选、不进入失败结果页；
    Given 多阶段夹具节点同样情形；Then `enter_node` 返回具名 issue `node_empty`，
    上一节点的该选项在候选阶段变为 invalid。
10. `event_trace_never_reaches_state_or_save`（`tests/persistence_cases.gd`，`persistence`）
    Given 开启 trace；When 进入事件、构建候选、提交、`export_snapshot`／存档往返；
    Then snapshot／存档／View／`rng` 不含 trace 字段，且与关闭 trace 时的摘要相同。
11. `event_chain_jumps_to_another_event_node`（`tests/event_flow_cases.gd`，`event_flow`）
    Given 夹具事件 A 的节点 `next={"event":"B","node":"entry"}`；When 提交；
    Then `room_event.id=="B"`、`stage=="entry"`、`chain` 含 A、`values`／`held` 延续、
    离开时 A∪B 的 `cleanup_effects` 各执行一次、`event_seen` 含 B。
12. `event_chain_loop_refused`（同文件）
    Given 链上已含 A；When 再次跳向 A；Then 该选项 invalid 且 gate=`chain_loop`，
    `state`／`rng`／存档不变。
13. `event_probe_and_projection_readonly`（`tests/architecture_cases.gd`，`architecture`）
    Given 任一事件（含链夹具）；When `get_view`／`candidates`／`evaluate_option(purpose=candidate/probe)`／
    `selector_values`；Then `export_snapshot()`、`rng`、`logs`、`version` 与调用前全等。
14. `event_frozen_options_roundtrip`（`tests/persistence_cases.gd`，`persistence`）
    Given 每个事件的冻结选项（普通与多阶段各取样例）；When 存档往返；Then 选项与 `room_event`
    逐字段相等，且 `option.has("next")` 的校验分支按 §6.3 判定。

场景 01–14 是 B1–B4 的逐步落地对象；未落地即未完成。

## 11. Validator procedure（agent 可运行；操作必须走真实输入）

宿主入口：`tests/test_game.gd`（规则）＋`tests/ui_smoke.gd`（界面）＋`tools/check.ps1`。
不默认截图；测试存档隔离（`ui.persistence_enabled=false`）。

1. 范围预检（不算通过）：
   `& tools/check.ps1 -Suite event_flow,events,content,architecture,persistence -Impact -ListOnly`
   与 `& tools/check.ps1 -UIOnly -UISuite events -ListOnly` → 输出 `PLAN ONLY:` 且列出上述分类。
2. 冻结判据（每批一次）：跑 §0.1 的 oracle 比对命令 → 退出码 0、`EVENT RESULT: PASS (94 scenarios, 0 failures)`；
   另在 trace 打开与关闭两种设置下各跑一次，两次输出摘要相同。
3. 内容门：`& tools/check-content.ps1` → `CONTENT PASS: 12 file(s)`。
4. 规则门：`& tools/check.ps1 -Suite event_flow,events,content,architecture -Impact -TimeoutSeconds 900`
   → 退出码 0；每个 `SUITE RESULT: PASS <name>`；`summary.json` 的 `status=passed` 且 `before==after`
   指纹（`source_changed` 不算通过）。
5. 界面回归（投影不动）：`& tools/check.ps1 -UIOnly -UISuite events -TimeoutSeconds 600`
   → 退出码 0、`UI PASS: N assertions`。
6. 人的路径证明（判据是套件的布尔 check，按顺序在真实界面上操作）：
   - 练习「漂浮皮带群」首次进入：事件候选（`payload.kind=="event"` 且 `action=="choose"`）恰为【硬闯】【接受灌注】，与基线一致；
   - 注入已持有 `softened_buckle` 的状态后再进入：【硬闯】仍缺席、【离开】出现（E6 维持现状）；
   - 选【硬闯】完成战斗：进入事件结果页、只发遗物、战后整备按原语义；
   - 事件选牌／道具奖励／付费离开各走一次，文案与原因与基线一致；
   - 多阶段事件（缚疗修女、魅魔三局赌牌）逐阶段点击，阶段标题与选项与基线一致；
   - 存档并在正式入口继续：选项、阶段、报告一致（旧档路径不变）；
   - 关闭 debug 开关：`g.event_trace` 为空。
7. 归属判定：失败先分"实现代码／测试脚本／环境／程序本身"；不确定就保持未分类上报，
   不自动改产品代码，不动判据。
8. 证据：`build/checks/<id>/check-rules.log`、`check-ui.log`、`summary.json`、oracle 输出；
   结果与域写 `docs/verification.md`（validator 负责，不在本契约宣称通过）。

## 12. 完成定义（DoD）

命令（每批一次 ＋ 收尾一次；不无故重复）：

```powershell
# 0) 冻结判据（每批必跑；基线只读）
& <Godot console exe> --headless --path . --script res://build/event-oracle-20260916/event_oracle.gd -- --baseline=build/event-oracle-20260916/baseline.json
# 1) 内容包校验
& tools/check-content.ps1
# 2) 规则门（-Impact 会并入 persistence、rewards、pressure、equipment、special_equipment）
& tools/check.ps1 -Suite event_flow,events,content,architecture -Impact -TimeoutSeconds 900
# 3) 界面回归（投影不动）
& tools/check.ps1 -UIOnly -UISuite events -TimeoutSeconds 600
```

必过的场景：§10 的 01–14 全部具名 check；E0 的 94 场景 0 失败；`check-content.ps1` 通过。

必有的证据：oracle 比对输出（含 `EVENT RESULT: PASS`）、两份 check 日志 ＋ `summary.json`
（`status=passed`、指纹稳定）、§8.3 的文档同步记录（由协调者派单，不在本片内改的那些要留
"待同步"清单）。

算未完成（任一）：

- 任一必跑命令未执行、失败、未知或被跳过；`summary.json` 为 `source_changed`／`failed`／`plan`；
- E0 出现红项而未解决、未显式上报人裁；用 `--write=` 重取基线让红变绿；
- 冻结选项布局被"顺手统一"（`options`／`snapshot` 变红）而未经人裁；
- 定义了 kind 集合以外的地方出现 kind 字面量、三处消费者枚举不一致；
- 出现静默丢弃（无 trace 记录、无 gate 名）；
- trace 进入 `state`／存档／View／日志，或 release 运行产出 trace；
- 新增 `get_view` 只读字段、新增 `game.event_diagnostics()`、改 `ui/` 或 `core/game.gd` 提交管线；
- 删／弱化既有断言（含 `event_flow_cases` 的隐藏选项断言、`persistence_cases:event_conditions`）换绿灯；
- 12 份内容之外的内容包被写入链形态（E0 不覆盖）；
- 宣称完整回归或提速。

## 13. 需人裁清单（选项／后果／推荐）

| # | 问题 | 选项与后果 | 推荐 |
| --- | --- | --- | --- |
| R1 | 冻结选项布局是否统一 | 保留 `frozen_form` 双布局＋显式声明（E0 可全绿）／统一为 staged（`options`＋`snapshot` 摘要必然变红，须重取基线并重新定义"语义不变"） | 保留双布局 |
| R2 | `hide_when_unavailable` 是否改名 | 保留为 `unavailable:"hide"` 的兼容拼写（那 6 处选项的 `snapshot`／`options` 摘要不变）／只留新名（这 6 处选项的 `snapshot`／`options` 变红） | 保留兼容拼写 |
| R3 | 声明粒度 | 节点默认＋选项覆盖（可表达同节点内差异）／仅节点级（无法表达普通事件 fight 藏、infusion 不藏）／仅选项级（普通非选择器选项会把策略写进存档→红） | 节点默认＋选项覆盖 |
| R4 | `schema_version` | 事件升 2（新旧形态可判、迁移可判）／保持 1（靠字段形状判，工具易误判） | 升 2 |
| R5 | 校验规则合并取值（§2.5） | 取并集（只放宽：`effects≤12`、空 `effects` 任意 reward、保留字加 `battle/loot`）／各自保留（则能力仍分家） | 取并集并逐条登记 |
| R6 | 空节点策略 `empty_node`（实测新增差异） | 按现值声明（普通 allow、多阶段 fail）／统一为 fail（普通事件获得"无可选项即失败页"兜底，属玩家可见变化） | 按现值声明；统一另案 |
| R7 | 事件链是否本片实现 | 实现最小跳转＋环守卫＋夹具（B4）／只留形态不实现（"分流指向事件"落空） | 实现（B4） |
| R8 | 启动期迁移脚本 | 不落地（本片存档形态不变，无事可做）／落地并把冻结布局统一（与 R1 绑定） | 不落地；设计留档（§6.4） |
| R9 | trace 落点 | `g.event_trace_enabled`＋`g.event_trace`（同 `copy_router_failures` 模式）／不落地 trace（定位能力退回现状）／`game.event_diagnostics()`（先前未授权，越白名单） | 前者 |
| R10 | 删除死分支 | 删除选项级 `pressure`／`pressure_source`（无内容、无测试可达）／保留 | 删除 |
| R11 | 是否新增 core 文件 | 不新增（本仓无行数门禁）／若按 500 行硬线：`core/event_conditions.gd`＋`core/event_options.gd`，且需先拆既有 890 行文件（E5） | 不新增 |
| R12 | `get_view` 新只读字段 | 0 个（投影不动，缺口靠 trace 在 core 内解释）／新增 `hidden_options`（越白名单，且会让 UI 可见语义变化） | 0 个 |

## 14. 假设与最可能爆掉的假设

1. **最可能爆：某处我判定"等价"的求值顺序在迁移后改变了 `event` 域消耗**——高风险点是
   `relic_gate` 的冻结前／后位置、`selector` 展开与 `outcome_draw` 的先后、生成器判定发生在
   `resolve_effect_copy` 之后。触发即 E0 的 `rng`／`options` 红；定位方法是按场景名二分
   （`start:`／`choose:`／`settle:`）并临时开 trace 对拍。
2. **次可能：迁移把普通非选择器选项的键序改了**（JSON 重排、补键、顺手统一 `report` 位置）→
   `options` 与 `snapshot` 同时红。缓解：迁移脚本逐文件往返比对（读入→写出→再读入，键序与值相等）
   后再入库。
3. **`flow` 镜像被当成死字段删掉** → 所有多阶段场景 `snapshot` 红。契约已写明：兼容键继续写入，
   只是没有运行分支读它。
4. **trace 引入实例级状态泄漏**（探测副本里写入、或在 `export_snapshot` 里被带上）→
   `snapshot`／`View` 摘要红。缓解：§10 场景 10 与"开／关两遍 oracle"。
5. **内容校验放宽项改写了既有反例断言**：`content_cases` 有 20+ 条 invalid 夹具（缺 `type`／
   多余键／空 `effects` 等），某几条在新规则下从"拒绝"变"接受"或反之。这不是产品缺陷，
   但会让 B1／B2 变红；处理方式是逐条按 §2.5 更新期望，**不得删除**。
6. **链语义污染 12 份内容**：迁移时误写 `next` 的对象形态或 `chain` 键 → E0 红。
7. 若人选择 R1 的"统一冻结布局"，则 E0 不再是本片判据，需要重取基线并重新定义验收——
   本契约的分批、DoD 与假设都要重写，属重新规划而不是"顺手改一下"。

## 15. `needs-human-review` 判定与逐条理由

**判定：是（`needs-human-review`）。** 实现者不得在人审记录落地前开工。

1. **内容包 schema 变更**：12 份外部 JSON、2 份模板、1 处生成来源、7 份文档受影响；形态由人裁第 2 条
   授权，但**具体字段清单与默认值**（§2）需要人确认。
2. **存档邻近**：`core/snapshot.gd` 的事件校验要改写；且需人确认"本片不改存档形态"与
   "是否仍要迁移脚本"（§6.4）这一对结论。
3. **新增能力**：跨事件跳转与 `chain` 存档键是新能力（人裁第 5 条的方向），当前无任何内容使用，
   其语义（`values`／`held`／`cleanup`／`event_seen`／`room.event` 的延续规则）需人确认。
4. **计划包含两处实测新增的隐式差异**（e 空节点处理、f 冻结选项布局），超出人列的 a–d；
   其中 f 直接受 E0 判据约束，必须由人确认"保留双布局"。
5. **依赖规范与文件拆分**：本片结论是不新增文件、不新增依赖边；若人要求按 500 行硬线拆，
   等于重新授权 E5（先前明确未授权），属范围变更。
6. **判据相互作用**：E0 全绿这一判据与"内容必须合并成一种形态"存在张力（冻结产物不能被统一），
   本契约的解法是把差异降为声明；该解法需人认可，否则整片范围与判据都要改。
