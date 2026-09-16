# 固定点存档契约（三点式写盘）

规划者契约（planner contract），2026-09-16。基线：分支 `event-pipeline-unification`，提交 `a673352`，
工作区干净。行号捕获于该提交；**函数名是稳定锚点**，动手前用 `rg` 复算。
本文件不写执行结果：通过／失败／未执行只登记到 `docs/verification.md`。

**状态：`needs-human-review`（见 §10）。实现者不得在协调者记录人审前开工。**

**修订记录**：本文件取代 `docs/save-write-skip.md`（"逐操作内容比对"方案，已删）与上一版
"全量触发集"方案。人审原话：**"只有你进入新的一层时存档，完成战斗时存档，完成休整后存档，
其他一律不存，所以不用扫全量了"** —— 故取消全量扫描防线（原场景 07），只留三点＋抽样正反例。

## 1. 领域与切口

领域：存档**写盘时机**。不改存档内容、格式、版本、迁移与回退规则。

**切口（本片全部改动点）**：

1. **进度存档只剩三个固定点**：①进入新的一层；②完成战斗；③完成休整之后（§2）。
   **其他状态迁移一律不写**（换房间、商店、事件房、宝箱、监狱进出与巡视、整备中、demo 结束等）。
2. **删除逐操作写盘**：`ui/main.gd:1923`（`_submit` 的 `if result.ok:` 分支）不再无条件调用
   `_save_progress()`；改为**只在 `dispatch` 结果带检查点信号时**调用（§2、§5.1）。
3. **删除"恢复后立刻写盘"**：`ui/main.gd:291`（`_resume_snapshot` 成功后）不再调用 `_save_progress()`。
   理由：磁盘内容与内存内容语义相同（只有 `restore_snapshot` 抬升过的 `version` 不同），
   写盘只会把 `.bak` 覆盖成当前起点的副本。
4. **不做去重、不新增只读接口**（§5.3）：三点稀疏，重复触发概率低；代价（同一点重复触发时
   `.bak` 被同内容覆盖）可接受。先前获批准但本方案不再需要的 `Game.scene_start_version()` **取消**。
5. 三条**非进度**写盘按显式意图／独立产物保留（§3）。

性能（P0 实测 `build/next-perf/results.json`）：`save` 恒定 39.4–48.8ms／次调用，与装备件数无关；
battle:26 一次成功提交 ≈ dispatch 58.8 ＋ get_view 63.5 ＋ save 44.1 ≈ 166ms。
本片后**场景内提交不再有 save 段**；三个固定点的单次写盘成本不变。

## 2. 三个进度固定点（时机、内容与恢复点）

**统一落点**：`core/game.gd` 的 `dispatch` 成功路径——`var original=state`（`:2335`）之后事务提交，
末尾 `_commit_scene_start(original)`（`:2441`）处 `original`＝提交前状态、`state`＝提交后状态。
检查点判定在同一位置求值（新增私有 `_checkpoint_kind(original) -> String`），
**写盘发生在提交之后**：写的内容是写入时刻的 `restart_snapshot()`（＝提交后的场景起点）。

| # | 固定点 | 确切时机（判定条件，锚点） | 写入内容 | **预期恢复点** |
| --- | --- | --- | --- | --- |
| P1 | **进入新的一层** | **同一座塔内**当前房间 `floor` ≠ 提交前（`room_data(state.room).floor` vs `room_data(original.room).floor`，**任一方向都算**）**且** `tower_generation` 未变；在 `dispatch` 成功、提交后。**换塔／出狱返塔不写盘**（人审裁定）：单纯比 `floor` 会让 `_restart_tower`（塔底 floor 变化）误触发，故必须带 `tower_generation` 不变这一排除项——见 §2.5 枚举与 §10 | 提交后的 `restart_snapshot()` ＋ 当时线稿 | **该层入口**（新层第一个房间的起点） |
| P2 | **完成战斗** | `original.phase` ∈ {`battle`} 且 `state.phase` ≠ `battle`（普通胜利→`reward`、事件战→`event`、监狱出口战→`reward`、被收押→`captured`／`prison_end`）；锚点 `_finish_battle`（`core/game.gd:683-707`）把 `battle` 改写为 `reward`／`event`；提交后 | 同上 | **战斗结束后的阶段起点**（奖励／事件结果／收押结果） |
| P3 | **完成休整之后** | `original.phase=="prepare"` 且 `state.phase!="prepare"`（离开整备：结束回合用尽、提前结束、进入下一场景）；提交后 | 同上 | **整备结束后的起点**（下一步行动前） |

