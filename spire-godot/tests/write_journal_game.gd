extends "res://tests/game_fixture.gd"
# CC-39 (rev3.4 plan-delta §3.1; dependencies-delta §1): the test-side write journal. A settle must not
# enter a durability write port, and that is only observable from a subclass that logs the two ports
# and brackets `_cleanup`. It overrides nothing else, adds no rule, changes no state and exists only in
# `tests/` (the product carries no counter: plan-delta §3 forbidden list).
# Q7 (rev3.5 plan-delta §2.2; G-Q7-1′…G-Q7-3′): the same subclass also records one ordered row per write
# that enters an overridden port. A row is built by `_journal_row` from the live record and two instance
# fields only -- it writes no `state`, draws no random, emits nothing and calls no other port -- so the
# journal is an observation of the single live write path, not a second one. Rows carry the record
# identity, its owner, the epoch on entry and the sandbox flag, which lets one window (a `dispatch`)
# be compared with the state difference of the same window.

var durability_entries: Array=[]
var quality_entries: Array=[]
var cleanup_frames: Array=[]
var journal: Array=[]
var quiet_settles: Array=[]
var _quiet_frame_end: int=0

# One row: `port` names the overridden port, `id`/`template` the record, `owner` the container owner the
# attribution rule groups by (root component, shoulder host, torso binding parent; empty otherwise),
# `epoch` the version on entry and `trial` the sandbox flag (QX6: any of the six sandbox entries, read
# from `_sandbox_depth`; before QX6 only the replacement transaction set it). The port-specific fields ride in
# `extra`. Reader only: no state write, no random draw, no emit, no second write port.
func _journal_row(port: String, record: Dictionary, extra: Dictionary) -> void:
 var owner=""
 if record.has("root_id"): owner=String(record.root_id)
 elif record.has("shoulder_host"): owner=String(record.shoulder_host)
 elif record.has("parent_id"): owner=String(record.parent_id)
 var row={"port":port,"id":String(record.get("id","")),"owner":owner,"template":String(record.get("template","")),"epoch":write_epoch(),"trial":_sandbox_depth>0}
 row.merge(extra,true)
 journal.append(row)

func _write_durability(target: Dictionary, value: float, tighten: bool=false) -> void:
 _journal_row("durability",target,{"tighten":tighten,"from":target.durability,"to":value})
 durability_entries.append(String(target.get("id","")))
 super._write_durability(target,value,tighten)

func _write_quality(target: Dictionary, grade: int) -> void:
 _journal_row("quality",target,{"grade_from":target.grade,"grade_to":grade})
 quality_entries.append(String(target.get("id","")))
 super._write_quality(target,grade)

func _tier_consequences(target: Dictionary, before: int, after: int, tighten: bool) -> void:
 _journal_row("tier",target,{"before":before,"after":after,"tighten":tighten})
 super._tier_consequences(target,before,after,tighten)

func _member_changed(record: Dictionary, change: String) -> void:
 _journal_row("member",record,{"change":change})
 super._member_changed(record,change)

func _join_hooks(entry: Array) -> void:
 _journal_row("join",entry[0],{"kind":String(entry[1]),"host":String(Dictionary(entry[3]).get("host",{}).get("id",""))})
 super._join_hooks(entry)

func _write_locked(target: Dictionary, locked: bool) -> void:
 _journal_row("locked",target,{"from":target.locked,"to":locked})
 super._write_locked(target,locked)

# QX2″ (rev3.5 plan-delta §3): the quiet settle (a `_cleanup(false)` outside every sandbox) is
# the only place a release can happen without a player-visible action, so it is counted here once and the
# row is built by the two static helpers below. The helpers read `state` and nothing else, so the QX2″
# parent-tree probe can call the same pair from a `core/game.gd` subclass instead of writing a second
# counter (one meaning, one path).
static func _quiet_ids(g) -> Dictionary:
 var ids={}
 for root in g.state.composites:
  ids[str(root.id)]=true
  for part in root.components:
   ids[str(part.id)]=true
   if part.has("shoulders"):
    for strap in part.shoulders.pieces: ids[str(strap.id)]=true
 for piece in g.state.equipment:
  ids[str(piece.id)]=true
  if piece.has("shoulders"):
   for strap in piece.shoulders.pieces: ids[str(strap.id)]=true
 for link in g.state.links: ids[str(link.id)]=true
 for item in g.state.special_equipment: ids[str(item.id)]=true
 return ids

