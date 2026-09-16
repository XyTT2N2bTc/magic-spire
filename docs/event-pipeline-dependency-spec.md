# 事件管线统一：依赖规范（cleaner／架构分类的检查对象）

规划者契约（planner contract），2026-09-16，与 `docs/event-pipeline-unification.md` 同批交付；
人审已通过（记录见该文件文件头与 §13）。清理器在 B1–B4 之后按本文件检查；
本文件与架构分类的具名 check 冲突时，**以本文件为准**，改规则须走协调者。

行号／函数名以落地时的仓库为准；**函数名与稳定 id 是锚点**。

## 1. 允许的依赖方向

```
data/*  →  core/*  →  ui/*
```

- `data/*` 只放注册表、数值与纯数据助手；**不得**取 `g`（游戏实例）做规则判定。
- `core/*` 之间允许的边（本片范围内，别的一律禁止）：

| 从 | 到 | 形式 |
| --- | --- | --- |
| `core/room_events.gd` | `data/room_events.gd`、`data/relics.gd` | `preload`（现状两条边，**不得新增**） |
| `core/room_events.gd` | `Game`、`Game.Snapshot`、`Game.SpecialEquipment`、`Game.Application`、`Game.Pressure`、`Game.EquipmentOffers`、`Game.Relics`、`Game.Enemies`、`Game.Tools`、`Game.B`、`Game.Cards`、`Game.Composites`、`Game.Equipment`、`Game.Links`、`Game.CopyRouter` | 经传入的 `g.*` 调用（现状集合） |
| `core/content_catalog.gd` | 各注册表 | 只经 `g.*`（**不 preload 任何 core／data 模块**） |
| `core/snapshot.gd` | `data/phases.gd`（preload）；`g.Events.*`、`g.*` 校验器 | 事件段只经 `g.Events.condition_saved_fields`／`battle_spec_issue`／`item_rewards_issue` 等既有入口 |
| `ui/*` | `core` | 只经 `ui/main.gd` 的 `preload`，且只调用 `get_view`／`dispatch`／`number`／`Prison.*`／`restore_snapshot`／`restart_snapshot`／三个按需只读入口 |

## 2. 禁止的边

1. `core/**` 不得 `preload`、`load` 或书写 `ui/**`（含 `ui/` 路径字符串与 UI 符号名）。
2. `ui/**` 不得读 `game.state`、不得调用 `dispatch` 之外的规则写入口、不得新增 `get_view` 之外的投影入口。
3. `data/**` 不得 `preload` `core/**` 或 `ui/**`；不得持有事件资格判定（条件种类、隐藏／禁用策略）。
4. `snapshot.gd` 不得自带第二套状态条件键集或 kind 清单；必须调 `g.Events.condition_saved_fields(kind)`。
5. `content_catalog.gd` 不得复写条件种类校验与 `mode` 语义；必须调 `g.Events.condition_issue(...)`；
   不得决定"隐藏还是禁用"（那是运行时求值入口的事）。
6. 生产代码（`core/`、`data/`、`ui/`）不得 `preload` `res://tests/**`；测试不得成为生产依赖。
7. 事件模块不得新增对战斗／奖励子系统的调用：现有允许的调用只有
   `g._start_battle()`（事件战斗开始）、`g._finish_preparation()`／`g._start_preparation()`、
   `g.reward_offer(...)`、`g._gain_card/_gain_tool/_cleanup/_emit/_candidate/validate/export_snapshot`；
   **`begin_battle`／`finish_battle`／`room_encounters` 的借用行为（E4）不得改动**。
8. 资格求值只允许一个入口：`probe_choice`／`availability_issue`／`condition_met`／`freeze_choice`
   不得被 `evaluate_option` 之外的 core 函数调用（冻结与投影走 `evaluate_option`）；
   兼容拼写（`availability`／`when`／`hide_when_unavailable`）只允许出现在
   `condition_entries` 与冻结投影两处。
9. 状态条件 kind 字面量只允许出现在 `Events.CONDITIONS` 声明表内。
10. 存档写入：`room_event.chain` 只允许在跨事件跳转时写入；`room_event.options[*].conditions`
    只允许由冻结投影写入；其他模块不得改写这两个键。

## 3. 文件与职责边界

| 文件 | 拥有 | 不得承担 |
| --- | --- | --- |
| `core/room_events.gd` | 事件定义访问（`definition`／`node`／`node_ids`）、节点与链管线（`enter_node`）、单求值入口（`evaluate_option`）、条件声明表与四处派生、冻结与效果执行、候选与投影、战斗桥与道具奖励桥、事件校验 | 内容 JSON 的结构校验（属 `content_catalog`）、存档形状与键集（属 `snapshot`）、UI 文本 |
| `core/content_catalog.gd` | 读取 JSON、作者层 schema 与引用校验、注册表提交 | 运行时资格判定、隐藏／禁用决策、存档键集 |
| `core/snapshot.gd`（事件段） | 存档形状、键集与委派 | 玩家可见资格（不得自己判断"该不该出现"） |
| `data/room_events.gd` | `TYPES` 注册表、卡牌池、`REFUSAL_MANA` | 规则逻辑、条件判定 |
| `content/packs/*.json`、`content/templates/*` | 作者声明 | 运行时状态、脚本、按事件 id 的分支 |
| `tests/*_cases.gd` | 具名 check 与夹具 | 被生产代码引用 |

