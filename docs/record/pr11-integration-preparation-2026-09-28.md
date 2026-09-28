# PR #11 合并准备（2026-09-28）

## 范围与结论

- PR：https://github.com/h13942080472-prog/magic-spire/pull/11；检查头部 `ec6019767de67e552bee6532abb27f62bf84f27a`，目标 `main` 为 `8398b1cc323ad449cfb13545360d3d136389997d`，目标是其祖先，远端显示可合并。准备分支 `codex/pr11-integration-20260928`。
- PR 相对目标包含275个文件、218个提交，合并装备查询接缝、卡牌依赖、指令路由与 present 分区，并带入种子标识、反馈附件、本局回顾与文档门禁。#11取代已关闭的#8／#9／#10，包含已关闭#7的功能；旧#1／#3不在本批。
- 已形成可合并的本地准备分支；没有合入主检出、推送、修改远端PR、部署反馈服务或打包。本报告不宣称逐行审查275文件、完整UI回归或性能提升。

## 整合与修复

- 保留主工作区八个未提交文件的原始字节，三方整合审查规范与GPL-3.0-only到准备分支。PR的新指令通道优先；当地数值免审、模型分级、复用证据等新要求保留。
- 规范适配：工作树位置按实际仓库定位，移除作者机器的固定路径；文档门禁从“未接入”改为现行状态；清理已删除ActionIndex的使用指引，候选移除契约标明当前实现状态。Godot生成的两份新指令脚本UID一并保存。
- **反馈探针重定向缺陷**：能力探针原先先于跳转处理，将正常302／303判为不支持存档。现在探针与回执共用允许域名、最多4次、无正文GET通道；最终schema决定附件，报告POST仍发原endpoint，探针结束重置回执预算。新增成功跳转、不可信域及超限反例。
- **composites旧测试预期**：真正目标main的96条全部通过；PR侧原断言两条失败，因此不能按主分支既有失败豁免。新指令身份不含派生伤害，charge改变后应按当前状态重新计算。更新测试核对派生payload变化而指令不变、实际只支付一次并耗牌与蓄力，原过期版本零写入拒绝仍保留；生产规则未为过测调整。
- 审查曾提出快捷解除吞点击疑点，经查注册牌型没有可达类型满足该前提，撤回此项，不据假设修代码。

## 本地验证

命令在准备树的 `spire-godot/` 执行，使用PowerShell 7与Godot 4.7.2。

| 范围／命令 | 结果与运行号 |
| --- | --- |
| 目标main：`tools/check.ps1 -Suite composites -KeepGoing` | 96 PASS；20260928T120930513-52780，证据在主检出build/checks |
| PR树：`tools/check.ps1 -Import -Suite composites -KeepGoing` | 首次导入因字体缓存尚未生成而失败；重导入成功后复现2/96失败，20260928T121023228-30352与20260928T121121844-31084 |
| 反馈修前：`tools/check.ps1 -UIOnly -UISuite interface -KeepGoing -TimeoutSeconds 300` | 新增302／303断言变红，434断言内失败；20260928T121407029-28888 |
| `tools/check.ps1 -Suite composites,architecture,runner,equipment,card_power,casting,persistence,event_flow,localization -Impact -Exhaustive -KeepGoing -TimeoutSeconds 900` | 45分类30799 PASS；20260928T121535805-37912 |
| `tools/check.ps1 -Suite item_discard,wall,services,intent,guard,tower -Exhaustive -KeepGoing -TimeoutSeconds 900` | 6分类3741 PASS；20260928T122055763-34568 |
| `tools/check.ps1 -Suite runner -VerifyRunner -TimeoutSeconds 120` | runner 541 PASS及测试器负例通过；20260928T121800494-54148，此541不重复计入规则总数 |
| `tools/check.ps1 -UIOnly -UISuite interface,display,targeting,route,home,home_persistence,card_power,enemies,guard,installed_tools,action_copy,keyboard,touch,intent -KeepGoing -TimeoutSeconds 900` | 14模块3006 PASS，其中interface 434；20260928T121705684-21156 |
| 仓库根：`node --test spire-godot/tools/feedback-service/test.cjs` | 离线服务契约通过，未发送邮件 |

- 两轮规则并集51分类34540断言；enemy_cycle 16/16、enemy_pool 24/24、tower_graph 201/201。14界面模块为真实窗口自动检查，无人工试玩。
- 最终四轮均 `status=passed`、`before==after`，同一指纹 `42531F71A22A7416A5AE0C204768240DB4DD1C5194E81EB6E75697FB71D3824D`；选定范围 `failed=[]`、`unrun=[]`。文档门禁35文件2492引用通过，允许清单仍为6条。工作区差异检查通过。
- 原始日志在准备树 `spire-godot/build/checks/`，聚合摘要在 `spire-godot/build/pr11-prep-20260928/final-checks.json`；PR元数据与评论已另存该目录。原工作区八文件保留验证在其 `build/pr11-prep-20260928/local-manifest.json`。
- 独立审查 `review_pr11_integration` 使用Astra low，新上下文、只读，按接口检查指令／装备查询／提交刷新／反馈／回顾域；反馈修复与测试更新定点复核无新增阻断，不重复运行相同门禁。

## 未验证与合并边界

- 未跑规则与界面的normal_play、其余33个界面模块、人工试玩、安卓真机、打包、实际反馈收件与服务部署、性能基准。
- PR作者登记的interface偶发失败本轮未复现，不能据一次通过宣称消除；TERMS可变表、非手牌／候选瓦片的独立拖放控件、反馈动画数值格式等作者已登记边界未扩域重构。
- 合并或推送前须再次核对远端main与PR头部；两者变化后按受影响范围复验。原主检出的在途修改已包含在准备分支，实际切换时须先保护它们，不能硬重置覆盖。


## 2026-09-28 后续合入授权与版本

用户随后授权合入main并推送，数字版本保持0.18.2、后缀加`.fix`。本批补齐版本元数据、两平台版本解析与版本说明；增量门禁`20260928T124740514-40908`规则289、窗口192、文档引用2492全部通过，版本解析32项通过。记录见验证册同日「合并发布标识」条目。未扩大到打包、标签、Release或反馈部署。合入前原主检出八文件再次逐一核对并保留stash备份，准备分支已包含它们的整合结果。
