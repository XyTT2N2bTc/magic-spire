# 装备只读邻接表：建表后仍全量拼接

状态：**已授权切分**（2026-09-26 人：先收 `targets_at` 单管线，再接线 `_submit`→`present`）。
域：`spire-godot/core/game.gd` 装备只读索引（`docs/spec/equipment-query-seam.md`）。

## 问题

作用域入口 `_build_equipment_read_index` 已按边物化（`_materialize_slot_edge`／`_materialize_root_edge`／`_materialize_link_edge`／`_materialize_connection_edge` 等）。`equipment_at`／`occupied`／`hand_blocked`／`links_at` 在作用域内查表。

`targets_at` 不是同一条管线的单一方法：

- `"shoulder"`：每次 `physical_pieces()` 再 `Equipment.is_shoulder` 过滤。槽表预留 `"shoulder"` 但 `_materialize_slot_edge` 只按 `Equipment.coverage` 正向投影，该键保持空，查询从不读它。
- 特殊槽：作用域内仍 `state.special_equipment.filter(SpecialEquipment.occupies)`，再拼 `links_at`。
- 普通槽：先 `equipment_at`（查表），再扫 `_composite_roots()` 按定义 coverage 去重追加组件，再拼 `links_at` 与 `connections.filter(e.slot==slot)`。连接边已物化，过滤仍在每次调用。

因此同一查询接口同时存在「查邻接表」与「再扫权威容器／再滤一遍」。热路径（`card_facts` 槽循环、`View.build` 身体行）消费的是 `targets_at`，不是已经查表的 `equipment_at`。建表省下的重复扫被这一层全量拼接吃掉。

写路径按契约仍 live（`dispatch` 原地改 `state`，表不得跟随）。本条待办管的是**只读作用域内已经建了表却不单一走表**。

## 闭合时须成立（未设计怎么做）

- 每个查询接口作用域内只走已物化边；无作用域才 live。不得同一方法内「查表 + 再扫」。
- `"shoulder"`／特殊槽／普通槽拼接顺序与过滤条件与现行接口表一致（含特殊件无耐久过滤、肩带不走 coverage），只允许改「怎么取到件集合」。
- 无第二套 `targets_at` 实现。不把写路径改成自动跟随 `state` 的表。

## 非本条

`_submit` 整树 `render`、`present` 多节脏集、收窄 `View.build`、写穿缓存。人已授权为**本刀之后**的接线刀。
