# 清洁者报告：submit-present（`_submit`→`present` 接线＋F1 卸载过滤）

结论：**no-op**。本域已洁；未改产品、测试、`docs/spec`、extract。不当实现者／加固者；未重做接线；未重做 F1；未改 bunny F1' 括注、未把实现改去贴括注。未 push。

日期：2026-09-26。工作树：`C:/1/tmp/magic-spire-wt-partition-delta`；分支：`worker/partition-delta`；HEAD：`f4d111a`（起步干净）。契约：`spire-godot/build/submit-present-extract.md`（F1 修订第 4 条）。对照：`implementer-report-submit-present.md`／`implementer-report-submit-present-f1.md`；双审 PASS 钉 `f4d111a`（bunny／muse）。撞墙提取结论：无未消化产品意图，本刀只核邻接表。心跳：`tmp/agent-cleaner-submit-present.log`。

## 邻接表（本域声称单路径所对照的表）

表在 `ui/main.gd::PRESENT_ADJACENCY`，不是全文搜索、不是实现者报告。粒度沿 header 刀既有约定：`present` 出边＝全量谓词／`render` 回退／各节直调节体；帧协议（`DragTargets.clear`／`_hide_term`／`layout.end_frame`／`keyboard_input.refresh_hints`／`_localize_controls`）是与 `render` 共享的既有边，不进本表。脏集助手按契约不是 present 邻接，**未**把 `_submit`／`_submit_dirty`／`previous_absent` 填进表，也未新写卸载函数。

`present` 声明出边与源直调节体双向一致：

| 声明边 | 源 |
| --- | --- |
| `_present_needs_full_render` | `present` 全量闸首项 |
| `render` | 闸命中回退 |
| `header.configure` | `header` 节 |
| `_relic_row`／`_hand`／`_build_action_rail` | `relics`／`hand`／`actions` |
| `_refresh_posture_section`／`_refresh_resource_section`／`_refresh_log_section` | `posture`／`resources`／`show_log` |
| `_refresh_body_details_section`／`_refresh_picker_section`／`_refresh_speech_section` | `body_details`／`pickers`／`speech` |
| `_refresh_notice_section` | `notice` |
| `_refresh_drawer_section` | `drawers` |
| `_scene_instances_need_full` | `present` 闸对 `scene_instances` 直调（`_present_needs_full_render` 内同谓词另有一条，表亦声明） |
| `_refresh_scene_instances_section` | `scene_instances` 节 |
| `layout.body_sidebar` | `body_bar` 节 |

notice 叶已声明：`_refresh_notice_section` → `_notice_presentation_key`／`_show_term`（命中早退；未命中 `_hide_term` 后重建，`_hide_term` 是 miss 路径内部，与其它节 unload 助手同粒度、不升为 present 出边）。`page`／`*`／未知仍经 `_present_needs_full_render` 回 `render`，无局部节体。表无源无、源无表无的节体边。无第二套 `present`／邻接表。

## 核对（简报点名）

- 无第二套刷新管线：UI 刷新入口仍仅 `present`（局部）与 `render`（全量）；`core/torso_binding.gd::present` 是装备谓词。脏集唯一导出 `_submit_dirty`，唯一调用点 `_submit`。
- 无新 UI 文件：`485d5e1..HEAD` 新增仅三份 `build/` 报告；`8ea38c5..HEAD` 产品面仍 `ui/main.gd`、`tests/display_ui_cases.gd`、`docs/spec/response-pipeline.md`。
- 无 `commit`／`present_rejection` 新符号：`ui/main.gd` 无这两个 `func`；spec 仍标待实现。
- `present(dirty: Array=["*"], snapshot: Dictionary={})` 保持未类型化 Array。
- `get_view` 白名单未增（`_resume_snapshot`／`render` 空快照／`_submit` 一次／`restart`）。写盘仍只 ok 且 `checkpoint` 非空。`card_motion.positions` 仍在 `dispatch` 前。反馈仍只 ok 且在 `present`／`render` 之后。
- `page` 仍全量：`_present_needs_full_render` 对 `page` 返回 true；`_submit_presentation_keys` 不含 `page`，脏集不进 `page`。
- `_submit` 在清选中前把 overlay 五节写入 `previous_absent`；`_submit_dirty` 只按该表去掉提交前已未挂载节；`notice` 仍按提交后 `notice==""` 去掉（⑥ 依赖；不改产品、不改 extract 括注）。
- `docs/spec/response-pipeline.md` 过滤句与源一致（提交前过滤／本次卸载留 dirty／空 notice 仍去掉），无并排旧事实，本刀不改 spec。
- 未碰 keyword-query／equipment-index／主树脏文档／全局 skill。
- Godot 无 Size and ESM；`main.gd` 已超行数线，简报不拆。`PRESENT_ADJACENCY` 即本域最小声明表；`spire-godot/tools/` 无钉住 present 边的机械检查器、无 GDScript 复杂度门禁，记未建，不新开框架。

## 四态

| 状态 | 本次域内结论 |
| --- | --- |
| 已通过 | 邻接表存在且与 `present` 直调节体一致；`_submit`／脏集助手不在表内；单刷新管线；无新 UI 文件／无禁符号／未类型化 `present` Array；调用点集合未增；`page` 仍全量；spec 过滤句与源一致；F1 提交前挂载过滤与提交后空 `notice` 判据与源一致。 |
| 失败 | 无。 |
| 未运行 | display 套件（本刀未改 gd／测试，按简报不开引擎）；规则套件、其它 UI 分类、档 2 变异、验收者、打包与发布。门禁沿用实现者 F1 声明 `20260926T070828431-40912`（display PASS、951 assertions），本会话未复跑。 |
| 不适用 | Size and ESM；内容包；keyword-query／equipment-index；把 F1' 括注写进 extract 或改产品。 |

本报告随后 `git add -f` 并本地 checkpoint。未暂存 `*.import`／`.uid`，未 `git add -A`，无 push／merge／PR／tag。
