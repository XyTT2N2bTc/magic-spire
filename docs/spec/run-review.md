# 本局回顾（战报面板：本局标识 · 节点概况 · 卡组）

契约文件：回顾面板的入口可见性、三块取源、只读保证、只读地图口径、布局、失败语义与验证判据。
内部实现以代码为准，接口语义以本文件为准；函数名与稳定 ID 是锚点，本文件不写行号。
本文件不写执行结果：通过／失败／未执行与红集登记 `docs/record/verification.md`。
依赖约束（允许改动文件表）见 `docs/spec/run-review-dependencies.md`。

路径约定：不带 `spire-godot/` 前缀的源码、测试与工具路径（`core/`、`ui/`、`data/`、`tests/`、
`tools/`、`build/`）均相对 `spire-godot/`；`docs/` 相对仓库根。

## 域

- 收束对象：**玩家在路线屏与通关屏打开的本局回顾面板**——它把本局标识、节点概况（只读紧凑地图＋进度行）
  与卡组列表放在同一个抽屉里展示。
- 不含：塔路生成与路线投影本身（`core/game.gd::route_view`，见 `docs/spec/response-pipeline.md`）、
  本局标识的字段与复制语义（见 `docs/spec/seed-identity.md`）、卡面文案的按需投影
  （见 `docs/spec/ondemand-copy.md`）、存档与固定点（见 `docs/spec/save-fixed-points.md`）。
- 明文口径：回顾面板是**纯只读显示入口**。它不产生提交、不消费候选、不推进随机、不写盘，
  也不改显示态以外的任何运行状态；打开与操作后 `view.version`、`export_snapshot()`
  与存档字节必须逐字节不变。

## 接口

### 面板组装（唯一入口）

```gdscript
# ui/run_review.gd（新建；extends RefCounted，与 ui/event_screen.gd::drawer 同形）
const TITLE_KEY="ui.run_review.title"
const TITLE_FALLBACK="本局回顾"
static func title_text(ui) -> String        # = ui._text(TITLE_KEY,TITLE_FALLBACK)；面板标题与两个入口按钮共用
static func can_open(route: Array) -> bool  # = not route.is_empty()：入口可见性的唯一判据
static func drawer(ui) -> void              # 建 ui._drawer_shell(...) 面板并追加三块

# ui/main.gd 侧唯一接线点
const RunReview=preload("res://ui/run_review.gd")
var show_run_review=false                   # 并加入 const DRAWERS
# _refresh_drawers() 非主页分支：if show_run_review: RunReview.drawer(self)
# _drawer_shell() 的全窗遮罩条件增 show_run_review（面板宽 1480 与 show_deck 相同，取同一种整窗遮罩面）
```

Esc 与安卓返回键沿既有 `DRAWERS` 清单关闭，不新增关闭通道。

### 三块取源（逐项点名）

| 块 | 取源（唯一） | 口径 |
| --- | --- | --- |
| 本局标识 | `ui.seed_report_text()` | 标签文本与 `seed_report_text()` **逐字节相等**；不得出现第二份种子文案 |
| 节点概况·进度 | `view.route` | `{floor}` = `status in ["completed","current"]` 的房间的最大 `floor` ＋1（`floor=-1` 的塔底 → 0，与 `core/game_view.gd::run_header` 的「第0层」同口径）；`{nodes}` = `status=="completed"` 的房间数 |
| 节点概况·地图 | `ui/route_map.gd` 的同一渲染器：`rooms=ui.view.route`、`compact=true`、`read_only=true` | 不裁剪 `rooms`、不重算 `status`、不新增第二份绘制 |
| 卡组 | `ui/deck_browser.gd::setup(ui, ui.view.deck_cards, false, ui._text("ui.run_review.deck_empty","卡组为空。"))` | 全量入口：只吃 `view.deck_cards`；默认筛选下条目数＝`view.deck_cards.size()` |

- 不使用 `view.rooms_completed` 作为进度来源：进度行与地图必须来自同一数组，避免同一语义的第二个来源。
- 卡组块的现算文案经 `deck_browser.setup` 内部既有入口 `ui.game.live_card_text_set`
  （`docs/ondemand-copy.md` §1.3 登记的全量只读入口）；`run_review.gd` 自身不调用任何 `ui.game.*`。

