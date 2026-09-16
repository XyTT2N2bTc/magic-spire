# 事件系统结构契约（测绘 → 切分提案）

规划者契约（planner contract），2026-09-16。由规划者会话（Codex，只读沙箱）产出，
协调者仅做搬运与落库，未改动其内容。本文件冻结事件系统的结构地图、结构性缺陷、
可定位性改进方向与切分提案（E0–E6）；内部实现以代码为准，接口语义以本文件为准。
本文件不写执行结果：通过／失败／未执行只登记到 docs/verification.md。

状态：**needs-human-review 已审**（2026-09-16，人裁见"决定记录"）：实现范围冻结为 E1–E3；E6 维持现状；E4/E5 未排期。

## 决定记录（协调者，2026-09-16）

来源：人裁（本会话问答）。以下决定**覆盖原 §4 的批次状态**（§1–§3 与 §4 的方案内容保持规划者原文，不改写）。

1. **本片范围 = E1–E3**（定义归一 + 选项生命周期 + trace）。理由：三批均为行为逐字节不变的结构整理，且 E3 直接解决"定位难"这一本次痛点。
2. **E5 物理拆分未授权**：不新增 core 文件、不新增依赖边；标"未排期"。理由：属复杂计划，收益与风险不成比例，先看 E1–E3 结果。
3. **E6 已决 = 维持现状**：已持有「软化扣环」时【硬闯】隐藏，同时出现"持有扣环才可见"的【离开】。实现见 `content/packs/floating_belt_cluster.json` 的 `leave` 选项与 `core/room_events.gd` 的 `has_relic` 条件（提交 `4441120`）。理由：人明确选择现状；E6 因此不再改玩家可见行为。
4. **trace 可做，但提交时必须隐藏为 debug**：只经 debug 开关或构建判定产出（默认关闭）；release 运行不得产出，且不得影响候选、View、存档与随机；测试可显式开启后断言 trace。理由：人裁——诊断要留，但不能进入发布行为。
5. **`game.event_diagnostics()` 与 `get_view.room_event.hidden_options` 未授权**：trace 保持 core 内部 + 测试可见。理由：越过只读 View 白名单需单独批准，且 E1–E3 不需要。
6. **内容包 schema 不改**：E1 只做内部归一，外部 JSON 与既有校验规则保持不变。

注：`tests/event_flow_cases.gd:171-194` 现断言漂浮皮带群只暴露 fight/infusion，与决定 3 一致；将来若改 E6 政策，该断言须同步。

## 1. 结构地图

