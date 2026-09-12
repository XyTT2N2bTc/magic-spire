extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const D=preload("res://data/special_equipment.gd")

static func run(t) -> void:
 catalog_and_projection(t)
 capacity_and_composites(t)
 pleasure_and_battery(t)
 climax_slip(t)
 escape_routes(t)
 manual_insertables(t)
 registry_paths(t)
 environment_classes(t)
 chastity_locks(t)
 upgrade_components(t)

static func upgrade_components(t) -> void:
 for reverse_order in [false,true]:
  var g=Game.new(42,false,"equipment",true,true,25)
  var old=g._install_special("negative_plate_lock_medium","special_2_a",3)
  var old_strap=g.state.special_equipment.filter(D.is_reinforcement)[0]
  var neighbour=g._install_special("nipple_ring_medium","special_1_a",2).duplicate(true)
  if reverse_order: g.state.special_equipment.reverse()
  var before=g.export_snapshot()
  var request={"kind":"special_install","type":"negative_vibrator_lock_catheter_high","slot":"special_2_a","grade":3,"tier":3}
  for protected_id in [old.id,old_strap.id]:
   var spec={"pool":"special","templates":[request.type],"grade":3,"tier":3,"count":1,"replace":true,"protected_ids":[protected_id]}
   t.check(not g.Application.can_apply(g,spec,"fixture") and g.state==before,"SPECIAL upgrade query excludes a protected root or component without mutation")
   var blocked=g.Application.execute_concrete(g,request,"fixture",true,[protected_id])
   t.check(not blocked.ok and g.state==before,"SPECIAL frozen upgrade cannot remove a protected root or component")
   g.state=before.duplicate(true)
   var spec_before=spec.duplicate(true)
   var batch=g.Application.execute(g,spec,"fixture")
   t.check(not batch.ok and batch.count==0 and g.state==before and spec==spec_before,"SPECIAL batch execution preserves caller protection just like its query and frozen submission")
   g.state=before.duplicate(true)
  var result=g.Application.execute_concrete(g,request,"fixture",true,[neighbour.id])
  t.check(result.ok and g._equipment(old.id).is_empty() and g._equipment(old_strap.id).is_empty(),"SPECIAL upgrade removes the old root and owned component before cleanup regardless of storage order")
  var straps=g.state.special_equipment.filter(D.is_reinforcement)
  t.check(straps.size()==1 and straps[0].owner_id==result.installed[0].id and g.validate()=="","SPECIAL upgrade immediately leaves one valid component owned by the new root")
  t.check(result.removed.size()==2 and old.id in result.removed and old_strap.id in result.removed,"SPECIAL upgrade receipt includes both removed physical ids for shared batch and event reporting")
  t.check(g._equipment(neighbour.id)==neighbour and g.state.energy==before.energy and g.state.mana==before.mana and g.state.pressure==before.pressure and g.state.rng==before.rng and g.state.deck==before.deck,"SPECIAL upgrade preserves unrelated equipment, resources, random streams and deck")

 var grouped=Game.new(42,false,"equipment",true,true,25)
 var covered=grouped._install_special("full_cup_medium","special_2_a",2)
 var group_before=grouped.export_snapshot()
 var requests=[{"kind":"special_install","type":"negative_plate_lock_medium","slot":"special_2_a","grade":2,"tier":3},{"kind":"install","template":"rope","slot":"ankle","grade":1,"tier":2,"variant":0}]
 var result=grouped.Application.execute_concrete(grouped,{"kind":"application_group","requests":requests},"fixture",true,[covered.id])
 t.check(not result.ok and grouped.state==group_before,"SPECIAL group preview cannot bypass protection through an automatic cross-family replacement")

