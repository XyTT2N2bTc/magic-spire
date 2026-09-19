extends RefCounted
const Give=preload("res://tests/curse_cases.gd")
const Click=preload("res://tests/curse_ui_cases.gd")

static func run(t) -> void:
 var ui=t.ui
 ui.game=preload("res://tests/binding_search_cases.gd").setup()
 ui._reset_interface(ui.game.get_view())
 var card=Give.give(ui.game,"binding_search")
 ui.game.add_fixture("eyes",8);ui.game.add_fixture("wrist",8);ui.game.add_fixture("thigh",8)
 ui.card_faces[card.uid]=false;ui.render();await t.frames()
 var face=ui.card_buttons[card.uid]
 t.check(face.rarity=="uncommon" and face.get_node("CardCost").text=="1" and face.ILLUSTRATIONS.has("binding_search"),"BIND SEARCH UI uncommon one-cost card has dedicated art")
 t.check(t.visible_text(face).contains("抽1张牌（X＝3）") and t.visible_text(face).contains("施法：无"),"BIND SEARCH UI bound face displays live rounded count and no limb requirement")
 ui.game.add_fixture("calf",8);ui.render();await t.frames()
 t.check(t.visible_text(ui.card_buttons[card.uid]).contains("抽2张牌（X＝4）"),"BIND SEARCH UI current hand updates when another body area is equipped")
 await t.capture("ui-binding-search.png")
 await Click.click_card(t,card.uid)
 t.check(ui.view.hand.size()==2 and ui.view.energy==19 and ui.view.mana==90,"BIND SEARCH UI native bound play draws live amount through original submission")
 card=Give.give(ui.game,"binding_search");ui.card_faces[card.uid]=false;ui.render();await t.frames()
 await t.flip(card.uid)
 t.check(t.visible_text(ui.card_buttons[card.uid]).contains("紧度2的中级拘束具"),"BIND SEARCH UI flipping shows full free effect")
 var before=ui.game.state.equipment.size();var hand=ui.view.hand.size()
 await Click.click_card(t,card.uid)
 t.check(ui.game.state.equipment.size()==before+1 and ui.view.hand.size()==hand+2,"BIND SEARCH UI free play installs real equipment then draws three without another picker")
 ui.localization.set_locale("en_US")
 var english=ui.localization.display("抽2张牌（X＝4）。X为有拘束具的非性器部位数，结果向下取整。")
 t.check(ui.localization.display("紧缚检索")=="Binding Search" and english.contains("Draw 2 cards") and (english.contains("X＝4") or english.contains("X = 4")) and english.contains("round down"),"BIND SEARCH UI English dynamic copy preserves both values")
 ui.localization.set_locale("zh_CN")
