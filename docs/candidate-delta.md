# 候选局部筛查与依赖声明（candidate-delta）

规划者契约（planner contract）**v2**，2026-09-17。分支 `event-pipeline-unification`，HEAD `eb85733`（v1 已提交于 `41f37fc`）。
状态：**`needs-human-review`**——理由见 §11。实现者开工前置＝**协调者记录的人 OK 覆盖本片切线**。
**v2 变更（人裁定 2026-09-17）**：目标由"2 → 1"改为 **0**；v1 的 Part I／Part II 切分**作废**——
字段依赖表与视图侧增量并入本片，全局构建只允许出现在**世界替换**。v1 的组清单、段结构、提交复核局部化设计保留。
**不写执行结果**：通过／失败／未执行只登记 `docs/verification.md`。
**工作区提示**：`spire-godot/tests/check_index.json` 与 `spire-godot/tests/normal_play_cases.gd` 有**他人未提交改动**；
本契约未触碰这两处，实现者不得把它们混入本片提交；`check-index.ps1 -Write` 需与索引改动方协调同批。
行号只作复算线索；**函数名、组名、字段名、稳定 id 才是锚点**。

## 0. 动机：为什么今天"任意操作都要全局筛查"，以及为什么可以不是

- 今天 `candidates()` 是**唯一**的候选构建入口，而全仓**没有一句"哪一行候选读取哪些 state 字段"的声明**。
  构建器因此无法回答"这次操作改了什么、谁会受影响"，只能整表重来。
- 两个消费点各自全建一次：`core/game.gd:dispatch` 的 `for c in candidates():`（**只为找到一行**）
  与 `core/game_view.gd:build` 的 `var actions=g.candidates()`（**只为刷新其中几组**）。
  实测一次成功提交占一次点击约 30–40%（`docs/verification.md` 2026-09-17「卡顿定位」）。
- **可证明的替代是存在的**：写入侧不必靠人声明——提交事务本来就留下 `original` 与已安装的 `state`，
  两者的**字段差分**就是"这次操作改了什么"（GDScript 对 `Dictionary`/`Array` 的 `==` 是逐值比较，代价远低于候选构建）。
  读取侧由**依赖表**给出（"候选行／组 → 它读取的 state 字段"，含间接读取）。
  两者的交集就是"必须重建的组"与"必须重建的界面节"。
- 于是**全局构建只剩一种合法场景：世界替换**（读档／继续／新局／练习／快速 SL／就地恢复快照）——
  那时整个状态对象图被换掉，没有可比的差分，也不该假装有。
- **本片目标：每个有效操作的"经 `candidates()` 的全表构建次数 = 0`**（候选一律经按组入口构建）；
  全局构建只属于世界替换。相位／结构变化时，差分命中 `phase` 等字段 → 作废集合＝全部组 → 走按组入口重建全部组：
  **调用口径的 0 成立，但工作量≈全表**，此类情况必须按 §9 的伴侣指标如实报告，不得宣称相位切换变快。

## 1. 领域、已核实事实与非目标

领域：一次有效操作（提交）前后，**候选与界面投影的构建范围**，以及支撑它的**字段依赖声明**。
不含：输入层、存档内容、窗口与队列、随机域、打包发布。

