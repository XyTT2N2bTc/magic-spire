# 规划者契约：卡牌依赖走稳定 ID

状态：可交协调者；**无新模块、无新允许边**，不标 `needs-human-review`。通宵已授权本切分。HEAD `b8a52af` 静态切片，未实现、未运行。域：`data/card_text.gd::keywords` 已有的 TERMS 键收集；槽／模式仍读 `Rules.SPECS.target_slots`／`Rules.face_mode`。本刀不是再剪 `card_facts`／`targets_at`。

## 已有入口（扩展，不建第二套）

- `data/card_text.gd::keywords(type, free, traits) -> Array`：已从 `Rules.SPECS` 收集 TERMS 键（`face_mode`、`casting.parts`、`_effect_terms` 的 `op`、`follow_through`、`exhaust`／`innate`／`ethereal` 等），再 `TERMS[id].duplicate`。**返回值丢掉 id**，只留 `{name,detail}`。`follow_through` 且 `follow_through_scope=="body"` 时改 `term.name` 为「超级顺延」（同一 id，显示名不是「顺延」）。
- `data/card_text.gd::metadata` → `face_keywords[side]`；公开 `data/balance.gd::card_metadata`。词条真源仍是 `TERMS`（`docs/spec/card-terms.md` 取源）。
- 槽／模式：`Rules.SPECS[type].target_slots`（可缺省）、`Rules.face_mode(type, free)`／`SPECS.mode`。`core/card_effects.gd::card_facts` 已按这两处走槽，不经词条名。
- `data/tutorial.gd` 已按 TERMS 键取条。测试／`ui/card_face.gd::separate_keywords` 现用 `term.name` 对齐显示，不是规则依赖。
- **没有**第二份 TERMS、没有 `keyword_ids`。禁止按译文／`term.name`／`requirements()` 中文行／`SLOT_NAMES` 反查依赖。

## 切分、接口和依赖

- 把 `keywords()` 内已有的 `ids` 收集抽成同文件 `keyword_ids(type, free, traits) -> Array`（元素＝TERMS 键，顺序＝今日 `keywords()` 遍历序）。`keywords()` 必须调用它再查 `TERMS`；禁止平行再走一遍 SPECS／效果。不把 `id` 写进 `face_keywords`／`TERMS`（`pot.face_keywords.bound==[Text.TERMS.exhaust]` 等字面比较保持）。
- 卡牌依赖＝同一点上的三元组，均稳定 ID：**keyword_ids**；**target_slots**＝`SPECS.get("target_slots", [])`；**mode**＝`Rules.face_mode(type, free)`。不新建 `card_deps` 模块，不在 `card_rules.gd` 复制词条收集，不抄 TERMS 表。
- 允许实现面：`spire-godot/data/card_text.gd`（上述抽取），`spire-godot/tests/card_text_cases.gd` 单个具名场景／`run` 注册。不得改 `core/card_effects.gd`、`core/game.gd`、UI、`separate_keywords`、`TERMS` 的 `name`／`detail`、本地化资源。
- 允许方向：仍是 `card_text` → `card_rules.SPECS`／`TERMS`；测试 → `card_text` 公开函数。`card_effects` 已有 `Rules` 与 `g.B.card_metadata`，**本刀不得**新增 `card_effects` → `card_text` preload。若实现要新模块、新边、或让 `card_facts` 消费 `keyword_ids` 去剪槽 → `needs-human-review` 并停下。

## Gherkin：`card_keyword_deps_stable_ids`（一个可观察行为）

Given `tests/card_text_cases.gd`，`Text=preload("res://data/card_text.gd")`，`Rules=Text.Rules`（或 `preload("res://data/card_rules.gd")`），`Game.new(42)` 的 `B.CARD_TRAITS`；钉 `strain`／`slip`／`crossed_legs`／`strong_elbow`／`magic_hand`／`pot_of_greed`／`mana_search`。先记下 `keywords()` 的 `{name,detail}` 与 `TERMS` 字面。
When 对每张钉牌的 bound／free 调用 `keyword_ids(type, free, traits)`，并读 `SPECS.target_slots`（缺省 `[]`）与 `Rules.face_mode(type, free)`；再把 `TERMS.strain.name`、`TERMS.follow_through.name`、`TERMS.exhaust.name` 改成非原文，重调 `keyword_ids`（测后恢复 TERMS）。
Then ids 为字符串数组、属于 `TERMS` 键、顺序与同参数 `keywords()` 一致；`keywords()` 各项 `{name,detail}` 在未改 TERMS 时与改前相等，且**无 `id` 键**。`strain` 拘束面 ids 含 `"strain"`、无 `target_slots`、mode 为 `"strain"`；`crossed_legs` 拘束面 `target_slots` 等于 `FOLLOW_THROUGH_REGIONS.legs`（不是「目标：腿部」或 `SLOT_NAMES`）；`strong_elbow` 为 `["upper_arm","forearm"]`；`magic_hand` 拘束面 ids 含 `"follow_through"`，同时 `keywords()` 对应项 `name=="超级顺延"`；`pot_of_greed` 两面 ids 含 `"exhaust"` 且 `face_keywords` 仍等于 `[Text.TERMS.exhaust]`；`mana_search` ids 含 `"search"`。改 TERMS 的 `name` 后 **ids／slots／mode 不变**。快照与 `state.rng` 不变。Oracle 不得用 `term.name`／译文／`requirements()` 行。

## 完成定义及档 2（尚未执行）

- 实现者交 `keyword_ids` 与上述场景；独立新会话审查者只核对本域源码／测试与本契约；清洁者核对：单次 ids 收集、无第二份 TERMS、无 `card_effects`→`card_text` 新边、`face_keywords` 形状未加 `id`。本刀不写 `docs/spec`。
- 实现者在 `spire-godot/` 运行 `& tools/check.ps1 -Suite card_power -TimeoutSeconds 600`。通过＝退出码 0、`SUITE RESULT: card_power PASS`、完成标记、`summary.json` 的 `status=passed` 且指纹未变。未运行、`source_changed`、钉牌缺失或改名后 ids 仍跟 `name`＝未完成。既有 `TERMS`／COPY 断言不得变红。
- 档 2（选定加固者，独立实现／清洁后）对上述钉牌跑 card_power。变异须红：①用 `term.name=="挣扎"`／`"顺延"`／`"消耗"`（或译文）当 ids；②从 `requirements()`／`SLOT_NAMES` 猜 `target_slots`；③`keyword_ids` 与 `keywords()` 各走一套 SPECS。原版绿；变异复原后重跑本域。缺工具或失败＝未通过，不算不适用。
- UI 验收 **none**：玩家可见 `name`／`detail` 与词条框集合不变；不改 `separate_keywords` 排版。不派验收者。无打包、发布、push。

## 非目标

T4／T5／分区 delta；`card_facts` 再剪 `targets_at`／消费 `keyword_ids`；改 TERMS 文案；改 `separate_keywords`；改 `face_keywords` 集合与顺序；新模块；`card_effects` 新边。

## 风险假设

`keywords()` 的 ids 顺序可原样抽出；超级顺延只改显示名。若抽出 ids 必须改 TERMS 形状或让 UI／`card_facts` 新依赖 `card_text`，停工交回，不扩边迁就。