### 只读保证（实现必须同时满足）

1. 不调用 `ui._submit`、`ui.actions`、`ui.game.dispatch`、`ui._save_progress`、`ui.copy_seed`；
   不读写 `ui.game.state`（测试与夹具除外）。
2. 回顾地图实例只读：`room_selected` 不接 `ui._select_route_room`，`drawings_changed` 不接
   `ui._save_progress`（这两条连接只属于 `_route_screen()`）。
3. `route_map.read_only=true`：`_ready()` 不建房间按钮、`_input()` 首行早退（见下节）。
4. 回顾地图实例的 `buttons` 为空，`strokes` 保持空；不写 `ui.map_drawings`、不进 `ui.candidate_buttons`。
5. 除 `_open_drawer`／`_close_drawers` 的抽屉显示态外，本面板不改任何 `ui` 字段。

判据：打开、滚动、筛选、点击面板内任意位置后，`view.version`、`ui.view.candidates`、
`ui.game.export_snapshot()`（含 `state.rng` 计数）与存档主档＋`.bak` 的字节与 mtime 全部不变。

### 入口可见性

- 唯一判据 `RunReview.can_open(view.route)`：`view.route` 为空（`core/game_view.gd::build` 里
  `state.practice` 或 `state.room=="prison"` 的练习局与牢房）时**不创建**入口控件——不是
  `visible=false` 的空壳，`ui.find_children("OpenRunReview","",true,false)` 必须为空。
- 两个入口，同一个 `name="OpenRunReview"`（两屏在 `render()` 里互斥，任意时刻至多一个）：
  - 路线屏 `ui/main.gd::_route_screen()`：追加在右栏 `navigation`（`MapOverview`／`MapLocate` 之后），
    既有地图控件与布局不动。
  - 通关屏 `ui/main.gd::_demo_exit_screen()`：追加在 `DemoExitPanel` 的按钮列
    （`view.demo_exit` 成立时 `view.route` 仍非空）；面板 rect 高度可按内容调整，
    判据是每个可见子控件都在面板矩形内（含 `view.demo_finished` 多出「返回菜单」的两态）。
- 入口点击只做 `ui._open_drawer("show_run_review")`；不触发候选、不出发、不写盘。

### 布局

- 单抽屉：`_drawer_shell(RunReview.title_text(ui),Rect2(60,78,1480,780),GOLD)`
  （与 `_deck_drawer`／`EventScreen.drawer` 同尺寸同遮罩面）。
- 内容列顺序：`本局标识`（小标题＋标识文本）→`节点概况`（小标题＋进度行＋只读地图）→`卡组`（小标题＋列表）。
- 尺寸口径：只读地图 `custom_minimum_size=Vector2(710,420)`；卡组浏览 `custom_minimum_size.y=340`。
  卡组浏览是共享控件的复用：`deck_browser.gd` 的网格固定 6 列、卡片 210 宽（`_display_card` 传入尺寸），
  网格最小宽约 1380（工具条另需约 800），因此卡组块必须整宽，**不与地图并排**：
  两栏「左地图右卡组」在 1600 宽视口内放不下，本片取单列 + 整宽卡组。
- 内容列放进 `ui._scroll()` 返回的滚动列；总高超出面板时纵向滚动（接受「卡组首行在折叠线以下」），
  控件不得溢出面板矩形。
- 节点名（检查定位用，唯一）：`RunReviewIdentity`／`RunReviewProgress`／`RunReviewMap`／`RunReviewDeck`。

### 只读地图的实现口径（`ui/route_map.gd`）

- 新增 `var read_only=false`，只影响两处：
  - `_ready()`：`read_only` 时不遍历 `rooms` 建 `Button`、不连 `pressed → room_selected.emit`
    （`buttons` 保持空，房间因此没有任何点击命中格）。
  - `_input()`：`read_only` 时第一行早退（不绘画、不接管左键平移；滚轮仍由父滚动控件处理）。
- `_draw()`、`point_for()`、`_layout_nodes()`、`ink_position()` 不改：同一渲染器、同一坐标与配色，
  紧凑模式继续只画图标与层号（`compact` 分支）。
