# 事件管线统一契约（定义形态 → 单求值入口 → 事件链）

规划者契约（planner contract），2026-09-16。冻结本片要动的事件定义形态、求值入口、
节点与事件链模型、存档表示与显式声明清单；内部实现以代码为准，接口语义以本文件为准。
本文件不写执行结果：通过／失败／未执行只登记到 `docs/verification.md`。

**状态：人审已通过（2026-09-16，记录见下与 §13／§15）。实现者可在本记录落地后按 B1→B4 开工。**

行号捕获于 commit `3bfec7e`；**函数名与稳定 id 才是锚点**，动手前用 `rg` 复算。

## 人审决定记录（协调者转写，2026-09-16）

来源：人审问答。以下四条为裁定原文摘要，覆盖本文件先前所有"待裁／建议"措辞。

1. **计划：接受，按契约执行**——B1→B4 分批，每批以 E0 94 场景全绿收口；`needs-human-review` 已解除。
2. **R8 启动期迁移脚本：不落地，设计留档**——§6.4 只保留为留档设计，不写脚本、不改启动链。
3. **R5 校验取值：取并集并逐条登记**——§2.5 的每条放宽项必须列出对应既有反例断言的期望更新。
4. **R1 由人澄清改写（原话）**：
   > 是我表达错误，应当是最后的功能实现，即玩家看到的不变，后端完善 trigger 系统，
   > 分条件可选和条件隐藏，可叠加

   含义（协调者转写，本契约按此修订）：**终态是后端 trigger 系统的完善**——"条件可选（显示但禁用）"
   与"条件隐藏（不生成）"是**两类可并存的模式**，且**条件可以叠加**（同一选项可同时声明多条条件、
   两类模式同时生效）；玩家可见行为不变仍是硬要求。**"保留冻结选项双布局"不是设计目标，只是
   E0 逐字节不变这一硬判据带来的兼容要求**（§6.1 按此措辞）。

其余条目按 §13 推荐执行（R2／R3／R4／R6／R7／R9／R10／R11／R12），不再单独人裁。
§15 的 `needs-human-review` 理由保留为历史记录，不再是关口。

已核实的既有缺陷（**不属本片范围，待排期**）：`content_catalog.gd:308` 阶段选项的
`_availability()` 漏传 `data`，`has_relic` 写在阶段选项上永远无法通过校验（**B1 已顺带修好**，
见执行记录）；阶段 id 保留字清单缺 `battle`／`loot`（两者是运行时阶段哨兵值，B1 已并入保留字）。

## 执行记录（B1 已落地；含裁定与偏差）

### B1 落地事实（commit `d770aea`，父 `4d22a00`；工作区干净、未推送）

| 项 | 内容 |
| --- | --- |
| 范围 | `core/room_events.gd`（唯一定义访问 `definition/node/node_ids`；`start` 按节点数驱动两条分支；`enter_stage`→`enter_node` 无别名；`probe/execute/view/validate` 全走访问器）、`core/content_catalog.gd`（事件 schema 升 2；单一形态校验 `start_node`＋`nodes`；§2.5 并集；`_flow_references` 与普通分支合并为 `_event_references`；`has_relic` 校验补传遗物表）、`core/snapshot.gd`（事件段改走访问器）、12 份内容包＋2 份模板＋生成来源迁移、3 个测试文件 |
| 判据 | E0 退出码 0／`PASS (94 scenarios, 0 failures)`／摘要 `1f11bea5…`（日志 `build/e0-diagnostic-20260916/compare-b1-final.log`）；`-Suite event_flow,events,content,architecture -Impact` 退出码 1，唯一失败分类＝`card_power`（`-KeepGoing` 23/24 通过、5/10339 失败，逐条为已登记既有项）；`check-content.ps1` 退出码 0 |
| 独立复核 | 协调者重跑 E0（同摘要）、四类套件全 PASS（1963 断言）、内容包校验 12 file(s) PASS |
| 场景落点 | 01 `event_definition_single_form`（event_cases）、02 `event_option_policies_match_current_behaviour`（event_flow_cases）、06／07／20（content_cases） |

**判据按增量判定成立**：B1 未引入新红项，E0 逐字节不变。

### B1b 落地事实（commit `a57dec3`，判据登记 `4d5bc8f`；工作区干净）

| 项 | 内容 |
| --- | --- |
| 范围 | 六份文件：`spire-godot/content/README.md` §3 整节重写为节点形态（定义字段、七个节点声明键与取值、合并后选项白名单含"适用形态"列、起始节点免费出口只约束多节点）；`docs/content-templates.md`／`content-generation.md`／`content-extension.md` 同步（模板为真源、文档跟随；已死的选项级 `pressure` 示例删除；`wager`／`reward:"keys"` 这类 B1 前就不被接受的写法改为显式标注为早期设计记录）；`tests/architecture_cases.gd` 的 `event_dependency_edges_pinned`／`event_definition_accessors_only`；`tests/content_cases.gd` 的 `event_author_manual_lists_current_fields` |
| 判据 | E0 退出码 0／摘要 `1f11bea5…`；`check-content.ps1` 12 file(s) PASS；模板探针 `-Path build/b1b-docs-20260916/template-probe` 2 file(s) PASS；四类套件全 PASS（2147 断言）；`-Impact` 红集恰好 `card_power` 五条；四份文档旧形态残留零命中（`rg` 退出码 1） |
| 独立复核 | 协调者重跑 E0（同摘要）、内容门、模板探针、四类套件 |
| 具名 check 非空洞 | `event_author_manual_lists_current_fields` 在修正 `allow_refuse` 取值前**真实红过一次**（反向对照成立） |

**依赖规范 §4.2 的两条追溯 check 已随 B1b 落地**；其余三条按 §9 分派 B2／B4。

### 裁定与偏差（协调者转人裁，2026-09-16 第二批；本节即偏差登记）

| # | 事项 | 裁定与契约位置 |
| --- | --- | --- |
| A1 | 并集白名单过渡态：单节点选项在 B1 后可编译 `next`／`when`／`outcomes`／`encounter`／`item_rewards`，其中 `next`／`when`／`outcomes` 到 B2 才生效 | **接受并登记**（§2.5 过渡态段）：有意的过渡态，不是漏做；B2 同批使其生效，§10 场景 08 为该能力的具名 check；**B2 落地前不得打包、不得发版**（§12）；B2 前任何内容包不得使用这三个键（12 份内容＋E0 已覆盖） |
| A2 | 起始节点免费出口规则只约束多节点定义 | **接受**（§2.5 登记表第 7 行注明读法）：字面约束单节点会让四份强制事件立即非法，与"只放宽不收紧"冲突 |
| A3 | 选项级 `conditions`／`unavailable` 规范拼写缓到 B2 | **接受**（§2.3）：避免反向开放尚未实现的能力；与声明表同批落地 |
| A4 | §6.3 按选项键判定暂缓到 B2 | **接受，但 B2 必须增量完成**（§6.3）：保留现有 `flow` 分支的检查，另补新键检查，**不得以放宽换取统一** |
| A5 | `normal_play` 红项 | **不进本片、不派修**。登记措辞按事实：`docs/verification.md:58` 已有既有登记（2026-09-14 全量尝试条目）；B1 实现者在 `HEAD~1` 复现出同样打转，但**因主动终止未能证明旧版断言同样红 → 归因未定**；**不得写成"与 B1 无关"**（§12） |
| A6 | 文档同步缺口（唯一实质缺口） | **立 B1b 批**（§8.3、§16）：`content/README.md`、`docs/content-templates.md`、`docs/content-generation.md`、`docs/content-extension.md` 仍教旧形态，照文档写出的包会被新校验拒绝 |
| A7 | 根指引"仍写 Godot 入口见 `spire-godot/AGENTS.md`" | **磁盘复核：不存在**（根 `AGENTS.md` 只有"## 模块规则（spire-godot/）"＋文档入口表；无该句、无 `tools/check_agents.py`、无"CI 检查指引行数"节）。此前表述来自注入副本，已在 §8.3 更正；新增假设见 §14 |
| A8 | 依赖规范 §4.2 的 5 条架构 check 归属 | 确认原意是分批判据，现按 §7.4／依赖规范 §4.2 明确分配：两条随 B1b，两条随 B2，一条 B2＋B4 两半 |

### 裁定与偏差（协调者转人裁，2026-09-16 第三批；B1b 之后）

| # | 事项 | 裁定与契约位置 |
| --- | --- | --- |
| A9 | 本地化词表漂移（`assets/localization/legacy-en_US.json` 仍登记被删除的旧文案、新文案缺译；安全回退显示源文，无玩法影响） | **不另立批次，并入 B2 范围**（§17）：B1 改掉了校验文案，B2 还会再动（并集、`conditions`、叠加），单独刷一次会立刻返工。B2 同批刷新英文字典并使其与新校验文案一致；命令、口径与验收方式写死在 §17（判据见 §12 命令 5） |
| A10 | `docs/event-structure.md` §1 结构地图已过期（描述 B1 前的 `stages/start_stage`） | **已由规划者处理**：§1 顶部加带日期状态注（指明现行形态见本契约执行记录，§2 缺陷 1／3／4／5／6／8 的状态以本契约执行记录为准）；§7.2 加同样的指向注。测绘原文保留，不重写 |
| A11 | `docs/content-generation.md` §7.4 的早期设计记录（`wager`／`keys`） | **接受现处理**（显式标注、不删）；不另派，仅登记 |

### B2 核心落地事实（commit `60869fc`，父 `fa96370`；**本批未完成**，收口见 §18）

| 项 | 内容 |
| --- | --- |
| 范围 | 四份文件：`core/room_events.gd`（`CONDITIONS` 单一声明表＋四处派生 `condition_kinds`／`condition_entries`／`condition_issue`／`condition_probe`／`condition_saved_fields`；`evaluate_option` 单入口带 `gates` 逐条与四种 `decision`、多命中按声明序 `"\n"` 拼接；`enter_node` 成唯一节点管线、七个声明全部生效、**节点数分支消失**；`probe`／`candidates`／`execute`／`view`／`validate` **不再读 `flow` 镜像**；删选项级 `pressure`／`pressure_source` 死分支）、`core/content_catalog.gd`（白名单加 `conditions`（1—8 条、每条 `mode`）与选项级 `unavailable`；`availability`＋`conditions` 互斥、`unavailable`＋`hide_when_unavailable` 互斥；kind 校验改调 `condition_issue`，第二份 kind 清单消失）、`core/snapshot.gd`（**增量**：保留 `flow` 分支全部检查，另加 `conditions` 形状／键集＝`condition_saved_fields(kind)+["mode"]`／`mode∈{optional,hidden}`／与 `availability` 互斥）、`tests/event_flow_cases.gd`（夹具把注入选项的 `stage` 从旧 `"choice"` 改为真实节点 `"service"`，断言未变） |
| 判据（协调者独立重跑） | E0 退出码 0／摘要 `1f11bea5…` **逐字相同**；`event_flow,events,content,architecture,persistence` 五套件全 PASS（2767 断言）；`-UIOnly -UISuite events` PASS 180；`check-content.ps1` 12 file(s) PASS；`-Impact` 红集经实现者枚举为恰好 `card_power` 五条（`docs/verification.md:29`） |
| 未完成（故 **B2 不得宣称通过**） | §10 场景 05／08／09／13／15–18 的具名 check **一条未落**；依赖规范 §4.2 三条 check 未落；本地化（裁定 A9）**完全未做**（字典未刷、盘点未出、`locale_legacy_catalog_matches_current_sources` 未产出） |
| 磁盘复核（规划者） | `room_events.gd` 已无 `get("flow")` 读取；`frozen_form` 判据＝`in_place 且无 selector`（§2.3／§6.1）；`empty_node` 只决定是否返回既有 issue 文案、**未记 gate**；可分离失败已记 `probe_failed`／`encounter_invalid`，无 `validate_failed`；`assets/localization/legacy-en_US.json` 最后改动仍停在 `e635bf5`（v0.17） |

### 裁定与偏差（协调者转人裁，2026-09-16 第四批；B2 核心之后）

| # | 事项 | 裁定与契约位置 |
| --- | --- | --- |
| A12 | `frozen_form` 的布局选择 | **接受并写进契约**（§2.3／§6.1）：**节点声明 `in_place` 且选项无 `selector` 时用 in_place 布局，否则用 staged**。依据 §1.1 P2：普通事件的选择器选项现状就由共享 staged 构建器冻结；只按节点声明选构建器会让 `temper`／`dissolve` 这类选项的冻结 id 与 `selected` 键改变 → E0 必红 |
| A13 | `validate_failed` 与 `node_empty` 的 gate 命名 | **缓到 B3（接受）**：B2 已把可分离的失败记成 `probe_failed`／`encounter_invalid`；单独命名 `validate_failed` 要拆 `probe()` 内部，属 B3「gate 命名全覆盖」；`node_empty` 现仍以既有 issue 文案返回、未单独记 gate，同属 B3。§4.2 表与 §10 场景 09／03 已标注 |
| A14 | B2 收口批 | **立 B2b（本批收口，不另立切片）**：①§10 场景 05／08／09／13／15–18 具名 check；②依赖规范 §4.2 三条 check；③本地化刷新＋盘点＋`locale_legacy_catalog_matches_current_sources`（按 §17 写死的口径①②③）；④以 B2 完整门禁命令（含 `localization`）复跑并交证据。**B2b 落地前本片仍不得打包发版**（§12） |

### B2b 落地事实（commit `5a60cda`，父 `d67ac01`；**三项交付已落、四条判据绿；收口续批待完成**）

| 项 | 内容 |
| --- | --- |
| 交付 | 五份文件：`tests/architecture_cases.gd`（+57：`event_condition_kinds_share_one_declaration`、`event_single_evaluation_entry`）、`tests/event_flow_cases.gd`（+100：`event_single_node_declarations`／`event_node_empty_policy_kept`／`event_stacked_conditions`）、`tests/persistence_cases.gd`（+17：`event_pipeline_writes_only_declared_keys`）、`tests/localization_cases.gd`（+81：`locale_legacy_catalog_matches_current_sources`）、`assets/localization/legacy-en_US.json`（删 25 条旧源文、增 29 条新校验文案，条目 4943→4947；`removed still present: []`／`required missing: []`） |
| 判据（协调者独立复核） | E0 退出码 0／摘要 `1f11bea5…` **逐字相同**；`-Impact` 展开集红集**恰好** `card_power` 五条、`unrun=[]`；`event_flow,events,content,architecture,localization,persistence` 六类全 PASS（3035 断言）；`-UIOnly -UISuite events,localization` PASS 231；`check-content.ps1` 12 file(s) PASS |
| 盘点 | `needs_review 5690`、`connected_static_call 33`；`en_US 52/52`、`ja_JP 0/52`（ja 缺译非本片引入、未动） |
| 未完成／未证（3 项，**本批不得宣称通过**） | 见下面的"B2b 续批清单" |

**B2b 续批清单（收口续批；每项都要有具名 check 或明确分类结论）**

| # | 未完成／未证 | 字面判据（契约要求） | 归属 |
| --- | --- | --- | --- |
| C1 | `conditions` ＋ `mode:"hidden"` **未证实真正丢弃选项**：实现者夹具在 `enter_node` 后选项仍在 `room_event.options`，只有 `evaluate_option` 报 `decision=="hidden"`。磁盘复核：已落地的 `event_stacked_conditions` 里 `stacked_fixture_1`（`mode:"hidden"`）**只被构造、未被断言**，`stacked_fixture_2` 只断言"两条件都不命中后恢复" | §10 场景 16／17 的字面判据＝选项**不在** `room_event.options`／候选里（`decision=="hidden"` 是中间量，不是判据） | 实现者定位并分类（夹具／真缺口）；真缺口则修 `enter_node` 或 in_place 到达路径 |
| C2 | 场景 09 第三段未落地：`next` 指向空节点时**上一节点候选变 invalid** | §10 场景 09 第三段；`probe` 的 `next` 探测路径必须有用例 | B2b 续批 |
| C3 | 场景 05 断言分布：集中在 `architecture_cases.gd` 一条 check 内（三处消费者都断言），未按字面分文件 | **裁定 A15：接受**——判据是"三处一致"，一条 check 覆盖三处消费者即可，**不强制分文件**；§10 场景 05 措辞已按此改写 | 已裁定，无需补 |

**为什么必须单独立证（E0 不能替代）**：现有 12 份内容走的是兼容拼写
（`hide_when_unavailable` → `_state_mode` → hidden），E0 证明的是那条路径；
**规范拼写 `conditions` 数组＋显式 `mode` 的容器解析不在 E0 覆盖内**（本片没有任何内容使用它），
所以 C1 必须由具名 check 立证，不能以"E0 全绿"代替。

### 裁定与偏差（协调者转人裁，2026-09-16 第五批；B2b 之后）

| # | 事项 | 裁定与契约位置 |
| --- | --- | --- |
| A15 | 场景 05 是否必须"内容侧／存档侧分文件各出断言" | **裁定：接受"单 check 覆盖三处消费者"**。判据是**三处一致**（内容校验／运行时求值／存档校验），一条 check 同时断言三者与分文件的检出力等价，文件分布不影响效力；§10 场景 05 与依赖规范 §4.2 的登记措辞已同步为"一条 check 覆盖三处消费者即可（不强制分文件）" |
| A16 | 打包与"完成"口径 | **记录并前置**：本片（含 B2b 收口）**未完成前不得打包发版**；**核心绿≠本批绿**（B2 核心绿≠B2 完成）、**B2b 续批绿≠整片完成**（B3／B4 未做）。任何报告不得用其中任一层绿色代表上一层（§12） |

### B2 收口事实（commit `b6d45b5`，父 `5a60cda`；判据登记 `df856b7`；**B2 全批判为已完成**）

| 项 | 内容 |
| --- | --- |
| 交付 | `tests/event_flow_cases.gd`（+23／−6，仅测试）：场景 16／17 改为契约字面判据（hidden 命中时选项**不在** `room_event.options`、候选里该选项 0 条；命中的 optional 条目使选项禁用并带作者原因）；场景 09 补第三段——进入 `penalty` 后 `next` 指向空节点的选项在候选阶段 invalid 且带非空原因，并同断言 `probe` 的 `next` 探测路径报同一 issue |
| C1 归因结论 | **(a) 夹具／断言问题，不是产品缺口**（未改产品代码）。错因两条：①原断言把 `options.is_empty()` 与 `candidates().is_empty()` 用 `and` 相连，而 `candidates()` 含阶段级候选 → 断言恒假；②另一夹具的期望依赖 `no_chastity_lock` 命中，而未戴平板锁时该条件本不该命中。最小复现 `build/b2-pipeline-20260916/repro_hidden.gd`（两组夹具 × 戴锁／不戴锁）证明 `hidden` 命中确实丢弃选项 |
| C1 附带读法坑（记入契约） | 给 `evaluate_option` 传**作者选项**而非**冻结选项**（`request.frozen` 缺失）时，第 4 步按设计**跳过状态条件**——诊断新拼写必须走 `request_for`／`frozen`，否则会把设计行为误读成缺口 |
| C2 | **已补**。原拟用的 `tighten_two` 在进房时被合法丢弃（`freeze_failed`）因而不产生候选，改用同节点内会存活的 `two_ropes`——属流程事实，不是静默删除 |
| C3 | 已按 A15 裁定，无需补 |
| 判据（协调者独立重跑） | E0 退出码 0／摘要 `1f11bea5…` 逐字相同；`event_flow,events,content,architecture,localization,persistence` 六类全 PASS（3044 断言）；`-Impact` 红集恰好 `card_power` 五条；`-UIOnly -UISuite events,localization -TimeoutSeconds 900` PASS 231；`check-content.ps1` 12 file(s) |
| **B2 状态** | **已完成**（核心 `60869fc`＋B2b `5a60cda`＋收口 `b6d45b5`，判据逐提交复核，登记 `df856b7`）。**整片仍未完成**：B2c（文档收尾）、B3、B4 未做；**打包禁令不变** |

