# 未随本次提交落地的两片：检查路由与每点击检查调试门控

> 记录：撰写当时的方案与结论，只读；实现在分支 `event-pipeline-unification`（提交见各节），**未随本次文档/指引提交**。
> 前置状态（2026-09-18）：本仓库的派生索引与调试门控都不存在，引用它们的地方以本文为准。

## 一、检查路由与失败隔离（原 `docs/check-routing.md`）

- 目的：开发期不再每次跑全量，只跑受本次改动影响的套件；路由由**派生冻结索引**给出，未命中即 fail-closed 到全量（`all-dev` / `all-dev-ui`）。
- 组成：`tests/check_index.json`（冻结物，含 `generated_from` 指纹）、`tests/check_index.gd`（派生实现）、`tests/check_index_edges.gd`（手写边）、`tests/route_plan.gd`（计划）、`tools/check-index.ps1`（零漂移门禁）、`tools/check.ps1` 的 `-Changed`／`-Since`／`-ChangedList` 与**套件失败隔离**。
- 关键结论（实测）：隔离**不省墙钟**（729s vs 539.6s，长驻进程内 `prison`／`persistence` 开销所致），收益是 `unrun=[]` 与免补跑编排；`normal_play` 与 `baseline` 属**里程碑套件**，开发路由永不运行，PR／打包／发版仍须 `-Suite all -UI -UISuite all`。
- 索引口径：冻结物现为 `suite_edges 437`、`blind 4`、`registries` 规则 51／界面 46（`suites_with_edges 94` 是另一口径）。
- 实现位置：分支 `event-pipeline-unification`（`3afdc55` 契约、`eaa003a` 失败隔离、`aa199f4` 路由与索引）。

## 二、每点击完整性检查改为调试门控（原 `docs/per-click-checks.md`）

- 冻结事实：`dispatch` 的五道检查（`Consumables.validate_buffs`／`Binding.state_issue`／`SpecialEquipment.validate`／`Cards.validate`／`RelicEffects.validate`）、候选入口的两道闸（`Binding.state_issue`／`SpecialEquipment.validate`）、事件探针的 `g.validate()` **每次点击都跑**；开销随装备件数而非候选数增长（0／12／26 件 ＝ 4.0／3.5／3.1ms），在 26 件档只占一次点击 1.7%，但在出发页占 15–17%。
- 敏感性证明：把开关默认关掉后跑既有语料，41 个套件里**只有 `events` 1 条**变红（既有用例依赖被门控的探针 validate 一半），`event_flow`／`core` 全绿——即这些检查在语料内从不失败。
- 方案：`debug_checks_enabled()` 为单一判据（`OS.is_debug_build()` 为假恒 false；测试可覆盖，release 无途径开启）；失败时写实例诊断数组并 `push_warning`，**不进 state／存档／View／玩家日志**；写档前聚合校验、读档后聚合校验、`SpecialEquipment.validate` 的规则用途、版本判定一律保留。
- 状态：实现于分支 `event-pipeline-unification`（`3f96965`／`84eb12f`），登记于 `docs/record/verification.md`；**已裁定为过渡形态**，将在点击路径根治时替换。
