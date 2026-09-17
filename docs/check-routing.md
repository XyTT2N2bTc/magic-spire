# 检查索引与失败隔离契约（派生索引路由 + 单套件失败不拖垮整轮）

规划者契约（本文件是切片的接口合同与依赖约束的载体；实现者按此落地，validator 按 §7 验收）。
状态：**待协调者记录人审**（`needs-human-review`，理由见 §11）。域：`spire-godot` 检查入口
（`tools/check.ps1`＋`tests/`），**不改产品代码**（`core/`、`ui/`、`data/`、`content/`）。

---

## 0. 切片与非目标

人给的判据（2026-09-17）：

1. **常态不再跑全量**：按"改了哪些文件"路由出该跑的套件，选择**可核验、可自证完整**；全量只在版本级／跨域大改动时跑一次。
2. **单套件失败不再拖垮整轮**：脚本错误记为**该套件失败并标注 runtime 错误**，其余套件照常跑完，`unrun` 不再作为常态出现。
3. **不弱化既有语义**：退出码、源码指纹与 `source_changed`、`summary.json` schema、规则／界面两相分离、各 flag 既有含义不得改坏；验证册里已登记的结论继续成立（尤其 2026-09-16／17 引用 `summary.json` 字段与红集口径的条目）。

路线裁定（协调者 2026-09-17，人提出"不如建索引"）：路由**不写手写映射表**，改为
"**从仓库自身派生 → 冻结进仓库 → 双向自检 + 零漂移 → 按索引路由**"（§3）。

**非目标（硬线）**：不改产品代码；不改冻结 oracle 与基线（`build/event-oracle-20260916/`、`build/transition-oracle-20260916/` 脚本与基线一字不动）；不改各套件内部断言、不修任何既有红项（`installed_tools`／`hand_assist`／`card_power`／`tower_progression`／`home_persistence` 保持红，只改"如何跑"）；不改红集口径；不改存档格式与 UI 行为；不新增运行时依赖；不打包、不发版、不推送；不新建 CI；不动 `-Suite`／`-UISuite` 显式选套件的既有用法；`-Suite all`／`-UISuite all` 全量仍保留且是里程碑专用；**不为了路由去改测试写法**（不要求套件加注释、加标签或改命名；索引只读仓库现状）。

## 1. 问题锚点（现状事实，本片据此改）

| # | 位置 | 现状 | 后果 |
| --- | --- | --- | --- |
| A1 | `spire-godot/tests/test_game.gd:65-68` | `runtime_error` 时**即使带 `-KeepGoing` 也 `break`** | 任一含脚本错误的套件（`installed_tools` 每轮触发）截断整轮，其后 16–24 类 `unrun`，必须补跑 |
| A2 | `spire-godot/tests/ui_smoke.gd:54,63-66` | 同一 break 逻辑＋setup 期错误直接 `return`（不打印 `SUITE RESULT`） | UI 阶段同样截断 |
| A3 | `spire-godot/tests/suite_selection.gd:16-44,58-69` | 只有"分类 ↔ 语义区域"的 `CROSS_AREAS`（46 条手写，仅服务 `-Impact`）＋`resolve` | 无法按"改了哪些文件"路由；`-ListOnly` 只列计划，不校验完整性 |
| A4 | `spire-godot/tests/test_game.gd:59-61` | 套件加载失败 → `quit(1)` 整轮结束 | 单个坏测试文件拖垮其余套件 |
| A5 | 实测墙钟（本机 2026-09-17） | 宽集规则门 135s；18 类 `unrun` 合并补跑 265s（2026-09-17 更正：原写 19 类；日志 `build/checks/20260917T003417097-32852`／`…T010002039-35512` 的 `summary.json` `unrun` 均为 18）；界面门 106s；事件 oracle 11s；迁移 oracle 9s；内容门 4s；全轮 ≈8m50s，其中 ≈400s 用于绕开中断 | 常态成本高且不可靠 |
| A6 | 现状无覆盖索引 | `CROSS_AREAS` 是"分类↔分类"；断言消息里的域前缀（`EVENT`／`PRISON`／`SAVE`／`COPY`／`WITCH`…，实测 261 个不同前缀／5452 条带前缀断言）从未用于路由；`docs/*-dependency-spec.md` 只写依赖方向 | 没有任何产物能回答"改这个文件要跑哪些套件" |

## 2. 命令面与兼容面

### 2.1 模块切分（Deep Module）

| 单元 | 文件 | 接口（小、稳定） | 隐藏的内部 |
| --- | --- | --- | --- |
| 索引派生与读取 | `spire-godot/tests/check_index.gd`（**新增**，纯静态） | `derive() -> Dictionary`、`frozen() -> Dictionary`、`compare(a,b) -> {ok,first_diff}`、`suites_for(files) -> {suites,signals,unmapped,blind}` | 三类文本信号扫描、套件归属闭包、域解析、排序与摘要 |
| 手写补充层 | `spire-godot/tests/check_index_edges.gd`（**新增**，数据＋理由） | `DOMAINS`（盲区文件→域词，含 `reason`）、`WIDEN`（声明放大）、`EXCLUDE`（夹具层等，含理由）、`BLIND_BY_DESIGN`、`INDEX_DEFECTS` | 只放派生不出来的知识，逐条写理由 |
| 冻结索引 | `spire-godot/tests/check_index.json`（**生成物，入库**） | 只读 JSON（schema 1）：`suite_files`／`case_files`／`domains`／`blind`／`stats`／`generated_from`／`digest` | 生成细节；**永不手改** |
| 索引生成器 | `spire-godot/tools/build_check_index.gd` ＋ `tools/check-index.ps1`（**新增**） | `-Write` 重新派生并覆盖冻结物；缺省＝按零漂移校验（退出码 0／1） | 与 `check_index.gd` 共用同一派生实现 |
| 计划宿主 | `spire-godot/tests/route_plan.gd`（**新增**，CLI） | `--files=<path> --plan=<json>`；打印 `ROUTE *` 行并写计划；退出码 0＝计划可用 | 读冻结索引、算路由、JSON 写出 |
| 执行器 | `spire-godot/tools/check.ps1`（扩展） | 新参 `-Changed`／`-Since`／`-ChangedList`；其余 flag 语义不变 | git 取变更集、调用计划宿主、灌进既有 `-Suite`／`-UISuite` 执行路径、`summary.route` |
| 阶段隔离 | `spire-godot/tests/test_game.gd`＋`tests/ui_smoke.gd` | 既有 `SUITE START/RESULT` 行不变，新增 `SUITE RUNTIME: <name> <n>` | 逐套件窗口的错误计数与继续执行 |

依赖方向（本片允许的边，不得新增其它边）：
`check_index_edges.gd` → `check_index.gd`（数据被读）；`check_index.json` 只被 `check_index.gd` 读；
`route_plan.gd → check_index.gd`；`tools/build_check_index.gd → check_index.gd`；
`runner_cases.gd → check_index.gd`；`test_game.gd`／`ui_smoke.gd` 不改依赖（只改自身控制流）；
`check.ps1 → route_plan.gd`＋既有 `test_game.gd`／`ui_smoke.gd` 入口。
**禁止**：`core/`／`ui/`／`data/` 引用 `tests/`；`check_index.gd` 预载宿主脚本（`test_game.gd`／`ui_smoke.gd`）；
`route_plan.gd` 引用 `core/`；出现第二份"文件→套件"映射（索引只此一份，派生或声明都在 §2.1 三个文件内）。
本片不新增运行时依赖（生成器只用 Godot 内建 ＋ PowerShell）。

