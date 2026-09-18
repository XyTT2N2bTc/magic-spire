# 候选局部筛查与依赖声明契约（candidate-delta）

本文件是现行契约：把候选构建从「唯一入口全建」改成「由字段依赖声明点名的组按需构建」，
并把同一份声明用于界面投影的脏集与提交复核的筛查。
实现前置＝**协调者记录的人 OK 覆盖本片切线**（`needs-human-review` 理由见「假设与待决」）。
本文件不写执行结果；通过／失败／未执行只登记在验证记录（`docs/record/verification.md`）。
**前置状态（2026-09-18）**：本契约尚未实施——`core/candidate_deps.gd`、`ui/candidate_delta.gd`、`tools/candidate-deps.ps1` 均未落地；文中引用的 `tools/check-index.ps1`／`tests/check_index.json` 属“检查路由”片，同样未随本次提交落地（两片的方案与结论见 `docs/record/proposals/check-routing-and-per-click-checks.md`）。未落地前 C0 不得开工。

路径约定：不带 `spire-godot/` 前缀的源码、测试与工具路径（`core/`、`ui/`、`data/`、`tests/`、`tools/`、`build/`）
均相对 `spire-godot/`；`docs/` 相对仓库根。

## 域

- 一次有效操作（提交）前后，**候选与界面投影的构建范围**，以及支撑它的**字段依赖声明**。
- 不含：输入层、存档内容、窗口与输入队列、随机域、打包发布；事件域不参与增量（候选读冻结的
  `state.room_event.options` 与 `stage`，产物全在 `event` 组）。
- 目标：**每个有效操作的「经 `candidates()` 的全表构建次数 = 0」**——候选一律经按组入口构建；
  全局构建只属于**世界替换**（读档／继续／新局／练习／快速 SL／就地恢复快照）。
  相位／结构变化时差分命中 `phase` 等字段 → 作废集合＝全部组 → 走按组入口重建全部组：
  **调用口径的 0 成立，但工作量≈全表**，此类情况必须按伴侣指标如实报告，不得宣称相位切换变快。
- 锚点：函数名、组名、字段名、稳定 id 是锚点；实现位置会移动，动手前用 `rg` 复算。

## 接口

### `core/candidate_deps.gd`（新，纯数据＋纯函数）

- 语义：「候选行／组 → 它读取的 state 字段」的唯一出处，同时给出投影侧「节 → 字段」。
  读取集必须含**间接读取**：`_candidate` 的通用读取面（`energy`／魔力余额 → `valid`/`reason`；
  `Pressure.action_risk` 与 `Cards.magic_card_traction` → `risk`；目标装备 `lock_only`／诅咒 → `reason`）、
  站点 `copy` builder、各组生产者自身（含经 `Equipment`／`Relics`／`Cards`／`Pressure`／`SpecialEquipment`
  等模块门面的读取）。
- 接口：
  - `field_universe() -> Array`：顶层 state 字段全集（含无读取者的字段，如 `version`／`logs`／`summary`）；
  - `group_reads(group) -> Array`：该组读取集；未知组名返回 `[]` 且不静默（调用方按 fail-closed 处理）；
  - `dirty_groups(writes) -> Array`：`{ G : group_reads(G) ∩ writes ≠ ∅ }`；含 `"*"`、含 `field_universe()`
    之外的字段、或任一组读取集标记不完整 → 返回 `["*"]`；
  - `section_reads(section)`／`sections_for(writes)`：C4 用，节名与语义照抄
    `docs/spec/response-pipeline.md` 的节键表。
- 只读、无状态、不持游戏引用、不写 state。表**只增不猜**：每个条目要么来自派生（调用图可达读取），
  要么是手写 edge 并**在文件内写明理由**；零漂移：冻结摘要＋自检（派生结果 ≠ 冻结即红）。

### `Game.candidate_runs(groups) -> Array`（core，新，只读）

