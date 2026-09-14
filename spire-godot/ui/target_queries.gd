extends RefCounted

# Read-only selection from one View and its ActionIndex. No nodes, game or retained cache.
const RELEASE_MODES=["strain","slip","magic_slip","lower","unlock"]

static func body_at(view: Dictionary, slot: String) -> Dictionary:
 for region in view.body_regions:
  if region.id==slot: return region
 for body in view.body_groups:
  if body.id==slot or slot in body.slots: return body
 return view.body_groups[0]

static func equipment_entries(body: Dictionary) -> Dictionary:
 var entries={}
 for section in body.sections:
  for e in section.equipment:
   if not entries.has(e.id): entries[e.id]={"equipment":e,"locations":[]}
   entries[e.id].locations.append(section.name)
 return entries

static func body_cards(actions, body: Dictionary, uid: String) -> Array:
 var includes_neck=body.id=="neck" or body.get("members",[]).any(func(member):return member.id=="neck")
 var choices=actions.select("card",{"uid":uid}).filter(func(c):return c.payload.slot in body.slots or (includes_neck and body.targets.has(c.payload.target)))
 var seen={};var unique=[]
 for c in choices:
  # Merge a physical target per face, preferring a usable candidate without reordering it.
  var key=(c.payload.target if c.payload.target!="" or body.id=="neck" else c.payload.slot)+str(c.payload.free)
  if not seen.has(key):
   seen[key]=unique.size();unique.append(c)
  elif c.valid and not unique[seen[key]].valid:
   unique[seen[key]]=c
 var order=equipment_entries(body).keys()
 unique.sort_custom(func(a,b):return order.find(a.payload.target)<order.find(b.payload.target))
 return unique

static func single_body_card(actions, body: Dictionary, uid: String, free: bool) -> Dictionary:
 var entries=equipment_entries(body)
 if entries.size()!=1:return {}
 var choices=body_cards(actions,body,uid).filter(func(c):return c.payload.free==free)
 if choices.size()!=1 or not entries.has(choices[0].payload.target):return {}
 return choices[0]

static func single_equipment_card(actions, bodies: Array, uid: String, free: bool) -> Dictionary:
 var entries={}
 for body in bodies:entries.merge(equipment_entries(body))
 if entries.size()!=1:return {}
 var target=entries.keys()[0]
 var fields={"uid":uid,"free":free}
 var choices=actions.select("card",fields).filter(func(c):return c.payload.get("target","")!="")
 # Other explicit targets (including capture) still require a player choice.
 if choices.is_empty() or choices.any(func(c):return c.payload.target!=target):return {}
 fields.target=target
 return actions.first_usable("card",fields)

static func payload_candidates(actions, data: Dictionary, version: int) -> Array:
 if data.get("version",-1)!=version:return []
 if data.has("card_uid"):
  var out=actions.select("card",{"uid":data.card_uid,"free":data.get("free",false)})
  if not data.get("free",false):out.append_array(actions.select("prison",{"action":"unlock","uid":data.card_uid}))
  var seen=[]
  return out.filter(func(c):
   if not c.payload.has("hand_uid") or c.payload.get("self_target",false):return true
   var key=[c.payload.target,c.payload.slot]
   if key in seen:return false
   seen.append(key);return true)
 if data.has("action_type"):
  return actions.select("attack",{"type":data.action_type,"form":data.get("form",0)})
 var ids=data.get("candidate_ids",[data.self_action_id] if data.has("self_action_id") else [])
 return ids.filter(func(id):return actions.by_id.has(id)).map(func(id):return actions.by_id[id])

static func equipment_choices(actions, data: Dictionary, version: int, body: Dictionary) -> Array:
 var out=[];var seen=[]
 for c in payload_candidates(actions,data,version):
  var target=c.payload.get("target","")
  if target in seen or not body.targets.has(target):continue
  seen.append(target);out.append(c)
 return out

# Quick release and body details keep the FIRST rejection when none can be used.
# ActionIndex.first_usable deliberately keeps its existing LAST-rejection fallback.
static func first_usable(offers: Array) -> Dictionary:
 for c in offers:
  if c.valid:return c
 return offers[0] if not offers.is_empty() else {}

static func release_choices(actions, body: Dictionary, data: Dictionary, version: int) -> Array:
 if not data.has("card_uid") or data.get("version",-1)!=version:return []
 return body_cards(actions,body,data.card_uid).filter(func(c):
  return c.payload.get("mode","") in RELEASE_MODES and c.payload.free==data.get("free",false) and body.targets.has(c.payload.target))

static func release_candidate(actions, body: Dictionary, target: String, data: Dictionary, version: int) -> Dictionary:
 if data.get("action_type","")=="fireball" and data.get("version",-1)==version:
  return first_usable(actions.select("attack",{"type":"fireball","target":target}))
 return first_usable(release_choices(actions,body,data,version).filter(func(c):return c.payload.target==target))
