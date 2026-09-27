# 规划者报告：close submit-present unmount dirty filter

## 结论

**PASS 可派实现。** 非 `needs-human-review`。bunny F1 是同一接缝内的脏集过滤缺口：未区分「提交前已未挂载」与「本次提交把它卸载」。本修订收口该点，无新模块、无新允许边、无 schema／运行时依赖。通宵已授权落地既有 `present(dirty)`；切分与依赖方向未变，引用该批准。muse PASS 不能盖掉 bunny F1；橡胶章批准题不是 NHR。

契约：`spire-godot/build/submit-present-extract.md`。HEAD 起步 `a423c0c`。域：`ui/main.gd::_submit`／`_submit_dirty`；`present` 既有全量谓词；`tests/display_ui_cases.gd` 卸载残留场景。

## 为何不是 NHR

- 不新增模块、UI 文件、`present` 邻接、`commit`／`present_rejection` 符号。
- 不改既有节全量谓词、不改节体无条件重建。
- 允许实现：过滤只看提交前挂载态，或把本次卸载的节留在 dirty 走既有全量谓词。两条都在 `_submit_dirty` 内。
- Gherkin＋短 UI 验收是全部契约。①–⑦ 保持对「未挂载时局部」的敏感性；⑧⑨ 使残留变红。

## 四态（本切片）

- 通过：无本轮产品检查（规划者不跑 Godot）。
- 失败：bunny 独立审查 F1（阻断），契约已按该 finding 修订。
- 未验证：实现、display 门禁、档 2 变异、独立审查（实现后另派）。
- 经协调者授权已跳过：无。

## 指派实现者

改 `_submit_dirty`（及同文件提交前谓词取样）。新增 `submit_unmounts_closed_overlay_sections` 并注册。改写 `docs/spec/response-pipeline.md` 过滤句。`submit_presents_local_dirty_or_full` ①–⑦ 正文不改。成功提交关闭手选／详情后树上不得有 `HandSelectionBar`／`EquipmentDetails`。⑧⑨ 允许因本次卸载全量而换 `GameHeader`。不得把提交前已未挂载的节也留在 dirty（⑤ 会红）。

本会话未实现、未开 Godot、未 push、未派双审、未改全局 skill。
