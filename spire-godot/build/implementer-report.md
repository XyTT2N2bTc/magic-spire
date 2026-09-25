# 实现者报告：present(dirty) 第一刀 body_bar

域：`ui/main.gd` M3 展示调度（`present`／节名枚举／仅 `["body_bar"]` 局部）。非清洁／非加固。

起步 HEAD：`a0ebd5c`。分支 `worker/partition-delta`。未 push。本报告提交前源码 HEAD：`ef7e231`（其上已有 present／场景／前一份报告）。

## 改动文件

- `spire-godot/ui/main.gd`（2950 行）：`PRESENT_SECTIONS`、`present`、`_present_needs_full_render`。未改 `_submit`。局部路径未调 `begin_frame`、未清空 `layout.used`。未改 `game_layout.gd`／`body_sidebar._presentation_key`。无新 UI 文件。无 core／data。
- `spire-godot/tests/display_ui_cases.gd`（717 行）：测试侧 `GetViewCountingGame`、`present_routes_body_bar_or_full`，已在 `run` 里接在 `sidebar_refresh` 之后。
- `spire-godot/build/implementer-report.md`（本文件，`git add -f`）

Godot 无 Size and ESM。`main.gd` 本就超长；本刀只加薄入口，未拆文件。

契约写 `Array[String]`；Godot 调用处字面量是无类型 `Array`，会 SCRIPT ERROR。生产签名为 `present(dirty: Array=["*"], snapshot: Dictionary={})`，元素按 `String` 对照节名枚举。未知／`["*"]`／缺项／非 `body_bar` 的已声明节／layout 空／View 空 → `render(当前 View)`，不再 `get_view`。

检查点：
- `382c8c1` `checkpoint(implementer): add present body_bar routing`
- `8bd0ddc` `checkpoint(implementer): add present_routes_body_bar_or_full`
- `2bfa594` `checkpoint(implementer): accept untyped present dirty arrays`

## end_frame

未停工。局部路径 `end_frame` 未释放 hero／body／敌人（场景内断言通过）。未改 `game_layout.gd`，未新开 present 文件。

## 检查

新鲜工作树无 `.godot`：首轮 `check.ps1` 自动 import，缺 `NotoSansCJKsc-Regular.otf` `.fontdata`；import 后字体缓存已在。未提交 `*.import`／`.uid`。

在 `spire-godot/`：

```
$env:GODOT_BIN='C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'
& tools/check.ps1 -UIOnly -UISuite display -TimeoutSeconds 900
```

通过（本会话实测）：

- 退出码 0
- `SUITE RESULT: display PASS`
- `UI PASS: 260 assertions`（`check-ui.log`：UI SUITE 43233 ms）
- `summary.json` `status=passed`，`before`＝`after`＝`602629A948CF16B6B1456D2331149DF2C86D0D1AEDC4EF888B73B0799480A0E9`
- 日志：`spire-godot/build/checks/20260925T075801868-39772/`

`sidebar_refresh` 同套件未红。

未跑：规则套件、其它 UI 套件、打包、加固变异、验收（本刀 UI 验收 none）。
