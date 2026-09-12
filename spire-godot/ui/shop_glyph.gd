extends Control
var kind="relic"
var symbol=""

func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
 var center=size/2
 var gold=Color("cfb67d");var cyan=Color("88d3db")
 draw_circle(center,30,Color(0.69,0.62,0.4,0.07))
 if kind=="card":
  for i in range(3):
   var card=Rect2(center+Vector2(-25+i*9,-27+i*5),Vector2(35,49))
   draw_style_box(preload("res://ui/visual_theme.gd").surface(Color("233847"),gold,3),card)
  draw_line(center+Vector2(3,0),center+Vector2(17,0),cyan,3,true)
 elif kind=="tool":
  if symbol.ends_with("potion"):
   draw_rect(Rect2(center+Vector2(-8,-27),Vector2(16,13)),gold)
   draw_line(center+Vector2(-7,-14),center+Vector2(-17,-3),Color("d7e3df"),3,true)
   draw_line(center+Vector2(7,-14),center+Vector2(17,-3),Color("d7e3df"),3,true)
   draw_circle(center+Vector2(0,8),21,Color("cfdddf"))
   draw_circle(center+Vector2(0,10),17,{"mana_potion":cyan,"energy_potion":gold,"charge_potion":Color("dc927e"),"lubricant_potion":Color("d6b64c")}.get(symbol,cyan))
   draw_line(center+Vector2(-9,0),center+Vector2(-12,9),Color("f2f5eb"),3,true)
  elif symbol.ends_with("scroll"):
   draw_style_box(preload("res://ui/visual_theme.gd").surface(Color("a38b62"),gold,3),Rect2(center+Vector2(-19,-21),Vector2(38,45)))
   for y in [-22,23]: draw_line(center+Vector2(-26,y),center+Vector2(26,y),Color("e2cc9d"),6,true)
   draw_arc(center,9,0,TAU,20,Color("415c6b"),2,true)
  elif symbol=="shard":
   draw_colored_polygon(PackedVector2Array([center+Vector2(-20,19),center+Vector2(-8,-24),center+Vector2(20,8)]),Color("b4bbb7"))
   draw_line(center+Vector2(-8,-24),center+Vector2(2,12),Color("f0e2c7"),2,true)
  elif symbol=="saw":
   draw_line(center+Vector2(-25,21),center+Vector2(15,-18),Color("d3c9b3"),12,true)
   draw_arc(center+Vector2(22,-23),12,0,TAU,24,gold,5,true)
   for n in range(5): draw_line(center+Vector2(-22+n*6,20-n*6),center+Vector2(-15+n*6,21-n*6),Color("64777f"),3,true)
  else:
   draw_line(center+Vector2(-23,22),center+Vector2(14,-19),gold,4,true)
   draw_arc(center+Vector2(17,-19),8,PI,TAU*1.25,22,gold,4,true)
   draw_line(center+Vector2(-14,25),center+Vector2(23,-12),Color("aec5c8"),3,true)
 else:
  draw_arc(center,28,0,TAU,36,gold,2,true)
  var diamond=PackedVector2Array([center+Vector2(0,-24),center+Vector2(18,0),center+Vector2(0,24),center+Vector2(-18,0)])
  draw_colored_polygon(diamond,cyan.darkened(0.4));diamond.append(diamond[0]);draw_polyline(diamond,gold,2,true)
  draw_line(center+Vector2(0,-24),center+Vector2(0,24),cyan,2,true)
  draw_circle(center+Vector2(-5,-7),4,Color("e3f6dc"))