static func catalog_and_projection(t) -> void:
 var g=Game.new(42,true,"special_equipment")
 t.check(g.validate()=="" and g.state.special_equipment.size()==3,"SPECIAL real equipment practice validates")
 t.check(g.state.pressure==8 and g.state.special_equipment[0].remaining==5,"SPECIAL first player turn applies the powered nipple clamp once")
 t.check(g.state.equipment.is_empty() and g.level("arms")==0 and g.level("legs")==0 and g.item_capacity()==3,"SPECIAL equipment does not change ordinary restraint or carried-item capacity")
 var groups=g.get_view().body_groups
 t.check(groups.map(func(b):return b.id)==["eyes","mouth","neck","upper_arm","special_1","forearm","wrist","hands","special_2","special_3","thigh","calf","ankle","feet"],"SPECIAL anatomical regions keep their requested display order")
 t.check(groups.filter(func(b):return b.special).map(func(b):return b.items.size())==[1,4,2],"SPECIAL seven concrete slots project in three named regions")
 t.check(groups[4].name=="乳头" and groups[8].name=="肉棒" and groups[9].name=="双穴","SPECIAL player-facing regions no longer use placeholder names")
 t.check(D.slot_name("special_2_a")=="柱身" and D.slot_name("special_2_d")=="马眼" and D.slot_name("special_3_b")=="后庭","SPECIAL concrete subslots use anatomical names")
 var before=g.state.duplicate(true)
 groups[4].items[0].equipment[0].name="altered"
 g.get_view();g.candidates()
 t.check(g.state==before,"SPECIAL view and candidate projection are read-only")
 for slot in D.slots():
  t.check(g._install_template("rope",slot,4,10,false,"test").is_empty(),"SPECIAL ordinary restraint factory rejects reserved slot "+slot)
 t.check(D.TYPES.size()==39 and D.DESIGNS.size()==D.TYPES.size(),"SPECIAL complete built-in catalog has paired trigger and fixed-design records")
 for type in D.TYPES:
  if D.TYPES[type].get("component_only",false): continue
  var wear=D.wear_text(type)
  t.check(not wear.is_empty() and wear.contains(D.TYPES[type].name) and not wear.contains("{name}"),"SPECIAL every built-in type owns reusable exact-name wear prose "+type)
 t.check(not D.wear_text("vaginal_egg_low").contains("牵引线") and not D.wear_text("anal_egg_low").contains("牵引线"),"SPECIAL wireless internal eggs never invent a retrieval wire")
 g=Game.new(42,true,"plate_lock")
 var locks=g.state.special_equipment.filter(D.is_chastity)
 var straps=g.state.special_equipment.filter(D.is_reinforcement)
 t.check(g.state.phase=="rest" and g.state.practice_kind=="plate_lock" and locks.size()==1 and locks[0].type=="negative_vibrator_lock_catheter_high" and locks[0].locked and g.tier(locks[0].durability,locks[0].maximum)==3,"SPECIAL plate-lock practice starts through the normal rest flow with one locked high-grade tier-three root")
 t.check(straps.size()==1 and straps[0].owner_id==locks[0].id and g.Pressure.maximum(g)==130 and g.state.hand.any(func(card):return card.type=="unlock"),"SPECIAL plate-lock practice attaches its real reinforcement, dynamic maximum and an immediately drawn unlock card")
 t.check(g.validate()=="","SPECIAL plate-lock practice is a valid isolated practice state")

static func capacity_and_composites(t) -> void:
 var g=Game.new(42)
 t.check(D.slots().map(func(slot):return D.capacity(slot))==[2,2,2,2,1,1,1],"SPECIAL corrected per-slot capacities are registered")
 var cup=g._install_special("full_cup_medium","special_2_a")
 var glans=g._install_special("glans_cup_medium","special_2_b")
 var shaft=g._install_special("shaft_ring_low","special_2_a")
 var rod=g._install_special("urethral_rod_low","special_2_d")
 t.check(not cup.is_empty() and not glans.is_empty() and not shaft.is_empty() and not rod.is_empty() and g.validate()=="","SPECIAL compatible different families fill the penis region atomically")
 t.check(D.occupied_slots(cup)==["special_2_a","special_2_b","special_2_c"] and g.targets_at("special_2_c").has(cup),"SPECIAL one composite cup root covers and targets through every declared slot")
 var before=g.state.duplicate(true)
 t.check(g._install_special("shaft_ring_high","special_2_a").is_empty() and g.state==before,"SPECIAL same family cannot be duplicated even when a slot has room")
 t.check(g._install_special("forced_milking_cup_high","special_2_a").is_empty() and g.state==before,"SPECIAL composite install rejects atomically when any covered slot is full")
 var card=t.hand_card(g,"strain")
 var choices=g.candidates().filter(func(c):return c.payload.get("uid","")==card.uid and c.payload.get("target","")==cup.id)
 t.check(choices.size()==1,"SPECIAL a multi-slot physical root creates one card target, not one per covered slot")
 var saved=g.export_snapshot();var restored=Game.new(17)
 t.check(restored.restore_snapshot(saved).ok and restored.state.special_equipment==g.state.special_equipment,"SPECIAL composite coverage and independent durability survive save restore")
 saved.special_equipment[0].coverage=["special_2_a"]
 before=restored.state.duplicate(true)
 t.check(not restored.restore_snapshot(saved).ok and restored.state==before,"SPECIAL forged partial composite coverage rejects atomically")

 g=Game.new(42)
 var vaginal=g._install_special("vaginal_egg_low","special_3_a")
 var anal=g._install_special("anal_egg_low","special_3_b")
 var rope=g._install_special("crotch_rope_low","special_3_a")
 t.check(not vaginal.is_empty() and not anal.is_empty() and not rope.is_empty() and g.validate()=="","SPECIAL zero-capacity crotch rope can coexist with both occupied cavity slots")
 t.check(D.used_capacity(g.state.special_equipment,"special_3_a")==1 and D.used_capacity(g.state.special_equipment,"special_3_b")==1,"SPECIAL crotch rope occupies both child displays without consuming either capacity")
 t.check(D.occupied_slots(rope)==["special_3_a","special_3_b"] and D.TYPES[rope.type].stimulates==["special_3_a"],"SPECIAL crotch rope is shown in both cavities but stimulates only the vagina")

