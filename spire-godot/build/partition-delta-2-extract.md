# 规划者契约：present(dirty) 第二刀（scene_instances）

checkpoint(planner): 搜既有节键／早退，选定下一节

状态：**needs-human-review；停止，不派实现者**。通宵仍只授权落地既有节键／`present(dirty)`，不新写 CSS。第一刀已落地，勿重做：`present`＋`PRESENT_SECTIONS`；仅 `["body_bar"]` 局部走 `layout.body_sidebar`／`_presentation_key`；`["*"]`／未知／其它已声明名全量 `render(view)` 且不 `get_view`。`_submit` 仍整树 `render`。本刀只规划下一节，不铺剩余 14 节，不拆 `commit`／`present_rejection`，不把 `_submit` 改接到 `present`。HEAD `6d788f0` 静态切片，未实现、未运行。域：`ui/main.gd::present` 对节 `scene_instances` 的局部路由；对照 `docs/spec/response-pipeline.md` 节键表。

## 已有入口（搜键／早退；不建第二套刷新管线）

- 现行 `present`：`_present_needs_full_render` 仅当 `dirty==["body_bar"]` 且 layout／view 可用才局部；否则 `render(next)`。局部序仍是 `DragTargets.clear` → `_hide_term` → View 同步 → `layout.body_sidebar` → `end_frame` → `refresh_hints` → `_localize_controls`。无 `begin_frame`。
- `header`：`_header` 每次 `header.tscn.instantiate` 再 `header.configure`。`configure` **无键、无早退**，每次新建教程／状态／道具／卡组／地图／菜单按钮。节键表字段（`run_header` location/turn/order/last、`security`、`wall`、`wall_position.distance`、`pressure.overloaded`、`carried_items`、`capacity`、`deck_count`、`prison.active`、`phase`、`practice`、`show_route`、`save_failed`、locale）**未实现为键**。
- `drawers`：`_refresh_drawers` 每次 `queue_free` `drawer_layer` 再建。无节键早退。
- `hand`／`body_details`：`card_faces` 是本地翻面态（缓存与失效键允许项），不是节键。`_hand` 每次新建牌钮。`_refresh_card_face` 只就地刷一张牌面，不能当 `present(["hand"])` 键命中跳过。
- `relics`／`actions`／`posture`／`resources`／`show_log`／`pickers`／`speech`／`notice`／`page`：重建入口均无显示键早退。
- `scene_instances`（本节）：`game_layout.hero_portrait`／`enemy_group`／`body_sidebar` 按实例／`enemy.id` 复用；`arena.configure_hero`／`configure_enemy` 与 `equipment_portrait.configure` 用 `appearance==next_appearance` 早退。`body_sidebar._presentation_key` 已属 `body_bar`，本刀不重做。管线非目标含「不改 arena 立绘重画」。

## 切分与阻塞（新键或新边）

checkpoint(planner): scene_instances 无法无新键／新边落地

- 拟议边界：只把 `present` 局部名单从 `body_bar` 扩到 `scene_instances`（仍同一 `present`，无新 UI 文件）。`["scene_instances"]` 走固定动作序后调既有 `layout.hero_portrait`／对存活敌人 `layout.enemy_group`／`layout.body_sidebar`，再 `end_frame`。未知／`["*"]`／缺项／其它已声明名仍全量 `render(view)`，禁止 `get_view`。不改 `_submit`。
- 不允许的捷径：`layout.enemy_group` 在复用分组时**先删掉 art 以外的子节点**（`_battle_scene` 挂在分组上的意图图标、选敌钮、血条、状态条、投放接收区）。局部调用会剥掉 `page` 节节点，即使 `configure_enemy` 外观命中早退。`hero_portrait` 不剥这些；问题在 `enemy_group`。
- 避开剥节则必须择一，均超出本切分微调：
  1. **新建键字段集**（在 `present`／`main` 复制 arena 外观键，命中则不调 `enemy_group`）；或给 `header.configure`／其它无键节新建表行键。
  2. **新允许边**：`main.present` 直调 `arena.configure_hero`／`configure_enemy`，绕过 `game_layout.enemy_group`（M3 越过 M5）。
  3. 改 `game_layout.enemy_group` 不再剥子节点（改 M5；且碰 arena 重画非目标）。
- 因此标复杂计划：`needs-human-review`。切分认可不够。不写依赖规约、不派实现者。

## 待协调者交人审的决定

择一后重新规划：①批准 `scene_instances` 的新键字段集（或改 M5／新边）并重写本刀契约；②改下一节为 `header`（须批准 `header.configure` 新键字段集，覆盖节键表该行）；③取消本刀。禁止无新键就把 `present(["scene_instances"])` 接到 `enemy_group`。禁止一次铺剩余 14 节。

## Gherkin／验收／完成定义（待决，不是本次通过）

- 拟定 Gherkin 位置 `tests/display_ui_cases.gd`：Given 战斗页已 `render(view)`，钉 `HeroArt`／一处 `EnemyGroup_*` 实例、`GameHeader`、意图图标仍在分组下；测试侧 `GetViewCountingGame`。When `present(["scene_instances"])` 外观未变；`present(["*"])`／`present(["not_a_section"])`；改一处外观键内字段（如 `view.posture` 或敌人 `gone`，不 `dispatch`）再 `present(["scene_instances"])`。Then 键命中：header 与 hero／enemy 实例保留，分组下 page 子节点仍在，`get_view` 不变；`["*"]`／未知替换 `GameHeader`；键未命中：header 保留，该节外观与 View 一致。判据依赖上节人审选项，**暂不注册可运行场景**。
- UI 验收 **none**（玩家路径仍 `_submit`→整树 `render`）。若人审选剥节方案则画面会变，须另写验收——当前不派验收者。
- 完成定义：协调者记录切分**及**复杂计划人审后，才写依赖规约、才派实现者。档 2 预选仍为 display 窗口：该节键命中须跳过重建；未知／`["*"]` 仍全量；生产无计数器。现在 Godot／审查／清洁／加固均未验证。
- 允许实现面：未批准前 **空**。不得改 `_submit`／`commit`／`present_rejection`、不得新 UI 文件、不得改 core／data、不得改 `body_sidebar._presentation_key` 字段集。

## 非目标

其余 13 节的键与局部重建；T4／T5；`card_facts`；`keyword_ids`；新 CSS／样式引擎；窗口输入队列；提交路径去重；`commit` 拆分；`present_rejection`；`_submit` 改接 `present`；场景 1–9 一次落地；恢复 `ActionIndex`；改 arena 立绘重画。

## 风险假设

`begin_frame` 仍会拆掉 `GameHeader`，故全量 vs 局部仍可用 header 实例区分。第一刀 `end_frame` 依赖上次 `render` 残留的 `used`。若人审批准直调 `configure_*`，须重审 M3→M5 边界，不在未批时扩边。
