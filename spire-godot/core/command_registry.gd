extends RefCounted

# Fact-outlet registry: the single assembly point for the COMMAND_KEYS kind set
# (docs/spec/fact-lookup-dependencies.md; contract row T4 in docs/spec/candidate-removal.md).
# Entries store data only (form + method names on g): this file preloads no module and holds no
# Callable, so domain functions stay reachable through g. No preload cycle can form here because
# core/copy_router.gd and core/save_store.gd preload core/game.gd back, and core/card_effects.gd
# takes this table in S3.
#
# Table form (every kind but attack and card after S3):
#   source : String — method name on g, signature (kind: String, params: Dictionary) -> Array.
#                     That array is the fact set the point query scans for this kind; every entry
#                     names the producer and guard its core/game.gd::_kind_facts arm used before S1.
# Point form (S2 landed it for attack; S3 adds card; the card keys／build／member forward to
# core/card_effects.gd, where the single enumeration and constructor live):
#   keys／build／member : String — method names on g, called as keys(g) -> Array,
#                     build(g, params) -> Dictionary, member(g, params) -> bool
#                     (signatures in the slice plan section 3; keys is the only candidate enumeration,
#                     build is the single-row constructor, member is the membership predicate).
#
# Fail-closed: an unregistered kind is not a command shape, so point() returns {} and no anonymous
# `_:` fallback exists to reach a producer.

# Whole-table item for the takeover phase (core/first_turn_control.gd::active): the selected table is
# named explicitly so the takeover scan has one declared source instead of an anonymous branch.
const TAKEOVER_SOURCE="command_facts"

const ENTRIES={
 "card":{"form":"point","keys":"card_point_keys","build":"card_point_fact","member":"card_point_member"},
 "chain":{"form":"table","source":"_whole_table_kind_facts"},
 "attack":{"form":"point","keys":"attack_point_keys","build":"attack_point_fact","member":"attack_point_member"},
 "status_toggle":{"form":"table","source":"_status_toggle_kind_facts"},
 "posture":{"form":"table","source":"_posture_kind_facts"},
 "wall_move":{"form":"table","source":"_wall_move_kind_facts"},
 "manual":{"form":"table","source":"_whole_table_kind_facts"},
 "hook":{"form":"table","source":"_whole_table_kind_facts"},
 "end":{"form":"table","source":"_flow_kind_facts"},
 "calm":{"form":"table","source":"_flow_kind_facts"},
 "surrender":{"form":"table","source":"_surrender_kind_facts"},
 "item_use":{"form":"table","source":"_item_use_kind_facts"},
 "item_install":{"form":"table","source":"_whole_table_kind_facts"},
 "item_retrieve":{"form":"table","source":"_whole_table_kind_facts"},
 "item_discard":{"form":"table","source":"_item_discard_kind_facts"},
 "finish_prepare":{"form":"table","source":"_flow_kind_facts"},
 "finish_rest":{"form":"table","source":"_flow_kind_facts"},
 "finish_pack":{"form":"table","source":"_flow_kind_facts"},
 "retain":{"form":"table","source":"_whole_table_kind_facts"},
 "retain_skip":{"form":"table","source":"_whole_table_kind_facts"},
 "rest_rare":{"form":"table","source":"_whole_table_kind_facts"},
 "rest_card":{"form":"table","source":"_whole_table_kind_facts"},
 "rest_flask":{"form":"table","source":"_whole_table_kind_facts"},
 "rest_begin":{"form":"table","source":"_whole_table_kind_facts"},
 "service":{"form":"table","source":"_whole_table_kind_facts"},
 "event":{"form":"table","source":"_whole_table_kind_facts"},
 "prison":{"form":"table","source":"_whole_table_kind_facts"},
 "depart":{"form":"table","source":"_whole_table_kind_facts"},
 "travel_step":{"form":"table","source":"_whole_table_kind_facts"},
 "reward":{"form":"table","source":"_whole_table_kind_facts"},
 "reward_skip":{"form":"table","source":"_whole_table_kind_facts"},
 "relic_bundle":{"form":"table","source":"_whole_table_kind_facts"},
 "departure":{"form":"table","source":"_whole_table_kind_facts"},
 "flask":{"form":"table","source":"_flask_kind_facts"},
 "relic_toggle":{"form":"table","source":"_relic_kind_facts"},
 "relic_discharge":{"form":"table","source":"_relic_kind_facts"},
 "relic_control_done":{"form":"table","source":"_whole_table_kind_facts"},
 "demo_end":{"form":"table","source":"_whole_table_kind_facts"},
 "demo_continue":{"form":"table","source":"_whole_table_kind_facts"},
}

