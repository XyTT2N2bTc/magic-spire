# 规划者契约：present(dirty) 第三刀（relics）

状态：可交协调者派实现者；**无新模块、无新允许边**，不标 `needs-human-review`。通宵仍授权落地既有节键／`present(dirty)`。节键表 `relics` 行已写字段集；给 `_relic_row` 建键并早退＝落地该行，不是新模块、不是新 CSS（header 先例：「既有节键」＝规格已写字段，不是代码里已有 `_presentation_key`）。HEAD 起步 `e5eceda`。域：`ui/main.gd::present` 加 `["relics"]` 局部；键只在 `ui/main.gd` 的 `_relic_row` 旁（条带重建入口，无独立 shell 文件）。保留 `["header"]`／`["body_bar"]` 局部。不拆 `commit`、不接 `present_rejection`、不改 `_submit`。不铺其余节。不新写 CSS。本刀不写 `docs/spec`。

checkpoint(planner): specify present relics third slice

## 已有入口（扩展 present，不建第二套刷新管线）

- `present`／`PRESENT_SECTIONS`／`PRESENT_ADJACENCY`／`_present_needs_full_render` 已落地：仅 `["header"]`／`["body_bar"]` 局部；`["*"]`／缺项／未知／其它已声明名 → 全量 `render(当前 view)`，禁止再 `get_view`。局部固定序：`DragTargets.clear(self,false)` → `_hide_term` → View 同步 → 节 → `layout.end_frame()` → `keyboard_input.refresh_hints`（`call_deferred`）→ `_localize_controls`。局部不得 `begin_frame`，不得清空 `layout.used`。
- 静态搜节键／早退：全仓 `_presentation_key` 只在 `body_sidebar.gd`（第一刀）与 `header.gd`（第二刀）。无更小的既有键可先扩 `present`。下一行即节键表 `relics`（`_relic_row`）。
- `_relic_row()` 每次 `ScrollContainer.new()` 名 `RelicStrip` 再 `_place`；`view.relics` 空则直接 return。无键、无早退。全量 `_header()` 顺手调用它；`begin_frame` 会释放旧条带。局部若直接再调且未拆叠，会叠 `RelicStrip`。
- 节键表 `relics` 行（键内容真源）：`relics`(id/name/detail/counter/current/rarity)、locale。`version` 不进键。

## 切分、接口和依赖

