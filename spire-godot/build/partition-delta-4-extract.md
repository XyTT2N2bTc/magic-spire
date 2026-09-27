# 规划者契约：present(dirty) 第四刀（hand）

状态：可交协调者派实现者；**无新模块、无新允许边**，不标 `needs-human-review`。通宵仍授权落地既有节键／`present(dirty)`。节键表 `hand` 行已写字段集；给 `_hand` 建键并早退＝落地该行，不是新模块、不是新 CSS（relics／header 先例：「既有节键」＝规格已写字段，不是代码里已有 `_presentation_key`）。HEAD 起步 `972427b`。域：`ui/main.gd::present` 加 `["hand"]` 局部；键只在 `main.gd` 的 `_hand` 旁。保留 `header`／`body_bar`／`relics` 局部。不拆 `commit`、不接 `present_rejection`、不改 `_submit`。不铺其余节。不新写 CSS。本刀不写 `docs/spec`。

checkpoint(planner): specify present hand fourth slice

## 已有入口（扩展 present，不建第二套刷新管线）

- `present`／`PRESENT_SECTIONS`／`PRESENT_ADJACENCY`／`_present_needs_full_render` 已落地：仅 `["header"]`／`["body_bar"]`／`["relics"]` 局部；`["*"]`／缺项／未知／其它已声明名 → 全量 `render(当前 view)`，禁止再 `get_view`。局部固定序：`DragTargets.clear(self,false)` → `_hide_term` → View 同步 → 节 → `layout.end_frame()` → `keyboard_input.refresh_hints`（`call_deferred`）→ `_localize_controls`。局部不得 `begin_frame`，不得清空 `layout.used`。
- 静态搜键／早退：全仓 `_presentation_key` 定义仅 `body_sidebar.gd`（第一刀）与 `header.gd`（第二刀）；遗物键仅 `main.gd::_relic_presentation_key`（第三刀）。无更小既有节键可先扩 `present`。节键表下一行＝`hand`（`_hand`）。
- `_hand()` 每次 `_card`→`CardFace.new()` 写入 `card_buttons[uid]`；无键、无早退。全量 `render` 开头 `card_buttons.clear()` 且 `begin_frame` 释放 layout 临时子节点，故全量不叠。就地再调会叠牌。`view.pressure.overloaded` 时改走 `_climax_narration()`（读 `view.climax.text`）；`view.hand` 空则放无名单「手牌已用完」标签。全量战斗页 `_battle_scene` 顺手 `_hand()`。`ui/card_face.gd`／`card_motion.gd` 不拥有手牌节。
- 节键表 `hand` 行（键内容真源）：`hand`(uid/type/draw_serial/draw_free/single_face/availability/face_*)、对应 `card_texts` 项、`card_instances`、`card_faces[uid]`、`selected_card`、`_selecting_hand()`、`card_motion.pending_draws`。`version` 不进键。

## 切分、接口和依赖

