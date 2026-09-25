# 规划者契约：present(dirty) 第四刀（hand）

状态：可交协调者派实现者；**无新模块、无新允许边**，不标 `needs-human-review`。通宵仍授权落地既有节键／`present(dirty)`。节键表 `hand` 行已写字段集；给 `_hand` 建键并早退＝落地该行，不是新模块、不是新 CSS（relics／header 先例：「既有节键」＝规格已写字段，不是代码里已有 `_presentation_key`）。HEAD 起步 `972427b`。域：`ui/main.gd::present` 加 `["hand"]` 局部；键只在 `main.gd` 的 `_hand` 旁。保留 `header`／`body_bar`／`relics` 局部。不拆 `commit`、不接 `present_rejection`、不改 `_submit`。不铺其余节。不新写 CSS。本刀不写 `docs/spec`。

checkpoint(planner): specify present hand fourth slice

## 已有入口（扩展 present，不建第二套刷新管线）

- `present`／`PRESENT_SECTIONS`／`PRESENT_ADJACENCY`／`_present_needs_full_render` 已落地：`["header"]`／`["body_bar"]`／`["relics"]` 局部；`["*"]`／缺项／未知／其它已声明名 → 全量 `render(当前 view)`，禁止再 `get_view`。局部固定序：`DragTargets.clear(self,false)` → `_hide_term` → View 同步 → 节 → `layout.end_frame()` → `keyboard_input.refresh_hints`（`call_deferred`）→ `_localize_controls`。局部不得 `begin_frame`，不得清空 `layout.used`。
- 静态搜节键／早退：全仓 `_presentation_key` 只在 `body_sidebar.gd`（第一刀）与 `header.gd`（第二刀）；遗物键在 `main.gd::_relic_presentation_key`（第三刀）。无更小的既有键可先扩 `present`。下一行即节键表 `hand`（`_hand`）。
- `_hand()` 经 `_card`／`_refresh_card_face` 每次 `CardFace.new()` 写入 `card_buttons[uid]`，全量 `render` 开头 `card_buttons.clear()` 故不叠；**无键、无早退**。`view.pressure.overloaded` 时走 `_climax_narration()` 而非手牌；`view.hand` 空时放 `手牌已用完` 标签。全量 `_battle_scene()` 顺手 `_hand()`；`begin_frame` 会释放未标 `used` 的控件。
- 节键表 `hand` 行（键内容真源）：`hand`(uid/type/draw_serial/draw_free/single_face/availability/face_*)、对应 `card_texts` 项、`card_instances`、`card_faces[uid]`、`selected_card`、`_selecting_hand()`、`card_motion.pending_draws`。`version` 不进键。

## 切分、接口和依赖

- 只扩展既有 M3 `present`：`["hand"]` 局部；`["header"]`／`["body_bar"]`／`["relics"]` 仍局部；未知／`["*"]`／缺项／其余已声明名仍全量 `render(view)`（非空当前 View，禁止再 `get_view`）。`dirty.size()!=1` 仍全量。局部不得 `begin_frame`。
- `["hand"]` 局部：只调 `_hand()`（或其就地早退／重建）。不得调 `_header`／`header.configure`／`_relic_row`／`_fixed_actions`／`_build_action_rail`／`layout.body_sidebar`／`begin_frame`。layout 空／View 空 → 全量。无活手牌按钮且 `view.hand` 非空 → 本函数创建按钮（仍局部，不因此全量）。
- 键只在 `main.gd`、紧挨 `_hand`（可名 `_hand_presentation_key`／保存 `_hand_key`）。不得新 UI 文件／新 CardFace 脚本；不得把键放到 `card_face.gd`／`card_motion.gd`；不得在第二处复制手牌键。键＝纯数据副本（Array／Dictionary／基础类型），不存旧 View／候选／装备图／节点引用。
- 键字段必须覆盖 `_hand` 及本节路径上 `_card`／`_refresh_card_face` **实际读取**的显示字段，且 ⊆ 节键表 `hand` 行：
  - 每张手牌（按 `view.hand` 顺序）：`uid`／`type`／`draw_serial`／`draw_free`／`single_face`／`availability`（含 free／bound 的 usable／dim／text）／`face_*`（经 `_refresh_card_face` 消费的 `face_names`／`face_effects`／`face_keywords`／`face_mana`／`face_costs`／`face_type_names`／`face_warnings`／`face_requirements`／`free_faces`／`rarity`／`rarity_name`／`type_name`／`cost`／`retained` 等，与 `_card` 合并 `card_texts[type]` 及 `card_instances[physical_uid]` 后的显示子集）。
  - 对应 `card_texts` 项与 `card_instances` 条目（上列合并所需字段）。
  - 当前手牌 uid 集合上的 `card_faces[uid]`。
  - `selected_card`。
  - `_selecting_hand()`；为真时另含 `_hand_choice` 所读的本地 `player_pick_data` 形状（`hand_selection`／`card_uid`／`free`／`target`／`slot`）——属 `_selecting_hand()` 语义，不是候选 `display_facts` 进键。
  - `card_motion.pending_draws`（排序后的 uid 列表；无 `card_motion` 时视为空）。
  - `view.hand.is_empty()`／手牌张数（空时 `手牌已用完` 与无按钮互斥）。
  - `view.pressure.overloaded`（`_hand` 早退分支读它；规格全量兜底亦含此项，本刀在 `_present_needs_full_render` 对该条件走全量，与局部手牌键并用）。
  - `version` 禁止。`TargetQueries` 的 `display_facts` 候选行不进键（表未写；进键＝新建字段集 → `needs-human-review` 停工）。`_hand` 新读显示字段必须同批进键，且仍 ⊆ 该行。