| 阶段 | 决策者 | 关键位置 | 决策内容 |
|---|---|---|---|
| 进入房间 | `Game._arrive_room` | `core/game.gd:2989-3003` | 按房间 `kind` 进入事件、商店、宝箱或战斗；事件调用 `Events.start`。 |
| 内容加载与校验 | `ContentCatalog` | `core/content_catalog.gd:13-22,92-108` | 扫描 JSON、解析 `kind/id/schema_version`、编译入既有注册表。 |
| 普通事件 schema | `ContentCatalog._definition/_references` | `core/content_catalog.gd:110-120,197-208,218-260` | 普通事件允许 `choices`、`allow_refuse`；校验 `reward/effects/recipe/selector/availability/encounter/item_rewards`。 |
| flow 事件 schema | `ContentCatalog._flow_references` | `core/content_catalog.gd:285-372` | 多阶段使用 `stages/start_stage`；每阶段有 `when/next/outcomes/allow_refuse`。普通事件字段与 flow 字段不是同一清单。 |
| 事件定义实例化 | `Events.start` | `core/room_events.gd:8-43` | 选择事件 ID、标记 `event_seen`、建立 `state.room_event`、决定普通路径或 flow 路径。 |
| 普通选项生成 | `Events.start` | `core/room_events.gd:44-66` | 依次处理遗物池为空闸门、selector 展开、recipe/effects、随机冻结、detail、`hide_when_unavailable`，最后追加拒绝选项。 |
| flow 选项生成 | `Events.enter_stage` | `core/room_events.gd:297-317` | 先过 `condition_met`，再展开 selector/outcome、遗物池闸门和阶段拒绝；不执行普通路径的 `hide_when_unavailable`。 |
| flow 条件 | `condition_met` | `core/room_events.gd:242-246` | 只读事件 counter 或 selector 数量；只服务 flow。 |
| 状态可用性 | `availability_issue` | `core/room_events.gd:581-591` | 运行时按 `kind` 硬编码匹配 `no_chastity_lock`、`has_relic`。 |
| 效果可执行性 | `probe_choice/probe` | `core/room_events.gd:560-579` | 复制整份 state，调用 `apply_effects`，flow 时还可能调用 `enter_stage`，最后执行 `g.validate()`。 |
| 候选构建 | `Game.candidates` | `core/game.gd:1904-1908,1927-1951,1953-1971` | 统一构建各阶段候选；事件阶段委托 `Events.candidates`。 |
| 事件候选 | `Events.candidates` | `core/room_events.gd:615-632` | 遍历已生成的 `event.options`，调用 `append_choice_candidate`；reward/result/battle 等阶段另行构建。 |
| 候选有效性 | `Game._candidate` | `core/game.gd:1689-1731` | 生成候选 ID、费用、`valid/reason/risk/detail/group`。选项若在前面被 `continue`，这里完全看不到它。 |
| 事件只读投影 | `Events.view` | `core/room_events.gd:810-840` | 输出事件名、intro、stage、report、result_status，以及 selector 的分组身份；不输出所有隐藏原因。 |
| 总 View | `GameView.build` | `core/game_view.gd:315-343` | 把 `room_event`、`candidates`、奖励面板和其他只读投影合并为快照。 |
| 显示调度 | `main.render` | `ui/main.gd:367-417` | `get_view`、建立 `ActionIndex`、按 `phase=="event"` 进入事件屏。 |
| 事件显示 | `EventScreen.build` | `ui/event_screen.gd:20-72` | 读取 `view.room_event` 和 `ui.actions`，显示 intro/report、selector 分组和普通候选。 |
| 候选按钮 | `EventScreen.action` | `ui/event_screen.gd:85-98` | `c.valid` 决定按钮是否禁用；有效候选显示 detail，无效候选显示 reason。 |
| selector 抽屉 | `EventScreen.selector_button/drawer` | `ui/event_screen.gd:74-135` | 只消费候选与 `room_event.selections`；实际提交仍使用原候选 ID。 |
| 选择提交 | `_submit` | `ui/main.gd:1906-1935` | 调用 `game.dispatch(candidate_id, version)`，失败写入 notice，成功保存并重新渲染。 |
| 提交复核 | `Game.dispatch` | `core/game.gd:2314-2382` | 校验版本、全局状态、重新生成候选、确认 `valid`，复制 state 后执行事务；失败完整回滚。 |
| 普通事件生效 | `Events.execute` | `core/room_events.gd:634-667` | 从 `event.options` 取冻结选项，再执行效果；分流到 item reward、encounter、card/relic reward、下一 flow 阶段或 result。 |
| 效果落地 | `apply_effects` | `core/room_events.gd:412-558` | 按效果顺序执行装备、资源、卡牌、道具、遗物、计数、暂存等；任一失败返回原因。 |
| 遗物重复失败 | `apply_effects` relic 分支 | `core/room_events.gd:532-535` | 已持有遗物时返回“已经持有这件遗物，不能重复领取”。 |
| 事件战斗开始 | `begin_battle` | `core/room_events.gd:723-740` | 冻结战斗 spec，设置 `room_event.stage="battle"`，并写入 `state.room_encounters[state.room]`，随后调用 `_start_battle`。 |
| 战斗生成 | `Game._start_battle` | `core/game.gd:456-507` | 读取 `room_encounters`，选择/冻结敌人组合、生成敌人、进入正式战斗回合。 |
| 事件战斗结算 | `Game._finish_battle` | `core/game.gd:683-694` | 若为事件战斗，绕过普通奖励路径，转给 `Events.finish_battle`。 |
| 事件战斗胜利 | `Events.finish_battle` | `core/room_events.gd:749-763` | 再次执行 `victory_effects`，设置 result、report、`prepare_pending`，不生成普通战斗卡牌/道具/遗物奖励。 |
| 普通奖励路径 | `Game._finish_battle` | `core/game.gd:695-707` | 非事件战斗才生成 `reward_options`、战斗道具、战斗遗物和整备。 |
| 事件奖励显示 | `GameView.reward_panel` | `core/game_view.gd:56-112` | 区分事件卡牌 reward、事件 item loot、普通战斗奖励、宝箱奖励。 |
| 结果离开 | `Events.execute("leave")` | `core/room_events.gd:674-682` | 执行 cleanup，检查暂存装备，进入整备或结束房间。 |
| 事件最终校验 | `Events.validate` | `core/room_events.gd:854-889` | 校验事件历史、阶段、战斗/loot 状态、遗物、暂存装备和计数。 |

