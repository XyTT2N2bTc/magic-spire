extends RefCounted

# Pure planning stages of the replacement transaction. The transaction
# (core/equipment_replacement.gd) and, from S2, the read-only judgment call these
# same functions, so this module is the single implementation of normalization,
# removable units, minimal cover sets, counts, strength comparison and link
# transfer. A second copy of any of them is a defect, not a shortcut.
#
# Invariants kept by every function here:
# - It never writes g.state, never copies or swaps a state snapshot, never emits
#   and never advances a random counter. Container parameters are the live
#   containers of g.state (equipment / special_equipment / composites / links)
#   and before.links: passed by reference, never copied and never installed back
#   into g.state. Arrays derived here (filters, concatenations, duplicated piece
#   records) are scratch values that the caller discards.
# - Allowed edges only: data/equipment, data/composites, data/special_equipment,
#   data/links, data/balance, core/shoulder_links, core/torso_binding,
#   core/witch_character. Never preload core/game.gd (cycle),
#   core/equipment_replacement.gd (cycle), ui/ or tests/. Read-only instance
#   methods may be called on the passed g because they read the same live state.

# The failure shape of the plan contract: every caller reads ok/reason and the empty
# id lists. A non-verdict carrier (writes reason, never valid); declared in
# tests/architecture_cases.gd::VERDICT_REASON_CARRIERS like the transaction's _fail.
static func failure(reason: String) -> Dictionary:
 return {"ok":false,"reason":reason,"removed":[],"installed":[],"lost_links":[],"comparisons":[]}

# Definition and parameter normalization. The request copy is local: the caller's
# dictionaries are never mutated. Structural checks delegate to the original
# factory/preparation APIs so the judgment and the transaction accept exactly the
# same requests.
static func normalize(g, requests: Array) -> Dictionary:
 if requests.is_empty(): return failure("本次没有指定要安装的装备。")
 var normalized=[]
 for input in requests:
  if not input is Dictionary: return failure("每件装备都需要具体安装规格。")
  var r=input.duplicate(true)
  if r.get("kind","") not in ["install","assembly","special_install"]: return failure("本次操作不是装备安装。")
  for key in ["grade","tier","layer"]:
   if r.has(key) and not r[key] is int: return failure("品质、紧度和层级必须使用整数。")
  if r.has("locked") and not r.locked is bool: return failure("上锁要求必须明确为是或否。")
  for key in ["template","slot","point","family","type","straps","attached_to"]:
   if r.has(key) and not r[key] is String: return failure("安装类型和具体位置必须使用名称。")
  if r.kind=="install":
   r.grade=r.get("grade",1);r.tier=r.get("tier",2);r.locked=r.get("locked",false);r.variant=r.get("variant",0)
   if not r.variant is int or r.variant<0: return failure("装备材质版本不合法。")
   var placement=g._prepare_installation(r.get("template",""),r.get("slot",""),r.grade,r.locked,r.get("point",""),r.get("layer",-1))
   if placement.reason!="" and not placement.get("capacity_full",false): return failure(placement.reason)
   if r.tier not in [1,2,3]: return failure("安装紧度必须为一至三档。")
   if r.variant>=g.Equipment.MATERIALS[g.Equipment.TEMPLATES[r.template].material][r.grade].size(): return failure("装备材质版本不合法。")
   var points=placement.points
   r.point=points[0] if g.Equipment.SEGMENTS.has(r.slot) else r.slot
  elif r.kind=="assembly":
   r.family=r.get("family","");r.variant=r.get("variant","");r.straps=r.get("straps","straight")
   if not r.variant is String: return failure("复合装备需要明确款式。")
   r.grade=r.get("grade",2);r.tier=r.get("tier",2);r.parts=r.get("parts",{}).duplicate(true) if r.get("parts",{}) is Dictionary else null
   if r.parts==null: return failure("复合组件规格必须按组件列出。")
   var layout=g.Composites.spec(r.family,r.variant,r.straps)
   if layout.is_empty(): return failure("复合装备款式尚未定义。")
   var issue=g._assembly_reason(layout,r.get("attached_to",""))
   if issue!="": return failure(issue)
   if r.grade not in g.Equipment.GRADES or r.grade<layout.minimum or r.tier not in [1,2,3]: return failure("复合装备的品质或紧度不满足安装要求。")
   for key in r.parts:
    if key not in layout.parts or not r.parts[key] is Dictionary: return failure("复合组件规格不属于这件装备。")
    if r.parts[key].has("tier") and (not r.parts[key].tier is int or r.parts[key].tier not in [1,2,3]): return failure("组件紧度必须为一至三档。")
    if r.parts[key].has("locked") and not r.parts[key].locked is bool: return failure("组件上锁要求不合法。")
   if r.get("locked",false):
    for key in layout.parts:
     if not r.parts.has(key): r.parts[key]={}
     r.parts[key].locked=true
  else:
   r.type=r.get("type",r.get("template",""))
   if not g.SpecialEquipment.DESIGNS.has(r.type): return failure("这件特殊装备尚未定义。")
   var design=g.SpecialEquipment.DESIGNS[r.type]
   r.slot=r.get("slot",design.slots[0])
   if r.slot!=design.slots[0]: return failure("该装备不能安装在这个位置。")
   if r.get("locked",false) or (r.has("grade") and r.grade!=design.grade) or r.get("tier",2) not in [1,2,3] or r.get("variant",0)!=0:
    return failure("这件特殊装备的品质和固定方式由自身款式决定。")
  normalized.append(r)
 return {"ok":true,"requests":normalized}

