# 清洁者报告：present(dirty) 第一刀 body_bar

checkpoint(cleaner): 范围与HEAD确认，零代码改动

域：本刀两文件增量（`ui/main.gd::present`／`PRESENT_SECTIONS`／`_present_needs_full_render`，`tests/display_ui_cases.gd::present_routes_body_bar_or_full`）。契约 `spire-godot/build/partition-delta-extract.md`，实现报告 `spire-godot/build/implementer-report.md`。简报要求 HEAD 起步 `ef7e231`；实际 HEAD `966b3e39`（分支 `worker/partition-delta`），相对 `ef7e231` 仅多 `checkpoint(implementer): record present body_bar display evidence`（只改 `implementer-report.md`）；`git diff 2bfa594..HEAD -- spire-godot/ui/main.gd spire-godot/tests/display_ui_cases.gd` 为空，源码与实现者跑检查时同指纹。`git status --short` 干净，无 untracked。独占 `C:\1\magic-spire-wt-partition-delta`。不当实现者／加固者；未改 `_submit`；未改 `game_layout.gd`／`body_sidebar._presentation_key`；无新 UI 文件；未拆 `main.gd`／`display_ui_cases.gd`；未 push；未暂存 `*.import`／`.uid`；未写 `docs/spec`。本报告覆写上一刀的 `cleaner-report.md`（旧 keywords 内容在 git 历史内可回溯）。本清洁零代码改动，按简报未重跑（消费实现者同指纹证据，见末块）。

checkpoint(cleaner): 无第二套刷新管线、无新 UI 文件，通过

域：`ui/main.gd` 展示调度（`render` 对 `present`）。`git diff a0ebd5c..HEAD --stat` 仅三文件：`implementer-report.md`、`ui/main.gd`（+21）、`tests/display_ui_cases.gd`（+92）；`git diff --name-only a0ebd5c..HEAD` 无新增 UI 文件。`git grep -n "func render|func present|_present_needs_full_render"` 全仓 UI 刷新仅 `main.gd::render`（399行）与 `main.gd::present`（490行）＋`_present_needs_full_render`（503行）；`core/torso_binding.gd::present(e)` 是装备绑定谓词（`binding.kind/durability` 判定），与 UI 刷新无关，不构成第二套管线。测试侧 `present_visible_slot_names`／`present_expected_slot_names` 只读 `ui.view`／节点可见性，`GetViewCountingGame` 只是 `get_view` 计数包装（生产无计数器，见空 snapshot 块），均不是刷新管线。`present` 内零 `preload`，无新 UI 文件边。结论：单刷新管线（`render` 全量＋`present` 薄入口复用），通过。

checkpoint(cleaner): `_submit` 未改接，通过

域：`ui/main.gd::_submit`（2090行）。`git diff a0ebd5c..HEAD -U0 -- spire-godot/ui/main.gd` 唯一增量是 488–507 行的 `PRESENT_SECTIONS`＋`present`＋`_present_needs_full_render`（+21行）；`Select-String "_submit|begin_frame|layout.used|get_view"` 在该 diff 内零命中。`_submit` 仍走 `game.dispatch`→`game.get_view`→`render(updated)`（2105–2127行），未改接 `present`，未改 `commit`／`present_rejection`。结论：提交路径不动，玩家路径仍整树 `render`，通过。

checkpoint(cleaner): `body_bar` 键仍只在 `_presentation_key`，通过

域：`ui/shell/body_sidebar.gd::_presentation_key`（109行）／`_slots_key`。`git grep -n "_presentation_key"` 仅命中 `body_sidebar.gd` 三处（109定义、135命中早退、207更新）；`git grep -n "_slots_key" -- spire-godot/ui/main.gd` 零命中——`main.gd` 未复制键计算。`main.gd` 仅有节名枚举 `PRESENT_SECTIONS: Array[String]`（15名与契约枚举逐字一致：header、relics、hand、actions、posture、resources、show_log、body_bar、body_details、pickers、speech、notice、drawers、page、scene_instances），其中 `body_bar` 只是路由字符串，不含键字段。`version` 未进键（键体为 size.y、locale、selected body id、expanded ids、regions `[id,name,count,members]`）。无第二套节键，无 CSS／样式引擎。结论：通过。