static func pleasure_and_battery(t) -> void:
 var g=Game.new(42)
 var shaft=g._install_special("shaft_ring_low","special_2_a")
 var rod=g._install_special("urethral_rod_low","special_2_d")
 var glans=g._install_special("glans_cup_medium","special_2_b")
 t.check(is_equal_approx(D.gain(shaft,"turn_start"),2.4),"SPECIAL shaft gain applies the 0.6 sensitivity multiplier")
 t.check(is_equal_approx(D.gain(rod,"energy"),6.0),"SPECIAL urethral gain applies the 1.5 sensitivity multiplier")
 t.check(is_equal_approx(D.gain(glans,"turn_start"),36.0),"SPECIAL multi-position cup combines the sensitivity of stimulated positions")

 g=Game.new(42)
 var clamp=g._install_special("nipple_clamp_low","special_1_a")
 for i in range(4): g._tick_special("turn_start")
 t.check(g.state.special_equipment.has(clamp) and clamp.remaining==0 and g.state.pressure==24,"SPECIAL battery applies exactly its declared number of player-turn pulses")
 g._tick_special("turn_start")
 t.check(g.state.special_equipment.has(clamp) and g.state.pressure==24 and D.gain(clamp,"turn_start")==0,"SPECIAL empty battery stops stimulation but leaves the equipment installed")

 g=Game.new(42)
 rod=g._install_special("urethral_rod_low","special_2_d")
 var pressure=g.state.pressure
 t.check(t.action(g,"attack",{"type":"heavy"}).ok and g.state.pressure==pressure+6,"SPECIAL a multi-energy action triggers each energy-paid effect only once")
 var stale=t.find_action(g,"end");var before=g.state.duplicate(true)
 t.check(not g.dispatch(stale.id,g.state.version-1).ok and g.state==before,"SPECIAL stale command causes no pleasure pulse or state change")

