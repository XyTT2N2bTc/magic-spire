# （已归档 · 方向被否 · 不实施）

归档：只读，不是现行指令。本契约经裁定方向错误、不实施，仅留档追溯；同一裁定登记在 `docs/record/verification.md` 的 2026-09-17 卡顿定位条目与 `docs/spec/candidate-delta.md`。

**状态**：协调者 2026-09-17 记录——**人裁定"方向错误"，本契约不实施**，仅作留档与追溯。
**否决理由（协调者转写）**：人判定该方向错误；未给出的替代方向由协调者另行提出待选。
**协调者对"为何可能是错方向"的判读（供后人参考，非人陈述）**：本方案为换取 dispatch 段 40–52% 的一次重建，代价是给**唯一提交入口**增加第二种入参形态、把"取值来源"从核心内部改成"外部提交行＋核心复算"，并**新增一条玩家可见拒绝文案**——用协议面的扩张去换约一次点击 16–20% 的开销，且削弱了"核心是唯一权威"的单一路径叙事。
**替代方向（未定，待选）**：①把成本压回生成侧（生成期共享输入只求一次）；②让核心自己按版本持有/索引刚产出的候选表（注意：项目不变量禁止查询结果跨提交保留，需先裁定该不变量在此处的适用边界）；③UI 侧 `present(dirty)` 局部刷新（缩短窗口）；④不做（接受现状）。

---

# 提交路径去重：单候选复核（submit-dedup）

规划者契约（planner contract），2026-09-17。分支 `event-pipeline-unification`，HEAD `5b13d13`（工作区干净）。
状态：**`needs-human-review`**——理由与需人裁的项见 §9。人审记录进协调者之前，实现者不得开工。**（2026-09-17 归档）：本节为撰写时状态，已废止**（见本文件 :1／:3：已归档 · 方向被否 · 不实施）。

本文件是本片唯一契约：切口与命令面、局部复算的接口边界、拒绝原因清单、Gherkin、
validator procedure、DoD、依赖约束。**不写执行结果**：通过／失败／未执行只登记 `docs/verification.md`。
行号以落地时的仓库为准；**函数名与稳定 id 才是锚点**。

## 0. 领域与已核实事实（契约据此写）

领域：**一次"提交类点击"的提交面**——`ui/main.gd:_submit` → `core/game.gd` `dispatch`。
不含：输入层、`get_view`／投影、`render` 整树、存档、窗口与队列。

已核实（2026-09-17，HEAD `5b13d13`；直接给出的行号供实现者复算用 `rg` 核对）。

**行号漂移提醒**：旧文面常引的 `tests/ui_smoke.gd:508-512`（陈旧提交四条断言）在 HEAD 已是 `:520-524`；
凡引用一律以函数名锚点为准（本片：`_index_boundary_tests`、`_submit`、`dispatch`、`_candidate`）。

| 事实 | 证据位置 |
| --- | --- |
| 一次提交的顺序：`game.dispatch(c.id, view.version)` → 成功后 `game.get_view()` → `render(updated)`；被拒也 `render(updated)`（`get_view` 与 `render` 都是无条件调用） | `ui/main.gd:_submit`（当前 `:1907`；dispatch `:1918`；get_view `:1919`；render `:1938`） |
| `dispatch(candidate_id: String, expected_version: int)`：先 `Consumables.validate_buffs` → `Binding.state_issue` → **版本相等** → `SpecialEquipment.validate` → `Cards.validate` → `RelicEffects.validate`，**再 `for c in candidates()` 找 id**；找不到 → "该行动已经失效，请重新选择。"；`not valid` → 返回 `c.reason` | `core/game.gd:dispatch`（当前 `:2413`-`:2430`） |
| 候选 ID 是 payload 的哈希：`row.id=JSON.stringify(payload).sha256_text().substr(0,24)`；同 payload 在不同版本下 ID 相同 | `core/game.gd:_candidate`（当前 `:1819`），全仓 `sha256_text` 在 core 仅此 1 处 + `core/save_store.gd` 既有 2 处 |
| 重建整表在提交路径上的用途恰好两个：①复核该候选当下存在且 `valid`；②**取出它的 `payload`／`cost`／`mana`／`mana_payment`**（提交面只传 ID） | `core/game.gd:2426-2432` 之后的 `chosen.*` 使用点 |
| 成本事实：battle:26 成功提交 ≈260ms ＝ dispatch 39.4%（其中 `candidates()+pick` 占 dispatch 的 40–52%）＋ get_view 29.1% ＋ render 20.4% ＋ feedback；被拒点击的 dispatch 只占 0.1–0.2% | `docs/verification.md` 2026-09-17「卡顿定位」条目 |
| 提交入口的调用面：`ui/` 只有 **1** 处 `game.dispatch(`（`_submit`）；`tests/**` 与 `tools/release_probe.gd` 共 **522** 处，**全部是 `dispatch(x.id, 版本)` 字符串形态** | `rg -c "\.dispatch\("` 统计 |
| UI 从不改写候选行：全仓唯一对 `*.drag_payload` 的写入是 `ui/main.gd:973`（`button.drag_payload.free=button.free_face`），**拖放载荷是另一个字典**；一切提交入口的候选都由 `ActionIndex`／`Queries.release_candidate(ui.actions,…)` 选回（`_attack_drop_candidate:2158`、`_free_player_candidate:2270`、`_hand_choice`、`quick_release_bar.candidate:80`） | `rg -n "payload\.[a-zA-Z_]+ *= *[^=]" ui/` 恰 1 命中（`drag_payload`）；`rg -n "payload\[[^]]*\] *=[^=]" ui/` 0 命中 |
| 候选行只由既有构造点产出：`core/game.gd:_candidate` 及其调用方（`core/card_effects.gd` 等模块经 `g._candidate`） | `rg "_candidate\(" core/` |

