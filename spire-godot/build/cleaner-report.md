# 清洁者报告：relics sibling 顺序 P1（bunny）

checkpoint(cleaner): 范围与 HEAD 确认，本刀零代码改动只交报告

域：本刀增量（`ui/main.gd::_relic_row` 挂回 host 后 `move_child` 恢复原 index；`tests/display_ui_cases.gd::present_routes_relics_or_full` 夹具含 `TowerMapScroll` sibling 并断言 `get_index()==0`）。契约 `spire-godot/build/partition-delta-3-extract.md`，FAIL 源 `spire-godot/build/review-partition-delta-3-fail-bunny.md`，实现增量 `git diff 8916dac..ce269b9`（`ui/main.gd` +3 行、`tests/display_ui_cases.gd` +5 行、`build/implementer-report.md` 报告）。简报要求 HEAD 起步 `ce269b9`；实际 HEAD 即 `ce269b9`（分支 `worker/partition-delta`，起步 `git status --short` 为空）。独占 `C:\1\magic-spire-wt-partition-delta`。不当实现者／加固者；未改 `_submit`；未改 `_place` 全局语义；未改 `header.gd`／`game_layout.gd`／`relic_icon.gd`；无新 UI 文件；未拆 `main.gd`／`display_ui_cases.gd`；未 push；未暂存 `*.import`／`.uid`；未写 `docs/spec`；未把协调者简报扫进提交。本报告覆写上一刀的 `cleaner-report.md`（旧内容在 git 历史 `8916dac` 内可回溯）。本刀源码已洁，零代码改动，消费实现者同指纹证据，不重跑（见末块）。

checkpoint(cleaner): sibling 顺序恢复，FAIL P1 已闭合，通过

域：`ui/main.gd::_relic_row` 重建挂载。`8916dac..ce269b9` 内 `_relic_row` 新增 `var host_index=0`；释放前与 `host` 同批记下首个有效条的 `host_index=existing.get_index()`（`main.gd:619-624`）；`_place(strip,host_rect,host)` 后立刻 `host.move_child(strip,host_index)`（`main.gd:640`）。真实 `RouteMapColumn` 先 `reparent` 条再 `add_child(TowerMapScroll)`（`main.gd:1812-1822`：reparent→回写 min size／size_flags／position→加 `TowerMapScroll`）；重建后条回到原 index（夹具中为 0），仍在 `TowerMapScroll` 之上，不再被挤到地图之后。结论：通过。

checkpoint(cleaner): 夹具含 TowerMapScroll sibling 并断言顺序，通过

域：`tests/display_ui_cases.gd::present_routes_relics_or_full`。夹具：`RouteMapColumn` 下先有 live `RelicStrip`（reparent，自定 min size／EXPAND_FILL／position ZERO），后加名为 `TowerMapScroll` 的 `ScrollContainer` sibling；先断言 `live.get_index()==0` 且 `host.get_child(1)==map_scroll`（`display_ui_cases.gd:600-602`）。键未命中重建后断言：`rebuilt.get_parent()==host`、`rebuilt.get_index()==0`、`host.get_child(1)==map_scroll`（603-608）、position／size_flags 不变、全树 `RelicStrip` 件数＝1。空 `VBoxContainer` 夹具已被真实宿主夹具取代，FAIL 指出的覆盖缺口已补。结论：通过。

checkpoint(cleaner): `_place` 未改语义，通过

域：`ui/main.gd::_place`（363-368）。`8916dac..ce269b9` 内 `_place` 函数体零 diff：仍 `owner.add_child(node)`＋写 `position`／`size` 并返回。改动只在调用方 `_relic_row`：`_place` 之后加 `host.move_child(strip,host_index)` 一行；其它 `_place` 调用点（`_panel`／`_header`／抽屉等）行为不受影响。结论：通过。

checkpoint(cleaner): 邻接表不因 move_child 扩边，通过

域：本域 `present` 路由（`PRESENT_ADJACENCY`）。本增量未改 `PRESENT_ADJACENCY`（diff 为空）；声明边仍为 `present`→`_present_needs_full_render`／`render`／`header.configure`／`_relic_row`／`layout.body_sidebar`，`_relic_row`→`_relic_presentation_key`，余为叶。`move_child` 是既有 Control API 调用（与 `remove_child`／`add_child`／`queue_free` 同类基础设施），按简报不扩边。表源双向核对：`present` 内 `relics` 分支仍直调 `_relic_row`（`main.gd:518`），`_relic_row` 开头仍读 `_relic_presentation_key`（`main.gd:609`）。无表外路由边，无新边。结论：已洁。

checkpoint(cleaner): 无第二套刷新管线、无 _submit 改接，通过

域：`ui/main.gd` 展示调度与提交路径。全仓 `_relic_row()` 调用点仅两处：`present` 的 `["relics"]` 局部（518）与 `_header` 全量路径（597）；`--diff-filter=A` 为空，无新增文件。`_submit` 零 diff（hunk 仅 619／624／640 三处，`_submit` 在 2158 附近无触及）：仍 `game.dispatch`→`get_view`→`render`，未调 `present`。禁改文件（`header.gd`／`game_layout.gd`／`relic_icon.gd`）不在 `--name-only` 内。结论：通过。

checkpoint(cleaner): 体积与门禁口径；检查器未建则报未建

域：体积与复杂度／依赖检查器。Godot 无 Size and ESM；项目 `AGENTS.md` 无 Size 条款；简报明令不拆 `main.gd`／`display_ui_cases.gd`（本增量产品＋测试共 +8 行，未为凑行数拆新模块），本清洁未拆。`spire-godot/tools/` 内无钉住 present 边的最小依赖检查器，无 GDScript 复杂度门禁；本域最小声明表即 `PRESENT_ADJACENCY`（实现第三刀已交，本增量未改，本清洁只复核），按简报不新开框架。结论：无范围冲突，复杂度／依赖检查器记为未建。

checkpoint(cleaner): 验证与结论，本域已洁

域：本刀（`8916dac..ce269b9` 的 sibling 顺序 P1）。本清洁零代码改动，按简报消费实现者同指纹证据，不重跑。在 `spire-godot/build/checks/20260925T115456474-34716/`：`summary.json` `status=passed` 且 `before`＝`after`＝`541B167B9C87FC5BEC454376EDD108B8DE0623FA23981441811A506C2E029A05`；`check-ui.log`：`SUITE RESULT: display PASS`、`UI PASS: 345 assertions`（`UI SUITE display: 345 assertions, 46914 ms`）；`git diff --check 8916dac..ce269b9` 通过；`present_routes_body_bar_or_full`／`present_routes_header_or_full`／`sidebar_refresh` 同套件未红（同指纹套件内）。未运行项：规则套件、其它 UI 套件、打包、加固变异、验收（本刀 UI 验收 none）。结论：本域已洁；`*.import`／`.uid` 未暂存未提交，未 push。心跳见 `spire-godot/build/agent-cleaner-partition-delta-3-sibling.log`。
