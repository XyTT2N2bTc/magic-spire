# 规划者契约：present(dirty) 第一刀（body_bar）

状态：可交协调者；**无新模块、无新允许边**，不标 `needs-human-review`。通宵已授权落地既有 `present(dirty)`／节键，不新写 CSS／样式引擎。HEAD `12c8191` 静态切片，未实现、未运行。域：`ui/main.gd` 的 M3 展示调度（现行 `render`／`_refresh_drawers`）加 `present`；节 `body_bar` 复用 `ui/shell/body_sidebar.gd` 既有 `_presentation_key`／`_slots_key`。本刀不拆 `commit`、不接 `present_rejection`、不改 `_submit`。

## 已有入口（扩展，不建第二套刷新管线）

- 现行落地：`ui/main.gd::render(snapshot={})`（空 snapshot 才 `get_view`）与 `_submit` → `render(updated)`。无 `commit`／`present`／`present_rejection`／通用脏节表。
- 节重建仍在 `main.gd`：`_header`、`_relic_row`、`_hand`、`_fixed_actions`／`_build_action_rail`、`_posture_controls`／`_wall_controls`、`_bottom_controls`、`_log_drawer`、`_body_drawer` → `layout.body_sidebar`、`_body_details`、`_player_picker`／`_hand_target_picker`、`_speech_bubble`／`_npc_speech_bubble`、`_show_term`（notice）、`_refresh_drawers`、`_route_screen` 等 page 入口。
- 已有键命中跳过：仅 `body_sidebar.configure` 对 `_slots_key==_presentation_key(ui)` 早退并保留按钮／滚动。`header.configure` 无键。`layout.begin_frame` 会释放除 gallery／hero／body／enemies 外的临时子节点（含每次 `render` 新建的 `GameHeader`）。
- `tests/display_ui_cases.gd::sidebar_refresh` 已钉 `render(ui.view)` 下身体栏实例与滚动保留。本刀扩展同一语义到 `present(["body_bar"])`，不另写一套身体栏缓存。

## 切分、接口和依赖

- 只在既有 M3（`ui/main.gd`）增加 `present(dirty: Array[String] = ["*"], snapshot: Dictionary = {}) -> void`。不新增 UI 文件（契约禁止未提案的独立 `present` 文件）。`main.gd` 已超行数线；本刀在原文件加薄入口，**不**为凑行数拆出新模块。
- 数据流：调用方传入脏集 → **显式**对照节名枚举 → `["*"]`／缺项／未知名／本刀未局部路由的已声明节 → 全量 `render(view)`（传入非空当前 View，禁止再 `get_view`）→ 仅 `["body_bar"]` 且 layout／view 可用 → 固定动作序的局部路径：`DragTargets.clear(self,false)` → `_hide_term` → View 同步（非空 snapshot 原子替换 `ui.view`；空则用当前 `ui.view`；**不**恢复已删的 `ActionIndex`）→ `layout.body_sidebar(self)`（其内既有键比对）→ `layout.end_frame()` → `keyboard_input.refresh_hints`（`call_deferred`）→ `_localize_controls`。局部路径**不得** `begin_frame`（会拆掉 header）。
- 节名枚举（`dirty` 元素真源，与 `docs/spec/response-pipeline.md` 节键表同名）：`header`、`relics`、`hand`、`actions`、`posture`、`resources`、`show_log`、`body_bar`、`body_details`、`pickers`、`speech`、`notice`、`drawers`、`page`、`scene_instances`。本刀只对 `body_bar` 局部调用既有 `layout.body_sidebar`／`configure`；其余已声明名走全量，不算未知。未知＝不在该枚举且不是 `"*"`。
- `body_bar` 键仍只在 `body_sidebar._presentation_key`：不在 `main.gd` 复制一份。`version` 不进键。禁止第二套节键或 CSS／样式引擎。
- 允许实现面：`spire-godot/ui/main.gd` 的 `present`＋节名枚举＋上述路由；`spire-godot/tests/display_ui_cases.gd` 单个具名场景／`run` 注册。不得改 `_submit`／`commit`／`present_rejection`、不得改 `body_sidebar._presentation_key` 字段集（除非同批证明 configure 新读了显示字段）、不得改 core／data。测试可对 `get_view` 做计数包装；生产源码不带计数器。
- 允许方向：仍是 `M3 → M5`（`layout.body_sidebar`／`configure`）与 `M3 → M1.refresh_hints`；测试 → `main.present`／`render`。**不新增**模块、运行时依赖、存档／schema、`present` 文件、`main`→core 新边。若实现要新 UI 文件或新允许边 → `needs-human-review` 并停下。

