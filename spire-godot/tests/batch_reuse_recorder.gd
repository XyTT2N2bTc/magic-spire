extends "res://tests/game_fixture.gd"
# D 批（K1-D）测试侧记录器：批内复用机制 core/game.gd::_batch_rows 的请求次数与真实构建次数，逐条目名。
# 只包装机制入口，规则行为与本类未包装时逐字节相同（不覆盖任何规则函数）；生产源码不带计数器。
# 口径：reuse_requests[条目]＝该条目被取用的次数；reuse_builds[条目]＝其中真正跑了构建的次数；
# 两者之差＝同一批次内的重复取用次数（＝被批内条目挡下的重复整表构建／重复走查，只进报告、不作判据）。
# 条目名形如 "table"／"attack_walk"／"card_rows:<uid>"；按种类聚合取冒号前的段。

var reuse_requests={}
var reuse_builds={}
var fact_source_calls=0
var join_units_calls=0

func _batch_rows(entry: String, build: Callable) -> Array:
 var built=[0]
 var counted=func():
  built[0]+=1
  return build.call()
 var rows=super._batch_rows(entry,counted)
 reuse_requests[entry]=int(reuse_requests.get(entry,0))+1
 reuse_builds[entry]=int(reuse_builds.get(entry,0))+built[0]
 return rows

func _fact_source() -> Array:
 fact_source_calls+=1
 return super._fact_source()

func _join_fact_units(units: Array) -> Array:
 join_units_calls+=1
 return super._join_fact_units(units)

func reuse_requests_of(kind: String) -> int:
 return _reuse_total(reuse_requests,kind)

func reuse_builds_of(kind: String) -> int:
 return _reuse_total(reuse_builds,kind)

func reset_reuse_counts() -> void:
 reuse_requests={}
 reuse_builds={}
 fact_source_calls=0
 join_units_calls=0

static func _reuse_total(table: Dictionary, kind: String) -> int:
 var total=0
 for key in table:
  if String(key).split(":")[0]==kind: total+=int(table[key])
 return total
