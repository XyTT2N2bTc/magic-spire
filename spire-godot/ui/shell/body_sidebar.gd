extends PanelContainer

const Palette=preload("res://ui/visual_theme.gd")

func _ready() -> void:
 add_theme_stylebox_override("panel",Palette.window_frame())

func configure(ui) -> void:
 $Canvas/Title.text="身体与拘束具"
 $Canvas/Title.add_theme_color_override("font_color",ui.GOLD)
 $Canvas/Divider.color=ui.GOLD.darkened(0.65)
 $Canvas/EquipmentPortrait.configure(ui.view,ui.display_settings.fixed_hero_portrait or ui.game.Character.active(ui.game))
 var slots=$Canvas/Slots
 for child in slots.get_children():
  slots.remove_child(child)
  child.queue_free()
 var index=0
 for body in ui.view.body_groups:
  var button=ui._button(body.name+("  "+str(body.count) if body.occupied else "")+("·链" if not body.links.is_empty() else ""),func():
   ui.show_body=not ui.show_body if ui._body_at(ui.selected_slot).id==body.id else true
   ui.selected_slot=body.id;ui.selected_candidate="";ui.player_pick=false
   ui.render(ui.view),ui.CYAN if body.id==ui._body_at(ui.selected_slot).id else (ui.GOLD if body.occupied else ui.MUTED.darkened(0.5)),true)
  button.tooltip_text=body.name+(" · %d件" % body.count if body.occupied else " · 自由")
  if body.can_release:
   button.add_theme_stylebox_override("normal",ui._style(Color("254b50"),ui.CYAN))
   button.tooltip_text+=" · 可一键解除"
  button.set_meta("can_release",body.can_release)
  button.name="BodySlot_"+body.id;button.custom_minimum_size=Vector2(120,29)
  button.accepted_kind="any"
  button.add_theme_font_size_override("font_size",12)
  button.hover_card=func(data):ui._show_drop_targets(body.id,data)
  button.accept_card=func(data):
   var candidate=ui._free_player_candidate(data,body.id)
   return not candidate.is_empty() and candidate.valid
  button.receive_card=func(data):
   var candidate=ui._free_player_candidate(data,body.id)
   if not candidate.is_empty() and candidate.valid:ui.call_deferred("_submit",candidate,int(data.version))
  ui._place(button,Rect2(186,34+index*32,120,29),slots)
  ui.body_buttons[body.id]=button
  for alias in body.slots:ui.body_buttons[alias]=button
  index+=1