# Capacity points actually occupied by one piece; a zero-cost special occupies none.
static func capacity_points(g, piece: Dictionary) -> Array:
 if g.SpecialEquipment.is_special(piece):
  return g.SpecialEquipment.occupied_slots(piece) if g.SpecialEquipment.capacity_cost(piece)>0 else []
 return g.Equipment.capacity_points(piece)

# Physical points covered by one piece, regardless of capacity cost.
static func physical_points(g, piece: Dictionary) -> Array:
 return g.SpecialEquipment.occupied_slots(piece) if g.SpecialEquipment.is_special(piece) else g.Equipment.physical_points(piece)

# Occupied capacity per point; special equipment weighs its own capacity cost.
static func counts(g, pieces: Array) -> Dictionary:
 var result={}
 for piece in pieces:
  var amount=g.SpecialEquipment.capacity_cost(piece) if g.SpecialEquipment.is_special(piece) else 1
  for point in capacity_points(g,piece): result[point]=result.get(point,0)+amount
 return result

# Removable outermost units that overlap the deficit: whole ordinary/special
# pieces plus the dependent components of a composite root (its body is the id).
static func units(g, equipment: Array, special_equipment: Array, composites: Array, deficit: Dictionary) -> Array:
 var result=[]
 for piece in equipment+special_equipment:
  if g.Equipment.lock_only(piece): continue
  if g.SpecialEquipment.is_chastity(piece) or g.SpecialEquipment.is_reinforcement(piece): continue
  if not g._outer(piece): continue
  var piece_counts=counts(g,[piece])
  if piece_counts.keys().any(func(p):return p in deficit): result.append({"id":piece.id,"pieces":[piece.duplicate(true)],"counts":piece_counts,"composite":false})
 for root in composites:
  var dependent=root.components.filter(func(e):return not e.get("independent",false))
  var body=g._composite_body(root)
  if not body.is_empty() and dependent.all(func(e):return g._outer(e)):
   var dependent_counts=counts(g,dependent)
   if dependent_counts.keys().any(func(p):return p in deficit): result.append({"id":body.id,"pieces":dependent.duplicate(true),"counts":dependent_counts,"composite":true})
  for piece in root.components:
   if not piece.get("independent",false) or not g._outer(piece): continue
   var single_counts=counts(g,[piece])
   if single_counts.keys().any(func(p):return p in deficit): result.append({"id":piece.id,"pieces":[piece.duplicate(true)],"counts":single_counts,"composite":false})
 return result

