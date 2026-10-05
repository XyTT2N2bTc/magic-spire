# 事实出口「直出＋对象注册」：依赖约束（cleaner 可核对）

> 接口契约（登记项字段、批间判据）见 [候选层移除](candidate-removal.md) T4 行与切片计划；本文件只列允许改动面、依赖方向与禁止项。
> 人审与模块切分批准：2026-10-04（协调者记录的裁定，规划产物暂存区不入库）；S1、S5、S2、S3 已落地；S4 未开工，开工时按 kind 另开切片并重列本表，不新增行。
> 与实现文件面**逐文件一致**（多写少写都算失败）；开工当日用文末复算命令重取迁移面清单，有漂移先经协调者改本表，不得静默多改少改。
> 本文件不写执行结果：通过／失败／未执行登记 `docs/record/verification.md`。

路径约定：不带 `spire-godot/` 前缀的源码路径（`core/`、`data/`、`ui/`、`tests/`、`tools/`、`build/`）均相对 `spire-godot/`；`docs/` 相对仓库根。

## 允许改动（核心面）

| 文件 | 允许的改动 | 必须保持 |
| --- | --- | --- |
| `core/command_registry.gd`（新建，S1 已落地；唯一汇编点） | 39 条登记项（`form` ＋ 方法名）：37 条 table 形（`source`）；S2（已落地）`attack`、S3（已落地）`card` 转 point 形（`keys`／`build`／`member`＝`core/command_registry.gd::point` 的 point 分支）；`core/command_registry.gd::kinds`／`core/command_registry.gd::entry`／`core/command_registry.gd::point`、接管整表项 `core/command_registry.gd::takeover_source` | 零模块 preload（经 `g` 调用域函数）；只读：不写 `state`、不产事件、不推进随机、不改 `version`；登记表是 kind 的唯一清单（`form` 无默认、必须显式） |
| `core/command_registry.gd.uid`（S1 已落地） | 引擎生成的脚本资源 UID 旁文件，随新脚本入库 | 不手工改 UID |
| `core/game.gd` | S2 补件（已落地）：`attack_point_member` 改独立谓词（守卫＋家族键面比对，不调 `attack_point_fact`／`_attack_offer_fact`／`core/witch_character.gd::attack_offer_fact`／`_equipment_spell_fact`），新增 `_attack_battle_families_ready`（基础／巫女共用的阶段守卫）、`_attack_point_release_target`（自解目标按 id 解析，构造与谓词共用）、`_basic_attack_point_key`／`_witch_attack_point_key`／`_equipment_point_member`；`attack_point_fact` 的基础／巫女分支补阶段守卫，`_equipment_point_fact` 改用共享解析。S1 已落地：`_kind_facts` 改登记表查找并删 `_:` 兜底臂；`_command_fact_row` 的接管分支取登记表项、可行动期经 `core/command_registry.gd::point`；登记表 table 形来源落为本文件具名函数（`core/game.gd::_whole_table_kind_facts`／`core/game.gd::_item_discard_kind_facts`／`core/game.gd::_posture_kind_facts`／`core/game.gd::_wall_move_kind_facts`／`core/game.gd::_status_toggle_kind_facts`／`core/game.gd::_relic_kind_facts`／`core/game.gd::_surrender_kind_facts`，签名统一 `(kind, params)`），`_flask_kind_facts`／`_flow_kind_facts`／`_item_use_kind_facts` 同步该签名。S5（已落地）：`dispatch` 结果新增 `fact` 键（判定行；失败与未判定为 `{}`；成功键面＝`{ok, version, resource_feedback, card_feedback, music_feedback, checkpoint, spell_failed, fact}`）。S2（已落地）：`attack_facts`／`equipment_spell_facts` 体内只做同登记项 keys × build 的家族取用（`target` 空／非空），新增 `attack_point_keys`／`attack_point_fact`／`attack_point_member` 与 `_equipment_point_fact`，装备自解循环体提为 `_equipment_spell_fact(target, factor, usage)`；`attack` 转 point 形后 `_attack_kind_facts` 删除。S3（已落地）：新增三个登记面转发 `card_point_keys`／`card_point_fact`／`card_point_member`（登记项只存 `g` 上的方法名，唯一实现在 `core/card_effects.gd`，转发不含逻辑）；`_phase_facts` 的手牌循环调用点保留（逐卡切片，行序与条数同转换前） | 五条预检顺序与 `error` 文案、版本比对、事务副本与全回滚、`version` 成功一次自增、执行分支、`get_view` 调用点白名单、`core/game.gd::command_params`／`shape_key`／`_fact`／`display_fact` 语义逐字不变；table 形来源函数的守卫、顺序与产出逐字不变（只把 kind／params 变成参数）；point 形候选键顺序＝转换前该 kind 生产者的表序（`attack`＝`attack_facts`＋`equipment_spell_facts`；`card`＝逐手牌的 `card_facts` 行序，含 `exhaust_hand` 选择展开与槽位走查顺序）；**point 形构造器与成员谓词的阶段／家族守卫必须与转换前生产者的守卫逐条对应**（S2 补件 L1／L9；不得只靠「某阶段没有存活敌人」一类隐含前提）：`attack` 基础／巫女＝`_attack_battle_families_ready`（`_phase_action_tail` ∧ `phase=="battle"`，keys／build／member 共用同一函数），装备自解＝非巫女 ∧ `factor>0` ∧ target 在 `action_targets`；判据＝`tests/architecture_cases.gd::attack_point_rejects_nonbattle_families`（非战斗阶段＋存活敌人负例）。View 生产者的到达守卫由转换前的 `base_action_block()` 换成经 `attack_point_keys` 的 `_phase_action_tail()`：**在 View 路径上等价**——两者差异只存在于 `_phase_facts` 提前返回的状态（非战斗的 `event`／`captured`／`inspection`／`prison_end` 早退，以及 overloaded＋战斗／`card_chain` 非空／`pending_retain` 三态早退），尾段攻击生产者在这两类状态都不可达；`attack_facts`／`equipment_spell_facts` 在 View 之外的唯一直呼者是 `tests/relic_mana_cases.gd`／`tests/relic_revision_cases.gd`，均为普通战斗态 |
| `core/card_effects.gd`（S3，已落地） | `core/card_effects.gd::card_facts` 改同登记项候选键 × build；新增 `core/card_effects.gd::card_point_keys`（该 kind 候选键的唯一枚举，按卡切片与整手共用）、`core/card_effects.gd::_card_point_card_keys`（单卡候选键枚举的唯一实现）、`core/card_effects.gd::_card_point_sites`（逐分支族条件与跳过条件的唯一落点）、`core/card_effects.gd::card_point_fact`（点构造；params 经 `core/card_effects.gd::_card_point_site`／`core/card_effects.gd::_card_point_choice` 解析到唯一站点与选择）、`core/card_effects.gd::card_point_member`（独立成员谓词：守卫＋成员判断，不构造行）、`core/card_effects.gd::_card_slot_walk`（槽位走查）、`core/card_effects.gd::_card_slot_key`／`core/card_effects.gd::_card_slot_fact`（槽位项的键面与行构造）与 `core/card_effects.gd::_target_choices`／`core/card_effects.gd::_target_fact`（exhaust_hand 选择展开与单行构造，供 `core/card_effects.gd::target_facts` 复用）。S2 补件（已落地，R10）：删除本模块的第二份手牌查找 `_hand_card`，两处调用（`core/card_effects.gd::card_point_fact`／`core/card_effects.gd::_card_point_site`）改经 `core/game.gd::_card`（唯一实现） | 分支面与行顺序逐字节不变；`core/card_effects.gd::target_payload`／`core/card_effects.gd::target_facts` 签名与产出不变；`card_facts_declared_slots` 语义（声明外槽位不查询、不产行）不变；no Callable 进 `data/`；**函数级守卫不对称须写明**：`core/card_effects.gd::card_facts` 体内无阶段守卫，而 `core/card_effects.gd::card_point_keys` 有 `_phase_action_tail`——**非行为差异**（View 侧的阶段条件在 `core/game.gd::_phase_facts` 尾段控制流里，转换前亦然），不得据此把任一函数改成另一形状 |
| `core/witch_character.gd`（S2，已落地） | 巫女家族的单行构造提为 `core/witch_character.gd::attack_offer_fact(g, enemy, part, form)`，供 point 构造复用；S2 补件（已落地，L4）：删除无调用方的第二份候选键枚举 `attack_facts`——巫女家族的候选键枚举唯一实现在 `core/game.gd::attack_point_keys` | `SPECS[id]` 运行期数据写入语义不变；不新增卡型代码注册路径；不保留第二份候选键枚举或构造 |
| `core/consumables.gd`／`core/mana_flask.gd`／`core/relic_effects.gd`／`core/relic_bundle.gd`／`core/departure.gd`／`core/room_services.gd`／`core/room_events.gd`／`core/prison.gd`／`core/prison_space.gd`／`core/demo_exit.gd`／`core/first_turn_control.gd` | S1 只作为登记项的 table 形来源被点名（**文件不改**）；S4 开工时才按 kind 改点形并重列本表 | 枚举语义、文案、顺序不变 |

