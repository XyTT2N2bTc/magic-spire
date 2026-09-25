# 实现者报告：present(dirty) 第十一刀 speech

域：`ui/main.gd` M3 展示调度（`present` 加 `["speech"]` 局部）与 `_speech_bubble` 共享键＋早退＋不叠组。非清洁／非加固。

起步 HEAD：`3cff258`（规划者第十一刀契约）。分支 `worker/partition-delta`。未 push。未碰其它工作树或 `C:\1\magic-spire` 主树。本报告提交前源码 HEAD：`10d97d4`。无 `needs-human-review`。未停工交回。

## 改动文件

- `spire-godot/ui/main.gd`（3516 行）：`present(["speech"])` 有独立分支，只调 `_refresh_speech_section`（薄包：键命中早退；未命中 `_remove_local_panel("HeroSpeechGroup")` 再 `_speech_bubble()`，默认 `point_to_hero=true`），**不**落入 `else` 的 `layout.body_sidebar`。`["header"]`／`["body_bar"]`／`["relics"]`／`["hand"]`／`["actions"]`／`["posture"]`／`["resources"]`／`["show_log"]`／`["body_details"]`／`["pickers"]` 仍局部。未知／`["*"]`／其它已声明名仍全量 `render(view)`，禁止再 `get_view`。`_speech_presentation_key` 与 `_speech_key` 紧挨 `_speech_bubble`；薄函数与 `_speech_bubble` 共用该键，无第二套。键字段＝`view.speech` 的 `id`／`text`（缺项按现行空）、本地 `speech_id`（字符串）与 `speech_deadline`（整数）。`version`／`npc_speech`／`visual`／`cue`／`phase`／`name`／locale／`suppressed_hero_speech_id`／`first_turn_control`／`show_home`／`show_route`／顶层 `phase` 不进键。`_present_needs_full_render`：**仅** `["speech"]` 且空对白／`show_home`／`show_route`／非 battle／`_takeover_locked()`／`suppressed_hero_speech_id` 命中当前 `speech.id`／`npc_speech` 非空 → 全量；`present` 对 snapshot 的 `next` 同检（接管锁：`not show_home and bool(next.first_turn_control.locked)`，缺项按现行假）。未把 `_speech_visible`／`Time.get_ticks_msec` 当全量谓词。不得把这些扩到 header／body_bar／relics／hand／actions／posture／resources／show_log／body_details／pickers，亦未删既有节的全量条件。`PRESENT_ADJACENCY` 与源同步（`present` 增 `_refresh_speech_section`，其读本文件键函数并调 `_speech_bubble`；`present` 直调不含 `_npc_speech_bubble`／`_skip_hero_speech`／`_battle_scene`／`_shop_chatter`／`_dismiss_speech`／`_speech_visible`）。签名仍是 `present(dirty: Array=["*"], snapshot: Dictionary={})`。未改 `_submit`。局部路径未调 `_npc_speech_bubble`／`_skip_hero_speech`／`_battle_scene`／`_shop_chatter`／`_dismiss_speech`／`_header`／`header.configure`／`_relic_row`／`layout.body_sidebar`／`_hand`／`_fixed_actions`／`_build_action_rail`／`_bottom_controls`／`_refresh_resource_section`／`_wall_controls`／`_posture_controls`／`_refresh_posture_section`／`_refresh_log_section`／`_log_drawer`／`_refresh_drawers`／`_open_drawer`／`_body_details`／`_refresh_body_details_section`／`_hand_target_picker`／`_player_picker`／`_refresh_picker_section`／`begin_frame`、未清空 `layout.used`、未建 `NpcSpeech`／`ShopkeeperSpeech`／`PlayerPart_*`。未改 `header.tscn`／`header.gd`／`body_sidebar.gd`／`game_layout.gd`／`first_turn_presenter.gd`／`command_routes.gd`／`command_router.gd`／`header._presentation_key`／`body_sidebar._presentation_key`／`_relic_presentation_key`／`_hand_presentation_key`／`_action_presentation_key`／`_posture_presentation_key`／`_resource_presentation_key`／`_log_presentation_key`／`_body_details_presentation_key`／`_picker_presentation_key`。无新 UI 文件。无 core／data。无 `docs/spec`。空对白／主页／路线／非战斗／接管／已抑制／有 NPC 泡本刀全量。
- `spire-godot/tests/display_ui_cases.gd`（1740 行）：`present_routes_speech_or_full` 已在 `run` 里接在 `present_routes_pickers_or_full` 之后。`present_routes_header_or_full`／`present_routes_relics_or_full`／`present_routes_hand_or_full`／`present_routes_actions_or_full`／`present_routes_posture_or_full`／`present_routes_resources_or_full`／`present_routes_show_log_or_full`／`present_routes_body_details_or_full`／`present_routes_pickers_or_full` 的「已声明非局部」步由 `["speech"]` 改为 `["notice"]`。本场景不测 `present(["body_details"])`／`present(["pickers"])` 的仍局部。测试侧 `GetViewCountingGame`。生产无计数器。夹具先注入 `view.speech` 并全量 `render` 建泡，再 `_open_drawer("show_log")`。
- `spire-godot/build/implementer-report.md`（本文件，`git add -f`；保留后文既有结论）

Godot 无 Size and ESM。`main.gd` 本就超长；本刀只加薄路由与对白早退，未拆文件。

检查点：
- `b5aaee1` `checkpoint(implementer): add present speech routing`
- `10d97d4` `checkpoint(implementer): add present_routes_speech_or_full`

## 叠组

不叠。键命中早退只在卸组／建模之前一次（`_refresh_speech_section`，**不**写进 `_speech_bubble` 本体），且要求树上活 `HeroSpeechGroup` 件数＝1，该组上 `HeroSpeech`／`HeroSpeechText` 各 1 且仍是该组子孙。禁止只凭缓存键、组已被 `begin_frame` 释放仍早退。键未命中先 `_remove_local_panel("HeroSpeechGroup")`，**禁止** `_dismiss_speech` 代替卸组。禁止卸 `NpcSpeechGroup`／`ShopkeeperSpeech`／`GameHeader`。保留 `GameHeader`／身体栏／手牌／`InformationLayer`／资源／姿态／详情（有则）。`_place` 父节点为 `layout`。全量 `_battle_scene`→`_speech_bubble` 不在此卸组（`begin_frame` 已释放），仍在实际建组之后写回键。空对白／接管／抑制／不可见早退不写本键。禁止卸组前预调 `_speech_visible`。无活 `HeroSpeechGroup` 且本路径条件已满足时本路径创建，不改走全量。场景断言 `HeroSpeechGroup`／`HeroSpeech`／`HeroSpeechText` 件数＝1。套件绿。

## 表外全量

只让 `["speech"]` 在空对白／`show_home`／`show_route`／非 battle／接管锁／`suppressed_hero_speech_id` 命中／`npc_speech` 非空时走全量。`header`／`body_bar`／`relics`／`hand`／`actions`／`posture`／`resources`／`show_log`／`body_details`／`pickers` 的全量条件未改。局部 `["speech"]` 因而从不在空对白／接管／已抑制／有 NPC 泡／非战斗页建 `HeroSpeechGroup`，从不建 `NpcSpeech`／`ShopkeeperSpeech`。

## 检查

在 `spire-godot/`：

```
$env:GODOT_BIN='C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'
& tools/check.ps1 -UIOnly -UISuite display -TimeoutSeconds 900
```

通过（本会话实测）：

- 退出码 0
- `SUITE RESULT: display PASS`
- `UI PASS: 739 assertions`（`check-ui.log`：UI SUITE display 739 assertions, 71.80s）
- `summary.json` `status=passed`，`before`＝`after`＝`30E174EAD119836292B098B91A1D47DED854EAC40E661F33D77C0C19B28C9188`
- 日志：`spire-godot/build/checks/20260925T184547542-42472/`

`present_routes_body_bar_or_full`／`present_routes_header_or_full`／`present_routes_relics_or_full`／`present_routes_hand_or_full`／`present_routes_actions_or_full`／`present_routes_posture_or_full`／`present_routes_resources_or_full`／`present_routes_show_log_or_full`／`present_routes_body_details_or_full`／`present_routes_pickers_or_full`／`sidebar_refresh` 同套件未红。未提交 `*.import`／`.uid`。

未跑：规则套件、其它 UI 套件、打包、加固变异、验收（本刀 UI 验收 none）、双审。未停工交回。无 `needs-human-review`。

---

# 实现者报告：present(dirty) 第十刀 pickers