# Branch only on a still-full position. Never peel a layer exposed by an earlier
# removal, or add an unrelated weak item to manufacture a majority.
static func sets(units: Array, remaining: Dictionary, chosen: Array, search: Dictionary) -> void:
 var key=chosen.duplicate();key.sort()
 var signature=str(key)
 if search.seen.has(signature): return
 search.seen[signature]=true
 var point=""
 for p in remaining:
  if remaining[p]>0: point=p;break
 if point=="":
  if chosen.size()<search.minimum: search.minimum=chosen.size();search.sets=[]
  if chosen.size()==search.minimum: search.sets.append(key)
  return
 if chosen.size()>=search.minimum: return
 for i in range(units.size()):
  if i in chosen or units[i].counts.get(point,0)==0: continue
  var next=remaining.duplicate()
  for p in next: next[p]-=units[i].counts.get(p,0)
  sets(units,next,chosen+[i],search)

# Every legal way to keep affected links on the new anchors. `anchors` are the
# incoming pieces; `link_anchors` and `live_links` are the validator's anchor set
# and current link list, hoisted by the caller: the transaction's link set does not
# change during one search, so the old per-candidate reads return the same value.
static func transfer_options(g, links: Array, anchors: Array, link_anchors: Array, live_links: Array) -> Array:
 var options=[]
 for link in links:
  var choices=[]
  var ends=[]
  for i in range(2):
   var old=g._equipment(link.ends[i])
   ends.append([old] if not old.is_empty() else anchors.filter(func(e):return link.contact_points[i] in g.Links.anchor_points(e,link.slots[i])))
  if link.slots.all(func(slot):return g._sealed_reason(slot)==""):
   for a in ends[0]:
    for b in ends[1]:
     var candidate=link.duplicate(true)
     candidate.ends=[a.id,b.id]
     candidate.blocked_slip=link.blocked_slip.map(func(id):return candidate.ends[link.ends.find(id)])
     if g.Links.validate(candidate,link_anchors,live_links)=="": choices.append(candidate)
  options.append(choices)
 var best={"count":-1,"solutions":[],"seen":{}}
 transfer_search(g,links,options,0,[],[],best,link_anchors,live_links)
 return best.solutions

static func transfer_search(g, links: Array, options: Array, index: int, kept: Array, lost: Array, best: Dictionary, link_anchors: Array, live_links: Array) -> void:
 # Empty option lists are unavoidable losses. If reaching the current best
 # requires keeping every other link, its loss set is already determined.
 # A previously found assignment for that set has the same comparison score.
 if best.count==links.size(): return
 var potential=kept.size()
 var fixed_losses=lost.duplicate()
 for remaining in range(index,links.size()):
  if options[remaining].is_empty(): fixed_losses.append(links[remaining].id)
  else: potential+=1
 if potential<best.count or (potential==best.count and best.seen.has(str(fixed_losses))): return
 if index==links.size():
  if kept.size()>best.count: best.count=kept.size();best.solutions=[];best.seen={}
  var signature=str(lost)
  if kept.size()==best.count and not best.seen.has(signature):
   best.seen[signature]=true
   best.solutions.append({"kept":kept.duplicate(true),"lost":lost.duplicate()})
  return
 for candidate in options[index]:
  if g.Links.validate(candidate,link_anchors,live_links+kept)=="":
   transfer_search(g,links,options,index+1,kept+[candidate],lost,best,link_anchors,live_links)
 transfer_search(g,links,options,index+1,kept,lost+[links[index].id],best,link_anchors,live_links)

static func comparison_value(g, piece: Dictionary) -> int:
 # Special durability drives its own damage rules, not an ordinary tightness.
 var tightness=0
 if not g.SpecialEquipment.is_special(piece):
  tightness=piece.tier if piece.has("tier") else g.tier(piece.durability,piece.maximum)
 return int(piece.grade)+tightness+(1 if piece.get("locked",false) else 0)

