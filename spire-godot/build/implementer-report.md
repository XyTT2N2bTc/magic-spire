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