案发包的输入在 `content/packs/floating_belt_cluster.json:7-27`：`fight` 有 `hide_when_unavailable`、`encounter` 和 `victory_effects.relic=softened_buckle`；`allow_refuse=false`。

## 2. 结构性缺陷清单

按“造成玩家可见故障”优先，再按“增加定位难度”排序。

| 缺陷 | 现象 | 根因 | 证据 | 玩家可见故障 | 定位变难 |
|---|---|---|---|---|---|
| 1. 可见性与奖励可行性耦合 | 已持有「软化扣环」后，【硬闯】整项消失，只剩【接受灌注】 | `hide_when_unavailable` 使用完整 `probe_choice`；探测会执行胜利遗物效果，重复遗物被判失败 | `core/room_events.gd:64,573-579,532-535`；包定义 `content/packs/floating_belt_cluster.json:15-27` | 是 | 是 |
| 2. 显示探测、提交复核、战后结算共用效果执行器 | 选项是否出现受结算语义影响；战斗胜利再次复用同一错误语义 | `probe` 复制 state 后跑 `apply_effects` 与 `validate`；`execute` 和 `finish_battle` 也跑 `apply_effects` | `core/room_events.gd:560-569,634-667,749-763` | 是 | 是 |
| 3. 四条资格通道并行 | 同一“不可用”概念可能由条件、availability、隐藏探测、奖励池四处决定，普通与 flow 结果不同 | `condition_met`、`availability_issue`、`hide_when_unavailable`、遗物池 `continue` 各自独立 | `core/room_events.gd:45-64,242-246,297-317,581-590` | 是 | 是 |
| 4. 普通事件与 flow 事件是两套构建器 | 同名字段在两类事件的默认值、允许键、执行时机不同 | 普通路径在 `start`，flow 路径在 `enter_stage`；schema 也分叉 | `core/room_events.gd:44-66,297-317`；`core/content_catalog.gd:218-260,285-372` | 是 | 是 |
| 5. 隐藏选项没有审计记录 | 玩家只能看到“少了一个选项”，日志和候选列表都没有说明 | 多处 `continue` 直接丢弃；只有仍存在的 invalid candidate 才有 `reason` | `core/room_events.gd:45,52,59,64,305,307,594-597` | 是 | 是 |
| 6. schema 与运行时是平行真相 | 新增一种条件或效果时，校验器和运行时必须手工同步；不同步会出现“能过校验但运行失败”或反之 | `content_catalog` 硬编码允许 kind；`room_events` 另有独立 `match` | `core/content_catalog.gd:397-404,427-469`；`core/room_events.gd:581-590` | 可能 | 是 |
| 7. 事件战斗借用普通战斗的 `room_encounters` 与奖励状态 | 事件战斗看似普通战斗，结算却走另一条奖励/整备路径，状态校验分散 | `begin_battle` 写普通 encounter 表；`_finish_battle` 按 `Events.active_battle` 分叉 | `core/room_events.gd:733-740,749-763`；`core/game.gd:683-707`；`core/snapshot.gd:213-215,233-238` | 可能 | 是 |
| 8. 冻结选项与候选期再次探测 | 到达时已冻结 `event.options`，显示候选时又重新 `probe_choice`；两次判定可能随状态或校验结果分歧 | 选项冻结与候选构建没有单一评估结果对象 | `core/room_events.gd:57-65,615-620,593-597` | 可能 | 是 |
| 9. `room_events.gd` 是超大职责模块 | 事件定义、生成、随机冻结、探测、效果、候选、投影、战斗桥、校验集中在一文件 | 约 890 行、约 50 个 static 函数 | `core/room_events.gd` 全文件；职责分布见上述行段 | 否 | 是 |
| 10. UI 只消费过滤后的候选 | `event_screen` 无法区分“未生成”“被隐藏”“生成但不可用”，也无法解释后端隐藏原因 | UI 只读取 `view.room_event` 与 `ActionIndex` | `core/game_view.gd:315-343`；`ui/event_screen.gd:20-72` | 是 | 是 |

