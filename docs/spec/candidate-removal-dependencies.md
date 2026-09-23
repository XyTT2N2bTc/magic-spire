# 候选层移除与指令路由：依赖约束（cleaner 可核对）

本文件是「候选层移除与指令路由」（`docs/spec/candidate-removal.md`）一片的依赖约束：允许改动的文件、
允许的依赖方向与禁止项。与实现文件面**逐文件一致**（多写少写都算失败）；开工当日用文末复算命令重取
迁移面清单，有漂移先协调者改本表，不得静默多改少改。
本文件不写执行结果：通过／失败／未执行登记 `docs/record/verification.md`。
本片标 `needs-human-review`：人审通过（协调者记录）前实现者不得开工；批 R2 另需 Q1 裁定（新 UI 文件提案）。

路径约定：不带 `spire-godot/` 前缀的源码、测试与工具路径（`core/`、`ui/`、`data/`、`tests/`、`tools/`、`build/`）
均相对 `spire-godot/`；`docs/` 相对仓库根。

## 允许改动（核心面，14 文件）

| 文件 | 允许的改动 | 必须保持 |
| --- | --- | --- |
| `core/game.gd` | R1 抽唯一合法性判定（工作名 eligibility，未落地）；R2 `core/game.gd::dispatch` 改收类型化指令（形状＋参数合法性复核），删按 id 取行；R3 显示事实来源（`core/game.gd::_fact`／`core/game.gd::display_fact`／`core/game.gd::shape_key` 与行动／姿态／墙面／底栏的事实构建器）；R5 删 `core/game.gd::candidates`／`core/game.gd::_candidate`／`core/game.gd::_build_candidates`／`core/game.gd::_phase_candidates` | 五条预检（Consumables／Binding／SpecialEquipment／Cards／RelicEffects）的顺序与 `error` 文案、事务副本与全回滚、`version` 成功一次自增、执行分支、`get_view` 调用点白名单语义逐字不变 |
| `core/game_view.gd` | R3–R5 显示点改经唯一判定取显示事实（T5；R3 落地：新增 `view.display_facts` 键＝`core/game_view.gd::display_facts`）；不再物化行表；删 `view.candidates` 键 | `core/game_view.gd::build` 签名；显示字段**值**（availability／原因／风险／费用等）逐字段不变；只读 |
| `core/first_turn_control.gd` | R1 接管阻断并入判定（不再写 `valid`／`reason`）；`select` 不再直呼行工厂；R5 行构建面删除 | `begin_turn`／`commit`／`view`／`validate` 语义；"豆包接管中"文案；`control_next` 事务内消费与回滚不变 |
| `core/card_effects.gd` | R3 `availability` 改消费判定结果，卡牌事实 `core/card_effects.gd::card_facts`／`core/card_effects.gd::target_facts`（手牌域）；R5 行生产改显示事实构建 | availability 显示语义与文本不变 |
| `core/consumables.gd` | R5 行生产转发改显示事实构建 | 枚举语义、文案、顺序不变 |
| `core/demo_exit.gd` | R5 行生产转发改显示事实构建 | 同上 |
| `core/witch_character.gd` | R3 角色2 攻击事实 `core/witch_character.gd::attack_facts`（行动栏）；R5 行生产转发改显示事实构建 | 同上 |
| `core/room_events.gd` | R5 行生产转发改显示事实构建 | 冻结选项语义不变 |
| `core/relic_bundle.gd` | R5 行生产转发改显示事实构建 | 同上 |
| `core/room_services.gd` | R5 行生产转发改显示事实构建 | 同上 |
| `core/relic_effects.gd` | R5 行生产转发改显示事实构建 | 同上 |
| `core/prison.gd` | R3 牢门解锁事实 `core/prison.gd::unlock_facts`（手牌可用性输入）；R5 行生产转发改显示事实构建 | 同上 |
| `core/mana_flask.gd` | R5 行生产转发改显示事实构建 | 同上 |
| `core/departure.gd` | R5 行生产转发改显示事实构建 | 同上 |

## 允许改动（UI 面，16＋2 文件）