- 语义：按当前状态的既有构建序返回**段**；段＝构建序列中的**极大同组连续段**。
  返回 `[{group:String, rows:Array}]`，段序＝构建序，段内序＝构建序；`rows` 与同状态全量 `candidates()`
  的对应段逐字段相同。
- **作用域过滤在行级**（`_candidate` 内）：不在作用域的行不构造，但其组名仍参与段边界判定，
  因此段边界与全量构建一致；**不加 builder 级早退守卫**（跳过整段会破坏段边界；守卫是后续可选优化，
  须自带段边界等价证据）。
- 只读：不写 state、不推进随机、不改 version、不产日志与事件、不跨调用保留。

### `dispatch`：局部复核 ＋ 加性键 `candidate_scope`

- 提交复核：`for c in candidates():` 改为**按构建序逐段构建、命中即止**（取第一条 id 匹配行）；
  **未命中回落全量 `candidates()` 复核一次**，仍未命中才走现有拒绝文案。
  等价性依据：①构建器只读；②顺序确定（段序＝调用序，段内序＝追加序，相位早退分支原样保留）；
  ③无非命中副作用（只影响「建了多少」；state／日志／随机域计数／快照／视图全不受影响）；
  ④命中的那一行就是全量构建中按追加顺序的第一条 id 匹配行，逐字段相同，未命中与拒绝文案逐字相同。
  步粒度不参与语义：只取决于「按追加顺序的第一条匹配行」，检查必须在每次追加之后、按追加顺序进行。
- **写入差分**：成功提交末尾（所有状态变更之后、返回之前）计算
  `writes = { f ∈ field_universe() : original[f] != state[f] }`；`version` 显式排除。
  差分字段超出 `field_universe()` → `writes=["*"]`（fail-closed）。
- **声明**：`candidate_scope = candidate_deps.dirty_groups(writes)`，作为 OK 结果的**加性键**放回：
  语义＝本次提交后必须重建的候选组；`["*"]`＝全组。
  接口面不变：入参、判定顺序（六个 `validate` → 版本 → 复核 → `valid`）、`error` 文案、`version` 语义
  全部不变；唯一变化是这个加性键（两个冻结 oracle 都不对结果整体取摘要，因此不可见）。
- 与已归档「提交去重」的区别（保留这段，避免后人误判）：本片**不改提交入参**、
  **不加核心跨提交缓存**、**不需要外部提交行**——候选仍由核心从当前状态自建，UI 仍只传
  `candidate_id` 与版本。局部复核不得暴露成第二提交入口。

### `Game.get_view_scoped(groups) -> Dictionary`（core，新，只读）

- 语义：与 `get_view()` **同形**（同样键、其余字段完整），但：①`candidates` 只含点名组的行（构建序）；
  ②逐 action 的投影（`release_preview`／`casting`／`body_part`／`brief`／`brief_tags`）只对这批行计算；
  ③额外键 `candidate_runs`＝同一批行的段结构（供 UI 合并；段边界与全量构建一致）。
- 只读、不写 state、不推进随机、不产日志；非空 `groups` 下**不得**再调 `get_view()` 或 `candidates()`。
- 谁能调：只允许 `ui/main.gd` 的增量路径与测试。

### `ui/candidate_delta.gd`（新，纯 static）

- `runs_of(rows) -> Array`：把扁平候选按极大同组连续段切分（纯函数）。
- `merge(base_rows, new_runs, scope) -> Dictionary` → `{ok:bool, error:String, candidates:Array}`：
  - `scope` 含 `"*"` 或未知组名 → `{ok:false}`（调用方改走 `get_view_scoped(["*"])`，**不得**走 `get_view()`）；
  - 按旧段序走一遍：旧段组 ∈ scope → 取该组新段队列的下一段；否则保留旧段；
    队列空（段消失）／收尾仍有剩余（段新增）→ `{ok:false}`；
  - `ok=true` 时 `candidates` 必须与同状态全量构建**逐字段逐顺序**相同。
