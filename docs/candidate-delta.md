# 候选局部筛查与视图增量（candidate-delta）

规划者契约（planner contract），2026-09-17。分支 `event-pipeline-unification`，HEAD `eb85733`（起稿时工作区干净）。
状态：**`needs-human-review`**——理由见 §10；人审记录进协调者之前，实现者不得开工。
**工作区提示（2026-09-17 本片收尾时）**：起稿时工作区干净；收尾时 `spire-godot/tests/check_index.json` 与
`spire-godot/tests/normal_play_cases.gd` 出现**他人未提交改动**。本契约未触碰这两处；实现者开工前先 `git status`，
不得把在途改动混入本片提交，且 `check-index.ps1 -Write` 需与索引改动方协调同批。
本文件是本片唯一契约：切口、接口语义、组清单与覆盖口径、Gherkin、validator procedure、DoD、依赖约束。
**不写执行结果**：通过／失败／未执行只登记 `docs/verification.md`。
行号只作复算线索；**函数名、组名、稳定 id 才是锚点**。

## 0. 领域、已核实事实与非目标

领域：**一次成功提交前后，候选表的构建范围**。两个生产侧全量点（协调者已核实，2026-09-17）：
`core/game_view.gd:build`（`var actions=g.candidates()`，每次构建视图）与
`core/game.gd:dispatch`（`for c in candidates():`，每次提交复核）。一次成功提交＝全表算两遍，
实测占一次点击约 30–40%（`docs/verification.md` 2026-09-17「卡顿定位」）。
不含：输入层、投影其余部分、`render` 整树、存档、窗口与队列、事件域。

已核实事实（契约据此写；来源＝协调者派单 + 本轮只读复算，行号以落地时仓库为准）：

| # | 事实 | 证据位置 |
| --- | --- | --- |
| F1 | `candidates()` 的唯一入口：`_build_candidates()`，先 `_begin_equipment_read()`、后还原；内部按**固定调用序**追加：`_phase_candidates`（各相位分支，含 `_wall_move_candidates`/`_posture_candidates`/`_attack_candidates`/`_equipment_spell_candidates`/`_card_candidates`→`Cards.candidates`/`_manual_candidates`/`_item_candidates`/`Prison.candidates`…）→ `Consumables.noncombat_candidates` → `_route_candidates` → 投降 → 逐件 `item_discard` → `ManaFlask.candidates` → `status_toggle` | `core/game.gd:candidates`/`_build_candidates`/`_phase_candidates` |
| F2 | 候选行由 `_candidate(out,payload,label,copy,cost,mana,reason,risk,group)` 组装；行含 `id`（payload 的 sha256 前 24 位）／`payload`／`label`／`detail`（卡牌按需）／`cost`／`mana`／`mana_payment`／`valid`／`reason`／`risk`／`group`。**全仓无调用点使用 `group` 默认值 `"action"`**：当前实际组名 24 个（§3.1） | `core/game.gd:_candidate`；本轮全仓 `_candidate(` 调用抽取 |
| F3 | 组＝现成的分组键；UI 消费面按组取：`ui/action_index.gd``by_id`/`by_group`/`select`/`find`/`first_usable`。**唯一按全局顺序读候选的 UI 点是 `ui/main.gd:1561`（监狱场景按 payload 过滤后保序）** | `ui/action_index.gd`；`rg -n "view\.candidates" ui/` |
| F4 | UI 侧本来就持有上一版候选：`ui/main.gd:371 view=game.get_view() if snapshot.is_empty() else snapshot`（唯一赋值点）、`:381 actions=ActionIndex.new(view.candidates)`。`view.candidates` 是 UI 唯一的候选来源，跨提交保留在 UI 层事实上已存在 | `ui/main.gd` |
| F5 | 提交路径现状：`_submit` → `game.dispatch(c.id, view.version)` → **无条件** `game.get_view()` → `render(updated)`（成功与否都重投影）；读档／新局／快速 SL：`_resume_snapshot:281`、`restart:1966` 各自 `game.get_view()` 全量 | `ui/main.gd:_submit`/`_resume_snapshot`/`restart`/`_quick_sl` |
| F6 | 路由器现状（本片**不动**）：`dispatch` 的 `payload.kind` if/elif 6 支（`event`／`departure`／`service`／`depart`／`surrender`／`prison`）＋ `_execute` 的 `match p.kind` 30 个标签＋ `else: _execute(chosen)`。`Events.execute` 的 `match p.action` 与 `apply_effects` 的 `match effect.op` 亦不动 | `core/game.gd:dispatch`/`_execute` |
| F7 | 事件域天然不重算：事件候选读 `state.room_event.options`（进入事件时冻结）与 `stage`（`Events.candidates`），产物全在 `event` 组 | `core/room_events.gd:candidates`／`:447` |
| F8 | 通用读取面（每个候选行都要过）：`_candidate` 按 `state.energy`／魔力余额写 `valid`/`reason`；按 `Pressure.action_risk`（读 `state.pressure_sources`＋装备/遗物）与 `Cards.magic_card_traction`（读手牌修正）写 `risk`；按目标装备的 `lock_only`／诅咒写 `reason`；`CopyRouter.text(copy)` 的正文由各站点 builder 自定（可读任意 state）。**这条决定了"哪些组必然被作废"无法按 kind 粗粒度证明**（§9） | `core/game.gd:_candidate`；`core/pressure.gd:action_risk` |
| F9 | 两个冻结 oracle 都按**候选数组整体**取摘要：`EVENTDIGEST` 对应的 `candidates:"sha256(JSON.stringify(g.candidates()))"`；迁移 oracle 记录所选候选的具名字段。结论：**候选行的字段、取值、顺序一个字都不能动** | `build/event-oracle-20260916/event_oracle.gd`；`build/transition-oracle-20260916/transition_oracle.gd`；两份 `baseline.json` |
| F10 | 已归档否决方向（**不得重提**）：UI 把候选行连同版本一起提交给 `dispatch`（协议面扩张）。本契约不新增入参、不改 `dispatch` 判定与文案，见 §9.2 的边界论证 | `docs/history/submit-dedup-2026-09-17.md` |

