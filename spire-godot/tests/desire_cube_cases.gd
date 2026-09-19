extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Opening=preload("res://core/game.gd")
const TYPE="desire_cube_pro_max"

static func run(t) -> void:
 opening(t)
 curve(t)
 lifecycle(t)
 pool(t)

static func opening(t) -> void:
 for role in ["original"]:
  var g=Opening.new(42,false,"equipment",true,false,25,false,false,role)
  var initial=g.Departure.initial_relic(g)
  var before=g.export_snapshot()
  var choice=t.find_action(g,"departure",{"op":"choose","option":TYPE})
  g.get_view();g.candidates()
  t.check(g.export_snapshot()==before,"DESIRE opening previews preserve resources and RNG: "+role)
  t.check(g.dispatch(choice.id,g.state.version).ok and initial not in g.state.relics and TYPE in g.state.relics and g.state.pressure==50,"DESIRE fifth option replaces the correct starter and grants fifty once: "+role)
  before=g.export_snapshot();g.RelicEffects.gain(g,TYPE)
  t.check(not g.dispatch(choice.id,g.state.version).ok and g.export_snapshot()==before,"DESIRE duplicate pickup and repeated choice cannot grant pressure: "+role)
  var restored=Opening.new(9)
  t.check(restored.restore_snapshot(before).ok and restored.state.pressure==50 and TYPE in restored.state.relics,"DESIRE save restores ownership without replaying pickup: "+role)
  t.check(TYPE not in g.Relics.REWARDS and TYPE not in g.Relics.BOSS_POOL and TYPE not in g.Relics.shop_pool() and not g.Relics.transformable(TYPE),"DESIRE remains starter-only: "+role)
 var witch=Opening.new(42,false,"equipment",true,false,25,false,false,"witch")
 var witch_before=witch.export_snapshot()
 witch.RelicEffects.gain(witch,TYPE)
 t.check(witch.state.departure.options.size()==4 and witch.state.departure.options.all(func(entry):return entry.id!=TYPE) and not t.action(witch,"departure",{"op":"choose","option":TYPE}).ok and witch.export_snapshot()==witch_before,"DESIRE witch keeps four choices and cannot acquire or exchange the original-only relic")
 var book=preload("res://data/encyclopedia.gd")
 t.check(not book.entries(witch,"witch").any(func(entry):return entry.id==TYPE) and book.entries(witch,"original").any(func(entry):return entry.id==TYPE),"DESIRE encyclopedia role selector hides the relic from witch only")
 var legacy=Opening.new(42).export_snapshot();legacy.departure.options.pop_back();legacy.relic_seen.erase(TYPE)
 var restored=Opening.new(9)
 t.check(restored.restore_snapshot(legacy).ok and restored.get_view().reward_panel.destination.contains("四选一"),"DESIRE old four-option opening snapshot still restores")
 var blocked=Opening.new(42);blocked.state.relics.clear();var before=blocked.export_snapshot()
 t.check(not t.action(blocked,"departure",{"op":"choose","option":TYPE}).ok and blocked.export_snapshot()==before,"DESIRE missing initial relic rejects exchange atomically")

