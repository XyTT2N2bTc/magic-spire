extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Rewards=preload("res://tests/reward_cases.gd")

static func containers(value, path: String, out: Array) -> void:
 if value is Dictionary:
  out.append({"value":value,"path":path})
  for key in value: containers(value[key],path+"."+str(key),out)
 elif value is Array:
  out.append({"value":value,"path":path})
  for i in range(value.size()): containers(value[i],path+"["+str(i)+"]",out)

static func shared(view: Dictionary, authority: Dictionary) -> String:
 var visible=[];var sources=[]
 containers(view,"view",visible);containers(authority,"authority",sources)
 for entry in visible:
  for source in sources:
   if is_same(entry.value,source.value): return entry.path+" -> "+source.path
 return ""

static func run(t) -> void:
 var images=preload("res://data/equipment_images.gd")
 var missing=[]
 for family in images.MATERIALS:
  for file in images.MATERIALS[family]:
   if not ResourceLoader.exists("res://assets/ui/equipment/"+file+".png"): missing.append(file)
 for file in images.TEMPLATES.values():
  if not ResourceLoader.exists("res://assets/ui/equipment/"+file+".png"): missing.append(file)
 t.check(missing.is_empty(),"ARCH all registered legacy equipment images exist: "+str(missing))
 var initial=Game.new(42,false,"equipment",false)
 t.check(initial.state.rng.size()==initial.B.RNG_SALTS.size() and initial.B.RNG_SALTS.keys().all(func(domain):return initial.state.rng.get(domain)==0),"ARCH initialization creates exactly the registered random domains with zero counters")
 card_identity(t)
 current_effect_boundaries(t)
 instance_effect_boundaries(t)
 for kind in ["equipment","component_links","prison_test","succubus_three_games","trader_solo","drone_solo","binding_box_solo"]:
  var g=Game.new(42,true,kind)
  if kind in ["drone_solo","binding_box_solo"]:
   t.check(t.action(g,"end").ok and g.CaptureBind.has_bind(g),"ARCH formal enemy turn establishes source-bound capture "+kind)
  projection_contract(t,g,kind)
 var g=Rewards.setup()
 var target=g.add_fixture("thigh",4)
 var id=target.id
 var focus=Rewards.give(t,g,"focus")
 t.check(Rewards.play(t,g,focus,"thigh",id).ok and g.state.charge==1,"ARCH real focus card grants shared charge")
 var before=g.export_snapshot()
 t.check(t.action(g,"manual",{"target":id}).ok,"ARCH release uses formal candidate")
 t.check(g._equipment(id).is_empty() and g.state.charge==1,"ARCH deleted ordinary target preserves unrelated charge")
 t.check(g.state.energy==before.energy-1 and g.state.mana==before.mana and g.state.rng==before.rng,"ARCH manual cleanup pays once and preserves unrelated resource and random domains")
 var settled=g.export_snapshot()
 g._cleanup()
 t.check(g.export_snapshot()==settled,"ARCH cleanup reaches a fixed point without repeated events")

static func card_identity(t) -> void:
 for damage in ["type","orphan","duplicate"]:
  var g=Rewards.setup()
  var candidate=g.candidates().filter(func(c):return c.valid)[0]
  var clean=g.export_snapshot()
  match damage:
   "type": g.state.deck[0].type="panic" if g.state.deck[0].type!="panic" else "sensitive"
   "orphan": g.state.deck[0].uid="card_missing"
   "duplicate": g.state.deck[0]=g.state.deck[1].duplicate(true)
  var damaged=g.export_snapshot()
  t.check(g.validate()!="","ARCH equal card counts cannot hide mismatched physical identity "+damage)
  t.check(not g.dispatch(candidate.id,g.state.version).ok and g.export_snapshot()==damaged,"ARCH invalid card identity rejects action before payment "+damage)
  g.state=clean
  t.check(not g.restore_snapshot(damaged).ok and g.export_snapshot()==clean,"ARCH same card invariant rejects restore atomically "+damage)

