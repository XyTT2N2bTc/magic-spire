# 固定点存档契约（触发式写盘，取代逐操作写盘）

规划者契约（planner contract），2026-09-16。基线：分支 `event-pipeline-unification`，提交 `a673352`，
工作区干净。行号捕获于该提交；**函数名是稳定锚点**，动手前用 `rg` 复算。
本文件不写执行结果：通过／失败／未执行只登记到 `docs/verification.md`。

**状态：`needs-human-review`（见 §8）。实现者不得在协调者记录人审前开工。**

**本契约取代 `docs/save-write-skip.md`**（原"操作检查／内存令牌跳过"方案已被人的裁定推翻：
"改成固定点存档而不是操作检查"）。原文已删除；其保留的部分（失败语义、`.bak` 顺序、性能协议）已并入本文件。

## 1. 领域与切口

领域：存档**写盘时机**——把"每次成功提交都写盘"改成"只在固定点写盘"。不改存档内容、格式、版本、迁移与回退规则。

人的指令原文：**"改成固定点存档而不是操作检查！"**

**切口（本片全部改动点）**：

1. **删掉逐操作写盘**：`ui/main.gd:1923`（`_submit` 的 `if result.ok:` 分支）不再调用 `_save_progress()`。
   于是场景内每次点击的 `save` 段成本归零，**也不再有任何"内容比对"发生在提交热路径上**。
2. **删掉"恢复后立刻写盘"**：`ui/main.gd:291`（`_resume_snapshot` 成功后）不再调用 `_save_progress()`。
   理由：此时磁盘内容与内存内容语义相同（只是 `restore_snapshot` 把内存 `version` 抬到 `max+1`），
   写盘只会把 `.bak` 覆盖成当前起点的副本——正是本片要消除的浪费。
3. **只在固定点写盘**（§2 的触发表）：状态迁移（`_scene_start` 真的重冻）、地图线稿变更、
   显式用户动作（新局替换不兼容档、手动"保存场景起点"）。
4. **固定点级重复写防护**（不是每操作比较）：同一固定点被触发两次时，第二次不写盘、不覆盖 `.bak`。
   输入是"上次已写的起点版本 ＋ 线稿 ＋ 文件 stat"，只 `write_game` 被调用时求值（§3.3）。

代价与收益（P0 实测，`build/next-perf/results.json`）：`save` 恒定 39.4–48.8ms／次调用，与装备件数无关；
battle:26 一次成功提交 ≈ dispatch 58.8 ＋ get_view 63.5 ＋ save 44.1 ≈ 166ms。
本片后**场景内提交不再有 save 段**；固定点的单次写盘成本不变（它本来就是必要的）。

## 2. 固定点清单（逐处枚举，来自代码；§4 场景 02 按此立证）

### 2.1 `_scene_start` 的赋值点（全部，`rg -n "_scene_start\s*=" core/`）

| # | 位置 | 语义 | 本片的写盘触发 |
| --- | --- | --- | --- |
| F1 | `core/game.gd:246`（开局初始化末尾：练习／入口／出发／首战） | 一局的初始起点 | **不单独写**：由显式"开始新局／替换不兼容档"动作（T3）覆盖；此后第一次状态迁移会写 |
| F2 | `core/game.gd:3184`（`restore_snapshot` 成功末尾） | 读档后的起点 | **不写**（见 §1 第 2 条；T4 手动可强制写） |
| F3 | `core/game.gd:3198`（`_commit_scene_start`：场景键变化时重冻） | 状态迁移产生的新起点 | **T1 写** |
| F4 | `core/game.gd:3201`（`_commit_scene_start`：测试注入场景为空时的兜底） | 首个正式命令落地 | **T1 写** |

### 2.2 `_commit_scene_start` 的调用点（全部，`rg -n "_commit_scene_start" core/`）

| # | 位置 | 说明 |
| --- | --- | --- |
| C1 | `core/game.gd:2441`（`dispatch` 成功路径，事务提交后） | **唯一调用点**：所有状态迁移都经这里，是否重冻由 `_scene_key` 是否变化决定 |

### 2.3 触发表（写盘只允许由这四条触发）

