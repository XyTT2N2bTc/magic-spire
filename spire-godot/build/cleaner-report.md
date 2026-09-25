# 清洁者报告：present(dirty) 第三刀 relics

checkpoint(cleaner): 范围与 HEAD 确认，本刀零代码改动只交报告

域：本刀三处源码增量（`ui/main.gd::present`／`_present_needs_full_render`／`PRESENT_ADJACENCY`／`_relic_row`／`_relic_presentation_key`，`tests/display_ui_cases.gd::present_routes_relics_or_full` 及 `present_routes_header_or_full` 步⑥改 `["hand"]`）。契约 `spire-godot/build/partition-delta-3-extract.md`，实现报告 `spire-godot/build/implementer-report.md` 文首第三刀。简报要求 HEAD 起步 `c495ab4`；实际 HEAD 即 `c495ab4`（分支 `worker/partition-delta`，起步 `git status` 干净，`3525cc0..c495ab4 --name-only` 仅三文件：`build/implementer-report.md`、`tests/display_ui_cases.gd`、`ui/main.gd`）。独占 `C:\1\magic-spire-wt-partition-delta`。不当实现者／加固者；未改 `_submit`；未改 `header.gd`／`header.tscn`／`game_layout.gd`／`relic_icon.gd`／`body_sidebar._presentation_key`；无新 UI 文件；未拆 `main.gd`／`display_ui_cases.gd`；未 push；未暂存 `*.import`／`.uid`；未写 `docs/spec`；未把协调者简报扫进提交。本报告覆写第二刀的 `cleaner-report.md`（旧内容在 git 历史内可回溯）。本刀源码已洁，零代码改动，消费实现者同指纹证据，不重跑（见末块）。

checkpoint(cleaner): 无第二套刷新管线、无新 UI 文件，通过

域：`ui/main.gd` 展示调度（`render` 对 `present`）。`3525cc0..c495ab4 --name-only` 仅上述三文件，无新增文件。全仓 UI 刷新仍仅 `main.gd::render`（全量，唯一 `begin_frame` 持有者）与 `main.gd::present`（薄入口复用）＋ `_present_needs_full_render`（谓词）；`core/torso_binding.gd::present` 是装备绑定谓词，与 UI 刷新无关。`present` 内零 `preload`、零 `instantiate`，`["relics"]` 局部只调 `_relic_row`，`["header"]` 仍只调已有 `GameHeader` 的 `configure`，其余走 `layout.body_sidebar` 或回 `render`。结论：单刷新管线，通过。

checkpoint(cleaner): `_submit` 未改接，通过

域：`ui/main.gd::_submit`。本刀 `main.gd` 增量仅 `present` 的 `relics` 分支、`_present_needs_full_render` 的 `relics` 存在性放行、`PRESENT_ADJACENCY` 的 `_relic_row` 边、`_relic_presentation_key` 与 `_relic_row` 键＋早退＋不叠条带；该 diff 内零命中 `_submit`／`commit`／`present_rejection`。`_submit` 仍走 `game.dispatch`→`game.get_view`→`render(updated)`，未调 `present`；`present` 全路径零 `game.get_view`（`get_view` 仅 `render` 空 snapshot 分支与 `_submit` 内）。结论：提交路径不动，玩家路径仍整树 `render`，通过。

checkpoint(cleaner): relics 键只在 `main.gd` 的 `_relic_row` 旁且字段集 ⊆ 节键表，通过

