# 清洁者报告：独立复合期望（muse P2）

checkpoint(cleaner): 独立复合期望清洁核对，无代码改动

域：`tests/architecture_cases.gd::_composite_contact_outside_equipment` 及其在 `has_targets_at_parity` 内 jacket 断言；生产 `core/game.gd::_visit_targets_at`／`targets_at`／`has_targets_at` 只做只读核对。契约：实现者报告 `spire-godot/build/implementer-report.md`。本刀允许面：该助手与 jacket 断言；不碰生产走查、`card_facts`、composites 2/96；不拆 `architecture_cases.gd`；不 push；不提交 `*.import`／`.uid`。

HEAD 说明：简报起点 `7ce069e`，实际 HEAD `7ce069e` 一致。`git diff HEAD --name-only` 除本报告外无改动；实现者改动面（`29d572a` 仅 `tests/architecture_cases.gd` 6＋／5－：助手签名加 `jacket` 参、体改独立推导、调用点传 `jacket`；`7ce069e` 仅 `implementer-report.md`）在允许面内；`spire-godot/ui/*.uid` 保持未跟踪、不提交。

checkpoint(cleaner): 单选择器核对通过

域：`tests/architecture_cases.gd` 内复合期望选择器。`_composite_contact_outside_equipment` 定义仅 1 处（651 行），调用仅 1 处（763 行 jacket 断言）；`Composites.definition` 在 tests 内仅 652 行一处；无第二套复合接触选择器。助手体仅调用 `Composites.definition`／`equipment_at`／`ids_for`，651–657 行内无 `targets_at`／`has_targets_at`（全文件 87 处 `targets_at|has_targets_at` 命中跳过 651–657 段）。

checkpoint(cleaner): 期望语义核对通过，不存在误把不覆盖该槽组件当期望

域：`_composite_contact_outside_equipment` 返回的 `(slot,id)` 相对生产走查的有效性。jacket standard 定义（`data/composites.gd` 43–47 行）：`coverage=E.B.ARM_SLOTS`（5 槽），组件按 `body→sleeves→hem` 顺序组装（`core/game.gd::_plan_assembly` 1217–1224 行按 `layout.parts` 插入序）；`body.coverage=ARM_SLOTS`，`sleeves.coverage=[]／contact=[wrist]`，`hem.coverage=[]／contact=[upper_arm]`。`equipment_at` 按 `slot in Equipment.coverage` 过滤活件（`core/game.gd` 1070–1074 行；`Equipment.coverage=e.get(coverage,[slot])`），故任一覆盖槽 `hosted=[body.id]`（sleeves／hem 永不在 `equipment_at`），助手返回首个非 hosted 件（即 sleeves）。生产 walk 对普通槽先收 `equipment_at`，再对 `slot in Composites.definition(root).coverage and active` 的根追加**全部**组件（仅排肩／去重，`core/game.gd` 1123–1131 行）；sleeves／hem 非肩（`is_shoulder=has shoulder_host or template==glove_strap`，`data/equipment.gd` 142–143 行），故 `(upper_arm, sleeves.id)` 满足 slot 在根覆盖、id 在 components、id 不在该槽 `equipment_at`、id 在 `targets_at(slot)`——组件自身 `coverage=[]` 与结论无关，生产按根覆盖分组而非按件覆盖过滤。运行时佐证：实现者 architecture PASS（3863 assertions）含 jacket 断言（763–771 行：outside 非空、id 在 walk、禁用后跟随）全绿；若返回非 walk 件该断言必红。jacket 无肩组件，本切片加 `is_shoulder` 过滤属无敏感性证明的 validation，按规约不加。助手 jacket 专用（glove 路径不用它），不做通用复合选择器。

checkpoint(cleaner): 助手重复核对通过，无第二套接口

域：`tests/architecture_cases.gd` 内 634–660 行助手群。`_has_targets_slots`（B.SLOTS＋shoulder＋特殊槽）是 parity 走查枚举，与 `card_facts_union_slot_oracle`（2132–2140 行：B.SLOTS＋neck＋shoulder＋特殊＋spec.target_slots 的 union-then-skip）域不同，不合并；`_link_slot_without_equipment`（646–649 行：`equipment_at` 空＋`links_at` 非空找活链接槽）与本助手（components＋coverage 减 `equipment_at`）来源不同（链接 vs 复合），不合并；`_check_has_targets_at_once`／`_modes` 复用既有 `ids_for`，各夹具复用 `_clear_gear`。jacket 断言内 `has_targets_at`／`targets_at` 调用（766、771 行）是 walk 包含性验证，属允许面，非选择器旁路。

checkpoint(cleaner): 检查器与门禁核对，缺失报未建

域：本仓结构／依赖检查器。`spire-godot/tools/` 仅 `check.ps1`／`check-docs.ps1`／`check-content.ps1` 等既有门禁，无复杂度／依赖方向专用检查器，报未建；按简报不新建框架。Godot 本仓 AGENTS 无 Size and ESM，不适用；`tests/architecture_cases.gd` 2196 行超长是既有，按简报不拆。

checkpoint(cleaner): 验证与结论，本域已洁

域：本刀（muse P2 独立复合期望）。本刀未改代码故未重跑 architecture 套件；代码指纹与实现者取证一致（除本报告外 `git diff HEAD --name-only` 为空），消费实现者同指纹证据：exit 0、`SUITE RESULT: architecture PASS`、`PASS: 3863 assertions`、docs PASS（35 docs，2412 refs）、`summary.json` status `passed` 且 before==after（非 `source_changed`）。未运行项沿实现者报告：equipment／composites／links／shoulder／torso_binding 独立套件未跑。结论：本域已洁，无清洁改动，无范围冲突；`.uid`／`.import` 未提交，未 push。
