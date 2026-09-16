# 游戏内反馈：Gmail 转发服务部署

收件邮箱仅在转发服务固定为 **towerlover7787@gmail.com**，玩家界面的编辑页与确认页都不展示地址，客户端也不保存该收件地址。入口位于行动日志上方「问题与建议」。窗口采用左侧填写／预览、右侧截图管理、底部网络提示和提交按钮的布局。客户端支持Bug／修改建议、标题、正文、最近40条行动日志（默认不勾选）、最多3张截图、提交前预览及失败后重试。截图可直接截取游戏（自动隐藏反馈窗口）或选取本地PNG／JPEG，统一压缩成最长1600像素的JPEG附件，每张最多2MB，不上传原始文件路径。

## 当前状态

2026-09-13已使用用户授权的Google账号部署并完成运行授权，project.godot已配置公网地址。部署账号为h13942080472@gmail.com，固定收件人仍为towerlover7787@gmail.com；两者不必相同。`export_presets.cfg`的Android联网权限已打开；本轮不重新打包，Android实机收件尚未验收。

- 脚本ID：`1-syp_ASOKIj4Qv1xv2O78RBr5E4cYMJW1rG_uiMAMmTAjbHi_u0aPiMf`
- 部署ID：`AKfycbw9SHt60mspbgTUvGsDpmV1ylFKXBJ76zupmjXben_3Sh_2yDA3G0eHmDdhdFlRUoeLMA`，版本3。
- [管理脚本](https://script.google.com/d/1-syp_ASOKIj4Qv1xv2O78RBr5E4cYMJW1rG_uiMAMmTAjbHi_u0aPiMf/edit)；[服务状态](https://script.google.com/macros/s/AKfycbw9SHt60mspbgTUvGsDpmV1ylFKXBJ76zupmjXben_3Sh_2yDA3G0eHmDdhdFlRUoeLMA/exec)。状态接口不发送邮件。
- OAuth凭据仅保留在本机用户配置，不进入项目或游戏包。维护工作目录build/feedback-deploy不属于运行资源。

## 首次部署或重建（由服务维护账号完成）

1. 使用服务维护账号登录 [Google Apps Script](https://script.google.com/home/start)，创建新项目，名称可填「紧缚尖塔反馈」。收件地址继续由Code.gs固定。
2. 将 `tools/feedback-service/Code.gs` 的全部内容复制到项目的 `Code.gs`。
3. 在项目设置中打开「在编辑器中显示 appsscript.json 清单文件」，将本项目同目录的 `appsscript.json` 内容复制进去。脚本仅请求发送邮件权限，不读取收件箱。
4. 点击「部署 → 新部署」，类型选择「网页应用」。执行身份选择「我」，访问权限选择「任何人」（包括未登录用户）。授权发送邮件时确认当前账号为服务维护账号；必要时在编辑器运行doGet完成权限授权。
5. 完成后复制以 `https://script.google.com/macros/s/` 开头、以 `/exec` 结尾的网页应用地址。不要使用仅开发者可访问的 `/dev` 测试地址。把 `/exec` 地址发给维护者即可，无需提供邮箱密码或授权码。
6. 维护者在 `project.godot` 设置 `[feedback]` 下的 `endpoint="完整 /exec 地址"`，检查服务，再由用户确认进行一次实际邮件提交及收件验收，最后按发布要求打包。仅修改编辑器中的脚本不会更新已有部署；后续应「管理部署 → 编辑 → 新版本」。

浏览器打开部署地址只返回服务版本，不发送邮件。正式POST提交才调用邮件服务；服务返回 `ok:true` 表示MailApp接受了该次邮件，不保证已出现在收件箱。首次验收也应查看垃圾邮件目录。

## 限额与失败处理

- 个人Gmail账号的Apps Script邮件额度目前为每日100个收件人；本脚本再限制每24小时最多80次发送尝试，预留额度。不同账号／Google策略可能变化，实际以官方额度及 `MailApp.getRemainingDailyQuota()` 为准。
- Google服务需可访问；反馈页面明确显示「提交反馈需要开启梯子（能访问 Google 服务）」。建议使用全局／TUN模式覆盖游戏程序，只有浏览器配置代理并不保证游戏能联网。普通游戏不需要此连接。
- 服务端收件地址固定，不接受客户端提供的收件人。校验字段长度、附件数量、大小及JPEG签名，正文采用纯文本。全局每10秒最多一次新提交，串行锁防止同时重复发送；这是小规模匿名反馈入口，不是具有账号身份验证的反滥用系统。
- 客户端只在玩家确认后发送，重复点击被禁用，失败保留草稿和原反馈编号。服务端保留48小时内已发送编号的摘要以减少重试产生的重复邮件；无法保证邮件已发送、但服务在记录回执前异常退出时的严格一次送达。
- 草稿单独存储于 `user://feedback-draft.json`，与正式存档／快速SL无关。包含玩家选择的截图，点击「清空草稿」或成功提交会清空它；不收集系统用户名、设备唯一标识、任意本地文件或邮箱密码。

## 验证

`node tools/feedback-service/test.cjs` 离线验证收件人固定、参数与附件校验、去重、限额、邮件失败和建议分类，不调用Google、不发送邮件。

2026-09-13公网验收：匿名GET返回service/schema；正式Godot反馈客户端发送无效POST后收到invalid并保留草稿。随后按用户测试要求提交一封“配置测试：游戏内反馈服务已接通”，固定收件人如上；编号a89e6137d40e4f04fadd05785fd8d340，服务保存了发送成功回执。客户端最终收到ok:true与对应编号，并显示提交成功、清空测试草稿。中间跳转页曾返回404，所有重试沿同一编号；未再生成新编号或发送其他内容。该邮件不含存档、个人日志或截图。随后在收件账号Gmail中按编号全邮箱搜索，确认16:57已送达垃圾邮件；已对该封邮件点击“这不是垃圾邮件”，Gmail确认移至收件箱，完成实际收件验收。

窗口案例归既有 `interface` 分类：检查入口相对日志的位置、必填、截图、附件上限、勾选日志、预览、关闭保留、无地址、超时重试、确认成功及游戏状态不变。其HTTP传输使用测试替身，不能代替公网部署和真实收件验收。

官方依据：[Web App部署](https://developers.google.com/apps-script/guides/web)、[MailApp与附件](https://developers.google.com/apps-script/reference/mail/mail-app)、[每日额度](https://developers.google.com/apps-script/guides/services/quotas)、[ContentService重定向](https://developers.google.com/apps-script/guides/content)。客户端保留HTTPS校验，302／303仅向script.googleusercontent.com发起不带正文的GET读取回执，最多4次；不自动转发POST。实测原Godot自动跳转产生400，因此由反馈请求入口显式处理。其他地址、循环和超时继续保留草稿及原编号。

若Google提交／回执跳转未返回有效响应，客户端对原exec地址追加receipt编号，最多补查一次，不重发邮件正文。查询仅返回该随机编号的发送状态，不泄露正文、附件或收件人；补查也失败时保留草稿并停止，等待玩家明确重试。