| # | 事实 | 证据位置 |
| --- | --- | --- |
| F1 | `candidates()` 唯一入口 `_build_candidates()`：按**固定调用序**追加（各相位 helper → `Consumables.noncombat_candidates` → `_route_candidates` → 投降 → 逐件 `item_discard` → `ManaFlask.candidates` → `status_toggle`），外层 `_begin_equipment_read()` 包裹并还原 | `core/game.gd:candidates`/`_build_candidates`/`_phase_candidates` |
| F2 | 候选行由 `_candidate(out,payload,label,copy,cost,mana,reason,risk,group)` 组装，含 `id`（payload 的 sha256 前 24 位）／`payload`／`label`／`detail`（卡牌按需）／`cost`／`mana`／`mana_payment`／`valid`／`reason`／`risk`／`group`；**当前无调用点使用默认组 `"action"`**，实际 24 组 | `core/game.gd:_candidate`；本轮全仓抽取 |
| F3 | 组＝现成分组键；UI 按组取（`ui/action_index.gd` 的 `by_id`/`by_group`/`select`/`find`/`first_usable`）。唯一按全局顺序读候选的 UI 点是 `ui/main.gd:1561`（监狱场景过滤后保序） | `ui/action_index.gd`；`rg -n "view\.candidates" ui/` |
| F4 | UI 唯一视图赋值点 `ui/main.gd:371 view=game.get_view() if snapshot.is_empty() else snapshot`；`:381 actions=ActionIndex.new(view.candidates)`。`ui.view` 本来就跨提交持有候选 | `ui/main.gd` |
| F5 | `_submit`：`game.dispatch(c.id, view.version)` → **无条件** `game.get_view()` → `render(updated)`。`get_view()` 全仓只有 4 个调用点：`:281`（`_resume_snapshot`）、`:371`（render 空快照＝初始化兜底）、`:1919`（`_submit`）、`:1966`（`restart`）；外部 screen 一律 `render(ui.view)`，不触发候选构建 | `ui/main.gd`；`rg -n "render\(\)" ui/` 为 0 命中 |
| F6 | 路由器现状（**不动**）：`dispatch` 的 `payload.kind` if/elif 6 支＋`_execute` 的 `match p.kind` 30 标签＋`else`；`Events.execute` 的 `match p.action`、`apply_effects` 的 `match effect.op` 亦不动 | `core/game.gd` |
| F7 | 事件域不重算：候选读冻结的 `state.room_event.options` 与 `stage`，产物全在 `event` 组 | `core/room_events.gd:candidates`／`:447` |
| F8 | 每行都要过 `_candidate` 的通用读取面：`energy`／魔力余额 → `valid`/`reason`；`Pressure.action_risk`（读 `pressure_sources`＋装备/遗物）与 `Cards.magic_card_traction`（读手牌修正）→ `risk`；目标装备 `lock_only`／诅咒 → `reason`；`CopyRouter.text(copy)` 的正文由站点 builder 自定（可读任意 state） | `core/game.gd:_candidate`；`core/pressure.gd:action_risk` |
| F9 | 两个冻结 oracle：`EVENTDIGEST` 覆盖 `candidates:"sha256(JSON.stringify(g.candidates()))"`（候选行整体）＋视图/快照/随机域摘要；迁移 oracle 冻结 before/after/`commit_logs`/`log_texts` 摘要 | 两份 `build/*-oracle-20260916/baseline.json` 与 oracle 脚本 |
| F10 | 已归档否决方向（**不得重提**）：UI 把候选行作为外部数据连同版本交给唯一提交入口。本契约不新增入参、不改判定与文案 | `docs/history/submit-dedup-2026-09-17.md` |
| F11 | **`present(dirty)`／`_section_*`／dirty 机制在 HEAD 未落地**：`ui/main.gd` 只有 `render(snapshot)` 整树入口（`layout.begin_frame`/`end_frame` 复用 hero／body／敌人实例）；`docs/response-pipeline.md` §3.2–§3.4 是**未落地的 draft**；已实现的键只有 `ui/shell/body_sidebar.gd:_presentation_key` | `ui/main.gd`；`ui/shell/body_sidebar.gd` |
| F12 | 两个 oracle **都不对 `dispatch` 结果整体取摘要**：事件 oracle 记 `"ok"/"rejected"`＋`error` 字符串，迁移 oracle 的行只含 before/after/日志摘要 → **在 OK 结果上加键对 oracle 不可见** | 两份 oracle 脚本的 `_dispatch`/`_record` |
| F13 | 规模基线（本轮只读派生，3 层调用图）：候选路径 24 个根 → 411 个函数／4362 行，读到 **97** 个 `state.<字段>`；`state` 顶层字面键 **121**（＋`departure`/`rooms`/`demo_*` 等后续 13 个）；全 `core/` 读取面 123（含 `.get(` 噪声） | 本轮脚本（式样同 `tests/check_index.gd` 的抽取规则，落地时以该批次的派生脚本为准） |
| F14 | 读档／新局／快速 SL：`_resume_snapshot` 经 `restore_snapshot`（version 抬到 `max(prev,saved)+1`）→ `get_view()`；`restart()` 同 | `ui/main.gd:_resume_snapshot`/`restart`/`_quick_sl` |

非目标（**不变项**，逐条对应人裁定）：
- 三层路由器（`kind`／`action`／`op`）不动；不重构 `dispatch` 分支结构。
- `dispatch(candidate_id, expected_version)` 的**入参签名与接受/拒绝语义不动**（OK 结果只允许**加性键**，见 §3.3）。
- 候选行内容、顺序、费用、文案、分组名一字不改（F9 的 oracle 是硬判据）。
- 不新增核心跨提交缓存；不重提 `submit-dedup`（F10）；不动读档／新局／快速 SL 的全量路径（§5.1）。
- 事件域不参与增量（F7）；不做窗口／输入队列（`docs/response-pipeline.md` 末尾，未排期）。
- 不新增运行时依赖；不打包、不发版、不推送；不做无关格式化。

## 2. 切口与批次（同一片，按可独立完工的顺序推进）

**切口**：把候选表的构建从"唯一入口全建"改成"**由字段依赖声明点名的组按需构建**"，
并把同一份声明同时用于**界面投影的脏集**与**提交复核的筛查**。四个组件：

