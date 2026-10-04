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