**与文面不符（交协调者指派更新，本片不改这些文件）**：

1. `docs/response-pipeline.md` §3.2／§7 写的"被拒时**仅当** `view.version != game.state.version` 才重同步"**在 HEAD 不存在**：
   `_submit` 无条件调 `game.get_view()`（`:1919`），且 `ui/` 对 `game.state` 的引用为 **0**（`rg -n "game\.state" ui/` 无命中），
   UI 无法求值该条件。实际保护是"core 的版本闸 + notice + 无条件重投影"，本片不依赖也不改这条。
2. 同文件 §3.2 描述的 `commit(c, expected_version)`／§3.3 的 `present(dirty)` 在 HEAD 未落地：`ui/main.gd` 只有 `_submit` 与 `render(snapshot)`。
   本片改的是 `_submit`，不阻塞也不承接该片。
3. 同文件 §2.2／§6.1 的"`card_texts` 无条件全量"已被按需化取代（P0 实测每次 2–4 型），该条已由「卡顿定位」条目登记。

## 1. 切口与非目标

**切口（协调者已定档）**：保留版本检查与六项状态自检；只把提交面上的"整表重建"换成**单候选复核**。

1. 提交面**加性扩展**：UI 可以把**它手上那个候选**（来自上一次 `get_view` 的候选列表）连同版本一起提交；
   `dispatch(c.id, version)` 字符串形态**行为逐字节不变**（测试 522 处、两个 oracle、release probe 全部继续可用）。
2. 核心**不信任** UI 自报的资格与代价：对**这一个**候选，用既有构造路径**局部复算**它必须拥有的字段，**拿复算结果执行**；复算不过按现文案拒绝。
3. 陈旧与伪造仍拒绝：版本不符 → 现文案；候选自报 identity 与复算不一致 → 拒绝（**具名原因**，见 §3.4）。
   `state.version` 只增语义、"被拒不 +1"语义不变。
4. **不得跨提交缓存**；允许复用的范围仅"同一次点击内、版本相等"的那一个候选。
5. 非目标（本片不做）：`get_view`／投影与按需入口；`render`／整树重建与 `present(dirty)`；窗口与输入队列（`docs/response-pipeline.md` 末尾，未排期）；
   候选的生成内容、顺序、ID 与分组；任何数值与既有文案（唯一例外是 §3.4 新增的一条拒绝文案）；存档与固定点；
   六项状态自检与事务语义；输入层（键盘／触摸／拖放）；拒绝呈现通道。

## 2. 命令面契约

### 2.1 `dispatch(target, expected_version) -> Dictionary`

入参第一个位置参数拓宽为 **`String` 或 `Dictionary`** 两种形态（GDScript 无重载，参数不加静态类型或标为 `Variant`）：

| 形态 | 内容 | 处理 |
| --- | --- | --- |
| 字符串（既有） | 候选 ID | **兼容路径**：完全保持今天的代码路径与语义——`for c in candidates()` 全表复核并取出该行。一个字符都不改。 |
| 字典（新增） | 上一次 `get_view` 的候选行（至少含 `id` 与 `payload`；通常就是 UI 手上的整行） | **窄路径**：不调用 `candidates()`／`_build_candidates()`，改为单候选复算与身份校验（§3）。 |

处理顺序（两种形态共用，**顺序不得调换**）：

1. `Consumables.validate_buffs` → 失败返回其 error（不变）；
2. `Binding.state_issue` → 失败返回其 error（不变）；
3. `expected_version != state.version` → `{"ok":false,"error":"状态已更新，请重新选择行动。"}`（不变；**必须在候选处理之前**）；
4. `SpecialEquipment.validate` → `Cards.validate` → `RelicEffects.validate`（不变）；
5. 取候选行（字符串 → 全表复核；字典 → 单候选复算 + 身份校验，见 §3）；
   - 候选不存在／无法复算出该身份 → `{"ok":false,"error":"该行动已经失效，请重新选择。"}`（现文案）；
   - 身份自洽失败或复算内容不等 → 见 §3.4 具名原因；
   - 复算行 `valid=false` → `{"ok":false,"error":复算行.reason}`（现语义、现文案）；
6. 事务（不变）：`state=state.duplicate(true)` → 扣 `cost` → 扣 `mana_payment` → 执行分派（`Events.execute`／`Prison.execute`／`_depart`／`_execute` …）→ 失败整体回滚且不碰 version；
7. 成功 `state.version=int(original.version)+1`（不变）。

- **执行只读复算行**：`chosen` 必须是复算行本身（字典形态）或全表复核取出的行（字符串形态）。
  提交面提供的 `payload`／`cost`／`mana`／`mana_payment`／`valid`／`reason`／`label`／`risk`／`group`／`detail` **一律不进执行**。
- 返回字典形状**不变**（既有键与加性键如 `checkpoint` 保持）；不新增回执。
- 失败路径**不写状态、不 +1、不产生日志与反馈**（不变）。

