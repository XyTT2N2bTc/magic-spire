# 状态迁移管线收束契约（同类迁移一条主路径）

规划者契约（planner contract），2026-09-16。基线：分支 `event-pipeline-unification`，提交 `c31d71c`，
工作区干净（`docs/save-fixed-points.md` 有一处未提交的扫描表更新，见 §0）。行号捕获于该提交；
**函数名是稳定锚点**，动手前用 `rg` 复算。本文件不写执行结果：通过／失败／未执行只登记到 `docs/verification.md`。

**状态：`needs-human-review`（见 §9）。实现者不得在协调者记录人审前开工。**

## 0. 切片与排期裁定（协调者记录，2026-09-16）

人的原话（本片动机）：

> 结束战斗有 8 条路径之类的问题是不可接受的，先把之前改存档时碰到的管线问题收束到同一条主路径上

1. **本片先做**（状态迁移管线收束）；**存档切片继续停放**：`docs/save-fixed-points.md` 状态＝暂停，
   代码半成品在 `git stash`（`stash@{0}`），**不并进本片**。
2. 收束完成后，固定点存档的判定应**挂在收束后的主路径上**（届时不再需要"比 `floor`／比 `phase`"的探测）——
   已在 `save-fixed-points` 写入"待迁移收束后按主路径重新规划"，并把其 P1／P2／P3 标注为**待重写**。
3. 本片的**现状图与目标表对照基准**＝`docs/save-fixed-points.md` §2.5 的 53 点扫描全集（A／B／C／D／T 分类）。

## 1. 领域与问题（现状，来自 53 点扫描）

| 类 | 现状点数 | 现状问题 |
| --- | --- | --- |
| 结束战斗 | **13 个引用点／8 个语义入口** | `_finish_battle` 本体、`_finish_if_saturated`（`:709`，含自递归）、`_start_round`（`:600/608`）、`_enemy_phase`（`:1126/1166/1167`）、`dispatch`（`:2392/2397`）、`_execute`（`:2565`）、`_end_turn`（`:2810`）各自判断"战斗是否结束"；**收押（`Guard.capture:113`）甚至不经过 `_finish_battle`**，直接写 `phase="captured"` |
| 阶段迁移 | **26 个 `state.phase=` 赋值点** | 27 个函数各自写阶段；同类迁移（如"结束整备"）分散在 `_finish_preparation` 的 3 个分支与其它路径；**无法回答"这次提交发生了什么迁移"** |
| 房间／楼层迁移 | **10 个 `state.room=` 赋值点** | 真进层只有 `_depart`／`_advance_travel`→`_arrive_room` 两条；其余为构造期／练习／换塔（4 条事务外＋换塔） |

**目标（人给的判据）**：**同一类状态迁移只能有一条主路径**——判定一处、写入一处、可枚举可检查。

## 2. 切口与接口

### 2.1 落点（优先现有文件；**不新增 core 文件**）

- 全部改动落在 **`core/game.gd`**（主路径与声明表）＋ **`core/guard.gd`**／`core/prison.gd`／
  `core/room_events.gd`／`core/room_services.gd`／`core/departure.gd`／`core/demo_exit.gd`（把各自的
  `state.phase=`／`state.room=` 写入改成调用主路径）。
- **不新增 `core/*.gd`**：E5 物理拆分此前未授权，新增文件须人审；本契约不请求新增。

### 2.2 主路径接口（全仓唯一写入者）

```
# 唯一写 state.phase／state.room 的地方；返回 ""＝成功，否则 issue（保持现有失败字符串风格）
_apply_transition(kind: String, args: Dictionary = {}) -> String

# 唯一战斗结束判定："" ／ "victory" ／ "saturated" ／ "captured"
_battle_end_reason() -> String

# 唯一战斗结束执行（原有实现保留，签名加 end kind；收押也走这里）
_finish_battle(end_kind: String = "victory") -> void
```

- `_apply_transition` 读**声明表** `TRANSITIONS`（§3），按 `kind` 写声明的 `phase`／`room` 字段并记录
  **迁移日志**（仅进程内、内存：`_transition_log: Array[String]`，元素＝`kind`，供 oracle 与测试读取；
  **不进 `state`／不进存档／不进 View**）。
- **立即写入、单一写入者，不做"事务末统一执行"**（拒绝延后）：事务中段会读 `state.phase`
  （例如 `_finish_battle` 之后的同一事务内继续按阶段分支），延后会改变行为；
  本片只收束**判定与赋值**，不改变赋值在控制流中的位置。