- 三者互斥判定，同时成立时**取优先级 P2 ＞ P3 ＞ P1**（并要求抽样夹具覆盖这一并集不产生歧义）。
- `dispatch` 成功字典新增**加性**键 `"checkpoint"`，取值 `""`／`"floor"`／`"battle_end"`／`"prepare_end"`；
  未命中时为空串（键存在但为空，或省略——实现时二选一并在报告里写明，判据按 §5.1 的取法）。
- **"完成休整"的用词（须人确认，§10 第 1 条）**：本契约按实现现状取 **`prepare`（战后整备）**——
  游戏的阶段名是"战后整备"与"休息"，代码与文案里**没有"休整"一词**（`rg -n 休整 data/ ui/ core/` 零命中）。
  若人指的是休息房（`rest`／`rest_choice`），P3 条件改为 `original.phase ∈ {rest_choice, rest}` 且
  `state.phase ∉ {rest_choice, rest}`，同时 §6 的反例 N9 转为正例。

### 2.5 枚举扫描：三类状态变化各由哪些代码路径产生（静态，2026-09-16 实测）

> 扫描方式：`rg -n "state\.room\s*=[^=]" core/`、`rg -n "state\.phase\s*=[^=]" core/`、
> `rg -n "_finish_battle|_finish_if_saturated" core/`，再逐条回溯一层调用者判断是否在
> `dispatch` 事务内（事务内＝`_execute`／`dispatch` 可达；事务外＝setup／重开／读档）。
> **结论：三类变化全部存在、且绝大多数发生在 `dispatch` 事务内**——所以"边界前后对比"能覆盖它们；
> 仅 setup／重开／读档路径在事务外（按设计不触发检查点，见下）。

**A. 能改变当前房间 `floor` 的路径（`state.room=`／`g.state.room=` 全部命中）**

| 位置（函数） | 是否在 `dispatch` 事务内 | 证据（调用者） | 本契约处理 |
| --- | --- | --- | --- |
| `game.gd:272` `_restart_tower`（含 `:278` 的 phase） | **是**（可由 `prison.gd:453/545` 逃狱／出狱返塔、`demo_exit.gd:36` 出口继续 触发） | `Prison.execute`／`DemoExit` 在事务内 | **不触发 P1**：`tower_generation` 变化被排除（换塔裁定） |
| `game.gd:331/356/365` `_start_practice` | 否（setup） | `_init`／练习入口 | 不触发（新局／练习起点由 T3／T4 或首次固定点覆盖） |
| `game.gd:2963` `_depart`（进入相邻房间） | **是** | `dispatch` → payload `depart` | **P1 候选**（同层不写、异层写） |
| `game.gd:2985` `_advance_travel`（多回合移动落点） | **是** | `_execute` → payload `travel_step` | **P1 候选** |
| `prison.gd:148` `start_practice` | 否（setup） | 练习入口 | 不触发 |
| `prison.gd:444` `escape`（逃狱返塔） | **是** | `Prison.execute` | **不触发 P1**（换塔，同 `_restart_tower`） |
| `prison.gd:584` `exit_practice`（练习出口） | 否（练习） | 练习入口／`execute` | 不触发（练习局；若经 `execute` 则落 `_restart_tower` 分支） |
| `guard.gd:117` `capture`（收押入狱） | **是** | `Guard.execute`（敌方阶段） | 不触发 P1（换场所但同层语义；`map_region` 变，`floor` 判据见 §10 第 3 条） |