static func climax_slip(t) -> void:
 for pair in [["urethral_rod_low",3.0],["urethral_rod_medium",2.0],["urethral_rod_high",1.0]]:
  var g=Game.new(42)
  var rod=g._install_special(pair[0],"special_2_d")
  var neighbour=g._install_special("shaft_ring_low","special_2_a")
  g.state.pressure=99
  var choice=t.find_action(g,"attack",{"type":"heavy"})
  var before=g.export_snapshot()
  t.check(not g.dispatch(choice.id,g.state.version-1).ok and g.export_snapshot()==before,"CLIMAX SLIP stale card leaves urethral and neighbouring equipment unchanged: "+pair[0])
  var durability=rod.durability
  t.check(g.dispatch(choice.id,g.state.version).ok and is_equal_approx(g._equipment(rod.id).durability,durability-pair[1]) and g._equipment(neighbour.id).durability==neighbour.durability,"CLIMAX SLIP formal climax applies 6 minus tier 2 minus grade only to urethral rod: "+pair[0])
  var records=g.state.logs.filter(func(log):return log.data.has("climax_slip"))
  t.check(records.size()==1 and records[0].data.climax_slip.tightness==2 and records[0].data.climax_slip.grade==rod.grade and records[0].data.climax_slip.damage==pair[1] and records[0].text.contains("固定滑脱伤害"),"CLIMAX SLIP structured mechanical log preserves formula and actual damage: "+pair[0])
 var g=Game.new(42)
 var rod=g._install_special("urethral_rod_high","special_2_d",3)
 g.state.pressure=99
 t.check(t.action(g,"attack",{"type":"heavy"}).ok and g._equipment(rod.id).durability==rod.maximum and g.state.logs.any(func(log):return log.data.has("climax_slip") and log.data.climax_slip.damage==0),"CLIMAX SLIP high grade at tier three reaches the exact zero-damage boundary and remains installed")
 g=Game.new(42)
 rod=g._install_special("urethral_rod_low","special_2_d")
 g.Pressure.gain(g,400,"连续高潮",true)
 var sequence=g.state.logs.filter(func(log):return log.data.has("climax_slip"))
 t.check(sequence.size()==3 and sequence.map(func(log):return log.data.climax_slip.tightness)==[2,2,1] and sequence.map(func(log):return log.data.climax_slip.damage)==[3.0,3.0,2.0] and g._equipment(rod.id).is_empty(),"CLIMAX SLIP consecutive climaxes recalculate tightness after each hit and stop once the rod comes out")
 t.check(g.validate()=="" and D.climax_slip_damage({"type":"shaft_ring_low","grade":1},2)==0 and D.climax_slip_rule("urethral_full_cup_high")=="","CLIMAX SLIP unrelated rings and integrated cup remain outside urethral-rod rule")

static func escape_routes(t) -> void:
 for type in ["shaft_ring_low","corona_ring_low","urethral_rod_low","crotch_rope_low","full_cup_medium"]:
  var design=D.DESIGNS[type]
  t.check("strain" in design.methods and "slip" in design.methods and "magic_slip" in design.methods,"SPECIAL physical card families are registered for "+type)
 t.check(D.DESIGNS.urethral_rod_low.environments==["hook"],"SPECIAL urethral rod accepts only hook-class environmental leverage")
 t.check(D.DESIGNS.vaginal_egg_low.methods==["manual"] and D.DESIGNS.anal_egg_low.environments.is_empty(),"SPECIAL wireless insertables expose only their direct manual removal")
 t.check(D.DESIGNS.full_cup_medium.environments==["hook","wall"] and "sharp" not in D.DESIGNS.full_cup_medium.environments,"SPECIAL cups do not accept sharp-class leverage")

 var g=Game.new(42)
 var ring=g._install_special("shaft_ring_low","special_2_a")
 g.add_fixture("wrist",8);g.state.wall_distance=2
 var preview=g.escape_preview(ring,"strain",5)
 t.check(preview.reason.contains("墙壁类") and preview.damage==0,"SPECIAL no usable hand and no contacted environment blocks a physical card")
 g.state.wall_distance=0
 preview=g.escape_preview(ring,"strain",5)
 t.check(preview.reason=="" and preview.damage>0 and preview.assist.hands.is_empty(),"SPECIAL compatible wall contact opens the normal card formula without inventing hand assistance")
 g.state.wall_distance=2
 t.check(g.escape_preview(ring,"magic_slip",5).reason=="" and g.escape_preview(ring,"magic_slip",5).damage>0,"SPECIAL magic slip does not inherit the physical environment gate")

 g=Game.new(42)
 var nipple=g._install_special("nipple_ring_low","special_1_a")
 g.add_fixture("wrist",8);g.state.wall_distance=0
 t.check(g.escape_preview(nipple,"strain",5).reason.contains("尖锐类") and g.escape_preview(nipple,"strain",5).damage==0,"SPECIAL nipple ring cannot substitute ordinary wall contact for its whitelist")
 g._gain_tool("shard")
 var tool=g.state.items[0]
 t.check(t.action(g,"item_install",{"item":tool.id,"mount":"high_wall"}).ok,"SPECIAL sharp environment uses the normal tool installation transaction")
 preview=g.escape_preview(nipple,"strain",5)
 t.check(preview.reason=="" and preview.damage>0,"SPECIAL contacted installed sharp tool opens the card route")
 var card=t.hand_card(g,"strain")
 var candidate=t.find_action(g,"card",{"uid":card.uid,"target":nipple.id,"free":false})
 t.check(candidate.valid and not candidate.payload.tool_bonus.is_empty(),"SPECIAL installed sharp tool remains an existing card-damage passive, not a separate removal action")
 t.check(not g.candidates().any(func(c):return c.payload.kind=="item_use" and c.payload.get("target","")==nipple.id),"SPECIAL carried tools never create a direct cutting action for sex toys")

 g=Game.new(42,true,"special_equipment")
 var rod=g.state.special_equipment.filter(func(item):return item.type=="urethral_rod_medium")[0]
 g.add_fixture("wrist",8)
 preview=g.escape_preview(rod,"strain",5)
 t.check(preview.reason=="" and preview.damage>0,"SPECIAL rest-room hook opens the urethral rod card route when the height can contact it")
 t.check(not g.candidates().any(func(c):return c.payload.kind=="hook" and c.payload.get("target","")==rod.id),"SPECIAL hook remains a card prerequisite and never becomes a separate direct action")

