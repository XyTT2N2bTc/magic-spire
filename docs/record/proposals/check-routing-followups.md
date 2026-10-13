# 检查路由 follow-up（片②验收后登记，2026-10-14）

状态：**未落地**。来源＝片②（检查路由）独立审查与验收一轮的三条 [存疑]＋R2/R5/R6；均非本片失败项，登记供后续裁定。

## 1. 空 `--ui-suite=` 的显式拒绝（建议）
纯 `declared-none` 变更集真跑 `-Changed` 时 `$Suite=[]` ⇒ `$UIOnly=true`、`$UISuite=[]`，UI 阶段仍被触发并以空参数起 `ui_smoke.gd` → `Unknown or empty UI check suite`、exit 1。fail-closed 非假绿，但失败信息与路由无关。建议在 `check.ps1` 增加「路由结果为空 UI 面」的显式拒绝文案（域：`tools/check.ps1` 路由段）。

## 2. 无 `static func run(` 的用例文件静默面（建议）
`tests/*_cases.gd` 中缺 `run(` 者既不进覆盖判据也不进闭包，行 scope 为空：单文件 fail-closed，混跑时该文件可无归属而整轮 passed；已注册用例文件删 `run(` 亦无判据。建议在索引派生或覆盖判据侧加「用例文件必须有 `run(` 或登记豁免」的机械检查（域：`tests/check_index*.gd`／`runner_cases.gd`）。

## 3. 合同正文与冻结期望的同步（滞后项）
计划区合同「`ui/main.gd` 规则 0」与当前冻结期望 `rules=architecture` 不一致（真实派生边 `rule:architecture→ui/main.gd`；G-RT-3/4 口径即「按当前树重测冻结」）。已随重落盘版保留口径；原文若再引用需按现树更正。

## 4. `-Changed`+`-RerunFailed` 对不可读目标的失败文案（加固候选）
目标目录不可读时给路径错误而非具名互斥文案；仍 fail-closed。域：`tools/check.ps1` 参数校验顺序。

## 5. A-RT-11 路由窄度（人审面）
「更窄处逐条有据」`ROUTE WIDEN CANDIDATE` 登记为人工审阅面，无机械判据（与依赖文档「仍靠人审」节一致）。