### 2.2 路由解析语义（确定性、可打印、可解释）

对每个变更文件（仓根相对路径）：

1. **索引命中** → 该文件的套件集 ＝ 冻结索引里指向它的套件（每条边带信号类别：`preload`／`symbol`／`symbol_ui`／`domain`），再并上该文件在 `WIDEN` 里的**声明放大**（每条带理由；可写 `impact:<区域>`，即现有 `CROSS_AREAS` 的一次性展开）。
2. **索引未命中**（盲区文件）→ 按目录**过近似闭包**（§5.3）：`spire-godot/core/**`／`data/**` → `all-dev`（规则），`spire-godot/ui/**` → `all-dev-ui`，`content/packs/**` → 内容消费者 ＋ 内容门，`tests/**` → 归属套件，`assets/**`／`tools/**`／模块根 → 各自声明集。计划里逐条打印 `ROUTE DEFAULT: <path> (blind, closure=<edge>)`。
3. **两者都未命中**（`spire-godot/` 下的新目录等）→ **fail-closed**：`all-dev`＋`all-dev-ui`，并在计划与 `summary.route.unmapped` 里逐条列出（不得静默、不得当"无需跑"）。
4. **仓库外路径**（不在 `spire-godot/` 下、也不匹配任何 `declared_none` 行）→ 起引擎前拒绝（退出码 1）：那不是源码。
5. `declared_none` 只允许指纹面之外（`docs/`、`release/`、`.zcode/`、根说明文件、`spire-godot/build/`、`spire-godot/.godot/`）：文档改动 → 无套件，`status=plan`、退出码 0，**永不作为通过**。
6. 结果集并集去重，顺序按注册表顺序（规则套件按 `SUITES`，界面套件按 `UI_MODULES`），便于逐字比对。
7. `all-dev`／`all-dev-ui` ＝ 全部规则／界面套件 **减去 `MILESTONE`**（`stage()=="milestone: explicit long run"`，当前 `{normal_play, baseline}`；理由 §10-1，待确认 §11-3）。
8. 计划里每个文件都打印一行（`ROUTE ROW`／`ROUTE DEFAULT`／`ROUTE UNMAPPED`），任何"少选／多选"都可见。

计划输出（`check-route.log`，示例）：

```
ROUTE MODE: changed (development feedback only; milestone gates use -Suite all -UI -UISuite all)
ROUTE FILES: 2 (sha256 1a2b3c…; index digest 9f8e…)
ROUTE ROW: spire-godot/core/save_store.gd -> rules=encyclopedia,persistence ui=home,home_persistence,persistence [signals=preload]
ROUTE ROW: spire-godot/tests/route_plan.gd -> rules=runner [signals=symbol]
ROUTE DEFAULT: (none)          # 盲区文件走目录闭包时逐条列出（含闭包边）
ROUTE UNMAPPED: (none)         # fail-closed 的文件逐条列出（非空≠红，但必须在报告里出现）
ROUTE WIDEN CANDIDATE: persistence -> CROSS_AREAS 里另有 N 个套件声明该区域（未自动加入；需要时写 WIDEN）
ROUTE RULE SCOPE: encyclopedia,persistence
ROUTE UI SCOPE: home,home_persistence,persistence
ROUTE GATE: content
PLAN ONLY: no game tests executed     # 仅 -ListOnly
```

### 2.3 命令面（flag 与两种用法）

```powershell
# 开发（常态）：按工作区变更路由；默认 base=HEAD
& tools/check.ps1 -Changed
& tools/check.ps1 -Changed -ListOnly                     # 只出计划，不算通过
& tools/check.ps1 -Changed -Since <ref>                  # 已提交后：ref → 工作区
& tools/check.ps1 -ChangedList build/checks/<id>/changed-files.txt   # 显式清单（探针／非 git 调用方）
# 索引维护（判据只读；重新派生必须显式执行）
& tools/check-index.ps1            # 零漂移校验（退出码 0／1）
& tools/check-index.ps1 -Write     # 重新派生并覆盖 tests/check_index.json（与源码同批提交）
# 里程碑／交付前（不路由；PR、打包、发版、版本推进一律用这条）
& tools/check.ps1 -Suite all -UI -UISuite all -TimeoutSeconds 900
# 既有定向用法（语义不变）
& tools/check.ps1 -Suite casting,pressure -Impact
& tools/check.ps1 -UIOnly -UISuite equipment_art,hero_art
& tools/check.ps1 -Suite runner -VerifyRunner
```

- `-Changed`：变更集 ＝ `git -c core.quotepath=false diff --name-only <base>` ＋ 未跟踪文件（`ls-files --others --exclude-standard`）；base 默认 `HEAD`，`-Since <ref>` 覆盖。规范化：仓根相对、`/` 分隔、排序去重、保留删除项；解析不了的行（重命名等）→ 拒绝并提示改用 `-ChangedList`（不猜）。变更集与 `HEAD` 相同（空集）→ 拒绝并提示"改动已提交，用 `-Since <base>`"。
- `-ChangedList <path>`：一行一仓根相对路径，`#` 与空行忽略；用于 `-VerifyRunner` 探针与确定性复跑。与 `-Changed` 互斥。
- 互斥／拒绝（**在起引擎前**，沿用现有习惯）：`-Changed`／`-ChangedList` 不得与 `-Suite`、`-UISuite`、`-UI`、`-UIOnly`、`-Impact` 同用；`-Since` 必须配 `-Changed`；`-RerunFailed` 不得与三者同用。允许与 `-Exhaustive`、`-ListOnly`、`-TimeoutSeconds` 同用。
- **默认行为**：人工与将来可能的 CI 都只走 `-Changed`；`check.ps1` 无参数时的默认 `-Suite runner,architecture` **不变**。
- **里程碑规则（控制 3 的落点）**：§2.3 的里程碑命令行是唯一入口；同一句话写进 `.zcode/skills/repo-ops/SKILL.md`——路由只服务开发期快速反馈，**PR／打包／发版／版本推进前跑全量**，`-Changed` 结果不得作为交付或里程碑门禁。
- `-ListOnly -Changed`：只跑计划宿主并打印 `PLAN ONLY: no game tests executed`；不启动测试宿主（因此不同于显式 `-Suite -ListOnly` 的引擎侧计划路径）。
- `summary.json` **加性**字段（`schema` 仍为 1）：`route={mode:"changed"|"list"|"explicit", since, files_count, files_sha256, index_digest, rules[], ui[], gates[], unmapped[], default_files[], blind_files[], defect_hits[], plan, log}`。既有键一律不动。

### 2.4 向后兼容面（不得改坏；逐项给引用）

