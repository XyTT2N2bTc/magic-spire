# 固定点存档契约（重写：按收束后的迁移声明表实现）

规划者契约（planner contract），2026-09-16 重写。基线：分支 `event-pipeline-unification`，提交 `9dd74fd`
（迁移收束已落地 `35f3411`，登记 `77d8dd7`），工作区干净。行号捕获于该提交；**函数名是稳定锚点**。
本文件不写执行结果：通过／失败／未执行只登记到 `docs/verification.md`。

**状态：重写（按收束后的迁移声明表实现）。** 原"探测方案"**作废**：

- 旧的 P1／P2／P3 上下文探测（比 `floor`、比 `phase`、`_checkpoint_kind(original)`）与 §2.5 的 53 点扫描表
  **全部作废**，只保留为历史对照；
- 旧半成品**已丢弃**（`git stash drop`，stash 列表现为空），补丁留档
  `spire-godot/build/dropped-save-wip-20260916.patch`（不入库）；
- 本文件保留旧契约里仍然有效的判据：正反例清单、`.bak` 与恢复、失败契约、性能口径、提速口径。

**修订记录**：本文件先后取代 `docs/save-write-skip.md`（逐操作比对，已删）与"全量探测"版；
人审原话：**"只有你进入新的一层时存档，完成战斗时存档，完成休整后存档，其他一律不存"**。

## 1. 切口（替换旧探测）

1. **三个固定点＝声明表上的 kind**：`core/game.gd` 的 `TRANSITIONS`（`:691`）中——
   `floor_enter`、`battle_end_victory`／`battle_end_saturated`／`battle_end_captured`、`prepare_end`。
   在表上**标记为 checkpoint**（加一列 `checkpoint:String` 或一份 `const CHECKPOINT_KINDS` 清单；
   二选一由实现定，但**必须只有一处声明**）。
2. **`dispatch` 成功结果加加性键 `checkpoint`**：`""`／`"floor"`／`"battle_end"`／`"prepare_end"`，
   由**本次提交实际产生的迁移条目**（`_transition_log` 的本次增量）推导；
   **多类同时命中取 `battle_end` ＞ `prepare_end` ＞ `floor`**；未命中为空串。既有键与顺序不变。
3. **UI 只按该键决定写盘**：`ui/main.gd` 的 `_submit` 仅在 `checkpoint` 非空时调 `_save_progress()`；
   **删除恢复后立刻写盘**（`:291`）；**保留**三条非进度写盘（`:1636` 线稿、`:1965` 新局替换、`:2682` 手动保存）。
4. **闭环扩展**：`checkpoint` 集合必须与声明表里被标记的 kind **完全一致**（固定清单，**多一个少一个即红**），
   防止将来新增 kind 时静默变成／丢掉固定点。

## 2. 三个固定点（kind → 写入内容 → 恢复点）

写入内容一律＝**写入时刻的 `restart_snapshot()` ＋ 当时线稿**；写盘发生在**提交之后**
（`dispatch` 成功返回、UI 收到非空 `checkpoint` 之后）。

| 固定点（`checkpoint` 值） | 来源 kind（声明表） | 预期恢复点 |
| --- | --- | --- |
| `"floor"` | `floor_enter`（**目标层高于当前层**；只用于真实移动与换塔落点） | **该层入口**（新层第一个房间的起点） |
| `"battle_end"` | `battle_end_victory`／`battle_end_saturated`／`battle_end_captured`（**收押含在内**） | **战斗结束后的阶段起点**（奖励／事件结果／收押结果） |
| `"prepare_end"` | `prepare_end`（三条分支：`pack`／`map`／`cleared`） | **整备结束后的起点**（下一步行动前） |

- **同类多条目**：同一提交内出现同类多个条目时，`checkpoint` 取值**按类别去重**，不由条目数决定（§6）。
- **同层移动**（`room_enter`）**不是**固定点；换塔（`tower_restart`）**不是**固定点（人审裁定）。