| 组件 | 边界（谁） | 接口（小） | 内部（藏） |
| --- | --- | --- | --- |
| A 依赖声明 | `core/candidate_deps.gd`（新） | `field_universe()`／`group_reads(g)`／`dirty_groups(writes)`／`section_reads(s)`／`sections_for(writes)`（§3.1） | 读取集数据、手写 edges、理由注释 |
| B 按组构建 | `core/game.gd`（`_build_candidates` 路径） | `candidate_runs(groups)`（§3.2）／`get_view_scoped(groups)`（§3.4） | 行级作用域过滤、段边界跟踪、逐 action 投影的作用域 |
| C 提交侧 | `core/game.gd:dispatch` | 入参/判定不变；OK 结果**加性键** `candidate_scope`（§3.3） | 逐段命中即止＋未命中回落全量；写入差分 |
| D 视图侧 | `ui/main.gd:_submit` ＋ `ui/candidate_delta.gd`（新） | `runs_of(rows)`／`merge(base_rows, new_runs, scope)`（§3.5） | 段替换、守卫、回退＝按组入口重建全组 |

批次（每批一次具名判据，**不得跨批开工**；每批可独立提交与复核）：

| 批 | 范围 | 该批判据 |
| --- | --- | --- |
| **C0** | 依赖表（派生＋手写 edges＋冻结摘要＋零漂移自检）；**行为零变化** | §7 场景 1 |
| **C1** | 段化构建＋`candidate_runs(groups)`＋按组闭环；**无调用方变化** | §7 场景 2、6 |
| **C2** | 提交复核局部化（`dispatch` 内）＋写入差分＋`candidate_scope` 加性键 | §7 场景 3、5、6 |
| **C3** | 视图侧增量（`get_view_scoped` ＋ UI 合并 ＋ 回退） | §7 场景 4、7、8 |
| **C4** | 投影侧脏集（`present(dirty)` ＋ `_section_*` 节键，**规格来源＝`docs/response-pipeline.md` §3.3／§3.4，不另造**），脏集由依赖表导出 | §7 场景 9（复用该契约 §9 场景 3／4／7 的具名 check） |

允许依赖方向：`core` 不 preload `ui`；仅 `ui/main.gd` 允许 preload core；`ui/candidate_delta.gd` 为纯 static
（只吃传入的 Array/Dictionary，不吃 game、控件，不跨刷新缓存）。
C4 涉及的 `response-pipeline` §3.3／§3.4 **在 HEAD 未落地**（F11）：本片 C4 需实现它们；
若协调者决定 C4 单独成片走原契约，**删除 C4 即可，C0–C3 与判据不受影响**（本契约已按此解耦）。

## 3. 接口契约

### 3.1 `core/candidate_deps.gd`（新，纯数据＋纯函数）

- 语义：**"候选行／组 → 它读取的 state 字段"** 的唯一出处，同时给出投影侧"节 → 字段"。
  读取集必须含**间接读取**：①`_candidate` 通用面（F8）；②站点 `copy` builder；
  ③各组生产者自身（含经 `Equipment`／`Relics`／`Cards`／`Pressure`／`SpecialEquipment` 等模块门面的读取）。
- 接口：
  - `static func field_universe() -> Array`：顶层 state 字段全集（含无读取者的字段，如 `version`／`logs`／`summary`）。
  - `static func group_reads(group: String) -> Array`：该组读取集；未知组名返回 `[]` 且不静默（调用方按 fail-closed 处理）。
  - `static func dirty_groups(writes: Array) -> Array`：`{ G : group_reads(G) ∩ writes ≠ ∅ }`；
    含 `"*"`、含 `field_universe()` 之外的字段、或任一组读取集标记不完整 → 返回 `["*"]`（全组）。
  - `static func section_reads(section: String) -> Array`／`static func sections_for(writes: Array) -> Array`（C4 用；
    节名与语义**照抄** `response-pipeline.md` §3.4）。
- 表**只增不猜**：每个读取集条目要么来自派生（调用图可达读取），要么是手写 edge 并**在文件内写明理由**
  （式样同 `tests/check_index_edges.gd`）。零漂移：冻结摘要＋自检（派生结果 ≠ 冻结即红），口径照 `tools/check-index.ps1`。
- 只读、无状态、不持游戏引用、不写 state。

### 3.2 `Game.candidate_runs(groups: Array) -> Array`（core，新，只读）

- 语义：按当前状态的既有构建序返回**段**；段＝构建序列中的**极大同组连续段**。返回 `[{group:String, rows:Array}]`，
  段序＝构建序，段内序＝构建序；`rows` 与同状态全量 `candidates()` 的对应段**逐字段相同**。
- **作用域过滤在行级**（`_candidate` 内）：不在作用域的行**不构造**，但其组名仍参与段边界判定，
  因此段边界与全量构建一致。**本片不加 builder 级早退守卫**（跳过整段会破坏段边界；守卫是后续可选优化，须自带等价证据）。
- 输入域与 fail-closed：`groups=[]` → `[]`；含未知组名 → `[]`；`groups=["*"]` → **全部组**（唯一合法的"全部"拼法）。
  空输入**绝不**等价于"全部"。
- 只读：不写 state、不推进随机、不改 version、不产日志与事件、不跨调用保留。
- 谁能调：`core/game.gd` 内部、`ui/main.gd`（经 §3.4）、测试。
- 信任依据：§7 场景 2（段 ≡ 全量：段数/段序/组名/逐字段）＋场景 6（fail-closed）。