| 触发 | 位置 | 条件 | 强制？ |
| --- | --- | --- | --- |
| **T1 状态迁移** | `ui/main.gd` 的 `_submit` 成功分支 | `dispatch` 结果带 `scene_start_frozen` 为真（＝`_commit_scene_start` 真的重冻） | 否，走去重防护 |
| **T2 地图线稿** | `ui/main.gd:1636` `graph.drawings_changed` → `_save_progress`（现状保留） | 线稿变化（ink 变化） | 否，走去重防护 |
| **T3 新局替换不兼容档** | `ui/main.gd:1965` `_save_progress(true)`（现状保留） | 用户在主页明确开始新局／替换 | **是**（`force`） |
| **T4 手动保存场景起点** | `ui/main.gd:2682` 按钮（现状保留） | 玩家显式点击 | **是**（`force`） |

### 2.4 `_scene_key` 的分量（T1 的判据面，`core/game.gd:_scene_key`）

`seed`、`tower_generation`、`map_region`、`room`、`phase`（`inspection`→`prison`；`rest_choice`→`rest`）、
`battle` 时的 `encounter`、`battle`／`prison`／`prepare` 时的 `combat.serial`、`demo_finished`。
**任一分量变化 ⇒ 起点变化 ⇒ 必须写盘**；§4 场景 02 对每个分量各覆盖一次
（战斗开始／战斗结束→整备／离开房间／换层／休息／商店／监狱进出／demo 结束等迁移类型）。

### 2.5 不变量（可机器检查，`architecture` 分类具名 check）

- `core/` 内 `_scene_start` 的赋值点集合 **⊆ {F1,F2,F3,F4}**；`ui/` 内 `_save_progress` 的调用点集合
  **⊆ {T1,T2,T3,T4}**（`T1` 计入 `_submit` 内的那一次）。
- 新增任一赋值点或调用点，**必须同时更新本表**，否则该 check 红——这是"漏掉固定点＝进度回退"的防线。

## 3. 接口与行为契约

### 3.1 `dispatch` 结果新增只读信号（须人确认，见 §8）

- `_commit_scene_start(before)` 返回 `bool`（是否真的重冻）。
- `dispatch` 成功字典**新增**键 `"scene_start_frozen":true`，**仅**在重冻时出现；
  未重冻时**不出现**该键（保持既有键集合与顺序不变，见 `docs/response-pipeline.md` §2.1 的消费方约定）。
- UI 只读该键决定是否触发 T1，**不做任何内容比较**。

### 3.2 `_save_progress(replace_incompatible=false, force=false)` 与
`write_game(game, replace_incompatible=false, map_drawings={}, force=false)`

- 新增 `force` 参数（**加性**，默认 `false`）：显式用户动作（T3／T4）传 `true`；
  `force=true` 跳过 §3.3 的去重防护，其余分支与顺序逐字不变。
- `replace_incompatible` 的语义与失败文案保持不变（T3 同时传两者）。

### 3.3 固定点级去重防护（**只在 `write_game` 被调用时求值**）

```
write_game(...)
  1. game.validate() 与 slot 合法性：保持现状，先跑（状态坏了必须报错，不得因去重放行）
  2. force==false 时计算候选信号：
       version = game.scene_start_version()   # 见 §3.4
       ink     = 与 pack() 同一实现产出的线稿文本（把 pack 内的 ink 构造抽成 helper，pack() 与去重共用）
     早退条件（全部成立才跳过）：本 SaveStore 实例在本次运行内已对该 slot 成功写过一次
       ∧ version 与 ink 等于上次成功写入的记录
       ∧ 主档存在且 size／mtime 等于上次成功写入后的记录
     → 直接返回与成功路径逐字相同的 {"ok":true,"slot":slot,"message":…}，不读档、不 pack、不写文件
  3. 其余情况：完整走今天的分支与顺序（版本检查→pack→大小检查→mkdir→tmp→回读校验→
     copy 主→.bak→rename），成功后记录新的信号（version／ink／size／mtime）
```

- 去重信号**只存内存**（SaveStore 实例字段，按 slot 分键）：不进存档、不进快照、不进 View、
  不进 `state`、不渲染、不做成计数器。
- **宁写不跳**：信号缺失、文件不存在、`size`／`mtime` 不符、`force=true`、`replace_incompatible=true`
  一律走完整路径。跳过只在"本会话确实写过同一份字节、且文件仍是那份"时发生。

### 3.4 只读接口 `Game.scene_start_version() -> int`（用途重新定位；须人确认，见 §8）

