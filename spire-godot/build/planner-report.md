# 规划者报告：present(dirty) 第四刀 hand

checkpoint(planner): specify present hand fourth slice

- 域：`ui/main.gd::present` 加 `["hand"]` 局部；键＋早退在 `main.gd::_hand` 旁。保留 `header`／`body_bar`／`relics` 路由。不拆 `commit`。不接 `present_rejection`。不改 `_submit`。
- 状态：**needs-human-review no**。静态搜无更小既有键／早退（已落地 `body_bar`／`header`／`relics` 在 `main.gd` 的遗物键）。节键表下一行 `hand` 已写字段集；给 `_hand` 建键并早退＝落地该行，不是新模块、不是新允许边。契约 `spire-godot/build/partition-delta-4-extract.md`。起步 HEAD `972427b` 静态读取；未实现、未跑 Godot。
- 切分：`["hand"]` 只调 `_hand()`，不得 `_header`／`_relic_row`／`_fixed_actions`／`body_sidebar`／`begin_frame`。键 ⊆ 节键表 hand 行且覆盖 `_hand`／`_card`／`_refresh_card_face` 显示字段（hand 条目、card_texts、card_instances、card_faces、selected_card、_selecting_hand、pending_draws、overload 分支）；`version` 不进键；不得新 UI 文件或把键抄进 `card_face.gd`。键命中保留同 uid `card_buttons` 实例；未知／`["*"]`／缺项／其余已声明名仍全量。`_present_needs_full_render` 对 `pressure.overloaded` 走全量（规格已写兜底）。
- Gherkin：`tests/display_ui_cases.gd::present_routes_hand_or_full`（待实现）。须改 `present_routes_header_or_full` 与 `present_routes_relics_or_full` 的「仍全量」步：`["hand"]`→`["actions"]`。验收 UI **none**。档 2：键命中 `card_buttons[uid]` 实例保留；未知／`["*"]` 全量；叠同 uid 按钮须红；生产无计数器。
- 允许文件：`spire-godot/ui/main.gd`、`spire-godot/tests/display_ui_cases.gd`。
- 检查证据：仅静态读取 `present`／`PRESENT_ADJACENCY`／`_hand`／`_card`／`_refresh_card_face`／节键表；Godot／测试／审查／清洁／加固均未验证，不报告通过；无产品源码、打包、发布或 push。
