extends Control

var equipment: Dictionary={}
var accent=Color("87d2d0")
var caption=""

func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 if caption!="":
  var heading=Label.new();heading.name="TargetBodyCaption";heading.text=caption
  heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  heading.add_theme_font_size_override("font_size",11);heading.add_theme_color_override("font_color",accent)
  heading.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(heading)
  heading.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
 if not equipment.get("image","").is_empty():
  var icon=TextureRect.new();icon.name="EquipmentTargetImage"
  icon.texture=load(equipment.image);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  icon.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
  add_child(icon);icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  icon.offset_left=5;icon.offset_right=-5;icon.offset_top=18 if caption!="" else 4;icon.offset_bottom=-17
 else:
  var label=Label.new();label.text=equipment.get("name","自由部位")
  label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
  label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.add_theme_font_size_override("font_size",12)
  label.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(label)
  label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);label.offset_bottom=-15
  if caption!="": label.offset_top=16
 resized.connect(queue_redraw)

func _draw() -> void:
 if equipment.is_empty() or equipment.get("lock_only",false): return
 var bar=Rect2(5,size.y-12,size.x-10,7)
 draw_rect(bar,Color("0b1720"))
 draw_rect(Rect2(bar.position,Vector2(bar.size.x*clampf(equipment.ratio,0,1),bar.size.y)),accent)
 for ratio in [0.4,0.8]:
  var x=bar.position.x+bar.size.x*ratio
  var top=Vector2(x,bar.position.y-3)
  var bottom=Vector2(x,bar.end.y+3)
  draw_line(top,bottom,Color("07131d"),4)
  draw_line(top,bottom,Color("ffd75e"),2)
