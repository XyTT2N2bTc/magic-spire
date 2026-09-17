# 游戏内反馈：Gmail 转发服务契约（部署与运维）

本文件是现行契约：登记游戏内反馈入口的客户端字段、服务端接口、限额与失败处理、验收边界。
本文件不写执行结果；通过／失败／未执行只登记在验证记录（`docs/record/verification.md`）。

路径约定：不带 `spire-godot/` 前缀的脚本与工程路径（`tools/feedback-service/`、`project.godot`、`build/`）
均相对 `spire-godot/`；`docs/` 相对仓库根。

## 域

- 玩家在游戏内向固定收件人递交反馈的端到端路径：客户端窗口 → Apps Script Web App → Gmail。
- 不含：游戏规则、存档格式、版本发布（见 `docs/spec/packaging.md`）。
- 服务是**小规模匿名反馈入口**，不是带账号身份验证的反滥用系统；任何"防刷"表述不得超出此口径。

## 接口

客户端与服务的唯一接口是 `project.godot` 中 `[feedback]` 的 `endpoint="完整 /exec 地址"`。

| 调用 | 语义 |
| --- | --- |
| 浏览器 / 匿名 GET 部署地址 | 只返回服务版本（`service`／`schema`），**不发送邮件** |
| 正式 POST 提交 | 才调用邮件服务；返回 `ok:true` 表示 `MailApp` 接受了该次邮件，**不保证**已出现在收件箱 |
| 回执补查（可选一次） | 对原 `exec` 地址追加 receipt 编号查询；只返回该随机编号的发送状态，不泄露正文、附件或收件人 |
| 管理入口 | [管理脚本](https://script.google.com/d/1-syp_ASOKIj4Qv1xv2O78RBr5E4cYMJW1rG_uiMAMmTAjbHi_u0aPiMf/edit)、[服务状态](https://script.google.com/macros/s/AKfycbw9SHt60mspbgTUvGsDpmV1ylFKXBJ76zupmjXben_3Sh_2yDA3G0eHmDdhdFlRUoeLMA/exec) |

- 脚本 ID：`1-syp_ASOKIj4Qv1xv2O78RBr5E4cYMJW1rG_uiMAMmTAjbHi_u0aPiMf`；部署 ID：`AKfycbw9SHt60mspbgTUvGsDpmV1ylFKXBJ76zupmjXben_3Sh_2yDA3G0eHmDdhdFlRUoeLMA`，版本 3。
- 收件邮箱**只在转发服务内固定**为 `towerlover7787@gmail.com`：玩家界面的编辑页与确认页都不展示地址，客户端也不保存该收件地址；服务端不接受客户端提供的收件人。
- 服务维护账号（部署账号）为 `h13942080472@gmail.com`；维护账号与固定收件人**不必相同**。
- 入口位置：行动日志上方的「问题与建议」。窗口布局：左侧填写／预览、右侧截图管理、底部网络提示与提交按钮。

## 输入域

客户端可提交的字段与其上限：

| 字段 | 规则 |
| --- | --- |
| 类型 | Bug／修改建议 |
| 标题、正文 | 纯文本；提交前可预览 |
| 最近行动日志 | 最近 40 条，**默认不勾选** |
| 截图 | 最多 3 张；可截取游戏画面（自动隐藏反馈窗口）或选取本地 PNG／JPEG；统一压缩为最长 1600 像素的 JPEG，每张最多 2 MB；**不上传原始文件路径** |

服务端校验：字段长度、附件数量、单张大小与 JPEG 签名；正文一律按纯文本处理。
草稿存于 `user://feedback-draft.json`，与正式存档／快速 SL 无关，包含玩家选择的截图；
点击「清空草稿」或成功提交会清空它。
不收集系统用户名、设备唯一标识、任意本地文件或邮箱密码。
网络前提：客户端必须能访问 Google 服务；反馈页面明确显示「提交反馈需要开启梯子（能访问 Google 服务）」，
建议用全局／TUN 模式覆盖游戏程序（只有浏览器配置代理不保证游戏能联网）；普通游戏不需要此连接。
Android 侧已打开联网权限。

## 失败语义

- 客户端只在玩家确认后发送；提交期间重复点击被禁用；失败保留草稿与原反馈编号。
- HTTPS 校验保留；302／303 只向 `script.googleusercontent.com` 发起**不带正文**的 GET 读取回执，最多 4 次；
  不自动转发 POST（实测 Godot 自动跳转产生 400，因此由反馈请求入口显式处理）。
- 若提交／回执跳转未返回有效响应：对原 `exec` 地址追加 receipt 编号**最多补查一次**，不重发邮件正文；
  补查也失败时保留草稿并停止，等待玩家明确重试。
- 服务端去重：保留 48 小时内已发送编号的摘要，减少重试产生的重复邮件；
  **不保证严格一次送达**（服务在记录回执前异常退出时无法保证已发送）。
- 限流：全局每 10 秒最多一次新提交；串行锁防止同时重复发送。
- 一次发送尝试 = 一个收件人；个人 Gmail 的 Apps Script 额度为每日 100 个收件人，脚本再限制
  每 24 小时最多 80 次发送尝试以预留额度；不同账号／Google 策略可能变化，
  实际以官方额度与 `MailApp.getRemainingDailyQuota()` 为准。
- 首次验收必须检查垃圾邮件目录；只收到 `ok:true` 不等于已送达收件箱。

## 证据入口

- 离线：`node tools/feedback-service/test.cjs`——验证收件人固定、参数与附件校验、去重、限额、
  邮件失败与建议分类；不调用 Google、不发送邮件。
- 公网验收：匿名 GET 返回 `service`／`schema`；正式客户端发送无效 POST 后收到 `invalid` 并保留草稿；
  再由用户确认提交一封实际邮件并按编号在收件账号 Gmail 全邮箱搜索，确认送达并完成收件验收。
  2026-09-13 的验收记录（编号、时间、跳转与重试过程）见 `docs/record/verification.md`。
- 界面案例归既有 `interface` 分类：检查入口相对日志的位置、必填、截图、附件上限、勾选日志、预览、
  关闭保留、不显示地址、超时重试、确认成功及游戏状态不变。
- 边界：HTTP 传输使用测试替身，**不能代替**公网部署与真实收件验收；桌面探针不代表 Android 真机，
  Android 实机收件仍未验收。
- 官方依据：[Web App 部署](https://developers.google.com/apps-script/guides/web)、
  [MailApp 与附件](https://developers.google.com/apps-script/reference/mail/mail-app)、
  [每日额度](https://developers.google.com/apps-script/guides/services/quotas)、
  [ContentService 重定向](https://developers.google.com/apps-script/guides/content)。

## 首次部署或重建（由服务维护账号完成）

1. 用服务维护账号登录 [Google Apps Script](https://script.google.com/home/start)，新建项目，名称可填「紧缚尖塔反馈」；
   收件地址继续由 `Code.gs` 固定。
2. 把 `tools/feedback-service/Code.gs` 的全部内容复制到项目的 `Code.gs`。
3. 打开「在编辑器中显示 appsscript.json 清单文件」，把同目录 `appsscript.json` 的内容复制进去；
   脚本仅请求发送邮件权限，不读取收件箱。
4. 「部署 → 新部署」，类型选「网页应用」，执行身份选「我」，访问权限选「任何人」（包括未登录用户）；
   授权发送邮件时确认当前账号为服务维护账号，必要时在编辑器运行 `doGet` 完成授权。
5. 复制以 `https://script.google.com/macros/s/` 开头、以 `/exec` 结尾的地址；
   **不要**使用仅开发者可访问的 `/dev` 测试地址；把 `/exec` 地址交给维护者即可，无需提供邮箱密码或授权码。
6. 维护者在 `project.godot` 的 `[feedback]` 写入 `endpoint`，检查服务，再由用户确认进行一次实际邮件提交与收件验收，
   最后按发布要求打包。仅修改编辑器中的脚本**不会**更新已有部署；后续应「管理部署 → 编辑 → 新版本」。

OAuth 凭据仅保留在本机用户配置，不进入项目或游戏包；维护工作目录 `build/feedback-deploy` 不属于运行资源。