checkpoint(cleaner): 局部路径无 `begin_frame`、无清空 `layout.used`，通过

域：`ui/main.gd::present` 局部路径（495–501行）。局部路径为 `DragTargets.clear(self,false)`→`_hide_term`→非空 snapshot 才 `view=snapshot`→`layout.body_sidebar(self)`→`layout.end_frame`→`refresh_hints.call_deferred`→`_localize_controls`。`git grep -n "begin_frame" -- spire-godot/ui/main.gd` 唯一命中 422行（`render` 内）；`present` 内零 `begin_frame`。`git grep -n "layout.used" -- spire-godot/ui/main.gd` 零命中；`present` 内无 `.used.clear()`、无 `layout.used=`。契约风险假设（`end_frame` 误删 hero／body／敌人）已闭合：`used` 沿用上次 `render` 残留（含 hero／body／enemies），`body_sidebar` 再 `append(body)`，故 `end_frame`（`game_layout.gd` 59–70行）保留三者（hero 只切 visible、不释放；body／enemies 均 `in used`）；场景 401–402行显式断言 hero 可见、body 存活、enemies 全存活。附带观察：每次局部调用给 `used` 多加一个重复 `body` 引用（数组+1／次），对 `in` 判定无正确性影响；修它须改被禁的 `game_layout.gd`，故不碰。结论：通过。

checkpoint(cleaner): `present(["body_bar"])` 空 snapshot 不 `get_view`，通过

域：`present`／`render` 的 View 来源。生产 `git grep -n "get_view" -- spire-godot/ui/main.gd`：`game.get_view()` 仅 312行（初始化）、404行（`render` 空 snapshot 分支）、2106行（`_submit`）、2165行（另一初始化）；`present`（490–507行）内零 `get_view`。空 snapshot 时 `next=view`（当前非空 View）；`_present_needs_full_render` 对单 `body_bar` 返回假，走局部路径（无 `get_view`）；需全量时 `render(next)` 传入非空 `next`，`render` 内 `snapshot.is_empty()` 为假故不 `get_view`。View 为空的边界（`view.is_empty()`→全量→`render({})`→`get_view`）是无 View 可传时的正确兜底，不属契约“传入非空当前 View、禁止再 `get_view`”的违反。生产 `git grep -n "get_view_calls|GetViewCounting" -- spire-godot/ui/ spire-godot/core/ spire-godot/data/` 零命中——无生产计数器；计数器只在测试（`display_ui_cases.gd` 347–350行定义，五处 `==baseline` 断言）。测试每步后 `get_view_calls==baseline`（400／407／412／430／433行）即该性质的行为钉。结论：通过。

checkpoint(cleaner): 特别核——保留未类型化 `Array` 签名正确，不改回 `Array[String]`

域：`ui/main.gd::present(dirty: Array=["*"], snapshot: Dictionary={})` 相对契约 `Array[String]`。Godot 拒收未类型化数组字面量进 `Array[String]` 形参（`present(["body_bar"])` 会 SCRIPT ERROR）；实现者 `2bfa594` 切到未类型化 `Array` 正是修复该失败。元素仍按 `String(dirty[0])` 对照枚举（506行），枚举本体 `PRESENT_SECTIONS` 保持 `Array[String]`（488行），`has(section)` 以 `String` 查询，类型收窄点仍在。改回 `Array[String]` 会让契约 Gherkin 的字面量调用与所有 `present(["…"])` 调用方解析失败，属“为满足契约字面破坏运行”的改法，简报已明令不做。本清洁未动签名。结论：保留正确，通过。

