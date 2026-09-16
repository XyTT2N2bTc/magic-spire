# 仓库现状

## 模块

- `spire-godot/`：《紧缚尖塔》，Godot 4 塔路与卡牌游戏，本仓当前唯一模块。
  规则以 `docs/` 为准；规范集中在本仓根 `AGENTS.md`。

## 目录职责

- `docs/`：仓库级文档——背景与指引索引、模块设计/契约/验证、发布说明与许可副本；入口 `docs/agent-guide.md`。
- `spire-godot/`：游戏源码、内容包、测试与分类检查脚本。
- 命令与操作流程不在 AGENTS.md：见 `.zcode/skills/repo-ops/SKILL.md`。

## 历史

- 本工作区曾包含网页文字 RPG 模块 `game-demo/`（《魔法少女又白给了》）。
  该模块现已不在本仓；其数值与流程不适用于 `spire-godot/`，也不据其反向修改规则定义。
  历史约束见 `docs/history/`。