- 只吃传入的 Array／Dictionary，不吃 game、控件，不跨刷新缓存；只能由 `ui/main.gd` 的成功提交分支调用。
  **UI 不得自行推断作废集合**（scope 一律来自核心的 `candidate_scope`），不得自行判定资格、不得读 `game.state`。

## 输入域

### 组参数与作用域语义（`candidate_runs` 与 `get_view_scoped` 一致）

| 输入 | 语义 |
| --- | --- |
| `[]` | 空结果（fail-closed）；**绝不**等价于「全部」 |
| `["*"]` | 全部组（唯一合法的「全部」拼法）；`get_view_scoped(["*"])` 把完整候选列表放回 `candidates`，调用方不再合并 |
| 含未知组名 | fail-closed：`candidates=[]`、`candidate_runs=[]`（调用方必须回退） |

### 组清单（组名即分组键，一字不改）

| 组 | 生产者（构建序位置） | 备注 |
| --- | --- | --- |
| `wall_move` | `_wall_move_candidates` | 相位限 battle/prepare/rest/prison 且有墙 |
| `posture` | `_posture_candidates` | |
| `attack` | `_attack_candidates`、`_equipment_spell_candidates`、`witch_character.gd` | 两处生产者相邻 → 单段 |
| `card` | `_card_candidates`→`Cards.candidates` | `detail` 按需 |
| `chain` | `Cards.continuation` | 互斥分支 |
| `manual` | `_manual_candidates` | 装备件数驱动，26 件时最贵之一 |
| `item` | `_item_candidates`、`Consumables.noncombat_candidates`、逐件 `item_discard` | **多段组** |
| `pressure` | `calm` | |
| `flow` | `end`／`finish_prepare`／`finish_rest`／`finish_pack`、`departure.gd` | 相邻生产者合并为单段 |
| `route` | `travel_step`、`_route_candidates`、`depart`、`departure.gd` | 相位限 map/travel/departure |
| `surrender` | `_build_candidates` 内联 | 战斗且仍有敌人 |
| `status_toggle` | `_build_candidates` 内联 | `charge>0` 且非过载 |
| `flask` | `ManaFlask.candidates` | |
| `prison` | `Prison.candidates`（经 `Prison.add`，组名硬编码）、直呼点 | 相位限 captured/inspection/prison |
| `rest_service` | `_phase_candidates` 内联 | 相位限 rest_choice |
| `reward` | `_phase_candidates` 内联、`RelicBundle.candidates`、`departure.gd` | 相位限 reward/cleared |
| `retain` | `_phase_candidates` 内联 | `pending_retain` |
| `service`／`service_release`／`service_remove`／`service_flow` | `Services.candidates`／`paid_candidate(group=…)` | 4 组同模块 |
| `event` | `Events.candidates`（读冻结 options） | 相位限 event，**不参与增量** |
| `demo_exit` | `DemoExit.candidates` | 相位限 cleared |
| `action` | 默认值，**当前无调用点** | 保留默认值不改 |

- 段结构：段＝极大同组连续段；**多段组今天只有 `item`**（战斗中最坏 3 段，被 `route`／`surrender`／
  `flask` 等隔开）。段边界由构建序列决定，且**必须由核心自己跟踪**（行级过滤下，被跳过的行仍参与边界判定）；
  调用方不得自行推断段边界。
- 复核项（未决）：代码侧 `rest` 相位的 `_rest_candidates` 另有 `hook` 组未列本表，组集合待复核。
- 读取集口径（覆盖优先）：①候选路径可达的每个 `state.<f>` 读取都必须在对应组的 `group_reads` 内（表外即红）；
  ②间接面显式——`CopyRouter` 注册表按 Callable 查表，静态调用图看不见其读取，必须为每个已注册 builder
  手写 edge，并由「注册表键集合 == edges 键集合」的机械闭合断言守住；③某组读取集标记不完整（或派生失败）
  → `dirty_groups` 返回 `["*"]`；④字段差分命中但无组读取（如 `logs`／`summary`）→ 不必重建任何组。