static func projection_contract(t, g, label: String) -> void:
 var before=g.state.duplicate(true)
 var view=g.get_view()
 var candidates=g.candidates()
 t.check(g.state==before,"ARCH preview preserves all state and random domains "+label)
 var alias=shared(view,{"state":g.state,"equipment":g.Equipment.TEMPLATES,"special":g.SpecialEquipment.TYPES,"regions":g.SpecialEquipment.REGIONS,"cards":g.Cards.Rules.SPECS,"buffs":g.Cards.Rules.BUFFS,"relics":g.Relics.TYPES,"enemies":g.Enemies.TYPES,"attacks":g.BasicAttacks.TYPES,"body_groups":g.Equipment.PANEL_GROUPS,"shop_copy":g.Services.ShopCopy.PERFORMANCES})
 t.check(alias=="","ARCH view has no writable references to state or registries "+label+": "+alias)
 var ids={}
 for candidate in candidates: ids[candidate.id]=true
 t.check(ids.size()==candidates.size() and candidates.map(func(c):return c.id)==view.candidates.map(func(c):return c.id),"ARCH distinct stable candidate identities survive repeat projection "+label)

static func current_effect_boundaries(t) -> void:
 var g=Game.new(42)
 g._discard_end();g.state.energy=30;g.state.relics=[];g.state.flask_mana=20
 for entry in [["echo_cast",false],["adaptability",false],["fire_control",false],["echo_cast",true]]:
  var card=preload("res://tests/curse_cases.gd").give(g,entry[0])
  t.check(t.action(g,"card",{"uid":card.uid,"free":entry[1]}).ok,"ARCH current effect uses formal card transaction "+entry[0])
 t.check(g.state.powers.size()==1 and g.state.powers[0].power_stacks==2 and g.state.temporary_mana==10 and "echo_cast_free" in g.state.card_buffs and g.validate()=="","ARCH fixture combines doubled power, temporary mana and pending replay")
 projection_contract(t,g,"active powers and split payment")
 g.RelicEffects.end_combat(g)
 g._start_rest()
 t.check(g.state.phase=="rest_choice" and not g.state.combat.active and g.state.temporary_mana==10 and g.state.powers.is_empty() and g.state.card_buffs.is_empty(),"ARCH rest choice retains temporary mana while clearing abilities and pending replay")
 projection_contract(t,g,"frozen rest choices")
 t.check(t.action(g,"rest_begin").ok and g.state.combat.active,"ARCH rest begins through its formal command")
 projection_contract(t,g,"new rest session")

static func instance_effect_boundaries(t) -> void:
 var f=preload("res://tests/concentration_cases.gd").setup()
 var g=f.g
 t.check(t.action(g,"card",{"uid":f.card.uid,"target":f.target.id,"free":true}).ok,"ARCH second bound face grows through the formal action")
 projection_contract(t,g,"physical card growth on second bound face")
 var checkpoint=g.restart_snapshot()
 var before=g.export_snapshot()
 var exposed=g.restart_snapshot()
 exposed.hand.clear();exposed.rng.clear()
 t.check(g.restart_snapshot()==checkpoint and g.export_snapshot()==before,"ARCH external restart snapshot cannot alter checkpoint or current state")
 g=Rewards.setup()
 var card=Rewards.give(t,g,"strain")
 t.check(t.action(g,"card",{"uid":card.uid,"free":true}).ok and g.state.charge==1,"ARCH preparation grants charge through the real card")
 t.check(t.action(g,"status_toggle",{"status":"charge","enabled":true}).ok,"ARCH charge mode uses the common command boundary")
 projection_contract(t,g,"prepared charge and all-stack mode")

 g=Game.new(42,true,"shop")
 t.check(t.action(g,"service",{"op":"take","index":0,"payment":"self"}).ok,"ARCH shop transaction freezes its actual payment source")
 projection_contract(t,g,"shop result and presentation registry")
