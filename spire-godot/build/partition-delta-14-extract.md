# 规划者契约：present(dirty) 第十四刀（page）

状态：`needs-human-review`；**停工**，不派实现者。通宵授权只覆盖既有节键／`present(dirty)` 的无新模块／无新允许边微调；`page` 不满足。HEAD 起步 `9bc3c52`。域：节键表 `page` 行切分未定。不拆 `commit`、不接 `present_rejection`、不改 `_submit`。不铺 `scene_instances`。不新写 CSS。本刀不写 `docs/spec`。不改产品代码。

checkpoint(planner): specify present page slice

## 切片（未切）

节键表下一未局部已声明行＝`page`（重建入口：`_route_screen`／`_rewards`／`_service_screen`／`_event_screen`／`_prison_controls`／`_capture_screen`／`_inspection_screen`／`_practice_screen`／`_demo_exit_screen`／`_battle_scene`；键：`phase` 及其实际读取字段；**结构变化一律走兜底清单**）。drawers 先例是同层可选窗里落地一个既有构建器（`_menu_drawer`）。`page` 表列入口是按 `phase`／`show_route`／`reward_panel` 互斥的整页，不是同层可拆窗。禁止跳过本行去切 `scene_instances`。

今日：`present(["page"])` 已因 `_present_needs_full_render` 末行全量 `render(当前 view)`（`display_ui_cases` 各 `present_routes_*` 的「已声明非局部」步钉 `GameHeader` 被替换）。`PRESENT_ADJACENCY` 的 `present` 不列 `_battle_scene`／`_route_screen`／`_rewards`／`_service_screen`／`_event_screen`／`reward_screen.build`／`EventScreen.build`／`ShopScreen`／`layout.hero_portrait`／`layout.enemy_group`；注释写明 present 不调 `_battle_scene`。局部路径不得 `begin_frame`。

## 切分（未定，故实现面为空）

- 不允许扩 `present(["page"])` 局部。不允许新 UI 文件、新 CSS、新模块、新允许边、把键写入 `_battle_scene`／`game_layout`／`reward_screen.gd`。
- 不允许把本行拆成未列名的新重建入口（从 `_battle_scene` 抽出 HUD／meter／drop）。那不是表列既有构建器，超出切分内微调。
- 人审之前：实现面＝空；允许方向＝不变；Gherkin＝无；门禁＝不跑。

## 标记原因（满足复杂计划任一条即停）

- **结构变化必须全量**：规格兜底清单含 `phase` 变化、`show_home` 进出、`show_route` 切换、locale、显示设置、`reward_panel.active`、`demo_end`、`pressure.overloaded`、`view.card_chain` 非空、首次战斗教程。表列入口切换＝这些条件，不是抽屉开一扇。
- **需要新边／会铺其它节**：`_battle_scene` 调 `layout.hero_portrait`／`layout.enemy_group`（`scene_instances`）与 `_speech_bubble`（`speech`）。`present`→`_battle_scene` 会越过当前邻接，并顺手那两节。无 `begin_frame` 时 `_place` 叠 hero drop／status／meter／施法标签；`begin_frame` 释 `GameHeader`＝全量。`enemy_group` 会清掉立绘外子节点再建模，仍碰 scene_instances。
- **无 drawers 式既有叶**：`_route_screen` 建 `RouteWorkspace` 且 `reparent` `RelicStrip`（`relics`）。`_rewards` 走 `reward_screen.gd.build`（可转 `departure_screen`／`relic_bundle_screen`）；`reward_panel.active` 已是全局兜底，且 `["actions"]` 已对它全量。`_service_screen`／`_event_screen` 走 `ShopScreen`／`EventScreen.build`。`_prison_controls` 亦由 `_fixed_actions` 调用（与 `actions` 双属）且 `phase=="prison"` 非战斗。`_capture_screen`／`_inspection_screen`／`_practice_screen`／`_demo_exit_screen` 均为换页。
- **无法保持严格非目标／小步反馈**：硬切任一入口要么叠节点、要么 `begin_frame` 全量、要么新边进其它节／其它 UI 文件。不能诚实地说一份 Gherkin＋验收流程就是全部契约。

## Gherkin

无。不发明 `present_routes_page_or_full`。既有场景里 `present(["page"])` 仍表示全量，不得改其断言。

## 验收流程

UI 验收 **none**。不派验收者。不改 `_submit`。

## 完成定义

- 本提取物已写入并 checkpoint。协调者等人审切分（可局部的页、键字段、是否允许 `present`→表列入口／`game_layout` 新边）。**人审记录之前实现者不开工。**
- 不跑 `& tools/check.ps1`。不派审查者／清洁者／加固者。
- 无打包、发布、push。

## 非目标

实现 `["page"]` 局部；抽出新 page／HUD 脚本；改 `PRESENT_ADJACENCY`；改 `game_layout.gd`／`reward_screen.gd`／`event_screen.gd`／`shop_screen.gd`／`header.tscn`／`header.gd`／`body_sidebar.gd`／`deck_browser.gd`／`first_turn_presenter.gd`／`command_routes.gd`／`command_router.gd`／`touch_input.gd`；铺 `scene_instances`；改已局部节键；拆 `commit`；`present_rejection`；把 `_submit` 改接到 `present`；新 CSS；实施兜底清单其余项；改 `docs/spec`。

## 风险假设

`layout.begin_frame` 仍释放 `GameHeader` 与 `RouteWorkspace`／`BattleRewards`／商店／事件根，保留 gallery／hero／body／enemies。局部不得 `begin_frame`、不得清空 `layout.used`；`end_frame` 仍按 `used` 显隐／回收 hero／body／敌人。`hero_portrait` 可复用实例，但 `_battle_scene` 仍写 scene_instances 并清敌人组子树。玩家路径仍整树 `render`。人未裁定前不得把「战斗页已稳定」当成可局部。