非目标（本片不做，逐条对应派单禁区）：
- 不改 `dispatch(candidate_id, expected_version)` 的**入参、返回值形状与接受/拒绝语义**（F10）。
- 不重构路由器（F6 三类 match 保持）；不表化（kind→组、状态字段→组的映射表属后续片，§9.4）。
- 不改候选内容、顺序、费用、文案与分组名；不动 UI 布局与刷新策略。
- 不引入核心侧跨提交缓存；不放宽"只读复用仅限单次调用内"（`docs/equipment-query-seam.md`）。
- 不碰窗口／输入队列（`docs/response-pipeline.md` 末尾，未排期）；不碰提交协议去重（F10）。
- 不动读档／新局／快速 SL 的全量路径（协调者 2026-09-17 硬约束，§4.1）。
- 不新增运行时依赖；不打包、不发版、不推送。

## 1. 切口、模块边界与依赖方向

切片按"能证明的部分先落地"切成两段；**本片只实现 Part I，Part II 是本片交付的下一片设计**（原因与证据见 §9）：

- **Part I（本片实现）**：候选构建**按构建序分段（run）推进**，`dispatch` 的提交复核改为**逐段筛查、命中即止**（未命中回落全量复核）；核心提供窄只读入口 `candidate_runs(groups)`（只构建被请求的组），供测试与 Part II 消费。
- **Part II（本片只写契约，不实现）**：视图侧增量（`get_view` 只构建被作废的组、UI 用上一版候选按段替换）+ 执行端声明作废组 + 声明覆盖闭环。其前置是 §9.4 的字段依赖分析。

| 模块 | 边界（谁） | 接口（小） | 内部（藏） |
| --- | --- | --- | --- |
| M1 候选构建 | `core/game.gd`（`_build_candidates` 及其调用方、`_candidate`） | `candidate_runs(groups) -> Array`（§2.1）；内部 `_candidate_steps(scope, stop_id)` | 段边界、作用域过滤、各 builder 的早退守卫、顺序 |
| M2 提交复核 | `core/game.gd:dispatch` | 入参/返回**不变**；内部改用 `_candidate_by_id(id)`（§2.2） | 逐段构建、命中即止、未命中回落全量 |
| M3（Part II，不在本片） | `core/game_view.gd` + 执行端声明 + `ui/candidate_delta.gd` | 见 §9.4 | — |

允许依赖方向（本片不变）：`core` 不 preload `ui`；`ui/candidate_delta.gd` 不在本片；
唯一允许 `preload` core 的 UI 文件仍是 `ui/main.gd`。M1/M2 均为 `core` 内改动，无新依赖边。

## 2. 接口契约

### 2.1 `Game.candidate_runs(groups: Array) -> Array`（core，新，只读）

- 语义：按**当前状态的既有构建序**返回候选**段**；段＝构建序列里**极大同组连续段**（同一组名的相邻行合并为一段；
  被跳过的其他组的行仍会在该处**断开**段，即使那些行不在结果里）。返回
  `[{group: String, rows: Array}]`，段的先后＝构建序，段内行的先后＝构建序。
- 作用域：`groups` 只含请求的组名；`rows` 里的行必须与同状态全量 `candidates()` 中对应段**逐字段相同**
  （同一构造路径、同一 `_begin_equipment_read()` 包裹、不复制不重排）。
- **fail-closed 输入域**：`groups` 为空 → 返回 `[]`（**绝不**等价于"全部"）；含未知组名 → 返回 `[]`；
  重复组名按一次处理。`groups=["*"]` 不是本入口的协议，返回 `[]`（调用方必须走全量 `candidates()`）。
