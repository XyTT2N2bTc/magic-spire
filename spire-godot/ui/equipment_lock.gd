extends Control
# One copper lock asset, with the shackle opened or closed from projected state.
var locked=false
var lockable=true

func _ready() -> void:
 custom_minimum_size=Vector2(26,28)
 mouse_filter=Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
 var shackle=PackedVector2Array()
 var center=Vector2(13,11) if locked else Vector2(18,7)
 for i in range(25):
  var angle=PI+PI*i/24.0
  shackle.append(center+Vector2(cos(angle),sin(angle))*6)
 shackle.insert(0,Vector2(center.x-6,17))
 shackle.append(Vector2(center.x+6,15 if locked else 10))
 draw_polyline(shackle,Color("634124"),5,true)
 draw_polyline(shackle,Color("e7bd78"),2,true)
 var body=StyleBoxFlat.new()
 body.bg_color=Color("bb8344")
 body.border_color=Color("664323")
 body.set_border_width_all(1)
 body.set_corner_radius_all(3)
 draw_style_box(body,Rect2(4,14,19,13))
 draw_line(Vector2(6,16),Vector2(20,16),Color("f3d295"),1,true)
 draw_circle(Vector2(13.5,20),2,Color("49321f"))
 draw_line(Vector2(13.5,20),Vector2(13.5,24),Color("49321f"),2,true)
 if not lockable:
  for points in [[Vector2(6,8),Vector2(22,24)],[Vector2(22,8),Vector2(6,24)]]:
   draw_line(points[0],points[1],Color("40191b"),5,true)
   draw_line(points[0],points[1],Color("ff5962"),3,true)