static func quiet_snapshot(g) -> Dictionary:
 var items={}
 for item in g.state.items: items[str(item.id)]=true
 var sources=[]
 for source in g.state.pressure_sources:
  sources.append({"equipment":str(source.get("equipment","")),"enemy":str(source.get("enemy","")),"room":str(source.get("room",""))})
 var roots=[]
 for id in g.Cards.restraint_roots(g): roots.append(str(id))
 return {"ids":_quiet_ids(g),"items":items,"sources":sources,"roots":roots,"logs":int(g.state.logs.size()),"round":int(g.state.round),"epoch":int(g.write_epoch()),"pressure":float(g.state.pressure)}

# One quiet settle: what left, what joined, what was spent, what the roots and the pressure did, and whether
# anything happened at all. `class` is rev3.2 plan-delta §4.1: four for member/root movement, five for items,
# pressure sources or pleasure, zero for a settle that changed nothing.
static func quiet_row(g, before: Dictionary, site: String) -> Dictionary:
 var ids=_quiet_ids(g)
 var left=[]
 for id in before["ids"]: if not ids.has(id): left.append(id)
 var joined=[]
 for id in ids: if not before["ids"].has(id): joined.append(id)
 var items_removed=[]
 for id in before["items"]: if not g.state.items.any(func(item):return str(item.id)==id): items_removed.append(id)
 var sources_removed=[]
 for source in before["sources"]:
  var kept=g.state.pressure_sources.any(func(live):return str(live.get("equipment",""))==source.equipment and str(live.get("enemy",""))==source.enemy and str(live.get("room",""))==source.room)
  if not kept: sources_removed.append(source)
 var roots_after=0
 for id in g.Cards.restraint_roots(g): roots_after+=1
 var pressure_changed=not is_equal_approx(float(g.state.pressure),float(before["pressure"]))
 var roots_changed=roots_after!=before["roots"].size()
 var did_work=not left.is_empty() or not joined.is_empty() or not items_removed.is_empty() or not sources_removed.is_empty() or pressure_changed or roots_changed or int(g.state.logs.size())!=int(before["logs"])
 var klass=0
 if not left.is_empty() or not joined.is_empty() or roots_changed: klass=4
 elif not items_removed.is_empty() or not sources_removed.is_empty() or pressure_changed: klass=5
 return {"site":site,"epoch":int(before["epoch"]),"round":int(before["round"]),"log_index":int(before["logs"]),"left":left,"joined":joined,"items_removed":items_removed,"sources_removed":sources_removed,"logs_added":int(g.state.logs.size())-int(before["logs"]),"roots_before":before["roots"].size(),"roots_after":roots_after,"pressure_changed":pressure_changed,"did_work":did_work,"class":klass}

# QX2″ commits c and d retired both rope-master settles, and the replacement module's quiet settles all run
# inside its sandbox, so no live path reaches this label any more. It stays as the declared S18 name until
# the Q7 counter is retired with its last subject; a future quiet settle outside a sandbox must classify as
# S18 rather than inventing a new label.
func _quiet_site() -> String:
 return "S18"

# One frame per settle: the port-entry counts at both ends, so the delta inside `_cleanup` is exact even
# when one action reaches several settle points. A quiet settle outside the sandbox also records one row
# (§3): the snapshot is taken before the frame is built and the row after `super`, so the row describes
# exactly this settle. The snapshot stays out of the `cleanup_frames.append`/`super` pair because the
# Q6'b mutation anchor `settle_never_enters_durability_port#cleanup-observed` selects those two lines
# adjacent and verbatim.
func _cleanup(released: bool=true) -> void:
 var quiet_before={}
 if not released and _sandbox_depth==0: quiet_before=quiet_snapshot(self)
 var frame={"released":released,"enter_durability":durability_entries.size(),"enter_quality":quality_entries.size(),"exit_durability":0,"exit_quality":0}
 cleanup_frames.append(frame)
 super._cleanup(released)
 frame["exit_durability"]=durability_entries.size()
 frame["exit_quality"]=quality_entries.size()
 if not quiet_before.is_empty(): quiet_settles.append(quiet_row(self,quiet_before,_quiet_site()))
 _quiet_frame_end=journal.size()

func settle_port_entries() -> Array:
 var rows=[]
 for frame in cleanup_frames:
  rows.append({"released":bool(frame["released"]),"durability":int(frame["exit_durability"])-int(frame["enter_durability"]),"quality":int(frame["exit_quality"])-int(frame["enter_quality"])})
 return rows
