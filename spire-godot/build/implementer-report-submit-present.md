结论：PASS（仅实现者域）。`_submit → present` 多节接线、单个具名 Gherkin 与响应契约已落地；最终指定 display 门禁通过。无 needs-human-review 越界点。独立审查、清洁、加固与验收者结论不由本报告代替。

日期：2026-09-26。工作树：`C:/1/tmp/magic-spire-wt-partition-delta`；分支：`worker/partition-delta`；起点：`485d5e1`；最终受检源码及契约 checkpoint：`daddf9b`。

## 域与实现

- 契约：`spire-godot/build/submit-present-extract.md`。
- `spire-godot/ui/main.gd`：`_submit` 在本地状态重置及 dispatch 之前读取既有节键，提交后只在前后均为 battle 时导出 dirty；成功加入无 main 键的 `scene_instances`，失败不加入；仅按既有谓词过滤约定的未挂载／空节。非空局部集交给 `present(dirty, updated)`，其余交给 `render(updated)`。
- `present(dirty: Array=["*"], snapshot: Dictionary={})` 保持未类型化 Array；按 `PRESENT_SECTIONS` 顺序各处理一次；`body_bar` 为具名分支。空集、`*`、`page`、未知及既有结构性谓词仍全量；多节本身不再触发全量。没有新增 present 直调节体，`PRESENT_ADJACENCY` 的边集合保持有效。
- `get_view`、dispatch、写盘、`card_motion.positions` 与成功反馈调用点集合未增加。反馈仍在展示之后。既有键字段集不变，无 kind 脏表、外观字段副本、新模块或新依赖。
- `spire-godot/tests/display_ui_cases.gd`：唯一新增场景 `submit_presents_local_dirty_or_full` 已注册于 `run`。覆盖多节命中、三种全量兜底、合法攻击、陈旧提交、非战斗 flow；观测节点身份、能量、快照／RNG、get_view 次数、无失败写盘及成功后反馈。计数包装、存档替身和反馈探针全部仅在测试侧。
- `docs/spec/response-pipeline.md`：改写被取代的实现状态、接口、键表、输入域、失败语义及反馈顺序。`commit`／`present_rejection`／同版本被拒零 get_view 仍明确为待实现。

## 命令与证据

PowerShell 实测版本 7.6.6。在 `spire-godot/`，只设置本次子进程环境，三轮均执行：

```powershell
$env:GODOT_BIN='C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'
& tools/check.ps1 -UIOnly -UISuite display -TimeoutSeconds 900
```

| 运行号（相对 `spire-godot/build/checks/`） | 结果与域 |
| --- | --- |
| `20260926T063049192-37472` | exit 1，display FAIL；新场景四条断言失败。恢复快照推进了版本，包装后仍显示旧 View，第一次攻击被陈旧版本拒绝。修复为计数基线之前同步恢复后的 View；未删失败断言。 |
| `20260926T063240098-23280` | exit 0，display PASS，936 assertions，summary passed，before==after。随后前键捕获时序与节键文档修改使此轮不能作为最终证据。 |
| `20260926T063527429-2616` | **最终** exit 0；`SUITE RESULT: display PASS`；`UI PASS: 936 assertions`；summary status=passed、ui.complete=true；docs PASS：35 文档、2421 引用、0 问题、allowlist 6。 |

最终同轮 `before` 与 `after` 均为 `9999B490F1EAFE13E8C7BC493DD80901BCC5D77DFEABA8457D3A15A509147E5B`；仅用于本轮稳定性守卫，不作为跨运行身份。证据：`spire-godot/build/checks/20260926T063527429-2616/summary.json`、`check-ui.log`、`check-docs.log`。

根目录执行 `git diff --check 485d5e1..HEAD` 返回 0；允许改动面核对仅上述三个文件及本报告。三份改动文件均通过严格 UTF-8 解码；大小分别为 main 205841、测试 190011、响应契约 41092 字节。引用门禁验证路径和符号；被取代句检查无残留，现行键表改为既有入口索引。

## 四态

| 状态 | 本次域内结论 |
| --- | --- |
| 已通过 | 最终 display 全分类（含新增场景及既有 present_routes_*／sidebar_refresh／submit_reject_semantics_unchanged／takeover_path_unchanged）、文档引用门禁、同轮指纹、差异空白及编码检查。 |
| 失败 | 最终无未解决失败；首轮夹具版本失败及修复见上表。 |
| 未运行 | 独立审查、清洁、加固／变异验证、验收者流程、其它 UI 分类、规则全回归、性能测量、打包及发布；不属本次实现者授权，不声称通过。契约场景 2／8 未完成。 |
| 不适用 | 内容包校验（无 packs 改动）、新模块／允许边／运行时依赖审批（均未新增）。 |

## Checkpoint 与交付边界

本地 checkpoint：`2779dae` 接线；`231cd2e` 场景；`8e262b5` 契约；`1281a6f` 夹具版本同步；`937ac57` 前键捕获时序；`daddf9b` 现行节键索引。本报告随后单独 `git add -f` 并 checkpoint。

心跳：`tmp/agent-implementer-submit-present.log`。仅改源码、测试、契约及授权报告；未提交 `.import`／`.uid`、日志或构建产物，未使用 `git add -A`。未碰 keyword-query、equipment-index、主树脏文档或全局技能；无 push、merge、PR、tag、升版本、打包或部署。