域：`ui/main.gd` M3 展示调度（`present` 加 `["pickers"]` 局部）与 `_hand_target_picker` 共享键＋早退＋不叠条。非清洁／非加固。

起步 HEAD：`f84064c`（规划者第十刀契约）。分支 `worker/partition-delta`。未 push。未碰其它工作树或 `C:\1\magic-spire` 主树。本报告提交前源码 HEAD：`63b9bec`。无 `needs-human-review`。未停工交回。

## 改动文件

- `spire-godot/ui/main.gd`（3473 行）：`present(["pickers"])` 有独立分支，只调 `_refresh_picker_section`（薄包：键命中早退；未命中 `_remove_local_panel("HandSelectionBar")` 再 `_hand_target_picker`），**不**落入 `else` 的 `layout.body_sidebar`。`["header"]`／`["body_bar"]`／`["relics"]`／`["hand"]`／`["actions"]`／`["posture"]`／`["resources"]`／`["show_log"]`／`["body_details"]` 仍局部。未知／`["*"]`／其它已声明名仍全量 `render(view)`，禁止再 `get_view`。`_picker_presentation_key` 与 `_picker_key` 紧挨 `_hand_target_picker`；薄函数与 `_hand_target_picker` 共用该键，无第二套。键字段＝本地 `player_pick` 布尔、`player_pick_data` 的 `hand_selection`／`card_uid`／`free`／`target`／`slot`（缺项按现行 `get` 默认；空字段也写键）。`version`／`view.hand`／`display_facts` 的 card／hand_uid 候选／`body_groups`／locale 不进键。`_present_needs_full_render`：**仅** `["pickers"]` 且 `not _selecting_hand()` → 全量；`present` 对 snapshot 的 `next` 同检（选牌态是 UI 实例标志）。不得把这条件扩到 header／body_bar／relics／hand／actions／posture／resources／show_log／body_details，亦未删 actions／body_details 已有的 `_selecting_hand` 全量。`PRESENT_ADJACENCY` 与源同步（`present` 增 `_refresh_picker_section`，其读本文件键函数并调 `_hand_target_picker`；`present` 直调不含 `_player_picker`／`_clear_player_picker`／`_hand`／`open_hand_selection`／`_hand_choice`／`command_router.emit`）。签名仍是 `present(dirty: Array=["*"], snapshot: Dictionary={})`。未改 `_submit`。局部路径未调 `_player_picker`／`_clear_player_picker`／`_hand`／`open_hand_selection`／`_hand_choice`／`TargetQueries.facts`／`DragTargets.focus`／`command_router.emit`／`_header`／`header.configure`／`_relic_row`／`layout.body_sidebar`／`_body_details`／`_refresh_body_details`／`_body_drawer`／`_fixed_actions`／`_build_action_rail`／`_bottom_controls`／`_refresh_resource_section`／`_wall_controls`／`_posture_controls`／`_refresh_posture_section`／`_refresh_log_section`／`_log_drawer`／`_refresh_drawers`／`_open_drawer`／`_battle_scene`／`begin_frame`、未清空 `layout.used`、未建 `PlayerPart_*`。未改 `header.tscn`／`header.gd`／`body_sidebar.gd`／`game_layout.gd`／`command_routes.gd`／`command_router.gd`／`target_queries.gd`／`header._presentation_key`／`body_sidebar._presentation_key`／`_relic_presentation_key`／`_hand_presentation_key`／`_action_presentation_key`／`_posture_presentation_key`／`_resource_presentation_key`／`_log_presentation_key`／`_body_details_presentation_key`。无新 UI 文件。无 core／data。无 `docs/spec`。关闭态／部位选择窗本刀全量。
- `spire-godot/tests/display_ui_cases.gd`（1627 行）：`present_routes_pickers_or_full` 已在 `run` 里接在 `present_routes_body_details_or_full` 之后。`present_routes_header_or_full`／`present_routes_relics_or_full`／`present_routes_hand_or_full`／`present_routes_actions_or_full`／`present_routes_posture_or_full`／`present_routes_resources_or_full`／`present_routes_show_log_or_full`／`present_routes_body_details_or_full` 的「已声明非局部」步由 `["pickers"]` 改为 `["speech"]`。本场景不测 `present(["actions"])`／`present(["body_details"])` 的仍局部。测试侧 `GetViewCountingGame`。生产无计数器。夹具先 `_open_drawer("show_log")` 再 `open_hand_selection`。
- `spire-godot/build/implementer-report.md`（本文件，`git add -f`；保留后文既有结论）

Godot 无 Size and ESM。`main.gd` 本就超长；本刀只加薄路由与选择条早退，未拆文件。

检查点：
- `61741c0` `checkpoint(implementer): add present pickers routing`
- `63b9bec` `checkpoint(implementer): add present_routes_pickers_or_full`

## 叠条

不叠。键命中早退只在卸条／建模之前一次（`_refresh_picker_section`，**不**写进 `_hand_target_picker` 本体），且要求树上活 `HandSelectionBar` 件数＝1，该条上 `HandTargetCancel` 件数＝1 且仍是该条子孙。禁止只凭缓存键、条已被 `begin_frame` 释放仍早退。键未命中先 `_remove_local_panel("HandSelectionBar")`，**禁止** `_clear_player_picker`。保留 `GameHeader`／身体栏／手牌／`InformationLayer`／资源／姿态／详情（有则）。`_place` 父节点为 `layout`。全量 `_player_picker`→`_hand_target_picker` 不在此卸条（`begin_frame` 已释放），仍在 `_hand_target_picker` 末写回键（空 `player_pick_data` 字段也写）。部位窗分支本刀不写本键。无活 `HandSelectionBar` 且本路径条件已满足时本路径创建，不改走全量。场景断言 `HandSelectionBar`／`HandTargetCancel` 件数＝1。套件绿。

## 表外全量

只让 `["pickers"]` 在 `not _selecting_hand()` 时走全量。`header`／`body_bar`／`relics`／`hand`／`actions`／`posture`／`resources`／`show_log`／`body_details` 的全量条件未改；actions／body_details 已有的 `_selecting_hand` 全量未删。局部 `["pickers"]` 因而从不在关闭态／部位选择窗建 `HandSelectionBar`，从不建 `PlayerPart_*`。

## 检查

在 `spire-godot/`：

```
$env:GODOT_BIN='C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'
& tools/check.ps1 -UIOnly -UISuite display -TimeoutSeconds 900
```

通过（本会话实测）：

- 退出码 0
- `SUITE RESULT: display PASS`
- `UI PASS: 681 assertions`（`check-ui.log`：UI SUITE display 681 assertions, 69.90s）
- `summary.json` `status=passed`，`before`＝`after`＝`E4696F0F6FD0300AAD19FC91C8DEF5959F6EB0F594E1ABBA63A1481BAD483FB2`
- 日志：`spire-godot/build/checks/20260925T182747565-39112/`

`present_routes_body_bar_or_full`／`present_routes_header_or_full`／`present_routes_relics_or_full`／`present_routes_hand_or_full`／`present_routes_actions_or_full`／`present_routes_posture_or_full`／`present_routes_resources_or_full`／`present_routes_show_log_or_full`／`present_routes_body_details_or_full`／`sidebar_refresh` 同套件未红。未提交 `*.import`／`.uid`。

未跑：规则套件、其它 UI 套件、打包、加固变异、验收（本刀 UI 验收 none）、双审。未停工交回。无 `needs-human-review`。

---

# 实现者报告：present(dirty) 第九刀 body_details

域：`ui/main.gd` M3 展示调度（`present` 加 `["body_details"]` 局部）与 `_body_details` 共享键＋早退＋不叠窗。非清洁／非加固。

起步 HEAD：`bc0e95e`（规划者第九刀契约）。分支 `worker/partition-delta`。未 push。未碰其它工作树或 `C:\1\magic-spire` 主树。本报告提交前源码 HEAD：`637a2ee`。无 `needs-human-review`。未停工交回。

## 改动文件