域：`ui/main.gd::_relic_presentation_key`／`_relic_key`／`_relic_row`。全仓 `_relic_presentation_key`／`_relic_key` 命中仅 `main.gd`（定义紧挨 `_relic_row`、键读取、命中比对、未命中写回），未进 `relic_icon.gd`，无第二处复制。键＝纯数据副本（每件 `id`／`name`／`detail`／`counter` 深复制／`current`／`rarity` ＋ locale 的 Array），不存旧 View／候选／装备图／节点引用；`version` 未进键；`TargetQueries.find` 的放电／切换事实不进键。键字段覆盖 `_relic_row` 实际读取的显示字段：`RelicShortcut_<id>` 建模读 `id`，悬停条目读 `name`／`detail`（`rarity_name` 由 `rarity` 派生，键存 `rarity` 即可）／`counter.detail`／`current`，`RelicCounter` 文本读 `counter.text`（键存深复制 `counter`），locale 覆盖末尾 `_localize_controls`。`_relic_row` 新读显示字段同批进键的约束本刀满足（diff 内无表外新读字段）。结论：通过。

checkpoint(cleaner): `header`／`body_bar` 键仍只在各自 `_presentation_key`，通过

域：`ui/shell/header.gd::_presentation_key` 与 `ui/shell/body_sidebar.gd::_presentation_key`。`3525cc0..c495ab4` 未碰 `header.gd`／`body_sidebar.gd`（该两路径 diff 为空）；全仓 `_presentation_key` 定义仍仅该两处，`main.gd` 零自建 header/body 键计算（仅声明边 `header.configure→header._presentation_key`，无求值复制）。测试侧 oracle 读取（`header._presentation_key`、`layout.body._presentation_key` 相等断言）是只读探针，非定义复制。结论：通过。

checkpoint(cleaner): `present` 签名仍为未类型化 `Array`，通过

域：`ui/main.gd::present`。签名保持 `present(dirty: Array=["*"], snapshot: Dictionary={})`，未改回 `Array[String]`（Godot 拒收未类型化字面量进 `Array[String]`，改回会使全部 `present(["…"])` 调用解析失败）。元素仍以 `String(dirty[0])` 对照 `PRESENT_SECTIONS` 枚举；`dirty.size()!=1` 仍全量。结论：通过。

checkpoint(cleaner): 局部无 `begin_frame`、无清空 `layout.used`、无 `_header`，通过

域：`ui/main.gd::present` 局部路径。`present` 函数体内零 `begin_frame`（全仓仅 `render` 内一次）、零 `layout.used`（全仓零命中）、零 `_header()` 调用（`_header()` 仅 `render` 内一次；`present` 的 `relics` 分支直调 `_relic_row`，`header` 分支直调已有 `GameHeader.configure`）。局部固定序仍为 `DragTargets.clear`→`_hide_term`→非空 snapshot 才替换 `view`→节动作→`layout.end_frame`→`refresh_hints.call_deferred`→`_localize_controls`。`_present_needs_full_render` 对 `relics` 仅放行（`section!="body_bar" and section!="relics"` 为假即局部），不探针条带存在性；layout 空／View 空仍全量。结论：通过。

checkpoint(cleaner): 叠条用 `RelicStrip`／同 id `RelicShortcut_*` 件数，空 relics 卸条，通过

域：`ui/main.gd::_relic_row` 与 `tests/display_ui_cases.gd::present_routes_relics_or_full`。键命中早退保留 `RelicStrip` 与已有 `RelicShortcut_*` 实例；键未命中先 `remove_child`＋`queue_free` 再建模；空 `view.relics` 写回键后直接返回（卸已有条）。全量 `_header`→`_relic_row` 仍写回键，但早退另要求条带仍在树上（`view.relics` 空或 `strips` 非空），`begin_frame` 释放后即使键相同也重建，不丢条带。场景断言：两次 `present(["relics"])` 后 `RelicStrip` 实例保留、树内恰 1 个、同名 `RelicShortcut_*` 实例保留且件数＝1；改 `counter` 后条带已换仍恰 1；`["header"]`／`["body_bar"]` 后条带实例保留；空 relics 后 `RelicStrip` 件数＝0 且 `GameHeader` 保留。结论：通过。

checkpoint(cleaner): 邻接表已扩 `_relic_row` 且表源一致，通过

