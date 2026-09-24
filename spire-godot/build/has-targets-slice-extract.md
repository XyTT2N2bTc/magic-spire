# 规划者契约：装备目标公开判空

状态：可交协调者；HEAD `1ee2085` 静态切片，未实现、未运行。域：`core/game.gd::targets_at` 的全部合法槽（普通槽、`shoulder`、特殊槽）及其新公开谓词 `has_targets_at(slot)`；本刀不改 `core/card_effects.gd::card_facts`。协调者已记录人审选项 ①，否决 `occupied=false` 和 coverage guard；不选 ②③。

## 切分、接口和依赖

- 只在既有 `Game` 装备只读接缝增加 `has_targets_at(slot: String) -> bool`。返回值恒等于同一状态、同一只读作用域下 `not targets_at(slot).is_empty()`；不返回容器，不写状态，不改变随机游标。作用域开／关（含无效索引的 live 回退）均一致，既有 `targets_at` 的顺序、去重、过滤、实例身份及返回容器隔离不变。
- 数据流：`Game` 权威装备／复合／链接／特殊件／连接 → 现有 `_equipment_read` 来源边（有作用域）或 live 来源（无作用域）→ **唯一的按槽目标来源遍历／投影** → `targets_at` 收集全部或 `has_targets_at` 命中即止。普通槽实体 → 活跃复合组件（按引用去重、排肩）→ 活链接 → 连接；肩槽与特殊槽按 `docs/spec/equipment-query-seam.md`「接口」原顺序和原过滤。过滤判定仅在该共享路径定义一次，不在谓词复制，不在 `card_effects` 拼 `links_at` 与复合；谓词不得调用 `targets_at(slot).is_empty()`、不得先组装全量目标数组。
- 单入口和写点：唯一判定入口为上述共享遍历；`targets_at` 和谓词只是两种消费，不增状态写点。允许方向仍为 `Game` → 既有 Equipment／Composites／SpecialEquipment／Links／Binding 和其索引；测试 → Game 公开接口。**不新增** `card_effects` → Game 依赖边（下一刀另审），不新增模块、运行时依赖、存档/schema。沿用 `docs/spec/equipment-query-seam.md` 已有来源表，不建立第二套目标规则。
- 允许实现面：`spire-godot/core/game.gd` 内接缝，以及 `spire-godot/tests/architecture_cases.gd` 的单个具名场景／注册。不得改接缝外的规则消费者。若共享路径需要复制过滤条件或更改允许依赖边，标 `needs-human-review` 并停下，不换 coverage guard。

## Gherkin：`has_targets_at_parity`（一个可观察行为）

Given `tests/game_fixture.gd.new(42)`，清空四类装备；按 `tests/link_cases.gd::index_link_edge_parity`、`tests/composite_cases.gd::index_root_edge_parity`、`tests/torso_binding_cases.gd` 既有工厂分别构造：真正空普通槽；单侧 `palm`／`fingers` 件（`occupied=false`）；仅有覆盖槽的活链接／连接／活跃复合组件；肩部件；特殊件；以及耐久 0 链接和禁用复合的反例。用测试侧 `targets_at` 调用计数代理和 live／scope 两种入口，同状态保存快照。
When 对每个所列槽调用 `has_targets_at(slot)`，独立调用现有 `targets_at(slot)` 得到 oracle；在至少一个实体件先命中的普通槽以测试侧 later-source 计数确认后续来源未访问。
Then 每个 bool 等于 oracle 非空，空槽与失效来源为 false，其余目标槽为 true；单侧手部 bool 为 true 而 `occupied` 仍为 false；谓词调用期间 `targets_at` 计数为 0，先命中不访问后续来源；scope/live 结果相同；既有 `targets_at` 逐项顺序／实例与调用前基线相同，快照／随机游标不变且退出作用域释放。测试先独立计算 oracle 再清零计数，不能用谓词自身作 oracle。

## 完成定义及档 2（尚未执行）

- 实现者交上述场景和唯一来源路径；独立新会话审查者只核对本域源码／测试与本契约，清洁者核对单路径与依赖。协调者确认新增接口的正式契约记录后才更新 `docs/spec/equipment-query-seam.md`；本次规划不写 `docs/spec`。
- 实现者在 `spire-godot/` 运行 `& tools/check.ps1 -Suite architecture -TimeoutSeconds 600`，检查退出码、`SUITE RESULT: architecture PASS`、完成标记及 `summary.json` 的 passed／未变指纹；来源表改动涉及的既有 `equipment`／`composites`／`links`／`shoulder`／`torso_binding` 相关套件由影响面再选，不借旧绿宣称本域通过。未运行、`source_changed`、夹具不可构造或任一反例缺失均未完成。
- 档 2 由选定的加固者在独立实现／清洁后，对有限上述输入域运行 architecture：变异 `has_targets_at` 恒 false、用 `occupied` 判空、丢链接／连接／复合／手侧任一来源、恢复 `targets_at(slot).is_empty()` 必须使对应检查红；原版绿，变异复原并重跑受影响域。不能靠静态搜索替代行为敏感性，测试侧计数不得进入生产源码。缺工具或失败为未通过，不算不适用。
- UI 验收 **none**：本刀仅新增未被 `card_facts` 消费的只读公开谓词，无玩家可达行为；协调者已限定不派验收者。无打包、发布、push。下一刀 `card_facts` 消费及事实等价／剪枝独立规划，T4／T5／delta／TERMS／UI 不在本刀。

## 风险假设

共享按槽遍历可在首个命中早停，同时不改变 `targets_at` 的排列、按引用去重和 live／scope 回退；若代码证明不可做到而需复制来源过滤条件，升级 `needs-human-review`，不实施护栏。`occupied=false` 的既有反例由链接、连接、复合及单侧手覆盖，不作为判空依据。