- 只读性：不写 `state`、不推进随机、不改 `version`、不产生日志与事件、不跨调用保留（沿用 `candidates()` 现有语义）。
- 成本口径：**不得**比"全量构建后过滤"更差地影响行内容；性能上只要求"被请求组之外的昂贵循环可被早退守卫跳过"（§3.3），
  本片不以该入口的耗时作通过判据。
- 谁能调：测试；`core/game.gd` 内部；Part II 的增量路径。UI 其它文件不得调（`ui/main.gd` 只能经 §9.4 的合并入口，本片不开放）。
- 信任依据：本契约 + §5 场景 1（`runs(all) ≡ candidates()` 逐字段逐顺序）＋ 场景 3（fail-closed 反例）。

### 2.2 `dispatch` 的提交复核：局部筛查（core，内部改动，接口不变）

- 现状：`var chosen={}; for c in candidates(): if c.id==candidate_id: chosen=c; break`
  （第一次命中即止，但**必须先把整表建出来**）。
- 契约：改为按构建序**逐段**构建并逐段匹配：任一段内出现 `id` 相等者即取**该段内第一条**并立即停止构建。
  - **步粒度不参与语义**：结果只取决于"按追加顺序的第一条 id 匹配行"，因此段/步可粗可细
    （整段检查、逐 step 检查都等价），但**检查必须在每次追加之后按追加顺序进行**，且不得跳过任何追加。
  - 等价判据：结果与现状**同一行**（构建序第一条 id 命中者）、同一 `valid`/`reason`/`payload`/`cost`/`mana`/`mana_payment`；
    未命中时的返回与拒绝文案完全不变。
  - **fail-closed**：逐段筛查未命中 → **回落全量 `candidates()` 再复核一次**，仍未命中才走现有拒绝文案。
    （守卫写错、段序列不全、缓存差异都不会造成"误拒"，最坏只是白花一次全量构建。）
  - 副作用：候选构建只读（不推进随机、不写 state、不产日志）；`_begin_equipment_read()` 的包裹与还原与现状一致。
- 接口面：`dispatch(candidate_id, expected_version)` 的入参、返回字典的键与取值、接受/拒绝语义、`version` 语义、文案**全部不变**。
- 谁能调：`dispatch` 内部唯一；不得把该入口暴露给 UI 或测试作为"提交"路径。
- 信任依据：本契约 + §5 场景 2（同状态双实例：局部筛查实例 ≡ 全量实例的返回与终态）＋ 两个冻结 oracle。

### 2.3 计数口径（判据用，必须逐字沿用）

- **全表构建**：一次把当前状态要产出的**全部**组都构造出来的候选构建（`candidates()`／`get_view()` 内那次）。
- **局部段构建**：`candidate_runs` 的组作用域构建，或提交复核里"逐段构建、命中即止"的部分构建。
- 一次成功提交的**全表构建次数**：现状 2；本片后 = 1（只剩视图侧那次；提交复核不再全表）。
  Part II 落地后才可能到 0/1（视图侧按声明增量）。**本片不宣称 0。**

## 3. 组清单、段结构与覆盖口径

### 3.1 组清单（今天实际存在的 24 组 + 未使用的默认 `action`）

| 组 | 生产者（构建序位置） | 消费方（UI／核心） | 备注 |
| --- | --- | --- | --- |
| `wall_move` | `_wall_move_candidates` | 候选子集 `wall_move`：动作栏／姿态区 | 相位限 battle/prepare/rest/prison 且有墙 |
| `posture` | `_posture_candidates` | 姿态区 | |
| `attack` | `_attack_candidates`、`_equipment_spell_candidates`（同组相邻）、`witch_character.gd` | 动作栏 | 两处生产者相邻，构成单段 |
| `card` | `_card_candidates`→`Cards.candidates`（逐张手牌） | 手牌区／目标选择／拖放 | `detail` 按需（`on_demand`） |
| `chain` | `Cards.continuation`（连段） | 连段选择 | 相位／状态互斥分支 |
| `manual` | `_manual_candidates` | 身体栏详情／动作行 | 装备件数驱动，26 件时最贵之一 |
| `item` | `_item_candidates`、`Consumables.noncombat_candidates`、逐件 `item_discard` | 道具区／背包／目标网格 | **多段组**（见 §3.2） |
| `pressure` | `calm`（深呼吸） | 底栏 | |
| `flow` | `end`／`finish_prepare`／`finish_rest`／`finish_pack`、`departure.gd` 两处 | 底栏／页面 | 多生产者，多数相邻 |
| `route` | `travel_step`、`_route_candidates`、`depart`、`departure.gd` | 地图／路线页 | 相位限 map/travel/departure |
| `surrender` | `_build_candidates` 内联 | 动作栏 | 战斗且仍有敌人 |
| `status_toggle` | `_build_candidates` 内联 | 状态区 | `charge>0` 且非过载 |
| `flask` | `ManaFlask.candidates` | 魔瓶入口 | |
| `prison` | `Prison.candidates`（经 `Prison.add`，硬编码组名）、`prison.gd` 直呼点 | 监狱页 | 相位限 captured/inspection/prison |
| `rest_service` | `_phase_candidates` 内联 4 条 | 休息页 | 相位限 rest_choice |
| `reward` | `_phase_candidates` 内联、`RelicBundle.candidates`、`departure.gd` | 奖励页 | 相位限 reward/cleared |
| `retain` | `_phase_candidates` 内联 | 保留选牌 | `pending_retain` |
| `service`／`service_release`／`service_remove`／`service_flow` | `Services.candidates`／`paid_candidate(group=…)` | 商店／宝箱／服务页 | 4 个组同一生产模块 |
| `event` | `Events.candidates`（读冻结 `room_event.options`） | 事件页 | 相位限 event |
| `demo_exit` | `DemoExit.candidates` | 结算页 | 相位限 cleared |
| `action` | 默认值，**当前无调用点** | — | 保留默认值不改 |

