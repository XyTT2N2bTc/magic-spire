extends RefCounted
const Cards=preload("res://tests/curse_cases.gd")
const Click=preload("res://tests/curse_ui_cases.gd")

static func run(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames();ui.game._discard_end();ui.game.state.energy=20
 for slot in ui.game.B.SLOTS.slice(0,5): ui.game.add_fixture(slot,8)
 var card=Cards.give(ui.game,"binding_power");ui.render();await t.frames()
 var face=ui.card_buttons[card.uid];var text=t.visible_text(face)
 t.check(face.rarity=="common" and face.ILLUSTRATIONS.has("binding_power") and face.get_node("CardCost").text=="1" and text.contains("消耗") and text.contains("拘束1") and text.contains("力量＋2") and text.contains("直到你的下回合结束前"),"BIND POWER UI displays common art cost exhaust and first bound live gain")
 await Click.click_card(t,card.uid);await t.frames()
 t.check(ui.game.RelicEffects.attribute(ui.game,"strength")==2 and ui.game.state.exhaust.any(func(item):return item.uid==card.uid),"BIND POWER UI first face click grants temporary strength and exhausts")
 card=Cards.give(ui.game,"binding_power");ui.render();await t.frames();await t.flip(card.uid)
 text=t.visible_text(ui.card_buttons[card.uid])
 t.check(text.contains("拘束2") and not text.contains("自由") and text.contains("获得1层蓄力"),"BIND POWER UI actual flip shows second bound face and rounded charge")
 await Click.click_card(t,card.uid);await t.frames()
 t.check(ui.game.state.charge==1 and ui.game.state.energy==18 and ui.game.state.exhaust.any(func(item):return item.uid==card.uid),"BIND POWER UI second face click pays once and grants charge")
 ui.localization.set_locale("en_US")
 t.check(ui.localization.display("拘束就是力量！")=="Restraint Is Power!" and ui.localization.display(ui.game.Cards.face_text(ui.game,"binding_power",true)).contains("Charge"),"BIND POWER UI English name and dynamic second-face effect resolve")
 ui.localization.set_locale("zh_CN")