- **用途**：仅作 §3.3 去重信号的输入——"上次写的起点版本 vs 当前起点版本"。
  **它不是每操作比较**：`write_game` 只在固定点被调用（T1–T4），提交热路径不再触碰它。
- 语义：返回"`restart_snapshot()` 现在会返回的那份快照"的版本号——`_scene_start` 与当前场景键一致时
  取其 `version`，否则取 `state.version`（**忠实镜像 `restart_snapshot()` 的 fallback 分支**）；**不得深拷贝**。
- 若人决定不要去重（固定点每次调用都写）：本接口**不需要**，由"每个固定点写一次"取代，
  代价＝同一定点重复触发时 `.bak` 被同内容覆盖（§8 备选项）。
- 备选（不采用）：在 `save_store` 里直读 `game._scene_start`——跨模块读私有成员，耦合更高。

### 3.5 保留（不得弱化）

- 失败路径与全部文案（`"保存失败：…原存档保留。"`／`"保存已暂停：原存档版本不兼容…"`／
  slot 非法／大小超限／回读校验失败），`docs/response-pipeline.md` §7 与既有 `save_failed`／
  `save_suspended` 语义；`pack()`／`unpack()` 的格式与校验；`restart_snapshot()` 的冻结时机；
  `read_slot` 的回退规则与 `summary()` 的可用性语义；`.bak` 的刷新顺序（先 `copy 主→.bak`、
  后 `rename tmp→主`，因此 `.bak` ＝写入前的主档 ＝**上一个固定点起点**）。
- `saved_at` 的含义自然变为"**上次固定点写入时间**"（不再是"上次点击"）。

## 4. Gherkin（场景名 → 既有分类的具名 check）

落在 `tests/persistence_cases.gd`（`persistence`）、`tests/architecture_cases.gd`（`architecture`）、
`tests/persistence_ui_cases.gd`（UI `persistence`）；复用隔离存档目录与真实夹具，不新建流程文件。

01. `save_skips_within_a_scene`（`persistence`）
    Given 一局已在一个固定点保存（真实 `SaveStore`＋隔离目录）；
    When 在同一场景内做若干次成功提交；
    Then 主档与 `.bak` 的**字节与 mtime 都不变**、无 `*.tmp`／`*.bak.tmp` 残留、
    且**未调用 `write_game`**（测试侧包装 SaveStore 子类计数，生产无计数器）。
02. `save_writes_on_every_scene_key_change`（`persistence`）
    Given 每类迁移的夹具；When 逐类触发（战斗开始／战斗结束→整备／离开房间／换层／休息／商店／
    监狱进出／demo 结束，覆盖 `_scene_key` 的每个分量）；
    Then **每次都写盘**：主档字节变化、`.bak` 等于写入前的主档，且新主档 `unpack` 等于新 `restart_snapshot()`。
03. `save_writes_on_drawings_changed`（UI `persistence`）
    Given 地图线稿为空；When 真实画一笔（触发 `drawings_changed`）；
    Then 写盘且 ink 与线稿一致；再画一笔 → 再写；重新进入同一地图不画 → **不写**。
04. `save_force_paths_always_write`（`persistence`）
    Given 内容未变；When 走 T3（新局替换不兼容档）与 T4（手动"保存场景起点"）；
    Then 两者都写盘（`force` 生效），且不兼容档替换的失败／成功语义与今天逐字一致。
05. `save_dedupes_repeated_fixed_point`（`persistence`）
    Given 同一固定点已写；When 同一固定点被再次触发（内容未变）；
    Then 不写盘、`.bak` 不被覆盖（仍是上一个固定点起点）；`force` 时例外地照写。
06. `save_backup_holds_previous_fixed_point`（`persistence`）
    Given 固定点 A → 固定点 B → 场景内若干次提交；
    When 主档被破坏（截断／改字节）；
    Then `read_slot` 回退到 `.bak`（`backup=true`），其字段等于 **A 的起点快照**（不是 B 的副本），
    且能经正式入口继续。
07. `save_triggers_are_pinned`（`architecture`，源文本扫描）
    Given 读取 `res://core/game.gd` 与 `res://ui/main.gd`；
    When 提取 `_scene_start` 赋值点与 `_save_progress` 调用点；
    Then 集合分别 **⊆ §2.1／§2.3 表**；出现表外点即失败并打印位置（漏固定点的防线）。
