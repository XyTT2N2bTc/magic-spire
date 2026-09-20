extends RefCounted
const Base=preload("res://tests/witch_expansion_cases.gd")
const Give=preload("res://tests/curse_cases.gd")
const Save=preload("res://tests/persistence_cases.gd")

static func run(t) -> void:
 _boundaries(t)
 for side in [false,true]:
  for grade in [1,2,3]:
   for tier in [1,2,3]:
    var g=Base.fresh();g.state.energy=0
    t.check(Base.play(t,g,"witch_binding_lure",side).ok and g.state.energy==0,"INDUCTION both skill faces play at zero energy")
    var part="hand" if side else "mouth"
    var request={"kind":"install","template":"rope" if side else "mouth_band","slot":"wrist" if side else "mouth","grade":grade,"tier":tier,"variant":0}
    var before=g.state.equipment.size();var outcome=g.Application.execute_concrete(g,request,"fixture")
    t.check(outcome.evaded==1 and g.state.equipment.size()==before+1 and not g.occupied(request.slot),"INDUCTION legal targeted application is evaded and redirects exactly one piece")
    var item=g.state.equipment.back()
    t.check(item.grade==grade and g.tier(item.durability,item.maximum)==tier and g.Character.restraint_part(g,item.slot)!=part,"INDUCTION redirect inherits incoming grade and tightness outside protected region")
    t.check("witch_induction_"+part in g.state.card_buffs,"INDUCTION unlimited protection is not consumed by a dodge")
 var g=Base.fresh()
 var spec=g.Cards.Rules.SPECS.witch_binding_lure
 t.check(spec.rarity=="uncommon" and spec.card_type=="skill" and spec.bound_modes==["self","self"] and not g.Cards.Rules.free_effect("witch_binding_lure",true),"INDUCTION uncommon card declares two bound skill faces")
 t.check(g.Character.reward_member(g,"witch_binding_lure","witch") and not g.Character.reward_member(g,"witch_binding_lure","original"),"INDUCTION reward eligibility is witch-exclusive")
 Base.play(t,g,"witch_binding_lure");Base.play(t,g,"witch_binding_lure",true);Base.play(t,g,"witch_binding_lure",true)
 t.check(g.state.card_buffs.count("witch_induction_hand")==1 and "witch_induction_mouth" in g.state.card_buffs,"INDUCTION faces coexist and repeated same face does not multiply redirects")
 var before=g.export_snapshot();g.get_view();g.candidates()
 t.check(g.state==before and not g.dispatch("missing",g.state.version).ok and g.state==before,"INDUCTION preview and rejected command leave state and random stream intact")
 var mouth={"kind":"install","template":"mouth_band","slot":"mouth","grade":2,"tier":3,"variant":0}
 g.state.witch_charges.hand=4;g.state.witch_charges.mouth=4
 for n in range(2):
  var result=g.Application.execute_concrete(g,mouth,"fixture")
  t.check(result.evaded==1 and not g.occupied("mouth") and g.state.witch_charges.hand==4 and g.state.witch_charges.mouth==4,"INDUCTION repeats and redirected cost bypasses preparation evasion")
 t.check(g.state.equipment.all(func(e):return g.Character.restraint_part(g,e.slot) not in ["mouth","hand"]),"INDUCTION dual protection redirects outside both protected regions")
 var restored=Save.roundtrip(t,g,"induction protection")
 if restored!=null:
  t.check(restored.Application.execute_concrete(restored,mouth,"fixture").evaded==1,"INDUCTION loaded protection still intercepts")
 g.Cards.expire_turn_buffs(g)
 t.check("witch_induction_mouth" in g.state.card_buffs,"INDUCTION ordinary turn end preserves enemy-action window")
 g._begin_player_turn()
 t.check(not g.state.card_buffs.any(func(id):return id.begins_with("witch_induction_")),"INDUCTION next player turn start expires both faces")
 g=Base.fresh();Base.play(t,g,"witch_binding_lure")
 var unrelated={"kind":"install","template":"rope","slot":"wrist","grade":1,"tier":1,"variant":0}
 t.check(g.Application.execute_concrete(g,unrelated,"fixture").ok and g.occupied("wrist"),"INDUCTION other incoming regions are unaffected")
 before=g.export_snapshot();var invalid=mouth.duplicate(true);invalid.slot="eyes"
 t.check(not g.Application.execute_concrete(g,invalid,"fixture").ok and g.state==before,"INDUCTION structurally invalid requests cannot trigger or draw random")
 g=Base.fresh();Base.play(t,g,"witch_binding_lure");g.state.evasion=1
 t.check(g.Application.execute_concrete(g,mouth,"fixture").evaded==1 and g.state.evasion==0 and g.state.equipment.is_empty(),"INDUCTION existing generic evasion retains first priority")
 t.check(g.Application.execute_concrete(g,mouth,"fixture",false,[],true).ok and g.occupied("mouth"),"INDUCTION voluntary card costs are not intercepted")
 g=Base._patience_encounter();Base.play(t,g,"witch_binding_lure")
 var enemy=g.state.enemies[0];enemy.intent=g.EnemyPlans.application(["mouth_band"],2,3);enemy.intent.slot="mouth"
 t.check(t.action(g,"end").ok and not g.occupied("mouth") and g.state.equipment.size()==1 and not "witch_induction_mouth" in g.state.card_buffs,"INDUCTION real enemy turn redirects before next-start expiration")
 _presentation(t)