- `spire-godot/ui/main.gd`（3438 行）：`present(["body_details"])` 有独立分支，只调 `_refresh_body_details_section`（薄包：键命中早退；未命中 `_remove_local_panel("EquipmentDetails")` 再 `_body_details`；选牌且非选牌态时按现行口径 `DragTargets.focus_bodies`），**不**落入 `else` 的 `layout.body_sidebar`。`["header"]`／`["body_bar"]`／`["relics"]`／`["hand"]`／`["actions"]`／`["posture"]`／`["resources"]`／`["show_log"]` 仍局部。未知／`["*"]`／其它已声明名仍全量 `render(view)`，禁止再 `get_view`。`_body_details_presentation_key` 与 `_body_details_key` 紧挨 `_body_details`；薄函数与 `_body_details` 共用该键，无第二套。键字段＝本地 `selected_slot`／`selected_card`／`selected_candidate`／`show_body`／`quick_release_open`、`view.pending_retain` 布尔、`view.guard_bind.is_empty()` 布尔、`card_faces` uid→bool 副本、相关候选（`_body_equipment_entries`＋members 同一批 id 的 manual／attack `select`；`selected_card!=""` 时另含 guard_bind `find`、`_body_card_actions` 各条、`_single_body_card_action` 可空）；每条用事实 `key`＋`valid`／`reason`／`cost`／`preview`。`version`／`quick_release_inspected`／`phase`／`retain_left`／装备外观／`severity`／`label`／`mana`／`risk`／`payload.*`／locale／`player_pick` 不进键。`_present_needs_full_render`：**仅** `["body_details"]` 且 `_selecting_hand()`／关窗／`quick_release_open`／非 battle／`pending_retain` → 全量；`present` 对 snapshot 的 `next` 同检。不得把这些扩到 header／body_bar／relics／hand／actions／posture／resources／show_log。`PRESENT_ADJACENCY` 与源同步（`present` 增 `_refresh_body_details_section`，其读本文件键函数并调 `_body_details`；`present` 直调不含 `_body_drawer`／`_refresh_body_details`／`_equipment_tile`／`_action_row`／`_card_target`／`release_details`／`quick_release_bar`）。签名仍是 `present(dirty: Array=["*"], snapshot: Dictionary={})`。未改 `_submit`。局部路径未调 `_body_drawer`／既有 `_refresh_body_details`／`layout.body_sidebar`／`_header`／`header.configure`／`_relic_row`／`_hand`／`_fixed_actions`／`_build_action_rail`／`_bottom_controls`／`_refresh_resource_section`／`_wall_controls`／`_posture_controls`／`_refresh_posture_section`／`_refresh_log_section`／`_log_drawer`／`_refresh_drawers`／`_open_drawer`／`_hand_target_picker`／`_player_picker`／`_battle_scene`／`begin_frame`、未清空 `layout.used`、未直调 `_equipment_tile`／`_action_row`／`_card_target`／`release_details.*`／`quick_release_bar.*`。未改 `header.tscn`／`header.gd`／`body_sidebar.gd`／`game_layout.gd`／`release_details.gd`／`target_queries.gd`／`quick_release_bar.gd`／`header._presentation_key`／`body_sidebar._presentation_key`／`_relic_presentation_key`／`_hand_presentation_key`／`_action_presentation_key`／`_posture_presentation_key`／`_resource_presentation_key`／`_log_presentation_key`。无新 UI 文件。无 core／data。无 `docs/spec`。选牌态／关窗／快捷挣脱／非战斗／保留手牌详情本刀不局部。
- `spire-godot/tests/display_ui_cases.gd`（1518 行）：`present_routes_body_details_or_full` 已在 `run` 里接在 `present_routes_show_log_or_full` 之后。`present_routes_header_or_full`／`present_routes_relics_or_full`／`present_routes_hand_or_full`／`present_routes_actions_or_full`／`present_routes_posture_or_full`／`present_routes_resources_or_full`／`present_routes_show_log_or_full` 的「已声明非局部」步由 `["body_details"]` 改为 `["pickers"]`。测试侧 `GetViewCountingGame`。生产无计数器。⑫ `present(["show_log"])` 须走既有局部路由，夹具在详情已建后 `_open_drawer("show_log")`（第八刀关闭态仍全量，本刀未改该条件）。
- `spire-godot/build/implementer-report.md`（本文件，`git add -f`；保留后文既有结论）

Godot 无 Size and ESM。`main.gd` 本就超长；本刀只加薄路由与详情节早退，未拆文件。

检查点：
- `30b7857` `checkpoint(implementer): add present body_details routing`
- `637a2ee` `checkpoint(implementer): add present_routes_body_details_or_full`

## 叠窗

不叠。键命中早退只在卸栏／建模之前一次（`_refresh_body_details_section`，**不**写进 `_body_details` 本体），且要求树上活 `EquipmentDetails` 件数＝1，该窗上 `CloseEquipmentDetails`／`EquipmentTutorial` 各 1 且仍是该窗子孙。禁止只凭缓存键、窗已被 `begin_frame` 释放仍早退。键未命中先 `_remove_local_panel("EquipmentDetails")`，保留 `BodyEquipmentPanel`／身体栏／其它已局部节。`_place` 父节点为 `layout`。全量 `_body_drawer`→`_body_details` 不在此卸窗（`begin_frame` 已释放），仍在 `_body_details` 末写回键（空装备／空选牌也写）。既有 `_refresh_body_details` 的 `clear(self)` 语义未改。无活 `EquipmentDetails` 且本路径条件已满足时本路径创建，不改走全量。场景断言 `EquipmentDetails`／`CloseEquipmentDetails` 件数＝1。套件绿。

## 表外全量

只让 `["body_details"]` 在 `_selecting_hand()`／关窗／`quick_release_open`／非 battle／`pending_retain` 时走全量。`header`／`body_bar`／`relics`／`hand`／`actions`／`posture`／`resources`／`show_log` 的全量条件未改。局部 `["body_details"]` 因而从不在选牌态／关窗／快捷挣脱／非战斗／保留手牌分支建详情，从不顺手 `body_sidebar`。

## 检查

在 `spire-godot/`：

```
$env:GODOT_BIN='C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'
& tools/check.ps1 -UIOnly -UISuite display -TimeoutSeconds 900
```

通过（本会话实测）：

- 退出码 0
- `SUITE RESULT: display PASS`
- `UI PASS: 629 assertions`（`check-ui.log`：UI SUITE display 629 assertions, 71.50s）
- `summary.json` `status=passed`，`before`＝`after`＝`0CFDC67557269E5DB039984CC7E3D2D1A0B282F7FDCC3934949AE53A7E384CE5`
- 日志：`spire-godot/build/checks/20260925T181007388-10416/`

`present_routes_body_bar_or_full`／`present_routes_header_or_full`／`present_routes_relics_or_full`／`present_routes_hand_or_full`／`present_routes_actions_or_full`／`present_routes_posture_or_full`／`present_routes_resources_or_full`／`present_routes_show_log_or_full`／`sidebar_refresh` 同套件未红。未提交 `*.import`／`.uid`。

未跑：规则套件、其它 UI 套件、打包、加固变异、验收（本刀 UI 验收 none）、双审。未停工交回。无 `needs-human-review`。

---

# 实现者报告：present(dirty) 第八刀 show_log

域：`ui/main.gd` M3 展示调度（`present` 加 `["show_log"]` 局部）与 `_log_drawer` 共享键＋早退＋不叠窗。非清洁／非加固。

起步 HEAD：`6a71539`（规划者第八刀契约）。分支 `worker/partition-delta`。未 push。未碰其它工作树或 `C:\1\magic-spire` 主树。本报告提交前源码 HEAD：`43e51ec`。无 `needs-human-review`。未停工交回。

## 改动文件