### 裁定与偏差（协调者转人裁，2026-09-16 第六批；B2 收口之后）

| # | 事项 | 裁定与契约位置 |
| --- | --- | --- |
| A17 | UI 判据的时限口径 | **固化**：`-UIOnly -UISuite events,localization` **必须带 `-TimeoutSeconds 900`**；默认 300 秒会因负载在 `events` 套件中途被中止（证据 `build/checks/20260916T083346894-13484`：无 `UI RESULT` 行）。已写进 §12 命令块与 §18／§19／§20／§21 |
| A18 | 归因纪律（新 check 首次变红时） | **写进 §14 假设节**：先分类"**判据／夹具写错** vs **行为漂移**"，用最小复现定类后再动手；**禁止把红断言直接改成通过**。本轮已两次实例：E0 比较器修复（`4d22a00`）与 `hidden` 立证（`b6d45b5`）。最小复现产物放已忽略的 `build/<topic>-<date>/`，摘要进 `docs/verification.md` |
| A19 | 旧待办更正：根 `AGENTS.md` 文档入口表两行 | **已在 `fa96370` 加好**（磁盘：`AGENTS.md:133` 事件定义形态与管线统一、`:134` 事件管线依赖约束；`git show fa96370:AGENTS.md` 命中 2 处）。此前把它列为"待协调者转派"是**我沿用了旧清单未复核磁盘**——已从 §8.3／§16／§18 的待办中删除，并作为"写规范前先核磁盘"的第三例（§14 假设 8） |

### B2c 与 B3 核心落地事实

| 项 | 内容 |
| --- | --- |
| B2c（`1f450d7`，登记 `3aee25a`） | 四份作者文档补 `conditions`／选项级 `unavailable`／`mode`／叠加语义并删过期标注；**已完成**（§9 已更新） |
| B3 核心（`f95e96f`，父 `3aee25a`） | `core/room_events.gd`：`probe_result`（唯一实现，`probe()` 保留原签名＝返回 `.reason`）：`effects`→`probe_failed`、`next_node`→取节点入口 gate、`validate`→**`validate_failed`**、暂存未归还→**`held_pending`**；`enter_node_result`（唯一实现）：空节点→**`node_empty`**、节点不存在→**`stage_missing`**，**issue 文案一字未改**；`feasibility_gate` 改从 `probe_result` 取 gate；debug trace＝`Events.trace_enabled(g)`／`event_trace(g)`／`trace_entry(...)`（**元数据实现**，条目 11 字段，见 A20） |
| B3 核心判据（协调者两遍） | 开关关闭与开启**均**退出码 0／`PASS (94 scenarios, 0 failures)`／摘要**逐字相同** `1f11bea5…`；冻结 oracle `cf48529a…` 与基线 `bdf08765…` 未变 |
| 未完成 | ①§10 场景 03／04／10／19 四条具名 check 未落（已写出但按纪律移除，见下）；②release 不产出的证据链未给出；③`start` 清空缺陷**已修**（`9e08d2a` 的 `clear_trace`）；④trace 行字段语义缺口**已钉死**（A25，待按新口径重写断言）；⑤`installed_tools` 已定类为既有红项（A23） |

**B3 核心待修（磁盘复核，属 B3b 收口）**：`core/room_events.gd:25` 写作
`if g.get("event_trace_enabled")==true: g.event_trace=[]`，而访问器用的是
`get_meta("event_trace_enabled")`／`get_meta("event_trace")`（`:383-396`）。两者不是同一存储：
①经 `set_meta` 打开开关时，第 25 行的守卫恒为假（`Object.get()` 读不到元数据）→ **`start` 不会清空**，
trace 会跨事件累积陈旧条目；②`g.event_trace=[]` 在 `core/game.gd` 无该成员时会触发脚本错误。
E0 摘要不受影响（E0 不读 trace），但 §4.5「每次 `start` 在启用时清空」与场景 03／19 的判据会被这条破坏。
**修法**：清空改走同一接口（如 `Events.clear_trace(g)` 或 `event_trace(g).clear()`），并让场景 03／19
显式断言"上一事件的行不残留"。另：**开关打开那遍必须核引擎错误日志**——oracle 显式 `quit(0)`，
退出码不反映脚本错误。

### 裁定与偏差（协调者转人裁，2026-09-16 第七批；B3 核心之后）

| # | 事项 | 裁定与契约位置 |
| --- | --- | --- |
| A20 | trace 落点（§20 与 §4.5 的措辞冲突） | **裁定：以"游戏对象上的普通调试字段、不进 `state`／`View`／存档"为语义实质**；**接受元数据实现**（`set_meta("event_trace_enabled")`／`set_meta("event_trace")` ＋ `Events.trace_enabled(g)`／`event_trace(g)`／`trace_entry(...)`）；**不授权改 `core/game.gd`**。§4.5 与 §20 已改为"trace 只挂在游戏对象上的调试字段（实现可经元数据或普通字段，均不得进 state／View／存档）"，依赖规范同步 |
| A21 | `installed_tools` 新红＝**待分类项**（不得写成既有项） | 现象：`tests/installed_tools_cases.gd:43` `SCRIPT ERROR: Invalid access to property or key 'detail'`、`FAIL: 0/9 assertions; 1 engine errors`；`t.find_action(g,"card",…)` 返回兜底 `{valid:false,payload:{}}`（该卡牌候选没生成）。实现者证据：把 `core/room_events.gd` 还原到 `1f450d7`（B3 之前）单跑该套件**同样报错、同样 0/9** → 排除 B3；但 HEAD 含 B1／B2／B2b／B2c，**不能排除本片早期提交引入**。该分类在 `docs/verification.md` 只有历史通过记录，**从未登记为阻塞项**。**两条路径**：①在 `4d22a00`（B1 之前）重跑同一套件 → 若同样红＝既有项，由协调者登记并把门禁红集改为 ⊆ {`card_power` 5 条, `installed_tools`}；②若在 `4d22a00` 绿而在本片某项后变红＝本片回归 → **停下 B3 收口，先修复再做收口**。`tests/installed_tools_cases.gd` **不在实现者可改清单内**：若结论是夹具过时，回到协调者裁定后再动 |
| A22 | 方法论口径（与 E0 比较器、hidden 立证并列） | **发现新红时，分类的第一步是"在引入点之前重跑同一套件"，而不是先解释现象**；分类前**不得**把红项登记为既有项、也**不得**直接修（§14 假设 9 已并入） |
| A23 | `installed_tools` 定类结论 | **既有红项**（协调者已登记 `docs/verification.md` 2026-09-16 B3 条目：`tests/installed_tools_cases.gd:43` 脚本错误、`0/9`；在 `4d22a00` 同样红 → **非本片回归**；根因方向＝夹具前置条件与当前卡牌／工具接口漂移，未定类未修）。**门禁红集口径自此为 ⊆ {`card_power` 5 条, `installed_tools` 1 条}**；§12 与 §20／§20.1 已同步 |
| A24 | E0 两遍的判据补强 | E0 的"关／开两遍摘要逐字相同"**必须与"引擎错误日志命中 0 行"一起用**（oracle 显式 `quit(0)`，退出码不反映脚本错误）；已写进 §12 命令块与 §20.1 的 D2／D5 |
| A25 | trace 行的 `index`／`source_choice`／`option_id` 语义与不变量 | **补齐契约缺口**（本轮误红的根因）：`index`＝条件条目在选项声明列表中的下标（0 起，任意求值恒定；非条件 gate 的 `index` 只是本次求值的记账位置、**不参与跨 purpose 比较**）；`source_choice`＝作者选项 id；`option_id`＝冻结实例 id（选择器选项带 `__<实例>` 后缀）；**状态条件行跨 purpose 必须逐字段相同（仅 `purpose` 可变），缺行即实现缺陷**；**禁止按 trace 总行数断言**。§4.5 已写全，§10 场景 03／19 与 §20.1 D1／D1a 已对齐 |

### B3 收口本轮事实（提交 `beb3005`，父 `9e08d2a`）

| 项 | 内容 |
| --- | --- |
| 分类结论 | **夹具期望写错，非产品缺陷**（独立最小复现 `build/b3-trace-20260916/repro_trace.gd`：单事件＋单选项＋两条 `optional` 的 `has_relic`，打印全部行）——条目字段齐备、命中两条各一行、`index` 0／1 与声明序一致、`mode=optional`、`reason` 甲乙按声明序、关闭时 0 行、第二次 `start` 后 `rows=2`（`clear_trace` 生效）。**产品与 §4.5／场景 19 字面相符**；先前断言把选择器场景与 `candidates()` 之后的追加行**计数写死**，属期望错误 |
| 已修 | `start` 清空改走 `clear_trace(g)`（D3 完成，`9e08d2a` 记录） |
| 仍未落地 | 场景 03／19 的 check 已写出但断言仍红，实现者按纪律**移除而未弱化、未提交**（占位说明留在 `tests/event_cases.gd:49-55`）。现象：套件上下文里 `candidates()` 后 trace 总数＝4（与独立复现一致），但**没有 `purpose=="candidate" and index==0` 的行**；选择器选项的冻结 id 带 `__` 后缀，前缀匹配仍报同一句 → **根因即 A25 的字段语义未钉死（`source_choice`／`option_id` 现为同一值）＋断言按总行数写死** |
| 判据（实现者实测） | E0 两遍摘要逐字相同且**引擎错误日志命中 0 行**；内容门 12 file(s)；`-Impact` 红集＝{`card_power`, `installed_tools`}（均在 A23 允许集内）；UI 900 秒 PASS 231。**B3 仍未完成** |
| 下一步 | 实现者补交**套件上下文下 trace 行的原始全字段数据**（不是断言结果）；按 A25 判定是"实现不一致"还是"断言超纲"，据此派修或改断言 |

## 0. 领域、裁决与不变量

领域（只在这里动）：

| 范围 | 文件 |
| --- | --- |
| 事件定义、生成、求值、执行、投影、校验 | `spire-godot/core/room_events.gd` |
| 内容编译与校验 | `spire-godot/core/content_catalog.gd` |
| 事件进度与选项存档校验 | `spire-godot/core/snapshot.gd`（事件段，含定义访问；约 379–428 行） |
| 外部内容 | `spire-godot/content/packs/*.json`、`content/templates/event*.json*` |
| 测试与判据宿主 | `spire-godot/tests/{event_cases,event_flow_cases,event_ui_cases,event_draw_cases,content_cases,persistence_cases,architecture_cases}.gd` |
| 启动链迁移脚本（**只在设计里写，本片不改**） | `release/开始游戏.vbs` → `spire-godot/tools/launch.ps1` |

非目标（本片不做）：`core/game.gd` 提交管线、`ui/`（含 `ui/event_screen.gd`）、文案路由、
装备查询索引、E4 战斗桥行为（`begin_battle`／`finish_battle`／`room_encounters` 借用）、
E6 玩家可见政策（漂浮皮带群持有扣环时的隐藏行为维持现状）、全量回归与打包。

人已裁五条（2026-09-16，直接按此设计，不再列为待裁）：

1. 普通事件（`choices`）与多阶段事件（`stages`）合并为**一种定义形态与一条生成／执行管线**。
2. 内容必须合并：外部 JSON 合并成一种事件形态，允许变更内容包 schema；12 份现有内容迁移。
3. **投影不动**：`room_events.view`、`game_view`、`get_view().room_event` 的可见字段与语义不变。
4. 旧档迁移允许，走启动期脚本；不要求游戏本体读旧存档。
5. 分流指向事件＝事件节点与事件链：路由目标统一为事件／节点 id；同一定义内的阶段即节点，
   跳转到另一个事件是同一机制，跨事件跳转形成事件链。

### 0.1 语义不变量（本片的硬判据）

**合并的是格式与管线，不是语义。** 12 份内容的玩家可见行为保持不变：哪些选项出现、哪些显示但禁用、
冻结后的效果、报告与结果文案、以及同一 seed 下 `event` 域随机抽取序列与计数。

可执行判据（E0，本片每一批都必须全绿）：

```powershell
# 在 spire-godot/ 下执行；基线只读，禁止 --write=
& <Godot console 可执行文件> --headless --path . --script res://build/event-oracle-20260916/event_oracle.gd -- --baseline=build/event-oracle-20260916/baseline.json
# 判据：退出码 0 且最后一行 EVENT RESULT: PASS (94 scenarios, 0 failures)
```

94 个场景逐场景比较 `candidates`／`view`／`options`／`snapshot`／`rng`（外加 `stage`／`phase`／
`validate`／`dispatch`／`error` 的明文值）。**任何红项都是需要解决或显式人裁的差异，不得默认为
"合并的正常结果"。** 基线摘要：`1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da`（单次约 10 秒）。

### 0.2 本片对"语义不变"的解释（必须写进实现）

E0 冻结的不只是玩家可见文本，还包括**运行期数据布局**：`snapshot` 摘要覆盖整个 `state`（含
`room_event` 与冻结选项），`options` 摘要覆盖 `room_event.options` 的 JSON 文本（**键序也算**）。
因此本片的统一发生在"作者形态 + 求值入口"，**不在冻结产物**。由此产生三条实现约束：

1. 冻结选项的字段布局按现状保留（见 §2.4 的 `frozen_form`），不得顺手统一；
2. 普通非选择器选项的冻结结果＝作者选项对象本身，迁移时**不得增删键、不得改键序**（§8.2）；
3. `room_event` 的键集合与键序保持不变（`flow`／`next_stage` 等兼容键继续写入，见 §6.1）。

## 1. 现状事实（契约据此写；落地前不改这些事实）

### 1.1 两条构建器实际是三条冻结路径

| 路径 | 触发 | 冻结结果形态 | 证据 |
| --- | --- | --- | --- |
| P1 原地（in_place） | 普通事件的非选择器选项 | `choice_definition.duplicate(true)` 后**就地**替换 `report`／`effects`／（可选）`item_rewards`／`detail`；键与键序＝作者对象 | `room_events.gd:54-65` |
| P2 分阶段（staged） | 普通事件的选择器选项、以及**全部**多阶段选项 | 新建固定字段序字典：`id, source_choice, label, reward, effects, next, report`，再按需 `show_pressure_sources`／`availability`／`item_rewards`／`detail`／`result_status`／`selected` | `room_events.gd:248-277,297-317` |
| P3 拒绝（refuse） | 节点声明 `allow_refuse` | `refusal(g)` 固定对象（含 `next:"result"`） | `room_events.gd:66,69-70,313` |

**推论**：`freeze_choice` 已经是普通选择器与多阶段共用的函数；本片剩下的工作是让 P1 与 P2
由同一入口按**显式声明**选择布局，而不是按"走哪条代码路径"。

### 1.2 求值顺序与随机消耗顺序（现状，必须逐项保持）

普通事件（`start`，逐选项）：

1. `reward=="relic" and available.is_empty()` → 丢弃（**冻结前**，不消耗随机）；
2. 有 `selector` → 每个 selection 调 `freeze_choice`：`outcomes` 加权抽取 → 合并效果 →
   `$selected` 替换 → `remove_restraints.targets` 归一 → `recipe` 编译 → `freeze_effects` →
   构建选项（含 `item_rewards`、`detail`）；
3. 无 `selector` → `effects`（或 `recipe` 编译）；`recipe` 编译为空且无 `effects` → 丢弃；
4. 效果 `resolve_effect_copy`；
5. 含生成器（`install_random`／`tighten_random`／`special_install_random`／`random_amount`）→ `freeze_effects`
   （失败即丢弃，**消耗随机**）；否则挂原始效果、**不消耗随机**；
6. `item_rewards` 冻结（消耗随机）；
7. `detail` 解析；
8. `hide_when_unavailable` 且 `probe_choice!=""` → 丢弃（探测本身不消耗随机）。

多阶段事件（`enter_stage`，逐选项）：

1. `when` 不满足 → 丢弃；
2. 有 `selector` → **先抽一次** `outcomes`，再把同一 outcome 复制给每个 selection；
3. `freeze_choice`（**无条件** `freeze_effects`）→ 失败即返回 `{}`（丢弃）；
4. 冻结后 `choice.reward=="relic" and room_event.relic==""` → 丢弃；
5. 节点级：`allow_refuse` → 追加 `refusal`；`options` 为空 → 返回"这一阶段没有能够执行的选项。"

**随机关键词**：`weighted`／`compile`／`freeze_effects`／`freeze_item_rewards` 的调用次序决定
`state.rng.event` 计数；`RelicRewards.offer` 用 `relic` 域、在 `start` 里按定义级 `offers_relic` 判定
调用一次。三者都不得改序、改次数、改判据。

### 1.3 资格四通道现值

| 通道 | 现状位置 | 现状语义 |
| --- | --- | --- |
| `condition_met`（`when`） | `room_events.gd:242-246` | 只服务多阶段；不满足即整条消失；只读事件计数或 selector 数量 |
| `availability_issue` | `:581-591` | 按 `kind` 硬编码 `no_chastity_lock`／`has_relic`；保留选项、给原因、`reason_surface="secondary"` |
| `hide_when_unavailable` 探测 | `:64`（普通）＋`probe_choice` `:573-579` | 普通显式声明时整条消失；多阶段**无条件**经冻结失败达到同样效果 |
| 遗物池闸门 | `:45`（普通，冻结前）／`:307,311`（多阶段，冻结后） | 普通按"遗物池为空"；多阶段按"本事件没有冻结到遗物" |

### 1.4 丢弃点现值（`docs/event-structure.md` §7.2 的 9 处＋1 处静默）

| # | 现状位置 | 现状原因 | 表现 |
| --- | --- | --- | --- |
| 1 | `start:45` | 遗物池为空（普通） | 静默丢弃 |
| 2 | `start:52` | `recipe` 编译为空（普通） | 静默丢弃 |
| 3 | `start:59` | 随机效果冻结失败（普通） | 静默丢弃 |
| 4 | `start:64` | `hide_when_unavailable` 探测失败（普通） | 静默丢弃 |
| 5 | `freeze_choice:261` | `recipe` 编译为空（共用） | 返回 `{}` |
| 6 | `freeze_choice:264` | 冻结失败（多阶段／普通选择器） | 返回 `{}` |
| 7 | `enter_stage:302` | `when` 不满足 | 静默丢弃 |
| 8 | `enter_stage:307,311` | 冻结后奖励遗物未被冻结 | 静默丢弃 |
| 9 | `enter_stage:314` | 节点没有任何可执行选项（唯一报错处） | 返回 issue |
| 10 | `start:47-49`／`freeze_choice` 外层 | `selector` 展开为空（两条路径都静默） | 零选项入列 |

### 1.5 定义形态现值与已知漂移

