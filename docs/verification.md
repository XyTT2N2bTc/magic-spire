## 2026-09-17 检查路由与失败隔离：两段实现与判据（实现者）

域：`spire-godot` 检查入口（`tools/check.ps1` ＋ `tests/`）——**套件失败隔离**与**派生检查索引＋路由**。
契约 `docs/check-routing.md`（§11 七条裁定随施工生效）。**产品代码零改动**：`git diff 3afdc55 -- spire-godot/core spire-godot/ui spire-godot/data spire-godot/content spire-godot/assets` 为空；
不推送、不打包、不发版；未跑全量 `-Suite all -UI -UISuite all`（契约未要求，见"未验证"）。

**两段提交（基线 `3afdc55`，分支 `event-pipeline-unification`）**

| 段 | 提交 | 内容 |
| --- | --- | --- |
| ① 隔离 | `eaa003a` | `tests/test_game.gd`／`tests/ui_smoke.gd`：去掉整轮 `break`／`return`，脚本错误与断言失败只记该套件 `FAIL`（脚本错误另打 `SUITE RUNTIME: <name> <n>`，`n≥1` 才打印）；套件加载失败打 `SUITE LOAD FAILED` 并继续；`-KeepGoing` 变兼容无操作；新增负例夹具 `tests/runtime_error_ui_probe.gd`（在 `await` 之后于协程内报错，证明控制权返回宿主）；`-VerifyRunner` 探针改为隔离反例；旧口径加 superseded 指针（event-pipeline-unification／transition-pipeline／verification／changelog／repo-ops）。 |
| ② 索引 | `aa199f4` | `tests/check_index.gd`（derive／frozen／compare／suites_for，单一派生实现）＋`tests/check_index_edges.gd`（手写层，每条带理由）＋冻结物 `tests/check_index.json`＋生成器 `tools/build_check_index.gd`／`tools/check-index.ps1`（`-Write` 是唯一写者）＋计划宿主 `tests/route_plan.gd`；`tests/runner_cases.gd` 落 §3.4 i–viii 自检与 §6-G3 路由样例；`tools/check.ps1` 增 `-Changed`／`-Since`／`-ChangedList`（与 `-Suite`／`-UISuite`／`-UI`／`-UIOnly`／`-Impact` 互斥）、仓库外路径起引擎前拒绝、内容门独立阶段、`summary.route`；repo-ops 更新命令面与里程碑条款。 |

**三段墙钟（本机实测）**

1. **隔离收益**：同一命令
   `-Suite event_flow,events,content,architecture,localization,persistence -Impact -KeepGoing -TimeoutSeconds 900`
   ——**改动前**〔278.6s 截断＋261s 补跑＝539.6s，两个进程，`unrun`＝18 类〕→ **改动后**〔**729s 一次进程**，37/37 套件都有 `SUITE RESULT`，`unrun=[]`〕。
   覆盖未减少：**逐套件断言数与改动前逐条相等**（37/37，合计 16903 条），红集不变＝{`card_power` 5, `installed_tools` 1, `tower_progression` 10}，`SUITE RUNTIME` 分别记 5／1／10。
   口径说明：本机这一次进程比"两段之和"慢约 190s，全部落在 `prison`（92→283s）与 `persistence`（24→169s）两套件；单跑 `-Suite prison,persistence` 回到 91s／23s〔125s 墙钟〕，即长驻进程的开销，**不是行为变化**（断言数不变）。契约 §5.6 预期"≈400s 一次进程"在本机未复现；隔离的可复现收益是"单进程＋`unrun=[]`＋无需人工补跑编排"，不是时间。
2. **路由收益**：内容包清单 `-ChangedList`（内容门＋7 个消费者）**43s**（规则 31.5s、3023 断言、`CONTENT PASS: 12 file(s)`、退出码 0）；`ui/event_screen.gd` **44s**（`ROUTE RULE SCOPE: (none)`、UI `events` PASS 180 断言、退出码 0，两相分离仍成立）；计划宿主一次 **约 7s**（契约 §5.6 预期 8–10s）。
3. **索引维护成本**：`tools/check-index.ps1` 零漂移校验 **2.4s**（退出码 0）；`runner` 套件内含 i–viii 自检与 G3 样例，**1.3s／+52 断言**（≤10s 目标），`-Suite runner -VerifyRunner` 全探针 **154s**。

**索引规模（实测）**：`suite_files` 覆盖 **94 个注册套件**（规则 50＋界面 44；`rule:core`／`ui:baseline` 由宿主 `_core_cases()`／`_baseline_tests()` 承载、无用例文件，登记在 `SUITE_EXEMPT`）；**436 条（套件→源文件）边**；176 个用例文件全部有唯一 owner；`core|data|ui` 120 个 `.gd` 中 **117 个有边或域解析**、**4 个盲区**（`core/tool_rules.gd`／`core/item_presentation.gd`／`core/release_view.gd`／`data/phases.gd`，逐条 `BLIND_BY_DESIGN` 理由并注明由哪条闭包兜住）；`DOMAINS` 58 条、`WIDEN` 1 条（`core/game.gd + impact:persistence`）、`EXCLUDE` 12 条、`SUITE_EXEMPT` 3 条、`ORACLE_NOTES` 2 条、`INDEX_DEFECTS` **空**（无未闭合缺陷）。冻结物 `digest db5617dd…`、`generated_from 1333fe78…`（**任何 `core|data|ui`／`tests/**` 文本改动不改索引即红**）。

**盲区闭包清单（里程碑全量必须覆盖的路径）**：`spire-godot/core/**`→`all-dev`（含 `tool_rules.gd` 等 4 个 `BLIND_BY_DESIGN`）、`spire-godot/data/**`→`all-dev`、`spire-godot/ui/**`→`all-dev-ui`、`spire-godot/tests/**` 无法归属者→`all-dev`＋`all-dev-ui`、`spire-godot/content/**`→7 个消费者＋内容门、`spire-godot/assets/**`→`localization`（`assets/art/**` 另加 `hero_art`／`equipment_art`）、`spire-godot/tools/**`→`runner`、模块根文件→`all-dev`＋`all-dev-ui`、其他新目录→`ROUTE UNMAPPED` fail-closed。每次计划逐条打印 `ROUTE DEFAULT`／`ROUTE DOMAIN`／`ROUTE UNMAPPED`／`ROUTE WIDEN CANDIDATE`／`ROUTE MILESTONE`（扣除清单）。**`all-dev`／`all-dev-ui` 扣除 `normal_play`／`baseline`**，扣除清单每次打印，里程碑唯一入口仍是 `-Suite all -UI -UISuite all`（已写进契约命令面与 repo-ops）。

**判据（命令／退出码／断言／红集）**

- `& tools/check.ps1 -Suite runner -VerifyRunner -TimeoutSeconds 900`：**退出码 0**〔154s〕；`negative-isolation-assertion`／`-assertion-keepgoing`／`-runtime`／`-load`／`-ui` 与 `route-ui-only`／`route-content`／`route-save`／`route-snapshot-domain`／`route-blind-closure`／`route-unmapped-fail-closed`／`route-declared-none`／`route-scope-matches` **全部 PASS**；`negative-stop`／`negative-continue`（旧行为探针）已按 §4.3 改为隔离反例。
- `& tools/check-index.ps1`：**退出码 0**〔2.4s〕，`CHECK INDEX PASS: frozen index equals the derivation (digest db5617dd…)`。
- `-Suite runner`：**PASS 1446 断言**〔1.3s〕（含 i–viii 与 G3 全部样例）。
- 注入复现（真实注入，非桩）：`--probe-suite-failure`／`--probe-suite-runtime-error`（`tests/runtime_error_probe.gd`）／`--probe-suite-load-failure` 三种都得到 `SUITE RESULT: runner FAIL`＋后续 `tower PASS`、`unrun=[]`、`rules.retry=[runner]`、退出码 1；UI 侧 `--probe-module-runtime-error` 得到 `SUITE RESULT: localization FAIL`＋`SUITE RUNTIME: localization 1`＋`home PASS`（`await` 内报错后控制权返回宿主，§10-2 的回退条件不成立，UI 隔离按 §4.2 正常交付）。
- `-Changed -ListOnly`（本片工作区 9 个文件）〔7s〕：`.zcode/…` 正确判为 `ROUTE NONE`、新增 `tests/*` 判为 `tests/**` 闭包、`tools/*` 判为 `runner`、`runner_cases.gd` 判为 owner `runner`。
- **`-VerifyRunner` 的既有缺口（本片修）**：选择探针的原实现把子进程 stderr 经 `2>&1` 灌进父进程，`ErrorActionPreference=Stop` 下变成终止错误——`-Suite runner -VerifyRunner` 在 `3afdc55`（stash 后重跑）**同样失败**，属既有 harness 缺陷；改为 try/catch 捕获后退出码与消息都成为探针证据。

**敏感性证明（原始输出，全部还原、`git status` 干净）**

1. 冻结物改一字节（`"schema": 1`→`2`）：`CHECK INDEX FAIL: frozen index schema is not 1`、退出码 1。
2. 冻结物改内容一字节（`"blind": 4`→`5`）：`CHECK INDEX FAIL: frozen index is not the derivation, first difference at root.stats.blind (4 vs 5.0)`；默认门禁 `-Suite runner` 同步红：`RUNNER index_matches_regeneration: … first difference: root.stats.blind (4 vs 5.0)`＋`FAIL: 1/1446 assertions`。
3. 删一条索引边（`rule:action_copy → spire-godot/core/action_copy.gd`）：`first difference at root.suite_files.rule:action_copy.spire-godot/core/action_copy.gd (missing on right)`，`runner` 同红。
4. 源码漂移不 `-Write`（给 `tests/content_cases.gd` 追加一行注释）：`RUNNER index_matches_regeneration: … first difference: root.generated_from`＋`index_regeneration_is_the_only_writer`，`FAIL: 2/1446 assertions`。
5. 隔离：见上"注入复现"。

**新登记：一条既有红项（非本片引入，未修）**：界面模块 `interface`（`tests/interface_ui_cases.gd:156`）失败——
`CARD ART every registered card has an illustration: [witch_strain, … witch_authority]`（28 张角色二卡无立绘），`UI SUITE interface: 355 assertions`。
**分类证据**：`git diff 3afdc55` 对 `spire-godot/ui`、`spire-godot/assets`、`spire-godot/content` 与该用例文件**均为空**（本片只改 `tests/` 宿主／`tools/`；用例内部断言未动），断言内容与种子／夹具未变 → **既有内容缺口**，此前未登记是因为门禁从未单独跑过 `interface` 模块。另记：`spire-godot/ui/event_screen.gd`→UI `events`、内容包清单两条路由实跑均绿，说明该红不是路由引入。

**未验证／未做**：全量 `-Suite all -UI -UISuite all`（契约要求它只作里程碑唯一入口，本片按其规定未跑）；Android 真机；打包／发版／推送；`INDEX_DEFECTS` 学习环尚无条目可演（列表为空是"未发生漏检"的记录，不是覆盖证明）。四态计数：**passed**＝隔离 37 套件＋内容路由 7 套件＋界面 events／home／localization＋runner／tower＋8 个 route 探针＋5 个隔离探针；**failed**＝`card_power` 5、`installed_tools` 1、`tower_progression` 10（均既有登记）、`interface` 1（本次新登记）；**unverified**＝全量与 Android 真机；**skipped**＝`-Exhaustive` 与 `normal_play`／`baseline`（按设计不进路由）。

## 2026-09-16 状态迁移管线收束：实现四批落地与四项判据（实现者）

域：`spire-godot` 状态迁移管线——`state.phase=`／`state.room=` 的唯一写入者 `_apply_transition`、
唯一战斗结束判定 `_battle_end_reason()`、唯一执行 `_finish_battle(end_kind)`、进程内迁移日志
`_transition_log`。契约 `docs/transition-pipeline.md` §2–§6；基线见本文件同日的冻结记录
（`TRANSITIONDIGEST 00089c29a675e1268473645ab6b7a363e70295abf575cc6cc2929db995ca3e11`）。
不推送、不打包、不发版；本片不新增 `core/*.gd`，不改存档格式、玩家文案、数值与 UI。

**四批提交（均在 `event-pipeline-unification`，基线 `ce4f978` 之后）**

| 批 | 提交 | 内容 |
| --- | --- | --- |
| 基线 | `9ee7a2f` | 冻结迁移 oracle 与基线（脚本与基线在 gitignored `build/`，摘要入本文件） |
| ① 战斗结束判定 | `d519402` | `_battle_end_reason()`（""／victory／captured／saturated）＋`_finish_battle(end_kind)`；`_finish_if_saturated()` 变薄封装；4 处 `_all_gone()` 判定改走同一判定；2 个测试调用点按声明 kind 适配 |
| ② 阶段赋值 | `a1744de` | 26 个 `state.phase=` 写入点全部改走 `_apply_transition`；新增 `TRANSITIONS` 声明表与 `_transition_log`（进程内） |
| ③ 房间赋值 | `9d5a6af` | 最后 10 个 `state.room=` 写入点改走主路径；`_room_transition_kind`（层高＝`floor_enter`，否则 `room_enter`） |
| ④ 闭环 check 与收口 | 本批 | `transition_write_sites_are_pinned`（architecture）＋§5 八条 Gherkin 具名 check；`_apply_transition` 阶段显式化与日志一次一记 |

**收束后规模（实测扫描，`文件|函数|组`）**：①`state.room=`／②`state.phase=` 各 1 点（都在
`_apply_transition` 内）；③战斗结束 19 行／8 个函数（`_battle_end_reason`／`_finish_battle`／
`_finish_if_saturated`／`_start_round`／`_enemy_phase`／`dispatch`／`_execute`／`_end_turn`，
即契约 §1 的"8 个语义入口"，13 个引用点保留为同一批函数；④`_restart_tower(` 4 行（定义＋
`demo_exit.continue_run`／`prison.return_to_tower`／`prison.completed_turn`）。

**判据（墙钟为本机实测）**

1. **迁移 oracle**〔7s〕`--baseline=` 退出码 0、`TRANSITION RESULT: PASS (31 scenarios, 0 failures)`、
   输出 `SCRIPT ERROR|ERROR:|Invalid access` **命中 0 行**；31 个场景的
   `before`／`after`／`commit_logs`／`log_texts`／`digest` **逐字段等于冻结基线**，迁移日志增量等于
   抓取时冻结的 `transition_log_declared`（比对时两侧按"相邻同名＝同一次迁移"合并，见下"口径"）。
2. **规则门**〔2m08s〕`& tools/check.ps1 -Suite core,rewards,battle_saturation,guard,prison,tower,tower_progression,events,event_flow,persistence,architecture -Impact -KeepGoing -TimeoutSeconds 900`
   → `-Impact` 展开 44 分类；`FAIL: 5/7861 assertions; 6 engine errors`，
   **红集＝{`card_power` 5 条, `installed_tools` 1 条} ⊆ 已知四项**；`installed_tools` 的
   `SCRIPT ERROR` 触发 runner 的 `runtime_error` 分支，其后 **24 个分类 `unrun`**
   （清单：environment_height／exploration／shoulder／slip_motion／torso_binding／casting／wall／
   special_equipment／services／intent／action_copy／status／persistence／rewards／events／core／links／
   prison／guard／pressure／enemies／trader／tower／tower_progression），**合并为一次调用补跑**〔3m29s〕：
   23 PASS，`tower_progression` FAIL＝**10 条（已登记）**；补跑后 `unrun` 为空（未记作通过）。
   `summary.json`：`before==after`、无 `source_changed`。
3. **界面门**〔1m22s〕`& tools/check.ps1 -UIOnly -UISuite persistence,home,events -TimeoutSeconds 900`
   → 退出码 0、三分类 PASS、`UI PASS: 369 assertions`。
4. **闭环 check 双向比对**〔架构套件 25s〕：扫描 `core/**/*.gd`（递归）、`#` 之后截断、`==` 排除，
   四组模式；扫描集 ⊆ 声明表（表外为空）且表内 14 项逐项命中（含③的 8 函数集合断言）。
   **敏感性证明（原始输出）**：在 `_finish_if_saturated` 顶部临时插入一处表外 `state.phase="battle"`
   → `SUITE RESULT: architecture FAIL`、`FAIL: 1/462 assertions`、
   `ERROR: ARCH transition scan finds no write site outside the pinned table: ["[\"res://core/game.gd:803:_finish_if_saturated\"]"]`
   （即 `文件:行:函数`）〔26s〕；随后还原（`git diff` 无残留）→ `architecture PASS`、`PASS: 466 assertions`〔25s〕。

**§5 八条 Gherkin 具名 check（全部走真实公开命令：先取 `candidates()` 再 `dispatch`）**

| 场景 | 落点 | 断言要点 |
| --- | --- | --- |
| 01 `battle_end_single_path_for_all_entry_points` | `tests/battle_reward_cases.gd` | 9 个入口（普通最后一击／`end` 后全灭／空间耗尽／事件战／监狱出口战／`dispatch` 后全灭／敌人离场后全灭／投降收押／警卫宣告收押）各自：迁移日志恰一条 `battle_end_*`、目标阶段不变、`_finish_battle` 计数 1（收押 0，走 `_apply_transition`） |
| 02 `prepare_end_three_branches_one_kind` | 同上 | `pack`／`map`／`cleared` 三支日志均为 `prepare_end`、目标阶段分别正确 |
| 03 `floor_enter_is_one_family` | `tests/tower_cases.gd` | 跨层抵达恰一条 `floor_enter` 且 room 变化在该条内；同层（牢房 -1→塔底 -1，真实出狱回合）零 `floor_enter` 且有 `tower_restart` |
| 04 `capture_routes_through_the_main_path` | `tests/guard_cases.gd` | 投降与警卫宣告两条收押：日志恰一条 `battle_end_captured`、`captured`／`prison` 不变、能量归零／无力化／牢房初始化与入狱快照（在迁移之后建立）一致、`validate()` 通过 |
| 05 `non_transitions_do_not_write` | `tests/service_cases.gd` | 打牌／未全灭的结束回合／商店交易／事件选择／牢房移动：日志为空、阶段与房间不变 |
| 06 `transition_log_never_reaches_state_or_view` | `tests/persistence_cases.gd` | 迁移日志在进程内非空；`state` 无 transition 键、快照／`pack` 存档／`get_view` 均不含 `battle_end_` 或 `_transition_log`；恢复存档不写日志 |
| 07 `transition_write_sites_are_pinned` | `tests/architecture_cases.gd` | §4 双向比对（含敏感性证明，见上） |
| 08 `demo_end_and_tower_restart_use_declared_kinds` | `tests/tower_cases.gd` | demo 结束＝`demo_end` 且阶段／房间不动；返塔继续日志全为 `tower_restart`、`map`／`tower_bottom` 不变 |

**迁移日志口径（新增，冻结基线时声明、收束后按此判定）**：一次迁移记一条。①同一 kind 的
`phase`／`room` 由调用点分两次写入（**赋值位置一律不变**），第二条只写未写过的字段时不再记；
②重复写同一字段仍是新的一次迁移（例如牢房每回合 `prison_cell_enter`）；③`_apply_transition` 只在
调用点显式给出 `phase` 时写阶段，且必须落在 `TRANSITIONS` 声明的集合内；只带 `room` 的续写调用不写阶段。
oracle 比对按"相邻同名合并"处理两侧，故行数差异不算漂移，kind 或顺序差异才算。

**与契约文面的偏差（实现中发现，已在报告列出）**：①契约 §5 场景 01 的"恰有一条"以本口径满足
（收押的 phase／room 两次写入合并为一条）；②契约 §3 表把 `guard.gd:113/117` 写作"经主路径执行"，
实现为两次 `_apply_transition`（不经 `_finish_battle`：后者拥有胜利／饱和的奖励体，收押副作用仍全部留在
`Guard.capture`、顺序不变）；③`floor_enter` 为契约 §5 场景 03 用到的 kind，§3 表只列了 `room_enter`，
本片补声明 `floor_enter`（层高判定）并保留 `room_enter`（抵达阶段的阶段写入）；④`demo_end` 为新增
marker kind（不写 phase／room，只记日志）；⑤`_enemy_phase` 尾部的 `_battle_end_reason()=="victory"`
判定在真实流程中不可达（1126／1166 的两处饱和调用先接管；只有"未完成的连续卡牌"这一非法状态才落到它），
oracle 用该非法状态单列一个场景（`battle_end_enemy_phase_all_gone`，唯一 `skip_validate` 行）冻结其行为。

**oracle 基线声明的两处更正（harness 缺陷，非行为漂移）**：抓取时无法自证的两行声明与代码事实不符——
`tower_restart_same_floor`／`demo_continue_restart` 声明 2 条 `tower_restart`（实际合并为 1 条）、
`prepare_end_cleared` 与 `practice_init_rest` 的重复同名写入；因两侧按同一合并口径比对，
**基线 JSON 与脚本的冻结内容未改**、行为字段零差异（31/31 逐字段相同）。

**未验证／未做**：`-Suite all`／`-UISuite all` 全量回归（契约未要求）；android 真机；
`docs/save-fixed-points.md`（暂停中，未 `stash pop`、未消费迁移日志，挂点已留）；打包／发版／推送。

## 2026-09-16 状态迁移管线收束：迁移 oracle 基线冻结（实现者，改道前）

域：`spire-godot` 状态迁移管线（`state.phase=`／`state.room=` 写入点、战斗结束判定、迁移日志）。契约 `docs/transition-pipeline.md` §3／§6(b)／协调者记录（本片硬前提：**改 `core/` 之前先冻结迁移基线**）。基线提交 `ce4f978`，抓取时 `git status --short` 为空。

- 脚本（gitignored）：`spire-godot/build/transition-oracle-20260916/transition_oracle.gd`，
  sha256 `b49b0164a6b962fc8eae4a843c36510e1fa12c846d9f0e565856fdc6ed092278`；式样照 `build/event-oracle-20260916/event_oracle.gd`，含 JSON 数字类型归一（比对侧）。
- 基线：`spire-godot/build/transition-oracle-20260916/baseline.json`，
  sha256 `ba979d18c31952d6d69ef06ce2ed102f7503c518fa8c6125ea6482c92bb5b4c8`，
  `TRANSITIONDIGEST 00089c29a675e1268473645ab6b7a363e70295abf575cc6cc2929db995ca3e11`，**31 个场景**。
- 抓取命令（`spire-godot/` 下）：`<godot> --headless --path . --script res://build/transition-oracle-20260916/transition_oracle.gd -- --write=build/transition-oracle-20260916/baseline.json`
  → 退出码 0，日志 `SCRIPT ERROR|ERROR:|Invalid access` **命中 0 行**，`TRANSITION PROBLEM` 0 条；同参数连抓两遍产物**逐字节相同**（`baseline-rerun.json`）。
- 场景覆盖（逐类）：`setup_init`／`departure_start|end`；八类战斗结束入口（普通最后一击／`end` 后全灭／空间耗尽／事件战／监狱出口战／投降收押／警卫宣告收押／`_enemy_phase` 尾部全灭）；整备结束三类（`pack`／`map`／`cleared`）；进层（`floor_enter`）与换塔同层（`tower_restart`，牢房 -1→塔底 -1）；房间迁移与练习初始化四种（rest／shop／battle／prison）；牢房回合、巡视、逃脱；事件进入／空房离开／事件道具奖励；demo 结束与返塔。
- 每场景逐字段冻结：迁移前后的 `phase`／`room`／`floor`／`version`／`state.rng`／本次提交日志 sha256（`commit_logs`）＋可读日志行（`log_texts`）／`room_event` 摘要，并给出行摘要 sha256（`digest`）。
- **迁移日志的比对口径**（写进脚本头注，供后续复核）：`transition_log` 是本次新增的进程内日志，收束前不存在；基线在抓取时冻结 `transition_log_declared`（31 行的期望 kind 清单），比对时要求收束后的日志增量**逐字等于该冻结声明**，其余字段双向逐字段比对。
- 基线自检（收束前用 `--baseline=` 自比）：仅 31 行 `transition_log` 差异（期望），**其余行为字段零差异**，`TRANSITION RESULT: FAIL (31 scenarios, 31 failures)` —— 证明该 oracle 的行为字段在收束前是逐字段自洽的（`selfcheck.log`）。
- 未验证／未做：`core/` 尚未改动（本记录只冻结基线）；`_apply_transition`／`_battle_end_reason` 与迁移日志尚未存在。

## 2026-09-15 文案路由与按需投影（B0、R0–R6、B1–B3）验收与配对收益

域：spire-godot 玩家可见文案的投影路径（`get_view().card_texts` 收窄到显示集合 S、`card_instances` 只留手牌 uid、`deck_list` 移出 View、card 组候选 detail 改按需、`core/copy_router.gd` 收口 74 类文案）。契约 `docs/ondemand-copy.md`。

提交链：`cc5e8f0`(B0)／`7f1c748`(R0)／`40071d4`(R1)／`3f895b0`(R2)／`ee02495`·`2c2115c`·`964347a`(R3a/b/c)／`6247a56`(R4)／`ed2b5b2`(R5)／`0ce790e`(R6)／`6eca6e0`(B1+B2)／`a3cdcbe`·`638d6bc`(B3)／`67650f9`(场景 1/5 具名 check)。

- 三条 oracle（实现者运行，协调者核对日志）：`MASK DECLARATION` 与实际移除键集合**相等**（B1 `card_texts` 90/90/90/92/92/92 键、`card_instances` 0；B2 `deck_list`；B3 card 组 detail 60/60/130），`sha256(mask(new))==sha256(mask(基线))`、`masked_hash=true`、无差异；全牌型三入口（`live_card_text`／`live_card_text_set`／∈S 的 `view.card_texts`）逐字段相等，实例部分为包含关系（只允许 `face_costs`／`casting`）；真实夹具 `ui.projection_misses` 为空，缺键场景留有具名记录。收口阶段（R0–R6）为**空声明集**全等，即未改变 View 内容。
- 门禁（§8 原命令）：规则 `20260915T200001805-38332` 红集=`card_power`；界面 `20260915T200035182-33956` 红集=`shoulder`；`-KeepGoing` 版 `20260915T194250607-55264`＝5/9608（失败集恰好 5 条已登记 `witch_*`）、`20260915T194512850-9968` UI 1045 断言红集恰好 `shoulder`2+`torso_binding`1+`interface`4。**红集只等于已登记既有阻塞项，未多一条。**
- 夹具序列与具名 check：场景 0／1／4／5／7 已落地（场景 4 由 B2 oracle 的全量条目比对 + 牌堆浏览/商店去卡套件 + 三入口相等三层覆盖，未单列）。
- **配对收益**（`docs/equipment-performance.md:45` 协议：同机同批、交替、2 次热身 + 15 次有效配对；headless；对象为一次 `get_view()` 与一次 `candidates()`；旧侧 `0ce790e`（收口后、按需前）、新侧 `67650f9`）：

| 夹具 | 视图 旧→新 中位 (ms) | 配对比值中位 | 候选 旧→新 中位 (ms) | 候选条数 |
| --- | --- | --- | --- | --- |
| battle:0 | 79.39→23.22 | 0.311 | 24.14→11.46 | 86 = 86 |
| battle:12 | 108.72→44.87 | 0.416 | 44.70→27.22 | 98 = 98 |
| battle:26 | 206.28→81.24 | 0.398 | 120.54→54.83 | 182 = 182 |
| departure:0 | 50.04→6.56 | 0.127 | 0.56→0.50 | 6 = 6 |
| departure:12 | 58.89→9.37 | 0.164 | 0.73→0.69 | 6 = 6 |
| departure:26 | 72.14→13.61 | 0.186 | 0.96→0.81 | 6 = 6 |

- 夹具未漂：旧侧六档的 `view`／`candidates` 哈希与 `docs/equipment-query-seam.md` §8.2 冻结基线逐项一致（如 battle:26 `f7401077…`／`361c3777…`）；新侧按设计不同，其中 departure 的 candidates 哈希**未变**（该相位没有卡牌候选）。
- 口径：这是**同机同批配对数字**，不与历史批次拼接、不外推为帧率或全设备结论；本批只测 headless；收益来自按需化，收口阶段是逐字节等价的纯结构迁移。
- 未验证：**一次完整的独立验收未跑完**（验收者两次中断，已复跑的片段为规则门、`-KeepGoing` 界面门与人路径套件，日志见 `_spire-wt/gate-*.log` 与 `build/checks/20260915T22*`–`T23*`）；未跑 `-Suite all`、未做 Android 真机；`escape_preview` 未动；UI 响应路径与节键未动；未打包、未推送。收尾过程中另行发现并登记了 `rewards` 的既有红项（见下"既有红项登记"）。

## 2026-09-15 既有红项登记（非本次两片引入，未修复）

域：spire-godot 测试门禁在本次两片（装备只读查询接缝、文案路由与按需）**开工前的提交上即已存在**的失败项。两项均不属任何一片的改动范围，**未修复、未分类**；登记供后续接手方与全量回归判断使用。不得把其中任一项当作已通过，也不得为凑绿而从门禁命令里删除对应套件。

- `card_power` 规则侧：`tests/card_power_cases.gd:85` 的 `CARD reward membership follows rarity and explicit gift exclusion` 等 5 条 `witch_*` 奖励归属断言失败。复现：在未改源码的 HEAD（`1795e86`）上 `git stash` 后运行该套件 → `build/checks/20260915T163500673-34468`，退出码 1、5 失败 / 1781 断言。归因方向：`core/witch_expansion.gd` 的 `REWARDS` 与 `rules.SPECS.rarity` 的关系；未定类，未修改。
- `shoulder` / `torso_binding` 界面侧：三条失败（`SHOULDER UI compact cards show side and method`、`SHOULDER UI host card explains remaining-side penalty`、`BIND UI attachment and independent durability are visible`）。复现与根因见下方装备片验收条目；摘要：在切片父提交 `16c89e9` 的临时工作树上结果相同（`20260915T160616347-54344`、`20260915T160711923-52452`），根因 `ui/release_details.gd:35-38`（v0.17 `e635bf5`）只为 `lock_only`／`is_special` 渲染 `card_status`。
- `tower_progression`（规则 + 界面）：10 条规则断言 + 1 条界面断言失败（`tests/demo_exit_cases.gd:44/51/55`、`tests/tower_progression_cases.gd`；含 `DEMO boss health uses normal base, not compounded previous health`、`DEMO custom encounter health also scales`、`DEMO summon base scales while fixed healing remains five`、`PROGRESSION actual adjacent departure summit`、`PROGRESSION rebuilt summit creates a new boss instance without clearing safety history`）。**四点定位，失败集逐条相同、均在 10/215、退出码 1**：`964347a`（HEAD，`20260915T171801224-46088`）／`1795e86`（B0 之前，`20260915T171350281-47260`）／`e635bf5`（v0.17 发布点，`20260915T172946961-28640`）／HEAD 且仅把 `core/demo_exit.gd` 还原到 R1 之前（`20260915T171821467-40568`）→ **先于 v0.17 即存在**；证据留档 `build/ondemand-copy-20260915/preexisting-tower-progression-*.log`。
- `interface`（界面）：多套件连跑时报 4 条错（单独跑只 1 条，属模块间状态污染）。`964347a`（`20260915T171841906-51540`）与 `1795e86`（`20260915T172502057-47120`）失败集相同 → 既有。
- `rewards`（界面）：1 条断言失败——`tests/reward_ui_cases.gd:138` 的 `REWARD UI final unlock segment does not promise a third lock`（313 断言、exit 1）。**三点定位，失败集逐条相同**：`67650f9`（HEAD，`20260915T233305923-26972`）／`base-0ce790e`（R1–R6 后、B1–B3 前，`20260915T233523727-20952`）／`1795e86`（**文案片首个代码提交之前，`core/copy_router.gd` 尚不存在**，`20260915T234925378-16980`）→ **非本次两片引入**；`e635bf5`(v0.17) 亦红（`20260915T234617519-20320`，但在 217 行因另一处脚本报错先中断，仅作旁证）。根因：链式行的 detail 由 `ui/release_details.gd:53-54` 放进**默认折叠**（"效果详情 ＋"），故不在 `visible_text` 中；`core/release_view.gd` 与 `tests/reward_ui_cases.gd` 在 `e635bf5→HEAD` 逐字节未变，属 **v0.17 UI 渲染 vs 测试期望**同族（与上面 `shoulder`／`torso_binding` 同源）。该套件自 v0.17 起未绿、且从未列入任何门禁命令。
  - 若日后要修，两条路都需先裁定：(a) 测试改为先展开"效果详情 ＋"再断言（等于改断言，须明确授权）；(b) 让链式行恢复内联 detail（改 v0.17 的 UI 设计，超出本片范围）。**本次两片都不得动。**

## 2026-09-15 装备只读查询接缝（B1–B9）验收

域：spire-godot core 装备只读查询（`_equipment_read` 作用域、契约 §1 查询接口、§3.1 外层入口作用域）。对象提交 `def4039`；链 `eb6eeed`(B1)／`094c1d3`(B2)／`240658c`(B3)／`8de2957`(B4)／`79946ab`(B5)／`5af275d`(B7)／`09ccdd7`(B8)／`def4039`(B9)，B6 并入 B9 无独立提交。验收者为独立复跑（非继承），未改产品代码与测试逻辑；测试存档隔离（`ui.persistence_enabled=false`），不默认截图。

- 范围预检（不算通过）：`& tools/check.ps1 -Suite architecture,equipment,equipment_complete,links,composites,shoulder,torso_binding,casting,prison,events,slip_motion -ListOnly` → 退出码 0、`PLAN ONLY`、列出全部 11 个套件。日志 `build/checks/20260915T154755781-47440`。
- 规则门（验收者复跑）：同一 11 套件 `-TimeoutSeconds 900` → 退出码 0；11/11 `SUITE RESULT: PASS`、`PASS: 3509 assertions`；`build/checks/20260915T154809866-41232/summary.json` 的 `status=passed`、`before==after=089A94CB8229B7444E752F15A5FC2219079BF97ED3D9CB5F4985BD8DCF5F351D`，与实现者早前同一棵树的 `20260915T154200809-8364` 指纹一致（指纹稳定）。§11 具名检查随所通过的分类执行，未按条单独打印。
- 界面门（验收者运行）：`& tools/check.ps1 -UI -Suite architecture -UISuite equipment_complete,body_layout,shoulder,torso_binding -TimeoutSeconds 900` → 退出码 1、`summary=status=failed`（`build/checks/20260915T155153696-56180`）。architecture 规则 193 项通过；UI 在 `shoulder` 套件 19 项断言后失败 2 项：`SHOULDER UI compact cards show side and method`、`SHOULDER UI host card explains remaining-side penalty`；该次调用中 `torso_binding,body_layout,equipment_complete` 未执行。
- 归因（保持未定类，留协调者裁决）：上述失败在切片父提交 `16c89e9` 的临时工作树上复跑结果相同——`shoulder` `20260915T160616347-54344` 19 项断言、同样 2 错；`torso_binding` `20260915T160711923-52452` 11 项断言、1 错（`BIND UI attachment and independent durability are visible`）。根因是 `ui/release_details.gd:35-38`（git blame 落在 v0.17 提交 `e635bf5`）只为 `lock_only`／`is_special` 渲染 `card_status`，而既有检查期待普通件的 `card_status` 文案（"无法挣扎"／"肩带N条…×0.5"／"躯干固缚"／"独立连接耐久"）出现在 EquipmentDetails；与 B1–B9 的实现代码无关。归类处于"程序本身（既有 UI 文案渲染）"与"测试脚本（既有期望未随 v0.17 更新）"之间，无法确定单一归属；未自行修改，也未放宽断言。临时工作树已删除。
- 其余界面分类（验收者复跑，干净工作区）：`-UIOnly -UISuite body_layout,equipment_complete` → `20260915T161052970-53984` 245 项通过、退出码 0、`status=passed`、指纹稳定（此前一次 `20260915T160743098-42972` 因验收者临时脚本改变指纹被标 `source_changed`，仅记录 245 项断言结果，不称冻结通过）；`-UIOnly -UISuite route,events,prison` → `20260915T161152069-53156` 531 项通过（route 地图、prison 牢房、events 事件）、退出码 0、`status=passed`、指纹稳定。
- 人的路径证明：优先复用既有分类，缺口由验收者补充脚本补齐（运行时临时置于 `tests/`，跑完已删除；脚本与日志归档在忽略目录 `build/validator/validator_equipment_seam_paths.gd`、`build/validator/supplement-head.log`，`VALIDATOR PASS: 44 assertions`、退出码 0；工作区随后恢复干净）：
  1. 战斗中真实点开普通件详情：位置行与 View section 文本、耐久／紧度行与 View entry、View entry 与权威实例逐项一致 → 新补（`body_layout`／`equipment_complete` 复用了开合、位置标签与文案断言）。
  2. 肩带件：详情卡片数 = `Shoulders.attached`（2/2）、每件名称、视图 `card_status` 的"连接至宿主"= 权威 `_equipment_name(host)` → 新补；`shoulder_ui_cases` 的可见"无法挣扎"文案属上一条红项，不计通过。
  3. 复合组件与链接绳：链接绳卡片使用 View 名称、每张卡片耐久 = 权威件耐久、三次真实切割根套体后"遗留外带"出现且被移除件无残留卡片 → 新补（"遗留外带"复用 `equipment_complete` 既有断言）。
  4. 真实打出会损坏装备的牌（`strain` 经真实拖放提交）：详情显示新的耐久／紧度行且不再包含旧行 → 新补（既有 `release_preview` 只覆盖提交前数值预览）。
  5. 进入地图／事件／监室各一次：三项既有套件全通过（上条）；补充脚本另断言三处入口后 `_equipment_read.is_empty()`、`validate()==""`，并以 QuickSL 完成一次读档校验 → 新补。
- 未验证项与边界：未运行全项目 `all` 回归；未做 Android 真机验收；未独立复核 §8 的 oracle 基线与分批记录（不在 §12 命令内，属实现者证据）；界面门整体仍为 `failed`，`shoulder`／`torso_binding` 两项既有红未修复，本片不能宣称验收全绿或全项目通过。本次只读验收：未改产品代码与契约、未截图、未打包或发布。

## 2026-09-15 v0.17 发布

- 用户要求Windows / Android打包、推送GitHub并发布v0.17；随后明确要求停止继续测试并直接发布。原已完成角色2、监狱、快捷解除、图鉴与立绘等工作随当前项目一并交付。
- Android通用PopupMenu接入独立触摸桥接；通过嵌入窗口入口处理原生选项，修复设置点选不生效、长列表覆盖打开按钮时误选；滑动不点选，取消不提交，系统返回键优先关闭选项框。游戏规则未因这次修复改变。
- 触摸专项20260914T154140815-7672通过23项断言，退出码0，源码指纹稳定；根指引检查及其5项单元测试通过。
- 全量尝试20260914T154351828-34328未完成。card_power中5项旧公共卡池断言未兼容新增小魔女专属卡；normal_play策略在零费失败留手法术上反复重试，诊断确认结束回合仍为有效候选。停止检查进程后汇总为failed，全量UI未执行。本次不宣称完整回归通过；未发布后续尚未验证的测试策略修改。
- Windows目录outputs/spire-v0.17-windows-x64-release-20260915：导出前后运行资源指纹一致；package-check-20260914T154921029通过PCK探针、角色2平衡探针与发布EXE独立启动。最终ZIP重新解压后23个清单文件校验一致。
- Android目录outputs/spire-v0.17-android-release-20260915：版本0.17、versionCode9、minSdk24、ARM64+ARMv7；V2/V3发布签名、provider唯一性、16KB对齐及内容包校验通过。android-probe-20260914T155014250包内资源探针通过。没有连接的Android设备，未做真机验收。
- 交付文件位于outputs/release-v0.17-20260915，均为正常无密码包，附SHA256SUMS.txt。源码/测试/资源/文档纳入对应提交；缓存、日志、玩家存档及签名秘密排除。

## 2026-09-15 点击／拖牌／快捷栏目标查询收拢

- 共用ui/target_queries.gd的10个只读查询；main、drag_targets、quick_release_bar保留原交互入口并转交共享筛选。模块不持有Game、控件或跨刷新缓存，返回原候选供既有ID＋版本提交；各入口原有去重、牌面、自动目标及首／末不可用原因顺序保持。RuleChangePackage见docs/release-interface.md。
- build/target-queries-20260915/compare.json记录空装备、多装备、复合与链接、拘束衣、长型单手套、监狱及特殊装备七场景；每场景1390项，共9730项新旧查询结果与顺序一致，完整状态和View未变。旧实现仅为忽略目录内诊断参照，不进入运行代码；本批不宣称帧率提升。
- targeting原分类新增17项契约断言，覆盖共享物理目标与两面、候选引用、返回容器隔离、首／末拒绝原因、捕缚额外目标、手牌去重、牢门、火球、指定ID顺序及失效版本；继续执行原真实点击和拖放用例。
- `tools/check.ps1 -UIOnly -UISuite targeting,basic_attacks,body_layout,keyboard,guard,equipment_complete,casting,card_power,exploration -TimeoutSeconds 600`：`20260914T145522480-63836`的card_power 307、basic_attacks 236、exploration 43、keyboard 87、casting 55、body_layout 147、targeting 100、equipment_complete 98、guard 87，共1160项断言全部通过，用时338.36秒。检查期间工作区变化，汇总为source_changed、退出码1；按修改时间发现同期英文目录、目录生成脚本和本地化测试更新，只记录断言结果，不宣称冻结源码门禁通过。
- 本批相关文件git diff --check无空白错误。纯UI查询重构未重复运行规则全量；未生成截图、处理存档、打包或发布。

## 2026-09-15 工具模块数据／规则分层

- 20个读取对局状态的工具查询方法原样迁到core/tool_rules.gd，继承data/field_tools.gd的同一只读注册表；数据层保留3个纯方法，197→61行，移除core/contact依赖。g.Tools入口与规则算法保持；game、game_view、consumables改读规则模块，图鉴／掉落继续只读数据。23个方法正文逐项一致，无重复转发或第二份数值表。实施边界同步game-design.md与AGENTS.md。
- build/tool-boundary-20260915记录普通／复合链接／监狱／特殊装备×站坐卧×有无触手朋友的24组完整View和候选对照，以及33次正式安装／取回的返回值与完整状态对照，全部一致，查询保持状态。副本仅在忽略目录，运行源码只有一套实现；此批不以耗时或帧率提升为目标。
- 工具、高度和消耗品按Impact合并item_discard、consumables、encyclopedia、installed_tools、environment_height、casting。`20260914T144300639-62632`中item_discard288／consumables229通过，图鉴测试仍通过Book.Tools调用实时description而解析失败；改为neutral.Tools，保留图鉴与实时说明一致性断言。`20260914T144358099-59992`补跑encyclopedia506／installed_tools44／environment_height25／casting581，共1156项通过。
- 新增架构检查先修正了脚本反射写法（初次ListOnly即报告解析失败，未作通过证据），随后`20260914T144358082-58872`暴露测试错误地试图修改只读常量表；未改运行时放宽只读，而将断言改为继承表身份、常量只读与标签一致。`20260914T144518873-60540`：architecture158／exploration198／prison1255，共1611项通过，退出码0、指纹稳定。规则去重合计3284项通过。
- `20260914T144358099-59992`窗口encyclopedia170／installed_tools56／exploration43／items46通过；consumables原断言仍要求普通动作栏总有InstalledTool按钮，实际入口已迁到快捷栏。改为真实关闭抽屉、切换快捷栏、点击该工具，核对全身固定说明、精准物品和无行动消耗。`20260914T144702242-63500`补跑consumables52项通过，窗口去重合计367项。最后批次运行期间有同期源码变化，状态source_changed；仅报告逐批断言通过，不称整版冻结回归。原失败日志均保留，UI SCREENSHOTS:none。
- 存档专项继续延期；没有全项目回归、打包、发布或大版本完成宣告。此前记录中的data/field_tools职责混杂已在本批解决，其他大文件和图鉴／教程分层风险仍按后续独立批次处理。

## 2026-09-15 架构与接口边界检查

- 静态扫描core 45／data 26／ui 46，共117个运行脚本的显式load／preload依赖与UI对game的调用；检查主提交入口、候选索引、只读投影、只读查询生命周期、自缚临时状态及新增快捷栏／释放预览的职责。诊断范围与当时源码散列保存在忽略的build/architecture-20260915/audit.json。没有显式加载循环、core／data反向加载ui／tests或UI直接game.state／私有game方法调用；动态助手调用不由此静态扫描证明安全。
- 发现并修复两个间接越层读取：主立绘和身体栏通过Character.active(game)读取实时角色，可能与render(snapshot)的独立快照不一致。改为EquipmentPortrait共享显示策略，只消费已有character_id与固定立绘偏好；无新状态、规则、文案或存档字段。display补5项真实不同角色对局与快照交叉显示、两处一致、偏好覆盖及状态不变检查。契约见ui-scene-refresh.md。
- 保留职责不同的接口：physical_pieces／equipment_targets／action_targets查询范围不同；ActionIndex.find取首个匹配，first_usable取首个可用并在全不可用时返回末个，快捷栏first则保留首个不可用原因，不能按名称相近直接合并。正式UI行动仍统一进入game.dispatch，候选ID、版本与资格在支付前复核，事务复制状态后执行并在失败时恢复；未添加另一套执行入口。
- 未消除的维护风险：检查时game.gd约2848行、main.gd约2693行，分别集中大量规则协调与页面／目标选择职责。data/field_tools.gd兼具注册表及触及计算，data/encyclopedia.gd与data/tutorial.gd包含说明投影并引用core，共5条data→core显式依赖；目前无加载循环，但data并非全是纯数据。后续宜按物品操作、目标选择、展示投影等完整职责逐批迁出，保留现有权威规则及分类门禁。本次未为了缩短文件而整体搬移或统一掉不同语义。
- 首轮`20260914T142208740-61812`：architecture151项、display127／home113／equipment_art169／hero_art50共459项窗口断言通过。期间另一批单手套立绘修改了game_view、equipment_portrait、装备立绘测试及素材，报告source_changed，不能视为冻结工作区通过；本次共享显示策略仍完整保留。交叉文件重新导入并补跑architecture、display、equipment_art、hero_art，主页已通过且未涉及后续变化。
- `20260914T142425356-51572`：资源导入、architecture151项、display127／equipment_art176／hero_art50共353项窗口断言通过，退出码0且指纹稳定。随后继续审查新字段的完整传递，发现arena精简hero_view漏掉composite_portrait_layers，既有装备立绘测试只检查身体栏，未捕获战场立绘不一致。将精简显示数据生成收回EquipmentPortrait.snapshot并补短／长单手套在两处立绘一致及输入复制隔离6项检查。`20260914T142716643-60772`因新增测试误将局部变量用于类型判断而解析失败，其他类未执行；改为脚本常量后仅补跑失败／未执行的窗口分类，原失败报告保留。
- 修正后`20260914T142750772-9268`：display133／equipment_art176／hero_art51共360项通过，源码变化仅为同期hero_art测试补充；两项运行代码修复均保留。最后只复核该变化分类，`20260914T142918982-56744`的hero_art51项通过、退出码0、指纹稳定。按各分类最终已执行结果去重，本轮architecture151项，窗口display133＋home113＋equipment_art176＋hero_art51＝473项逐批通过；不把多轮混合结果称作整版冻结全量验收。无默认截图。
- 本轮检查不等同全项目逐条玩法验收；存档专项继续延期，没有打包、发布或大版本完成宣告。

## 2026-09-15 快捷栏重复选择优化

- 只读UI优化包与分段测量见equipment-performance.md。同一格更新只解析一次部位和装备；原候选、排序、精准选择和具体原因保持，不跨同版本的UI操作保留缓存。新增10项检查覆盖换目标、翻面往返、过期版本、缺失部位／目标、主动选择空部位、候选身份及View／状态／控件不变。
- `20260914T141124582-58372`：`tools/check.ps1 -UIOnly -UISuite basic_attacks,keyboard,body_layout,targeting,equipment_complete -TimeoutSeconds 600`，分别236／87／147／83／98，共651项窗口断言全部通过，退出码0、指纹前后一致、summary.status=passed。包含正式出牌、火球、降紧／开锁、原生拖放、键盘和详情开关。测试中窗口最小化导致绘制等待，恢复同一窗口后完成；因此总369.57秒不是运行性能数据。UI SCREENSHOTS:none。
- 五场景9600组新旧显示及候选逐项一致，默认四格全卡牌扫描空闲16→8、带选牌24→4；已记住选择的路径另测，空闲扫描没有下降且密集样例计时回退，具体数据及限制完整保留。诊断副本只在忽略的build目录。
- 本批纯显示选择优化，按模块约定只跑以上受影响窗口分类，没有全项目规则回归、存档跟进、打包或发布。

## 2026-09-14 小魔女扩展与脱缚练习

- 规则包见character-two.md最新扩展段。初始11张、每部位无限预备／每回合一次成功释放、五张新奖励牌、两面混合牌类型、回合增益和强制锁回合均沿正式候选提交。脱缚练习两面共享实体进度，按1×3／1×6／2×6／3×6逐段结算，10／20／30／40次后进化；累计1张而非累计段数，跨战斗保留，卡组与牌堆进度不一致拒绝恢复。
- 初次合批20260914T133646540-24076中card_splash144、architecture151、persistence597、pressure1076通过；其间源码变化，标记source_changed，不作为冻结全量结果。card_expansion的休息限制优先级修复后，20260914T134345605-3048中card_expansion1088、encyclopedia506通过。图鉴旧数量断言已改为按角色过滤。
- 连续开锁旧用例写死入狱魔力100，实际夹具入狱后为80；改为核对真实入狱值扣除本次支付，保留连续开锁、一次付费和临时魔力优先断言。20260914T134638179-22204中rewards666、localization73通过；窗口encyclopedia170、localization51通过。home的旧断言未展开新“装备说明”折叠层，补正式点击后20260914T134844634-62396 home113通过，指纹一致。
- 最后增加同一初始牌依次打出两面、同阶段卡组／牌堆累计差异的回滚检查；20260914T134754114-43468 witch_character455断言通过，指纹一致。窗口覆盖角色2实际选角、预备／释放、释放后自动切回，图鉴角色选择不改对局、五个进化阶段同页、初始稀有度、两面红色警告和分面技能／魔法分类。
- 本批只报告上述受影响分类与补跑结果，没有全项目回归、截图、打包、发布或大版本完成宣告。

## 2026-09-14 墙缝高度与安装工具状态栏

- 位置名称从固定高度表生成，详情、候选、地块与日志共用；不改变安装 ID、触及表、费用或存档。
- 只将正式候选中可触发的安装工具投影到角色状态栏及“环境”分类；沿用道具图标，角标显示次数，点击打开对应详情。随身切割工具和可用药剂不加入；无次数、离墙、不可触及及非行动阶段不显示有效工具状态。预览及点击详情均不改状态或随机。
- `20260914T124451422-55624` 资源导入通过；修正新增英文模板参数后，`20260914T124647878-50060` 的 localization 分类73断言通过。
- `20260914T124714118-55180`：installed_tools/environment_height/exploration/status 规则566断言通过，installed_tools/exploration 窗口99断言通过。期间其他源码仍有修改，门禁标记 source_changed；这些为已执行断言结果，不宣称冻结工作区全量通过。
- 状态窗口旧测试将费用徽标也拼进标题，错误要求整个控件文本以“深呼吸”开头；改为检查实际标题控件后，`20260914T124949797-19420` 的 status 窗口58断言通过。未截图、打包或发布。

## 2026-09-14 拘束具图鉴关键数值与限制补全

- 按用户要求保持简短，只扩充既有条目。普通装备补品质、紧度分档、锁效果；四种口球列出品质与紧度倍率和三档合计，眼罩说明意图遮挡与马具影响。复合装备显示各组件耐久／方法及关键解除前置；链接补向下1.25加成；特殊装备补取出条件与费用、刺激倍率、环境要求、电量耗尽仍保留、平板锁的已有特殊效果。口球按当前规则填写，没有新增假阳具款禁施法效果。RuleChangePackage见docs/equipment-design.md。
- 20260914T124657697-59256：localization73／architecture151／encyclopedia493／content380，共1097项规则断言全部通过；encyclopedia窗口79项通过，实际搜索并选中普通假阳具口球，核对0.25品质倍率及0.375／0.25／0.125三档合计，浏览不修改状态。UI SCREENSHOTS:none。
- 运行期间有同期源码变化，报告为source_changed，不作为整版冻结验收；本批只补文案与只读图鉴，未更改规则、存档、随机或发行版本，不打包。

## 2026-09-14 全卡牌双面资料与跨部位装备投影合批

- 完整83种牌型仍供图鉴、奖励和牌堆浏览；双面正文与metadata分别一次生成，普通牌型card_info重复工作4→2。按两面各自费用、原显示精度、动态数量和实例成长生成，不冻结规则注册表。装备基础资料在既有只读上下文按权威实例复用，各部位拿独立副本并设置slot。影响包、旧接口语义与结果见docs/equipment-performance.md；玩法、事件、随机、数值、支付和玩家文案保持。
- 20260914T112226775-48592：architecture151、encyclopedia399共550项通过；源码同期变化，状态source_changed。新增装备检查覆盖跨槽内容、返回值污染、复制目标、临时状态和同版本耐久修改；保留完整只读View、候选与引用检查。
- 20260914T112702588-52316：witch_character224／card_power1671／card_expansion1083／card_growth20／architecture151／encyclopedia399／content380／casting565／special_equipment332／equipment_complete448，共5273项规则全部通过。卡面新增检查覆盖三个快感值、全部注册牌型、独立两面费用、内联数值舍入、规则表即时修改和成长／般若汤实例。
- 同批窗口card_power307／encyclopedia76／casting55通过；card_growth11项只有1项旧UI前提失败：它要求候选全文默认可见，但现有ReleasePreview已改为摘要＋“效果详情”展开。更新为先核对正式headline／change，再真实点击展开核对candidate.detail，保留真实出牌、成长与牌堆浏览。后续三类未执行，未标绿。报告source_changed，失败证据保留。
- 20260914T113235836-13300只补card_growth13／special_equipment52／body_layout147／equipment_complete98，共310项窗口通过，前后源码指纹一致，状态passed。无截图。其余已通过分类沿前述报告，不将跨批结果称为全项目冻结验收；本批三个运行文件与规则门禁前备份一致。
- 五场景新旧完整投影及全部83类metadata逐项相同，状态与随机游标未改变。完整刷新首测有明显负载波动，另以相同正式候选单独计量显示生成；15个有效交替配对的新／旧比值中位为空装备0.823、29件0.886、拘束衣0.755、复合链接0.743、特殊装备0.745。这里只报告显示阶段，不冒充整帧提速。初次基线词表未加载动态注册变体的诊断无效，纠正诊断初始化后复测，无引擎／脚本错误。数据和限制见性能文档。
- README和既有性能／引用文档同步。无旧档迁移、帧率设置修改、打包或版本里程碑宣告；诊断与基线仅放忽略的build/projection-batch-20260914。

## 2026-09-14 继续优化解除预览与候选费用

- 单次只读刷新按完整参数复用解除／施法预览，输入键和返回嵌套容器隔离，临时状态绕开原缓存，退出即释放；正式执行重新计算。卡牌逐目标候选按牌面共用费用，不改资格、数值、支付、随机、正文或存档。RuleChangePackage和测量见docs/equipment-performance.md，调用及引用说明见docs/equipment-reference-audit.md。
- 20260914T110022875-18612：architecture145项通过，包含24项新增检查；由于同期源码变化，状态source_changed。新检查涵盖全部四个布尔参数的16种组合、三种方法、极近浮点基础值、嵌套辅助档案、输入／结果修改隔离、复制目标、临时状态恢复及复合／肩带／躯干连接／特殊装备连续正式出牌。
- 20260914T110309543-53012按casting、equipment、hand_assist、slip_motion、card_splash、architecture的Impact展开36类；已执行30类共9653项，前29类全部通过，core657项仅TC-ENEMY-0003失败，后6类和窗口未运行。失败仍要求离场施加中级2档，而docs/content-generation.md和正式声明已固定中级3档；更新该单项旧预期，保留真实准备、行动和最终离场检查。报告有同期源码变化，保留原失败记录。
- 20260914T110819356-47620只补core及前批未执行的equipment、links、composites、equipment_complete、prison、trader，2870项全部通过；窗口使用实际登记的card_power307／card_splash12／casting55／equipment_complete98，共472项通过，无截图。此前命令中的card_expansion没有对应窗口分类且窗口尚未启动，补测按正式注册入口选择，未新增或伪造分类。36类规则的断言至此逐批通过，但两批报告均source_changed，不合称当前整版冻结验收；本轮game.gd、card_effects.gd、architecture_cases.gd与测试前备份一致，不覆盖同期改动。
- 最终独立交替性能对照无引擎／脚本错误，0／12／29件完整显示、各次查询只读及实际提交最终状态均相同。29件候选生成中位167.816→146.757ms，完整View266.329→237.540ms，样本出牌172.458→125.554ms；本轮与前批绝对时间不可跨负载拼接，空装备样例收益不稳定。解除实际计算264→149、施法217→10、魔力费用231→175。一次被同期测试文件改写打断的诊断保留为paired-interrupted.log，其数据未用于结论。
- 同步README、AGENTS和既有两份性能／引用文档；不迁移旧档、不修改帧率偏好、不打包或宣告v0.17完成。诊断副本与计数器只在忽略的build/equipment-preview-20260914目录。

## 2026-09-14 出狱新地图普通战斗统一强怪池

- 到期出狱与击败出口守卫重建地图时，将全部普通房间的已有pool字段设为strong，实际入场继续沿原随机与连续不重复选择。精英／Boss、通关后塔底重新开始的前期弱怪保持。先选商店、退出起点选择或保存恢复不清除配置；地图仍用普通战斗图标，房间说明、出狱日志和教程新增强怪池说明，中英文同步。规则与影响边界见docs/prison-release.md。
- 20260914T101221506-56428：localization71／architecture69／content380／prison1203项通过；tower因测试种子42生成的第10—11层没有商店，索引空数组导致1个引擎错误，保留失败报告。测试改用实际有合法商店的固定种子47，补非空断言；读档比较沿既有same排除恢复时更新的版本号，提交后重新取得真实房间引用，不使用旧事务前对象。
- 20260914T101717427-56212：tower292项、prison窗口209项全部通过。覆盖两种出狱标记、第一场及连续多场强怪、不重复抽取、先选商店、保存恢复与敌人名单一致、强怪房间被篡改成弱怪时原子拒绝、正常新开反例及地图说明／图标。各分类用例通过，但运行期间另有源码变化，报告状态source_changed，不将其作为整版冻结验收；不为同期变化重复跑全量。窗口无新增截图。
- 无新增存档字段、快照修订或历史存档迁移；不打包、不发布，不宣告大版本完成。

## 2026-09-14 出狱练习按正式监狱重做

- 用户反馈旧练习空身、登记清单为空，预装工具被没收后便直接合格。到期与延期练习改用正式Guard.capture生成收押装备、链接和完整登记清单，先显示收押结果，玩家确认进入牢房后从第1回合、已服刑0／20、巡视剩余16回合开始。移除19／20回合和预装工具夹具，不预设检查结果；出口守卫练习保留正式收押装备及正常敌人血量。菜单、说明、提示和英文同步，正式监狱规则及快照结构保持；RuleChangePackage见docs/prison-release.md。
- 首轮20260914T075836722-41224：localization71、architecture69、content380通过；prison1194项仅1项失败，原因是测试错误要求出口战斗开场之后仍恰好8件，遗漏正式开场追加的2件。诊断确认收押为8件普通装备、2件特殊装备和1条链接，出口战斗为10件；修正为收押时精确核对配额、战斗后保留正式追加。首轮存在源码变化，不作冻结验收，失败记录保留。
- 最终20260914T080116670-50964：prison1196项、prison窗口208项全部通过，源码指纹稳定，状态passed。覆盖真实收押确认、非空清单、完整20回合、第16回合巡视、已登记装备缺失导致补装和延期、8个追加回合及存读档一致、10—11层起点按钮和正常守卫生命。窗口未生成截图；UI边界案例只在确认真实入狱后加速一次到期检查，完整计时另有规则及真实窗口点击覆盖。
- 不打包、不发布，不将本次练习修复视为v0.17大版本完成；旧练习进度不迁移，需从练习菜单重新开始。

## 2026-09-14 大量拘束具性能与对象接口追踪

- 已按用户补充要求沿普通件、复合根／部件、肩带、链接绳、躯干连接和特殊装备逐类追踪创建、存放、查询、候选、事务、删除与UI。9个正式练习场景目标ID唯一、查询返回权威实例、读批次结束释放索引；引用列表及动态调用边在build/equipment-performance-20260914，说明见docs/equipment-reference-audit.md。
- 29件、5张手牌、200候选的一次get_view中，equipment_at1694次但只实际筛选13次，堆叠264次但只实际计算29次；_candidate原每目标重复查3次改为1次，该路径600→200。body_sections也复用查到的对象。索引只覆盖一轮只读调用，临时state绕开，提交和清理不复用；折叠详情首次展开才创建动作树，重复开合不再重复建节点。
- 原生窗口29件样例完整View147.735→87.390ms、候选95.131→46.767ms、手胸详情刷新中位33.444→26.595ms。0／12／29件完整View与优化前逐项相同，快照只读；最终代码的无索引／有索引11次对照，29件View中位162.136→93.422ms，正式出牌7次中位107.031→54.667ms且最终状态一致。具体数据及局限见docs/equipment-performance.md，不将一次样例当成全设备帧率。
- 首轮20260914T102147204-42804：12类规则5955项，card_power1661／card_expansion1083／relics848／application71／architecture107／runner431／casting565／special_equipment332／links165／composites90全部通过；equipment154与equipment_complete448合计11项旧前提失败。错误涉及离场档位、新监狱练习开局及限制项圈固定生命周期，不是索引输出不一致。第一次更新遗漏守卫练习已清空收押报告，20260914T102549544-49100保留失败；修正为检查正式入狱配额、真实链接及守卫战阶段后，20260914T102713460-21548两类602项全部通过，源码稳定。
- 20260914T102847180-2600窗口1180项：card_power307／display122／keyboard67／special_equipment52／body_layout147／targeting83／equipment_complete96通过；localization51中3项缺英文，services255中1项旧“紧度 1档”空格断言失败。补齐现有主页原角色说明及“双腿”英文，生成词表同步；旧标签测试按当前“紧度1档”更新，未删除可见数值检查。
- 最终20260914T103645837-17220状态passed，源码前后指纹一致：localization71／architecture121／equipment154／equipment_complete448，共794项规则；localization51／services255／equipment_complete98，共404项窗口通过。新增实际解除后旧装备详情节点释放、按钮索引无脱树节点、目标唯一与权威引用检查均通过。其他已通过分类沿用上述报告，不将多批结果合称全项目验收。
- 更新AGENTS及性能／引用说明。所有本次窗口检查未指定截图，未发送真实反馈，未新增存档迁移、改变帧率偏好或打包发布；v0.17仍在开发，不宣告版本里程碑完成。性能插桩只放忽略的build目录，游戏运行时代码不带诊断计时器。
- 收尾复核发现core/game.gd、tools/build_english_catalog.py和assets/localization/legacy-en_US.json在上述稳定门禁之后又有同期修改；本批读查询索引、重复查找合并及两项英文映射仍在。794项规则与404项窗口的通过结论仅对应报告记录的源码快照，不自动覆盖这些后续改动；没有覆盖同期工作或重新宣告当前整版全绿。

## 2026-09-14 项目跟进：身体栏复用与测试入口补齐

- 跟进当前四区解缚、场景复用、魔女角色及近期监狱／卡牌／遗物变更。扫描115个运行脚本、223条字面脚本依赖，未发现循环、失效路径、core／data反向引用UI、UI直接game.state访问或至少5行的重复完整函数体；这是静态限定检查，不等于所有接口或玩法均无问题。证据在build/progress-optimization-20260914/final-structure.json。
- 身体栏显示事实未变时保留部位按钮、滚动容器和输入映射；区域滚动不再因普通刷新回到顶部。失效覆盖语言、真实计数／占用／解除标记、焦点、展开顺序和高度；回调只持有稳定部位ID并读取当前候选，不保存旧View、装备图或候选。影响边界见docs/ui-scene-refresh.md。
- 首轮20260914T073306145-19316发现witch_character_cases未登记归属；补上唯一witch_character规则分类和17个实际交互区域，并列入当前开发分类。没有复制或删除原测试，最终224项角色规则全部执行通过。20260914T073345856-35224复现按钮重建／滚动复位／等价投影重建；新增焦点断言也纠正为实际选中hover色，原样式没有改变。
- 修复后20260914T073524855-48352：当时的规则716项通过，touch18／keyboard67／body_layout136／targeting83／equipment_complete96项全部通过，共400项交互断言；display121项中只有原音乐连打失败，未记整组通过。该报告源码稳定，保留失败记录。
- 音乐定位报告20260914T073755935-43964与20260914T073905346-49500确认音源相同、播放位置正常前进，但第二次实际出牌剩余0能量，正式候选拒绝。测试夹具显式准备10能量并新增点击前正式资格断言，保留实际消耗、暂停、进度和循环检查；未改播放实现或游戏费用。20260914T074007901-7688的display122项通过，但同期其他源码变化，不能作为冻结验收。
- 最终20260914T074057043-50376状态passed、前后源码指纹一致：witch_character224／architecture69／runner429，共722项规则；display122项全部通过。五类交互沿用前述报告，不把跨批次结果合称全项目回归。所有本次窗口检查UI SCREENSHOTS:none，未发送真实反馈，未新增旧档适配。当前v0.17仍有其他在途功能，未宣告里程碑完成或触发版本提交／推送／打包。

## 2026-09-14 场景拆分与立绘按需刷新

- 主布局、顶栏、身体栏、角色立绘、敌人分组、装备立绘拆为 6 个 `.tscn`；运行代码仍消费原 View 和候选。没有合并旧 PR、改变规则、重写文案、修改版本或发布包。规则说明与影响边界见 `docs/ui-scene-refresh.md`。
- `display` 增加真实绘制计数和实例身份检查：连续三次普通界面更新保留布局、主角、敌人和装备立绘，三个立绘绘制计数均为 0；程序绘制敌人静置 12 帧重绘 0 次；没有空闲 `_process`，姿势恢复、固定立绘忽略无关变化、无关／对应素材变更和游戏快照只读均检查。
- 初轮 `20260914T031721707-1144`：display／equipment_art／hero_art 共 326 项通过、源码指纹稳定。补充固定立绘和素材变更反例后 display 为 111 项。
- 扩展检查发现复用身体栏与商店新面板的鼠标层序冲突，已在本批次修正：身体栏恢复原兄弟顺序，不再只依赖 z_index；收起时释放该栏。原有真实鼠标检查保留，未放宽断言。临时定位输出已移除。
- 修复后 `20260914T032632664-30612`：display 111、services 255、consumables 49、rewards 307 项全部通过；interface 353 项中 352 通过，唯一失败是工作区已有 17 张新增魔女卡牌缺少插图。合计 1075 项、1074 通过；不标成整组通过。此前 body_layout 97、targeting 91、installed_tools 43、home 110、route 134、equipment_art 168、hero_art 50 项通过，详见 `20260914T032010796-7892`，该报告包含已修复的界面失败，不作为全绿证据。
- 移除临时诊断打印后的连续切页收尾报告 `20260914T033053718-6868`：display／home／route／services／consumables 全部通过；interface 仍只剩上述魔女卡图缺失，合计 1012 项、1011 通过。没有放宽原交互断言，也未把已知失败标绿；运行前后源码指纹一致。
- 其他在途门禁问题保留：`20260914T031830111-47100` 的 architecture 69 项通过，runner 因 `witch_character_cases.gd` 尚未登记归属失败；`20260914T032010796-7892` 的 localization 因新增主页角色选择文字缺英文失败。没有覆盖这些在途功能或删除失败检查。
- 各次检查使用独立 APPDATA、既有检查入口和限定分类，`UI SCREENSHOTS: none`；没有新增验收截图，也未发送真实反馈。大版本完成后自动提交推送源码的规则已写入两级 AGENTS.md，本次不提前发布在途 v0.17。

## 2026-09-13 项目跟进与显示计算优化

- 跟进普通／诅咒平板锁商店付款、解除服务、免费宝箱、新卡牌显示、字体、反馈入口及上轮帧率设置；未扩展延期的存档专项。静态扫描107个运行时脚本、208条字面依赖，未发现循环、失效脚本路径、core／data反向依赖UI、UI直接访问game.state或至少5行的重复完整函数体；这是限定扫描结论。
- 本地化完整字符串匹配优先级不变。未登记且不含中文的文本不再遍历中文模板；合法动态目标只在安装包时解析一次。显示结果缓存最多512条、输入与输出合计65536字符，超预算清空重建，单条超预算不保留；语言切换、成功替换和目录重载失效，坏包拒绝保持已接受结果。无规则状态、候选或节点进入缓存。
- localization并入精确ASCII翻译、动态重复调用、替换／拒绝／切换、条目和字符预算、超长原文保持，以及重载前先预热的反例。汇流更新后的两面静态及带当前收益预览缺英文，补齐4个兼容模板与离线生成器词表，不改卡牌数值。
- 首轮`20260913T082902604-50296`规则1147项通过，6类窗口895项中发现上述缺词与两项旧测试问题；运行中源码变化。独立定位报告`20260913T083221096-52324`保留原始失败：正文79像素与区域78.6667像素仅差0.3333，整数scroll_vertical无法移动；卡组排序缺少新版开局已移除的unlock，后续取首项报错。测试改为至少1像素的有效滚动范围，仍验证所有卡牌两面／尺寸及实际长文滚轮；排序夹具显式加入unlock，原费用／名称／翻面及只读断言保留。
- 单线程同机微基准：6个固定显示字符串重复300次，1800次查询1052.046ms→3.857ms，结果逐项一致。此数值仅表示重复文字查询路径，不能解释为整局帧率提升同等倍数；记录在`build/progress-optimization-20260913/baseline-translation.json`与`optimized-translation.json`。诊断脚本与旧源码均只放入被忽略的build目录。
- 实际窗口顺序对比：保持现有局部刷新、同一字体和60帧上限，仅替换本地化实现，超量道具栏预热后开合说明30次。英文更新p50为16.451→3.972ms、p95为19.745→4.336ms；中文p50为2.496→2.569ms，未见同量级变化。两者都创建345个节点，静态背景60帧内均不重画。记录为同目录`baseline-detail.json`／`optimized-detail.json`，这是同机单轮观测。
- 修复后主工作区报告`20260913T083335405-45976`规则1149项、窗口900项断言全部通过，但仍因同期其他修改标记source_changed。为取得固定源码验收，在`build/progress-optimization-20260913/snapshot`保存测试专用副本；588个纳入清单的文件与捕获时工作区内容一致，清单见`snapshot-manifest.json`。此副本仅作验证证据，不发布、不作为开发入口，不将其反向覆盖工作区；后续新增修改须独立验证。
- 固定快照最终验收通过：`snapshot/build/checks/20260913T083750101-6964/summary.json`状态passed，前后指纹均为`394A1784D23F7D9D739CF6D8367D901FCEF6AAD448FA77BE8A30D7A34893952C`。localization／architecture／shop_release／runner／services规则1149项，localization／display／items／home／services／interface窗口900项全部通过；包含上轮帧率设置、商店与反馈的现有回归，反馈发送使用替身，没有发出真实反馈。仅为上述范围验收，不称为全项目全量或公网服务验收；未打包。
- 收尾对比：本轮本地化实现与两个修改的测试文件仍与已验证快照一致；兼容目录和生成器随后出现其他任务修改，未覆盖它们或把这些后续修改纳入本轮固定指纹结论。对比清单为`verified-change-comparison.json`与`verified-template-comparison.json`。

## 2026-09-13 游戏内问题与建议功能复测

- 用户要求测试现有反馈功能，本轮未修改运行逻辑。执行node tools/feedback-service/test.cjs，离线服务契约全部通过：固定收件人、字段与JPEG附件校验、重复编号去重、限流／额度、邮件失败和建议分类；未连接Google或发送邮件。
- architecture共69项、interface窗口共343项全部通过（含原反馈案例），报告build/checks/20260913T063342218-50812，源码指纹稳定。实际窗口验证入口、空标题阻止、隐藏窗口后截图、压缩JPEG及3张上限、关闭重开草稿、日志默认不附带／勾选后预览、无地址提示、模拟超时同编号重试、阻止重复发送、模拟成功清空草稿及全程游戏状态不变。未新增截图。
- project.godot的feedback/endpoint仍为空；网络发送及成功回执使用测试传输替身，没有公网服务或真实邮件收件验证。本次未覆盖重启进程后的草稿磁盘恢复和原生本地文件选择器，也未部署或打包；不能将上述通过解释为反馈服务已开通。

## 2026-09-13 主页左下角免费发布声明

- HomeDisclaimer使用14号中性灰，位于主页左下角，两行显示免费发布与付费购买提醒；不拦截鼠标。使用ui.home.disclaimer并同步中文、英文资源，不修改游戏状态或主页按钮。
- 更新home原标题区检查以容纳声明，验证完整正文、两行、灰色、位置不越界和鼠标穿透。architecture／localization共115项与home窗口96项全部通过；报告build/checks/20260913T062645560-52124，源码指纹稳定。无新截图或打包。

## 2026-09-13 平板锁商店付款与诅咒解除禁令

- 普通平板锁自付例外收窄至真实平板锁根的解除；普通装备、链接、复合装备及删牌均不能绕过自付限制，魔瓶仍按原费用支付。诅咒平板锁通过release_jobs禁用全部目标及两种来源，执行复核同一正式项目；宝箱免费领取保持独立。
- shop_release原文件加入普通锁自付删牌／其他拘束拒绝且状态不变、魔瓶实际支付成功、锁本身自付解除后恢复付款、诅咒锁全部项目禁用、旧候选被新佩戴诅咒锁阻断，以及魔瓶购买／删牌继续有效。商店共用说明与旧店主建议同步，避免引导购买被禁止的解除服务。
- 首轮architecture／shop_release／content／services共1057项及services窗口255项通过（build/checks/20260913T060721985-16948）。最终文案修改后相关shop_release／content／services共988项与services窗口255项通过（build/checks/20260913T060913649-46104）。两轮源码指纹稳定，无新截图或打包。

## 2026-09-13 宝箱误用商店付款限制修复

- 根因是宝箱库存领取复用了paid_candidate；商店平板锁自付限制因此阻止了0费宝箱。宝箱改为原通用候选的免费领取，不再附payment，也不检查商店付款条件；仍执行已拥有／已领取和正式提交复核。
- services原文件加入平板锁＋自身／魔瓶0余额的小刻印领取：奖励可用且无付款提示，过期提交不变，正式获得遗物且装备／余额不变，重复领取拒绝。原services窗口宝箱分支同样佩戴平板锁、置零余额后点击实际奖励按钮；原商店付款与解除服务案例保持。
- architecture／services共564项、services窗口255项全部通过；报告build/checks/20260913T060315911-53112，前后源码指纹一致。无新截图、存档迁移或打包。

## 2026-09-13 帧率上限与垂直同步选项

- DisplaySettings提供60／120／240／0（无上限），默认60；垂直同步独立布尔值，默认开启。统一应用Engine.max_fps与当前窗口的垂直同步模式，单独调整不重设窗口大小或游戏状态。两项写入原display-settings.cfg，缺失／非法值回退默认，未增加游戏存档字段。
- 主页与游戏内共用显示页。新增5条中英语义消息（现37条），说明无上限与垂直同步的关系；显示项置于内部滚动区，底部反馈速度仍可滚动到达。同期新增“问题与建议”缺完整英文译文，补齐兼容目录及生成器词表，未放宽残留中文检查。
- display窗口覆盖四档实际Engine值、垂直同步实际开关、两者独立、窗口切换保留、240及无上限的偏好恢复、非法90与损坏布尔回退、浏览不改变规则状态；localization更新为实际滚动到达最后一项再回到语言选择。沿用现有分类，不新增测试框架。
- 首轮`build/checks/20260913T055128935-42916`规则516项通过，display99项与home95项通过；旧布局断言及同期反馈入口英文缺词失败，工作区变化标记source_changed。该报告不作为最终通过证据。
- 修复后两次完整复核`20260913T055320115-52492`、`20260913T055445854-52036`均为规则516项与窗口235项全部断言通过（localization41／display99／home95）；同期其他任务持续修改工作区，两份均标记source_changed，未取得冻结版本验收，不标记稳定Verified。报告、前后备份及差异见`build/frame-settings-20260913/`；保留同期反馈／地图／商店修改，不归为本次帧率功能，不发布打包。

## 2026-09-13 地图绘画在SL和读档后保留

- 沿原main.map_drawings和归一化节点坐标保存备注；快速SL在重置界面后恢复当前画线，文件继续则读取对应存档附件。右键松开、绘画失焦与清除自动写入，重绘与查看仍不写档；新开游戏清空当前备注。
- SaveStore附件与场景起点正文共同校验、原子写入并备份；坐标按无损浮点序列化，解码检查点列与有限数值。无附件的当前格式存档为空白地图，不改游戏快照或正式回退范围。
- 原persistence案例增加附件往返、篡改校验、无效坐标和无附件边界；route窗口使用独立测试存档目录，通过原鼠标绘画、菜单快速SL、清空内存后真实磁盘继续、清除落盘、同种子新局等检查。游戏状态／随机不受绘画影响；原缩放、越界、滚动及正式旅行检查保留。
- 首轮architecture／content／persistence共982项与route窗口134项全部通过，报告build/checks/20260913T055042301-50528。复核build/checks/20260913T055137733-47844同样982项规则与134项窗口全部通过；两轮期间其他源码持续变化，均标记source_changed，不宣称冻结版本全量通过。没有新增截图或打包。

## 2026-09-13 运行结构与道具溢出性能优化

- 用户报告“超出一件道具后弹出道具栏，电脑严重卡顿”。本机成功复现正式finish_rest进入pack并自动打开抽屉，但没有复现持续卡死；初始有效诊断显示静置帧间隔约4.1ms，约240帧。不得把本轮测得的开销当作已证明的用户设备唯一根因。
- 界面显示统一最高60帧；背景静态图与飘尘分层，只有飘尘按30帧更新，静态层不再每帧重建绘制命令。正常卡牌、拖动、反馈与输入仍沿原帧流程和真实时间工作，规则回合不按帧数推进。
- 道具栏选中项、目标分组、安装菜单及使用说明共享_item_details构建入口，只重建详情与页脚；保留列表、列表滚动及主场景。抽屉整体刷新和局部刷新共用_release_candidate_controls，删除旧控件时同步恢复底层候选索引。正式命令提交后仍使用新View全量刷新，未缓存权威规则或绕过版本校验。
- 新检查在修改前稳定失败3项：静态背景持续重画、帧率无限制、切换导致列表重建；报告`build/checks/20260913T053926800-15884`，118项窗口断言。新用例复用items／display，验证真实超量1件、连续开合、只读浏览、稳定节点数／候选索引、滚动保留、单次丢弃及零回合、刚好容量允许结束、全部丢弃后的空列表；既有安装、涂抹、键盘与触屏窗口全分类保留。
- 首轮修复后规则987项通过，localization窗口被既有“每使用火球术：抽牌1。”缺少完整英文译文阻断（`20260913T054144244-6920`）。补齐该完整句的兼容译文与生成器人工词表，未放宽残留中文检查或改法术规则。
- 最终`build/checks/20260913T054424320-38760/summary.json`状态passed，源码指纹前后一致：`7040F42974446291C0577B58C4E0468D31ABA2D2ED2C59DA7F5416BC68D8A348`。localization／item_discard／consumables／architecture／runner规则1033项、localization／display／installed_tools／items／touch／keyboard／consumables窗口342项全部通过。未运行存档专项、长程normal_play、全项目或打包。
- 原始备份、前后差异、诊断脚本和日志保留在`build/runtime-optimization-20260913/`。最初未导入同期confluence.svg的诊断有解析错误，已明确排除；随后通过正式Import修复资源缓存，再做有效测量。
- 同机顺序测量（Godot 4.7.2、OpenGL、RTX 4080 Laptop，均固定60帧以隔离详情重建开销）：超量3／2件，预热后连续开合说明30次。旧／新创建节点1275→345（减少72.9%）；中文详情更新p50为7.710→4.213ms、p95为9.709→5.476ms；英文p50为24.928→17.393ms、p95为30.666→19.153ms。静态背景60帧内draw回调60→0，优化后帧间隔约16.666ms。记录为`baseline-detail.json`／`optimized-detail.json`；旧UI仅从本轮备份加载，放在被忽略的build诊断目录，不形成第二套运行实现。耗时是本机单轮观测，不承诺所有设备同幅度加速。

## 2026-09-13 跟进新增架构、接口与本地化

- 对照上次全面检查的运行时指纹，新增1个本地化模块、既有34个脚本变更。重点复核施法失败返还原魔力池、火球失败保留次数、累计准备与能力叠加、非战斗魔力恢复、完全自由降低快感、绿色小鸟动态保护线和商店递增删牌价格；存档专项继续延期。本轮没有据此修改已通过的玩法规则。
- 静态扫描106个运行时脚本、206条字面脚本依赖：未发现循环、失效脚本引用、core／data反向引用UI、UI直接读取game.state或至少5行的重复完整函数体。这是限定扫描结果，不代表项目不存在任何重复或缺陷。
- 修复兼容模板把标点／空格计作中文上下文、可误匹配任意参数串的问题；仍允许合法完整字符串精确翻译。成功加载新中文目录时清空旧兼容精确／模板／片段缓存，缺失译文不再沿用上一目录；无效中文源继续保留之前有效目录。新反例在修复前稳定复现2／46失败，报告`build/checks/20260913T044002807-35076`。
- 英文主页模式开关改用固定语义ID，语义消息32条；“唯一”同步到兼容目录与离线生成人工词表。未削弱窗口残留中文检查，复用localization现有分类，补正反例和重载边界。盘点工具通过，en_US语义消息32／32，ja_JP仍为空并回退中文。
- 初轮18个相关规则分类启用完整种子矩阵，共7917项断言通过（`20260913T043718432-39404`）；10个窗口分类共1271项，只有localization两项缺词检查失败，其余9类通过（`20260913T043741640-48316`）。两份报告都因同期修改标记source_changed，只作为问题定位证据，不能合称冻结版本通过。
- 随后规则512项及7项测试入口负向探针通过，但工作区变化（`20260913T044059652-43016`）。首次联合复核因同期新增平板锁差分图片尚未导入，窗口未执行（`20260913T044343975-44124`）；执行正式资源导入后，规则512项、窗口212项及7项负向探针全部通过（`20260913T044701170-48436`），该轮仍为source_changed，不隐去失败或源码变化状态。
- 最终稳定复核：`build/checks/20260913T044844197-46000/summary.json`状态passed，运行前后源码指纹一致。localization／architecture／runner规则512项、localization／display／home窗口212项及7项入口负向探针全部通过。此结论仅对应列出的分类，不是全项目冻结回归。
- 本轮源码修改、前后备份、运行时差异和结构扫描证据保留于`build/followup-audit-20260913/`，各轮结果索引为`check-reports.json`；同期arena／equipment_portrait和差分图片改动保留，不归为本轮本地化修复。未运行存档专项、全项目长程normal_play或发布打包，未新增截图与测试套件。

## 2026-09-13 绿色小鸟随当前快感上限封顶

- 保护线由固定99改为当前Pressure.maximum－1，原前6回合、场次延续及超额舍弃保持；共用增长、资源均分、拾取／开场、装备变化结算，先封顶再判断高潮。
- 更新原relic_revision与shared_fate案例：上限120时增长和均分封顶119，拾取时119.5降到119，降低紧度后封顶114，解除装备后封顶99；无高潮副作用，投影只读。原默认上限和第7回合到期反例保留；rewards窗口原案例改为实际动态上限119。
- 注册、资源详情、计数说明、日志及规则书同步；无新存档字段或截图。首轮绿色小鸟相关通过，仅同期诅咒平板锁存档反例失败且工作区变化。复核报告build/checks/20260913T042328598-44160：card_expansion／relics／content／pressure全部2924项及rewards窗口304项通过，无截图；运行期间其他源码仍有变化，报告标记source_changed，不作为冻结版本的全量验证。

## 2026-09-13 商店删牌初始30、每次固定＋20

- 按用户最新修订使用30／50／70／90／110……，成功付费才将shop_removals加1。Data.removal_price统一供候选、只读商店入口、选牌付款与提交日志读取；每店一次限制保持，取消、无效／过期提交和事件免费删除不累计。自身魔力／魔瓶均按同一价格，不合并余额，不使用临时魔力。
- 次数归角色存档，Boss两次继续以及带原角色出狱重建塔路均不清除，真正新游戏归零。当前快照49与Services.validate检查非负整数；无旧档迁移。教程、规则说明、README和实际价格显示同步，其他商品和装备解除费用不变。
- 复用services覆盖四次真实付费、跨塔、两种付款池、余额不足／过期／重复拒绝、当前存档往返和坏值回滚；demo_exit原继续流程覆盖两轮保留，原商店窗口核对入口30、实付删除及后续50。未新增套件或截图。
- 最终content/services/tower_progression共1012项规则检查、services窗口249项通过，源码指纹稳定；报告build/checks/20260913T040914673-45180。结构检查在此前build/checks/20260913T040753103-35352通过，后续仅按用户修订调整递增公式与对应预期。未打包。

## 2026-09-13 完全自由时每回合快感－2

- Balance.FREE_PRESSURE_RELIEF=2；Pressure.free_relief复用action_targets和CaptureBind，任何普通／复合组件、独立肩带、链接、特殊装备或捕缚都阻止自然降低。Pressure.relax只在正式结束玩家回合及移动自动滑脱后调用，扣至0，不调用增长倍率；不新增存档、计数或随机。
- 卡牌／刺激／遗物回合末效果沿原顺序完成后降低，再进入敌方行动与下回合；冰心诀可叠加。战斗、整备、休息、牢房共用，选择路线本身不降。压力详情、教程、实际日志及README同步；无新叙事场景、接口菜单或截图。
- 复用pressure现有案例验证四场次各一次、只读／拒绝无变化、眼／口／普通／特殊／复合阻止、单独捕缚、遗物固定减值叠加、1.5降至0；tower原真实移动用例验证只在完成移动时降低，pressure窗口真实结束按钮验证显示10→8及规则正文。
- 绿色小鸟到期、敏感回合末、无装备训练敌人的高潮边界与移动源旧预期同步。首次相关分类运行architecture/content/status/core/tower通过；调整旧预期后relics/curses/pressure共1603项通过，总相关规则3049项。最终pressure窗口74项通过，未新生成截图。报告依次为build/checks/20260913T035215461-19472、20260913T035400582-12200、20260913T035528688-36064，各次源码指纹稳定；只重跑失败／未运行范围，未打包。

## 2026-09-13 余火回合前置、追加8魔力与持续加伤

- 拘束面使用共用requires_successful_spell资格：当前玩家回合至少一次成功火球术才可使用；正式施法成功记录至combat.successful_spells，失败不记录，刷新次数不删除，各回合开始／场次结束清除。当前快照47保存记录，不做旧档迁移。
- 基础5魔力、0能量保持；抽1后足够余额时自动追加8魔力抽1，临时池优先，实际付款收益沿既有接口。自由面本回合火球基础伤害＋4，成功、群攻、装备目标和复放均不消费增益，回合结束与直接转入整备的新回合统一清除。
- 更新原embers_cases、mana_circuit、echo_cast和卡面文案断言；涵盖失败前置／拒绝回滚、成功后刷新、当前存档恢复、回合清理、5／12.9／13余额、临时魔力与耗魔收益、同源拒绝、重复群攻／装备半伤。卡面、状态期限、图鉴及规则说明同步，未新增套件或截图。
- card_power、card_expansion、basic_attacks、architecture、content、casting、status完整相关分类3512项通过；casting／status窗口101项通过，报告build/checks/20260913T032915145-2544。余火所在card_power窗口266项通过，报告build/checks/20260913T033058183-5812。两次均前后源码指纹一致；最初旧5魔力文案断言和复演低血量夹具失败已修正并重跑。仅相关分类检查，未打包。

## 2026-09-13 深呼吸每回合2次与基础降低20

- CALM_REDUCTION=20、CALM_USES_PER_TURN=2；嘴部原倍率对应自由20及受限16／12／8／4／0。仍耗1能量、成功获得下回合1能量。calm_uses只在实际提交后递增，所有玩家回合开始重置，场次清理重置；现有快照46保存0—2整数，恢复不会重置次数，无旧档迁移。
- 候选展示剩余次数和用完原因，实际日志记录扣减与剩余；教程、练习、规则说明同步。复用原口部矩阵、最低快感、资源／版本回滚、存档恢复、战斗／休息跨回合用例，追加第三次拒绝与正式按钮用完显示。未新增套件或截图。
- pressure／curses／relics原降压数值断言同步，口部与状态窗口验证实际点击降20或衰减8。窗口检查另同步当前快感说明已不含施法加价的事实，仍验证两种来源时机与实际魔力损失说明。
- 最后稳定规则检查relics、architecture、curses、content、status、pressure共2324项通过；status窗口57项通过（build/checks/20260913T030242558-44952）。更新旧窗口文案断言后按-RerunFailed仅复核pressure窗口，68项通过且指纹一致（build/checks/20260913T030425066-39204）。早期旧数值断言失败与并行源码变化记录保留；最终相关范围完成，不是全项目回归，未打包。
## 2026-09-13 滑精分回合损失魔力

- 触发已有滑精状态或状态尚未消退时，免除高潮即时魔力损失；后两次玩家回合开始，各扣5自身魔力并沿原计数扣减剩余回合。重复只刷新，不叠加。能量－1、下一回合后手、普通高潮即时－10和非战斗未形成状态时的流程保留。
- 魔力不足扣至0，临时魔力／魔瓶不参与，不调用耗魔收益；扣费记录前后值、实际损失和剩余回合。状态／压力说明、教程与扩展契约同步，无新存档字段或独立系统。
- 原特殊装备正例加入即时不扣、首回合－5、次回合－5断言；同分类补充只读显示、重复刷新、移除触发装备后仍存续、低魔力、到期恢复普通高潮损失。未新增套件或截图。
- content、special_equipment、status、pressure完整分类1221项通过，status窗口55项通过，前后源码指纹一致；build/checks/20260913T025109524-44652/summary.json。仅相关范围检查，未打包。
## 2026-09-13 汲取力量改为稀有

RuleChangePackage：siphon_strength稀有度由uncommon改为rare，移出UNCOMMON并加入RARE；共用定义同步卡面／图鉴分类、奖励及商店卡池，新商店价格按稀有卡40魔力。1能量、零耗魔、双面手部施法、目标筛选与效果保持。影响卡牌分类、随机池资格、商店价和玩家可见稀有度；其他数值、事务、事件／机械日志、叙事、十四交互轴及已冻结商品不变，不新增状态／随机域、不迁移存档、不打包。既有汲取力量测试更新奖励池断言并核对运行卡面及图鉴；规则书与卡牌框架已同步。另将henshin旧拒绝提示断言对齐当前“唯一”前缀，未修改其行为。验证：tools/check.ps1 -Suite card_expansion,content,rewards,services -Exhaustive -TimeoutSeconds 300 -KeepGoing，2414项断言全部通过且运行前后源码指纹一致；报告build/checks/20260913T034251769-45108/summary.json。未打包。

## 2026-09-13 暂停快感耗魔加成

RuleChangePackage：增加后台默认关闭的PRESSURE_MAGIC_SURCHARGE_ENABLED，保留magic_multiplier原公式及0.5幅度；默认调用返回1，卡牌各面／火球／牢门继续共用正式费用与付款管线，全部按基础耗魔。旧曲线保留显式后台启用参数用于进阶设计验证，不增加玩家开关、候选类型、随机域或存档字段。快感详情移除耗魔倍率句，魔力转换说明移除当前无效的倍率例外文字，规则书与卡牌框架同步；未来方案收录docs/advanced-design-ideas.md。十四交互轴中资源费用、费用门槛、按实际耗魔触发的累计数及对应卡面／预览／机械扣费受影响；快感上限与增长、施法概率、身体资格、能量、伤害、失败返还比例、临时魔力抵扣、材料层级、姿态和地图不变。机械付款日志仍读真实支出，无新增叙事。不做旧档迁移或打包。

测试覆盖默认关闭的比例边界／不同上限、所有卡牌双面费用、只读不变、旧版本回滚、高快感下刚好足额可用并实际支付、原临时池分摊、成功率仍下降、失败半额返还、火球及牢门同入口；原曲线锚点与单调性测试改为显式启用后台参数。卡面旧“高快感费用大于10”断言更新为等于基础10，保留图鉴一致与正文不重复要求。窗口检查高快感耗魔徽章和火球候选；火球返还提示断言与当前统一全文对齐，保留并行任务新增的次数说明。

稳定验证：`tools/check.ps1 -Suite pressure,casting,card_expansion,card_power,content -UI -UISuite casting,pressure -Screenshots ui-card-mana-badges.png -TimeoutSeconds 300 -KeepGoing`，3719项规则及113项窗口断言通过，报告`build/checks/20260913T031831473-32704/summary.json`；独立完整`-Suite prison`另741项通过，报告`build/checks/20260913T031831499-44132/summary.json`。两个报告运行前后及彼此源码指纹均一致，合计4460项规则和113项窗口断言。人工检查截图确认快感75时魔力涌流徽章为−5、火球术为10魔力，成功率仍为25%。此前通过断言但source_changed的轮次不计稳定证据，未打包。

## 2026-09-13 诅咒平板锁定制开局

RuleChangePackage：本地显示偏好新增cursed_plate_start布尔值，默认关闭并由贞操锁池／固定立绘资格约束；正式Game新局只在第0层初始化读取，沿RelicEffects.gain执行真实拾取。departure保存定制标记和前三类冻结选项，不生成第4类；候选、快照校验与只读奖励窗口同步，三项居中，首页直接显示不可勾选原因。日志复用遗物拾取，开局摘要明确替换结果；不新增叙事或修改遗物固有效果。影响新局状态、遗物／装备拾取、候选集合、冻结随机结果、偏好和当前快照、UI及摘要；十四交互轴中开局阶段与初始遗物来源受影响，数值公式、身体／层级／锁／材料、姿势、伤害、战斗回合、地图与后续奖励规则保持。无旧档迁移，不打包。

覆盖默认／池关闭／固定立绘、勾选清除及偏好持久化、非法偏好、正式新局与练习隔离、3项候选与直接出发、实际遗物及首次战斗能量、无效第4项原子拒绝、快照恢复不重复拾取、损坏快照回滚、真实鼠标操作与继续游戏沿原场景SL。相关遗物旧测试原先错误要求商店完全隐藏诅咒锁，现按已有实现断言显示专属钥匙限制且不可解除；未改商店行为。首次新增SL测试已修正为遵循原版本递增与场景起点恢复，未更改SL规则。

稳定验证：`tools/check.ps1 -Suite tower,relics -UI -UISuite home,display -Exhaustive -Screenshots ui-home-custom-start.png,ui-departure-custom-start.png -TimeoutSeconds 300`，3082项规则断言、172项窗口断言全部通过，包含完整塔图201种子；运行前后源码指纹一致。报告：`build/checks/20260912T163316760-20352/summary.json`。人工查看`build/ui-home-custom-start.png`与`build/ui-departure-custom-start.png`，确认勾选项在池开关下方且未被裁切、三项奖励居中并保留直接出发。此前两轮断言全通过但并行修改导致source_changed，不作为稳定证据；另一轮同样处于移动源码，出现无关音乐暂停时序断言失败，最终完整所选分类已重跑通过。未打包。

## 2026-09-13 漂浮锁离场附加与首页概率下限

规则沿EnemyPlans公开意图、Application安装、通用打断与final离场，不新增玩家命令或存档字段。漂浮锁定义固定中级2档负数平板锁离场来源；开启开关且无上锁目标后执行，全场饱和不能提前跳过该次动作，即使无法安装也执行落空与离场。关闭时原规则不变；被击败取消附加。首页及独立显示偏好限制5%～100%，旧0%偏好提升到5%，局内既有保存格式不变。

覆盖两端概率固定装备、实际紧度／默认锁态、打断与恢复、已有同级／高级锁拒绝重复或降级、击败取消、关闭开关原案例、首页真实按钮到5%禁用向下但可向上、偏好加载与上下界。图鉴、练习提示、首页说明与敌人文档同步；机械日志复用正式安装／落空／离场，未增加叙事。验证：`tools/check.ps1 -Suite enemies,battle_saturation,content,intent,core -UI -UISuite home,display,encyclopedia -KeepGoing`，2454项规则和217项窗口断言全部通过，源码指纹一致；报告`build/checks/20260912T160430545-36736/summary.json`。未打包。

## 2026-09-13 六缚踢击后意图说明

RuleChangePackage：仅修改IntentView的已行动和新登场说明，复用真实空意图／出场回合及可见性投影。候选、数值、事务、敌人循环、打断、先后手、机械日志、叙事、随机域与存档结构不变；十四交互轴无规则改动。不提前生成下一回合意图，不做旧档迁移或打包。changedUiAndLogs为悬浮说明；机械日志／叙事N/A，因为没有新增行动或结算。

复现正式并腿踢击→倒地→结束回合→后手：原意图在新回合实际执行，新增装备及玩弄牌，随后三回合继续推进并获得收束。另验证打断状态快照往返结果一致；先手打断、真正空闲与眼罩隐藏沿现有分类回归。此前把饱和逮捕基线失败推测为同源并无充分证据，本批未修改该逻辑；后续完整敌人分类已通过。

窗口案例真实点击踢击和结束回合，再悬停六缚意图，确认显示已行动、查询不改变状态；眼罩仍隐藏意图。最终检查：`tools/check.ps1 -Suite enemies,intent -UI -UISuite intent,enemies`，规则1574项、窗口254项通过，前后源码指纹一致；报告`build/checks/20260912T155057624-43140/summary.json`。前一轮`20260912T154742997-36592`虽断言全过但发生工作区源码变化，不作为稳定结果。

## 2026-09-13 全面检查、测试维护与颈肩计数

- 全目录静态检查覆盖105个运行脚本、204条字面量脚本依赖；未发现依赖环、core/data反向引用UI、UI直接访问game.state、缺失字面量脚本或至少5行的重复完整函数体。资源路径与JSON另行核对。这是静态检查范围，不等于所有运行交互已穷举。原件、差异与指纹在`build/full-audit-20260913/`；差异可能含其他任务同文件的并行改动，以本节列出的修改归属为准。
- 修复批量施加清空调用方protected_ids的问题；先复现4项失败，再沿原批次保留已有保护并追加本批物件，保留整状态／随机／输入不变断言。删除无调用方的旧sensitivity_multiplier；道具按钮合并到_compact_action，安装／取回的实际操作部位恢复就近显示，名称复用正式候选。内容目录阶段选项／结果中出现的错误缩进也已修正，保留并行新增的资格规则；内容目录12份和模板5份校验通过。
- 过期测试按正式第0层选择、整备结束时清理、火球首发费用、同部位波及、复合目标和套娃二级奖励修订。services删除与rewards重复的休息窗口检查，罕见选牌／返回不重抽／实际领取统一并入rewards。安装窗口断言读取正式候选名称，停止要求已删除的低／中／高简称；魔瓶动画通过正式整备结束触发遗物回魔。
- 调度入口拒绝`-UIOnly -Suite`及未启用窗口时传`-UISuite`，新增负向自检证明不会用默认分类或遗漏窗口代替指定范围。稳定runner报告`build/checks/20260912T150545446-43840/summary.json`含383项及原超时／运行时错误／停止与继续检查和两项新参数误用检查；它是该时点源码的结果。
- 长流程试玩仍从真实Game开局，只消费只读候选；可见战斗达到30回合后使用正式投降，随后继续牢房路线。视觉受阻时沿正式方向候选探索，只记忆已提交方向，发现通风口后留下完成正式踢击；不读取隐藏坐标、不降低敌人数值、不注入资源。窗口驱动同步地图入口、右键招式、手牌目标及两次投降确认。固定种子与严格终点／步数上限保留；检查点只写到build供失败诊断，策略不读取这些文件。
- 用户截图“颈部12”来自颈部与肩部合并分组：数字是去重后的物理目标数，左右肩带各计一条，实际并非颈部容量。统一显示“颈肩”，沿panel_groups读取名称，保留neck稳定ID及展开后的颈部／肩部分区。复现大臂两个位置各3件装备产生12条肩带，同时颈部占用0、整体状态合法；规则shoulder完整分类131项稳定通过：`build/checks/20260912T153855075-44716/summary.json`。不改变肩带规则、容量、数值、事件或存档。
- 全面回归范围为48个规则分类、43个窗口分类，包含normal_play与baseline，排除用户明确延期的规则persistence及窗口persistence/home_persistence。修复后47个非长流程规则分类曾17400项全部通过，含完整随机种子和调度负向检查，但源码在运行期间改变，报告`20260912T151609697-42912`为source_changed，不能计作最终稳定全量。窗口也曾执行到normal_play前的33个分类，其中installed_tools旧名称断言失败，其他32类通过；报告`20260912T151609698-22104`中止并受源码变化影响，不计全量通过。
- 01:34—01:35另一个任务开始接入诅咒平板锁，新的47类检查`20260912T153631447-17092`发现该开发中功能的henshin保持、Boss钥匙触发及整件清除断言失败；本次未覆盖或撤销其并行实现。颈肩复现夹具首轮误将第二组放在不会附肩带的小臂，已改成规则要求的大臂上侧并完成上述131项回归，未改规则来迁就测试。运行期间源码变更、主动中止及未到达终点的试玩一律不当作通过。
- `profile-checkpoint.log`最初错误地将整数形式的浮点字段转换为整数，不能作为规则证据；`profile-inspect.log`读取不存在字段的调试失败也排除。修正读取方式后的诊断仅用于定位旧试玩策略拒绝合法盲行的问题，不替代完整分类验证。未进行旧档适配、存档专项或打包。

补充验证与并行新增跟进：

- 颈肩改名及教程说明完成后，architecture/content/shoulder三个完整分类580项稳定通过：`build/checks/20260912T154050916-46304/summary.json`。窗口shoulder20项（含截图）、installed_tools43项在`20260912T154112649-43416`中通过；已人工核对`build/ui-113-shoulder-pair.png`，侧栏与详情同名，左右肩带各一张，脖颈空位单列。整轮窗口结论仍须读取报告的源码稳定标记。
- 正常窗口试玩997项通过，真实到达警戒1的监狱地图起点，报告`20260912T153236962-38356`。期间其他功能及本次颈肩文字改动触发source_changed，不将这份报告列为当前源码的稳定完整回归，也不以该简单策略推断胜率。
- 新增专属遗物后，旧六缚饱和夹具把全部高级设计都装入，误包含relic_only根但没有对应遗物；改为排除专属设计，保留正式容量耗尽和收押断言。全遗物窗口补齐正式领取专属遗物附带装备，避免以缺件状态陈列；同批奖励规则夹具已由并行任务同步。本轮47类报告`20260912T153631447-17092`共17429项、7项失败：3项来自开发中的专属遗物，2项来自已纠正的肩带夹具，另2项来自上述新增设计／全遗物夹具。报告含完整16／24／201种子，因期间源码变化保持source_changed，不擦除原始失败。

收尾记录：

- 正常规则试玩三个种子42／20260906／7分别用228／307／282次正式提交到达监狱地图起点，共833项通过，报告`20260912T153207818-7176`；完整轨迹在`build/normal-play.json`。它与997项正常窗口试玩均为source_changed，保留行为证据但不当作当前稳定全量。
- 更新夹具后的relics/rewards/enemies完整分类5037项通过，含16／24种子，报告`20260912T154422816-43224`；运行期间并行意图改动使该报告仍为source_changed。
- 42个非正常试玩窗口分类全部执行完，共3633项，仅intent的“本回合已行动”悬停说明断言失败，其余41类通过，报告`20260912T154112649-43416`。该进程01:41启动，而意图投影及对应测试01:47仍有并行更新，整轮保持source_changed；未把此失败隐藏或算成通过。
- 新进程architecture/shoulder/runner/intent四个完整规则分类723项稳定通过，附16／16种子和7项调度负向检查：`build/checks/20260912T155225294-41632/summary.json`。截至该报告，已执行全部48个非延期规则分类、43个非延期窗口分类；这是执行范围，不是同一源码下的全项目绿色结论。逐轮状态、失败与最后一次分类结果见`build/full-audit-20260913/report-index.json`，不得跨指纹相加。
- 最后使用新窗口复核installed_tools/shoulder/intent，110项稳定通过：`build/checks/20260912T155622192-42124/summary.json`，前后指纹均为`F8F3061AC65A2CE6C2C15524F1AF54C55E20373C8D924D08DAAB33791E1FF82F`。意图的已行动说明在新进程中通过；保留实际弹窗文本的失败诊断，不改预期文案、不降低断言。颈肩名称、实际肩带目标／拖动费用及统一道具安装入口均通过。本轮结束时测试进程已退出，未干预用户正在运行的游戏；存档专项和打包仍未执行。

## 2026-09-13 新增架构与接口检查

- 对照上次build/progress-audit-20260912/final-runtime.json，初始标出35个运行脚本新增／变化，重点检查第0层选择、卡牌自由态计数与首发费用、般若汤、音乐事件、图鉴衍生牌、奖励排布和新装备生成。初始静态扫描覆盖105个运行脚本、204条字面量脚本依赖，未发现依赖环、core/data反向引用UI、UI直接访问game.state、缺失字面量加载资源或至少5个有效代码行的相同完整函数体。这不等于所有动态接口与交互组合无缺陷。
- 修复自动升级的三个接口问题。①Game._install_special原来逐个删除后再判断依附关系，主体先删时会留下旧附属件；现在按删除前状态冻结完整移除集合。②Application自动安装分支未回填removed，现按实际物理ID差集回填，敌人／巡视沿原结果显示真实数量，巡视说明包含组件。③候选及冻结单件提交原来不检查自动替换碰到的protected_ids；整组Replacement预演的直接安装路径也能绕过保护。单件沿共同资格查询拒绝，整组在共享预演返回边界复核真实removed/lost_links，失败恢复原状态与反馈记录器。未新增玩家命令或第二套规则；沿原资格、容量、费用、版本与随机域。
- 在现有special_equipment分类补充存储正反顺序、主体与组件保护、无关对象保持、准确移除回执、整组跨家族自动替换回滚。先复现再修复：孤立组件报告build/checks/20260912T142023827-7004（264项中2项失败）；单件保护及回执报告20260912T142315469-12720（274项中10项失败）；整组保护报告20260912T142713562-45780（275项中1项失败）。保留失败日志，不删除边界断言。
- 同步两处过期测试：赠牌效果比较排除已明确的reward_excluded/encyclopedia_hidden标记，并单独验证图鉴隐藏；真实拖动按首发火球1能量、次发0能量走完伤害、付款、击杀与命中区移除。首轮10个规则分类4935项仅赠牌比较失败，首轮四个窗口分类517项仅interface的5项连带断言失败；日志20260912T141826087-14208和20260912T141826086-5400。没有更改实际费用或恢复旧玩法。
- 阶段性稳定结果：修复孤立组件与旧测试后，relics/replacement/application/architecture/runner/special_equipment/status/pressure/enemies共5886项通过（20260912T142042185-42792）；special_equipment/status/interface窗口421项通过（20260912T142042185-41052）。tower完整分类2303项、地图201/201种子通过（20260912T142529417-9032）。图鉴、显示与首页窗口在首轮也各自通过，包括开局选择与音乐测试；这些是各自当时源码的结果。
- 最终修复后的关联长流程5898项断言全部通过，包含replacement/application/architecture/runner/special_equipment/status/prison/pressure/enemies，enemy_cycle16/16、enemy_pool24/24；但并行立绘资源在运行中更新，报告状态source_changed，不能计为稳定整轮通过（20260912T142737772-15804）。上一轮5897项同样受并行改动影响（20260912T142343296-45900）。没有把这两轮合并成全项目通过。
- 最终稳定收尾：replacement/application/architecture/runner/special_equipment五个完整分类907项通过，前后源码指纹一致，使用Exhaustive并保留16/16定向种子。报告build/checks/20260912T143049615-11792/summary.json。未运行all、normal_play或baseline；不进行存档专项或旧档适配，不打包，不新增截图。
- 本轮修改4个运行脚本、3个测试脚本，并同步AGENTS、README和装备设计文档。修改前原件、差异、各轮报告索引与运行时指纹在build/progress-audit-20260913/。并行新增的立绘投影／渲染／资源仅记录变化，未作为本轮最终稳定窗口验收；pending-art-review.json列明后续需要另行跟进的部分。最终运行时指纹用于后续对照，不代表这些并行视觉改动已全部验收。

## 2026-09-13 魔力松缚与术式解锁稀有度互换

- magic_slip改为basic，unlock改为uncommon；UNCOMMON中替换对应卡牌，奖励／商店与卡面／图鉴沿现有规则读取同一稀有度。初始卡组、动作、费用和施法条件未修改。卡牌框架分类表同步，扩展牌说明不再误称全部都是奖励牌。
- content、rewards完整相关分类946项通过，源码指纹一致：build/checks/20260912T140437930-32932/summary.json。未新增测试、截图或打包。
## 2026-09-12 马眼棒高潮滑脱

- 三档马眼棒共享6点基础值，每次高潮以当前紧度与装备等级抵扣后直接削减耐久；连续高潮逐次重算，归零解除。马眼全包杯及其他特殊装备不受影响。装备详情显示公式和当前值，图鉴显示通用公式，机械日志保存完整结算事实。
- 首轮encyclopedia/content分别361／372项通过；special_equipment测试误用了已改版的高潮练习旧手牌前提而中止，记录build/checks/20260912T121103099-43960/summary.json，不计整轮通过。修正为正式付费体术触发后，special_equipment/pressure规则481项通过：build/checks/20260912T121212010-13552/check-rules.log。
- 首轮窗口发现special_equipment两条旧断言仍假定同部位波及不会伤及其他装备；按现行正式波及候选保留并校验波及值，没有放宽目标检查。最终special_equipment/pressure窗口115项通过且源码指纹稳定：build/checks/20260912T121518959-44796/summary.json。此前同批encyclopedia窗口75项已通过。未运行无关分类、未打包。

## 2026-09-12 特殊装备图鉴耐久文案

- 特殊装备详情删除“初始耐久”，保留位置与最大耐久；仅修改data/encyclopedia.gd显示模板，未改初始耐久计算或装备数值。运行时data/core/ui已无该文案。
- encyclopedia分类执行358项，357项通过；既有“duplicate special variants omitted from public entries”卡牌列表数量断言失败，位置为tests/encyclopedia_cases.gd:33，与本次特殊装备文本模板不共用分支。本批不修改卡牌列表或其测试，不声称完整门禁通过。源码指纹一致，记录build/checks/20260912T120234521-41972/summary.json。无新增测试、截图或打包。
## 2026-09-12 休息奖励统一排布

- 三项奖励共用奖励卡行；罕见卡选择、随机稀有直接领取与魔瓶补充各自绑定原候选。统一名称／费用／操作位置，首页合并重复跳过入口，保留选牌子页返回与跳过。原数量、费用、随机、冻结及资源结算不变。
- services/rewards完整规则1038项、rewards窗口291项通过：build/checks/20260912T101725047-41544/summary.json。新窗口检查等尺寸／等间距／视口边界、花费与不足原因、三个直接入口真实结算；既有罕见卡四选一与返回／跳过覆盖继续通过。人工检查build/ui-rest-rewards.png，无遮挡或分散按钮。未打包。

## 2026-09-12 图鉴衍生牌合页

- 卡面与实时奖励提示补全般若汤后续卡名。新增双面静态正文、实时奖励正文与实际卡面完整名称断言；encyclopedia规则357项、窗口75项通过：build/checks/20260912T100627188-6132/summary.json。生成与费用不变，未打包。

- 后续修正：其二／其三／其四／好汤也隐藏独立条目，般若汤只保留其一列表入口，其一详情仍完整展示全部衍生牌。搜索系列或任一后续名称均只返回其一。完整encyclopedia规则354项、窗口72项通过：build/checks/20260912T100453696-42264/summary.json；未打包。

- 四种特殊重复版本隐藏独立条目，原版详情展示关联衍生牌；般若汤沿正式奖励配置展示后续生成链。搜索包含衍生名称与效果，但不恢复重复列表行。共用正式卡面资料，各自翻面，自动换行并滚动查看。
- 完整encyclopedia规则358项、窗口67项通过，源码前后指纹一致：build/checks/20260912T095811173-39204/summary.json。覆盖条目去重、生成顺序、检索、独立翻面、详情宽度、末张滚动可达、注册表及游戏状态不变。仅相关分类，未打包。

## 2026-09-12 葫芦酒壶与般若汤

- 新增Boss池遗物gourd_flask与永久固有其一，阶段2—4、好汤和三种赠牌沿临时卡牌生命周期；等级／属性／首次体术强化沿战斗增益，在本场整备结束统一清除。使用同等级继续升级，低等级或满级只生成好汤；复放不重复领取。饮用费用按嘴部等级＋紧度取最高，上身分数严密度也要求坐／躺。规则范围见hannya-change.md。
- Hannya规则用例唯一归属card_expansion；实际窗口用例归card_power。覆盖Boss真实领取、开场固有、两种首次强化、完整四级、同级／低级／满级、只读与版本回滚、口部九种组合、姿势、耗费不足、封顶回魔、10张手牌、衍生费用与原条件、虚无优先、当场快照恢复、奖励→整备保持及结束清理。状态显示单一等级与累计属性；低级实卡正文按当前结果投影。新增六张SVG并复用原赠牌画面，不增加截图或发布包。
- 首轮相关完整分类card_power/card_expansion/relics/basic_attacks/architecture/content/runner/casting/status/rewards带Exhaustive共4839项通过；当时源码稳定。该轮UI因新增测试读取错字段中断，整轮不计通过：build/checks/20260912T092107280-15024/summary.json。随后修正测试字段，保留失败日志。
- UI复核发现两处实际显示问题：通用静态效果覆盖般若汤低级实卡结果，及完美henshin长标题与耗魔徽章挤占／换行后裁切。实卡metadata统一读取动态结果；长标题以两行占用原标题行高度，完整文字与徽章互不遮挡。增加实际低级手牌和完整标题的断言，未降低字体下限或删除失败检查。
- rewards中欧内的手三个旧预期仍按魔术手旧闪避效果，已按现行“下2次手部体术忽略拘束”更新；先真实发动两次肘击耗尽效果，再打普通副本，继续验证赠牌弃置、普通牌消耗及付款。没有修改魔术手规则或删除覆盖。
- 最终interface315项、rewards265项，共580项真实窗口检查通过，前后源码指纹一致：build/checks/20260912T094059278-34180/summary.json。
- 曾有一轮出牌窗口断言全部通过但工作区指纹变化（build/checks/20260912T093551475-32268），不作为稳定验收。最终另做card_expansion/status/runner共1583项，card_power窗口262项，全部通过且前后源码指纹一致：build/checks/20260912T094404138-40836/summary.json。以上各轮不相加称为同一源码全项目all通过；未开展延期存档专项、长流程或打包。

## 2026-09-12 新增架构、接口与过期测试跟进

- 对照上次build/new-progress-audit/final-runtime.json，标出25个新增／改动运行脚本。重点沿战斗→奖励→整备→离开、跨战资源保留、事件战与监狱出口、批量消耗手牌、新增遗物、套娃二级领取、卡组排序和拖动提示检查唯一规则入口、冻结选择及只读投影。全100个运行脚本的198条字面量脚本依赖扫描未发现环、core/data反向引用UI、UI直接访问game.state、缺失字面量加载资源或至少5个有效代码行的完整函数体重复；该静态结果不代表所有动态路径无缺陷。
- 修正1处实际说明遗漏：地图休息房仍写“扣4回合选一张稀有卡”。现从Balance读取全部费用与数量，明确随机稀有卡、冻结罕见卡选择、魔瓶补充及跳过；保留挂钩、自由面限制和不自然回魔。加入services现有分类的完整选项与只读状态检查。Game._start_rest与GameView.reward_panel移除旧双稀有度遗留的两个单元素循环；保留候选、随机顺序和实际结算。没有另造规则／奖励接口。
- 修正interface中8项旧失败的前提，不删除行为：魔术手赠牌明确共用原图，其他图片继续校验独立与非空；紧缚爱好沿既有0.58图高，其余保持2/3，继续检查双面双尺寸、文字边界及图片比例。长文滚动改用仅显示的明确长文夹具，保留真实滚轮、插图尺寸不变与翻面归零；全卡实际正文仍先逐个检查。教程资源规则可提及并搜索乌龟壳，仍禁止重新生成遗物图鉴。拖动用例按30血敌人的存活→最后一击→移除命中区走完，不伪造击杀。
- 两项塔顶路线旧预期改为休息离开不回魔、胜利暂不回魔，继续验证整备结束回魔一次及整理道具不重复。施法用例给足双面正式费用后单独检查身体资格，保留原失败率；临时魔力用例验证致命法术50→40只生成付款反馈、领奖进入整备保持40、真正离开整备40→20才生成保留上限反馈。版本拒绝、正式提交和其他资源边界断言均保留。
- 首轮12个完整规则分类执行5705项，2项旧路线预期失败，其余通过；源码稳定。报告build/checks/20260911T141301728-56096/summary.json。原interface306项复现8项失败，源码稳定：build/checks/20260911T141311826-48816/summary.json。
- 修正后architecture／runner／services／tower_progression完整分类1035项通过，源码稳定：build/checks/20260911T141816179-45700/summary.json。interface309项、rewards261项真实窗口断言全部通过，合计570项，源码稳定：build/checks/20260911T141826375-56160/summary.json。
- 补查basic_attacks／event_flow／encyclopedia／content／casting／status／events／prison，共2837项；仅casting的上述3项旧前提失败，其余分类通过，源码稳定：build/checks/20260911T142017882-57940/summary.json。修正后完整casting358项与runner371项（合计729项）通过，源码稳定：build/checks/20260911T142342050-33888/summary.json。重复运行的runner不另算独立行为覆盖。
- 初次通过分类与修正后的通过分类来自不同源码指纹，不能相加称为同一版本的全项目all通过。本轮是新增范围及受影响完整分类检查，未运行normal_play／baseline／all，不开展存档专项或旧档适配，不打包，也未改变现有UI版式或另拍截图。结果索引、差异、修改前原件和最终运行时指纹保存在build/progress-audit-20260912/。

## 2026-09-11 虾滑

- 新增罕见shrimp_paste，沿pickup_mana_max=12与pickup_mana=12：先提高上限再恢复，加入通用奖励／商店池；图鉴与简洁SVG图标同步，无新规则接口或存档字段，不打包。
- 将原茄子拾取用例参数化，与虾滑共用，覆盖实际奖励领取、未满／满魔力、只读投影、重复／旧版本拒绝、后续阶段不重复。未复制测试框架或增加截图。
- 初次检查遇到并行整备生命周期修订；同步两处旧测试：小宝石只检查奖励进入整备后的日志，避免误读先前战斗开场；资源反馈改验致命火球先扣魔力、整备结束再由遗物恢复，来源与清理断言仍保留。早期失败日志保留在build/checks/20260911T131335107-55980及20260911T131516882-49484。
- 最终完整相关分类relics、encyclopedia、content、rewards共2006项通过，encyclopedia窗口50项通过；前后源码指纹一致。记录：build/checks/20260911T131641186-57936/summary.json。仅相关范围检查，非全项目回归。
## 2026-09-11 新增进度与接口复查（测试细则整理之后）

- 本轮对照最新规则与实现检查命运同担、身轻如燕／闪避、魔术手及赠牌、借力打力、呼吸调控、控火条件、新遗物、术式解锁0能量、休息两组奖励、施加补空、法阵／四小怪、六缚逮捕和固定人物立绘。检查期间另有任务更新控火夹具与六缚实现，以实际加载源码和检查指纹区分结果，不把先前通过数合并成当前全项目结论。
- 结构扫描覆盖97个运行脚本、194条字面量脚本依赖：未发现循环、core/data反向引用ui、UI直接引用game.state、缺失的字面量加载资源或至少5个有效代码行的完整函数体重复。重点沿卡牌费用／效果／多段顺延、Application合法查询与实际闪避、Pressure增长与直接均分的分离、冻结奖励领取及显示偏好检查共用接口，未确认需要本轮修改的新增接口重复或绕过规则问题。这不是所有动态路径与交互组合的无缺陷证明。
- 结构结果、运行结果索引及运行时前后指纹在build/new-progress-audit/。初次扫描后有core/enemy_plans.gd、core/snapshot.gd、data/encyclopedia.gd发生变化；卡牌相关文件在初次扫描之前也有更新。没有覆盖其他任务的实现，没有修改游戏数值、存档迁移或发布包。
- 首轮11个完整规则分类带Exhaustive执行6381条，其中1条控火夹具失败：保留微量耐久后未先执行正式清理，却期望手部已经自由。检查期间原测试已经补上_cleanup并重建后续独立夹具，本轮未修改或删除这条断言。首轮源码也发生变动，整体失败；日志build/checks/20260911T114512846-42396/。
- 经-RerunFailed重跑原范围，card_expansion、basic_attacks、replacement、application、architecture、installation_priority、runner、services、rewards、pressure、enemies全部完成，6428条断言无失败；enemy_cycle为16／16、enemy_pool为24／24。运行期间enemy_ui_cases继续变化，仍被SOURCE CHANGED判为无效，不算稳定验收：build/checks/20260911T114800409-5472/。本轮不继续重复这一大组合。
- 独立card_power、relics分类1444条通过，17.15秒、退出0且指纹一致：build/checks/20260911T114651093-37520/。该结果属于当时源码范围，不覆盖随后六缚修改。
- card_splash、prison共885条断言无失败，但遇运行时文件变化，整轮无效：build/checks/20260911T114722452-47212/。display、casting、home、prison、rewards窗口共484条断言无失败，也因源码变化未取得稳定门禁：build/checks/20260911T114557792-27976/。此前casting悬停波动本轮未复现，不据此宣布已修复其偶发问题。
- 最终稳定补验：card_expansion、architecture、runner、prison四个完整分类1819条通过，99.75秒、退出0、无引擎错误、前后源码指纹一致，补齐此前术式解锁与牢房检查没有固定版本结果的缺口：build/checks/20260911T115039669-46532/。card_power窗口独立226条通过，88.43秒、退出0且指纹一致，包含魔术手、借力打力、呼吸调控和更新后的控火条件：build/checks/20260911T114944981-36808/。
- 结论：所审新增接口暂未发现需要修改的确定问题，最终上述规则与卡牌窗口范围取得稳定结果；大组合与其他窗口的源码一致性验收仍未闭合，不能称全项目通过。存档专项、完整正常游玩、Android真机不在本轮范围。未新增截图、不打包。

## 2026-09-11 命运同担

- shared_fate：罕见技能0费、双面同效，直接均分自身魔力与快感并保留小数；临时魔力／魔瓶不参与，不视为增长倍率或施法支付。独立应用资源上限与既有过载；Pressure只提取原过载处理供两种入口共用，无新存档状态。
- data/card_rules.gd、balance.gd、卡面SVG及图鉴／奖励共用注册；既有self牌候选显示当前均分值。结构化日志记录前值、平均值及封顶结果。
- shared_fate_cases仅归card_expansion：覆盖双面、奇数和／零值、零能量、身体受限、只读／旧版本回滚、正常弃置、敏感／大理石直接设值、耗魔收益不触发、魔力上限、快感阈值及绿色小鸟。未增加截图或打包。
- 初次10类规则4159项及界面90项断言通过，但其他任务修改reward_ui_cases导致源码指纹变化，该轮不记稳定门禁（build/checks/20260911T113731785-43920）。
- 稳定源码复核：card_power、card_expansion、relics、architecture、curses、encyclopedia、content、runner、rewards、pressure共4159项通过；encyclopedia窗口50项通过。casting窗口的两条既有悬停检查本轮失败，完整保留失败日志（build/checks/20260911T114005305-47816）。未改代码，仅通过-RerunFailed重跑casting，40项通过、指纹一致（build/checks/20260911T114202156-31716）。这是相关范围检查，不是全项目回归；悬停检查存在一次未复现波动。
## 2026-09-11 法阵仪式3与四小怪去重

- 看着不妙的魔法阵与继承其计划的小型魔法阵均改为仪式3，正常施加数量4、7、10……；启动、打断、每自身回合末增长、加固回退、先后手及死亡流程保持。图鉴数量从敌人配置生成，练习说明与敌人设定文档同步。
- four_weak配方开启unique_weak_types，四只均为强度1且按怪物类型去重；同种不同等级也不能重复。统一弱怪抽取先确认剩余强度能否补齐再抽取，必要时复用宽松资格回退；没有足够种类时不重复补位、不输出半组、不推进随机。其他配方与普通弱怪战维持原重复规则。名单仍在入场时冻结，当前快照拒绝四小怪名单中的同种重复。
- 更新实际法阵逐回合施加／加固与打断案例；强怪穷举逐份检查种类唯一、总强度4、组合历史不重复、查询不重抽；保留普通弱战允许同种重复的案例。新增四种恰好可用和仅三种不足的边界，以及同强度重复名单的原子恢复拒绝。
- 完整architecture、encyclopedia、content、services、enemies、tower分类通过6814项，前后源码指纹一致：build/checks/20260911T110238152-23692/，92.53秒。enemy_cycle穷举16／16、enemy_pool穷举24／24、tower_graph穷举201／201。
- 首轮窗口encyclopedia完整49项通过，enemies唯一失败是无人机拖牌旧断言仍按基础挣脱5计算30→20；按当前基础6、捕缚倍率2更新为30→18，保留实际拖牌与付费记录检查，没有更改无人机规则。首轮：build/checks/20260911T110522400-37928/。仅重跑完整enemies窗口后200项通过、指纹一致：build/checks/20260911T110827885-42044/，81.94秒。法阵实际施加数量和仪式状态显示均通过。
- 无布局或素材变动，不生成截图；不适配旧档、不运行全项目、不打包。

## 2026-09-11 休息稀有卡恢复三选一、消耗5回合

- 按最新要求，稀有卡恢复三选一，花5回合、剩1回合；罕见三选一维持花3回合、剩3回合。两组各三张在入场时通过原奖励随机域冻结，领取不抽签、不改变稀有率修正。合并为rest_card按所选卡稀有度支付，移除直接随机发牌的rest_rare分支；魔瓶和跳过保持原规则。
- rest_cards沿原字段保存六张候选，当前快照验证组内唯一且各稀有度三张。规则案例覆盖未入选稀有卡拒绝、只读查询、当前快照复现、精确选中卡入组、5／3回合扣除、一次真实开场、互斥领取、旧版本重放拒绝及剩余回合结束。
- 完整architecture、content、services、rewards、core、tower分类通过3667项，tower穷举201／201种子，前后源码指纹一致：build/checks/20260911T105208200-45688/，38.65秒。
- 奖励弹窗沿行ID复用选牌组件，分别显示两组三张牌。完整services、rewards窗口通过510项，覆盖实际点击两组、组间切换不串牌、返回不扣费或重抽、精确领取、魔瓶、跳过与原战后奖励流程；前后源码指纹一致：build/checks/20260911T105401297-47968/，103.59秒。已检查唯一截图build/ui-rest-card-options.png：两行三选一及5／3回合代价清楚，魔瓶与跳过完整可见。
- 教程、规则书、接口文档与README同步；不适配旧档，不运行全项目，不打包。

## 2026-09-11 术式解锁拘束面0能量

- 术式解锁配置拘束面减1能量，沿统一牌面费用查询从基础1降至0；默认10魔力、手部施法资格、成功率及失败留牌不变。自由面仍为1能量、2层魔力预备。牢门的真实手牌开锁候选改为复用同一费用入口；没有新增玩法状态、旧档迁移或打包。
- 先新增0能量／9魔力拒绝并回滚、0能量／10魔力开锁、锁之外耐久保持、成功弃牌、自由面仍需1能量与过期提交拒绝。改规则前新增的3项行为检查如期失败：build/checks/20260911T103203537-27044/。实现后完整card_power、card_expansion、architecture、content、casting、rewards、core通过，其中casting350项；同批prison的开锁检查已通过，但将其输入能量设为0后，后续独立站起／离开场景因没有移动预算出现6项连带失败。给后续姿势场景恢复独立测试预算2，不改正式移动规则。记录：build/checks/20260911T103239753-46112/，该批前后源码指纹一致，不能将失败报告标为全绿。
- 修正夹具后完整prison两轮均完成741项且没有断言失败：build/checks/20260911T103646809-47096/、build/checks/20260911T103859724-44968/；两轮期间其他任务继续写入源码，均被SOURCE CHANGED门禁判为无效，不能作为固定版本的全绿验收。
- casting窗口完整40项通过，包含真实鼠标出牌、0能量时拘束面费用0且高亮、翻到自由面费用1且低亮、再翻回并成功开锁扣10魔力。记录build/checks/20260911T103859715-42212/，前后指纹一致。该批prison另有2项旧传送符界面检查寻找已取消的二级目标组；改为验证现有正式“使用”按钮、0费用和悬停身体条件，保留实际使用／离开与道具消耗检查，未改传送符规则。
- 重跑prison窗口先被并行新增的leverage.svg尚未导入阻止，通过正式检查入口导入后141项全部完成，无断言失败：build/checks/20260911T104313557-5756/。该轮仍遇源码变动，整体验收不标为通过。未生成截图，费用数值沿现有卡面渲染；未运行全项目。

## 2026-09-11 休息卡牌奖励调整

- 稀有三选一改为提交时随机获得1张稀有卡，费用从4回合降至3；罕见卡沿原选择页提供三选一，同样花3回合。保留总计6回合、魔瓶＋50扣3和跳过保留6；奖励互斥，领取后才执行一次正式休息开场。复用原奖励随机域、加牌与休息入口，未新增状态字段。
- services行为覆盖冻结三张不同罕见卡、拒绝把稀有卡作为罕见选择、两种正确稀有度及实际加牌、仅随机稀有领取消耗一次奖励随机、概率修正保持、当前快照复现、只读查询、过期重复提交拒绝、互斥领取、开场触发次数和剩余回合耗尽。services窗口覆盖实际鼠标选择、返回不重抽、四种奖励／跳过路径与直接进入对应休息时长。
- 完整architecture、content、runner、services、core、tower分类通过，tower穷举201／201种子；同批rewards的一项旧界面断言仍假设只有一个附加选项，按新增随机稀有选项更新为两个。首轮记录：build/checks/20260911T101847416-43824/，4038项中该项失败，源码指纹一致。随后仅重跑完整rewards分类，305项通过、指纹一致：build/checks/20260911T102039883-14876/。不将首轮报告标为全绿或全项目回归。
- services窗口首轮被尚未导入的breath_control.svg阻止启动；通过正式检查入口导入后重跑完整services窗口，267项通过、指纹一致：build/checks/20260911T102129437-47460/。已检查唯一截图build/ui-rest-card-options.png：罕见三选一、随机稀有、魔瓶和跳过均可见，3回合代价明确，无底部溢出。
- 教程、规则书、奖励投影、候选和领取日志同步；当前快照只接受三张罕见候选，无旧存档迁移或重新打包。

## 2026-09-11 六缚高潮逮捕

- 规则数据与状态：六缚的首次高潮逮捕门槛为累计4次，之后门槛每次增加1。公开意图冻结本次对应门槛；未打断时复用正式收押，打断后取消本次逮捕、保留六缚当前步骤，并将原行动直接恢复为下一回合意图。装备空间耗尽的普通逮捕不携带取消标记，继续使用原延后规则。
- 正例、反例与边界：覆盖累计3次不触发、第4次触发并收押、共用体术打断、日志文案、取消后原步骤不推进、下一回合原行动正常执行，以及第5次高潮再次触发。当前快照保存下一门槛和公开意图，拒绝意图门槛与实例记录不一致且保持原子回滚；修订号升至37，不迁移旧档。
- `encyclopedia,intent,enemies`完整专项在门槛、打断和图鉴接线完成后通过1732项断言：`build/checks/20260911T101557711-4860/`。随后收紧快照非法门槛与非六缚标记校验，最终`enemies`完整专项通过1339项断言，前后源码指纹一致：`build/checks/20260911T101911579-30140/`。没有运行全项目、窗口截图或重新打包。

## 2026-09-11 同档施加优先补空小部位

- 按用户最终澄清保留原三档优先级，只在同档内先向没有拘束具的小部位施加。使用正式精确点及左右侧别；复合主体覆盖计为已有拘束，即使不占普通容量。没有空点才恢复该档原随机方案，不跨档找空位。无区域等级／增幅评分，不新增第四档，不改变单件紧度或区域计算公式。
- EquipmentOffers.preferred统一筛选Application、敌人批量和事件候选；普通来源、复合结构、特殊真实占位和原子组均沿现有规则数据取小部位。保留来源、明确目标、混合池／规格／材质权重、替换权限与受保护装备。无额外写入、随机、效果预执行或状态字段。
- installation_priority更新同档补空案例：大臂已有一段仍优先空的手肘上方、无区域数值提升仍补空、区域已4级仍补空段、原前两档不变、逐件重判后才叠加、事件／敌人一致、复合覆盖与手部侧别、替换资格及回滚。移除被用户更正的区域评分断言。玩家词条及现行规则说明同步。
- 相关回归同时修正guard残留的基础卡5伤断言为既定6伤：无其他拘束时12伤、50点捕缚剩38，存在其他拘束时6伤；未修改捕缚运行规则。
- 完整关联范围installation_priority、content、runner、events、equipment、links、composites、prison、guard、enemies以Exhaustive执行，5731项行为断言全部通过，168.16秒；日志build/checks/20260911T095551500-44916/。工作区有其他任务并行修改，检查器标记source_changed，这轮不作为固定版本的绿色门禁。上一轮唯一失败为旧测试要求皮带堆随机全身施加必出链接；补空可用完全部位置，已改为保留完整六阶段材料／分裂检查，并从同一正式皮带池取得合法链接实际提交验证，未修改敌人出招。
- 最终专项replacement、application、architecture、installation_priority全部319项通过，10.07秒、退出0，前后源码指纹一致：build/checks/20260911T100041901-33412/。窗口intent完整40项通过，18.73秒、退出0，前后指纹一致：build/checks/20260911T095947510-28104/。这些是明确范围的通过，不代称全项目或静止版本的大范围回归。
- 玩家施加词条与规则说明同步。无美术或布局变更，不生成截图，不做旧档适配或重新打包。

## 2026-09-11 主页固定立绘开关

- “扶她出去”默认关闭，保存到既有display-settings.cfg；初始化读取布尔值，缺项默认关闭。左侧和战场共用既有equipment-portrait-cutout-v1.png，开启后全部差分隐藏，战场固定站姿比例与位置；不修改GameState和正式候选。
- display窗口23项、home窗口18项通过：build/checks/20260911T094541501-40108。hero_art最终42项通过：build/checks/20260911T094713368-45908，覆盖主页实际鼠标开关、正式站→坐→躺行动中的固定图像、所有叠层隐藏、尺寸稳定及关闭后恢复真实差分。首轮测试误把主页继续的正式场景起点恢复计入开关效果，最终显示夹具保持当前状态，未改写继续游戏规则。
- 已查看build/ui-home-fixed-portrait.png和build/ui-fixed-portrait-battle.png，开关无溢出、两处站姿完整且无差分。没有生成或修改人物素材，没有整体回归或重新打包。

## 2026-09-11 并腿踢击统一腿部衰减

- 并拢飞踢／并腿蹬击由kick_profile按（基础10／5＋力量＋蓄力）整体乘双腿BODY_DAMAGE；预览和实际攻击共用。保留费用、资格、打断、躺下和冷却，4级倍率0仍沿原合法动作流程。
- 更新原冷却与窗口伤害期望，新增站／坐两姿态、腿部1—4级、力量2＋蓄力1的预览／真实掉血、旧版本拒绝及一次扣费扣蓄力案例。首轮8项失败源于夹具把脚踝共同固定误算为腿部1级，已按正式脚踝2级修正并使用小腿夹具覆盖1级，未改动等级规则。
- ListOnly确认basic_attacks后，完整体术规则167项、窗口50项通过；日志build/checks/20260911T092708848-28872。未运行整体测试，未重打包或修改已交付v0.12成品。

## 2026-09-11 测试细则：过期删除与重复整合

- 全tests目录扫描同体函数、连续重复代码、长断言、历史名／旧行为检查和常量断言，再对候选结合当前注册表与专属案例核对。修改9个测试脚本，净减33行和11处断言调用位置；逐文件统计、清理理由与修改前副本在build/test-detail-audit/。这是静态扫描及候选定向核对，不是全部交互组合已无缺陷的结论。
- 删除4处已不属于本期需求的检查：已删除tailor／locksmith事件名称必须持续缺席、已删除resonant_band与intimidation定义持续缺席，以及advanced旧奖励字段继续兼容的断言。当前事件池／奖励三档／真实警卫回合无压力来源等有效正反例保留；运行时旧字段兼容实现和延期存档文件未修改。
- 合并7处重复断言：商贩UI的5处数值／头部配置／怪池检查已有trader规则检查，其中强池归属还保留了更严格的唯一搭档断言。UI中独有的计划字段、合法模板、循环深拷贝和图鉴内容约束迁入trader，不丢失。core中2处投影只读／深引用断言由architecture.projection_contract的完整容器遍历与多场景合同承接；篡改候选伤害／费用仍无法改变正式提交的检查留在core。
- 3个重复辅助函数收敛：binding_enthusiast重复give使用既有curse_cases.give；echo_cast和letter_opener同体play合为curse_cases.play。原默认牌面一个false、一个true，调用处显式保留各自值，不能因函数体相同误换牌面。没有新增框架或运行时接口；剩余至少3个有效代码行的完整函数体未发现完全相同副本。
- 保留看似相同但前提不同的测试：各张卡的过期版本拒绝、不同费用／随机域、失效目标、UI刷新后无重复表现、不同材质与身体条件，以及合法当前快照边界。不缩减种子集，不删除故意错误探针，不因含old／removed字样机械清理。
- 完整受影响规则分类card_power、architecture、curses、runner、events、core、pressure、trader共2293断言通过，37.21秒、退出0；日志build/checks/20260911T084950562-38908/。商贩窗口分类38断言通过，14.62秒、退出0；日志build/checks/20260911T085000845-23776/。两轮无引擎错误，前后源码指纹一致。没有重复执行已通过且未改动的其他项目，也未运行全部项目。
- README和AGENTS补充允许经对照删除过期测试、统一重复归属的规则，保留有效覆盖。首页恢复已知失败仍在延期项目，不计修复；无存档专项、无布局／美术变更、无截图、不打包。

## 2026-09-11 按当前Demo进度重组测试项目

- 从rewards移出既有card_power、card_expansion、relic_revision整块测试，分别登记为card_power、card_expansion、relics；Boss遗物和余烬结晶并入relics，原rewards不重复调用。保留三个新项目原先随rewards取得的交叉影响覆盖，定向选分类不扩张，显式Impact仍不丢关联用例。没有为每张新卡复制测试框架或修改游戏规则。
- 窗口card_power从casting的嵌套调用移为独立分类；home拆为首页导航、encyclopedia图鉴和home_persistence恢复。旧首页57处断言逐行比对全部保留，新增2处首页正式新局／返回检查；转移核对及修改前副本存于build/test-project-reset/。原服务房间恢复失败断言原样保留在home_persistence，没有通过删断言或改预期制造绿灯。
- README维护当前项目映射，suite_selection的调度标签区分当前能力／卡牌／遗物／奖励／体术开发、其余按改动维护、延期存档与显式长流程。标签只供计划展示，不排除显式选择。persistence、home_persistence延期；normal_play、baseline不进入日常小批次。完整登记现为49规则分类、45窗口模块，增加的是可独立选择的职责边界，并非新增重复测试内容。全量只列计划，没有运行。
- runner新增实际run调用的归属校验：所有带run入口的案例必须接入唯一分类，辅助函数引用不误算为重复执行；同时校验新分类独立选择和旧交叉覆盖保留。最终345断言通过、1.29秒、退出0且无错误，日志build/checks/20260911T080159644-45120/。
- 完整规则card_power、card_expansion、relics、rewards共2110断言通过，20.18秒、退出0、前后源码指纹一致，日志build/checks/20260911T075956030-27036/。本轮只搬移调用归属，原规则断言和抽样策略保持。
- 完整窗口card_power、encyclopedia、casting、home共299断言通过，89.47秒、退出0、无引擎错误、前后源码指纹一致，日志build/checks/20260911T075938203-38420/。逐模块为能力卡195条／69.37秒、图鉴49条／1.98秒、施法37条／7.31秒、首页18条／0.96秒（模块时间不含进程启动）。日常改首页或施法界面因此不再连带整套能力卡与恢复用例。分类搬移后相关输入流程可独立执行。
- 延期恢复项目仅检查断言迁移、注册归属与计划标签，未执行，也不计通过；上一轮已知“恢复服务房间后仍可交互”失败继续开放。最终仅补跑受改动的runner验证交叉覆盖表，没有重复运行已通过且未改的规则和窗口项目。本轮无运行时功能变化、无截图、不适配旧档、不打包。

## 2026-09-11 测试流程精简与续跑

- tools/check.ps1仍为唯一入口，默认从全量改为architecture、runner；-Suite仅执行指定完整分类，-Impact显式恢复从初始请求的一次性交叉扩展。UI默认home，完整all与正常试玩长流程仍保留，-ListOnly改为可选预览。没有删除行为断言、抽减新的随机样本、修改游戏规则或开展旧档兼容。
- 规则／窗口运行器输出分类开始和结果；首个失败分类结束后停止，-KeepGoing仅继续当前阶段的断言失败，运行时错误仍停止。初始化与UI重启出错及时返回，避免继续级联。每轮summary.json记录选择、通过、失败、未执行、续跑范围和源码指纹；-RerunFailed不复用历史PASS冒充当前完整通过。运行中代码变化使整轮失效并要求重跑原选范围。README和AGENTS旧默认／隐式扩展说明已替换。
  > **本条已取代（superseded，2026-09-17；新口径见 `docs/check-routing.md` §4.1／§4.3）**："首个失败分类结束后停止／`-KeepGoing` 仅继续断言失败／运行时错误仍停止"**全部作废**。现行：断言失败与脚本错误都只记该套件 `FAIL`（脚本错误另标 `SUITE RUNTIME: <name> <n>`），其余套件一律跑完，`unrun=[]`；`-KeepGoing` 为兼容无操作。历史文本原样保留。
- 默认规则architecture、runner共92断言通过。最终从source_changed报告续跑相同完整范围，92断言通过、10.95秒、退出0，前后指纹一致；日志build/checks/20260911T075557529-5876/。故意源码变化的独立探针正确退出1并标记全部原分类待重跑，日志build/checks/20260911T075534315-29272/；临时探针JSON已经清除。
- runner自身23断言通过；VerifyRunner验证故意脚本错误（规则／UI）、1秒超时、首分类失败停止、KeepGoing继续以及失败／未执行报告。日志build/checks/20260911T075415322-43052/。根据其中真实negative-stop日志构造恢复报告，经公开-RerunFailed入口执行runner、tower，165断言通过，日志build/checks/20260911T075507550-13640/。
- 范围计划核对：casting直接选1分类、Impact选16分类且不引入normal_play；显式all仍含46规则分类、42窗口模块及完整随机样本。未知分类退出1、报告failed；计划不计测试通过。未运行全项目回归。
- 窗口home真实执行107断言，其中1条“HOME restored service room remains interactive”失败，位置tests/home_ui_cases.gd:185；完整运行因此退出1，summary准确保留已通过规则并只要求续跑home。-RerunFailed配合-ListOnly核对仅选home、不重复规则。本轮保留失败，按用户存档工作延期要求不展开修复；日志build/checks/20260911T075235020-43584/。因此这里只确认测试流程工作，不声明全部游戏测试通过。无布局改动、无截图、不打包。
## 2026-09-11 v0.12 PC／Android交付

- 按用户“直接打包、不再跑整体测试”的最新指示，停止本轮规则与窗口测试，不声明本轮整体回归通过。魔力回路旧UI文案断言改为检查真实的30耗魔／能量＋1，原实际双重激活验证保留。
- Windows文件／产品版本0.12.0.0，Android versionName=0.12、versionCode=4，沿用org.magic.spire和发布签名。两端导出源码指纹351个文件逐项一致。
- Windows实际EXE启动和PCK新游戏／练习／隔离存档探针通过：build/package-check-20260911T075011467。APK发布签名、16KB对齐、启动入口与内容清单通过：build/android-20260911-v012；包内资源探针通过：build/android-probe-20260911T075045934/probe.log。没有连接ADB设备，未进行Android真机验收。
- 发布包不含玩家存档、个人设置、测试代码或签名私钥。PC ZIP内各文件与发布清单哈希相符。交付文件：../outputs/紧缚尖塔demo-v0.12-Windows64.zip（113677300字节），../outputs/spire-v0.12-android-20260911-v012/spire-v0.12.apk（128716589字节）；SHA256见../outputs/spire-v0.12-checksums.json。旧版成品保留。

## 2026-09-11 开信刀play跨回合累计

- 两面卡文及状态说明改为“每使用3张技能牌”，本场保留未满3张的进度。删除唯一旧reset_power_progress接口及其回合开始调用；既有record_play／flush_powers继续按实体技能牌计数，每满3张触发并扣除3张。本场结束清理保留，伤害及费用不变，无新状态、随机域或旧档适配。
- letter_opener_cases更新回合边界断言，覆盖自由面余数保存、当前快照往返、跨回合补齐后击杀，以及拘束面2张跨回合补第3张后按原预览伤害触发。既有多段、连续触发、其他牌型排除、旧版本拒绝、复合外层目标及结束清理继续完整验证。card_power_ui_cases通过真实翻面、出牌和结束回合验证新卡文及2／3→跨回合2／3→0／3。
- 规则rewards及自动交叉19分类6994断言通过（176.37秒），日志build/checks/20260911T072640735-42204/check-rules.log。窗口casting分类231断言通过（84.03秒），日志build/checks/20260911T072640739-39340/check-ui.log。两项退出0、无引擎错误；没有布局／美术改动，未新增截图。规则书、框架文档、模板说明、README与AGENTS同步；不打包。

## 2026-09-11 拘束之拥

- 新增罕见能力，自由2费／拘束1费；两面均持续本场、可反复触发。沿实体能力、正式装备安装及清理、既有抽牌和版本提交。待抽张数只在对应状态图标角标及悬停展示，能力卡保持固定文案。新增SVG卡画，奖励／商店／图鉴沿罕见池自动接入。
- restraint_embrace_cases归入rewards既有能力测试，覆盖两面费用、查询不变、旧版本拒绝、同面拒绝、真实出牌解除、重复清理、复合按根计数、部分组件、加固、延迟发放、再次积累、快照往返／坏值拒绝、场次结束、链接、替换预演／提交／重复拒绝、10张上限。规则关联equipment/composites/links/shoulder/replacement/persistence/status均已列入本批完整分类门禁。
- 初轮规则10594断言中3项失败及1处脚本错误：新夹具误用低于复合工厂最低品质的1级；既有紧缚爱好链接夹具未把安装点固定为其指定端点。已将夹具改为正式允许的2级复合及明确膝上／膝下位置，不改规则或削弱断言；失败日志build/checks/20260911T071137310-37468/check-rules.log。
- 窗口casting初轮230断言仅旧魔力撑隙文案检查失败，仍写死原来的1层；改为读取该牌正式自由面正文进行UI完整性检查。重跑整个casting分类229断言通过、退出0且无引擎错误，日志build/checks/20260911T071425225-5764/check-ui.log。新卡两面真实点击、固定卡文、状态计数及跨回合能力保留检查通过。
- 修正仅涉及测试夹具／旧文案断言；规则rewards及全部自动交叉范围共19分类6980断言通过，耗时266秒、退出0且无引擎错误，日志build/checks/20260911T071709025-41960/check-rules.log。首轮其余受影响分类均已通过，本轮完整重跑所有发生失败的所属分类，未改单例替代分类门禁。
- 显式截图仅1张build/ui-restraint-embrace.png，已查看两面费用、罕见边框、独立卡画和能力区文字，无溢出；测试修正没有视觉变化，未重复截图。不适配旧档、不打包。

## 2026-09-11 正义飞踢重设与灌注

- 正义飞踢最终为2能量18伤害，未并腿站姿沿“站着踢”的腿部活动自由条件；无自带打断、次数、冷却或开场回合限制。并腿／坐姿变体继续使用原独立效果和共用冷却。灌注为稀有魔法，施法部位无；自由1能量20魔力、拘束2能量10魔力，分别给下一次手部／腿部体术附加一次打断。多段只延迟一次，同一已延迟意图不重复延迟，匹配增益沿原完整动作消费。
- 新增infusion_cases覆盖两面费用、身体无要求、快感施法失败、重复施放拒绝、正式消费、攻击家族匹配、多段／群攻／原生打断、击杀、无效提交、快照和状态。原敌人打断用例改用已登记灌注增益与普通踢击夹具；腿部受限用例先通过正式行动坐下，未绕过新正义飞踢资格。
- 相关分类首轮10172断言发现自由面附加费用配置及一个旧混合敌人站姿夹具不符；已修复。受影响分类`-Suite rewards,enemies`重跑7537断言通过，引擎退出0、无错误，日志`build/checks/20260911T065645823-37676/check-rules.log`。其余首轮相关分类已通过，无重复全局回归。
- `-UIOnly -UISuite basic_attacks,intent,targeting -Screenshots ui-infusion.png`通过154断言，引擎退出0、无错误，日志`build/checks/20260911T065645822-13300/check-ui.log`。验证首回合连续正义飞踢、实际腿部禁用、灌注翻面／价格／使用、动作打断标签及目标／意图交互；人工检查`build/ui-infusion.png`。未打包。

## 2026-09-11 新增接口复查（二）：奖励键盘已修复，规则回归仍未通过

本轮跟进上次检查之后的统一奖励、Boss遗物、卡牌波及、深呼吸、饱和逮捕、教程与启动入口，以及同时推进的能力牌和基础动作调整。检查期间“塔-设定2”仍在修改规则，不能把某次测试加载的代码当成后续全部修改的验收结果。不打包，不做旧档适配。

- 静态扫描当前97个运行脚本、194条字面量脚本依赖，未发现循环、core/data反向依赖ui、UI直接读取game.state、缺失字面量资源或至少5行的完整函数体重复。相对上轮指纹已有45个新增／变化脚本；检查期间仍有其他规则文件变化，初始与结束指纹、扫描摘要及失败明细保存在build/incremental-audit-20260911-pm/。这不是对所有动态路径或交互组合的无缺陷证明。
- 修复：新统一奖励页没有进入KeyboardInput原来的弹窗焦点范围，选牌后Tab/R/Enter分别无法导航、翻面和领取。新增真实输入测试先分别复现三项失败；现在popup_region集中识别付款弹窗、抽屉、主页与实际可见BattleRewards，blocked、悬停翻面和焦点导航共用它。优先级保留付款弹窗和上层抽屉，确认只触发原按钮，Esc仍沿原返回逻辑，不增加奖励命令或支付分支。
- 补充覆盖：奖励列表与选牌页焦点、悬停翻面不领取、领取恰好一次、重绘后不重复确认，以及Boss遗物页的焦点和真实领取。键盘分类67项通过。基础操作教学.txt、docs/keyboard-controls.md及AGENTS.md同步；未改规则数值、存档结构、布局或素材。
- 窗口组合：card_splash/keyboard/interface/pressure/rewards，共643项通过、退出0且无引擎错误；日志build/checks/20260911T064758688-45700/check-ui.log。无新增截图。该结果验证本轮奖励输入修复及测试加载时的相关界面，不能覆盖运行过程中另一任务后续修改的规则。
- 规则组合：card_splash/battle_saturation/rewards/pressure/architecture及自动交叉范围，共23分类7793项断言，40项失败，整体退出1；日志build/checks/20260911T064808865-40456/check-rules.log。失败集中在pressure和enemies：当前kick_profile对未并腿站姿正义飞踢返回interrupt=false、cooldown_turns=0，而现有契约及多项打断测试仍要求原打断与冷却。未发生预期的延迟后，又连带造成阶段推进、装备施加和后续行动不存在的断言失败。相关规则正在另一任务调整，本轮保留失败，不擅自恢复旧行为，也不删除断言假装通过。
- 首次规则运行碰到灌注注册表的中间状态，CARD_NAMES已登记但SPECS尚不完整，出现大量级联错误（build/checks/20260911T064522631-15100/）。首次窗口运行还遇到新增infusion.svg尚未导入（build/checks/20260911T064557499-40180/）。资源导入成功后，完整键盘分类明确复现本轮三项导航失败，修复后62项通过，再补充Boss与列表案例完成上述67项及643项组合。早期错误运行均不计通过。
- 本地启动tools/launch.ps1 -CheckOnly退出0，VBS和CMD仍汇入单一启动脚本；未再启动交互窗口或改发布包。

当前结论：奖励键盘接线已修复并验证；新增规则尚未整体闭合，正义飞踢／灌注这批调整需要同步规则约定与打断用例后重新执行失败分类。完整普通游玩长流程、密集装备性能及Android真机验收仍未由本轮完成。

## 2026-09-11 独立奖励统一弹窗与跳过

- 用户最终边界：只改独立奖励领取和选牌界面；与事件选项绑定的直接奖励、商店交易、套娃等自动发放照常结算，不追加可跳过的领取阶段。
- GameView.reward_panel统一战斗／Boss、事件奖励选牌、休息稀有卡和宝箱的只读奖励行、原候选ID、继续／跳过及休息魔瓶入口；ui/reward_screen.gd负责唯一弹窗。删除main.gd旧事件领奖、休息选牌与宝箱独立布局，事件阅读结果和其他事件选项选择保留。
- reward_skip按card／relic单独放弃，既有reward_claimed记录skip，界面显示“已跳过”；不退出奖励阶段、不丢弃其他奖励、不发物品或触发遗物、不扣费、不重抽。当前快照校验与回读识别该结果，候选仍按版本复核，跳过后重复领取／提交拒绝。休息沿rest_begin保留全部回合，事件跳过不撤销原选项已结算代价。保留手牌沿原retain_skip，消耗手牌的跳过仅取消未提交行动。
- battle_reward_cases覆盖普通与Boss分项跳过、其他奖励领取、已跳过显示、资源与随机／回合不变、过期与重复提交、当前快照恢复和休息回合；奖励、服务与事件窗口用真实点击覆盖统一列表、选牌／遗物二级页、返回、跳过、继续与原选项效果保留。共享窗口测试助手按只读action_ids打开对应奖励行，不绕过正式行动。
- 完整rewards,events,services,persistence及自动关联分类9439条通过，332.83秒，日志build/checks/20260911T062803332-43524/check-rules.log。
- 窗口首轮services 245条、events 176条通过；rewards有1处旧断言仍把奖励候选总数固定为4，已改为区分领取与独立跳过。完整rewards复验223条通过（85.46秒），日志build/checks/20260911T063227717-39576/check-ui.log；首轮日志build/checks/20260911T062803333-5508/check-ui.log。已人工查看build/ui-rewards-unified.png，三张遗物、说明、返回及跳过按钮无重叠；仅保留这一张相关截图。未打包。

## 2026-09-11 术式解锁自由面2层

- 仅修改unlock的自由面reserve_mana.amount为2，每层仍为5点，实际获得10点临时魔力；1能量、手部使用条件、免施法与免耗自身魔力、正常弃置保持。双重解锁仍为1层，不增加状态、迁移或新接口，不打包。
- temporary_mana_cases覆盖低／高快感下正式使用、与小数余额叠加、1能量、无魔力支出／随机消耗、正常弃置、旧版本回滚及手部阻止；card_text_cases核对图鉴、实时卡面和10点徽章；casting_ui_cases新增真实翻面与点击使用。AGENTS、README、设计文档和卡牌框架同步。
- 规则门禁：首轮core,casting及关联分类5188条中仅1处旧“+5”角标预期失败，实际效果和资格用例通过；同步该断言后完整rewards及其关联分类6753条通过（189.63秒），日志build/checks/20260911T060500385-44548/check-rules.log。首轮已通过的core、casting等未改逻辑，不重复执行。
- 窗口门禁：同步既有卡牌修订检查中的unlock“+10”预期，并修正新增测试在自动选面之后再翻面的顺序，沿现有鼠标点击助手提交；完整casting分类212条通过（73.72秒），日志build/checks/20260911T060809015-33916/check-ui.log。卡面2层、角标+10与真实使用到账均通过，无截图、无打包。

## 2026-09-11 本地启动去除控制台

- 新增开始游戏.vbs作为无命令行窗口入口，原cmd转接。launch.ps1将Godot图形进程与启动控制台分离，失败仍显示具体异常；脚本保存UTF-8 BOM，兼容Windows PowerShell中文提示。
- Windows PowerShell执行`tools/launch.ps1 -CheckOnly`退出0，找到本机Godot 4.7.2图形程序。经wscript真实启动，确认游戏窗口完成初始化并显示“紧缚尖塔demo v0.11 (DEBUG)”，启动助手已退出；仅正常关闭本次新启动的测试窗口，未关闭用户原游戏或其他任务进程。
- 仅本地启动脚本修改，不改玩法、不重跑游戏规则或界面套件、不打包。

## 2026-09-11 教程基础操作置顶

- 教程默认打开基础操作，导航及全部条目均以基础操作开头，首屏显示电脑右键／手机长按翻面、卡牌与行动拖动、具体装备选择。双平台介绍避免被通用安卓文字替换改错。
- `-UIOnly -UISuite interface -Screenshots ui-tutorial-basics.png`通过282条断言，引擎退出0，无引擎错误；日志`build/checks/20260911T061130007-43512/check-ui.log`。覆盖默认页、全部条目排序、分类与搜索、关闭及游戏状态不变。
- 人工检查`build/ui-tutorial-basics.png`，三项操作说明在首屏完整可见。仅教程入口与文案调整，不改规则，不打包。

## 2026-09-11 顶栏信息带排布

- 五项信息合为深色横向底板，地点暖金、行动状态小色标，统一单行居中和细线分隔；沿用现有只读信息，教程书及功能按钮位置保持。
- `-UIOnly -UISuite interface -Screenshots ui-run-header.png`通过276条断言，引擎退出0，无引擎错误；日志`build/checks/20260911T060101612-28896/check-ui.log`。覆盖更新后的回合／警戒数值、单行对齐、控件不重叠、非战斗状态标及原顶栏导航。首轮测试把只有阶段字段的商店夹具完整渲染，缺少商店数据；已改为用有效场景检查只读非战斗标题投影，重跑通过。
- 人工检查`build/ui-run-header.png`，顶栏完整可读，信息层次清楚。纯界面修改，不重跑规则、不打包。

## 2026-09-11 顶栏教程书入口

- 教程书从游戏菜单移至顶部警戒度与状态之间，暖金底色、亮金边框与柔和高亮；菜单移除重复入口。继续调用原共享抽屉，不新增玩法状态或存档字段。
- `-UIOnly -UISuite interface -Screenshots ui-header-tutorial.png`通过269条断言，日志`build/checks/20260911T055121934-31832/check-ui.log`。验证顶栏各控件不重叠、高亮、菜单无重复项、顶栏真实点击切换抽屉、分类／搜索／Esc与状态不变。首轮测试变量重名导致解析失败，已改名重跑，失败批次不计通过。
- 人工检查`build/ui-header-tutorial.png`，入口与其他顶栏按钮对齐，文字清晰且高亮明显。此次只涉及界面，不重跑规则、不打包。

## 2026-09-11 金字塔仅限本场保留（已验证）

- 仅修改手牌结束生命周期：回合末保留继续；active场次结束复用_discard_end(end_session=true)忽略全部保留来源。删去胜利、手动结束整备／休息和出狱路径重复的回合末处理。
- 覆盖胜利、整备提前／自然结束、休息提前／自然结束、出狱、巡视转警卫战。新案例在同一个Boss遗物案例入口内，检查同场保留、跨场清除、保留期限归零、永久卡组和物理卡不丢不重。
- UI／文案：玩家遗物说明按用户要求保持原样；卡牌移动继续用原discard／exhaust动画和真实只读牌堆，无新增窗口、文案或截图。魔力、能量、蓄力、遗物本体、随机域、费用和存档结构不变。
- 验证：tools/check.ps1 -Suite rewards -TimeoutSeconds 360完整分类及交叉检查6753断言通过、无引擎错误；记录build/checks/20260911T055253208-43584/check-rules.log。包含七类场次边界、正常回合保留和永久卡组／实体卡守恒；首轮测试反抗动作字段误用op，已纠正为正式action并通过重跑。未新增截图或打包。

## 2026-09-11 基础挣扎／滑脱卡6点

- 奋力挣动（strain）与扭身抽离（slip）共用规则定义的base由5改为6；费用、自由面和原伤害公式不变。卡面、装备与捕缚预览／提交同步；毕业证书仍加4，卡面为10；波及基础为当前牌面的50%。无新增状态、接口或存档适配，不打包。
- graduate_certificate_cases新增未持有遗物时两张牌的6点卡面／候选／实际耐久、1能量与正常弃置检查；更新持有时10点及捕缚、锁、叠层和旧版本回滚断言。card_splash_cases检查普通滑脱6点对应3点波及；reward_ui_cases覆盖领取前6点和领取后10点及卡组展示。README、设计文档与AGENTS同步。
- 首轮rewards,core,card_splash分类共7737条，4处失败均为旧数值预期：蓄力案例固定按5点，无人机案例固定按旧卡伤害推导捕缚条。已将这些交互测试改为读取当前牌面／正式预览；其他分类通过，未为该改值修改任何蓄力或无人机规则。
- 规则复验：完整rewards及关联分类6728条通过（213.45秒），日志build/checks/20260911T054653946-33172/check-rules.log；首轮已通过的core、casting、basic_attacks、pressure未重跑。窗口首次因interface_ui_cases.gd预加载失败而未执行，独立语法检查通过；重跑完整rewards窗口分类213条通过（80.26秒），日志build/checks/20260911T055235905-13348/check-ui.log。无截图、无打包。

## 2026-09-11 深呼吸按嘴部等级＋紧度衰减

- RuleChangePackage：Balance登记口部总值倍率，Pressure.calm只读当前真实嘴部装备等级与耐久对应紧度，取最大总值；候选预览／阻止原因与提交结算共用。2—6依次减效20%—100%，无拘束恢复基础25；下回合能量＋1始终不参与衰减，完全封锁时无合法行动。
- 不变项：1能量费用、零耗魔、非施法、原压力0／过载门槛、回合与随机、姿势／手部资格、道具减效算法、其他减压来源、存档结构和原预备能量到账／抵扣／收押清理。动作结果继续输出实际减压和完整能量奖励，无新叙事分支；教程、README、AGENTS与设计正文同批更新。
- 案例：口球／堵嘴胶带各9种等级紧度组合、正式预览与结果一致、版本过期和完全封锁的整状态回滚、费用／能量奖励与不变卡牌装备随机、真实日志、正式徒手取下后的25点恢复、眼部不影响、带锁口球降档后的5点恢复、低快感截断与当前快照恢复。UI检查实际快感－10、下回合＋1、点击生效及高级3档原因／拒绝。
- 先ListOnly确认pressure及9个交叉分类、pressure窗口。最终规则4188项通过，54.07秒（build/checks/20260911T054552646-5716/check-rules.log）；窗口60项通过（build/checks/20260911T054640913-43792/check-ui.log），exit0且无引擎错误，不截图。
- 首轮规则失败来自同工作区基础牌5→6后两处旧固定伤害断言，已随该批规则更新后完整复测。首次窗口失败来自测试替换嘴部装备前漏掉清理已解除物品；补齐正式清理并断言新夹具安装成功／状态有效，未更改游戏规则或放宽结果断言，随后完整pressure窗口复测通过。本轮只改源码，不打包发布。

## 2026-09-11 普通卡汲取

- 以既有双面卡模板加入siphon：拘束0能量回复5魔力、不判施法；自由1能量回复10魔力并抽2张，腿部束缚等级0、嘴部吟唱判定。注册普通奖励／商店池、中文名称／分面文本及配套SVG图标，无专属结算或保存分支。
- tests/siphon_cases.gd纳入rewards分类的card_expansion入口，覆盖受限身体下的拘束面、两面能量、魔力上限、失败无收益／保留手牌、普通弃置、腿部限制、真实嘴部概率、旧版本拒绝及8种种子下成功／失败的当前快照复现。rewards交叉区域补充content，确保内容修改也覆盖混合施法与身体条件。
- 首轮rewards,casting,content为8214条、9处测试失败：原通用文本检查把身体条件当成全部条件；新增快照测试未计入恢复会推进版本号。修正这两种测试假设后，重跑完整rewards及关联分类，6721条通过，日志build/checks/20260911T053424178-45856/check-rules.log。其余已通过的casting分类保持不变，没有宣称首轮综合门禁通过。
- 窗口siphon模块通过6条断言，日志build/checks/20260911T053059902-44456/check-ui.log：真实翻面、分面费用／回复／抽牌、自由面腿部条件及点击结算。导入通过；人工检查build/ui-siphon.png，卡面图标、魔力角标和两项要求清晰。仅保留这一张新图标相关截图，未打包。

## 2026-09-11 Boss遗物接入（已验证）

- 规则数据／状态：新增五件Boss遗物、独立随机池、boss_relic_options；复用原relic随机域、领取类别互斥、拾取入口和能量边界。当前存档修订36。
- 行为边界：最大能量跨普通／特殊战斗回能；两张永久诅咒；三品质各抽一；回合不弃牌；魔力上限付费；永久眼罩阻断操作、伤害、替换、事件、商店，变身／续局保留。
- UI与日志：三选一全图标／名称／说明，领取后回到奖励清单；Boss图鉴分类；能量上限提示；拾取后的实际卡组／上限／装备结果；结束回合按遗物描述保留手牌。
- 未改：卡牌稀有度、其他遗物普通池概率、战斗AI／数值、伤害公式、地图生成和费用规则。无新发布产物。
- 案例：boss_relic_cases由rewards原入口统一运行；既有塔顶测试改验Boss三选一。reward_ui_cases增加真实三选一点击／返回不重抽／卡牌先领后领遗物，仅保留ui-boss-relic-choices.png一张专项截图。
- 最终规则证据：共享工作区在本批全部源文件修改后运行的rewards完整分类及交叉归属检查，build/checks/20260911T053424178-45856/check-rules.log，6721断言通过、无引擎错误，含本批Boss拾取／回能／永久眼罩／三选一／快照用例。额外replacement分类在build/checks/20260911T053010488-26492/check-rules.log中97断言通过；该早期整批有并行卡图更新导致的status依赖加载错误，不将早期整批记为通过。
- 最终窗口证据：build/checks/20260911T053609017-12412/check-ui.log，rewards完整窗口分类212断言通过、无引擎错误。ui-boss-relic-choices.png已查看，三列名称／图标／效果完整、未溢出；卡牌先领后仍可打开Boss选择，选择后回到已领取清单。
- 早期复核：牢房测试夹具补齐正式入狱记录；损坏快照回滚对比改为读档后版本。并行新卡用例的中途失败以最终共享工作区绿色记录覆盖。本批未打包。


## 2026-09-11 v0.12回魔平衡：激发魔力20／小刻印5

- 仅修改mana_invocation两面mana_gain=20和small_sigil.opening_mana=5。沿原实际回魔／上限、魔法判定、消耗与开场生命周期，普通／整备／休息／牢房共用。名称、稀有度、费用、抽牌、失败、遗物结束回魔及临时魔力保留不变，无状态／随机／迁移变更。
- 玩家文案：卡面、右上角回魔徽章、图鉴和实际结果继续从共用规则生成；小刻印说明改为恢复5魔力，设计与README同步。无新增叙事或日志分支。
- 更新真实出牌案例：两面分别从0、60、80、95、100魔力施放，检查20点恢复与上限，保留旧版本回滚、能量不足、失败不回魔和消耗入堆。开场案例检查各类场次30→35、结束遗物35→45仅一次，以及奖励→整备与提前结束的连续余额。窗口检查＋20徽章及实际点击40→60、扣1能量并进入消耗堆。
- 门禁：先ListOnly确认rewards／casting及24个交叉分类、casting窗口。本批回魔、卡面及生命周期断言通过；第二轮综合回归8181项仅1项失败，来自并行新增Boss遗物的缺失永久眼罩快照回滚断言（build/checks/20260911T052552166-39668/check-rules.log），不宣称综合门禁通过。首轮含同步中的Boss夹具失败及一处被宽泛数值替换误改的原大理石断言，后者已还原并在第二轮通过，旧失败记录保留。
- casting窗口210项通过、exit0、无引擎错误（build/checks/20260911T052403219-35252/check-ui.log），包括＋20徽章及实际40→60、扣费与消耗牌验证。剩余Boss存档断言归属并行Boss遗物修改；本批不修改其规则或放宽测试。本轮不截图、不打包发布。

## 2026-09-11 绿色小鸟前6回合

- 将green_bird既有pressure_guard_turns从4改为6，遗物正文同步；共用保护结算、99上限、超额舍弃、combat.turn和图标倒计数保持。更新战斗／整备／休息／牢房第1—6回合保护、第7回合失效、中途拾取及巡视续接的原行为用例；界面验证第2回合实际剩余5回合。
- 先ListOnly确认rewards及关联分类，再执行`tools/check.ps1 -Suite rewards -UI -UISuite rewards -TimeoutSeconds 600`。绿色小鸟全部边界断言通过；整批未全绿：正在修改的Boss遗物／Boss奖励接口使“直接赋予全部遗物后逮捕”“Boss掉普通稀有遗物”“旧battle_relic_drop字段”相关旧测试失败，共3项断言和1次脚本错误。本次没有改动Boss奖励逻辑，也不把该批记录为通过。日志：build/checks/20260911T051525241-31480/check-rules.log。
- 随后先ListOnly，再执行`tools/check.ps1 -UIOnly -UISuite rewards`，204项窗口断言通过，76.60秒；含真实回合推进、99保护、绿色小鸟图标剩余5回合和资源说明。退出码／引擎错误／完成标记门禁通过，未截图。日志：build/checks/20260911T052112172-45292/check-ui.log。
- README、AGENTS、游戏设计和内容模板已同步前6回合／第7回合失效；不增存档字段，不打包发布。

## 2026-09-11 正义飞踢

- 原站姿独立踢击打断更名为正义飞踢，基础2能量、15物理伤害；原打断、共享3回合冷却、身体倍率、力量／蓄力及体术减费继续沿正式候选结算。坐姿、并腿与其余形态保持原费用／伤害；动作栏、冷却说明和教程同步。
- `-Suite basic_attacks`及关联status、enemies通过1748条断言，日志`build/checks/20260911T051440093-17744/check-rules.log`。覆盖费用不足原子拒绝、实际15伤害、2能量支付、指定敌人延迟、姿势及共享冷却；初轮旧双敌测试仍按6伤害断言，更新为目标剩余9/24后重跑通过。
- 本轮附带窗口检查碰到同时编辑中的ui/main.gd临时解析错误，未计通过，已停止该失败检查进程。文件恢复后以`-UIOnly -UISuite basic_attacks`独立重跑，42条通过，日志`build/checks/20260911T051829899-29868/check-ui.log`。无布局修改，不截图、不打包。

## 2026-09-11 深呼吸预备能量

- 深呼吸保留原1能量费用、降低25快感和使用条件，成功时向现有next_energy增加Balance.CALM_NEXT_ENERGY=1。下一玩家回合由共用回合入口一次消费；不新增触发器、存档字段或专属清理。候选／动作栏、日志、状态来源、教程、练习与设计说明已同步。
- pressure新增真实行动覆盖：只读预览、当前扣费／次回合到账、重复使用累加、过期版本与能量不足回滚、快感不足25仍完整奖励、快感0禁用、抵扣过载惩罚、非战斗回合与当前快照恢复；pressure窗口真实点击深呼吸、查看预备能量详情并结束回合，验证实际4能量且预备计数清零。无布局变动，无截图。
- 首次先ListOnly，再运行pressure,status及关联分类，pressure136项与其他深呼吸相关检查通过；同批4项旧断言遇到另一批战后保留规则更新（event_flow／rewards），整批不记为通过。日志：build/checks/20260911T050208276-39164/check-rules.log。
- 当前代码复验：先ListOnly，再运行`tools/check.ps1 -Suite event_flow,rewards -UI -UISuite pressure,status -TimeoutSeconds 600`。规则6609项通过，175.38秒；pressure窗口56项通过。status一项旧完整状态比较随后由同批状态测试维护补齐summary排除，未修改其蓄力规则。该批日志：build/checks/20260911T050438765-29272/。
- 最后仅复验status窗口，先ListOnly，再执行`tools/check.ps1 -UIOnly -UISuite status`，55项通过，14.55秒；日志build/checks/20260911T050911113-33208/check-ui.log。相关失败均已复核，保留引擎退出码、错误日志和完成标记门禁。只改源码，未打包发布。

## 2026-09-11 卡牌伤害波及

- 新增card_splash规则与窗口分类。覆盖卡面成长后的50%基础、逐目标锁／堆叠／同层倍率、准确部位分组、最低紧度与并列随机、预览只读、旧版本拒绝、当前快照复现、多点物理件去重、免疫／外层／特殊装备手部及环境资格、遗物仅触发一次、主目标退款不复制与被动不递归。原顺延、肩带、躯干连接和链接测试按真实波及结果更新；未取消原边界断言。
- 波及随机专项：`-Suite card_splash -Exhaustive`通过143条断言，日志`build/checks/20260911T050526859-43080/check-rules.log`。
- `-Suite core,equipment,casting,rewards`覆盖37个分类。首次受同步中的资源保留变更及旧波及断言影响，未计通过；更新后的批次9590条仅链接波及测试将小腿／脚踝夹具对应反了（1处失败）。修正后重跑完整`-Suite links,special_equipment`及其交叉分类，5055条通过，日志`build/checks/20260911T050652916-23968/check-rules.log`；此轮也覆盖最后补正的特殊装备手部资格。没有宣称失败的综合批次整体通过。
- 实际窗口拖牌、卡面成长与奖励流程：`-UIOnly -UISuite card_splash,card_growth,rewards`通过217条断言，日志`build/checks/20260911T050306025-36932/check-ui.log`。首次奖励窗口沿用火球1能量的旧断言，已按现行0能量更新后重跑。无布局／美术变更，不截图、不打包。

## 2026-09-11 v0.12跨战保留：临时魔力20／蓄力2

- 变更范围：普通结束时临时魔力最多保留20点、蓄力最多保留2层。两项在战斗内获取仍无此上限，全部来源同等处理；乌龟壳通过uncapped_combat_retention解除两项结束保留上限。数值集中于Balance，Game提供只读保留查询，RelicEffects.end_combat在原清理时机应用。
- 状态／事务／迁移：删除旧charge_prepared来源份额，保留charge、charge_all和独立temporary_mana余额。沿原版本检查、资源反馈、结束与开场事务，不新增随机域或迁移旧档。入狱／既有续局重置、普通与全量蓄力触发、支付优先级、存瓶／购物资格和其他增益清理不变。
- 玩家文案：同步两种状态持续时间、遗物说明与实际保留量、卡牌关键词、教程及节魔卷轴。教程只讲通用上限，遗物例外留在遗物和实际状态内；不新增冗余日志。说明与README、AGENTS同批更新。
- 案例：0、低于／等于／超过上限、小数余额、两种遗物状态、全部场次类型、重复清理、获得与失去遗物、实际胜利→整备→移动→下一战、全量释放、开场遗物叠加、能力消失而所得资源保留、存档往返及入狱重置；对照断言除两项余额与空蓄力模式外，其他资源、装备、卡组、事件和随机状态与原结束处理一致。
- 首轮门禁失败：旧生命周期断言及同工作区并行的范围伤害测试更新中；失败日志保留于build/checks/20260911T045853917-30640/check-rules.log，不计通过。
- 第二轮已ListOnly确认的36个相关规则分类共9552项中，本批生命周期用例全部通过；仅链接波及旧夹具对应反了，综合批次1处失败，不宣称整批通过（build/checks/20260911T050254029-28896/check-rules.log）。夹具修正后重跑links及10个交叉分类，1566项通过（build/checks/20260911T050927208-30900/check-rules.log）。
- UI首次发现临时魔力夹具用了整数而非正式浮点值，序列化归一化影响完整快照比较；改为35.0且增加差异字段诊断，未放宽断言。另把旧拖牌“另一件完全不受伤”断言改为检查第二件为真实主目标、波及来源及两件低耐久都被解除，以兼容已接入的范围伤害。status窗口55项通过（build/checks/20260911T050744755-27264/check-ui.log），interface窗口261项通过（build/checks/20260911T050927208-30900/check-ui.log）。最终复测均exit0，无引擎错误；未生成截图、未打包发布。

## 2026-09-11 六缚与人形／机械饱和逮捕

- 共用EnemyPlans完整装备能力查询，移除六缚、玩偶师和捕缚类的无条件豁免以及六缚独立终局判断。检查真实普通／复合／特殊装备、链接、加固上锁、备用装备余额和其他存活敌人；无空间时生成下一项capture意图，沿原冻结、延后和收押流程执行，不产生饱和胜利奖励。
- Replacement预演排除装备／连接关系无变化的原样替换，忽略新编号与来源。普通、复合、特殊装备均覆盖；等值真实修复及不同款式继续合法。随机材质候选仅保留实际可替换款式，查询不改变随机域。保留原批次保护、失败回滚、版本复核、结构和链接检查，不增存档字段。
- 行为覆盖：最后一次加固后留出玩家回合、下一敌人行动收押、无捕缚条也可逮捕、首领必须击败标记不阻止收押、其他存活敌人仍有空间时继续、已离场来源不计、剩余备用复合件、新增锚定装备开放链接、当前快照保留预告。窗口以真实鼠标悬停捕缚图标并点击结束回合，验证简短说明、只读展示及实际captured界面；保留原打断和眼部受阻用例，无布局变动，未截图。
- 首轮发现旧同状态替换导致测试填满循环超时；随后检查揭示备用怪物夹具未使用fixed_members入口，以及新装特殊装备仍有真实链接空间，均已修正，失败批次不计为通过。
- 门禁：先ListOnly确认范围，再执行`tools/check.ps1 -Suite battle_saturation,enemies,guard,replacement,application -Exhaustive -UI -UISuite intent -TimeoutSeconds 600`。扩展随机样本（enemy_cycle 16／16、enemy_pool 24／24）及20个相关规则分类共8128断言通过，199.93秒；intent窗口40断言通过，17.41秒。引擎退出码、错误日志与完成标记均通过。
- 日志：`build/checks/20260911T044749109-44892/check-rules.log`、同目录`check-ui.log`。已同步AGENTS、README、游戏／装备／敌人设计文档及battle_saturation交叉分类；本批只改源码，未打包发布。

## 2026-09-11 并腿踢击共用冷却与躺姿代价

- 站姿并拢飞踢、坐姿并腿蹬击均携带fall并在真实攻击后躺下；原伤害10／5、站姿打断／坐姿不打断、1能量保持。第0踢击形态统一读取kick_cooldown，不再因坐姿无打断而跳过；沿原kick_last记录和cooldown_turns=2算法形成3回合使用间隔，即第1回合使用、第4回合恢复。横扫和第2形态不读写此冷却。
- 固定姿态捕缚无法满足躺下代价时明确阻止，不能静默免除代价；回身缎带沿原fell触发并更新对应说明。正式冷却状态、候选风险与完整文案同步，不新增状态、随机或存档字段；通风口独立次数不变。
- basic_attacks补充两种起始姿态、真实伤害／扣费／躺下、缎带触发、正式起身和三次回合推进、共享冷却防绕过、过期提交与固定坐姿捕缚回滚。UI补充坐姿踢击预览、实际落地、坐起后按钮禁用和状态提示。
- ListOnly确认basic_attacks／status及关联分类，规则4041项、UI96项通过，exit0且无引擎错误。日志build/checks/20260911T042338620-40924/check-rules.log及check-ui.log。无视觉布局改变，不截图、不打包。

## 2026-09-11 v0.12开发：火球术0能量

- BasicAttacks.TYPES.fireball.cost改为0；拘束具自解删除独立1能量常量，复用同一费用。敌人／装备候选、按钮与正式扣费同步，基础10魔力及其修正、伤害、施法概率、次数、复放和临时魔力不改。零能量火球的成功／失败对白在ActionCopy中按正式攻击类型选取，不再被能量费用门槛吞掉；行动日志继续只列实际支出。
- 新增0能量连续施放、伤害／耗魔／共享次数、魔力不足与次数耗尽拒绝、过期提交全状态不变，以及真实启用炫火后的0能量拘束具自解案例。界面检查按钮显示0能量且可用，并沿真实点击支付魔力。更新原失败施法、复放、减费隔离、拖放、键盘及日志中的旧能量预期；姿态测试改用实际右键切换后的坐姿踢击耗能，保留原能量不足门槛验证。
- ListOnly确认basic_attacks／casting及16个关联规则模块；最终5741项通过、无引擎错误：build/checks/20260911T041754069-24512。首轮暴露新测试持有旧事务对象引用及零能量施法对白被吞的问题，原失败日志保留于build/checks/20260911T041454194-21900，不记为通过。
- 窗口basic_attacks 37／keyboard 58／casting 210／targeting 63／action_copy 30项通过：build/checks/20260911T041731235-39560；该批interface的旧费用和形态选择断言失败，未将整批记为通过。修正后再次ListOnly并完整复验interface 260项通过：build/checks/20260911T042159936-39484。合计六模块658项，原资源、目标与次数断言保留。
- 规则说明、卡牌框架和AGENTS同步。不打包、不发布，不改已交付v0.11成品。

## 2026-09-11 v0.11 PC与安卓发布

- 按用户要求更新项目版本0.11；Windows EXE文件／产品版本0.11.0.0，Android versionName=0.11、versionCode=3，包名org.magic.spire和原发布签名保持。更新两平台导出脚本、成品版本探针及发布说明；Windows另附最新基础操作教学。游戏规则不改。
- ListOnly确认core／content／persistence及33个选入规则模块，日常种子矩阵8743项通过；touch／keyboard／home／targeting／interface／events六个窗口模块678项通过。退出0，无引擎错误：build/checks/20260910T194225390-12664。此为所列范围回归，不宣称all或normal_play长流程完成。
- Windows：outputs/spire-v0.11-windows-x64-20260911-v011；导出前后源码一致，外部12份内容包及授权文件齐全。PCK资源、主页、新游戏、练习、隔离存档保存／读取／恢复、开发脚本排除与独立EXE启动通过：build/package-check-20260910T194815532。
- 最终Windows ZIP：outputs/紧缚尖塔demo-v0.11-Windows64.zip，112436605字节，SHA256 bb4d5369e3750d924df0de8699cf78490e638ccee2daf061a45a0bd934b13420。CRC及清单逐文件SHA256一致，重新解压后PCK与EXE再次验证通过：build/package-check-20260910T194959383。
- Android：outputs/spire-v0.11-android-20260911-v011/spire-v0.11.apk，128603723字节，SHA256 f76ea80d450536fa009530dbb10de74633a5c4322a005c79b6eee295e3f3b9b0。发布签名、16KB对齐、AndroidX provider修复、启动入口、版本、ARM64／ARMv7和12份内置内容包哈希验证通过：build/android-20260911-v011。包内资源启动、新游戏／练习及隔离存档探针通过：build/android-probe-20260910T194843122。
- 两平台源码清单归一化后完全相同，且与最终运行源码哈希一致；包内无玩家存档、个人设置、开发工具或签名密钥。ADB无连接设备，未进行Android系统实际安装／启动或真机触控和性能验收；Android随包说明已明确此边界。

## 2026-09-11 卡牌说明精简

- 敏感的保留关键词由“自动保留”简化为“保留”。玩弄与玩弄＋仍是原有状态牌，六缚的混牌、留手快感和场次结束清理均不改变；只删除卡面末尾重复的“本场临时牌”。火动力学拘束面与对应能力状态统一显示“火球术施法成功率＋25%”，底层仍按原`chance_bonus=0.25`在倍率后相加并封顶。
- ListOnly确认rewards／casting及casting／home窗口范围。首次180秒规则进程在已完成23个模块且没有断言失败时超时，记录`build/checks/20260911T061222055-30532/`，不计通过；放宽至360秒后关联规则8255项、窗口319项通过，exit0且无引擎错误，日志`build/checks/20260911T061639472-34888/`。纯文案修改未增加镜像测试；未截图、未打包。

## 2026-09-11 堵嘴胶带更名

- 将普通口部胶带模板`mouth_tape`的玩家可见名称统一为“堵嘴胶带”；装备栏、事件结果、图鉴和敌人施加均继续读取同一数据名称。内部ID、材质、部位、生成池与规则不变，设计表中的旧称同步清理。
- ListOnly确认equipment及关联分类；规则5336项通过，exit0且无引擎错误，日志`build/checks/20260910T193414231-45108/`。纯名称修改不增加镜像测试；未截图、未打包。

## 2026-09-11 活化拘束具事件佩戴文案

- 普通单件佩戴正文拆分为人物协助与活化拘束具两套部位差分；通用事件效果以结构化`wear_style`冻结并保存选择，结果生成器按真实安装部位和装备名读取。人物亲手佩戴的缚疗修女、魅魔赌牌继续使用原文案；迷宫测绘队、缚梦客房和“拘束具堆里的微光”全部改为拘束具自行扑上、缠绕和收紧，不再出现“她替你佩戴”的动作。
- “魅纹师的空房”结果旁白删除“以后只要花掉能量”整句规则说明；淫纹效果仍由卡牌与状态说明呈现，事件正文只保留刻下淫纹时发生的动作和身体反应。内容字段校验与快照验证同步接受`assisted/animated`两个稳定值，未知值拒绝加载。
- ListOnly确认equipment／content／events及events窗口范围；关联规则6370项通过，日志`build/checks/20260910T192026740-22464/`；events窗口172项通过，日志`build/checks/20260910T192441372-30932/`。均退出0且无引擎错误；未截图、未打包。

## 2026-09-11 教程书精简与图鉴去重

- 删除教程“遗物”“敌人与意图”分类以及自动复制的卡牌、道具、遗物、意图、逐件装备与材料版本列表。图鉴继续提供原完整资料。原“道具与环境”改为“环境”，保留墙面、挂钩、安装与接触规则；原“卡牌与增益”改为“增益与关键词”，通用出牌操作归入操作，战后选牌归入房间。
- 力量与灵巧只说明伤害作用，移除丝袜例外；魔力、施法部位、蓄力、粗糙墙面、战后整备等不再夹带特定遗物、药剂或卡牌效果。删除重复关键词及抽取修正过程的长说明，保留通用条件、费用、概率与失败代价。顺手纠正教程旧存档说明为当前场景起点恢复。仅维护教程文案与展示，不修改卡牌、遗物、道具、状态或规则。
- 移除教程卡牌专用渲染分支；更新interface中旧“教程须收录全部卡牌／意图”的断言，验证删除分类和搜索结果、不再自动生成图鉴资料、保留通用增益及环境、图鉴四类内容仍存在，原输入／搜索／退出与状态不变检查保留。
- ListOnly确认interface窗口专项，完整260项通过，无引擎错误，见build/checks/20260910T191935885-66860/check-ui.log。本轮不截图、不打包。

## 2026-09-11 事件结果重复尾句补清

- 用户截图中的删牌结果已由report写出具体牌名，describe_result又追加通用删牌说明。清除删牌、换牌和解除所选拘束具的同义尾句；保留正文、实际日志、动态档位、资源数值及随机奖励。仅调整共享结果文案，不改候选、效果、随机或流程；content/README.md同步其编写边界。
- ListOnly确认events及关联分类；1790项规则、172项events窗口断言通过，exit0且无引擎错误，见build/checks/20260910T185433267-44924/。纯文案沿既有检查，不添加镜像测试；未截图、未打包。

## 2026-09-11 状态日志与事件注语精简

- 状态日志只记本次获得、增层、结束及实际数值，清理增生、无力化、准备就绪、仪式、狂躁、收束、玩偶、药剂和能力牌重复的效果说明。卡牌执行记录使用实际效果结果，状态窗口、卡面和判定数据保留。日志批次先ListOnly确认action_copy／status及关联分类，3968项规则、84项窗口断言通过：build/checks/20260910T183137029-37408/。
- 逐项检查12个事件及多阶段选项，按钮已写清的奖惩不再重复到注语；保留补充奖励、概率和有实际影响的后备惩罚。截图所示魅纹师空房只保留遗物与诅咒注语。普通结果收尾使用“离开”，跳过选牌和离开不再附带结算／状态保证。公共效果预告、默认奖励说明和事件入场日志同步精简；既有资格、费用、效果、随机冻结和流程保持。
- 内容包沿原detail字段支持显式空字符串，缺省仍自动生成简短预告；随机outcomes仍须提供非空公开说明。新增既有分类中的加载边界测试覆盖空值保留、非法类型、空白／超长／格式拒绝和随机预告要求。事件窗口检查空注语确实不创建标签，普通收尾只有一个按钮；无需新文案系统或按中文过滤。
- 事件批次ListOnly确认events／content及关联分类。首轮2710项中3项赌牌无装备分支预告断言失败，补回简短的“添加拘束具（自选）”后，event_flow完整330项通过；其余首轮模块均通过。日志分别为build/checks/20260910T184304427-46696/check-rules.log、build/checks/20260910T184517730-28992/check-rules.log。
- 首次事件窗口剩一项断言仍要求已删的“身上没有拘束具”标签；更新为检查“直接翻牌”、失败概率和真实新增惩罚后，events完整172项通过，exit0且无引擎错误：build/checks/20260910T184718220-68684/check-ui.log。本批截图0张；未打包。

## 2026-09-11 拖牌目标恢复按部位展示

- 按用户纠正移除拖起即生成的跨部位汇总栏和阻止部位更新的分支。只在对准的部位旁显示该部位目标，切换手腕／脚踝等部位立即替换；坐标统一转到游戏画布后对齐。卡牌与已有目标的道具行动共用部位栏，保留真实物理件去重。
- 部位内不可选目标仍显示并压暗，可选目标保持高亮；不可选原因及实际伤害沿原候选显示。仅修改UI选择和只读筛选，原候选ID／版本提交、资源、随机、规则与存档不变。基础操作教学、内置教学和AGENTS同步；不打包。
- ListOnly确认touch／keyboard／body_layout／targeting／equipment_complete。首轮触屏18、键盘58、身体96、装备96项通过；targeting有一项旧断言误将正常深呼吸悬停提示视作过期拖牌提示残留，见build/checks/20260910T182359429-2296/check-ui.log，整批不记为通过。
- 改为检查原目标及drag_reason提示确实清理，并增加真实拖到低亮目标后不扣费、不改状态的断言。再次ListOnly后完整复验body_layout／targeting共160项通过，无引擎错误，见build/checks/20260910T182634183-68436/check-ui.log。覆盖部位来回切换、按钮旁对齐、同区明暗、取消／非法落点状态不变、合法卡牌与道具恰好提交一次。已检查build/ui-body-target-brightness.png，手部仅含两件手部目标，外层高亮、内层低亮。

## 2026-09-11 删除事件立绘下方分类字样

- 从共享EventScreen移除立绘下方“奇遇”标签，所有事件页同步。仅删除显示控件，不改事件、选项、流程或数据；纯文案不新增镜像测试，不截图、不打包。
- ListOnly确认events窗口模块。首轮有两项阶段结果／装备归还断言失败，未据此修改规则或测试；同一版本完整复验170项通过，exit0且无引擎错误，见build/checks/20260910T181902366-56004/check-ui.log。首轮失败记录保留于build/checks/20260910T181622299-38396/check-ui.log，原因未证实，不将其记为通过。

## 2026-09-11 行动日志默认收起

- main.gd初始值与会话界面重置均设action_log_open=false。日志照常记录，右上入口和L键仍可打开；固定、栏外收起与普通刷新行为不变。仅本地UI状态，不改规则、存档或布局。
- targeting补充新会话默认关闭、入口可见与刷新仍关闭，并显式打开后复验原栏外收起／固定／手动关闭。ListOnly确认keyboard／targeting；完整窗口114项通过，exit0且无引擎错误。日志：build/checks/20260910T181035079-58796/check-ui.log。不截图、不打包。

## 2026-09-11 卡牌与遗物平衡调整

- 蓄势待发保留1能量／10魔力／嘴部条件：拘束消耗指定手牌获得3层蓄力，自由消耗指定手牌获得下一次体术减1能量（最低0，不叠加）。复用card_buffs和攻击完成钩子，正式候选、显示及扣费共用attack_cost；肘击／近身短打／踢击各形态适用，火球与姿态不消费。指定手牌复放保存原UID并复核，已消耗则跳过，不能再付出同一张牌或凭空获得收益。
- 专心致志按用户最终要求基础6、每次成长3，两面／实体／复放／场次清理沿原逻辑；强力肘击拘束抽1；强欲之壶保留0费抽2消耗、进入罕见池；魔血力量3、回合开始快感5；游丝指环在卡牌滑脱造成降档或直接解除时每玩家回合最多抽1，纯降档和无变化不触发。其余平衡建议不实施。
- 最小正例、版本／目标失效回滚、施法失败留手、临时魔力、嘴部阻止、减费各攻击形态／多段仅一次／0能量／火球和姿态隔离／重复增益阻止、现有快照往返及实际UI显示均覆盖。卡面、日志、状态说明、奖池和文档同步；未新增存档字段，不适配旧档，不截图、不打包。
- ListOnly确认规则rewards／casting／basic_attacks／card_growth及关联分类、UI同名模块。规则7682项通过，日志build/checks/20260910T174112350-20444/check-rules.log。
- 同批UI basic_attacks35、casting210、card_growth11项通过；rewards中一项仍预期魔血旧力量对应的10伤害，真实新值为11，导致该UI整批失败（不能记作整批通过）。修正该旧预期后，rewards完整194项通过，exit0且无引擎错误，日志build/checks/20260910T174632565-68484/check-ui.log。最终受影响UI合计450项已验证。

## 2026-09-11 新增架构与接口复查

本轮对照上次架构审查指纹跟进新增功能，静态扫描当前95个运行脚本；重点复查快捷键、全目标拖放、单件目标展开、牌堆浏览、腿部三形态、打断意图、事件战后整备、塔路一步离房，以及本日最新卡牌／遗物平衡调整。不进行旧存档适配，不打包。

- 静态扫描：198条字面量脚本依赖，无循环、core/data反向导入ui、UI直接读取game.state或缺失字面量资源；未发现至少5行的完整函数体重复。相对上次指纹有24个新增／变更运行脚本，本轮另更新内置教学。扫描不能证明所有动态调用和游戏组合都无问题。结果与审查前后指纹在build/new-feature-audit-20260911/。
- 修复1：DragTargets把payload.free误当作自由效果，双拘束面卡牌的第二面会把装备伤害显示在主角提示上。现在复用main已有的free_faces投影查询，保留真实装备目标及原拖放提交；不新增规则或费用判断。真实翻面／原生拖动用例已先复现错误，覆盖第二面、具体目标、取消及完整状态不变。
- 修复2：键盘模态边界遗漏商店付款演出，M/I/Esc能打开背后的地图、道具或菜单。现在共用main.modal_region限制快捷键和弹窗焦点导航；Tab及Enter只操作演出自己的原按钮，Android返回键也沿该按钮关闭演出，确认只改变本地已读标记。新增实际键盘用例已先复现背景导航问题，覆盖完整游戏状态及不得重复付款。
- 操作说明：基础操作教学.txt更新为拖起即展示全部合法目标、单件自动选择但不自动使用、可拖动道具行动选项、地图直接离房及PC快捷键；内置教学、keyboard-controls.md与AGENTS.md同步。无规则数值、资源公式、随机域或存档结构变更。
- 规则门禁：tower/events/basic_attacks/architecture及交叉范围4872项通过（build/checks/20260910T174146937-31300/）；最新rewards/card_growth及交叉范围6228项通过（build/checks/20260910T174440819-19848/）；教学更新后content及交叉范围1626项通过（build/checks/20260910T174607365-24056/）。相同模块取最后一次完整结果，去重共28分类7317项；使用日常抽样矩阵，不是exhaustive或all。
- 窗口组合basic_attacks/touch/keyboard/card_growth/route/services/targeting/intent/interface共1065项通过、退出0且无引擎错误（build/checks/20260910T174440819-19848/check-ui.log）。Android返回键共用边界后，keyboard/touch/services完整321项复验通过（build/checks/20260910T174847517-57056/check-ui.log），退出0且无引擎错误。两批相同模块取最后结果，去重共9分类1067项。
- 初轮新增商店测试误用了不存在的buy选项，已修正为真实take选项；该运行含引擎错误，不计通过。随后分别取得付款弹窗背景导航和第二拘束面错误提示的失败证据，修复后使用完整所选分类复验，未删弱断言。

限制：本轮不替代全项目完整回归。此前密集装备性能、完整普通游玩长流程及Android真机验收仍未结项；桌面合成触屏输入通过也不能替代真机验收。本轮未改布局或素材，不额外截图。

## 2026-09-11 PC快捷键与独立键位页

- 设置新增“显示／键位”分栏。默认数字键选手牌、R翻面、Space／Enter确认、Tab／Shift+Tab切换目标、E结束回合，基础动作及牌堆／状态／地图／日志快捷键见keyboard-controls.md。键位支持组合键、冲突提示、恢复默认、独立配置保存；Esc固定取消，结束回合可选长按0.5秒。
- 键盘只维护UI选择，合法目标和高亮复用DragTargets，实际行动继续使用原候选和版本复核。鼠标选择部位后按确认会使用该部位当前目标；鼠标原入口已经结算时，不再重复提交。卡牌、基本动作、蓄力切换继续调用既有右键入口；游戏状态变化、重开、加载、失焦与拖动按相应边界清理待操作状态。
- 文本输入不触发背景快捷键；窗口内确认沿原控件输入，覆盖复选框等原生行为。数字键不自动使用无目标牌，按键重复不连续付费；卡牌与常用按钮提示随改键更新。仅更新只读UI和本地键位偏好，不修改规则、随机、资源公式或存档格式。本轮不打包。
- ListOnly先确认范围。keyboard/home/interface/events组合812项通过：build/checks/20260910T171706685-37640/check-ui.log。随后键盘目标／鼠标同步和日志／身体开关补正，最终keyboard专项53项通过：build/checks/20260910T172224598-55212/check-ui.log。touch与keyboard共享目标接线复验71项通过：build/checks/20260910T172114391-54396/check-ui.log；显示设置21项通过，见build/checks/20260910T171353503-66056/check-ui.log中display模块。
- 初次组合检查曾出现长按未完成和旧测试只发送Esc按下、不发送释放的问题。旧窗口测试补齐真实按下／释放；键盘、触屏与普通窗口均完整复验，保持防连发、失焦取消、费用和完整状态断言。未将早期失败批次记作全通过。代表性键位页截图build/ui-key-bindings.png已检查，无重叠或底部控件越界。

## 2026-09-11 塔路离房与选点合并

- RuleChangePackage：depart复用原离房候选，在一个版本复核／原子事务内完成房间收尾与建立行程；地图只读投影复用同一候选。涉及整备／休息／整理、商店／宝箱及普通事件结果，离房日志、移动消息与可达节点同步。
- 不改费用、路程、travel_step、装备、奖励、随机域、存档结构或旧档适配。战斗／奖励／未完成事件与待整备事件结果、过载、续段、保留选择、容量、实际地图连线与特殊监狱返程继续阻挡。
- 案例对比六类房间的原两步流程与一步流程（除版本／日志外全状态一致），覆盖查询只读、非法路线回滚、一次提交、重复旧版本拒绝、超容量、过载、事件待整备及练习隔离；窗口以真实地图按钮验证打开只读和点击出发。
- ListOnly确认规则tower／services／events／rewards及自动交叉分类，窗口route／tower_progression／services／events。初轮相关规则模块均无断言失败，但新增事件夹具错误引用已删除的refuse选项导致塔路模块中断；改为当前真实事件credit选项后，tower及全部关联分类3527项通过，见build/checks/20260910T173507788-68400/check-rules.log。其余受影响规则模块的通过记录见build/checks/20260910T173117132-34516/check-rules.log，不把该失败批次记作整体通过。
- 窗口最终route／services共371项通过，见build/checks/20260910T173819834-43260/check-ui.log；tower_progression的51项与events的170项在build/checks/20260910T173507788-68400/check-ui.log中通过。初轮窗口失败来自整理阶段已显示地图却断言show_route必须为true，以及上批单件自动展开后仍断言原因隐藏，已改为实际地图可见／状态不变及正式不可用原因断言。本批无布局或素材变动，不截图、不打包。

## 2026-09-11 单件目标省略选择与操作高亮

- 仅修改UI：按真实物理ID合并部位条目，单件默认展开，选牌时单件自动选中但仍由原按钮提交；多件保留选择。DragTargets共用高亮／压暗与清理，资格只读取当前牌面正式候选。
- 覆盖单件／共享覆盖／多件、合法与不合法部位、资源不足、翻面不重建手牌、取消恢复、鼠标与触屏原生操作，以及选中不改资源／牌／随机、实际提交恰好一次。规则、事件、费用、随机域和存档无变化。
- ListOnly确认body_layout／targeting／equipment_complete／card_growth／consumables／touch／keyboard窗口范围；最终345项窗口断言通过、无引擎错误，日志build/checks/20260910T172015905-31596/check-ui.log。代表截图仅build/ui-card-target-focus.png，已人工检查单件操作与部位明暗。
- 旧手部拖动案例仍假定非法目标会进入全目标栏，已改为验证非法目标不进入拖动栏，同时通过真实点击路径检查压暗、具体原因及拒绝不扣费；保留原合法目标拖放与一次结算断言。过期拖动提示清理的组合断言拆分定位后，targeting专项与最终组合回归均通过。

## 2026-09-11 全部合法拖动目标与普通悬停分离

- RuleChangePackage：仅UI交互，DragTargets读取正式候选，按牌UID／牌面、动作形态、同源选项候选及当前版本取合法目标；装备按物理ID去重，人物／敌人与手牌各用真实目标。不增加判定、费用、事务、数值、事件、随机或存档字段。
- 卡牌开始拖动即展开装备框；攻击同时标示合法敌人，换姿势／自由效果标示主角，指定消耗手牌标示合法手牌。现有道具／挂钩／续段目标选项可沿原候选拖动；提交仍复核candidateId与版本。普通悬停不生成目标框，保留交互高光及意图详情。目标提示只显示原名称、效果和数值，非法目标不伪装成合法项。
- 取消、拖放、视图更新集中清理全部临时窗和高光，抽屉临时隐藏后恢复；UI查询不能花费资源或改随机。针对目标同步显示、实体去重、过期拖动、取消、原选项一次使用和悬停无副作用补充真实鼠标测试。
- 验证：ListOnly确认范围后，installed_tools／casting／card_growth／targeting／intent／equipment_complete联合窗口437项通过（build/checks/20260910T170627781-13212/）。并行目标简化合入后，最新targeting专项50项通过（build/checks/20260910T172017795-50248/），baseline完整基础窗口271项通过（build/checks/20260910T172122456-52896/）；以上成功门禁均退出0、无引擎错误。扩展检查中的equipment_complete 96项和prison 141项亦通过；该批总结果曾被旧基础用例及取消提示断言阻止，未冒充整批绿色，之后对应失败分类已分别修订并重跑通过。基础辅助按所选部位／物理ID定位全局目标，不再假定第一个图标就是当前部位；单件详情保留明确不可用原因。未改规则或运行规则全量。已查看代表截图build/ui-all-legal-drag-targets.png，确认手腕与脚踝目标同时显示、部位标签清晰、窗口在屏内。

## 2026-09-11 逐层抽离与接连挣动修订

- RuleChangePackage：仅修改peel的段数／顺延与chain的伤害类型，复用正式卡牌候选、逐段结算、固定点、目标随机域和事件；费用、稀有度、自由面、牌区、其他牌和保存接口不变，无旧档迁移。
- 玩家文案从规则表生成，卡面、悬停、图鉴、奖励及商店共用；设计文档和卡牌框架同步。
- 覆盖：两牌实际三段伤害／预览公式、滑脱3档免疫与挣扎区别、层级／区域顺延、提前结束、只付一次费用、蓄力与安装工具次数、压力和遗物整牌后触发。手动续段的规则／窗口／保存用例改用真实双重解锁；peel自动段不再等待选目标。
- 门禁：ListOnly后运行rewards／installed_tools／persistence及关联33个规则模块，8567项通过；casting／rewards／persistence实际窗口470项通过。最终退出0，无引擎错误，日志build/checks/20260910T164751563-63744/。未运行全项目回归，无布局／素材变化，不新增截图。初轮暴露旧卡面文案和旧滑脱测试假设，已同步修正并完整重跑所选范围。

## 2026-09-11抽牌堆／弃牌堆列表修复

- 根因：两个牌堆按钮都以默认deck打开浏览器，GameView只提供整副卡组列表。现在投影draw_cards／discard_cards的实际实体UID与类型，两个按钮分别选择draw／discard；共享DeckBrowser消费明确传入的列表。标题、数量和空堆说明同步，顶栏卡组和能力区保持原来源。
- interface新增真实点击测试覆盖空弃牌堆、重复同名卡、两个实际牌堆、完整卡组、空抽牌堆及正式抽牌／洗牌后的刷新；浏览前后完整游戏状态保持一致。只改只读投影及UI，不改抽牌、弃牌、洗牌、费用、随机或存档格式。
- 先ListOnly确认范围，touch/card_growth/status/interface共570项通过：`build/checks/20260910T165055854-55140/check-ui.log`。共用浏览器的能力区额外按casting完整分类复验207项通过：`build/checks/20260910T165206525-65204/check-ui.log`。合计777项，无引擎错误，未产生截图。
- 更新Android安装版本为2，沿用v0.1发布签名，成品在项目上级`outputs/spire-v0.1-android-20260911-piles/spire-v0.1.apk`。导出、签名、对齐、资源清单验证通过，最终APK包内启动及隔离存档探针通过：`build/android-probe-20260910T165328588/probe.log`。仍未进行安卓真机验收。

## 2026-09-11 Android APK与长按操作

## 2026-09-11 打断图标与原意图互斥

- IntentView优先投影delayed，停止展开原行动及附加图标；被打断时也不追加召唤当回合等待标识。保留原冻结意图、蒙眼隐藏和离场不显示的优先级；敌方正式回合清除delayed后正常恢复，不修改规则状态、延迟或随机。
- intent分类通过正式踢击、敌方停顿回合验证打断单图标、查询不变、原意图恢复；组合行动覆盖拘束／负面效果／加固附加提示全部被替代。intent窗口实际出手后检查控件仅剩打断、悬停短句、结束回合恢复原图标。
- ListOnly后运行intent及关联status规则214项、intent窗口35项，全部通过，退出0且无引擎错误。日志build/checks/20260910T163230563-63992/。无布局或素材变化，不新增截图。

- `ui/touch_input.gd`送入真实鼠标GUI路径：长按约0.5秒只触发一次原右键并显示完整当前卡面详情；点按、拖牌、滑动列表、第二指、取消触摸、释放防误触、返回键及手机显示设置均有真实输入／状态不变断言。桌面仍保留鼠标交互。
- 定向UI的display/basic_attacks/home/route/status共308项通过，`build/checks/20260910T160702373-57616/check-ui.log`；最终touch18项通过，`build/checks/20260910T161150359-39036/check-ui.log`。合计326项；首轮触屏测试节点名断言修正为真实StatusIcon_charge，未修改规则以迎合测试。
- 内容分类及交叉范围1600项通过，`build/checks/20260910T161035208-51836/check-rules.log`；范围先经ListOnly确认。沿用v0.1已有完整回归限制，不把本轮定向检查称为全项目回归或长跑完成。
- 成品`outputs/spire-v0.1-android-20260911-v01/spire-v0.1.apk`（项目上级outputs）：minSdk24、targetSdk36、ARM64／ARMv7，横屏。`build/android-20260911-v01/`保存v2/v3签名、16KB ZIP对齐、清单、内置JSON逐文件一致性和源码指纹。AndroidX provider修复前后清单比较仅其authority改变，其他清单事实保持；入口与唯一authority校验通过。
- 直接读取最终APK资源的主机探针通过：`build/android-probe-20260910T161713854/probe.log`，涵盖包内12份内容、主页、动态装备贴图、正式新局／练习和隔离存档写入／恢复。首次探针重复初始化内置包导致重复ID，已修正探针只在目标路径不同的时候显式初始化，不改游戏注册表。
- APK无玩家存档、开发代码、私钥及构建工具；发布签名在项目外。ADB没有连接设备，尚未进行Android系统安装／启动、屏幕字体、触控尺寸、软键盘与性能真机验收；包内说明和交付同时注明。

## 2026-09-11 全项目架构与接口复查：分类复验通过，完整长跑未完成

检查范围为整个独立 `spire-godot`，包括规则、数据、界面、场景／资源引用、内容包、测试入口与检查脚本。按9月10日重新启用的场景起点SL约定检查当前接口，不做旧档适配。

- 静态扫描覆盖91个运行时脚本（core 36、data 25、ui 30）、192条字面量脚本依赖；无循环依赖、core/data反向导入ui、UI直接读取game.state，未发现至少5行的完整函数体重复。337处字面量资源引用无缺失；18份JSON无重复键。静态扫描不等于穷尽动态调用或所有游戏组合。
- 修复实际接口遗漏：双拘束面目标悬停向共用damage_type传入所选牌面，第二面滑脱不再误标为挣扎；QuickSL结束判断改读已有ViewModel。新增架构边界检查覆盖实体成长、整备蓄力与全量模式、检查点深拷贝，以及商店结果与文案注册表的引用隔离。
- 精简冗余：删除无人调用的VisualTheme.key_material及闲置chroma_key着色器，源图保留；商店展示删除旧交易日志兼容分支，仅消费当前shop_trade；allow_links=false直接传入原EquipmentOffers.for_pool，不再生成全部链接后过滤。新增案例确认实际存在合法链接、普通请求与顺序保持一致、查询不改状态／随机，并且禁止链接时不查询物理锚点。
- 测试接线合并：规则与窗口路线共用RouteDriver.event_action，支持没有拒绝选项的现行事件；道具安装先打开现有入口，长列表先滚入视口再点击。更新实际费用、精简伤害提示、具体阻碍原因和商店练习阶段的过时断言；保留真实点击、拖放、费用、伤害及版本断言。普通试玩助手按只读自由效果事实区分第二拘束面，该长流程本轮未完成，不能记为绿色。
- 检查脚本修复已复现的并行启动文件锁冲突：build/.gdignore使用OpenOrCreate及共享读写，不再反复独占截断；失败消息附进程退出码。并行ListOnly均成功，超时与规则／界面运行时错误负例继续正确失败。
- README、内容扩展说明与美术历史记录同步；清理与现行场景SL、显示尺寸和共享版本常量冲突的旧说明。

| 验证范围 | 结果与证据 |
| --- | --- |
| 43个功能规则分类，完整随机矩阵 | 14307项；初跑仅商店练习阶段旧断言失败，日志 `build/checks/20260910T151143564-67304/check-rules.log`。修复后equipment_complete完整427项通过，`build/checks/20260910T151443140-57648/check-rules.log`。矩阵为16/16、24/24、201/201种子。 |
| runner分类及错误门禁 | 20项通过，超时、规则运行时错误、界面运行时错误负例通过：`build/checks/20260910T152107307-38340/`。与上述去重合计44分类、14327项；不含normal_play。 |
| 界面第一批6分类 | slip_motion/card_growth/wall/baseline/services/interface，1054项通过：`build/checks/20260910T150631620-60120/check-ui.log`。 |
| 界面第二批10分类 | enemies/equipment_complete/pressure/guard/prison/tower_progression/events/consumables/rewards/persistence，1039项通过：`build/checks/20260910T151221665-63900/check-ui.log`。 |
| 界面第三批20分类 | 其余20个非normal_play分类，1131项通过：`build/checks/20260910T152031830-43032/check-ui.log`。三批互不重复，合计36分类、3224项，均有完整UI PASS且无引擎错误。 |
| 资源导入与并行启动 | 导入成功：`build/checks/20260910T150157389-22536/`；修复文件锁后并行ListOnly：`build/checks/20260910T151251064-32824/`、`build/checks/20260910T151251070-38176/`。ListOnly不计测试通过数。 |

尚未解决：普通游玩在密集装备、巡视及抵抗战斗阶段明显变慢，局部取消无用链接枚举不能证明整体性能已解决。规则all从00:47运行到01:19，最新进度为seed=42、第700次行动、三级牢房（normal阶段已耗1822258ms），随后由本批主动终止；它没有完成标记，也没有跑完三条普通游玩种子，日志 `build/checks/20260910T144718597-62532/check-rules.log`。原窗口all进程在收尾核对时已退出，但日志没有normal_play或UI总体完成标记，退出原因未由日志确定：`build/checks/20260910T144752685-49584/check-ui.log`。该初跑也包含旧断言及本批早期测试助手调用错误；均使用后续独立分类复验核实，不能拿初跑局部断言推断整个窗口回归通过。

结论：扫描范围覆盖全项目，已修复本轮确认的接口、冗余和测试接线问题；44个规则分类与36个界面分类完成复验。完整普通游玩和整体性能仍是未结项，不宣称all通过或架构已经没有任何问题。当前扫描摘要与源码指纹见 `build/architecture-audit-20260911/`。

## 2026-09-11 拖动目标提示框收缩

- DragTargets.hint在最终宽度换行后，将高度重置为实际内容最小高度，保留原位置边界、说明和鼠标穿透。复用全部目标提示入口，未改变候选、伤害、支付或拖放流程。
- tools/check.ps1 -UIOnly -UISuite targeting -Screenshots ui-drag-clean-battlefield.png -TimeoutSeconds 300：完整targeting窗口分类51项通过、退出0且无引擎错误。沿既有真实火球拖动案例检查短提示高度不超过90且等于内容最小高度；人工确认唯一截图中提示为紧凑两行。日志build/checks/20260910T171932807-12272/check-ui.log。

## 2026-09-11 魔力松缚0费

- 共用card_rules中magic_slip.cost由1降为0，两面候选、卡面与教程均沿energy_cost读取。保留原魔力、条件与效果；更新既有施法失败案例，在0能量时实际出牌，验证仍扣魔力、失败留手且没有成功效果。
- tools/check.ps1 -Suite casting -TimeoutSeconds 360：完整casting及分类交叉覆盖共4240项通过，退出0且无引擎错误。日志build/checks/20260910T140845175-55704/check-rules.log。无新增截图或镜像测试，规则说明同步。

## 2026-09-10 顶部警戒等级

- HeaderSecurity位于距墙右侧，显示只读view.security；无新增状态或结算。沿interface现有run_header案例检查初值、变化后3级及与相邻文字／状态按钮不重叠，相关检查通过。
- 完整interface窗口分类执行461项，日志build/checks/20260910T135530037-63064/check-ui.log。整组未通过：并行新增shopkeeper.png当时未导入，以及原posture_controls要求按钮始终含“少耗1能量”，与当前紧凑布局仅stride>=48显示的实现不一致。本批已完成资源导入，未修改无关姿势布局／断言；不得将整组记为通过。

## 2026-09-10 魅魔的魔力典当铺插图接入与配图核对

## 2026-09-10 翘腿无视正式卡图

- 本地OpenCV／Pillow抠图，保留源像素和完整坐姿、饮料、吸管；精修座面阴影和手臂下真实背景空隙，白色丝袜与杯子反光保留。正式透明PNG登记到已有FORMAL_ART，原CardFace背景、比例、两面文字与测试版SVG保持。未调用imagegen，未修改源文件。
- 已查看暗色合成预览与实际卡面截图。home既有逐项画风检查追加正式图默认选中、RGBA透明、两面同图、测试版来回切换及游戏状态不变；未为纯素材新增规则测试。
- ListOnly后执行Import及完整home窗口检查，108项通过，退出0且无引擎错误：build/checks/20260910T134747394-49700/check-ui.log。唯一窗口截图build/ui-crossed-legs-formal.png，人物完整落在原插图区，无白底、座面块或拉伸。

- 用户提供的 `00093-2888790767.png` 原样复制到 `assets/art/event-succubus-magic-pawnshop-v1.png`，源图与项目副本SHA256一致；通过现有 `ARTWORK` 映射接入正式事件和练习，完整等比显示，不改变事件效果和文案。
- 先ListOnly确认events窗口范围，再执行 `tools/check.ps1 -Import -UIOnly -UISuite events -TimeoutSeconds 240`。纹理导入成功，完整events窗口分类163项通过、退出0且无引擎错误；日志 `build/checks/20260910T132922635-42664/`。复用现有检查，无新增截图。
- 核对当前 `content/packs` 中12个event定义与 `ui/event_screen.gd::ARTWORK`，全部已有对应插图；`data/room_events.gd` 基础表为空，事件来自内容包，无遗漏的内置事件。

## 2026-09-10 神秘女人的雕像插图接入

- 用户提供的 `00091-1968829285.png` 原样复制到 `assets/art/event-mysterious-woman-statue-v1.png`，源图与项目副本SHA256一致；通过现有 `ARTWORK` 映射接入正式事件和练习，完整等比显示，不改变事件效果和文案。
- 先ListOnly确认events窗口范围，再执行 `tools/check.ps1 -Import -UIOnly -UISuite events -TimeoutSeconds 240`。纹理导入成功，完整events窗口分类163项通过、退出0且无引擎错误；日志 `build/checks/20260910T132535194-42248/`。复用现有检查，无新增截图。

## 2026-09-10 缚梦客房插图接入

- 用户提供的 `00090-3863653336.png` 原样复制到 `assets/art/event-bound-dream-guest-room-v1.png`，源图与项目副本SHA256一致；通过现有 `ARTWORK` 映射接入正式事件和练习，完整等比显示，不改变事件效果和文案。
- 先ListOnly确认events窗口范围，再执行 `tools/check.ps1 -Import -UIOnly -UISuite events -TimeoutSeconds 240`。纹理导入成功，完整events窗口分类163项通过、退出0且无引擎错误；日志 `build/checks/20260910T132229627-41320/`。复用现有检查，无新增截图。

## 2026-09-10 玩偶师与召唤人偶正式立绘

- 用户00097-4167223127.png经本地白底遮罩生成1536×2304的enemy-puppeteer-formal-v1.png；31231231.png逐边描出人偶，去掉旁侧披风，生成331×430的enemy-puppet-formal-v1.png。未调用imagegen、未重绘源图；暗底检查白发、手指、面部、牵线及闭合白底空隙，保护原画高光。
- 两个正式图片登记已有FORMAL_ART，沿现有独立偏好与Arena／图鉴入口；玩偶师使用竖幅显示位置，召唤人偶沿原尺寸。原SVG保留。沿原召唤案例更新默认图断言，追加人偶独立切换且不改变召唤者图片的检查，不增加规则接口或玩法字段。
- tools/check.ps1 -Import -UIOnly -UISuite home,enemies -Screenshots ui-puppet-formation.png -TimeoutSeconds 300：完整home 103项、enemies 201项，共304项通过，退出0且无引擎错误。日志build/checks/20260910T134431772-58408/check-ui.log。只生成一张同场截图，复核人物和独立人偶均正常显示；无规则变更，不扩跑规则全量。

## 2026-09-10 六缚正式立绘与逐项画风

- 仅修改图片、显示偏好与共用绘图入口。用户提供的00095-2191451330.png经本地Pillow/NumPy遮罩及白底去色生成1536×2304透明PNG（约1.92MiB）；未调用imagegen，源图未改。首次遮罩误伤浅色皮肤，已修正并重新检查暗底预览及战斗画面，保留人物、六个法阵与半透明边缘。
- 图鉴按cards/enemies＋类型ID独立保存；正式图缺失时明确禁用，已有图默认正式版。沿现有display-settings.cfg保存偏好，CardFace/Arena按信号即时刷新，未增加游戏状态、行动接口或旧档迁移。规则数值、回合、资源、敌人身份、随机与游戏存档不变。
- 窗口分类display完整21项、home完整103项通过，包含独立保存恢复、图鉴来回切换、缺图提示及状态不变；日志build/checks/20260910T133048055-13712/check-ui.log。该批随后因新增敌人显示案例误用不存在的练习按钮失败，已改为复用现有six_bind_cases遭遇夹具；不增加生产入口。
- 完整enemies窗口分类复验199项通过、退出0且无引擎错误：build/checks/20260910T133248948-18720/check-ui.log。只输出并人工检查ui-six-bind-formal.png一张战斗截图；图片已导入。无规则变更，不扩大运行规则全量。

## 2026-09-10 拘束具堆里的微光插图接入

- 用户提供的 `00089-3699988499.png` 原样复制到 `assets/art/event-bound-adventurer-relic-v1.png`，源图与项目副本SHA256一致；通过现有 `ARTWORK` 映射接入正式事件和练习，完整等比显示，不改变事件效果和文案。
- 先ListOnly确认events窗口范围，再执行 `tools/check.ps1 -Import -UIOnly -UISuite events -TimeoutSeconds 240`。纹理导入成功，完整events窗口分类163项通过、退出0且无引擎错误；日志 `build/checks/20260910T131930895-43148/`。复用现有检查，无新增截图。

## 2026-09-10 缚疗修女插图接入

- 用户提供的 `00088-549235516.png` 原样复制到 `assets/art/event-binding-cleric-v1.png`，源图与项目副本SHA256一致；通过现有 `ARTWORK` 映射接入正式事件和练习，完整等比显示，不改变事件效果和文案。
- 先ListOnly确认events窗口范围。纹理导入成功；初验发现原窗口案例将修女固定为无图占位，已将该断言更新为实际贴图路径及等比显示检查，不新增用例或截图。初验日志 `build/checks/20260910T131441267-51972/`。
- 复验 `tools/check.ps1 -UIOnly -UISuite events -TimeoutSeconds 240` 完整events窗口分类163项通过、退出0且无引擎错误；日志 `build/checks/20260910T131647136-62828/`。

## 2026-09-10 女药师的试饮摊插图接入

- 用户提供的 `00087-1686288904.png` 原样复制到 `assets/art/event-alchemist-tasting-stall-v1.png`，源图与项目副本SHA256一致；通过现有 `ARTWORK` 映射接入正式事件和练习，完整等比显示，不改变事件效果和文案。
- 先ListOnly确认events窗口范围，再执行 `tools/check.ps1 -Import -UIOnly -UISuite events -TimeoutSeconds 240`。纹理导入成功，完整events窗口分类163项通过、退出0且无引擎错误，日志位于 `build/checks/20260910T131110739-63844/`；复用现有检查，无新增截图。

## 2026-09-10 魅纹师的空房插图接入

- 用户提供的 `00086-4247279898.png` 原样复制到 `assets/art/event-enchanters-empty-studio-v1.png`，源图与项目副本SHA256一致；通过现有 `ARTWORK` 映射接入正式事件和练习，完整等比显示，不改变事件效果和文案。
- 先ListOnly确认events窗口范围，再执行 `tools/check.ps1 -Import -UIOnly -UISuite events -TimeoutSeconds 240`。纹理导入完成，完整events窗口分类163项通过；日志位于 `build/checks/20260910T130548739-62972/`。复用现有检查，无新增截图。

## 2026-09-10 偷渡商人的魔药箱插图接入

- 用户提供的 `00085-558123539.png` 原样复制到 `assets/art/event-smuggled-mana-potions-v1.png`，源图与项目副本SHA256一致；通过现有 `ARTWORK` 映射接入正式事件和练习，完整等比显示，不改变事件效果和文案。
- 先ListOnly确认events窗口范围，再执行 `tools/check.ps1 -Import -UIOnly -UISuite events -TimeoutSeconds 240`。纹理导入成功，完整events窗口分类163项通过、退出0且无引擎错误，记录在 `build/checks/20260910T130237552-63248/`；复用现有检查，无新增测试或截图。

## 2026-09-10 迷宫测绘队插图接入

- 将用户提供的 `00084-4094280623.png` 原样复制为 `assets/art/event-maze-survey-team-v1.png`，源图与项目副本 SHA256 一致；`ui/event_screen.gd::ARTWORK` 以稳定事件ID接入，正式事件与练习共用，沿原画框完整等比显示。
- 在现有事件窗口用例中补充真实贴图路径与缩放方式检查，不新增截图。先以 `tools/check.ps1 -UIOnly -UISuite events -ListOnly` 核对范围，再执行 `-Import -UIOnly -UISuite events -TimeoutSeconds 240`；纹理导入成功，完整 events 窗口分类通过163项断言、退出0且无引擎错误，日志位于 `build/checks/20260910T125842194-45508/`。

## 2026-09-10 两张事件插图接入

- 将用户确认的二次元版废弃储物室、减少数量版漂浮皮带群复制到 `assets/art/event-abandoned-storeroom-v1.png` 与 `assets/art/event-floating-belt-cluster-v1.png`，两份原图与项目副本的 SHA256 分别一致。
- 仅为 `ui/event_screen.gd::ARTWORK` 增加两个映射，正式事件与练习共用原事件画框；沿原完整等比缩放与鼠标忽略行为。事件正文、选项、数值、状态、随机和存档不变，原赌牌立绘保留。
- 先以 `tools/check.ps1 -UIOnly -UISuite events -ListOnly` 核对范围，再执行 `-Import -UIOnly -UISuite events -TimeoutSeconds 240`。纹理导入成功，完整 events 窗口分类通过162项断言、退出0且无引擎错误；日志 `build/checks/20260910T125334872-58796/check-import.log` 与 `check-ui.log`。两事件的练习进入和原选择／结果流程均被现有分类覆盖；不新增镜像测试，不额外截图。

## 2026-09-11 v0.1 Windows打包

- 最终ZIP：outputs/紧缚尖塔demo-v0.1-Windows64.zip，113533282字节，SHA256为9447cc85334a8e868cce4746e686e8692d323f46b89f9d3c4fcd9d09ffe974e6。从ZIP重新解压后逐文件清单、成品PCK及独立EXE复验通过，日志build/package-check-20260910T155226293。包内附验证说明，未隐去长流程检查的未完成状态。
- 新增Windows x86_64发布预设，config/version=0.1，EXE文件／产品版本0.1.0.0。tools/package.ps1排除开发资源、复制正式外部内容包与授权、核对导出前后源码指纹并生成逐文件SHA256清单；未改变游戏数值、候选或事务。构建目录为上级outputs/spire-v0.1-windows-x64-20260911-v01，脚本拒绝覆盖既有目录。
- 正式模板来自Godot 4.7.2官方发布，下载TPZ与官方SHA256一致。EXE独立启动退出0，无引擎错误，已查看一张主页代表帧；中文、背景与主菜单正常。最终EXE／PCK与首轮实际启动文件哈希一致，验证记录在build/package-20260911-rc1。导出资源包验证通过12份内容包、动态装备JSON和纹理、新游戏、练习、隔离存档保存／读取／恢复及开发脚本排除；最终tools/check-package.ps1通过，日志build/package-check-20260910T154914924。
- 首次all规则与UI检查在normal_play长流程中持续耗时，规则seed42到500次操作已用829897ms，进入牢房战斗；只停止本次两项检查拥有的进程。原始日志保留于build/checks/20260910T152907426-65124和build/checks/20260910T152939020-63096，不声明这两轮整体通过。wall的一处安装菜单测试需避免把已展开菜单再次收起，已按实际展开状态修正真实点击。
- 其余分类补完：扩展随机矩阵规则14307项通过、退出0、无引擎错误，日志build/checks/20260910T154426046-24832；最后11个UI模块1092项通过、退出0、无引擎错误，日志build/checks/20260910T154426046-68132。结合首轮已完成且无失败的模块，共36个UI模块3224项；wall旧失败已由最终整分类复验解决。normal_play规则与UI仍明确为未完成，包内release-v0.1-validation.txt同步该限制。

## 2026-09-10 向墙移动放在坐下上方

- 战斗中的向墙移动位于右侧姿势列最上方，与坐下等宽、边缘对齐并间隔4像素。基础动作横栏仍为五项；坐姿有两个后续姿势时共享紧凑布局，保持在横栏下方、结束回合上方。非战斗入口不变。只重排原候选按钮，不改变移动资格、费用、回合、被动滑脱或提交管线。
- wall窗口检查真实移动、位置与费用、贴墙后的姿势、坐姿多按钮边界；旧安装测试同步实际展开菜单及重新打开日志。先ListOnly确认basic_attacks／wall范围，最终窗口77项通过，退出0、无引擎错误：build/checks/20260910T134930684-56444/check-ui.log。已查看本批唯一代表截图build/ui-basic-action-rail.png，向墙移动位于坐下正上方。

## 2026-09-10 种子标签

- 重新开始窗口的输入标签统一为“种子”，整数校验提示同步为“种子需要填写整数。”，说明改为“相同种子生成相同初始局面。”。仅修改显示文字，种子输入、校验和开局逻辑不变。静态检查ui／data／core已无“局面编号”和“同编号”旧表述；本次未运行游戏回归。

## 2026-09-10 专心致志与双拘束面

- 范围：新增罕见1费技能concentration、独立SVG、UNCOMMON来源；bound_modes／damage_growth声明双拘束面及本场按实体成长，原目标候选与预览、实际伤害、工具和复放共用。新增活牌damage_bonus，不改卡组；清理沿end_powers。验证非负整数及合法增量，快照拒绝坏成长数据；不迁移旧存档。
- 界面／文案：face_names／free_faces区分选择位和实际自由效果，手牌／卡组／动画读取card_instances的当前基础伤害，图鉴和奖励读取模板值；第二面复用选择部位→目标，不直接走自由效果，实际对白按滑脱动作选择。日志具名报告成长，两面共用数值。费用、回合、随机域、材料、层级、锁、身体辅助、蓄力、被动及环境规则不变。
- card_growth规则分类覆盖8→12→16、同名UID隔离、两面预览和实际伤害、拒绝不变、同场重抽、快照恢复／非法值、场末清理、休息第二面、无目标、合法免疫0伤、第二面免费复放与失效跳过。真实窗口验证右键、拖向人物后选择目标、只显示当前面目标、重抽数值、独立同名牌及卡组浏览。card_growth交叉区域含core／casting／equipment／rewards／content／persistence。
- 新卡规则20项、窗口11项初验通过。初验发现测试沿用提交前的旧卡引用导致重抽丢失成长，已改为按UID获取当前实体；窗口正文实际读取face_effects，因此为实例投影补齐完整元数据，并让动画使用真实UID。复放目标扩展仅用于带成长或双拘束配置的卡，保留原连续牌的三字段记录格式。已查看唯一代表截图build/ui-concentration.png，两面名称、伤害和独立实体显示正确。
- 最终card_growth／services／content及自动选入的交叉分类通过3969项断言、退出0且无引擎错误：build/checks/20260910T115431448-30572/check-rules.log。商店容量用例改为按实际剩余容量填充，而非假定初始背包为空；施法动作教程窗口断言同步现有的一只手自由文案，不修改遗物规则。完整casting／card_growth窗口复验通过211项、退出0且无引擎错误：build/checks/20260910T120235887-17512/check-ui.log。
- 额外通用UI检查未全通过，不能报告全量绿色：同批interface完成457项且无失败；baseline仍有9项失败，涉及事件固定拒绝／离开遍历（3项）、未展开工具详情的安装及后续损耗（4项）、链接悬停旧共享耐久文案（1项）、单手套挂钩旧结构提示（1项）。记录于build/checks/20260910T115431448-30572/check-ui.log；这批未改动相应事件、工具安装、链接或挂钩规则，需在相应界面维护批次核对。该日志中的另1项施法遗物旧文案断言已由上述211项复验解决。

## 2026-09-10 行动日志文案整理

- 文案批次：实付费用只读格式化，结果优先；统一施法成败说明、明确敌人剩余生命，精简开锁／解除／场次结束／遗物触发的重复规则。卡牌机械日志附带action_result用于侧栏，原计算正文与结构化倍率保留；移动读取已有被动滑脱摘要，遗物来源读取原relic_trigger。
- 不影响：伤害、费用、施法概率、随机域、候选资格、回合、状态清理及牌区去向；不修改已有正文包中的人物对白与事件叙事。历史摘要在提交时保存，不从当前装备重算；不做旧存档迁移。
- action_log_cases并入action_copy分类，覆盖实际失败施法、费用小数、各魔力来源、微量支出、留手、拒绝不变、只读重复投影、装备伤害短结果／完整公式、恢复历史、真实遗物退款来源和移动摘要。action_copy交叉关联补齐casting／equipment／slip_motion／rewards／core；窗口使用真实火球拖放检查结果和费用文案，无截图。
- 已ListOnly检查action_copy／casting／slip_motion／rewards／core及action_copy窗口范围。首轮合并检查7550项，唯一失败为新移动日志夹具使用了不参与被动滑脱的脚踝；改用既有大腿根夹具，并移除与该姿态正式候选不符的一格距离限制，只提交实际候选。其余分类未发现错误，日志build/checks/20260910T111034872-32796/check-rules.log。修正夹具后，完整action_copy分类通过60项，真实窗口通过29项，两项均退出0、无引擎错误且有PASS标记，日志build/checks/20260910T111417165-54236/check-rules.log与check-ui.log。无截图，未为通过测试修改移动规则。

## 2026-09-10 乌龟壳与蓄力保留条件

## 2026-09-10 道具图鉴

- items分类从Tools.TYPES枚举全部正式物品，按药剂／卷轴／工具分支，沿用名称／效果搜索与原图鉴详情。物品不显示无关品质筛选，复用ShopGlyph；详情含基础效果、次数、材料／条件、安装被动及免费丢弃规则。无领取或使用按钮，不启动新局，不写存档或随机。
- Tools.description、Consumables.description、InstalledTools.description提取纯effect_description格式器：背包与商店仍传入当前实际效果，图鉴传入注册表基础值。未修改使用判定、伤害或次数结算。百科分类关联installed_tools与consumables，既有基础类型收录断言保留。
- 规则检查1054项通过：build/checks/20260910T110430202-49392/check-rules.log。新增完整注册表收录、道具次数与共享效果来源检查；窗口通过实际导航验证分类、卷轴过滤、锯条搜索、具体数值／图标以及查看不改游戏状态。
- 首次窗口检查遇到另一批新遗物SVG尚未完成导入及工具整数展示格式问题；补齐整数格式并导入已落盘资源后，完整重跑home,installed_tools,services，251项通过，退出0且无引擎错误：build/checks/20260910T110610411-42188/check-ui.log。唯一截图build/ui-encyclopedia-items.png已查看，药剂／卷轴／工具筛选和道具详情布局正常，正文在详情滚动区完整显示。

- 默认所有蓄力在本场结束时清除，包含整备获得的层数。新增一般稀有遗物乌龟壳，通过retain_prepared_charge修饰与Game.retained_charge共用查询，仅保留尚未消耗的整备来源份额。此条替代下方无遗物时也保留整备蓄力的旧记录。
- 不新增状态、命令、随机域或存档字段；原charge_prepared继续记录来源，全量释放、普通消耗顺序、费用、伤害公式及入狱清除不变。奖励／商店／宝箱沿一般稀有池；新增独立SVG，状态、遗物悬停、卡牌关键词和教程同步说明条件与实际余量。
- charge_cases覆盖无遗物的战斗与整备清空、正式稀有奖励抽取、拾取不恢复旧层数、持有后整备→地图→战斗保留、混合来源优先消耗及结束仅保留原份额、全量用完、休息／牢房新得层数不保留。status窗口同时检查无遗物／有遗物说明、真实右键及遗物图标注册；旧整备奖励测试同步新清除预期。
- 分类门禁发现原整塔遍历器把“仍有能量但无合适攻击”当作错误，并只允许10次操作结束一场战斗；改用正式结束回合候选，保留30次操作的有界限制。终局断言同步既有“所有阶段可丢弃道具”入口，仍断言17个房间完成、每战一次奖励与终局；未改变游戏规则来适配遍历。
- 已先ListOnly核对status／rewards／services／core与status／rewards窗口范围，SVG导入成功。最终规则分类检查通过6970项断言、退出0且无引擎错误（build/checks/20260910T104933390-59168/check-rules.log）。同批窗口检查仅有一处旧status悬停断言仍要求默认跨战保留；rewards的181项完成且无该分类错误。修正旧预期后，完整status窗口复验通过56项断言、退出0且无引擎错误（build/checks/20260910T105428261-56708/check-ui.log）。已查看唯一代表截图build/ui-charge-all.png，乌龟壳图标、全量模式、伤害预览与3层可保留／4层清除说明一致。

## 2026-09-10 蓄力右键全量释放与整备来源保留

- 状态：charge仍为总层数，charge_prepared记录其中整备获得的余量，charge_all记录下一次全量释放。获取、计算、消耗和清理集中在Game；卡牌／能力／药剂／遗物共用，普通消耗优先本场份额。仅整备余量跨战保留，入狱／续局全部清除。
- 候选／事务：status_toggle使用原ID、版本复核及原子提交，零费用／零回合；无蓄力及终局无入口。伤害公式保留原材料、紧度、堆叠、锁、部位、环境、属性、肩带及链接倍率，体术保持原整次触发，逐段卡牌首个触发段用完后重新预览。失败／过期请求不消耗，纯倍率群体／被动／火球不新增蓄力收益。
- 界面／日志：战场图标与详情卡真实右键均可切换，全量模式金色强调；伤害预览、悬停、教程和卡牌关键词同步，状态说明分别显示两类余量。沿原行动日志与摘要、资源反馈，不新增叙事 cue；状态切换不改变资源、回合、牌区、装备、敌人或随机。沿当前快照整体状态，不开展旧档兼容与存档专项。
- status分类复用charge_cases覆盖7层释放、切回、普通／多段体术、挣扎／滑脱／捕缚、逐段卡牌后续不重用旧蓄力、火球保留、拒绝回滚、整备→地图→战斗、优先消耗与混合份额全量清除、休息／牢房清理；更新灵活变通、牢房出口与原整备夹具的旧保留预期。status交叉区域补充basic_attacks／equipment／guard／prison／core。
- 首轮8512项检查有2处断言失败：新切换测试漏排除正常更新的日志摘要；旧装备练习测试与同批已接入的“随时丢弃道具”候选冲突。已修正比较范围，并保留六回合结束、无塔路进度、仅允许通用丢弃的检查；未改练习规则或丢弃规则。
- 先ListOnly核对范围。最终`tools/check.ps1 -Suite status,basic_attacks,equipment,guard,rewards,prison -TimeoutSeconds 300`通过8515项断言，日志`build/checks/20260910T101331411-23748/check-rules.log`。`-UIOnly -UISuite status -Screenshots ui-charge-all.png`通过54项真实窗口断言，日志`build/checks/20260910T101239468-53588/check-ui.log`。两项退出0、无引擎错误；已查看唯一代表截图`build/ui-charge-all.png`，图标、预览和说明一致。

## 2026-09-10 魔瓶即时存取

## 场景SL（2026-09-10）

用户指定重新进入恢复场景第一回合，并新增菜单快速SL。scene_restart_cases并入persistence，检查同场景攻击／回合保持检查点、随机重放、过期拒绝、磁盘重开、商店付款与库存整体撤回、离店收益、牢房及战斗奖励边界。原精确快照测试继续保留；文件写入与窗口恢复断言改为场景起点。home/persistence窗口检查菜单真实点击、重新启动、连续牌撤回、事件选择撤回、文件错误与槽位隔离。先ListOnly核对persistence关联分类及home/persistence窗口；不新增截图。规则门禁通过7078项断言（build/checks/20260910T101244207-13248/check-rules.log）。首轮UI两项失败来自测试用普通按钮尝试重新打出拖拽牌，已改用真实拖拽重放；完整home/persistence窗口复验通过156项断言，无引擎错误（build/checks/20260910T101748543-37724/check-ui.log）。

## 2026-09-10 分辨率与三种显示模式

- ui/display_settings.gd通过Godot Window接口控制真实窗口，统一管理三种模式、当前显示器尺寸筛选、窗口居中、全屏返回尺寸与borderless标记。设置页复用原抽屉和控件主题，保留行动速度设置；原1600×900逻辑画布与keep比例不变。显示偏好使用独立ConfigFile，不修改游戏快照、资源、随机或回合；缺失配置保留默认窗口，越界尺寸按当前屏幕收敛，保存失败在设置内明确提示。
- 引擎接口依据：[Godot DisplayServer文档](https://docs.godotengine.org/en/stable/classes/class_displayserver.html)。全屏自动设置borderless，退出时必须按所选模式显式复原；全屏模式不提供无效的窗口尺寸按钮。
- 新display窗口分类测试真实1280×720窗口、无边框、全屏、返回有边框和原尺寸、选择前后游戏状态完全不变，以及隔离配置写入／新实例读取／异常尺寸回退。主页既有设置检查改用DisplayMode入口，显示测试恢复原窗口后继续主页流程；测试不读写玩家的真实偏好文件。
- ListOnly后完整执行display,home窗口分类，105项断言通过，退出0且无引擎错误：build/checks/20260910T100754218-20528/check-ui.log。已查看唯一截图build/ui-display-settings.png，720p下设置完整可见，三个控件与正文正常显示，无裁切或拉伸。无规则改动，未重复规则全量检查。

## 2026-09-10 墙缝安装二级菜单

- 道具栏将三个安装入口收为“安装到墙缝”，展开后显示低／中／高，分别提交原foot_wall／hand_wall／high_wall候选。展开状态复用原道具位置选择；同级使用位置互斥，切换物品重置。费用、可用性、具体原因、接触范围及提交复核不变，无规则或存档字段修改。
- installed_tools窗口新增默认收起、三个高度映射、正式可用性、展开／收起零状态变化检查；既有安装及触发继续验证真实结算。共享UI测试点击入口补上菜单展开步骤，牢房／嘴部安装／环境工具仍走原候选。
- ListOnly确认installed_tools,wall,exploration,equipment_complete,enemy_feedback后执行完整五类窗口检查，275项通过，退出0且无引擎错误。日志build/checks/20260910T100105938-38340/check-ui.log。仅生成并查看build/ui-tool-install-menu.png：菜单与低／中选项正常显示，高选项在同一滚动区；说明保留换行，无内容越出窗口。

## 2026-09-10 道具随时丢弃

- 单一item_discard候选由Game.candidates为全部真实道具生成，复用正式dispatch版本复核、原子移除与事件；删除行动阶段及商店重复候选。随身／已安装道具均可丢弃，无身体、姿态、触及或阶段限制，不扣资源或回合，不新增状态／迁移。各阶段道具栏与商店整理共用；无使用候选时只显示丢弃，不显示空目标选择。
- 新item_discard交叉分类关联installed_tools、services、prison、rewards、pressure、events。真实地图出发、休息开始、战斗结束、巡视进入、强制回合及多段续打等流程覆盖：候选唯一、查看不变、旧版本拒绝、只移除指定物品、资源／回合／随机／阶段及未完成卡牌保持不变、重复请求原子拒绝，原连续行动仍可完成。旧阶段锁定断言仅放行免费丢弃，原道具使用限制保留。
- ListOnly后运行item_discard规则及installed_tools,services窗口：286项规则、148项UI断言通过，日志build/checks/20260910T094933976-30216/。窗口使用真实点击从地图道具栏丢弃，并检查资源和回合不变；无布局修改，不另截图。
- 扩展prison,pressure,services,rewards分类共执行7125项，发现旧工具投影／商店描述与内容覆盖断言尚未匹配当前代码。更新后按失败分类content,installed_tools,services重新ListOnly并完整回归其关联分类，共3883项通过，退出0且无引擎错误：build/checks/20260910T095520277-46984/check-rules.log。初次其余分类均通过，未重复运行已通过且未变更部分。

- 存入／取出继续提交原候选ID与版本；仅修改ResourceFeedback的展示方式。成功后自身魔力条、战场魔力条及瓶内余额即时显示最新投影，不为转移排队飘字。旧行动／遗物记录保留浮字，停止对这两项余额插值；后续普通记录仍正常播放。
- 复用mana_flask_ui_cases验证真实连续存入、次数耗尽与取出，移除原9秒等待余额测试；另以致死火球的真实扣费／遗物返还队列验证存取后数值不回跳、旧浮字保留且呈现不修改状态。余额、次数、药剂资格／取整、购物、回合、随机和存档规则均未改变，无新增玩家文案或布局。
- 已先ListOnly核对范围；`tools/check.ps1 -UIOnly -UISuite consumables,rewards -TimeoutSeconds 300`完成216项窗口断言，退出0且无引擎错误。日志：`build/checks/20260910T094406605-59728/check-ui.log`。无布局改动，不截图。

## 2026-09-10 道具详细效果补全

- 问题来源：game_view只为药剂／卷轴填description，普通工具为空；安装被动也只在已安装后显示。现在Tools.description统一读取正式类型、伤害、材料与当前伤害倍率，覆盖切割、开锁和逃离工具；药剂卷轴沿原说明。商店复用同源说明，地图只读阶段保留完整效果；安装前可查看原InstalledTools.description，无候选不再显示空目标标题。
- 展示7点真实伤害、适用材料、当前剩余2次、使用耗1次、安装1能量／取回免费及安装后的牌伤触发。当前伤害有增益时同时标明基础值。未修改判定、消耗或伤害规则，也未引入可写状态。
- ListOnly仅installed_tools窗口分类，追加地图只读道具详情与商店同源效果、费用／材料／次数和查看不改状态检查；原真实切割、安装与出牌被动触发继续回归。`tools/check.ps1 -UIOnly -UISuite installed_tools -Screenshots ui-tool-effect-details.png -TimeoutSeconds 300`通过33项，退出码0。日志build/checks/20260910T094102253-20504/。
- 已查看build/ui-tool-effect-details.png：地图上打开锯条也可完整阅读基础与安装效果，正文在右侧正常换行，无空目标分组或截断。

## 2026-09-10 单手套与单腿套旧项目图片恢复

## 魔力预备卡面正文（2026-09-10）

恢复被临时魔力徽章过滤的reserve_mana效果正文，统一为“获得N层魔力预备”；保持+5／+10徽章与实际临时魔力。rewards下既有card_text_cases核对术式解锁正文、徽章及回合开始效果；casting窗口通过真实右键翻面验证正文存在和解释仍可悬停。先ListOnly核对关联分类，不截图、不改规则或存档；5594项规则断言通过，日志build/checks/20260910T093648989-42784/check-rules.log；casting窗口201项断言通过，日志同目录check-ui.log；均退出0且无引擎错误。

- 对照旧项目game/presentation/composite-restraint-icon.ts，确认正式图为structure-armbinder.png和structure-legbinder.png；当前项目已保留相同文件，SHA-256一致。只修正EquipmentImages的两条模板映射，装备目标与图鉴同步。未重画、裁剪或变更规则／存档。
- encyclopedia规则262项与home,equipment_complete窗口182项通过，退出0、无引擎错误：build/checks/20260910T093429173-35384/。直接查看旧图确认是用户提供的插画版，本次不重复截图或增加镜像测试。
## 2026-09-10 已有装备图片接入与图鉴同步

- EquipmentImages按稳定family补已有特殊装备图片；图鉴普通、复合、链接及特殊条目使用同一映射。用户确认只接已有图，因此硅胶棒系列三种品质复用旧图，其他特殊装备空图且保留名称。原文件复制后SHA-256一致，运行时只读本项目副本。
- 图鉴列表缩略图与详情完整图使用同一纹理，等比居中、限制边界；切换到缺图条目清除旧图。图鉴数据查询及浏览不更改游戏状态、规则、随机或存档。新增检查并入既有encyclopedia与home窗口，不复制装备机制测试。
- Import与初次图鉴检查通过；最终encyclopedia规则262项通过：build/checks/20260910T091512161-38776/check-rules.log。home,equipment_complete窗口183项通过：build/checks/20260910T091618740-58232/check-ui.log，无引擎错误。
- 仅截图build/ui-equipment-book-images.png，已查看列表与详情无越界，图片未拉伸。未运行all、未生成新美术、未发布或导出。
## 2026-09-10 滑脱原因区分与重复套体目标

- 套体受两侧肩带固定时明确提示先解除至少一侧；交叉肩带提示先松到1档。肩带条件满足后，外层遮挡提示真实部位与装备名称。_outer_cover_at提取原曝光检查中的遮挡对象，_outer_at沿原条件返回布尔；只调整原因表达与优先次序，不改变实际资格、数值、费用或存档。
- _body_card_actions将颈部既有去重推广至合并身体组：同一物理目标／牌面仅显示一项，优先保留已合法候选，自由部位仍保留原位置。候选ID／版本／正式提交不变，手掌与手指不再重复同一套体。
- 规则ListOnly后composites／links及关联分类1561项通过：build/checks/20260910T091341547-59836/check-rules.log。补充肩带与真实遮挡区别及正式解除肩带后改为手腕遮挡的案例；原案例一次挂钩只降档，修正为两次正式操作后确认实际移除。首轮牢房目录两项未过，诊断时当前初始化正确，同分类复跑已通过；本批未修改牢房规则。
- 同轮shoulder窗口17项、special_equipment46项、equipment_complete95项通过。新增body_layout窗口先发现测试仍读取提交前装备引用，改为提交后真实装备查询后，完整body_layout53项通过：build/checks/20260910T091533993-56544/check-ui.log。检查重复目标消失、真实原因、拒绝不扣费、不改随机、解除阻碍后原生拖牌正确扣费和伤害。最终相关进程退出0且无引擎错误。
- 已查看ui-hand-slip-reason.png，两个物理目标各显示一次、肩带提示清晰，未运行全项目回归。

## 2026-09-10 安全等级巡视周期

- PRISON_INTERVALS改为16／14／12／10／8，入狱初始化、检查后重置与校验使用共用表，去掉固定4级索引上限。练习描述读取首级周期，教程及game-design同步。5级仍沿原高安全监室终局，不开放新回合或迁移旧档。
- 新增1—4级真实回合边界用例：第N－1回合仍在牢房且剩1，读取不扣时，第N回合进入检查，正式inspect／accept／resume后重置同一周期。已有再次入狱、钥匙暂停、巡视反抗及练习断言更新；探索界面验证行动本身不推进计时。
- ListOnly初次受工作区依赖脚本临时无法解析影响，重新只读校验core/game后再次ListOnly通过。正式prison及关联分类3032项通过（build/checks/20260910T090939655-14656/check-rules.log）；练习目录equipment_complete补跑424项通过（build/checks/20260910T091146038-50680/）。
- 首轮窗口仅旧地图标题断言失败：此前布局已把“监狱 · 移动消息”精简为“移动消息”，更新为同时检查当前标题与真实map_name／region_name，未改游戏行为。最终 `tools/check.ps1 -UIOnly -UISuite prison,exploration -TimeoutSeconds 300`通过179项，退出码0，日志build/checks/20260910T091320864-42688/。

## 2026-09-10 阶段完成文案更正

## 顶栏运行信息（2026-09-10）

只读投影提供当前层数、阶段对应回合和战斗先后手；interface检查正式开场、变更后刷新、非战斗不残留战斗信息、牢房独立回合及距墙栏不重叠。ListOnly确认architecture规则与interface窗口，保留一张ui-run-header.png检查实际布局；55项规则、455项窗口断言通过，退出0且无引擎错误。日志build/checks/20260910T091120177-11388，截图build/ui-run-header.png已检查三项信息与距墙提示不重叠。

- 按用户最新要求，出口标题使用“第一阶段完成／第二阶段完成／第三阶段完成”；相关日志、结束选项、出口名称和阶段提示移除“试炼”。只修改文案，轮次、倍率、奖励和候选不变；删除未使用的enemy_health_multiplier视图字段。
- tower_progression规则141项及实际窗口51项通过：build/checks/20260910T085912640-24064/，退出0，无引擎错误；不重复截图。随后同步塔图名称“塔顶出口”和阶段摘要“当前阶段完成”。
## 2026-09-10 出口、三轮续局与首领固定奖励

- 出口正式候选提供结束／继续，第三轮仅结束。继续复用原监狱返塔的塔图重建，保留卡组、遗物、成长与随身物品，清除拘束／组件／链接／特殊装备和战斗临时状态，补满实际魔力上限；监狱返塔的原资源规则保持不变。demo_cycle与demo_finished使用当前快照修订33，不迁移旧档。
- 全部敌人基础生命按1／1.5／2缩放；已按父体实际生命计算的分裂子体不重复缩放，固定缝补仍＋5。Boss固定三选一稀有卡与一件未持有稀有遗物，耗尽为滚木，曾见未持有仍可获得。
- tower_progression收录续局、清装、保留成长、实际Boss奖励、分裂／召唤生命、非法版本回滚、快照恢复与第三轮终止；关联tower／prison／rewards／enemies／persistence，继续采用单次联合分类入口。首页已结束存档禁用继续但不报损坏，新游戏恢复第一轮。主页三条过时图鉴断言改为登记分类／实际筛选结果，不锁死数量或首条内容。
- 联合分类tower_progression,rewards,enemies,persistence,runner：7641项通过，183.21秒；日志build/checks/20260910T084731409-32240/check-rules.log。最终规则增量复验tower_progression：141项通过，日志build/checks/20260910T085450138-40688/check-rules.log。
- 最终home,tower_progression真实窗口检查133项通过，29.23秒，退出0且无引擎错误：build/checks/20260910T085607624-51156/check-ui.log。仅保留一张出口截图build/ui-45-summit-cleared.png，已查看；移除出口费用尾缀，清理之前的飘字／卡牌动画，标题和按钮无遮挡。续局重置原界面选择与地图画线，不另造游戏命令。未运行all、未导出或发布。
## 2026-09-10 捕缚条穿透状态窗口修复

- 根因是HeroGuardBind、数字、标签和GuardBindTarget分别使用246—248层，高于InformationDrawer的230层。移除这组特例，使其与战场魔力条使用默认层级；坐标、资源、正式候选及左下自适应不变。
- 复用guard正式敌人回合施加捕缚后，打开状态并选择捕缚详情，检查窗口覆盖原条形位置、全组层级、真实鼠标命中窗口及点击不改状态。关闭后检查原控件仍在原处可交互，再以原生拖牌验证实际损伤与支付。
- ListOnly确认status／guard完整窗口分类；85项通过、退出0且无引擎错误，日志：build/checks/20260910T085507868-47988/check-ui.log。已查看ui-guard-status-layer.png，状态说明中不再出现穿透的捕缚条；未运行无关规则或all。

## 2026-09-10 回合提示魔力小数修复

- enemy_feedback收尾阶段原先直接用%s输出浮点魔力，现复用game.number；18.6053240740741/100.0显示为18.61/100。仅格式化展示，不更改资源精度或结算。同步清除上一动作遗留tooltip。
- ListOnly确认enemy_feedback窗口分类，沿已有演出／跳过／隐藏动作／状态不变检查，不新增镜像文案测试。`tools/check.ps1 -UIOnly -UISuite enemy_feedback -TimeoutSeconds 300`通过42项，退出码0；日志`build/checks/20260910T085249043-47604/`。

## 2026-09-10 拖牌目标透明素材与伤害提示

- 检查同工作区旧项目PNG透明通道：已有透明套体special素材直接复用，30张普通材质图原为实色底，使用tools/prepare_equipment_icons.py本地去底色及环内空隙，保留高光和主体。本项目副本更新，旧项目不写入；未使用imagegen。
- 拖牌二级提示仅留装备名称与正式preview伤害数值／类型，工具切割单列，向下链接倍率已计入；删费用、装备参数及重复倍率说明。非伤害结果／整件脱下／实际不可用原因沿原候选。耐久40%／80%标记改为2px亮金线＋4px深色描边。没有规则、费用、随机或存档变化。
- ListOnly确认installed_tools／slip_motion／equipment_complete完整窗口分类，导入后136项全部通过，退出码0，无引擎错误；日志：build/checks/20260910T084809946-44880/check-ui.log。包括30张材料图透明背景与非空主体、挣扎／滑脱／附加切割实际预览、链接倍率及真实拖放一次扣费与损伤。
- 已查看ui-118-equipment-drag-card.png和ui-120-card-tool-bonus.png：多目标与附加切割提示紧凑清楚，图标无方形底色，分界线可见；未运行无关规则或all。

## 2026-09-10 准备类行动日志简写

- 警卫及共用捕缚准备正文统一为“准备捕缚。”，删除下一次行动、初始数值与叠加规则。_enemy_preparation不再自动拼接敌人名，避免重复；蓄力、法阵和停顿使用动作短句，actor标题与蒙眼隐藏仍沿原结构化来源。
- 纯文案复用已有检查，不添加镜像测试。ListOnly先检查enemies/guard广域关联，按实际文案范围收至action_copy/intent及自动关联status，窗口enemies。初次运行发现将idle统一成等待会丢失实际“动作落空”原因，已保留intent原结果正文，仅去掉重复姓名。
- 最终 `tools/check.ps1 -Suite action_copy,intent -UI -UISuite enemies -TimeoutSeconds 300`：195项规则与196项窗口检查通过，退出码0。日志 `build/checks/20260910T084544654-59108/`。检查包括蒙眼不泄漏准备行动、行动顺序、原结果记录及敌人窗口流程；不改游戏数值、状态、随机或存档。

## 2026-09-10 扩大地图与紧凑消息栏

- 地图主面板从(376,151,1172,650)扩为(376,68,1212,820)，右栏从365缩至约220px；剩余空间分配给地图。共享遗物条移入地图列顶部，保留悬停和计数，节点不受遮挡。总览纵向填满，按钮字号14，定位文字精简。无规则、候选、费用、随机或存档变化。
- ListOnly仅route窗口分类。新增主区域边界、地图宽高、消息栏宽度、遗物归属与不遮挡、悬停说明与状态不变检查；原右键绘画／缩放对齐／清除、左键拖图、正式前进、暂停和无连线拒绝回归通过。
- `tools/check.ps1 -UIOnly -UISuite route -Screenshots ui-map-expanded.png,ui-118-map-art-overview.png,ui-98-map-messages.png -TimeoutSeconds 300`：105项通过、退出码0。日志：`build/checks/20260910T083451182-29300/`。
- 已查看三张截图，详细地图、总览与旅行状态均无截断，消息正常换行，窄栏内旅行和地图按钮完整，遗物悬停可读。

## 2026-09-10 左下资源按捕缚状态排布

- MainResourcePanel保持原位置和高度，按真实view.guard_bind显示两行或三行：无捕缚时加大快感／魔力的行距及条形高度，有捕缚时三行等距收紧，清除后恢复。删除CaptureMeterSpace空占位，保留原资源控件ID、魔力悬停和飘字；魔瓶、能量和牌堆不移位。标题禁用自动换行，数字按实际条形高度居中。
- 沿consumables内原魔瓶窗口流程检查两行→三行→恢复、条形和文字不越界、名称／数值与条形同中心、魔瓶位置稳定及读取不改状态；原存取、实际捕缚、商店付款和动画仍验证。casting旧空占位断言更新为实际魔力条边界；guard沿正式回合及拖牌验证。
- ListOnly后完整casting/guard/consumables窗口258项通过：build/checks/20260910T083016440-60364/check-ui.log。截图发现自动换行使标签下移，修正短标签并补充对齐检查后，完整consumables窗口33项通过：build/checks/20260910T083325587-57336/check-ui.log。两轮均退出0且无引擎错误。已查看最终build/ui-mana-flask.png与build/ui-mana-flask-capture.png，无规则或存档修改，未跑无关规则或all。

## 2026-09-10 地图右键自由绘画

- RouteMap新增右键笔画与清除入口，只维护UI数组；按地图节点坐标归一化，保持缩放／滚动／重建对齐。地图外起笔无效，越界分段，地图外松手结束；原左键拖动、节点候选与版本提交不变。按地图拓扑隔离画线，同会话重开窗口保留，换局／载入清空。不涉及规则、随机、资源或存档变更；教程只补一句操作说明。
- 先ListOnly确认route分类；新增实际右键按下／移动／释放、节点上绘画无误触、滚动对齐、越界与重入、纸外释放、纸外起笔、总览／定位重建保留、教程遮挡、清除及新局重置检查。原合法路线、拖图不移动、拒绝无连线目的地和自动旅行回归继续运行。
- 首轮 `20260910T082832946-48776` 发现总览缩放的横向标记偏移；改为与节点同用115px侧边距的归一化坐标后复跑。最终 `tools/check.ps1 -UIOnly -UISuite route -Screenshots ui-map-freehand.png -TimeoutSeconds 300` 通过99项，退出码0，日志 `build/checks/20260910T082916132-60636/`。
- 已查看 `build/ui-map-freehand.png`：暗红笔画清晰，保持纸内裁切，右下清除按钮完整可用，无额外大说明框。

## 2026-09-10 现有卡图区放大与横向比例

- 共享CardFace上部图层改为牌高2/3，标题／费用覆盖顶部，正文在下部固定区域。用户进一步要求横向对齐后，将铺满裁切改为KEEP_ASPECT_CENTERED：卡图在标题下按宽高同时约束，完整等比居中，上下空余由原牌面背景衔接。保持原卡框及现有SVG，不使用ImageGen、不改卡牌数值／随机／持久状态。
- CardText改为ScrollContainer＋Content，保留全部效果、身体条件和不可用原因；正文过长时可滚动且共享悬停补充全文，翻面重置阅读位置。interface覆盖全部卡牌、两种卡宽、两面、图片区固定比例、完整素材无裁切、正文边界及实际滚轮输入；费用与法力徽记原位置／翻面更新检查保留。
- ListOnly确认interface及casting窗口范围。两轮检查因窗口被最小化而等待绘制帧，分别触发300秒／180秒超时；恢复且将测试窗口移出可见桌面后正常执行。build/checks/20260910T082536474-62276的casting模块201项完成，无该模块失败；同轮interface新增滚轮案例错误地选用内容已完整容纳的宽卡，导致断言失败。改用真实184×252手牌宽度，并先断言确有溢出，没有修改运行逻辑来迎合案例。
- 最终interface检查：`tools/check.ps1 -UIOnly -UISuite interface -Screenshots ui-72-unified-drawer.png -TimeoutSeconds 180`，447项通过、退出0、无引擎错误；日志build/checks/20260910T082911579-52300/check-ui.log。已查看牌组截图build/ui-72-unified-drawer.png：横向素材完整，牌名／费用／法力及下部文字未重叠。临时诊断输出已删除，未运行无关全项目回归。

## 2026-09-10 教程书统一简洁用语

- 精简88个教程正文条目、共享敌人术语和自动生成装备／道具说明；短句列条件、效果与关键数值，去掉反问、比喻、重复步骤及实现说明。分类、稳定条目ID、数据表插值与卡牌／遗物来源保持原路径；无规则、费用、随机或存档变更。
- 单手套特殊脱下说明按现有has_open_strap核对为至少一侧肩带解除，紧度百分比明确40%与80%边界。搜索提示同步缩短。
- ListOnly确认仅interface窗口分类。最终运行 `tools/check.ps1 -UIOnly -UISuite interface -TimeoutSeconds 300`，443项通过，退出码0；覆盖条目完整性、分类过滤、肩带搜索与焦点保持、空结果、关闭及浏览不改状态。日志：`build/checks/20260910T080420345-58232/`。纯文案不新增镜像测试，不运行无关全量或截图。

## 2026-09-10 地图取消悬停弹窗

- 按用户明确答复，RouteMap所有节点删除原生tooltip，不增加二级浮窗；保留鼠标／键盘高亮、连线、点击及拖图。route_view移除不再消费的description字段；房间候选短说明删怪物池列表、生成规则、种子与泛化精英教学。移动消息空列表不再显示操作说明，装备查看删除无效提示行；教程同步地图行为并精简过时的池与实现说明。
- 路线窗口沿实际输入等待原生提示延迟，验证所有节点tooltip为空、实际悬停无弹窗、状态和随机不变；原节点对齐、拖图不误出发、合法移动、无连线拒绝、暂停与换局计时检查保留。tower原房间说明检查改为短文案且查看不抽取敌人。
- ListOnly范围：tower/encyclopedia及自动合并交叉分类，窗口route/interface。首次build/checks/20260910T075510548-51720的规则检查有2项旧图鉴断言要求显示怪池“各50%”，因此整轮失败且未进入窗口检查；已改为核验真实皮带材质与分裂说明，保留此前所有实际抽取、分裂和保存边界测试。
- 最终build/checks/20260910T075737891-40672：3203项规则、531项窗口断言通过，退出0且无引擎错误；规则采用原日常随机集合，未运行all或Exhaustive。已查看唯一截图build/ui-map-hover-no-popup.png，悬停可前往节点时无底部长条或二级窗口。

## 2026-09-10 主页仅保留游戏标题

## 怪物图鉴文案统一（2026-09-10）

精简所有已登记敌人的图鉴正文，统一生命、开场／行动、特殊效果、出现位置；只读文本中的同名分裂子怪合并计数，捕缚说明共用一份通则，移除后台随机筛选及过期的练习限定说明。敌人定义、行动、数值、随机及存档均未改动；纯文案不新增镜像测试。先ListOnly确认encyclopedia规则及interface窗口，沿既有覆盖检查条目完整性、关键捕缚规则、只读性与图鉴入口。验证build/checks/20260910T075334248-52060：257项图鉴规则、443项interface窗口断言通过，退出0且无引擎错误；无截图。

- 左侧只保留96字号“紧缚尖塔”，移除宣传说明、开发提示、内容包入口及无人调用的弹窗处理器、徽记和分隔线；右侧菜单与存档逻辑不变，无规则或持久状态变化。
- 更新home现有标题断言，验证左侧控件只有标题、状态不变；启动、开始新局、继续、菜单入口和窗口缩放的检查均通过。完整home窗口分类运行77项，3项图鉴筛选断言未通过（分支全集、能力稀有筛选、遗物稀有度数量），未修改本任务无关的图鉴逻辑，也不报告全分类通过。日志build/checks/20260910T074916996-49700/check-ui.log。无新增截图。

## 2026-09-10 战场及窗口冗余提示清理

## 商店品质价格（2026-09-10）

卡牌15／25／40、遗物45／65／90，特殊遗物45。既有services分类增加实际生成商品的各品质价格、显示候选一致性及自身／魔瓶两种正式付款检查；窗口services核对每件商品的品质价和可见价签，复用原购买、容量、重开与宝箱免费检查。ListOnly选中consumables/shop_release/casting/services/rewards及services窗口，不修改生成池，无需扩大穷举或截图。检查通过：2525项规则、114项窗口断言，退出0且无引擎错误；日志build/checks/20260910T074101075-41596/check-rules.log与check-ui.log。

- 删除战场顶部drag_feedback控件及各拖放分支的有效操作长说明，固定动作拖拽只显示名称。错误原因复用TermExplanation，在实际目标旁显示，重复校验不反复建窗，移出／结束拖动清理；提交失败仍能显示notice。卡组、图鉴、奖励、事件、塔路、菜单和设置删除重复操作页脚，准备阶段教学行删除；可用手牌不再显示“可用”，失效原因、变暗状态及关键数值保留。
- targeting分类补充真实原生拖放：过期请求就地解释、复用浮窗、取消不扣费、正常火球对实际目标仅支付一次；casting沿原身体限制恢复流程验证恢复亮度并清除原因。仅展示变化，不改规则、候选、随机或存档。
- 初次ListOnly后完整运行casting/route/targeting/interface/guard/prison/events/rewards，共1247项。build/checks/20260910T073239702-30648/check-ui.log中casting有三次旧文案断言失败（强欲之壶两面仍要求无消耗说明、顺延仍找旧措辞），整轮不标通过；其余七分类完成且未报错。保留独立消耗词条与当前三级顺延说明，按现行文案同步断言。
- 最终ListOnly后复查受影响casting/targeting/interface完整分类，677项通过、退出0且无引擎错误：build/checks/20260910T073714127-56296/check-ui.log。其余五类首次完整检查共570项未报错。未运行无关规则或all回归。已查看最终单张代表截图build/ui-drag-clean-battlefield.png，确认有效拖放期间顶部无文字横栏、鼠标旁只有动作名。

## 2026-09-10 玩偶与玩偶师站位

## 卡牌悬停去冗（2026-09-10）

沿card_text_cases检查纯抽牌无额外术语／备注、检索只有共享短说明及原元数据完整性；沿card_power_ui_cases用实际悬停检查两面强欲之壶不再解释抽牌，仅保留消耗说明、魔路检索只有一句补充，并继续验证原抽牌／选牌／费用。文案只改data/card_text、balance备注与通用悬停组合，不改变规则。首次规则检查build/checks/20260910T073025039-21976只有henshin备注的固定短语断言失败；已在精简文案中保留明确的“同源不叠加”。同期强欲之壶改为0费消耗，复验073235551-6112中的纯抽牌测试因此需要区分抽牌与独立消耗词条；已保留新效果，并调整只读文案断言。最终复验build/checks/20260910T073539394-46376：5215项规则、200项casting窗口断言通过，退出0且无引擎错误；实际悬停和出牌验证通过，无截图。

- 战场本地展示列表把玩偶师排到右侧，召唤出的玩偶在左侧；完整EnemyGroup与点击／拖牌区域一同排列。只处理展示列表，不改GameView或真实敌人数组、行动及伤害顺序。
- 敌人窗口分类补充左右站位／点击区域及重绘不改状态、原敌人顺序的检查。先ListOnly后运行完整enemies窗口分类，197项通过、退出0且无引擎错误：build/checks/20260910T072123477-47272/check-ui.log。已查看单张截图build/ui-puppet-formation.png。

## 2026-09-10 状态合并与图标

- StatusView保持唯一只读目录，新增图标、角标、归属及是否常驻的展示信息；力量／灵巧合并手牌来源，姿态合并行动顺序／速度，咏唱合入口部。保留牌和同定义同触发时点的刺激合并说明，分别保留真实期限；同能力实体的进度全部保留，未合并计时器或改结算。
- 遗物重复条目及耳坠累计／腿足灵巧／姿态减免专用状态行移除；RelicEffects.view在原counter之外投影current触发机会及当前姿态减免，顶栏悬停读取。装备锁、肩带、连接限制继续由原装备详情提供。角色实际获得的蓄力和临时魔力照常显示。
- StatusIcon本地程序图案＋已有能力卡图供战场与总览共用；角色和敌人分别排列已有状态，头顶IntentView删除坚硬／分裂／玩偶保护重复投影。总览六列图卡、单一详情区，自适应高度；悬停／点击沿原术语浮窗与互斥抽屉，不改游戏状态。
- 原分类新增／更新读投影不改变状态、装备解除即撤图标、敌人离场、能力独立进度、来源完整性、图标归属／角标、实际悬停点击及遗物使用机会测试。trader窗口旧“不得进入强怪池”的断言与项目当前versatile_trader强怪组合冲突，改为验证弱池不含、强池包含，未修改敌人池。
- ListOnly：build/checks/20260910T070703520-24580。关联规则status/rewards/intent及交叉18模块5814项通过：build/checks/20260910T070723854-7060/check-rules.log。日常随机样本，未运行all／Exhaustive。
- 联动窗口初次1303项检查中两项失败：位置断言误取位于原点的容器而非动作按钮、玩偶说明断言查找未显示的“嘲讽”字样，实际界面分别已有正确位置与“单体攻击必须选择玩偶”。修正断言后，完整targeting/intent/status/enemies分类295项通过，退出0且无引擎错误：build/checks/20260910T071552365-60740/check-ui.log。前批其余trader/hand_assist/casting/wall/interface/pressure/guard/rewards分类未报错，不将初轮整体报告为通过。
- 截图检查补足单行状态总览高度，增加完整卡面不被滚动区域裁切的断言；最终status完整分类47项通过、退出0且无引擎错误：build/checks/20260910T071753435-24836/check-ui.log。已查看build/ui-status-icons-overview.png与build/ui-status-icons-battle.png。常驻练习长说明从战场移除，拖牌提示继续显示并在拖动结束复位，避免覆盖敌人状态或挤入行动轨道。
- 初轮规则与窗口报告不计为通过：旧独立状态行预期和测试练习名修正前分别记录于build/checks/20260910T065844692-11396、build/checks/20260910T070108971-23664。

## 2026-09-10 强欲之壶改为0费消耗

- 用户将强欲之壶改为0费、消耗；两面抽2张、普通技能与卡池保持原样。只修改SPECS.cost及既有CARD_TRAITS.exhaust，共用抽牌、消耗区、动画和卡面词条，不新增接口、状态、随机域或存档迁移。README、规则设定、卡牌框架及协作说明同步，此条替代历史1费正常弃置说明。
- 修改原有规则和窗口案例，覆盖双面费用、零能量仍可打出、实际抽牌及消耗区、满手限制、过期请求原子拒绝、悬停消耗解释及预览无状态变化。不追加重复测试或截图。初轮旧无关键词预期未通过，已同步为两面仅含消耗解释；同批还出现henshin文案断言失败，单独诊断当前源码符合原断言，未改其规则或断言，完整重跑通过。失败日志保留于build/checks/20260910T073147907-32844/。
- rewards及其完整关联规则分类5215项断言通过，日志build/checks/20260910T073453233-12084/check-rules.log，退出0、无引擎错误。
- casting完整窗口分类200项断言通过，含两面真实点击、卡面0费／消耗说明、悬停与实际消耗区，日志同目录check-ui.log；退出0、无引擎错误，无截图。

## 2026-09-10 拖牌装备图标目标栏

- 将拖牌大卡面改成贴着部位按钮的图片＋耐久条。两条细线显示40%／80%分界；栏宽随数量变化，最多三行后内部滚动。悬停复用只读候选中的伤害／费用／工具加伤／具体失败原因及现有TermExplanation，保留原DropTarget提交与版本复核；拖动期间隐藏原大详情框，结束恢复。未修改数值、行动条件、随机或存档。
- 复用旧项目原PNG，来源与缺图退回真实名称策略记录在assets/ui/equipment/SOURCE.md。architecture追加一项集中资源存在性检查，原投影隔离与随机不变检查继续通过；55项通过，日志build/checks/20260910T064850470-50572/check-rules.log。
- 更新原目标栏相关断言，改为实际悬停后读二级窗口。完整targeting、equipment_complete、installed_tools、slip_motion、special_equipment、shoulder、torso_binding窗口分类204项通过，日志build/checks/20260910T065120953-58776/check-ui.log；精确命中、费用、工具磨损、链接／组件及特殊目标均沿正式操作验证。只针对本次界面查看ui-118-equipment-drag-card.png，未开启全截图矩阵。
- 初轮equipment_complete保留了旧的单侧手部区域0级预期，已按项目已接入的任一侧计分规则改为1级，仍验证另一手能实际使用工具。扩大运行的baseline未通过：事件流程仍假设所有事件可以拒绝，休息工具夹具仍选旧foot_wall安装位置，共7项错误；日志build/checks/20260910T064850470-50572/check-ui.log。该批如实记失败，未改无关玩法或删断言，不将本次报告为全项目回归通过。
- 最后将目标栏高度增加6像素，避免单行出现多余滚动条；重跑equipment_complete完整窗口分类65项通过，无截图，日志build/checks/20260910T065249904-24724/check-ui.log。

## 2026-09-10 玩偶师与玩偶

## 基础动作栏重制（2026-09-10）

规则仅增加正式候选的简洁显示字段，不改攻击判定或结算。basic_attacks覆盖每种形态的单段数值与段数；窗口覆盖整行两端边距、五格等宽、轨道内包含关系、下方手牌间距、精简文本、右键切换、原候选点击／拖放、深呼吸与火球悬停。先ListOnly确认basic_attacks及关联enemies规则，窗口basic_attacks/casting/status/targeting；本轮美术验证只留ui-basic-action-rail.png一张截图。首次检查（build/checks/20260910T064548625-56284）规则1332项通过，窗口暴露整数伤害仍带.0及文本测试未去空行两项问题；已修正简洁数值格式与对应读取断言。复验build/checks/20260910T064822318-37092：规则1332项、窗口279项断言通过，退出0且无引擎错误；截图build/ui-basic-action-rail.png已人工检查整行占位、两行内容及手牌间距。

- 72生命人形精英进入第一幕精英池、图鉴和独立练习。T1召唤具有保护的10生命玩偶，T2添加嘲讽与受击反应；按最后修订，T3增加5生命上限并回满、T4准备复合装备、T5准备特殊装备，循环T3—T5。共享伤害入口处理生命下限、逐段反应和溢出转移，击败操纵者立即清除召唤物。现有装备施加／替换继续承担实际安装，不增加第二套规则。
- enemies集中覆盖正式召唤／循环、嘲讽原子拒绝、群攻、逐段伤害、零伤害、非攻击来源、准备消耗、缝补、操纵者死亡、单次奖励、快照校验及恢复后确定性；窗口分类验证独立练习、两种插图、保护／嘲讽图标、实际多段命中及T3回血。沿既有分类合并执行，不另建截图矩阵。
- 初次门禁发现遗漏独立练习注册，已修正；后续爬塔门禁发现路线测试的持续战斗夹具漏认人形敌人和玩偶师，导致随机路线停留战斗。只补充该测试夹具的既有类别列表，仍通过正式攻击／奖励／移动命令完成路线，不改变战斗数值或通过删除断言掩盖失败。诊断重跑路线无失败。失败日志保留于20260910T060313142-6664、20260910T060810784-55060及20260910T061428821-60636。
- 美术沿现有SVG注册表，已查看一次两种敌人的实际绘制合图build/puppeteer-preview.png；没有扩展截图回归。
- 最终相关规则分类合并检查通过7350项断言，日志build/checks/20260910T061815922-39068/check-rules.log。该批窗口首次失败是测试未先选择玩偶并翻到两段攻击，已补成真实鼠标操作；仅重跑受影响的enemies完整窗口分类，194项断言通过，退出0，日志build/checks/20260910T062209057-7564/check-ui.log。无引擎错误，不重复已通过的规则检查，不生成窗口截图。

## 2026-09-10 卡牌右上角魔力标记

- 即时耗魔／恢复与临时魔力点数共用右上角组件，负数为消耗、正数为获得；临时池使用紫色较小圆角样式，普通魔力为青色圆角样式。没有即时收支则隐藏。标题自动让位，左右翻面同步数字、颜色、显隐与原能量费用；效果正文移除重复的即时值，条件追加耗魔及回合触发保留。
- CardRules.face_mana_base与正式CardEffects.face_mana共享基础费用；CardText按效果数据整理face_mana，Balance.card_metadata向全部CardFace入口提供只读数值与分面正文。静态目录显示基础费用，运行时显示正式当前费用；临时魔力按档数乘既有5点常量，不改变真实付款或恢复。没有新增状态、随机或存档迁移。
- card_text_cases在既有rewards入口检查全部卡牌两面费用、动态／固定费用、普通及临时收益、整数格式、条件收益不冒充即时收益和投影不变性；casting真实翻面检查正负、池样式、隐藏与资源不变，interface集中检查所有卡片两种尺寸下的标记／标题／正文边界。原出牌、商店、奖励及动画交互继续检查。
- 首轮窗口数值断言发现默认数字格式带“.0”，已去除；保留了浮点费用精度和所有执行断言。规则复查同时遇到当前共享工作区的路线夹具遗漏人形持续敌人，原路线停在奴隶贩子／多面手遭遇；已确认最新共享route_driver补入humanoid／puppeteer，再运行原完整分类，不改敌人机制或跳过正式行动。
- 先用ListOnly选择rewards,casting及传递分类；UI选择casting,services,interface,rewards。仅本批两张代表截图用于实际排版检查：ui-107-card-casting-tooltip.png、ui-card-mana-badges.png；整数格式修正后不重复截图。最终门禁结果记录如下。
- 最终窗口 **917项断言通过**，退出0、无引擎错误，包含正式翻面、支付／出牌、卡组、商店、领取与卡牌动画。日志`build/checks/20260910T061714122-45756/check-ui.log`。
- 最终rewards,casting及全部关联规则分类 **6566项断言通过**，退出0、无引擎错误；日志`build/checks/20260910T061815045-60200/check-rules.log`。采用原日常种子集，无新增随机分支或全项目回归。

## 2026-09-10 卡面关键词与束缚等级

- 用户确认将区域综合等级改称“束缚等级”，并接入短词卡面、独立身体／目标条件及随翻面更新的解释。保留单件紧度、所有既有数值、费用、目标、施法与抽牌规则，无状态、随机或存档变更。README、卡牌框架、游戏规则、教程及协作说明同步。
- CardRules沿原效果数据提供compact文本，CardText只读生成分面关键词与限制；执行和展示共用face_casts。Hand／Book共用metadata；卡组移除旧说明拼接与重复信号，所有卡牌界面共用悬浮入口。浮窗记录所属卡片，在翻面时替换内容；旧浮窗隐藏、改名后延迟释放，避免连续替换导致名称冲突，也不在退出场景时同步移除节点。卡面按真实文本高度缩短插图，不裁切效果／限制。
- 原rewards分类新增分面正文、条件跟随数据、词条去重、投影隔离检查；原界面分类集中检查全部卡牌两面和两种尺寸，casting保留真实翻面／施法与身体条件测试，并检查长解释框边界。毕业证书相关断言更新为“挣扎9／滑脱9”，继续检查遗物加值真实进入手牌与卡组。
- 先执行ListOnly确认rewards,casting,status及传递分类。规则完整范围为consumables,basic_attacks,battle_saturation,architecture,event_flow,curses,encyclopedia,content,installed_tools,exploration,shoulder,slip_motion,casting,wall,special_equipment,services,status,rewards,core,prison,enemies,trader；日常样本，无生成器变化，不扩展随机矩阵。**6550项规则断言通过**，退出0、无引擎错误；日志`build/checks/20260910T054748184-21256/check-rules.log`。
- 首轮旧文案断言、卡组重复信号、界面夹具父节点类型及浮窗名称冲突均曾被门禁拒绝，未记为通过；已逐项修正，失败日志保留。`20260910T055337220-36564`虽完成942项断言，但退出时同步移除浮窗报错，外层门禁正确拒绝；修正为隐藏、改名及延迟释放后再检查。
- 最终casting,services,status,interface,rewards完整窗口分类 **942项断言通过**，包含真实翻面、施法、商店、奖励领取、状态、卡组与退出清理；退出0、无引擎错误。日志`build/checks/20260910T055701413-51700/check-ui.log`，本次不重复截图。
- 本批只截取并查看`build/ui-107-card-casting-tooltip.png`一次，用于确认真实手牌及说明框排版；不为每卡／每分支重复截图。

## 2026-09-10 卡牌数值、腿部目标与准备效果整合

## 魔力回路（2026-09-10）

新增2费稀有能力，复用能力区、两面资格、通用效果、实际付款与状态投影。rewards下的mana_circuit_cases覆盖两面并存和同面叠加、分批激活的独立余数、跨回合、两种魔力付款、失败施法、额外付款、一次跨多个阈值、后续身体受限、多段完成时发奖、复演与场次清理。casting/interface窗口通过真实翻面及点击，检查两张自由面效果、状态进度、禁用原因与拘束面出牌。沿既有当前格式校验记录必要字段，不做旧档适配。

按ListOnly确认rewards、casting、persistence及关联规则分类，新增稀有池使用Exhaustive；窗口限定casting、interface。首次检查build/checks/20260910T045804182-49896因新增测试夹具耐久大于上限而出现脚本错误，未记为通过；已修正为合法耐久及上限，保留原失败日志。修正后同范围穷举规则9555项断言通过，退出0，日志build/checks/20260910T050113296-5620/check-rules.log；casting/interface窗口609项断言通过，退出0，日志同目录check-ui.log；通过真实点击和翻面检查，无截图。

- 2026-09-10卡牌修订：一点点抽出基础滑脱5点，绷紧再挣基础挣扎4点；翘腿无视拘束面仅限腿部拘束具。术式解锁与双重解锁自由面改为1档临时魔力（5点），删除储备术式与开锁免能量。蓄力每层基础＋3同时用于主动挣扎、普通／魔法滑脱及原体术，每次命中消耗1层，多段逐段处理；被动移动与纯倍率群体效果不使用。找准松处拘束面改为获得1层蓄力、抽1张牌，无需装备目标；自由面仍先保留1张再抽1张。余势复演的相关说明统一写“拘束面”。
- 影响：卡牌数据与目标候选、正式数值预览／伤害／分段消耗、捕缚伤害、开锁和牢门费用、状态与资源反馈、卡面及教程、规则文案。移除reserve_unlock和slip_focus及旧专用focus方式，不添加替代状态或兼容支路；快照只更新当前格式。原抽牌管线、10张上限、自由面其他效果、随机域、奖励池、施法条件、环境／材料／层序倍率均不变。
- 更新既有rewards、core、prison、status、slip_motion及关联清理案例，加入腿部各槽正例／上肢反例、找准松处正式出牌、主动三类伤害增益与消耗、多段逐段消耗、免疫消耗、被动不消费、开锁优先使用临时魔力但不免能量。casting／status窗口验证卡面与真实点击，沿原分类唯一执行，无截图。
- 先执行ListOnly，再执行rewards,equipment,casting,status,guard及全部关联分类，**7696项规则断言通过**；casting,status真实窗口测试**214项断言通过**。退出0，无引擎错误；日志为build/checks/20260910T044519775-49700/check-rules.log与check-ui.log。采用日常种子，无生成器／随机分支变化，不扩展种子，不截图；规则书、卡牌框架、README与协作说明已同步。

## 2026-09-10 魔路检索总严密等级修正

- 用户更正自由面资格：上半身总严密等级≥1禁用。用已有free_max_levels={arms:0}替代逐槽free_slots；正式候选与提交共用level("arms")，没有新增规则接口、状态、随机或存档字段。此条替代下方首版的逐部位资格说明。
- 更新卡面、详情、README、游戏规则、卡牌框架及AGENTS。rewards案例覆盖总等级0／1、头嘴及下肢反例、单侧大臂三档但总等级0、捕缚最低1、提交前变化的原子拒绝；casting窗口验证眼部有拘束仍可用、总等级1禁用及实际拘束面抽牌。费用、抽牌词条和数量均保持。
- 验证完成：先执行ListOnly，再执行rewards完整关联分类，4664项断言通过；casting窗口165项断言通过，含413次真实鼠标事件。退出0，无引擎错误。日志位于build/checks/20260910T042421637-12720/。本批无美术或随机变化，不扩展种子、不截图。

## 2026-09-10 魔路检索与魔法／能力双词条

- mana_search为1费普通技能，不消耗、不判施法。拘束面定向抽1张、自由面抽2张；自由面与控火共用上半身精准部位列表及整数紧度检查。新增180×90透明检索书／放大镜SVG，按既有注册表进入共用卡面。
- 用户确认按卡面词条判定魔力牌。type_tags默认主类型，猛火下山明确登记magic+power；卡面、教程、图鉴、卡组筛选、类型计数和抽牌匹配共用此数据，主类型仍决定实体能力生命周期。抽牌沿原draw效果与Game._draw的可选filter.tag，从栈顶依序取匹配牌，不动其余牌；空堆正常洗弃牌，非空无匹配时停止，10张上限和逐张反馈保持。实际抽牌日志不把不足数量写成足额结果。
- mana_search_cases归rewards→card_power_cases唯一执行：普通池与费用、无消耗、双词条能力入手、保留未匹配顺序／随机不动、预览和版本拒绝、缺目标／不足／空堆洗牌／满手牌、精准上半身1档／0档与腿部反例、无魔力高压力下技能照常使用、复演、当前快照及定义拒绝。casting窗口真实翻面／出牌／查看牌组验证禁用与双分类；interface集中验证全部卡面插图、尺寸、教程和现有操作。
- 首轮Exhaustive完整种子检查8244项无断言失败，但零档口部装备夹具尚未走正式清理就枚举候选，产生4个引擎错误，整批记失败。修正为先执行共享清理，再检查自由面；enemy_cycle 16/16、enemy_pool 24/24样本均已完成。首轮日志：`build/checks/20260910T035954622-52640/check-rules.log`。
- 修正后的rewards,casting及全部关联完整分类 **6041项通过**，退出0，无引擎错误。日志：`build/checks/20260910T040203546-53652/check-rules.log`。未更改随机域或生成器，最终回归使用日常样本，保留首轮完整矩阵证据。
- 本批窗口casting,interface **567项通过**，退出0、无引擎错误；日志：`build/checks/20260910T040203546-53652/check-ui.log`。未生成截图，未运行全项目回归。README、游戏规则、卡牌框架与AGENTS同批同步；无新持久状态或旧档兼容工作。

## 2026-09-10 当前进度与架构接口跟进

- 本轮核对卡牌复演／多段顺延／能力叠加、临时魔力与魔瓶、遗物回合生命周期、休息前选择、事件和奖励入口。83个运行时脚本、167条初始脚本引用（最终164条）未发现依赖环、core/data反向依赖UI或UI直写game.state／调用Game内部写方法。最终静态资源字面引用768项未发现缺失；内容包12份、模板5份经原校验器通过。
- 删除Game._play_card单调用转发，正式card分支直接调用Cards.play；删除无调用的Prison.DISCOVERIES旧正文表，折返符真实定义仍在FieldTools.TYPES。清理9个无调用旧常量：AFTER_BATTLE_MANA、BASIC_ESCAPE、NORMAL_ATTACK、HEAVY_ATTACK、BLINDFOLD_HP、CHAINS、EVENT_ADJUST、EVENT_WAGER、COLUMNS。真实卡牌／攻击／敌人／事件／地图定义及数值不变。
- 跟进上轮链接转接性能：把空候选列表作为必然损失，结合可保留数量上界和已见损失集合剪枝；不同损失集合、方向额度和首次合法结果继续保留。新增真实三链接、三替代连接点用例，旧实现21次连接点查询触发性能断言，修正后不超过12次，保留结果、顺序、状态与随机不变。原方向配额／损失比较／原子提交用例继续执行。此为具体重复计算的修正，没有据此宣称密集装备整局性能已解决。
- 架构专项由31项扩充到54项，复用一个投影契约检查器；casting与tower加入其交叉归属，分类选择runner 20项通过（200105830-55436）；新增正式打牌建立的双重能力、待复演和临时魔力组合，再验证场次清理、冻结休息选择和正式开始休息。检查重复查询不改变状态或随机、视图没有可变引用泄漏、候选ID唯一且稳定。未新增运行时状态、玩家命令或检查框架。
- 修改前相关24个分类6272项通过，日志build/checks/20260909T194624490-54464/check-rules.log。新增性能用例首次因测试插入位置错误产生语法错误（194817784-54892）；修正后准确复现21次冗余查询并仅性能断言失败（194829500-14704）。修正算法后相关24类6300项通过（194929834-53284）；以上失败日志保留，不记为通过。
- 旧常量清理后，architecture/core/links/pressure/tower及关联28个分类6995项通过，118.13秒，退出0；日志build/checks/20260909T195133543-52656/check-rules.log。采用现行日常样本：enemy_cycle 4/16、enemy_pool 4/24、tower_graph 7/201；没有修改生成算法或种子集合。
- casting/services/status/interface/rewards五个窗口分类854项通过，退出0、无引擎错误；日志build/checks/20260909T194955105-15928/check-ui.log。保留真实输入、动画与状态检查，无截图。
- 检查期间接连挣动的拘束面在共享工作区改为三段滑脱并自动顺延。追加检查195401885-38044准确发现旧手动续段案例换用peel时误把payload.kind也改为peel，导致候选为空及后续越界；此轮失败，未进入窗口阶段。正式续段命令仍是chain。并行任务于05:55:28同步修正规则筛选和窗口夹具，保留手动peel与自动顺延chain各自验证；本任务没有覆盖新规则，也未重复改写已修正文件。最终当前定义的rewards及关联13个规则分类4546项通过，无引擎错误，复用共享工作区日志build/checks/20260909T195554335-54280/check-rules.log；同批casting 142项、rewards 179项无断言失败，但该并行任务额外的存档窗口失败导致整轮UI退出失败；本轮没有检查或修改其存档问题，也不把这次整体失败记为PASS。另用仅含casting／rewards的窗口检查独立确认，321项（142＋179）通过，112.69秒、退出0且无引擎错误；日志build/checks/20260909T200009099-12476/check-ui.log。与此前services 98／status 32／interface 409项合计，本轮五个非存档窗口分类最终分批860项通过，不将重跑项重复相加。

存档专项继续延期到整个Demo完成后，本轮没有修改存档实现或专项案例。采用现有受影响分类及日常种子，没有宣称全项目all或完整随机矩阵通过，也没有重跑上轮三条耗时正常试玩。未改UI布局／美术，不新增截图、导出或发布。README、AGENTS和内容扩展文档同步；最近两处并行记录错位的章节标题已归位，历史内容与失败记录保留。

## 2026-09-10 四种漂浮敌人插图

- 按用户收窄后的范围，只替换漂浮绳索、漂浮皮带、漂浮锁、漂浮口球的旧素材。新增4张640×640透明SVG，采用与卡面一致的哑金／冷青及平滑轮廓；其他简洁程序绘制和魅魔警卫原立绘不变。共用arena控件的战场、练习、图鉴同步生效。
- 删除旧敌人图集加载、区域映射、裁图函数与无用抠色分支，未删除原资源文件。保留现有悬浮、淡出、尺寸适配、拥挤缩放和点击目标；无规则、状态、数值、事件文案或存档变更。
- enemies既有分类集中检查四种实际定义的透明且独立纹理、半尺寸显示、平滑采样、无抠色、不拦截输入、inactive淡化及不改状态。受影响窗口分类一次验证：`tools/check.ps1 -Import -UIOnly -UISuite enemies,guard,hero_art -TimeoutSeconds 300`，**236项通过**（enemies185、guard27、hero_art24），退出0，无引擎错误。日志：`build/checks/20260909T195419225-47060/check-ui.log`。没有运行全项目或截图测试。
- 人工核对单张4敌人总览：`build/floating-enemy-preview.png`，实际arena渲染完整且无裁切。用户警卫原图修改前后SHA256一致：紫色B26789330D06D718CF2C3706263F0858E3EE721AC392DB60BC3B6CEB45E38148；棕色598562AE70145A1A2C882796F9626AA5D0321163E2A9E2861A43A610A217D1D2。

## 2026-09-10 默认卡面插图替换

- 范围：23张复用怪物素材的卡牌及原程序绘制的火焰精通，共新增24张原创SVG；保留此前11张独立插图。共享CardFace现覆盖35张内置牌，删除怪物贴图回退、抠色材质和火焰精通特殊绘制分支。
- 无数值、候选、事务、日志正文、随机域或存档变化。卡牌名称、费用、描述、稀有度边框和操作保持原投影；美术映射统一作用于所有既有卡牌入口。
- 在既有interface_ui_cases集中加入4项覆盖检查：所有真实登记卡牌都有图；非空且不重复使用同一纹理；190/290两种卡宽与双面下均在图槽内且不拦截输入；展示不改变正式状态。未新增逐卡测试文件或完整规则回归。
- `tools/check.ps1 -Import -UIOnly -UISuite interface -TimeoutSeconds 300` 通过：**409项**，退出0、无引擎错误。日志：`build/checks/20260909T194548912-14248/check-ui.log`。
- 仅渲染并人工检查一张24图总览：`build/card-art-preview.png`，各图轮廓、颜色、缩放和中文名称清晰，无裁切。总览脚本及图片留在忽略的build目录，不进入游戏运行逻辑。

## 2026-09-10 连续挣

- repeated_strain为1费普通消耗技能，base=1／hits=5／follow_through=true，自由面增加2层charge。仅用原数据字段登记普通池、两面文字与原创SVG；顺延与牌区结算不另造逻辑，也无新存档字段。规则书、卡牌框架、README和AGENTS已同步。
- 在follow_through_cases增加普通品质与真实池成员、两面费用／消耗、五次实际基础1伤害、一次消耗动画、费用不足整份状态不变、精准点→大部位→区域、提前结束不跨区以及消耗后的当前快照恢复。casting窗口通过两面真实拖放验证1费、数值、消耗区与文本高度。
- 本次完整种子检查中新增连续挣案例通过，但并行开发的余势复演出现3项失败，因此整轮失败，见build/checks/20260909T194011928-38112/check-rules.log。随后共享工作区联合规则检查已通过5950项，包含rewards1090项及相关分类且无引擎错误，见build/checks/20260909T194142849-51972/check-rules.log；复用该已完成结果。
- 同期拖牌入口改为候选ID区分同一装备的多个行动选项，窗口助手仍按物理ID查找导致1项报错。reveal_drop_target现可从正式候选payload.target定位物理目标，或直接使用候选ID，不按控件文字猜测。修正后本任务单独复查casting窗口136项全部通过，退出码0，无引擎错误；日志build/checks/20260909T194343851-45204/check-ui.log。未生成截图或运行全项目回归。

## 2026-09-10 余势复演

- 新增1费罕见技能echo_cast，原控火保留。自由准备下一火球，挣扎准备下一张双面不同的挣扎面牌；只复放原目标，失效跳过。统一复用卡牌效果／攻击／施法及正式费用管线，复放不额外移动实体卡、扣能量／魔力／火球次数或计技能出牌。能力复放保存一张卡的两重效果，连续牌保存已执行目标序列；当前快照校验同步更新，无旧档适配。
- tests/echo_cast_cases.gd由rewards→card_power_cases唯一接入。覆盖费用、原控火保留、两面与排除、预览只读／过期回滚、失败留手、独立施法、猛火下山抽牌、余火消耗后的重算、群体及装备火球、致死跳过、工具每牌一次、技能计数、上下层不改目标、多段与顺延、重复能力回合效果、跨回合／场次清理、连续状态恢复及坏字段拒绝。窗口casting沿真实翻面／点击／目标操作，校验名称／稀有度／文字高度／费用／伤害／状态消失。
- 初轮完整种子检查8093项无断言失败，但新夹具当前耐久30误配默认上限10，产生1个引擎错误，整批失败；第二轮8153项有3个夹具断言失败：自动续段被误当作等待玩家、低紧度外层用了不满足最高紧度资格的挣扎。均已改为正式合法夹具：显式耐久上限、需要选择的双重开锁续段及滑脱外层。两轮完整enemy_cycle 16/16、enemy_pool 24/24种子均已跑完；不能把失败批次标成通过。
- 最终受影响完整分类rewards,casting及关联分类 **5950项通过**，退出0、无引擎错误。日志：`build/checks/20260909T194142849-51972/check-rules.log`。此前完整种子矩阵日志：`build/checks/20260909T194008465-8004/check-rules.log`；修正只涉及测试夹具，最终无需重复随机矩阵。
- 最终窗口casting **136项通过**，退出0、无引擎错误；日志：`build/checks/20260909T194241262-52652/check-ui.log`。窗口先补导入并行新增的连续挣SVG，再将该用例的拖牌目标参数由装备ID纠正为正式候选ID；余势复演窗口检查无失败。未运行全项目回归，不生成截图。
- README、规则书、卡牌框架、AGENTS和本验证记录已同步；原创双重火焰SVG与卡面共用现有展示。没有发布或改动隔壁网页项目。

## 2026-09-10 猪神之皇焚与三级顺延

- 3费稀有技能、6×5挣扎伤害／5层蓄力，登记稀有卡池及原创SVG。follow_through复用hit/card_chain/normalize及完整清理，原件未解开持续命中；解除后按精准点→同一左栏大部位→原头／手／腿区域选择当前最外层，同优先级才随机。左栏与顺延共用equipment.PANEL_GROUPS，投影深拷贝。首段普通挣扎资格不改，后续只取代最高紧度目标排序；完整伤害倍率、方法资格、工具每牌一次及每段蓄力沿原管线。
- follow_through_cases由rewards下card_expansion唯一接入：费用与两面文字、无随机自由面、预览／过期／不足费用原子拒绝、原件五段不转移、指定位置内层显露优先、其余分段先于区域、脚趾纳入腿区、无目标停止、不跨区域、后继只选外层、确定性恢复与独立随机域、单牌工具一次、逐段蓄力、真实手掌／手指与脚掌／脚趾左栏分组。窗口casting增加真实拖牌全自动结算、自由面给层、两面高度与关键词悬停，卡面不展示长说明。
- 第一轮完整种子矩阵6591项无断言失败，但新测试用普通安装器传入不支持的单侧手指精确点，导致夹具为空而出现1个引擎错误，整轮按失败处理；修正夹具为普通手指正式覆盖，并补齐用户确认的左栏大部位分组。日志build/checks/20260909T192634056-51480/check-rules.log。
- 修正后rewards及全部关联日常分类4413项通过，casting窗口114项通过，退出码0且无引擎错误；日志build/checks/20260909T192948088-54340/check-rules.log和check-ui.log。无全项目回归，无截图，无旧存档迁移；随机域按当前版本统一校验。规则书、卡牌模板、README与AGENTS同批更新。

- 最终复查：rewards／casting及关联完整分类5845项通过；窗口casting 114项通过，规则和窗口退出0，无引擎错误。日志：`build/checks/20260909T192757726-7980/check-rules.log`、`check-ui.log`。保留首轮已通过的完整随机样本证据；未运行全项目或截图。

## 2026-09-10 猛火下山

- wildfire_descent为1费稀有能力，基础耗魔20，嘴部施法，双面相同且共用一个不可叠加的buff。能力模板开放原cast／mana_cost字段；统一施法入口先结算，再在成功后移入能力区，失败付费但保留原手牌，临时魔力／快感倍率／定咒及零概率拦截照原流程。
- BUFFS.spell_use_effects声明抽牌，统一_cast_magic在记录一次结果后调用Cards.spell_used；按指定spell过滤，不按牌名分支。群体只触发一次，装备目标也触发，失败使用仍抽牌；其他法术和无效／过期请求不触发。致死火球先抽再结束场次，满手牌、重洗、UID和动画共用原抽牌逻辑。共用效果日志改为报告实际抽牌数量，满手牌不会声称抽到1张。
- 规则覆盖双面费用与嘴部零概率、失败留手、临时池重试、无自触发、普通／群体／失败／装备目标抽牌、同名能力去重、存取后的连续使用、10张上限、空堆重洗及致死清理。UI使用真实翻面、悬停成功率、点击激活与火球术，断言费用、能力区、实际手牌增长和文字高度。加入稀有池及原创SVG，规则书、卡牌框架、README、AGENTS同步，无新状态或旧档迁移。
- 首轮扩展检查日志`build/checks/20260909T192601551-55884/check-rules.log`：8025项断言无失败，但关联follow_through测试的手指夹具用了不被普通安装接受的fingers_left参数，访问空对象时报1处引擎错误；未把该轮记为通过。夹具改用正式fingers位置，不改顺延规则。该轮enemy_cycle 16/16、enemy_pool 24/24的扩展样本与其余完整分类通过；修复后重新运行所涉完整分类，不重复无变化的全随机矩阵。

## 2026-09-10 灵活变通

- 验证：ListOnly确认范围后，rewards及关联完整分类使用Exhaustive通过6538项（enemy_cycle 16/16、enemy_pool 24/24）；窗口casting通过91项，含新卡真实输入与卡面适配。素材导入、规则及窗口退出0，无引擎错误。日志：`build/checks/20260909T191927966-48544/check-rules.log`、`check-ui.log`。未运行全项目或截图。

- 新增adaptability：1费罕见能力，自由面每回合开始经reserve_mana=1获得5点临时魔力，挣扎面经charge=1获得1层蓄力。加入罕见池，既有奖励、商店、图鉴与能力区共享分类和卡面；新增本地SVG。打出当下不发放，同面不叠加、双面可以并存。
- BUFFS.turn_start_effects沿现有附加效果列表校验，Cards.begin_turn在统一玩家回合补能／遗物之后、抽牌之前执行apply_effects；不新增牌名分支、计时字段或存档迁移。回合开始重复效果属于当前已生效能力，手牌／弃牌／查看／翻面与恢复快照不触发。战斗结束移除能力，所得蓄力按原规则保留，临时魔力清空。
- 新规则案例覆盖正式付款、旧版本与资源不足原子拒绝、延迟到下回合、无上限魔力池、飘字收据、同面拒绝、双面同时触发、同版本还原后的后续回合一致性、场次清理以及整备／休息／牢房正式结束回合。窗口案例使用真实翻牌、点击能力与结束回合，检查双面文字、牌面高度和资源变化。README、规则书、卡牌框架与AGENTS同步。

## 2026-09-10 控火与独立临时魔力池

- 最终窗口casting／status／rewards共292项通过，含真实出牌、永久加伤、10点临时魔力、状态寿命、魔力条点数显示与卡面高度：`build/checks/20260909T191236306-52240/check-ui.log`。规则及窗口退出0，无引擎错误；默认无截图。

- 控火为普通1费消耗技能，不判施法：自由面永久增加火球基础伤害1点，按头部／颈肩／双臂双手的实际非零紧度检查（范围暂定）；挣扎面经共用预备魔力效果提供10点临时魔力。永久增值跨战保留、新局清零、基础相加后再乘增益；卡图、卡面、状态与真实点击已接入。
- 预备魔力每层立即转成5点temporary_mana，移除原层数状态与逐次折扣，池子独立且无容量上限。候选和提交共享付款拆分：卡牌、火球及牢门开锁优先抵扣，再扣自身；固定魔力转换适用，失败照付。魔瓶／商店商品／服务不读取临时池，耗魔遗物及返还只算自身真实支出。各类end_combat统一清空，跨回合保留；当前格式保存小数余额，无旧档迁移。
- 更新卡牌、节魔卷轴、状态、魔力条、教程、日志、资源飘字与规则书。删除离场时笼统承诺所有增益保留的旧句。临时池损耗与自身魔力分开记录，致死施法先付费再清空余量，反馈保留两段。
- 控火单独完成时，规则扩展样本7836项、窗口279项通过，日志`build/checks/20260909T190433886-49696/`。随后临时魔力整批扩展检查`build/checks/20260909T191058312-49352/check-rules.log`共9219项，6项失败均为新增临时池测试夹具：未排除开场遗物的结束恢复，以及未清掉第二只敌人；其余分类通过。修正夹具后按casting、consumables及关联完整分类复查3001项全通过：`build/checks/20260909T191236306-52240/check-rules.log`，包含小数、无上限、付款不足原子拒绝、旧版本拒绝、失败施法、固定转换、遗物实际支出、商店及魔瓶隔离、各场次清空与同版本存取。保留已通过的扩展池样本结果，不重复全项目。

## 2026-09-10 余火

- 普通0费、基础5魔力、手部施法。free复用next_attack增益并将base_bonus=4接入火球基础伤害计算；同源不叠加，失败保留，整次群攻成功后一次消耗，装备自解分支也消耗。bound先抽1张，然后按当前余额及optional_draw固定5魔力追加一次抽牌；使用原临时魔力分摊与真实自身耗魔遗物hook，不额外施法，不新增状态或UI行动。
- 规则用例归入原rewards卡牌扩展，验证5／9.9／10魔力边界、0能量可施法、临时池和耳坠、伤害倍率前加值、群攻整波、同源拒绝、火球失败保留、装备自解半伤和消耗、双面失败扣首次费用并留牌；窗口casting实际点击验证普通卡、手部要求及双次抽牌付款。源码注册、教程式说明、状态、实际额外付款与抽牌日志、普通池和SVG同步，不截图。
- `rewards,casting,basic_attacks`及关联分类5903项全部通过：`build/checks/20260909T193222310-51720/check-rules.log`。
- `basic_attacks,casting`窗口132项通过，脚本退出0、无截图：`build/checks/20260909T193222310-51720/check-ui.log`。

## 2026-09-10 死灰复燃与通用失败留牌

- 死灰复燃：普通1费、基础10魔力、手部施法，两面成功后将既有火球术已用次数清零；上限仍读取BasicAttacks.usage，炫火3→4和敌人／装备共用次数继续有效。加入普通池、图鉴、卡面与本地SVG。refresh_spell沿self_faces声明并校验已登记法术，无新增状态或独立行动。
- 用户后续明确修改全部卡牌法术：Cards.play在任何实体牌移动之前统一施法，失败照付、留手、保留原顺序与保留期限，没有离手动画或成功出牌计数；消耗牌亦然。成功后才执行原弃牌／消耗／效果，牢门调用同一流程。非卡牌法术的次数与费用不变。教程、悬停、卡牌说明、日志与规则书同步；无旧档迁移。
- 沿既有casting和rewards用例更新失败断言，补充同一实体卡失败留手、无动画、保存恢复与重新成功的覆盖；死灰复燃用例验证耗尽后实际刷新并再次施放、3／4次数上限、两面、1＋10付款、手部阻止、失败不刷新、旧候选拒绝。UI实际点击普通刷新和消耗牌失败后重试，无截图。
- 新卡初版规则5731项通过：`build/checks/20260909T191810321-38608/check-rules.log`；同轮窗口仅首次火球悬停断言失败，补上先移出再移入以真正触发悬停。用户补充通用规则后，首轮3047项仅一处新增多段卡的文字格式断言失败：`build/checks/20260909T192209105-52040/check-rules.log`；将原只接受“6点”的断言扩展为接受准确的“6×5点”，保留真实基础值和段数校验，不改该卡规则。
- 最终规则`casting`及关联分类3047项通过、退出0：`build/checks/20260909T192336459-46380/check-rules.log`。同批窗口被并行新增的两张SVG未导入阻止，随后仅导入并重跑窗口，未重复已通过规则。
- 导入后的窗口中，失败留牌／重试和死灰复燃用例均通过；仅并行新增顺延卡测试把物理装备ID当作拖放候选ID，导致定位断言失败（实际后续行动通过）。按现有drop_targets候选键取正式candidate.id修正测试，不改游戏逻辑；日志`build/checks/20260909T192600244-55380/check-ui.log`，basic_attacks 16项已通过并保留结果。
- 最终casting窗口114项全部通过、退出0、无截图：`build/checks/20260909T192744292-51796/check-ui.log`。规则与相关窗口门禁完成。

## 2026-09-10 火动力学

- 2费稀有双面能力已接入原能力区、稀有池、图鉴和共享卡面，附本地SVG。自由面沿现有群攻冻结敌人名单，一次费用、一次次数、一次施法结果；保留魔法属性、伤害倍率、死亡与分裂结算。炫火自解仍单目标。挣扎面chance_bonus在快感／部位／法术倍率后加0.25并封顶，正式施法、预览、状态及事件共用。
- `tests/fire_dynamics_cases.gd`挂在rewards既有能力测试内，覆盖2费、封顶、口部零倍率后的独立加区、其他法术不变、精通共存、双面／去重、当前格式恢复、场次清理、群攻付款及一次使用、魔法对机械全伤、分裂子代不追击、失败全体无伤、炫火单目标。UI沿casting测试实际翻面及打出，并检查插图、稀有品质和50%群攻投影。不加截图或旧档迁移。
- 首次运行恰逢并行临时魔力字段迁移，旧reserve_mana读取失败，已停止该次运行。随后`rewards,casting,basic_attacks`及关联分类共5720项，除临时魔力专项6项外其余通过，火动力学无失败；日志`build/checks/20260909T191104468-53092/check-rules.log`。临时魔力用例同步修正后只重跑casting及其关联分类。
- 窗口`casting,basic_attacks`共97项通过、退出0，无截图：`build/checks/20260909T191213155-24068/check-ui.log`。
- 修正后`casting`及关联分类3001项全部通过、退出0：`build/checks/20260909T191309169-56024/check-rules.log`。其余前轮已通过分类不重复运行。

## 2026-09-10 休息处六回合与入场增益

- REST_TURNS=6。rest_choice在正式抵达时冻结三张不重复稀有卡，不推进普通卡牌rare_offset；点击卡牌扣4回合并获得它，rest_flask扣3回合补50魔瓶魔力，rest_begin保留6回合。不按装备状态限制，不发工具。删除旧rest_tool执行与rest_service_used字段，统一_begin_rest在选择后才开始场次及第1个真实回合；扣掉的时间不执行_end_turn或补发任何触发。练习直接开始6回合，保留场景配置工具。
- 新选择页沿用手牌样式显示三个真实稀有卡，另列补魔瓶／直接休息。选择后页面关闭并显示剩余2／3／6回合；非回合选择阶段不开放魔瓶存取。挂钩3次、自由面禁用、背包及结束规则保留。教程、路线说明、练习说明、规则书、README同步，无截图或旧档迁移。
- 规则覆盖实际卡牌与魔瓶领取、三条时长、原有装备不阻止选择、选择前无开场效果、选择后仅一次抽牌／补能／遗物、绿色小鸟从实际第1回合计数、无快感或回合末补魔的虚假跳过、魔瓶1000→1050且自身魔力不变、查看不重抽、旧版本重复提交拒绝、选择后不能再领、剩余回合耗尽退出。services关联pressure。
- 旧测试迁移：原工具服务获取改为工具夹具；旧5回合期待改6；所有经过休息处的旧路线补上rest_begin选择。首轮基础／服务／压力／奖励批次5556项中的6项失败来自未更新的路线假设（含1处后续空敌人访问），第二轮物品／部件／核心／路线批次4966项中9项失败来自剩余监狱路线入口假设；各已通过分类保留结果。日志分别`build/checks/20260909T185241943-53564/check-rules.log`、`build/checks/20260909T185508860-47188/check-rules.log`。修正后的prison/tower_progression及关联分类1962项全部通过：`build/checks/20260909T185717360-54536/check-rules.log`。
- 窗口services98项、prison120项通过：`build/checks/20260909T185717360-54536/check-ui.log`。该批仅旧pressure断言把既有魔瓶入口误判为多余操作；按现有规则排除魔瓶，并修正测试内同名局部变量后，pressure41项全通过、脚本退出0：`build/checks/20260909T190124235-53368/check-ui.log`。未改变魔瓶既有玩法，也未重复已通过的窗口分类。


## 2026-09-10 炫火、火球次数与火焰精通费用

- 新增稀有1费能力炫火及本地SVG卡图。两面沿原能力来源：自由面每回合火球术3→4次；挣扎面从装备详情选择最外层拘束具造成当前火球术一半的魔法伤害。敌人与装备共享次数、施法与付款；失败计次，过期／不可用提交不计次。半伤复用基础增伤、手势与倍率公式，不重复加入挣扎／滑脱修正；外层、免疫和真实装备清理保留。火焰精通两面统一2费，实际卡面与不足2费拒绝同步验证。
- 新案例flame_flourish_cases由rewards下card_power唯一接入，覆盖两面共存、同面拒绝、三次封顶、回合内加一次、跨目标共用、换回合、场次清理、当前快照、只读与过期回滚、锁定件直接扣耐久、倍率取半、外层遮挡／破坏及付费失败。窗口casting补充真实出牌、翻面、装备详情施法按钮点击、扣费／次数及两面卡面高度。targeting复查原基础攻击入口。
- 首轮rewards/casting/content完整种子矩阵7867项中4项失败：两处装备断言读取了事务前引用、一处外层夹具选到了不同精准位置，及扩大卡池后原32种子未覆盖全卡；均修正为提交后按ID取目标、显式同部位夹具、按卡池规模设置有界抽样。该轮其余分类通过，日志build/checks/20260909T190733187-40504/check-rules.log。
- 修正后按ListOnly范围运行rewards及全部关联日常分类，4297项通过；窗口casting/targeting共107项通过，均无引擎错误。日志build/checks/20260909T191122603-49452/check-rules.log及check-ui.log。没有运行全项目回归、生成截图或增加旧存档兼容。
## 2026-09-10 henshin自由面不可叠加

- 确认原共享增益逻辑已按稳定来源去重，重复自由面在付款前拒绝，保留该实现。自由卡面与状态说明直接写明“不可叠加”，通用重复提示改为具名“henshin已生效，不能重复叠加。”；不同来源的原倍率组合和挣脱面保持原规则。
- 沿card_expansion既有实际重复使用、整份状态不变、伤害倍率、战斗结束清理及被动伤害案例补充显示断言。ListOnly确认后，rewards及关联完整日常分类通过4170项，窗口casting通过63项，包含双面卡牌实际操作及文本高度检查。日志`build/checks/20260909T184750323-49332/check-rules.log`与`check-ui.log`。未新增规则字段、截图或存档兼容，未运行全项目回归。

## 2026-09-10 开信刀play

- 新增罕见1费双面能力letter_opener并进入罕见池，复用能力区及双面共存／同面不叠加规则。BUFFS.periodic统一配置技能类型、每3张阈值、目标和基础伤害；进度附着物理能力牌，每玩家回合开始归零，结束场次清除，多段完整结束后才触发，续段不重复计数。
- 自由面5普通物理伤害复用全局倍率、敌人抗性、分裂及击败。挣扎面冻结当前全部外层目标和各自公式，以3点仅乘紧度、锁、堆叠、目标及伤害增益；不加属性／蓄力／辅助／墙面、不消费准备、不执行主动直接卸除。装备实际损伤和清理沿共享入口，不穿透新露出的内层。新增原创开信刀信封SVG、卡面说明和状态进度；模板与规则书同步，不做旧档迁移。
- 导入成功，ListOnly确认后rewards及关联完整分类以Exhaustive通过6372项，日志`build/checks/20260909T184205458-49588/check-rules.log`。涵盖第三／第六张、每回合重置、零费技能、魔法与诅咒排除、失效命令、只读投影、多段技能一次、倍率数值、蓄力不消耗、低紧度外层打破后内层保留、复合／独立装备去重及群伤胜利清理。测试夹具使用同一精准小腿位置建立真实层叠，避免自动选位将两件放到不同位置。
- 完整窗口casting最终通过63项，日志`build/checks/20260909T184521459-41396/check-ui.log`；status30项及rewards179项已在前一窗口批次完成。首轮新增点击用例将已自动显示自由面的技能误翻回挣扎面，修正测试为按当前牌面决定翻转后，仅重跑受影响casting。验证真实点击、右键牌面、费用、能力区、2／3状态及双面文字边界。未运行全项目或新增截图。

## 2026-09-10 奥利哈基米

- 罕见一般遗物olihakimi，unspent_turn_mana=8。四类正式玩家回合结束时，未实际支付魔力则由共享hook恢复8并封顶；不在单纯结束战斗时补发。combat.mana_used在任何正数正式付款时记录，不依赖是否持有该遗物，也独立于耳坠累计余数；回合开始重置、场次结束清理。零费与魔瓶转移不标记，付费失败仍标记，恢复魔力不撤销。同步图标、说明、规则／模板和当前快照字段，提升集中修订号但不迁移旧档。
- 完成ListOnly、导入及rewards/content相关Exhaustive检查。新用例覆盖真实结束回合、实际火球付款后饮药、零费准备、魔瓶转移、耳坠阈值归零、付费施法失败、回合中途拾取、恢复封顶、四类回合生命周期、同版本读回及损坏字段原子拒绝。最初夹具在受拘束站姿饮药、以及将用于读回的初始魔力赋为整数，修正为合法坐姿与浮点值；读回后的版本变更用真实快照比较。
- 本遗物用例最终无失败；完整status/rewards窗口通过209项，日志`build/checks/20260909T183914781-37496/check-ui.log`，验证悬停品质／条件、真实结束回合恢复8及施法后不恢复。首次窗口受并行新增letter_opener.svg未导入影响，重新导入后通过。
- 共享奖励分类整合门禁尚未全绿：`build/checks/20260909T183914781-3636/check-rules.log`共6344项，3项断言失败及4条引擎错误均来自并行新增的letter_opener_cases；该轮不能记作通过。未修改该并行实现或跳过其测试。本任务未新增截图、存档迁移或全项目回归。

## 2026-09-10 绿色小鸟

- 稀有一般遗物green_bird，pressure_guard_turns=4。combat.turn为全部战斗／类战斗统一回合数，开场归零、玩家回合先递增；巡视暂停不重置。Pressure.gain在倍率之后和阈值结算之前截断99，超额舍弃；开场及有效期内拾取也纠正已有99以上小数。第5回合正常增长，无补算。资源来源说明与遗物倒计数共用只读投影，新增绿色小鸟SVG及具名抵消反馈。规则／模板／README同步，不做旧档迁移。
- 覆盖稀有池、四类真实开场、前1—4回合、真实结束行动、保护期间魔力／能量／手牌／阈值计数不变、第5回合正常阈值、当场第3回合取得只剩2回合、非战斗无保护、巡视后第5回合不重新保护。rewards分类关联pressure，防止将来专项遗漏。
- 首轮rewards/pressure关联4970项中9项失败均来自新牢房夹具将倒计时设为非法10，正式行动被拒绝；修正为正式初始倒计时，其余分类通过。首轮日志`build/checks/20260909T183032721-5724/check-rules.log`。修正后rewards及其关联全分类4085项通过：`build/checks/20260909T183239129-50128/check-rules.log`；pressure及其他无变化分类未重复。
- 界面初次被同时编辑的olihakimi.svg尚未导入阻塞；重新导入后status完整分类30项通过，但rewards加载时同时编辑的olihakimi测试函数尚未写完。其文件完整后，仅重跑rewards，179项通过，退出0。status证据`build/checks/20260909T183447757-22020/check-ui.log`，rewards最终证据`build/checks/20260909T183604714-3784/check-ui.log`。本任务未修改该并行功能。
- 真实界面结束回合后快感98→99，遗物剩余保护4→3；资源详情说明99上限，所有遗物图标与完整悬停说明检查通过。无截图。

## 2026-09-10 红烧鱼香茄子

- 稀有一般遗物braised_eggplant；仅注册已有pickup_mana_max=20、pickup_mana=20，先永久加上限再恢复。加入REWARDS和共用SVG图标；无需新增规则逻辑、接口、计数或存档字段，文案、规则说明、模板已同步。
- 规则覆盖真实稀有池抽取、满魔力／非满魔力正式领取、只读资源投影、防止重复领取与过期提交再次增加、后续特殊战斗不重复加成。窗口真实点击领取后立即显示120/120与持有图标；全部遗物的悬停说明沿现有批量检查验证。无截图。
- ListOnly后导入及rewards关联分类首轮4032项，仅同时修改中的触手朋友3项失败；本次新遗物和其他分类通过。日志：`build/checks/20260909T182213323-53140/check-rules.log`。触手朋友夹具更新后单独复查受影响consumables完整分类，120项通过：`build/checks/20260909T182429727-55732/check-rules.log`，本任务未修改其代码或夹具。
- rewards完整窗口166项通过：`build/checks/20260909T182405813-36264/check-ui.log`。复查脚本退出0，无引擎错误。未重复无变化的已通过分类。

## 2026-09-10 触手朋友

- 稀有一般遗物tentacle_friend，unrestricted_items=1。药剂、卷轴、开锁针和折返符取消身体／姿势／触及限制；魔瓶饮用复用药剂资格，potion_amount口部减效及取整原样保留。不改玩家真实身体自由度、施法或徒手辅助资格，次数、阶段、材料、外层遮挡和有效目标仍按原规则。
- Tools.assisted/is_fixed/target_contact集中解释权限与全身接触，随身trigger_damage_types工具视为固定，复用InstalledTools最强兼容工具选择、每牌限次及固定伤害；含头部与特殊部位的可用工具环境。真实mount不改，工具仍占携带格、能随人离房，不需安装且不再提供直接切割入口。已真实安装的工具可由触手取回，原位置与数量校验保留。新SVG及道具面板显示“触手固定”“全身”，不把虚拟固定写成真实墙面安装。
- 已确认分类范围并完成导入。初轮consumables/installed_tools/rewards/content及关联Exhaustive执行6294项，3项新案例失败：测试临时改口部装备等级后未恢复结构，以及给不存在的独立颈部模板构造夹具；该轮不视作通过。修正为还原口部结构、以真实颈肩接触点验证范围，consumables先通过117项；再补充真实旧工具取回及手部状态不变案例，并覆盖special_equipment完整分类和关联接口，最终通过2320项，日志`build/checks/20260909T182416401-26048/check-rules.log`。其他未变分类已在`build/checks/20260909T182058439-32992/check-rules.log`完成。consumables交叉关联补入installed_tools/special_equipment/content。
- 完整status/consumables/rewards窗口通过223项，日志`build/checks/20260909T182302963-54600/check-ui.log`。真实操作验证拘束下使用卷轴、旧禁用原因消失、随身工具显示固定被动及全身范围、共享遗物图标。规则验证真实眼部出牌加成、次数与伤害、过期命令不重复、外层／材料／耗尽反例、魔瓶半效及上下取整、工具携带与库存。未新增截图、存档迁移或全项目回归。

## 2026-09-10 爆炒麻辣米线

- 普通一般遗物spicy_rice_noodles，opening_charge=2。沿既有begin_combat增加charge，覆盖战斗／牢房／休息／整备，保留叠层、原有使用规则与状态投影。独立SVG和具名获得反馈已接入，说明／模板同步；无新状态、计数、迁移或截图。
- ListOnly确认rewards及其关联分类，导入成功。首轮3986项中仅客房事件的2项旧测试失败：随机奖励抽到了改变魔力上限的遗物，与该夹具固定92上限的假设冲突；其余分类（包括新遗物完整规则用例）通过。日志：`build/checks/20260909T181633502-14512/check-rules.log`。
- 客房两种数值夹具限定奖励资格，隔离无关的拾取加成，保持正式随机生成与交易。受影响event_flow分类复查302项全通过：`build/checks/20260909T181832905-53992/check-rules.log`。未重复已通过且无修改的规则分类。
- 完整status/rewards窗口检查193项通过：`build/checks/20260909T181832905-53992/check-ui.log`，真实奖励进入整备获得蓄力，遗物横栏图标／悬停与现有状态投影正确。脚本退出0，无引擎错误、无截图。
- 规则覆盖普通池抽取、途中拾取不追溯、四类真实开场叠层、普通换回合不重复、正式奖励转整备、只读查看与过期提交不重复，以及巡视后恢复不重开场。

## 2026-09-10 传单

- 普通一般遗物flyer，进入商店向魔瓶补充20魔力；shop_flask_mana沿既有RelicEffects._mana_hook增加魔瓶目标，复用商店stock首次初始化防重，不新增持久字段。店内取得不追溯，其他房间不触发，自身魔力与手动存入次数不变，无容量封顶。新增传单SVG、共用图标与具名资源反馈，规则书及模板同步。
- ListOnly确认范围，导入成功。rewards/services/content及关联分类以Exhaustive完成首轮，6333项断言无失败，但新商店夹具误调用仅测试Game支持的_gain_relic，出现1条引擎错误，该轮未视作通过。修正为正式RelicEffects.gain后，受影响services及其全部关联consumables/shop_release/rewards分类通过1146项，日志`build/checks/20260909T180728221-42056/check-rules.log`；其他分类已在`build/checks/20260909T180620998-31860/check-rules.log`完成。仅修正测试调用，未重复运行无变化分类。
- 覆盖真实路线进入商店／宝箱、连续不同商店、1000魔瓶余量继续增加、只读页面、过期进入命令原子拒绝、重开不补发、店内拾取不追溯、普通池实际抽取、可扩展字段及超界拒绝。services交叉分类补充rewards/content关联。
- 完整窗口services/status/rewards通过279项，日志`build/checks/20260909T180728221-42056/check-ui.log`。真实点击到店后余额增加20，宝箱不增加；图标、普通品质与说明正确。未运行全项目、未新增截图或存档迁移。

## 2026-09-10 成王之礼精装修订重置版

- 稀有一般遗物kings_gift_revised，trigger复用turn_end／battle周期，round=7、fixed_enemy_damage=77。第7个玩家回合结束时冻结在场敌人，固定伤害不受坚硬／力量／蓄力／henshin倍率影响。普通攻击与遗物统一_damage_enemy处理生命、死亡和分裂；新子代不在本次目标集合内，全灭立即结算一次奖励。复用round、combat.serial、relic_used与只读counter，无新计数状态或存档字段。模板校验、说明、日志、图标及回合／已触发显示同步。
- 完整rewards、basic_attacks、content及关联分类通过3750项，日志`build/checks/20260909T180151538-31668/check-rules.log`。覆盖第6／7／8回合、机械与普通目标固定伤害、蓄力保留、全灭奖励／重复提交、下场重置、死亡／半血分裂子代和休息排除，以及JSON指定回合整数与适用范围校验。首轮分裂测试误读提交前对象，改为按ID读取正式敌人后通过，未修改分裂规则。
- 窗口basic_attacks通过16项、enemies通过182项，同目录check-ui.log；该批随后加载rewards时因并行新增图标引起ART资源解析失败，未计整批通过。统一重新导入后完整rewards通过157项，日志`build/checks/20260909T180535409-49700/check-ui.log`。真实点击结束第7回合验证全部敌人100→23及图标7→✓，共享悬停说明通过。未截图或运行存档专项。

## 2026-09-10 滚木

- 新增特殊收藏遗物rolling_log，没有效果，不进入一般遗物池。抽中品质池耗尽时统一替代发放，不再换抽其他品质；精英奖励、商店、宝箱和随机事件共用。重复领取只累加持有数量，顶部一个图标右下角计数；同步原创木段SVG、悬停说明、内容模板和规则书。
- 复用collectible、can_gain与counter投影，收藏定义禁止附带属性、触发或卡面加值。拾取不触发效果动画，魔力、能量及角色属性不变；每个商店货位独立购买与售罄。删除宝箱30魔力及商店留空回退。快照仅更新正式事务所需的合法遗物／领取资格校验，未添加旧存档兼容或迁移。
- ListOnly确认范围后，rewards/services/content及关联完整分类以Exhaustive通过6309项，日志`build/checks/20260909T175626751-38324/check-rules.log`。覆盖单品质／全池耗尽、普通池不受替代领取影响、重复拾取、真实精英领奖、三份商店购买、宝箱免费领取、回合不增加数量、只读预览、失效命令及内容校验。首轮修正测试夹具对相同商品字典的索引查找，正式货位逻辑未变。
- 完整窗口services/status/rewards通过271项，日志`build/checks/20260909T175626751-27220/check-ui.log`。真实点击验证奖励重复领取及三个独立商品扣费／售罄，图标数量和悬停说明正确；已查看`build/ui-rolling-log.png`。未运行全项目回归。

## 2026-09-10 大理石

- 罕见一般遗物marble，low_mana_end_restore=20。真实战斗／牢房探索场次结束时，在行动遗物flush之后、余烬护符等battle_mana之前，按当前魔力≤当前上限50%判定并恢复封顶；不依赖持有顺序。探索巡视只暂停，不触发；反抗转战斗或逃离时结束探索，休息／整备排除。复用active避免重复结算，无新状态／存档字段。说明、模板、具名触发日志及共享大理石SVG同步。
- 完整rewards及关联分类通过3586项，日志`build/checks/20260909T174413035-48612/check-rules.log`。覆盖50%临界及略高反例、变化后的上限、恢复封顶、两种持有顺序、只读预览、重复结束、真实整备／休息离开、探索移动／巡视暂停／反抗／逃离。
- 完整status、rewards窗口分类通过169项，日志`build/checks/20260909T174413035-48612/check-ui.log`。真实付费法术击败敌人后魔力降至50，先大理石＋20再护符＋10，奖励页正确显示80；全部遗物图标及悬停说明通过。未截图、未运行全项目或存档专项。

## 2026-09-10 优秀学员毕业证书

- 新增罕见一般遗物graduate_certificate：奋力挣动／扭身抽离卡面基础5→9。通用card_base_bonuses按稳定卡牌ID配置加值；Cards.base_damage统一供装备、捕缚与动态卡面使用，不改共享SPECS和自由面，不影响其他牌／体术／被动。加值在倍率之前，三档滑脱仍免疫卡牌伤害，原环境真实伤害保持独立。
- 手持、卡组、奖励、商店、图鉴陈列共用GameView.card_texts；卡牌候选说明同样读取动态牌面。新增原创证书SVG与悬停说明，无伪计数器。既有JSON加载器支持可选card_base_bonuses，校验真实有基础伤害的卡牌ID、非空对象及1—100整数，批次失败不提交。
- ListOnly确认范围后运行Import与rewards/content/services完整分类；修正捕缚测试为正式guard练习的三回合施加流程，并将三档反例分开断言卡牌免疫与环境真实伤害。最终`-Suite rewards -Exhaustive`及关联完整分类通过5767项，日志`build/checks/20260909T174036305-50028/check-rules.log`；生成域完整矩阵保留。先前services、shop_release与trader各分类也已完成，最终只重跑受修正影响的rewards及关联分类。
- 完整窗口services/interface/rewards通过598项，日志`build/checks/20260909T173712127-51936/check-ui.log`。真实鼠标操作验证两张手牌及卡组均显示9、遗物悬停显示罕见和＋4、查看不改变游戏状态；已查看`build/ui-graduate-certificate-deck.png`。规则覆盖实际装备／捕缚伤害、原有倍率、三档免疫、锁与堆叠、其他牌不变、自由面不变、重复授予、失效命令原子拒绝、新局不受影响及内容加载正反例。未新增存档兼容或迁移。

## 2026-09-10 一只小猪

- 稀有一般遗物little_pig以always_wall=1接入at_wall，wall_contact独立保留真实墙面距离判定。贴墙起身、探索免摔倒与原墙面加成使用效果判定；工具安装／取回／触发、挂钩与对应特殊装备工具条件使用真实接触。实际位置、墙种、距离与随机域不因拾取改变，状态、移动预告、日志和教程明确区分持续支撑与真实位置。新增共享猪形SVG，不新增状态或存档字段。
- 完整rewards、wall及关联分类通过4155项，日志`build/checks/20260909T172813464-4548/check-rules.log`。新案例验证真实折扣起身、离墙仍有效、无墙边界、蒙眼探索不掷摔倒骰、实际位移及远程工具拒绝；沿现有wall分类并登记rewards关联，不另建启动器。
- 完整wall、status、rewards窗口分类通过209项，日志`build/checks/20260909T173112340-47616/check-ui.log`。真实点击离墙起身、距离显示、持续状态来源及全遗物悬停说明通过。首轮窗口被并行新增但尚未导入的graduate_certificate.svg阻断，统一重新导入资源后复查通过；没有调整无关功能、截图或存档专项。

## 2026-09-10 遗物靠左与对白自动关闭

- 遗物横栏移至场景最左上角（405,78），人物对白层级在其上。对白框与尾巴统一显隐：左键按下任意位置立即关闭，右键不关闭，未点击则首次展示5秒后自动关闭。按正式speech.id识别新发言；普通重绘和窗口操作不延长期限，也不复活已关闭对白。仅UI状态，不修改日志、回合和资源；点击继续传给原控件。
- 先ListOnly确认范围，再运行`./tools/check.ps1 -UIOnly -UISuite action_copy,rewards,casting,interface -Screenshots ui-77-dialogue-action-log.png,ui-relics-after-dialogue.png -TimeoutSeconds 240`，577项断言通过。日志`build/checks/20260909T171155900-52752/check-ui.log`。
- 实际输入覆盖对白内／外左键、右键反例、真实5秒等待、中途重绘保留截止时间、消失后新发言、遮盖时遗物不透出悬停、消失后遗物可悬停、计数遗物与施法遗物入口。查看两张截图确认对白、尾巴与遗物层级。同步更新既有遗物悬停测试为先按实际点击关闭遮挡对白，未绕过输入。未运行无关规则或存档专项。

## 2026-09-10 小宝石

- 新增普通一般遗物small_gem，opening_energy=1；战斗、牢房、休息与整备首回合正常补能后额外＋1，复用combat.first_turn，不新增计数器。中途拾取不补发，后续回合不重复；说明、模板、具名触发日志和共享宝石图标同步。
- 完整rewards及关联分类通过3328项，日志`build/checks/20260909T170925732-54160/check-rules.log`；覆盖四类场次首回合、准备背包／预备能量／甜甜圈叠加、真实战后进入整备及过期提交拒绝。首轮新增测试未重置抽牌堆，修正夹具后通过，未改变游戏抽牌规则。
- 完整status、rewards窗口分类通过153项，日志`build/checks/20260909T171249932-11148/check-ui.log`。验证实际进入整备显示4能量、下一回合恢复3、图标与完整悬停说明；窗口焦点切换修正后复查通过。没有新增截图、存档兼容或全项目回归。

## 2026-09-10 场景遗物横栏与顶部精简

- 全部持有遗物改为场景上方一字横排，超宽横向滚动；悬停直接显示名称、品质、完整效果和当前累计进度，离开关闭。移除独立遗物按钮、列表浮窗和旧show_relics状态；计数器继续读取正式投影并锚定图标右下角，触发反馈使用新横栏。场景上方房间名、阶段文字按用户要求删除，展开日志下移避免挡住遗物。
- ui/relic_icon统一20种遗物图案，新增19张本地原创SVG，已有开心小fa保留；商店与奖励共享映射，未知扩展遗物保留通用图案回退。无规则、资源结算或存档修改。
- 先ListOnly确认casting、services、interface、rewards窗口范围；Import与上述完整窗口分类通过637项断言。日志：`build/checks/20260909T170204373-40596/check-ui.log`。覆盖全部持有遗物逐个真实悬停、完整说明、单行布局、横向滚动后的末项可达、查看不改变状态、实际回合0→1→2→0计数及第三回合能量4、旧按钮及场景重复标题消失、商店购买与施法遗物入口。已查看`build/ui-relic-turn-counter.png`、`build/ui-55-relics-scrolled.png`及`build/ui-97-shop.png`。首次检查发现日志遮挡末尾图标，已修复并完整重跑通过。

## 2026-09-10 欲望魔方

- 新增稀有遗物欲望魔方，加入一般奖励池；沿现有遗物魔力钩子，每成功施加一件拘束具恢复5魔力，受当前魔力上限限制。普通件、独立链接与特殊装备计入，复合根整件计一次；加固、上锁、组件维护与原装备归还不触发。替换只在成功提交时计新装备，预演不发放，失败整组回滚。
- `./tools/check.ps1 -Suite rewards,application -TimeoutSeconds 300`及关联分类通过3442项，日志`build/checks/20260909T165702510-53284/check-rules.log`。补充完整replacement及关联分类通过674项，日志`build/checks/20260909T165827838-51036/check-rules.log`。覆盖实际敌人施加、各类安装、奖励池、上限、拒绝安装、预演只读、替换提交、重复提交拒绝和原子回滚；遗物说明与触发日志同步。未新增截图测试或存档兼容。

## 2026-09-10 开心小fa与累计遗物计数器

- 新增罕见一般遗物happy_fa，turn_energy_step=3，沿统一玩家回合入口在补能后每3回合＋1能量；relic_counters按遗物ID保存余数，跨战斗／整备／休息／牢房保留，地图及零回合操作不计。新增字段沿普通状态事务提交，不扩展存档兼容或迁移。RelicEffects.counter/view输出只读计数，顶部快捷图标与遗物图卡共用ui/relic_icon右下角数字；魔力耳坠使用其原耗魔余数，无累计的遗物不显示数字。原创笑脸挂饰happy-fa.svg在持有、商店和奖励处共用。
- `-Suite rewards,services,content -Exhaustive`及关联分类通过5937项，日志`build/checks/20260909T164804106-48488/check-rules.log`。新增实际结束回合、战斗结束保留2回合进度、领奖进入整备触发第三回合、补能叠加、过期命令拒绝、非玩家回合不计、重复授予不清进度和新局归零检查；新遗物可由真实一般池取得，日志含实际触发与能量收益。
- 完整窗口services、status、rewards分类通过197项，日志`build/checks/20260909T164804106-48488/check-ui.log`。真实回合操作验证0→1→2→0与第三回合能量4，点击顶部图标只打开详情、状态不变，详情计数器完整位于图标右下角。已查看`build/ui-relic-turn-counter.png`和`build/ui-relic-turn-trigger.png`。未进行存档专项或全项目all。

## 2026-09-10 商店固定品质货位与扩容

- 商店按2普通、2罕见、1稀有卡牌＋4种道具＋3个一般遗物货位生成；移除已无调用的shop卡牌品质概率，共用reward_offer的固定池与count参数。道具池纳入现有全部6种药剂／卷轴，暂定各15魔力，原工具保留价格。遗物继续去除持有／已展示项，池不足留空，不创建专属池。扩宽商店，以三排显示全部12件；商店行动日志沿原日志浮窗，避免遮挡商品和付款。
- `-Suite services,rewards -Exhaustive`通过5841项，日志`build/checks/20260909T162241088-53928/check-rules.log`。新增32种子检查固定品质配额、同店去重、9道具覆盖、不同rare_offset下同种子货品一致、全局随机域不动、重复进入不补货、遗物仅余0／1／2件。既有购买、资源不足、售罄和背包满事务检查继续通过。旧卡牌概率测试移除商店百分比，保留战斗及事件修正测试。
- 首轮窗口测试暴露日志侧栏挡住魔瓶付款；改用原日志浮窗后，完整services、consumables窗口分类通过116项，日志`build/checks/20260909T162538765-53212/check-ui.log`。12商品控件在1600×900与1280×720下均可见且互不重叠；原生点击魔瓶付款、购买、删牌／解除和日志只读检查通过。已查看`build/ui-97-shop.png`、`build/ui-shop-1280.png`、`build/ui-shop-flask-payment.png`。早期失败不计通过，未修改存档实现或兼容旧档。

## 2026-09-10 各界面视觉统一

- ui/visual_theme集中维护暗底、按钮状态、搜索／筛选菜单、滚动条与细分隔线；新增原创window-frame.svg可伸缩角饰边框与crest.svg菱形纹章。主页、装备、塔路、商店、事件、卡组、状态、奖励及共用信息窗同步使用，状态筛选明确选中，遗物改两列图卡并保留全部正文。非行动页面收紧魔瓶底框，取消下半部空白。
- 完整窗口分类home、interface、body_layout、status、services、events、rewards、route、consumables通过837项，日志`build/checks/20260909T160944841-42100/check-ui.log`。替换遗物旧的按文案查找且可能不执行的滚动检查，改为断言真实持有卡片数量及最后一张可完整滚动到达。实际查看主页、塔图、卡组筛选、状态、遗物末页、装备详情、商店、事件及奖励列表截图。
- 底框收紧后重跑完整route、consumables窗口分类，通过112项，日志`build/checks/20260909T161242469-53748/check-ui.log`；已查看`build/ui-shop-flask-payment.png`，确认商店魔瓶紧凑、付款入口保留。未运行规则全量或存档专项，没有改变规则结算。

## 2026-09-10 贴身魔瓶、双来源商店付款与左下紧凑布局

区域美化追加：资源条采用统一暗底，捕缚保留第三行；魔瓶与新增能量徽章上下对齐，右侧统一能力区／抽牌堆宽度，抽牌堆加入原创卡背图标，整个操作区使用低对比暗底与细金属边。抽牌／能力动画中心随按钮同步。`-Import -UIOnly -UISuite consumables,interface`通过394项窗口断言，日志`build/checks/20260909T154300718-51408/check-ui.log`。已查看`build/ui-mana-flask.png`和`build/ui-mana-flask-capture.png`，确认正常／捕缚两种状态下数字、魔瓶与按钮无重叠；未修改规则结算。

视觉层级调整：新增原创矢量资源`assets/ui/mana-flask.svg`，以青蓝玻璃、黄铜瓶口和微光构成大魔瓶主体；储量贴瓶显示，存取按钮缩小并纵向排列于右侧，剩余存入次数以两个小圆点表示。移除外围大边框，存取结算不变。完整consumables窗口分类25项通过，日志`build/checks/20260909T153723331-50604/check-ui.log`；已查看更新后的`build/ui-mana-flask.png`，确认魔瓶比按钮醒目，且不遮挡捕缚条、能量和抽牌堆。

完成全局flask候选与正式转移、每回合存入配额、共用药剂资格和取整、商店商品／删牌／解除的self或flask单来源付款。左下资源横排，真实捕缚条占预留位置，魔瓶固定在抽牌堆上方；删除重复教学，施法概率移至魔力悬停。数值反馈与抽牌／能力动画位置同步，存档运行代码未扩展。

- `./tools/check.ps1 -Suite consumables,services,core,pressure`及全部关联分类通过2363项规则断言，日志`build/checks/20260909T152118299-55004/check-rules.log`。之后补充嘴部减效下小数缺额补满的边界处理，重跑完整受影响分类`consumables,services,core`通过1222项，日志`build/checks/20260909T152627335-54020/check-rules.log`。
- 新增mana_flask_cases归入consumables，分类关联增加services。覆盖2次上限／实际新回合重置、部分余额与百万储量、取出不限次数、药剂嘴部整数边界、半点缺额、站姿与握持限制、坐姿豁免、领奖和打断阶段可存入、预览只读、过期／重复操作拒绝、存储不触发耗魔遗物、商店全额扣魔瓶且不混付、售罄／余额不足不结算以及删牌／解除服务。
- `./tools/check.ps1 -UIOnly -UISuite consumables,services,casting,rewards`通过182项窗口断言，日志`build/checks/20260909T152335518-46708/check-ui.log`。真实点击验证存入／取出／禁用余次、付款切换不改状态、从魔瓶购买；检查飘字结束后两种余额与实际值一致，真实50/100捕缚条不会与魔瓶重叠。已查看`build/ui-mana-flask.png`、`build/ui-mana-flask-capture.png`、`build/ui-shop-flask-payment.png`。
- 过程修正：原分段卡牌／巡视／打断断言只允许阶段行动，现保留原限制并允许用户明确要求的全局魔瓶；原“全部遗物”窗口夹具只注入随机奖励池，遗漏新增专属来源遗物，改为注入正式TYPES全集。没有改动遗物掉落池或其他规则。早期失败不计为通过；未运行全项目all或存档专项。

## 2026-09-10 偷渡商人的魔药箱

- 新增正式地图事件与练习“偷渡商人的魔药箱”。开场对白按确认稿使用“嘘，小声点。我可是偷偷溜进来做生意的。”；【赊账】使贴身魔瓶直接获得90魔力并取得诅咒“敏感”，【不赊】无代价离开且不改变资源、卡组、装备或遗物。
- 新增可跨事件复用的`flask_mana_gain`效果，已覆盖内容字段白名单与0—100范围校验、方案说明、原子执行、结果说明、快照校验和结构化`flask_mana`资源反馈。它不建立金币或欠款状态，不改变角色当前魔力、不受角色魔力上限约束，也不占用每回合两次手动存入次数；执行流程没有事件ID专用分支。
- 联合规则门禁`tools/check.ps1 -Suite content,events,event_flow,tower,consumables -TimeoutSeconds 300`覆盖20个关联模块，3771项通过，记录`build/checks/20260909T160440389-17680/`。事件窗口`tools/check.ps1 -UIOnly -UISuite events -TimeoutSeconds 240`通过96项，记录`build/checks/20260909T160620555-51340/`。按截图精简要求未请求或生成截图，也未运行全项目回归。

## 2026-09-10 战后战利品领取界面

战后改为居中的卡牌／道具／遗物独立领取列表；卡牌行打开三选一，支持右键翻面、返回和领取后回到列表，最后点击继续。道具与遗物生成只冻结结果，正式领取才入包或触发拾取效果；继续清空掉落记录并放弃未领内容。复用原reward候选、版本复核、道具容量整理和监狱出口流程。ui/reward_screen.gd只消费GameView.battle_rewards，图标沿用扩展后的shop_glyph。

- 规则：`./tools/check.ps1 -Suite core`及其完整关联分类通过1004项断言，其中rewards为470项。新增battle_reward_cases覆盖三种领取顺序、实际入包、重复与过期拒绝、只读投影、随机不重抽、继续放弃及下一战重置；原容量、阶段与出口案例已按明确领取／继续更新。日志：`build/checks/20260909T143612681-54680/check-rules.log`。
- 窗口：`./tools/check.ps1 -UIOnly -UISuite rewards,consumables,prison`通过196项断言；包含鼠标真实点击奖励行／返回／领取、卡牌右键翻面、灰置已领项和出口继续。日志：`build/checks/20260909T143345630-41204/check-ui.log`。已人工查看`build/ui-reward-list.png`、`build/ui-54-reward-cards.png`和`build/ui-reward-claimed.png`，无文本越界或遮住领取按钮。
- 宽范围检查`core,rewards,tower_progression`并未全绿：日志`build/checks/20260909T143420215-14660/check-rules.log`记录13个断言失败及1个额外脚本错误。事件路线助手原本假定所有事件都能拒绝，现改为提交实际合法事件步骤，上述1004项复核已通过；另有两项关联存档检查仍按“掉落遗物必已入包”的旧假设拒绝未领取奖励，按用户暂缓存档要求未修改存档运行代码。该轮强怪组合案例还出现drone_pair、ominous_circle_pair、serpent_weak及数量索引失败；同目录敌人测试在检查期间有并行修改，本轮未处理或标记其为通过。
- 本批未运行全项目all回归，未启动存档专项、兼容或迁移；没有把宽范围失败当作通过。规则正文同步至game-design、card-framework与AGENTS。

## 2026-09-09 全目录架构检查与精简

本次按用户要求检查整个独立项目的架构和接口，包含运行时、定义表、窗口、内容包、测试、脚本、资源接线和维护文档。存档专项按用户最新要求延期；只读依赖扫描经过文件名，不据此认定存档机制已验收。旧存档不适配，相关运行代码与专项案例未修改。

| 范围 | 检查与处理 |
|---|---|
| core / data / ui | 78个运行时脚本的引用、职责与调用方扫描；156条字面脚本引用无环，未发现core反向依赖UI或UI直接读写game.state。分别核对正式提交、装备工厂、施加／替换、接触与能力、回合与敌人、捕缚、奖励、事件、商店、牢房与塔路。 |
| 冗余接口 | 删除仅供旧测试使用的Game._install_composite，14个调用转入原_install_assembly；删除Enemies.POOLS兼容代理，内容加载与测试直接读写FirstFloor.POOLS。保留具有不同目标集合语义的physical_pieces／equipment_targets／action_targets及真实调用的内部入口。 |
| 重复数据与声明 | Guard.application复用EnemyPlans.application；普通房间说明直接读取强怪组合及弱怪阈值，图鉴类别读取card_rules.TYPES。删除4个未使用UI常量／预加载，不新增规则框架。 |
| 查询与预演成本 | EquipmentOffers.links复用单次查询的接触位置，并调用正式邻接判断排除不可能组合；对照完整工厂枚举，检查候选及顺序完全一致、配额重新复核、查询不改状态或随机。Replacement使用原_assign做乐观可行性检查，并排除分数不可能优于已得方案的重复试装；链接转接只保留每个丢失集合的首个合法接法，全部链接均保留时停止等价搜索。最小移除集合、链接损失、实际比较与提交复核仍以原实现为准。 |
| 测试组织与流程 | 检查现有99个测试脚本的入口和助手归属，不另建runner。路线规则与窗口共用整理背包策略，真实丢弃／确认后才继续到出口；正常试玩在两次检查仍未离开牢房时尝试正式反抗，保持原3个种子、1800／600步上限、完整生命、资源和提交检查，不注入状态或假定胜利。 |
| 工具、内容与资源 | 4个PowerShell及4个Python工具通过语法检查；实际内容包1份与模板5份通过原内容校验。核对场景、资源路径和脚本UID，未发现缺失静态资源引用或重复UID；60张PNG／SVG无完全相同文件。不重新处理素材，不清理未知动态资源。检查器的故意报错与超时反例均正确拒绝。 |
| 文档 | README从413行整理为102行，保留启动、操作、架构归属、权威文档、门禁与素材来源；原存档章节原样保留。AGENTS与内容文档去掉旧怪池代理、旧施法／收押条件、过期组合数量及重复辅助说明，保留用户鼓励语与长期维护要求。 |

过程中的失败与复核：

- 首轮全窗口的基础长路线未处理新增掉落带来的pack阶段；最终到达出口断言失败。补齐正式整理操作后，基础窗口流程283项通过。没有跳过背包容量或直接写phase。
- 正常开局的密集装备场景暴露链接枚举与替换预演的重复工作；原执行途中停止以进行定位，停止的进程不记为通过。临时诊断只使用本轮构造的内存夹具，没有经过存档加载器；诊断脚本与二进制夹具在完成后删除，日志保留。
- 新增链接对照案例最初误用普通绳索和单侧位置参数，改用合法细绳工厂夹具后，links及关联分类1309项通过；其中links163项。新塔路说明案例的局部变量与已有变量重名，修正命名后重新执行完整所选分类，没有删断言。
- 原自动试玩从不选择反抗，在重复检查中长期循环；策略改为根据只读投影中的真实检查次数选择正式反抗，已有可逃离入口仍优先。此策略只用于测试，游戏规则和玩家操作不变；结果不能据此解释为胜率或最终平衡结论。
- 替换专项最终671项通过，包含密集强装备提前拒绝、密集弱装备保持合法替换、等价链接转接去重、纯查询不变以及完整原子提交。日志：build/checks/20260909T124325413-54064/check-rules.log。
- runner专项20项通过；故意脚本错误和1秒挂起反例均未误报PASS，日志：build/checks/20260909T122821197-40904/。

最终覆盖与日志：

- 41个非存档、非正常试玩规则分类使用完整原随机矩阵，10771项断言通过（enemy_cycle 16/16、enemy_pool 24/24、tower_graph 201/201）；日志build/checks/20260909T123752550-46596/check-rules.log。
- 最终42个非存档规则分类一次运行全部通过：12308项断言，1717.56秒，Godot退出码0；完整enemy_cycle 16/16、enemy_pool 24/24、tower_graph 201/201。日志build/checks/20260909T124419823-26252/check-rules.log。normal_play保留原3个种子，共1534项断言：42／cautious执行572步到达prison_end，20260906／elite执行422步通关，7／trade执行531步到达prison_end；全部最终状态校验通过，没有到达1800步上限。此前独立试玩用于定位，已停止并由本次运行替代，不记为通过。
- 34个非存档窗口分类已分批复核，最终合计3922项断言无未处理失败。首轮全窗口3918项仅rewards中1条旧施法断言失败，其余32个分类3810项通过、casting 58项通过；日志build/checks/20260909T124429381-48580/check-ui.log。奖励案例按当前手／嘴可选路径补齐正反例，并把仅限双手的限制检查移到真正仅限手部的术式解锁；免费准备面不掷施法概率的边界保留。之后完整rewards＋casting共112项通过（54＋58），日志build/checks/20260909T130227183-51132/check-ui.log。中间一次复核仍引用旧原因句而失败，已改为当前具体手掌／手指条件；失败日志130056704-53684保留。本结论是最终分类结果合计，不把首轮失败运行记为整体PASS。

运行性能仍有余项：seed 42正常试玩572次正式操作耗时1051862ms，最终97个装备目标并到达五级高安全监室；seed 20260906执行422次操作、133778ms到达通关出口；seed 7执行531次操作、373627ms到达高安全监室。整局时间包含投影和校验，且曾与窗口测试并行，不能据此声称平均帧率或稳定加速倍数；但逐操作诊断已确认密集装备下有秒级链接／替换预演成本。本轮已减少无效枚举和等价预演，现有功能断言通过也不代表这一性能问题已完全解决。

覆盖指所有目录的接口／依赖／资源接线及上述现有门禁，不等于穷举所有装备、卡牌和内容组合。没有新增截图，没有导出或发布。

## 2026-09-09 当前框架与接口复查（首领、施法及捕缚接入后）

- 扫描core/data/ui共78个运行时脚本、159条字面脚本引用：没有引用环、core反向依赖UI、UI访问game.state／Game内部写接口，未发现五行以上完全相同的函数体。核对新增CaptureBind、CardRewards、RelicRewards与原Game提交、施加、效果生命周期、只读投影的接线。
- 六缚普通施加复制了通用普通施加的整份声明，现改为调用EnemyPlans.application并设置原替换权限。保留来源池、等级、紧度、数量、文案和执行时机，不新增接口或改变随机算法。
- 架构案例增加魔导无人机和魔导拘束盒正式回合后的捕缚投影检查；查询不得改变状态或随机，公开视图不得引用权威状态、卡牌增益或遗物注册表中的可变容器。
- 用户中途明确存档等整个Demo完成后再跟进：已停止本轮存档专项，撤回刚新增的专项案例，没有修改存档运行时代码。相关检查时机已写入AGENTS.md；此轮不认定存档部分完成。
- 范围收缩前的基线运行：`tools/check.ps1 -Suite architecture,casting,rewards,enemies,persistence,runner -Exhaustive -TimeoutSeconds 600`，7789项通过，150.66秒；日志`build/checks/20260909T115148385-51796/check-rules.log`。之后不再选择存档专项。
- `tools/check.ps1 -Suite architecture,enemies -UI -UISuite enemies,casting,status -TimeoutSeconds 600`：规则2390项通过（69.97秒），其中architecture 31项；采用原日常抽样，生成算法未修改。日志`build/checks/20260909T115702544-48120/check-rules.log`。
- 同次窗口运行269项中，施法提示悬停1项失败；status 30项与enemies 182项无失败。该案例翻面后直接取卡牌矩形中心，改为沿既有card_point先移出再移入，明确触发原生悬停；保留提示断言，增加实际投影概率与悬停不改变状态的检查，不改运行时施法或UI行为。关联日志为同目录`check-ui.log`，不将这次失败运行记为整体通过。
- `tools/check.ps1 -UIOnly -UISuite casting -TimeoutSeconds 300`复查58项通过，Godot用时18.40秒；日志`build/checks/20260909T120003276-54228/check-ui.log`。最终关联窗口分项合计270项（58＋30＋182）无未处理失败，非一次全窗口运行。不新增截图，不运行全项目all或存档专项。

## 2026-09-10 单侧手部区域计分

- 手掌／手指任意侧存在有效拘束即计入手部合计1分，不按件数、左右或掌指重复累计；全覆盖4级仍要求双侧手掌和手指都受限。其他部位权重与共同固定判定不变，无新增分侧结构或状态字段。
- 单侧包裹纳入状态计分来源；左右握持、施法及辅助继续独立，辅助触及保留原共同固定／捕缚条件，避免区域总分限制自由侧。教程、设计和README同步。
- 复用现有检查覆盖单／双手包裹计分、解除后归零、单侧不满足全覆盖／双侧全覆盖、自由侧施法与切割、辅助伤害、药水站姿限制与坐姿使用、状态来源。
- `tools/check.ps1 -Suite equipment_complete,consumables,status,hand_assist,basic_attacks -TimeoutSeconds 300`及自动关联分类通过2953项，44.23秒。日志：`build/checks/20260909T155427517-50836/`。未新增截图、测试框架或存档专项。

## 2026-09-10 药剂姿势限制

- 用户最终修正：站姿上肢分值＜1且能握持即可，含0.5；坐／躺绕过握持。嘴部半效独立计算。抽出原分级计算保留0.5，其他行动经level向上取整保持原行为；无新增状态或玩家接口。物品说明、具体禁用原因、教程及设计文档同步。
- 现有consumables分类覆盖三种药剂的0／0.5／1边界、站姿拒绝不扣资源、双手无法握持时坐姿全效和躺姿嘴部半效实际使用、物品说明投影；嘴部单独拘束仍可站着喝，卷轴坐姿仍需原操作部位资格。
- `tools/check.ps1 -Suite consumables -TimeoutSeconds 300`：50项通过，2.50秒；日志`build/checks/20260909T150102495-8036/`。无新增截图或存档专项。
- 扩大分类`consumables,pressure`未全绿：药剂50项与pressure118项无失败，关联事件检查出现room_events.gd缺少choices字段等错误，最终7/1171断言失败、56引擎错误；日志`build/checks/20260909T150013292-50352/`。未扩大修改事件逻辑。同文件行动回滚处两行多余缩进已纠正；此前脚本加载失败已随后续成功运行排除。

## 2026-09-10 强怪组合扩充

- 新增双无人机、双强怪魔法阵、绳蛇＋强度1弱怪、多面手＋奴隶贩子；绳蛇后台强度3，生命和行动不变。复用固定成员与弱怪预算，无新增接口、存档字段或截图。
- 更新已有敌人检查：四种实际编队、总强度4、绳蛇弱怪补位及奴隶贩子入池；连续组合去重仍沿原正式入场检查。UI与日志沿原成员／组合投影，文档同步。
- 最终运行 `tools/check.ps1 -Suite enemies -TimeoutSeconds 300`：2394项断言中2393项通过，新增组合及去重检查通过。整体门禁未通过：`enemy_heap_cases.gd:123`的战后恢复检查报“战斗遗物领取记录损坏”。按用户暂缓存档工作的要求保留失败记录，不改存档、不跳过断言。
- 日志：`build/checks/20260909T143635636-32492/check-rules.log`。此前两轮分别修正旧的奴隶贩子不入池断言、未注册练习夹具及不应依赖战场显示顺序的组合断言。

## 2026-09-09 状态牌分类

- 玩弄、玩弄+从诅咒分类调整为状态牌，同步卡面、图鉴分支、筛选和状态统计；原效果及临时清除规则保持不变。
- 运行 `tools/check.ps1 -Suite curses,encyclopedia,status -UI -UISuite home -TimeoutSeconds 300`，相关规则2186项、首页界面81项通过；未新增截图检查。
- 日志：`build/checks/20260909T114236030-43232/`。

## 2026-09-09 魔导拘束盒

- 接入64生命、后台强度4的单只强怪组合、独立练习、图鉴和机械箱体立绘。普通池保留皮革与口球，回合被动仅皮革；机械类复合施加授权现有替换流程，普通施加不扩权。
- 正式回合验证：首次40捕缚，下一玩家回合被动后50；固定坐姿；施加／累计四档加固→准备→备用复合装备循环；捕缚解除后准备再施加，不补充库存。来源死亡停止其被动，其他来源继续。
- 三件库存成功才消耗，合法候选在出手时随机选择；满位替换弱外层、过强外层阻止替换并保留库存、全用完后捕缚＋10均通过。准备后的保存恢复得到相同下一步，重复库存索引原子拒绝。
- 强怪池检查从固定三组计数改为读取注册表，仍验证总强度4、实际编队与不连续同组。新例复用enemies入口，没有新增检查框架或截图。随机库存选择保留16种子覆盖，完整三件消耗流程仅跑一次，不按每个种子重复安装三套。
- 完整受影响检查：`./tools/check.ps1 -Suite guard,enemies,application,replacement,persistence,status -Exhaustive -UI -UISuite enemies,guard,status,persistence -TimeoutSeconds 600`。规则7200项、窗口298项通过；日志`build/checks/20260909T084443155-32688/`，规则205.51秒、窗口107.40秒。
- 测试去重后仅重跑敌人及其关联分类：`./tools/check.ps1 -Suite enemies -Exhaustive -TimeoutSeconds 600`，4595项通过、109.52秒；日志`build/checks/20260909T092525833-47852/`。运行时代码与已验证窗口未再修改，无重复窗口或截图检查。

## 2026-09-09 魔导无人机与同种去重捕缚

- 魔导无人机进入弱怪池、独立练习和图鉴，32生命／后台强度2；机械坚硬、三步循环、2能量被动施加与累计加固2档均通过正式行动结算。没有合法胶带目标时不选择加固，预告后失去目标则空过。
- 从Guard移出共用捕缚逻辑至CaptureBind，保持单一进度条和原拖牌目标。按种类保存来源与余数；同种不叠加，异种按新种类初始值的一半增加；55与65两个顺序、重复实例／同类新实例均有检查。固定站姿、来源离场、归零清除、100后下一敌方回合收押复用现有回合与监狱流程。
- 敌方阶段冻结当阶段已预告行动，防止中途达到100后后排敌人即时改成收押。坚硬在每次实际命中按伤害属性处理；状态、意图图标、伤害说明、日志、教程和图鉴同步。
- 存档修订号仍集中于Snapshot.REVISION，不迁移旧档。新来源结构、残余能量、保存恢复后相同下一步、非法来源与过期动作的原子拒绝通过。
- 新例集中于drone_cases并由既有enemies分类单次调用；原24路线种子继续验证入场，完整成员可达改用有限直接怪池抽样，避免为观察新成员反复建塔。截图为0，未增加独立检查框架。
- 最终命令：`tools/check.ps1 -Suite guard,enemies,basic_attacks,persistence,status -Exhaustive -UI -UISuite guard,enemies,status,persistence -TimeoutSeconds 600`。规则 **7059项通过**（126.09秒），窗口 **294项通过**（103.68秒），引擎退出码0且无错误。完整enemy_cycle 16/16、enemy_pool 24/24。
- 日志：`build/checks/20260909T081051724-37752/check-rules.log`、`check-ui.log`。此前失败为原抽样集未覆盖扩大的全部弱怪，已由上述定向采样修正并复查。不是全项目all回归。

## 2026-09-09 八件遗物、力量／灵巧与特殊战斗

- 新增魔力耳坠、准备背包、光滑的丝袜、甜甜圈、神秘药剂、小刻印、体术书、草莓，登记稀有度、真实效果、图鉴、教程和状态文案。草莓／神秘药剂由共用拾取入口永久写入mana_max，再恢复对应魔力；事件、购买和精英奖励共用入口，恢复不会重放拾取。
- 复用RelicEffects统一普通／特殊战斗开场、首回合和结束；combat保存场次编号、首回合、余能、耳坠余数。巡视暂停不重开，反抗／整备／返回牢房分别进入新场次；结束只结算一次。魔力耳坠统计实际支付、包含失败和固定兑换；非出牌阶段不累计，余数本场保留。甜甜圈在回合末效果之后保存能量。
- 力量加入挣扎及三组体术每段基础伤害；腿足灵巧按真实滑脱部位加入主动和移动被动，不扩大方法资格或重复叠加部位。原状态／手牌加值、倍率和预览／提交共用；魔法攻击不加力量。
- RelicRewards与原奖励／商品／事件流程接线，独立relic随机域、已展示去重、精英一件、商店两个一般货位及大小宝箱分布。空稀有度沿剩余池回退，暂无首领／商店专属池时不伪造。规则来源及适配边界见game-design第10节。
- Snapshot.REVISION已更新，保存上限、场次进度及已抽遗物，拒绝损坏状态，不迁移旧档。事件回归发现外部JSON整数字段counter以浮点进入冻结结果，在既有冻结边界规范为整数，未增加事件接口。
- 新例收进现有rewards分类，覆盖拾取／恢复／重复拒绝、真实兑换支付、非法动作回滚、四类场次、巡视暂停恢复、放大后的魔力上限、体术变体、部位限定、被动滑脱及掉落分布。旧用例移除固定遗物总数、固定唯一稀有遗物和旧版无特殊战斗回魔假设；没有复制测试入口或新增截图。
- 最终命令：`tools/check.ps1 -Suite rewards,services,status,basic_attacks,slip_motion,persistence,casting,events,content -Exhaustive -UI -UISuite rewards,services,home,persistence,status -TimeoutSeconds 600`。规则 **7801项通过**（199.89秒）；窗口 **255项通过**（53.90秒）。随机生成修改采用完整enemy_cycle 16/16及enemy_pool 24/24种子矩阵。
- 最终日志：`build/checks/20260909T072723328-33628/check-rules.log`与`check-ui.log`。退出码0、无引擎错误、无截图；未运行全项目all、导出或发布。临时修改脚本与诊断脚本已移除，正式检查日志保留。

## 2026-09-09 遗物核对与三档分类

- 现有7件遗物明确登记common／uncommon／rare。余烬护符、折叠工具匣、回身缎带为普通；整备沙漏、断缚护腕、游丝指环为罕见；余烬晶石为稀有。数值、触发机会、抽取权重和价格不变，初始遗物不因分类进入奖励池。
- 核对实际调用后，将余烬晶石正文从泛指“耗魔行动”修正为首次付费施法返还实际支出50%，失败同样返还、零支付保留机会；设计页去掉过时“比例待定”。没有改写施法或遗物触发逻辑。
- 图鉴新增遗物分类及三档筛选，持有列表、状态来源、商店小标签和宝箱说明复用注册表投影。内容包rarity为必填，未知／缺失值拒绝，模板与设计示例同步。存档只持有原ID，不新增存档字段或修订号。
- 案例加入现有encyclopedia／content／home／services模块：注册覆盖、初始来源保持、只读视图、内容包字段保存与错误拒绝、首页真实筛选、商店可见标签；未新建测试框架或重复遗物效果测试。
- 先用ListOnly确认范围，再执行`tools/check.ps1 -Suite rewards,content,services,encyclopedia,status -UI -UISuite home,services,rewards -TimeoutSeconds 400`。规则**3241项通过**（118.64秒）；窗口**166项通过**（33.83秒）。规则按日常抽样enemy_cycle 4/16、enemy_pool 4/24，分类未改随机生成算法。
- 日志：`build/checks/20260909T062917372-48704/check-rules.log`及`check-ui.log`。最终退出码0，无引擎错误，无截图，未运行全项目all或导出发布。

## 2026-09-09 双面新卡、独立来源增益与稀有度奖励

- 接入强力肘击、欲能转换、魔力转换、魔力涌流、henshin；火焰精通双面共存。来源ID分别保存／派生，伤害相乘、同源不叠加；真实费用、施法失败、消耗区、多段完成后消耗、完整解除及战斗清理均沿原事务。状态栏和能力区显示实际来源／牌面。
- CardRewards采用尖塔1逐张稀有度及动态修正，正常／精英／首领／商店区分来源，显式事件池保留限定抽取；固定百分位覆盖概率带，不用大型概率模拟。奖励修正、双面能力和独立增益均覆盖快照恢复及下一次动作。规则详见[卡牌框架](card-framework.md)。
- 新案例card_expansion_cases由rewards唯一调用，不建新runner；rewards交叉关联增加equipment／slip_motion。旧power案例明确选择牌面，防止测试助手从另一合法牌面出牌；窗口发现并修正能力区默认面未反映已打出面的实际问题。新增移动案例读取原子提交后的目标，工具案例使用正式可触及目标。
- 扩展种子5、10暴露旧heap断言禁止链接，与已冻结的绳索池包含链接规则冲突。诊断确认新增普通件与链接均为中级三档、原链接保留，只修改旧断言，不修改敌人执行逻辑。
- 规则最终：`tools/check.ps1 -Suite rewards,casting,persistence,equipment -Exhaustive -TimeoutSeconds 800`，**8099项通过**，138.10秒，enemy_cycle 16/16、enemy_pool 24/24。日志：`build/checks/20260909T054750186-37468/check-rules.log`。
- 商店分类补充：`-Suite services -Exhaustive -TimeoutSeconds 120`，shop_release／services **182项通过**，1.74秒，日志：`build/checks/20260909T055117955-6960/check-rules.log`。其中shop_release与上一命令重叠，不将两次数字相加声称唯一覆盖数量。
- 窗口最终：`-UIOnly -UISuite home,casting,rewards,interface,services -TimeoutSeconds 500`，**544项通过**，57.02秒；真实翻面、选择后提交、双面施法悬停、能力区、分类、奖励与商店，以及全部新卡双面文字边界。日志：`build/checks/20260909T054303830-14600/check-ui.log`。
- 上述最终进程退出码均为0，无引擎错误。无截图；未运行全项目all，未发布或生成新导出包。旧存档不迁移，修订号读取Snapshot.REVISION。

## 2026-09-09：框架与接口复查、随机域与施加反馈修正

## 2026-09-09 卡牌二重分类与火焰精通

- 卡牌定义显式登记技能／魔法／能力／诅咒及基础／普通／罕见／稀有／诅咒，图鉴、卡组、手牌、奖励与商店共用分类卡面。图鉴和卡组交叉筛选；基础牌及诅咒不进入常规奖励，原事件学习池仍保留三项。新增稀有能力火焰精通进入现有奖励／供货来源，没有增加稀有度抽样或随机域。
- 能力沿原自身出牌候选与费用事务进入真实powers区；统一牌区守恒、重复能力拒绝、非战斗拒绝、过期版本／费用不足回滚、回合洗牌不回收能力、胜利及收押清理、快照坏数据拒绝和恢复后正式施法均有验证。火球术独立忽略口部倍率并失去手势增伤，保留快感概率及法术费用，不改变其他法术。
- 新案例模块card_power_cases由rewards唯一调用；补充rewards关联persistence／status，复用原分类选择器。新窗口案例由casting唯一调用；首页验证稀有能力筛选，卡面最小高度检查覆盖手牌文字边界。
- 规则：`tools/check.ps1 -Suite rewards,casting,persistence -TimeoutSeconds 360`，**5079项通过**。实际选入consumables、basic_attacks、battle_saturation、replacement、application、architecture、installation_priority、event_flow、curses、encyclopedia、shop_release、content、installed_tools、environment_height、exploration、shoulder、slip_motion、torso_binding、casting、special_equipment、status、persistence、rewards、core、links、prison、enemies、trader，逐项去重；173.25秒。日志`build/checks/20260909T042601325-44380/check-rules.log`。
- 窗口：`-UIOnly -UISuite home,casting`，最终紧凑卡面版本**100项通过**，日志`build/checks/20260909T043313475-14576/check-ui.log`；`-UIOnly -UISuite rewards,interface,services`，**415项通过**，日志`build/checks/20260909T043746001-11100/check-ui.log`。共515项窗口断言，真实点击、翻面、能力区、交叉筛选、商店与奖励共用卡面均通过；所有引擎正常退出，无错误，无截图。
- 本批未运行全项目all或发布。沿原存档修订策略拒绝旧档，不做迁移。完整规则与源码扩展模板见[卡牌框架](card-framework.md)。


静态扫描覆盖core/data/ui的75个运行时脚本、152条字面脚本引用：未发现引用环、core反向依赖UI、UI直接访问game.state／内部写接口或五行以上完全相同的函数体。进一步复核新监狱路线、普通／复合混合施加与批次保护、消耗品、掉落、存档及只读投影。相似工厂、查询、事务与显示入口职责不同，未按文件行数或名称强行合并。

确认并处理的问题：
- 随机域名单在Game初始化、Snapshot字段规格及新增item_drop的补充初始化中重复维护，内容生成说明也已漏掉新增域。初始化与恢复校验改为共同读取data/balance.gd::RNG_SALTS；不改任何盐值、计数推进或随机算法。原校验接受未登记域的缺口已由失败案例复现，现在拒绝多余、缺失、非整数与负计数，失败不改当前状态。合法存档结构不变，Snapshot.REVISION本轮不提升，旧档仍不迁移。
- runner旧断言要求persistence排除prison，与新增监狱路线的实际交叉归属冲突。修正为包含监狱读档，同时排除递归带入的tower_progression／normal_play，保留原去重与一次展开约束。
- `_plan_install`没有正式调用，只剩测试在走旧预选流程；删除该入口，将案例接回Application及正式敌人回合。批次生成仍使用的`_install_choice`保留。装备测试不再从新apply声明读取旧slot字段；事件验证白名单补齐已实现的sequence行为。
- 正式apply结果对链接沿用普通单部位coverage，导致反馈遗漏第二端；现在读取链接真实slots，不改变普通装备覆盖规则。同一敌人同一操作的多次安装日志原只保留第一条slots，现在按事件顺序合并全部实际部位并去重。正式链接回合、商贩批次及窗口高亮检查覆盖修复，播放结束不改游戏状态。
- 补充初始化全域零计数、逐域坏数据、监狱地图查询无状态引用泄漏，以及真实领奖返塔重置全部随机计数／保留本幕掉落概率的交互检查。按game-design第6.2节，逃狱重建仍在第一幕，掉落概率保留符合规则，未擅自重置40%。

所有范围先经ListOnly确认。记录：
- 修改前现行功能基线：tools/check.ps1 -Suite architecture,prison,consumables,application,replacement,persistence,tower -Exhaustive -UI -UISuite prison,route,consumables -TimeoutSeconds 240，通过8106项规则、214项窗口断言；85.50秒／62.48秒。日志build/checks/20260908T165038756-50156/，包含enemy_cycle 16/16、enemy_pool 24/24、tower_graph 201/201。
- 新增拒绝案例在旧实现上的复现：-Suite persistence，3910项中1项失败，未登记随机域被恢复；build/checks/20260908T165233635-37348/check-rules.log。
- 首轮全规则回归在11959项中发现3项断言失败及4次引擎错误记录：runner交叉归属过期、两个法阵的sequence白名单遗漏、装备案例访问已废弃的预选slot，build/checks/20260908T165422919-49852/check-rules.log；修正后runner专项20项通过（0.79秒），build/checks/20260908T165610800-31952/check-rules.log。
- 测试改接正式施加后，6480项中复现链接反馈漏报1项，build/checks/20260908T170238146-21860/check-rules.log；修复后-Suite equipment,events,installation_priority,enemies -Exhaustive通过6480项（62.97秒），build/checks/20260908T170717845-46536/check-rules.log。
- enemy_feedback窗口42项中复现批量部位与高亮2项失败，build/checks/20260908T170830214-43124/check-ui.log，保留案例并修正合并逻辑。
- 随机域调整后，-UIOnly -UISuite prison,route,consumables,persistence通过273项窗口断言（78.16秒），build/checks/20260908T165654026-43728/check-ui.log。
- 反馈修正后，-UIOnly -UISuite enemies,enemy_feedback通过211项窗口断言（80.83秒），build/checks/20260908T170924101-9684/check-ui.log；含真实链接双端、批量全部部位高亮、显示播放不修改状态。

最终`tools/check.ps1 -Suite all -TimeoutSeconds 300`完整规则回归通过11970项断言（214.35秒），涵盖全部43个分类，enemy_cycle 16/16、enemy_pool 24/24、tower_graph 201/201完整种子；日志`build/checks/20260908T170849131-41384/check-rules.log`。本轮关联窗口合计484项通过（273＋211），并非全窗口all。完成运行均通过退出码、成功标记与引擎错误门禁。无美术修改或新增截图。

最新批次（2026-09-09，敌人阵列与魅魔警卫对齐）：敌人行按788—1568的完整战场范围计算居中起点，单人右移88像素、双人右移130像素，三人以上继续使用原完整宽度；行动日志不再占用阵列布局范围。魅魔警卫专用146像素立绘框右移70像素，与意图、光圈、名称及血条共用中心，点击区域同步。`tools/check.ps1 -UIOnly -UISuite guard,enemies`通过199项窗口断言，单／双警卫截图已复核。

最新批次（2026-09-09，拘束等级战斗立绘）：用户提供的坐姿与卧姿原图通过项目本地GrabCut脚本生成真实透明PNG；坐姿臀部下方低色度投影杂色已以最低前景连通条件清除，未调用生成工具或重绘人物。只读视图统一投影`has_restraint_level`，双臂／双腿任一等级大于0时切换拘束态坐／卧图，拘束态站姿直接复用装备栏组合器；仅眼／口装备不虚构肢体等级。`tools/check.ps1 -Import -UIOnly -UISuite hero_art,equipment_art`通过190项窗口断言，并生成站／坐／卧三张实机截图。

## 2026-09-09：链接池覆盖、魔法阵满位加固与眼部两件上限

本批核对发现：魔法阵旧循环只施加且普通白名单漏了链接；通用事件随机冻结只接受install，也会拒绝生成器返回的link。按用户随后确认，改为EquipmentOffers.for_pool单点派生：普通池含绳索／细绳／皮带／细皮带／皮革眼罩及其base_template派生款时，自动加入既有合法链接绳。敌人、监狱、批量动作、事件统一消费；链接保持第三优先级、两端真实装备、方向容量与具体装备对唯一，不占普通格、不免费补端。明确上锁、指定部位／位置继续复核两端。复合、特殊装备及仅口球等池不因皮革材质而被扩充。

事件生成结果可冻结为link，通过原execute_concrete提交，沿已有探测副本与事务实现版本复核、费用和失败回滚；预览、日志显示两个真实位置，快照复用现有链接意图形状验证。警卫普通名单排除已移出的布带眼罩。两种魔法阵以tighten_missing显式开启无处新增后的逐次普通加固；其他意图无目标空过规则不变，空间耗尽判断同时检查该能力。眼部容量在Equipment.capacity集中改为2，安装、替换、存档、投影共同遵守。集中修订号更新，旧档不迁移。

规则分类`tools/check.ps1 -Suite enemies,equipment,events,persistence,links -TimeoutSeconds 360`共5241项通过，日志`build/checks/20260908T174711258-1880/check-rules.log`。窗口分类`tools/check.ps1 -UIOnly -UISuite enemies,intent,equipment_complete,events -TimeoutSeconds 240`共346项通过，日志`build/checks/20260908T174721538-29432/check-ui.log`。均先ListOnly确认范围，未运行all或完整随机矩阵，未生成截图。

新增或修订案例覆盖真实来源池的第三档链接候选与提交、皮带变体实际链接、事件公开两端及同版本恢复、端点消失时连同费用原子拒绝、魔法阵先补最后一条链接再加固、全空间耗尽只结算一次、眼部跨材质共享两格、第三件拒绝、损坏存档拒绝及合法外层替换。首轮发现旧测试把“皮带没有链接”和“普通格满即必须替换”当作前提；复合数量／强度边界改用不会额外生成链接的胶带来源保留覆盖，监狱用例分别验证链接余地优先和连同链接完全饱和后的替换。另修正一处测试读取事务前旧对象引用的问题，最终用提交后的真实编号查询。后续仅同步文档。

## 2026-09-09：独立监狱路线与领奖后重新攀塔

离开牢房统一进入出发点、5回合休息点、出口精英战组成的独立监狱地图；复用现有房间图、移动、休息、战斗和奖励提交。出口固定生成当前警戒度数量的魅魔警卫，必须击败全队，只结算一次奖励。领取或跳过后返回新塔路，超容量先走原整理流程，不追加战后整备或返程恢复。新种子在正式提交中生成，重置地图与遭遇随机进度，保留角色、装备、卡组、资源、警戒度和存档归属。实例编号继续递增，同版本领奖页恢复会生成相同的新种子；旧档不迁移。

沿prison现有分类验证可继续探索的1—4级警戒对应人数、不可跳过休息点、移动与奖励页恢复、损坏路线原子拒绝、多人战一次奖励、容量整理先于返塔、状态保留和失败后再次收押。tower_progression沿正式行动通过新增路线；normal_play的旧限时检查点明确标为到达监狱路线，不冒充通过出口。

ListOnly确认后执行`tools/check.ps1 -Suite prison,tower,persistence,rewards -TimeoutSeconds 240`，4514项通过，日志`build/checks/20260908T163124463-11204/check-rules.log`。首轮发现普通奖励记录清理范围扩大导致旧塔路案例索引失败，已将清理收窄到监狱出口奖励并完整复跑上述分类。窗口执行`tools/check.ps1 -UIOnly -UISuite prison,route -TimeoutSeconds 240`，205项通过，日志`build/checks/20260908T163627385-45284/check-ui.log`，覆盖地图名称、真实节点进入、五回合休息、出口战及领奖返塔。没有新增截图，也未执行all或完整随机矩阵。最后只同步折返符旧去向说明和文档。

## 2026-09-09：魅魔警卫双立绘池

用户指定两张源图作为魅魔警卫战斗立绘，并要求每只敌人独立随机、允许重复。本批使用本地 `tools/extract_portrait.py` 抠除边缘连通白底，没有调用图像生成工具；两张输出均含真实Alpha且四边透明，源图、裁框和哈希记录在 `assets/art/enemy-guards-v1/README.md`。

规则只新增数据声明 `guard.visual_pool`、独立 `enemy_visual` 随机域和敌人实例的稳定 `visual_variant`。双警卫逐只调用有放回抽取；只读投影公开选中ID，Arena据此加载透明PNG。行动随机域保持独立，UI刷新不抽取。敌人状态和随机域进入快照校验，`Snapshot.REVISION`提升至12，旧档继续按既定策略拒绝而不迁移。

先用 `tools/check.ps1 -Suite guard,persistence -UI -UISuite guard -ListOnly` 查看影响范围。规则最终执行 `tools/check.ps1 -Suite guard,persistence -TimeoutSeconds 240`，相关23个规则模块3846项通过，日志 `build/checks/20260908T154431635-45480/check-rules.log`。日常随机样本为 enemy_cycle 4/16、enemy_pool 4/24，未运行全项目all。

资源导入后执行 `tools/check.ps1 -UIOnly -UISuite guard -Import -Screenshots ui-34-guard-intent.png,ui-36-double-guard.png`，警卫窗口25项通过，日志 `build/checks/20260908T154029134-46088/check-ui.log`。实际截图确认透明背景、单人完整比例及双警卫同场重复立绘。随后工作区并行新增主角姿势资源；重新导入后复跑在既有收押界面读取 `view.prison.toy_rule` 时失败，警卫立绘映射断言此前已通过，失败点与本批敌人美术状态无关，日志 `build/checks/20260908T154649586-29752/check-ui.log`。本批没有改动该并行中的收押投影工作。

并行资源稳定后，尾巴围住的封闭白底由两个明确背景种子清除；最终执行 `tools/check.ps1 -UIOnly -UISuite guard -Screenshots ui-34-guard-intent.png,ui-36-double-guard.png,ui-guard-brown-portrait.png`，27项通过，日志 `build/checks/20260908T155219504-40320/check-ui.log`。三张截图分别覆盖紫发单人、双警卫允许重复和棕发单人；另用 `build/guard-cutout-preview.png` 在深色棋盘底检查两张透明轮廓及白色服装保留。

## 2026-09-08：当前架构复查与分类门禁修正

复查core/data/ui共73个运行时脚本及150条字面脚本引用，未发现引用环、UI直接访问game.state或core反向引用UI。沿Game提交、Application/Replacement、EnemyPlans能力检查、连续攻击、瞬时反馈与Snapshot/SaveStore恢复边界复核；没有确认新的运行时接口冲突。本次没有改动游戏规则、存档结构或美术；静态扫描和以下分类回归不代表穷尽全部组合或全项目all。

修正四类维护缺口：
- AGENTS、README与内容扩展／生成说明仍混有旧的预选装备目标、无目标执行时补施加、prepared/attachment字段及互相冲突的当前存档版本数字。现行接口说明改为敌人出手选择、事件沿自身阶段冻结；当前修订号统一引用Snapshot.REVISION，保留旧档不适配及恢复失败回主页策略。历史验证记录仍保留当时版本。
- basic_attack_cases与battle_saturation_cases原先仅内嵌在core，单独选enemies或application会漏跑对应交叉行为。两文件分别登记为basic_attacks与battle_saturation，移除core内重复调用，并用runner案例检查相关分类纳入和组合去重。architecture增加人形敌人练习及基础攻击注册表引用隔离检查。
- 日常奖励分类会带入敌人测试，绳蛇的双分支断言在旧4种子日常样本中失败；完整16种子通过。该定向案例现始终保留完整16种子，不删除断言、不修改随机或正式行动。失败证据：build/checks/20260908T113412957-15468/check-rules.log。

- 卡牌动画窗口案例沿用默认frames/click等待，新增的抽牌落位等待会在断言前消耗完整动画，导致四项中间态检查失败。现有助手增加settle_feedback选项，默认仍等待落位；只有明确观察动画的三个调用只等待真实布局／绘制，保留原生控件提交、全部断言、到达期限与状态不变检查。失败日志build/checks/20260908T114109438-5696/check-ui.log。

验证均先查看ListOnly：
- tools/check.ps1 -Suite architecture,application,replacement,core,enemies,persistence -Exhaustive -UI -UISuite enemies,intent,persistence -TimeoutSeconds 240：5554项规则／250项窗口通过，规则96.36秒、窗口84.17秒；日志build/checks/20260908T112855869-12480/。这是分类调整前的现行功能基线，包含enemy_cycle 16/16及enemy_pool 24/24。
- tools/check.ps1 -Suite runner,architecture,basic_attacks,battle_saturation：调整后81项规则通过，11.78秒；日志build/checks/20260908T113311483-45500/check-rules.log。
- tools/check.ps1 -Suite rewards,runner -UI -UISuite basic_attacks,rewards,trader -TimeoutSeconds 240：抽样修正后2054项规则通过，27.28秒；日志build/checks/20260908T113543253-42716/check-rules.log。本次窗口在240秒后超时，日志build/checks/20260908T113543253-42716/check-ui.log；不能记为通过。单独基础攻击随后16项通过（10.20秒，build/checks/20260908T114034073-16720/check-ui.log），同组合重跑复现上列四项动画观察失败；初次超时的原因尚未确定，后续未再复现。

- 动画观察接口修正后：tools/check.ps1 -UIOnly -UISuite basic_attacks,rewards,trader -TimeoutSeconds 180，149项窗口通过（基础攻击16、人形敌人82、奖励与动画51），37.89秒；日志build/checks/20260908T114237118-6596/check-ui.log。没有提高原240秒超时上限，没有删除失败案例。

各次范围有重叠，断言数字不相加为独立总覆盖；窗口只进行真实交互和状态核对，无截图。

## 2026-09-08：绳蛇与共用持续施加

新增40生命、后台强度2的游动的绳蛇，登记强怪图鉴、独立练习和代码绘制外观。缠身叠加紧缠，下一次各50%收紧或甩缚，再返回缠身；随机分支预告冻结，收紧目标出手时随机选定。持续施加由`EnemyPlans.activate_install/tick_install`共用：绳蛇按层数在玩家回合结束时触发，一堆绳／皮带固定1层在玩家回合开始触发。死亡／分裂清除来源层数，既有装备保留。没有新增随机强怪组合。

状态从旧布尔值改为真实层数，快照修订号升至4，不迁移旧版；同版本读档、非法层数原子拒绝、打断续接已验证。新案例合入已有enemies分类，覆盖两种随机分支、先后手时机、延后的施加、叠层、多来源独立及死亡停效；原heap案例继续覆盖绳／皮带单件增生和分裂后的停效。

先通过`-ListOnly`检查范围，再运行`tools/check.ps1 -Suite enemies,persistence,status -Exhaustive -UI -UISuite enemies,status`：规则5213项通过，enemy_cycle 16/16、enemy_pool 24/24，80.18秒，日志`build/checks/20260908T105813099-11140/check-rules.log`。没有运行全项目all。

窗口检查发现旧状态栏案例把攻击的所有可切换形式都当作常驻按钮，改为检查实际四个`BasicAttack`控件，保留深呼吸布局与真实点击验证。随后仅重跑`tools/check.ps1 -UIOnly -UISuite enemies,status`：185项通过，63.12秒，日志`build/checks/20260908T110149959-45500/check-ui.log`。无截图。

## 2026-09-08：30生命的小型魔法阵进入弱怪池

新增`small_circle`，从现有强怪法阵深复制定义，仅调整名称、排序、生命30和后台强度1；共用5点仪式和两档装备施加，不另建行动逻辑。登记真实弱怪来源、分类、图鉴和独立练习。顺序型敌人的入场资格读取已声明施加规格与既有安装候选；弱战和强怪组合的弱怪成员都会沿原预算抽到该类型。

验证入口先用`-ListOnly`确认，再运行`tools/check.ps1 -Suite enemies,tower -Exhaustive -UI -UISuite enemies`。规则5841项通过（enemy_cycle 16/16、enemy_pool 24/24、tower_graph 201/201），窗口150项通过，无截图。日志为`build/checks/20260908T104658766-33888/check-rules.log`及`check-ui.log`；规则34.64秒，窗口52.88秒。

原种子矩阵覆盖八种弱怪及重复组队；新增小型法阵30血、入池、真实施加和练习窗口检查。遍历夹具把顺序循环敌人纳入原有缩短持久战机制，仍走正式攻击。删除塔路套件里重复且按废弃“无目标自动补施加／冻结具体目标”规则编写的adaptive_cases；当前施加、加固时机和打断继续由已有application、enemies、intent分类验证。塔顶攻击集成检查改为使用正式候选伤害，不再硬编码旧6点基础伤害。

## 2026-09-08：魔法阵强怪与仪式

已接入`ominous_circle`：生命暂定40、后台强度2，强怪个体库、图鉴、独立练习与代码绘制的法阵外观。复用开场／循环计划和统一施加入口，两档规格每件独立选择；仪式及数量加成保存在真实敌人实例，沿自身回合末增长。没有新增随机强怪组合。

`enemy_ritual_cases.gd`归入已有enemies套件，验证正式行动6／11件增长、两档真实装备、满位落空、启动前／后的打断差异、同版本读档续接、损坏状态原子拒绝、死亡停效和后手一次结算。新窗口步骤通过实际练习入口及结束回合按钮检查法阵、状态和真实施加。没有新建测试启动器或截图测试。

最终规则检查：`tools/check.ps1 -Suite enemies,application,persistence,status -Exhaustive -UI -UISuite enemies,intent`，先通过`-ListOnly`核对分类。规则5158项通过，日志`build/checks/20260908T103106880-20672/check-rules.log`，50.59秒；包含关联交叉分类，未运行all。

窗口初次检查揭示已有拖牌测试会在抽牌动画期间操作仍隐藏的手牌。共享等待助手现按真实`pending_draws`结束等待，与现有敌人反馈等待并列，保留超时上限，不跳过动画或直接提交卡牌。随后仅重跑`tools/check.ps1 -UIOnly -UISuite enemies,intent`：176项通过，日志`build/checks/20260908T103518321-16088/check-ui.log`，57.95秒，无截图。数值平衡未视为最终确定。

## 2026-09-08：施加／替换机制完成接入

本批完成统一施加入口与内部替换事务，覆盖普通／复合分池、空位优先、显式替换权限、最外层与最小移除集合、逐位置品质／紧度／锁／链接损失比较、复合多数比较、整批单件完整覆盖和链接转接。保留原实例工厂、特殊装备同族／容量／方法限制与事件原结果；没有新增敌人组合或旧存档迁移。

接线修正：敌人特殊池统一使用施加模块读取的`templates`；快照按池校验模板或复合选择器。普通、复合、链接、肩部及特殊的具体敌人操作也进入`execute_concrete`。人形权限与本次声明共同决定能否替换；警卫继续具备原有的成对肩部附加来源，一对组件按一次施加计数。正式结果携带实际装备ID与覆盖位置，施加反馈有标题、动作和部位高亮。

结构清理：替换直接读取Game安装检查的`capacity_full`及位置结果，不复制层级逻辑或解析中文错误。移除重复状态预演、动态检查模块是否存在的临时分支、只被测试使用的分类查询、单独的替换测试启动器及无调用导入；移除未落地`trader`规则测试的悬空登记。没有添加第二套状态或玩家提交接口。测试中的旧预备目标已改为实际声明／出手选择；牢房奖励夹具在正式开始战斗前设定先手，避免把敌人实际先手施加后的攻击限制误当作奖励流程失败。

最终验证：`tools/check.ps1 -Suite application,replacement,enemies,guard,events,persistence,core,equipment_complete -Exhaustive -UI -UISuite enemies,intent,enemy_feedback,events,persistence -TimeoutSeconds 240`。

- 规则6313项通过，enemy_cycle 16/16及enemy_pool 24/24；按分类自动合并关联模块并去重，没有运行all。
- 窗口347项通过：敌人、意图、行动反馈、事件、存档。默认未截图。
- 日志：`build/checks/20260908T080918830-45084/check-rules.log`与`check-ui.log`；规则48.24秒，窗口21.73秒。

范围限制：本结论针对施加／替换及其现有调用。工作区新敌人的完整行动循环不作为本批已验收内容；不把机制通过扩大为全部新内容或最终数值平衡通过。

## 2026-09-08：加固意图生成与执行时机

范围限定为本轮用户要求的加固意图：生成时无合法目标则从怪物已有施加意图随机选择；已生成的加固预告在执行时选择真实目标，无目标空过且推进原步骤。批量缺额不补施加，警卫复用同一生成函数。普通施加仍调用现有工厂；未为本次改动扩充装备、敌人或替换权限。删除了无调用的`prepare_special`转发函数，空批次日志直接说明动作落空，教程与行动表同步。

验证使用现有`intent`分类，包含真实卡牌解除目标、剩余目标加固、完全空过、批量部分／全部空过、警卫单步流程、生成阶段随机改选、快照恢复后继续回合和只读预览。固定夹具设置初始阶段，之后经正式候选与版本提交；不靠直接删装备模拟玩家解除。

- 范围预检：`tools/check.ps1 -Suite intent -Exhaustive -UI -UISuite intent -ListOnly`。
- 最终验证：`tools/check.ps1 -Suite intent -Exhaustive -UI -UISuite intent`，126项规则断言与29项窗口断言通过；随机样本16/16。日志：`build/checks/20260908T074213035-18580/check-rules.log`及`check-ui.log`。没有截图、没有全项目回归。
- 验证范围不包含此前尚未收尾的完整施加／替换与新敌人批次；工作区仍登记了尚缺文件的`trader`测试，旧`installation_priority`及警卫测试也有旧意图假设。本次通过不能表述为此前整批或全部敌人分类通过。

## 2026-09-08：接触与预检架构清理


## 2026-09-08：整体架构复查收尾

本轮复查覆盖core的25个、data的21个、ui的22个运行时脚本，共68个；扫描139处脚本引用，核对主场景和UI派发入口，未发现缺失脚本、静态脚本引用循环或规则／数据层反向依赖UI。结合正式调用链复核事务、卡组、装备工厂、实例与依附生命周期、回合、事件／商店、地图／牢房、存档、只读投影和反馈显示。接口归属与后续扩展约定维护在`docs/content-extension.md`及AGENTS，不另建框架或第二份工作看板。这是运行时接口和现有测试覆盖的一轮整体复核，不代表穷尽未来内容组合。

修复与整合：

- 卡组原先在运行时只比较张数，而Snapshot另有uid／类型校验；相同张数下的类型错配、孤立编号和重复卡均可能通过行动入口。现在统一由`Cards.validate`检查uid、类型与唯一性，Snapshot先保护输入形状。商店和事件删牌共用`CardEffects.remove_permanent`及`ZONES`，按实例删除全部牌堆中的对应副本，保留其他同类型牌、顺序、资源与随机。商店和肩带的重复`slip_focus`删除也归并到原游戏清理阶段。
- 普通安装的资格查询与工厂重复计算位置和层级，显式插入复合同层时只有工厂拒绝。`Game._prepare_installation`现在统一返回具体位置、层级和原因，两处消费相同结果；正常自动外层安装不变。删除已停用的`torso_rope/torso_belt`模板、旧显示／校验分支和身前／身后安装参数，41处调用同步到末尾`variant, point`。真实空间坐标、部位倍率和Binding附加状态不是该旧参数。
- 多阶段事件在真实提交中预演下一阶段时，状态副本会回滚，但独立的资源反馈记录器没有隔离，导致尚未选择的代价生成“扣费再恢复”的虚假飘字。`freeze_effects/probe`现暂停并归还记录器；预演不产生反馈，真正选择代价时只记录一次支付。未改代价、事件结果、随机冻结规则或界面布局。

失败复现：卡组边界旧实现6项失败见`build/checks/20260908T050546810-43664/check-rules.log`；复合同层查询与工厂不一致的单一失败见`build/checks/20260908T051144245-14216/check-rules.log`；事件预演虚假反馈的单一失败见`build/checks/20260908T051647280-18752/check-rules.log`。修复后均随下面的完整回归通过。

完整回归也发现三个旧测试前提：正常试玩策略在零能量时无限交替免费坐下／靠墙站起，现结束耗尽回合；窗口试玩复用已有事件选牌窗口的真实打开流程；警卫窗口改验真实意图图标和简短悬停。未放宽1800／600步上限、替换失败种子、缩短真实试玩敌人生命或改变正式规则。三条纯正常试玩分别经过354／491／311次正式行动并达到逃离结果；断言总数减少来自不再重复无进展姿势循环。窗口案例继续复核真实拖放／点击、正式提交与状态版本。

最终验证：

- `tools/check.ps1 -Suite all -UI -UISuite all -TimeoutSeconds 600`的规则阶段通过全部37个模块、10368项断言，86.67秒；日志`build/checks/20260908T051857613-21580/check-rules.log`。包含enemy_pool 24/24、enemy_cycle 16/16及tower_graph 201/201完整随机样本。该次窗口因上述旧用例失败，不能计为窗口通过。
- 仅修正窗口用例后，`tools/check.ps1 -UIOnly -UISuite normal_play,guard -TimeoutSeconds 600`通过1046项断言，49.05秒；日志`build/checks/20260908T052337546-43748/check-ui.log`。
- 最终`tools/check.ps1 -UIOnly -UISuite all -TimeoutSeconds 600`通过全部32个窗口模块、2943项断言，138.59秒；日志`build/checks/20260908T052507825-3636/check-ui.log`。与最终规则结果之间只修改窗口测试及文档，运行时代码未再变化。

最终两份全量日志均通过退出码、引擎错误和完成标记门禁。无布局／美术变动，未截图；测试存档使用原隔离目录，未触碰玩家存档。现行快照结构与合法状态含义未变，修订号仍为2，继续执行旧存档不适配、恢复失败统一回主界面的约定。



## 2026-09-08：长期维护边界与统一读档失败返回

用户明确老存档统统不适配，并要求架构调整考虑长期维护；两项约定已写入项目AGENTS。快照新增集中维护的`Snapshot.REVISION=2`，缺失、错误类型或不同修订号在改写状态前拒绝；文件编码`FORMAT=1`独立保留。档位名单统一由Snapshot维护。启动或运行中恢复失败均回主界面，显示原因并暂停自动保存，原内存与文件保留；只有明确新游戏才替换不兼容档。当前版本损坏主文件的有效备份恢复继续工作，版本不兼容不自动回退。

删除仅服务旧档的牢房四项发现池兼容、旧security/terminal固定架与专用材料分支。当前发现池要求完整匹配三项，终局沿用真实装备清单。历史兼容成功用例移除，改在存档输入边界覆盖缺失池与错误池的原子拒绝；折返符现有道具行为以当前库存夹具继续验证。

装备生命周期发现普通件被正式徒手解除后仍残留`slip_focus`。先通过真实找准松处卡牌建立效果，再提交正式解除，旧实现出现“目标已删除但效果未清除”的单一失败；证据`build/checks/20260908T044825227-41980/check-rules.log`。现由`Game._cleanup`对真实行动目标统一清理依附效果；验证一次支付、不改无关魔力和随机、重复清理达到固定点。

新增`architecture`交叉模块覆盖equipment、component_links、prison_test、succubus_three_games四种场景：查看与候选查询保持全部状态和随机域，视图不共享状态及主要内容表的可变容器。沿调用链复核事务、物理目标集合、随机域、敌方执行、遗物触发与内容注册；未把职责不同的结构校验和规则校验误合并。规则与接口结论同步`docs/content-extension.md`。

- 验证命令：`tools/check.ps1 -Suite architecture,persistence,equipment,prison,services,content,rewards,enemies,core,guard,pressure,events -UI -UISuite persistence,home,installed_tools,events`。
- 规则通过5440项断言，41.83秒；窗口通过239项断言，16.64秒。日志分别为`build/checks/20260908T045245190-28096/check-rules.log`和`check-ui.log`，无引擎错误。
- 存档窗口用真实按钮验证缺失修订号、结构损坏、JSON损坏均回主页；检查内存和原文件不变、提示可见、可开始新局。修订号案例同时放置有效备份，确认不会悄悄回退。测试均使用隔离目录，不接触玩家进度。
- 使用分类关联去重与日常随机样本，未运行全项目all或Exhaustive；未新增截图。运行后仅同步说明文档与注释，未再改变运行时行为。


`Contact.evaluate`统一生成接触原因和合法位置，`usable_slots`不再重复手部、外层及链接连接点判断；删除无调用的`Contact.mounted_reason`，牢房的同名位置检查保持独立。修复复合套体在膝上连接处外露、同区域大腿根被另一件装备覆盖时，正式切割候选合法但界面遗漏位置的问题。`FieldTools.operator_profile`统一安装／取回操作部位和原因；事件三种预检共用复制、校验与恢复骨架；随身切割清理不可达的已安装分支。保留原事务入口、版本复核、费用、材料与结构限制，沿用具体失败原因和正式切割结果文案。

先运行links分类，新增案例在旧实现中仅“合法链接应出现在位置分组”失败（`build/checks/20260908T042716337-6628/`）。修复后覆盖真实连接点遮挡反例、只读预览、过期版本和拒绝回滚、切割只扣共享绳耐久与一次工具次数，并以实际鼠标展开、滚动和点击验证入口。

关联回归发现并修正旧测试前提：敌人外观清单补入已实现的四种团／堆外观；三档免疫检查乘区，零伤害付费案例使用普通墙；塔路助手识别配置循环敌人、优先攻击低生命目标并在能量耗尽时提交正式结束回合；菜单助手先真实关闭信息面板；已离场敌人检查命中区域移除；警卫窗口明确固定合法警卫遭遇及腿部夹具，不假设随机精英必为警卫或移动后初始脚踝装备必然保留。没有改变敌人、墙面、移动或攻击的正式规则。

- `tools/check.ps1 -Suite contact,events,environment_height -UI -UISuite installed_tools,events`的规则阶段通过2447项断言，22.73秒；`build/checks/20260908T043253702-25500/check-rules.log`。该次窗口阶段因新增按钮未滚入视口失败，不算窗口通过。
- 修正窗口案例后，`tools/check.ps1 -UIOnly -UISuite installed_tools,events,baseline,tower_progression,interface`通过749项断言，50.18秒；`build/checks/20260908T043921730-41244/check-ui.log`。包含道具25、基础287、界面313、塔顶44、事件80项；无引擎错误，未截图。

仅运行受影响分类及其注册的关联模块；没有运行全项目all。架构说明同步至README与docs/content-extension.md；未安装外部分析工具，未添加新的规则框架或第二套提交接口。

## 2026-09-08：第二局无拘束具后备分支

修复三局赌牌第一局后“继续第二局”因没有可押拘束具而变成灰色的问题。多阶段事件的`when`现在可比较一个既有卡牌／拘束具选择器的实际可选数量，与事件计数条件互斥；这是通用内容条件，没有按事件ID增加操作。三局赌牌声明零件后备选项：没有拘束具时第二局直接翻牌，胜率仍为1/2；成功获得1枚心形筹码并进入第二局结算，失败进入原拘束惩罚，由可执行的随机绳索／上锁皮带选项添加拘束具。有可押拘束具时仍只生成真实实例选择，不同时显示后备项。

- `tools/check.ps1 -Suite event_flow,content,persistence -UI -UISuite events`：1986项规则、80项事件窗口断言通过，无引擎错误，记录`build/checks/20260907T171638805-38588/`。
- `tools/check.ps1 -Suite events`：903项规则断言通过，记录`build/checks/20260907T171741337-25876/`。
- 覆盖零装备进入第二局、后备项唯一且可执行、成功／失败固定种子、成功筹码、失败进入添加拘束具、候选预览不推进随机、有装备时不出现后备项、条件混填／未知选择器拒绝、内容加载、快照及原事件回归。窗口确认不再显示“这一阶段没有能够执行的选项”。本批没有视觉布局变化，依项目级截图要求保存0张截图。

## 2026-09-08：明显的事件成功／失败提示

结果页标题下新增70像素高的独立横条，34号文字与符号同时显示“✓ 成功”（绿色）、“× 失败”（红色）或“◇ 已完成”（中性金色）。输赢不依赖正文猜测：普通／多阶段选项及加权结果支持通用result_status；冻结在后台选项中，提交后保存到当前事件结果，读档保留。三局赌牌的10个既有分支均补显式标记，钥匙事件沿真实命中结果设置标记，后续普通推进／领取清回中性。没有改故事正文、随机权重、效果或支付数值。旧档缺失的标记保持中性，不反推过去输赢；查看完整提示应新进入／重开事件。

验证：`tools/check.ps1 -Suite events,content,persistence -UI -UISuite events`，2186项关联规则与72项事件窗口断言通过，无引擎错误。记录`build/checks/20260907T165413027-46232/`。覆盖提交前不泄露、冻结和已提交结果读档、损坏标记拒绝并保留原状态、成功／失败／中性、进入下一页后横条隐藏。该次运行遵循当前共享截图开关，默认没有写图；为核对新增横条，仅定向运行`-UIOnly -UISuite events -Screenshots ui-event-result-page.png`，73项通过（含1项图片保存），记录`build/checks/20260907T165556612-30100/`，只更新并查看1张结果页截图。本次关联规则门禁全绿；前批记录的链接测试失败在当前共享树已不再出现，本任务未修改链接模块。

## 2026-09-08：结果先读、再显示下一阶段

事件结果页只显示本次report和一个“继续”，阅读后替换为阶段intro及正式选项。继续只更新本地已读page_id；不派发命令、不改资源、版本、随机或存档。后续提交替换当前report，之前已提交的日志保留。奖励页不重播开场，最终页直接显示结果与离开入口。事件移除独立HeroSpeech气泡，正文自带对白不改。

- `tools/check.ps1 -UIOnly -UISuite events,action_copy,persistence`通过128项窗口断言，记录`build/checks/20260907T164521658-41764/`。覆盖结果／正文互斥、唯一继续、真实点击无状态改变、重绘保持已读、后续结果不累计、选卡／装备与取消、旧版本拒绝及读档续选。
- 事件截图由原来的多分支截图缩减为两张：`build/ui-event-result-page.png`和`build/ui-event-next-page.png`，已查看。删除事件对白接口对应的重复截图，行为断言保留。
- 关联规则门禁`-Suite events`本次851/854通过；event_flow的54项和events的220项全部通过。三项失败位于未修改的`tests/installation_priority_cases.gd`第27／74／76行，分别为链接安装优先级、失效端点重选与正式回合提交；不属于本次分页改动，未擅自修复。记录`build/checks/20260907T164446738-11636/check-rules.log`，因此不宣称关联门禁全绿。

## 2026-09-08：通用事件布局与二级选择

全部事件与事件练习共用`ui/event_screen.gd`：左上300×360插画预留区，右上独立滚动正文，右下少量主选项；未提供插画时不借用角色素材。永久卡牌与拘束具选择由只读事件投影按作者的选择来源分组，不解析中文或拆解ID，不暴露冻结结果。选卡与卡牌奖励复用六列CardFace；拘束具窗口显示真实部位、耐久、紧度与锁。统一抽屉负责遮罩、关闭与Esc，最终选定才提交原候选和打开时版本。文案正文、费用、效果、随机、存档格式与阶段顺序未改。

- 关联规则：`tools/check.ps1 -Suite events -UI -UISuite events`，853项规则、首轮63项窗口检查通过，记录`build/checks/20260907T163414421-15484/`。
- 最终窗口与事件关联交互：`tools/check.ps1 -UIOnly -UISuite events,action_copy,persistence`，131项窗口检查通过，无引擎错误，记录`build/checks/20260907T163628275-26848/`。
- 覆盖普通／多阶段／练习、奖励二级窗口、十张实体卡不合并、原生鼠标选卡与选装备、翻面、Esc／关闭／遮罩取消、旧版本拒绝、结果日志及存档续选。规则断言还验证投影不改变随机或状态、不包含隐藏效果。
- 已查看`build/ui-46-tailor-choices.png`、`ui-53-succubus-three-games-practice.png`、`ui-54-event-card-selection.png`与`ui-55-event-equipment-selection.png`；主框未越出视口，正文与选项分区，长卡组在弹窗内滚动。未来事件界面约定写入模板H5与AGENTS。仅验证相关分类，不宣称全项目回归。

## 2026-09-07：内容生成规则与 AI 编写模板

新增 `docs/content-generation.md` 与 `docs/content-templates.md`，覆盖普通／复合拘束具、链接、特殊部位装备、道具、遗物、敌人／遭遇、事件及房间来源。核对当前注册表、生成器、安装工厂、事件效果、随机域、目标复核与快照字段；明确仅练习／正式池、设计字段／真实配置之间的边界。

特殊装备按最新七子槽与容量【1】【2、2、2、1】【1、1】、固定品质与耐久、混合类型到期保留能量被动整理。躯干固定绳／带继续保留，仅身后。事件文档明确选牌在支付后生成，以及引用目标、组合预告、退出模式等现有扩展限制。

同步修订 `content-extension.md` 的贴墙、身体入口、反馈、事件冻结与旧递归测试说明；README 和项目 AGENTS 增加统一入口。十个 JSON 数据／参数例子均只在文档，不添加游戏定义或生成池。

文档静态核对通过：110项检查，包含10个 JSON 例子解析与关键形状／引用核对、本地链接及代码路径存在性、Markdown 围栏配对、样例未进入运行时。记录位于 `build/doc-checks/content-generation-20260907.json`。本批仅修改文档，没有运行玩法或窗口回归，也不据此宣称这些未注册样例已经可玩。

## 2026-09-07：五项优化修正

1. 施法倍率计算后统一量化为10000个抽签结果，显示精度0.01%；候选可用性和正式施法使用同一成功结果数。新增99—100过载附近的边界案例，0%拒绝且不扣卡、能量、魔力或随机次数；保留免费准备、单次多目标判定与存档重放。
2. core/contact.gd统一精准接触位置、躯干范围、链接端接触、同手限制与外层检查；手部辅助、徒手和手持工具复用。手工精细操作范围、工具材质与头颈禁切、安装工具的身体接触继续分开检查；同一只手须同时满足操作能力与目标触及。
3. 右键翻牌只刷新该牌文本、亮度、拖放数据与目标详情；选敌只刷新标记和攻击框，日志固定原位更新。其他纯UI重排复用现有只读快照。窗口测试实际点击／拖放，并断言场景、其他卡牌和日志控件未被重建、规则投影次数未增加。
4. 套件按初始修改范围补齐直接交叉案例，不再递归加载无关依赖；没有删除原套件或断言。规则与窗口共享引擎错误收集器，外层继续复核退出码、日志及完成标记。每次检查使用独立日志目录，避免并行任务覆盖。故意缺失字典键的规则／窗口反例均退出1、输出FAIL、不输出PASS。
5. 辅助预览记录逐手原因：手腕受限、不能握持、同手无法自助、够不到或被外层遮挡。目标详情直接解释，拖放目标框悬停可查看，日志保存正式执行时的辅助事实。

最终相关检查：`tools/check.ps1 -Suite contact,casting,persistence,runner -UI -UISuite casting,targeting,interface,rewards,enemy_feedback,special_equipment -VerifyRunner`。

- 2006项规则断言通过，29.39秒；包含当前并行任务的新特殊装备接口与存档交叉案例。
- 400项窗口断言通过，16.35秒；覆盖施法、特殊装备、敌人反馈、选敌、菜单导航与奖励。
- 两个故意报错的反例均被正确拒绝；错误输出为预期的测试输入，不计为正常检查通过。
- 本批最终日志：`build/checks/20260907T044234049-7704/`。早期执行碰到另一任务尚未接完的特殊装备接口，以及新增直接存档覆盖后的旧范围断言；已保留新接口并更新范围断言，最终检查通过。

此次为相关分类回归，不是全项目完整回归或平衡测试；不同批次检查范围不同，不将断言数减少当作等量测试加速。

## 2026-09-07：特殊装备容量、耐久与正式解除

按用户最新修正，七个子位置容量为【1】【2、2、2、1】【1、1】，可同时保存10个独立装备根。DESIGNS冻结每种样例的品质、耐久、部位、方法和环境／工具白名单；TYPES保留原三类触发与到期行为。旧无耐久样例被本节取代，不将下文历史记录当作当前规则。

普通挣扎／滑脱复用完整伤害预览与事务，双手不能抓住目标且无可借用环境时拒绝并保持费用、卡牌、随机与状态不变。魔法滑脱按真实施法门槛、工具按原固定切割、挂钩按降档分别结算；特殊装备不参与普通敌人施加池或身体活动等级。已验证同槽最高紧度／堆叠除数、逐件损伤与移除、手部辅助、无手环境门槛、工具安装与接触、真实魔法支付、三档普通滑脱免疫、满槽回滚、固定品质拒绝伪造、独立编号与存档恢复。旧无耐久练习档明确拒绝恢复，重新开练习即可。

最终受影响规则 special_equipment/hand_assist/casting/equipment/persistence 及入口合并的交叉范围共2021项通过，25.92秒；窗口special_equipment/status共59项通过，6.05秒。随后仅调整部位选择窗以容纳新增入口，targeting/special_equipment窗口66项通过，5.96秒；套件选择runner4项通过。没有运行全项目回归。检查日志分别位于build/checks/20260907T044047891-39412及20260907T044142107-2860。

ui-108-special-equipment-drag.png记录实际拖牌：同子位置两件分别编号，选择第二件后只有该件耐久下降，第一件与原普通部位无变化。ui-104-special-slots-and-meters.png覆盖第四子位置、容量、耐久／紧度及真实手部范围。装备详情、拖放摘要、状态／压力来源、教程及设计文档已同步，投影不再假定每槽只有一件。

## 2026-09-07：手部辅助与占位部位触及

挣扎／普通滑脱／魔法滑脱沿escape_preview共用手部辅助：单手基础＋1、双手＋2。按真实左右握持、手腕、姿态、精准子位置、身前身后躯干固定和原外层资格计算；双臂自由所有姿态全触及。手腕自由且小臂无躯干固定时，全姿态额外触及手肘上方与六个占位子槽；原大腿范围包含位置3。特殊装备无耐久与普通施加禁令不变。卡牌每批候选共享临时范围，后续动作／连段重新获取，避免持久缓存过期。

规则hand_assist/casting/wall/status/persistence/special_equipment及去重依赖4744项通过，34.68秒。随后补齐精细操作与普通握持区别、链接接触计数，hand_assist126项、action_copy19项、normal_play713项，连同入口校验861项通过（10.77秒）。三条正常开局用正式投影和命令完成：seed42谨慎路线251步逃狱；seed20260906精英路线243步通关；seed7交易路线213步通关，未注入角色或装备状态。

窗口special_equipment30项、targeting27项、status21项通过；rewards旧手势原因措辞断言同步后27项通过（4.79秒）。已查看ui-104-special-slots-and-meters.png，六个特殊位置沿原面板显示实际可触及手，空位和装备信息清晰。真实卡牌提交、一次能量支付、日志辅助侧别、无手部辅助、内层遮挡、三档免疫、锁倍率与刷新后候选均已覆盖。

遗物降档案例从6耐久调整到7，以保持其“二档降一档而非直接解除”的测试前提；断言仍检查真实降档和抽牌，未削弱规则。第一轮检查虽末尾打印PASS，但因脚本错误被共享入口正确判失败，修正后重跑通过。非全项目回归。

## 2026-09-07：施法概率、口部倍率与卡牌可用性

当前魔法牌及火球术全部在card_rules显式声明嘴部施法与默认额外倍率1；概率只对嘴部配置乘口部等级、紧度，非嘴部配置不受影响。过载曲线、实际施放、牢门开锁、逐牌悬停和资源区显示共用正式概率计算。原手势资格保留；自由面准备不判失败。失败照常花费但不触发法术效果与连段；0%拒绝且不支付。手牌可用原因来自已有候选，不可用低亮但可正常悬停／翻面。

规则casting/status/persistence/special_equipment与自动去重依赖4543项通过，24.97秒。随后追加失败魔法滑脱、牢门零概率拒绝和失败支付检查，casting最终193项通过，1.74秒。覆盖9种口部等级×紧度组合、曲线边界与单调性、非嘴部隔离、逐牌额外倍率、成功/失败、随机重放、不变预览、支付、自由面与诅咒例外。旧必成功检查改用明确的成功随机夹具，仍执行正式施放门槛；不删除规则来迎合旧断言。

窗口casting 9项、special_equipment 29项、interface 257项通过；enemies修正夹具注入装备后须右键翻至拘束面的操作后36项通过（6.49秒）。casting最终另跑9项通过（3.26秒）。已查看ui-107-card-casting-tooltip.png：牌面原因与低亮、完整倍率浮窗、魔力下方及人物脚下成功率均在视口内。非全项目回归，未新增独立测试流程。

## 2026-09-07：合并部位、特殊占位装备与资源条

手部/足部仅合并入口，保留真实掌/指槽、能力和候选。新增按1/3/2子槽配置的特殊区域与三类无耐久装备；能量支付只触发一次，回合开始准确递减次数，3号到期保留能量被动。旧鸣响束带及生成、来源、练习已移除；新装备暂仅进入独立练习。

规则special_equipment、pressure、status、persistence及去重依赖4355项通过（46.26秒）。覆盖零费/多点能量、贴墙跨回合、立即过载取消待选连牌但保留首段、到期、存档后继续、独立槽容量与非法状态拒绝。相关窗口首次393项通过；最终文字/显示调整后special_equipment 29项、interface 253项再次通过（9.62秒），body_layout 29项、pressure 43项、persistence 44项沿用本批已通过结果。非全项目回归。

实际拖牌从合并手部选择手指装备只改变该件；查看子槽不消耗资源；三号到期说明和全尺寸/紧凑两套资源条已核对。截图ui-104-special-slots-and-meters.png与ui-105-compact-resource-meters.png记录当前布局，窗口缩放至1280×720后仍在视口内。所有检查继续使用既有入口，无独立测试脚手架。

## 2026-09-07：游戏主页

主页接入新局、继续、教程、练习、设置及退出，菜单支持返回主页。启动不自动恢复或创建存档，明确继续才恢复；内存继续保留当前局。设置提供全屏和行动展示速度，不改变游戏规则。

沿原窗口检查入口验证：home最终28项通过，5.92秒；本批interface 251项、persistence 44项通过。覆盖实际点击、无存档启动、开始后保存、返回与继续、损坏存档保护、隐藏行动拒绝及1280×720缩放。未运行无关规则全量。截图为`build/ui-102-home.png`与`build/ui-103-home-continue.png`。

## 2026-09-07：敌人动作衔接与结果反馈

新增敌方已提交结果队列：每次操作按真实enemy_id/sequence/kind/slots标记，普通多敌和警卫附加行动顺序展示；敌人轻微前移、高亮，结果短框与身体部位闪烁，结尾显示玩家行动/奖励/监狱等实际阶段。跳过展示和自然结束均不再结算，重开清队列，重绘/恢复不重复历史。蒙眼下准备动作保留unseen，不揭示蓄力或收押准备。玩家原有HP飘字保留。

规则第一次enemies/intent/action_copy与依赖818项通过；补充警卫与不可观察准备后guard/intent/action_copy及依赖1451项通过（9.11秒）。窗口第一次enemy_feedback/intent/action_copy 40项通过；修正提示序号换行、缩小短框并补双操作目标测试后，baseline/enemy_feedback/guard共308项通过（33.86秒）。覆盖不同实例顺序、实际结果与目标锚点、播放时阻止重复提交、自然结束/跳过不改状态、不重放旧日志、蒙眼不泄露、新局清理及同一警卫两次操作独立分组。

窗口检查仍执行真实队列与输入，普通模块把单步展示时长设为0.04秒，等待实际结束；专项用0.2秒验证中间态。并未禁用动画或略过正式敌方结算。已查看ui-100-enemy-action.png，发现序号被挤成三行，随后固定序号宽度并禁止换行，最终相关检查通过。未新增游戏规则、成人文本或图片资源。

## 2026-09-07：地图直接进入、左键拖动与移动消息

用户最新确认：Demo阶段不修旧地图，也不维护旧版地图兼容。移除本批及此前的Tower.migrate、legacy_direct旧路程豁免与对应迁移用例；没有修改玩家存档文件。新图继续保证只走相邻层、无连续同类休息/商店/精英、第14层无休息，并补上首层汇合边裁剪、最后统一填普通战斗的原版分配顺序。依据地图算法逆向作者的第一手说明（设计文档已有链接），不宣称逐种子复制原版。

点击可前往节点直接提交原depart，450毫秒间隔逐次提交travel_step，可暂停或单步。按住左键移动超过8像素仅拖图，不触发节点；滚轮与悬停说明保留。右侧删除重复目标选择按钮，改为滚动移动消息与紧凑进度控制。data.travel标记一次正式移动批次的所有结果，投影按真实顺序显示，不解析文字、不新建第二套日志；后续途中事件沿同一批次进入。信息菜单暂停自动移动，旧定时回调复核本局对象与版本，不能误推进新开局。

新图规则与服务首次2239项通过；扩展到201个种子并合并压力及依赖后3126项通过（11.44秒）。首次拖图检查发现使用系统鼠标坐标无法可靠处理注入事件，改为事件自身坐标；随后baseline/route/services/interface共533项窗口检查通过（36.29秒）。后续菜单暂停/定时回调修正后route再次12项通过。包括从可用图标开始拖动不出发、非法节点不移动、实际五回合自动抵达、暂停与新局隔离、消息条目及原有操作。

正常数值窗口最终通过639项（26.66秒）：seed7实际通关，安全等级0，移动17回合，未触发收押。此前预期必须收押的旧断言已替换为严格的真实终点与状态校验。

已查看ui-98-map-messages.png确认右侧消息布局与地图短标签；ui-99-map-arrival.png记录抵达后的消息。普通战斗节点统一使用“战斗”短标题，修正旧weak/strong图标回退完整房间名导致的重叠。正常数值长路线测试不再强制seed7必须得到旧版同一结局，仍要求在步数上限内达到真实通关/终局/收押后逃离，并验证最终状态，未放宽无候选或循环判定。

## 2026-09-07：随机一幕、魔力商店、宝箱与目标复核

本批完成：相邻层随机塔路（7列、15层、6条路径，固定首层战斗/第9层宝箱/第15层休息，接双警卫与出口）、按实际普通战斗次数选择前三场弱怪、随机精英/事件/商店、基础魔力交易与一次删牌、宝箱领取、旧图跳层修复及旧在途兼容。装备耐久/紧度带标签，手动松解仅在可使用时出现。敌人逐项复核失效目标，不增加行动次数/改变时机；头部专项附着保留指定部位。

规则完整检查通过3625项（20.23秒）。最后稳定场景调整后，core/enemies/events/services及自动合并依赖再次通过2302项（11.72秒）。services中77项覆盖支付、余额不足、容量、重复领取、全部牌堆删牌、查看/读档不重抽、法术资源不影响购物、非法存档回滚、初始入口、前三场弱池及旧在途恢复。地图生成跨30个种子检查楼层、合法连接、交叉、特殊层和房型限制。

完整窗口运行覆盖全部模块；中途发现旧测试仍假定早期休息固定位置、显示不可用徒手原因和恰好两个事件房，以及第二次拖牌没有显式备好该牌。这些夹具/断言已按新规则修正，未删除正式动作或绕过资格。修正后baseline/events/services重跑288项全部通过（24.95秒）；其余窗口模块在完整运行中通过。此前塔路图例断言已改为检查实际首领图标。未把中途失败的全窗口命令标记为通过。

检查入口整合：UI_MODULES是窗口套件唯一注册表，baseline可以单独选或与相关模块合并；保留原退出码、错误日志和完成标记检查。稳定机制场景集中于tests/game_fixture.gd，仅声明场景数据，不覆盖规则或提交；地图生成、services与normal_play使用真实Game开局。后续无需每个小改动重复全部基础流程。

正常数值规则试玩：seed42通关（252步、8场、魔力17.5），seed20260906通关（313步、10场、魔力16.71875）；seed7经历收押后成功逃回新塔底（195步、安全等级1）。窗口normal_play的610项断言通过。记录仅说明这些种子流程可推进，不能证明最终难度、胜率或商店价格平衡。

已查看随机地图ui-96与商店/宝箱ui-97截图，并通过原生按钮执行购买、领取和离开。新布局缩小7列节点的实际点击区域，避免同行重叠；地图概览用短房型名，详情保留楼层和完整房间名。新地图分布只用于新开局/逃狱重建，旧档不重抽内容。

## 2026-09-07：教程、日志与腿部分段差分

本批完成：菜单教程书（11类、正文搜索）、卡牌/装备/房间重复说明迁入教程、51条通用解释与共享敌人术语改为短句/例子；人物实际操作和结果加入同一行动日志，费用只记录一次。随后按用户补充，将腿部从等级整图切换改为实际覆盖的七组差分，最终方案为包含皮肤、袜子和绳子的整段替换；有/无拘束每段各一张，脚趾暂无差分。分段底图留切边保护并作上下过渡，避免旧轮廓重影和缩放黑线。生成脚本逐像素验证无拘束七段可还原原底图。

检查分批按影响范围执行：教程/日志的core、equipment_complete及依赖、intent、status、action_copy规则874项通过；更新共享术语后intent/action_copy 31项通过。教程原生搜索、分类、空结果、Esc与查看不改状态并入interface247项；action_copy窗口15项通过。整段差分与body_layout窗口200项通过；最后修正缩放接缝后的equipment_art专项172项通过，窗口4.747秒，含启动6.95秒。覆盖16种普通部位组合、单独脚趾、眼嘴独立层、真实切割套体/保留外带/解除固定点、查看不改状态。所有末次检查退出码0，无错误日志；未将专项称为全量回归。

已查看教程分类与搜索截图ui-92/ui-93、最新腿段ui-94各位置与ui-95独立膝上外带；最后的全腿截图确认缩小后的切边无黑色接缝。中途发现搜索框吞Esc及切片透出旧轮廓/接缝，均已修正后运行相关检查。临时纯绳v2贴片已清理，运行时仅引用最终v3整段资源。

# 原型检查记录

最新批次（2026-09-07，装备栏等级差分与口/眼独立覆盖）：五张用户原图使用共享裁剪和本地白底抠图，图6/7只提取对应口/眼变化贴片；原文件不修改，未使用生成工具。equipment_portrait统一读取既有等级/占位投影，双臂0且双腿受限按要求使用图1，全部自由恢复原自由图；脸部两层独立，不改变战场立绘或游戏规则。

首次关联`equipment_art,body_layout,equipment_complete`通过160项窗口断言（窗口8.893秒、含启动11.02秒）；之后补充真实腿部4→3解除切图和仅眼部佩戴不引入图7中的口部装备，末次equipment_art通过95项（窗口3.907秒、含启动6.43秒）。退出码0、无错误日志、完成标记齐全。检查覆盖25种正式等级组合、查看不改变状态/随机、自由图与差分图双层合成、真实徒手解除后分别恢复、低档切图保留脸部层，以及原有部位点击、拖牌、复合装备窗口流程。只变更显示与素材，未重复无关规则/完整长路线。

已查看深色素材合成预览及ui-88-equipment-legs0.png、ui-89-equipment-free-face.png、ui-90-equipment-bound-face.png、ui-91-equipment-eyes-only.png；同组共享原始裁剪坐标，嘴/眼层随基图同一缩放对齐。装备栏属于用户指定的区域等级简化图，图片中的具体绳索样式不充当真实装备清单；战场三姿态仍独立。

以下为此前批次记录。

最新批次（2026-09-07，换姿与贴墙动态框组）：移除左侧固定三姿态和独立贴墙栏，合并到结束回合上方。候选新增来自原顺序检查的adjacent元数据，费用、合法性、状态提交不变。相邻但能量不足的选项保持可见，贴墙直接注明结束当前行动。最后微调双行按钮内边距，避免最小尺寸撑大导致相邻框重叠。

core规则320项通过（4.03秒）；初次hero_art/interface窗口67项通过；新增动态框与实际换姿案例后末次interface70项通过（窗口5.333秒，含启动7.58秒）。覆盖站/坐/躺1/3/2框、有墙/非战斗、零能量普通起身不可用但贴墙可用、正式贴墙推进回合、原生拖放与面板操作；新增实际按钮边界断言防止双行内容重叠。退出码0，无错误日志。已查看ui-86-posture-choices-seated.png与ui-87-posture-choices-lying.png；未重跑无关长路线或全量规则。

以下为此前批次记录。

最新批次（2026-09-06，三张用户原图替换战场像素立绘）：站/坐通过边缘白底与人工确认封闭空隙抠图，躺姿通过本地GrabCut及明确床单空隙细修得到真实透明PNG。未使用生成工具、未改原图。资源统一登记在HERO_POSES，按正式姿态切换、各图等比缩放、共用底边；对话头像同步更换。装备栏独立图、敌人画材、拖放区域、规则与存档结构不变。

`-UIOnly -UISuite hero_art,interface,action_copy,body_layout`通过108项窗口断言，窗口7.623秒、含启动9.66秒。随后只清理躺姿残留床单，末次导入后`-UIOnly -UISuite hero_art`通过21项（含启动3.71秒）。退出码0、无错误日志、完成标记齐全；未为美术更换重复完整规则/长路线测试。原公共美术检查迁入可单选hero_art模块，默认all不会重复执行。首次检查发现基线仍引用旧HERO常量，已同步修正，失败轮不计通过。

已查看三张深色背景抠图以及正式`ui-21-hero-stand/sit/lie.png`截图，检查原比例、完整显示、共同落地线、头像、真实姿态切换及原生攻击/姿态/手牌拖放。躺姿保留用户原图构图，不据画面姿势修改正式坐/躺能力或制作装备差分。

以下为此前批次记录。

最新批次（2026-09-06，装备区立绘与纵向部位列表）：用户原图经本地确定性抠图得到621×2098真实透明PNG，已检查深色背景下的发丝、手臂间隙与白色衣料。左侧人物等比完整显示，全部12个部位从头到脚排列，装备详情移至侧旁独立滚动窗；正式规则与存档格式未修改。

新增`body_layout`28项窗口断言，覆盖透明资源、等比显示、部位顺序及边界、最低部位真实点击、零回合查看、关闭后目标保留、头部真实装备、原生拖牌和取消不消耗。现有装备/链接/整备检查统一通过`inspect_body`实际打开详情，未删除原断言或绕过行动。相关窗口70项通过（含启动6.94秒），随后一次完整窗口通过1539项（窗口72.161秒，含启动73.81秒），退出码0且无错误日志。完整检查含756项正常数值试玩和敌人、装备、警卫、监狱、事件、奖励、存档流程；未重复无关规则检查。

已查看`ui-81-pinned-log-selected-target.png`、`ui-84-body-equipment-details.png`、`ui-85-body-card-drop.png`及`cutout-dark-preview.png`。正式默认布局、详情滚动和逐装备拖放均保持可用；该立绘只是装备栏人物展示，不代表已增加装备外观差分。

以下为此前批次记录。

最新批次（2026-09-06，日志收起/固定与点击选敌）：`-UIOnly -UISuite targeting,interface,action_copy,intent,guard`通过140项窗口断言，窗口9.673秒、含启动11.43秒，退出码0且无错误日志。只修改界面和交互，未重跑无关规则。新增targeting27项验证未固定栏外点击自动关闭且同一次选择/攻击有效、栏内阅读不关闭、重新打开、固定保持、固定时手动关闭、取消固定，以及四种攻击逐一只伤害所选敌人。

问题根因为名称按钮已接选择，而敌人立绘区域原先只接拖放；现两处复用_select_enemy。选择不写游戏状态，四个按钮的候选统一按实例切换，攻击拖到另一目标仍按实际落点执行。侧栏通过可见性切换收起，鼠标按下时不重建控件，不吞点击或拖放。已查看ui-81-pinned-log-selected-target.png与ui-82-collapsed-action-log.png；固定按钮、右上折叠入口及指向悬浮锁的攻击说明完整可见。

以下为此前批次记录。

最新批次（2026-09-06，警卫精简意图与术语悬停）：`-Suite intent`通过11项（10项行为＋1项套件校验），`-Suite status`53项通过；最终`-UIOnly -UISuite intent,guard,interface`通过100项，窗口7.306秒、含启动9.53秒。未修改游戏行动规则或存档格式，未重复无关全量。原意图和状态字段保留，警卫面板消费新的只读精简行。

测试覆盖真实冻结计划、威压＋15和余波＋10×2、各警卫独立目标、被移除目标、只读/RNG不变，以及眼部受限时短文本和悬停说明不泄露隐藏计划。窗口以真实鼠标移入/移出打开关闭解释，检查左右侧避让与视口内边界、刷新关闭旧浮窗；并复核菜单/拖放和完整警卫收押流程。已查看ui-79-guard-term-hover.png、ui-80-hidden-intent-hover.png。早期检查发现并修复浮窗初始高度、树变更期间清理和void回调问题；报错轮即使打印PASS仍由统一日志门禁拒绝，不计成功。

以下为此前批次记录。

最新批次（2026-09-06，人物台词与右上行动日志）：`-Suite persistence,action_copy -UI`通过2650项关联规则和1463项完整窗口断言，检查分别11.93秒与69.53秒（含引擎启动）；退出码、错误日志与完成标记均通过。规则覆盖现有存档/事件/警卫/装备等传递依赖及新文案接口，完整窗口包含756项正常数值试玩。随后让事件选择也显示头像台词并为对话框留出空间，末次`-UIOnly -UISuite action_copy,events`35项通过，5.90秒；未为这项显示修改重复无关全量规则。

人物与玩家拖放目标同步下移100设计像素；敌人横向收拢，为右上252宽的日志侧栏留出空间。人物头像沿既有源图区域显示；最新台词持续到下一成功动作，长文本可滚动，卡牌拖放和敌人目标仍走原生入口。日志只投影实际敌人执行和事件结果，默认测试文案从JSON读取，不改旧机械正文。事件内部施加与结果摘要去重，最新40条按发生顺序反向显示。

新案例覆盖实际攻击/结束回合/事件、失败提交回滚、查看不重放/RNG不变、嘴部受限、看不清的准备动作、真实存档恢复和修改文案不改变状态；窗口覆盖下移后攻击与姿态拖放、头像对话框、侧栏与事件选择。第一次窗口检查发现测试姿态按钮参数错误，随后又发现正式posture动作未映射到专用台词cue，两项均修正后取得上述通过结果；失败轮不计通过。已查看ui-77-dialogue-action-log.png与ui-78-event-action-log.png，规则仍为暂定数值，未增加配音/逐字动画或成品叙事。

以下为此前批次记录。

最新批次（2026-09-06，统一状态栏与检查提速）：状态、环境与持续效果收进顶部“状态”，复用原面板互斥与正式稳定心神候选。只读状态目录集中身体能力、属性、装备限制、跨回合收益、压力来源/过载、动作使用记录、卡牌保留/连续操作、房间进度与遗物触发机会。双臂/双腿零级常驻，独立手部包裹来源按侧区分，不计为共同固定；终局不显示巡视倒计时。

本批规则核心检查320项通过；新增状态专项最终53项通过（52项行为断言＋1项套件名称校验），覆盖全部练习投影、真实解除与增益消耗、只读/RNG不变、隐藏意图不泄露、左右手来源和实际五级终局。减少等待后完整窗口通过1450项，窗口总计60.184秒、含引擎启动的检查62.29秒，无错误日志。随后补充脚趾状态、侧别来源和可见稳定心神禁用原因，末次状态/压力窗口专项64项通过；未将专项复核计作再次完整回归。

相同109项状态/interface/压力窗口断言的对照：优化前模块总计12.046秒（2.683/4.921/4.442秒），优化后6.763秒（1.636/2.441/2.686秒），本机样本耗时减少43.9%。这是相同检查的实测，不承诺所有机器相同比例。没有删除断言；共享布局等待由8帧减至2帧，仍等待绘制完成，移除输入助手之后的重复等待。完整窗口继续包含756项正常数值试玩以及装备、敌人、压力、警卫、监狱、塔路、事件、奖励和存档流程。

日常通过既有-Suite/-UISuite选择完整关联模块，依赖去重、未知名称拒绝、零退出码/错误日志/完成标记三项门禁全部保留。状态投影不自动拉入无关长路线，所有模块与整个检查报告耗时。已查看最终ui-74-status-overview.png、ui-75-status-buffs.png、ui-76-status-pressure.png，身体零级、增益层数、分类切换、来源和持续条件清晰；稳定心神的真实费用/效果或禁用原因直接可见。

以下为此前批次记录。

最新批次（2026-09-06，第二轮UI简化整合）：最终 `-UIOnly` 完整窗口检查通过 **1430项**，包括interface46、正常试玩756、敌人36、装备39、压力43、警卫40、监狱60、塔路49、事件22、奖励27、存档36以及公共基线。退出码0，无错误日志，完成标记齐全。规则、资源数值、敌人行为和存档格式未修改，因此未重复运行无关规则检查。

顶栏由八个按钮收为五个，菜单收纳存档、记录、玩法和重开；六类信息面板共用打开、互斥、标题、关闭及外侧遮罩。检查覆盖菜单切换、同入口收起、点击内部保留、外侧仅关闭而不穿透攻击、Esc、关闭后的攻击/姿态/出牌，以及真实练习菜单和存档恢复。身体自由提示与卡牌翻面提示去重，姿态费用明确单位并对齐左栏，固定行动归入同一条操作区。已查看1440×810默认窗口及新截图 `build/ui-71-game-menu.png`、`ui-72-unified-drawer.png`、`ui-73-simplified-battle.png`。

测试侧同时适配新交互：打开练习先经真实菜单，拖牌前如有信息面板，先真实点击关闭；原演员拖放案例移入interface，只执行一次。早期失败没有计作通过；原自动策略穿过信息面板出牌已修正，未让游戏遮罩透传输入。共享frames增加已绘制帧等待；最终测试独占脚本指针输入，隔离29次外部系统鼠标事件。所有合成鼠标/键盘事件继续走真实Viewport/Control命中、拖放及正式候选提交；这不是系统级物理鼠标驱动验收。输入隔离只在ui_smoke进程启用，正式游戏不变。

以下为之前批次记录。

本批最新（2026-09-06，UI与美术升级）：`-UIOnly`完整窗口检查通过1372项，包含正常开局到入狱再逃离的754项操作；随后补充卡牌插图尺寸与实际伤害数字回归，`-UIOnly -UISuite enemies`通过34项。未修改规则、数值或存档结构，没有重跑无关规则套件。此前两次检查长时间未完成而人工终止，不计通过；补充分段进度后的一次完整运行取得正式成功标记及零退出码。

已检查新版默认1440×810窗口、双警卫、奖励和塔路截图：`build/ui-08-default-window.png`、`ui-36-double-guard.png`、`ui-04-reward.png`、`ui-05-map.png`。身体三列、装备卡、双面插图卡牌、敌人立绘和地图文字完整可见；原生拖放、右键翻面、眼部隐藏意图、姿态图集与绿底去除仍通过完整窗口流程。

本批修正了卡牌插图在布局前读取零宽度的问题，并让绿底画材保留节点颜色/透明度，使离场敌人的淡出真实生效。新增检查验证插图在卡框内拥有正尺寸，正式攻击后伤害数字等于实际生命差，数字消失不改变游戏状态。颜色/面板/画材归入visual_theme，六种敌人合并为图集与共享显示；源码内几何占位敌人已移除。没有制作穿戴差分、攻击帧动画或额外新敌人。

以下为此前批次记录。

本批最新（2026-09-06，正常开局试玩与眼部意图）：眼部改动关联规则`-Suite guard`通过1392项，敌人26＋警卫38共64项窗口专项通过；正常试玩`-Suite normal_play`通过807项，实际窗口`-UIOnly -UISuite normal_play`通过754项。均沿原检查入口，错误日志与完成标记一并复核；不是全项目回归计数。末次运行时改动仅修正回合开始可见性文案，随后再次检查眼部/警卫关联范围。

正常数值自动试玩使用100魔力、初始10牌、正式敌人生命，不注入装备或资源、不删装备、不读隐藏计划/钥匙/未来牌序。只读取玩家快照选候选并正式提交。完成两轮共6次；第一次有不必要的牢房反复起坐及休息时超过策略目标继续取牌，随后修正试玩策略、保留游戏数值，再复跑三局。结果随选牌/牌序变化，不能估计胜率或把全部失败归因于数值。

最后一轮：

| 种子 | 路线偏好 | 结果 | 逃离方法 | 剩余魔力 | 压力 | 正式操作数 |
|---|---|---|---|---:|---:|---:|
| 42 | 保守选路 | 到达第17层出口 | — | 40.00 | 35 | 230 |
| 20260906 | 优先精英 | 被收押后逃回塔底 | 踢开通风口 | 20.94 | 55 | 321 |
| 7 | 优先事件 | 被收押后逃回塔底 | 术式开门 | 17.04 | 60 | 249 |

策略在卡组达到18张后跳过可选取牌，这只是试玩策略，不是新增卡组容量上限。精英路线牢房结束3回合后从通风口离开；事件路线结束5回合后用术式开门离开，两者此轮均在首次巡视前逃离。保守路线通关时保留10层蓄力，表明跨战积累值得在数值阶段评估；另外两路仍有合法逃离路径，未遇到无候选或步数上限。所有数字是样本结果，不是难度结论。

实际窗口完整复核种子7，从普通入口到塔顶失败、入狱、出牌解除装备、术式开门、站起并离开，最终魔力17.04、压力60、安全等级1、保留一件装备。没有读取或覆盖玩家存档。已查看ui-66-hidden-intents.png、ui-70-normal-escape.png；正常开始与收押画面另存ui-68/69，恢复意图为ui-67。

眼部案例验证任意紧度、多件堆叠、部分损伤不恢复、最后一件真实解除立即恢复原计划；后手眼罩施加即生效，盲视打断仍延后，保存恢复不重抽。视图不输出真实意图阶段/收押状态；新蓄力和收押准备日志不泄露看不见的计划，已观察历史和实际结果不删除。没有额外关闭攻击、改变命中或抽牌。颈部单件和未定义额外加固结构仍只保留设计预留，不因本次说明开放生成。

历史批次（2026-09-06，高安全装备修正、延期生成与整局衔接）：`tools/check.ps1 -Suite persistence -UI`中全部14套规则通过2626项；完整窗口发现旧长路线直接跳过整备和休息测试混入施法条件的问题。修正窗口测试流程和帮助文案后，`tools/check.ps1 -UIOnly`完整通过611项，无引擎错误。未把此前失败窗口计为通过，末次仅测试/文案修订未重跑无关规则。

- 五级沿用现有高级三档满耐久装备，保留物理编号、封闭结构和有效链接，按合法容量补齐并锁住可锁处。验证已穿长套的边界、所有计数部位覆盖、普通容量/封闭资格、终局无行动/重复入狱、完整清单恢复与损坏原子拒绝；8种入狱种子配置均合法。旧固定架生成拒绝，历史已结束记录仍可恢复。
- 新探索池只有小石片、锈锯条、通风口；旧四项待发现记录中的折返符不进入候选计数或领取，其他三项顺序不重抽。保留已有库存的姿态/手指/容量/阶段资格、检查没收、一次性逃离与存档归属验证，明确使用库存夹具而非声称正式掉落。
- 窗口长路线和规则长路线共用整备动作选择；窗口实际拖牌到口部目标，普通手动解开沿实际按钮，消耗真实牌与费用。休息禁自由效果用基础非魔法牌独立检查，不由另一项咏唱限制掩盖目标规则。
- 完整窗口包含长塔路、拖放/姿态/休息及九个专项模块；终点实际抵达第17层，战斗奖励次数一致。警卫生命仍使用既有短战斗夹具，最终数值难度和全部策略组合尚未验证。
- 已查看`build/ui-07-cleared.png`及`build/ui-65-security-five.png`：终点与高安全监室说明、真实24/24耐久、装备列表可读。帮助、主规则、装备说明、内容接口和README同步更新。仅参考旧规则书高安全监室“满容量最高档”设定，没有读取旧Demo代码。

历史批次（2026-09-06，五级终局与折返符）：规则2619项通过；最后纯显示投影改为读取实际终局组件数值后，牢房55项/存档33项窗口专项共88项通过。已查看ui-64-return-seal.png与ui-65-security-five.png，道具条件和终局真实数值均完整可读。

验证五级工厂上下文与普通生成池隔离、关闭套体内层完整保留、三组件/1000耐久/极高损伤仍为0、真实身体4级与头部限制、拒绝残缺存档、旧終局原样恢复；折返符四项实际探索获得、三种姿态/一只手/双手禁用、消费后容量、过载/巡视/反抗阻断、正常检查保留/再收押没收、一次性原子逃离及资源与存档归属保持、保存恢复后正式逃离一致。新增发现使旧测试的道具数量增加，改用正式丢弃处理全部超载，而非削弱容量断言。检查仍共用既有prison/persistence模块，未新建启动器。


历史批次（2026-09-06，悬浮口部敌人与遭遇池）：2540项规则断言通过；窗口enemies19/persistence33，共52项专项通过。已查看ui-62-floating-silencer.png与ui-63-mouth-restriction.png，独立敌人轮廓、蓄力进度、施加后口部装备与具体咏唱禁用原因可见。

复用眼罩的两次蓄力/最终施加逻辑，覆盖16种种子、双模板、首次冻结/预览不变、三阶段打断与存档续局、提前击倒、满位/临时释放/再次占满、后手立即禁咏唱而保留手势魔法、多人离场奖励一次、正式塔路强弱池可达。原眼罩全套回归保留。修正测试随机断言只比较装备/敌人域，正常回合洗牌不应被误判为重抽装备；长路线测试通过正式整备解除口部，不改胜负或身体规则。新增两个真实练习，现有存档逐练习往返检查自动包含，测试入口没有复制。


历史批次（2026-09-06，正式压力来源）：规则2342项通过，窗口专项pressure38/events22/persistence33，共93项通过，未将专项冒称全窗口。已查看ui-60-formal-pressure.png与ui-61-timed-pressure.png，来源、次数、停止条件均可见。

覆盖正式装备工厂/合法警卫池、独立附着与真实解除、降档不停止、跨房保持、玩家回合末触发、警卫意图冻结/打断/持续到期/不同施加者、战斗胜利/收押清理、事件公开代价与一次性过载、保存恢复后下一正式动作一致、错误持续时间原子拒绝。已有十四套规则由persistence依赖合并去重。修复先手连动已完成时空意图存档误拒绝，保留当前回合行动记录与上次意图校验。修订等级检查以验证新模板的最低等级拒绝边界。新增来源未改变普通装备压力、魔法曲线或既有过载惩罚数值；本批新增来源数值为暂定。


本项目使用独立的轻量开发流程。规则改动检查相关行为，界面改动增加窗口操作验证；不继承其他项目的阶段门禁。

## 检查入口

- 规则：`Godot --headless --path . --script res://tests/test_game.gd`
- 界面与完整流程：`Godot --path . --script res://tests/ui_smoke.gd`
- Windows：`tools/check.ps1`，加 `-UI` 包含窗口内操作与截图。
- 窗口专项：`tools/check.ps1 -UIOnly -UISuite rewards`；可选equipment_complete、pressure、guard、prison、tower_progression、events、rewards，并可逗号组合。从同一窗口入口运行既有模块、每项先重置、按注册顺序去重；默认all保留原完整流程，未知套件拒绝。不复制测试，不把部分专项统计成完整窗口结果。
- 相关规则：`tools/check.ps1 -Suite equipment_complete`，按统一注册表补齐core/equipment/links/composites依赖、去重运行。可逗号指定多个套件，默认all；每套件记录耗时。规则通过后的纯显示修改用同一入口的`-UIOnly`，保持错误日志与完成标记检查。

## 覆盖范围

2026-09-06存档批次最终结果：`tools/check.ps1 -Suite persistence -UI -UISuite persistence`通过2285项规则断言、33项存档窗口专项，无引擎错误。14个规则套件按依赖去重运行，其中persistence293，其余继承rewards及传递依赖1991项，另有选择断言1项。此前本批完整窗口`-UIOnly`通过552项断言；最后补充运行期间不兼容文件保护后，重跑完整关联规则及存档窗口专项，不把专项计作新的完整窗口结果。

存档案例覆盖全部33项实际练习与64位大种子；保存→恢复→正式下一步和不中断运行逐项对照，资源、随机、牌堆与日志均不变化，只有操作版本刷新。覆盖战斗、奖励、整备、地图、行进、休息、整理道具、事件选择/钥匙/结果、多段挣扎与双重开锁中途、已保留一张牌、待发放遗物、过载、入狱结果、牢房、巡视到达/结果/完成、反抗战斗、五级结束与练习完成。练习实际开门逃回塔底后存档身份仍为practice，写入不覆盖tower。

失败案例检查缺字段、未知阶段/卡牌、牌堆不一致、损坏随机/意图/地图引用、重复编号风险、非有限数、错误格式、损坏JSON和校验和；失败恢复保留当前状态。真实文件案例检查首次保存、连续替换、上次备份、主文件损坏回退、后续修复、不同档位隔离、文件夹不可写时保留原文件；不兼容主文件不自动回退，也不能在游戏运行期间被普通自动保存覆盖，只有明确新局可以替换。

初次完整对照发现文本浮点往返与Godot StringName转普通字符串导致差异。当前整数使用十进制类型标记、浮点保存原始64位、StringName保留名称类型；全部真实装备/事件往返及后续动作对照已通过，没有用近似比较掩盖状态差异。恢复不运行状态清理、回合开始或随机生成，无法继续的损坏多段选择被拒绝。

窗口专项实际启动新场景读取自动保存，验证成功操作写入而翻面/查看/旧版本拒绝不写；塔路/练习按钮、缺档禁用原因、练习分档、多段拖牌恢复不重复扣费、事件隐藏结果保留与结算后不能重选、备份回退提示、未知版本暂停自动保存、明确重开后恢复写入。截图`ui-56-save-menu.png`、`ui-57-resumed-card.png`、`ui-58-save-recovery.png`、`ui-59-save-incompatible.png`已查看，界面内容在视口内。测试在独立build临时目录执行，基础窗口挂载前禁用文件保存，未访问玩家存档。

架构：Game继续持有唯一游戏状态，snapshot只作结构保护、复用现有注册表及规则校验；save_store统一无损编码、格式和文件替换。UI仅在已有成功提交入口调用保存，读档清理界面焦点并派发完整恢复。状态新增save_slot用于固定开局归属，不根据逃狱后的practice标志猜测档位。未来已有字段含义变化需显式迁移/版本升级；本批是首个格式，无历史版本迁移承诺。

2026-09-06首批奖励补全：规则入口`tools/check.ps1 -Suite rewards -UI`通过1992项断言，包含全部13个相关套件且各执行一次：rewards162、events204、core301、equipment108、links37、composites83、equipment_complete229、prison153、guard120、pressure105、enemies160、tower184、tower_progression145，另有选择断言1项。同轮完整窗口通过520项断言，无引擎错误。随后仅修订第二段开锁说明，完整窗口复查因最小化暂停并打断鼠标拖放，该轮明确作废；恢复干净窗口后最终执行`tools/check.ps1 -UIOnly -UISuite equipment_complete,pressure,rewards`，34项装备、28项压力、27项奖励共89项窗口专项全部通过，无引擎错误，模块耗时合计约11秒。规则行为未因这次显示与检查入口修订改变。

本批完成找准松处、扯开缺口、接连挣动、逐层抽离、双重解锁，以及断缚护腕、游丝指环、回身缎带、余烬晶石。规则覆盖32种子随机奖励无重复/可复现/独立域、8张牌全部可抽取、只读预览；五种自由效果的费用与魔法身体条件、先保留后抽牌与两张保留不重复延期；滑脱标记实际加伤/免疫消耗/回合及提前离房清理；直接解除返能量；两段每次重新计算强制目标与新外层、并列选择、只支付一次、旧版本拒绝、选择期间不能插入其他行动、无目标不转自由效果；整张牌后一次压力增长与立即过载。

遗物检查直接归零与连带移除区分、每玩家回合刷新、实际二档到一档抽牌与纯降档/直接移除排除；真实飞踢落地后躺到坐的零费边界与机会消耗；实际魔力费用减免后的50%返还、每战首次限制、自由面不占机会、非战斗不触发。补充双重解锁先牢门后装备/先装备后牢门、储备术式只消耗一次、可停止第二把且不退费、真实收押保留全部遗物并清临时状态。非法多段状态在提交前原子拒绝。

窗口沿既有入口新增`tests/reward_ui_cases.gd`，共用原生拖牌、实际候选按钮、目标框滚动与截图助手。验证2费显示、拖向第一件后真实选择并列第二件、自由面直接拖到玩家保留两张、两把实际装备锁只耗一次魔力、单手受限时自由魔法仍禁用、新牌奖励进入卡组、完整遗物列表可滚动到最后一件。截图`ui-52-chain-targets.png`至`ui-55-relics-scrolled.png`已查看；最初测试误传装备ID而非候选ID，门禁正确报失败，修正后重跑通过。末次截图发现第二段开锁说明重复提示下一把，已修正为本次结束并补窗口断言，最终奖励专项通过。

整合：`data/card_rules.gd`集中机械定义及普通／罕见／稀有／完整奖励池；`core/card_effects.gd`共用旧牌和新牌的目标、费用、保留及逐段处理；`core/relic_effects.gd`统一直接触发、次数与行动后发放。只读投影/界面不增加状态写入口，卡牌和遗物均继续沿`dispatch`提交。事件奖励池已按真实稀有度拆分，文档及扩展接口同步。暂定数值为滑脱准备＋3、重挣扎9、两段各4、晶石返还50%；不表示最终平衡完成。

2026-09-06首批事件与扩展接口历史结果：`tools/check.ps1 -Suite events -UI`通过1826项规则断言、494项窗口断言，无引擎错误。相关依赖覆盖当前全部12个规则套件，每套件只执行一次：events200、core301、equipment108、links37、composites83、equipment_complete229、prison153、guard120、pressure105、enemies160、tower184、tower_progression145，另有选择断言1项。

本批新增`tests/event_cases.gd`和`tests/event_ui_cases.gd`，沿既有入口检查。规则覆盖：12种子冻结完整方案、独立事件随机域、预览不写状态/编号/随机、不向UI泄露有效钥匙；三种裁缝交易真实普通/复合安装与组件锁、加固2/10→8/10、无目标中级回退、选牌与跳过不退代价；拒绝费不足/为零仍能结束；三枚钥匙分别用实际种子覆盖全部成功/失败、锁优先新目标、眼罩/皮带真实加固、不可重复领奖、满眼部容量拒绝完整赌局。检查未知效果、无效状态和目标不合法不留下部分装备或奖励。

奖励覆盖：慌乱无主动候选、虚无先于保留、卡组不删除、下一战和完整巡视恢复；开锁针零能量真实开锁、不改耐久、消耗次数、不能安装、手腕限制及姿态接触；开牢门仍检查逃离速度，逃出保留工具次数和遗物。折叠工具匣增加实际容量，整备沙漏延长实际战后整备；同遗物拒绝重复，池耗尽不提供无法发放的遗物方案。事件不触发回魔或战后奖励，不消耗跨战增益，离房仍检查容量。

窗口覆盖：正式地图两事件图标、进入后查看地图不重抽、真实点击交易/三选一/跳过/离房，钥匙阶段只有三个选项且无道具操作；领取遗物显示已生效说明，实际中奖开锁针在休息房打开指定锁并扣次数。已查看`ui-46-tailor-choices.png`至`ui-51-lockpick-tool.png`：选项代价、锁的变化、事件奖励与遗物说明完整。窗口长路线也逐房经过事件，通过正式拒绝和离房完成；新事件占用原战斗分支位置，因此路线最低数量按战斗＋已完成事件合计检查，战斗奖励仍逐场一一对应。

整合：警卫与事件共用`equipment_offers`及真实实例工厂；复合生成组合回到结构数据，敌人将行为/外观/装备池拆成模板字段；事件配置使用配方或显式原子效果，新增内容不得再复制阶段流程。遗物与卡牌特性通过注册表参与真实规则；扩展位置和约束在`docs/content-extension.md`。该历史批次仅用过渡牌池，五张奖励牌和四件遗物在后续批次补齐；没有新增升级、专属首领行为或完成最终数值平衡。

2026-09-06塔路精英与塔顶批次历史结果：导入通过，全部11个规则套件共1622项断言通过；修正窗口测试对并拢飞踢伤害及躺姿代价的预期后，`tools/check.ps1 -UIOnly`通过479项窗口断言，无引擎错误。规则分项：core297、equipment108、links37、composites83、equipment_complete229、prison153、guard120、pressure105、enemies160、tower184、tower_progression145，另有套件选择断言1项。

新增`tests/tower_progression_cases.gd`与`tests/tower_progression_ui_cases.gd`，共用原检查入口。覆盖12种子下第8/12层可选精英及实际绕行连接、第16层双警卫与唯一出口连接；实际旅途保留装备和资源，两名70生命警卫分别受击，只击倒一名不能领奖；奖励、整备和容量整理完成前出口不开放，伪造抵达出口的移动完整回滚。精英与塔顶均沿正式收押、探索、坐姿踢开通风口、逃离和重建塔路流程检查，安全等级保留，新塔顶使用新敌人实例。

窗口验证实际地图查看不跳房、拖踢击到指定警卫、携带腿部装备时并拢飞踢造成10伤害并打断且变躺姿、双警卫失败仅入狱一次、正式塔路重开入口、领取奖励和整备后前往出口。`ui-41-elite-summit-map.png`至`ui-45-summit-cleared.png`已实际查看：地图图例、双敌意图、失败分支与通关文字完整。初次窗口测试把携带腿部拘束的踢击误按普通6伤害断言，修正为真实10伤害及姿态代价；修正过程中的测试字段笔误由错误日志门禁拦截，最终窗口重跑通过。

本批统一`room_entry_reason`供地图与正式前进读取；`-Suite tower_progression`自动合并监狱、警卫、塔路及传递依赖，各套件只执行一次。长路线规则与窗口复用`tests/route_driver.gd`，仅在流程测试中降低警卫生命，后续攻击、奖励和整备仍使用正式操作。定点窗口夹具从真实相邻休息房开始；原长路线检查仍逐房前进。这些通过结果不表示70生命双警卫与当前牌池的最终难度已经平衡。

监狱批次历史最终结果：`tools/check.ps1 -Suite prison -UI`通过1463项规则断言和423项窗口断言，无引擎错误。相关依赖覆盖当前全部10个规则套件：core283、equipment108、links37、composites83、equipment_complete229、prison153、guard120、pressure105、enemies160、tower184，另有选择断言1项。最终左右分栏牢房与返塔地图截图已再次查看。

2026-09-06监狱批次：新增`tests/prison_cases.gd`与`tests/prison_ui_cases.gd`，沿原套件/窗口主入口执行。`-Suite prison`合并guard/tower及所有实际依赖，每套件一次；初次完整`-Import -UI`通过1444项规则、423项窗口断言。随后优化牢房左右分栏，并补充高安全等级、手势条件和反抗整备超容量检查，最终结果见下方。

规则覆盖：真实收押进入牢房、普通抽弃补能、独立有限发现随机、只读投影不泄露未发现顺序；探索费用按真实区域等级、零费发现不可重复刷取；倒计时精确到巡视，降低耐久不等于缺装，组件编号丢失可被发现；清单齐全保留随身工具、没收已安装工具；违规收紧及按安全等级追加真实装备、没收所有工具、不恢复通风口。检查完成才恢复消耗牌至弃堆、不能重复确认。三个巡视节点都可反抗且不提前恢复消耗区；胜利发专用钥匙、一次正常奖励/恢复、整备容量整理后回牢房；失败保留装备并只增加一次安全等级。开锁使用真实卡牌、手势条件、压力魔力费用和储备，旧版本/姿态变化不能绕过出口速度。坐姿并腿踢击打开通风口，每玩家回合一次，扣能量并消费对应蓄力；出口检查携带容量。逃离保留资源/装备/卡组/增益/安全等级，遗留墙面工具，重建路线而非复刷旧房，下场才正常补能。最后一回合过载只到达一次巡视、下一玩家回合只扣一次惩罚，回合中过载关闭探索和出口。非法发现记录导致回合、牌堆、资源和日志完整回滚。

窗口覆盖：真实练习菜单，测试夹具仅把警卫的已公开意图推进至收押，随后实际结束回合与进入牢房；点击探索获得两件有限工具和通风口，安装工具沿原道具入口，逐回合进入巡视，检查后真实没收墙面工具，继续启动下一巡视钟。坐姿三次踢击后经独立出口返回新塔底，地图实际显示可达的新入口。原生拖牌确认自由面不能开门、拘束面消耗实际“术式解锁”和魔力后打开牢门，并沿速度合格路线逃出。基础三姿态与原身体装备拖放继续保留。

截图`ui-37-prison-cell.png`、`ui-38-prison-inspection.png`、`ui-39-prison-vent.png`、`ui-40-prison-return.png`已查看。牢房最初纵向长列表已改为探索/通风口与牢门左右分栏；返塔地图使用独立塔底节点，不与首层重叠，也不再显示当前房间不可达的矛盾提示。五级只完成终局流程，不把未生成的专用固定套装计作通过；当时特殊道具路线和塔路精英节点尚未接入；本批已接入塔路精英。

2026-09-06警卫批次历史检查：`tools/check.ps1 -Import -UI`通过，导入无错误，规则1310项断言、窗口381项断言通过。规则分项：core283、equipment108、links37、composites83、equipment_complete229、guard120、pressure105、enemies160、tower184，另有套件选择断言1项。相关入口`-Suite guard`已通过1126项断言，自动合并依赖，每套件只执行一次；最后完整回归同时确认原塔路与普通敌人流程。

警卫规则覆盖：12个种子的意图/普通与复合工厂合法性、同种子复现、工厂探测不改状态或随机；公开的额外操作不递归、先加固再上锁、原目标失效落空；蓄力与先手双操作、普通回合不重复执行、打断延后；第10回合完成后11准备/12执行，双区域满级触发锁定、解除不取消、不改写当前意图；准备和执行分别打断、击倒取消、躺姿仍按既定先后手执行收押；双警卫首个收押立即终止整场且只增加一次安全等级，击倒两者才发一次奖励。入狱验证原装备耐久/锁/组件/链接及魔力/压力/卡组保留、随身与安装工具没收、增益/惩罚清理、实际新增普通件和链接、检查基准一致、无战后恢复奖励、重复回调与旧行动拒绝。非法附加操作引起整个正式提交回滚，资源和日志一并恢复。案例集中在`tests/guard_cases.gd`，不复制通用规则测试。

警卫窗口覆盖：真实菜单启动单/双警卫，拖踢击到指定实例只影响该敌人；逐回合经过打断、连动、收押进入真实结果，查看保留/新增装备不写状态；该批结果仅到入狱；本次已改为通过正式入口继续牢房。`ui-34-guard-intent.png`、`ui-35-capture-result.png`、`ui-36-double-guard.png`已实际查看，意图与收押提示完整，双敌目标分离。警卫仍为临时轮廓，非最终人物素材。

压力批次历史最终界面复核：`tools/check.ps1 -UIOnly`通过339项断言，无引擎错误；当时保留上一轮1000项相关规则日志。法术牌当前费用和过载空手牌提示已随截图复核。

2026-09-06压力批次：首次`-Import -UI`完整回归通过1183项规则断言、338项窗口断言。随后补充法术牌实时费用与无来源时的预览快速返回，以`-Suite pressure -UI`通过1000项相关规则断言和338项窗口断言；相关套件为core283、equipment108、links37、composites83、equipment_complete223、pressure105、enemies160，另有选择断言1项。tower184已在本批完整回归通过，后续修改未触及塔路。过载空手牌文案另用UIOnly复核，最终结果见下方。

新增压力覆盖：0/40/80分档与单调魔力曲线、加费后再扣储备、实时法术牌费用、免费魔法不加费且休息房仍禁自由效果；稳定心神费用/版本/回滚；来源时机和装备移除停止；行动后增长、立即过载、余数、多次累计、魔力归零下限、禁用全部剩余动作；后续回合惩罚只消费一次并与能量增益抵扣；先后手下的两名敌人顺序、打断一并延后、不取消第二名敌人、不重复前一敌人阶段；战斗结束/奖励/整备/练习退出只继承压力；移动来源保留、房间来源停止；非法来源使整个提交回滚。核心案例为`tests/pressure_cases.gd`，沿原依赖注册表合并运行。

压力窗口：真实滚动菜单启动两种练习，压力按钮显示实际来源/时机/魔力倍率，稳定心神扣费；两次原生拖牌触发过载、弹出结果、只保留继续入口；继续后准确更新休息计数和能量；敌人意图显示威压65，两个实际行动累计过载2次；完成战斗、选奖励进入整备保留压力而无惩罚。截图`ui-31-pressure-sources.png`、`ui-32-overload.png`、`ui-33-enemy-pressure.png`已查看。看到空手牌旧提示与过载冲突后，已修改为跳过剩余行动并增加窗口断言。

- 初始10牌、抽弃牌守恒、保留牌到期、奖励加牌、三回合整备和跨战继承。
- 紧度边界、同比降档、锁减半、单件无堆叠惩罚、分层与同层目标选择。
- 普通滑脱免疫时仍付费、眼部无挣扎不能触发自由分支、魔法身体条件及资源折扣。
- 姿态相邻切换、借墙结束玩家阶段、先后手只在回合开始判定。
- 冻结意图、打断不重抽、连续打断限制、击倒与附着离场各自结束战斗。
- 版本过期、伪造或不可用行动拒绝且不改状态；预览不推进随机；固定种子复现。
- 实际窗口按钮完成选牌、目标选择、出牌、遭遇、奖励、整备、下一场与重开。

2026-09-06装备补全历史记录：Godot 4.7.2。该批通过`tools/check.ps1 -Import -UI`：导入无错误，规则1073项断言、界面311项断言通过。窗口检查覆盖1600×900与默认1440×810。规则分项为core283、equipment108、links37、composites83、equipment_complete217、enemies160、tower184，另有套件选择断言1项。全规则约6.6秒，各套件只执行一次；未缩减既有规则覆盖。

本批修正了底栏溢出、同部位目标名称混淆、蓄力在体术衰减前计入基础伤害，以及浮游锁在蓄力时确定最终目标。确认目标提前解除后，锁的最终附着落空，不改选新目标。

新增覆盖：沿不同分支均可完成长塔路并抵达出口；禁止跳房与重复领奖；移动耗时按姿态和实际固定部位计算；移动期间牌堆、资源、玩家回合增益与随机游标不变。

界面测试使用真实鼠标事件验证右键翻面和Godot原生拖放：自由面生效、错误牌面拒绝、拖离目标取消、两件装备分别展开、拖入第二框只移除第二件，以及三档免疫滑脱仍扣除卡牌和费用。

新增角色拖放：固定攻击以实际落点敌人为目标，法术费用只扣一次；攻击不能作用玩家，已离场敌人不接收，挣脱牌不能作用敌人。姿态拖到玩家使用正常费用和回合规则。拘束面拖到玩家后先选部位，再选具体装备；选择前无消耗，右键翻面撤销原选择。自由面点击或拖到玩家直接生效；魔法身体条件不满足、能量不足均不扣资源。截图补充 `build/ui-09-actor-actions.png`、`build/ui-10-player-picker.png`。

休息房覆盖：真实塔路进入与离开、5回合耗尽、提前离开、每房服务仅一次、无自动回魔与消耗牌恢复、禁止自由效果但允许拘束分支的附加收益；挂钩3次、同比降档、三档紧度绕过、结构及外层限制和姿态范围。

工具覆盖：手指与脚趾安装、使用无能量费用、只切外露兼容材质、锁不减伤、次数共享与耗尽移除、携带容量减少、超载整理、随身次数跨房保留与安装工具离房遗失。窗口操作覆盖领取、打开道具面板、安装到墙脚、改变姿态和两次实际切割。截图：`build/ui-11-rest-room.png`、`build/ui-12-hook-targets.png`、`build/ui-13-field-tool.png`。

新版截图：`build/ui-01-battle.png`、`ui-02-free-drag.png`、`ui-03-two-targets.png`、`ui-04-reward.png`、`ui-05-map.png`、`ui-06-travel.png`、`ui-07-cleared.png`、`ui-08-default-window.png`。较早无ui前缀的截图仅为历史验证产物。

## 当前边界

架构整合验证：显示投影不推进随机或修改状态，嵌套显示数据不引用可写的运行状态；篡改显示中的伤害或费用不能覆盖提交时的正式判定。战斗、整备、休息三种真实流程下，下回合能量只消费一次，抽弃牌守恒，魔力不额外恢复，战斗计数与非战斗倒计时分别推进。

界面索引验证：实际敌人与不存在目标分离、空行动组保持为空；打开面板不推进规则，外部状态推进后旧候选与旧拖放均拒绝且不消耗资源，失败提交也刷新显示和索引。原有125项界面断言包含完整战斗、路线、休息房和工具操作。

检查入口新增退出码、错误日志和完成标记三重检查。实测临时注入运行时错误后，Godot仍打印`PASS: 261 assertions`，入口正确判失败；已恢复原测试文件并重新跑通过。故障注入仅用于验证检查入口，未留在游戏或测试源码中。最新日志为`build/check-rules.log`与`build/check-ui.log`。

模板批次覆盖：四类材质的生成与实际解除、初/中级和紧度独立、材质版本随意图冻结、独立随机序列、错误部位/锁定/材质版本/耐久的原子拒绝、同部位混合容量与外层追加、加固与滑脱共用既有规则、胶带不继承旧粘性封锁、锁选择和执行时的双重复核、石片与锯条对塑料的实际兼容差异。专项案例在`tests/equipment_cases.gd`，由原规则入口统一运行。

装备练习通过真实界面入口启动：鼠标点击重开面板、编号合法性、四材质显示、明确的徒手/切割禁用原因、锯条两次切断扎带、原生拖牌滑脱胶带、挂钩解除绳索、练习结束及回到塔路。练习沿用正式候选和提交，5回合到期不产生战斗奖励或塔路进度。截图：`build/ui-14-equipment-practice.png`、`build/ui-15-material-tools.png`、`build/ui-16-practice-menu.png`。

敌人批次覆盖：绳索四阶段与第二回合两类分支；眼罩两回合蓄力、规格冻结、初/中级、各阶段打断、提前击倒、公开前后眼部容量改变的施加落空；同种多敌的独立生命、行动和来源，跨房ID不复用，全部离场仅奖励一次。眼部受阻立即显示且不擅自隐藏敌人意图。弱池开局抽取与只读预览可复现。专项案例在`tests/enemy_cases.gd`，由规则入口统一运行。

地图覆盖：已走连线严格对应真实移动记录；未选分支、正在移动与未来路线分别投影；房间图标查看不改变状态、不产生跳房候选，滚动位置随查看保留。窗口中实际点击未来节点，进入绳索＋眼罩战斗，并拖放踢击到第二只绳索，确认只有落点目标受伤与延后。战斗内查看地图不会叠出结束回合按钮。截图：`build/ui-17-rope-blindfold.png`、`build/ui-18-double-rope.png`、`build/ui-19-spire-map.png`。

长塔路覆盖：30个种子的节点唯一、向上连接、全节点可达、无非出口死路、生成段分支不交叉；同种子复现与不同种子变化；第7/11/15层休息点；预览不修改图或随机游标；两条完整长路线每战奖励一次。案例在`tests/tower_cases.gd`。窗口通过真实按钮完成长塔路，切换整塔总览、定位当前房间并维持不可跳房规则。整塔截图为`build/ui-20-full-tower.png`。

人物美术覆盖：从正式姿态动作依次切换站/坐/躺，显示正确图集区域并保持比例与地面对齐；绘制与动画不改变状态或随机游标；窗口像素检查确认绿底消失且粉色人物仍可见，原拖牌目标继续正常工作。当前使用用户本轮指定的三姿态附件，躺姿区域已扩展以完整容纳头发。截图：`build/ui-21-hero-stand.png`、`build/ui-21-hero-sit.png`、`build/ui-21-hero-lie.png`。绿底透明由专用画材在运行时完成，保留源图。

普通链接覆盖：两端引用同一共享耐久，显示快照无可写引用；同对逆序重复、失效目标、跨区域连接与普通施加入口拒绝；独立紧度伤害、蓄力只消耗一次、旧拖放原子拒绝、无滑脱与上锁；方向声明只阻止指定装备的滑脱。徒手接触检查任一外露且可达连接处，不把连接装备的锁或材质误当链接自身限制；工具固定伤害、次数与零能量费用；移除链接保留装备，移除必要装备清理链接，新装备不重接；战后、整备和房间移动保留连接。非法链接导致回合事务完整回滚。专项案例在`tests/link_cases.gd`。

链接窗口覆盖：真实点击独立练习入口、两部位显示连接标记、原生拖牌选择共享链接目标且仅结算一次、坐下后切割并同步更新两处详情。截图：`build/ui-22-link-targets.png`、`build/ui-23-link-released.png`。链接练习继续使用正式5回合规则与两件切割工具。

单手套覆盖：短/长与直/交叉四种组合的原子创建、覆盖与能力差分、组件共享目标和只读投影、容量与内外层、关闭手指后的施法/握持/安装条件、组件独立锁、肩带紧度上限、结构滑脱/挂钩前置、首次肩带解除不触发同次脱下、跨三档伤害不倒推资格、切割/滑脱不冒用挣扎捷径、外层阻挡、套体破坏保留独立内外层、敌人组件上锁、跨战与跨房保持、错误覆盖原子回滚。新增83项断言集中于`tests/composite_cases.gd`，通用材质、链接与回合案例不复制。

单手套窗口覆盖：真实菜单启动短型/长型，拖牌至手腕或小臂后选肩带和套体；两次滑脱去除一侧直肩带，再用一次挣扎按预览解除整件并更新资源/容量。长型验证交叉肩带共享耐久、挂钩前置、关闭手指后的切割拒绝、脚趾安装与躺姿固定工具切割。截图：`build/ui-24-glove-components.png`、`build/ui-25-glove-release-preview.png`、`build/ui-26-long-glove-tool.png`。目标摘要与完整详情分开，禁用原因不重复堆放。

检查整合实测：composites选项自动执行core/equipment/links/composites，各套件仅一次；完整规则约5秒（按输出分项耗时），未削减既有断言。未知套件misspelled实际返回非零且不生成成功标记，日志为`build/check-suite-rejection.log`，其中错误属于这次预期拒绝。窗口共用真实练习启动和滚动至指定拖放目标助手；UIOnly只重跑窗口流程，保留此前规则日志。

装备补全覆盖：29个练习的真实生成数量与配置一致，预览不写状态；普通模板全部合法等级；四种单腿套破坏套体后的外带ID/耐久/锁/链接保留、能力恢复与容量预留、长短叠层和超容量原子拒绝；拘束衣双前置、无滑脱袖部连接、已安装工具处理与整件清理；左右独立包裹的手势/握持/卡牌自由分支和上肢容量单次扣减；眼口胶带、马具逐眼罩紧度比较、相等允许、母件/附属件分别解除、马具独立锁减伤；十二种躯干固定的手持/徒手范围；高级复合基础耐久且无未定义魔法效果。损坏组件结构后的失败回合完整回滚。新增217项断言集中在`tests/equipment_complete_cases.gd`。

装备窗口补全：共用助手滚动到菜单下方并真实点击；工具三次切断单腿套套体后，链接仍引用遗留外带，随后原生拖牌到该外带准确扣耐久；自由的另一只手切开单侧包裹；拘束衣禁用原因可见，并用脚趾安装工具、切换坐/躺、切割真实袖部连接；马具分别阻止较松眼罩并允许等紧度眼罩使用挂钩；高级材料真实显示。新增窗口案例集中于`tests/equipment_ui_cases.gd`，从原窗口入口运行，共用助手。截图`ui-27-leg-bands-retained.png`、`ui-28-jacket-structure.png`、`ui-29-head-comparison.png`、`ui-30-advanced-catalog.png`已查看确认。悬浮眼罩另新增16种子规格文案检查与两模板覆盖，保留冻结/打断/落空原有测试。

四类普通材质、眼口、包裹、单手套、四种单腿套、拘束衣、躯干固定和普通/组件链接均有真实装备规则与练习入口。29项装备练习、2项压力练习、2项警卫练习合计33项。警卫练习已施加合法中级普通/复合装备，并完成实际入狱保留、没收与追加结算。普通塔路敌人生成绳索、皮带及布带/胶带眼罩；第8、12层的可选警卫与第16层塔顶双警卫可生成合法中级普通/复合装备。地图包含15层房间、第16层双警卫与第17层出口，约30节点。监狱探索、巡视、反抗、消耗恢复、三条基本逃路与返回塔底现已实现。第5/9层已加入首批两个事件，慌乱、开锁针、工具匣与沙漏已实际结算。五级专用固定结局装备、特殊逃离道具、其余道具与多章节尚未实现；自动存档与继续游戏已在后续批次实现；颈部用途、肩部跨区域链接、额外通用加固、驷马/折叠固定和专项模板不在本批已定义范围。数值集中暂定，主角仍只有基础三姿态，无逐件穿戴差分；警卫临时轮廓不代表最终美术。

窗口截图生成在 `build/`，不是运行资源。


## 2026-09-07：具体位置、抽牌牌面与行动交互
- 规则相关分类合并运行：equipment_complete、rewards、persistence、action_copy、intent及自动去重的依赖，4325项通过，27.29秒。
- 界面针对实际拖牌、工具安装→关窗→换姿→重开→切割、贴墙结束休息回合、重复刷新不重播反馈进行了验证。baseline 252、enemy_feedback 36、interface 250、equipment_art 172均通过；奖励旧翻面预期修正后，rewards 27、prison 60与enemy_feedback 36复核通过（最后一轮123项、12.60秒）。不把最后一轮称为全项目回归。
- 精确位置检查覆盖独立小腿段不互相遮挡/减伤、同段真实外层遮挡、位置容量、无效位置原子拒绝、肩带排序与存档原位恢复；旧15回合预期统一改为5。
- 抽牌以新抽取序号初始化UI，保留手动翻面；资源不足不影响默认面的目标判断，三档免疫与身体条件影响。新字段损坏的存档必须拒绝且不改当前局。
- UI证据沿用既有固定文件名覆盖，未另建检查脚手架。ui-101-installed-tool-and-feedback.png记录已安装工具常驻入口；ui-86-posture-choices-seated.png记录贴墙按钮与普通起身并排。


## 2026-09-07 · 贴墙状态、颈部与子位置

- 新增 `wall` 专项，正式Game验证战斗距墙1—4随机、读档不重抽、预览不改随机；固定输入后验证移动支付、末段停墙、边界拒绝、贴墙属性、起身不结束回合、工具与挂钩接触、入狱及反抗位置。三能量移动仅触发一次能量被动，不推进持续回合。71项通过，1.70秒。
- 关联规则批次执行4500项，其中两条沿用“贴墙结束回合”的旧断言失败；已按新需求改为保持当前回合／先后手，再执行core全部338项通过。其他关联套件（存档、商店、状态、特殊装备、奖励、事件、装备、链接、复合、监狱、警卫、压力、敌人、塔路）在原批次没有失败，没有无故重复运行。
- 界面实际点击、拖牌验证距墙显示、右侧“向墙移动”费用与结算、到墙后起身、颈部两子位与肩带、空大腿三子位；展开的行动日志不遮挡移动。最新wall／targeting／status／equipment_complete共110项通过（10.01秒）。此前interface／body_layout／enemy_feedback／special_equipment共348项通过；新的位置专项覆盖后续移动入口调整。
- 视觉核对 `build/ui-106-neck-and-wall.png`：顶栏仅距墙数字，贴墙Buff在状态栏；右下移动按钮，左侧14组完整可见，颈部位于口部与大臂之间。
- 工具安装、墙边使用、取回与挂钩共用实际接触条件；安装工具未因离墙删除。部位细分只投影原装备真实点；肩带的展示位置不更改动作接触规则或身体活动等级。未增普通颈部装备池。

## 2026-09-07：左侧装备双列小卡片

普通／复合／链接／特殊装备详情复用同一小卡片组件，显示字段由equipment_entry统一提供。新增真实窗口断言验证两卡并排无重叠、点击展开与收起均不改变游戏快照，并保留真实拖牌目标与解除流程。遗留外带及特殊装备到期后的被动状态保留在默认卡面，不因折叠说明被隐藏。

规则special_equipment及关联status/rewards共288项通过（4.29秒）；窗口body_layout/special_equipment/equipment_complete/targeting共142项通过（9.96秒）。检查记录build/checks/20260907T044820511-22688。截图ui-84-body-equipment-details.png已查看，双列卡片位于原部位详情窗内，名称、耐久、紧度和详情按钮清晰。未改动行动规则，未运行全项目回归。

## 2026-09-07：跨子部位自动紧凑排列

取消每个子部位单独起一行的网格。整个详情面板连续排卡，按宽度与数量自适应列数；共享物理ID去重显示，卡内保留全部子部位，空位置不再占据整行卡片空间。特殊装备沿相同布局，保留容量和触及信息。

窗口body_layout/special_equipment/equipment_complete共114项通过；随后添加截图对应的拘束衣双掌共享卡、单卡满宽、手掌与手指不同装备同排和位置标签检查，body_layout最终43项通过（4.52秒）。截图ui-109-compact-jacket-card.png和ui-110-compact-cross-slot-cards.png已生成，后者已视觉核对。未修改规则或运行无关回归。

## 2026-09-07：躯干固定仅保留身后版本

用户澄清保留躯干固定绳／带及额外限制，只取消身前版本。已移除身前生成选项和六个身前练习；工厂拒绝身前施加，存档拒绝旧身前实例且保持恢复前状态；身后接触与解除规则保留。教程、装备投影、状态说明、设计文档已同步。hand_assist将原身前夹具改为身后夹具，并把原大腿额外范围断言移到装入躯干固定前，继续分别验证真实前置与固定后的限制。

contact范围及关联规则1180项通过（15.31秒），equipment_complete窗口42项通过（6.21秒）。记录build/checks/20260907T045926725-3092。已通过任务消息同步给“设计紧缚尖塔游戏设定”（01a070f2-5b3a-7980-82c2-3816e7a504a1），明确不能删除该装备或其身后限制。

## 2026-09-07：躯干固缚附加状态（取代上文专用绳／带方案）

本批规则变更：普通大臂／小臂／手腕三档单件随机附加连接式或一体式；降档保留，加固结果三档刷新（包含二档回三档、连接耗尽且原件仍三档）。附着状态、独立耐久、最外层生效、同层追加、普通外层拒绝、复合施加时原子取消及原件移除级联全部进入正式规则。连接式只在挣扎上豁免堆叠，滑脱仍受影响；一体式沿原件两种计算。

影响安装／加固候选、敌人／警卫／事件／监狱事务、装备清理、独立binding随机域、严格存档恢复、手部接触、装备卡／状态／教程／日志及练习目录。失败不清除状态，预览不消耗随机。费用、原有环境资格、其他乘区、七子槽容量、手势魔法及已安装工具身体接触不变。独立耐久10／16／24为待平衡值，紧度读取原件；刷新保留原形式。旧专用装备不静默迁移，需重新开始练习。

torso_binding规则专项覆盖：两种种子结果、三档触发／二档不触发、手指手掌排除、降档保留、真实卡牌仅破坏连接、两种加固刷新、同层／外层、复合成功／失败、原件正式解除、存档恢复／损坏拒绝、已有外层下休眠恢复及教程更新。窗口专项通过真实菜单与卡牌拖放核对卡片、连接耐久和费用。

关联contact,enemies,guard,events,persistence：2210规则通过，31.07秒；equipment_complete,body_layout：85窗口通过，7.49秒（build/checks/20260907T053457103-13164）。随后补齐连接读取原件整数紧度、教程及连接降耐久说明，最终torso_binding,action_copy：81规则通过，1.13秒；torso_binding：11窗口通过，3.48秒（build/checks/20260907T054312726-43368）。build/ui-111-torso-binding-cards.png已视觉核对，原件与连接目标紧凑并排。未运行无关全量回归。


## 2026-09-07：易滑脱倍率与移动被动

本批变更：肩部站／坐／躺均1.2；脚掌与脚趾为1／1.2／1.2；其余腿部按game-design第4.2B表。主动普通／魔法滑脱增加独立位置乘区。付费室内位移、每个实际跨房移动回合、成功探索接入共享被动；各点随机选择外层支持挣扎的物理件，预先冻结选择，按物理ID去重，不继续攻击新外露内层。肩带使用独立滑脱位置查询，不扩大套体覆盖、容量或触及。

涉及：escape_preview与正式行动事务、精准物理点、组件前置与清理、motion随机域、严格存档、墙面移动／塔路／探索、结构日志、短摘要、即时反馈和教程。费用、回合数、物品生成、敌人计划、锁及紧度的原有作用、手部辅助范围、特殊装备触发、施法成功率不变。被动不读取灵巧／环境平加值／手部辅助／蓄力／准备层，不消耗准备，不判魔法成功率，不受过载值影响。旧Demo存档缺少motion域时拒绝恢复，不做兼容迁移。

slip_motion专项142项：三姿态完整系数表、肩带和套体区分、主动普通／魔法倍率、正式位移只触发一次、辅助与准备不消耗、同层均匀抽取及较松件减半、共享套体去重、外层移除不穿透、结构禁止与三档免疫、过载不影响伤害、脚踝排除、资源不足／过期版本拒绝、晚期校验回滚、存档继续复现、姿态不触发、有装备探索与免费探索、跨房五步和最终入房顺序、教程与数值表一致。

最终关联规则：slip_motion,equipment,composites,links,casting,wall,prison,tower,tower_progression,rewards,persistence,hand_assist,status，经原分类入口去重展开19个套件，4207项通过，17.81秒。日志：build/checks/20260907T063634994-44976/check-rules.log。

最终窗口：slip_motion,casting,wall,route,prison,interface，共369项通过，18.38秒。日志：build/checks/20260907T063808279-40668/check-ui.log。使用真实移动点击、肩带卡牌拖放、塔路点击与行进、探索／牢门卡牌及教程入口；新增窗口检查确认耐久4→2.5、短摘要不混入公式、历史损耗不重放。build/ui-112-slip-motion.png已核对即时反馈；随后短摘要改动由窗口断言验证，详细公式只留日志。

调整现有检查：跨房组件不再断言耐久完全不变，改为按正式被动结果逐件核对损耗，同时保留全部其他结构／编号；紧凑装备栏检查实际位置文案，不再查已移除的旧子面板节点；牢门成功拖牌案例显式固定无口部阻碍、零过载的施法条件，魔法失败代价仍由casting覆盖；悬停案例先从手牌外移入，消除上一套件鼠标停留同坐标的干扰。未运行无关全量回归，未新增独立测试框架。

## 2026-09-07：肩部附加拘束定稿写入

状态：DesignConfirmed，ImplementationPending。用户本轮要求“写入”，本批仅更新设计、生成／模板／扩展说明、README和AGENTS；未修改运行时、玩家教程或测试，不报告绿色规则回归。权威正文equipment-design第7.2A节；单手套第6.1节同步撤销旧规则权威并保留待迁移说明。

影响计划：成对安装／加固补缺事务、原件一对上限、左右独立数值与交叉历史、滑脱数量倍率、肩部真实接触和同层容量、单手套结构、级联清理、存档、生成与随机、UI卡片／原因／教程／日志。changedUiAndLogs：本批N/A（仅文档）；上述玩家表面是实现完成条件。既有费用、一般材料资格、非肩部容量、躯干固缚及肩部部位倍率不变；移动被动既有“支持挣扎”资格在后续案例中明确核对，不能借本批擅自扩大。

第7.2A列出的正常、反例、边界、回滚、存档和窗口案例全部待编写／待执行，不是已通过的测试。旧肩带测试仅证明旧行为，不能证明本定稿。文档一致性核对覆盖3档触发、初中高初始1/2/3、一件一对、左右独立、2/1/0侧、交叉3→2→1、禁止挣扎及补缺规则。


## 2026-09-07：直接进入牢房的练习与探索讨论稿

范围：新增prison_test与prison_blind两个练习目录项，通过现有普通装备工厂装入一档手腕／大腿装备，蒙眼版加布带眼罩；Prison.start_practice只建立初始化状态和真实巡视基准，然后复用enter／begin_turn。开场一级安全、躺姿靠墙、8回合巡视、基础卡组，存档保持practice归属。没有新增探索命令、空间位置或蒙眼随机，也没有改变普通入狱姿态；空间探索改版与已确认的蒙眼零移动代价记录在prison-exploration-proposal.md，状态为讨论中。

影响：练习目录、初始化、普通卡牌／探索／巡视的直接进入条件、初始日志及练习说明、存档／菜单显示。生成池、敌人行动、正式入狱、旧探索费用、距离状态、姿态候选、被动滑脱公式均不修改。两个测试场景共用正式牢房对象，不复制第二套规则。安全等级和清单等由初始化配置建立；之后实际行动全部走候选＋版本复核。

规则新增20项：两种可见性、躺姿靠墙、正常首回合资源与抽牌、无敌人、真实巡视清单、练习存档身份、恢复后刷新版本但保留其余全部状态、过期行动拒绝、探索发现和支付一次、共享移动被动、正式回合倒计时与完整校验。目录遍历和存档全练习遍历自动覆盖新入口；目录明确区分战斗、休息、牢房开局。

最终 prison,persistence,equipment_complete 关联门禁展开8套件，1202项通过（12.06秒），build/checks/20260907T065843094-45396/check-rules.log。窗口prison,equipment_complete共117项通过（12.30秒），build/checks/20260907T065647620-43940/check-ui.log；真实菜单点击两种场景，验证旧探索按钮、巡视、眼罩和对应场景身份，截图build/ui-113-prison-practice.png。并行肩带改造期间出现编译错误及旧cross夹具错误，已与对应任务同步并在修复后重跑；肩部倍率夹具统一为40%耐久比例，保留新肩带不参与挣扎及移动被动的规则。未运行无关全量检查。

## 2026-09-07：肩部链接与单手套独立肩带实装

本记录将上文肩部DesignConfirmed／ImplementationPending推进为Implemented／Verified。新增core/shoulder_links.gd作为game管线内部助手；普通原件嵌套一对肩部链接，真实左右目标进入统一物理列表。单手套改left/right两组件，不再使用cross共享组件；交叉历史独立保存，旧组件记录拒绝恢复。普通施加与各处加固共用刷新，三档触发／补缺不修复幸存侧，不因预览或普通清理再生。警卫的额外肩部施加走正式选装、公开意图、目标复核与执行，保存后不重抽；失败不写入半对。肩带无挣扎，其他基础材料方法继承，交叉封锁统一作用滑脱与挂钩；2／1／0侧控制原件滑脱。解除位置仅肩部，UI与教程和状态面板同步，肩部主动×1.2仍保留，移动被动因无挣扎资格不再抽肩带。

新增shoulder规则专项最终105项通过：三品质初始档、六种基础材料、左右独立损耗、真实出牌费用、2／1／0侧效果、交叉3→2→1及再升3、历史存档、损坏配对拒绝、加固补缺、原件删除、幸存侧不重置、单手套同规则、焦点增益清理、同肩三对同层、额外警卫意图保存与施加。肩部窗口19项通过，实际进入新练习、拖牌解除一侧、验证另一侧耐久及费用、原件0.5提示和单手套交叉左右卡。

验证记录：
- 初次关联contact/guard/enemies/persistence/events/slip_motion共2487项，4项旧断言失败，其余通过：肩部主动倍率夹具原先借套体同步紧度，及旧肩带显示在小臂的断言；已按新规则修正，不更改正式数值。
- 修正后shoulder/slip_motion/equipment及直接交叉套件921项全部通过（5.73秒）；shoulder/body_layout/equipment_complete窗口104项通过（10.44秒），build/checks/20260907T065822663-676。
- 增加肩带解除清除找准松处测试后shoulder/status共120项通过（2.20秒）；同批intent/status/interface窗口分别14／21／260项均通过。baseline暴露旧口部自由面禁用测试，与当前施法规则冲突，已改为口部不阻止准备、真正手势卡仍检查手指。未修改正式施法逻辑。
- 六种材料补充后shoulder最终105项通过（1.25秒），build/checks/20260907T070205356-24864。
- 最终baseline窗口252项通过（38.24秒），覆盖长短单手套真实拖牌、肩部入口、交叉禁挂钩、套体特殊脱下及墙面工具，build/checks/20260907T070446172-43456。

截图build/ui-113-shoulder-pair.png、build/ui-114-independent-crossed-shoulders.png均已视觉核对：紧凑左右卡片独立显示名称、耐久、紧度、交叉与无法挣扎说明。未运行无关全项目回归。另一任务正在同步开发躺姿牢房练习，本批保留其改动，未将该练习误计为肩带新增内容。

## 2026-09-07：手指资格与手掌半效辅助

按用户最新要求，辅助逐手先检查手指自由，受限贡献0；手指自由且手掌可用贡献1，手掌不能使用贡献0.5。原有手腕、触及、自身手部和外层限制不变。core/contact.gd仅在assist分支改变资格与倍率，手持切割／徒手／开锁仍保留原来的握持和精细操作要求。core/hand_assist.gd汇总两手实际贡献，目标预览与机械事件保存逐手倍率／加值；label不再整数截断，状态面板使用相同摘要。减半只减少辅助加值，原有力量、灵巧、锁、紧度与堆叠乘区照常处理。教程与设计／生成／README／AGENTS同步，旧“手指精细不影响辅助”描述已撤销。

规则hand_assist/special_equipment/action_copy/status共286项通过；之后完整contact及直接关联肩部、躯干、装备、复合、链接、牢房等1340项通过（15.97秒）。新增边界覆盖双手掌不可用各0.5、三个解除模式真实伤害、锁后倍率、一侧手指受限且另一侧掌受限总0.5、工具资格不被放宽、预览只读、正式支付及日志。hand_assist/status窗口30项通过（5.49秒），实际状态卡、分数预览、拖牌支付与结果均核对。记录build/checks/20260907T073610912-27720，截图build/ui-115-half-hand-assistance.png已检查。未运行无关全量回归。


## 2026-09-07：后台方格探索与行动级摔倒（已接入）

用户最新修正：贴墙免判按每次移动行动的起步判断，不保留至回合结束。无眼罩只选目的地，方向仅标在目的地上；蒙眼用方向移动与？？？地点列表，最短路程≤2高亮，脚下才揭示。旧50%零移动机制取消。

实现：core/prison_space.gd统一后台7×7空间、最短路径、发现、实时墙距、工具位置、只读信息过滤与落位校验。探索候选和wall_move复用wall_movement_profile费用／步长，逐格发现后只调用一次SlipMotion；能量被动结算后按当前腿部等级判摔倒。概率采用20/40/50/60%×(2-Pressure.cast_chance)+蒙眼20个百分点，封顶100%。起步或抵达墙边免判，坐／躺／腿0不判。摔倒1—2级坐、3—4级躺，保留位移及费用，不强制结束回合。新增explore/fall独立随机域、快照校验；无旧档迁移。普通入狱躺姿起步。眼罩坐转站在原减免后+1费，墙面起身同样适用。

出口和道具：通风口、门钥匙、开门法术、开锁针和连锁开锁第二目标复核当前地点。安装处保存真实位置并加入返回目的地；现有墙缝容量不变，反抗战斗继续使用原距墙模型，战后恢复探索位置，新安装工具挂在最近可达墙格。已知工具、发现和巡视检查继续使用同一库存及正式管线，不新造第二套入口。UI只有选择框，不显示网格；移动与摔倒直接提示，明细保留日志。

验证：prison,wall,persistence,casting关联14套件共2034项通过，21.06秒；日志build/checks/20260907T075803506-16104/check-rules.log。随后追加远距连锁开门阻断、外部阶段起身加费、战斗安装工具返回牢房、两格行动只判一次等10项，exploration完整专项171项通过，3.77秒；日志build/checks/20260907T080302790-39228/check-rules.log。两组计数包含重叠，不相加为总覆盖数。旧牢房／奖励／施法／赶路案例改用明确空间夹具，功能提交仍为真实候选；完整连续路线由新专项覆盖，无眼罩和蒙眼均走到全部发现并验证往返不重复发物品。

窗口exploration,prison,wall,casting,slip_motion共136项通过，12.51秒；日志build/checks/20260907T075803506-16104/check-ui.log。覆盖原生目的地点击、路径距离刷新、隐藏方位和距离、附近高亮、现场发现、解除眼罩恢复目的地、安装／巡视／通风口逃离与门卡拖放。已查看build/ui-114-prison-destinations.png及build/ui-115-prison-blind.png，蒙眼地点采用紧凑两列，方向动作费用不重复，移动提示同步实际距离与被动结果。未运行无关全量检查，未改旧网页工程或图像素材；并行肩部和手部辅助修改保留。教程、README、规则书、扩展接口、随机域清单和AGENTS同步，以新探索正文替代早前讨论稿。

2026-09-07：稳定心神更名为深呼吸，战斗固定行动栏调整为五列，深呼吸固定在火球术右侧；整备、休息、牢房保留同位置入口。状态面板只保留操作位置和效果／禁用原因说明。原calm候选、1能量／降低25压力及版本复核保持不变，教程、练习描述、状态和日志同步更名。pressure关联规则642项、targeting/status/pressure窗口103项通过；原生点击验证降压及扣费，验证同排右侧位置和零压力禁用原因，已查看ui-116-deep-breath-action.png。日志：build/checks/20260907T082302181-16496。


## 2026-09-07：牢房二级操作与装备拖牌卡

主探索框改双列地点卡，巡视／待探索计数、移动步长／费用各显示一次，删除重复行走说明与混排的全部出口操作。地点“查看”进入原框内对应门／已发现通风口／工具二级页，返回仅改界面焦点。门锁拖牌区仅在门页显示，实际候选、距离、费用、牌面和版本复核均保留。PrisonSpace.view只新增可见性过滤后的site.interaction；蒙眼远处不给设施或工具类型，未发现通风口不提前开放操作。

装备拖牌目标改双列卡，和左侧装备卡共用位置／名称／材质／耐久条／紧度／锁及关键状态内容，另突出本次费用、效果和具体不可用原因。整个卡面继续使用原DropTarget，子文字不截获鼠标；容器按内容计算高度，修复首版卡面被撑至1200像素的问题。未增加第二套装备或探索规则。

规则exploration完整180项通过，包含预览不修改快照、蒙眼远处无交互元信息、已发现脚下通风口上下文，以及原路径／摔倒／移动／存档规则；日志build/checks/20260907T082045619-45016/check-rules.log。窗口exploration、prison、equipment_complete、baseline、body_layout、hand_assist、shoulder、slip_motion共491项通过（49.64秒），日志build/checks/20260907T082452132-47116/check-ui.log。覆盖原生查看／返回、门卡正确与错误牌面、实际魔力扣费、通风口逃离、工具二级页，以及普通／复合／链接装备真实拖牌一次结算。新增高度断言防止标题竖排或装备卡异常撑高。

此前窗口检查发现装备卡高度反馈错误，以及原生查看测试被已展开日志挡住；前者改正常容器布局，后者使用正式收起日志按钮后再点击，并新增确认确实进入二级页的断言，没有绕过拖放或行动校验。最终无脚本错误。已核对build/ui-114-prison-destinations.png、ui-117-prison-door-details.png及ui-118-equipment-drag-card.png，计数横排、主列表精简、门页独立、装备卡耐久条与效果可见。README、设计、探索及扩展说明、AGENTS同步；未运行无关全量，未修改图片或旧网页工程，并行任务代码保留。

## 2026-09-07：正式地图美术与纸面降亮

ui/route_map.gd 接入 map-icons-v1 八类节点和 map-parts-v2 七张独立素材。纸面以RGB 0.78调制显示；背景按可见窗口等比取图，滚动时重绘，左右建筑等比且低透明度显示，避免把纸面／建筑拉伸至整条长路线。详细／总览用不同显示尺寸，状态文字继续保留；当前位置金圈、可前往／正在前往青圈、已完成勾记只消费原投影，已走／正在走连线读取原path.status。删除旧程序图标和纸面划痕，正式移动、版本复核、房间和随机逻辑不变。

沿tests/route_ui_cases.gd新增实际窗口纸面明度、所有节点与原点击区域对齐、总览／定位前后快照不变及截图。原拖动防误触、非法目的地、正式五回合移动、暂停／自动继续、抵达消息、新局旧计时器失效检查全部保留。执行 tools/check.ps1 -Import -UIOnly -UISuite route 导入；修正新测试对Control坐标转换的调用后，tools/check.ps1 -UIOnly -UISuite route 88项通过，无引擎错误。通过日志：build/checks/20260907T082722506-48532/check-ui.log，窗口套件5.355秒。未修改规则，未跑无关全量。

已查看实际窗口 build/ui-117-map-art-detail.png、ui-118-map-art-overview.png、ui-99-map-arrival.png，确认暗纸面、透明图标、详细标题／状态、总览17层与入口、实际已走路线和右侧移动消息正常。没有使用示意拼装图的房间布局或路径代替正式数据。

2026-09-07警卫行动删除：按用户要求删除guard_charge及其准备／抢先两次操作生命周期、15点威压与两次10点余波定义；取消回合开始的优先行动分支，普通附加行动、打断延后和收押保持。同步意图、术语、教程、练习、文案包及设计说明；当前普通警卫存档可恢复，旧蓄力和优先计划拒绝恢复。新例覆盖全部普通阶段不生成删除项、打断后原计划执行一次且不增压、保存及非法旧行动回滚；窗口从正式警卫入口连续推进验证。guard/pressure/intent关联规则1212项与窗口98项通过，persistence关联847项通过（两批存在重复依赖，不合计为唯一案例数）。已查看ui-117-guard-no-charge.png。检查日志分别为build/checks/20260907T083617364-44724、build/checks/20260907T083710735-46988。历史记录中的警卫蓄力覆盖自本次起废止。


## 2026-09-07：探索距离条、安装地点与离墙预告

距离条按入口到各地点的固定最短距离作基准，靠近缩短、超过区段标红；0格初始基准与装置地点正常支持，重绘与读档不重新设定。PrisonSpace投影已安装工具实际位置／次数，UI优先显示独立地点卡，并继续通过原二级页安装／使用／取回。蒙眼远处不投影数字或安装工具身份。离墙提示取本次实际步长路径：沿墙不报、离墙报、中途离墙后回墙独立提示；预览不更改任何结算。

规则exploration198项通过，覆盖新增的入口基准、走远／回程、0基准、沿墙／离墙／回墙／后续行动边界、蒙眼信息、真实安装／取回、安装坐标读档与原探索全套；窗口exploration、wall、prison共156项通过。记录build/checks/20260907T084650404-47120，规则4.49秒、窗口15.05秒。后续把条体高度调至22以容纳数字，并通过正式收起日志按钮拍摄完整面板；exploration窗口48项再次通过，build/checks/20260907T085000233-46260，6.12秒。已核对ui-119-prison-distance-tool.png及ui-120-prison-blind-wall-warning.png，红段、安装地点与蒙眼提示可见。

查阅原项目规则书第19、23章及多操作部位／高度交叉契约，将高度／部位／姿势简化建议放在探索说明讨论稿；未复制旧代码，也未把未定稿高度、嘴部安装、家具层级或临时姿势接入运行时。原工具伤害／费用／资格、墙面状态与摔倒规则保持不变；未修改其他任务刚删除的警卫技能或深呼吸入口。未做旧存档迁移或无关全量测试。


## 2026-09-07：小石片／锯条嘴部安装与高度方案v1

两件工具新增逐物品mouth_install白名单；嘴部自由时站／坐安装随手墙缝、躺姿安装墙脚缝。Tools.install_operators统一列出手指／脚趾／嘴部资格，保留旧路线；Game候选与正式installation事件记录实际operator。仍需贴墙、空位、1能量，不扣次数；没开放嘴部直接切割、开锁或取回。装好后继续走原身体接触，嘴部之后被占用不影响已安装用途。界面和教程同时补可用部位、嘴部路线、费用与边界说明。

wall关联完整6套件833项通过：新增六种工具×姿势组合的真实提交、嘴部占用、错误高度、远离墙、无墙、空位、能量、过期版本、次数不变、旧手部路线与安装后固定切割；首跑6项断言错误来自测试读取事务提交前旧物品引用，已改为读取提交后的正式实例，未为修测试改动事务。记录build/checks/20260907T090046837-38984/check-rules.log，12.63秒。

exploration／wall／prison窗口164项通过，14.77秒，同目录check-ui.log；手指和脚趾都受限的牢房练习真实使用嘴部安装，验证1能量／次数／新增工具地点和日志，截图ui-121-mouth-installation.png已核对。完整后续方案写入docs/environment-interaction-proposal-v1.md，明确三档高度、嘴部取回、按具体安装点计容量仍待确认。未改变其他任务的警卫生成、品质、紧度或深呼吸修改，未修改旧网页工程。


## 2026-09-07：固定三档高度、躺姿抬腿与中位挂钩

按最新确认实施环境高度方案：低／中／高墙缝固定0.2／0.8／1.4米；身体按真实子部位判断。躺姿膝下和小腿中部可低中，脚踝／脚掌／脚趾可低中高；脚趾安装／取回仍需自由且双腿≤2级。两件工具的嘴部取回、同格同档容量与不同墙格独立安装已接入，原费用、固定损伤、用途／材质／遮挡和正式版本提交保留。挂钩固定墙边中位0.8米，共用高度表与原次数／滑脱结构判定；坐姿上半身与躺姿抬腿范围真实参与候选。

contact、wall、persistence及直接关联完整套件共2236项断言通过，build/checks/20260907T092319560-9440/check-rules.log（21.69秒）。新增environment_height覆盖具体手肘子位置、高位足部／中位小腿、内外层、嘴／脚趾取回、换姿势保留安装点、费用次数、远处拒绝、同高不同位置、重复占位读档拒绝与挂钩降档。旧挂钩肩部／头部夹具改为坐姿后仍执行原结构断言；没有绕过正式规则放行。

界面exploration、wall、baseline、equipment_complete、prison共484项通过，build/checks/20260907T093420616-44864/check-ui.log（56.82秒）。最终补齐特殊装备卡与非装备目标的排列后，wall、special_equipment、prison共176项通过，build/checks/20260907T093611981-47472/check-ui.log（15.92秒）。原生点击覆盖地点安装、页内刷新、具体装备卡使用、取回、真实坐起后挂钩、嘴部操作与折返符说明；正常试玩与原拖牌路径保留。已检查ui-122-fixed-height-targets.png、ui-123-mid-height-hook.png。完整矩阵移至教程书；主界面仅保留实际高度与占用，可用目标优先并以双列紧凑卡呈现。

文档、教程、练习提示、具体禁用原因和安装／取回日志已同步；无旧档迁移、无第二套空间或状态系统、未修改旧网页工程及角色美术。


## 2026-09-07：高度仅后台、前台按身体部位说明

用户取消显式高度说明。墙缝改为一／二／三编号，安装候选、固定工具和挂钩直接列出当前可接触的身体部位；取回显示操作部位，无法接触说明实际目标部位。教程不再展示高度档位／米数，后台高度与全部判定保留。field_tools.part_names仅将完全覆盖的区域合并，部分范围仍显示精准子部位。

environment_height完整22项规则断言、exploration／wall／special_equipment窗口136项通过；build/checks/20260907T094059483-14000，规则1.46秒、窗口11.24秒。真实点击仍验证躺姿高处足部与中处小腿区别、安装取回及挂钩动作；界面检查身体名称存在且无高度数字，已核对ui-123-mid-height-hook.png。


### 2026-09-07 道具二级位置菜单与安装伤害被动

最新用户修正：触发按卡牌实际伤害类型，不绑定固定牌名或普通行动模式。CardRules.damage_type 与 Tools.trigger_damage_types 分离方法与伤害；魔法滑脱属于滑脱。已安装切割不再生成主动 item_use，随身道具投影合法位置分组；共享接触助手按真实外露位置筛选，连接绳解析真实连接部位。安装工具在原牌伤害后提供固定值，次数、最强选择、多段逐工具一次、末次清理、读档和版本拒绝已接入。

- 规则 core/equipment/rewards/persistence/wall/environment_height 及直接交叉套件2443项通过：build/checks/20260907T095803966-11644/check-rules.log。新installed_tools专项39项涵盖跨牌名／魔法伤害、零伤害、锁、免疫、原牌先解除、材质、姿态、位置、最强选择、多段换工具、末次清理及读档。
- 后续修正合法位置投影后，contact/installed_tools及直接交叉套件1404项通过：build/checks/20260907T100012925-33728/check-rules.log。
- 最终窗口 installed_tools/wall/baseline/equipment_complete/events 共404项通过：同目录check-ui.log。原生位置点击、切割、安装、姿态、拖牌固定加成、连接绳／复合、牢房取回与开锁针均通过；检查ui-118-tool-position-menu、ui-119-installed-tool-passive、ui-120-card-tool-bonus截图。
- 前轮 enemy_feedback/interface/rewards/persistence 窗口各38/256/27/44项无失败；该轮整体因旧交互测试与位置分组缺口失败，不能标记整轮通过。上述失败均由最终404项覆盖修复。
- 没有修改压力来源或结算。并行内容加载器曾短暂缺文件导致编译失败，配套落盘后已重新验证；不删他人改动、不绕过错误门禁。

最终截图验收补充：拖牌紧凑目标卡直接显示工具名称、另加固定切割和耗1次，不再仅在detail里说明。installed_tools窗口20项通过（build/checks/20260907T100240498-35644/check-ui.log），重新检查ui-120-card-tool-bonus截图。

### 2026-09-07 塔图连线与前进统一
route_connection_reason统一真实出边及相邻层校验，出发、每次travel_step和行程验证共用。路径available复用目标进入资格；无连线分支仅显示具体原因。新增规则覆盖视图连线与候选一致、同层上方无连接、跨层／回头原子拒绝、途中边失效无资源变化、非法行程读档。tower及关联2297项通过（build/checks/20260907T100534533-48804/check-rules.log）；route窗口90项通过（build/checks/20260907T100619758-47992/check-ui.log），包括原生点击相邻无连线房间保持状态、显示具体原因，以及既有真实节点出发与逐回合抵达。


## 2026-09-07 五类可加载内容包与普通单件三档边界

- 新增 content/templates 五种独立可校验 JSON，填写说明和 AI 交接要求在 content/README.md。content/packs 默认为空，仅有说明文件；不将示例自动投放。启动扫描固定排序，逐种严格字段/范围/引用检查，全批次成功后合入原静态注册表。正常塔路/敌人装备/事件/遗物奖励均使用原来源，特殊装备通过正式 special_install 事件取得。新增内容沿候选、事务、日志和存档验证生效。
- 新增 tools/check-content.ps1 只读检查命令；5个模板独立及整批校验通过。主页提供加载数量、实际目录及可滚动错误详情；错误包全批次停用，保留内置定义。明确仅支持已有机制、重启新局启用、缺少引用拒绝读档，不提供旧包迁移或任意脚本执行。
- content专项最终283项包含磁盘加载、启动一次性登记、错误批次拒绝、重复ID、所有模板根字段的错误类型、跨文件引用、正式塔路出现、新敌人实际行动、新拘束具真实解除、新遗物容量、事件支付和奖励、特殊装备触发/到期、版本拒绝与保存恢复。新增普通变体按基础模板识别原有肩部规则，不以新名称绕过资格。
- 用户补充：全部三档紧度触发的额外添加机制仅普通单件适用。删除单手套套体三档补回肩带的旧分支及其“可加固补缺”资格。复合自带组件、左右独立耐久与交叉/滑脱数量规则保留。短/长单手套×两种肩带配置均验证一侧/两侧解除后不再生、存档不补回、三档不产生躯干固缚；普通单件正例仍通过。教程、规则与模板说明同步。
- 接入批次 equipment/special_equipment/events/enemies/rewards/persistence/tower 及直接交叉4444项、home/events/special_equipment/enemies窗口130项通过：build/checks/20260907T100435633-46776。随后启动错误类型边界专项通过，初次发现 schema_version 数组类型比较会报引擎错误，已先类型检查后判定数值，全部错误类型用例重跑通过。
- 最终普通单件/复合边界修改后 content/shoulder/composites 及直接交叉1090项、shoulder窗口19项通过：build/checks/20260907T101743186-31088。此前 content/shoulder/persistence及交叉1209项、special_equipment/home窗口73项通过：build/checks/20260907T101334565-48492。
- 主页最终35项通过：build/checks/20260907T101125870-45416，已目视核对 ui-102-home.png、ui-124-content-error.png，错误正文可读且显示文件与问题，不写游戏状态或存档。
- 事件原有开锁针案例补上已存在的到门位置夹具，保持正式开锁的距离限制，未开放远距离使用。没有复制第二个 Demo，没有发布或声称验证导出安装包。

## 2026-09-07 商店陈列重制与整件解除服务

- `ui/shop_screen.gd` 替换旧商店长列表，使用原生几何商人、棚檐、灯笼、双层货架与既有卡牌插图；售罄保留原位。解除、删牌、整理道具复用互斥二级面板，点击均提交既有候选ID与版本，商品及费用仍由规则层提供。
- `core/room_services.gd` 按整件根投影服务清单。普通20魔力、完整复合加15、所处理部分有锁加10（一次）；先开锁再归零全部组成部分，复用正式事务回滚、徒手解除效果与既有清理。不修改玩家手部自由状态或姿态，不消耗能量、回合、预备层数、随机流，不触发挣扎遗物或施法返还。
- 107项新服务断言覆盖普通及含锁报价、复合整件与独立外带、附带肩部／躯干连接／焦点清理、独立装备保留、链接依赖、外层阻挡、余额边界、重复服务、过期提交、最终校验失败回滚与存档恢复。服务不接入特殊部位装备列表。
- 最终 `services,composites,links` 与自动选中的交叉分类共1025项规则断言通过，`services` 原生界面39项通过；日志：`build/checks/20260907T110045362-44804/`。检查器同时核对引擎错误与退出码，没有将中途其他任务测试文件改写时出现的编译失败计为通过。
- 原有服务UI用例同步当前装备卡的耐久／紧度标签与“查看详情”入口，继续真实点击徒手解除；没有通过隐藏控件信号绕过鼠标操作。
- 已目视核对 `build/ui-97-shop.png`（售罄）、`build/ui-shop-release.png`（报价）、`build/ui-shop-low-mana.png`（余额不足）、`build/ui-shop-1280.png`（720p）。新商店支持原生购买、删牌、整件解除、空目标与离店；规则与教程同步，未发布或测试导出包。

## 2026-09-07 特殊设备与资源文案独立验收

- 只做验收与明显错误修复，未修改冻结的设备数值、容量或事件费用。修复 `core/content_catalog.gd` 特殊类型字段校验的一处多余缩进，以及 `ui/main.gd` 特殊部位说明、收押说明两处多余缩进。
- 更新过期断言：房间来源使用实际源名与 room/equipment 依赖，不再要求中文名包含“房间”；设备练习下回合开始为8→16，只有当前回合型来源触发，不再沿用旧的两个来源20点预期。
- 新增33种内置设备逐一工厂安装、验证、只读投影、候选及三种预览检查；可用挣扎牌实际提交，确认特殊目标不会读取普通装备模板而崩溃。两种无线设备分别覆盖大臂、手腕、手掌、手指阻止时原子拒绝；全部自由后一次移除、花费1能量且保留无关根。
- 既有用例通过：容量与家族唯一、敏感度、耗尽后设备仍保留、复合真实覆盖、跨槽零容量装备，以及已安装环境白名单。新增事件断言检查裁缝调整和锁匠失败都把对应接触来源写入实际资源变化日志。
- `pressure,content,special_equipment,status` 及自动交叉共1386项通过：`build/checks/20260907T120320444-22160/check-rules.log`。界面 special_equipment 38项、status 32项在 `20260907T120525076-28908` 通过；该轮pressure发现旧预期后，修改并单独重跑47项通过：`20260907T120644104-2728/check-ui.log`。合计117项界面检查通过，未声称此前整轮失败日志为PASS。
- `rg` 扫描 ui/core/data/content 的 `.gd` 与 `.json`，玩家侧旧词“压力／过载／威压／占位装备”无命中。后台稳定ID与测试名称保持原样。

## 2026-09-07 主页读取商店存档中断修复

用户启动日志证实：`SaveStore.summary` 缺少 shop 显示映射，读取真实商店存档时抛错，后续 summary.available 访问再次失败，主页只创建到内容包按钮。补全 shop/treasure 的存档摘要名称，集中为 PHASE_NAMES；未修改用户存档或游戏规则。

新增合法快照全部阶段均有摘要名称的契约断言；主页原生测试增加商店已购商品／宝箱分别保存→冷启动→全部主页按钮可见→继续游戏，验证金额、库存、已售状态和存档文件不被启动覆盖。home共63项通过：build/checks/20260907T121112739-33392/check-ui.log，截图build/ui-home-shop-save-fixed.png已目视核对。persistence及自动交叉1432项通过：build/checks/20260907T121153009-44544/check-rules.log。最后通过原启动器重新打开游戏，实际用户目录的启动日志不再报错。


### 2026-09-07 规则书 v0.12 整理

文档批次，仅整理普通道具、安装被动和塔图前进。主规则第6章补当前工具数值、直接使用菜单、共享次数与后台三处安装点；第9.3节集中维护真实连线、分支限制、途中复核与读档；第15章修正地图纸面旧说明。内容生成指南补high_wall及伤害类别字段，未改运行时代码、数值或既有测试。核对依据为field_tools、installed_tools、contact及game的现行规则；实现验证沿用此前道具与塔路记录，本批只做文档结构及引用检查，不声称重新完成游戏回归。
# 2026-09-07 口球组合替换

验收补记：用户要求运行测试后，`-Suite equipment_complete,casting,enemies,guard,prison,persistence` 自动合并相关交叉分类，3298项断言全部通过；`-UIOnly -UISuite equipment_complete,casting,enemies,body_layout` 共139项窗口断言全部通过，两个最终进程均退出0且无引擎错误。修正了规则／窗口各一处旧施法夹具：高级口球现在带马具，零成功率案例改用独立手腕目标，避免先被口球结构限制拦截；保留零成功率不支付、不随机、不可提交及界面原因断言，不修改玩法。最终日志分别为 `build/checks/20260907T124423228-48500/check-rules.log` 与 `build/checks/20260907T124542306-51400/check-ui.log`。下段“未运行”是上一批提交时的历史记录，本次结果以本补记为准；非全项目回归。

沿mouth_band原接口接入四种组合及固定等级，复用口部卡牌／徒手／上锁／施法和马具滑脱限制；停止独立马具新生成。练习、敌人预告、事件、教程与高安全等级显示同步。equipment_complete增加组合、单目标及存档断言，现有马具用例改为整件口球。按用户要求本批未运行测试，待equipment_complete／casting／enemies／guard／prison／persistence及相关窗口验收；不能据此标记验证通过。旧名称口部装备存档未做迁移，需重新开始。

### 2026-09-07 仅向下普通链接滑脱×1.25
Links.slip_factor从有效普通同肢链接和真实两端部位派生，仅普通单件受益，多条不叠乘，有向上链接则无加成。共用escape_preview接入普通／魔法／移动被动，独立link_factor进入历史计算日志，拖牌卡直接标明已计入。新增方向反序、三姿态、普通与魔法、被动、挣扎不变、多下链、上下链、解除重算、三档免疫、读档、正式出牌及旧请求拒绝。规则与教程同步；未改变原blocked_slip方向限制、数值档位、固定切割或复合结构。links/slip_motion及关联981项通过；窗口slip_motion通过，日志build/checks/20260907T130658818-29604。


## 2026-09-07：结构审查六项修复与缓存清理限制

- 阶段定义归并至`data/phases.gd`，合法存档阶段、主页摘要和房间标题读取同一表。卡牌文案通过`Balance.card_info`读取基础伤害、段数、加成与实际魔力费用，不再匹配“消耗10魔力”替换整句话；实际费用保留统一两位小数显示。
- 规则／窗口注册表只保存路径，选中后加载对应模块；检查进程默认180秒超时，可配置。`-VerifyRunner`额外验证挂起进程在1秒后终止，故意运行时报错不能得到PASS。仅处理检查启动的进程。
- 删除无调用的`Contact.torso_reach`及旧`buffs/legacy`副本，现有UI和测试使用结构化`statuses`。保留被真实特殊装备投影调用的`equipment_entry`描述与电量显示。
- 复合装备的候选和安装共用`Game._prepare_assembly`；准备函数只构造待安装组件并检查资格，不替换state、不推进编号或随机、不发事件。实际安装才提交。补充空闲／已有复合装备的预检与真实安装一致性、拒绝原子性及引用隔离验证。
- 每份快照只生成一次特殊装备列表和压力投影，供身体区域、状态及资源显示复用。特殊装备安装及回合触发迁入Game的既有工厂／回合管线，数据文件不再执行这两类写入；内容模板文档与测试调用同步。
- 二级信息面板只重建自身覆盖区域；打开、切换、关闭后主场景和手牌控件实例保持不变，候选按钮引用正确回收，遮罩不穿透。实际行动及存档状态变化仍沿既有完整刷新。
- 完整试玩暴露牢房保留选牌期间没有探索候选时的空字典访问，已修复并显示先完成选牌提示。自动试玩改用可见地点的已探索状态、距离和交互类型选路，使用当前二级界面，不读取隐藏位置或改写规则。三条规则试玩分别249／246／300次正式行动完成；第三条实际入狱后逃离。折返符与塔顶点击测试按当前目标选择及连线限制核对。

验证：

- `tools/check.ps1 -Suite runner -VerifyRunner`：规则范围合并及运行时错误／超时负例通过，记录`build/checks/20260907T125135306-49624/`。
- `-Suite all`：全32个规则模块，7016条断言通过，记录`build/checks/20260907T130756551-21040/check-rules.log`。同批窗口全套检查发现上述特殊装备旧调用、牢房选牌空候选及两项旧UI路径断言，未将该批窗口记作PASS。
- 最终受影响分类复验`-Suite status -UI -UISuite special_equipment,normal_play,prison,tower_progression`：178条规则断言、1166条窗口断言通过，无引擎错误，记录`build/checks/20260907T131306807-34444/`。其余完整窗口模块在上一批完成；导航专项额外验证主场景与手牌实例不重建。主页截图`build/ui-home-shop-save-fixed.png`可见全部入口并可继续商店进度。

第七项开发产物清理未执行：删除`build/cutout-deps`、旧浏览器预览缓存与过期隔离测试存档的命令被自动审批以“blocked by policy”拒绝；没有提供更细原因。未改用其他删除手段，所有文件保留。已记录本机抠图依赖的确切版本及重建方法，源码／素材、用户存档和历史验收截图未删除。本次统计assets约36.93MiB、core/data/ui合计约0.54MiB；build约257.71MiB、.godot约27.33MiB，缓存不作为游戏源码体积。

### 2026-09-07 一层怪物库、独立出场池与空强池
新增enemy_library个体弱/强/精英分类与配置版本；first_floor_enemy_pools独立维护普通弱池、空强池、精英与固定塔顶。原配对遭遇定义保留供练习，不进入当前普通随机池。Game支持强池为空：不抽空数组、后续普通战斗继续弱池、房间说明明确显示；Snapshot允许空强选项，拒绝错误分类和空强选项被标为已选。旧POOLS为同一份数据的兼容属性，现有内容包保持单一写入源。规则enemies/tower/persistence及交叉3848项通过（build/checks/20260907T131649485-35144/check-rules.log），含后续普通战斗仍用弱池、独立池影响真实生成、只入库不生成、分类与原子读档。窗口route/services/enemies共165项通过（build/checks/20260907T131828188-30068/check-ui.log）。规则书、生成指南、模板和独立怪物库文档已同步。


### 2026-09-07 股绳作为链接端

- 初／中／高级股绳使用已有物理编号，提供大腿上端／手腕下端；资格独立于普通占位查询，仅允许上述两个区域。股绳自身不应用普通单件的仅向下链接倍率。其他特殊装备、链接自身、同一对重复连接、伪造接触部位均拒绝。
- 原安装工厂、入狱链接配额、接触检查、链接解除、根移除级联和存档恢复共用正式路径。股绳侧与普通部位侧投影同一链接；特殊区域单独显示链接，不增加装备计数／容量。教程同步说明方向。
- `tools/check.ps1 -Suite links,special_equipment,guard,persistence`及关联分类：2743断言通过；记录`build/checks/20260907T133139270-3524/check-rules.log`。新增64条链接断言覆盖三级／三姿势方向、拒绝原子性、读档与损坏读档回滚、真实出牌移除股绳、清理与更换不重接、实际股绳接触解绳、入狱配额生成。
- `tools/check.ps1 -UIOnly -UISuite special_equipment,equipment_complete,guard`：128断言通过；记录`build/checks/20260907T133302784-3728/check-ui.log`。新增窗口案例真实打开特殊部位详情、拖入链接目标出牌、检查共享耐久只扣一次及两个连接装备保留，再从大腿侧检查同一链接。无引擎错误。
# 2026-09-07 皮革眼罩

新增中／高级eye_leather，复用现有眼罩与皮革固定接口；悬浮眼罩抽取前过滤模板等级，通用选装与两项练习接入。equipment_complete既有全模板／全等级检查覆盖初级拒绝及中高级安装；enemies补充初级排除与中级生成断言。按用户要求未运行测试。


### 2026-09-07 环境三类统一

- `data/environments.gd`集中墙壁／尖锐／挂钩类别ID与名称；普通／粗糙墙面映射墙壁类，小石片／锯条声明尖锐类，休息区挂钩映射挂钩类。特殊装备原environments及内容包校验读取同一注册表。
- 分类实际参与环境匹配，保留装备接受类别、具体工具白名单、安装处、贴墙、真实接触与剩余次数；不新增损伤／费用／解除候选或存档状态。工具详情、墙面状态、挂钩详情、教程及模板说明同步。
- `tools/check.ps1 -Suite special_equipment,environment_height,content -UI -UISuite installed_tools,special_equipment,status`：858条规则断言、101条窗口断言通过，无引擎错误。记录`build/checks/20260907T134319573-48996/`。新增19条规则检查验证墙面映射、正式安装激活、随身／高度／次数／类别不符失效及只读显示；窗口检查携带／已安装尖锐类标签。
- 首轮新增测试持有安装事务前的工具引用，导致四项负例没有改变提交后的实例；测试已改为正式提交后重新按ID查询，再完整复验上述分类。未修改接触规则以迎合测试。


### 2026-09-07 特殊部位统一装备显示

特殊部位按钮改为普通部位相同的名称＋实际件数，空位只显示名称，移除容量分数及专用位置提示。详情复用同一装备卡与真实子位置列表，跨子位置的同一装备按ID只显示一次；容量和接触事实仍保留在只读数据及规则中。链接的显示位置按两个真实接触区域展开，使股绳侧及普通部位侧在共用列表均可查看同一绳，不修改实际占位。

验证：`tools/check.ps1 -Suite links,special_equipment -UI -UISuite special_equipment,body_layout,equipment_complete`通过1795条规则断言和141条窗口断言，无引擎错误。记录`build/checks/20260907T134715171-20776/`；覆盖件数／空位文字、无容量横幅、容量拒绝仍有效、子位置、股绳链接双侧显示与实际拖牌。此前窗口检查发现旧手部触及文案断言与股绳侧显示映射缺失，已按新共用布局更新并完整复验。

### 2026-09-08 配置驱动冗余清理

- 卡牌自由／命中／降档／直接解除效果改为共享列表执行，实际数量及卡面说明共用配置；段数、保留与工具已触发数量校验读取规则字段。
- 新增配置案例验证新ID三段开锁的一次支付与中途读档、保留3张后抽2、手牌属性加值进入／离开／恢复及负值下限、未知效果原子拒绝。新ID遗物验证数值、周期、返还、姿态候选与状态说明；内容包验证合法trigger及错误组合全批拒绝；新ID精英验证普通战斗计数。
- 主关联门禁：tools/check.ps1 -Suite rewards,content,status,persistence,installed_tools,links,slip_motion,enemies,tower -UI -UISuite rewards,status,slip_motion。规则4979项、窗口73项通过，无引擎错误；目录 build/checks/20260907T143433363-31260/。
- 最后补充手牌负加值不得产生负伤害的下限：tools/check.ps1 -Suite rewards,installed_tools,links,slip_motion，1718项通过，无引擎错误；目录 build/checks/20260907T143642448-33708/。下限只约束临时属性合计，环境加值仍走原位置。
- 初次窗口回归发现末段开锁说明仍暗示后续段，已改为读取真实remaining并完整复验窗口。初次新遗物案例错误地忽略了下一次挣扎会消耗1层蓄力，已修正测试预期，保留原消耗规则。
- 存档待发放记录由三项汇总改为按遗物ID记录效果；旧结构按项目不迁移旧版约定拒绝恢复，原存档文件不删除。当前结构的中途连续／保留恢复与损坏数据拒绝均已覆盖。


### 2026-09-08 首页图鉴与统一卡面

- 首页增加图鉴入口，复用已有互斥抽屉、关闭与Escape路线。四类内容从现有注册表读取；拘束具按材料／复合／链接及品质筛选，特殊装备按部位与品质筛选，卡牌保留普通／魔法／诅咒分支，敌人按弱／强／精英与实际出场池展示。未实现敌人不加入运行池，空分支不虚构条目。
- `data/encyclopedia.gd`生成独立只读展示数据，`ui/encyclopedia.gd`负责筛选与详情；不创建装备、推进随机或修改存档。卡组只读投影补充类型及永久牌UID，删除仍提交原正式候选。
- 卡组、图鉴、教程、商店、删牌、保留选择、宝箱与战斗奖励统一复用手牌CardFace和卡牌说明。展示卡关闭战斗拖放及悬停位移，保留右键翻面，容器保持固定卡面尺寸。真实手牌拖放、奖励选择、购买与删牌费用不变。
- 最终门禁：`tools/check.ps1 -Suite encyclopedia,content,rewards,services -UI -UISuite home,interface,services,rewards`：845项规则断言、411项窗口断言通过，无引擎错误。记录`build/checks/20260907T143816332-31200/`。覆盖注册内容完整性、只读与随机不变、主页打开／分类／搜索／诅咒分支、卡面翻转与尺寸、真实购买／删牌及原手牌拖放。
- 前一轮的casting窗口11项、normal_play窗口557项通过，seed7正常试玩通关；该轮唯一失败是并行规则批次正在修正的末段开锁提示，修正后已在上述最终门禁完整复验rewards窗口。当前批次未另改连续开锁规则。
- 视觉检查：`build/ui-encyclopedia-curse.png`与`build/ui-97-shop.png`，卡面没有横向拉伸，商店商品与服务区均在视口内。

### 2026-09-08 慌乱与敏感

- 慌乱替换旧不可打出／虚无定义：1费、消耗、无其他效果；可直接点击或拖到玩家。敏感注册为保留／不可打出，实际手牌的 `hand_modifiers.pleasure_multiplier` 进入统一快感增长入口，多张相乘，离开手牌立即停止。普通奖励池、初始牌组与事件池均未扩大；敏感供既有事件加牌接口引用。
- `CARD_TRAITS`承担诅咒分类、打出消耗与固有保留；固有保留不占主动保留名额。单面卡、状态栏、装备刺激预览、机械增长日志、图鉴与对应教程说明同步，不依赖牌名或显示文字判规则。
- `tools/check.ps1 -Suite curses`：35项通过，记录 `build/checks/20260907T145632721-45304/check-rules.log`。覆盖费用／版本拒绝不变、正式自身出牌、休息与双手受限、未打出正常弃置、消耗恢复、手牌倍率／多张／移出、固有保留、保存恢复后继续行动、降低量不变、阈值与连续来源、实际能量支付触发与非法倍率。
- 首次窗口 `-UIOnly -UISuite rewards,home,casting,status`：161项通过、无引擎错误，记录 `build/checks/20260907T145422848-51836/`；含两张牌的真实鼠标点击、原生拖到玩家、不可打出／费用不足、单面、图鉴。视觉检查 `build/ui-curse-cards.png`，两牌完整可见，敏感效果未截断；卡图沿用现有共享资源，未制作新插图。
- 扩展回归没有全绿，不能把本次专项通过写成全项目通过：`20260907T145300402-11296`的3204项中，自己的读档测试误在0快感请求深呼吸已修正；另一失败为高安全监室seed2的高级三档／锁校验。单独复现时仅有原始10牌、倍率1，进入监室事务被正确回滚，未修改该系统。
- 后续共享目录出现新敌人配置变化，`20260907T145502330-17700`扩展回归有内容模板普通敌人行为断言、未观察文案及缺字段错误。`20260907T145632721-45304`的窗口161项断言执行完毕，但因教程读取新增 `special_install` 行为缺少显示映射而门禁失败；保留红灯记录，没有改动这些敌人／模板／教程行为映射或跳过错误检测。
- 最终卡牌／施法／状态窗口专项 `-UIOnly -UISuite rewards,casting,status`：81项通过，无引擎错误，记录 `build/checks/20260907T145818726-26840/`。不包含上述仍红灯的主页教程流程，不宣称其问题已解决。

### 2026-09-08 通用多阶段事件接口

- 外部事件新增`start_stage/stages/cleanup_effects`结构，阶段只向前推进；`outcomes`、`install_random`和`tighten_random`在进入阶段时沿event随机域冻结为普通具体效果。运行时继续走原事件候选、版本复核、原子提交、压力、卡牌和装备工厂，没有事件ID分支。
- `hold_special/restore_held`按精准特殊部位暂存并原样归还无连接的既有性玩具；暂存实例及冻结选项进入快照校验。初始阶段必须提供默认付费离开，非法循环、缺收尾、专用脚本op与没有下一阶段合法行动的方案均失败关闭。
- 最终联合门禁`tools/check.ps1 -Suite events -UI -UISuite events`：785项规则断言与30项窗口断言通过，无引擎错误，记录`build/checks/20260907T153255956-32932/`。规则范围覆盖event_flow、curses、content、shoulder、torso_binding、action_copy与既有events；窗口案例实际点击三阶段、提交批量效果、进入共享结果并在离场时恢复原实例。界面没有识别事件ID或添加专用按钮。
- 存档分类`tools/check.ps1 -Suite persistence`：1688项规则断言通过，无引擎错误，记录`build/checks/20260907T153348604-51680/check-rules.log`；覆盖暂存中、冻结下一阶段、恢复后继续、损坏去向拒绝和既有装备／链接／特殊装备存档回归。
- 模板与嵌套字段补强后，`tools/check.ps1 -Suite event_flow`通过30项，记录`build/checks/20260907T153555866-39344/check-rules.log`；`tools/check.ps1 -Suite content`通过477项，记录`build/checks/20260907T153610071-24168/check-rules.log`。实际`.disabled`模板会按启用后的格式解析编译，错误的嵌套effects与未知专用op均整包拒绝。


### 2026-09-08 魅魔的三局赌牌

- 新事件`succubus_three_games`已通过内容包进入正式事件池，并以`Practice_succubus_three_games`进入独立练习；练习与塔路共用同一事件定义、候选、版本复核和原子事务。
- 新事件`succubus_magic_pawnshop`已通过内容包进入正式事件池，并以`Practice_succubus_magic_pawnshop`进入独立练习。普通事件新增通用`allow_refuse`与`hide_when_unavailable`字段：本事件不生成离开候选；固定的中级无线乳夹跳蛋与中级无线后庭跳蛋必须同时可安装，“再加点料”才出现并原子结算，否则仅保留小额与大额交易。
- 第一局从当前非诅咒永久卡牌生成押牌项，胜率2/3；胜利保牌并加1枚心形筹码，失败把所选实例改为「慌乱」。第二局从当前真实拘束具生成押注，胜负各半；胜利解锁并松一档，失败进入“2件初级2档绳索／1件上锁中级2档皮带／2处收到3档”三选一。前两局结束均可按现有筹码兑现。
- 第三局先以演出文字表现椅子机关；肉棒位置现有性玩具的取下与装回只属于封闭演出，真实实例、编号、位置和剩余次数从头到尾不变。正式快感接口造成至少一次高潮，失败再造成一次并随机安装一件当前合法的中级性玩具，无合法位置时加入「敏感」。射精文案明确魔力储存在精液中并随射出的精液流失。
- 新增的`selector`、`transform_card/remove_card/ease_restraint`、事件`counter＋when`和`special_install_random＋fallback`均为内容通用接口，没有按事件ID分支；冻结选项、所选实例、事件计数与暂存装备均进入快照校验。
- `tools/check.ps1 -Suite events -UI -UISuite events`：810项关联规则与35项窗口断言通过，记录`build/checks/20260907T161237633-48164/`；实际从练习菜单打开第一局并截图`build/ui-53-succubus-three-games-practice.png`。`tools/check.ps1 -Suite persistence`：1717项关联规则断言通过，记录`build/checks/20260907T160414865-51280/`。

### 2026-09-08 六类弱怪替换与后台强度

- 绳索、皮带、胶带、扎带、口球、玩具箱加入第一幕六个单怪弱遭遇；旧锁／眼罩／封口带个体与原弱池替换，强池保持空，精英不改。`strength=1`仅保留在个体定义及内容包验证中，不进入GameView、战斗、图鉴或教程，不缩放生命或装备数值。
- 常规材质怪共用一套合法精准位置抽取与安装工厂，初级2档施加、同类加固／补施加、准备、中级2档附着离场。口球两次准备后按口部容量1附着。玩具箱使用同一特殊装备资格／工厂，准备、佩戴、停顿循环；准备冻结、打断延期、目标占用后失败不换抽，击败取消未执行计划。
- 首页六类练习、图鉴、教程、意图词条、行动结果和共享arena外形同步。新胶带／扎带／箱子是代码绘制的简易外形；没有新增图像生成或改写人物素材。
- 规则主回归 `tools/check.ps1 -Suite enemies,equipment,persistence,core`：4678项通过，记录 `build/checks/20260907T152308984-32628/check-rules.log`。包含64组材质怪完整循环、准备中存取及打断、随机池复现、失败目标、箱子多循环／满位／后手存取、已损坏保存原子拒绝，以及关联装备与移动测试。
- 窗口最终回归 `tools/check.ps1 -UIOnly -UISuite baseline,enemy_feedback,enemies,home`：446项通过，无引擎错误，记录 `build/checks/20260907T152548122-45884/`。包括真实主页与练习导航、三阶段箱子操作、拖牌、敌方反馈和完整路线。已查看 `build/ui-weak-toybox-prepare.png`：生命条保留，后台强度没有显示。
- 内容与地图补充回归 `tools/check.ps1 -Suite content,tower -UI -UISuite route,intent`：2642项规则断言、104项窗口断言通过，无引擎错误，记录 `build/checks/20260907T152719392-5460/`。包含强度非法值拒绝、图鉴只读、六个弱遭遇生成与正式地图进入。
- 初次回归的旧测试假定敌人总在手腕安装、最终三档、浮游锁存在、所有普通怪自行离场。已更新为当前真实规则：双目标拖牌采用明确手腕夹具；锁跨房保留采用已上锁脚踝；跨房随机腿部装备变化须逐条匹配正式被动滑脱日志。长路线测试只降低警卫与玩具箱夹具生命，仍通过正式攻击、奖励、整备和移动，不以此声称平衡验证完成。
- 同批检查发现反馈测试直接伪造第三阶段意图而漏掉准备记录，已改由正式计划生成；并行事件工作期间的一处match分支缩进导致编译失败，仅修正该缩进，事件功能属于另一批任务。本页记录最终关联门禁通过，不宣称全项目全量回归。


### 2026-09-08 日常测试范围与随机样本优化

- 审计发现模块已按原始请求单次合并去重，未重复执行同名套件；主要额外工作来自相同场景的大批种子（弱怪64组循环、口球16组、怪池24张、地图201张）及定向规则误带完整窗口。未删除定向行为、边界、非法输入、回滚、打断与存档用例，也未修改游戏代码。
- `suite_selection.SEED_SETS`集中管理四组日常／完整种子。日常普通怪／口球4个（0、1、3、15，胶带眼／普通／嘴分支均覆盖）、怪池4个、空强池2个、地图7个；`-Exhaustive`恢复原16／24／12／201样本，`all`自动启用完整样本。完整模式断言与既有种子保持不变；日常地图多样性要求7个样本各不相同，完整仍要求超过20种。
- 新增 `-ListOnly`使用同一个分类解析器列出每个模块的直接／交叉选入原因，窗口也使用自身注册表；不执行测试、不打印PASS。定向规则加-UI必须显式给-UISuite，防止默认完整窗口。原单次关联、去重、动态加载、独立日志、引擎报错与超时门禁保留。
- 同范围实测 `-Suite runner,enemies,tower -Exhaustive -VerifyRunner`：4666项规则通过、20.33秒；故意运行时错误（规则／窗口）和挂起超时均被正确拒绝。目录 `build/checks/20260907T153538073-44828/`。
- 同范围日常实测 `-Suite runner,enemies,tower -UI -UISuite intent`：1650项规则通过、8.11秒；真实窗口14项通过、4.51秒。目录 `build/checks/20260907T153707514-6180/`。本机该次规则耗时减少约60%，不是跨机器或所有模块的性能保证。
- 18项runner断言检查完整原种子集合、日常非空唯一子集、返回值不可污染配置、原因和范围一致，以及既有去重／未知分类拒绝。首次日常样本遗漏胶带嘴部，原断言报错后将种子7换成3，保留原分支断言，完整矩阵未改。
- 列表模式联合规则／窗口验证 `20260907T153749228-27296/`；all列表确认exhaustive且未执行测试 `20260907T153751769-27296/`；未知分类列表正确失败 `20260907T153752688-27296/`；未指定窗口模块的定向-UI在启动引擎前拒绝。本批未运行全项目all，仅验证它的完整选入与模式选择，不能将列表输出当作全量回归。
- 后续日常按实际改动合并分类一次执行；只有生成器、随机域、出场池和新随机分支改动才对相关分类加-Exhaustive。规则通过后的纯显示修改只跑对应窗口；修复失败后不重复已经无关的完整流程。用耗时和关键行为衡量检查价值，不为凑断言数添加镜像测试。

### 2026-09-08 漂浮锁与弱怪强度组队

- 漂浮锁加入弱怪与练习，后台强度1；仅按“预告行动→上锁”循环，不安装、加固或自行离场。练习提供两件真实可上锁装备，正式锁操作复用原目标资格与结算。战斗中无目标的专门行为仍待用户补充，暂沿用原通用空行动。
- 普通弱战在实际进入战斗时，根据当前装备筛选并随机抽取到总强度2；当前全部强度1，因此每组两只，允许同类重复。嘴部已占用排除口球，没有未上锁且可上锁的真实拘束具排除锁；其余材质怪与玩具箱读取现有安装资格。严格筛选全空时，仅保留口球和锁的排除，放宽其他筛选。不会预先算入同组敌人未来安装的装备。
- 地图生成只保存weak_group计划，首次入场冻结enemy_members；恢复与预览不重抽。固定练习／精英及原强池行为不变。强度只参与后台组队，不在界面显示，也不缩放生命或装备属性。文档、模板、教程与图鉴同步。
- 扩展关联门禁 `tools/check.ps1 -Suite enemies,content,tower -Exhaustive -UI -UISuite enemies,home,route`：4855项规则通过（20.29秒）、240项窗口通过（18.68秒），记录 `build/checks/20260907T160338290-38284/`。覆盖循环、打断与准备存取、目标失效后重选、击败取消、资格筛选、预算恰好填满、同类重复、兜底与冻结恢复。
- 补入正式地图点击进入新组合的原生窗口案例后，`tools/check.ps1 -Suite enemies -UI -UISuite enemies`：1285项规则通过（8.15秒）、73项窗口通过（9.86秒），记录 `build/checks/20260907T160513357-48276/`。已查看 `build/ui-weak-budget-group.png`：两只敌人分别显示生命与意图，无后台强度文字；漂浮锁窗口截图 `build/ui-floating-lock.png`。
- 初次新增测试曾持有原子提交前的旧字典引用，现改为提交后重新读取正式状态；“无可上锁目标”夹具的嘴部装备也明确上锁，避免错误排除合法锁目标。并行事件修改期间仅修正共享文件中的缩进编译问题，未借此改写事件功能。以上为相关分类验证，不宣称全项目全量回归。

### 2026-09-08 卡组一览卡牌墙

卡组一览改为1480×780宽屏面板和六列卡牌网格。每个永久卡牌uid各显示一张，默认按费用排序，可按名称／获得顺序排列，提供费用过滤、名称搜索、空结果提示、悬停放大及完整详情、右键翻面与Esc返回。使用现有CardFace和统一遮罩／关闭机制，无规则、数值或存档修改。

验证：tools/check.ps1 -UIOnly -UISuite interface，315项窗口断言通过，无引擎错误，记录build/checks/20260907T162348165-48356/。32牌测试检查重复实体牌、费用顺序、末行可滚达、搜索11张同名牌、费用冲突空态、恢复获得顺序与完整游戏快照不变。截图build/ui-deck-gallery.png、ui-deck-gallery-bottom.png及正常卡组ui-72-unified-drawer.png，已查看整体网格。

首次检查修正空搜索的字符串匹配；关联旧拖放案例不再固定姿态耗1费，而读取正式候选，双装备选择也不再依赖敌人的随机部位，改为明确同紧度手腕夹具。关闭后的正式攻击、姿态和卡牌拖放回归保留并通过。


### 2026-09-08 三档添加优先级与敌方链接施加

- 共用施加顺序收敛为空手腕、空嘴部／手指、其余全部合法追加三档。先按来源模板过滤，最高档随机选择；绳索初始／最终池含link_rope，链接固定第三档，真实两端不免费补装。候选、怪池资格、事件随机批量与警卫使用相同优先级；链接施加复用原工厂、公开准备、目标复核、存档和结果反馈。
- `tools/check.ps1 -Suite installation_priority,enemies,equipment,links,guard,events,persistence -Exhaustive -UI -UISuite enemies,intent`：5211项规则、92项窗口通过，44.45秒／12.06秒，记录 `build/checks/20260907T163700707-49372/`。截图 `build/ui-enemy-link-intent.png`。这份结果对应用户追加区域内链接规则之前的版本，后续链接扩展另记验证。
- 新测试最初误把手腕与手指当相邻，修正为真实手腕—手掌连接，不放宽生产规则。关联回归发现事件练习被旧目录测试当作休息流程，已按真实event声明验证；高安全监室升三档时新生成的可锁肩带漏锁，补齐生成后的锁状态，同一终局检查已通过。未运行全项目all。

### 2026-09-08 精准部位串联与截图缩减

- 同区域不同子部位可两两连接，跨区域仅连接相邻边界，股绳保留手腕／大腿根例外。链接不占普通容量，两件具体物理拘束之间最多一条；各方向上限为该区域对应方向剩余子部位数、至少1。复合组件按真实接触位置与物理ID共享额度，不按覆盖部位重复扩容，也不生成同一复合根的内部普通链接。
- 链接工厂、候选、敌方准备与目标复核、环境接触、部位显示、滑脱和存档共同读取contact_points。旧的仅有粗分区域的链接快照拒绝恢复，Demo不增迁移层。
- `tools/check.ps1 -Suite links,installation_priority -Exhaustive`：1138项关联规则通过，15.30秒，记录 `build/checks/20260907T164851760-49508/`；包括区域三角串联、双向额度、精确配对、复合组件、容量不变、非法操作回滚和存档拒绝。
- 最终 `tools/check.ps1 -Suite enemies,guard,persistence,rewards,environment_height -Exhaustive -UI -UISuite enemies,equipment_complete`：4520项规则、113项窗口通过，41.71秒／10.47秒，记录 `build/checks/20260907T165716733-46740/`。前次运行唯一失败是警卫夹具把小臂默认位置当作手腕相邻边界，现明确使用小臂中部；保留实际新增链接断言，未放宽规则。窗口继续验证真实操作与结果，本批未运行全项目all。
- 窗口默认跳过截图帧等待、图像读回、PNG写入及保存断言；只有 `-Screenshots <文件名>` 明确选择的画面才保存。本轮日志为 `UI SCREENSHOTS: none`，没有新截图，不把历史PNG当作本次视觉验收。README与项目工作约定已同步。

### 2026-09-08 清理内部流程文案

删除卡牌自由面的“不判失败”说明，魔法牌自由面不再弹施法成功率；翻面立即隐藏旧浮窗，不依赖浮起后鼠标是否仍落在卡框内。卡面注释、教程、练习描述、存档提示、姿态／移动提示、收押／终局说明与连续行动结束日志删除内部流程、实现状态及无意义的“不变”声明。费用、实际效果、失败消耗、条件与具体不可用原因保留；未改战斗或施法规则。

验证：tools/check.ps1 -UIOnly -UISuite casting,interface，317项窗口断言通过，无引擎错误，记录build/checks/20260907T165718286-49288/。既有付费牌成功率及失败原因可见，新增验证实际右键翻到自由面后浮窗消失，界面关闭后的正式交互仍通过。

关联规则门禁tools/check.ps1 -Suite casting,wall,prison,rewards在build/checks/20260907T165545400-31636/记录2579项，其中三项整局路线失败：ROUTE persistent enemy still requires legal real attack、ROUTE long run completes with one reward per fight east、ROUTE no repeat rewards or rooms including summit。没有将该门禁标记通过，也没有为本次文案清理修改战斗或路线规则。其余所选专项通过。

### 2026-09-08 手牌上限10张

Balance.HAND_LIMIT统一为10；正常回合、卡牌效果及遗物抽牌共用_draw的空位检查。9张抽4张只抽1张，满手不抽走牌、不重洗弃牌、不推进随机或抽牌序号；释放空位后可重新抽至10张。教程和满手日志同步。10张手牌存档可恢复，11张拒绝且原状态保持。

tools/check.ps1 -Suite rewards,persistence：2182项关联规则断言通过，无引擎错误，记录build/checks/20260907T172012331-18784/。

### 2026-09-08 资源飘字与遗物触发反馈

core/resource_feedback.gd记录成功事务中魔力、能量及四种准备资源的前后值，Game在扣费、事件记录和提交结束捕获；失败不返回反馈，临时记录不进入存档。遗物按稳定元数据标记来源，战后恢复按实际持有遗物逐件记录并保留原上限。ui/resource_feedback.gd独立于重建的layout，用约1.15秒缓慢飘字和显示值插值按序播放；魔力两处表与能量数值联动。刷新／奖励阶段保留队列，重开／主页清除，玩家实际资源与判定不等待动画。

tools/check.ps1 -Suite rewards -UI -UISuite rewards：825项关联规则及36项窗口检查通过，build/checks/20260907T172612098-46612/。新增案例：最后一敌1生命、60魔力火球击杀，收据严格保留60→50→60，实际进入奖励阶段，失败行动没有收据。随后加入刷新保留队列和主页清理，tools/check.ps1 -UIOnly -UISuite rewards -Screenshots ui-resource-feedback-spend.png：38项窗口检查通过，build/checks/20260907T172713961-33280/。已查看build/ui-resource-feedback-spend.png，人物头上魔力−10与左侧中间数值同时可见；动画结束回到60/100，完整游戏快照保持不变。

### 2026-09-08 当前能量即时显示

按用户修正从资源反馈字段移除energy，同时删除动画对EnergyValue的写入；当前能量只由正常render读取提交后数值。魔力、其他准备资源与遗物反馈保留。窗口新增验证：普通火球出手后能量立即为2，魔力动画仍在播放，能量不在待播或活动队列。


### 2026-09-08 一团绳死亡分裂与练习

- `rope_mass`作为强怪个体加入运行库、图鉴及首页独立练习。暂定48生命、后台强度3，准备→中级2档绳索类施加→同类加固循环，链接沿共享候选和安装工厂。强怪池仍未组合，预算4仅预留。
- 击败分支取消原计划，以共用敌人实例工厂生成两只完整生命的现有rope；来源与出现回合保存，新实例本回合不行动、下回合按原弱怪行为行动。死亡分裂与只击败一个子体均不提前发奖，全部敌人离场才结算一次。没有增加半血判定；按用户要求移除半血反例测试，保留实际死亡、重复提交、存档、先后手衔接与奖励风险案例。
- `tools/check.ps1 -Suite enemies,persistence,rewards -Exhaustive -UI -UISuite enemies`：4238项关联规则、76项窗口断言通过，30.66秒／8.85秒，记录 `build/checks/20260908T024149991-31272/`。窗口从真实练习菜单进入、攻击击败本体、检查两只新敌人的候选及分裂结果。默认 `UI SCREENSHOTS: none`；没有截图，也未运行全项目all。
- 首次联合检查发现新增分裂词条缺少教程标题映射，已补齐共享教程名称后完成上述门禁。规则与存档相关检查保留原子拒绝和随机复现；本次没有新建战斗流程、专用攻击接口或第二套装备生成器。


### 2026-09-08 无效与重复测试审计

- 扫描规则／窗口测试中的已删除机制、静态目录断言、重复场景及图像读回，并与实际行为入口核对；只清理确认多余的案例，不将所有否定断言视为无用。
- 一团绳：删除人为调用其不会生成的leave动作再检查不分裂的案例，删除预留强池常量与空池的重复断言。实际死亡分裂、重复提交、分裂来源／回合存档、先后手衔接和单次奖励保留。
- 警卫：删除把stage从1改到12、反复确认已删除蓄力／抢先／压力行为不存在的循环；Guard.build实际不读取stage。删除对应旧第三阶段投影及隐藏文案检查。普通计划打断／恢复仍由正式动作验证；未知敌方行动的存档拒绝归入persistence现有损坏输入矩阵，不再绑定已删除guard_charge名。
- 目录与重复运行：删除固定弱怪名单／退休ID存在性检查、固定八卡六遗物计数。奖励采样仍检查每个当前配置奖励均实际抽到；修改怪池返回副本仍检查注册表不变。空强池已有library_cases的真实地图检查，删除mouth_cases另造多张地图的重复段及未再使用的empty_strong_pool种子组；其他随机样本数量不变。
- 监狱：删除已废弃终局框架工厂的否定案例，以及Demo不要求的旧终局档缺字段兼容案例；当前真实终局装备、容量、完整记录及损坏记录拒绝保留。
- 窗口：删除人物像素计数与地图单点颜色阈值检查，不再在默认窗口流程读取整张画面。实际纹理加载、透明通道、等比布局、落地线、地图命中区域、拖动与真实导航保留。完整画面读回现在仅在明确选择的capture路径执行。
- 验证：`tools/check.ps1 -Suite enemies,guard,intent,rewards,persistence,prison,runner -UI -UISuite hero_art,route`通过3382项关联规则与100项窗口断言，33.10秒／8.06秒；记录`build/checks/20260908T025157394-1156/`，窗口`UI SCREENSHOTS: none`。本批只改测试与说明，未改游戏规则；没有全项目回归，也不把不同分类／采样范围的耗时当作前后提速对比。

### 2026-09-08 环境真实加成与三类伤害公式

粗糙墙面从基础属性乘区移到伤害结尾，预览分别保存scaled_damage和environment_true；卡牌说明分列原类型伤害与墙面真实伤害，Game._formula用于候选及日志。普通滑脱三档免疫时原伤害为0，但保留满足条件的墙面2点；完全不可损伤和方法阻挡不开放。切割及被动滑脱不加墙面伤害。状态不再把墙面加进力量／灵巧，环境说明、教程与规则书同步。

新增案例覆盖双件堆叠且上锁时差值恒为2、魔法滑脱乘区、三档普通滑脱正式出牌10→8、躺姿／离墙／被动无加成、无挣扎路线目标仍0、切割固定值不追加墙面。旧状态预期改为人物基础属性；旧抽牌三档免疫案例明确普通墙面，避免依赖现已能造成真实伤害的粗糙墙面。

tools/check.ps1 -Suite wall,hand_assist,slip_motion,installed_tools,rewards -UI -UISuite wall,hand_assist,slip_motion：2775项关联规则、69项窗口断言通过，无引擎错误；记录build/checks/20260908T031644221-25812/。本次为daily关联种子采样，非全种子穷举。


### 2026-09-08 一堆绳六次行动、来源效果与半血分裂

- 新增rope_heap正式精英遭遇、独立练习、代码绘制轮廓与图鉴。回合开始增生读取存活来源，在抽牌前施加；成组施加／加固使用既有具体位置、容量、来源池和工厂。公开目标保存，失效目标才替换。第六次操作全身添加只使用普通绳索／细绳，随后按最大生命一半分裂。
- 共享父子生成入口支持继承生命；受击后先判断死亡，再对配置了阈值的敌人判断半血。取消未执行计划与持续来源，新子体本回合不行动。既有rope_mass死亡分裂不变，全部子体离场只发一次奖励。保存校验覆盖分裂基数与实际子体上限。
- 新案例覆盖来源生效时点与消失、公开两处目标不重复、目标解除后的替换、加固不足的补位、1档直接升3档、49点未触发／48点触发、47点子体向上取整、直接击杀跳过分裂、第六次完整正式回合路线、全身施加不生成链接、子体行动时机、后续死亡分裂与单次奖励、存档继续和损坏继承上限原子拒绝。循环场景沿用enemy_cycle的16个种子，不增加重复随机域。
- 验证命令：`tools/check.ps1 -Suite enemies,status,persistence,tower -Exhaustive -UI -UISuite enemies`。6393项关联规则与82项窗口断言通过，无引擎错误；规则44.69秒，窗口9.05秒。记录`build/checks/20260908T033256238-3796/`。完成enemy_cycle 16、enemy_pool 24、tower_graph 201个既有样本；未运行全项目all。窗口从正式练习菜单进入、结束回合、攻击分裂并核对真实目标与状态，`UI SCREENSHOTS: none`。
- 首轮检查修正图鉴格式串的百分号转义，以及加固夹具误用默认皮带的问题。关联链接检查仍把整段伤害乘1.25且假定三档最终伤害为0，与本日已完成的粗糙墙面真实加成变更冲突；调整其断言为乘区伤害×1.25＋不变的环境加成，三档只检查乘区免疫，未修改游戏伤害规则。

- 最后复核小数生命：大子体完整继承47.5，小子体各向上取整为24；保存校验使用相同规则。`tools/check.ps1 -Suite enemies,persistence -Exhaustive`再次通过4305项关联规则，无引擎错误，37.39秒，记录`build/checks/20260908T033752874-12464/`。这是生命数值边界修正，未重复已通过的窗口与塔路检查。


### 2026-09-08 一团／一堆皮带变体与分组权重

- 从一团绳／一堆绳配置派生皮带变体，保留全部生命、强度、行动、分裂时机与继承计算；只替换材质池、名称、轮廓和同材质子体。图鉴、准备意图、增生状态及行动日志改为读取实际材质，练习入口共用循环注册。
- 新增mass_family／heap_family遭遇组，通过variants声明二选一。精英池只保留guard_solo与heap_family两个条目；修复Tower.generate把精英固定写成列表第一项的实际出场错误。进入组遭遇时仅抽一次材质并写回原room_encounters，之后显示与恢复不再选皮肤；强怪组已登记但仍不加入待定的强怪组合池。
- 验证复用已有enemy_pool 24个种子，检查两种组内皮肤均实际生成、每次仅一次encounter随机消耗、查看不修改状态；tower_graph 201种子检查真实精英房可生成警卫及一堆X，原相邻层、禁止连续精英等约束继续通过。定向案例验证皮带准备施加、增生、完整六次行动、自动分裂、47.5生命继承、后续子体死亡分裂和存档；没有再复制绳索版全部阈值测试。
- `tools/check.ps1 -Suite enemies,tower,persistence,status -Exhaustive -UI -UISuite enemies`：6537项关联规则与90项窗口断言通过，无引擎错误，52.62秒／9.77秒。记录`build/checks/20260908T035052000-1236/`。窗口从真实练习菜单进入皮带变体并操作结束回合、击败与子怪生成，截图默认关闭，未运行全项目all。

### 2026-09-08 负面效果意图图标

怪物负面效果预告改为紫色旋涡与金色星点组成的眩晕图标，悬停／键盘聚焦使用统一信息浮窗，正文固定“敌人将要对你施加某种负面效果”。IntentView统一识别已存在的负面效果字段和嵌套operations；预告不再投影其原文、数值与次数。普通与警卫均读取同一debuff行，其他意图保持原入口，实际结算与状态栏未改动。

tools/check.ps1 -Suite intent -UI -UISuite intent -Screenshots ui-debuff-intent.png：12项规则、18项窗口断言通过，无引擎错误；记录build/checks/20260908T040033203-30924/。覆盖只读显示、原文不泄露、组合行动单图标、实际悬停文案、蒙眼关闭图标与旧浮窗、普通无负面效果时无图标。截图build/ui-debuff-intent.png。


### 2026-09-08 离场清位与连续缩放

仅修改战场渲染：过滤gone实例后按存活数量重新排列，4只起使用3/数量比例缩放整组信息和命中区域；统一底部对齐。名称选择改为查找组内控件，伤害飘字把缩放后的目标坐标转换到布局坐标。未删除敌人状态或改动分裂、继承、行动与奖励规则。

沿既有enemies窗口案例实际攻击一堆绳分裂，再击败一团绳产生四只敌人，验证两个旧本体均无显示槽和目标。用正式实例工厂补入视觉夹具，检查4／5／6／7只逐步缩小、目标互不重叠且不越视口、名称保留、可正确选择末尾目标和渲染不改状态。复用targeting窗口覆盖原点击／拖放路线。

`tools/check.ps1 -UIOnly -UISuite enemies,targeting`通过168项窗口断言，无引擎错误，11.48秒；记录`build/checks/20260908T040214941-24212/`。无规则改动，未重复规则全量；未截图。

2026-09-08 持续增生意图漏接修复：rope_heap／belt_heap 的 turn_install 接入通用 debuff 图标，隐藏增生预告详情，保留生效后状态栏详情和普通施加意图。intent 定向检查通过18项规则、21项UI（含真实一堆绳练习悬停）；日志 build/checks/20260908T040545279-41608。

2026-09-08 怪物意图全图标：删除普通怪／警卫常驻文字框，统一IntentView.icons分类合并与intent_icon绘制，撤下debuff专用控件。拘束、负面效果、原地行动、加固、锁、收押、离场及特性图标共用悬停接口。20项规则、166项UI检查通过（intent/enemies）；检查目录20260908T040928700-24368，目视复核一堆绳及双警卫两张截图。行动资格、费用、执行与状态效果不变。

2026-09-08 蓄力悬停精简为单句‘敌人正在蓄力’，空标题不渲染；真实一团绳练习悬停断言全文并验证状态不变。intent通过20项规则、27项UI；build/checks/20260908T041353143-16452。

2026-09-08 全部意图悬停精简：统一短句注册表，去掉原始意图文字、术语正文、目标与重复标题拼接，同类合并不再追加段落。覆盖全部18种意图映射及真实悬停、蒙眼、状态不变；38项规则、27项UI通过，build/checks/20260908T041507525-1768。

2026-09-08 意图接口去冗余：删除旧行投影、长文拼接、public_plan和重复递归has_debuff；直接从真实行动生成去重图标，保留隐藏／离场／打断／新子体／分裂／时限。game_view移除旧intent/status/intent_rows输出，墙面投影只计算一次。相关旧测试改查图标和实际状态，教程术语保留。发现并修复存档测试辅助函数将正式Game恢复成固定位置夹具的问题，现保持输入脚本类型。定向规则3355项通过（build/checks/20260908T042256588-43924）；意图／敌人／压力UI207项通过（build/checks/20260908T042225099-30852）。无布局变动，未截图。


### 2026-09-08 强怪组合入场抽取

新增mass_weak与four_weak两个强池条目，复用原弱怪预算抽取器（预算1／4）、家族材质二选一及敌人实例工厂。组合在实际入场时选择，排除last_strong_group后冻结；恢复同时校验成员预算和指定家族，不能用同强度的错误组合替换。图鉴来源与普通房间说明同步更新。

定向样本检查两组、两种一团材质、七类弱怪与同种重复实际可达；验证前三次普通战斗阈值、组合不连续、装备资格过滤、只读预览、保存后经过休息的下一组一致，以及缺成员／错组合／坏历史的原子拒绝。初跑续抽案例误用了固定距墙的测试夹具，修正为正式Game恢复后复测通过；未修改正式距墙逻辑。

`tools/check.ps1 -Suite enemies,tower,persistence -Exhaustive -UI -UISuite enemies,route`通过6707项关联规则、227项窗口断言，无引擎错误；35.35秒／12.97秒。记录`build/checks/20260908T042345240-1212/`。窗口复用现有地图进入、怪物行动、分裂与多人缩放验证；未新增截图、未运行全项目all。

2026-09-08 悬停框宽度自适应：移除固定面板宽度，按标题／正文最长行的实际字体宽度决定内容宽，最大326后换行，保留内边距与屏幕边界定位。短句／长文／真实悬停UI29项通过（20260908T063221417-31116），已查看ui-intent-fit.png确认短句无大片空白。

2026-09-08 铜锁状态图：增加共用矢量铜锁控件，按真实locked切换开闭环；普通卡面与事件装备选择接入，移除lock_text及摘要锁状态文字，新增lockable只读资格。2334项规则、131项装备／事件UI通过；闭锁截图已复核，开闭状态有控件断言。规则日志20260908T065153658-8568，最终UI日志20260908T065332348-16500。

2026-09-08 铜锁三态补齐：不可上锁显示铜锁叠红X，装备卡和事件展示统一接线。真实链接绳验证不可上锁图标，装备／事件UI133项通过；已复核ui-equipment-lock-cross.png，日志20260908T065512453-18896。

### 2026-09-08 人形强怪奴隶贩子

- 新增生命40、后台强度2的人形强怪“被魔法控制的奴隶贩子”，进入图鉴与`trader_solo`固定练习，未加入第一幕弱／强／精英／塔顶池。使用现有敌人实例、行动阶段、施加、替换和警卫收押入口，没有新增第二套安装或入狱流程。
- 正式序列为1／2／3／4开场，再重复1／3／4两轮，第11次实际行动收押。无力化持续一个玩家行动回合，禁用普通体术、强力体术与踢击，火球及卡牌魔法继续按原施法条件判断。准备就绪保存在敌人实例，可叠层；每件成功施加或替换消耗一层并把实际紧度固定为3档，失败或打断不消耗。动作3先使用旧层，再获得新层。
- 施加范围使用显式普通模板白名单，布带眼罩、链接绳、复合装备及特殊装备不进入。动作4优先中级马具口球、皮革眼罩或胶带眼罩，两处无解才在同一中级普通白名单内改选。所有未指定目标都在出手时选择，容量已满时只凭人形权限调用现有替换事务。
- `tools/check.ps1 -Suite trader -Exhaustive -UI -UISuite trader,enemies,intent,status`通过67项规则与283项窗口断言，记录`build/checks/20260908T095315890-42684/`。随后运行关联门禁`tools/check.ps1 -Suite application,replacement,guard,casting,status,persistence,content,enemies,intent -Exhaustive -UI -UISuite trader,enemies,intent,status`，6283项规则与283项窗口断言通过，无引擎错误，记录`build/checks/20260908T095413690-43436/`。本批无截图，也未运行全项目`all`。

2026-09-08 火球术悬停成功率：固定魔法攻击按自身施法配置投影概率，按钮共用自适应短句提示。真实悬停验证正常／0%失效状态、状态不变。casting规则1724项、UI14项通过；build/checks/20260908T100422987-29816。

2026-09-08 一键解除入口：部位按有效整件manual候选高亮，装备二级卡直接显示一键解除按钮及费用，复用原事务。实际口球用例验证高亮、直接可见、上锁／零能量禁用、真实点击移除并扣1能量、解除后撤销高亮。414项规则、60项装备UI通过；ui-quick-release.png已复核，日志20260908T101106828-11404。

2026-09-08 卡牌动画：新增瞬时card_feedback顺序记录与持久CardMotion表现层，共用卡面；初始／普通抽牌飞入、出牌先抬起再归堆、弃牌飞向弃牌堆、消耗缩小暖色淡出、洗牌三张牌背回流、保留闪光、剩余手牌补位。记录不保存；无动画专用游戏状态／命令。规则覆盖同UID弃后重抽、顺序、真实张数、失败无回放、消耗和保留；UI覆盖实际结束回合、消耗牌真实点击、跨render、完成后状态不变、重开清理与拖牌。1800项规则通过（20260908T102041581-21528），73项rewards/targeting UI通过（20260908T102136977-34784）。已查看ui-card-transfers.png。

2026-09-08 抽牌逐张落位修正：待到达手牌隐藏，抽牌堆逐张飞出，落位才显示可操作卡；重绘不提前露牌，后续动画保留未完成抽牌。新增初始全隐藏／重绘／部分已到达／全部到达及状态不变断言。rewards/targeting UI78项通过（20260908T102428663-14512），ui-sequential-deal.png已复核。

2026-09-08 基础攻击双形态：肘击／近身短打新数值与逐击，双臂共系数、双腿资格、横扫全体且无冷却；右键无状态变更，禁用时可切换，拖放携带form。补充basic_attack_cases归core与basic_attacks UI。core/enemies扩展种子检查4081项通过（20260908T104531844-34408）；basic_attacks/targeting/guard UI85项通过（20260908T104514398-34088），最后按钮字号调整后basic_attacks UI17项通过（20260908T104705315-29836），截图已复核。日常种子首次检查中另一个任务的TIMING双分支覆盖断言失败，本次未改其生成器或采样，扩展16种子覆盖通过。

### 2026-09-08：主角可添加／加固空间耗尽时结束战斗
- 用户最终口径：主角身上必须仍有当前场上存活敌人能合法添加内容物的位置或能继续加固的拘束具，战斗才继续。当前意图不作判断依据。
- Application.can_apply与choose共用_choice_bands；EnemyPlans.application_spec共用实际数量、准备层数与替换权限，can_affect_equipment检查来源安装、加固和上锁能力。Game在行动完成、入场、回合边界统一复核，空间耗尽按非击败离场结算一次奖励；清除持续施加层数，保留装备。快照修订号5，无旧档适配。
- tests/battle_saturation_cases.gd纳入core，覆盖无随机副作用、仅加固继续、满位结束、锁来源权限、多敌／已离场来源、拒绝命令不结算、入场与一次奖励。旧敌人循环案例同步最新结束规则；enemies窗口增加锁完最后目标后实际领奖场景。
- 已通过：core,enemies完整随机矩阵4130项规则及enemies窗口157项，日志build/checks/20260908T111654874-34600。检查期间其余任务开始修改data/enemies.gd及first_floor_enemy_pools.gd，后续guard,persistence扩展运行受新怪物／遭遇池与旧断言未同步影响，并遇既有daily随机样本覆盖不足；该扩展运行整体失败，不记为绿色。其guard117、persistence386、prison242项本身无失败，完整失败记录build/checks/20260908T111815008-42024。
- 警卫窗口补验：首次运行达到180秒上限（build/checks/20260908T112011433-26556），增大运行上限后实际42.05秒完成，43项通过（build/checks/20260908T112334248-31944）；没有跳过收押或改变测试断言。敌人和警卫窗口合计200项通过。并行任务已开始接入新增怪物的weighted_moves与本次结束判定，综合怪池回归仍以其收尾记录为准。
## 2026-09-08：杂乱拘束具、材质归类与双池出场

已接入42生命、后台强度2的`mixed_bundle`：首招散缚，之后按25／30／45权重及连续次数上限选择散缚、翻卷收紧、躁动膨胀。实际执行后记录动作历史，打断保留原招；狂躁永久增加施加数量，翻卷在施加后共用原加固入口。普通绳索、细绳和链接绳保留物理模板，在普通施加合法优先带内共用材质抽取权重，再选位置和款式。

弱怪预算2可抽到单只，强池新增`mixed_pair`两只组合；原`four_weak`明确限制单体强度1，`mass_weak`仍为3＋1。两种练习、独立目标、美术轮廓、狂躁状态与图鉴来源同步。内容包弱怪强度允许1或2；新加权行为只走内置配置，没有额外开放JSON行为编辑接口。快照修订号6，同版本保存动作历史、加成及固定成员，旧版不迁移。

先以`-ListOnly`查看相关范围，再执行`tools/check.ps1 -Suite application,enemies,tower,persistence,content -Exhaustive -UI -UISuite enemies,intent -TimeoutSeconds 240`。最终规则7709项通过，113.15秒；窗口191项通过，约65.42秒。完整随机样本：enemy_cycle 16/16、enemy_pool 24/24、tower_graph 201/201。日志位于`build/checks/20260908T113748293-11680/`。交叉分类由现有注册表合并，包含同期加入的basic_attacks与battle_saturation；未运行all，无截图。

中途失败已处理：旧地图案例将弱池预算2写死为两只，改为实际强度；新增混合敌人的数量案例把加固3档产生的附属肩部件当成新施加整件，改为统计装备根。保留实际动作、费用、状态、随机稳定与存档检查，没有修改游戏规则迎合旧断言。

## 2026-09-08：人形强怪多面手与性玩具随机池

新增44生命、后台强度2的人形强怪`versatile`。第1次行动发呆，此后循环“安装一件初级2档性玩具→控制拘束具”：形成控制意图时在当前可成立的随机上锁一件与随机加固至多两件到3档之间等概率选择；只有一类可成立时直接选择，两类都不成立时改为安装性玩具。控制分支形成后保持不变，具体目标在出手时随机选择；打断和同版本读档保留已公开分支，目标随后消失时按现有行动规则落空。

`SpecialEquipment.RANDOM_POOLS`成为敌人共用的明确随机表。初级池排除全部飞机杯和外置震动棒；中级池加入中级外置震动棒，仍排除全部飞机杯。多面手与漂浮玩具箱读取同一初级池，明确指定装备的事件和练习仍可使用池外成品。多面手进入强怪分类、图鉴、代码绘制人形轮廓和独立练习；当前没有用户指定的强怪组合，因此未加入第一幕随机强怪池。快照修订号升至7，不迁移旧档。

先以`tools/check.ps1 -Suite enemies,special_equipment,content,persistence -Exhaustive -UI -UISuite enemies,intent,special_equipment -ListOnly`确认分类范围。日常敌人抽样在`build/checks/20260908T120854523-31836/`通过2155项规则；四个日常种子继续覆盖既有材质、施加档位和多面手控制分支。最终`tools/check.ps1 -Suite enemies,special_equipment,content,persistence -Exhaustive -TimeoutSeconds 240`通过6140项关联规则，完整执行enemy_cycle 16/16及enemy_pool 24/24，日志`build/checks/20260908T121333584-12508/check-rules.log`。`tools/check.ps1 -UIOnly -UISuite enemies,intent,special_equipment -TimeoutSeconds 180`通过243项窗口断言，日志`build/checks/20260908T121538951-15488/check-ui.log`。没有运行全项目`all`，也没有生成截图。

## 2026-09-08：警卫更名与现行行动核对

原精英警卫更名为魅魔警卫，敌人名称、单／双人练习、塔顶名称、地图提示、收押后重试、反抗入口与教程相关名称同步；图鉴和行动日志沿原敌人名称读取。内部guard及遭遇ID、70生命、行动概率、装备池、收押时机和存档结构保持原值。本批尚未进行行动重设。

docs/game-design.md第8.2节根据现行Guard、EnemyPlans及装备执行代码重新整理：普通操作次数与类别在预告时确定，目标在出手时选择；失去目标时空过，不保留旧文档中“临时补施加／预先指定具体目标”的描述。普通与复合池各半、中级2档、逐档加固及第11回合准备／第12回合收押均由现行代码核对。

先以-ListOnly确认范围，再执行tools/check.ps1 -UIOnly -UISuite guard,tower_progression -TimeoutSeconds 240：87项窗口检查通过，包含43项警卫与44项塔顶流程；无截图。日志build/checks/20260908T122539793-34732/check-ui.log。只调整原有文字断言，不新增镜像测试、不重复规则全量。

## 2026-09-09：魅魔警卫捕缚重制

本批以独立`guard_bind`状态替换旧十回合／双区域满级收押条件。魅魔警卫开场固定施加手腕、口部和脚踝三件中级2档装备，准备一回合后建立50/100捕缚；之后循环双普通施加、捕缚＋10、复合施加。复合方案在出手时再次复核，无法安装或替换便改为至多两次3档加固。捕缚降到0后立即把仍存活警卫的下一步切到重新准备；达到100后立即把下一次敌方行动切到收押，不先执行旧循环意图。双警卫共享一条不可叠加进度。

`RuleChangePackage`覆盖如下：

- 状态与数值：新增独立捕缚进度0—100、初始50、固定推进10、敌人`bind_ready/cycle_step`；捕缚期间上身严密度最低1。敌人生命、战后奖励、入狱安全等级和监狱追加装备数值未改。
- 候选与事务：所有真实挣扎／滑脱伤害牌增加捕缚目标，牌面基础、属性和蓄力全额结算；仅剩眼罩／口球时×2，环境固定加成明确为0。姿态只允许躺→坐→站，每次成功切换＋10；成功消耗能量的行动在同一正式提交中随机刺激一个特殊部位。魔法牌仍先结算原成功率，失败照常支付且不造成捕缚伤害。
- 回合与固定点：捕缚增减、高潮及动作支付后统一复核警卫下一意图；开场冻结计划和打断标记不被状态同步重建。每次高潮使捕缚＋10，达到100只安排下一次警卫行动，不在当前事务中直接入狱。
- 事件、界面与文案：新增捕缚施加、推进、受击、解除及随机刺激的结构化日志；玩家立绘下方、魔力条下方显示可拖放的独立粉红进度条，状态栏说明限制。练习、教程书、敌人图鉴、意图短句、即时反馈与两份设计文档同步；删除旧收押时限、旧准备收押和旧警卫蓄力的可见术语／图标入口。
- 存档、迁移与随机：快照修订号升至8，校验捕缚来源、范围、警卫阶段和独立`capture_bind`随机域；按Demo约定不迁移旧版本存档。
- 交互轴：覆盖单／双警卫、先后手、打断、普通／复合／特殊装备、空位与替换、卡牌连续段、普通与魔法滑脱、能量支付、快感倍率与高潮、姿态、环境隔离、战斗胜负／入狱、保存恢复、教程／图鉴／日志。墙距、探索、商店、遗物、牌堆构成和敌人出场池没有规则变化。

最终关联门禁：`tools/check.ps1 -Import -Suite guard,pressure,status,casting,encyclopedia -TimeoutSeconds 300`通过导入及3968项规则断言，日志`build/checks/20260908T141329334-45348/`；`tools/check.ps1 -UIOnly -UISuite guard,status,interface -TimeoutSeconds 240`通过369项窗口断言，日志`build/checks/20260908T141509758-30508/`。移动即时反馈框后再以真实卡牌拖放重验guard窗口21项并生成`build/ui-35-guard-bind.png`，日志`build/checks/20260908T141932867-31364/`。未运行全项目`all`。

清理最后一个旧警卫蓄力校验分支后，`tools/check.ps1 -Import -Suite guard -TimeoutSeconds 240`再次通过导入及918项关联断言，日志`build/checks/20260908T142315503-11744/`。

### 2026-09-09：一次性药剂／卷轴与战后道具池
- 已实现：魔力、活力、蓄势药剂；应变、节魔、定咒卷轴。物品定义共用FieldTools注册表，6件均1次，原小石片3次／锯条2次保持。8件独立战后池等权；开锁针／折返符不混入。
- 掉率依据：https://slaythespire.wiki.gg/wiki/Potions （Slay the Spire 1，2026-09-09核对）。40%起，掉落－10个百分点，未掉落＋10个百分点，0—100%；独立item_drop随机域。战斗结束事务唯一抽取并收入道具栏，奖励页显示，满容量不丢失且继续使用原整备整理；保存概率、随机进度与本次结果，不适配旧档。当前仅第一幕，新局初始化；未来新增幕时需显式重置，逃狱重建不是换幕。
- 规则验证：tests/consumable_cases.gd覆盖全部6件效果、嘴部减半与4/5取整边界、自由脚趾使用、双手／双脚趾受限拒绝、10张手牌截断及动画回执、实际施法付费／定咒只消费一次、定咒保存与战后清除、0/100概率边界、重复结束和预览不重抽、超量仍获道具、跳过牌奖励仍保留、64种子覆盖8种掉落及损坏概率原子拒绝。纳入consumables交叉分类，与casting/rewards/persistence/guard共同运行完整随机矩阵，7037项通过：build/checks/20260908T143238031-38704。
- 初次回归发现3项旧路线／牢房夹具只整理固定数量物品，新掉落后仍超量；已改为通过正式item_discard和finish_pack完整整理，未删除容量门禁或跳过正式行动。
- 窗口验证：consumables,rewards 58项通过（build/checks/20260908T143219316-22020）；最后统一“定咒”到增益分类并补真实过滤入口，status,consumables 41项通过（build/checks/20260908T143534862-36988）。检查实际直接使用、消耗与恢复、禁用原因、增益显示、奖励页道具名及原卡牌／资源动画。截图build/ui-consumable-items.png和build/ui-item-drop-reward.png已目视核对；未进行全项目all回归。
- 同批文案：更新动态道具效果／资格／类别、定咒状态与施法预览、掉落日志和奖励页、通用道具自言自语；规则书第6.2节、内容模板F1及AGENTS同步。现有商城／休息专用供应池未增加新物品，未擅自制定价格。

### 2026-09-09：装备详情显示徒手解除不可用原因
- 修复ui/main.gd装备小卡片将所有invalid徒手候选隐藏的问题。有效一键解除保持卡面直接入口；详情显示其余正式候选和具体禁用原因，不在UI自行判断或放宽套体、外层、锁、触及及费用规则。
- equipment_complete窗口新增双单腿套叠穿案例：最外膝上带允许一键且大腿高亮、内层带显示外层覆盖、零能量显示缺1能量、已锁目标显示先开锁。65项窗口断言通过，build/checks/20260908T144656252-40552。
- 第一次窗口运行遇到另一并行修改中的equipment_application.gd局部变量result未定义；该文件随后由原修改任务修正，本批未改其施加规则。重跑无引擎错误。
- 只读核对当时practice存档：prison、3能量、双臂等级2、手腕受限；各单腿套外带实际徒手原因均为手腕未自由。存档时间不保证对应用户截图时刻，不据此覆盖截图描述。

## 2026-09-09：巡视补装、外层替换与逐次登记

违规检查以本次基准清单缺失N个真实普通装备／组件／链接编号为依据，名额N＋2，中级三档普通件。先正常补空位，满位明确授权Application／Replacement处理外层；使用处罚前等级、紧度、锁和链接代价，复合必须凑齐同时覆盖的完整强度方案。完成补装后收紧原有幸存装备、没收道具并恢复消耗牌。每次完整检查，包括无违规，都按最终实际目标重建基准并显示记录件数；旧缺失、替换移除和新附带结构不会循环增加当前名额。特殊部位装备本批不接入。

复用既有施加和替换入口，在同一批次保护已安装对象，防止满位重复替换新件、虚报数量。比较值仍由Replacement单点维护，覆盖组合先用必要强度下界过滤显然不可能的候选，完整链接和原子安装继续交由原替换预演复核。无新增玩家命令、规则模块或长期保护状态。检查报告和结构化事件包含缺失、计划、实际、替下、丢失链接、没收、消耗牌恢复和重新登记数；教程、两份规则说明、README与AGENTS已同步。快照修订号按新检查规则更新，不迁移旧档。

规则案例沿prison、application原分类补充：N＋2与安全等级解耦、实装中级三档、检查结果保存／恢复一致、跨检查不累计旧损失、满位只替换一次、不足覆盖保留复合、完整覆盖整组替换、肩带损失强度比较、附带结构和基准更新。窗口沿原prison入口真实点击检查与接受，核对新计划数、实际数和重新登记文案；不额外创建截图测试。

最终先以ListOnly确认范围，执行tools/check.ps1 -Suite prison,application,replacement,persistence -TimeoutSeconds 240，23个相关规则模块共3801项通过，110.11秒。日志：build/checks/20260908T145601738-46092/check-rules.log。使用现有日常随机样本enemy_cycle 4/16、enemy_pool 4/24，未运行all或完整随机矩阵。窗口tools/check.ps1 -UIOnly -UISuite prison -TimeoutSeconds 180通过98项，日志：build/checks/20260908T145311038-46200/check-ui.log；没有生成截图。窗口检查后仅补充共享比较值的必要下界过滤和后续检查计数案例，最终规则覆盖这些收尾变更。

首次关联回归中，监狱及替换规则均通过，旧塔顶路线案例因警卫更名后仍匹配“双警卫”、随机掉落后只丢固定一件物品而失败。已将前者对齐现有“双魅魔警卫”文案，后者通过正式放弃道具动作整理至实际容量以内；未改路线、掉落或容量规则。最终tower_progression分类123项通过。

## 2026-09-09：警戒度控制入狱与巡视装备规格

入狱追加、独立配额链接及巡视补装共同读取`PRISON_SECURITY`：1级初级二档、2级中级二档、3级中级三档、4级高级二档、5级高级三档。3级起显式声明定制复合池；单件／整套各计一个新装名额，真实组件仍逐件登记。普通和复合先查合法空位，均无空位才在获授权的巡视处罚中尝试替换；同一阶段两池都有合法方案时各占一半。工厂继续控制等级、容量、结构、初始肩带紧度及真实链接。原装备处罚收紧在补装之后，新件保持当前规格。

复用Application的来源声明和批次保护，删除Guard旧install_options、pick_install、add_intake_equipment抽装路径。Prison只组合声明与显示文本，UI读取投影；无新玩家命令、安装工厂、持久化池或兼容迁移。收押界面、巡视报告、状态栏和数据生成的教程表同步，快照只支持新修订。警卫战斗的原意图规格、特殊部位装备和第五级终局规则不改。

案例沿原application、prison、shoulder和窗口分类补充或调整：五档实际入狱等级／紧度与附件例外、1—2级禁用复合、3—4级真实巡视补装、混合池可达、跨池先填空位、不可用池退回合法池、新装整套计数与批次保护、组件清单刷新、只读投影、同版本读档随机复现。新混合池用例最初误用两个不能共存的单手套，已改为合法的手套与腿套组合；没有放宽实际装备规则。另修正旧压力练习在战后随机道具超过容量时未先整理的测试步骤，使用正式放弃道具操作，不修改掉落或容量。

先ListOnly确认范围，执行`tools/check.ps1 -Suite prison,application,guard,pressure,status,persistence -TimeoutSeconds 300`：29个相关模块、4413项全部通过，用时90.94秒。日志：`build/checks/20260908T152306164-5972/check-rules.log`。使用现有日常随机样本，不运行all，不增加截图。

窗口执行`tools/check.ps1 -UIOnly -UISuite prison,guard -TimeoutSeconds 240`，123项通过；日志：`build/checks/20260908T152948476-2104/check-ui.log`。核对真实收押、各级追加规格文字、检查计划／实际／重新登记、卡牌开门、道具逃离和第五级终局。首轮旧成功用例只解除嘴部而未明确保证手指手势，随机入狱的新装备分布使其条件不足；已将开门／折返符成功夹具明确准备为所需手指自由，保留真实抽牌、点击与提交，实际使用资格未改变。最后仅调整此窗口夹具和文档，规则实现保持4413项通过时版本。

## 2026-09-09：魅魔事件立绘

仅新增事件只读id、显示映射和原图资源；不改候选、随机、费用或存档。事件窗口测试补充非目标事件保持占位、目标事件使用指定原图和等比显示，既有布局、选择器、真实选择、结果页和过期版本测试继续执行。先ListOnly确认范围，执行 tools/check.ps1 -UIOnly -UISuite events -Import -Screenshots ui-event-portrait.png，83项通过；日志 build/checks/20260908T150707928-29956/check-ui.log。已人工查看 build/ui-event-portrait.png，立绘完整且未遮挡文字和选项。

关联规则分类先ListOnly后执行 tools/check.ps1 -Suite events，1139项中1137项通过。两项失败为 tests/event_cases.gd:21 对 ominous_circle、small_circle 的行为注册检查：现有数据使用 sequence，断言白名单未包含该行为，与此次立绘及id投影无关，未修改该并行工作。日志 build/checks/20260908T150740529-46304/check-rules.log。未运行全项目all。

## 2026-09-09：入狱性玩具清单与巡视充电

每次真实收押在普通拘束具与链接之后，另通过现有`Application`请求安装2件当前警戒度等级的性玩具，并保存实际新增编号及完整特殊装备基准。监狱池与敌人／事件通用池分开：常规种类保留同等级股绳，警戒度3级起加入同等级飞机杯；多面手与漂浮玩具箱的原名单不变。特殊装备继续遵守既有精准容量、同族唯一、复合占位、品质比较和替换事务，没有新增监狱专用实例工厂或绕过容量的安装接口。

巡视分别比较普通清单与性玩具清单。普通缺N件仍补N＋2件并在补装后收紧幸存原件；性玩具缺N件补N＋1件。任一类缺失都会没收全部道具，两份清单都齐全时仍只没收已安装工具。每次接受完整检查，无论是否缺件，最后都把所有`duration>0`的在身特殊装备恢复至类型声明的满电量；永久零电量装备保持0。处罚、恢复消耗牌、充电、重建两份实际清单与结构化日志在同一正式事务中完成。快照新增两份特殊装备清单字段并提升集中修订号，不迁移旧档。

测试覆盖五档收押池、固定2件、股绳保留、3级飞机杯开关、缺1补2、现有空电池和新装电池在处罚末充满、零电量装备不被改写、无违规检查不虚增装备、清单刷新、同版本结果页恢复，以及收押／检查的玩家可见数量和规则说明。专项规则命令`tools/check.ps1 -Suite prison,special_equipment,application,replacement,persistence,status,guard`通过4450项，日志`build/checks/20260908T155415521-29956/check-rules.log`。窗口命令`tools/check.ps1 -UIOnly -UISuite prison,guard`通过132项，日志`build/checks/20260908T160210049-43636/check-ui.log`，未生成截图。

教程书和规则文案同步后，再执行`tools/check.ps1 -Suite content,prison -TimeoutSeconds 240`，1714项通过，日志`build/checks/20260908T161201898-12836/check-rules.log`；执行`tools/check.ps1 -UIOnly -UISuite interface,prison -TimeoutSeconds 180`，433项通过，日志`build/checks/20260908T161255645-40184/check-ui.log`。均使用日常随机样本，没有运行完整随机矩阵。
## 2026-09-09：普通魔法牌「激发魔力」

1能量、零魔力费用、消耗；两面均通过既有嘴部施法流程，成功恢复15魔力并限制于角色mana_max。只在SPECS、CARD_TRAITS、文案与COMMON登记，复用self_faces.mana_gain、正式出牌和消耗区；无新增结算接口或存档字段。普通奖励、商店和图鉴沿共用卡池纳入。

`tools/check.ps1 -Suite rewards -UI -UISuite casting`通过2920项关联规则与45项窗口断言。新增验证双面、零魔力、上限、失败消耗、费用不足和过期版本回滚，以及真实点击恢复和卡面标签；日志：`build/checks/20260909T083002632-48588/`。

## 2026-09-09：魔法牌施法部位与自动选路

`casting.parts`合并原魔法手势枚举与单值施法部位；嘴部保留口部装备概率，手部要求同一只手的手掌和手指均自由，无部位要求仅按快感基础概率。多路径自动选最高成功率，预览、卡面、悬停、卡牌正式提交、双重解锁和牢门共享同一判定。魔力转换两面加入施法成功／失败，通用`fixed_mana_cost`保持原固定兑换费用及不参与折扣／返还。定咒不绕过身体资格；免费准备面和火球术的原规则保留。集中快照修订已提升，不适配旧档。

卡面和图鉴显示所需部位；悬停显示选中部位和实际概率。常驻概率标明嘴部，避免与手部／无部位的卡牌概率混淆。教程和规则文档同步。更新旧双手条件断言，路线测试的既有持久敌人助手补入无人机／拘束盒，仍提交真实攻击与奖励，不改运行时敌人规则。

覆盖单侧可用、跨左右手不能拼接、全部路径不可用的原子拒绝、最高概率与配置顺序、嘴部回退实际开锁及续段只付费一次、四张无部位牌的双面概率、固定兑换成功／失败与定咒、费用和随机数、复合手部装备、牢门、卡面显示及禁用原因适配。

最终关联规则命令 `tools/check.ps1 -Suite casting,composites -TimeoutSeconds 300` 通过3407项断言，日志 `build/checks/20260909T103604371-2172/check-rules.log`。施法窗口分类通过52项断言，日志 `build/checks/20260909T103317166-13956/check-ui.log`；卡面条件、实际路径切换和带禁用原因的文字高度均已检查。使用日常种子范围，未运行全项目回归。

## 2026-09-09：双手施法与稀有遗物「施法动作教程」

默认手部条件改为双手的手掌和手指全部自由。新增稀有遗物casting_manual，沿原TYPES／REWARDS、MODIFIER_LIMITS和RelicEffects.gain接入图鉴、奖励、商店、持有列表及恢复。single_hand_cast为正时放宽为任意一只完整自由手，不跨左右拼接；常驻读取真实持有遗物，无新状态或触发计数。

Game.hand_cast_reason为卡牌手部路径、免费准备、牢门与火球术手势加成的唯一资格检查。火球术保留嘴部基础施法，手部不满足时使用基础威力；火焰精通禁用手势加成仍优先。工具握持、挣脱辅助、口部概率、最高路径选择及费用不变。快照集中修订已提升，不适配旧档。卡牌备注、教程、规则书、遗物表和内容包字段文档同步。

测试覆盖默认双手、单侧包裹、取得教程后的实际开锁及火球术伤害、掌部受限、左右不能拼接、定咒交互、火焰精通优先级、正式遗物池抽取、同版本保存恢复、双侧复合装备以及界面取得遗物后的即时可用性与描述。掌部反例使用现有自动选层工厂，避免在复合包裹同层构造非法装备。

最终命令：tools/check.ps1 -Suite casting,rewards,composites -UI -UISuite casting -TimeoutSeconds 300。通过5324项关联规则断言、57项施法窗口断言；日志：build/checks/20260909T104507074-45700/。使用日常种子范围，未运行全项目回归。

## 2026-09-09：塔顶首领六缚、收束与临时诅咒

第一幕塔顶固定遭遇改为单只六缚。新增六区开场和七步循环；调教升温冻结`1＋当前收束层数`的性玩具安装与加固次数，结算后收束＋1。性玩具满位沿现有人形替换事务处理，同族等品质允许替换，批次保护不允许同次行动反复换掉刚装件。终局忽略替换机会，只在普通／复合均无新增空位且没有加固目标时预告收押。临时诅咒玩弄／玩弄+以真实卡牌UID加入本场牌堆，留手回合末分别增加5／8快感，胜利或收押时从全部牌区清除。塔路、图鉴、教程、意图、行动反馈、首领绘制与出口文案同步；快照修订提升，不迁移旧档。

首轮规则专项发现六缚测试保存了事务提交前的敌人字典引用，正式原子提交后断言仍在读取旧对象；塔顶资源断言也漏算休息作为特殊战斗结束时触发的余烬护符。修正测试引用与既有触发预期后，日常随机专项通过3024项。首轮联合窗口中首页和敌人模块通过，塔顶流程失败是通用快速通关夹具未识别`six_bind`为持续敌人；加入该类型后单独塔顶窗口42项通过，没有更改正式战斗。

最终执行`tools/check.ps1 -Suite enemies,replacement,curses,tower_progression,persistence,content -Exhaustive -TimeoutSeconds 600`，自动合并29个相关规则模块，完整覆盖enemy_cycle 16／16和enemy_pool 24／24种子，共7180项断言通过；日志`build/checks/20260909T113052835-46276/`。窗口执行`tools/check.ps1 -UIOnly -UISuite tower_progression -TimeoutSeconds 300`，42项通过；日志`build/checks/20260909T112943100-8032/`。此前同一批联合窗口的home 80项与enemies 182项已通过。按截图精简要求未生成截图，也未运行无关的全项目all。

## 2026-09-09 缚疗修女与普通单件佩戴正文

- 新增地图事件与练习“缚疗修女”：恢复20魔力并原子安装两件初级2档普通单件、射精一次后通过现有卡牌选择器移除一张真实永久卡牌，或无惩罚离开。
- 事件效果新增通用`mana_gain`，恢复量受现有`mana_max`限制；`install_random.allow_links=false`复用Application并仅过滤链接结构，不建立事件专用安装器。
- 多阶段起始页可用一个无条件、无效果、直达结果页的作者选项替代默认收费拒绝；没有这类安全出口时仍拒绝`allow_refuse=false`内容。
- `Equipment.WEAR_TEXTS`集中维护眼部、口部、脖颈、上肢、下肢、脚掌与脚趾的普通单件佩戴正文，事件结果按冻结后的真实部位和具体装备名调用；脚掌不再显示为“足部”。
- 事件注册新增通用`pool`资格，塔路只从显式合格列表抽取，外部事件默认仍可入池，也可用`pool:false`保留为练习内容。早期占位的裁缝与机械锁匠事件按最新要求连同直接定义、专属钥匙阶段、可见文案和专属回归一起移除。
- 联合执行`tools/check.ps1 -Suite equipment,events,event_flow,content,tower -UI -UISuite events -TimeoutSeconds 600`：规则5578项、事件窗口77项通过，记录`build/checks/20260909T134124947-51860/`。另执行`tools/check.ps1 -Suite persistence -TimeoutSeconds 600`：关联规则4560项通过，记录`build/checks/20260909T134312208-30556/`。两次均未请求或生成截图。

## 2026-09-10 拘束具堆里的微光

- 新增正式地图事件与独立练习。被眼罩、口球及多层拘束具捕缚的扶她冒险者没有对白、示意或主动配合；正文只从主角观察与行动出发，也不重复强调全员成年这一既定背景。
- 玩家尝试从其腰侧皮包取得遗物。第一次成功率25%，失败后逐次提高10%，第九次必定成功；每次尝试无论成败均冻结并原子新增一件初级2档普通单件，排除链接绳、复合与性玩具。装备来自周围数量充足的活化拘束具，不从被困者身上转移。
- 每一阶段均可无代价离开并保留此前新增装备；没有合法单件位置时只保留离开。成功真实获得一件未持有随机遗物，失败进入下一阶段，结果继续复用真实装备名与身体部位佩戴正文。
- 执行`tools/check.ps1 -Suite content,event_flow,events,tower -Exhaustive -UI -UISuite events -TimeoutSeconds 600`：完整随机矩阵规则7795项、事件窗口82项通过，记录`build/checks/20260909T141800897-51928/`。未请求或生成截图。

## 2026-09-10 魅纹师的空房、淫纹与针匣

- 新增正式地图事件和练习“魅纹师的空房”。【回火】在通用二级选择窗口中选满两件普通拘束具后原子解除；任一冻结实例在提交前失效则整项拒绝，不会只解除另一件。【翻查】获得指定事件稀有遗物“魅纹师的针匣”与永久诅咒“淫纹”；【离开】不改变角色状态。可选拘束具不足两件或已经持有针匣时，隐藏无法完整执行的对应选项。
- 普通事件选择器新增通用`count=1—4`及拘束具`include_special`过滤，冻结状态、只读投影、快照和事件窗口均支持多目标数组；新增通用`remove_restraints`效果，先复核全部目标再统一解除。事件界面仍只显示少量主选项，多目标选择留在二级窗口，没有事件专用命令、判断或随机域。
- 淫纹不可打出且不自带保留；只在实际手牌中生效。每次正式行动实际花费至少1能量且成功提交后，每张淫纹追加4快感；一次行动无论花费几点只触发一次，零费、拒绝与事务回滚均不触发，多张相加并继续经过敏感倍率。针匣为稀有、事件限定遗物，不进入通用奖励池；战斗、牢房、休息与整备的每个玩家回合开始统一额外抽1张牌。
- 联合门禁`tools/check.ps1 -Suite persistence -TimeoutSeconds 300`自动覆盖22个相关规则模块，4752项通过，记录`build/checks/20260909T153818833-54760/`；`tools/check.ps1 -Suite events,status,tower -TimeoutSeconds 300`自动覆盖20个相关模块，4038项通过，记录`build/checks/20260909T154033488-51848/`。事件窗口`tools/check.ps1 -UIOnly -UISuite events -TimeoutSeconds 240`通过91项，记录`build/checks/20260909T153140710-9744/`。均使用日常随机样本，未运行全项目回归，也未请求或生成截图。
- 关联回归暴露并修正两处既有测试／校验脆弱点：候选列表不再以数组首项猜事件或连续行动，改按结构化类型筛选；未领取的冻结战斗遗物可正常保存，领取后才要求出现在持有列表。新增未领取遗物的存档往返案例。

## 2026-09-10 漂浮皮带群与事件战斗返回

2026-09-11修订：下列首版记录中的“无整备”已被最新要求替代。事件战斗胜利仍先返回指定结果、发放指定奖励；结果按钮改为“开始整备”，显示当前整备回合数。通过原leave候选完成事件收尾后，消费prepare_pending并进入共用整备，基础3回合及沙漏等修正均生效。非战斗事件仍直接结束。

新增事件流程案例覆盖默认／沙漏回合数、开场抽牌／能量／遗物与蓄力来源、结果与整备起点快照、损坏标记和过期提交拒绝、自然完成／提前结束及奖励不重复。event_flow/rewards关联18类规则6173项通过（build/checks/20260910T162934759-66092/check-rules.log）。窗口先修正测试中的横扫右键切换步骤，最终events完整窗口170项通过，无引擎错误（build/checks/20260910T163316133-66204/）；验证正式战斗结果、按钮文案、整备手牌／结束回合及提前结束。不涉及布局美术，本批无截图。

- 新增正式地图事件和练习“漂浮皮带群”，且不提供离开选项。【硬闯】进入三只初级漂浮皮带组成的指定战斗，必须全部击败；胜利后直接返回事件成功结果并获得稀有事件遗物“软化扣环”，不生成普通卡牌、道具或遗物奖励，也不进入战后整备。【接受灌注】恢复角色25魔力但不超过上限，并获得永久诅咒“淫纹”；皮带临时束缚只属于本段演出，结束后不新增拘束具。
- 普通事件选择新增通用`encounter`声明，保存遭遇、必须击败、胜利效果、胜利正文与结果状态。运行时通过`room_event.battle`冻结返回信息，完整复用正式敌人实例、卡牌行动、回合结算与战斗遗物生命周期；胜利效果再次复核后原子提交。界面只按正式阶段切换事件页与战斗页，没有事件ID专用分支。
- “软化扣环”不进入普通遗物奖励池；持有后，上锁拘束具受到的力量挣扎伤害倍率由0.5提高至0.75，滑脱与开锁不变。事件战斗计入遭遇与胜利数量；`requires_defeat=true`时，装备空间耗尽不能替代击败敌人。
- 先后执行事件流程专项、内容／事件／塔专项及事件窗口专项：234项、3706项和105项全部通过，记录分别为`build/checks/20260909T161941804-41816/`、`build/checks/20260909T162005277-51656/`、`build/checks/20260909T162117909-16260/`。最终执行`tools/check.ps1 -Suite content,events,event_flow,tower,rewards,equipment -TimeoutSeconds 300`，自动覆盖30个相关规则模块，共6026项通过，记录`build/checks/20260909T162320276-38960/`。均使用日常随机样本，未运行全项目回归，也未请求或生成截图。

## 2026-09-10 女药师的试饮摊

- 新增正式地图事件与独立练习“女药师的试饮摊”，且不提供额外离开项。原参考事件中的香蕉、甜甜圈和盒子不进入成品正文，三项改为塔民女药师售卖的魔力补剂、解缚溶剂与魅魔特调。
- 【魔力补剂】沿通用`mana_gain`恢复角色25魔力且不超过上限。【解缚溶剂】通过共享二级拘束具窗口选择一件普通拘束具并完全解除，没有目标时不显示。【魅魔特调】正文明确喝下粉色媚药，沿普通事件遗物池获得一件进入事件时已经冻结的随机遗物，同时用通用`card`效果获得永久诅咒“敏感”；遗物池用尽时隐藏完整选项。
- `remove_restraints`仍是唯一完全解除事务；本批只把单选冻结结果规范成单元素目标数组，使其与2—4件多选继续共用逐目标复核、原子提交和失败回滚，没有增加事件专用拆除、遗物或诅咒分支。
- 事件流程专项`tools/check.ps1 -Suite event_flow -TimeoutSeconds 300`通过242项，记录`build/checks/20260909T163629028-33576/`。事件窗口专项`tools/check.ps1 -UIOnly -UISuite events -TimeoutSeconds 240`通过120项，记录`build/checks/20260909T163638824-38624/`。最终合并门禁`tools/check.ps1 -Suite content,events,event_flow,tower,rewards,equipment -TimeoutSeconds 300`覆盖30个相关规则模块，共6038项通过，记录`build/checks/20260909T163719327-36956/`。均使用日常随机样本，未运行全项目回归，也未请求或生成截图。

## 2026-09-10 废弃储物室与通用事件道具奖励

- 新增正式地图事件和练习“废弃储物室”。事件为纯探索补给，不含拘束或性描写；搜索时分别从三种药剂、三种卷轴和两种普通工具中冻结一件，结果恰好为药剂、卷轴、工具各一件。
- 普通事件新增通用`item_rewards:[{id,pool}]`字段，沿事件随机域冻结每组结果并保存至`room_event.loot`。搜索后进入既有战斗结算战利品界面，但只显示三行事件道具；每行单独领取并在提交时复核随身容量，满位就地灰置并显示具体原因。继续会放弃剩余行并直接完成房间，不生成卡牌、遗物或普通掉落，不进入整备或整理道具。
- 奖励窗口通过稳定分组ID匹配同类别的多行候选；原战斗卡牌、单件道具与遗物行仍沿既有字段和按钮工作。快照验证覆盖搜索前的冻结分组、领取页及单行领取状态，查看、读档和界面刷新均不重抽。
- `tools/check.ps1 -Suite event_flow -TimeoutSeconds 300`通过266项，记录`build/checks/20260909T165040314-46084/`；事件窗口专项通过128项，记录`build/checks/20260909T165050297-41316/`。最终规则门禁`tools/check.ps1 -Suite content,events,event_flow,tower,rewards -TimeoutSeconds 300`覆盖24个相关模块、4602项通过，记录`build/checks/20260909T165202833-41128/`；联合窗口`tools/check.ps1 -UIOnly -UISuite events,rewards -TimeoutSeconds 300`通过204项，记录`build/checks/20260909T165400587-36476/`。均使用日常随机样本，未运行全项目回归，也未请求或生成截图。

## 2026-09-10 三局赌牌性玩具演出

- 第三局“解下原有性玩具”与结算后“重新戴回原处”分别写入阶段正文，不再在选项说明中显示“实际装备状态不会改变”的系统解释。事件不声明`hold_special`或`restore_held`，原装备实例、位置和状态从头到尾保持不变；失败分支新增一件性玩具的既有正式效果不受影响。

## 2026-09-10 缚梦客房与最大魔力事件效果

- 新增正式地图事件和练习“缚梦客房”，只有两个选择且没有额外离开项。【睡到自然醒】恢复至当前魔力上限，并原子佩戴三件中级1档普通单件拘束具；生成明确排除链接绳，任一件无法找到合法位置时整项不生成。【拔走床芯】永久失去8点最大魔力，当前魔力超出新上限时同步压低，并获得进入事件时冻结的随机遗物。
- 新增可跨事件使用的`mana_restore_full`与`mana_max_loss`效果，覆盖内容字段校验、执行前后说明、原子回滚、结果正文和快照验证；最大魔力合法下限调整为1。普通事件同步开放既有`install_random`生成器，只在进房时冻结具体装备；不含生成器的普通固定效果仍保留候选阶段的动态不可用原因。
- 专项`tools/check.ps1 -Suite content,event_flow -TimeoutSeconds 300`通过913项，记录`build/checks/20260909T172011840-54144/`。事件窗口`tools/check.ps1 -UIOnly -UISuite events -TimeoutSeconds 240`通过137项，记录`build/checks/20260909T172027055-47760/`。最终联合门禁`tools/check.ps1 -Suite content,events,event_flow,tower,rewards,persistence -TimeoutSeconds 300`覆盖29个相关模块，共5831项通过，记录`build/checks/20260909T172109761-53264/`。均使用日常随机样本，未运行全项目回归，也未请求或生成截图。
## 2026-09-10 神秘女人的雕像

新增正式事件与练习入口。场景固定为神秘性感女人的蓝石雕像，浅盘中央固定飞机杯；玩家主动插入肉棒并高潮一次，之后才进入共用删牌二级窗口。性交结果正文只写雕像、飞机杯、射精和精液中储存的魔力被吸收，不把卡牌或卡组写成世界内道具。第二项在进阶段时把30—60的随机整数冻结为现有`flask_mana_gain`，查看和候选探测不重抽，提交后给出准确资源反馈且不消耗手动存入次数；第三项无代价离开。

新增作者层通用`random_amount`，仅可包装`mana_loss/mana_gain/flask_mana_gain/pressure`，校验0—100整数上下限并在冻结后彻底展开，运行选项和快照仍只保存原有定值效果。错误上下限和不支持的包装效果均由内容编译拒绝。事件没有专用结算分支，也没有新增随机域或截图。

- `tools/check.ps1 -Suite content,event_flow -TimeoutSeconds 300`：939项通过。
- `tools/check.ps1 -UIOnly -UISuite events -TimeoutSeconds 240`：151项通过。
- `tools/check.ps1 -Suite content,events,event_flow,tower -TimeoutSeconds 300`：4010项通过。
## 2026-09-10 迷宫测绘队

新增正式事件与练习入口，并加入正常高塔事件池。【独自探险】使用现有`flask_mana_gain`向贴身魔瓶增加100魔力，同时沿普通事件作者生成器冻结并原子安装两件中级2档普通单件拘束具；排除链接绳，无法完整安装时不显示整项选择。【结伴而行】增加30魔瓶魔力且不改变装备。两个分支均不建立金币或生命资源，也不占用手动存入次数；结果页显示明确成功标记，独自分支逐件追加实际装备的通用佩戴正文。无新增接口、随机域、存档字段或截图。

- `tools/check.ps1 -Suite content,event_flow,tower -TimeoutSeconds 300`：3365项通过。
- `tools/check.ps1 -UIOnly -UISuite events -TimeoutSeconds 240`：159项通过。

## 2026-09-10 接连挣动改为滑脱顺延

- 数据：chain改为4点基础×3次滑脱，带顺延；2费罕见、自由面蓄力1与抽2、正常弃置保持原设定。共享follow_through校验允许strain/slip，无牌名分支、存档字段、随机域或独立行动新增。
- 文案：卡面、词条、规则书伤害分类及卡牌框架同步。旧版本记录中接连挣动两段挣扎与手动续段的描述由本次修订替代。
- 回归：follow_through新增滑脱实际次数／公式／3档免疫／层级阻挡／优先次序／提前结束／单次扣费与弃置；casting窗口真实拖放验证。旧手动续段与保存恢复用例改用逐层抽离，继续检查选择冻结、无重复扣费、原子拒绝及延迟遗物触发。
- 验证：`build/checks/20260909T195554335-54280/`的rewards及交叉分类4546条规则断言通过；同批窗口casting 142条、rewards 179条通过。`20260909T195318304-52252`中hand_assist 154条、persistence 486条通过；该初次批次的旧续段测试筛选错误已修正并在4546条规则门禁复验。
- 存档窗口恢复事件选牌的旧用例未打开现有二级窗口，已复用Event UI原生点击辅助打开并选择真实卡牌，额外断言卡组只减少一张；无游戏逻辑改动。最终`build/checks/20260909T200056695-51652/`定向persistence窗口61条通过。所有最终相关分类无断言／引擎错误，未生成截图。

## 2026-09-10 强欲之壶

- 数据、文案与卡池：pot_of_greed，1费普通技能，双面抽2，正常弃置；共用self_faces与draw效果，无新逻辑分支、状态或存档迁移。普通奖励／商店／图鉴沿COMMON自动接入。
- 测试：card_expansion检查双面实际抽2、费用、零魔力与身体受限仍可用、普通池及相同双面、过期／缺能量原子拒绝、满手只抽到10；casting窗口验证原生点击两面及抽牌后真实手牌。interface统一验证新SVG覆盖与两种卡宽。
- 验证通过：`build/checks/20260910T034929357-61072/`，导入完成；rewards及交叉分类完整随机矩阵6753条规则断言通过，casting、interface窗口557条断言通过（含两面原生点击抽牌及全卡插图／布局检查）。无引擎错误，未生成截图。

## 2026-09-10 翘腿无视

- 1费普通技能，拘束面8点滑脱并抽1；自由面费用－1、抽1，腿部整体level≤1。普通卡池、独立SVG、卡面、详情与明确阻止原因同步。
- 复用hit_effects/free_effects/draw；通用自由面减费与整体等级上限通过定义校验。统一energy_cost供正式候选与face_costs投影，界面翻面读显示费用，不在界面计算规则。无新状态、迁移或随机域。
- crossed_legs_cases归入rewards，覆盖实际伤害／抽牌、3档免疫仍抽、整体等级边界、0费可用、条件变动提交复核、缺能量／坏定义拒绝；casting窗口真实拖放两面、1／0费用与等级原因；interface覆盖全卡图与布局。
- 验证通过：`build/checks/20260910T042011685-56556/`。导入完成；rewards、casting及交叉分类完整随机矩阵8310条断言通过；casting、interface窗口580条断言通过。覆盖原生拖放、翻面费用、等级阻止原因和全卡插图／布局，无引擎错误，未生成截图。

## 2026-09-10 蓄势待发

- 1费／基础10魔力的普通嘴部魔法，两面消耗指定另一张手牌并获得1蓄力。本牌正常弃置，成功才消耗目标。普通卡池、独立SVG、卡面、目标提示与实际结果日志同步。
- 通用self_faces.exhaust_hand生成正式card候选hand_uid；复用人物目标选择UI、共用卡面、施法、牌区和消耗动画。不新增中间运行状态、随机域或存档字段。
- ready_to_strike_cases归入rewards并由casting交叉覆盖：双面实际费用／消耗、同名实体、不可消耗本牌、目标失效与过期提交、失败留两牌、嘴部阻挡、临时魔力付款、消耗区快照、同面不触发复放；casting UI检查原生点击、取消、指定实体和真实结算。
- 验证通过：`build/checks/20260910T043751978-28776/`，导入完成；rewards、casting及交叉分类完整随机矩阵8296条断言通过；casting、interface窗口592条断言通过。包含原生选牌／取消、两面实际施法、消耗目标实体及全卡插图／布局，无引擎错误，未生成截图。
# 2026-09-10：人物付费行动、快感／堵嘴与施法失败对白

- `core/action_copy.gd`只从已提交payload、行动前后快感、真实口部装备与正式施法结果生成稳定cue；`data/action_copy.json`补齐卡牌四类、非卡牌付费行动、三档快感、清晰／含混说话及卡牌／火球失败正文。完全堵嘴共用一条纯鼻音，事件与零费来源不扩张新机制。
- 加入新系统前的`hero.attack`、`hero.card.bound/free`、`hero.pose`、`hero.calm`、`hero.end`、`hero.item`、`hero.event`与`hero.default`正文和生成分支均已删除。旧存档中的这些cue会被投影静默忽略，不会回退成占位对白；零费结束回合及未纳入新分类的普通操作也不再弹出人物对白。
- 最终规则门禁`tools/check.ps1 -Suite action_copy,casting -TimeoutSeconds 300`通过4071项断言，记录`build/checks/20260910T093623320-46932/`。最终窗口门禁`tools/check.ps1 -UIOnly -UISuite action_copy,casting -TimeoutSeconds 300`通过227项断言，记录`build/checks/20260910T094033775-39812/`；未生成截图。覆盖稳定文案键完整性、卡牌分类、快感边界、普通口球含混、胶带／假阳具口球完全堵嘴、真实卡牌与固定火球失败差分、付费攻击实际组合、旧cue静默清理以及投影不修改规则状态。

## 2026-09-10 高潮不再自动打开角色状态窗

- 正式行动令快感达到100时，界面沿原抽屉互斥流程关闭已有信息面板，但不再把`show_pressure`重新设为开启；高潮中断画面及“继续 · 高潮后缓一缓”保留，顶部状态按钮在之后仍可由玩家主动使用。
- 本批只修改界面显隐与对应真实窗口断言，不改变快感累计、高潮次数、魔力损失、下一回合能量惩罚、候选或存档。`tools/check.ps1 -UIOnly -UISuite pressure -TimeoutSeconds 300`通过49项窗口断言，记录`build/checks/20260910T104515157-54396/`；未生成截图。

## 2026-09-10 高潮第二人称旁白与对白分栏

- 每次正式高潮在原机械日志中保存稳定`climax_copy`旁白cue与`hero_copy`对白cue。旁白全部采用第二人称，只在高潮中断期间替换原手牌区；角色实际发出的声音继续进入既有人物对话框，不进入状态窗口或行动日志。
- 文案按普通高潮、同回合连续高潮及射精前魔力不足20选择稳定差分；对白再区分清晰、含混堵嘴与完全堵嘴，完全堵嘴共用鼻音。低魔力正文将魔力明确写作储存在精液中并随射精流失，不把两者并列成不同液体。旧存档中只有机械高潮记录时使用普通第二人称旁白，不借用更早的行动台词。
- `tools/check.ps1 -Suite action_copy,pressure -TimeoutSeconds 300`覆盖11个关联规则模块并通过3645项断言，记录`build/checks/20260910T105149254-54208/`。`tools/check.ps1 -UIOnly -UISuite action_copy,pressure -TimeoutSeconds 300`通过77项窗口断言，记录`build/checks/20260910T105225902-53924/`；验证真实拖牌高潮后的手牌区旁白、人物对话框、无自动状态窗及唯一继续入口，未生成截图。

## 2026-09-10 事件抵达抽取与每局去重

- 规则边界：本局每个正式事件ID最多出现一次；生成塔图及出发／预览不选事件，最后一步抵达时才从原event随机域抽取未见ID，记录与房间同时冻结。拒绝或离开不返池。正式新游戏、出狱重开与Demo继续均清空记录；本局读档保留，指定练习独立。
- 状态／存档：新增event_seen；未抵达房间不含event字段，池耗尽保存空ID并标记可前进的空房间，不补发奖励。Snapshot修订34，无旧档迁移；校验未知／重复ID与房间重复分配。费用、位移、回合、敌人、装备及奖励规则保持原实现，未增加随机域或通用配置接口。
- 玩家文案：未揭晓房间保持“事件”，说明“抵达后发现事件。”；耗尽显示“空房间”及“房间里没有新的发现，可以继续前进。”。原事件正文和结果沿既有定义，未更改。
- 案例：event_draw_cases并入events，覆盖正式出发／抵达、预览只读、抵达前后存读档、事件排除、耗尽和新局重置；内容包事件接入检查改为抵达抽取。同步修正既有敌人注册列表及工具说明改动后失效的旧断言，不改对应玩法。events关联tower／persistence，按分类合并执行。
- 窗口：events分类162项通过，真实点击出发和旅行后打开事件；日志build/checks/20260910T095349496-24100/check-ui.log。无布局改动，不截图。
- 规则门禁：tools/check.ps1 -Suite events,tower,persistence -TimeoutSeconds 360，通过7847项断言，退出0、无引擎错误；日志build/checks/20260910T095218436-48280/check-rules.log。

## 2026-09-10 火球术基础次数调整

- 将data/basic_attacks.gd的uses_per_turn由3改为2；玩家每回合基础可用2次，炫火自由面仍额外＋1，生效后3次。死灰复燃继续清零已用次数并恢复当前上限，敌人／装备目标共用、失败计次与回合刷新沿原实现。
- 同步炫火能力说明、卡牌框架、游戏设计及AGENTS旧数值；费用、伤害、施法条件、随机和存档结构不变。复用现有flame_flourish／rekindle规则与casting窗口用例修改边界，不新增镜像测试或截图。
- basic_attacks,rewards分类合并5927项中只有原charge_cases把玩家行动摘要误列为不可变状态失败；摘要是实际切换结果，修正断言排除summary后，完整status分类及关联检查3606项全部通过（build/checks/20260910T100740650-11924/check-rules.log）。其余分类此前通过，日志build/checks/20260910T100425883-45808/check-rules.log。
- basic_attacks窗口23项、casting窗口201项通过；日志build/checks/20260910T100542370-51376/check-ui.log。旧姿势用例以三次火球耗尽能量，现改为两能量夹具并实际施放两次，复核耗尽后的起身条件。
- interface窗口复跑453项通过，退出0且无引擎错误；日志build/checks/20260910T100917899-46364/check-ui.log。


## henshin解除捕缚（2026-09-10）

拘束面的release_all沿正式成功施法分支调用CaptureBind.clear_bind，清空全部捕缚来源与共用进度；原装备移除流程、费用、消耗及自由面倍率不变。卡面及框架文档同步。新增捕缚下双面使用案例，验证仅解除面清空、只读捕缚隐藏、警卫回到准备意图。首轮测试夹具遗漏警卫已完成开场的stage，已修正；复验casting关联分类4039项断言仅剩3项ROUTE路线失败，新增henshin案例及所属rewards的1620项均通过。规则日志build/checks/20260910T104727233-56704/check-rules.log；完整casting窗口201项通过，日志build/checks/20260910T104651715-33796/check-ui.log。路线失败保留记录，不宣称整批门禁通过。


## 加固额度可用于上锁（2026-09-10）

Game._reinforcement_locks统一判断3档、可上锁、未上锁；_reinforce_equipment优先完成一次锁定，否则沿原紧度／附加结构刷新。EnemyPlans目标与材料筛选保留原范围并纳入上锁，累计budget每次仍只扣1，不重复锁定；通用事件tighten共享执行与结果文案，指定tighten_to不扩大其明确目标。通过现有锁状态投影复用铜锁图标、伤害减免和解除限制，无新增存档字段。新增reinforcement_lock_cases并入enemies，验证2→3再锁、3档内耐久不回复、满耐久已锁与不可上锁反例、正式回合执行及过期拒绝。肩带旧断言同步新规则，同时保持不补回复合肩带。首轮夹具场景ID写错及旧肩带断言失败已修正；完整enemies/events关联分类5501项规则断言及enemies窗口196项断言全部通过，无引擎错误。日志：build/checks/20260910T105820879-13660/。


## 加固上锁恢复耐久（2026-09-10补正）

按用户补正，上锁属于一次正常加固：3档上锁分支将本体耐久恢复至maximum并调用原_refresh_equipment，保留普通加固的躯干固缚／肩带刷新；不额外占加固额度。日志、词条和规则文档同步。reinforcement_lock_cases中的3档受损样本断言改为恢复满耐久；既有加固及肩带、躯干交叉分类完整复验通过5529项断言，无引擎错误（build/checks/20260910T110408889-62276/check-rules.log）。本条替代上一批“不回复耐久”的设计。

## 2026-09-10 冰心诀与魔血

- 新增普通ice_heart：玩家回合末固定降低3快感，最低0；稀有magic_blood：现有力量＋2，玩家回合开始增加5快感。均登记一般REWARDS、品质、完整说明及共享RelicIcon本地SVG（冰蓝书卷／金边暗红魔法血滴）。图鉴、商店、宝箱及奖励沿现有注册流程读取。
- 规则直接接Pressure.tick的turn_start／turn_end，由RelicEffects读取两个明确数值hook；限定COMBAT_PHASES与active场次，其他行动时机不触发。增长复用Pressure.gain，保留手牌倍率、绿色小鸟及上限结算；降低不套增长倍率，不撤销之前已发生的惩罚。无新状态、存档字段、随机域或特殊事件分支。
- pressure_relic_cases归入rewards，既有分类关联覆盖pressure、属性、特殊战斗、内容与持久化。通过真实回合覆盖4种场次、低于3的边界、力量与伤害、达到上限、保护、存读档、只读与拒绝原子性；图标和悬停在rewards窗口原流程验证。未增加截图。
- Import及rewards,pressure合并分类完成6834项规则断言，退出0、无引擎错误；日志build/checks/20260910T110553546-34164/check-rules.log。窗口初次检查中，伤害预期误放在敌方施加装备之后，已将力量预览检查移到结束回合前，保留真实回合触发检查。

- rewards窗口复跑191项全部通过，退出0、无引擎错误；日志build/checks/20260910T110848695-58044/check-ui.log。两件遗物共享图标／悬停和真实快感变化已验证。


## 遗物图鉴小图（2026-09-10）

图鉴遗物列表使用RelicIcon.ART的40宽缩略图，详情复用RelicIcon显示112×112插画，不伪造局内计数器；切换条目清除旧卡牌悬浮说明，防止遮住遗物正文。无规则或存档变化。home完整窗口97项断言通过，稀有筛选、实际纹理、只读浏览均已验证。截图build/ui-encyclopedia-relics.png人工检查通过；最终日志build/checks/20260910T110949767-59448/。

## 2026-09-10 主页提示删除

删除主页底部的‘开始新游戏将替换塔路进度。’标签及其空条件分支，继续／新游戏／存档行为不变。已先ListOnly核对home范围，完整home窗口检查通过96项断言，退出0且无引擎错误：build/checks/20260910T111759886-49956/check-ui.log。纯文案删除，无截图。


## 分辨率列表至4K（2026-09-10）

取消DisplaySettings.choices按显示器尺寸过滤，720p至3840×2160固定预设均可选；合法自定义窗口尺寸最多保留至4K，异常存储值仍回退预设。全屏继续采用显示器原生尺寸，窗口与无边框选择及显示偏好持久化保持原接口。display完整窗口19项断言通过，覆盖小屏仍列出1440p/4K、选择4K、重新读取4K偏好及原模式切换；日志build/checks/20260910T112507804-37408/。

## 2026-09-10 删除神秘药剂、精简遗物说明、重制余烬晶石

- 删除神秘药剂定义、奖励池及图标引用和SVG，现有注册式图鉴自动同步。能力说明保留必要数值／触发条件，删除力量和灵巧通用解释、重复特殊战斗范围、封顶及既有规则说明；图鉴不再追加同样的获取途径。玩法范围不变。
- 晶石复用遗物触发与tick记录：paid_cast／turn／guarantee一次机会；施法前读取并显示100%，正式付费后使用，仍收取全额费用。身体条件阻止、候选过期与资源不足不使用机会；临时魔力及固定费用兑换计入。免费复放不消费，定咒同时存在时先用晶石并保留卷轴。读取／读档不刷新机会，普通和三类特殊战斗复用正式回合。
- 原晶石返还用例替换为ember_crystal_cases，覆盖付费首发、第二发、下回合刷新、读档、身体条件、临时魔力、卷轴、固定兑换及四种场次；通用重命名遗物仍验证按配置生效。原神秘药剂拾取测试改用红烧鱼香茄子，继续验证上限和重复拾取。日志检查同步为成功保证来源。
- 初跑发现免费复放没有mana字段，已先按replay判断排除；既有复放全分类再次验证。两个新场次夹具重复开场抽牌造成11张手牌，已按既有夹具方式清手后给测试牌。原说明断言同步为精简后的效果，不要求重复规则文字。
- home,rewards窗口290项通过，日志build/checks/20260910T112200375-41248/check-ui.log，退出0且无引擎错误。检查图鉴与实际施法100%／付费／回合刷新，不截图。
- rewards,casting,content及关联分类复跑7429项全部通过，退出0、无引擎错误；日志build/checks/20260910T112402172-32684/check-rules.log。


## 传送符（2026-09-10）

折返符更名为传送符，稳定ID return_seal保留，category为scroll。正式新游戏抵达塔底时获得1张，1次使用后消失；不额外加入掉落、商店或牢房发现池，练习场继续原配置。手指或脚趾任一侧自由即可使用，复用所有卷轴的共用身体条件；触手朋友可绕过该限制。原有1—4级牢房行动回合、背包容量及监狱出发点去向不变。存读场景起点不会重复发放。按原规则被收押仍没收随身道具，没有新增传送符免没收特例。

传送符验证：prison/consumables关联分类4255项规则断言、home/prison/consumables窗口269项断言全部通过，无引擎错误；日志build/checks/20260910T113512009-54100/。


## 回合区与主动投降（2026-09-10）

结束回合155×90并使用24字号，姿势控制行高48／按钮44，红色投降155×44。第一次点击只修改当前版本的界面确认，第二次走正式surrender候选；其他正式行动／重开取消确认。新增规则案例验证普通入狱、5级终局、过期拒绝、场景起点和入狱后不可重复；窗口原生点击验证两次确认、布局尺寸与直接入狱。规则prison关联分类3528项断言通过；截图build/ui-surrender-confirm.png检查通过，prison完整窗口142项断言通过，无引擎错误。日志build/checks/20260910T133445517-13700/。


## 主角显示名（2026-09-10）

主角显示名由希凛改为魔法少女，统一更新人物对白、行动日志署名及默认回退。无规则变更，不适配旧存档历史文字。action_copy完整分类60项规则、29项窗口断言通过；日志build/checks/20260910T134904133-65504/。


## 商店店主立绘与直接测试（2026-09-11）

使用用户原图assets/characters/shopkeeper.png，移除旧矢量商人及无用逐帧重绘。商店扩展至1552×790，左侧店主图片作为商品、店名、对白下层；商店收起战斗身体栏与状态区，魔瓶控件移到顶部并保留正式存取，日志入口移入顶部空位避免覆盖付款。5卡／4道具／3遗物布局和正式服务保持，Practice_shop通过Services.start建立正式库存，离开沿原练习结束流程。测试覆盖实际进入、12货位、纹理、无身体栏遮挡、购买扣款和练习离店。

services关联规则2887项通过（build/checks/20260910T135543739-14732/check-rules.log）；初轮窗口变量重名、离店误期望map及布局移除旧日志入口的失败已修正。最终services完整窗口123项通过，无引擎错误（build/checks/20260910T140229283-53084/）；截图build/ui-shopkeeper-new.png和build/ui-shop-1280.png检查店主无遮挡、全部商品与服务位于画面内。

## 商店侧栏、对白与价签补正（2026-09-11）

身体／资源侧栏默认收起，边缘箭头可反复展开、检查部位并收起详情；只保留顶部一份魔瓶。圆弧遮棚移到店主图片上层。商品卡宽缩到196，价格居中、固定单行并与木架分离。

店主与人物对白共用左键任意处隐藏和首次展示5秒自动隐藏；店主身份读取商店房间及交易日志序号，重绘、付款／侧栏切换和无关日志不续时、不复活旧对白，相同正文的新购买可重新显示。规则验证两次正式购买的发言身份与只读性；窗口覆盖自然超时、右键保留、左键隐藏、侧栏／详情原生点击、两种分辨率价签位置、购买扣款及实际服务。

services关联规则2893项通过（build/checks/20260910T141704852-49064/check-rules.log）。窗口初轮发现发言身份类型比较及价签换行最小高度问题，均已修正；最终services/action_copy/consumables完整窗口306项通过，无引擎错误（build/checks/20260910T142013255-63708/）。本批仅取build/ui-shopkeeper-new.png与build/ui-shop-sidebar.png两张代表画面，已检查收起1600×900／展开1280×720；价签后续限定单行后，以最终布局断言复核。
## 2026-09-11 商店付款对白与小演出

- 保留原 `shopkeeper.png`，图2—5完成SHA256一致的原样复制和Godot导入。自身付款按结算前 `level("arms")` 分为自行射精或飞机杯／手交／足交三选一，方法写入正式交易日志后再投影；魔瓶付款、挑选商品与余额不足均使用普通限时对话框。弹窗确认只改界面已读标记，不改变游戏快照。
- ListOnly确认规则范围为`services,content`及其交叉分类，窗口范围为`services`，没有请求全量或新增截图。最终规则专项3996项通过：`build/checks/20260910T150028003-63900/check-rules.log`；服务窗口专项245项通过：`build/checks/20260910T150159541-50124/check-ui.log`。两次均退出0且无引擎错误。

## 腿部三形态与打断冷却（2026-09-11）

原腿部按钮按正式候选在踢击打断、横扫和站着踢／坐着踢之间循环；第三形态1能量，站姿8伤且要求腿部0级，坐姿6伤且允许0—3级。坐姿倍率1／0.8／0.6／0.4，力量和蓄力复用共用计算；普通踢击可重复，不打断、不倒地、不读写打断冷却。原打断组使用后再等待2回合，第1回合使用后第4回合恢复；原并腿蹬击的同回合次数限制保留，通风口不变。

新增规则案例遍历站／坐／躺与腿部0—4级，验证正式伤害、付款、连续使用、无效提交回滚、力量／蓄力、真实换回合冷却与状态同步。窗口验证三形态右键循环、姿势切换自动更名与伤害、禁用原因、连续使用和禁用时仍能切换。basic_attacks及其status/enemies关联分类1543项规则、basic_attacks/status完整窗口90项均通过（build/checks/20260910T165233104-2540/）。腿部状态说明补充后复核status完整窗口55项通过（build/checks/20260910T165458031-54252/）。无引擎错误；无布局美术变更，本批无截图。
## 2026-09-11 润滑油与身体分组药剂

- 新物品复用FieldTools／Consumables的buff候选与正式item_use事务：3次、0能量／魔力、不耗回合，无身体／姿势或口部减效；按侧栏14组选择完整区域，空组可选，组内后来新增装备也生效。使用同一组仍扣次但不叠加，用尽清理。body_buffs仅保存类型与分组，由同一生命周期清理，不适配旧档。
- escape_preview统一解除三级普通滑脱免疫并对普通／魔法／自动滑脱最终乘2，包含墙面加成；原结构与外层资格、锁具状态、挣扎与额外切割伤害保持。共享Equipment.panel_groups，候选／状态／道具界面共用真实分组，UI只提交原候选与版本。掉落池9件、商店15魔力、黄色药瓶图标，设计书、F1模板和入口说明同步。
- 新案例tests/body_consumable_cases.gd归入consumables，关联equipment／status／slip_motion／services／persistence；覆盖全组候选、嘴手受限、费用／次数、重复、第三次清理、脚掌脚趾和左右掌指覆盖、后来新增装备、普通卡牌真实执行与预览一致、墙面最终乘区、锁具资格不变、外层阻止、过期版本原子拒绝、损坏／重复效果拒绝、当前快照、战斗及整备结束清除。窗口实际点击分组，只提交一次，无二级装备选择，重开显示剩余次数。
- ListOnly先确认consumables／slip_motion／status／services及关联分类；首次规则批次5227项中，新夹具误将粗绳装到脚趾导致8条引擎错误，且旧掉落断言仍写8件，整批失败，日志build/checks/20260910T175756699-57052/check-rules.log。其余关联分类均完成通过。随后只修正夹具与旧断言，并补真实滑脱执行、锁具及外层案例；发现锁并非一律禁滑脱、自动安装会选择其他细分位置，按现有规则修正测试，未改写原规则。
- 最终consumables及其关联encyclopedia／casting共767项通过，exit0、无引擎错误，日志build/checks/20260910T180452643-52896/check-rules.log；同批consumables窗口44项通过。只核对一张ui-lubricant-groups.png；随后将选择按钮改为左右两列等宽，单独重跑该窗口分类，44项通过，日志build/checks/20260910T180736137-29324/check-ui.log，并重新核对同名截图。未运行全项目all，未打包。
## 2026-09-11 单拘束具点击手牌直接出牌

- 用户明确纠正上次仅自动选中再显示“打出”的实现。main._activate_card在原自用／自由面分支之后，按所有身体组中的真实物理ID确认仅剩一件拘束具，并确认当前牌面的显式目标均为该件；用已有ActionIndex.first_usable取得原候选，以原View版本调用_submit。其他部位上的检查焦点不影响定位。多件中只有一件合法不视为单件，捕缚条等其他目标仍保留选择；无效候选不提交而显示原具体原因。
- 不修改规则、费用、伤害、随机、快照及存档。普通检查、右键翻面、原拖动及数字键选牌不触发此捷径；真实自用牌／自由面保持原流程。内置教学、基础操作TXT、规则书、AGENTS与README已同步。
- tests/body_layout_ui_cases.gd新增真实鼠标输入案例：单目标普通挣扎与第二拘束面滑脱各扣一次费用、伤害等于预览、无确认窗、当前部位不匹配仍定位、能量不足无变化、多个真实目标不代选、过期View被正式版本复核拒绝、捕缚条加单件装备保留选择。原单部位检查、压暗高亮、复合去重案例保留。
- ListOnly确认body_layout／keyboard／touch／card_growth后运行完整四个窗口模块，共180项通过，exit0且无引擎错误；日志build/checks/20260910T181750543-26436/check-ui.log。纯交互修正未增加截图，不重复运行无关规则全量，不打包。

## 2026-09-11 道具页图标与信息精简

- 变更包：仅修改道具只读投影、摘要文案及窗口布局／选择交互。状态、效果、数值、费用、候选资格、事务、正式日志、随机域、存档与迁移均不变；各身体部位、材料、姿势、安装高度、环境借力及使用次数继续沿原规则。玩家表面包括列表图标／次数、效果摘要、条件提示、使用说明和操作按钮；完整规则仍可展开，非零成本和具体失败原因保留。
- core/item_presentation复用Consumables.amount与工具定义，GameView提供稳定图标键及摘要；UI使用现有ShopGlyph，不新增位图或状态判定。传送符直接提交原使用候选，其他工具保持目标选择和安装分组。移除所选道具时新选择自动收起旧说明。
- 新增items窗口模块，覆盖原生打开／选择／说明展开、零状态变化、独立图标、实际丢弃的目标与费用和焦点更新。既有consumables、installed_tools整类验证真实药效、阻止原因、涂抹部位、安装／取回和工具被动；旧完整说明断言改为先实际展开后检查，不删除规则覆盖。
- ListOnly确认consumables／installed_tools及关联item_discard、encyclopedia、casting规则；1096项规则通过，日志build/checks/20260911T055700131-13788/check-rules.log。该次UI因number方法引用错误未通过，已修正为game.number；最终items／consumables／installed_tools完整窗口108项通过，退出0、无引擎错误，日志build/checks/20260911T060256249-42948/check-ui.log。
- 已实际查看ui-inventory-compact.png、ui-inventory-tools.png、ui-lubricant-groups.png。药剂分组最终增高20像素，使底部说明按钮完整可见；重新检查最终截图，三列部位与固定丢弃按钮无重叠。仅维护源码和验证记录，未打包或发布。

## 2026-09-11 两张基础牌改名

仅修改strain／slip显示名为“用力！”／“顾涌！”。受影响文字包括共享卡名、优秀学员毕业证书、特殊装备可用牌说明、设计书和现有复放日志断言。稳定ID、状态、候选、伤害、费用、效果、随机和快照均不变；无迁移、无新增规则测试或截图。已检索data／core／ui／tests／content，旧名无运行时残留。按ListOnly确认rewards及其关联分类后执行完整分类回归，不打包发布。

验证结果：rewards及关联分类6753项断言通过，退出0；日志build/checks/20260911T061949712-37820/check-rules.log。未执行发布或全项目all。

## 2026-09-11 手牌区直接选择消耗目标

- 变更包：UI交互／提示与键位接线。原hand_uid候选、版本校验、支付、施法、成功消耗／失败留手、事件和随机保持；无状态字段、迁移或规则改动。身体、姿势、资源、材料和场景各交互轴仍由原候选决定。选牌不提前消耗，点击目标才原子提交原候选及进入选择时的版本。
- 删除HandTargetPicker复制牌窗口，当前手牌区直接显示高亮和压暗目标；施放牌不可选，同名UID分开。小提示及取消复用固定动作区域，不再额外打开身体详情；目标模式禁止拖出／翻面误用。数字键选择源牌后进入同一模式，再按目标数字键提交；Esc、取消及安卓返回退出。
- 更新casting分类中的现有card_power_ui_cases：真实鼠标操作两面、同名目标独立、原卡区控件映射、源牌禁选、取消无状态／随机变化、精确消耗与一次付款；补数字键进入／选牌、Esc及过期版本拒绝。保留targeting原生拖牌回归，touch和keyboard完整分类检查相邻交互。
- ListOnly确认touch／keyboard／casting／targeting范围；完整四类窗口358项断言通过，退出0，无引擎错误，日志build/checks/20260911T062758202-37900/check-ui.log。已查看唯一指定截图build/ui-hand-exhaust-selection.png：原手牌位置、青色目标边、灰暗源牌、上方提示与取消完整可见，没有二级窗口。纯界面接线未重复规则全量，未打包发布。

## 2026-09-11 魔力撑隙预备2层

- 变更包：仅ease自由面reserve_mana数量1→2，实际10点临时魔力。影响自由面收益、共享卡面和临时魔力徽章、实际获得日志；正式候选与事务继续共用原效果定义。状态结构、拘束面、施法资格、1能量费用、自身魔力、弃置、回合、随机、身体及环境交互、存档和迁移不变，原场内无上限／结束保留规则不变。
- 在casting所含temporary_mana案例补充真实高级嘴部受限、高快感、已有临时余额、卡面与徽章一致、过期版本回滚、10点到账及正常弃置。更新core先准备再支付解锁的余额期望及已有baseline窗口的5→10期望。设计书、卡牌框架、AGENTS与README同步；无新界面布局，不额外截图或发布。

验证：先ListOnly确认casting／core及关联范围。首轮5223断言中4项失败：本次旧5点期望1项已修正，另3项为ready_to_strike_cases的kick0在第1回合不能使用（并行变更新增stand_min_round=2），与ease收益无关。修正后完整casting及关联分类重跑，casting自身340项、core410项通过；整体仍因上述3条正义飞踢旧夹具失败而退出1，未宣称全绿。最终日志build/checks/20260911T063514893-6924/check-rules.log；本次新增高口部限制／高快感、10点徽章与收益、回滚和弃置断言均通过。未改写其他任务的飞踢规则或夹具。
## 2026-09-11 稀有能力牌「紧缚爱好」

- 变更范围：新增3费稀有能力牌及战斗期能力状态。状态不保存一次性属性快照，只保存已生效的实体卡牌；力量、灵巧与能力计数由当前普通拘束根、仍有主体的复合根和性玩具实时投影。连接绳、复合组件和附属固定不计。装备安装、移除、破坏、替换及保存恢复后均读取同一动态事实。
- 候选与事务：两面均为原有无目标能力候选并支付3能量；激活本身不增加快感。成功提交其他拘束面牌后，由统一出牌完成钩子固定增加10快感；自由面、拒绝、失败施法及连续段不会多触发。固定增长绕过手牌快感倍率，仍走正式快感上限、高潮及结构化事件。
- 数值与交互轴：每件提供力量＋1、灵巧＋1，进入现有属性乘区并覆盖主动挣扎、体术及主动／被动滑脱。普通／复合／性玩具／连接、自由／拘束牌面、敏感倍率、高潮边界、跨回合、战斗结束、存档恢复与过期版本均有明确案例。敌人、姿势、环境、商店、奖励概率、魔力、能量恢复和随机域没有新规则。
- UI与文案：卡面、图鉴、能力状态、力量／灵巧详情和专属SVG卡图使用同一规则数据；能力状态显示当前件数及实时加值。`changedUiAndLogs`包含卡面双面正文、状态来源／持续时间和固定快感事件；没有二级窗口或新操作模式。
- 迁移：沿现有当前快照修订和卡牌注册表保存实体能力，不增加状态字段；旧档策略不变。随机域：N/A，本能力不抽取随机数。
- 相邻系统：目标为自身，资源为3能量及固定10快感。姿势、朝向、距离、身体侧、材质、紧度、锁、层级和环境不新增资格；当前装备根数继续与现有属性及快感结算相交。
- 验证：`tools/check.ps1 -Suite rewards -TimeoutSeconds 300`通过6984项规则断言，日志为`build/checks/20260911T072412390-36260/check-rules.log`。卡面按最终文案显示“当前每件拘束具/性玩具：力量、灵巧＋1。使用拘束面牌时，快感固定＋10。”，并为完整文字单独缩短本卡插图区；`casting,status`窗口检查完成288项断言，其中紧缚爱好的两面正文、专属卡图、无滚动完整显示、实际激活及动态重算均通过，整组仍有2项并行修改中的魔力回路旧文案断言失败。日志为`build/checks/20260911T074328395-37156/check-ui.log`，截图为`build/ui-binding-enthusiast.png`。未打包、未发布。

## 2026-09-11 猛火下山稀有度与耗魔调整

- 改为罕见，两面基础耗魔10，1能量与嘴部施法保持。定义与UNCOMMON池同步，奖励、商店、图鉴和卡面沿共享数据读取；火球使用抽1、双面同效且不叠加保持。
- 更新原wildfire_descent规则／窗口案例：两面费用、9魔力拒绝、10魔力恰好成功、临时魔力、失败与旧版本回滚、实际激活及火球抽牌、罕见显示和魔力徽章。
- 先ListOnly确认范围，再运行tools/check.ps1 -Suite rewards -TimeoutSeconds 300：6984项断言通过（含自动关联分类）。日志：build/checks/20260911T072412390-36260/check-rules.log。
- tools/check.ps1 -UIOnly -UISuite casting -TimeoutSeconds 300：229项窗口断言通过。日志：build/checks/20260911T072422561-32256/check-ui.log。无截图、不打包。

## 2026-09-11 取消遗物已展示即移出池

- RelicRewards.available仅排除已持有，不再读取relic_seen；offer增加可选本批excluded，由商店传入当前货位，保持同一商店不重复。历史记录继续用于奖励与快照一致性，不新增或迁移存档字段，不重抽已经冻结的商品／事件奖励，不改品质分布、已持有排除及真正空品质的滚木补位。
- 原用relic_seen模拟池耗尽的测试改为真实持有；定向池测试使用显式本批排除，避免把其他遗物效果注入业务场景。新增同一局全见过仍可重现、已领取排除、本批去重、保存恢复、商店离开后事件获得正常遗物的实际流程覆盖。
- ListOnly确认后，relics／rewards／services／event_flow／events／wall／status／consumables／tower_progression共2525项通过：build/checks/20260911T094003591-35764/check-rules.log。
- rewards窗口首次发现全持有夹具的传单进店补魔使旧余额断言失效，改为从真实入店后余额断言三次付款。之后两次窗口均223项断言通过，无窗口失败；检查器均因并行任务运行期间修改工作区而标记source_changed，不能作为静止版本的完整绿色门禁。最新记录：build/checks/20260911T094422342-29956/summary.json。停止重复追逐其他任务的修改；本批未打包。


## 2026-09-11 西兰花与新大理石

- 原marble保留罕见及结束回魔规则，显示名改为西兰花、图标broccoli.svg；新增稀有marble_stone，沿用原marble.svg，进入通用遗物奖励／商店／图鉴。
- 统一Pressure.gain正向增量乘0.6，固定来源也受影响；普通来源与手牌倍率相乘，降低量不缩放。相关预览、装备详情及快感状态共用gain_multiplier。
- 复用pressure_relic_cases覆盖拾取不追溯、两件名称图片、奖励池、敏感叠乘、固定来源、冷却、高潮余数、小鸟封顶和四类场次真实回合；原结束回魔案例继续保留。
- 最后一轮 tools/check.ps1 -Import -Suite relics,pressure,curses,special_equipment,events,guard,content,status,card_power,rewards,encyclopedia,architecture -UI -UISuite rewards,status：规则3490断言、窗口282断言均通过。证据build/checks/20260911T095619064-44004；运行期间存在并行源码修改，summary为source_changed，不能称为静止源码整批门禁通过。不增加截图、不打包。
- 前次失败为新增测试误用void拾取函数返回值，已改为检验实际持有；另一次因并行新增m_donalds.svg未导入中断，完成导入后上述分类通过。

## 2026-09-11 M当劳商店限定遗物

- m_donalds罕见，沿商店罕见分支等权抽取，售价65魔瓶魔力；shop_only／shop_payment及pickup_mana_full为共用数据字段，正常奖励源保持隔离。付款候选显示错误来源／余额原因，正式提交重建并原子扣费，拾取先加10上限再回满。界面价格标明魔瓶，图鉴商店限定分组与M纸袋SVG同步，无旧档适配或打包。
- services覆盖实际种子生成、非商店来源排除、同品质入池、错误付款和余额拒绝、过期回滚、嘴部与高快感下正常购买、已有非默认上限、临时魔力保持、售罄、重复拾取及图鉴。content验证通用字段与错误值；已有滚木耗尽商店夹具改为包含shop_pool。窗口实际切换付款来源、点击购买、检查资源与图标／售罄。
- tools/check.ps1 -Import -Suite services,relics,rewards,content,encyclopedia,event_flow,events -Exhaustive -UI -UISuite services,rewards -TimeoutSeconds 300：规则2502项、窗口477项通过，退出0，源码指纹稳定。日志与summary：build/checks/20260911T095705769-48900/。无截图、未打包。

## 2026-09-11 运气与双目标消耗手牌

- breath_control普通技能，双面2能量。自由：口部无拘束，蓄力1、下一次体术费用－1；拘束：滑脱8×2。两面选择另一张手牌消耗，自身弃置，不删除永久卡组。顶层exhaust_hand/free_slots生成同时含装备、部位和hand_uid的正式候选；提交复核并一次付款，续段／复演不重付。无新状态字段、旧档适配或打包。
- card_expansion新增breath_control_cases：两面数值、普通池与文案、实际两次8基础滑脱、无耗魔／无施法随机、逐档口部阻止、只有自身手牌、目标手牌消失、版本拒绝、重复卡UID、牌区守恒、一次动画、复演和下一次体术真实减费。card_power窗口覆盖两面正文、直接点击、取消、精准消耗、装备拖动→真实手牌选择；casting／targeting／keyboard回归既有选牌入口。
- 首轮新增口部测试误写“嘴部”而正式部位名为“口部”，已纠正断言，未改规则来迎合测试。随后2606条规则、378条窗口断言通过，但同期其他源码修改使检查器标记source_changed；不计为静止版本通过。
- 最终沿check.ps1 -RerunFailed重跑原完整受影响分类：card_power/card_expansion/card_splash/architecture/content/casting/rewards（exhaustive），窗口card_power/keyboard/casting/targeting。规则2614项、窗口381项全部通过，退出0且源码指纹稳定。证据：build/checks/20260911T103241806-47012/summary.json及对应规则／窗口日志。未增加截图、未重新打包。

## 2026-09-11 身轻如燕（已验证）

- 稀有技能light_as_swallow，1费；自由面腿部等级0时获得2层闪避，拘束面下一次卡牌滑脱实际伤害×2。卡面、燕子SVG、关键词、状态层数及通用奖励／商店／图鉴同步。闪避跨回合、本场结束清除，快照38验证非负整数，不适配旧档。
- 闪避由统一Application在真实施加时消耗；随机批次抵消前只查询合法性，随后每次成功施加仍按即时优先级选位。抵消不创建装备、不触发佩戴收益、不转加固；普通、复合、特殊、链接、肩部和替换共用。复合整件及需要完整覆盖的替换组在删除旧件前取消；加固、上锁、捕缚状态不消耗闪避。旧批量接口被闪避的位置不计成功占用。
- 卡牌滑脱倍率在目标／波及／捕缚条预览和实际命中共用，与已有倍率独立相乘；首次有正伤害的一段及其波及结束后移除，后续段正常。施法失败和零伤害保留，普通挣扎、移动被动滑脱及工具不消耗。没有新增玩家操作接口或重复结算器。
- tests/light_as_swallow_cases.gd唯一归属card_expansion，覆盖资格／费用／版本回滚、层数累加／生命周期、选位与随机、无目标、复合／特殊／替换、抵消后不加固、普通／魔法滑脱、失败／免疫、独立乘区、多段与波及。
- 完整所选分类：card_power、card_expansion、card_splash、replacement、application、architecture、content、status、rewards、events、prison、guard、enemies。build/checks/20260911T103408611-39896前十类稳定通过；prison暴露原零能量开门测试未补充起身费用，已在独立姿势检查前补3能量，不改游戏规则。以-RerunFailed重跑失败及未执行范围，build/checks/20260911T103713054-40844：prison／guard／enemies 2117断言通过，窗口encyclopedia／casting／status 144断言通过，源码指纹稳定。合并唯一规则分类5089断言。未跑全项目、未新增截图、未打包。
- 初轮并行breath_control测试及运行期间源码更新的记录保留于102809551-38404、103010933-46644、103117096-5992；以以上稳定分类证据为准。

## 借力打力（2026-09-11）

普通技能，1能量，稳定ID `leverage`。拘束面：造成当前佩戴拘束具数量×2的基础挣扎伤害，不计特殊装备。普通件每件计1，复合拘束具整件计1，已失效件不计；沿既有佩戴计数，不额外计连接绳、肩带或复合组件。自由面要求上身束缚等级＝0，获得1层闪避和1层蓄力。两面无耗魔、无施法判定，成功后正常弃置。

通过 `worn_damage={per_item:2,include_special:false}` 声明动态基础值，`Cards.base_damage`供卡面、预览、实际伤害、波及及复放共用；力量、蓄力和挣扎乘区继续正常生效。`worn_count`默认仍包含特殊装备，紧缚爱好不变。牌面显示公式、当前基础伤害和特殊装备排除说明；普通奖励、商店和图鉴共用注册表，添加独立SVG小图。不新增状态、随机域或存档迁移，不打包。
RuleChangePackage：状态复用evasion/charge；候选复用card目标、上身等级和能量资格；数值新增佩戴计数×2；事务仍按版本复核与原子提交；事件／日志复用挣扎伤害及增益事件；界面／文案更新卡面、图鉴、奖励、商店和图标。迁移、随机域无新增。交互轴覆盖目标、部位、层级、组件、锁、材料、姿势、环境、属性、增益、资源、阶段、随机、版本，除计数基础值和自由面效果外均沿现有规则。测试包含空计数、特殊件排除、复合去重和失效、动态显示、主目标／波及、过期版本、能量不足、上身限制与解除后恢复；测试归card_expansion与card_power窗口。card_expansion、card_power、card_growth、card_splash、rewards、casting、architecture共2298项规则断言通过；card_power真实窗口214项断言通过。报告：build/checks/20260911T104531915-48188/summary.json。首次检查发现旧文案断言只支持固定基础值，已补充动态公式及当前数值断言，再对全部所选分类完整重跑通过。未打包。

## 2026-09-11 炫火降为罕见

- flame_flourish由rare改为uncommon，从RARE移入UNCOMMON；保留1能量及双面能力效果。普通奖励／固定品质奖励／商店从同一注册表取牌，新商店按罕见25魔力定价，卡面与图鉴读取罕见分类。设计表、说明与既有炫火规则／窗口断言同步，不打包。
- 最终 tools/check.ps1 -Suite card_power,rewards,services -Exhaustive -UI -UISuite card_power：规则1601项、窗口214项通过，退出0且源码指纹稳定。证据build/checks/20260911T104629539-47284/summary.json。
- 前两轮窗口先遇同期新增leverage.svg尚未导入、再遇借力文案断言失败；完成导入并等待该断言在工作区修正后重跑原受影响分类。最终不保留失败，不将同期移动源码的结果当作最终通过。
## 首场战斗教程引导（2026-09-11）

“扶她出去”默认关闭，保留玩家主动保存的开关选择。教程书默认关闭；本地玩家首次实际显示battle界面时，自动打开既有教程书的basics分类，并立即在display-settings.cfg的onboarding.first_battle_tutorial_seen写入true。首页、地图、商店及其他非战斗界面不消费首次展示；刷新、关闭、读档或开新局不重复弹出。仍可通过原教程按钮手动打开。该标记独立于局内存档，PC与Android均使用既有user://设置目录；不修改玩法、资源、回合或随机。

RuleChangePackage：仅显示偏好与首次展示入口，复用教程抽屉及遮罩；状态是本地布尔偏好，候选／事务／规则数值／游戏事件／机械日志／随机域均N/A（无玩法变化）。玩家文案沿既有基础操作和关闭按钮；显示设置写入保留该标记，默认缺失为false。首页专项覆盖首次、非战斗、关闭、重复渲染、跨设置重载、再开局、独立配置及手动开启；不开展局内存档迁移，不打包。

验收：architecture／runner共420项规则断言、display／home共53项真实窗口断言通过，最终稳定源码报告build/checks/20260911T105316059-40140/summary.json。扩展interface检查有4项既有卡面布局断言失败：binding_enthusiast已有独立0.58图高比例，而旧测试统一要求2/3，并依赖它提供滚动溢出示例；本次未修改该卡布局或放宽断言。首次扩展检查还报告源码指纹变化，故不采用其通过数，已在稳定源码上完整重跑本次引导、设置和框架范围。未打包。

## 斧护符（2026-09-11）

罕见遗物axe_amulet，最终名称为“斧护符”。进入精英房、Boss房或监狱时恢复20点自身魔力，不超过mana_max；不恢复魔瓶或临时魔力。加入普通奖励和商店池，图鉴／遗物栏共用名称、说明及独立双刃斧护符SVG。

分别声明elite_entry_mana、boss_entry_mana、prison_entry_mana通用数值。_start_battle在遭遇变体确定后、首回合行动前按Boss优先／精英其次调用原_mana_hook；同一Boss兼具精英标签只触发一次。入狱在Guard.capture真正收押后触发，点击进入牢房、巡视、继续探索、反抗后返回均不重复；再次被捕属于新一次进入，包含高安全监室终局。牢房练习入场也调用相同恢复钩子。拾取本身不追补当前房间，普通战斗、商店、休息与整备不触发。

RuleChangePackage：新增遗物配置和三个通用入场回魔数值，无新保存字段或随机域。正式提交、版本复核、原子回滚、魔力上限与原遗物触发日志共用；正文报告实际恢复量。状态／候选／事务仅在真实入场时增加mana；其余十四交互轴（目标、部位、层级、组件、锁、材质、姿势、环境、属性、增益、资源、阶段、随机、版本）除资源与入场时机外均沿既有规则。规则测试归relics并覆盖普通／精英／Boss／重叠标签／变体、上限、只读、拾取、过期、重复、巡视、反抗、再捕和高安全边界；窗口归encyclopedia。暂不进行旧档迁移，不打包。

## 魔术手、超级顺延与欧内的手（2026-09-11）

魔术手为罕见魔法，两面1能量、20基础魔力、嘴部施法；拘束面每段降紧1档，共3段，超级顺延；自由面获得2层闪避；正常版本成功使用后消耗。超级顺延先保留原目标，再按同精准部位→左栏大部位→同区域寻找合法目标，原顺延无目标后才全身补选，优先手腕→口部／手指→其他，同级随机；后续重新使用所在部位的普通顺延优先级。沿既有层级与直接降紧资格，上锁装备仍可降紧；费用、施法及实体牌消耗只结算一次。

欧内的手为普通奖励和商店池的罕见遗物；首次拾取向永久卡组及当前弃牌堆加入1张专属魔术手。赠牌与普通版本共享全部机械定义，仅无消耗特性且排除随机卡池；使用后正常弃置，跨战斗重建和当前快照保留该身份，不修改已有魔术手。新增独立卡图和遗物SVG，图鉴、卡面、悬停、来源及拾取日志同步。

RuleChangePackage：复用现有card_chain、evasion、卡组实体及card_target随机域，无新增保存字段。候选／事务沿统一版本复核，双面魔法费用读取face_mana，降紧逐段复用lower_durability；结构化日志保存每段实际目标与结果。新增通用pickup_cards内容配置及永久牌校验。十四交互轴中目标、部位、层级、锁、资源、增益、阶段、随机和版本都有正反／边界检查；材质、姿势、环境及其余结构限制沿原候选规则，不新增旁路。测试归card_expansion／relics／content及card_power／rewards窗口；包括三档足额／不足、局部优先／全身补选／并列随机、锁与遮挡、失败付款留手、临时魔力、过期回滚、真实闪避、赠牌身份与重复拾取、两种版本同局操作。未迁移旧档、未打包。

验证记录：最终选定分类relics／architecture／content／rewards／prison／guard共2350项规则断言及encyclopedia窗口50项断言全部通过（build/checks/20260911T113532571-3872/summary.json）。但运行期间其他任务改动pressure.gd、card_effects.gd及奖励／新卡测试，统一入口按SOURCE CHANGED返回失败，因此本批不得标为整批稳定Verified，也不得声称最终源码全绿。此前放大镜图标未导入和两处自定义遗物／奖励快照报错已在最新一次运行消失；本任务未修改对应恢复代码。斧护符专项已多次通过，名称、卡池、真实进房与入狱回魔、上限、去重和图鉴均有证据；未打包发布。

## 2026-09-11 放大镜验证

- 稀有遗物magnifying_glass：奖励生成时增加1个候选，同窗口先领取遗物仍保留原三张；默认奖励四选一，商店显式2／2／1货位不变。测试归入rewards（battle_reward_cases）、窗口rewards；content／relics／services／events／encyclopedia／core／tower按影响验收。
- 规则入口：`tools/check.ps1 -Suite architecture,content,rewards,relics,services,events,encyclopedia,core,tower -Import -Exhaustive -KeepGoing -TimeoutSeconds 600`，首轮relics／architecture／encyclopedia通过；content发现卸载内容包后快照提前读取未知遗物，已补定义检查，未绕过错误。
- `-RerunFailed build/checks/20260911T113312504-45008`：剩余content／services／rewards／events／core／tower全部通过，4127断言，固定指纹，报告`build/checks/20260911T113435699-6924/summary.json`。包含同窗口冻结与快照、四张唯一可复现抽样、Boss品质、休息5／3回合、事件第四张领取及商店不扩位。
- 首轮窗口测试中下一场战斗夹具缺少battle阶段，已修正夹具；该轮存在源码变动，结果未作为最终门禁。重跑rewards：251断言通过，固定指纹，报告`build/checks/20260911T113812245-16680/summary.json`；其余encyclopedia／services／events重新运行508断言通过，报告`build/checks/20260911T114011006-38128/summary.json`。
- 人工检查`build/ui-magnifying-glass-reward.png`：四张牌无重叠、未越界，返回与跳过完整；实际点击第四张只领取该牌，休息四选一仍可无费用跳过。图鉴与顶部遗物栏共用SVG。未运行完整项目回归，未打包或发布，不兼容旧档。
验证记录：
- 魔术手原实现稳定回归build/checks/20260911T111844609-42268：剩余所选规则2228项、card_power／casting／targeting窗口328项通过，退出0。
- 加入欧内的手后，build/checks/20260911T113253554-38564中card_power、card_expansion、relics、architecture、installation_priority、encyclopedia通过；content遇同期奖励数量投影在未知遗物定义上提前求值，工作区后续已补充定义验证。先前OLI池测试依赖已取消的relic_seen排除，已改为正式显式排除数组，保留实际抽取断言。
- build/checks/20260911T113704410-42792：card_power通过；card_expansion仅同期新增FATE direct redistribution is not multiplied by gain modifiers失败。本次没有删除或放宽该断言，不能称为全部受影响分类全绿。
- 最后一轮build/checks/20260911T113803846-45392：relics、architecture、installation_priority、encyclopedia、content、casting、services、rewards共2836项规则断言通过；card_power、casting、targeting、rewards共578项真实窗口断言通过，涵盖普通魔术手消耗、赠牌弃置及新图标。之前遗物ART加载错误经资源重新导入后未再出现，BREATH拖拽选手牌单次失败在本轮完整窗口分类中未复现。
- 最后报告为source_changed：共享工作区在运行中仍有其他源码写入，因此仅记录上述实际检查结果，不宣称稳定版本全绿。未对无关新牌失败展开修复，未自动重复全项目、未截图、未打包。

## 控火自由面修订（2026-09-11）

控火自由面改为火球术基础伤害永久＋2；使用条件为手部自由且上身束缚等级≤1。删除旧UPPER_BODY_SLOTS逐部位全部无拘束要求。free_max_levels.arms=1复用区域条件，self_faces.free.requires_hand复用正式hand_cast_reason；默认双手的手掌与手指自由，施法动作教程允许任意一只完整自由手。两项条件同时检查，身体等级1可用、大于1拒绝。仍是1费普通技能、消耗，不耗魔、不判施法；拘束面仍获得2层魔力预备。

永久值沿spell_base_bonuses与既有火球伤害入口，先加基础再乘倍率；多张每次＋2、跨战保留。卡面通过free_spell_bonus读取真实配置，删除旧逐部位紧度词条，显示手部自由／上身束缚等级≤1，保留手部词条及具体失败原因。

RuleChangePackage：数据改永久增量与自由面资格；新通用布尔requires_hand仅声明身体使用条件，不新增施法或状态。候选、原子提交、版本复核、日志、状态、图鉴、卡面及快照字段继续共用。十四交互轴中属性、增益、身体与区域等级、资源／版本已覆盖，其他目标、层级、组件、锁、材质、姿势、环境、阶段及随机不增加规则。测试更新＋2／多次＋4、倍率、跨战、手部限制、恰好1、腕部超过1、低耐久归零、单双手遗物边界、无施法、能量不足和过期回滚，窗口验证新词条与实际火球数值；不打包，不迁移旧档。
控火验收：card_expansion、casting、architecture共1074项规则断言通过；card_power真实窗口226项断言通过，源码指纹稳定。最终报告build/checks/20260911T114540857-35760/summary.json。旧残留耐久案例更新为经过正式_cleanup移除后恢复手部自由，避免沿用已经取消的仅紧度归零条件。未打包。

## 2026-09-11 六缚循环空闲回合

- 六缚循环由7步改为8步，在六缚齐收后复用idle，正式敌方回合推进一次，等待图标／悬浮“敌人暂不行动”／行动日志同步。开场、其他7步、收束增长及逮捕优先级保持；第一轮初级与后续中级品质、当前快照校验共用循环长度。
- `tools/check.ps1 -Suite architecture,enemies,intent,encyclopedia,content,core,tower -KeepGoing -TimeoutSeconds 600`：2794断言通过，日常种子范围，运行前后指纹一致。报告`build/checks/20260911T114901714-34708/summary.json`。覆盖连续三轮顺序、齐收后等待、真实空闲回合无施加／加固／状态牌／收束、恢复当前快照结果相同、旧版本提交回滚、共享打断保留步骤、高潮逮捕插入及取消恢复。
- `tools/check.ps1 -UIOnly -UISuite enemies,encyclopedia -TimeoutSeconds 600`：254断言通过，指纹一致。报告`build/checks/20260911T115054092-40956/summary.json`。实测等待意图与悬浮说明，结束空闲回合后正常显示下一轮施加意图。
- 未新增界面布局或图片，未开启截图；未运行全量回归、未适配旧档、未打包发布。
## 汲取力量（2026-09-11）

新增siphon_strength「汲取力量」：1能量、罕见魔法、双面手部施法，不消耗魔力。自由面消耗手牌中全部魔法牌，每张恢复10点自身魔力（不超上限）；拘束面消耗全部非魔法手牌，每张获得1层蓄力。按type_tags筛选，含magic的双词条牌与其他汲取力量计入自由面；技能、非魔法能力、诅咒和状态计入拘束面。同名实体分别计数，正在打出的源牌不计入。源牌正常弃置，不删除永久卡组；没有符合条件的牌仍可打出，收益为0。手部、施法动作教程、快感成功率与失败支付沿正式管线；失败只扣能量、保留手牌，无消耗和奖励。

self_faces新增通用exhaust_hand_batch配置（include_type或exclude_type、mana_gain、effects），成功后冻结真实手牌目标集合，再统一移入exhaust并按实际数量应用效果。没有hand_uid、手动挑牌或待决选择。每张提交既有exhaust动画事件，由CardMotion逐张缩小淡出；动画不持有或修改规则状态。日志记录实际张数与UID数组；卡面、图鉴共读配置，右上自由面魔力徽记“+10×”表示每张回复量，拘束面无魔力徽记。登记罕见奖励／商店池及独立SVG。

RuleChangePackage：影响卡牌数据、双面候选、手牌／弃牌／消耗区、魔力／蓄力、事件、卡面与消耗动画；不新增存档状态、随机域或专用UI判定。十四交互轴中资源、手部与遗物、牌区／类型、增益、施法随机及版本回滚沿共享实现；目标层级、材质、锁、环境、姿势与NPC等不新增行为。规则用例加入card_expansion，实际点击／双面／无选择／逐张动画加入card_power窗口分类；沿casting和architecture复核共享文案及配置。已通过相关规则与窗口检查；未打包发布。
汲取力量最终验收：按最新要求，自由面消耗魔法手牌、每张恢复10魔力，拘束面消耗非魔法手牌、每张蓄力1。card_expansion／casting／architecture共1104项断言通过；card_power窗口238项断言通过，包含一次点击完成、无手选窗和逐张消耗动画。源码指纹稳定；报告build/checks/20260911T120534372-33972/summary.json。未打包发布。

## v0.13双平台打包（2026-09-11）

按用户明确要求直接打包，未运行整体测试、发布检测脚本或成品启动探针。项目版本0.13；Windows文件／产品版本0.13.0.0；Android versionName=0.13、versionCode=5，沿用org.magic.spire与既有发布签名。两个平台运行源码清单一致，导出成功；保留打包过程所需的签名、对齐、版本／资源完整性处理，未进行安卓真机安装。

成品：outputs/紧缚尖塔demo-v0.13-Windows64.zip（Windows x64便携包）与outputs/spire-v0.13-android-20260911-v013/spire-v0.13.apk（ARM64＋ARMv7）。发布包不携带存档和个人设置；校验和记录在outputs/spire-v0.13-checksums.json。导出日志：build/package-20260911-v013及build/android-20260911-v013。后续改动仍需用户明确要求后再打包。
## 套娃二级遗物领取（2026-09-11）

按用户最新确认，选中套娃后先生成并固定普通、罕见、稀有遗物各1件，立即显示三张带图标、品质、名称和完整说明的遗物卡。每件独立领取或跳过，可以全部领取；领取一件后其余两件仍可操作。完成或跳过剩余后返回原奖励界面，套娃本身标记已领取，卡牌等奖励继续保留。此要求覆盖此前套娃自动发放、不追加二级领取的限定。

core/relic_bundle维护候选、冻结记录、领取／跳过及只读投影；UI只提交正式候选。领取时复用RelicEffects.gain执行真实拾取效果；生成、查看与跳过不发放增益。无新随机域，使用relic域；查看、重复渲染与逐件领取不重抽，零能量／零回合。普通池各品质无候选时分别使用滚木，同名滚木用索引区分三份奖励。未完成界面只提供当前三件的选择与返回，阻止底层奖励或战斗操作绕过领取流程。

新增relic_bundle存档字段；快照修订39，校验来源、三档固定品质、真实领取状态和归属，当前快照可恢复选到一半的界面，不兼容旧存档。注册在relics、rewards关联分类，实际窗口用例覆盖打开／逐件领取／跳过／返回；键盘复用奖励界面焦点边界。相关规则与窗口专项已通过；不重新打包。
套娃二级界面验收：relics／architecture／rewards共1225项规则断言通过；keyboard／rewards窗口324项断言通过，源码指纹稳定。包含原生点击套娃、三卡说明、单件领取与跳过、继续领取剩余、返回原奖励页和键盘边界。报告build/checks/20260911T125605998-48992/summary.json。未重新打包。

## 火堆随机金卡（2026-09-11 最新修订）

覆盖此前稀有三选一花5回合的规则：rest_rare点击领取时从正式稀有卡池随机获得1张，消耗3回合，剩3回合休息。reward_offer使用fixed来源和显式count=1，不推进稀有率修正，选牌数量遗物不增加随机赠牌数量。rest_cards仅冻结罕见候选，保留普通三选一／放大镜四选一、原3回合费用；魔瓶及跳过原样。统一原候选、版本复核、领取日志和_begin_rest，不新建随机域或旧档适配，不打包。
RuleChangePackage：影响休息候选、reward随机域的抽取时机、rest_cards当前快照资格和只读奖励面板；领取日志保留实际卡名、扣除及剩余回合，教程同步。能量、魔力、装备、姿势、世界、材料、锁、层级等不改；仅选择奖励后按原顺序进入真实休息开场。测试更新services／rewards及对应窗口，覆盖随机品质与数量、种子差异、查看不抽签、过期及不足回合原子拒绝、快照重现、其他奖励互斥、遗物选牌数量交互和剩余回合结束。

验证：build/checks/20260911T130325590-53964中services全部452项规则断言通过，包含新随机金卡、3回合、只读／回滚、重现及互斥；该轮源码变化，不能作为稳定完整回归。修正休息奖励行数量的旧断言后，后续规则回归被tests/prison_cases.gd与tests/guard_cases.gd无法预加载阻断。最终稳定源码窗口报告build/checks/20260911T130607873-57328：services 270项通过，真实点击随机金卡直接获得1张稀有卡并剩3回合休息；rewards因上述其他测试脚本加载错误失败。此前rewards另有FX资源反馈断言失败，未改变或放宽无关断言。当前不宣称完整回归全绿；未打包。

## 横扫伤害调整（2026-09-11）

横扫基础伤害4→5，沿BasicAttacks.TYPES.kick[1]统一读取，候选、简明预览和全体实际命中同步。费用仍1能量，姿势、腿部倍率、蓄力、冷却与打断规则不变。RuleChangePackage仅改基础数值及对应显示；正式事务、事件日志和各交互轴沿现有规则，无新增随机域／状态／存档字段。更新basic_attacks完整分类的5点预览、连续两次全体10点伤害及真实窗口单次全体5点伤害断言。不打包。

验收：basic_attacks规则167项、真实窗口50项断言通过，退出0且源码指纹稳定。报告build/checks/20260911T131135799-54524/summary.json。


## 怪物血量上调（2026-09-11）

按用户确认：漂浮口球18→24；漂浮绳索／胶带／扎带24→30；漂浮锁24→28；一团分不清的拘束具42→56；游动的绳蛇40→60；奴隶贩子40→56；多面手44→60；魅魔警卫70→90；玩偶师72→96。其余基础血量保持，包括漂浮皮带30、玩具箱30、小法阵30／大法阵40、无人机32、拘束盒64、一团绳／皮带48、一堆绳／皮带96、玩偶10及六缚220。

仅修改敌人基础生命数据，沿原敌人工厂、正式攻击和只读图鉴／血条生效。续局仍从新基础值乘1／1.5／2；一堆系列直接分裂使用原继承血量，不因小怪基础血量增加而重算；一团绳死亡产生的普通绳索沿新30生命。行动、分裂条件、强度、奖励、减伤及成长不改。不打包。专项覆盖三轮工厂血量、两发基础火球后的存活与3能量50伤害的实际攻击序列，复核既有敌人／警卫／奴隶贩子／窗口与路线用例。

血量调整验证记录：新增enemy_health_cases覆盖全部注册敌人在第1／2／3轮的基础血量与倍率，并通过正式攻击验证30血绳索承受两发12伤害火球后剩6血、60血绳蛇承受50伤害后剩10血。敌人分类最新执行1465项断言，1464项通过，仅six_bind_cases中的战后临时诅咒立即清理断言失败；该失败对应同期战斗结束时机改动，未修改该规则或掩盖旧断言。该次源码在运行期间被其他改动更新，报告状态source_changed，不作为最终分类全绿记录（build/checks/20260911T132122369-58324/summary.json）。此前core与tower_progression中的战后回魔断言同样失败，留待对应结算批次处理。

窗口：enemies／trader／targeting分别204／38／63项通过（build/checks/20260911T131759133-58532/summary.json）；随后修正两处警卫窗口的旧血量／踢击预期，改为检验正式候选的伤害与打断结果。guard／tower_progression合计90项通过且源码指纹稳定（build/checks/20260911T132359877-38236/summary.json）。玩偶师群攻用例沿当前横扫注册伤害检查两目标命中，避免继续硬编码已变更的4点横扫。未运行全项目测试、未打包。

## henshin双面费用（2026-09-11 最新要求）

拘束面2能量，自由面4能量；基础40魔力、施法、消耗、解除及不可叠加伤害翻倍效果不变。cost=2，自由面沿现有附加energy_cost=2，不增加费用接口。RuleChangePackage仅改双面能量阈值／实付及卡面数字，其余状态、事务、随机、身体／装备等交互轴沿原规则；关键词、图鉴与候选共用原费用投影。更新现有双面不足能量拒绝／实付规则用例，捕缚效果案例补足自由面能量，窗口验证两面数字及点击扣费。不迁移旧档、不打包。

验证：card_expansion／relics共1416项规则断言通过，见build/checks/20260911T132722716-59036。窗口同步了旧“两面3费”夹具（自由面实际需4能量）和拘束之拥沿现行整备规则的持续时间断言，未修改其机械效果。最终card_power全部248项窗口断言通过，含henshin双面显示、点击实付和消耗，见build/checks/20260911T133234581-58088；该最后报告source_changed，共享源码运行中有变更，因此不宣称稳定源码完整全绿。未打包。

## 战斗延续至整备与跨战保留验收（2026-09-11）

按用户最终确认，henshin拘束2费／自由4费。战斗胜利保留原牌区、能力与增益；整备进入下一个玩家回合，不重复开场。结束收益与清理统一在整备结束执行一次；休息结束不触发战斗结束收益。跨战额外能量默认1，乌龟壳后3；蓄力2→4，临时魔力20→30。

规则分类core／relics／card_power／card_expansion／rewards／status／services／events／pressure／enemies／prison／architecture／content共7194项断言通过，报告build/checks/20260911T133421371-48476/summary.json。敌人随机矩阵按日常采样执行，无随机生成规则变更。

实际窗口card_power／rewards／status／services／events／prison／pressure共1211项断言通过，报告build/checks/20260911T133421377-59172/summary.json。覆盖双面显示和实际付费、奖励页保留增益、整备回能与消耗区延续、状态持续时间、回魔动画分时机、提前／自然结束以及事件／监狱流程。两份最终报告均为passed，源码指纹稳定；此前工作区并行修改期间的source_changed报告不作为最终验收。同步规则说明与教程；不适配旧档、不打包发布。

## v0.14发布包（2026-09-11）

按用户要求生成Windows和Android v0.14发布包。项目显示版本0.14，Windows文件／产品版本0.14.0.0；Android versionName=0.14、versionCode=6，沿用org.magic.spire及既有发布签名，ARM64＋ARMv7。

新Windows包取消“开始前请读.txt”，保留基础操作教学与许可文件。Windows及Android发布目录和ZIP都原样加入项目根目录“版本更新内容.txt”，文件及压缩包内文本均与用户原文件SHA256一致，不改写正文。Android ZIP附APK及安装说明；原APK也可单独安装。

成品位于项目根outputs：紧缚尖塔demo-v0.14-Windows64.zip、紧缚尖塔demo-v0.14-Android.zip；独立APK位于spire-v0.14-android-20260911-v014/spire-v0.14.apk。校验和见spire-v0.14-checksums.json。双平台运行源码清单相同且导出期间稳定，Windows包资源探针及成品启动通过，Android签名／对齐／版本／资源探针通过；无存档或个人设置，未做安卓真机安装。本次仅打包与成品检查，未重跑完整玩法回归。

导出日志：build/package-20260911-v014、build/android-20260911-v014。Windows验证：build/package-check-20260911T134455943；APK资源验证：build/android-probe-20260911T134556438。不涉及远程上传或托管。

## 卡组浏览排序修正（2026-09-11）

默认按当前展示牌面的能量费用升序，同费按中文名称顺序，再按原列表位置稳定排列；稀有度不参与比较。按名称独立排列，中文使用固定zh-CN字序，英文忽略大小写并保留数字自然顺序。按获得顺序恢复原实体列表；每个UID保留独立卡片。费用筛选与排序读取和卡面相同的只读face_costs，翻面后同步刷新。不可打出排在费用最后。

RuleChangePackage：仅浏览排序／筛选和本地翻面展示，复用正式卡面费用投影；候选、事务、资源、牌堆、随机、日志、存档及十四规则交互轴均N/A（不提交玩法动作）。UI保留原三项排序与独立稀有度筛选，不增加常驻说明。interface窗口新增名称／费用／稀有度冲突顺序、术式解锁0→1翻面、筛选、重复实体、恢复获得顺序及状态不变回归；与现有全部interface分类一起验证。不打包。

## 顶栏与日志回合统一（2026-09-11）

修复整备顶栏与日志使用不同计数器的问题。Game.display_round统一提供当前显示回合：战斗读取round，整备／休息读取combat.turn，牢房／巡视读取prison.turn；顶栏和_emit日志时间戳共同使用，已有日志按记录时的回合保留，不随当前阶段重写。战斗→整备继续既定场次回合，休息从自身第1回合开始。只统一显示口径，不改回合推进、行动花费、敌人时机或遗物计数。

RuleChangePackage：影响只读顶栏与新日志round值，复用原日志字段、候选和原子提交；无新状态字段、随机域、旧档迁移或规则数值变化，其余十四交互轴不变。action_copy分类覆盖五种阶段、整备连续推进、休息从1计数、历史保留、只读和拒绝请求；interface真实窗口验证领奖进入整备后顶部／日志同时第4回合、结束回合同时第5回合。不打包。

验收记录：build/checks/20260911T140021986-56040中relics／services／action_copy共1258项规则断言通过；interface完整窗口134项中，本次顶栏／日志对齐及连续整备回合用例通过，另有3项既有卡图／文字布局断言失败（magic_hand_gift共享图、binding_enthusiast非2/3图高、旧文本溢出示例）。本次未改动或放宽这些无关布局检查。报告还标记source_changed，故不宣称稳定完整全绿；本次未打包。

排序修正验收（2026-09-12）：interface完整窗口分类执行306项断言；排序、牌面费用、翻面后筛选、重复UID、获得顺序和浏览状态不变的新增／既有断言全部通过。该分类另有8项失败，涉及magic_hand_gift图片独立性、紧缚爱好版式、长文滚动、乌龟壳教程搜索及旧战斗拖动击杀预期；未修改或删除这些失败断言。最终源码指纹稳定，报告build/checks/20260911T140343546-54488/summary.json，分类整体状态仍为failed，不称为全部通过。仅运行interface窗口分类，未打包。

名称字序由tools/generate-chinese-collation.ps1按zh-CN生成，固定U+4E00—U+9FFF排序表随脚本资源导出，PC／Android运行时无需系统语言API、联网或新增依赖；表外字符使用原自然字符顺序。浏览卡片排序复用原控件并移动位置，翻面不销毁同一张卡，避免旧焦点／悬停引用失效。费用来源是GameView.card_texts.face_costs，稀有度仅保留独立筛选功能。

## 拖牌至不可选部位的悬浮提示修正（2026-09-12）

拖牌经过无目标的身体部位时，不再生成空的三列装备选择框；改为正常宽度的部位提示“这张牌不能用于该部位”，显示时使用实际部位名称。移到可用部位恢复正式目标列表，移回无效部位清除旧列表；取消或无效位置松手清理提示，不提交行动。过期操作仍要求重新选择。悬浮窗统一把全局锚点换算到界面本地坐标，窗口缩放后继续对齐；卡牌及基础动作拖动预览显示在左侧栏上方，偏离鼠标且不拦截目标。

RuleChangePackage：仅UI候选消费、浮窗位置、显示层级及临时控件清理；复用原正式候选、版本校验和提交。玩法数值、部位资格、事务、资源、回合、牌区、随机、日志、存档及十四规则交互轴不变，无迁移。玩家可见变化为准确的部位不可选原因，机械日志与叙事N/A（悬停不执行动作）。

验收：targeting／intent完整窗口专项132项断言通过，源码指纹稳定；覆盖普通及缩放布局、重复悬停、无效→有效→无效目标切换、拖动预览层级和无效松手状态不变。报告build/checks/20260911T140442769-57360/summary.json；截图build/ui-unavailable-body-drag.png已人工检查。未重打包，现有v0.14成品不包含本次后续修正。

## v0.14原位更新发布包（2026-09-12）

按用户要求将当前源码重新导出，仍命名v0.14，已替换outputs/紧缚尖塔demo-v0.14-Windows64.zip与紧缚尖塔demo-v0.14-Android.zip。包含拖牌至不可选部位的悬浮提示、缩放定位与拖动预览层级修正以及导出时当前工作区内容；不修改版本。Windows仍为0.14.0.0，Android仍为versionName 0.14／versionCode 6、org.magic.spire与原发布签名，ARM64＋ARMv7。

导出批次20260912-v014-refresh，两端源码清单一致且导出期间稳定。Windows成品资源／启动检查通过（build/package-check-20260911T142745493）；APK签名／对齐／版本及资源检查通过（build/android-20260912-v014-refresh、build/android-probe-20260911T142830397）。逐文件检查ZIP内容与导出目录SHA256一致，原样保留版本更新内容.txt且无开始前请读／清读、存档或签名私钥；更新outputs/spire-v0.14-checksums.json。仅打包和成品检查，无完整玩法回归或安卓真机安装测试。

当前独立APK位于outputs/spire-v0.14-android-20260912-v014-refresh/spire-v0.14.apk；Windows展开目录为outputs/spire-v0.14-windows-x64-20260912-v014-refresh。旧带日期导出目录仅保留为历史归档，同名正式ZIP已替换。

## 魔术手自由面：两次自由态手部体术（2026-09-12）

按用户新要求，自由面由闪避2改为接下来2次手部体术忽略拘束限制和减益，按自由态结算。适用于肘击／近身短打及连击，每个完整行动只用1次；近身短打的腿部拘束门槛同样忽略。保留站姿、能量、每回合使用次数、无力化、敌方嘲讽／减伤，以及力量、蓄力和其他正常增益。踢击、火球、卡牌挣扎和装备操作不消耗次数，也不获得这项自由态效果。重复成功使用刷新至2次，不累加；跨回合和战斗→整备保留，本场整备结束或被收押时清除。真实装备与角色限制不修改。

普通魔术手和欧内的手赠牌共用定义；1能量、20基础魔力、嘴部施法及失败规则不变。拘束面降紧3／超级顺延不变，原版消耗、赠牌正常弃置不变。卡面简写“下2次手部体术无视拘束限制与减益（按自由态）”；状态图标使用卡图并展示剩余次数，完整说明保留触发范围、每次完整攻击计一次和刷新规则；成功体术日志报告剩余次数。

RuleChangePackage：新增card_buff_uses计数映射，与card_buffs共同校验，由共享grant_buff与consume_attack_buffs更新；自由态仅作用正式体术候选计算，执行继续原支付／版本复核／多段伤害管线。Snapshot.REVISION升40，不兼容旧档，不新增迁移或随机域。影响状态、候选、体术数值、提交与结束清理、日志、卡面／状态／图鉴；十四交互轴中的部位拘束资格、资源、增益、阶段、版本与多段计数覆盖，装备层级／材质／锁／环境／地图与施加逻辑不改。用例归card_expansion及现有card_power窗口，复核basic_attacks／casting／status／guard／relics／architecture；存档专项依项目约定延期，不重新打包。

魔术手自由面验收（2026-09-12）：card_expansion／relics／basic_attacks／architecture／casting／status／guard完整规则分类2434项断言通过，报告build/checks/20260912T083032727-25604/summary.json，源码指纹稳定。窗口首次新增点击用例未先切换肘击形态，导致2项断言失败；仅修正测试为先原生右键切连击再点击当前目标，未改动玩法逻辑。随后card_power完整窗口252项全部通过且源码稳定，报告build/checks/20260912T083312287-25388/summary.json；包含普通／赠牌实际效果、双面文案、状态图标2→1、多段只计一次、费用和原拘束面回归。截图build/ui-magic-hand-free.png已检查，显示正式肘击连击4×2及攻击反馈；次数由原生操作后的状态图标断言验证。未运行整体回归或重打包。

## 第0层开局选择（2026-09-12）

正式新局在第0层提供四类选项：卡牌、资源／遗物、代价交换、初始遗物交换。前三类各随机出现一项，第四类固定失去余烬护符并获得随机Boss遗物。只显示分类和效果，不另命名；可在选择前查看塔路或直接出发，不能先进入第一层再回头领取。练习场和续塔不重复发放开局奖励。

卡牌池：移除1张牌；变化1张基础牌（普通／罕见）；罕见卡三选一。资源池：魔瓶＋40；魔力上限＋10并恢复10；随机普通遗物；道具容量永久＋1且随机药剂1瓶。代价池：魔力上限－10换稀有卡三选一；自身魔力－40换随机稀有遗物；随机诅咒换魔瓶＋100；加入用力！／顾涌！各1换普通／罕见遗物各1；佩戴中级、紧度3、无锁手腕绳索换随机罕见遗物。Boss拾取沿现有正式流程，包含相应代价与套娃后续领取。

入场以种子冻结四项、奖励牌、变化目标对应结果和随机遗物／药剂／诅咒；查看与场景SL不重抽。删牌／变化／三选一进入共用风格的奖励选牌弹窗；进入选牌后不可跳过，最终选择才原子支付代价并获得奖励。零回合，不触发战斗开始／结束收益，保留原地图层号。选牌与结果只显示只读投影，派发正式departure候选，经现有版本复核和回滚提交。

RuleChangePackage：data/departure.gd为选项权威；core/departure.gd负责生成、候选、原子效果、投影和校验；state.departure保存冻结选项、选择阶段、结果及永久容量修正，快照修订41，不适配旧档。影响状态、候选、事务、资源、牌区、装备施加、遗物拾取、当前快照、UI／日志；随机结果使用独立种子本地流，不推进战斗、事件、卡牌稀有度修正等现有随机域。十四交互轴中阶段／资源／牌区／装备来源受影响；部位层级、材料、锁、姿势、伤害、施法、地图连线与战斗规则不改。新用例归tower，窗口归home，兼顾services／rewards／relics／content／architecture交叉验证；覆盖全部选项、正例、无效目标／不足资源反例、重复提交、回滚、只读、SL冻结和练习隔离。本次不打包。

第0层验证完成：`build/checks/20260912T094324477-20100/summary.json`状态passed，运行前后源码指纹一致。完整受影响分类relics／architecture／content／runner／services／rewards／tower（Exhaustive）共4900条规则断言通过，包含201个地图种子和128个开局种子；home／tower_progression／rewards窗口共360条断言通过。原生点击验证四选一、塔路预览返回、跳过、变化选牌、结果出发与中级紧度3无锁手腕绳索；`build/ui-departure.png`及`build/ui-departure-cards.png`已检查。所有Boss拾取代价与套娃返回、快照冻结、无效目标／资源不足、重复提交及原子性均纳入。首轮UI测试脚本参数错误已修正，首轮有并行源码变化，不作为最终通过证据。本次仅更新源码，发布包未替换。

2026-09-12葫芦酒壶说明精简：统一detail改为“拾取时，将一张「般若汤-其一」加入卡组。”，删除固有和后续饮用的扩展解释。RuleChangePackage仅玩家可见遗物说明，图鉴／奖励／悬停共用注册表；拾取赠牌、固有词条、卡牌效果、候选／事务／资源／随机／存档及各交互轴均不变，不打包。

## 火球术首发费用（2026-09-12）

每个玩家回合第一次主动使用火球术消耗1能量，之后0能量；魔力费用、次数、伤害与施法条件不变。施法失败已支付费用并计为一次使用；资格不足或过期提交不计。攻击敌人和炫火自解共用首发记录，群体火球仅计一次，免费复放不额外收费。死灰复燃只恢复次数，不重置当回合首发记录。正式新回合／新场次重置，整备按原回合入口重置。

RuleChangePackage：基础攻击配置首发费用，combat新增按攻击类型保存的首发记录；正式候选和自解候选读取统一费用，付款／版本复核／回滚与失败流程保持。更新当前快照修订及严格字段校验，不迁移旧档。UI按钮／悬停／日志复用候选费用，具名规则说明新增一句费用规则。十四交互轴中资源、回合、牌面增益／次数恢复、目标、复放及版本受影响，其余拘束／部位／姿势／锁／材料／环境／伤害／随机规则不变。验证归basic_attacks并回归casting、card_power、enemies、relics及architecture，窗口basic_attacks。不打包。

## 休息房自由面禁用漏判修复（2026-09-12）

汲取自由面及其他self_faces／self_target卡牌此前因自目标提前返回，跳过了休息房自由效果禁用检查。现在Cards.reason先按真实牌面执行休息阶段限制，再检查各类目标。正式候选、提交复核和卡面availability共用同一具体原因“休息房禁止卡牌自由效果。”；禁止打出时不支付、不回魔、不抽牌、不判施法、不写行动日志。汲取拘束面仍为0费回5魔力，战斗／整备自由面仍正常；专心致志第二拘束面不视作自由效果。

RuleChangePackage：修复现有规则遗漏，不新增规则、状态、随机域或存档修订。影响候选、卡面低亮与原因、提交资格；回滚保持全状态不变。资源／抽牌／施法日志只在正式成功提交后出现，禁用不伪造日志；十四交互轴中阶段与真实牌面受影响，身体、层级、锁、材料、姿势、伤害及其他费用不变。测试归card_expansion（汲取及全体自目标自由面、拘束面最近反例、第二拘束面、整备和旧候选复核），UI归siphon，交叉检查casting／card_power／card_growth／services。无旧档适配，不打包。

火球术首发费用验收（2026-09-12）：basic_attacks／casting／card_power／card_expansion／architecture全部通过；含首发1费、后续0费、零能量拒绝首发、过期／缺魔回滚、失败消耗首发、敌人／装备共用、复放只付一次、死灰复燃不重收、换回合／新场重置和当前快照保留。规则共3280项，仅relics中的欧内的手赠牌与原版效果完全相等旧断言失败，其他3279项通过；源码指纹稳定，报告build/checks/20260912T102529922-8212/summary.json。basic_attacks真实窗口52项全部通过，覆盖按钮1→0、零能量禁用首发与第二发可用，源码稳定，报告build/checks/20260912T102529922-6808/summary.json。

初次扩大到enemies的检查遇到新开局流程导致旧弱怪组队路线夹具失败，并在访问缺失enemy_members时中断；该轮源码也发生同期更新，不作为通过记录。相关血量攻击序列已同步首发费用：30血绳索承受两火球后余6血、余2能量；60血绳蛇承受两火球＋短打后余18血、余0能量。未修改无关敌人流程。当前快照修订42，不做旧档迁移；未运行全项目测试或打包。

本次修复验收：`build/checks/20260912T102345750-20100`的card_power／card_expansion／card_growth／casting／services共2780条规则断言通过，card_power窗口262条通过。汲取窗口夹具改为真实右键翻面（避免首次绘制按抽牌面覆盖预设值）后，`build/checks/20260912T102734302-42220/summary.json`的siphon完整窗口9条通过，源码指纹稳定；截图`build/ui-siphon-rest-blocked.png`已检查。验证自由面低亮原因、点击全状态不变，以及翻回拘束面正常回5魔力。原设备练习测试改用合法拘束面继续覆盖开信刀，不删除覆盖；两项火球费用断言同步项目最新首发1能量规则，未改火球运行时。最终没有再次运行存档专项或打包。

2026-09-12卡牌音乐：card_power／architecture／content完整分类1442项、display窗口45项全部通过，源码指纹一致，报告build/checks/20260912T103918574-43584/summary.json。覆盖两种卡双面正式提交、过期／不足资源／失败不播、监狱单次、整备休息静音；窗口验证开关即时停止、音量即时应用、重启偏好、实际点击出牌、渲染不重播、胜利领奖停播、单次自然播放结束与同通道替换。OGG全曲解码无错误；原始FLAC尾部报告一个无效帧，转出时长225.79秒与源声明时长一致。仅专项检查，无整体回归或打包。

声音页截图验收：build/checks/20260912T104107116-12232/summary.json，display完整窗口46项通过（含截图写入检查）、源码指纹一致；已检查build/ui-card-music-settings.png，开关、声音页和带百分比滑条完整显示，无遮挡。

2026-09-12 henshin战斗练习：card_power／architecture／equipment_complete完整规则1521项、home真实窗口46项全部通过，报告build/checks/20260912T104642858-11720/summary.json。覆盖开场7张手牌／12张牌组、首回合4能量、两版本双面正式费用与效果、真实音乐反馈、普通新局隔离、主页选择及实际点击出牌。初检发现普通自由面共需4能量（原3点不足），已仅给练习首回合额外1点后重跑全部受影响分类。未打包。

2026-09-12音乐暂停／续播、重复曲目去重与共用淡入淡出：display完整窗口54项通过，报告build/checks/20260912T105712098-27072/summary.json，源码指纹一致。覆盖开关暂停后的稳定进度、重新开启继续、两版本实际重复出牌不重播、暂停时结束场景不续播、0.65秒淡入进度／终值、切换曲目先淡出、0.6秒战斗结束淡出与反复渲染不重置计时。初检因按固定帧数等待不足真实渐变时长而失败，改用真实计时器等待后重跑完整分类通过；暂停进度检查等待音频混音线程接收暂停再取基线。仅播放器与窗口测试变更，无规则变更，无打包。

2026-09-12音乐结束淡出延长至4秒：display完整窗口55项通过，报告build/checks/20260912T110010272-43716/summary.json。验证领奖弹出后超过1秒仍在递减播放，4秒后清理，重复渲染不重置计时，换曲0.6秒及暂停／续播／重复出牌规则保持。未打包。

2026-09-12鸳鸯戏61秒素材及般若汤-其二：card_power／architecture／content／equipment_complete完整规则1920项、display完整窗口64项全部通过，源码指纹一致，报告build/checks/20260912T111151722-41060/summary.json。素材完整解码61.000秒，首尾六段PCM比对符合1秒线性渐变，记录build/mandarin-duck-audio-check.json。覆盖双面与阶段、过期／饮用阻止不播放、静态／动态说明，练习原生出牌后雨爱→鸳鸯戏→雨爱双向替换、暂停恢复、重复其二不重播、片段边界循环、监狱播放一次自然停止。无需调整共用播放器逻辑，仅新增曲目注册。未运行全项目测试或打包。

2026-09-12音乐练习入口显名：home完整窗口48项通过，报告build/checks/20260912T111636355-43804/summary.json；覆盖菜单入口明确显示henshin／般若汤-其二、原生进入及其二开场在手，未打包。

## 高潮练习（2026-09-12）

“练习与自定义”新增独立“高潮练习”。开场为99快感，正式安装现有`urethral_rod_low`，并通过既有练习抽牌入口额外抽入普通“用力！”。自由面候选仍为正常1费技能；成功提交后，能量支付固定点调用性玩具的既有`energy_gain`，马眼棒按敏感部位倍率增加6快感，再由`Pressure.gain`进入一次高潮并回落至5。手牌清理、魔力损失、下回合乏力、对白／旁白和继续回合全部复用原流程。

错误的专用高潮卡及卡牌`pressure`效果接口已移除。练习外的新局保持0快感且无该装备；没有新增保存字段或随机域。高潮中断期间不再显示投降与蓄力模式切换，既有即时魔瓶和丢弃道具入口保持。

验收：`build/checks/20260912T121519974-12696/summary.json`中architecture／content／equipment_complete／pressure规则共1131项、pressure真实窗口68项全部通过，覆盖99快感、真实特殊装备、普通牌实例、候选只读、过期回滚、实际付费触发、正式高潮结果、无音乐串扰、普通新局隔离和原生点击演出。未打包。

## 平板锁默认上锁与标准锁效果（2026-09-13）

平板锁佩戴时继续由正式安装事务写入`locked=true`，装备卡改为正常闭锁图标并明确显示“状态：已上锁”，不再叠加普通特殊装备的不可上锁红叉。锁体沿用项目标准上锁规则；因为平板锁只接受滑脱／魔法滑脱与开锁，没有加固带时，上锁状态不会额外关闭滑脱路线。锁体仍上锁且专属加固带存在时，滑脱由结构原因明确阻止；正式开锁后，任意正数滑脱伤害直接解除整件并级联清除加固带。

RuleChangePackage补充：仅修正锁状态、滑脱候选、正式损伤提交、装备只读投影及玩家可见说明；自动安装、单向升级、快感上限／倍率、滑精、随机池、概率归还和存档字段保持原设计。加固带直接损伤仍只接受固定切割类道具。新增正例覆盖中级锁无加固带时的标准滑脱路线、三级锁加固带阻止、开锁后越过加固带解除；最近反例覆盖直接调用也不能绕过仍上锁的加固带。图鉴补齐“开锁”方法显示名。

验证：`build/checks/20260912T140108376-45856/summary.json`中architecture／content／special_equipment规则696项、special_equipment窗口51项全部通过且源码指纹稳定；随后加入明确“已上锁”文字后，`build/checks/20260912T140246354-43168/summary.json`的special_equipment窗口51项再次通过。敌人完整分类1470项通过，报告`build/checks/20260912T135512272-43824/summary.json`。首轮敌人检查暴露图鉴缺少`unlock`显示名并已修复，失败轮不作通过证据。已人工检查`build/ui-118-chastity-lock.png`，锁体显示正常闭锁图标，加固带仍作为独立不可上锁组件显示。本次未运行全项目回归，未打包。

## 平板锁拘束站姿差分（2026-09-13）

四张用户原图由本地脚本生成平板锁替换底图、加固带透明层和马眼棒透明层；素材配对、原路径及SHA-256见`assets/art/equipment-special-layers.json`。只读投影按真实锁体、加固带、独立马眼棒或内置导尿管选择图层。左侧装备立绘和战斗站姿共用组合器；无肢体拘束的自由立绘、扶她出去固定立绘、坐姿与躺姿保持原素材。

`tools/build_equipment_special_layers.py`重组暗色背景下的大腿分段，只有12个抗锯齿边缘像素超过3级色差阈值，低于32像素门槛；并用明确背景种子清除锁体右侧6×10像素白底碎点。人工检查`build/ui-special-equipment-portrait-comparison.png`未见大腿切片接缝、白边或漂浮残影。最终稳定检查`build/checks/20260912T144744199-10788/summary.json`：architecture 69项、equipment_art／hero_art窗口212项全部通过（含三张截图写入检查）。此前`build/checks/20260912T143000877-40576`的特殊装备与架构344项、立绘窗口209项通过，但随后同工作区有其他源码写入，因此仅作过程记录；写入稳定后的special_equipment分类存在另一批“批量替换保护”4条失败，本批没有修改或删除这些断言。未运行全项目回归，未打包。

## 平板锁命名与专项练习（2026-09-13）

该装备家族在源码、界面文案与维护文档中的玩家可见名称已统一为“平板锁”，内部稳定ID保持不变。新增`plate_lock`练习：正式6回合休息场景开场安装高级3档负数跳蛋锁（导尿管），自动上锁并附加高级平板锁加固带；额外抽入术式解锁，保留小石片、锯条和3次挂钩。练习显示动态130点快感上限并在首回合按正式持续刺激增加24.48快感。普通新局、随机池和其他练习不注入这组装备。

RuleChangePackage：练习特殊装备夹具新增可选紧度传递，安装仍调用正式`_install_special`，不新增旁路候选、事务、状态、随机或存档字段。影响练习注册、初始化、玩家可见名称、练习说明、装备详情和主页入口；普通装备层级、敌人、监狱、快感公式、解除规则和地图不变。规则用例覆盖真实3档、上锁、加固带所属、快感上限、额外开场牌、合法状态和练习隔离；窗口用例真实滚动并点击入口，核对身体栏两件装备、明确“已上锁”与新名称。

最终稳定门禁：`build/checks/20260912T142935029-42752/summary.json`完成资源导入，architecture／content／special_equipment共716项规则断言及home／special_equipment共110项窗口断言全部通过，运行前后源码指纹一致。截图专项`build/checks/20260912T143110689-38292/summary.json`的home 60项通过，已人工检查`build/ui-119-plate-lock-practice.png`；装备立绘专项`build/checks/20260912T143256096-24376/summary.json`共168项通过。未运行全项目回归，未打包。

## 神秘女人雕像的平板锁限制（2026-09-13）

“神秘女人的雕像”事件中，“使用飞机杯”在佩戴普通、导尿管型或高级跳蛋型平板锁时仍显示但不可选择。按钮本身不追加规则注语；悬浮或键盘聚焦时，共用二级说明窗显示“平板锁封住了肉棒，无法插进浅盘上的飞机杯。”。已经开锁但仍佩戴的平板锁继续阻止该选项，实际取下后恢复；其他性玩具不误判。“收集魔力”与“离开”始终沿原资格和效果。

RuleChangePackage：选项内容声明新增`availability.kind=no_chastity_lock`白名单，按正式特殊装备族判断，随普通／多阶段选项冻结并由当前快照校验。候选生成和正式执行共同复核；过期或直接提交均不能绕过，拒绝时资源、装备、回合、随机和事件流程保持不变。候选只读投影以`reason_surface=secondary`指定共用说明窗，Godot界面不从事件ID、装备名称或正文猜条件，也不把原因重复到日志、叙事或注语。十四交互轴中仅特殊装备存在性、事件资格、冻结方案、版本复核及玩家可见禁用原因受影响；平板锁本身的部位、容量、紧度、锁、耐久、快感、解除，事件奖励、卡组、姿势、地图、敌人和其他随机域不变。无新增持久状态或旧档迁移，不打包。

稳定门禁：`build/checks/20260912T145340271-46252/summary.json`完成资源导入，content／event_flow规则721项、events真实窗口180项全部通过，运行前后源码指纹一致。另由内容包检查确认12个文件全部通过。未运行全项目回归，未打包。

## 炫火拘束面卡面措辞（2026-09-13）

炫火拘束面卡面改为“火球现在可以对拘束具使用,但是伤害减半”。仅替换卡面与图鉴共用正文；正式资格仍只生成当前合法最外层拘束具目标，实际伤害继续乘0.5，并与敌人火球共用次数、施法与付款。候选、事务、数值、日志、资源、回合、随机、存档及十四交互轴均未改变，无迁移、不打包。`card_power`窗口加入逐字断言，内容注册复核归`content`。

稳定门禁：`build/checks/20260912T154052235-16308/summary.json`完成资源导入，card_power／content规则1429项及card_power真实窗口262项全部通过，运行前后源码指纹一致。

## 事件平板锁正文差分（2026-09-13）

内容事件新增通用`report_variants/source_variants`，当前条件`equipped_special_family`只读取仍在佩戴的特殊装备族，并在进入事件／阶段时冻结为普通正文。缚疗修女“净化”、魅魔三局赌牌第三局及魔力典当铺三项交易现已覆盖平板锁：肉棒不能勃起，只能在锁下顶动，人物从短暂惊讶转为改用乳房与小穴刺激，高潮后的精液从锁具下流出。赌牌失败的第二次高潮、典当铺三项原高潮次数及固定性玩具安装后果保持不变。未佩戴平板锁时，所有原有正文与机械效果保持。

专项验证覆盖修女分支、赌牌成功／失败两种冻结结果、典当铺小额／大额／追加玩具三项交易、一次／两次高潮、旧肉棒刺激正文不混入、未知装备族拒绝及来源长度边界。最终`build/checks/20260912T154106594-46604/summary.json`中content／events共633项规则断言全部通过；没有修改UI组件，因此未追加截图或全窗口回归。未打包。

## 2026-09-13 诅咒平板锁分支

- 新增规则与边界见 [诅咒平板锁](cursed-plate-lock.md)。覆盖占位替换、三档上锁、无限持续、能量上限、定向／群体／手动／henshin解除保护、无效提交回滚、替换阻止、普通与饱和胜利反例、Boss自动钥匙整件取下及附属清理、一次性进度、当前快照恢复与损坏拒绝、生成池隔离、普通锁原规则不变。
- 稳定规则报告：`build/checks/20260912T154511540-39412/summary.json`。card_power、relics、replacement、architecture、encyclopedia、special_equipment、services、rewards、guard九类通过；event_flow六项失败，均为普通负数平板锁的典当铺既有文案／来源差分断言，使用的不是新增诅咒类型。本次未改这些正文，也未把该分类或本批完整规则报告标为通过。合计4071/4077项通过。
- 稳定窗口报告：`build/checks/20260912T154641699-38544/summary.json`，encyclopedia、special_equipment共127项通过，包含新遗物图标及自动解锁整件取下说明。
- 先前`20260912T154338189-5400`虽然规则1338项与窗口127项通过，但被标为source_changed，不作为稳定验收依据。本次没有打包或发布。

## 出牌效果完成后再弃置（2026-09-13）

RuleChangePackage：新增内部`play`牌区，非能力牌离开手牌后先在这里完成自身抽牌、追加效果、自动续段和余势复演，再进入弃牌堆或消耗区。该牌不参与自己触发的弃牌重洗；打出仍立即腾出手牌位置。多段牌的`card_chain`与使用中实体一并保存、校验及恢复，结束、主动停止和高潮打断都经统一接口安置实体。Snapshot修订提升至45，不迁移旧档；没有新增随机域或玩家操作入口。

正例覆盖抽牌堆0／弃牌堆0时打出“抽牌1”实际抽0且源牌随后弃置；最近反例覆盖弃牌堆仅有另一张牌时先洗牌并抽取该牌；边界覆盖十张手牌腾位、抽2消耗牌先抽后消耗、多段牌最后一段才弃置、续段保存恢复、高潮中断、缺失使用中实体的损坏快照和过期提交原子回滚。现有牌堆数量与卡牌移动动画读取提交后的牌区和结构化回执，卡面、机械日志与叙事无需新增正文。

第一次合并回归的全部断言虽通过，但运行期间同工作区另有源码更新，报告`build/checks/20260912T160351721-39796/summary.json`按门禁标为`source_changed`，未作为验收依据。文件稳定后以合并源码重跑：`build/checks/20260912T160922447-42152/summary.json`中card_power、card_expansion、relics、item_discard、architecture、casting、services、persistence、rewards、events、core、prison、pressure、tower共7006项规则断言，以及card_power真实窗口264项断言全部通过；运行前后源码指纹同为`DB513C2A1D2960B761A825C600752A4C6B8AD395C4D59F90476D878ABD6FCC14`。未运行全项目回归，未打包。
## 2026-09-13 商店平板锁结账

平板锁下的自身魔力商品付款、魔瓶旁路、解除服务例外、整件与加固带清理、专用文案上下文、原付款图片复用及店主`zako`称呼已由`shop_release／services`规则570项和`services`窗口248项验证。源码指纹稳定，报告：`build/checks/20260912T163036795-43524/summary.json`。未运行全项目回归，未打包。

## 2026-09-13 能力叠加开放 — Verified

猛火下山、紧缚爱好、拘束之拥两面、灵活变通两面、开信刀play两面与炫火自由面已开放重复叠加。沿现有stackable配置和能力实体累计，无新增运行时接口或状态字段；卡牌说明、能力状态详情与规则文档同步。紧缚爱好的属性与固定快感同时累加，开信刀各张独立计数，炫火保留已用次数且拘束面仍不可重复。

完整分类命令：`tools/check.ps1 -Suite card_power,content -UI -UISuite card_power -TimeoutSeconds 300`。规则1531项、窗口266项全部通过，报告为`build/checks/20260912T163230139-15840/summary.json`，状态passed，源码指纹稳定。覆盖实际重复支付与收益、无效版本回滚、双倍回合资源／抽牌／属性／快感、逐层开信刀伤害、清场、炫火当回合／下一回合与真实窗口连续使用及层数。前两轮新增测试夹具修正了耐久上限、提交后旧引用和敌方阶段新增装备的干扰；最终完整分类重新通过。未打包。
## v0.15 发布完成（2026-09-13）

按用户要求将当前工作区打包为Windows／Android 0.15。Windows文件及产品版本0.15.0.0；Android versionName 0.15、versionCode 7，org.magic.spire及既有发布签名保持，支持ARM64＋ARMv7。

交付：项目根outputs/紧缚尖塔demo-v0.15-Windows64.zip、outputs/紧缚尖塔demo-v0.15-Android.zip；独立APK为outputs/spire-v0.15-android-20260913-v015/spire-v0.15.apk。校验清单outputs/spire-v0.15-checksums.json。版本更新内容.txt原样加入两端，正文及ZIP内SHA256与原件一致。

导出批次20260913-v015；两端运行源码清单一致，各自导出期间稳定。Windows包资源及成品启动检查通过（build/package-check-20260912T163957862）；Android发布签名／对齐／版本／内容包哈希检查通过（build/android-20260913-v015），包内资源探针通过（build/android-probe-20260912T163957866）。ZIP已逐文件检查数量、长度及SHA256；无存档、个人设置、私钥或开发目录。复核脚本build/finalize-v015.ps1。仅版本与打包配置变更，未重跑完整玩法回归，未做安卓真机安装测试。

## 2026-09-13 本地化框架 — Verified（框架范围）

固定ID／中文资源／空日语资源、独立语言设置、命名参数与中文回退已接通。主页主要按钮、共用关闭按钮、显示／声音设置是首批接线；键位正文、卡牌、装备、事件、商店、对白与日志的全文迁移不属于本轮完成范围，实际日语译文0条。规则、存档快照、费用、行动和随机不变，未打包。

资源导入通过；最终完整分类命令：`tools/check.ps1 -Suite localization,architecture,runner -UI -UISuite localization,home,display -Screenshots ui-localization-framework.png -TimeoutSeconds 300`。规则492项、窗口196项断言通过，报告`build/checks/20260912T165431453-3008/summary.json`状态passed，源码指纹稳定。覆盖源文变更、缺译、未知ID、参数顺序与重复次数、字面大括号、非法参数、非法包原子拒绝、缺失／损坏文件中文回退、偏好保存／重读／非法值、真实窗口切换与音量模板更新、切换前后快照和候选不变。伪文本只在测试内存中使用，未写入日语包。

`build/ui-localization-framework.png`已人工查看，显示设置中的语言、窗口模式、分辨率与速度完整可见。Python离线提取器自检及资源校验通过，生成`build/localization/inventory.json`：30条已登记中文、日语0条、24处可直接识别的固定调用、5005处待审核中文线索；循环调用与拼接仍需人工审查，数量不是全文覆盖率。未运行全项目回归或安卓真机测试。

## 2026-09-13 英文版 — 验证范围

在既有框架上新增`en_US`及English设置项。31条共用语义消息全部提供英文；全运行时盘点为5029处中文线索、4270个不同源串，兼容目录共4296条（包含动态与测试覆盖所需模板）。最终显示桥覆盖控件、卡面延迟刷新、商店、事件、战斗、状态、日志、对白与叙事；动态格式参数也在代入前递归本地化。日语资源仍为空并回退中文。

RuleChangePackage：本批只新增显示资源、只读解析与语言相关界面布局。切换语言不提交Command，不改变GameState、候选、事务、资源、装备、卡组、敌人、事件进度、回合、随机或快照；无存档迁移。核心UI及代表性正文已人工整理，其余长篇正文是第一轮英文稿。非法／缺失／源文过期译文继续原子拒绝并回退中文；英文运行时不依赖翻译模型或网络。

验证覆盖英文资源完整性、动态模板与嵌套参数、非法包、设置保存、切换前后玩法不变、主页／设置／商店／事件／战斗代表页面无中文字符、卡面异步缩字不退回中文、商店长台词在固定区域滚动，以及切回中文。最终报告`build/checks/20260912T191101222-12852/summary.json`状态passed：资源导入通过，localization／architecture／runner共500项规则断言及localization／home／display／services／events／card_power共907项窗口断言全部通过，运行前后源码指纹一致。四张英文截图已人工验收。未运行全项目回归、安卓真机测试或打包。

## 2026-09-13 英文本地化跟进

最新资源随同期新增界面和卡牌扩展为38/38条语义英文、4536条兼容英文；盘点覆盖5289处运行时中文、4501个不同源串。人工优先表为528条，跟进修正高频词义错误（Potion／Scroll／Relic／Withdraw等）、整套卡牌名、Bound／Free牌面、动态删牌价格、汇流／共享命运／猛火下山／火焰精通等卡面正文，以及魅魔和平板锁段落的人称与句法。其余长篇正文仍按第一轮英文稿处理。

生成器改为仅在出现未缓存新源文时加载离线翻译依赖；纯人工校订可直接从缓存重建。同期新增中文先重新盘点再补入目录，英文资源不存在空正文、中文残留或重复ID。只改变显示资源与离线维护工具，不改变规则、候选、事务、数值、回合、随机或存档。

首次关联检查`build/checks/20260913T082642852-6928/summary.json`在运行中遇到同期新增的汇流卡面并按门禁标记失败／source_changed，不作为通过证据。补齐新增动态正文后，英文专项`build/checks/20260913T083543254-53844/summary.json`通过66项规则与55项窗口断言；最终完整关联报告`build/checks/20260913T084158453-54148/summary.json`状态passed，localization／architecture／runner共538项规则断言及localization／card_power／display／home／services／events共983项窗口断言全部通过，运行前后源码指纹一致。最新商店截图已人工检查，卡名、牌面、价格与长对白正常。未运行全项目回归、安卓真机测试或打包。


## 2026-09-13 施法失败返还魔力 — Verified（施法专项）

失败施法返还本次实际耗魔的50%，自身与临时魔力分别退回原池；能量与次数照常消耗，原牌留手。固定兑换同样适用，免费复放不产生退款；耗魔触发仍按退款前实际付款累计。规则包见AGENTS.md和docs/card-framework.md。本轮未打包、未提交或更新GitHub Release。

稳定专项：`tools/check.ps1 -Suite casting -TimeoutSeconds 300`，454项规则断言通过，报告`build/checks/20260913T030928178-27416/summary.json`；`tools/check.ps1 -UIOnly -UISuite casting -Screenshots ui-107-card-casting-tooltip.png -TimeoutSeconds 300`，45项窗口断言通过，报告`build/checks/20260913T030844273-39912/summary.json`。两轮状态均passed且源码指纹稳定。验证两池独立／混合支付、零耗魔、固定兑换、分数退款、免费复放、旧版本回滚、成功全额付款、失败留牌、火球次数、耗魔累计、退款日志与资源动画；截图已人工检查，提示完整可读。

关联分类card_power／card_expansion／relics／basic_attacks／content／exploration／casting／prison的4821项断言在`build/checks/20260913T030458667-34324/check-rules.log`全部通过，但运行期间其他任务修改源码，报告标记source_changed，不作为稳定整轮或全项目通过证明。其窗口阶段发现火球悬浮提示缺失，已补充后以上述稳定窗口专项复核。
`build/checks/20260913T030815769-28628`再次完成关联4821项断言，全部通过；期间补齐并统一火球提示措辞，仍标记source_changed。最终施法规则与窗口的稳定报告以上述030928／030844两轮为准。


## 2026-09-13 火球术失败保留次数 — Verified

火球术只有成功施放才扣每回合次数；敌人、群体及炫火自解共用。失败仍支付当前能量、返还50%实际耗魔，并写明“火球术次数未消耗”。首发能量记录与使用触发保持，免费复放不额外扣次数；候选说明、悬浮提示、教程及规则对照已同步。

`tools/check.ps1 -Suite casting,basic_attacks,card_power -UI -UISuite casting,basic_attacks -KeepGoing -TimeoutSeconds 300`：1791项规则断言、96项窗口断言全部通过，报告`build/checks/20260913T031340568-17600/summary.json`状态passed且源码指纹稳定。新增连续3次失败仍保留全部次数、成功重试仅扣1次及失败日志检查；同步群体／自解失败断言，回归首发能量、使用抽牌与免费复放。未打包或上传。

## 2026-09-13 非战斗魔力恢复

- 魔力药剂以unrestricted_outside_battle声明阶段豁免，Consumables统一解释药剂／魔瓶取出资格及描述。非战斗选择页额外补充正式候选，避免与正常行动页重复；开局奖励投影只接收departure候选，不把药剂或魔瓶操作混入奖励。实际战斗、其他药剂、嘴部半效／取整、满魔力拒绝、单次消耗、魔瓶扣量与存入限制不变。无存档字段或随机域变更。
- 新增mana_recovery_cases，归consumables，覆盖战斗反例与领奖、整备、休息选择／休息、地图、商店、牢房的实际提交；检查嘴部半效、无回合／阶段／随机推进、候选唯一、过期回滚与满魔力拒绝。开局及套娃中实际恢复，保持冻结奖励，候选不混进奖励列表。departure原封闭候选断言相应更新并继续验证不能跳过选择。
- 稳定规则：build/checks/20260913T031640968-44048/summary.json中consumables、architecture、tower共572项通过。此前services、rewards、prison分类亦通过（20260913T031007856-12748）；该早期报告tower两项旧候选断言失败，不能作为整批通过报告。
- 稳定窗口：20260913T031640968-44048的encyclopedia与home通过；consumables最初未展开“使用说明”便要求其正文可见，修正为实际点击展开后，在build/checks/20260913T032036209-26548/summary.json中49项通过。验证领奖页实际用药、魔瓶取出、10／5点嘴部减效与原阶段保持。未打包。


## 2026-09-13 熟练而已、牵扯与唯一 — Verified

新增稀有2费能力practiced及独立SVG卡图，加入稀有奖励／商店与图鉴。自由面在成功打出其他实体牌后累计3个百分点的独立成功率加值，回合开始归零；拘束面在乘区、加区之后提供75%最低成功率，真实手部等结构要求仍有效。魔法类型牌无论零费、非施法面或实际施法成败都额外牵扯一次，按1能量折算而不扣能量；原付款触发仍单独结算。两面可共存，各自唯一，复放不得倍增唯一能力。词条、候选、状态进度、卡面、教程及规则文档同步；仅新增对应能力实体计数字段及严格校验，不迁移旧档，不打包或上传。

最终命令：`tools/check.ps1 -Suite card_power,casting,pressure,guard,curses,content,persistence,special_equipment,architecture -UI -UISuite card_power,casting,encyclopedia -Screenshots ui-practiced-card.png,ui-practiced-power.png -KeepGoing -TimeoutSeconds 300`。报告`build/checks/20260913T034345417-2100/summary.json`状态passed，运行前后源码指纹稳定。规则3811项、窗口392项断言全部通过。

新增practiced_cases归card_power并随其交叉分类接入；practiced_ui_cases归card_power窗口。覆盖本牌不自计、成功／失败计牌、独立加算与现有火球加值相加、100%上限、75%后置保底、口部零倍率／手部真阻止、回合重置、场次清理、双面共存／同面拒绝、复放唯一、坏档与过期事务回滚、零费和有费用魔法的额外牵扯、固定火球／技能反例，以及装备、手牌、无人机点数、魅魔警卫敏感度的真实触发。卡面截图已人工检查，名称、图标、关键词与完整悬浮说明可读；能力截图记录真实点击后的计数增长。同步另一项已确认稀有度变化的汲取力量UI测试预期（罕见→稀有），未改其规则。
## 2026-09-13 Boss额外80魔瓶魔力待领取奖励

RuleChangePackage：Balance.BOSS_FLASK_MANA=80，战斗胜利冻结battle_flask_drop，沿原reward候选／正式提交／reward_claimed接入flask分类；奖励页与机械日志说明全额存入魔瓶。击败、领奖及整备依旧为三个阶段，饱和结束、自行离场、普通战与监狱出口战排除。界面复用奖励行与原魔瓶SVG，四行时调整间距和页脚位置。当前快照49严格检查金额与阶段；修正Boss遗物保存校验读取待恢复存档的房间事实，而不是尚未加载地图的校验实例。

受影响：奖励冻结、领取资格、魔瓶数值、版本复核／重复领取回滚、当前保存恢复、列表及日志。十四交互轴中阶段、资源与存档／事务受影响；卡牌／遗物／道具原抽取与领取、身体部位、层级、锁、材料、姿势、触及、伤害、随机域、回合费用与整备效果不变。没有独立叙事事件，奖励领取沿现有机械反馈；无旧档迁移、不打包。

在现有rewards案例添加真实伤害击败、四奖励同屏、未领取不加魔力、超过自身上限仍全额存入、无资源／回合／随机变化、过期及重复提交、保存前后领取状态、离开放弃及非Boss／饱和／自行离场反例。rewards窗口复用Boss领取流程，检查第四行文字／按钮、真实点击及与继续按钮的边界，保留卡牌／遗物后续领取回归。

最终rewards／persistence规则1127项、rewards窗口304项断言全部通过，报告build/checks/20260913T041058186-17360/summary.json；因同期其他源码修改，整轮状态为source_changed，不能标记稳定版本门禁通过。前轮build/checks/20260913T040750850-39652额外包含截图断言，窗口305项通过但同样source_changed；已人工检查build/ui-boss-flask-reward.png，四行及继续按钮完整可见。首次relics／architecture分类通过；发现的旧快感窗口断言已按完全自由时回合末－2同步。本轮未打包，未运行全项目回归。


## 2026-09-13 累计准备次数与卡牌调整验收

Verified：魔术手每次增加2次手部体术自由态；余势复演同面每次增加1次复放，下次触发使用对应全部层数，仍按原目标独立施法。两者移除唯一，次数与状态角标、连续牌、可叠加能力和当前存档一致。余火基础6／追加6，右上角读取真实基础费用；魔力涌流自由面魔力预备2；双重解锁退出正式奖励／商店／图鉴。

规则完整分类card_power/card_expansion/architecture/content/casting/persistence/rewards通过4262项断言，报告build/checks/20260913T041256047-42468/summary.json（源码稳定；当轮两个新UI用例因夹具未实际翻面失败）。随后只修正UI测试为实际右键翻面，card_power/status完整窗口通过337项断言，报告build/checks/20260913T041637855-20416/summary.json且源码稳定；前轮encyclopedia/casting窗口另120项通过。没有在规则门禁后修改运行时代码，不宣称全项目回归。

新案例覆盖叠加后真实使用、次数全部消耗、两面独立、能力四次生效、存档、旧版本请求回滚、临时魔力、6/11.9/12付款边界及卡面数据。现有案例同步新计数夹具、余火付款及魔力涌流差异；UI通过真实两次点击检查次数。已查看build/ui-embers-six.png与build/ui-surge-reserve.png，确认−6费用角标及自由面2层魔力预备、−5耗魔／＋10临时魔力分栏。未打包或上传。
## 2026-09-13 诅咒平板锁限时版与抖M专用版

- 默认版复用正式`combat.turn`，确认每场第1—6回合的跳蛋刺激正常触发、第7回合停止，新场第1回合恢复；消耗能量的导尿管刺激及普通有限电量跳蛋保持原规则。
- 高潮后快感保留系数默认在10封顶，连续高潮与非法存档不能越界；主页“抖M专用版”随新局冻结，确认第12回合仍会震动且系数可从10增至11。
- 装备详情与“装备刺激”状态改为逐件显示当前刺激方式、时机、最终数值和`（品质＋紧度）×当前系数`结果；加固带明确无独立刺激。教程、遗物正文、主页提示和快照修订同步，无新增随机域或截图案例。
- 规则门禁：`localization,relics,content,special_equipment`共1484项通过，记录`build/checks/20260913T042650710-44072/summary.json`；`architecture`69项通过，记录`build/checks/20260913T042849428-45660/summary.json`。
- 窗口门禁：`home`95项通过，记录`build/checks/20260913T042734393-7936/summary.json`；`special_equipment`51项通过，记录`build/checks/20260913T042825170-45936/summary.json`。两次均按缩减设置不产出截图。另尝试`display,home`时，新增设置与主页断言均通过，但既有`card_music_ui_cases`出现2项暂停位置失败，因此该次组合报告未计为通过；本批未修改音乐逻辑。


## 2026-09-13 般若汤角标与衍生灌注

Verified。般若汤其一至其四双面＋5角标读取HANNYA_MANA_GAIN，升级回魔也读取该常量；仍为技能、无魔法标签和施法判定。低级／满级实体牌只生成好汤时移除不生效的回魔角标。般若汤衍生灌注两面基础耗魔10，0能量、消耗／虚无与原效果保持；原版灌注不变。

card_power/card_expansion/content完整规则2622项、card_power/encyclopedia窗口359项通过且源码稳定：build/checks/20260913T043013109-48252/summary.json。新增断言覆盖四阶段两面元数据、技能分类／无施法、9魔力拒绝回滚、10魔力实际付款与对应打断、原版反例及真实翻面的＋5／−10显示。回归中同步另一并行改动的平板锁图鉴断言为前6回合，不改其规则；首次运行因该旧断言失败及源码变化不计为通过。本次无存档格式变化，未打包或上传。
## 2026-09-13 自由站姿平板锁差分

RuleChangePackage：新增两个只含原图像素的透明差分资源及可复现本地提取脚本；`SpecialEquipment.portrait_layers`继续作为唯一状态来源。Arena只在自由站姿且投影含平板锁时启用战场自由底图组合，普通自由站姿仍沿原静态图；平板锁显示图2对图1差分，正式加固带存在时追加图3对图2差分。左侧装备栏、受限站姿、坐／躺姿和固定立绘开关保持原逻辑。

本批只影响战场角色立绘表现与资源清单；装备安装、等级、耐久、上锁、加固带生成／解除、部位、快感、候选、事务、回合、随机、存档、日志和叙事均不变，玩家可见机械文案N/A。测试沿真实平板锁二档／三档状态验证底图、层列表及两层显隐，并生成`ui-hero-free-flat-lock.png`及`ui-hero-free-flat-lock-reinforced.png`。最终报告`build/checks/20260913T045020790-42632/summary.json`源码指纹稳定：architecture／special_equipment规则357项、special_equipment／hero_art窗口96项全部通过。本轮不打包。

## 2026-09-13 战场立绘放大与状态左移

RuleChangePackage：战场人物区域由355×302调整为348×390，站姿等比放大约29%，保留脚底502的基线；拖牌命中区域与立绘共用同一矩形，快感、魔力、捕缚条及对白指向同步对齐人物中心。玩家状态图标移至人物左侧单列，纵向溢出可滚动；敌人仍为横排。图标计数、悬停说明、键盘与点击详情沿用原入口。左侧装备肖像与立绘素材不变。

仅影响布局与命中区域；状态数值、装备、身体／姿势／层级／材料／锁／触及、候选资格、费用、事务、回合、事件、随机域和存档均不变。changedUiAndLogs：沿用现有图标及全部说明，日志／叙事文案N/A（无机械行为变化）。新增窗口断言验证站姿放大、资源条居中、各姿势拖牌区一致，以及玩家状态位于立绘左侧且采用纵向容器；原悬停、点击及捕缚窗口同步回归。

Verified：architecture/status完整规则365项、hero_art/status/guard完整窗口147项全部通过，源码指纹稳定，报告`build/checks/20260913T050046749-43652/summary.json`。已查看`build/ui-hero-free-flat-lock-reinforced.png`与`build/ui-status-icons-battle.png`，确认角色完整显示、状态竖排及资源条对齐。本批不打包。


## 2026-09-13 共鸣

Verified：共鸣为罕见1费能力，拘束面唯一、每件有效拘束使魔法耗魔降低5%，动态按现有整件计数，最低0；自由面可叠加，每张在玩家回合开始获得闪避1。两面无施法／耗魔，进入能力区并沿本场整备结束清除；魔法卡和固定火球通过共用费用函数同步候选、卡面与实际付款，固定兑换及非施法追加费用保留原例外。原创SVG插图接入共用卡面及能力状态。

规则card_power/card_expansion/basic_attacks/content/casting/persistence/rewards通过4435项，窗口card_power/encyclopedia通过365项，源码稳定：build/checks/20260913T052357229-47604/summary.json。新增resonance_cases归card_power，无新套件；覆盖0件、普通／复合／特殊计根、装卸动态、唯一重复拒绝与回滚、存档、9.5实际付款／临时优先／4.75失败净支出、20件以上封底、能力清理、两份自由面连续两回合闪避及只读投影。UI实际点击／翻面检查1费、罕见、唯一分面、图标、5%状态、−9.5费用及真实回合闪避。修复新增百分比显示因浮点接近整数而截断的问题；计数上限测试使用分散部位合法装备，未绕过单部位容量。未打包或上传。
## 2026-09-13 拘束之拥自由面叠加回能

RuleChangePackage：按用户最新要求，自由面保持2费，每解除1个真实拘束根抽1张牌并恢复1能量，抽牌与回能均按同面实体能力和power_stacks叠加；拘束面保持1费与下回合抽牌。复用restraint_changed与清理前后根ID差集，回能与抽牌独立，满手仍回能；无新增存档字段。整件复合、独立链接和肩带仍按原物理根计数，部分组件清理、加固和敌人替换移除不算挣脱，重复清理不重复发放。

影响资源收益、能力触发、结构化restraint_energy事件、卡面／图鉴／状态摘要与英文兼容文案；状态显示实际每件抽牌数和能量。候选资格、付款、施法、拘束面、回合／整备生命周期、能量跨战保留、装备部位／层序／材质／锁／姿势／触及／耐久、随机域和存档格式不变，无新增叙事cue。测试沿现有card_power正例、部分复合反例、实际出牌付款、整批解除、两张实体与复放层数、满手、替换无收益、重复清理、到期清除及卡面窗口检查，不另建测试分类；本批不打包。

Verified：architecture/card_power/status/content/equipment/composites/links/shoulder/replacement/localization完整规则2712项、card_power/status完整窗口347项全部通过；最终报告`build/checks/20260913T053050112-49900/summary.json`。初次运行使用旧的唯一回能要求，且多层夹具修改了事务提交前的旧引用，2项断言失败；已按最终可叠加要求重写断言，并修正为通过uid取得当前能力实体，完整重跑上述范围。未新增截图、运行存档专项或打包。


## 2026-09-13 汇流

Verified（卡牌扩展／图鉴专项）。新增普通0费技能：拘束面按当前佩戴整件数恢复自身魔力；自由面获得floor(件数/2)点本回合力量，可累加，出牌后装卸不改变已获加值。右上角回魔数值与正文共用worn_resource和正式计件，无装备显示＋0；自由面无虚假魔力角标，静态图鉴无角色时用＋X说明。turn_strength沿正式力量入口参与挣扎和体术，回合／场次清理归零；当前快照51严格保存非负整数，不改永久力量，不迁移旧档。普通池／图鉴、SVG、资源日志、到期日志及力量详情同步。

最终稳定分类card_expansion通过1047项、encyclopedia窗口76项，报告build/checks/20260913T054646239-50924/summary.json。更广的card_power/card_expansion/basic_attacks/content/persistence/rewards规则4081项和card_power/encyclopedia窗口370项均通过，但报告build/checks/20260913T054218954-49336/summary.json为source_changed（并行修改ui/main.gd、道具界面用例与英文资源／生成器），不宣称该整轮稳定或全项目通过。汇流实际点击、翻面及＋0→＋3角标／力量正文的窗口断言在两轮均通过；本任务运行时代码随后未修改。初次装卸断言使用提交前旧对象，已改为按装备ID读取当前实体。

测试覆盖0—4件奇偶、普通／复合／特殊整根、重复和装备变化、正式攻击数值／永久力量不变、下一回合清除、资源封顶、临时魔力不变、版本回滚、存档及非法负值／零除数。现有分类内接线，无新套件。未打包或上传。

## 2026-09-13 战场怪物放大

Implemented，界面断言通过。小型怪物264×216（原220×180），高立绘高度288（原270）；敌人槽280宽，按舞台宽度自动缩放，意图／名称／血条／状态留出间距，拖动接收区跟随立绘。双怪实际画面与守卫画面已查看：build/ui-enlarged-monsters.png、build/ui-34-guard-intent.png。规则、数值、目标ID、文案和存档均不变；规则对照见first-floor-enemy-library.md，变更包见AGENTS.md。

完整display/enemies/guard窗口两轮均无失败：首轮351项（含截图），build/checks/20260913T055302282-42964/summary.json；复查349项（关闭截图断言），build/checks/20260913T055538809-50408/summary.json。覆盖双怪增大、意图／名称间距、4—7怪缩放不重叠、实际选择／拖动、守卫对齐与显示设置。两轮均因工作区并行改动标为source_changed，不宣称稳定整轮或全项目Verified；本次显示改动未在两轮之间修改。git diff --check通过。未打包、未上传。

## 2026-09-13 主角缩小15%

Implemented，hero_art/action_copy两组窗口80项断言通过。战场主角显示框改为295.8×331.5，中心横坐标614与脚底502保持，拖动范围同源，状态条继续居中；站立实际高度331.5，姿势差分与左侧人物图继续原入口。截图build/ui-21-hero-stand.png已查看。纯UI变更，规则与文案事实无变化，变更包见AGENTS.md。

初轮对白测试使用浮点矩形精确相等产生1项误差断言，改为Rect2.is_equal_approx后两轮全部80项通过，报告build/checks/20260913T060012588-34908/summary.json与build/checks/20260913T060045151-51796/summary.json；两轮都因并行工作区变化为source_changed，未宣称稳定整轮Verified。git diff --check通过。未打包或上传。

## 2026-09-13 商店付款限制集中显示

Verified。平板锁导致的自身魔力付款限制在付款按钮下方显示一次；商品与删牌卡片不再重复共同原因，独有原因与禁用状态保留。切换魔瓶付款即时隐藏，删牌弹窗统一说明，浏览和切换不改变状态。提示固定单行，避免自动换行留下过大的控件高度。

architecture／shop_release／services规则661项通过，services窗口255项通过，稳定报告build/checks/20260913T060110474-35032/summary.json。包含共享提示唯一性、付款切换、删牌窗口、提示与商品行边界、交易与原解除服务回归；截图build/ui-shop-shared-payment-note.png已核对。此前失败为提示Label自动换行产生526像素空白高度，现已修正；早期并行源码变化报告不作为最终结果。未打包、未发布。
## 2026-09-13 游戏内问题与建议

RuleChangePackage：在行动日志上方增加「问题与建议」入口。反馈草稿由独立UI节点维护，仅消费GameView的场景、版本、回合、种子和可选最近40条行动日志；不派发玩法命令、不修改正式GameState、回合、随机或存档格式。独立user://feedback-draft.json保存编辑内容与所选截图，关闭／失败保留，确认成功或主动清空后移除内容。发送前有单独确认页；未配置HTTPS服务地址时不能发送，也不提示成功。

编辑页左侧是类型、标题、正文和日志勾选，右侧管理最多3张截图；底部固定显示需要梯子的提示及提交操作。截图时隐藏反馈窗口，只截取游戏视口；本地PNG／JPEG重新编码为最长1600像素、每张最多2MB的JPEG，不包含原文件路径。右侧可预览与删除，编辑与确认页均隐藏收件邮箱。实际收件地址只在服务端配置。客户端仅以确认后的报告编号发送，同一草稿超时重试沿用编号，等待时禁止重复提交；响应编号不匹配不认为成功。

服务为独立Google Apps Script部署文件：固定收件人、文本／附件限制、JPEG签名、串行锁、每10秒一次新请求、24小时80次上限及48小时回执摘要去重。不需要把邮件凭据放进客户端。无账户身份验证，公网可达性、Google账户授权和实际收件仍待部署验收；不能把离线传输替身当作已完成公网发送。Android导出配置启用INTERNET，但未打包或进行Android实机验收。

影响界面入口、联网、独立本地草稿及用户主动提交内容；所有装备、战斗、卡牌、敌人、地图、正式事务、日志生成、叙事及十四规则轴均不变。UI文案覆盖必填、额度／繁忙／超时／未配置、成功回执、截图限制、预览与清空。沿既有interface窗口添加截图／预览／勾选／重试／状态不变与隐藏邮箱断言；服务离线测试见tools/feedback-service/test.cjs，部署说明见docs/feedback-deployment.md。

验收：服务端离线合同测试通过（不联网、不发邮件）。已查看build/ui-feedback-report.png，确认邮箱隐藏、双列布局、缩略图、固定底栏与梯子提示。architecture/runner规则470项、keyboard/action_copy/interface窗口441项通过（含截图断言），报告build/checks/20260913T060544242-41252/summary.json；随后完整重跑相同范围，规则470项与窗口440项通过（不重复截图），报告build/checks/20260913T060755731-45328/summary.json。两轮均因其他源码同期变化标记source_changed，因此不声明冻结版本整体通过。首轮定位并修正窄HBox标签挤成竖排及按钮溢出问题；action_copy内两项旧断言同步当前立绘矩形与既定50%施法失败返还，未为测试修改玩法。客户端窗口功能已验收；Google账户部署、真实网络／邮件送达和Android实机仍待完成，不打包。

## 2026-09-13 战斗人物选择框收窄与左移

Verified（人物布局专项）。选择框宽度219.8、人物中心590，原图大小与脚底高度保持，资源条同步。既有hero_art断言检查各姿势的中心、选择框、原始比例与资源对齐；截图build/ui-21-hero-stand.png已核对。

hero_art／targeting／action_copy／status窗口230项全部通过，报告build/checks/20260913T060623169-51240/summary.json因并行源码变化标为source_changed，不视作稳定整轮。随后hero_art稳定复查50项通过，build/checks/20260913T060814146-53092/summary.json。无规则改动，仅运行界面专项；未打包、未发布。
## 2026-09-13 汇流卡面完整说明

RuleChangePackage：汇流两面从仅显示动态回魔／力量值改为「完整佩戴数量条件＋当前收益」；拘束面每1件恢复1魔力，自由面每2件增加本回合1力量并明确不足2件不计。正文除数来自worn_resource.divisor，当前收益继续调用Rules.worn_gain；无角色的静态图鉴不添加当前值。补充说明写明出牌时计件、复合整件计数及力量重复叠加／回合结束清除。

仅影响共用卡面／图鉴／预览文案；候选、费用、类别、普通稀有度、装备计件、资源收益、能量、随机、快照、事件日志与十四交互轴均不变，机械／叙事正文N/A（没有行为变化）。现有confluence_cases沿0—4件与两面验证固定条件及当前数值；card_power窗口新增无装备与翻面的正文检查。无需打包。

Verified：card_expansion/content完整规则1448项、card_power完整窗口297项通过，源码稳定，报告build/checks/20260913T061618629-52148/summary.json。已查看ui-confluence-description.png，确认零装备时规则正文仍显示在当前值之前；手牌沿原正文滚动区展示全文。本轮未打包。
## 2026-09-13 汇流双面交换

RuleChangePackage：交换confluence.self_faces的worn_resource配置，拘束面turn_strength/divisor=2，自由面mana/divisor=1。卡面两段正文同步交换并各自读取对应面的除数／动态预览；右上角回魔数值自动跟随自由面，静态图鉴同样交换。候选与正式结算继续从同一配置读取；即时力量、力量到期、回魔上限、普通技能0费、无施法、佩戴根计数、牌区、随机及存档结构不变。唯一行为变化是对应牌面，仍沿既有自由／拘束面使用限制和触发分类，不新增绕过规则的入口。

现有0—4件两面、奇偶／零边界、复合整件、重复力量／清理、魔力封顶、版本回滚与元数据案例均同步面向；窗口通过真实翻面及实际打出验证拘束面力量与自由面回魔。保留上轮完整说明，不恢复仅动态数值的缩写。日志沿实际资源结果生成，未新增叙事或迁移，不打包。

两轮card_expansion/content完整规则均1448项通过，card_power完整窗口均296项通过：build/checks/20260913T062448389-48164/summary.json、build/checks/20260913T062737698-46344/summary.json。两轮均因工作区同期其他改动标记source_changed，不声明冻结版本整体通过；本项实际效果与卡面翻面断言均无失败。未再次生成截图或打包。

## 2026-09-13 内置中文字体修复缺字方框

RuleChangePackage：修复主页及全游戏中文依赖玩家已安装微软雅黑的问题。新增官方未修改Noto Sans CJK SC Regular完整字体，Palette主题与项目默认控件共用同一FontFile；初次启动及语言切换均不再创建SystemFont。Windows／Android导出显式包含OFL许可，字体按正式资源引用随包导出。来源及SHA256记录于assets/fonts/SOURCE.md。

仅改变字体资源、文本排版和导出依赖；中文／英文正文、翻译回退规则、菜单入口、候选、数值、事务、状态、随机、事件日志、存档和十四玩法交互轴均不变。玩家文案N/A（正文不变，修复可读性）；不要求玩家改系统语言，不新增设置或游戏接口，不迁移或打包。既有localization规则增加关闭系统回退后的字形覆盖、已编写中文覆盖和导出许可检查；localization窗口验证启动与真实切换语言后的继承字体，home／display检查布局。待运行受影响完整分类门禁。
## 2026-09-13 性玩具当前刺激文案与公式

RuleChangePackage见`AGENTS.md`同名章节。装备详情和装备刺激状态现按13个可玩家族显示具体身体接触；能量与回合触发显示基础刺激、部位倍率、可选锁内震动系数、当前来源倍率及最终快感。马眼棒高潮滑脱和平板锁高潮保留保留独立当前公式；电量耗尽和诅咒平板锁超时显示0。压力来源及状态按物理根去重，不再把裆部股绳和多部位榨精杯重复列出，也不再复制卡牌／环境解除教程。

验证范围：`special_equipment/content`规则及`special_equipment/status`窗口；覆盖全家族正文登记、马眼棒凸粒和内外同时刺激、公式当前值、电量、锁内0.4系数、状态短文案、跨部位去重及浏览只读。未新增截图、状态字段、随机或存档迁移，未打包。

Verified：`special_equipment/content`规则685项通过，报告`build/checks/20260913T064812913-46264/summary.json`；`special_equipment/status`窗口109项通过，报告`build/checks/20260913T064834533-47204/summary.json`；`localization/architecture`规则122项通过，报告`build/checks/20260913T064911336-35224/summary.json`。窗口运行未生成截图。初次规则运行暴露新增投影缩进错误，修正后第二轮只剩测试把中级股绳基础值误写成3而失败；断言改为权威注册值5后完整分类通过。

首轮资源导入成功；localization／architecture规则122项、localization／display／home窗口246项全部通过。报告build/checks/20260913T064714281-46540/summary.json因同期工作区其他改动标记source_changed，不能作为冻结版本整体通过。继续复跑相同受影响范围；不生成新截图或发布包。

Verified：稳定复跑同一范围，规则122项、窗口246项全部通过，报告build/checks/20260913T064857934-51832/summary.json为passed。关闭系统回退后的中／繁／日／英字形与既有中文正文覆盖无缺字；实际启动、语言切换、显示设置和主页布局通过。资源与双平台导出配置已接入，尚未重新打包、发布或在反馈玩家电脑上实测。

## 2026-09-13 再利用

Verified（能力／施法规则专项）。罕见唯一能力，自由面1费返还失败施法已付临时魔力的80%；拘束面2费，上身和腿部都≥2返还80%，都≥3返还100%。条件逐次查询，不满足2级则暂停；两种魔力分别原池退款，不叠加比例、不返还能量，不为成功或免费复放退款。共用能力生命周期、当前快照与原施法日志，无新存档字段。卡面／要求／图鉴／SVG／状态当前比例或暂停原因／施法提示及默认教程同步。

稳定card_power／casting规则1850项通过，build/checks/20260913T065006417-47636/summary.json。前一轮card_power／casting／content／architecture规则2299项与card_power／casting／status窗口404项均通过，但因并行源码变化标记source_changed，报告build/checks/20260913T064644443-48652/summary.json，不宣称该整轮为稳定全项目验证。

新增案例覆盖0／1／2级最近反例、3／2与2／3不升级、3／3全额、动态降档／暂停／恢复、三种临时余额下混合付款的独立退款、两面共存与唯一、能量不退、魔瓶不变、成功不退、版本回滚、当前存档与场次清理；窗口检查逐面1／2费、唯一、需求、实际出牌、80／100%与暂停原因。首轮修正了逐面energy_cost为附加费用的接线；共享特殊装备脚本并行写入导致的早期加载失败已在后续通过报告中排除。未打包、未发布。

2026-09-13再利用文案更正：自由面卡文及状态说明统一以“使用临时魔力施法失败时”开头。仅修正文案，原分池返还逻辑不变；content分类380项通过，build/checks/20260913T065339484-44636/summary.json。未打包。

## 2026-09-13 火系能力费用与双面唯一入池

Verified：火焰精通／火动力学拘束面1能量，自由面2能量；火动力学独立成功率加算30个百分点。手牌、牌组及静态图鉴的分面费用同步，实际施法与状态文案使用30%。双面唯一能力按永久卡组实时过滤共用随机获取池；牌区移动不解禁、删掉最后副本即恢复。既有未购买商店条目也以同一资格过滤只读库存和付款候选。教程与规则对照见card-framework.md，完整变更包见AGENTS.md。

card_power/card_expansion/content/casting/services首轮3797项规则通过；rewards新增存档测试初次因累计发牌超过手牌上限失败，改用独立的新局夹具后742项奖励规则、378项card_power/encyclopedia窗口全部通过且源码稳定，报告build/checks/20260913T065518925-39408/summary.json。首轮报告build/checks/20260913T065400604-46916/summary.json保留失败记录。覆盖真实1费支付、零费不足回滚、30%乘区后加算与上限、两面并存、重复唯一拒绝、普通／精英／Boss／固定奖励、只有一面唯一的反例、能力区持有、两副本逐一移除、存档恢复、既有商店隐藏／复现与旧购买回滚。UI确认30%正文、1费角标和55%实际火球概率；未新增截图，未打包或上传。
## 2026-09-13 反馈邮件收件验收补充

- 用户反馈主收件箱为空后，在其已打开的towerlover7787@gmail.com Gmail窗口按完整反馈编号使用in:anywhere搜索，找到16:57送达的配置测试邮件，标签为垃圾邮件；发件账号与服务维护账号一致，正文和编号匹配。
- 对该封邮件执行“这不是垃圾邮件”，Gmail明确确认已移除垃圾邮件标签并移至收件箱；搜索结果随即显示收件箱标签。至此真实收件验收通过，覆盖下文先前尚未检查收件箱的状态。没有重新发送邮件，没有修改游戏或服务代码。

## 2026-09-13 反馈服务公开部署与真实提交

- 用户完成Google账号登录、Apps Script API开启及脚本运行授权；使用clasp发布至该账号，最终部署版本3，project.godot配置公开exec地址。凭据不进入项目，固定收件人不变。源码／部署和验收编号见docs/feedback-deployment.md。
- 实际发现Google ContentService跳转曾返回404；原Godot自动POST跳转返回400。反馈客户端改为手动读取指定HTTPS域回执（302／303转无正文GET），异常时对原服务只读补查一次原编号。失败保留草稿，补查不重复发送邮件，不改变游戏状态。
- 公网Godot验证：匿名健康GET返回200；无效POST经一次GET跳转返回invalid且保留草稿；配置测试邮件编号a89e6137d40e4f04fadd05785fd8d340已被MailApp接受并保存回执，实际客户端最终收到200／ok:true／匹配编号，显示提交成功并清空测试草稿。所有重试使用同一编号，无存档、截图或个人日志。未检查收件箱／垃圾邮件位置，不宣称收件方已经读到。
- 离线服务契约通过，覆盖新增回执存在、缺失和非法编号。最终分类报告build/checks/20260913T070203595-50452：architecture 69项通过；interface运行352项，仅卡牌文字滚动断言CARD TEXT失败，全部反馈相关断言通过（跳转GET不带正文、不可信地址、上限、补查失败停止、重试编号与成功清理）。前次报告20260913T065713720-41636也仅同一卡牌断言失败。本次未修改卡牌渲染或该断言，不将interface整体标为通过。
- 无新增截图或PC／Android打包；公网服务已更新，本地游戏源码已接通，原发布包不会自动获得新配置。

## 2026-09-13 三档电量加强

Verified（特殊装备专项）。初／中／高有限电池6／9／12回合，共用BATTERY_TURNS；26项普通电量型及集成震动平板锁同步。零电量持续型和诅咒平板锁特殊时限保持。新装／监狱充电读取新最大值，既存remaining保留，详情／状态沿实际剩余电量显示。初级实测6次触发后耗尽，耗尽装备仍保留；逐类型品质容量断言覆盖全部有限电池。

稳定special_equipment规则332项、同名窗口51项通过，build/checks/20260913T070441734-7208/summary.json。前轮special_equipment／prison／content规则1453项与special_equipment／pressure／status窗口183项全部通过，build/checks/20260913T070110653-50056/summary.json因并行源码改动为source_changed，不作为稳定整轮结果。没有新测试套件、快照字段或发布物，未打包。

## 2026-09-13 高潮20魔力／滑精两回合各10魔力

Verified。Balance统一普通高潮即时损失20、滑精每个后续玩家回合损失10（持续2回合）。保留最低0、临时／魔瓶不参与、滑精期间免即时损失、重复刷新与到期停止。既有数值案例覆盖单次／连续多次、低余额、状态浏览只读、移除触发装备后存续、到期恢复普通损失和原能量／后手；状态与日志同源，教程不再写死旧数值。

content／special_equipment／status／pressure规则1823项、status／pressure窗口132项通过，build/checks/20260913T072011966-27728/summary.json。随后将压力窗口文字断言明确收紧为“损失20魔力”，pressure窗口74项再次通过，build/checks/20260913T072224413-28424/summary.json。无新字段／套件，未打包。

## 2026-09-13 预备咏唱

- 普通魔法prepared_chant：1能量、基础10魔力、嘴部施法，保留／消耗；自由与拘束面成功后通过既有turn增益与cast_minimum=1将本回合合法施法成功率固定100%。卡本身先判施法，失败照常退款、留手而不生效；身体资格、目标、费用和次数不被绕过。不新增状态或存档结构。
- 成功率来源说明移除对熟练而已的写死引用，读取实际提供下限的增益名称。普通池、双面卡面／图鉴、状态与原创SVG、英文同步；英文首轮因占位符须使用兼容目录的p0而失败，已修正，未放宽校验。
- build/checks/20260913T072614760-38780：localization／card_power／card_expansion／architecture／content／casting／rewards共4130项规则断言全部通过；UI因新SVG尚未导入未开始，不能算窗口通过。使用正式Import入口后只重跑未完成casting窗口，build/checks/20260913T072740552-53708共47项全部通过，验证两面显示和实际点击付款／消耗／100%状态。规则用例覆盖真实后续施法、嘴部降低、手部资格、失败留手、未出牌保留、缺魔／过期回滚及正式回合清理。
- 无新增截图或重新打包。原其他任务改动保留。

## 2026-09-13 接连挣动、逐层抽离及玩偶师开场

- 接连挣动自由面蓄力1→2，保留抽牌2；逐层抽离自由面保留2→立即保留打出后全部剩余手牌，下回合能量＋1保持。retain.all沿原retain_until与保留动画结算，不弹选择窗口；后续新进入手牌的卡不自动保留，原回合期限、虚无与场次末清理保持。
- 玩偶师通过统一_append_enemies出生入口建立所属玩偶，开场已有10生命、1生命下限与溢出转伤；首回合赋予嘲讽和受击反应，然后缝补／复合／特殊循环。删除召唤意图及其执行／校验／提示入口。实际怪物96生命和其他效果不变；正式、练习、续局倍率共用，读档不重复生成。图鉴、怪物库、规则对照和英文已更新。
- 初轮build/checks/20260913T074639886-49292被另外两处编译错误阻断：equipment_replacement的E未定义、room_events描述分支在声明target前读取；分别改用g.Equipment和先取得target，保留原锁具规则。随后卡牌反例夹具误选既有同名牌，改为明确添加一张新实体，未改玩法以迎合测试。
- 分类累计成功证据：localization 53项（074639886-49292）；card_power 1392／architecture 69／content 380项（074801092-41204）；rewards 672／enemies 1519／tower 274项及enemies窗口212／rewards窗口303项（074849610-47828）。共4359项规则、515项窗口断言通过。最终报告标记source_changed：运行期间其他任务同时修改game、card_effects、demo_exit、prison、界面等文件，不能宣称最终合并版本已完整通过；未在持续变化的工作区反复全量重跑。
- 覆盖整手保留、后入手牌反例、真实弃牌与到期、开场双单位、首回合赋予、完整循环、多段反应／溢出伤害／死亡联动、实际窗口出牌、存档及续局倍率。所有窗口运行UI SCREENSHOTS: none，未新增截图或打包。

## 2026-09-13 魔力涌流自由面0耗魔

Verified：自由面mana_cost为0，0自身魔力即可尝试，成功获得2层魔力预备（10临时魔力）并消耗。拘束面仍5魔力／蓄力2。两面仍为0能量魔法，保留原施法判定、失败留手及魔法触发；自由面角标仅紫色＋10，不显示−5。规则对照表与AGENTS变更包同步。另修复悬浮成功率按当前面实际耗魔读取付费保底资格：75快感＋余烬结晶时拘束面100%、自由面25%，不改变实际判定。

首轮card_power/card_expansion/content/casting规则3335项、card_power/encyclopedia/casting窗口425项断言通过，报告build/checks/20260913T080747986-48436/summary.json因随后修改分面成功率提示而为source_changed。最终card_power/content/casting规则2265项、encyclopedia/casting窗口125项通过且源码稳定，报告build/checks/20260913T081142611-54488/summary.json。覆盖实际零魔力使用、另一面原费用、临时魔力、消耗、失败留手、静态图鉴与真实手牌角标、付费保底反例及当前面悬浮文字。git diff --check通过，无新截图、存档变更或打包。

## 2026-09-13 入狱保底、限制项圈与累计警戒度

Verified：1—4级按普通/活跃复合根保底6/8/10/12件，不足补齐并额外2/2/3/3，全部至少2档；达到保底不再追加普通/复合件，只收紧1档至多3档。加固产生的新肩带同样至少2档。特殊装备独立追加2/2/3/3件2档，空位不足不替换；五级终局和原巡视/链接配置保持。

限制项圈从3级起固定佩戴，既有项圈重新上锁且不重复；不计件数，不进入普通生成/替换、伤害/降紧/滑脱/商店及事件直接解除。无可损伤耐久，内部常量仅承担已有物理生命周期，普通界面、图鉴与终局说明不显示为数值条。沿颈部正式候选、开锁术/便携开锁针、双臂自由后的1能量取下、完美版henshin两面直接解除接入。普通henshin两面阻止并有明确原因。颈部开锁目标、连续开锁部位与当前快照白名单同步，解锁未取下可保存恢复；真正新开游戏security归零，携带卡组/遗物继续两次以及出狱重建均保留现有security。

排查与验证：首轮发现颈部尚未纳入卡牌目标和快照白名单，已补齐；项圈UI用例改用正式颈部面板投影，不从仅含常规身体槽的原数组寻找。图鉴旧隐藏名单同步当前已隐藏的double_unlock，未修改其玩法。37条相关英文source/text与人工生成词表同步。复用既有prison/tower_progression用例，覆盖保底以下/等于/超过、已有身份/特殊装备保留、新肩带、3级门槛、锁状态、开锁工具次数、正常/完美henshin、费用/过期回滚、保存恢复及续局；窗口确认无耐久与锁显示、无伪耐久条和真实监狱流程。

- build/checks/20260913T080021392-55068/summary.json：prison/tower_progression 916项通过、源码稳定。
- build/checks/20260913T080835767-52324/summary.json：15个相关规则分类共5078项通过，card_power/guard窗口通过；prison窗口因测试查询旧数组失败。运行期间修改了终局说明和英文目录，报告source_changed，不作为最终合并版本全量通过。
- 最终build/checks/20260913T081653145-45152/summary.json：localization/architecture/prison/tower_progression共1040项规则断言、prison窗口144项断言全部通过，before/after指纹相同，status=passed。相关文件git diff --check通过。无新增截图，无旧档迁移，无打包或发布。

## 2026-09-13 火堆统一入场SL

RuleChangePackage：火堆的rest_choice／rest统一为同一场景键，并从该场景键排除开始休息时递增的combat.serial；只修改检查点边界，不改变实际生命周期。快速SL与磁盘继续沿既有restart_snapshot／SaveStore／restore_snapshot共同恢复入场选择前状态，奖励、资源花费、时间、手牌／装备／增益和随机一起撤回；离场仍生成新起点保留收益。精确快照接口、版本单调与回滚、其他场景、事件日志／中文正文、十四玩法交互轴均不变；玩家文案N/A（现有“场景起点”说明与本规则一致）。没有新增字段或旧档迁移，不打包。

现有persistence场景案例覆盖四种火堆选项、推进、过期回滚、磁盘重开、相同随机重放、开场效果不重复与离场保留。persistence窗口通过真实快速SL／重开验证奖励窗口和全状态恢复；services检查原奖励与休息行为。待完整受影响分类运行。

首轮火堆新增规则均通过；persistence中旧“接连挣动选两张保留”夹具因同期卡牌已改为全部保留而失效。将待选保留快照案例改用当前仍具有真实选牌与后续抽牌的专心致志自由面，并明确断言进入pending_retain；不修改卡牌行为、不删除选牌恢复覆盖。首轮报告build/checks/20260913T082537979-6928/summary.json保留失败记录，复跑完整受影响分类。

Verified：persistence/services/architecture完整规则1152项、persistence完整窗口76项全部通过，稳定报告build/checks/20260913T082708033-52324/summary.json为passed。实际快速SL重新显示火堆奖励选择，重新启动读取同一入场状态；正常离开保留收益。未打包。

## 2026-09-13 魔力松缚基础卡组与自由面嘴部施法

新局基础10牌以magic_slip替换unlock；开锁专项改为显式赠送测试牌，专门平板锁练习的声明开场牌保持。自由面cast_free及free_mana_cost=0复用正式施法路径，正反例覆盖成功获得5临时魔力/抽1、失败留手不生效、嘴部0%拒绝、过期提交原子拒绝、拘束面10魔力保持；手牌和图鉴同面要求/角标/成功率一致。

最终稳定专项build/checks/20260913T084051343-53804/summary.json：tower 275断言、casting窗口52断言全部通过。前置casting 545断言及pressure 823断言通过；首次扩展分类中的card_expansion/content/special_equipment/persistence/rewards/core通过，links/composites修正旧开锁夹具后通过。baseline/home/prison窗口分别269/96/147断言通过，但该批有随后修正的casting测试及源文件变化，不记整批通过。零费基础牌的旧全手牌灰置断言已修正，魔力松缚无目标时默认自由面的翻面测试已修正，并在最终稳定专项复验。

扩展回归限制：relics有诅咒平板锁商店原因、旧电池8回合预期及宝箱payment字段的4条失败；equipment_complete有新增restriction_collar品质材料预期失败，与此次牌组/嘴部配置无关。较大组合批次达到300秒超时，不能记为完整绿色回归。git diff --check通过；不截图、不打包、不改旧存档。

补充：build/checks/20260913T083918477-42012中casting/pressure/enemies/tower共3162断言与casting窗口52断言均通过，但报告检测到共享工作区source_changed，故保留为动态工作区结果；最终稳定的tower/施法界面证据仍采用20260913T084051343-53804。不继续重复扩大回归。

## 2026-09-13 出口继续游玩降低快感并站立

RuleChangePackage：仅在正式demo_continue的原清理后固定快感－40（最低0）、posture=stand；既有版本复核与原子提交、下一阶段SL起点共用。影响资源／姿势数值及候选正文、结算日志和人物／快感只读投影；日志携带变化前后快感与姿势。正文中英目录与生成器词表同步。卡组、遗物、成长、警戒、不可解除装备例外、魔力原恢复、随机域、移动／锁／层级／链接／材料规则、费用、回合、存档格式均不变；无新入口或迁移，不打包。

tower_progression既有demo_exit案例扩展三姿势×0／25／40／80快感、预览只读、过期拒绝、零下限、资源／卡组保留、同阶段SL不重复及结束不触发；窗口用真实继续按钮验证35快感、站姿与日志，content/localization核验正文。待完整门禁。

Verified：tower_progression/content/localization/architecture完整规则732项、tower_progression完整窗口54项全部通过，稳定报告build/checks/20260913T084932563-56248/summary.json为passed。真实出口继续从75快感躺姿进入35快感站姿，候选说明与日志一致；拒绝、低值封底及SL不重复恢复均通过。未打包。
## 2026-09-13 v0.16六缚计数热修复

针对性检查enemies／architecture／content全部2208项通过，报告build/checks/20260913T101727756-1180/summary.json；之后中英文图鉴更新后的localization／content全部446项通过，报告build/checks/20260913T102110562-10064/summary.json。两份报告均为稳定源码passed。检查覆盖24种历史组合及入场、读档、前三次／第四次、下一场、坏档原子拒绝，保留既有逮捕打断和实际收押案例。首次检查还复现v0.16提前注册未开放角色卡牌导致mind标签读取错误；修复分支只在显式选择该角色时注册，其余v0.17代码不混入。不运行全量或额外截图。

## 2026-09-13 v0.16发布范围与测试中止

发布准备修复RoomEvents.arrive非多阶段事件未调用resolve_effect_copy／conditional_copy的遗漏，复用既有稳定条件接口，不改正文、随机或效果数值。运行中的event_flow分类595项通过。全量规则日志build/checks/20260913T091941659-53108在用户要求停止时尚未完成，已出现relics和action_copy断言失败；窗口日志build/checks/20260913T092116859-49736仍有home_persistence和exploration失败且尚未完成。停止测试后更新发布脚本，因此报告也可能标记source_changed；不能作为稳定全量通过证据。

按用户“别测了，发布吧”的明确指令不继续修测试或补跑，仅执行Windows导出、Android签名／对齐／内置资源完整性和分发文件校验。未运行独立启动探针或安卓真机验收。v0.16发布说明明确此边界。

## 2026-09-13 事件高潮每次扣20魔力

已核对四个相关事件，沿Pressure通用结算使用OVERLOAD_MANA=20，没有在事件效果内追加mana_loss。修正事件阶段被残留slip_ejaculation_turns免除即时扣魔的边界；其他阶段的延后扣魔不变。新增event_flow案例通过正式选项覆盖修女、雕像、典当铺三选项与赌牌第三局，分别检查100／15／0魔力、残留状态0／2、实际次数与扣量、临时魔力／魔瓶保持、日志及过期重复提交。旧通用事件用例的90余额改为当前规则80。

本次资源检查全部通过。最终event_flow完整595项中589通过，剩余6项均为既有典当铺平板锁分支文案断言，本次未修改该文案或内容包，不能宣称完整事件分类通过。报告build/checks/20260913T085933311-3688/summary.json。联合回归中special_equipment和pressure均通过，见build/checks/20260913T085841019-55696/summary.json；首次加入案例复现20项扣魔／日志失败，逻辑修正后均通过。git diff --check通过，无新增截图或打包。
## 2026-09-13 0.17可选角色2

- 主菜单角色选择、11张初始卡组、四部位蓄力／释放、精神集中、角色专属改单、部位安装限制、固定站姿、角色图鉴与教程接通。记录在`docs/character-two.md`；原版牌定义不覆盖，旧存档默认原角色，源码与导出预设版本0.17。本轮不打包、不发布。
- 最终功能验收`build/checks/20260913T100208948-45608/summary.json`为passed、源码指纹稳定：core与card_power共2169项，home实际窗口110项通过。覆盖所有改单真实使用、失败返魔及留层、多段和AOE、打断、两次手部豁免、奖励/商店/变牌、角色存档恢复、捕缚伤害倍率及整备结束清理。窗口实际点击选角、新游戏、蓄力、右键翻面、释放和切回原角色；截图`build/ui-witch-selection.png`、`build/ui-witch-battle.png`已检查布局。
- 关联回归`20260913T095831689-57824`的12个规则分类共5769项及encyclopedia/home窗口均完成通过；因运行期间继续修正捕缚加伤与结束清理，报告如实标为source_changed，不作为固定源码全量通过证据。对应最终改动由上述core/card_power重验。
- 按`-Suite core -Impact`补充一次性交叉覆盖，报告`20260913T100326125-1140`：card_power/card_expansion/card_splash/card_growth/consumables/basic_attacks/battle_saturation/architecture/installation_priority/casting/action_copy/status/rewards/core/pressure全部通过。relics的4条失败为旧测试仍要求旧商店提示、旧电池时长，以及给免费宝箱强加付款字段；仅修正测试，玩法未改。报告保留失败及source_changed，不将不同源码运行相加宣称全项目通过。
- relics修正后的完整分类复验`20260913T100722090-29012`：786项通过、源码指纹稳定。旧日志测试也已按现有施法失败返还50%规则校正，图鉴旧总数断言纳入角色专属隐藏牌。`git diff --check`通过。未运行完整all、长程随机试玩或Android设备验收。
## 2026-09-13 0.17 Windows本地交付

- 按用户要求只制作PC包，不上传、不发布、不制作Android。Windows预设、EXE描述和文件／产品版本统一0.17／0.17.0.0；打包脚本读取project.godot版本，成品探针从manifest获取期望版本。
- 导出`build/package-local017-20260913`：导出完成、前后运行源码指纹一致。成品目录`outputs/spire-v0.17-windows-x64-local017-20260913`；内容包、MIT代码许可、素材权利声明及第三方许可随包保留，不含用户存档。
- `tools/check-package.ps1`通过，记录`build/package-check-20260913T101129825`：实际发布EXE无窗口启动退出正常；编辑器载入成品PCK验证版本、12份内容包、动态贴图、原角色／角色2、11张初始卡、魔术手专属效果、练习与隔离存档恢复。两条路径分开验收，未宣称发布EXE执行外部探针。
- ZIP重新解压后核对23个manifest文件和总文件数，全部一致。`紧缚尖塔demo-v0.17-Windows64.zip`为135275426字节；SHA256为`e0a65e63bef2950b98b5501b7edfff76b9f39be764c14338c702363ac6515875`，附同名.sha256文件。
- 本轮仅进行成品检查；上一批角色功能专项记录保留，未补跑全项目all或长程试玩。包内更新说明已说明验证范围。

## 2026-09-13 0.17 蓄力释放覆盖补丁

RuleChangePackage：按最新截图选项1，角色2手部／嘴部／精神法术成功释放后清空对应部位蓄力；伤害仍按提交前N层产生N+1段，其他部位不变。魔女飞踹仍需4层且只消耗1层，失败保留蓄力与精神集中；付款、退款、命中、AOE、抵挡、回合、随机、姿势、拘束资格和角色1不变。不新增状态／存档字段或迁移。候选、状态、教程、角色选择说明同步。

core及home完整专项通过，源码指纹稳定，见build/checks/20260913T121701855-54224。覆盖0／2／4层、实际多段、其他部位保持、下次基础一段、失败保留、腿部例外和真实右键／释放入口。未运行全项目all。

本地补丁从原交付0.17 PCK重新打包，739个资源中仅替换witch_character／status_view／tutorial／home_screen四份编译脚本，逐资源SHA256校验其余不变；报告build/charge-all-patch-20260913/紧缚尖塔.pck.resources.json。没有纳入工作区其他并行改动。覆盖后的整包通过check-package -ChargeAll（build/package-check-20260913T122313279）：成品PCK真实提交三种法术、清空所选部位且下次一段，原版EXE正常启动；内容包、原角色、角色2、存档与练习探针通过。仅交付Windows覆盖ZIP，不发布。

## 2026-09-14 角色2平衡修订验收

- 规则与界面范围见AGENTS.md「角色2第二批平衡修订」、docs/character-two.md。最终补充开局Boss交换按角色实际初始遗物读取名称、资格并移除正确遗物；不能仍向角色2索取余烬护符。
- 稳定检查20260913T141159390-60236：core/relics/casting -Impact一次展开22个相关完整分类，8983项规则断言通过；home/status窗口168项通过。涵盖原角色回归、专属新局75/75/50与护符、战斗阶段限制、新遗物、2层抵挡、分部位伤害/清空、精神集中保留和乌龟壳、失败退款与减层、分面消耗、增伤预览、原生切换及自动回切。
- 最后开局交换及内容补全后，稳定检查20260913T141724506-31156：localization/encyclopedia/content/services/persistence/core共2575项通过，home窗口110项通过。追加魔术手实际连续降低4档（部位目标移除后顺延全身）、30魔力只付一次、过期回滚、最终消耗一次及真实开局遗物交换；没有用只读定义断言代替实际执行。
- 首轮core失败源于伤害调整后旧胜利夹具仍按旧伤害假设击杀；调整明确夹具蓄力层数后复验。首次扩大检查遇到新SVG尚未导入造成预加载错误，随后通过正式-Import导入再完整重验；失败报告保留，不宣称其为通过。
- 两份通过报告各自源码前后指纹一致；不把不同源码批次合并宣称全项目all。git diff --check通过；无全量all、长程随机试玩、打包或发布。当前源码保留其他任务既有修改；旧0.17交付ZIP不覆盖。

## 2026-09-14 角色2平衡版Windows完整包

用户授权打包当前项目，本地交付、不发布。build/package-witch-balance-20260914导出源码指纹前后一致；成品check-package -ChargeAll -WitchBalance通过，日志build/package-check-20260913T143629354。验证0.17版本、原角色/角色2、75魔力与快感上限、50魔瓶魔力、魔女护符、魔术手新效果、两件专属SVG、12份外部内容包、存档与真实释放清空、独立EXE启动。最初成品探针沿旧夹具注入100魔力超过新75上限，故被正式提交校验拒绝；修正探针按实际mana_max补满后通过，未修改玩法。

ZIP解压后逐一核对23份文件的大小与SHA256，总计24 个文件含manifest，全部一致。交付紧缚尖塔demo-v0.17-角色2平衡更新-Windows64.zip，135294326 字节，SHA256：3d948be397b926f59884d4d34e706f0c40e13e46884d0d07afd26f356c3fdb08。未覆盖旧交付、未含存档，不制作Android。此前功能专项记录保留，本次只做成品检查。


## 2026-09-14 反馈1847ba708526785c2322abae5cdd7561

用户确认截图开局启用了无限效果模式。反馈文本是第8层战后整备、截图是第11层第50回合；缺少实际存档，不声称按种子精确重放了两者之间的整局操作。以该种子、两名mixed_bundle、无限模式高保留系数建立明确状态夹具，经正式end复现每轮0能量和持续中断：回合增加，敌人每轮只执行一次；首次草拟夹具在开场后才切卧姿，会合法跨越“旧回合玩家先手、下一回合敌人先手”的两个敌人阶段，已改为开场前设置真实卧姿，不能把前者误报为重复结算。

根因：无限模式的回落值接近阈值，回合开始的持续来源再次触发强制状态；同时原surrender候选排除了overloaded，导致普通行动与投降都隐藏。修复保留战斗中的正式投降、原二次确认、版本复核与完整收押事务，不调整无限效果、资源、敌人行为或end管线。普通警戒进入牢房后仍可能继续受设备影响，不强行清除该模式；截图警戒4时投降沿原规则进入警戒5的终局。整备复现从3回合连续提交至0并回地图，已击败敌人不再施加装备。

验证：20260913T185256036-42504改动前最小回归仅“中断期间保留投降出口”失败，确认覆盖缺陷。扩大交叉检查20260913T185329577-34216的其余12分类通过；pressure两条旧预期分别错误地要求入狱不再受无限效果、练习只允许继续，已按本次规则修正。最终20260913T185531623-49552：prison/pressure完整规则1753项、pressure窗口79项全部通过，源码前后指纹一致。覆盖反复继续、不重复敌方阶段、整备结束、版本过期回滚、重复投降拒绝、普通/警戒4退出路径以及实际投降按钮两次点击。git diff --check通过。未运行全项目all，未改或重新打包已交付0.16/0.17文件。

## 2026-09-14 离场怪附加装备加强

RuleChangePackage：离场施加统一中级／紧度3。Balance登记离场grade=2/tier=3，EnemyPlans.application对final声明统一使用；安装能力扫描与实际意图同源。漂浮锁固定平板锁来源同用常量，开启锁池后维持固定类型／无概率／无法佩戴仍离场，正常紧度3规则自动附带中级加固带。漂浮口球由初级2档升至中级3档；四种基础材料怪由中级2档升至中级3档。原非离场施加仍初级2档，其他持续型敌人不变。

影响等级、紧度、所导出的耐久／部位限制与附属组件；资格、模板池、数量、锁规则、来源、替换、回合、准备／打断、失败离场、死亡取消、奖励、随机域、存档结构不新增接口或分支。原安装与日志直接使用新规格；图鉴中英及词表同步。十四交互轴仅等级／紧度及原规则连带效果改变。既有enemies案例覆盖实际附加、非离场反例、打断／死亡、无空位、概率两端、存读和奖励；窗口检查真实口球附着规格。不打包。


## 2026-09-14 魔路精通与 henshin 费用

用户最终确认为两个角色共同更新、henshin拘束面＋1（3费）、自由仍4费；魔路精通两面互斥，不同时存在。RuleChangePackage见game-design.md同名章节。卡牌说明、状态条件／次数、失败实付来源退款和回能日志、互斥候选拒绝、中英文资源均同步；不重发旧版安装包。

最小及边界案例沿card_power扩展：纯自身／混合／纯临时支付、正数耗魔条件、实际0费卡前两次及第三次、成功及复放反例、2/2→3/2→3/3→2/3动态限制、降级不刷新配额、下一回合重置、失去／恢复等级、两角色共享注册、同面及另一面重复提交原子拒绝、存档次数及非法状态、整备清理、henshin普通与完美版分面费用。旧henshin批量解除和捕缚案例按3费修正输入与付费期望，非费用机制保持。

初轮card_power有1条批量解除旧2费断言失败，源码期间还受到其他批次修改，不记通过；后续修正。英文兼容表初次追加用了printf形式目标参数，被加载器正确拒绝；改用{p0}后localization通过。20260914T051707385-38532中localization 68与card_power 1596通过，其card_expansion有3条捕缚夹具仍给2能量而失败。修正夹具后20260914T051755588-46308：card_expansion 1082、architecture 69、content 380、casting 564、persistence 585全部通过，源码指纹稳定。core仅TC-ENEMY-0003的敌人离场紧度旧2档断言失败：工作区另有离场附加改成中级3档的修改，不由本次卡牌调整引起，本次没有覆盖该改动或将core记为通过。

验证：首轮build/checks/20260914T051444647-46880/summary.json的唯一规则失败为混合遭遇口球旧初级断言，已同步为中级3档，并补齐练习入口旧文案。复跑build/checks/20260914T051739888-16116/summary.json：enemies/architecture/content/localization规则2278项、enemies窗口213项全部通过；同期其他任务修改源码，整轮状态为source_changed，不声明冻结版本整体Verified。新规格、平板锁加固带、原离场边界与实际界面操作均无断言失败。本批未截图、打包、发布或推送大版本。

## 传送符入狱保留（2026-09-14）

RuleChangePackage：传送符声明 keep_on_capture，统一收押流程过滤没收名单并按实际移除数量记录；主动投降、敌人收押及五级监室均保留原实例、次数与顺序。无需新存档字段或迁移，不重复发放。其他道具仍没收，巡视检查、使用消耗、主动丢弃、使用资格、容量、回合、随机和装备规则不变。十四交互轴仅涉及道具生命周期与收押，其他不变。

玩家文案同步道具详情、图鉴共用说明、收押词条、教程及警卫练习说明和英文回退。机械日志继续报告真实没收数量，无新增叙事事件。复用 prison／guard／architecture／content／localization 分类，覆盖实际投降与敌人收押、五级边界、旧候选回滚、实例次数保持、快照恢复、普通道具反例与共享说明；不新增窗口、截图、打包或发布。

20260914T051926160-7184：relics 786项及card_power窗口302项断言全部通过，但运行期间其他批次源码改动导致source_changed。补做20260914T052204848-40212，同样786项规则／302项窗口断言通过，仍检测到工作区源码变化，因此两次均不标记稳定源码整体门禁通过，不无限重跑并行修改中的工作区。既有稳定运行中的card_power、localization、card_expansion、architecture、content、casting、persistence结果分别保留；core的无关旧敌人数值断言仍如实记失败。git diff --check无空白错误。本批源码完成，未打包、提交、推送或发布，不作为新的大版本里程碑完成声明。

验证完成：20260914T052724734-42644 的 localization／architecture／content／prison 通过；guard 最后一条回滚断言误把恢复后递增的版本号与原快照比较，改为与恢复后的提交前快照比较。20260914T053035005-44188 仅重跑 guard，40项通过。相关五分类合计1336项通过，两次最终运行均无 source_changed；非全项目回归，不打包。此前失败包括旧“再次收押没收传送符”断言及入狱背包必须为空的校验，均已修正。收押阶段校验与存档恢复现只允许带 keep_on_capture 的道具保留，其他道具夹带仍拒绝且回滚。


## 2026-09-14 体术动作格字号与居中

名称与实际伤害以整行测量后同排居中，默认18号、长招式最低16号；费用／标签居中显示，默认14号、长行最低12号。右下快捷键维持11号原样并预留对称安全区；轨道、候选、点击／右键切换／拖动／禁用条件不变。具体RuleChangePackage见game-design.md对应章节。

20260914T053122276-45688：architecture 69＋basic_attacks窗口79项通过，源码稳定。检查现有ui-basic-action-rail.png及ui-basic-attack-forms.png发现火球费用标签尾部省略，改为紧凑分隔并按长度适配字号。20260914T053334413-42704：basic_attacks 84、touch 18、keyboard 67项窗口断言全部通过；期间工作区其他main.gd改动造成source_changed，不能作为整体稳定通过。最终20260914T053516805-25700：basic_attacks 82项通过、源码指纹一致（不启用截图，因此比带截图运行少2项）。截图已人工查看名称／伤害同排、连击长名完整、火球费用／次数／成功率完整、快捷键无遮挡。git diff --check无空白错误。不打包、不发布，不修改正在进行的其他装备UI改动。


## 2026-09-14 墙缝道具遮挡与捕缚移动限制

RuleChangePackage：UI安装工具面板从魔瓶区域移至体术栏右侧／非战斗手牌上方；体术格仅在存在已安装工具时预留宽度。CaptureBind提供共用移动拒绝原因，wall_move候选与正式提交复核禁止捕缚中的两方向移动，移动按钮灰置并直接解释。状态／图鉴／教程与英文兼容目录和人工词表同步。影响捕缚行动资格及界面布局，无新增状态、事件、随机、存档字段或迁移；能量、距离、姿势原规则、装备／层级／锁／材料／目标、伤害、工具触发／次数、回合与其余十四交互轴不变。拒绝无机械日志；已有捕缚与移动成功日志保持准确，非UI叙事N/A。

最小正例、无捕缚反例、两方向边界、旧候选复核和原子回滚加入wall现有分类，覆盖三种来源及解除恢复。guard窗口验证真实第三回合施加后按钮灰置和具体原因；installed_tools窗口验证面板不覆盖魔瓶／体术、真实鼠标存入与新入口打开。复用完整wall／guard／installed_tools／enemies／content／localization／architecture规则及installed_tools／guard／wall窗口；结果待记录。本批不截图、不打包、不发布。


本批结果：20260914T054719458-47044 的七项规则分类2530项全部通过，installed_tools与guard窗口通过；wall窗口发现禁用提示挤入姿势行及另一批身体详情改动的空脖颈缺失。已修正本次提示布局：紧凑行直接显示具体拒绝原因，普通贴墙状态保持距离提示；非战斗工具栏缩至32高并压缩内边距，验证与真实手牌、魔瓶均不重叠。20260914T060238373-44540 相关六类规则769项通过；wall窗口的移动布局及新非战斗面板断言通过，仅空脖颈详情旧检查仍失败。guard新增位置断言初版没有处理高潮时无姿势栏的情况，已改为检查存在时不重叠。

最终20260914T060515825-18304：installed_tools／guard完整窗口95项全部通过，源码指纹稳定。实测安装后魔瓶存入、工具入口打开和真实捕缚移动灰置；前两轮规则运行期间存在其他任务修改，按source_changed保留单类结果，不声明整个工作区全量通过。颈部详情断言属于另一批在途身体栏改动，未在本批覆盖或放宽；未打包、发布或推送。git diff --check通过。


## 2026-09-14 角色选择名称

RuleChangePackage：选择页角色1改为“魔法少女(futa)”，角色2改为“小魔女·测试版”。通过两个独立本地化ID显示，中英文与中文安全回退同步；内部original／witch标识、顺序、选中角色、新开／继续流程、角色规则和存档均保持。仅UI名称受影响，候选、数值、事务、事件／日志、非UI叙事、随机及十四规则交互轴N/A。既有witch_character窗口检查准确名称、选中后新局及切回原角色；localization／architecture分类复核资源与边界。不截图、不打包。

## 魔力耳坠阈值30（2026-09-14）

RuleChangePackage：每累计消耗自身魔力30点获得1能量，替换原20点。统一遗物注册数值、效果说明、英文回退与规则对照；计数显示和校验沿同一阈值读取。触发阶段、跨回合余数、本场结束清零、临时魔力排除、失败施法及退款逻辑不变；不增加状态、候选、随机或存档字段，其他交互轴不变。既有具名触发日志无须改写。复用 relics／card_expansion／casting／architecture／content／localization 完整分类，覆盖20不触发、29边界、30触发、跨回合与多阈值、兑换及余火交互；不打包。


验证：20260914T061242279-41644 的localization／architecture共137项通过。窗口分类最初误填witch_character（实际由home分类加载），未执行有效窗口案例；改用正式home完整分类。20260914T061525492-47556共111项检查，仅平板锁练习的上锁／加固带可见说明断言失败；本次两个名称、角色2开局及切回角色1的实际流程断言均通过。该失败涉及另一批在途装备详情UI，未修改或放宽；运行期间源码变化，整轮不标记通过。不打包。

魔力耳坠验证：20260914T061541360-47872 的 localization／card_expansion／relics／architecture／content／casting 六分类共2952项断言全部通过。运行期间工作区存在并行源码修改，门禁结果为 source_changed，因此不声称最终合并版本冻结通过；未打包或发布。


## 2026-09-14 四区解缚界面预览

RuleChangePackage：docs/release-interface.md。UI 四区/单区展开、同部位外内层、共享物理目标去重、正式端点候选、前后耐久及衰减短提示；特殊装备仍显示电量与当前状态，长说明/公式按需展开。原动作资格和事务不变，不打包或发布。

20260914T060525904-40228：body_layout、targeting、equipment_complete、keyboard、touch 共359项窗口断言通过，源码指纹一致。含真实鼠标拖放、自由区域拒绝、跨区域目标替换、单目标预览与实际扣费/伤害一致、无回合检查和旧版本拒绝。之后增加特殊装备状态显示，并修正共享连接绳候选必须匹配当前部位。20260914T061425186-6328：special_equipment、body_layout、targeting 共228项全部通过，但并行工作区改动使该次状态为source_changed，不能作为最终稳定版本的发布门禁。

20260914T060525909-13704：localization 68项、architecture 69项通过；equipment的新增只读预览、零伤害、限制项圈开锁/取下事务案例通过。该完整分类154项中仍有4条 POOL grade independent of application tier（rope/belt/tape/cable_tie）断言失败，关联正在调整的敌人生成等级/紧度，本次未改其规则或旧期望值。display在20260914T055250277-45188中的场景复用检查通过，但 DUCK MUSIC repeated actual soup play preserves progress 未通过；未宣称整个display分类通过，未修改音乐逻辑。

预览图为显式选择的 build/ui-release-region-panel.png 和 build/ui-release-numeric-panel.png，仅截取区域入口与解缚详情，已人工检查外内层顺序、数值/倍率及按钮排版。未运行全项目发布检测。

最终窗口复核 20260914T061735866-22176：special_equipment、body_layout、targeting 共230项通过（含两张局部截图）；仍发生外部源码变动，状态source_changed。停止重复整批窗口测试，不将并行变化中的工作区标记为稳定发布版本。本次交付为可评审UI预览。

英文补充最终复核 20260914T062045304-684：localization 69项通过，源码指纹一致，包含四区动态件数及特殊装备主体标签。

## 2026-09-14 监狱期限与起点选择

- RuleChangePackage见`docs/prison-release.md`。已实现分级刑期、单次检查最多延长8回合、到期施加与自动出狱、出口稀有三选一／遗物／60魔瓶奖励、8—10层非休息起点、倍率后的安全等级生命加成，以及两项正式流程练习。快照52，不迁移旧档，不打包或发布。
- 首轮`20260914T061623932-45708`：architecture通过，prison旧的连续巡视夹具因新刑期提前结束而失败；已将该夹具的后两次巡视倒计时设为1，继续验证真实检查／登记而不与独立刑期案例互相覆盖。
- `20260914T061906250-44988`：architecture69、content380、persistence593、rewards672、prison869、enemies1761，共4344项规则通过。运行期间补了召唤物跨收押的生命加成记录和英文文案，不视为最终完整指纹证明。
- 主页原先依赖练习顺序的音乐入口已恢复原顺序；新增出狱练习列于现有条目之后。`20260914T062451809-47736`：home111项仍有一条原有平板锁详情检查失败，与本批监狱规则和新增入口无关，未修改其断言或把该组标为通过。
- 复查`20260914T062524537-46312`：localization69、persistence593、prison870、enemies1761，共3293项规则通过；route134、prison155项窗口检查通过，运行前后源码指纹稳定。随后按用户补充排除宝箱房，相关规则、窗口文字与反例同步，并另跑最终专项。

- 用户补充“宝箱房也不能选”后，正式入口仅允许8／9／10层的battle／event／shop；rest／treasure同时拒绝，文案及英文同步。`20260914T063040663-3304`：localization69、content380、prison913，共1362项规则及prison155项窗口通过，源码指纹稳定。新增范围矩阵及真实非法depart拒绝／状态不变反例，没有用页面隐藏代替规则拒绝。
- 最后只补巡视确认前的处罚提示与英文，规则数值保持；另跑localization／content与prison窗口，结果随后记录。

- 最终提示复查`20260914T063524115-5108`：localization69、content380和prison窗口156项全部通过，源码指纹稳定；检查前处罚提示通过实际窗口断言。相关实现已完成，已知主页失败保持记录，不打包。


## 2026-09-14 自缚正式接入

稳定ID：self_binding；名称：自缚；正式生成：罕见X费技能，加入UNCOMMON／REWARDS，沿原商店、休息罕见选择、普通奖励与图鉴入口，两名角色共用。无保留／消耗／唯一标签，打出后正常弃置；沿已有self_binding.svg。

自由面：腿部随机佩戴2件普通拘束具，每件品质＋紧度＝2X；具体池为绳索／细绳／皮带／细皮带／胶带／扎带，腿部五类身体槽与精准位置、层级、容量均使用现有安装资格。无上锁、替换、链接或特殊装备生成。先确认存在可完整安装的两件组合；随机第一件必须给第二件留出合法位置，不能部分执行后回魔。主动佩戴属于卡牌代价，明确以Application内部voluntary参数跳过闪避与魔女蓄力抵挡，不消耗这两类状态；原敌人／事件施加默认仍可被抵挡，参数没有接为独立玩家命令。

拘束面：按原可加固的真实普通件／复合组件／独立肩带随机逐档收紧，总计2X档；紧度已3不算可收紧空间，不触发上锁额度，也不靠补附件凑档。实际收紧沿_reinforce_equipment与原刷新规则，原有锁不变，正常到3档的附属效果保留。当前完整容量小于2X时禁用整张牌；不改变装备、不扣能量、不回魔。两面完整执行后恢复15X自身魔力，受原上限限制，临时魔力／魔瓶不作为这项回魔目标。

X为打出前全部剩余能量，候选保存X并由原事务支付。自由面X=0或X>3没有合法品质／紧度组合而禁用；拘束面X=0可以打出但不收紧、不回魔，X>3只要容量足够即可。复放沿用原X并重新检查剩余容量，不能完整执行则跳过该次复放，不追加回魔。休息房禁止自由效果等原阶段规则保持。

RuleChangePackage：影响卡牌定义／双面区别、共用X费用、随机装备选择、收紧、回魔、奖励池与玩家说明；不增加GameState／快照字段、随机域或UI直写入口。预演临时隔离并恢复状态和反馈，不消耗随机、不写外部日志；实际装备／收紧／实回魔以结构化事件进入原行动摘要与日志。手牌、图鉴保留完整2X／15X公式和不足禁用说明，具体预览同时展示当前X与收益；英文目录及词表同步。十四交互轴仅费用、品质／紧度、现有安装资格／容量、装备触发、资源回报与原复放相关，姿势、伤害、施法、回合、捕缚、特殊装备与其他规则不变。

验证用例归既有card_power，覆盖X=0/1/2/3/4、每件独立求和、只剩1位置拒绝／恰好2位置成功、无替换、收紧不足原子拒绝、预览只读、旧版本拒绝、回魔封顶、免费复放继承X／不足跳过、实际存读不重复、两角色与抵挡边界、休息自由禁用。窗口沿card_power，核对X费、原图、罕见与完整文案、实际点击佩戴及不足时零变化；rewards验证正式随机池可达，application验证原施加行为。不新增套件，不截图、不打包。


自缚验证结果：20260914T065430605-47564 的card_power／application／architecture／content共2179项通过，源码指纹稳定。补齐角色2／休息边界及英文后，20260914T065903980-45828 的localization／card_power／application／architecture／content／rewards共2917项全部通过，正式奖励抽样包含自缚。窗口初次两条失败来自测试在首次渲染前设置牌面被原抽牌定向覆盖，改为首次显示后通过真实右键翻面；未改游戏默认牌面。20260914T070308720-44332 的完整card_power窗口307项全部通过，包含X费、原图、完整公式、实际两件佩戴与空间不足无变化。后两轮因同时进行的其他工作区修改标记source_changed，不声称冻结源码全量门禁通过，也不无限重跑其他任务的在途改动。git diff --check通过；不截图、打包或发布。

## 秘密武器（2026-09-14）

稀有奖励遗物，加入普通奖励、宝箱、商店与套娃稀有来源。脚趾可代替手部施法，选手部／脚趾合法路线中的较高成功率；独立口部路线、无部位和明确身体豁免仍按原规则。脚趾只要有真实覆盖拘束便不可用于施法，最终成功率为0%，必成与最低成功率不能绕过。脚趾代替的是施法，不放开握持、工具、药剂或体术的手部条件；火球手势和控火手部施法条件可由脚趾满足。

持有时，空脚趾施加优先级从普通档提升至嘴部／手指同档，仅次于空手腕；已有脚趾装备仍落回原追加档。来源模板、精准部位、容量、层级、合法性、闪避与替换机制不变，不更改卡牌超级顺延的解除排序。

用户授权自行调数值：牵扯按真实覆盖脚趾的每个物理件品质＋当前紧度合计2／3／4／5／6，分别增加1／2／3／4／6基础快感，多件累加。每次花能量的行动触发一次，2能量不额外倍增；熟练而已的额外牵扯同样触发。复用原快感来源倍率（含大理石、平板锁等）、上限保护与高潮结算，无新增敏感度倍率。普通／复合覆盖共用equipment_at，拾取时已有拘束立即生效，降档立即重算，解除后停止。现有特殊装备没有通用品质紧度表，本表只属于秘密武器，不回写特殊装备规则。

RuleChangePackage：状态为遗物持有及实时派生牵扯；无新存档字段、随机域或迁移。候选／事务涉及施法部位准入、最高概率选择、统一施加优先级、统一消耗能量牵扯；数值注册于遗物表，结构化法术事件保留hand类别并新增实际source_part。其他交互轴包括锁／层序／姿势／工具／移动／资源／魔力池／回合均沿原规则；未涉及的规则不改。玩家可见文字覆盖稀有遗物效果及分档、专属SVG图标、图鉴共用展示、手部／脚趾概率对比、拒绝原因、真实施法来源日志、行动风险与状态详情，英文回退同步。无新增文学叙事，现有通用施法叙事沿用。

测试并入relics下secret_weapon_cases，覆盖casting／installation_priority／pressure／persistence交互，不复制到多套件；复用casting窗口验证图标、概率、禁用及实时状态，无截图。相关完整规则分类relics／casting／installation_priority／application／pressure／architecture／content／localization；不打包或发布。


## 2026-09-14 魔血平衡调整

RuleChangePackage：魔血力量加成3→2、稀有→罕见，共用定义同步奖励池、商店定价、图鉴与中英文说明。每玩家回合开始快感＋5保持；既有实例按稳定遗物ID读取新值，无需存档迁移，不改变已冻结商品价格。正式体术／挣扎属性读取共用修正，不新增状态、事务、事件、随机域或叙事。十四交互轴除力量数值外保持。更新rewards规则／窗口现有真实伤害与奖励池断言，覆盖回合效果、预览只读、失败不变和存读档；content／localization复核共用说明，不打包。验证结果见docs/verification.md后续记录。

秘密武器验证：20260914T071730474-48696 的 localization 70项通过；修正测试中近身短打要求双腿自由的夹具，改用2能量接连挣动，并修复无捕缚时原能量上下文为0导致漏触发的问题。20260914T071956026-8264 的 relics／application／architecture／installation_priority／content／casting／pressure 共2990项通过，casting窗口55项通过。合计相关规则3060项、窗口55项，无新增截图。最后运行因并行源码修改标记 source_changed，仅记录断言通过，不声称最终合并版本冻结通过；不打包、提交或发布。


## 2026-09-14 自适应分区与紧凑解缚详情

RuleChangePackage见docs/release-interface.md。身体框与分区列收窄，小部位字体放大，按实际高度保留多区，溢出按开启顺序收起；单区过长内部滚动。详情缩小图标及空白，手胸／臀腿显示正式小数严密度，确认按钮固定页脚。高亮保留按钮边距，避免拖牌时几何变化。无规则、存档、数值或事件变更。

20260914T071957134-48380：architecture／localization共139项通过；body_layout／targeting／equipment_complete／keyboard／touch共403项通过，含精确高度及少1像素、单区滚动、多个展开、刷新只读、小数严密度、固定确认按钮、真实拖牌与出牌结算。此前窗口失败暴露高亮覆盖紧凑边距及确认按钮被滚动裁切，修复后原断言通过。当前有其他任务同时修改源码，检查器标记source_changed，不能作为冻结工作区或发布门禁通过证明；不追加全量测试。已查看build/ui-release-region-panel.png、ui-release-adaptive-panel.png及ui-release-numeric-panel.png，确认标题数值横排、层级列表及固定页脚无裁切。不打包或发布。

## 奖励页顶部遮罩接缝（2026-09-14）

RuleChangePackage：顶栏高62，旧奖励遮罩从78开始，漏出16像素背景。普通奖励／套娃／开场奖励共用reward_backdrop，读取实际GameHeader底边并换算奖励容器局部坐标，遮罩覆盖到底部900，保持各奖励内容位置与原透明度。顶栏继续可访问；没有新文本，changedUiAndLogs=N/A（仅消除背景接缝，原标签、日志不变）。状态、规则、候选、资源、回合、随机和存档及其他交互轴均不变。rewards／home窗口沿已有真实领奖流程核对三种布局的遮罩全宽、上下边缘及顶栏排除，复用architecture；不新增截图、不打包、不发布。


2026-09-14 魔血：已改为罕见、力量＋2，回合开始快感＋5保持；新生成商店按罕见65魔力定价。localization／content／rewards规则1116项通过；rewards窗口309项中仅双重解锁提示断言失败（tests/reward_ui_cases.gd:138），魔血图标、真实回合与＋2伤害预览检查通过。同期其他源码仍在变化，报告为source_changed，不记整批或冻结全量通过。报告spire-godot/build/checks/20260914T072117822-45376/summary.json；未打包。

2026-09-14 马眼棒立绘差分依附平板锁：`SpecialEquipment.portrait_layers`要求任意平板锁与导尿管／独立马眼棒条件同时成立，单独马眼棒不再错误叠加基于锁体制作的差分。既有普通平板锁无差分、导尿管平板锁有差分用例保持，并新增普通平板锁＋独立马眼棒及单独马眼棒反例。`20260914T072907893-49312`的architecture规则69项、equipment_art／hero_art窗口219项全部通过，源码前后指纹一致；未重做素材、截图、打包或发布。

遮罩验证：20260914T072428777-48320 architecture 69项通过；home执行113项，本次开场奖励遮罩两项通过，另有既有PLATE LOCK HOME状态／加固带文字检查失败。20260914T072536852-40220 rewards执行313项，本次普通与套娃遮罩四项通过，另有REWARD UI final unlock segment does not promise a third lock文案检查失败，且运行期间并行修改导致source_changed。未改动这两项无关文案／行为，不宣称完整UI门禁通过；无截图、打包或发布。
## 2026-09-14 出狱临时检查与显示楼层校正

- 以地图实际显示的10—11层为准（内部9／10），候选与中文／英文说明同步，继续排除休息与宝箱。出狱到期在同一正式结束回合中自动执行一次正常规则的临时检查；违规处罚且最多追加8回合，下次到期重新检查。通过才执行出狱装备判定并打开起点选择。
- 临时检查不插入回合、不改变正常巡视倒计时；同回合正常巡视仍按期到来。持钥匙或反抗时正常巡视暂停，但到期检查仍执行。复用已有检查次数与延期字段，不提升快照52、不迁移、不打包。
- `20260914T072424293-48388`：localization70、architecture69、content380、persistence593、prison935，共2047项规则通过；route134、prison160，共294项窗口通过。案例含重复延期、多类违规只加一次、周期同回合边界、钥匙暂停、过期命令原子拒绝、保存恢复、显示楼层边界与正式延期后继续操作。
- 报告为`source_changed`：测试期间另有departure_ui_cases、release_view、英文目录、equipment_art_ui_cases与special_equipment修改；未把用例通过写成固定源码整批门禁通过。本任务代码未因这些修改回滚或覆盖，相关实现记录见`docs/prison-release.md`。
## 2026-09-14 更新出狱练习入口

- 练习菜单现在分别提供检查通过、违规延期、击败出口守卫。前两项均从19／20回合开始；延期项由真实道具工厂预装一件低墙缝小石片，包含正式墙面位置，玩家结束回合后真实没收并延长8回合。再实际完成8回合，正常临时检查通过并打开10—11层起点选择。守卫练习说明同步稀有三选一、遗物、60魔瓶及起点范围；菜单和开场提示均有英文。
- RuleChangePackage见`docs/prison-release.md`；只改练习配置、对应初始化与文案，不新增正式规则、存档字段或旁路命令。窗口检查直接从新练习按钮进入，已删除测试里手工制造缺装的替代夹具。
- 首轮`20260914T074055848-35216`：localization70、architecture69、content380通过；prison发现预装工具缺少具体墙缝位置，已补上`Space.attachment_position`。
- 修复复查`20260914T074248079-46568`：prison959项规则、prison170项真实窗口用例全部通过，包括有效初始化、没收、期限／正常周期、保存恢复、8个实际回合和新地图选择。运行期间其他源码有同期变化，报告为`source_changed`，不宣称固定源码的整批门禁通过。没有打包或发布。


## 战斗施加后自动展开身体区域（2026-09-14）

RuleChangePackage：正式行动成功后，以提交前后只读body_regions.targets的物理ID对比确认新增或替换的拘束具，自动展开受影响区域并更新展开顺序；普通、复合、链接及特殊装备均复用其正式区域投影。仅战斗内动作生效（包含该动作结算进入奖励／整备），不在开局、读档、SL、非战斗行动、普通重绘或失败提交时自动展开。同件纯加固／降档不触发；手动收起保持到后续真实施加。只展开左侧区域，不选择装备、不弹出详情、不派发额外动作；空间不足继续按实际高度收起旧区域，最新区域可内部滚动。

不新增游戏状态、存档、随机或事件，不改变施加资格、数量、部位、层级、费用、回合及十四规则交互轴。玩家文案N/A：使用已有区域名称、计数、展开／收起标志；无新日志或叙事。body_layout窗口补真实结束回合施加、旧版本拒绝、同数量替换、手动收起与刷新、加固反例、非战斗隔离及只读断言；复用architecture与display窗口覆盖场景刷新边界，不打包。

## 基础动作部位与左侧能量徽标（2026-09-14）

RuleChangePackage：基础动作栏统一采用32像素左侧能量徽标（复用energy-medallion.svg，数字读取candidate.cost），右侧主行显示名称与伤害，次行显示部位、耗魔、次数和成功率。删除主副两行的重复能量消费字样，0费与不可用状态均保持徽标；右下快捷键不变。深呼吸同样采用徽标，并保留次回合回能效果说明，它不是当前费用。使用部位由只读GameView投影：肘击双臂，近身短打双臂／双腿，踢击双腿，魔法采用正式casting.source_part，覆盖秘密武器脚趾替代、魔女部位及无部位施法。深呼吸读既有正式嘴部判定与效果。

没有修改费用、伤害、施法、部位资格或动作规则。点击、拖拽、右键换式、快捷键、禁用原因和详细悬停继续用原候选；日志N/A（原结算事件未变），结构化状态、回合、随机、存档与其余交互轴不变。中英部位／效果文案同步，窗口检查费用徽标的0／1切换、部位说明、文字与徽标不重叠、热点保留及实际付款。运行basic_attacks／architecture／localization规则和basic_attacks／casting窗口，不新增截图、不打包。


2026-09-14 战斗施加自动展开：正式提交成功后按区域投影中新增物理ID展开左侧对应区域，兼容同数量替换；手动收起不被普通刷新重开、不弹详情。body_layout完整窗口145项通过且源码稳定，报告spire-godot/build/checks/20260914T075354234-48868/summary.json。首轮architecture69项通过；display窗口另有语言切换后身体标签旧断言失败，本批不改翻译路径，未记跨分类全绿；首轮新增测试误用行动分组已修正并完整复测body_layout。未打包。


2026-09-14 基础动作栏验证：build/checks/20260914T075316120-20556 中 localization 71、basic_attacks 181、architecture 69，共321项规则断言通过；basic_attacks 87、casting 55，共142项窗口断言通过。覆盖左侧0/1费用徽标、部位只读投影、文字对齐及真实点击/拖拽/招式切换。运行期间其他任务修改源码，报告为 source_changed，不宣称固定源码整批门禁通过。同步修复阻止语言包加载的已有守卫增援英文占位符格式；不打包、不发布。


## 2026-09-14 监狱探索警卫战援军

按用户最终要求做成战场负面效果，开战起每4个完整回合召来1名警卫，全场上限1＋警戒度，胜利立刻取消；出逃战不生效。RuleChangePackage与规则边界见docs/prison-reinforcements.md。复用正式敌人创建、结束回合、状态投影、存档复核；新警卫出生回合不行动，先手／后手及原警卫阵亡均不改变场地时钟。

20260914T075204241-16528：prison 1135、guard 40、status 299、intent 89、architecture 69、content 380项通过；新增用例包含4回合边界、警戒度1／2／4上限、打断不中止、原警卫阵亡、胜利取消、奖励整备、出逃排除、存读档重放、过期提交及坏存档原子拒绝。该轮localization因英文参数格式被拒绝，随后词条改为兼容包的{pN}格式；20260914T075522198-20088 localization 71项通过，guard窗口69项通过，验证常驻倒计时、新警卫真实目标和共享计数。首次测试误期望返回牢房后保留已退场敌人列表，按原正式清场行为改为列表为空，并保留无召唤事件断言。工作区存在其他任务并行修改，source_changed不作为冻结源码／发布门禁通过证明。未跑全量、未截图、未打包或发布。


## 基础动作费用居中与禁用原因（2026-09-14）

RuleChangePackage：费用数字关闭自动换行并固定居中，避免最小高度撑出徽标。不可用动作保留部位行，在底部单独显示11号红色简短原因；说明关闭自动换行并限制在按钮内，悬停继续显示完整正式原因。常见双臂／双腿限制、站姿、次数和无力化仅缩短显示文案，中英文同步；不改变候选资格、费用、状态、随机、回合、存档、输入或日志。窗口补齐实际布局后的徽标数字矩形、禁用原因颜色／位置／裁切和腿部限制反例；复用basic_attacks、casting窗口及architecture、localization规则。


2026-09-14 动作栏对齐复验：关闭费用数字自动换行后，实际布局中心与32像素徽标中心一致；不可用动作使用24像素标题行、17像素部位行与17像素红字原因行，按钮增至60、整栏72像素，仍与手牌区分离。首轮140项localization／architecture规则通过；窗口发现中文字形最小行高17超出原14像素分配，已修复并补齐正义飞踢简短原因。最终build/checks/20260914T100955306-55060中basic_attacks105、casting55，共160项窗口断言通过，源码稳定。未打包或发布。


## 2026-09-14 警卫开场满位加固

RuleChangePackage：首回合三处apply原有replace权限保留，补tighten_missing；不足次数通过共用加固候选，仅限该操作required_slots真实覆盖部位，1次只加固1件／1档。满3档可上锁时复用加固上锁与满耐久，空位先施加、合法替换先替换、不原样替换。被闪避的次数不转加固；无加固目标则落空，不跨部位补装。共用targets增加可选部位过滤，默认空列表保持六缚等原全身后备行为。已保存首回合旧意图执行时补同样后备，不增加存档字段。首回合后循环、准备、捕缚、随机域、资源费用及其余十四交互轴不变。图鉴／练习中英说明同步，实际日志沿既有施加、替换、加固／上锁与落空日志；不新增叙事。guard增加满位低品质替换、高品质加固、3档锁恢复、跨部位反例、只读／过期拒绝、存读档与阶段推进；关联application、replacement、enemies、intent、persistence、content、localization。不打包。


警卫首回合修复验证：20260914T104131444-3824中localization／replacement／application／architecture／content／intent／enemies全部通过（2590项）；guard初轮70项仅“满3档加固上锁”测试失败，原因是测试持有被正式安装流程更新前的字典引用，已按稳定ID读取最终装备并补旧意图存读档用例。20260914T105830535-51180最终guard规则75项、完整guard窗口69项全部通过；同期其他源码变化，报告source_changed，保留专项通过记录，不标记冻结全量通过。git diff --check通过。未打包。


## 2026-09-14 其他人形敌人装备流程排查

范围：按humanoid注册逐项核对玩偶师、玩偶、六缚、多面手、奴隶贩子，并回归已修复的警卫。installation_intents与实际application_spec均保留替换权限；普通空位优先、满位比较及结构封闭仍沿Application/Replacement。六缚开场与收尾逐区域、双重束缚缺额及复合失败已有各自加固分支；多面手有独立上锁／双件加固。奴隶贩子按准备就绪确定实际紧度并执行指定偏好；玩偶受击的普通及预备附加仍沿正式人形施加。未发现第二处与警卫首回合同类的漏接；没有将警卫新增后备扩展到其他未声明此效果的动作，也未修改运行规则。

测试补入已有enemies分类：枚举全部当前人形来源、确认只读权限和真实满位替换、保持原品质与无关装备、替换日志、六缚初／中级区域施加失败后加固、多面手双件3档上锁和满耐久、无目标不反向补装。无新状态、候选、数值、事务、随机域、存档、UI或玩家文案；RuleChangePackage.changedUiAndLogs=N/A（仅审计及测试，运行表现不变）。专项结果随后记录；不打包。


人形流程审计验证结果：20260914T111017278-57252完整enemies1793项通过且源码稳定；20260914T111220973-8144完整battle_saturation34项通过（首次临时脚本加载错误已在重试消失）。20260914T110818892-48760中replacement／application／intent／guard／trader均通过；新增审计夹具初轮误用了六缚练习ID、并把奴隶贩子初级施加预期写成中级，已修正夹具并完整复测enemies，未因此改动游戏规则。已核对所有当前人形的替换权限、正式满位替换、规定的加固后备和全场无操作后的逮捕条件，未发现新的规则漏接。未运行全项目或重新打包。


## 2026-09-14 监狱巡视榨精与正常出狱对白

每次例行巡视接受检查结果时，以及每次刑期到期的额外巡视中，均通过正式检查事务追加一次狱警手部榨精。复用通用高潮身体、装备及遗物反应，高潮总数增加1，自身魔力立即损失`min(20，当前魔力)`；不打开战斗高潮覆盖层，不生成高潮后乏力或滑精两回合延迟。低于20魔力、平板锁、平板锁且低魔力分别选用稳定文案cue，重复接受已完成检查不能重复结算。正常出狱在重建塔路后仍显示一次无名字的棕发资深狱警对白框；例行巡视固定显示紫发狱警。两张用户指定图片已按透明抠图流程替换原警卫资源，来源、裁框和哈希见`assets/art/enemy-guards-v1/README.md`。

最终门禁`build/checks/20260914T112747431-54388`源码前后指纹一致：localization、architecture、content、action_copy、prison、guard、pressure共2989项规则断言全部通过；prison真实窗口212项全部通过。窗口流程实际确认巡视到来、接受检查、扣除20魔力、平板锁低储量正文、两张狱警立绘、无名字对白框和正常出狱后对白。未运行全项目、未生成截图、未打包或发布。


## 2026-09-14 收押与巡视短文案

收押页移除保底规则、状态保留与战后奖励说明，改为押送和登记演出加三项实际数量；巡视页移除检查次数、清单原理、事务过程与重复规则提示，公开和完成结果改为短句。进入牢房后新增无名字棕发狱警对白。底层检查事件仍保存缺失、请求、实际安装、更新后清单、牌区恢复、电池与延期事实；规则断言因此改读结构化字段，而不要求玩家界面重新显示实现报告。

`build/checks/20260914T114658541-5540`中localization、architecture、content、action_copy、prison、guard共2002项规则断言全部通过，guard窗口70项通过；prison窗口的两项旧长句断言暴露后已改为短文案＋结构化事实检查。最终复验`build/checks/20260914T115315468-54688`的prison窗口216项全部通过，源码前后指纹一致。两轮均未生成截图；未运行全项目、打包或发布。

## 2026-09-14 一次性收押事件页与收押榨精

RuleChangePackage见`docs/prison-release.md`。正式收押先执行既有战斗结束、装备追加与链接安装，再进行一次脚本高潮，立即损失最多20自身魔力，最后执行进入监狱的遗物钩子；主动投降也停在同一个`captured`收押页，确认“进入牢房”后才开始牢房回合或五级终局。捕获记录新增可选`intake_scene`，保存实际普通／复合拘束具、连接绳与性玩具的共用佩戴正文以及榨精差分；旧快照没有该字段时仅使用安全回退，不提高快照修订。原`prison.guard.cell_entry`持久NPC日志已删除，普通牢房回合不再反复弹出收押对白。

规则检查`build/checks/20260914T124444794-54936`中relics、architecture、content、action_copy、prison、guard、pressure共3775项通过；localization在同期目录重生期间失败，随后重新生成英文目录并由`build/checks/20260914T124800800-59224`以73项单独通过。更早的定向`build/checks/20260914T122057604-57588`验证guard 77项及平板锁低魔力差分。监狱窗口`build/checks/20260914T124914202-47392`共217项通过，覆盖事件式收押页、具体装备正文、真实扣魔、主动投降入口和进入牢房后旧对白不复现；运行期间有其他界面源码更新，报告标记`source_changed`，因此仅记录专项通过，不宣称冻结源码全量门禁。pressure窗口先通过本次强制高潮投降分支，后在同期快捷栏改动造成的两条深呼吸显示旧断言处失败，未计为整组通过。

本批没有生成截图、没有打包或发布。为恢复窗口检查，顺带修正同期新增`ui/quick_release_bar.gd`中一个缺失的闭合括号及对应缩进；该修复不改变候选、费用、资源或规则。


## 2026-09-14 体术连击名称截断

RuleChangePackage：名称／伤害默认字号18降至16，按两段实际字体宽度共同缩小，间距8减至6；移除伤害区62%比例限额，以完整文字的测量宽度居中分配。沿已有能量徽章、部位／次数副行及不可用原因，未缩写招式名称或改动作规则、数值、候选、日志、存档与随机。basic_attacks窗口新增肘击连击／近身短打连击，在有／无墙缝工具压缩栏位下测量完整文字、边界、间距及只读状态。20260914T114156443-48444完整basic_attacks窗口123项通过，git diff --check通过。未打包。


## 2026-09-14 体术及身体栏位置互换

RuleChangePackage：体术显示列表交换heavy与kick，顺序为肘击、踢击、近身短打、火球术、深呼吸；身体栏仅在渲染时排序为头颈、手胸、性器、臀腿。原候选列表／规则区域顺序、快捷键绑定、右键招式切换、目标ID、费用、伤害、展开优先级及溢出收起规则不变。没有新增文案、状态、事务、日志、随机或存档；玩家标签沿用现有名称。现有basic_attacks补位置先后断言，body_layout调整预期顺序及最底部可见滚动区高度边界检查，不改底层分区。未打包。

位置互换验证：20260914T114527346-52760的basic_attacks完整124项通过且源码稳定；20260914T114620561-48244的body_layout完整147项通过，但同期其他源码变化，报告source_changed，不标记整批冻结通过。两处位置、展开／收起、实际点击及宽高边界检查均通过；未打包。


## 动作栏切页与快捷挣脱 · 2026-09-14

已接入：右侧零回合切页；四区默认装备／耐久／紧度／锁状态；右键切小部位；先点部位再点挣扎／滑脱牌，以及真实拖牌直接提交；第五格已安装道具；探索、整备及休息保留动作页的深呼吸。费用、目标资格及版本继续由原候选决定，无新游戏状态或存档字段，中英文提示同步，未打包。

- `20260914T120922083-46916`：architecture 151、localization 71项通过，共222；工作区同时有编辑，脚本标记source_changed，仅记录断言结果，不记作冻结源码门禁。该次窗口新增测试误将只读pressure对象当数字比较，修正为测试状态的数值后重新执行相关分类。
- `20260914T121317688-53964`：basic_attacks 158、installed_tools 51、body_layout 147、targeting 83项通过。包括先部位后牌真实点击、真实滑脱拖放、独立区域不变、只扣一次费用、缺能量／旧版本／错误牌面拒绝、切页保留立绘与手牌、右键零消耗、非战斗深呼吸、安装道具及魔瓶不遮挡、英文提示。此批唯一失败为exploration旧远端牢门案例没有确定的开门资格，依赖随机起手含开锁牌，不是横栏功能失败。
- 为该远端测试明确注入持有狱警钥匙的前提，原“需要先到牢门前”及不夹杂其他地点断言保留；玩法代码未改。`20260914T121459900-55468`重新执行exploration完整分类43项通过，退出码0、源码指纹稳定。

五个受影响窗口分类最终合计482项通过（分上述两次结果），没有宣称原组合失败批次整体通过，也没有进行全项目回归。相关规则断言与窗口结果的源码稳定性分别如上记录。截图未默认生成。


## 左侧捕缚拖牌、快捷装备循环、探索火球术 · 2026-09-14

已完成：左侧捕缚整行与战场捕缚共用接收函数；四区上一件／下一件和←／→循环本区物理目标，默认优先最外层可挣扎的最低紧度项；切换联动左侧小部位和展开的装备详情；手动目标保持，失效候选不改打其他装备；X为踢击、V为近身短打；探索显示火球术与深呼吸，自解能力沿原施法候选拖到拘束具或快捷格。

- `20260914T123350477-57924`：keyboard 67、guard 87项通过。捕缚新例以合法牌堆夹具验证拖到标签与条身，两处高亮、实际进度／能量、错误牌及旧版本拒绝、移除捕缚后接收区消失。该批源码变化，`source_changed`，只记录断言结果；同批basic_attacks的火球拖放测试先拖牌再展开部位导致输入取消，调整为先展开后真实拖牌，不改正式接收逻辑。
- `20260914T123737669-58032`：architecture 151、localization 71，共222项规则断言通过；basic_attacks 174、body_layout 147、targeting 83项通过。含默认低紧度目标、实体选择、跨小部位循环、空部位开始循环、左右键、二三级详情联动和不遮挡横栏、X/V真实选择、探索炫火自解实际拖放及正式费用。该批源码指纹稳定，但exploration一条旧安装位置文案断言仍期待“墙缝一”，与当前正式“离地0.2米的墙缝”不一致，因此不记录组合批次整体通过。
- exploration断言改为验证当前正式mount_label及原3次使用数。重新检查时发现同时改动的投降分支有一行Guard.capture缩进脱离elif，修复为仅在surrender分支执行；`core/game.gd --check-only`解析通过。`20260914T124233679-8536`：exploration完整43项通过，退出码0、源码指纹稳定。

相关窗口六分类最终601项通过，规则222项通过；结果来自上述批次，源码稳定性分别记录，不宣称全项目或同一次冻结检查全部通过。早期捕缚新测试直接替换手牌而未同步卡组，被正式验证正确拒绝；改为共用加牌工厂且保留原牌区后通过，未绕过一致性检查。

本地化门禁发现英文兼容表新加入的5条具名占位符未转为p0格式，导致整个兼容表拒绝加载；仅修正参数标记并同步生成脚本映射，原中文及英文正文语义不变。localization重新71项通过。没有生成截图、打包或发布。

## 2026-09-14 图鉴卡牌与实时对局显示隔离

图鉴通过现有卡面入口显式关闭实时卡牌类型／实体投影合并；原牌、衍生牌、双面、魔力角标及悬浮说明统一采用静态注册表。手牌及其他展示默认沿用实时投影，角色专属定义及图鉴筛选不变。只读显示变化，无规则、存档或新文案。

- `20260914T130814854-57824`：card_power完整307项通过；该批`source_changed`，仅记录断言结果。新增图鉴局内夹具最初沿用主页的正式开局，未进入战斗导致取不到手牌控件，改为既有game_fixture；之后改用正式打开抽屉入口，避免直接置位同时留下其他启动抽屉，保留原关闭面板断言。
- `20260914T131234528-7932`：encyclopedia完整158项通过，退出码0、源码稳定。覆盖真实装备使汇流收益及般若汤费用变化的前提、手牌动态效果保留、图鉴基础费用／效果／角标、两面及全部相关衍生牌、不显示即时施法概率、浏览不改快照及实际关闭。

未运行全项目回归，未截图、打包或发布。

## 2026-09-14 拘束具图鉴简洁排版

按最新要求移除通用耐久百分比紧度分档说明；保留装备具体施法倍率及滑脱限制。基础信息、组件明细和特殊效果以空行分段，删除重复组件汇总，整数耐久不显示小数尾零；拘束具正文18号字、行距6。仅改只读图鉴及相应测试，不改规则、候选、数值、日志、随机、存档或其他分类布局。

`20260914T125159535-59980`：localization 73、architecture 151、encyclopedia 495，共719项规则断言通过；encyclopedia窗口82项通过，包含胶带包裹分段、字号行距、完整耐久和口球倍率保留。工作区期间有源码变化，报告`source_changed`，仅记录断言通过，不宣称冻结源码门禁通过。`git diff --check`无空白错误。未打包、发布或生成截图。

## 快捷栏两侧箭头与同栏位键位 · 2026-09-14

四区上一件／下一件改为左右端28×60的整高点击区，三角图形直接绘制，中央文字与键位提示不覆盖箭头。对应栏位的strike／kick／heavy／fireball绑定在快捷页只选择头颈／手胸／性器／臀腿，默认Z／X／V／F；原←／→循环、右键小部位、详情联动及拖牌仍沿原入口。

`tools/check.ps1 -UIOnly -UISuite basic_attacks,keyboard -TimeoutSeconds 300 -KeepGoing`：`20260914T125218834-46768`，basic_attacks 202、keyboard 81，共283项通过，退出码0，源码指纹稳定。检查两侧整高几何、文本与键位不相交、空区禁用、真实点击及拖牌、四个原键位只读选择、自定义Q替代Z、旧键失效、抽屉阻挡和切回原动作选择。`git diff --check`无空白错误。纯UI改动，未运行全项目回归，未截图、打包或发布。

## 快捷框无数字耐久条 · 2026-09-14

RuleChangePackage：装备名称右侧增加48×8的剩余耐久条，只消费现有ratio，隐藏数字和百分比，空部位隐藏；名称留出空间，原悬浮完整名称与耐久／紧度文字沿用。条形忽略鼠标输入，不改点击、详情开关、拖放及原候选。仅显示变化，状态、数值、费用、事务、日志／对白、随机、存档、迁移和十四规则轴不变；无新增中英文文案。

`tools/check.ps1 -UIOnly -UISuite basic_attacks -TimeoutSeconds 300 -KeepGoing`：`20260914T130918718-46368`，完整basic_attacks 226项断言通过。新增当前比例、切换与实际卡牌伤害后更新、空区隐藏、数字隐藏、名称与箭头边界、点击条形开关详情且不扣费；原真实拖牌回归通过。检查期间其他源码变化，汇总source_changed、退出码1，未声明冻结门禁通过。`git diff --check`无空白错误；未截图、打包或发布。

## 快捷框点击开关三级详情 · 2026-09-14

RuleChangePackage：点击快捷框或对应栏位快捷键展开当前目标的原装备三级详情，再次选择同框关闭，保留部位及目标供直接点牌；选择另一框切换详情，箭头和右键切换仍始终展开。空部位只显示原部位页面，快捷模式详情统一保持在横栏上方。只改UI开关和几何，不新增状态字段或文案；原中英文名称、说明及原因沿用，日志／叙事N/A，候选、费用、事务、回合、随机、存档、迁移与十四规则轴不变。

`tools/check.ps1 -UIOnly -UISuite basic_attacks,keyboard -TimeoutSeconds 300 -KeepGoing`：最终`20260914T130353156-59888`，basic_attacks 217、keyboard 87，共304项通过，退出码0、源码稳定。覆盖同部位多件装备的精确三级展开、同框关闭／重开、关闭后实际点牌效果、跨框切换、快捷键开关及空部位窗口不遮横栏。此前`20260914T130213557-52928`的299项检查是在用户追加关闭要求前启动，不作为最终版本门禁。`git diff --check`无空白错误；未截图、打包或发布。

## 快捷栏补齐降紧与开锁 · 2026-09-14

RuleChangePackage：修复快捷卡牌模式过滤遗漏lower／unlock，魔力撑除及开锁牌均复用原选中物理目标、卡面、候选ID和版本，经原事务执行。UI匹配及中英文不适用提示／探索说明受影响；状态、数值、施法成功率、费用、回合、事件、日志、叙事、存档、迁移、随机与十四规则轴不变。无有效目标仍显示原候选原因，禁止改用其他可用装备。

`tools/check.ps1 -Suite localization -UI -UISuite basic_attacks,casting -TimeoutSeconds 300 -KeepGoing`：`20260914T125921838-56060`，localization 73、basic_attacks 212、casting 55项断言通过。新例覆盖多件装备中先选目标再真实点击魔力撑除、精确降紧及费用、无锁目标拒绝且不改打另一件、缺魔拖放拒绝、旧版本及自由面拒绝、真实拖放开锁一次。共267项窗口断言通过，但检查期间其他源码有变化，汇总为source_changed、退出码1；此记录不代表冻结源码门禁或全项目回归通过。`git diff --check`无空白错误。未截图、打包或发布。
## 2026-09-14 狱警巡视事件页与紫发狱警透明图修复

RuleChangePackage：正式`inspection`候选、结算、处罚、榨精、反抗和巡视周期保持不变；仅把arrival／result／done三个阶段集中投影为事件式页面，并移除普通巡视事件中的持久`npc_copy`，避免浮动对白覆盖牢房或跨阶段重放。延长8回合仍作为结构化结果显示，狱警对白不再念规则数值。紫发狱警继续使用用户原图，本地边缘分离提高白色阈值并补充尾巴封闭区背景种子，保留白手套、丝袜、手臂和腿部，不生成、不重绘。英文目录、UI回归及规则对照同步；不改变状态、随机、数值、事务和存档格式，不截图、不打包。

验证：`20260914T131733355-43252`的localization／architecture／action_copy／prison共1551项规则断言通过；prison窗口执行217项，仅旧测试把带已安装工具的结果误当成完全合规而失败，实际页面已正确显示藏工具差分，断言随后按结构化场景修正。复跑被同期删除、仍由角色2入口引用的`core/witch_expansion.gd`阻断，未擅自恢复另一批文件；本批Godot导入在该同期删除前为0错误。未截图。

## 2026-09-15 单手套拘束具立绘差分

RuleChangePackage：使用用户提供的两张对齐原图，通过本地脚本提取银白套体、黑色肩带与扣件的像素差异，并生成普通和平板锁组合的透明替换底图及大腿根切片。`GameView`从真实复合拘束具投影`composite_portrait_layers`，只有主体仍有效的`glove`根启用该显示；短型、长型与肩带样式共享差分。左侧装备肖像和战斗受限站姿同步，解除套体后恢复原图。规则、数值、候选、费用、事务、回合、日志、叙事、随机和存档不变，无新增玩家文案；没有调用图像生成工具。

验证：`build/checks/20260914T142422863-63312`完成Godot导入，architecture 151项、equipment_art 176项通过；战场快照发现只读字段未随英雄快照复制后，统一经`EquipmentPortrait.snapshot`传递并复测。最终`build/checks/20260914T142821261-39696`中equipment_art与hero_art共231项窗口断言通过，覆盖短／长单手套、普通／平板锁组合、左侧与战场同步及状态只读；截图`build/ui-equipment-single-glove.png`、`build/ui-hero-single-glove.png`和`build/ui-hero-restrained-special-equipment.png`已人工查看。未运行全项目回归，未打包或发布。
## 2026-09-15：小魔女三姿势与身体栏立绘

- 本地抠图：站、坐、躺三张用户原图均保留RGBA透明通道与原始比例；坐姿仅补清帽内及脚／斗篷间白底，未使用会吃进大腿的白色连通区；躺姿补清双腿间白底。左侧身体栏使用站姿窄裁版。
- 左栏构图：专用裁框由源图`(140,0,1060,2304)`平移为`(460,0,1380,2304)`，显示宽高比不变；按人物身体中心而非帽檐与斗篷的整体透明重心定位，使人物在178×454画框内向左移动并居中。
- 显示边界：战场只读取View中的角色与姿势；小魔女佩戴拘束具后仍使用对应默认姿势，不借用角色1差分。角色1原有自由、拘束及固定立绘路径保持。
- 规则影响：N/A。图片与映射不改候选、费用、事务、事件、日志、随机、存档或任何装备判定；玩家可见文字沿现有角色和姿势名称，无新增机械文案。
- 自动检查：`tools/check.ps1 -RerunFailed build/checks/20260914T145515294-42952 -TimeoutSeconds 300`稳定通过；`architecture` 158项，`display,home,equipment_art,hero_art` 485项。首轮导入和截图轮的同组断言也全部通过，但因工作区同时有其他既有修改而被指纹门禁标为`source_changed`，最终稳定轮退出码为0。实机截图`build/ui-witch-portrait-stand.png`、`sit.png`、`lie.png`已检查三姿势切图、透明背景、原始比例、落地线和左栏窄裁显示。
- 左移复核：最终裁图重新导入后，`tools/check.ps1 -Import -UIOnly -UISuite hero_art -Screenshots ui-witch-portrait-stand.png -TimeoutSeconds 300`通过64项；截图确认人物身体位于左栏画框中部。

## 2026-09-16 事件选项状态条件的存档校验（`has_relic` 读档失败修复）

缺陷（仅存在于未发布的本地提交）：`4441120` 为漂浮皮带群加入 `has_relic` 状态条件后，冻结选项把它带进存档，而 `core/snapshot.gd:391` 仍只接受 `kind=="no_chastity_lock"` 且键集必须为 2。持有「软化扣环」进入该事件时写出的存档在读取时被判「事件选项的状态条件损坏。」，`Store.unpack` 与 `restore_snapshot` 均拒绝，该存档槽无法继续。写入侧 `SaveStore.write_game` 只跑 `game.validate()`，而事件 `validate` 不检查 availability，所以保存会成功、失败只出现在读档——不对称是本缺陷难被发现的原因。`e635bf5`（v0.17）不含 `has_relic`，缺陷不在任何已发布版本中。

RuleChangePackage：`core/snapshot.gd` 的状态条件校验改为按 `kind` 复核键集——`no_chastity_lock` 恰好 `{kind,reason}`；`has_relic` 恰好 `{kind,type,reason}` 且 `type` 必须是已登记遗物；未知 `kind` 或多余键一律拒绝。`content/README.md` 同步记录两种条件的键集与"新增条件种类必须同时扩展存档校验"。规则、候选、费用、事务、随机、存档格式与旧档兼容性不变。

验证：`tools/check.ps1 -Suite persistence,events,event_flow,content,architecture -TimeoutSeconds 600 -KeepGoing`：`build/checks/20260916T023640988-18172`，architecture／event_flow／content／persistence／events 全部 PASS，共 2118 项断言。新增 `tests/persistence_cases.gd:event_conditions`（持有遗物时的事件往返 + 五类畸形条件的原子拒绝）与 `tests/content_cases.gd` 的 `has_relic` 正例及三类反例（缺 `type`／未登记遗物／多余键）。反向对照：临时撤销 `snapshot.gd` 修复后 `-Suite persistence` 复现真实错误（`build/checks/20260916T023516144-10164`，persistence FAIL，1/604，"无法继续这份存档：事件选项的状态条件损坏。"），证明该断言确实覆盖本缺陷。未运行全项目回归、未截图、未打包。

## 2026-09-16 E0 事件等价判据：比较器类型缺陷修复与判据身份登记

缺陷（**判据侧，不是产品行为**）：`build/event-oracle-20260916/event_oracle.gd` 的比较路径用 `JSON.stringify` 比对进程内整数与从基线文件读回的浮点（Godot 4.7 的 `JSON.parse_string` 把所有 JSON 数字解析为 float），所以基线一旦冻结，94 个场景恒判红（差异形如 `count: 4.0 -> 4`）。实现者在改动任何产品代码前停下上报，并给出独立证据：以 `--write=` 重放写出的文件与冻结基线逐字节相同、摘要仍为 `1f11bea5…`——据此把"判据坏了"与"行为漂移"分开，协调者裁决后才动手（授权范围仅比较路径，冻结基线与捕获路径一字不动）。

修复：仅新增 `_normalized()`，把基线侧整数值 float 归一为 int 后再比较；场景集合、捕获路径、摘要算法、基线文件均未改动。

验证（域：E0 oracle 判据，`build/` 产物）：
- 干净跑：退出码 0，`EVENT RESULT: PASS (94 scenarios, 0 failures)`，`EVENTDIGEST 1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da`（＝契约 §0.1 记录的基线摘要）；日志 `build/e0-diagnostic-20260916/compare-fixed.log`。
- 反向对照（证明判据不是永远绿灯）：进程内注入两处真实漂移（`start:abandoned_storeroom` 的 `count` +1、`choose:binding_cleric:purify` 的 `view` sha256 首位改 0），退出码 1、`FAIL (94 scenarios, 2 failures)`，逐条打印场景与字段差异，摘要同时变红（`1c640cde8a6e83a64404d8c153cd92711a2d44c0a228c581650bcc01703f7306`）；日志 `build/e0-diagnostic-20260916/compare-drift.log`，漂移副本 `event_oracle_drift.gd`。
- 捕获侧未变：`build/e0-diagnostic-20260916/rows_after_fix.json` 与冻结基线逐字节相同（各 50744 字节，`cmp` 通过）。
- 判据身份（`build/` 已 gitignore，脚本不进仓库，故登记哈希作为复核依据）：脚本修复前 `651890ac192f0d3e836b3b7fd6616ce4263e8ae788d8993658c0932082b6725a` → 修复后 `cf48529a19af7773f4d8ac6be343a759fa6038151942fdf66dd249c89e20557f`；基线 `bdf08765f8dea0c1f6ac489245abd689907fd6974f794b7cea1e98d7a090e9c8`（未变）；漂移副本 `d12652336d4246ecaee94c08093bfb9faff42d57944ff2314f9dcbf19c47245b`。四个哈希与 `cmp` 结果已由协调者独立复核。
- 产品代码零改动（本项全部落在 gitignore 的 `build/` 内）；事件管线 B1 的判据自此可用字面退出码。

判据适用说明：B1–B4 的分类门禁以**增量**判定——红集必须恰好等于 `docs/verification.md` 已登记的既有阻塞项（当前为 `card_power` 的 5 条 `witch_*`），多出任何一条即停手上报；`card_power` 的修复不在本片范围，另行排期。

## 2026-09-16 B1b 作者文档同步（事件节点形态）

RuleChangePackage（文档与测试，零产品代码）：`spire-godot/content/README.md` §3 事件整节重写为单一节点形态（`start_node`／`nodes`／`schema_version: 2`、七个节点声明键与取值、合并后的选项白名单含"适用形态"列、起始节点免费出口只约束多节点、`availability` 两形态都生效、完整示例只指向两个模板）；`docs/content-templates.md`、`docs/content-generation.md`、`docs/content-extension.md` 同步到节点形态，模板为真源、文档跟随；已死的选项级 `pressure` 示例删除，B1 之前就不被校验接受的 `wager`／`reward:"keys"` 改为显式标注为早期设计记录（不整段删除）。新增具名 check：`tests/architecture_cases.gd` 的 `event_dependency_edges_pinned`、`event_definition_accessors_only`，`tests/content_cases.gd` 的 `event_author_manual_lists_current_fields`（读 README §3，字段 token 必须落在校验器词汇内，并逐条把文档里的声明取值拿去编译）。内容包与模板未改动；oracle／基线、契约、`core/`、`ui/` 未改动。

验证（提交 `a57dec3`，父 `c0b6a1d`；域：文档同步 + 事件分类）：
- E0 等价：退出码 0、`PASS (94 scenarios, 0 failures)`、`EVENTDIGEST 1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da`（与冻结基线逐字相同）。
- 内容包：`tools/check-content.ps1` 退出码 0、`CONTENT PASS: 12 file(s)`；模板探针 `tools/check-content.ps1 -Path build/b1b-docs-20260916/template-probe` 退出码 0、`CONTENT PASS: 2 file(s)`。
- 规则门：`tools/check.ps1 -Suite event_flow,events,content,architecture -TimeoutSeconds 600 -KeepGoing` 四类全 PASS；`-Impact` 展开集的唯一红项分类＝`card_power`（5 条 `witch_*`，登记于本文件第 29 行），未多一条；断言总数由 B1 的 10339 增至 10523（文档 check +184）。
- 旧形态残留：对四份文档检索 `start_stage`／`"stages"`／顶层 `choices` 零命中（`rg` 退出码 1）。协调者已独立复核上述 E0、四类套件（2147 断言）、内容包与模板探针三项。
- 具名 check 非空洞性：`event_author_manual_lists_current_fields` 在修正 `allow_refuse` 取值拼写前真实红过一次（`EVENT MANUAL node declaration documents every accepted value: allow_refuse ["true","false"]`）。

遗留（另行排期，不属本批）：①`docs/event-structure.md` §1 结构地图仍描述 B1 前的 `stages/start_stage` 形态（该文件是规划者契约，须由其加注或修订）；②本地化词表漂移——`assets/localization/legacy-en_US.json` 仍登记 B1 已删除的校验文案，新校验文案缺译（按已定义安全回退显示源文，无玩法影响）；③`docs/content-generation.md` §7.4 的早期设计记录是否彻底移除属文档裁定。未跑：`-Suite all`、打包与发布门禁（本批零产品代码改动）；未推送、未打包。

## 2026-09-16 B2 事件管线：声明表、单求值入口与叠加条件（含 B2b 收口与本地化）

RuleChangePackage（规则内重构，行为逐字节不变）：事件选项的资格判定从四条并行通道（`condition_met`／`availability_issue`／`hide_when_unavailable` 探测／遗物池闸门）收敛为**一份 `CONDITIONS` 声明表**，由它派生四处——运行时求值（`condition_probe`）、内容校验（`condition_issue`）、存档键集（`condition_saved_fields`）、trace 命名；新增**唯一求值入口** `evaluate_option`，返回逐条 `gates`（`gate`／`kind`／`mode`／`index`／`detail`／`reason`）与四种 `decision`，多命中按声明序以 `"\n"` 连接；`enter_node` 成为唯一节点管线，B1 遗留的"节点数分支"消失，七个节点声明（`frozen_form`／`relic_gate`／`random_freeze`／`outcome_draw`／`unavailable`／`empty_node`／`allow_refuse`）全部生效；新增规范拼写 `conditions`（1—8 条、每条 `mode∈{optional,hidden}`）与选项级 `unavailable`，与旧拼写互斥校验；`probe`／`candidates`／`execute`／`view`／`validate` 不再读 `flow` 镜像；删除选项级 `pressure`／`pressure_source` 死分支；`snapshot` 事件段**增量**补键集（保留原有 `flow` 分支全部检查，不以放宽换统一）。同批刷新英文字典。

**关键判据口径**：`frozen_form=="in_place"` **且选项无 `selector`** 时用 in_place 冻结布局，其余一律 staged（依据：选择器选项历来走共享 staged 构建器，改判据会让 `temper`／`dissolve` 的冻结 id 与 `selected` 键变化 → E0 必红）；`validate_failed` 与 `node_empty` 的具名 gate 缓到 B3（要单独命名须先拆 `probe()` 内部）。

验证（提交 `60869fc`（核心）→ `5a60cda`（B2b）→ `b6d45b5`（收口）；域：事件分类 + 存档 + 本地化）：
- **E0 等价**：退出码 0、`PASS (94 scenarios, 0 failures)`、`EVENTDIGEST 1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da` —— 三次提交后各自复核均**逐字相同**（协调者亲自重跑，非采信报告）。
- **规则门**：`tools/check.ps1 -Suite event_flow,events,content,architecture,localization -Impact -TimeoutSeconds 600 -KeepGoing` 退出码 1，`5/10664`，`failed=['card_power']`、`unrun=[]`、`passed=23`、指纹前后一致 —— 红集**恰好**等于本文件第 29 行登记的 5 条 `witch_*`；`event_flow／events／content／architecture／localization／persistence` 六类全 PASS（协调者重跑 3044 断言）。
- **界面**：`tools/check.ps1 -UIOnly -UISuite events,localization -TimeoutSeconds 900` 退出码 0、`UI PASS: 231 assertions`。**口径**：该命令默认 300 秒会因负载在 `events` 窗口套件中途被中止（`20260916T083346894-13484`，无 UI RESULT），记录与复跑一律用 `-TimeoutSeconds 900`。
- **内容包**：`tools/check-content.ps1` 退出码 0、`CONTENT PASS: 12 file(s)`。
- **本地化**：`legacy-en_US.json` 删 25 条本片已不存在的旧源文（阶段专用文案）、增 29 条新校验文案英文条目，条目 4943→4947；`removed still present: []`、`required missing: []`；`python tools/localization_inventory.py`：`needs_review 5690`、`connected_static_call 33`，`en_US 52/52`、`ja_JP 0/52`（ja 缺译非本片引入、未动）。具名 check `locale_legacy_catalog_matches_current_sources` 断言旧源文不存在且所需源文译文非空（安全回退不算通过）。
- **具名 check**：§10 场景 05／08／09／13／15–18 落地（`event_condition_kinds_share_one_declaration`、`event_single_node_declarations`、`event_node_empty_policy_kept`、`event_probe_and_projection_readonly`、`event_stacked_conditions`）；依赖规范三条 check 落地（`event_condition_kinds_share_one_declaration`、`event_single_evaluation_entry`、`event_pipeline_writes_only_declared_keys` 内容半；链半属 B4）。场景 05 经裁定为"一条 check 覆盖三处消费者即可"（判据是三处一致，不强制分文件）。

**一次"红项归因"记录（值得留档）**：B2b 首轮报告"`conditions` + `mode:"hidden"` 可能不丢弃选项"，实现者用最小复现（两组夹具 × 戴锁／不戴锁）分类为**断言写法错**而非产品缺口——原断言把 `options.is_empty()` 与 `candidates().is_empty()` 用 `and` 连接，而 `candidates()` 含非事件候选；且第二条夹具的期望默认 `no_chastity_lock` 在未戴锁时本不该命中。据此按契约字面判据重写断言，**未改产品代码**。这与 E0 比较器那次同类：先分类"判据坏了／行为漂移了"，再动手。

遗留（另行排期，不属本批）：B2c＝把 `conditions`／`unavailable`／叠加语义补进四份作者文档；B3＝trace 具名全覆盖（含 `validate_failed`／`node_empty`）与 debug 开关；B4＝事件链与环守卫；`card_power` 5 条与 `normal_play` 1 条为既有登记项。未跑：`-Suite all`、打包与发布门禁。**整片（B3／B4）未完成前不得打包发版**；未推送、未打包。

## 2026-09-16 B2c 作者文档补 conditions 与叠加语义

RuleChangePackage（文档与文档 check，零产品代码）：`spire-godot/content/README.md` §3 选项表新增 `conditions`／`unavailable` 两行（各写明与 `availability`／`hide_when_unavailable` 互斥），状态条件段重写为"两类拼写＋规范拼写规格（1—8 条、kind 只能取声明表种类）＋两种模式语义（`optional` 显示但禁用／`hidden` 不生成）＋完整模式优先级＋叠加求值与 `reason` 拼接规则（**声明顺序决定换行顺序**）"；`docs/content-templates.md`、`docs/content-generation.md`、`docs/content-extension.md` 同步；删除 B1b 遗留的"B2 起生效"标注。`README.md:219` 的"跨事件跳转／事件链 **B4 起生效**"据实保留（B4 未落地，文档不得提前宣称可用）。`tests/content_cases.gd` 的 `event_author_manual_lists_current_fields` 扩展词表（`conditions`／`unavailable`／`mode`／`optional`／`hidden`／`disable`／`hide`／`kind`／`reason`／`type`／`no_chastity_lock`／`has_relic`）并加反向断言（不得出现"B2 起生效／待 B2／尚不可用"，必须出现两类拼写、两类模式与"声明顺序"）；只加断言、未放宽任何既有断言。

验证（提交 `1f450d7`；域：作者文档 + 事件分类）：
- E0 等价：退出码 0、`PASS (94 scenarios, 0 failures)`、`EVENTDIGEST 1f11bea5…`（逐字相同）。
- 规则门：`content`／`architecture` 全 PASS；`-Impact` 变体（`20260916T084820647-6816`）退出码 1、`5/9455`、`failed=['card_power']`、`unrun=[]` —— 红集恰好等于本文件第 29 行既有登记项。
- 界面：`-UIOnly -UISuite events,localization -TimeoutSeconds 900` PASS 231。内容包：`CONTENT PASS: 12 file(s)`。
- 残留扫描：`B2 起生效`／`待 B2`／`B2 前`／`尚不可用` 零命中（唯一合法命中是 `README.md:219` 的 B4 标注）。协调者已独立复核 E0、两类套件（1019 断言）、UI 与内容门。
- 未跑：`-Suite all`、打包与发布门禁。**整片（B3／B4）未完成前不得打包发版**；未推送、未打包。

## 2026-09-16 B3 事件 trace 与具名 gate（核心 + B3b 收口，**本批未完成**）

RuleChangePackage（规则内重构，行为逐字节不变）：`core/room_events.gd` 新增 `probe_result`（唯一实现，`probe()` 保留原签名＝返回 `.reason`）把探测拆成可分别命名的阶段——`effects` 失败→`probe_failed`、`next_node`→取节点入口 gate、`validate` 失败→**`validate_failed`**、暂存未归还→**`held_pending`**；新增 `enter_node_result`（唯一实现）——空节点→**`node_empty`**、节点不存在→**`stage_missing`**，**既有 issue 文案一字未改**；`feasibility_gate` 改从 `probe_result` 取 gate。新增 **debug-only trace**：开关与数组挂在游戏对象的调试字段（`set_meta`／`get_meta`，**不进 `state`／不进存档／不进 View**，`core/game.gd` 未改），`trace_entry` 记录 `event／node／source_choice／option_id／decision／gate／kind／mode／index／reason／purpose`。修复实现者自查出的缺陷：`start` 原先用属性式 `g.get("event_trace_enabled")` 清空、而访问器用元数据，**两套存储**导致开关打开时不清空、trace 跨事件累积陈旧行（且 `g.event_trace=[]` 真执行会报脚本错误）；改为新增 `clear_trace(g)`，读／写／清三处统一到同一存储与接口。

验证（提交 `e78fc72`、`367477c`；域：事件分类 + 持久化）：
- **E0 两遍（协调者亲自复核，含引擎错误日志判定）**：关闭＝退出码 0、`PASS (94 scenarios, 0 failures)`、摘要 `1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da`；开启（冻结 oracle 的副本 + 一行开关，冻结物未改）＝同样退出码 0、同一摘要；两遍日志中 `SCRIPT ERROR|ERROR:|Invalid access` **命中 0 行**（日志 `build/b3-verify/off.log`／`on.log`）。**口径补强**：oracle 显式 `quit(0)`，退出码不反映脚本错误，因此"退出码 0 + 摘要相同"必须与错误日志核对一起用。
- **release 不产出证据链**：①全仓 `rg` 显示只有测试与构建副本调用 `set_meta("event_trace_enabled"…)`，生产路径（`core/`／`data/`／`ui/`）无设置点、默认 false；②关闭与开启两遍摘要逐字相同；③`get_view`／`export_snapshot` 的 JSON 不含 `event_trace`／`event_trace_enabled`（由场景 10 的 check 断言）。
- 规则门：`event_flow,events,content,architecture,persistence` 全 PASS（协调者重跑 2919 断言）；`-Impact` 展开集 `failed=[card_power, installed_tools]`、无本片新红（`unrun` 为预算内未跑完，非失败）。界面：`-UIOnly -UISuite events,localization -TimeoutSeconds 900` 状态 `passed`（`summary.json` 复核）。内容包：`CONTENT PASS: 12 file(s)`。
- 落地具名 check：场景 04 `event_hidden_relic_option_traced`（event_flow_cases）、场景 10 `event_trace_never_reaches_state_or_save`（persistence_cases）。
- **未落地（本批未完成的原因）**：场景 03（gate 名全覆盖，须含 `validate_failed`／`node_empty`／`held_pending`／`stage_missing`）与场景 19（叠加逐条 trace＋关开关后为空＋上一事件行不残留）两者的断言在 D3 修复后**仍红**，实现者按纪律**移除红断言并未弱化、未提交**，怀疑与 `arrival`／`candidate` 两次评估间 trace 行的归属有关但未证实。**待定位并分类**（产品缺陷 vs 夹具期望）。

**新登记的既有红项**：`installed_tools` —— `tests/installed_tools_cases.gd:43` `SCRIPT ERROR: Invalid access to property or key 'detail'`，`FAIL: 0/9`；`t.find_action(g,"card",…)` 返回兜底 `{valid:false,payload:{}}`，即该 `strain` 卡候选未生成。**分类证据**：实现者在 `4d22a00`（B1 之前，临时签出 `core/`＋`content/`＋`tests/` 后还原、`git status` 干净）跑同一套件，**同样报错、同样 0/9** → 非本片回归；协调者在 HEAD 重跑复现同一错误。根因方向＝该夹具前置条件与当前卡牌/工具接口漂移，**未定类、未修**。门禁红集口径自此为 ⊆ {`card_power` 5 条, `installed_tools` 1 条}。

未跑：`-Suite all`、打包与发布门禁。**整片（B3 收口、B4）未完成前不得打包发版**；未推送、未打包。

## 2026-09-16 B3 续批：trace 行语义落地与两处实现缺陷修复（**B3 仍未完成**）

RuleChangePackage（规则内重构，行为逐字节不变）：
- **D1a**：`evaluate_option` 现在分别传 `source_choice`＝作者选项 id、`option_id`＝冻结实例 id（无冻结实例时回落作者 id），`trace_entry` 从字段取 `source_choice`——此前两者被写成同一个值，违反契约 §4.5（A25 第 3 条）。仅影响 trace 行。
- **`selector_empty` 具名化**：`enter_node` 在选择器展开为空时原先直接 `continue`，该选项**既不记 gate 也不产 trace 行**（违反 §4.2 的具名 gate 要求，也是场景 03 缺行的原因）。改为仍调用一次求值入口，使该选项得到 `selector_empty` gate 与一行 trace；**行为不变**（选项本就不进入冻结选项，E0 摘要即是其证明）。
- 场景 19 具名 check 落地（`event_flow_cases.gd:event_stacked_condition_trace_and_release`）：按 `purpose` 过滤、逐条比对 `source_choice`／`option_id`／`index`／`mode`／`gate`／`reason`、**跨 purpose 全等**（仅 `purpose` 可变）、`start` 后无残留、关闭时 0 行、存档与 View 不含 trace。

**一次误报的自我更正（留档）**：上一轮"套件上下文缺少 `purpose=="candidate" and index==0` 的行"**经原始数据否定**——实现者在取数前**多调用了一次 `candidates()`**（行数 4→6），且按总行数写死断言，违反 A25 第 2 条"禁止按 trace 总行数断言"。原始行数据显示两次求值的状态条件行**只差 `purpose`**、完全合规。这是本轮第三次"红项先定类"救回的时间（前两次：E0 比较器、`hidden` 模式立证）。

验证（提交 `4e9a1a2`；域：事件分类 + 持久化）：
- **E0 两遍（协调者亲自复核，含引擎错误日志）**：关闭与开启各退出码 0、`PASS (94 scenarios, 0 failures)`、摘要 `1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da` 逐字相同；两遍日志 `SCRIPT ERROR|ERROR:|Invalid access` **命中 0 行**（`build/b3-verify2/off.log`／`on.log`）。
- 规则门：`event_flow,events,content,architecture,persistence` 全 PASS（协调者重跑 2926 断言）；`-Impact` 红集 = {`card_power`, `installed_tools`}（均为既有登记项）。界面：`-UIOnly -UISuite events,localization -TimeoutSeconds 900` PASS 231。内容包：`CONTENT PASS: 12 file(s)`。
- **未完成**：场景 03（gate 名全覆盖，须含 `validate_failed`／`node_empty`／`held_pending`／`stage_missing` 与选择器两类 id 分开断言）仍为占位、未落地；B4 未做。**整片未完成前不得打包发版**；未推送、未打包。

## 2026-09-16 B3 完成：trace 与具名 gate 全覆盖（场景 03 落地）

RuleChangePackage（规则内重构，行为逐字节不变）：`tests/event_cases.gd` 新增 `event_gate_names_are_total`（+162/−18），按 `docs/event-pipeline-unification.md` §4.5（A25）与 §10 场景 03 的口径落地——①12 份内容逐事件：每个作者选项至少一条 arrival 行、未展开项恰一行、每行 `decision` ∈ {generated,dropped,hidden,disabled}、dropped/hidden 行必须命中 §4.2 的具名 gate 清单（12 名）；②状态条件行在 arrival↔candidate 双向**缺行/多行即失败**，逐字段（event／source_choice／option_id／decision／gate／kind／mode／index／reason）相等，单节点另断 `node` 相等，不进冻结集合的行必须确为 dropped/hidden；③**选择器两类 id 分开**：`source_choice` 恒不含 `__`，含 `__` 的行必须 `<source_choice>__…` 且逐实例恰一行、实例集合 == `room_event.options[*].id` == 候选 `payload.choice`；④**`selector_empty`**（`enchanters_empty_studio` 的 `temper`，seed 42）恰一行 `gate=="selector_empty"`＋`dropped`，且不进冻结选项与候选；⑤开/关两遍的 frozen options／candidates／rng／view 逐字相等、关闭时 0 行；⑥**禁止按 trace 总行数断言**，重复只按单次求值判定。五个具名 gate 全部用真实夹具（无桩）：`stage_missing`（已进事件上 `enter_node_result(g,"missing")`）、`node_empty`（关死多节点夹具 `finale` 的唯一选项后 `enter_node_result`）、`probe_failed`（真实魔力不足探针）、`validate_failed`（已进事件上把 `room_event.values` 弄坏后 `probe_result`）、`held_pending`（真装 `shaft_ring_low` → `hold_special` → `probe_result(...,true)`）。

**卡点定类（第四次"先分类"）**：前一轮的 `probe_result` 报 `Invalid access to property or key 'refs'`**不是** `validate_failed` 通路的问题——`probe_result` 首行即 `apply_effects(..., g.state.room_event.refs, …)`，而 `refs` 只有 `start` 之后才存在；同一条读取在 B3 之前（`f95e96f~1:core/room_events.gd:801`）逐字相同，产品全部调用点都在事件内。**结论＝夹具约束**（探针必须在已进入的事件上跑），非产品缺陷、非契约缺口；未改产品代码、未改契约、未放宽断言。

验证（提交 `79bd622`，父 `5c5ffda`；域：事件分类）：
- **E0 两遍（协调者亲自复核，含引擎错误日志）**：关闭与开启各退出码 0、`PASS (94 scenarios, 0 failures)`、摘要 `1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da` 逐字相同；两遍日志 `SCRIPT ERROR|ERROR:|Invalid access` **命中 0 行**（`build/b3-verify3/off.log`／`on.log`）。
- 规则门：`event_flow,events,content,architecture,persistence` 全 PASS（协调者重跑 3362 断言）。界面：`-UIOnly -UISuite events,localization -TimeoutSeconds 900` PASS 231。内容包：`CONTENT PASS: 12 file(s)`。
- **红集口径扩展**：`-Impact` 展开集的红集为 {`card_power`（5 条）, `installed_tools`（1 条）, `tower_progression`（10 条规则 + 1 条界面）}，三者均为本文件已登记的既有项（`tower_progression` 见本文件第 31 行；在新会话把它 `git stash` 掉后同样 10 条红，故非本片回归）。**门禁红集口径自此为 ⊆ 上述三项**。
- **操作口径**：`-Impact` 展开集里 `installed_tools` 的 `SCRIPT ERROR` 会触发 runner 的 runtime_error 分支而使其余分类 `unrun`——"红集恰好"的判定必须以**补充枚举**（跑完 `unrun` 分类）为准，报告里必须列出 `unrun` 清单，不得把未跑当通过。

**两处 trace 形状待裁（不影响玩法、不影响上述判据；已交规划者裁定后并入 B4 或 B3c）**：①`stage_missing` 无 trace 行（`enter_node_result` 只在 `node_empty` 分支写行，`room_events.gd:376` vs `:361`），而 A25 §4 把 `stage_missing` 列为节点入口失败行——补行还是改契约措辞待裁；②candidate 阶段探测后继节点时 `enter_node_result` 以 `purpose="arrival"`、`node=当前 stage` 写入且每个冻结实例各写一份（`succubus_three_games` 10 份相同行），A25 的过滤元组无法与真实 arrival 行区分——需给该情形独立的 `purpose` 取值或修订过滤口径。

B4（跨事件 `next` 与 `chain`）未做；`README.md:219` 的"B4 起生效"标注据实保留。**整片完成前不得打包发版**；未推送、未打包。

## 2026-09-16 B4 完成：事件链（跨事件 next、chain 键、环守卫）——本片最后一批代码

RuleChangePackage（行为在现有内容上逐字节不变，链能力为新）：`next` 接受对象形态 `{"event","node"}`，静态校验要求事件已登记、节点存在于该定义、拒绝自引用，同定义内仍只向后；新增 `next_target`（唯一解析入口）／`enter_target`／`chain_cleanup`／`_enter_chain`，跳转时重写 `room_event.id`／`stage`、`values`／`held` 延续、`cleanup_effects` 按 key 并集、`event_seen` 加入目标、`flow` 按新定义重算；`chain` **只在真跳转时**写入且与 `event_seen.append` 同一事务；候选阶段环守卫给 `disabled`＋gate `chain_loop`；A30 `stage_missing` 补节点入口失败行；A31 后继节点探测用独立 `purpose="next_probe"` 且节点级行按 `(event,purpose,node,gate)` 去重；`snapshot` 增量接受 `chain`（数组、元素已登记、不重复、非空），既有字符串分支与检查逐条保留。`_next_ends_event` 让"带奖励必须结束事件"与"起始节点可离开"不再对对象形态做 Dictionary↔String 比较。

验证（提交 `8633bd9`，父 `73e2f21`，6 files／+309−16；域：events + persistence）：
- **E0 两遍（协调者亲自复核，含引擎错误日志）**：关闭与开启各退出码 0、`PASS (94 scenarios, 0 failures)`、摘要 `1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da` 逐字相同；两遍日志 `SCRIPT ERROR|ERROR:|Invalid access` **命中 0 行**（`build/b4-verify/off.log`／`on.log`）。12 份内容与冻结 oracle 夹具均不含跨事件 `next`，对象形态只在新夹具里用。
- 规则门：`event_flow,events,content,architecture,persistence` 全 PASS（协调者重跑 3420 断言）。界面：`-UIOnly -UISuite events,localization -TimeoutSeconds 900` PASS 231。内容包：`CONTENT PASS: 12 file(s)`。
- **A29 补充枚举**：`-Impact` 展开集因 `installed_tools` 的 runtime error 使 18 分类 `unrun`；补跑后 17 PASS、仅 `tower_progression` 红（10 条）→ **补齐后红集恰好＝A28 三元集**，`unrun=[]`、指纹前后一致。
- 具名 check：`event_chain_jumps_to_another_event_node`（id／stage 切换、`chain==["chain_source_fixture"]`、`values`／`held` 延续、`flow` 镜像、`event_seen` 恰一次、cleanup 并集去重、离开时两个 cleanup 各执行一次且两件暂存装备原样装回）、`event_chain_loop_refused`（候选 invalid＋决策 `disabled`＋`gates==[chain_loop/kind chain]`、求值与提交均不改 state／rng／存档）、`event_chain_trace_rows`（A30／A31：`stage_missing` 行 `node`＝目标、`option_id` 空、重复进入仍 1 行；`node_empty` 由两个冻结选项探测仍恰 1 行 `next_probe`）、`event_chain_references_fail_closed`（自引用／未登记／节点不存在／缺 node／多余键／非字符串 node 逐例整包拒绝且注册表不变）、`event_pipeline_writes_only_declared_keys`（抵达实例无 `chain`；真跳转新增键恰为 `chain`；往返保持；`[]`／字符串／未登记／重复／非字符串元素原子拒绝；12 份内容仍无 `chain`）。

**B4 报出的三处缺口（待裁／待收尾，均不影响上述判据）**：①跳转**不重抽遗物**——`room_event.relic` 保持来源事件抽到的值，若目标事件含遗物奖励选项，`execute` 会发放**来源事件的遗物**（§3.3 未规定，未改随机消耗、未立证）；②`hold_special` 的 key 唯一性只在单定义内静态校验，**跨定义重复 key 无静态拒绝**（运行期"同一保管位置不能重复使用"会挡住，未立证）；③新增玩家可见 reason `CHAIN_LOOP_REASON` **缺英／日条目**，按安全回退显示中文。

**本片代码批次（B1／B1b／B2／B2b／B2c／B3／B3b／B4）至此全部落地**；仍待：上述三处缺口裁定与收尾、跨事件 `next` 与链语义补进四份作者文档（含删除 `README.md:219` 的"B4 起生效"标注）、validator 验收。**整片完成前不得打包发版**；未推送、未打包。

## 2026-09-16 B5 完成：链遗物重抽、跨定义暂存 key、本地化与作者文档收尾（本片最后一批）

RuleChangePackage：①**A32 跳转重抽遗物**——抽出唯一 `offer_relic(g,spec)`，`start` 与 `_enter_chain` 共用；跳转时按**目标定义**重算 `room_event.relic`（目标含遗物奖励且池非空→抽一次；目标不含或池空→**置空**），不再保留来源事件的遗物。②**A33 跨定义暂存 key**——`_event_references` 末尾沿跳转图逐路径校验 `hold_special` key（`_chain_hold_key_issue`／`_hold_keys`／`_jump_targets`），跨定义重复或 cleanup 引用非本定义 key 即**整包拒绝**；运行期守卫文案未改。③**A34 本地化**——`legacy-en_US.json` 增 `legacy.hbe6fbb665a810824ce3c074b`（`CHAIN_LOOP_REASON`），条目 4947→**4948**，`needs_review` 5701→5702，`en_US 52/52`、`ja_JP 0/52`，旧源文零残留、译文非空。④**文档收尾**——四份作者文档补跨事件 `next` 对象形态与链语义（`chain`／并集／环／不能再回头），**删除 `README.md:219` 的"B4 起生效，当前不接受"**并改为现行说明；`event_author_manual_lists_current_fields` 纳入链关键词并加反向断言（只加未放宽）。

验证（提交 `556a231`，父 `8808be5`；域：events／persistence／本地化／文档）：
- **E0 两遍（协调者亲自复核，含引擎错误日志）**：关闭与开启各退出码 0、`PASS (94 scenarios, 0 failures)`、摘要 `1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da` 逐字相同；两遍日志 `SCRIPT ERROR|ERROR:|Invalid access` **命中 0 行**（`build/b5-verify2/off.log`／`on.log`）。12 份内容仍不含链。
- 规则门（协调者重跑）：`event_flow,events,content,architecture,localization,persistence` 全 PASS（3586 断言）。界面：`-UIOnly -UISuite events,localization -TimeoutSeconds 900` PASS 231。内容包：`CONTENT PASS: 12 file(s)`。
- 具名 check：A32 三类（`event_chain_relic_drawn_from_target`／`..._cleared_without_target_offer`／`..._cleared_when_pool_empty`，各含随机域对拍）＋A33 `event_chain_hold_keys_fail_closed`（重复 key 与 cleanup 引用外部 key 双反例整包拒绝、注册表不变）＋A34 `locale_legacy_catalog_matches_current_sources`（`REQUIRED_SOURCES` 纳入新常量）＋文档反向断言。
- **判据敏感性**：临时停用 `_enter_chain` 的重算后 A32 五条断言变红（四条 class1＋一条 class2）——证明该 check 真的承载判据，不是空转。

**新登记的既有红项**：`hand_assist` —— `tests/hand_assist_cases.gd:38` `SCRIPT ERROR: Invalid access to property or key 'detail'`，`FAIL: 0/125`（与 `installed_tools` 同类：`find_action` 返回兜底 `{valid:false,payload:{}}`）。**分类证据**：把本批改动 `git stash` 后在 `8808be5` 上重跑同一套件**同样红** → 非本片回归；协调者在 HEAD 复现同一错误。**门禁红集口径自此扩为四项** ⊆ {`card_power` 5 条, `installed_tools` 1 条, `tower_progression` 10 条规则＋1 条界面, `hand_assist` 1 条}。根因方向＝夹具前置条件与当前动作接口漂移，未定类未修、另行排期。

**两条操作提示（留给后续与重建目录时用）**：①`python tools/build_english_catalog.py` 在本机**无法运行**（`build/translation-lite` 与 `english-translation-cache-v4.json` 不存在），新条目按契约 §17"离线模型不可用则人工补齐"直接写入目录；**日后重建英文目录时需把该条目补进生成器的 `MANUAL`／缓存，否则会被重建覆盖**。②新增作者层校验文案（本批 A33 的"事件链上重复使用了暂存 key："与 B4 同类新增）未补译，仅体现为盘点 `needs_review` +1，安全回退显示中文（作者层、非玩家主线）。③跨定义环（A→B→A）**静态不拒绝**（仅拒自引用，契约如此）：静态遍历以"路径上重复定义即停"保证终止，运行期由 `chain_loop` 守卫拒绝并由场景 12 立证。

**本片代码与文档批次（B1–B5 全部）至此收口**，下一步＝整片 validator 验收（契约 §11，20 条具名场景＋全部判据）。**B5 已收口，验收可开始；验收通过前不得打包发版。**未推送、未打包。


## 2026-09-16 事件管线统一（B1–B5）整片验收

域：`spire-godot` 事件管线统一切片——定义形态归一（`nodes`／`start_node`）、单求值入口（`evaluate_option`／`enter_node`）、资格从四条并行通道收敛为一份 `CONDITIONS` 声明派生四处、选项生命周期具名 gate、debug-only trace、跨事件 `next` 与 `chain`。契约 `docs/event-pipeline-unification.md` §11／§12／§10／§0.1／§4.5／§3.3／§3.4／§9；依赖规范 `docs/event-pipeline-dependency-spec.md` §4.2。

验收者：独立会话（未参与本片实现），未改产品代码／既有测试／内容包／契约与依赖规范／冻结 oracle 与基线；只新增忽略目录内的验证脚本与记录。对象提交 `3e64cff`（父 `84f8ea3`），验收期间工作区 `git status --porcelain` 前后均为空。

- 验收脚本（`spire-godot/build/validator-20260916/`，gitignored，可复跑）：
  `run-validation.ps1`（编排全部判据并产出 `run-20260916-02/report.json`／`report.txt`）；
  `scenario_probe.gd`（§10 01–20 具名 check 的逐条直调，附依赖规范 §4.2 五条与本地化口径①②，逐条打印断言数与引擎错误数）；
  `scenario14_roundtrip.gd`（场景 14 的 validator 侧覆盖，见下）；`human_path_ui.gd`（真实窗口与真实 viewport 输入驱动 §11 第 6 条缺口）。
  复跑：`powershell -NoProfile -ExecutionPolicy Bypass -File build/validator-20260916/run-validation.ps1 -RunId <id>`。
- **E0 两遍（关闭／开启 trace）**：均退出码 0、`EVENT RESULT: PASS (94 scenarios, 0 failures)`、`EVENTDIGEST 1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da` **逐字相同且等于冻结基线**；两遍日志 `SCRIPT ERROR|ERROR:|Invalid access` **命中 0 行**（`e0-off.log`／`e0-on.log`）。
- 内容门：`& tools/check-content.ps1` 退出码 0、`CONTENT PASS: 12 file(s); validated without changing game or saves`（日志 `check-content-engine.log`）。
- **规则门** `& tools/check.ps1 -Suite event_flow,events,content,architecture,localization,persistence -Impact -KeepGoing -TimeoutSeconds 900`：退出码 1（既有红项），`-Impact` 展开 37 个分类，`summary.json` 各轮 `before==after`、无 `source_changed`。**红集＝{`card_power` 5 条, `installed_tools` 1 条, `tower_progression` 10 条}**，逐条计数与登记一致，**未超出 A35 四项集**。`installed_tools` 的 `SCRIPT ERROR` 触发 runner 的 `runtime_error` 分支，**使其后 18 个分类 `unrun`**（清单：environment_height／exploration／shoulder／slip_motion／torso_binding／casting／special_equipment／services／action_copy／persistence／rewards／events／links／prison／pressure／enemies／trader／tower_progression）；按 A29 **逐分类单进程补跑**，17 个 PASS、`tower_progression` FAIL（10 条），**补跑后 `unrun` 为空**，`unrun` 未记作通过。
- **界面门** `& tools/check.ps1 -UIOnly -UISuite events,localization -TimeoutSeconds 900`（A17 时限）：退出码 0、`SUITE RESULT: localization PASS`／`events PASS`、`UI PASS: 231 assertions`、`summary=passed`。
- **§10 20 条具名场景：20/20 `passed`**（`scenario-probe.log`，同一进程逐条直调，断言数见括号）：01 event_definition_single_form(185)／02 event_option_policies_match_current_behaviour(134)／03 event_gate_names_are_total(436)／04 event_hidden_relic_option_traced(3)／05 event_condition_kinds_share_one_declaration(9)／06 event_stage_available_condition_validates(8)／07 event_definition_form_rejects_legacy_shape(14)／08 event_single_node_declarations(8)／09 event_node_empty_policy_kept(8)／10 event_trace_never_reaches_state_or_save(6)／11 event_chain_jumps_to_another_event_node(19)／12 event_chain_loop_refused(8)／13 event_probe_and_projection_readonly(3)／14 event_frozen_options_roundtrip(84，**validator 侧覆盖**，见下)／15–18 由合并 check `event_stacked_conditions`(14) 承载／19 event_stacked_condition_trace_and_release(7)／20 event_stacked_conditions_keep_current_content(98)。0 引擎错误。
- **场景 14 无落地的具名 check**（磁盘复核：`rg -n event_frozen_options_roundtrip spire-godot/tests/` 无命中；契约 §10 的 01–20 归属清单也未列 14）。validator 按 §11"把验收程序变成可执行脚本"在忽略目录补 `scenario14_roundtrip.gd`：12 份内容的冻结选项与 `room_event` 经真实 `SaveStore.pack/unpack` 与正式入口往返**逐字节相等**（8 单节点＋4 多节点），`next` 只在 staged 布局出现，六类畸形 `next`（缺键／非串或对象／未知节点／未登记事件／自引用／目标节点不存在）**整包原子拒绝**且文案＝"无法继续这份存档：多阶段事件冻结选项损坏。"（84 断言 PASS）。**该缺口属契约落地缺口，非产品缺陷**；正式具名 check 是否补落由规划者裁定。
- 另两条与字面合同的偏差（均不影响行为判据）：①场景 19 的**存档侧同断言**按 §10 应落 `tests/persistence_cases.gd`，实际落在 `tests/event_flow_cases.gd:800`（同一断言内含"存档与 View 不含 trace"半；B3 执行记录已按此登记，属落点与文面不一致）；②§11 第 6 条"付费离开"在所有内容包中已无对应选项（`rg 支付费用 content/packs/` 零命中），该人路径项按现行内容不存在，已改以正式离开路径与人路径 H2／H6 立证。
- **依赖规范 §4.2 五条 check：5/5 `passed`**（直调断言数）：event_dependency_edges_pinned(9)／event_definition_accessors_only(140)／event_condition_kinds_share_one_declaration(9)／event_single_evaluation_entry(26)／event_pipeline_writes_only_declared_keys(85)。
- **本地化口径①②③**：①＋②由 `locale_legacy_catalog_matches_current_sources` 直调 PASS(62 断言：`REMOVED_SOURCES` 25 条旧源文零残留、`REQUIRED_SOURCES` 35 条译文非空)；③盘点 `python tools/localization_inventory.py`＝`needs_review 5702`、`connected_static_call 33`、`en_US 52/52（缺 0）`、`ja_JP 0/52`，目录条目 **4948**（与 B5 记录 4947→4948 一致）。`python tools/build_english_catalog.py` **未运行**：本机缺 `build/translation-lite` 与 `english-translation-cache-v4.json`（A36① 已登记），目录按"离线不可用→人工补齐"维护。
- **§11 第 6 条人路径（真实窗口、真实 viewport 输入）**：既有 `-UISuite events` 覆盖首次进入候选、硬闯战斗→整备、选牌／道具奖励、多阶段逐阶段点击、离开；**其未覆盖的两项由 validator 驱动脚本补**（`human-path.log`，退出码 0、18 断言 PASS）：H2 持有 `softened_buckle` 后【硬闯】缺席且【离开】出现并可由真实点击走完（E6 政策维持现状）；H6 存档并在**正式入口** `HomeContinue` 继续后，阶段／冻结选项／报告与存档点逐字段一致、重按【祈福】报告文本逐字相同。§11 第 7 条叠加条件证明由场景 15–19 承载。
- **四态计数（本片 20 场景）**：`passed 20`／`failed 0`／`unverified 0`／`skipped 0`。步骤层：E0 `passed`、内容门 `passed`、规则门 `passed`（红集在册、`unrun` 清零）、界面门 `passed`、依赖五条 `passed`、本地化口径①②③ `passed`、人路径 `passed`。
- 补充核对（非判据，仅确认既有红项仍如登记）：`-Suite hand_assist` 退出码 1、`0/125`、`SCRIPT ERROR ...'detail'`（A35 一致）；`-UIOnly -UISuite tower_progression` 退出码 1、54 断言、1 条 `SUMMIT UI run loss offers correct restart instead of equipment practice`（登记一致）。
- 未验证／未跑：`-Suite all` 与 `-UISuite all` 全量回归（契约未要求）；Android 真机；`build_english_catalog.py`（环境不可用，见上）；§10 场景 14 的**正式具名 check**（validator 脚本已覆盖行为，落地归属待裁定）。人路径的"关闭 debug 开关：`g.event_trace` 为空"在规则侧场景 19／10 有断言，未另做界面侧重复操作（同一切面，无新增信息）。
- 结论：**本片通过验收**（20/20 场景、五条依赖 check、口径①②③、E0 两遍逐字相同且 0 错误行、红集 ⊆ A35 四项集且补跑后 `unrun` 为空）。未打包、未发版、未推送。归因纪律：本轮无新红项，未修改产品代码、未改动任何既有断言。

## 2026-09-16 B6 完成：场景 14 的具名 check 落进仓库（验收可复现性收口）

RuleChangePackage（仅测试，零产品代码）：`spire-godot/tests/persistence_cases.gd` 新增 `event_frozen_options_roundtrip`（定义 153 行、由 `run()` 在 255 行调用，本次 +75 行），把原先只由**忽略目录里验证者私有脚本**覆盖的场景 14 落成仓库内正式 check（域＝存档）——①12 份内容（8 单节点＋4 多节点）的冻结选项与 `room_event` 经真实 `SaveStore.pack/unpack` 与**正式入口** `restore_snapshot` 往返后 **`JSON.stringify` 逐字节相等**、`validate()==""`、单节点/多阶段计数 8/4；②`next` 只在 staged 布局（`frozen_form != "in_place"` 或作者选项带 `selector`）出现，并覆盖单节点 in_place 事件里由共享 staged 构建器冻结的选择器实例（`alchemist_tasting_stall`／`enchanters_empty_studio`）；③**六类畸形 `next`**（缺键／非字符串或非对象／未知节点／未登记事件／自引用／目标节点不存在）**整包原子拒绝**且文案＝`无法继续这份存档：多阶段事件冻结选项损坏。`，断言只改快照副本（A27）。

验证（提交 `3011cff`，父 `b9e5639`；域：persistence）：
- **E0 两遍（协调者亲自复核，含引擎错误日志）**：关闭与开启各退出码 0、`PASS (94 scenarios, 0 failures)`、摘要 `1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da` 逐字相同、两遍日志 `SCRIPT ERROR|ERROR:|Invalid access` **命中 0 行**（`build/b6-verify/off.log`／`on.log`）。冻结 oracle 与基线未改。
- 规则门（协调者重跑）：`persistence,event_flow,events,content,architecture` 全 PASS（3544 断言）。实现者侧另跑 `-Impact -KeepGoing` 六类：红集＝{`card_power` 5, `installed_tools` 1, `tower_progression` 10} 在 A35 四项集内；`installed_tools` 的 SCRIPT ERROR 使 18 分类 `unrun`，**逐分类补跑后 `unrun=0`**（17 PASS＋`tower_progression` FAIL 10）。界面门 `-UIOnly -UISuite events,localization -TimeoutSeconds 900` PASS 231；内容门 12 file(s)。
- **敏感性证明**（随后还原、`git status` 干净）：①改错期望文案 → **恰 6 条红**，六类畸形 `next` 逐条打印；②往返比对注入漂移（`options[0].label` 加后缀）→ **12 条红**并打印 `SAVE DIFF state.options[0].label …`。证明该 check 不是空转；先试的"把比对改成恒真"因按构造不可能变红而弃用（属正确的判据设计判断）。

**越界缺口（本批未修、未断言，交规划者裁定，A40）**：单节点 **in_place** 事件的冻结选项 `next` **完全不被存档校验覆盖**——`core/snapshot.gd:427` 的 `next` 校验挂在 `if event.get("flow",false)` 分支内，普通事件从不进入该分支。最小复现：把 in_place 事件的选择器实例（如 `alchemist_tasting_stall` 的 `dissolve__equipment_2`）的 `next` 改成未知节点／未登记事件／`42`，`restore_snapshot` **全部接受**（`build/b6-probe-20260916/probe_inplace_next.gd`）。**来源判读：既有缺口，非本片引入**——该分支结构先于 B1，且 B2 已论证"把校验从 flow 分支改为按选项键判定"会**放宽** flow 侧的既有拒绝（缺 `next` 的损坏多阶段选项今天被拒），故当时按契约保留分支不动。影响有限：运行期 `next_target` 解析对未知目标会经 `stage_missing` 等具名 gate 失败（本片 B3 的产物），不是崩溃路径。**裁定：不在本片内修**，登记为既有缺口另行排期；契约 §6.3 需按现状改写（staged 布局选项的逐键校验已落地，in_place 实例的 `next` 未校验）。

**本片至此代码、文档、验证三线收口**：B1–B6 全部完成，整片通过验收（`3e64cff`，登记 `1881568`），场景 14 的仓库内可复现入口补齐（`3011cff`）。**未打包、未发版、未推送**；打包与发布须用户明确指令。

## 2026-09-17 状态迁移管线收束（单写入者 + 单战斗结束判定）

RuleChangePackage（规则内重构，行为逐字节不变）：把散落的同类状态迁移收束到**单写入者**——`state.phase=` 26 点 → **1 点**、`state.room=` 10 点 → **1 点**（均在 `core/game.gd` 的 `_apply_transition` 内，由 `TRANSITIONS` 声明表驱动）；结束战斗从 13 个引用点／**8 个语义入口** → **1 处判定** `_battle_end_reason()` ＋**1 处执行** `_finish_battle(end_kind)`（调用位点保留，避免改变随机消耗与日志顺序）；**收押（`Guard.capture`）改道进同一路径**；`_restart_tower` 保留 3 个调用点。副作用（生成敌人、滚奖励、收押清理、牢房初始化）**留在原函数、原顺序**；**赋值在控制流中的位置不变**（明确拒绝"事务末统一执行"，因为事务中段会读 `state.phase`）；新增迁移日志 `_transition_log` 仅进程内（不进 `state`／存档／View）。新增闭环 check `tests/architecture_cases.gd:104 transition_write_sites_are_pinned`（四组模式扫描、注释与 `==` 不计入、**双向比对**：扫描集 ⊆ 表 ∧ 表内点都被扫到，表外或未命中打印 `文件:行:函数`），表内 **14 项**。

验证（提交 `9ee7a2f`（基线冻结）→ `d519402`（战斗结束）→ `a1744de`（阶段）→ `9d5a6af`（房间）→ `35f3411`（闭环与八条 check）；域：core + rewards/battle_saturation/guard/prison/tower/persistence/architecture）：
- **迁移 oracle（主证据）**：31 个场景覆盖八类战斗结束入口、`prepare_end` 三类、`floor_enter` 与同层换塔、练习初始化四种、牢房回合／巡视／逃脱／高安全、事件进入／空房／道具奖励、demo 结束与返塔；每场景冻结迁移前后 `phase/room/floor/version/rng/本次提交日志 sha256＋可读日志行/room_event 摘要`。**协调者独立重跑两次**：均退出码 0、`TRANSITION RESULT: PASS (31 scenarios, 0 failures)`、`TRANSITIONDIGEST 14eb8cf9c3c8b5d4347b2b9d118b8c504596e04d296d091884995bc359b522b6`（两次同值）、`SCRIPT ERROR|ERROR:|Invalid access` **0 行**。
- **受影响套件（协调者重跑）**：`battle_saturation,rewards,guard,prison,tower,persistence,architecture` 全 PASS、3678 断言、墙钟 148s。实现者侧完整门禁：规则门 2m08s（11 类 → `-Impact` 展开 44 类）红集 **{`card_power` 5, `installed_tools` 1} ⊆ 已知四类**，`installed_tools` 的脚本错误令 24 分类 `unrun`，**合并一次调用**补跑 3m29s → 23 PASS ＋ `tower_progression` FAIL 10 条（已登记），`unrun` 清零；界面门 1m22s `persistence,home,events` PASS 369 断言；闭环 check 25s。
- **闭环 check 敏感性证明**：临时在 `_finish_if_saturated` 插一处表外 `state.phase="battle"` → `FAIL: 1/462`，并打印 `["res://core/game.gd:803:_finish_if_saturated"]`；还原后 `architecture PASS: 466 assertions`、`git diff` 无残留。
- **未跑（按契约保持未验证）**：`-Suite all`／`-UISuite all` 全量、Android 真机、迁移日志的消费方（存档切片仍暂停）；未推送、未打包。

**判据身份（迁移 oracle，2026-09-16 冻结）**：冻结脚本 sha256 `b49b0164a6b962fc8eae4a843c36510e1fa12c846d9f0e565856fdc6ed092278`（摘要 `00089c29a675e1268473645ab6b7a363e70295abf575cc6cc2929db995ca3e11`）；当前脚本 sha256 `59d41c682b3b302c1d291eb64aea770994c89508ee3fcb637afc7902024c045c`（摘要 `14eb8cf9…`，两次运行同值）；**基线文件 sha256 `ba979d18c31952d6d69ef06ce2ed102f7503c518fa8c6125ea6482c92bb5b4c8` 自冻结起未改**。脚本冻结后**只在比对侧改两处**（新增 `_merged` 折叠相邻同名、`_compare_row` 仅对 `transition_log` 一列双侧折叠；其余列仍逐字段硬比对并保留 `NEWFIELD／MISSINGFIELD` 双向检查），**抓取路径未动**。证据：用当前脚本 `--write=` 到 `build/transition-oracle-20260916/identity-tmp.json`（sha256 `8cf606aa94fb9d946fc7317ad07e55bc9395684deb1f1767595bfa01964cc1bc`）与冻结基线对照——行名与逐行键集完全相同，**唯一差异列是 `transition_log`（31/31，冻结时该列按设计为空、现在为真实 kind）**；把两侧投影到参与比对的六列（`before/after/commit_logs/log_texts/digest/transition_log_declared`）规范化后**两侧同为 sha256 `5333ab642896dd5932faca53211aa7f77510b59065fc0c3a0a1d6374bd78d2fb`**，即扩展未放宽任何比对项；冻结脚本自身 `--baseline=` 自比（`selfcheck.log`）显示 31 条差异**全在 `transition_log`**、行为字段 0 条。**口径**：摘要是脚本版本指纹、**比对才是门禁**；重跑时摘要不一致不等于行为漂移，须按上表核对身份。

**与契约文面的四处不符（已转规划者入契约，均不需改产品代码）**：①收押经 `_apply_transition` **两次**写入（phase／room），不经 `_finish_battle`（后者拥有胜利／饱和奖励体；副作用仍在 `Guard.capture`、顺序不变）；②新增 `floor_enter` 与 `demo_end` 两个 kind（§3 表原只列 `room_enter`，§5 场景 03 用到 `floor_enter`）；③`_enemy_phase` 尾部判定在真实流程**不可达**（仅非法卡链状态可达），oracle 单列 `skip_validate` 场景冻结它，删除会改动闭环表行数与函数集合，故保留；④oracle 两处冻结声明与代码事实不符（`tower_restart`×2、重复同名写入），按"两侧同口径合并"比对，**基线 JSON 与行为字段零改动**。**折叠边界（协调者裁定）**：`transition_log` 列放过"同一 kind 相邻重复的额外一条"——该列是进程内诊断、不进 `state`／存档／View，且"恰一条 `battle_end_*`／均为 `prepare_end`"由闭环 check 与场景 01／02／04 承接，故接受；若将来该日志成为存档切片的数据源，此边界须重审。

## 2026-09-17 固定点存档：只在三处写盘

RuleChangePackage（行为对玩家不变，档案写入时机改变）：`core/game.gd` 的 `TRANSITIONS` 声明表新增 `checkpoint` 列——`floor_enter`→`floor`、三个 `battle_end_*`（含 `battle_end_captured`）→`battle_end`、`prepare_end`→`prepare_end`；新增 `CHECKPOINT_PRIORITY` 与 `_checkpoint_kind(log_start)`：`dispatch` 在 `var original=state` 前记 `log_start`，成功字典**末尾追加加性键 `checkpoint`**（`""`／`floor`／`battle_end`／`prepare_end`，由本次提交实际产生的迁移日志条目推导、同类去重、多类按 `battle_end ＞ prepare_end ＞ floor` 取一），失败字典保持原 `{ok,error}` 形状。`ui/main.gd` 的 `_submit` **仅在 `checkpoint` 非空时**调 `_save_progress()`；**删除恢复后立刻写盘**（`_quick_sl` 路径）；**保留**三条非进度写盘（地图线稿变更 `:1636`、新局替换不兼容档 `:1965`、手动"保存场景起点" `:2682`）。新增具名 check：`tests/persistence_cases.gd` 六个（正例 3／反例集合 1／`.bak` 与回退 1／失败与格式契约 1）＋`tests/persistence_ui_cases.gd` 真实 UI 写盘门控＋`tests/architecture_cases.gd` 的闭环 `save_checkpoint_kinds_are_pinned`（checkpoint 集合与声明表被标记的 kind 完全一致，多／少／改值／优先级名集不一致均红）。

验证（提交 `87a357e`，父 `9dd74fd`；域：persistence + architecture + UI home/persistence）：
- **迁移 oracle（第一道防线，协调者亲自复核）**：退出码 0、`TRANSITION RESULT: PASS (31 scenarios, 0 failures)`、`TRANSITIONDIGEST 14eb8cf9c3c8b5d4347b2b9d118b8c504596e04d296d091884995bc359b522b6`（与当前脚本指纹一致）、脚本 `59d41c68…`／基线 `ba979d18…` 未动、引擎错误 0 行。墙钟 5s。
- **规则门（协调者重跑窄集）**：`persistence,architecture` 全 PASS、1426 断言、28.9s。实现者完整门禁：`-Impact -KeepGoing` 72s 红集 = {`card_power` 5, `installed_tools` 1} ⊆ 已知项，`unrun` 16 类**合并一次调用**补跑 142s → 15 PASS ＋ `tower_progression` 10 条（已知），`unrun=0`、**无新红**。
- **界面门（协调者重跑）**：`-UIOnly -UISuite persistence,home -TimeoutSeconds 900` 退出码 0、`home PASS`／`persistence PASS`、**217 断言**、66s。实现者另跑 `-UISuite route` PASS 134（证明地图线稿真手势写盘保留）。
- **性能配对**（`docs/equipment-performance.md:45` 协议；`build/save-fixed-points-20260916/paired-results.json`，`problems: []`）：0/12/26 × battle/departure 六组合**场景内提交 `save` 段中位全为 0.0ms、`new_writes=0`**（旧侧中位 28.0–38.0ms）、两侧最终状态 `identical: true`；固定点单次写盘中位 **18.1ms（0 件）／36.8ms（26 件）**。
- **敏感性证明**：①给非固定点 `rest_start` 标 checkpoint → `architecture` 与 `persistence` 同时红（11/1427，打印 `rest_start->floor` 与固定点集合尺寸）；②摘掉 `prepare_end` 标记 → 12/1422 红。两次均还原、`git status` 干净，日志 `build/save-fixed-points-20260916/sensitivity-{1,2}-*.log`。
- **口径裁定（协调者）**：休息房的**最后一个休息回合**经 `_finish_preparation` 落到 `prepare_end` → **写盘**（这正是"完成休整后存档"）；休息房内的行动、奖励选择与非末回合**不写**。该语义在 kind 粒度上不可再细分，故反例集合的措辞以"非末回合／奖励不写"为准。
- **实现的取舍记录**：`tests/persistence_cases.gd` 增至 735 行（超出项目 500 行惯例；本仓无 Size 计数规则，且本片边界禁止新增文件，故落在既有文件内）。

**新登记的既有红项**：`home_persistence`（UI 套件，`tests/home_persistence_ui_cases.gd`）——3 条断言失败：`HOME new game creates and saves actual tower entry`／`HOME controls remain in logical 16:9 frame after resize`／`HOME restored service room remains interactive`，`UI FAIL: 45`。**分类证据**：把 `core/`＋`ui/`＋`tests/` 整体回退到**已推送的 `a673352`**（早于迁移收束与存档两片）后跑同一套件，**同样三条断言失败** → **非本片引入**；此前未登记是因为门禁一直用 `persistence,home` 两个独立套件，从未跑过 `home_persistence` 这个组合套件。**方法注**：只回退产品文件会因 HEAD 的测试引用新符号而编译失败，定类必须整体回退 `core/`＋`ui/`＋`tests/`。门禁红集口径自此为 ⊆ {`card_power` 5, `installed_tools` 1, `tower_progression` 10＋1, `hand_assist` 1, `home_persistence` 3}。

未跑：`-Suite all`／`-UISuite all` 全量、Android 真机、打包发布。