static func manual_insertables(t) -> void:
 for pair in [["vaginal_egg_low","special_3_a"],["anal_egg_low","special_3_b"]]:
  var g=Game.new(42)
  var egg=g._install_special(pair[0],pair[1])
  var kept=g._install_special("shaft_ring_low","special_2_a").duplicate(true)
  var direct=t.find_action(g,"manual",{"target":egg.id})
  t.check(direct.valid and direct.cost==1 and direct.label=="直接取出","SPECIAL free hands expose one-action direct removal "+pair[0])
  var strain=t.hand_card(g,"strain")
  t.check(not t.find_action(g,"card",{"uid":strain.uid,"target":egg.id,"free":false}).valid,"SPECIAL wireless target rejects strain cards")
  for slot in ["upper_arm","wrist","palm","fingers"]:
   var restraint=g.add_fixture(slot,4)
   var before=g.export_snapshot()
   direct=t.find_action(g,"manual",{"target":egg.id})
   t.check(not direct.valid and not g.dispatch(direct.id,g.state.version).ok and g.export_snapshot()==before,"SPECIAL direct removal blocked atomically by "+slot)
   restraint.durability=0;g._cleanup()
  var energy=g.state.energy
  t.check(t.action(g,"manual",{"target":egg.id}).ok and g._equipment(egg.id).is_empty() and g.state.energy==energy-1 and g._equipment(kept.id)==kept,"SPECIAL removal costs one action and preserves unrelated root")

static func registry_paths(t) -> void:
 for type in D.TYPES:
  if D.TYPES[type].get("component_only",false): continue
  var g=Game.new(42)
  var target={}
  if D.TYPES[type].get("relic_only",false):
   g.RelicEffects.gain(g,type)
   target=g.state.special_equipment.filter(func(item):return item.type==type)[0]
  else: target=g._install_special(type,D.DESIGNS[type].slots[0])
  t.check(not target.is_empty() and g.validate()=="","SPECIAL every registered type installs through factory "+type)
  if target.is_empty(): continue
  var before=g.export_snapshot()
  g.get_view();g.candidates()
  for mode in ["strain","slip","magic_slip"]: g.escape_preview(target,mode,5)
  t.check(g.export_snapshot()==before,"SPECIAL complete registry preview does not mutate or access ordinary template "+type)
  var card=t.hand_card(g,"strain")
  var candidate=t.find_action(g,"card",{"uid":card.uid,"target":target.id,"free":false})
  if candidate.valid:
   t.check(g.dispatch(candidate.id,g.state.version).ok,"SPECIAL registered target uses formal damage path "+type)