- 普通：顶层 `intro`＋`choices`＋`allow_refuse`；多阶段：`intro`＋`start_stage`＋`stages`＋
  `cleanup_effects`；两套白名单、两套默认值、两套 `effects` 上限（8／12）。
- 死代码：`start:53` 的选项级 `pressure`／`pressure_source` 分支，两套白名单都不收该字段，
  12 份内容 0 处命中、测试 0 处构造 → 不可达。
- 阶段 id 保留字只挡 `choice/keys/reward/result`，未挡 `battle`／`loot`（与事件战斗／道具奖励
  的 sentinel 阶段同名会撞 `snapshot` 校验）→ 现有内容未触发，属未验证风险。
- 多阶段选项校验调用 `_availability(choice.availability)` **未传 `data`**（`content_catalog.gd:308`），
  而 `has_relic` 分支要读 `data.relic`；12 份内容里 `has_relic` 只出现在普通选项，
  因此该组合**从未被内容或测试覆盖**（未验证路径，不是已证实的失败）。

## 2. 统一后的定义形态（内容包 schema）

### 2.1 定义级字段（`kind:"event"`）

| 字段 | 必填 | 说明 |
| --- | --- | --- |
| `schema_version` | 是 | 事件升为 **2**（其他 kind 仍为 1）；见 §13 R4 |
| `kind` / `id` / `name` / `intro` / `pool` | 是（`pool` 可选，默认 true） | 与现状一致 |
| `start_node` | 是 | 起始节点 id；普通事件固定为 `choice` |
| `nodes` | 是 | 节点数组，1–12 项，顺序＝作者顺序（迁移时保留原阶段顺序） |
| `cleanup_effects` | 可选 | 与现状一致（定义级，≤8 项，只接受 `restore_held`） |

顶层不再有 `choices`／`stages`／`allow_refuse`；两者同时出现或残留一律拒绝（迁移完整性判据）。

### 2.2 节点级字段

| 字段 | 必填 | 取值／现值 | 对应现状 |
| --- | --- | --- | --- |
| `id` | 是 | 稳定 id。**单节点定义必须用 `choice`**（普通事件的唯一 sentinel 节点）；**多节点定义禁用** `choice`／`reward`／`result`／`battle`／`loot`／`keys`（sentinel 与战斗／道具奖励阶段占用） | 阶段 id |
| `title` / `intro` | 多阶段必填；普通节点**不得出现**（键缺失，不是空串） | 与现状一致；`view` 的拼接按"键存在"判定，保证普通事件 `intro` 逐字节不变 | `stages[].title/intro` |
| `allow_refuse` | 是 | **必填、无默认**：普通＝原顶层值（8 份全是 `false`）；多阶段＝该阶段现值（仅 `succubus_three_games.wager_card` 为 `true`） | `start:66`（默认 true）／`enter_stage:313`（默认 false） |
| `unavailable` | 是 | `"hide"`／`"disable"`：普通节点＝`disable`；多阶段节点＝`hide` | 隐式差异 (a) |
| `relic_gate` | 是 | `"pool"`／`"claimed"`：普通＝`pool`（冻结前查池）；多阶段＝`claimed`（冻结后查本事件冻结的遗物） | 隐式差异 (b) |
| `random_freeze` | 是 | `"generators"`／`"always"`：普通＝`generators`；多阶段＝`always` | 隐式差异 (c1) |
| `outcome_draw` | 是 | `"option"`／`"selection"`：全部＝`option`（选择器外抽一次再复制） | 隐式差异 (c2) |
| `frozen_form` | 是 | `"in_place"`／`"staged"`：普通＝`in_place`；多阶段＝`staged` | 隐式差异 (f)，E0 冻结 |
| `empty_node` | 是 | `"allow"`／`"fail"`：普通＝`allow`（保持零候选）；多阶段＝`fail`（返回具名 issue） | 隐式差异 (e) |
| `choices` | 是 | 1–6 项 | 与现状一致 |

### 2.3 选项级字段（合并后的唯一清单）

| 字段 | 取值 | 说明 |
| --- | --- | --- |
| `conditions` | 1–8 条条目的数组 | **规范拼写**（新增能力，R1 澄清的 trigger 系统）：每条 `{"kind":…, "mode":"optional"\|"hidden", "reason":…, …kind 字段}`；可叠加，两类模式可同时声明；求值语义见 §5.3。**B2 起接受**（B1 只收兼容拼写，裁定 A3） |
| `availability` | `{kind, ...}` | **兼容拼写**：等价于一条"按选项默认模式解析"的状态条件；只为 12 份内容与冻结产物键集而保留（§0.2、§13 R2） |
| `unavailable` | `"hide"`／`"disable"` | 可选覆盖节点默认；决定该选项**未被显式 `mode` 约束的条目**的默认模式；与 `hide_when_unavailable` 冲突即拒绝。**选项级覆盖 B2 起接受**（节点级已在 B1 生效，裁定 A3） |
| `hide_when_unavailable` | 布尔 | **兼容拼写**，等价 `unavailable:"hide"`（今日语义：状态条件与可行性探测**都**隐藏）；只为冻结产物键集而保留 |
| `when` | `{counter\|selector, equals/minimum/maximum}` | **兼容拼写**：等价于一条 `mode:"hidden"` 的实例条件；kind 集合由 §5 的单一声明派生 |
| `outcome_draw` | `"option"`／`"selection"` | 可选覆盖；只在有 `outcomes` 时有效 |
| `next` | `"result"`／节点 id／`{"event":"<id>","node":"<id>"}` | 缺省 `"result"`；跨事件形态见 §3.2 |
| `encounter`／`item_rewards`／`selector`／`outcomes`／`recipe`／`effects`／`report`／`report_variants`／`detail`／`result_status`／`show_pressure_sources` | 不变 | 白名单合并后，普通与多阶段**都可使用全部字段**（能力不再按结构分家） |

- 同一选项**不得**同时写 `conditions` 与 `availability`（两种容器只允许选一种）——否则拒收，
  避免同一份资格出现两个真相源。
- `mode` 只允许 `"optional"`（显示但禁用）与 `"hidden"`（不生成）；省略时按 §5.3 的模式解析
  （**B2 起接受**）。
- **布局判据（裁定 A12，就近写明，不留在代码注释里）**：冻结布局**不是**只看节点声明——
  `frozen_form=="in_place"` **且选项没有 `selector`** 时才用 in_place 布局，其余情况一律 staged。
  依据：§1.1 P2 已证实"普通事件的选择器选项历来由共享 staged 构建器冻结"；若只按节点声明选布局，
  `temper`／`dissolve` 这类选项的冻结 `id`（含 `__<实例id>` 后缀）与 `selected` 键会变 → E0 必红。
  节点声明仍决定 staged 节点的整体布局，`frozen_form=="staged"` 时任何选项都不走 in_place。
- **冻结产物键集（兼容要求，不是设计目标）**：用兼容拼写的内容，冻结选项里保留原键
  （`availability` 原对象、`hide_when_unavailable` 原布尔、`when` 不进 staged 布局）；
  用规范拼写 `conditions` 的新内容，冻结选项携带 `conditions` 数组（含 `mode`）。
  两者由 §6.3 的存档校验同时接受，且都由 §5 的同一张声明表派生。

删除：选项级 `pressure`／`pressure_source`（死分支，无内容、无测试可达）。

### 2.4 编译后注册表形态

`Data.TYPES[id]` **就是**作者形态（同一份定义，不做第二套内部结构）。禁止再出现
`definition.choices`／`definition.stages`／`definition.start_stage` 三种并行访问：统一走
`Events.definition(id)`／`Events.node(definition, node_id)`／`Events.node_ids(definition)`。

### 2.5 校验规则合并取值（人审：取并集并逐条登记）

合并＝**并集，只放宽不收紧**（现有 12 份内容在新旧两套取值下都合法，见 §8.1）。
每条放宽项必须同时登记既有反例断言／夹具的期望更新；**不得删除任何反例，只允许改写路径或新增**。

| # | 放宽项 | 现状普通 | 现状多阶段 | 合并后（并集） | 既有反例断言／夹具的期望更新（逐条） |
| --- | --- | --- | --- | --- | --- |
| 1 | `effects` 上限 | 8 | 12 | 12（`outcome.effects` 另计 12） | 无既有反例（没有 9–12 项普通选项的拒绝用例）→ 新增"12 项接受／13 项拒绝"用例 |
| 2 | 空 `effects` | 只允许无奖励离开／战斗选项 | 允许任何 reward | 允许（含带 reward） | `content_cases.gd` 的 `bad_encounter`／`bad_victory_effect`／`bad_item_rewards`／`duplicate_item_groups` 用的 reward 是 `none`，拒绝理由与空 `effects` 无关 → 期望不变；新增"阶段选项空 `effects`＋reward `common`"正例 |
| 3 | `hold_special`／`restore_held` | 禁止（`_references` 有专门拒绝分支） | 允许（key 唯一＋cleanup 配平） | 允许（保持 key 唯一＋cleanup 配平） | 无既有反例（`event_flow_cases` 用的都是正例）→ 删除普通拒绝分支，新增"普通节点声明 `hold_special` 且 cleanup 配平通过／不配平拒绝"两例 |
| 4 | `recipe` 与 `effects` | 必须且只能一个 | 不能同时出现 | 不能同时出现；允许只有 `outcomes` | 无既有反例 → 新增"只有 `outcomes` 接受／`recipe`＋`effects` 拒绝"两例 |
| 5 | `allow_refuse` | 顶层默认 true | 每阶段默认 false | 节点必填、无默认 | `content_cases.gd:142` `bad_refusal`（字符串值）路径改 `nodes[0].allow_refuse`，仍拒绝；新增"缺 `allow_refuse`"反例 |
| 6 | 节点 id 保留字 | — | 挡 `choice/keys/reward/result` | 单节点必须 `choice`；多节点追加挡 `battle`／`loot` | 无既有反例 → 新增"多节点用 `battle`／`loot` 拒绝"与"单节点非 `choice` 拒绝"两例 |
| 7 | 起始节点免费出口 | — | 必须可离开 | 保持（`allow_refuse:true` 或无条件免费离开） | `event_flow_cases.gd:468` `flow_no_exit` 路径改 `nodes[0].allow_refuse`，断言不变 |
| 8 | 奖励选项的 `next` | 无 `next` | 必须 `"result"` | 带 reward 的选项必须结束事件（`"result"`） | 无既有反例（守卫在 `_flow_next`／reward 检查里）→ 新增"带 reward 且 `next` 指向节点即拒绝"一例 |

**非放宽项但必须同批登记的路径改写**（断言与语义不变，只改访问路径）：

| 位置 | 现状 | 合并后 |
| --- | --- | --- |
| `tests/content_cases.gd:26,29,30,33,39,43,46,53,60,65,70,75,81,88,94,105,113…` | `document.data.choices[0]…`、`tables.event[id].choices[0]…` | `document.data.nodes[0].choices[0]…`、`tables.event[id].nodes[0].choices[0]…` |
| `tests/content_cases.gd` 全字段类型反例 | 事件文档字段集＝`schema_version/kind/id/name/intro/pool/choices/allow_refuse` | 字段集＝`schema_version/kind/id/name/intro/pool/start_node/nodes`（4 个非法值仍逐项拒绝） |
| `tests/event_flow_cases.gd:95-140`（`document()` 夹具）、`:411`（模板读取）、`:466-486`（8 个反例） | `data.stages[0]`、`data.start_stage`、`data.cleanup_effects` | `data.nodes[0]`、`data.start_node`、`data.cleanup_effects`（cleanup 仍在定义级） |
| `tests/event_flow_cases.gd:667`（`trapped_definition`） | `.stages`／`.start_stage` | `.nodes`／`.start_node` |
| `tests/event_cases.gd:32-37` | `spec.has("choices")` 分支 | `spec.nodes.size()==1` 与多节点两条分支 |
| `tests/event_ui_cases.gd:233` | `Catalog.compile(ui.game,[Flow.document()])` | 夹具随形态改写，断言不变 |
| `content/templates/event.json`、`event_multistage.json.disabled` | 旧形态 | 新形态（§8.1），`content_cases.gd:12` 的"5 份模板"断言不变 |

`build/event-oracle-20260916/event_oracle.gd` 只读 `Data.TYPES[id].name` 与键集合，**不改**，
E0 命令保持不变。

**第 7 行的读法（裁定 A2，B1 已按此落地）**：该规则**只约束多节点（staged）定义**。
单节点定义可以是强制事件（`allow_refuse:false`、无无条件免费出口）——字面地把规则扩展到单节点
会让四份已发布强制事件立即非法，与"只放宽不收紧"冲突。登记为读法而非新规则，
改动它必须重新人审。

**并集白名单的过渡态（裁定 A1，B1 现存事实，必须登记）**

B1 的单一白名单让**单节点**选项也能编译 `next`／`when`／`outcomes`／`encounter`／`item_rewards`。
逐项现状（B1 实测）：

| 键 | 单节点现状 | 说明 |
| --- | --- | --- |
| `encounter`／`item_rewards` | **已生效** | 原普通路径本就支持（冻结与执行都在 in_place 分支里） |
| `next` | **恒为 `"result"`** | 非 `"result"` 时校验先拒（`_flow_next` 不允许指向自身/回退）；运行期不读 |
| `when` | **不生效** | 只被 `enter_node` 读取，单节点走 `start` 的 in_place 分支 |
| `outcomes` | **仅在选择器选项上生效** | 无 selector 的选项不读；**有 selector 的选项经 `freeze_choice` 时按"每个 selection 抽一次"**（＝声明值 `outcome_draw:"selection"`），与节点声明的 `"option"` 暂不一致 |

这是**有意的过渡态，不是漏做**：

1. B2 同批让四者全部按节点声明生效（含把单节点选择器选项的 outcome 抽取改为遵循
   `outcome_draw` 声明）；判据是 §10 场景 08（统一选项能力）＋ 场景 05（单声明）；
2. **B2 落地前不得打包、不得发版**（写进 §12 的"算未完成"）；
3. B2 前任何内容包不得在单节点上使用 `next`／`when`／`outcomes`；现有 12 份内容与 E0 夹具
   都不使用（E0 已覆盖此点），新内容按本契约写。

## 3. 节点与事件链模型

### 3.1 节点即阶段

- 运行期 `state.room_event.stage` 就是当前节点 id；sentinel 值 `choice`（普通事件的唯一节点）、
  `reward`、`result`、`battle`、`loot` 沿用现状语义。
- 普通事件的节点 id 固定为 `choice`：`view`／`validate`／`snapshot` 的既有阶段集合因此逐字不变
  （普通 `["choice","reward","result"]`，多阶段 `["reward","result"]+node_ids`）。
- `Events.node_ids(definition)` 是唯一的节点枚举入口（替换 `flow_stage`／`definition.stages`）。

### 3.2 `next` 的统一形态

`next` 指向三种目标，均由**同一个解析入口**（`Events.next_target`）解释：

1. `"result"`：结束事件（sentinel）；
2. `"<node_id>"`：同一定义内的后继节点；定义内**只能向后**（保持现状校验，不引入倒退与环）；
3. `{"event":"<id>","node":"<node_id>"}`：跨事件跳转，形成事件链。

### 3.3 链的运行时表示与不变量

| 项 | 规则 |
| --- | --- |
| 实例容器 | 同一次进入仍只有一个 `room_event`；跳转时重写 `id` 与 `stage`，不新建实例 |
| 计数 `values` | 链上共享（计数跨事件继续累加） |
| 暂存 `held` | 链上共享；暂存 key 在整条链上唯一 |
| `cleanup_effects` | 链上**并集**（按 `key` 去重）；离开（`leave`）时按并集逐条执行一次 |
| `room.event` | 保持抵达时抽取的 id（`history_issue` 与 `event_seen` 判据不变） |
| `event_seen` | 链上目标事件加入 `event_seen`（不得被本局再次抽到） |
| `flow` 镜像 | 每次跳转按当前定义是否有 >1 个节点重写（兼容键，见 §6.1） |
| 新键 `chain` | **只在真的发生跨事件跳转时**写入：`chain:[event_id,...]`（抵达即不含该键） |
| 环 | 目标事件已在当前实例 `chain` 中 → 该选项在候选阶段 `disabled`，gate=`chain_loop`；静态校验另拒绝"事件引用自身" |

### 3.4 安全规则

- 同一定义内的 `next` 保持现状校验（不倒退、不循环、必须已声明）；
- 跨事件跳转的目标必须已登记，且目标定义必须是多节点或普通形态都合法；
- 事件链**不得**出现在 12 份迁移内容里（E0 只覆盖单定义事件；链只在夹具与专门场景使用）。

## 4. 单一求值入口（资格通道整合）

### 4.1 接口

```gdscript
# 唯一求值入口：任何"这条选项现在是什么状态"的判断都走这里（含叠加条件的聚合）
# request={"definition":Dictionary,"node":String,"choice":Dictionary,
#          "selected":<empty|Dictionary|Array>,"purpose":"arrival"|"candidate"|"probe"|"execute"}
# 返回 {"decision":String,
#       "gates":Array[Dictionary],   # 全部命中条目，按声明顺序；每条 {"gate","kind","mode","index","detail","reason"}
#       "gate":String,               # 兼容单值 = 首个命中的 gate（无命中为 ""）
#       "reason":String,             # 单条命中＝原文；多条 optional 命中＝按声明顺序 "\n" 连接
#       "option":Dictionary}
static func evaluate_option(g, request: Dictionary) -> Dictionary

# 唯一的条目解析入口：把作者声明＋节点策略解析成规范条目列表（校验与求值共用，§5）
static func condition_entries(node: Dictionary, choice: Dictionary) -> Array

# 节点级构建／推进：普通与多阶段共用
static func enter_node(g, node_id: String) -> String   # "" = 成功；否则具名 issue（替换 enter_stage）

# 请求装配器（B2 核心已落地）：从"当前实例 + 冻结选项"还原出 request 的**唯一**构造点，
# 供 candidates／probe／execute／测试复用；它只装配，不做任何判定。
static func request_for(g, option: Dictionary, purpose: String) -> Dictionary
```

- 生成侧：`start`（起始节点）与 `execute`／`probe` 的节点推进都调用 `enter_node`；
  `enter_node` 内部对每个作者选项调用 `evaluate_option`。
- 消费侧：`candidates`（`purpose:"candidate"`）、`probe`／`probe_choice`（`purpose:"probe"`）、
  `execute`（`purpose:"execute"`）都从同一入口取"决定＋具名原因"，不再各自重算资格。
- `gates` **必须按条目逐条记录**：同一选项命中多条条件时，不许只留一个笼统原因；
  `gate`／`reason` 只是给旧签名的兼容投影。
- 入口**只读**（与 `probe` 同款：状态副本＋恢复），唯一写状态的分支是 `enter_node` 在
  `purpose=="arrival"` 时把冻结选项写入 `state.room_event`。

### 4.2 结果词汇与具名 gate

`decision`（由 `gates` 按 §5.3 聚合）：