### 3.3 `dispatch`：局部复核 ＋ 加性键 `candidate_scope`

- 提交复核：`for c in candidates():` 改为**按构建序逐段构建、命中即止**（取**第一条** id 匹配行）；
  **未命中回落全量 `candidates()` 复核一次**，仍未命中才走现有拒绝文案。
  - **等价性论证**：①构建器只读（不写 state／不推进随机／不产日志／不改 version）；②顺序确定（段序＝调用序，段内序＝追加序，
    相位早退分支原样保留）；③无非命中副作用（只影响"建了多少"；state／日志／随机域计数／`export_snapshot()`／视图全不受影响）；
    ④命中的那一行就是全量构建中按追加顺序的第一条 id 匹配行，逐字段相同；未命中与拒绝文案逐字相同。
  - **步粒度不参与语义**：只取决于"按追加顺序的第一条匹配行"，检查必须在每次追加之后、按追加顺序进行。
- **写入差分**：成功提交末尾（所有状态变更之后、返回之前）核心计算
  `writes = { f ∈ field_universe() : original[f] != state[f] }`；`version` 显式排除（无候选读取者，由场景 1 断言守住）。
  差分字段超出 `field_universe()` → `writes=["*"]`（fail-closed）。
- **声明**：`candidate_scope = candidate_deps.dirty_groups(writes)`；OK 结果加 **`"candidate_scope": Array`**。
  语义＝"本次提交后必须重建的候选组"；`["*"]`＝全组（相位／结构变化或字段未知）。
  - **接口面**：入参、判定顺序（六个 `validate` → 版本 → 复核 → `valid`）、`error` 文案、`version` 语义全部不变；
    唯一变化是这个**加性键**（F12：两个冻结 oracle 都不对结果整体取摘要，因此不可见）。
- **与已归档"提交去重"的区别（保留这段，避免后人误判）**：本片**不改提交入参**、**不加核心跨提交缓存**、
  **不需要外部提交行**——候选仍由核心从当前状态自建，UI 仍只传 `candidate_id` 与版本（F10）。
- 谁能调：`dispatch` 内部唯一；不得把局部复核暴露成第二提交入口。

### 3.4 `Game.get_view_scoped(groups: Array) -> Dictionary`（core，新，只读）

- 语义：与 `get_view()` **同形**（同样键、其余字段完整），但：①`candidates` 只含点名组的行（构建序）；
  ②逐 action 的投影（`release_preview`／`casting`／`body_part`／`brief`／`brief_tags`）只对这批行计算；
  ③额外键 `candidate_runs`＝同一批行的段结构（供 §3.5 合并；段边界与全量构建一致）。
- 输入域：`["*"]` → 全部组（并把完整候选列表放回 `candidates`，调用方**不再合并**）；`[]` 或含未知组名 → fail-closed：
  `candidates=[]`、`candidate_runs=[]`（调用方必须回退，见 §3.5）。
- 只读、不写 state、不推进随机、不产日志；非空 `groups` 下**不得**再调 `get_view()` 或 `candidates()`。
- 谁能调：只允许 `ui/main.gd` 的增量路径与测试。

### 3.5 `ui/candidate_delta.gd`（新，纯 static）

- `static func runs_of(rows: Array) -> Array`：把扁平候选按极大同组连续段切分（纯函数）。
- `static func merge(base_rows: Array, new_runs: Array, scope: Array) -> Dictionary` →
  `{ok:bool, error:String, candidates:Array}`：
  - `scope` 含 `"*"` 或未知组名 → `{ok:false}`（调用方改走 `get_view_scoped(["*"])`，**不得**走 `get_view()`）；
  - 按旧段序走一遍：旧段组 ∈ scope → 取该组新段队列的下一段；否则保留旧段；
    队列空（段消失）／收尾仍有剩余（段新增）→ `{ok:false}`；
  - `ok=true` 时 `candidates` 必须与同状态全量构建**逐字段逐顺序**相同。
- 谁能调：`ui/main.gd:_submit` 的成功分支。**UI 不得自行推断作废集合**（scope 一律来自核心的 `candidate_scope`），
  不得自行判定资格、不得读 `game.state`。

### 3.6 计数口径（判据用，逐字沿用）

- **全表构建**：一次调用 `candidates()`（含 `get_view()` 内部那次）。
- **按组构建**：`candidate_runs(groups)`／`get_view_scoped(groups)`（含 `["*"]`＝全组重建）。
- **主判据**：**有效操作期间的全表构建次数 = 0**；全局构建只出现在世界替换（§5.1）。
- **伴侣指标（诚实列，必须同报）**：被重建组数 / 24（相位或结构变化时会等于全组，此时工作量≈全表，只是调用口径为 0），
  每次提交的 `writes` 规模，以及提交复核实际构建的段数与命中位置。

## 4. 组清单、段结构与读取集口径

### 4.1 组清单（今天实际 24 组 ＋ 未使用的默认 `action`）

