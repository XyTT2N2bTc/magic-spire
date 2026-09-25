# 清洁者报告：has_targets_at 共享走查

域：`core/game.gd::_visit_targets_at`／`targets_at`／`has_targets_at`；`tests/architecture_cases.gd::has_targets_at_parity`；`docs/spec/equipment-query-seam.md` 接缝表 `has_targets_at` 行。HEAD `ab898b3`，本刀未改代码。

- 单路径：肩／特殊／普通三分支来源与过滤只在 `_visit_targets_at` 定义一次（肩 `is_shoulder＋durability`、特殊 `SpecialEquipment.occupies`、普通 `equipment_at→_composite_roots＋Composites.definition／active＋排肩→links_at→connections`）；`targets_at` 只收集、`has_targets_at` 只首 hit 返回，均无自带过滤。
- 空 `found` 去重不改 bool：谓词传 `[]` 使 `found.has` 恒假；普通首 hit 在 `equipment_at` 即返，复合去重不可达；复合内首个非肩件即返，去重永不翻转空／非空；等价性由 `has_targets_at_parity` 全夹具 oracle 比对覆盖。
- 无复制过滤、无第二套目标规则；`links_at`／`equipment_at`／`physical_pieces` 复用既有接缝边（谓词组装的是既有来源边数组，从不组装全量目标数组、不调用 `targets_at`）。
- 生产无计数器（`targets_at_slots`／`composite_root_calls`／`links_at_calls` 只在测试子类）；`card_effects` 零 `has_targets_at` 引用，无新增依赖边。
- 依赖方向仍为 Game → 既有 Equipment／Composites／SpecialEquipment／Links／Binding（含 Shoulders 经 `physical_pieces`、索引经 `_equipment_read`)，未新增模块与运行时依赖。
- Godot 本仓无 Size and ESM，不适用。复杂度／依赖方向检查器未建（`tools/` 仅规则＋文档门禁），按简报不新建框架。
- 未改代码故未重跑；消费实现者 `architecture` 证据（exit 0、`SUITE RESULT: architecture PASS`、3344 assertions、`summary.json` passed 且 before==after），对应当前指纹源码；未扫 `docs/record`、未碰 `card_facts`、未 push、未提交 `.uid`／`.import`。
- 结论：本域已洁，无清洁改动，无范围冲突。
