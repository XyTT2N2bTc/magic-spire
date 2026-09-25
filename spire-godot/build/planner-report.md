# 规划者报告：present(dirty) 第四刀 hand

checkpoint(planner): report present hand fourth slice

- 域：`ui/main.gd::present` 加 `["hand"]` 局部；键＋早退在 `main.gd::_hand` 旁。保留 `header`／`body_bar`／`relics` 路由。不拆 `commit`。不接 `present_rejection`。不改 `_submit`。
- 状态：**needs-human-review no**。静态搜无更小既有键／早退（仅已落地 `body_bar`／`header`／`relics`）。节键表下一行 `hand` 已写字段集；给 `_hand` 建键并早退＝落地该行，不是新模块、不是新允许边。`pressure.overloaded`／`climax` 不在该行：不新建字段集，仅 `["hand"]`＋overloaded 走全量，其它已局部节不变。契约 `spire-godot/build/partition-delta-4-extract.md`。起步 HEAD `972427b` 静态读取；未实现、未跑 Godot。
- 切分：`["hand"]` 只调 `_hand`，不得 `_header`／`header.configure`／`_relic_row`／`body_sidebar`／`begin_frame`。键 ⊆ 节键表 hand 行且覆盖牌面显示字段（uid/type/draw_serial/draw_free/single_face/availability/face_*、对应 card_texts／card_instances、card_faces、selected_card、`_selecting_hand()` 布尔、pending_draws）；`version`／`display_facts`／`climax` 不进键；不得新 UI 文件或把键抄进 `card_face.gd`。再调不得叠同 uid 手牌按钮。未知／`["*"]`／缺项／其余已声明名仍全量。
- Gherkin：`tests/display_ui_cases.gd::present_routes_hand_or_full`（待实现）。须改 header 与 relics 场景「已声明非局部」步为 `["actions"]`。验收 UI **none**。档 2：键命中 `card_buttons[first_uid]` 实例保留；未知／`["*"]` 全量；叠牌须红；生产无计数器。
- 允许文件：`spire-godot/ui/main.gd`、`spire-godot/tests/display_ui_cases.gd`。
- 检查证据：仅静态读取 `present`／`PRESENT_ADJACENCY`／`_hand`／`_card`／`card_face.gd`／节键表；Godot／测试／审查／清洁／加固均未验证，不报告通过；无产品源码、打包、发布或 push。