### 3.2 段（run）结构

- 段＝构建序列里的极大同组连续段；**多段组今天只有 `item`**（战斗中最坏 3 段：
  `_item_candidates` → `Consumables.noncombat_candidates` → 逐件 `item_discard`，被 `route`/`surrender`/`flask` 等隔开），
  `flow`／`reward`／`route` 的多生产者若相邻即并为一段。
- 段边界由构建序列决定，不由调用者声明：M1 在追加时比较"当前段的组名与本次行的组名"，
  不同则开新段（被作用域过滤掉的行也参与这个比较）——因此 `candidate_runs(["item"])` 在战斗里返回 3 段而不是 1 段。
- Part I 的提交复核按段推进即可保证"第一条命中"与全量构建序一致（段是构建序的连续切分）。

### 3.3 早退守卫（M1 内部，闭合校验对象）

- 规则：守卫**只允许**出现在"该 builder（含其独占被调用的子函数）只追加单一组"的位置，形如
  `if not scope.is_empty() and not scope.has("<组名>"): return`；**作用域为空＝全量，任何守卫都不得跳过**。
- 允许加守卫的 builder（组名与 §3.1 一致）：`_wall_move_candidates`→`wall_move`、`_posture_candidates`→`posture`、
  `_attack_candidates`／`_equipment_spell_candidates`→`attack`、`_card_candidates`（经 `Cards.candidates`）→`card`、
  `_manual_candidates`→`manual`、`_item_candidates`→`item`、`Consumables.candidates`／`noncombat_candidates`→`item`、
  `ManaFlask.candidates`→`flask`、`Prison.candidates`／`Prison.Space.candidates`→`prison`、`Events.candidates`→`event`、
  `RelicBundle.candidates`→`reward`、`DemoExit.candidates`→`demo_exit`、`Cards.continuation`→`chain`。
- **不得**加守卫（单函数多组或含多组分支）：`_build_candidates`／`_phase_candidates`／`_route_candidates`（`route` 单一但
  与内联站点同批，允许但不要求）、`Services.candidates`／`paid_candidate`（`service`／`service_release`／`service_remove`／
  `service_flow`）、`Departure.candidates`（`reward`＋`flow` 交错）。这些位置由 `_candidate` 的行级过滤承担，
  多建几行不是正确性问题，漏建才是。
- 守卫正确性的判据不是"看起来对"，而是 §5 场景 4 的**动态按组闭环**：对每个组名 G，
  `candidate_runs([G])` 展平后必须与 `candidates()` 中 `group==G` 的行**逐字段逐顺序**相同
  （夹具矩阵上全跑）。守卫漏建/误跳行 → 该断言必红；守卫漏加只是少省一点时间，不算错。
- 静态补强（防组名漂移）：`core/` 中每个 `scope.has("…")` 的组字面量必须出现在同文件的 `_candidate(...)` 组字面量里；
  `core/` 中 `_candidate(...)` 用到的组字面量必须都在 §3.1 的 24 组 ＋ 默认 `action` 内。

### 3.4 覆盖口径（本片需要证明到哪一层）

本片**不**主张"某 kind 只作废某些组"（那需要 §9.4 的字段依赖表）。本片只要求下面三条可判定的事实：

1. **完备**：`candidate_runs([])`／无作用域构建产出的段集合＝`candidates()` 的段集合；在任一作用域下，
   未请求的组**不得**影响已请求组的行内容（行内容由段落构造决定，与过滤无关）。
2. **同序**：段序列与行内顺序与全量构建一致（逐段比对可判）。
3. **可达**：`core/` 里出现的每个组字面量都必须属于某个守卫的声明集或某个不加守卫的内联站点
   （表外即红，§5 场景 4），不得存在"任何作用域下都建不出来的组"。