- **随机域**：主路径只写 `phase`／`room`（及既有副作用留在原处），**不得新增或减少任何随机消耗**。

### 2.3 与 `dispatch` 事务、回滚、版本与场景起点冻结的关系（不得改变）

| 关注点 | 现状 | 本片 |
| --- | --- | --- |
| 事务边界 | `dispatch`（`var original=state`）→ `state=state.duplicate(true)` → `_execute(...)` → 成功则 `state.version=…`（`:3182`）→ `_commit_scene_start(original)`（`:2441`） | **不变**：主路径在事务副本内被调用（与今天的写入点相同） |
| 失败回滚 | 任一 issue → `state=original`，不留部分变化 | **不变**：`_apply_transition` 返回 issue 时同样由既有回滚路径处理；不得新增"部分写入后再报错"的路径 |
| `version` 递增 | 成功提交时一次 | **不变** |
| `_commit_scene_start` | 场景键变化才重冻 | **不变**；本片不消费迁移日志，只为将来（存档切片）留出挂点 |

## 3. 迁移声明表（目标形态）

`const TRANSITIONS={kind:{"phase":String,"room":bool,"tx":bool,"owners":Array[String]}}`
（`tx=false`＝构造／练习等事务外路径；`room=true`＝该迁移允许改当前房间）。**每个 kind 有唯一实现分支**。

| kind | 判定条件（触发者） | 目标 `phase` | 可改 `room` | 收束前散落点 → 收束后 |
| --- | --- | --- | --- | --- |
| `battle_start` | `_start_battle`（`_arrive_room`／练习） | `battle` | 否 | `:470` → 主路径 |
| `battle_end_victory` | `_battle_end_reason()=="victory"` → `_finish_battle("victory")` | `reward`（事件战＝`event`） | 否 | `:690/698` → 主路径（实现仍在 `_finish_battle`，写入经主路径） |
| `battle_end_saturated` | `_battle_end_reason()=="saturated"` → `_finish_battle("saturated")` | `reward` | 否 | `:600/608/1126/1166/1167/2392/2397/2565/2810/712/726` 的**判定**合并为 `_battle_end_reason`，调用位点保留 |
| `battle_end_captured` | `Guard.capture` 判定收押 → **经主路径**执行 | `captured` | **是**（`prison`） | `guard.gd:113/117` → 主路径（收押副作用仍在 `Guard.capture`，顺序不变） |
| `prepare_start` | `_start_preparation` | `prepare` | 否 | `:621` → 主路径 |
| `prepare_end` | `_finish_preparation` 的三条分支 | `pack`／`map`／`cleared` | 否 | `:2836/2841/2846` → 主路径 |
| `rest_start` | `_start_rest`／`_begin_rest` | `rest_choice`／`rest` | 否 | `:664/674` → 主路径 |
| `room_enter` | `_arrive_room`（`_depart`／`_advance_travel` 内） | `map`／`cleared` | **是**（当前房间） | `:2992/2996`（＋`:2963/2985` 的房间写入） → 主路径 |
| `travel_start` | `_depart` | `travel` | 否 | `:2969` → 主路径 |
| `prison_enter`／`prison_turn`／`inspection_start`／`prison_exit_battle_start` | `prison.gd` 的 `enter`／`begin_turn`／`end_turn`／`execute` | `prison`／`prison_end`／`inspection`／`battle` | **是**（`prison`／`prison_start`／`prison_gate`） | `prison.gd:190/207/221/381/446/148/444/584` → 主路径 |
| `event_enter`／`event_leave_empty` | `room_events.start` | `event`／`map` | 否 | `room_events.gd:22/28` → 主路径 |
| `event_item_rewards` | `begin_item_rewards` | `reward` | 否 | `room_events.gd:1060` → 主路径 |
| `shop_enter` | `room_services.start` | 房间 `kind` | 否 | `room_services.gd:7` → 主路径 |
| `departure_start`／`departure_end` | `Departure.start`（构造期）／`Departure.execute` | `departure`／`map` | 否 | `departure.gd:21/101` → 主路径（`tx=false`／`true`） |
| `tower_restart`／`practice_init`／`setup_init` | `_restart_tower`／`_start_practice`／`_init` | `map` 等 | **是** | `:243/272/278/331/356/365` ＋ `demo_exit.gd:36`／`prison.gd:453/545` → 主路径（`tx=false`，换塔类） |

**谁不允许再直接赋值**（本片的硬线）：