| 文件 | 允许的改动 | 必须保持 |
| --- | --- | --- |
| `ui/main.gd` | R2 A1–A60 直连与改道（A40–A45）收敛为 `emit`；`ui/main.gd::_submit` 改造为路由执行段（Q4 定名）；R3 显示改线（显示键 `ui/main.gd::display_key`；姿态拖放身份改形状键）／R4 显示改线 | 唯一提交执行段；`ui/main.gd::render` 空快照取投影；checkpoint 非空才写盘；选择类点击零提交零写盘 |
| `ui/action_index.gd` | R5 **整文件删除** | 删除前不得先改语义；删除属终态断言之一 |
| `ui/target_queries.gd` | R4 行筛选面（`payload_candidates`／`release_*`／`body_cards`／`single_*`）改指令装配或并入分类子路由；纯显示查询（`ui/target_queries.gd::body_at`／`ui/target_queries.gd::equipment_entries`）保留 | 纯显示查询语义不变；不持游戏、控件、跨刷新缓存 |
| `ui/quick_release_bar.gd` | R4 行取用改指令装配 | 格内显示字段与不可用原因原文不变 |
| `ui/drag_targets.gd` | R4 拖放取行改指令装配 | 拖放高亮与接收语义不变 |
| `ui/keyboard_input.gd` | R2 三处直连改 `emit` | host 成员契约（Q4 未改名则不变）；键位与输入语义不变 |
| `ui/first_turn_presenter.gd` | R2 自动接管提交改 `emit` | takeover 语义、对白与语音不变 |
| `ui/deck_browser.gd` | R2 直连改 `emit` | 显示与按钮语义不变 |
| `ui/departure_screen.gd` | R2 三处直连改 `emit` | 同上 |
| `ui/event_screen.gd` | R2 三处直连改 `emit` | 事件显示与冻结语义不变 |
| `ui/mana_flask.gd` | R2 直连改 `emit` | 同上 |
| `ui/reward_screen.gd` | R2 六处直连改 `emit` | 同上 |
| `ui/relic_bundle_screen.gd` | R2 四处直连改 `emit` | 同上 |
| `ui/shop_screen.gd` | R2 五处直连改 `emit` | 同上 |
| `ui/shell/body_sidebar.gd` | R2 一处延迟直连改 `emit`（`call_deferred("_submit",…)` 形态，不在契约 §1.1 的 A 表内；见下行说明） | 拖放接收语义不变 |
| 新 UI 文件（工作名 command_router，**未落地**，实现期定名） | R2 新增：指令路由（`emit`＋分类转发表） | 须先过 Q1 提案；不得 preload core |
| 新 UI 文件（工作名 command_routes，**未落地**，实现期定名） | R2 新增：分类子路由（每类指令一条装配） | 同上 |

## 允许改动（测试与工具面）

| 文件 | 允许的改动 | 必须保持 |
| --- | --- | --- |
| `tests/architecture_cases.gd` | 新增 G1／G2／G4／G6／G7（`docs/spec/candidate-removal.md` 第 5 节）＋旧提交面调用形态迁移 | 既有断言语义不删不弱 |
| `tests/display_ui_cases.gd` | 新增 G3／G5／G8＋调用形态迁移 | 同上 |
| `tests/persistence_cases.gd` | 新增 G3（写盘时机部分）／G9＋调用形态迁移 | 存档隔离断言不变 |
| `tests/target_sidebar_ui_cases.gd` | 新增 G5（拖放／目标）＋调用形态迁移 | 真实输入助手用法不变 |
| `tests/body_layout_ui_cases.gd` | 新增 G5（装备／快捷解除／身体栏）＋调用形态迁移 | 同上 |
| `tests/ui_smoke.gd` | `tests/ui_smoke.gd::_index_boundary_tests` 四条**不删不放松**；"ui.actions 已按新状态重建"一语随行索引删除改为等价显示事实断言（波及项，须人类批准）＋调用形态迁移 | 锁定语义不变 |
| `tests/` 其余迁移面（逐文件清单见文末，183 文件） | 旧提交面调用形态迁移（`dispatch` 指令形态、`candidates()` 行断言→显示事实／判定断言、`ui.actions`／ActionIndex→新显示读取） | 期望值与断言语义不变 |
| `tools/release_probe.gd` | `dispatch` 调用形态迁移 | 探针语义不变 |
| `tools/check-docs.ps1` 及其它 `tools/` | **零改动**（允许清单删除条目属 `tools/` 改动，只点名不动手） | — |

