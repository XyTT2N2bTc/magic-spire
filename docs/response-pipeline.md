# 响应管线接口契约（输入 → 提交 → 落地）

规划者契约（planner contract），2026-09-15。冻结本片两个接缝的接口语义，
供实现者、加固者、验收者只读消费；内部实现以代码为准，接口语义以本文件为准。
本文件不写执行结果：通过／失败／未执行只登记到 docs/verification.md。

## 0. 领域、现状事实与非目标

领域：一次玩家输入从进来到界面落地。跨两个接缝：
- 接缝 A（UI↔core）：`game.dispatch(candidate_id, expected_version)`、`game.get_view()`、
  `ui/action_index.gd`、`ui/target_queries.gd`。
- 接缝 B（UI 内部）：现唯一整树入口 `ui/main.gd:364 render(snapshot)`，
  以及"选择类点击"与"提交类点击"两条路径。

已核实现状（契约据此写，落地前不改这些事实）：
> 行号约定：本文行号捕获于 2026-09-15；`core/game.gd` 在邻接表片（docs/equipment-query-seam.md）与
> 文案收口／按需片（docs/ondemand-copy.md）推进期间会移动（例：`get_view` 捕获时在 `:2805`，
> 同日随邻接表片 B9 已到 `:2948`）。**函数名才是稳定锚点**，行号以落地时仓库为准，动手前用 `rg` 复算。
- `game.dispatch` 的唯一调用点是 `ui/main.gd:1873`；UI 侧 `game.*` 全部读取只有
  `get_view`×4（main.gd:278、367、1874、1919）、`dispatch`×1、`restore_snapshot`×1、
  `restart_snapshot`×1、`number`（显示格式化）、`Prison` 常量（立绘选择）。UI 不读也不写 `game.state`。
  **按需入口（2026-09-15，三个均已落地）**：`docs/ondemand-copy.md` 的收口与按需阶段引入三个只读入口——
  `game.live_card_text`（B0 提交 `cc5e8f0`）、`game.candidate_detail`（R0 提交 `7f1c748`）、
  `game.live_card_text_set`（B2 提交 `6eca6e0`）。
  三者都**不属于 `get_view` 白名单**（§2.2），也不得经 `get_view` 参数化实现；
  本行按仓库现状维护，接口语义以 `docs/ondemand-copy.md` 为准。
- `_submit`：1864 守卫（`show_home` 或 `enemy_feedback` 有效即 return）→ 1866 `_use_self_card` 分流 →
  1873 `dispatch` → 1874 `get_view` → 1875 notice → 成功分支 1877 `expand_applied`／1879 `_save_progress`／
  1880 `_reset_interface`（仅 demo_continue）→ **1891 `render(updated)` 在 `if result.ok` 之外（失败也整树重建）**
  → 1893 demo_end → 1896-1901 四个反馈调用（`resource_feedback.enqueue`／`_animate_cards`／
  `card_music.consume`／`CombatFeedback.play`，仅成功）。不存在名为 feedback 的单函数。
- `render`：367 快照为空才 `get_view`；376 `ActionIndex.new(view.candidates)`；379-381 清三张按钮表；
  382-385 `layout.begin_frame`；386-392 主页分支 return；399-420 按 phase 分派各屏；
  421-448 商店／底部控件／身体抽屉／行动侧栏／气泡／选择器／支付遮罩／notice／`end_frame`／
  `keyboard_input.refresh_hints`／`_localize_controls`。
- `render` 调用点共 51 处：main.gd 35、keyboard_input 4、reward_screen 4、event_screen 2、
  shop_screen 2、body_sidebar 2、quick_release_bar 1、header 1。**其中 reward_screen(4)／
  event_screen(2)／shop_screen(2)／header(1) 共 9 处不在本片授权文件内**，
  它们必须继续能用（见 §5 范围问题）。
- 选择类点击（只改本地选中态，不 dispatch／get_view／save）：2026-09-17 实测 `_select_enemy` 与手牌翻面
  （`ui/card_face.gd` 的 `flip_requested` → `ui/main.gd` `_card` 内回调）为 0 次整树重建，点牌选中（`_activate_card`）1 次。
  各分支入口如下（行号以落地时仓库为准）：`_activate_card`、`_use_self_card`、`_card_target`、`_select_enemy`、
  `_player_picker`、`_hand_target_picker`、`body_sidebar._toggle`、`ui/keyboard_input.gd` 的 `select_card`／`cancel`、
  `quick_release_bar.select`。
- 提交类入口最终都进 `_submit`：`_status_control:564`、`_basic_action_tile:731`、`_posture_controls:836`、
  `_bottom_controls:1075/1088`、`_wall_controls:1118`、`_equipment_tile:1226`、`_action_row:1282/1288`、
  `_card_target:1313`、`_prison_controls:1446/1455`、`_compact_action:1532`、`_route_screen:1627`、
  `_select_route_room:1657`、`_queue_map_step:1677`、`_show_drop_targets:2066`、
  `_activate_guard_bind_target:2161`、`_receive_player_drop:2204`、`_use_free_card:2231`、
  `_activate_card:2239/2261/2270`、`_use_self_card:2277`、`_item_details:2466/2503`、`keyboard_input:106/197/282`。
- **被拒／无效 → 整树重建（当前病灶命名）**：共 7 处，全部整树 `render(view)`；
  本片收敛为 §3.5 `present_rejection` 唯一入口（人已决：打回即打回、不新增动画、不重算）。
  两层成本必须分开命名：**投影重算**（只发生在提交被拒——多付一次 `get_view()`，含按需 `card_texts` 的少量成本：
  2026-09-17 实测 0 件档约 0.7ms、占 `get_view` 约 1.3–7.9%；`core/game_view.gd` 的 `View.build` 按 `shown.has(type)` 只生成显示集合）
  与**界面整树重建**（7 处都有）。每处真正改变的本地态即"只允许刷新的脏集上界"：

  | 行 | 入口 | 触发 | 脏集上界 |
  | --- | --- | --- | --- |
  | 1660-1661 | `_select_route_room` | 点击路线上当前不可进入的房间 | 仅 `notice` |
  | 2163-2164 | `_activate_guard_bind_target` | 对 guard_bind 目标使用当前选中牌、候选存在但 invalid | 仅 `notice` |
  | 2233-2234 | `_use_free_card` | 自由放置无可用部位／候选 invalid | 仅 `notice` |
  | 2246-2247 | `_activate_card` | 自身目标牌候选存在但 invalid | 仅 `notice` |
  | 2251-2252 | `_activate_card` | 单面牌（`single_face`）不可用 | 仅 `notice` |
  | 2264-2266 | `_activate_card` | 快速解除栏与当前拘束具不匹配 | `notice` + `selected_card=uid`、`selected_candidate=""`、`show_body=false` → 另加 `hand`／`body_details` |
  | 1875／1891 | `_submit`（提交被拒） | dispatch 返回 `ok=false` | `notice`；仅当**核心回传"需要重同步"**时另加键差脏集（§7；判据不得由 UI 自行求值 `game.state`，见 §3.1 的 2026-09-17 更正） |
