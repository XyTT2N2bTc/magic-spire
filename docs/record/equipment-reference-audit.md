# 拘束对象与接口引用追踪 · 2026-09-14

> 路径说明：本卷正文保留撰写当时的文件路径（旧 `docs/<名>.md` 现按类归入 `docs/spec|design|guide|record|history/`）；需要定位时按文件名搜索。


记录类型：审计记录（只追加）；不是规范正文，接口契约见 `docs/spec/`。

日期与域：2026-09-14～2026-09-15。域＝`spire-godot/core/`（装备实体、查询接口、候选与清理）与 `spire-godot/ui/`（View 与界面引用）的拘束对象创建、持有、查询与引用边界；性能测量见 `equipment-performance.md`，验证结论见 `verification.md`。

口径：表格列出的是静态调用点与抽样追踪，不冒充动态次数或全组合覆盖。

本次沿创建、持有、查询、候选、提交、清理和界面检查拘束对象。运行时的装备实体是Dictionary；装备图片和详情控件是独立的显示对象。以下表格中的多个查询入口覆盖不同对象范围，不能因名字相近而直接合并。

2026-09-15新增快捷栏跟进：update_tile与candidate分别在本次调用内共用区域、小部位和装备解析；body_at／equipment_at沿相同解析入口保持原调用语义。可用目标集合只服务本次排序，仍从ActionIndex中的原候选读取；没有新增玩法查询或写接口，也不按View版本缓存UI选择。全组卡牌扫描计数、五场景对照和交互验证见equipment-performance.md与verification.md。

## 对象逐类追踪

| 对象 | 创建与权威持有位置 | 外部关联 | 查询及清理 |
| --- | --- | --- | --- |
| 普通件 | game._install_template → state.equipment | 独立equipment ID，真实部位points | physical_pieces / equipment_at；_cleanup移除失去耐久的普通件，保留诅咒规则 |
| 复合根与部件 | _prepare_assembly / _make_assembly_piece → _install_assembly → state.composites[].components | 部件root_id指向根；根无额外行动耐久 | physical_pieces返回部件，不把根再加入目标；_cleanup按独立外带生命周期保留或级联删除 |
| 肩带 | shoulder_links.install / refresh → 普通宿主.shoulders.pieces；复合肩带位于components | shoulder_host / root_id | physical_pieces展开一次；Shoulders.cleanup在宿主或肩带失效时清理 |
| 躯干连接 | torso_binding.refresh → 普通宿主.binding | parent_id指宿主，一体式不新增独立目标 | Binding.connections只返回真实连接式对象；宿主删除后自然不再可查询 |
| 独立链接绳 | _prepare_link → _install_link → state.links | ends / slots / points保存真实两端ID与位置 | equipment_targets增加链接；_cleanup在自身断开或端部对象不存在时删除 |
| 特殊装备及加固带 | _install_special / _attach_chastity_reinforcement → state.special_equipment | 加固带owner_id指向锁体 | action_targets加入特殊对象；_cleanup处理主体删除及失去宿主的加固带；替换也通过原装备事务 |

九个场景 equipment、component_links、prison_test、head_harness、jacket、shoulder_links、shoulder_auto、torso_binding、special_equipment 的行动目标ID均唯一，_equipment返回的是对应权威实例，状态验证通过，读查询退出后没有残留索引。例：component_links为2个复合根、6个部件及1条链接，共7个行动目标；根没有被重复算成第8／9个目标。完整数目见build/equipment-performance-20260914/object-audit.json。该抽样不能替代所有未来组合的验证。

## 查询接口逐项追踪

| 接口 | 返回范围和主要使用方 | 引用约束 |
| --- | --- | --- |
| physical_pieces | 普通件＋复合部件＋普通肩带；接触、容量、敌人、替换、显示 | 新数组，成员仍为当前权威实例，不含独立链接或特殊装备 |
| equipment_targets | physical_pieces＋独立链接；徒手候选、收押与巡视清单 | 不把特殊物品混入普通装备清单 |
| action_targets | equipment_targets＋特殊装备＋躯干连接；卡牌、工具、效果与ID查找 | 行动用的完整物理目标集合 |
| equipment_at | 按coverage与有效耐久筛选普通物理部件；名称、活动度、层序与候选 | 数组可由调用方排序／清空，不能破坏同批查询索引 |
| targets_at | 加上真实复合覆盖、链接及身体连接；卡牌资格、连段与View | 是行动目标范围，不等同于容量占用范围 |
| _equipment | 从action_targets按稳定ID找到实体；合并重复查找后67处静态调用点，遍布规则、效果、清理及投影 | 同批只读查找使用ID索引；正式提交重新按当前状态查找 |
| _stack_items | 与目标真实覆盖重叠的件；escape_preview、特殊装备名称 | 不跨提交缓存；临时／复制目标绕开权威实例缓存 |
| escape_preview | 计算层级、锁、堆叠、辅助、姿势、增益与方法资格 | 输出解释与数值，不修改目标；不同模式和参数不能仅按ID合并 |
| _candidate | 汇合目标封锁、施法、资源及风险，输出payload.target等稳定ID | 候选不持有整个装备对象；执行前仍有版本与资格复核 |
| _cleanup | 正式行动、连段、替换推演、事件和自动滑脱调用 | 不是空闲帧任务；删除依赖后再生成新View，不复用旧读索引 |