| 组 | 生产者（构建序位置） | 消费方 | 备注 |
| --- | --- | --- | --- |
| `wall_move` | `_wall_move_candidates` | 动作栏／姿态区 | 相位限 battle/prepare/rest/prison 且有墙 |
| `posture` | `_posture_candidates` | 姿态区 | |
| `attack` | `_attack_candidates`、`_equipment_spell_candidates`、`witch_character.gd` | 动作栏 | 两处生产者相邻 → 单段 |
| `card` | `_card_candidates`→`Cards.candidates` | 手牌区／目标选择／拖放 | `detail` 按需 |
| `chain` | `Cards.continuation` | 连段选择 | 互斥分支 |
| `manual` | `_manual_candidates` | 身体栏详情／动作行 | 装备件数驱动，26 件时最贵之一 |
| `item` | `_item_candidates`、`Consumables.noncombat_candidates`、逐件 `item_discard` | 道具区／背包／目标网格 | **多段组**（§4.2） |
| `pressure` | `calm` | 底栏 | |
| `flow` | `end`／`finish_prepare`／`finish_rest`／`finish_pack`、`departure.gd` | 底栏／页面 | 相邻生产者合并为单段 |
| `route` | `travel_step`、`_route_candidates`、`depart`、`departure.gd` | 地图／路线页 | 相位限 map/travel/departure |
| `surrender` | `_build_candidates` 内联 | 动作栏 | 战斗且仍有敌人 |
| `status_toggle` | `_build_candidates` 内联 | 状态区 | `charge>0` 且非过载 |
| `flask` | `ManaFlask.candidates` | 魔瓶入口 | |
| `prison` | `Prison.candidates`（经 `Prison.add`，组名硬编码）、`prison.gd` 直呼点 | 监狱页 | 相位限 captured/inspection/prison |
| `rest_service` | `_phase_candidates` 内联 4 条 | 休息页 | 相位限 rest_choice |
| `reward` | `_phase_candidates` 内联、`RelicBundle.candidates`、`departure.gd` | 奖励页 | 相位限 reward/cleared |
| `retain` | `_phase_candidates` 内联 | 保留选牌 | `pending_retain` |
| `service`／`service_release`／`service_remove`／`service_flow` | `Services.candidates`／`paid_candidate(group=…)` | 商店／宝箱／服务页 | 4 组同模块 |
| `event` | `Events.candidates`（读冻结 options） | 事件页 | 相位限 event，**不参与增量** |
| `demo_exit` | `DemoExit.candidates` | 结算页 | 相位限 cleared |
| `action` | 默认值，**当前无调用点** | — | 保留默认值不改 |

### 4.2 段结构与行级过滤

- 段＝极大同组连续段；**多段组今天只有 `item`**（战斗中最坏 3 段：`_item_candidates` → `noncombat_candidates` →
  逐件 `item_discard`，被 `route`／`surrender`／`flask` 等隔开）。
- 段边界由构建序列决定，且**必须由核心自己跟踪**（行级过滤下，被跳过的行仍参与边界判定）；
  调用方不得自行推断段边界（UI 只能从 `get_view_scoped` 的 `candidate_runs` 读，或对自己手里的旧候选做 `runs_of`）。

### 4.3 读取集口径（覆盖优先）

1. **完备**：候选路径可达的每个 `state.<f>` 读取都必须在对应组的 `group_reads` 内（§7 场景 1，表外即红）。
2. **间接面显式**：`CopyRouter` 注册表按 Callable 查表，静态调用图**看不见**其读取 →
   必须为**每个已注册 builder** 手写 edge，并由"注册表键集合 == edges 键集合"的机械闭合断言守住（§11 头号风险）。
3. **不完整即全组**：某组读取集被标记不完整（或派生失败）→ `dirty_groups` 返回 `["*"]`，运行时永不出现"该重建却没重建"。
4. **无读取者字段**：字段差分命中但无组读取（如 `logs`／`summary`）→ 不必重建任何组（这正是收益来源之一）。

## 5. 失效、回退与"0 的唯一例外"

### 5.1 强制全量入口（世界替换；**一行不改**，协调者 2026-09-17 硬约束）

`ui/main.gd:_resume_snapshot`（读档／继续）、`restart()`（新局／练习）、`_quick_sl()`（快速 SL）、
`render()` 的空快照初始化兜底（F5 `:371`）：各自继续走 `game.get_view()` 全量。
- 这些入口**是**全局构建的合法出现处；契约要求用具名断言锁住（§7 场景 7：读档／新局首屏候选 ≡ 全量构建，
  且该次 `get_view()` 计入"允许的全表构建"）。
- 世界替换后的**第一次提交**同样按正常增量走（新视图已是全量基线，`view.version` 与新世界一致）。

### 5.2 回退条件枚举