## 允许改动（UI 面）

| 文件 | 允许的改动 | 必须保持 |
| --- | --- | --- |
| `ui/main.gd` | S5（已落地）：`ui/main.gd::_submit` 删除提交前的 `command_fact(cmd)`，改读 `dispatch` 结果里的判定行（体内不出现 `command_fact(`）；`payload` 取用点不变 | 提交执行段仍唯一；`dispatch` 调用点仍唯一（`tests/architecture_cases.gd::instruction_router_single_entry` 锁定）；ok 路径呈现输入逐字段不变；失败路径无可见差；不改选择类零提交语义、不改 `get_view` 调用点 |

## 允许改动（测试与工具面）

| 文件 | 允许的改动 | 必须保持 |
| --- | --- | --- |
| `tests/architecture_cases.gd` | S1 已落地：`pipeline_lookup_inspect` 判据反转（删 `T4_WIRED_KINDS`／`unwired_keys>0`／`_:` 断言；新增 `command_registry_is_total`；`PIPELINE_LOOKUP_EDGES` 由三条改两条 L-point／L-table；新增 `POINT_KINDS`＋运行期派生的 `TABLE_KINDS`；新增未登记 kind 的运行期 fail-closed 探针）。S2（已落地）：双向等价 harness `fact_lookup_equivalence`＋变异语料 `fact_lookup_mutations`＋用例 `attack_fact_direct_lookup`（逐家族覆盖计数）与 `attack_point_lookup_reads_one_row`（源码文本＋计数子类 `AttackLookupCountingGame`）；`POINT_KINDS` 加 `attack`、`FROZEN_TABLE_SOURCES` 移出 `attack`，新增 `FROZEN_POINT_METHODS` 钉 `attack` 的 keys／build／member。S3（已落地）：card 双向等价用例 `card_fact_direct_lookup`（0／12／26／44 件 × 战斗／监狱／整备夹具＋分支族夹具；`FACT LOOKUP` 打印逐分支族覆盖计数，任一为 0 即红；`CARD_BRANCH_FAMILIES` 常量列字段族）与 `card_point_lookup_reads_one_row`（源码文本＋计数子类 `FactSourceCountingGame`）；夹具 `card_branch_fixture`／`card_exhaust_fallback_fixture`／`card_bind_fixture`／`card_special_cross_slot_fixture`／`card_empty_target_fixture`／`card_duplicate_params_fixture`；`POINT_KINDS` 加 `card`、`FROZEN_TABLE_SOURCES` 移出 `card`，`FROZEN_POINT_METHODS` 钉 `card` 的 keys／build／member。S5（已落地）：单次查询计数用例 `single_fact_lookup_per_submit`／`rejected_submit_lookup_counts`／`submit_presented_fact_is_unchanged`（计数子类 `SubmitLookupCountingGame`；打印每次提交的 `command_fact` 计数与成功结果的新旧键面）；`r1_build` 增可选 `game_class` 参数（省略时构造逐字节不变，仅供计数子类复用同一夹具）；G6 冻结值按协调者裁定的显式重算：`submit_keys` 与派生 `<record>` 共 26 cell（O7 批准的 `fact` 键所致，mask 与其余记录字段不变；自证见 `docs/record/verification.md` 的 S5 条）。S2 补件（已落地）：新增 `attack_point_rejects_nonbattle_families`（非战斗阶段＋存活敌人负例：点查询为空且 params 不在表内、member 同假）与夹具 `attack_nonbattle_enemy_fixture`／`attack_nonbattle_witch_fixture`；`attack_point_lookup_reads_one_row` 的源码文本判据扩为被调单行 helper 白名单（`ATTACK_POINT_HELPERS`，含 `core/witch_character.gd::attack_offer_fact`）＋间接调用扫描（`ATTACK_POINT_INDIRECT_CALLS`）＋member 独立于请求行构造器（`ATTACK_POINT_ROW_CONSTRUCTORS`）；重复收敛夹具注释改为只主张「点查询返回枚举序首条」；`core/card_effects.gd` 的源码提取用测试内 `source_static_func_body_code`（既有 `source_func_text` 只认行首 `\nfunc `，对全 static 文件会取到文件尾）。C1 收尾（已落地）：新增具名 check `dispatch_fact_row_is_readonly`（扫 `core/game.gd::dispatch` 体内对判定行的成员／索引赋值——`chosen.<字段> …=`／`chosen["…"] …=`／`chosen.payload…=`，比较与传参不算）与 `payload_write_sites_are_pinned`（扫 `core/`＋`data/` 的 `payload` 写点，集合断言＝字面白名单 `PAYLOAD_WRITE_WHITELIST`，多一处或少一处都红）。C1 修正批（R14，已落地）：写形态放宽为「接收者**末段**恰为 `payload`」的成员赋值 `.field=`（含 `+=` 等复合）与索引赋值 `[…]=`，保留 `payload.merge(`／`erase(`／`clear(` 一族，段边界 `\b`（`attack_payload.x=`／`target_payload[…]` 不计）；按出现次数逐条重钉白名单 `PAYLOAD_WRITE_WHITELIST`＝`core/card_effects.gd::card_point_fact` 两处＋`core/prison.gd::add` 一处；`PAYLOAD_WRITE_CALLS`／`PAYLOAD_INDEX_WRITE_PATTERN` 删为 `PAYLOAD_WRITE_PATTERN`／`PAYLOAD_MUTATOR_CALL_PATTERN` | 既有断言语义不删不弱；G2／G6／既有 T4 行等价仍绿；计数器只在测试侧（`tests/architecture_cases.gd` 的计数子类形态，如 `FactSourceCountingGame`），生产源码不带计数器 |
| `tests/` 其余文件 | 实测本片 0 处迁移（`.dispatch(` 调用点只读 `.ok` 与具名字段；逐文件见复算命令）；若后续改动触及其断言面再按形态迁移 | 期望值与断言语义不变；不删有效失败用例 |
| `tools/check.ps1`／`tools/check-docs.ps1`／`tools/doc-scan-scope.ps1` | **零改动**（允许清单不得新增条目；若需新增即违反本规约） | — |

