# 事实表的「面 / 点」边界收口：依赖约束索引

「事实表的『面 / 点』边界收口」片（`docs/spec/candidate-removal.md`「接口」T4／T5／T8 之后的收口）的依赖约束索引：
**A 批（K0 分支词表＋K1 单元表）与 B 批（K2 点查询的限定生产者：39 kind 各自一个域臂）已落地**；
C（点形家族一次构造）／D（整表批内复用）／E（需求机制＋结果标量）／F（接线）／G（声明切片）未开工。判据的真源是下表点名的检查，散文不复述内容
（规则见 `skills/spire-docs/SKILL.md`「判据优先」）。

路径约定：不带 `spire-godot/` 前缀的源码、测试与工具路径（`core/`、`ui/`、`data/`、`tests/`、`tools/`、`build/`）
均相对 `spire-godot/`；`docs/` 相对仓库根。本文件不写执行结果：通过／失败／未执行登记 `docs/record/verification.md`。

## 收口后的唯一入口（A＋B 批已落地）

| 语义 | 唯一入口 |
| --- | --- |
| 表出口 | `core/game.gd::command_facts`（唯一整表出口；B 批未改） |
| 表的组成（单元序列） | `core/command_registry.gd::FACT_UNITS`（单元表：id／order／owner／producer／groups／input） |
| 单元连接 | `core/game.gd::_join_fact_units`（唯一通道：按表序 `call(producer, facts)`；未声明单元不产行） |
| 阶段分支 | `core/game.gd::_phase_branch`（具名分支 id；`core/game.gd::_phase_facts` 与 23 项 kind 域臂共用） |
| 点查询的来源 | `core/command_registry.gd::ENTRIES[kind].source`（每 kind 一个域臂＝分支守卫＋该分支单元的最小生产者；B 批落地） |
| 行 → 组 | `core/game.gd::display_fact` 的 `fact.group=` 写入点（本批未改） |

## 判据 → 检查

| 判据 | 执行它的检查 |
| --- | --- |
| 单元表 ↔ 测试内字面期望双向全量（owner 序／id／producer／input／order）；生产者都在 `core/game.gd` 上存在；连接通道唯一（源码文本）；每单元 input 指向同 owner 更早的单元；组列与实测行 group 值域双向一致；测试侧重放与 `core/game.gd::_fact_source`／`core/game.gd::_phase_facts` 逐字节相等 | `tests/architecture_cases.gd::fact_units_cover_fact_source` |
| 分支词表三处双向全量：`tests/architecture_cases.gd::PHASE_BRANCH_VOCABULARY`（字面表）↔ `core/game.gd::_phase_branch` 的 return 点 ↔ `core/game.gd::_phase_facts` 的 return 点；`core/game.gd::_phase_facts` 体内无条件链 | `tests/architecture_cases.gd::phase_branch_vocabulary_is_total` |
| G-1 零移动：`R5_BASELINE` 与四个 mask 常量按动工前摘要冻结（任何移动＝红；重冻必须走前值冻结＋声明差异＋自证的程序） | `tests/architecture_cases.gd::baseline_constants_are_unchanged` |
| 缺省路径逐字节不变（26 cell 的 facts／verdicts／view／record 摘要） | `tests/architecture_cases.gd::behavior_baseline_equivalence` |
| 本片判据的突变证据存在；`known_gaps` 只许相对 A 批冻结清单缩短（新增条目即红） | `tests/architecture_cases.gd::mutation_evidence_is_total`＋`tools/check-mutation.ps1` |
| 全 39 kind 的双向等价：方向①（点查询 == 该 kind 表内首条 params 命中行）／方向②（变异 params 的接受集 == 表成员集）＋跨夹具成员语料（过宽臂在此层红）；表形 kind 跳 keys／member 步骤 | `tests/architecture_cases.gd::fact_lookup_all_kinds` |
| 域臂守卫只经 `core/game.gd::_phase_branch()` 取分支（扫域臂体，不扫 `_phase_facts` 体）；9 个 K0 之前的窄来源与 1 个恒空臂逐条豁免且双向核对 | `tests/architecture_cases.gd::domain_arm_guards_call_phase_branch` |
| 整表来源不再是点查询的答案：登记表文本无整表来源名；每个 table kind 的臂体不调 `core/game.gd::_fact_source()`／`core/game.gd::command_facts()`；23 项绑定各自的域臂 | `tests/architecture_cases.gd::point_sources_are_kind_limited` |
| 点查询不建整表：可行动期一次 `command_fact` 的整表构建＝0；接管期声明豁免＝1；23 项里至少 15 项命中非空行 | `tests/architecture_cases.gd::point_query_builds_no_table` |
| 分支/前缀态的行面按动工前值冻结（63 态：13 相位 × plain／relic_bundle／departure／domain_blocked ＋ 十一个状态标志分支），前缀零移动在仓库内可重放 | `tests/architecture_cases.gd::prefix_branch_tables_are_frozen` |
| kind → table 来源的身份字面冻结（23 项已 rebase 到域臂；少改／多改都红） | `tests/architecture_cases.gd::fact_source_map_is_pinned`、`tests/architecture_cases.gd::pipeline_lookup_inspect` |
| 单元生产者不得写判定、不得推进随机（只读面） | `tests/architecture_cases.gd::single_eligibility_implementation`、`tests/architecture_cases.gd::behavior_baseline_equivalence` 的 `rng`／`rng_total` 逐 cell |