static func environment_classes(t) -> void:
 var g=Game.new(42);g.state.equipment=[];g.state.items=[]
 var anchor=g._install_special("crotch_rope_low","special_3_a")
 for wall in ["normal","rough","none"]:
  g.state.wall=wall;g.state.wall_distance=0
  t.check(D.environment_contact(g,anchor,"wall")== (wall!="none") and g.wall_view().environment_class==("wall" if wall!="none" else ""),"ENV CLASS both real wall surfaces, no fictitious wall "+wall)
 g.state.wall="normal";g.state.wall_distance=1
 t.check(not D.environment_contact(g,anchor,"wall"),"ENV CLASS wall tag does not bypass distance")
 g.state.wall_distance=0;g.state.posture="stand"
 for type in ["shard","saw"]:
  g.state.items=[];g._gain_tool(type)
  var tool=g.state.items[0]
  t.check(not D.environment_contact(g,anchor,"sharp"),"ENV CLASS carried sharp item is not an installed environment "+type)
  t.check(t.action(g,"item_install",{"item":tool.id,"mount":"hand_wall"}).ok and D.environment_contact(g,anchor,"sharp"),"ENV CLASS formal installation activates compatible sharp interface "+type)
  var before=g.export_snapshot();var item_view=g.get_view().items[0]
  t.check(item_view.environment_class=="sharp" and item_view.environment_name=="尖锐类" and g.export_snapshot()==before,"ENV CLASS read-only source label "+type)
  tool=g._item(tool.id)
  tool.mount="high_wall"
  t.check(not D.environment_contact(g,anchor,"sharp"),"ENV CLASS category does not bypass body contact height "+type)
  tool.mount="hand_wall";tool.uses=0
  t.check(not D.environment_contact(g,anchor,"sharp"),"ENV CLASS exhausted sharp source is inactive "+type)
 g=Game.new(42,true,"special_equipment")
 var rod=g.state.special_equipment.filter(func(item):return item.type=="urethral_rod_medium")[0]
 t.check(D.environment_contact(g,rod,"hook") and g.get_view().hook_environment_name=="挂钩类","ENV CLASS rest hook matches existing interface")
 t.check(not D.environment_contact(g,rod,"wall") and not D.environment_contact(g,rod,"unknown"),"ENV CLASS unaccepted or unknown class remains blocked")
 g.state.hook_uses=0
 t.check(not D.environment_contact(g,rod,"hook"),"ENV CLASS exhausted hook cannot supply environment")
 g.state.hook_uses=3;g.state.wall_distance=1
 t.check(not D.environment_contact(g,rod,"hook"),"ENV CLASS hook tag does not bypass wall contact")
 t.check(not g.Tools.TYPES.picks.has("environment_class") and not g.Tools.TYPES.return_seal.has("environment_class"),"ENV CLASS unrelated tools do not become environmental leverage")