## 允许改动（文档面）

| 文件 | 允许的改动 | 必须保持 |
| --- | --- | --- |
| `docs/spec/fact-lookup-dependencies.md`（本文件，S1 新建） | 随阶段同步文件面；C1 修正批（R14，已落地）：禁止项的 payload 写点判据射程＋四条已知逃逸面 | 与实现逐文件一致；被取代段落改写或删除，不留「更正」段 |
| `docs/spec/candidate-removal.md` | S1 已落地：§2.1 T4 行与查找边措辞；S1 清洁：§1.6 D-4 过时取行措辞。S5（已落地）：§3.1 M-III 的返回形状清单（加 `fact`，并补上清单原本漏写的既有 `spell_failed`）。C1 收尾：§2.1 新增「事实行只读」不变量（不拷贝、执行段只写 `state`、未来落点在 `state`）与两条判据点名。C1 修正批（R14，已落地）：§2.1 补「判据的射程（不是「共享行只读」的证明）」段——写点扫描口径与白名单实值，逃逸面链接依赖规约 | 其余 T 图与 G 条不动；机读真源仍是 `tests/architecture_cases.gd::PIPELINE_LOOKUP_EDGES`，文档只链接不复制 |
| `docs/spec/candidate-removal-dependencies.md` | S1 清洁（协调者追加授权）：T4 登记项取行与整表来源措辞；S2 补件：`core/witch_character.gd` 行的历史符号锚点改纯文本名（L4 删除 `attack_facts` 后锚点会判未声明） | 其余允许面与不变量不动 |
| `docs/spec/response-pipeline.md` | S5（已落地）：接缝 A 的 `dispatch` 返回形状行 | 其余接缝与调用点白名单不动 |
| `docs/record/verification.md` | 只追加：每批日期＋域＋命令＋结果＋未跑项＋敏感性证明运行号 | 历史条目不改 |

