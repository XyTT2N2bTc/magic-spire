extends RefCounted
const Game=preload("res://tests/game_fixture.gd")

static func run(t) -> void:
 magnifying_glass(t)
 skip_rewards(t)
 for order in [["card","item","relic"],["relic","card","item"],["item","relic","card"]]:
  var g=Game.new(78)
  g.state.room_encounters[g.state.room]="guard_solo"
  g.state.item_drop_chance=100
  var deck=g.state.deck.size();var items=g.state.items.size();var relics=g.state.relics.size()
  g._finish_battle()
  var offered=g.state.reward_options.duplicate();var rng=g.state.rng.duplicate()
  t.check(g.state.phase=="reward" and g.state.deck.size()==deck and g.state.items.size()==items and g.state.relics.size()==relics,"LOOT battle freezes rewards without granting them")
  var pending_save=preload("res://tests/persistence_cases.gd").roundtrip(t,g,"pending battle relic reward")
  t.check(pending_save!=null and pending_save.state.battle_relic_drop==g.state.battle_relic_drop,"LOOT pending unclaimed relic survives save validation")
  t.check(g.get_view().battle_rewards.size()==3 and g.get_view().battle_rewards.all(func(row):return not row.claimed),"LOOT all pending categories have a real reward projection")
  for category in order:
   var pick=t.find_action(g,"reward",{"category":category})
   var version=g.state.version
   t.check(g.dispatch(pick.id,version).ok and g.state.phase=="reward" and g.state.reward_claimed[category]==pick.payload.type,"LOOT independent pickup stays on reward screen "+category)
   var after=g.export_snapshot()
   t.check(not g.dispatch(pick.id,version).ok and not t.action(g,"reward",{"category":category}).ok and g.state==after,"LOOT stale and duplicate pickup cannot grant another reward "+category)
   t.check(g.get_view().battle_rewards.filter(func(row):return row.category==category)[0].claimed and g.state.rng==rng and g.state.reward_options==offered,"LOOT claimed projection and frozen random result "+category)
  t.check(g.state.deck.size()==deck+1 and g.state.items.size()==items+1 and g.state.relics.size()==relics+1,"LOOT all categories grant exactly once in either order")
  t.check(t.action(g,"reward",{"type":"skip"}).ok and g.state.phase=="prepare" and g.get_view().battle_rewards.is_empty(),"LOOT continue enters preparation only after acknowledgement")
  g.state.phase="battle";g._finish_battle()
  t.check(g.state.reward_claimed.is_empty() and g.get_view().battle_rewards.all(func(row):return not row.claimed),"LOOT next battle resets claim state")
 var g=Game.new(78);g.state.item_drop_chance=100;g.state.room_encounters[g.state.room]="guard_solo"
 var deck=g.state.deck.size();var items=g.state.items.duplicate(true);var relics=g.state.relics.duplicate()
 g._finish_battle()
 var dropped=g.state.battle_item_drop;var relic=g.state.battle_relic_drop
 t.check(t.action(g,"reward",{"type":"skip"}).ok and g.state.deck.size()==deck and g.state.items==items and g.state.relics==relics,"LOOT continue forfeits every unclaimed reward")
 t.check(not t.action(g,"reward",{"category":"item","type":dropped}).ok and not t.action(g,"reward",{"category":"relic","type":relic}).ok,"LOOT cannot collect a reward after leaving")