域：本刀 `present` 路由。简报必做：声称单路径必须有已声明邻接表。实现已交表（`PRESENT_ADJACENCY` 紧随 `PRESENT_SECTIONS`，边＝稳定符号），本清洁逐边复核未再改表。声明边：`present`→`_present_needs_full_render`／`render`／`header.configure`／`_relic_row`／`layout.body_sidebar`，`header.configure`→`header._presentation_key`，`_relic_row`→`_relic_presentation_key`，其余四节点（谓词、两键纯读、`layout.body_sidebar`／`render` 本域边界叶）出边为空。表源双向核对：声明七边在源码均有直接调用对应（`present` 内路由五分支、`header.configure` 开头比对与末尾写回、`_relic_row` 开头读键）；源码本域直接调用无表外路由边（`present` 内无第二套键计算、无 `_header`／`begin_frame`；`_relic_row` 内既有帮手 `find_children`／`_place`／`TargetQueries.find`／`command_router.emit` 均为刀前已存在的基础设施边，非本刀路由边，与第二刀 `header.configure` 省略 `_style`／`_button` 边同口径）。未新开模块，未写 `docs/spec`。结论：已洁。

checkpoint(cleaner): 依赖面 ⊆ 允许面，通过

域：本刀运行时依赖方向。`present` 新增边仅 `_relic_row`（仍 M3 内部，与既有 `header.configure`／`layout.body_sidebar` 同层）；`_relic_row` 内 `preload relic_icon.gd`／`TargetQueries.find`／`command_router.emit` 均为刀前上下文行（diff 非 `+` 行），无新增模块、无运行时依赖、无存档／schema、无 `present` 独立文件、无 `main`→core 新边、无 UI 文件。`PRESENT_SECTIONS` 未新增节名（`relics` 本就已声明，本刀只放行局部）。测试边：测试→`main.present`／`render`＋测试侧 `GetViewCountingGame`（生产 `ui` 内零 `get_view_calls` 命中）；`present_routes_header_or_full` 步⑥由 `present(["relics"])` 改为已声明非局部的 `["hand"]`，`present_routes_relics_or_full` 已在 `run` 内接在 header 场景之后。结论：通过。

checkpoint(cleaner): 体积与门禁口径，不拆文件；检查器未建则报未建

域：体积与复杂度／依赖检查器。Godot 无 Size and ESM；项目 `AGENTS.md` 无 Size 条款。`main.gd`、`display_ui_cases.gd` 本就超长，简报明令不拆（本刀薄路由＋键＋场景，未为凑行数拆新模块），本清洁未拆。`spire-godot/tools/` 仅套件执行与文档门禁，无钉住 present 边的最小依赖检查器，无 GDScript 复杂度门禁；本域最小声明表即 `PRESENT_ADJACENCY`（实现已交，本清洁只复核），按简报不新开框架。结论：无范围冲突，检查器记为未建。

checkpoint(cleaner): 验证与结论，本域已洁

域：本刀（`present(dirty)` 第三刀 `relics`）。本清洁零代码改动，按简报消费实现者同指纹证据，不重跑。在 `spire-godot/build/checks/20260925T110904852-31036/`：退出码 0、`SUITE RESULT: display PASS`、`UI PASS: 331 assertions`（`check-ui.log`：`UI SUITE display: 331 assertions`）、`summary.json` `status=passed` 且 `before`＝`after`＝`B749E320F29F2AE56EC7555823E2717FDB7C97DC68AFA750589B95EFE8542A69`（非 `source_changed`；docs PASS，35 docs，2412 refs）。`present_routes_body_bar_or_full`／`present_routes_header_or_full`／`sidebar_refresh` 同套件未红（同指纹套件内）。未运行项：规则套件、其它 UI 套件、打包、加固变异（档 2）、验收（本刀 UI 验收 none）。结论：本域已洁；`*.import`／`.uid` 未暂存未提交，未 push。心跳见 `spire-godot/build/agent-cleaner-partition-delta-3.log`。