### 2.2 `ui/main.gd:_submit` 的改法

唯一改动：把 `game.dispatch(c.id, …)` 改为提交**候选对象** `game.dispatch(c, view.version if expected_version<0 else expected_version)`。
其余全部保持：`show_home`／`enemy_feedback` 守卫、`_use_self_card` 分流、`card_motion.positions` 先抓、
`game.get_view()`、`notice=result.error`、成功分支的 `expand_applied`／`checkpoint` 写盘／选择态与抽屉清理／
`render(updated)`／四个反馈调用的顺序与条件。

- `c` 必须是 UI **手上那一行**（`ui.actions`／`view.candidates` 的引用），**不得复制、不得重新 json 序列化、不得改写任何字段**。
- 现有空行守卫（`not c.is_empty()` 等）保持；`_submit` 不新增分支。
- 成功分支的 UI 行为判断现状只用 `c.payload.*`、`updated.*`、`result.*`（不用自报的 `cost`／`valid`／`reason`）——**保持**；
  身份校验保证成功时 UI 手上的 payload 与复算 payload 内容相等，故这些判断可信。
- 失败分支保持现状（notice + 无条件重投影），本片不动 §0 的第 1 条。

### 2.3 保持原样的调用点（不得改动、不得"顺手迁移"）

- `tests/**` 的 522 处 `dispatch(x.id, version)`；`tools/release_probe.gd`。
- 两个 oracle：`build/transition-oracle-20260916/transition_oracle.gd`、`build/event-oracle-20260916/event_oracle.gd`（都用字符串形态）。
- `tests/test_game.gd` 的 `TC-CORE-0002/0003`（伪造 id `"not-real"` 与陈旧版本各自被拒且状态原子不变，`:95-99`）、
  `tests/persistence_cases.gd:607-608`（就地恢复后用旧版本提交必须被拒）、
  `tests/ui_smoke.gd` 的 `_index_boundary_tests` 陈旧提交四条断言（旧文面写作 `:508-512`，当前为 `:520-524`）、
  `tests/test_game.gd:532-538`（改 payload 后按 **id** 提交仍成功、且不采信改值与改费用）。
  这四处**不得删、不得弱化、不得改成字典形态**；字典形态的对应断言是 §4 的 S1／S3。
- `ui/main.gd` 对 core 的其余读取面（`get_view`×4、`number`、`Prison.*`、`restore_snapshot`、`restart_snapshot`、
  `live_card_text`、`candidate_detail`、`Cards.Rules.SPECS`）不变。

## 3. 接口契约：局部复算的边界

### 3.1 必须由核心复算的字段（字典形态）

复算**必须来自产出 `candidates()` 的同一构造调用点**（同一个 `_candidate(...)` 调用及其参数计算），**不得另写第二份公式**：

| 字段 | 说明 |
| --- | --- |
| `payload` | 效果载荷本身。**执行只用复算出的 payload**；效果字段（`free`／`slot`／`target`／`uid`／`type`／`item`／`room`／`damage`／`preview`／`after`／`x`／`mode`／`hand_uid` …）不得由提交面提供 |
| `cost` | 能量费用（含既有的取整／减免／墙体／遗物修正） |
| `mana`／`mana_payment` | 魔力与分摊（`mana`／`temporary_mana`／`flask_mana`，含 `payment=="flask"` 分支） |
| `valid`／`reason` | 资格与拒绝原因（能量／魔力不足、锁定项圈、诅咒眼罩、施法成功率、休息回合不足、道具栏满、贴墙／接触／滑脱等既有来源），并按现语义返回 |
| `id` | 由复算 payload 得出的候选 id |
| `label`／`risk`／`detail`／`group` | 复算行必须是**完整行**（`label` 进日志与 `player_action.label`；`group`／`risk`／`detail` 供显示与后续消费） |

### 3.2 不得采信（不得用于执行、不得用于资格判定）

提交面提供的 `valid`、`reason`、`cost`、`mana`、`mana_payment`、`label`、`risk`、`group`、`detail`、`payload`（作为执行输入）。
"自报 `valid=false`"不构成拒绝理由，"自报 `valid=true`"不构成许可：**资格一律以复算行为准**。

### 3.3 身份判定（字典形态）

1. **自洽**：`target.id == 候选 id 函数(target.payload)`。候选 id 算法只允许一处实现（把 `_candidate` 现有行提取为唯一函数，
   例如 `_candidate_id(payload)`），`_candidate` 与身份校验共用；`rg -n "sha256_text" core/game.gd` 期望**恰 1 命中**。
2. **存在性与内容相等**：以 `target.payload` 为选择键在**当下状态**复算该候选；
   - 复算所得一条且其 `payload` 与提交 payload **内容相等**（键值相等；**键序不参与判定**，不得用 JSON 字符串比较）→ 用复算行执行；
   - 按键命中但内容不等 → §3.4 具名原因；
   - 无任何命中 → §3.4 失效文案。
3. 身份判定之后**不得**再读提交面的任何字段（除 `target` 用于本步）。

### 3.4 拒绝原因清单（字典形态与字符串形态）