- `spire-godot/ui/main.gd`（3363 行）：`present(["show_log"])` 有独立分支，只调 `_refresh_log_section`（薄包：键命中早退；未命中 `_ensure_log_layer` 后卸 `DismissDrawer`／`InformationDrawer`，`building_drawer=true` 再 `_log_drawer`），**不**落入 `else` 的 `layout.body_sidebar`。`["header"]`／`["body_bar"]`／`["relics"]`／`["hand"]`／`["actions"]`／`["posture"]`／`["resources"]` 仍局部。未知／`["*"]`／其它已声明名仍全量 `render(view)`，禁止再 `get_view`。`_log_presentation_key` 与 `_log_key` 紧挨 `_log_drawer`；薄函数与 `_log_drawer` 共用该键，无第二套。键字段＝`action_log` 各条 `actor`／`round`／`text`（空数组也进键）、`logs` 按现行切片（`size()-1` 降到 `maxi(-1,size()-45)`）各条 `kind`／`text`。`version`／`show_log`／`show_home`／其它 `DRAWERS`／`travel_log`／locale／`LogDetails` 展开态不进键。`_present_needs_full_render`：**仅** `["show_log"]` 且 `not show_log` 或 `show_home` → 全量；`present` 对 snapshot 的 `next` 同检（标志在 UI 实例上）。不得把这些扩到 header／body_bar／relics／hand／actions／posture／resources。`PRESENT_ADJACENCY` 与源同步（`present` 增 `_refresh_log_section`，其读本文件键函数并调 `_log_drawer`；`present` 直调不含 `_refresh_drawers`／`_open_drawer`／`_close_drawers`／`_drawer_shell`）。签名仍是 `present(dirty: Array=["*"], snapshot: Dictionary={})`。未改 `_submit`。局部路径未调 `_refresh_drawers`／`_open_drawer`／`_close_drawers`／其它 `_*_drawer`／`_bottom_controls`／`_refresh_resource_section`／`_wall_controls`／`_posture_controls`／`_refresh_posture_section`／`_fixed_actions`／`_build_action_rail`／`_header`／`header.configure`／`_relic_row`／`layout.body_sidebar`／`_hand`／`_body_details`／`begin_frame`、未清空 `layout.used`、未直调 `_drawer_shell`。未改 `header.tscn`／`header.gd`／`game_layout.gd`／`_drawer_shell` 公共几何／`header._presentation_key`／`body_sidebar._presentation_key`／`_relic_presentation_key`／`_hand_presentation_key`／`_action_presentation_key`／`_posture_presentation_key`／`_resource_presentation_key`。无新 UI 文件。无 core／data。无 `docs/spec`。主页／关闭态日志本刀不局部。
- `spire-godot/tests/display_ui_cases.gd`（1399 行）：`present_routes_show_log_or_full` 已在 `run` 里接在 `present_routes_resources_or_full` 之后。`present_routes_header_or_full`／`present_routes_relics_or_full`／`present_routes_hand_or_full`／`present_routes_actions_or_full`／`present_routes_posture_or_full`／`present_routes_resources_or_full` 的「已声明非局部」步由 `["show_log"]` 改为 `["body_details"]`。测试侧 `GetViewCountingGame`。生产无计数器。
- `spire-godot/build/implementer-report.md`（本文件，`git add -f`；保留后文既有结论）

Godot 无 Size and ESM。`main.gd` 本就超长；本刀只加薄路由与日志节早退，未拆文件。

检查点：
- `c499f65` `checkpoint(implementer): add present show_log routing`
- `43e51ec` `checkpoint(implementer): add present_routes_show_log_or_full`

## 叠窗

不叠。键命中早退只在卸栏／建模之前一次（`_refresh_log_section`，**不**写进 `_log_drawer` 本体），且要求树上活 `InformationLayer` 件数＝1，该层上 `InformationDrawer`／`DismissDrawer`／`LogBackToMenu`／`LogDetails`／`LogDetailRows` 各 1。禁止只凭缓存键、层已被 `begin_frame` 释放仍早退。键未命中先卸该层上 `DismissDrawer`／`InformationDrawer`（含子树），保留 `InformationLayer` 实例；`building_drawer=true` 时壳父节点＝`drawer_layer`。禁止只卸 `InformationDrawer`。无活层且 `show_log` 且非 `show_home` 时按现行口径建 `InformationLayer` 再 `_log_drawer`，不改走 `_refresh_drawers`。全量 `_refresh_drawers`→`_log_drawer` 不在此卸栏，仍在 `_log_drawer` 末写回键。场景断言层／窗／返回菜单件数＝1。套件绿。

## 表外全量

只让 `["show_log"]` 在 `not show_log` 或 `show_home` 时走全量。`header`／`body_bar`／`relics`／`hand`／`actions`／`posture`／`resources` 的全量条件未改。局部 `["show_log"]` 因而从不在抽屉关闭时建日志窗、从不在主页建日志窗、从不重建菜单／牌堆／其它抽屉。

## 检查

在 `spire-godot/`：

```
$env:GODOT_BIN='C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'
& tools/check.ps1 -UIOnly -UISuite display -TimeoutSeconds 900
```

通过（本会话实测）：

- 退出码 0
- `SUITE RESULT: display PASS`
- `UI PASS: 573 assertions`（`check-ui.log`：UI SUITE display 573 assertions, 63.45s）
- `summary.json` `status=passed`，`before`＝`after`＝`2CD2726EE6BE2B194A3344CDB522F5D0C59CA5D0FFF33DFB2BD421A0A9D057CC`
- 日志：`spire-godot/build/checks/20260925T175010661-10804/`

`present_routes_body_bar_or_full`／`present_routes_header_or_full`／`present_routes_relics_or_full`／`present_routes_hand_or_full`／`present_routes_actions_or_full`／`present_routes_posture_or_full`／`present_routes_resources_or_full`／`sidebar_refresh` 同套件未红。未提交 `*.import`／`.uid`。

未跑：规则套件、其它 UI 套件、打包、加固变异、验收（本刀 UI 验收 none）、双审。未停工交回。无 `needs-human-review`。

---

# 实现者报告：present(dirty) 第七刀 resources

域：`ui/main.gd` M3 展示调度（`present` 加 `["resources"]` 局部）与 `_bottom_controls` 在墙／姿之前的资源／能量／牌堆／flow／surrender／魔瓶段共享键＋早退＋不叠栏。非清洁／非加固。

起步 HEAD：`81c45bc`（规划者第七刀契约）。分支 `worker/partition-delta`。未 push。未碰其它工作树或 `C:\1\magic-spire` 主树。本报告提交前源码 HEAD：`ec698ae`。

## 改动文件

- `spire-godot/ui/main.gd`（3285 行）：`present(["resources"])` 有独立分支，只调 `_refresh_resource_section`（卸栏后 `_build_resource_bar(true)`），**不**落入 `else` 的 `layout.body_sidebar`。`["header"]`／`["body_bar"]`／`["relics"]`／`["hand"]`／`["actions"]`／`["posture"]` 仍局部。未知／`["*"]`／其它已声明名仍全量 `render(view)`，禁止再 `get_view`。`_resource_presentation_key` 与 `_resource_key` 紧挨 `_bottom_controls`；`_build_resource_bar` 与薄函数共用该键，无第二套。键字段＝`energy`／`mana`／`temporary_mana`／`mana_max`、`pressure.value`／`.maximum`、`guard_bind.is_empty` 布尔（有捕缚时另含 `value`／`maximum`／`detail`）、`powers.size()`、`draw_count`／`discard_count`、`phase`、本地 `surrender_version`。`version`／`show_route`／`mana_flask.*`／`casting.percent`／`energy_max`／`end_turn_locked`／flow／surrender 候选细字段／locale／`Hero*`／`include_tools` 不进键。`_present_needs_full_render`：**仅** `["resources"]` 且 `next.phase!="battle"` 或 `show_route` → 全量；`present` 对 snapshot 的 `next` 同检。不得把这些扩到 header／body_bar／relics／hand／actions／posture。`PRESENT_ADJACENCY` 与源同步（`present` 增 `_refresh_resource_section`，其读本文件键函数并调 `_build_resource_bar`；`present` 直调不含 `_wall_controls`／`_posture_controls`／`mana_flask.build`／完整 `_bottom_controls`）。签名仍是 `present(dirty: Array=["*"], snapshot: Dictionary={})`。未改 `_submit`。局部路径未调 `_bottom_controls`／`_wall_controls`／`_posture_controls`／`_refresh_posture_section`／`mana_flask.build`／`_fixed_actions`／`_build_action_rail`／`_rest_controls`／`_prison_controls`／`_header`／`header.configure`／`_relic_row`／`layout.body_sidebar`／`_hand`／`begin_frame`、未清空 `layout.used`。未改 `header.tscn`／`header.gd`／`game_layout.gd`／`mana_flask.gd`／`target_queries.gd`／`header._presentation_key`／`body_sidebar._presentation_key`／`_relic_presentation_key`／`_hand_presentation_key`／`_action_presentation_key`／`_posture_presentation_key`。无新 UI 文件。无 core／data。无 `docs/spec`。prepare／rest／prison／shop 底栏本刀不局部。
- `spire-godot/tests/display_ui_cases.gd`（1291 行）：`present_routes_resources_or_full` 已在 `run` 里接在 `present_routes_posture_or_full` 之后。`present_routes_header_or_full`／`present_routes_relics_or_full`／`present_routes_hand_or_full`／`present_routes_actions_or_full`／`present_routes_posture_or_full` 的「已声明非局部」步由 `["resources"]` 改为 `["show_log"]`。测试侧 `GetViewCountingGame`。生产无计数器。
- `spire-godot/build/implementer-report.md`（本文件，`git add -f`；保留后文既有结论）

Godot 无 Size and ESM。`main.gd` 本就超长；本刀只加薄路由与资源节早退，未拆文件。