- 只扩展既有 M3 `present`：`["hand"]` 局部；`["header"]`／`["body_bar"]`／`["relics"]` 仍局部；未知／`["*"]`／缺项／其余已声明名仍全量 `render(view)`（非空当前 View，禁止再 `get_view`）。`dirty.size()!=1` 仍全量。局部不得 `begin_frame`。
- `["hand"]` 局部：只调 `_hand`（或其就地早退／重建）。不得调 `_header`、不得 `header.configure`、不得 `_relic_row`、不得 `layout.body_sidebar`、不得 `_fixed_actions`／`_build_action_rail`／`_body_details`／`_hand_target_picker`／`_player_picker`、不得 instantiate `header.tscn`。layout 空／View 空 → 全量。无活手牌按钮且 `view.hand` 非空 → 本函数创建按钮，不因此改走全量。
- **高潮分支不进手牌键**：`_hand` 读 `view.pressure.overloaded` 与 `view.climax`，二者不在节键表 `hand` 行。本刀不新建字段集。改为 `_present_needs_full_render`：**仅当** `dirty==["hand"]` 且 `view.pressure.overloaded` 为真 → 全量。不得把 overloaded 扩成 `header`／`body_bar`／`relics` 的新全量条件（header 键已含 overloaded，其局部须保持）。局部 `["hand"]` 因而从不走 `_climax_narration`。
- 键只在 `main.gd`、紧挨 `_hand`（可名 `_hand_presentation_key`／保存 `_hand_key`）。不得在 `card_face.gd`／`card_motion.gd` 或新 UI 文件复制第二套 hand 键；不得新开手牌容器脚本／文件。允许在 `_hand` 内给返回的按钮设名（如 `HandCard_<uid>`）以便计数；这不是新模块。键＝纯数据副本（Array／Dictionary／基础类型），不存旧 View／候选／装备图／节点引用。
- 键字段必须覆盖 `_hand` 路径上 `_card`／`_refresh_card_face` **实际读取**且 ⊆ 节键表 `hand` 行的显示字段：每张 `uid`／`type`／`draw_serial`／`draw_free`／`single_face`／`availability`（free／bound 的 usable／dim／text）、合并 `card_texts[type]` 与 `card_instances[physical_uid 或 uid]` 后的 `face_*`（`face_names`／`face_effects`／`face_keywords`／`face_mana`／`face_costs`／`face_type_names`／`face_warnings`／`face_requirements` 等 `_refresh_card_face` 已读项）、当前手牌 uid 上的 `card_faces[uid]`、`selected_card`、`_selecting_hand()` **布尔**、`card_motion.pending_draws` 的 uid 集合（无 `card_motion` 视为空）。`version` 禁止。
- **不进键**（进键＝超出节键表的新字段集 → 停工交回）：`display_facts`／`_hand_choice` 候选行、`player_pick_data` 细字段（target／slot／card_uid／free 等）、`view.climax`、`view.pressure.overloaded`（改走上一则全量）、`unplayable`、悬停 `_card_tooltip` 的 `note`／`casting`、`display_settings`、locale（局部仍跑 `_localize_controls`）。`_card` 拖放载荷里的 `view.version` 不进键。`_hand` 新读显示字段必须同批进键，且仍 ⊆ 该行。
- 键命中：早退，保留每个 `view.hand` uid 的 `card_buttons[uid]` 实例（仍在树上、该 uid 件数＝1）；`card_buttons` 键集＝当前手牌 uid 集。禁止只凭 `_hand_key`、按钮已被 `begin_frame` 释放仍早退。键未命中：就地更新该节（先卸本节手牌按钮／空牌标签／误留的 `ClimaxNarration`，再按现行非高潮逻辑建模，或等价使每个手牌 uid 件数＝1）；`view.hand` 空则卸掉已有手牌按钮并至多保留 1 个空牌提示。不得把叠牌当跳过。全量 `_battle_scene`→`_hand` 仍须写回键。
- 允许实现面：`spire-godot/ui/main.gd` 的 `present` 路由（含 `_present_needs_full_render` 对 **`["hand"]`＋overloaded** 的全量、`PRESENT_ADJACENCY` 与源同步：`present` 增 `_hand`，`_hand` 读本文件键函数）、`_hand` 键＋早退＋不叠牌；`spire-godot/tests/display_ui_cases.gd` 单个具名场景／`run` 注册，并改 `present_routes_header_or_full` 与 `present_routes_relics_or_full` 的「已声明非局部」步：`present(["hand"])` 改为仍全量的已声明名（`["actions"]`），因本刀后 hand 局部。不得改 `_submit`／`commit`／`present_rejection`、不得改 `header._presentation_key`／`body_sidebar._presentation_key`／`_relic_presentation_key` 字段集、不得改 `header.tscn`／`header.gd`／`game_layout.gd`／`card_face.gd`／`card_motion.gd`／core／data。测试可对 `get_view` 做计数包装；生产源码不带计数器。
- 允许方向：仍 M3 内 `present`→`_hand`（既有 `_battle_scene`→`_hand` 同向）与既有 M3→M5 header／body、M3→`_relic_row`、M3→M1.refresh_hints；测试 → `main.present`／`render`。**不新增**模块、运行时依赖、存档／schema、`present` 文件、`main`→core 新边、UI 文件。若实现仍要新模块／新 UI 文件／新允许边／超出节键表的新字段集 → `needs-human-review` 并停下。
- `main.gd` 已超行数线；本刀只加薄路由与 `_hand` 早退，**不**为凑行数拆新模块。Godot 无 Size and ESM。`present(dirty: Array=…)` 保持未类型化 Array。

