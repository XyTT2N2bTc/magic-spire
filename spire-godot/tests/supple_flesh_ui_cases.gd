extends RefCounted
const Give=preload("res://tests/curse_cases.gd")
const Click=preload("res://tests/curse_ui_cases.gd")

static func run(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames();ui.game._discard_end();ui.game.state.energy=0
 var card=Give.give(ui.game,"supple_flesh");ui.render();await t.frames()
 var face=ui.card_buttons[card.uid]
 t.check(face.rarity=="uncommon" and face.ILLUSTRATIONS.has("supple_flesh") and face.get_node("CardCost").text=="0" and t.visible_text(face).contains("4点临时灵巧"),"SUPPLE UI shows uncommon zero-cost skill with first-face dexterity")
 await Click.click_card(t,card.uid);await t.frames()
 t.check(ui.view.statuses.any(func(row):return row.id=="power_supple_flesh_bound" and row.value=="灵巧＋4" and row.duration=="本回合结束"),"SUPPLE UI bound click presents actual temporary dexterity")
 card=Give.give(ui.game,"supple_flesh");ui.render();await t.frames();await t.flip(card.uid)
 t.check(t.visible_text(ui.card_buttons[card.uid]).contains("2点临时力量"),"SUPPLE UI actual flip shows temporary strength on free face")
 await Click.click_card(t,card.uid);await t.frames()
 t.check(ui.view.statuses.any(func(row):return row.id=="power_supple_flesh_free" and row.value=="力量＋2") and ui.game.state.energy==0 and ui.game.state.exhaust.is_empty(),"SUPPLE UI free click coexists without cost or exhaustion")
 for enemy in ui.game.state.enemies: enemy.intent.delayed=true
 ui.render();await t.frames();await t.click("end")
 t.check(not ui.view.statuses.any(func(row):return row.id.begins_with("power_supple_flesh_")),"SUPPLE UI actual turn end removes both statuses")
 ui.localization.set_locale("en_US")
 t.check(ui.localization.display("活动媚肉")=="Supple Flesh" and ui.localization.display("获得4点临时灵巧。")=="Gain 4 temporary Dexterity.","SUPPLE UI English card name and effect resolve")
 ui.localization.set_locale("zh_CN")