- 只扩展既有 M3 `present`：`["relics"]` 局部；`["header"]`／`["body_bar"]` 仍局部；未知／`["*"]`／缺项／其余已声明名仍全量 `render(view)`（非空当前 View，禁止再 `get_view`）。`dirty.size()!=1` 仍全量。局部不得 `begin_frame`。
- `["relics"]` 局部：调 `_relic_row()`。不得调 `_header`、不得 `header.configure`、不得 `layout.body_sidebar`、不得 instantiate `header.tscn`。layout 空／View 空 → 全量。无 `RelicStrip` 且 relics 非空 → 本函数创建条带（仍局部，不因此全量）。
- 键只在 `main.gd`、紧挨 `_relic_row`（可名 `_relic_presentation_key`）；不得新 UI 文件／新 RelicStrip 脚本；不得把键放到 `relic_icon.gd`；不得在第二处复制遗物键。键＝纯数据副本（Array／Dictionary／基础类型），不存旧 View／候选／装备图／节点引用。
- 键字段必须覆盖 `_relic_row` **实际读取的遗物显示字段**，且 ⊆ 节键表 `relics` 行：每件 `id`／`name`／`detail`／`counter`（含其 `text`／`detail`）／`current`／`rarity`、locale。locale：`_relic_row` 不调 `display`，但 present／render 固定序末尾 `_localize_controls`；locale 进键。`rarity_name` 由 `rarity` 决定，键 `rarity` 即可。`icon`（豆包／百变怪）与 `name`／`detail`／`current` 同批变，不另开字段集。`version` 禁止。`TargetQueries.find` 的遗物放电／切换事实不进键（表未写候选；进键＝新建字段集 → `needs-human-review` 停工）。`_relic_row` 新读显示字段必须同批进键，且仍 ⊆ 该行。
- 早退当且仅当树上已有活 `RelicStrip` **且** 键命中：保留条带与已有 `RelicShortcut_*` 实例。禁止只凭缓存键、条带已被 `begin_frame` 释放仍早退（全量会丢条带）。键未命中：就地更新该节；先释放已有 `RelicStrip` 再按现行逻辑建模（relics 空则不建）。之后树内 `RelicStrip` 件数＝0（空）或 1（非空）；每个 `RelicShortcut_<id>` 件数＝1。不得把叠条带／叠快捷方式当跳过。
- 允许实现面：`spire-godot/ui/main.gd` 的 `present` 路由（含 `_present_needs_full_render`、`PRESENT_ADJACENCY`：`present` 增加 `_relic_row`；`_relic_row` 读键函数）、`_relic_row` 键＋早退＋不叠条带；`spire-godot/tests/display_ui_cases.gd` 单个具名场景／`run` 注册，并改 `present_routes_header_or_full` 原⑥步：`present(["relics"])` 现为局部，改测仍全量的已声明名（`["hand"]`）。不得改 `_submit`／`commit`／`present_rejection`、不得改 `header.gd`／`body_sidebar._presentation_key` 字段集、不得改 `relic_icon.gd`／`header.tscn`／`game_layout.gd`／core／data。测试可对 `get_view` 做计数包装；生产源码不带计数器。
- 允许方向：仍 M3 内部（`present`→`_relic_row`）与既有 M3→M5／M3→M1.refresh_hints；测试 → `main.present`／`render`。**不新增**模块、运行时依赖、存档／schema、`present` 文件、`main`→core 新边、UI 文件。若实现仍要新模块／新 UI 文件／新允许边／把候选事实写进遗物键 → `needs-human-review` 并停下。
- `main.gd` 已超行数线；本刀只加薄路由与 `_relic_row` 早退，**不**为凑行数拆新模块。Godot 无 Size and ESM。`present(dirty: Array=["*"], …)` 保持未类型化 Array。

## Gherkin：`present_routes_relics_or_full`（一个可观察行为）

Given `tests/display_ui_cases.gd`，`ui.restart(42)` 后 `render(ui.view)`（战斗页，默认遗物使 `RelicStrip` 已建）。测试侧 `GetViewCountingGame`（或等价包装，生产无计数器）接到 `ui.game` 后再 `render(ui.view)` 一次，记下 `get_view` 基线、`GameHeader` 实例、`RelicStrip` 实例与件数、一枚 `RelicShortcut_*` 实例、`ui.body_buttons.wrist`（若有）、快照／`state.rng`。不调 `_submit`。
When 依次：① `present(["relics"])` 空 snapshot、View／locale 未改，再立刻第二次 `present(["relics"])`；② `present(["*"])`；③ `present(["not_a_section"])`；④ 只改 `ui.view` 上一处键内显示字段（如首件 `counter` 写入带 `text` 的字典，不 `dispatch`）再 `present(["relics"])`；⑤ `present(["header"])`；⑥ `present(["body_bar"])`；⑦ `present(["hand"])`（已声明、本刀非局部）；⑧ `present(["relics"], snapshot)` 传入当前 View 的非空副本。每步 `await t.frames`，每步记下该步之前的 `GameHeader`／`RelicStrip` 实例。
Then ① `RelicStrip` 实例保留、树内恰 1 个 `RelicStrip`；同一 `RelicShortcut_*` 实例保留、同名件数＝1；`GameHeader` 实例保留；wrist／hero／body／敌人仍有效；`get_view`＝基线。②与③ 各相对该步之前的 `GameHeader` 被替换（全量走了 `begin_frame`），`get_view` 仍＝基线。④ `GameHeader` 等于③之后的那个（不再全量）；`RelicStrip` 已换；`RelicCounter`（或所改字段对应可见控件）文本与改后 View 一致；`RelicStrip` 仍恰 1。⑤与⑥ `RelicStrip` 等于④之后的那个（`header`／`body_bar` 路由仍局部）。⑦ `GameHeader` 被替换（其余已声明名仍全量）。⑧ `get_view` 仍＝基线，`ui.view` 即传入 snapshot。全程 `export_snapshot()`／随机游标不变。不得用生产计数器；不得把 `render()` 空 snapshot 的 `get_view` 算进 present 义务。既有 `present_routes_body_bar_or_full`／`present_routes_header_or_full`／`sidebar_refresh` 不得红。本场景不是契约场景 3 全表。