## Gherkin：`present_routes_hand_or_full`（一个可观察行为）

Given `tests/display_ui_cases.gd`，`ui.restart(42)` 后 `render(ui.view)`（战斗页，`GameHeader` 已建，`view.hand` 非空且非 `pressure.overloaded`）。`first_uid=view.hand[0].uid`。测试侧 `GetViewCountingGame`（或等价包装，生产无计数器）接到 `ui.game` 后再 `render(ui.view)` 一次，记下 `get_view` 基线、`GameHeader` 实例、`RelicStrip` 实例（0 或 1）、`card_buttons[first_uid]` 实例、`ui.body_buttons.wrist`（若有）、快照／`state.rng`。不调 `_submit`。
When 依次：① `present(["hand"])` 空 snapshot、View／locale／选中态未改，再立刻第二次 `present(["hand"])`；② `present(["*"])`；③ `present(["not_a_section"])`；④ 只改 `ui.view.hand[0].availability` 上当前翻面（`card_faces.get(first_uid,false)` → free 否则 bound）一处键内显示字段（把 `text` 写成 `"probe-hand"` 且 `usable=false`／`dim=true`，不 `dispatch`）再 `present(["hand"])`；⑤ `present(["header"])`；⑥ `present(["body_bar"])`；⑦ `present(["relics"])`；⑧ `present(["actions"])`（已声明、本刀非局部）；⑨ `present(["hand"], snapshot)` 传入当前 View 的非空副本。每步 `await t.frames`，每步记下该步之前的 `GameHeader`／`card_buttons[first_uid]` 实例。
Then ① `card_buttons[first_uid]` 实例保留；该 uid 活按钮件数＝1；`card_buttons` 键数＝`view.hand.size()`；`GameHeader` 实例保留；有则 `RelicStrip` 实例保留；wrist／hero／body／敌人仍有效；`get_view`＝基线。②与③ 各相对该步之前的 `GameHeader` 被替换（全量走了 `begin_frame`），`get_view` 仍＝基线。④ `GameHeader` 等于③之后的那个（不再全量）；`card_buttons[first_uid]` 已换或等价重建；`CardAvailability`（或所改可用性对应可见控件）可见文本含 `probe-hand`；该 uid 件数仍＝1（不得叠）。⑤⑥⑦ `GameHeader` 等于④之后的那个且 `card_buttons[first_uid]` 不被⑤⑥⑦换掉（`header`／`body_bar`／`relics` 路由仍局部、不顺手 `_hand`）。⑧ `GameHeader` 被替换（其余已声明名仍全量）。⑨ `get_view` 仍＝基线，`ui.view` 即传入 snapshot。全程 `export_snapshot()`／随机游标不变。不得用生产计数器；不得把 `render()` 空 snapshot 的 `get_view` 算进 present 义务。既有 `present_routes_body_bar_or_full`／`present_routes_header_or_full`／`present_routes_relics_or_full`／`sidebar_refresh` 不得红（header 与 relics 的「已声明非局部」步须改 `["actions"]`）。本场景不是契约场景 3／5 全表。

## 验收流程

UI 验收 **none**：本刀不改 `_submit`，玩家路径仍整树 `render`；画面刷新范围不变。不派验收者。

## 完成定义及档 2（尚未执行）

