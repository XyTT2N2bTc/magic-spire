extends RefCounted

static func build(ui) -> void:
 if not ui.view.mana_flask.available: return
 var panel=Control.new();panel.name="ManaFlask";panel.z_index=100;panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
 ui._place(panel,Rect2(38,697,300,87))
 var icon=TextureRect.new();icon.name="FlaskIcon";icon.tooltip_text="贴身魔瓶";icon.mouse_filter=Control.MOUSE_FILTER_STOP
 icon.texture=preload("res://assets/ui/mana-flask.svg");icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 ui._place(icon,Rect2(-3,-8,120,104),panel)
 var value=ui._label(ui.game.number(ui.view.mana_flask.mana),25,ui.CYAN);value.name="FlaskManaValue"
 value.autowrap_mode=TextServer.AUTOWRAP_OFF;value.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 value.tooltip_text=ui.game.number(ui.view.mana_flask.mana);value.mouse_filter=Control.MOUSE_FILTER_STOP
 ui._place(value,Rect2(123,22,91,36),panel)
 var uses=ui._label("●".repeat(ui.view.mana_flask.remaining)+"○".repeat(2-ui.view.mana_flask.remaining),12,ui.GOLD)
 uses.name="FlaskDepositUses";uses.tooltip_text="本回合可存入%d次" % ui.view.mana_flask.remaining;uses.mouse_filter=Control.MOUSE_FILTER_STOP
 ui._place(uses,Rect2(125,54,64,18),panel)
 for op in ["deposit","withdraw"]:
  var choice=ui.actions.find("flask",{"op":op})
  if choice.is_empty(): continue
  var label="存入" if op=="deposit" else "取出"
  var button=ui._button(label,func():ui._submit(choice),ui.CYAN)
  button.name="FlaskDeposit" if op=="deposit" else "FlaskWithdraw"
  button.disabled=not choice.valid;button.tooltip_text=choice.detail if choice.valid else choice.reason
  button.add_theme_font_size_override("font_size",13);button.custom_minimum_size.y=28
  for state in ["normal","disabled"]:
   var style=ui._style(Color("13222e"),Color("456068") if state=="normal" else Color("303f48"),6)
   style.shadow_size=0;style.set_border_width_all(1)
   button.add_theme_stylebox_override(state,style)
  ui._place(button,Rect2(225,9 if op=="deposit" else 49,72,28),panel)
  ui.candidate_buttons[choice.id]=button