- 被拒时的可见反馈（现状，只记事实）：
  - 打回路径零动画：`ui/main.gd:1895-1901` 四个反馈调用整体在 `if result.ok:` 之内，
    被拒时不触发任何反馈节点、声音或补间；该路径唯一视觉信号是 `notice` 经
    `_show_term`（`ui/main.gd:1711-1731`）生成的纯静态 `PanelContainer` + label + `_position_term`，
    无 tween、无淡入、无抖动。全仓 `create_tween` 分布为 `card_motion.gd` 4、`combat_feedback.gd` 3、
    `shop_screen.gd` 2、`resource_feedback.gd` 1、`card_music.gd` 1、`card_face.gd` 1，
    拒绝路径一个都不经过。
  - 触屏点按被拒无可见反馈：`ui/main.gd:1712` 守卫
    `if is_instance_valid(touch_input) and touch_input.finger>=0 and not touch_input.details_allowed: return`；
    `ui/touch_input.gd:62` 手指按下即 `details_allowed=false` 并 `host._hide_term()`，
    `:99` 只在长按阈值后置 true。触摸事件同步派发：`touch_input.gd:131/135` 在 `release()` 内
    合成鼠标按下／抬起 → `dispatch_mouse:172` 的 `viewport.push_input(event,true)`，
    而 `finger=-1` 要到 `:136` 才复位；因此 tap 触发的 `_submit` → `render` → `_show_term`
    全程 `finger>=0`，notice 被守卫吞掉。结论：鼠标与键盘被拒至少有一行提示，
    **触屏点按被拒没有任何可见反馈**（`notice` 仍写入 `ui.notice`，但要等下一次有人在不按键时
    渲染才会显示）；该行为**无断言覆盖**：`tests/touch_ui_cases.gd` 中
    `notice`／`TermExplanation`／`_show_term` 出现 0 次，全仓除实现外只有 `ui/main.gd:965` 与
    `ui/touch_input.gd` 自身引用 `details_allowed`。已决：拒绝提示必须可见且桌面／触屏一致，
    只让拒绝/notice 走 §3.5 的独立通道，不新增动画（见 §5 第 5 条）。
- 已具备的复用范例：`game_layout.begin_frame:12` 只清临时子节点（hero/body/enemies 实例保留，:20/:32/:50，:59 end_frame）；
  `arena.gd:27/:40`、`equipment_portrait.gd:77` 的 appearance 比对；
  `body_sidebar.gd:62 _presentation_key`（注释明确：只保存显示事实，不保存旧 View／候选／装备图）、
  `configure:72`、`expand_applied:18`。
- 输入层：`touch_input.gd` 不调提交类方法，把触摸合成鼠标事件推入 viewport；`keyboard_input.gd` 无自定义信号，
  直接调 host 方法。`enemy_feedback.gd:21` 全屏 `MOUSE_FILTER_STOP` 配合 `_submit:1864` 守卫，
  播报期点击被设计性吃掉（产品决策，本片不改）。
- 只读索引：`action_index.gd` 32 行只查找不重算资格，`old_action` 在刷新后仍可被拿去做陈旧提交（测试即如此用）；
  `target_queries.gd` 94 行只接受 View 数据 + ActionIndex + 本次载荷，不持有 Game／控件。

非目标（本片不做）：
- 不改 core 规则、数值、存档语义、快照格式、随机域；`card_texts` 单次成本留在 core（见 §3.1）。
- 不动 arena 立绘重画与分帧动画；不新增每帧重绘；不重建立绘实例。
- 不改文案与本地化文本；不改输入语义与键位；不改"播报期吃点击"。
- 不新增第三方依赖；不新增常驻钩子（P0 计时脚本用完即删，见 §8）。
- 不新建 UI 流程文件或看板；不宣称帧率提升或全量回归。

## 1. 模块切分与依赖方向

| 模块 | 边界（谁） | 接口（小） | 内部（藏） |
| --- | --- | --- | --- |
| M1 输入适配 | `ui/keyboard_input.gd`、`ui/touch_input.gd` | `handle(event)->bool`；触摸只合成既有鼠标事件 | 键位表、选择状态机、长按阈值、弹窗桥 |
| M2 提交接缝 | `ui/main.gd` `commit` | `commit(c, expected_version) -> Dictionary`（§3.2） | 分流、守卫、反馈编排 |
| M3 展示调度 | `ui/main.gd` `present` + 节键表 | `present(dirty, snapshot={})`；`render(snapshot)` 兼容整树 | 各节重建函数、键比对、兜底 |
| M4 只读查询 | `ui/action_index.gd`、`ui/target_queries.gd` | `_init(actions)`／`select`／`find`／`first_usable`；static 查询 | 去重、排序、首／末拒绝原因选择 |
| M5 静态场景与实例 | `ui/shell/game_layout.gd`、`ui/shell/body_sidebar.gd` | `begin_frame`／`hero_portrait`／`enemy_group`／`body_sidebar`／`end_frame`；`configure`／`_presentation_key`／`expand_applied` | 场景节点、按外观比对、展开预算、滚动 |
| M6 提交后反馈 | `card_motion.gd`、`resource_feedback.gd`、`combat_feedback.gd`、`enemy_feedback.gd` | `positions`／`enqueue`／`play`／`consume`／`finish` | 补间、队列、播报分页与高亮 |

允许依赖方向（本片不变）：
`M1 → M2/M3`（通过 host）→ `M4/M5` →（main.gd 的 `preload`）`core.Game`／`core.SaveStore`；
`M6 ← M3` 传入的 `view`／`payload`／锚点节点。
仅 `ui/main.gd` 允许 `preload` core（现状：`Game`、`SaveStore`）。`ui/shell` 禁止 preload core。

依赖方向禁令：
- core／data 不得 preload ui；UI（含 shell）不得读 `game.state`、不得调用 `dispatch` 之外的规则写入口
  （快照入口 `restore_snapshot`／`restart_snapshot` 只允许在 `_resume_snapshot:275`、`restart:1916`、`_quick_sl:288` 使用）。
- M4 不得持有 Game、控件；M5 不得读 View 之外的规则；M6 不得 dispatch／get_view／改判定。
- 任何节键不得保存旧 View、候选、装备图或节点引用，不得用 version 当键（§4.2）。
- `ui/main.gd` 约 2700 行（2026-09-17 复核）：本片不新增文件；若 `commit`／`present` 需要独立文件，按 §5 范围问题处理，不得自行新建。

## 2. 接缝 A：既有接口的契约（固化，不改语义）

### 2.1 `game.dispatch(candidate_id, expected_version) -> Dictionary`

- 输入域：`candidate_id` 必须来自当前 View 的 `candidates`；`expected_version` 为 UI 当前 `view.version`
  （`_submit` 允许调用方给 `-1`，此时 UI 补 `view.version`）。
- 返回：`{ok:true, resource_feedback?, card_feedback?, music_feedback?, ...}` 或 `{ok:false, error:String}`。
  已核实的拒绝语义（core/game.gd:1955-1972）：
  - 版本不符 → `{"ok":false,"error":"状态已更新，请重新选择行动。"}`；
  - 候选 ID 不在新候选里 → `{"ok":false,"error":"该行动已经失效，请重新选择。"}`；
  - 候选存在但 `valid=false` → `{"ok":false,"error":chosen.reason}`；
  - 五个 `validate`（Consumables/binding/special/cards/relic）失败 → 对应 `error`。
- 副作用：只有 `ok=true` 才写状态；`state=state.duplicate(true)`（:1987）后执行，失败回滚，不留部分付款／部分装备。
- 谁能调：只有 M2 `commit`。测试可直调（既有做法），UI 其它文件禁止。
- 信任依据：`core/game.gd:1955-1987` + `tests/test_game.gd` `_core_cases` 的 TC-CORE-0002/0003（ forge 候选与陈旧版本原子拒绝）。
- UI 义务：不自行判定资格、不改牌面、不按名称／颜色／译文识别对象；失败按 §7 的条件式处理
  （仅展示版本落后时才重同步）、不重试、不改派其它候选。

### 2.2 `game.get_view() -> Dictionary`

- 纯只读投影（`core/game.gd:2805` → `core/game_view.gd:175 build`）。内部含
  `g.candidates()`（:176）、每个 action 的 `ReleaseView.preview`（:179）、
  全量注册牌型 `card_texts` 循环（:301-305，约 83 型，无条件）以及 room_event／shop／relics／prison 四个 view（:320-323，无条件）。
  **（预告 2026-09-15）**"无条件全量"是当前事实、不是长期不变量：`card_texts` 的收窄由
  `docs/ondemand-copy.md` §1.2（界面固有显示集合 S）持有授权，落地前不改本行。
  **（2026-09-17 被按需化取代：实测每次 2–4 型，占 `get_view` 约 1.3–7.9%；见 docs/ondemand-copy.md 与 docs/verification.md 2026-09-17 卡顿定位条目）**
