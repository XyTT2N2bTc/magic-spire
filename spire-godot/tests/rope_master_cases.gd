extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Replacement=preload("res://core/equipment_replacement.gd")
const SelfBinding=preload("res://core/self_binding.gd")
const Give=preload("res://tests/curse_cases.gd")
const Arch=preload("res://tests/architecture_cases.gd")

# The one rope-master encounter fixture: the plain game and the test-side probes share this builder,
# so the entrance and the battle entry stay one path.
static func encounter(seed_value: int=42, script=Game):
 var g=script.new(seed_value,false,"equipment",true)
 g.state.room_encounters.entrance="rope_master_solo"
 g._start_battle()
 return g

static func turn(t,g) -> void:
 var result=g.dispatch(g.command({"kind":"end"},g.state.version),g.state.version)
 t.check(result.ok,"ROPE real end-turn commits: "+str(result.get("error","")))

static func threshold_and_stock(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 boss.rope_art.stock=1
 g.RopeArt.hogtie(g,boss,2)
 t.check(boss.rope_art.refill and boss.rope_art.hogtie_pending==2 and boss.rope_art.hogtie=="","ROPE insufficient stock defers the required hogtie without a partial install")
 g.RopeArt.execute(g,boss,{"kind":"art_refill"})
 var hog=g._equipment(boss.rope_art.hogtie)
 t.check(not hog.is_empty() and hog.grade==2 and g.equipment_tier(hog)==2 and boss.rope_art.stock==9 and boss.rope_art.hogtie_pending==0,"ROPE refill completes the pending medium tier-two hogtie and pays its value")

 g=encounter();boss=g.RopeArt.master(g)
 boss.rope_art.domain=true
 g.state.guard_bind={"progress":0.0,"sources":{g.RopeArt.MASTER:{"enemy":boss.id,"energy":0}}}
 boss.rope_art.total=49;boss.rope_art.previous=49
 g.RopeArt.observe(g)
 t.check(boss.rope_art.drunk==0 and boss.rope_art.hogtie=="","ROPE values below the first threshold do not trigger")
 boss.rope_art.total=50;g.RopeArt.observe(g)
 hog=g._equipment(boss.rope_art.hogtie)
 t.check(boss.rope_art.drunk==2 and not hog.is_empty() and hog.grade==2 and boss.rope_art.total==54,"ROPE first crossing 50 adds two drunk layers and a counted medium hogtie")
 boss.rope_art.total=75;boss.rope_art.previous=74;g.RopeArt.observe(g)
 t.check(boss.rope_art.drunk==4,"ROPE first crossing 75 adds two drunk layers")
 boss.rope_art.total=80;boss.rope_art.previous=79;g.RopeArt.observe(g)
 hog=g._equipment(boss.rope_art.hogtie)
 t.check(hog.grade==3 and g.equipment_tier(hog)==2 and boss.rope_art.total==81,"ROPE crossing 80 upgrades and resets the hogtie while counting its added value")
 boss.rope_art.total=90;boss.rope_art.previous=89;g.RopeArt.observe(g)
 var first=boss.rope_art.drunk
 g.RopeArt.observe(g)
 boss.rope_art.total=89;boss.rope_art.previous=90;g.RopeArt.observe(g)
 boss.rope_art.total=90;g.RopeArt.observe(g)
 t.check(first==6 and boss.rope_art.drunk==8,"ROPE 90 triggers once per upward crossing and can trigger again after falling below")

static func card_layers(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 g.RopeArt.execute(g,boss,{"kind":"art_domain"})
 var rope=g.action_targets().filter(g.RopeArt.is_rope)[0]
 var other=g.Application.execute_concrete(g,{"kind":"install","template":"belt","slot":"thigh","point":"thigh_root","grade":1,"tier":1,"variant":0,"locked":false},"fixture").installed[0]
 boss.rope_art.submission=1;boss.rope_art.drunk=1
 var shown=g.get_view().statuses.filter(func(row):return row.id in ["rope_submission","rope_drunk"])
 t.check(shown.size()==2 and shown.all(func(row):return row.active and row.owner=="hero" and row.badge=="1" and row.icon!="info"),"ROPE status projection exposes both player debuffs and their actual stack badges")
 g.state.play=[g._make_card("strain")]
 var first_rope=g.RopeArt.card_damage(g,rope,7.0)
 var same_card_other=g.RopeArt.card_damage(g,other,7.0)
 t.check(first_rope==0 and same_card_other==0 and boss.rope_art.submission==0 and boss.rope_art.drunk==1,"ROPE submission has priority and nullifies every equipment hit of one card")
 shown=g.get_view().statuses.filter(func(row):return row.id in ["rope_submission","rope_drunk"])
 t.check(shown.size()==1 and shown[0].id=="rope_drunk" and shown[0].badge=="1","ROPE status projection removes spent submission while retaining drunk")
 g.state.play=[g._make_card("strain")]
 var drunk_first=g.RopeArt.card_damage(g,rope,7.0)
 var drunk_second=g.RopeArt.card_damage(g,rope,7.0)
 t.check(drunk_first==0 and drunk_second==0 and boss.rope_art.drunk==0,"ROPE drunk consumes one layer per card rather than per hit")
 t.check(not g.get_view().statuses.any(func(row):return row.id in ["rope_submission","rope_drunk"]),"ROPE zero-stack debuffs leave the status projection")
 g.state.play=[g._make_card("strain")]
 t.check(g.RopeArt.card_damage(g,rope,7.0)==7.0,"ROPE damage resumes on the following card after both blockers are spent")

static func enchantments_and_helper(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 boss.rope_art.domain=true;boss.rope_art.total=1;boss.rope_art.previous=1
 g.state.guard_bind={"progress":1.0,"sources":{g.RopeArt.MASTER:{"enemy":boss.id,"energy":0}}}
 g.state.strength=5;g.state.dexterity=5;boss.rope_art.active=2
 t.check(g.RelicEffects.attribute(g,"strength")==3 and g.RelicEffects.attribute(g,"dexterity")==3,"ROPE active enchantment dynamically lowers both attributes")
 boss.rope_art.total=0
 t.check(g.RelicEffects.attribute(g,"strength")==5 and g.RelicEffects.attribute(g,"dexterity")==5,"ROPE enchantments pause when capture value reaches zero")
 boss.rope_art.total=1;boss.rope_art.drain=2;g.state.mana=20
 g.RopeArt.turn_end(g)
 boss.rope_art.desire=2;g.state.pressure=0
 g.RopeArt.played(g,{"replay":false,"target":""},true)
 t.check(g.state.mana==10 and g.state.pressure==2,"ROPE drain uses own mana and desire settles once for a played card")
 var enchantments=g.get_view().statuses.filter(func(row):return row.id in ["rope_active","rope_drain","rope_desire"])
 t.check(enchantments.size()==3 and enchantments.all(func(row):return row.active and row.owner=="hero" and row.badge=="2"),"ROPE all three enchantments share the player status strip and actual stack counters")

 g.RopeArt.summon(g,boss)
 var helper=g.RopeArt.assistant(g)
 g.RopeArt.execute(g,helper,{"kind":"art_status"})
 var cards=g.state.draw.filter(func(card):return card.type==g.RopeArt.STATUS)
 var gag=g.equipment_at("mouth")[0]
 t.check(cards.size()==1 and gag.grade==3 and g.equipment_tier(gag)==2 and gag.name.contains("假阳具口球"),"ROPE hard assault adds the status card and the required advanced tier-two dildo gag")
 var status=cards[0];g.state.draw.erase(status);g._put_card_in_hand(status)
 t.check(boss.rope_art.submission==1,"ROPE drawing the helper status grants one submission layer")
 t.check(g.get_view().statuses.any(func(row):return row.id=="rope_submission" and row.active and row.badge=="1"),"ROPE drawing the real status card exposes its debuff badge")
 var before=g.state.special_equipment.map(func(item):return item.id)
 g._damage_enemy(helper,999,"fixed","test")
 var added=g.state.special_equipment.filter(func(item):return item.id not in before)
 t.check(added.size()==2 and added.all(func(item):return g.RestraintValue.from_profile(item.grade,g.equipment_tier(item))==4),"ROPE helper death leaves two distinct value-four special restraints")
 t.check(boss.rope_art.submission==0 and (["deck"]+g.Cards.ZONES).all(func(zone):return not g.state[zone].any(func(card):return card.type==g.RopeArt.STATUS)),"ROPE helper death removes every status copy and its debuff")
 t.check(not g.get_view().statuses.any(func(row):return row.id=="rope_submission"),"ROPE helper death also removes the submission status row")

static func persistence(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 g.RopeArt.execute(g,boss,{"kind":"art_intro"})
 boss.rope_art.active=1;boss.rope_art.hogtie_pending=3;boss.rope_art.refill=true
 var saved=g.export_snapshot()
 var restored=Game.new(0,false,"equipment",false)
 var result=restored.restore_snapshot(saved)
 var loaded=restored.RopeArt.master(restored)
 t.check(result.ok and loaded.rope_art.active==1 and loaded.rope_art.hogtie_pending==3 and loaded.rope_art.refill and not restored.RopeArt.assistant(restored).is_empty(),"ROPE snapshot restores encounter counters, pending threshold work and assistant state")

static func hogtie_shared_release(t) -> void:
 for slot in ["wrist","ankle"]:
  var g=encounter();var boss=g.RopeArt.master(g)
  g.RopeArt.hogtie(g,boss,2)
  var hog=g._equipment(boss.rope_art.hogtie);var id=hog.id
  t.check(g.equipment_at("wrist").any(func(e):return e.id==id) and g.equipment_at("ankle").any(func(e):return e.id==id),"ROPE both slots expose the same physical instance")
  var target=g.equipment_at(slot).filter(func(e):return e.id==id)[0]
  g._apply_equipment_damage(target,7,"strain");g._cleanup()
  var wrist=g.equipment_at("wrist").filter(func(e):return e.id==id)[0]
  var ankle=g.equipment_at("ankle").filter(func(e):return e.id==id)[0]
  t.check(wrist.durability==ankle.durability and g.equipment_tier(wrist)==1 and g.equipment_tier(ankle)==1,"ROPE damage through either slot lowers shared tightness")
  g._apply_equipment_damage(target,999,"strain");g._cleanup()
  t.check(g.equipment_at("wrist").all(func(e):return e.id!=id) and g.equipment_at("ankle").all(func(e):return e.id!=id) and not g.RopeArt.hogtied(g),"ROPE breaking either contact releases both slots")

static func hogtie_attachments(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 g.RopeArt.hogtie(g,boss,2)
 var hog=g._equipment(boss.rope_art.hogtie)
 t.check(not g.Binding.eligible(hog) and g.Links.anchor_slots(hog).is_empty() and not g.Shoulders.eligible(hog),"ROPE hogtie supplies no ordinary, torso or shoulder attachment anchor")
 for grade in [2,3]:
  var stock=boss.rope_art.stock
  var rng=g.state.rng.duplicate(true)
  g.RopeArt.hogtie(g,boss,grade)
  t.check(hog.grade==grade and g.equipment_tier(hog)==2 and not hog.has("binding") and boss.rope_art.stock==stock and g.state.rng==rng,"ROPE repeated or upgraded hogtie preserves stock value and RNG without attachments")
  g._reinforce_equipment(hog)
  t.check(g.equipment_tier(hog)==3 and not hog.has("binding") and g.state.rng==rng,"ROPE tier-three hogtie never generates or rolls a torso attachment")
 var wrist=g._install_template("rope","wrist",6.4,8.0,false,"fixture")
 var palm=g._install_template(g.Equipment.default_template("palm"),"palm",6.4,8.0,false,"fixture")
 var ankle=g._install_template("rope","ankle",6.4,8.0,false,"fixture")
 var foot=g._install_template(g.Equipment.default_template("foot"),"foot",6.4,8.0,false,"fixture")
 var crotch=g._install_special("crotch_rope_low","special_3_a")
 var before=g.export_snapshot()
 for pair in [[palm,"wrist","palm","palm_left"],[foot,"ankle","foot","foot"],[crotch,"wrist",g.Links.CROTCH_CONTACT,g.Links.CROTCH_CONTACT]]:
  for reverse in [false,true]:
   var ends=[hog.id,pair[0].id];var slots=[pair[1],pair[2]];var points=[pair[1],pair[3]]
   if reverse: ends.reverse();slots.reverse();points.reverse()
   t.check(g._install_link(ends[0],ends[1],6.4,"fixture",1,[],slots,points).is_empty() and g.export_snapshot()==before,"ROPE explicit link installation rejects either hogtie endpoint without IDs, resources or RNG changes")
 var offers=g.EquipmentOffers.links(g,1)
 t.check(not offers.is_empty() and offers.all(func(offer):return hog.id not in offer.ends) and g.export_snapshot()==before,"ROPE enemy link candidates exclude hogtie while retaining valid neighbours read-only")
 t.check(not g._install_link(wrist.id,palm.id,6.4,"fixture",1,[],["wrist","palm"],["wrist","palm_left"]).is_empty() and not g._install_link(ankle.id,foot.id,6.4,"fixture").is_empty(),"ROPE ordinary wrist and ankle anchors retain their real links")
 g._reinforce_equipment(wrist)
 t.check(wrist.has("binding") and not hog.has("binding") and g.validate()=="","ROPE ordinary tier-three wrist still gains its own torso binding")
 var restored=Game.new(0,false,"equipment",false)
 t.check(restored.restore_snapshot(g.export_snapshot()).ok,"ROPE hogtie and independent ordinary attachments roundtrip through the real validator")
 before=g.export_snapshot()
 for kind in ["linked","integrated"]:
  var saved=before.duplicate(true)
  saved.equipment.filter(func(item):return item.id==hog.id)[0].binding={"kind":kind}
  t.check(not g.restore_snapshot(saved).ok and g.export_snapshot()==before,"ROPE forbidden hogtie attachment rejects restoration atomically: "+kind)

static func reported_turn_sequence(t) -> void:
 var g=preload("res://core/game.gd").new(3364630912,true,"rope_master_solo")
 var crossed_upgrade=false
 for step in range(20):
  if g.state.phase!="battle": break
  var result=g.dispatch(g.command({"kind":"end"},g.state.version),g.state.version)
  t.check(result.ok,"ROPE reported seed end-turn commits through upgrade and capture: "+str(result.get("error","")))
  if not result.ok: break
  crossed_upgrade=crossed_upgrade or g.state.equipment.any(func(item):return item.template==g.RopeArt.HOGTIE and item.grade==3)
  t.check(g.state.equipment.filter(func(item):return item.template==g.RopeArt.HOGTIE).all(func(item):return not item.has("binding") and g.state.links.all(func(link):return item.id not in link.ends)),"ROPE live end-turn sequence never attaches a connection to hogtie")
 t.check(crossed_upgrade and g.state.phase=="captured" and g.state.guard_bind.is_empty() and g.validate()=="","ROPE reported sequence crosses hogtie upgrade and reaches valid capture")
 t.check(not g.get_view().statuses.any(func(row):return row.id.begins_with("rope_")),"ROPE battle-only statuses disappear after capture even with retained enemy records")
 var copy=Game.new(0,false,"equipment",false)
 t.check(copy.restore_snapshot(g.export_snapshot()).ok,"ROPE completed capture remains a valid save checkpoint")
 var h=encounter()
 h.RopeArt.execute(h,h.RopeArt.master(h),{"kind":"art_domain"})
 var before=h.state.guard_bind.duplicate(true)
 h.CaptureBind.clear_bind(h)
 t.check(h.state.guard_bind==before,"ROPE ordinary in-battle clearing still respects the domain immunity")
 var result=h.dispatch(h.command({"kind":"surrender"},h.state.version),h.state.version)
 t.check(result.ok and h.state.phase=="captured" and h.state.guard_bind.is_empty(),"ROPE real surrender clears the domain only as part of capture")

# QX2″ (rev3.2 gherkin G-QX2-1…7): the capture ledger. Every expectation below is recomputed from
# the live containers with the same published formula (`RestraintValue.from_profile` over
# `action_targets()`), so the assertion side never reads the ledger it judges.
static func rope_expected(g) -> Dictionary:
 var expected={}
 for item in g.action_targets():
  if not g.RopeArt.is_rope(item): continue
  if float(item.get("durability",0.0))<=0.000001: continue
  expected[String(item.id)]=int(g.RestraintValue.from_profile(item.grade,g.equipment_tier(item)))
 return expected

static func ledger_matches(t, g, label: String) -> void:
 var expected=rope_expected(g)
 var boss=g.RopeArt.master(g)
 var values=Dictionary(boss.rope_art.values)
 var total=0
 for id in expected: total+=int(expected[id])
 var extra=values.keys().filter(func(id):return not expected.has(String(id)))
 var missing=expected.keys().filter(func(id):return not values.has(String(id)))
 var wrong=expected.keys().filter(func(id):return values.has(String(id)) and int(values[id])!=int(expected[id]))
 t.check(extra.is_empty() and missing.is_empty() and wrong.is_empty() and int(boss.rope_art.total)==total,"REMOVAL "+label+": the ledger holds exactly the rope instances of the body with the recomputed values, and its total is their sum: extra="+str(extra)+" missing="+str(missing)+" wrong="+str(wrong)+" total="+str(boss.rope_art.total)+"/"+str(total))

static func capture_entry_counts_every_rope_instance(t) -> void:
 var g=Game.new(42,false,"equipment",true)
 var maximum=g.Equipment.maximum(3)
 var arm=g._install_template("rope","upper_arm",maximum,maximum,false,"fixture",3)
 var wrist=g._install_template("rope","wrist",maximum,maximum,false,"fixture",3)
 var palm=g._install_template(g.Equipment.default_template("palm"),"palm",maximum,maximum,false,"fixture",1)
 g._install_special("crotch_rope_low","special_3_a")
 g._install_link(wrist.id,palm.id,maximum,"fixture",1,[],["wrist","palm"],["wrist","palm_left"])
 var preset=rope_expected(g)
 var straps=g.Shoulders.pieces(g).filter(func(item):return String(item.get("shoulder_host",""))==String(arm.id))
 var binding=Dictionary(arm.get("binding",{}))
 var binding_id=String(binding.get("id","")) if String(binding.get("kind",""))=="linked" else ""
 t.check(not straps.is_empty() and not binding.is_empty() and preset.size()>=5,"REMOVAL capture_entry_counts_every_rope_instance: the fixture installs a tier-three rope upper-arm that grows both rope shoulder straps and a torso connection, plus a wrist rope and a crotch rope: straps="+str(straps.size())+" binding="+str(binding.get("kind",""))+" preset="+str(preset.size()))
 g.state.room_encounters.entrance="rope_master_solo"
 g._start_battle()
 var boss=g.RopeArt.master(g)
 var counted=Dictionary(boss.rope_art.values)
 var absent=[]
 for id in [String(arm.id),String(wrist.id)]+straps.map(func(item):return String(item.id))+([binding_id] if binding_id!="" else []):
  if not counted.has(id): absent.append(id)
 t.check(not boss.is_empty() and absent.is_empty(),"REMOVAL capture_entry_counts_every_rope_instance: the battle entry counts every rope instance once -- the arm piece, its two straps, its torso connection and the wrist rope are all in the ledger: absent="+str(absent)+" counted="+str(counted.size())+"/"+str(preset.size()))
 ledger_matches(t,g,"capture_entry_counts_every_rope_instance")
 t.check(g.RopeArt.account_issue(g)=="","REMOVAL capture_entry_counts_every_rope_instance: the full recount agrees with the ledger right after the battle entry: "+g.RopeArt.account_issue(g))

static func capture_accounts_new_members_at_join(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 g.RopeArt.execute(g,boss,{"kind":"art_domain"})
 var maximum=g.Equipment.maximum(3)
 var foot=g._install_template(g.Equipment.default_template("foot"),"foot",maximum,maximum,false,"fixture",1)
 var ankle=g._install_template("rope","ankle",maximum,maximum,false,"fixture",3)
 var link=g._install_link(ankle.id,foot.id,6.4,"fixture")
 t.check(not link.is_empty() and Dictionary(boss.rope_art.values).has(String(link.id)),"REMOVAL capture_accounts_new_members_at_join: a rope link installed by a non-rope source is in the ledger when the install returns: id="+String(link.get("id","missing")))
 var crotch=g._install_special("crotch_rope_low","special_3_a")
 t.check(not crotch.is_empty() and Dictionary(boss.rope_art.values).has(String(crotch.id)),"REMOVAL capture_accounts_new_members_at_join: a crotch rope installed by a non-rope source is in the ledger when the install returns: id="+String(crotch.get("id","missing")))
 var arm=g._install_template("rope","upper_arm",maximum,maximum,false,"fixture",3)
 var straps=g.Shoulders.pieces(g).filter(func(item):return String(item.get("shoulder_host",""))==String(arm.id))
 var binding=Dictionary(arm.get("binding",{}))
 var binding_id=String(binding.get("id","")) if String(binding.get("kind",""))=="linked" else ""
 var absent=[]
 for id in [String(arm.id)]+straps.map(func(item):return String(item.id))+([binding_id] if binding_id!="" else []):
  if not Dictionary(boss.rope_art.values).has(id): absent.append(id)
 t.check(not arm.is_empty() and straps.size()==2 and absent.is_empty(),"REMOVAL capture_accounts_new_members_at_join: the tier-three rope upper-arm books itself, its two shoulder straps and its torso connection at the join hook, not at the physical layer: absent="+str(absent))
 ledger_matches(t,g,"capture_accounts_new_members_at_join")

static func capture_follows_tier_hook_only(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 g.RopeArt.execute(g,boss,{"kind":"art_domain"})
 var maximum=g.Equipment.maximum(2)
 var piece=g._install_template("rope","wrist",(g.RestraintValue.TIER_RATIOS[1]+g.RestraintValue.TIER_RATIOS[2])*0.5*maximum,maximum,false,"fixture",2)
 var id=String(piece.id)
 var before=int(boss.rope_art.values.get(id,-1))
 t.check(before>0 and g.equipment_tier(piece)==2,"REMOVAL capture_follows_tier_hook_only: the fixture starts at tier two with a value the ledger holds: value="+str(before))
 var band=float(piece.durability)-g.RestraintValue.TIER_RATIOS[1]*maximum
 g._apply_equipment_damage(piece,band*0.25,"strain")
 t.check(g.equipment_tier(piece)==2 and int(boss.rope_art.values.get(id,-1))==before,"REMOVAL capture_follows_tier_hook_only: a write inside one tier leaves the booked value alone (only a tier change or a tightening intent recounts): tier="+str(g.equipment_tier(piece))+" value="+str(boss.rope_art.values.get(id,"missing")))
 g._apply_equipment_damage(piece,band,"strain")
 t.check(g.equipment_tier(piece)==1 and int(boss.rope_art.values.get(id,-1))==int(g.RestraintValue.from_profile(piece.grade,1)),"REMOVAL capture_follows_tier_hook_only: a write across a tier recounts the piece at the non-tightening row: tier="+str(g.equipment_tier(piece))+" value="+str(boss.rope_art.values.get(id,"missing")))
 ledger_matches(t,g,"capture_follows_tier_hook_only")

static func capture_unaccounts_removed_closure(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 g.RopeArt.execute(g,boss,{"kind":"art_domain"})
 var maximum=g.Equipment.maximum(3)
 var arm=g._install_template("rope","upper_arm",maximum,maximum,false,"fixture",3)
 var straps=g.Shoulders.pieces(g).filter(func(item):return String(item.get("shoulder_host",""))==String(arm.id))
 var binding=Dictionary(arm.get("binding",{}))
 var binding_id=String(binding.get("id","")) if String(binding.get("kind",""))=="linked" else ""
 var ids=[String(arm.id)]+straps.map(func(item):return String(item.id))+([binding_id] if binding_id!="" else [])
 var booked=ids.filter(func(id):return Dictionary(boss.rope_art.values).has(id))
 t.check(booked.size()==ids.size() and ids.size()>=3,"REMOVAL capture_unaccounts_removed_closure: the arm piece, its torso connection and both shoulder straps are booked before the removal: booked="+str(booked.size())+"/"+str(ids.size()))
 g._apply_equipment_damage(arm,999,"strain")
 g._cleanup()
 var left=ids.filter(func(id):return Dictionary(boss.rope_art.values).has(id))
 t.check(left.is_empty(),"REMOVAL capture_unaccounts_removed_closure: the removal announcement writes off the whole closure -- the arm, both straps and the connection leave the ledger with it: left="+str(left))
 ledger_matches(t,g,"capture_unaccounts_removed_closure")

# G-QX2-7 third clause (R3, cleaner notes §3 P2): the linked torso connection of a destroyed host is
# only written off through the host's closure -- no unit frame owns that removal. Seed 1 grows the
# connection as `linked` (seed 42, used above, grows it as `integrated`), so this fixture is the one
# that exercises the closure's linked-binding row.
static func capture_unaccounts_removed_linked_closure(t) -> void:
 var g=encounter(1)
 var boss=g.RopeArt.master(g)
 g.RopeArt.execute(g,boss,{"kind":"art_domain"})
 var maximum=g.Equipment.maximum(3)
 var arm=g._install_template("rope","upper_arm",maximum,maximum,false,"fixture",3)
 var binding=Dictionary(arm.get("binding",{}))
 var binding_id=String(binding.get("id",""))
 var straps=g.Shoulders.pieces(g).filter(func(item):return String(item.get("shoulder_host",""))==String(arm.id))
 var booked=Dictionary(boss.rope_art.values)
 var pre_present=[String(arm.id),binding_id]+straps.map(func(item):return String(item.id))
 var pre_absent=pre_present.filter(func(id):return not booked.has(id))
 t.check(String(binding.get("kind",""))=="linked" and binding_id!="" and straps.size()==2 and pre_absent.is_empty(),"REMOVAL capture_unaccounts_removed_linked_closure: the seed-one fixture grows a linked torso connection and the join hook books the arm, its connection and both straps: kind="+String(binding.get("kind",""))+" id="+binding_id+" absent="+str(pre_absent))
 t.check(int(boss.rope_art.total)==32 and booked.has(binding_id),"REMOVAL capture_unaccounts_removed_linked_closure: before the purge the ledger holds the whole closure for a total of thirty-two: total="+str(boss.rope_art.total)+" values="+str(booked))
 g._apply_equipment_damage(arm,999,"strain")
 g._cleanup()
 boss=g.RopeArt.master(g)
 var after=Dictionary(boss.rope_art.values)
 t.check(not after.has(binding_id) and int(boss.rope_art.total)==8,"REMOVAL capture_unaccounts_removed_linked_closure: the purge writes the linked connection off with its host: total="+str(boss.rope_art.total)+" values="+str(after))
 t.check(after.size()==2 and int(after.get("equipment_1",0))==4 and int(after.get("equipment_2",0))==4,"REMOVAL capture_unaccounts_removed_linked_closure: only the two art-domain ropes remain booked, four each: values="+str(after))
 t.check(g.RopeArt.account_issue(g)=="","REMOVAL capture_unaccounts_removed_linked_closure: the debug recount agrees with the ledger after the purge: "+g.RopeArt.account_issue(g))
 ledger_matches(t,g,"capture_unaccounts_removed_linked_closure")

# G-QX2-5′ (C2d): a replacement transaction writes the removed closure off by id and replays the join
# hook of the installed piece, so the old host's linked connection and both straps leave with it and
# the installed closure enters on the live state.
static func capture_replacement_commit_accounts_closure(t) -> void:
 var g=encounter(1)
 var boss=g.RopeArt.master(g)
 g.RopeArt.execute(g,boss,{"kind":"art_domain"})
 var point="upper_arm_top"
 var filled=[]
 for index in range(g._capacity(g.Links.point_slot(point))):
  filled.append(add_rope(g,"upper_arm",point,1,3))
 var old=filled[0] if not filled.is_empty() else {}
 var old_binding=Dictionary(old.get("binding",{}))
 var old_binding_id=String(old_binding.get("id",""))
 var old_straps=g.Shoulders.pieces(g).filter(func(item):return String(item.get("shoulder_host",""))==String(old.get("id","")))
 var old_ids=[String(old.get("id",""))]+old_straps.map(func(item):return String(item.id))+([old_binding_id] if String(old_binding.get("kind",""))=="linked" else [])
 t.check(filled.size()==g._capacity(g.Links.point_slot(point)) and old_straps.size()==2 and String(old_binding.get("kind",""))=="linked" and Dictionary(boss.rope_art.values).has(old_binding_id),"REMOVAL capture_replacement_commit_accounts_closure: the full point holds rope hosts whose linked connection and straps are booked: old="+String(old.get("id",""))+" closure="+str(old_ids))
 var maximum=g.Equipment.maximum(3)
 var plan=Replacement.plan(g,[{"kind":"install","template":"rope","slot":"upper_arm","grade":3,"tier":3,"point":point,"variant":0,"locked":false}],"fixture")
 var missing_removed=old_ids.filter(func(id):return id not in plan.get("removed",[]))
 t.check(plan.ok and not plan.get("installed",[]).is_empty() and missing_removed.is_empty(),"REMOVAL capture_replacement_commit_accounts_closure: the replacement plan names the whole removed closure: ok="+str(plan.ok)+" removed="+str(plan.get("removed",[]))+" missing="+str(missing_removed))
 var applied=Replacement.execute(g,plan)
 boss=g.RopeArt.master(g)
 var left=old_ids.filter(func(id):return Dictionary(boss.rope_art.values).has(id))
 t.check(applied.ok and left.is_empty(),"REMOVAL capture_replacement_commit_accounts_closure: the commit writes the replaced host, its connection and both straps off the ledger: left="+str(left))
 var new_id=String(applied.get("installed",[{}])[0].get("id","")) if not applied.get("installed",[]).is_empty() else ""
 var live=g._equipment(new_id)
 var new_binding=Dictionary(live.get("binding",{}))
 var new_straps=g.Shoulders.pieces(g).filter(func(item):return String(item.get("shoulder_host",""))==new_id)
 var new_ids=[new_id]+new_straps.map(func(item):return String(item.id))+([String(new_binding.get("id",""))] if String(new_binding.get("kind",""))=="linked" else [])
 var new_absent=new_ids.filter(func(id):return not Dictionary(boss.rope_art.values).has(id))
 t.check(new_id!="" and not live.is_empty() and new_straps.size()==2 and new_absent.is_empty(),"REMOVAL capture_replacement_commit_accounts_closure: the replayed join hook books the installed host, its straps and its linked connection: id="+new_id+" absent="+str(new_absent))
 t.check(g.RopeArt.account_issue(g)=="","REMOVAL capture_replacement_commit_accounts_closure: the debug recount agrees with the ledger after the replacement: "+g.RopeArt.account_issue(g))
 ledger_matches(t,g,"capture_replacement_commit_accounts_closure")

# G-QX2-2／-4 (加固带): a reinforced special is never a rope instance, so its lock and the strap it owns
# enter no ledger row on install, on a forced replacement or on a release; the recount stays silent.
static func capture_ignores_non_rope_special_closure(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 g.RopeArt.execute(g,boss,{"kind":"art_domain"})
 var booked=Dictionary(boss.rope_art.values).duplicate(true)
 var lock=g._install_special("negative_plate_lock_medium","special_2_a",3)
 var lock_strap={}
 for item in g.state.special_equipment:
  if g.SpecialEquipment.reinforcement_matches(item,lock): lock_strap=item
 var unchanged=Dictionary(boss.rope_art.values)
 var extra=unchanged.keys().filter(func(id):return not booked.has(String(id)))
 t.check(not lock.is_empty() and not lock_strap.is_empty() and int(boss.rope_art.total)==8 and unchanged.size()==booked.size() and extra.is_empty(),"REMOVAL capture_ignores_non_rope_special_closure: the reinforced lock and its strap are not rope instances and enter no ledger row: lock="+String(lock.get("id",""))+" strap="+String(lock_strap.get("id",""))+" extra="+str(extra)+" total="+str(boss.rope_art.total))
 t.check(g.RopeArt.account_issue(g)=="","REMOVAL capture_ignores_non_rope_special_closure: the recount agrees right after the reinforced lock lands: "+g.RopeArt.account_issue(g))
 var replaced=Replacement.force_special(g,"negative_vibrator_lock_catheter_high",3,"fixture")
 boss=g.RopeArt.master(g)
 var old_gone=g._equipment(String(lock.get("id",""))).is_empty() and g._equipment(String(lock_strap.get("id",""))).is_empty()
 var new_lock=g.state.special_equipment.filter(func(item):return g.SpecialEquipment.is_chastity(item) and not g.SpecialEquipment.is_reinforcement(item))
 var new_strap={}
 for item in g.state.special_equipment:
  if not new_lock.is_empty() and g.SpecialEquipment.reinforcement_matches(item,new_lock[0]): new_strap=item
 var after=Dictionary(boss.rope_art.values)
 var after_extra=after.keys().filter(func(id):return not booked.has(String(id)))
 t.check(replaced.ok and old_gone and new_lock.size()==1 and not new_strap.is_empty() and after.size()==booked.size() and after_extra.is_empty(),"REMOVAL capture_ignores_non_rope_special_closure: the forced replacement swaps both non-rope members and still books nothing: ok="+str(replaced.ok)+" extra="+str(after_extra)+" specials="+str(g.state.special_equipment.map(func(item):return String(item.id))))
 t.check(g.RopeArt.account_issue(g)=="","REMOVAL capture_ignores_non_rope_special_closure: the recount agrees after the forced replacement: "+g.RopeArt.account_issue(g))
 ledger_matches(t,g,"capture_ignores_non_rope_special_closure")

# G-QX2-4 second segment (C2c): a composite that covers the wrist cancels the rope's linked connection
# inside the install unit; the commit's id write-off is the only path that removes it from the ledger.
static func capture_unaccounts_composite_preemption(t) -> void:
 var g=encounter(1)
 var boss=g.RopeArt.master(g)
 g.RopeArt.execute(g,boss,{"kind":"art_domain"})
 var maximum=g.Equipment.maximum(3)
 var wrist=g._install_template("rope","wrist",maximum,maximum,false,"fixture",3)
 var binding=Dictionary(wrist.get("binding",{}))
 var binding_id=String(binding.get("id",""))
 t.check(String(binding.get("kind",""))=="linked" and binding_id!="" and Dictionary(boss.rope_art.values).has(binding_id),"REMOVAL capture_unaccounts_composite_preemption: the tier-three wrist rope books its linked connection before the composite lands: id="+binding_id)
 var glove=g._install_assembly("glove","short","fixture",2,1)
 var after=Dictionary(boss.rope_art.values)
 t.check(not glove.is_empty() and g._equipment(wrist.id).get("binding",{}).is_empty() and not after.has(binding_id),"REMOVAL capture_unaccounts_composite_preemption: the covering composite cancels the connection and the unit commit writes it off the ledger: glove="+String(glove.get("id",""))+" values="+str(after))
 t.check(g.RopeArt.account_issue(g)=="","REMOVAL capture_unaccounts_composite_preemption: the recount agrees after the pre-emptive cancellation: "+g.RopeArt.account_issue(g))
 ledger_matches(t,g,"capture_unaccounts_composite_preemption")

# G-QX2-4 third segment (C2b, 单侧肩带): breaking one shoulder writes only that side off; the host, its
# linked connection and the other strap stay booked.
static func capture_unaccounts_single_strap(t) -> void:
 var g=encounter(1)
 var boss=g.RopeArt.master(g)
 g.RopeArt.execute(g,boss,{"kind":"art_domain"})
 var maximum=g.Equipment.maximum(3)
 var arm=g._install_template("rope","upper_arm",maximum,maximum,false,"fixture",3)
 var binding_id=String(Dictionary(arm.get("binding",{})).get("id",""))
 var straps=g.Shoulders.pieces(g).filter(func(item):return String(item.get("shoulder_host",""))==String(arm.id))
 var before=int(boss.rope_art.total)
 t.check(straps.size()==2 and String(Dictionary(arm.get("binding",{})).get("kind",""))=="linked","REMOVAL capture_unaccounts_single_strap: the fixture has two straps and a linked connection to keep: straps="+str(straps.map(func(item):return String(item.id))))
 var broken=String(straps[0].id)
 var kept=String(straps[1].id)
 var broken_value=int(g.RestraintValue.from_profile(straps[0].grade,g.equipment_tier(straps[0])))
 g._apply_equipment_damage(straps[0],999,"strain")
 boss=g.RopeArt.master(g)
 var damaged=Dictionary(boss.rope_art.values)
 t.check(not damaged.has(broken) and damaged.has(kept) and damaged.has(binding_id) and int(boss.rope_art.total)==before-broken_value,"REMOVAL capture_unaccounts_single_strap: the zeroing write drops only the broken side and keeps the other side and the connection: broken="+broken+" values="+str(damaged)+" total="+str(boss.rope_art.total))
 g._cleanup()
 boss=g.RopeArt.master(g)
 var after=Dictionary(boss.rope_art.values)
 t.check(not after.has(broken) and after.has(kept) and after.has(binding_id) and int(boss.rope_art.total)==before-broken_value,"REMOVAL capture_unaccounts_single_strap: the settle leaves the ledger at the same single-side result: values="+str(after)+" total="+str(boss.rope_art.total))
 t.check(g.RopeArt.account_issue(g)=="","REMOVAL capture_unaccounts_single_strap: the recount agrees after the single-side removal: "+g.RopeArt.account_issue(g))
 ledger_matches(t,g,"capture_unaccounts_single_strap")

static func capture_settles_only_in_rope_battle(t) -> void:
 var g=Game.new(42,false,"equipment",true)
 g._start_battle()
 var maximum=g.Equipment.maximum(3)
 var arm=g._install_template("rope","upper_arm",maximum,maximum,false,"fixture",3)
 t.check(g.RopeArt.master(g).is_empty(),"REMOVAL capture_settles_only_in_rope_battle: a battle without the rope master has no ledger owner, so the same install books nothing:")
 var owners=g.state.enemies.filter(func(row):return row.has("rope_art"))
 t.check(owners.is_empty() and g.RopeArt.account_issue(g)=="","REMOVAL capture_settles_only_in_rope_battle: no enemy record grows a rope ledger outside the rope-master encounter, and the recount stays silent: owners="+str(owners.map(func(row):return String(row.id))))
 t.check(not arm.is_empty() and g.validate()=="","REMOVAL capture_settles_only_in_rope_battle: the install still lands physically and the state validates: "+g.validate())

static func capture_account_matches_recount(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 g.RopeArt.execute(g,boss,{"kind":"art_domain"})
 t.check(g.RopeArt.account_issue(g)=="","REMOVAL capture_account_matches_recount: the debug recount agrees with the ledger after the domain expansion: "+g.RopeArt.account_issue(g))
 await turn(t,g)
 boss=g.RopeArt.master(g)
 t.check(g.RopeArt.account_issue(g)=="","REMOVAL capture_account_matches_recount: the debug recount still agrees after a full enemy turn runs the thresholds and the cleanup: "+g.RopeArt.account_issue(g))
 var saved=int(boss.rope_art.total)
 boss.rope_art.total=saved+3
 var issue=g.RopeArt.account_issue(g)
 boss.rope_art.total=saved
 t.check(issue!="" and g.RopeArt.account_issue(g)=="","REMOVAL capture_account_matches_recount: a ledger total that disagrees with the recount is a named issue, and restoring it clears the issue: issue="+issue)

# QX2″ b rows: the join layer is the only place an application presents and observes. The helpers
# below build the same fixtures the criteria read, so a threshold fixture stays one screen long.
static func log_texts(g, from: int) -> Array:
 var out=[]
 for index in range(from,g.state.logs.size()): out.append(String(g.state.logs[index].text))
 return out

static func add_rope(g, slot: String, point: String, grade: int, tier: int, template: String="rope") -> Dictionary:
 var maximum=g.Equipment.maximum(grade)
 return g._install_template(template,slot,maximum*[0.0,0.4,0.8,1.0][tier],maximum,false,"fixture",grade,-1,0,point)

# G-QX2-14's tighten probe (rev3.3 gherkin-delta「钩子记录探针」): the test-side subclass records the
# tighten order, whether each target is still the live record when the step returns, and the log mark
# after the step. It overrides no rule, writes no state, and `RopeArt.execute` keeps calling the same
# four factories through the same entry.
class TightenProbe extends "res://tests/game_fixture.gd":
 var steps: Array=[]
 func _reinforce_equipment(target: Dictionary, to_tier: int=0) -> String:
  var text=super._reinforce_equipment(target,to_tier)
  var live=_equipment(String(target.get("id","")))
  steps.append({"id":String(target.get("id","")),"live":not live.is_empty() and is_same(target,live),"logs":state.logs.size()})
  return text

# The tier-hook frame probe (hardener4 L1/L2, A260): every `_tier_consequences` call reachable through a
# shipped entry is recorded with the frame it ran in, its row, the previous/total it saw and what it saw
# when its own `_unit_commit` ran. It overrides no rule and writes no state beyond the record list.
class TierFrameProbe extends "res://tests/game_fixture.gd":
 var events: Array=[]
 var depth: int=0
 func _rope_boss() -> Dictionary:
  return RopeArt.master(self)
 func _rope_total() -> int:
  var boss=_rope_boss()
  return -1 if boss.is_empty() else int(boss.rope_art.total)
 func _rope_previous() -> int:
  var boss=_rope_boss()
  return -1 if boss.is_empty() else int(boss.rope_art.previous)
 func _unit_begin() -> bool:
  var owned=super._unit_begin()
  events.append({"event":"begin","owned":owned,"depth":depth,"total":_rope_total(),"previous":_rope_previous()})
  if owned: depth+=1
  return owned
 func _unit_commit(owned: bool) -> void:
  events.append({"event":"commit","owned":owned,"depth":depth,"total":_rope_total(),"previous":_rope_previous()})
  if owned: depth-=1
  super._unit_commit(owned)
 func _tier_consequences(target: Dictionary, before: int, after: int, tighten: bool) -> void:
  var row="install" if before<0 else ("tighten" if tighten else "ease")
  var record={"event":"tier","row":row,"nested":depth>0,"before":before,"after":after,"sandbox":_sandbox_depth,"previous":_rope_previous(),"total":_rope_total(),"id":String(target.get("id","")),"at":events.size()}
  events.append(record)
  super._tier_consequences(target,before,after,tighten)
  record["previous_after"]=_rope_previous()
  record["total_after"]=_rope_total()
  events.append({"event":"end","at":int(record.at)})

# G-QX2-9′: the hogtie a threshold applies joins inside the hook of the piece that caused the
# crossing, so the presentation order is host, hogtie, host -- not both hosts and then the hogtie.
static func capture_hogtie_nests_inside_join_hook(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 boss.rope_art.domain=true
 boss.rope_art.total=48
 boss.rope_art.previous=48
 g.state.guard_bind={"progress":48.0,"sources":{g.RopeArt.MASTER:{"enemy":boss.id,"energy":0}}}
 var mark=g.state.logs.size()
 g.RopeArt.execute(g,boss,{"kind":"art_domain"})
 var live=g.RopeArt.master(g)
 var applies=log_texts(g,mark).filter(func(text):return text.contains("施加了"))
 t.check(applies.size()==3 and applies[1]==live.name+"施加了驷马缚。","REMOVAL capture_hogtie_nests_inside_join_hook: the expansion's two rope applications nest the hogtie application between them, inside the second host's hook: applies="+str(applies))
 var hog=g._equipment(live.rope_art.hogtie)
 t.check(not hog.is_empty() and hog.grade==2 and g.equipment_tier(hog)==2,"REMOVAL capture_hogtie_nests_inside_join_hook: the nested application lands as one grade-two tier-two piece: id="+String(live.rope_art.hogtie))
 t.check(live.rope_art.drunk==2 and live.rope_art.total==60 and live.rope_art.stock==36,"REMOVAL capture_hogtie_nests_inside_join_hook: the three applications book twelve value and pay twelve stock, and the nested one still crosses the fifty threshold once: drunk="+str(live.rope_art.drunk)+" total="+str(live.rope_art.total)+" stock="+str(live.rope_art.stock))

# G-QX2-12: observation belongs to the top-level join hook only -- a replacement transaction's
# write-off and replay stay inside one unit, and an art application observes once, after the hogtie.
static func capture_observes_at_top_level_hook(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 boss.rope_art.domain=true
 var a=add_rope(g,"thigh","thigh_root",1,3)
 var b=add_rope(g,"thigh","thigh_root",1,3)
 var c=add_rope(g,"thigh","thigh_root",1,3)
 boss.rope_art.total=82
 boss.rope_art.previous=82
 boss.rope_art.seen50=true
 boss.rope_art.seen75=true
 boss.rope_art.values={String(a.id):4,String(b.id):4,String(c.id):4}
 var plan=Replacement.plan(g,[{"kind":"install","template":"rope","slot":"thigh","grade":2,"tier":3,"point":"thigh_root","variant":0,"locked":false}],"fixture")
 var applied=Replacement.execute(g,plan)
 t.check(plan.ok and applied.ok and plan.get("removed",[])==[String(a.id)],"REMOVAL capture_observes_at_top_level_hook: the replacement removes the value-four rope whose point is full: removed="+str(plan.get("removed",[])))
 var live=g.RopeArt.master(g)
 t.check(live.rope_art.total==83 and live.rope_art.previous==83,"REMOVAL capture_observes_at_top_level_hook: the unit writes the removal off and replays the install before its single top-level observation, so the intermediate seventy-eight never becomes previous: total="+str(live.rope_art.total)+" previous="+str(live.rope_art.previous))
 t.check(live.rope_art.hogtie=="" and live.rope_art.drunk==0,"REMOVAL capture_observes_at_top_level_hook: a nested observation of the write-off would turn the replay into an eighty crossing; none happens: hogtie="+String(live.rope_art.hogtie)+" drunk="+str(live.rope_art.drunk))
 g=encounter()
 boss=g.RopeArt.master(g)
 boss.rope_art.domain=true
 boss.rope_art.total=47
 boss.rope_art.previous=47
 var mark=g.state.logs.size()
 t.check(g.RopeArt.install(g,boss,g.RopeArt.spec(3,3)),"REMOVAL capture_observes_at_top_level_hook: the art install books and presents its piece")
 live=g.RopeArt.master(g)
 var applies=log_texts(g,mark).filter(func(text):return text.contains("施加了"))
 t.check(applies.size()==2 and applies[0].ends_with("绳索。") and applies[1]==live.name+"施加了驷马缚。","REMOVAL capture_observes_at_top_level_hook: exactly the host and then its hogtie present; the nested binding and straps add no copy: applies="+str(applies))
 t.check(live.rope_art.previous==live.rope_art.total and live.rope_art.previous==mini(100,live.rope_art.total) and live.rope_art.drunk==2,"REMOVAL capture_observes_at_top_level_hook: the single observation sees the completed total and crosses fifty once: previous="+str(live.rope_art.previous)+" total="+str(live.rope_art.total)+" drunk="+str(live.rope_art.drunk))

# G-QX2-13: the presentation charges the stock before the hook's threshold read, so a required
# hogtie that the remaining stock cannot pay is deferred instead of installed for free.
static func capture_hold_keeps_stock_before_threshold(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 boss.rope_art.domain=true
 boss.rope_art.total=47
 boss.rope_art.previous=47
 boss.rope_art.stock=4
 var before=g.state.equipment.size()
 var installed=g.RopeArt.install(g,boss,g.RopeArt.spec(2,2))
 var live=g.RopeArt.master(g)
 t.check(installed and g.state.equipment.size()==before+1,"REMOVAL capture_hold_keeps_stock_before_threshold: the affordable value-four piece still lands: pieces="+str(g.state.equipment.size()-before))
 t.check(live.rope_art.stock==0 and live.rope_art.hogtie_pending==2 and live.rope_art.refill,"REMOVAL capture_hold_keeps_stock_before_threshold: the hook reads the stock after its own payment, so the required hogtie is deferred and requests a refill: stock="+str(live.rope_art.stock)+" pending="+str(live.rope_art.hogtie_pending)+" refill="+str(live.rope_art.refill))
 t.check(live.rope_art.total==51 and live.rope_art.hogtie=="","REMOVAL capture_hold_keeps_stock_before_threshold: the deferred hogtie adds nothing and the piece still counts: total="+str(live.rope_art.total)+" hogtie="+String(live.rope_art.hogtie))

# G-QX2-14: each tightening observes through its own hook, so the crossing hogtie is applied before
# the remaining steps and enters their rebuilt target list.
static func capture_tighten_all_applies_hogtie_midway(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 boss.rope_art.domain=true
 g.state.energy=2
 for row in [["thigh","thigh_root",1,1],["thigh","mid_thigh",1,1],["thigh","above_knee",3,2],["calf","below_knee",3,3],["calf","mid_calf",3,3],["ankle","",3,3],["ankle","",3,3],["ankle","",3,2],["foot","",3,3],["foot","",3,2]]:
  add_rope(g,row[0],row[1],row[2],row[3])
 boss=g.RopeArt.master(g)
 t.check(boss.rope_art.total==49 and SelfBinding.capacity(g)>=4,"REMOVAL capture_tighten_all_applies_hogtie_midway: the fixture holds forty-nine value and at least four tightening steps: total="+str(boss.rope_art.total)+" capacity="+str(SelfBinding.capacity(g)))
 var card=Give.give(g,"self_binding")
 var command=t.find_action(g,"card",{"uid":card.uid,"free":false})
 var mark=g.state.logs.size()
 t.check(command.valid and g.dispatch(g.command(command.payload,g.state.version),g.state.version).ok,"REMOVAL capture_tighten_all_applies_hogtie_midway: the bound face commits its four steps: "+String(command.get("reason","")))
 var live=g.RopeArt.master(g)
 var tighten=g.state.logs.slice(mark).filter(func(row):return row.data.has("self_binding_tighten"))
 var targets=tighten.map(func(row):return String(row.data.self_binding_tighten.id))
 t.check(tighten.size()==4 and tighten.all(func(row):return int(row.data.self_binding_tighten.after)>int(row.data.self_binding_tighten.before)),"REMOVAL capture_tighten_all_applies_hogtie_midway: four steps raise four tiers: steps="+str(targets))
 t.check(not live.rope_art.hogtie.is_empty() and String(live.rope_art.hogtie) in targets,"REMOVAL capture_tighten_all_applies_hogtie_midway: the hogtie the mid-loop crossing applies is a later step of the same card: hogtie="+String(live.rope_art.hogtie)+" targets="+str(targets))
 t.check(live.rope_art.total==57 and live.rope_art.previous==57 and live.rope_art.drunk==2 and g.validate()=="","REMOVAL capture_tighten_all_applies_hogtie_midway: the card ends settled once: total="+str(live.rope_art.total)+" previous="+str(live.rope_art.previous)+" drunk="+str(live.rope_art.drunk)+" validate="+g.validate())

# G-QX2-14 (甲, D18) on the master face: every tightening observes through its own top-level tier hook,
# so the crossing mid-swing applies the hogtie between two tightenings -- paid from the stock and named
# once -- instead of being booked for free with no copy at the loop tail.
static func capture_master_tighten_all_pays_and_names_the_hogtie(t) -> void:
 var g=encounter(42,TightenProbe)
 var boss=g.RopeArt.master(g)
 boss.rope_art.domain=true
 for row in [["thigh","thigh_root"],["thigh","mid_thigh"],["thigh","above_knee"],["calf","below_knee"],["calf","mid_calf"],["ankle",""],["ankle",""],["foot",""],["foot",""]]:
  add_rope(g,row[0],row[1],3,2)
 boss=g.RopeArt.master(g)
 var stock=int(boss.rope_art.stock)
 var mark=g.state.logs.size()
 t.check(boss.rope_art.total==45 and stock==48 and g.RopeArt.account_issue(g)=="","REMOVAL capture_master_tighten_all_pays_and_names_the_hogtie: the nine grade-three tier-two ropes hold forty-five value against the opening stock with no ledger issue: total="+str(boss.rope_art.total)+" stock="+str(stock)+" issue="+g.RopeArt.account_issue(g))
 g.RopeArt.execute(g,boss,{"kind":"art_tighten"})
 var live=g.RopeArt.master(g)
 var texts=log_texts(g,mark)
 var named=texts.filter(func(text):return text==live.name+"施加了驷马缚。")
 t.check(named.size()==1,"REMOVAL capture_master_tighten_all_pays_and_names_the_hogtie: the mid-swing crossing applies and names exactly one hogtie: logs="+str(texts))
 t.check(g.steps.size()==9 and g.steps.all(func(step):return bool(step["live"])),"REMOVAL capture_master_tighten_all_pays_and_names_the_hogtie: the loop tightens the nine live records once each, so every target was still the record of its id: steps="+str(g.steps))
 var marks=g.steps.map(func(step):return int(step["logs"]))
 t.check(marks.size()==9 and named.size()==1 and marks[3]==mark and marks[4]==mark+1 and marks[8]==mark+1,"REMOVAL capture_master_tighten_all_pays_and_names_the_hogtie: the unit's line lands inside the fifth tightening -- four tightenings before it and four after -- not at the loop tail: marks="+str(marks)+" mark="+str(mark))
 t.check(live.rope_art.stock==stock-4,"REMOVAL capture_master_tighten_all_pays_and_names_the_hogtie: the hogtie pays its value four from the stock and the tightenings themselves pay nothing: stock="+str(live.rope_art.stock)+" before="+str(stock))
 var hog=g._equipment(String(live.rope_art.hogtie))
 var hog_tier=g.equipment_tier(hog) if not hog.is_empty() else -1
 var tightened=g.steps.map(func(step):return String(step["id"]))
 t.check(not hog.is_empty() and hog_tier==2 and String(hog.id) not in tightened,"REMOVAL capture_master_tighten_all_pays_and_names_the_hogtie: the hogtie lands at tier two and this action never tightens it (the loop keeps its opening snapshot): hogtie="+String(live.rope_art.hogtie)+" tier="+str(hog_tier))
 t.check(live.rope_art.total==58 and live.rope_art.previous==58 and live.rope_art.drunk==2 and g.RopeArt.account_issue(g)=="" and g.validate()=="","REMOVAL capture_master_tighten_all_pays_and_names_the_hogtie: the swing books fifty-eight, observes the completed total once and reconciles: total="+str(live.rope_art.total)+" previous="+str(live.rope_art.previous)+" drunk="+str(live.rope_art.drunk)+" issue="+g.RopeArt.account_issue(g)+" validate="+g.validate())

# F2 (A262, G-QX2-14 Then): the crossing hogtie's join epilogue speaks through J4 (the restraint_mana
# relic), J5 (the worn restraint_draw power) and J6 (the application copy), not only through the
# application line. The fixture reuses the shipped faces: `desire_cube` is the restraint_mana relic
# (`tests/equipment_cases.gd::_join_battle_fixture`) and `restraint_embrace`'s bound face carries the
# worn trigger. All three lines must land in the fifth tightening's step window -- after the four
# tightenings that precede the crossing and before the four that follow it -- because the crossing's
# observation and its join hook run inside that step's tier unit.
static func capture_master_tighten_all_logs_the_hogtie_epilogue(t) -> void:
 var g=encounter(42,TightenProbe)
 var boss=g.RopeArt.master(g)
 boss.rope_art.domain=true
 g.state.energy=2
 for row in [["thigh","thigh_root"],["thigh","mid_thigh"],["thigh","above_knee"],["calf","below_knee"],["calf","mid_calf"],["ankle",""],["ankle",""],["foot",""],["foot",""]]:
  add_rope(g,row[0],row[1],3,2)
 g.RelicEffects.gain(g,"desire_cube")
 var power=Give.give(g,"restraint_embrace")
 var bound=t.find_action(g,"card",{"uid":power.uid,"free":false})
 var played=bool(bound.valid) and g.dispatch(g.command(bound.payload,g.state.version),g.state.version).ok
 boss=g.RopeArt.master(g)
 # The mana hook only speaks when the relic can refill; the starting pool is not the subject here.
 g.state.mana=0
 var stock=int(boss.rope_art.stock)
 var mark=g.state.logs.size()
 t.check(played and g.state.powers.size()==1 and boss.rope_art.total==45 and stock==48,"REMOVAL capture_master_tighten_all_logs_the_hogtie_epilogue: the fixture carries the worn power and the restraint_mana relic over the nine-rope swing: played="+str(played)+" powers="+str(g.state.powers.size())+" total="+str(boss.rope_art.total)+" stock="+str(stock))
 g.RopeArt.execute(g,boss,{"kind":"art_tighten"})
 var live=g.RopeArt.master(g)
 var texts=log_texts(g,mark)
 var named=texts.filter(func(text):return text==live.name+"施加了驷马缚。")
 var mana=texts.filter(func(text):return text.begins_with("欲望魔方：佩戴驷马缚") and text.ends_with("魔力。"))
 var worn=texts.filter(func(text):return text.begins_with("拘束之拥·拘束：") and text.ends_with("张牌。"))
 var marks=g.steps.map(func(step):return int(step["logs"]))
 var mana_at=texts.find(mana[0]) if not mana.is_empty() else -1
 var worn_at=texts.find(worn[0]) if not worn.is_empty() else -1
 var named_at=texts.find(named[0]) if not named.is_empty() else -1
 var window_start=marks[3]-mark if marks.size()==9 else -1
 var window_end=marks[4]-mark if marks.size()==9 else -1
 var inside=mana_at>=window_start and worn_at>=window_start and named_at>=window_start and mana_at<window_end and worn_at<window_end and named_at<window_end
 t.check(marks.size()==9 and marks[3]==mark and window_start==0 and window_end==3 and marks[8]==mark+3 and named.size()==1 and mana.size()==1 and worn.size()==1 and inside,"REMOVAL capture_master_tighten_all_logs_the_hogtie_epilogue: the crossing hogtie's mana, worn and application lines all land inside the fifth tightening's step window -- after the four leading tightenings and before the four trailing ones: marks="+str(marks)+" mark="+str(mark)+" mana_at="+str(mana_at)+" worn_at="+str(worn_at)+" named_at="+str(named_at)+" logs="+str(texts))

# F1 (A262): this criterion guards I1 at the player face -- one in-frame application pays exactly once
# and writes exactly one copy -- and the card's OWN log order, not G-QX2-14. G-QX2-14's When is the
# master face's `art_tighten`; that scenario is covered by
# `capture_master_tighten_all_pays_and_names_the_hogtie`. The card face differs of its own accord:
# `core/self_binding.gd::resolve` emits each step copy only after `_reinforce_equipment` returns, so
# the hogtie's application line (written inside that call) necessarily precedes the trigger step's
# copy. The assertion below pins that order as the card's current statement order, not as a mapping
# of the scenario.
static func capture_card_tighten_all_pays_and_names_the_hogtie(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 boss.rope_art.domain=true
 g.state.energy=2
 for row in [["thigh","thigh_root",1,1],["thigh","mid_thigh",1,1],["thigh","above_knee",3,2],["calf","below_knee",3,3],["calf","mid_calf",3,3],["ankle","",3,3],["ankle","",3,3],["ankle","",3,2],["foot","",3,3],["foot","",3,2]]:
  add_rope(g,row[0],row[1],row[2],row[3])
 boss=g.RopeArt.master(g)
 var stock=int(boss.rope_art.stock)
 t.check(boss.rope_art.total==49 and stock==48,"REMOVAL capture_card_tighten_all_pays_and_names_the_hogtie: the card fixture holds forty-nine value against the opening stock: total="+str(boss.rope_art.total)+" stock="+str(stock))
 var card=Give.give(g,"self_binding")
 var command=t.find_action(g,"card",{"uid":card.uid,"free":false})
 var mark=g.state.logs.size()
 t.check(command.valid and g.dispatch(g.command(command.payload,g.state.version),g.state.version).ok,"REMOVAL capture_card_tighten_all_pays_and_names_the_hogtie: the bound face commits its steps: "+String(command.get("reason","")))
 var live=g.RopeArt.master(g)
 var texts=log_texts(g,mark)
 var named=texts.filter(func(text):return text==live.name+"施加了驷马缚。")
 t.check(named.size()==1,"REMOVAL capture_card_tighten_all_pays_and_names_the_hogtie: the mid-card crossing names the hogtie exactly once: logs="+str(texts))
 t.check(live.rope_art.stock==stock-4,"REMOVAL capture_card_tighten_all_pays_and_names_the_hogtie: the hogtie pays its value four from the stock and tightening itself costs nothing: stock="+str(live.rope_art.stock)+" before="+str(stock))
 var steps=texts.filter(func(text):return text.begins_with("自缚：") and text.contains("紧度"))
 t.check(steps.size()==4,"REMOVAL capture_card_tighten_all_pays_and_names_the_hogtie: the card still completes its four steps after the mid-card hogtie: steps="+str(steps))
 var named_at=texts.find(named[0]) if not named.is_empty() else -1
 var first_step=texts.find(steps[0]) if not steps.is_empty() else -1
 t.check(named_at>=0 and first_step>named_at,"REMOVAL capture_card_tighten_all_pays_and_names_the_hogtie: the unit's line precedes the card's own step copy, because the card writes that copy after the tighten call returns: named_at="+str(named_at)+" first_step="+str(first_step)+" logs="+str(texts))
 t.check(live.rope_art.previous==live.rope_art.total and live.rope_art.drunk==2 and g.RopeArt.account_issue(g)=="" and g.validate()=="","REMOVAL capture_card_tighten_all_pays_and_names_the_hogtie: the card ends settled once and reconciles: total="+str(live.rope_art.total)+" previous="+str(live.rope_art.previous)+" drunk="+str(live.rope_art.drunk)+" issue="+g.RopeArt.account_issue(g)+" validate="+g.validate())

# I2 (甲, D21); the premise G-QX2-19 rests on: T books inside its own unit but never observes from
# within an enclosing one, so a framed tighten cannot rewrite `previous` or apply the hogtie mid-unit.
# The enclosing frame is opened by hand because no shipped entry tightens inside an accepted unit; the
# criterion pins the invariant, and the first top-level observation settles the crossing once.
static func capture_tier_hook_defers_observation_to_the_owning_unit(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 boss.rope_art.domain=true
 var piece=add_rope(g,"thigh","above_knee",3,2)
 for row in [["thigh","thigh_root",1,1],["thigh","mid_thigh",1,1],["calf","below_knee",3,3],["calf","mid_calf",3,3],["ankle","",3,3],["ankle","",3,3],["ankle","",3,2],["foot","",3,3],["foot","",3,2]]:
  add_rope(g,row[0],row[1],row[2],row[3])
 boss=g.RopeArt.master(g)
 t.check(boss.rope_art.total==49 and not piece.is_empty() and g.RopeArt.account_issue(g)=="","REMOVAL capture_tier_hook_defers_observation_to_the_owning_unit: the fixture holds forty-nine value with the tier-two thigh rope first: total="+str(boss.rope_art.total)+" issue="+g.RopeArt.account_issue(g))
 var owned=g._unit_begin()
 g._reinforce_equipment(piece)
 boss=g.RopeArt.master(g)
 t.check(boss.rope_art.total==50 and boss.rope_art.previous==49 and boss.rope_art.drunk==0 and String(boss.rope_art.hogtie)=="","REMOVAL capture_tier_hook_defers_observation_to_the_owning_unit: a framed tighten books the fifty crossing but leaves it unobserved: total="+str(boss.rope_art.total)+" previous="+str(boss.rope_art.previous)+" drunk="+str(boss.rope_art.drunk)+" hogtie="+String(boss.rope_art.hogtie))
 g._unit_commit(owned)
 boss=g.RopeArt.master(g)
 t.check(boss.rope_art.previous==49 and boss.rope_art.drunk==0 and String(boss.rope_art.hogtie)=="","REMOVAL capture_tier_hook_defers_observation_to_the_owning_unit: the owning commit joins nothing, so the crossing still waits for the next declared observation point: previous="+str(boss.rope_art.previous)+" drunk="+str(boss.rope_art.drunk)+" hogtie="+String(boss.rope_art.hogtie))
 g.RopeArt.observe(g)
 boss=g.RopeArt.master(g)
 t.check(boss.rope_art.drunk==2 and not String(boss.rope_art.hogtie).is_empty() and boss.rope_art.previous==boss.rope_art.total and g.RopeArt.account_issue(g)=="","REMOVAL capture_tier_hook_defers_observation_to_the_owning_unit: the next top-level observation settles the crossing exactly once: total="+str(boss.rope_art.total)+" previous="+str(boss.rope_art.previous)+" drunk="+str(boss.rope_art.drunk)+" hogtie="+String(boss.rope_art.hogtie)+" issue="+g.RopeArt.account_issue(g))

# L1 (hardener4, A260): the runtime census behind "a nested tier hook never observes". Every tier-hook
# call a shipped entry can reach is recorded by the frame probe: the install rows run inside the
# installing unit's own frame, never book and never observe; a booked row (tighten/ease) only runs at
# the top level, and the hogtie its crossing applies opens its own frame at depth zero after that unit
# committed. F3 (A262): the census below is only the three fixtures this criterion builds, so every
# message that reads it speaks for the fixture census, never for every shipped entry. The guards for
# the cells the census cannot drive are quoted in tmp/io-qx2/hardener4/notes.md §1-2.
static func capture_tier_hook_never_nests_a_booked_observation(t) -> void:
 var installed=encounter(42,TierFrameProbe)
 var installs_boss=installed.RopeArt.master(installed)
 installed.RopeArt.execute(installed,installs_boss,{"kind":"art_domain"})
 installed.RopeArt.install(installed,installs_boss,installed.RopeArt.spec(3,3))
 installed._install_special("crotch_rope_low","special_3_a")
 var installs=installed.events.filter(func(row):return String(row.event)=="tier" and String(row.row)=="install")
 var unobserved=installs.filter(func(row):return bool(row.nested) and int(row.previous_after)==int(row.previous) and int(row.total_after)==int(row.total))
 t.check(installs.size()>=4 and unobserved.size()==installs.size(),"REMOVAL capture_tier_hook_never_nests_a_booked_observation: every install row runs inside the installing unit's own frame and never books or observes there: installs="+str(installs.size())+" unobserved="+str(unobserved.size())+" rows="+str(installs.map(func(row):return [String(row.row),bool(row.nested),int(row.total),int(row.total_after),int(row.previous),int(row.previous_after)])))
 var g=encounter(42,TierFrameProbe)
 var boss=g.RopeArt.master(g)
 boss.rope_art.domain=true
 for row in [["thigh","thigh_root"],["thigh","mid_thigh"],["thigh","above_knee"],["calf","below_knee"],["calf","mid_calf"],["ankle",""],["ankle",""],["foot",""],["foot",""]]:
  add_rope(g,row[0],row[1],3,2)
 boss=g.RopeArt.master(g)
 t.check(boss.rope_art.total==45,"REMOVAL capture_tier_hook_never_nests_a_booked_observation: the swing fixture holds forty-five value: total="+str(boss.rope_art.total))
 var mark=g.events.size()
 g.RopeArt.execute(g,boss,{"kind":"art_tighten"})
 boss=g.RopeArt.master(g)
 g.RopeArt.hogtie(g,boss,3)
 var victim={}
 for item in g.action_targets():
  if g.RopeArt.is_rope(item) and g.equipment_tier(item)==3:
   victim=item
   break
 t.check(not victim.is_empty(),"REMOVAL capture_tier_hook_never_nests_a_booked_observation: the swing leaves a tier-three rope for the ease row")
 g._apply_equipment_damage(victim,float(victim.durability)-g.RestraintValue.durability_for(victim.maximum,1)+0.000001,"strain")
 var top_level=g.events.slice(mark).filter(func(row):return String(row.event)=="tier" and String(row.row)!="install" and not bool(row.nested) and int(row.sandbox)==0)
 var holding=[]
 for row in top_level:
  if not (String(row.row)=="tighten" or int(row.before)!=int(row.after)): continue
  var commit_at=-1
  var end_at=-1
  for index in range(int(row.at)+1,g.events.size()):
   var event=g.events[index]
   if String(event.event)=="commit" and bool(event.owned) and commit_at<0: commit_at=index
   if String(event.event)=="end" and int(event.at)==int(row.at): end_at=index; break
  if commit_at<0 or end_at<0: continue
  for index in range(commit_at+1,end_at):
   var event=g.events[index]
   if String(event.event)=="begin" and bool(event.owned) and int(event.depth)==0:
    holding.append({"record":row,"begin":index,"total":int(event.total)})
    break
 var hog_id=String(g.RopeArt.master(g).rope_art.hogtie)
 var hog_install=g.events.filter(func(event):return String(event.event)=="tier" and String(event.row)=="install" and String(event.id)==hog_id)
 t.check(hog_id!="" and holding.size()==1 and hog_install.size()==1 and int(hog_install[0].at)>int(holding[0].begin) and int(holding[0].total)==50,"REMOVAL capture_tier_hook_never_nests_a_booked_observation: the crossing hogtie opens its own unit at depth zero after the tier unit committed, so its join hook runs inside that scope: hogtie="+hog_id+" holding="+str(holding.size())+" begin_total="+str(holding[0].total if not holding.is_empty() else -1))
 var stale=top_level.filter(func(row):return int(row.previous_after)!=mini(100,int(row.total_after)))
 t.check(top_level.size()>=10 and stale.is_empty(),"REMOVAL capture_tier_hook_never_nests_a_booked_observation: every top-level booked row leaves previous on the completed total, i.e. it observes after its own unit closed: rows="+str(top_level.size())+" stale="+str(stale.map(func(row):return [String(row.row),int(row.previous_after),int(row.total_after)])))
 var sandbox_g=encounter(1,TierFrameProbe)
 var sandbox_boss=sandbox_g.RopeArt.master(sandbox_g)
 sandbox_g.RopeArt.execute(sandbox_g,sandbox_boss,{"kind":"art_domain"})
 for index in range(sandbox_g._capacity(sandbox_g.Links.point_slot("upper_arm_top"))):
  add_rope(sandbox_g,"upper_arm","upper_arm_top",1,3)
 sandbox_boss=sandbox_g.RopeArt.master(sandbox_g)
 sandbox_boss.rope_art.previous=int(sandbox_boss.rope_art.total)
 sandbox_boss.rope_art.seen50=true
 sandbox_boss.rope_art.seen75=true
 var plan=Replacement.plan(sandbox_g,[{"kind":"install","template":"rope","slot":"upper_arm","grade":3,"tier":3,"point":"upper_arm_top","variant":0,"locked":false}],"fixture")
 var applied=Replacement.execute(sandbox_g,plan) if plan.ok else {}
 t.check(bool(plan.ok) and bool(applied.get("ok",false)),"REMOVAL capture_tier_hook_never_nests_a_booked_observation: the replacement fixture commits: "+String(plan.get("reason","")))
 var sandboxed=sandbox_g.events.filter(func(row):return String(row.event)=="tier" and int(row.sandbox)>0)
 var sandboxed_moved=sandboxed.filter(func(row):return int(row.previous_after)!=int(row.previous))
 t.check(sandboxed.size()>=1 and sandboxed_moved.is_empty(),"REMOVAL capture_tier_hook_never_nests_a_booked_observation: a sandboxed ease row keeps the physical layer but drops its frame, and no observation runs inside it: rows="+str(sandboxed.size())+" moved="+str(sandboxed_moved.size()))
 var census=installed.events.filter(func(row):return String(row.event)=="tier")+g.events.filter(func(row):return String(row.event)=="tier")+sandbox_g.events.filter(func(row):return String(row.event)=="tier")
 var booked=census.filter(func(row):return String(row.row)!="install" and (String(row.row)=="tighten" or int(row.before)!=int(row.after)))
 var nested_booked=booked.filter(func(row):return bool(row.nested))
 t.check(booked.size()>=10 and nested_booked.is_empty(),"REMOVAL capture_tier_hook_never_nests_a_booked_observation: within the fixture census, no booked tier hook a shipped entry drives runs from inside another unit: booked="+str(booked.size())+" nested="+str(nested_booked.size())+" rows="+str(nested_booked.map(func(row):return [String(row.row),int(row.before),int(row.after)])))

# L2 (hardener4, A260): an ease row that drops the total across a line keeps the fixed observation
# point. The grade-three tier-three rope falls to tier one (six to four), so the total falls from
# fifty-one to forty-nine under the fifty line: the tier unit accounts the drop, commits, and only then
# observes, so previous follows the drop instead of keeping the pre-drop fifty-one; the fifty flag is
# already set, so a downward crossing never drinks a second time.
static func capture_ease_crossing_keeps_previous_after_the_unit(t) -> void:
 var g=encounter(42,TierFrameProbe)
 var boss=g.RopeArt.master(g)
 boss.rope_art.domain=false
 for row in [["thigh","thigh_root",3,2],["thigh","mid_thigh",3,2],["thigh","above_knee",3,2],["calf","below_knee",3,3],["calf","mid_calf",3,2],["ankle","",3,2],["ankle","",3,2],["ankle","",3,2],["foot","",3,2],["foot","",3,2]]:
  add_rope(g,row[0],row[1],row[2],row[3])
 boss=g.RopeArt.master(g)
 boss.rope_art.domain=true
 boss.rope_art.previous=int(boss.rope_art.total)
 boss.rope_art.seen50=true
 boss.rope_art.seen75=true
 boss.rope_art.drunk=2
 var victim={}
 for item in g.action_targets():
  if g.RopeArt.is_rope(item) and g.equipment_tier(item)==3:
   victim=item
   break
 t.check(boss.rope_art.total==51 and not victim.is_empty() and g.RopeArt.account_issue(g)=="","REMOVAL capture_ease_crossing_keeps_previous_after_the_unit: the fixture holds fifty-one value with one tier-three rope: total="+str(boss.rope_art.total)+" issue="+g.RopeArt.account_issue(g))
 var mark=g.events.size()
 g._apply_equipment_damage(victim,float(victim.durability)-g.RestraintValue.durability_for(victim.maximum,1)+0.000001,"strain")
 boss=g.RopeArt.master(g)
 t.check(g.equipment_tier(victim)==1 and boss.rope_art.total==49,"REMOVAL capture_ease_crossing_keeps_previous_after_the_unit: the ease write drops the rope two tiers and the total under the fifty line: tier="+str(g.equipment_tier(victim))+" total="+str(boss.rope_art.total))
 t.check(boss.rope_art.previous==49 and boss.rope_art.drunk==2 and String(boss.rope_art.hogtie)=="","REMOVAL capture_ease_crossing_keeps_previous_after_the_unit: previous follows the drop and the downward crossing drinks nothing: previous="+str(boss.rope_art.previous)+" drunk="+str(boss.rope_art.drunk)+" hogtie="+String(boss.rope_art.hogtie))
 var rows=g.events.slice(mark).filter(func(row):return String(row.event)=="tier")
 var record=rows[0] if rows.size()==1 else {}
 var commit_previous=-1
 if not record.is_empty():
  for index in range(int(record.at)+1,g.events.size()):
   var event=g.events[index]
   if String(event.event)=="commit" and bool(event.owned):
    commit_previous=int(event.previous)
    break
 t.check(not record.is_empty() and String(record.row)=="ease" and not bool(record.nested) and int(record.before)==3 and int(record.after)==1 and commit_previous==51 and int(record.previous_after)==49 and int(record.total_after)==49,"REMOVAL capture_ease_crossing_keeps_previous_after_the_unit: the ease unit commits before the observation, so previous is still fifty-one at the commit and forty-nine after it: record="+str(record)+" commit_previous="+str(commit_previous))
 t.check(g.RopeArt.account_issue(g)=="" and g.validate()=="","REMOVAL capture_ease_crossing_keeps_previous_after_the_unit: the eased state reconciles: issue="+g.RopeArt.account_issue(g)+" validate="+g.validate())

# G-QX2-19: a removal is observed once, outside the unit that wrote it off, so the damaged piece and
# the later purge both leave previous equal to the recomputed total instead of a stale pre-unit value.
static func capture_removal_observes_outside_units(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 boss.rope_art.domain=true
 boss.rope_art.seen50=true
 boss.rope_art.seen75=true
 var maximum=g.Equipment.maximum(3)
 var arm=g._install_template("rope","upper_arm",maximum,maximum,false,"fixture",3)
 var straps=g.Shoulders.pieces(g).filter(func(item):return String(item.get("shoulder_host",""))==String(arm.id))
 t.check(straps.size()==2,"REMOVAL capture_removal_observes_outside_units: the tier-three arm fixture grows two rope straps: straps="+str(straps.size()))
 boss.rope_art.total=96
 boss.rope_art.previous=96
 g._apply_equipment_damage(arm,999,"strain")
 t.check(boss.rope_art.total==90 and boss.rope_art.previous==90,"REMOVAL capture_removal_observes_outside_units: the damage hook observes the post-removal total once: total="+str(boss.rope_art.total)+" previous="+str(boss.rope_art.previous))
 g._cleanup()
 t.check(boss.rope_art.previous==boss.rope_art.total and boss.rope_art.total<90,"REMOVAL capture_removal_observes_outside_units: the purge writes off its closure first and observes afterwards, so previous is the purged total: previous="+str(boss.rope_art.previous)+" total="+str(boss.rope_art.total))
 var added=0
 while boss.rope_art.total<90 and added<3:
  add_rope(g,["upper_arm","forearm","wrist"][added],"",3,3)
  added+=1
 boss=g.RopeArt.master(g)
 t.check(boss.rope_art.total>=90 and boss.rope_art.previous==mini(100,boss.rope_art.total) and boss.rope_art.drunk==2,"REMOVAL capture_removal_observes_outside_units: the refill pieces cross ninety from the purged total and drink once: total="+str(boss.rope_art.total)+" previous="+str(boss.rope_art.previous)+" drunk="+str(boss.rope_art.drunk))

# G-QX2-20: the self-binding card keeps resolving after the hogtie its first install triggers, on both
# faces -- the free face installs its second piece, the bound face finishes all four tightening steps.
static func self_binding_survives_midway_hogtie(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 boss.rope_art.domain=true
 for row in [["thigh","thigh_root",3,3],["thigh","mid_thigh",3,3],["thigh","above_knee",3,3],["calf","below_knee",3,3],["calf","mid_calf",3,3],["ankle","",3,3],["ankle","",3,3],["foot","",2,3]]:
  add_rope(g,row[0],row[1],row[2],row[3])
 boss=g.RopeArt.master(g)
 t.check(boss.rope_art.total==47,"REMOVAL self_binding_survives_midway_hogtie: the free-face fixture holds forty-seven value: total="+str(boss.rope_art.total))
 g.state.energy=2
 var card=Give.give(g,"self_binding")
 var mark=g.state.logs.size()
 var command=t.find_action(g,"card",{"uid":card.uid,"free":true})
 t.check(command.valid and g.dispatch(g.command(command.payload,g.state.version),g.state.version).ok,"REMOVAL self_binding_survives_midway_hogtie: the free face commits both installs: "+String(command.get("reason","")))
 var live=g.RopeArt.master(g)
 var texts=log_texts(g,mark)
 var installs=texts.filter(func(text):return text.begins_with("自缚：在"))
 var hogtie_line=live.name+"施加了驷马缚。"
 t.check(installs.size()==2 and hogtie_line in texts and texts.find(hogtie_line)<texts.find(installs[0]),"REMOVAL self_binding_survives_midway_hogtie: the hogtie application the first install's hook triggers precedes both self-binding lines, so the card keeps running: logs="+str(texts))
 t.check(not live.rope_art.hogtie.is_empty() and live.rope_art.drunk==2 and g.state.equipment.size()==11 and g.validate()=="","REMOVAL self_binding_survives_midway_hogtie: the mid-card hogtie lands, drinks once, and the second install still lands: hogtie="+String(live.rope_art.hogtie)+" drunk="+str(live.rope_art.drunk)+" pieces="+str(g.state.equipment.size())+" validate="+g.validate())
 g=encounter()
 boss=g.RopeArt.master(g)
 boss.rope_art.domain=true
 g.state.energy=2
 for row in [["thigh","thigh_root",1,1],["thigh","mid_thigh",1,1],["thigh","above_knee",3,2],["calf","below_knee",3,3],["calf","mid_calf",3,3],["ankle","",3,3],["ankle","",3,3],["ankle","",3,2],["foot","",3,3],["foot","",3,2]]:
  add_rope(g,row[0],row[1],row[2],row[3])
 boss=g.RopeArt.master(g)
 t.check(boss.rope_art.total==49 and SelfBinding.capacity(g)>=4,"REMOVAL self_binding_survives_midway_hogtie: the bound-face fixture holds forty-nine value and enough tightening steps: total="+str(boss.rope_art.total)+" capacity="+str(SelfBinding.capacity(g)))
 card=Give.give(g,"self_binding")
 mark=g.state.logs.size()
 command=t.find_action(g,"card",{"uid":card.uid,"free":false})
 var bound=g.dispatch(g.command(command.payload,g.state.version),g.state.version)
 live=g.RopeArt.master(g)
 var tighten=g.state.logs.slice(mark).filter(func(row):return row.data.has("self_binding_tighten"))
 var targets=tighten.map(func(row):return String(row.data.self_binding_tighten.id))
 t.check(bound.ok,"REMOVAL self_binding_survives_midway_hogtie: the bound face finishes instead of aborting on the mid-card hogtie: "+String(command.get("reason","")))
 t.check(tighten.size()==4 and (String(live.rope_art.hogtie) in targets),"REMOVAL self_binding_survives_midway_hogtie: all four steps complete and the mid-card hogtie is among their targets: steps="+str(targets)+" hogtie="+String(live.rope_art.hogtie))
 t.check(live.rope_art.drunk==2 and live.rope_art.previous==live.rope_art.total and g.validate()=="","REMOVAL self_binding_survives_midway_hogtie: the card ends settled once: previous="+str(live.rope_art.previous)+" total="+str(live.rope_art.total)+" drunk="+str(live.rope_art.drunk)+" validate="+g.validate())

# G-QX2-16 (原 G-QX5-2): a new hogtie no longer settles the foreign writes of the same submit. A piece
# already damaged to zero stays in its container until the next declared settle point removes it.
static func hogtie_install_leaves_foreign_writes_to_settle_points(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 boss.rope_art.domain=true
 var victim=add_rope(g,"thigh","thigh_root",1,3)
 g._apply_equipment_damage(victim,999,"strain")
 var zeroed=g._equipment(String(victim.id))
 t.check(not zeroed.is_empty() and float(zeroed.durability)<=0.000001,"REMOVAL hogtie_install_leaves_foreign_writes_to_settle_points: the damaged piece is zeroed but still in the container, so the settle point owns its removal: id="+String(victim.get("id",""))+" present="+str(not zeroed.is_empty()))
 var mark=g.state.logs.size()
 g.RopeArt.hogtie(g,boss,2)
 var live=g.RopeArt.master(g)
 t.check(not live.is_empty() and not String(live.rope_art.hogtie).is_empty() and not g._equipment(String(victim.id)).is_empty(),"REMOVAL hogtie_install_leaves_foreign_writes_to_settle_points: the new hogtie returns without settling the zeroed foreign piece: hogtie="+String(live.get("rope_art",{}).get("hogtie",""))+" present="+str(not g._equipment(String(victim.id)).is_empty()))
 g._cleanup()
 t.check(g._equipment(String(victim.id)).is_empty() and log_texts(g,mark).any(func(text):return text.ends_with("已解除。")),"REMOVAL hogtie_install_leaves_foreign_writes_to_settle_points: the next declared settle point removes it and emits the release line: logs="+str(log_texts(g,mark)))

# G-QX2-15 (原 G-QX5-1): a rope-master install no longer settles either, so a zeroed foreign piece waits
# for the next declared settle point.
static func rope_install_leaves_foreign_writes_to_settle_points(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 boss.rope_art.domain=true
 var victim=add_rope(g,"thigh","thigh_root",1,3)
 g._apply_equipment_damage(victim,999,"strain")
 var zeroed=g._equipment(String(victim.id))
 t.check(not zeroed.is_empty() and float(zeroed.durability)<=0.000001,"REMOVAL rope_install_leaves_foreign_writes_to_settle_points: the damaged piece is zeroed but still in the container: id="+String(victim.get("id",""))+" present="+str(not zeroed.is_empty()))
 var mark=g.state.logs.size()
 var installed=g.RopeArt.install(g,boss,g.RopeArt.spec(1,2))
 t.check(installed and not g._equipment(String(victim.id)).is_empty(),"REMOVAL rope_install_leaves_foreign_writes_to_settle_points: the install returns after applying its own piece and leaves the zeroed foreign piece in the container: installed="+str(installed)+" present="+str(not g._equipment(String(victim.id)).is_empty()))
 g._cleanup()
 t.check(g._equipment(String(victim.id)).is_empty() and log_texts(g,mark).any(func(text):return text.ends_with("已解除。")),"REMOVAL rope_install_leaves_foreign_writes_to_settle_points: the next declared settle point removes it and emits the release line: logs="+str(log_texts(g,mark)))

# QX2'' second round (rev3.2 G-QX2-2 input domain: 记录类别 股绳 x C2a): `cord` is the other ordinary
# template the master's own spec names. It carries rope material, so the same join hook must book it.
static func capture_accounts_cord_at_install(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 g.RopeArt.execute(g,boss,{"kind":"art_domain"})
 var installed=g.RopeArt.install(g,boss,{"pool":"ordinary","templates":["cord"],"grade":3,"tier":3,"count":1,"replace":true,"allow_links":false})
 var live=g.RopeArt.master(g)
 var cords=g.state.equipment.filter(func(e):return String(e.get("template",""))=="cord")
 var id=String(cords[0].id) if not cords.is_empty() else ""
 t.check(installed and cords.size()==1 and String(cords[0].get("material",""))=="rope" and g.equipment_tier(cords[0])==3,"REMOVAL capture_accounts_cord_at_install: the application installs one tier-three cord -- the small-slot template the master's spec names -- at rope material: installed="+str(installed)+" cords="+str(cords.size()))
 t.check(id!="" and int(Dictionary(live.rope_art.values).get(id,-1))==int(g.RestraintValue.from_profile(3,3)),"REMOVAL capture_accounts_cord_at_install: the cord is booked at its join hook with the published profile value, exactly like a rope piece: id="+id+" value="+str(Dictionary(live.rope_art.values).get(id,"missing"))+" expected="+str(int(g.RestraintValue.from_profile(3,3))))
 ledger_matches(t,g,"capture_accounts_cord_at_install")

# QX2'' second round (记录类别 杯 x C2a/C2d): the full cup family is plastic, so neither the cup nor its
# leather reinforcement strap may enter the ledger, and forcing the high cup replaces both without a row.
static func capture_ignores_cup_special_closure(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 g.RopeArt.execute(g,boss,{"kind":"art_domain"})
 var before=Dictionary(boss.rope_art.values).duplicate(true)
 var cup=g._install_special("urethral_full_cup_medium","special_2_a",3)
 var strap=g.state.special_equipment.filter(func(item):return g.SpecialEquipment.reinforcement_matches(item,cup))
 var live=g.RopeArt.master(g)
 var extras=Dictionary(live.rope_art.values).keys().filter(func(id):return not before.has(String(id)))
 t.check(not cup.is_empty() and String(cup.get("type",""))=="urethral_full_cup_medium" and String(cup.get("material",""))=="plastic" and strap.size()==1 and String(strap[0].get("material",""))=="leather","REMOVAL capture_ignores_cup_special_closure: the medium full cup installs as plastic with its leather reinforcement strap: cup="+String(cup.get("type","missing"))+" straps="+str(strap.size()))
 t.check(extras.is_empty() and Dictionary(live.rope_art.values)==before,"REMOVAL capture_ignores_cup_special_closure: neither the plastic cup nor its leather strap enters the capture ledger: extra="+str(extras))
 var forced=Replacement.force_special(g,"urethral_full_cup_high",3,"fixture")
 var after=g.RopeArt.master(g)
 var swapped=g.state.special_equipment.filter(func(item):return String(item.get("type",""))=="urethral_full_cup_high")
 t.check(bool(forced.get("ok",false)) and swapped.size()==1 and g._equipment(String(cup.id)).is_empty() and Dictionary(after.rope_art.values)==before,"REMOVAL capture_ignores_cup_special_closure: forcing the high cup replaces the medium cup and its strap without adding any ledger row: ok="+str(forced.get("ok",false))+" swapped="+str(swapped.size())+" removed="+str(g._equipment(String(cup.id)).is_empty()))
 ledger_matches(t,g,"capture_ignores_cup_special_closure")

# QX2'' second round (记录类别 链接 x C2b): a wrist-to-palm link loses its anchor when the wrist leaves,
# so the purge takes the link with the host and writes its id off the ledger.
static func capture_unaccounts_link_without_anchor(t) -> void:
 var g=encounter(1)
 var boss=g.RopeArt.master(g)
 g.RopeArt.execute(g,boss,{"kind":"art_domain"})
 var wrist=g._install_template("rope","wrist",6.4,8.0,false,"fixture")
 var palm=g._install_template(g.Equipment.default_template("palm"),"palm",6.4,8.0,false,"fixture")
 var link=g._install_link(wrist.id,palm.id,6.4,"fixture",1,[],["wrist","palm"],["wrist","palm_left"])
 var live=g.RopeArt.master(g)
 t.check(not link.is_empty() and Dictionary(live.rope_art.values).has(String(link.get("id",""))),"REMOVAL capture_unaccounts_link_without_anchor: the wrist-to-palm link installs and its id is booked before the anchor leaves: link="+String(link.get("id","missing")))
 ledger_matches(t,g,"capture_unaccounts_link_without_anchor")
 var mark=g.state.logs.size()
 g._apply_equipment_damage(wrist,999,"strain")
 g._cleanup()
 var after=g.RopeArt.master(g)
 t.check(g.state.links.is_empty() and not Dictionary(after.rope_art.values).has(String(link.get("id",""))),"REMOVAL capture_unaccounts_link_without_anchor: the purge takes the link with its lost anchor and writes its id off the ledger: links="+str(g.state.links.size())+" booked="+str(Dictionary(after.rope_art.values).has(String(link.get("id","")))))
 t.check(log_texts(g,mark).any(func(text):return text.contains("这条链接随之移除")),"REMOVAL capture_unaccounts_link_without_anchor: the settle point reports the anchor loss as the link's removal: logs="+str(log_texts(g,mark)))
 t.check(int(after.rope_art.total)==8 and Dictionary(after.rope_art.values).size()==2,"REMOVAL capture_unaccounts_link_without_anchor: only the two domain pieces remain booked after the host and its link leave: total="+str(after.rope_art.total)+" values="+str(after.rope_art.values))
 ledger_matches(t,g,"capture_unaccounts_link_without_anchor")

# QX2'' second round (来源 助理 x C2a): the assistant's own patch application installs rope stock
# through `RopeArt.install` (own=false), so every piece it applies must be booked and presented once.
static func capture_accounts_assistant_installs(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 g.RopeArt.execute(g,boss,{"kind":"art_domain"})
 g.RopeArt.summon(g,boss)
 var helper=g.RopeArt.assistant(g)
 var mark=g.state.logs.size()
 g.RopeArt.execute(g,helper,{"kind":"art_patch"})
 var live=g.RopeArt.master(g)
 var fresh=g.state.equipment.filter(func(e):return String(e.get("source",""))==String(helper.id))
 var booked=fresh.filter(func(e):return Dictionary(live.rope_art.values).has(String(e.id)))
 t.check(not helper.is_empty() and fresh.size()==8 and fresh.all(func(e):return g.RopeArt.is_rope(e)),"REMOVAL capture_accounts_assistant_installs: the assistant's patch fills the eight remaining arm and leg positions with rope stock: pieces="+str(fresh.size())+" helper="+String(helper.get("id","missing")))
 t.check(booked.size()==fresh.size(),"REMOVAL capture_accounts_assistant_installs: every piece the assistant installs is booked at its join hook: booked="+str(booked.size())+"/"+str(fresh.size())+" absent="+str(fresh.filter(func(e):return not Dictionary(live.rope_art.values).has(String(e.id))).map(func(e):return String(e.id))))
 var presented=log_texts(g,mark).filter(func(text):return text.contains(String(helper.get("name",""))+"施加了"))
 t.check(presented.size()==fresh.size()+1,"REMOVAL capture_accounts_assistant_installs: each assistant application presents once through its own scope -- the eight pieces plus the crotch rope: lines="+str(presented.size())+" pieces="+str(fresh.size()))
 ledger_matches(t,g,"capture_accounts_assistant_installs")

# QX2'' second round (战斗 战斗外): after a real surrender the master record is retained but the phase is
# no longer battle, so the same install entry must land the piece without writing any ledger row.
static func capture_writes_nothing_outside_battle(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 g.RopeArt.execute(g,boss,{"kind":"art_domain"})
 var result=g.dispatch(g.command({"kind":"surrender"},g.state.version),g.state.version)
 var retained=g.state.enemies.filter(func(row):return row.type==g.RopeArt.MASTER)
 t.check(result.ok and g.state.phase=="captured" and retained.size()==1,"REMOVAL capture_writes_nothing_outside_battle: a real surrender reaches the captured phase with the master record still in state: ok="+str(result.ok)+" phase="+g.state.phase+" retained="+str(retained.size()))
 var snapshot={"values":Dictionary(retained[0].rope_art.values).duplicate(true),"total":int(retained[0].rope_art.total),"previous":int(retained[0].rope_art.previous)}
 var pieces=g.state.equipment.size()
 var installed=g.RopeArt.install(g,retained[0],g.RopeArt.spec(3,3))
 var now={"values":Dictionary(retained[0].rope_art.values).duplicate(true),"total":int(retained[0].rope_art.total),"previous":int(retained[0].rope_art.previous)}
 t.check(installed and g.state.equipment.size()==pieces+1,"REMOVAL capture_writes_nothing_outside_battle: the install entry still applies the rope piece outside battle: installed="+str(installed)+" pieces="+str(g.state.equipment.size()-pieces))
 t.check(now==snapshot,"REMOVAL capture_writes_nothing_outside_battle: the retained master record keeps its ledger and observation values byte for byte, so the install wrote no row outside the battle phase: now="+str(now)+" before="+str(snapshot))
 t.check(g.RopeArt.master(g).is_empty() and g.RopeArt.account_issue(g)=="","REMOVAL capture_writes_nothing_outside_battle: the master lookup and the debug recount both stay empty outside battle: master_absent="+str(g.RopeArt.master(g).is_empty())+" issue="+g.RopeArt.account_issue(g))

# F3 (A257): G-QX2-6's third situation -- the master is gone but the record is still retained -- has no
# runtime assertion yet. The battle-end sweep can run in that window, so the guard is pinned on it: a
# non-rope source install books nothing and the debug recount has nothing to compare.
static func capture_departed_master_books_nothing(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 g.RopeArt.execute(g,boss,{"kind":"art_domain"})
 boss=g.RopeArt.master(g)
 var before={"values":Dictionary(boss.rope_art.values).duplicate(true),"total":int(boss.rope_art.total),"previous":int(boss.rope_art.previous)}
 var pieces=g.state.equipment.size()
 boss.gone=true
 var installed=add_rope(g,"upper_arm","",3,3)
 var now={"values":Dictionary(boss.rope_art.values).duplicate(true),"total":int(boss.rope_art.total),"previous":int(boss.rope_art.previous)}
 t.check(not installed.is_empty() and g.state.equipment.size()==pieces+1,"REMOVAL capture_departed_master_books_nothing: the rope piece still lands physically after the master is gone, so only the ledger can tell the departure: installed="+str(not installed.is_empty())+" pieces="+str(g.state.equipment.size()-pieces))
 t.check(g.RopeArt.master(g).is_empty() and now==before,"REMOVAL capture_departed_master_books_nothing: a gone master is no ledger owner, so the same install writes no value and no observation: now="+str(now)+" before="+str(before))
 t.check(g.RopeArt.account_issue(g)=="","REMOVAL capture_departed_master_books_nothing: the debug recount stays silent without a live master: issue="+g.RopeArt.account_issue(g))

# F3 (A257): G-QX2-6's data half -- the ledger's "a non-rope part counts zero" premise holds only while
# every composite part template and every reinforcement-strap design stays non-rope. The scan reads the
# data tables and the composites source, so a part the spec helper cannot reach still fails closed.
static func capture_no_rope_material_in_parts(t) -> void:
 var g=Game.new(42)
 var templates=[]
 for row in g.Composites.GENERATION: _collect_part_templates(g,templates,String(row[0]),String(row[1]),String(row[2]))
 for row in [["jacket","standard","straight"],["wrap","left","straight"],["wrap","right","straight"],["head","harness","straight"]]:
  _collect_part_templates(g,templates,String(row[0]),String(row[1]),String(row[2]))
 var unknown=templates.filter(func(name):return not g.Equipment.TEMPLATES.has(String(name)))
 var rope_parts=templates.filter(func(name):return String(g.Equipment.TEMPLATES.get(String(name),{}).get("material",""))=="rope")
 t.check(templates.size()>=9 and unknown.is_empty(),"REMOVAL capture_no_rope_material_in_parts: every composite part template the spec helper can produce is a real equipment template: parts="+str(templates)+" unknown="+str(unknown))
 t.check(rope_parts.is_empty(),"REMOVAL capture_no_rope_material_in_parts: no composite part template is rope material, so a composite never enters the capture ledger through a component: rope="+str(rope_parts))
 var declared=_composites_source_templates()
 var uncovered=declared.filter(func(name):return String(name) not in templates)
 var extra=templates.filter(func(name):return String(name) not in declared)
 t.check(not declared.is_empty() and uncovered.is_empty() and extra.is_empty(),"REMOVAL capture_no_rope_material_in_parts: the spec enumeration covers every part template named in data/composites.gd: declared="+str(declared)+" uncovered="+str(uncovered)+" extra="+str(extra))
 var straps=g.SpecialEquipment.REINFORCEMENT_COMPONENTS.duplicate()
 straps.sort()
 var component_only=g.SpecialEquipment.TYPES.keys().filter(func(type):return bool(g.SpecialEquipment.TYPES[type].get("component_only",false))).map(func(type):return String(type))
 component_only.sort()
 var rope_straps=straps.filter(func(type):return String(g.SpecialEquipment.DESIGNS.get(String(type),{}).get("material",""))=="rope")
 t.check(straps==component_only and straps.all(func(type):return g.SpecialEquipment.DESIGNS.has(String(type))),"REMOVAL capture_no_rope_material_in_parts: the reinforcement-strap list is exactly the component-only special designs and every one has a design row: straps="+str(straps)+" component_only="+str(component_only))
 t.check(rope_straps.is_empty(),"REMOVAL capture_no_rope_material_in_parts: no reinforcement-strap design is rope material, so a strap never enters the capture ledger: rope="+str(rope_straps))

# QX2'' second round (来源 大师 x 看我手速): the sweep applies one piece per empty position, so every
# piece is booked by its own top-level hook and the last hook observes the completed total.
static func capture_sweep_books_each_piece(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 g.RopeArt.execute(g,boss,{"kind":"art_domain"})
 boss=g.RopeArt.master(g)
 var before_ids=g.state.equipment.map(func(e):return String(e.id))
 var mark=g.state.logs.size()
 g.RopeArt.execute(g,boss,{"kind":"art_sweep"})
 var live=g.RopeArt.master(g)
 var added=g.state.equipment.filter(func(e):return String(e.id) not in before_ids)
 var booked=added.filter(func(e):return Dictionary(live.rope_art.values).has(String(e.id)))
 var presented=log_texts(g,mark).filter(func(text):return text.contains(String(live.get("name",""))+"施加了"))
 t.check(added.size()==8 and booked.size()==added.size(),"REMOVAL capture_sweep_books_each_piece: the sweep fills the eight remaining arm and leg positions one piece at a time and every piece is booked at its own top-level hook: added="+str(added.size())+" booked="+str(booked.size())+" absent="+str(added.filter(func(e):return not Dictionary(live.rope_art.values).has(String(e.id))).map(func(e):return String(e.id))))
 t.check(presented.size()==9 and int(live.rope_art.total)==35,"REMOVAL capture_sweep_books_each_piece: the nine applications -- eight pieces plus the crotch rope -- present once each and sum to thirty-five: lines="+str(presented.size())+" total="+str(live.rope_art.total))
 t.check(int(live.rope_art.previous)==mini(100,int(live.rope_art.total)) and live.rope_art.drunk==0 and String(live.rope_art.hogtie)=="","REMOVAL capture_sweep_books_each_piece: the last top-level hook observed after its own booking, so previous is the capped total and no threshold fired: previous="+str(live.rope_art.previous)+" total="+str(live.rope_art.total)+" drunk="+str(live.rope_art.drunk))
 ledger_matches(t,g,"capture_sweep_books_each_piece")

# QX2'' second round (来源 助理 x 死亡追加): the assistant death appends two special restraints through
# `RopeArt.install`; the rope-material one is booked, the plastic one stays out, and the recount agrees.
static func capture_accounts_death_appends(t) -> void:
 var g=encounter(8)
 var boss=g.RopeArt.master(g)
 g.RopeArt.execute(g,boss,{"kind":"art_domain"})
 g.RopeArt.summon(g,boss)
 var helper=g.RopeArt.assistant(g)
 var before=g.state.special_equipment.map(func(item):return String(item.id))
 g._damage_enemy(helper,999,"fixed","test")
 var live=g.RopeArt.master(g)
 var added=g.state.special_equipment.filter(func(item):return String(item.id) not in before)
 var ropes=added.filter(func(item):return g.RopeArt.is_rope(item))
 var plastic=added.filter(func(item):return not g.RopeArt.is_rope(item))
 t.check(bool(helper.get("gone",false)) and added.size()==2 and live.rope_art.deaths==1,"REMOVAL capture_accounts_death_appends: the assistant death appends two special restraints and counts one death: gone="+str(helper.get("gone",false))+" added="+str(added.size())+" deaths="+str(live.rope_art.deaths))
 t.check(ropes.size()==1 and Dictionary(live.rope_art.values).has(String(ropes[0].id)),"REMOVAL capture_accounts_death_appends: the rope-material restraint the append installs is booked by its join hook: ropes="+str(ropes.size())+" booked="+str(ropes.filter(func(item):return Dictionary(live.rope_art.values).has(String(item.id))).size()))
 t.check(plastic.size()==1 and not Dictionary(live.rope_art.values).has(String(plastic[0].id)),"REMOVAL capture_accounts_death_appends: the plastic restraint the same append installs stays out of the ledger: plastic="+str(plastic.size())+" booked="+str(Dictionary(live.rope_art.values).has(String(plastic[0].id)) if not plastic.is_empty() else "missing"))
 ledger_matches(t,g,"capture_accounts_death_appends")

# QX2'' second round (S18/S19 x 有⑤): an install no longer settles, so an exhausted tool waits with the
# zeroed piece for the next declared settle point, which reports the exhaustion exactly once.
static func capture_install_leaves_exhausted_items_to_settle_points(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 boss.rope_art.domain=true
 var victim=add_rope(g,"thigh","thigh_root",1,3)
 g._apply_equipment_damage(victim,999,"strain")
 var tool=_exhausted_tool(g)
 var mark=g.state.logs.size()
 var installed=g.RopeArt.install(g,boss,g.RopeArt.spec(1,2))
 t.check(installed and not g._equipment(String(victim.id)).is_empty() and g.state.items.has(tool) and not log_texts(g,mark).any(func(text):return text.contains("已经耗尽次数")),"REMOVAL capture_install_leaves_exhausted_items_to_settle_points: the install returns with the zeroed piece and the exhausted tool still in their containers: installed="+str(installed)+" item="+str(g.state.items.has(tool))+" logs="+str(log_texts(g,mark)))
 g._cleanup()
 t.check(g._equipment(String(victim.id)).is_empty() and not g.state.items.has(tool) and log_texts(g,mark).filter(func(text):return text.contains("已经耗尽次数")).size()==1,"REMOVAL capture_install_leaves_exhausted_items_to_settle_points: the next declared settle point removes both and reports the exhaustion once: present="+str(not g._equipment(String(victim.id)).is_empty())+" logs="+str(log_texts(g,mark)))

# QX2'' second round (S18/S19 x 有⑤, second path): the same deferral holds for the new-hogtie branch.
static func capture_hogtie_leaves_exhausted_items_to_settle_points(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 boss.rope_art.domain=true
 var victim=add_rope(g,"thigh","thigh_root",1,3)
 g._apply_equipment_damage(victim,999,"strain")
 var tool=_exhausted_tool(g)
 var mark=g.state.logs.size()
 g.RopeArt.hogtie(g,boss,2)
 t.check(not String(boss.rope_art.hogtie).is_empty() and not g._equipment(String(victim.id)).is_empty() and g.state.items.has(tool) and not log_texts(g,mark).any(func(text):return text.contains("已经耗尽次数")),"REMOVAL capture_hogtie_leaves_exhausted_items_to_settle_points: the new hogtie returns with the zeroed piece and the exhausted tool still in their containers: hogtie="+String(boss.rope_art.hogtie)+" item="+str(g.state.items.has(tool)))
 g._cleanup()
 t.check(g._equipment(String(victim.id)).is_empty() and not g.state.items.has(tool) and log_texts(g,mark).filter(func(text):return text.contains("已经耗尽次数")).size()==1,"REMOVAL capture_hogtie_leaves_exhausted_items_to_settle_points: the next declared settle point removes both and reports the exhaustion once: present="+str(not g._equipment(String(victim.id)).is_empty())+" logs="+str(log_texts(g,mark)))

# QX2'' second round (S18/S19 x 有 power): with a released-trigger power on the hero, the install leaves
# the zeroed rope in place, so the release count happens once at the next declared settle point.
static func capture_install_defers_release_count_to_settle_points(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 g.RopeArt.execute(g,boss,{"kind":"art_domain"})
 t.check(_free_embrace(t,g),"REMOVAL capture_install_defers_release_count_to_settle_points: the battle carries the released-trigger power face before the install: powers="+str(g.state.powers.size()))
 boss=g.RopeArt.master(g)
 g.RopeArt.install(g,boss,g.RopeArt.spec(3,3))
 var target=g.action_targets().filter(func(item):return g.RopeArt.is_rope(item))[-1]
 g._apply_equipment_damage(target,999,"strain")
 var mark=g.state.logs.size()
 var installed=g.RopeArt.install(g,boss,g.RopeArt.spec(2,2))
 var early=_release_rows(g,mark)
 t.check(installed and not g._equipment(String(target.id)).is_empty() and early.is_empty(),"REMOVAL capture_install_defers_release_count_to_settle_points: the install returns with the zeroed rope still in the container and the release trigger has not run: early="+str(early))
 g._cleanup()
 var counts=_release_rows(g,mark).map(func(row):return int(Dictionary(row.data.restraint_energy).get("count",-1)))
 t.check(g._equipment(String(target.id)).is_empty() and _release_rows(g,mark).size()==1 and counts==[1],"REMOVAL capture_install_defers_release_count_to_settle_points: the one declared settle point counts the released piece once and releases the power once: counts="+str(counts))
 var settled=g.state.logs.size()
 g._cleanup()
 t.check(g.state.logs.size()==settled,"REMOVAL capture_install_defers_release_count_to_settle_points: a second settle point adds no second release count: new_lines="+str(g.state.logs.size()-settled))

# QX2'' second round (S18/S19 x 有 power, second path): the same deferral holds for the new-hogtie branch.
static func capture_hogtie_defers_release_count_to_settle_points(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 g.RopeArt.execute(g,boss,{"kind":"art_domain"})
 t.check(_free_embrace(t,g),"REMOVAL capture_hogtie_defers_release_count_to_settle_points: the battle carries the released-trigger power face before the hogtie: powers="+str(g.state.powers.size()))
 boss=g.RopeArt.master(g)
 g.RopeArt.install(g,boss,g.RopeArt.spec(3,3))
 var target=g.action_targets().filter(func(item):return g.RopeArt.is_rope(item))[-1]
 g._apply_equipment_damage(target,999,"strain")
 var mark=g.state.logs.size()
 g.RopeArt.hogtie(g,boss,2)
 var early=_release_rows(g,mark)
 t.check(not String(boss.rope_art.hogtie).is_empty() and not g._equipment(String(target.id)).is_empty() and early.is_empty(),"REMOVAL capture_hogtie_defers_release_count_to_settle_points: the new hogtie returns with the zeroed rope still in the container and the release trigger has not run: early="+str(early)+" hogtie="+String(boss.rope_art.hogtie))
 g._cleanup()
 var counts=_release_rows(g,mark).map(func(row):return int(Dictionary(row.data.restraint_energy).get("count",-1)))
 t.check(g._equipment(String(target.id)).is_empty() and _release_rows(g,mark).size()==1 and counts==[1],"REMOVAL capture_hogtie_defers_release_count_to_settle_points: the one declared settle point counts the released piece once and releases the power once: counts="+str(counts))
 var settled=g.state.logs.size()
 g._cleanup()
 t.check(g.state.logs.size()==settled,"REMOVAL capture_hogtie_defers_release_count_to_settle_points: a second settle point adds no second release count: new_lines="+str(g.state.logs.size()-settled))

# QX2'' second round (S18/S19 x 有⑤ x 有 power): the same declared settle point owns both deferred
# jobs -- erasing the exhausted tool and counting the released roots -- and does each exactly once.
static func capture_settle_point_owns_exhaustion_and_release(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 boss.rope_art.domain=true
 t.check(_free_embrace(t,g),"REMOVAL capture_settle_point_owns_exhaustion_and_release: the battle carries the released-trigger power face before the deferred members exist: powers="+str(g.state.powers.size()))
 boss=g.RopeArt.master(g)
 var victim=add_rope(g,"thigh","thigh_root",1,3)
 g._apply_equipment_damage(victim,999,"strain")
 var tool=_exhausted_tool(g)
 var mark=g.state.logs.size()
 var installed=g.RopeArt.install(g,boss,g.RopeArt.spec(1,2))
 t.check(installed and not g._equipment(String(victim.id)).is_empty() and g.state.items.has(tool) and _release_rows(g,mark).is_empty() and not log_texts(g,mark).any(func(text):return text.contains("已经耗尽次数")),"REMOVAL capture_settle_point_owns_exhaustion_and_release: the install returns with the zeroed piece, the exhausted tool and the release trigger all still pending: installed="+str(installed)+" item="+str(g.state.items.has(tool))+" early="+str(_release_rows(g,mark)))
 g._cleanup()
 var counts=_release_rows(g,mark).map(func(row):return int(Dictionary(row.data.restraint_energy).get("count",-1)))
 t.check(g._equipment(String(victim.id)).is_empty() and not g.state.items.has(tool) and log_texts(g,mark).filter(func(text):return text.contains("已经耗尽次数")).size()==1 and _release_rows(g,mark).size()==1 and counts==[1],"REMOVAL capture_settle_point_owns_exhaustion_and_release: one settle point removes both deferred members, reports the exhaustion once and releases the power once: present="+str(not g._equipment(String(victim.id)).is_empty())+" counts="+str(counts)+" logs="+str(log_texts(g,mark)))
 var settled=g.state.logs.size()
 g._cleanup()
 t.check(g.state.logs.size()==settled,"REMOVAL capture_settle_point_owns_exhaustion_and_release: a second settle point adds neither a second exhaustion report nor a second release count: new_lines="+str(g.state.logs.size()-settled))
 var h=encounter()
 var hboss=h.RopeArt.master(h)
 hboss.rope_art.domain=true
 t.check(_free_embrace(t,h),"REMOVAL capture_settle_point_owns_exhaustion_and_release: the hogtie path carries the released-trigger power face before the deferred members exist: powers="+str(h.state.powers.size()))
 hboss=h.RopeArt.master(h)
 var hvictim=add_rope(h,"thigh","thigh_root",1,3)
 h._apply_equipment_damage(hvictim,999,"strain")
 var htool=_exhausted_tool(h)
 var hmark=h.state.logs.size()
 h.RopeArt.hogtie(h,hboss,2)
 t.check(not String(hboss.rope_art.hogtie).is_empty() and not h._equipment(String(hvictim.id)).is_empty() and h.state.items.has(htool) and _release_rows(h,hmark).is_empty() and not log_texts(h,hmark).any(func(text):return text.contains("已经耗尽次数")),"REMOVAL capture_settle_point_owns_exhaustion_and_release: the new hogtie returns with the zeroed piece, the exhausted tool and the release trigger all still pending: hogtie="+String(hboss.rope_art.hogtie)+" item="+str(h.state.items.has(htool))+" early="+str(_release_rows(h,hmark)))
 h._cleanup()
 var hcounts=_release_rows(h,hmark).map(func(row):return int(Dictionary(row.data.restraint_energy).get("count",-1)))
 t.check(h._equipment(String(hvictim.id)).is_empty() and not h.state.items.has(htool) and log_texts(h,hmark).filter(func(text):return text.contains("已经耗尽次数")).size()==1 and _release_rows(h,hmark).size()==1 and hcounts==[1],"REMOVAL capture_settle_point_owns_exhaustion_and_release: the hogtie path's one settle point removes both deferred members, reports the exhaustion once and releases the power once: present="+str(not h._equipment(String(hvictim.id)).is_empty())+" counts="+str(hcounts)+" logs="+str(log_texts(h,hmark)))

# The exhausted-tool precondition of the S18/S19 cells: a real tool with no uses left, left in the
# container for the next settle point to report and erase.
static func _exhausted_tool(g) -> Dictionary:
 g._gain_tool("mana_potion")
 var tool=g.state.items[g.state.items.size()-1]
 tool.uses=0
 return tool

# The released-trigger power of the shared battle fixture: "拘束之拥·自由" draws and restores energy per
# released physical root, so its energy row carries the count the one settle point must apply.
static func _free_embrace(t,g) -> bool:
 g.state.energy=5
 var card=Give.give(g,"restraint_embrace")
 var command=t.find_action(g,"card",{"uid":card.uid,"free":true})
 if not command.valid: return false
 var result=g.dispatch(g.command(command.payload,g.state.version),g.state.version)
 return result.ok and g.state.powers.size()==1

# The release-count rows a settle writes for the released-trigger power.
static func _release_rows(g, from: int) -> Array:
 return g.state.logs.slice(from).filter(func(row):return row.data.has("restraint_energy"))

# Part templates of one composite spec, collected once per template name.
static func _collect_part_templates(g, out: Array, kind: String, variant: String, straps: String) -> void:
 var spec=g.Composites.spec(kind,variant,straps)
 for key in spec.get("parts",{}):
  var name=String(spec.parts[key].template)
  if name not in out: out.append(name)

# Every part template named as the second argument of a `part(` call in the composites source.
static func _composites_source_templates() -> Array:
 var names=[]
 var source=FileAccess.get_file_as_string("res://data/composites.gd")
 if source=="": return names
 var regex=RegEx.new()
 regex.compile("part\\([^,\\n]*,\\s*\"([a-z_]+)\"")
 for found in regex.search_all(source):
  var name=found.get_string(1)
  if name not in names: names.append(name)
 return names

static func capture_ledger(t) -> void:
 capture_entry_counts_every_rope_instance(t)
 capture_accounts_new_members_at_join(t)
 capture_follows_tier_hook_only(t)
 capture_unaccounts_removed_closure(t)
 capture_unaccounts_removed_linked_closure(t)
 capture_replacement_commit_accounts_closure(t)
 capture_ignores_non_rope_special_closure(t)
 capture_unaccounts_composite_preemption(t)
 capture_unaccounts_single_strap(t)
 capture_settles_only_in_rope_battle(t)
 capture_hogtie_nests_inside_join_hook(t)
 capture_observes_at_top_level_hook(t)
 capture_hold_keeps_stock_before_threshold(t)
 capture_tighten_all_applies_hogtie_midway(t)
 capture_master_tighten_all_pays_and_names_the_hogtie(t)
 capture_master_tighten_all_logs_the_hogtie_epilogue(t)
 capture_card_tighten_all_pays_and_names_the_hogtie(t)
 capture_tier_hook_defers_observation_to_the_owning_unit(t)
 capture_tier_hook_never_nests_a_booked_observation(t)
 capture_ease_crossing_keeps_previous_after_the_unit(t)
 capture_removal_observes_outside_units(t)
 self_binding_survives_midway_hogtie(t)
 hogtie_install_leaves_foreign_writes_to_settle_points(t)
 rope_install_leaves_foreign_writes_to_settle_points(t)
 capture_accounts_cord_at_install(t)
 capture_ignores_cup_special_closure(t)
 capture_unaccounts_link_without_anchor(t)
 capture_accounts_assistant_installs(t)
 capture_writes_nothing_outside_battle(t)
 capture_departed_master_books_nothing(t)
 capture_no_rope_material_in_parts(t)
 capture_sweep_books_each_piece(t)
 capture_accounts_death_appends(t)
 capture_install_leaves_exhausted_items_to_settle_points(t)
 capture_hogtie_leaves_exhausted_items_to_settle_points(t)
 capture_install_defers_release_count_to_settle_points(t)
 capture_hogtie_defers_release_count_to_settle_points(t)
 capture_settle_point_owns_exhaustion_and_release(t)
 await capture_account_matches_recount(t)

# QX7 (rev3.3 gherkin G-QX7-1…3, dependencies-delta「编织绳网批保护」): the weave's three applications
# share one protected batch. The probe records every unit a plan zeroes -- a replacement removes a
# piece only by zeroing it, and the trial copies run on the same records -- so a criterion can name
# the ids dismantled during one art, including a piece the art itself just installed. It overrides no
# rule and writes no state of its own.
class WeaveProbe extends "res://tests/game_fixture.gd":
 var dismantled: Array=[]
 var recording: bool=false
 func _write_durability(target: Dictionary, value: float, tighten: bool=false) -> void:
  if recording and float(value)<=0.0 and float(target.get("durability",0.0))>0.0:
   var id=String(target.get("id",""))
   if not dismantled.has(id): dismantled.append(id)
  super._write_durability(target,value,tighten)

# QX7 fixture: fill every position a rope or cord could occupy, so an application that installs at
# all has to replace something. `short` keeps a named slot one piece below its capacity.
static func weave_full_body(g, short: Dictionary) -> void:
 for slot in ["upper_arm","forearm","wrist","palm","thigh","calf","ankle","foot"]:
  var limit=int(short.get(slot,g.Equipment.capacity(slot,"rope")))
  if g.Equipment.SEGMENTS.has(slot):
   for point in g.Equipment.points(slot):
    while g._capacity_point_count(point)<limit:
     if add_rope(g,slot,point,3,1).is_empty(): break
  else:
   var first=String(g.Equipment.points(slot)[0])
   while g._capacity_point_count(first)<limit:
    if add_rope(g,slot,"",3,1).is_empty(): break
 for slot in ["fingers","toes"]:
  var first=String(g.Equipment.points(slot)[0])
  while g._capacity_point_count(first)<g.Equipment.capacity(slot,"cord"):
   if add_rope(g,slot,"",3,1,"cord").is_empty(): break

# QX7 fixture: the same full body, but the wrist stack keeps `waiting` value-two ropes, so the art has
# exactly those beatable pieces to take there. The fill stops `waiting` pieces short of the wrist
# capacity; the added ropes make the body full again.
static func weave_contested_body(g, waiting: int) -> Array:
 weave_full_body(g,{"wrist":g.Equipment.capacity("wrist","rope")-waiting})
 var pieces=[]
 for index in range(waiting): pieces.append(add_rope(g,"wrist","wrist",1,1))
 return pieces

# The one id snapshot of an art: the action targets as ids, taken before and after the applications.
static func weave_ids(g) -> Array:
 return g.action_targets().map(func(item):return String(item.get("id","")))

# The art's observable change on `g`: `appeared` are the action targets it installed, `stray` are the
# ids it dismantled that were not on the body before it. `recording` brackets the art alone.
static func weave_change(g, boss: Dictionary, before: Array) -> Dictionary:
 g.recording=true
 g.RopeArt.execute(g,boss,{"kind":"art_weave"})
 g.recording=false
 var after=weave_ids(g)
 return {"appeared":after.filter(func(id):return not before.has(id)),"stray":g.dismantled.filter(func(id):return not before.has(id))}

# The fixture's own claim: no rope or cord position is open. "" means the body is full.
static func weave_full_issue(g) -> String:
 for slot in ["upper_arm","forearm","wrist","palm","thigh","calf","ankle","foot","fingers","toes"]:
  var template="cord" if slot in ["fingers","toes"] else "rope"
  var limit=g.Equipment.capacity(slot,template)
  for point in g.Equipment.points(slot):
   if g._capacity_point_count(point)<limit: return "%s/%s still has a free position" % [slot,point]
 return ""

# G-QX7-1「ROPE weave pieces never replace each other」(rev3.3 acceptance §3.QX7, no free position
# with the second piece's only replaceable being the first): the older rope is taken and nothing this
# art installs is dismantled by it.
static func weave_pieces_never_replace_each_other(t) -> void:
 var g=encounter(42,WeaveProbe)
 var waiting=weave_contested_body(g,1)
 var before=weave_ids(g)
 var free=weave_full_issue(g)
 var change=weave_change(g,g.RopeArt.master(g),before)
 var weak=waiting[0]
 t.check(free=="" and not weak.is_empty(),"ROPE weave_pieces_never_replace_each_other: the fixture leaves no free position for a value-three rope and one older rope waiting inside the wrist stack: free="+free+" weak="+String(weak.get("id","")))
 t.check(change.stray.is_empty() and g.dismantled.has(String(weak.get("id",""))) and change.appeared.size()>=2,"ROPE weave_pieces_never_replace_each_other: the first piece takes the older rope and no piece this art installs is dismantled by a later application: dismantled="+str(g.dismantled)+" appeared="+str(change.appeared)+" weak="+String(weak.get("id","")))
 # The same claim over the other two acceptance states: free positions (nothing is dismantled at all)
 # and a hogtie applied mid-art (a piece that appears between two applications is not dismantled).
 var open=encounter(42,WeaveProbe)
 var open_before=weave_ids(open)
 var open_change=weave_change(open,open.RopeArt.master(open),open_before)
 var art=encounter(42,WeaveProbe)
 var art_waiting=weave_contested_body(art,2)
 var art_boss=art.RopeArt.master(art)
 art_boss.rope_art.domain=true
 art_boss.rope_art.total=48
 art_boss.rope_art.previous=48
 art.state.guard_bind={"progress":48.0,"sources":{art.RopeArt.MASTER:{"enemy":art_boss.id,"energy":0}}}
 var art_before=weave_ids(art)
 var art_change=weave_change(art,art_boss,art_before)
 var hogtie=String(art.RopeArt.master(art).rope_art.hogtie)
 t.check(open_change.stray.is_empty() and open_change.appeared.size()>=2,"ROPE weave_pieces_never_replace_each_other: a body with free positions takes both pieces without dismantling anything: dismantled="+str(open.dismantled)+" appeared="+str(open_change.appeared))
 t.check(art_change.stray.is_empty() and not art_waiting[0].is_empty() and not art_waiting[1].is_empty() and not hogtie.is_empty() and not art._equipment(hogtie).is_empty(),"ROPE weave_pieces_never_replace_each_other: a hogtie applied between two applications stays, and nothing this art installs is dismantled around it: dismantled="+str(art.dismantled)+" appeared="+str(art_change.appeared)+" hogtie="+hogtie)

# G-QX7-2 (rev3.3 acceptance §3.QX7, no free position with an older rope outside this art): protection
# covers the pieces this art installed, not every rope on the body.
static func weave_still_replaces_older_equipment(t) -> void:
 var g=encounter(42,WeaveProbe)
 var waiting=weave_contested_body(g,2)
 var before=weave_ids(g)
 var free=weave_full_issue(g)
 var change=weave_change(g,g.RopeArt.master(g),before)
 var first=waiting[0]
 var second=waiting[1]
 var older=g.dismantled.filter(func(id):return id==String(first.get("id","")) or id==String(second.get("id","")))
 t.check(free=="" and not first.is_empty() and not second.is_empty(),"ROPE weave_still_replaces_older_equipment: the fixture leaves no free position and two value-two ropes waiting inside the wrist stack: free="+free+" first="+String(first.get("id",""))+" second="+String(second.get("id","")))
 t.check(change.stray.is_empty() and older.size()==2 and change.appeared.size()>=2,"ROPE weave_still_replaces_older_equipment: both older ropes are replaceable while the pieces this art installed stay, so the protection names this art's targets and not every rope: dismantled="+str(g.dismantled)+" appeared="+str(change.appeared)+" older="+str(older))

# G-QX7-3 (rev3.3 acceptance §3.QX7): one protected batch -- declared once before the loop, the
# difference set of the action targets that appeared during the art, and handed to all three
# applications through `ordinary`'s `extra`. No runtime seam exposes the spec's protected_ids, so this
# criterion pins the declared shape; G-QX7-1 and G-QX7-2 judge that shape's runtime effect.
static func weave_shares_one_protected_batch(t) -> void:
 var body=Arch.code_of_function("core/rope_master.gd","execute")
 var start=body.find("\"art_weave\":")
 var stop=body.find("\"art_enchant\":")
 var branch=body.substr(start,stop-start) if start>=0 and stop>start else ""
 var declared=branch.find("var protected=[]")
 var loop=branch.find("for i in range(2):")
 var pass_through=branch.count("\"protected_ids\":protected")
 var rebuilds=branch.count("protected=[]")
 # The accumulation is one private helper shared with the death art: the branch hands it the ids
 # taken before the application and the targets read after it, and the helper keeps the difference
 # set verbatim. Moving either half out of that path, or re-inlining the loop at either call site,
 # is red.
 var absorbs=branch.count("_absorb_protected(protected,before,g.action_targets())")
 var death=Arch.code_of_function("core/rope_master.gd","death").count("_absorb_protected(protected,before,g.state.special_equipment)")
 var accumulation=Arch.code_of_function("core/rope_master.gd","_absorb_protected").contains("if item.id not in before: protected.append(item.id)")
 var difference=absorbs==1 and death==1 and accumulation and branch.contains("var before=g.action_targets().map(func(item):return item.id)")
 t.check(start>=0 and stop>start and declared>=0 and loop>declared and branch.count("var protected")==1 and rebuilds==1,"ROPE weave_shares_one_protected_batch: the art declares its protected list once, before the two profiles, and never rebuilds it per application (the same list serves the whole art): branch="+branch.substr(0,120)+" declared="+str(declared)+" loop="+str(loop)+" declarations="+str(branch.count("var protected"))+" rebuilds="+str(rebuilds))
 t.check(pass_through==2 and difference,"ROPE weave_shares_one_protected_batch: the batch is the difference set of the action targets that appeared and every application receives it through ordinary's extra: pass_through="+str(pass_through)+" difference="+str(difference)+" branch="+branch)

# QX7 hardener L1 (A289; cleaner §8 left the death side with only the structural pin): the
# assistant-death art appends two special restraints through the same shared difference set the weave
# uses, so its behaviour needs its own judge. Fixture: fill every special capacity point with a
# value-three piece and leave one value-one crotch rope as the piece the grade-one death profile
# takes. Seed 46 draws grade one and then grade two (the two size-three `enemy` draws); the second
# application's only legal target is the grade-one crotch rope the first one installed, and taking it
# would be a real grade change (a same-grade replacement is refused as a no-op), so the surviving id
# and the id counter say whether it took it. Special replacement erases the record instead of
# zeroing durability, so the judge reads the container and the counter, not the durability probe.
static func death_contested_body(g) -> Dictionary:
 for entry in [["nipple_clamp_high","special_1_a"],["nipple_ring_high","special_1_a"],["full_cup_high","special_2_a"],["shaft_ring_high","special_2_a"],["corona_ring_high","special_2_c"],["urethral_rod_high","special_2_d"],["vaginal_egg_high","special_3_a"],["anal_egg_high","special_3_b"]]:
  g._install_special(String(entry[0]),String(entry[1]),2)
 return g._install_special("crotch_rope_low","special_3_a",1)

static func death_appends_never_replace_each_other(t) -> void:
 var g=encounter(46)
 var old=death_contested_body(g)
 var before=g.state.special_equipment.map(func(item):return String(item.get("id","")))
 var start=int(g.state.next_equipment)
 var boss=g.RopeArt.master(g)
 g.RopeArt.summon(g,boss)
 var helper=g.RopeArt.assistant(g)
 g._damage_enemy(helper,999,"fixed","test")
 var after=g.state.special_equipment.map(func(item):return String(item.get("id","")))
 var installed=after.filter(func(id):return not before.has(id))
 var first="special_%d" % start
 t.check(not old.is_empty() and not after.has(String(old.get("id",""))),"ROPE death_appends_never_replace_each_other: the older rope outside this art is replaced, so protection covers this art's pieces and not every rope: old="+String(old.get("id",""))+" after="+str(after))
 t.check(installed.size()==1 and installed[0]==first and int(g.state.next_equipment)==start+1,"ROPE death_appends_never_replace_each_other: the second application cannot take the first one's piece (that piece is its only legal candidate), so the first id survives and only one piece is created: installed="+str(installed)+" first="+first+" start="+str(start)+" next="+str(int(g.state.next_equipment)))

static func run(t) -> void:
 var g=encounter()
 var boss=g.RopeArt.master(g)
 t.check(boss.hp==140 and boss.rope_art.stock==48 and boss.intent.kind=="art_intro","ROPE approved opening health, stock and intent")
 t.check(g.validate()=="","ROPE initial state validates: "+g.validate())
 await turn(t,g)
 boss=g.RopeArt.master(g)
 var helper=g.RopeArt.assistant(g)
 t.check(not helper.is_empty() and helper.hp==36 and helper.stage==1,"ROPE summon skips its birth turn")
 t.check(g.RopeArt.target_reason(g,helper,false)!="" and g.RopeArt.target_reason(g,helper,true)=="","ROPE protection rejects single targeting but permits area attacks")
 await turn(t,g)
 boss=g.RopeArt.master(g)
 t.check(boss.rope_art.domain and boss.rope_art.total==8 and boss.rope_art.stock==40,"ROPE domain installs two medium tier-two ropes and spends eight")
 var before=g.export_snapshot()
 g.get_view();g.get_view()
 t.check(g.export_snapshot()==before,"ROPE views preserve inventory, thresholds and RNG")
 g.CaptureBind.damage_bind(g,100,"test")
 t.check(g.state.guard_bind.progress==8,"ROPE capture cannot be attacked directly")
 await turn(t,g)
 t.check(g.validate()=="","ROPE opening sweep validates: "+g.validate())
 boss=g.RopeArt.master(g)
 boss.rope_art.seal=true
 var rope=g.state.equipment.filter(func(item):return item.material=="rope")[0]
 g._apply_equipment_damage(rope,999,"cut")
 g._apply_manual_release(rope,0.0)
 g._cleanup()
 t.check(rope.durability>0 and g._equipment(rope.id).id==rope.id,"ROPE final seal blocks damage destruction and direct release")
 boss.rope_art.seal=false
 g.RopeArt.hogtie(g,boss,2)
 var hog=g._equipment(boss.rope_art.hogtie)
 t.check(not hog.is_empty() and g.Equipment.coverage(hog)==["wrist","ankle"] and g.Equipment.capacity_points(hog).is_empty(),"ROPE hogtie is one instance with two contacts and no ordinary capacity")
 t.check(g._slip_reason(hog)!="","ROPE hogtie rejects slipping")
 g.RopeArt.observe(g)
 t.check(g.state.posture=="lie" and g.state.order=="last","ROPE hogtie enforces lying and acting last")
 var stock=boss.rope_art.stock
 g.RopeArt.hogtie(g,boss,3)
 t.check(hog.grade==3 and boss.rope_art.stock==stock-1,"ROPE hogtie grade upgrade pays only the added value")
 var cup=g._install_special("glans_cup_medium","special_2_b",2)
 t.check(not cup.is_empty() and g.RopeArt.unavailable(g),"ROPE cup equipment disables the primary body branch")
 helper=g.RopeArt.assistant(g)
 g._damage_enemy(helper,999,"fixed","test")
 boss=g.RopeArt.master(g)
 t.check(boss.rope_art.deaths==1 and boss.intent.kind=="art_grief","ROPE first assistant death preempts the master with grief")
 g.RopeArt.execute(g,boss,boss.intent)
 t.check(g.RopeArt.plan(g,boss).kind=="art_revive","ROPE grief schedules exactly one resurrection")
 g.RopeArt.execute(g,boss,g.RopeArt.plan(g,boss))
 helper=g.RopeArt.assistant(g)
 t.check(helper.hp==36 and helper.stage==1,"ROPE resurrected assistant resets health and its action sequence: id=%s hp=%s stage=%s assistants=%s" % [helper.get("id","missing"),helper.get("hp","missing"),helper.get("stage","missing"),g.state.enemies.filter(func(row):return row.type==g.RopeArt.ASSISTANT).map(func(row):return [row.id,row.gone,row.stage])])
 g._damage_enemy(helper,999,"fixed","test")
 boss=g.RopeArt.master(g)
 g.RopeArt.execute(g,boss,g.RopeArt.plan(g,boss))
 t.check(boss.rope_art.deaths==2 and not boss.rope_art.revive,"ROPE second death causes grief without another resurrection")
 g._damage_enemy(boss,999,"fixed","test")
 t.check(g._all_gone(),"ROPE master defeat ends the encounter")
 threshold_and_stock(t)
 card_layers(t)
 enchantments_and_helper(t)
 persistence(t)
 hogtie_attachments(t)
 hogtie_shared_release(t)
 await capture_ledger(t)
 reported_turn_sequence(t)
 weave_pieces_never_replace_each_other(t)
 weave_still_replaces_older_equipment(t)
 weave_shares_one_protected_batch(t)
 death_appends_never_replace_each_other(t)
