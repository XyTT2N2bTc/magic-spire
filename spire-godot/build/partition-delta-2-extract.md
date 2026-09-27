# 规划者契约：present(dirty) 第二刀（header）

状态：可交协调者派实现者；**无新模块、无新允许边**，不标 `needs-human-review`。协调者已记录通宵计划审阅选①：按 `docs/spec/response-pipeline.md` 节键表 `header` 行给 `header.configure` 建键并早退；改 `ui/shell/header.gd`；局部 `present(["header"])` 不得叠按钮；不改 `_submit`；不新 UI 文件；不在 `main.gd` 复制第二套 header 键。「既有节键」＝规格已写字段集，不是代码里已有 `_presentation_key`。起步 HEAD `9cb5754`。域：`ui/main.gd::present` 加 `["header"]` 局部；键只在 `ui/shell/header.gd`。保留第一刀 `body_bar` 路由。不拆 `commit`、不接 `present_rejection`。不铺其余节。不新写 CSS。本刀不写 `docs/spec`。Godot／测试／审查／清洁／加固均未验证。

checkpoint(planner): map header onto existing present

## 已有入口（扩展 present，不建第二套刷新管线）

- `present`／`PRESENT_SECTIONS`／`_present_needs_full_render` 已落地。生产签名保持 `present(dirty: Array=["*"], snapshot: Dictionary={})`（元素 `String(dirty[0])` 对照枚举）；**不得**改回 `Array[String]`（Godot 拒收未类型化字面量）。仅 `["body_bar"]` 局部 → `layout.body_sidebar`；`["*"]`／缺项／`dirty.size()!=1`／未知／其它已声明名 → 全量 `render(当前 view)`，禁止再 `get_view`。局部固定序：`DragTargets.clear(self,false)` → `_hide_term` → View 同步 → 节 → `layout.end_frame()` → `keyboard_input.refresh_hints`（`call_deferred`）→ `_localize_controls`。局部不得 `begin_frame`，不得清空 `layout.used`。
- `_header()` 每次 instantiate `header.tscn` 再 `configure`，并顺手 `_relic_row()`。`header.configure` 无键、无早退；每次 `_place` 新按钮（`OpenTutorial`／`OpenStatus`／`OpenItems`／`OpenDeck`／`OpenMap` 或 `OpenPrisonTutorial`／`OpenMenu`）。就地再 `configure` 会叠按钮。Godot 对重名子节点会改成 `OpenTutorial2` 等，故叠按钮不得只靠 `find_child("OpenTutorial")` 件数＝1 判定。
- 节键表 `header` 行（键内容真源）：`run_header`(location/turn/order/last)、`security`、`wall`、`wall_position.distance`、`pressure.overloaded`、`carried_items`、`capacity`、`deck_count`、`prison.active`、`phase`、`practice`、`show_route`、`save_failed`、locale。`version` 不进键。

## 切分、接口和依赖

