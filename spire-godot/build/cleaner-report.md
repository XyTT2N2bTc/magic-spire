# 清洁者报告：keyword_ids 稳定 ID 抽取

checkpoint(cleaner): 范围与HEAD确认，零代码改动

域：`data/card_text.gd::keyword_ids`／`keywords`、`tests/card_text_cases.gd::card_keyword_deps_stable_ids`。契约：`spire-godot/build/keyword-deps-extract.md`（无新模块、无新允许边，不标 needs-human-review）。HEAD 起步 `36c55e8` 与实际一致；工作树相对 HEAD 干净（`git status --short` 与 `git diff --stat` 均为空，实现提交 `d921ab6` 已在 HEAD 内）。独占 `C:\1\magic-spire-wt-keyword-deps`。不当实现者／加固者，不改 `card_facts`／走查／UI，不写 `docs/spec`，不 push，不提交 `*.import`／`.uid`，不拆超长无关文件。允许面内零代码改动，按简报未重跑 card_power（消费实现者同指纹证据，见末块）。本报告覆写前一切片的 `cleaner-report.md`（旧内容已在 git 历史内，可回溯）。

checkpoint(cleaner): ids 只收集一次且 keywords() 调用它，通过

域：`data/card_text.gd::keyword_ids`（87–121行）与 `keywords`（123–132行）。`keyword_ids` 持有全部 ids 走查（`unique_face`、`traction`、`drinking`、`hannya`、`innate`／`ethereal`、`exhaust_hand`、施法 parts／`hand_use`、`face_mode`、`follow_through`、`self_faces` 的 effects／buff／`charge`／`exhaust`／`mouth_clear`／`upper_clear`、else 分支各效果键、`power`、`exhausts`、`auto_retain`、`levels`），首次出现去重后返回。`keywords()` 不再走 SPECS／效果，仅 `for id in keyword_ids(type,free,traits)` 再 `TERMS[id].duplicate(true)`，附原有的超级顺延改名（`follow_through_scope=="body"` 时改 `name`／`detail`，同一 id）。`keywords()` 内的 `var spec=Rules.SPECS[type]` 是抽取前即有的单字段显示读取（仅判 `follow_through_scope`），不是第二遍 ids／SPECS／效果扫描；去重循环只是原逻辑改名（`result`→`unique`），语义与顺序未动（diff `d921ab6` 为证）。

checkpoint(cleaner): 无第二份 TERMS、无平行 SPECS 扫描，通过

域：TERMS 单一性与收集路径唯一性。卡牌 TERMS 仅 `data/card_text.gd` 一处（现 `static var TERMS`，见下块评估）。`data/glossary.gd::TERMS` 是敌方计划术语域（值为 String，键为 `turn_install`／`install`／`capture` 等），形状与键空间均不同，不是卡牌 TERMS 副本。`data/tutorial.gd` 仅 `preload("res://data/card_text.gd").TERMS[id]` 只读取用（既有消费者，未动）。`_effect_terms`／`_buff_terms` 为共享 helper，只被 `keyword_ids` 路径调用一次；`keywords()` 不另起第二套收集。测试侧读写 `Text.TERMS` 仅为契约规定的改名—恢复（见下块），无抄表。

checkpoint(cleaner): face_keywords 未被加上 id，通过

域：`data/card_text.gd::metadata`（173行）`face_keywords[side]=keywords(...)`；`keywords()` 追加的是 `TERMS[id].duplicate` 后的 `{name,detail}`，未写 `id` 键，TERMS 条目形状未动。测试侧逐条断言 `term.has("name") and term.has("detail") and not term.has("id")`，且 `pot.face_keywords.bound==[Text.TERMS.exhaust]` 字面比较保持。`metadata`／`face_keywords` 集合与顺序无变化。

checkpoint(cleaner): 无 card_effects→card_text 新边，通过

