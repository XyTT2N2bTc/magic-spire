# 事实出口「直出＋对象注册」：依赖约束索引

「事实出口直出＋对象注册」（`docs/spec/candidate-removal.md`「接口」中提交入口与唯一判定两条的落地形态）一片已落地
（S1／S2／S3／S5；S4 未开工）。本文件是这一片的依赖约束索引：判据的真源是下表点名的检查，散文不复述内容
（2026-10-06 重放并集后改写为索引形态，与规范重写线的其余依赖索引同形；规则见 `skills/spire-docs/SKILL.md`「判据优先」）。

路径约定：不带 `spire-godot/` 前缀的源码、测试与工具路径（`core/`、`ui/`、`data/`、`tests/`、`tools/`、`build/`）
均相对 `spire-godot/`；`docs/` 相对仓库根。
本文件不写执行结果：通过／失败／未执行登记 `docs/record/verification.md`。

## 判据 → 检查

| 判据 | 执行它的检查 |
| --- | --- |
| 登记表全量：`core/command_registry.gd::kinds` 与 `core/game.gd::COMMAND_KEYS` 逐条相等（39／39）；每条登记项的 `form` 显式且为 point｜table；table 项点名的来源、point 项的 `keys`／`build`／`member` 都是 `g` 上已声明的方法；未登记 kind fail-closed；`tests/architecture_cases.gd::POINT_KINDS`（＝`["attack","card"]`）与登记项实际形态一致 | `tests/architecture_cases.gd::command_registry_is_total` |
| 来源表钉死：37 条 table kind 的整表来源映射与登记表**双向**相等（期望侧是测试内字面表 `tests/architecture_cases.gd::FROZEN_TABLE_SOURCES`，不取自登记表；missing／extra 两侧都报），接管整表项＝`core/command_registry.gd::takeover_source`；point 形的 `keys`／`build`／`member` 三种方法名另由 `tests/architecture_cases.gd::FROZEN_POINT_METHODS` 钉 | `tests/architecture_cases.gd::fact_source_map_is_pinned` |
| 点查询 ≡ 整表枚举（双向等价 harness）：方向①点查询命中的行与该状态自身整表行逐字节相等（含重复归一化 params、显式不在表内的 params）；方向②测试侧变异 params 与整表成员扫描一致、成员谓词与键集一致；视图行 ＝ keys × build | `tests/architecture_cases.gd::fact_lookup_equivalence` |
| attack 点形：候选键唯一枚举（基础／巫女／装备自解三家族，顺序＝转换前 `core/game.gd::attack_facts`＋`core/game.gd::equipment_spell_facts` 的表序）；冻结矩阵＋稠密＋非战斗＋巫女＋重复 params 夹具的逐家族覆盖计数，任一为 0 即红 | `tests/architecture_cases.gd::attack_fact_direct_lookup` |
| attack 点查询只构造一行：源码文本（被调单行 helper 白名单＋间接调用扫描＋成员谓词不调请求行构造器）＋运行期计数子类（`core/game.gd::attack_facts`／`core/game.gd::equipment_spell_facts`／整表生产者调用数＝0） | `tests/architecture_cases.gd::attack_point_lookup_reads_one_row` |
| attack 点形的阶段／家族守卫与转换前生产者逐条对应：非战斗阶段＋存活敌人时基础／巫女家族 fail-closed（点查询为空、params 不在表内、成员谓词同假） | `tests/architecture_cases.gd::attack_point_rejects_nonbattle_families` |
| card 点形：0／12／26／44 件 × 战斗／监狱／整备夹具＋分支族夹具（bind／跨槽／空目标／重复 params／exhaust 回退），逐分支族覆盖计数任一为 0 即红 | `tests/architecture_cases.gd::card_fact_direct_lookup` |
| card 点查询只构造一行：源码文本＋运行期计数子类 | `tests/architecture_cases.gd::card_point_lookup_reads_one_row` |
| 每提交恰一次事实出口查询：成功提交的 `command_fact` 计数＝1（在 `dispatch` 内）、`ui/main.gd::_submit` 体内 0 次 | `tests/architecture_cases.gd::single_fact_lookup_per_submit` |
| 被拒提交的查询计数逐类精确（陈旧版本 0、形状不合法 0、判定不通过 1）＋失败文案与状态快照相等 | `tests/architecture_cases.gd::rejected_submit_lookup_counts` |
| 提交成功后的呈现输入与旧行为逐字段相等（旧路径两次查询与新路径一次查询结果一致、提交结果相同） | `tests/architecture_cases.gd::submit_presented_fact_is_unchanged` |
| 成功键面 `fact` 加入的自证：加入前键面摘要＝S5 前冻结值、加入后＝重钉值（两侧都是测试内字面常量） | `tests/architecture_cases.gd::submit_key_face_rebaseline_self_proof` |
| 判定行只读：`core/game.gd::dispatch` 体内无对判定行的成员／索引赋值 | `tests/architecture_cases.gd::dispatch_fact_row_is_readonly` |
| `payload` 写点集合＝字面白名单 `tests/architecture_cases.gd::PAYLOAD_WRITE_WHITELIST`（按出现次数）：`core/card_effects.gd::card_point_fact` 两处＋`core/prison.gd::add` 一处；射程与逃逸面见下「仍靠人审」 | `tests/architecture_cases.gd::payload_write_sites_are_pinned` |
| UI 侧：`ui/main.gd::_submit` 无提交前的 `command_fact(`（源码文本），UI 侧 `dispatch` 调用点仍唯一 | `tests/architecture_cases.gd::single_fact_lookup_per_submit`、`tests/architecture_cases.gd::instruction_router_single_entry` |