- 早退当且仅当键命中 **且** 对每个 `view.hand[i].uid`：`card_buttons` 有活实例、实例仍在树上、该 uid 按钮件数＝1；`card_buttons` 键集与当前手牌 uid 集一致；`view.hand` 空时无活 `CardFace` 手牌按钮且 `ClimaxNarration`／`手牌已用完` 状态与键一致。禁止只凭 `_hand_key`、按钮已被 `begin_frame` 释放仍早退。键未命中：释放本节手牌按钮（及本节专属空牌／高潮面板），再按现行逻辑建模；不得叠按钮。键命中且仅 `selected_card`／`card_faces`／`pending_draws` 等键内字段变：允许就地 `_refresh_card_face`／显隐／布局，或等价重建，但同一 uid 须保留实例（与场景 5 方向一致；本刀 Gherkin 只断言键命中双调保留实例）。
- 允许实现面：`spire-godot/ui/main.gd` 的 `present` 路由（含 `_present_needs_full_render` 对 `pressure.overloaded` 的全量兜底、`PRESENT_ADJACENCY`：`present` 增 `_hand`；`_hand` 读键函数）、`_hand` 键＋早退＋不叠按钮；`spire-godot/tests/display_ui_cases.gd` 单个具名场景／`run` 注册，并改 `present_routes_header_or_full` 与 `present_routes_relics_or_full` 原「仍全量的已声明名」步：`present(["hand"])` 本刀后变局部，改测 `present(["actions"])`。不得改 `_submit`／`commit`／`present_rejection`、不得改 `header.gd`／`body_sidebar._presentation_key`／`_relic_presentation_key` 字段集、不得改 `card_face.gd`／`card_motion.gd`／`header.tscn`／`game_layout.gd`／core／data。测试可对 `get_view` 做计数包装；生产源码不带计数器。
- 允许方向：仍 M3 内部（`present`→`_hand`）与既有 M3→M1.refresh_hints；测试 → `main.present`／`render`。**不新增**模块、运行时依赖、存档／schema、`present` 文件、`main`→core 新边、UI 文件。若实现仍要新模块／新 UI 文件／新允许边／把 `display_facts` 写进手牌键 → `needs-human-review` 并停下。
- `main.gd` 已超行数线；本刀只加薄路由与 `_hand` 早退，**不**为凑行数拆新模块。Godot 无 Size and ESM。`present(dirty: Array=["*"], …)` 保持未类型化 Array。

## Gherkin：`present_routes_hand_or_full`（一个可观察行为）

Given `tests/display_ui_cases.gd`，`ui.restart(42)` 后 `render(ui.view)`（战斗页，`view.hand` 非空，`GameHeader` 与手牌 `card_buttons` 已建）。取 `first_uid=view.hand[0].uid`。测试侧 `GetViewCountingGame`（或等价包装，生产无计数器）接到 `ui.game` 后再 `render(ui.view)` 一次，记下 `get_view` 基线、`GameHeader` 实例、`RelicStrip` 实例（若有）、`card_buttons[first_uid]` 实例、`ui.body_buttons.wrist`（若有）、快照／`state.rng`。不调 `_submit`。
When 依次：① `present(["hand"])` 空 snapshot、View／locale 未改，再立刻第二次 `present(["hand"])`；② `present(["*"])`；③ `present(["not_a_section"])`；④ 只改 `ui.view` 上一处键内显示字段（如 `view.hand[0].name` 或合并后的 `face_effects` 子字段，不 `dispatch`）再 `present(["hand"])`；⑤ `present(["header"])`；⑥ `present(["body_bar"])`；⑦ `present(["relics"])`；⑧ `present(["actions"])`（已声明、本刀非局部）；⑨ `present(["hand"], snapshot)` 传入当前 View 的非空副本。每步 `await t.frames`，每步记下该步之前的 `GameHeader`／`card_buttons[first_uid]` 实例。
Then ① `card_buttons[first_uid]` 实例保留、该 uid 按钮件数＝1、手牌 `card_buttons` 键数＝`view.hand.size()`；`GameHeader` 实例保留；`RelicStrip`（若存在）保留；wrist／hero／body／敌人仍有效；`get_view`＝基线。②与③ 各相对该步之前的 `GameHeader` 被替换（全量走了 `begin_frame`），`get_view` 仍＝基线。④ `GameHeader` 等于③之后的那个；`card_buttons[first_uid]` 已换或等价重建；`CardTitle`（或所改字段对应可见控件）文本与改后 View 一致；手牌 uid 件数仍各＝1。⑤⑥⑦ `GameHeader` 等于④之后的那个且 `card_buttons[first_uid]` 不被⑤⑥⑦换掉（`header`／`body_bar`／`relics` 仍局部）。⑧ `GameHeader` 被替换（其余已声明名仍全量）。⑨ `get_view` 仍＝基线，`ui.view` 即传入 snapshot。全程 `export_snapshot()`／随机游标不变。不得用生产计数器；不得把 `render()` 空 snapshot 的 `get_view` 算进 present 义务。既有 `present_routes_body_bar_or_full`／`present_routes_header_or_full`／`present_routes_relics_or_full`／`sidebar_refresh` 不得红（header／relics 场景「仍全量」步须改 `["actions"]`）。本场景不是契约场景 3 全表。

