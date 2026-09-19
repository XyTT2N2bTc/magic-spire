extends RefCounted

static func run(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames()
 ui.game.state.relics=["edging_seal","magic_blood"];ui.game.state.pressure=98
 for enemy in ui.game.state.enemies: enemy.intent.delayed=true
 ui.render();await t.frames()
 var icon=ui.find_child("RelicShortcut_edging_seal",true,false)
 t.check(icon!=null and icon.find_child("RelicCounter",true,false).text=="1" and preload("res://ui/relic_icon.gd").ART.has("edging_seal"),"SEAL UI original icon and available use visible")
 await t.move_mouse(icon.get_global_rect().get_center());await t.frames()
 t.check(ui.term_popup!=null and t.visible_text(ui.term_popup).contains("绿色小鸟优先生效"),"SEAL UI hover explains priority and shared preparation use")
 t.check(await t.click("end") and ui.game.state.charge==3 and not ui.game.state.overloaded,"SEAL UI actual end-turn input triggers numeric protection")
 icon=ui.find_child("RelicShortcut_edging_seal",true,false)
 t.check(icon.find_child("RelicCounter",true,false).text=="0","SEAL UI spent-use counter refreshes after real action")
 await t.move_mouse(icon.get_global_rect().get_center());await t.frames()
 t.check(t.visible_text(ui.term_popup).contains("本场已触发"),"SEAL UI tooltip exposes spent use")
 ui.localization.set_locale("en_US")
 t.check(ui.localization.display("寸止钢印")=="Threshold Seal" and ui.localization.display("：快感100 → 50，获得3层蓄力。").contains("gain 3 Charge"),"SEAL UI English static and dynamic text retain numeric values")
 ui.localization.set_locale("zh_CN")
