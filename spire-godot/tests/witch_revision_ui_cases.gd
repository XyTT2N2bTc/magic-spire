extends RefCounted
const Base=preload("res://tests/witch_expansion_cases.gd")
const Give=preload("res://tests/curse_cases.gd")
const Click=preload("res://tests/curse_ui_cases.gd")

static func run(t) -> void:
 var ui=t.ui
 ui.selected_character="witch";ui.restart(42);await t.frames()
 ui.game=Base.fresh();ui.game._discard_end();ui.attack_forms.clear();ui.render();await t.frames()
 var tile=ui.find_child("BasicAttack_witch_hand",true,false)
 var meta=tile.find_child("BasicAttackMeta",true,false).text
 t.check(tile.find_child("BasicAttackTitle",true,false).text=="手部施法" and meta.contains("1能量") and meta.contains("5魔力") and meta.contains("100%") and not meta.contains("当前") and not meta.contains("手部"),"WITCH REV UI compact action title and explicit real energy mana chance")
 var card=Give.give(ui.game,"witch_escape_practice");card.practice_plays=6
 for permanent in ui.game.state.deck:
  if permanent.uid==card.uid: permanent.practice_plays=6
 ui.render();await t.frames();await t.close_information();await t.move_mouse(Vector2(30,90));await t.move_mouse(t.card_point(card.uid));await t.frames()
 var hover_text=t.visible_text(ui.term_popup) if ui.term_popup!=null else "missing tooltip"
 t.check(ui.term_popup!=null and hover_text.contains("6／7次") and hover_text.contains("再使用1次升级"),"WITCH REV UI mouse hover always shows training instance upgrade progress: "+hover_text)
 await t.flip(card.uid);await t.move_mouse(t.card_point(card.uid));await t.frames()
 t.check(t.visible_text(ui.term_popup).contains("6／7次"),"WITCH REV UI both bound faces share hover progress: "+t.visible_text(ui.term_popup))
 ui.game._discard_end();card=Give.give(ui.game,"witch_binding_lure")
 ui.render();await t.frames()
 if not ui.card_buttons[card.uid].free_face: await t.flip(card.uid)
 await Click.click_card(t,card.uid);await t.frames()
 t.check("witch_induction_hand" in ui.game.state.card_buffs and ui.view.statuses.any(func(s):return s.id=="power_witch_induction_hand" and s.duration=="下回合开始"),"WITCH REV UI second bound face plays and shows next-start protection: "+str(ui.game.state.card_buffs))
 card=Give.give(ui.game,"witch_authority");ui.card_faces[card.uid]=true
 ui.render();await t.frames();await Click.click_card(t,card.uid);await t.frames()
 var button=ui.find_child("EndTurnButton",true,false)
 t.check(button.disabled and button.find_child("EndTurnLockPattern",true,false)!=null,"WITCH REV UI authority action adds lock artwork and disables ending")
 var before=ui.game.export_snapshot();var point=button.get_global_rect().get_center()
 await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)
 t.check(ui.game.state==before,"WITCH REV UI clicking decorated locked end button cannot advance turn")
 ui.game=preload("res://tests/game_fixture.gd").new(42,true,"prison_test",true,false,25,false,false,"witch");ui.render();await t.frames()
 t.check(ui.find_child("BasicAttack_fireball",true,false)==null and ui.find_child("DeepBreath",true,false)!=null,"WITCH REV UI prison removes original fireball placeholder and keeps applicable actions")
 ui.localization.set_locale("en_US")
 t.check(ui.localization.display("升级进度：6／7次；再使用1次升级。").contains("6/7") and ui.localization.display("拘束诱导")=="Binding Lure","WITCH REV UI translated progress and new card name")
 ui.localization.set_locale("zh_CN")