## 3. 可定位性单列

这次定位难，不是单个 `if` 写错，而是链路被拆散：

1. 玩家看到的是 UI 少了按钮；真正决策在 `room_events.start:64`。
2. `start` 调的是 `probe_choice`，后者再进入 `probe → apply_effects(relic)`；故障语义跨越了可见性、效果和奖励。
3. 候选生成时又重新探测，导致“事件实例中有什么”和“当前候选列表有什么”不是同一层数据。
4. `condition_met`、`availability_issue`、`hide_when_unavailable`、遗物池闸门四条通道没有共同的判定结果类型。
5. 隐藏选项直接 `continue`，没有 `choice_id/stage/gate/reason` 记录。
6. schema 的允许 kind 与运行时 `match` 各自维护，新增条件必须手工改两份。
7. 事件战斗还跨到 `room_encounters`、普通战斗结算和 `snapshot` 校验，增加了间接路径。

最小可行改进方向：

- 增加一个仅 core/test 可读的临时 `EventOptionTrace`：
  `event_id`、`stage`、`source_choice`、展开后的 `option_id`、`gate`、`decision`、`reason`、`payload_hash`。
- 每次选项被 `continue` 或变成 invalid 时都记录具名原因：
  `relic_pool_empty`、`condition_failed`、`availability_failed`、`effect_probe_failed`、`encounter_invalid`、`validate_failed`。
- 第一阶段不放入 `state`、存档或 `get_view`，避免改变现有接口；测试可直接断言 trace。
- 第二阶段若要让玩家看见“为什么不可用”，再单独裁决“保留并禁用”还是“继续隐藏但保证离开入口”，不能和内部重构混做。

## 4. 切分提案

### 模块边界

| 模块 | Deep Module 小接口 | 允许依赖 | 非目标 |
|---|---|---|---|
| Event Definition | `load(id) -> EventSpec`、`validate(document) -> Issue[]`、`stage_choices(spec, stage) -> Array` | `content_catalog`、`data/room_events`、既有注册表 | 不执行效果、不访问 UI |
| Event Option Engine | `build(g, stage) -> Array[OptionInstance]`、`evaluate(g, option, purpose) -> Evaluation` | Application、Relics、Enemies、Equipment 查询 | 不生成 UI、不提交事务 |
| Event Trace | `record(entry)`、`entries() -> Array`、`clear()` | 只被 core 调用 | 不进入 `state`、存档、View、文案 |
| Event Projection | `view(g) -> Dictionary`、`candidates(g, out) -> void` | Option Engine、Game candidate sink | 不改规则、不重新推导另一套资格 |
| Event Battle Bridge | `begin(g, spec)`、`active(g)`、`finish(g, saturated)` | Game 战斗入口、Enemies、事件效果 | 不生成普通战斗奖励 |
| UI Event Consumer | 继续使用 `view.room_event`、`view.candidates`、`dispatch(id,version)` | 只依赖 Game View 与 ActionIndex | 不读 `game.state`，不直接调用 core 规则 |