> **`state.phase=`／`state.room=` 只允许出现在 `_apply_transition` 内。**
> 其余 52 个点全部改为"调用 `_apply_transition("<kind>", {...})`"，副作用（生成敌人、滚奖励、
> 收押清理、牢房初始化等）**留在原函数、原顺序**。

## 4. 闭环检查（散落回归的防线；沿用 `save-fixed-points` §2.5 的式样）

- **扫描**：`core/**/*.gd`，`#` 之后为注释（不计入），排除 `==`；四组模式：
  ① `state.room=`／`g.state.room=` ② `state.phase=`／`g.state.phase=` ③ `_finish_battle(`／
  `_finish_if_saturated(`／`_battle_end_reason(` ④ `_restart_tower(`。
- **双向比对**：扫描集 ⊆ 声明表 **且** 表内每一点都被扫到；**表外或未命中都打印 `文件:行:函数`**。
- **收束后的期望规模**：①1 点（`_apply_transition` 内）②1 点（同处）③13 个调用位点（全部调用
  `_battle_end_reason`／`_finish_battle`，不得再有 `_all_gone()` 式独立判定；`_finish_if_saturated`
  改为 `_battle_end_reason` 的薄封装或删除）④3 个调用位点（`demo_exit`／`prison`×2，经 `tower_restart`）。
- 落 `tests/architecture_cases.gd`（`architecture` 类）具名 check `transition_write_sites_are_pinned`。

## 5. Gherkin（场景名 → 既有分类的具名 check；**全部走真实公开命令**）

驱动方式：取候选（`candidates()`）→ `dispatch(candidate_id, version)`；**不得直接调
`_apply_transition`／手工改 `state.phase`** 来伪造迁移。

01. `battle_end_single_path_for_all_entry_points`（`core`／`battle_saturation`／`rewards`）
    Given 八类战斗结束入口各自的可构造夹具（普通最后一击／`end` 后全灭／空间耗尽／事件战胜利／
    监狱出口战胜利／收押／`_enemy_phase` 内全灭／`dispatch` 后全灭）；
    When 逐个真实提交；Then 每次迁移日志恰有一条 `battle_end_*`、目标阶段与今天相同、
    `_finish_battle` 只被调用一次、**收押也走同一路径**（迁移日志同为 `battle_end_captured`）。
02. `prepare_end_three_branches_one_kind`（`core`／`rewards`）
    Given `prepare` 中的三种结束方式；Then 迁移日志均为 `prepare_end`，目标阶段分别 `pack`／`map`／`cleared`。
03. `floor_enter_is_one_family`（`core`／`tower`）
    Given 同层换房与跨层移动（含多回合 `travel_step` 落点）；Then **同层不产生 `floor_enter`**、
    跨层产生恰一条 `floor_enter`，且 `room` 变化只出现在该迁移内。
04. `capture_routes_through_the_main_path`（`guard`／`prison`）
    Given 收押夹具；Then 迁移日志含 `battle_end_captured`、`phase`／`room` 与今天逐字节相同、
    收押副作用（能量归零、无力化、牢房初始化）顺序不变。
05. `non_transitions_do_not_write`（`core`／`services`／`events`）
    Given 代表性非迁移提交（打牌／结束回合中未全灭／商店交易／事件选择／牢房行动）；
    Then 迁移日志为空、`state.phase`／`state.room` 未变。
06. `transition_log_never_reaches_state_or_view`（`persistence`）
    Given 任一迁移；Then `export_snapshot()`／`get_view()`／存档不含迁移日志。
07. `transition_write_sites_are_pinned`（`architecture`，见 §4）
08. `demo_end_and_tower_restart_use_declared_kinds`（`tower`／`tower_progression`）
    Given demo 结束与返塔／出口继续；Then 迁移日志为 `tower_restart`／`cleared` 等已声明 kind，
    且目标阶段与今天相同。

## 6. 判据与 oracle（**不接受"测试绿了就算"**）

**(a) 既有分类套件**（本片动核心状态机，取覆盖面更大的一次）：

```powershell
& tools/check.ps1 -Suite core,rewards,battle_saturation,guard,prison,tower,tower_progression,events,event_flow,persistence,architecture -Impact -KeepGoing -TimeoutSeconds 900
& tools/check.ps1 -UIOnly -UISuite persistence,home,events -TimeoutSeconds 900
```