检查点：
- `0e042d6` `checkpoint(implementer): add present resources routing`
- `ec698ae` `checkpoint(implementer): add present_routes_resources_or_full`

## 叠栏

不叠。键命中早退只在卸栏／建模之前一次，且要求树上 `MainResourcePanel`／`ResourceToolsPanel`／`EnergyMedallion`／`EnergyValue`／`DrawPileButton`／`DiscardPileButton`／`OpenPowers` 件数＝1；`EndTurnButton` 有则 1 且 `end_button` 仍指向该实例；有则 `SurrenderButton`／`ManaFlask`／`MainGuardBind`／`SidebarGuardBindTarget` 件数不超过 1；本节写入的 flow `candidate_buttons` 仍指向这些实例。禁止只凭缓存键、钮已被 `begin_frame` 释放仍早退。键未命中先卸 layout 上本节全部直子（`MainResourcePanel`／`ResourceToolsPanel`／`ManaFlask`／`EnergyMedallion`／`OpenPowers`／牌堆钮／`EndTurnButton`／`SurrenderButton`／计量／捕缚目标／`ResourceTurnDivider`／`FlowButton_*`），`end_button` 在 `EndTurnButton` 被卸后置空。然后按现行战斗＋非 `show_route`＋`include_tools=true` 建模，不调墙／姿。禁止只卸 `MainResourcePanel`。全量 `_bottom_controls` 不在此卸栏，仍在墙／姿之前写回键。无活 `MainResourcePanel` 时本路径创建，不改走全量。场景断言 `MainResourcePanel`／`EnergyMedallion`／`EndTurnButton` 件数＝1。套件绿。

## 表外全量

只让 `["resources"]` 在 `phase!="battle"` 或 `show_route` 时走全量。`header`／`body_bar`／`relics`／`hand`／`actions`／`posture` 的全量条件未改。局部 `["resources"]` 因而从不走商店关栏口径、从不在地图 overlay 上建底栏、prepare／rest／prison 底栏本刀不局部。

## 检查

在 `spire-godot/`：

```
$env:GODOT_BIN='C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'
& tools/check.ps1 -UIOnly -UISuite display -TimeoutSeconds 900
```

通过（本会话实测）：

- 退出码 0
- `SUITE RESULT: display PASS`
- `UI PASS: 517 assertions`（`check-ui.log`：UI SUITE display 517 assertions, 51963 ms）
- `summary.json` `status=passed`，`before`＝`after`＝`F6263394B346384E486C02E86069B7F71CF150470CDD63A021DFBF40834554DD`
- 日志：`spire-godot/build/checks/20260925T173252793-17128/`

`present_routes_body_bar_or_full`／`present_routes_header_or_full`／`present_routes_relics_or_full`／`present_routes_hand_or_full`／`present_routes_actions_or_full`／`present_routes_posture_or_full`／`sidebar_refresh` 同套件未红。未提交 `*.import`／`.uid`。

未跑：规则套件、其它 UI 套件、打包、加固变异、验收（本刀 UI 验收 none）。未停工交回。无 `needs-human-review`。

---

# 实现者报告：present(dirty) 第六刀 posture

域：`ui/main.gd` M3 展示调度（`present` 加 `["posture"]` 局部）与 `_wall_controls`／`_posture_controls` 共享键＋早退＋不叠栏。非清洁／非加固。

起步 HEAD：`2a6f192`（规划者第六刀契约）。分支 `worker/partition-delta`。未 push。未碰其它工作树或 `C:\1\magic-spire` 主树。本报告提交前源码 HEAD：`a829daf`。

## 改动文件

- `spire-godot/ui/main.gd`（3202 行）：`present(["posture"])` 局部只调 `_refresh_posture_section`（先 `_wall_controls` 再 `_posture_controls`）；`["header"]`／`["body_bar"]`／`["relics"]`／`["hand"]`／`["actions"]` 仍局部。未知／`["*"]`／其它已声明名仍全量 `render(view)`，禁止再 `get_view`。`_posture_presentation_key` 与 `_posture_key` 紧挨 `_posture_controls`；`_wall_controls` 共用该键，无第二套。键字段＝`view.posture`／`guard_bind.is_empty` 布尔、posture 且 `payload.adjacent` 的子集、wall_move 且 `direction=="toward"` 的子集；每条用 `TargetQueries.fact_key`＋`valid`／`reason`／`cost`，姿态条另含 `adjacent`／`wall`，toward 条另含 `distance`。`phase`／`show_route`／`label`／`detail`／`payload.after`／away／非 adjacent 姿态事实／`flow`／`surrender`／能量／抽弃牌／locale／`version` 不进键。`_present_needs_full_render`：**仅** `["posture"]` 且 `next.phase!="battle"` 或 `show_route` → 全量；`present` 对 snapshot 的 `next` 同检。不得把这些扩到 header／body_bar／relics／hand／actions。`PRESENT_ADJACENCY` 与源同步（`present` 增 `_refresh_posture_section`，其调 `_wall_controls`／`_posture_controls`，后二者读本文件键函数）。签名仍是 `present(dirty: Array=["*"], snapshot: Dictionary={})`。未改 `_submit`。局部路径未调 `_bottom_controls`／`_fixed_actions`／`_build_action_rail`／`_hand`／`_header`／`header.configure`／`_relic_row`／`layout.body_sidebar`／`begin_frame`、未清空 `layout.used`。未改 `header.tscn`／`header.gd`／`game_layout.gd`／`target_queries.gd`／`body_sidebar._presentation_key`／`_relic_presentation_key`／`_hand_presentation_key`／`_action_presentation_key`。无新 UI 文件。无 core／data。无 `docs/spec`。prepare／rest／prison 姿态本刀不局部。
- `spire-godot/tests/display_ui_cases.gd`（1184 行）：`present_routes_posture_or_full` 已在 `run` 里接在 `present_routes_actions_or_full` 之后。`present_routes_header_or_full`／`present_routes_relics_or_full`／`present_routes_hand_or_full`／`present_routes_actions_or_full` 的「已声明非局部」步由 `["posture"]` 改为 `["resources"]`。测试侧 `GetViewCountingGame`。生产无计数器。
- `spire-godot/build/implementer-report.md`（本文件，`git add -f`；保留后文既有结论）

Godot 无 Size and ESM。`main.gd` 本就超长；本刀只加薄路由与姿态节早退，未拆文件。

检查点：
- `7e34835` `checkpoint(implementer): add posture presentation key`
- `a214ac8` `checkpoint(implementer): add present posture routing`
- `b8e37cc` `checkpoint(implementer): add present_routes_posture_or_full`
- `a829daf` `checkpoint(implementer): register present_routes_posture_or_full`

## 叠栏

不叠。键命中早退只在 `_refresh_posture_section` 二者之前一次，且要求树上 `PostureChoices` 件数＝相邻非空时 1 否则 0、`WallMove_toward` 件数＝toward 非空时 1 否则 0、同名 `Posture_*` 仍在、`candidate_buttons` 仍指向这些实例。禁止只凭缓存键、钮已被 `begin_frame` 释放仍早退。键未命中先卸 `PostureChoices` 与 `WallMove_toward`（墙钮是 layout 直子，另清其 `candidate_buttons`），再 `_wall_controls`→`_posture_controls`。`_wall_controls`／`_posture_controls` 各自不 miss 卸二者。写键只在 `_posture_controls` 跑完之后（空相邻也写）。全量 `_bottom_controls` 不在此卸栏，仍写回键。无活栏且相邻／toward 非空时本路径创建，不改走全量。场景断言 `PostureChoices`／`Posture_sit` 件数＝1。套件绿。

## 表外全量

只让 `["posture"]` 在 `phase!="battle"` 或 `show_route` 时走全量。`header`／`body_bar`／`relics`／`hand`／`actions` 的全量条件未改。局部 `["posture"]` 因而从不走探索／休息／监狱栏、从不在地图 overlay 上建姿／墙钮。

## 检查

在 `spire-godot/`：

```
$env:GODOT_BIN='C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'
& tools/check.ps1 -UIOnly -UISuite display -TimeoutSeconds 900
```

通过（本会话实测）：

- 退出码 0
- `SUITE RESULT: display PASS`
- `UI PASS: 463 assertions`（`check-ui.log`：UI SUITE display 463 assertions, 52793 ms）
- `summary.json` `status=passed`，`before`＝`after`＝`C9C5DD12F84C2831237DFAB9A5676EAD49B731C15E595D97E4DB73AEB03681A8`
- 日志：`spire-godot/build/checks/20260925T171500158-1008/`