static func curve(t) -> void:
 for limit in [75.0,100.0,130.0]:
  for row in [[0.0,0.0],[0.25,0.5],[0.5,1.0],[0.75,0.5],[1.0,0.0]]:
   t.check(is_equal_approx(Game.Pressure.cast_chance(limit*row[0],limit,true),row[1]),"DESIRE normalized curve matches exact anchor "+str(row)+" at cap "+str(limit))
  var previous=-1.0
  for i in range(51):
   var p=i/100.0;var chance=Game.Pressure.cast_chance(limit*p,limit,true)
   t.check(chance>=previous and chance>=0 and chance<=1 and is_equal_approx(chance,Game.Pressure.cast_chance(limit*(1-p),limit,true)),"DESIRE curve rises smoothly and mirrors its falling half")
   previous=chance
 var g=Game.new(42);g.state.relics=[TYPE];g.state.pressure=25
 t.check(is_equal_approx(g.cast_view({"parts":["mouth"]}).chance,0.5),"DESIRE real mouth projection consumes the new curve")
 var gag=g.add_fixture("mouth",4,10,false,1)
 var cast=g.cast_view({"parts":["mouth"]})
 t.check(cast.chance<0.5 and cast.base==0.5 and not cast.factors.is_empty(),"DESIRE mouth restraint factors still multiply after pressure curve")
 gag.durability=0;g._cleanup();g.state.pressure=0
 t.check(g.cast_view({"parts":["hand"]}).chance==0,"DESIRE pressure zero no longer guarantees casting")
 g.state.relics=[]
 t.check(g.cast_view({"parts":["hand"]}).chance==1 and Game.Pressure.cast_chance(25)==1,"DESIRE absent relic and unrelated default-curve callers preserve ordinary rules")
 for pressure in [0,50]:
  g=Game.new(42);g.state.relics=[TYPE];g.state.pressure=pressure
  var target=g.add_fixture("wrist",8);var card=t.hand_card(g,"ease")
  if pressure==0:
   var before=g.export_snapshot()
   t.check(not t.action(g,"card",{"uid":card.uid,"target":target.id}).ok and g.export_snapshot()==before,"DESIRE zero chance preserves existing unusable-cast guard without payment or RNG")
   continue
  t.check(t.action(g,"card",{"uid":card.uid,"target":target.id}).ok,"DESIRE spell passes through formal dispatch")
  var spell=g.state.logs.filter(func(log):return log.data.has("spell")).back().data.spell
  t.check(spell.success==(pressure==50) and g.state.rng.magic==0,"DESIRE guaranteed endpoint failure and peak success use actual casting")

static func lifecycle(t) -> void:
 var g=Game.new(79);g.state.relics=[TYPE];g.state.pressure=40
 g._finish_battle()
 t.check(g.state.pressure==40 and g.state.combat.active,"DESIRE reward stage preserves existing battle-end settlement timing")
 t.action(g,"reward",{"type":"skip"});g.state.pressure=40
 t.check(t.action(g,"finish_prepare").ok and g.state.pressure==50 and not g.state.combat.active,"DESIRE battle session closes with ten pressure through normal preparation exit")
 var before=g.export_snapshot();g.RelicEffects.end_combat(g);g.get_view()
 t.check(g.export_snapshot()==before,"DESIRE completed session and view cannot repeat end effect")
 g=Game.new(79);g.state.relics=[TYPE];g._finish_battle();t.action(g,"reward",{"type":"skip"});g.state.pressure=95
 t.check(t.action(g,"finish_prepare").ok and g.state.pressure==5 and g.state.overload_total==1 and not g.state.overloaded,"DESIRE battle-end threshold uses ordinary overload then clears interruption on departure")
 for phase in ["rest","prison"]:
  g=Game.new(80,true,"prison_test") if phase=="prison" else Game.new(79)
  if phase=="rest": g._start_rest();t.action(g,"rest_begin")
  g.state.relics=[TYPE];g.state.pressure=40;g.RelicEffects.end_combat(g)
  t.check(g.state.pressure==40,"DESIRE non-battle session does not grant ending pressure: "+phase)

static func pool(t) -> void:
 var g=Game.new(42);var spec=g.Cards.Rules.SPECS.fire_control
 # Reuse one real card under a temporary tag; no placeholder card ships.
 var original=spec.duplicate(true);spec.reward_pool="lewd_magic"
 t.check(not g.can_offer_card("fire_control") and g.reward_offer(["fire_control"]).is_empty(),"DESIRE locked pool is absent from actual reward selection")
 g.state.relics.append(TYPE)
 t.check(g.can_offer_card("fire_control") and g.reward_offer(["fire_control"])==["fire_control"],"DESIRE ownership unlocks tagged cards through shared offer eligibility")
 g._gain_card("fire_control");g.state.relics.erase(TYPE)
 t.check(g.state.deck.any(func(card):return card.type=="fire_control") and not g.can_offer_card("fire_control"),"DESIRE losing relic closes future offers without deleting owned cards")
 var shared=g.Cards.Rules.SPECS.prepared_chant;var shared_original=shared.duplicate(true);shared.reward_pool="lewd_magic"
 var witch=Opening.new(42,false,"equipment",true,false,25,false,false,"witch")
 t.check(not witch.Character.allowed_card(witch,"prepared_chant") and not witch.can_offer_card("prepared_chant") and "prepared_chant" not in witch.Character.pool(witch,["prepared_chant"]),"DESIRE future tagged shared card is excluded from witch compatibility and offers")
 shared.clear();shared.merge(shared_original)
 spec.clear();spec.merge(original)
