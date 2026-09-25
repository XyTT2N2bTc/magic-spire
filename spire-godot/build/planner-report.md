# 规划者报告：card_facts 消费 has_targets_at

- 域：`core/card_effects.gd::card_facts` 槽循环消费 `Game.has_targets_at`；无 `target_slots` 的挣扎／滑脱／降紧不对空槽 `targets_at` 全身收集。不改走查。
- 状态：**needs-human-review**。契约 `spire-godot/build/card-facts-consume-extract.md`。对照 `has-targets-slice-extract.md`、`docs/spec/equipment-query-seam.md` 的 `has_targets_at` 行、既有 `card_facts_declared_slots`。HEAD `bc84826` 静态读取；未实现、未跑 Godot。
- 切分：唯一消费点在将调用 `targets_at` 的槽前问谓词；空则沿用空槽事实规则且不再收集。不得用 `occupied` 判空，不得复制 `_visit_targets_at` 过滤。
- **新增边（待协调者记录认可）：** `card_effects::card_facts` → `Game.has_targets_at`。上一刀未加此边。未批不派实现者、不写 `docs/spec`。
- Gherkin：`tests/architecture_cases.gd::card_facts_consumes_has_targets_at`（待实现）。验收 UI **none**。档 2：关谓词／改 occupied／空槽仍 `targets_at` 须红。
- 检查证据：仅静态读取接口与 `card_facts` 槽循环；Godot／测试／审查／清洁／加固均未验证，不报告通过；无产品源码、打包、发布或 push。
