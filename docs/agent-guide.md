# Agent 指引与历史入口

根 AGENTS.md 仅说明项目、命令、长期规则、禁区和验证。
网页与 Godot 的实现约束分别由各自目录的 AGENTS.md 索引；
数值调整、版本过程和详细背景应维护在模块 docs 或网页 work 文档中。

## 按任务读取

- Godot：先读 [模块指引](../spire-godot/AGENTS.md)，再读其中对应专题。
- 网页：先读 [模块指引](../game-demo/AGENTS.md)，再读规则书与对应契约。
- 追溯网页规则和旧根指令：搜索 [根指令原文归档](history/root-agent-contract-2026-09-14.md)。
- 追溯 Godot 功能与修订：搜索 [Godot 原文归档](../spire-godot/docs/history/agent-contract-2026-09-14.md)。

这两份归档是精简前的完整文件副本，保留相互覆盖的历史记录。
不要在每轮任务自动全文加载；只搜索主题并读取匹配上下文。
以最新用户要求和当前专题文档为准，归档中的旧路径、旧数值及
“本轮不打包”等一次性要求不自动成为当前任务要求。

## 维护与自动门禁

`python tools/check_agents.py` 与 GitHub Actions 使用同一检查器：

- 根 AGENTS.md：200～500 行。
- 所有被 Git 跟踪或未忽略的 AGENTS.md：最多500行、小于10,000字节。
- UTF-8、文件末尾换行、无制表符或尾随空白。
- 检查范围包括新增、尚未提交的子模块文件；依赖和忽略文件不扫描。

`python -m unittest discover -s tools -p "test_check_agents.py"` 验证门禁边界。
工作流见 [.github/workflows/agents.yml](../.github/workflows/agents.yml)。
本次不改游戏的格式配置或运行逻辑；模块已有 ESLint、构建和 Godot
检查入口继续负责代码及行为验证。不要把格式、导入排序或测试清单
复制成长篇指令；要增加约束时直接维护对应配置及门禁。

2026-09-14：两份指令原文归档时均逐文件 SHA-256 对照一致。
历史测试与发布结论保留在原位置，本次整理不重新认证任何游戏版本。
