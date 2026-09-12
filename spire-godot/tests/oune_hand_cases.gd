extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Give=preload("res://tests/curse_cases.gd")
const RELIC="oune_hand"
const GIFT="magic_hand_gift"

static func run(t) -> void:
 var g=Game.new(42);var excluded=g.Relics.REWARDS.filter(func(id):return id!=RELIC)
 t.check(g.Relics.TYPES[RELIC].rarity=="uncommon" and preload("res://tests/rolling_log_cases.gd").offer_tier(g,"uncommon",excluded)==RELIC,"OUNE uncommon relic participates in the shared random pool")
 var gift_spec=g.Cards.Rules.SPECS[GIFT].duplicate(true);gift_spec.erase("reward_excluded");gift_spec.erase("encyclopedia_hidden")
 t.check(g.Cards.Rules.SPECS[GIFT].get("encyclopedia_hidden",false),"OUNE gift is grouped under its original encyclopedia card")
 t.check(gift_spec==g.Cards.Rules.SPECS.magic_hand and GIFT not in g.Cards.Rules.REWARDS and not g.B.CARD_TRAITS.get(GIFT,{}).get("exhaust",false) and g.B.CARD_TRAITS.magic_hand.exhaust,"OUNE gift shares exact card effects but only normal magic hand enters random rewards and exhausts")
 var original=Give.give(g,"magic_hand");var before=g.export_snapshot()
 g.RelicEffects.gain(g,RELIC)
 var gift=g.state.discard.filter(func(c):return c.type==GIFT)[0]
 t.check(g.state.deck.size()==before.deck.size()+1 and g.state.deck.any(func(c):return c.uid==gift.uid and c.type==GIFT) and g.state.hand.any(func(c):return c.uid==original.uid and c.type=="magic_hand") and g.state.energy==before.energy and g.state.mana==before.mana,"OUNE pickup adds one permanent reusable copy to discard without changing old cards or resources")
 before=g.export_snapshot();g.RelicEffects.gain(g,RELIC)
 t.check(g.state==before,"OUNE repeated pickup is rejected without duplicating the gift")
 t.check(g.state.logs.any(func(e):return e.text.contains("魔术手") and e.text.contains("正常弃置")),"OUNE pickup log clearly identifies the non-exhausting gift")
 var restored=preload("res://tests/persistence_cases.gd").roundtrip(t,g,"reusable magic hand from relic")
 t.check(restored!=null and restored.state.deck.any(func(c):return c.uid==gift.uid and c.type==GIFT),"OUNE existing snapshot retains gifted card identity")
 for free in [false,true]:
  g=Game.new(42);g._discard_end();g.RelicEffects.gain(g,RELIC)
  gift=g.state.discard.filter(func(c):return c.type==GIFT)[0]
  g.state.discard.erase(gift);g.state.hand.append(gift)
  var target=g.add_fixture("wrist",10)
  var result=t.action(g,"card",{"uid":gift.uid,"free":free})
  t.check(result.ok and g.state.energy==2 and g.state.mana==80 and g.state.discard.any(func(c):return c.uid==gift.uid) and not g.state.exhaust.any(func(c):return c.uid==gift.uid),"OUNE both gift faces pay unchanged costs and discard normally")
  t.check((g.state.card_buff_uses.get("magic_hand_free")==2 if free else g._equipment(target.id).is_empty()) and result.card_feedback.any(func(e):return e.kind=="play" and e.uid==gift.uid),"OUNE gift executes actual free-state attacks or super-follow loosening and uses normal play animation")
  g.state.discard.erase(gift);g.state.hand.append(gift)
  t.check(t.action(g,"card",{"uid":gift.uid,"free":true}).ok and g.state.discard.any(func(c):return c.uid==gift.uid),"OUNE gifted card remains playable after returning to hand")
  g._start_battle()
  t.check(g.state.deck.any(func(c):return c.uid==gift.uid and c.type==GIFT) and (g.state.hand+g.state.draw+g.state.discard).any(func(c):return c.uid==gift.uid and c.type==GIFT) and g.Cards.validate(g)=="","OUNE new battle preserves reusable variant through normal deck rebuild")
 var book=preload("res://data/encyclopedia.gd").card(GIFT)
 t.check(book.name=="魔术手" and not book.bound.contains("消耗") and not book.free.contains("消耗") and book.note.contains("欧内的手") and book.face_keywords.bound.all(func(term):return term.name!="消耗"),"OUNE card and encyclopedia omit exhaust keyword and identify relic source")