static func chastity_locks(t) -> void:
 var g=Game.new(42,false,"equipment",true,true,25)
 var cup=g._install_special("full_cup_medium","special_2_a",2)
 var rod=g._install_special("urethral_rod_medium","special_2_d",2)
 var lock=g._install_special("negative_plate_lock_medium","special_2_a",2)
 t.check(not lock.is_empty() and lock.locked and g._equipment(cup.id).is_empty() and not g._equipment(rod.id).is_empty(),"CHASTITY plain plate atomically removes shaft toys while retaining an independent meatus rod")
 var locked_preview=g.escape_preview(lock,"slip",6)
 t.check(locked_preview.reason=="" and locked_preview.damage>0 and locked_preview.lock_multiplier==1.0,"CHASTITY an auto-locked root without reinforcement uses the ordinary lock rule and retains its slip route")
 t.check(g.Pressure.maximum(g)==120 and is_equal_approx(g.Pressure.source_multiplier(g,[]),1.2) and is_equal_approx(g.Pressure.source_multiplier(g,["special_2_a"]),1.0) and is_equal_approx(g.Pressure.source_multiplier(g,["special_2_d"]),1.2),"CHASTITY grade plus tightness raises maximum and multiplies only sources outside covered slots")
 var before=g.export_snapshot()
 t.check(g._install_special("shaft_ring_high","special_2_a",2).is_empty() and g.state==before,"CHASTITY ordinary toys cannot occupy or replace a worn lock")
 var replaced=g.Application.execute(g,{"pool":"special","templates":["shaft_ring_high"],"grade":3,"tier":3,"count":1,"replace":true},"enemy")
 t.check(not replaced.ok and not g._equipment(lock.id).is_empty(),"CHASTITY enemy replacement permission cannot remove the lock for another sex toy")
 var catheter=g._install_special("negative_plate_lock_catheter_medium","special_2_a",2)
 t.check(not catheter.is_empty() and g._equipment(lock.id).is_empty() and g._equipment(rod.id).is_empty() and g.state.special_equipment.filter(func(item):return D.is_chastity(item)).size()==1,"CHASTITY same-grade model with the integrated catheter upgrades the plain lock and outranks the standalone meatus rod")
 before=g.export_snapshot()
 t.check(g._install_special("negative_plate_lock_medium","special_2_a",2).is_empty() and g.state==before,"CHASTITY a less functional model cannot replace the current lock")
 var high=g._install_special("negative_vibrator_lock_catheter_high","special_2_a",3)
 var straps=g.state.special_equipment.filter(func(item):return D.is_reinforcement(item) and item.owner_id==high.id)
 t.check(not high.is_empty() and high.locked and straps.size()==1 and is_equal_approx(D.gain(high,"turn_start"),24.48),"CHASTITY high vibrator lock upgrades the medium model and applies total covered-slot stimulation times 0.4")
 var strap=straps[0];var strap_before=strap.durability
 g._apply_equipment_damage(strap,5,"strain")
 t.check(strap.durability==strap_before,"CHASTITY reinforcement ignores non-cutting damage")
 g._apply_equipment_damage(strap,5,"cut")
 t.check(strap.durability==strap_before-5 and not g._equipment(high.id).is_empty(),"CHASTITY reinforcement is an independent cutting target and does not remove its owner early")
 t.check(g.escape_preview(high,"slip",6).reason.contains("加固带"),"CHASTITY reinforcement blocks slip only while its owner remains locked and exposes the specific reason")
 var locked_durability=high.durability
 g._apply_equipment_damage(high,6,"slip")
 t.check(high.durability==locked_durability,"CHASTITY a linked reinforcement prevents direct slip damage while the owner remains locked")
 g.state.equipment.clear();g.state.composites.clear();g.state.links.clear()
 var unlock=t.hand_card(g,"unlock")
 t.check(t.action(g,"card",{"uid":unlock.uid,"target":high.id,"free":false}).ok and not g._equipment(high.id).locked,"CHASTITY existing unlock card opens the auto-locked root without changing durability")
 high=g._equipment(high.id)
 var preview=g.escape_preview(high,"slip",1)
 t.check(preview.reason=="" and preview.damage>0,"CHASTITY unlocking permits any positive slip result even while reinforcement remains")
 g._apply_equipment_damage(high,preview.damage,"slip");g._cleanup()
 t.check(g._equipment(high.id).is_empty() and g._equipment(strap.id).is_empty(),"CHASTITY positive slip removes the whole unlocked lock and cascades its reinforcement")

 g=Game.new(42,false,"equipment",true,true,25)
 lock=g._install_special("negative_plate_lock_catheter_medium","special_2_a",2)
 g.state.pressure=119
 g.Pressure.gain(g,1,"锁内刺激",true,["special_2_a"])
 t.check(g.state.pressure==12 and g.state.chastity_climax_factor==4 and g.state.slip_ejaculation_turns==2 and g.state.slip_ejaculation_force_last and g.state.overload_energy==0,"CHASTITY climax retains S times factor, increments the permanent factor and replaces normal fatigue with 滑精")
 g.state.overloaded=false;g.state.energy=0;g._start_round()
 t.check(g.state.order=="last" and g.state.slip_ejaculation_turns==1 and g.state.energy==2,"CHASTITY next player turn is forced last and consumes the first of two energy penalties")
 g.state.enemies=[];g.state.phase="prepare";g._begin_player_turn()
 t.check(g.state.slip_ejaculation_turns==0 and g.state.energy==2,"CHASTITY second player turn consumes the final one-energy penalty")
 g.state.chastity_climax_factor=7;g._restart_tower(true)
 t.check(g.state.chastity_climax_factor==7,"CHASTITY accumulated climax retention factor survives removal and continued towers within the run")

 g=Game.new(42,false,"equipment",true,true,100)
 var spec={"pool":"special","templates":["negative_plate_lock_medium","nipple_ring_medium"],"grade":2,"tier":2,"count":1,"replace":true}
 var chosen=g.Application.choose(g,spec,"enemy")
 t.check(chosen.get("type","")=="negative_plate_lock_medium","CHASTITY 100 percent setting selects a legal lock branch")
 lock=g._install_special("negative_vibrator_lock_catheter_high","special_2_a",2)
 chosen=g.Application.choose(g,spec,"enemy")
 t.check(chosen.get("type","")=="nipple_ring_medium","CHASTITY when no lock upgrade remains its probability is returned to legal ordinary toys")
 g=Game.new(42,false,"equipment",true,false,100)
 t.check(g.Application.choose(g,spec,"enemy").get("type","")=="nipple_ring_medium","CHASTITY disabled generation excludes lock types even at a stored 100 percent chance")