# ==== K1 单元表（plan §3 A 批；docs/spec/fact-table-dependencies.md「单元表」）====
# 表出口（core/game.gd::_fact_source）与阶段分支（core/game.gd::_phase_facts）的组成面：每个追加点＝一个单元，
# 表项＝{id, order, owner, producer, groups, input}。
#  owner    — "relic_bundle"／"departure"／"main"（_fact_source 的三个前缀分支之一，或其后主序列）
#             或 core/game.gd::_phase_branch 的分支 id（_phase_facts 的分支）。
#  order    — 该单元在其 owner 序列内的执行序（1 起，连续）；顺序是数据，不是控制流。
#  producer — core/game.gd 上的方法名，签名 (facts: Array) -> Array；facts＝本单元之前已累积的表。连接通道唯一：
#             core/game.gd::_join_fact_units（未声明单元不产行；表外无第二处追加点）。
#  groups   — 该单元行的 group 值域（判据取实测：tests/architecture_cases.gd::fact_units_cover_fact_source 双向核对）。
#  input    — 本单元读取的已产出单元 id（"读累积表"的跨单元前置；空串＝无前置）。
# 不可独立增量（显式登记，G 批不得触碰）：三个 *_consumables 单元（按已累积表去重）与 route（读累积表的出口行＋
# 现算 room_entry_reason）；宽切片单元（relic_effects／hand_cards／prison／events／services）同理；任何"按本次提交的
# kind 决定复用"的做法不得进入本表（第二份失效真源）。
const FACT_UNITS=[
 {"id":"relic_bundle_prefix","order":1,"owner":"relic_bundle","producer":"_unit_relic_bundle","groups":["reward"],"input":""},
 {"id":"relic_bundle_consumables","order":2,"owner":"relic_bundle","producer":"_unit_noncombat_consumables","groups":["item"],"input":"relic_bundle_prefix"},
 {"id":"relic_bundle_flask","order":3,"owner":"relic_bundle","producer":"_unit_flask_full","groups":["flask"],"input":""},
 {"id":"departure_prefix","order":1,"owner":"departure","producer":"_unit_departure","groups":["flow","reward"],"input":""},
 {"id":"departure_consumables","order":2,"owner":"departure","producer":"_unit_noncombat_consumables","groups":["item"],"input":"departure_prefix"},
 {"id":"departure_flask","order":3,"owner":"departure","producer":"_unit_flask_full","groups":["flask"],"input":""},
 {"id":"phase","order":1,"owner":"main","producer":"_unit_phase","groups":["attack","card","chain","demo_exit","event","flow","hook","item","manual","posture","pressure","prison","rest_service","retain","reward","route","service","service_flow","service_refresh","service_release","service_remove","wall_move"],"input":""},
 {"id":"noncombat_consumables","order":2,"owner":"main","producer":"_unit_noncombat_consumables","groups":["item"],"input":"phase"},
 {"id":"route","order":3,"owner":"main","producer":"_unit_route","groups":["route"],"input":"phase"},
 {"id":"surrender","order":4,"owner":"main","producer":"_unit_surrender","groups":["surrender"],"input":""},
 {"id":"item_discard","order":5,"owner":"main","producer":"_unit_item_discard","groups":["item"],"input":""},
 {"id":"flask","order":6,"owner":"main","producer":"_unit_flask","groups":["flask"],"input":""},
 {"id":"relic_effects","order":7,"owner":"main","producer":"_unit_relic_effects","groups":["relic"],"input":""},
 {"id":"status_toggle","order":8,"owner":"main","producer":"_unit_status_toggle","groups":["status_toggle"],"input":""},
 {"id":"rest_choice_block","order":1,"owner":"rest_choice","producer":"_unit_rest_choice","groups":["rest_service"],"input":""},
 {"id":"services","order":1,"owner":"shop_treasure","producer":"_unit_services","groups":["service","service_flow","service_refresh","service_release","service_remove"],"input":""},
 {"id":"events","order":1,"owner":"event","producer":"_unit_events","groups":["event"],"input":""},
 {"id":"prison","order":1,"owner":"captured_inspection","producer":"_unit_prison","groups":["prison"],"input":""},
 {"id":"climax_end","order":1,"owner":"overload_climax","producer":"_unit_climax_end","groups":["flow"],"input":""},
 {"id":"chain","order":1,"owner":"card_chain","producer":"_unit_chain","groups":["chain"],"input":""},
 {"id":"retain","order":1,"owner":"pending_retain","producer":"_unit_retain","groups":["retain"],"input":""},
 {"id":"reward","order":1,"owner":"reward","producer":"_unit_reward","groups":["reward"],"input":""},
 {"id":"travel_step","order":1,"owner":"travel","producer":"_unit_travel_step","groups":["route"],"input":""},
 {"id":"demo_exit","order":1,"owner":"cleared","producer":"_unit_demo_exit","groups":["demo_exit"],"input":""},
 {"id":"pack_items","order":1,"owner":"pack","producer":"_unit_item_action","groups":["item"],"input":""},
 {"id":"pack_flow","order":2,"owner":"pack","producer":"_unit_flow","groups":["flow"],"input":""},
 {"id":"wall_move","order":1,"owner":"action_tail","producer":"_unit_wall_move","groups":["wall_move"],"input":""},
 {"id":"posture","order":2,"owner":"action_tail","producer":"_unit_posture","groups":["posture"],"input":""},
 {"id":"attack","order":3,"owner":"action_tail","producer":"_unit_attack","groups":["attack"],"input":""},
 {"id":"equipment_spell","order":4,"owner":"action_tail","producer":"_unit_equipment_spell","groups":["attack"],"input":""},
 {"id":"hand_cards","order":5,"owner":"action_tail","producer":"_unit_hand_cards","groups":["card"],"input":""},
 {"id":"manual","order":6,"owner":"action_tail","producer":"_unit_manual","groups":["manual"],"input":""},
 {"id":"item_action","order":7,"owner":"action_tail","producer":"_unit_item_action","groups":["item"],"input":""},
 {"id":"hook","order":8,"owner":"action_tail","producer":"_unit_hook","groups":["hook"],"input":""},
 {"id":"prison_tail","order":9,"owner":"action_tail","producer":"_unit_prison","groups":["prison"],"input":""},
 {"id":"flow","order":10,"owner":"action_tail","producer":"_unit_flow","groups":["flow","pressure"],"input":""},
]