允许依赖方向：

`content_catalog/data → Event Definition → Event Option Engine → Event Projection/Event Battle Bridge → Game → GameView → ui/event_screen`

UI 只调用 `get_view` 和 `dispatch`；core 不依赖 UI。
若物理拆成新文件，至少会新增 core 模块，属于复杂计划，必须人审。

### 分批

| 批次 | 范围 | 性质 | 独立判据与 oracle |
|---|---|---|---|
| E0 基线 | 记录现有普通/flow 事件、floating belt、事件战斗快照、候选数量/顺序 | 不改产品 | 形成候选数组、`room_event.options`、`state`、随机计数的基线；只作为后续比较输入 |
| E1 定义归一 | 在 `content_catalog` 内把普通/flow 定义转成统一内部 `EventSpec`，外部 JSON 不变 | 行为逐字节不变 | `events,event_flow,content,architecture`；内容包校验通过；候选 ID、顺序、文本、随机域全等 |
| E2 选项生命周期 | 把生成、条件、availability、效果探测整理成统一 `Evaluation`；先保留现有隐藏/禁用语义 | 行为逐字节不变 | `events,event_flow,content,architecture`；探测前后 snapshot、RNG、日志不变；floating belt 仍与当前基线一致 |
| E3 可定位性 | 加临时具名 trace，覆盖所有 `continue` 和 invalid 原因 | 行为逐字节不变 | 新增事件 trace 断言；候选数组、View、日志、存档和随机结果逐字节不变 |
| E4 战斗桥 | 抽出事件战斗 begin/active/finish；保留现有 `room_encounters` 兼容行为 | 行为逐字节不变 | `events,event_flow,rewards,battle_saturation,persistence,enemies`；事件战斗仍跳过普通奖励、胜利效果只执行一次 |
| E5 物理拆分 | 将 Definition、Option Engine、Trace、Battle Bridge 从 890 行模块拆为小文件 | 预期行为不变，但新增依赖边 | 重跑 E1-E4 全部 oracle；每个新模块文件保持项目行数阈值内；需人审新文件授权 |
| E6 玩家可见政策 | 决定重复遗物、隐藏选项和无可离开选项的产品语义 | 必然改变玩家可见行为 | `events,event_flow,content` + UI `events`；明确断言按钮数量、禁用原因、离开路径和文案 |

### 必然改变玩家行为、需人裁的选项

1. 已持有「软化扣环」时，【硬闯】：
   - 保留并禁用，显示“胜利奖励已持有”；
   - 继续隐藏，但强制提供离开选项；
   - 改为无遗物或替代奖励。
2. `allow_refuse:false` 且所有有效选项被隐藏时，是否强制 schema 拒绝该内容包。
3. 是否允许在 `get_view` 中增加 `hidden_options`/`option_diagnostics`。这会越过现有只读 View 白名单，必须单独批准。
4. 是否把事件战斗的 encounter ID 从 `room_encounters` 分离成专用 `room_event.battle.encounter_id`。可先用兼容适配器，避免一次改变存档形状。

### 规划契约附带 Gherkin

- **隐藏原因可追踪**
  Given 事件选项含 encounter 胜利遗物且角色已持有该遗物
  When 构建事件选项
  Then 生成具名 trace，包含 `source_choice=fight`、`gate=effect_probe`、具体 reason；候选与当前基线保持不变，直到 E6 获批。

- **探测无副作用**
  Given 任一普通或 flow 事件
  When 调用 `get_view`、`candidates`、选项探测
  Then `state`、RNG、日志、版本和装备实例不变。