- `read_only=false`（路线屏）逐项不变：既有 `ROUTE` 断言（每房间都有按钮、节点点击出发、
  右键绘画、按住左键平移）继续成立。
- 回顾地图的父节点是滚动列内的 `VBoxContainer`，`_background()` 走 `scroll==null` 分支（纸面按控件矩形铺满）；
  不得为此改 `_draw()`。

### 本地化 key 表（zh_CN 与 en_US 各一条，`source` 与 zh_CN 的 `text` 逐字相同）

| key | zh_CN `text` | zh_CN `context` | en_US `text` |
| --- | --- | --- | --- |
| `ui.run_review.title` | 本局回顾 | 回顾面板标题与路线屏／通关屏两个入口按钮；唯一文本入口 `RunReview.title_text` | Run Review |
| `ui.run_review.identity` | 本局标识 | 回顾面板第一块小标题 | Run identity |
| `ui.run_review.route` | 节点概况 | 回顾面板第二块小标题 | Route overview |
| `ui.run_review.deck` | 卡组 | 回顾面板第三块小标题 | Deck |
| `ui.run_review.progress` | 已到达第 {floor} 层 · 已走过 {nodes} 个节点 | 节点概况的进度行；{floor}／{nodes} 由 `view.route` 现算的整数 | Reached floor {floor} · {nodes} nodes travelled |
| `ui.run_review.no_route` | 没有可回顾的路线数据。 | `view.route` 为空而面板已开时的失败态，替代地图位置 | No route data to review. |
| `ui.run_review.deck_empty` | 卡组为空。 | 卡组块空数据文案，交给 `deck_browser.setup` 的 `empty_message` | The deck is empty. |

- 所有玩家可见文本只经 `ui._text(key, 与 zh_CN 逐字相同的 fallback)`；两个入口按钮与面板标题共用
  `RunReview.title_text(ui)`，不复制字面量（复制会触发 `stale_callsite` 诊断）。
- 标识文本 `ui.seed_report_text()` 是四要素引用文本，本身不随语言切换（见 `docs/spec/seed-identity.md`）；
  面板内**不**再造一份翻译副本，也不新增复制控件（复制仍由路线屏角标 `copy_seed()` 承担）。

### 失败语义

- `view.route` 为空而面板已开（相位被替换的极端情形）：地图块位置显示 `ui.run_review.no_route` 文本，
  不空白、不报错、不显示空地图；卡组块照常显示（练习局也有卡组）。
- `view.deck_cards` 为空：交给 `deck_browser` 的既有空数据文案 `ui.run_review.deck_empty`。
- 进度行：`completed∪current` 为空时按 `{floor}=0,{nodes}=0` 显示（防御；`route_view` 正常产出下
  当前房间必在该集合内）。计数不得在面板里另开第二套推导。
- 面板内不出现规则失败提示：它不提交任何东西；也不为缺席数据留空白格且无记录。

## 场景与判据（Gherkin）

落点：窗口 `route` 分类 → `tests/route_ui_cases.gd`（新增 `run_review(t)`，在既有 `run(t)`
恢复存档隔离之前调用；复用既有真实指针助手与真实夹具）。每条判据都必须给出**敏感性证明**
（关掉或改错它会让哪条断言变红），没有敏感性证明的检查不进验收。

### 场景 A｜打开回顾屏不动规则、候选、随机与存档

- Given 路线屏已渲染（真实开局：`ui.restart(42)` → `t.click("departure",{"op":"skip"})`）、
  存档隔离目录内已有主档；
- When 打开回顾屏并在面板内滚动、切换卡组筛选、点击地图区域；
- Then `ui.view.version` 不变、`ui.view.candidates` 与打开前深比较相等（无候选被消费）、
  `ui.game.export_snapshot()` 逐字节相同（含 `state.rng`）、
  `persistence_cases.stamp(ui.saves,"tower")` 前后主档与 `.bak` 的字节与 mtime 都不变，
  且 `preload("res://tests/persistence_cases.gd").unchanged(...)` 通过；
  `RunReviewMap` 的 `strokes` 在面板内右键拖拽后仍为空。