## 验收流程

UI 验收 **none**：本刀不改 `_submit`，玩家路径仍整树 `render`；画面刷新范围不变。不派验收者。

## 完成定义及档 2（尚未执行）

- 实现者交 `present` 的 `relics` 局部路由、`_relic_row` 键＋早退＋不叠条带、`PRESENT_ADJACENCY` 与源码同批、上述场景及 header 场景⑥步改名；独立新会话审查者只核对本域源码／测试与本契约；清洁者核对：无第二套刷新管线、无新 UI 文件、无 `_submit` 改接、遗物键只在 `_relic_row` 旁、`header`／`body_bar` 键位置不变、邻接表源一致、依赖面 ⊆ 允许面。本刀不写 `docs/spec`。
- 实现者在 `spire-godot/` 运行 `& tools/check.ps1 -UIOnly -UISuite display -TimeoutSeconds 900`。通过＝退出码 0、`SUITE RESULT: display PASS`、完成标记、`summary.json` 的 `status=passed` 且指纹未变。未运行、`source_changed`、场景未注册进 `display_ui_cases.run`、或 `present` 空 snapshot 仍 `get_view`＝未完成。既有 `present_routes_body_bar_or_full`／`present_routes_header_or_full`／`sidebar_refresh` 不得变红。不改 `body_sidebar.gd`／`header.gd` 则不借旧绿宣称本域通过，也不必扩跑。
- 档 2（选定加固者，独立实现／清洁后）。栈档 2：规则套件＋内容包。内容包不适用（未改 packs）。规则 headless 无法观察节点实例／条带件数：本刀敏感性在 display 窗口套件上跑，命令同上。变异须红：①`present(["not_a_section"])` 或 `["*"]` 不走全量（`GameHeader` 实例保留）；②`present(["relics"])` 键命中仍重建该节（`RelicStrip` 被换，或 `RelicShortcut_*` 实例在未改键时被换）；③再 `_relic_row` 叠条带（`RelicStrip` 件数＞1，或同名 `RelicShortcut_*` 件数＞1）；④生产源码出现重建／`get_view` 计数器。原版绿；变异复原后重跑本域。不能靠静态搜索替代①②③的行为敏感性。缺工具或失败＝未通过，不算不适用。
- 无打包、发布、push。

## 非目标

其余已声明节一次落地；`commit` 拆分；`present_rejection`；把 `_submit` 改接到 `present`；新 CSS／样式引擎；T4／T5；`card_facts`；`keyword_ids`；窗口输入队列；恢复 `ActionIndex`；改 `header.tscn`／`game_layout.gd`／`relic_icon.gd`；改 `header`／`body_sidebar` 键字段集；把遗物候选事实写进键；本刀实施 phase／overload／`card_chain` 全量兜底清单。

## 风险假设

`layout.begin_frame` 仍释放 `GameHeader` 与 `RelicStrip`，全量 vs 局部仍可用二者实例区分。局部路径仍不得 `begin_frame`、不得清空 `layout.used`。全量 `_header()` 仍调 `_relic_row`：早退必须要求条带仍在树上，否则 `begin_frame` 后键命中会丢遗物条。键未覆盖已读显示字段时，早退会留下过期图标／角标／悬停文案。右键放电／切换闭包绑在建模时的 `choice`；本刀不接 `_submit`，玩家路径仍整树 `render`。若实现要新 UI 文件、新允许边、或把 `display_facts` 写进遗物键，停工交回，不新开 `present` 文件迁就。