checkpoint(cleaner): 场景 oracle 空调用评估——保留，不删

域：`tests/display_ui_cases.gd::present_routes_body_bar_or_full` 394–396行（`oracle=_presentation_key(ui)`＋键相等断言）。契约 Gherkin 明写 `Oracle＝body_sidebar._presentation_key(ui)`，删该行即偏离契约。该 check 非无敏感性空调用：它对“局部路径意外变异 `view`／`expanded_body_regions`”有独立敏感性（键变则红），而实例检查（header／wrist／scroll 同一性）不能完全替代键稳定性信号——键命中早退正是 `configure` 135–137行的行为前提，oracle 行把该前提钉在测试里。若关掉该单行，`configure` 键字段集被改（例如误读显示字段）时本步的直接信号丢失。且测试对 `_presentation_key` 仅读（oracle 比对），未改其字段集，符合“不得改字段集（除非同批证明 configure 新读显示字段）”。结论：保留，不删，通过。

checkpoint(cleaner): 依赖面 ⊆ 允许面，通过

域：本刀运行时依赖方向。`present` 调用的全部边均为既有边：`DragTargets.clear`（`render` 402行已有）、`_hide_term`、`layout.body_sidebar`（`main.gd` 1304行 `_body_drawer` 已有调用，仍是 M3→M5）、`layout.end_frame`（`render` 428／484行已有）、`keyboard_input.refresh_hints`（M3→M1，`render` 485行同式）、`_localize_controls`、`render`（全量回退）。无新增模块、无运行时依赖、无存档／schema、无 `present` 独立文件、无 `main`→core 新边、无新 `preload`。测试边：测试→`main.present`／`render`＋测试侧 `GetViewCountingGame`（`game_fixture` 包装），生产无计数器。若需新 UI 文件或新允许边则 `needs-human-review`——本刀均无。结论：依赖面 ⊆ 允许面，通过。

checkpoint(cleaner): 体积与门禁口径，不拆文件；检查器未建则报未建

域：体积与复杂度／依赖检查器。Godot 无 Size and ESM；项目 `AGENTS.md` 无 Size 条款，本刀不适用。`main.gd` 2950行、`display_ui_cases.gd` 717行本就超长，简报明令不拆（本刀只加薄入口：+21／+92行），本清洁未拆。`spire-godot/tools/` 仅 `check.ps1`（套件执行）／`check-docs.ps1` 等既有门禁；无钉住“present 边”的最小依赖检查器，无 GDScript 复杂度（CRAP）门禁；`tests/architecture_cases.gd` 的通用依赖断言不覆盖本刀 present 边。按简报报未建且不新建框架、不写 `docs/spec`。结论：无范围冲突。

checkpoint(cleaner): 验证与结论，本域已洁

域：本刀（`present(dirty)` 第一刀 `body_bar`）。本清洁零代码改动，按简报“未改代码则消费实现者同指纹证据，不重跑”：消费 `spire-godot/build/checks/20260925T075801868-39772/` 同指纹证据（源码自 `2bfa594` 未动，`before`＝`after`＝`602629A948CF16B6B1456D2331149DF2C86D0D1AEDC4EF888B73B0799480A0E9`，非 `source_changed`）：在 `spire-godot/` `$env:GODOT_BIN='C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'; & tools/check.ps1 -UIOnly -UISuite display -TimeoutSeconds 900`，退出码 0、`SUITE RESULT: display PASS`、`UI PASS: 260 assertions`（`check-ui.log`：UI SUITE 43233 ms）、`summary.json` `status=passed` 且指纹未变、docs PASS（35 docs，2412 refs）。`sidebar_refresh` 同套件未红。未运行项沿实现者报告：规则套件、其它 UI 套件、打包、加固变异（档 2）、验收（本刀 UI 验收 none）。结论：本域已洁，无清洁改动，无范围冲突；`*.import`／`.uid` 未暂存未提交，未 push。