- 红集必须 **⊆ 已知既有项 {`card_power` 5 条, `installed_tools` 1 条, `tower_progression` 10 规则＋1 界面,
  `hand_assist` 1 条}**（均在 `docs/verification.md` 已登记），**不得出现新红**；
  `-KeepGoing` 下若有分类因 `SCRIPT ERROR` 变成 `unrun`，**必须逐分类补跑**，报告列出 `unrun` 清单
  （不得把未跑当通过）。`content/packs` 未改动，**不跑** `check-content.ps1`（非本片范围）。

**(b) 迁移 oracle（新增，参照 E0 的摘要式判据；本片的核心证据）**

- 脚本：`build/transition-oracle-<date>/transition_oracle.gd`（已忽略目录，用完删原始目录、摘要入 `docs/verification.md`）。
- 每个迁移场景**在迁移前后各取一次摘要**：`phase`、`room`、`floor`、`version`、`state.rng`、
  **迁移日志**（新增，来源＝`_transition_log`）、本次提交新增日志的 sha256、`room_event` 摘要。
- 用法与判据同 E0：`--write=` 在**收束前的提交**抓基线，收束后 `--baseline=` 比对；**逐场景逐字段相等**
  才算"行为逐字节不变"；任何红项都要按"契约未更新 vs 行为漂移"定性（不得直接改期望）。
- 场景清单（≥12）：八类战斗结束入口、`prepare_end` 三类、`floor_enter`（跨层）与同层移动、
  `capture`、事件战、监狱出口战、demo 结束、返塔、练习初始化。

**(c) 闭环 check**：§4／场景 07。

## 7. 非目标

- 不改存档格式与语义（`pack`／`unpack`／`snapshot` 校验、`save_revision`）、不改玩家可见文案与数值、
  不改 `ui/**`、不改随机域与消耗、不改 `dispatch` 的事务／回滚／版本／`_commit_scene_start` 语义。
- **不顺手物理拆文件**（不新增 `core/*.gd`）、不并进存档切片（`save-fixed-points` 保持暂停）、
  不实现"固定点存档"的判定（只在主路径留出挂点：迁移日志）。
- 不做全量回归（`-Suite all`）、不打包、不发版。

## 8. 假设与最可能爆掉的假设

1. **最可能爆：把写入路由进 `_apply_transition` 时改了写入的"位置或次数"**——同一提交内出现两次候选
   写入、或写入后立刻被下游读取。缓解：(b) 的迁移前后摘要逐字段比对 + 场景 01–08 覆盖每类入口；
   红了先按"契约未更新 vs 行为漂移"定性。
2. **次可能：收押改道后副作用顺序变化**（`Guard.capture` 现在先写 `phase`／`room` 再做牢房初始化）。
   缓解：主路径只接管 `phase`／`room` 两个字段，其余原样保留；场景 04 逐项断言副作用顺序。
3. **第三：合并"判定"时顺手减少调用位点**，改变随机消耗或日志顺序（例如 `_finish_if_saturated` 被删）。
   缓解：只允许合并**判定**（`_battle_end_reason`），**调用位点保留**；oracle 的 `rng`／日志摘要兜住。
4. **第四：声明表退化为"注释式清单"**（表里写了 kind，代码仍各写各的）。缓解：闭环 check 只放行
   `_apply_transition` 内的两个赋值点，表外即红。
5. **第五：`tx=false` 的构造期路径经主路径后引入新的失败面**（`_init` 里没有 `original` 可回滚）。
   缓解：声明 `tx` 列并只做赋值，不引入新的校验失败；练习／新局由场景 08 与既有套件覆盖。

## 9. 需人确认（`needs-human-review` 的原因）

1. **核心状态机改动**：26 个 `state.phase=`／10 个 `state.room=`／13 个战斗结束引用点全部改道，
   任一疏漏都会改变玩家可见流程或存档内容。
2. **接口改动**：新增 `_apply_transition`／`_battle_end_reason`；`_finish_battle` 加 `end_kind` 参数；
   `Guard.capture` 改走主路径——`core/` 内接口变化需人认可。
3. **跨切片影响**：存档切片（暂停中）的固定点判定将挂到本片的主路径上；本片的迁移日志是
   为它预留的挂点（本片不消费）。
4. **不新增文件的结论**：本契约选择全部落在现有文件内；若人要求拆成 `core/transition*.gd`，
   属新增文件（E5 未授权），需另批。
5. 判据口径：迁移 oracle 需要在**收束前的提交**抓基线（与 E0 同法），因此本片**必须在动手前先落基线**；
   若人不同意冻结该基线，行为不变性就没有可对照证据。