## 4. 失效、回退与强制全量

### 4.1 强制全量入口（协调者 2026-09-17 硬约束；**一行不改**）

`ui/main.gd:_resume_snapshot`（读档／继续）、`restart()`（新局／练习）、`_quick_sl()`（快速 SL）、
任何"整个游戏世界被替换"的路径：各自继续走 `game.restore_snapshot`／`restart_snapshot` → `game.get_view()` 全量。
- 本片**不引入**增量路径，因此这些入口天然只产全量候选；契约要求**保持**该性质，并由 §5 场景 7 把它锁成断言
  （读档／新局后的首次 `view.candidates` 必须逐字段等于同状态全量构建，且不得经过任何局部/增量产物）。
- Part II 落地时必须在这四个入口**显式失效**增量（一次性强制全量标记），并且**回退条件必须覆盖它们**：
  强制全量入口 ⊆ 回退条件（同一节陈述）。失效判据（写死）：①入口被调用即置一次性"强制全量"标记，
  下一次视图构建消费并清除；②版本不连续（`new_version != base_version + 1`，`restore_snapshot` 会把 version 抬到
  `max(prev,saved)+1`）一律视为不可增量；③base 视图不是当前世界的视图（phase／room／`room_event` 标识变化）→ 不可增量。

### 4.2 回退条件枚举（Part I 已实现部分）

| 条件 | 行为 |
| --- | --- |
| `candidate_runs` 收到空 groups、未知组名、`"*"` | 返回 `[]`，调用方必须全量 |
| 提交复核逐段筛查**未命中** | 回落全量 `candidates()` 复核一次；仍未命中 → 现有拒绝文案 |
| 任何作用域构建的段集合/行内容与全量不一致 | 视为缺陷（§5 场景 1 红），不得以"回退"掩盖 |
| 读档／新局／快速 SL／外部快照渲染 | 全量（§4.1） |

## 5. Gherkin（场景名 → 既有 case 文件的具名 check；**正例走真实公开命令**）

用例文件沿用既有分类文件，不新建流程文件与看板；夹具复用 `tests/game_fixture.gd` 与既有真实输入助手。

1. `candidate_runs_match_full_build`（规则分类 `architecture`，`tests/architecture_cases.gd`）
   - Given 夹具矩阵：战斗 0／12／26 件装备、整备、休息、商店、事件、监狱各一个真实夹具（同种子）；
   - When 对每个夹具取 `g.candidates()` 的段分解，再取 `g.candidate_runs(全部 24 组名)`；
   - Then 两者**段数、段序、每段组名、每行逐字段**相同；且 `candidate_runs([])`／未知组名／`["*"]` → `[]`（反例，见场景 3）。
2. `submit_screen_matches_full_scan`（规则分类 `architecture`，`tests/architecture_cases.gd`）
   - Given 同种子双实例：A＝真实 `dispatch`；B＝测试侧子类把 `_candidate_by_id` 换回"全量构建＋首命中"（既有 `PreviewCountingGame` 式 fixture 子类写法，生产源码不留开关/计数器）；
   - When 对每个夹具与每个**可提交候选**（遍历该夹具全部候选，含 invalid 反例）执行真实 `dispatch(id, version)`；
   - Then 两侧返回字典逐键相同、`chosen` 行逐字段相同、`export_snapshot()`／日志／各随机域计数相同；
     invalid 候选与陈旧版本两条拒绝路径文案相同；未命中候选（伪造 id）文案相同。
3. `candidate_runs_scope_fail_closed`（规则分类 `architecture`）
   - Given 任意夹具；When `candidate_runs([])`、`candidate_runs(["no_such_group"])`、`candidate_runs(["*"])`；
   - Then 返回 `[]`（不是全部、不是异常、不改状态）。
4. `group_scope_closure`（规则分类 `architecture`；动态闭环为主，源文本扫描为辅）
   - Given 夹具矩阵同场景 1；测试内用手写字面量列出 §3.1 的 24 组名 ＋ 默认 `action`（**枚举用清单**，
     式样同 `tests/check_index_edges.gd` 的 `DOMAINS`：手写、逐条带理由，不是产品侧映射表）；
   - When ①对每个 G 取 `g.candidate_runs([G])` 并展平，与 `g.candidates().filter(c.group==G)` 逐字段逐顺序比对；
     ②取 `g.candidate_runs(全部组名)` 展平，与 `g.candidates()` 逐字段逐顺序比对；
   - Then ①两处全部相同（守卫漏建/误跳行、组名写错都必红）；②相同；
     反例：把某守卫的组名改一个字母 → 该组在 ① 中行缺失或多余，红，并打印组名与函数名；
   - 源文本补强：读取 `core/**.gd`，断言每个 `scope.has("…")` 的组字面量出现在同文件的 `_candidate(...)` 组字面量里，
     且 `core/` 出现的所有 `_candidate(...)` 组字面量 ∈ §3.1 的 24 组 ∪ {`action`}，表外即红。
