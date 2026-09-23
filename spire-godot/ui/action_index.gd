extends RefCounted
const Queries=preload("res://ui/target_queries.gd")

# Index one view snapshot. This class selects existing actions; it never decides rules.
var by_id: Dictionary={}
var by_group: Dictionary={}

func _init(actions: Array) -> void:
 for c in actions:
  by_id[c.id]=c
  if not by_group.has(c.group): by_group[c.group]=[]
  by_group[c.group].append(c)

func select(group: String, fields: Dictionary={}) -> Array:
 var result: Array=[]
 for c in by_group.get(group,[]):
  var matches=true
  for field in fields:
   if c.payload.get(field)!=fields[field]:
    matches=false
    break
  if matches: result.append(c)
 return result

func find(group: String, fields: Dictionary={}) -> Dictionary:
 var matches=select(group,fields)
 return matches[0] if not matches.is_empty() else {}

# 首个可用项的唯一通道（销 DUP4，docs/spec/candidate-removal.md §2.3）：回退策略显式声明为 "last"——
# 改动前本类的末条拒绝回退行为逐条不变；R5 删行载体后本文件与该方法一起消失。
func first_usable(group: String, fields: Dictionary={}) -> Dictionary:
 return Queries.first_usable(select(group,fields),"last")