### 计数口径（判据用，逐字沿用）

- **全表构建**：一次调用 `candidates()`（含 `get_view()` 内部那次）。
- **按组构建**：`candidate_runs(groups)`／`get_view_scoped(groups)`（含 `["*"]`＝全组重建）。
- **主判据**：有效操作期间的全表构建次数 = 0；全局构建只出现在世界替换。
- **伴侣指标（必须同报）**：被重建组数／24（相位或结构变化时会等于全组，此时工作量≈全表，只是调用口径为 0）、
  每次提交的 `writes` 规模、提交复核实际构建的段数与命中位置
  （如 `kind=attack, hit_segment=3/12, built_rows=…, full_rows=…`）。

### 强制全量入口（世界替换；一行不改）

`ui/main.gd` 的 `_resume_snapshot`（读档／继续）、`restart()`（新局／练习）、`_quick_sl()`（快速 SL）、
`render()` 的空快照初始化兜底：各自继续走 `game.get_view()` 全量，是全局构建的合法出现处，
并用具名断言锁住（首屏候选 ≡ 全量构建，且该次 `get_view()` 计入「允许的全表构建」）。
世界替换后的第一次提交同样按正常增量走（新视图已是全量基线，版本与新世界一致）。

## 失败语义

| 条件 | 行为 |
| --- | --- |
| `writes` 含 `field_universe()` 之外的字段 | `candidate_scope=["*"]` → 全组重建（**不**调用 `candidates()`） |
| 组读取集不完整／派生失败 | `dirty_groups` 返回 `["*"]` |
| `get_view_scoped`／`candidate_runs` 收到 `[]` 或未知组名 | 返回空结果（调用方必须回退） |
| 段守卫失败（旧段消失／新段出现） | `merge` → `{ok:false}` → 调 `get_view_scoped(["*"])` 重建全部候选；**不得**调用 `get_view()` |
| 提交复核逐段未命中 | 回落全量 `candidates()` 复核一次（被拒路径；属「允许的兜底」，须计数报告） |
| 读档／新局／快速 SL／初始化空快照 | 全量 |

明确不允许：UI 自行推断作废集合；把回退实现成 `get_view()`（会打破主判据的 0）；用 `version` 当缓存键或脏集依据。
依赖表只增不猜，手写 edge 必须带理由；表外读取即红；不完整即全组。
复用准入线（现行结论）：**复用必须附可证失效规则，无证明即禁止**；核心侧不跨提交保留查询结果，
按组增量每次现算，作废集合的判定权在核心。

## 证据入口

具名 check（场景名 → 既有 case 文件；正例走真实公开命令）：

1. `candidate_deps_read_closure`（`architecture`）：从 24 个候选根做调用图闭包收集 `state.<f>` 读取 →
   ①每个读取都在对应组的 `group_reads` 内（表外即红，打印组名＋函数名＋字段）；
   ②`CopyRouter` 注册表键集合 == 手写 edges 键集合；③`state.keys()` ⊆ `field_universe()`；
   ④派生结果与冻结摘要一致（零漂移）。
2. `candidate_runs_match_full_build`（`architecture`）：夹具矩阵（战斗 0／12／26 件、整备、休息、商店、事件、监狱，
   同种子）→ 段数／段序／组名／逐字段全部相同；按组展平 ≡ `candidates().filter(c.group==G)`。
3. `write_diff_drives_candidate_scope`（`architecture`）：对每个可提交候选执行真实 `dispatch(id, version)` →
   `candidate_scope` == 由快照前后差分经 `dirty_groups` 推出的集合；反例：只改 `energy` 的提交必须让含
   `cost>0` 行的组进入集合；只写 `logs` 的提交必须得到 `[]` 或极小组。