| 条件 | 行为 |
| --- | --- |
| `writes` 含 `field_universe()` 之外的字段 | `candidate_scope=["*"]` → 全组重建（**不**调用 `candidates()`） |
| 组读取集不完整／派生失败 | `dirty_groups` 返回 `["*"]` |
| `get_view_scoped`／`candidate_runs` 收到 `[]` 或未知组名 | 返回空结果（调用方必须回退） |
| 段守卫失败（旧段消失／新段出现） | `merge` → `{ok:false}` → 由 `ui/main.gd` 调 `get_view_scoped(["*"])` 重建全部候选；**不得**调用 `get_view()` |
| 提交复核逐段未命中 | 回落全量 `candidates()` 复核一次（被拒路径；属"允许的兜底"，须计数报告） |
| 读档／新局／快速 SL／初始化空快照 | 全量（§5.1） |

### 5.3 明确不允许

- 不允许任何"UI 自行推断作废集合"的实现（scope 一律来自核心）。
- 不允许把回退实现成 `get_view()`（那会把主判据的 0 打破；回退只允许 `get_view_scoped(["*"])`）。
- 不允许用 `version` 当缓存键或脏集依据（version 不进依赖表，§3.3）。

## 6. 既有冲突结论：`response-pipeline.md` §4.1"禁止跨提交缓存候选"

**结论：核心侧不变量不放宽，也不需放宽；但必须加一句注**，否则后来者会按旧禁令判红本片。理由：
- §4.1 的禁令对象是（i）跨提交缓存规则结果、（ii）把旧 View／候选／节点引用当键、（iii）用 `version` 当缓存版本号；
  其立条理由是"UI 不得用缓存绕过投影成本、核心不得保留查询结果跨提交"。
- 本片：**核心只提供"按需构建被点名组"的只读入口，不缓存任何东西**（§3.2／§3.4 每次现算）；
  **判定权在核心**（`candidate_scope` 由核心的写入差分 × 依赖表导出，UI 不得自行推断）；
  被保留的是**UI 手里的投影**（`ui.view`／`view.candidates` 本来就跨提交持有，F4），UI 只是按核心给的集合替换投影。
- 因此这不是"放宽"，而是把 §4.1 的适用范围写清楚。**同批**在 `docs/response-pipeline.md` §4.1 末尾加注（逐字）：

> 2026-09-17 注（见 `docs/candidate-delta.md` §6）：本条约束**核心侧**——核心不得跨提交保留查询结果复用。
> UI 手里的 `ui.view`（含 `view.candidates`）是投影、不是核心缓存；按组增量的作废集合由**核心**给出
> （写入差分 × 字段依赖表），UI 只按该集合替换投影，不得自行推断作废集合或资格。核心侧不变量未放宽。

## 7. Gherkin（场景名 → 既有 case 文件的具名 check；**正例走真实公开命令**）

1. `candidate_deps_read_closure`（规则分类 `architecture`，`tests/architecture_cases.gd`）
   - Given 读取 `core/**.gd` 与 `core/candidate_deps.gd`；
   - When 按 `tests/check_index.gd` 式样的抽取规则从 24 个候选根做调用图闭包，收集 `state.<f>` 读取；
   - Then ①每个读取都在对应组的 `group_reads` 内（表外即红，打印组名＋函数名＋字段）；②`CopyRouter` 注册表键集合 ==
     手写 edges 键集合；③`state.keys()` ⊆ `field_universe()`；④派生结果与冻结摘要一致（零漂移）。
2. `candidate_runs_match_full_build`（规则分类 `architecture`）
   - Given 夹具矩阵（战斗 0／12／26 件、整备、休息、商店、事件、监狱，同种子）；
   - When 对每个夹具段分解 `candidates()`，再取 `candidate_runs(["*"])`，并逐组取 `candidate_runs([G])`；
   - Then 段数／段序／组名／逐字段全部相同；按组展平 ≡ `candidates().filter(c.group==G)`（逐字段逐顺序）。
3. `write_diff_drives_candidate_scope`（规则分类 `architecture`）
   - Given 夹具矩阵；When 对每个**可提交候选**执行真实 `dispatch(id, version)`；
   - Then 结果的 `candidate_scope` == 由 `export_snapshot()` 前后差分经 `candidate_deps.dirty_groups` 推出的集合；
     反例：只改 `energy` 的提交必须让含 `cost>0` 行的组进入集合；只写 `logs` 的提交必须得到 `[]` 或极小组。
4. `scoped_view_matches_full_build`（界面分类 `display`，`tests/display_ui_cases.gd`；**真实点击**）
   - Given 同种子双实例 A／B（B 用测试侧子类计数 `candidates()`，生产不留计数器）；
   - When B 走真实点击 → `dispatch` → `get_view_scoped(scope)` → `merge`；A 走同点击 → `get_view()` 全量；
   - Then B 的 `view.candidates`／`ui.actions`／其余视图字段与 A **逐字段逐顺序**相同；B 的 `candidates()` 调用 = 0。