## 允许改动（文档面）

| 文件 | 允许的改动 | 必须保持 |
| --- | --- | --- |
| `docs/spec/candidate-removal.md`、`docs/spec/candidate-removal-dependencies.md` | 本片契约与后续改写（含 R5 终态义务：已删符号锚点改纯文本历史名） | 被取代口径删改，不加「更正」段 |
| `docs/spec/response-pipeline.md` | 仅第 10 节波及清单点名段落（接缝 A、术语段、失败语义、输入域、锁定断言行、未排期方向段），须**人类批准后统一同步** | 节键表与兜底清单仍为唯一来源；其余内容不动 |
| `docs/spec/release-interface.md` | 仅波及清单点名段落（同上审批条件） | 其余内容不动 |
| `docs/spec/ondemand-copy.md` | 仅 `candidate_detail` 相关节（同上审批条件） | 文案路由与按需语义其余不动 |
| `docs/spec/transition-pipeline.md` | 仅证据入口「取候选 → `dispatch`」措辞（同上审批条件） | 迁移声明表与闭环 check 不动 |
| `docs/spec/save-fixed-points.md` | 仅证据入口「取候选 → `dispatch`」措辞（同上审批条件） | 固定点语义与写盘规则不动 |
| `docs/spec/event-pipeline.md` | 仅事件系统结构表「候选／界面／提交复核」三行（同上审批条件） | 事件定义与求值管线不动 |
| `docs/spec/equipment-query-seam.md` | 仅波及清单点名的候选措辞行（同上审批条件） | 接缝 ①–⑤ 内部一行不改 |
| 根 `AGENTS.md` | 仅禁区行「不绕过正式候选修正界面结果」改写（同上审批条件） | 其余任何内容不动 |
| `.zcode/skills/spire-architecture/SKILL.md` | 仅候选相关行（描述行、「提交必须复核候选身份与状态版本」、「UI 提交已有候选 ID＋版本…」两行，同上审批条件） | 其余任何内容不动 |
| `docs/record/*` | 只追加登记（由协调者指派写入） | 历史条目不改 |

## 允许的依赖方向

- core／data 不 preload ui；`ui/` 内只有 `ui/main.gd` 允许 preload core；两个新 UI 文件不得 preload core。
- 新增边只允许 `docs/spec/candidate-removal.md` 第 2.1 节的 T1–T5；**同批立新边即删旧边**；
  任何时刻每条边只有一条对应路径。
- 提交面复算口径：契约 §1.1 的 A 表用 `rg '_submit\('` 复算，不匹配 `call_deferred("_submit",…)` 形态；
  `ui/shell/body_sidebar.gd` 的延迟直连因此未进 A 表，但属同一收敛面（R2 已改 `emit`，见上行）。
- 不新增第三方依赖、不新增运行时钩子、生产源码不带计数器／计时钩子、不新增存档字段与随机域。

## 禁止项

- 第二份合法性判定（任何地方重算 `valid`／`reason`）；绕过指令路由的第二提交入口；UI 自行判定资格。
- 用译文／名称／颜色／图片识别对象；用 `version` 当缓存键或失效键；跨 View 保留行或旧显示数据。
- 改拒绝／原因文案、数值、可见文案、键位与输入语义、立绘与动画体系。
- 改 `core/snapshot.gd::REVISION`；新增存档字段；改随机域语义；改存档格式与 `save_revision`。
- 触碰装备只读查询接缝内部（`_query_stack_items`／`targets_at` 等）；实现 `escape_preview` 按需化。
- 删改 `tests/ui_smoke.gd` 锁定断言（等价改写除外且须批准）；删有效失败用例换绿灯；新增 check-docs 允许项。
- 复活被取代三片的未落地设计（display_rows／get_view_scoped／candidate_deps 等）。
- 推送、打标签、改版本号；改 `project.godot` 或导出预设。