5. `dispatch_result_shape_unchanged`（规则分类 `core`，`tests/test_game.gd` 既有 `_core_cases`）
   - Given 任意真实候选；When 提交成功与被拒各一次；
   - Then 返回字典的键集合与键序、`error` 文案、`state.version` 语义与现状一致（本片**不新增返回键**）。
6. `event_domain_frozen_candidates`（界面分类 `events`，`tests/event_ui_cases.gd`）
   - Given 进入事件（选项冻结）；When 依次提交选项／奖励／离开；
   - Then `view.candidates` 逐字段等于同状态全量构建、`state.room_event.options` 不被本片改动；
     冻结 oracle（§7）保持绿——事件域不参与局部构建。
7. `load_paths_build_full_candidates`（界面分类 `persistence`，`tests/persistence_ui_cases.gd`）
   - Given 已有一份存档与一个已开始的本局；When 真实走 `_resume_snapshot`（读档）、`restart()`（新局）、`_quick_sl()`；
   - Then 每条路径后的首次 `ui.view.candidates` 逐字段逐顺序等于"同状态独立实例全量 `get_view().candidates`"，
     且没有经过任何局部段产物（本片以"结果等价 + 代码路径断言（§5 场景 4 的静态扫描不含增量路径）"作为判据）。

## 6. validator procedure（agent 可运行；操作系统的真实界面）

宿主：`tests/ui_smoke.gd` + `tools/check.ps1`；操作必须走真实 viewport 输入（`move_mouse`／`mouse_button`／`flip`／`start_drag`／`release_target`），
测试存档隔离（`ui.persistence_enabled=false`），不默认截图。

1. 范围预检（不算通过）：
   `& tools/check.ps1 -Suite architecture,core,runner,battle_saturation,rewards,guard,persistence -Impact -ListOnly`
   → 打印 `PLAN ONLY:` 且列出所选分类。
2. 规则 + 窗口：
   `& tools/check.ps1 -Suite architecture,core,runner,battle_saturation,rewards,guard,persistence -Impact -TimeoutSeconds 900`
   → 退出码 0；`SUITE RESULT: PASS …` 全部；`UI PASS: N assertions`。
   `& tools/check.ps1 -UIOnly -UISuite display,interface,targeting,basic_attacks,body_layout,events,persistence -TimeoutSeconds 900`
   → 退出码 0；各 `SUITE RESULT: PASS <ui>`；`summary.json` `status=passed` 且 `before==after` 指纹。
3. 人的路径证明（按顺序操作界面，判据是 suite 的布尔 check）：
   - 26 件装备的战斗里，依次：打出一张牌 → 攻击 → 结束回合 → 翻面手牌 → 点选敌人 → 开身体栏 → 用一件道具；
     每一步之后行动栏内容与全量构建一致（行为断言在 suite 内，人的路径只证明"操作能得到这些 check"）。
   - 读档：点击继续／读档 → 再打出一张牌；新局：重启 → 再操作一次；快速 SL：恢复场景起点 → 再操作一次。
   - 事件：进入一个事件 → 依次选完选项 → 离开。
4. 归属判定：失败原因分"实现代码／测试脚本／环境／程序本身"；不确定就保持未分类上报，不自动改产品代码。
5. 证据：`build/checks/<id>/check-rules.log`、`check-ui.log`、`summary.json`；结果与域写 `docs/verification.md`（validator 负责）。

## 7. 判据、完成定义与测量

命令（必跑，一次，不无故重复）：

```
& tools/check.ps1 -Suite architecture,core,runner,battle_saturation,rewards,guard,persistence -Impact -TimeoutSeconds 900
& tools/check.ps1 -UIOnly -UISuite display,interface,targeting,basic_attacks,body_layout,events,persistence -TimeoutSeconds 900
& tools/check-index.ps1                     # 零漂移；改动 core/ 后必须 -Write 并与源码同批提交
& <godot console exe> --headless --path . --script res://build/event-oracle-20260916/event_oracle.gd -- --baseline=build/event-oracle-20260916/baseline.json
& <godot console exe> --headless --path . --script res://build/transition-oracle-20260916/transition_oracle.gd -- --baseline=build/transition-oracle-20260916/baseline.json
```

- 两个冻结 oracle 必须：`EVENT RESULT: PASS (94 scenarios, 0 failures)`／`TRANSITION RESULT: PASS (31 scenarios, 0 failures)`，
  `EVENTDIGEST`／`TRANSITIONDIGEST` 与基线**逐字相同**，引擎错误日志 **0 行**（oracle 显式 `quit(0)`，退出码不反映脚本错误）。
