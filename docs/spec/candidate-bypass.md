# 候选层接口冻结与显示读取改线契约（candidate-bypass）

本文件是现行契约：**冻结候选层的接口**（它是提交时唯一的合法性权威），并把界面每次点击／每次渲染的
**显示读取**从「重新物化全量候选表」改成「按键读取」与「同一 View 内零读取」。
本片**不优化候选层内部实现**：不建字段依赖表、不做分段构建、不做写入差分、不做增量合并、
不改生产者与行工厂、不改装备只读查询接缝内部。
实现前置＝**协调者记录的人 OK 覆盖本片切线**；本片标 `needs-human-review`（理由见「假设与待决」H0），
人审通过前不得开工。本文件不写执行结果；通过／失败／未执行只登记 `docs/record/verification.md`。

本契约采用的解读（协调者记录）：候选层内部不做性能优化／重构；接口冻结；规划新接线，
让界面每次点击不再依赖全量候选表的重新物化来取得它要显示的东西。
另一种读法（「提交路径本身也必须低于一次全表物化」）会改变切法，见 H3／H4，不得由实现者自行采用。

路径约定：不带 `spire-godot/` 前缀的源码、测试与工具路径（`core/`、`ui/`、`data/`、`tests/`、`tools/`、`build/`）
均相对 `spire-godot/`；`docs/` 相对仓库根。

## 域

- 候选层**接口面**：行的形状与稳定 ID、提交复核语义、索引「只查找不重算」的边界。
- 界面**显示读取路径**：一次点击（选择类／提交类）与一次渲染分别读什么、读几次、成本上界是什么。
- 不含（本片非目标，点名即不得做）：候选层内部实现与其性能（生产者、行工厂、`core/card_effects.gd` 的
  候选枚举、`core/game_view.gd::build` 内部的投影算法）；装备只读查询接缝内部（见 `docs/spec/equipment-query-seam.md`）；
  存档与快照格式、随机域、数值与文案、输入语义与键位、动画与立绘。
- 目标：**每次点击的「显示读取」不再重新物化全量候选表**；提交路径的合法性权威仍只有候选层一条路径。

## 冻结面

以下符号与语义在本片内**冻结**。冻结的含义：本片不改它们的行为；本片之后要改，须走「改动程序」。

| 编号 | 冻结项 | 冻结的语义 |
| --- | --- | --- |
| F1 | `core/game.gd::candidates` | 返回**全量**候选行，按既有构建序；是提交复核与投影的共同来源；只读（不写 state、不推进随机、不改 version、不产日志与事件） |
| F2 | 候选**行的形状** | 键与含义：`id`／`payload`／`label`／`cost`／`mana`／`mana_payment`／`valid`／`reason`／`risk`／`group`，可选 `detail`；投影追加 `release_preview`／`casting`／`body_part`／`brief`／`brief_tags`；自动接管追加 `automated` |
| F3 | **稳定 ID** | `id` 只由 `payload` 决定（行工厂内的哈希表达式）；同一 payload 在任何状态、任何版本下得到同一 `id`；UI 只传 `id`，不解析 `id` 反推 payload |
| F4 | `core/game.gd::_candidate` | 行工厂是**唯一**写 `valid`／`reason`／`risk`／`mana_payment` 的位置；`card` 类 payload 不预生成 `detail`（按需经 `core/game.gd::candidate_detail` 现算） |
| F5 | `core/game.gd::dispatch(candidate_id, expected_version)` | 复核语义：六个 `validate` → 版本比对 → 在**当前** `candidates()` 中按 `id` 取首条命中行 → `valid` 闸门 → 事务与回滚；失败文案逐字不变；`candidate_id` 必须来自当前候选层输出 |
| F6 | `core/game.gd::_build_candidates`／`core/game.gd::_phase_candidates` | 候选**集合**（哪些行存在、顺序、组名）冻结；本片不得为省成本而删行、跳过组或改构建序 |
| F7 | `ui/action_index.gd` | 只查找不重算：`by_id`／`by_group` 只登记收到的行；`select`／`find`／`first_usable` 不判定资格、不造行、不改行 |
| F8 | `ui/main.gd::_submit` | 唯一提交入口；只传候选 `id` 与 `view.version`；不判定资格、不改写 core 的拒绝文案、不重试 |
| F9 | `core/game_view.gd::build` 的**值** | 候选派生的显示字段（`hand` 的 `availability`、`items` 的 `target_groups`／`unavailable_reasons`、`body_groups` 的 `can_release`、`reward_panel`、`route`、`first_turn_control`、`card_texts` 的显示集合）逐字段值冻结：本片只允许改**它们从哪里取行**，不允许改它们的值 |