| 条件 | 返回 error | 文案归属 |
| --- | --- | --- |
| 版本不符 | `状态已更新，请重新选择行动。` | 现状，不变 |
| 候选身份在当下状态不存在／无法复算出（字符串形态的"找不到 id"也一样） | `该行动已经失效，请重新选择。` | 现状，不变 |
| 字典形态：`id` 与 `payload` 不自洽，或复算内容与提交 payload 不等 | `提交的行动与当前状态不一致，请重新选择。` | **新增的唯一玩家可见字面量**（见 §9 需人裁项 2） |
| 复算行 `valid=false` | 复算行 `reason` | 现状，不变 |
| 五项 `validate` 失败 | 各自 error | 现状，不变 |
| 执行期 issue | `行动未提交：<issue>` | 现状，不变 |

新增字面量只允许由本条判据产生（不得被别的拒绝路径复用），并有断言锁定（S3）。

### 3.5 不变量

- **无跨提交缓存**：不得新增实例字段保存候选行、复算结果、提交面引用或索引；不得用 `version` 当缓存键。
  允许复用的范围仅"同一次调用内、版本相等"的那一条候选，调用结束即释放。
- **复算只读**：不得写 `state`、不得推进 `state.rng`（任一域）、不得产生日志／事件／反馈；由 S4 的 `state` 逐字节相等间接锁定。
- **版本语义**：`state.version` 只在成功提交 +1、`restore_snapshot` 抬升；被拒一律不 +1。
- **原子性**：执行失败整体回滚（`state=original`），不留部分付款／部分装备。
- **机制允许与禁止**：允许的实现形态是"把提交的 payload 当选择键，让**既有构造路径**只产出那一条"
  （例如给构造管线一个"仅此一条"的收窄参数 + 在各分组循环的**廉价前置匹配**处早退）；
  **禁止**为窄路径另写一份"按 kind 分支重算费用／资格"的公式副本。
  判据两条：(a) `in_dispatch` 期间**公共全表入口 `candidates()` 调用数为 0**；
  (b) `in_dispatch` 期间 `_candidate()` 物化的 payload 集合 **⊆ {提交的那一条}**（即不允许"走完整组／整表再在 `_candidate` 里丢弃"）。
  把 `_build_candidates` 参数化为窄构建是允许的（不按名字判），但它同样要满足 (b)。
- **分组覆盖（闭合）**：窄路径必须覆盖 `candidates()` 能产出的**全部 kind**；不允许"未覆盖则静默回退整表"。
  实际做法：在 `tests/architecture_cases.gd` 声明 `SUBMIT_KINDS` 表（部分种子：`attack`／`calm`／`card`／`chain`／
  `demo_continue`／`demo_end`／`depart`／`departure`／`end`／`event`／`finish_pack`／`finish_prepare`／`finish_rest`／
  `flask`／`hook`／`item_discard`／`item_install`／`item_retrieve`／`item_use`／`manual`／`posture`／`prison`／`relic_bundle`／
  `rest_begin`／`rest_card`／`rest_flask`／`rest_rare`／`retain`／`retain_skip`／`reward`／`reward_skip`／`service`／
  `status_toggle`／`surrender`／`travel_step`／`wall_move`）＋ `SUBMIT_KIND_EXEMPT`（每条带理由），
  由 check 双向比对：语料里出现的 kind ⊆ 表 ∪ 豁免，且表内非豁免项都被语料实际覆盖；红则打印 kind 名。
  实现者若发现某 kind 做不到窄路径，**按未完成上报**（禁止静默回退）。

## 4. Gherkin（落既有分类的具名 check；正例必须走真实公开命令）

计数只用测试侧包装（`tests/architecture_cases.gd` 的 fixture 子类式样）；**生产源码不得带计数器**。

复用式样（非强制但推荐）：计数夹具 `extends "res://tests/game_fixture.gd"`，覆盖 `dispatch(target, version)`
置 `in_dispatch` 标志并调用 `super`，在 `candidates()`／`_build_candidates()`／`_candidate(...)` 内按标志计数与记录 payload。

### S1 `dict_submit_rejects_stale_version`（`tests/persistence_cases.gd`，分类 `persistence`）

- Given `Game.new(42)`；`stale=g.candidates()[0]`、`version=g.state.version`、`snapshot=g.export_snapshot()`；
- When `g.restore_snapshot(snapshot)` 后就地恢复，再 `g.dispatch(stale, version)`（**字典形态**）；
- Then `ok=false`、`error=="状态已更新，请重新选择行动。"`、`JSON.stringify(g.state)` 与提交前逐字节相同、version 未再变；
- 反例（同案必过）：同一行在**版本相等**时提交成功（证明夹具不是恒红）。
- 既有 `:607-608` 的字符串形态断言**原样保留**（同一 check 内并列，不改旧行）。

### S2 `dict_submit_ignores_self_reported_cost_and_validity`（`tests/architecture_cases.gd`，`architecture`）

- Given 战斗夹具（0 件与 12 件两档）各取一条 `cost>0` 的卡牌候选与一条 `end` 候选；
- When 复制该行并改写自报字段：`cost=0`、`mana=0`、`mana_payment={"mana":0.0,"temporary_mana":0.0,"flask_mana":0.0}`、
  `valid=false`＋`reason="伪造原因"`、`label="伪造文案"`，再以字典形态提交；
- Then 提交成功且**按复算值**扣能量与魔力（与字符串形态同一结果）、`state.version` 恰 +1、
  新增日志的 `player_action.label/cost/mana/temporary_mana` 与复算行一致（伪造 label 不得进日志）、
  `error` 为空；反例：把 `payload` 的一个效果字段改值 → S3 的具名拒绝。