- 只扩展既有 M3 `present`：`["header"]` 与 `["body_bar"]` 均可局部；未知／`["*"]`／缺项／其余已声明名仍全量 `render(view)`（非空当前 View，禁止再 `get_view`）。`dirty.size()!=1` 仍全量。局部不得 `begin_frame`。
- `["header"]` 局部：同一固定序，节动作＝对**已有** `GameHeader` 调 `configure(self)`。`present` **必须**调用 `configure`（键比对只在 `header.gd`，`main.gd` 不得复制键、不得因自算键而跳过 `configure`）。不得再 instantiate `header.tscn`；不得调 `_header()` 除非局部路径保证不二次 instantiate、不跑 `_relic_row`；不得顺手 `layout.body_sidebar` 或其它节重建。无 `GameHeader`／layout 空／View 空 → 全量。允许改 `present`／`_present_needs_full_render` 的节路由。
- 键只在 `header.gd`：计算入口 `header._presentation_key(ui) -> Array`（与 body 同名）；脚本内保存上次键；`configure` 开头比对，命中早退。`main.gd` 不得复制第二套 header 键。键＝纯数据副本（Array／Dictionary／基础类型），不存旧 View／候选／装备图／节点引用。
- 键字段＝节键表 `header` 行，且必须覆盖 `configure` **实际读取**的 View／本地态。实读：`run_header.location`／`turn`／`order`／`last`、`security`、`wall`、`wall_position.distance`、`pressure.overloaded`、`carried_items`、`capacity`、`deck_count`、`prison.active`（与 `view.prison.get("active",false)` 同义）、`phase`、`practice`、`ui.show_route`、`ui.save_failed`。locale：`configure` 不调 `localization.display`，但 present／render 固定序末尾 `_localize_controls` 读 `ui.localization.locale`；locale **进键**（落地该表行）。`version` 禁止。configure 新读显示字段必须同批进键，且仍 ⊆ 该行。未命中重建后必须写入保存键，否则下一次局部必叠或必重建。
- 键命中：早退，保留 `GameHeader` 与已有具名按钮**实例**；`GameHeader` 上 `Button` 件数＝6。键未命中：就地更新该节（标签＋按钮）；已有 `OpenTutorial` 等须复用或先清再建模；再 `configure` 后 `GameHeader` 上 `Button` 件数仍＝6（地图键为 `OpenMap` 与 `OpenPrisonTutorial` 合计 1 个 Button）。不得把叠按钮当跳过。
- 允许实现面：`spire-godot/ui/main.gd` 的 `present` 路由（含 `_present_needs_full_render`）；`spire-godot/ui/shell/header.gd` 键＋早退＋不叠按钮；`spire-godot/tests/display_ui_cases.gd` 单个具名场景／`run` 注册。不得改 `_submit`／`commit`／`present_rejection`、不得改 `body_sidebar._presentation_key` 字段集、不得改 `header.tscn`／`game_layout.gd`／core／data。测试可对 `get_view` 做计数包装；生产源码不带计数器。
- 允许方向：仍 M3→M5（`header.configure`／`_presentation_key`）与既有 M3→M1.refresh_hints；测试 → `main.present`／`render`。**不新增**模块、运行时依赖、存档／schema、`present` 文件、`main`→core 新边、UI 文件。若实现仍要新模块／新 UI 文件／新允许边 → `needs-human-review` 并停下。
- `main.gd` 已超行数线；本刀只加薄路由，**不**为凑行数拆新模块。Godot 无 Size and ESM。

checkpoint(planner): specify present header Gherkin

## Gherkin：`present_routes_header_or_full`（一个可观察行为）

Given `tests/display_ui_cases.gd`，`ui.restart(42)` 后 `render(ui.view)`（战斗页，`GameHeader` 已建）。测试侧 `GetViewCountingGame`（已有包装，生产无计数器）接到 `ui.game` 后再 `render(ui.view)` 一次，记下 `get_view` 基线。钉 `GameHeader` 实例、其上 `Button` 件数（须＝6）、`OpenTutorial` 实例、`HeaderSecurity` 文本、`RelicStrip` 件数（0 或 1；有则钉实例）、快照／`state.rng`。Oracle＝该 `GameHeader._presentation_key(ui)`。不调 `_submit`。叠按钮计数：`header.find_children("*","Button",true,false).size()`（不要只数精确名 `OpenTutorial`，重名会被改成 `OpenTutorial2`）。
When 依次：① `present(["header"])` 空 snapshot、View／`show_route`／`save_failed`／locale 未改，再立刻第二次 `present(["header"])`；② `present(["*"])`；③ `present(["not_a_section"])`；④ 只改 `ui.view.security`（键内字段，不 `dispatch`）再 `present(["header"])`；⑤ `present(["body_bar"])`；⑥ `present(["relics"])`（已声明、本刀非局部）；⑦ `present(["header"], snapshot)` 传入当前 View 的非空副本。每步 `await t.frames`，每步记下该步之前的 `GameHeader` 实例。
Then ① `GameHeader` 实例保留、树内恰 1 个 `GameHeader`；其上 `Button` 件数＝6；`OpenTutorial` 实例 id 两次 present 均不变；`OpenStatus`／`OpenItems`／`OpenDeck`／`OpenMenu` 各存在；`OpenMap` 与 `OpenPrisonTutorial` 合计 1；`RelicStrip` 件数不增（有则实例不变）；hero／body／敌人仍有效；oracle 不变；`get_view`＝基线。②与③ 各相对该步之前的 `GameHeader` 被替换（全量走了 `begin_frame`），`get_view` 仍＝基线。④ header 实例等于③之后的那个（不再全量）；`HeaderSecurity` 可见文本含改后 `security`；`Button` 件数仍＝6（不得叠）。⑤ `GameHeader` 等于④之后的那个（`body_bar` 路由仍局部）。⑥ `GameHeader` 被替换（其余已声明名仍全量）。⑦ `get_view` 仍＝基线，`ui.view` 即传入 snapshot。全程 `export_snapshot()`／随机游标不变。不得用生产计数器；不得把 `render()` 空 snapshot 的 `get_view` 算进 present 义务。既有 `present_routes_body_bar_or_full`／`sidebar_refresh` 不得红。本场景不是契约场景 3 全表。

