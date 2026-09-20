extends RefCounted
const Cards=preload("res://tests/curse_cases.gd")
const Click=preload("res://tests/curse_ui_cases.gd")

static func run(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames();ui.game._discard_end();ui.game.state.energy=20
 var card=Cards.give(ui.game,"formation");ui.card_faces[card.uid]=false;ui.render();await t.frames()
 var face=ui.card_buttons[card.uid]
 t.check(face.rarity=="uncommon" and face.get_node("CardCost").text=="2" and face.ILLUSTRATIONS.has("formation") and t.visible_text(face).contains("必定成功"),"FORMATION UI uncommon two-cost bound face has dedicated art and guarantee text")
 await t.flip(card.uid)
 t.check(t.visible_text(ui.card_buttons[card.uid]).contains("能量－1") and t.visible_text(ui.card_buttons[card.uid]).contains("严密度≤1"),"FORMATION UI free face exposes discount and upper requirement")
 await Click.click_card(t,card.uid)
 t.check(ui.game.state.powers.any(func(x):return x.type=="formation" and x.power_face=="free") and ui.view.statuses.any(func(x):return x.id=="power_formation_free" and x.value.contains("－1")),"FORMATION UI real click activates immediately and shows available buff")
 card=Cards.give(ui.game,"ease");ui.card_faces[card.uid]=true;ui.render();await t.frames()
 t.check(ui.card_buttons[card.uid].get_node("CardCost").text=="0","FORMATION UI magic card cost updates immediately")
 await Click.click_card(t,card.uid)
 t.check(ui.view.statuses.any(func(x):return x.id=="power_formation_free" and x.value=="本回合已触发"),"FORMATION UI playing discounted card updates consumed status")
 card=Cards.give(ui.game,"formation");ui.card_faces[card.uid]=false;ui.render();await t.frames()
 await Click.click_card(t,card.uid)
 ui.game.state.pressure=75
 var spell=Cards.give(ui.game,"mana_surge");ui.card_faces[spell.uid]=false;ui.render();await t.frames()
 var entry=ui.view.hand.filter(func(x):return x.uid==spell.uid)[0]
 t.check(entry.face_casting.bound.percent=="100%" and entry.face_casting.bound.formula.contains("布阵"),"FORMATION UI card projection uses the same guaranteed chance as execution")
 await Click.click_card(t,spell.uid)
 t.check(not ui.game._magic_failed and ui.view.statuses.any(func(x):return x.id=="power_formation_bound" and x.value=="本回合已触发"),"FORMATION UI zero-cost spell actually consumes guaranteed buff")
 ui.localization.set_locale("en_US")
 t.check(ui.localization.display("布阵")=="Formation" and ui.localization.display("上身严密度≤1或腿部严密度≤1").contains("or leg") and ui.localization.display("必定成功剩余2张").contains("2"),"FORMATION UI English names, OR requirements and variable remaining counts use display localization")
 ui.localization.set_locale("zh_CN")