- **普通/flow 统一内部表示**
  Given 等价的普通和 flow 选项
  When 经过 Definition 层
  Then Option Engine 接收同一内部字段语义；外部 JSON 与现有校验规则不变。

- **事件战斗结算隔离**
  Given floating belt 的 `fight` 已进入事件战斗
  When 击败全部敌人
  Then 只执行事件 `victory_effects`，进入事件 result，跳过普通战斗奖励，并保留 `prepare_pending` 语义。

- **玩家政策变更**
  Given E6 选定“保留并禁用”
  When 重复遗物条件成立
  Then UI 保留【硬闯】按钮、按钮不可选、显示确定原因，并仍提供可完成的离开路径。

### Validator procedure

1. 运行受影响规则套件：`events,event_flow,content,architecture`；E4 追加 `rewards,battle_saturation,persistence,enemies`。
2. 若涉及事件界面，运行 UI `events` 套件；不运行全量回归。
3. 比较 E0 基线与当前版本的：
   - `room_event.options`；
   - 候选 ID、数量、顺序、`valid/reason/detail`；
   - `state`、日志和 RNG；
   - 事件战斗胜利后的阶段、奖励字段和 `prepare_pending`。
4. 手动/脚本路径：
   - 启动 `Practice_floating_belt_cluster`；
   - 验证首次进入显示【硬闯】【接受灌注】；
   - 注入已持有 `softened_buckle` 的状态；
   - 检查 trace 是否记录隐藏原因；
   - 按 E6 选定政策检查按钮、原因和离开路径；
   - 完成战斗，确认只进入事件结果而不进入普通战斗奖励。
5. 结果必须区分 `passed/failed/unverified/skipped`；未运行的套件不能算通过。

## 5. 与既有三片的关系

- **响应管线片**：保持 `game.dispatch(candidate_id, expected_version)`、`game.get_view()`、候选 ID＋版本提交和 UI 只读边界不变。不得把事件 trace 偷塞进 UI 缓存。
- **装备查询片**：继续复用 `RoomEvents.selector_values` 的只读作用域；不改装备索引生命周期，不实现 `escape_preview` 按需化。
- **文案路由/按需片**：事件候选 detail 已经走 `event.choice` 路由入口（`core/room_events.gd:593-604`）。本片不改文案、不改 `copy_router`、不改 `get_view.card_texts`。
- **越界待批**：
  - 新增 `game.event_diagnostics()`；
  - 增加 `get_view.room_event.hidden_options` 或 trace 字段；
  - 修改内容包 schema 以表达新的 availability/奖励语义；
  - 新增 `core/event_*.gd` 生产文件。

这些都不能在本片默认落地，须协调者转人确认。

## 6. 假设与最可能爆掉的假设

1. 现有 `events/event_flow/content/architecture` 套件仍是事件行为 oracle；其中 `event_flow_cases.gd:171-194` 当前明确断言 floating belt 只暴露 `fight/infusion`。
2. 普通与 flow 可以归一为内部结构，但不能假设外部字段或默认值已经等价。
3. 随机冻结顺序必须保持；归一化若改变 `event` RNG 消耗，就会造成内容和存档差异。
4. trace 必须是临时诊断数据；一旦进入 `state`，就会扩大快照、校验和迁移范围。
5. 事件战斗当前借用 `room_encounters` 是事实，不代表可以直接改存档字段。
6. 最可能爆掉的是 E6 的产品决策：重复遗物究竟是“不可用”“替代奖励”还是“仍可战斗但不再给遗物”。这不是内部重构能自行决定的。
7. 第二可能爆掉的是新模块授权与依赖方向：物理拆分会新增 core 文件，不能只凭规划者判断。

**结论：本提案标记为 `needs-human-review`。** 协调者需要转人确认新文件/新只读入口授权、重复遗物的玩家语义、是否允许修改内容包 schema，以及是否接受事件战斗从 `room_encounters` 中进一步解耦。