**B. 能结束战斗的路径（`_finish_battle`／`_finish_if_saturated` 全部命中）**

| 位置 | 是否在事务内 | 证据 | 本契约处理 |
| --- | --- | --- | --- |
| `game.gd:690/698` `_finish_battle` 本体（→`event`／`reward`／`captured` 由 `Guard.capture` 另行设置） | **是** | 调用者：`dispatch`（`:2392`）、`_execute`、`_end_turn`、`_enemy_phase`、`_finish_if_saturated`（`:712/726`）、`room_events` 事件战结算 | **P2 判定点** |
| `game.gd:1167` `_end_turn` 内 `_all_gone()` | **是** | `_execute` → payload `end` | **P2 候选**（结束回合后全灭） |
| `game.gd:2392` `dispatch` 内 `_all_gone()` | **是** | 任意会打死最后一敌的命令 | **P2 候选**（普通攻击／技能） |
| `game.gd:2565`（另一处 `_all_gone()`） | **是** | 事务内 | **P2 候选** |
| `game.gd:600/608/1126` `_finish_if_saturated()` | **是** | 事务内 | **P2 候选**（空间耗尽提前结束） |
| `room_events` 事件战：`Events.finish_battle` → `battle_spec_issue` 路径 | **是** | `_finish_battle` 的 event 分支 | **P2 候选**（事件战） |
| `prison.gd:381` `execute` 内 `phase="battle"`（出口战开始）→ 其结束仍走 `_finish_battle` | **是** | `Prison.execute` | **P2 候选**（监狱出口战） |
| `guard.gd:113` `capture` 设 `phase="captured"`（不经 `_finish_battle`） | **是** | `Guard.execute` | **P2 候选**（收押＝战斗结束，人审已确认） |

**C. 能结束 `prepare` 的路径（`_finish_preparation` 的 3 个分支）**

| 位置 | 是否在事务内 | 证据 | 本契约处理 |
| --- | --- | --- | --- |
| `game.gd:2836` `_finish_preparation` → `pack` | **是** | `_execute`／`_end_turn`（payload `end` 用尽回合、`finish_prepare` 提前结束） | **P3 判定点** |
| `game.gd:2841` → `map` | **是** | 同上 | **P3** |
| `game.gd:2846` → `cleared` | **是** | 同上（练习／阶段完成） | **P3** |

**D. 事务外路径（setup／重开／读档）——不触发检查点，逐条给出理由**

| 路径 | 位置 | 理由 |
| --- | --- | --- |
| 新局初始化 | `_init`（`:243` 起） | 尚无"上一个固定点"；由 T3（新局替换不兼容档）落盘 |
| 快速 SL／重开 | `_restart_tower` 经 `restart`／`_quick_sl` 的入口 | 内容等于正在恢复／重建的起点；恢复后不写（§1 第 3 条） |
| 读档 | `restore_snapshot`（`:3184`） | 磁盘内容与内存语义相同，写盘只会污染 `.bak` |
| 练习初始化 | `_start_practice`／`Prison.start_practice` | 练习局；起点由 T4（手动）或首个固定点覆盖 |

## 3. 非进度写盘（按显式意图／独立产物保留）

| 触发 | 位置 | 什么时候发生 | 写什么 | 与恢复粒度 |
| --- | --- | --- | --- | --- |
| **T3 新局替换不兼容档** | `ui/main.gd:1965` `_save_progress(true)`（保留） | 用户在主页明确开始新局／替换不兼容档 | 当时的 `restart_snapshot()`（＝开局起点）＋线稿 | 进度的**起点**；去掉会让旧档用户开不了局 |
| **T4 手动"保存场景起点"** | `ui/main.gd:2682` 按钮 `func(): _save_progress();…`（保留） | 玩家显式点击 | 当前 `restart_snapshot()`＋线稿 | 只是把**当前场景起点**落盘，不改变恢复点语义 |
| **T2 地图线稿变更** | `ui/main.gd:1636` `graph.drawings_changed.connect(_save_progress)`（保留） | 玩家在塔路图上画／擦 | 当前 `restart_snapshot()`＋**最新线稿**（独立产物） | **不改变恢复点**（内容仍是当前场景起点），但不写会丢玩家批注 |

