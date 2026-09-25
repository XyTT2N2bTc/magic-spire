# 规划者报告：present(dirty) 第一刀

- 域：`ui/main.gd` M3 增加 `present(dirty, snapshot)`；仅 `body_bar` 局部走既有 `layout.body_sidebar`／`_presentation_key`。不改 `_submit`，不做 `commit`／`present_rejection`。
- 状态：可交协调者；**不** `needs-human-review`（无新模块、无新允许边；通宵已授权落地既有 present／节键）。契约 `spire-godot/build/partition-delta-extract.md`。对照 `docs/spec/response-pipeline.md` 接缝 B／节键表与现行 `render`／`_submit`。HEAD 规划起点 `12c8191` 静态读取；未实现、未跑 Godot。
- 切分：节名枚举声明全表；未知／`["*"]`／未局部路由的已声明名 → `render(view)` 全量；仅 `["body_bar"]` 不 `begin_frame`。禁止第二套刷新管线与独立 present 文件。
- Gherkin：`tests/display_ui_cases.gd::present_routes_body_bar_or_full`（待实现）。验收 UI **none**。档 2：未知／`["*"]` 不换 header；键命中仍重建 body_bar；生产带计数器 → 须红。
- 检查证据：仅静态读取 `render`／`_submit`／`body_sidebar` 键；Godot／测试／审查／清洁／加固均未验证，不报告通过；无产品源码、打包、发布或 push。
