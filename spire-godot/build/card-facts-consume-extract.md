# 规划者契约：card_facts 消费 has_targets_at

状态：**needs-human-review；实现者不开工**。域：`core/card_effects.gd::card_facts` 槽循环里对将调用 `targets_at` 的槽先问 `Game.has_targets_at`；无 `target_slots` 的 `strain`／`slip`／`lower` 不再对空槽 `targets_at` 全身收集。HEAD `bc84826` 静态切片，未实现、未运行。谓词已在 `core/game.gd::has_targets_at`／`_visit_targets_at` 落地；本刀不改走查、不过滤复制。

**新增允许边（须协调者记录人审）：** `core/card_effects.gd::card_facts` → `Game.has_targets_at`。上一刀 `spire-godot/build/has-targets-slice-extract.md` 刻意不写这条边。切分／过夜任务授权不等于本边已批。未记录前不派实现者、不写 `docs/spec` 依赖规约。

## 切分、接口和依赖

- 只改 `card_facts(g, card) -> Array` 槽循环中**现有会调用 `targets_at(slot)` 的分支**（无 `target_slots` 时每槽 `declared==true`；有表牌的已声明槽同门）。入口仍是该循环；不新增事实生产者、模块、运行时依赖、存档／schema、状态写点。
- 数据流：`card_facts` 槽循环 → **`has_targets_at(slot)` 判空** → false 则沿用现有空槽规则（特殊／肩／特殊槽 `continue`；普通槽 `targets=[{}]`；其后 `bound_modes` 仍跳过空目标）且**不得**再调 `targets_at`；true 则 `targets_at(slot)` 取件，再走既有 `target_payload`／`target_facts`。判空不得用 `occupied`；`occupied` 只保留现有「有目标且非肩、未占满则追加 `{}`」规则。表外槽占用跳过（`g.occupied(slot)` continue）属已落地 `card_facts_declared_slots`，本刀不改。
- 过滤只存在于 `Game._visit_targets_at`。`card_facts` 不得复制来源顺序／过滤（不得自拼 `equipment_at`／复合／`links_at`／`Binding.connections`），不得把 `has_targets_at` 实现为 `targets_at(slot).is_empty()`，不得在生产者内建第二套目标规则。非空槽允许先谓词再收集（两次走查），不得在 `card_effects` 缓存走查结果。
- 允许实现面：`spire-godot/core/card_effects.gd` 的上述槽循环，以及 `spire-godot/tests/architecture_cases.gd` 的单个具名场景／`run` 注册。不得改 `core/game.gd` 走查、其它规则消费者、UI、`data/`。边未批或实现需复制过滤／改其它允许边 → 保持／升级 `needs-human-review` 并停下。

## Gherkin：`card_facts_consumes_has_targets_at`（一个可观察行为）

Given `tests/architecture_cases.gd` 的 `TargetsAtCountingGame.new(42)`（或等价、生产无计数器），`state.phase=="battle"`，清空四类装备；`Rewards.give` 无 `target_slots` 的 `strain`（可同夹具再给 `slip`）。按 `has_targets_at_parity` 已用工厂分别构造：真正空；单侧 `palm`／`fingers`（`occupied=false`）；仅覆盖槽的活链接／连接／活跃复合；以及耐久 0 链接、禁用复合的空槽反例。Oracle＝测试侧 `card_facts_union_slot_oracle`（仍经 `targets_at` 收集，不用生产者自身）。先算 oracle 与快照／`state.rng`，再清零 `targets_at_slots`。
When 对各夹具调用 `g.Cards.card_facts(g,card)`。
Then 事实与 oracle 逐字段相等（含空普通槽自由面 `[{}]`、单侧手／链接／连接／复合解除行的 id）；空槽（含失效来源）的 `targets_at_slots` 不含该槽；有目标的槽仍出现在计数中；单侧手 `occupied` 仍为 false 且事实含该件；快照／随机游标不变。既有 `card_facts_declared_slots` 不得变红。生产源码不加计数器。

## 完成定义及档 2（尚未执行）

- 协调者记录本边人审后：实现者交上述场景与唯一消费点；独立新会话审查者只核对本域源码／测试与本契约；清洁者核对未复制走查过滤、未用 `occupied` 判空、依赖面 ⊆ 允许面。人审之后才把该边写入 `docs/spec/candidate-removal-dependencies.md` 的 `core/card_effects.gd` 行；本次规划不写 `docs/spec`。
- 实现者在 `spire-godot/` 运行 `& tools/check.ps1 -Suite architecture -TimeoutSeconds 600`。通过＝退出码 0、`SUITE RESULT: architecture PASS`、完成标记、`summary.json` 的 `status=passed` 且指纹未变。未运行、`source_changed`、夹具不可构造或反例缺失＝未完成。不借 `has_targets_at_parity` 旧绿宣称本域通过。
- 档 2（选定加固者，独立实现／清洁后）对上述有限输入域跑 architecture。变异须红：①关掉谓词消费（空槽仍全身 `targets_at`）；②用 `occupied` 替代 `has_targets_at` 判空；③`has_targets_at` 为 false 仍调 `targets_at`。原版绿；变异复原后重跑本域。不能靠静态搜索替代行为敏感性。缺工具或失败＝未通过，不算不适用。
- UI 验收 **none**：事实形状与本刀前相等，无玩家新行为；不派验收者。无打包、发布、push。

## 非目标

T4／T5／delta／TERMS／关键字识别／分区渲染；改 `has_targets_at`／`_visit_targets_at`；表外占用跳过重写；第二套目标规则；扩整份 `card_facts`。

## 风险假设

已落地谓词与同槽 `targets_at` 非空等价（`has_targets_at_parity`）。本刀只换空槽是否调用 `targets_at`，不改变行集合。若实现无法只消费谓词而要复制过滤或把 `occupied` 当目标空，停工交回，不改契约去迁就。
