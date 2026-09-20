extends RefCounted
const Cases=preload("res://tests/ditto_cases.gd")
const Pointer=preload("res://tests/target_sidebar_ui_cases.gd")

static func run(t) -> void:
 var ui=t.ui
 ui.restart(42)
 for seed in range(512):
  var g=Cases.Game.new(seed,true,"shop")
  if g.room_data(g.state.room).stock.any(func(row):return row.type=="ditto"):
   ui.game=g;break
 t.check(ui.game.state.phase=="shop","DITTO UI natural shop contains uncommon exclusive relic")
 if ui.game.state.phase!="shop": return
 ui.game.state.mana=100;ui.shop_payment="self";ui.render();await t.frames()
 var offer=ui.view.shop.stock.filter(func(row):return row.type=="ditto")[0]
 await Pointer.press(t,ui.find_child("ShopOffer%d" % offer.index,true,false))
 var payment=ui.find_child("ShopPaymentContinue",true,false)
 if payment!=null: await Pointer.press(t,payment)
 t.check("ditto" in ui.game.state.relics and ui.game.state.mana==30 and ui.game.state.ditto_form=="" and ui.find_child("RelicShortcut_ditto",true,false)!=null,"DITTO UI purchase pays uncommon price and waits for next session to transform")
 ui.game=Cases.fixture("great_wand");ui.game.state.mana=40
 ui.game.state.relic_counters.ditto=4;ui.game.state.relic_counters.great_wand=2
 ui.render();await t.frames()
 var control=ui.find_child("RelicShortcut_ditto",true,false)
 var original=ui.find_child("RelicShortcut_great_wand",true,false)
 t.check(control!=null and original!=null and control.find_child("RelicCounter",true,false).text=="4" and original.find_child("RelicCounter",true,false).text=="2","DITTO UI two sources display distinct counters")
 var point=control.get_global_rect().get_center()
 await t.move_mouse(point)
 await t.mouse_button(point,MOUSE_BUTTON_RIGHT,true);await t.mouse_button(point,MOUSE_BUTTON_RIGHT,false);await t.frames()
 t.check(ui.game.state.mana==44 and ui.game.state.relic_counters.ditto==0 and ui.game.state.relic_counters.great_wand==2,"DITTO UI native right click exchanges only transformed wand progress")
 t.check(preload("res://ui/relic_icon.gd").ART.has("ditto") and ui.view.relics.filter(func(row):return row.id=="ditto")[0].icon=="great_wand","DITTO UI original and transformed art follow authoritative projection")
 ui.restart(42);await t.frames()
