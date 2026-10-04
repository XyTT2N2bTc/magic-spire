# 事实出口「直出＋对象注册」：依赖约束（cleaner 可核对）

> 接口契约（登记项字段、批间判据）见 [候选层移除](candidate-removal.md) T4 行与切片计划；本文件只列允许改动面、依赖方向与禁止项。
> 人审与模块切分批准：2026-10-04（协调者记录的裁定，规划产物暂存区不入库）；S1 已落地，S5／S2／S3 未开工的行以「未落地」标注，开工时改本行，不新增行。
> 与实现文件面**逐文件一致**（多写少写都算失败）；开工当日用文末复算命令重取迁移面清单，有漂移先经协调者改本表，不得静默多改少改。
> 本文件不写执行结果：通过／失败／未执行登记 `docs/record/verification.md`。

路径约定：不带 `spire-godot/` 前缀的源码路径（`core/`、`data/`、`ui/`、`tests/`、`tools/`、`build/`）均相对 `spire-godot/`；`docs/` 相对仓库根。

## 允许改动（核心面）

| 文件 | 允许的改动 | 必须保持 |
| --- | --- | --- |
| `core/command_registry.gd`（新建，S1 已落地；唯一汇编点） | 39 条 table 形登记项（`form` ＋ `source` 方法名）、`core/command_registry.gd::kinds`／`core/command_registry.gd::entry`／`core/command_registry.gd::point`、接管整表项 `core/command_registry.gd::takeover_source`；S2／S3 把 `attack`／`card` 的登记项改 point 形（`keys`／`build`／`member`） | 零模块 preload（经 `g` 调用域函数）；只读：不写 `state`、不产事件、不推进随机、不改 `version`；登记表是 kind 的唯一清单（`form` 无默认、必须显式） |
| `core/game.gd` | S1 已落地：`_kind_facts` 改登记表查找并删 `_:` 兜底臂；`_command_fact_row` 的接管分支取登记表项、可行动期经 `core/command_registry.gd::point`；登记表 table 形来源落为本文件具名函数（`core/game.gd::_whole_table_kind_facts`／`core/game.gd::_attack_kind_facts`／`core/game.gd::_item_discard_kind_facts`／`core/game.gd::_posture_kind_facts`／`core/game.gd::_wall_move_kind_facts`／`core/game.gd::_status_toggle_kind_facts`／`core/game.gd::_relic_kind_facts`／`core/game.gd::_surrender_kind_facts`，签名统一 `(kind, params)`），`_flask_kind_facts`／`_flow_kind_facts`／`_item_use_kind_facts` 同步该签名。S5（未落地）：`dispatch` 结果新增 `fact` 键（判定行，未判定为 `{}`）。S2（未落地）：`attack_facts`／`equipment_spell_facts` 改同登记项 keys × build，新增 `attack_point_keys`／`attack_point_fact`／`attack_point_member`（`_attack_offer_fact` 复用）。S3（未落地）：手牌循环调用点（如需） | 五条预检顺序与 `error` 文案、版本比对、事务副本与全回滚、`version` 成功一次自增、执行分支、`get_view` 调用点白名单、`core/game.gd::command_params`／`shape_key`／`_fact`／`display_fact` 语义逐字不变；table 形来源函数的守卫、顺序与产出逐字不变（只把 kind／params 变成参数） |
| `core/card_effects.gd`（S3，未落地） | `card_facts` 改同登记项 keys × build；新增 `card_point_keys`／`card_point_fact`／`card_point_member`（复用 `target_payload`／`target_facts`／`reason`）；`card_facts_declared_slots` 语义不变 | 分支面与行顺序逐字节不变；`core/card_effects.gd::target_payload` 签名与产出不变；no Callable 进 `data/` |
| `core/witch_character.gd`（S2，未落地，仅当需要暴露巫女家族键／构造器） | 暴露 point 键与构造器入口；`attack_facts` 语义与顺序不变 | `SPECS[id]` 运行期数据写入语义不变；不新增卡型代码注册路径 |
| `core/consumables.gd`／`core/mana_flask.gd`／`core/relic_effects.gd`／`core/relic_bundle.gd`／`core/departure.gd`／`core/room_services.gd`／`core/room_events.gd`／`core/prison.gd`／`core/prison_space.gd`／`core/demo_exit.gd`／`core/first_turn_control.gd` | S1 只作为登记项的 table 形来源被点名（**文件不改**）；S4 开工时才按 kind 改点形并重列本表 | 枚举语义、文案、顺序不变 |

## 允许改动（UI 面）

| 文件 | 允许的改动 | 必须保持 |
| --- | --- | --- |
| `ui/main.gd` | S5（未落地）：`ui/main.gd::_submit` 删除提交前的 `command_fact(cmd)`，改读 `dispatch` 结果里的判定行；`payload` 取用点不变 | 提交执行段仍唯一；`dispatch` 调用点仍唯一（`tests/architecture_cases.gd::instruction_router_single_entry` 锁定）；ok 路径呈现输入逐字段不变；失败路径无可见差；不改选择类零提交语义、不改 `get_view` 调用点 |

## 允许改动（测试与工具面）

| 文件 | 允许的改动 | 必须保持 |
| --- | --- | --- |
| `tests/architecture_cases.gd` | S1 已落地：`pipeline_lookup_inspect` 判据反转（删 `T4_WIRED_KINDS`／`unwired_keys>0`／`_:` 断言；新增 `command_registry_is_total`；`PIPELINE_LOOKUP_EDGES` 由三条改两条 L-point／L-table；新增 `POINT_KINDS`＋运行期派生的 `TABLE_KINDS`；新增未登记 kind 的运行期 fail-closed 探针）。S2（未落地）：双向等价 harness（独立 oracle）＋ attack 用例。S3（未落地）：card 等价＋分支覆盖＋重复收敛用例。S5（未落地）：单次查询计数用例 | 既有断言语义不删不弱；G2／G6／既有 T4 行等价仍绿；计数器只在测试侧（`tests/architecture_cases.gd` 的计数子类形态，如 `FactSourceCountingGame`），生产源码不带计数器 |
| `tests/` 其余文件 | 仅当实现改动触及其断言面时按形态迁移（实测本片预计 0 处：`dispatch` 调用点只读 `.ok` 与具名字段） | 期望值与断言语义不变；不删有效失败用例 |
| `tools/check.ps1`／`tools/check-docs.ps1`／`tools/doc-scan-scope.ps1` | **零改动**（允许清单不得新增条目；若需新增即违反本规约） | — |

## 允许改动（文档面）

| 文件 | 允许的改动 | 必须保持 |
| --- | --- | --- |
| `docs/spec/fact-lookup-dependencies.md`（本文件，S1 新建） | 随阶段同步文件面 | 与实现逐文件一致；被取代段落改写或删除，不留「更正」段 |
| `docs/spec/candidate-removal.md` | S1 已落地：§2.1 T4 行与查找边措辞。S5（未落地）：§3.1 M-III 的返回形状清单 | 其余 T 图与 G 条不动；机读真源仍是 `tests/architecture_cases.gd::PIPELINE_LOOKUP_EDGES`，文档只链接不复制 |
| `docs/spec/response-pipeline.md` | S5（未落地）：接缝 A 的 `dispatch` 返回形状行 | 其余接缝与调用点白名单不动 |
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
