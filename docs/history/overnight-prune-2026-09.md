> 归档：只读，不是现行指令。通宵协调窗 2026-09-25–26 的切片顺位与落地边界；现行以人最新点名、开着的 PR 和源码为准。

# 事实表剪枝通宵窗 · 2026-09-25–26

人 2026-09-25 授权三块，顺位：

1. 只访问必要依赖（空槽先 `has_targets_at` 再 `targets_at`）
2. 卡牌依赖走稳定 ID（`keyword_ids`；按牵涉决定查询／`get_view` 跑哪一段）
3. 分区 delta（已有 `present(dirty)`／节键，不新写 CSS）

规划者把第 2 块收成只抽出 `data/card_text.gd::keyword_ids`，消费标非目标。人 2026-09-26 说明昨晚不要求审核；稳定 ID 是词条分类预处理，不是运行时再检测。

## 当时开着的产品 PR（fork `XyTT2N2bTc` → 作者仓）

| PR | 枝 | 当时头 | 内容 |
| --- | --- | --- | --- |
| [#8](https://github.com/h13942080472-prog/magic-spire/pull/8) | `pr/necessary-deps` | `80b2aec` | `has_targets_at`；`card_facts` 跳过空槽收集 |
| [#9](https://github.com/h13942080472-prog/magic-spire/pull/9) | `pr/keyword-deps` | 当时清洁枝 `8b4cb89`；后窗曾推进 | `keyword_ids` 收集器。**未**作为完成态接到 `get_view` |

对照 tip：`seed-chip-tip`＝本地主树 `614f683`。主检出 `seed-chip-save-upload` 未合这些 PR。

## 测量（毫秒不是完成判据）

`spire-godot/build/overnight-press-cardfacts-20260926/`（gitignored）：`strain` 的 `targets_at` 次数，`614f683` vs consume `b8a52af`。空装 21→0；只手掌 21→1；44 件 21→12。未测 `get_view`。

## 工作树

2026-09-27 人令卸掉全部附加 worktree。Git 只留 `C:\1\magic-spire`。本地 `worker/*`、`pr/*` 枝仍在，提交未删。会话派单、审查 log、旧交接在仓外 `C:/1/tmp/archive/magic-spire-agents-2026-09/`。