- 具名 check：`ROUTE run review is not part of rules, candidates or randomness`
- 敏感性：把面板内任一交互接到 `ui._submit(...)`／`ui._save_progress()`（例如把回顾地图的
  `drawings_changed` 接上 `_save_progress`）→ 快照或 mtime 断言变红。

### 场景 B（本片最重要的反例）｜在回顾屏里点地图节点不出发

- Given 地图相位（`view.phase=="map"`）且存在 `status=="available"` 的节点，记录 `state.room`；
- When 打开回顾屏，在该节点于回顾地图中的屏幕位置（`graph.get_global_transform()*graph.point_for(room)`）
  做真实左键点击；
- Then `ui.view.phase=="map"`、`ui.view.rooms_completed` 不变、`ui.view.journey` 不变、
  `ui.view.version` 不变、`ui.game.export_snapshot()` 不变；且 `RunReviewMap` 满足
  `read_only==true` 与 `buttons.is_empty()`（回顾地图没有任何节点命中格）。
- 具名 check：`ROUTE run review node click never departs`
- 敏感性：①去掉 `_ready()` 里的 `read_only` 守卫 → `buttons.is_empty()` 变红；
  ②在回顾面板接上 `graph.room_selected.connect(ui._select_route_room)` 并让按钮存在 →
  点击后 `view.phase=="travel"` 且 `version+1`，相位与版本断言变红。

### 场景 C｜节点地图与 `view.route` 同源，已走过路径随真实行进

- Given 全新塔路（`state.traversed_edges` 为空）打开回顾屏；
- Then `RunReviewMap.rooms == ui.view.route`（逐项相同，同一来源）；
  投影里 `paths[].status in ["travelled","travelling"]` 的边集合为空
  （边界：一个节点都没走过时地图不画金色路径），并与 `ui.game.state.traversed_edges` 一致；
- When 关闭回顾屏，用真实节点点击出发并走完这段路程（既有自动行进与等待写法）；
  Then 再次打开回顾屏：投影的 travelled 边恰为 `[[from,to]]` 一条，等于出发的那条边，
  且与 `ui.game.state.traversed_edges` 逐项一致。
- 具名 check：`ROUTE run review map matches the projected route`
- 敏感性：把回顾地图改成过滤 `rooms`（只画已到过节点）或把 `status` 重算／写死 →
  `rooms == ui.view.route` 或边集合断言变红；只画「已到过」还会让边界场景的 `rooms` 条数变红。

### 场景 D｜进度行取自同一投影，且与权威状态一致

- Given 全新塔路（当前房间为塔底入口 `entrance`，`floor=-1`，`completed_rooms` 为空）打开回顾屏；
- Then `RunReviewProgress.text` 的 `{floor}` 为 `0`（`max(floor)+1`）、`{nodes}` 为 `0`；
- When 真实出发并抵达下一节点后重开回顾屏；
- Then `{nodes}` 等于 `ui.game.state.completed_rooms.size()`，`{floor}` 等于
  `max(state.room 与 completed_rooms 各房间的 floor) + 1`（用 `ui.game.room_data(...)` 求层）。
- 具名 check：`ROUTE run review progress counts the walked nodes`
- 敏感性：把当前房间也计入节点数（`nodes+1`），或把层号来源换成 `view.rooms_completed`／
  顶栏所在层等第二个来源 → 出发后的数字断言变红（新局下 `completed_rooms` 为空而当前房间为塔底
  `floor=-1`，两来源在同一点上分叉）。

### 场景 E｜卡组条数等于 `view.deck_cards.size()`

- Given 回顾屏打开（默认筛选、默认排序）；
- Then `RunReviewDeck.cards.size()==ui.view.deck_cards.size()`、
  `RunReviewDeck` 内 `DeckGrid` 的子节点数等于 `ui.view.deck_cards.size()`、
  `DeckCount` 文本中的总数等于 `ui.view.deck_cards.size()`；
  搜索框输入后计数分母不变、分子按既有筛选语义变化。
- 具名 check：`ROUTE run review deck lists every physical card`
- 敏感性：把来源换成 `view.draw_cards`／`view.hand`／按 `powers` 过滤 → 条数断言变红；
  另写一套卡片列表（第二套列表）会让 `RunReviewDeck` 的子节点类型与 `DeckGrid` 断言变红。

### 场景 F｜种子文本与 `seed_report_text()` 同源

