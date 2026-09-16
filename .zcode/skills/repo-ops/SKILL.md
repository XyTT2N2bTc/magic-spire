---
name: repo-ops
description: >-
  本仓（magic-spire）的命令与操作流程：分类检查门禁、内容包校验、引擎定位与启动、
  打包与发布入口。要在本仓跑检查、启动或打包，或问"命令是什么/怎么验证"时使用。
  AGENTS.md 只写规范；本文件写操作。
---

# 本仓命令与操作流程

规范见仓库根 `AGENTS.md`（含模块规范）；本文件只放操作与命令。
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
```

- 分类注册在 `tests/test_game.gd` 与 `tests/ui_smoke.gd`。
- 纯显示用 `-UIOnly`；规则与界面同时修改则明确指定 `-Suite` 和 `-UISuite`。
- 共享规则用 `-Impact` 合并交叉分类一次跑完；随机生成改动加 `-Exhaustive`。
- `-ListOnly` 只预览范围、不算通过；`-KeepGoing` 跑完全部分类；`-RerunFailed <日志目录>` 只重跑失败与未完成的分类。
- `all` 只用于明确完整回归；检查通过后不无故重复运行。
- 内容包校验：`& tools/check-content.ps1`（改动 `spire-godot/content/packs/` 后必跑）。
- 引擎与启动：`tools/find-godot.ps1` 定位引擎（`GODOT_BIN` 或项目内探测），`tools/launch.ps1` 启动游戏。
- 打包输出默认写到仓库根 `outputs/`（`package.ps1 -OutputRoot` 可覆盖）；打包与发布：`tools/check-package.ps1`、`tools/package.ps1`、`tools/package-android.ps1`、`tools/check-android-package.ps1`；先读 `docs/packaging.md`，不以旧发布说明代替当前脚本。

## 产物与清理

- 计时脚本、基准数据、验收补充脚本等一次性产物放已忽略的 `spire-godot/build/`，
  不入库、不进运行时；摘要登记到 `docs/verification.md` 后清理原始目录。
