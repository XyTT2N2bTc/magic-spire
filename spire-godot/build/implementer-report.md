# 实现者报告：present(dirty) 第二刀 header

域：`ui/main.gd::present` 加 `["header"]` 局部；键＋早退＋不叠按钮在 `ui/shell/header.gd`。`["body_bar"]` 路由保留。非清洁／非加固。

起步 HEAD：`cd3b2e6`（规划者 close；其上为 `3db554e`）。分支 `worker/partition-delta`。未 push。本报告提交前源码 HEAD：`3fd78fa`。

## 改动文件

- `spire-godot/ui/main.gd`（2957 行）：`present` 对 `["header"]` 调已有 `GameHeader.configure(self)`；`_present_needs_full_render` 允许 `header`／`body_bar` 局部。无 GameHeader／layout 空／View 空 → 全量。未改 `_submit`。局部未调 `begin_frame`、未清空 `layout.used`、未 instantiate `header.tscn`、未调 `_header`／`_relic_row`。`main.gd` 不复制 header 键、不因自算键跳过 `configure`。未改 `header.tscn`／`game_layout.gd`／`body_sidebar._presentation_key`。无新 UI 文件。无 core／data。
- `spire-godot/ui/shell/header.gd`（59 行）：`_presentation_key(ui) -> Array`；脚本内 `_key`；`configure` 开头比对，命中早退；未命中先清 Button 再建模并写回 `_key`。字段 ⊆ 节键表 header 行且覆盖 configure 实读（含 locale／`show_route`／`save_failed`）；`version` 不进键。
- `spire-godot/tests/display_ui_cases.gd`（793 行）：`present_routes_header_or_full`，已在 `run` 里接在 `present_routes_body_bar_or_full` 之后。测试侧复用 `GetViewCountingGame`；生产无计数器。
- `spire-godot/build/implementer-report.md`（本文件，`git add -f`）

Godot 无 Size and ESM。`main.gd` 本就超长；本刀只加薄路由，未拆文件。`present(dirty: Array=["*"], snapshot: Dictionary={})` 保持未类型化 Array。

检查点：
- `cfd7522` `checkpoint(implementer): add header presentation key`
- `4274257` `checkpoint(implementer): add present header routing`
- `e2d6f3b` `checkpoint(implementer): add present_routes_header_or_full`
- `3fd78fa` `checkpoint(implementer): register present_routes_header_or_full`

## 叠按钮

不叠。键命中早退，保留 `GameHeader` 与 `OpenTutorial` 实例；`header.find_children("*","Button",true,false).size()`＝6。键未命中先清再建模，件数仍＝6。`present(["relics"])`／`["*"]`／未知名仍全量替换 `GameHeader`。

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
- 日志：`spire-godot/build/checks/20260925T090356087-10692/`

`present_routes_body_bar_or_full`／`sidebar_refresh` 同套件未红。未提交 `*.import`／`.uid`。

未跑：规则套件、其它 UI 套件、打包、加固变异、验收（本刀 UI 验收 none）。