## 自检清单（实现者交付前逐条对照）

- `rg` 复算：A 组直连 0 条；UI 侧 `dispatch` 调用点唯一；写 `valid`／`reason` 仅唯一判定一处。
- 终态五对象不存在（`candidates`／`_candidate`／`_build_candidates`／`_phase_candidates`／`ui/action_index.gd`）；
  无按提交身份 id 的取行复核。
- 每批同批立新边删旧边；批间门禁绿；敏感性证明各一次实测取证。
- 拒绝／原因文案逐字比对通过；`REVISION`／随机域／存档字段不变；回滚完整。
- 依赖表文件面与实际改动文件面**逐文件一致**。

## 测试与工具迁移面（逐文件清单，2026-09-23 复算）

复算命令（在 `spire-godot/` 下执行；开工当日重取，漂移先改本表）：

```powershell
rg -l "\.dispatch\(|candidates\(\)|candidate_detail|ActionIndex|ui\.actions|\.actions\.(select|find|first_usable|by_id|by_group)|TargetQueries|quick_release_bar" tests tools --glob '*.gd'
```

清单（183 文件；另加 `tests/display_ui_cases.gd`＝新增 check 落点，不在上式命中内）：
```text
tests/action_copy_cases.gd
tests/action_copy_ui_cases.gd
tests/action_log_cases.gd
tests/adaptability_cases.gd
tests/architecture_cases.gd
tests/axe_amulet_cases.gd
tests/basic_attack_cases.gd
tests/basic_attack_ui_cases.gd
tests/battle_reward_cases.gd
tests/battle_saturation_cases.gd
tests/binding_enthusiast_cases.gd
tests/binding_power_cases.gd
tests/binding_search_cases.gd
tests/body_consumable_cases.gd
tests/body_layout_ui_cases.gd
tests/boss_relic_cases.gd
tests/breath_control_cases.gd
tests/card_expansion_cases.gd
tests/card_music_cases.gd
tests/card_music_ui_cases.gd
tests/card_power_cases.gd
tests/card_power_ui_cases.gd
tests/card_splash_cases.gd
tests/card_splash_ui_cases.gd
tests/card_text_cases.gd
tests/casting_cases.gd
tests/casting_ui_cases.gd
tests/charge_cases.gd
tests/composite_cases.gd
tests/concentration_cases.gd
tests/concentration_ui_cases.gd
tests/confluence_cases.gd
tests/consumable_cases.gd
tests/content_cases.gd
tests/crossed_legs_cases.gd
tests/cumulative_cards_cases.gd
tests/curse_cases.gd
tests/cursed_plate_cases.gd
tests/demo_exit_cases.gd
tests/departure_cases.gd
tests/desire_cube_cases.gd
tests/ditto_cases.gd
tests/drone_cases.gd
tests/echo_cast_cases.gd
tests/edging_seal_cases.gd
tests/ember_crystal_cases.gd
tests/embers_cases.gd
tests/endless_war_goddess_cases.gd
tests/endless_war_goddess_ui_cases.gd
tests/enemy_cases.gd
tests/enemy_feedback_ui_cases.gd
tests/enemy_heap_cases.gd
tests/enemy_mixed_cases.gd
tests/enemy_ritual_cases.gd
tests/enemy_serpent_cases.gd
tests/enemy_split_cases.gd
tests/enemy_ui_cases.gd
tests/enemy_versatile_cases.gd
tests/environment_height_cases.gd
tests/equipment_art_ui_cases.gd
tests/equipment_cases.gd
tests/equipment_complete_cases.gd
tests/equipment_ui_cases.gd
tests/event_cases.gd
tests/event_draw_cases.gd
tests/event_flow_cases.gd
tests/event_ui_cases.gd
tests/exploration_cases.gd
tests/fire_control_cases.gd
tests/fire_dynamics_cases.gd
tests/first_turn_control_cases.gd
tests/first_turn_control_ui_cases.gd
tests/flame_flourish_cases.gd
tests/follow_through_cases.gd
tests/formation_cases.gd
tests/graduate_certificate_cases.gd
tests/great_wand_cases.gd
tests/great_wand_ui_cases.gd
tests/guard_cases.gd
tests/guard_ui_cases.gd
tests/hand_assist_cases.gd
tests/hand_assist_ui_cases.gd
tests/hannya_cases.gd
tests/hannya_ui_cases.gd
tests/home_persistence_ui_cases.gd
tests/impact_feedback_ui_cases.gd
tests/infusion_cases.gd
tests/installation_priority_cases.gd
tests/installed_tools_cases.gd
tests/installed_tools_ui_cases.gd
tests/intent_cases.gd
tests/interface_ui_cases.gd
tests/iron_man_cases.gd
tests/item_discard_cases.gd
tests/keyboard_ui_cases.gd
tests/kip_up_cases.gd
tests/letter_opener_cases.gd
tests/leverage_cases.gd
tests/lewd_magic_cases.gd
tests/lewd_magic_ui_cases.gd
tests/lewd_relic_cases.gd
tests/light_as_swallow_cases.gd
tests/link_cases.gd
tests/lucidity_necklace_cases.gd
tests/magic_hand_cases.gd
tests/mana_attachment_cases.gd
tests/mana_attachment_ui_cases.gd
tests/mana_circuit_cases.gd
tests/mana_flask_cases.gd
tests/mana_flask_ui_cases.gd
tests/mana_recovery_cases.gd
tests/mana_search_cases.gd
tests/membership_card_cases.gd
tests/normal_play_cases.gd
tests/olihakimi_cases.gd
tests/persistence_cases.gd
tests/persistence_ui_cases.gd
tests/practiced_cases.gd
tests/pressure_cases.gd
tests/pressure_relic_cases.gd
tests/pressure_ui_cases.gd
tests/prison_cases.gd
tests/prison_reinforcement_cases.gd
tests/prison_ui_cases.gd
tests/puppeteer_cases.gd
tests/ready_to_strike_cases.gd
tests/reinforcement_lock_cases.gd
tests/rekindle_cases.gd
tests/relic_bundle_cases.gd
tests/relic_mana_cases.gd
tests/relic_revision_cases.gd
tests/resonance_cases.gd
tests/restraint_embrace_cases.gd
tests/restraint_embrace_ui_cases.gd
tests/reward_cases.gd
tests/reward_ui_cases.gd
tests/rolling_log_cases.gd
tests/route_driver.gd
tests/route_ui_cases.gd
tests/scene_restart_cases.gd
tests/scrap_robot_cases.gd
tests/scrap_robot_ui_cases.gd
tests/secret_weapon_cases.gd
tests/self_binding_cases.gd
tests/service_cases.gd
tests/service_ui_cases.gd
tests/shared_fate_cases.gd
tests/shop_release_cases.gd
tests/shoulder_cases.gd
tests/shoulder_ui_cases.gd
tests/siphon_cases.gd
tests/siphon_strength_cases.gd
tests/siphon_ui_cases.gd
tests/six_bind_cases.gd
tests/slip_motion_cases.gd
tests/slip_motion_ui_cases.gd
tests/special_equipment_cases.gd
tests/special_equipment_ui_cases.gd
tests/sundial_cases.gd
tests/supple_flesh_cases.gd
tests/sympathetic_form_cases.gd
tests/target_sidebar_ui_cases.gd
tests/temporary_mana_cases.gd
tests/tentacle_friend_cases.gd
tests/test_game.gd
tests/torso_binding_cases.gd
tests/torso_binding_ui_cases.gd
tests/tower_cases.gd
tests/tower_progression_cases.gd
tests/tower_progression_ui_cases.gd
tests/trader_ui_cases.gd
tests/ui_smoke.gd
tests/unique_power_reward_cases.gd
tests/universal_scanner_cases.gd
tests/universal_scanner_ui_cases.gd
tests/wall_cases.gd
tests/wall_ui_cases.gd
tests/wildfire_descent_cases.gd
tests/witch_character_cases.gd
tests/witch_character_ui_cases.gd
tests/witch_expansion_cases.gd
tests/witch_revision_cases.gd
tools/release_probe.gd
```