## 验收流程

UI 验收 **none**：本刀不改 `_submit`，玩家路径仍整树 `render`；画面刷新范围不变。不派验收者。

## 完成定义及档 2（尚未执行）

- 实现者交 `present` 的 `hand` 局部路由、`_hand` 键＋早退＋不叠按钮、`PRESENT_ADJACENCY` 与源码同批、`_present_needs_full_render` 的 `pressure.overloaded` 全量兜底、上述场景及 header／relics 场景「仍全量」步改名；独立新会话审查者只核对本域源码／测试与本契约；清洁者核对：无第二套刷新管线、无新 UI 文件、无 `_submit` 改接、手牌键只在 `_hand` 旁、`header`／`body_bar`／`relics` 键位置不变、邻接表源一致、依赖面 ⊆ 允许面。本刀不写 `docs/spec`。
- 实现者在 `spire-godot/` 运行 `& tools/check.ps1 -UIOnly -UISuite display -TimeoutSeconds 900`。通过＝退出码 0、`SUITE RESULT: display PASS`、完成标记、`summary.json` 的 `status=passed` 且指纹未变。未运行、`source_changed`、场景未注册进 `display_ui_cases.run`、或 `present` 空 snapshot 仍 `get_view`＝未完成。既有 `present_routes_*`／`sidebar_refresh` 不得变红。不改 `body_sidebar.gd`／`header.gd`／`relic_icon.gd` 则不借旧绿宣称本域通过，也不必扩跑。
- 档 2（选定加固者，独立实现／清洁后）。栈档 2：规则套件＋内容包。内容包不适用（未改 packs）。规则 headless 无法观察节点实例／手牌件数：本刀敏感性在 display 窗口套件上跑，命令同上。变异须红：①`present(["not_a_section"])` 或 `["*"]` 不走全量（`GameHeader` 实例保留）；②`present(["hand"])` 键命中仍重建该节（`card_buttons[first_uid]` 实例在未改键时被换）；③再 `_hand` 叠同 uid 按钮（该 uid `card_buttons` 件数＞1）；④生产源码出现重建／`get_view` 计数器。原版绿；变异复原后重跑本域。不能靠静态搜索替代①②③的行为敏感性。缺工具或失败＝未通过，不算不适用。
- 无打包、发布、push。

## 非目标

其余已声明节一次落地；`commit` 拆分；`present_rejection`；把 `_submit` 改接到 `present`；新 CSS／样式引擎；T4／T5；`card_facts`；`keyword_ids`；窗口输入队列；恢复 `ActionIndex`；改 `card_face.gd`／`card_motion.gd`／`header.tscn`／`game_layout.gd`／`relic_icon.gd`；改 `header`／`body_bar`／`relics` 键字段集；把 `display_facts` 扩进手牌键；本刀实施 phase／`card_chain`／locale／显示设置等全量兜底清单其余项；场景 5 `hand_node_identity_preserved` 全表（仅方向一致）。

## 风险假设

`layout.begin_frame` 仍释放 `GameHeader` 与手牌区控件，全量 vs 局部仍可用 `GameHeader` 与 `card_buttons[uid].get_instance_id()` 区分。局部路径仍不得 `begin_frame`、不得清空 `layout.used`。全量 `_battle_scene()` 仍调 `_hand()`：早退必须要求按钮仍在树上，否则 `begin_frame` 后键命中会丢手牌。键未覆盖 `_refresh_card_face` 已读显示字段时，早退会留下过期牌面／可用性／选中高亮。`_selecting_hand()` 为真时依赖 `display_facts` 亮灭，本刀不把 `display_facts` 写入键；玩家路径仍整树 `render`，选择类点击不走 `present`。`card_motion.pending_draws` 为空与缺失等价。`restart(42)` 战斗开局手牌非空，夹具不另造牌。`pressure.overloaded` 经 `_present_needs_full_render` 走全量，避免局部手牌键与高潮面板分叉。若实现要新 UI 文件、新允许边、或把候选事实写进手牌键，停工交回，不新开 `present` 文件迁就。
