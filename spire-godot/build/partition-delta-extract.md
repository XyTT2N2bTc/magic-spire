# 规划者契约：present(dirty) 第一刀（body_bar 路由）

状态：可交协调者；**无新模块、无新允许边**，不标 `needs-human-review`。通宵已授权落地既有 `present(dirty)`／节键，不新写 CSS／样式引擎。HEAD `12c8191` 静态切片，未实现、未运行。域：`ui/main.gd` 的 M3 展示调度（现行 `render`／`_refresh_drawers`）加 `present`；节重建只复用既有 `layout.body_sidebar` → `body_sidebar.configure`／`_presentation_key`／`_slots_key`。本刀不改 `_submit`、不做 `commit`／`present_rejection`、不整表落地场景 1–9。

## 已有入口（扩展，不建第二套刷新管线）

- 现行落地：`ui/main.gd::render(snapshot={})`（空 snapshot 才 `get_view`）与 `_submit` 成功／被拒后的 `render(updated)`。`_header` 每次 `instantiate` `header.tscn`（节点名 `GameHeader`）。`_body_drawer` → `game_layout.body_sidebar` → `body_sidebar.configure`。
- 既有跳过重建：`body_sidebar._presentation_key(ui)`／`_slots_key`（键命中保留按钮与滚动）。`tests/display_ui_cases.gd::sidebar_refresh` 已钉 `render(ui.view)` 下身体栏实例／滚动保留。`header.configure` **没有**键，全量 `render` 必换 `GameHeader`。
- **没有** `present`／`commit`／`present_rejection`／通用脏节表。禁止第二套 `render`、禁止新 UI 文件、禁止新 CSS 引擎。`ActionIndex` 已删（R5），本刀不恢复。

## 切分、接口和依赖

- 只在既有 M3（`ui/main.gd`）增加 `present(dirty: Array[String] = ["*"], snapshot: Dictionary = {}) -> void`。`dirty` 元素来自节名枚举或 `"*"`。空 snapshot 用当前 `ui.view`，**禁止** `get_view`；非空 snapshot 原子替换 `ui.view`，**禁止**再 `get_view`。全量兜底走既有 `render(view)`（传入当前／已替换 View，保持「空 snapshot 才 get_view」只属于 `render`）。
- 节名枚举（声明、不实现全部键）：`header` `relics` `hand` `actions` `posture` `resources` `show_log` `body_bar` `body_details` `pickers` `speech` `notice` `drawers` `page` `scene_instances`。本刀**唯一**局部路由：`dirty` 规范化后恰为 `["body_bar"]` 且 `layout` 已实例化、View 非空 → 不 `begin_frame`（否则会拆掉 `GameHeader`），顺序：`DragTargets.clear(self,false)` → `_hide_term` → View 同步 → `layout.body_sidebar(self)`（内部仍用 `_presentation_key` 跳过）→ `layout.end_frame()` → `keyboard_input.refresh_hints`（`call_deferred`）→ `_localize_controls`。不得另写身体栏重建体。
- 显式全量（不得靠「没键就重画」）：`dirty` 缺项／含 `"*"`／含枚举外未知名／含本刀未局部路由的已声明名／`layout` 未实例化／View 为空。本刀不落地其余兜底清单（phase／locale／显示设置等）。
- 允许实现面：`spire-godot/ui/main.gd` 的 `present`＋节名枚举＋上述路由；`spire-godot/tests/display_ui_cases.gd` 单个具名场景／`run` 注册。不得改 `body_sidebar.gd` 键算法、不得改 `_submit`／`commit`／`present_rejection`、不得新 UI 文件、不得 preload 新边。允许方向仍为 `M3 → M5 body_sidebar`（已有）、测试 → `present`／`render`。`main.gd` 已远超行数线；按契约不新增 UI 文件，本刀只在该文件加薄入口。若实现要新模块、新允许边、或把 `present` 抽到独立文件 → `needs-human-review` 并停下。
