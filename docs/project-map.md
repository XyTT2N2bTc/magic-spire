# 仓库现状

## 模块

- `spire-godot/`：《紧缚尖塔》，Godot 4 塔路与卡牌游戏，本仓当前唯一模块。
  规则以 `docs/` 为准；规范集中在本仓根 `AGENTS.md`。

## 目录职责

- `docs/`：仓库级文档——背景与指引索引、模块设计/契约/验证、发布说明与许可副本；入口 `docs/agent-guide.md`。
- `spire-godot/`：游戏源码、内容包、测试与分类检查脚本。
- 命令与操作流程不在 AGENTS.md：见 `.zcode/skills/repo-ops/SKILL.md`。

## 相邻项目（不在本仓）

- 网页文字 RPG《魔法少女又白给了》位于与本仓同级的另一仓库 `mahou-shoujo-escape`。
  本仓不包含它的源码、素材清单或构建流程，也不运行它的 npm 门禁与发布。
- `spire-godot/` 的少量美术是经用户确认从该项目复制过来的副本，
  来源与处理记录见 `spire-godot/assets/art/ART-NOTES.md`、`spire-godot/assets/ui/equipment/SOURCE.md`；
  运行时只读本项目副本。该项目的数值与流程不适用于 `spire-godot/`，
  不据其实现反向修改本仓规则定义。
- 本仓 `docs/history/` 保留的是本仓自己的历史契约（当时根契约曾同时覆盖两个项目）。