`present_routes_body_bar_or_full`／`present_routes_header_or_full`／`present_routes_relics_or_full`／`present_routes_hand_or_full`／`present_routes_actions_or_full`／`sidebar_refresh` 同套件未红。未提交 `*.import`／`.uid`。

未跑：规则套件、其它 UI 套件、打包、加固变异、验收（本刀 UI 验收 none）。未停工交回。无 `needs-human-review`。

---

# 实现者报告：present(dirty) 第五刀 actions

域：`ui/main.gd` M3 展示调度（`present` 加 `["actions"]` 局部）与 `_build_action_rail` 键＋早退＋不叠栏。非清洁／非加固。

起步 HEAD：`06045f8`（规划者第五刀契约）。分支 `worker/partition-delta`。未 push。未碰其它工作树或 `C:\1\magic-spire` 主树。本报告提交前源码 HEAD：`4e496c1`。

## 改动文件

- `spire-godot/ui/main.gd`（3135 行）：`present(["actions"])` 局部只调 `_build_action_rail`；`["header"]`／`["body_bar"]`／`["relics"]`／`["hand"]` 仍局部。未知／`["*"]`／其它已声明名仍全量 `render(view)`，禁止再 `get_view`。`_action_presentation_key` 与 `_action_key` 紧挨 `_build_action_rail`。键字段＝`phase`／`selected_enemy`／`attack_forms` 副本／`quick_release_open`、attack 且 `payload.kind=="attack"` 且 `payload.enemy==selected_enemy` 的子集、pressure 且 `payload.kind=="calm"` 的子集；每条用 `TargetQueries.fact_key`＋`valid`／`reason`／`cost`／`label`／`body_part`／`casting`／`brief`／`risk`。`version`／`flow`／`surrender`／`character_id`／`equipment_fireball_unlocked`／`brief_tags`／`mana`／`detail`／`payload.type|form|witch_action`／locale 不进键。`_present_needs_full_render`：**仅** `["actions"]` 且非 battle／`quick_release_open`／`_selecting_hand()`／`card_chain` 非空／`reward_panel.active` → 全量；`present` 对 snapshot 的 `next` 同检。不得把这些扩到 header／body_bar／relics／hand。`PRESENT_ADJACENCY` 与源同步（`present` 增 `_build_action_rail`，`_build_action_rail` 读本文件键函数）。签名仍是 `present(dirty: Array=["*"], snapshot: Dictionary={})`。未改 `_submit`。局部路径未调 `_fixed_actions`／`quick_release_bar.build`／`toggle`／`_rest_controls`／`_prison_controls`／`_header`／`header.configure`／`_relic_row`／`layout.body_sidebar`／`_hand`／`begin_frame`、未清空 `layout.used`。未改 `header.tscn`／`header.gd`／`game_layout.gd`／`quick_release_bar.gd`／`target_queries.gd`／`body_sidebar._presentation_key`／`_relic_presentation_key`／`_hand_presentation_key`。无新 UI 文件。无 core／data。无 `docs/spec`。
- `spire-godot/tests/display_ui_cases.gd`（1080 行）：`present_routes_actions_or_full` 已在 `run` 里接在 `present_routes_hand_or_full` 之后。`present_routes_header_or_full`／`present_routes_relics_or_full`／`present_routes_hand_or_full` 的「已声明非局部」步由 `["actions"]` 改为 `["posture"]`。测试侧 `GetViewCountingGame`。生产无计数器。
- `spire-godot/build/implementer-report.md`（本文件，`git add -f`；保留后文既有结论）

Godot 无 Size and ESM。`main.gd` 本就超长；本刀只加薄路由与 `_build_action_rail` 早退，未拆文件。

检查点：
- `c3e8f37` `checkpoint(implementer): add action presentation key`
- `70fc828` `checkpoint(implementer): add present actions routing`
- `6824a5b` `checkpoint(implementer): add present_routes_actions_or_full`
- `4e496c1` `checkpoint(implementer): register present_routes_actions_or_full`

## 叠栏

不叠。键命中早退且要求树上 `AttackActions` 件数＝1；键未命中先 `_remove_local_panel("AttackActions")` 再按现行战斗＋非快捷挣脱逻辑建模。全量 `_fixed_actions`→`_build_action_rail` 仍写回键（`begin_frame` 释放后即使键相同也重建）。无活栏且本刀局部条件成立时本函数创建栏，不改走全量。场景断言 `AttackActions`／`DeepBreath`／`ActionRailToggle` 件数＝1。套件绿。

## 表外全量

只让 `["actions"]` 在非 battle／快捷挣脱开／选牌／`card_chain` 非空／奖励面板 active 时走全量。`header`／`body_bar`／`relics`／`hand` 的全量条件未改。局部 `["actions"]` 因上述条件已改道全量，不走快捷挣脱栏、不建探索火球空钮、不顺手 page 控件。

## 检查

在 `spire-godot/`：

```
$env:GODOT_BIN='C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'
& tools/check.ps1 -UIOnly -UISuite display -TimeoutSeconds 900
```

通过（本会话实测）：

- 退出码 0
- `SUITE RESULT: display PASS`
- `UI PASS: 418 assertions`（`check-ui.log`：UI SUITE display 418 assertions, 63.25s）
- `summary.json` `status=passed`，`before`＝`after`＝`C0A343E7ABE447FD376B2D238F59CE22E7CAD17A0C0BD2178C51FE9E345861BF`
- 日志：`spire-godot/build/checks/20260925T165700025-28696/`

先有一轮 import 因工作树缺 `.fontdata` 失败（`20260925T165545911-34176`，`status=failed`，display 未跑）。补齐导入缓存后重跑上列命令通过。未提交 `*.import`／`.uid`。

`present_routes_body_bar_or_full`／`present_routes_header_or_full`／`present_routes_relics_or_full`／`present_routes_hand_or_full`／`sidebar_refresh` 同套件未红。

未跑：规则套件、其它 UI 套件、打包、加固变异、验收（本刀 UI 验收 none）。未停工交回。无 `needs-human-review`。

---

# 实现者报告：present(dirty) 第四刀 hand

域：`ui/main.gd` M3 展示调度（`present` 加 `["hand"]` 局部）与 `_hand` 键＋早退＋不叠牌。非清洁／非加固。

起步 HEAD：`5a74a21`（规划者 report）。分支 `worker/partition-delta`。未 push。未碰其它工作树或 `C:\1\magic-spire` 主树。本报告提交前源码 HEAD：`7488672`。

## 改动文件

- `spire-godot/ui/main.gd`（3099 行）：`present(["hand"])` 局部只调 `_hand`；`["header"]`／`["body_bar"]`／`["relics"]` 仍局部。未知／`["*"]`／其它已声明名仍全量 `render(view)`，禁止再 `get_view`。`_hand_presentation_key` 与 `_hand_key` 紧挨 `_hand`。键字段＝每张 uid／type／draw_serial／draw_free／single_face／availability(free／bound 的 usable／dim／text)／合并 card_texts 与 card_instances 后 `_card`／`_refresh_card_face` 已读的 face_* 及对应条目显示字段、当前手牌 uid 的 `card_faces`、`selected_card`、`_selecting_hand()` 布尔、`card_motion.pending_draws` uid 集合。`version`／`display_facts`／`climax`／`pressure.overloaded`／locale 不进键。`_present_needs_full_render`：**仅** `["hand"]` 且 `view.pressure.overloaded` → 全量；不得把 overloaded 扩到 header／body_bar／relics。`PRESENT_ADJACENCY` 与源同步（`present` 增 `_hand`，`_hand` 读本文件键函数）。签名仍是 `present(dirty: Array=["*"], snapshot: Dictionary={})`。未改 `_submit`。局部路径未调 `_header`／`header.configure`／`_relic_row`／`layout.body_sidebar`／`begin_frame`、未清空 `layout.used`。未改 `header.tscn`／`header.gd`／`game_layout.gd`／`card_face.gd`／`card_motion.gd`／`body_sidebar._presentation_key`／`_relic_presentation_key`。无新 UI 文件。无 core／data。无 `docs/spec`。
- `spire-godot/tests/display_ui_cases.gd`（991 行）：`present_routes_hand_or_full` 已在 `run` 里接在 `present_routes_relics_or_full` 之后。`present_routes_header_or_full` 与 `present_routes_relics_or_full` 的「已声明非局部」步由 `["hand"]` 改为 `["actions"]`。测试侧 `GetViewCountingGame`。生产无计数器。
- `spire-godot/build/implementer-report.md`（本文件，`git add -f`；保留后文既有结论）

