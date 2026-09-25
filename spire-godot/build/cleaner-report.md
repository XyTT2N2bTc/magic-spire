# 清洁者报告：present(dirty) 第二刀 header

checkpoint(cleaner): 范围与HEAD确认，本刀补最小邻接表后重跑通过

域：本刀三处源码增量（`ui/main.gd::present`／`_present_needs_full_render`，`ui/shell/header.gd::_presentation_key`／`configure`，`tests/display_ui_cases.gd::present_routes_header_or_full`）。契约 `spire-godot/build/partition-delta-2-extract.md`，实现报告 `spire-godot/build/implementer-report.md`。简报要求 HEAD 起步 `54255c4`；实际 HEAD 即 `54255c4`（分支 `worker/partition-delta`，`git status` 起步干净）。独占 `C:\1\magic-spire-wt-partition-delta`。不当实现者／加固者；未改 `_submit`；未改 `header.tscn`／`game_layout.gd`／`body_sidebar._presentation_key`；无新 UI 文件；未拆 `main.gd`／`display_ui_cases.gd`；未 push；未暂存 `*.import`／`.uid`；未写 `docs/spec`。本报告覆写第一刀的 `cleaner-report.md`（旧内容在 git 历史内可回溯）。本刀相对实现者有一处清洁改动：`main.gd` 在 `PRESENT_SECTIONS` 旁补已声明邻接表 `PRESENT_ADJACENCY`（简报必做项，实现未交，表缺失即未洁）；改后按简报重跑 display 套件（见末块），不消费实现者旧指纹。

checkpoint(cleaner): 无第二套刷新管线、无新 UI 文件，通过

域：`ui/main.gd` 展示调度（`render` 对 `present`）。`git diff cd3b2e6..HEAD --name-only` 仅四文件：`build/implementer-report.md`、`tests/display_ui_cases.gd`、`ui/main.gd`、`ui/shell/header.gd`，无新增文件。全仓 UI 刷新仍仅 `main.gd::render`（全量）与 `main.gd::present`（薄入口复用）＋`_present_needs_full_render`（谓词）；`core/torso_binding.gd::present` 是装备绑定谓词，与 UI 刷新无关。`present` 内零 `preload`、零 `instantiate`、零 `_header()` 调用、零 `_relic_row`，无新 UI 文件边。`["header"]` 局部只对已有 `GameHeader` 调 `configure`，`["body_bar"]` 仍走 `layout.body_sidebar`，其余已声明名／未知／`["*"]`／`dirty.size()!=1`／View 空／layout 空／无 `GameHeader` 均回 `render`。结论：单刷新管线，通过。

checkpoint(cleaner): `_submit` 未改接，通过

域：`ui/main.gd::_submit`。本刀 `main.gd` 增量仅 `present` 节路由分支、`_present_needs_full_render` 的 `header` 存在性探针，以及本次清洁补的 `PRESENT_ADJACENCY` 声明；该 diff 内零命中 `_submit`／`commit`／`present_rejection`。`_submit` 仍走 `game.dispatch`→`game.get_view`→`render`，未改接 `present`。结论：提交路径不动，玩家路径仍整树 `render`，通过。

checkpoint(cleaner): header 键只在 `header.gd` 且字段集 ⊆ 契约节键表，通过

域：`ui/shell/header.gd::_presentation_key`／`configure`／`_key`／`_clear_buttons`。全仓 `_presentation_key` 定义仅两处：`body_sidebar.gd`（body 域）与 `header.gd`（本域）；`main.gd` 零命中（未复制键计算、未自算键跳过）。`header._presentation_key` 返回 17 元纯数据（`run_header` 四元、`security`、`wall`、`wall_position.distance`、`pressure.overloaded`、`carried_items`、`capacity`、`deck_count`、`prison.active`、`phase`、`practice`、`show_route`、`save_failed`、locale），与契约 `header` 行逐项对应，`version` 未进键，不存旧 View／候选／装备图／节点引用。`configure` 开头命中早退、未命中先 `_clear_buttons` 再建模、末尾写回 `_key`（两次 `present(["header"])` 与改 `security` 后 `Button` 件数均＝6 的行为钉在场景里）。结论：通过。

checkpoint(cleaner): `body_bar` 键仍只在 `body_sidebar._presentation_key`，通过

域：`ui/shell/body_sidebar.gd::_presentation_key`／`_slots_key`。本刀未改该文件（`--name-only` 无它）；`_presentation_key` 定义／命中早退／更新仍仅该文件三处。附带观察：本刀测试把 `present_routes_body_bar_or_full` 的首步 oracle 由相等断言改为丢弃调用（`ui.layout.body._presentation_key(ui)` 单行），该行零敏感性变化不影响本域结论（键位置未动），是否恢复相等断言交回规划者定夺，本清洁不碰测试语义。结论：通过。

checkpoint(cleaner): `present` 签名仍为未类型化 `Array` 且必须调 `configure`，通过

域：`ui/main.gd::present`。签名保持 `present(dirty: Array=["*"], snapshot: Dictionary={})`，未改回 `Array[String]`（Godot 拒收未类型化字面量进 `Array[String]`，改回会使全部 `present(["…"])` 调用解析失败）。元素仍以 `String(dirty[0])` 对照 `PRESENT_SECTIONS` 枚举。`["header"]` 分支直接 `layout.get_node("GameHeader").configure(self)`，无条件调用，无自算键跳过。结论：通过。

