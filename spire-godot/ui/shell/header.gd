extends Control

func configure(ui) -> void:
 var view=ui.view
 $Trim.color=ui.GOLD.darkened(0.62)
 var info_style=ui._style(Color("121e27"),Color("35424a"),9);info_style.shadow_size=0
 $HeaderInfo.add_theme_stylebox_override("panel",info_style)
 var location_style=ui._style(Color("302d25"),Color("65583e"),8);location_style.shadow_size=0
 $HeaderInfo/Location.add_theme_stylebox_override("panel",location_style)
 var tone=ui.RED if view.run_header.last else ui.CYAN
 var order_style=ui._style(tone.darkened(0.82),tone.darkened(0.62),6);order_style.shadow_size=0
 $HeaderInfo/HeaderOrderBadge.add_theme_stylebox_override("panel",order_style)
 for entry in [["HeaderFloor",view.run_header.location,ui.GOLD],["HeaderRound",view.run_header.turn,ui.TEXT],["HeaderOrder",view.run_header.order,tone],["HeaderSecurity","警戒度%d级" % view.security,ui.GOLD],["WallPosition","距墙%d格" % view.wall_position.distance,ui.MUTED]]:
  var label=get_node("HeaderInfo/"+entry[0])
  label.text=entry[1];label.add_theme_color_override("font_color",entry[2])
 $HeaderInfo/WallPosition.visible=view.wall!="none"
 var book=ui._button("教程书",func():ui._open_tutorial(),ui.GOLD)
 book.name="OpenTutorial"
 for state in ["normal","hover","pressed"]:
  var glow=ui._style(Color("514127") if state=="normal" else Color("695433") if state=="hover" else Color("3c3020"),Color("e4c17e"),8)
  glow.shadow_color=Color(0.79,0.65,0.34,0.22);glow.shadow_size=4
  book.add_theme_stylebox_override(state,glow)
  book.add_theme_color_override("font_color" if state=="normal" else "font_"+state+"_color",Color("ffe4a6"))
 ui._place(book,Rect2(714,12,100,38),self)
 var status=ui._button("状态 !" if view.pressure.overloaded else "状态",func():ui._open_drawer("show_pressure"),ui.RED if view.pressure.overloaded else ui.CYAN)
 status.name="OpenStatus";ui._place(status,Rect2(830,12,144,38),self)
 var items=ui._button("道具 %d / %d" % [view.carried_items,view.capacity],func():ui._open_drawer("show_items"))
 items.name="OpenItems";ui._place(items,Rect2(990,12,154,38),self)
 var deck=ui._button("卡组 %d" % view.deck_count,func():ui._open_drawer("show_deck"))
 deck.name="OpenDeck";ui._place(deck,Rect2(1160,12,118,38),self)
 var in_prison=view.prison.get("active",false) or view.phase in ["captured","prison_end"]
 var map=ui._button("牢房说明" if in_prison else "返回房间" if ui.show_route and view.phase in ["battle","prepare","reward","rest","event","shop","treasure","departure"] else ("练习说明" if view.practice else "塔路"),func():
  if in_prison:ui._open_tutorial("prison")
  elif ui.view.phase in ["battle","prepare","reward","rest","event","shop","treasure","departure"]:
   ui.show_route=not ui.show_route;ui._close_drawers()
   ui.selected_card="";ui.show_body=false
   ui.render(ui.view),ui.CYAN)
 map.name="OpenPrisonTutorial" if in_prison else "OpenMap"
 ui._place(map,Rect2(1294,12,118,38),self)
 var menu=ui._button("菜单 !" if ui.save_failed else "菜单 ≡",func():ui._open_drawer("show_menu"),ui.RED if ui.save_failed else ui.MUTED)
 menu.name="OpenMenu";ui._place(menu,Rect2(1428,12,136,38),self)