新增文件（若人另批）：`core/event_conditions.gd` 只拥有声明表与四处派生；`core/event_options.gd`
只拥有求值入口与冻结管线。除此之外本片不得新增 core 文件。

## 4. 可执行检查点

### 4.1 清理器（cleaner）手工命令（只读；发现违规先归因再报协调者）

```bash
# 1) core 不得出现 ui
rg -n "ui/" spire-godot/core/
# 2) 事件相关 preload 边（只允许 data/room_events.gd、data/relics.gd）
rg -n "^const .*=preload" spire-godot/core/room_events.gd spire-godot/core/content_catalog.gd spire-godot/core/snapshot.gd
# 3) 定义访问必须走 node/node_ids：不得直读 stages/start_stage/choices
rg -n "\.stages|start_stage|\.choices" spire-godot/core/
# 4) 资格求值的唯一入口：这些名字不应出现在 evaluate_option/enter_node 之外
rg -n "probe_choice\(|availability_issue\(|condition_met\(|freeze_choice\(" spire-godot/core/
# 5) kind 字面量只允许在声明表内（命中数应为声明表内部的条数）
rg -n "\"(no_chastity_lock|has_relic)\"" spire-godot/core/
# 6) 存档新键只允许在管线里写
rg -n "\"chain\"|\"conditions\"|\"mode\"" spire-godot/core/
# 7) 生产代码不得引用 tests
rg -n "res://tests/" spire-godot/core/ spire-godot/data/ spire-godot/ui/
```

判定：1／7 命中即违规；2 出现新目标即违规；3 只允许定义访问函数内部命中；4 只允许
`evaluate_option`／`enter_node`／`probe`／`probe_cleanup` 命中；5／6 命中位置必须落在
`room_events.gd` 的声明表与冻结投影内。

### 4.2 架构分类的具名 check（按批承载；cleaner 之后由 validator 复跑）

承载批次：B1b＝两条追溯项；B2＝求值入口与声明表两项 + 新键检查的内容半；B4＝新键检查的链半。

| check | 分类 | 承载批次 | 判据 |
| --- | --- | --- | --- |
| `event_dependency_edges_pinned` | `architecture` | **B1b**（B1 已满足其内容，追溯判据） | `room_events.gd`／`content_catalog.gd`／`snapshot.gd` 的 preload 目标集合恰好等于本文件 §1 表列出的集合（多一个或少一个即红） |
| `event_definition_accessors_only` | `architecture` | **B1b**（B1 已满足其内容，追溯判据） | 行为式：`definition`／`node`／`node_ids` 之外取不到节点与选项；非法键（旧 `stages`／`start_stage`）返回空且不抛错 |
| `event_condition_kinds_share_one_declaration` | `architecture`＋`content`＋`persistence` | **B2b**（声明表已在 `60869fc` 落地，缺具名 check） | kind 集合在内容校验／运行时求值／存档校验三处相等；未知 kind 三处一致拒绝 |
| `event_single_evaluation_entry` | `architecture` | **B2b**（求值入口已在 `60869fc` 落地，缺具名 check） | 计数包装：构建一次事件时 `evaluate_option` 的调用次数＝该节点展开出的评估次数；`probe_choice`／`availability_issue` 的调用只来自入口内部（测试侧包装，生产无计数器） |
| `event_pipeline_writes_only_declared_keys` | `persistence` | **B2b（内容半）＋ B4（链半）** | 存档往返后新增键只可能是 `chain`（跨事件跳转时）与 `conditions`（规范拼写内容）；B2b 先断言 **12 份内容一个都不出现**；B4 补 `chain` 的跨事件断言 |

未落地即未完成；本表 5 条与 `docs/event-pipeline-unification.md` §10 的 01–20 是同一批判据，
不得择一执行。

### 4.3 执行现状（2026-09-16）

- B1（commit `d770aea`）：§4.1 的 7 条手工命令已执行——**未新增 preload 边**
  （`room_events.gd` 仍只有 `data/room_events.gd`＋`data/relics.gd` 两条）、`core/` 无 `ui/`、
  生产代码不引用 `res://tests/`。
- B1b（commit `a57dec3`）：`event_dependency_edges_pinned` 与 `event_definition_accessors_only`
  **已落地**（`tests/architecture_cases.gd`），即 §4.2 的前两条追溯 check 已可执行；
  `event_author_manual_lists_current_fields`（`tests/content_cases.gd`）同批落地。
- B2 核心（commit `60869fc`）：产品代码已具备单求值入口与单一声明表；三条 check 的**代码承载仍未落地**
  （测试未写），按上表分派到 **B2b**（`event_condition_kinds_share_one_declaration`／
  `event_single_evaluation_entry`／`event_pipeline_writes_only_declared_keys` 的内容半）与 B4（链半）。
  **B2 因此判定为"核心已落地、本批未完成"**：未落地不是缺口而是未完成项，未完成前不得宣称通过。
