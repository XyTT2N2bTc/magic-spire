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

# One row: `port` names the overridden port, `id`/`template` the record, `owner` the container owner the
# attribution rule groups by (root component, shoulder host, torso binding parent; empty otherwise),
# `epoch` the version on entry and `trial` the replacement sandbox flag. The port-specific fields ride in
# `extra`. Reader only: no state write, no random draw, no emit, no second write port.
func _journal_row(port: String, record: Dictionary, extra: Dictionary) -> void:
 var owner=""
 if record.has("root_id"): owner=String(record.root_id)
 elif record.has("shoulder_host"): owner=String(record.shoulder_host)
 elif record.has("parent_id"): owner=String(record.parent_id)
 var row={"port":port,"id":String(record.get("id","")),"owner":owner,"template":String(record.get("template","")),"epoch":write_epoch(),"trial":bool(_rope_trial)}
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

# One frame per settle: the port-entry counts at both ends, so the delta inside `_cleanup` is exact even
# when one action reaches several settle points.
func _cleanup(released: bool=true) -> void:
 var frame={"released":released,"enter_durability":durability_entries.size(),"enter_quality":quality_entries.size(),"exit_durability":0,"exit_quality":0}
 cleanup_frames.append(frame)
 super._cleanup(released)
 frame["exit_durability"]=durability_entries.size()
 frame["exit_quality"]=quality_entries.size()

func settle_port_entries() -> Array:
 var rows=[]
 for frame in cleanup_frames:
  rows.append({"released":bool(frame["released"]),"durability":int(frame["exit_durability"])-int(frame["enter_durability"]),"quality":int(frame["exit_quality"])-int(frame["enter_quality"])})
 return rows
