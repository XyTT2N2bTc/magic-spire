# 规划者报告：card_facts 无声明槽

- 域：`core/card_effects.gd::card_facts`，无 `target_slots` 的 `strain`／`slip`／`lower` 普通槽查询。
- 状态：`needs-human-review`，阻塞；未实施、未派工、未写 `docs/spec`。
- 切分：预期单一 `card_facts` 槽循环消费现有 Game 查询，事实逐字段相等且自由面空槽事实保留；详见 `spire-godot/build/card-undeclared-slice-extract.md`。
- 证据：`docs/spec/equipment-query-seam.md` 的 `occupied` 只问实体件/手侧双占，`targets_at` 还含链接、连接、复合覆盖；`occupied=false` 不可安全免查，现有接口没有已证实的廉价完整判空。
- 决定请求：协调者请人审新增统一判空接口/依赖边、改定更窄可证剪枝域，或取消本刀；旧护栏草案不得实施。
- 检查状态：仅静态契约核对；Godot、architecture、档 2、UI 验收均未验证，不宣称通过。
- 范围：提取物与计划待办；无产品代码、测试、打包、发布或推送改动。