三条都**不是进度固定点**：它们不增加恢复点数量，只保证"起点＋批注"这类内容不丢。

## 4. 人可见后果（**须人确认**，本次产品取舍）

1. **恢复粒度变粗**：今天每次成功提交都写"当前场景起点"，崩溃／退出后回到**当前场景**开头；
   新方案只写三个点，崩溃／退出后回到**三者中最近的一个**——本层入口／上一场战斗结束／上次整备结束。
   即：**场景内（战斗中途、整备途中、房间之间）的进度不再保留**，这是本次的有意取舍。
2. `saved_at` 的含义变为"**上次固定点写入时间**"（不再是"上次点击"）。
3. `.bak` 稳定持有**上一次固定点内容**（不再被空写覆盖），主菜单"继续"在损坏时回退到它。
4. 存档文件在主菜单里的"摘要时间"更新频率明显下降（只在三点、手动保存与画线时变化）。

## 5. 接口与行为契约

### 5.1 `dispatch` 结果新增检查点键（加性；须人确认）

- 成功字典新增 `"checkpoint"`（`""`／`"floor"`／`"battle_end"`／`"prepare_end"`）；既有键与顺序不变。
- UI 取法：`if result.ok and String(result.get("checkpoint","")) != "": _save_progress()`；
  **不做任何内容比较、不读快照**。

### 5.2 无签名变更

- `_save_progress(replace_incompatible=false)` 与 `write_game(game, replace_incompatible=false, map_drawings={})`
  **签名与参数保持现状**（本方案无需 `force`、无需去重令牌）。
- `ui/main.gd` 的 `_save_progress` 调用点收敛为四处：T1（`_submit` 内、带检查点条件）、T2、T3、T4。

### 5.3 取消的接口与机制（明确记录）

- `Game.scene_start_version()`：**先前获批准，但本方案不再需要**——理由＝三点稀疏，重复写概率低，
  不引入去重就不需要"上次写的起点版本"这一信号；取消可减少一处跨模块只读接口。
  代价：同一固定点被触发两次时第二次会照写，把 `.bak` 覆盖成**同内容副本**（可接受）。
- 内存令牌 ＋ `size`／`mtime` 每操作比对：**取消**（那是"操作检查"路线，已被推翻）。

### 5.4 保留（不得弱化）

- 失败路径与全部文案（`"保存失败：…原存档保留。"`／`"保存已暂停：原存档版本不兼容…"`／
  slot 非法／大小超限／回读校验失败）；`docs/response-pipeline.md` §7 与既有 `save_failed`／
  `save_suspended` 语义；`pack()`／`unpack()` 的格式与校验；`restart_snapshot()` 的冻结时机；
  `read_slot` 的回退规则与 `summary()` 的可用性语义；`.bak` 顺序（先 `copy 主→.bak`、后 `rename tmp→主`
  ⇒ `.bak`＝写入前的主档＝**上一次固定点内容**）。

## 6. Gherkin（场景名 → 既有分类的具名 check）

落在 `tests/persistence_cases.gd`（`persistence`）、`tests/persistence_ui_cases.gd`（UI `persistence`）；
复用隔离存档目录与真实夹具，不新建流程文件。

**正例（必写，逐点一条，含恢复点断言）**

01. `save_writes_on_new_floor`（`persistence`）
    Given 已在某层保存；When 走进**新的一层**（含上一层的相邻房间不触发）；Then 写盘、
    `.bak`＝写入前主档、主档 `unpack` 的 `room`＝新层入口房间、`floor`＝新层；
    读该档后 `phase`／`room` 与该层入口一致（**恢复点＝该层入口**）。
