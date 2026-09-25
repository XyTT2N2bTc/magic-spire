# 清洁者报告：relics 审查 FAIL 闭合（bunny P1/P2）

checkpoint(cleaner): 范围与 HEAD 确认，本刀零代码改动只交报告

域：本刀增量（`ui/main.gd::_relic_row` 保留原父容器＋早退 0/1 条不变量，`tests/display_ui_cases.gd::present_routes_relics_or_full` 的 `body_bar` 步钉 `RelicStrip`）。契约 `spire-godot/build/partition-delta-3-extract.md`，FAIL 源 `spire-godot/build/review-partition-delta-3-bunny.md`，实现增量 `git diff 6afce9a..091d315`（内含 `70d299c` 代码＋`091d315` 报告）。简报要求 HEAD 起步 `091d315`；实际 HEAD 即 `091d315`（分支 `worker/partition-delta`，起步 `git status --porcelain` 干净，`6afce9a..091d315 --name-only` 仅三文件：`build/implementer-report.md`、`tests/display_ui_cases.gd`、`ui/main.gd`）。独占 `C:\1\magic-spire-wt-partition-delta`。不当实现者／加固者；未改 `_submit`；未改 `header.gd`／`header.tscn`／`game_layout.gd`／`relic_icon.gd`／`body_sidebar._presentation_key`；无新 UI 文件；未拆 `main.gd`／`display_ui_cases.gd`；未 push；未暂存 `*.import`／`.uid`；未写 `docs/spec`；未把协调者简报扫进提交。本报告覆写第三刀的 `cleaner-report.md`（旧内容在 git 历史内可回溯）。本刀源码已洁，零代码改动，消费实现者同指纹证据，不重跑（见末块）。

checkpoint(cleaner): P1 重建保留原父容器，通过

域：`ui/main.gd::_relic_row` 重建挂载（地图页 `RouteMapColumn` reparent 情形）。`6afce9a..091d315` 内 `_relic_row` 键未命中路径先记 `host`＝首个有效 `RelicStrip` 的 `get_parent()`（`is Control` 才记），并记 `host_rect=Rect2(existing.position,existing.size)`、`custom_minimum_size`、`size_flags_horizontal/vertical`，释放旧条后 `is_instance_valid(host)` 则 `_place(strip,host_rect,host)` 并回写三项布局属性，否则回退 `_place(strip,Rect2(405,78,1013,56))`（战斗页默认位）。不再把地图页条挂回默认 `layout` 位。场景钉：`live.reparent(host)` 后改 `counter` 触发重建，断言 `rebuilt.get_parent()==host`、`position==Vector2.ZERO`、`size_flags_horizontal==EXPAND_FILL`、件数＝1。结论：通过。

checkpoint(cleaner): P2 早退仅当 0/1 条不变量成立，通过

域：`ui/main.gd::_relic_row` 早退谓词与空／多条规范化。早退由 `if _relic_key==key and (view.relics.is_empty() or not strips.is_empty())` 收紧为 `if _relic_key==key and strips.size()==(0 if view.relics.is_empty() else 1)`。空视图有条（`size==1` 而期望 `0`）则不早退，走释放循环后 `view.relics.is_empty()` 分支写回键并返回（卸载）；多条（`size==2` 而期望 `1`）则不早退，走清再建。场景钉：异父双条夹具 `size==2` 经 `present(["relics"])` 折叠为 `1`；空视图 `leftover` 单条夹具经 `present(["relics"])` 卸为空；空视图卸载后 `GameHeader` 保留、`get_view` 基线不变。结论：通过。

checkpoint(cleaner): `body_bar` 步已钉 `RelicStrip`，通过

域：`tests/display_ui_cases.gd::present_routes_relics_or_full` 的 `body_bar` 路由。`6afce9a..091d315` 在 `present(["body_bar"])` 步追加两断言：`find_child("RelicStrip")==strip_after_mutation`（键变更后那条）与 `find_children("RelicStrip").size()==1`。此前该步只断言 `GameHeader` 保留，误删／重建／移动条带仍会绿；现与 `present(["header"])` 步的条带断言对称，补上回归敏感性。结论：通过。

checkpoint(cleaner): 邻接表仍与源一致，不扩表，通过