### S3 `dict_submit_rejects_forged_identity`（`tests/architecture_cases.gd`，`architecture`）

- Given 战斗夹具一条真实卡牌候选行（并另取一条 `attack` 候选重复要点）；
- When 逐项构造：①`payload.damage`（或该 kind 的等价效果字段）改值；②`payload.free` 翻转；③`payload.target`／`payload.uid` 改成不存在对象；
  ④增删 payload 键；⑤`id` 改成与 payload 不符；各以字典形态提交一次；
- Then 每次 `ok=false`、`error` ∈ {`提交的行动与当前状态不一致，请重新选择。`（自洽失败或内容不等）、
  `该行动已经失效，请重新选择。`（该身份在当下状态不存在）}、`JSON.stringify(g.state)` 与提交前逐字节相同、
  `state.version` 不变、无新日志、`resource_feedback`／`card_feedback` 为空；
- 反例（同案必过）：同一行未篡改提交成功。

### S4 `dict_submit_matches_legacy_for_every_candidate`（`tests/architecture_cases.gd`，`architecture`）

- Given 同构造参数的两个夹具实例，第二个的 `state` 取第一个的 `state.duplicate(true)`（沿用 `tests/architecture_cases.gd:661` 式样）；
  `rows=g.candidates()`；
- When 对每条 row：`a.dispatch(row.id,V)`（字符串形态）与 `b.dispatch(row,V)`（字典形态）；
- Then `a`／`b` 的 `ok`、`error`、`checkpoint` 相等，且 `JSON.stringify(a.state)==JSON.stringify(b.state)`；
- 输入域（必须打印覆盖清单与语料条数）：0／12／26 件 × battle（`tests/game_fixture.gd`(42)）与 departure（`core/game.gd`(42)）的
  `card`／`end`／`travel_step`／`depart` **全量**；其余 kind 在 battle／prepare／rest／route／event／reward／prison／shop 夹具里**各取前两条**；
  语料必须覆盖 `SUBMIT_KINDS` 非豁免项（§3.5 的闭合 check 与本用例共用一次语料）。
  若墙钟超出架构套件容忍，只允许按 kind 分层抽样，抽样规则与理由同时写进 check 注释、实现者报告与 `docs/verification.md`。

### S5 `dispatch_success_does_not_rebuild_candidate_table`（`tests/architecture_cases.gd`，`architecture`）

- Given 计数夹具（S4 同一实例）；
- When 用字典形态提交（逐条走 S4 的语料）；
- Then `in_dispatch` 期间公共全表入口 `candidates()` 的调用数**恒为 0**；且 `in_dispatch` 期间 `_candidate()` 物化的 payload 集合
  **⊆ {本次提交的那一条}**（条数记入报告，允许 0 或 1）；
- 反例（同案必过）：同一夹具用字符串形态提交 → `candidates()` 调用数 == 1（兼容路径的整表复核**必须保留**）；
  若某 kind 做不到上述两条，按未完成上报，**不得**静默回退整表。

### S6 `ui_submit_passes_the_row_it_holds`（`tests/display_ui_cases.gd`，UI 分类 `display`）

- Given 把 UI 的夹具换成计数实例：沿用 `tests/display_ui_cases.gd:46` 的 `ui.game=<夹具>.new(...)` 式样（若本用例需要重新开局，
  把 `ui.game_factory` 也指向同一计数类）；稳定战斗 View；
- When 走**真实点击**成功提交一次（既有 `click(...)` 助手或 `ui.candidate_buttons[c.id].pressed.emit()`，等价于人点击）；
- Then `in_dispatch` 期间 `candidates()` 调用数 == 0；`ui.view.version==ui.game.state.version`；notice 为空；
  成功分支既有行为（写盘只随 `checkpoint`、反馈四调用只在 ok）不变；
- 反例（同案必过）：`ui._submit(stale_row, old_version)` → 版本拒绝、状态与存档零变化、`notice` 非空，
  且 `tests/ui_smoke.gd` 的 `_index_boundary_tests` 四条断言（当前 `:520-524`）原样通过。

### S7 `dict_submit_does_not_cache_across_submissions`（`tests/architecture_cases.gd`，`architecture`）

- Given 计数夹具；
- When 连续两次字典形态提交（第二次的候选取自第一次提交后的新 `candidates()`）；
- Then 两次 `in_dispatch` 期间 `candidates()` 调用数都为 0；两次物化的 payload 集合各自 ⊆ 本次提交的那条（无上一次残留）；
  `state.version` 恰 +2、两次 `ok=true`；
- 反例：把第一次的行再交一次 → 版本拒绝、状态不变（陈旧语义不因窄路径而放松）。

### 场景与落点汇总

