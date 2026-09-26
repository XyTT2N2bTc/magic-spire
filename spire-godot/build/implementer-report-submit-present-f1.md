结论：PASS（仅实现者域）。bunny F1 的脏集过滤已按提交前挂载态收口：本次卸载的 `pickers`／`body_details` 留在 dirty，交既有全量谓词 `render`／`begin_frame` 拆除；提交前已未挂载的节仍滤掉。`submit_unmounts_closed_overlay_sections` 已注册。指定 display 门禁通过。无 needs-human-review 越界点。独立审查、清洁、加固与验收者结论不由本报告代替。

日期：2026-09-26。工作树：`C:/1/tmp/magic-spire-wt-partition-delta`；分支：`worker/partition-delta`；起点：`8ea38c5`；源码／测试／契约 checkpoint：`ddafbea`。本报告随后单独 `git add -f` 并 checkpoint。

## 域与实现

- 契约：`spire-godot/build/submit-present-extract.md` 第 4 条。bunny F1：过滤把「提交前已未挂载」与「本次提交把它卸载」滤成一类。muse PASS 未当作 F1 已关。
- `spire-godot/ui/main.gd::_submit`：与 `previous_keys` 同时、在 ok 清选中之前，对 `show_log`／`pickers`／`body_details`／`speech`／`drawers` 取样既有 `_present_needs_full_render([section])`。`_submit_dirty` 只按该提交前表去掉已未挂载节；本次卸载的节留在 dirty。空 `notice` 仍按提交后 `notice==""` 去掉（清空靠多节 `_hide_term`；⑥ 陈旧拒绝要能局部挂上 notice）。不得、也没有用清选中之后的状态做 overlay 过滤。
- 未改 `_present_needs_full_render` 各节谓词、未改 `_refresh_picker_section`／`_refresh_body_details_section` 无条件重建、无新卸载函数、无新模块、无 `kind` 脏表、无第二套外观键。`present(dirty: Array=["*"], snapshot: Dictionary={})` 保持未类型化 Array。
- `spire-godot/tests/display_ui_cases.gd`：新增 `submit_unmounts_closed_overlay_sections`（⑧ 手选后出牌、⑨ 详情后出牌）并注册于 `run`。`submit_presents_local_dirty_or_full` ①–⑦ 正文未改。⑧⑨ 允许因卸载全量而换 `GameHeader`；断言卸载后树上无 `HandSelectionBar`／`HandTargetCancel`／`EquipmentDetails`／`CloseEquipmentDetails`，`get_view`＝基线＋1。
- `docs/spec/response-pipeline.md`：被取代的「候选中只过滤既有未挂载／空节谓词」已改写为提交前过滤／本次卸载留 dirty；无并排旧事实。

## 命令与证据

PowerShell。在 `spire-godot/`，只设置本次子进程环境：

```powershell
$env:GODOT_BIN='C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'
& tools/check.ps1 -UIOnly -UISuite display -TimeoutSeconds 900
```

| 运行号（相对 `spire-godot/build/checks/`） | 结果与域 |
| --- | --- |
| `20260926T070828431-40912` | **最终** exit 0；`SUITE RESULT: display PASS`；`UI PASS: 951 assertions`；summary status=passed、ui.complete=true；docs PASS：35 文档、2421 引用、0 问题、allowlist 6。 |

同轮 `before` 与 `after` 均为 `8785EF2AC6AE0EE7A0FBF3FD486BA58D7C18EF2DA22D7608035D6BF19E4D0DB0`；仅用于本轮稳定性守卫，不作为跨运行身份。证据：`spire-godot/build/checks/20260926T070828431-40912/summary.json`、`check-ui.log`、`check-docs.log`。

根目录 `git diff --check 8ea38c5..HEAD` 返回 0。允许改动面仅 `ui/main.gd`、`tests/display_ui_cases.gd`、`docs/spec/response-pipeline.md` 及本报告。三份改动文件均通过严格 UTF-8 解码；大小分别为 main 206077、测试 193812、响应契约 41283 字节。计数文件行数：`ui/main.gd` 3660（本刀 +8，已超行数线，未拆模块）、`tests/display_ui_cases.gd` 2197、`docs/spec/response-pipeline.md` 375。Godot 无 Size and ESM。

## 四态

| 状态 | 本次域内结论 |
| --- | --- |
| 已通过 | 最终 display 全分类（含新增卸载场景及既有 `present_routes_*`／`sidebar_refresh`／`submit_presents_local_dirty_or_full`／`submit_reject_semantics_unchanged`／`takeover_path_unchanged`）、文档引用门禁、同轮指纹、差异空白及编码检查。 |
| 失败 | 无。 |
| 未运行 | 独立审查、清洁、加固／档 2 变异、验收者流程、其它 UI 分类、规则全回归、性能测量、打包及发布；不属本次实现者授权，不声称通过。契约场景 2／8 未完成。 |
| 不适用 | 内容包校验（无 packs 改动）、新模块／允许边／运行时依赖审批（均未新增）。 |

## Checkpoint 与交付边界

本地 checkpoint：`c9d7277` 提交前 overlay 过滤；`c6a1041` ⑧⑨ 场景；`ddafbea` 契约过滤句。本报告随后单独 `git add -f` 并 checkpoint。

心跳：`tmp/agent-implementer-submit-present-f1.log`。仅改源码、测试、契约及授权报告；未提交 `.import`／`.uid`、日志或构建产物，未使用 `git add -A`。未碰 keyword-query、equipment-index、主树脏文档或全局技能；无 push、merge、PR、tag、升版本、打包或部署。未清洁、未加固、未派双审。
