extends Control

var host
var texture: Texture2D
var origin: WeakRef
var native_size=false
var scroller: ScrollContainer
var canvas: Control
var picture: TextureRect
var zoom: Button

func _ready() -> void:
 name="CardArtInspection";z_index=300;mouse_filter=Control.MOUSE_FILTER_STOP
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var shade=Button.new();shade.name="ArtInspectionBackdrop";shade.focus_mode=Control.FOCUS_NONE
 var style=StyleBoxFlat.new();style.bg_color=Color(0.01,0.015,0.025,0.94)
 for state in ["normal","hover","pressed","focus"]: shade.add_theme_stylebox_override(state,style)
 add_child(shade);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 shade.pressed.connect(dismiss)
 scroller=ScrollContainer.new();scroller.name="ArtInspectionScroll";add_child(scroller)
 scroller.gui_input.connect(func(event):
  if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed and not picture.get_global_rect().has_point(get_global_mouse_position()):
   scroller.accept_event();dismiss())
 canvas=Control.new();canvas.mouse_filter=Control.MOUSE_FILTER_IGNORE;scroller.add_child(canvas)
 picture=TextureRect.new();picture.name="ArtInspectionImage";picture.texture=texture
 picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 picture.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;picture.mouse_filter=Control.MOUSE_FILTER_STOP
 canvas.add_child(picture)
 zoom=host._button("",func():native_size=not native_size;_arrange(),host.GOLD)
 zoom.name="ArtInspectionZoom";add_child(zoom)
 resized.connect(_arrange)
 get_viewport().size_changed.connect(_arrange.call_deferred)
 _arrange();zoom.grab_focus()

func _arrange() -> void:
 if not is_instance_valid(picture): return
 zoom.text=host._text("ui.art.inspect.fit","适应屏幕") if native_size else host._text("ui.art.inspect.native","1:1 原图")
 zoom.position=Vector2(24,20);zoom.size=Vector2(180,38)
 scroller.position=Vector2(24,76);scroller.size=size-Vector2(48,152)
 scroller.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO if native_size else ScrollContainer.SCROLL_MODE_DISABLED
 scroller.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO if native_size else ScrollContainer.SCROLL_MODE_DISABLED
 scroller.mouse_filter=Control.MOUSE_FILTER_STOP if native_size else Control.MOUSE_FILTER_IGNORE
 # A source pixel occupies one screen pixel in native mode, including window scaling.
 var pixels=texture.get_size()/get_screen_transform().get_scale().abs()
 var available=scroller.size-Vector2(18,18) if native_size else scroller.size
 var factor=1.0 if native_size else minf(1.0,minf(available.x/pixels.x,available.y/pixels.y))
 picture.size=pixels*factor
 canvas.custom_minimum_size=picture.size.max(available)
 picture.position=(canvas.custom_minimum_size-picture.size)/2
 scroller.scroll_horizontal=0;scroller.scroll_vertical=0

func dismiss() -> void:
 if is_queued_for_deletion(): return
 hide()
 # Release modal identity now; tree-exit callbacks must not reenter parent removal.
 name="ClosingArtInspection"
 queue_free()
 var card=origin.get_ref() if origin!=null else null
 if is_instance_valid(card) and card.is_visible_in_tree(): card.grab_focus()