static func skip_rewards(t) -> void:
 for boss in [false,true]:
  var g=Game.new(78)
  if boss:
   g.state.room="summit";g._start_battle();g._finish_battle()
  else:
   g.state.room_encounters[g.state.room]="guard_solo";g.state.item_drop_chance=100;g._finish_battle()
  var before=g.export_snapshot()
  for category in ["card","relic"]:
   var skip=t.find_action(g,"reward_skip",{"category":category})
   var preview=g.export_snapshot();var panel=g.get_view().reward_panel
   t.check(panel.active and panel.rows.any(func(row):return row.category==category and row.skip_id==skip.id) and g.state==preview,"SKIP reward projection exposes the formal per-category skip without mutation")
   t.check(g.dispatch(skip.id,g.state.version).ok and g.state.phase=="reward" and g.state.reward_claimed[category]=="skip","SKIP settles one category without leaving the reward screen")
   var settled=g.export_snapshot()
   t.check(not g.dispatch(skip.id,g.state.version-1).ok and not t.action(g,"reward_skip",{"category":category}).ok and not t.action(g,"reward",{"category":category}).ok and g.state==settled,"SKIP stale, repeated and later claims reject atomically")
   var restored=Game.new(2)
   t.check(restored.restore_snapshot(settled).ok and restored.state.reward_claimed==g.state.reward_claimed and restored.get_view().battle_rewards.any(func(row):return row.category==category and row.skipped),"SKIP current snapshots preserve skipped cards and normal or Boss relics")
  t.check(g.state.deck==before.deck and g.state.relics==before.relics and g.state.items==before.items and g.state.mana==before.mana and g.state.flask_mana==before.flask_mana and g.state.rng==before.rng and g.state.tick==before.tick,"SKIP no cards, relic effects, costs, random draws or turns are granted")
  if not boss: t.check(t.action(g,"reward",{"category":"item"}).ok,"SKIP remaining item reward can still be claimed")
  t.check(t.action(g,"reward",{"type":"skip"}).ok and g.state.phase=="prepare","SKIP continue still enters ordinary preparation")
 var rest=Game.new(42);rest.state.room="rest";rest._start_rest()
 var panel=rest.get_view().reward_panel;var deck=rest.state.deck.duplicate(true)
 t.check(panel.active and panel.rows.size()==3 and panel.rows[0].action_ids.size()==3 and panel.rows.slice(1).all(func(row):return row.action_ids.size()==1 and row.direct) and panel.extra_ids.is_empty() and t.action(rest,"rest_begin").ok and rest.state.rest_left==rest.B.REST_TURNS and rest.state.deck==deck,"SKIP rest uses three common reward rows and keeps all rest turns when declining")