| 值 | 含义 | 现状对应 |
| --- | --- | --- |
| `generated` | 已生成且当前可执行（`gates` 为空） | 冻结成功且候选 `valid` |
| `dropped` | **未生成**（结构性闸门，冻结前） | 1／2／5／10 与 `when` 不满足 |
| `hidden` | 生成后被**隐藏**（有 `hidden` 模式条目命中；可同时带 `optional` 命中） | 3／4／6／8 与多阶段的隐式隐藏 |
| `disabled` | 生成但**禁用**（只有 `optional` 模式条目命中；列出全部命中条目） | 普通事件保留 `availability`／效果不可行时的候选 |

`gate` 具名清单（全部具名，无静默丢弃；每条命中都带 `index`（条目序号）＋`kind`＋`mode`＋`detail`，
因此可区分到**每条条件**；`validate_failed`／`node_empty` 两条见下表的 B3 标注）：

| gate | 明细字段 | 现状出处 |
| --- | --- | --- |
| `condition_unmet` | `kind`＝`counter`／`selector_count`，`detail`＝key／selector.kind | `enter_stage:302` |
| `availability_unmet` | `kind`＝状态条件种类（§5 表），`detail`＝`""` | `availability_issue` |
| `relic_pool_empty` | `kind`＝`relic_pool` | `start:45`（`relic_gate:"pool"`） |
| `relic_already_offered` | `kind`＝`relic_offered` | `enter_stage:307,311`（`relic_gate:"claimed"`） |
| `selector_empty` | `kind`＝`selector` | `start:47-49`／selector 展开为空 |
| `recipe_empty` | `kind`＝`recipe` | `start:52`／`freeze_choice:261` |
| `freeze_failed` | `kind`＝`feasibility`（`random_freeze`） | `start:59`／`freeze_choice:264` |
| `probe_failed` | `kind`＝`feasibility` | `probe_choice` 的效果探测失败 |
| `encounter_invalid` | `kind`＝`feasibility` | `probe_choice` 的战斗记录或胜利效果探测 |
| `validate_failed` | `kind`＝`feasibility` | `probe` 末尾 `g.validate()`——**B2 未单独命名**（要与 `probe_failed` 分离须拆 `probe()` 内部），**B3 收口**（裁定 A13） |
| `node_empty` | 节点级（`enter_node` 的 issue） | `enter_stage:314`——**B2 仍以既有 issue 文案返回、未记 gate**，**B3 收口**（裁定 A13） |
| `chain_loop` | `kind`＝`chain` | 新增（§3.3）；B4 落地 |

`reason` 一律为**现状字符串原文**（候选原因、issue 文案），不得改写措辞；多条 `optional` 命中时
的新拼接规则见 §5.3（现有内容最多一条，原文不变）。

### 4.3 求值顺序（按声明参数化，必须与 §1.2 等价）

```
evaluate_option(purpose):
  E. entries=condition_entries(node, choice)        # 规范条目（§5），声明顺序
  0. 实例条件（when／selector_count）命中 → 记 gate condition_unmet
  1. relic_gate=="pool" 且名义 reward=="relic" 且遗物池为空 → 记 gate relic_pool_empty
  2. 有 selector:
       selections=selector_selections(...)；为空 → 记 gate selector_empty
       outcome_draw=="option" 且有 outcomes → weighted() 抽一次
       逐 selection: freeze_one()
     无 selector: freeze_one()
  3. relic_gate=="claimed" 且冻结后 reward=="relic" 且 room_event.relic=="" → 记 gate relic_already_offered
  4. 按 freeze_one 的结果与状态条件条目：命中则记 availability_unmet／freeze_failed…
  5. 聚合 gates（§5.3）→ decision／reason；hidden 或 dropped 时该选项不进入 options
freeze_one():
  a. 有 outcomes 且 outcome_draw=="selection" → weighted() 抽一次（每 selection 一次）
  b. recipe → compile()；为空 → 记 gate recipe_empty
  c. 效果合并／$selected 替换／remove_restraints 归一（顺序同 `freeze_choice`）
  d. random_freeze=="always" 或效果含生成器 → freeze_effects()；issue → 记 gate freeze_failed
  e. 按 frozen_form 组装（in_place＝作者对象就地更新；staged＝固定字段序）
  f. item_rewards 冻结 → detail 解析 → result_status/selected 落位
  g. 可行性探测（含状态条件）在 arrival 时可按模式隐藏、在 candidate 时给原因（§4.4）
```

**顺序是判据的一部分**：第 1 步在冻结前、第 3 步在冻结后，正是 `relic_gate` 声明的语义；
把任一闸门挪位会改变 `event` 域消耗 → E0 红。条目**求值顺序**不影响随机消耗（只影响 `gates` 顺序
与 `reason` 拼接），但必须按声明顺序记录，保证 trace 与原因可复现。

### 4.4 各 purpose 的检查清单（必须逐项等价，不得多不得少）

| purpose | 执行到哪一步 | 现状依据 |
| --- | --- | --- |
| `arrival` | 全部（含 4 步的 hidden 丢弃），并把结果写入 `room_event.options` | `start`／`enter_stage` |
| `candidate` | 第 4 步的探测结果只影响 `valid/reason`；不写状态；`hidden` 的选项不会出现在这里（arrival 已丢掉） | `append_choice_candidate`→`probe_choice` |
| `probe` | 同 `candidate`，另在"有后继节点且 reward=="none""时探测后继节点（现状的 `flow` 分支由 `next!="result"` 取代） | `probe:566` |
| `execute` | **只**复核 `optional` 模式的状态条件（现状只查 `availability`，不得改成全量探测，否则拒绝文案会变） | `execute:641` |

`reason_surface="secondary"` 的判定改为：`decision=="disabled"` 且 `gates` 非空且**每条命中都是
状态条件条目**（`kind` ∈ §5 表）；不再二次调用 `availability_issue`（同一结果，去掉平行真相）。
现有内容每次最多命中一条状态条件 → 与现状逐字节相同。

### 4.5 trace（debug 开关）

- 落点：**只挂在游戏对象上的调试字段**（默认关闭；实现可经元数据或普通字段，§A20）：
  **不进 `state`／不进 View／不进存档／不渲染／不做成计数器**；接口为 `Events.trace_enabled(g)`／
  `Events.event_trace(g)`／`Events.trace_entry(g,fields)`，清空必须走同一接口（`Events.clear_trace(g)`）。
- 条目：`{"event","node","source_choice","option_id","decision","gate","kind","mode","index","reason","purpose"}`
  （11 字段；`node_empty`／`stage_missing` 这类**无选项**的行不带 `option_id`／`source_choice`）。
- **字段语义（钉死，裁定 A25；此前只有字段名没有定义，导致断言口径分歧）**：
  1. `index` ＝ **该条件条目在其选项声明列表中的下标，从 0 起**：规范拼写 `conditions` 取数组下标；
     兼容拼写 `availability` 恒为 `0`。**同一选项在任意一次求值中取值相同**（与 `purpose` 无关）。
     非条件类 gate（`condition_unmet`／`relic_pool_empty`／`relic_already_offered`／`selector_empty`／
     `recipe_empty`／`freeze_failed`／`probe_failed`／`encounter_invalid`／`validate_failed`／
     `held_pending`／`chain_loop`）的 `index` 是**本次求值里的记账位置**，沿用现状（状态条件之后＝
     `entries.size()`）；**它不参与跨 purpose 比较**，也不得被断言当作稳定标识。
  2. `source_choice` ＝ **作者选项 id**（选择器选项**不含** `__<实例>` 后缀）。
  3. `option_id` ＝ **本次求值的冻结实例 id**：非选择器选项＝作者 id；选择器选项＝
     `<作者 id>__<实例 id>[__<实例 id>…]`，与 `room_event.options[*].id`、候选 `payload.choice` 同值。
     **现状实现把 `source_choice` 与 `option_id` 写成同一个值（`room_events.gd:210,398`）→ B3b 必修**
     （D1 的一部分），否则选择器选项的断言无法建立。
  4. `node`：普通求值行＝当前 `room_event.stage`；节点入口失败行（`node_empty`／`stage_missing`）＝
     **被尝试进入的节点 id**（该行以 `gate`＋`node`＋空 `option_id` 识别）。
- **行集合不变量（裁定 A25）**：
  - **状态条件行**（`kind` ∈ §5.1 声明表）：同一选项在 `arrival`／`candidate`／`probe` 的**任意两次求值**
    产出**逐字段相同**的行，**唯一允许变化的是 `purpose`**（`reason` 对状态条件恒为作者原文）。
    **缺行即实现缺陷**，不是"上下文差异"。
  - **非条件行**：按阶段产生（如 `freeze_failed` 只在 `arrival`、`validate_failed` 在探测阶段），
    **不做跨 purpose 相等承诺**；承诺是"同一次求值内每个命中各一行、不重复、按声明／求值顺序追加"。
  - **禁止按 trace 总行数断言**：trace 是**追加流水**（同一选项可有多行，跨求值累积、跨事件由
    `start` 清空）；断言必须按 `(purpose, source_choice, option_id, gate|kind, index)` **过滤后判定**。
    本轮夹具写死计数而误红，根因即此。
- 每次 `start` 在启用时清空（经 `Events.clear_trace(g)`，同一存储）；`enter_node`／`evaluate_option`／
  `probe_choice` 写入；测试显式开启后断言。
- 硬约束：开启与关闭时 `candidates`／`view`／`options`／`snapshot`／`rng` 摘要必须相同
  （用 E0 跑两遍证明，且**两遍都要核引擎错误日志命中 0 行**，见 A24）；release 默认关闭，运行不产出。
- 不新增 `game.event_diagnostics()`（先前未授权），不加 View 字段。

## 5. 状态条件的单一声明与叠加求值

### 5.1 声明表与四处派生

单一声明落在 `core/room_events.gd`（不新增文件、不新增依赖边）：

```gdscript
# 唯一声明：一种条件一行；新增条件只改这里。
# required/optional＝该条目的作者字段；check＝内容校验；probe(g, entry) -> bool＝是否命中；saved＝存档键集
static var CONDITIONS={
  "no_chastity_lock":{"required":[],"optional":[],"check":Callable,"probe":Callable},
  "has_relic":{"required":["type"],"optional":[],"check":Callable,"probe":Callable},
}
```

条件**条目**（entry）是统一后的求值单位，规范形状：

```
{"kind":"has_relic"|"no_chastity_lock"|…, "mode":"optional"|"hidden", "reason":String, <kind required 字段…>}
```

四种派生（都读同一张表，`core/` 内禁止再写 kind 字面量）：

| 消费者 | 派生接口 | 现状平行真相 |
| --- | --- | --- |
| 条目解析 | `Events.condition_entries(node, choice) -> Array`（作者拼写＋节点策略 → 规范条目，含每条的模式） | 两套路径各自在代码里决定 |
| 内容校验 | `Events.condition_issue(g, entry, data) -> String`（逐条目，含 `mode` 合法性） | `content_catalog._availability`（且多阶段路径漏传 `data`） |
| 运行时求值 | `Events.condition_probe(g, entry) -> bool`（被 `evaluate_option` 调用） | `availability_issue` 内的 `match` |
| 存档校验 | `Events.condition_saved_fields(kind) -> Array`（＝`["kind","reason"]+required`） | `snapshot.gd:389-397` 手写键集 |

配套：`Events.condition_kinds() -> Array` 给测试枚举；`condition_issue` 校验未登记 kind 时返回
与现状一致的拒绝文案（"尚未支持这种状态条件。"）。

### 5.2 作者拼写 → 规范条目（四种现有拼写都在此收敛）

| 作者拼写 | 解析出的条目 | 模式（§5.3 解析） | 现状出处 |
| --- | --- | --- | --- |
| `availability:{kind,reason,…}` | 1 条状态条件 | 状态条件默认 `optional`；`hide_when_unavailable:true` 时为 `hidden` | `floating_belt_cluster.leave`（has_relic）、`mysterious_woman_statue.offering.use_sleeve`（no_chastity_lock） |
| `when:{counter\|selector,…}` | 1 条实例条件（`counter`／`selector_count`） | 固定 `hidden` | `succubus_three_games` 的 10 处 counter 条件、`mysterious_woman_statue` 的 1 处 selector 条件 |
| `hide_when_unavailable:true` | 1 条可行性条件（`kind:"infeasible"`，明细由探测给出 `probe_failed`／`encounter_invalid`／`validate_failed`） | 固定 `hidden` | 6 处选项 |
| 节点 `relic_gate` | 1 条奖励遗物条件（`relic_pool`／`relic_offered`） | 固定 `hidden` | 普通＝池闸门、多阶段＝冻结后闸门 |
| `conditions:[…]`（规范拼写） | 逐条解析，两类模式可混 | 每条自带 `mode` | 新增能力，本片无内容使用 |

### 5.3 模式解析与叠加求值语义（本片最终规则）

**模式解析（优先级由高到低）**：

1. 条目自带 `mode`（只在规范拼写 `conditions` 下允许）；
2. 选项 `unavailable`（`"hide"`→`hidden`／`"disable"`→`optional`）；
3. `hide_when_unavailable:true` → `hidden`（今日语义：状态条件与可行性**都**隐藏）；
4. 种类默认：状态条件＝`optional`（显示但禁用）；可行性条件＝节点 `unavailable` 默认
   （普通节点 `disable`、多阶段节点 `hide`）；实例条件与奖励遗物条件＝`hidden`。

**叠加求值（同一条目列表内，AND 语义）**：

1. 所有条目都要满足才算"通过"；命中（不满足）的条目按声明顺序收集进 `gates`；
2. 聚合优先级：**任一 `hidden` 命中 → `decision="hidden"`**（其余命中一并记进 `gates`）；
3. 否则任一 `optional` 命中 → `decision="disabled"`，`gates` 列出**全部**命中的条目；
4. 全部通过 → `decision="generated"`，`gates` 为空；
5. `reason` 拼接：单条命中＝该条 `reason` 原文（现有内容走这条，逐字节不变）；
   多条 `optional` 命中＝按声明顺序用 `"\n"` 连接；`hidden` 命中的 `reason` 供 trace 与节点 issue 使用。

**与现状的等价性（12 份内容，逐项）**：每份内容的每个选项最多解析出**一条**状态条件条目，
模式与现值一致（`floating_belt_cluster.leave`＝`optional`＋隐藏覆盖、`mysterious_woman_statue`
的 `use_sleeve`＝`optional`、`when`＝`hidden`），因此 `gates` 长度恒为 0 或 1，
`reason`／`reason_surface`／`decision` 与现状逐字节相同 → E0 不变。

### 5.4 验收点：新增条件只改一处、叠加不改变现有内容

- `condition_kinds()` 的集合，必须与**内容校验**能接受的集合、**运行时求值**能求值的集合、
  **存档校验**能接受的集合**三处相等**（条目解析 `condition_entries` 是三者共用的一条路径，
  不单独决定 kind 集合）；测试对每个 kind 各跑一遍"编译通过＋求值有结果＋存档往返通过"，
  并对未知 kind 跑一遍三处一致拒绝。
- 回归对照：`tests/persistence_cases.gd:event_conditions`（`has_relic` 往返＋5 类畸形拒绝）保持通过；
  `tests/content_cases.gd` 的 `has_relic` 正例与三类反例保持通过。
- 撤销任一消费者的派生（回到手写列表）必须让这条用例变红——这是本条判据的"反向对照"。
- 叠加能力上线后，12 份内容的 `decision`／`gates`／`reason` 在 E0 94 场景下不变（见 §10 场景 20）。

## 6. 存档表示

### 6.1 冻结产物逐字节不变（**E0 硬判据带来的兼容要求，不是设计目标**）

`room_event` 的键集合与键序、冻结选项的字段布局都**保持不变**（`flow`、`next_stage`、`held`、
`values`、`cleanup_effects`、`refs`、`reward`、`winner`、`relic` 继续原样写入）。
**这不是"要保留双布局"的设计意图**：按人审 R1 澄清，终态是后端 trigger 系统（条件可选／条件隐藏／
可叠加，§5）与单一定义形态＋单求值入口；冻结产物的两套布局之所以并存，只因为 E0 把"玩家可见不变"
钉在了逐字节摘要上（§0.1）。因此：

- 新内容用规范拼写（`conditions` 等）时不受旧布局约束，冻结算法规格见 §2.3；
- 旧内容的兼容布局由**一条声明**（`frozen_form`）选择，而不是两套构建器；**布局判据（裁定 A12）**：
  `frozen_form=="in_place"` **且选项无 `selector`** → in_place 布局；其余一律 staged
  （普通事件的选择器选项历来由共享 staged 构建器冻结，见 §1.1 P2）。该判据写在 §2.3 与本节，
  不只留在代码注释里；改它必须重新人审（会让 `temper`／`dissolve` 的冻结 id 与 `selected` 键变化）；
- 若将来人决定放松 E0 判据（重取基线），删除兼容布局只需要把 `frozen_form` 与兼容拼写移除，
  求值入口、声明表、条目解析都不受影响——这正是"兼容层可拆"的判据。

`flow` 与 `next_stage` 在新实现里降级为**兼容镜像**：`flow` 仍按定义节点数（>1）写入，
`next_stage` 仍写 `""`（现状从未赋值），但**不再有任何运行分支读它们**（B2 核心已落地：
`room_events.gd` 内 `get("flow")` 读取为零；`probe`／`candidates`／`execute`／`validate`／`view`
的分支由 `next` 的声明形态与 `node_ids` 取代）。

### 6.2 新增键只在链实际发生时出现

`chain` 只在跨事件跳转后出现（§3.3）；用规范拼写 `conditions` 的新内容才会在冻结选项里出现
`conditions` 键——12 份迁移内容与 E0 夹具都不产生这两个键。

### 6.3 事件段存档校验改为按"选项自身形态"判定

- 基础形状（`id/label/detail/reward/effects`＋`result_status`）保持；
- **新增**：`option.has("next")` 时要求 `next:s`／`report:s` 且 `source_choice∈declared`
  （`declared`＝该节点选项 id ＋ 节点 `allow_refuse` 时的 `refuse`）——
  由 `flow` 标志分支改为按选项键判定；`staged` 选项都有 `next`，`in_place` 选项都没有，
  因此现状两种内容的结论不变；
- **状态条件两条分支，都从 §5 的同一张表派生**：
  - `option.availability`（兼容）：键集恰好等于 `condition_saved_fields(kind)`（现状不变）；
  - `option.conditions`（规范）：必须是 1–8 条数组，每条键集恰好等于
    `condition_saved_fields(kind)+["mode"]`，且 `mode∈{"optional","hidden"}`；
  - 两种键**不得同时出现**；未知 kind／多余键／缺字段一律拒绝；
- 节点集合判定用 `node_ids(definition)` 替换 `definition.stages`；
- `values`／`held`／`cleanup_effects` 的检查保持（两种形态的实例本来就都带这些键）。

**B2 的完成方式（裁定 A4，必须增量、不得放宽）**：B1 保留了现有 `flow` 分支的全部检查，
只把定义访问改走访问器。B2 必须**同时**做到：①保留现有分支检查（`flow` 实例的
`held/values/cleanup_effects/next_stage`、阶段集合、`source_choice∈declared`）；②新增
`conditions` 条目的键集与 `mode` 检查；③新键检查不得成为放宽的替代品——**禁止**用
"按选项键判定"删掉或弱化任何既有断言；`tests/persistence_cases.gd:event_conditions` 保持通过。

### 6.4 启动期迁移脚本（**人审：不落地，设计留档**）