| 面 | 不得改变的内容 | 已登记引用（复审点） |
| --- | --- | --- |
| `summary.json` | `schema=1`；`status ∈ {plan,passed,failed,source_changed}`；`error`；`impact`；`exhaustive`；`verify_runner`；`before`／`after`；`rules.{selected,passed,failed,unrun,retry,scope_resolved,complete,log}`；`ui.*` | `docs/verification.md` 2026-09-16 整片验收（红集＋`unrun` 清单）、2026-09-17 两片（`summary.json` 复核／界面门）、`docs/event-pipeline-unification.md` §11.2 |
| 日志 token | `CHECK LOGS:`／`RULE SCOPE:`／`UI SCOPE:`／`SUITE START: <name>`／`SUITE RESULT: <name> PASS\|FAIL`／`PASS: <n> assertions`／`UI PASS: <n> assertions`／`FAIL:`／`SAMPLES `／`PLAN ONLY:`／`SUMMARY:`／`SOURCE CHANGED:`／`RERUN:` | `tools/check.ps1:72-91,118-132,193-207` 的解析器；上表同一批条目 |
| 退出码 | 0＝（计划／通过），1＝任何红／拒绝／超时／`source_changed` | 全部已登记条目 |
| `-RerunFailed <目录\|summary.json>` | 读 `rules.retry`／`ui.retry`；`plan`／`passed` 摘要拒绝 | `docs/verification.md:627`、repo-ops |
| 指纹 | 目录 `core,data,ui,tests,content,assets,tools` ＋扩展名集＋模块根文件（`tools/check.ps1:54-70`） | 上表同一批条目；**索引扫描面与冻结物都在指纹面内**（§3.3） |
| `-KeepGoing` | 参数保留、可继续传；含义变为"默认行为"的兼容无操作 | repo-ops（`-KeepGoing` 选项）；`docs/event-pipeline-unification.md` §12（A29）；`docs/transition-pipeline.md` §6 |
| 其它 flag | `-Impact`／`-Exhaustive`／`-Suite`／`-UISuite`／`-UI`／`-UIOnly`／`-Import`／`-Screenshots`／`-VerifyRunner`／`-TimeoutSeconds` 语义不变 | repo-ops；已登记命令逐条可复跑 |

新增 token（不改旧 token 含义）：`SUITE RUNTIME: <name> <n>`（该套件窗口内引擎错误数，`n≥1` 才打印）；`ROUTE *` 前缀行；`PLAN ONLY: no game tests executed`。

## 3. 索引：派生／冻结／自检／路由

**索引解决的是静态"谁碰了谁"。** 它按信号从仓库现状派生，不允许为了好建模去改测试写法。

### 3.1 信号来源（实测 2026-09-17，本规划会话；可复现：三类正则扫描 176 个 `tests/*_cases.gd`）

| 信号 | 提取方式 | 实测规模 | 精度 |
| --- | --- | --- | --- |
| `preload` | 用例文件里的 `preload("res://(core\|data\|ui)/…")` | 55 个源文件被 ≥1 用例文件直接预载（按目录计 `core` 22/47、`data` 17/26、`ui` 15/47）；`core/game.gd` 24 例、`data/encyclopedia.gd` 17 例 | 精确 |
| `symbol` | 用例文件里对游戏门面的调用 `(g\|game\|t.game\|ui.game).<成员>(` → 名字在 `core\|data\|ui` 里的**声明文件**（同名多处＝全收，只放大不缩小） | 1652 个 (用例文件, 成员) 对；536 个函数名中 **515 个只在 1 个文件声明**；173/176 用例文件至少得到 1 条唯一边 | 多数精确，少数（7 个多声明名）放宽 |
| `symbol_ui` | UI 用例文件里的 `ui.<成员>` → `ui/**` 声明文件 | 710 个 (UI 用例文件, 成员) 对；`ui` 侧在 `preload`（15/47）之外合并 `symbol`／`symbol_ui` 后覆盖到 **28/47** | 偏粗（`ui/main.gd` 是巨型宿主） |
| `domain` | 断言消息的首个大写词（`SAVE`／`EVENT`／`PRISON`／`PASSIVE`／`COPY`／`WITCH`…） | 5452 条带前缀断言、**261 个不同前缀**；名称与套件强相关（`PRISON`→prison、`SAVE`→persistence） | 仅用于**手写层的域解析**（§3.5），不单独成边 |

**派生结果（实测）**：97 个注册套件里 **63 个**得到 ≥1 条派生边；**306 条套件→源文件边**；冻结 JSON ≈ **11 KB**；
`core`＋`data`＋`ui` 共 120 个 `.gd` 里 **67 个**有派生边，**53 个盲区**（`core` 25、`data` 9、`ui` 19）。
（2026-09-17 被冻结物取代：`spire-godot/tests/check_index.json` 现状＝注册 97 个套件（规则 51＋界面 46）里 `suites_with_edges` **94**、`suite_edges` **437**、`sources_with_edges` **117/120**、体积 **71 KB**、盲区 **4**；本段 63／306／≈11 KB／67／53 为撰写时值。）
样例（可复现）：`core/save_store.gd` → 规则 `encyclopedia,persistence`＋界面 `home,home_persistence,persistence`；
`core/pressure.gd` → `casting,curses,pressure`；`data/tower.gd` → `equipment_complete,tower,tower_progression`；
`core/game.gd` → 18 个套件；`core/snapshot.gd`／`core/prison.gd`／`core/installed_tools.gd`／`data/relics.gd` 现均有派生边（`core/snapshot.gd` 由 `domain` 信号直连 `persistence`，已非盲区）；**盲区只剩 4 个**：`core/item_presentation.gd`／`core/release_view.gd`／`core/tool_rules.gd`／`data/phases.gd`。

### 3.2 派生算法（确定性，实现者按此写 `CheckIndex.derive()`）

1. **注册表与归属**：从 `tests/test_game.gd` 的 `SUITES` 与 `tests/ui_smoke.gd` 的 `UI_MODULES` 取注册根（沿用
   `tests/runner_cases.gd:46-47` 的归属算法：只跟随 `preload("res://tests/…").run(t…)` 调用），得到
   `用例文件 → 唯一归属套件`（实测 176 个文件、无多重归属）。
2. **逐用例文件取信号**：`preload` 目标（`core|data|ui` 下）＋门面调用符号（名字→声明文件，多个声明全收）
   ＋UI 侧 `ui.<成员>`；`tests/game_fixture.gd`、`tests/route_driver.gd`、`tests/error_collector.gd`、
   `tests/suite_selection.gd`、两个宿主脚本**不参与精确边**（夹具层太粗：实测 123/176 个用例文件预载
   `game_fixture.gd`，其闭包会把所有套件连到 `core/game.gd`）——它们进 `EXCLUDE`，逐条写理由。
3. **域解析（盲区专用）**：对盲区文件，用手写层 `DOMAINS{path→[域词], reason}` 把域词解析成
   "用例消息里用过该域词的全部套件"。域词必须在语料里出现过（否则红）。
4. **反向索引**：`suite → {源文件 → [信号类别]}`（冻结物主表）＋`用例文件 → {owner, 信号计数}`（覆盖自检用）。
5. **确定性**：键排序、LF、UTF-8 no BOM、无时间戳；`generated_from` ＝ 全部输入（路径, 文本 sha256）排序后的 sha256；`digest` ＝ 主表的 sha256。**同一输入必须逐字节同输出**。

### 3.3 冻结物（入库）与生成器

- **路径：`spire-godot/tests/check_index.json`**。理由：① 运行期必须能被套件通过 `res://tests/check_index.json` 读到——
  索引在 Godot 工程内；`docs/check-index.json` **不可行**（`docs/` 在工程外，`res://` 读不到，只能用绝对路径，脆弱且越界）；
  ② `tests/` 在源码指纹面内，且 `.json` 在指纹扩展名集内 →**手改冻结物会同时被指纹与零漂移检查抓住**；
  ③ 与它索引的注册表（`SUITES`／`UI_MODULES`）同目录，便于同批复核。
