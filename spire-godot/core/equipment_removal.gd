extends RefCounted
# Member-layer settlement (Q6'a, rev3.4 plan §7 / G-Q6-7, G-Q6-8', G-Q6-12): the live cleanup
# skeleton, moved here verbatim from `core/game.gd::_cleanup`, which now only delegates.
# The removal predicates stay on the game (the read-only judgment reaches them through the same
# `g`), the link-anchor list is read once before its loop so the link pass sees exactly the
# anchors left by the earlier passes, and this module preloads nothing: every dependency travels
# through the `g` parameter. Callers: `core/game.gd::_cleanup` plus the six Q6'b write ports and
# dispatch hooks (REMOVAL_CALL_SITES).
#
# Q6'b dirty ledger (plan-delta §2.1, §3.1; G-Q6-1'…4', 9', 10'): `dispatch` binds the live state
# object to `g._settle_table` after its duplicate and unbinds before its success return. The four
# write ports mark what they wrote (`mark`, `replaced`), so a settle that runs while bound judges
# only the marked members plus the members whose verdict depends on one that left; every other
# member keeps the verdict the previous settle gave it. The ledger holds nothing else: no counter
# and no version key, and it never enters `state`, the view, a save, a checkpoint or the read
# cache. `settle_residue` (debug only) re-reads every removal predicate of the settled state and
# `unit_residue` (debug only) reads the one record whose join hook is running.

# The one ledger snapshot (plan-delta §2.1): the open window is five keys over the live state object.
# `bind` opens it and a settle that consumed its marks re-opens it, so the keys and their defaults
# have one constructor instead of one at each end.
static func _open(g) -> Dictionary:
 return {"bound":g.state,"writes":{},"leaves":{},"full":false,"blindfold":"cursed_blindfold" in g.state.relics}

# The one liveness test (plan-delta §1.4): a mark, a replacement announcement and a settle count only
# while the table is the live one. An empty table and a sandbox swap (the table still names the object
# the state was before the swap) are the same answer here, so no caller re-derives it.
static func _live(g,table: Dictionary) -> bool:
 return not table.is_empty() and is_same(g.state,table["bound"])

static func bind(g) -> void:
 g._settle_table=_open(g)

# A successful dispatch unbinds before returning; the two failure paths swap `g.state` back to the
# original object instead, so the next `bind` cannot mistake the stale table for the live one.
static func unbind(g) -> void:
 g._settle_table={}

# The one dirty-entry function (plan-delta §2.1): `written` (durability/quality), `added` and
# `removed` arrive from the write ports, and only while the live state object is the bound one --
# a sandbox swap (replacement trial, event preview, self-binding plan, compile) writes to a copy,
# so its marks are dropped here instead of leaking into the live table.
static func mark(g,record: Dictionary,change: String) -> void:
 var table: Dictionary=g._settle_table
 if not _live(g,table): return
 var id=String(record.get("id",""))
 if id=="": return
 if change=="removed": table["leaves"][id]=true
 else: table["writes"][id]=true

# M13: a whole-container replacement (the two `_commit_changes` callers) can move any member, so
# the next settle judges everything.
static func replaced(g) -> void:
 var table: Dictionary=g._settle_table
 if not _live(g,table): return
 table["full"]=true

# Filtering reads the two id sets only (plan-delta §1.2): a member is re-judged when a port wrote it
# or when it left. Composites widen this to their parts and their `attached_to` host (M06–M08);
# links widen it to either end (M09).
static func _marked(ids: Dictionary,record: Dictionary) -> bool:
 var id=String(record.get("id",""))
 return id!="" and ids.has(id)

static func _touched(writes: Dictionary,leaves: Dictionary,record: Dictionary) -> bool:
 return _marked(writes,record) or _marked(leaves,record)

static func _root_touched(writes: Dictionary,leaves: Dictionary,root: Dictionary) -> bool:
 if _touched(writes,leaves,root) or (String(root.get("attached_to",""))!="" and leaves.has(String(root.attached_to))): return true
 for part in root.components:
  if _touched(writes,leaves,part): return true
 return false

static func _link_touched(writes: Dictionary,leaves: Dictionary,link: Dictionary) -> bool:
 if _touched(writes,leaves,link): return true
 return link.ends.any(func(id):return leaves.has(String(id)))

