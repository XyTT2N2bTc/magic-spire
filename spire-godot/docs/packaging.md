# Windows v0.1 打包

## Android v0.1

运行`tools/package-android.ps1 -BuildId <唯一编号>`，在上级`outputs/spire-v0.1-android-<编号>/spire-v0.1.apk`生成签名APK。使用Godot4.7.2官方Android模板、JDK17、Android build-tools35.0.1；模板自身为minSdk24／targetSdk36，支持ARM64与ARMv7。ETC2/ASTC导入与兼容渲染器开启，横屏保持16:9。原有桌面发布配置保留。

Android通过res://读取内置content/packs，运行资源、动态装备JSON及授权文件均进入包。包中不带存档、测试代码、密钥或构建工具，不申请网络和共享存储权限，禁止云端备份恢复旧安装数据。系统返回键先关闭当前窗口，没有窗口时打开菜单。

签名配置默认在`G:/CodexData/keys/spire-android/signing.json`，密码由当前Windows账户DPAPI保护；通过`-SigningConfig`指定其他本机配置。发布脚本只通过环境变量传递密码，源码及APK不包含私钥。后续覆盖安装必须保留同一签名，并递增version/code；迁移签名环境时另行妥善备份密钥。

Godot4.7.2非Gradle导出器会把所有provider的authorities写成`.fileprovider`，见[官方导出器源码](https://raw.githubusercontent.com/godotengine/godot/4.7.2-stable/platform/android/export/export_plugin.cpp)。`fix_android_manifest.py`只将AndroidX Startup的标识改回本包的`.androidx-startup`，保留其他清单事实和全部资源，移除旧签名后重新进行16KB对齐、发布签名和验签。工具校验唯一provider标识、启动入口及内容包逐文件SHA256。

`tools/check-android-package.ps1 -Apk <APK路径>`直接取APK的assets，使用主机Godot ZIP资源加载器启动包内游戏并验证主页、内容、动态资源、新游戏、练习和隔离存档；该探针不代表Android虚拟机或真机运行。触屏行为通过真实ScreenTouch／ScreenDrag输入进入正式UI，专项入口`tools/check.ps1 -UIOnly -UISuite touch`。本机暂无连接的安卓设备，设备字体、触控尺寸、系统键盘、性能及安装后启动仍待真机确认。

安卓导出配置参照[Godot官方Android导出文档](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html)。

## Windows

目标为Windows x86_64发布模板，版本0.1，EXE资源版本0.1.0.0。`export_presets.cfg`导出编译脚本、运行资源与动态装备JSON；测试、工具、文档、日志和内容模板不进入PCK。正式`content/packs`复制在EXE旁，遵循已有发布版加载入口。程序与PCK必须一起分发。

运行`tools/package.ps1 -BuildId <本次唯一编号>`在上级`outputs`建立新目录，拒绝覆盖旧目录；脚本核对导出退出码、错误、文件存在以及导出前后源码指纹，不将变化中的代码批次认定为稳定包。导出日志与源码指纹存入`build/package-<编号>`，成品含版本／文件SHA256清单和第三方授权。

模板来自[Godot 4.7.2官方归档](https://godotengine.org/download/archive/4.7.2-stable/)，完整TPZ的SHA256为`f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011`。只安装Windows x86_64、版本标记和ICU数据。导出配置参照[官方Windows导出说明](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_windows.html)，未进行代码签名。

验收分开记录：发布EXE直接运行并检查主页渲染与启动错误；`tools/release_probe.gd`用编辑器通过`--main-pack`载入同一成品PCK，验证开发脚本排除、版本、12份相邻内容包、动态贴图、新游戏、练习及隔离目录的存档读写恢复。官方模板禁止脚本／路径覆盖，因此不能声称使用发布EXE执行了该外部脚本。实际EXE的启动检查独立进行；检查使用临时用户目录，不读取或覆盖玩家存档。

运行`tools/check-package.ps1 -Directory <成品目录>`可复验清单、发布EXE启动及成品PCK。压缩前应核对本批验证记录，生成最终ZIP与SHA256，并从ZIP重新解压核对所有清单文件。完整回归存在失败、超时或未完成项时，必须在包内验证说明及交付消息中写明，不把局部通过写成全量通过。