static func magnifying_glass(t) -> void:
 var Save=preload("res://tests/persistence_cases.gd")
 var g=Game.new(78)
 g.state.room_encounters[g.state.room]="guard_solo";g._finish_battle()
 g.state.battle_relic_drop="magnifying_glass"
 if "magnifying_glass" not in g.state.relic_seen: g.state.relic_seen.append("magnifying_glass")
 var offered=g.state.reward_options.duplicate();var random=g.state.rng.duplicate(true)
 var pickup=t.find_action(g,"reward",{"category":"relic"})
 var version=g.state.version
 t.check(g.dispatch(pickup.id,version).ok and "magnifying_glass" in g.state.relics,"LENS formal rare relic pickup succeeds")
 t.check(offered.size()==3 and g.state.reward_options==offered and g.state.rng==random,"LENS same window keeps its three frozen cards without drawing random numbers")
 var snapshot=g.export_snapshot()
 t.check(not g.dispatch(pickup.id,version).ok and g.state==snapshot,"LENS stale pickup rejects without changing rewards")
 Save.roundtrip(t,g,"lens acquired after three-card reward froze")
 var count=g.state.deck.size()
 t.check(t.action(g,"reward",{"category":"card","type":offered[-1]}).ok and g.state.deck.size()==count+1 and g.state.deck[-1].type==offered[-1],"LENS original choices still grant exactly the selected card")
 for source in ["normal","elite","boss"]:
  for seed_value in range(32):
   var a=Game.new(seed_value);var b=Game.new(seed_value)
   a.RelicEffects.gain(a,"magnifying_glass");b.RelicEffects.gain(b,"magnifying_glass")
   var before=a.state.rng.duplicate(true)
   var choices=a.reward_offer(a.Cards.Rules.REWARDS,source)
   t.check(choices.size()==4 and choices.all(func(id):return choices.count(id)==1) and choices==b.reward_offer(b.Cards.Rules.REWARDS,source),"LENS four unique reproducible choices: "+source)
   t.check(a.state.rng.deck==before.deck and a.state.rng.enemy==before.enemy and a.state.rng.relic==before.relic,"LENS extra choice only uses reward random domain")
   if source=="boss": t.check(choices.all(func(id):return a.Cards.Rules.SPECS[id].rarity=="rare"),"LENS Boss fourth card stays rare")
 g=Game.new(42);g.RelicEffects.gain(g,"magnifying_glass");g._finish_battle()
 t.check(g.state.reward_options.size()==4 and g.get_view().reward_panel.rows.filter(func(row):return row.category=="card")[0].action_ids.size()==4,"LENS actual battle finish exposes four formal candidates")
 Save.roundtrip(t,g,"lens four-card battle reward")
 for rarity in ["uncommon"]:
  g=Game.new(42);g.RelicEffects.gain(g,"magnifying_glass");g.state.room="rest";g._start_rest()
  var cards=g.state.rest_cards.filter(func(id):return g.Cards.Rules.SPECS[id].rarity==rarity)
  t.check(g.state.rest_cards.size()==4 and cards.size()==4 and g.get_view().reward_panel.rows.filter(func(row):return row.id=="uncommon")[0].action_ids.size()==4,"LENS rest freezes four uncommon choices")
  Save.roundtrip(t,g,"lens rest "+rarity)
  random=g.state.rng.duplicate(true);count=g.state.deck.size()
  t.check(t.action(g,"rest_card",{"type":cards[-1]}).ok and g.state.deck.size()==count+1 and g.state.deck[-1].type==cards[-1] and g.state.rest_left==g.B.REST_TURNS-g.B.REST_CARD_TURNS[rarity] and g.state.rng==random,"LENS fourth rest choice preserves original fee and does not reroll")
 g=Game.new(42);g.RelicEffects.gain(g,"magnifying_glass");g.state.room="rest";g._start_rest()
 count=g.state.deck.size()
 t.check(t.action(g,"rest_rare").ok and g.state.deck.size()==count+1 and g.Cards.Rules.SPECS[g.state.deck[-1].type].rarity=="rare" and g.state.rest_left==3,"LENS random rare still grants exactly one card for three turns")
 g=Game.new(42);g.RelicEffects.gain(g,"magnifying_glass")
 preload("res://tests/event_cases.gd").arrive(g,"succubus_magic_pawnshop")
 t.check(t.action(g,"event",{"action":"choose","choice":"small_trade"}).ok and g.state.room_event.stage=="reward" and g.state.room_event.reward.size()==4,"LENS actual event choice generates four reward cards")
 var fourth=g.state.room_event.reward[-1];count=g.state.deck.size()
 t.check(t.action(g,"event",{"action":"reward","type":fourth}).ok and g.state.deck.size()==count+1 and g.state.deck[-1].type==fourth,"LENS fourth event card uses original claim transaction")
 var shop=Game.new(42);var baseline=Game.new(42)
 shop.RelicEffects.gain(shop,"magnifying_glass")
 for game in [shop,baseline]:
  game.state.room=game.state.rooms.filter(func(room):return room.kind=="shop")[0].id
  game.Services.start(game)
 var stock=shop.room_data(shop.state.room).stock.filter(func(row):return row.kind=="card")
 t.check(stock.size()==5 and stock==baseline.room_data(baseline.state.room).stock.filter(func(row):return row.kind=="card"),"LENS shop explicit 2/2/1 card stock is unchanged")
 t.check("magnifying_glass" in g.Relics.REWARDS and "magnifying_glass" in g.Relics.shop_pool() and g.Relics.TYPES.magnifying_glass.rarity=="rare","LENS participates in rare reward and shop pools")