静态调用点的文件、行号与所属函数逐条列在build/equipment-performance-20260914/interface-references.json。统计是字面代码调用点，不冒充动态次数。动态追踪覆盖game.gd的180个实例方法，本次29件样本实际经过73个方法；core/data静态辅助函数没有逐个插桩，其耗时归到所属实例方法，不能用它断言所有静态函数都已测过。

## View与UI引用

GameView.equipment_entry创建显示字典，body_groups / body_sections / ReleaseView.regions分别组织精准部位、合并部位与四区。跨部位会出现同一ID的显示条目，这是共享部件的多处展示，并非再次安装；UI._body_equipment_entries和区域targets按ID合并。原architecture检查逐层验证View不共享state或注册表的可写容器。

UI.main持有当前View、ActionIndex和候选按钮索引。普通render清空输入索引，game_layout清理临时控件；身体栏保留显示事实未变的按钮，回调按稳定部位ID读当前候选。装备详情只在展开时创建动作控件，刷新时随原详情释放。装备立绘保留一个场景和有限素材层，按外观事实决定更新，不为每件绳索新增逐帧处理对象。

提交链为：UI候选ID＋版本 → dispatch复核 → 复制事务状态 → 按ID找事务内对象 → 原规则修改及_cleanup → 新只读View。旧View仍是旧显示快照，不能用旧Dictionary对象直接改新事务；本次索引仅存在于一次只读调用内部，推演换state时绕开外层索引，返回后恢复上下文，退出立即释放。

性能数据、发现的重复调用、修改范围与验证结果分别见equipment-performance.md和verification.md。运行时测量产物只在忽略的build目录，不进入游戏资源或发布包。

## 首批高频接口实测

样本：种子42，29个合法物理装备，5张手牌，200个候选；统计一次完整get_view，不是每帧统计。插桩仅用于计数和定位路径，不把插桩耗时当成实际帧率。最终call-audit.json保存全部方法及调用边，参考对象类型和数量见object-audit.json。

| 方法 | 调用次数 | 已定位的来源及处理 |
| --- | ---: | --- |
| number | 3144 | 公式格式化1232次、View正文841次等；频繁但不是最大的计算开销 |
| equipment_at | 1694 | 名称473次，活动度、接触与资格等共用；索引后实际只筛选13次 |
| _equipment | 1130 | 候选、目标名称、部位投影和堆叠身份复核；原_candidate每候选查3次已合为1次，该路径600→200；body_sections也复用同一次查找 |
| _equipment_name | 473 | 多个候选各自构造显示名称；仍使用当前部位顺序命名 |
| _stack_items | 264 | 全部来自解除预览；实际堆叠计算264→29，返回数组仍独立 |
| escape_preview | 264 | 主要由5张牌的双面／各目标资格产生；149组不同完整参数，仍是主要耗时路径之一 |
| _mana_cost / cast_view | 231 / 217 | 手牌、候选及全卡牌文案的费用／施法投影；保留原判定来源 |

内部索引有效性检查另调用3279次，这是便宜的上下文核对，不是重新遍历装备。解除预览虽有相同参数重复，但涉及辅助、被动、区域效果、连段和溅射；本批未以目标ID粗略缓存整份数值，避免混用这些条件。

## 继续优化：完整参数相等时复用

后续显示合批也沿同一生命周期：GameView.equipment_entry只按当前权威实例复用_build_equipment_entry的基础显示行，返回副本后再填写调用方的slot。拘束衣跨部位的15次生成降为3次，复合链接11次降为7次；EquipmentDetails追加内容不会写回缓存。完整card_texts继续提供全部83种牌型，Cards.face_texts合并双面生成，Balance.card_metadata也一次生成两面的效果说明。这里不缓存候选或跨刷新文案，也不把两个部位的slot合并；对应基准和范围见equipment-performance.md的投影合批结果。

后续批次仍使用同一29件样本。escape_preview入口保持264次，真正执行_build_escape_preview为149次；cast_view入口保持217次，_build_cast_view为10次、_cast_path为11次。_mana_cost从231次降到175次，同一张牌在一次候选生成中按牌面复用能量／魔力费用。入口数量不等于实际重新计算数量；number同步降至2610次，equipment_at降至1467次，_equipment因新增权威对象身份复核变为1279次，仍使用本轮索引。

解除预览的复用键包含全部传入参数，不截断浮点值，也不只按目标ID匹配；非当前权威实例直接重算。施法预览按完整profile相等比较。缓存保存独立输入键和独立结果，调用者修改辅助档案、伤害缩放或显示信息不会污染其他预览。临时state和后续正式执行仍重新计算，最外只读调用退出立即释放。生产代码不插入计数器；对应诊断在build/equipment-preview-20260914/call-audit.json和paired-benchmark.json，性能及门禁见equipment-performance.md和verification.md。