**改动程序**（改冻结面需要什么）：① 改写本契约（不留「更正」段）；② 协调者记录的**人类批准**；
③ 重跑本契约点名的等价性判据与 `docs/spec/response-pipeline.md` 的锁定断言。
三者缺一即算未完成。实现者不得以「顺手」方式改冻结面。

## 新接线

### W1 按键读取（core，新增只读入口）

- `core/game.gd` 新增只读入口 `display_rows(needs)`（本片契约命名；该符号尚未落地，故本文不写成
  `文件::符号` 锚点；实现者不得改名，改名须改本契约）。
- 输入：`needs` ＝ 显示键数组；一个显示键 ＝ `{"group": String, "match": Dictionary}`，
  `match` 的字段语义与 `ui/action_index.gd::select` 的 `fields` **逐字相同**（payload 字段相等）。
- 返回语义（**定义即等价式**）：结果 ＝ 冻结全量构建中**满足任一显示键**的行，按既有构建序，
  逐字段与 `candidates()` 相同。即
  `display_rows(needs) == candidates().filter(任一键命中)`——顺序、行数、每个键值都必须相等。
- 实现约束（这才是本片的收益来源）：**只有可能产出被请求组的行工厂可以运行，每个至多一次**；
  请求之外的行工厂不运行。行工厂**内部**的计算本片不动（那是候选层内部）。
- 只读：不写 state、不推进随机、不改 version、不产日志与事件、不跨调用保留。
- 谁能调：只允许 `ui/main.gd` 的显示路径与测试。
- 禁则：`display_rows` **不是**合法性权威，`dispatch` 内不得调用它，也不得用它替换 `candidates()`
  的复核（F5 不动）。

### W2 同一 View 的渲染零读取（UI）

- `ui/main.gd::render` 的**局部刷新路径**：当传入 `snapshot` 与当前 `ui.view` 是**同一对象**
  且布局有效、且未命中兜底条件时，渲染
  ① 不重建 `ui.actions`（沿用当前索引）、② 不读 `view.candidates`、③ 只重建**节键发生变化**的节。
- 节名与节键内容**唯一来源**是 `docs/spec/response-pipeline.md` 的节键表；本片**不新建第二份节表**，
  只落地其中本批需要的节键。
- 兜底触发清单同样唯一来源＝`docs/spec/response-pipeline.md` 的 `present` 兜底条件（`phase` 变化、
  首页进出、`show_route` 切换、locale／显示设置变化、布局未实例化、View 为空、`reward_panel.active`、
  `demo_end`、`pressure.overloaded`、`card_chain` 非空、首次战斗教程等）；**节键缺失或未知也算兜底**。
- 选择类点击（选牌、选敌人、开身体栏、切抽屉）不得调用 `get_view`／`dispatch`／存档（现行语义不变）。

### W3 提交路径（权威不变）

- `ui/main.gd::_submit` 仍只传 `id` 与 `view.version`；`dispatch` 仍是唯一权威；`get_view` 的调用点集合不变
  （`_resume_snapshot`／`render` 空快照／`_submit`／`restart`），本片**不新增调用点**。
- 本片**不删除**提交后那次 `get_view`：它内部仍会做一次全表物化。该残余成本见 H3，未获裁定前
  不得宣称点击成本已降到一次物化以下。

### W4 复用规则（给不出失效条件就不许缓存）

- 允许的复用只有一种：**同一 View 内的复用**。行与 `ui.actions` 与 View **同批原子替换**；
  失效条件是可证的结构事实——**View 被替换（提交、`render` 传新快照、世界替换）即全部作废**，
  不存在跨 View 的复用。
