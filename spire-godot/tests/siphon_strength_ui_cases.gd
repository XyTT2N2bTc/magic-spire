extends RefCounted
const Cards=preload("res://tests/curse_cases.gd")

static func run(t) -> void:
 var ui=t.ui
 for free in [false,true]:
  ui.restart(42);await t.frames();ui.game._discard_end();ui.game.state.mana=20
  var source=Cards.give(ui.game,"siphon_strength")
  var first=Cards.give(ui.game,"strain");var second=Cards.give(ui.game,"sensitive");var magic=Cards.give(ui.game,"ease")
  ui.render();await t.frames()
  if ui.card_faces.get(source.uid,false)!=free: await t.flip(source.uid)
  var face=ui.card_buttons[source.uid]
  t.check(face.rarity=="rare" and t.visible_text(face).contains("手部") and t.visible_text(face).contains("恢复10魔力" if free else "获得1层蓄力"),"SIPHON STRENGTH UI shows rare hand spell and complete per-card effect")
  t.check(face.ILLUSTRATIONS.has("siphon_strength"),"SIPHON STRENGTH UI uses dedicated illustration")
  await preload("res://tests/curse_ui_cases.gd").click_card(t,source.uid)
  t.check(not ui._selecting_hand() and ui.find_child("HandSelectionBar",true,false)==null and ui.find_child("HandTargetPicker",true,false)==null,"SIPHON STRENGTH UI one click resolves without any hand picker")
  var removed=[magic.uid] if free else [first.uid,second.uid]
  var kept=[first.uid,second.uid] if free else [magic.uid]
  t.check(ui.game.state.exhaust.map(func(card):return card.uid)==removed and ui.game.state.hand.map(func(card):return card.uid)==kept,"SIPHON STRENGTH UI automatically exhausts magic on free and nonmagic on bound")
  t.check(ui.game.state.energy==2 and ui.game.state.mana==(30 if free else 20) and ui.game.state.charge==(0 if free else 2),"SIPHON STRENGTH UI grants correct resource per exhausted card immediately")
  t.check(ui.card_motion.get_children().filter(func(node):return node.name.begins_with("CardMotion_exhaust_")).size()==removed.size(),"SIPHON STRENGTH UI creates one visible exhaustion animation for each selected card")