## 3. 非进度写盘（按显式意图／独立产物保留，不变）

| 触发 | 位置 | 写什么 | 说明 |
| --- | --- | --- | --- |
| 地图线稿变更 | `ui/main.gd:1636` `graph.drawings_changed` | 当前 `restart_snapshot()` ＋最新线稿 | 玩家批注是独立产物；**不改变恢复点** |
| 新局替换不兼容档 | `ui/main.gd:1965` `_save_progress(true)` | 开局起点＋线稿 | 版本不兼容时开始新局的必经路径 |
| 手动"保存场景起点" | `ui/main.gd:2682` 按钮 | 当前 `restart_snapshot()`＋线稿 | 显式用户意图；**本契约无去重机制**，点击即写 |

## 4. 人可见后果（人已裁定接受）

1. **恢复粒度＝三个固定点**：崩溃／退出后回到三者中最近的一个（本层入口／上一场战斗结束／上次整备结束）；
   场景内（战斗中途、整备途中、房间之间）的进度不再保留。
2. `saved_at` 含义＝"上次固定点写入时间"（不再是"上次点击"）。
3. `.bak` 稳定持有**上一次固定点内容**（不再被空写覆盖）；主菜单"继续"在损坏时回退到它。
4. 主菜单摘要时间更新频率明显下降（只在三个固定点、手动保存与画线时变化）。

## 5. 接口与行为契约

- `dispatch` 成功字典新增 `"checkpoint"`（`""`／`"floor"`／`"battle_end"`／`"prepare_end"`）；**加性**。
  UI 取法：`if result.ok and String(result.get("checkpoint","")) != "": _save_progress()`；**不做内容比较、不读快照**。
- `_save_progress(replace_incompatible=false)` 与 `write_game(game, replace_incompatible=false, map_drawings={})`
  **签名不变**；`core/save_store.gd` **不需要改**。
- **保留不得弱化**：失败路径与全部文案（`"保存失败：…原存档保留。"`／`"保存已暂停：原存档版本不兼容…"`／
  slot 非法／大小超限／回读校验失败）；`pack()`／`unpack()` 的格式与校验；`restart_snapshot()` 的冻结时机；
  `read_slot` 的回退规则与 `summary()` 的语义；`.bak` 顺序（先 `copy 主→.bak`、后 `rename tmp→主`，
  ⇒ `.bak`＝写入前的主档＝上一次固定点内容）；存档格式与 `save_revision` 不变。

## 6. 折叠边界收口（原"附加条件"的结论）

**背景**：`docs/transition-pipeline.md` §6 对 oracle 的 `transition_log` 一列做了**双侧折叠相邻同名**的边界，
其附加条件是"若该日志将来成为存档切片的数据源，此边界必须重审"。**现在它就是了**（`checkpoint` 由
`_transition_log` 的本次增量推导），故在此**收口**：

**结论：本片可接受该边界，但必须同时满足以下三条；三条缺一即本片未完成。**

1. **推导按类别、与条目数无关**：`checkpoint` 只由本次提交出现过的 **kind 集合**决定（按 §1 的优先级取一），
   **不得**依赖条目条数或相邻重复的次数；同一提交内重复出现同一 kind 时结果不变。
2. **语义由别处承接、不得依赖 oracle 折叠**："恰一条 `battle_end_*`"这类语义由**闭环 check 与具名场景**
   （本片 §7-01／02 与 `transition-pipeline` 场景 01／02／04）承接；本片另加**重复不敏感**具名 check
   （向 `_transition_log` 注入一条相邻重复 → `checkpoint` 取值不变、**写盘次数仍为 1**）。
3. **审计留痕**：本片报告必须复述 `transition-pipeline` §6 的投影证据（六列投影两侧同为 `5333ab64…`、
   冻结脚本自比 31 条差异全在该列）并标注"该列**现在是数据源**"；**比对仍是门禁、摘要仍是脚本版本指纹**。

