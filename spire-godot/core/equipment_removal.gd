extends RefCounted
# Member-layer settlement (Q6'a, rev3.4 plan §7 / G-Q6-7, G-Q6-8', G-Q6-12): the live cleanup
# skeleton, moved here verbatim from `core/game.gd::_cleanup`, which now only delegates.
# The removal predicates stay on the game (the read-only judgment reaches them through the same
# `g`), the link-anchor list is read once before its loop so the link pass sees exactly the
# anchors left by the earlier passes, and this module preloads nothing: every dependency travels
# through the `g` parameter. Callers: `core/game.gd::_cleanup` only (REMOVAL_CALL_SITES).

static func settle(g,released: bool=true) -> void:
 var roots=g.Cards.restraint_roots(g) if released and not g.state.powers.is_empty() else []
 g.Shoulders.cleanup(g)
 for item in g.state.special_equipment.duplicate():
  if g._released(item):
   if g.SpecialEquipment.is_reinforcement(item):
    var owner=g._equipment(item.owner_id)
    if not owner.is_empty() and g.SpecialEquipment.supports_reinforcement(owner): owner.reinforcement_state="removed"
   g._special_erase(item)
   for strap in g.state.special_equipment.duplicate():
    if g._strap_follows(item,strap): g._special_erase(strap)
   g._emit("event",item.name+"已解除。")
 for strap in g.state.special_equipment.duplicate():
  if g._strap_orphaned(strap,g.state.special_equipment):
   g._special_erase(strap)
 for item in g.state.items.duplicate():
  if item.uses<=0:
   g._emit("event",g.Tools.TYPES[item.type].name+"已经耗尽次数。")
   g.state.items.erase(item)
 for i in range(g.state.equipment.size()-1,-1,-1):
  var e=g.state.equipment[i]
  g.RopeArt.track(g,e)
  if g._piece_released(e):
   g._emit("event",e.name+"已解除。")
   g.state.equipment.remove_at(i)
   g._member_changed(e,"removed")
 for root in g.state.composites.duplicate():
  var body=g._composite_body(root)
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
  g.RopeArt.track(g,link)
  if g._released(link):
   g.state.links.erase(link)
   g._member_changed(link,"removed")
   g._emit("event",link.name+"已解除。")
  elif g._link_anchor_lost(link,anchors):
   g.RopeArt.track(g,link,true)
   g.state.links.erase(link)
   g._member_changed(link,"removed")
   g._emit("event",link.name+"连接的一件装备已解除，这条链接随之移除。")
 g.Pressure.cleanup(g)
 g.Pressure.settle_maximum(g,"平板锁解除后")

 if not roots.is_empty():
  var remaining=g.Cards.restraint_roots(g)
  g.Cards.restraint_changed(g,"released",roots.filter(func(id):return id not in remaining).size())