static func settle(g,released: bool=true) -> void:
 var table: Dictionary=g._settle_table
 var bound=_live(g,table)
 var full=not bound or bool(table["full"])
 var writes: Dictionary=table["writes"] if bound else {}
 var leaves: Dictionary=table["leaves"] if bound else {}
 # M14: the cursed blindfold is the one relic a removal predicate reads, and a relic change is not
 # a member write, so a change since the bind falls back to the full scan.
 if bound and not full and ("cursed_blindfold" in g.state.relics)!=bool(table["blindfold"]): full=true
 var roots=g.Cards.restraint_roots(g) if released and not g.state.powers.is_empty() else []
 g.Shoulders.cleanup(g)
 for item in g.state.special_equipment.duplicate():
  if (full or _touched(writes,leaves,item)) and g._released(item):
   if g.SpecialEquipment.is_reinforcement(item):
    var owner=g._equipment(item.owner_id)
    if not owner.is_empty() and g.SpecialEquipment.supports_reinforcement(owner): owner.reinforcement_state="removed"
   g._special_erase(item)
   for strap in g.state.special_equipment.duplicate():
    if g._strap_follows(item,strap): g._special_erase(strap)
   g._emit("event",item.name+"已解除。")
 # M05: an orphan reinforcement strap belongs to whichever special item left, so this pass runs
 # whenever a member left; with nothing left it cannot change a verdict.
 for strap in g.state.special_equipment.duplicate():
  if (full or not leaves.is_empty()) and g._strap_orphaned(strap,g.state.special_equipment):
   g._special_erase(strap)
 for item in g.state.items.duplicate():
  if item.uses<=0:
   g._emit("event",g.Tools.TYPES[item.type].name+"已经耗尽次数。")
   g.state.items.erase(item)
 for i in range(g.state.equipment.size()-1,-1,-1):
  var e=g.state.equipment[i]
  if not (full or _touched(writes,leaves,e)): continue
  if g._piece_released(e):
   g._emit("event",e.name+"已解除。")
   g.state.equipment.remove_at(i)
   g._member_changed(e,"removed")
 for root in g.state.composites.duplicate():
  var body=g._composite_body(root)
  if not (full or _root_touched(writes,leaves,root)): continue
  if g._root_head_orphaned(root,g._equipment(root.attached_to)):
   g.state.composites.erase(root)
   for part in root.components: g._member_changed(part,"removed")
   g._member_changed(root,"removed")
   g._emit("event","口部固定带已解除，依附其上的头部马具一并移除。")
   continue
  if not body.is_empty() and g._released(body):
   var released_parts=root.components.filter(func(e):return not g._component_kept(e))
   root.components=root.components.filter(func(e):return g._component_kept(e))
   for part in released_parts: g._member_changed(part,"removed")
   if root.components.is_empty():
    g.state.composites.erase(root)
    g._member_changed(root,"removed")
   g._emit("event",root.name+"的套体已解除。"+("附带部件一并解除。" if root.components.is_empty() else ""))
  else:
   var previous_count=root.components.size()
   for part in root.components.duplicate():
    if g._released(part):
     root.components.erase(part)
     g._member_changed(part,"removed")
     g._emit("event",part.name+"已解除。")
   if root.components.is_empty():
    g.state.composites.erase(root)
    g._member_changed(root,"removed")
   elif not body.is_empty():
    var removed=root.components.size()<previous_count
    if removed and g._slip_reason(body)=="": g._emit("event","现在可以尝试滑脱"+root.name+"的套体。")
 var anchors=g.link_anchors()
 for link in g.state.links.duplicate():
  if not (full or _link_touched(writes,leaves,link)): continue
  if g._released(link):
   g.state.links.erase(link)
   g._member_changed(link,"removed")
   g._emit("event",link.name+"已解除。")
  elif g._link_anchor_lost(link,anchors):
   g.state.links.erase(link)
   g._member_changed(link,"removed")
   g._emit("event",link.name+"连接的一件装备已解除，这条链接随之移除。")
 g.Pressure.cleanup(g)
 g.Pressure.settle_maximum(g,"平板锁解除后")

 if not roots.is_empty():
  var remaining=g.Cards.restraint_roots(g)
  g.Cards.restraint_changed(g,"released",roots.filter(func(id):return id not in remaining).size())
 # G-Q6-2': after a settle that skipped members, a debug run re-reads every removal predicate.
 if bound and not full and g.debug_checks_enabled(): settle_residue(g)
 # The window stays bound; the marks were consumed, so a second settle in the same dispatch starts
 # empty instead of re-judging the same verdicts. `_open` writes the same snapshot `bind` does.
 if bound: g._settle_table=_open(g)

