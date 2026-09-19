extends RefCounted
const Cards=preload("res://tests/curse_cases.gd")

static func run(t) -> void:
 var ui=t.ui
 for free in [false,true]:
  ui.restart(42);ui.game._discard_end();ui.game.state.mana=35
  var card=Cards.give(ui.game,"sympathetic_form");ui.render();await t.frames()
  if ui.card_faces.get(card.uid,false)!=free: await t.flip(card.uid)
  var face=ui.card_buttons[card.uid]
  t.check(face.rarity=="rare" and face.get_node("CardCost").text=="3" and face.get_node("CardIllustration").texture!=null and t.visible_text(face).contains("交感形态"),"SYMPATHETIC UI rare card cost and dedicated illustration")
  t.check(t.visible_text(face).contains("恢复20魔力" if free else "10点临时魔力与1能量"),"SYMPATHETIC UI selected face describes the registered turn trigger")
  await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid)
  t.check(ui.view.energy==0 and ui.view.mana==35 and ui.view.temporary_mana==0 and ui.view.powers.any(func(v):return v.uid==card.uid),"SYMPATHETIC UI real click activates power without immediate resource grant")
  for enemy in ui.game.state.enemies: enemy.intent.delayed=true
  ui.render();await t.frames()
  t.check(await t.click("end"),"SYMPATHETIC UI end turn uses original command")
  t.check(ui.view.mana==55 if free else ui.view.temporary_mana==10 and ui.view.energy==4,"SYMPATHETIC UI next turn projects actual mana or temporary mana and energy")
