extends RefCounted

# Legacy save compatibility layer (A67). The only place that reads revisions 52/53/54 and rewrites
# them to the current shape. Called from core/game.gd::restore_snapshot only: migrate_candidate runs
# on the candidate copy before Snapshot.check (same order as the former inline chain), and
# refresh_after_swap rebuilds the fields a migrated save lacks after the swap. The whole file is
# excluded from the unique-path scan face (tests/architecture_cases.gd::UNIQUE_PATH_SCAN_EXCLUDED),
# so no rule path may reach it. This file preloads nothing: modules are used through the passed `g`.

static func migrate_candidate(s: Dictionary, g) -> String:
 var revision=s.get("save_revision")
 # One membership test for the legacy set (52/53/54) inside this layer. restore_snapshot gates on
 # the same set before calling, so this copy only rejects a direct call; the stages below are one
 # monotone chain and need no second list: a stage applies to every revision at or before the one
 # that introduced its shape.
 if not revision is int or revision not in [g.Snapshot.REINFORCEMENT_STATE_REVISION,g.Snapshot.CUP_STACK_REVISION,g.Snapshot.IRON_DRONE_REVISION]: return ""
 if revision<=g.Snapshot.REINFORCEMENT_STATE_REVISION:
  var special_items=[]
  if s.get("special_equipment") is Array: special_items.append_array(s.special_equipment)
  var saved_event=s.get("room_event",{})
  if saved_event is Dictionary and saved_event.get("held") is Dictionary:
   for held_items in saved_event.held.values():
    if held_items is Array: special_items.append_array(held_items)
  migrate_reinforcement_state(g,special_items)
 if revision<=g.Snapshot.CUP_STACK_REVISION:
  var issue=migrate_cup_stacks(s,g)
  if issue!="": return issue
 migrate_iron_drone(s,g)
 s.save_revision=g.Snapshot.REVISION
 return ""

# Post-swap refresh: the two fields the migrated save does not carry (new display names and the
# iron drone plan rebuilt from the current encounter). The relative order is the former inline one.
static func refresh_after_swap(g) -> void:
 for enemy in g.state.enemies:
  var member=g.Enemies.encounter_member(g.state,enemy.type)
  if member.has("name"): enemy.name=member.name
  if enemy.type=="iron_drone" and not enemy.gone and g.state.phase=="battle":
   var delayed=enemy.intent.delayed
   enemy.intent=g.EnemyPlans.build(g,enemy)
   enemy.intent.delayed=delayed

static func migrate_iron_drone(s: Dictionary, g) -> void:
 if not s.get("enemies") is Array: return
 for enemy in s.enemies:
  if enemy is Dictionary and enemy.get("type")=="iron_drone" and not enemy.has("guard"):
   enemy.guard=g.Guard.initial()

static func migrate_cup_stacks(s: Dictionary, g) -> String:
 if not s.get("special_equipment") is Array: return "性玩具列表缺损。"
 var containers=[s.special_equipment]
 var event=s.get("room_event",{})
 if event is Dictionary and event.get("held") is Dictionary:
  for held in event.held.values():
   if not held is Array: return "事件暂存装备记录损坏。"
   containers.append(held)
 var all_items=[]
 for items in containers: all_items.append_array(items)
 var issue=g.SpecialEquipment.validate(all_items,true)
 if issue!="": return issue
 var cups=all_items.filter(func(item):return g.SpecialEquipment.exclusive_family(item.type)=="cup")
 if cups.size()<2: return ""
 cups.sort_custom(func(a,b):return a.grade>b.grade if a.grade!=b.grade else int(a.id.trim_prefix("special_"))<int(b.id.trim_prefix("special_")))
 var removed=cups.slice(1).map(func(item):return item.id)
 for item in all_items:
  if item.owner_id in removed: removed.append(item.id)
 for items in containers:
  for item in items.duplicate():
   if item.id in removed: items.erase(item)
 # Migration is not a player removal; inspections must not punish repaired saves.
 for record in [s.get("capture",{}),s.get("prison",{})]:
  if not record is Dictionary: continue
  for key in ["retained_special","special_added","special_baseline","special_missing"]:
   if record.get(key) is Array: record[key]=record[key].filter(func(id):return id not in removed)
 if s.get("pressure_sources") is Array:
  s.pressure_sources=s.pressure_sources.filter(func(source):return not source is Dictionary or source.get("equipment","") not in removed)
 return ""

static func migrate_reinforcement_state(g, items: Array) -> void:
 g.SpecialEquipment.ensure_catalog()
 var valid=items.filter(func(item):return item is Dictionary)
 for owner in valid:
  if not g.SpecialEquipment.supports_reinforcement(owner) or owner.has("reinforcement_state"): continue
  var straps=valid.filter(func(item):return g.SpecialEquipment.reinforcement_matches(item,owner))
  owner.reinforcement_state="active" if straps.size()==1 else "none"
  # Older cups had no band at any tightness; loading must not add a new restraint.
  if straps.is_empty() and g.SpecialEquipment.is_reinforced_cup(owner) and float(owner.get("durability",0))>float(owner.get("maximum",0))*g.RestraintValue.TIER_UPPER_2: owner.reinforcement_state="removed"