## 允许的依赖方向

- `core/game.gd` → `core/command_registry.gd`：允许；单元表只存 `g` 上的方法名与字面数据（零 preload、无 Callable）。
- 单元生产者只写在 `core/game.gd` 上，签名 `(facts: Array) -> Array`；`facts`＝本单元之前已累积的表；
  连表只经 `core/game.gd::_join_fact_units`（表外不追加任何行）。
- `core/game.gd::_phase_branch`：只读——不写 `state`、不推进随机、不改 `version`。
- 域臂（`core/game.gd::_chain_kind_facts` 一族，`ENTRIES[*].source` 的取值）× 分支守卫：只经 `core/game.gd::_phase_branch()`
  取分支 id；不得复制 `core/game.gd::_phase_facts` 的早退链，也不得回落 `core/game.gd::_fact_source()`／`core/game.gd::command_facts()`。
- 域臂的生产者＝`core/command_registry.gd::FACT_UNITS` 里该分支的单元生产者（休息／奖励／旅途复用同一单元生产者，
  不写第二份实现）；点查询路径与整表出口共用同一批生产者，故两者不可能各自漂移。
- 不新增依赖边；core／data 不 preload ui；本批不新增 View 键、不新增存档字段、不改提交事务与判定语义。

## 不可独立增量（显式登记）

读已累积表的单元与宽切片单元不得开切片复用（G 批不得触碰）：`relic_bundle_consumables`／`departure_consumables`／
`noncombat_consumables`（按 payload.kind／item 去重）、`route`（读累积表的出口行＋现算 `core/game.gd::room_entry_reason`）、
`relic_effects`／`hand_cards`／`prison`／`events`／`services`。任何"按本次提交的 kind 决定复用"的做法同禁。

## 仍靠人审（无机械判据，A 批保留）

- **`core/game.gd::_phase_facts` 直呼的语义残差**：其三个前缀臂（relic_bundle／departure／domain_blocked）落回尾段；
  改动前该函数在这些状态会命中链内的相位分支。可达面：三个前缀由 `core/game.gd::_fact_source` 先行解析，
  `core/game.gd::_flow_kind_facts` 带域守卫，`core/game.gd::_depart` 在前缀表上不可达，路线理由只消费出口行；
  实测（A 批差分探针，`build/` 目录，不随提交）＝90 个状态里表出口面逐字节相等，仅 6 个前缀状态 × 直呼
  `core/game.gd::_phase_facts`（rest_choice／reward／travel × relic_bundle／domain_blocked）不同，且都不在生产调用路径上。
  **B 批起表出口面的前缀零移动已在仓库内可重放**（`tests/architecture_cases.gd::prefix_branch_tables_are_frozen` 冻结
  63 个分支/前缀态的行面摘要）；上面这条直呼残差仍只由差分探针实测，不在仓库内重放。
- **豁免与恒空臂**：9 个 K0 之前的窄来源（`tests/architecture_cases.gd::PHASE_BRANCH_ARM_EXEMPT`）与 1 个恒空臂
  （`tests/architecture_cases.gd::BATCH_ARM_GUARDLESS`，`core/game.gd::_relic_control_done_kind_facts`）逐条登记并双向核对
  （列错即红）；但「臂在夹具矩阵之外的分支是否真的不产行」只由该矩阵与覆盖断言保证，无全机械证明。
- **组列观测夹具的覆盖上限**：`tests/architecture_cases.gd::FACT_UNIT_GROUP_UNCOVERED` 逐条登记矩阵里观测不到的
  (单元:组) 对（A 批为 chain 相关两项，需牌链夹具）；判据双向核对（列出的必须真的观测不到），豁免不能腐烂。
- **单元表的完备性**：新增一个生产者而不登记，由源码文本判据（表外第二处追加点）与 G6 行面兜底；
  表自身"少声明一个单元"由测试内字面期望与实测组列抓。
- 不属于本片授权面：推送／打标签／改版本号、打包；改 `project.godot` 与导出预设；改 `tools/check.ps1`／
  `tools/check-docs.ps1`／`tools/doc-scan-scope.ps1` 与其允许清单。