- 明确禁止：用 `version` 当键或当缓存版本号（`version` 不单调，`restore_snapshot` 后可回退，进键会误命中）；
  跨 View 保留行、候选、装备图或节点引用；由 UI 自行推断作废范围；把行缓存进节点或节键。
- 跨操作保留 `ui.view`／`ui.actions` 与本地显示态**本来就允许**（见 `docs/spec/response-pipeline.md`），
  本片不扩大这条准入线。

### W5 成本上界（可测口径）

| 路径 | 现状（`621952c` 口径） | 本片目标 | 判据形式 |
| --- | --- | --- | --- |
| 选择类点击（同一 View） | `candidates()` 0 次、`ui/action_index.gd` 重建 1 次、整树重建（占该次点击 84–89%） | `candidates()` 0、索引重建 0、重建节 ≤ 3、**查询入口 0 次** | 测试侧计数（B1） |
| 提交类点击 | `candidates()` 2 次（`dispatch` 一次＋投影一次） | 本片保持 2；**若 H3 获批**再降到 ≤ 1 | 测试侧计数（B1／B3） |
| 世界替换与相位变化 | 全量 `get_view` | 不变（合法的全表物化点） | 既有断言 |

- 毫秒数**不是**完成判据，只作为报告项：同一机器、同一窗口、同一协议（2 次热身＋15 次有效配对，
  报逐对比值中位与两侧独立中位，p95 单列，跨批次数字不得拼接）。
- 硬性回归线：提交类点击与选择类点击的中位数**不得高于**改动前同机同协议数字的 110%。

## 分批

每批独立完工、独立提交、独立回退；**不得跨批开工**；后批被裁定否决时前批仍然成立。

| 批 | 范围 | 该批判据 | 前置 |
| --- | --- | --- | --- |
| **B1** | 同一 View 渲染零读取：局部刷新路径＋本批所需节键（`hand`／`body_details`／`notice`／`resources`）；其余节缺键即兜底 | 场景 1、2、6 | 切线人 OK |
| **B2** | `display_rows(needs)` 按键读取＋显示路径改读（`ui/main.gd` 的显示读取不再依赖整表列表） | 场景 3、4、5 | 切线人 OK |
| **B3** | 提交后投影的候选派生字段改由按键读取取得，使提交类点击的全表物化 ≤ 1 | 场景 3、7 | **H3 裁定通过**；未通过则本批不启动 |
| **B4** | `dispatch` 的取行不再全表物化（候选层内部寻址或核心侧跨调用复用） | — | **H4 裁定通过**；未通过则本批不启动 |

- B1 的收益只覆盖选择类点击；其余 `render` 调用点因节键缺失走兜底，行为与今日相同。
- B3／B4 未获批时，残余成本必须如实上报（见「证据入口」的报告义务），不得用「调用口径」掩盖工作量。

## 失败语义

| 条件 | 行为 |
| --- | --- |
| `needs` 为空、含未知组名、或含 `"*"` | 按键读取返回全量 `candidates()` 结果（fail-closed），并记录本次走了全量路径 |
| 节键缺失或未知 | 走整树重建兜底（今日行为），不得靠「没键就不重画」隐式实现 |
| 快照与当前 View 不是同一对象 | 走整树重建兜底 |
| 相位／世界替换 | 全量 `get_view`（`_resume_snapshot`／`restart`／`_quick_sl`／`render` 空快照） |
| 按键读取与全量构建不一致 | **不得静默降级**：判据直接失败（场景 3），实现按缺陷处理 |
| 提交被拒 | 仍由 core 决定文案；UI 只呈现；本片不改被拒路径 |

## 输入域

- 显示键的组名取值＝`docs/spec/candidate-delta.md` 的组清单（组名一字不改；该清单已存在于现行契约，
  本片**不新建组名表**，只消费它）。清单本身尚未落地为代码表，故实现者须先按该清单核对代码侧组名
  （`rg` 复算），不一致先回报，不得自行改名。
- 显示键的 `match` 只允许 payload 字段相等；不得用译文、名称、颜色或图片字段做键。
- `needs` 的规模上界：一次调用内显示键数量 = 该次渲染实际画出的控件所对应的键，去重后 ≤ 64（超出即兜底）。