# _fact_source 的三个前缀 owner（"main" 只在这三者之外到达；core/game.gd::_phase_branch 的前三个 id）。
const FACT_PREFIX_OWNERS=["relic_bundle","departure","domain_blocked"]

# _fact_source 的单元序列（顺序＝表序）：前缀分支只跑该前缀 owner 的单元；"main" 只在这三个前缀之外到达
# （domain_blocked＝空表）。阶段分支（_phase_facts 的 owner）不进本序列。
static func fact_source_units(branch: String) -> Array:
 var out=[]
 for unit in FACT_UNITS:
  var owner=String(unit.owner)
  if owner=="main":
   if branch not in FACT_PREFIX_OWNERS: out.append(unit)
  elif owner in FACT_PREFIX_OWNERS and owner==branch:
   out.append(unit)
 return out

# _phase_facts 的单元序列（顺序＝表序）：按分支的 owner 取；空表分支（prison_end／map）与未声明 owner 都返回空。
static func phase_units(branch: String) -> Array:
 var out=[]
 for unit in FACT_UNITS:
  if String(unit.owner)==branch: out.append(unit)
 return out

static func kinds() -> Array:
 return ENTRIES.keys()

# Unregistered kind -> {} (fail-closed; callers must not guess a default form).
static func entry(kind: String) -> Dictionary:
 return ENTRIES.get(kind,{})

static func takeover_source() -> String:
 return TAKEOVER_SOURCE

# The single point-query lookup: table form = first params hit in that kind's named source
# (core/game.gd::_kind_facts reads it); point form = the entry's member predicate, then its single-row
# builder. Unregistered kind -> {} and the producer is never reached. The returned dictionary is the
# raw fact, not the display fact: core/game.gd::_command_fact_row is the only caller that projects it.
static func point(g, kind: String, params: Dictionary) -> Dictionary:
 var item=entry(kind)
 if item.is_empty(): return {}
 var form=String(item.get("form",""))
 if form=="table":
  for f in g._kind_facts(kind,params):
   if String(f.payload.get("kind",""))!=kind: continue
   if g.command_params(kind,f.payload)==params: return f
  return {}
 if form=="point":
  if not g.call(String(item.get("member","")),g,params): return {}
  return g.call(String(item.get("build","")),g,params)
 return {}