5. `submit_screen_matches_full_scan`（规则分类 `architecture`）
   - Given 同种子双实例：A＝局部复核；B＝测试侧子类把复核换回"全量构建＋首命中"；
   - When 遍历夹具全部候选（含 invalid 与伪造 id 反例）真实 `dispatch`；
   - Then 返回字典逐键相同（含 `candidate_scope`）、所选行逐字段相同、终态／日志／随机域计数相同、拒绝文案相同。
6. `unknown_field_and_unknown_group_fail_closed`（规则分类 `architecture`）
   - Given 构造未知写入字段、未知组名、`[]`、`["*"]` 四种输入；
   - Then 未知字段 → `["*"]`；`[]`／未知组名 → 空结果且不改状态；`["*"]` → 全组；四条都有具名断言。
7. `load_paths_build_full_candidates`（界面分类 `persistence`）
   - Given 存档与已开局的本局；When `_resume_snapshot`／`restart()`／`_quick_sl()`；
   - Then 首屏 `ui.view.candidates` ≡ 同状态独立实例的全量 `get_view().candidates`，且该次为**允许的全表构建**（计数断言）；
     其后的一次提交仍走增量且与全量等价。
8. `event_domain_frozen_candidates`（界面分类 `events`）
   - Given 进入事件（选项冻结）；When 依次提交选项／奖励／离开；
   - Then 事件分支的 `candidate_scope` = `["*"]`、`state.room_event.options` 不被改动、候选逐字段等于全量；冻结 oracle 绿。
9. `section_dirty_from_deps`（界面分类 `interface`）——C4
   - 复用 `docs/response-pipeline.md` §9 场景 3／4／7 的具名 check（键命中跳过重建／相位兜底／兜底触发，**不另造**）；
   - 并新增：被重建的节集合 ⊆ `candidate_deps.sections_for(writes)`；反例：只改 `logs` → 只重建 `log_sidebar`。

## 8. validator procedure（agent 可运行；操作真实界面）

宿主 `tests/ui_smoke.gd` ＋ `tools/check.ps1`；真实 viewport 输入；测试存档隔离；不默认截图。

1. 范围预检（不算通过）：
   `& tools/check.ps1 -Suite architecture,core,runner,battle_saturation,rewards,guard,persistence -Impact -ListOnly`
2. 规则＋窗口：
   `& tools/check.ps1 -Suite architecture,core,runner,battle_saturation,rewards,guard,persistence -Impact -TimeoutSeconds 900`
   `& tools/check.ps1 -UIOnly -UISuite display,interface,targeting,basic_attacks,body_layout,events,persistence -TimeoutSeconds 900`
   → 退出码 0；`summary.json` `status=passed` 且 `before==after` 指纹。
3. 人的路径（每条断言的判据是 suite 的布尔 check）：26 件装备战斗中依次——打出一张牌／攻击／结束回合（相位变化）／
   翻面手牌／点选敌人／开身体栏／用一件道具／进商店买一件／进事件选完／读档／新局／快速 SL。
4. 归属判定：实现代码／测试脚本／环境／程序本身；不确定则未分类上报，不自动改产品代码。
5. 证据：`build/checks/<id>/check-rules.log`、`check-ui.log`、`summary.json`；结果与域写 `docs/verification.md`。

## 9. 判据、完成定义与测量

命令（必跑，一次）：

```
& tools/check.ps1 -Suite architecture,core,runner,battle_saturation,rewards,guard,persistence -Impact -TimeoutSeconds 900
& tools/check.ps1 -UIOnly -UISuite display,interface,targeting,basic_attacks,body_layout,events,persistence -TimeoutSeconds 900
& tools/check-index.ps1                     # 零漂移；改 core/ 后必须 -Write 并与源码同批提交
& <godot console exe> --headless --path . --script res://build/event-oracle-20260916/event_oracle.gd -- --baseline=build/event-oracle-20260916/baseline.json
& <godot console exe> --headless --path . --script res://build/transition-oracle-20260916/transition_oracle.gd -- --baseline=build/transition-oracle-20260916/baseline.json
```

- **主判据**：每个有效操作经 `candidates()` 的全表构建次数 = **0**；读档／新局／快速 SL／初始化仍为全量（§5.1）。
- **伴侣指标（必须同报，不得只报 0）**：被重建组数/24、每次提交的 `writes` 规模、提交复核实际构建的段数与**命中位置**
  （`kind=attack, hit_segment=3/12, built_rows=…, full_rows=…`）；相位／结构变化时如实标注"全组重建（工作量≈全表）"。
- **等价性**（不因 0 而放松）：§7 场景 2／4／5 全部通过；`candidate_runs(["*"])` 与 `candidates()` 逐字段逐顺序相同。
- 两个冻结 oracle：`EVENT RESULT: PASS (94 scenarios, 0 failures)`／`TRANSITION RESULT: PASS (31 scenarios, 0 failures)`，
  `EVENTDIGEST`／`TRANSITIONDIGEST` 与基线**逐字相同**，引擎错误日志 **0 行**。