## 验收程序（Gherkin）

每条 Given／When／Then 即实现与门禁的验收合同；落点写测试分类名（套件注册见 `tests/test_game.gd` 的
`SUITES` 与 `tests/ui_smoke.gd` 的 `UI_MODULES`）。计数一律用测试侧包装（`ui.game_factory` 注入计数子类，
生产源码不带计数器／计时钩子）。

1. `same_view_render_reads_nothing`（`display`，`tests/display_ui_cases.gd`）
   - Given 44 件装备的战斗夹具，已渲染一次
   - When 连续两次点击同一张手牌（选择类），再开一次身体栏
   - Then 每次点击的 `candidates()` 计数 0、`ui/action_index.gd` 构造计数 0、装备查询建表计数 0、
     重建节数 ≤ 3；未被重建节的节点实例 id 与位置不变；`notice` 文本等于该次读出的原因
2. `phase_change_full_rebuild_fallback`（`interface`，`tests/interface_ui_cases.gd`）
   - Given 同一 View 的局部刷新路径可用
   - When 提交一次会改变 `phase` 的行动
   - Then 走整树重建（页面容器实例替换、旧候选按钮不残留、hero／敌人实例不重复）；
     `show_route` 切换、locale 变化、`pressure.overloaded` 各有一个触发例与一个反例
3. `keyed_read_matches_full_build`（`architecture`，`tests/architecture_cases.gd`）
   - Given 夹具矩阵（0／12／26／44 件 × 战斗／整备／休息／商店／事件／监狱，同种子）
   - When 对每个 UI 显示键集合调用 `display_rows(needs)`
   - Then 结果与 `candidates().filter(任一键命中)` 逐行逐字段逐顺序相等；`state`／随机游标／
     `export_snapshot()` 不变；未命中任何键的行工厂计数 0
4. `keyed_read_fails_closed`（`architecture`）
   - Given 同上夹具
   - When 传入 `[]`、含未知组名、含 `"*"` 三种输入
   - Then 三者都返回与 `candidates()` 全量相等的结果，且不改变状态
5. `no_second_eligibility_path`（`architecture` ＋ 源文本断言）
   - Given 现行代码
   - When 扫描 `ui/` 与 `core/game_view.gd`
   - Then 没有第二处写 `valid`／`reason` 的位置；`ui/` 除 `ui/main.gd` 外无 `core/` 的 `preload`；
     `ui/action_index.gd` 的三个查询函数体未新增判定；渲染出的不可用文本等于行内 `reason` 原文
6. `submit_path_authority_unchanged`（`display` ＋ `architecture`）
   - Given 陈旧版本、已失效候选、`valid=false` 候选三种提交
   - When 经真实控件提交
   - Then 拒绝文案与改动前逐字相同；`dispatch` 内未出现按键读取调用；状态回滚完整；
     存档只在 `ok` 且 `checkpoint` 非空时发生
7. `click_cost_counters`（`display`，真实窗口）
   - Given 44 件夹具的真实窗口与真实指针
   - When 依次执行：打出一张牌／攻击／结束回合／翻面手牌／点选敌人／开身体栏／用一件道具／
     进商店买一件／进事件选完／读档／新局／快速 SL
   - Then 每次点击的 `candidates()` 计数、索引构造计数、装备查询建表计数与重建节数写入结果文件；
     选择类点击满足场景 1 的上界；提交类点击不超过改动前同协议中位数的 110%
8. `save_and_random_untouched`（`persistence`）
   - Given 任一夹具
   - When 走完显示读取路径与一次提交
   - Then `export_snapshot()` 在纯读取前后相等；随机域计数不变；`core/snapshot.gd` 的 `REVISION` 不变；
     不新增存档字段

## 判据与敏感性证明

「敏感性证明」＝把该判据的实现点换回旧路径（或去掉该判据守的机制），该具名 check 必须变红；
这条替换必须在本片的验证记录里以**一次实际运行**取证，不得推断。