**若将来需要"该列逐条精确"的诊断**（例如把新增 kind 的计数写进判据），必须**另立批次**恢复该列的严格比对；
在此之前**不得**把折叠边界当作"精确计数已通过"。

## 7. Gherkin（场景名 → 既有分类的具名 check；全部走真实公开命令）

落在 `tests/persistence_cases.gd`／`tests/persistence_ui_cases.gd`（`persistence`）与
`tests/architecture_cases.gd`（`architecture`）；复用隔离存档目录与既有夹具，不新建流程文件。

**正例（必写；走真实命令＝取候选 → `dispatch`）**

01. `save_writes_on_floor_enter`（`persistence`）——Given 已在某层保存；When 走到**更深的层**
    （经由 `depart`／`travel_step`）；Then `result.checkpoint=="floor"`、写盘、`.bak`＝写入前主档、
    主档 `unpack` 的 `room` 为新层入口、**写进去的是写入时刻的 `restart_snapshot()`**。
02. `save_writes_on_each_battle_end_kind`（`persistence`）——三个 `battle_end_*` 各一例（胜利／空间耗尽／收押）：
    各自 `checkpoint=="battle_end"`、写盘一次、主档 `phase` 等于结束后的阶段。
03. `save_writes_on_prepare_end`（`persistence`）——`prepare` 的三种结束（回合用尽／提前结束／进入下一场景）：
    各自 `checkpoint=="prepare_end"`、写盘一次、主档 `phase` 不再为 `prepare`。
04. `save_writes_on_explicit_and_drawing_paths`（UI `persistence`）——线稿一笔／手动保存／新局替换：三者都写盘，
    且**线稿写入后主档内容仍是当前固定点起点**（恢复点不变）。

**反例（必不写；判据＝主档与 `.bak` 的字节与 mtime 都不变、且**未调用 `write_game`**）**

05. `save_skips_representative_non_points`（`persistence`，测试侧包装 SaveStore 子类计数，生产无计数器）——
    N1 战斗中出牌｜N2 战斗中结束回合｜N3 战斗中翻面｜N4 同层移动｜N5 商店交易｜N6 事件选择｜
    N7 宝箱领取｜N8 监狱巡视与牢房行动｜N9 休息房行动与休息回合｜N10 demo 结束｜N11 读档成功。

**回退、契约与闭环**

06. `save_backup_holds_previous_fixed_point`（`persistence`）——固定点 A → 固定点 B → 场景内若干活动；
    When 主档被破坏；Then `read_slot` 回退到 `.bak`＝**A**（不是 B 的副本），可经正式入口继续。
07. `save_format_and_failure_contract_unchanged`（`persistence`）——各类失败前置（`persistence_enabled=false`／
    `save_suspended`／`validate()` 失败／slot 非法／大小超限／不兼容旧档）：返回值与文案逐字相同，
    `pack`／`unpack` 格式与 `read_slot` 回退规则不变，**任一失败不得被放行**。
08. `checkpoint_kinds_are_pinned`（`architecture`，源文本扫描）——扫描集合与**被标记为 checkpoint 的 kind 清单**
    **完全一致**（多一个或少一个即红，打印差异）；新增 kind 必须同批决定"是否固定点"。
09. `checkpoint_ignores_duplicate_entries`（`persistence`）——向本次提交的 `_transition_log` 注入一条相邻重复：
    `checkpoint` 取值不变、**写盘次数仍为 1**（§6 第 1／2 条）。

## 8. Validator procedure（agent 可运行；真实输入）

1. 范围预检（不算通过）：`& tools/check.ps1 -Suite persistence,architecture -Impact -KeepGoing -ListOnly`；
   `& tools/check.ps1 -UIOnly -UISuite persistence,home -ListOnly`。
