# AGENTS.md

## 项目是什么

- 本仓当前只维护 `spire-godot/`（《紧缚尖塔》，Godot 塔路与卡牌游戏）。
  模块边界与目录职责见 `docs/project-map.md`。

- 网页项目《魔法少女又白给了》是同级另一仓库 `mahou-shoujo-escape`，不在本仓。
  本仓不引用其源码或构建流程；其数值与流程不适用于 Godot，
  不据其界面反向修改本仓规则定义。

- 游戏面向成人；所有登场角色均为成年人。
  素材与文案按任务授权及资源许可处理。

- 当前工作区以实际仓库位置为准。
  不使用历史文档中的旧绝对路径定位源码。

- 命令与操作流程见 `.zcode/skills/repo-ops/SKILL.md`；打包与发布先读 `docs/packaging.md`。

- `docs/agent-guide.md` 索引背景与历史。
  只读取当前任务相关的文档和章节。

- 历史记录用于追溯，不是新的待办。
  不把归档中的旧约束恢复成当前要求。

- 规则集中在根 AGENTS.md；将来加入第二个模块时再按模块拆分。

## 常用命令

命令与操作流程不在本文件：见 `.zcode/skills/repo-ops/SKILL.md`
（根级 git 检查、`spire-godot` 分类门禁与语义、内容包校验、引擎定位、打包发布）。

## 必须遵守的规则

- 最新明确用户要求优先于旧设计记录。
  冲突时先核对文档日期及所属模块。

- 已确认规则优先于旧 Demo 行为。
  不根据旧界面反向修改规则定义。

- 开始修改前检查已有差异。
  用户和其他任务的在途修改必须保留。

- 先读相关规则、实现及现有测试。
  修改范围以当前任务及其必要依赖为限。

- 验证结论必须对应实际运行的源码。
  报告测试范围、失败和未验证部分。

- 长背景、数值修订和执行结果写入 docs。
  AGENTS.md 不追加聊天流水或版本日志。

- 指引只写长期规范与索引；细节、操作与历史拆到 docs/ 与项目 skill。

## 禁区

- 不复制第二套 Demo 或规则内核。
  不从历史部署归档恢复当前源码。

- 不绕过正式候选修正界面结果。
  不由组件直接修改资源、装备或回合。

- 不为了展示效果伪造装备或状态。
  不把占位入口宣称为已实现功能。

- 不从叙事、颜色或标签猜规则事实。
  不用本地化后的文本识别对象。

- 不删除有效失败案例换取绿灯。
  过期或重复测试须依据覆盖关系处理。

- 不把少量采样称为完整回归。
  不把桌面资源探针称为安卓真机验收。

- 不提交缓存、用户存档和临时日志。
  构建目录及依赖目录不得手工修补。

- 不把密钥、签名秘密或令牌写入仓库。
  日志与归档也必须遵守此限制。

- 不强推或覆盖远端提交。
  有歧义的冲突、权限问题先说明阻碍。

- 不把源码同步等同于打包或发布。
  安装包、标签和 Release 遵循明确要求。

- Godot 大版本完成且门禁通过后自动推送。
  先核对远端、分支与范围，只提交已完成内容。

- 小修改不触发大版本自动提交。
  不为推送提前宣布里程碑完成。

## 验证方式

- 格式与导入约束交给已有检查工具。
  代码风格保持现状，不做无关批量格式化。

- 新规则覆盖正例、最近反例与边界。
  有支付、版本或随机变化时检查回滚。

- 跨系统变化覆盖真实交互路径。
  UI 出现和静态文本匹配不能代替行为验证。

- 纯文档修改验证链接、编码和体积。
  不为说明文件重跑整个游戏回归。

- 测试通过后只因新修改或新问题重跑。
  不无故扩大范围或重复已完成的检查。

- 交付前复查本次差异及验证结果。
  明确是否只改源码、是否已打包或发布。

## 模块规则（spire-godot/）

以下是模块的文档索引、项目 skill 索引与代码规范；架构、界面文案素材、验证发布的细则在同目录技能里。

### 文档入口

| 任务 | 按需阅读 |
| --- | --- |
| 玩法、场次、奖励、资源 | docs/game-design.md |
| 装备、覆盖、链接、解除 | docs/equipment-design.md |
| 卡牌与内容扩展 | docs/card-framework.md、docs/content-extension.md |
| 生成与模板 | docs/content-generation.md、docs/content-templates.md |
| 角色2 | docs/character-two.md |
| 监狱及出狱 | docs/prison-release.md、docs/prison-reinforcements.md |
| 平板锁 | docs/cursed-plate-lock.md |
| 界面拆分与装备详情 | docs/ui-scene-refresh.md、docs/release-interface.md |
| 输入到落地的提交与刷新 | docs/response-pipeline.md |
| 候选局部筛查与依赖声明 | docs/candidate-delta.md |
| 前端重构问题清单（无方案，交原作者） | docs/refactor-direction.md |
| 装备只读查询 | docs/equipment-query-seam.md |
| 玩家可见文案的收口与按需 | docs/ondemand-copy.md |
| 事件系统结构 | docs/event-structure.md |
| 事件定义形态与管线统一（现行） | docs/event-pipeline-unification.md |
| 事件管线依赖约束 | docs/event-pipeline-dependency-spec.md |
| 状态迁移管线（单写入者） | docs/transition-pipeline.md |
| 每次点击的检查链（冻结与影响） | docs/per-click-checks.md |
| 检查索引与失败隔离（路由） | docs/check-routing.md |
| 文案与本地化 | docs/action-copy-guide.md、docs/localization.md |
| 美术来源与差分 | spire-godot/assets/art/ART-NOTES.md、spire-godot/assets/vendor/CREDITS.md |
| 验证结果 | docs/verification.md |
| 打包与反馈服务 | docs/packaging.md、docs/feedback-deployment.md |
| 历史决策追溯 | docs/history/agent-contract-2026-09-14.md |

历史归档包含已被推翻的记录；先搜索主题再读取相关段落，
按用户最终要求和最新专题文档判断，不能整份视为现行指令。

### 项目 skill 索引

细节规范与操作按类拆到本目录技能，改动前按需读取：

- `repo-ops`：命令与操作流程（检查门禁及语义、内容包校验、引擎定位、打包发布）。
- `spire-architecture`：架构边界与数据流（提交入口、只读投影、候选与索引、随机、只读复用、装备事务、分层）。
- `spire-ui-content`：界面、文案、本地化、立绘与素材。
- `spire-validation-release`：验证口径、测试夹具隔离、自动推送与打包发布边界。

### 代码规范

以下为本模块现状约定，检查工具覆盖不到，改动时人工遵守：

- GDScript 缩进是**每层一个空格**（不是四空格）；不重排函数、不批量格式化未触及的代码。
- 命名：变量与函数 snake_case，常量与 preload 类 PascalCase；判定只用稳定 ID（template/type/id）。
- 失败用返回原因字符串表达（空串=成功）或 `{ok,error}` 字典，不用异常；早退守卫写在前面。
- 注释写不变量、原因与边界（英文）；玩家可见文案与 docs 用中文。
- 新增文件须有明确职责边界与依据；大文件按职责拆，不按行数硬拆。
- 测试断言消息用英文并写明域；优先复用 `tests/` 既有夹具与真实输入助手。