4. `scoped_view_matches_full_build`（`display`，真实点击）：同种子双实例 A／B（B 用测试侧子类计数 `candidates()`）
   → B 的 `view.candidates`／`ui.actions`／其余视图字段与 A 逐字段逐顺序相同；B 的 `candidates()` 调用 = 0。
5. `submit_screen_matches_full_scan`（`architecture`）：A＝局部复核、B＝测试侧把复核换回「全量构建＋首命中」→
   返回字典逐键相同（含 `candidate_scope`）、所选行逐字段相同、终态／日志／随机域计数相同、拒绝文案相同。
6. `unknown_field_and_unknown_group_fail_closed`（`architecture`）：未知写入字段、未知组名、`[]`、`["*"]`
   四种输入 → 未知字段 `["*"]`；`[]`／未知组名空结果且不改状态；`["*"]` 全组。
7. `load_paths_build_full_candidates`（`persistence`）：`_resume_snapshot`／`restart()`／`_quick_sl()` →
   首屏候选 ≡ 同状态独立实例的全量 `get_view().candidates`，且该次为允许的全表构建（计数断言）；
   其后的一次提交仍走增量且与全量等价。
8. `event_domain_frozen_candidates`（`events`）：进入事件（选项冻结）后依次提交选项／奖励／离开 →
   事件分支的 `candidate_scope` = `["*"]`、`state.room_event.options` 不被改动、候选逐字段等于全量；冻结 oracle 绿。
9. `section_dirty_from_deps`（`interface`，C4）：复用 `docs/spec/response-pipeline.md` 的场景 3／4／7 具名 check
   （键命中跳过重建／相位兜底／兜底触发），并新增：被重建的节集合 ⊆ `sections_for(writes)`；
   反例：只改 `logs` → 只重建 `log_sidebar`。

```powershell
& tools/check.ps1 -Suite architecture,core,runner,battle_saturation,rewards,guard,persistence -Impact -TimeoutSeconds 900
& tools/check.ps1 -UIOnly -UISuite display,interface,targeting,basic_attacks,body_layout,events,persistence -TimeoutSeconds 900
& tools/check-index.ps1                     # 随“检查路由”片提交；未落地前 C0 不得开工（见文件头注）
& <godot console exe> --headless --path . --script res://build/event-oracle-20260916/event_oracle.gd -- --baseline=build/event-oracle-20260916/baseline.json
& <godot console exe> --headless --path . --script res://build/transition-oracle-20260916/transition_oracle.gd -- --baseline=build/transition-oracle-20260916/baseline.json
```

- `tools/check-index.ps1` 与 `tests/check_index*.gd` 属检查索引契约的交付物（本片不新建、不改写）；
  本片 C0 的零漂移自检沿用其口径，未落地前 C0 不得开工。
- 判据：两个冻结 oracle `EVENT RESULT: PASS`／`TRANSITION RESULT: PASS`，`EVENTDIGEST`／`TRANSITIONDIGEST`
  与基线逐字相同，引擎错误日志 0 行；`check-index.ps1` 退出码 0（该工具随“检查路由”片提交）；`summary.json` `status=passed`
  且 `before==after` 指纹。
- 红集必须 ⊆ 既有六项：`card_power` 5／`installed_tools` 1／`tower_progression` 10＋1／`hand_assist` 1／
  `home_persistence` 3／`interface` 1（28 张 `witch_*` 卡缺立绘）；新增红项视为本片未完成。
- 人的路径（判据是 suite 布尔 check）：26 件装备战斗中依次打出一张牌／攻击／结束回合（相位变化）／翻面手牌／
  点选敌人／开身体栏／用一件道具／进商店买一件／进事件选完／读档／新局／快速 SL。