2. 规则门：`& tools/check.ps1 -Suite persistence,architecture -Impact -KeepGoing -TimeoutSeconds 600` →
   退出码 0、`summary.json` 的 `status=passed` 且 `before==after` 指纹（`source_changed` 不算通过）；
   若出现 `unrun` 分类，**合并一次调用补跑**并列出清单。
3. 界面门：`& tools/check.ps1 -UIOnly -UISuite persistence,home -TimeoutSeconds 900` → 退出码 0（**900 秒硬要求**）。
4. 人的路径证明（判据是套件的布尔 check；按顺序在真实界面上操作）：
   - 战斗内点若干张牌、结束回合 → 主档与 `.bak` 的 mtime 不变；
   - 打赢这一场 → 写盘，主页"继续"回到**战斗结束后的起点**；
   - 走完整备 → 写盘；整备中再做若干操作 → 不再写；
   - 走到**更深的层** → 写盘，恢复点＝该层入口；**同层换房 → 不写**；
   - 塔路图上画一笔 → 写盘（恢复点不变）；重进同一地图不画 → 不写；
   - 手工破坏主档 → 主页"继续" → 回到**上一次固定点**且状态完整；不打包、不发布。
5. 失败路径复核：失败／暂停／被拒的提示与行为与改动前逐字一致（不新增文案）。
6. 归属判定：失败先分"实现代码／测试脚本／环境／程序本身"；不确定保持未分类上报，不自动改产品代码。
7. 证据：`build/checks/<id>/`（`check-rules.log`／`check-ui.log`／`summary.json`）；结果与域写
   `docs/verification.md`（validator 负责，不在本契约宣称通过）。

## 9. 完成定义（DoD）

```powershell
& tools/check.ps1 -Suite persistence,architecture -Impact -KeepGoing -TimeoutSeconds 600
& tools/check.ps1 -UIOnly -UISuite persistence,home -TimeoutSeconds 900
```

- 必过场景：§7 的 01–09；`persistence`／`architecture` 全 PASS；界面门 PASS；红集 ⊆ 已知既有项
  {`card_power` 5 条, `installed_tools` 1 条, `tower_progression` 10 规则＋1 界面, `hand_assist` 1 条}，
  **不得新红**；`content/packs` 未改动，不跑 `check-content.ps1`。
- **性能判据（沿用 `docs/equipment-performance.md:45` 配对协议）**：0／12／26 件 × battle／departure，
  2 热身＋15 配对，报**逐对比值中位**与两侧独立中位；口径：①**场景内提交的 `save` 段＝0**
  （由 §7-05 的"未调用 `write_game`"＋mtime／字节断言立证），同夹具总耗时下降量照报；
  ②固定点单次写盘成本**照报**（不设下降目标）；③不得以"应该更快"、单次采样或拼接历史数字宣称收益；
  计时脚本与 JSON 只放已忽略的 `build/`，摘要入 `docs/verification.md` 后删除原始目录；生产源码不留计数器。
- **敏感性证明（必须做，随后还原）**：临时让一个非固定点的 dispatch 也带 `checkpoint`（或让某个
  checkpoint kind 不写）→ **§7-05／01 之类相关 check 必须变红**；还原后全绿。证据（临时补丁＋红日志）入报告。
- **判据提速口径（沿用，作为后续默认）**：①每批只跑受影响套件；②`unrun` **合并一次调用**补跑；
  ③报告**带墙钟**。
- 算未完成（任一）：任一必跑命令未执行／失败／未知或跳过；`summary.json` 为
  `source_changed`／`failed`／`plan`；为绿灯弱化失败路径断言或改文案；场景内仍有写盘；
  固定点漏写或 `checkpoint` 取值错；`checkpoint` 推导依赖条目数；闭环 check 与声明表标记不一致；
  新增生产文件、改 `pack()`／`unpack()` 格式与校验、改 `restart_snapshot()` 冻结时机、改 `read_slot` 回退规则；
  未做敏感性证明；宣称完整回归或打包。

## 10. 依赖约束

