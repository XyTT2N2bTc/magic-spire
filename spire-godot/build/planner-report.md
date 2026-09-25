# 规划者报告：present(dirty) 第二刀 scene_instances

checkpoint(planner): 汇总第二刀阻塞

- 域：`ui/main.gd::present` 下一节 `scene_instances`（节键表：`layout.hero_portrait`／`enemy_group`／`body_sidebar`，外观由 arena／`equipment_portrait`／`body_sidebar` 自身比对）。不改 `_submit`。不拆 `commit`／`present_rejection`。不重做 `body_bar`。
- 状态：**needs-human-review；停止**。搜键：`header.configure` 无键；drawer 无早退；`card_faces` 非节键。仅 `scene_instances` 有既有外观早退，但 `game_layout.enemy_group` 复用时剥掉 `_battle_scene` 挂上的 page 子节点；避开则须新键字段集、或 M3 越过 M5 的新边、或改 M5。契约 `spire-godot/build/partition-delta-2-extract.md`（未覆写第一刀提取物）。起始 HEAD `6d788f0` 静态读取；未实现、未跑 Godot。
- 切分：未批准前允许实现面为空。未知／`["*"]` 仍须全量的档 2 口径保留为待决，不注册新 Gherkin。验收 UI **none**。
- 检查证据：仅静态读取 `present`／`header.configure`／`_refresh_drawers`／`_hand`／`arena`／`equipment_portrait`／`game_layout.enemy_group`；Godot／测试／审查／清洁／加固均未验证，不报告通过；无产品源码、打包、发布或 push。