Godot 无 Size and ESM。`main.gd` 本就超长；本刀只加薄路由与 `_hand` 早退，未拆文件。

检查点：
- `8df029a` `checkpoint(implementer): add hand presentation key`
- `3b65276` `checkpoint(implementer): add present hand routing`
- `e024d79` `checkpoint(implementer): add present_routes_hand_or_full`
- `7488672` `checkpoint(implementer): register present_routes_hand_or_full`

## 叠牌

不叠。键命中早退且要求该 uid 按钮仍在树上、件数＝1、`card_buttons` 键数＝手牌张数；键未命中先卸手牌按钮／空牌标签／误留 `ClimaxNarration` 再按非高潮逻辑建模。空 `view.hand` 卸已有按钮并至多保留 1 个 `EmptyHand`。全量 `_battle_scene`→`_hand` 仍写回键（`begin_frame` 释放后即使键相同也重建）。活按钮名为 `HandCard_<uid>`。场景断言每 uid 件数＝1。套件绿。

## overloaded

只让 `["hand"]` 走全量。`header`／`body_bar`／`relics` 的全量条件未改；局部 `["hand"]` 因 overloaded 已改道全量而不走 `_climax_narration`。

## 检查

在 `spire-godot/`：

```
$env:GODOT_BIN='C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'
& tools/check.ps1 -UIOnly -UISuite display -TimeoutSeconds 900
```

通过（本会话实测）：

- 退出码 0
- `SUITE RESULT: display PASS`
- `UI PASS: 378 assertions`（`check-ui.log`：UI SUITE display 378 assertions, 49319 ms）
- `summary.json` `status=passed`，`before`＝`after`＝`E617CD6CBD5FE8E5C7620C6C7F8EB7E181B56622D74836E94C93A2686B1C01FB`
- 日志：`spire-godot/build/checks/20260925T130728951-40492/`

`present_routes_body_bar_or_full`／`present_routes_header_or_full`／`present_routes_relics_or_full`／`sidebar_refresh` 同套件未红。未提交 `*.import`／`.uid`。

未跑：规则套件、其它 UI 套件、打包、加固变异、验收（本刀 UI 验收 none）。

---

# 实现者报告：闭合 relics sibling 顺序 P1（bunny）

域：`ui/main.gd::_relic_row` 重建后 `move_child` 恢复原 sibling 位；`tests/display_ui_cases.gd::present_routes_relics_or_full` 的 `RouteMapColumn` 夹具含 `TowerMapScroll`。非清洁／非加固。未改 `_place` 全局语义、`_submit`、`header.gd`／`game_layout.gd`／`relic_icon.gd`。无新 UI 文件。未写 `docs/spec`。

起步 HEAD：`8916dac`。分支 `worker/partition-delta`。未 push。未碰其它工作树或 `C:\1\magic-spire` 主树。本报告提交前源码 HEAD：`c0d9396`。

## 改动文件

- `spire-godot/ui/main.gd`（3018 行）：`_relic_row` 释放前记下首个有效 `RelicStrip` 的 `get_index()`；`_place` 挂回原 host 后 `host.move_child(strip, host_index)`，使条仍在 `TowerMapScroll` 之上。`_place` 仍只 `add_child`＋写 rect，语义未改。
- `spire-godot/tests/display_ui_cases.gd`（908 行）：`RouteMapColumn` 夹具先有条、后加名为 `TowerMapScroll` 的 sibling；键未命中重建后断言条 `get_index()==0` 且 `TowerMapScroll` 仍是下一 sibling。空 VBox 不再算过。
- `spire-godot/build/implementer-report.md`（本文件，`git add -f`；保留后文既有结论）

Godot 无 Size and ESM。`main.gd` 本就超长；本修复只加 index 记录与 `move_child`，未拆文件。

检查点：
- `5905982` `checkpoint(implementer): restore RelicStrip sibling index after host rebuild`
- `c0d9396` `checkpoint(implementer): assert RouteMapColumn RelicStrip stays above TowerMapScroll`

## 顺序怎么恢复

键未命中时先记下首个有效条的 `get_index()`，再 `remove_child`＋`queue_free`。新条 `_place` 到已保存 host 后立刻 `host.move_child(strip, host_index)`。真实 `RouteMapColumn` 先 reparent 条再 `add_child(TowerMapScroll)`；重建后条仍在 index 0。

## 检查

在 `spire-godot/`：

```
$env:GODOT_BIN='C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'
& tools/check.ps1 -UIOnly -UISuite display -TimeoutSeconds 900
```

通过（本会话实测）：

- 退出码 0
- `SUITE RESULT: display PASS`
- `UI PASS: 345 assertions`（`check-ui.log`：UI SUITE display 345 assertions, 46914 ms）
- `summary.json` `status=passed`，`before`＝`after`＝`541B167B9C87FC5BEC454376EDD108B8DE0623FA23981441811A506C2E029A05`
- 日志：`spire-godot/build/checks/20260925T115456474-34716/`

`present_routes_body_bar_or_full`／`present_routes_header_or_full`／`sidebar_refresh` 同套件未红。未提交 `*.import`／`.uid`。

未跑：规则套件、其它 UI 套件、打包、加固变异、验收（本刀 UI 验收 none）。

---

# 实现者报告：闭合 relics 审查 FAIL（bunny P1/P2）

域：`ui/main.gd::_relic_row` 重建宿主与 0-or-1 早退；`tests/display_ui_cases.gd::present_routes_relics_or_full` 的 `body_bar` 条带断言。非清洁／非加固。未改 `_submit`／`PRESENT_SECTIONS`／`present(dirty: Array=…)` 签名／header／layout／relic_icon／`body_sidebar._presentation_key`。无新 UI 文件。未写 `docs/spec`。

起步 HEAD：`6afce9a`（清洁者）。分支 `worker/partition-delta`。未 push。未碰其它工作树或 `C:\1\magic-spire` 主树。本报告提交前源码 HEAD：`70d299c`。

## 改动文件

- `spire-godot/ui/main.gd`（3015 行）：P1 键未命中重建时记下原 `RelicStrip` 父容器与 position／size／`custom_minimum_size`／size_flags，新条挂回该宿主，不默认 `_place` 到 layout `(405,78,1013,56)`。P2 早退仅当键命中且条数＝0（空 `view.relics`）或 1（非空）；多条清再建，空视图有条则卸载。
- `spire-godot/tests/display_ui_cases.gd`（903 行）：`present(["body_bar"])` 步断言 `RelicStrip` 实例＝`strip_after_mutation` 且件数＝1。同场景钉：异父双条折叠为 1；地图宿主重建保留 parent／position／size_flags；空视图 leftover 卸载。
- `spire-godot/build/implementer-report.md`（本文件，`git add -f`；保留后文第三刀结论）

Godot 无 Size and ESM。`main.gd` 本就超长；本修复只改 `_relic_row` 早退与挂载，未拆文件。

检查点：
- `70d299c` `checkpoint(implementer): preserve RelicStrip host and 0-or-1 early-exit`

## 检查

在 `spire-godot/`：

```
$env:GODOT_BIN='C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'
& tools/check.ps1 -UIOnly -UISuite display -TimeoutSeconds 900
```

通过（本会话实测）：

- 退出码 0
- `SUITE RESULT: display PASS`
- `UI PASS: 342 assertions`（`check-ui.log`：UI SUITE display 342 assertions, 123800 ms）
- `summary.json` `status=passed`，`before`＝`after`＝`CE7DA483E38C11E086C1A0EB9315884800E451F825B866B9CF66C53CE99A21B7`
- 日志：`spire-godot/build/checks/20260925T113346952-20352/`

`present_routes_body_bar_or_full`／`present_routes_header_or_full`／`sidebar_refresh` 同套件未红。未提交 `*.import`／`.uid`。

未跑：规则套件、其它 UI 套件、打包、加固变异、验收（本刀 UI 验收 none）。

---

# 实现者报告：present(dirty) 第三刀 relics

域：`ui/main.gd` M3 展示调度（`present` 加 `["relics"]` 局部）与 `_relic_row` 键＋早退＋不叠条。非清洁／非加固。

起步 HEAD：`3525cc0`（规划者 report）。分支 `worker/partition-delta`。未 push。未碰其它工作树或 `C:\1\magic-spire` 主树。本报告提交前源码 HEAD：`b6a02d2`。

## 改动文件

