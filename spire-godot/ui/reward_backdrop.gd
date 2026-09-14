extends RefCounted

static func build(ui, root: Control, opacity: float) -> void:
 var header=ui.layout.get_node("GameHeader")
 var top=header.get_rect().end.y
 var shade=ColorRect.new()
 shade.name="RewardShade"
 shade.color=Color(0.018,0.026,0.04,opacity)
 ui._place(shade,Rect2(Vector2(0,top)-root.position,Vector2(1600,900-top)),root)
