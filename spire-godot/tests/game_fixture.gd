extends "res://core/game.gd"
# Stable encounter fixture for mechanics/UI cases. The shipped Game and normal-play
# tests use the actual random opening. No commands or rule checks are overridden.
func _generate_tower() -> void:
 super._generate_tower()
 var entrance=room_data("entrance")
 var first=room_data(entrance.next[0])
 state.rooms.erase(entrance)
 var old_id=first.id
 state.room_encounters.erase(old_id)
 first.id="entrance";first.name="入口回廊";first.wall="rough"
 first.erase("pool");first.erase("encounter_choices");first.erase("encounter_selected")
 first.encounter="belt_tie";first.map_version=Tower.MAP_VERSION
 state.room_encounters.entrance="belt_tie"
 # Make two explicit adjacent encounter branches for target/route identity cases.
 var next_row=state.rooms.filter(func(r):return r.floor==1)
 var selected=[next_row[0],next_row[-1]]
 if selected[0]==selected[1]:
  var extra=selected[0].duplicate(true);extra.id="fixture_right";extra.lane=1.0;state.rooms.append(extra);selected[1]=extra
 first.next=[]
 for i in range(2):
  var r=selected[i];var old=r.id;var id="east" if i==0 else "west"
  for parent in state.rooms:
   if old in parent.next: parent.next[parent.next.find(old)]=id
  state.room_encounters.erase(old)
  r.id=id;r.kind="battle";r.name="东侧窄廊" if i==0 else "西侧石廊";r.wall="normal" if i==0 else "rough"
  r.erase("pool");r.erase("encounter_choices");r.erase("encounter_selected");r.erase("event")
  r.encounter="rope_solo" if i==0 else "rope_tape";state.room_encounters[id]=r.encounter
  first.next.append(id)

 var west=room_data("west")
 var landing=room_data(west.next[0]);var old=landing.id
 for r in state.rooms:
  if old in r.next: r.next[r.next.find(old)]="landing"
 state.room_encounters.erase(old)
 landing.id="landing";landing.name="上层回廊";landing.kind="battle";landing.encounter="double_rope"
 landing.erase("pool");landing.erase("encounter_choices");landing.erase("encounter_selected");landing.erase("event")
 state.room_encounters.landing="double_rope"

func _initial_wall_distance(_battle: bool) -> int:
 return 0

# Observe projection calls without touching authoritative state or overriding rules.
var view_reads=0
func get_view() -> Dictionary:
 view_reads+=1
 return super.get_view()