域：本刀依赖方向。`core/card_effects.gd` 头部 preload 仅 `Rules`／`Splash`／`Hannya`／`SelfBinding`，`core/` 内 grep `preload.*card_text` 零命中（唯一含 `card_text` 的是 `game_view.gd` 的 `card_texts` 视图键，与模块无关）。方向仍是契约允许的 `card_text`→`card_rules.SPECS`／`TERMS`、测试→`card_text` 公开函数；`card_facts` 未消费 `keyword_ids`（`card_effects.gd` 本刀零差异），无新模块、无新边。静态 preload 方向检查器未建：`spire-godot/tools/` 仅 `check.ps1`（套件执行）／`check-docs.ps1`（文档引用）等既有门禁，无钉住本边的最小依赖检查器，按简报报未建且不新建（`tools/` 在允许面外）。

checkpoint(cleaner): const TERMS 改 static var TERMS 评估——保留，不改

域：`data/card_text.gd` 第 5 行。本刀唯一的生产形状变化就是 `const TERMS`→`static var TERMS`（diff `d921ab6`）。契约 Gherkin 明确要求“把 `TERMS.strain/follow_through/exhaust.name` 改成非原文，重调 `keyword_ids`（测后恢复）”；实现者证据载明在 Godot 4.7 下直接改 const 字典经历两次解析／运行时失败（`20260925T064327924-39996`、`20260925T064452659-31440`，非通过），故 static var 是契约＋引擎共同所迫。评估替代项：①改回 const——则契约规定的改名验证无法执行，属单方撕约，不取；②测试用副本改名——`keyword_ids` 读的是全局 TERMS，改副本证明不了全局无关性，证明力丢失，且会改测试实现、不取；③给 `keyword_ids` 注入 TERMS 参数——改接口、扩允许面，契约禁止，不取。风险已核：全仓 grep `TERMS=` 赋值零命中（仅声明＋`has` 读取＋`duplicate` 投影＋测试改名／恢复两处）；生产代码只读不写，`static var` 的重赋值能力无人使用。文件头 `# Read-only card wording` 注释是模块级描述且生产路径仍只读，按清洁者“不为可读性加注释”不改。无新增 validation（去重 `if id not in seen` 是原逻辑，原有“每面无重复词条”断言即其敏感性证明），故无“无敏感性 validation”可删。

checkpoint(cleaner): 体积与门禁口径，不拆文件

域：体积与复杂度门禁。项目 AGENTS.md 无 Size and ESM 条款（实现者已核），本切片不适用；触及文件 `data/card_text.gd` 176 行、`tests/card_text_cases.gd` 176 行，均远低于 500，无 ESM 漏斗穿透（无新增 preload／跨层直引），按简报不拆任何文件。本清洁零代码改动，按简报条件（“改了代码则跑”）未重跑 `card_power`。

checkpoint(cleaner): 验证与结论，本域已洁

域：本刀（keyword_ids 抽取）。消费实现者同指纹证据（工作树源码与 HEAD 一致，`git diff HEAD --` 允许面两文件为空）：`spire-godot/` `$env:GODOT_BIN='C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'; & tools/check.ps1 -Suite card_power -TimeoutSeconds 600`，Exit 0、`SUITE RESULT: card_power PASS`、`PASS: 2295 assertions`、`spire-godot/build/checks/20260925T064606091-5292/summary.json` status `passed` 且 before==after（非 `source_changed`），docs PASS（35 docs，2412 refs）。Gherkin `card_keyword_deps_stable_ids` 已在 `run` 注册，覆盖七钉牌双面 ids／slots／mode、TERMS 改名后不变、快照／rng 冻结；既有 TERMS／COPY 断言同次绿。未运行项沿实现者报告：architecture／UI／加固变异（档 2）未跑；UI 验收 none。结论：本域已洁，无清洁改动，无范围冲突；`*.import`／`.uid` 未提交，未 push。
