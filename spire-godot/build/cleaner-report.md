# 清洁者报告：全部独立复合接触件（bunny P2）

checkpoint(cleaner): 范围与HEAD确认，无生产改动

域：`tests/architecture_cases.gd::_composite_contact_outside_equipment` 与 `has_targets_at_parity` 内 jacket 断言；生产 `core/game.gd::_visit_targets_at`／`targets_at`／`has_targets_at` 与 `card_facts` 只读消费。契约：`spire-godot/build/implementer-report.md`（bunny P2 全量独立期望）与前次审查 `spire-godot/build/review-composite-expect-bunny.md`（单哨兵部分返回不通过）。HEAD 起步 `fdaf682` 与实际一致；`git diff 8970595..HEAD -- spire-godot/tests/architecture_cases.gd` 为空，`git diff 029ac58..HEAD --stat` 仅 `spire-godot/tests/architecture_cases.gd` 与 `spire-godot/build/implementer-report.md` 两文件；`core/`／`data/` 无差异，`card_facts` 未碰；`spire-godot/ui/*.uid` 保持未跟踪、不提交；不 push。

checkpoint(cleaner): 只剩一个选择器通过

域：`tests/architecture_cases.gd` 内复合接触选择器。`_composite_contact_outside_equipment` 定义仅 1 处（651行），调用仅 1 处（764行 jacket 断言）；`composite_contact|outside_equipment` 全仓 tests 命中仅该定义与该调用，无第二套复合接触选择器。

checkpoint(cleaner): 选择器不调用targets_at与has_targets_at选期望通过

域：`_composite_contact_outside_equipment` 体（651–658行）。体仅调用 `Composites.definition`／`equipment_at`／`ids_for`；651–658段内无 `targets_at`／`has_targets_at`（全文件89处命中跳过该段，下一命中为660行走查函数）。下游 jacket 断言内 `has_targets_at`／`targets_at` 调用（771行逐接触包含性、776行禁用跟随）是 walk 验证，非期望选择旁路。

checkpoint(cleaner): sleeves与hem各钉住通过

域：`has_targets_at_parity` 内 jacket 断言（764–776行）。768–769行分别断言 `outside.any(c.id==sleeves)` 与 `outside.any(c.id==hem)`；765行断言 outside 非空；771行逐接触断言 walk 包含 slot+id；775–776行禁用后逐接触跟随为 false。漏任一组件（或任一覆盖槽对）即红，闭合前次审查的部分返回漏检。

checkpoint(cleaner): 笛卡尔重复核对通过，非无意义重复对

域：`_composite_contact_outside_equipment` 返回形状相对生产走查。jacket standard 定义（`data/composites.gd` 43–47行）：`coverage=E.B.ARM_SLOTS`（5槽：upper_arm/forearm/wrist/palm/fingers），组件 body（coverage=ARM_SLOTS）＋sleeves（coverage=[]／contact=[wrist]）＋hem（coverage=[]／contact=[upper_arm]）。`equipment_at` 按 `slot in Equipment.coverage` 过滤活件（`core/game.gd` 1070–1074行），故每覆盖槽 hosted 含 body 而永不含 sleeves／hem，助手返回 5槽×2件=10对，无完全相同的(slot,id)重复。生产 walk 对普通槽先收 `equipment_at`，再对 `slot in Composites.definition(root).coverage and active` 的根追加全部组件（仅排肩／引用去重，`core/game.gd` 1123–1131行）；契约 `docs/spec/equipment-query-seam.md` 33行同槽 `targets_at` 语义亦为该拼接顺序。故每对 (slot,sleeves/hem) 都是真实 walk 事实（sleeves 在 upper_arm 亦在 walk 内），笛卡尔形状与生产一致，不是无意义重复。禁用循环复用同一数组按接触逐槽断言 false（同槽出现两次、消息按槽重复），覆盖全部5槽；为保槽覆盖不改该形状，不做为压数字而动的断言 churn。

checkpoint(cleaner): 检查器与门禁核对，缺失报未建

域：本仓结构／依赖检查器。`spire-godot/tools/` 仅 `check.ps1`／`check-docs.ps1`／`check-content.ps1` 等既有门禁，无复杂度／依赖方向专用检查器，报未建；按简报不新建框架。项目 AGENTS 无 Size and ESM，不适用；`tests/architecture_cases.gd` 2201行超长是既有，按简报不拆。composites 2/96 不在本刀，不修。

checkpoint(cleaner): 验证与结论，本域已洁

域：本刀（bunny P2 全部独立接触）。本刀未改产品与测试代码故未重跑 architecture 套件；代码指纹与实现者取证一致（`git diff 8970595..HEAD` 测试文件为空，`git diff --check` 通过），消费同指纹证据：exit 0、`SUITE RESULT: architecture PASS`、`PASS: 3883 assertions`、docs PASS（35 docs，2412 refs）、`summary.json` status `passed` 且 before==after。未运行项沿实现者报告：equipment／composites／links／shoulder／torso_binding 独立套件未跑。结论：本域已洁，无清洁改动，无范围冲突；`.uid`／`.import` 未提交，未 push。
