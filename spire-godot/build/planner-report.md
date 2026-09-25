# 规划者报告：present(dirty) 第三刀 relics

checkpoint(planner): specify present relics third slice

- 域：`ui/main.gd::present` 加 `["relics"]` 局部；键＋早退在 `_relic_row` 旁。保留 `header`／`body_bar` 路由。不拆 `commit`。不接 `present_rejection`。不改 `_submit`。
- 状态：**needs-human-review no**。静态搜无更小既有键／早退（仅已落地的 `body_sidebar`／`header`）。节键表 `relics` 行已写字段集；给 `_relic_row` 建键并早退＝落地该行，不是新模块、不是新允许边。契约 `spire-godot/build/partition-delta-3-extract.md`。起步 HEAD `e5eceda` 静态读取；未实现、未跑 Godot。
- 切分：`["relics"]` 调 `_relic_row`，不得 `_header`／`header.configure`／`body_sidebar`、不得 `begin_frame`。无条带且 relics 非空则本函数创建（仍局部）。早退须条带仍在树上。键 ⊆ 节键表 relics 行且覆盖遗物显示实读字段（含 locale／`counter`；`rarity_name` 归 `rarity`）；`version` 不进键；候选事实不进键。再 `_relic_row` 不得叠 `RelicStrip`／同名 `RelicShortcut_*`。未知／`["*"]`／缺项／其余已声明名仍全量。
- Gherkin：`tests/display_ui_cases.gd::present_routes_relics_or_full`（待实现）。须改 `present_routes_header_or_full` 原⑥步为 `["hand"]`。验收 UI **none**。档 2：键命中 `RelicStrip` 实例保留；未知／`["*"]` 全量；叠条带须红；生产无计数器。
- 允许文件：`spire-godot/ui/main.gd`；`spire-godot/tests/display_ui_cases.gd`。
- 检查证据：仅静态读取 `present`／`_relic_row`／`RelicEffects.view`／节键表／既有 `_presentation_key` 两处；Godot／测试／审查／清洁／加固均未验证，不报告通过；无产品源码、打包、发布或 push。