checkpoint(cleaner): 局部无 `begin_frame`、无清空 `layout.used`，通过

域：`ui/main.gd::present` 局部路径。局部固定序：`DragTargets.clear`→`_hide_term`→非空 snapshot 才替换 `view`→节动作（`header.configure` 或 `layout.body_sidebar`）→`layout.end_frame`→`refresh_hints.call_deferred`→`_localize_controls`。`present` 与 `_present_needs_full_render` 内零 `begin_frame`（全仓仅 `render` 内一次）、零 `layout.used`／`.used.clear()`、零 `header.tscn` 二次实例化。`_present_needs_full_render` 对 `header` 仅探针 `GameHeader` 存在性，不调 `configure`，无 `GameHeader` 时回全量。结论：通过。

checkpoint(cleaner): 叠按钮计数用 `Button` 件数，通过

域：`tests/display_ui_cases.gd::present_header_button_count`。实现为 `header.find_children("*","Button",true,false).size()`，非精确名 `OpenTutorial` 件数（Godot 重名改 `OpenTutorial2`，精确名计数漏叠）。场景基线／两次命中／改 `security` 未命中后三次断言件数＝6，且 `OpenTutorial` 实例保持、地图键（`OpenMap` 与 `OpenPrisonTutorial` 合计 1）、`RelicStrip` 件数不增。结论：通过。

checkpoint(cleaner): 依赖面 ⊆ 允许面，通过

域：本刀运行时依赖方向。`present` 新增边仅 `header.configure`（仍是 M3→M5，与既有 `layout.body_sidebar` 同向）与 `_present_needs_full_render` 内 `GameHeader` 存在性探针；其余均为既有边（`render` 回退、`DragTargets.clear`、`end_frame`、`refresh_hints`、`_localize_controls`）。`header.configure` 内仅读 View／本地态＋调 `ui` 既有构件（`_style`／`_button`／`_place`／`_open_tutorial`／`_open_drawer`），无新模块、无运行时依赖、无存档／schema、无 `present` 独立文件、无 `main`→core 新边。测试边：测试→`main.present`／`render`＋测试侧 `GetViewCountingGame`（生产 `ui` 内零计数器命中）。结论：通过。

checkpoint(cleaner): 邻接表已补且表源一致，通过

域：本刀 `present` 路由。简报必做：声称单路径必须有已声明邻接表。实现未交表（全仓无 `PRESENT_ADJACENCY`／邻接表声明，全文搜索与实现者报告不是表），本清洁在允许面内补最小表：`main.gd` 紧随 `PRESENT_SECTIONS` 的 `PRESENT_ADJACENCY` 常量，边＝稳定符号。声明边：`present`→`_present_needs_full_render`／`render`／`header.configure`／`layout.body_sidebar`，`header.configure`→`header._presentation_key`，其余三节点（`_present_needs_full_render` 谓词、`header._presentation_key` 纯读、`layout.body_sidebar`／`render` 本域边界叶）出边为空。表源双向核对：声明五边在源码均有直接调用对应（`present` 内路由四分支、`configure` 开头比对与末尾写回）；源码本域直接调用无表外边（`present` 内无第二套键计算、无 `_header`／`_relic_row`／`begin_frame`）。未新开模块，未写 `docs/spec`。结论：已洁。

checkpoint(cleaner): 体积与门禁口径，不拆文件；检查器未建则报未建

域：体积与复杂度／依赖检查器。Godot 无 Size and ESM；项目 `AGENTS.md` 无 Size 条款。`main.gd`、`display_ui_cases.gd` 本就超长，简报明令不拆（本刀实现薄路由＋场景，清洁仅加声明表约十行），本清洁未拆。`spire-godot/tools/` 仅套件执行与文档门禁，无钉住 present 边的最小依赖检查器，无 GDScript 复杂度门禁；本次补的 `PRESENT_ADJACENCY` 即该域的最小声明表，按简报不新开框架。结论：无范围冲突。

checkpoint(cleaner): 验证与结论，本域已洁

域：本刀（`present(dirty)` 第二刀 `header`）。本清洁改了代码（邻接表声明），按简报重跑而非消费旧指纹。在 `spire-godot/` 运行 `$env:GODOT_BIN='C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'; & tools/check.ps1 -UIOnly -UISuite display -TimeoutSeconds 900`：退出码 0、`SUITE RESULT: display PASS`、`UI PASS: 292 assertions`、`summary.json` `status=passed` 且 `before`＝`after`＝`3B3E1FFACC673276F6C0409FA4DE1CE889FC303C6F3921015E45172C031B9B93`（非 `source_changed`；指纹与实现者 `FB06…` 不同系因本刀补表，属预期内单次变化）、docs PASS（35 docs，2412 refs）。日志 `spire-godot/build/checks/20260925T091056354-40004/`。`present_routes_body_bar_or_full`／`sidebar_refresh` 同套件未红。未运行项：规则套件、其它 UI 套件、打包、加固变异（档 2）、验收（本刀 UI 验收 none）。结论：本域已洁；`*.import`／`.uid` 未暂存未提交，未 push。