- 成本事实：单次成本与装备件数相关（候选生成中位 6.4/41.3/146.8ms @0/12/29 件，docs/equipment-performance.md:49-51），
  空装备时仍有固定投影成本（显示生成 20.869ms，docs/equipment-performance.md:69）。
- **UI 侧只能减少 get_view 的调用次数，不能降低单次成本。** 单次成本在 `core/game_view.gd`，
  属本片授权范围外：记为"越界待批"接缝；UI 可在自己的投影上做增量刷新，但不得把投影结果当成规则判定来源（见 §4.1）；
  该越界项已由 `docs/ondemand-copy.md` 承接（见 §6.1）。
- 允许的调用点（唯一集合，任何新增即契约违例）：
  `ui/main.gd:278`（`_resume_snapshot`）、`:367`（`render` 空快照）、`:1874`（`commit` 成功必取；被拒且展示版本落后时取）、
  `:1919`（`restart`）。
- **新入口不属于本白名单**：`game.live_card_text`／`game.live_card_text_set`／`game.candidate_detail`
  （见 §0"按需入口"与 `docs/ondemand-copy.md`）是三个**独立的只读入口**，不改变本白名单，也不得经
  `get_view` 参数化实现；本白名单只约束 `get_view` 的调用点。
- 版本语义：`view.version == game.state.version`；`restore_snapshot` 把 version 抬到 `max(prev, saved)+1`
  （core/game.gd:2826），因此"版本回退"只可能来自 UI 自己传入的独立快照（display 测试就这么用），
  键不得依赖单调 version。

### 2.3 快照与显示格式化

- `restore_snapshot(saved) -> {ok,error}`／`restart_snapshot() -> Dictionary`：UI 只判断 `ok`，
  不解析快照结构、不迁移字段。
- `game.number(n) -> String`、`game.Prison.*` 常量：允许的只读显示调用，不参与判定。

### 2.4 `ActionIndex`（消费方契约）

- `_init(actions)` 只建立 `by_id`／`by_group`；不重算资格、不缓存旧索引。
- `select(group, fields)` 按 payload 相等筛选；`find` 取首个匹配（无匹配返回 `{}`）；
  `first_usable` 取首个可用，全不可用返回**末项**。
- 与 `TargetQueries.first_usable`（全不可用返回**首项**）语义不同：不得按名字相近合并。
- 构造点唯一：View 更新时（`render:376`）。本片新增规则：`view` 与 `actions` 原子同步更新（§3.3）。
- 消费方可以信任：登记在 `by_id` 的候选就是该 View 的候选；它不保证提交成功——那由 `dispatch` 复核。
  陈旧 `ActionIndex` 只允许用于"按旧版本提交并得到拒绝"的测试路径。

### 2.5 `TargetQueries`（消费方契约）

- static、无状态；输入只有 View 数据、ActionIndex、本次载荷；不接收 Game／控件，不写状态。
- 返回原候选（不复制、不改写）；`RELEASE_MODES` 是唯一模式定义处。
- 自动唯一目标、手牌去重、首／末不可用原因各保留原语义（见 docs/release-interface.md 目标查询共享边界）。

### 2.6 shell、输入与反馈接口的消费方契约

| 接口 | 输入／返回 | 谁能调 | 后一个 agent 凭什么信任 |
| --- | --- | --- | --- |
| `game_layout.begin_frame(home: bool)` | 只清临时子节点，保留 `MoonlitGallery`／`hero`／`body`／`enemies`；重置 `used` | 只有 M3 的节／页函数 | 调用后保留实例仍有效；`end_frame` 释放本次未标 used 的 body／敌人（game_layout.gd:12-18） |
| `hero_portrait(view, fixed, rect) -> Control` | 传入 View（不是 state）；创建或就地更新 hero 实例并定位 | 战斗／阶段页节函数 | 返回活实例；只更新外观，不改规则；`EquipmentPortrait.uses_fixed_portrait` 只读 `character_id` 与固定立绘偏好（docs/ui-scene-refresh.md） |
| `enemy_group(enemy, settings) -> Control` | `enemy` 为 View 的敌人条目；按稳定 `id` 复用分组，清子节点后重配 | 战斗页节函数 | 同一 id 的实例身份保持；离场敌人由 `end_frame` 删除，调用方无需手动释放 |
| `body_sidebar(ui) -> void` | 实例化／重排身体栏并调用 `configure(ui)` | 显示身体栏的页节函数 | 再次调用复用同一实例；不在需要的页面由 `end_frame` 释放（ui-scene-refresh.md 身体栏语义） |
| `body_sidebar.configure(ui)` | 读 `ui.view`、`ui.selected_slot`、`ui.expanded_body_regions`、`ui.show_body`、locale、高度 | M3 身体栏节 | 返回后 `ui.body_buttons` 对当前 View 有效（含非激活区域别名→header 的映射）；键命中时按钮与滚动保留（body_sidebar.gd:84-86） |
| `body_sidebar._presentation_key(ui) -> Array` | 纯显示字段键（高度、locale、选中部位、展开顺序、各区域 members 显示字段） | 加固门禁与节键比对 | 注释即合同："只渲染事实；绝不保存旧 View／候选／装备图"（body_sidebar.gd:62-70）；新增显示字段必须同批进键（H1） |
| `body_sidebar.expand_applied(ui, before, after)` | 两个 View；比较 `body_regions.targets` 的物理 ID 新增 | 只在 `commit` 的 ok 分支且 phase 命中时 | 同件加固／降档不展开；非战斗与失败不展开；不选装备不派发（docs/release-interface.md） |
| `keyboard_input.handle(event) -> bool` | 返回是否已处理；内部可能调 `host._submit`／`host._activate_card` | `main._input` 与 PopupMenu 桥 | 本片冻结 host 成员名与语义（`view`／`actions`／`card_buttons`／`card_faces`／`attack_forms`／`_submit`／`_activate_card`／`render`／`_show_term`／`_hide_term`／`_panel`／`_label`／`_button`／`_open_drawer`／`_close_drawers`／`DRAWERS`／`modal_region`／`quick_release_*`）；android 直接返回 false；不新增 dispatch |
| `keyboard_input.refresh_hints()` | 幂等重建按钮角标 | `present` 末尾（call_deferred） | 只读 view 与 settings；无游戏副作用 |
| `touch_input` | 把触摸合成鼠标事件推入 viewport（含 PopupMenu 独立视口桥） | 引擎输入；`_ready` 由 main 挂载 | 不直接调提交／规则；长按阈值、取消路径不提交；`ui` 侧不得假设存在触摸专用入口 |
| `card_motion.positions(ui) -> Dictionary` | 抓取当前手牌按钮位置／角度／牌面 | `commit` 在 dispatch 前 | 只读；不改状态；不推进随机 |
| `card_motion.enqueue(events, before)` | core 的 `card_feedback` 事件 + 提交前快照 | `commit` ok 分支，且 `present` 之后 | 幽灵卡不持有牌、不挡输入；`pending_draws` 隐藏新抽牌按钮的规则必须被 `present` 的手牌节尊重（main.gd:1013） |
| `resource_feedback.enqueue(events, point, instant_fields)` | core 的 `resource_feedback` 事件 + 锚点 | `commit` ok 分支 | 只消费已提交差值；`update_numbers` 只做显示；`show_home` 时自毁 |
| `combat_feedback.play(ui, before, payload)` | 提交前 View + 已提交 payload | `commit` ok 分支 | 只用可见前后差分（HP／日志／装备耐久）；不预测、不改伤害／意图／资源／时机 |
| `enemy_feedback.finish()` | 清 `ui.enemy_feedback` 并释放 | `_return_home`、`_reset_interface`、播报结束 | 节点存在即"播报期"：`_submit` 守卫与 `blocked()` 都据此吃输入（产品决策，本片不改）；全屏 `MOUSE_FILTER_STOP` 不得被 `present` 提前回收 |

## 3. 接缝 B：新接缝契约草案

### 3.1 提交路径的现状分解与目标条件（草案）