# Strength penalty of removing `piece` at `point`: lost links attached there plus,
# at the shoulder anchor, the shoulder pieces lost with their host.
static func loss(g, piece: Dictionary, point: String, unit: Dictionary, before_links: Array, lost: Array) -> int:
 var ids={}
 for link in before_links:
  if link.id not in lost: continue
  for i in range(2):
   if link.ends[i]==piece.id and link.contact_points[i]==point: ids[link.id]=true
 if point=="upper_arm_top":
  var shoulders=piece.get("shoulders",{}).get("pieces",[])
  if unit.composite: shoulders=unit.pieces.filter(func(e):return g.Equipment.is_shoulder(e))
  for strap in shoulders:
   if strap.id in lost: ids[strap.id]=true
 return ids.size()

# Strength comparison and assignment. `before_links` is the pre-transaction link
# set used to price losses; rows are built only for points in the deficit.
static func compare(g, units: Array, installed: Array, deficit: Dictionary, before_links: Array, lost: Array) -> Dictionary:
 var rows=[]
 var strict_roots={}
 for unit in units:
  if unit.composite:
   var points=[]
   for piece in unit.pieces:
    for point in physical_points(g,piece):
     if point not in points: points.append(point)
   var singles=installed.filter(func(item):return not item.has("components") and physical_points(g,item).any(func(p):return p in points))
   var strict=singles.size()>=points.size()
   for point in points:
    var locals=unit.pieces.filter(func(piece):return point in physical_points(g,piece))
    var incoming=singles.filter(func(piece):return point in physical_points(g,piece))
    if incoming.is_empty(): strict=false
    for old in locals:
     if incoming.any(func(piece):return comparison_value(g,piece)<=comparison_value(g,old)+loss(g,old,point,unit,before_links,lost)): strict=false
   strict_roots[unit.id]=strict
  for piece in unit.pieces:
   for point in capacity_points(g,piece):
    if point not in deficit: continue
    rows.append({"old_id":piece.id,"unit":unit.id,"point":point,"old_value":comparison_value(g,piece)+loss(g,piece,point,unit,before_links,lost),"lost_link_bonus":loss(g,piece,point,unit,before_links,lost),"composite":unit.composite})
 # Incidental overlap from removing a whole root is not an extra voting ticket.
 rows.sort_custom(func(a,b):return a.old_value>b.old_value)
 var needed={};var selected=[]
 for row in rows:
  if needed.get(row.point,0)>=deficit[row.point]: continue
  needed[row.point]=needed.get(row.point,0)+1;selected.append(row)
 var assigned=assign(g,selected,installed,strict_roots,0,{}, {},[])
 var score=0
 for row in rows: score+=row.old_value
 return {"ok":assigned.ok,"rows":assigned.get("rows",[]),"score":score}

# Exact assignment search: each new piece may fill one row per point, and a
# composite's overlapping components must not be counted as extra voting tickets.
static func assign(g, rows: Array, installed: Array, strict_roots: Dictionary, index: int, used: Dictionary, votes: Dictionary, results: Array) -> Dictionary:
 if index==rows.size():
  for tally in votes.values():
   if tally.low<=tally.high: return {"ok":false}
  return {"ok":true,"rows":results}
 var row=rows[index]
 for i in range(installed.size()):
  var item=installed[i]
  var composite=item.has("components")
  if not composite and row.composite and not strict_roots.get(row.unit,false): continue
  for piece in pieces(item):
   var key=piece.id+":"+row.point
   if used.has(key) or row.point not in capacity_points(g,piece): continue
   var value=comparison_value(g,piece)
   if not composite and value<row.old_value: continue
   var next_used=used.duplicate();next_used[key]=true
   var next_votes=votes.duplicate(true)
   if composite:
    if not next_votes.has(i): next_votes[i]={"low":0,"high":0}
    next_votes[i]["low" if row.old_value<=value else "high"]+=1
   var result=row.duplicate();result.new_id=piece.id;result.new_value=value;result.request=i
   var attempt=assign(g,rows,installed,strict_roots,index+1,next_used,next_votes,results+[result])
   if attempt.ok: return attempt
 return {"ok":false}

# A composite carries its components; any other record is its own single piece.
static func pieces(item: Dictionary) -> Array:
 return item.components if item.has("components") else [item]
