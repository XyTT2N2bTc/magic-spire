extends "res://tests/game_fixture.gd"
# CC-39 (rev3.4 plan-delta §3.1; dependencies-delta §1): the test-side write journal. A settle must not
# enter a durability write port, and that is only observable from a subclass that logs the two ports
# and brackets `_cleanup`. It overrides nothing else, adds no rule, changes no state and exists only in
# `tests/` (the product carries no counter: plan-delta §3 forbidden list).

var durability_entries: Array=[]
var quality_entries: Array=[]
var cleanup_frames: Array=[]

func _write_durability(target: Dictionary, value: float, tighten: bool=false) -> void:
 durability_entries.append(String(target.get("id","")))
 super._write_durability(target,value,tighten)

func _write_quality(target: Dictionary, grade: int) -> void:
 quality_entries.append(String(target.get("id","")))
 super._write_quality(target,grade)

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
