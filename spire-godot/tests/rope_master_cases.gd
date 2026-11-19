extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Replacement=preload("res://core/equipment_replacement.gd")
const SelfBinding=preload("res://core/self_binding.gd")
const Give=preload("res://tests/curse_cases.gd")

static func encounter(seed_value: int=42):
 var g=Game.new(seed_value,false,"equipment",true)
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

static func add_rope(g, slot: String, point: String, grade: int, tier: int) -> Dictionary:
 var maximum=g.Equipment.maximum(grade)
 return g._install_template("rope",slot,maximum*[0.0,0.4,0.8,1.0][tier],maximum,false,"fixture",grade,-1,0,point)

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

static func capture_ledger(t) -> void:
 capture_entry_counts_every_rope_instance(t)
 capture_accounts_new_members_at_join(t)
 capture_follows_tier_hook_only(t)
 capture_unaccounts_removed_closure(t)
 capture_settles_only_in_rope_battle(t)
 capture_hogtie_nests_inside_join_hook(t)
 capture_observes_at_top_level_hook(t)
 capture_hold_keeps_stock_before_threshold(t)
 capture_tighten_all_applies_hogtie_midway(t)
 capture_removal_observes_outside_units(t)
 self_binding_survives_midway_hogtie(t)
 hogtie_install_leaves_foreign_writes_to_settle_points(t)
 await capture_account_matches_recount(t)

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