- Given 回顾屏打开；Then `RunReviewIdentity.text == ui.seed_report_text()`（逐字节）；
- When 走真实通关屏的「继续游玩」重建塔路（`demo_exit_cases.exit_fixture` + 真实 `demo_continue` 候选）
  后重开回顾屏；Then 标识文本随新的 `tower_generation` 与 `seed` 变化，仍等于 `ui.seed_report_text()`。
- 具名 check：`ROUTE run review identity reuses the run report text`
- 敏感性：把标识写成面板自己的硬编码或第二份拼装 → 逐字节相等或「随重建变化」断言变红。

### 场景 G｜入口可见性跟随路线数据

- Given 练习局（`ui.restart(42,true,"equipment")`，`view.route` 为空）与监狱牢房相位
  （既有真实路径 `tests/prison_ui_cases.gd::enter(t)` → 收押 → 入牢，`view.route` 为空）；
  Then `ui.find_children("OpenRunReview","",true,false)` 为空（不出现空壳入口）；
- Given 路线屏与通关屏（`view.route` 非空）；Then 恰好一个 `OpenRunReview`，
  且其 rect 落在 `RouteWorkspace`／`DemoExitPanel` 矩形内、不与既有控件相交。
- 具名 check：`ROUTE run review entries follow the route data`
- 敏感性：把可见性判据写成 `view.practice`／相位判断而漏掉监狱，或改成
  `visible=false`（控件仍存在）→ `find_children` 计数断言变红。

### 场景 H｜抽屉机制与既有面板一致，点击不穿透

- Given 从路线屏打开回顾屏（背后仍有可点的出发节点）；
- When 点击 `DismissDrawer` 遮罩、点击 `CloseDrawer`、按 `ui_cancel`（Esc 的 `InputEventKey` 写法）；
  Then 三种方式都关闭面板（`ui.show_run_review==false`，`ui.find_child("InformationDrawer",true,false)` 为 null），
  且关闭前后 `export_snapshot()` 与存档字节不变；
- When 在面板内部的空白／地图位置单击；Then 面板仍打开且 `export_snapshot()` 不变（点击没有穿透成背后行动），
  遮罩面覆盖整个视口（`DismissDrawer` 的 rect 为 1600×900）。
- 具名 check：`ROUTE run review behaves like the shared drawer`
- 敏感性：把面板 rect 挪到遮罩之外，或自建模态而不走 `_drawer_shell` →
  「面板内点击不关闭不穿透」或「Esc 关闭」断言变红。

### 场景 I｜两种语言都有文案，无缺译诊断，无投影缺失

- Given 回顾屏打开（zh_CN）；Then `ui.localization.diagnostics()` 为空
  （无 `unknown_key`／`stale_callsite`／`call_parameters`）；
- When 切到 en_US（经 `ui._set_language("en_US")` 或设置页真实选择）并重建回顾屏；
  Then 标题、三个小标题、进度行、`no_route`／`deck_empty` 备选文案都不含中文字符
  （用 `tests/localization_ui_cases.gd::chinese_runs` 扫描面板子树；标识文本是四要素引用文本，按契约保持不变）；
  切回 zh_CN 后文案复原；
- Then 打开回顾屏与滚动卡组块后 `ui.projection_misses` 为空（卡组属全量入口，不做 S 推导）。
- 具名 check：`ROUTE run review copy exists in both languages and records no miss`
- 敏感性：删掉任一条 en_US 条目 → 规则 `localization` 的
  `LOCALE English is complete for registered IDs` 与 `coverage("en_US").missing==0` 变红；
  把 `_text` 换成硬编码中文 → 面板中文残留扫描变红；
  改用 `ui.card_entry` 取卡面（显示集合 helper）→ `projection_misses` 出现 `card_entry` 记录，变红。

## 验收程序（validator 按此操作真实界面）

在 `spire-godot/` 下，用带窗口的真实运行（`tools/launch.ps1` 启动，或窗口化 `tools/check.ps1`），
以真实鼠标／键盘操作；不默认截图，必要时把截图作为补充证据写在验证记录里。