- 红集必须 ⊆ 既有六项：`card_power` 5／`installed_tools` 1／`tower_progression` 10＋1／`hand_assist` 1／
  `home_persistence` 3／`interface` 1（28 张 `witch_*` 卡缺立绘）；新增红项视为本片未完成。
- 测量（参考，不承诺毫秒）：沿用 `docs/equipment-performance.md:45` 协议（0／12／26 件 × battle／departure，
  交替执行、2 热身＋15 有效配对、逐对比值中位与两侧独立中位分开报告）；**写入差分本身的成本必须单列**
  （121 个顶层字段的深比较），若与候选构建同量级必须如实上报。产物放忽略目录 `build/candidate-delta-<date>/`，
  摘要入 `docs/verification.md` 后删除原始目录；生产源码不留计数器／计时钩子。
- 算未完成（任一）：任一必跑套件未执行／失败／无授权跳过；oracle 摘要漂移或错误日志非 0；`check-index.ps1` 非 0；
  有效操作路径上仍出现 `candidates()` 调用；回退实现成 `get_view()`；UI 自行推断作废集合；
  候选行／判定／文案变化；读档路径被改；依赖表外读取放行；生产留计数器；只报 0 不报伴侣指标；
  宣称帧率提升或全量回归。
- 同批小步（文档）：①根 `AGENTS.md` 文档入口表加一行 `docs/candidate-delta.md`；②§6 的注加入 `docs/response-pipeline.md` §4.1。

## 10. 依赖约束（cleaner 可核对）

- `core` 不得 preload `ui`；仅 `ui/main.gd` 可 preload core；`ui/candidate_delta.gd` 纯 static、无状态、无缓存。
- 核心只读入口不写 state、不推进随机、不改 `version`、不产日志；不跨调用保留；容器新建。
- `dispatch` 判定顺序、入参、错误文案不变；OK 结果只允许**加性键**（当前仅 `candidate_scope`）。
- 候选行与 `group` 名不变；段序／段内序不变；不得重排构建序列。
- 作用域语义：`[]`＝空（fail-closed）；`["*"]`＝全部；未知组名＝空。三者在 `candidate_runs` 与 `get_view_scoped` 一致。
- 依赖表：只增不猜；手写 edge 必须带理由；表外读取即红；不完整即全组。
- 回退只允许 `get_view_scoped(["*"])`；`get_view()` 只允许世界替换与初始化。

## 11. 假设与最可能爆的点（含 needs-human-review 理由）

- **A1（最可能爆的一点：间接读取面）**：`CopyRouter` 按 Callable 注册表分派站点 builder，**静态调用图看不见**；
  若手写 edges 漏掉某个 builder 的读取，就会出现"字段改了但组没被作废"的**过期候选**（正确性问题）。
  缓解：①注册表键集合 == edges 键集合的**机械闭合**（注册表运行时可枚举）；②`_candidate` 通用面与模块门面
  （`Equipment`／`Relics`／`Cards`／`Pressure`／`SpecialEquipment`）的读取用**保守归并**（被谁可达就归谁）；
  ③§7 场景 4 的双实例等价矩阵逐夹具兜底；④"读取集不完整"标记 → 一律全组重建。
- **A2（0 的口径）**：相位／结构变化的提交其 `writes` 命中 `phase` 等 → 全组重建。0 是**调用口径**，
  不等于相位切换免费；必须按伴侣指标如实报告（§9）。
- **A3（写入差分成本）**：121 个顶层字段的深比较必须实测并单列；若在密集夹具上与候选构建同量级，报告出来，不隐瞒。
- **A4（C4 体量）**：`present(dirty)`／节键在 HEAD **未落地**（F11），C4 需实现 `response-pipeline` §3.3／§3.4。
  已按"删 C4 不影响 C0–C3"解耦；若协调者要 C4 单独成片，在派单里写明即可。
- **A5（新文件）**：本片新增 `core/candidate_deps.gd`、`ui/candidate_delta.gd`（可能加 `tools/candidate-deps.ps1`）；
  `response-pipeline` §5.4 的"不得自行新建"在此由**本契约点名授权**，实现者不得再自增文件。
- **A6（跨契约注）**：§6 的注必须与代码同批落地，否则 `response-pipeline` §4.1 会与本片字面冲突。
- **A7（flag 理由）**：新模块与新依赖边（UI 合并读取 core 的 scope）、跨契约注、C4 需实现他人 draft、
  目标口径由 1 改 0 —— 判 `needs-human-review`；人审只需读 §0／§2／§11 与 §9 的判据。
- **A8（未决项）**：人 OK 的形式（见文件头）：若协调者判定本轮裁定已代替"计划摘要人审"，请在派单写明。

## 12. 后续片／未排期（不在本片）

1. builder 级早退守卫（可选优化）：跳过不在作用域的单组 builder，但必须自带**段边界等价证据**（本片 §3.2 明确不做）。
2. 窗口与输入队列（`docs/response-pipeline.md` 末尾，未排期）。
3. 依赖表细化（行级而非组级、装备件级差分）——只有测量证明值当再立片。