人审结论（2026-09-16，记录见文件头）：**不落地迁移脚本**，不改启动链；本节只留档设计，
供将来真正改变存档形态时复用。

**为什么现在不需要**：§6.1 按 E0 硬判据保持存档形态不变，旧档由新代码直接读取；
没有可迁移的差异，强行迁移只增加误写风险。

留档设计（若将来需要）：

- 位置：`spire-godot/tools/migrate_saves.gd`（`SceneTree` 脚本，用引擎解析 `user://saves/`）＋
  可选 `tools/migrate.ps1` 包装（复用 `find-godot.ps1` 的引擎定位）。
- 触发时机：`tools/launch.ps1` 启动游戏**之前**串行执行一次；游戏本体不读旧格式。
  检查／测试路径不触发（测试用隔离目录）。
- 幂等：逐槽按文件内容判定（目标格式标记写入 `payload`），不依赖全局标记文件；
  已迁移文件直接跳过；**不降级**（新格式遇到旧代码即现状的"不兼容"提示）。
- 失败与备份：先复制 `<slot>.json` → `<slot>.json.premigrate`，再走 temp→校验→rename 的原子替换
  （复用 `core/save_store.gd:133` 的写法）；任一步失败保留原文件、写 `<slot>.json.migration-failed`
  记录、**不阻塞游戏启动**（游戏按现有"版本不兼容"路径提示并从主界面开始新局）。
- 验收：迁移一个真实旧档后，`-Suite persistence` 与读档继续路径通过；重复运行两次结果相同；
  人为损坏一份存档时原文件保持可读。

## 7. 模块切分、接口与依赖规范草案

### 7.1 模块与接口

| 模块 | 小接口 | 内部（藏） |
| --- | --- | --- |
| 事件定义 | `Events.definition(id)`、`Events.node(definition,node_id)`、`Events.node_ids(definition)` | 节点查找、sentinel 集合 |
| 事件求值 | `Events.evaluate_option(g, request)`、`Events.condition_kinds()/condition_issue()/condition_saved_fields()` | 声明表、探测副本、gate 命名、trace |
| 事件管线 | `Events.start(g,id)`、`Events.enter_node(g,node_id)`、`Events.execute(g,c)`、`Events.probe(g,…)` | 冻结、RNG 顺序、节点推进、链路由 |
| 事件投影 | `Events.view(g)`、`Events.candidates(g,out)` | 分组身份、intro 拼接 |
| 内容编译 | `ContentCatalog.compile/_definition/_references` | 单一形态校验、引用解析 |
| 存档校验 | `Snapshot.check`（事件段） | 形状、键集、链字段 |

保持不变的既有接口：`start`／`view`／`candidates`／`execute`／`validate`／`history_issue`／
`probe`／`probe_choice`／`availability_issue`／`selector_values`／`freeze_effects`／`apply_effects`／
`describe`／`describe_result`／战斗桥与道具奖励入口。重命名只允许一处：`enter_stage` → `enter_node`
（外部调用点只有测试，同批更新；**不得**保留同名别名）。

### 7.2 允许依赖方向（本片不变）

`data/* → core/room_events → core/game → core/game_view → ui/*`；`core/content_catalog → data/*`
（经 `g.*` 注册表）；`core/snapshot → core/room_events`（经 `g.Events.*`，**无新增 preload**）。
禁令：core 不得 preload ui；事件模块不得新增 preload 到装备／战斗模块之外的边；
`view` 不得新增只读字段；测试不得成为生产依赖。

### 7.3 文件与行数

- 本仓**没有源码行数门禁**：`docs/agent-guide.md`（2026-09-16 条目）已声明删除
  `tools/check_agents.py`、其单测与 `.github/workflows/agents.yml`；现存检查不读取 `.gd` 行数。
  模块规范只有"新增文件须有明确职责边界；大文件按职责拆，不按行数硬拆"。
- 因此**本片不新增 core 文件**（`room_events.gd` 现状 890 行、`content_catalog.gd` 509 行，
  增长量在本片范围内可控，且拆分既有文件属 E5，先前未授权）。
- 若人坚持 500 行硬线：最小清单为 `core/event_conditions.gd`（§5 的声明表与四处派生，约 90 行）
  与 `core/event_options.gd`（§4 的求值入口＋条目解析＋冻结管线＋trace，约 260 行），允许依赖
  `data/room_events`、`core/room_events`（回调方向需再定），**但这仍需先拆既有 890 行文件**，
  建议另开切片（原 E5）。

### 7.4 依赖规范（正式文件见 `docs/event-pipeline-dependency-spec.md`）

本契约的同批交付物：`docs/event-pipeline-dependency-spec.md`（cleaner 与架构分类的检查对象）。
摘要：

1. 事件相关模块的 `preload` 集合不得超出 `data/room_events.gd`、`data/relics.gd`、
   `data/card_rules.gd`、`core/*`（不含 `ui/`）；
2. `core/` 不得出现 `ui/` 字样（现状检查保持）；
3. 事件定义访问只经 `definition/node/node_ids` 三个接口：`core/` 内不得再出现
   `\.stages`／`start_stage`／`\.choices` 直读（普通节点的 `choices` 只允许出现在 `node` 返回值上）；
4. 状态条件 kind 只允许在 `CONDITIONS` 声明表内出现字面量；内容校验／运行时求值／存档校验
   三处枚举出的 kind 集合必须相等（由 §5.4 的用例执行，不靠源码扫描）；
5. 兼容拼写（`availability`／`when`／`hide_when_unavailable`）只允许出现在条目解析与冻结投影处，
   不得新增第二个消费点。

## 8. 内容迁移（12 份＋模板）

### 8.1 映射规则（逐字段，机械可执行）

普通 8 份（`abandoned_storeroom`、`alchemist_tasting_stall`、`bound_dream_guest_room`、
`enchanters_empty_studio`、`floating_belt_cluster`、`maze_survey_team`、`smuggled_mana_potions`、
`succubus_magic_pawnshop`）：

1. 顶层 `intro/name/id/pool` 保留；
2. 新建 `start_node:"choice"` 与单元素 `nodes`；节点写 `id:"choice"`、
   `allow_refuse:<原顶层值>`、`unavailable:"disable"`、`relic_gate:"pool"`、
   `random_freeze:"generators"`、`outcome_draw:"option"`、`frozen_form:"in_place"`、`empty_node:"allow"`；
3. 节点**不写** `title`／`intro`（键缺失）；
4. `choices` 原样搬入节点：**逐项不增删键、不改键序、不改值**（§8.2）；
5. 删除原顶层 `choices`／`allow_refuse`。

多阶段 4 份（`binding_cleric`、`bound_adventurer_relic`、`mysterious_woman_statue`、
`succubus_three_games`）：

1. 顶层 `intro/name/id/pool/cleanup_effects` 保留；
2. `start_stage` → `start_node`；`stages` → `nodes`，顺序不变；
3. 每个节点补 `allow_refuse:<原值>`、`unavailable:"hide"`、`relic_gate:"claimed"`、
   `random_freeze:"always"`、`outcome_draw:"option"`、`frozen_form:"staged"`、`empty_node:"fail"`；
4. `choices` 及选项字段原样保留（可选键可自由增删，staged 布局不回声作者对象）。

模板：`content/templates/event.json`（升 schema 2、单节点）与
`content/templates/event_multistage.json.disabled`（升 schema 2、多节点＋声明字段）。
生成来源：`content_catalog._definition` 里为 `special_equipment` 生成的内置到达事件
（`data.event[e.id+"_arrival"]`）也必须改名成节点形态，并显式写 `allow_refuse:true`
（原实现依赖顶层默认 true，否则玩家可见行为会变）。

### 8.2 digest 安全约束（写进实现与迁移脚本）

- 普通事件的 17 个非选择器选项：作者对象即冻结产物 → **键集合、键序、值三者都必须与今天逐字节相同**；
  JSON 重排（`sort_keys`）、格式化工具、顺手补键都会让 `options`／`snapshot` 摘要变红；
- 6 处 `hide_when_unavailable:true` 位置与取值保持不变（兼容拼写，§13 R2）；
- `report_variants`／`selector`／`availability`／`encounter`／`item_rewards` 等作者键
  在 in_place 路径上会原样留在冻结产物里，迁移不得删除；
- 多阶段／选择器选项进入 staged 布局，作者键不回声，但**产出字段的取值**必须一致
  （`next` 缺省 `"result"`、`report`／`result_status`／`detail` 的解析结果不变）。

### 8.3 文档影响与 B1b 交付清单（裁定 A6：B1b 同批补齐）

| 文档 | 需要的变更（执行批次） |
| --- | --- |
| `spire-godot/content/README.md` §3 事件（97–175 行） | 唯一作者手册：nodes/start_node、节点声明表、选项字段合并清单、schema 2、单节点禁用 `next`／`when`／`outcomes`；`has_relic` 键集说明保留（**B1b**；跨事件 `next` 与选项级 `conditions`／`unavailable` 缓到 B2／B4） |
| `spire-godot/content/templates/event.json`、`event_multistage.json.disabled` | B1 已迁移为真源；B1b 只核对其正文与文档示例逐字一致（**不改内容**） |
| `spire-godot/content/packs/README.txt` | 无字段说明，不需要改（B1b 复核一次） |
| `docs/content-templates.md` | §H 事件模板、H4 多阶段、H5 界面约定、§488 行测试表：字段与形态改为单一形态（**B1b**） |
| `docs/content-generation.md` | §7 事件生成与结算（242／275／279／285／289／291／295 行等）：两形态合并后的描述与"必须填写的声明"（**B1b**） |
| `docs/content-extension.md` | 事件流程段（133–150 行）与内容表（124 行）的事件行（**B1b**） |
| `docs/event-pipeline-dependency-spec.md` | 本片新增的依赖规范（§7.4 指向它；由本契约同批交付，已落地） |
| `docs/verification.md` | 只登记结果（validator 负责） |
| 根 `AGENTS.md` 文档入口表 | **已就位**（裁定 A19）：`AGENTS.md:133` 事件定义形态与管线统一、`:134` 事件管线依赖约束（`fa96370` 加入）。**不再是待办** |
| `docs/event-structure.md`（§1／§7.2 状态注） | 已由规划者按 A10 加注；表内同步的其余内容仍属跨片，须协调者另派 |

另注（**已按磁盘复核更正**，裁定 A7／A19）：根 `AGENTS.md` 在磁盘上只有"## 模块规则（spire-godot/）"＋
文档入口表，**不含**"Godot 入口见 spire-godot/AGENTS.md"这句、**不含** `tools/check_agents.py`，
也没有"CI 检查指引行数"一节（`grep` 三次均无命中）。此前契约与简报里的这两条表述来自注入副本，
**是误报，已作废**；`docs/response-pipeline.md` §5 第 3 条提到的 `spire-godot/AGENTS.md` 属历史
记录，磁盘无此文件。文档入口表的两行也已在本契约之外加好（A19）——**本片指引侧无未决待办**。

**B1b 的交付清单（裁定 A6；B1 只改了代码与内容，四份教旧形态的文档必须同批补齐）**

| 文件 | B1b 要改成什么 |
| --- | --- |
| `spire-godot/content/README.md` §3 事件（约 97–175 行） | 唯一作者手册：`schema_version:2`（事件）；定义级 `name/intro/pool/start_node/nodes/cleanup_effects`；节点级七个声明（`allow_refuse`／`unavailable`／`relic_gate`／`random_freeze`／`outcome_draw`／`frozen_form`／`empty_node`）逐项写清取值与当前含义；选项字段按"单节点可用／多阶段可用"两张清单重排；**明确写**：单节点定义**不得**使用 `next`／`when`／`outcomes`（B2 前会被接受但不生效，见 §2.5 过渡态）；起始节点免费出口只约束多节点（裁定 A2）；`availability` 现在在阶段选项上同样有效（B1 已修） |
| `docs/content-templates.md` | §H 事件模板（约 375–446 行）换成节点形态示例；H4 多阶段（446–465）与 H5 界面约定（467–477）按新形态改写；§488 的测试表行同步 |
| `docs/content-generation.md` §7 事件生成与结算（约 230–297 行） | 两形态合并后的生成／结算描述；节点声明与选项字段清单；`next`／`when`／`outcomes` 的单节点禁用说明 |
| `docs/content-extension.md` | 事件流程段（约 133–150 行）与内容表 events 行（约 124 行）按新形态改写 |
| `spire-godot/content/templates/event.json`、`event_multistage.json.disabled` | B1 已迁移，B1b 只需**核对其正文与文档示例逐字一致**（不改内容） |
| `spire-godot/content/packs/README.txt` | 无字段说明，不需要改 |

**B1b 明确缓到 B2 的部分**（避免二次返工，裁定 A3）：选项级 `conditions` 数组、选项级
`unavailable` 覆盖、`mode` 与叠加语义、"条件可选／条件隐藏"两类的作者写法——B2 与声明表同批
落地后再补进上述四份文档。跨事件 `next={"event","node"}` 缓到 B4。
`docs/event-structure.md` 的 §1／§7.2 状态注已按 A10 加好；表内其余同步仍属跨片，须协调者另派（不并入 B1b／B2c）。

## 9. 分批（每批都以 E0 全绿收口；B1 已落地，B1b／B2 见 §16／§17）

| 批 | 范围 | 判据 | 状态 |
| --- | --- | --- | --- |
| B1 定义形态归一 | 定义级 `nodes/start_node` 落地；内容 12 份＋模板＋生成来源迁移；`content_catalog` 单一形态校验（含 §2.5 并集规则与路径改写）；`view`／`validate`／`snapshot`／测试夹具改走 `definition/node/node_ids`；`enter_stage`→`enter_node`（行为仍按现状两条分支） | E0 全绿 ＋ `-Suite event_flow,events,content,architecture -Impact` ＋ `check-content.ps1`；§10 场景 01／02／06／07／20 | **已完成**（`d770aea`，见执行记录） |
| B1b 文档同步 | 四份仍教旧形态的文档改成节点形态（清单见 §8.3）；不含选项级 `conditions`／`unavailable` | E0 全绿 ＋ `check-content.ps1` ＋ 文档示例编译探针（§16） ＋ 依赖规范 §4.2 的两条 B1 追溯 check | **已完成**（`a57dec3`，判据登记 `4d5bc8f`，见执行记录） |
| B2 声明与单入口 | 节点声明生效（`frozen_form`／`relic_gate`／`random_freeze`／`outcome_draw`／`unavailable`／`empty_node` 不再是死数据）；一线管：单 `evaluate_option`＋单 `enter_node` 覆盖两形态；四通道收敛为**条件条目＋单求值入口**（§5）；叠加求值（`gates` 逐条）；`conditions`／`unavailable` 规范拼写与声明表同批接受；删除死分支与平行真相；`snapshot` 增量补新键检查；**同批刷新英文字典**（裁定 A9，§17） | E0 全绿 ＋ `check-content.ps1` ＋ `localization` 规则／界面门 ＋ §10 场景 05／08／09／13／15–18 ＋ 依赖规范 §4.2 三条 check | **已完成**（核心 `60869fc`＋B2b `5a60cda`＋收口 `b6d45b5`；判据逐提交复核，登记 `df856b7`） |
| B2b 收口 | 仅补 B2 未完成的三块：①§10 场景 05／08／09／13／15–18 具名 check；②依赖规范 §4.2 三条 check；③本地化刷新＋盘点＋`locale_legacy_catalog_matches_current_sources`；④以 B2 的完整门禁命令（含 `localization`）复跑交证 | 见 §18（不改产品语义；`probe()` 内部与 `node_empty` 的单独 gate 名属 B3） | **已完成**（`5a60cda` 三项交付＋`b6d45b5` 收口 C1／C2；C3 按 A15 无需补） |
| B2c 文档收尾 | 把 `conditions` 规范拼写、选项级 `unavailable`、`mode` 与叠加语义补进四份作者文档，并取消 B1b 留下的"B2 起生效"标注（A6 的收口） | 见 §19 | **已完成**（`1f450d7`，登记 `3aee25a`） |
| B3 具名丢弃与 trace | gate 命名全覆盖（含 `selector_empty`／`node_empty`／`validate_failed` 的单独命名，裁定 A13）＋叠加命中逐条记录；debug trace＋开关；测试断言；release 不产出 | 见 §20：E0 全绿（开关开／关各跑一遍、摘要逐字相同）＋ §10 场景 03／04／10／19 | **核心已落地、本批未完成**（`f95e96f`；四条 check／release 证据／清空缺陷见 §20 收口清单） |
| B3b 收口 | ①场景 03／04／10／19 具名 check（按 A25 口径重写断言）；②release 不产出的证据链（含引擎错误日志）；③`source_choice`／`option_id` 字段拆分（D1a）；④复核红集口径 ⊆ {`card_power`, `installed_tools`} | 见 §20.1 收口清单 | 待派工 |
| B4 事件链路由 | `next` 支持 `{"event","node"}`；`chain` 条件键；环守卫；夹具与用例 | 见 §21：E0 全绿 ＋ §10 场景 11／12 ＋ 依赖规范 §4.2 的新键半 | 待派工（§21） |

每批单独跑该批判据；**不得把前一批的绿色拼进下一批**。B1b 与 B2 之间代码必须可跑可测
（B1 的两条分支仍在，只是由节点形态驱动；B2 才把节点声明接上）。

## 10. Gherkin（场景名 → 既有分类的具名 check）

不新建流程文件、不新建看板；用具名函数加入既有 case 文件，复用 `tests/game_fixture.gd` 与
`tests/event_cases.gd.arrive`。**已落地（B1）**：01／02／06／07／20；B2 核心已落地产品代码但
**场景一条未落**，故 05／08／09／13／15–18 归 **B2b**；03／04／10／19 归 B3；11／12 归 B4。

01. `event_definition_single_form`（`tests/event_cases.gd`，`events`）
    Given 12 份迁移后的内容包；When 编译并逐个进入；Then `Data.TYPES[id]` 只含 `nodes/start_node`，
    无顶层 `choices/stages/allow_refuse`，且每个节点含 §2.2 全部声明键；`view().room_event` 的
    字段与基线一致。
02. `event_option_policies_match_current_behaviour`（`tests/event_flow_cases.gd`，`event_flow`）
    Given 每份内容的每个节点／选项；When 读取声明；Then 声明值与 §2.2／§2.3 现值表逐项相等
    （普通节点 `disable/pool/generators/option/in_place/allow`；多阶段节点 `hide/claimed/always/option/staged/fail`）。
03. `event_gate_names_are_total`（`tests/event_cases.gd`，`events`）
    Given 开启 trace；When 逐事件执行 `arrival`（`Events.start`）与 `candidates()`；
    Then（**按 §4.5 过滤判定，禁止按总行数**）：
    ①每个**作者选项**（按 `source_choice` 分组）至少一行；
    ②每行 `decision ∈ {generated,dropped,hidden,disabled}`；
    ③`decision ∈ {dropped,hidden}` 的行必须带非空 `gate` 且 gate ∈ §4.2 清单；
    ④**状态条件行**在 `arrival` 与 `candidate` 两次求值中逐字段相同（仅 `purpose` 不同）——**缺行即失败**；
    ⑤选择器选项：`source_choice`＝作者 id（无 `__` 后缀）、`option_id`＝冻结实例 id（有后缀），
    两者都要按各自形态断言（这是 A25 的钉死点，也是本轮误红的根因）；
    ⑥节点入口失败行以 `gate=="node_empty"`／`"stage_missing"` ＋ `node==<目标节点>` ＋ 空 `option_id` 识别；
    ⑦候选数组、View、随机计数与关闭 trace 时逐字节相同。