| 场景 | 落点 | 分类 | 判据要点 |
| --- | --- | --- | --- |
| S1 陈旧版本仍拒绝 | `tests/persistence_cases.gd` | `persistence` | 现文案 + 状态零变化；旧 607-608 不动 |
| S2 自报代价不被采信 | `tests/architecture_cases.gd` | `architecture` | 按复算值扣款、日志用复算 label |
| S3 伪造 identity 仍拒绝 | `tests/architecture_cases.gd` | `architecture` | 具名原因 + 零状态变化 |
| S4 字典形态 ≡ 字符串形态 | `tests/architecture_cases.gd` | `architecture` | 全 kind 语料上 `ok/error/checkpoint/state` 相等 |
| S5 成功路径不重建整表 | `tests/architecture_cases.gd` | `architecture` | 全表入口计数 0 + 物化 ⊆ 本次提交；字符串形态计数 1 保留；kind 闭合表 |
| S6 UI 提交的是它手上的行 | `tests/display_ui_cases.gd` | `display` | 真实点击 + 计数 0；陈旧提交反例 |
| S7 无跨提交缓存 | `tests/architecture_cases.gd` | `architecture` | 连续两次各自独立、无残留 |

## 5. validator procedure（agent 可运行；只判最终版本，不拼旧版本通过）

宿主：`tests/ui_smoke.gd` + `tools/check.ps1`；操作必须是真实 viewport 输入（`move_mouse`／`mouse_button`／`flip`／
`start_drag`／`release_target` 等既有助手，触摸走 `tests/touch_ui_cases.gd`）；测试存档隔离（`ui.persistence_enabled=false`）；
引擎用 `tools/find-godot.ps1` 定位。**每条"人的路径"的判据是套件里的布尔 check，不靠目测、不默认截图。**

1. **范围预检（不算通过）**
   `& tools/check.ps1 -Suite battle_saturation,rewards,guard,persistence,architecture,runner -Impact -UI -UISuite display,body_layout,targeting,keyboard,touch,interface,persistence,home,events,route,basic_attacks,card_power,wall -ListOnly`
   → 输出计划且含上述分类与 `runner`；缺一即范围问题。
2. **规则门 + 界面门**（§6 第 1、2 条命令）→ 退出码 0、`SUITE RESULT: PASS …`、`UI PASS: N assertions`、
   `summary.json.status=passed` 且 `before==after` 指纹；`unrun` 必须为空（缺失分类**合并一次调用**补跑后仍空）。
   红集必须 ⊆ §6 的既有六项集，且逐条与登记项对得上（打印条数）。
3. **人的路径证明**（按顺序操作界面）：
   1. 战斗中点击手牌→选目标→提交成功（0／12／26 件各一次）：能量／魔力与提交前 View 的数值一致，
      界面按新 View 刷新，notice 为空，日志新增行带正确 label 与费用；
   2. 由外部推进回合制造陈旧展示（`_index_boundary_tests` 路径）→ 点击界面上的旧行动 → 只出现提示、
      展示版本追平、不扣费、不写档（`tests/ui_smoke.gd` 的 `_index_boundary_tests` 原判据，当前 `:520-524`）；
   3. 在 departure 页真实点击"继续前进"一回合 → 成功并刷新（证明 departure 候选也走窄路径）；
   4. 键盘：Tab／方向选择后确认 → 恰好提交一次；Esc 取消 → 状态零变化；
   5. 触摸：单击一张卡牌提交一次 → 与鼠标同路径、不重复提交；
   6. 拖动一个**旧版本**的攻击载荷（`ui._attack_drop_candidate` 旧 version）→ 空候选、被拒、不写档。
4. **两个 oracle（逐字）**：
   - 迁移：`& <godot> --headless --path . --script res://build/transition-oracle-20260916/transition_oracle.gd -- --baseline=build/transition-oracle-20260916/baseline.json`
     → 退出码 0、`TRANSITION RESULT: PASS (31 scenarios, 0 failures)`、摘要 `14eb8cf9c3c8b5d4347b2b9d118b8c504596e04d296d091884995bc359b522b6`、
     `SCRIPT ERROR|ERROR:|Invalid access` 命中 0 行；
   - 事件 E0：`& <godot> --headless --path . --script res://build/event-oracle-20260916/event_oracle.gd -- --baseline=build/event-oracle-20260916/baseline.json`
     → 退出码 0、`EVENT RESULT: PASS (94 scenarios, 0 failures)`、`EVENTDIGEST 1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da`、错误日志 0 行；
   - 两遍前置核对：脚本与基线 sha256 未变（迁移脚本 `59d41c682b3b302c1d291eb64aea770994c89508ee3fcb637afc7902024c045c`、
     基线 `ba979d18c31952d6d69ef06ce2ed102f7503c518fa8c6125ea6482c92bb5b4c8`；事件脚本 `cf48529a19af7773f4d8ac6be343a759fa6038151942fdf66dd249c89e20557f`、
     基线 `bdf08765f8dea0c1f6ac489245abd689907fd6974f794b7cea1e98d7a090e9c8`；以上为 2026-09-17 计划期读数，落地时以 `docs/verification.md` 登记值为准）。
5. **配对测量（只作参考，不作门禁）**：`docs/equipment-performance.md:45` 协议（同夹具交替、2 次热身 + 15 次有效配对、
   报逐对比值中位与两侧独立中位，不拼接）；测 0／12／26 件 × battle／departure 的**成功提交**点击；
   复用 `build/stutter-trace-20260917/` 的 driver 与 `instrument.py` 形态（真实窗口、插桩用完 `git checkout --` 还原），
   产物只放忽略目录 `build/submit-dedup-20260917/`。报：`dispatch` 段占该次点击的比例（新／旧）、
   `dispatch` 内候选复核段的绝对值中位、`get_view`／`render` 段对照（预期不降，用于证明收益来自复核段）。