- 场景：§5 的 1–7 全部具名 check 通过。**场景 1、2、4 是主判据**；5、6、7 锁接口面与既有不变量。
- 测量（**参考，不承诺绝对毫秒**）：沿用 `docs/equipment-performance.md:45` 的配对协议——
  同一夹具交替执行、2 次热身 + 15 次有效配对、报逐对比值中位与两侧独立中位；样本轴 0／12／26 件 × battle／departure；
  主要记录**结构计数**：每次成功提交的"全表构建次数"（现状 2 → 本片 1）、
  提交复核实际构建的**段数**（按 kind 记录：`attack`／`card` 应显著少于全表）。
  计时脚本与 JSON 只放已忽略的 `build/candidate-delta-<date>/`，摘要（机器、件数、kind、段数、中位数、样本数）
  登记 `docs/verification.md` 后删除原始目录；生产源码不得留计数器、开关或计时钩子。
- 红集必须 ⊆ 既有六项：`card_power` 5／`installed_tools` 1／`tower_progression` 10＋1／`hand_assist` 1／
  `home_persistence` 3／`interface` 1（28 张 `witch_*` 卡缺立绘）；新增红项一律视为本片未完成。
- 算未完成（任一）：任一必跑套件未执行／失败／跳过得无授权；oracle 摘要漂移或错误日志非 0 行；
  `check-index.ps1` 非 0；测试用旧版本结果拼接最终结论；删／弱化既有断言换绿灯；
  候选行字段、取值、顺序或 `dispatch` 返回形状有任何变化；读档／新局／快速 SL 路径被改动；
  生产源码留计数器／计时钩子；提交 `build/` 产物；宣称 0 次全表构建或宣称帧率提升。
- 另需（小步、同批）：根 `AGENTS.md` 文档入口表加一行 `docs/candidate-delta.md`。

## 8. 依赖约束（cleaner 可核对）

- `core` 不得 preload `ui`；本片不新增文件（Part II 才需要 `ui/candidate_delta.gd`，见 §9.4）。
- `candidate_runs`：只读、无状态、无跨调用保留；容器新建；输入域为空/未知即 `[]`。
- `dispatch`：入参与返回**形状不变**；不得新增返回键；不得改判定顺序（六个 `validate` → 版本 → 复核 → `valid`）；
  不得把 `chosen` 的来源改成外部输入（F10）。
- 段与顺序：不得重排构建序列、不得改变任何组的相对位置、不得合并跨组的段。
- 守卫：只允许"作用域非空且不含本组"的早退；只允许加在"单函数单组"的 builder 上（§3.3）；
  不得改变 `scope` 为空时的行为；不得用守卫实现行级筛选（行级筛选只在 `_candidate`）。
- 只读复用：仍限单次调用内；不得引入跨提交缓存、不得缓存候选/资格/预览/费用。
- 文案与数值：一个字不动；不新增拒绝文案（F10 的教训）。

## 9. 与协调者派单的差异（需协调者／人确认）

### 9.1 本片实现提交侧局部筛查，视图侧增量整片后移

派单的切口（核心"按组取候选"入口 + **执行端声明作废组** + **UI 用增量替换整表**）中，
前一条本片落地；后两条**本片不实现**，理由与证据如下（不是省事，是覆盖面无法闭合）：

### 9.2 视图侧增量需要"哪些 kind 作废哪些组"，而该表今天无法按 kind 粗粒度证明

- 每个候选行都要过 `_candidate` 的通用读取面（F8）：`energy`／魔力余额（写 `valid`/`reason`）、
  `pressure_sources`＋装备/遗物（写 `risk`）、目标装备锁定/诅咒（写 `reason`）、
  `CopyRouter.text(copy)` 的站点 builder（可读任意 state）。
- 具体耦合实例：`status_toggle` 只改 `state.charge_all`，而 `charge_bonus()` 读 `charge_all`（`core/game.gd:1636`），
  `charge_bonus()` 又被 `kick_profile`、`_attack_offer`（`core/game.gd`，`kick_profile` 供攻击与监狱踢击）
  与 `Cards.bind_payload`（`core/card_effects.gd:544`，卡牌伤害 payload）读取 →
  "只作废 `status_toggle` 一组"不成立，至少还要 `attack`／`card`／`chain` 等。
- 因此"某 kind 只作废某些组"的每一行都要按**行级读取域**证明；现在写出来的粗粒度声明只能是 `["*"]`（全量），
  等于没有增量。要做到"声明可信"，需要**状态字段→组/行的依赖表**（含每个 `copy` builder 的读取集）——
  这正是派单列为后续片的"表化"。**先做覆盖面，本片不假装覆盖到了。**

### 9.3 为什么提交侧局部筛查不是被归档否决的那个方向

