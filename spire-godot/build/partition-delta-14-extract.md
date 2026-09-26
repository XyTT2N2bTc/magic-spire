# 规划者契约：present(dirty) 第十四刀（page）

状态：**已闭合**（打回后按已记录切分，不是停工等人批准）。`page` **保全量**；允许面空；无 Gherkin；无门禁。不派实现者。不标 `needs-human-review`（切分＝按已有规格做，不是越界）。通宵仍授权落地既有节键／`present(dirty)` 的无新模块／无新允许边微调；本刀不改 `present`。HEAD 起步 `9bc3c52`。域：节键表 `page` 行闭合为全量兜底。不拆 `commit`、不接 `present_rejection`、不改 `_submit`。不铺 `scene_instances`（下一刀）。不新写 CSS。本刀不写 `docs/spec`。不改产品代码。

checkpoint(planner): close present page slice as full-render

## 切片（已闭合）

节键表 `page` 行：重建入口 `_route_screen`／`_rewards`／`_service_screen`／`_event_screen`／`_prison_controls`／`_capture_screen`／`_inspection_screen`／`_practice_screen`／`_demo_exit_screen`／`_battle_scene`；键：`phase` 及其实际读取字段；**结构变化一律走兜底清单**（规格已写，引用即可）。drawers 先例是同层可选窗里落地一个既有构建器（`_menu_drawer`）。`page` 表列入口是按 `phase`／`show_route`／`reward_panel` 互斥的整页，不是同层可拆窗。无既有可单独局部的叶。硬切表列入口会新增 `present` 邻接并铺到 `scene_instances`／`speech`／`relics`。

今日：`present(["page"])` 已因 `_present_needs_full_render` 末行／未知节兜底全量 `render(当前 view)`。既有 drawers 等场景的 `present(["page"])` 全量步保持现状。`PRESENT_ADJACENCY` 的 `present` 不列 `_battle_scene`／`_route_screen`／`_rewards`／`_service_screen`／`_event_screen`／`reward_screen.build`／`EventScreen.build`／`ShopScreen`／`layout.hero_portrait`／`layout.enemy_group`；注释写明 present 不调 `_battle_scene`。

这不是跳节：本刀闭合后，下一未局部行＝`scene_instances`（`partition-delta-15-extract.md`）。

## 切分（已记录）

- `["page"]` 继续走现有 `_present_needs_full_render` 末行／未知节兜底。不扩 `present(["page"])` 局部。
- 本刀不改 `present`、不派实现者、不新模块、不新允许边。不把键写入 `_battle_scene`／`game_layout`／`reward_screen.gd`。不从 `_battle_scene` 抽出 HUD／meter／drop。
- 允许实现面＝**空**。允许方向＝不变。Gherkin＝无。门禁＝不跑。

## Gherkin

无。不发明 `present_routes_page_or_full`。既有场景里 `present(["page"])` 仍表示全量，不得改其断言。

## 验收流程

UI 验收 **none**。不派验收者。不改 `_submit`。

## 完成定义

- 本提取物已按打回切分改写并 checkpoint。实现者不开工。不跑 `& tools/check.ps1`。不派审查者／清洁者／加固者。
- 无打包、发布、push。

## 非目标

实现 `["page"]` 局部；抽出新 page／HUD 脚本；改 `PRESENT_ADJACENCY`；改 `game_layout.gd`／`reward_screen.gd`／`event_screen.gd`／`shop_screen.gd`／`header.tscn`／`header.gd`／`body_sidebar.gd`／`deck_browser.gd`／`first_turn_presenter.gd`／`command_routes.gd`／`command_router.gd`／`touch_input.gd`；铺 `scene_instances`；改已局部节键；拆 `commit`；`present_rejection`；把 `_submit` 改接到 `present`；新 CSS；实施兜底清单其余项；改 `docs/spec`。

## 风险假设

`layout.begin_frame` 仍释放 `GameHeader` 与 `RouteWorkspace`／`BattleRewards`／商店／事件根，保留 gallery／hero／body／enemies。局部不得 `begin_frame`、不得清空 `layout.used`。玩家路径仍整树 `render`。`["page"]` 全量步是既有测试钉 `GameHeader` 被替换的判据，闭合后不得改该钉。