域：本域 `present` 路由（`PRESENT_ADJACENCY`）。本增量未改 `PRESENT_ADJACENCY`（`6afce9a..091d315` 内该常量 diff 为空）；声明边仍为 `present`→`_present_needs_full_render`／`render`／`header.configure`／`_relic_row`／`layout.body_sidebar`，`_relic_row`→`_relic_presentation_key`，余为叶。表源双向核对：`present` 内 `relics` 分支仍直调 `_relic_row`（`main.gd:518`），`_relic_row` 开头仍读 `_relic_presentation_key`（`main.gd:609`）；`_place(strip,host_rect,host)` 的第三参只是既有帮手 `_place(node,rect,parent=null)`（`main.gd:363`，签名本增量未动，刀前已存在），按简报不为它扩表；`find_children`／`remove_child`／`queue_free` 同为刀前基础设施边，与第三刀口径一致。无表外路由边，无新边。结论：已洁。

checkpoint(cleaner): 无第二套刷新管线、无新 UI 文件，通过

域：`ui/main.gd` 展示调度（`render` 对 `present`）。`6afce9a..091d315 --name-only` 仅上述三文件，`--diff-filter=A` 为空，无新增文件。全仓 UI 刷新仍仅 `main.gd::render`（全量，唯一 `begin_frame` 持有者，`main.gd:422`）与 `main.gd::present`（薄入口复用）；`present` 函数体内零 `begin_frame`、零 `layout.used`（全仓 `layout.used` 零命中）、零 `_header()` 调用（`_header` 仅 `render` 内一次）；`["relics"]` 局部只调 `_relic_row`，未调 `_header`／`header.configure`／`layout.body_sidebar`，未 `preload`／`instantiate` 新 UI。`core/torso_binding.gd::present` 是装备绑定谓词，与 UI 刷新无关。结论：单刷新管线，通过。

checkpoint(cleaner): `_submit` 未改接，通过

域：`ui/main.gd::_submit`。本增量 diff 内零命中 `_submit`／`commit`／`present_rejection`（`--name-only` 无相关文件，内容 diff 无该三符号 `+`／`-` 行）。`_submit` 仍走 `game.dispatch`→`game.get_view`→`render(updated)`（`main.gd:2170-2192`），未调 `present`；`present` 全路径零 `game.get_view`（`get_view` 仅 `render` 空 snapshot 分支与 `_submit` 内，`present`／`_relic_row` 内零命中）。`PRESENT_SECTIONS` 未新增节名，`present(dirty: Array=["*"],…)` 保持未类型化 Array。结论：提交路径不动，玩家路径仍整树 `render`，通过。

checkpoint(cleaner): 体积与门禁口径，不拆文件；检查器未建则报未建

域：体积与复杂度／依赖检查器。Godot 无 Size and ESM；项目 `AGENTS.md` 无 Size 条款。`main.gd`、`display_ui_cases.gd` 本就超长，简报明令不拆 `main.gd`／`display_ui_cases.gd`（本修复只改 `_relic_row` 早退与挂载共 21 行、`display` 场景共 28 行，未为凑行数拆新模块），本清洁未拆。`spire-godot/tools/` 仅套件执行与文档门禁，无钉住 present 边的最小依赖检查器，无 GDScript 复杂度门禁；本域最小声明表即 `PRESENT_ADJACENCY`（实现第三刀已交，本增量未改，本清洁只复核），按简报不新开框架。结论：无范围冲突，复杂度／依赖检查器记为未建。

checkpoint(cleaner): 验证与结论，本域已洁

域：本刀（`6afce9a..091d315` 的 relics FAIL 闭合）。本清洁零代码改动，按简报消费实现者同指纹证据，不重跑。在 `spire-godot/build/checks/20260925T113346952-20352/`：`summary.json` `status=passed` 且 `before`＝`after`＝`CE7DA483E38C11E086C1A0EB9315884800E451F825B866B9CF66C53CE99A21B7`；`check-ui.log`：`SUITE RESULT: display PASS`、`UI PASS: 342 assertions`（`UI SUITE display: 342 assertions, 123800 ms`）；`check-docs.log`：`DOCS PASS: 35 rule-class document(s), 2412 reference(s)`；`git diff --check 6afce9a..091d315` 通过；`present_routes_body_bar_or_full`／`present_routes_header_or_full`／`sidebar_refresh` 同套件未红（同指纹套件内）。未运行项：规则套件、其它 UI 套件、打包、加固变异（档 2）、验收（本刀 UI 验收 none）。结论：本域已洁；`*.import`／`.uid` 未暂存未提交，未 push。心跳见 `spire-godot/build/agent-cleaner-partition-delta-3-fail.log`。