- **生成器：`tools/build_check_index.gd`（headless）＋`tools/check-index.ps1`**（沿用 `tools/check-content.ps1`＋
  `tools/check_content.gd` 的既有式样）。派生实现只有一份（`tests/check_index.gd`），生成器与自检共用，避免两套实现漂移。
- **判据只读**：检查流程**永不**自动重写冻结物；更新只能显式 `-Write`，并与源码**同批提交**。
- **更新触发**：`tests/**` 或 `core|data|ui` 源码变化会改变派生结果 → 同批 `-Write` 重新冻结；忘了就由零漂移自检红。

### 3.4 索引自检（双向 + 零漂移；落 `tests/runner_cases.gd` 具名 check + `tools/check-index.ps1`）

| # | check | 判据（红＝打印锚点：JSON 键路径／`文件:行`） |
| --- | --- | --- |
| i | `index_covers_every_case_file` | 每个含 `static func run(` 的 `tests/*_cases.gd` 都出现在 `case_files` 里，且 `owner` 与归属算法一致 |
| ii | `index_targets_exist` | 每条边的目标路径在磁盘上存在（文件／目录），否则打印该路径 |
| iii | `index_matches_regeneration` | `CheckIndex.derive()` 与冻结物**逐字节相等**（零 diff）；不等则打印第一处差异的键路径 |
| iv | `index_suites_are_all_reachable` | 每个注册套件都是主表的键，或在 `BLIND_BY_DESIGN` 里有理由；否则打印套件名（防孤岛） |
| v | `index_skips_no_source_file` | `core|data|ui` 每个 `.gd` 要么有派生边、要么在 `DOMAINS`、要么在 `BLIND_BY_DESIGN`（含理由）；否则打印路径 |
| vi | `index_declared_domains_exist` | `DOMAINS` 里每个域词在语料里出现过；`WIDEN` 的 `impact:<区域>` 必须是已登记区域；否则打印条目 |
| vii | `index_defects_stay_closed` | `INDEX_DEFECTS` 每条记录补的边／域仍在主表里（不得回退）；否则打印该条 |
| viii | `index_regeneration_is_the_only_writer` | 冻结物的 `digest`／`generated_from` 与当前输入一致（＝iii 的机器可读形式；`tools/check-index.ps1` 的退出码证据） |

**式样**：沿用 `docs/transition-pipeline.md` §4／`tests/architecture_cases.gd:104` 的既有闭环 check——表外即红、未命中即红、打印锚点。
**性能**：自检与既有 `ownership` **共用一次扫描**；`runner` 套件的墙钟增量必须实测（目标 ≤10s，写入验证记录）。

### 3.5 手写层（只保留派生不出来的，逐条写明理由）

`tests/check_index_edges.gd`（纯数据，人类审查面）：

- `DOMAINS`：盲区源文件 → 域词 ＋ `reason`。约 **53 条**（实测盲区数），例：
  `{"path":"spire-godot/core/snapshot.gd","domains":["SAVE"],"reason":"存档校验经门面调用，无直接 preload"}`、
  `{"path":"spire-godot/core/installed_tools.gd","domains":["PASSIVE","TOOL"],"reason":"用例经 game_fixture 走门面"}`。
- `WIDEN`：声明放大（每条带理由），例：`{"path":"spire-godot/core/game.gd","add":"impact:persistence","reason":"存档写入经 game 提交"}`；
  **不写的区域不会自动加入**（计划只打印 `ROUTE WIDEN CANDIDATE` 提示）。
- `EXCLUDE`：不参与精确边的夹具／宿主层（`game_fixture.gd`／`route_driver.gd`／`error_collector.gd`／`suite_selection.gd`／两个宿主），
  逐条写"夹具层太粗，无法区分"的理由。
- `BLIND_BY_DESIGN`：连域词都落不上的文件（预期为空或个位数；每条必须有理由并说明由 §5.3 的哪条闭包兜住）。
- `INDEX_DEFECTS`：学习环登记（§5.5）。

### 3.6 盲区（已知，不是缺陷而是覆盖面事实）

实测 53 个盲区文件里（2026-09-17 被 `spire-godot/tests/check_index.json` 取代：现为 4 个盲区／117 个有边，共 120 个源文件），多数能被域词＋`WIDEN` 解析（`snapshot.gd`→`SAVE`、`prison.gd`→`PRISON`、`installed_tools.gd`→`PASSIVE`…），
但**不是全部**：`core/tool_rules.gd`、`core/item_presentation.gd`、`core/release_view.gd`、`data/phases.gd` 这类
"被投影／文案间接消费"的文件没有专属域词。这些进 `BLIND_BY_DESIGN`，由 §5.3 的目录闭包（`core/**`→`all-dev`）兜住——
即**盲区默认全量，不会漏跑**（fail-closed）。DoD 要求 `BLIND_BY_DESIGN` 逐条给理由，且不得用它来掩盖"没做域解析"。

### 3.7 路由侧读取

路由只读**冻结物**（不重新派生），因此计划宿主成本＝一次 JSON 读＋引擎启动；派生成本只落在生成器与自检。
`check.ps1` 在 `summary.route.index_digest` 记录本次使用的索引摘要 → 报告可回溯"这次路由基于哪版索引"。

## 4. 隔离契约（脚本错误与失败不再拖垮整轮）

### 4.1 规则阶段（`tests/test_game.gd`，不得偏离）

1. `SUITE START: <name>` 与 `SUITE RESULT: <name> PASS|FAIL` 的行格式与位置不变（解析器依赖）。
2. 判定 `failed` ＝ 断言数增量 > 0 **或** 引擎错误增量 > 0；`failed` 时追加 `SUITE RUNTIME: <name> <引擎错误增量>`。
3. **不得 `break`**：无论断言失败、脚本错误还是 `-KeepGoing` 与否，后续套件一律继续执行。
4. 套件加载失败（`load()` 为 null／不可实例化）→ 记该套件为 FAIL（另打印 `SUITE LOAD FAILED: <name>`），继续跑其余套件（取代今天的 `quit(1)`）。
5. 收尾判定不变：有任何断言失败或引擎错误 → `FAIL:` ＋ `quit(1)`；否则 `PASS:` ＋ `quit(0)`；`-KeepGoing` 保留为兼容无操作。
6. 结果：`summary.rules.unrun == []`（除超时／进程被杀）；`unrun` 仍作为超时与崩溃的兜底字段保留。

### 4.2 界面阶段（`tests/ui_smoke.gd`）——含条件性交付

同一套改动（第 2–4 条等价物）。**附加**：setup 期（`ui.restart` 等）出现引擎错误时也要打印 `SUITE RESULT: <name> FAIL`＋`SUITE RUNTIME`
后再进入下一模块（今天直接 `return`，摘要里该模块没有结论）。**条件**：Gherkin ① 的 UI 探针必须证明
"`await suite.run(self)` 内的脚本错误会返回控制权"；若不成立（挂起），UI 侧改动按 §10-2 回退为"该模块 FAIL(runtime) 且记 `unrun`"，
并把偏差回协调者；规则侧隔离仍照 §4.1 交付。