## 允许的依赖方向

- `core/game.gd` → `core/command_registry.gd`：允许。
- `core/command_registry.gd`：**不 preload 任何模块**；域函数经 `g` 取用。不得 preload `ui/`；不得 preload `core/copy_router.gd`／`core/save_store.gd`（二者反向 preload `core/game.gd`）。
- `core/card_effects.gd` → `core/command_registry.gd`：允许（仅登记表零 preload 时）。
- core／data 不 preload ui；`ui/` 内只有 `ui/main.gd` 允许 preload core；无新增 UI→core 边。
- 数据只走声明字段：`data/card_rules.gd::SPECS` 不持有 Callable／函数引用；卡型 override（若获准，见裁定的 O2 条目）只落在 core 侧的表并过同一套判据。
- 不新增第三方依赖、不新增运行时钩子、生产源码不带计数器／计时钩子、不新增存档字段与随机域。

## 禁止项

- 第二份 kind 清单或第二个查表点；第二套点构造器／资格判定；绕过登记项的提交前查询。
- 点查询路径到达整表生产者（`core/game.gd::_fact_source`）或该域整表枚举函数，除非该 kind 的登记项**显式点名**整表来源；用 mock 生产者或空壳夹具换绿。
- 写判定行或其 `payload`：事实行与其 `payload` 自产出起只读，UI 与执行共享同一对象、不引入拷贝（语义与落点见 `docs/spec/candidate-removal.md` §2.1「事实行只读」）；执行段只写 `state`。
  - **判据的射程**：`tests/architecture_cases.gd::payload_write_sites_are_pinned` 是「`core/`＋`data/` 全部 `.gd` 内、接收者**末段**恰为 `payload` 的**写点集合计数钉**」，抓文本形态的写点，**不是对「共享行只读」的证明**。扫描面＝成员赋值 `.field=`（含 `+=` 等复合赋值）与索引赋值 `[…]=`（段边界 `\b`，故 `attack_payload.x=`／`target_payload[…]` 等末段不是 `payload` 的接收者不计），外加改字典内容的 `payload.merge(`／`payload.erase(`／`payload.clear(`；集合**恰等于**字面白名单 `tests/architecture_cases.gd::PAYLOAD_WRITE_WHITELIST`，按写点**出现次数**逐条登记（同一函数内的第二处写——即使同一行——同样变红）。白名单（生产者侧构造其刚造的本地载荷）：`core/card_effects.gd::card_point_fact`（两处写点：`payload.kind="card"` 与 `payload.uid=card.uid`）与 `core/prison.gd::add`（`payload.merge(extra)`）。与 `tests/architecture_cases.gd::dispatch_fact_row_is_readonly`（只扫 `core/game.gd::dispatch` 体内的 `chosen` 写点）合起来仍不是只读证明。
  - **已知逃逸面**（本判据抓不到的写形态，逐条登记）：①`dispatch` 之外对判定行／`chosen` 的成员形写（判据①只扫 `dispatch` 体内；`var c=chosen` 后写 `c.xxx=` 这类改写亦然）；②UI 侧写入（扫描面不含 `ui/`，而「UI 只读消费同一对象」正是本不变量的一端；`ui/` 里 `payload` 另有「拖放载荷」含义（如 `ui/drag_targets.gd` 的 `drag_payload`、`ui/impact_feedback.gd` 的 `payload` 参数），扩面会大面积误报，故不扩——该面靠架构边界（UI 只消费只读投影）与审查，不靠本判据）；③函数内局部别名（`var p=chosen.payload; p["x"]=1`——接收者末段是 `p` 不是 `payload`；生产者侧同类如 `core/card_effects.gd::card_point_fact` 的 `bind.kind="card"`／`bind.uid=card.uid`）；④把 `chosen.payload` 传给 helper、由 helper 去写（写点文本上不属于 `payload`）。补偿＝白名单计数变化即红＋审查。