08. `save_format_and_failure_contract_unchanged`（`persistence`）
    Given 各类失败前置（`persistence_enabled=false`／`save_suspended`／`validate()` 失败／slot 非法／
    大小超限／不兼容旧档）；
    Then 返回值与文案与今天**逐字相同**，`pack`／`unpack` 格式与 `read_slot` 回退规则不变，
    且**去重不得让任一失败被放行**。

## 5. Validator procedure（agent 可运行；真实输入）

宿主入口：`tests/test_game.gd`（规则）＋`tests/ui_smoke.gd`（界面）＋`tools/check.ps1`；
测试存档隔离，不读写玩家存档，不默认截图。

1. 范围预检（不算通过）：
   `& tools/check.ps1 -Suite persistence,architecture -Impact -ListOnly`；
   `& tools/check.ps1 -UIOnly -UISuite persistence,home -ListOnly`。
2. 规则门：`& tools/check.ps1 -Suite persistence,architecture -Impact -TimeoutSeconds 600` → 退出码 0，
   `status=passed` 且 `before==after` 指纹（`source_changed` 不算通过）。
3. 界面门：`& tools/check.ps1 -UIOnly -UISuite persistence,home -TimeoutSeconds 900` → 退出码 0
   （**900 秒是硬要求**：默认 300 秒在负载下会被中途中止）。
4. 人的路径证明（判据是套件的布尔 check；按顺序在真实界面上操作）：
   - 练习局：进入战斗后点若干张牌（**不换场景**）→ 存档文件与 `.bak` 的 mtime 不变；
   - 结束战斗／进入整备／进入下一房／换层 → 主档更新，`.bak` 变为"上一个固定点起点"；
   - 在地图上画一笔 → 写盘；重进同一张地图不画 → 不写；
   - 手工破坏主档 → 主页"继续" → 回到**上一个固定点起点**且状态完整；
   - 全程不打包、不发布。
5. 失败路径复核：失败／暂停／被拒的提示与行为与改动前逐字一致（以既有断言为准，不新增文案）。
6. 归属判定：失败先分"实现代码／测试脚本／环境／程序本身"；不确定保持未分类上报，不自动改产品代码。
7. 证据：`build/checks/<id>/check-rules.log`、`check-ui.log`、`summary.json`；结果与域写
   `docs/verification.md`（validator 负责，不在本契约宣称通过）。

## 6. 完成定义（DoD）

```powershell
& tools/check.ps1 -Suite persistence,architecture -Impact -TimeoutSeconds 600
& tools/check.ps1 -UIOnly -UISuite persistence,home -TimeoutSeconds 900
```

- 必过的场景：§4 的 01–08 全部具名 check；`persistence`／`architecture` 全 PASS；界面门 PASS。
- 必有的证据：两份 check 日志＋`summary.json`（`status=passed`、指纹稳定）；
  既有失败路径断言逐条保留（**不得**为绿灯改文案或删断言）。
- **性能判据（沿用 `docs/equipment-performance.md:45` 配对协议）**：0／12／26 件 × battle／departure 夹具，
  2 次热身＋15 次有效配对，报**逐对比值中位**与两侧独立中位；口径：
  ①**场景内提交的 `save` 段＝0**（由 §4 场景 01 的"未调用 `write_game`"与 mtime／字节断言立证），
  同夹具下总耗时的下降量照报；
  ②固定点单次写盘成本**照报**（不设下降目标，它本来是必要的）；
  ③不得以"应该更快"、单次采样或拼接历史数字宣称收益；计时脚本与 JSON 只放已忽略的
  `build/<topic>-<date>/`，摘要（机器／夹具／件数／中位／样本数）进 `docs/verification.md` 后删除原始目录；
  生产源码不得留计数器或计时钩子。
- 算未完成（任一）：任一必跑命令未执行／失败／未知或跳过；`summary.json` 为
  `source_changed`／`failed`／`plan`；为绿灯弱化失败路径断言或改写既有文案；
  出现 §2 表外的写盘触发点或漏掉某个固定点（场景 02／07 红）；场景内仍有写盘（场景 01 红）；
  去重放行了任一失败路径、或让 `force` 路径被跳过；信号进入存档／快照／View／`state`；
  新增生产文件、改 `pack()`／`unpack()` 格式与校验、改 `restart_snapshot()` 冻结时机、
  改 `read_slot` 回退规则；宣称完整回归或打包。