### 4.3 取代 A29（supersession，逐条登记；旧文本保留为历史事实，由实现者加一行指针）

| 被取代的旧口径 | 位置 | 新口径 |
| --- | --- | --- |
| "`-Impact` 展开集里某分类 `SCRIPT ERROR` 会让其余分类 `unrun`；判据是'把 `unrun` 分类补跑完之后……'，报告必须列出 `unrun` 清单与补跑结果" | `docs/event-pipeline-unification.md:1281-1286`（A29）、§12 判据段 | 脚本错误只记该套件 FAIL(runtime)，同轮跑完其余套件；`unrun=[]`；**"逐分类补跑"退化为历史做法**，仅超时／崩溃才可能再出现 `unrun` |
| "`-KeepGoing` 下若出现 `unrun` 分类，合并为一次调用补跑" | `docs/transition-pipeline.md:218-221` | 无需补跑；`-KeepGoing` 为兼容无操作 |
| "首个失败分类结束后停止，`-KeepGoing` 仅继续当前阶段的断言失败，运行时错误仍停止" | `docs/verification.md:625,627`（2026-09-11 条目，历史记录，不改写） | 新记录按本契约执行；旧条目保留为历史 |
| "`-KeepGoing` 跑完全部分类" | `.zcode/skills/repo-ops/SKILL.md:38` | 改为"默认跑完全部已选套件；`-KeepGoing` 兼容保留" |
| "`-Suite runner -VerifyRunner` 含失败停止与继续执行反例" | `docs/changelog.md:447`（历史日志，不改写） | 探针改为**隔离反例**（§7-1） |

**明确**：`-RerunFailed` 仍是唯一"续跑"入口（只重跑失败与未完成），语义不变；它是**红项／超时后的补救**，不再是绕开中断的常态步骤。

## 5. 风险与风险控制（人提出："这个游戏体现出反直觉与不可测，不全量需要承担风险"）

### 5.1 历史证据（"漏检会发生且不可预测"）

| 证据 | 位置 | 教训 |
| --- | --- | --- |
| `home_persistence` **只在组合形式下红**（单跑 `persistence`、`home` 全绿，组合套件 3 条断言失败；此前从未跑过该组合） | `docs/verification.md:4543` | **索引只能看见静态"谁碰了谁"，看不见"组合才红"** → 组合与里程碑全量不可省 |
| `has_relic` 内容条件改动炸的是**存档校验**（`core/snapshot.gd:391`），写入成功、读档失败，不对称 | `docs/verification.md:4336` | "改 A 炸 B"是常态 → 路由不许按"同名／同目录"想当然 |
| `installed_tools`／`hand_assist` 的红与其名称无关（夹具前置条件与接口漂移） | `docs/verification.md:4470` | 套件名 ≠ 覆盖面；新红必须按"引入点之前重跑"定类 |
| E0 oracle **比较器恒红**（缺陷在判据而非产品） | `docs/verification.md:4344` | 判据自身会坏；门禁要能区分"判据坏"与"行为漂移" |
| `selector_empty` **静默跳过**（不记 gate、不产 trace） | `docs/verification.md:4420`、`docs/event-pipeline-unification.md:199`（D1b） | 最危险的不是红，是"根本没有记录" → 计划必须逐文件打印命中，未命中不得静默 |
| `_enemy_phase` 尾部判定真实流程不可达却仍在表内；迁移日志折叠边界差点放过一条重复 | `docs/transition-pipeline.md:136-139`、`docs/verification.md:4528` | 双向比对＋"未命中即红"；放过边界必须写明理由 |
| `normal_play` 长流程尝试打转（2026-09-14 全量尝试，主动终止） | `docs/verification.md` 的 2026-09-14 全量尝试条目（`docs/event-pipeline-unification.md` §12 引作 `docs/verification.md:58`；该文件新条目插在顶部，行号会漂移，按标题检索） | 里程碑长流程不能进日常默认，否则门禁被噪声占领 |

### 5.2 控制 1：fail-closed（宁可多跑，绝不默认少跑）

- 索引未命中 → 走 §5.3 的目录闭包；闭包也未命中 → `all-dev`＋`all-dev-ui`；两级都逐条打印、进 `summary.route.unmapped`。
- `declared_none` 只能声明在指纹面之外（§2.2-5），且由 §3.4-v 同源的扫描守住；源码面里没有"不用跑"这种值。
- 仓库外路径 → 起引擎前拒绝，不猜。

### 5.3 控制 2：过近似（只放大不缩小，边有依据）

| 边 | 展开 | 依据 |
| --- | --- | --- |
| `spire-godot/core/**` | `all-dev`（全部规则套件 − `MILESTONE`） | `core/game.gd` 是所有规则的提交入口与状态机（`docs/transition-pipeline.md` §2.2） |
| `spire-godot/data/**` | `all-dev` | `data/*.gd` 是 `core` 的唯一注册表来源（`docs/project-map.md`、各 `*-dependency-spec.md`） |
| `spire-godot/ui/**` | `all-dev-ui` | `ui/main.gd` 承载全部抽屉与提交入口（`docs/ui-scene-refresh.md`） |
| `spire-godot/content/packs/**` | 内容消费者（`content`／`event_flow`／`events`／`encyclopedia`／`shop_release`／`installation_priority`／`curses`）＋ **内容门** | `docs/content-extension.md`、`docs/event-pipeline-unification.md` §0；`tools/check-content.ps1` |
| `spire-godot/tests/**` | 归属套件（索引派生）；无法归属者 `all-dev`＋`all-dev-ui` | `tests/runner_cases.gd:46-47` 的既有归属算法 |
| `spire-godot/assets/**` | 规则 `localization` ＋ 界面 `localization`／`baseline`／`hero_art`／`equipment_art`（按子目录收窄） | `docs/localization.md`、`spire-godot/assets/art/ART-NOTES.md` |
| `spire-godot/tools/**` | 规则 `runner`（`note`：改 `check.ps1` 另跑 `-VerifyRunner`） | 本契约 §7-1 |
| `spire-godot/`（模块根 `project.godot`／`main.tscn`） | `all-dev`＋`all-dev-ui` | 工程与主场景是全部套件的宿主 |

**与索引的关系（必须写进实现）**：**命中索引 → 用索引（可选 `WIDEN` 声明放大）；未命中索引 → 用目录闭包兜住**。
即闭包是**盲区的兜底**，不是所有文件的默认——否则索引对 `core/**` 毫无作用（这就是"先按索引、再按声明的边放大"的含义；
本解释需人确认，见 §11-4）。索引命中的文件即使比闭包窄，也必须在计划里可见，且其窄度是 `WIDEN`／`DOMAINS` 的可审查决定。

### 5.4 控制 3：里程碑必须全量（索引的盲区就是它的存在理由）

- 全量命令（唯一入口，写进 §2.3 与 `.zcode/skills/repo-ops/SKILL.md`）：`& tools/check.ps1 -Suite all -UI -UISuite all -TimeoutSeconds 900`。
- **强制场景**：PR、打包（`tools/package*.ps1`／`check-package.ps1`）、发版（tag／Release）、版本推进、跨域大改。
- **本控制不可被索引替代**：索引只回答"静态谁碰了谁"；`home_persistence` 证明**跨套件组合效应不可从静态边推导**（§5.1），
  因此里程碑全量是检出该类的唯一手段。路由记录（`summary.route.mode=changed`）**不得**用于宣称里程碑／交付通过。
