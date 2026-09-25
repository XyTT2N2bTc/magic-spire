# 规划者契约：present(dirty) 第十四刀（page）

状态：**`needs-human-review`，停**。不派实现者。通宵代批不及：新允许边／拆 `_battle_scene`／把结构页当抽屉叶硬切。节键表下一未局部行＝`page`；不得跳去 `scene_instances`。HEAD 起步 `9bc3c52`。域：未授权改 `ui/main.gd::present`。保留 `header`／`body_bar`／`relics`／`hand`／`actions`／`posture`／`resources`／`show_log`／`body_details`／`pickers`／`speech`／`notice`／`drawers` 局部。不拆 `commit`、不接 `present_rejection`、不改 `_submit`。不新写 CSS。本刀不写 `docs/spec`。

checkpoint(planner): specify present page slice

## 标记原因（复杂计划，切分未定）

- 节键表 `page` 行：重建入口＝`_route_screen`／`_rewards`／`_service_screen`／`_event_screen`／`_prison_controls`／`_capture_screen`／`_inspection_screen`／`_practice_screen`／`_demo_exit_screen`／`_battle_scene`；键＝`phase` 及其实际读取字段；**结构变化一律走兜底清单**（`phase` 变化 · `show_home` 进入／离开 · `show_route` 切换 · locale · 显示设置 · layout 空 · View 空 · snapshot `version` 回退 · 节键缺失／未知 · `reward_panel.active` · `demo_end` · `pressure.overloaded` · 非空 `card_chain` · 首次战斗教程）。这些页是互斥结构，不是 drawers 那种同层可选窗。
- 今日 `present(["page"])` 已因 `_present_needs_full_render` 末行全量（drawers 场景⑫ 钉 `GameHeader` 被换）。`PRESENT_ADJACENCY` 与源注释写明 `present` **不**调 `_battle_scene`。局部不得 `begin_frame`（会卸 `GameHeader`＝全量）；`_place` 无卸窗则叠层。
- 无既有可单独局部的叶（drawers＝已有 `_menu_drawer`）。硬切任一表列入口都会越界：
  - `_battle_scene`：`layout.hero_portrait`／`enemy_group`＝`scene_instances`；`_speech_bubble`＝`speech`；layout 直子接收区／状态条／资源条无整组卸窗。`present`→`_battle_scene` 是新边，且顺手其它节。
  - `_route_screen`：`show_route`／非战斗属兜底；`RelicStrip.reparent` 动已局部 `relics`。
  - `_rewards`：`reward_panel.active` 已在兜底清单；且 `reward_screen.build`／`departure_screen`／`relic_bundle_screen` 不在现行 `present` 邻接。
  - `_service_screen`／`_event_screen`／`_capture_screen`／`_inspection_screen`／`_practice_screen`／`_demo_exit_screen`：换相／换页＝结构变化。
  - `_prison_controls`：`_fixed_actions` 亦调（与 `actions` 双入口）；`phase=="prison"` 非战斗。拆出新 HUD 构建器＝新模块。
- 满足规划者复杂计划任一条：新增允许边（超出微调）、无法保持严格非目标（会铺 `scene_instances`／`speech`／`relics` 或拆新入口）、不能诚实地说 Gherkin＋验收即全部契约。不代批。不硬切。不跳节。

## 已有入口（只读，本刀不扩）

- `present`／`PRESENT_SECTIONS`／`PRESENT_ADJACENCY`／`_present_needs_full_render` 已落地：上列 13 节局部；`["page"]`／`["scene_instances"]`／`["*"]`／缺项／未知仍全量 `render(当前 view)`，禁止再 `get_view`。
- 全量 `render`：`_header()` 后按 `reward_panel.layout`／`phase`／`demo_exit`／`show_route`／`practice` 互斥调上列页入口；`else` 才 `_battle_scene`（随后 `_chain_screen`／`_rewards`／`_fixed_actions`＋`_hand`）。`_battle_scene` 写 hero 接收区、状态条、资源条、`_speech_bubble`、敌人组内意图／选敌／生命。`game_layout.begin_frame` 清空 `used` 并释放除 gallery／hero／body／enemies 外子节点；`hero_portrait`／`enemy_group` 复用实例但 `enemy_group` 会清掉立绘以外子节点。
- 静态搜键：无 `page` 节键。无更小既有页构建器可先扩 `present` 而不碰结构／邻接。

## 切分、接口和依赖（未批准，实现面空）

- **不允许**本刀改 `present` 路由、邻接表、键、测试、`_submit`／`commit`／`present_rejection`、任何 UI／core／data 文件。
- 切分未定：不得假定 `["page"]` 局部＝`_battle_scene` 或其它单一入口。人审须先定：page 是否永远全量（规格「结构变化走兜底」落地为该节无局部）、或另开构建器／另开节、或允许 `present`→页入口及哪些邻接。未记录批准前实现者不开工。
- 允许实现面：**无**。允许方向：**无新增**。

## Gherkin

**无**。不发明 `present_routes_page_or_full`。既有 drawers／notice 等场景的 `present(["page"])` 全量步保持现状，本刀不改测试。

## 验收流程

UI 验收 **none**。不派验收者、不派实现者。

## 完成定义

- 本文件已 checkpoint。人审记录前不得派实现／清洁／加固。
- 门禁命令：**无**（不跑 Godot／`check.ps1`）。
- 无打包、发布、push。

## 非目标

把 `page` 硬切成局部；跳过 `page` 去切 `scene_instances`；`present`→`_battle_scene`／`_route_screen`／`reward_screen.build`／`ShopScreen`／`EventScreen.build`；拆 `_battle_scene` 新模块；`commit` 拆分；`present_rejection`；改 `_submit`；新 CSS；改已局部节键；实施兜底清单其余项为全局条件（本刀亦不改代码）。

## 风险假设

`layout.end_frame` 只处理 hero／body／敌人；页级 `_place` 面板不在 `used` 里，全量靠 `begin_frame` 卸。玩家路径仍整树 `render`。若人审批准「page 永不局部」，下一切仍是 `scene_instances`，须另开规划刀，不得把本文件当开工契约。
