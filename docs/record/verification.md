# 验证记录（现行卷 · 2026-09-14 及以后）

> 路径说明：本卷正文保留撰写当时的文件路径（旧 `docs/<名>.md` 现按类归入 `docs/spec|design|guide|record|history/`）；需要定位时按文件名搜索。


- 性质：记录类，只追加；本卷即现行口径。归档卷：`verification-2026-09-13.md`（2026-09-11～09-13，190 条）、
  `verification-2026-09-12-and-earlier.md`（2026-09-07～09-10，203 条）。
- 本卷内容：84 条条目 + 卷首 3 个现行口径节。条目 = 原文 2026-09-17～14 标题条目 79 条
  + 原文缺标题的 09-17 条目 2 条（标题按正文重建，正文逐字保留）+ 作者侧 `origin/main`（v0.17.1 提交）新增 3 条。
- 现行口径节：`检查入口`／`覆盖范围`／`当前边界` 是无日期小节，属检查入口、覆盖范围与边界的现行说明，
  不随归档卷迁出；`覆盖范围` 正文含 2026-09-06 的存档批次结果，同样留在本卷。
- 条目格式：`## <日期> <标题>（角色）`。标题与正文逐字保留（仅把标题内的日期统一到标题前）；
  角色沿用原文署名，原文未署角色者不补。「域」行原文已有者保留，缺者按正文中的代码路径、
  契约文档名与主题词机械提取（无路径者为主题词归类），不新增正文事实。
- 口径与指针（不改写原文）：B3 条目存在「本批未完成 → 仍未完成 → B3 完成」更正链，三条原文均保留；
  `2026-09-17 状态迁移管线收束` 内的「截断／补跑」口径已由正文 superseded 标记指向检查路由契约；
  「提交面去重」方向经人裁定不实施，契约在 `docs/history/submit-dedup-2026-09-17.md`；
  作者侧 `修复18条基线失败` 与原文登记的既有红项并存，两侧原文均保留。
- 链接对应：作者侧条目正文中的 `pr2-integration-review.md` 即 `docs/history/pr2-integration-review-2026-09-17.md`；
  正文中的 `verification.md` 自指即本文件。
- 规范类结论（规则、接口与检查口径的可执行定义）以 `docs/spec/*` 为准，本卷只记录与链接，不复制规范正文。

## 检查入口

**现行口径**（非历史条目）。

- 规则：`Godot --headless --path . --script res://tests/test_game.gd`
- 界面与完整流程：`Godot --path . --script res://tests/ui_smoke.gd`
- Windows：`tools/check.ps1`，加 `-UI` 包含窗口内操作与截图。
- 窗口专项：`tools/check.ps1 -UIOnly -UISuite rewards`；可选equipment_complete、pressure、guard、prison、tower_progression、events、rewards，并可逗号组合。从同一窗口入口运行既有模块、每项先重置、按注册顺序去重；默认all保留原完整流程，未知套件拒绝。不复制测试，不把部分专项统计成完整窗口结果。
- 相关规则：`tools/check.ps1 -Suite equipment_complete`，按统一注册表补齐core/equipment/links/composites依赖、去重运行。可逗号指定多个套件，默认all；每套件记录耗时。规则通过后的纯显示修改用同一入口的`-UIOnly`，保持错误日志与完成标记检查。

## 覆盖范围

**现行口径**（非历史条目）。

2026-09-06存档批次最终结果：`tools/check.ps1 -Suite persistence -UI -UISuite persistence`通过2285项规则断言、33项存档窗口专项，无引擎错误。14个规则套件按依赖去重运行，其中persistence293，其余继承rewards及传递依赖1991项，另有选择断言1项。此前本批完整窗口`-UIOnly`通过552项断言；最后补充运行期间不兼容文件保护后，重跑完整关联规则及存档窗口专项，不把专项计作新的完整窗口结果。

存档案例覆盖全部33项实际练习与64位大种子；保存→恢复→正式下一步和不中断运行逐项对照，资源、随机、牌堆与日志均不变化，只有操作版本刷新。覆盖战斗、奖励、整备、地图、行进、休息、整理道具、事件选择/钥匙/结果、多段挣扎与双重开锁中途、已保留一张牌、待发放遗物、过载、入狱结果、牢房、巡视到达/结果/完成、反抗战斗、五级结束与练习完成。练习实际开门逃回塔底后存档身份仍为practice，写入不覆盖tower。

失败案例检查缺字段、未知阶段/卡牌、牌堆不一致、损坏随机/意图/地图引用、重复编号风险、非有限数、错误格式、损坏JSON和校验和；失败恢复保留当前状态。真实文件案例检查首次保存、连续替换、上次备份、主文件损坏回退、后续修复、不同档位隔离、文件夹不可写时保留原文件；不兼容主文件不自动回退，也不能在游戏运行期间被普通自动保存覆盖，只有明确新局可以替换。

初次完整对照发现文本浮点往返与Godot StringName转普通字符串导致差异。当前整数使用十进制类型标记、浮点保存原始64位、StringName保留名称类型；全部真实装备/事件往返及后续动作对照已通过，没有用近似比较掩盖状态差异。恢复不运行状态清理、回合开始或随机生成，无法继续的损坏多段选择被拒绝。

窗口专项实际启动新场景读取自动保存，验证成功操作写入而翻面/查看/旧版本拒绝不写；塔路/练习按钮、缺档禁用原因、练习分档、多段拖牌恢复不重复扣费、事件隐藏结果保留与结算后不能重选、备份回退提示、未知版本暂停自动保存、明确重开后恢复写入。截图`ui-56-save-menu.png`、`ui-57-resumed-card.png`、`ui-58-save-recovery.png`、`ui-59-save-incompatible.png`已查看，界面内容在视口内。测试在独立build临时目录执行，基础窗口挂载前禁用文件保存，未访问玩家存档。

架构：Game继续持有唯一游戏状态，snapshot只作结构保护、复用现有注册表及规则校验；save_store统一无损编码、格式和文件替换。UI仅在已有成功提交入口调用保存，读档清理界面焦点并派发完整恢复。状态新增save_slot用于固定开局归属，不根据逃狱后的practice标志猜测档位。未来已有字段含义变化需显式迁移/版本升级；本批是首个格式，无历史版本迁移承诺。

2026-09-06首批奖励补全：规则入口`tools/check.ps1 -Suite rewards -UI`通过1992项断言，包含全部13个相关套件且各执行一次：rewards162、events204、core301、equipment108、links37、composites83、equipment_complete229、prison153、guard120、pressure105、enemies160、tower184、tower_progression145，另有选择断言1项。同轮完整窗口通过520项断言，无引擎错误。随后仅修订第二段开锁说明，完整窗口复查因最小化暂停并打断鼠标拖放，该轮明确作废；恢复干净窗口后最终执行`tools/check.ps1 -UIOnly -UISuite equipment_complete,pressure,rewards`，34项装备、28项压力、27项奖励共89项窗口专项全部通过，无引擎错误，模块耗时合计约11秒。规则行为未因这次显示与检查入口修订改变。

本批完成找准松处、扯开缺口、接连挣动、逐层抽离、双重解锁，以及断缚护腕、游丝指环、回身缎带、余烬晶石。规则覆盖32种子随机奖励无重复/可复现/独立域、8张牌全部可抽取、只读预览；五种自由效果的费用与魔法身体条件、先保留后抽牌与两张保留不重复延期；滑脱标记实际加伤/免疫消耗/回合及提前离房清理；直接解除返能量；两段每次重新计算强制目标与新外层、并列选择、只支付一次、旧版本拒绝、选择期间不能插入其他行动、无目标不转自由效果；整张牌后一次压力增长与立即过载。

遗物检查直接归零与连带移除区分、每玩家回合刷新、实际二档到一档抽牌与纯降档/直接移除排除；真实飞踢落地后躺到坐的零费边界与机会消耗；实际魔力费用减免后的50%返还、每战首次限制、自由面不占机会、非战斗不触发。补充双重解锁先牢门后装备/先装备后牢门、储备术式只消耗一次、可停止第二把且不退费、真实收押保留全部遗物并清临时状态。非法多段状态在提交前原子拒绝。

窗口沿既有入口新增`tests/reward_ui_cases.gd`，共用原生拖牌、实际候选按钮、目标框滚动与截图助手。验证2费显示、拖向第一件后真实选择并列第二件、自由面直接拖到玩家保留两张、两把实际装备锁只耗一次魔力、单手受限时自由魔法仍禁用、新牌奖励进入卡组、完整遗物列表可滚动到最后一件。截图`ui-52-chain-targets.png`至`ui-55-relics-scrolled.png`已查看；最初测试误传装备ID而非候选ID，门禁正确报失败，修正后重跑通过。末次截图发现第二段开锁说明重复提示下一把，已修正为本次结束并补窗口断言，最终奖励专项通过。

整合：`data/card_rules.gd`集中机械定义及普通／罕见／稀有／完整奖励池；`core/card_effects.gd`共用旧牌和新牌的目标、费用、保留及逐段处理；`core/relic_effects.gd`统一直接触发、次数与行动后发放。只读投影/界面不增加状态写入口，卡牌和遗物均继续沿`dispatch`提交。事件奖励池已按真实稀有度拆分，文档及扩展接口同步。暂定数值为滑脱准备＋3、重挣扎9、两段各4、晶石返还50%；不表示最终平衡完成。

2026-09-06首批事件与扩展接口历史结果：`tools/check.ps1 -Suite events -UI`通过1826项规则断言、494项窗口断言，无引擎错误。相关依赖覆盖当前全部12个规则套件，每套件只执行一次：events200、core301、equipment108、links37、composites83、equipment_complete229、prison153、guard120、pressure105、enemies160、tower184、tower_progression145，另有选择断言1项。

本批新增`tests/event_cases.gd`和`tests/event_ui_cases.gd`，沿既有入口检查。规则覆盖：12种子冻结完整方案、独立事件随机域、预览不写状态/编号/随机、不向UI泄露有效钥匙；三种裁缝交易真实普通/复合安装与组件锁、加固2/10→8/10、无目标中级回退、选牌与跳过不退代价；拒绝费不足/为零仍能结束；三枚钥匙分别用实际种子覆盖全部成功/失败、锁优先新目标、眼罩/皮带真实加固、不可重复领奖、满眼部容量拒绝完整赌局。检查未知效果、无效状态和目标不合法不留下部分装备或奖励。

奖励覆盖：慌乱无主动候选、虚无先于保留、卡组不删除、下一战和完整巡视恢复；开锁针零能量真实开锁、不改耐久、消耗次数、不能安装、手腕限制及姿态接触；开牢门仍检查逃离速度，逃出保留工具次数和遗物。折叠工具匣增加实际容量，整备沙漏延长实际战后整备；同遗物拒绝重复，池耗尽不提供无法发放的遗物方案。事件不触发回魔或战后奖励，不消耗跨战增益，离房仍检查容量。

窗口覆盖：正式地图两事件图标、进入后查看地图不重抽、真实点击交易/三选一/跳过/离房，钥匙阶段只有三个选项且无道具操作；领取遗物显示已生效说明，实际中奖开锁针在休息房打开指定锁并扣次数。已查看`ui-46-tailor-choices.png`至`ui-51-lockpick-tool.png`：选项代价、锁的变化、事件奖励与遗物说明完整。窗口长路线也逐房经过事件，通过正式拒绝和离房完成；新事件占用原战斗分支位置，因此路线最低数量按战斗＋已完成事件合计检查，战斗奖励仍逐场一一对应。

整合：警卫与事件共用`equipment_offers`及真实实例工厂；复合生成组合回到结构数据，敌人将行为/外观/装备池拆成模板字段；事件配置使用配方或显式原子效果，新增内容不得再复制阶段流程。遗物与卡牌特性通过注册表参与真实规则；扩展位置和约束在`docs/content-extension.md`。该历史批次仅用过渡牌池，五张奖励牌和四件遗物在后续批次补齐；没有新增升级、专属首领行为或完成最终数值平衡。

2026-09-06塔路精英与塔顶批次历史结果：导入通过，全部11个规则套件共1622项断言通过；修正窗口测试对并拢飞踢伤害及躺姿代价的预期后，`tools/check.ps1 -UIOnly`通过479项窗口断言，无引擎错误。规则分项：core297、equipment108、links37、composites83、equipment_complete229、prison153、guard120、pressure105、enemies160、tower184、tower_progression145，另有套件选择断言1项。

新增`tests/tower_progression_cases.gd`与`tests/tower_progression_ui_cases.gd`，共用原检查入口。覆盖12种子下第8/12层可选精英及实际绕行连接、第16层双警卫与唯一出口连接；实际旅途保留装备和资源，两名70生命警卫分别受击，只击倒一名不能领奖；奖励、整备和容量整理完成前出口不开放，伪造抵达出口的移动完整回滚。精英与塔顶均沿正式收押、探索、坐姿踢开通风口、逃离和重建塔路流程检查，安全等级保留，新塔顶使用新敌人实例。

窗口验证实际地图查看不跳房、拖踢击到指定警卫、携带腿部装备时并拢飞踢造成10伤害并打断且变躺姿、双警卫失败仅入狱一次、正式塔路重开入口、领取奖励和整备后前往出口。`ui-41-elite-summit-map.png`至`ui-45-summit-cleared.png`已实际查看：地图图例、双敌意图、失败分支与通关文字完整。初次窗口测试把携带腿部拘束的踢击误按普通6伤害断言，修正为真实10伤害及姿态代价；修正过程中的测试字段笔误由错误日志门禁拦截，最终窗口重跑通过。

本批统一`room_entry_reason`供地图与正式前进读取；`-Suite tower_progression`自动合并监狱、警卫、塔路及传递依赖，各套件只执行一次。长路线规则与窗口复用`tests/route_driver.gd`，仅在流程测试中降低警卫生命，后续攻击、奖励和整备仍使用正式操作。定点窗口夹具从真实相邻休息房开始；原长路线检查仍逐房前进。这些通过结果不表示70生命双警卫与当前牌池的最终难度已经平衡。

监狱批次历史最终结果：`tools/check.ps1 -Suite prison -UI`通过1463项规则断言和423项窗口断言，无引擎错误。相关依赖覆盖当前全部10个规则套件：core283、equipment108、links37、composites83、equipment_complete229、prison153、guard120、pressure105、enemies160、tower184，另有选择断言1项。最终左右分栏牢房与返塔地图截图已再次查看。

2026-09-06监狱批次：新增`tests/prison_cases.gd`与`tests/prison_ui_cases.gd`，沿原套件/窗口主入口执行。`-Suite prison`合并guard/tower及所有实际依赖，每套件一次；初次完整`-Import -UI`通过1444项规则、423项窗口断言。随后优化牢房左右分栏，并补充高安全等级、手势条件和反抗整备超容量检查，最终结果见下方。

规则覆盖：真实收押进入牢房、普通抽弃补能、独立有限发现随机、只读投影不泄露未发现顺序；探索费用按真实区域等级、零费发现不可重复刷取；倒计时精确到巡视，降低耐久不等于缺装，组件编号丢失可被发现；清单齐全保留随身工具、没收已安装工具；违规收紧及按安全等级追加真实装备、没收所有工具、不恢复通风口。检查完成才恢复消耗牌至弃堆、不能重复确认。三个巡视节点都可反抗且不提前恢复消耗区；胜利发专用钥匙、一次正常奖励/恢复、整备容量整理后回牢房；失败保留装备并只增加一次安全等级。开锁使用真实卡牌、手势条件、压力魔力费用和储备，旧版本/姿态变化不能绕过出口速度。坐姿并腿踢击打开通风口，每玩家回合一次，扣能量并消费对应蓄力；出口检查携带容量。逃离保留资源/装备/卡组/增益/安全等级，遗留墙面工具，重建路线而非复刷旧房，下场才正常补能。最后一回合过载只到达一次巡视、下一玩家回合只扣一次惩罚，回合中过载关闭探索和出口。非法发现记录导致回合、牌堆、资源和日志完整回滚。

窗口覆盖：真实练习菜单，测试夹具仅把警卫的已公开意图推进至收押，随后实际结束回合与进入牢房；点击探索获得两件有限工具和通风口，安装工具沿原道具入口，逐回合进入巡视，检查后真实没收墙面工具，继续启动下一巡视钟。坐姿三次踢击后经独立出口返回新塔底，地图实际显示可达的新入口。原生拖牌确认自由面不能开门、拘束面消耗实际“术式解锁”和魔力后打开牢门，并沿速度合格路线逃出。基础三姿态与原身体装备拖放继续保留。

截图`ui-37-prison-cell.png`、`ui-38-prison-inspection.png`、`ui-39-prison-vent.png`、`ui-40-prison-return.png`已查看。牢房最初纵向长列表已改为探索/通风口与牢门左右分栏；返塔地图使用独立塔底节点，不与首层重叠，也不再显示当前房间不可达的矛盾提示。五级只完成终局流程，不把未生成的专用固定套装计作通过；当时特殊道具路线和塔路精英节点尚未接入；本批已接入塔路精英。

2026-09-06警卫批次历史检查：`tools/check.ps1 -Import -UI`通过，导入无错误，规则1310项断言、窗口381项断言通过。规则分项：core283、equipment108、links37、composites83、equipment_complete229、guard120、pressure105、enemies160、tower184，另有套件选择断言1项。相关入口`-Suite guard`已通过1126项断言，自动合并依赖，每套件只执行一次；最后完整回归同时确认原塔路与普通敌人流程。

警卫规则覆盖：12个种子的意图/普通与复合工厂合法性、同种子复现、工厂探测不改状态或随机；公开的额外操作不递归、先加固再上锁、原目标失效落空；蓄力与先手双操作、普通回合不重复执行、打断延后；第10回合完成后11准备/12执行，双区域满级触发锁定、解除不取消、不改写当前意图；准备和执行分别打断、击倒取消、躺姿仍按既定先后手执行收押；双警卫首个收押立即终止整场且只增加一次安全等级，击倒两者才发一次奖励。入狱验证原装备耐久/锁/组件/链接及魔力/压力/卡组保留、随身与安装工具没收、增益/惩罚清理、实际新增普通件和链接、检查基准一致、无战后恢复奖励、重复回调与旧行动拒绝。非法附加操作引起整个正式提交回滚，资源和日志一并恢复。案例集中在`tests/guard_cases.gd`，不复制通用规则测试。

警卫窗口覆盖：真实菜单启动单/双警卫，拖踢击到指定实例只影响该敌人；逐回合经过打断、连动、收押进入真实结果，查看保留/新增装备不写状态；该批结果仅到入狱；本次已改为通过正式入口继续牢房。`ui-34-guard-intent.png`、`ui-35-capture-result.png`、`ui-36-double-guard.png`已实际查看，意图与收押提示完整，双敌目标分离。警卫仍为临时轮廓，非最终人物素材。

压力批次历史最终界面复核：`tools/check.ps1 -UIOnly`通过339项断言，无引擎错误；当时保留上一轮1000项相关规则日志。法术牌当前费用和过载空手牌提示已随截图复核。

2026-09-06压力批次：首次`-Import -UI`完整回归通过1183项规则断言、338项窗口断言。随后补充法术牌实时费用与无来源时的预览快速返回，以`-Suite pressure -UI`通过1000项相关规则断言和338项窗口断言；相关套件为core283、equipment108、links37、composites83、equipment_complete223、pressure105、enemies160，另有选择断言1项。tower184已在本批完整回归通过，后续修改未触及塔路。过载空手牌文案另用UIOnly复核，最终结果见下方。

新增压力覆盖：0/40/80分档与单调魔力曲线、加费后再扣储备、实时法术牌费用、免费魔法不加费且休息房仍禁自由效果；稳定心神费用/版本/回滚；来源时机和装备移除停止；行动后增长、立即过载、余数、多次累计、魔力归零下限、禁用全部剩余动作；后续回合惩罚只消费一次并与能量增益抵扣；先后手下的两名敌人顺序、打断一并延后、不取消第二名敌人、不重复前一敌人阶段；战斗结束/奖励/整备/练习退出只继承压力；移动来源保留、房间来源停止；非法来源使整个提交回滚。核心案例为`tests/pressure_cases.gd`，沿原依赖注册表合并运行。

压力窗口：真实滚动菜单启动两种练习，压力按钮显示实际来源/时机/魔力倍率，稳定心神扣费；两次原生拖牌触发过载、弹出结果、只保留继续入口；继续后准确更新休息计数和能量；敌人意图显示威压65，两个实际行动累计过载2次；完成战斗、选奖励进入整备保留压力而无惩罚。截图`ui-31-pressure-sources.png`、`ui-32-overload.png`、`ui-33-enemy-pressure.png`已查看。看到空手牌旧提示与过载冲突后，已修改为跳过剩余行动并增加窗口断言。

- 初始10牌、抽弃牌守恒、保留牌到期、奖励加牌、三回合整备和跨战继承。
- 紧度边界、同比降档、锁减半、单件无堆叠惩罚、分层与同层目标选择。
- 普通滑脱免疫时仍付费、眼部无挣扎不能触发自由分支、魔法身体条件及资源折扣。
- 姿态相邻切换、借墙结束玩家阶段、先后手只在回合开始判定。
- 冻结意图、打断不重抽、连续打断限制、击倒与附着离场各自结束战斗。
- 版本过期、伪造或不可用行动拒绝且不改状态；预览不推进随机；固定种子复现。
- 实际窗口按钮完成选牌、目标选择、出牌、遭遇、奖励、整备、下一场与重开。

2026-09-06装备补全历史记录：Godot 4.7.2。该批通过`tools/check.ps1 -Import -UI`：导入无错误，规则1073项断言、界面311项断言通过。窗口检查覆盖1600×900与默认1440×810。规则分项为core283、equipment108、links37、composites83、equipment_complete217、enemies160、tower184，另有套件选择断言1项。全规则约6.6秒，各套件只执行一次；未缩减既有规则覆盖。

本批修正了底栏溢出、同部位目标名称混淆、蓄力在体术衰减前计入基础伤害，以及浮游锁在蓄力时确定最终目标。确认目标提前解除后，锁的最终附着落空，不改选新目标。

新增覆盖：沿不同分支均可完成长塔路并抵达出口；禁止跳房与重复领奖；移动耗时按姿态和实际固定部位计算；移动期间牌堆、资源、玩家回合增益与随机游标不变。

界面测试使用真实鼠标事件验证右键翻面和Godot原生拖放：自由面生效、错误牌面拒绝、拖离目标取消、两件装备分别展开、拖入第二框只移除第二件，以及三档免疫滑脱仍扣除卡牌和费用。

新增角色拖放：固定攻击以实际落点敌人为目标，法术费用只扣一次；攻击不能作用玩家，已离场敌人不接收，挣脱牌不能作用敌人。姿态拖到玩家使用正常费用和回合规则。拘束面拖到玩家后先选部位，再选具体装备；选择前无消耗，右键翻面撤销原选择。自由面点击或拖到玩家直接生效；魔法身体条件不满足、能量不足均不扣资源。截图补充 `build/ui-09-actor-actions.png`、`build/ui-10-player-picker.png`。

休息房覆盖：真实塔路进入与离开、5回合耗尽、提前离开、每房服务仅一次、无自动回魔与消耗牌恢复、禁止自由效果但允许拘束分支的附加收益；挂钩3次、同比降档、三档紧度绕过、结构及外层限制和姿态范围。

工具覆盖：手指与脚趾安装、使用无能量费用、只切外露兼容材质、锁不减伤、次数共享与耗尽移除、携带容量减少、超载整理、随身次数跨房保留与安装工具离房遗失。窗口操作覆盖领取、打开道具面板、安装到墙脚、改变姿态和两次实际切割。截图：`build/ui-11-rest-room.png`、`build/ui-12-hook-targets.png`、`build/ui-13-field-tool.png`。

新版截图：`build/ui-01-battle.png`、`ui-02-free-drag.png`、`ui-03-two-targets.png`、`ui-04-reward.png`、`ui-05-map.png`、`ui-06-travel.png`、`ui-07-cleared.png`、`ui-08-default-window.png`。较早无ui前缀的截图仅为历史验证产物。

## 当前边界

**现行口径**（非历史条目）。

架构整合验证：显示投影不推进随机或修改状态，嵌套显示数据不引用可写的运行状态；篡改显示中的伤害或费用不能覆盖提交时的正式判定。战斗、整备、休息三种真实流程下，下回合能量只消费一次，抽弃牌守恒，魔力不额外恢复，战斗计数与非战斗倒计时分别推进。

界面索引验证：实际敌人与不存在目标分离、空行动组保持为空；打开面板不推进规则，外部状态推进后旧候选与旧拖放均拒绝且不消耗资源，失败提交也刷新显示和索引。原有125项界面断言包含完整战斗、路线、休息房和工具操作。

检查入口新增退出码、错误日志和完成标记三重检查。实测临时注入运行时错误后，Godot仍打印`PASS: 261 assertions`，入口正确判失败；已恢复原测试文件并重新跑通过。故障注入仅用于验证检查入口，未留在游戏或测试源码中。最新日志为`build/check-rules.log`与`build/check-ui.log`。

模板批次覆盖：四类材质的生成与实际解除、初/中级和紧度独立、材质版本随意图冻结、独立随机序列、错误部位/锁定/材质版本/耐久的原子拒绝、同部位混合容量与外层追加、加固与滑脱共用既有规则、胶带不继承旧粘性封锁、锁选择和执行时的双重复核、石片与锯条对塑料的实际兼容差异。专项案例在`tests/equipment_cases.gd`，由原规则入口统一运行。

装备练习通过真实界面入口启动：鼠标点击重开面板、编号合法性、四材质显示、明确的徒手/切割禁用原因、锯条两次切断扎带、原生拖牌滑脱胶带、挂钩解除绳索、练习结束及回到塔路。练习沿用正式候选和提交，5回合到期不产生战斗奖励或塔路进度。截图：`build/ui-14-equipment-practice.png`、`build/ui-15-material-tools.png`、`build/ui-16-practice-menu.png`。

敌人批次覆盖：绳索四阶段与第二回合两类分支；眼罩两回合蓄力、规格冻结、初/中级、各阶段打断、提前击倒、公开前后眼部容量改变的施加落空；同种多敌的独立生命、行动和来源，跨房ID不复用，全部离场仅奖励一次。眼部受阻立即显示且不擅自隐藏敌人意图。弱池开局抽取与只读预览可复现。专项案例在`tests/enemy_cases.gd`，由规则入口统一运行。

地图覆盖：已走连线严格对应真实移动记录；未选分支、正在移动与未来路线分别投影；房间图标查看不改变状态、不产生跳房候选，滚动位置随查看保留。窗口中实际点击未来节点，进入绳索＋眼罩战斗，并拖放踢击到第二只绳索，确认只有落点目标受伤与延后。战斗内查看地图不会叠出结束回合按钮。截图：`build/ui-17-rope-blindfold.png`、`build/ui-18-double-rope.png`、`build/ui-19-spire-map.png`。

长塔路覆盖：30个种子的节点唯一、向上连接、全节点可达、无非出口死路、生成段分支不交叉；同种子复现与不同种子变化；第7/11/15层休息点；预览不修改图或随机游标；两条完整长路线每战奖励一次。案例在`tests/tower_cases.gd`。窗口通过真实按钮完成长塔路，切换整塔总览、定位当前房间并维持不可跳房规则。整塔截图为`build/ui-20-full-tower.png`。

人物美术覆盖：从正式姿态动作依次切换站/坐/躺，显示正确图集区域并保持比例与地面对齐；绘制与动画不改变状态或随机游标；窗口像素检查确认绿底消失且粉色人物仍可见，原拖牌目标继续正常工作。当前使用用户本轮指定的三姿态附件，躺姿区域已扩展以完整容纳头发。截图：`build/ui-21-hero-stand.png`、`build/ui-21-hero-sit.png`、`build/ui-21-hero-lie.png`。绿底透明由专用画材在运行时完成，保留源图。

普通链接覆盖：两端引用同一共享耐久，显示快照无可写引用；同对逆序重复、失效目标、跨区域连接与普通施加入口拒绝；独立紧度伤害、蓄力只消耗一次、旧拖放原子拒绝、无滑脱与上锁；方向声明只阻止指定装备的滑脱。徒手接触检查任一外露且可达连接处，不把连接装备的锁或材质误当链接自身限制；工具固定伤害、次数与零能量费用；移除链接保留装备，移除必要装备清理链接，新装备不重接；战后、整备和房间移动保留连接。非法链接导致回合事务完整回滚。专项案例在`tests/link_cases.gd`。

链接窗口覆盖：真实点击独立练习入口、两部位显示连接标记、原生拖牌选择共享链接目标且仅结算一次、坐下后切割并同步更新两处详情。截图：`build/ui-22-link-targets.png`、`build/ui-23-link-released.png`。链接练习继续使用正式5回合规则与两件切割工具。

单手套覆盖：短/长与直/交叉四种组合的原子创建、覆盖与能力差分、组件共享目标和只读投影、容量与内外层、关闭手指后的施法/握持/安装条件、组件独立锁、肩带紧度上限、结构滑脱/挂钩前置、首次肩带解除不触发同次脱下、跨三档伤害不倒推资格、切割/滑脱不冒用挣扎捷径、外层阻挡、套体破坏保留独立内外层、敌人组件上锁、跨战与跨房保持、错误覆盖原子回滚。新增83项断言集中于`tests/composite_cases.gd`，通用材质、链接与回合案例不复制。

单手套窗口覆盖：真实菜单启动短型/长型，拖牌至手腕或小臂后选肩带和套体；两次滑脱去除一侧直肩带，再用一次挣扎按预览解除整件并更新资源/容量。长型验证交叉肩带共享耐久、挂钩前置、关闭手指后的切割拒绝、脚趾安装与躺姿固定工具切割。截图：`build/ui-24-glove-components.png`、`build/ui-25-glove-release-preview.png`、`build/ui-26-long-glove-tool.png`。目标摘要与完整详情分开，禁用原因不重复堆放。

检查整合实测：composites选项自动执行core/equipment/links/composites，各套件仅一次；完整规则约5秒（按输出分项耗时），未削减既有断言。未知套件misspelled实际返回非零且不生成成功标记，日志为`build/check-suite-rejection.log`，其中错误属于这次预期拒绝。窗口共用真实练习启动和滚动至指定拖放目标助手；UIOnly只重跑窗口流程，保留此前规则日志。

装备补全覆盖：29个练习的真实生成数量与配置一致，预览不写状态；普通模板全部合法等级；四种单腿套破坏套体后的外带ID/耐久/锁/链接保留、能力恢复与容量预留、长短叠层和超容量原子拒绝；拘束衣双前置、无滑脱袖部连接、已安装工具处理与整件清理；左右独立包裹的手势/握持/卡牌自由分支和上肢容量单次扣减；眼口胶带、马具逐眼罩紧度比较、相等允许、母件/附属件分别解除、马具独立锁减伤；十二种躯干固定的手持/徒手范围；高级复合基础耐久且无未定义魔法效果。损坏组件结构后的失败回合完整回滚。新增217项断言集中在`tests/equipment_complete_cases.gd`。

装备窗口补全：共用助手滚动到菜单下方并真实点击；工具三次切断单腿套套体后，链接仍引用遗留外带，随后原生拖牌到该外带准确扣耐久；自由的另一只手切开单侧包裹；拘束衣禁用原因可见，并用脚趾安装工具、切换坐/躺、切割真实袖部连接；马具分别阻止较松眼罩并允许等紧度眼罩使用挂钩；高级材料真实显示。新增窗口案例集中于`tests/equipment_ui_cases.gd`，从原窗口入口运行，共用助手。截图`ui-27-leg-bands-retained.png`、`ui-28-jacket-structure.png`、`ui-29-head-comparison.png`、`ui-30-advanced-catalog.png`已查看确认。悬浮眼罩另新增16种子规格文案检查与两模板覆盖，保留冻结/打断/落空原有测试。

四类普通材质、眼口、包裹、单手套、四种单腿套、拘束衣、躯干固定和普通/组件链接均有真实装备规则与练习入口。29项装备练习、2项压力练习、2项警卫练习合计33项。警卫练习已施加合法中级普通/复合装备，并完成实际入狱保留、没收与追加结算。普通塔路敌人生成绳索、皮带及布带/胶带眼罩；第8、12层的可选警卫与第16层塔顶双警卫可生成合法中级普通/复合装备。地图包含15层房间、第16层双警卫与第17层出口，约30节点。监狱探索、巡视、反抗、消耗恢复、三条基本逃路与返回塔底现已实现。第5/9层已加入首批两个事件，慌乱、开锁针、工具匣与沙漏已实际结算。五级专用固定结局装备、特殊逃离道具、其余道具与多章节尚未实现；自动存档与继续游戏已在后续批次实现；颈部用途、肩部跨区域链接、额外通用加固、驷马/折叠固定和专项模板不在本批已定义范围。数值集中暂定，主角仍只有基础三姿态，无逐件穿戴差分；警卫临时轮廓不代表最终美术。

窗口截图生成在 `build/`，不是运行资源。

## 2026-09-17 v0.17.1 修复版发布成品

来源：作者侧 `origin/main`（v0.17.1 提交，2026-09-17），正文逐字保留。

域：检查与测试、打包与发布。

- 用户要求更新GitHub为0.17修复版，同时提供PC、Android及密码保护的双层压缩版。版本统一为0.17.1，Windows文件版本0.17.1.0，Android versionCode由9升至10；保留原v0.17标签与发布，不并入PR #3的macOS打包。Android打包脚本改为读取同版本说明并附基础教学，避免沿用根目录旧说明；成品探针继续对0.17.x执行小魔女检查。
- `20260917T030419647-26868`：导入、architecture 471、touch 23通过，退出码0、源码指纹稳定。此前修复批次与PR整合各分类结果仍按下文分别记录；本次未重跑全项目或全部种子。根指引检查及5项检查器测试通过。
- Windows输出`outputs/spire-v0.17.1-windows-x64-fix-20260917`，导出前后运行资源指纹一致。`package-check-20260917T030529454`通过PCK内容、贴图、新局、练习、隔离保存恢复、小魔女平衡及发布EXE独立无头启动检查；未将无头启动宣称为目视渲染验收。
- Android输出`outputs/spire-v0.17.1-android-fix-20260917`，导出指纹一致，包名org.magic.spire、版本0.17.1／安装版本10、minSdk24、ARM64＋ARMv7。V2／V3验签、16KB对齐、provider唯一性及12份内容逐文件校验通过；证书SHA256与v0.17相同。`android-probe-20260917T030545246`包内资源探针通过。adb未发现设备，未做真机安装／触控／性能验收。
- 最终成品在`outputs/release-v0.17.1-20260917`，附验证说明、许可、基础教学和SHA256SUMS.txt。普通Windows／Android ZIP实际解压后与成品目录逐文件SHA256一致；双层7z包含两平台完整目录，内外两层都加密文件名，正确密码解压成功、错误密码拒绝读取，两次解压后的全部文件与源目录一致。证据在`outputs/verify-v0.17.1-20260917/verification.json`。
- GitHub按v0.17.1新标签及同名修复版Release交付，上传后以服务端附件SHA256与本地文件比对，再公开发布。缓存、测试存档、签名秘密、临时发布脚本及构建日志不纳入源码提交。

## 2026-09-17 修复18条基线失败

来源：作者侧 `origin/main`（v0.17.1 提交，2026-09-17），正文逐字保留。

域：界面、检查与测试。

- RuleChangePackage：玩法数值、候选、事务、随机和存档结构不变。本批修正17条过时测试前提，并把主页显示设置保存错误提示从右下角移到左侧免责声明上方，解决字体最小高度使控件底边超出900逻辑画布7像素的问题；保留现有错误文案及更新入口，无新增翻译或运行时状态副本。
- card_power的5条失败来自通用奖励池误包含小魔女专属牌；保留稀有度与排除条件检查，补五张专属牌在双方角色奖励池中的正反例。tower_progression的6条生命断言补上夹具保留的警戒2所产生的10点加成，保留周目倍率、分裂不重复缩放及固定治疗5点；另4条出狱顶层流程失败改为先正式选择10／11层入口，并增加未选择时拒绝跳顶层、失败状态不变的检查。
- home_persistence的新局预期改为真实开局奖励阶段departure，同时核对落盘阶段；宝箱恢复检查真实奖励面板，商店保留服务面板检查，二者均实际点击离开／继续并核对房间完成。保留精确恢复、资源和库存断言；新增非空保存错误在缩放后仍位于画布内、不压住免责声明且不改变游戏状态的检查。
- 主工作区`20260917T025735300-30980`：`tools/check.ps1 -Suite card_power,tower_progression -UI -UISuite home_persistence,home -KeepGoing -TimeoutSeconds 600`，规则card_power 1788／tower_progression 225共2013项通过，UI home_persistence 51项通过；home原左侧三控件断言因新增提示区失败，同批退出码1，源码指纹稳定。原失败日志保留。
- 更新home布局断言，明确检查标题、角色说明、保存提示和免责声明四个控件及状态不变；仅补跑受此修改影响的home分类。`20260917T030014632-4392`：`tools/check.ps1 -UIOnly -UISuite home -TimeoutSeconds 600`，113项通过，退出码0、源码指纹稳定。
- 本批最终按分类去重为规则2013项、UI164项通过，18条基线失败均已处理；不是一次全项目或全部种子回归。未生成截图、提交、推送、打包或发布。

## 2026-09-17 PR #2 架构与固定点存档选择性整合

来源：作者侧 `origin/main`（v0.17.1 提交，2026-09-17），正文逐字保留。

域：契约 `pr2-integration-review.md`。

基线e635bf5，PR头a56de58；先在隔离工作树验证，保留根／模块指引与现有目录。引入查询索引、文案按需入口、统一事件节点、状态迁移和checkpoint保存。修复非手牌实例显示被覆盖、四个测试文件漏迁移详情接口、重开时旧候选访问新游戏；存档文案及英文生成来源同步。RuleChangePackage、逐分类结果与可复现日志见[整合审查](pr2-integration-review.md)。

首批17个规则分类7996项、11个UI分类1280项分别通过；当时card_power 5条、tower_progression 10条、home_persistence 3条失败均在真正v0.17基线复现。这18条随后已处理，详见本文顶部修复记录；原失败日志保留。不是一次全项目门禁；未运行全部种子、Android／macOS真机或上游私有oracle，未截图、提交、推送、打包或发布。

## 2026-09-17 打包：Windows x64 v0.17（build pr2-20260917，协调者）

域：`tools/package.ps1`／`tools/check-package.ps1` 的产物与复验。**只打包，未发版、未推送、未做 Android。**

**环境（本机首次搭起，两条前置已登记 `.zcode/skills/repo-ops/SKILL.md`）**：引擎 Godot **4.7.2.stable.official.ed1daf0bf**（本机原先只有 4.7.0，与既有发布口径不符，故按 `docs/packaging.md` 装 4.7.2）；导出模板取自官方 4.7.2-stable TPZ，**SHA256 `f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011` 逐字等于文档记录值**，只安装 Windows x86_64 的 release／debug（±console）、`version.txt`（`4.7.2.stable`）与 `icudt_godot.dat`；打包脚本须用 **PowerShell 7**（5.1 无 `[IO.Path]::GetRelativePath`），且 `GODOT_BIN` 必须指向 `*_console.exe`（否则 GUI exe 不被等待、`$LASTEXITCODE` 为空，导出成功也会被判失败）。

**产物（`outputs/`，已被 `.gitignore` 忽略，不入库）**：目录 `spire-v0.17-windows-x64-pr2-20260917/`（24 项，含 `紧缚尖塔.exe`／`.pck`／12 份内容包／授权／`版本更新内容.txt`／`验证说明.txt`／`manifest.json`）；ZIP `spire-v0.17-windows-x64-pr2-20260917.zip`；校验和 `…-checksums.json`。

| 判据 | 结果 |
| --- | --- |
| `package.ps1 -BuildId pr2-20260917` | 退出码 0；导出前后运行源码指纹一致（`build/package-pr2-20260917/source-manifest.json`）；日志无 ERROR 行 |
| `check-package.ps1 -Directory <成品>` | **PASS**（清单逐项 SHA256 一致、发布 EXE 启动、成品 PCK 资源探针）；两次：`build/package-check-20260917T115621322`，加入包内验证说明并同步登记清单后 `…T115708521` 再次 PASS |
| ZIP 解压复核 | 24/24 清单项哈希与字节一致；清单外文件仅 `manifest.json` 自身（脚本按设计不把自身写入 files） |
| 哈希 | ZIP `8212e594af0d4e511fff70b550469c5075f8799f9d0870716fc83fadaf7d479d`（143545728 B）；EXE `28e19c54…`；PCK `5bf7f18b…`；manifest `62aa0857…` |

**未完成／不得当作通过（已写入包内 `验证说明.txt`）**：里程碑全量 `-Suite all -UI -UISuite all` **未运行**（本仓该命令历史上从未跑完）；本包依据的是开发路由的受影响套件轮（218.8s、`unrun=[]`、红集未超出既有六项）与两个冻结 oracle 的逐字通过，**两者都不能替代里程碑门禁**；Android 未打包（本机缺签名配置 `G:/CodexData/keys/spire-android/signing.json`）。包内另写明"每点击完整性检查改 debug feature"的过渡实现导致 release 不跑五道提交前检查与两道候选闸（早拦缺失由提交后聚合校验兜底并回滚）。

## 2026-09-17 per-click 完整性检查改 debug feature（实现者；协调者转写）

域：`spire-godot/core/game.gd`（提交入口／候选）、`core/room_events.gd`（事件探针）、`tests/architecture_cases.gd`＋`tests/check_index.json`。
契约 `docs/per-click-checks.md`。提交 `3f96965`（4 文件 +177/−18）＋`84eb12f`（2 文件 +8/−3），本地提交，未推送／未打包。

**实现**：`debug_checks_enabled()` 为单一判据（`OS.is_debug_build()` 为假恒 false；真时可由 `set_debug_checks_enabled(bool)` 覆盖，字段 `_debug_checks_override`；release 里 setter 直接 return）。门控点位：`game.dispatch` 五道早拦（`Consumables.validate_buffs`／`Binding.state_issue`／`SpecialEquipment.validate`／`Cards.validate`／`RelicEffects.validate`，顺序与版本判定位置不变）、`game._build_candidates` 两道候选闸、`room_events.probe_result` 只门控 `g.validate()` 一半（effects／可行性与 `held_pending` 不动）。**保持不门控**：版本相等、`write_game` 写档前聚合校验、`restore_snapshot` 读档聚合校验、`Snapshot.check`、`SpecialEquipment.validate` 的规则用途（`room_events.gd:783/903/1250`）、`equipment_replacement` 自检。
诊断落 `debug_check_failures`（`{check,reason,location}`）＋`push_warning`；**不进 state／存档／View／玩家日志／`{ok,error}`**，由新 check 逐条断言。

**判据（最终提交内容上复跑）**：①冻结 oracle 各两遍全绿且逐字等于基线（`EVENTDIGEST 1f11bea5…`、`TRANSITIONDIGEST 14eb8cf9…`）；②`-Suite architecture,core,runner,persistence,rewards,guard,battle_saturation -Impact -KeepGoing`：退出码 1、218.8s、`FAIL 15/20157`、**红集＝{card_power 5, installed_tools 1, tower_progression 10} ⊆ 既有六项**、`unrun=[]`、`runner` 索引零漂移 PASS；③新具名 check `tests/architecture_cases.gd:per_click_checks_are_debug_only`（消息前缀 `PERCLICK`）；④敏感性证明（临时把覆盖默认值改 false）：`events` 红 1 条（`tests/event_cases.gd:179` 确有既有用例依赖被门控的探针 validate 半）、`event_flow`／`core` PASS（＝五道检查与两道候选闸在既有语料里从不失败）、`architecture` 红 17 条（证明新 check 非空转），随后按 sha256 还原（`core/game.gd=71484d1e…`）。

**release 行为差异（登记要点）**：release 下五道 dispatch 检查与两道候选闸**不跑**——早拦消失；候选闸跳过**等于带坏状态继续建候选**；`dispatch` 内"执行后、提交前"的聚合 `validate()` 不在冻结清单、未动，仍是 release 的安全网（坏提交被"行动未提交：…"拒绝并回滚）。写档／读档／规则用途不受影响。

**未验证**：真 release 二进制行为（需打包，超出本片边界）、UI 套件与全量 `-Suite all -UI -UISuite all`、Android 真机。**观察交回**：执行后的聚合 `validate()` 是否纳入后续片待裁。

**追记（协调者，同日）**：人已裁定本 debug feature 属**过渡形态**，将在点击路径根治的提交中一并替换（`docs/refactor-direction.md`），届时本条的 release 门控结论随之失效，须重跑受影响的域。

## 2026-09-17 长流程试玩策略零进展护栏（原文缺标题，按正文重建）

域：`spire-godot/tests/normal_play_cases.gd`（长流程试玩策略）——**:184 断言未改、三条种子未删、1800 步上限未动**；
**产品代码零改动**（`git diff c356c64` 不含 `spire-godot/core|data|ui|content|assets`）。索引随 `tests/**` 改动 `check-index.ps1 -Write` 重冻结同批提交。

**复现与原始数据（分类依据，非断言失败推断）**
- 复现：`& tools/check.ps1 -Suite normal_play -TimeoutSeconds 900 -KeepGoing` → 退出码 1、`SUITE RESULT: normal_play FAIL`、
  `FAIL: 1/2779 assertions`、`SUITE RUNTIME: normal_play 1`（`n`＝该套件窗口内的引擎错误数，出处 `tests/test_game.gd`）、**660716 ms**（耗时字段出自另一行 `SUITE normal_play: 2779 assertions, 660716 ms`，同 `tests/test_game.gd`）；红项只有 :184；`seed=20260906 style=elite` → `result=action_limit`、**1800 步**（550216 ms），
  step≈226 起每 25 步采样恒为 `自由 · 手腕`。日志 `build/checks/20260917T060154346-39608/`。
- 打转步抓取（`build/diag-normal-20260917/`，复刻同一循环逐步 dump 候选／dispatch 结果／前后状态差）：
  - `seed 42/cautious step 331`：`valid=3`＝{`自由 · 脚趾`（`magic_slip` 自由面，0 能量 0 魔力，`slot=toes` 空位）、`结束回合`、`取出`}；提交 `ok=true`、**`CHANGED=["version"]`**（手牌、四堆计数、魔力、快感、牢房字段全不动），事件 `「魔力松缚」施法失败（成功率0.92%）。卡牌留在手中。`
  - `seed 20260906/elite step 226`：`valid=52`；提交 `解除 · 普通假阳具口球`（`magic_slip` 束缚面，10 魔力、失败返还 5、成功率 **0.03%**）→ `CHANGED=["version","mana"]`（每次净耗 5 魔力），事件 `「魔力松缚」施法失败（成功率0.03%）。返还5魔力。卡牌留在手中。`
  - 结论性事实：**每次提交都被受理（`ok=true`、`version+1`），但装备耐久、牢房进度（turn/vent/door/key/position）、阶段与牌堆都不动**；
    动作是零／低成本的施法抽奖，而 `结束回合`（唯一能恢复能量、推进牢房回合的动作）被策略分数永久排在后面（`end`=−50 ＜ 自由面 0 ＜ 束缚面伤害分）。RNG 每步推进，因此不是状态完全冻结，而是**策略永不改选**。

**分类：(b) 测试策略缺陷**（非 (a) 产品缺陷、非 (c) 环境噪声）。依据：该候选由 `_candidate` 按真实施法成功率（0.03%／0.92% > 0）判为 valid，失败留手与按 `failure_outcome` 返还魔力是既有规则（`core/game.gd:2609 _cast_magic`）且有玩家可见文案；同一投影里本就有 `结束回合`／`item_discard` 等可推进候选，产品侧不存在"反复成功却不改状态"的动作，也没有无法脱出的状态机死路（修复后同种子 317 步到达检查点）。

**机制定性（明确）**："低成功率施法＝抽奖，失败只退默认 50% 魔力"是**刻意的游戏机制，不是 bug**——`core/card_effects.gd:39 failure_refund_rates`（默认 `CAST_FAILURE_REFUND`＝50%）、`:73 failure_refund_detail`（"失败默认返还本次耗魔的50%，自身与临时魔力各退回原池"），增益可改写为全额返还（如"失败返还100% · 能量＋1"），单卡 `refund` 可覆盖；因此"烧掉一半魔力而什么都不推进"是合法结果，成功率低到 0.03% 时近乎空转仍属机制内。本次**产品代码零改动**，只修测试策略；`tests/normal_play_cases.gd` 头部注释已按此改写（旧措辞"pays and refunds mana"易被读成全额退还，与实测"10 魔力净耗 5"不符）。

**修复（`tests/normal_play_cases.gd`，+94 行）**：新增"零进展重试护栏"——提交后由驱动侧记录**可见投影指纹** `progress_key`（阶段／房间／回合／姿态／墙／手臂腿／快感／手牌 uid／四堆计数／状态／装备耐久与锁／敌人 hp／牢房 turn-left-vent-door-key-checks-found-sites），**已付与已返还的魔力不计入进展**；同一 `attempt_key`（载荷可见身份，不含 preview 数字）在指纹未变时只允许**重试一次**，其后 `choose` 先跳过它改选其它合法动作，指纹一移动即解除。
护栏只覆盖"原地尝试类"（`card`／`manual`／`hook`／`item_*`／`flask`／`calm`／`status_toggle`）；移动与回合动作不进入（盲走合法性允许重复同一方向，`结束回合` 正是要到达的兜底）。护栏是**偏好不是锁**：若它是唯一合法候选则照常选择（`choose` 两遍），不会产生 `no_candidate`。
新增 6 条具名 check：失败候选在结果未知时可打、指纹忽略已付/返还魔力、允许一次重试、零进展后改选、指纹移动后复位、绝不抽空合法动作、盲走不进入护栏。

**判据（本机墙钟）**
1. `& tools/check.ps1 -Suite normal_play -TimeoutSeconds 900 -KeepGoing`：**退出码 0**〔**274.2s**，其中 `CHECK rules` 271.46s〕、`SUITE RESULT: normal_play PASS`、**959 assertions**；
   三条种子全部 `result=prison_route`：42/cautious **334 步**（38.7s，护栏命中 6 步）、20260906/elite **317 步**（130.8s，护栏 16 步；原为 1800 步 action_limit）、7/trade **285 步**（99.6s，护栏 2 步）。274s ＜ 打转时 660s。
2. `& tools/check.ps1 -Suite prison,guard,persistence,architecture,runner -Impact -KeepGoing -TimeoutSeconds 900`：退出码 1〔**209.6s**〕、38 套件全有 `SUITE RESULT`、`unrun=[]`、`before==after`；
   `FAIL: 15/17673 assertions; 16 engine errors`，**红集＝{`card_power` 5, `installed_tools` 1, `tower_progression` 10(+1)} ⊆ 既有登记六项集**，无新增红项；`runner`（含索引零漂移自检）PASS。
3. 冻结 oracle：event `EVENT RESULT: PASS (94 scenarios, 0 failures)`、`EVENTDIGEST 1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da` 逐字等于冻结基线、退出码 0、`SCRIPT ERROR|ERROR:|Invalid access` **0 行**〔5.7s〕；
   transition `TRANSITION RESULT: PASS (31 scenarios, 0 failures)`、`TRANSITIONDIGEST 14eb8cf9c3c8b5d4347b2b9d118b8c504596e04d296d091884995bc359b522b6`（＝收束后记录值）、退出码 0、错误行 0〔4.4s〕。

**未验证／未做**：全量 `-Suite all -UI -UISuite all`（里程碑重跑由协调者决定；本片只修长流程策略）；Android 真机；打包／发版／推送。
残余风险：`attempt_key`／`progress_key` 是测试侧启发式，若将来出现"合法重复且指纹不动"的动作类别需按新证据重分类。

## 2026-09-17 检查路由与隔离·实现侧记录（原文缺标题，按正文重建）

域：`spire-godot` 检查入口（`tools/check.ps1` ＋ `tests/`）——**套件失败隔离**与**派生检查索引＋路由**。
契约 `docs/check-routing.md`（§11 七条裁定随施工生效）。**产品代码零改动**：`git diff 3afdc55 -- spire-godot/core spire-godot/ui spire-godot/data spire-godot/content spire-godot/assets` 为空；
不推送、不打包、不发版；未跑全量 `-Suite all -UI -UISuite all`（契约未要求，见"未验证"）。

**两段提交（基线 `3afdc55`，分支 `event-pipeline-unification`）**

| 段 | 提交 | 内容 |
| --- | --- | --- |
| ① 隔离 | `eaa003a` | `tests/test_game.gd`／`tests/ui_smoke.gd`：去掉整轮 `break`／`return`，脚本错误与断言失败只记该套件 `FAIL`（脚本错误另打 `SUITE RUNTIME: <name> <n>`，`n≥1` 才打印）；套件加载失败打 `SUITE LOAD FAILED` 并继续；`-KeepGoing` 变兼容无操作；新增负例夹具 `tests/runtime_error_ui_probe.gd`（在 `await` 之后于协程内报错，证明控制权返回宿主）；`-VerifyRunner` 探针改为隔离反例；旧口径加 superseded 指针（event-pipeline-unification／transition-pipeline／verification／changelog／repo-ops）。 |
| ② 索引 | `aa199f4` | `tests/check_index.gd`（derive／frozen／compare／suites_for，单一派生实现）＋`tests/check_index_edges.gd`（手写层，每条带理由）＋冻结物 `tests/check_index.json`＋生成器 `tools/build_check_index.gd`／`tools/check-index.ps1`（`-Write` 是唯一写者）＋计划宿主 `tests/route_plan.gd`；`tests/runner_cases.gd` 落 §3.4 i–viii 自检与 §6-G3 路由样例；`tools/check.ps1` 增 `-Changed`／`-Since`／`-ChangedList`（与 `-Suite`／`-UISuite`／`-UI`／`-UIOnly`／`-Impact` 互斥）、仓库外路径起引擎前拒绝、内容门独立阶段、`summary.route`；repo-ops 更新命令面与里程碑条款。 |

**三段墙钟（本机实测）**

1. **隔离收益**：同一命令
   `-Suite event_flow,events,content,architecture,localization,persistence -Impact -KeepGoing -TimeoutSeconds 900`
   ——**改动前**〔278.6s 截断＋261s 补跑＝539.6s，两个进程，`unrun`＝18 类〕→ **改动后**〔**729s 一次进程**，37/37 套件都有 `SUITE RESULT`，`unrun=[]`〕。
   覆盖未减少：**逐套件断言数与改动前逐条相等**（37/37，合计 16903 条），红集不变＝{`card_power` 5, `installed_tools` 1, `tower_progression` 10}，`SUITE RUNTIME` 分别记 5／1／10。
   口径说明：本机这一次进程比"两段之和"慢约 190s，全部落在 `prison`（92→283s）与 `persistence`（24→169s）两套件；单跑 `-Suite prison,persistence` 回到 91s／23s〔125s 墙钟〕，即长驻进程的开销，**不是行为变化**（断言数不变）。契约 §5.6 预期"≈400s 一次进程"在本机未复现；隔离的可复现收益是"单进程＋`unrun=[]`＋无需人工补跑编排"，不是时间。
2. **路由收益**：内容包清单 `-ChangedList`（内容门＋7 个消费者）**43s**（规则 31.5s、3023 断言、`CONTENT PASS: 12 file(s)`、退出码 0）；`ui/event_screen.gd` **44s**（`ROUTE RULE SCOPE: (none)`、UI `events` PASS 180 断言、退出码 0，两相分离仍成立）；计划宿主一次 **约 7s**（契约 §5.6 预期 8–10s）。
3. **索引维护成本**：`tools/check-index.ps1` 零漂移校验 **2.4s**（退出码 0）；`runner` 套件内含 i–viii 自检与 G3 样例，**1.3s／+52 断言**（≤10s 目标），`-Suite runner -VerifyRunner` 全探针 **154s**。

**索引规模（实测）**：`suite_files` 覆盖 **97 个注册套件**（规则 51＋界面 46；其中 **94 个有派生边**＝`suites_with_edges` 的另一口径；`rule:core`／`ui:baseline` 由宿主 `_core_cases()`／`_baseline_tests()` 承载、无用例文件，登记在 `SUITE_EXEMPT`）；**436 条（套件→源文件）边**；176 个用例文件全部有唯一 owner；`core|data|ui` 120 个 `.gd` 中 **117 个有边或域解析**、**4 个盲区**（`core/tool_rules.gd`／`core/item_presentation.gd`／`core/release_view.gd`／`data/phases.gd`，逐条 `BLIND_BY_DESIGN` 理由并注明由哪条闭包兜住）；`DOMAINS` 58 条、`WIDEN` 1 条（`core/game.gd + impact:persistence`）、`EXCLUDE` 12 条、`SUITE_EXEMPT` 3 条、`ORACLE_NOTES` 2 条、`INDEX_DEFECTS` **空**（无未闭合缺陷）。冻结物 `digest db5617dd…`、`generated_from 2214ff1a…`（冻结物以 `tests/check_index.json` 为准，2026-09-17 重冻为 digest `e2f17665…`／`generated_from 8c32ce78…`／437 边；上述 436 条与本段数字为撰写时值，原值保留为历史）；**连续两次 `-Write` 产物逐字节相同**（`cmp` 通过，键序稳定 §11-6，`git status` 无差异）。**体积 71 KB／3250 行**（契约估计 ≈11 KB）：主表 29.7 KB、`case_files` 17.6 KB、`domains` 10.8 KB、`domain_words` 4.2 KB、`registries` 1.8 KB——为可逐行 diff 用了 2 空格缩进与排序键。**任何 `core|data|ui`／`tests/**` 文本改动不改索引即红**（见敏感性证明 4）。

**盲区闭包清单（里程碑全量必须覆盖的路径）**：`spire-godot/core/**`→`all-dev`（含 `tool_rules.gd` 等 4 个 `BLIND_BY_DESIGN`）、`spire-godot/data/**`→`all-dev`、`spire-godot/ui/**`→`all-dev-ui`、`spire-godot/tests/**` 无法归属者→`all-dev`＋`all-dev-ui`、`spire-godot/content/**`→7 个消费者＋内容门、`spire-godot/assets/**`→`localization`（`assets/art/**` 另加 `hero_art`／`equipment_art`）、`spire-godot/tools/**`→`runner`、模块根文件→`all-dev`＋`all-dev-ui`、其他新目录→`ROUTE UNMAPPED` fail-closed。每次计划逐条打印 `ROUTE DEFAULT`／`ROUTE DOMAIN`／`ROUTE UNMAPPED`／`ROUTE WIDEN CANDIDATE`／`ROUTE MILESTONE`（扣除清单）。**`all-dev`／`all-dev-ui` 扣除 `normal_play`／`baseline`**，扣除清单每次打印，里程碑唯一入口仍是 `-Suite all -UI -UISuite all`（已写进契约命令面与 repo-ops）。

**判据（命令／退出码／断言／红集）**

- `& tools/check.ps1 -Suite runner -VerifyRunner -TimeoutSeconds 900`：**退出码 0**〔154s〕；`negative-isolation-assertion`／`-assertion-keepgoing`／`-runtime`／`-load`／`-ui` 与 `route-ui-only`／`route-content`／`route-save`／`route-snapshot-domain`／`route-blind-closure`／`route-unmapped-fail-closed`／`route-declared-none`／`route-scope-matches` **全部 PASS**；`negative-stop`／`negative-continue`（旧行为探针）已按 §4.3 改为隔离反例。
- `& tools/check-index.ps1`：**退出码 0**〔2.4s〕，`CHECK INDEX PASS: frozen index equals the derivation (digest db5617dd…)`。
- `-Suite runner`：**PASS 1446 断言**〔1.3s〕（含 i–viii 与 G3 全部样例）。
- 注入复现（真实注入，非桩）：`--probe-suite-failure`／`--probe-suite-runtime-error`（`tests/runtime_error_probe.gd`）／`--probe-suite-load-failure` 三种都得到 `SUITE RESULT: runner FAIL`＋后续 `tower PASS`、`unrun=[]`、`rules.retry=[runner]`、退出码 1；UI 侧 `--probe-module-runtime-error` 得到 `SUITE RESULT: localization FAIL`＋`SUITE RUNTIME: localization 1`＋`home PASS`（`await` 内报错后控制权返回宿主，§10-2 的回退条件不成立，UI 隔离按 §4.2 正常交付）。
- `-Changed -ListOnly`（本片工作区 9 个文件）〔7s〕：`.zcode/…` 正确判为 `ROUTE NONE`、新增 `tests/*` 判为 `tests/**` 闭包、`tools/*` 判为 `runner`、`runner_cases.gd` 判为 owner `runner`。
- **`-VerifyRunner` 的既有缺口（本片修）**：选择探针的原实现把子进程 stderr 经 `2>&1` 灌进父进程，`ErrorActionPreference=Stop` 下变成终止错误——`-Suite runner -VerifyRunner` 在 `3afdc55`（stash 后重跑）**同样失败**，属既有 harness 缺陷；改为 try/catch 捕获后退出码与消息都成为探针证据。

**敏感性证明（原始输出，全部还原、`git status` 干净）**

1. 冻结物改一字节（`"schema": 1`→`2`）：`CHECK INDEX FAIL: frozen index schema is not 1`、退出码 1。
2. 冻结物改内容一字节（`"blind": 4`→`5`）：`CHECK INDEX FAIL: frozen index is not the derivation, first difference at root.stats.blind (4 vs 5.0)`；默认门禁 `-Suite runner` 同步红：`RUNNER index_matches_regeneration: … first difference: root.stats.blind (4 vs 5.0)`＋`FAIL: 1/1446 assertions`。
3. 删一条索引边（`rule:action_copy → spire-godot/core/action_copy.gd`）：`first difference at root.suite_files.rule:action_copy.spire-godot/core/action_copy.gd (missing on right)`，`runner` 同红。
4. 源码漂移不 `-Write`（给 `tests/content_cases.gd` 追加一行注释）：`RUNNER index_matches_regeneration: … first difference: root.generated_from`＋`index_regeneration_is_the_only_writer`，`FAIL: 2/1446 assertions`。
5. 隔离：见上"注入复现"。

**新登记：一条既有红项（非本片引入，未修）**：界面模块 `interface`（`tests/interface_ui_cases.gd:156`）失败——
`CARD ART every registered card has an illustration: [witch_strain, … witch_authority]`（28 张角色二卡无立绘），`UI SUITE interface: 355 assertions`。
**分类证据**：`git diff 3afdc55` 对 `spire-godot/ui`、`spire-godot/assets`、`spire-godot/content` 与该用例文件**均为空**（本片只改 `tests/` 宿主／`tools/`；用例内部断言未动），断言内容与种子／夹具未变 → **既有内容缺口**，此前未登记是因为门禁从未单独跑过 `interface` 模块。另记：`spire-godot/ui/event_screen.gd`→UI `events`、内容包清单两条路由实跑均绿，说明该红不是路由引入。

**未验证／未做**：全量 `-Suite all -UI -UISuite all`（契约要求它只作里程碑唯一入口，本片按其规定未跑）；Android 真机；打包／发版／推送；`INDEX_DEFECTS` 学习环尚无条目可演（列表为空是"未发生漏检"的记录，不是覆盖证明）。四态计数：**passed**＝隔离 37 套件＋内容路由 7 套件＋界面 events／home／localization＋runner／tower＋8 个 route 探针＋5 个隔离探针；**failed**＝`card_power` 5、`installed_tools` 1、`tower_progression` 10（均既有登记）、`interface` 1（本次新登记）；**unverified**＝全量与 Android 真机；**skipped**＝`-Exhaustive` 与 `normal_play`／`baseline`（按设计不进路由）。

## 2026-09-16 状态迁移管线收束：实现四批落地与四项判据（实现者）

域：`spire-godot` 状态迁移管线——`state.phase=`／`state.room=` 的唯一写入者 `_apply_transition`、
唯一战斗结束判定 `_battle_end_reason()`、唯一执行 `_finish_battle(end_kind)`、进程内迁移日志
`_transition_log`。契约 `docs/transition-pipeline.md` §2–§6；基线见本文件同日的冻结记录
（`TRANSITIONDIGEST 00089c29a675e1268473645ab6b7a363e70295abf575cc6cc2929db995ca3e11`）。
不推送、不打包、不发版；本片不新增 `core/*.gd`，不改存档格式、玩家文案、数值与 UI。

**四批提交（均在 `event-pipeline-unification`，基线 `ce4f978` 之后）**

| 批 | 提交 | 内容 |
| --- | --- | --- |
| 基线 | `9ee7a2f` | 冻结迁移 oracle 与基线（脚本与基线在 gitignored `build/`，摘要入本文件） |
| ① 战斗结束判定 | `d519402` | `_battle_end_reason()`（""／victory／captured／saturated）＋`_finish_battle(end_kind)`；`_finish_if_saturated()` 变薄封装；4 处 `_all_gone()` 判定改走同一判定；2 个测试调用点按声明 kind 适配 |
| ② 阶段赋值 | `a1744de` | 26 个 `state.phase=` 写入点全部改走 `_apply_transition`；新增 `TRANSITIONS` 声明表与 `_transition_log`（进程内） |
| ③ 房间赋值 | `9d5a6af` | 最后 10 个 `state.room=` 写入点改走主路径；`_room_transition_kind`（层高＝`floor_enter`，否则 `room_enter`） |
| ④ 闭环 check 与收口 | 本批 | `transition_write_sites_are_pinned`（architecture）＋§5 八条 Gherkin 具名 check；`_apply_transition` 阶段显式化与日志一次一记 |

**收束后规模（实测扫描，`文件|函数|组`）**：①`state.room=`／②`state.phase=` 各 1 点（都在
`_apply_transition` 内）；③战斗结束 19 行／8 个函数（`_battle_end_reason`／`_finish_battle`／
`_finish_if_saturated`／`_start_round`／`_enemy_phase`／`dispatch`／`_execute`／`_end_turn`，
即契约 §1 的"8 个语义入口"，13 个引用点保留为同一批函数；④`_restart_tower(` 4 行（定义＋
`demo_exit.continue_run`／`prison.return_to_tower`／`prison.completed_turn`）。

**判据（墙钟为本机实测）**

1. **迁移 oracle**〔7s〕`--baseline=` 退出码 0、`TRANSITION RESULT: PASS (31 scenarios, 0 failures)`、
   输出 `SCRIPT ERROR|ERROR:|Invalid access` **命中 0 行**；31 个场景的
   `before`／`after`／`commit_logs`／`log_texts`／`digest` **逐字段等于冻结基线**，迁移日志增量等于
   抓取时冻结的 `transition_log_declared`（比对时两侧按"相邻同名＝同一次迁移"合并，见下"口径"）。
2. **规则门**〔2m08s〕`& tools/check.ps1 -Suite core,rewards,battle_saturation,guard,prison,tower,tower_progression,events,event_flow,persistence,architecture -Impact -KeepGoing -TimeoutSeconds 900`
   → `-Impact` 展开 44 分类；`FAIL: 5/7861 assertions; 6 engine errors`，
   **红集＝{`card_power` 5 条, `installed_tools` 1 条} ⊆ 已知四项**；`installed_tools` 的
   `SCRIPT ERROR` 触发 runner 的 `runtime_error` 分支，其后 **24 个分类 `unrun`**
   （清单：environment_height／exploration／shoulder／slip_motion／torso_binding／casting／wall／
   special_equipment／services／intent／action_copy／status／persistence／rewards／events／core／links／
   prison／guard／pressure／enemies／trader／tower／tower_progression），**合并为一次调用补跑**〔3m29s〕：
   23 PASS，`tower_progression` FAIL＝**10 条（已登记）**；补跑后 `unrun` 为空（未记作通过）。
   `summary.json`：`before==after`、无 `source_changed`。
   > **本条已取代（superseded，2026-09-17；新口径见 `docs/check-routing.md` §4.3）**："截断／`unrun`／合并为一次调用补跑"口径作废——脚本错误只记该套件 `FAIL(runtime)`＋`SUITE RUNTIME: <name> <n>`，同轮跑完其余套件、`unrun=[]`；数字原样保留为历史。
3. **界面门**〔1m22s〕`& tools/check.ps1 -UIOnly -UISuite persistence,home,events -TimeoutSeconds 900`
   → 退出码 0、三分类 PASS、`UI PASS: 369 assertions`。
4. **闭环 check 双向比对**〔架构套件 25s〕：扫描 `core/**/*.gd`（递归）、`#` 之后截断、`==` 排除，
   四组模式；扫描集 ⊆ 声明表（表外为空）且表内 14 项逐项命中（含③的 8 函数集合断言）。
   **敏感性证明（原始输出）**：在 `_finish_if_saturated` 顶部临时插入一处表外 `state.phase="battle"`
   → `SUITE RESULT: architecture FAIL`、`FAIL: 1/462 assertions`、
   `ERROR: ARCH transition scan finds no write site outside the pinned table: ["[\"res://core/game.gd:803:_finish_if_saturated\"]"]`
   （即 `文件:行:函数`）〔26s〕；随后还原（`git diff` 无残留）→ `architecture PASS`、`PASS: 466 assertions`〔25s〕。

**§5 八条 Gherkin 具名 check（全部走真实公开命令：先取 `candidates()` 再 `dispatch`）**

| 场景 | 落点 | 断言要点 |
| --- | --- | --- |
| 01 `battle_end_single_path_for_all_entry_points` | `tests/battle_reward_cases.gd` | 9 个入口（普通最后一击／`end` 后全灭／空间耗尽／事件战／监狱出口战／`dispatch` 后全灭／敌人离场后全灭／投降收押／警卫宣告收押）各自：迁移日志恰一条 `battle_end_*`、目标阶段不变、`_finish_battle` 计数 1（收押 0，走 `_apply_transition`） |
| 02 `prepare_end_three_branches_one_kind` | 同上 | `pack`／`map`／`cleared` 三支日志均为 `prepare_end`、目标阶段分别正确 |
| 03 `floor_enter_is_one_family` | `tests/tower_cases.gd` | 跨层抵达恰一条 `floor_enter` 且 room 变化在该条内；同层（牢房 -1→塔底 -1，真实出狱回合）零 `floor_enter` 且有 `tower_restart` |
| 04 `capture_routes_through_the_main_path` | `tests/guard_cases.gd` | 投降与警卫宣告两条收押：日志恰一条 `battle_end_captured`、`captured`／`prison` 不变、能量归零／无力化／牢房初始化与入狱快照（在迁移之后建立）一致、`validate()` 通过 |
| 05 `non_transitions_do_not_write` | `tests/service_cases.gd` | 打牌／未全灭的结束回合／商店交易／事件选择／牢房移动：日志为空、阶段与房间不变 |
| 06 `transition_log_never_reaches_state_or_view` | `tests/persistence_cases.gd` | 迁移日志在进程内非空；`state` 无 transition 键、快照／`pack` 存档／`get_view` 均不含 `battle_end_` 或 `_transition_log`；恢复存档不写日志 |
| 07 `transition_write_sites_are_pinned` | `tests/architecture_cases.gd` | §4 双向比对（含敏感性证明，见上） |
| 08 `demo_end_and_tower_restart_use_declared_kinds` | `tests/tower_cases.gd` | demo 结束＝`demo_end` 且阶段／房间不动；返塔继续日志全为 `tower_restart`、`map`／`tower_bottom` 不变 |

**迁移日志口径（新增，冻结基线时声明、收束后按此判定）**：一次迁移记一条。①同一 kind 的
`phase`／`room` 由调用点分两次写入（**赋值位置一律不变**），第二条只写未写过的字段时不再记；
②重复写同一字段仍是新的一次迁移（例如牢房每回合 `prison_cell_enter`）；③`_apply_transition` 只在
调用点显式给出 `phase` 时写阶段，且必须落在 `TRANSITIONS` 声明的集合内；只带 `room` 的续写调用不写阶段。
oracle 比对按"相邻同名合并"处理两侧，故行数差异不算漂移，kind 或顺序差异才算。

**与契约文面的偏差（实现中发现，已在报告列出）**：①契约 §5 场景 01 的"恰有一条"以本口径满足
（收押的 phase／room 两次写入合并为一条）；②契约 §3 表把 `guard.gd:113/117` 写作"经主路径执行"，
实现为两次 `_apply_transition`（不经 `_finish_battle`：后者拥有胜利／饱和的奖励体，收押副作用仍全部留在
`Guard.capture`、顺序不变）；③`floor_enter` 为契约 §5 场景 03 用到的 kind，§3 表只列了 `room_enter`，
本片补声明 `floor_enter`（层高判定）并保留 `room_enter`（抵达阶段的阶段写入）；④`demo_end` 为新增
marker kind（不写 phase／room，只记日志）；⑤`_enemy_phase` 尾部的 `_battle_end_reason()=="victory"`
判定在真实流程中不可达（1126／1166 的两处饱和调用先接管；只有"未完成的连续卡牌"这一非法状态才落到它），
oracle 用该非法状态单列一个场景（`battle_end_enemy_phase_all_gone`，唯一 `skip_validate` 行）冻结其行为。

**oracle 基线声明的两处更正（harness 缺陷，非行为漂移）**：抓取时无法自证的两行声明与代码事实不符——
`tower_restart_same_floor`／`demo_continue_restart` 声明 2 条 `tower_restart`（实际合并为 1 条）、
`prepare_end_cleared` 与 `practice_init_rest` 的重复同名写入；因两侧按同一合并口径比对，
**基线 JSON 与脚本的冻结内容未改**、行为字段零差异（31/31 逐字段相同）。

**未验证／未做**：`-Suite all`／`-UISuite all` 全量回归（契约未要求）；android 真机；
`docs/save-fixed-points.md`（暂停中，未 `stash pop`、未消费迁移日志，挂点已留）；打包／发版／推送。

## 2026-09-16 状态迁移管线收束：迁移 oracle 基线冻结（实现者，改道前）

域：`spire-godot` 状态迁移管线（`state.phase=`／`state.room=` 写入点、战斗结束判定、迁移日志）。契约 `docs/transition-pipeline.md` §3／§6(b)／协调者记录（本片硬前提：**改 `core/` 之前先冻结迁移基线**）。基线提交 `ce4f978`，抓取时 `git status --short` 为空。

- 脚本（gitignored）：`spire-godot/build/transition-oracle-20260916/transition_oracle.gd`，
  sha256 `b49b0164a6b962fc8eae4a843c36510e1fa12c846d9f0e565856fdc6ed092278`；式样照 `build/event-oracle-20260916/event_oracle.gd`，含 JSON 数字类型归一（比对侧）。
- 基线：`spire-godot/build/transition-oracle-20260916/baseline.json`，
  sha256 `ba979d18c31952d6d69ef06ce2ed102f7503c518fa8c6125ea6482c92bb5b4c8`，
  `TRANSITIONDIGEST 00089c29a675e1268473645ab6b7a363e70295abf575cc6cc2929db995ca3e11`，**31 个场景**。
- 抓取命令（`spire-godot/` 下）：`<godot> --headless --path . --script res://build/transition-oracle-20260916/transition_oracle.gd -- --write=build/transition-oracle-20260916/baseline.json`
  → 退出码 0，日志 `SCRIPT ERROR|ERROR:|Invalid access` **命中 0 行**，`TRANSITION PROBLEM` 0 条；同参数连抓两遍产物**逐字节相同**（`baseline-rerun.json`）。
- 场景覆盖（逐类）：`setup_init`／`departure_start|end`；八类战斗结束入口（普通最后一击／`end` 后全灭／空间耗尽／事件战／监狱出口战／投降收押／警卫宣告收押／`_enemy_phase` 尾部全灭）；整备结束三类（`pack`／`map`／`cleared`）；进层（`floor_enter`）与换塔同层（`tower_restart`，牢房 -1→塔底 -1）；房间迁移与练习初始化四种（rest／shop／battle／prison）；牢房回合、巡视、逃脱；事件进入／空房离开／事件道具奖励；demo 结束与返塔。
- 每场景逐字段冻结：迁移前后的 `phase`／`room`／`floor`／`version`／`state.rng`／本次提交日志 sha256（`commit_logs`）＋可读日志行（`log_texts`）／`room_event` 摘要，并给出行摘要 sha256（`digest`）。
- **迁移日志的比对口径**（写进脚本头注，供后续复核）：`transition_log` 是本次新增的进程内日志，收束前不存在；基线在抓取时冻结 `transition_log_declared`（31 行的期望 kind 清单），比对时要求收束后的日志增量**逐字等于该冻结声明**，其余字段双向逐字段比对。
- 基线自检（收束前用 `--baseline=` 自比）：仅 31 行 `transition_log` 差异（期望），**其余行为字段零差异**，`TRANSITION RESULT: FAIL (31 scenarios, 31 failures)` —— 证明该 oracle 的行为字段在收束前是逐字段自洽的（`selfcheck.log`）。
- 未验证／未做：`core/` 尚未改动（本记录只冻结基线）；`_apply_transition`／`_battle_end_reason` 与迁移日志尚未存在。

## 2026-09-15 文案路由与按需投影（B0、R0–R6、B1–B3）验收与配对收益

域：spire-godot 玩家可见文案的投影路径（`get_view().card_texts` 收窄到显示集合 S、`card_instances` 只留手牌 uid、`deck_list` 移出 View、card 组候选 detail 改按需、`core/copy_router.gd` 收口 74 类文案）。契约 `docs/ondemand-copy.md`。

提交链：`cc5e8f0`(B0)／`7f1c748`(R0)／`40071d4`(R1)／`3f895b0`(R2)／`ee02495`·`2c2115c`·`964347a`(R3a/b/c)／`6247a56`(R4)／`ed2b5b2`(R5)／`0ce790e`(R6)／`6eca6e0`(B1+B2)／`a3cdcbe`·`638d6bc`(B3)／`67650f9`(场景 1/5 具名 check)。

- 三条 oracle（实现者运行，协调者核对日志）：`MASK DECLARATION` 与实际移除键集合**相等**（B1 `card_texts` 90/90/90/92/92/92 键、`card_instances` 0；B2 `deck_list`；B3 card 组 detail 60/60/130），`sha256(mask(new))==sha256(mask(基线))`、`masked_hash=true`、无差异；全牌型三入口（`live_card_text`／`live_card_text_set`／∈S 的 `view.card_texts`）逐字段相等，实例部分为包含关系（只允许 `face_costs`／`casting`）；真实夹具 `ui.projection_misses` 为空，缺键场景留有具名记录。收口阶段（R0–R6）为**空声明集**全等，即未改变 View 内容。
- 门禁（§8 原命令）：规则 `20260915T200001805-38332` 红集=`card_power`；界面 `20260915T200035182-33956` 红集=`shoulder`；`-KeepGoing` 版 `20260915T194250607-55264`＝5/9608（失败集恰好 5 条已登记 `witch_*`）、`20260915T194512850-9968` UI 1045 断言红集恰好 `shoulder`2+`torso_binding`1+`interface`4。**红集只等于已登记既有阻塞项，未多一条。**
- 夹具序列与具名 check：场景 0／1／4／5／7 已落地（场景 4 由 B2 oracle 的全量条目比对 + 牌堆浏览/商店去卡套件 + 三入口相等三层覆盖，未单列）。
- **配对收益**（`docs/equipment-performance.md:45` 协议：同机同批、交替、2 次热身 + 15 次有效配对；headless；对象为一次 `get_view()` 与一次 `candidates()`；旧侧 `0ce790e`（收口后、按需前）、新侧 `67650f9`）：

| 夹具 | 视图 旧→新 中位 (ms) | 配对比值中位 | 候选 旧→新 中位 (ms) | 候选条数 |
| --- | --- | --- | --- | --- |
| battle:0 | 79.39→23.22 | 0.311 | 24.14→11.46 | 86 = 86 |
| battle:12 | 108.72→44.87 | 0.416 | 44.70→27.22 | 98 = 98 |
| battle:26 | 206.28→81.24 | 0.398 | 120.54→54.83 | 182 = 182 |
| departure:0 | 50.04→6.56 | 0.127 | 0.56→0.50 | 6 = 6 |
| departure:12 | 58.89→9.37 | 0.164 | 0.73→0.69 | 6 = 6 |
| departure:26 | 72.14→13.61 | 0.186 | 0.96→0.81 | 6 = 6 |

- 夹具未漂：旧侧六档的 `view`／`candidates` 哈希与 `docs/equipment-query-seam.md` §8.2 冻结基线逐项一致（如 battle:26 `f7401077…`／`361c3777…`）；新侧按设计不同，其中 departure 的 candidates 哈希**未变**（该相位没有卡牌候选）。
- 口径：这是**同机同批配对数字**，不与历史批次拼接、不外推为帧率或全设备结论；本批只测 headless；收益来自按需化，收口阶段是逐字节等价的纯结构迁移。
- 未验证：**一次完整的独立验收未跑完**（验收者两次中断，已复跑的片段为规则门、`-KeepGoing` 界面门与人路径套件，日志见 `_spire-wt/gate-*.log` 与 `build/checks/20260915T22*`–`T23*`）；未跑 `-Suite all`、未做 Android 真机；`escape_preview` 未动；UI 响应路径与节键未动；未打包、未推送。收尾过程中另行发现并登记了 `rewards` 的既有红项（见下"既有红项登记"）。

## 2026-09-15 既有红项登记（非本次两片引入，未修复）

域：spire-godot 测试门禁在本次两片（装备只读查询接缝、文案路由与按需）**开工前的提交上即已存在**的失败项。两项均不属任何一片的改动范围，**未修复、未分类**；登记供后续接手方与全量回归判断使用。不得把其中任一项当作已通过，也不得为凑绿而从门禁命令里删除对应套件。

- `card_power` 规则侧：`tests/card_power_cases.gd:85` 的 `CARD reward membership follows rarity and explicit gift exclusion` 等 5 条 `witch_*` 奖励归属断言失败。复现：在未改源码的 HEAD（`1795e86`）上 `git stash` 后运行该套件 → `build/checks/20260915T163500673-34468`，退出码 1、5 失败 / 1781 断言。归因方向：`core/witch_expansion.gd` 的 `REWARDS` 与 `rules.SPECS.rarity` 的关系；未定类，未修改。
- `shoulder` / `torso_binding` 界面侧：三条失败（`SHOULDER UI compact cards show side and method`、`SHOULDER UI host card explains remaining-side penalty`、`BIND UI attachment and independent durability are visible`）。复现与根因见下方装备片验收条目；摘要：在切片父提交 `16c89e9` 的临时工作树上结果相同（`20260915T160616347-54344`、`20260915T160711923-52452`），根因 `ui/release_details.gd:35-38`（v0.17 `e635bf5`）只为 `lock_only`／`is_special` 渲染 `card_status`。
- `tower_progression`（规则 + 界面）：10 条规则断言 + 1 条界面断言失败（`tests/demo_exit_cases.gd:44/51/55`、`tests/tower_progression_cases.gd`；含 `DEMO boss health uses normal base, not compounded previous health`、`DEMO custom encounter health also scales`、`DEMO summon base scales while fixed healing remains five`、`PROGRESSION actual adjacent departure summit`、`PROGRESSION rebuilt summit creates a new boss instance without clearing safety history`）。**四点定位，失败集逐条相同、均在 10/215、退出码 1**：`964347a`（HEAD，`20260915T171801224-46088`）／`1795e86`（B0 之前，`20260915T171350281-47260`）／`e635bf5`（v0.17 发布点，`20260915T172946961-28640`）／HEAD 且仅把 `core/demo_exit.gd` 还原到 R1 之前（`20260915T171821467-40568`）→ **先于 v0.17 即存在**；证据留档 `build/ondemand-copy-20260915/preexisting-tower-progression-*.log`。
- `interface`（界面）：多套件连跑时报 4 条错（单独跑只 1 条，属模块间状态污染）。`964347a`（`20260915T171841906-51540`）与 `1795e86`（`20260915T172502057-47120`）失败集相同 → 既有。
- `rewards`（界面）：1 条断言失败——`tests/reward_ui_cases.gd:138` 的 `REWARD UI final unlock segment does not promise a third lock`（313 断言、exit 1）。**三点定位，失败集逐条相同**：`67650f9`（HEAD，`20260915T233305923-26972`）／`base-0ce790e`（R1–R6 后、B1–B3 前，`20260915T233523727-20952`）／`1795e86`（**文案片首个代码提交之前，`core/copy_router.gd` 尚不存在**，`20260915T234925378-16980`）→ **非本次两片引入**；`e635bf5`(v0.17) 亦红（`20260915T234617519-20320`，但在 217 行因另一处脚本报错先中断，仅作旁证）。根因：链式行的 detail 由 `ui/release_details.gd:53-54` 放进**默认折叠**（"效果详情 ＋"），故不在 `visible_text` 中；`core/release_view.gd` 与 `tests/reward_ui_cases.gd` 在 `e635bf5→HEAD` 逐字节未变，属 **v0.17 UI 渲染 vs 测试期望**同族（与上面 `shoulder`／`torso_binding` 同源）。该套件自 v0.17 起未绿、且从未列入任何门禁命令。
  - 若日后要修，两条路都需先裁定：(a) 测试改为先展开"效果详情 ＋"再断言（等于改断言，须明确授权）；(b) 让链式行恢复内联 detail（改 v0.17 的 UI 设计，超出本片范围）。**本次两片都不得动。**

## 2026-09-15 装备只读查询接缝（B1–B9）验收

域：spire-godot core 装备只读查询（`_equipment_read` 作用域、契约 §1 查询接口、§3.1 外层入口作用域）。对象提交 `def4039`；链 `eb6eeed`(B1)／`094c1d3`(B2)／`240658c`(B3)／`8de2957`(B4)／`79946ab`(B5)／`5af275d`(B7)／`09ccdd7`(B8)／`def4039`(B9)，B6 并入 B9 无独立提交。验收者为独立复跑（非继承），未改产品代码与测试逻辑；测试存档隔离（`ui.persistence_enabled=false`），不默认截图。

- 范围预检（不算通过）：`& tools/check.ps1 -Suite architecture,equipment,equipment_complete,links,composites,shoulder,torso_binding,casting,prison,events,slip_motion -ListOnly` → 退出码 0、`PLAN ONLY`、列出全部 11 个套件。日志 `build/checks/20260915T154755781-47440`。
- 规则门（验收者复跑）：同一 11 套件 `-TimeoutSeconds 900` → 退出码 0；11/11 `SUITE RESULT: PASS`、`PASS: 3509 assertions`；`build/checks/20260915T154809866-41232/summary.json` 的 `status=passed`、`before==after=089A94CB8229B7444E752F15A5FC2219079BF97ED3D9CB5F4985BD8DCF5F351D`，与实现者早前同一棵树的 `20260915T154200809-8364` 指纹一致（指纹稳定）。§11 具名检查随所通过的分类执行，未按条单独打印。
- 界面门（验收者运行）：`& tools/check.ps1 -UI -Suite architecture -UISuite equipment_complete,body_layout,shoulder,torso_binding -TimeoutSeconds 900` → 退出码 1、`summary=status=failed`（`build/checks/20260915T155153696-56180`）。architecture 规则 193 项通过；UI 在 `shoulder` 套件 19 项断言后失败 2 项：`SHOULDER UI compact cards show side and method`、`SHOULDER UI host card explains remaining-side penalty`；该次调用中 `torso_binding,body_layout,equipment_complete` 未执行。
- 归因（保持未定类，留协调者裁决）：上述失败在切片父提交 `16c89e9` 的临时工作树上复跑结果相同——`shoulder` `20260915T160616347-54344` 19 项断言、同样 2 错；`torso_binding` `20260915T160711923-52452` 11 项断言、1 错（`BIND UI attachment and independent durability are visible`）。根因是 `ui/release_details.gd:35-38`（git blame 落在 v0.17 提交 `e635bf5`）只为 `lock_only`／`is_special` 渲染 `card_status`，而既有检查期待普通件的 `card_status` 文案（"无法挣扎"／"肩带N条…×0.5"／"躯干固缚"／"独立连接耐久"）出现在 EquipmentDetails；与 B1–B9 的实现代码无关。归类处于"程序本身（既有 UI 文案渲染）"与"测试脚本（既有期望未随 v0.17 更新）"之间，无法确定单一归属；未自行修改，也未放宽断言。临时工作树已删除。
- 其余界面分类（验收者复跑，干净工作区）：`-UIOnly -UISuite body_layout,equipment_complete` → `20260915T161052970-53984` 245 项通过、退出码 0、`status=passed`、指纹稳定（此前一次 `20260915T160743098-42972` 因验收者临时脚本改变指纹被标 `source_changed`，仅记录 245 项断言结果，不称冻结通过）；`-UIOnly -UISuite route,events,prison` → `20260915T161152069-53156` 531 项通过（route 地图、prison 牢房、events 事件）、退出码 0、`status=passed`、指纹稳定。
- 人的路径证明：优先复用既有分类，缺口由验收者补充脚本补齐（运行时临时置于 `tests/`，跑完已删除；脚本与日志归档在忽略目录 `build/validator/validator_equipment_seam_paths.gd`、`build/validator/supplement-head.log`，`VALIDATOR PASS: 44 assertions`、退出码 0；工作区随后恢复干净）：
  1. 战斗中真实点开普通件详情：位置行与 View section 文本、耐久／紧度行与 View entry、View entry 与权威实例逐项一致 → 新补（`body_layout`／`equipment_complete` 复用了开合、位置标签与文案断言）。
  2. 肩带件：详情卡片数 = `Shoulders.attached`（2/2）、每件名称、视图 `card_status` 的"连接至宿主"= 权威 `_equipment_name(host)` → 新补；`shoulder_ui_cases` 的可见"无法挣扎"文案属上一条红项，不计通过。
  3. 复合组件与链接绳：链接绳卡片使用 View 名称、每张卡片耐久 = 权威件耐久、三次真实切割根套体后"遗留外带"出现且被移除件无残留卡片 → 新补（"遗留外带"复用 `equipment_complete` 既有断言）。
  4. 真实打出会损坏装备的牌（`strain` 经真实拖放提交）：详情显示新的耐久／紧度行且不再包含旧行 → 新补（既有 `release_preview` 只覆盖提交前数值预览）。
  5. 进入地图／事件／监室各一次：三项既有套件全通过（上条）；补充脚本另断言三处入口后 `_equipment_read.is_empty()`、`validate()==""`，并以 QuickSL 完成一次读档校验 → 新补。
- 未验证项与边界：未运行全项目 `all` 回归；未做 Android 真机验收；未独立复核 §8 的 oracle 基线与分批记录（不在 §12 命令内，属实现者证据）；界面门整体仍为 `failed`，`shoulder`／`torso_binding` 两项既有红未修复，本片不能宣称验收全绿或全项目通过。本次只读验收：未改产品代码与契约、未截图、未打包或发布。

## 2026-09-15 v0.17 发布

域：检查与测试、打包与发布。

- 用户要求Windows / Android打包、推送GitHub并发布v0.17；随后明确要求停止继续测试并直接发布。原已完成角色2、监狱、快捷解除、图鉴与立绘等工作随当前项目一并交付。
- Android通用PopupMenu接入独立触摸桥接；通过嵌入窗口入口处理原生选项，修复设置点选不生效、长列表覆盖打开按钮时误选；滑动不点选，取消不提交，系统返回键优先关闭选项框。游戏规则未因这次修复改变。
- 触摸专项20260914T154140815-7672通过23项断言，退出码0，源码指纹稳定；根指引检查及其5项单元测试通过。
- 全量尝试20260914T154351828-34328未完成。card_power中5项旧公共卡池断言未兼容新增小魔女专属卡；normal_play策略在零费失败留手法术上反复重试，诊断确认结束回合仍为有效候选。停止检查进程后汇总为failed，全量UI未执行。本次不宣称完整回归通过；未发布后续尚未验证的测试策略修改。
- Windows目录outputs/spire-v0.17-windows-x64-release-20260915：导出前后运行资源指纹一致；package-check-20260914T154921029通过PCK探针、角色2平衡探针与发布EXE独立启动。最终ZIP重新解压后23个清单文件校验一致。
- Android目录outputs/spire-v0.17-android-release-20260915：版本0.17、versionCode9、minSdk24、ARM64+ARMv7；V2/V3发布签名、provider唯一性、16KB对齐及内容包校验通过。android-probe-20260914T155014250包内资源探针通过。没有连接的Android设备，未做真机验收。
- 交付文件位于outputs/release-v0.17-20260915，均为正常无密码包，附SHA256SUMS.txt。源码/测试/资源/文档纳入对应提交；缓存、日志、玩家存档及签名秘密排除。

## 2026-09-15 点击／拖牌／快捷栏目标查询收拢

域：`ui/target_queries.gd`；契约 `release-interface.md`。

- 共用ui/target_queries.gd的10个只读查询；main、drag_targets、quick_release_bar保留原交互入口并转交共享筛选。模块不持有Game、控件或跨刷新缓存，返回原候选供既有ID＋版本提交；各入口原有去重、牌面、自动目标及首／末不可用原因顺序保持。RuleChangePackage见docs/release-interface.md。
- build/target-queries-20260915/compare.json记录空装备、多装备、复合与链接、拘束衣、长型单手套、监狱及特殊装备七场景；每场景1390项，共9730项新旧查询结果与顺序一致，完整状态和View未变。旧实现仅为忽略目录内诊断参照，不进入运行代码；本批不宣称帧率提升。
- targeting原分类新增17项契约断言，覆盖共享物理目标与两面、候选引用、返回容器隔离、首／末拒绝原因、捕缚额外目标、手牌去重、牢门、火球、指定ID顺序及失效版本；继续执行原真实点击和拖放用例。
- `tools/check.ps1 -UIOnly -UISuite targeting,basic_attacks,body_layout,keyboard,guard,equipment_complete,casting,card_power,exploration -TimeoutSeconds 600`：`20260914T145522480-63836`的card_power 307、basic_attacks 236、exploration 43、keyboard 87、casting 55、body_layout 147、targeting 100、equipment_complete 98、guard 87，共1160项断言全部通过，用时338.36秒。检查期间工作区变化，汇总为source_changed、退出码1；按修改时间发现同期英文目录、目录生成脚本和本地化测试更新，只记录断言结果，不宣称冻结源码门禁通过。
- 本批相关文件git diff --check无空白错误。纯UI查询重构未重复运行规则全量；未生成截图、处理存档、打包或发布。

## 2026-09-15 工具模块数据／规则分层

域：`core/tool_rules.gd`、`data/field_tools.gd`；契约 `game-design.md`。

- 20个读取对局状态的工具查询方法原样迁到core/tool_rules.gd，继承data/field_tools.gd的同一只读注册表；数据层保留3个纯方法，197→61行，移除core/contact依赖。g.Tools入口与规则算法保持；game、game_view、consumables改读规则模块，图鉴／掉落继续只读数据。23个方法正文逐项一致，无重复转发或第二份数值表。实施边界同步game-design.md与AGENTS.md。
- build/tool-boundary-20260915记录普通／复合链接／监狱／特殊装备×站坐卧×有无触手朋友的24组完整View和候选对照，以及33次正式安装／取回的返回值与完整状态对照，全部一致，查询保持状态。副本仅在忽略目录，运行源码只有一套实现；此批不以耗时或帧率提升为目标。
- 工具、高度和消耗品按Impact合并item_discard、consumables、encyclopedia、installed_tools、environment_height、casting。`20260914T144300639-62632`中item_discard288／consumables229通过，图鉴测试仍通过Book.Tools调用实时description而解析失败；改为neutral.Tools，保留图鉴与实时说明一致性断言。`20260914T144358099-59992`补跑encyclopedia506／installed_tools44／environment_height25／casting581，共1156项通过。
- 新增架构检查先修正了脚本反射写法（初次ListOnly即报告解析失败，未作通过证据），随后`20260914T144358082-58872`暴露测试错误地试图修改只读常量表；未改运行时放宽只读，而将断言改为继承表身份、常量只读与标签一致。`20260914T144518873-60540`：architecture158／exploration198／prison1255，共1611项通过，退出码0、指纹稳定。规则去重合计3284项通过。
- `20260914T144358099-59992`窗口encyclopedia170／installed_tools56／exploration43／items46通过；consumables原断言仍要求普通动作栏总有InstalledTool按钮，实际入口已迁到快捷栏。改为真实关闭抽屉、切换快捷栏、点击该工具，核对全身固定说明、精准物品和无行动消耗。`20260914T144702242-63500`补跑consumables52项通过，窗口去重合计367项。最后批次运行期间有同期源码变化，状态source_changed；仅报告逐批断言通过，不称整版冻结回归。原失败日志均保留，UI SCREENSHOTS:none。
- 存档专项继续延期；没有全项目回归、打包、发布或大版本完成宣告。此前记录中的data/field_tools职责混杂已在本批解决，其他大文件和图鉴／教程分层风险仍按后续独立批次处理。

## 2026-09-15 架构与接口边界检查

域：`data/field_tools.gd`、`data/encyclopedia.gd`、`data/tutorial.gd`；契约 `ui-scene-refresh.md`。

- 静态扫描core 45／data 26／ui 46，共117个运行脚本的显式load／preload依赖与UI对game的调用；检查主提交入口、候选索引、只读投影、只读查询生命周期、自缚临时状态及新增快捷栏／释放预览的职责。诊断范围与当时源码散列保存在忽略的build/architecture-20260915/audit.json。没有显式加载循环、core／data反向加载ui／tests或UI直接game.state／私有game方法调用；动态助手调用不由此静态扫描证明安全。
- 发现并修复两个间接越层读取：主立绘和身体栏通过Character.active(game)读取实时角色，可能与render(snapshot)的独立快照不一致。改为EquipmentPortrait共享显示策略，只消费已有character_id与固定立绘偏好；无新状态、规则、文案或存档字段。display补5项真实不同角色对局与快照交叉显示、两处一致、偏好覆盖及状态不变检查。契约见ui-scene-refresh.md。
- 保留职责不同的接口：physical_pieces／equipment_targets／action_targets查询范围不同；ActionIndex.find取首个匹配，first_usable取首个可用并在全不可用时返回末个，快捷栏first则保留首个不可用原因，不能按名称相近直接合并。正式UI行动仍统一进入game.dispatch，候选ID、版本与资格在支付前复核，事务复制状态后执行并在失败时恢复；未添加另一套执行入口。
- 未消除的维护风险：检查时game.gd约2848行、main.gd约2693行，分别集中大量规则协调与页面／目标选择职责。data/field_tools.gd兼具注册表及触及计算，data/encyclopedia.gd与data/tutorial.gd包含说明投影并引用core，共5条data→core显式依赖；目前无加载循环，但data并非全是纯数据。后续宜按物品操作、目标选择、展示投影等完整职责逐批迁出，保留现有权威规则及分类门禁。本次未为了缩短文件而整体搬移或统一掉不同语义。
- 首轮`20260914T142208740-61812`：architecture151项、display127／home113／equipment_art169／hero_art50共459项窗口断言通过。期间另一批单手套立绘修改了game_view、equipment_portrait、装备立绘测试及素材，报告source_changed，不能视为冻结工作区通过；本次共享显示策略仍完整保留。交叉文件重新导入并补跑architecture、display、equipment_art、hero_art，主页已通过且未涉及后续变化。
- `20260914T142425356-51572`：资源导入、architecture151项、display127／equipment_art176／hero_art50共353项窗口断言通过，退出码0且指纹稳定。随后继续审查新字段的完整传递，发现arena精简hero_view漏掉composite_portrait_layers，既有装备立绘测试只检查身体栏，未捕获战场立绘不一致。将精简显示数据生成收回EquipmentPortrait.snapshot并补短／长单手套在两处立绘一致及输入复制隔离6项检查。`20260914T142716643-60772`因新增测试误将局部变量用于类型判断而解析失败，其他类未执行；改为脚本常量后仅补跑失败／未执行的窗口分类，原失败报告保留。
- 修正后`20260914T142750772-9268`：display133／equipment_art176／hero_art51共360项通过，源码变化仅为同期hero_art测试补充；两项运行代码修复均保留。最后只复核该变化分类，`20260914T142918982-56744`的hero_art51项通过、退出码0、指纹稳定。按各分类最终已执行结果去重，本轮architecture151项，窗口display133＋home113＋equipment_art176＋hero_art51＝473项逐批通过；不把多轮混合结果称作整版冻结全量验收。无默认截图。
- 本轮检查不等同全项目逐条玩法验收；存档专项继续延期，没有打包、发布或大版本完成宣告。

## 2026-09-15 快捷栏重复选择优化

域：契约 `equipment-performance.md`。

- 只读UI优化包与分段测量见equipment-performance.md。同一格更新只解析一次部位和装备；原候选、排序、精准选择和具体原因保持，不跨同版本的UI操作保留缓存。新增10项检查覆盖换目标、翻面往返、过期版本、缺失部位／目标、主动选择空部位、候选身份及View／状态／控件不变。
- `20260914T141124582-58372`：`tools/check.ps1 -UIOnly -UISuite basic_attacks,keyboard,body_layout,targeting,equipment_complete -TimeoutSeconds 600`，分别236／87／147／83／98，共651项窗口断言全部通过，退出码0、指纹前后一致、summary.status=passed。包含正式出牌、火球、降紧／开锁、原生拖放、键盘和详情开关。测试中窗口最小化导致绘制等待，恢复同一窗口后完成；因此总369.57秒不是运行性能数据。UI SCREENSHOTS:none。
- 五场景9600组新旧显示及候选逐项一致，默认四格全卡牌扫描空闲16→8、带选牌24→4；已记住选择的路径另测，空闲扫描没有下降且密集样例计时回退，具体数据及限制完整保留。诊断副本只在忽略的build目录。
- 本批纯显示选择优化，按模块约定只跑以上受影响窗口分类，没有全项目规则回归、存档跟进、打包或发布。

## 2026-09-14 小魔女扩展与脱缚练习

域：契约 `character-two.md`。

- 规则包见character-two.md最新扩展段。初始11张、每部位无限预备／每回合一次成功释放、五张新奖励牌、两面混合牌类型、回合增益和强制锁回合均沿正式候选提交。脱缚练习两面共享实体进度，按1×3／1×6／2×6／3×6逐段结算，10／20／30／40次后进化；累计1张而非累计段数，跨战斗保留，卡组与牌堆进度不一致拒绝恢复。
- 初次合批20260914T133646540-24076中card_splash144、architecture151、persistence597、pressure1076通过；其间源码变化，标记source_changed，不作为冻结全量结果。card_expansion的休息限制优先级修复后，20260914T134345605-3048中card_expansion1088、encyclopedia506通过。图鉴旧数量断言已改为按角色过滤。
- 连续开锁旧用例写死入狱魔力100，实际夹具入狱后为80；改为核对真实入狱值扣除本次支付，保留连续开锁、一次付费和临时魔力优先断言。20260914T134638179-22204中rewards666、localization73通过；窗口encyclopedia170、localization51通过。home的旧断言未展开新“装备说明”折叠层，补正式点击后20260914T134844634-62396 home113通过，指纹一致。
- 最后增加同一初始牌依次打出两面、同阶段卡组／牌堆累计差异的回滚检查；20260914T134754114-43468 witch_character455断言通过，指纹一致。窗口覆盖角色2实际选角、预备／释放、释放后自动切回，图鉴角色选择不改对局、五个进化阶段同页、初始稀有度、两面红色警告和分面技能／魔法分类。
- 本批只报告上述受影响分类与补跑结果，没有全项目回归、截图、打包、发布或大版本完成宣告。

## 2026-09-14 墙缝高度与安装工具状态栏

域：装备与解除、检查与测试。

- 位置名称从固定高度表生成，详情、候选、地块与日志共用；不改变安装 ID、触及表、费用或存档。
- 只将正式候选中可触发的安装工具投影到角色状态栏及“环境”分类；沿用道具图标，角标显示次数，点击打开对应详情。随身切割工具和可用药剂不加入；无次数、离墙、不可触及及非行动阶段不显示有效工具状态。预览及点击详情均不改状态或随机。
- `20260914T124451422-55624` 资源导入通过；修正新增英文模板参数后，`20260914T124647878-50060` 的 localization 分类73断言通过。
- `20260914T124714118-55180`：installed_tools/environment_height/exploration/status 规则566断言通过，installed_tools/exploration 窗口99断言通过。期间其他源码仍有修改，门禁标记 source_changed；这些为已执行断言结果，不宣称冻结工作区全量通过。
- 状态窗口旧测试将费用徽标也拼进标题，错误要求整个控件文本以“深呼吸”开头；改为检查实际标题控件后，`20260914T124949797-19420` 的 status 窗口58断言通过。未截图、打包或发布。

## 2026-09-14 拘束具图鉴关键数值与限制补全

域：契约 `equipment-design.md`。

- 按用户要求保持简短，只扩充既有条目。普通装备补品质、紧度分档、锁效果；四种口球列出品质与紧度倍率和三档合计，眼罩说明意图遮挡与马具影响。复合装备显示各组件耐久／方法及关键解除前置；链接补向下1.25加成；特殊装备补取出条件与费用、刺激倍率、环境要求、电量耗尽仍保留、平板锁的已有特殊效果。口球按当前规则填写，没有新增假阳具款禁施法效果。RuleChangePackage见docs/equipment-design.md。
- 20260914T124657697-59256：localization73／architecture151／encyclopedia493／content380，共1097项规则断言全部通过；encyclopedia窗口79项通过，实际搜索并选中普通假阳具口球，核对0.25品质倍率及0.375／0.25／0.125三档合计，浏览不修改状态。UI SCREENSHOTS:none。
- 运行期间有同期源码变化，报告为source_changed，不作为整版冻结验收；本批只补文案与只读图鉴，未更改规则、存档、随机或发行版本，不打包。

## 2026-09-14 全卡牌双面资料与跨部位装备投影合批

域：契约 `equipment-performance.md`。

- 完整83种牌型仍供图鉴、奖励和牌堆浏览；双面正文与metadata分别一次生成，普通牌型card_info重复工作4→2。按两面各自费用、原显示精度、动态数量和实例成长生成，不冻结规则注册表。装备基础资料在既有只读上下文按权威实例复用，各部位拿独立副本并设置slot。影响包、旧接口语义与结果见docs/equipment-performance.md；玩法、事件、随机、数值、支付和玩家文案保持。
- 20260914T112226775-48592：architecture151、encyclopedia399共550项通过；源码同期变化，状态source_changed。新增装备检查覆盖跨槽内容、返回值污染、复制目标、临时状态和同版本耐久修改；保留完整只读View、候选与引用检查。
- 20260914T112702588-52316：witch_character224／card_power1671／card_expansion1083／card_growth20／architecture151／encyclopedia399／content380／casting565／special_equipment332／equipment_complete448，共5273项规则全部通过。卡面新增检查覆盖三个快感值、全部注册牌型、独立两面费用、内联数值舍入、规则表即时修改和成长／般若汤实例。
- 同批窗口card_power307／encyclopedia76／casting55通过；card_growth11项只有1项旧UI前提失败：它要求候选全文默认可见，但现有ReleasePreview已改为摘要＋“效果详情”展开。更新为先核对正式headline／change，再真实点击展开核对candidate.detail，保留真实出牌、成长与牌堆浏览。后续三类未执行，未标绿。报告source_changed，失败证据保留。
- 20260914T113235836-13300只补card_growth13／special_equipment52／body_layout147／equipment_complete98，共310项窗口通过，前后源码指纹一致，状态passed。无截图。其余已通过分类沿前述报告，不将跨批结果称为全项目冻结验收；本批三个运行文件与规则门禁前备份一致。
- 五场景新旧完整投影及全部83类metadata逐项相同，状态与随机游标未改变。完整刷新首测有明显负载波动，另以相同正式候选单独计量显示生成；15个有效交替配对的新／旧比值中位为空装备0.823、29件0.886、拘束衣0.755、复合链接0.743、特殊装备0.745。这里只报告显示阶段，不冒充整帧提速。初次基线词表未加载动态注册变体的诊断无效，纠正诊断初始化后复测，无引擎／脚本错误。数据和限制见性能文档。
- README和既有性能／引用文档同步。无旧档迁移、帧率设置修改、打包或版本里程碑宣告；诊断与基线仅放忽略的build/projection-batch-20260914。

## 2026-09-14 继续优化解除预览与候选费用

域：契约 `equipment-performance.md`、`equipment-reference-audit.md`、`content-generation.md`。

- 单次只读刷新按完整参数复用解除／施法预览，输入键和返回嵌套容器隔离，临时状态绕开原缓存，退出即释放；正式执行重新计算。卡牌逐目标候选按牌面共用费用，不改资格、数值、支付、随机、正文或存档。RuleChangePackage和测量见docs/equipment-performance.md，调用及引用说明见docs/equipment-reference-audit.md。
- 20260914T110022875-18612：architecture145项通过，包含24项新增检查；由于同期源码变化，状态source_changed。新检查涵盖全部四个布尔参数的16种组合、三种方法、极近浮点基础值、嵌套辅助档案、输入／结果修改隔离、复制目标、临时状态恢复及复合／肩带／躯干连接／特殊装备连续正式出牌。
- 20260914T110309543-53012按casting、equipment、hand_assist、slip_motion、card_splash、architecture的Impact展开36类；已执行30类共9653项，前29类全部通过，core657项仅TC-ENEMY-0003失败，后6类和窗口未运行。失败仍要求离场施加中级2档，而docs/content-generation.md和正式声明已固定中级3档；更新该单项旧预期，保留真实准备、行动和最终离场检查。报告有同期源码变化，保留原失败记录。
- 20260914T110819356-47620只补core及前批未执行的equipment、links、composites、equipment_complete、prison、trader，2870项全部通过；窗口使用实际登记的card_power307／card_splash12／casting55／equipment_complete98，共472项通过，无截图。此前命令中的card_expansion没有对应窗口分类且窗口尚未启动，补测按正式注册入口选择，未新增或伪造分类。36类规则的断言至此逐批通过，但两批报告均source_changed，不合称当前整版冻结验收；本轮game.gd、card_effects.gd、architecture_cases.gd与测试前备份一致，不覆盖同期改动。
- 最终独立交替性能对照无引擎／脚本错误，0／12／29件完整显示、各次查询只读及实际提交最终状态均相同。29件候选生成中位167.816→146.757ms，完整View266.329→237.540ms，样本出牌172.458→125.554ms；本轮与前批绝对时间不可跨负载拼接，空装备样例收益不稳定。解除实际计算264→149、施法217→10、魔力费用231→175。一次被同期测试文件改写打断的诊断保留为paired-interrupted.log，其数据未用于结论。
- 同步README、AGENTS和既有两份性能／引用文档；不迁移旧档、不修改帧率偏好、不打包或宣告v0.17完成。诊断副本与计数器只在忽略的build/equipment-preview-20260914目录。

## 2026-09-14 出狱新地图普通战斗统一强怪池

域：契约 `prison-release.md`。

- 到期出狱与击败出口守卫重建地图时，将全部普通房间的已有pool字段设为strong，实际入场继续沿原随机与连续不重复选择。精英／Boss、通关后塔底重新开始的前期弱怪保持。先选商店、退出起点选择或保存恢复不清除配置；地图仍用普通战斗图标，房间说明、出狱日志和教程新增强怪池说明，中英文同步。规则与影响边界见docs/prison-release.md。
- 20260914T101221506-56428：localization71／architecture69／content380／prison1203项通过；tower因测试种子42生成的第10—11层没有商店，索引空数组导致1个引擎错误，保留失败报告。测试改用实际有合法商店的固定种子47，补非空断言；读档比较沿既有same排除恢复时更新的版本号，提交后重新取得真实房间引用，不使用旧事务前对象。
- 20260914T101717427-56212：tower292项、prison窗口209项全部通过。覆盖两种出狱标记、第一场及连续多场强怪、不重复抽取、先选商店、保存恢复与敌人名单一致、强怪房间被篡改成弱怪时原子拒绝、正常新开反例及地图说明／图标。各分类用例通过，但运行期间另有源码变化，报告状态source_changed，不将其作为整版冻结验收；不为同期变化重复跑全量。窗口无新增截图。
- 无新增存档字段、快照修订或历史存档迁移；不打包、不发布，不宣告大版本完成。

## 2026-09-14 出狱练习按正式监狱重做

域：契约 `prison-release.md`。

- 用户反馈旧练习空身、登记清单为空，预装工具被没收后便直接合格。到期与延期练习改用正式Guard.capture生成收押装备、链接和完整登记清单，先显示收押结果，玩家确认进入牢房后从第1回合、已服刑0／20、巡视剩余16回合开始。移除19／20回合和预装工具夹具，不预设检查结果；出口守卫练习保留正式收押装备及正常敌人血量。菜单、说明、提示和英文同步，正式监狱规则及快照结构保持；RuleChangePackage见docs/prison-release.md。
- 首轮20260914T075836722-41224：localization71、architecture69、content380通过；prison1194项仅1项失败，原因是测试错误要求出口战斗开场之后仍恰好8件，遗漏正式开场追加的2件。诊断确认收押为8件普通装备、2件特殊装备和1条链接，出口战斗为10件；修正为收押时精确核对配额、战斗后保留正式追加。首轮存在源码变化，不作冻结验收，失败记录保留。
- 最终20260914T080116670-50964：prison1196项、prison窗口208项全部通过，源码指纹稳定，状态passed。覆盖真实收押确认、非空清单、完整20回合、第16回合巡视、已登记装备缺失导致补装和延期、8个追加回合及存读档一致、10—11层起点按钮和正常守卫生命。窗口未生成截图；UI边界案例只在确认真实入狱后加速一次到期检查，完整计时另有规则及真实窗口点击覆盖。
- 不打包、不发布，不将本次练习修复视为v0.17大版本完成；旧练习进度不迁移，需从练习菜单重新开始。

## 2026-09-14 大量拘束具性能与对象接口追踪

域：`core/game.gd`、`assets/localization/legacy-en_US.json`；契约 `equipment-reference-audit.md`、`equipment-performance.md`。

- 已按用户补充要求沿普通件、复合根／部件、肩带、链接绳、躯干连接和特殊装备逐类追踪创建、存放、查询、候选、事务、删除与UI。9个正式练习场景目标ID唯一、查询返回权威实例、读批次结束释放索引；引用列表及动态调用边在build/equipment-performance-20260914，说明见docs/equipment-reference-audit.md。
- 29件、5张手牌、200候选的一次get_view中，equipment_at1694次但只实际筛选13次，堆叠264次但只实际计算29次；_candidate原每目标重复查3次改为1次，该路径600→200。body_sections也复用查到的对象。索引只覆盖一轮只读调用，临时state绕开，提交和清理不复用；折叠详情首次展开才创建动作树，重复开合不再重复建节点。
- 原生窗口29件样例完整View147.735→87.390ms、候选95.131→46.767ms、手胸详情刷新中位33.444→26.595ms。0／12／29件完整View与优化前逐项相同，快照只读；最终代码的无索引／有索引11次对照，29件View中位162.136→93.422ms，正式出牌7次中位107.031→54.667ms且最终状态一致。具体数据及局限见docs/equipment-performance.md，不将一次样例当成全设备帧率。
- 首轮20260914T102147204-42804：12类规则5955项，card_power1661／card_expansion1083／relics848／application71／architecture107／runner431／casting565／special_equipment332／links165／composites90全部通过；equipment154与equipment_complete448合计11项旧前提失败。错误涉及离场档位、新监狱练习开局及限制项圈固定生命周期，不是索引输出不一致。第一次更新遗漏守卫练习已清空收押报告，20260914T102549544-49100保留失败；修正为检查正式入狱配额、真实链接及守卫战阶段后，20260914T102713460-21548两类602项全部通过，源码稳定。
- 20260914T102847180-2600窗口1180项：card_power307／display122／keyboard67／special_equipment52／body_layout147／targeting83／equipment_complete96通过；localization51中3项缺英文，services255中1项旧“紧度 1档”空格断言失败。补齐现有主页原角色说明及“双腿”英文，生成词表同步；旧标签测试按当前“紧度1档”更新，未删除可见数值检查。
- 最终20260914T103645837-17220状态passed，源码前后指纹一致：localization71／architecture121／equipment154／equipment_complete448，共794项规则；localization51／services255／equipment_complete98，共404项窗口通过。新增实际解除后旧装备详情节点释放、按钮索引无脱树节点、目标唯一与权威引用检查均通过。其他已通过分类沿用上述报告，不将多批结果合称全项目验收。
- 更新AGENTS及性能／引用说明。所有本次窗口检查未指定截图，未发送真实反馈，未新增存档迁移、改变帧率偏好或打包发布；v0.17仍在开发，不宣告版本里程碑完成。性能插桩只放忽略的build目录，游戏运行时代码不带诊断计时器。
- 收尾复核发现core/game.gd、tools/build_english_catalog.py和assets/localization/legacy-en_US.json在上述稳定门禁之后又有同期修改；本批读查询索引、重复查找合并及两项英文映射仍在。794项规则与404项窗口的通过结论仅对应报告记录的源码快照，不自动覆盖这些后续改动；没有覆盖同期工作或重新宣告当前整版全绿。

## 2026-09-14 项目跟进：身体栏复用与测试入口补齐

域：契约 `ui-scene-refresh.md`。

- 跟进当前四区解缚、场景复用、魔女角色及近期监狱／卡牌／遗物变更。扫描115个运行脚本、223条字面脚本依赖，未发现循环、失效路径、core／data反向引用UI、UI直接game.state访问或至少5行的重复完整函数体；这是静态限定检查，不等于所有接口或玩法均无问题。证据在build/progress-optimization-20260914/final-structure.json。
- 身体栏显示事实未变时保留部位按钮、滚动容器和输入映射；区域滚动不再因普通刷新回到顶部。失效覆盖语言、真实计数／占用／解除标记、焦点、展开顺序和高度；回调只持有稳定部位ID并读取当前候选，不保存旧View、装备图或候选。影响边界见docs/ui-scene-refresh.md。
- 首轮20260914T073306145-19316发现witch_character_cases未登记归属；补上唯一witch_character规则分类和17个实际交互区域，并列入当前开发分类。没有复制或删除原测试，最终224项角色规则全部执行通过。20260914T073345856-35224复现按钮重建／滚动复位／等价投影重建；新增焦点断言也纠正为实际选中hover色，原样式没有改变。
- 修复后20260914T073524855-48352：当时的规则716项通过，touch18／keyboard67／body_layout136／targeting83／equipment_complete96项全部通过，共400项交互断言；display121项中只有原音乐连打失败，未记整组通过。该报告源码稳定，保留失败记录。
- 音乐定位报告20260914T073755935-43964与20260914T073905346-49500确认音源相同、播放位置正常前进，但第二次实际出牌剩余0能量，正式候选拒绝。测试夹具显式准备10能量并新增点击前正式资格断言，保留实际消耗、暂停、进度和循环检查；未改播放实现或游戏费用。20260914T074007901-7688的display122项通过，但同期其他源码变化，不能作为冻结验收。
- 最终20260914T074057043-50376状态passed、前后源码指纹一致：witch_character224／architecture69／runner429，共722项规则；display122项全部通过。五类交互沿用前述报告，不把跨批次结果合称全项目回归。所有本次窗口检查UI SCREENSHOTS:none，未发送真实反馈，未新增旧档适配。当前v0.17仍有其他在途功能，未宣告里程碑完成或触发版本提交／推送／打包。

## 2026-09-14 场景拆分与立绘按需刷新

域：契约 `ui-scene-refresh.md`。

- 主布局、顶栏、身体栏、角色立绘、敌人分组、装备立绘拆为 6 个 `.tscn`；运行代码仍消费原 View 和候选。没有合并旧 PR、改变规则、重写文案、修改版本或发布包。规则说明与影响边界见 `docs/ui-scene-refresh.md`。
- `display` 增加真实绘制计数和实例身份检查：连续三次普通界面更新保留布局、主角、敌人和装备立绘，三个立绘绘制计数均为 0；程序绘制敌人静置 12 帧重绘 0 次；没有空闲 `_process`，姿势恢复、固定立绘忽略无关变化、无关／对应素材变更和游戏快照只读均检查。
- 初轮 `20260914T031721707-1144`：display／equipment_art／hero_art 共 326 项通过、源码指纹稳定。补充固定立绘和素材变更反例后 display 为 111 项。
- 扩展检查发现复用身体栏与商店新面板的鼠标层序冲突，已在本批次修正：身体栏恢复原兄弟顺序，不再只依赖 z_index；收起时释放该栏。原有真实鼠标检查保留，未放宽断言。临时定位输出已移除。
- 修复后 `20260914T032632664-30612`：display 111、services 255、consumables 49、rewards 307 项全部通过；interface 353 项中 352 通过，唯一失败是工作区已有 17 张新增魔女卡牌缺少插图。合计 1075 项、1074 通过；不标成整组通过。此前 body_layout 97、targeting 91、installed_tools 43、home 110、route 134、equipment_art 168、hero_art 50 项通过，详见 `20260914T032010796-7892`，该报告包含已修复的界面失败，不作为全绿证据。
- 移除临时诊断打印后的连续切页收尾报告 `20260914T033053718-6868`：display／home／route／services／consumables 全部通过；interface 仍只剩上述魔女卡图缺失，合计 1012 项、1011 通过。没有放宽原交互断言，也未把已知失败标绿；运行前后源码指纹一致。
- 其他在途门禁问题保留：`20260914T031830111-47100` 的 architecture 69 项通过，runner 因 `witch_character_cases.gd` 尚未登记归属失败；`20260914T032010796-7892` 的 localization 因新增主页角色选择文字缺英文失败。没有覆盖这些在途功能或删除失败检查。
- 各次检查使用独立 APPDATA、既有检查入口和限定分类，`UI SCREENSHOTS: none`；没有新增验收截图，也未发送真实反馈。大版本完成后自动提交推送源码的规则已写入两级 AGENTS.md，本次不提前发布在途 v0.17。

## 2026-09-14 角色2平衡修订验收

域：契约 `character-two.md`。

- 规则与界面范围见AGENTS.md「角色2第二批平衡修订」、docs/character-two.md。最终补充开局Boss交换按角色实际初始遗物读取名称、资格并移除正确遗物；不能仍向角色2索取余烬护符。
- 稳定检查20260913T141159390-60236：core/relics/casting -Impact一次展开22个相关完整分类，8983项规则断言通过；home/status窗口168项通过。涵盖原角色回归、专属新局75/75/50与护符、战斗阶段限制、新遗物、2层抵挡、分部位伤害/清空、精神集中保留和乌龟壳、失败退款与减层、分面消耗、增伤预览、原生切换及自动回切。
- 最后开局交换及内容补全后，稳定检查20260913T141724506-31156：localization/encyclopedia/content/services/persistence/core共2575项通过，home窗口110项通过。追加魔术手实际连续降低4档（部位目标移除后顺延全身）、30魔力只付一次、过期回滚、最终消耗一次及真实开局遗物交换；没有用只读定义断言代替实际执行。
- 首轮core失败源于伤害调整后旧胜利夹具仍按旧伤害假设击杀；调整明确夹具蓄力层数后复验。首次扩大检查遇到新SVG尚未导入造成预加载错误，随后通过正式-Import导入再完整重验；失败报告保留，不宣称其为通过。
- 两份通过报告各自源码前后指纹一致；不把不同源码批次合并宣称全项目all。git diff --check通过；无全量all、长程随机试玩、打包或发布。当前源码保留其他任务既有修改；旧0.17交付ZIP不覆盖。

## 2026-09-14 角色2平衡版Windows完整包

域：角色与美术、打包与发布。

用户授权打包当前项目，本地交付、不发布。build/package-witch-balance-20260914导出源码指纹前后一致；成品check-package -ChargeAll -WitchBalance通过，日志build/package-check-20260913T143629354。验证0.17版本、原角色/角色2、75魔力与快感上限、50魔瓶魔力、魔女护符、魔术手新效果、两件专属SVG、12份外部内容包、存档与真实释放清空、独立EXE启动。最初成品探针沿旧夹具注入100魔力超过新75上限，故被正式提交校验拒绝；修正探针按实际mana_max补满后通过，未修改玩法。

ZIP解压后逐一核对23份文件的大小与SHA256，总计24 个文件含manifest，全部一致。交付紧缚尖塔demo-v0.17-角色2平衡更新-Windows64.zip，135294326 字节，SHA256：3d948be397b926f59884d4d34e706f0c40e13e46884d0d07afd26f356c3fdb08。未覆盖旧交付、未含存档，不制作Android。此前功能专项记录保留，本次只做成品检查。

## 2026-09-14 反馈1847ba708526785c2322abae5cdd7561

域：战斗与敌人、架构与接口。

用户确认截图开局启用了无限效果模式。反馈文本是第8层战后整备、截图是第11层第50回合；缺少实际存档，不声称按种子精确重放了两者之间的整局操作。以该种子、两名mixed_bundle、无限模式高保留系数建立明确状态夹具，经正式end复现每轮0能量和持续中断：回合增加，敌人每轮只执行一次；首次草拟夹具在开场后才切卧姿，会合法跨越“旧回合玩家先手、下一回合敌人先手”的两个敌人阶段，已改为开场前设置真实卧姿，不能把前者误报为重复结算。

根因：无限模式的回落值接近阈值，回合开始的持续来源再次触发强制状态；同时原surrender候选排除了overloaded，导致普通行动与投降都隐藏。修复保留战斗中的正式投降、原二次确认、版本复核与完整收押事务，不调整无限效果、资源、敌人行为或end管线。普通警戒进入牢房后仍可能继续受设备影响，不强行清除该模式；截图警戒4时投降沿原规则进入警戒5的终局。整备复现从3回合连续提交至0并回地图，已击败敌人不再施加装备。

验证：20260913T185256036-42504改动前最小回归仅“中断期间保留投降出口”失败，确认覆盖缺陷。扩大交叉检查20260913T185329577-34216的其余12分类通过；pressure两条旧预期分别错误地要求入狱不再受无限效果、练习只允许继续，已按本次规则修正。最终20260913T185531623-49552：prison/pressure完整规则1753项、pressure窗口79项全部通过，源码前后指纹一致。覆盖反复继续、不重复敌方阶段、整备结束、版本过期回滚、重复投降拒绝、普通/警戒4退出路径以及实际投降按钮两次点击。git diff --check通过。未运行全项目all，未改或重新打包已交付0.16/0.17文件。

## 2026-09-14 离场怪附加装备加强

域：装备与解除、战斗与敌人。

RuleChangePackage：离场施加统一中级／紧度3。Balance登记离场grade=2/tier=3，EnemyPlans.application对final声明统一使用；安装能力扫描与实际意图同源。漂浮锁固定平板锁来源同用常量，开启锁池后维持固定类型／无概率／无法佩戴仍离场，正常紧度3规则自动附带中级加固带。漂浮口球由初级2档升至中级3档；四种基础材料怪由中级2档升至中级3档。原非离场施加仍初级2档，其他持续型敌人不变。

影响等级、紧度、所导出的耐久／部位限制与附属组件；资格、模板池、数量、锁规则、来源、替换、回合、准备／打断、失败离场、死亡取消、奖励、随机域、存档结构不新增接口或分支。原安装与日志直接使用新规格；图鉴中英及词表同步。十四交互轴仅等级／紧度及原规则连带效果改变。既有enemies案例覆盖实际附加、非离场反例、打断／死亡、无空位、概率两端、存读和奖励；窗口检查真实口球附着规格。不打包。

## 2026-09-14 魔路精通与 henshin 费用

域：契约 `game-design.md`。

用户最终确认为两个角色共同更新、henshin拘束面＋1（3费）、自由仍4费；魔路精通两面互斥，不同时存在。RuleChangePackage见game-design.md同名章节。卡牌说明、状态条件／次数、失败实付来源退款和回能日志、互斥候选拒绝、中英文资源均同步；不重发旧版安装包。

最小及边界案例沿card_power扩展：纯自身／混合／纯临时支付、正数耗魔条件、实际0费卡前两次及第三次、成功及复放反例、2/2→3/2→3/3→2/3动态限制、降级不刷新配额、下一回合重置、失去／恢复等级、两角色共享注册、同面及另一面重复提交原子拒绝、存档次数及非法状态、整备清理、henshin普通与完美版分面费用。旧henshin批量解除和捕缚案例按3费修正输入与付费期望，非费用机制保持。

初轮card_power有1条批量解除旧2费断言失败，源码期间还受到其他批次修改，不记通过；后续修正。英文兼容表初次追加用了printf形式目标参数，被加载器正确拒绝；改用{p0}后localization通过。20260914T051707385-38532中localization 68与card_power 1596通过，其card_expansion有3条捕缚夹具仍给2能量而失败。修正夹具后20260914T051755588-46308：card_expansion 1082、architecture 69、content 380、casting 564、persistence 585全部通过，源码指纹稳定。core仅TC-ENEMY-0003的敌人离场紧度旧2档断言失败：工作区另有离场附加改成中级3档的修改，不由本次卡牌调整引起，本次没有覆盖该改动或将core记为通过。

验证：首轮build/checks/20260914T051444647-46880/summary.json的唯一规则失败为混合遭遇口球旧初级断言，已同步为中级3档，并补齐练习入口旧文案。复跑build/checks/20260914T051739888-16116/summary.json：enemies/architecture/content/localization规则2278项、enemies窗口213项全部通过；同期其他任务修改源码，整轮状态为source_changed，不声明冻结版本整体Verified。新规格、平板锁加固带、原离场边界与实际界面操作均无断言失败。本批未截图、打包、发布或推送大版本。

## 2026-09-14 传送符入狱保留

域：监狱与收押、检查与测试。

RuleChangePackage：传送符声明 keep_on_capture，统一收押流程过滤没收名单并按实际移除数量记录；主动投降、敌人收押及五级监室均保留原实例、次数与顺序。无需新存档字段或迁移，不重复发放。其他道具仍没收，巡视检查、使用消耗、主动丢弃、使用资格、容量、回合、随机和装备规则不变。十四交互轴仅涉及道具生命周期与收押，其他不变。

玩家文案同步道具详情、图鉴共用说明、收押词条、教程及警卫练习说明和英文回退。机械日志继续报告真实没收数量，无新增叙事事件。复用 prison／guard／architecture／content／localization 分类，覆盖实际投降与敌人收押、五级边界、旧候选回滚、实例次数保持、快照恢复、普通道具反例与共享说明；不新增窗口、截图、打包或发布。

20260914T051926160-7184：relics 786项及card_power窗口302项断言全部通过，但运行期间其他批次源码改动导致source_changed。补做20260914T052204848-40212，同样786项规则／302项窗口断言通过，仍检测到工作区源码变化，因此两次均不标记稳定源码整体门禁通过，不无限重跑并行修改中的工作区。既有稳定运行中的card_power、localization、card_expansion、architecture、content、casting、persistence结果分别保留；core的无关旧敌人数值断言仍如实记失败。git diff --check无空白错误。本批源码完成，未打包、提交、推送或发布，不作为新的大版本里程碑完成声明。

验证完成：20260914T052724734-42644 的 localization／architecture／content／prison 通过；guard 最后一条回滚断言误把恢复后递增的版本号与原快照比较，改为与恢复后的提交前快照比较。20260914T053035005-44188 仅重跑 guard，40项通过。相关五分类合计1336项通过，两次最终运行均无 source_changed；非全项目回归，不打包。此前失败包括旧“再次收押没收传送符”断言及入狱背包必须为空的校验，均已修正。收押阶段校验与存档恢复现只允许带 keep_on_capture 的道具保留，其他道具夹带仍拒绝且回滚。

## 2026-09-14 体术动作格字号与居中

域：契约 `game-design.md`。

名称与实际伤害以整行测量后同排居中，默认18号、长招式最低16号；费用／标签居中显示，默认14号、长行最低12号。右下快捷键维持11号原样并预留对称安全区；轨道、候选、点击／右键切换／拖动／禁用条件不变。具体RuleChangePackage见game-design.md对应章节。

20260914T053122276-45688：architecture 69＋basic_attacks窗口79项通过，源码稳定。检查现有ui-basic-action-rail.png及ui-basic-attack-forms.png发现火球费用标签尾部省略，改为紧凑分隔并按长度适配字号。20260914T053334413-42704：basic_attacks 84、touch 18、keyboard 67项窗口断言全部通过；期间工作区其他main.gd改动造成source_changed，不能作为整体稳定通过。最终20260914T053516805-25700：basic_attacks 82项通过、源码指纹一致（不启用截图，因此比带截图运行少2项）。截图已人工查看名称／伤害同排、连击长名完整、火球费用／次数／成功率完整、快捷键无遮挡。git diff --check无空白错误。不打包、不发布，不修改正在进行的其他装备UI改动。

## 2026-09-14 墙缝道具遮挡与捕缚移动限制

域：塔路与地图、界面。

RuleChangePackage：UI安装工具面板从魔瓶区域移至体术栏右侧／非战斗手牌上方；体术格仅在存在已安装工具时预留宽度。CaptureBind提供共用移动拒绝原因，wall_move候选与正式提交复核禁止捕缚中的两方向移动，移动按钮灰置并直接解释。状态／图鉴／教程与英文兼容目录和人工词表同步。影响捕缚行动资格及界面布局，无新增状态、事件、随机、存档字段或迁移；能量、距离、姿势原规则、装备／层级／锁／材料／目标、伤害、工具触发／次数、回合与其余十四交互轴不变。拒绝无机械日志；已有捕缚与移动成功日志保持准确，非UI叙事N/A。

最小正例、无捕缚反例、两方向边界、旧候选复核和原子回滚加入wall现有分类，覆盖三种来源及解除恢复。guard窗口验证真实第三回合施加后按钮灰置和具体原因；installed_tools窗口验证面板不覆盖魔瓶／体术、真实鼠标存入与新入口打开。复用完整wall／guard／installed_tools／enemies／content／localization／architecture规则及installed_tools／guard／wall窗口；结果待记录。本批不截图、不打包、不发布。


本批结果：20260914T054719458-47044 的七项规则分类2530项全部通过，installed_tools与guard窗口通过；wall窗口发现禁用提示挤入姿势行及另一批身体详情改动的空脖颈缺失。已修正本次提示布局：紧凑行直接显示具体拒绝原因，普通贴墙状态保持距离提示；非战斗工具栏缩至32高并压缩内边距，验证与真实手牌、魔瓶均不重叠。20260914T060238373-44540 相关六类规则769项通过；wall窗口的移动布局及新非战斗面板断言通过，仅空脖颈详情旧检查仍失败。guard新增位置断言初版没有处理高潮时无姿势栏的情况，已改为检查存在时不重叠。

最终20260914T060515825-18304：installed_tools／guard完整窗口95项全部通过，源码指纹稳定。实测安装后魔瓶存入、工具入口打开和真实捕缚移动灰置；前两轮规则运行期间存在其他任务修改，按source_changed保留单类结果，不声明整个工作区全量通过。颈部详情断言属于另一批在途身体栏改动，未在本批覆盖或放宽；未打包、发布或推送。git diff --check通过。

## 2026-09-14 角色选择名称

域：界面、检查与测试。

RuleChangePackage：选择页角色1改为“魔法少女(futa)”，角色2改为“小魔女·测试版”。通过两个独立本地化ID显示，中英文与中文安全回退同步；内部original／witch标识、顺序、选中角色、新开／继续流程、角色规则和存档均保持。仅UI名称受影响，候选、数值、事务、事件／日志、非UI叙事、随机及十四规则交互轴N/A。既有witch_character窗口检查准确名称、选中后新局及切回原角色；localization／architecture分类复核资源与边界。不截图、不打包。

## 2026-09-14 魔力耳坠阈值30

域：压力与快感、检查与测试。

RuleChangePackage：每累计消耗自身魔力30点获得1能量，替换原20点。统一遗物注册数值、效果说明、英文回退与规则对照；计数显示和校验沿同一阈值读取。触发阶段、跨回合余数、本场结束清零、临时魔力排除、失败施法及退款逻辑不变；不增加状态、候选、随机或存档字段，其他交互轴不变。既有具名触发日志无须改写。复用 relics／card_expansion／casting／architecture／content／localization 完整分类，覆盖20不触发、29边界、30触发、跨回合与多阈值、兑换及余火交互；不打包。


验证：20260914T061242279-41644 的localization／architecture共137项通过。窗口分类最初误填witch_character（实际由home分类加载），未执行有效窗口案例；改用正式home完整分类。20260914T061525492-47556共111项检查，仅平板锁练习的上锁／加固带可见说明断言失败；本次两个名称、角色2开局及切回角色1的实际流程断言均通过。该失败涉及另一批在途装备详情UI，未修改或放宽；运行期间源码变化，整轮不标记通过。不打包。

魔力耳坠验证：20260914T061541360-47872 的 localization／card_expansion／relics／architecture／content／casting 六分类共2952项断言全部通过。运行期间工作区存在并行源码修改，门禁结果为 source_changed，因此不声称最终合并版本冻结通过；未打包或发布。

## 2026-09-14 四区解缚界面预览

域：契约 `release-interface.md`。

RuleChangePackage：docs/release-interface.md。UI 四区/单区展开、同部位外内层、共享物理目标去重、正式端点候选、前后耐久及衰减短提示；特殊装备仍显示电量与当前状态，长说明/公式按需展开。原动作资格和事务不变，不打包或发布。

20260914T060525904-40228：body_layout、targeting、equipment_complete、keyboard、touch 共359项窗口断言通过，源码指纹一致。含真实鼠标拖放、自由区域拒绝、跨区域目标替换、单目标预览与实际扣费/伤害一致、无回合检查和旧版本拒绝。之后增加特殊装备状态显示，并修正共享连接绳候选必须匹配当前部位。20260914T061425186-6328：special_equipment、body_layout、targeting 共228项全部通过，但并行工作区改动使该次状态为source_changed，不能作为最终稳定版本的发布门禁。

20260914T060525909-13704：localization 68项、architecture 69项通过；equipment的新增只读预览、零伤害、限制项圈开锁/取下事务案例通过。该完整分类154项中仍有4条 POOL grade independent of application tier（rope/belt/tape/cable_tie）断言失败，关联正在调整的敌人生成等级/紧度，本次未改其规则或旧期望值。display在20260914T055250277-45188中的场景复用检查通过，但 DUCK MUSIC repeated actual soup play preserves progress 未通过；未宣称整个display分类通过，未修改音乐逻辑。

预览图为显式选择的 build/ui-release-region-panel.png 和 build/ui-release-numeric-panel.png，仅截取区域入口与解缚详情，已人工检查外内层顺序、数值/倍率及按钮排版。未运行全项目发布检测。

最终窗口复核 20260914T061735866-22176：special_equipment、body_layout、targeting 共230项通过（含两张局部截图）；仍发生外部源码变动，状态source_changed。停止重复整批窗口测试，不将并行变化中的工作区标记为稳定发布版本。本次交付为可评审UI预览。

英文补充最终复核 20260914T062045304-684：localization 69项通过，源码指纹一致，包含四区动态件数及特殊装备主体标签。

## 2026-09-14 监狱期限与起点选择

域：契约 `prison-release.md`。

- RuleChangePackage见`docs/prison-release.md`。已实现分级刑期、单次检查最多延长8回合、到期施加与自动出狱、出口稀有三选一／遗物／60魔瓶奖励、8—10层非休息起点、倍率后的安全等级生命加成，以及两项正式流程练习。快照52，不迁移旧档，不打包或发布。
- 首轮`20260914T061623932-45708`：architecture通过，prison旧的连续巡视夹具因新刑期提前结束而失败；已将该夹具的后两次巡视倒计时设为1，继续验证真实检查／登记而不与独立刑期案例互相覆盖。
- `20260914T061906250-44988`：architecture69、content380、persistence593、rewards672、prison869、enemies1761，共4344项规则通过。运行期间补了召唤物跨收押的生命加成记录和英文文案，不视为最终完整指纹证明。
- 主页原先依赖练习顺序的音乐入口已恢复原顺序；新增出狱练习列于现有条目之后。`20260914T062451809-47736`：home111项仍有一条原有平板锁详情检查失败，与本批监狱规则和新增入口无关，未修改其断言或把该组标为通过。
- 复查`20260914T062524537-46312`：localization69、persistence593、prison870、enemies1761，共3293项规则通过；route134、prison155项窗口检查通过，运行前后源码指纹稳定。随后按用户补充排除宝箱房，相关规则、窗口文字与反例同步，并另跑最终专项。

- 用户补充“宝箱房也不能选”后，正式入口仅允许8／9／10层的battle／event／shop；rest／treasure同时拒绝，文案及英文同步。`20260914T063040663-3304`：localization69、content380、prison913，共1362项规则及prison155项窗口通过，源码指纹稳定。新增范围矩阵及真实非法depart拒绝／状态不变反例，没有用页面隐藏代替规则拒绝。
- 最后只补巡视确认前的处罚提示与英文，规则数值保持；另跑localization／content与prison窗口，结果随后记录。

- 最终提示复查`20260914T063524115-5108`：localization69、content380和prison窗口156项全部通过，源码指纹稳定；检查前处罚提示通过实际窗口断言。相关实现已完成，已知主页失败保持记录，不打包。

## 2026-09-14 自缚正式接入

域：装备与解除、卡牌与奖励。

稳定ID：self_binding；名称：自缚；正式生成：罕见X费技能，加入UNCOMMON／REWARDS，沿原商店、休息罕见选择、普通奖励与图鉴入口，两名角色共用。无保留／消耗／唯一标签，打出后正常弃置；沿已有self_binding.svg。

自由面：腿部随机佩戴2件普通拘束具，每件品质＋紧度＝2X；具体池为绳索／细绳／皮带／细皮带／胶带／扎带，腿部五类身体槽与精准位置、层级、容量均使用现有安装资格。无上锁、替换、链接或特殊装备生成。先确认存在可完整安装的两件组合；随机第一件必须给第二件留出合法位置，不能部分执行后回魔。主动佩戴属于卡牌代价，明确以Application内部voluntary参数跳过闪避与魔女蓄力抵挡，不消耗这两类状态；原敌人／事件施加默认仍可被抵挡，参数没有接为独立玩家命令。

拘束面：按原可加固的真实普通件／复合组件／独立肩带随机逐档收紧，总计2X档；紧度已3不算可收紧空间，不触发上锁额度，也不靠补附件凑档。实际收紧沿_reinforce_equipment与原刷新规则，原有锁不变，正常到3档的附属效果保留。当前完整容量小于2X时禁用整张牌；不改变装备、不扣能量、不回魔。两面完整执行后恢复15X自身魔力，受原上限限制，临时魔力／魔瓶不作为这项回魔目标。

X为打出前全部剩余能量，候选保存X并由原事务支付。自由面X=0或X>3没有合法品质／紧度组合而禁用；拘束面X=0可以打出但不收紧、不回魔，X>3只要容量足够即可。复放沿用原X并重新检查剩余容量，不能完整执行则跳过该次复放，不追加回魔。休息房禁止自由效果等原阶段规则保持。

RuleChangePackage：影响卡牌定义／双面区别、共用X费用、随机装备选择、收紧、回魔、奖励池与玩家说明；不增加GameState／快照字段、随机域或UI直写入口。预演临时隔离并恢复状态和反馈，不消耗随机、不写外部日志；实际装备／收紧／实回魔以结构化事件进入原行动摘要与日志。手牌、图鉴保留完整2X／15X公式和不足禁用说明，具体预览同时展示当前X与收益；英文目录及词表同步。十四交互轴仅费用、品质／紧度、现有安装资格／容量、装备触发、资源回报与原复放相关，姿势、伤害、施法、回合、捕缚、特殊装备与其他规则不变。

验证用例归既有card_power，覆盖X=0/1/2/3/4、每件独立求和、只剩1位置拒绝／恰好2位置成功、无替换、收紧不足原子拒绝、预览只读、旧版本拒绝、回魔封顶、免费复放继承X／不足跳过、实际存读不重复、两角色与抵挡边界、休息自由禁用。窗口沿card_power，核对X费、原图、罕见与完整文案、实际点击佩戴及不足时零变化；rewards验证正式随机池可达，application验证原施加行为。不新增套件，不截图、不打包。


自缚验证结果：20260914T065430605-47564 的card_power／application／architecture／content共2179项通过，源码指纹稳定。补齐角色2／休息边界及英文后，20260914T065903980-45828 的localization／card_power／application／architecture／content／rewards共2917项全部通过，正式奖励抽样包含自缚。窗口初次两条失败来自测试在首次渲染前设置牌面被原抽牌定向覆盖，改为首次显示后通过真实右键翻面；未改游戏默认牌面。20260914T070308720-44332 的完整card_power窗口307项全部通过，包含X费、原图、完整公式、实际两件佩戴与空间不足无变化。后两轮因同时进行的其他工作区修改标记source_changed，不声称冻结源码全量门禁通过，也不无限重跑其他任务的在途改动。git diff --check通过；不截图、打包或发布。

## 2026-09-14 秘密武器

域：装备与解除、压力与快感。

稀有奖励遗物，加入普通奖励、宝箱、商店与套娃稀有来源。脚趾可代替手部施法，选手部／脚趾合法路线中的较高成功率；独立口部路线、无部位和明确身体豁免仍按原规则。脚趾只要有真实覆盖拘束便不可用于施法，最终成功率为0%，必成与最低成功率不能绕过。脚趾代替的是施法，不放开握持、工具、药剂或体术的手部条件；火球手势和控火手部施法条件可由脚趾满足。

持有时，空脚趾施加优先级从普通档提升至嘴部／手指同档，仅次于空手腕；已有脚趾装备仍落回原追加档。来源模板、精准部位、容量、层级、合法性、闪避与替换机制不变，不更改卡牌超级顺延的解除排序。

用户授权自行调数值：牵扯按真实覆盖脚趾的每个物理件品质＋当前紧度合计2／3／4／5／6，分别增加1／2／3／4／6基础快感，多件累加。每次花能量的行动触发一次，2能量不额外倍增；熟练而已的额外牵扯同样触发。复用原快感来源倍率（含大理石、平板锁等）、上限保护与高潮结算，无新增敏感度倍率。普通／复合覆盖共用equipment_at，拾取时已有拘束立即生效，降档立即重算，解除后停止。现有特殊装备没有通用品质紧度表，本表只属于秘密武器，不回写特殊装备规则。

RuleChangePackage：状态为遗物持有及实时派生牵扯；无新存档字段、随机域或迁移。候选／事务涉及施法部位准入、最高概率选择、统一施加优先级、统一消耗能量牵扯；数值注册于遗物表，结构化法术事件保留hand类别并新增实际source_part。其他交互轴包括锁／层序／姿势／工具／移动／资源／魔力池／回合均沿原规则；未涉及的规则不改。玩家可见文字覆盖稀有遗物效果及分档、专属SVG图标、图鉴共用展示、手部／脚趾概率对比、拒绝原因、真实施法来源日志、行动风险与状态详情，英文回退同步。无新增文学叙事，现有通用施法叙事沿用。

测试并入relics下secret_weapon_cases，覆盖casting／installation_priority／pressure／persistence交互，不复制到多套件；复用casting窗口验证图标、概率、禁用及实时状态，无截图。相关完整规则分类relics／casting／installation_priority／application／pressure／architecture／content／localization；不打包或发布。

## 2026-09-14 魔血平衡调整

域：契约 `verification.md`。

RuleChangePackage：魔血力量加成3→2、稀有→罕见，共用定义同步奖励池、商店定价、图鉴与中英文说明。每玩家回合开始快感＋5保持；既有实例按稳定遗物ID读取新值，无需存档迁移，不改变已冻结商品价格。正式体术／挣扎属性读取共用修正，不新增状态、事务、事件、随机域或叙事。十四交互轴除力量数值外保持。更新rewards规则／窗口现有真实伤害与奖励池断言，覆盖回合效果、预览只读、失败不变和存读档；content／localization复核共用说明，不打包。验证结果见docs/verification.md后续记录。

秘密武器验证：20260914T071730474-48696 的 localization 70项通过；修正测试中近身短打要求双腿自由的夹具，改用2能量接连挣动，并修复无捕缚时原能量上下文为0导致漏触发的问题。20260914T071956026-8264 的 relics／application／architecture／installation_priority／content／casting／pressure 共2990项通过，casting窗口55项通过。合计相关规则3060项、窗口55项，无新增截图。最后运行因并行源码修改标记 source_changed，仅记录断言通过，不声称最终合并版本冻结通过；不打包、提交或发布。

## 2026-09-14 自适应分区与紧凑解缚详情

域：契约 `release-interface.md`。

RuleChangePackage见docs/release-interface.md。身体框与分区列收窄，小部位字体放大，按实际高度保留多区，溢出按开启顺序收起；单区过长内部滚动。详情缩小图标及空白，手胸／臀腿显示正式小数严密度，确认按钮固定页脚。高亮保留按钮边距，避免拖牌时几何变化。无规则、存档、数值或事件变更。

20260914T071957134-48380：architecture／localization共139项通过；body_layout／targeting／equipment_complete／keyboard／touch共403项通过，含精确高度及少1像素、单区滚动、多个展开、刷新只读、小数严密度、固定确认按钮、真实拖牌与出牌结算。此前窗口失败暴露高亮覆盖紧凑边距及确认按钮被滚动裁切，修复后原断言通过。当前有其他任务同时修改源码，检查器标记source_changed，不能作为冻结工作区或发布门禁通过证明；不追加全量测试。已查看build/ui-release-region-panel.png、ui-release-adaptive-panel.png及ui-release-numeric-panel.png，确认标题数值横排、层级列表及固定页脚无裁切。不打包或发布。

## 2026-09-14 奖励页顶部遮罩接缝

域：`tests/reward_ui_cases.gd`。

RuleChangePackage：顶栏高62，旧奖励遮罩从78开始，漏出16像素背景。普通奖励／套娃／开场奖励共用reward_backdrop，读取实际GameHeader底边并换算奖励容器局部坐标，遮罩覆盖到底部900，保持各奖励内容位置与原透明度。顶栏继续可访问；没有新文本，changedUiAndLogs=N/A（仅消除背景接缝，原标签、日志不变）。状态、规则、候选、资源、回合、随机和存档及其他交互轴均不变。rewards／home窗口沿已有真实领奖流程核对三种布局的遮罩全宽、上下边缘及顶栏排除，复用architecture；不新增截图、不打包、不发布。


2026-09-14 魔血：已改为罕见、力量＋2，回合开始快感＋5保持；新生成商店按罕见65魔力定价。localization／content／rewards规则1116项通过；rewards窗口309项中仅双重解锁提示断言失败（tests/reward_ui_cases.gd:138），魔血图标、真实回合与＋2伤害预览检查通过。同期其他源码仍在变化，报告为source_changed，不记整批或冻结全量通过。报告spire-godot/build/checks/20260914T072117822-45376/summary.json；未打包。

2026-09-14 马眼棒立绘差分依附平板锁：`SpecialEquipment.portrait_layers`要求任意平板锁与导尿管／独立马眼棒条件同时成立，单独马眼棒不再错误叠加基于锁体制作的差分。既有普通平板锁无差分、导尿管平板锁有差分用例保持，并新增普通平板锁＋独立马眼棒及单独马眼棒反例。`20260914T072907893-49312`的architecture规则69项、equipment_art／hero_art窗口219项全部通过，源码前后指纹一致；未重做素材、截图、打包或发布。

遮罩验证：20260914T072428777-48320 architecture 69项通过；home执行113项，本次开场奖励遮罩两项通过，另有既有PLATE LOCK HOME状态／加固带文字检查失败。20260914T072536852-40220 rewards执行313项，本次普通与套娃遮罩四项通过，另有REWARD UI final unlock segment does not promise a third lock文案检查失败，且运行期间并行修改导致source_changed。未改动这两项无关文案／行为，不宣称完整UI门禁通过；无截图、打包或发布。

## 2026-09-14 出狱临时检查与显示楼层校正

域：契约 `prison-release.md`。

- 以地图实际显示的10—11层为准（内部9／10），候选与中文／英文说明同步，继续排除休息与宝箱。出狱到期在同一正式结束回合中自动执行一次正常规则的临时检查；违规处罚且最多追加8回合，下次到期重新检查。通过才执行出狱装备判定并打开起点选择。
- 临时检查不插入回合、不改变正常巡视倒计时；同回合正常巡视仍按期到来。持钥匙或反抗时正常巡视暂停，但到期检查仍执行。复用已有检查次数与延期字段，不提升快照52、不迁移、不打包。
- `20260914T072424293-48388`：localization70、architecture69、content380、persistence593、prison935，共2047项规则通过；route134、prison160，共294项窗口通过。案例含重复延期、多类违规只加一次、周期同回合边界、钥匙暂停、过期命令原子拒绝、保存恢复、显示楼层边界与正式延期后继续操作。
- 报告为`source_changed`：测试期间另有departure_ui_cases、release_view、英文目录、equipment_art_ui_cases与special_equipment修改；未把用例通过写成固定源码整批门禁通过。本任务代码未因这些修改回滚或覆盖，相关实现记录见`docs/prison-release.md`。

## 2026-09-14 更新出狱练习入口

域：契约 `prison-release.md`。

- 练习菜单现在分别提供检查通过、违规延期、击败出口守卫。前两项均从19／20回合开始；延期项由真实道具工厂预装一件低墙缝小石片，包含正式墙面位置，玩家结束回合后真实没收并延长8回合。再实际完成8回合，正常临时检查通过并打开10—11层起点选择。守卫练习说明同步稀有三选一、遗物、60魔瓶及起点范围；菜单和开场提示均有英文。
- RuleChangePackage见`docs/prison-release.md`；只改练习配置、对应初始化与文案，不新增正式规则、存档字段或旁路命令。窗口检查直接从新练习按钮进入，已删除测试里手工制造缺装的替代夹具。
- 首轮`20260914T074055848-35216`：localization70、architecture69、content380通过；prison发现预装工具缺少具体墙缝位置，已补上`Space.attachment_position`。
- 修复复查`20260914T074248079-46568`：prison959项规则、prison170项真实窗口用例全部通过，包括有效初始化、没收、期限／正常周期、保存恢复、8个实际回合和新地图选择。运行期间其他源码有同期变化，报告为`source_changed`，不宣称固定源码的整批门禁通过。没有打包或发布。

## 2026-09-14 战斗施加后自动展开身体区域

域：战斗与敌人、装备与解除。

RuleChangePackage：正式行动成功后，以提交前后只读body_regions.targets的物理ID对比确认新增或替换的拘束具，自动展开受影响区域并更新展开顺序；普通、复合、链接及特殊装备均复用其正式区域投影。仅战斗内动作生效（包含该动作结算进入奖励／整备），不在开局、读档、SL、非战斗行动、普通重绘或失败提交时自动展开。同件纯加固／降档不触发；手动收起保持到后续真实施加。只展开左侧区域，不选择装备、不弹出详情、不派发额外动作；空间不足继续按实际高度收起旧区域，最新区域可内部滚动。

不新增游戏状态、存档、随机或事件，不改变施加资格、数量、部位、层级、费用、回合及十四规则交互轴。玩家文案N/A：使用已有区域名称、计数、展开／收起标志；无新日志或叙事。body_layout窗口补真实结束回合施加、旧版本拒绝、同数量替换、手动收起与刷新、加固反例、非战斗隔离及只读断言；复用architecture与display窗口覆盖场景刷新边界，不打包。

## 2026-09-14 基础动作部位与左侧能量徽标

域：装备与解除、压力与快感。

RuleChangePackage：基础动作栏统一采用32像素左侧能量徽标（复用energy-medallion.svg，数字读取candidate.cost），右侧主行显示名称与伤害，次行显示部位、耗魔、次数和成功率。删除主副两行的重复能量消费字样，0费与不可用状态均保持徽标；右下快捷键不变。深呼吸同样采用徽标，并保留次回合回能效果说明，它不是当前费用。使用部位由只读GameView投影：肘击双臂，近身短打双臂／双腿，踢击双腿，魔法采用正式casting.source_part，覆盖秘密武器脚趾替代、魔女部位及无部位施法。深呼吸读既有正式嘴部判定与效果。

没有修改费用、伤害、施法、部位资格或动作规则。点击、拖拽、右键换式、快捷键、禁用原因和详细悬停继续用原候选；日志N/A（原结算事件未变），结构化状态、回合、随机、存档与其余交互轴不变。中英部位／效果文案同步，窗口检查费用徽标的0／1切换、部位说明、文字与徽标不重叠、热点保留及实际付款。运行basic_attacks／architecture／localization规则和basic_attacks／casting窗口，不新增截图、不打包。


2026-09-14 战斗施加自动展开：正式提交成功后按区域投影中新增物理ID展开左侧对应区域，兼容同数量替换；手动收起不被普通刷新重开、不弹详情。body_layout完整窗口145项通过且源码稳定，报告spire-godot/build/checks/20260914T075354234-48868/summary.json。首轮architecture69项通过；display窗口另有语言切换后身体标签旧断言失败，本批不改翻译路径，未记跨分类全绿；首轮新增测试误用行动分组已修正并完整复测body_layout。未打包。


2026-09-14 基础动作栏验证：build/checks/20260914T075316120-20556 中 localization 71、basic_attacks 181、architecture 69，共321项规则断言通过；basic_attacks 87、casting 55，共142项窗口断言通过。覆盖左侧0/1费用徽标、部位只读投影、文字对齐及真实点击/拖拽/招式切换。运行期间其他任务修改源码，报告为 source_changed，不宣称固定源码整批门禁通过。同步修复阻止语言包加载的已有守卫增援英文占位符格式；不打包、不发布。

## 2026-09-14 监狱探索警卫战援军

域：契约 `prison-reinforcements.md`。

按用户最终要求做成战场负面效果，开战起每4个完整回合召来1名警卫，全场上限1＋警戒度，胜利立刻取消；出逃战不生效。RuleChangePackage与规则边界见docs/prison-reinforcements.md。复用正式敌人创建、结束回合、状态投影、存档复核；新警卫出生回合不行动，先手／后手及原警卫阵亡均不改变场地时钟。

20260914T075204241-16528：prison 1135、guard 40、status 299、intent 89、architecture 69、content 380项通过；新增用例包含4回合边界、警戒度1／2／4上限、打断不中止、原警卫阵亡、胜利取消、奖励整备、出逃排除、存读档重放、过期提交及坏存档原子拒绝。该轮localization因英文参数格式被拒绝，随后词条改为兼容包的{pN}格式；20260914T075522198-20088 localization 71项通过，guard窗口69项通过，验证常驻倒计时、新警卫真实目标和共享计数。首次测试误期望返回牢房后保留已退场敌人列表，按原正式清场行为改为列表为空，并保留无召唤事件断言。工作区存在其他任务并行修改，source_changed不作为冻结源码／发布门禁通过证明。未跑全量、未截图、未打包或发布。

## 2026-09-14 基础动作费用居中与禁用原因

域：界面、装备与解除。

RuleChangePackage：费用数字关闭自动换行并固定居中，避免最小高度撑出徽标。不可用动作保留部位行，在底部单独显示11号红色简短原因；说明关闭自动换行并限制在按钮内，悬停继续显示完整正式原因。常见双臂／双腿限制、站姿、次数和无力化仅缩短显示文案，中英文同步；不改变候选资格、费用、状态、随机、回合、存档、输入或日志。窗口补齐实际布局后的徽标数字矩形、禁用原因颜色／位置／裁切和腿部限制反例；复用basic_attacks、casting窗口及architecture、localization规则。


2026-09-14 动作栏对齐复验：关闭费用数字自动换行后，实际布局中心与32像素徽标中心一致；不可用动作使用24像素标题行、17像素部位行与17像素红字原因行，按钮增至60、整栏72像素，仍与手牌区分离。首轮140项localization／architecture规则通过；窗口发现中文字形最小行高17超出原14像素分配，已修复并补齐正义飞踢简短原因。最终build/checks/20260914T100955306-55060中basic_attacks105、casting55，共160项窗口断言通过，源码稳定。未打包或发布。

## 2026-09-14 警卫开场满位加固

域：监狱与收押、装备与解除。

RuleChangePackage：首回合三处apply原有replace权限保留，补tighten_missing；不足次数通过共用加固候选，仅限该操作required_slots真实覆盖部位，1次只加固1件／1档。满3档可上锁时复用加固上锁与满耐久，空位先施加、合法替换先替换、不原样替换。被闪避的次数不转加固；无加固目标则落空，不跨部位补装。共用targets增加可选部位过滤，默认空列表保持六缚等原全身后备行为。已保存首回合旧意图执行时补同样后备，不增加存档字段。首回合后循环、准备、捕缚、随机域、资源费用及其余十四交互轴不变。图鉴／练习中英说明同步，实际日志沿既有施加、替换、加固／上锁与落空日志；不新增叙事。guard增加满位低品质替换、高品质加固、3档锁恢复、跨部位反例、只读／过期拒绝、存读档与阶段推进；关联application、replacement、enemies、intent、persistence、content、localization。不打包。


警卫首回合修复验证：20260914T104131444-3824中localization／replacement／application／architecture／content／intent／enemies全部通过（2590项）；guard初轮70项仅“满3档加固上锁”测试失败，原因是测试持有被正式安装流程更新前的字典引用，已按稳定ID读取最终装备并补旧意图存读档用例。20260914T105830535-51180最终guard规则75项、完整guard窗口69项全部通过；同期其他源码变化，报告source_changed，保留专项通过记录，不标记冻结全量通过。git diff --check通过。未打包。

## 2026-09-14 其他人形敌人装备流程排查

域：战斗与敌人、装备与解除。

范围：按humanoid注册逐项核对玩偶师、玩偶、六缚、多面手、奴隶贩子，并回归已修复的警卫。installation_intents与实际application_spec均保留替换权限；普通空位优先、满位比较及结构封闭仍沿Application/Replacement。六缚开场与收尾逐区域、双重束缚缺额及复合失败已有各自加固分支；多面手有独立上锁／双件加固。奴隶贩子按准备就绪确定实际紧度并执行指定偏好；玩偶受击的普通及预备附加仍沿正式人形施加。未发现第二处与警卫首回合同类的漏接；没有将警卫新增后备扩展到其他未声明此效果的动作，也未修改运行规则。

测试补入已有enemies分类：枚举全部当前人形来源、确认只读权限和真实满位替换、保持原品质与无关装备、替换日志、六缚初／中级区域施加失败后加固、多面手双件3档上锁和满耐久、无目标不反向补装。无新状态、候选、数值、事务、随机域、存档、UI或玩家文案；RuleChangePackage.changedUiAndLogs=N/A（仅审计及测试，运行表现不变）。专项结果随后记录；不打包。


人形流程审计验证结果：20260914T111017278-57252完整enemies1793项通过且源码稳定；20260914T111220973-8144完整battle_saturation34项通过（首次临时脚本加载错误已在重试消失）。20260914T110818892-48760中replacement／application／intent／guard／trader均通过；新增审计夹具初轮误用了六缚练习ID、并把奴隶贩子初级施加预期写成中级，已修正夹具并完整复测enemies，未因此改动游戏规则。已核对所有当前人形的替换权限、正式满位替换、规定的加固后备和全场无操作后的逮捕条件，未发现新的规则漏接。未运行全项目或重新打包。

## 2026-09-14 监狱巡视榨精与正常出狱对白

域：`assets/art/enemy-guards-v1/README.md`。

每次例行巡视接受检查结果时，以及每次刑期到期的额外巡视中，均通过正式检查事务追加一次狱警手部榨精。复用通用高潮身体、装备及遗物反应，高潮总数增加1，自身魔力立即损失`min(20，当前魔力)`；不打开战斗高潮覆盖层，不生成高潮后乏力或滑精两回合延迟。低于20魔力、平板锁、平板锁且低魔力分别选用稳定文案cue，重复接受已完成检查不能重复结算。正常出狱在重建塔路后仍显示一次无名字的棕发资深狱警对白框；例行巡视固定显示紫发狱警。两张用户指定图片已按透明抠图流程替换原警卫资源，来源、裁框和哈希见`assets/art/enemy-guards-v1/README.md`。

最终门禁`build/checks/20260914T112747431-54388`源码前后指纹一致：localization、architecture、content、action_copy、prison、guard、pressure共2989项规则断言全部通过；prison真实窗口212项全部通过。窗口流程实际确认巡视到来、接受检查、扣除20魔力、平板锁低储量正文、两张狱警立绘、无名字对白框和正常出狱后对白。未运行全项目、未生成截图、未打包或发布。

## 2026-09-14 收押与巡视短文案

域：监狱与收押、文案与本地化。

收押页移除保底规则、状态保留与战后奖励说明，改为押送和登记演出加三项实际数量；巡视页移除检查次数、清单原理、事务过程与重复规则提示，公开和完成结果改为短句。进入牢房后新增无名字棕发狱警对白。底层检查事件仍保存缺失、请求、实际安装、更新后清单、牌区恢复、电池与延期事实；规则断言因此改读结构化字段，而不要求玩家界面重新显示实现报告。

`build/checks/20260914T114658541-5540`中localization、architecture、content、action_copy、prison、guard共2002项规则断言全部通过，guard窗口70项通过；prison窗口的两项旧长句断言暴露后已改为短文案＋结构化事实检查。最终复验`build/checks/20260914T115315468-54688`的prison窗口216项全部通过，源码前后指纹一致。两轮均未生成截图；未运行全项目、打包或发布。

## 2026-09-14 一次性收押事件页与收押榨精

域：`ui/quick_release_bar.gd`；契约 `prison-release.md`。

RuleChangePackage见`docs/prison-release.md`。正式收押先执行既有战斗结束、装备追加与链接安装，再进行一次脚本高潮，立即损失最多20自身魔力，最后执行进入监狱的遗物钩子；主动投降也停在同一个`captured`收押页，确认“进入牢房”后才开始牢房回合或五级终局。捕获记录新增可选`intake_scene`，保存实际普通／复合拘束具、连接绳与性玩具的共用佩戴正文以及榨精差分；旧快照没有该字段时仅使用安全回退，不提高快照修订。原`prison.guard.cell_entry`持久NPC日志已删除，普通牢房回合不再反复弹出收押对白。

规则检查`build/checks/20260914T124444794-54936`中relics、architecture、content、action_copy、prison、guard、pressure共3775项通过；localization在同期目录重生期间失败，随后重新生成英文目录并由`build/checks/20260914T124800800-59224`以73项单独通过。更早的定向`build/checks/20260914T122057604-57588`验证guard 77项及平板锁低魔力差分。监狱窗口`build/checks/20260914T124914202-47392`共217项通过，覆盖事件式收押页、具体装备正文、真实扣魔、主动投降入口和进入牢房后旧对白不复现；运行期间有其他界面源码更新，报告标记`source_changed`，因此仅记录专项通过，不宣称冻结源码全量门禁。pressure窗口先通过本次强制高潮投降分支，后在同期快捷栏改动造成的两条深呼吸显示旧断言处失败，未计为整组通过。

本批没有生成截图、没有打包或发布。为恢复窗口检查，顺带修正同期新增`ui/quick_release_bar.gd`中一个缺失的闭合括号及对应缩进；该修复不改变候选、费用、资源或规则。

## 2026-09-14 体术连击名称截断

域：界面、装备与解除。

RuleChangePackage：名称／伤害默认字号18降至16，按两段实际字体宽度共同缩小，间距8减至6；移除伤害区62%比例限额，以完整文字的测量宽度居中分配。沿已有能量徽章、部位／次数副行及不可用原因，未缩写招式名称或改动作规则、数值、候选、日志、存档与随机。basic_attacks窗口新增肘击连击／近身短打连击，在有／无墙缝工具压缩栏位下测量完整文字、边界、间距及只读状态。20260914T114156443-48444完整basic_attacks窗口123项通过，git diff --check通过。未打包。

## 2026-09-14 体术及身体栏位置互换

域：检查与测试、界面。

RuleChangePackage：体术显示列表交换heavy与kick，顺序为肘击、踢击、近身短打、火球术、深呼吸；身体栏仅在渲染时排序为头颈、手胸、性器、臀腿。原候选列表／规则区域顺序、快捷键绑定、右键招式切换、目标ID、费用、伤害、展开优先级及溢出收起规则不变。没有新增文案、状态、事务、日志、随机或存档；玩家标签沿用现有名称。现有basic_attacks补位置先后断言，body_layout调整预期顺序及最底部可见滚动区高度边界检查，不改底层分区。未打包。

位置互换验证：20260914T114527346-52760的basic_attacks完整124项通过且源码稳定；20260914T114620561-48244的body_layout完整147项通过，但同期其他源码变化，报告source_changed，不标记整批冻结通过。两处位置、展开／收起、实际点击及宽高边界检查均通过；未打包。

## 2026-09-14 动作栏切页与快捷挣脱

域：检查与测试、装备与解除。

已接入：右侧零回合切页；四区默认装备／耐久／紧度／锁状态；右键切小部位；先点部位再点挣扎／滑脱牌，以及真实拖牌直接提交；第五格已安装道具；探索、整备及休息保留动作页的深呼吸。费用、目标资格及版本继续由原候选决定，无新游戏状态或存档字段，中英文提示同步，未打包。

- `20260914T120922083-46916`：architecture 151、localization 71项通过，共222；工作区同时有编辑，脚本标记source_changed，仅记录断言结果，不记作冻结源码门禁。该次窗口新增测试误将只读pressure对象当数字比较，修正为测试状态的数值后重新执行相关分类。
- `20260914T121317688-53964`：basic_attacks 158、installed_tools 51、body_layout 147、targeting 83项通过。包括先部位后牌真实点击、真实滑脱拖放、独立区域不变、只扣一次费用、缺能量／旧版本／错误牌面拒绝、切页保留立绘与手牌、右键零消耗、非战斗深呼吸、安装道具及魔瓶不遮挡、英文提示。此批唯一失败为exploration旧远端牢门案例没有确定的开门资格，依赖随机起手含开锁牌，不是横栏功能失败。
- 为该远端测试明确注入持有狱警钥匙的前提，原“需要先到牢门前”及不夹杂其他地点断言保留；玩法代码未改。`20260914T121459900-55468`重新执行exploration完整分类43项通过，退出码0、源码指纹稳定。

五个受影响窗口分类最终合计482项通过（分上述两次结果），没有宣称原组合失败批次整体通过，也没有进行全项目回归。相关规则断言与窗口结果的源码稳定性分别如上记录。截图未默认生成。

## 2026-09-14 左侧捕缚拖牌、快捷装备循环、探索火球术

域：`core/game.gd`。

已完成：左侧捕缚整行与战场捕缚共用接收函数；四区上一件／下一件和←／→循环本区物理目标，默认优先最外层可挣扎的最低紧度项；切换联动左侧小部位和展开的装备详情；手动目标保持，失效候选不改打其他装备；X为踢击、V为近身短打；探索显示火球术与深呼吸，自解能力沿原施法候选拖到拘束具或快捷格。

- `20260914T123350477-57924`：keyboard 67、guard 87项通过。捕缚新例以合法牌堆夹具验证拖到标签与条身，两处高亮、实际进度／能量、错误牌及旧版本拒绝、移除捕缚后接收区消失。该批源码变化，`source_changed`，只记录断言结果；同批basic_attacks的火球拖放测试先拖牌再展开部位导致输入取消，调整为先展开后真实拖牌，不改正式接收逻辑。
- `20260914T123737669-58032`：architecture 151、localization 71，共222项规则断言通过；basic_attacks 174、body_layout 147、targeting 83项通过。含默认低紧度目标、实体选择、跨小部位循环、空部位开始循环、左右键、二三级详情联动和不遮挡横栏、X/V真实选择、探索炫火自解实际拖放及正式费用。该批源码指纹稳定，但exploration一条旧安装位置文案断言仍期待“墙缝一”，与当前正式“离地0.2米的墙缝”不一致，因此不记录组合批次整体通过。
- exploration断言改为验证当前正式mount_label及原3次使用数。重新检查时发现同时改动的投降分支有一行Guard.capture缩进脱离elif，修复为仅在surrender分支执行；`core/game.gd --check-only`解析通过。`20260914T124233679-8536`：exploration完整43项通过，退出码0、源码指纹稳定。

相关窗口六分类最终601项通过，规则222项通过；结果来自上述批次，源码稳定性分别记录，不宣称全项目或同一次冻结检查全部通过。早期捕缚新测试直接替换手牌而未同步卡组，被正式验证正确拒绝；改为共用加牌工厂且保留原牌区后通过，未绕过一致性检查。

本地化门禁发现英文兼容表新加入的5条具名占位符未转为p0格式，导致整个兼容表拒绝加载；仅修正参数标记并同步生成脚本映射，原中文及英文正文语义不变。localization重新71项通过。没有生成截图、打包或发布。

## 2026-09-14 图鉴卡牌与实时对局显示隔离

域：装备与解除、卡牌与奖励。

图鉴通过现有卡面入口显式关闭实时卡牌类型／实体投影合并；原牌、衍生牌、双面、魔力角标及悬浮说明统一采用静态注册表。手牌及其他展示默认沿用实时投影，角色专属定义及图鉴筛选不变。只读显示变化，无规则、存档或新文案。

- `20260914T130814854-57824`：card_power完整307项通过；该批`source_changed`，仅记录断言结果。新增图鉴局内夹具最初沿用主页的正式开局，未进入战斗导致取不到手牌控件，改为既有game_fixture；之后改用正式打开抽屉入口，避免直接置位同时留下其他启动抽屉，保留原关闭面板断言。
- `20260914T131234528-7932`：encyclopedia完整158项通过，退出码0、源码稳定。覆盖真实装备使汇流收益及般若汤费用变化的前提、手牌动态效果保留、图鉴基础费用／效果／角标、两面及全部相关衍生牌、不显示即时施法概率、浏览不改快照及实际关闭。

未运行全项目回归，未截图、打包或发布。

## 2026-09-14 拘束具图鉴简洁排版

域：装备与解除、检查与测试。

按最新要求移除通用耐久百分比紧度分档说明；保留装备具体施法倍率及滑脱限制。基础信息、组件明细和特殊效果以空行分段，删除重复组件汇总，整数耐久不显示小数尾零；拘束具正文18号字、行距6。仅改只读图鉴及相应测试，不改规则、候选、数值、日志、随机、存档或其他分类布局。

`20260914T125159535-59980`：localization 73、architecture 151、encyclopedia 495，共719项规则断言通过；encyclopedia窗口82项通过，包含胶带包裹分段、字号行距、完整耐久和口球倍率保留。工作区期间有源码变化，报告`source_changed`，仅记录断言通过，不宣称冻结源码门禁通过。`git diff --check`无空白错误。未打包、发布或生成截图。

## 2026-09-14 快捷栏两侧箭头与同栏位键位

域：界面、装备与解除。

四区上一件／下一件改为左右端28×60的整高点击区，三角图形直接绘制，中央文字与键位提示不覆盖箭头。对应栏位的strike／kick／heavy／fireball绑定在快捷页只选择头颈／手胸／性器／臀腿，默认Z／X／V／F；原←／→循环、右键小部位、详情联动及拖牌仍沿原入口。

`tools/check.ps1 -UIOnly -UISuite basic_attacks,keyboard -TimeoutSeconds 300 -KeepGoing`：`20260914T125218834-46768`，basic_attacks 202、keyboard 81，共283项通过，退出码0，源码指纹稳定。检查两侧整高几何、文本与键位不相交、空区禁用、真实点击及拖牌、四个原键位只读选择、自定义Q替代Z、旧键失效、抽屉阻挡和切回原动作选择。`git diff --check`无空白错误。纯UI改动，未运行全项目回归，未截图、打包或发布。

## 2026-09-14 快捷框无数字耐久条

域：装备与解除、界面。

RuleChangePackage：装备名称右侧增加48×8的剩余耐久条，只消费现有ratio，隐藏数字和百分比，空部位隐藏；名称留出空间，原悬浮完整名称与耐久／紧度文字沿用。条形忽略鼠标输入，不改点击、详情开关、拖放及原候选。仅显示变化，状态、数值、费用、事务、日志／对白、随机、存档、迁移和十四规则轴不变；无新增中英文文案。

`tools/check.ps1 -UIOnly -UISuite basic_attacks -TimeoutSeconds 300 -KeepGoing`：`20260914T130918718-46368`，完整basic_attacks 226项断言通过。新增当前比例、切换与实际卡牌伤害后更新、空区隐藏、数字隐藏、名称与箭头边界、点击条形开关详情且不扣费；原真实拖牌回归通过。检查期间其他源码变化，汇总source_changed、退出码1，未声明冻结门禁通过。`git diff --check`无空白错误；未截图、打包或发布。

## 2026-09-14 快捷框点击开关三级详情

域：装备与解除、界面。

RuleChangePackage：点击快捷框或对应栏位快捷键展开当前目标的原装备三级详情，再次选择同框关闭，保留部位及目标供直接点牌；选择另一框切换详情，箭头和右键切换仍始终展开。空部位只显示原部位页面，快捷模式详情统一保持在横栏上方。只改UI开关和几何，不新增状态字段或文案；原中英文名称、说明及原因沿用，日志／叙事N/A，候选、费用、事务、回合、随机、存档、迁移与十四规则轴不变。

`tools/check.ps1 -UIOnly -UISuite basic_attacks,keyboard -TimeoutSeconds 300 -KeepGoing`：最终`20260914T130353156-59888`，basic_attacks 217、keyboard 87，共304项通过，退出码0、源码稳定。覆盖同部位多件装备的精确三级展开、同框关闭／重开、关闭后实际点牌效果、跨框切换、快捷键开关及空部位窗口不遮横栏。此前`20260914T130213557-52928`的299项检查是在用户追加关闭要求前启动，不作为最终版本门禁。`git diff --check`无空白错误；未截图、打包或发布。

## 2026-09-14 快捷栏补齐降紧与开锁

域：界面、检查与测试。

RuleChangePackage：修复快捷卡牌模式过滤遗漏lower／unlock，魔力撑除及开锁牌均复用原选中物理目标、卡面、候选ID和版本，经原事务执行。UI匹配及中英文不适用提示／探索说明受影响；状态、数值、施法成功率、费用、回合、事件、日志、叙事、存档、迁移、随机与十四规则轴不变。无有效目标仍显示原候选原因，禁止改用其他可用装备。

`tools/check.ps1 -Suite localization -UI -UISuite basic_attacks,casting -TimeoutSeconds 300 -KeepGoing`：`20260914T125921838-56060`，localization 73、basic_attacks 212、casting 55项断言通过。新例覆盖多件装备中先选目标再真实点击魔力撑除、精确降紧及费用、无锁目标拒绝且不改打另一件、缺魔拖放拒绝、旧版本及自由面拒绝、真实拖放开锁一次。共267项窗口断言通过，但检查期间其他源码有变化，汇总为source_changed、退出码1；此记录不代表冻结源码门禁或全项目回归通过。`git diff --check`无空白错误。未截图、打包或发布。

## 2026-09-14 狱警巡视事件页与紫发狱警透明图修复

域：`core/witch_expansion.gd`。

RuleChangePackage：正式`inspection`候选、结算、处罚、榨精、反抗和巡视周期保持不变；仅把arrival／result／done三个阶段集中投影为事件式页面，并移除普通巡视事件中的持久`npc_copy`，避免浮动对白覆盖牢房或跨阶段重放。延长8回合仍作为结构化结果显示，狱警对白不再念规则数值。紫发狱警继续使用用户原图，本地边缘分离提高白色阈值并补充尾巴封闭区背景种子，保留白手套、丝袜、手臂和腿部，不生成、不重绘。英文目录、UI回归及规则对照同步；不改变状态、随机、数值、事务和存档格式，不截图、不打包。

验证：`20260914T131733355-43252`的localization／architecture／action_copy／prison共1551项规则断言通过；prison窗口执行217项，仅旧测试把带已安装工具的结果误当成完全合规而失败，实际页面已正确显示藏工具差分，断言随后按结构化场景修正。复跑被同期删除、仍由角色2入口引用的`core/witch_expansion.gd`阻断，未擅自恢复另一批文件；本批Godot导入在该同期删除前为0错误。未截图。

## 2026-09-15 单手套拘束具立绘差分

域：角色与美术、装备与解除。

RuleChangePackage：使用用户提供的两张对齐原图，通过本地脚本提取银白套体、黑色肩带与扣件的像素差异，并生成普通和平板锁组合的透明替换底图及大腿根切片。`GameView`从真实复合拘束具投影`composite_portrait_layers`，只有主体仍有效的`glove`根启用该显示；短型、长型与肩带样式共享差分。左侧装备肖像和战斗受限站姿同步，解除套体后恢复原图。规则、数值、候选、费用、事务、回合、日志、叙事、随机和存档不变，无新增玩家文案；没有调用图像生成工具。

验证：`build/checks/20260914T142422863-63312`完成Godot导入，architecture 151项、equipment_art 176项通过；战场快照发现只读字段未随英雄快照复制后，统一经`EquipmentPortrait.snapshot`传递并复测。最终`build/checks/20260914T142821261-39696`中equipment_art与hero_art共231项窗口断言通过，覆盖短／长单手套、普通／平板锁组合、左侧与战场同步及状态只读；截图`build/ui-equipment-single-glove.png`、`build/ui-hero-single-glove.png`和`build/ui-hero-restrained-special-equipment.png`已人工查看。未运行全项目回归，未打包或发布。

## 2026-09-15 小魔女三姿势与身体栏立绘

域：角色与美术、塔路与地图。

- 本地抠图：站、坐、躺三张用户原图均保留RGBA透明通道与原始比例；坐姿仅补清帽内及脚／斗篷间白底，未使用会吃进大腿的白色连通区；躺姿补清双腿间白底。左侧身体栏使用站姿窄裁版。
- 左栏构图：专用裁框由源图`(140,0,1060,2304)`平移为`(460,0,1380,2304)`，显示宽高比不变；按人物身体中心而非帽檐与斗篷的整体透明重心定位，使人物在178×454画框内向左移动并居中。
- 显示边界：战场只读取View中的角色与姿势；小魔女佩戴拘束具后仍使用对应默认姿势，不借用角色1差分。角色1原有自由、拘束及固定立绘路径保持。
- 规则影响：N/A。图片与映射不改候选、费用、事务、事件、日志、随机、存档或任何装备判定；玩家可见文字沿现有角色和姿势名称，无新增机械文案。
- 自动检查：`tools/check.ps1 -RerunFailed build/checks/20260914T145515294-42952 -TimeoutSeconds 300`稳定通过；`architecture` 158项，`display,home,equipment_art,hero_art` 485项。首轮导入和截图轮的同组断言也全部通过，但因工作区同时有其他既有修改而被指纹门禁标为`source_changed`，最终稳定轮退出码为0。实机截图`build/ui-witch-portrait-stand.png`、`sit.png`、`lie.png`已检查三姿势切图、透明背景、原始比例、落地线和左栏窄裁显示。
- 左移复核：最终裁图重新导入后，`tools/check.ps1 -Import -UIOnly -UISuite hero_art -Screenshots ui-witch-portrait-stand.png -TimeoutSeconds 300`通过64项；截图确认人物身体位于左栏画框中部。

## 2026-09-16 事件选项状态条件的存档校验（`has_relic` 读档失败修复）

域：`core/snapshot.gd`、`content/README.md`、`tests/persistence_cases.gd`、`tests/content_cases.gd`。

缺陷（仅存在于未发布的本地提交）：`4441120` 为漂浮皮带群加入 `has_relic` 状态条件后，冻结选项把它带进存档，而 `core/snapshot.gd:391` 仍只接受 `kind=="no_chastity_lock"` 且键集必须为 2。持有「软化扣环」进入该事件时写出的存档在读取时被判「事件选项的状态条件损坏。」，`Store.unpack` 与 `restore_snapshot` 均拒绝，该存档槽无法继续。写入侧 `SaveStore.write_game` 只跑 `game.validate()`，而事件 `validate` 不检查 availability，所以保存会成功、失败只出现在读档——不对称是本缺陷难被发现的原因。`e635bf5`（v0.17）不含 `has_relic`，缺陷不在任何已发布版本中。

RuleChangePackage：`core/snapshot.gd` 的状态条件校验改为按 `kind` 复核键集——`no_chastity_lock` 恰好 `{kind,reason}`；`has_relic` 恰好 `{kind,type,reason}` 且 `type` 必须是已登记遗物；未知 `kind` 或多余键一律拒绝。`content/README.md` 同步记录两种条件的键集与"新增条件种类必须同时扩展存档校验"。规则、候选、费用、事务、随机、存档格式与旧档兼容性不变。

验证：`tools/check.ps1 -Suite persistence,events,event_flow,content,architecture -TimeoutSeconds 600 -KeepGoing`：`build/checks/20260916T023640988-18172`，architecture／event_flow／content／persistence／events 全部 PASS，共 2118 项断言。新增 `tests/persistence_cases.gd:event_conditions`（持有遗物时的事件往返 + 五类畸形条件的原子拒绝）与 `tests/content_cases.gd` 的 `has_relic` 正例及三类反例（缺 `type`／未登记遗物／多余键）。反向对照：临时撤销 `snapshot.gd` 修复后 `-Suite persistence` 复现真实错误（`build/checks/20260916T023516144-10164`，persistence FAIL，1/604，"无法继续这份存档：事件选项的状态条件损坏。"），证明该断言确实覆盖本缺陷。未运行全项目回归、未截图、未打包。

## 2026-09-16 E0 事件等价判据：比较器类型缺陷修复与判据身份登记

域：契约 `verification.md`。

缺陷（**判据侧，不是产品行为**）：`build/event-oracle-20260916/event_oracle.gd` 的比较路径用 `JSON.stringify` 比对进程内整数与从基线文件读回的浮点（Godot 4.7 的 `JSON.parse_string` 把所有 JSON 数字解析为 float），所以基线一旦冻结，94 个场景恒判红（差异形如 `count: 4.0 -> 4`）。实现者在改动任何产品代码前停下上报，并给出独立证据：以 `--write=` 重放写出的文件与冻结基线逐字节相同、摘要仍为 `1f11bea5…`——据此把"判据坏了"与"行为漂移"分开，协调者裁决后才动手（授权范围仅比较路径，冻结基线与捕获路径一字不动）。

修复：仅新增 `_normalized()`，把基线侧整数值 float 归一为 int 后再比较；场景集合、捕获路径、摘要算法、基线文件均未改动。

验证（域：E0 oracle 判据，`build/` 产物）：
- 干净跑：退出码 0，`EVENT RESULT: PASS (94 scenarios, 0 failures)`，`EVENTDIGEST 1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da`（＝契约 §0.1 记录的基线摘要）；日志 `build/e0-diagnostic-20260916/compare-fixed.log`。
- 反向对照（证明判据不是永远绿灯）：进程内注入两处真实漂移（`start:abandoned_storeroom` 的 `count` +1、`choose:binding_cleric:purify` 的 `view` sha256 首位改 0），退出码 1、`FAIL (94 scenarios, 2 failures)`，逐条打印场景与字段差异，摘要同时变红（`1c640cde8a6e83a64404d8c153cd92711a2d44c0a228c581650bcc01703f7306`）；日志 `build/e0-diagnostic-20260916/compare-drift.log`，漂移副本 `event_oracle_drift.gd`。
- 捕获侧未变：`build/e0-diagnostic-20260916/rows_after_fix.json` 与冻结基线逐字节相同（各 50744 字节，`cmp` 通过）。
- 判据身份（`build/` 已 gitignore，脚本不进仓库，故登记哈希作为复核依据）：脚本修复前 `651890ac192f0d3e836b3b7fd6616ce4263e8ae788d8993658c0932082b6725a` → 修复后 `cf48529a19af7773f4d8ac6be343a759fa6038151942fdf66dd249c89e20557f`；基线 `bdf08765f8dea0c1f6ac489245abd689907fd6974f794b7cea1e98d7a090e9c8`（未变）；漂移副本 `d12652336d4246ecaee94c08093bfb9faff42d57944ff2314f9dcbf19c47245b`。四个哈希与 `cmp` 结果已由协调者独立复核。
- 产品代码零改动（本项全部落在 gitignore 的 `build/` 内）；事件管线 B1 的判据自此可用字面退出码。

判据适用说明：B1–B4 的分类门禁以**增量**判定——红集必须恰好等于 `docs/verification.md` 已登记的既有阻塞项（当前为 `card_power` 的 5 条 `witch_*`），多出任何一条即停手上报；`card_power` 的修复不在本片范围，另行排期。

## 2026-09-16 B1b 作者文档同步（事件节点形态）

域：`content/README.md`、`tests/architecture_cases.gd`、`tests/content_cases.gd`、`tools/check-content.ps1` 等；契约 `content-templates.md`、`content-generation.md`、`content-extension.md` 等。

RuleChangePackage（文档与测试，零产品代码）：`spire-godot/content/README.md` §3 事件整节重写为单一节点形态（`start_node`／`nodes`／`schema_version: 2`、七个节点声明键与取值、合并后的选项白名单含"适用形态"列、起始节点免费出口只约束多节点、`availability` 两形态都生效、完整示例只指向两个模板）；`docs/content-templates.md`、`docs/content-generation.md`、`docs/content-extension.md` 同步到节点形态，模板为真源、文档跟随；已死的选项级 `pressure` 示例删除，B1 之前就不被校验接受的 `wager`／`reward:"keys"` 改为显式标注为早期设计记录（不整段删除）。新增具名 check：`tests/architecture_cases.gd` 的 `event_dependency_edges_pinned`、`event_definition_accessors_only`，`tests/content_cases.gd` 的 `event_author_manual_lists_current_fields`（读 README §3，字段 token 必须落在校验器词汇内，并逐条把文档里的声明取值拿去编译）。内容包与模板未改动；oracle／基线、契约、`core/`、`ui/` 未改动。

验证（提交 `a57dec3`，父 `c0b6a1d`；域：文档同步 + 事件分类）：
- E0 等价：退出码 0、`PASS (94 scenarios, 0 failures)`、`EVENTDIGEST 1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da`（与冻结基线逐字相同）。
- 内容包：`tools/check-content.ps1` 退出码 0、`CONTENT PASS: 12 file(s)`；模板探针 `tools/check-content.ps1 -Path build/b1b-docs-20260916/template-probe` 退出码 0、`CONTENT PASS: 2 file(s)`。
- 规则门：`tools/check.ps1 -Suite event_flow,events,content,architecture -TimeoutSeconds 600 -KeepGoing` 四类全 PASS；`-Impact` 展开集的唯一红项分类＝`card_power`（5 条 `witch_*`，登记于本文件第 29 行），未多一条；断言总数由 B1 的 10339 增至 10523（文档 check +184）。
- 旧形态残留：对四份文档检索 `start_stage`／`"stages"`／顶层 `choices` 零命中（`rg` 退出码 1）。协调者已独立复核上述 E0、四类套件（2147 断言）、内容包与模板探针三项。
- 具名 check 非空洞性：`event_author_manual_lists_current_fields` 在修正 `allow_refuse` 取值拼写前真实红过一次（`EVENT MANUAL node declaration documents every accepted value: allow_refuse ["true","false"]`）。

遗留（另行排期，不属本批）：①`docs/event-structure.md` §1 结构地图仍描述 B1 前的 `stages/start_stage` 形态（该文件是规划者契约，须由其加注或修订）；②本地化词表漂移——`assets/localization/legacy-en_US.json` 仍登记 B1 已删除的校验文案，新校验文案缺译（按已定义安全回退显示源文，无玩法影响）；③`docs/content-generation.md` §7.4 的早期设计记录是否彻底移除属文档裁定。未跑：`-Suite all`、打包与发布门禁（本批零产品代码改动）；未推送、未打包。

## 2026-09-16 B2 事件管线：声明表、单求值入口与叠加条件（含 B2b 收口与本地化）

域：`tools/check-content.ps1`。

RuleChangePackage（规则内重构，行为逐字节不变）：事件选项的资格判定从四条并行通道（`condition_met`／`availability_issue`／`hide_when_unavailable` 探测／遗物池闸门）收敛为**一份 `CONDITIONS` 声明表**，由它派生四处——运行时求值（`condition_probe`）、内容校验（`condition_issue`）、存档键集（`condition_saved_fields`）、trace 命名；新增**唯一求值入口** `evaluate_option`，返回逐条 `gates`（`gate`／`kind`／`mode`／`index`／`detail`／`reason`）与四种 `decision`，多命中按声明序以 `"\n"` 连接；`enter_node` 成为唯一节点管线，B1 遗留的"节点数分支"消失，七个节点声明（`frozen_form`／`relic_gate`／`random_freeze`／`outcome_draw`／`unavailable`／`empty_node`／`allow_refuse`）全部生效；新增规范拼写 `conditions`（1—8 条、每条 `mode∈{optional,hidden}`）与选项级 `unavailable`，与旧拼写互斥校验；`probe`／`candidates`／`execute`／`view`／`validate` 不再读 `flow` 镜像；删除选项级 `pressure`／`pressure_source` 死分支；`snapshot` 事件段**增量**补键集（保留原有 `flow` 分支全部检查，不以放宽换统一）。同批刷新英文字典。

**关键判据口径**：`frozen_form=="in_place"` **且选项无 `selector`** 时用 in_place 冻结布局，其余一律 staged（依据：选择器选项历来走共享 staged 构建器，改判据会让 `temper`／`dissolve` 的冻结 id 与 `selected` 键变化 → E0 必红）；`validate_failed` 与 `node_empty` 的具名 gate 缓到 B3（要单独命名须先拆 `probe()` 内部）。

验证（提交 `60869fc`（核心）→ `5a60cda`（B2b）→ `b6d45b5`（收口）；域：事件分类 + 存档 + 本地化）：
- **E0 等价**：退出码 0、`PASS (94 scenarios, 0 failures)`、`EVENTDIGEST 1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da` —— 三次提交后各自复核均**逐字相同**（协调者亲自重跑，非采信报告）。
- **规则门**：`tools/check.ps1 -Suite event_flow,events,content,architecture,localization -Impact -TimeoutSeconds 600 -KeepGoing` 退出码 1，`5/10664`，`failed=['card_power']`、`unrun=[]`、`passed=23`、指纹前后一致 —— 红集**恰好**等于本文件第 29 行登记的 5 条 `witch_*`；`event_flow／events／content／architecture／localization／persistence` 六类全 PASS（协调者重跑 3044 断言）。
- **界面**：`tools/check.ps1 -UIOnly -UISuite events,localization -TimeoutSeconds 900` 退出码 0、`UI PASS: 231 assertions`。**口径**：该命令默认 300 秒会因负载在 `events` 窗口套件中途被中止（`20260916T083346894-13484`，无 UI RESULT），记录与复跑一律用 `-TimeoutSeconds 900`。
- **内容包**：`tools/check-content.ps1` 退出码 0、`CONTENT PASS: 12 file(s)`。
- **本地化**：`legacy-en_US.json` 删 25 条本片已不存在的旧源文（阶段专用文案）、增 29 条新校验文案英文条目，条目 4943→4947；`removed still present: []`、`required missing: []`；`python tools/localization_inventory.py`：`needs_review 5690`、`connected_static_call 33`，`en_US 52/52`、`ja_JP 0/52`（ja 缺译非本片引入、未动）。具名 check `locale_legacy_catalog_matches_current_sources` 断言旧源文不存在且所需源文译文非空（安全回退不算通过）。
- **具名 check**：§10 场景 05／08／09／13／15–18 落地（`event_condition_kinds_share_one_declaration`、`event_single_node_declarations`、`event_node_empty_policy_kept`、`event_probe_and_projection_readonly`、`event_stacked_conditions`）；依赖规范三条 check 落地（`event_condition_kinds_share_one_declaration`、`event_single_evaluation_entry`、`event_pipeline_writes_only_declared_keys` 内容半；链半属 B4）。场景 05 经裁定为"一条 check 覆盖三处消费者即可"（判据是三处一致，不强制分文件）。

**一次"红项归因"记录（值得留档）**：B2b 首轮报告"`conditions` + `mode:"hidden"` 可能不丢弃选项"，实现者用最小复现（两组夹具 × 戴锁／不戴锁）分类为**断言写法错**而非产品缺口——原断言把 `options.is_empty()` 与 `candidates().is_empty()` 用 `and` 连接，而 `candidates()` 含非事件候选；且第二条夹具的期望默认 `no_chastity_lock` 在未戴锁时本不该命中。据此按契约字面判据重写断言，**未改产品代码**。这与 E0 比较器那次同类：先分类"判据坏了／行为漂移了"，再动手。

遗留（另行排期，不属本批）：B2c＝把 `conditions`／`unavailable`／叠加语义补进四份作者文档；B3＝trace 具名全覆盖（含 `validate_failed`／`node_empty`）与 debug 开关；B4＝事件链与环守卫；`card_power` 5 条与 `normal_play` 1 条为既有登记项。未跑：`-Suite all`、打包与发布门禁。**整片（B3／B4）未完成前不得打包发版**；未推送、未打包。

## 2026-09-16 B2c 作者文档补 conditions 与叠加语义

域：`content/README.md`、`tests/content_cases.gd`；契约 `content-templates.md`、`content-generation.md`、`content-extension.md`。

RuleChangePackage（文档与文档 check，零产品代码）：`spire-godot/content/README.md` §3 选项表新增 `conditions`／`unavailable` 两行（各写明与 `availability`／`hide_when_unavailable` 互斥），状态条件段重写为"两类拼写＋规范拼写规格（1—8 条、kind 只能取声明表种类）＋两种模式语义（`optional` 显示但禁用／`hidden` 不生成）＋完整模式优先级＋叠加求值与 `reason` 拼接规则（**声明顺序决定换行顺序**）"；`docs/content-templates.md`、`docs/content-generation.md`、`docs/content-extension.md` 同步；删除 B1b 遗留的"B2 起生效"标注。`README.md:219` 的"跨事件跳转／事件链 **B4 起生效**"据实保留（B4 未落地，文档不得提前宣称可用）。`tests/content_cases.gd` 的 `event_author_manual_lists_current_fields` 扩展词表（`conditions`／`unavailable`／`mode`／`optional`／`hidden`／`disable`／`hide`／`kind`／`reason`／`type`／`no_chastity_lock`／`has_relic`）并加反向断言（不得出现"B2 起生效／待 B2／尚不可用"，必须出现两类拼写、两类模式与"声明顺序"）；只加断言、未放宽任何既有断言。

验证（提交 `1f450d7`；域：作者文档 + 事件分类）：
- E0 等价：退出码 0、`PASS (94 scenarios, 0 failures)`、`EVENTDIGEST 1f11bea5…`（逐字相同）。
- 规则门：`content`／`architecture` 全 PASS；`-Impact` 变体（`20260916T084820647-6816`）退出码 1、`5/9455`、`failed=['card_power']`、`unrun=[]` —— 红集恰好等于本文件第 29 行既有登记项。
- 界面：`-UIOnly -UISuite events,localization -TimeoutSeconds 900` PASS 231。内容包：`CONTENT PASS: 12 file(s)`。
- 残留扫描：`B2 起生效`／`待 B2`／`B2 前`／`尚不可用` 零命中（唯一合法命中是 `README.md:219` 的 B4 标注）。协调者已独立复核 E0、两类套件（1019 断言）、UI 与内容门。
- 未跑：`-Suite all`、打包与发布门禁。**整片（B3／B4）未完成前不得打包发版**；未推送、未打包。

## 2026-09-16 B3 事件 trace 与具名 gate（核心 + B3b 收口，**本批未完成**）

域：`core/room_events.gd`、`core/game.gd`、`tests/installed_tools_cases.gd`。

RuleChangePackage（规则内重构，行为逐字节不变）：`core/room_events.gd` 新增 `probe_result`（唯一实现，`probe()` 保留原签名＝返回 `.reason`）把探测拆成可分别命名的阶段——`effects` 失败→`probe_failed`、`next_node`→取节点入口 gate、`validate` 失败→**`validate_failed`**、暂存未归还→**`held_pending`**；新增 `enter_node_result`（唯一实现）——空节点→**`node_empty`**、节点不存在→**`stage_missing`**，**既有 issue 文案一字未改**；`feasibility_gate` 改从 `probe_result` 取 gate。新增 **debug-only trace**：开关与数组挂在游戏对象的调试字段（`set_meta`／`get_meta`，**不进 `state`／不进存档／不进 View**，`core/game.gd` 未改），`trace_entry` 记录 `event／node／source_choice／option_id／decision／gate／kind／mode／index／reason／purpose`。修复实现者自查出的缺陷：`start` 原先用属性式 `g.get("event_trace_enabled")` 清空、而访问器用元数据，**两套存储**导致开关打开时不清空、trace 跨事件累积陈旧行（且 `g.event_trace=[]` 真执行会报脚本错误）；改为新增 `clear_trace(g)`，读／写／清三处统一到同一存储与接口。

验证（提交 `e78fc72`、`367477c`；域：事件分类 + 持久化）：
- **E0 两遍（协调者亲自复核，含引擎错误日志判定）**：关闭＝退出码 0、`PASS (94 scenarios, 0 failures)`、摘要 `1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da`；开启（冻结 oracle 的副本 + 一行开关，冻结物未改）＝同样退出码 0、同一摘要；两遍日志中 `SCRIPT ERROR|ERROR:|Invalid access` **命中 0 行**（日志 `build/b3-verify/off.log`／`on.log`）。**口径补强**：oracle 显式 `quit(0)`，退出码不反映脚本错误，因此"退出码 0 + 摘要相同"必须与错误日志核对一起用。
- **release 不产出证据链**：①全仓 `rg` 显示只有测试与构建副本调用 `set_meta("event_trace_enabled"…)`，生产路径（`core/`／`data/`／`ui/`）无设置点、默认 false；②关闭与开启两遍摘要逐字相同；③`get_view`／`export_snapshot` 的 JSON 不含 `event_trace`／`event_trace_enabled`（由场景 10 的 check 断言）。
- 规则门：`event_flow,events,content,architecture,persistence` 全 PASS（协调者重跑 2919 断言）；`-Impact` 展开集 `failed=[card_power, installed_tools]`、无本片新红（`unrun` 为预算内未跑完，非失败）。界面：`-UIOnly -UISuite events,localization -TimeoutSeconds 900` 状态 `passed`（`summary.json` 复核）。内容包：`CONTENT PASS: 12 file(s)`。
- 落地具名 check：场景 04 `event_hidden_relic_option_traced`（event_flow_cases）、场景 10 `event_trace_never_reaches_state_or_save`（persistence_cases）。
- **未落地（本批未完成的原因）**：场景 03（gate 名全覆盖，须含 `validate_failed`／`node_empty`／`held_pending`／`stage_missing`）与场景 19（叠加逐条 trace＋关开关后为空＋上一事件行不残留）两者的断言在 D3 修复后**仍红**，实现者按纪律**移除红断言并未弱化、未提交**，怀疑与 `arrival`／`candidate` 两次评估间 trace 行的归属有关但未证实。**待定位并分类**（产品缺陷 vs 夹具期望）。

**新登记的既有红项**：`installed_tools` —— `tests/installed_tools_cases.gd:43` `SCRIPT ERROR: Invalid access to property or key 'detail'`，`FAIL: 0/9`；`t.find_action(g,"card",…)` 返回兜底 `{valid:false,payload:{}}`，即该 `strain` 卡候选未生成。**分类证据**：实现者在 `4d22a00`（B1 之前，临时签出 `core/`＋`content/`＋`tests/` 后还原、`git status` 干净）跑同一套件，**同样报错、同样 0/9** → 非本片回归；协调者在 HEAD 重跑复现同一错误。根因方向＝该夹具前置条件与当前卡牌/工具接口漂移，**未定类、未修**。门禁红集口径自此为 ⊆ {`card_power` 5 条, `installed_tools` 1 条}。

未跑：`-Suite all`、打包与发布门禁。**整片（B3 收口、B4）未完成前不得打包发版**；未推送、未打包。

## 2026-09-16 B3 续批：trace 行语义落地与两处实现缺陷修复（**B3 仍未完成**）

域：事件、检查与测试。

RuleChangePackage（规则内重构，行为逐字节不变）：
- **D1a**：`evaluate_option` 现在分别传 `source_choice`＝作者选项 id、`option_id`＝冻结实例 id（无冻结实例时回落作者 id），`trace_entry` 从字段取 `source_choice`——此前两者被写成同一个值，违反契约 §4.5（A25 第 3 条）。仅影响 trace 行。
- **`selector_empty` 具名化**：`enter_node` 在选择器展开为空时原先直接 `continue`，该选项**既不记 gate 也不产 trace 行**（违反 §4.2 的具名 gate 要求，也是场景 03 缺行的原因）。改为仍调用一次求值入口，使该选项得到 `selector_empty` gate 与一行 trace；**行为不变**（选项本就不进入冻结选项，E0 摘要即是其证明）。
- 场景 19 具名 check 落地（`event_flow_cases.gd:event_stacked_condition_trace_and_release`）：按 `purpose` 过滤、逐条比对 `source_choice`／`option_id`／`index`／`mode`／`gate`／`reason`、**跨 purpose 全等**（仅 `purpose` 可变）、`start` 后无残留、关闭时 0 行、存档与 View 不含 trace。

**一次误报的自我更正（留档）**：上一轮"套件上下文缺少 `purpose=="candidate" and index==0` 的行"**经原始数据否定**——实现者在取数前**多调用了一次 `candidates()`**（行数 4→6），且按总行数写死断言，违反 A25 第 2 条"禁止按 trace 总行数断言"。原始行数据显示两次求值的状态条件行**只差 `purpose`**、完全合规。这是本轮第三次"红项先定类"救回的时间（前两次：E0 比较器、`hidden` 模式立证）。

验证（提交 `4e9a1a2`；域：事件分类 + 持久化）：
- **E0 两遍（协调者亲自复核，含引擎错误日志）**：关闭与开启各退出码 0、`PASS (94 scenarios, 0 failures)`、摘要 `1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da` 逐字相同；两遍日志 `SCRIPT ERROR|ERROR:|Invalid access` **命中 0 行**（`build/b3-verify2/off.log`／`on.log`）。
- 规则门：`event_flow,events,content,architecture,persistence` 全 PASS（协调者重跑 2926 断言）；`-Impact` 红集 = {`card_power`, `installed_tools`}（均为既有登记项）。界面：`-UIOnly -UISuite events,localization -TimeoutSeconds 900` PASS 231。内容包：`CONTENT PASS: 12 file(s)`。
- **未完成**：场景 03（gate 名全覆盖，须含 `validate_failed`／`node_empty`／`held_pending`／`stage_missing` 与选择器两类 id 分开断言）仍为占位、未落地；B4 未做。**整片未完成前不得打包发版**；未推送、未打包。

## 2026-09-16 B3 完成：trace 与具名 gate 全覆盖（场景 03 落地）

域：`tests/event_cases.gd`、`core/room_events.gd`；契约 `event-pipeline-unification.md`。

RuleChangePackage（规则内重构，行为逐字节不变）：`tests/event_cases.gd` 新增 `event_gate_names_are_total`（+162/−18），按 `docs/event-pipeline-unification.md` §4.5（A25）与 §10 场景 03 的口径落地——①12 份内容逐事件：每个作者选项至少一条 arrival 行、未展开项恰一行、每行 `decision` ∈ {generated,dropped,hidden,disabled}、dropped/hidden 行必须命中 §4.2 的具名 gate 清单（12 名）；②状态条件行在 arrival↔candidate 双向**缺行/多行即失败**，逐字段（event／source_choice／option_id／decision／gate／kind／mode／index／reason）相等，单节点另断 `node` 相等，不进冻结集合的行必须确为 dropped/hidden；③**选择器两类 id 分开**：`source_choice` 恒不含 `__`，含 `__` 的行必须 `<source_choice>__…` 且逐实例恰一行、实例集合 == `room_event.options[*].id` == 候选 `payload.choice`；④**`selector_empty`**（`enchanters_empty_studio` 的 `temper`，seed 42）恰一行 `gate=="selector_empty"`＋`dropped`，且不进冻结选项与候选；⑤开/关两遍的 frozen options／candidates／rng／view 逐字相等、关闭时 0 行；⑥**禁止按 trace 总行数断言**，重复只按单次求值判定。五个具名 gate 全部用真实夹具（无桩）：`stage_missing`（已进事件上 `enter_node_result(g,"missing")`）、`node_empty`（关死多节点夹具 `finale` 的唯一选项后 `enter_node_result`）、`probe_failed`（真实魔力不足探针）、`validate_failed`（已进事件上把 `room_event.values` 弄坏后 `probe_result`）、`held_pending`（真装 `shaft_ring_low` → `hold_special` → `probe_result(...,true)`）。

**卡点定类（第四次"先分类"）**：前一轮的 `probe_result` 报 `Invalid access to property or key 'refs'`**不是** `validate_failed` 通路的问题——`probe_result` 首行即 `apply_effects(..., g.state.room_event.refs, …)`，而 `refs` 只有 `start` 之后才存在；同一条读取在 B3 之前（`f95e96f~1:core/room_events.gd:801`）逐字相同，产品全部调用点都在事件内。**结论＝夹具约束**（探针必须在已进入的事件上跑），非产品缺陷、非契约缺口；未改产品代码、未改契约、未放宽断言。

验证（提交 `79bd622`，父 `5c5ffda`；域：事件分类）：
- **E0 两遍（协调者亲自复核，含引擎错误日志）**：关闭与开启各退出码 0、`PASS (94 scenarios, 0 failures)`、摘要 `1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da` 逐字相同；两遍日志 `SCRIPT ERROR|ERROR:|Invalid access` **命中 0 行**（`build/b3-verify3/off.log`／`on.log`）。
- 规则门：`event_flow,events,content,architecture,persistence` 全 PASS（协调者重跑 3362 断言）。界面：`-UIOnly -UISuite events,localization -TimeoutSeconds 900` PASS 231。内容包：`CONTENT PASS: 12 file(s)`。
- **红集口径扩展**：`-Impact` 展开集的红集为 {`card_power`（5 条）, `installed_tools`（1 条）, `tower_progression`（10 条规则 + 1 条界面）}，三者均为本文件已登记的既有项（`tower_progression` 见本文件第 31 行；在新会话把它 `git stash` 掉后同样 10 条红，故非本片回归）。**门禁红集口径自此为 ⊆ 上述三项**。
- **操作口径**：`-Impact` 展开集里 `installed_tools` 的 `SCRIPT ERROR` 会触发 runner 的 runtime_error 分支而使其余分类 `unrun`——"红集恰好"的判定必须以**补充枚举**（跑完 `unrun` 分类）为准，报告里必须列出 `unrun` 清单，不得把未跑当通过。

**两处 trace 形状待裁（不影响玩法、不影响上述判据；已交规划者裁定后并入 B4 或 B3c）**：①`stage_missing` 无 trace 行（`enter_node_result` 只在 `node_empty` 分支写行，`room_events.gd:376` vs `:361`），而 A25 §4 把 `stage_missing` 列为节点入口失败行——补行还是改契约措辞待裁；②candidate 阶段探测后继节点时 `enter_node_result` 以 `purpose="arrival"`、`node=当前 stage` 写入且每个冻结实例各写一份（`succubus_three_games` 10 份相同行），A25 的过滤元组无法与真实 arrival 行区分——需给该情形独立的 `purpose` 取值或修订过滤口径。

B4（跨事件 `next` 与 `chain`）未做；`README.md:219` 的"B4 起生效"标注据实保留。**整片完成前不得打包发版**；未推送、未打包。

## 2026-09-16 B4 完成：事件链（跨事件 next、chain 键、环守卫）——本片最后一批代码

域：事件、塔路与地图。

RuleChangePackage（行为在现有内容上逐字节不变，链能力为新）：`next` 接受对象形态 `{"event","node"}`，静态校验要求事件已登记、节点存在于该定义、拒绝自引用，同定义内仍只向后；新增 `next_target`（唯一解析入口）／`enter_target`／`chain_cleanup`／`_enter_chain`，跳转时重写 `room_event.id`／`stage`、`values`／`held` 延续、`cleanup_effects` 按 key 并集、`event_seen` 加入目标、`flow` 按新定义重算；`chain` **只在真跳转时**写入且与 `event_seen.append` 同一事务；候选阶段环守卫给 `disabled`＋gate `chain_loop`；A30 `stage_missing` 补节点入口失败行；A31 后继节点探测用独立 `purpose="next_probe"` 且节点级行按 `(event,purpose,node,gate)` 去重；`snapshot` 增量接受 `chain`（数组、元素已登记、不重复、非空），既有字符串分支与检查逐条保留。`_next_ends_event` 让"带奖励必须结束事件"与"起始节点可离开"不再对对象形态做 Dictionary↔String 比较。

验证（提交 `8633bd9`，父 `73e2f21`，6 files／+309−16；域：events + persistence）：
- **E0 两遍（协调者亲自复核，含引擎错误日志）**：关闭与开启各退出码 0、`PASS (94 scenarios, 0 failures)`、摘要 `1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da` 逐字相同；两遍日志 `SCRIPT ERROR|ERROR:|Invalid access` **命中 0 行**（`build/b4-verify/off.log`／`on.log`）。12 份内容与冻结 oracle 夹具均不含跨事件 `next`，对象形态只在新夹具里用。
- 规则门：`event_flow,events,content,architecture,persistence` 全 PASS（协调者重跑 3420 断言）。界面：`-UIOnly -UISuite events,localization -TimeoutSeconds 900` PASS 231。内容包：`CONTENT PASS: 12 file(s)`。
- **A29 补充枚举**：`-Impact` 展开集因 `installed_tools` 的 runtime error 使 18 分类 `unrun`；补跑后 17 PASS、仅 `tower_progression` 红（10 条）→ **补齐后红集恰好＝A28 三元集**，`unrun=[]`、指纹前后一致。
- 具名 check：`event_chain_jumps_to_another_event_node`（id／stage 切换、`chain==["chain_source_fixture"]`、`values`／`held` 延续、`flow` 镜像、`event_seen` 恰一次、cleanup 并集去重、离开时两个 cleanup 各执行一次且两件暂存装备原样装回）、`event_chain_loop_refused`（候选 invalid＋决策 `disabled`＋`gates==[chain_loop/kind chain]`、求值与提交均不改 state／rng／存档）、`event_chain_trace_rows`（A30／A31：`stage_missing` 行 `node`＝目标、`option_id` 空、重复进入仍 1 行；`node_empty` 由两个冻结选项探测仍恰 1 行 `next_probe`）、`event_chain_references_fail_closed`（自引用／未登记／节点不存在／缺 node／多余键／非字符串 node 逐例整包拒绝且注册表不变）、`event_pipeline_writes_only_declared_keys`（抵达实例无 `chain`；真跳转新增键恰为 `chain`；往返保持；`[]`／字符串／未登记／重复／非字符串元素原子拒绝；12 份内容仍无 `chain`）。

**B4 报出的三处缺口（待裁／待收尾，均不影响上述判据）**：①跳转**不重抽遗物**——`room_event.relic` 保持来源事件抽到的值，若目标事件含遗物奖励选项，`execute` 会发放**来源事件的遗物**（§3.3 未规定，未改随机消耗、未立证）；②`hold_special` 的 key 唯一性只在单定义内静态校验，**跨定义重复 key 无静态拒绝**（运行期"同一保管位置不能重复使用"会挡住，未立证）；③新增玩家可见 reason `CHAIN_LOOP_REASON` **缺英／日条目**，按安全回退显示中文。

**本片代码批次（B1／B1b／B2／B2b／B2c／B3／B3b／B4）至此全部落地**；仍待：上述三处缺口裁定与收尾、跨事件 `next` 与链语义补进四份作者文档（含删除 `README.md:219` 的"B4 起生效"标注）、validator 验收。**整片完成前不得打包发版**；未推送、未打包。

## 2026-09-16 B5 完成：链遗物重抽、跨定义暂存 key、本地化与作者文档收尾（本片最后一批）

域：`tests/hand_assist_cases.gd`。

RuleChangePackage：①**A32 跳转重抽遗物**——抽出唯一 `offer_relic(g,spec)`，`start` 与 `_enter_chain` 共用；跳转时按**目标定义**重算 `room_event.relic`（目标含遗物奖励且池非空→抽一次；目标不含或池空→**置空**），不再保留来源事件的遗物。②**A33 跨定义暂存 key**——`_event_references` 末尾沿跳转图逐路径校验 `hold_special` key（`_chain_hold_key_issue`／`_hold_keys`／`_jump_targets`），跨定义重复或 cleanup 引用非本定义 key 即**整包拒绝**；运行期守卫文案未改。③**A34 本地化**——`legacy-en_US.json` 增 `legacy.hbe6fbb665a810824ce3c074b`（`CHAIN_LOOP_REASON`），条目 4947→**4948**，`needs_review` 5701→5702，`en_US 52/52`、`ja_JP 0/52`，旧源文零残留、译文非空。④**文档收尾**——四份作者文档补跨事件 `next` 对象形态与链语义（`chain`／并集／环／不能再回头），**删除 `README.md:219` 的"B4 起生效，当前不接受"**并改为现行说明；`event_author_manual_lists_current_fields` 纳入链关键词并加反向断言（只加未放宽）。

验证（提交 `556a231`，父 `8808be5`；域：events／persistence／本地化／文档）：
- **E0 两遍（协调者亲自复核，含引擎错误日志）**：关闭与开启各退出码 0、`PASS (94 scenarios, 0 failures)`、摘要 `1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da` 逐字相同；两遍日志 `SCRIPT ERROR|ERROR:|Invalid access` **命中 0 行**（`build/b5-verify2/off.log`／`on.log`）。12 份内容仍不含链。
- 规则门（协调者重跑）：`event_flow,events,content,architecture,localization,persistence` 全 PASS（3586 断言）。界面：`-UIOnly -UISuite events,localization -TimeoutSeconds 900` PASS 231。内容包：`CONTENT PASS: 12 file(s)`。
- 具名 check：A32 三类（`event_chain_relic_drawn_from_target`／`..._cleared_without_target_offer`／`..._cleared_when_pool_empty`，各含随机域对拍）＋A33 `event_chain_hold_keys_fail_closed`（重复 key 与 cleanup 引用外部 key 双反例整包拒绝、注册表不变）＋A34 `locale_legacy_catalog_matches_current_sources`（`REQUIRED_SOURCES` 纳入新常量）＋文档反向断言。
- **判据敏感性**：临时停用 `_enter_chain` 的重算后 A32 五条断言变红（四条 class1＋一条 class2）——证明该 check 真的承载判据，不是空转。

**新登记的既有红项**：`hand_assist` —— `tests/hand_assist_cases.gd:38` `SCRIPT ERROR: Invalid access to property or key 'detail'`，`FAIL: 0/125`（与 `installed_tools` 同类：`find_action` 返回兜底 `{valid:false,payload:{}}`）。**分类证据**：把本批改动 `git stash` 后在 `8808be5` 上重跑同一套件**同样红** → 非本片回归；协调者在 HEAD 复现同一错误。**门禁红集口径自此扩为四项** ⊆ {`card_power` 5 条, `installed_tools` 1 条, `tower_progression` 10 条规则＋1 条界面, `hand_assist` 1 条}。根因方向＝夹具前置条件与当前动作接口漂移，未定类未修、另行排期。

**两条操作提示（留给后续与重建目录时用）**：①`python tools/build_english_catalog.py` 在本机**无法运行**（`build/translation-lite` 与 `english-translation-cache-v4.json` 不存在），新条目按契约 §17"离线模型不可用则人工补齐"直接写入目录；**日后重建英文目录时需把该条目补进生成器的 `MANUAL`／缓存，否则会被重建覆盖**。②新增作者层校验文案（本批 A33 的"事件链上重复使用了暂存 key："与 B4 同类新增）未补译，仅体现为盘点 `needs_review` +1，安全回退显示中文（作者层、非玩家主线）。③跨定义环（A→B→A）**静态不拒绝**（仅拒自引用，契约如此）：静态遍历以"路径上重复定义即停"保证终止，运行期由 `chain_loop` 守卫拒绝并由场景 12 立证。

**本片代码与文档批次（B1–B5 全部）至此收口**，下一步＝整片 validator 验收（契约 §11，20 条具名场景＋全部判据）。**B5 已收口，验收可开始；验收通过前不得打包发版。**未推送、未打包。

## 2026-09-16 事件管线统一（B1–B5）整片验收

域：`spire-godot` 事件管线统一切片——定义形态归一（`nodes`／`start_node`）、单求值入口（`evaluate_option`／`enter_node`）、资格从四条并行通道收敛为一份 `CONDITIONS` 声明派生四处、选项生命周期具名 gate、debug-only trace、跨事件 `next` 与 `chain`。契约 `docs/event-pipeline-unification.md` §11／§12／§10／§0.1／§4.5／§3.3／§3.4／§9；依赖规范 `docs/event-pipeline-dependency-spec.md` §4.2。

验收者：独立会话（未参与本片实现），未改产品代码／既有测试／内容包／契约与依赖规范／冻结 oracle 与基线；只新增忽略目录内的验证脚本与记录。对象提交 `3e64cff`（父 `84f8ea3`），验收期间工作区 `git status --porcelain` 前后均为空。

- 验收脚本（`spire-godot/build/validator-20260916/`，gitignored，可复跑）：
  `run-validation.ps1`（编排全部判据并产出 `run-20260916-02/report.json`／`report.txt`）；
  `scenario_probe.gd`（§10 01–20 具名 check 的逐条直调，附依赖规范 §4.2 五条与本地化口径①②，逐条打印断言数与引擎错误数）；
  `scenario14_roundtrip.gd`（场景 14 的 validator 侧覆盖，见下）；`human_path_ui.gd`（真实窗口与真实 viewport 输入驱动 §11 第 6 条缺口）。
  复跑：`powershell -NoProfile -ExecutionPolicy Bypass -File build/validator-20260916/run-validation.ps1 -RunId <id>`。
- **E0 两遍（关闭／开启 trace）**：均退出码 0、`EVENT RESULT: PASS (94 scenarios, 0 failures)`、`EVENTDIGEST 1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da` **逐字相同且等于冻结基线**；两遍日志 `SCRIPT ERROR|ERROR:|Invalid access` **命中 0 行**（`e0-off.log`／`e0-on.log`）。
- 内容门：`& tools/check-content.ps1` 退出码 0、`CONTENT PASS: 12 file(s); validated without changing game or saves`（日志 `check-content-engine.log`）。
- **规则门** `& tools/check.ps1 -Suite event_flow,events,content,architecture,localization,persistence -Impact -KeepGoing -TimeoutSeconds 900`：退出码 1（既有红项），`-Impact` 展开 37 个分类，`summary.json` 各轮 `before==after`、无 `source_changed`。**红集＝{`card_power` 5 条, `installed_tools` 1 条, `tower_progression` 10 条}**，逐条计数与登记一致，**未超出 A35 四项集**。`installed_tools` 的 `SCRIPT ERROR` 触发 runner 的 `runtime_error` 分支，**使其后 18 个分类 `unrun`**（清单：environment_height／exploration／shoulder／slip_motion／torso_binding／casting／special_equipment／services／action_copy／persistence／rewards／events／links／prison／pressure／enemies／trader／tower_progression）；按 A29 **逐分类单进程补跑**，17 个 PASS、`tower_progression` FAIL（10 条），**补跑后 `unrun` 为空**，`unrun` 未记作通过。
- **界面门** `& tools/check.ps1 -UIOnly -UISuite events,localization -TimeoutSeconds 900`（A17 时限）：退出码 0、`SUITE RESULT: localization PASS`／`events PASS`、`UI PASS: 231 assertions`、`summary=passed`。
- **§10 20 条具名场景：20/20 `passed`**（`scenario-probe.log`，同一进程逐条直调，断言数见括号）：01 event_definition_single_form(185)／02 event_option_policies_match_current_behaviour(134)／03 event_gate_names_are_total(436)／04 event_hidden_relic_option_traced(3)／05 event_condition_kinds_share_one_declaration(9)／06 event_stage_available_condition_validates(8)／07 event_definition_form_rejects_legacy_shape(14)／08 event_single_node_declarations(8)／09 event_node_empty_policy_kept(8)／10 event_trace_never_reaches_state_or_save(6)／11 event_chain_jumps_to_another_event_node(19)／12 event_chain_loop_refused(8)／13 event_probe_and_projection_readonly(3)／14 event_frozen_options_roundtrip(84，**validator 侧覆盖**，见下)／15–18 由合并 check `event_stacked_conditions`(14) 承载／19 event_stacked_condition_trace_and_release(7)／20 event_stacked_conditions_keep_current_content(98)。0 引擎错误。
- **场景 14 无落地的具名 check**（磁盘复核：`rg -n event_frozen_options_roundtrip spire-godot/tests/` 无命中；契约 §10 的 01–20 归属清单也未列 14）。validator 按 §11"把验收程序变成可执行脚本"在忽略目录补 `scenario14_roundtrip.gd`：12 份内容的冻结选项与 `room_event` 经真实 `SaveStore.pack/unpack` 与正式入口往返**逐字节相等**（8 单节点＋4 多节点），`next` 只在 staged 布局出现，六类畸形 `next`（缺键／非串或对象／未知节点／未登记事件／自引用／目标节点不存在）**整包原子拒绝**且文案＝"无法继续这份存档：多阶段事件冻结选项损坏。"（84 断言 PASS）。**该缺口属契约落地缺口，非产品缺陷**；正式具名 check 是否补落由规划者裁定。
- 另两条与字面合同的偏差（均不影响行为判据）：①场景 19 的**存档侧同断言**按 §10 应落 `tests/persistence_cases.gd`，实际落在 `tests/event_flow_cases.gd:800`（同一断言内含"存档与 View 不含 trace"半；B3 执行记录已按此登记，属落点与文面不一致）；②§11 第 6 条"付费离开"在所有内容包中已无对应选项（`rg 支付费用 content/packs/` 零命中），该人路径项按现行内容不存在，已改以正式离开路径与人路径 H2／H6 立证。
- **依赖规范 §4.2 五条 check：5/5 `passed`**（直调断言数）：event_dependency_edges_pinned(9)／event_definition_accessors_only(140)／event_condition_kinds_share_one_declaration(9)／event_single_evaluation_entry(26)／event_pipeline_writes_only_declared_keys(85)。
- **本地化口径①②③**：①＋②由 `locale_legacy_catalog_matches_current_sources` 直调 PASS(62 断言：`REMOVED_SOURCES` 25 条旧源文零残留、`REQUIRED_SOURCES` 35 条译文非空)；③盘点 `python tools/localization_inventory.py`＝`needs_review 5702`、`connected_static_call 33`、`en_US 52/52（缺 0）`、`ja_JP 0/52`，目录条目 **4948**（与 B5 记录 4947→4948 一致）。`python tools/build_english_catalog.py` **未运行**：本机缺 `build/translation-lite` 与 `english-translation-cache-v4.json`（A36① 已登记），目录按"离线不可用→人工补齐"维护。
- **§11 第 6 条人路径（真实窗口、真实 viewport 输入）**：既有 `-UISuite events` 覆盖首次进入候选、硬闯战斗→整备、选牌／道具奖励、多阶段逐阶段点击、离开；**其未覆盖的两项由 validator 驱动脚本补**（`human-path.log`，退出码 0、18 断言 PASS）：H2 持有 `softened_buckle` 后【硬闯】缺席且【离开】出现并可由真实点击走完（E6 政策维持现状）；H6 存档并在**正式入口** `HomeContinue` 继续后，阶段／冻结选项／报告与存档点逐字段一致、重按【祈福】报告文本逐字相同。§11 第 7 条叠加条件证明由场景 15–19 承载。
- **四态计数（本片 20 场景）**：`passed 20`／`failed 0`／`unverified 0`／`skipped 0`。步骤层：E0 `passed`、内容门 `passed`、规则门 `passed`（红集在册、`unrun` 清零）、界面门 `passed`、依赖五条 `passed`、本地化口径①②③ `passed`、人路径 `passed`。
- 补充核对（非判据，仅确认既有红项仍如登记）：`-Suite hand_assist` 退出码 1、`0/125`、`SCRIPT ERROR ...'detail'`（A35 一致）；`-UIOnly -UISuite tower_progression` 退出码 1、54 断言、1 条 `SUMMIT UI run loss offers correct restart instead of equipment practice`（登记一致）。
- 未验证／未跑：`-Suite all` 与 `-UISuite all` 全量回归（契约未要求）；Android 真机；`build_english_catalog.py`（环境不可用，见上）；§10 场景 14 的**正式具名 check**（validator 脚本已覆盖行为，落地归属待裁定）。人路径的"关闭 debug 开关：`g.event_trace` 为空"在规则侧场景 19／10 有断言，未另做界面侧重复操作（同一切面，无新增信息）。
- 结论：**本片通过验收**（20/20 场景、五条依赖 check、口径①②③、E0 两遍逐字相同且 0 错误行、红集 ⊆ A35 四项集且补跑后 `unrun` 为空）。未打包、未发版、未推送。归因纪律：本轮无新红项，未修改产品代码、未改动任何既有断言。

## 2026-09-16 B6 完成：场景 14 的具名 check 落进仓库（验收可复现性收口）

域：`tests/persistence_cases.gd`、`core/snapshot.gd`。

RuleChangePackage（仅测试，零产品代码）：`spire-godot/tests/persistence_cases.gd` 新增 `event_frozen_options_roundtrip`（定义 153 行、由 `run()` 在 255 行调用，本次 +75 行），把原先只由**忽略目录里验证者私有脚本**覆盖的场景 14 落成仓库内正式 check（域＝存档）——①12 份内容（8 单节点＋4 多节点）的冻结选项与 `room_event` 经真实 `SaveStore.pack/unpack` 与**正式入口** `restore_snapshot` 往返后 **`JSON.stringify` 逐字节相等**、`validate()==""`、单节点/多阶段计数 8/4；②`next` 只在 staged 布局（`frozen_form != "in_place"` 或作者选项带 `selector`）出现，并覆盖单节点 in_place 事件里由共享 staged 构建器冻结的选择器实例（`alchemist_tasting_stall`／`enchanters_empty_studio`）；③**六类畸形 `next`**（缺键／非字符串或非对象／未知节点／未登记事件／自引用／目标节点不存在）**整包原子拒绝**且文案＝`无法继续这份存档：多阶段事件冻结选项损坏。`，断言只改快照副本（A27）。

验证（提交 `3011cff`，父 `b9e5639`；域：persistence）：
- **E0 两遍（协调者亲自复核，含引擎错误日志）**：关闭与开启各退出码 0、`PASS (94 scenarios, 0 failures)`、摘要 `1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da` 逐字相同、两遍日志 `SCRIPT ERROR|ERROR:|Invalid access` **命中 0 行**（`build/b6-verify/off.log`／`on.log`）。冻结 oracle 与基线未改。
- 规则门（协调者重跑）：`persistence,event_flow,events,content,architecture` 全 PASS（3544 断言）。实现者侧另跑 `-Impact -KeepGoing` 六类：红集＝{`card_power` 5, `installed_tools` 1, `tower_progression` 10} 在 A35 四项集内；`installed_tools` 的 SCRIPT ERROR 使 18 分类 `unrun`，**逐分类补跑后 `unrun=0`**（17 PASS＋`tower_progression` FAIL 10）。界面门 `-UIOnly -UISuite events,localization -TimeoutSeconds 900` PASS 231；内容门 12 file(s)。
- **敏感性证明**（随后还原、`git status` 干净）：①改错期望文案 → **恰 6 条红**，六类畸形 `next` 逐条打印；②往返比对注入漂移（`options[0].label` 加后缀）→ **12 条红**并打印 `SAVE DIFF state.options[0].label …`。证明该 check 不是空转；先试的"把比对改成恒真"因按构造不可能变红而弃用（属正确的判据设计判断）。

**越界缺口（本批未修、未断言，交规划者裁定，A40）**：单节点 **in_place** 事件的冻结选项 `next` **完全不被存档校验覆盖**——`core/snapshot.gd:427` 的 `next` 校验挂在 `if event.get("flow",false)` 分支内，普通事件从不进入该分支。最小复现：把 in_place 事件的选择器实例（如 `alchemist_tasting_stall` 的 `dissolve__equipment_2`）的 `next` 改成未知节点／未登记事件／`42`，`restore_snapshot` **全部接受**（`build/b6-probe-20260916/probe_inplace_next.gd`）。**来源判读：既有缺口，非本片引入**——该分支结构先于 B1，且 B2 已论证"把校验从 flow 分支改为按选项键判定"会**放宽** flow 侧的既有拒绝（缺 `next` 的损坏多阶段选项今天被拒），故当时按契约保留分支不动。影响有限：运行期 `next_target` 解析对未知目标会经 `stage_missing` 等具名 gate 失败（本片 B3 的产物），不是崩溃路径。**裁定：不在本片内修**，登记为既有缺口另行排期；契约 §6.3 需按现状改写（staged 布局选项的逐键校验已落地，in_place 实例的 `next` 未校验）。

**本片至此代码、文档、验证三线收口**：B1–B6 全部完成，整片通过验收（`3e64cff`，登记 `1881568`），场景 14 的仓库内可复现入口补齐（`3011cff`）。**未打包、未发版、未推送**；打包与发布须用户明确指令。

## 2026-09-17 状态迁移管线收束（单写入者 + 单战斗结束判定）

域：`core/game.gd`、`tests/architecture_cases.gd`；契约 `check-routing.md`。

RuleChangePackage（规则内重构，行为逐字节不变）：把散落的同类状态迁移收束到**单写入者**——`state.phase=` 26 点 → **1 点**、`state.room=` 10 点 → **1 点**（均在 `core/game.gd` 的 `_apply_transition` 内，由 `TRANSITIONS` 声明表驱动）；结束战斗从 13 个引用点／**8 个语义入口** → **1 处判定** `_battle_end_reason()` ＋**1 处执行** `_finish_battle(end_kind)`（调用位点保留，避免改变随机消耗与日志顺序）；**收押（`Guard.capture`）改道进同一路径**；`_restart_tower` 保留 3 个调用点。副作用（生成敌人、滚奖励、收押清理、牢房初始化）**留在原函数、原顺序**；**赋值在控制流中的位置不变**（明确拒绝"事务末统一执行"，因为事务中段会读 `state.phase`）；新增迁移日志 `_transition_log` 仅进程内（不进 `state`／存档／View）。新增闭环 check `tests/architecture_cases.gd:104 transition_write_sites_are_pinned`（四组模式扫描、注释与 `==` 不计入、**双向比对**：扫描集 ⊆ 表 ∧ 表内点都被扫到，表外或未命中打印 `文件:行:函数`），表内 **14 项**。

验证（提交 `9ee7a2f`（基线冻结）→ `d519402`（战斗结束）→ `a1744de`（阶段）→ `9d5a6af`（房间）→ `35f3411`（闭环与八条 check）；域：core + rewards/battle_saturation/guard/prison/tower/persistence/architecture）：
- **迁移 oracle（主证据）**：31 个场景覆盖八类战斗结束入口、`prepare_end` 三类、`floor_enter` 与同层换塔、练习初始化四种、牢房回合／巡视／逃脱／高安全、事件进入／空房／道具奖励、demo 结束与返塔；每场景冻结迁移前后 `phase/room/floor/version/rng/本次提交日志 sha256＋可读日志行/room_event 摘要`。**协调者独立重跑两次**：均退出码 0、`TRANSITION RESULT: PASS (31 scenarios, 0 failures)`、`TRANSITIONDIGEST 14eb8cf9c3c8b5d4347b2b9d118b8c504596e04d296d091884995bc359b522b6`（两次同值）、`SCRIPT ERROR|ERROR:|Invalid access` **0 行**。
- **受影响套件（协调者重跑）**：`battle_saturation,rewards,guard,prison,tower,persistence,architecture` 全 PASS、3678 断言、墙钟 148s。实现者侧完整门禁：规则门 2m08s（11 类 → `-Impact` 展开 44 类）红集 **{`card_power` 5, `installed_tools` 1} ⊆ 已知四类**，`installed_tools` 的脚本错误令 24 分类 `unrun`，**合并一次调用**补跑 3m29s → 23 PASS ＋ `tower_progression` FAIL 10 条（已登记），`unrun` 清零；界面门 1m22s `persistence,home,events` PASS 369 断言；闭环 check 25s。
  > **本条已取代（superseded，2026-09-17；新口径见 `docs/check-routing.md` §4.3）**："截断／`unrun`／合并一次调用补跑"口径作废——脚本错误只记该套件 `FAIL(runtime)`＋`SUITE RUNTIME: <name> <n>`，同轮跑完其余套件、`unrun=[]`、无需补跑；数字原样保留为历史。
- **闭环 check 敏感性证明**：临时在 `_finish_if_saturated` 插一处表外 `state.phase="battle"` → `FAIL: 1/462`，并打印 `["res://core/game.gd:803:_finish_if_saturated"]`；还原后 `architecture PASS: 466 assertions`、`git diff` 无残留。
- **未跑（按契约保持未验证）**：`-Suite all`／`-UISuite all` 全量、Android 真机、迁移日志的消费方（存档切片仍暂停）；未推送、未打包。

**判据身份（迁移 oracle，2026-09-16 冻结）**：冻结脚本 sha256 `b49b0164a6b962fc8eae4a843c36510e1fa12c846d9f0e565856fdc6ed092278`（摘要 `00089c29a675e1268473645ab6b7a363e70295abf575cc6cc2929db995ca3e11`）；当前脚本 sha256 `59d41c682b3b302c1d291eb64aea770994c89508ee3fcb637afc7902024c045c`（摘要 `14eb8cf9…`，两次运行同值）；**基线文件 sha256 `ba979d18c31952d6d69ef06ce2ed102f7503c518fa8c6125ea6482c92bb5b4c8` 自冻结起未改**。脚本冻结后**只在比对侧改两处**（新增 `_merged` 折叠相邻同名、`_compare_row` 仅对 `transition_log` 一列双侧折叠；其余列仍逐字段硬比对并保留 `NEWFIELD／MISSINGFIELD` 双向检查），**抓取路径未动**。证据：用当前脚本 `--write=` 到 `build/transition-oracle-20260916/identity-tmp.json`（sha256 `8cf606aa94fb9d946fc7317ad07e55bc9395684deb1f1767595bfa01964cc1bc`）与冻结基线对照——行名与逐行键集完全相同，**唯一差异列是 `transition_log`（31/31，冻结时该列按设计为空、现在为真实 kind）**；把两侧投影到参与比对的六列（`before/after/commit_logs/log_texts/digest/transition_log_declared`）规范化后**两侧同为 sha256 `5333ab642896dd5932faca53211aa7f77510b59065fc0c3a0a1d6374bd78d2fb`**，即扩展未放宽任何比对项；冻结脚本自身 `--baseline=` 自比（`selfcheck.log`）显示 31 条差异**全在 `transition_log`**、行为字段 0 条。**口径**：摘要是脚本版本指纹、**比对才是门禁**；重跑时摘要不一致不等于行为漂移，须按上表核对身份。

**与契约文面的四处不符（已转规划者入契约，均不需改产品代码）**：①收押经 `_apply_transition` **两次**写入（phase／room），不经 `_finish_battle`（后者拥有胜利／饱和奖励体；副作用仍在 `Guard.capture`、顺序不变）；②新增 `floor_enter` 与 `demo_end` 两个 kind（§3 表原只列 `room_enter`，§5 场景 03 用到 `floor_enter`）；③`_enemy_phase` 尾部判定在真实流程**不可达**（仅非法卡链状态可达），oracle 单列 `skip_validate` 场景冻结它，删除会改动闭环表行数与函数集合，故保留；④oracle 两处冻结声明与代码事实不符（`tower_restart`×2、重复同名写入），按"两侧同口径合并"比对，**基线 JSON 与行为字段零改动**。**折叠边界（协调者裁定）**：`transition_log` 列放过"同一 kind 相邻重复的额外一条"——该列是进程内诊断、不进 `state`／存档／View，且"恰一条 `battle_end_*`／均为 `prepare_end`"由闭环 check 与场景 01／02／04 承接，故接受；若将来该日志成为存档切片的数据源，此边界须重审。

## 2026-09-17 固定点存档：只在三处写盘

域：`core/game.gd`、`ui/main.gd`、`tests/persistence_cases.gd`、`tests/persistence_ui_cases.gd` 等；契约 `equipment-performance.md`。

RuleChangePackage（行为对玩家不变，档案写入时机改变）：`core/game.gd` 的 `TRANSITIONS` 声明表新增 `checkpoint` 列——`floor_enter`→`floor`、三个 `battle_end_*`（含 `battle_end_captured`）→`battle_end`、`prepare_end`→`prepare_end`；新增 `CHECKPOINT_PRIORITY` 与 `_checkpoint_kind(log_start)`：`dispatch` 在 `var original=state` 前记 `log_start`，成功字典**末尾追加加性键 `checkpoint`**（`""`／`floor`／`battle_end`／`prepare_end`，由本次提交实际产生的迁移日志条目推导、同类去重、多类按 `battle_end ＞ prepare_end ＞ floor` 取一），失败字典保持原 `{ok,error}` 形状。`ui/main.gd` 的 `_submit` **仅在 `checkpoint` 非空时**调 `_save_progress()`；**删除恢复后立刻写盘**（`_quick_sl` 路径）；**保留**三条非进度写盘（地图线稿变更 `:1636`、新局替换不兼容档 `:1965`、手动"保存场景起点" `:2682`）。新增具名 check：`tests/persistence_cases.gd` 六个（正例 3／反例集合 1／`.bak` 与回退 1／失败与格式契约 1）＋`tests/persistence_ui_cases.gd` 真实 UI 写盘门控＋`tests/architecture_cases.gd` 的闭环 `save_checkpoint_kinds_are_pinned`（checkpoint 集合与声明表被标记的 kind 完全一致，多／少／改值／优先级名集不一致均红）。

验证（提交 `87a357e`，父 `9dd74fd`；域：persistence + architecture + UI home/persistence）：
- **迁移 oracle（第一道防线，协调者亲自复核）**：退出码 0、`TRANSITION RESULT: PASS (31 scenarios, 0 failures)`、`TRANSITIONDIGEST 14eb8cf9c3c8b5d4347b2b9d118b8c504596e04d296d091884995bc359b522b6`（与当前脚本指纹一致）、脚本 `59d41c68…`／基线 `ba979d18…` 未动、引擎错误 0 行。墙钟 5s。
- **规则门（协调者重跑窄集）**：`persistence,architecture` 全 PASS、1426 断言、28.9s。实现者完整门禁：`-Impact -KeepGoing` 72s 红集 = {`card_power` 5, `installed_tools` 1} ⊆ 已知项，`unrun` 16 类**合并一次调用**补跑 142s → 15 PASS ＋ `tower_progression` 10 条（已知），`unrun=0`、**无新红**。
- **界面门（协调者重跑）**：`-UIOnly -UISuite persistence,home -TimeoutSeconds 900` 退出码 0、`home PASS`／`persistence PASS`、**217 断言**、66s。实现者另跑 `-UISuite route` PASS 134（证明地图线稿真手势写盘保留）。
- **性能配对**（`docs/equipment-performance.md:45` 协议；`build/save-fixed-points-20260916/paired-results.json`，`problems: []`）：0/12/26 × battle/departure 六组合**场景内提交 `save` 段中位全为 0.0ms、`new_writes=0`**（旧侧中位 28.0–38.0ms）、两侧最终状态 `identical: true`；固定点单次写盘中位 **18.1ms（0 件）／36.8ms（26 件）**。
- **敏感性证明**：①给非固定点 `rest_start` 标 checkpoint → `architecture` 与 `persistence` 同时红（11/1427，打印 `rest_start->floor` 与固定点集合尺寸）；②摘掉 `prepare_end` 标记 → 12/1422 红。两次均还原、`git status` 干净，日志 `build/save-fixed-points-20260916/sensitivity-{1,2}-*.log`。
- **口径裁定（协调者）**：休息房的**最后一个休息回合**经 `_finish_preparation` 落到 `prepare_end` → **写盘**（这正是"完成休整后存档"）；休息房内的行动、奖励选择与非末回合**不写**。该语义在 kind 粒度上不可再细分，故反例集合的措辞以"非末回合／奖励不写"为准。
- **实现的取舍记录**：`tests/persistence_cases.gd` 增至 735 行（超出项目 500 行惯例；本仓无 Size 计数规则，且本片边界禁止新增文件，故落在既有文件内）。

**新登记的既有红项**：`home_persistence`（UI 套件，`tests/home_persistence_ui_cases.gd`）——3 条断言失败：`HOME new game creates and saves actual tower entry`／`HOME controls remain in logical 16:9 frame after resize`／`HOME restored service room remains interactive`，`UI FAIL: 45`。**分类证据**：把 `core/`＋`ui/`＋`tests/` 整体回退到**已推送的 `a673352`**（早于迁移收束与存档两片）后跑同一套件，**同样三条断言失败** → **非本片引入**；此前未登记是因为门禁一直用 `persistence,home` 两个独立套件，从未跑过 `home_persistence` 这个组合套件。**方法注**：只回退产品文件会因 HEAD 的测试引用新符号而编译失败，定类必须整体回退 `core/`＋`ui/`＋`tests/`。门禁红集口径自此为 ⊆ {`card_power` 5, `installed_tools` 1, `tower_progression` 10＋1, `hand_assist` 1, `home_persistence` 3}。

未跑：`-Suite all`／`-UISuite all` 全量、Android 真机、打包发布。

## 2026-09-17 检查路由与隔离（派生索引 + 单套件失败不中断）

域：`tests/test_game.gd`、`tests/ui_smoke.gd`、`tests/runtime_error_ui_probe.gd`、`tests/check_index.gd` 等。

RuleChangePackage（**只改工具与测试，产品代码零改动**；`git diff a56de58 -- core ui data content assets` 为空）：
- **隔离**（`eaa003a`）：`tests/test_game.gd` 去掉整轮 `break` 与加载失败 `quit(1)`——脚本错误只记该套件 `FAIL` ＋ `SUITE RUNTIME: <name> <n>`（n≥1 才打印），其后套件照跑；`tests/ui_smoke.gd` 同款（setup 期错误打 `SUITE RESULT FAIL` ＋ `SUITE RUNTIME` 后进入下一模块）；`--keep-going` 成为兼容无操作；新增 `tests/runtime_error_ui_probe.gd` 负例夹具。`tools/check.ps1 -VerifyRunner` 探针扩为 5 条隔离反例，**并修掉一个既有 harness 缺陷**（选择探针把子进程 stderr 经 `2>&1` 灌进父进程，`ErrorActionPreference=Stop` 下变终止错误；该缺陷在 `3afdc55` 上同样复现）。5 处旧口径加 superseded 指针（**只加指针、未改历史文本**）。
- **索引**（`aa199f4`）：`tests/check_index.gd` 单一派生实现（信号：`preload`／门面符号／`ui.<成员>`／断言域前缀；`static func` 故意不入索引以免无精度放大），生成器 `tools/build_check_index.gd` ＋ `tools/check-index.ps1 -Write`（**判据只读**），冻结物 `tests/check_index.json`，手写层 `tests/check_index_edges.gd`（`DOMAINS` 58／`WIDEN` 1／`EXCLUDE` 12／`BLIND_BY_DESIGN` 4／`INDEX_DEFECTS` 空，逐条带理由），计划宿主 `tests/route_plan.gd`，`tools/check.ps1` 增 `-Changed`／`-Since`／`-ChangedList`（与 `-Suite`／`-UISuite`／`-UI`／`-UIOnly`／`-Impact` 互斥）。**索引规模**：覆盖 97 个注册套件（规则 51＋界面 46；`suites_with_edges` 94 是"有派生边"的另一口径）、**436 条"套件→源文件"边**、176 个用例文件全部有唯一 owner、`core|data|ui` 120 个源文件中 117 有边或域解析、4 个盲区；冻结摘要 `db5617dd2d272df99cbcca2b6f7a28d36dd823f8cc69f4fe5c258ee169894dda`（冻结物以 `tests/check_index.json` 为准，2026-09-17 重冻为 digest `e2f17665…`／437 边；436 条与原摘要保留为历史）。

验证（提交 `eaa003a`、`aa199f4`、`cfc5d9d`、`6100179`；域：检查工具与测试基础设施）：
- **协调者独立复核**：`tools/check-index.ps1` → `CHECK INDEX PASS: frozen index equals the derivation`（摘要 `db5617dd…`）、退出码 0、**2s**；`-Suite runner` **PASS 1446 断言**、11s；造一个真实改动（`ui/event_screen.gd` ＋1 行注释）→ 计划逐行打印 `ROUTE MODE`／`ROUTE FILES (sha256＋index digest)`／`ROUTE ROW … -> rules=(none) ui=events [signals=domain]`／`ROUTE MILESTONE: declared baseline,normal_play; deducted (none)`／`ROUTE RULE SCOPE`／`ROUTE UI SCOPE`／`ROUTE PLAN`；**干净工作区下 `-Changed` 显式报错**（"The change set is empty; committed changes need -Changed -Since <ref>"），不静默。
- **隔离判据（实现者实测）**：同一宽集命令改动前 **278.6s 截断 ＋ 补跑 261s ＝ 539.6s／2 进程／`unrun`=18** → 改动后 **729s／1 进程／37/37 有结果／`unrun`=[]**；红集不变；**逐套件断言数与改动前逐条相等，合计 16903 条**（"不靠减少覆盖换速度"成立）。
- **三处敏感性证明**（全部还原、工作区干净）：①冻结物改一字节 → `CHECK INDEX FAIL` ＋ 默认门禁 `runner` 同红；②删一条索引边 → `first difference at root.suite_files.…(missing on right)` ＋ `runner` 同红；③源码漂移不 `-Write` → `root.generated_from` ＋ `index_regeneration_is_the_only_writer`、`FAIL 2/1446`；④隔离四反例（assertion／assertion-keepgoing／runtime／load）经 `-VerifyRunner` 得 `SUITE RESULT: runner FAIL` ＋ 后续套件 PASS ＋ `unrun=[]`。
- **`-Changed` 正反例（实现者实测）**：改动内容包 → 7 个消费者＋内容门、退出码 0（43s）；`ui/event_screen.gd` → `RULE SCOPE (none)` ＋ UI `events` PASS 180（44s）；真实工作区计划 ≈7s。

**诚实的反发现（重要，纠正协调者早先的预期）**：契约 §5.6 预期的"隔离后一次进程 ≈400s"**未复现**——单进程 729s 比改动前两段之和 539.6s **慢约 190s**，全部落在 `prison`（92→283s）与 `persistence`（24→169s）；单独跑这两套件回到 91s／23s（125s）。即**长驻进程内的累积开销**，断言数不变。所以隔离的**可复现收益是"`unrun=[]`、免除人工补跑编排、运行时错误有具名标注"，不是墙钟时间**；"拿回五分钟"这一说法**作废**。待裁：是否改为**分批跑**（每 N 个套件重启一次进程，保留隔离语义）。

**与契约的偏差（均加性、已带理由，交规划者确认）**：①`check_index.gd` **551 行**（§9 目标 ≤300；其余文件达标）——为把抽取规则写进文件头与四个接口同文件；②冻结物 **71 KB／3250 行**（§11-6 引用的估算 ≈11 KB；键序稳定已证：两次 `-Write` 逐字节相同）；③`tests/**` 非用例文件走目录闭包（契约 §2.2 的示例早于协调者裁定⑤，属文面滞后）；④新增 3 个数据键（`CLOSURE`／`ORACLE_NOTES`／`SUITE_EXEMPT`）与路由对象内加性键 `gate_results`。

**新登记的既有红项**：界面模块 `interface`（`tests/interface_ui_cases.gd:156`）——`CARD ART every registered card has an illustration` 列出 **28 张 `witch_*` 卡缺立绘**，`UI FAIL: 355`。**分类证据**：`git diff a56de58` 对 `ui/`／`assets/`／`content/`／该用例文件均为空、断言与夹具未变 → 既有内容缺口（角色二卡缺立绘），此前未登记只因门禁从未单独跑过该模块。协调者在 HEAD 复现。**门禁红集口径自此为 ⊆ {`card_power` 5, `installed_tools` 1, `tower_progression` 10＋1, `hand_assist` 1, `home_persistence` 3, `interface` 1(28 张卡)}**。

未跑：全量 `-Suite all -UI -UISuite all`（契约定为里程碑唯一入口）、Android 真机、打包／发版。

## 2026-09-17 卡顿定位：一次点击的成本分布（P0 分段计时，测量非改动）

域：`tests/game_fixture.gd`、`core/game.gd`、`ui/main.gd`、`core/game_view.gd`；契约 `response-pipeline.md`。

方法：真实窗口 1600×900、zh；夹具 battle＝`tests/game_fixture.gd`(42)／departure＝`core/game.gd`(42)；0/12/26 件 × 三类点击（成功提交／选择类／被拒或无效）；`ui/main.gd render()` 与 `dispatch`／`get_view` 调用点**临时插桩**（标签用 `docs/response-pipeline.md` §8 节名），跑完 `git checkout --` 还原（**协调者复核：工作区干净、`build/` 外无插桩残留**）。产物与原始数据：`spire-godot/build/stutter-trace-20260917/`（`round-a.json`／`round-b.json`／`analysis.md`／`noise.md`）。

**结论（占比，% of 该次点击同步总耗时）**：
- **最大单项是候选生成，且被付了两遍**（2026-09-17 更正：两次 `candidates()` 面对不同状态，不是重复计算；见本条目下文更正段。）：battle:26 成功提交（A 轮，总计 **260.3ms**）＝ `dispatch` 39.4% ＋ `get_view` 29.1% ＋ `render` 20.4% ＋ feedback 10.3%；其中 `dispatch` 内 `candidates()+pick` 占 40–52%、`get_view` 内 `g.candidates()` 占 49–66%。结构佐证：`core/game.gd` 的 `dispatch` 内 `for c in candidates()`（提交前复核）与 `core/game_view.gd` 的投影（`get_view` 内 `g.candidates()`）各算一次。
- **整树重建 `render` 不是提交类点击的最大项**（battle 43–53ms，与件数几乎无关：0→26 件 51.4→53.0ms；占提交 20–37%），但**是"点牌选中"点击的 94–95%**（该次点击仅 45.4ms）与**被拒点击的 36–62%**。render 内部最大三节：`body_bar.configure` 约 11ms（仅在相位／身体内容变化时付；同相位刷新命中 `_presentation_key` 仅 0.3ms）、`hand` 9.6–12ms、`actions+rail` 6.5–8.6ms；departure 页面的 render 由 `header+relics` 占约 70%。
- **`save` 24 个单元格全部 0 次 `write_game`**（固定点存档已把磁盘移出点击路径；计数器经 `restart()` 固定点验证＝每次 1 次）。
- **被拒点击的 `dispatch` 只占 0.1–0.2%**（131–182µs，版本判定在候选生成之前返回）；其成本在 `get_view`（36–62%）与 `render`（36–62%）。
- **`get_view` 的 `card_texts` 只占 1.6–7.9%**——"每次无条件生成约 83 型"已是过期事实（`core/game_view.gd:4 _card_display_set` 按需，实测每次 2–4 型、departure 为 0）。

**两条与契约文面不符（协调者已核代码事实，待规划者改文本）**：①`docs/response-pipeline.md` 关于 `card_texts` 无条件全量的成本事实（§2.2／§6.1）已被按需化取代；②同文件"选择类点击每条分支都整树 `render(view)`"不成立——翻面与选敌现在 0 次重建（局部刷新），只有点牌选中会 1 次重建。

**可靠性边界（必须遵守）**：①占比可靠（两轮首位一致 23/24；占比比值无一处超 0.5–2.0）；②**绝对微秒不可跨进程使用**——两轮整体差约 ×0.6（98 处），与 2026-09-17 早先的跨会话方差发现一致；③battle:0 的 cardsel 样本混入了提交（不可用）；`body_bar.configure` 的"仅换相位时贵"为机制推断；④未覆盖 map／shop／event／reward／prison／practice 相位、触屏路径、英文 locale；⑤首次 B 轮在 `build_scene battle/12` 出现约 700s 引擎停滞（环境级，已重跑，本轮数据作废）。

**两条修复方向（均指向既有契约，非新设计）**：①**候选不要算两遍**——dispatch 复核重算候选，而 UI 手上已有同版本候选（`ActionIndex`），正是 `docs/response-pipeline.md` 里"候选 ID＋版本提交、索引只查找不重算"的本意，约可省一次 30% 量级的开销（2026-09-17 被否：该方向经人裁定"方向错误"、不实施，见本条目下文更正段）；②**`present(dirty)`**——整树重建只在"点牌选中"这类高频低改动点击上成为主项（45ms 中约 43ms），正是该契约的适用范围。

**更正（2026-09-17，协调者）**：上一条里"同一份候选算了两次"的说法**不准确**。核对代码：`ui/main.gd` 的 `_submit` 顺序是 `dispatch(c.id, version)` → 成功后 `get_view()`，两次 `candidates()` 面对的是**两个不同状态**——`dispatch` 内那次是**提交前**（用于复核提交的候选并取出其 payload），`get_view` 内那次是**提交后**（用于渲染新的行动栏）。二者内容不同、各自都有用途，**不是重复计算**。可省的只有第一条的"全表重建"（核心其实只需要那一个候选）：`_submit` 手上本就有候选对象 `c`，却只传了 `c.id`。详见协调者对该问题的答复。

**更正（2026-09-17，协调者）**：本条列出的"两条修复方向"中，**第①条（提交路径去重／候选不再全表重建）经人裁定"方向错误"**，契约已归档 `docs/history/submit-dedup-2026-09-17.md`（**不实施**），理由与四个替代方向写在该文件头。第②条（`present(dirty)` 局部刷新）**未裁决**，仍在待选。

**再归并（2026-09-17，协调者）：按"候选／校验／深拷贝／执行"重切同批原始数据**（只重算 `round-a.json`／`round-b.json` 的占位，未重跑仪器、无插桩）。
成功提交（battle，B 轮，件数 0／12／26，整次同步 98.1／110.7／187.7ms；上文 260.3ms 属 A 轮，跨轮不可比）：

| 段 | 0 件 | 12 件 | 26 件 | 26 件占整次点击 |
| --- | --- | --- | --- | --- |
| `dispatch` 内 候选+取回 | 8.4ms | 19.9ms | 41.6ms | 22.2% |
| `dispatch` 内 `_execute`+清理 | 6.2ms | 10.6ms | 27.5ms | **14.7%（第二大）** |
| `dispatch` 内 五项校验+版本 | 4.0ms | 3.5ms | 3.1ms | **1.7%（最小项）** |
| `dispatch` 内 `state.duplicate(true)` | 0.3ms | 0.4ms | 0.5ms | 0.3% |
| `get_view` 内 候选 | 9.1ms | 16.3ms | 36.2ms | 19.3% |
| `get_view` 内 preview／card_texts | 0.6／0.7ms | 1.6／0.6ms | 3.6／0.7ms | 1.9／0.4% |

- **五项校验不随候选数、只随装备件数走**（battle 3.1–4.0ms 平；departure 3.5→4.0ms），在 battle 26 件时只占整次点击 1.7%；**0 件档反而是它的相对高位**（4.1%）。
- **第二大头是 `_execute`+清理**（26 件 27.5ms，0→26 件放大 4.4×），从未分段，"执行一个动作到底花在哪"目前是空白。
- 0 件档的主导项是 UI：`render` 36%、`feedback` 20%，core 侧只有 41ms／98ms。
- **例外页：departure**（候选恒 6 条、`_execute` 0.2ms）——校验 3.5–5.6ms 成为 `dispatch` 首位（占 `dispatch` 39–42%、占整次点击 15–17%），debug 门控的相对收益主要落在这种"低候选、每次点击都付"的页面。
- 归并口径警告：`body_drawer` 是 `body_bar.configure` 的**外层包装**（`build/stutter-trace-20260917/instrument.py:166-176`，同一段时间被记两次），渲染节占比按 `body_bar.configure` 记 ~22–23%，**不得相加读成 44%**；`page`／`resources` 等节的完整排序见同目录 `analysis.md`。
- 本段只用同一次点击内的比值与同一轮内的件数曲线；绝对微秒仍受"不可跨进程"限制。未覆盖：map／shop／event／reward／prison／practice 相位、触屏路径、英文 locale。

## 2026-09-17 瞬时反馈批次：快感滤镜／蓄力·深呼吸边框／冲击震动（实现者）

域：`core/resource_feedback.gd`、`ui/main.gd`、新模块 `ui/impact_feedback.gd`、`tests/impact_feedback_ui_cases.gd`、`tests/pressure_cases.gd`、`tests/ui_smoke.gd`；契约 `docs/spec/response-pipeline.md`（提交面），无新增玩家文案。

RuleChangePackage（加性、零规则改动：不动候选、数值、存档、随机；不新增规则接口）：`core/resource_feedback.gd` 的 `FIELDS` 增第 6 个字段 `pressure`，`dispatch` 既有返回键 `resource_feedback` 因此携带提交内快感增量，UI 只读该返回值、不解析 `state.logs`。`ui/main.gd` 的 `_submit` 成功分支新增 `_impact_feedback(events,payload,updated)`；交给既有 `ui/resource_feedback.gd` 的事件经既有 `instant_fields` 参数抑制 `pressure`，避免与滤镜重复表现。三种效果共用同一个全屏层与同一张 `FEEDBACK_*` 参数表（`ui/impact_feedback.gd` 顶部）：**滤镜**在 `delta=Σ(after-before)>0` 时出一次（同提交多处上涨合并成一次），峰值 `clamp(0.06+0.24*ratio_now,0.06,0.30)` 再取 `max(峰值,0.5*ratio_rise)` 下限，淡出 `clamp(0.12+0.6*ratio_rise,0.12,0.40)` 秒、`alpha(t)=peak*(1-(t/fade)^2)`，形状按 `1-(d/dmax)^2` 加重的矩形 vignette，颜色复用 `main.gd` 的 `OVERLOAD_COLOR`；**边框**在 `charge` 增量>0／载荷为 `status_toggle` 的 charge 切换（不改数值，只能靠载荷判定）／载荷 `kind=="calm"` 时触发，用时长与强度区分来源（蓄力 0.22s／α0.50，深呼吸 0.60s／α0.30，颜色语义作废；边框取自己 0.18 倍半短边为 dmax，权重函数与滤镜相同）；**震动**在载荷 `kind=="attack"`（含火球术·自解 `attack_release`）单脉冲、`kind=="card"` 且 `mode` 为 strain 双脉冲／slip 与 magic_slip 单脉冲略长，幅度由 `preview.damage`／扁平 `damage` 归一化为 `clamp(1.2+0.45*damage,1.2,6.0)` 像素，只位移 `ImpactShakeHost`、结束复位、布局不动。淡出期间再来一次上涨只刷新强度、不重启计时（截止时刻与首次淡出长度都不变，避免连闪）。硬约束：层与全部子节点 `mouse_filter=IGNORE`；无 `_process`（一次性 Tween，`Fade.finish()` 后 `hide()`＋`set_process(false)`）；层 `z_index=218`，在全部抽屉／面板／浮字之下。

与假设不符的三处（已按实际代码实现）：①普攻载荷是**扁平 `damage`**，只有伤害卡才有 `preview.damage`；②`status_toggle` 载荷写的是 `status:"charge"`（`charge_all` 在 `enabled` 与 copy args 里），不是 `status:"charge_all"`；③`card` 载荷没有 `damage_type` 字段，判定用 `mode`（`strain`／`slip`／`magic_slip`；`magic_hand` 为 mode=magic_slip、damage_type=slip）。

验证（分支 `feedback-effects` 工作区实测，未提交推送；引擎 **4.7.2.stable.official.ed1daf0bf**，`GODOT_BIN` 指向 `*_console.exe`）：
- **冻结 oracle 逐字不变**：`transition_oracle.gd -- --baseline=build/transition-oracle-20260916/baseline.json` → `TRANSITIONDIGEST 14eb8cf9c3c8b5d4347b2b9d118b8c504596e04d296d091884995bc359b522b6`、`TRANSITION RESULT: PASS (31 scenarios, 0 failures)`；`event_oracle.gd -- --baseline=build/event-oracle-20260916/baseline.json` → `EVENTDIGEST 1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da`、`EVENT RESULT: PASS (94 scenarios, 0 failures)`。脚本与基线 sha256 与本卷登记值一致（transition 脚本 `59d41c68…`、基线 `ba979d18…`；event 脚本 `cf48529a…`、基线 `bdf08765…`，均未改）。
- **规则门**：`tools/check.ps1 -Suite runner,architecture,core,persistence,pressure,rewards,event_flow,casting -TimeoutSeconds 1800`（`build/checks/20260917T232152668-42784`）→ 退出码 0、8 套件全 PASS、`PASS: 5962 assertions`、139.91s。新增具名规则 check 在 `tests/pressure_cases.gd`：receipt 合并与"望远镜"不变式（两处 turn_end 上涨 ≥2 事件、Σ增量＝状态净变化）、净上涨才触发、下降只出边框不出滤镜、纯魔力支付不出滤镜；单独复跑 `-Suite pressure` 退出码 0、1081 断言（`build/checks/20260917T234326243-25172`）。
- **窗口门**：`tools/check.ps1 -UIOnly -UISuite impact_feedback,display,home,interface,route,pressure,rewards,persistence -KeepGoing`（`build/checks/20260917T232448848-48048`）→ 退出码 1、`UI FAIL: 1315 assertions`；`display／home／route／impact_feedback／persistence` PASS，红 = `interface`（既有登记：28 张 `witch_*` 卡缺立绘）＋`pressure`（2 条 CALM UI）＋`rewards`（1 条 REWARD UI）。新增模块 `impact_feedback` PASS **75 断言**（`build/checks/20260917T234336041-26092`，29.15s）：触发正／反例、合并、参数边界、颜色复用、层契约（`modulate.a` 峰值、淡出时钟、两种效果同帧共存且互不取消）、真实指针点击路径（普攻单击／拖拽挣扎卡／深呼吸／charge 切换）、穿透（特效运行中 press 仍落到按钮并提交）、空闲态（结束后 hide、`is_processing()==false`、无存活 Tween）。
- **新增红项定类（既有、非本片）**：把全部改动 `git stash -u` 后在**同一 HEAD 干净树**重跑 `-UIOnly -UISuite pressure,rewards`（`build/checks/20260917T233438622-22364`）→ **同样三条失败、断言数相同（pressure 79／rewards 313＝392）**，故 `pressure` 的 `CALM UI shows attenuated relief with unchanged deferred energy`／`CALM UI action description exposes the deferred reward` 与 `rewards` 的 `REWARD UI final unlock segment does not promise a third lock` 为既有红（此前门禁一直用独立套件，从未单独跑过这两套件）。**门禁红集口径自此扩为 ⊆ {`card_power` 5, `installed_tools` 1, `tower_progression` 10＋1, `hand_assist` 1, `home_persistence` 3, `interface` 1(28 张卡), `pressure` 2, `rewards` 1}**。
- **敏感性证明（三条，全部还原、产品文件与备份逐字节一致）**：①层 `mouse_filter` 改 `STOP` → 3 条 `IMPACT INPUT` 红（`build/checks/20260917T233901768-32216`，含"特效期间真实点击仍生效"）；②`filter.refresh`／`border.refresh` 改成总是 `start(...)`（朴素重启）→ 2 条"保持淡出时钟"红（`build/checks/20260917T234221325-44508`）；③`FIELDS` 去掉 `pressure` → `-Suite pressure` 2/1081 红（`build/checks/20260917T234301865-29524`）。**检查改进记录**：初版"淡出中不重启"只比较同一帧内的 `ends`，对同帧重启不敏感，已改成"淡出长度与截止时刻同时不变"（新涨幅淡出长度不同时才有区分度）。
- **未验证**：`-Suite all`／`-UISuite all` 全量回归、Android 真机、打包与发布；`UI SCREENSHOTS: none`（未做像素级截图比对，三种效果只断言参数、锚点与节点状态）。

**更正与返工（2026-09-17，实现者；独立审查 5 项，全部处置）**：

① **不实记录更正**：上文「`magic_hand` 为 mode=magic_slip／damage_type=slip」是错的。事实：`magic_hand`／`witch_magic_hand` 的 `mode` 为 `"lower"` 且**没有** `damage_type`（`data/card_rules.gd` 的 `MAGIC_HAND`；`core/witch_character.gd` 的 witch override 只改 mana／hits／free_effects），`mode=magic_slip`／`damage_type=slip` 的是 `magic_slip` 卡（`data/card_rules.gd`）。错误来源正是 `tests/impact_feedback_ui_cases.gd` 里那条合成载荷 `{"type":"magic_hand","mode":"magic_slip"}`——真实数据不存在这种组合。**已改**：三种卡载荷的 `mode` 一律由 `card_rules.gd` 的 `Rules.face_mode(type,false)` 现取，并新增一条规格锚点断言（`face_mode("strain"/"slip"/"magic_slip")` 与 `damage_type("magic_hand")==""`），另加一条**真实候选**形状断言（`tests/game_fixture.gd` 装腕部夹具后取真实 `card` 候选，断言 `mode` 存在且 `damage_of` 等于其 `preview.damage`）；`magic_slip` 用例改用真实卡 `{"type":"magic_slip","mode":face_mode("magic_slip")}`。第 3 条口径偏差由此改写为：**`card` 载荷无 `damage_type`，判定只用 `mode`；`strain`／`slip`／`magic_slip` 三个 mode 都对应真实卡（`magic_slip` 卡的 damage_type 是 `slip`），`magic_hand` 是无伤害的 `lower` 卡**。

② **规范同步**：`docs/spec/response-pipeline.md` 四处登记新模块——域的文件域列表、M6 行（边界／小接口／内部）、接口表新增 `impact_feedback.play(events, payload, snapshot) -> void` 一行（输入域、调用点、信任依据：不读 `state`／`state.logs`、无效果时为空操作、全 IGNORE 鼠标、无 `_process`、Tween 结束即 `hide()`＋`set_process(false)`）、输入域新增 `play` 条目（receipt 字段口径指向 `core/resource_feedback.gd` 的 `FIELDS`、载荷读法与"输入不是资格判定来源"）。原「本管线不新增 UI 文件」的绝对措辞改为「默认不新增（先提案）」＋本片经任务授权的唯一例外 `ui/impact_feedback.gd`（纯显示、只读消费）＋同类新增仍须提案。

③ **z_index 措辞更正（记录与代码注释同改，数值未改）**：218 并非"在全部抽屉／面板／浮字之下"——`ui/keyboard_input.gd` 的 `KeyboardTargets`(216) 在它**下面**。准确说法：唯一被它覆盖的是 `KeyboardTargets`（只读提示层，位于屏心、vignette 权重近 0，且点击仍穿透）；它在落点／拖放提示(220)、卡牌动画(225)、抽屉与遮罩(228／230)、战斗反馈(240–250)、术语窗(260)、资源浮字(270)、商店遮罩(280)、菜单(300+) **之下**。保留 218 的理由：滤镜必须压在棋盘与世界层之上才有"全屏"语义，而"低于一切可读面板"仍是硬要求——216 是唯一例外且无害。

④ **参数集中**：逐脉冲衰减 `0.35` 已并入顶部参数表 `FEEDBACK_SHAKE_PULSE_DECAY`（效果参数不再有表外魔法数）。

⑤ **新增 UI 层合并用例（含敏感性证明）**：`tests/impact_feedback_ui_cases.gd` 新增 `merged_receipt`，把**多事件 receipt**（两条快感上涨 + 一条魔力）直接喂进 `play()`，钉住：只装填一次包络（`Fade.starts==1`，新增该计数=包络被装填次数）、峰值与淡出长度取**求和**后的上涨、淡出截止时刻为本次提交起算的整段淡出。敏感性：把 `play()` 改成逐事件调用 `_play_filter` → 该 3 条同时红（`build/checks/20260918T000807288-22124`）。

**如实标注（审查要求，不改代码）**：①两个冻结 oracle 的 digest **不覆盖** `resource_feedback` 这条路径（摘要的是 candidates／view／options／snapshot／rng，不含 `dispatch` 返回的 receipt），故本片的**规则侧实际覆盖**就是上文 `tests/pressure_cases.gd` 的 3 条（含"Σ增量＝净变化"与"一次提交 ≥2 个上涨事件"），oracle 只证明事件／迁移结构未被本片改动。②`not is_processing()` 的断言在当前实现下**不可能变红**（脚本未定义 `_process`、无 `set_process(true)`），属结构性守卫，只作"不会退化成常驻逐帧"的静态标注，**不计作行为判据**。

**返工后实测（工作区，分支 `feedback-effects` 第二次提交前；`-KeepGoing`、`-TimeoutSeconds 1800`）**：规则门 `-Suite runner,architecture,core,persistence,pressure,rewards,event_flow,casting` → 退出码 0、8/8 PASS、`PASS: 5962 assertions`（`build/checks/20260918T000926231-16336`）；窗口门 `-UIOnly -UISuite impact_feedback,display,home,interface,route,pressure,rewards,persistence` → 退出码 1、8 套件全部跑完、`UI FAIL: 1320 assertions`，逐套件 display 141／home 113／route 134／interface 355／pressure 79／impact_feedback **81**（原 75 ＋ 规格锚点 1 ＋ 真实载荷 2 ＋ 合并 3）／rewards 313／persistence 104（`build/checks/20260918T001450395-11052`）；两个 oracle digest 逐字不变、脚本与基线 sha256 未动。未验证项不变（全量回归、Android 真机、打包发布、像素级截图比对）。

**第三次返工（2026-09-18，实现者；两项人工试玩缺陷＋触发／配色映射定稿）**：

域：`ui/impact_feedback.gd`、`ui/main.gd`（`_submit` 反馈节）、`ui/visual_theme.gd`（三个边框色 token）、`core/resource_feedback.gd` 的 `FIELDS`、`tests/impact_feedback_ui_cases.gd`、`tests/pressure_cases.gd`；契约 `docs/spec/response-pipeline.md`（`play` 接口行与输入域）。本条**取代**本案例上文两处已被推翻的措辞：①「只位移 `ImpactShakeHost`、布局不动」——正是这句排布导致震动只平移了近乎透明的边缘叠加层、游戏画面从未移动（缺陷 A 的直接原因）；②「颜色语义作废／两种边框只用时长与强度区分」——改为按触发族一族一色（白／黄／蓝，映射见下）。`docs/record/changelog.md` 的 2026-09-17 瞬时反馈批次条目中「不用颜色」「只位移反馈层、布局不动」两句同样以本条为准。

**缺陷 A（震动不可见，结构性）**：`filter_bands`／`border_bands` 原先是 `ImpactShakeHost` 的子节点，震动只把边缘带平移 1.2–6px。现改为位移承载全部已提交控件的 `main.gd` GameLayout（`shake_target=host.layout`；层自身与两条叠加带不动）：`_play_shake` 在效果开始前记录 `shake_origin`，淡出中来的第二次震动沿用同一原点，脉冲结束 `_shake_finished` 按该原点**精确复位**，`_exit_tree` 中途拆卸同样复位。「不得改变布局」的验收口径改为「效果结束后整帧与效果前逐像素相同」：`real_attack` 与两条像素探针都同时断言运行期间确实位移、结束后 `ui.layout.position` 与记录原点逐位相等。幅度 `1.2/0.45/1.2/6.0` → `FEEDBACK_SHAKE_BASE_PX=4.0`／`PER_DAMAGE=0.25`／`MIN=4.0`／`MAX=9.0`（真实伤害 6–8 的挣扎卡／普攻：3.9–4.8px → 5.5–6.0px）。

**缺陷 B（低快感滤镜不可见）**：实测 pressure 6/130、rise 6 时峰值 0.0744，存档帧边缘无可辨变化。参数改为 `FEEDBACK_FILTER_ALPHA_BASE=0.14`／`PER_RATIO=0.25`／`MIN=0.14`／`MAX=0.38`，滤镜与边框共用 `FEEDBACK_EDGE_EXTENT=0.30`（dmax=0.30×半短边；滤镜原 1.0、边框原 0.18），最低强度峰值 0.1438。（工作区里曾残留一次把四个 alpha 常量改回 0.06 的未提交试验，与已提交断言矛盾，本轮已按已提交值恢复。）

**映射定稿（C）**：触发全部来自已提交 receipt 的顶层状态字段净增量＋载荷：`pressure` 净涨→粉滤镜；`charge`／`next_energy` 净涨→黄边框；`mana`／`temporary_mana`／`witch_focus` 净涨→蓝边框；载荷 `kind=="calm"`→白边框；攻击／挣扎／滑脱→震动。`core/resource_feedback.gd` 的 `FIELDS` 加 `witch_focus`（加性、同一通道；该键只在女巫角色 state 上存在，`capture` 用 `state.has` 跳过缺失键，其他角色不受影响）；`ui/main.gd` 的 `instant_fields` 同时抑制它与 `pressure` 的浮字（含 flask 分支）。每族一行声明表 `FEEDBACK_BORDERS`（色 token＋峰值＋淡出），触发字段声明表 `FEEDBACK_BORDER_FIELDS` 的键序即优先级；`border_kind_of` 先判 calm 载荷、再按表返回首个净涨族，故**一次提交只出一条边框**：白＞黄＞蓝。色 token 落 `ui/visual_theme.gd`：`BORDER_CALM`(f2ede0)／`BORDER_CHARGE`(e8c47b)／`BORDER_MANA`(8fd3ee)，效果层无内联 hex。淡出中来的新触发换族色与标签、保留原包络时钟（不重启）。

**三条像素判据实测**（真实窗口 `root.get_texture().get_image()`；判据：震动内容区 max≥24/255 且差异像素占比≥2%，滤镜／边框边带内 mean≥3/255 且 max≥12/255；`build/checks/20260918T011931131-4724`）：
- 震动：峰值帧 vs 提交前帧的**内容区**（去掉 0.30×半短边边带）max=**243**、share=**0.6645**、mean=14.492，观测峰值位移 5.9px；效果结束后整帧 max=0、share=0（逐像素相同），直接脉冲探针观测位移 5.4px。
- 滤镜：最低强度（pressure 2/130、rise 2，峰值 0.1438）边带内 mean=**14.240**、max=**47**、share=0.9751。
- 边框每色一档：白（calm 载荷＋真实深呼吸的 `next_energy` 净涨，像素路径证明优先级）mean=**40.290**、max=**95**；黄（`charge` 净涨 +1）mean=**49.149**、max=**140**；蓝·魔法预备（`temporary_mana` +4）mean=**43.429**、max=**117**；蓝·精神集中（`witch_focus` +2）mean=**43.429**、max=**117**。

**门禁（同一冻结树；两轮 `summary.json` 的 before／after 都是 `A6CB801C3FB9D9B7CF68B63E4E2AC2560376F6D21EAC9074695BBB7BF7BC2926`，即运行期间 `spire-godot` 源码未变）**：
- 规则门 `-Suite runner,architecture,core,persistence,pressure,rewards,event_flow,casting -TimeoutSeconds 1800` → 退出码 0、8/8 PASS、`PASS: 5965 assertions`、98.5s（`build/checks/20260918T012810867-34568`）；新增 3 条 `tests/pressure_cases.gd` check（女巫 魔法预备 提交的 receipt 携带 `witch_focus`＋`temporary_mana` 增量、该 receipt 判为蓝族、精神集中被消耗的释放不触发任何边框）。
- 窗口门 `-UIOnly -UISuite impact_feedback,display,home,interface,route,pressure,rewards,persistence -KeepGoing -TimeoutSeconds 1800` → 退出码 1、8 套件全部跑完、`UI FAIL: 1349 assertions`；逐套件 display 141／home 113／route 134／interface 355／pressure 79／impact_feedback **110**（原 95：＋触发／优先级／色 token 8、＋蓝族重染 1、＋边框像素探针 6——原单条 calm 探针 2 条断言改为白／黄／蓝预备／蓝集中四条共 8 条）／rewards 313／persistence 104（`build/checks/20260918T011931131-4724`，465.6s，`-TimeoutSeconds 1800` 下 rewards 未被杀）。红项与登记集合完全一致、无新增红：`interface` 的 `CARD ART`（28 张 `witch_*` 缺立绘 1 条）＋`pressure` 2 条 `CALM UI` ＋`rewards` 1 条 `REWARD UI`（`UI ENGINE ERRORS: 4`＝这 4 条）。
- 冻结 oracle：两个 `summary.json` 的 before／after 逐字节相同（上表 digest）；内容 oracle 逐字不变——`TRANSITIONDIGEST 14eb8cf9c3c8b5d4347b2b9d118b8c504596e04d296d091884995bc359b522b6`（31 场景 0 失败）、`EVENTDIGEST 1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da`（94 场景 0 失败）；脚本与基线 sha256 与上文登记值一致（transition 脚本 `59d41c68…`、基线 `ba979d18…`；event 脚本 `cf48529a…`、基线 `bdf08765…`）。

**可触发场景（人工口径，写入记录）**：挣扎与滑脱只在压力练习房可触发（菜单 `Practice_pressure`，UI 用例走 `t.start_practice("Practice_pressure")`）；密集装备的战斗夹具里打击被拘束手臂拦住、深呼吸被口部拘束具拦住，两者都到不了提交，所以真实点击用例必须落在练习房，战斗夹具只能覆盖普攻与法力支付。

**未验证**：全量回归（`-Suite all`／`-UISuite all`）、Android 真机、打包与发布；蓝边框的 `witch_focus` 只在规则侧 receipt＋直接 `play()` 的真实帧像素探针上验证过，未经女巫存档的真实点击提交；真实拖拽只覆盖挣扎卡（滑脱／magic_slip 的幅度与步长由 `shake_spec` 单元用例＋同一像素通道覆盖）；两次提交重叠窗口内的族色切换观感未人工确认。

**第四次返工·审查五项收口（2026-09-18，实现者）**：

域：`ui/visual_theme.gd`（新增令牌）、`ui/main.gd`（`OVERLOAD_COLOR` 改读令牌）、`ui/impact_feedback.gd`（两处回退色改读令牌）、`tests/impact_feedback_ui_cases.gd`（两条新证据＋像素判据改写）；契约 `docs/spec/response-pipeline.md` 不变，无规则／候选／存档／随机改动，无玩家文案。

- ① **门禁溯源更正**：第三次返工登记的 **`A6CB801C…`** 两轮（`build/checks/20260918T011931131-4724`、`20260918T012810867-34568`）是**提交前工作区**的指纹（交付提交 `5ef9173` 的树指纹为 `30D93BEC…`），不构成交付版本证据。本次已在交付提交 **`07795c6`** 复跑（其后仅有 docs 提交，不改源码指纹）：**原登记为提交前工作区，已在 `07795c6` 复跑，指纹 `C8D361BC9F49C8F70018C5C18EB0E3E873A7A0B111AE1459141383C45FDE056C`**。
- ② **令牌收口**：`ui/impact_feedback.gd` 的 `Color("ed82b9")` 两处（`FEEDBACK_FALLBACK_COLOR` 常量与 `Bands.color` 初值）删除，改读 `ui/visual_theme.gd` 新增令牌 `OVERLOAD` 与 `FEEDBACK_FALLBACK`；`ui/main.gd` 的 `OVERLOAD_COLOR` 同步改读 `Palette.OVERLOAD`，全仓 `ed82b9` 只剩令牌定义一处。「效果层无内联 hex」自本轮起为事实。
- ③ **变更日志指针**：`docs/record/changelog.md` 追加 2026-09-18 行，点名 2026-09-17 条目中「用时长与强度区分来源，不用颜色」与「只位移反馈层、布局不动」两句已被取代，并写明新行为（边框按触发族一族一色；震动位移承载全部已提交控件的 `GameLayout` 且效果后逐像素复位）。
- ④ **新增两条测试证据**（`tests/impact_feedback_ui_cases.gd`）：`layer_contract` 在脉冲中途再触发一次震动，断言沿用首次记录原点并从该原点重新起摆，再逐帧采样断言合并后的位移峰值落在该次幅度 ±0.5px 内（不叠加）；新函数 `teardown` 在脉冲中途 `queue_free()`，断言 `ui.layout.position` 与效果前逐位相等。敏感性（`build/checks/20260918T021254362-30836`，4.7.2）：把 `_play_shake` 续振分支改成重锚原点且不做复位、并移除 `_exit_tree` 复位后，恰好这 3 条红（合并峰值 6.54px＞幅度 6.00px），其余 112 条不动。
- ⑤ **像素判据改写（隔离位移）**：`shake_pixels` 不再对照提交前帧（那会混入本次提交自身的 energy／HP／候选行变化），改为**位移峰值帧 vs 复位后帧**——两帧同处已提交状态，提交自身的变化在两侧相同而相消；`restore_pixels`（settled 状态直接 `play()`，复位帧先断言与效果前帧逐像素相同 max=0／share=0）给出完全隔离的位移判据（内容区 max≥24 且 share≥2%）。**真实含义（登记）**：位移证据＝`peak_offset`＋复位帧与效果前帧逐像素相同；share 只是辅助量级，不单独作为位移证明。

**本轮门禁（同一冻结树；引擎 4.7.2.stable.official.ed1daf0bf，`GODOT_BIN` 指向 `*_console.exe`）**：
- 规则门 `-Suite runner,architecture,core,persistence,pressure,rewards,event_flow,casting -TimeoutSeconds 1800` → 退出码 0、8/8 PASS、`PASS: 5965 assertions`、86.6s（`build/checks/20260918T020049240-17784`）。
- 窗口门 `-UIOnly -UISuite impact_feedback,display,home,interface,route,pressure,rewards,persistence -KeepGoing -TimeoutSeconds 1800` → 退出码 1、8 套件全部跑完、`UI FAIL: 1354 assertions`（第三次返工 1349＋新增 5）：display 141／home 113／route 134／interface 355／pressure 79／impact_feedback **115**／rewards 313／persistence 104（`build/checks/20260918T020228172-37196`）。红项仍为登记集合、无新增红：`interface` 的 `CARD ART`（28 张 `witch_*` 缺立绘 1 条）＋`pressure` 2 条 `CALM UI` ＋`rewards` 1 条 `REWARD UI`（`UI ENGINE ERRORS: 4`＝这 4 条）。
- 本轮像素（4.7.2 实测）：滤镜 floor mean=14.301／max=47；边框白 mean=40.245／max=95、黄 mean=49.087／max=139、蓝·预备 mean=43.403／max=116、蓝·集中 mean=43.396／max=116；震动 `peak_offset=5.8px`、位移帧 vs 复位帧内容区 mean=12.580／max=242／share=0.6160（辅助量级）、复位帧 vs 效果前帧整帧 max=0／share=0、直接脉冲隔离探针 max=243／share=0.6128（复位帧已证同于效果前帧）。
- 冻结 oracle 复跑（脚本与基线 sha256 未动，与上文登记一致：transition 脚本 `59d41c68…`／基线 `ba979d18…`、event 脚本 `cf48529a…`／基线 `bdf08765…`）：`TRANSITIONDIGEST 14eb8cf9c3c8b5d4347b2b9d118b8c504596e04d296d091884995bc359b522b6`（31 场景 0 失败）、`EVENTDIGEST 1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da`（94 场景 0 失败），逐字节与登记一致；两个 `summary.json` 的 before／after 同为 `C8D361BC…`（运行期间源码未变）。
- 环境注记：本次会话默认 `GODOT_BIN` 指向 `Godot_v4.7-stable_win64.exe`（`4.7.stable.official.5b4e0cb0f`，非登记引擎）；上述门禁、像素与 oracle 结果均在显式改用 `v4.7.2-stable` 的 `*_console.exe` 后取得，4.7-stable 下的中间结果（`20260918T015807820-17784` 等）不使用。

**未验证（本轮追加）**：新增的续振／拆卸证据是层内直接 `play()`＋`queue_free()` 路径，未覆盖重启或退场菜单触发 `_demo_exit_screen` 的拆卸；上述其余未验证项与前文相同。

**第五次返工·蓝族按 delta 触发、加减两变与强度（2026-09-18，实现者）**：

域：`ui/impact_feedback.gd`、`tests/impact_feedback_ui_cases.gd`、`tests/pressure_cases.gd`；契约 `docs/spec/response-pipeline.md`（`play` 接口行、输入域、dispatch 成功键）。`ui/main.gd` 与 `core/` **无净改动**：本轮开工时工作区里有一版把施法失败经 `core/game.gd` 的 `dispatch` 新键 `magic_failed` 透传给 UI 的未提交改动；按本轮明确口径（直接 trace delta、不得新增 `magic_failed` 键、不动 core）整段回退，两文件回到 `1378cd0` 原文，施法失败改由 receipt 净值自动落入蓝族 loss。无规则／候选／存档／随机改动，无玩家文案。

**判定与参数**（`FEEDBACK_*` 表仍是唯一参数源）：
- 触发：`charge`／`next_energy` 仍只认净涨（黄）、`pressure` 仍只认净涨（粉滤镜）；`mana`／`temporary_mana`／`witch_focus` 改为任一净变化（Δ≠0）出蓝，施法失败（付款后只返还一半的净下降）因此无需标志即出蓝；`flask_mana` 不进蓝族。优先级仍白＞黄＞蓝、一次提交仍只出一条边框。
- 变体：gain（Δ>0）＝`attack 0.10s` 上冲后 `fade 0.30s` 淡出、边带 `extent 0.34`（更宽）；loss（Δ<0）＝即刻峰值（`attack 0`）后 `fade 0.55s` 慢退、`extent 0.26`（更窄）；同一 `BORDER_MANA` token，只有包络／边带／峰值系数区分。边带经新增 `Bands.set_extent` 随变体重画，`Fade` 新增 `attack` 上升段（`ends=现在+(attack+fade)`）。
- 强度（替代阈值，无最小增量门槛）：`ratio=Σ(字段净Δ/该字段参考尺度)`（mana 用提交后 View 的 `mana_max`，临时魔力用 20 点保留上限、精神集中用 4 层上限），`peak=变体系数×min(|ratio|,1)`，loss 0.46／gain 0.34。例：−10/100 支付 peak=0.0460、+10 临时魔力 peak=0.17、−20/100 失败 peak=0.0920、`|ratio|=0.0005` 时 peak<0.001（近乎不可见）。

**新增证据（`tests/impact_feedback_ui_cases.gd`，146 断言，原 115；`tests/pressure_cases.gd` 净增 1 条）**：
- 真实失败施法（变身 40 魔力、强制低成功率、卡留手）→`border_kind=mana`、`variant=loss`、`border_ratio` 等于实际状态差的归一化值、`peak=0.46×ratio`、`border.starts==1`（只装填一次包络），边带像素 mean=**9.273**／max=**29**（判据 ≥3／≥12）。
- 真实成功支付（预备咏唱 10 魔力）→蓝 loss、peak=**0.0460**，并断言小于同池失败值 0.0920（成功支付更淡）。
- 真实魔力 gain（魔力涌流自由面 +10 临时魔力）→`variant=gain`、peak=**0.17**、`attack>0`、extent 0.34＞loss 0.26、token 不变。
- 两变体同比例断言 `mana_peak("loss",0.25)=0.115 > mana_peak("gain",0.25)=0.085`；无变化提交（真实 posture 变更）→`will_play=false` 且层根本未被创建。
- 定格像素探针：gain +10 预备 mean=**20.177**／max=**53**（focus +2 同值），loss −10/100 mean=**4.572**／max=**15**（即成功支付在自身强度上的判据）。

**敏感性（必须红）**：把 `border_kind_of` 的蓝族分支改成 rise-only（`elif delta>0.0`）→`-UIOnly -UISuite impact_feedback` 恰好 8 条红，含 `IMPACT BORDER a real failed cast lights the blue loss border from the receipt alone`、`IMPACT BORDER the successful mana-paying action draws the blue loss border instead of staying dark` 与 `BORDER mana loss` 两条像素断言（mean=0／max=0）；146→140 断言（层未创建使后续检查早退）；`build/checks/20260918T033102300-33700`。随后还原，并以 `-Suite runner`（`20260918T033202821-38336`，435 断言 PASS）复核树指纹未变。

**门禁（同一冻结树；`GODOT_BIN` 指向 `v4.7.2-stable` 的 `*_console.exe`，4.7.2.stable.official.ed1daf0bf）**：
- 规则门 `-Suite runner,architecture,core,persistence,pressure,rewards,event_flow,casting -TimeoutSeconds 1800` → 退出码 0、8/8 PASS、`PASS: 5966 assertions`、82.22s（`build/checks/20260918T024932533-9072`）。
- 窗口门 `-UIOnly -UISuite impact_feedback,display,home,interface,route,pressure,rewards,persistence -KeepGoing -TimeoutSeconds 1800` → 退出码 1、8 套件全部跑完、`UI FAIL: 1385 assertions`；逐套件 display 141／home 113／route 134／interface 355／pressure 79／impact_feedback **146**／rewards 313／persistence 104（`build/checks/20260918T025101998-27088`）。红项与登记集合完全一致、无新增红：`interface` 的 `CARD ART`（28 张 `witch_*` 缺立绘 1 条）＋`pressure` 2 条 `CALM UI` ＋`rewards` 1 条 `REWARD UI`（`UI ENGINE ERRORS: 4`）。环境注记：home 套件期间 Godot 窗口处于最小化、渲染降频使该套件耗时 1683.8s（其余 10–290s），窗口恢复后立刻回到常规速度；整套仍完整跑完、指纹未漂移，结果有效。
- 冻结 oracle 复跑：`TRANSITIONDIGEST 14eb8cf9c3c8b5d4347b2b9d118b8c504596e04d296d091884995bc359b522b6`（31 场景 0 失败）、`EVENTDIGEST 1f11bea560288ae922fc31ce7f46fb77d5cab22916798e3c1c81a00a131053da`（94 场景 0 失败），与登记逐字节一致；脚本／基线 sha256 未动（transition `59d41c68…`／`ba979d18…`、event `cf48529a…`／`bdf08765…`）。
- **交付树指纹**：规则门与窗口门的 before／after 同为 **`2D2AAD80AA0AF5A3C30D64905D3E88031588F8E706A02B42C9FB0469D758F5A0`**（运行期间 `spire-godot` 源码未变，交付提交沿用该树）。

**未验证（本轮追加）**：全量回归、Android 真机、打包与发布与前文相同；蓝族 loss 的真实像素证据取「变身失败」一条（失败卡留手、帧对干净），成功支付与 gain 的像素判据来自同比例的定格直接 `play()` 探针（成功施法会消耗卡牌、离手动画与效果窗口重叠，未做真实提交的像素对）；多字段混合符号的观感未人工确认（数值上按归一化求和并入单一边框）。

**独立复核（2026-09-18，独立会话子代理，轻量迭代口径）**：

域：`ui/impact_feedback.gd` 与 `tests/impact_feedback_ui_cases.gd`（提交 `51bfcfb`，交付树指纹 `2D2AAD80…`）；本会话不改产品代码，只读核对差异，敏感性改动用完即还原。

- 差异核对（只读）：`border_kind_of` 的非 rise-only 分支为 `elif delta!=0.0`；`FEEDBACK_BORDER_RISE_ONLY={"charge":true}`；蓝族字段表为 `mana`／`temporary_mana`／`witch_focus`（`flask_mana` 不在）；`border_spec` 的 gain／loss 行与 `mana_peak` 的 `min(|ratio|,1)` 均取自 `FEEDBACK_*` 表；`core/` 与 `ui/main.gd` 相对 `1378cd0` 无净改动。
- 独立窗口门：`tools/check.ps1 -UIOnly -UISuite impact_feedback -TimeoutSeconds 1800`（`GODOT_BIN` 指向 `v4.7.2-stable` 的 `*_console.exe`，4.7.2.stable.official.ed1daf0bf）→ 退出码 **0**、`SUITE RESULT: impact_feedback PASS`、**146 断言**、46.9s（`build/checks/20260918T033423088-27392`；before／after 同为 `2D2AAD80…`）。像素实测：失败施法 loss 边带 mean=9.244／max=38，蓝 gain 探针 mean=20.132／max=54，蓝 loss 探针 mean=4.514／max=16，滤镜 floor mean=14.302／max=47，震动 peak_offset=6.0px、隔离位移 max=243／share=0.6145、复位帧整帧 max=0／share=0。
- 敏感性（独立复现，与实现者报告一致）：把蓝族分支改成 rise-only（`elif delta>0.0`）→ 同一套件 **8 条红**、`SUITE RESULT: impact_feedback FAIL`、退出码 1、146→140 断言；红项含 `IMPACT BORDER a real failed cast lights the blue loss border from the receipt alone`、`IMPACT BORDER the successful mana-paying action draws the blue loss border instead of staying dark`、`BORDER mana loss` 两条像素（mean=0／max=0）；`build/checks/20260918T033536000-37300`，修改树指纹 `5FD8B57A…`（与实现者敏感性运行逐字相同）。随后 `git checkout` 还原：`git status` 干净、`border_kind_of` 回到 `elif delta!=0.0`、交付树指纹不变。
- **本轮未跑：规则门／oracle／性能测量**（按人指示"不必每次都测效率"，留到定稿轮）；像素判据未另跑独立脚本或截图，只随 `impact_feedback` 套件执行。实现者会话同轮另行跑过规则门与冻结 oracle（数字见上一段），不在本复核范围内。


## 2026-09-18｜PR #4／#5 本地整合验证

**来源与范围**：主分支基线 `80abcd71c99225e51916d163f5e9ae6c5372d402`；PR #4 `08b2caf57b312797a965cb020ed193145f8e87c3`；PR #5 `63993badc0a6c1425a5a0ca38432188c2fffc0a3`。#5 包含 #4；按用户「以 PR 为优先」完整接纳其目录、根指引、项目 skills、打包路径及反馈实现，保留独立审查发现的必要补修。没有并入 #2 后续提交或 #3 macOS 打包。

**补修域**：`ui/impact_feedback.gd` 的 `Fade.refresh` 保持同一 Tween 的时间线，仅调整当前强度，连续 gain 不再重播上升段或延长结束时间；`ui/main.gd` 的 `_clear_impact_feedback` 收口返回主页、结束画面与重启时的清理，立即恢复布局原点。`tests/impact_feedback_ui_cases.gd` 增加 9 条断言（146 → 155）。文档区分已实现的 `_submit`／`render` 与规划中的 commit／present／dirty section，明确 UI 复用要求可证明的失效条件，README 更新为现行 0.17.1 与新入口。独立子代理完成文档、调用边界与补修测试审查，没有剩余阻塞意见。

**规则检查**（日志均在整合工作树 `spire-godot/build/checks/`）：

- `20260918T045136391-25052`：`-Import -Suite architecture,pressure -UI -UISuite impact_feedback -KeepGoing`，architecture 471＋pressure 1085＝1556 条规则通过；上游反馈 146 条通过，退出码 0。此轮早于反馈清理／时间线补修，指纹 `69641D4BA790366B715EFB94D6C7B4E2BCBA28D37FF800AF021ACC52A93135A1` 前后一致；后续仅 UI 补修，没有改这些规则实现或规则测试。
- `20260918T045940041-2024`：`-Suite core,persistence,witch_character -KeepGoing`，core 888＋persistence 955＋witch_character 455＝2298 条通过，退出码 0。合计 3854 条规则断言通过，属于两轮分类检查，未宣称全量回归。
- 全新 worktree 第一次导入 `20260918T045058786-49172` 因尚未生成的字体缓存 `.fontdata` 报错；保留失败日志，第二次导入成功，没有以引擎退出码 0 掩盖首次错误。

**界面检查与原版对照**：

- 整合工作树 `20260918T045553428-42872`：`-UIOnly -UISuite impact_feedback,home,home_persistence,enemy_feedback,pressure,rewards,interface -KeepGoing`，全部 7 类运行完成，共 1107 条断言；impact_feedback 155、home 113、home_persistence 51 全部通过，其余四类共 8 条失败，退出码 1。
- 未改动的主分支基线 `20260918T050041299-48564`：独立运行 `enemy_feedback,interface,pressure,rewards`，788 条断言，退出码 1。逐条比较日志，8 条失败的文本与顺序完全相同，没有新增失败。
- 既有失败为 enemy_feedback 4 条（旧 `InstalledTool_item_1` 入口与剩余使用次数交互断言）、interface 1 条（28 张 `witch_*` 卡缺插图）、pressure 2 条（深呼吸描述）、rewards 1 条（最终解锁段描述）。这些失败保留，没有删除有效失败断言换取绿灯；本次不把它们记为已修复。
- 补修后 UI 与规则补查的 before／after 指纹均为 `918750D99A085B68B2F1A5B608A6DBBEC0A5C15F35EC4626B270B3635FC167CE`，运行期间源码没有漂移。反馈套件含真实提交、Tween 确定性推进及逐帧像素检查，未保存默认截图。

**迁移与成品**：当前文档、根入口和 skills 的 29 份 Markdown 链接检查通过；不存在残留的 PR 旧目录受版本管理副本。Windows 验证导出 `pr45-validation-20260918` 与 `check-package.ps1 -WitchBalance` 通过，探针 `package-check-20260918T050054756` 验证导出程序、PCK、资源、内容、新游戏、练习、存档隔离、快照与小魔女平衡。导出的版本说明、Godot 两份许可文件与新位置源文件 SHA-256 一致。Windows 与 Android 打包脚本均使用新许可路径，Android include filter 包含 `packaging/licenses/*.txt`；本轮没有生成或安装 Android 包。

**交付边界**：本地整合，不自动合并 GitHub PR、不推送、不改版本号、不发布 Release。未跑全量规则／全部 UI、全种子／独立冻结 oracle、Android 真机与 macOS；小魔女 focus 的真实点击像素链及多次效果重叠观感仍沿用 PR 记录的未验证边界。

**补修敏感性实测**：临时把 `ui/main.gd` 与 `ui/impact_feedback.gd` 换回 PR #5 原实现，保留新增测试；`20260918T050537005-37408` 的 impact_feedback 155 条中恰好 7 条失败（刷新包络 5 条、返回主页清理 2 条），退出码 1。这是主动回退缺陷的预期失败，不能混入前述 8 条基线失败；运行前后指纹一致。完成后已在 finally 中恢复两份补修源码，Git 确认与暂存的交付实现一致。

**恢复补修后复验**：`20260918T050752116-23240`，impact_feedback 155 条全部通过，退出码 0，前后指纹恢复为 `918750D99A085B68B2F1A5B608A6DBBEC0A5C15F35EC4626B270B3635FC167CE`。真实震动复位像素 mean／max／share 均为 0。

**主工作区同步验证**：完整补丁已应用到主工作区，147 个变更路径（包含删除项）与整合候选逐一核对一致。主工作区 `20260918T050947519-21640` 运行 `-Import -Suite architecture`，引擎导入成功、471 条架构断言通过、退出码 0。主工作区原始字节指纹 before／after 均为 `31358B427CF948CE1870A749B8A4DE37880E5D60408568A050C4303E4C039332`；与 worktree 指纹不同的原因是已有 checkout 的 LF／CRLF 差异。按检查器同一文件集合核对 632 份文件，仅 334 份文本换行不同，归一化后源码与资源完全一致，未改写这些无关文件的换行。更改保留在本地工作区，未创建提交、未推送、未合并远端 PR。


## 2026-09-18｜v0.17.2 发布准备与专项复验

用户明确要求推送为 0.17.2，并按上版提供 Windows、Android 与双层加密合集。当前整合源码未继续修改运行时规则；project.godot 与两平台预设统一为 0.17.2，Windows 文件版本 0.17.2.0，Android 安装版本 10 → 11，包名与原签名入口保持。

发布专项 `20260918T051429212-46436`：`-Suite runner,architecture -UI -UISuite impact_feedback,home,home_persistence,persistence,display,touch -KeepGoing`，规则 906、UI 588 条全部通过，退出码 0；before／after 指纹 `F25C673B7E8AC574DD230407339E93A5FBC38C220A18B6C5267394CE2125D972` 一致。既有 8 条界面失败仍按前文对照证据披露，本轮不重跑不相关失败分类，不声明全项目或全部种子通过。版本、说明路径、Android code 与签名边界已由独立只读子代理审查，无发布阻塞项。

**正式成品与压缩验收**：Windows 构建 `package-release-20260918`、成品探针 `package-check-20260918T051716988` 通过；PE 文件版本／产品版本均为 0.17.2.0。Android 构建 `android-release-20260918`、APK 资源探针 `android-probe-20260918T051750789` 通过，versionName 0.17.2、versionCode 11；与 v0.17.1 的证书 SHA-256 相同（`9da2962a178eec7a6be1bb45c77c37372c0f18c2f2efe313e3f8aad07cdd0608`），V2／V3 签名、16 KB 对齐、provider 唯一性及 12 份内置内容校验通过。两平台 440 份导出源码清单一致；APK CRC、迁移后的两份 Godot 许可原文与开发／存档文件排除检查通过。

产物目录 `outputs/release-v0.17.2-20260918/`：Windows64 ZIP、Android ZIP、独立 APK、PC＋Android 双层加密 7z、README 与 SHA256SUMS。两个普通 ZIP 已实际解压并逐文件 SHA256 核对；内外两层 7z 均使用本次指定密码和加密文件名，错误密码不能列出目录；外层解压后内层文件 SHA256 一致，再解内层后的 38 份文件逐个与原成品匹配。没有把只测试外层当作完整验证。包内说明及发布页均披露前述 8 条旧失败；未执行完整回归或 Android 真机验收。原始日志和解压证据保留在已忽略的 build／outputs，本批不进入源码提交。


## 2026-09-19｜练习生命说明、英文与内容取数边界

基线 `79c499a`（v0.17.2）。用户截图指出玩偶师、杂乱拘束具、绳蛇与多面手练习说明滞后，要求相关内容及测试及时更新。核对发现注册表与敌人设计总表已经一致，错误位于 `data/equipment_catalog.gd::entries` 的独立文案副本。

本批将 7 条含生命数值的练习说明改为从 `Enemies.TYPES` 动态生成，双怪练习继承同一来源；同步玩偶师开场携带玩偶、首次行动激活反击与嘲讽的实际流程。`enemy_health_cases.gd::practice_descriptions` 增 24 条：8 场正式 `LiveGame` 初始化核对说明与实际生命、读取前后快照相等，并临时改变注册表后重新初始化，证明文案不会停留在硬编码常量。临时注册表值每次恢复，不改游戏平衡。

英文经现有 inventory／build_english_catalog 流程更新：7 个生命动态模板改为完整人工译文，补齐扫描发现的 16 条现有缺译。旧源文删除 15 条，新增 23 条，最终 4959 条；其余共有源文的 ID 与译文完全未变。生成器按既有源文顺序输出，避免无关整表重排。`localization_cases.gd::run` 增 16 条，覆盖 8 场当前与调整后生命的完整英文显示。第一次生成因本地缺离线翻译依赖及 16 条未缓存源文而停止；补充人工译文后成功，不安装额外运行时依赖。

规则门 `20260919T050822758-32408`：`-Suite architecture,enemies,localization,content -KeepGoing`，architecture 471、enemies 1817、localization 156、content 574，共 **3018** 条通过，退出码 0；before／after 指纹 `38E00ACB19032C0AB4E888A7CF76AFE2CC649E55D46098B8777D7CA7FFEA5494` 一致。随机池采用日常采样，未称全部种子通过。

内容 CLI 独立进程探针 `build/content-cli-20260919`：正式目录 12 文件校验通过（退出 0），损坏 JSON 与不存在目录均失败（退出 1）；空目录返回 0 文件合法（退出 0），这只证明目录内没有非法定义，不能当成完整内容验收。现有 content 用例同时覆盖批次注册失败不留下部分数据、重复初始化不重复登记。`docs/design/content.md` 明确 Wiki／导出必须额外检查加载报告与所需内容集合，每次用新进程，基础生命与遭遇覆盖值分列；当前没有 Wiki 构建器，本轮不把 CLI 结果登记成 Wiki 导出验收。人工文章应登记适用源码及依赖，依赖改变后标记待复核。

独立只读子代理核对新增依赖无环、正式开局和查询只读性、玩偶流程、临时注册表恢复、翻译语义差异与文档边界，无阻塞问题。本批仅源码／测试／文档维护，不修改已发布 v0.17.2 标签或安装包，不推送、不打包；全量回归及安卓真机未执行。

**窗口复验**：`20260919T050947917-22676`，`-UIOnly -UISuite localization`，51 条断言通过、退出码 0，指纹与上述规则门相同。覆盖真实语言选择、英文主页／设置及商店、事件、战斗显示；未请求或生成默认截图。

**后续同步授权（2026-09-19）**：用户要求更新 GitHub，本批以维护提交同步 main；提交前复算源码指纹，与上述 3018 条规则及 51 条窗口断言通过的版本完全一致，复用已有证据，不重复运行。此次仅同步源码、翻译、测试与文档，v0.17.2 标签、Release 附件及本地安装包保持原发布内容。

**2026-09-19 五级＝普通牢房最小基线**（分支 `feedback-effects`；成果提交见 `changelog.md` 同日条）：

域：`core/prison.gd`（`Prison.enter` 统一入场、删除 `high_security`／终局校验与文案）、`core/game.gd`（`TRANSITIONS` 去掉 `prison_high_security`、`restore_snapshot` 丢弃旧键）、`core/snapshot.gd`（去掉 `capture.terminal_equipment` 类型校验）、`data/tutorial.gd`、`docs/design/prison.md` §5／`equipment-design.md` §12／`content.md`、`docs/spec/equipment-query-seam.md`／`transition-pipeline.md`；测试域 `prison`（TERMINAL 正反例）、`relics`（`axe_amulet`）、`status`、`pressure`、`persistence`、`prison_ui`、`architecture`（索引 parity 文案）。

改动与判据：

- 五级入场与一至四级同一条路径（`RelicEffects.begin_combat` → `Prison.initial`（`left=8`）→ `Space.initial` → 躺姿靠墙 → `_reset_piles` → `begin_turn`），不再调用 `high_security()`、不再写 `prison_end`、不再写 `capture.terminal_equipment`；`prison_end` 相位声明、`status_view`／`main.gd` 只读投影保留，只服务旧档。追加与替换仍由 `PRISON_SECURITY[5]`（高级／三档／普通＋定制复合）与 `PRISON_INTERVALS[4]`／`PRISON_SENTENCE[4]` 表驱动；传送符仍限 1–4 级（`core/tool_rules.gd::escape_reason` 未改），五级只剩开门／通风口／钥匙三条路线（prison.md §4／§5 已写明）。
- 旧档 `capture.terminal_equipment` 处理采用**读档时丢弃**（`Game.restore_snapshot` 在 `validate()` 前 `erase`），快照侧的独立类型校验删除；正例与旧档各验证一次：套件内 `TERMINAL legacy manifest is accepted and dropped on load without touching the cell`（注入旧字段后 `restore_snapshot().ok`、键被丢弃、`phase` 仍为 `prison`，且随后仍能正常 `end`），以及一次性探针 `build/probe/prison_probe.gd`（打印 `legacy restore ok=true has_key=false phase=prison`，登记后已删除）。
- 规则门（冻结树；退出码 0）：`tools/check.ps1 -Suite prison,persistence,equipment,relics,pressure,status,tower_progression,exploration,architecture -TimeoutSeconds 1800` → 9/9 PASS、`PASS: 5513 assertions`、106.56s（`build/checks/20260918T170243518-9668`；`before==after==6D92FE378D8FF733EB182308DA4187DA0C1848910E0D7935F6ABAC1E576B4EFC`，无 `SOURCE CHANGED`）。**红集为空**，无既有登记外的红项；请求中的 `demo_exit`／`prison_space` 在本修订不是注册分类（`tests/test_game.gd::SUITES`），改由 `tower_progression`（内含 `demo_exit_cases.run`）与 `exploration`（牢房空间）承载，另加断言被改的 `relics`／`status`／`pressure`／`architecture`。
- 窗口门（同一冻结树；退出码 0）：`tools/check.ps1 -UIOnly -UISuite prison -TimeoutSeconds 1800` → `UI PASS: 217 assertions`、131.99s（`build/checks/20260918T170437205-44524`；before／after 同指纹）。断言含 `TERMINAL UI five opens the ordinary cell with the shortest patrol and live actions` 与「无 `本次逃脱失败`／`高安全监室` 文案」两条新判据。
- 关键正反例（`tests/prison_cases.gd::remaining_routes`）：security 5 入场后 `phase=="prison"`、`left==8`、`turn==1`、追加 6 件高级三档普通／复合 + 2 件高级三档特殊 + 1 个上锁限制项圈、原有复合结构与口部带保留、`validate()==""`、有巡视计时与逃脱候选；反例为 `not capture.has("terminal_equipment")`、无 `prison_end`、无终局清单；另加 8 个种子跨档复核。

**未验证（本轮未跑）**：oracle（迁移／事件）、像素判据、性能测量——按人指示留到定稿轮；全量回归、`normal_play` 长跑、Android 真机、打包与发布与前文口径相同。`build/transition-oracle-20260916/transition_oracle.gd` 仍引用已删的 `prison_high_security` 场景，本轮未运行也未更新（属未入库产物）。

**2026-09-19 内容包根改为单一常量 + 打包断言**（分支 `feedback-effects`；成果提交见 `changelog.md` 同日条）：

域：`core/content_catalog.gd`（`PACKS_ROOT`／`packs_root()`）、`tools/assert-packs-root.ps1`、`tools/package.ps1`、`tools/package-android.ps1`、`tools/launch.ps1`；测试域 `content`（`packs_root_single_switch`）与 `architecture`（`content_pack_root_has_no_build_feature_branch`）。契约：`docs/spec/packaging.md`（取值、翻转步骤与断言的唯一正文）、`docs/spec/project-map.md`（目录表指针）。无规则／候选／随机／存档改动，无玩家可见文案，不新增第二套内容包加载。

改动与判据：

- 常量与访问器：`const PACKS_ROOT := "res://content/packs"`（注释英文写明：发布值为 `"adjacent"`、打包前翻转打包后改回、见 packaging.md）；`packs_root()` 是唯一读取点——`"adjacent"` → `OS.get_executable_path().get_base_dir().path_join("content/packs")`，其它值原样返回。`ensure(g,root)` 的显式 `root` 参数与 `Catalog.report.directory` 不变。
- 删除：原 `directory()` 的构建类型判断（`OS.has_feature("editor")`／`("android")`）；`tools/launch.ps1` 仍只拼 `--path <游戏目录>`（本分支从未传入该开关，未改）。`core/`・`ui/`・`data/` 内除 `content_catalog.gd` 外无 `content/packs` 字样（扫描断言）。
- 打包断言：新增 `tools/assert-packs-root.ps1::Assert-SpirePacksRoot -GameDirectory <模块> -Expected <值>`，正则取 `^const PACKS_ROOT` 的字符串字面量，不符即 throw，消息含文件绝对路径与要改成的整行（`... change that line to: const PACKS_ROOT := "<值>"`）。两个打包脚本在第 8 行（先于产物目录创建、先于 `--export-release`）调用：`package.ps1` 断 `"adjacent"`，`package-android.ps1` 断 `"res://content/packs"`；两处都不自动翻转。
- Android 断言方向与派单文字不同，依据（技术事实优先）：Android 预设 `include_filter` 含 `content/packs/**/*.json`、`exclude_filter` 不排除 content，`tools/check-android-package.ps1` 也按 `SPIRE_PROBE_CONTENT='res://content/packs'` 探针，APK 旁没有可写内容目录——跟随 Windows 断 `"adjacent"` 会让装机版读不到内容。Windows 预设 `exclude_filter` 含 `content/*`（不进 PCK），故断 `"adjacent"`。文档同口径。
- 测试：`tests/content_cases.gd::packs_root_single_switch` 三条（`PACK ROOT the constant keeps the development value res://content/packs`／`... a value other than adjacent is used as the pack root itself`／`... adjacent resolves to content/packs beside the executable`，末条为源码解析式静态断言，因常量不可在运行中改写）；`tests/architecture_cases.gd::content_pack_root_has_no_build_feature_branch` 保留无 `has_feature("editor")`／`has_feature("android")`，加常量＋访问器、删除物不得回归（`packs_root_switch`／`resolve_packs_root`／`packs_root_cache`）与「只有 `core/content_catalog.gd` 拼内容包路径」（扫 `core/`・`ui/`・`data/`；文件枚举抽成 `script_files(root)`，原 `transition_core_files()` 改为其调用，行为不变）。开关、覆盖、缓存三条镜像用例按派单删除。
- **敏感性（实测，改完即还原）**：把 `PACKS_ROOT` 临时改成 `"adjacent"` → `-Suite content` 5/483 红，前两条即新判据 ①`PACK ROOT the constant keeps the development value res://content/packs` ②`PACK ROOT a value other than adjacent is used as the pack root itself: C:/1/Tools/Godot/v4.7.2-stable/content/packs`（②同时实测证明 `"adjacent"` 解析到当前可执行文件（Godot console exe）同级的 `content/packs`），另 3 条为内容包整体加载失败连带的既有 `EVENT CONDITION` 断言（`build/checks/20260919T050936427-45868`）；同改动跑 `-Suite content,architecture` 时 architecture 阶段红 1 条 `ARCH the pack root is one constant behind the single packs_root entry`＋1 条连带 `ARCH definition accessor resolves a shipped event` 并停止后续分类（`build/checks/20260919T050912171-29136`）。
- **打包断言探针（一次性 pwsh，跑完已删除）**：`build/packs-root-guard-probe.ps1` 与翻转副本 `build/packs-root-guard-probe/core/content_catalog.gd`，四例四中：真实树×`"adjacent"`→FAIL、真实树×`"res://content/packs"`→PASS、翻转副本×`"adjacent"`→PASS、翻转副本×`"res://content/packs"`→FAIL；失败消息形如 `Content packs would not load: PACKS_ROOT is "res://content/packs" in C:\1\magic-spire\spire-godot\core\content_catalog.gd. This export needs "adjacent"; change that line to: const PACKS_ROOT := "adjacent"`。探针脚本与副本已删除（断言未实跑导出）。
- 文档：`docs/spec/packaging.md`「域」收「常量决定＋二值语义＋翻转步骤＋两脚本断言」，Windows／Android 流水线段各留本平台一句；`docs/spec/project-map.md` 目录表只留指针；`spire-godot/content/README.md` 未改（其「导出后用可执行文件旁目录」仍与发布值一致）。

**门禁（冻结树；`GODOT_BIN` 指向 `v4.7.2-stable` 的 `*_console.exe`，`Godot Engine v4.7.2.stable.official.ed1daf0bf`）**：

- 规则门 `tools/check.ps1 -Suite content,application,runner,architecture -TimeoutSeconds 1800` → 退出码 **0**、4/4 PASS、`PASS: 1563 assertions`、21.99s（`build/checks/20260919T050954359-15932`；before==after==`FD814F2C5065EEB9475BE0B0F5F35303E6340D8BD2C29096BBC7C838A2E244D5`，无 `SOURCE CHANGED`）。**红集为空**，无既有登记外的红项。断言数 1560→1563（content 5→4、architecture 4→8）。
- 同一命令在敏感性翻转前跑过一次，同样 4/4 PASS、1563 断言、同一指纹（`build/checks/20260919T050758181-3328`）；翻转还原后指纹回到该值，说明还原是精确的。

**未验证（本轮未跑）**：oracle（迁移／事件）、像素判据、性能测量、真实打包与成品探针（`check-package.ps1`／`release_probe.gd`）与 Android 真机——按人指示留到定稿轮；打包脚本只跑了断言探针，**未执行 `package.ps1`／`package-android.ps1` 全流程**、未向 `outputs/` 写产物（断言位置与顺序为静态核对：第 8 行，先于产物目录与 `--export-release`）；`tools/launch.ps1` 未实跑启动游戏；`content/packs` 未改动，未跑 `tools/check-content.ps1`；未入库的 `tools/play_release.ps1`（协调者所有）仍在传已删除的 `--packs-root` 开关（第 115 行与第 10 行注释），本轮未改，需其同步；未打包、未推送。

**2026-09-19 牢房计时在战斗内暂停＋战斗不重置牢房位置**（分支 `feedback-effects`，成果提交 `8cb7db5`）：

域：`core/prison.gd::completed_turn`（战斗相位守卫）、`core/prison.gd::execute` 的 `"resist"` 分支（删除 `wall_distance` 复位）；测试域 `prison`（`tests/prison_cases.gd::battle_pause_cases`）。契约：`docs/design/prison.md` §2（计时与开战位置的唯一正文）。不改候选、随机域、存档结构与 UI 只读投影；`prison.left` 仍只有 `Prison.end_turn` 一个递减点，`served_turns` 仍只有 `completed_turn` 一个递增点，到期判定仍只有 `release_inspection` 一处。

改动与判据：

- `completed_turn` 在 `state.phase=="battle"` 时直接返回 false：不推进 `served_turns`、不做 `release_inspection`。出口战不受影响（`Prison.escape` 已清空 `state.prison`，首行 `active` 守卫即返回）；`is_exit_battle` 的练习入口同路。
- 计时路径核实（结论，战斗内没有第二条推进牢房计时的路径）：`prison.left` 仅 `Prison.end_turn` 写，而它只在 `game._end_turn` 的 `state.phase=="prison"` 分支被调用；`Prison.begin_turn` 只写 `prison.turn`，其四个调用点（`Prison.enter`／`end_turn`／`execute "resume"`／`after_preparation`）都不在战斗内；`tick_reinforcements` 只写 `reinforcements`；`release_inspection` 仅由 `completed_turn` 调用。
- 位置：删除 `"resist"` 行的 `g.state.wall_distance=g._initial_wall_distance(true)`；`prison.space.position` 原本就未被改写，返回牢房由 `Prison.after_preparation` 从 `Space.wall_distance(prison.space.position)` 重算。牢房内进入战斗的入口只有 `execute "resist"` 一处（`Prison.exit_practice` 先 `escape` 再打 `prison_gate` 出口战，`prison` 已清空；塔路 `_start_battle` 与牢房无关）。
- 文案：`execute "resist"` 的日志「巡视暂停」与 `Prison.won` 的「巡视继续暂停」经核对与新口径一致（战后持钥匙返回牢房，巡视倒计时仍暂停），`data/tutorial.gd`「战斗期间暂停巡视」同样一致，均未改。
- 文档：`docs/design/prison.md` §2 计时条改写为「牢房与返回牢房前的整备共用正式结束回合计数（刑期按完整回合累计，巡视倒计时只在牢房相位递减）；反抗战期间整套牢房计时暂停：巡视倒计时与刑期都不推进，出狱到期检查也不会在战斗内触发，返回牢房后从暂停处继续」；§2 反抗条补「战斗开始时保留当前牢房位置，不重置离墙距离」。
- 新具名 check（英文、点名域，全部在本轮门禁中真实执行）：`PRISON resistance starts a real battle from the cell`、`PRISON battle start keeps the cell wall distance and never repositions the player`、`PRISON battle round 1／2 neither advances the clock nor runs the due release check`（到期日在战前已越过）、`PRISON resistance victory keeps the keyed cell`、`PRISON return to the cell reuses the same position, the same paused clock and recomputes its wall distance`、`PRISON first cell turn after the return runs the due check and its eight-turn delay`、`PRISON keyed patrol stays paused across the delayed due check`、`PRISON battle-pause scenario keeps a valid state`。
- **敏感性（实测，改完即还原）**：把相位守卫改回 `and false` 并恢复 `wall_distance` 复位后跑 `-Suite prison`，正好红 5 条新 check（开战离墙距离、战斗第 1／2 回合计时、返回牢房、回到牢房首回合到期），`build/checks/20260919T044534482-46904`；还原后同套件 PASS。
- 既有钉住行为未动：`release_inspection_cases` 的 `PRISON repeated due violation adds eight while keyed patrol remains paused` 与 `PRISON temporary inspection preserves normal patrol schedule` 在本轮通过。

**门禁（冻结树；本机 `GODOT_BIN` 为 `Godot Engine v4.7.stable.official.5b4e0cb0f`）**：

- 规则门 `tools/check.ps1 -Suite prison,persistence,tower_progression,exploration -TimeoutSeconds 1800` → 退出码 **0**、4/4 PASS、`PASS: 2671 assertions`、142.23s（`build/checks/20260919T052015476-11832`；before==after==`409D2AF2…`，无 `SOURCE CHANGED`）。**红集为空**，未超出既有登记项（本文件既有登记集 `card_power` 5／`installed_tools` 1／`tower_progression` 10＋1／`hand_assist` 1／`home_persistence` 3，本轮所属四套件全 PASS）。
- 窗口门 `tools/check.ps1 -UIOnly -UISuite prison -TimeoutSeconds 1800` → 退出码 **0**、`UI PASS: 217 assertions`、130.76s（`build/checks/20260919T051549108-48752`；与规则门同一指纹 `409D2AF2…`，无 `SOURCE CHANGED`）。
- 工作区说明：本轮有另一任务在同一工作区在途改动（`core/content_catalog.gd`、`tools/*.ps1`），窗口门另有三次同样 `UI PASS: 217` 但被 `source_changed` 标记的轮次（`build/checks/20260919T045244562-24840`／`20260919T050521650-28376`／`20260919T051120012-40596`）与一次在 `209dd5e` 干净基线（`git stash`）上的 PASS 217（`20260919T045003779-46524`，同样被 `source_changed` 标记），均未计作证据。

**未验证（本轮未跑，按人指示留到定稿轮）**：oracle、像素判据、性能测量；未打包、未推送。范围外行为照旧未改：战斗结束后的奖励与整备相位仍按完成回合累计刑期（只有战斗相位暂停），`state.phase=="prison"` 之外的 `end` 行为未加断言。