- 允许改动：`core/game.gd`（声明表加 checkpoint 标记；`dispatch` 结果加 `checkpoint` 键与其推导）、
  `ui/main.gd`（删 `:291`；`_submit` 只在 `checkpoint` 非空时写盘）、
  `tests/persistence_cases.gd`／`tests/persistence_ui_cases.gd`／`tests/architecture_cases.gd`、
  `build/` 下一次计时脚本（不入库）。
- **不改**：`core/save_store.gd`、`pack()`／`unpack()` 格式与校验、`restart_snapshot()` 冻结时机、
  `write_game` 的既有分支顺序与失败文案、`core/snapshot.gd`、`assets/localization/**`、
  `TRANSITIONS` 的既有 kind 语义（**只加标记**）、其它契约。
- 依赖方向：`ui/main.gd → core/{Game,SaveStore}`（既有边）；`core/game.gd` 内部改一处推导。
  **不新增模块依赖、不新增生产文件、不新增只读接口。**

## 11. 需人确认（只剩一条）

**§6 的折叠边界结论**（本片可接受 ＋ 三条附加保证 ＋ "若需精确计数须另立批"）——请人确认一句话即可。
其余切口（三个固定点＝声明表 kind、`checkpoint` 加性键、删恢复后写盘、保留三条非进度写盘、
恢复粒度变粗、手动保存不做去重）均为人已裁定口径，本契约不再列为待决。

## 12. 假设与最可能爆掉的假设

1. **最可能爆：`checkpoint` 的推导读到的不是"本次提交的增量"**（读到历史条目或跨提交累积）→
   在非固定点写盘、或在固定点漏写。缓解：§7-05（反例）与 01–03（正例）成对覆盖，§7-09 断言重复不敏感。
2. **次可能：声明表标记与闭环清单不同步**（新增 kind 时忘记决定是否固定点）。缓解：§7-08 的双向一致 check。
3. **第三：`floor_enter` 只认上行**（与"走到更深的层"一致）；若将来希望"回到上层也算固定点"，
   须先改 `transition-pipeline` 的 kind 语义，再改本片标记（属跨契约改动）。
4. **第四：删掉恢复后写盘**（`:291`）后，读档时被 `restore_snapshot` 抬升过的 `version` 不再立即写回文件；
   该字段只是乐观并发计数，内容不受影响；若人要求"读档后必须立刻把版本写回"，需回 §11 重裁。
5. **第五：线稿写入会把"当前固定点起点"一起写入**（有意：文件内容始终是"起点＋最新线稿"），
   但画线也会刷新主档；若人认为画线不应触碰主档，需把线稿拆成独立文件（属新切片）。

## 协调者记录（2026-09-17）：§11 收口

- **§6 折叠边界：批准**。三条保证同时成立即可动用该边界（①`checkpoint` 只按 kind 集合与优先级取一，不得依赖条目条数或相邻重复次数；②"恰一条 `battle_end_*`"由闭环 check 与具名场景承接，另加"重复不敏感"具名 check；③审计留痕：六列投影 `5333ab64…` 与冻结脚本自比 31 条差异全在该列）。**若将来需要该列逐条精确的诊断，必须另立批次恢复严格比对**，不得在本片内放宽边界解释。
- **两条残余风险已知悉，暂不改**：①`floor_enter` **只认上行**（"进入新的一层"＝目标层更深）；若将来"回上层也算固定点"，须先改 `docs/transition-pipeline.md` 的 kind 语义，属行为口径变更、需立批；②删除恢复后那次写盘后，**读档不再立即把被抬升的 `version` 写回文件**——存档内容不受影响，最新内容在下一次固定点写入时落盘；若要求"读档即落盘"，回 §11 重裁。
- 本片其余口径均为已裁定项（三点固定点、加性 `checkpoint` 键、UI 只在非空时写盘、保留三条非进度写盘、闭环一致性与重复不敏感 check、性能＝场景内 `save` 段 0）。