04. `event_hidden_relic_option_traced`（`tests/event_flow_cases.gd`，`event_flow`）
    Given 已持有 `softened_buckle` 的漂浮皮带群；When 构建选项；Then 【硬闯】缺席且 trace 记录
    `source_choice=fight`＋具名 gate，候选集合与 E0 基线一致（E6 政策维持现状）。
05. `event_condition_kinds_share_one_declaration`（**一条 check 覆盖三处消费者即可，不强制分文件**
    ——裁定 A15：判据是"三处一致"；B2b 落在 `tests/architecture_cases.gd`，规则分类 `architecture`）
    Given `Events.condition_kinds()`；When 逐 kind 造最小合法 `availability`（普通选项与阶段选项各一次）；
    Then 内容编译通过、运行时求值返回非空、存档往返通过且键集＝`condition_saved_fields(kind)`；
    未知 kind 在三处一致拒绝；三处 kind 集合相等（条目解析为三者共用路径）。
06. `event_stage_available_condition_validates`（`tests/content_cases.gd`，`content`）
    Given 阶段选项声明 `has_relic`；When 编译；Then 通过（覆盖 `_availability` 漏传 `data` 的现状缺口），
    未登记遗物／缺 `type`／多余键仍拒绝。
07. `event_definition_form_rejects_legacy_shape`（`tests/content_cases.gd`，`content`）
    Given 同时含 `choices` 与 `stages`、缺 `start_node`、节点缺任一声明键、节点 id 用 `battle`／`loot`、
    `recipe` 与 `effects` 同填；When 编译；Then 逐例拒绝且整包不登记（`Catalog.tables(g)` 不变）。
08. `event_unified_option_capabilities`（`tests/event_flow_cases.gd`，`event_flow`）
    Given 夹具把 `encounter`／`item_rewards`／`hide_when_unavailable` 写在阶段选项、
    把 `when`／`outcomes`／`next` 写在**单节点**选项（含"单节点 + selector + outcomes"一例）；
    When 编译并执行；Then 全部按节点声明生效（`outcomes` 的抽取按 `outcome_draw` 声明、
    `when` 参与显示判定、`next` 按目标推进）——**即 §2.5 过渡态的收口判据**，
    且 12 份内容的行为不变。
09. `event_node_empty_policy_kept`（`tests/event_cases.gd`，`events`）
    Given 普通夹具节点的全部选项被丢弃；When 构建；Then 节点保持零候选、不进入失败结果页；
    Given 多阶段夹具节点同样情形；Then `enter_node` 返回具名 issue `node_empty`，
    上一节点的该选项在候选阶段变为 invalid。
    **状态（B2b 续批 R2）：第三段（`next` 指向空节点 → 上一节点候选变 invalid）尚未落地**；
    `node_empty` 的**单独 gate 名**仍属 B3（裁定 A13）。
10. `event_trace_never_reaches_state_or_save`（`tests/persistence_cases.gd`，`persistence`）
    Given 开启 trace；When 进入事件、构建候选、提交、`export_snapshot`／存档往返；
    Then snapshot／存档／View／`rng` 不含 trace 字段，且与关闭 trace 时的摘要相同。
11. `event_chain_jumps_to_another_event_node`（`tests/event_flow_cases.gd`，`event_flow`）
    Given 夹具事件 A 的节点 `next={"event":"B","node":"entry"}`；When 提交；
    Then `room_event.id=="B"`、`stage=="entry"`、`chain` 含 A、`values`／`held` 延续、
    离开时 A∪B 的 `cleanup_effects` 各执行一次、`event_seen` 含 B。
12. `event_chain_loop_refused`（同文件）
    Given 链上已含 A；When 再次跳向 A；Then 该选项 invalid 且 gate=`chain_loop`，
    `state`／`rng`／存档不变。
13. `event_probe_and_projection_readonly`（`tests/architecture_cases.gd`，`architecture`）
    Given 任一事件（含链夹具）；When `get_view`／`candidates`／`evaluate_option(purpose=candidate/probe)`／
    `selector_values`；Then `export_snapshot()`、`rng`、`logs`、`version` 与调用前全等。
14. `event_frozen_options_roundtrip`（`tests/persistence_cases.gd`，`persistence`）
    Given 每个事件的冻结选项（普通与多阶段各取样例）；When 存档往返；Then 选项与 `room_event`
    逐字段相等，且 `option.has("next")` 的校验分支按 §6.3 判定。

**叠加条件（R1 澄清后的 trigger 系统能力；夹具用规范拼写 `conditions`，本片无内容使用）**

15. `event_single_optional_condition_keeps_choice_visible`（`tests/event_flow_cases.gd`，`event_flow`）
    Given 夹具选项声明 1 条 `mode:"optional"` 的 `has_relic`（未持有）；When `arrival` 构建与
    `candidate` 求值；Then 选项**仍在** `room_event.options` 里、候选 `valid=false`、
    `reason`＝该条 `reason` 原文、`gates` 长度 1 且 `gate=="availability_unmet"`、
    `reason_surface=="secondary"`。
16. `event_single_hidden_condition_removes_choice`（同文件）
    Given 夹具选项声明 1 条 `mode:"hidden"` 的 `has_relic`（未持有）；When 构建；
    Then 选项**不在** `room_event.options`／候选里，`decision=="hidden"`、`gates` 长度 1。
    **状态（B2b 续批 C1）：尚未立证**——已落地的 `event_stacked_conditions` 只构造了该夹具、
    未断言；`decision=="hidden"` 是中间量，判据是"选项不在 `room_event.options`／候选里"。
17. `event_stacked_condition_modes_combine`（同文件）
    Given 同一选项声明两条（`optional` 的 `has_relic` ＋ `hidden` 的 `no_chastity_lock`），
    两条同时命中；When 构建；Then `decision=="hidden"` **且选项不在 `room_event.options`／候选里**；
    `gates` **同时含两条**（按声明顺序，`mode` 分别为 `optional`／`hidden`）；把 `hidden` 那条
    置为不命中时，同一选项变为 `disabled`、`gates` 只剩 `optional` 那条。
    **状态（B2b 续批 C1）：与场景 16 同一未证项**（已落地的夹具只断言"两条件都不命中后恢复"）。
18. `event_stacked_same_mode_lists_all_hits`（同文件）
    Given 同一选项两条 `optional`（两条都命中）与一条 `optional`（不命中）；When `candidate` 求值；
    Then `decision=="disabled"`、`gates` 恰为命中的两条（声明顺序）、
    `reason`＝两条 `reason` 用 `"\n"` 连接、未命中的那条不出现在 `gates` 里；
    `hidden` 模式的两条叠加同样只列命中项。
19. `event_stacked_condition_trace_and_release`（`tests/event_cases.gd`，`events`；
    存档侧同断言落 `tests/persistence_cases.gd`，`persistence`）
    Given 开启 trace 的叠加夹具；When 执行 `arrival` → `candidates()`；
    Then（**按 §4.5 过滤判定，禁止按总行数**）：
    ①每条命中的条件各一行，按 `(purpose, source_choice, index)` 过滤即可定位；
    ②`index` 与声明序一致（0／1），`mode` 与作者声明一致（`optional`／`hidden`），`reason` 为作者原文；
    ③同一选项的状态条件行在 `arrival` 与 `candidate` 两次求值中除 `purpose` 外逐字段相同（缺行即失败）；
    ④第二次 `start` 后旧行不残留（`clear_trace` 生效）；
    When 关闭开关（release 路径）；Then `Events.event_trace(g)` 为空、该次求值产出 0 行，
    且候选／View／存档／`rng` 摘要与开启时相同。
20. `event_stacked_conditions_keep_current_content`（`tests/content_cases.gd`，`content`）
    Given 12 份迁移内容；When 逐选项跑 `condition_entries`；Then 每个选项解析出**恰好一条**条目
    （形状·条件 6 处＝`optional`＋`hidden` 覆盖、其余状态条件＝`optional`、`when`＝`hidden`、
    奖励遗物＝`hidden`），且 `gates` 长度恒为 0/1、`reason` 与基线逐字节相同；
    叠加能力上线前后 E0 94 场景摘要一致（由 §12 第 0 条命令执行）。

场景 01–20 是 B1–B4 的逐步落地对象；未落地即未完成。归属：B1 已落 01／02／06／07／20；
B2b 已落 05（裁定 A15：单 check 覆盖三处）／08／09（前两段，第三段见 R2）／13／15／18，
**16／17 的"选项不在 `room_event.options`／候选里"仍待立证（C1）**；
B3 落 03／04／10／19；B4 落 11／12；B1b 不新增场景（判据见 §16）。

**完成口径（裁定 A16，逐层不得代偿）**：B2 核心绿（`60869fc`）≠ B2 完成；
B2b 三项交付绿（`5a60cda`）≠ B2b 完成（R1／R2 未收口）；
**B2b 续批绿 ≠ 整片完成**（B3／B4 未做）；全程不得打包发版。

**裁定 A13 的落点标注**：
- 场景 09（`event_node_empty_policy`）的**行为半**（普通节点保持零候选、多阶段节点返回既有 issue
  文案、上一节点选项 invalid）属 **B2b**；**`node_empty` 单独记 gate 的命名半**属 **B3**；
- 场景 03／04 的 gate 清单里 `validate_failed`（拆 `probe()` 内部才能与 `probe_failed` 分离）
  与 `node_empty` 的具名，同属 **B3**；B2b 只断言现有 gate 名集合与叠加逐条记录。

## 11. Validator procedure（agent 可运行；操作必须走真实输入）

宿主入口：`tests/test_game.gd`（规则）＋`tests/ui_smoke.gd`（界面）＋`tools/check.ps1`。
不默认截图；测试存档隔离（`ui.persistence_enabled=false`）。

1. 范围预检（不算通过）：
   `& tools/check.ps1 -Suite event_flow,events,content,architecture,persistence -Impact -ListOnly`
   与 `& tools/check.ps1 -UIOnly -UISuite events,localization -ListOnly` → 输出 `PLAN ONLY:` 且列出上述分类。
2. 冻结判据（每批一次）：跑 §0.1 的 oracle 比对命令 → 退出码 0、`EVENT RESULT: PASS (94 scenarios, 0 failures)`；
   另在 trace 打开与关闭两种设置下各跑一次，两次输出摘要相同。
3. 内容门：`& tools/check-content.ps1` → `CONTENT PASS: 12 file(s)`。
4. 规则门：`& tools/check.ps1 -Suite event_flow,events,content,architecture -Impact -TimeoutSeconds 900`
   → 退出码 0；每个 `SUITE RESULT: PASS <name>`；`summary.json` 的 `status=passed` 且 `before==after`
   指纹（`source_changed` 不算通过）。
5. 界面回归（投影不动）：`& tools/check.ps1 -UIOnly -UISuite events,localization -TimeoutSeconds 900`（**A17：必须 900**）
   → 退出码 0、`UI PASS: N assertions`。
6. 人的路径证明（判据是套件的布尔 check，按顺序在真实界面上操作）：
   - 练习「漂浮皮带群」首次进入：事件候选（`payload.kind=="event"` 且 `action=="choose"`）恰为【硬闯】【接受灌注】，与基线一致；
   - 注入已持有 `softened_buckle` 的状态后再进入：【硬闯】仍缺席、【离开】出现（E6 维持现状）；
   - 选【硬闯】完成战斗：进入事件结果页、只发遗物、战后整备按原语义；
   - 事件选牌／道具奖励／付费离开各走一次，文案与原因与基线一致；
   - 多阶段事件（缚疗修女、魅魔三局赌牌）逐阶段点击，阶段标题与选项与基线一致；
   - 存档并在正式入口继续：选项、阶段、报告一致（旧档路径不变）；
   - 关闭 debug 开关：`g.event_trace` 为空。
7. 叠加条件证明（夹具能力，无内容依赖；判据是 §10 场景 15–18 的布尔 check）：
   在测试夹具上逐项运行"单条可选／单条隐藏／两类叠加／同类多条叠加"，核对
   `decision`／`gates`（条数、顺序、`mode`、`kind`）／`reason`（多条 `optional` 时 `"\n"` 连接）；
   再开 trace 断言每条命中条件各一条记录，关开关后 `g.event_trace` 为空且摘要不变；
   释放路径（关闭开关）不得产出 trace。
8. 归属判定：失败先分"实现代码／测试脚本／环境／程序本身"；不确定就保持未分类上报，
   不自动改产品代码，不动判据。
9. 证据：`build/checks/<id>/check-rules.log`、`check-ui.log`、`summary.json`、oracle 输出；
   结果与域写 `docs/verification.md`（validator 负责，不在本契约宣称通过）。

## 12. 完成定义（DoD）

命令（每批一次 ＋ 收尾一次；不无故重复）。**第 0、2 条命令覆盖 §10 全部 20 个具名 check 的分类**：

```powershell
# 0) 冻结判据（每批必跑；基线只读；判据＝94 场景 0 失败 **且引擎错误日志命中 0 行**（A24））
& <Godot console exe> --headless --path . --script res://build/event-oracle-20260916/event_oracle.gd -- --baseline=build/event-oracle-20260916/baseline.json
# 1) 内容包校验（改 content/packs、content/templates 或站点文档示例后必跑）
& tools/check-content.ps1
# 2) 规则门（分类点名：events＝01/03/09/19；event_flow＝02/04/08/11/12/15-18；
#    content＝05/06/07/20；persistence＝10/14/19 存档侧；architecture＝05/13；各批实际归属见 §9）
& tools/check.ps1 -Suite event_flow,events,content,architecture -Impact -TimeoutSeconds 900
# 3) 界面回归（投影不动；A17 固化时限）
& tools/check.ps1 -UIOnly -UISuite events,localization -TimeoutSeconds 900
# 4) B1b 专用：文档示例编译探针（把两份模板复制为 .json 到临时目录后校验，见 §16）
& tools/check-content.ps1 -Path <临时目录>
# 5) B2 专用：本地化词表刷新与验收（裁定 A9；在 spire-godot/ 下执行）
python tools/localization_inventory.py
python tools/build_english_catalog.py          # 需要离线模型／缓存；不可用时改人工补齐（见 §17）
& tools/check.ps1 -Suite localization -TimeoutSeconds 600
& tools/check.ps1 -UIOnly -UISuite localization -TimeoutSeconds 600
```

**每批判据的"恰好红集"**：`-Suite ... -Impact -KeepGoing` 时只允许
`card_power`（`docs/verification.md:29`，5 条 `witch_*`）为红；**多出一条即本片未完成**；
其余分类（含 `persistence`、`special_equipment`、`equipment`、`pressure`、`tower`）必须全绿。

**红集口径（裁定 A21 → A23 定类）**：`红集 ⊆ {`card_power` 5 条（`docs/verification.md:29`）,
`installed_tools` 1 条（`docs/verification.md` 2026-09-16 B3 条目）}`；多出任何一条即本片未完成。
`installed_tools` 的定类过程留档：先按 A21 记为**待分类项**（不得当既有项），再按 A22 在
`4d22a00`（B1 之前）重跑同一套件 → 同样红 → 判为**既有红项，非本片回归**（根因方向＝夹具前置条件与
当前卡牌／工具接口漂移；未定类未修）。**不得**为凑绿改该套件断言或把它从门禁里拿掉。

`normal_play`（`docs/verification.md:58` 的 2026-09-14 全量尝试条目）**不进本片、不派修**；
登记措辞按事实：既有登记项；B1 实现者在 `HEAD~1` 复现出同样打转，但**因主动终止未能证明旧版
断言同样红 → 归因未定**。**不得写成"与 B1 无关"的结论，也不得据此改断言或删套件。**

**新红的分类口径（裁定 A22，与 A18 配套）**：发现新红时，**分类的第一步是"在引入点之前重跑同一
套件"**，而不是先解释现象；结论出来前既不得登记为既有项，也不得直接修。

必过的场景：§10 的 01–20 全部具名 check（按 §9 的批次归属逐批验收，B1b 不新增场景）；E0 的 94 场景 0 失败；`check-content.ps1` 通过；
`docs/event-pipeline-dependency-spec.md` §4.2 的 5 条检查按 §9（§7.4）归属批次落地并通过
（同批判据，不得择一执行）；§2.5 的两张表逐条落地（放宽项 8 条 ＋ 路径改写行），
**既有反例只允许改写路径或新增，不得删除**。

必有的证据：oracle 比对输出（含 `EVENT RESULT: PASS`）、两份 check 日志 ＋ `summary.json`
（`status=passed`、指纹稳定；红集只允许 §12 的 `card_power` 项）、本地化盘点数字与套件结果、
§8.3 的文档同步记录（B1b 已完成，见执行记录）。

算未完成（任一）：

- 任一必跑命令未执行、失败、未知或被跳过；`summary.json` 为 `source_changed`／`failed`／`plan`；
  红集**超出** §12 规定的 `card_power` 项；
- **B2 落地前打包、导出或发版**（裁定 A1：过渡态下"能编译但不生效"的键会随包外发）；
- E0 出现红项而未解决、未显式上报人裁；用 `--write=` 重取基线让红变绿；
- 冻结产物被"顺手统一"（`options`／`snapshot` 变红）——§6.1 已定：兼容布局是 E0 判据带来的要求，
  未经人裁不得改动；
- B2 以"按选项键判定"删掉或弱化现有 `flow` 分支检查（裁定 A4）；
- 声明表以外的地方出现状态条件 kind 字面量、三处消费者枚举不一致；
- 叠加求值未按 §5.3：命中多条时只留一条原因、只给笼统 gate、或 `gates` 顺序与声明序不一致；
- `conditions` 与 `availability` 同时出现在同一选项（两个真相源）而未被拒收；
- 出现静默丢弃（无 trace 记录、无 gate 名）；
- trace 进入 `state`／存档／View／日志，或 release 运行产出 trace；
- 新增 `get_view` 只读字段、新增 `game.event_diagnostics()`、改 `ui/` 或 `core/game.gd` 提交管线；
- 删／弱化既有断言（含 `event_flow_cases` 的隐藏选项断言、`persistence_cases:event_conditions`）换绿灯；
- 把 `normal_play` 的既有红项写成"与 B1 无关"的结论，或据此改断言、删套件；
- 本地化把缺译写成通过、以"离线模型不可用"为由跳过字典刷新、或只改目录不改盘点口径（裁定 A9）；
- 落地迁移脚本或改启动链（人审：不落地）；
- 12 份内容之外的内容包被写入链形态（E0 不覆盖）；
- B1b 未完成就开始 B2（文档与代码形态不一致期不得叠批）；
- **B2b 未完成就宣称 B2 通过**（核心绿≠本批绿：§10 场景、依赖 check、本地化三块必须同批收口，§18）；
- **用任一层绿色代表上一层**（裁定 A16）：B2 核心绿≠B2 完成（现已完成）；
  **B2 全批绿≠整片完成**（B2c／B3／B4 未做）；**B2c 绿≠B3／B4 绿**；**全程不得打包发版**；
- 宣称完整回归或提速。

## 13. 裁定记录（R1 按人审澄清改写；其余按推荐执行）

