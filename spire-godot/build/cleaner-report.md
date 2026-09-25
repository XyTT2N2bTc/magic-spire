# 清洁者报告：card_facts 消费 has_targets_at

checkpoint(cleaner): 范围与HEAD确认，无清洁改动

域：`core/card_effects.gd::card_facts` 槽循环、`tests/architecture_cases.gd::card_facts_consumes_has_targets_at`、`core/game.gd::has_targets_at`／`_visit_targets_at` 只读核对。契约：`spire-godot/build/card-facts-consume-extract.md`（切分已批，允许边 `card_facts` → `has_targets_at`，协调者 2026-09-25 记录）。HEAD 起步 `bbbd6f3` 与实际一致（`git rev-parse HEAD` 为 `bbbd6f3`）；工作树相对 HEAD 仅 `spire-godot/build/card-facts-consume-extract.md` 脏（规划者状态改写，已批 vs needs-human-review 两行），`git diff HEAD -- spire-godot/core/game.gd spire-godot/core/card_effects.gd spire-godot/tests/architecture_cases.gd --stat` 为空，实现提交 `2ee7bc7` 已在 HEAD 内。不当实现者／加固者，不改走查，不 push，不提交 `*.import`／`.uid`，不拆超长既有文件，不把该脏提取物扫进本提交（本提交只加本报告）。

checkpoint(cleaner): 谓词只在声明槽 targets_at 前通过

域：`core/card_effects.gd::card_facts` 槽循环（933–946行）。`not declared` 分支（937–939行）永不调 `targets_at`（特殊／`bound_modes`／`occupied` 则 `continue`，否则 `targets=[{}]`）；`declared` 分支（940–946行）先问 `g.has_targets_at(slot)` 再决定是否调 `g.targets_at(slot)`。无 `target_slots` 时每槽 `declared==true`，有表牌的已声明槽同门，均走同一谓词门。谓词不在非声明槽前，不在不调 `targets_at` 的路径上加问。

checkpoint(cleaner): 空槽走旧规则且不再收集通过

域：同上声明分支空路径（941–943行）。`not has_targets_at` 时特殊槽 `continue`、普通槽 `targets=[{}]`，且该路径无 `targets_at` 调用；其后 `bound_modes` 仍跳过空目标（948行 `target.is_empty() and spec.has("bound_modes")` 未动）。非空路径（944–946行）才 `targets=g.targets_at(slot)`，并保留旧追加规则（非特殊、非肩、未占满则追加 `{}`）。旧实现（`2ee7bc7` 前）为先 `targets_at` 再判空；新实现等价，差异仅为空槽少一次全身收集（等价性由 `has_targets_at_parity` 保证）。

checkpoint(cleaner): 未用 occupied 判空通过

域：同上槽循环判空点。空／非空判定唯一是 `g.has_targets_at(slot)`（941行）；`g.occupied(slot)` 仅出现在两处旧位：非声明分支表外占用跳过（938行，属已落地 `card_facts_declared_slots`，本刀不改），以及非空追加 `{}` 条件（946行 `not g.occupied(slot)`）。无 `occupied` 替代谓词、无 `targets_at(slot).is_empty()` 式判空。

checkpoint(cleaner): 未复制走查过滤通过

域：`core/card_effects.gd::card_facts`（893–966行）与 `core/game.gd::has_targets_at`／`_visit_targets_at`（1098–1140行）。生产 `card_facts` 内无自拼 `equipment_at`／复合／`links_at`／`Binding.connections` 目标规则（该函数内 `equipment_at` 仅 963行旧显示标签左右手文案，非收集；`links_at`／`connections`／`Composites` 零命中）；`has_targets_at` 实现为 `_visit_targets_at(slot,[],true)`（1103–1104行），非 `targets_at(slot).is_empty()`；`card_facts` 未缓存走查结果，非空槽允许两次走查（先谓词后收集）。`core/game.gd` 本刀零差异，走查过滤只存在于 `_visit_targets_at`。

checkpoint(cleaner): 依赖面与检查器核对，检查器报未建

域：本刀依赖边。生产新增边仅一处：`core/card_effects.gd::card_facts` → `Game.has_targets_at`（941行），即契约允许边；`git show 2ee7bc7` 生产差仅该谓词门，无新模块／运行时依赖／preload／存档／随机域／计数器（`targets_at_slots`／`slot_builds` 在 `core/` 零命中，计数器仅测试侧 `TargetsAtCountingGame`）。测试侧 `g.has_targets_at(slot)` 调用（2216行）是期望预测，非生产依赖。静态依赖方向检查器未建：`spire-godot/tools/` 仅 `check.ps1`（套件执行）／`check-docs.ps1`（文档引用）等既有门禁，无钉住本边的最小依赖检查器，按简报报未建且不新建（允许面无 `tools/`）。行为门禁即 `card_facts_consumes_has_targets_at` 本身，下见实现者证据。

checkpoint(cleaner): 文档与体积核对，不写 docs/spec

域：`docs/spec/candidate-removal-dependencies.md` 与体积。实现者未写 `docs/spec`（`2ee7bc7`＋HEAD 统计仅 `core/card_effects.gd`、`tests/architecture_cases.gd`、`build/implementer-report.md`）。本清洁亦不写：契约要求人审之后才把本边写入该依赖表 `core/card_effects.gd` 行，本次无该人审记录，留待收口；若将来写，只动该行且点名符号 `card_facts`／`has_targets_at` 均存在（已验证）。项目 AGENTS 无 Size and ESM，不适用；`core/card_effects.gd` 1456行／`tests/architecture_cases.gd` 2211行超长是既有，按简报不拆。无 ESM 漏斗穿透（仍经 `g` 调用同层 `Game` 方法，无新增 preload／跨层直引）。

checkpoint(cleaner): 验证与结论，本域已洁

域：本刀（card_facts 消费谓词）。本清洁零代码改动，按简报未重跑 architecture 套件；消费实现者同指纹证据（工作树源码与 HEAD 一致，`git diff HEAD --` 上述三文件为空）：`spire-godot/` `$env:GODOT_BIN=...; & tools/check.ps1 -Suite architecture -TimeoutSeconds 600`，Exit 0、`SUITE RESULT: architecture PASS`、`PASS: 4429 assertions`、`spire-godot/build/checks/20260925T055947199-28432/summary.json` status `passed` 且 before==after（`98A53704…FBBAFFC49B4F`），docs PASS（35 docs，2412 refs）。Gherkin：`card_facts_consumes_has_targets_at` 已在 `run` 注册（388行），覆盖真正空、单侧 palm／fingers（`occupied=false` 且件 id 在事实内）、仅覆盖槽活链接／连接／活跃复合、耐久 0 链接与禁用复合反例；oracle 经 `targets_at` 收集，空槽 `targets_at_slots` 无该槽、有目标槽仍计数、快照／rng 冻结；既有 `card_facts_declared_slots` 同次 PASS。未运行项沿实现者报告：equipment／composites／links／torso_binding 独立套件、加固变异（档 2）未跑；UI 验收 none。结论：本域已洁，无清洁改动，无范围冲突；`*.import`／`.uid` 未提交，未 push。