6. **归因**：失败原因分"实现代码／测试脚本／环境／程序本身"；原因不确定就保持未分类上报，不自动改产品代码、不自行扩范围。
7. **证据与登记**：`build/checks/<id>/check-rules.log`、`check-ui.log`、`summary.json`、两份 oracle 日志、测量摘要；
   结果、命令、红集、覆盖清单写 `docs/verification.md`（validator 负责，不在本文件宣称通过）。

## 6. 完成定义（Definition of Done）

命令（一次，不无故重复；`<godot>` 由 `tools/find-godot.ps1` 给出）：

```powershell
& tools/check.ps1 -Changed -ListOnly                    # 开发期计划，不算通过（需有未提交改动；已提交后用 -Changed -Since <ref>）
& tools/check.ps1 -Suite battle_saturation,rewards,guard,persistence,architecture,runner -Impact -TimeoutSeconds 900
& tools/check.ps1 -UIOnly -UISuite display,body_layout,targeting,keyboard,touch,interface,persistence,home,events,route,basic_attacks,card_power,wall -TimeoutSeconds 900
& tools/check-index.ps1 -Write                          # core/ui/tests 改动后必须重新冻结，与源码同批提交
& tools/check-index.ps1                                 # 期望 CHECK INDEX PASS（零漂移）
& <godot> --headless --path . --script res://build/transition-oracle-20260916/transition_oracle.gd -- --baseline=build/transition-oracle-20260916/baseline.json
& <godot> --headless --path . --script res://build/event-oracle-20260916/event_oracle.gd -- --baseline=build/event-oracle-20260916/baseline.json
```

必过：

- §4 的 S1–S7 全部具名 check 通过，且**既有断言一条不弱化**：
  `tests/test_game.gd` `TC-CORE-0002/0003`（`:95-99`）、`tests/persistence_cases.gd:607-608`、
  `tests/ui_smoke.gd` 的 `_index_boundary_tests`（当前 `:520-524`）、`tests/test_game.gd:532-538`；
- 规则门 `unrun` 为空；红集 ⊆ {`card_power` 5、`installed_tools` 1、`tower_progression` 10+1、`hand_assist` 1、`home_persistence` 3、`interface` 1(28 张卡)}；
- 界面门退出码 0、各 `SUITE RESULT: PASS`、`UI PASS: N`；`summary.json.status=passed` 且 `before==after` 指纹；
- 两个 oracle：退出码 0、场景数 31／94 全过、摘要与登记值逐字相同、错误日志 0 行、脚本与基线 sha256 未变；
- 配对测量已跑并报告（`dispatch` 段占比与 `dispatch` 内复核段中位；**只作参考，本片不承诺绝对毫秒、不承诺整帧提速**），
  摘要（机器、件数、函数名、中位数、样本数）写 `docs/verification.md`，原始目录删除或留在被忽略的 `build/` 且不入库；
- 检查索引冻结物与源码**同批提交**。

算未完成（任一）：

- 任一必跑命令未执行、失败、未分类或被跳过（跳过须协调者书面授权并记录理由）；
- 字典形态仍调用 `candidates()`、或 `in_dispatch` 期间物化了本次提交之外的候选行（S5／S6 红），或某 kind 静默回退整表；
- 篡改 payload 仍能执行、或自报 `cost`／`valid`／`reason`／`label` 被采信（S2／S3 红）；
- 字符串形态行为被改（oracle 或 S4 红）；
- 删／弱化既有断言换绿灯；把既有断言改写为字典形态；
- 生产源码留计数器／开关／计时钩子；`build/` 产物或测量脚本入库；新增文件（本片不得新增文件）；
- 改 `get_view`／投影／`render` 整树／窗口与队列／候选内容与顺序与 ID／数值与既有文案（§3.4 新增那一条除外）；
- 以单次采样或"应该更快"宣称提速，或宣称完整回归／全量通过（未跑的域保持未验证）。

## 7. 依赖约束（cleaner 检查对象；人审通过后本节冻结为依赖规范）

允许方向（不变）：`data/* → core/* → ui/*`；`ui/**` 只经 `ui/main.gd` 的 `preload` 调 core 的既有只读面与 `dispatch`。

禁令与可执行检查（在 `spire-godot/` 下执行；括号内为期望）：

```bash
rg -n "game\.dispatch\(" ui/                 # 恰 1 处，位于 ui/main.gd:_submit，第一实参是候选对象（不得出现 c.id）
rg -n "game\.state" ui/                      # 0 命中（既有不变量）
rg -n "preload\(\"res://ui" core/ data/      # 0 命中
rg -n "sha256_text" core/game.gd             # 恰 1 命中（候选 id 算法的唯一实现，_candidate 与身份校验共用）
rg -n "sha256_text" core/ ui/ data/          # core/game.gd 1 处 + core/save_store.gd 既有 2 处，不得新增
rg -n "preload\(\"res://tests" core/ ui/ data/   # 0 命中（测试不得成为生产依赖）
```

- 不得为窄路径新写第二份费用／资格公式；窄路径只允许复用既有构造点（`_candidate` 及其调用方）。
- 不得新增保存候选／复算结果的实例字段（跨提交缓存）；不得用 `version` 当缓存键。
- 本片**不得新增文件**（`core/`、`ui/`、`tests/`、`docs/` 均已足够）；`ui/main.gd` 只允许 `_submit` 一行实质改动。
- 具名 check 只落在既有用例文件（`tests/*_cases.gd`），并复用既有夹具与真实输入助手；断言消息英文且写明域。
- 代码规范照 `spire-godot` 现状：GDScript 每层一个空格缩进；失败用原因字符串或 `{ok,error}`；英文注释写不变量与边界；
  玩家可见文案中文；不重排、不批量格式化未触及的代码。