本块现状与目标混排：`dispatch` 后无条件 `game.get_view()`、`render(updated)` 整树重建、成功反馈四调用是 HEAD 现状；
"仅当展示版本落后才重同步"与 `present(...)` 局部刷新是**目标条件**，尚未落地（2026-09-17 复核）。

```
_submit(c, expected_version=-1)
  guard: show_home 或 enemy_feedback 有效 -> 直接 return（不 dispatch／不 get_view／不 save）
  分流:  有效卡牌且 hand_uid 且非 self_target 且未在选择手牌 -> _use_self_card
  previous = view;  previous_cards = card_motion.positions(self)   # 必须在 dispatch 前抓
  result = game.dispatch(c.id, view.version if expected_version<0 else expected_version)
  # 成功必取新投影（现状）；被拒时是否需要重同步由核心回传（目标条件，例如结果里带 `resync` 标志）
  # （2026-09-17 更正：旧写法 `view.version != game.state.version` 会让 UI 求值 `game.state.version`，
  #  违反 §1 依赖方向禁令；实测 ui/ 0 处读 `game.state`，该写法不得按字面实现）
  updated = game.get_view() if result.ok or result.get("resync", false) else view
  notice = "" if result.ok else result.error
  成功: expand_applied(previous, updated) / _save_progress() / _reset_interface(仅 demo_continue)
        清选择态 / phase 变则 _close_drawers / pack 开道具 / overloaded 关抽屉
  present(...)                                                     # 现状是整树 render(updated)
  成功且 demo_end: _return_home(); return
  成功: resource_feedback.enqueue / _animate_cards / card_music.consume / CombatFeedback.play
```

### 3.2 `commit(c: Dictionary, expected_version: int = -1) -> Dictionary`

- 入口：`ui/main.gd`，M2 内唯一 `dispatch` 点（取代 `_submit` 的规则部分；`_submit` 可保留为薄别名）。
- 输入：`c` 为当前 View 候选字典（不要求同一引用）；`expected_version < 0` 时取 `view.version`。
- 返回：`{"ok":bool, "error":String, "view":Dictionary, "dirty":Array[String], "blocked":bool}`。
  - `view` 为本次的当前 View：版本不等时是本次 `get_view()` 的结果，相等时是调用前的 `ui.view`。
    语义是"提交后 UI 应当展示的 View"，不是"每次都必须重新投影"；`view` 被替换时，
    `ui.actions` 必须与它同一批原子替换。
  - `dirty` 由节键比对产生，只在本次调用内计算；元素来自 §4.2 节枚举。
  - `blocked=true`：`show_home` 或 `enemy_feedback` 有效，未 dispatch、未 get_view、`dirty=[]`，`view` 为当前 view。
- 拒绝语义：dispatch 拒绝 → `ok=false`、`dirty>=["notice"]`；不得自动重试或改派候选。
- 缓存：UI 可以跨操作持有投影（`view`／`actions`）与自己的显示态；作废集合由核心给出，UI 不得自行推断资格或作废范围。
- 成功附加行为顺序（契约，不得调换）：抓 `positions` → dispatch → get_view → 设 notice →
  `expand_applied` → `_save_progress`（仅 ok）→ 选择态清理／抽屉调整 → `present` → 反馈四调用。
  失败路径：dispatch → 仅当**核心回传需要重同步**时 `get_view` 并原子替换 `view`/`actions`（判据不得由 UI 自行求值 `game.state`，见 §3.1 的 2026-09-17 更正）
  → 设 notice → `present(["notice", …键差])`（版本相等时只 `present(["notice"])`）；不 save、不反馈。
- 谁能调：main.gd 内的候选按钮、拖放接收器、`keyboard_input`／`touch_input` 到达的同一入口。
  `reward_screen`／`event_screen`／`shop_screen`／`header` 不在授权内，继续用 `render(view)` 兜底（§5）。

### 3.3 `present(dirty: Array[String] = ["*"], snapshot: Dictionary = {}) -> void`

- 语义：只重建 `dirty` 列出的节；`["*"]`、缺项、未知节名 → 全量兜底重建。
- `view`／`actions`：若 `snapshot` 非空则原子替换 View+ActionIndex；为空则用当前 `ui.view`。
  **禁止 `present` 在非空 snapshot 下再调 `get_view`**；`render(snapshot)` 兼容入口保留
  "空 snapshot 才 get_view"的现状（:367）。
- 每次 `present` 的固定动作：`DragTargets.clear` → `_hide_term` → View/ActionIndex 同步 →
  节键比对 → 重建脏节 → `layout.end_frame()` → `keyboard_input.refresh_hints.call_deferred()` → `_localize_controls`。
- 必须保留：普通刷新不销毁 hero／身体栏／敌人实例；抽屉打开或 phase 变化的兜底路径照旧重建整页。
- 兜底条件（任一成立即整树，且必须显式判据，不得靠"没键就重画"隐式实现）：
  `phase` 变化 · `show_home` 进入／离开 · `show_route` 切换 · locale 变化 ·
  显示设置变化（`fixed_hero_portrait`、`art_changed`、字号类）· `layout` 未实例化 ·
  View 为空 · 传入 snapshot 的 `version` 小于当前 `view.version`（版本回退）· 节键缺失或未知 ·
  `reward_panel.active` 或 `demo_end` 或 `pressure.overloaded` 或 `view.card_chain` 非空或
  首次战斗教程触发（这些会改页面结构，见 §7 假设 2）。

### 3.4 节键表（draft；节名同时是 `dirty` 元素）

键只用"当次 View 投影 + 本地 UI 态"，纯数据（Array/Dictionary/基础类型），**`version` 不进键**。
现状列说明改动点。

