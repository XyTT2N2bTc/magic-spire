extends RefCounted

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

func first_usable(group: String, fields: Dictionary={}) -> Dictionary:
 var matches=select(group,fields)
 for c in matches:
  if c.valid: return c
 return matches.back() if not matches.is_empty() else {}