## 8. 假设与最可能爆的点

1. **等价性靠"同一构造调用点"**：任何"按 kind 另写一份复算"的实现在后续规则改动时必然漂移；S4 是唯一防线，
   语料必须覆盖全部 kind（含 `chain`／`relic_bundle`／`prison`／`service`／`demo_*`）。若某 kind 进不了语料，
   只能进 `SUBMIT_KIND_EXEMPT` 并写理由——**理由不成立就是未完成**。
2. **收益可能落空**：若只在 `_candidate` 层过滤，昂贵的 `target_payload`／预览／候选文案仍会跑，`dispatch` 段占比不降。
   本片不承诺绝对毫秒；实现者必须报告"省下的是哪一段、哪些行走被跳过"，配对测量只作方向参考。
3. **早退改掉副作用**：`candidates()` 路径里任何进程内写入（临时字段、只读索引上下文 `_begin_equipment_read`）都必须在窄路径里保持；
   S4 的 `state` 逐字节相等锁定状态，但进程内字段不在 `state` 里——实现者必须在报告里说明收窄参数的作用域与恢复（成对设置／清除或按参数传递）。
4. **语料墙钟**：26 件全量候选双跑可能超出架构套件容忍（每 cell 数百条 × 2 次 dispatch，含深拷贝与 `validate()`）；
   只允许按 kind 分层抽样并公开规则，不得悄悄缩小到只剩 `card`。
5. **新增玩家可见文案**：`提交的行动与当前状态不一致，请重新选择。` 是本片唯一新字面量（仅篡改／缺陷路径可达）。
   若人不接受新增文案，需在开工前改判据（例如复用"该行动已经失效，请重新选择。"），改判据要同步改 §3.4 与 S3。
6. **GDScript 无重载**：第一实参放宽可能影响静态推断，需确认 522 处既有调用与 `tools/release_probe.gd` 编译通过
   （`-Suite runner` 与各门禁的编译错误即红）。
7. **UI 侧不得加容错**：若某 UI 路径提交的行与核心复算内容不等（漏键／键序外的不等价），必须落到具名拒绝；
   不允许 UI 侧为此重建 payload、补键或重试。
8. **既有"改 payload 后按 id 提交仍成功"**（`tests/test_game.gd:532-538`）是字符串形态的既有语义，本片保留；
   字典形态对同一场景是**拒绝**（S3）。两者并存是有意设计，不得为"统一"而改前者。
9. **两个 oracle 只用字符串形态**：它们对窄路径零覆盖；窄路径的回归证据是 S1–S7 与界面门，不得用 oracle 替代。

## 9. 人审标记与需协调者裁定的事项

**`needs-human-review`（理由，按规划者 skill 的复杂判据）**：

1. 改的是**唯一的正式提交入口**：`dispatch` 的入参形态、取值来源与判定顺序，外加 UI 唯一提交点；
   它同时是版本闸、事务入口与"提交是否有效"的唯一判据（未排期窗口／队列片会与它叠加，见 §10）。
2. **新增一条玩家可见拒绝文案**（§3.4），需人确认。
3. 窄路径要**跨多个 core 文件收窄既有构造路径**（非新模块、非局部小改），正确性依赖 S4 的全 kind 等价判据。
4. 收益只在 `dispatch` 段的 40–52% 量级上（实测），本片不承诺绝对毫秒；若人期望"点击明显变快"，需先对齐口径。

**人审前不得开工**（实现者不得以 cut-OK 替代本项）。

需协调者裁定或指派更新（本片不改这些文件）：

1. `docs/response-pipeline.md` §3.2／§7 的"仅当 `view.version != game.state.version` 才重同步"与 HEAD 不符（§0 第 1 条），
   以及 §3.2 的 `commit`／§3.3 的 `present(dirty)` 未落地（§0 第 2 条）：请裁定是加 superseded 指针还是按现状改写。
2. 本片落地后，`docs/response-pipeline.md` §2.1 的入参描述需补"字典形态"一行（一行加性说明，由协调者指派）。
3. 本片与未排期窗口／队列片的交接：见 §10，落地时请把该段并入那份契约。

## 10. 与未排期"结算窗口与输入队列"的关系（留给那份契约）

- 本片**不引入**窗口、队列或结算状态；`dispatch` 仍是唯一的有效性判据。
- 将来做窗口／队列时：队列只保存 `(候选行, 版本)` 并在窗口重开后**原样重放**到 `dispatch`，
  不得在 UI 侧重算候选资格、不得为队列再写一份"提交是否有效"的判断。
- 本片的字典形态正好是队列需要的载荷形态（行 + 版本），且"同 payload 在不同版本下 ID 相同"这一既有事实
  （`_candidate` 的 hash）意味着**队列不能只靠 ID 重放**——必须带版本，否则会把后面的回合也执行掉（该风险已由
  `docs/response-pipeline.md` 末尾的协调者记录登记）。本片不放宽这一点：版本闸在候选处理之前，字典形态同样适用。