| 节 | 重建函数（现状） | 键内容 | 现状 |
| --- | --- | --- | --- |
| `header` | `_header`→`header.configure` | `run_header`(location/turn/order/last)、`security`、`wall`、`wall_position.distance`、`pressure.overloaded`、`carried_items`、`capacity`、`deck_count`、`prison.active`、`phase`、`practice`、`show_route`、`save_failed`、locale | 每次新建 + configure |
| `relics` | `_relic_row` | `relics`(id/name/detail/counter/current/rarity)、locale | 每次新建 |
| `hand` | `_hand` | `hand`(uid/type/draw_serial/draw_free/single_face/availability/face_*）、`card_texts` 对应项、`card_instances`、`card_faces[uid]`、`selected_card`、`_selecting_hand()`、`card_motion.pending_draws` | 每张牌每次新建按钮 |
| `actions` | `_fixed_actions`／`_build_action_rail` | `phase`、`selected_enemy`、`attack_forms`、`quick_release_open`、候选子集(attack/pressure/flow/surrender)的 id/valid/reason/cost/label/body_part/casting/brief/risk | 每次新建 |
| `posture` | `_posture_controls`／`_wall_controls` | `posture`、候选子集(posture/wall_move) 的 id/valid/reason/cost/distance/adjacent/wall、`guard_bind.is_empty` | 每次新建 |
| `resources` | `_bottom_controls` | `energy`、`mana`、`temporary_mana`、`mana_max`、`pressure`、`guard_bind`、`powers.size`、`draw_count`、`discard_count`、`phase`、`surrender_version` | 每次新建 |
| `log_sidebar` | `_action_sidebar` | `action_log`、`phase`、`action_log_open/pinned` | 每次新建 |
| `body_bar` | `body_sidebar.configure` | 既有 `_presentation_key`：`size.y`、locale、选中部位、展开顺序、每区域 members 显示字段 | 已有键；命中时保留按钮与滚动 |
| `body_details` | `_body_details`／`_equipment_tile`／`_action_row`／`_card_target` | `selected_slot`、`selected_card`、`selected_candidate`、`show_body`、`pending_retain`、`quick_release_open`、`guard_bind.is_empty`、`card_faces`、相关候选子集 id/valid/reason/cost/preview | 每次新建（同时清理 `candidate_buttons` 旧项） |
| `pickers` | `_player_picker`／`_hand_target_picker` | `player_pick`、`player_pick_data`、`hand` 相关项、候选子集(card/hand_uid) | 每次新建局部面板 |
| `speech` | `_speech_bubble`／`_npc_speech_bubble` | `speech`／`npc_speech`(id/text/phase/cue)、locale、本地 `speech_id/deadline` | 每次新建 |
| `notice` | `_show_term(actor_targets.hero, …)` | `notice`、`actor_targets.has("hero")` | 依赖 hero 接收区存在 |
| `drawers` | `_refresh_drawers` + 各构建器 | `DRAWERS` 标志、`deck_zone`、`status_filter`、`selected_item`、`show_shop_service` 等本地态 + 各自投影、locale | 每次重建整层 |
| `page` | `_route_screen`／`_rewards`／`_service_screen`／`_event_screen`／`_prison_controls`／`_capture_screen`／`_inspection_screen`／`_practice_screen`／`_demo_exit_screen`／`_battle_scene` | `phase` 及其实际读取字段；结构变化一律走 §3.3 兜底 | 每次新建；兜底集合 |
| `scene_instances` | `layout.hero_portrait`／`enemy_group`／`body_sidebar` | 外观字段由 arena／equipment_portrait／body_sidebar 自身比对 | 已保留实例 |

节键计算的成本也要进 P0 计时（§8），不得默认"算键几乎免费"。

`notice` 节的调用方是 §0 表中 7 处拒绝分支（6 处选择类 + 提交被拒）；每处只允许按该表列出的
脏集上界刷新，禁止整树 `render(view)`。各行读到的 View 原因取自当次投影，不得改写或另造文案。
`notice` 的显示受 `ui/main.gd:1712` 触屏守卫影响（见 §0"被拒时的可见反馈"）；已决：拒绝/notice
走 §3.5 的独立呈现通道，不再受该守卫限制，桌面与触屏一致，且不新增动画（§5 第 5 条）。

### 3.5 `present_rejection(reason, source, dirty)`（拒绝路径唯一入口）

人已决（2026-09-15）：**打回即打回，不新增动画；最多留一个触发器；不要重算。**
7 处拒绝分支全部经由本入口，不得各自实现：
§0 表 6 处选择类（`_select_route_room:1660`／`_activate_guard_bind_target:2163`／
`_use_free_card:2233`／`_activate_card:2246`／`:2251`／`:2264`）+ 提交被拒（`_submit:1875`）。

- 载荷（至少三项）：`reason`（当次从候选／View 读出的原文，不得另造文案）、
  `source`（输入来源：`mouse`／`keyboard`／`touch`）、`dirty`（该次脏集上界，按 §0 表）。
- 入口内**不得**：`dispatch`／`get_view`／`_save_progress`；超出 §0 表脏集的重建；每帧调用。
- 本片**不实现任何反馈消费者**；未来若要加反馈只准挂在此处。
- 不新增 Godot `signal`，不建空节点或空函数占位（无消费者的推测性管道不建）；入口本身就是触发点。
- 触屏可见：入口负责让拒绝可见，且只让拒绝/notice 走一条不受 `ui/main.gd:1712` 守卫限制的通道
  （例如入口自己呈现，或给一次性的允许标记）。硬边界：`_show_term` 共 18 处调用
  （`main.gd:445/529/531/557/558/628/629/741/742/975/2087/2135`、`keyboard_input.gd:135/171`、
  `event_screen.gd:94/95`、`reward_screen.gd:89`、`touch_input.gd:115`；另 `main.gd:1711` 为定义），
  绝大多数是悬浮／焦点／长按详情提示，**这些既有抑制规则不得改动**，只允许为拒绝/notice 另开通道。

## 4. 缓存、失效与只读边界

### 4.1 允许与禁止

允许（只读显示口径，现状保留）：
- core 只读调用内的装备显示行复用、`face_texts` 合批（docs/equipment-performance.md）；
- `body_sidebar._slots_key`／`_button_index`（显示字段键 + 稳定部位 ID → 按钮索引）；
- `card_faces`／`card_draw_serials`（本地翻面／抽牌显示态）、`map_drawings`（界面备注，随本局保存）；
- 节键：当次 View 投影 + 本地 UI 态的纯数据副本。

禁止：
- 用 `version` 当键或当缓存版本号（version 不单调，`restore_snapshot` 后可回退，进键会误命中，见 §2.2／§7）；
  用译文、颜色、名称、图片识别玩法对象。

（2026-09-17 修订）删除原"禁止跨提交缓存规则结果／禁止保存旧 View、候选、节点引用当键／禁止把投影结果缓存到 UI"三条。新的准入线是"复用必须附可证失效规则；无证明即禁止"；核心与 UI 的分工见 §3.2 与 docs/candidate-delta.md §6。删除理由：该一刀切禁令被读成"UI 不得跨操作持有数据"，与仓库现状不符（ui.view／ui.actions 本就跨提交持有），并成为"每次变化整树重建"的来源之一。

### 4.2 失效键

键内容变化即失效；键必须覆盖该节渲染实际读取的 View 字段（加固门禁 H1，§9）。
本地 UI 态同样进键：选中部位／敌人／手牌、展开顺序、抽屉开合、语言、面板高度、`card_faces`。
`version`、节点实例 id、鼠标位置、时间不得进键。

## 5. 范围问题（需协调者转人，规划者不自行认定）

1. `render` 的 9 处外部调用方在授权文件外：`ui/reward_screen.gd`(4)、`ui/event_screen.gd`(2)、
   `ui/shop_screen.gd`(2)、`ui/shell/header.gd`(1)。契约默认它们继续调 `render(view)`（整树兜底），
   不改这些文件；若本片要收窄它们的刷新，需授权扩展范围。
2. 测试文件：Gherkin 要落在既有 `tests/*_cases.gd` 与 `tests/architecture_cases.gd`（改动既有文件），
   授权清单只列了 ui/；需要把"tests 既有用例文件追加具名 check"纳入范围。
3. **已完成（2026-09-15）**：`spire-godot/AGENTS.md` 文档入口表已加入三行索引——响应管线、装备查询、
   文案收口与按需（`docs/response-pipeline.md`、`docs/equipment-query-seam.md`、`docs/ondemand-copy.md`）；
   该文件现 126 行／7896 字节（上限 500 行／10000 字节，指引门禁通过）。保留本行供追溯，**不再是待办**。
   （2026-09-16 注：`spire-godot/AGENTS.md` 已在 `ee9c54c` 合并进仓库根 `AGENTS.md`，该路径不再存在；
   本条为历史记录，勿按原路径查文件。）
4. 若节键／commit 需要独立文件（如 `ui/section_keys.gd`），不得自行新建；先向协调者提案。
5. **触屏被拒的反馈策略（人已决，不再是待转问题；保留在此供追溯）**：
   拒绝提示必须可见，桌面与触屏一致；只让拒绝/notice 走 §3.5 的不受 `_show_term:1712` 守卫限制的
   通道，且**不新增动画**（抖动／闪红／音效等新可见行为不在本片）。其中"为打回新增动画"仍**未选定，
   本片不得实现**；若将来选择，约束为：挂在不会被重建的节点上、不得每帧重绘、
   鼠标／键盘／触屏三路语义一致、播放期间不得吃掉有效点击。

## 6. 接缝 A 的待批事实：card_texts 与候选计时

### 6.1 `card_texts`（越界待批）

- 每次 `get_view` 无条件为全部注册牌型（约 83）生成双面文本与 metadata（`core/game_view.gd:301-305`）——
  **（2026-09-17 被按需化取代：实测每次 2–4 型；见 docs/ondemand-copy.md 与 docs/verification.md 2026-09-17 卡顿定位条目）**，
  空装备亦 ≈18-21ms（docs/equipment-performance.md:69 的 20.869ms）；该值属显示生成整段，非 card_texts 单项（2026-09-17 更正）。
- 本片授权不含 `core/`：**UI 侧只能减少 get_view 调用次数**，不得降低其单次成本，
  不得改变投影内容本身（graph、奖励、牌堆浏览共用该投影）；在本投影之上做增量刷新不算绕过。
- core 侧接缝（把 `card_texts` 改成按需／增量）记为越界待批，需人明确授权后才能进 core。
  **（2026-09-15 更新）**该待批项已由独立契约承接：`docs/ondemand-copy.md`（先收口文案路由、后按需投影）。
  本片与 UI 不得改变投影内容本身（graph、奖励、牌堆浏览共用该投影）；在本投影之上做增量刷新不算绕过；按需化只在那一契约的分批与授权下进行。

### 6.2 候选计时矛盾（P0 必须取证）

- 事实：`core/game_view.gd` 的 `View.build` 在 `get_view` 内部调用 `g.candidates()`，因此"完整 View 耗时"已含候选生成；
  交接单称"candidates 仅 0.07-0.11ms"与 docs/equipment-performance.md:49-51 的中位
  6.955/49.620/167.816ms（旧）与 6.388/41.292/146.757ms（新）@0/12/29 件矛盾。
  **（2026-09-17 已解释清楚：该数字是每行均值，不是一次调用总成本）**0 件档 `dispatch` 内候选生成
  8.4ms ÷ 86 行 ≈ 0.098ms/行（P0 数据 `build/stutter-trace-20260917/round-b.json`）；**不得用于收益预期**。
- 契约要求：
  1. P0 必须在**真实调用点**分段取证（`commit` 内 dispatch、`get_view` 内、`render` 内，见 §8），
     每个数字必须带函数名 + 状态（件数）+ 仪器；
  2. 0.07-0.11ms 的口径已解释清楚（每行均值而非一次调用总成本，见上）；本片基线以 P0 数据为准；
  3. 该数字不得用于本片的收益预期或完成判据。

## 7. 失败路径契约（保留断言，不许弱化）

- 锁定断言（不得删、不得放松）：`tests/ui_smoke.gd` `_index_boundary_tests`（陈旧提交四条；行号以落地时仓库为准）——
  失败提交后状态不变且 notice 非空；
  `ui.view.version==ui.game.state.version and ui.view.energy==ui.game.state.energy`（显示快照被刷新）；
  旧版本拖放被拒；
  `ui.actions` 已按新状态重建（陈旧提交后动作索引替换）。
- 重算分界（人已决："不要重算"）：
  - 同版本被拒 → **零重算**：不 `get_view`、不替换 `ui.actions`、不落盘、不反馈，只刷新 `notice` 节。
  - 版本落后被拒 → **必须重同步**：执行 `get_view` + `view`/`actions` 同一批原子替换
    + 按节键比对刷新脏集（可能近乎整页）。理由（后来者不必重新论证）：
    ① 不同步会让界面停在一个不可能的状态——它显示的状态已被取代；
    ② 之后每一次点击都会以同样理由被继续拒绝，因为候选全部携带旧版本；
    ③ 该行为被 `tests/ui_smoke.gd` `_index_boundary_tests` 的四条（显示快照被刷新／旧版本拖放被拒／
    actions 已按新状态重建；行号以落地时仓库为准）锁定，删弱即失败。
  - 判据可靠的原因：version 只在成功提交时自增一次（core/game.gd:2039-2045 校验失败 `state=original`
    且不碰 version；另一处自增是 core/game.gd:2826 的 `restore_snapshot`），所以
    `view.version==state.version` 等于"展示的 View 就是当前已提交状态"，此时没有需要重算的内容。
- 两种情形共同要求：拒绝经 §3.5 唯一入口呈现、notice 非空、不保存、不反馈、不改派候选、不自动重试；
  present 用节键比对决定重建集合（版本不等 → 脏集；相等 → 只有 `notice` 节）。
- 禁止：版本不等时跳过重同步或跳过 `actions` 替换、任一情形吞掉 notice、自动重试、或删掉上述断言。
- 成功路径不得因此改动：`_save_progress` 仍只在 ok；`expand_applied` 的 phase 条件不变；
  `_reset_interface` 仍只 demo_continue；反馈四调用仍在 present 之后、只在 ok。

## 8. P0 测量契约（先测，不改 core，不成门禁）

目的：为后续"减少调用次数／局部刷新"提供**真实调用点**的成本分布；不是通过判据，不提速宣称。

分段计时点（标签必须逐段打印，归因到函数）：
- `commit`：guard 判定／`dispatch` 内五个 validate（Consumables.validate_buffs、Binding.state_issue、
  版本判定、SpecialEquipment.validate、Cards.validate、RelicEffects.validate）／`dispatch` 内 `candidates()`／
  `state.duplicate(true)` 深拷贝／`_execute`+清理／dispatch 总计；
- `get_view`：`_begin_equipment_read`／`g.candidates()`／每 action 的 `ReleaseView.preview`／
  `card_texts` 循环／`hand` 循环／`bodies` 投影／route／reward／prison／总计；
- `save`（`core/save_store.gd:133 write_game`）：`game.validate()`／读旧档／`restart_snapshot()` 深拷贝／
  JSON／大小检查／写临时文件／回读校验／备份 copy+rename／总计；
- `present`／`render` 各节：`begin_frame`／`header+relics`／`hand`／`actions+rail`／`log_sidebar`／
  `resources`／`posture`／`body_bar.configure`／`body_details`／`drawers`／`localize`／`refresh_hints`／
  `end_frame`／**每节键计算**／总计。

样本轴：装备 **0／12／26 件**（用相同种子与正式安装工厂构造，记录实际物理件数）×
路径两条：（a）选择类点击——翻面、选敌、开身体详情；（b）提交类点击——打出一张牌、结束回合、一次失败提交。
26 件为本片指定样例；若需要与 docs/equipment-performance.md 的 0/12/29 对照，另加 29 件列并**分开报告**。

方法（沿用 docs/equipment-performance.md:45）：同一夹具下交替执行、2 次热身 + 15 次有效配对、
报逐对比值中位与两侧独立中位（不得互相代替）；同机同窗口状态；不拼接头尾数字。

口径：headless 与原生窗口数字不得拼接；本批与历史批次数字不得拼接；
先记录现状基线，新旧实现配对比值留到实现片（P1）用同一协议复测。

产物与清理：计时脚本与 JSON 只放已忽略的 `build/<topic>-<date>/`，不入库、不进运行时；
摘要（含机器、件数、函数名、中位数、样本数）登记到 docs/verification.md 后**删除原始目录**；
生产源码不得留计数器、开关或计时钩子；P0 不修改 core。

通过判据（P0 自身）：每段 ≥15 次有效样本、热身不计入、无脚本／引擎错误、
每数字带函数名+状态+仪器、删除前重跑一次得到同量级结果。

## 9. Gherkin（场景名 → 既有分类的具名 check）

不新建流程文件、不新建看板；用具名函数加入既有 case 文件，复用现有夹具与真实输入助手。
以下 Given/When/Then 即实现与门禁的验收合同；未落地即未完成。
计数只用测试侧包装（`tests/architecture_cases.gd` 的 `PreviewCountingGame` 模式：fixture 子类、
或替换 `ui.saves` 为计数 `SaveStore` 子类）；生产源码不得带计数器。

1. `selection_click_is_readonly`（`tests/target_sidebar_ui_cases.gd`，UI 分类 `targeting`）
   - Given 战斗夹具（0 件与 12 件两档）、`ui.game` 换成仅计数的 fixture 子类（既有模式：`tests/architecture_cases.gd` 的 `PreviewCountingGame`）；
   - When 真实点击：翻面一张手牌、点选敌人、点开身体部位与装备详情、收起详情；
   - Then `dispatch` 计数 0、`get_view` 计数不变、存档写入计数 0（计数 `ui.saves` 包装）、
     `game.export_snapshot()` 与 `view.version` 不变、`ui.actions` 未被替换。

2. `failed_submit_resyncs_and_presents_notice`（`tests/display_ui_cases.gd`，UI 分类 `display`）
   - Given 按 `_index_boundary_tests` 的做法先由外部推进一回合让展示候选陈旧；
   - When 用旧候选与旧版本提交一次；
   - Then 状态与提交前相同、notice 非空、`ui.view.version==ui.game.state.version`、`ui.view.energy==state.energy`、
     `ui.actions` 已替换（旧版本拖放被拒）、未写存档（计数 `ui.saves` 包装）、`enemy_feedback==null`（未触发反馈）；
   - 反例：同版本失效候选提交（展示版本与已提交状态相等）→ 只刷新 `notice` 节
     （记录被重建的节名，断言无其它节重建），且未调 `get_view`、未替换 `ui.actions`。
   - 原 `tests/ui_smoke.gd` `_index_boundary_tests`（陈旧提交四条）断言保持原样。

3. `section_key_hit_skips_rebuild`（`tests/display_ui_cases.gd`，`display`）
   - Given 稳定战斗 View + 记录各节根节点实例 id（手牌按钮、敌人按钮、动作栏、底栏、身体栏、详情面板）；
   - When 重复 `present(["notice"])` 与一次仅改本地选中态的 `present(["hand"])`；
   - Then 键命中节实例 id／位置／滚动不变、重建计数 0；改一个键内字段后该节实例被替换且内容与 View 一致。

4. `phase_change_full_rebuild_fallback`（`tests/interface_ui_cases.gd`，UI 分类 `interface`）
   - Given 战斗界面；
   - When 真实点击结束回合进入 reward/prepare、再进入 map/travel；
   - Then 全量兜底触发（页面容器实例替换、旧页面候选按钮不残留）、View/ActionIndex 一致、
     hero/敌人实例不重复、身体栏按原语义释放；
   - 反例：同一 phase 内的普通刷新不走全量。

5. `hand_node_identity_preserved`（`tests/body_layout_ui_cases.gd`，UI 分类 `body_layout`）
   - Given 记录 5 张手牌按钮实例 id 与位置；
   - When 选择类点击（选敌、开身体栏、翻面）与键命中的 `present`；
   - Then 同一 uid 的手牌按钮实例 id 与位置不变、卡面文本与 availability 与 View 一致、
     身体栏滚动位置保留；键变化（打出／抽牌事件）时按既有语义替换。

6. `key_table_covers_read_fields`（`tests/architecture_cases.gd`，规则分类 `architecture`）
   - Given 读取 `ui/main.gd` 源文本；
   - When 提取每个 `_section_<name>` 函数体中的 `view.<field>` 与对应 `_section_key_<name>` 中的字段标记；
   - Then 重建体读到的字段是键字段的子集；缺失即失败并打印节名与字段名。

7. `fallback_triggers_full_present`（`tests/interface_ui_cases.gd`，`interface`）
   - Given §3.3 兜底条件清单逐项构造（每项一次触发 + 一次不触发反例）；
   - Then 每项触发走全量路径且无陈旧节节点；反例不走全量。

8. `rejection_branches_present_dirty_only`（`tests/display_ui_cases.gd`，UI 分类 `display`）
   - Given §0 表 6 处选择类拒绝分支各自的可构造夹具（不可进入的路线房间、guard_bind 候选 invalid、
     自由放置无可用部位、自身目标牌 invalid、单面牌不可用、快捷栏牌与当前拘束具不匹配），
     并用测试侧包装记录被重建的节名与 `get_view`／`dispatch`／存档写入计数；
   - When 逐一点击各自入口的真实 UI 按钮（`pressed.emit()` 等既有入口，等价于人的点击）；
   - Then 每处只重建该表列出的脏集节（其余节根节点实例 id 与滚动不变）、未调 `get_view`、
     `ui.view`／`ui.actions` 未被替换、无存档写入、无整树重建，且 notice 文本等于该分支
     当次从候选／View 读出的原因（`c.reason`／`card.bound`／快捷栏 message），未被改写；
   - 且 7 处全部经由 §3.5 同一入口：测试侧计数包装断言入口调用次数与分支一一对应（无遗漏、无重复实现）。

9. `touch_rejection_notice_visible`（`tests/touch_ui_cases.gd`，UI 分类 `touch`）
   - Given 触屏夹具（`InputEventScreenTouch` 合成路径，`finger>=0` 期间派发）；
   - When 真实点按一个当前不可用／被拒的目标；
   - Then 拒绝提示可见（`TermExplanation` 存在且文本等于该分支原因）、未调 `get_view`、
     状态与存档零变化、`ui.actions` 未替换；
   - 反例：长按详情与悬浮说明的既有抑制规则不变（长按仍出详情；普通 tap 不出悬浮说明）。

## 10. 验收程序（validator 用；agent 可运行）

宿主入口：`tests/ui_smoke.gd` + `tools/check.ps1`。操作必须是真实 viewport 输入
（`move_mouse`／`mouse_button`／`flip`／`start_drag`／`release_target` 等既有助手），
触摸用 `tests/touch_ui_cases.gd`。不默认截图；测试存档隔离（`ui.persistence_enabled=false`）。

步骤：
1. 范围预检（不算通过）：
   `& tools/check.ps1 -Suite architecture -UI -UISuite display,body_layout,targeting,keyboard,touch,interface -ListOnly`
   → 输出 `PLAN ONLY:` 且列出上述分类；缺一即范围问题。
2. 规则+窗口：
   `& tools/check.ps1 -Suite architecture -UI -UISuite display,body_layout,targeting,keyboard,touch,interface -TimeoutSeconds 900`
   → 退出码 0；输出含 `RULE SCOPE:`（含 architecture）、`SUITE RESULT: PASS architecture`、
   各 `SUITE RESULT: PASS <ui>`、`UI PASS: N assertions`；`summary.json` 的 `status=passed`，
   且 `before==after` 指纹（`source_changed` 不算通过，需改动安定后重跑受影响域）。
3. 人的路径证明（按顺序操作界面，每条断言的判据是 suite 的布尔 check）：
   - 战斗中点击一张手牌（选择）→ 无版本变化、无付款；翻面 → 卡面与 View 一致且不变状态；
     点选敌人 → 攻击目标与按钮高亮一致；开身体栏 → 详情出现；拖动滚动条 → 滚动位置在随后刷新中保留；
   - 由外部推进回合制造陈旧展示（`_index_boundary_tests` 路径）→ 点击界面上的旧行动 →
     只出现提示、快照版本追平、不扣费、不写档；
   - 点击一个当前不可用／被拒的目标（不可进入的路线房间、绑缚目标上的无效牌、无可用部位的自由牌、
     无效自身目标牌、单面牌、与当前拘束具不匹配的快捷栏牌）→ 只出现提示，界面无整树重建
     （除该表脏集节外，其余节节点实例与滚动位置不变），不扣费、不改版本、不写档；
   - 点击结束回合 → 整页切换为奖励／整备且没有旧候选按钮残留、立绘实例仍为原实例；
   - 键盘：Tab/方向选择后确认 → 恰好提交一次；Esc 取消 → 状态零变化；
   - 触摸：单击与长按卡牌 → 与鼠标同路径，不重复提交；点按一个被拒／不可用目标 → 拒绝提示可见
     （与桌面一致），状态零变化、不写档。
4. 归属判定：失败原因分"实现代码／测试脚本／环境／程序本身"；原因不确定就保持未分类上报，
   不自动改产品代码。
5. 证据：`build/checks/<id>/check-rules.log`、`check-ui.log`、`summary.json`；
   结果与域写 docs/verification.md（validator 负责，不在本文件宣称通过）。

## 11. 完成定义（Definition of Done）

命令（必跑，一次，不无故重复）：
```
& tools/check.ps1 -Suite architecture -Impact -TimeoutSeconds 600
& tools/check.ps1 -Suite architecture -UI -UISuite display,body_layout,targeting,keyboard,touch,interface -TimeoutSeconds 900
```
必过的场景：§9 的 1–9 全部具名 check 通过；`tests/ui_smoke.gd` `_index_boundary_tests`（陈旧提交四条）原断言不变且通过。
必有的证据：两份 check 日志 + `summary.json`（status=passed，指纹稳定）；P0 摘要写入 docs/verification.md
（含机器／件数／函数名／中位数／样本数），原始计时目录已删除。

算未完成（任一）：
- 任一必跑套件未执行、失败、未知或被跳过；`summary.json` 为 `source_changed`／`failed`／`plan`；
- 用旧版本的通过拼接最终结论；删／弱化既有断言（尤其 `tests/ui_smoke.gd` `_index_boundary_tests` 四条）换绿灯；
- 键缺字段、兜底条件靠隐式路径、选择类点击仍整树重建、失败路径仍整树重建且无键依据；
- §0 表 6 处选择类拒绝分支仍走整树 `render(view)`（应按该表脏集上界刷新）；
- 生产源码留计数器／计时钩子；提交 timer 脚本或 build/ 数据；
- 改动 core／存档语义／文案／依赖方向；未授权新增文件；
- 以"应该更快"或单次采样宣称提速，或宣称完整回归／全量通过。

## 12. 加厚档位展开（协调者已选：节键漂移门禁 + 全重建兜底行为断言）

范围与强度：只做 H1、H2 与受影响域回归；不引入变异测试／覆盖率门禁（本仓库无对应工具链，
未选即不得声称通过，也不得自行扩范围）；不加常驻钩子。

H1 节键漂移门禁（键必须覆盖该节渲染实际读取的 View 字段）
- 目标模块：`ui/main.gd`（节／键函数）、`ui/shell/body_sidebar.gd`（既有 `_presentation_key`）、
  `ui/shell/game_layout.gd`（节清理集合）、`ui/keyboard_input.gd`（无节键，回归）。
- 适用检查：① architecture 静态扫描（§9 场景 6，源文本字段子集断言）；② display 动态探针——
  对每节代表字段做"改字段 → 该节重建且内容一致／不改 → 实例与滚动不变"。
- 有限输入域：节表 15 节 × 每节 2 个代表字段（键内字段），动态探针 ≤30 次；
  夹具域：0 件与 12 件装备 × battle/prepare/rest/shop/route/event 六阶段。
- 命令：`& tools/check.ps1 -Suite architecture -Impact -TimeoutSeconds 600`；
  `& tools/check.ps1 -UIOnly -UISuite display,body_layout -TimeoutSeconds 600`。
- 通过判据：静态门 0 缺失（新增 `view.<field>` 读取必须同批进键）；动态探针全部满足；
  未声明字段刷新不改变实例与滚动。红则修键／修实现，不许豁免或削弱断言。

H2 全重建兜底路径行为断言
- 目标模块：`ui/main.gd` 的兜底分支、`game_layout.end_frame` 回收、`body_sidebar` 释放与重建。
- 适用检查：display／interface／body_layout 的 §9 场景 4、7；触发清单见 §3.3 共 14 条
  （phase/show_home/show_route/locale/显示设置/layout 未实例化/空 View/版本回退/节键缺失/
  reward_panel.active/demo_end/pressure.overloaded/card_chain/首次战斗教程），
  每条 1 触发 + 1 反例 ≤28 次 present；phase/show_home 用真实点击，其余用真实状态变更 + 快照渲染。
- 命令：同 H1 的第 2 条（UISuite 增加 `interface`）。
- 通过判据：每个 trigger 断言"全量被选中 + 无陈旧节节点 + View/ActionIndex 与 game 一致 +
  hero/敌人实例不重复"；反例断言"未走全量"；任一项红即 H2 未完成。

## 协调者记录（2026-09-17）：结算窗口与输入队列（**已讨论、未排期**）

起因：卡顿定位发现"版本号是唯一的意图守卫"，并演示出真实故障——**卡顿时连点两次【结束回合】，第二次迟到但仍合法**：候选 ID 是 `payload` 的哈希（`core/game.gd` 的 `_candidate` 里 `row.id=JSON.stringify(payload).sha256_text().substr(0,24)`），与新版本里的同 payload 候选**哈希完全相同**，因此它会通过复核并把**下一个回合也结束掉**。

现状事实（已核）：
- **数据层分开**：菜单/抽屉是纯 UI 本地状态（`ui/main.gd:114 const DRAWERS=[…14 个布尔]`），不进 `state`、不是候选、不经 `dispatch`；游戏动作才是候选（`kind`: `attack`/`end`/`depart`/`hook`/`posture`/`rest_*`/`retain*`/`finish_prepare` 等）。
- **输入层混合**：`ui/main.gd:_input` 先让 `keyboard_input.handle(event)` 吃事件（既提交动作也切抽屉/地图），随后同一函数处理 `ui_cancel`、选牌、语音、动作日志。
- **没有"回合窗口"概念**：非交互阶段靠"没有候选"隐式达成；**动画期间靠 UI 早退静默吞输入**（`_submit` 的 `if is_instance_valid(enemy_feedback): return`），**核心不知道结算/动画在进行**。

拟议形态（**未排期、未授权**，将来做时须走契约＋人批）：
1. **核心侧显式窗口**：`state` 增加可执行窗口（如 `input_window: player / settling / menu`），由事务维护；`dispatch` 要求"窗口＝player"。版本号保留，但角色降为新鲜度校验，不再是唯一意图守卫。
2. **UI 侧结算队列＋按 kind 策略表**：结算期间到达的输入入队，窗口重开后按序重放；**每个候选 kind 必须声明策略**：`queue`（可排队重放）／`drop`（丢弃并给反馈）／`collapse`（同 kind 连续重复只留一条）。`end` 取 `collapse` 或 `drop`——把"连续 end turn"从"靠版本号兜"变成"**按声明拦截**"。
3. **窗口关闭由核心/结算驱动**，不由 UI 自行判断动画播完。
4. **闭环检查**：每个候选 kind 必须在策略表内，表外即红（同前几片的式样）。

风险与顺序：① 策略表缺失会静默吞输入 → 必须有闭环检查；② **先把点击变便宜**（提交不再重建整表、`present(dirty)` 局部刷新）→ 窗口自然缩短；③ **动画体系成形前不引入队列**（非目标：不为尚不存在的动画堆复杂度）。

与相邻契约的关系：本条不改 `dispatch(candidate_id, expected_version)` 的现状语义，也不改"版本相等＝新鲜度"的口径；它新增的是**窗口与队列**这一层。落地前必须与"提交路径去重"（候选不再全表重建）合并考虑，避免两处各自维护一套"提交是否有效"的判断。

## 协调者记录（2026-09-17）：术语澄清与"指令收口／分发 + 增量更新"方向

**术语**：本仓文档里的"**路由**"（`docs/check-routing.md`、repo-ops）专指**测试按源码变更选套件**；与"把指令收到同一接口再分发"不是一回事。后者在本文件统一称"**指令收口／分发**"（core 侧唯一入口 `Game.dispatch(candidate_id, expected_version)`，UI 侧收口在 `ui/main.gd:_submit`）。

**人给的判据（原话转写）**：
> 修复完后把现成的路由就利用起来，每次有效操作都进行全量是显然有问题的，高频操作一定要追delta，先考虑覆盖面

按"指令收口／分发"理解后的口径：
1. **不新增入口**，在**既有唯一提交入口**上做；玩家有效操作都从它走。
2. **每次有效操作只做增量（delta）**：现状是"一次成功提交 → 全表候选重建两次（提交复核 1 次＋提交后视图 1 次）"，实测占一次点击 17.8%／32.7%／41.5%（2026-09-17 P0 成功提交，0／12／26 件），这在高频操作上不可接受；应由"本次操作改变了什么"推出"哪些投影/候选需要跟着更新"。
3. **覆盖优先**：先把"**哪些状态变化必须触发哪些更新**"枚举完整（枚举不全＝过期视图/候选，属正确性问题；省时间排在覆盖之后）。

**与既有条目的关系**：本方向与上文"结算窗口与输入队列（已讨论、未排期）"同域——窗口/队列决定"什么时候接受指令"，增量更新决定"接受后更新什么"；两者都建立在**单一提交入口**之上，落地时一并规划，避免两处各自维护"什么算变化"。