# The two reconciliations below differ in scope (whole state vs the one record whose join hook runs),
# not in how a member is judged, so each judgment they share is answered once here. A verdict that
# existed on only one side would let the whole-state scan and the unit scan disagree silently.
static func _released_residue(g,label: String,record: Dictionary) -> String:
 if g._released(record): return label+":"+String(record.get("id",""))
 return ""

# An ordinary piece has its own rule (`_piece_released` keeps a cursed-eyes piece without an absolute
# release), so that decision is its own single site rather than a label on `_released_residue`.
static func _piece_residue(g,record: Dictionary) -> String:
 if g._piece_released(record): return "piece:"+String(record.get("id",""))
 return ""

static func _orphan_residue(g,record: Dictionary) -> String:
 if g._strap_orphaned(record,g.state.special_equipment): return "orphan:"+String(record.get("id",""))
 return ""

static func _link_residue(g,link: Dictionary,anchors: Array) -> String:
 if g._released(link): return "link:"+String(link.get("id",""))
 if g._link_anchor_lost(link,anchors): return "anchor:"+String(link.get("id",""))
 return ""

# Debug-only reconciliation (G-Q6-2'): re-read the removal predicates of the settled state with no
# filter. A hit names a member whose removal the incremental settle missed -- an unregistered write,
# an unexpanded leave or a stale binding. Read-only: writes nothing, draws no random, emits nothing
# and never touches the ledger or a write port.
static func settle_residue(g) -> void:
 var residue=[]
 for item in g.state.special_equipment:
  var special_hit=_released_residue(g,"special",item)
  if special_hit!="": residue.append(special_hit)
 for strap in g.state.special_equipment:
  var orphan_hit=_orphan_residue(g,strap)
  if orphan_hit!="": residue.append(orphan_hit)
 for e in g.state.equipment:
  var piece_hit=_piece_residue(g,e)
  if piece_hit!="": residue.append(piece_hit)
 for root in g.state.composites:
  var body=g._composite_body(root)
  if g._root_head_orphaned(root,g._equipment(root.attached_to)): residue.append("head:"+String(root.get("id","")))
  elif not body.is_empty() and g._released(body):
   for part in root.components:
    if not g._component_kept(part): residue.append("body:"+String(part.get("id","")))
  else:
   for part in root.components:
    var part_hit=_released_residue(g,"part",part)
    if part_hit!="": residue.append(part_hit)
 var anchors_now=g.link_anchors()
 for link in g.state.links:
  var link_hit=_link_residue(g,link,anchors_now)
  if link_hit!="": residue.append(link_hit)
 g._debug_check("settle_residue","removal.settle",", ".join(residue))

# Debug-only piece settlement (G-Q6-10', CC-29/CC-33): the record whose join hook is running, held to
# its own removal rule only -- the frame's registration order is post-order, so a nested member was
# settled before its host. It never removes, never tracks, never touches the ledger and never calls
# `settle`. `B` has no removal rule and is not reconciled; `S` reads the host off the entry's
# `detail.host` and `R` also needs its owner to still be in the container.
static func unit_residue(g,entry: Array) -> void:
 var record: Dictionary=entry[0]
 var detail: Dictionary=entry[3]
 var residue=[]
 var hit=""
 match String(entry[1]):
  "P":
   hit=_piece_residue(g,record)
  "C":
   for part in record.components:
    var component_hit=_released_residue(g,"component",part)
    if component_hit!="": residue.append(component_hit)
   if String(record.get("kind",""))=="head" and g._equipment(String(record.get("attached_to",""))).is_empty(): residue.append("head:"+String(record.get("id","")))
  "S":
   var host: Dictionary=detail.get("host",{})
   if g.Shoulders.released_with_host(host,record): residue.append("shoulder:"+String(record.get("id","")))
  "R":
   hit=_released_residue(g,"strap",record)
   if hit=="": hit=_orphan_residue(g,record)
  "X":
   hit=_released_residue(g,"special",record)
  "K":
   hit=_link_residue(g,record,g.link_anchors())
 if hit!="": residue.append(hit)
 g._debug_check("unit_settle_residue","game.join_hooks",", ".join(residue))