- 改拒绝／原因／标签／费用／魔力／风险文案与顺序；改接管语义与「豆包接管中」文案。
- 改 `core/snapshot.gd::REVISION`、存档字段、随机域语义；触碰装备只读查询接缝内部。
- 删改既有断言换绿灯；新增 `check-docs` 允许清单条目；把 `relic_bundle`／`departure`／接管整表改写成点形。
- 把 S4 未转换 kind 写成已转换；用毫秒数或采样数作完成判据／提速宣称。
- 推送、打标签、改版本号；改 `project.godot` 或导出预设。

## 自检清单（实现者交付前逐条对照）

- `core/command_registry.gd::kinds` 与 `GameCore.COMMAND_KEYS` 键集合逐条相等（39／39）；`POINT_KINDS` 与登记项实际形态一致。
- `rg` 复算：`core/game.gd::_kind_facts` 无 `_:` 臂；`ui/main.gd::_submit` 无 `command_fact(`；`ui/` 内 `.dispatch(` 调用点仍唯一。
- 方向①／②在冻结矩阵＋稠密夹具＋至少一个非战斗阶段实跑通过；card 分支覆盖计数全部 > 0；harness 期望侧不取自登记项。
- 每批敏感性证明各一次实测取证；批间门禁绿；G2／G6／既有 T4 行等价仍绿；`source_changed` 未被当作通过。
- 依赖表文件面与实际改动文件面**逐文件一致**（多写少写都改本表）。

## 复算命令（开工当日重取；漂移先经协调者改本表）

在 `spire-godot/` 下执行：

```powershell
rg -n "func _kind_facts|func _command_fact_row|func command_fact|func command_facts|func dispatch|func _fact_source" core/game.gd
rg -n "command_fact\(|command_facts\(" ui/ tools/ tests/architecture_cases.gd
rg -n "\.dispatch\(" ui/
rg -n "attack_facts|equipment_spell_facts" core/ tests/
rg -n "card_facts\(" core/ tests/
rg -l "\.dispatch\(" tests --glob '*.gd' | Measure-Object -Line
```

（最后一条用于核对「dispatch 调用点只读具名字段」的迁移面；本片预计不产生迁移改动，若命中面与预期不符，先改本表再动手。）
