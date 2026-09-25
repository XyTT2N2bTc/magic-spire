# 清洁者报告：keywords 单次收集源码断言

checkpoint(cleaner): 范围与HEAD确认，零代码改动

域：`tests/card_text_cases.gd::card_text_func_body`／`card_text_func_call_count`／`card_keyword_deps_stable_ids`，生产 `data/card_text.gd` 应无 diff。契约 `spire-godot/build/keyword-deps-extract.md`，实现报告 `spire-godot/build/implementer-report.md`（HEAD `c056ecc` 内容）。HEAD 起步 `c056ecc` 与实际一致；工作树相对 HEAD 干净（`git status --porcelain` 空，`git diff --stat` 空）。独占 `C:\1\magic-spire-wt-keyword-deps`。不当实现者／加固者，不改生产 `keyword_ids`／`keywords`／`TERMS`，不改 `card_facts`／走查／UI，不写 `docs/spec`，不 push，不提交 `*.import`／`.uid`，不拆 `card_text_cases.gd`，不为 `static var TERMS` 加 seam。本报告覆写上一刀的 `cleaner-report.md`（旧内容在 git 历史内可回溯）。允许面内零代码改动，按简报未重跑 card_power（消费实现者同指纹证据，见末块）。

checkpoint(cleaner): 助手与 pipeline_lookup 重复评估——同文件仿写通过，无新模块新边

域：`tests/card_text_cases.gd::card_text_func_body`（77–88行）／`card_text_func_call_count`（90–99行）对 `tests/architecture_cases.gd::pipeline_lookup_func_body`（1988–2000行）／`pipeline_lookup_call_count`（2002–2011行）。两对助手同为“FileAccess 读源码→`find("func "+name+"(")` 切片→逐行去 `#` 注释→子串计数”模式，属本刀简报允许的同文件仿写。差异仅为目标文件（`res://data/card_text.gd` 对 `res://core/game.gd`）与切片哨兵（`rest.find("func ",1)` 对 `rest.find("\nfunc ",1)`），不构成抽共享模块的重复度。全仓 grep `card_text_func_body` 仅命中 `tests/card_text_cases.gd` 内三处（定义、调用、计数调用），无第二文件、无共享模块、无新增 preload 边。测试 preload 面未动（`Game`／`Book`／`Text` 三常量＋既有 `curse_cases.gd` 动态取牌），`core/card_effects.gd` 零 `card_text` 命中，`core/` 内 `card_text` 命中仅 `game.gd::live_card_text*` 函数名与 `game_view.gd::card_texts` 视图键，与模块 preload 无关。结论：重复度在允许面内，不建新模块。

checkpoint(cleaner): 切片未误切 keyword_ids 本体，通过

域：`data/card_text.gd::keywords` 切片。本地复算（`find("func keywords(")` 起，至下一 `func ` 止）：body 长 385 字节，正文为 `func keywords(...)`→`for id in keyword_ids(type,free,traits)`→`TERMS[id].duplicate`→超级顺延改名→`result.append`→`return`，尾部仅带下一 `static ` 前缀词。`body.count("func keyword_ids")==0`，`keyword_ids(` 计数为 1 且来自循环头唯一调用，切片未含 `keyword_ids` 函数定义体（该函数在 `keywords` 之前，相邻但不在切片内）。结论：切片边界正确。

checkpoint(cleaner): ids.append 未误伤 result.append，通过

域：同上 keywords body。本地计数：`ids.append` 为 0（断言要求的“无第二收集器”成立），`result.append` 为 1（投影追加仍在，未被误伤）。测试断言 `find("ids.append")<0` 与实现语义一致：`keywords()` 内唯一的追加是 `result.append(term)`，去重循环（`seen`/`unique`）在 `keyword_ids` 内，不在 `keywords()` 内。结论：无误伤。

checkpoint(cleaner): keyword_ids( 计数未计入签名或其它函数，通过

域：`card_keyword_deps_stable_ids` 首两断言。`card_text_func_call_count` 以子串 `name+"("` 计数；body 内签名是 `func keywords(`，needle 是 `keyword_ids(`，二者不相交，故签名不被计入。body 内无其它 `keyword_ids(`（本地计数==1），其它函数调用（`TERMS[id].duplicate`、`spec.get`、`Rules.SUPER_FOLLOW_THROUGH_TEXT` 读取）均不含该子串。被允许的显示读取 `Rules.SPECS[type]`／`follow_through_scope` 也不命中 needle。结论：`==1` 为真实单次调用断言，非计数口径污染。

checkpoint(cleaner): 无生产打点，生产无 diff，通过

域：`data/card_text.gd` 生产面。`git diff HEAD -- spire-godot/data/card_text.gd` 为空；`git status --porcelain`、`git diff --name-only`、`git diff --cached --name-only` 均为空（除本报告待提交外，核对时为空）。body 内 `print(`／`print_debug`／`push_warning`／`push_error` 计数均为 0；`TERMS` 声明仍为单处 `static var TERMS={`（`TERMS=` 赋值计数 1，无新增写点；`const TERMS` 零命中，符合协调者已驳回 P2、不为本刀加 seam／不回 const 的要求）。`keyword_ids`／`keywords`／`TERMS` 语义未动，`card_facts`／`game.gd`／UI 零差异。结论：生产面干净。

checkpoint(cleaner): 体积与门禁口径，不拆文件；检查器未建则报未建

域：体积与复杂度／依赖检查器。Godot 无 Size and ESM；项目 AGENTS.md 无 Size 条款，本刀不适用。触及文件 `tests/card_text_cases.gd` 203 行，未超长，按简报不拆 `card_text_cases.gd`（只加同文件助手，文件未超长）。`spire-godot/tools/` 仅 `check.ps1`（套件执行）／`check-docs.ps1`（文档引用）等既有门禁，无钉住“keywords 单次收集”边的最小依赖检查器；本域的门禁即测试内源码结构断言本身（`card_text_func_body`／`card_text_func_call_count`＋Gherkin 行为断言）。按简报报未建且不新建框架，不写 `docs/spec`。结论：无范围冲突。

checkpoint(cleaner): 验证与结论，本域已洁

域：本刀（keywords 单次收集源码断言）。本清洁零代码改动，按简报“未改代码则消费实现者同指纹证据，不重跑”：消费 `523275a`→`c056ecc` 链上的同指纹证据（工作树与 HEAD 一致，允许面两文件 `git diff HEAD --` 为空）：`spire-godot/` `$env:GODOT_BIN='C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'; & tools/check.ps1 -Suite card_power -TimeoutSeconds 600`，Exit 0、`SUITE RESULT: card_power PASS`、`PASS: 2297 assertions`（`check-rules.log` 末行）、`spire-godot/build/checks/20260925T071208916-32260/summary.json` status `passed` 且 before==after（`B294C017...`，非 `source_changed`），docs PASS（35 docs，2412 refs）。既有 TERMS／COPY 断言同次绿。未运行项沿实现者报告：architecture／UI／加固变异（档 2）未跑；UI 验收 none。结论：本域已洁，无清洁改动，无范围冲突；`*.import`／`.uid` 未暂存未提交，未 push。