02. `save_writes_when_battle_finishes`（`persistence`）
    Given 战斗中；When 战斗结束（普通胜利→`reward`、事件战→`event`、监狱出口战→`reward`、
    被收押→`captured`／`prison_end`，四类各一例）；Then 每次写盘，且主档 `phase` 等于结束后的阶段
    （**恢复点＝战斗结束后的阶段起点**）。
03. `save_writes_when_prepare_finishes`（`persistence`）
    Given `phase=="prepare"` 且已保存过；When 整备结束（回合用尽／提前结束／进入下一场景）；
    Then 写盘，主档 `phase` ≠ `prepare`（**恢复点＝整备结束后的起点**）。

**反例（必不写，抽样清单；判据＝主档与 `.bak` 的字节与 mtime 均不变、且未调用 `write_game`）**

04. `save_skips_representative_non_points`（`persistence`，测试侧包装 SaveStore 子类计数，生产无计数器）
    逐条抽样（每条一次提交）：
    N1 战斗内打出一张牌｜N2 战斗内结束回合｜N3 战斗内翻面／查看（UI 本地态，不进 dispatch）｜
    N4 同层换房间｜N5 进入商店并完成一次交易｜N6 进入事件房并选择一次｜N7 宝箱房领取一次｜
    N8 监狱内巡视／牢房行动｜N9 休息房内行动与休息回合推进（**若"休整"指休息房则转正例，见 §10**）｜
    N10 demo 结束（`cleared`／`demo_end`）｜N11 读档成功（`_resume_snapshot` 后不写）｜
    N12 换塔／出狱返塔（`tower_generation` 变化，人审裁定不算进入新的一层）。
05. `save_writes_on_explicit_and_drawing_paths`（UI `persistence`）
    Given 内容未变；When 走 T3（新局替换不兼容档）、T4（手动按钮）、T2（画一笔线稿）；
    Then 三者都写盘；T2 写后主档内容仍是**当前场景起点**＋最新线稿（恢复点不变）。

**回退与契约（保留不得弱化）**

06. `save_backup_holds_previous_fixed_point`（`persistence`）
    Given 固定点 A → 固定点 B → 场景内若干次提交（不写）；When 主档被破坏；
    Then `read_slot` 回退到 `.bak`（`backup=true`），其字段等于 **A**（不是 B 的副本），且能经正式入口继续。
07. `save_format_and_failure_contract_unchanged`（`persistence`）

**闭环 check（机器可执行；`architecture` 分类的源码扫描；取代旧版"扫 `_scene_start`"）**

08. `save_transition_sites_are_enumerated`（`tests/architecture_cases.gd`，`architecture`）
    Given 读取 `res://core/` 下的 `.gd` 源文本；When 提取
    ① `state.room\s*=`／`g.state.room\s*=`（排除 `==`）② `state.phase\s*=`／`g.state.phase\s*=`（排除 `==`）
    ③ `_finish_battle(`／`_finish_if_saturated(` ④ `_restart_tower(` 的**全部赋值／引用点**；
    Then 每个点必须落在 §2.5 的表 A／B／C／D 中（**表外即红**，打印文件:行:函数）；
    **新增任一能改 `floor`／`phase` 或结束战斗的路径，必须同批更新 §2.5 的表与 Gherkin 映射**。
    （与旧版的区别：旧版扫 `_scene_start` 赋值点，只能证明"冻结点没变多"；本版扫**能造成三类状态变化的
    赋值点**，直接回答"进新的一层是否同一个方法"。）

**触发点 → 命令／方法 → 具名 check 映射（正向抽样必须按此表驱动）**