- 机械保证：`-Changed`／`-ChangedList` 与 `-Suite`／`-UISuite` 互斥（§2.3），路由模式**无法**顺带覆盖 `MILESTONE` 套件。
- 里程碑全量必须显式报告**每条**盲区闭包文件与 `INDEX_DEFECTS` 状态（"这次全量覆盖了哪些索引看不见的路径"）。

### 5.5 控制 4：索引缺陷学习环

- **触发**：任何一次全量（`-Suite all -UI -UISuite all`，或任何比路由结果更宽的运行）发现"路由本会漏掉"的红。
- **登记位置**：① `tests/check_index_edges.gd` 的 `INDEX_DEFECTS`（`date`／`path`／`missed_suites`／`found_by`／`log`／`added`：补的 `DOMAINS`／`WIDEN`／派生规则修正）；② `docs/verification.md` 新条目（域、发现命令、日志路径、补的规则）。
- **口径（可判）**：**下次全量若再现同类漏检，即视为本片未收口**；`INDEX_DEFECTS` 里 `added` 缺项或 §3.4-vii 红者为**未闭合**，必须在里程碑报告里逐条列出。
- **机器守护**：§3.4-vii（补的边不得回退）＋ 计划宿主对命中已知缺陷路径的变更打印 `ROUTE KNOWN GAP: <path>`（只提示，不自动放宽或收紧）。
- **派生规则本身的缺陷**（信号抽取漏掉一类写法）属同一环：修正 `CheckIndex.derive()` 后必须 `-Write` 重新冻结并附"为什么旧规则看不见它"的一句说明。

### 5.6 量化（预期；由 validator 实测后填入验证记录）

| 场景 | 今天（实测） | 本片后（预期） | 归属 |
| --- | --- | --- | --- |
| 同一条宽集命令（44 类，含 `installed_tools` 脚本错误） | 135s（截断）＋265s（补跑）＝400s，两个进程，`unrun` 16–24 类（2026-09-17 被取代：实测是 **37 类**、539.6s／37-37 套件；另一次 729s 未复现；见 `docs/verification.md` 2026-09-17） | **一次进程 ≈400s − 进程启动开销**，`unrun=[]`（2026-09-17 被取代：实测 539.6s／729s，未复现 ≈400s；收益是 `unrun=[]` 而非墙钟） | 隔离收益（省下的是补跑编排与不确定性，**不是覆盖**） |
| 两个含脚本错误的套件（`installed_tools`＋`hand_assist`） | 每命中一个就截断一次，最坏 3 个进程 | 1 个进程，两处各打 `SUITE RUNTIME` | 隔离收益 |
| 典型路由子集（例：只改 `core/save_store.gd`） | 需人工猜 `-Suite persistence -Impact`（展开 ≈25 类，几分钟） | 计划 8–10s＋规则 `encyclopedia,persistence`＋界面 `home,home_persistence,persistence`：**约 30–90s** | 路由收益 |
| 只改 `ui/**`（命中派生边的文件） | 人工猜 `-UIOnly -UISuite …` | 计划 8–10s＋界面子集：**约 20–60s**，**规则套件 0 个** | 路由收益 |
| 只改 `content/packs/**` | 易漏内容门 | 内容门 4s＋内容消费者套件，**界面 0 个** | 路由收益 |
| 盲区文件／跨域大改 | 无此路径 | `core/**` → `all-dev` 规则 ≈400s（＋界面 106s） | fail-closed 的代价，可预期 |
| 索引自检（`runner` 套件内） | — | ＋≤10s（实测上限） | 索引成本 |
| 里程碑全量 | `-Suite all -UI -UISuite all` | **不变** | 控制 3 |

**验收口径之一：不靠减少覆盖换速度。** 两类收益**分开报**（隔离 delta／路由 delta／索引维护成本三段墙钟）；证据要求：
① 同一命令改动前后，**同一批套件的断言数逐套件相等**、`unrun` 由 16–24 降为 0；
② 路由结果 ⊇ 冻结索引里该文件的边（无隐藏收窄），且盲区文件走闭包（不静默）；
③ 不删任何断言、不改任何套件内部、不动红集口径、不改测试写法。

## 6. Gherkin（Given/When/Then；落点已定）

**G1 故意注入脚本错误的套件不中断整轮**
Given 规则宿主以 `--suite=<A>,<B>` 选中两个套件、第一个套件执行中抛脚本错误（真实注入，非桩）；
When 不带 `-KeepGoing` 跑完（`-Suite runner -VerifyRunner` 的 `negative-isolation-runtime`／`negative-isolation-load` 探针）；
Then 第一套件打印 `SUITE RESULT: A FAIL`＋`SUITE RUNTIME: A <n≥1>`（加载失败路径打印 `SUITE LOAD FAILED`）；
`B` 出现在 `SUITE START`／`SUITE RESULT: B PASS`；`summary.rules.unrun == []`；`rules.retry == [A]`；退出码 1。
（UI 侧同一场景由 `negative-isolation-ui` 探针承载，条件与回退见 §4.2。）

**G2 断言失败不再需要 `-KeepGoing`**
Given 同上但注入纯断言失败（既有 `--probe-suite-failure`）；When 不带 `-KeepGoing` 跑；
Then `B` 仍 PASS、`unrun` 为空、`retry == [A]`、退出码 1。

**G3 索引路由的正例与反例**（`tests/runner_cases.gd` 具名 check，纯函数读冻结索引）
Given 下列清单，When `Selection.route(files)`，Then 逐条（正例 ⊇，反例 ∩=∅，全部按实测派生结果钉）：
`["spire-godot/core/save_store.gd"]` → `persistence ∈ rules`、`{home,home_persistence,persistence} ⊆ ui`、`signals` 含 `preload`；
`["spire-godot/ui/main.gd"]` → `rules == []`、`ui ≠ []`；
`["spire-godot/content/packs/abandoned_storeroom.json"]` → `content ∈ rules`、`ui == []`、`content ∈ gates`；
`["spire-godot/tests/runner_cases.gd"]` → `runner ∈ rules`（归属套件）；
`["spire-godot/core/snapshot.gd"]` → `persistence ∈ rules`（结论不变；2026-09-17 复核：冻结索引 `suite_files` 里 `rule:persistence`／`ui:persistence` 均含它（`domain` 信号），它已是直接边、不在 `blind`）；
`["spire-godot/core/tool_rules.gd"]`（`BLIND_BY_DESIGN`）→ 走 `core/**` 闭包，取到 `all-dev`，且 `default_files` 含它；
`["docs/check-routing.md"]` → `rules == [] && ui == []` 且 `status` 只能是 `plan`；
`["spire-godot/newdir/x.gd"]` → `unmapped` 含它且 `rules == all-dev`（fail-closed）。

**G4 索引双向自检 + 零漂移**（§3.4 的 i–viii 全部作为具名 check／`check-index.ps1` 退出码；
负例敏感性证明：临时改一处 `tests/*_cases.gd` 的 `preload` 目标或手改冻结物一行 → 零漂移检查必红，还原后绿）

