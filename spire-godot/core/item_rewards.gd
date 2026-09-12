extends RefCounted
const Tools=preload("res://data/field_tools.gd")

# Called once by battle completion, never by a view or reward acknowledgement.
static func roll(g) -> void:
 var chance=g.state.item_drop_chance
 var dropped=g._random_index("item_drop",100)<chance
 g.state.item_drop_chance=clampi(chance+(-Tools.DROP_STEP if dropped else Tools.DROP_STEP),0,100)
 g.state.battle_item_drop=""
 if not dropped: return
 var type=Tools.DROP_POOL[g._random_index("item_drop",Tools.DROP_POOL.size())]
 g.state.battle_item_drop=type
 g._emit("event","发现"+Tools.TYPES[type].name+"，可以在战利品中领取。",{"item_drop":{"type":type,"chance":chance}})