## Gherkin：`present_routes_body_bar_or_full`（一个可观察行为）

Given `tests/display_ui_cases.gd`，`ui.restart(42)` 后 `render(ui.view)`（战斗页，header／body 已建）。测试侧 `GetViewCountingGame`（或等价包装，生产无计数器）接到 `ui.game` 后再 `render(ui.view)` 一次，记下 `get_view` 基线。钉 `GameHeader` 实例、`ui.body_buttons.wrist`（或同页稳定 `BodySlot_*`）、一处 `BodyRegionContent_*` 的 `scroll_vertical`（可按 `sidebar_refresh` 把 `BodyEquipmentPanel.size.y` 压到可滚）。Oracle＝`body_sidebar._presentation_key(ui)`；快照／`state.rng`。不调 `_submit`。
When 依次：① `present(["body_bar"])` 空 snapshot、View 未改；② `present(["*"])`；③ `present(["not_a_section"])`；④ 只改 `ui.view` 上一处键内显示字段（如某 `body_regions.members` 的 `count`，不 `dispatch`）再 `present(["body_bar"])`；⑤ `present(["body_bar"], snapshot)` 传入当前 View 的非空副本。每步 `await t.frames`，每步记下该步之前的 `GameHeader` 实例。
Then ① `GameHeader` 与身体按钮实例 id、滚动不变，`get_view` 计数＝基线。②与③ 各相对该步之前的 `GameHeader` 实例被替换（全量走了 `begin_frame`），`get_view` 仍＝基线。④ header 实例等于③之后的那个（不再全量）；身体按钮实例已换且可见件数与改后 View 一致；`get_view` 仍＝基线。⑤ `get_view` 仍＝基线，`ui.view` 即传入 snapshot。全程 `export_snapshot()`／随机游标不变。不得用生产计数器；不得把 `render()` 空 snapshot 的 `get_view` 算进 present 义务。本场景不是契约场景 3 全表。

## 验收流程

UI 验收 **none**：本刀不改 `_submit`，玩家路径仍整树 `render`；画面刷新范围不变。不派验收者。

## 完成定义及档 2（尚未执行）

- 实现者交 `present`、节名枚举与上述场景；独立新会话审查者只核对本域源码／测试与本契约；清洁者核对：无第二套刷新管线、无新 UI 文件、无 `_submit` 改接、`body_bar` 键仍只在 `_presentation_key`、依赖面 ⊆ 允许面。本刀不写 `docs/spec`。
- 实现者在 `spire-godot/` 运行 `& tools/check.ps1 -UIOnly -UISuite display -TimeoutSeconds 900`。通过＝退出码 0、`SUITE RESULT: display PASS`、完成标记、`summary.json` 的 `status=passed` 且指纹未变。未运行、`source_changed`、场景未注册进 `display_ui_cases.run`、或 `present` 空 snapshot 仍 `get_view`＝未完成。既有 `sidebar_refresh` 不得变红。不改 `body_sidebar.gd` 则不借 body_layout 旧绿宣称本域通过，也不必扩跑。
- 档 2（选定加固者，独立实现／清洁后）。栈档 2 的内容包不适用（未改 packs）。规则 headless 无法观察节点实例：本刀敏感性在 display 窗口套件上跑，命令同上。变异须红：①`present(["not_a_section"])` 或 `["*"]` 不走全量（`GameHeader` 实例保留）；②`present(["body_bar"])` 键命中仍重建该节（身体按钮实例被换）；③生产源码出现重建／`get_view` 计数器。原版绿；变异复原后重跑本域。不能靠静态搜索替代①②的行为敏感性。缺工具或失败＝未通过，不算不适用。
- 无打包、发布、push。

## 非目标

T4／T5；`card_facts`；`keyword_ids`；新 CSS／样式引擎；窗口输入队列；提交路径去重（已否）；`commit` 拆分；`present_rejection`；把 `_submit` 改接到 `present`；场景 1–9 一次落地；其余节的键计算与局部重建；兜底清单（phase／locale／显示设置等）除本刀已写的未知／`["*"]`／缺项／layout 空／View 空；恢复 `ActionIndex`。

## 风险假设

`layout.begin_frame` 释放 `GameHeader` 而保留 `layout.body`，故全量 vs `body_bar` 局部可用 header 实例区分，不必生产计数器。`configure` 既有键命中早退对 `present` 调用的 `layout.body_sidebar` 仍然成立。若局部路径不调 `begin_frame` 时 `end_frame` 会误删 hero／body／敌人，停工交回，不新开 `present` 文件迁就。
