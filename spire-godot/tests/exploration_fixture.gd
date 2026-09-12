extends RefCounted
const Space=preload("res://core/prison_space.gd")
# Explicit spatial fixtures for tests of other features. Full travel is covered separately.
static func position(g, pos: Array) -> void:
 g.state.prison.space.position=pos.duplicate();g.state.wall_distance=Space.wall_distance(pos)
static func site(g, name: String) -> Dictionary:
 return g.state.prison.space.sites.filter(func(s):return s.id==name or s.discovery==name or (name=="door" and s.id=="place_1"))[0]
static func at_site(g, name: String) -> void:
 position(g,site(g,name).position)
static func mark_found(g, name: String) -> void:
 site(g,name).visited=true;g.state.prison.discoveries.erase(name)
 if name not in g.state.prison.found: g.state.prison.found.append(name)
static func approach(g, name: String) -> Dictionary:
 var dest=site(g,name);var s=g.state.prison.space
 var route=Space.path(s,s.position,dest.position)
 if route.is_empty():
  for delta in Space.DIRECTIONS.values():
   var next=[dest.position[0]+delta[0],dest.position[1]+delta[1]]
   if Space.walkable(s,next): position(g,next);break
 else: position(g,route[-2] if route.size()>1 else s.position)
 var payload={"action":"explore"}
 if g.occupied("eyes"):
  var delta=[dest.position[0]-s.position[0],dest.position[1]-s.position[1]]
  for d in Space.DIRECTIONS:
   if Space.DIRECTIONS[d]==delta: payload.direction=d;payload.steps=1
 else: payload.site=dest.id
 return payload
static func collect(t,g) -> void:
 for name in g.Prison.ACTIVE_DISCOVERIES:
  if name in g.state.prison.found: continue
  var payload=approach(g,name);g.state.energy=3
  t.check(t.action(g,"prison",payload).ok,"EXP fixture arrival uses formal discovery and movement")