static func _presentation(t) -> void:
 var g=Base.fresh()
 for count in [0,9,10,39,40,55]:
  var type=g.Character.Expansion.TRAINING[mini(4,count/10)]
  var card=Give.give(g,type);card.practice_plays=count
  var metadata=g.Cards.metadata(g,type,card.uid)
  var expected="已完成全部升级" if count>=40 else "%d／%d次" % [count,(int(count/10)+1)*10]
  t.check(metadata.note.contains(expected),"WITCH training tooltip exposes physical-instance progress: "+str(count))
 for part in g.Character.PARTS:
  var c=t.find_action(g,"attack",{"type":"witch_"+part,"form":0})
  t.check(c.label==g.Character.NAMES[part]+"施法" and c.brief_tags=="" and c.cost==1 and c.mana==5,"WITCH preparation labels retain real costs without redundant body and stacks")
 g=Base.fresh();Base.play(t,g,"witch_authority",true)
 t.check(g.get_view().end_turn_locked,"WITCH authoritative end lock projects independently of text")
 g.state.enemies.clear();g._finish_battle()
 t.check(not g.get_view().end_turn_locked,"WITCH end lock visual clears after victory")
 g=preload("res://tests/game_fixture.gd").new(42,true,"prison_test",true,false,25,false,false,"witch")
 t.check(not g.candidates().any(func(c):return c.payload.kind=="attack" and c.payload.type=="fireball"),"WITCH prison offers no original-character fireball")

static func _boundaries(t) -> void:
 var g=Base.fresh()
 g.Cards.grant_buff(g,"witch_induction_hand")
 var spec={"pool":"composite","templates":[{"family":"glove","variant":"short","straps":"straight"}],"grade":2,"tier":3}
 var request=g.Application.choose(g,spec,"probe")
 t.check(not request.is_empty() and g.Application._slots(request).size()>1,"composite fixture uses real multi-part coverage")
 var outcome=g.Application.execute_concrete(g,request,"probe")
 t.check(outcome.evaded==1 and g.state.composites.is_empty() and g.state.equipment.size()==1,"composite induction evades whole root and adds exactly one ordinary item")
 var item=g.state.equipment.back()
 t.check(item.grade==2 and g.tier(item.durability,item.maximum)==3 and g.Character.restraint_part(g,item.slot)!="hand","composite redirected item inherits grade and tier outside protected region")
 t.check(g.validate()=="","composite outcome validates")

 g=Base.fresh()
 var fill={"templates":g.Equipment.TEMPLATES.keys(),"slots":g.B.SLOTS.filter(func(slot):return slot!="mouth"),"allow_links":false,"grade":2,"tier":3,"replace":false}
 var filled=0
 for n in range(120):
  var selected=g.Application.choose(g,fill,"probe_fill","equipment")
  if selected.is_empty(): break
  var result=g.Application.execute_concrete(g,selected,"probe_fill",false,[],true)
  if not result.ok: break
  filled+=1
 t.check(filled>0 and not g.Application.can_apply(g,fill,"probe_fill"),"full-body fixture has no other legal grade-two ordinary position")
 g.Cards.grant_buff(g,"witch_induction_mouth")
 var mouth={"kind":"install","template":"mouth_band","slot":"mouth","grade":2,"tier":3,"variant":0}
 var before=g.state.equipment.duplicate(true)
 var rng=g.state.rng.duplicate(true)
 outcome=g.Application.execute_concrete(g,mouth,"probe")
 t.check(outcome.evaded==1 and g.state.equipment==before and not g.occupied("mouth"),"no redirect position still evades without installing or replacing equipment")
 t.check(g.state.rng==rng,"empty redirect pool does not advance random stream")
 t.check(g.validate()=="","full-body result validates")

 g=Base.fresh();g.Cards.grant_buff(g,"witch_induction_mouth")
 var restored=Save.roundtrip(t,g,"witch induction boundary")
 if restored!=null:
  var live=g.Application.execute_concrete(g,mouth,"probe")
  var loaded=restored.Application.execute_concrete(restored,mouth,"probe")
  t.check(live==loaded and live.evaded==1,"same incoming application returns identical result after restore")
  t.check(g.state.equipment==restored.state.equipment and g.state.rng==restored.state.rng,"restore preserves exact redirect equipment and random stream")
  t.check(Save.same(g.state,restored.state),"full resulting game state matches uninterrupted run except version")
