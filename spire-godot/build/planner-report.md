# 规划者报告：present(dirty) 第二刀 header

checkpoint(planner): specify present header second slice

- 域：`ui/main.gd::present` 加 `["header"]` 局部；键＋早退在 `ui/shell/header.gd::configure`。保留 `body_bar` 路由。不拆 `commit`。不接 `present_rejection`。不改 `_submit`。
- 状态：**needs-human-review no**。协调者已记录通宵计划审阅选①；给 `header.configure` 建键并早退＝落地节键表 `header` 行，不是新模块、不是新允许边。契约 `spire-godot/build/partition-delta-2-extract.md`。起步 HEAD `9cb5754` 静态读取；未实现、未跑 Godot。
- 切分：`["header"]` 找已有 `GameHeader` 再 `configure`，不得二次 instantiate、不得 `_relic_row`、不得 `begin_frame`。键 ⊆ 节键表 header 行且覆盖 configure 实读字段（含 locale／`show_route`／`save_failed`）；`version` 不进键；`main.gd` 不复制第二套键。再 `configure` 不得叠 `OpenTutorial` 等。未知／`["*"]`／缺项／其余已声明名仍全量。
- Gherkin：`tests/display_ui_cases.gd::present_routes_header_or_full`（待实现）。验收 UI **none**。档 2：键命中 header 实例保留；未知／`["*"]` 全量；叠按钮须红；生产无计数器。
- 检查证据：仅静态读取 `present`／`_header`／`header.configure`／节键表；Godot／测试／审查／清洁／加固均未验证，不报告通过；无产品源码、打包、发布或 push。
