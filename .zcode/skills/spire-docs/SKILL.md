---
name: spire-docs
description: >-
  《紧缚尖塔》的文档规范：五类生命周期与写入规则、符号锚点、判据优先、改动同步义务、
  依赖表与允许改动表、记录诚实、文档守卫。改动 docs/、写契约或写记录之前读它。
---

# 文档规范（magic-spire）

## 五类生命周期与写入规则

| 类 | 目录 | 规则 |
| --- | --- | --- |
| 现行契约 | `docs/spec/` | 只写现在成立的事；**被取代即删**，不留"更正"段；同一条规则只写一处 |
| 设计与内容真源 | `docs/design/` | 每条事实只写一处，其它文件只链接，不复制 |
| 怎么干活 | `docs/guide/` | 操作口径（本地化、文案指南等） |
| 记录 | `docs/record/` | **只追加**；每条带日期＋域；验证册按时间分卷；不改写历史条目 |
| 归档 | `docs/history/` | 只读；含已被推翻的旧决策，不得当成现行指令 |

## 引用与锚点

- 引用代码用**符号锚点**（如 `core/game.gd::route_view`、`ui/route_map.gd::_input`），**不写行号**——行号随每次改动漂移。
- 引用文件用仓库相对路径（`spire-godot/ui/route_map.gd`、`docs/spec/…`）；写进文档前先确认该路径存在。

## 判据优先

- 一条规则要么配一个"关掉它什么会红"的检查，要么明写"本规则无机械判据、靠人审"。**没有判据又没有替代动作的禁令就是噪声**：不要写"不从叙事、颜色或标签猜规则事实"这类句子，写正面规则——判定只用稳定 ID。
- 契约里的判据条目若尚无对应检查，必须标注"未守卫"，并登记到 `docs/record/proposals/`。

## 改动同步义务

- 改代码或内容时，同步它点名的文档：文档入口表、依赖表（允许改动文件表）、本地化 key 表、设计真源、
  **管线／邻接表**（第五类）。
- **管线／邻接表**：声明"某入口按哪些边到达哪些子例程"的表，改实现路径、改节／例程名或改边时，
  必须在**同一批**改动里同步该表，否则表与实现漂移而无人可查。现有三张：
  - `spire-godot/ui/main.gd::PRESENT_ADJACENCY`（present 管线声明表）：入表口径见其表头注释，判据＝
    `spire-godot/tests/architecture_cases.gd::present_adjacency_graph_is_pinned`（三条：声明边必须有直调、
    表内符号被已登记父函数直调必须登记、无死项）。该判据只校验**已声明**的边，不保证每个管线条目都已登记：
    新增节／舞台例程不入表、删整行、乃至把整表掏空为 `{"present":[]}` 都不会变红，**由评审负责**；
    不设完整性下限（"已登记父在 `ui/main.gd` 里的每个直调都须入表或成子"会牵出约 80 个本地例程，
    多为随实现频繁变动的构建／域例程，属第二份易漂移手工清单）。每个被声明的符号（含仅作子出现的叶）都必须在表内有自己的行。
  - `docs/spec/candidate-removal.md` 的管线表（邻接表，第 1 节现状图与第 2 节目标图）：跨文件锚点、
    含历史行与未落地行，**无整表机械判据**；其机读子集＝
    `spire-godot/tests/architecture_cases.gd::PIPELINE_LOOKUP_EDGES`（检查入口
    `spire-godot/tests/architecture_cases.gd::command_fact_kind_lookup`）与
    `spire-godot/tests/architecture_cases.gd::instruction_router_single_entry`。改该表的边或锚点须同批核对这两处。
  - `docs/spec/equipment-query-seam.md` 的邻接表（`targets_at`／`has_targets_at` 路径一节）：声明查询入口到
    按槽走查的边与禁止边，**无整表机械判据**；其行为检查器＝
    `spire-godot/tests/equipment_cases.gd::index_targets_edge_parity`、
    `spire-godot/tests/architecture_cases.gd::has_targets_at_parity` 与
    `spire-godot/tests/architecture_cases.gd::index_materializes_once_per_scope`。改该表的边或锚点须同批核对这三处。
- 被取代的段落**改写为新事实或删除**；不要在新事实旁边留着旧事实当注释。

## 依赖表与允许改动表（`docs/spec/*-dependencies.md`）

- 表里的路径必须真实存在，且与实现的文件面一致（多写、少写都要改）。
- 表是 cleaner 与审查者的核对面：改动面超出表即失败，不是协商。

## 记录诚实

- 每条记录写全：日期＋域＋命令＋结果＋**未跑项**；不得把未跑写成通过。
- 指纹与摘要只作**同一次运行内**的守卫，**不当身份**；跨运行可对账的是逐分类计数与具名 check。
- 运行号必须可查（`build/checks/<运行号>`）；日志已被清理时写明"随临时 worktree 删除"。

## 文档守卫（现行）

- 规则类文档（`docs/spec`、`docs/design`、`docs/guide`、根 `AGENTS.md`、`.zcode/skills/*/SKILL.md`）
  在 `tools/check.ps1::Get-SourceFingerprint` 内：改这些文档会触发 `SOURCE CHANGED`，不再是零守卫。
  范围与排除理由（`docs/record/**` 只追加、`docs/history/**` 只读归档）的唯一声明在
  `spire-godot/tools/doc-scan-scope.ps1`。
- 引用门禁 `spire-godot/tools/check-docs.ps1`：点名路径必须存在、`文件::符号` 锚点必须已声明、
  本地 md 链接必须可达。允许存在的缺失引用逐条登记在检查内的允许清单（带理由与消掉条件），
  检查每次打印条目数；清单只能缩小。
- 仍靠人审：依赖表与实现的文件面一致（多写、少写都要改）、判据条目的实质正确性、
  被取代段落的删除。这三条没有机械判据。