人审 2026-09-16（原话见文件头）：计划接受；R8 不落地、设计留档；R5 取并集并逐条登记；
**R1 由人澄清改写**；其余按本表推荐执行。本表从此为决定记录，不再是待裁清单。

| # | 问题 | 裁定 |
| --- | --- | --- |
| R1 | ~~冻结选项布局是否统一~~ → **终端功能＝后端 trigger 系统完善**：条件可选（显示但禁用）与条件隐藏（不生成）两类模式**可并存、可叠加**；玩家可见不变 | 按人审改写：§5 的条目模型＋§5.3 叠加语义＋§4 的 `gates` 逐条记录；`frozen_form` 降为**E0 兼容要求**（§6.1），不是设计目标；规范拼写 `conditions` 为新增能力，本片无内容使用，只由夹具覆盖（§10 场景 15–18） |
| R2 | `hide_when_unavailable` 是否改名 | 按推荐：保留为兼容拼写（与 `unavailable` 冲突即拒收）；6 处选项摘要不变 |
| R3 | 声明粒度 | 按推荐：节点默认＋选项覆盖（`mode` 优先级见 §5.3）；兼容拼写条目按选项默认模式解析 |
| R4 | `schema_version` | 按推荐：事件升 2 |
| R5 | 校验规则合并取值 | **人审：取并集并逐条登记**；登记表见 §2.5（8 条放宽项＋路径改写清单＋既有反例期望更新） |
| R6 | 空节点策略 `empty_node` | 按推荐：按现值声明（普通 allow、多阶段 fail）；统一为 fail 属玩家可见变化，另案 |
| R7 | 事件链是否本片实现 | 按推荐：实现最小跳转＋环守卫＋夹具（B4） |
| R8 | 启动期迁移脚本 | **人审：不落地，设计留档**；§6.4 保留留档设计，不改启动链 |
| R9 | trace 落点 | 按推荐：`g.event_trace_enabled`＋`g.event_trace`（同 `copy_router_failures` 模式）；叠加求值下每条命中条件各一条记录 |
| R10 | 删除死分支 | 按推荐：删除选项级 `pressure`／`pressure_source` |
| R11 | 是否新增 core 文件 | 按推荐：不新增（本仓无行数门禁）；500 行硬线属另案（E5） |
| R12 | `get_view` 新只读字段 | 按推荐：0 个（投影不动；条件命中明细只进 core 内 trace） |

## 14. 假设与最可能爆掉的假设

1. **最可能爆：某处我判定"等价"的求值顺序在迁移后改变了 `event` 域消耗**——高风险点是
   `relic_gate` 的冻结前／后位置、`selector` 展开与 `outcome_draw` 的先后、生成器判定发生在
   `resolve_effect_copy` 之后。触发即 E0 的 `rng`／`options` 红；定位方法是按场景名二分
   （`start:`／`choose:`／`settle:`）并临时开 trace 对拍。
2. **次可能：迁移把普通非选择器选项的键序改了**（JSON 重排、补键、顺手统一 `report` 位置）→
   `options` 与 `snapshot` 同时红。缓解：迁移脚本逐文件往返比对（读入→写出→再读入，键序与值相等）
   后再入库。
3. **`flow` 镜像被当成死字段删掉** → 所有多阶段场景 `snapshot` 红。契约已写明：兼容键继续写入，
   只是没有运行分支读它。
4. **trace 引入实例级状态泄漏**（探测副本里写入、或在 `export_snapshot` 里被带上）→
   `snapshot`／`View` 摘要红。缓解：§10 场景 10 与"开／关两遍 oracle"。
5. **内容校验放宽项改写了既有反例断言**：`content_cases` 有 20+ 条 invalid 夹具（缺 `type`／
   多余键／空 `effects` 等），某几条在新规则下从"拒绝"变"接受"或反之。这不是产品缺陷，
   但会让 B1／B2 变红；处理方式是逐条按 §2.5 更新期望，**不得删除**。
6. **链语义污染 12 份内容**：迁移时误写 `next` 的对象形态或 `chain` 键 → E0 红。
7. 若把 §5.3 的叠加语义改成"OR／任一满足即可选"或"optional 优先于 hidden"，会出现同一选项
   在两种模式下给出不同 `gates`／`reason` 的实现分歧——判据是 §10 场景 17／18，
   规则以 §5.3 为准，改规则属重新规划。
8. **写规范或核对事实前，先以磁盘文件为准**（`rg`／`sed` 实地读仓库文件），不采信注入副本、
   历史会话摘要或协调者简报里的"现状引述"。已出现**三次**同类误报：根指引被报"仍列
   `tools/check_agents.py`"、被报"仍指 `spire-godot/AGENTS.md`"（裁定 A7），以及把根 `AGENTS.md`
   文档入口表两行当成待办（裁定 A19，实际 `fa96370` 已加）。凡引用"某文件现在写着 X"的结论，
   必须带当次核对的命令与命中行。
9. **归因纪律（裁定 A18，新 check 首次变红时）**：先分类"**判据／夹具写错** vs **行为漂移**"，
   用最小复现定类后再动手；**禁止把红断言直接改成通过**。最小复现放已忽略的
   `build/<topic>-<date>/`，摘要（含定类与证据路径）进 `docs/verification.md`。
   本轮两次实例：E0 比较器修复（`4d22a00`）、`hidden` 立证（`b6d45b5`，结论＝夹具／断言问题）。
   另记一条读法坑（C1 附带）：给 `evaluate_option` 传作者选项而非冻结选项时，
   第 4 步按设计跳过状态条件——诊断新拼写必须走 `request_for`／`frozen`。
10. **新红的两步定类法（裁定 A22，与假设 9 配套）**：**第一步永远是"在引入点之前重跑同一套件"**，
   不是先解释现象；结论出来前**不得**登记为既有项、**不得**直接修、**不得**改断言或把套件从门禁里拿掉。
   本轮实例：`installed_tools`（`tests/installed_tools_cases.gd:43`，`detail` 取键失败、0/9）——
   已排除 B3（还原 `room_events.gd` 到 `1f450d7` 同样红），但**尚未排除本片早期提交**（须在 `4d22a00`
   之前重跑）；分类结论未定前它是**待分类项**（A21）。
   三条并列实例：E0 比较器、`hidden` 立证、`installed_tools`。

## 15. `needs-human-review` 判定（历史记录）

**原判定：是（`needs-human-review`）。人审已于 2026-09-16 通过，记录见文件头与 §13；
本节保留当时的理由，供追溯，不再是关口。**

1. **内容包 schema 变更**：12 份外部 JSON、2 份模板、1 处生成来源、7 份文档受影响；形态由人裁第 2 条
   授权，但**具体字段清单与默认值**（§2）需要人确认。
2. **存档邻近**：`core/snapshot.gd` 的事件校验要改写；且需人确认"本片不改存档形态"与
   "是否仍要迁移脚本"（§6.4）这一对结论。
3. **新增能力**：跨事件跳转与 `chain` 存档键是新能力（人裁第 5 条的方向），当前无任何内容使用，
   其语义（`values`／`held`／`cleanup`／`event_seen`／`room.event` 的延续规则）需人确认。
4. **计划包含两处实测新增的隐式差异**（e 空节点处理、f 冻结产物布局），超出人列的 a–d；
   其中 f 直接受 E0 判据约束。
5. **依赖规范与文件拆分**：本片结论是不新增文件、不新增依赖边；若人要求按 500 行硬线拆，
   等于重新授权 E5（先前明确未授权），属范围变更。
6. **判据相互作用**：E0 全绿这一判据与"内容必须合并成一种形态"存在张力（冻结产物不能被统一），
   本契约的解法是把差异降为声明；该解法需人认可，否则整片范围与判据都要改。

## 16. B1b 派工要点（文档同步；**已完成 `a57dec3`，此处留档**）

- **一句话**：把四份仍教旧形态的文档改成节点形态，并在文档里写清"单节点不得使用
  `next`／`when`／`outcomes`"，使照文档写出的包能被当前校验接受。
- **域**：文档与作者手册的一致性。不改产品代码、不改测试、不改判据脚本、不改内容包与模板
  （模板是 B1 已迁移并通过校验的真源，**文档跟随模板，不反过来改模板**）。
- **可改文件（授权清单，只这四份）**：
  1. `spire-godot/content/README.md`（§3 事件，约 97–175 行）
  2. `docs/content-templates.md`（§H／H4／H5／§488 行测试表）
  3. `docs/content-generation.md`（§7 事件生成与结算）
  4. `docs/content-extension.md`（事件流程段、内容表 events 行）
  内容与改写要点见 §8.3；`docs/event-structure.md`、根 `AGENTS.md`、本契约不在 B1b 授权内。
- **判据命令（全跑，一次）**：
  ```powershell
  # 0) 冻结判据（文档改动不应影响它；红了先查是否误改代码/内容）
  & <Godot console exe> --headless --path . --script res://build/event-oracle-20260916/event_oracle.gd -- --baseline=build/event-oracle-20260916/baseline.json
  # 1) 内容门（含模板）
  & tools/check-content.ps1
  # 2) 文档示例编译探针：把两份模板按 .json 复制到已忽略的临时目录后校验
  & tools/check-content.ps1 -Path <临时目录>     # 判据：CONTENT PASS: 2 file(s)
  # 3) 规则门（回归，防止误改代码）
  & tools/check.ps1 -Suite event_flow,events,content,architecture -Impact -TimeoutSeconds 900
  # 4) 旧形态残留扫描（人工判读；只允许出现在"迁移说明"段）
  rg -n "start_stage|\"stages\"|顶层 .*choices|allow_refuse 默认" spire-godot/content/README.md docs/content-templates.md docs/content-generation.md docs/content-extension.md
  ```
- **DoD**：
  - 四份文档的字段表与 `content_catalog.gd` 的实际白名单一致（节点七个声明取值、选项白名单、
    `schema_version: 2`、"起始节点免费出口只约束多节点"、`availability` 在阶段选项同样有效）；
  - 文档中的完整示例**指向** `content/templates/` 的两个文件，不复制第二份完整 JSON；
  - 文档写明 B2 前单节点禁用 `next`／`when`／`outcomes`，以及"`conditions`／`unavailable` 规范拼写
    将在 B2 提供"（**不作为可用能力描述**）；
  - 上述 4 条命令退出码 0（第 4 条为人工判读，命中项须逐条给出理由）；
  - 证据与结果写 `docs/verification.md`（域：文档同步）。
- **具名 check**：依赖规范 §4.2 的两条 B1 追溯项（`event_dependency_edges_pinned`、
  `event_definition_accessors_only`，B1 已满足、B1b 落地即可）＋ `tests/content_cases.gd` 新增
  `event_author_manual_lists_current_fields`：读 `res://content/README.md` 的字段表小节，
  断言其中出现的反引号标识符全部 ∈ 校验器白名单 ∪ 既有非字段词表，且不出现
  `start_stage`／顶层 `choices`。允许实现者收窄为"只查字段表小节"，**不得弱化为不检查**。
- **非目标**：不改任何内容包语义、不改模板、不动 B2 才开放的拼写、不打包。

## 17. B2 派工要点（声明与单入口；**已完成**：核心 `60869fc`＋B2b `5a60cda`＋收口 `b6d45b5`）

- **一句话**：让 B1 写进内容的节点声明真正生效，把资格四通道收敛成"条件条目 ＋ 单求值入口"，
  并同批接受 `conditions`／选项级 `unavailable` 规范拼写与叠加求值。
- **域**：`room_events.gd` 的事件生成／求值／执行；`content_catalog.gd` 的作者层校验；
  `snapshot.gd` 的事件段键集；对应测试。
- **可改文件（授权清单）**：
  - `spire-godot/core/room_events.gd`、`spire-godot/core/content_catalog.gd`、`spire-godot/core/snapshot.gd`
  - `spire-godot/tests/{event_cases,event_flow_cases,content_cases,persistence_cases,architecture_cases}.gd`
  - `spire-godot/assets/localization/legacy-en_US.json`（裁定 A9：同批刷新英文字典）
  - **不改**：`content/packs/*`（七个节点声明 B1 已写好，值＝现值）、`content/templates/*`、
    `ui/**`、`core/game.gd` 提交管线、`core/game_view.gd`、`docs/**`（作者手册补充归 **B2c**，见 §19；B2 已落地，该缺口按 A6 必须在 B2c 收口）。
- **交付物（接口级，按 §4／§5）**：
  1. `CONDITIONS` 声明表 ＋ `condition_kinds`／`condition_entries`／`condition_issue`／
     `condition_probe`／`condition_saved_fields`（一处声明，三处消费者集合相等）；
  2. `evaluate_option(g, request)`：`gates` 数组（`gate`／`kind`／`mode`／`index`／`detail`／`reason`）、
     四种 `decision`、按声明顺序、多命中 `reason` 按 `"\n"` 连接；
  3. `enter_node` 成为唯一节点管线：节点声明 `frozen_form`／`relic_gate`／`random_freeze`／
     `outcome_draw`／`unavailable`／`empty_node`／`allow_refuse` 全部被读取（B1 的节点数分支消失）；
     包含过渡态里"单节点 + selector + outcomes 按 per-selection 抽"这一例改为遵循 `outcome_draw` 声明；
  4. 模式解析优先级与叠加聚合（§5.3）＋ `reason_surface` 改由 gate 判定；
  5. 白名单加 `conditions`（1–8 条、每条 `mode`）与选项级 `unavailable`；两者与 `availability`
     不得并存；`content_catalog` 的状态条件校验改为调 `condition_issue`；
  6. `snapshot` **增量**补齐：保留 `flow` 分支全部检查，另加 `conditions` 键集与 `mode` 检查
     （裁定 A4：不得以放宽换统一）；
  7. 删除死分支（选项级 `pressure`／`pressure_source`）与平行真相（`condition_met`／
     `availability_issue` 内部 match 改为查表）；
  8. `probe`／`candidates`／`execute` 全经入口，`purpose` 检查清单按 §4.4（多一步少一步都算红）；
  9. **英文字典刷新（裁定 A9）**：`assets/localization/legacy-en_US.json` 与 B2 收口后的校验文案
     一致——B1／B2 删除或改写的中文源文条目从目录移除，B1／B2 新增或改写的源文有非空译文；
     口径与验收见下面的"本地化验收"。
- **本地化验收（口径写死，判定可复核；入口＝`docs/localization.md` §维护流程／§验证，
  项目 skill `spire-ui-content` 指向同一文档）**：
  - 判定①**旧源文**：某目录条目的 `source` 不再出现在 `python tools/localization_inventory.py` 的
    盘点源文集合（范围 `project.godot`／`*.tscn`／`core`／`data`／`ui`／`content/packs`，
    跳过 `legacy-*`）→ 该条为旧源文，**必须删除**；抽查范围＝本片动到的文案。
  - 判定②**缺译**：盘点集合中的源文在目录里没有条目、或条目 `text` 为空 → 缺译；
    运行期 `Localizer.display()` 未命中即原样返回中文源文（安全回退，无诊断、不改判定）。
  - 判定③**通过条件**：本片删除的源文条目清零（由 `REMOVED_SOURCES` 断言保证）、
    本片新增/改写的源文有非空译文（由 `REQUIRED_SOURCES` 断言保证）；全量盘点数字
    （目录条目数 before／after、缺译条数）与套件结果进 `docs/verification.md`。
  - `python tools/build_english_catalog.py` 需要离线模型／缓存；**模型不可用时按"人工补齐本片动到的
    条目"完成**（数量有限、逐条可数），**不得**以环境为由跳过；仍无法产出译文的条目登记为
    未完成 → 该批未完成，不得宣称通过。
- **判据命令（一次，不无故重复）**：
  ```powershell
  & <Godot console exe> --headless --path . --script res://build/event-oracle-20260916/event_oracle.gd -- --baseline=build/event-oracle-20260916/baseline.json
  & tools/check-content.ps1
  & tools/check.ps1 -Suite event_flow,events,content,architecture,localization -Impact -TimeoutSeconds 900
  & tools/check.ps1 -UIOnly -UISuite events,localization -TimeoutSeconds 900   # A17：必须 900
  # 本地化刷新（在 spire-godot/ 下执行；顺序即口径）
  python tools/localization_inventory.py
  python tools/build_english_catalog.py
  ```
- **DoD**：
  - E0 退出码 0、`PASS (94 scenarios, 0 failures)`、摘要 `1f11bea5…`（**摘要必须逐字相同**）；
  - `-KeepGoing` 红集**只允许** `card_power`（`docs/verification.md:29`）；任何新红项即未完成；
  - §10 场景 05／08／09／13／15–18 全部具名 check 通过（08 必须证明单节点上
    `next`／`when`／`outcomes` 已按声明生效——即 §2.5 过渡态收口）；
  - 依赖规范 §4.2：`event_condition_kinds_share_one_declaration`、`event_single_evaluation_entry`
    落地；`event_pipeline_writes_only_declared_keys` 的"12 份内容不出现 `conditions`／`chain`"半落地；
  - `tests/persistence_cases.gd:event_conditions` 与既有反例断言保持通过（只允许新增/改路径）；
  - **本地化（裁定 A9）**：`& tools/check.ps1 -Suite localization` 与
    `& tools/check.ps1 -UIOnly -UISuite localization` 通过；新增具名 check
    `locale_legacy_catalog_matches_current_sources`（`tests/localization_cases.gd`）：以本片动到的
    文案清单为常量（`REMOVED_SOURCES` 已删除的旧中文串、`REQUIRED_SOURCES` 新增/改写的源文），
    断言目录中不存在 `REMOVED_SOURCES`、`REQUIRED_SOURCES` 全部存在且 `text` 非空；
    `docs/verification.md` 登记目录条目数 before／after 与缺译条数；
  - 报告必须给出：`gates` 顺序与多命中拼接的样例、四个 `purpose` 的检查清单对照、E0 摘要、
    本地化口径①②③的判定结果；
  - **B2 完成前不得打包、不得发版**（§12；过渡态下"能编译但不生效"的键与未刷新的字典都会随包外发）。
- **已知最可能爆的点**：求值顺序与随机消耗（§4.3）——`relic_gate` 冻结前／后位置、
  `outcome_draw` 与 selector 展开的先后、生成器判定在 `resolve_effect_copy` 之后；
  以及 `frozen_form`＝`in_place` 必须保持"作者对象回声"布局（键序不变）；
  本地化侧：把缺译写成通过，或只改目录不改盘点口径。
- **非目标**：trace 与 gate 全覆盖（B3）、跨事件 `next` 对象形态与 `chain`（B4）、
  作者手册再补文档（归 B2c，§19）、`get_view` 字段、`ui/`、提交管线。

## 18. B2b 派工要点（B2 收口；**已完成**：三项交付 `5a60cda`＋收口 C1／C2 `b6d45b5`）

- **定位**：B2 核心（`60869fc`）已改完产品代码且核心判据全绿，但**本批未完成**——缺三块：
  具名 check、依赖 check、本地化刷新。B2b 只补这三块与复跑证据，**不改产品语义**。
  **当前状态**：三块已落（`5a60cda`，四条判据绿，协调者独立复核），**续批剩 C1（hidden 立证）
  与 C2（场景 09 第三段）**；C3（场景 05 分文件）已按 A15 裁定，无需补。