归档否决的是"UI 把候选行（外部数据）连同版本交给 `dispatch`"（`docs/history/submit-dedup-2026-09-17.md`）：
代价是唯一提交入口出现第二种入参、取值来源变成外部、新增玩家可见拒绝文案。
本片：入参不变、取值仍由核心自建、无新文案、版本闸与六个 `validate` 次序不变，
只是**构建到什么程度才停**——"核心只是不必把整表建出来才能找到那一行"。
若要更保守，可把本片缩到只留 `candidate_runs` 只读入口、不动 `dispatch`（收益归零，但仍为后续片铺路）。

### 9.4 后续片（Part II）的最小形态（本片只写契约）

- `core/game_view.gd:build` 增加"候选作用域"（只构建被作废组并只对这批行做逐 action 投影）；
- 执行端在既有 `dispatch`／`_execute` 分支上声明 `candidate_groups`（默认 `"*"`＝全量；未声明即全量）；
- UI 合并：`ui/candidate_delta.gd`（新文件，需授权）提供纯函数 `runs_of(rows)` 与
  `merge(base_rows, new_runs, dirty) -> {ok,error,candidates,note}`，落地规则：
  按旧段序走一遍，命中 dirty 组的旧段→取该组新段队列的下一段，未命中→保留旧段；
  队列空（段消失）／收尾仍有剩余（段新增）／未知组名／`"*"` → **整次回退全量**；
  合并结果必须与全量构建**逐字段逐顺序**相同（双实例对照）；
- 强制全量入口 ⊆ 回退条件（§4.1）；诊断字段只允许"上一次提交的路径说明"这类**单值、逐次覆盖、进程内**的测试可读记录
  （式样同 `_transition_log`），不得做成计数器或历史。
- Part II 必须自带的最小判据（派单已点名，本片不得遗漏）：①**增量结果 ≡ 全量结果**（同状态双实例、逐字段逐顺序、
  正例走真实公开命令 `dispatch` ＋真实点击）；②**未知/未声明 kind → 回退全量**；③**闭环检查**：每个 `dispatch`／
  `_execute` 执行分支都必须声明作废组或显式声明"不作废任何组"，表外即红（源文本扫描 ＋ 声明锐化项必须有等价场景）；
  ④**事件域不受影响**（冻结选项不参与增量，事件分支一律全量）；⑤读档／新局／快速 SL 的首次候选必须是全量产物（§4.1）。

## 10. 假设与最可能爆的点（含 needs-human-review 理由）

- **A1（最可能爆）**：§9.2 的通用读取面意味着"高频 kind 只作废少数组"很难成立；若后续片仍想拿到 0 次全表构建，
  必须先做字段依赖表。本片以**结构计数**（2 → 1）为主判据，**不承诺**毫秒收益，也不宣称 0。
- **A2**：守卫的组名漂移会让某个作用域下的组建不出来 → 本片用 §5 场景 4（守卫↔字面量闭合）＋场景 1（段≡全量）
  兜住；提交复核另有"未命中回落全量"的 fail-closed，最坏只是慢，不会误拒。
- **A3**：段序列重构若不保序（重排、合并跨组段、把内联站点移出序列）会静默改变"第一条命中"的语义 →
  场景 1、2 必须在**全候选**上比（含 invalid 与伪造 id 的反例），不能只比"能打出的牌"。
- **A4**：`dispatch` 内部改动与已归档方向相邻（§9.3）→ 需要协调者记录人裁；未记录不得动手。
- **A5**：`item` 组的多段结构（§3.2）在后续片的按段替换里是最容易错的地方（段消失/新增的守卫）→ 后续片必须
  对 `item` 单列场景；本片只在场景 1 里把它作为段结构与全量比对的一部分。
- **A6**：套件覆盖有限：`core/game.gd` 在冻结索引里被 93 个套件引用，本片 DoD 只列 7 个规则套件（+ 7 个界面套件）
  并以 `-Impact` 合并交叉分类；未跑到的分类按域登记为"未验证"，**不得**声称全量回归。
- **A7（flag 理由）**：本片偏离派单：视图侧增量与"执行端声明"整片后移到 Part II（§9.1–9.2，证据在手），
  而把收益点放在提交复核的局部筛查上（§9.3，需人明确背书它不在归档否决范围内）。判 `needs-human-review`。
- **A8**：`docs/response-pipeline.md` §4.1 的"禁止跨提交缓存候选"与 Part II 的"UI 沿用上一版候选行"字面冲突 →
  后续片必须先在 `response-pipeline.md` 加注（UI 侧按组沿用＝授权；核心侧仍禁止），否则后来者会按旧禁令判红。本片不触碰该条。

## 11. 后续片清单（不在本片）

1. Part II（视图侧增量 + 执行端声明 + 声明覆盖闭环 + 强制全量失效），前置：字段依赖分析。
2. 字段依赖表（状态字段→组/行；含 `copy` builder 读取集）与声明锐化。
3. 窗口与输入队列（`docs/response-pipeline.md` 末尾，未排期）。
