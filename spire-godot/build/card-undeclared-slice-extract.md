# 规划者提取物：无声明槽卡牌事实剪枝（阻塞）

状态：**needs-human-review；停止，不派实现者**。域：`core/card_effects.gd::card_facts` 中无 `target_slots`、`mode` 为 `strain`／`slip`／`lower` 的普通槽事实生产。`card_facts_undeclared_coverage_guard` 护栏草案已否决；本刀要求真实查询剪枝，不把全身扫描锁为目标。

## 切分与接口

- 预期边界：仅 `card_facts(g, card) -> Array` 的槽查询分支；消费既有公开 `Game.targets_at`／`occupied` 等查询；`target_payload`、`target_facts`、`_fact` 与事实形状、顺序、`payload`／`valid`／`reason`／`key` 不变。无新增事实副本、运行时依赖或状态写入。
- 数据流与唯一入口：`card_facts` 槽循环 → 占用目标仍经 `targets_at(slot)` → `target_payload` → `target_facts`；真正空普通槽原先 `targets_at(slot)==[]` → `[{}]`，自由面事实必须保留。槽查询/事实判定不另开第二路径。
- 非目标：有 `target_slots` 的表外不查已完成刀、`self_faces`／`single_face` 早退、T4 `card`、T5、delta、TERMS、整份 `card_facts`、装备查询接缝内部。允许方向仅卡牌生产者调用 Game 公开查询，不能复制目标集合规则。

## 阻塞证据（HEAD `614f683`；静态核对，未跑 Godot）

- `docs/spec/equipment-query-seam.md`「接口」：`occupied(slot)` 只问 `equipment_at(slot)`，手掌/手指另有双侧特例；`targets_at(普通槽)` 还合并活跃复合组件、`links_at(slot)`、`Binding.connections(self)`。因此 `not occupied(slot)` **不蕴含** `targets_at(slot).is_empty()`。
- 反例输入域：普通槽无实体装备但有覆盖该槽的独立链接或躯干连接，`occupied=false` 而 `targets_at` 非空，当前解除事实不可丢。手掌/手指一侧装备存在也可 `occupied=false`；活跃复合覆盖是另一来源。
- 当前 `card_facts` 对无 `target_slots` 普通槽直接 `targets_at`，空则 `[{}]`；简单改成 `if not g.occupied(slot): targets=[{}]` 会漏目标行，事实不可能逐字段相等。单查 `links_at` 仍未排除连接/复合；逐槽重组这些规则是第二套目标语义，扫描 `action_targets` 也不是已证实的省查询。
- 已查既有公开接口契约，未找到低于 `targets_at` 成本且完整判空的现成查询。旧 `tests/architecture_cases.gd::card_facts_union_slot_oracle` 只证明上一刀声明槽事实相等，不能证明本刀剪枝安全。

## 待协调者交人审的决定

择一后重新规划：①允许装备查询接缝提供统一、低成本的 `has_targets_at(slot)` 或等价公开接口，批准新增依赖边与契约；②授权更窄且有非零可观察剪枝的输入域，先证明空槽判定和成本；③取消本刀。不能以只增 architecture 护栏、强制全身扫描或现状绿替代。新增接口属复杂计划，切分认可之外还须计划人审。

## Gherkin／验收／完成定义（待决，不是本次通过）

- 拟定 Gherkin 位置 `tests/architecture_cases.gd`：Given 无 `target_slots` 的 `strain`／`slip`／`lower`，普通真空槽及实体/链接/连接/复合/手侧半占用槽；When `card_facts`；Then 全部事实与本刀前逐字段相等，空槽自由面保留；测试子类计数 `targets_at`，只对经批准接口证明为空的槽要求 0，仍有目标的槽保持事实。判空契约未定，暂不写不可运行的守卫；生产不加计数器。
- 拟定验收流程：以这些状态在正常手牌 UI 选卡，确认空槽自由面与各占用目标可见、可选择且提交结果一致；路径/夹具须在获批的安全输入域确定后落成 agent 可运行步骤，目前不得派验收者。
- 完成定义：协调者记录切分及复杂计划人审认可，随后依赖规约落 `docs/spec`、实现、`tools/check.ps1 -Suite architecture` 对等价和计数变绿、独立审查及验收按域取证。现在 Godot/验收/档 2 均未验证；只形成阻塞判断。
- 加固预选档 2（未执行）：域为上述 architecture；变异恢复真正空槽 `targets_at` 应红、丢链接/连接/复合事实应红、改字段应红，原场景须绿。窗口、内容包、打包、档 4／5 不属本刀；具体命令及有限输入域待重新定界。
