# 候选层接口冻结与显示读取改线：依赖约束（cleaner 可核对）

本文件是「候选层接口冻结与显示读取改线」（`docs/spec/candidate-bypass.md`）一片的依赖约束：
允许改动的文件、允许的依赖方向与禁止项。本片在分支 `seed-chip-save-upload` 上独立成片，
**只写文档、不改产品代码**是规划阶段的状态；实现阶段按本表放行。
本文件不写执行结果：通过／失败／未执行登记 `docs/record/verification.md`。

本片标 `needs-human-review`：人审通过（协调者记录）前，实现者不得开工；B3／B4 还各需一条裁定
（见 `docs/spec/candidate-bypass.md` 的 H3／H4），未获批时不得启动该批。

路径约定：不带 `spire-godot/` 前缀的源码、测试与工具路径（`core/`、`ui/`、`data/`、`tests/`、`tools/`、`build/`）
均相对 `spire-godot/`；`docs/` 相对仓库根。

## 允许改动

| 文件 | 允许的改动 | 必须保持 |
| --- | --- | --- |
| `core/game.gd` | 新增只读入口 `display_rows(needs)` 与其「组 → 行工厂」接线表；表只写已存在行工厂的组，未知组走 fail-closed | `candidates`／`_candidate`／`_build_candidates`／`_phase_candidates`／`dispatch` 的行为、构建序、行集合、行形状、`id` 表达式与拒绝文案逐字不变；`display_rows` 不写 state、不推进随机、不改 version、不产日志与事件、不跨调用保留；`dispatch` 内不得调用它 |
| `ui/main.gd` | `render` 增加同一 View 的局部刷新路径：不重建索引、不读 `view.candidates`、只重建节键变化的节；节键缺失即兜底 | 兜底触发清单与节名沿用 `docs/spec/response-pipeline.md`（唯一来源，不新建第二份节表）；`_submit` 仍只传 `id` 与 `view.version`；`get_view` 调用点集合不变；选择类点击仍不提交、不写档 |
| `ui/action_index.gd` | 默认**零改动** | `by_id`／`by_group` 只登记收到的行；`select`／`find`／`first_usable` 不判定资格、不造行、不改行 |
| `core/game_view.gd` | B3 获批时：候选派生字段改由按键读取取行（只改取值来源） | 字段**值**逐字段不变（含 `hand` 的 `availability` 文本、`items` 的 `target_groups`／`unavailable_reasons`、`body_groups` 的 `can_release`、`reward_panel`、`route`、`first_turn_control`、`card_texts` 显示集合）；`build` 内 `candidates()` 的调用口径变化必须写进验证记录 |
| `tests/architecture_cases.gd` | 新增具名 check：按键读取等价、fail-closed、无第二判定、行工厂入口计数 | 既有断言与助手签名不改；不删既有 `INDEX` 前缀 check |
| `tests/display_ui_cases.gd` | 新增具名 check：同一 View 渲染零读取、点击计数 | 既有断言不删不改 |
| `tests/interface_ui_cases.gd` | 新增兜底触发／反例断言 | 既有页面切换断言不改 |
| `tests/target_sidebar_ui_cases.gd`、`tests/body_layout_ui_cases.gd` | 各新增一条选择类点击零读取断言（复用既有夹具与真实输入助手） | 既有断言不删不改 |
| `tests/persistence_cases.gd` | 新增「显示读取不改存档与随机」断言 | 既有存档隔离断言不改 |
| `docs/spec/candidate-bypass.md`、`docs/spec/candidate-bypass-dependencies.md` | 本片契约落盘与后续改写 | 被取代的口径删改，不加「更正」段 |
| 根 `AGENTS.md` 文档入口表 | 增加一行指向 `docs/spec/candidate-bypass.md` | 其它行不改 |
| `docs/spec/response-pipeline.md` | 实现状态句按新事实改写（该文件自己的「尚无 `commit`、`present`、`present_rejection` 或通用脏节表」会变成部分过期） | 节键表与兜底清单仍是唯一来源，不改内容；锁定断言（`tests/ui_smoke.gd` 的 `_index_boundary_tests` 四条）不得删改 |
| `docs/record/changelog.md`、`docs/record/verification.md` | 实现完成后各追加一条／一节（日期＋域＋命令＋结果＋未跑项） | 只追加，不改历史条目 |

## 允许的依赖方向

- 不新增依赖边：`display_rows` 在 `core` 内，只被 `ui/main.gd` 与测试调用；`core`／`data` 不得 `preload` ui；
  `ui/` 内只有 `ui/main.gd` 允许 `preload` core（现行规则）。
- 不新增文件、不新增模块、不新增第三方依赖、不新增运行时钩子。
- 不新增随机域、不新增存档字段、不新增 View 键、不新增候选、不新增本地化 key、不动 `core/snapshot.gd` 的 `REVISION`。
- 装备只读查询接缝内部（`core/game.gd::_query_stack_items`、`core/game.gd::targets_at` 等）不在本片改动面内。

## 禁止项

- 在 `ui/` 或 `core/game_view.gd` 里另写一份资格判定（重算 `valid`／`reason`、按名称或译文反查规则、
  合成候选行冒充候选层结论）。
- 让 `display_rows` 变成第二提交入口或第二权威（`dispatch` 内调用它、用它替换全表复核）。
- 为省成本删行、跳过行工厂、改构建序或改组名；改 `id` 表达式或行键集合。
- 用 `version` 当缓存键或失效键；跨 View 保留行、候选、装备图或节点引用；由 UI 自行推断作废范围；
  把行缓存进节点或节键。
- 新建第二份节表或兜底清单（唯一来源是 `docs/spec/response-pipeline.md`）。
- 在 B3／B4 未获批时删除提交后的 `get_view`、或宣称点击成本已降到一次物化以下。
- 改 `dispatch` 的六个 `validate`、版本比对、复核顺序与拒绝文案；改数值与玩家可见文案。
- 新增计时钩子或计数器到生产源码（计数只用测试侧包装，经 `ui.game_factory` 注入）。
- 改 `docs/spec/candidate-delta.md` 或 `docs/spec/equipment-query-seam.md`（前者的去留见契约 H5，
  后者是本片点名的冲突来源，裁定前不得改动）。
- 推送、打标签、改版本号、改 `project.godot` 或导出预设。

## 自检清单（实现者交付前逐条对照）

- `rg` 复算：写 `valid`／`reason` 的位置仍只有行工厂一处；`ui/` 无第二处。
- `candidates()` 与 `get_view()` 的调用点集合与改动前逐处相同（新增调用点即失败）。
- 同一 View 的选择类点击：`candidates()` 0、索引构造 0、装备查询建表 0、重建节 ≤ 3。
- `display_rows(needs)` 在每个夹具上与 `candidates().filter(任一键命中)` 逐行逐字段逐顺序相等。
- `display_rows([])`／未知组／`"*"` 三种输入都返回全量结果（fail-closed），且不改状态。
- 未命中任何显示键的行工厂在按键读取中入口计数为 0。
- `export_snapshot()` 在纯显示读取前后相等；随机域计数不变。
- 未新增文件；未改冻结面（F1–F9）；未动 `REVISION`。
- 不可用控件的显示文本等于行内 `reason` 原文（不改写、不拼接）。
- 文档：本片点名的路径都存在；未给未落地符号写 `文件::符号` 锚点；被取代段落已改写而非加注。