- **域**：测试（具名 check）、依赖规范检查、本地化词表。产品代码（`core/room_events.gd`／
  `content_catalog.gd`／`snapshot.gd`）**只有在补场景过程中发现真缺陷时才可动**；动了就必须
  按 B2 的完整门禁重跑并说明原因。
- **可改文件（授权清单）**：
  - `spire-godot/tests/{event_cases,event_flow_cases,content_cases,persistence_cases,architecture_cases,localization_cases}.gd`
  - `spire-godot/assets/localization/legacy-en_US.json`
  - 必要时 `spire-godot/core/{room_events,content_catalog,snapshot}.gd`（仅修缺陷，须在报告里列明）
  - **不改**：`content/packs/*`、`content/templates/*`、`ui/**`、`core/game.gd`、`core/game_view.gd`、`docs/**`
- **交付物**：
  1. **§10 场景 05／08／09／13／15–18** 的具名 check：
     - 05 `event_condition_kinds_share_one_declaration`（三处 kind 集合相等；未知 kind 三处一致拒绝）
     - 08 `event_unified_option_capabilities`（含"单节点 + selector + outcomes"按 `outcome_draw` 抽取）
     - 09 `event_node_empty_policy`（**行为半**：普通节点零候选、多阶段返回既有 issue、上一节点选项 invalid；
       `node_empty` 单独 gate 名属 B3）
     - 13 `event_probe_and_projection_readonly`
     - 15／16／17／18 叠加四条（单条 optional／单条 hidden／两类叠加／同类多条叠加，含 `gates` 顺序、
       `mode`、`reason` 的 `"\n"` 拼接）
  2. **依赖规范 §4.2 三条 check**：`event_condition_kinds_share_one_declaration`、
     `event_single_evaluation_entry`（测试侧计数包装，生产无计数器）、
     `event_pipeline_writes_only_declared_keys`（内容半：12 份内容不出现 `conditions`／`chain`）
  3. **本地化（裁定 A9，口径见 §17）**：`python tools/localization_inventory.py` →
     `python tools/build_english_catalog.py`（模型不可用则人工补齐本片动到的条目）→
     词典与 B1／B2 收口后的校验文案一致 → 具名 check `locale_legacy_catalog_matches_current_sources`
     （`REMOVED_SOURCES` 清零、`REQUIRED_SOURCES` 有非空译文）
  4. **复跑证据**：B2 的完整门禁命令，含 `localization` 规则与界面门
- **判据命令（一次，不无故重复；在 spire-godot/ 下）**：
  ```powershell
  & <Godot console exe> --headless --path . --script res://build/event-oracle-20260916/event_oracle.gd -- --baseline=build/event-oracle-20260916/baseline.json
  & tools/check-content.ps1
  python tools/localization_inventory.py
  python tools/build_english_catalog.py
  & tools/check.ps1 -Suite event_flow,events,content,architecture,persistence,localization -Impact -KeepGoing -TimeoutSeconds 900
  & tools/check.ps1 -UIOnly -UISuite events,localization -TimeoutSeconds 900
  ```
- **DoD**：
  - E0 退出码 0、`PASS (94 scenarios, 0 failures)`、摘要 `1f11bea5…`（**逐字相同**）；
  - `-KeepGoing` 红集**只允许** `card_power`（`docs/verification.md:29`）；任何新红项即未完成；
  - §10 场景 05／08／09／13／15–18 全部具名 check 通过；依赖规范三条 check 落地并通过；
  - 本地化：`localization` 规则／界面门通过；口径①②③判定结果写入 `docs/verification.md`
    （目录条目数 before／after、缺译条数、`REMOVED_SOURCES`／`REQUIRED_SOURCES` 结论）；
  - 报告必须给出：`gates` 顺序与多命中拼接的实际输出样例、四个 `purpose` 的检查清单对照、
    `event_single_evaluation_entry` 的计数方式、本地化判定①②③、E0 摘要；
  - **B2b 完成前本片不得打包、不得发版**（§12；过渡态键与未刷新的字典都会随包外发）。
- **非目标**：`validate_failed`／`node_empty` 的单独 gate 命名与 trace（B3）；跨事件 `next` 与 `chain`（B4）；
  作者手册补写 `conditions`／`unavailable`／叠加语义（归 B2c，§19）；改 `content/packs` 语义；
  `get_view` 字段、`ui/`、提交管线。

## 19. B2c 派工要点（文档收尾：把 B2 的能力写进作者手册）

- **定位**：B2 已让 `conditions`／选项级 `unavailable`／`mode`／叠加求值生效，但四份作者文档仍停在
  B1b 版本（只写了"B2 起生效"与兼容拼写）。B2c 把这些能力写成可用能力，**并删掉过期标注**。
  这是裁定 A6 文档缺口的正式收口，不改产品代码、不改内容包。
- **可改文件（授权清单，只这五份）**：
  1. `spire-godot/content/README.md` §3 事件
  2. `docs/content-templates.md`（§H／H4／H5 与测试表行）
  3. `docs/content-generation.md`（§7 事件生成与结算）
  4. `docs/content-extension.md`（事件流程段与内容表 events 行）
  5. `spire-godot/tests/content_cases.gd`（仅在需要扩展文档 check 时，见下）
  **不改**：`content/packs/*`、`content/templates/*`、`core/**`、`ui/**`、本契约与依赖规范。
- **要写清的内容（逐项，缺一即未完成）**：
  1. **规范拼写 `conditions`**：1–8 条数组；每条 `{kind, mode, reason, …kind 字段}`；
     与 `availability` **互斥**（不得同时出现）；kind 只能取声明表列出的种类
     （`no_chastity_lock`／`has_relic`），新增种类由代码侧扩展、内容包不得自造；
  2. **选项级 `unavailable`**：`"hide"`／`"disable"`；与 `hide_when_unavailable` **互斥**；
     作用＝该选项**未被显式 `mode` 约束**的条目的默认模式；列出 §5.3 的完整优先级
     （条目 `mode` ＞ 选项 `unavailable` ＞ `hide_when_unavailable:true` ＞ 种类默认）；
  3. **`mode` 与两类模式的语义**：`optional`＝显示但禁用（按钮保留、悬浮／聚焦显示 `reason`）、
     `hidden`＝不生成（选项与候选都不出现）；
  4. **叠加求值**：全部条目满足才通过；**任一 `hidden` 命中即隐藏（优先级高于 optional）**；
     只有 `optional` 命中时**列出全部命中**，`reason` 按**声明顺序**用换行连接——
     **"声明顺序决定 `reason` 拼接顺序"必须明写**；不命中者不进列表；
  5. **兼容拼写的定位**：`availability`／`hide_when_unavailable` 继续可用、语义同上，
     新内容优先用规范拼写；两者同时出现会被拒收；
  6. **删除过期标注**：把 B1b 写的"B2 起生效／待 B2"等标注改为现行描述（B2 已落地）。
- **判据命令（一次；A17 时限固化）**：
  ```powershell
  & <Godot console exe> --headless --path . --script res://build/event-oracle-20260916/event_oracle.gd -- --baseline=build/event-oracle-20260916/baseline.json
  & tools/check-content.ps1
  & tools/check.ps1 -Suite content,architecture -Impact -TimeoutSeconds 600
  & tools/check.ps1 -UIOnly -UISuite events,localization -TimeoutSeconds 900
  # 旧标注/旧形态残留扫描（人工判读：命中项须逐条给理由）
  rg -n "B2 起生效|待 B2|B2 前|start_stage|\"stages\"" spire-godot/content/README.md docs/content-templates.md docs/content-generation.md docs/content-extension.md
  ```
- **文档 check 是否需扩展：需要（按 A18 最小改动、不得弱化）**：
  `event_author_manual_lists_current_fields`（`tests/content_cases.gd`）现判"README 字段表里的反引号
  标识符 ⊆ 校验器白名单 ∪ 已知非字段词表，且不出现 `start_stage`／顶层 `choices`"。B2c 要：
  ①把 `mode`／`optional`／`hidden`／`conditions`／`unavailable` 等新词纳入（`conditions`／`unavailable`
  已在白名单，`mode` 等属值词表）；②反向断言：README **不得**再把 `conditions`／`unavailable`
  描述为"B2 起生效／尚不可用"，并**必须**同时出现 `conditions` 与两类模式的关键词。
  扩展只允许"加断言／加词表"，**禁止**放宽既有断言。
- **DoD**：E0 退出码 0、摘要逐字相同；`check-content.ps1` PASS；`content`／`architecture` 全 PASS；
  `events,localization` UI PASS；残留扫描命中项为零或逐条有理由；文档示例仍**指向**两份模板
  （不复制第二份完整 JSON）；`docs/verification.md` 记录域＝文档收尾。
- **非目标**：改产品代码或内容包语义、跨事件 `next`（B4）、trace 文档（B3）、打包。

## 20. B3 派工要点（gate 命名全覆盖 + debug trace）

- **定位**：B2 已把可分离的可行性失败记成 `probe_failed`／`encounter_invalid`，但
  `validate_failed`（`probe()` 内部 `g.validate()`）与 `node_empty`（`enter_node` 的 issue 文案）
  仍未单独命名，trace 也尚未落地。B3 收口这两件，**不改玩家可见行为**（文案一字不改）。
- **可改文件（授权清单）**：`spire-godot/core/room_events.gd`（主）、必要时
  `spire-godot/core/snapshot.gd`（若 trace 相关形状需要，**不得新增存档键**）、
  `spire-godot/tests/{event_cases,event_flow_cases,architecture_cases,persistence_cases}.gd`。
  **不改**：`content/**`、`ui/**`、`core/game.gd`、`core/game_view.gd`、`docs/**`。
- **拆分方案（`probe` 与 `enter_node` 的具名化）**：
  1. `probe()` 内部按阶段产出**结构化结果**（新增 `probe_result(g,effects,option,cleanup) -> {"gate","reason"}`
     作为唯一实现，`probe()` 保留原签名＝返回 `.reason`，**不新增第二套探测逻辑**）。阶段与 gate：
     `effects`→`probe_failed`（现状）、`next_node`→取自节点入口的 gate（见下）、
     `validate`→**`validate_failed`**（新）、`held_pending`→现状"事件仍有尚未归还的装备。"（cleanup 专用，B3 起具名）。
  2. `enter_node` 增加结果形态（新增 `enter_node_result(g,id) -> {"issue","gate","detail"}` 作为唯一实现，
     `enter_node` 保留原签名＝返回 `.issue`）：空节点 → gate `node_empty`、`detail`＝节点 id、
     `issue`＝**原文案"这一阶段没有能够执行的选项。"**（B2b 已按此断言，不得改字）；
     节点不存在 → gate `stage_missing`（现状文案"下一阶段不存在。"）。
  3. `evaluate_option` 的可行性条目改从 `probe_result` 取 gate（`validate_failed`／`probe_failed`／
     `encounter_invalid`），叠加命中仍走状态条件条目（不变）；`chain_loop` 留给 B4。
- **debug 开关形态（§4.5 已定＋裁定 A20）**：trace 只挂在**游戏对象上的调试字段**（实现可经元数据或
  普通字段，均不得进 `state`／`View`／存档）；接口 `Events.trace_enabled(g)`／`event_trace(g)`／
  `trace_entry(g,fields)`／`clear_trace(g)`；条目 11 字段
  `{event,node,source_choice,option_id,decision,gate,kind,mode,index,reason,purpose}`；
  每次 `start` 在启用时**经同一接口**清空；release 默认关闭、运行不产出；
  **不授权改 `core/game.gd`**。
- **判据命令（一次；含开／关两遍 E0，A17 时限固化）**：
  ```powershell
  # 开关关闭（默认）
  & <Godot console exe> --headless --path . --script res://build/event-oracle-20260916/event_oracle.gd -- --baseline=build/event-oracle-20260916/baseline.json
  # 开关打开（临时把 g.event_trace_enabled 默认置 true 或用测试夹具开关后重跑，判据：摘要逐字相同）
  & tools/check-content.ps1
  & tools/check.ps1 -Suite event_flow,events,content,architecture,persistence -Impact -KeepGoing -TimeoutSeconds 900
  & tools/check.ps1 -UIOnly -UISuite events,localization -TimeoutSeconds 900
  ```
- **具名 check 清单（§10 已定义，B3 落地）**：03 `event_gate_names_are_total`（每次构建的每个作者选项
  至少一条 trace；decision∈四种；每条丢弃／隐藏带具名 gate，**含 `validate_failed`／`node_empty`**）、
  04 `event_hidden_relic_option_traced`（漂浮皮带群持有扣环：trace 记录 `source_choice=fight` 与具名 gate；
  候选集合与 E0 基线一致）、10 `event_trace_never_reaches_state_or_save`（snapshot／存档／View／`rng`
  不含 trace；开／关摘要相同）、19 `event_stacked_condition_trace_and_release`（叠加下每条命中条件各一条
  trace，`index` 与声明序一致；关开关后 `g.event_trace` 为空）。
- **DoD**：E0 开／关两遍退出码 0 且摘要**逐字相同**且**引擎错误日志命中 0 行**（A24）；
  `-KeepGoing` 红集 ⊆ {`card_power` 5 条, `installed_tools` 1 条}（A23）；四条具名 check 通过；
  `validate_failed`／`node_empty` 在 trace 与 `gates` 里可区分；
  玩家可见文案与候选 `reason` 逐字不变；`docs/verification.md` 记录域＝events／persistence。
- **非目标**：跨事件 `next` 与 `chain`（B4）；把 trace 暴露给 UI／译文；改任何文案。

### 20.1 B3b 收口清单（B3 核心已落地 `f95e96f`，本批未完成）

| # | 收口项 | 判据 |
| --- | --- | --- |
| D1 | §10 场景 03／04／10／19 四条具名 check 落地 | 四条 check 通过；03／19 按 **§4.5 A25 口径**写断言（**按 `(purpose, source_choice, option_id, gate\|kind, index)` 过滤，禁止按总行数**；选择器选项 `source_choice`＝作者 id、`option_id`＝冻结实例 id）；03 必须覆盖 `validate_failed`／`node_empty`／`held_pending` 的具名与**状态条件行的跨 purpose 相等不变量（缺行即失败）** |
| D1a | 修 `source_choice`／`option_id` 的字段语义（A25） | `trace_entry` 现把两者写成同一值（`room_events.gd:210,398`）→ 拆成"作者 id"与"冻结实例 id"；只影响 trace 行，不影响 state／View／存档／随机（E0 摘要必须不变） |
| D2 | release 不产出的证据链 | 默认关闭下：①`Events.trace_enabled(g)` 为假且 `event_trace(g)` 为空、该次求值 0 行；②E0 关／开两遍**摘要逐字相同**（协调者已两遍复核，收口报告需复述并附日志）；③**两遍都要核引擎错误日志命中 0 行**（A24；oracle 显式 `quit(0)`，退出码不反映脚本错误） |
| D3 | 修 `start` 清空走同一接口（磁盘复核缺陷） | ~~`core/room_events.gd:25` 的 `g.get("event_trace_enabled")`／`g.event_trace=[]`~~ → **已在 `9e08d2a` 修为 `clear_trace(g)`**；保留判据：场景 03／19 显式断言"上一事件的行不残留"，且 E0 关／开两遍摘要仍逐字相同 |
| D4 | `installed_tools` 分类结论 | **已定类＝既有红项**（A23，协调者已登记进 `docs/verification.md` 2026-09-16 B3 条目：`4d22a00` 之前同样红 → 非本片回归；根因方向＝夹具前置条件与当前卡牌／工具接口漂移，未定类未修）。B3b 只需复核门禁红集口径 ⊆ {`card_power` 5 条, `installed_tools` 1 条} |
| D5 | B3b 判据命令 | 见 §20 命令块（含 A17 的 900 秒时限）；报告需给 D1／D1a／D2／D3 的逐项证据、E0 两遍摘要与**引擎错误日志命中数** |

## 21. B4 派工要点（事件链：`next` 指向另一事件的节点）

- **定位**：人裁第 5 条的最后一块——"分流要能指向事件"。`next` 目前只接受 `"result"` 与同定义节点 id
  （`content_catalog._flow_next` 硬要求 `next is String`）。B4 打开跨事件形态并给出链的运行时表示。
- **可改文件（授权清单）**：`spire-godot/core/room_events.gd`、`spire-godot/core/content_catalog.gd`、
  `spire-godot/core/snapshot.gd`、`spire-godot/tests/{event_flow_cases,content_cases,persistence_cases,architecture_cases}.gd`。
  **不改**：`content/packs/*`（链不得写进 12 份内容）、`content/templates/*`（模板可另批加示例）、
  `ui/**`、`core/game.gd`、`core/game_view.gd`。
- **交付物（§3.2／§3.3 的落地）**：
  1. `next` 接受 `{"event":"<id>","node":"<node_id>"}`（对象形态），与 `"result"`／同定义节点 id 并列；
     校验：目标事件已登记、目标节点存在、**不得引用自身事件**（静态拒绝）；同定义节点仍只能向后；
  2. 跳转实现：重写 `room_event.id` 与 `room_event.stage`；`values`／`held` 延续；`cleanup_effects` 取
     链上并集（按 `key` 去重，离开时各执行一次）；`event_seen` 加入目标事件；`flow` 镜像按新定义重算；
  3. **`chain` 条件键**：只在真的发生跨事件跳转时写入 `chain:[event_id,…]`（抵达时不含该键）；
  4. **环守卫**：目标事件已在当前实例 `chain` 中 → 该选项在候选阶段 `disabled`、gate `chain_loop`；
  5. `snapshot`：接受 `chain`（数组、元素为已登记事件 id、不含重复），其余键集合不变；
  6. 依赖规范 `event_pipeline_writes_only_declared_keys` 的**链半**断言落地。
- **判据命令（一次；A17 时限固化）**：
  ```powershell
  & <Godot console exe> --headless --path . --script res://build/event-oracle-20260916/event_oracle.gd -- --baseline=build/event-oracle-20260916/baseline.json
  & tools/check-content.ps1
  & tools/check.ps1 -Suite event_flow,events,content,architecture,persistence -Impact -KeepGoing -TimeoutSeconds 900
  & tools/check.ps1 -UIOnly -UISuite events,localization -TimeoutSeconds 900
  ```
- **具名 check 清单（§10 已定义，B4 落地）**：11 `event_chain_jumps_to_another_event_node`
  （`room_event.id`／`stage` 切换、`chain` 含来源、`values`／`held` 延续、离开时并集 cleanup 各一次、
  `event_seen` 含目标）、12 `event_chain_loop_refused`（再次跳向链上事件 → invalid、gate `chain_loop`、
  `state`／`rng`／存档不变）；另加**静态**反例：`next` 引用自身事件／未登记事件／不存在的节点 → 整包拒绝。
- **DoD**：E0 退出码 0、摘要逐字相同（12 份内容不含链，摘要必须不变）；`-KeepGoing` 红集只允许
  `card_power`；场景 11／12 与静态反例通过；`chain` 不出现在 12 份内容与 E0 夹具里；
  依赖规范链半断言通过；`docs/verification.md` 记录域＝events／persistence。
- **非目标**：把链写进任何 `content/packs` 内容；UI 的链式展示（投影不动，`view.room_event` 字段不变）；
  B2c 的文档（链的文档化在 B4 之后另派，属同一 A6 收口链）。