| 触发点 | 产生的命令（`dispatch` payload）／方法 | 具名 check |
| --- | --- | --- |
| P1 进层（相邻房） | `depart` → `_depart` → `_arrive_room` | 01 `save_writes_on_new_floor` |
| P1 进层（多回合移动） | `travel_step` → `_advance_travel` → `_arrive_room` | 01 |
| P1 反例（同层换房） | `depart`（同层） | 04 N4 |
| P1 反例（换塔） | 逃狱／出狱返塔（`Prison.escape`→`_restart_tower`）、出口继续（`DemoExit`） | 04 N12 |
| P2 打完最后一敌 | `attack`／体术／法术等任意造成最后一击的候选 | 02 |
| P2 结束回合后全灭 | `end`（`_end_turn` 内 `_all_gone()`） | 02 |
| P2 空间耗尽 | 任意事务内触发 `_finish_if_saturated()` 的候选 | 02 |
| P2 事件战结束 | 事件战胜利（`Events.finish_battle` 分支） | 02 |
| P2 监狱出口战结束 | 监狱出口战胜利（`Prison.execute`） | 02 |
| P2 收押 | 敌方阶段 `Guard.execute` → `Guard.capture` | 02 |
| P3 整备回合用尽 | `end`（`prepare` 中）→ `_finish_preparation` | 03 |
| P3 提前结束整备 | `finish_prepare` | 03 |
| P3 离开整备进入下一场景 | `finish_pack`／离开类候选 → `_finish_preparation` | 03 |

**运行时证据要求（交给实现者；不由本契约代跑）**

- 每个正例必须由**真实命令路径**产生：先取候选（`candidates()`）再 `dispatch(candidate_id, version)`，
  断言 `result.checkpoint` 的取值与磁盘写入（mtime／字节／`.bak`）；**不得直接调用
  `_checkpoint_kind` 或手工设置 `state.phase`／`state.room` 来伪造触发**。
- 若某条路径无法经公开命令触达（例如需要特定种子／特定敌人组合），报告必须写明**原因**与
  **替代证据**（例如由该路径的上级命令 + 夹具状态构造，并标注哪些断言因此不覆盖）。
- §2.5 中标注"事务外"的四条路径同样需要证据：证明它们**不写盘**（内容未变时 mtime 不变），
  或在报告中说明为何不可触达（如快速 SL 需真实存档往返）。
    Given 各类失败前置（`persistence_enabled=false`／`save_suspended`／`validate()` 失败／slot 非法／
    大小超限／不兼容旧档）；Then 返回值与文案逐字相同、`pack`／`unpack` 格式与 `read_slot` 回退规则不变。

## 7. Validator procedure（agent 可运行；真实输入）

宿主入口：`tests/test_game.gd`（规则）＋`tests/ui_smoke.gd`（界面）＋`tools/check.ps1`；
测试存档隔离，不读写玩家存档，不默认截图。

1. 范围预检（不算通过）：`& tools/check.ps1 -Suite persistence,architecture -Impact -ListOnly`；
   `& tools/check.ps1 -UIOnly -UISuite persistence,home -ListOnly`。
2. 规则门：`& tools/check.ps1 -Suite persistence,architecture -Impact -TimeoutSeconds 600` → 退出码 0，
   `status=passed` 且 `before==after` 指纹（`source_changed` 不算通过）。
3. 界面门：`& tools/check.ps1 -UIOnly -UISuite persistence,home -TimeoutSeconds 900` → 退出码 0
   （**900 秒是硬要求**：默认 300 秒在负载下会被中途中止）。
4. 人的路径证明（判据是套件的布尔 check；按顺序在真实界面上操作）：
   - 战斗内点若干张牌、结束回合 → 存档文件与 `.bak` 的 mtime 不变；
   - 打赢这一场 → 主档更新（`.bak` 变为上一个固定点），主页"继续"回到**战斗结束后的起点**；
   - 走完整备 → 主档更新；再在整备中做若干操作 → 不再更新；
   - 走到新的一层 → 主档更新，恢复点＝**该层入口**；
   - 在塔路图上画一笔 → 写盘（进度恢复点不变）；重进同一地图不画 → 不写；
   - 手工破坏主档 → 主页"继续" → 回到**上一次固定点**且状态完整；
   - 全程不打包、不发布。
5. 失败路径复核：失败／暂停／被拒的提示与行为与改动前逐字一致（以既有断言为准，不新增文案）。
6. 归属判定：失败先分"实现代码／测试脚本／环境／程序本身"；不确定保持未分类上报，不自动改产品代码。
7. 证据：`build/checks/<id>/check-rules.log`、`check-ui.log`、`summary.json`；结果与域写
   `docs/verification.md`（validator 负责，不在本契约宣称通过）。