## 允许的依赖方向

- `core/game.gd` → `core/command_registry.gd`：允许；`core/card_effects.gd` → `core/command_registry.gd`：允许。
- `core/command_registry.gd`：**不 preload 任何模块**（只存 `g` 上的方法名，无 Callable）；不得 preload `core/copy_router.gd`／`core/save_store.gd`（二者反向 preload `core/game.gd`，会成环）。
- core／data 不 preload ui；不新增 UI→core 边；`data/card_rules.gd::SPECS` 不持有 Callable／函数引用。
- 不新增第三方依赖、不新增运行时钩子；生产源码不带计数器／计时钩子（计数子类只在测试侧）。

## 仍靠人审（无机械判据，本批保留）

- **S4 未开工**：其余 37 条 kind 仍走 table 形（`form` 显式登记、来源为既有域函数）；把未转换 kind 写成已转换、
  或按 kind 另开切片时未重列本文件，均算未完成。
- **`payload` 写点判据的射程**（不是「共享行只读」的证明）：`tests/architecture_cases.gd::payload_write_sites_are_pinned`
  是 `core/`＋`data/` 全部 `.gd` 内写点**出现次数**的计数钉，抓文本形态；扫描面＝成员赋值 `.field=`（含 `+=` 等复合）与索引赋值 `[…]=`
  （接收者**末段**恰为 `payload`，段边界 `\b`，故 `attack_payload.x=`／`target_payload[…]` 这类不计），
  外加改字典内容的 `payload.merge(`／`erase(`／`clear(`。已知逃逸面逐条：①`dispatch` 之外对判定行／`chosen`
  的成员形写（该判据只扫 `dispatch` 体内；`var c=chosen` 后写 `c.xxx=` 亦然）；②UI 侧写入（扫描面不含 `ui/`——
  `ui/` 里 `payload` 另有「拖放载荷」含义（`ui/drag_targets.gd` 的 `drag_payload`、`ui/impact_feedback.gd` 的形参），
  扩面会大面积误报，故不扩，该面靠架构边界与审查）；③函数内局部别名（`var p=chosen.payload; p["x"]=1`）；
  ④把 `chosen.payload` 传给 helper、由 helper 去写。补偿＝白名单计数变化即红＋审查。
- **point 形构造器与成员谓词的阶段／家族守卫必须与转换前生产者逐条对应**（不得只靠「某阶段没有存活敌人」一类隐含前提）；
  `core/card_effects.gd` 的函数级守卫不对称（`core/card_effects.gd::card_facts` 体内无阶段守卫，
  而 `core/card_effects.gd::card_point_keys` 有 `core/game.gd::_phase_action_tail` 一类守卫）是既有形状、非行为差异，
  不得据此把任一函数改成另一形状。
- 不写 `valid`／`reason`、不产事件、不推进随机、不改 `version`；不把 `relic_bundle`／`departure`／接管整表改写成点形。
- 不属于本片授权面：推送／打标签／改版本号；改 `project.godot` 或导出预设；
  `tools/check.ps1`／`tools/check-docs.ps1`／`tools/doc-scan-scope.ps1` 与 `check-docs` 允许清单。
