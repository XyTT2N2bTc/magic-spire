---
name: repo-ops
description: >-
  本仓（magic-spire）的命令与操作流程：分类检查门禁、内容包校验、引擎定位与启动、
  打包与发布入口。要在本仓跑检查、启动或打包，或问"命令是什么/怎么验证"时使用。
  AGENTS.md 只写规范；本文件写操作。
---

# 本仓命令与操作流程

规范见仓库根 `AGENTS.md` 与同目录技能（`spire-architecture`／`spire-ui-content`／`spire-validation-release`）；本文件只放操作与命令。
命令在标明的目录执行；占位分类替换为本次实际影响的分类。

## 仓库根

```powershell
git status --short
git diff --stat
git diff --check
git diff --name-only
```

## spire-godot（Godot 模块）

```powershell
& tools/check.ps1 -Suite architecture
& tools/check.ps1 -Suite casting,pressure -Impact
& tools/check.ps1 -UIOnly -UISuite equipment_art,hero_art
& tools/check.ps1 -Import -Suite architecture -UI -UISuite home
& tools/check.ps1 -Suite installation_priority -Impact -Exhaustive
& tools/check.ps1 -Suite runner -VerifyRunner
& tools/check.ps1 -Suite all -UI -UISuite all          # 完整回归
& tools/check.ps1 -Changed                             # 按工作区变更路由（默认 base=HEAD）
& tools/check.ps1 -Changed -ListOnly                   # 只出计划，不算通过
& tools/check.ps1 -Changed -Since <ref>                # 已提交后：ref → 工作区
& tools/check.ps1 -ChangedList <清单文件>               # 显式清单（探针／非 git 调用方）
& tools/check-index.ps1                                # 检查索引零漂移校验（退出码 0／1）
& tools/check-index.ps1 -Write                         # 重新派生并覆盖 tests/check_index.json
```

- **路由只服务开发期快速反馈**：PR、打包（`tools/package*.ps1`／`check-package.ps1`）、发版（tag／Release）、版本推进、跨域大改**一律用全量的 `-Suite all -UI -UISuite all`**（里程碑唯一入口）；`-Changed` 的结果**不得**作为交付或里程碑门禁。全量必须包含 `normal_play`／`baseline`（路由按设计扣除它们）。
- 路由解析：索引命中用索引（可加 `WIDEN` 声明放大）；未命中走目录闭包；两者都未命中为 `unmapped`（fail-closed 到 `all-dev`＋`all-dev-ui`）。每次运行按适用范围打印 `ROUTE ROW`／`ROUTE DEFAULT`／`ROUTE DOMAIN`／`ROUTE UNMAPPED`／`ROUTE WIDEN CANDIDATE`／`ROUTE MILESTONE`（扣除清单）——**默认决定必须每次可见**；指纹外的路径（如文档）不打印上述各行，只逐条打印 `ROUTE NONE: <path> (outside the source fingerprint; no suites, never a pass)`（2026-09-17 实跑 `-ChangedList <docs-only> -ListOnly` 的输出）；`summary.route` 记录本次使用的索引摘要。
- `-Changed`／`-ChangedList` 与 `-Suite`／`-UISuite`／`-UI`／`-UIOnly`／`-Impact` 互斥，`-Since` 必须配 `-Changed`；空变更集与 `spire-godot/` 之外的路径在起引擎前拒绝。
- 分类注册在 `tests/test_game.gd` 与 `tests/ui_smoke.gd`。
- 纯显示用 `-UIOnly`；规则与界面同时修改则明确指定 `-Suite` 和 `-UISuite`。
- 共享规则用 `-Impact` 合并交叉分类一次跑完；随机生成改动加 `-Exhaustive`。
- `-ListOnly` 只预览范围、不算通过；**所有已选套件默认跑完**（断言失败与脚本错误只记该套件 `FAIL`，脚本错误另打印 `SUITE RUNTIME: <name> <n>`），`-KeepGoing` 仅兼容保留；`-RerunFailed <日志目录>` 只重跑失败与未完成的分类。
- `all` 只用于明确完整回归；检查通过后不无故重复运行。
- 内容包校验：`& tools/check-content.ps1`（改动 `spire-godot/content/packs/` 后必跑）；路由判定内容门时会作为独立阶段自动跑，结果记在 `summary.route.gate_results`。
- 检查索引维护：改动 `core`／`data`／`ui` 或 `tests/**` 会改变派生结果，必须 `check-index.ps1 -Write` 重新冻结并**与源码同批提交**；忘了就由零漂移自检红（默认门禁 `-Suite runner` 立刻失败）。判据只读，检查流程永不自动重写冻结物。
- 引擎与启动：`tools/find-godot.ps1` 定位引擎（`GODOT_BIN` 或项目内探测），`tools/launch.ps1` 启动游戏。
- 打包输出默认写到仓库根 `outputs/`（`package.ps1 -OutputRoot` 可覆盖）；打包与发布：`tools/check-package.ps1`、`tools/package.ps1`、`tools/package-android.ps1`、`tools/check-android-package.ps1`；先读 `docs/packaging.md`，不以旧发布说明代替当前脚本。

## 产物与清理

- 计时脚本、基准数据、验收补充脚本等一次性产物放已忽略的 `spire-godot/build/`，
  不入库、不进运行时；摘要登记到 `docs/verification.md` 后清理原始目录。
