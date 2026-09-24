# 规划者报告：装备目标公开判空

- 域：`core/game.gd::targets_at`／拟议 `has_targets_at`，普通／肩／特殊槽、live 与只读作用域；不含 `card_facts`。
- 状态：协调者记录人审选项 ①；已规划未实现。契约 `spire-godot/build/has-targets-slice-extract.md`，依据 `docs/spec/equipment-query-seam.md` 与阻塞提取物 `spire-godot/build/card-undeclared-slice-extract.md`。
- 切分：Game 同一目标来源路径产完整数组与早停 bool；无新消费者／写点／依赖边。复制过滤或先调 `targets_at` 均不合格，无法共享时 `needs-human-review` 停止。
- Gherkin：`tests/architecture_cases.gd::has_targets_at_parity`（待实现），覆盖空槽、实体、链接、连接、复合、肩／特殊、手侧及失效来源，live／scope 等价和不调用 `targets_at`。
- 完成：architecture 具名场景及受影响既有套件通过、单路径独立审查、清洁与档 2 敏感性；验收 none（未有玩家路径）。
- 检查证据：仅 HEAD `1ee2085` 静态读取接口契约、`Game.targets_at` 与已有夹具；Godot／测试／审查／清洁／加固均未验证，不报告通过；无产品源码、`docs/spec`、打包、发布或 push。
