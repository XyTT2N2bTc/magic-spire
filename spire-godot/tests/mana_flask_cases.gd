extends RefCounted
const Game=preload("res://tests/game_fixture.gd")

static func shop(g) -> bool:
 preload("res://tests/service_cases.gd").arrive(g,"shop")
 var id=g.room_data(g.state.room).next.filter(func(next):return g.room_data(next).kind=="shop")[0]
 var departure=g.candidates().filter(func(c):return c.payload.kind=="depart" and c.payload.room==id)[0]
 if not g.dispatch(departure.id,g.state.version).ok: return false
 while g.state.phase=="travel":
  var step=g.candidates().filter(func(c):return c.payload.kind=="travel_step")[0]
  if not g.dispatch(step.id,g.state.version).ok: return false
 return g.state.phase=="shop"

static func run(t) -> void:
 var g=Game.new(42);g.state.relics.append("mana_earring")
 var before=g.export_snapshot();var pick=t.find_action(g,"flask",{"op":"deposit"})
 g.get_view();g.candidates()
 t.check(g.state==before,"FLASK preview never moves mana or spends deposit uses")
 t.check(g.dispatch(pick.id,g.state.version).ok and g.state.mana==90 and g.state.flask_mana==10 and g.state.flask_deposits==1,"FLASK deposit transfers ten")
 var committed=g.export_snapshot()
 t.check(not g.dispatch(pick.id,before.version).ok and g.state==committed,"FLASK stale deposit rejects atomically")
 t.check(t.action(g,"flask",{"op":"deposit"}).ok and g.state.mana==80 and g.state.flask_mana==20,"FLASK second deposit succeeds")
 committed=g.export_snapshot()
 t.check(not t.action(g,"flask",{"op":"deposit"}).ok and g.state==committed,"FLASK third deposit refuses without resource changes")
 t.check(["tick","round","energy","rng","charge","temporary_mana","combat"].all(func(key):return g.state[key]==before[key]),"FLASK storage costs no turn or energy and cannot trigger mana-spend relics")
 t.check(t.action(g,"flask",{"op":"withdraw"}).ok and t.action(g,"flask",{"op":"withdraw"}).ok and g.state.mana==100 and g.state.flask_mana==0 and g.state.flask_deposits==2,"FLASK repeated withdrawals restore full mana without refunding deposits")
 t.action(g,"end")
 t.check(g.state.flask_deposits==0 and t.action(g,"flask",{"op":"deposit"}).ok,"FLASK actual next turn restores deposit allowance")
 g=Game.new(42);g.state.mana=3.5;g.state.flask_mana=1000000.0
 t.check(t.action(g,"flask",{"op":"deposit"}).ok and g.state.mana==0 and g.state.flask_mana==1000003.5,"FLASK partial deposit preserves fractional mana and has no capacity limit")
 g.state.mana=98.5
 t.check(t.action(g,"flask",{"op":"withdraw"}).ok and g.state.mana==100 and g.state.flask_mana==1000002,"FLASK withdrawal draws only missing mana near the personal cap")
 for grade in [1,2]:
  g=Game.new(42);g.state.mana=40;g.state.flask_mana=9
  g._install_template("mouth_band","mouth",16,16,false,"fixture",grade)
  var expected=g.Consumables.amount(g,"mana_potion",9)
  t.check(t.action(g,"flask",{"op":"withdraw"}).ok and g.state.flask_mana==0 and g.state.mana==40+expected and expected==(5 if grade==1 else 4),"FLASK odd mouth reduction uses potion rounding boundary")
  g.state.mana=99.5;g.state.flask_mana=10
  t.check(t.action(g,"flask",{"op":"withdraw"}).ok and g.state.mana==100 and g.state.flask_mana==(9 if grade==1 else 8),"FLASK fractional deficit remains refillable under both potion rounding rules")
 g=Game.new(42);g.state.mana=40;g.state.flask_mana=50
 g.add_fixture("upper_arm",4);g.add_fixture("forearm",4);g.add_fixture("fingers",8)
 committed=g.export_snapshot()
 t.check(not t.action(g,"flask",{"op":"withdraw"}).ok and g.state==committed,"FLASK standing follows potion arm and grip restrictions")
 t.check(t.action(g,"flask",{"op":"deposit"}).ok,"FLASK deposit is still possible with bound hands")
 g.state.posture="sit"
 for i in range(3):t.check(t.action(g,"flask",{"op":"withdraw"}).ok,"FLASK seated withdrawal bypasses grip with no per-turn count limit")
 g=Game.new(42);g._finish_battle();g.state.mana=70
 t.check(t.action(g,"flask",{"op":"deposit"}).ok and g.state.phase=="reward","FLASK remains usable on reward page")
 g=Game.new(42);g.Pressure.gain(g,100,"fixture")
 before=g.export_snapshot()
 t.check(g.state.overloaded and t.action(g,"flask",{"op":"deposit"}).ok and g.state.tick==before.tick and g.state.overloaded,"FLASK deposit remains available during interruption without advancing it")
 g=Game.new(42);t.check(shop(g),"FLASK enters shop through actual travel")
 g.state.mana=1;g.state.flask_mana=300;g.state.temporary_mana=1000
 g._install_template("mouth_band","mouth",16,16,false,"fixture",3)
 var offer=t.find_action(g,"service",{"op":"take","payment":"flask"});var price=offer.mana
 before=g.export_snapshot()
 t.check(not t.find_action(g,"service",{"op":"take","index":offer.payload.index,"payment":"self"}).valid and offer.valid,"FLASK shop rejects temporary mana despite plentiful independent balance")
 t.check(g.dispatch(offer.id,g.state.version).ok and g.state.flask_mana==300-price and g.state.mana==1 and g.state.temporary_mana==1000,"FLASK shop pays full price despite blocked mouth and spell discounts")
 t.check(g.state.tick==before.tick and g.state.flask_deposits==before.flask_deposits,"FLASK purchase cannot refresh turn deposit limit")
 committed=g.export_snapshot()
 t.check(not g.dispatch(offer.id,g.state.version).ok and g.state==committed,"FLASK sold goods cannot charge either currency again")
 var target=g.add_fixture("thigh",4)
 var release=t.find_action(g,"service",{"op":"release","target":target.id,"payment":"flask"})
 var balance=g.state.flask_mana
 t.check(g.dispatch(release.id,g.state.version).ok and g._equipment(target.id).is_empty() and g.state.flask_mana==balance-release.mana and g.state.mana==1,"FLASK release service uses the same selected currency")
 var count=g.state.deck.size()
 t.check(t.action(g,"service",{"op":"remove","payment":"flask"}).ok and g.state.deck.size()==count-1 and g.state.mana==1,"FLASK card removal also accepts bottle mana")
 g.state.flask_mana=0
 var item=t.find_action(g,"service",{"op":"take","payment":"flask"});committed=g.export_snapshot()
 t.check(not item.valid and not g.dispatch(item.id,g.state.version).ok and g.state==committed,"FLASK insufficient payment rolls back item and all resources")