## 7. 依赖约束

- 允许改动：`ui/main.gd`（删两处调用、加 T1／T3／T4 的 `force` 传参）、`core/game.gd`
  （`_commit_scene_start` 返回 bool、`dispatch` 加 `scene_start_frozen` 键、新增只读
  `scene_start_version()`）、`core/save_store.gd`（`force` 参数＋去重防护＋ink helper 抽取）、
  `tests/persistence_cases.gd`／`tests/persistence_ui_cases.gd`／`tests/architecture_cases.gd`、
  `build/` 下一次计时脚本（不入库）。
- **不改**：`pack()`／`unpack()` 的格式与校验、`restart_snapshot()` 的冻结时机与返回语义、
  `write_game` 的既有分支顺序与失败文案（除新增去重早退与 `force`）、`core/snapshot.gd`、
  `assets/localization/**`、`docs/response-pipeline.md`（其 §2.1 只增一行说明由本契约承接时的加性键）、
  其它契约。
- 依赖方向：`ui/main.gd → core/{Game,SaveStore}`（既有边）；`core/save_store.gd → core/game.gd`
  （既有边，新增一次只读调用）。**不新增模块依赖、不新增生产文件。**
- 信号与去重状态不得被 `ui/`（除读取 `scene_start_frozen` 外）或 `core/game_view.gd` 引用。

## 8. 需人确认（`needs-human-review` 的原因）

1. **固定点清单是否完整**（§2）：表由代码枚举得出（4 个赋值点、1 个调用点、4 条触发）；
   人需确认"哪些迁移该写盘"的语义判断（尤其：开局初始化 F1 不单独写、读档 F2 不写、恢复后不写）。
2. **`saved_at` 语义**：变为"上次固定点写入时间"（不再是"上次点击"）——玩家可见。
3. **只读接口的去留**（§3.4）：保留＝作固定点级去重信号（推荐）；去掉＝每个固定点都写，
   代价是同一定点重复触发会把 `.bak` 覆盖成同内容副本。
4. **`dispatch` 新增 `scene_start_frozen` 键**（§3.1）：加性，但属接缝 A 的返回形状变化，需认可。
5. **手动保存是否强制写**（§2.3 T4）：本契约取"强制"（显式动作必须落地）；若人要求"内容未变则跳过"，
   改一处传参即可。
6. 交付形态：只出本契约一份文件；实现范围＝§7 的允许改动清单。

## 9. 假设与最可能爆掉的假设

1. **最可能爆：漏掉一个固定点 ⇒ 玩家进度回退。** 唯一调用点 C1 让"是否写盘"由 `_scene_key`
   的判定决定；若 `scene_start_frozen` 的传递在某条路径上丢失（例如 `dispatch` 的其它返回分支、
   或 `_commit_scene_start` 的兜底 F4 未返回真），该迁移就不会写盘。缓解：§4 场景 02 逐分量覆盖 ＋
   场景 07 的源文本清单 check（表外点即红）。
2. **次可能：`scene_start_version()` 未镜像 `restart_snapshot()` 的 fallback** →
   "起点已变却版本号相同"导致去重误跳。缓解：§3.4 明确要求镜像；场景 02／08 立证。
3. **地图线稿路径**：`drawings_changed` 在失去窗口焦点等时刻也会 emit（`ui/route_map.gd:47`）；
   若 emit 而未变，去重防护应当跳过（ink 相同）——判据是场景 03 的"重进不画不写"。
4. **删掉恢复后写盘**（§1 第 2 条）：读档后不再把抬升过的 `version` 写回文件；
   该版本号只是乐观并发计数，内容不受影响。若人认为"读档后必须立刻把版本写回"，需回 §8 重裁。
5. **`force` 参数的加性改动的调用面**：`_save_progress` 仅 `ui/main.gd` 内 4 处调用；
   实现在报告里给出改后调用点与传参清单，避免漏传导致 T3／T4 被去重挡下。
6. 若人认为"玩家手动保存后磁盘必须立刻有新 mtime"（外部同步工具依赖），
   T3／T4 的 `force` 已满足；其余固定点按去重（同内容不重复写）是有意行为。