**G5 `-ListOnly` 输出与最终执行集合一致**
Given 清单 `["spire-godot/tests/runner_cases.gd"]`；When 先 `-ChangedList <f> -ListOnly` 取计划，再 `-ChangedList <f>` 真跑；
Then `plan.rules == summary.rules.selected`、`plan.ui == summary.ui.selected`、`plan.index_digest == summary.route.index_digest`、退出码 0、`status=passed`。

## 7. Validator procedure（agent 可运行；本片无玩家可见行为，人的路径证明＝"像人一样跑门禁"）

1. **入口自检（机器判据，先在仓库内跑）**：`& tools/check.ps1 -Suite runner -VerifyRunner -TimeoutSeconds 900`
   → 全部 `CHECK negative-*`／`CHECK route-*` 行 PASS：`negative-isolation-runtime`／`negative-isolation-assertion`／
   `negative-isolation-load`／`route-ui-only`／`route-content`／`route-save`／`route-snapshot-domain`／`route-blind-closure`／
   `route-unmapped-fail-closed`／`route-scope-matches`。
2. **索引面**：`& tools/check-index.ps1`（零漂移、退出码 0）；再按 G4 做一次敏感性证明（改一行 → 红 → 还原 → 绿）。
3. **计划面（不算通过）**：`-Changed -ListOnly`（真实工作区）与 §6-G3 的 8 条 `-ChangedList … -ListOnly`
   → 逐条核对 `ROUTE ROW`／`ROUTE DEFAULT`／`ROUTE UNMAPPED`／`ROUTE WIDEN CANDIDATE`；`-Changed` 空集与仓库外路径各被拒绝一次。
4. **隔离的现场证明**：跑一条含 `installed_tools` 的宽集命令
   （例：`-Suite installed_tools,hand_assist,rewards,persistence,architecture,runner -Impact -TimeoutSeconds 900`）
   → ① `SUITE RUNTIME: installed_tools …`＋`SUITE RUNTIME: hand_assist …` 均出现；② 其后套件全部有 `SUITE RESULT`；③ `summary.rules.unrun == []`；④ 退出码 1，红集 ⊆ 已登记五项（`card_power` 5／`installed_tools` 1／`tower_progression` 10＋1／`hand_assist` 1／`home_persistence` 3）。
5. **覆盖未减少的证明**：同一命令在父提交（本片改动前）与本片 HEAD 各跑一次，逐套件比对断言数（同批套件必须相等）；
   分别记录三段墙钟（隔离／路由／索引）。**不同提交的结果不得拼接**（`docs/event-pipeline-unification.md` §11.1 第 4 条）。
6. **路由实跑**：`-Changed`（本片自身的变更集）→ 记录 `ROUTE ROW` 逐行、`summary.route` 全字段、墙钟与 `unrun`；再 `-ChangedList` 一条 ui-only 清单实跑到 `UI PASS`（证明规则／界面两相分离仍成立）。
7. **续跑语义未坏**：取步骤 4 的运行目录 `-RerunFailed build/checks/<id> -TimeoutSeconds 900` → 只选失败／未完成套件、`RERUN:` 行出现、结果不得被当作全量通过。
8. **不回归既有命令**：`-Suite architecture,runner -TimeoutSeconds 900`、`-UIOnly -UISuite home,persistence -ListOnly`、
   `-Suite persistence -Impact -ListOnly` 三条旧命令各跑一次，逐字比对 `RULE SCOPE`／`UI SCOPE`／`PLAN ONLY`／
   `summary.json` 键集与父提交输出（新增键只允许 §2.3 的 `route`、§2.4 的 `runtime`）。
9. **文档与登记**：`git diff --stat -- spire-godot/core spire-godot/ui spire-godot/data spire-godot/content` 必须为空；
   新条目写 `docs/verification.md`（范围、提交、命令、退出码、断言数、红集、`unrun`、三段墙钟、盲区闭包清单、`INDEX_DEFECTS` 状态）；
   四态计数分开记（passed／failed／unverified／skipped）。
10. **归属判定**：失败先分"实现代码／测试脚本／环境／程序本身"；不确定就保持未分类上报，不自动改产品代码或判据。

## 8. DoD（命令、Gherkin、判据；缺一即未完成）

1. G1–G5 全部通过（探针＋具名 check，§6／§7-1）。
2. `tools/check-index.ps1` 零漂移退出码 0；§3.4 的 i–viii 全绿；`runner` 套件仍全绿（既有 `ownership` 不回归）。
3. 索引落地形态达标：冻结物在 `spire-godot/tests/check_index.json`（`tests/` 内、指纹面内）；生成器 `-Write` 可复现；
   `DOMAINS` 覆盖全部可解析盲区、`BLIND_BY_DESIGN` 逐条有理由且数量写进验证记录；`INDEX_DEFECTS` 为空或全部闭合。
4. 隔离：§7-4 的四条观察成立；`-KeepGoing` 仍被接受；加载失败不再 `quit` 整轮。
5. 兼容：§2.4 表逐项复核无变化（旧命令、token、`summary` 既有键、退出码、`-RerunFailed`）。
6. 覆盖未减少：§7-5 的逐套件断言数比对与三段墙钟写进验证记录；`runner` 索引自检增量 ≤10s（实测值）。
7. 文档：`.zcode/skills/repo-ops/SKILL.md` 更新命令面与里程碑条款；§4.3 的五处旧口径加 superseded 指针
   （只加指针，不改写历史文本）；`docs/verification.md` 新条目。
8. 边界：`git diff` 不含 `core/`／`ui/`／`data/`／`content/`／oracle／基线的任何改动；**不改任何测试断言与测试写法**；
   未跑全量 `-Suite all`（非本片范围）；未打包／发版／推送。
9. **不算完成的情形**：`unrun` 非空（探针或现场证明）；任一 Gherkin 缺；探针日志缺失；
   索引出现目标不存在／套件孤岛／未覆盖的用例文件；盲区文件未登记就静默走闭包（必须打印）；
   路由结果窄于冻结索引的边（隐藏收窄）；用减少断言、删套件、放宽红集换绿灯；未报三段墙钟。

## 9. 依赖约束（dependency spec，本片以本节为规范文件）

- 允许的边：`check_index_edges.gd`（数据）→ `check_index.gd`；`check_index.json` → `check_index.gd`；
  `check_index.gd` → `route_plan.gd`／`runner_cases.gd`／`tools/build_check_index.gd`；
  `test_game.gd`／`ui_smoke.gd` 不改依赖；`check.ps1` → `route_plan.gd`＋既有宿主脚本。
- 禁止：`core/`／`ui/`／`data/` 引用 `tests/`；`check_index.gd` 预载宿主脚本；`route_plan.gd` 引用 `core/`；
  第二份"文件→套件"映射；手改 `check_index.json`（只能由生成器写）。
- 文件规模：`check_index.gd` ≤ 300 行（2026-09-17 已裁定接受超限，见本文件后文）；`check_index_edges.gd` ≤ 400 行（约 53 条 `DOMAINS`＋`WIDEN`＋`EXCLUDE`＋缺陷登记）；
  `route_plan.gd` ≤ 120 行；`suite_selection.gd` 只加纯函数（≤80 行），既有 API 行为不变。
- 依赖规范文件：本 §9 即本片的依赖约束规范；若协调者按仓习惯要求单独成文件，规划者在本契约批准后补
  `docs/check-routing-dependency-spec.md`（内容＝本节）。

## 10. 假设与最可能爆的点