| 判据 | 敏感性做法 | 现状（改动前）是否已红 |
| --- | --- | --- |
| 场景 1 的「索引重建 0、重建节 ≤3」 | 让同一 View 的 `render` 走回整树路径 | **今天就是红的**（每次 `render` 都重建索引与整树）——能看见回归 |
| 场景 3 的逐字段等价 | 从按键读取的行工厂表里删掉一个组／多挂一个组 | 今天无此入口，不适用；落地后即红 |
| 场景 4 的 fail-closed | 把未知组名改成返回空数组 | 落地后即红 |
| 场景 5 的第二判定 | 在 `ui/action_index.gd::find` 里合成一行（伪造 `valid`） | 落地后即红 |
| 场景 2 的兜底 | 从兜底触发清单里去掉 `phase` | 落地后即红 |
| **计数判据（新增，现有门禁看不见）** | 见下 | — |

**计数判据（协调者点名的缺口）**：现有门禁 `tests/architecture_cases.gd` 的测试侧计数类（`IndexCountingGame`）
只数「每作用域每边建表 ≤ 1 次」，而建表确实只有 1 次，所以它对「每次调用都跑全图遍历」是**盲的**
（实测一次投影内 `physical_pieces()` 入口数 = N+5，返回元素数 = N²+5N；12→44 件元素量 ×9.0 而件数只 ×3.7）。
本契约因此要求新增**入口次数与返回元素数**两族计数，并且分两级：

- **可达级（本片判据）**：同一 View 渲染路径的查询入口 0 次；按键读取只运行被请求组的行工厂，
  行工厂**入口数**不随件数增长（现状：全表构建运行全部行工厂）。
- **受限级（本片不得承诺，登记为 H1／H3 的后续）**：一次投影内 `physical_pieces()` 等查询入口数
  不得随件数增长（现状 N+5，目标常数）。它落在被冻结的装备只读查询接缝内部，
  在 H1 裁定前**不得**作为本片判据，也不得据此宣称提速。

## 证据入口

```powershell
& tools/check.ps1 -Suite architecture,persistence -Impact -TimeoutSeconds 900
& tools/check.ps1 -UIOnly -UISuite display,interface,targeting,body_layout,touch -TimeoutSeconds 900
& tools/check.ps1 -Suite runner -VerifyRunner
& tools/check-docs.ps1
```

- 范围预检：同列表加 `-ListOnly`（输出 `PLAN ONLY:`，不算通过）。
- 判读：退出码 0；每个分类 `SUITE RESULT: PASS`；完成标记 `PASS: N assertions`／`UI PASS: N assertions`；
  `summary.json` 的 `status=passed` 且 `before==after` 指纹（`source_changed` 不算通过）；引擎错误日志 0 行。
- 探针口径（复用 `621952c` 复现片：真实窗口＋真实指针，忽略目录 `build/repro-20260922/`）：
  夹具＝0／12／26／44 件、`SEED=20260922`、2 次热身＋15 次有效配对；标记名沿用
  `submit.dispatch`／`submit.get_view`／`render.total`／`submit.feedback` 与 `d.*`／`gv.*`／节内标记；
  产物只放已忽略目录 `build/<topic>-<date>/`，摘要登记 `docs/record/verification.md` 后删除原始目录。
- 判据用**计数与相等性**；毫秒数只作报告（现状基线，可直接引用，不重复测）：
  44 件档一次出牌提交 104–142 ms（`dispatch` 43–47%、`get_view` 35–48%、render 11–21%）；
  选择类点击 26.9–28.3 ms（其中 render 23.7 ms，占 84–89%）；候选行数 = 6N+28。
- 人的路径（判据是套件布尔 check）：战斗中依次打出一张牌／攻击／结束回合／翻面手牌／点选敌人／
  开身体栏／用一件道具／进商店买一件／进事件选完／读档／新局／快速 SL，逐项与改动前一致。
- 算未完成（任一）：任一必跑分类未执行／失败／无授权跳过；按键读取与全量构建不一致；
  出现第二份资格判定；`dispatch` 内出现按键读取；改动冻结面而未走改动程序；
  提交后 `get_view` 被删而 B3 未获批；用耗时数字当完成判据；只报调用次数不报工作量；
  生产源码留下计数器或计时钩子。

## 假设与待决