- `spire-godot/ui/main.gd`（2998 行）：`present(["relics"])` 局部只调 `_relic_row`；`["header"]`／`["body_bar"]` 仍局部。未知／`["*"]`／其它已声明名仍全量 `render(view)`，禁止再 `get_view`。`_relic_presentation_key` 与 `_relic_key` 紧挨 `_relic_row`；键字段为每件 `id`／`name`／`detail`／`counter`／`current`／`rarity` 与 locale；`version`／discharge／toggle 不进键。`PRESENT_ADJACENCY` 与源同步（`present` 增 `_relic_row`，`_relic_row` 读本文件键函数）。签名仍为 `present(dirty: Array=["*"], snapshot: Dictionary={})`。未改 `_submit`。局部路径未调 `_header`／`header.configure`／`layout.body_sidebar`／`begin_frame`、未清空 `layout.used`。未改 `header.tscn`／`header.gd`／`game_layout.gd`／`relic_icon.gd`／`body_sidebar._presentation_key`。无新 UI 文件。无 core／data。
- `spire-godot/tests/display_ui_cases.gd`（875 行）：`present_routes_relics_or_full` 已在 `run` 里接在 `present_routes_header_or_full` 之后。`present_routes_header_or_full` 步⑥ `present(["relics"])` 改为 `["hand"]`。测试侧 `GetViewCountingGame`。生产无计数器。
- `spire-godot/build/implementer-report.md`（本文件，`git add -f`；保留后文既有结论）

Godot 无 Size and ESM。`main.gd` 本就超长；本刀只加薄路由与 `_relic_row` 早退，未拆文件。

检查点：
- `3d5f259` `checkpoint(implementer): add relic presentation key`
- `26bebdd` `checkpoint(implementer): add present relics routing`
- `fbb749c` `checkpoint(implementer): add present_routes_relics_or_full`
- `b6a02d2` `checkpoint(implementer): register present_routes_relics_or_full`

## 叠条

不叠。键命中早退，保留 `RelicStrip` 与已有 `RelicShortcut_*` 实例；键未命中先 `remove_child`＋`queue_free` 再建模。空 `view.relics` 卸已有条。全量 `_header`→`_relic_row` 仍写回键（条被 `begin_frame` 释放后即使键相同也重建）。场景断言 `RelicStrip` 件数＝0 或 1，同 id `RelicShortcut_*` 件数＝1。套件绿。

## 检查

在 `spire-godot/`：

```
$env:GODOT_BIN='C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'
& tools/check.ps1 -UIOnly -UISuite display -TimeoutSeconds 900
```

通过（本会话实测）：

- 退出码 0
- `SUITE RESULT: display PASS`
- `UI PASS: 331 assertions`（`check-ui.log`：UI SUITE display 331 assertions, 46868 ms）
- `summary.json` `status=passed`，`before`＝`after`＝`B749E320F29F2AE56EC7555823E2717FDB7C97DC68AFA750589B95EFE8542A69`
- 日志：`spire-godot/build/checks/20260925T110735975-32232/`

`present_routes_body_bar_or_full`／`present_routes_header_or_full`／`sidebar_refresh` 同套件未红。未提交 `*.import`／`.uid`。

未跑：规则套件、其它 UI 套件、打包、加固变异、验收（本刀 UI 验收 none）。

---

# 实现者报告：present(dirty) 第二刀 header

域：`ui/main.gd` M3 展示调度（`present` 加 `["header"]` 局部）与 `ui/shell/header.gd` 键＋早退＋不叠按钮。非清洁／非加固。

起步 HEAD：`cd3b2e6`（规划者 close）。未 reset 回 `3db554e`。分支 `worker/partition-delta`。未 push。本报告提交前源码 HEAD：`3fd78fa`。

## 改动文件

- `spire-godot/ui/main.gd`（2957 行）：`present` 在已有 `GameHeader` 上调用 `configure`；`_present_needs_full_render` 允许 `header` 与 `body_bar` 局部。签名仍为 `present(dirty: Array=["*"], snapshot: Dictionary={})`。未复制 header 键、未因自算键跳过 `configure`。未改 `_submit`。局部路径未调 `begin_frame`、未清空 `layout.used`、未 instantiate `header.tscn`、未调 `_relic_row`。未改 `header.tscn`／`game_layout.gd`／`body_sidebar._presentation_key`。无新 UI 文件。无 core／data。
- `spire-godot/ui/shell/header.gd`（59 行）：`_presentation_key(ui) -> Array`；保存 `_key`；`configure` 开头比对，命中早退；未命中先清 Button 再建模，重建后写入 `_key`。键字段 ⊆ 节键表 header 行（含 locale；不含 `version`）。
- `spire-godot/tests/display_ui_cases.gd`（793 行）：`present_header_button_count` 用 `header.find_children("*","Button",true,false).size()`＝6；`present_routes_header_or_full` 已在 `run` 里接在 `present_routes_body_bar_or_full` 之后。测试侧 `GetViewCountingGame`。生产无计数器。
- `spire-godot/build/implementer-report.md`（本文件，`git add -f`）

Godot 无 Size and ESM。`main.gd` 本就超长；本刀只加薄路由，未拆文件。

检查点：
- `cfd7522` `checkpoint(implementer): add header presentation key`
- `4274257` `checkpoint(implementer): add present header routing`
- `e2d6f3b` `checkpoint(implementer): add present_routes_header_or_full`
- `3fd78fa` `checkpoint(implementer): register present_routes_header_or_full`

## 叠按钮

不叠。键命中早退，保留 `GameHeader` 与 `OpenTutorial` 实例；键未命中先清再建模。场景断言 `Button` 件数＝6（不靠精确名 `OpenTutorial` 件数，避免 `OpenTutorial2` 漏检）。套件绿。

## 检查

在 `spire-godot/`：

```
$env:GODOT_BIN='C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'
& tools/check.ps1 -UIOnly -UISuite display -TimeoutSeconds 900
```

通过（本会话实测）：

- 退出码 0
- `SUITE RESULT: display PASS`
- `UI PASS: 292 assertions`（`check-ui.log`：UI SUITE 45340 ms）
- `summary.json` `status=passed`，`before`＝`after`＝`FB062692198026992AE5782AAF2C570CD0A195E0B41BD275FF66B374AD0CBE9A`
- 日志：`spire-godot/build/checks/20260925T090403055-23760/`

`present_routes_body_bar_or_full`／`sidebar_refresh` 同套件未红。未提交 `*.import`／`.uid`。

未跑：规则套件、其它 UI 套件、打包、加固变异、验收（本刀 UI 验收 none）。

---

# 实现者报告：恢复 body_bar oracle 断言（bunny P2）

域：`tests/display_ui_cases.gd::present_routes_body_bar_or_full` 的 presentation key 相等断言。非清洁／非加固。未改 header 产品代码、`present` 路由、`PRESENT_ADJACENCY`、`_submit`、`present_routes_header_or_full`。

起步 HEAD：`9019596`（清洁者 adjacency）。分支 `worker/partition-delta`。未 push。未碰其它工作树或 `C:\1\magic-spire` 主树。

## 改动文件

- `spire-godot/tests/display_ui_cases.gd`：把 `present_routes_body_bar_or_full` 里丢弃返回值的裸调用 `ui.layout.body._presentation_key(ui)` 换回 oracle＋相等断言。其它断言未删。`present_routes_header_or_full` 未改。
- `spire-godot/build/implementer-report.md`（本文件，`git add -f`；保留上节 header 结论）

恢复文本：

```
 var oracle=ui.layout.body._presentation_key(ui)
 ui.present(["body_bar"]);await t.frames()
 t.check(ui.layout.body._presentation_key(ui)==oracle,"DISPLAY present body_bar keeps the body presentation key")
```

Godot 无 Size and ESM。未改产品计数文件。

## 检查

在 `spire-godot/`：

```
$env:GODOT_BIN='C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'
& tools/check.ps1 -UIOnly -UISuite display -TimeoutSeconds 900
```

通过（本会话在恢复后的精确 diff 上实测）：

- 退出码 0
- `SUITE RESULT: display PASS`
- `UI PASS: 293 assertions`（`check-ui.log`：UI SUITE display 293 assertions, 45361 ms）
- `summary.json` `status=passed`，`before`＝`after`＝`EC6F9B8872656BB2C933E6A8C3C3B88E243D7E0596C3DAA60F2948A2D5C5FAFE`
- 日志：`spire-godot/build/checks/20260925T092529175-14372/`

`present_routes_header_or_full`／`sidebar_refresh` 同套件未红。未提交 `*.import`／`.uid`。未跑：规则套件、其它 UI 套件、打包、加固变异。