1. **正常局（路线屏入口）**：主页 → 开始新游戏 → 真实出发选卡 → 路线屏。
   1.1 右栏出现「本局回顾」入口，按下后打开面板：小标题三块齐、标识文本可读、
   进度行显示「已到达第 0 层 · 已走过 0 个节点」、紧凑地图画出全部节点且无金色路径、卡组块显示全部卡牌。
   1.2 在地图上任一「可前往」节点的位置单击 → 仍停在地图屏（无移动消息、无出发、无回合消耗）。
   1.3 在地图上按住右键拖拽 → 地图上不出现铅笔线（画笔只属于路线屏）。
   1.4 在面板内滚动到卡组块，输入搜索／切换费用筛选 → 计数分母不变；关闭后重新打开，游戏状态与界面一致。
2. **行进后的回顾**：关闭面板，真实点击节点出发并走完这段路；再开回顾 →
   地图出现金色已走路径（恰一行进方向）、进度行数字增加（节点数 = 已走过节点数）；层号与顶栏所在层一致。
3. **通关屏入口**：走到塔顶出口（或用既有 `exit_fixture` 夹具）→ 通关屏出现「本局回顾」入口，
   打开后三块齐；面板 rect 容纳所有可见按钮（含「结束并返回菜单」／「继续游玩」）。
4. **无数据时不摆空壳**：主页 → 练习与自定义进入练习局（`view.route` 为空）→ 无「本局回顾」入口；
   进监狱（既有 `tests/prison_ui_cases.gd::enter(t)` 的真实收押路径或真实被俘入牢）→ 同样无入口。
5. **语言**：设置 → 语言 → English → 重建回顾屏：标题、小标题、进度行、空数据文案为英文，
   面板内无残留中文（标识文本按契约保持四要素原文）；切回简体中文复原。
6. **失败语义抽查**：在面板打开时用夹具制造 `view.route` 为空（如替换为练习局 `view`）→
   地图位置显示「没有可回顾的路线数据。」而不是空白或报错。

判据：以上每一步都可复现；任何一步出现出发、回合消耗、存档写入、面板空白或报错，即为失败。
面板相关观察以真实运行截图或 `build/validator/` 下的一次性脚本作为补充证据，登记到
`docs/record/verification.md`。

## 证据入口（命令与判据）

```powershell
# 规则侧：本片改了本地化资源；architecture 作为 ui 新增文件的静态旁证（core 零改动）
& tools/check.ps1 -Suite localization,architecture -KeepGoing -TimeoutSeconds 900
# 窗口侧：route 为本片新 check 的落点，localization 复查诊断与英文残留
& tools/check.ps1 -UIOnly -UISuite route,localization -TimeoutSeconds 900
```

- 判据：退出码 0；每个分类 `SUITE RESULT: <name> PASS`；`summary.json` 的 `status=passed` 且
  `before==after`（同一源码指纹，无 `SOURCE CHANGED`）；`unrun=[]`。
- `route` 分类的具名 check 全绿即上表场景 A–I；新增断言数作为范围证据登记，不作为唯一判据。
- 不需要跑 `-Suite all`、oracle、像素、性能、打包；未跑项必须写进验证记录。

## 完成定义（DoD）

- 契约：本文件与 `docs/spec/run-review-dependencies.md` 已落盘；根 `AGENTS.md` 文档入口表已登记两行。
- 实现：`ui/run_review.gd`（新建）、`ui/route_map.gd`（`read_only`）、`ui/main.gd`（入口与抽屉接线）、
  两份本地化、`tests/route_ui_cases.gd`（含 `run_review(t)`）均已按上表落地；
  `core/`、`data/`、`Snapshot.REVISION`、`ui/feedback_report.gd`、未跟踪的
  `spire-godot/tools/play_release.ps1` 零改动。
- 证据：上面两条命令退出码 0 且指纹未漂移；每条判据的敏感性证明实测（还原后复跑）。
- 记录：`docs/record/changelog.md` 追加一条（日期＋范围＋证据＋未推送）；
  `docs/record/verification.md` 追加一节（日期＋域＋命令＋逐分类结果＋具名 check＋敏感性实测＋
  与契约的差异＋未跑项）。实现完成前不得在计划或报告里宣称这些记录已存在。
- 独立审查：实现完成后由独立子代理（新会话）按本契约边界审查，审查者不改代码。
