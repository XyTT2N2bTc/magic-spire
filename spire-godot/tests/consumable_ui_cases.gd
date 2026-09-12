extends RefCounted

static func body_group_item(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames()
 ui.game._gain_tool("lubricant_potion")
 var id=ui.game.state.items.back().id
 ui.selected_item=id;ui.render();ui._open_drawer("show_items");await t.frames()
 var state=ui.game.export_snapshot()
 t.check(ui.view.items.filter(func(item):return item.id==id)[0].target_groups.size()==14,"OIL UI projects all fourteen sidebar groups including empty ones")
 t.check(t.visible_text(ui.layout).contains("润滑油") and t.visible_text(ui.layout).contains("不受口部减效影响") and t.visible_text(ui.layout).contains("剩余3次"),"OIL UI shows charges and physical/mouth exemptions")
 await t.capture("ui-lubricant-groups.png")
 await preload("res://tests/interface_ui_cases.gd").press(t,"ToolSlot_hands");await t.frames()
 t.check(ui.game.state.version==state.version+1 and ui.game._item(id).uses==2 and ui.game.state.body_buffs==[{"type":"lubricant_potion","group":"hands"}],"OIL UI single body-group click submits once without equipment selection")
 t.check(ui.view.statuses.any(func(s):return s.id=="body_buff_lubricant_potion_hands" and s.value=="滑脱×2"),"OIL UI status exposes actual coated group and multiplier")
 ui._close_drawers();ui.render();ui._open_drawer("show_items");await t.frames()
 t.check(t.visible_text(ui.layout).contains("剩余2次"),"OIL UI reopening uses current remaining charges")

static func run(t) -> void:
 await body_group_item(t)
 await preload("res://tests/mana_flask_ui_cases.gd").run(t)
 var ui=t.ui
 ui.restart(42);await t.frames()
 ui.game.state.mana=70
 ui.game._gain_tool("mana_potion")
 var id=ui.game.state.items.back().id
 ui.selected_item=id;ui.render();ui._open_drawer("show_items");await t.frames()
 t.check(t.visible_text(ui.layout).contains("药剂") and t.visible_text(ui.layout).contains("恢复20魔力"),"ITEM UI shows category and actual potion effect")
 t.check(await t.click("item_use",{"item":id}) and ui.game.state.mana==90 and ui.game._item(id).is_empty(),"ITEM UI direct use consumes actual potion and restores mana")
 ui.game._gain_tool("casting_scroll");id=ui.game.state.items.back().id
 ui.selected_item=id;ui.render();await t.frames()
 t.check(await t.click("item_use",{"item":id}) and ui.view.statuses.any(func(s):return s.id=="sure_cast"),"ITEM UI scroll exposes actual guarantee status")
 var navigation=preload("res://tests/interface_ui_cases.gd")
 await navigation.press(t,"OpenStatus")
 await navigation.press(t,"StatusFilter_benefit")
 t.check(ui.find_child("Status_sure_cast",true,false)!=null,"ITEM UI guarantee appears in the actual benefit filter")
 await navigation.press(t,"OpenItems")
 ui.game._gain_tool("draw_scroll");id=ui.game.state.items.back().id
 ui.game.add_fixture("fingers",8);ui.game.add_fixture("toes",8)
 ui.selected_item=id;ui.render();await t.frames()
 t.check(t.visible_text(ui.layout).contains("手指和脚趾均被拘束"),"ITEM UI unavailable scroll shows concrete reason")
 ui.game.RelicEffects.gain(ui.game,"tentacle_friend");ui.render();await t.frames()
 t.check(t.visible_text(ui.layout).contains("触手朋友协助展开") and not t.visible_text(ui.layout).contains("手指和脚趾均被拘束"),"FRIEND UI explanation follows overridden scroll permission")
 t.check(await t.click("item_use",{"item":id}) and ui.game._item(id).is_empty(),"FRIEND UI real scroll click works with bound fingers and toes")
 ui.game._gain_tool("shard");id=ui.game.state.items.back().id
 ui.selected_item=id;ui.render();await t.frames()
 t.check(t.visible_text(ui.layout).contains("触手固定") and t.visible_text(ui.layout).contains("全身") and ui.find_child("InstalledTool_"+id,true,false)!=null,"FRIEND UI carried cutter displays full-body fixed passive")
 await t.capture("ui-consumable-items.png")
 ui.game.state.item_drop_chance=100
 ui.game._finish_battle();ui._close_drawers();ui.render();await t.frames()
 t.check(ui.find_child("BattleItemDrop",true,false)!=null and t.visible_text(ui.layout).contains(ui.view.battle_item_drop),"DROP UI reward shows frozen item name")
 await t.capture("ui-item-drop-reward.png")
