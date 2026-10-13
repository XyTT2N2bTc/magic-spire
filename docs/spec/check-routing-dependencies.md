# 检查路由依赖约束

域：`tests/check_index.gd`、`tests/check_index_edges.gd`、`tests/check_index.json`、`tests/route_plan.gd`、`tests/runner_cases.gd`、`tools/build_check_index.gd`、`tools/check-index.ps1`、`tools/check.ps1` 的路由面。
语义与命令面见 `docs/spec/check-routing.md`。本文件是 cleaner 的核对面。

## 允许的边（逐条，不在表内的边即缺陷）

- `tests/check_index_edges.gd`（数据）→ 只被 `tests/check_index.gd` 预载；理由：手写层的八张表是派生不出来的知识，读取方只此一个。
- `tests/check_index.json` → 只被 `tests/check_index.gd::frozen()` 读；理由：冻结物是生成物的唯一消费面，其他读者会使「谁在读索引」出现第二处。
- `tests/check_index.gd` → 被 `tests/route_plan.gd`、`tests/runner_cases.gd`、`tools/build_check_index.gd` 预载；理由：派生实现只此一份，生成器／自检／计划宿主共用。
- `tools/check-index.ps1` → `tools/build_check_index.gd`；理由：入口脚本只负责起引擎、收日志与退出码。
- `tools/check.ps1` → `tests/route_plan.gd`（计划宿主）＋既有宿主 `tests/test_game.gd`／`tests/ui_smoke.gd`；理由：路由模式只把计划的 `rules`／`ui` 灌进既有执行路径，不新增第二个执行器。
- `tests/runner_cases.gd` 只**读**冻结物与手写层（经 `tests/check_index.gd`），不回写；`tests/suite_selection.gd` 本片**未改**（既有 API 与 `CROSS_AREAS` 行为不变）。

## 禁止的边

- `core/`／`ui/`／`data/` 引用 `tests/`（产品代码不依赖测试层）。
- `tests/check_index.gd` 预载宿主脚本（`tests/test_game.gd`／`tests/ui_smoke.gd` 只以文本读取）。
- `tests/route_plan.gd` 引用 `core/`（计划宿主只读冻结物）。
- 出现第二份「文件→套件」映射：派生在 `tests/check_index.gd`，手写例外在 `tests/check_index_edges.gd`，冻结在 `tests/check_index.json`，别处不得新建。
- 手改 `tests/check_index.json`（只许 `tools/check-index.ps1 -Write` 写，且与源码同批提交）。

## 有意重复的声明（各带同步义务）

- **declared-none 前缀**在 `tools/check.ps1`（起引擎前拒绝，函数 `Test-DeclaredNone`）与 `tests/check_index.gd`（路由拒绝）各有一份文本；理由：仓库外路径必须在起引擎前被拒，计划宿主不能替代该拒绝。改一处必须同步另一处（两份文本目前逐项相同）。
- **里程碑名单**唯一声明在 `tests/suite_selection.gd::LONG_RUNS`，索引以文本读取（不预载），扣除清单每次计划打印；`tests/check_index_edges.gd::CLOSURE` 的 `all-dev`／`all-dev-ui` 展开同样按该名单扣除。
- **影响域交叉表** `tests/suite_selection.gd::CROSS_AREAS` 仍是唯一手工声明；索引只以 `tests/check_index_edges.gd::WIDEN` 的 `impact:<区域>` 消费它，并用 `ROUTE WIDEN CANDIDATE` 打印两者的不一致（不自动放宽、不回写）。

## 规模与职责边界（2026-10-13 实测）

| 文件 | 行数 | 行数线 | 说明 |
| --- | --- | --- | --- |
| `tests/check_index.gd` | 534 | 400 | **超出**：派生（scan／compare）与路由（suites_for／ROUTE 渲染）同文件。职责边界是整个索引流水线；本片允许面不含第三个 `tests/` 文件，拆分会新增允许面外的文件。按根 `AGENTS.md`「大文件按职责拆，不按行数硬拆」，此处以职责说明代替拆分。 |
| `tests/check_index_edges.gd` | 148 | 500 | 手写层八张表（`DOMAINS` 60／`WIDEN` 1／`EXCLUDE` 15／`BLIND_BY_DESIGN` 3／`INDEX_DEFECTS` 0／`CLOSURE` 9／`ORACLE_NOTES` 2／`SUITE_EXEMPT` 3），逐条 `reason`；随语料增长，是人类审查面。 |
| `tests/route_plan.gd` | 56 | 120 | 计划宿主 CLI：读冻结物、打印 `ROUTE *`、写计划 JSON。 |
| `tools/build_check_index.gd` | 47 | 60 | `--verify`／`--write`；与读取方共用同一 `derive()`。 |
| `tests/runner_cases.gd` | 210 | — | 既有归属自检＋九条索引判据（一次 `derive()` 共用）。 |
| `tools/check.ps1` | 572 | — | 原 417 行；路由面新增 flag 校验、计划宿主调用、内容门阶段、八条探针与 `summary.route`。 |
| `tests/check_index.json` | 3732 | — | 生成物（schema 1），永不手改。 |

## 文档守卫

`docs/spec/check-routing.md` 与本文件的路径、`文件::符号` 锚点与本地链接由 `tools/check-docs.ps1` 守卫（随 `tools/check.ps1` 的 docs 阶段）；改动后必须过该门。