## 8. 完成定义（DoD）

```powershell
& tools/check.ps1 -Suite persistence,architecture -Impact -TimeoutSeconds 600
& tools/check.ps1 -UIOnly -UISuite persistence,home -TimeoutSeconds 900
```

- 必过的场景：§6 的 01–07 全部具名 check；`persistence`／`architecture` 全 PASS；界面门 PASS。
- 必有的证据：两份 check 日志＋`summary.json`（`status=passed`、指纹稳定）；
  既有失败路径断言逐条保留（**不得**为绿灯改文案或删断言）。
- **性能判据（沿用 `docs/equipment-performance.md:45` 配对协议）**：0／12／26 件 × battle／departure 夹具，
  2 次热身＋15 次有效配对，报**逐对比值中位**与两侧独立中位；口径：
  ①**场景内提交的 `save` 段＝0**（由 §6 场景 04 的"未调用 `write_game`"与 mtime／字节断言立证），
  同夹具下总耗时下降量照报；
  ②三个固定点的单次写盘成本**照报**（不设下降目标，它本来就是必要的）；
  ③不得以"应该更快"、单次采样或拼接历史数字宣称收益；计时脚本与 JSON 只放已忽略的
  `build/<topic>-<date>/`，摘要（机器／夹具／件数／中位／样本数）进 `docs/verification.md` 后删除原始目录；
  生产源码不得留计数器或计时钩子。
- 算未完成（任一）：任一必跑命令未执行／失败／未知或跳过；`summary.json` 为
  `source_changed`／`failed`／`plan`；为绿灯弱化失败路径断言或改写既有文案；
  三个固定点任一漏写或写错时机（场景 01–03 红）；抽样反例里任一发生写盘（场景 04 红）；
  场景内仍有写盘；`dispatch` 的检查点键让既有键集合或顺序发生变化；
  新增生产文件、改 `pack()`／`unpack()` 格式与校验、改 `restart_snapshot()` 冻结时机、
  改 `read_slot` 回退规则；宣称完整回归或打包。

## 9. 依赖约束

- 允许改动：`core/game.gd`（`_checkpoint_kind(original)`＋`dispatch` 成功字典加 `checkpoint` 键）、
  `ui/main.gd`（删 `:1923` 与 `:291` 的写盘；`_submit` 改为按检查点调用；T2／T3／T4 保持）、
  `tests/persistence_cases.gd`／`tests/persistence_ui_cases.gd`、`build/` 下一次计时脚本（不入库）。
- **不改**：`core/save_store.gd`（本方案无需改动）、`pack()`／`unpack()` 格式与校验、
  `restart_snapshot()` 冻结时机与返回语义、`write_game` 的既有分支顺序与失败文案、
  `core/snapshot.gd`、`assets/localization/**`、`ui/route_map.gd`（线稿信号保持）、其它契约。
- 依赖方向：`ui/main.gd → core/{Game,SaveStore}`（既有边）；`core/game.gd` 内部新增一个私有判定。
  **不新增模块依赖、不新增生产文件、不新增只读接口。**

## 10. 需人确认（`needs-human-review` 的原因）

1. **"完成休整"的所指——已裁定：＝战后整备（`prepare`）**，P3 条件与"休息房内行动不写"（反例 N9）
   **按契约现取不变**。备注：代码与玩家文案里**没有"休整"一词**（`rg -n 休整 data/ ui/ core/` 零命中），
   取 `prepare` 由人确认；§2 末段的"若指休息房"替换写法保留为历史备选，不再是待决项。
2. **被收押是否算"完成战斗"——已裁定：算。** P2 现取不变（`battle→captured`／`prison_end` 计入写盘）；
   若将来要排除，P2 条件加一个排除项即可。
