extends RefCounted
const Navigation=preload("res://tests/interface_ui_cases.gd")

static func run(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game.state.items.clear();ui.game._gain_tool("return_seal")
 ui.game.state.phase="map";ui.render();await t.frames()
 var before=ui.game.export_snapshot()
 await Navigation.press(t,"OpenItems")
 var item=ui.view.items[0]
 var drawer=ui.find_child("InformationDrawer",true,false)
 var glyph=ui.find_child("ToolIcon_"+item.id,true,false)
 t.check(glyph!=null and glyph.symbol=="return_scroll" and glyph.kind=="tool","INVENTORY return seal uses the existing scroll artwork")
 var text=t.visible_text(drawer)
 t.check(text.contains("监狱外部路线") and text.contains("剩余1次") and not text.contains("每次消耗1次使用次数") and not text.contains("0能量"),"INVENTORY default view keeps effect and count without repetitive costs")
 t.check(ui.find_child("ItemHelpContent",true,false)==null and drawer.size.y<500 and ui.game.state==before,"INVENTORY compact initial drawer and browsing are read-only")
 await t.capture("ui-inventory-compact.png")
 await Navigation.press(t,"ItemHelpToggle")
 t.check(t.visible_text(ui.find_child("ItemHelpContent",true,false)).contains("手指或脚趾") and ui.game.state==before,"INVENTORY detailed rules remain available on demand without gameplay changes")
 await Navigation.press(t,"ItemHelpToggle")
 ui.game.RelicEffects.gain(ui.game,"toolbox");ui.game._gain_tool("mana_potion");ui.game._gain_tool("saw")
 ui.game.state.mana=60;ui.render();await t.frames()
 for row in ui.view.items:
  await Navigation.press(t,"ToolItem_"+row.id)
  var icon=ui.find_child("ToolIcon_"+row.id,true,false)
  t.check(icon!=null and icon.symbol==("return_scroll" if row.type=="return_seal" else row.type),"INVENTORY every actual item retains its own stable icon mapping")
  t.check(ui.find_child("ItemHelpContent",true,false)==null,"INVENTORY changing selection closes the previous item rules")
 await t.capture("ui-inventory-tools.png")
 var selected=ui.selected_item;before=ui.game.export_snapshot()
 await Navigation.press(t,"ItemHelpToggle")
 await Navigation.press(t,"ItemDiscard")
 t.check(ui.game._item(selected).is_empty() and ui.game.state.items.size()==before.items.size()-1 and ui.game.state.energy==before.energy and ui.game.state.tick==before.tick,"INVENTORY compact discard submits the actual chosen item once and costs no turn")
 t.check(ui.find_child("ItemHelpContent",true,false)==null,"INVENTORY removing the selection collapses rules for the replacement item")
 await t.close_information()
