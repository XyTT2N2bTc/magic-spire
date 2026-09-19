extends RefCounted
const Cards=preload("res://tests/curse_cases.gd")
const Click=preload("res://tests/curse_ui_cases.gd")

static func run(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames();ui.game._discard_end();ui.game.state.energy=20
 var card=Cards.give(ui.game,"kip_up");ui.card_faces[card.uid]=false;ui.render();await t.frames()
 var face=ui.card_buttons[card.uid]
 t.check(face.rarity=="common" and face.ILLUSTRATIONS.has("kip_up") and face.get_node("CardCost").text=="1","KIP UI common skill has dedicated art and base energy cost")
 t.check(t.visible_text(face).contains("保留") and t.visible_text(face).contains("躺姿限定") and t.visible_text(face).contains("力量≥4"),"KIP UI shows retention, pose condition and conditional cost without removing rules")
 ui.game.state.strength=4;ui.game.state.posture="lie";ui.render();await t.frames()
 t.check(ui.card_buttons[card.uid].get_node("CardCost").text=="0","KIP UI strength threshold updates the real bound cost")
 await Click.click_card(t,card.uid)
 t.check(ui.view.posture=="stand" and not ui.card_buttons.has(card.uid),"KIP UI clicking bound face stands up and removes played card")
 card=Cards.give(ui.game,"kip_up");ui.game.state.strength=3;ui.game.state.posture="lie";ui.render();await t.frames()
 await t.flip(card.uid)
 t.check(ui.card_buttons[card.uid].get_node("CardCost").text=="1" and t.visible_text(ui.card_buttons[card.uid]).contains("无视姿势"),"KIP UI reduced strength restores one cost with complete free-face effect")
 await Click.click_card(t,card.uid)
 t.check(ui.view.posture=="lie" and ui.view.statuses.any(func(s):return s.id=="power_kip_up_free" and s.active),"KIP UI free play shows actual pending buff without changing posture")
 ui.attack_forms.kick=1;ui.render();await t.frames()
 await t.drag_control_to(t.action_button("kick"),ui.view.enemies[0].id)
 t.check(not ui.view.statuses.any(func(s):return s.id=="power_kip_up_free" and s.active),"KIP UI real leg attack consumes and removes status")
 ui.localization.set_locale("en_US")
 t.check(ui.localization.display("鲤鱼打挺")=="Kip Up" and ui.localization.display("躺姿限定")=="Lying down only","KIP UI card name and posture condition have English copy")
 ui.localization.set_locale("zh_CN")
