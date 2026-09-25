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