1. **`all-dev` 扣除 `MILESTONE`（`normal_play`／`baseline`）**：这是"只放大不缩小"的唯一例外，理由是 registry 自带调度标签与 `normal_play` 的打转历史；若人不接受，改为成员含 `normal_play`（代价：每次盲区变更都跑长流程）。
2. **UI 侧脚本错误是否返回控制权**：`await suite.run(self)` 内抛错可能让协程被丢弃→模块挂起（超时）。缓解：Gherkin ① 的 UI 探针先做；失败则按 §4.2 回退并上报偏差（规则侧隔离不受影响）。
3. **引擎错误归属窗口**：延迟调用／`await` 的错误可能落进下一个套件的窗口，`SUITE RUNTIME` 归因会偏。缓解：按窗口计数（与今天一致）＋写明口径；若证明偏移，改为"窗口内 ≥1 即标注、不宣称精确条数"。
4. **加载失败隔离会引入 `ERROR:` 行**（`load()` 失败由引擎打印）：`Invoke-SpireCheck` 的 `ERROR:` 正则会让该轮照旧判红（本就该红）；探针用 `Invoke-CheckEngine` 直连，不受影响；不要为消掉这行改写宿主。
5. **派生的稳定性**：`domain`／`symbol` 抽取依赖测试写法（消息前缀、门面调用）。缓解：抽取规则写进 `check_index.gd` 顶部注释与契约；**任何抽取规则变化都要 `-Write` 重新冻结**并附"旧规则看不见什么"；零漂移检查保证冻结物与当前源码一致。
6. **`tests/` 文件改名／移动**会改索引（expected）：`-Write` 同批提交；否则 `runner` 红（有意）。
7. **`-Changed` 在提交后为空集**：默认 base＝`HEAD`；工作流是"先跑门禁再提交"，提交后用 `-Since <base>`；拒绝时给出这句话。
8. **`runner` 默认门禁与索引耦合**：索引坏了默认门禁立刻红（有意的 fail-closed），代价是索引必须与源码同批维护。
9. **内容门作为新阶段**：`content` gate 的退出码与日志单独记（不并入规则／界面结论）；`check-content.ps1` 自身失败不得被解释成"路由坏了"。
10. **oracle 不由路由自动选择**（非目标）：计划只打印 `ROUTE NOTE`（如 `core/game.gd`／`core/room_events.gd` → "另跑事件／迁移 oracle"），不自动执行、不改 oracle 与基线。
11. **盲区闭包的成本**：盲区文件（实测 53 个）若未解析就改，会退化成全量规则套件（≈400s）。缓解：`DOMAINS` 优先解析；`ROUTE DEFAULT` 逐条可见；学习环登记。

## 11. 待协调者与人确认（`needs-human-review` 的理由）

1. **门禁语义本身改变**：默认"首个失败即停"变成"跑完全部已选套件"、`-KeepGoing` 变兼容无操作；虽不改红集与退出码，但它改变所有后续验证记录与操作习惯（§4.3）。
2. **审的是索引的"窄度"决定**：派生边由机器算，但**盲区的域解析与 `WIDEN` 放大是人的判断**（§3.5，约 53 条＋若干 `WIDEN`）。机器只能证明完备性、存在性与零漂移，不能证明"这条窄得安全"。请人看 `tests/check_index_edges.gd` 与冻结物 `suite_files` 主表的 extract。
3. **`all-dev` 扣除 `MILESTONE` 套件**（§10-1）需要人裁。
4. **闭包与索引的关系解释**（§5.3）：命中的文件用索引（可比闭包窄），未命中的才用目录闭包。若人要求"`core/**` 一律全量规则套件、索引只作提示"，则本片退化为"仅隔离 + 计划视图"，路由收益消失——请在此确认取舍。
5. **`-Changed` 的结果可否用于交付**：本契约定为"开发期快速反馈，里程碑／交付必须全量"（§5.4）；若人要另设门槛（例如"改动落在 `core/` 时交付前必须全量"），请确认。
6. **索引冻结物的位置与体积**：`spire-godot/tests/check_index.json`（≈11 KB，指纹面内）；若人希望换成 `tests/check_index.gd` 常量表（避免 JSON 解析、便于逐行 diff），请指明。
7. **旧文档指针**：§4.3 只加 superseded 指针、不改写历史文本；`docs/changelog.md` 保持历史不动。若人要求更多登记，请指明范围。

## 协调者记录（2026-09-17）：§11 七条裁定

人已批"索引回来就开工"，以下裁定随施工生效（可随时叫停）：

1. **§11-1 门禁语义改变：接受**。默认改为"跑完全部已选套件"、`-KeepGoing` 成为兼容无操作；红集与退出码语义不变。**它取代此前 A29 的"逐分类补跑"口径**（该做法从此为历史）。
2. **§11-2 盲区与 `WIDEN` 属人的判断：接受，但加可见性要求**——每次路由运行必须**打印它做出的默认决定**：经 `DOMAINS` 解析的盲区文件、落到目录闭包的文件、以及 `WIDEN` 候选。审查面从此不只靠读文件，而是每次运行可核。
3. **§11-3 `all-dev` 扣除 `MILESTONE`：接受**，条件是该扣除清单**显式且每次计划里打印**，且里程碑命令（`-Suite all -UI -UISuite all`）必须包含它们。
4. **§11-4 索引与闭包的关系：保留索引路由**（命中用索引、未命中用目录闭包），不退化为"仅隔离＋计划视图"；**并追加两条过近似**：①`core/**` 的变更在索引结果上**固定追加 `architecture,persistence,runner`**（跨切面／元数据套件）；②盲区文件一律走目录闭包。理由：本仓历史证明 core 改动的外溢不可预测（`has_relic` 改内容炸存档校验、`_enemy_phase` 不可达路径、折叠边界），这三条是廉价的对冲。
5. **§11-5 `-Changed` 的用途：接受契约口径**——开发期快速反馈；**PR／打包／发版前必须全量**（里程碑规则不变）。
6. **§11-6 冻结物位置：接受** `spire-godot/tests/check_index.json`；但要求**重新生成时键序稳定**（否则零漂移检查不可读）。
7. **§11-7 旧文档指针：接受**——只加 superseded 指针，不改写历史文本。

## 协调者记录（2026-09-17）：落地复核与偏差裁定

- **计划裁定：接受**（两段均已落地并提交；协调者独立复核了零漂移门、runner 自检、路由计划打印、干净工作区的显式报错）。
- **偏差裁定**：①`check_index.gd` 551 行（超 §9 目标）**接受**——理由成立（抽取规则与四接口同文件），下片若拆文件须先立批；②冻结物 71 KB **接受**，键序稳定已证；③`tests/**` 走闭包 **接受**（属裁定⑤的后果）；④三个加性数据键与 `gate_results` **接受**（加性、带理由）。
- **反发现裁定**：隔离**不省墙钟**（729s vs 539.6s，长驻进程内 `prison`／`persistence` 开销所致），收益是 `unrun=[]`＋免补跑编排＋具名标注。**"隔离拿回五分钟"一说作废**，不得再以时间宣传该段收益。**待办**：是否改为"每 N 个套件重启进程"的分批执行——属新片，需先量出 N 的拐点，且**不得改变隔离语义与红集**。
- **红集口径扩展**：加入 `interface`（28 张角色二卡缺立绘，既有内容缺口），自此为六项集。