- 实现者交 `present` 的 `hand` 局部路由、`_hand` 键＋早退＋不叠牌、`PRESENT_ADJACENCY` 与源同步、`_present_needs_full_render` 仅对 `["hand"]`＋overloaded 全量、上述场景及 header／relics「已声明非局部」步改名；独立新会话审查者只核对本域源码／测试与本契约；清洁者核对：无第二套刷新管线、无新 UI 文件、无 `_submit` 改接、hand 键只在 `main.gd` 的 `_hand` 旁、`header`／`body_bar`／`relics` 键仍只在各自原位、邻接表与源一致、依赖面 ⊆ 允许面、overloaded 全量未扩到其它已局部节。本刀不写 `docs/spec`。
- 实现者在 `spire-godot/` 运行 `& tools/check.ps1 -UIOnly -UISuite display -TimeoutSeconds 900`。通过＝退出码 0、`SUITE RESULT: display PASS`、完成标记、`summary.json` 的 `status=passed` 且指纹未变。未运行、`source_changed`、场景未注册进 `display_ui_cases.run`、或 `present` 空 snapshot 仍 `get_view`＝未完成。既有 `present_routes_body_bar_or_full`／`present_routes_header_or_full`／`present_routes_relics_or_full`／`sidebar_refresh` 不得变红。不改 `body_sidebar.gd`／`header.gd` 则不借其旧绿宣称本域通过，也不必扩跑。
- 档 2（选定加固者，独立实现／清洁后）。栈档 2：规则套件＋内容包。内容包不适用（未改 packs）。规则 headless 无法观察节点实例／牌数：本刀敏感性在 display 窗口套件上跑，命令同上。变异须红：①`present(["not_a_section"])` 或 `["*"]` 不走全量（`GameHeader` 实例保留）；②`present(["hand"])` 键命中仍重建该节（`card_buttons[first_uid]` 在未改键时被换）；③再 `_hand` 叠牌（同一 uid 活按钮件数＞1）；④生产源码出现重建／`get_view` 计数器。原版绿；变异复原后重跑本域。不能靠静态搜索替代①②③的行为敏感性。缺工具或失败＝未通过，不算不适用。
- 无打包、发布、push。

## 非目标

其余已声明节一次落地；`commit` 拆分；`present_rejection`；把 `_submit` 改接到 `present`；新 CSS／样式引擎；T4／T5；`card_facts`；`keyword_ids`；窗口输入队列；恢复 `ActionIndex`；改 `header.tscn`／`header.gd`／`game_layout.gd`／`card_face.gd`／`card_motion.gd`；改 `body_sidebar`／`header`／`relics` 键字段集；把 `display_facts`／`climax`／`player_pick_data` 细字段扩进 hand 键；把 `pressure.overloaded` 做成全局（非仅 `["hand"]`）全量兜底；实施 phase／locale／显示设置等其余兜底清单项；场景 5 `hand_node_identity_preserved` 全表。

## 风险假设

`layout.begin_frame` 仍释放 `GameHeader` 与手牌 `CardFace`，全量 vs 局部仍可用二者实例区分。局部路径仍不得 `begin_frame`、不得清空 `layout.used`（否则 `end_frame` 会藏 hero／卸 body／敌人）。全量 `_battle_scene()` 现顺手 `_hand()`：`["header"]`／`["relics"]`／`["body_bar"]` 局部不得走 `_hand`。键命中须要求按钮仍在树上，否则 `begin_frame` 后键命中会丢手牌。`_selecting_hand()` 为真时亮灭依赖 `display_facts`；本刀不把候选行写入键；玩家路径仍整树 `render`，选择类点击不走 `present`。拖放载荷里的 `version` 在键命中按钮上可能陈旧；本刀不改 `_submit`。`restart(42)` 开局手牌非空且非高潮，夹具不另造牌、不测高潮。若实现要新 UI 文件或新允许边或把 `display_facts`／`climax` 写入键，停工交回，不新开 `present`／手牌容器文件迁就。
