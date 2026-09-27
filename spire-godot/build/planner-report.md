# 规划者报告：present(dirty) 第五刀 actions

checkpoint(planner): specify present actions slice

- 域：`ui/main.gd::present` 加 `["actions"]` 局部；键＋早退在 `main.gd::_build_action_rail` 旁。保留 `header`／`body_bar`／`relics`／`hand` 路由。不拆 `commit`。不接 `present_rejection`。不改 `_submit`。
- 状态：**needs-human-review no**。静态搜无更小既有键／早退（仅已落地 `body_bar`／`header`／`relics`／`hand`）。节键表下一行 `actions` 已写字段集；给 `_build_action_rail` 建键并早退＝落地该行，不是新模块、不是新允许边。`quick_release_bar.build`／非战斗火球／`_selecting_hand`／`card_chain`／`reward_panel` 不进该行：不新建字段集，仅 `["actions"]`＋这些条件走全量，其它已局部节不变。契约 `spire-godot/build/partition-delta-5-extract.md`。起步 HEAD `d8875d3` 静态读取；未实现、未跑 Godot。
- 切分：`["actions"]` 只调 `_build_action_rail`，不得 `_fixed_actions`／`quick_release_bar`／`_header`／`header.configure`／`_relic_row`／`body_sidebar`／`_hand`／`begin_frame`。键 ⊆ 节键表 actions 行且覆盖 `phase`／`selected_enemy`／`attack_forms`／`quick_release_open`／attack＋calm 子集的 key/valid/reason/cost/label/body_part/casting/brief/risk；`version`／`flow`／`surrender`／`mana`／`brief_tags` 不进键；不得新 UI 文件或把键抄进 `quick_release_bar.gd`。再调不得叠 `AttackActions`。未知／`["*"]`／缺项／其余已声明名仍全量。
- Gherkin：`tests/display_ui_cases.gd::present_routes_actions_or_full`（待实现）。须改 header／relics／hand 场景「已声明非局部」步为 `["posture"]`。验收 UI **none**。档 2：键命中 `AttackActions`／`DeepBreath` 实例保留；未知／`["*"]` 全量；叠栏须红；生产无计数器。
- 允许文件：`spire-godot/ui/main.gd`、`spire-godot/tests/display_ui_cases.gd`。
- 检查证据：仅静态读取 `present`／`PRESENT_ADJACENCY`／`_build_action_rail`／`_fixed_actions`／`quick_release_bar.gd`／节键表；Godot／测试／审查／清洁／加固均未验证，不报告通过；无产品源码、打包、发布或 push。