- 测量（参考，不承诺毫秒）：沿用 `docs/record/equipment-performance.md` 的协议（0／12／26 件 × battle／departure，
  交替执行、2 热身＋15 有效配对、逐对比值中位与两侧独立中位分开报告）；**写入差分本身的成本必须单列**，
  若与候选构建同量级必须如实上报；产物放忽略目录 `build/candidate-delta-<date>/`，摘要入验证记录后删除，
  生产源码不留计数器／计时钩子。
- 算未完成（任一）：任一必跑套件未执行／失败／无授权跳过；oracle 摘要漂移或错误日志非 0；`check-index.ps1` 非 0（随该片提交后生效）；
  有效操作路径上仍出现 `candidates()` 调用；回退实现成 `get_view()`；UI 自行推断作废集合；
  候选行／判定／文案变化；读档路径被改；依赖表外读取放行；生产留计数器；只报 0 不报伴侣指标；
  宣称帧率提升或全量回归。

## 分批（同一片，按可独立完工的顺序推进）

| 批 | 范围 | 该批判据 |
| --- | --- | --- |
| **C0** | 依赖表（派生＋手写 edges＋冻结摘要＋零漂移自检）；**行为零变化** | 场景 1 |
| **C1** | 段化构建＋`candidate_runs(groups)`＋按组闭环；**无调用方变化** | 场景 2、6 |
| **C2** | 提交复核局部化（`dispatch` 内）＋写入差分＋`candidate_scope` 加性键 | 场景 3、5、6 |
| **C3** | 视图侧增量（`get_view_scoped` ＋ UI 合并 ＋ 回退） | 场景 4、7、8 |
| **C4** | 投影侧脏集（`present(dirty)` ＋节键，规格来源＝`docs/spec/response-pipeline.md`，不另造），脏集由依赖表导出 | 场景 9 |

每批一次具名判据，**不得跨批开工**；每批可独立提交与复核。
C4 涉及的节键在实现时尚未落地：本片 C4 需实现它们；若协调者决定 C4 单独成片走原契约，
**删除 C4 即可，C0–C3 与判据不受影响**（本契约已按此解耦）。

## 假设与待决

- **最可能爆（A1）：间接读取面。** `CopyRouter` 按 Callable 注册表分派站点 builder，静态调用图看不见；
  手写 edges 漏掉某个 builder 的读取会出现「字段改了但组没被作废」的过期候选（正确性问题）。
  缓解：①注册表键集合 == edges 键集合的机械闭合（注册表运行时可枚举）；②`_candidate` 通用面与模块门面的读取
  保守归并（被谁可达就归谁）；③场景 4 的双实例等价矩阵逐夹具兜底；④「读取集不完整」标记 → 一律全组重建。
- **A2（0 的口径）**：相位／结构变化提交的 `writes` 命中 `phase` 等字段 → 全组重建；0 是调用口径，
  不等于相位切换免费，必须按伴侣指标如实报告。
- **A3（写入差分成本）**：121 个顶层字段的深比较必须实测并单列；若在密集夹具上与候选构建同量级，不隐瞒。
- **A4（C4 体量）**：见上；删 C4 不影响 C0–C3。
- **A5（新文件）**：本片新增 `core/candidate_deps.gd`、`ui/candidate_delta.gd`（可能加 `tools/candidate-deps.ps1`）；
  由本契约点名授权，实现者不得再自增文件。
- **A6（依赖方向）**：`core` 不 preload `ui`；仅 `ui/main.gd` 允许 preload core；`ui/candidate_delta.gd` 纯 static。
- **待决**：人 OK 的形式——若协调者判定本轮裁定已代替「计划摘要人审」，请在派单写明。

## 后续片／未排期（不在本片）

1. builder 级早退守卫（可选优化）：跳过不在作用域的单组 builder，但必须自带**段边界等价证据**。
2. 窗口与输入队列（见 `docs/spec/response-pipeline.md`，未排期）。
3. 依赖表细化（行级而非组级、装备件级差分）——只有测量证明值当再立片。