## 验收流程

UI 验收 **none**：本刀不改 `_submit`，玩家路径仍整树 `render`；画面刷新范围不变。不派验收者。

checkpoint(planner): close present header second slice

## 完成定义及档 2（尚未执行）

- 实现者交 `present` 的 `header` 局部路由、`header.gd` 的 `_presentation_key`＋保存键＋早退＋不叠按钮、上述场景（已注册进 `display_ui_cases.run`）；独立新会话审查者只核对本域源码／测试与本契约；清洁者核对：无第二套刷新管线、无新 UI 文件、无 `_submit` 改接、header 键只在 `header.gd`、`body_bar` 键仍只在 `body_sidebar._presentation_key`、`present` 签名仍为未类型化 `Array`、依赖面 ⊆ 允许面。本刀不写 `docs/spec`。
- 实现者在 `spire-godot/` 运行 `& tools/check.ps1 -UIOnly -UISuite display -TimeoutSeconds 900`。通过＝退出码 0、`SUITE RESULT: display PASS`、完成标记、`summary.json` 的 `status=passed` 且指纹未变。未运行、`source_changed`、场景未注册、或 `present` 空 snapshot 仍 `get_view`＝未完成。既有 `present_routes_body_bar_or_full`／`sidebar_refresh` 不得变红。不改 `body_sidebar.gd` 则不借 body_layout 旧绿宣称本域通过，也不必扩跑。
- 档 2（选定加固者，独立实现／清洁后）。栈档 2：规则套件＋内容包。内容包不适用（未改 packs）。规则 headless 无法观察节点实例／按钮件数：本刀敏感性在 display 窗口套件上跑，命令同上。变异须红：①`present(["not_a_section"])` 或 `["*"]` 不走全量（`GameHeader` 实例保留）；②`present(["header"])` 键命中仍重建该节（`GameHeader` 被换，或未改键时 `OpenTutorial` 实例被换）；③再 `configure` 叠按钮（`GameHeader` 上 `Button` 件数＞6）；④生产源码出现重建／`get_view` 计数器。原版绿；变异复原后重跑本域。不能靠静态搜索替代①②③的行为敏感性。缺工具或失败＝未通过，不算不适用。
- 无打包、发布、push。

## 非目标

其余已声明节一次落地；`scene_instances`／`enemy_group` 剥节；`commit` 拆分；`present_rejection`；把 `_submit` 改接到 `present`；新 CSS／样式引擎；T4／T5；`card_facts`；`keyword_ids`；窗口输入队列；恢复 `ActionIndex`；改 `header.tscn`／`game_layout.gd`；改 `body_sidebar` 键字段集。

## 风险假设

`layout.begin_frame` 仍释放 `GameHeader`，全量 vs 局部仍可用 header 实例区分。局部路径仍不得 `begin_frame`、不得清空 `layout.used`。`_header()` 现顺手 `_relic_row()`：局部若走 `_header` 且未拆遗物，会叠 `RelicStrip`。键未覆盖 configure 已读字段时，早退会留下过期标签／按钮文案／闭包。若实现要新 UI 文件或新允许边，停工交回，不新开 `present` 文件迁就。
