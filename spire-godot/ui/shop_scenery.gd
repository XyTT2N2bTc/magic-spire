extends Control

# Frame sits behind the merchant; the canopy covers the top of the image.
var foreground=false

func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
 if foreground:
  _draw_canopy()
  return
 draw_style_box(preload("res://ui/visual_theme.gd").window_frame(),Rect2(Vector2.ZERO,size))
 for y in [416,550,688]:
  draw_rect(Rect2(380,y,size.x-400,12),Color("6c4e36"))
  draw_line(Vector2(380,y),Vector2(size.x-18,y),Color("c39c63"),2,true)
  for x in range(390,int(size.x)-20,41): draw_line(Vector2(x,y+5),Vector2(x+26,y+5),Color("453329"),1,true)

func _draw_canopy() -> void:
 for i in range(12):
  var x=14+i*(size.x-28)/12
  draw_rect(Rect2(x,12,(size.x-28)/12,40),Color("514653") if i%2==0 else Color("403941"))
  draw_circle(Vector2(x+(size.x-28)/24,52),(size.x-28)/24,Color("514653") if i%2==0 else Color("403941"))
 draw_line(Vector2(14,12),Vector2(size.x-14,12),Color("cfac74"),3,true)