- **H0（为什么需要人审）**：本片不是「当前切线内的小调整」——它新增一个 core 只读入口（W1）、
  新增 UI 局部刷新机制（W2，与 `docs/spec/response-pipeline.md` 未落地的接缝 B 部分重叠），
  且 B3／B4 的可行性取决于尚未裁定的契约冲突（H1–H4）。因此按规划者章程标 `needs-human-review`，
  人审通过前不得开工。
- **H1（契约冲突，需人类裁定）**：`docs/spec/equipment-query-seam.md` 自己写着
  「不新增『每次调用都跑全图遍历』的路径：全图遍历只允许出现在作用域入口的建表里，每次作用域一次」，
  而该契约点名的两处症结（`core/game.gd::_query_stack_items` 每目标一次全件 `filter(Equipment.overlaps)`；
  `core/game.gd::targets_at` 的肩部槽每次全件扫）**今天就在违反这一条**；
  同一契约又把 `escape_preview` 的按需化明文判为「**未排期**，排期确认前任何一片都不得实现」。
  本片不替这两条做决定、也不假设会被解禁：H1 未裁定前，「入口次数不随件数增长」只登记为受限级判据。
- **H2（术语，需人类裁定）**：「同一判定、带提前退出的窄路径」算不算被禁的「第二份判定」？
  这决定 B3 能否在不写第二份资格逻辑的前提下把提交类点击降到一次物化。本契约不预设答案。
- **H3（提交后投影，需人类裁定）**：B3 要让提交类点击的全表物化 ≤ 1，必须让 `core/game_view.gd::build`
  的候选派生字段（F9）改由按键读取取得。这属于「投影取值来源」的改动，须 H2 先裁定。
- **H4（核心侧跨调用复用，需人类裁定）**：B4 要让 `dispatch` 的取行不全表物化，只有两条路——
  候选层内部寻址，或核心侧跨调用复用候选结果。后者与
  `docs/spec/equipment-query-seam.md` 的「不得跨调用保留任何索引内容」、
  `docs/spec/candidate-delta.md` 的「核心侧不跨提交保留查询结果」直接冲突，且需要可证失效规则
  （任何直接写 `state` 的路径都必须让它失效，今天测试与夹具大量直接写 `state`）。
  本契约不假设它会被解禁；未解禁时 B4 不启动，残余成本如实上报。
- **H5（旧契约的去留，需人类裁定）**：`docs/spec/candidate-delta.md` 是**未落地**的旧片契约
  （其 C0–C4＝依赖表／分段构建／写入差分／增量视图），与本片方向不同。按文档规则「被取代即删」，
  它应当被删除或改写为新事实；本契约不代它做决定，也不删别人的文件——请协调者指定归属后再动。
- **A1（最可能爆）**：显示键的组名来自 `docs/spec/candidate-delta.md` 的清单，该清单**尚未落地为代码**，
  且其「复核项（未决）」自己写着 `rest` 相位的 `hook` 组未列。实现者必须先按代码复算组名集合，
  不一致时停下回报，不得自行改名或补组。
- **A2（收益上限）**：本片不改行工厂内部，所以**单次全表物化的成本不变**；本片只能减少物化次数与读取面。
  任何「显著提速」的表述都不许写；报数只报计数与实测中位数。
- **A3（B1 与 response-pipeline 的重叠）**：B1 落地后，`docs/spec/response-pipeline.md` 的实现状态句
  （「尚无 `commit`、`present`、`present_rejection` 或通用脏节表」）会变成部分过期，必须同批改写为新事实，
  不留「更正」段；节键表本身仍以该文件为唯一来源。

## 记录义务（实现完成后，不在本文件假装已跑）

- `docs/record/changelog.md`：每条带日期＋域（本片＝候选层接口冻结与显示读取改线）＋本次落地的批次。
- `docs/record/verification.md`：每条带日期＋域＋命令＋结果＋**未跑项**；写明走的是哪条路径的计数、
  未获批而未启动的批次（B3／B4）与残余成本；不得把未跑写成通过。
- 落地后同步：根 `AGENTS.md` 的文档入口表加一行指向本文件；`docs/spec/response-pipeline.md` 的实现状态句按 A3 改写。