3. **换塔／出狱返塔是否算"进入新的一层"——已裁定：不算。** 换塔不写盘，恢复点仍为**上一次固定点**
   （反例清单 N12）。**枚举后的必要细化（需人确认一句话）**：P1 的条件是
   "同一座塔内 `floor` 不同 **且** `tower_generation` 未变"——因为 `_restart_tower`（逃狱／出狱返塔／
   出口继续）走的是 `dispatch` 事务内路径并会改 `floor`（塔底），**只比 `floor` 会与人审裁定冲突**；
   加这一排除项是执行人的裁定，不是新增语义（§2.5 表 A 已列证据）。
   **待否决的解释**：`floor` 变化按**任一方向**都算（上行也触发），最贴近"进入新的一层"的字面；
   若人反对，改条件即可（例如只算上行）。
9. **全量扫描已按人审重新纳入**（§2.5 枚举 ＋ 场景 08 闭环 check）：它回答"每个触发点由哪些方法产生、
   是否在 `dispatch` 事务内"——结论是**三类变化全部存在且绝大多数在事务内**（仅 setup／重开／读档在事务外，
   按设计不触发）；三条"事务外"路径（快速 SL／重开、读档、练习初始化）各自的理由见 §2.5 表 D。
4. **恢复粒度变粗**（§4）：崩溃／退出后只能回到三个点中最近的一个——本次产品取舍，需人认可。
5. **`dispatch` 新增 `checkpoint` 键**（加性）：属接缝 A 的返回形状变化，需认可。
6. **取消 `Game.scene_start_version()`**（先前获批准、本方案不需要）与**取消去重**（§5.3）。
7. **非进度写盘三条保留**（§3）：新局替换／手动按钮／线稿——按显式意图与独立产物保留；
   若人要求"零额外写盘"，应删手动按钮（属另一决定，本契约不预设）。
8. 交付形态：只出本契约一份文件；实现范围＝§9 的允许改动清单。

**已接受、不再待决（人审 2026-09-16）**：三条非进度写盘保留（T2／T3／T4）、不新增只读接口（取消 `scene_start_version()`）、`core/save_store.gd` 不动、判定用 `dispatch` 的加性键 `checkpoint`、恢复粒度变粗（§4）、判据命令与性能判据（§8）。**本契约自此无待决项，仅余第 3 条的"任一方向"解释待可被否决。**

## 11. 假设与最可能爆掉的假设

1. **最可能爆：三个判定条件与真实迁移对不上**（例如整备结束其实经过 `reward`／`pack` 中转、
   或事件战结束时 `phase=="event"` 但玩家仍在事件里）。缓解：§6 场景 02／03 对每类结束各给一例
   （含监狱出口战与事件战），并断言**写后主档的阶段**就是恢复点所在阶段；红了先按 A22 口径
   在引入点之前重跑同一套件定性，再改判定。
2. **次可能：进入新层被写成"每次换房间"**（`floor` 取错房间／跨层移动分多步提交，
   中间步的 `floor` 已在变）。缓解：条件用"提交前 vs 提交后当前房间的 `floor`"并在场景 01
   同时给"同层换房不写"的反例（N4）。
3. **反例抽样里的"同层换房间"可能经过 `travel` 多回合**：若某一步的提交把 `phase` 从 `battle` 之类
   变成别的（跨场景），需按 P2／P3 的严格条件核对——抽样夹具必须打印提交前后 `phase`／`room`／`floor`，
   便于定位（不新增生产日志）。
4. **线稿写入与进度写入共用同一文件**：线稿写会把"当前场景起点"一起写入——这是**有意**的
   （文件内容始终是"起点＋最新线稿"），但意味着画线也会刷新主档；若人认为画线不应触碰主档，
   需把线稿拆成独立文件（属新切片，不在本片）。
5. **`_checkpoint_kind` 的优先级**（P2＞P3＞P1）在真实路径里若出现并发命中（一场战斗结束同时换层），
   断言会依赖优先级；实现需在报告里给出该类路径的实测取样。
6. 若人认为"三点之外（如商店交易后）也必须保留"，恢复粒度目标会被推翻，需回到 §10 重裁。
