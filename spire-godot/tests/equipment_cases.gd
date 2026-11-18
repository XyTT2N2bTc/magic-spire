extends RefCounted

const Game=preload("res://tests/game_fixture.gd")
const E=preload("res://data/equipment.gd")
# Living index-off reference for the B1 parity checks (single definition in the architecture suite).
const Arch=preload("res://tests/architecture_cases.gd")

static func leather_slip(t) -> void:
 for mode in ["strain","slip","magic_slip"]:
  for passive in [false,true]:
   var g=Game.new(42);g.state.wall="rough"
   var leather=g.add_fixture("ankle",4,10,false,0,"belt")
   var rope=leather.duplicate(true);rope.material="rope";rope.template="rope"
   var plain=g.escape_preview(rope,mode,2,[],passive)
   var boosted=g.escape_preview(leather,mode,2,[],passive)
   var factor=1.0
   t.check(is_equal_approx(boosted.damage,plain.damage*factor) and is_equal_approx(boosted.environment_true,plain.environment_true*factor),"LEATHER non-card previews exclude the card-only material bonus: "+mode+str(passive))
   if not passive:
    var ordinary=boosted.duplicate(true)
    g.Cards.scale_card_preview(g,boosted,mode,"",leather)
    var card_factor=1.0 if mode=="strain" else 1.5
    t.check(is_equal_approx(boosted.damage,ordinary.damage*card_factor) and is_equal_approx(boosted.environment_true,ordinary.environment_true*card_factor),"LEATHER only card slip scales final damage including the wall bonus: "+mode)
 var g=Game.new(42);g.state.wall="normal"
 var target=g.add_fixture("ankle",8,10,false,0,"belt")
 var card=preload("res://tests/curse_cases.gd").give(g,"slip")
 var choice=t.find_action(g,"card",{"uid":card.uid,"target":target.id,"free":false},true)
 var before=g.export_snapshot();var damage=choice.payload.preview.damage
 t.check(choice.payload.preview.material_factor==1.5 and is_equal_approx(damage,g.escape_preview(target,"slip",6).damage*1.5),"LEATHER real slip card includes its material multiplier exactly once")
 t.check(not g.dispatch(g.command(choice.payload,g.state.version-1),g.state.version-1).ok and g.export_snapshot()==before,"LEATHER stale slip preserves equipment and resources")
 t.check(g.dispatch(g.command(choice.payload,g.state.version),g.state.version).ok and is_equal_approx(g._equipment(target.id).durability,maxf(0,8-damage)),"LEATHER real card damage matches multiplied preview")

static func eye_capacity(t) -> void:
 var g=Game.new(42,true,"head_harness")
 var eyes=g.get_view().bodies.filter(func(b):return b.id=="eyes")[0]
 t.check(eyes.capacity==2 and eyes.capacity_used==2 and eyes.equipment.size()==2,"EYES real mixed masks share two projected positions")
 var before=g.export_snapshot()
 t.check(g._install_template("eye_leather","eyes",6.4,16,false,"fixture",2).is_empty() and g.export_snapshot()==before,"EYES third material cannot bypass capacity")
 var broken=before.duplicate(true)
 var extra=g.equipment_at("eyes")[0].duplicate(true)
 extra.id="equipment_"+str(broken.next_equipment);broken.next_equipment+=1
 broken.equipment.append(extra)
 t.check(not g.restore_snapshot(broken).ok and g.export_snapshot()==before,"EYES over-capacity saved masks are rejected atomically")
 var old_ids=g.equipment_at("eyes").map(func(e):return e.id)
 var result=g.Application.execute(g,{"pool":"ordinary","templates":["eye_tape"],"count":1,"grade":2,"tier":3,"replace":true},"event:capacity")
 t.check(result.ok and result.removed.size()==1 and g.equipment_at("eyes").size()==2 and g.equipment_at("eyes").any(func(e):return e.id not in old_ids) and g.validate()=="","EYES authorized replacement swaps one at the two-slot limit without creating a third")

# Q4′（G-Q4-2／6／8）共用：只数「形成了…」事件与 `state.rng.binding` 的增量，肩带/入列文案不计。
static func _binding_mark(g) -> Dictionary:
 return {"rng":int(g.state.rng.binding),"logs":g.state.logs.size()}

static func _added_texts(g, mark: Dictionary) -> Array:
 return g.state.logs.slice(int(mark.logs)).map(func(row):return String(row.text))

static func _formed_count(texts: Array) -> int:
 return texts.filter(func(text):return String(text).contains("形成了")).size()

# 审查 F1 正例夹具：经绳艺大师的真实施加入口（`RopeArt.install`）装一件 2 档绳件并返回新件；
# 返回空表示入口不可达，调用方据此具名红而不是静默跳过。
static func _rope_master_tracked_piece(g,boss: Dictionary) -> Dictionary:
 if boss.is_empty(): return {}
 var known=g.action_targets().map(func(item):return String(item.id))
 g.RopeArt.install(g,boss,{"pool":"ordinary","templates":["rope"],"grade":2,"tier":2,"count":1,"replace":true,"allow_links":false})
 for item in g.action_targets():
  if String(item.id) not in known: return item
 return {}

# 满值、可上锁、未上锁的 3 档大臂宿主：连接式固缚记录低于满值，左肩带缺侧、右肩带保留一半耐久。
# 真值走 `_install_template`（3 档安装即成交叉肩带与固缚），种子上限固定，故同一树内可复现；
# 找不到连接式记录就返回空，调用方据空表具名红而不是静默跳过。
static func _equal_value_host(template: String) -> Dictionary:
 for seed in range(1,96):
  var g=Game.new(seed)
  var host=g._install_template(template,"upper_arm",g.Equipment.maximum(3),g.Equipment.maximum(3),false,"fixture",3)
  if host.is_empty() or String(host.get("binding",{}).get("kind",""))!="linked": continue
  var right={}
  for strap in g.Shoulders.attached(g,host):
   if strap.side=="right": right=strap
   else: strap.durability=0.0
  if right.is_empty(): continue
  host.binding.durability=float(host.binding.maximum)*0.4
  right.durability=float(right.maximum)*0.5
  return {"game":g,"host":host,"right":right}
 return {}

# G-Q4-2（rev3 gherkin；Q4′）：收紧不重抽、不重复事件。每条原因走真实入口，计数只数「形成了…」；
# 肩带补齐另段验证只补缺侧。
static func tightening_draws_binding_once(t) -> void:
 # 档位分支：无记录的 2 档大臂绳升入 3 档 → 抽 1、事件 1。
 var g=Game.new(42)
 var piece=g.add_fixture("upper_arm",8,16,false,0,"rope")
 var mark=_binding_mark(g)
 var change=g._reinforce_equipment(piece)
 var drawn=int(g.state.rng.binding)-int(mark.rng)
 t.check(g.equipment_tier(piece)==3 and drawn==1 and _formed_count(_added_texts(g,mark))==1 and piece.has("binding"),"REMOVAL tightening_draws_binding_once: the tier branch lifts a recordless piece into tier three with exactly one binding draw and one formed event: change="+change+" draws="+str(drawn)+" formed="+str(_formed_count(_added_texts(g,mark))))
 # 锁定分支（皮带可上锁）与同值档位分支（绳索不可上锁）：已有连接式记录的满值 3 档件原地收紧
 # → 抽 0、事件 1 且 refreshed=true。
 for template in ["belt","rope"]:
  var fixture=_equal_value_host(template)
  t.check(not fixture.is_empty(),"REMOVAL tightening_draws_binding_once: the "+template+" fixture reaches a full tier-three host with a linked record below its maximum through the real install path: "+str(fixture.keys()))
  if fixture.is_empty(): continue
  var host=fixture.host
  var right=fixture.right
  var right_durability=float(right.durability)
  var binding_max=float(host.binding.maximum)
  mark=_binding_mark(fixture.game)
  fixture.game._reinforce_equipment(host)
  var added=fixture.game.state.logs.slice(int(mark.logs))
  drawn=int(fixture.game.state.rng.binding)-int(mark.rng)
  var refreshed=added.filter(func(row):return row.data.get("torso_binding",{}).get("refreshed",false))
  var straps=fixture.game.Shoulders.attached(fixture.game,host)
  t.check(is_equal_approx(float(host.binding.durability),binding_max) and drawn==0 and _formed_count(_added_texts(fixture.game,mark))==1 and refreshed.size()==1 and straps.size()==2,"REMOVAL tightening_draws_binding_once: the "+template+" equal-value tightening refills the existing linked record in place with no new draw and one refreshed formed event, and the missing side returns: durability="+str(host.binding.durability)+"/"+str(binding_max)+" draws="+str(drawn)+" formed="+str(_formed_count(_added_texts(fixture.game,mark)))+" refreshed="+str(refreshed.size())+" straps="+str(straps.size()))
  t.check(straps.any(func(strap):return strap.id==right.id and is_equal_approx(float(strap.durability),right_durability)),"REMOVAL tightening_draws_binding_once: the "+template+" fill repairs only the missing side and never resets the surviving one: right="+str(right.id)+" durability="+str(right.durability)+"/"+str(right_durability))
 # 事件「收紧到档」：2 档无记录 → 抽 1、事件 1。
 g=Game.new(42)
 var event_target=g.add_fixture("upper_arm",8,16,false,0,"rope")
 mark=_binding_mark(g)
 t.check(g.Events.apply_effects(g,[{"op":"tighten_to","target":event_target.id,"tier":3}],{})=="" and g.equipment_tier(event_target)==3 and int(g.state.rng.binding)-int(mark.rng)==1 and _formed_count(_added_texts(g,mark))==1,"REMOVAL tightening_draws_binding_once: the tighten_to event lifts a recordless piece into tier three with exactly one draw and one formed event: draws="+str(int(g.state.rng.binding)-int(mark.rng))+" formed="+str(_formed_count(_added_texts(g,mark))))
 # 入狱收紧：保底已满（六件）时只收紧 1 档，唯一可固缚件 2→3 → 抽 1、事件 1。
 g=Game.new(42)
 g.state.security=1
 var intake_target={}
 for slot in ["thigh","calf","ankle","foot","palm","upper_arm"]:
  var template="rope" if slot=="upper_arm" else "belt"
  var worn=g._install_template(template,slot,20,32,false,"fixture",1)
  if slot=="upper_arm": intake_target=worn
 mark=_binding_mark(g)
 var intake=g.Prison.intake_equipment(g)
 drawn=int(g.state.rng.binding)-int(mark.rng)
 t.check(not intake_target.is_empty() and g.equipment_tier(intake_target)==3 and drawn==1 and _formed_count(_added_texts(g,mark))==1,"REMOVAL tightening_draws_binding_once: intake at a full floor tightens the one bindable piece into tier three with exactly one draw and one formed event: draws="+str(drawn)+" formed="+str(_formed_count(_added_texts(g,mark)))+" enough="+str(intake.get("enough",false)))
 # 巡视违规收紧：同上三件旧件，安全等级 1 的补装都停在 2 档，唯一可固缚件 2→3 → 抽 1、事件 1。
 g=Game.new(42)
 g.state.security=1
 g.state.phase="inspection"
 g.state.prison.stage="result"
 g.state.prison.missing=[g._install_template("belt","thigh",12,32,false,"fixture",1).id]
 g.state.prison.special_missing=[]
 g.state.prison.baseline=[]
 g.state.prison.special_baseline=[]
 g.state.prison.sentence_extra=0
 g.state.prison.checks=0
 g.state.prison.report=""
 var watch=g._install_template("rope","upper_arm",12,32,false,"fixture",1)
 g._install_template("belt","calf",12,32,false,"fixture",1)
 mark=_binding_mark(g)
 g.Prison.execute(g,{"payload":{"action":"accept"}})
 drawn=int(g.state.rng.binding)-int(mark.rng)
 t.check(not watch.is_empty() and g.equipment_tier(watch)==3 and drawn==1 and _formed_count(_added_texts(g,mark))==1,"REMOVAL tightening_draws_binding_once: the inspection violation tightens every surviving piece to full, and only the recordless bindable one draws once and forms once: draws="+str(drawn)+" formed="+str(_formed_count(_added_texts(g,mark))))
 # 驷马缚升级：品质写口按收紧派发，但驷马缚不可固缚、且升级把耐久写回 2 档 → 抽 0、事件 0。
 var rope_game=preload("res://tests/rope_master_cases.gd").encounter()
 var boss=rope_game.RopeArt.master(rope_game)
 rope_game.RopeArt.hogtie(rope_game,boss,2)
 var hog=rope_game._equipment(boss.rope_art.hogtie)
 mark=_binding_mark(rope_game)
 rope_game.RopeArt.hogtie(rope_game,boss,3)
 t.check(not hog.is_empty() and hog.grade==3 and not hog.has("binding") and int(rope_game.state.rng.binding)-int(mark.rng)==0 and _formed_count(_added_texts(rope_game,mark))==0,"REMOVAL tightening_draws_binding_once: a hogtie upgrade changes quality only, drawing no binding and forming no event: draws="+str(int(rope_game.state.rng.binding)-int(mark.rng))+" formed="+str(_formed_count(_added_texts(rope_game,mark))))
 # 肩带件：3 档肩带自身收紧 → 抽 0、事件 0（肩带不是固缚候选）。
 var strap_game=Game.new(42)
 var strap=_crossed_left_strap(strap_game)
 mark=_binding_mark(strap_game)
 if not strap.is_empty(): strap_game._reinforce_equipment(strap)
 t.check(not strap.is_empty() and strap_game.equipment_tier(strap)==3 and int(strap_game.state.rng.binding)-int(mark.rng)==0 and _formed_count(_added_texts(strap_game,mark))==0,"REMOVAL tightening_draws_binding_once: a shoulder strap never draws or forms a torso binding, because the shoulder slot is not a binding candidate: draws="+str(int(strap_game.state.rng.binding)-int(mark.rng))+" formed="+str(_formed_count(_added_texts(strap_game,mark))))

# G-Q4-8（rev3.1 gherkin-delta；A140）：3 档同值写入按原因意图分流。收紧＝锁定分支（耐久同值）→ 固缚
# 补满、formed 事件 refreshed=true、补回左肩带；非收紧＝0 伤害落在这件上（耐久同值）→ 固缚、肩带、日志都不变。
static func equal_value_tier3_follows_cause_intent(t) -> void:
 for template in ["belt","rope"]:
  var fixture=_equal_value_host(template)
  t.check(not fixture.is_empty(),"REMOVAL equal_value_tier3_follows_cause_intent: the "+template+" fixture is reachable through the real install path (a full tier-three host, a linked record below its maximum, a missing left strap): "+str(fixture.keys()))
  if fixture.is_empty(): continue
  var g=fixture.game
  var host=fixture.host
  var binding_before=float(host.binding.durability)
  var binding_max=float(host.binding.maximum)
  var right=fixture.right
  var right_durability=float(right.durability)
  var mark=_binding_mark(g)
  g._reinforce_equipment(host)
  var added=g.state.logs.slice(int(mark.logs))
  var refreshed=added.filter(func(row):return row.data.get("torso_binding",{}).get("refreshed",false))
  var straps=g.Shoulders.attached(g,host)
  t.check(is_equal_approx(binding_before,binding_max*0.4) and is_equal_approx(float(host.binding.durability),binding_max) and refreshed.size()==1 and straps.size()==2 and straps.any(func(strap):return strap.id==right.id and is_equal_approx(float(strap.durability),right_durability)),"REMOVAL equal_value_tier3_follows_cause_intent: a tightening write at an unchanged value still refills the linked record, announces refreshed=true and repairs only the missing strap: template="+template+" binding="+str(binding_before)+"->"+str(host.binding.durability)+"/"+str(binding_max)+" refreshed="+str(refreshed.size())+" straps="+str(straps.size()))
  # 同一局面的另一份副本：0 伤害命中同一件（写入同值），只追踪。
  var copy=_equal_value_host(template)
  if copy.is_empty(): continue
  var cg=copy.game
  var chost=copy.host
  var cright=copy.right
  var copy_binding=float(chost.binding.durability)
  var copy_right=float(cright.durability)
  var copy_straps=cg.Shoulders.attached(cg,chost).size()
  var copy_logs=cg.state.logs.size()
  var copy_rng=int(cg.state.rng.binding)
  cg._apply_equipment_damage(chost,0.0,"passive_slip",true)
  t.check(is_equal_approx(float(chost.binding.durability),copy_binding) and cg.Shoulders.attached(cg,chost).size()==copy_straps and cg.state.logs.size()==copy_logs and int(cg.state.rng.binding)==copy_rng and is_equal_approx(float(cright.durability),copy_right),"REMOVAL equal_value_tier3_follows_cause_intent: a zero-damage write at an unchanged value stays non-tightening, so the linked record, the missing strap, the logs and the binding counter are untouched: template="+template+" binding="+str(chost.binding.durability)+"/"+str(copy_binding)+" straps="+str(cg.Shoulders.attached(cg,chost).size())+"/"+str(copy_straps)+" logs="+str(cg.state.logs.size())+"/"+str(copy_logs)+" rng="+str(cg.state.rng.binding)+"/"+str(copy_rng))

# G-Q4-6（rev3 gherkin；Q4′）：非收紧行新增的绳艺追踪只会是空操作（数据钉子）。镣铐模板、诅咒平板锁
# 设计、复合套体与肩带模板都不是 rope；替换事务的两个入口全程在沙盒内（QX6：`_sandbox_begin`／`_sandbox_end`，
# `RopeArt.track` 首行读 `_sandbox_depth` 即返回）；`hook_facts()` 在非 rest 相位为空。
static func settle_writes_track_only_rope_or_no_op(t) -> void:
 var rope_templates=[]
 for template in E.TEMPLATES:
  var spec=E.TEMPLATES[template]
  if bool(spec.get("shackle",false)) and String(spec.get("material",""))=="rope": rope_templates.append(String(template))
 var shackles=E.TEMPLATES.keys().filter(func(template):return bool(E.TEMPLATES[template].get("shackle",false)))
 t.check(not shackles.is_empty() and rope_templates.is_empty(),"REMOVAL settle_writes_track_only_rope_or_no_op: the shackle class is non-empty and no shackle template is made of rope, so the non-tightening tracker can only be a no-op on key release: shackles="+str(shackles)+" rope="+str(rope_templates))
 var special=preload("res://data/special_equipment.gd")
 var plate=special.DESIGNS.get("cursed_plate_lock",{})
 t.check(not plate.is_empty() and String(plate.get("material",""))!="rope","REMOVAL settle_writes_track_only_rope_or_no_op: the cursed plate lock design is not rope, so the boss-key release cannot start tracking rope art: design="+str(plate.get("material","")))
 var composites=preload("res://data/composites.gd")
 var rope_parts=[]
 var part_rows=0
 for row in composites.GENERATION:
  var layout=composites.spec(String(row[0]),String(row[1]),String(row[2]))
  for key in layout.get("parts",{}):
   part_rows+=1
   var template=String(layout.parts[key].template)
   if E.TEMPLATES.get(template,{}).get("material","")=="rope": rope_parts.append(String(row[0])+"/"+String(row[1])+"/"+String(row[2])+"/"+String(key))
 t.check(part_rows>0 and rope_parts.is_empty(),"REMOVAL settle_writes_track_only_rope_or_no_op: every composite body, band and shoulder-strap part is non-rope, so a composite damage write or a strap release tracks nothing: parts="+str(part_rows)+" rope="+str(rope_parts))
 var plan=Arch.code_of_function("core/equipment_replacement.gd","plan")
 var force=Arch.code_of_function("core/equipment_replacement.gd","force_special")
 var track=Arch.code_of_function("core/rope_master.gd","track")
 t.check(plan.contains("var sandbox=g._sandbox_begin()") and plan.contains("g._sandbox_end(sandbox)") and force.contains("var sandbox=g._sandbox_begin()") and force.contains("g._sandbox_end(sandbox)") and track.contains("if g._sandbox_depth>0: return"),"REMOVAL settle_writes_track_only_rope_or_no_op: Replacement.plan and force_special stay inside the sandbox for their whole transaction and RopeArt.track早退: plan="+str(plan.contains("var sandbox=g._sandbox_begin()"))+" force="+str(force.contains("var sandbox=g._sandbox_begin()"))+" track="+str(track.contains("if g._sandbox_depth>0: return")))
 var battle=Game.new(42)
 battle.state.phase="battle"
 var battle_facts=battle.hook_facts()
 battle.state.phase="map"
 var map_facts=battle.hook_facts()
 t.check(battle_facts.is_empty() and map_facts.is_empty(),"REMOVAL settle_writes_track_only_rope_or_no_op: hook_facts() is empty outside the rest phase, so no hook release can reach the non-tightening tracker in battle or on the map: battle="+str(battle_facts.size())+" map="+str(map_facts.size()))
 # 正例（审查 F1；G-Q4-6 的对照面）：非收紧行真的会追踪——绳艺大师在场时，伤害与手动松解各写一次，
 # `rope_art` 在该调用返回时立即更新，不依赖下一次结算。`track` 处理器改成 `pass` 时这两条具名红。
 var track_game=preload("res://tests/rope_master_cases.gd").encounter()
 var track_boss=track_game.RopeArt.master(track_game)
 var damage_piece=_rope_master_tracked_piece(track_game,track_boss)
 var damage_id=String(damage_piece.get("id",""))
 var damage_before=int(track_boss.rope_art.values.get(damage_id,0))
 var damage_total_before=int(track_boss.rope_art.total)
 if not damage_piece.is_empty(): track_game._apply_equipment_damage(damage_piece,float(damage_piece.maximum)*0.5,"slip")
 var damage_tier=track_game.equipment_tier(damage_piece) if not damage_piece.is_empty() else -1
 var damage_expected=track_game.RestraintValue.from_profile(int(damage_piece.get("grade",0)),damage_tier) if damage_tier>=0 else -1
 t.check(not damage_piece.is_empty() and damage_before>0 and damage_tier==1 and int(track_boss.rope_art.values.get(damage_id,-1))==damage_expected and int(track_boss.rope_art.total)==damage_total_before-damage_before+damage_expected,"REMOVAL settle_writes_track_only_rope_or_no_op: a non-tightening damage write updates the rope art before any settle point, so the master reads the post-write value and total in the same call instead of the next cleanup: piece="+damage_id+" tier="+str(damage_tier)+" tracked="+str(track_boss.rope_art.values.get(damage_id,"missing"))+" expected="+str(damage_expected)+" total="+str(track_boss.rope_art.total)+"/"+str(damage_total_before-damage_before+damage_expected))
 var release_piece=_rope_master_tracked_piece(track_game,track_boss)
 var release_id=String(release_piece.get("id",""))
 var release_before=int(track_boss.rope_art.values.get(release_id,0))
 var release_total_before=int(track_boss.rope_art.total)
 if not release_piece.is_empty(): track_game._apply_manual_release(release_piece,0.0)
 var release_tier=track_game.equipment_tier(release_piece) if not release_piece.is_empty() else -1
 t.check(not release_piece.is_empty() and release_before>0 and release_tier==0 and not track_boss.rope_art.values.has(release_id) and int(track_boss.rope_art.total)==release_total_before-release_before,"REMOVAL settle_writes_track_only_rope_or_no_op: a non-tightening manual release retires the rope from the art before any settle point, so the master's value map drops the released piece and the total falls in the same call: piece="+release_id+" tier="+str(release_tier)+" tracked="+str(track_boss.rope_art.values.get(release_id,"missing"))+" total="+str(track_boss.rope_art.total)+"/"+str(release_total_before-release_before))

# Q5（G-Q5-2）：版本号单调且只在进程内。七个写口每次进入都严格增大；失败提交回滚与 restore_snapshot
# 只换 state、不减小计数器；SaveStore.encode／get_view／export_snapshot／dispatch 的 checkpoint 与
# `_equipment_read` 都不出现版本号字段。原因矩阵的逐行等价由验收两树比对取证，本判据取同一批写口的
# 直接调用与真实安装／结算路径。
static func write_epoch_is_monotone_and_private(t) -> void:
 var g=Game.new(42)
 var stamp=int(g.write_epoch())
 var piece=g._install_template("rope","thigh",8.0,10.0,false,"fixture")
 t.check(not piece.is_empty() and g.write_epoch()>stamp,"REMOVAL write_epoch_is_monotone_and_private: the install factory advances the process-local epoch through its member announcement: before="+str(stamp)+" after="+str(g.write_epoch()))
 stamp=g.write_epoch();g._write_durability(piece,piece.durability,false)
 t.check(g.write_epoch()>stamp,"REMOVAL write_epoch_is_monotone_and_private: the durability port advances the epoch on entry, even for an equal value: before="+str(stamp)+" after="+str(g.write_epoch()))
 stamp=g.write_epoch();g._write_quality(piece,2)
 t.check(g.write_epoch()>stamp,"REMOVAL write_epoch_is_monotone_and_private: the quality port advances the epoch on entry: before="+str(stamp)+" after="+str(g.write_epoch()))
 stamp=g.write_epoch();g._write_locked(piece,true)
 t.check(g.write_epoch()>stamp and bool(piece.get("locked",false)),"REMOVAL write_epoch_is_monotone_and_private: the lock port advances the epoch and writes the lock: before="+str(stamp)+" after="+str(g.write_epoch()))
 stamp=g.write_epoch();g._write_locked(piece,false)
 t.check(g.write_epoch()>stamp and not bool(piece.get("locked",true)),"REMOVAL write_epoch_is_monotone_and_private: the unlock path is the same port and advances the epoch: before="+str(stamp)+" after="+str(g.write_epoch()))
 stamp=g.write_epoch()
 var root=g._install_assembly("leg","upper","fixture",2,2)
 var body=root.components.filter(func(e):return String(e.get("part",""))=="body")[0]
 var band=g._install_template("rope",g.Links.point_slot("below_knee"),8.0,10.0,false,"fixture",1,-1,0,"below_knee")
 var link=g._install_link(body.id,band.id,4.8,"fixture",1,[],["thigh","calf"],["above_knee","below_knee"])
 t.check(not root.is_empty() and not band.is_empty() and not link.is_empty() and g.write_epoch()>stamp,"REMOVAL write_epoch_is_monotone_and_private: the assembly, band and link installs advance the epoch through the member announcements: before="+str(stamp)+" after="+str(g.write_epoch()))
 stamp=g.write_epoch();var special=g._install_special("shaft_ring_low","special_2_a")
 t.check(not special.is_empty() and g.write_epoch()>stamp,"REMOVAL write_epoch_is_monotone_and_private: the special factory advances the epoch through _special_append: before="+str(stamp)+" after="+str(g.write_epoch()))
 stamp=g.write_epoch();g._special_erase(special)
 t.check(g.write_epoch()>stamp and not g.state.special_equipment.has(special),"REMOVAL write_epoch_is_monotone_and_private: _special_erase advances the epoch and removes the record: before="+str(stamp)+" after="+str(g.write_epoch()))
 stamp=g.write_epoch();g._special_append(special)
 t.check(g.write_epoch()>stamp and g.state.special_equipment.has(special),"REMOVAL write_epoch_is_monotone_and_private: _special_append advances the epoch and restores the record: before="+str(stamp)+" after="+str(g.write_epoch()))
 stamp=g.write_epoch();g._members_replaced()
 t.check(g.write_epoch()==stamp+1,"REMOVAL write_epoch_is_monotone_and_private: the whole-container replacement port advances the epoch exactly once: before="+str(stamp)+" after="+str(g.write_epoch()))
 # G-Q5-4 removal coverage through the real paths, not only the declared call sites: each live
 # removal class announces every member it takes out, so the epoch moves once per removed record.
 # A reordered filter (released list read after the container was rewritten) keeps the static
 # call count and still announces nothing; only the runtime step sees that.
 var shoulders=Game.new(42)
 var shoulder_host=shoulders._install_template("rope","upper_arm",3.0,10.0,false,"fixture",1)
 t.check(not shoulder_host.is_empty() and not shoulders._equipment(shoulder_host.id).has("shoulders"),"REMOVAL write_epoch_is_monotone_and_private: the tightening fixture starts below tier three with no shoulder pair, so the refresh path that establishes the pair is reachable: "+str(shoulder_host.keys()))
 var refresh_stamp=int(shoulders.write_epoch())
 shoulders._reinforce_equipment(shoulders._equipment(shoulder_host.id),3)
 # The tighten reaches Shoulders.refresh with no pair yet: the durability port, the container
 # announcement refresh now makes after writing `host.shoulders`, and the two sides fill adds each
 # advance the epoch once. Dropping the container announcement leaves three steps; this sees that.
 t.check(shoulders._equipment(shoulder_host.id).has("shoulders") and shoulders.write_epoch()==refresh_stamp+4,"REMOVAL write_epoch_is_monotone_and_private: the tier-three tighten establishes the shoulder pair through Shoulders.refresh, so the container announcement is one epoch step beside the durability port and the two filled sides: before="+str(refresh_stamp)+" after="+str(shoulders.write_epoch()))
 var shoulder_pair=shoulders.Shoulders.attached(shoulders,shoulders._equipment(shoulder_host.id))
 if shoulder_pair.size()==2:
  shoulders._equipment(shoulder_pair[0].id).durability=0.0
 var fill_stamp=int(shoulders.write_epoch())
 shoulders.Shoulders.fill(shoulders,shoulders._equipment(shoulder_host.id))
 t.check(shoulder_pair.size()==2 and shoulders.Shoulders.attached(shoulders,shoulders._equipment(shoulder_host.id)).size()==2 and shoulders.write_epoch()==fill_stamp+2,"REMOVAL write_epoch_is_monotone_and_private: the shoulder filter announces the released strap and the refilled side, one epoch step per member: before="+str(fill_stamp)+" after="+str(shoulders.write_epoch()))
 if shoulder_pair.size()==2:
  shoulders._equipment(shoulder_pair[1].id).durability=0.0
 var band_stamp=int(shoulders.write_epoch())
 shoulders.Shoulders.cleanup(shoulders)
 t.check(shoulders.Shoulders.attached(shoulders,shoulders._equipment(shoulder_host.id)).size()==1 and shoulders.write_epoch()==band_stamp+1,"REMOVAL write_epoch_is_monotone_and_private: the shoulder cleanup announces a zeroed strap while its host survives, one epoch step per removed member: before="+str(band_stamp)+" after="+str(shoulders.write_epoch()))
 shoulders._equipment(shoulder_host.id).durability=0.0
 var host_stamp=int(shoulders.write_epoch())
 shoulders.Shoulders.cleanup(shoulders)
 t.check(shoulders.Shoulders.attached(shoulders,shoulders._equipment(shoulder_host.id)).is_empty() and shoulders.write_epoch()==host_stamp+1,"REMOVAL write_epoch_is_monotone_and_private: the shoulder cleanup announces the last strap when the host leaves, one epoch step per removed member: before="+str(host_stamp)+" after="+str(shoulders.write_epoch()))
 var plates=Game.new(42)
 plates._install_special("negative_plate_lock_medium","special_2_a",2)
 var plate_stamp=int(plates.write_epoch())
 var plate_item=plates._install_special("negative_vibrator_lock_catheter_high","special_2_a",3)
 var plate_ids=plates.state.special_equipment.map(func(item):return String(item.get("id","")))
 t.check(not plate_item.is_empty() and plate_ids.size()==2 and plate_ids.has(String(plate_item.get("id",""))) and plates.write_epoch()>=plate_stamp+2*3,"REMOVAL write_epoch_is_monotone_and_private: the plate upgrade announces the displaced lock and both new records through _special_erase/_special_append, at least one epoch step per member and per port: before="+str(plate_stamp)+" after="+str(plates.write_epoch()))
 var teardown=Game.new(42)
 var teardown_root=teardown._install_assembly("leg","upper","fixture",2,2)
 var teardown_body=teardown_root.components.filter(func(e):return String(e.get("part",""))=="body")[0]
 var teardown_band=teardown._install_template("rope",teardown.Links.point_slot("below_knee"),8.0,10.0,false,"fixture",1,-1,0,"below_knee")
 var teardown_link=teardown._install_link(teardown_body.id,teardown_band.id,4.8,"fixture",1,[],["thigh","calf"],["above_knee","below_knee"])
 var teardown_expected=teardown_root.components.size()+3
 for part in teardown_root.components: part.durability=0.0
 teardown._equipment(teardown_band.id).durability=0.0
 var teardown_stamp=int(teardown.write_epoch())
 teardown._cleanup()
 t.check(not teardown_link.is_empty() and teardown.state.composites.is_empty() and teardown.state.links.is_empty() and teardown.write_epoch()==teardown_stamp+teardown_expected,"REMOVAL write_epoch_is_monotone_and_private: _cleanup announces the composite root, every released component and the link, one epoch step per removed member: before="+str(teardown_stamp)+" after="+str(teardown.write_epoch())+" expected="+str(teardown_expected))
 # The sequence clause needs a non-zero stamp too: a port call before the loop makes a lowering
 # commit path visible, while a fresh game kept the stamp at 0 and the `>=` always held.
 var sequence=Game.new(42)
 sequence._install_template("rope","thigh",8.0,10.0,false,"fixture")
 var sequence_stamp=int(sequence.write_epoch())
 var sequence_ok=true
 var end_result={}
 for i in range(2):
  var last=int(sequence.write_epoch())
  end_result=t.action(sequence,"end")
  sequence_ok=sequence_ok and sequence.write_epoch()>=last
 t.check(sequence_ok and sequence_stamp>0 and end_result.get("ok",false),"REMOVAL write_epoch_is_monotone_and_private: a real action sequence never lowers the epoch and commits normally: epoch="+str(sequence.write_epoch())+" result="+str(end_result.get("error","")))
 var rollback=Game.new(42)
 rollback.set_debug_checks_enabled(false)
 rollback.state.wall_distance=7
 var rollback_snapshot=rollback.export_snapshot()
 var rollback_epoch=int(rollback.write_epoch())
 var rollback_command={}
 for row in rollback.command_facts():
  if String(row.payload.get("kind",""))=="end" and row.valid:
   rollback_command=rollback.command(row.payload,rollback.state.version)
   break
 var rollback_result={"ok":false}
 if not rollback_command.is_empty(): rollback_result=rollback.dispatch(rollback_command,int(rollback.state.version))
 # The rejected `end` runs its own ports before the post-execution `validate` fails, so the epoch must
 # have moved and must stay moved: a rollback that restored the counter would land back on the stamp.
 t.check(not rollback_command.is_empty() and not rollback_result.get("ok",false) and rollback.export_snapshot()==rollback_snapshot and rollback.write_epoch()>rollback_epoch,"REMOVAL write_epoch_is_monotone_and_private: a failed commit rolls the state back byte-for-byte after entering write ports, and the epoch keeps every bump instead of following the rollback: epoch="+str(rollback_epoch)+"->"+str(rollback.write_epoch())+" result="+str(rollback_result.get("error","")))
 # The restore clause needs a non-zero stamp to be falsifiable: a port call before the snapshot makes a
 # counter-resetting restore visible, while an epoch-0 fixture silently passed the `>=`.
 var loaded=Game.new(42)
 loaded._install_template("rope","thigh",8.0,10.0,false,"fixture")
 var loaded_snapshot=loaded.export_snapshot()
 var loaded_epoch=int(loaded.write_epoch())
 loaded.state.wall_distance=2
 var loaded_result=loaded.restore_snapshot(loaded_snapshot)
 t.check(loaded_result.get("ok",false) and loaded_epoch>0 and loaded.write_epoch()>=loaded_epoch,"REMOVAL write_epoch_is_monotone_and_private: restore_snapshot swaps the state and never lowers the epoch: epoch="+str(loaded_epoch)+"->"+str(loaded.write_epoch()))
 var encoded=Arch.save_text(loaded.state)
 var view=JSON.stringify(loaded.get_view())
 var snapshot=JSON.stringify(loaded.export_snapshot())
 var checkpoint=JSON.stringify(end_result.get("checkpoint",null))
 var leaked=[]
 for token in ["_write_epoch","write_epoch"]:
  if encoded.contains(token) or view.contains(token) or snapshot.contains(token) or checkpoint.contains(token): leaked.append(token)
 t.check(leaked.is_empty() and loaded._equipment_read.is_empty() and checkpoint!="null","REMOVAL write_epoch_is_monotone_and_private: the epoch field stays out of the encoded save, the View, the exported snapshot, the committed checkpoint and the equipment read batch: leaked="+str(leaked)+" checkpoint="+checkpoint+" read_batch="+str(loaded._equipment_read))
 stamp=int(g.write_epoch());var scope=g._begin_equipment_read()
 g.equipment_at("thigh");g.get_view()
 g._equipment_read=scope
 g._write_durability(piece,piece.durability,false)
 t.check(g.write_epoch()>stamp and g._equipment_read.is_empty(),"REMOVAL write_epoch_is_monotone_and_private: reads and writes leave no epoch or index residue in the equipment read batch: before="+str(stamp)+" after="+str(g.write_epoch())+" read_batch="+str(g._equipment_read))

# Q6'a (G-Q6-7; rev3.4 gherkin "the full-restraint fixture's per-anchor disconnect sequence"): the link pass
# reads its anchor list once before the loop and must read it after the special / ordinary / composite passes,
# so anchors removed by those passes are already gone and their links follow. This case disconnects one anchor
# at a time on a full-restraint fixture: each iteration zeroes one anchor's durability and runs one real settle,
# then checks that the removed links are exactly those that lost an anchor (or were released themselves);
# hoisting the list before the special pass leaves the link alive, so this case reddens by name. Both settle
# modes are driven: released=true (the default) and released=false (the silent settle), because the hoist
# equivalence must not depend on the release mode.
# The fixture is built through the real factories (_install_assembly / _install_template / _refresh_equipment /
# _install_special / _install_link) and holds ordinary, component, strap and crotch-rope special anchors. No
# existing fixture does that (r1_install_equipment uses the test writer `add_fixture` and clears links), so the
# fixture stays local. A shoulder strap is never a legal link end (Links rules), so straps only serve as the
# control case "breaking one removes no link".
static func _full_restraint_into(g, assembly_tier: int, link_durability: float) -> void:
 g.state.equipment=[];g.state.composites=[];g.state.special_equipment=[];g.state.links=[]
 g.state.next_equipment=1
 g.state.pressure=0.0
 # Install the leg assembly first: it holds the thigh coverage, later ordinary pieces must go around it, and the assembly can get in.
 g._install_assembly("leg","upper","fixture",2,assembly_tier)
 var templates=["rope","belt","tape","cable_tie","cord","fine_belt"]
 for slot in E.B.ARM_SLOTS+E.B.LEG_SLOTS+["eyes","mouth","neck"]:
  for layer in range(3):
   for side in ["left","right",""]:
    for template in templates:
     var piece=g._install_template(template,slot,E.maximum(2),E.maximum(2),false,"fixture",2,layer,0)
     if piece.is_empty(): continue
     if side!="": piece.side=side
     break
 # Three-tier hosts form shoulder straps on refresh (the one entry, Shoulders.refresh).
 for host in g.state.equipment.duplicate(): g._refresh_equipment(host)
 for root in g.state.composites.duplicate():
  for part in root.components.duplicate(): g._refresh_equipment(part)
 for pair in [["crotch_rope_high","special_3_a"],["nipple_clamp_medium","special_1_a"],["shaft_ring_medium","special_2_a"]]:
  g._install_special(String(pair[0]),String(pair[1]),3)
 # Links go through legal enumeration: at most one link per anchor, skip when it does not fit (the Links judgment owns the rule; the fixture does not write it).
 for anchor in g.link_anchors():
  for other in g.link_anchors():
   if String(other.id)==String(anchor.id): continue
   if g.state.links.any(func(link):return String(anchor.id) in link.ends and String(other.id) in link.ends): break
   if not g._install_link(String(anchor.id),String(other.id),link_durability,"fixture",2).is_empty(): break

static func _full_restraint() -> Dictionary:
 var g=Game.new(42)
 g.state.phase="map"
 _full_restraint_into(g,2,12.8)
 var pieces=g.physical_pieces()
 var points=0
 for piece in pieces: points+=E.physical_points(piece).size()
 # Count two separate faces: anchor kinds (straps included) and link-end kinds (straps are not accepted as link ends, so they are absent here).
 var anchor_kinds={}
 for anchor in g.link_anchors():
  var kind="special" if String(anchor.get("template",""))=="special" else ("component" if anchor.has("root_id") else ("strap" if anchor.has("shoulder_host") else "ordinary"))
  anchor_kinds[kind]=int(anchor_kinds.get(kind,0))+1
 var kinds={}
 for link in g.state.links:
  for end in link.ends:
   for anchor in g.link_anchors():
    if String(anchor.id)!=String(end): continue
    var kind="special" if String(anchor.get("template",""))=="special" else ("component" if anchor.has("root_id") else ("strap" if anchor.has("shoulder_host") else "ordinary"))
    kinds[kind]=int(kinds.get(kind,0))+1
 return {"game":g,"pieces":pieces.size(),"points":points,"links":g.state.links.size(),"anchors":g.link_anchors().size(),"kinds":kinds,"anchor_kinds":anchor_kinds}

# The anchor record: one of an ordinary piece, a special piece, a composite component or a host's shoulder
# strap; empty when absent (the caller names that in the error). `physical_pieces()` is the product's own
# single materializer of equipment + composite components + shoulder straps, so this helper does not re-list
# those containers; special pieces are not physical pieces (only the crotch anchor is a link anchor) and are
# added explicitly.
static func _anchor_record(g,id: String) -> Dictionary:
 for piece in g.physical_pieces():
  if String(piece.id)==id: return piece
 for piece in g.state.special_equipment:
  if String(piece.id)==id: return piece
 return {}

static func anchor_hoist_matches_rescan(t) -> void:
 var fixture=_full_restraint()
 var g=fixture.game
 print("REMOVAL FIXTURE pieces=%d points=%d links=%d anchors=%d anchor_kinds=%s link_end_kinds=%s" % [fixture.pieces,fixture.points,fixture.links,fixture.anchors,str(fixture.anchor_kinds),str(fixture.kinds)])
 var anchor_ids=g.link_anchors().map(func(anchor):return String(anchor.id))
 t.check(fixture.pieces>=30 and fixture.links>=20 and fixture.anchors>=30 and anchor_ids.size()==fixture.anchors,"REMOVAL anchor_hoist_matches_rescan: the full-restraint fixture is dense enough for the per-anchor sequence (a thin or empty fixture would make every clause vacuous): pieces="+str(fixture.pieces)+" points="+str(fixture.points)+" links="+str(fixture.links)+" anchors="+str(fixture.anchors)+" anchor_kinds="+str(fixture.anchor_kinds)+" link_end_kinds="+str(fixture.kinds))
 var uncovered=["ordinary","component","special"].filter(func(kind):return int(fixture.kinds.get(kind,0))==0)
 t.check(uncovered.is_empty() and int(fixture.anchor_kinds.get("strap",0))>0,"REMOVAL anchor_hoist_matches_rescan: the fixture's links reach every anchor kind a legal link can use (ordinary pieces, composite components, the crotch-rope special) and its anchor list also holds shoulder straps, so the disconnect sequence is not narrowed to one kind: link_ends="+str(fixture.kinds)+" anchors="+str(fixture.anchor_kinds)+" uncovered="+str(uncovered))
 var pristine=g.state.duplicate(true)
 var bad=[]
 var removed_any=0
 var cases=0
 for id in anchor_ids:
  g.state=pristine.duplicate(true)
  var record=_anchor_record(g,id)
  if record.is_empty():
   bad.append(id+":missing-anchor");continue
  record.durability=0.0
  var before=g.state.links.duplicate(true)
  g._cleanup()
  var remaining=g.link_anchors().map(func(anchor):return String(anchor.id))
  cases+=1
  for link in before:
   var removed=not g.state.links.any(func(kept):return String(kept.id)==String(link.id))
   var lost=not link.ends.all(func(end):return String(end) in remaining)
   var released=float(link.durability)<=0.000001
   if removed != (lost or released): bad.append(id+":"+String(link.id)+":removed="+str(removed)+":lost="+str(lost)+":released="+str(released))
   if removed: removed_any+=1
 t.check(cases==anchor_ids.size() and removed_any>0 and bad.is_empty(),"REMOVAL anchor_hoist_matches_rescan: every anchor of the full-restraint fixture is disconnected in its own settle, and the link pass removes exactly the links that lost an anchor after the earlier passes (a hoist taken before the special/ordinary passes leaves the link alive, so this is red): cases="+str(cases)+"/"+str(anchor_ids.size())+" removed_links="+str(removed_any)+" mismatches="+str(bad.size())+" first="+str(bad.slice(0,4)))
 # The second release mode: `_cleanup(false)` is the silent settle (no restraint-root card settlement). The link
 # pass and its hoist are the same, so the same per-anchor sequence must hold; a mode-only branch that drops or
 # clears links reddens only this clause.
 var silent_bad=[]
 var silent_removed=0
 for id in anchor_ids:
  g.state=pristine.duplicate(true)
  var record=_anchor_record(g,id)
  if record.is_empty():
   silent_bad.append(id+":missing-anchor");continue
  record.durability=0.0
  var before=g.state.links.duplicate(true)
  g._cleanup(false)
  var remaining=g.link_anchors().map(func(anchor):return String(anchor.id))
  for link in before:
   var removed=not g.state.links.any(func(kept):return String(kept.id)==String(link.id))
   var lost=not link.ends.all(func(end):return String(end) in remaining)
   var released=float(link.durability)<=0.000001
   if removed != (lost or released): silent_bad.append("silent:"+id+":"+String(link.id)+":removed="+str(removed)+":lost="+str(lost)+":released="+str(released))
   if removed: silent_removed+=1
 t.check(anchor_ids.size()>0 and silent_removed>0 and silent_bad.is_empty(),"REMOVAL anchor_hoist_matches_rescan: the silent settle (released=false) removes exactly the links whose anchors the earlier passes removed, so the hoist equivalence does not depend on the release mode (a mode-only link branch is red): anchors="+str(anchor_ids.size())+" removed_links="+str(silent_removed)+" mismatches="+str(silent_bad.size())+" first="+str(silent_bad.slice(0,4)))

static func run(t) -> void:
 leather_slip(t)
 preload("res://tests/shackle_cases.gd").run(t)
 mouth_stacking(t)
 release_projection(t)
 precise_positions(t)
 eye_capacity(t)
 index_slot_edge_parity(t)
 index_targets_edge_parity(t)
 index_predicate_parity(t)
 manual_release_guards_stay_in_policy(t)
 cross_release_waits_for_settle(t)
 refresh_only_forms_crossing(t)
 tightening_draws_binding_once(t)
 equal_value_tier3_follows_cause_intent(t)
 settle_writes_track_only_rope_or_no_op(t)
 anchor_hoist_matches_rescan(t)
 write_epoch_is_monotone_and_private(t)
 hook_release_guards_are_already_upstream(t)
 join_hooks_run_after_unit_commit(t)
 join_hooks_follow_post_order(t)
 tier_unit_hooks_follow_post_order(t)
 unit_frames_never_leak(t)
 join_epilogue_keeps_order(t)
 previews_never_leak_join_effects(t)
 incremental_settle_matches_full_scan(t)
 settle_residue_stays_empty(t)
 unbound_state_uses_full_scan(t)
 residue_check_is_debug_only(t)
 settle_never_enters_durability_port(t)
 unit_settle_touches_only_its_closure(t)
 unit_settle_residue_stays_empty(t)
 reinforce_writes_are_journaled(t)
 shoulder_members_are_journaled(t)
 port_journal_matches_state_diff(t)
 var wear_slots=["eyes","mouth","neck","upper_arm","forearm","wrist","palm","fingers","thigh","calf","ankle","foot","toes"]
 t.check(E.WEAR_TEXTS.keys().all(func(slot):return slot in wear_slots) and wear_slots.all(func(slot):return E.WEAR_TEXTS.has(slot)),"WEAR ordinary single restraint prose covers every approved body location")
 t.check(E.ANIMATED_WEAR_TEXTS.keys().all(func(slot):return slot in wear_slots) and wear_slots.all(func(slot):return E.ANIMATED_WEAR_TEXTS.has(slot)),"WEAR animated restraint prose covers every approved body location")
 for slot in wear_slots:
  var wear=E.wear_text("测试拘束具",slot)
  t.check(wear.count("测试拘束具")==1 and not wear.contains("{name}") and not wear.contains("固定"),"WEAR reusable exact-name prose for "+slot)
  var animated=E.wear_text("测试拘束具",slot,"animated")
  t.check(animated.count("测试拘束具")==1 and not animated.contains("{name}") and not animated.contains("她"),"WEAR animated prose keeps an autonomous subject for "+slot)
 t.check(E.wear_text("测试拘束具","foot").contains("脚掌") and not E.wear_text("测试拘束具","foot").contains("足部"),"WEAR foot copy uses the visible body name 脚掌")
 for template in ["rope","belt","tape","cable_tie"]:
  var g=Game.new(42)
  var target=g.add_fixture("thigh",4,10,false,0,template)
  t.check(not target.is_empty() and g.validate()=="","TEMPLATE valid instance "+template)
  var entry=g.get_view().bodies.filter(func(b):return b.id=="thigh")[0].equipment[0]
  t.check(entry.name==E.name_for(template,"thigh") and entry.material_name==E.material_name(target),"TEMPLATE visible name and material "+template)
  t.check(g.escape_preview(target,"strain",5).reason=="" and g.escape_preview(target,"slip",5).reason=="","TEMPLATE both damage routes "+template)
  var manual=t.find_action(g,"manual",{"target":target.id})
  if template in ["rope","belt"]:
   t.check(manual.valid and t.action(g,"manual",{"target":target.id}).ok and g._equipment(target.id).is_empty(),"TEMPLATE actual quick release "+template)
  else:
   var before=JSON.stringify(g.state)
   t.check(not manual.valid and manual.reason.contains("解除牌或工具"),"TEMPLATE structural manual rejection "+template)
   t.check(not g.dispatch(g.command(manual.payload,g.state.version),g.state.version).ok and JSON.stringify(g.state)==before,"TEMPLATE blocked manual is atomic "+template)
   var card=t.hand_card(g,"slip")
   t.check(t.action(g,"card",{"uid":card.uid,"target":target.id}).ok and g._equipment(target.id).is_empty(),"TEMPLATE actual slip still works "+template)

 var g=Game.new(4)
 for args in [["rope","fingers",false],["belt","toes",false],["tape","eyes",false],["cable_tie","mouth",false],["rope","thigh",true],["tape","thigh",true],["cable_tie","thigh",true],["missing","thigh",false]]:
  var before=JSON.stringify(g.state)
  t.check(g._install_template(args[0],args[1],4,10,args[2],"fixture").is_empty() and JSON.stringify(g.state)==before,"TEMPLATE invalid installation has no id/resource effects "+str(args))
 t.check(not g.add_fixture("fingers",4,10,false,0,"cord").is_empty(),"TEMPLATE fine cord supports fingers")
 t.check(not g.add_fixture("toes",4,10,true,0,"fine_belt").is_empty(),"TEMPLATE fine leather supports locked toes")
 var before=JSON.stringify(g.state)
 t.check(g._install_template("rope","thigh",4,10,false,"fixture",4).is_empty() and JSON.stringify(g.state)==before,"TEMPLATE undefined grade not generated")
 for bad in [NAN,INF,-1.0,11.0]:
  t.check(g._install_template("rope","thigh",bad,10,false,"fixture").is_empty() and JSON.stringify(g.state)==before,"TEMPLATE invalid durability rejected")
 t.check(g._install_template("rope","thigh",4,10,false,"fixture",1,-1,99).is_empty() and JSON.stringify(g.state)==before,"TEMPLATE invalid material version rejected")

 # Different materials share capacity, order and the same damage pipeline.
 g=Game.new(3)
 var inner=g.add_fixture("ankle",8,10,false,0,"rope")
 var outer=g.add_fixture("ankle",4,10,false,2,"belt")
 var tape=g._install_template("tape","ankle",4,10,false,"fixture")
 t.check(tape.layer==2 and g.escape_preview(inner,"slip",5).reason!="","TEMPLATE normal addition joins current outer layer")
 t.check(g.escape_preview(inner,"strain",5).reason=="" and g.escape_preview(outer,"strain",5).reason!="","TEMPLATE mixed materials force highest strain target")
 before=JSON.stringify(g.state)
 t.check(g._install_template("cable_tie","ankle",4,10,false,"fixture").is_empty() and JSON.stringify(g.state)==before,"TEMPLATE mixed materials do not increase capacity")
 g=Game.new(3)
 tape=g.add_fixture("thigh",10,10,false,0,"tape")
 t.check(g.escape_preview(tape,"slip",5).immune,"TEMPLATE tight tape uses common tier-three immunity")
 tape.durability=4
 t.check(g.escape_preview(tape,"slip",5).damage>0,"TEMPLATE loose tape has no legacy dry-adhesion block")

 # Declared enemy pools select concrete equipment only on the real enemy turn.
 for template in ["rope","belt","tape","cable_tie"]:
  for final in [false,true]:
   g=preload("res://tests/enemy_cases.gd").encounter(template+"_solo",51)
   var enemy=g.state.enemies[0]
   var deck_rng=g.state.rng.deck
   var equipment_rng=g.state.rng.equipment
   var plan=g.EnemyPlans.application([template],2 if final else 1,2,1,final)
   enemy.intent=plan
   t.check(plan.kind=="apply" and plan.templates==[template],"POOL actual source declares allowed equipment "+template)
   t.check(plan.grade==(2 if final else 1) and plan.tier==(3 if final else 2),"POOL normal application retains requested tier; departure uses declared middle-grade tier three "+template)
   t.check(g.state.rng.deck==deck_rng and g.state.rng.equipment==equipment_rng,"POOL declaration does not draw card or material randomness")
   before=JSON.stringify(g.state)
   g.get_view();g.command_facts()
   t.check(JSON.stringify(g.state)==before,"POOL preview does not choose equipment or material")
   t.check(t.action(g,"end").ok,"POOL declared installation commits through real enemy turn "+template)
   var installed=g.state.equipment.filter(func(item):return item.source==enemy.id)[0]
   t.check(installed.template==template and installed.slot in E.TEMPLATES[template].slots and installed.grade==plan.grade and installed.maximum==E.maximum(plan.grade),"POOL committed instance matches declared source and grade "+template)
   t.check(g.tier(installed.durability,installed.maximum)==plan.tier,"POOL initial durability follows declared tier")

 g=preload("res://tests/enemy_cases.gd").encounter("rope_solo")
 for i in range(g._capacity("wrist")): g._install_template("rope","wrist",4,10,false,"fixture",1)
 var next_id=g.state.next_equipment
 t.check(t.action(g,"end").ok and g.state.next_equipment==next_id+1,"POOL full wrist leaves one installation at another legal position")
 t.check(g.state.equipment.back().slot!="wrist" and g.state.equipment.back().source==g.state.enemies[0].id,"POOL actual placement observes current capacity and preserves source identity")
 g=preload("res://tests/enemy_cases.gd").encounter("rope_solo")
 var plan=g.state.enemies[0].intent.duplicate(true)
 var material_rng=g.state.rng.equipment
 g.state.round=2
 g.state.card_buffs.append("infusion_bound") # Interruption fixture; the card itself has separate casting tests.
 t.action(g,"attack",{"type":"kick","form":2,"enemy":g.state.enemies[0].id});t.action(g,"end")
 t.check(g.state.enemies[0].intent==plan and g.state.rng.equipment==material_rng,"POOL interrupt preserves declared source and does not select material early")

 # Locks select and recheck template capability, not just a target id.
 g=Game.new(42,true,"guard")
 var rope=g.add_fixture("thigh",4,10,false,0,"rope")
 var belt=g.add_fixture("calf",8)
 var lock=g.state.enemies[0]
 lock.stage=2
 t.check(g.EnemyPlans.targets(g,lock,"lock").map(func(e):return e.id)==[belt.id],"LOCK pool excludes non-lockable material")
 lock.intent={"kind":"guard_sequence","priority":false,"delayed":false,"text":"上锁","operations":[{"kind":"lock","target":rope.id,"text":"上锁","delayed":false}]}
 t.check(t.action(g,"end").ok and not rope.locked and not g._equipment(rope.id).locked,"LOCK commit rechecks non-lockable target")

 # Tool compatibility affects actual payment, durability and use counts.
 g=Game.new(42,true)
 var plastic=g.state.equipment.filter(func(e):return e.template=="cable_tie")[0]
 var shard=g.state.items[0]
 var saw=g.state.items[1]
 var cut=t.find_action(g,"item_use",{"item":shard.id,"target":plastic.id})
 before=JSON.stringify(g.state)
 t.check(not cut.valid and cut.reason.contains("塑料"),"TOOL stone explicitly cannot cut plastic")
 t.check(not g.dispatch(g.command(cut.payload,g.state.version),g.state.version).ok and JSON.stringify(g.state)==before,"TOOL incompatible attempt consumes no uses")
 t.check(t.action(g,"item_use",{"item":saw.id,"target":plastic.id}).ok and g._equipment(plastic.id).is_empty() and g._item(saw.id).uses==1 and g.state.energy==3,"TOOL saw removes basic plastic through shared zero-energy action")
 t.check(g.state.encounter==0 and g.state.reward_count==0 and g.state.rest_left==6 and g.get_view().route.is_empty(),"PRACTICE no fake battle, rewards or route")
 for i in range(6): t.action(g,"end")
 t.check(g.state.phase=="cleared" and g.state.completed_rooms.is_empty() and g.command_facts().all(func(c):return c.payload.kind=="item_discard"),"PRACTICE ends after six real rounds without tower progress; only universal item discard remains")
 t.check(g.validate()=="","PRACTICE final state valid")

# docs/spec/equipment-query-seam.md「证据入口」: presence and count predicates over ordinary equipment in precise
# positions answer exactly like the live path, and agree with the slot and point edges.
static func index_predicate_parity(t) -> void:
 var g=Game.new(42)
 g.state.equipment.clear()
 for slot in ["thigh","calf","ankle","foot","wrist","palm","eyes","fingers"]: g.add_fixture(slot,7,10)
 g._install_template("belt","calf",4,10,false,"fixture",1,0,0,"below_knee")
 g._install_template("rope","thigh",4,10,false,"fixture",1,0,0,"mid_thigh")
 var reference=Arch.UncachedGame.new(42);reference.state=g.state.duplicate(true)
 var before=g.export_snapshot()
 var previous=g._begin_equipment_read()
 var parity=true
 for slot in g.B.SLOTS:
  parity=parity and g.occupied(slot)==reference.occupied(slot) and g.capacity_used(slot)==reference.capacity_used(slot)
  for side in ["left","right"]: parity=parity and g.hand_blocked(slot,side)==reference.hand_blocked(slot,side)
 for point in g.Equipment.ANATOMY+["missing_point"]: parity=parity and g._point_count(point)==reference._point_count(point)
 parity=parity and g._capacity_issue(g.physical_pieces())==reference._capacity_issue(reference.physical_pieces())
 parity=parity and g._capacity_issue(g.physical_pieces()+g.state.equipment.duplicate())==reference._capacity_issue(reference.physical_pieces()+reference.state.equipment.duplicate())
 parity=parity and g.occupied("calf")==(not g.equipment_at("calf").is_empty()) and g.hand_blocked("palm","left")==g.equipment_at("palm").any(func(e):return e.get("side","") in ["","left"])
 parity=parity and g._point_count("below_knee")==g.physical_pieces().filter(func(e):return "below_knee" in g.Equipment.capacity_points(e)).size() and g._point_count("missing_point")==0
 g._equipment_read=previous
 t.check(parity and g.export_snapshot()==before and g._equipment_read.is_empty(),"INDEX predicate parity with the live path over precise positions")
 t.check(g.occupied("calf")==reference.occupied("calf") and g.capacity_used("calf")==reference.capacity_used("calf") and g._point_count("below_knee")==reference._point_count("below_knee"),"INDEX predicates outside a scope stay live")

static func index_fixture(kind: String):
 if kind=="component": return Game.new(42,true,"component_links")
 if kind=="shoulder": return Game.new(42,true,"shoulder_links")
 var g=Game.new(42)
 g.state.equipment.clear()
 g.add_fixture("thigh",7,10,false,0,"rope")
 g.add_fixture("thigh",7,10,false,0,"rope")
 g.add_fixture("calf",7,10,true)
 g._install_template("rope","upper_arm",10,10,false,"fixture",2)
 return g

# docs/spec/equipment-query-seam.md「证据入口」: the materialized slot edge and piece set answer exactly like the live
# path, in piece order, including the order that powers the "第 N 条" names.
static func index_slot_edge_parity(t) -> void:
 for kind in ["plain","component","shoulder"]:
  var g=index_fixture(kind)
  var reference=Arch.UncachedGame.new(42);reference.state=g.state.duplicate(true)
  var before=g.export_snapshot()
  var previous=g._begin_equipment_read()
  var pieces=g.physical_pieces()
  var live=reference.physical_pieces()
  var parity=pieces==live and pieces.map(func(e):return e.id)==live.map(func(e):return e.id)
  for slot in g.B.SLOTS+["shoulder","special_2_d"]:
   var here=g.equipment_at(slot)
   var expected=reference.equipment_at(slot)
   parity=parity and here==expected and here.map(func(e):return e.id)==expected.map(func(e):return e.id)
  for e in pieces:
   parity=parity and is_same(e,g._equipment(e.id)) and g._equipment_name(e)==reference._equipment_name(reference._equipment(e.id))
  t.check(parity,"INDEX slot edge parity with the live path "+kind)
  t.check(g._equipment_index_issues.is_empty() and g.export_snapshot()==before,"INDEX slot edge read records no self-check issue and changes no state "+kind)
  g._equipment_read=previous
  t.check(g._equipment_read.is_empty(),"INDEX slot edge read releases its materialized index "+kind)
 var plain=index_fixture("plain")
 var plain_scope=plain._begin_equipment_read()
 var thigh=plain.equipment_at("thigh")
 var labels=thigh.map(func(e):return plain._equipment_name(e))
 t.check(thigh.size()==2 and labels[0]!=labels[1] and labels.all(func(label):return label.begins_with("第")),"INDEX slot edge keeps 第 N 条 order for repeated templates "+str(labels))
 var hosts=plain.state.equipment.filter(func(e):return e.has("shoulders"))
 t.check(hosts.size()==1 and plain.physical_pieces().size()==plain.state.equipment.size()+hosts[0].shoulders.pieces.size(),"INDEX piece set is equipment plus host shoulder pieces")
 plain._equipment_read=plain_scope

# docs/spec/equipment-query-seam.md「证据入口」: the materialized slot-target edge answers exactly like the live
# path, including shoulder pieces that stay off the slot edge and zero-durability specials.
static func index_targets_edge_parity(t) -> void:
 var cases=[]
 for kind in ["plain","component","shoulder"]: cases.append({"label":kind,"game":index_fixture(kind)})
 for kind in ["component_links","shoulder_links","special_equipment","torso_binding"]: cases.append({"label":kind,"game":Game.new(42,true,kind)})
 for entry in cases:
  var g=entry.game
  if entry.label=="special_equipment":
   t.check(not g.state.special_equipment.is_empty(),"INDEX special fixture has a special piece "+entry.label)
   if not g.state.special_equipment.is_empty(): g.state.special_equipment[0].durability=0
  var reference=Arch.UncachedGame.new(42);reference.state=g.state.duplicate(true)
  var before=g.export_snapshot()
  var previous=g._begin_equipment_read()
  var slots=Arch.index_target_slots(g)
  var parity=true
  for slot in slots:
   var here=g.targets_at(slot)
   var expected=reference.targets_at(slot)
   parity=parity and here==expected and here.map(func(e):return e.id)==expected.map(func(e):return e.id)
   parity=parity and g.equipment_at(slot)==reference.equipment_at(slot) and g.occupied(slot)==reference.occupied(slot)
  var straps=g.physical_pieces().filter(func(e):return g.Equipment.is_shoulder(e) and e.durability>0)
  if not straps.is_empty():
   parity=parity and not g.targets_at("shoulder").is_empty() and g.equipment_at("shoulder").is_empty()
  for e in g.physical_pieces().filter(func(e):return g.Equipment.is_shoulder(e)):
   parity=parity and (e.durability<=0 or g.targets_at("shoulder").has(e))
   for slot in slots:
    if slot=="shoulder": continue
    parity=parity and not g.targets_at(slot).has(e)
  if entry.label=="special_equipment" and not g.state.special_equipment.is_empty():
   var dead=g.state.special_equipment[0]
   for slot in g.SpecialEquipment.occupied_slots(dead): parity=parity and g.targets_at(slot).has(dead)
  t.check(parity,"INDEX targets edge parity with the live path "+entry.label)
  t.check(g.export_snapshot()==before,"INDEX targets edge read changes no state "+entry.label)
  g._equipment_read=previous
  t.check(g._equipment_read.is_empty(),"INDEX targets edge read releases its materialized index "+entry.label)
  var live=true
  for slot in slots:
   live=live and g.targets_at(slot)==reference.targets_at(slot) and g.targets_at(slot).map(func(e):return e.id)==reference.targets_at(slot).map(func(e):return e.id)
  t.check(live,"INDEX targets_at outside a scope stays live "+entry.label)

static func release_projection(t) -> void:
 var g=Game.new(42);g.state.equipment.clear();g._discard_end();g.state.wall="normal"
 var target=g.add_fixture("ankle",10,10)
 var slip=preload("res://tests/curse_cases.gd").give(g,"slip")
 var before=g.export_snapshot()
 var c=g.get_view().display_facts.filter(func(action):return action.payload.kind=="card" and action.payload.uid==slip.uid and action.payload.get("target","")==target.id and not action.payload.free)[0]
 t.check(c.valid and c.release_preview.before==c.release_preview.after and not c.release_preview.modifiers.is_empty(),"RELEASE immune slip is an explicit zero-change preview, not a blocked method")
 t.check(g.export_snapshot()==before,"RELEASE projection changes no state, payment, logs or RNG")
 g.state.equipment.clear();g._discard_end()
 var collar=g._install_template("restriction_collar","neck",1,1,true,"fixture",3)
 var card=preload("res://tests/curse_cases.gd").give(g,"unlock")
 g.state.sure_cast=true
 c=g.get_view().display_facts.filter(func(action):return action.payload.kind=="card" and action.payload.uid==card.uid and action.payload.get("target","")==collar.id and not action.payload.free)[0]
 t.check(c.valid and c.release_preview.headline=="已上锁 → 已开锁" and not c.release_preview.headline.contains("耐久"),"RELEASE lock-only equipment shows lock outcome without fake durability")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and not g._equipment(collar.id).locked,"RELEASE original unlock transaction still commits")
 c=g.get_view().display_facts.filter(func(action):return action.payload.kind=="manual" and action.payload.target==collar.id)[0]
 t.check(c.valid and c.release_preview.headline=="整件取下","RELEASE unlocked collar uses categorical removal preview")
 t.check(g.dispatch(g.command(c.payload,g.state.version),g.state.version).ok and g._equipment(collar.id).is_empty(),"RELEASE categorical removal matches the actual lifecycle")

static func precise_positions(t) -> void:
 var g=Game.new(42)
 var low=g._install_template("rope","calf",4,10,false,"fixture",1,0,0,"mid_calf")
 var high=g._install_template("belt","calf",10,10,false,"fixture",1,2,0,"below_knee")
 t.check(g.escape_preview(low,"slip",5).reason=="" and not g.escape_preview(low,"slip",5).immune and g.escape_preview(low,"strain",5).divisor==1,"POSITION separate calf segments do not share outer blocking, tightness or stack penalty")
 var view=g.get_view();var body=view.bodies.filter(func(b):return b.id=="calf")[0]
 t.check(body.targets.values()[0].id==high.id and body.targets[low.id].position_text=="小腿中间","POSITION target boxes sort anatomically despite reverse creation order")
 t.check(view.body_coverage.points==["mid_calf","below_knee"],"POSITION ordinary piece covers exactly one physical segment")
 var saved=g.export_snapshot();var restored=Game.new(0,false,"equipment",false)
 t.check(restored.restore_snapshot(saved).ok and restored.get_view().body_coverage==view.body_coverage,"POSITION save/load preserves exact occupied locations")
 var before=JSON.stringify(g.state)
 t.check(g._install_template("rope","calf",4,10,false,"fixture",1,0,0,"thigh_root").is_empty() and JSON.stringify(g.state)==before,"POSITION foreign body position is rejected atomically")
 var cover=g._install_template("tape","calf",4,10,false,"fixture",1,3,0,"mid_calf")
 t.check(not cover.is_empty() and g.escape_preview(low,"slip",5).reason!="" and g.escape_preview(high,"strain",5).divisor==1,"POSITION same-segment outer cover blocks only that segment")
 g=Game.new(42,true,"glove_long")
 body=g.get_view().bodies.filter(func(b):return b.id=="forearm")[0]
 t.check(body.targets.size()==1 and g.get_view().body_groups.filter(func(b):return b.id=="neck")[0].targets.values().all(func(e):return e.position_text in ["左肩","右肩"]),"POSITION shoulders have own neck location instead of forearm targets")

static func mouth_stacking(t) -> void:
 var g=Game.new(42);g.state.energy=30
 var gag=g.add_fixture("mouth",8,10,false,1,"mouth_band")
 var before=g.export_snapshot()
 t.check(g._capacity("mouth")==2 and g._install_template("mouth_band","mouth",4,10,false,"fixture").is_empty() and g.state==before,"MOUTH STACK two positions do not allow a second non-tape restraint")
 var options=g.EquipmentOffers.ordinary(g,1,false,["mouth_band","mouth_tape"])
 t.check(options.size()==1 and options[0].template=="mouth_tape" and g.state==before,"MOUTH STACK real offer generator only allows tape over an occupied mouth without writes")
 var result=g.Application.execute(g,{"pool":"ordinary","templates":["mouth_tape"],"count":1,"grade":1,"tier":1},"event:mouth_stack")
 var tape=g.equipment_at("mouth").filter(func(e):return e.material=="tape")[0]
 t.check(result.ok and tape.layer>gag.layer and not g._outer(gag) and g._outer(tape) and g.validate()=="","MOUTH STACK real application installs mixed-material tape in the outer layer")
 var mouth=g.get_view().body_groups.filter(func(b):return b.id=="mouth")[0]
 t.check(mouth.capacity==2 and mouth.capacity_used==2 and mouth.sections[0].equipment[0].id==tape.id,"MOUTH STACK projection shows two positions and outer tape first")
 t.check(g.escape_preview(gag,"slip",5).reason!="" and not t.find_action(g,"manual",{"target":gag.id}).valid,"MOUTH STACK inner gag cannot be slipped or manually removed through tape")
 before=g.export_snapshot()
 t.check(g._install_template("mouth_tape","mouth",4,10,false,"fixture").is_empty() and g.state==before,"MOUTH STACK third item is rejected without consuming IDs or resources")
 var restored=Game.new(42)
 t.check(restored.restore_snapshot(before).ok and not restored._outer(restored._equipment(gag.id)),"MOUTH STACK two-piece save restores the real cover relationship")
 var broken=before.duplicate(true);var third=tape.duplicate(true)
 third.id="equipment_"+str(broken.next_equipment);broken.next_equipment+=1;broken.equipment.append(third)
 t.check(not g.restore_snapshot(broken).ok and g.state==before,"MOUTH STACK existing capacity validator rejects three saved pieces atomically")
 for layer in [gag.layer,maxi(0,gag.layer-1)]:
  broken=before.duplicate(true)
  broken.equipment.filter(func(e):return e.id==tape.id)[0].layer=layer
  t.check(not g.restore_snapshot(broken).ok and g.state==before,"MOUTH STACK aggregate validation rejects mixed tape at or below the gag layer atomically")
 broken=before.duplicate(true)
 var duplicate=gag.duplicate(true);duplicate.id=tape.id
 broken.equipment[broken.equipment.find(broken.equipment.filter(func(e):return e.id==tape.id)[0])]=duplicate
 t.check(not g.restore_snapshot(broken).ok and g.state==before,"MOUTH STACK aggregate validation rejects two non-tape mouth pieces atomically")
 var slip=t.hand_card(g,"slip")
 t.check(t.action(g,"card",{"uid":slip.uid,"target":tape.id}).ok and g._equipment(tape.id).is_empty() and g._outer(gag),"MOUTH STACK real card removes outer tape and exposes the original gag")
 t.check(t.action(g,"manual",{"target":gag.id}).ok and g.equipment_at("mouth").is_empty(),"MOUTH STACK exposed gag becomes removable through the existing action")
 g=Game.new(42)
 tape=g.add_fixture("mouth",4,10,false,0,"mouth_tape");before=g.export_snapshot()
 t.check(g._install_template("mouth_band","mouth",4,10,false,"fixture").is_empty() and g.state==before,"MOUTH STACK gag cannot be inserted under existing tape")
 var second=g.add_fixture("mouth",4,10,false,0,"mouth_tape")
 t.check(not second.is_empty() and second.layer==tape.layer and g.validate()=="","MOUTH STACK two tape pieces preserve normal same-material stacking")
 before=g.export_snapshot()
 t.check(g._install_template("mouth_tape","mouth",4,10,false,"fixture").is_empty() and g.state==before,"MOUTH STACK same-material stack also stops at two")
 g=Game.new(42);gag=g.add_fixture("mouth",4,10,false,5,"mouth_band")
 tape=g.add_fixture("mouth",4,10,false,0,"mouth_tape")
 t.check(tape.layer>gag.layer and g.validate()=="","MOUTH STACK explicit fixture layer cannot place mixed tape inside the gag")

# G-Q2-4（plan §8 Q2；Gherkin G-Q2-4）：写口本身没有策略 —— 诅咒平板锁、未开锁的限制项圈与
# `after>0` 的镣铐在直接调用 `_apply_manual_release` 时耐久不变；普通件照常写入，因此这条判据
# 不是靠「一次都没写」变绿。三个反例各自传入与现值不同的 after，所以单独去掉任一守卫都会让
# 该件耐久变成 after（≠现值）而具名红；不这样设，after 恰等于现值就会让一条守卫的去除不可观测。
static func manual_release_guards_stay_in_policy(t) -> void:
 var g=Game.new(42)
 var plain=g.add_fixture("ankle",8,16,false,0,"belt")
 g._apply_manual_release(plain,6.0)
 t.check(is_equal_approx(float(g._equipment(plain.id).durability),6.0),"REMOVAL manual_release_guards_stay_in_policy: a plain target is written by the same call, so the three guarded rows below are not vacuous: "+str(g._equipment(plain.id).durability))
 var collar=g._install_template("restriction_collar","neck",1.0,1.0,false,"fixture",3)
 var collar_before=float(g._equipment(collar.id).durability)
 g._apply_manual_release(g._equipment(collar.id),collar_before+0.4)
 t.check(is_equal_approx(float(g._equipment(collar.id).durability),collar_before),"REMOVAL manual_release_guards_stay_in_policy: an unlocked restriction collar keeps its durability because the lock-only guard stays in the policy: "+str(g._equipment(collar.id).durability))
 var types=E.SHACKLES
 if not types.is_empty():
  g.Application.execute(g,g.EnemyPlans.application([types[0]],2,2),"fixture")
  var shackle=g.state.equipment.filter(func(e):return bool(g.Equipment.is_shackle(e)))
  if not shackle.is_empty():
   var shackle_before=float(shackle[0].durability)
   g._apply_manual_release(shackle[0],shackle_before+5.0)
   t.check(is_equal_approx(float(g._equipment(String(shackle[0].id)).durability),shackle_before),"REMOVAL manual_release_guards_stay_in_policy: a shackle is never written while after>0, because the shackle guard stays in the policy: "+str(shackle_before)+" -> "+str(g._equipment(String(shackle[0].id)).durability))
 var plate_game=Game.new(42)
 plate_game._install_special("negative_vibrator_lock_catheter_high","special_2_a",3)
 plate_game.RelicEffects.gain(plate_game,"cursed_plate_lock")
 var plates=plate_game.state.special_equipment.filter(plate_game.SpecialEquipment.is_cursed_plate)
 if not plates.is_empty():
  var plate_before=float(plates[0].durability)
  plate_game._apply_manual_release(plates[0],plate_before+1.0)
  t.check(is_equal_approx(float(plate_game._equipment(String(plates[0].id)).durability),plate_before),"REMOVAL manual_release_guards_stay_in_policy: a cursed plate lock is never written, because the cursed-plate guard stays in the policy: "+str(plate_before)+" -> "+str(plate_game._equipment(String(plates[0].id)).durability))

# The left strap of a freshly installed tier-three host, created through the real fill path; both
# QX1 scenarios start from this joint fixture.
static func _crossed_left_strap(g) -> Dictionary:
 var host=g._install_template("rope","upper_arm",g.Equipment.maximum(3),g.Equipment.maximum(3),false,"fixture",3)
 for piece in g.Shoulders.attached(g,host):
  if piece.side=="left": return piece
 return {}

# G-QX1-1（H2=C；plan-delta §4.2）：事件「松一档」只改耐久，交叉解除提示由该效果末尾的
# `_cleanup()` 结算点发出，故它紧跟「…已经松到1档。」而不插在写入处。
static func cross_release_waits_for_settle(t) -> void:
 var g=Game.new(42)
 var left=_crossed_left_strap(g)
 t.check(not left.is_empty() and bool(left.crossed) and g.tier(left.durability,left.maximum)==3,"REMOVAL cross_release_waits_for_settle: the tier-three host auto-attaches a crossed left strap through the real fill path: "+str(left))
 if left.is_empty(): return
 # The crossing only forms at tier three and only clears at tier one, so a tier-two piece keeps it
 # and the easing write crosses the release boundary.
 left.durability=left.maximum*0.6
 preload("res://tests/event_cases.gd").arrive(g,"binding_cleric")
 g.state.room_event.options=[{"id":"ease_shoulder","label":"松开肩带","detail":"松开所选装备一档。","reward":"none","report":"她解开了左肩绳的固定。","effects":[{"op":"ease_restraint","target":left.id}]}]
 var logs_before=g.state.logs.size()
 t.action(g,"event",{"action":"choose","choice":"ease_shoulder"})
 var added=g.state.logs.slice(logs_before)
 var texts=added.map(func(row):return String(row.text))
 var live=g._equipment(left.id)
 t.check(added.size()>=2 and texts[0]==left.name+"已经松到1档。" and texts[1]==left.name+"已松到一档，交叉固定解除。","REMOVAL cross_release_waits_for_settle: the release belongs to the settle point, so it follows the easing line instead of preceding it: "+str(texts))
 # The data-bearing release row is located by its own shape, so this check judges the settle
 # point's state write alone and leaves the line order to the check above.
 var release=added.filter(func(row):return row.data.get("shoulder",{}).has("crossed"))
 t.check(release.size()==1 and bool(release[0].data.shoulder.crossed)==false and not bool(live.crossed) and g.validate()=="","REMOVAL cross_release_waits_for_settle: the settle point clears crossed on the piece and on its event data, and the committed state validates: crossed="+str(live.crossed)+" issue="+g.validate())
 # The message reads the whole list: a failed commit leaves no row, and a message that indexes
 # back() would raise instead of naming this check.
 t.check(not added.is_empty() and added.back().data.has("action_copy") and String(added.back().data.action_copy.get("cue",""))=="event.binding_cleric.choose" and texts.back().contains("已经松到1档。"),"REMOVAL cross_release_waits_for_settle: this event still ends on its action-copy report: "+str(texts))

# G-QX1-2（H2=C；plan-delta §4.2）：写入只成交叉、不解除；解除只在结算点；升入 3 档仍立即成交叉。
# 两段分别用肩带件与 `glove_strap` 组件（`E.is_shoulder` 的两条来源）。
static func refresh_only_forms_crossing(t) -> void:
 var cases=[
  ["strap",func(g): return _crossed_left_strap(g)],
  ["glove_strap",func(g):
   var root=g._install_assembly("glove","long","fixture",3,2,{},"straight")
   return root.components[1]]]
 for row in cases:
  var label=String(row[0])
  var g=Game.new(42)
  var piece=(row[1] as Callable).call(g)
  t.check(not piece.is_empty() and bool(piece.crossed) and g.tier(piece.durability,piece.maximum)==3,"REMOVAL refresh_only_forms_crossing: the "+label+" fixture starts crossed at tier three through the real fill or assembly path: "+str(piece))
  if piece.is_empty(): continue
  # Lower segment: the crossing history lives at tier two, then a direct write reaches tier one.
  piece.durability=piece.maximum*0.6
  piece.durability=piece.maximum*0.2
  var logs_before=g.state.logs.size()
  g._refresh_equipment(piece)
  var live=g._equipment(piece.id)
  t.check(not live.is_empty() and bool(live.crossed) and g.state.logs.size()==logs_before,"REMOVAL refresh_only_forms_crossing: a direct write down to tier one followed by the refresh keeps crossed and emits no cross event for the "+label+": crossed="+str(live.crossed)+" added="+str(g.state.logs.size()-logs_before))
  var after_refresh=g.state.logs.size()
  g._cleanup()
  live=g._equipment(piece.id)
  var added=g.state.logs.slice(after_refresh)
  t.check(not live.is_empty() and not bool(live.crossed) and added.size()==1 and String(added[0].text)==live.name+"已松到一档，交叉固定解除。","REMOVAL refresh_only_forms_crossing: the settle point then releases the crossing and emits the unchanged line for the "+label+": crossed="+str(live.crossed)+" added="+str(added.map(func(entry):return String(entry.text))))
  # Raise segment: tier two to tier three still forms the crossing at write time.
  piece=g._equipment(piece.id)
  if piece.is_empty(): continue
  piece.durability=piece.maximum
  logs_before=g.state.logs.size()
  g._refresh_equipment(piece)
  live=g._equipment(piece.id)
  added=g.state.logs.slice(logs_before)
  t.check(not live.is_empty() and bool(live.crossed) and added.size()==1 and String(added[0].text)==live.name+"已收成交叉型。","REMOVAL refresh_only_forms_crossing: a write up to tier three forms the crossing immediately and emits the unchanged line for the "+label+": crossed="+str(live.crossed)+" added="+str(added.map(func(entry):return String(entry.text))))

# G-Q2-3（plan B11、A66 NHR-3(a)；Gherkin G-Q2-3）：挂钩改走 `_apply_manual_release` 后守卫恒不触发。
# 枚举 rest＋靠墙＋挂钩次数>0 下的 `hook_facts()`：每类目标至少一条事实，凡 `valid=true` 都满足
# 非镣铐／非限制项圈／非诅咒平板锁／非诅咒眼罩／`floor_value(after)==after`；镣铐、限制项圈、
# 诅咒眼罩恒为 `valid=false`。任一合法事实触发守卫即红（该情形应停下交回，不在此处修）。
# 真实执行一步后再核「写的就是 facts 的 after、次数正好减一、日志逐字不变」。
static func hook_release_guards_are_already_upstream(t) -> void:
 var rows=[
  ["ordinary","lie",func(g): g.add_fixture("ankle",8,16,false,0,"belt"),"valid"],
  ["ordinary_tier_one","lie",func(g): g.add_fixture("ankle",4,16,false,0,"belt"),"valid"],
  ["composite_part","stand",func(g): g._install_assembly("wrap","left","fixture",2,2),"valid"],
  ["shoulder","sit",func(g):
   var host=g.add_fixture("upper_arm",8,16,false,0,"rope")
   g.Shoulders.install(g,host,"rope",2,"fixture"),"valid"],
  ["connection","sit",func(g):
   var host=g.add_fixture("upper_arm",12,16,false,0,"rope")
   g._refresh_equipment(host),"valid"],
  ["rope","lie",func(g): g.add_fixture("ankle",8,16,false,0,"rope"),"valid"],
  ["shackle","sit",func(g):
   var types=E.SHACKLES
   if types.is_empty(): return
   g.Application.execute(g,g.EnemyPlans.application([types[0]],2,2),"fixture"),"blocked"],
  ["lock_only","sit",func(g): g._install_template("restriction_collar","neck",1.0,1.0,false,"fixture",3),"blocked"],
  ["cursed_eyes","sit",func(g): g.RelicEffects.gain(g,"cursed_blindfold"),"blocked"]]
 var thin=[]
 var violated=[]
 var missing=[]
 for row in rows:
  var bucket=String(row[0])
  var g=_rest_for_hooks(t,42,String(row[1]))
  if g==null:
   missing.append(bucket)
   continue
  (row[2] as Callable).call(g)
  var valid_rows=[]
  var invalid_rows=[]
  for fact in g.hook_facts():
   var displayed=g.display_fact(fact)
   var id=String(displayed.payload.get("target",""))
   var target=g._equipment(id)
   if target.is_empty(): continue
   if not bool(displayed.valid): invalid_rows.append(id); continue
   valid_rows.append(id)
   var after=float(displayed.payload.get("after",0.0))
   if bool(g.Equipment.is_shackle(target)): violated.append(bucket+"/"+id+" shackle")
   if bool(g.Equipment.lock_only(target)): violated.append(bucket+"/"+id+" lock_only")
   if bool(g.cursed_plate(target)): violated.append(bucket+"/"+id+" cursed_plate")
   if bool(g.cursed_eyes(target)): violated.append(bucket+"/"+id+" cursed_eyes")
   if not is_equal_approx(g.RopeArt.floor_value(g,target,after),after): violated.append(bucket+"/"+id+" floor_value")
  if valid_rows.size()+invalid_rows.size()==0: thin.append(bucket+":no facts")
  if String(row[3])=="valid" and valid_rows.is_empty(): thin.append(bucket+":no legal fact")
  if String(row[3])=="blocked" and not valid_rows.is_empty(): violated.append(bucket+" legal="+str(valid_rows))
 t.check(missing.is_empty(),"REMOVAL hook_release_guards_are_already_upstream: the rest fixture is reachable through the real depart/travel/rest_begin route, so the enumeration below is not empty by accident: missing="+str(missing))
 t.check(thin.is_empty(),"REMOVAL hook_release_guards_are_already_upstream: every target class yields a hook fact and every class declared legal yields at least one legal fact (a class that silently disappears must not pass): thin="+str(thin))
 t.check(violated.is_empty(),"REMOVAL hook_release_guards_are_already_upstream: every legal hook fact already satisfies the manual-release guards (not a shackle, not lock-only, no cursed plate, no cursed eyes, floor value is the fact value), and the three guarded classes stay invalid: violated="+str(violated))
 # The executed hook writes the fact's exact value, spends exactly one use and keeps the log text.
 var executed=0
 for row in rows:
  if String(row[3])!="valid": continue
  var g=_rest_for_hooks(t,42,String(row[1]))
  if g==null: continue
  (row[2] as Callable).call(g)
  var chosen=null
  for fact in g.hook_facts():
   var displayed=g.display_fact(fact)
   if not bool(displayed.valid): continue
   var id=String(displayed.payload.get("target",""))
   if g._equipment(id).is_empty(): continue
   chosen={"id":id,"after":float(displayed.payload.get("after",0.0)),"target":g._equipment(id).duplicate(true)}
   break
  if chosen==null: continue
  var uses_before=int(g.state.hook_uses)
  var logs_before=g.state.logs.size()
  var ok=t.action(g,"hook",{"target":chosen.id}).ok
  var live=g._equipment(chosen.id)
  var landed=0.0 if live.is_empty() else float(live.durability)
  var expected="借悬挂挂钩松开"+String(chosen.target.name)+"，耐久降至"+g.number(chosen.after)+"；剩余"+str(uses_before-1)+"次。"
  var added=g.state.logs.slice(logs_before)
  var first="" if added.is_empty() else String(added[0].text)
  # At the tier-one boundary the same submit also appends the pre-existing removal line, so a zero
  # result may carry one extra entry; the hook message itself must still be the first and exact.
  t.check(ok and is_equal_approx(landed,chosen.after) and int(g.state.hook_uses)==uses_before-1 and first==expected and added.size()==(2 if chosen.after<=0.0 else 1),"REMOVAL hook_release_guards_are_already_upstream: the real submit writes exactly the fact's after value, spends one use and appends the unchanged message: bucket="+String(row[0])+" ok="+str(ok)+" landed="+str(landed)+" after="+str(chosen.after)+" uses="+str(g.state.hook_uses)+"/"+str(uses_before)+" added="+str(added.size())+" log="+first)
  executed+=1
 t.check(executed>=6,"REMOVAL hook_release_guards_are_already_upstream: at least six legal classes are executed through the real submit entry (a loop that finds nothing must not pass): executed="+str(executed))
 # G-Q2-3（输入域 battle 列）：挂钩是休息相位专有命令 —— `hook_facts` 在非 rest 相位直接返回空。
 # 战斗相位下八类目标各不产出合法挂钩事实；与上表同一事实出口核对，不手写相位判断。
 # 敏感性：去掉 `hook_facts` 首行的相位守卫（`state.phase!="rest"` 改成假）后本断言具名红。
 var battle=[]
 for row in rows:
  var bg=Game.new(42)
  (row[2] as Callable).call(bg)
  bg.state.wall_distance=0
  bg.state.hook_uses=3
  bg.state.posture=String(row[1])
  var legal=0
  for fact in bg.hook_facts():
   if bool(bg.display_fact(fact).valid): legal+=1
  if bg.state.phase!="battle" or legal!=0: battle.append(String(row[0])+":phase="+String(bg.state.phase)+" legal="+str(legal))
 t.check(battle.is_empty(),"REMOVAL hook_release_guards_are_already_upstream: the hook is a rest-phase command, so outside rest every one of the eight target classes yields no legal hook fact (the battle column of the input domain): battle="+str(battle))

# rest 相位、靠墙、挂钩次数＝3：与 `hook_facts` 的三条前置一致。路线复用既有 `tests/test_game.gd::enter_rest`
# （真实 depart／travel_step／rest_begin），不手写相位，避免夹具比生产宽松。
static func _rest_for_hooks(t, seed: int, posture: String):
 var g=Game.new(seed)
 if g.state.rooms.filter(func(r):return "rest" in r.next).is_empty(): return null
 t.enter_rest(g)
 if g.state.phase!="rest": return null
 g.state.wall_distance=0
 g.state.hook_uses=3
 g.state.posture=posture
 return g

# Q5″ 共用探针（rev3.3 gherkin-delta「钩子记录探针」）：测试侧子类只记录 `_join_hooks` 的调用与此刻
# 四容器的 id 面，不覆盖规则、不改状态、不改调用顺序。记录为空即入口不可达，调用方据此具名红。
# `bound`／`strapped` 是「固缚记录已在件上」「宿主已有两侧肩带」的同一时刻快照。
class JoinProbe extends "res://tests/game_fixture.gd":
 var joined: Array=[]
 var faces: Array=[]
 func _join_hooks(entry: Array) -> void:
  var record: Dictionary=entry[0]
  joined.append([String(record.get("id","")),String(entry[1]),bool(entry[2])])
  faces.append(_container_face())
  super._join_hooks(entry)
 func _container_face() -> Dictionary:
  return {"equipment":state.equipment.map(func(e):return String(e.id)),"composites":state.composites.map(func(e):return String(e.id)),"links":state.links.map(func(e):return String(e.id)),"special":state.special_equipment.map(func(e):return String(e.id)),"bound":state.equipment.filter(func(e):return e.has("binding")).map(func(e):return String(e.id)),"strapped":state.equipment.filter(func(e):return e.has("shoulders") and e.shoulders.pieces.size()==2).map(func(e):return String(e.id))}

# 安装后 `validate()` 失败的提交探针：只在容器已长出装备时注入一次失败，用来验证回滚不留帧。
class RollbackProbe extends "res://tests/game_fixture.gd":
 var armed=false
 var pristine: Array=[]
 func validate() -> String:
  if armed and state.equipment.size()>pristine.size(): return "test injection: validate fails after the unit committed"
  return super.validate()

static func _probe_reset(probe) -> void:
 probe.joined=[]
 probe.faces=[]

static func _kinds(probe) -> Array:
 return probe.joined.map(func(row):return String(row[1]))

static func _first_face(probe) -> Dictionary:
 return {} if probe.faces.is_empty() else probe.faces[0]

# One filter for every debug-check row: `_check_rows` is the general form (the Q6'b clauses read
# `settle_residue`／`unit_settle_residue` through it), so the Q5" frame helper delegates to it instead
# of carrying a second copy of the same predicate. Behaviour of the three `_frame_issues` callers and
# their ERROR copy is unchanged.
static func _frame_issues(g) -> Array:
 return _check_rows(g,"unit_frames")

# G-Q5-8（rev3.3 gherkin-delta）：钩子只在单位提交后跑一遍。探针在第一次钩子调用时看到的容器面必须
# 已含本单位的全部成员——物理写在前、钩子在后，五类入口逐一走真实入口，返回时不留帧。
static func join_hooks_run_after_unit_commit(t) -> void:
 # U3-1 模板件：3 档大臂绳，单位内长出固缚记录与两侧肩带。
 var g=JoinProbe.new(42)
 var piece=g.add_fixture("upper_arm",16,16,false,0,"rope")
 var face=_first_face(g)
 t.check(not piece.is_empty() and not g.joined.is_empty() and g._unit_frames.is_empty(),"REMOVAL join_hooks_run_after_unit_commit: the template unit registers its members and returns with no open frame: piece="+String(piece.get("id",""))+" joined="+str(g.joined)+" frames="+str(g._unit_frames.size()))
 t.check(not face.is_empty() and face.equipment.has(String(piece.get("id",""))) and face.bound.has(String(piece.get("id",""))) and face.strapped.has(String(piece.get("id",""))),"REMOVAL join_hooks_run_after_unit_commit: the first hook call already sees the host, its binding record and both shoulder straps, so no hook ran before the unit's physical writes: face="+str(face))
 # U3-2 复合件：整件一次加入。
 var assembly=JoinProbe.new(42)
 var root=assembly._install_assembly("glove","short","fixture",2,1)
 t.check(not root.is_empty() and _kinds(assembly)==["C"] and not _first_face(assembly).is_empty() and _first_face(assembly).composites.has(String(root.id)) and assembly._unit_frames.is_empty(),"REMOVAL join_hooks_run_after_unit_commit: the composite unit writes the root before its one join registration: root="+String(root.get("id",""))+" joined="+str(assembly.joined)+" face="+str(_first_face(assembly)))
 # U3-3 特殊件：3 档可加固平板锁与它自动扣上的加固带，锁（宿主）最后登记。
 var lock_game=JoinProbe.new(42)
 var lock=lock_game._install_special("negative_plate_lock_medium","special_2_a",3)
 var lock_face=_first_face(lock_game)
 t.check(not lock.is_empty() and _kinds(lock_game)==["R","X"] and String(lock_game.joined[1][0])==String(lock.id) and not lock_face.is_empty() and lock_face.special.size()==2 and lock_face.special.has(String(lock.id)) and lock_game._unit_frames.is_empty(),"REMOVAL join_hooks_run_after_unit_commit: the special unit writes the lock and its reinforcement strap before any hook, and registers the host last: lock="+String(lock.get("id",""))+" joined="+str(lock_game.joined)+" face="+str(lock_face))
 # U3-6 置换：旧锁先走，新锁与加固带才挂；第一次钩子调用时旧锁已不在容器里。
 var replace=JoinProbe.new(42)
 var old_lock=replace._install_special("negative_plate_lock_medium","special_2_a",2)
 _probe_reset(replace)
 var new_lock=replace._install_special("negative_vibrator_lock_catheter_high","special_2_a",3)
 var replace_face=_first_face(replace)
 t.check(not old_lock.is_empty() and not new_lock.is_empty() and not replace_face.is_empty() and replace_face.special.size()==2 and not replace_face.special.has(String(old_lock.id)) and replace_face.special.has(String(new_lock.id)) and replace._unit_frames.is_empty(),"REMOVAL join_hooks_run_after_unit_commit: the displaced lock leaves before the first hook and the replacement lock plus its strap are already in the container: old="+String(old_lock.get("id",""))+" new="+String(new_lock.get("id",""))+" face="+str(replace_face))
 # U3-4 链接绳：两端的物理件已在容器里，链接绳才登记。
 var link_game=JoinProbe.new(42)
 var forearm=link_game._install_template("rope","forearm",4,8,false,"fixture",1,-1,0,"mid_forearm")
 var wrist=link_game._install_template("rope","wrist",4,8,false,"fixture",1,-1,0,"wrist")
 _probe_reset(link_game)
 var link=link_game._install_link(forearm.id,wrist.id,4.8,"fixture",1,[],["forearm","wrist"],["mid_forearm","wrist"])
 t.check(not link.is_empty() and _kinds(link_game)==["K"] and not _first_face(link_game).is_empty() and _first_face(link_game).links.has(String(link.id)) and link_game._unit_frames.is_empty(),"REMOVAL join_hooks_run_after_unit_commit: the link unit writes the rope before its one join registration: link="+String(link.get("id",""))+" joined="+str(link_game.joined)+" face="+str(_first_face(link_game)))
 # U12/U13 `Shoulders.install`：两侧肩带在同一个单位里写完，才逐件跑钩子。
 var shoulder_game=JoinProbe.new(42)
 var host=shoulder_game.add_fixture("upper_arm",8,16,false,0,"rope")
 _probe_reset(shoulder_game)
 var accepted=shoulder_game.Shoulders.install(shoulder_game,host,"rope",2,"fixture")
 t.check(accepted and _kinds(shoulder_game)==["S","S"] and not _first_face(shoulder_game).is_empty() and _first_face(shoulder_game).strapped.has(String(host.id)) and shoulder_game._unit_frames.is_empty(),"REMOVAL join_hooks_run_after_unit_commit: the shoulder entry writes both straps before the first hook and returns with no open frame: accepted="+str(accepted)+" joined="+str(shoulder_game.joined))

# G-Q5-9（rev3.3）：同一单位里父子都加入时，钩子序＝登记序＝物理序，子件先、宿主后。
static func join_hooks_follow_post_order(t) -> void:
 var g=JoinProbe.new(42)
 var piece=g.add_fixture("upper_arm",16,16,false,0,"rope")
 var host=g._equipment(piece.id)
 var straps=host.get("shoulders",{}).get("pieces",[]) if not host.is_empty() else []
 t.check(not piece.is_empty() and _kinds(g)==["B","S","S","P"],"REMOVAL join_hooks_follow_post_order: the nested members join before the host in the pre-Q5\" statement order (binding, left strap, right strap, host): joined="+str(g.joined))
 t.check(g.joined.size()==4 and straps.size()==2 and String(g.joined[1][0])==String(straps[0].id) and String(g.joined[2][0])==String(straps[1].id),"REMOVAL join_hooks_follow_post_order: the two strap hooks follow the piece order inside the host, so the registration order equals the physical order: joined="+str(g.joined)+" straps="+str(straps.map(func(e):return String(e.id))))
 t.check(g.joined.size()==4 and not bool(g.joined[0][2]) and not bool(g.joined[1][2]) and not bool(g.joined[2][2]) and bool(g.joined[3][2]),"REMOVAL join_hooks_follow_post_order: only the unit's own member is top-level; nested members carry top=false: joined="+str(g.joined))
 var lock_game=JoinProbe.new(42)
 var lock=lock_game._install_special("negative_plate_lock_medium","special_2_a",3)
 t.check(not lock.is_empty() and _kinds(lock_game)==["R","X"] and String(lock_game.joined[1][0])==String(lock.id) and bool(lock_game.joined[1][2]) and not bool(lock_game.joined[0][2]),"REMOVAL join_hooks_follow_post_order: the reinforcement strap joins before the lock it was made for, and only the lock is top-level: joined="+str(lock_game.joined))

# G-Q5-10（rev3.3）：工厂之外的收紧写（U7 无记录升档、U8 同值收紧）由 `_tier_consequences` 自己开帧，
# 嵌套件仍是子先宿主后；这类单位没有新的顶层成员，宿主不在加入序里。
static func tier_unit_hooks_follow_post_order(t) -> void:
 var g=JoinProbe.new(42)
 var host=g.add_fixture("upper_arm",8,16,false,0,"rope")
 _probe_reset(g)
 var change=g._reinforce_equipment(host)
 t.check(change!="" and g.equipment_tier(host)==3 and _kinds(g)==["B","S","S"],"REMOVAL tier_unit_hooks_follow_post_order: the recordless tighten opens a unit at the tier write and joins binding then both straps: change="+change+" joined="+str(g.joined))
 t.check(g.joined.all(func(row):return String(row[1])!="P") and g._unit_frames.is_empty(),"REMOVAL tier_unit_hooks_follow_post_order: the tightened host was announced in the physical layer and is not joined again; the frame closes with the write: joined="+str(g.joined)+" frames="+str(g._unit_frames.size()))
 t.check(not _first_face(g).is_empty() and _first_face(g).bound.has(String(host.id)) and _first_face(g).strapped.has(String(host.id)),"REMOVAL tier_unit_hooks_follow_post_order: the first hook call already sees the binding record and both straps, so the frame opened after the physical write: face="+str(_first_face(g)))
 # U8：已有连接式固缚记录、满值 3 档、缺左肩带的宿主原地收紧。
 var equal=null
 for seed in range(1,96):
  var candidate=JoinProbe.new(seed)
  var equal_host=candidate._install_template("rope","upper_arm",candidate.Equipment.maximum(3),candidate.Equipment.maximum(3),false,"fixture",3)
  if equal_host.is_empty() or String(equal_host.get("binding",{}).get("kind",""))!="linked": continue
  var right={}
  for strap in candidate.Shoulders.attached(candidate,equal_host):
   if strap.side=="right": right=strap
   else: strap.durability=0.0
  if right.is_empty(): continue
  equal_host.binding.durability=float(equal_host.binding.maximum)*0.4
  right.durability=float(right.maximum)*0.5
  _probe_reset(candidate)
  candidate._reinforce_equipment(equal_host)
  equal=candidate
  break
 t.check(equal!=null and _kinds(equal)==["B","S"] and equal._unit_frames.is_empty(),"REMOVAL tier_unit_hooks_follow_post_order: the equal-value tighten refills the existing record (binding first) and only the missing side joins, with no leftover frame: joined="+str([] if equal==null else equal.joined))

# G-Q5-12（rev3.3）运行时：每次 `dispatch` 返回前帧栈为空，`DEBUG CHECK unit_frames` 零命中；
# 安装后校验失败的提交回滚到提交前，同样不留帧。
static func unit_frames_never_leak(t) -> void:
 var g=JoinProbe.new(42)
 g._discard_end()
 g.state.wall="normal"
 var before=g.state.equipment.size()
 var first=t.action(g,"end")
 t.check(first.ok and g.state.equipment.size()>before,"REMOVAL unit_frames_never_leak: the end-turn submit really installs equipment through the factories, so the frame check below is not vacuous: ok="+str(first.ok)+" added="+str(g.state.equipment.size()-before))
 t.check(g._unit_frames.is_empty() and _frame_issues(g).is_empty(),"REMOVAL unit_frames_never_leak: the submit returns with an empty frame stack and no unit_frames debug failure: frames="+str(g._unit_frames.size())+" debug="+str(_frame_issues(g)))
 var rollback=RollbackProbe.new(42)
 rollback._discard_end()
 rollback.state.wall="normal"
 var snapshot=rollback.export_snapshot()
 rollback.pristine=snapshot.equipment.map(func(e):return String(e.id))
 rollback.armed=true
 var failed=t.action(rollback,"end")
 rollback.armed=false
 t.check(not failed.ok and rollback.state==snapshot and rollback._unit_frames.is_empty() and _frame_issues(rollback).is_empty(),"REMOVAL unit_frames_never_leak: a submit whose post-install validation fails rolls the state back and leaves no frame or debug record behind: ok="+str(failed.ok)+" error="+String(failed.get("error",""))+" frames="+str(rollback._unit_frames.size())+" debug="+str(_frame_issues(rollback)))

# rev3.1 G-Q5-6：加入尾声的日志序与嵌套不变。带即时抽牌与下回合多抽两种 restraint_draw power 与
# restraint_mana 遗物的战斗夹具，逐类走真实安装入口，把新增日志按语义分档后比对整条序。
static func _join_tags(texts: Array) -> Array:
 return texts.map(func(text):
  var line=String(text)
  if line.contains("形成了"): return "binding"
  if line.contains("已连到") and line.contains("左肩"): return "left"
  if line.contains("已连到") and line.contains("右肩"): return "right"
  if line.contains("自动扣上了"): return "strap"
  if line.contains("欲望魔方"): return "mana"
  if line.contains("下回合多抽"): return "worn"
  return "other")

static func _join_battle_fixture(t):
 var g=Game.new(42)
 g._discard_end()
 g.state.energy=50
 g.state.wall="normal"
 g.RelicEffects.gain(g,"desire_cube")
 var free=preload("res://tests/curse_cases.gd").give(g,"restraint_embrace")
 if not t.action(g,"card",{"uid":free.uid,"free":true}).ok: return null
 var bound=preload("res://tests/curse_cases.gd").give(g,"restraint_embrace")
 if not t.action(g,"card",{"uid":bound.uid,"free":false}).ok: return null
 return g

static func join_epilogue_keeps_order(t) -> void:
 var g=_join_battle_fixture(t)
 t.check(g!=null and g.state.powers.size()==2,"REMOVAL join_epilogue_keeps_order: the battle fixture really carries both restraint_draw faces and the restraint_mana relic: powers="+str(0 if g==null else g.state.powers.size()))
 if g==null: return
 # 3 档大臂绳：固缚 → 左肩入列 → 左肩 worn → 右肩入列 → 右肩 worn → 宿主回魔 → 宿主 worn。
 var mark=g.state.logs.size()
 var piece=g._install_template("rope","upper_arm",16,16,false,"enemy",1,-1,0,"")
 var tags=_join_tags(g.state.logs.slice(mark).map(func(row):return String(row.text)))
 t.check(not piece.is_empty() and tags==["binding","left","worn","right","worn","mana","worn"],"REMOVAL join_epilogue_keeps_order: the tier-three rope keeps the pre-Q5\" order binding, left strap, left worn, right strap, right worn, host mana, host worn: tags="+str(tags)+" texts="+str(g.state.logs.slice(mark).map(func(row):return String(row.text))))
 # 3 档可加固平板锁：加固带入列 → 回魔 → worn。
 mark=g.state.logs.size()
 var lock=g._install_special("negative_plate_lock_medium","special_2_a",3)
 var lock_tags=_join_tags(g.state.logs.slice(mark).map(func(row):return String(row.text)))
 t.check(not lock.is_empty() and lock_tags==["strap","mana","worn"],"REMOVAL join_epilogue_keeps_order: the reinforced plate lock keeps the strap copy, then the host mana and worn: tags="+str(lock_tags))
 # 复合手套与链接绳：回魔 → worn，各一次（复合件另有自己的装备通告，不属加入尾声）。
 mark=g.state.logs.size()
 var root=g._install_assembly("glove","short","fixture",2,1)
 var assembly_texts=g.state.logs.slice(mark).map(func(row):return String(row.text))
 var assembly_tags=_join_tags(assembly_texts).filter(func(tag):return tag!="other")
 t.check(not root.is_empty() and assembly_tags==["mana","worn"],"REMOVAL join_epilogue_keeps_order: the composite glove keeps one mana and one worn step: tags="+str(assembly_tags)+" texts="+str(assembly_texts))
 var forearm=g._install_template("rope","forearm",4,8,false,"fixture",1,-1,0,"mid_forearm")
 var wrist=g._install_template("rope","wrist",4,8,false,"fixture",1,-1,0,"wrist")
 mark=g.state.logs.size()
 var link=g._install_link(forearm.id,wrist.id,4.8,"fixture",1,[],["forearm","wrist"],["mid_forearm","wrist"])
 var link_tags=_join_tags(g.state.logs.slice(mark).map(func(row):return String(row.text)))
 t.check(not link.is_empty() and link_tags==["mana","worn"],"REMOVAL join_epilogue_keeps_order: the link rope keeps one mana and one worn step: tags="+str(link_tags))
 # shoulder kind：两条肩带各自入列 → worn（独立夹具，避开复合件占位）。
 var shoulder_game=_join_battle_fixture(t)
 t.check(shoulder_game!=null,"REMOVAL join_epilogue_keeps_order: the shoulder case gets its own battle fixture")
 if shoulder_game==null: return
 var shoulder_host=shoulder_game.add_fixture("upper_arm",8,16,false,0,"rope")
 mark=shoulder_game.state.logs.size()
 var accepted=shoulder_game.Shoulders.install(shoulder_game,shoulder_host,"rope",2,"fixture")
 var shoulder_texts=shoulder_game.state.logs.slice(mark).map(func(row):return String(row.text))
 var shoulder_tags=_join_tags(shoulder_texts)
 t.check(accepted and shoulder_tags==["left","worn","right","worn"],"REMOVAL join_epilogue_keeps_order: the shoulder entry pairs each join copy with its own worn step: accepted="+str(accepted)+" tags="+str(shoulder_tags)+" texts="+str(shoulder_texts))
 # 每件恰一次安装反馈：单件安装只产生一条回执事件并置 installed。
 var feedback=preload("res://core/resource_feedback.gd").new()
 feedback.capture(g.state)
 g._resource_feedback=feedback
 var fresh=g._install_template("rope","calf",4,8,false,"enemy",1,-1,0,"")
 g._resource_feedback=null
 t.check(not fresh.is_empty() and feedback.events.size()==1 and feedback.installed,"REMOVAL join_epilogue_keeps_order: one ordinary install produces exactly one installation receipt and sets the installed flag: events="+str(feedback.events.size())+" installed="+str(feedback.installed))

# rev3.1 G-Q5-7（rev3.3 去掉 `room_events.compile` 一项）：在已开启回执的提交上下文里，五个预演入口
# 都不许漏出加入效果——live state（含 rng）、回执事件与标志、`_card_feedback`、帧栈全部与调用前相等。
static func previews_never_leak_join_effects(t) -> void:
 var g=JoinProbe.new(42)
 g._discard_end()
 g.state.energy=8
 g.state.wall="normal"
 g.add_fixture("ankle",4)
 g.state.room_event={"refs":{}}
 # `room_events.gd::compile` 不在本判据内（rev3.3 作废与改写一览）：先在回执上下文之外取好效果表。
 var effects=preload("res://core/room_events.gd").compile(g,"free_basic")
 _probe_reset(g)
 var before=g.export_snapshot()
 var feedback=preload("res://core/resource_feedback.gd").new()
 feedback.capture(g.state)
 g._resource_feedback=feedback
 g._card_feedback=[]
 var spec={"pool":"ordinary","templates":["rope"],"count":1,"grade":3,"tier":3,"replace":false}
 g.Application.can_apply(g,spec,"event:probe")
 g.Application.choose(g,spec,"event:probe")
 var plan=preload("res://tests/replacement_cases.gd").Replacement.plan(g,[preload("res://tests/replacement_cases.gd").request("wrist",3,3)],"fixture")
 var self_plan=preload("res://core/self_binding.gd").installation_plan(g,"self_binding",1,false)
 var probe=preload("res://core/room_events.gd").probe_result(g,effects,{},false)
 g._resource_feedback=null
 var untouched=g.state==before and feedback.events.is_empty() and not feedback.installed and not feedback.damaged and feedback.sounds.is_empty() and feedback.scoped_sounds.is_empty() and g._card_feedback.is_empty() and g._unit_frames.is_empty()
 t.check(untouched,"REMOVAL previews_never_leak_join_effects: can_apply, choose, an uncommitted replacement plan, the self-binding plan and the event result probe leave the live state, rng, receipts, card feedback and the frame stack untouched: state="+str(g.state==before)+" receipts="+str(feedback.events.size())+" installed="+str(feedback.installed)+" damaged="+str(feedback.damaged)+" sounds="+str(feedback.sounds.size())+" scoped="+str(feedback.scoped_sounds.size())+" cards="+str(g._card_feedback.size())+" frames="+str(g._unit_frames.size())+" joined="+str(g.joined))
 var live_ids=[]
 for row in [g.state.equipment,g.state.composites,g.state.links,g.state.special_equipment]:
  for item in row: live_ids.append(String(item.id))
 var leaked=g.joined.filter(func(entry):return String(entry[0]) in live_ids)
 t.check(leaked.is_empty(),"REMOVAL previews_never_leak_join_effects: every member the trial installs registered stays in the discarded trial state -- no preview-registered id reaches a live container: leaked="+str(leaked)+" joined="+str(g.joined))
 t.check(not effects.is_empty() and not probe.is_empty() and plan.has("ok") and not self_plan.is_empty(),"REMOVAL previews_never_leak_join_effects: every preview entry really ran on a reachable input, so the untouched state above is not vacuous: effects="+str(effects.size())+" probe="+str(probe)+" plan_ok="+str(plan.get("ok",false))+" self_plan="+str(self_plan.size()))
 # 安装后校验失败的提交：回滚后 state 与帧栈同样干净。
 var rollback=RollbackProbe.new(42)
 rollback._discard_end()
 rollback.state.wall="normal"
 rollback.add_fixture("ankle",4)
 var snapshot=rollback.export_snapshot()
 rollback.pristine=snapshot.equipment.map(func(e):return String(e.id))
 rollback.armed=true
 var failed=t.action(rollback,"end")
 rollback.armed=false
 t.check(not failed.ok and rollback.state==snapshot and rollback._unit_frames.is_empty() and _frame_issues(rollback).is_empty(),"REMOVAL previews_never_leak_join_effects: a submit that fails validation after its units committed restores the state and leaves no frame behind: ok="+str(failed.ok)+" frames="+str(rollback._unit_frames.size()))

# ==== Q6'b（rev3.4 gherkin G-Q6-1'…4'、9'、10'；plan-delta §2.1、§3.1）：脏件表、全扫回退、对账、件结算 ====
const Removal=preload("res://core/equipment_removal.gd")
const Journal=preload("res://tests/write_journal_game.gd")

# 差分双胞胎（G-Q6-1'）：同一份 state、同一组产品入口写。`forced` 一侧在每次结算前调用产品函数
# `Removal.replaced(self)`（产品不设测试专用入口），即全扫；另一侧用脏件表。`_debug_check` 数对账
# 调用次数（用来证明对账真的跑过——零命中不等于没跑），并把两处对账的行直接记进行表而不写日志。
class SettleTwin extends "res://tests/game_fixture.gd":
 var forced=false
 var residue_checks=0
 var unit_checks=0
 func _cleanup(released: bool=true) -> void:
  if forced: Removal.replaced(self)
  super._cleanup(released)
 func _debug_check(name: String, location: String, reason: String) -> String:
  # 两处对账的正向对照故意造出待移除成员：记进行表（判据读的就是它），但不把引擎告警写进套件
  # 日志——`DEBUG CHECK` 零命中是证据口径，负例只以一个判定结论出现。
  if name=="settle_residue" or name=="unit_settle_residue":
   if name=="settle_residue": residue_checks+=1
   else: unit_checks+=1
   if reason!="": debug_check_failures.append({"check":name,"reason":reason,"location":location})
   return reason
  return super._debug_check(name,location,reason)

static func _check_rows(g,name: String) -> Array:
 return g.debug_check_failures.filter(func(row):return String(row.get("check",""))==name)

static func _ledger_row_names() -> Array:
 return ["M01","M02","M03","M04","M05","M06","M07","M08","M09","M10","M11","M12","M13","M14"]

# 每格只用产品入口写：写口（`_write_durability`／`_apply_manual_release`）、成员通告
# （`_special_erase`／`_members_replaced`）、工厂（`add_fixture`／`_install_special`）。M08 的头部
# 马具在满拘束夹具里没有真实工厂入口（头部套件要口部宿主与专用布局），故该格用夹具记录。
static func _plate(g) -> Dictionary:
 for item in g.state.special_equipment:
  if g.SpecialEquipment.is_cursed_plate(item): return item
 return g._install_special("negative_plate_lock_medium","special_2_a",3)

# The two eye cells (M11 absolute release, M14 blindfold relic) need an eyes piece that a full scan
# keeps: eye cloth at zero durability is protected by the cursed blindfold until an absolute release
# or until the relic leaves. Installed through the factory, then written through the durability port;
# the state is fully settled before the row binds, so neither mark survives into the measured window.
static func _prepare_eyes(g) -> Dictionary:
 var eyes=g.add_fixture("eyes",8.0)
 if not "cursed_blindfold" in g.state.relics: g.state.relics.append("cursed_blindfold")
 g._write_durability(eyes,0.0)
 g._cleanup()
 return eyes

static func _ledger_prepare(g,label: String) -> void:
 if label in ["M11","M14"]: _prepare_eyes(g)

static func _ledger_row(g,label: String) -> void:
 match label:
  "M01": g._write_durability(g.state.equipment[0],0.0)
  "M02":
   var host=g.state.equipment.filter(func(e):return e.has("shoulders") and e.shoulders.pieces.size()==2)[0]
   g._write_durability(host,0.0)
  "M03": g._write_durability(_plate(g),0.0)
  "M04":
   var plate=_plate(g)
   var straps=g.state.special_equipment.filter(func(item):return g.SpecialEquipment.is_reinforcement(item) and String(item.get("owner_id",""))==String(plate.id))
   if not straps.is_empty(): g._write_durability(straps[0],0.0)
  "M05": g._special_erase(_plate(g))
  "M06": g._write_durability(g._composite_body(g.state.composites[0]),0.0)
  "M07":
   var root=g.state.composites[0]
   var part=root.components.filter(func(e):return String(e.get("part",""))!="body")
   if not part.is_empty(): g._write_durability(part[0],0.0)
  "M08":
   var head_host=g.state.equipment[0]
   g.state.composites.append({"id":"fixture_head_root","name":"测试头部马具","kind":"head","attached_to":String(head_host.id),"components":[{"id":"fixture_head_body","name":"测试头套","part":"body","durability":6.0,"maximum":10.0,"independent":false}]})
   g._write_durability(head_host,0.0)
  "M09": g._write_durability(g._equipment(String(g.state.links[0].ends[0])),0.0)
  "M10": g._write_durability(g.state.links[0],0.0)
  # M11: `_apply_manual_release` is the one write point and carries no registration of its own; the
  # `_write_durability` it calls is the only place that marks (plan-delta §1.3).
  "M11": g._apply_manual_release(_eyes(g),0.0,false,true)
  # M12: a new member is announced, so the next settle re-judges it against its own removal rule. The
  # factories reject a zero-durability install (`Equipment.validate`), so the observable cell is that
  # the added member survives the same settle on both sides and leaves no residue.
  "M12": g.add_fixture("calf",4,10)
  # M13: a whole-container replacement is announced, not marked member by member.
  "M13":
   g.state.equipment[0].durability=0.0
   g._members_replaced()
  # M14: the relic leaves the state without a member write; only the bind-time blindfold snapshot can
  # widen the window to the full scan, which is what removes the eye cloth.
  "M14": g.state.relics.erase("cursed_blindfold")

static func _eyes(g) -> Dictionary:
 return g.state.equipment.filter(func(e):return String(e.get("slot",""))=="eyes")[0]

# G-Q6-1'：同一状态、同一组产品入口写，脏件结算与强制全扫四项（编码状态、logs、rng、回执面）相等；
# 每格覆盖次数 ≥1；脏件一侧每个结算点都真的跑了 `settle_residue`。
static func incremental_settle_matches_full_scan(t) -> void:
 var fixture=_full_restraint()
 var base=fixture.game.state.duplicate(true)
 var coverage={}
 var mismatches=[]
 var removed_total=0
 var unreconciled=[]
 var residue=[]
 for label in _ledger_row_names():
  var dirty=SettleTwin.new(42)
  dirty.state=base.duplicate(true)
  var full=SettleTwin.new(42)
  full.forced=true
  full.state=base.duplicate(true)
  _ledger_prepare(dirty,label)
  _ledger_prepare(full,label)
  Removal.bind(dirty)
  Removal.bind(full)
  _ledger_row(dirty,label)
  _ledger_row(full,label)
  var pieces_before=dirty.state.equipment.size()
  dirty._cleanup()
  full._cleanup()
  Removal.unbind(dirty)
  Removal.unbind(full)
  removed_total+=maxi(0,pieces_before-dirty.state.equipment.size())
  coverage[label]=int(coverage.get(label,0))+1
  if Arch.save_text(dirty.state)!=Arch.save_text(full.state) or JSON.stringify(dirty.state.rng)!=JSON.stringify(full.state.rng) or dirty.state.logs.size()!=full.state.logs.size():
   mismatches.append(label+":dirty="+str(dirty.state.equipment.size())+"/"+str(dirty.state.links.size())+" full="+str(full.state.equipment.size())+"/"+str(full.state.links.size()))
  if not label in ["M13","M14"] and dirty.residue_checks<=0: unreconciled.append(label)
  for row in _check_rows(dirty,"settle_residue"): residue.append(label+":"+String(row.get("reason","")))
 t.check(coverage.size()==_ledger_row_names().size() and coverage.values().all(func(count):return int(count)>=1),"REMOVAL incremental_settle_matches_full_scan: every M row runs at least one cell (M02 is the shoulder control), so the matrix is not narrowed: coverage="+str(coverage))
 t.check(removed_total>0 and mismatches.is_empty(),"REMOVAL incremental_settle_matches_full_scan: the dirty ledger settles to the same encoded state, logs and rng as the forced full scan on every row (a dropped mark, an unexpanded leave or an over-narrow filter is red): removed="+str(removed_total)+" mismatches="+str(mismatches))
 t.check(unreconciled.is_empty() and residue.is_empty(),"REMOVAL incremental_settle_matches_full_scan: each bound, non-full settle of the dirty side ran the debug reconciliation (full-flag rows excepted) and left no residue: unreconciled="+str(unreconciled)+" residue="+str(residue))
 print("REMOVAL DIFFERENTIAL coverage=%s removed=%d" % [str(coverage),removed_total])

# G-Q6-2'：差分夹具与满拘束夹具上，每个绑定且非全扫的结算点之后 `settle_residue` 全扫只读、结果全假；
# 对账本身不改状态、不推进随机。零命中的正向证据是 `_debug_check` 的调用计数（见 SettleTwin）。
static func settle_residue_stays_empty(t) -> void:
 var fixture=_full_restraint()
 var base=fixture.game.state.duplicate(true)
 var checked=0
 var failures=[]
 for label in ["M01","M03","M09","M12"]:
  var g=SettleTwin.new(42)
  g.state=base.duplicate(true)
  Removal.bind(g)
  _ledger_row(g,label)
  g._cleanup()
  checked+=g.residue_checks
  for row in _check_rows(g,"settle_residue"): failures.append(label+":"+String(row.get("reason","")))
 # 满拘束夹具上逐锚点断开（同一缺陷面换成满规模输入），每次仍走绑定窗口。
 var anchors=fixture.game.link_anchors().map(func(anchor):return String(anchor.id))
 for id in anchors.slice(0,6):
  var g=SettleTwin.new(42)
  g.state=base.duplicate(true)
  Removal.bind(g)
  var record=_anchor_record(g,id)
  if record.is_empty(): continue
  g._write_durability(record,0.0)
  g._cleanup()
  checked+=g.residue_checks
  for row in _check_rows(g,"settle_residue"): failures.append(id+":"+String(row.get("reason","")))
 # 只读：对账前后编码状态与 rng 相等，且真的报出待移除成员（正向对照）。
 var probe=SettleTwin.new(42)
 probe.state=base.duplicate(true)
 Removal.bind(probe)
 var pending=probe.state.equipment[0]
 probe._write_durability(pending,0.0)
 var encoded=Arch.save_text(probe.state)
 var rng=JSON.stringify(probe.state.rng)
 Removal.settle_residue(probe)
 var hits=_check_rows(probe,"settle_residue")
 var read_only=encoded==Arch.save_text(probe.state) and rng==JSON.stringify(probe.state.rng)
 Removal.unbind(probe)
 t.check(checked>=10 and failures.is_empty(),"REMOVAL settle_residue_stays_empty: every bound, non-full settle of the differential and full-restraint fixtures ran a debug reconciliation that found no member a full scan would still remove (an unregistered write or an unexpanded leave is red): checks="+str(checked)+" failures="+str(failures))
 t.check(hits.size()==1 and String(hits[0].get("reason","")).contains(String(pending.id)) and read_only,"REMOVAL settle_residue_stays_empty: the reconciliation is read-only (encoded state, logs and rng unchanged) and does report a releasable member that the incremental settle skipped, so the empty result above is not vacuous: hits="+str(hits)+" read_only="+str(read_only))

# G-Q6-3'：`dispatch` 外直调、沙盒换表、成功解绑、失败回滚、`restore_snapshot` 之后的下一次结算——都走
# 全扫，且 live 表不被沙盒登记污染。
static func unbound_state_uses_full_scan(t) -> void:
 var direct=SettleTwin.new(42)
 direct.state.phase="map"
 var piece=direct.add_fixture("thigh",4,10)
 piece.durability=0.0
 direct._cleanup()
 t.check(direct.state.equipment.is_empty() and direct._settle_table.get("bound",null)==null,"REMOVAL unbound_state_uses_full_scan: a settle outside dispatch is unbound and removes a directly written zero-durability piece exactly as before: left="+str(direct.state.equipment.size()))
 var sandbox=SettleTwin.new(42)
 sandbox.state.phase="map"
 var host=sandbox.add_fixture("thigh",4,10)
 Removal.bind(sandbox)
 sandbox._write_durability(host,8.0)
 var live_writes=sandbox._settle_table["writes"].duplicate(true)
 var live_leaves=sandbox._settle_table["leaves"].duplicate(true)
 var live=sandbox.state
 sandbox.state=live.duplicate(true)
 sandbox._write_durability(sandbox.state.equipment[0],0.0)
 sandbox._cleanup(false)
 sandbox.state=live
 t.check(sandbox._settle_table["writes"]==live_writes and sandbox._settle_table["leaves"]==live_leaves and sandbox.state.equipment.size()==1,"REMOVAL unbound_state_uses_full_scan: a sandbox swap makes the settle a full scan and drops the sandbox port registrations instead of leaking them into the live table: writes="+str(sandbox._settle_table["writes"])+" leaves="+str(sandbox._settle_table["leaves"]))
 var settled=SettleTwin.new(42)
 settled.state.phase="battle"
 var result=t.action(settled,"end")
 var table=settled._settle_table
 t.check(result.ok and table.get("bound",null)==null and table.get("writes",{}).is_empty() and table.get("leaves",{}).is_empty(),"REMOVAL unbound_state_uses_full_scan: a successful dispatch returns unbound with empty write and leave sets, so no window outlives the call: ok="+str(result.ok)+" table="+str(table))
 var probe=RollbackProbe.new(42)
 probe._discard_end()
 probe.state.wall="normal"
 probe.add_fixture("ankle",4)
 var snapshot=probe.export_snapshot()
 probe.pristine=snapshot.equipment.map(func(e):return String(e.id))
 probe.armed=true
 var failed=t.action(probe,"end")
 probe.armed=false
 var stale=probe._settle_table
 t.check(not failed.ok and probe.state==snapshot and stale.get("bound",null)!=null and not is_same(probe.state,stale.get("bound",null)),"REMOVAL unbound_state_uses_full_scan: a rolled-back dispatch restores the state and leaves a table whose bound identity no longer matches the live state, so the next bind starts a clean window: rollback="+str(not failed.ok)+" bound="+str(stale.get("bound",null)!=null))
 # `restore_snapshot` is the real load entry: it swaps `state` for the candidate object, so a table
 # bound before the restore must not match and the next settle has to be the full scan. A valid
 # snapshot cannot carry a releasable member (`Equipment.validate` rejects durability<=0), so the
 # full scan is observed where it is visible: the debug reconciliation runs only after a bound,
 # non-full settle. The second bind + settle is the positive control that the counter does move.
 var reloaded=SettleTwin.new(42)
 reloaded.state.phase="map"
 reloaded.add_fixture("thigh",4,10)
 var restored_snapshot=reloaded.export_snapshot()
 var checks_before=reloaded.residue_checks
 Removal.bind(reloaded)
 var saved_bound=reloaded._settle_table["bound"]
 var restored=reloaded.restore_snapshot(restored_snapshot)
 var restored_state=reloaded.state
 reloaded._cleanup()
 var stale_bound=reloaded._settle_table.get("bound",null)==saved_bound and not is_same(restored_state,saved_bound)
 var full_scan_checks=reloaded.residue_checks-checks_before
 Removal.bind(reloaded)
 reloaded._cleanup()
 var incremental_checks=reloaded.residue_checks-checks_before-full_scan_checks
 Removal.unbind(reloaded)
 t.check(restored.get("ok",false) and stale_bound and full_scan_checks==0 and incremental_checks==1,"REMOVAL unbound_state_uses_full_scan: a real restore_snapshot swaps the state object, so the next settle is a full scan -- the pre-restore binding is stale, that settle ran no incremental reconciliation, and a control bind + settle does run exactly one: restored="+str(restored.get("ok",false))+" stale_bound="+str(stale_bound)+" full_scan_checks="+str(full_scan_checks)+" incremental_checks="+str(incremental_checks))

# One real unit that installs a member and breaks it before the unit commits: the join hook (and so the
# piece reconciliation) then runs with the record already at zero durability. `_unit_begin` keeps the
# frame open while the factory inside opens and closes its own nested one.
static func _unit_install_then_break(g) -> Dictionary:
 var owned=g._unit_begin()
 var piece=g.add_fixture("thigh",4,10)
 g._write_durability(piece,0.0)
 g._unit_commit(owned)
 return piece

# G-Q6-4：两个对账的每个调用点都由 `debug_checks_enabled()` 守卫（静态），关掉 debug 后同一两种局面
# 不再留痕（运行期），开 debug 时两种局面各留一次（正向对照——`_debug_check` 不看开关，调用了就留痕）。
static func residue_check_is_debug_only(t) -> void:
 var offenders=[]
 for site in [["core/equipment_removal.gd","settle"],["core/game.gd","_join_hooks"]]:
  var body=Arch.code_of_function(String(site[0]),String(site[1]))
  for line in body.split("\n"):
   var text=String(line)
   if not (text.contains("settle_residue(") or text.contains("unit_residue(")): continue
   if not text.contains("debug_checks_enabled()"): offenders.append(String(site[0])+"::"+String(site[1])+":"+text.strip_edges())
 var on=SettleTwin.new(42)
 on.state.phase="map"
 var on_piece=on.add_fixture("thigh",4,10)
 Removal.bind(on)
 on_piece.durability=0.0
 on._cleanup()
 Removal.unbind(on)
 var off=SettleTwin.new(42)
 off.state.phase="map"
 off.set_debug_checks_enabled(false)
 var off_piece=off.add_fixture("thigh",4,10)
 Removal.bind(off)
 off_piece.durability=0.0
 off._cleanup()
 Removal.unbind(off)
 var on_install=SettleTwin.new(42)
 on_install.state.phase="map"
 _unit_install_then_break(on_install)
 var off_install=SettleTwin.new(42)
 off_install.state.phase="map"
 off_install.set_debug_checks_enabled(false)
 _unit_install_then_break(off_install)
 var on_settle=_check_rows(on,"settle_residue").size()
 var on_unit=_check_rows(on_install,"unit_settle_residue").size()
 t.check(offenders.is_empty() and on_settle==1 and on_unit==1 and _check_rows(off,"settle_residue").is_empty() and _check_rows(off_install,"unit_settle_residue").is_empty(),"REMOVAL residue_check_is_debug_only: both reconciliation calls are guarded by debug_checks_enabled() and a run with checks disabled records nothing for the same two residue-producing situations, while an enabled run records exactly one each: offenders="+str(offenders)+" on="+str(on_settle)+"/"+str(on_unit)+" off="+str(_check_rows(off,"settle_residue").size())+"/"+str(_check_rows(off_install,"unit_settle_residue").size()))

# G-Q6-6'：`WriteJournalGame` 在两处 `_cleanup` 进出标记之间数耐久／品质写口的进入次数；直调与 dispatch
# 各一次结算，两者都必须为 0（红＝事实发现，交回协调者，不改判据迁就）。
static func settle_never_enters_durability_port(t) -> void:
 var fixture=_full_restraint()
 var journal=Journal.new(42)
 journal.state=fixture.game.state.duplicate(true)
 journal.state.phase="battle"
 journal._cleanup()
 var result=t.action(journal,"end")
 var rows=journal.settle_port_entries()
 var dirty=rows.filter(func(row):return int(row["durability"])>0 or int(row["quality"])>0)
 t.check(journal.cleanup_frames.size()>=2 and result.ok,"REMOVAL settle_never_enters_durability_port: one direct settle and one dispatch settle are both observed (a fixture that never settles would make the count vacuous): frames="+str(journal.cleanup_frames.size())+" ok="+str(result.ok)+" error="+String(result.get("error","")))
 t.check(dirty.is_empty(),"REMOVAL settle_never_enters_durability_port: no settle enters `_write_durability` or `_write_quality` on a full-restraint fixture, so the coupling is one-way (a settle-side durability write is red): frames="+str(rows)+" entries="+str(journal.durability_entries.size()))

# G-Q6-9'：件结算只读本 entry 的闭包。对 P／C／X／R／K／S／B 各一条真实记录直调产品函数，前后
# `_settle_table` 的写集与离开集逐项相等；正常记录不产生命中。
static func unit_settle_touches_only_its_closure(t) -> void:
 var fixture=_full_restraint()
 var g=fixture.game
 var plate=_plate(g)
 var host=g.state.equipment.filter(func(e):return e.has("shoulders") and e.shoulders.pieces.size()==2)[0]
 var entries=[[g.state.equipment[0],"P",true,{}],[g.state.composites[0],"C",true,{}],[plate,"X",true,{}],[g.state.links[0],"K",true,{}],[host.shoulders.pieces[0],"S",true,{"host":host}],[g.state.equipment[0],"B",true,{}]]
 var straps=g.state.special_equipment.filter(func(item):return g.SpecialEquipment.is_reinforcement(item))
 if not straps.is_empty(): entries.append([straps[0],"R",true,{}])
 Removal.bind(g)
 g._write_durability(g.state.equipment[1],7.0)
 var before=JSON.stringify(g._settle_table)
 var unstable=[]
 var hits=[]
 for entry in entries:
  var encoded=Arch.save_text(g.state)
  Removal.unit_residue(g,entry)
  if JSON.stringify(g._settle_table)!=before: unstable.append(String(entry[1]))
  if Arch.save_text(g.state)!=encoded: unstable.append(String(entry[1])+":state")
 for row in _check_rows(g,"unit_settle_residue"): hits.append(String(row.get("reason","")))
 Removal.unbind(g)
 t.check(entries.size()>=6 and unstable.is_empty() and hits.is_empty(),"REMOVAL unit_settle_touches_only_its_closure: the piece reconciliation writes no ledger entry and no state -- the ledger's write and leave sets and the encoded state are identical before and after every class (P/C/X/R/K/S/B), and no normal record is reported (this proves no writes, not that it reads only this entry): classes="+str(entries.map(func(entry):return String(entry[1])))+" unstable="+str(unstable)+" hits="+str(hits))

# G-Q6-10'：正常流程下 `unit_settle_residue` 零命中；同一 unit 内安装并打断的件（敏感性）恰一次命中、
# 件仍在容器里、且下一次声明结算点才移除；B 类不对账。
static func unit_settle_residue_stays_empty(t) -> void:
 var fixture=_full_restraint()
 var fixture_hits=_check_rows(fixture.game,"unit_settle_residue")
 var zero=SettleTwin.new(42)
 zero.state.phase="map"
 var installed=_unit_install_then_break(zero)
 var zero_hits=_check_rows(zero,"unit_settle_residue")
 var still_there=zero.state.equipment.any(func(e):return String(e.id)==String(installed.get("id","")))
 zero._cleanup()
 var probe=SettleTwin.new(42)
 probe.state.phase="map"
 var binding_record=probe.add_fixture("thigh",4,10)
 probe.debug_check_failures.clear()
 Removal.unit_residue(probe,[binding_record,"B",true,{}])
 t.check(fixture_hits.is_empty(),"REMOVAL unit_settle_residue_stays_empty: the full-restraint fixture installs every member class through the real factories and the piece reconciliation reports nothing: hits="+str(fixture_hits))
 t.check(not installed.is_empty() and zero_hits.size()==1 and String(zero_hits[0].get("reason","")).contains(String(installed.get("id",""))) and still_there and zero.state.equipment.is_empty() and _check_rows(probe,"unit_settle_residue").is_empty(),"REMOVAL unit_settle_residue_stays_empty: a member installed and broken inside one unit is reported exactly once by the join hook, stays in its container until the next declared settle removes it (the piece reconciliation never removes), and the binding class is not reconciled: hits="+str(zero_hits)+" still="+str(still_there)+" left="+str(zero.state.equipment.size())+" b="+str(_check_rows(probe,"unit_settle_residue").size()))
 # 对账本身不改状态、不改 logs：干净记录上直调前后编码状态与日志长度相等。
 var quiet=SettleTwin.new(42)
 quiet.state.phase="map"
 quiet.add_fixture("thigh",4,10)
 var quiet_encoded=Arch.save_text(quiet.state)
 var quiet_logs=quiet.state.logs.size()
 Removal.unit_residue(quiet,[quiet.state.equipment[0],"P",true,{}])
 t.check(quiet_encoded==Arch.save_text(quiet.state) and quiet_logs==quiet.state.logs.size() and _check_rows(quiet,"unit_settle_residue").is_empty(),"REMOVAL unit_settle_residue_stays_empty: the piece reconciliation writes no state and appends no log line (the receipt face is untouched): logs="+str(quiet_logs)+"->"+str(quiet.state.logs.size()))



# ---- Q7 unified observation exit (rev3.5 gherkin G-Q7-1′…G-Q7-3′; plan-delta §2.2／§2.3) ----
# The three judgments read the test-side journal of `tests/write_journal_game.gd`. They add no rule: every
# row is an observation of the one live write path, and a red is a missing or a forged write.

# The G-Q7-1′ host: the first ordinary upper-arm rope at grade two that carries a shoulder pair. A rope takes
# no lock, so `_reinforcement_locks` cannot fire on it and the host itself never becomes a tighten target.
static func _q7_shoulder_host(g) -> Dictionary:
 for piece in g.state.equipment:
  if not piece.has("shoulders"): continue
  if String(piece.get("slot",""))!="upper_arm": continue
  if E.base_template(String(piece.get("template","")))!="rope": continue
  if int(piece.get("grade",0))!=2: continue
  return piece
 return {}

# The dense body: the `_full_restraint` construction with the leg assembly already at tier three. It fills
# every point the six-bind pool can reach, so the application spec loses its legal positions one by one.
static func _q7_dense(g) -> void:
 _full_restraint_into(g,3,E.maximum(2))

# Every piece reaches its own maximum and takes a lock when it still has a reinforcement route, so the only
# tighten target left is `keep` (the G-Q7-1′ pair at tier two). Both writes are the real ports.
static func _q7_quiet_normalize(g, keep: Array) -> void:
 var all=g.physical_pieces()
 all.append_array(g.state.special_equipment)
 for piece in all:
  if String(piece.get("id","")) in keep: continue
  if piece.durability<piece.maximum: g._write_durability(piece,piece.maximum,true)
 for piece in all:
  if String(piece.get("id","")) in keep: continue
  if g._can_tighten(piece): g._write_locked(piece,true)

# Fill positions through the real install factories until the frozen spec has no legal position at all. The
# fixture does not write the containers itself; the greedy pass only asks the product where it may still
# install. Returns the number of additions, which the caller uses to keep the precondition non-vacuous.
static func _q7_fill_positions(g, boss, spec) -> int:
 var added=0
 for round in range(60):
  if not g.Application.can_apply(g,spec,boss.id): break
  var current=spec.duplicate(true)
  current.merge(spec.get("profiles",[{}])[0],true)
  var done=false
  for request in g.Application._raw(g,current,boss.id):
   if g.Application._request_reason(g,request,true,[])!="": continue
   var placed=false
   if String(request.get("kind",""))=="link":
    placed=not g._install_link(String(request.ends[0]),String(request.ends[1]),E.maximum(2),"fixture",2,request.get("blocked_slip",[]),request.get("slots",[]),request.get("contact_points",[])).is_empty()
   else:
    placed=not g._install_template(String(request.template),String(request.slot),E.maximum(2),E.maximum(2),false,"fixture",2,-1,0,String(request.get("point",""))).is_empty()
   if placed:
    done=true;added+=1
    break
  if not done: break
 return added

# The strap ids the journal has added and not yet removed for one host (a member row's owner is the shoulder
# host through the record's `shoulder_host` field).
static func _q7_member_set(rows: Array, host_id: String) -> Array:
 var live=[]
 for row in rows:
  if String(row.get("port",""))!="member": continue
  if String(row.get("owner",""))!=host_id: continue
  var id=String(row.get("id",""))
  if not id.begins_with(host_id+"_shoulder_"): continue
  if String(row.get("change",""))=="added":
   if not live.has(id): live.append(id)
  else:
   live.erase(id)
 return live

# The strap ids the live host record still holds (empty once the host itself left the container).
static func _q7_live_straps(g, host_id: String) -> Array:
 var host=g._equipment(host_id)
 if host.is_empty(): return []
 return host.get("shoulders",{}).get("pieces",[]).map(func(strap):return String(strap.id))

# One step's equality clause: the journal's added-minus-removed strap set equals the live host record's set.
static func _q7_pair_matches(g, host_id: String) -> bool:
 var from_journal=_q7_member_set(g.journal,host_id)
 var from_state=_q7_live_straps(g,host_id)
 from_journal.sort();from_state.sort()
 return from_journal==from_state

# G-Q7-1′ (A78 blind spot ①; replaces rev3 G-Q7-1): the six-bind fallback reaches the host's shoulder pair
# through the durability port, and each write dispatches its own tier consequence. The fixture starts from
# `six_bind_cases.encounter()`'s ported state and fills the body until the application spec has no legal
# position at all, so the freeze reports `tighten_missing` with count two and the two reinforcement
# operations can only take the pair. Red by name when the durability row or its tier row is missing, when
# the product write bypasses the port, and when the fixture stops having no legal position (a top-level
# `member`/`added` row in the window would then be the application that got through).
static func reinforce_writes_are_journaled(t) -> void:
 var six=preload("res://tests/six_bind_cases.gd").encounter()
 var g=_obs_clone(preload("res://tests/write_journal_game.gd"),six.state)
 var boss=g.state.enemies[0]
 boss.stage=4
 _q7_dense(g)
 boss.intent=g.EnemyPlans.six_plan(g,boss)
 var spec=g.EnemyPlans.application_spec(g,boss,boss.intent)
 var host=_q7_shoulder_host(g)
 var keep=[]
 if host.has("shoulders"):
  for strap in host.shoulders.pieces: keep.append(String(strap.id))
 _q7_quiet_normalize(g,keep)
 var added=_q7_fill_positions(g,boss,spec)
 _q7_quiet_normalize(g,keep)
 host=_q7_shoulder_host(g)
 var host_id=String(host.get("id",""))
 var pair=host.get("shoulders",{}).get("pieces",[]) if host.has("shoulders") else []
 var pair_ids=pair.map(func(strap):return String(strap.id))
 var frozen=bool(boss.intent.get("tighten_missing",false)) and int(boss.intent.get("count",0))==2
 t.check(host_id!="" and pair.size()==2 and frozen and not g.Application.can_apply(g,spec,boss.id) and is_equal_approx(host.durability,host.maximum) and not g._can_tighten(host) and pair.all(func(strap):return int(strap.grade)==2 and g.equipment_tier(strap)==2 and not bool(strap.get("crossed",true))),"OBS reinforce_writes_are_journaled: the G-Q7-1′ state freezes the six-bind plan at `tighten_missing` with count two because the application spec has no legal position, and the full grade-two upper-arm rope cannot be tightened further, so its two tier-two shoulder straps are the only reinforcement targets: host="+host_id+" pair="+str(pair_ids)+" frozen="+str(frozen)+" can_apply="+str(g.Application.can_apply(g,spec,boss.id))+" host_tier="+str(g.equipment_tier(host))+" can_tighten="+str(g._can_tighten(host)))
 var from=g.journal.size()
 var result=t.action(g,"end")
 var window=g.journal.slice(from)
 var real=window.filter(func(row):return not bool(row.get("trial",true)))
 var durability=real.filter(func(row):return String(row.port)=="durability" and bool(row.get("tighten",false)))
 var writes=durability.map(func(row):return String(row.id))
 var installs=real.filter(func(row):return String(row.port)=="member" and String(row.get("change",""))=="added" and String(row.get("owner",""))=="")
 t.check(result.ok and installs.is_empty(),"OBS reinforce_writes_are_journaled: the frozen turn installs no top-level record, so every member row of the window is a nested or a removal row and the two writes below are the whole reinforcement (an application that got through would leave a member/added row for a top-level id): ok="+str(result.ok)+" installs="+str(installs))
 t.check(writes.size()==2 and writes[0]!=writes[1] and pair_ids.has(writes[0]) and pair_ids.has(writes[1]),"OBS reinforce_writes_are_journaled: the fallback tightens both shoulder straps through the durability port -- exactly two real `tighten` rows with distinct ids, each the pair's own, and no third reinforcement write in the window: rows="+str(writes)+" pair="+str(pair_ids)+" durability_rows="+str(real.filter(func(row):return String(row.port)=="durability").size()))
 var chained=[]
 for index in range(real.size()):
  if String(real[index].port)!="durability" or not bool(real[index].get("tighten",false)): continue
  var follow={}
  if index+1<real.size(): follow=real[index+1]
  chained.append(String(follow.get("port",""))=="tier" and String(follow.get("id",""))==String(real[index].id) and int(follow.get("before",-1))==2 and int(follow.get("after",-1))==3 and bool(follow.get("tighten",false)))
 t.check(durability.size()==2 and chained.size()==2 and chained.all(func(ok):return ok),"OBS reinforce_writes_are_journaled: each strap write dispatches one tier-2-to-3 tightening consequence immediately after it and before the next durability row, so the port's last sentence is observed and not re-derived from the final state: chained="+str(chained)+" window="+str(real))
 var final_host=g._equipment(host_id)
 var final_pair=final_host.get("shoulders",{}).get("pieces",[]) if final_host.has("shoulders") else []
 t.check(final_pair.size()==2 and final_pair.all(func(strap):return g.equipment_tier(strap)==3 and bool(strap.get("crossed",false))),"OBS reinforce_writes_are_journaled: both straps end at tier three and crossed, which is what the two tier rows claimed: final="+str(final_pair.map(func(strap):return String(strap.id)+"/t"+str(g.equipment_tier(strap))+"/crossed="+str(strap.get("crossed",false))))+" added="+str(added))

# G-Q7-2′ (A78 blind spot ②; replaces rev3 G-Q7-2): every shoulder member change reaches `_member_changed`
# and every new strap joins through `_join_hooks` as class S. The single-host fixture is the
# `write_epoch_is_monotone_and_private` construction: a grade-one upper-arm rope below tier three with no
# pair; the tighten forms the pair, a zeroed side is announced and refilled, and two settle steps remove one
# strap and then the host's last strap. One step runs through the real `dispatch` route (a posture action
# settles at its commit), so the join layer observed is the committed one and not a direct-call shortcut.
static func shoulder_members_are_journaled(t) -> void:
 var g=preload("res://tests/write_journal_game.gd").new(42)
 var host=g._install_template("rope","upper_arm",3.0,10.0,false,"fixture",1)
 var host_id=String(host.get("id",""))
 var from=g.journal.size()
 g._reinforce_equipment(g._equipment(host_id),3)
 var establish=g.journal.slice(from)
 var pair=g.Shoulders.attached(g,g._equipment(host_id)).map(func(strap):return String(strap.id))
 var host_row=establish.any(func(row):return String(row.port)=="member" and String(row.get("change",""))=="added" and String(row.get("id",""))==host_id)
 var pair_rows=pair.size()==2 and pair.all(func(id):return establish.any(func(row):return String(row.port)=="member" and String(row.get("change",""))=="added" and String(row.get("id",""))==id))
 var steps=[_q7_pair_matches(g,host_id)]
 var refilled=""
 if pair.size()==2:
  g._equipment(pair[0]).durability=0.0
  from=g.journal.size()
  g._cleanup()
  var released_rows=g.journal.slice(from)
  g._reinforce_equipment(g._equipment(host_id),3)
  var refill_rows=g.journal.slice(from)
  refilled=String(pair[0])
  steps.append(_q7_pair_matches(g,host_id))
  pair_rows=pair_rows and released_rows.any(func(row):return String(row.port)=="member" and String(row.get("change",""))=="removed" and String(row.get("id",""))==refilled) and refill_rows.any(func(row):return String(row.port)=="member" and String(row.get("change",""))=="added" and String(row.get("id",""))==refilled)
 var remaining=_q7_live_straps(g,host_id)
 var settle_a=""
 var settle_a_rows=[]
 if remaining.size()==2:
  settle_a=String(remaining[0])
  g._equipment(settle_a).durability=0.0
  from=g.journal.size()
  var facts=g.command_facts().filter(func(fact):return String(fact.payload.kind)=="posture" and fact.valid)
  var acted={"ok":false}
  if not facts.is_empty(): acted=_obs_window(g,facts[0].payload,true)["receipt"]
  settle_a_rows=g.journal.slice(from)
  steps.append(_q7_pair_matches(g,host_id))
  pair_rows=pair_rows and bool(acted.get("ok",false)) and settle_a_rows.any(func(row):return String(row.port)=="member" and String(row.get("change",""))=="removed" and String(row.get("id",""))==settle_a)
 var last=_q7_live_straps(g,host_id)
 var settle_b=String(last[0]) if last.size()==1 else ""
 from=g.journal.size()
 var host_record=g._equipment(host_id)
 if not host_record.is_empty(): host_record.durability=0.0
 g._cleanup()
 var settle_b_rows=g.journal.slice(from)
 steps.append(_q7_pair_matches(g,host_id))
 pair_rows=pair_rows and settle_b!="" and settle_b_rows.any(func(row):return String(row.port)=="member" and String(row.get("change",""))=="removed" and String(row.get("id",""))==settle_b)
 t.check(host_row and pair_rows and steps.size()==4 and steps.all(func(ok):return ok) and refilled!="" and settle_a!="" and settle_b!="","OBS shoulder_members_are_journaled: every shoulder member change reaches `_member_changed` -- the establishment announces the host and both straps, the refill announces the released side and the refilled side, and both settle steps announce the strap they take out, while the journal's added-minus-removed strap set equals the live host record after every step: host="+host_id+" host_row="+str(host_row)+" pair_rows="+str(pair_rows)+" refilled="+refilled+" settle_a="+settle_a+" settle_b="+settle_b+" steps="+str(steps))
 var strap_added={}
 var strap_join={}
 var join_bad=[]
 for row in g.journal:
  var id=String(row.get("id",""))
  if not id.begins_with(host_id+"_shoulder_"): continue
  if String(row.get("owner",""))!=host_id: continue
  if String(row.port)=="member" and String(row.get("change",""))=="added": strap_added[id]=int(strap_added.get(id,0))+1
  if String(row.port)=="join":
   strap_join[id]=int(strap_join.get(id,0))+1
   if String(row.get("kind",""))!="S" or String(row.get("host",""))!=host_id: join_bad.append(row)
 var joined=strap_added.keys().all(func(id):return int(strap_join.get(id,0))==int(strap_added[id]))
 t.check(not strap_added.is_empty() and joined and join_bad.is_empty(),"OBS shoulder_members_are_journaled: each new strap joins through `_join_hooks` as class S -- every strap member/added row carries exactly one join row, all class S with the host id as the join owner: added="+str(strap_added)+" joins="+str(strap_join)+" bad="+str(join_bad))


# The three fields the product still writes outside a port (CC-44; NHR-R35-1's X1-X3). Each row declares one
# field and the condition that makes its write legal here; the judgment subtracts it only under that
# condition, requires the row to be exercised at least once, and requires the touched id to stay out of the
# log -- a row that never fires, or fires on a journaled id, is a lie and reddens the judgment. A row fires
# only while its record stays on both sides of the window (CC-52): a whole-record add or removal is the
# member rows' business and is never excused here.
const OBS_UNJOURNALED_FIELDS=[
 {"name":"X1","field":"remaining","condition":"changed","why":"special-equipment duration ticks without a port","anchor":"core/game.gd::_tick_special"},
 {"name":"X2","field":"reinforcement_state","condition":"retired","why":"a released reinforcement strap marks its owner in place","anchor":"core/equipment_removal.gd::settle"},
 {"name":"X3","field":"binding","condition":"erased","why":"a composite installation erases the neighbour piece's torso binding","anchor":"core/torso_binding.gd::cancel_for_assembly"}]

# One record's comparable field map: components and shoulder pieces are counted as their own records;
# shoulder-pair metadata and `binding` stay fields of their host, which is CC-47's attribution.
static func _obs_fields(record: Dictionary) -> Dictionary:
 var fields={}
 for key in record:
  if str(key)=="components": continue
  if str(key)=="shoulders":
   var pair=Dictionary(record[key]).duplicate(true)
   pair.erase("pieces")
   fields[str(key)]=JSON.stringify(pair)
   continue
  fields[str(key)]=JSON.stringify(record[key])
 return fields

# The four containers plus the nested members as `id -> {fields, parent}`. `parent` is the immediate owner:
# a component belongs to its root, a shoulder strap to its host (CC-47). A binding record is not a member
# here: it rides in its host's field map.
static func _obs_records(state: Dictionary) -> Dictionary:
 var out={}
 for root in state.composites:
  out[str(root.id)]={"fields":_obs_fields(root),"parent":""}
  for part in root.get("components",[]):
   out[str(part.id)]={"fields":_obs_fields(part),"parent":str(root.id)}
   if part.has("shoulders"):
    for strap in part.shoulders.pieces: out[str(strap.id)]={"fields":_obs_fields(strap),"parent":str(part.id)}
 for piece in state.equipment:
  out[str(piece.id)]={"fields":_obs_fields(piece),"parent":""}
  if piece.has("shoulders"):
   for strap in piece.shoulders.pieces: out[str(strap.id)]={"fields":_obs_fields(strap),"parent":str(piece.id)}
 for link in state.links:
  out[str(link.id)]={"fields":_obs_fields(link),"parent":""}
 for item in state.special_equipment:
  out[str(item.id)]={"fields":_obs_fields(item),"parent":""}
 return out

static func _obs_parents(records: Dictionary) -> Dictionary:
 var parents={}
 for id in records:
  var parent=str(records[id].get("parent",""))
  if parent!="": parents[id]=parent
 return parents

# CC-47's folding: a nested record whose owner did not exist on one side of the window is attributed to that
# owner, and the walk continues up the chain (strap -> component -> root).
static func _obs_fold(id: String, parents: Dictionary, before: Dictionary, after: Dictionary) -> String:
 var key=id
 for step in range(8):
  var parent=str(parents.get(key,""))
  if parent=="": break
  if before.has(parent) and after.has(parent): break
  key=parent
 return key

# One declared field, subtracted only under the row's own condition (CC-52, rev3.6 plan-delta §2.6). The
# caller has already required the record on both sides; the conditions are X1 any `remaining` change (the
# product also increases it, so no direction), X2 the value becoming `"removed"`, and X3 the torso-binding
# erasure an assembly installation performs -- so the window has to add a composite root, which is the
# declared write site's only caller (`core/torso_binding.gd::cancel_for_assembly`).
static func _obs_declared(row: Dictionary, before_fields: Dictionary, after_fields: Dictionary, assembly: bool) -> bool:
 var field=str(row.get("field",""))
 var before_value=str(before_fields.get(field,"<absent>"))
 var after_value=str(after_fields.get(field,"<absent>"))
 if before_value==after_value: return false
 match str(row.get("condition","")):
  "changed": return before_value!="<absent>" and after_value!="<absent>"
  "retired": return after_value=="\"removed\""
  "erased": return assembly and before_value!="<absent>" and after_value=="<absent>"
 return false

# The state difference of one window, already folded and already net of the declared fields. `triggered`
# names every declared row that actually fired, and `deducted` maps those rows to the ids they excused. A
# declared row fires -- and is subtracted -- only while the record stays on both sides (CC-52); X3
# additionally needs the window's own composite installation (the declared write site's only caller).
static func _obs_context(before: Dictionary, after: Dictionary) -> Dictionary:
 var before_records=_obs_records(before)
 var after_records=_obs_records(after)
 var parents=_obs_parents(before_records)
 parents.merge(_obs_parents(after_records),true)
 var bindings={}
 for records in [before_records,after_records]:
  for id in records:
   var binding=JSON.parse_string(str(records[id]["fields"].get("binding","null")))
   if binding is Dictionary and binding.has("parent_id"): bindings[str(binding.get("id",""))]=str(binding.parent_id)
 return {"before":before_records,"after":after_records,"parents":parents,"bindings":bindings}

static func _obs_diff(after: Dictionary, rows: Array, context: Dictionary) -> Dictionary:
 var before_records=context["before"]
 var after_records=context["after"]
 var parents=context["parents"]
 var assembly=after.composites.any(func(root):return not before_records.has(str(root.id)))
 var union=before_records.keys()
 for id in after_records: if not union.has(id): union.append(id)
 var keys={}
 var triggered={}
 var deducted={}
 for id in union:
  var before_fields=Dictionary(before_records.get(id,{}).get("fields",{}))
  var after_fields=Dictionary(after_records.get(id,{}).get("fields",{}))
  var fields=before_fields.keys()
  for field in after_fields: if not fields.has(field): fields.append(field)
  var changed=[]
  for field in fields:
   if str(before_fields.get(field,"<absent>"))!=str(after_fields.get(field,"<absent>")): changed.append(field)
  if before_records.has(id) and after_records.has(id):
   for row in OBS_UNJOURNALED_FIELDS:
    var field=str(row.get("field",""))
    if not changed.has(field): continue
    if not _obs_declared(row,before_fields,after_fields,assembly): continue
    changed.erase(field)
    triggered[str(row.get("name",""))]=true
    if not deducted.has(str(row.get("name",""))): deducted[str(row.get("name",""))]=[]
    deducted[str(row.get("name",""))].append(id)
  if changed.is_empty(): continue
  keys[_obs_fold(id,parents,before_records,after_records)]=true
 return {"keys":keys,"triggered":triggered,"deducted":deducted}

# The log side of the same window, folded with the same rule. `rows` is the window's real rows, or the union
# of real and sandbox rows when the window opened the replacement sandbox (CC-45).
static func _obs_log_key(row: Dictionary, context: Dictionary) -> String:
 var id=str(row.get("id",""))
 var owner=str(row.get("owner",""))
 if owner!="" and str(context["bindings"].get(id,""))==owner: id=owner
 return _obs_fold(id,context["parents"],context["before"],context["after"])

static func _obs_log_keys(rows: Array, context: Dictionary) -> Dictionary:
 var keys={}
 for row in rows:
  keys[_obs_log_key(row,context)]=true
 return keys

# Equal-value touches (CC-46): a port row whose own from/to are the same, so the log is right and the state
# difference has nothing to show for it.
static func _obs_equal_row(row: Dictionary) -> bool:
 return str(row.get("port",""))=="durability" and str(row.get("from",""))==str(row.get("to",""))

static func _obs_equal_keys(rows: Array, context: Dictionary) -> Dictionary:
 var keys={}
 for row in rows:
  if not _obs_equal_row(row): continue
  keys[_obs_log_key(row,context)]=true
 return keys

# Transitional members (CC-46): a logged id that exists on neither side of the window -- a member a factory
# created and the same window's settle retired (C0: enemy install, turn-start climax slip).
static func _obs_transition_keys(rows: Array, phantom: Dictionary, context: Dictionary) -> Dictionary:
 var added={}
 var lifecycles={}
 for row in rows:
  if bool(row.get("trial",false)) or str(row.get("port",""))!="member": continue
  var id=str(row.get("id",""))
  if str(row.get("change",""))=="added": added[id]=true
  elif str(row.get("change",""))=="removed" and added.has(id): lifecycles[id]=true
 var keys={}
 for row in rows:
  var id=str(row.get("id",""))
  var key=_obs_log_key(row,context)
  if context["bindings"].has(id) or not phantom.has(key): continue
  if not lifecycles.has(id): continue
  if context["before"].has(id) or context["after"].has(id): continue
  keys[key]=true
 return keys

static func _obs_transition_boundary(start: Dictionary) -> Dictionary:
 var context=_obs_context(start,start)
 var present_id=str(start.equipment[0].id)
 var absent_id=present_id+"_absent"
 while context["before"].has(absent_id): absent_id+="_absent"
 var absent_rows=[{"port":"member","id":absent_id,"owner":"","change":"added","trial":false},{"port":"member","id":absent_id,"owner":"","change":"removed","trial":false}]
 var present_rows=[{"port":"member","id":present_id,"owner":"","change":"added","trial":false},{"port":"member","id":present_id,"owner":"","change":"removed","trial":false}]
 var unpaired_row={"port":"durability","id":absent_id,"owner":"","from":1.0,"to":2.0,"trial":false}
 return {"transitional_accepts_absent":_obs_transition_keys(absent_rows,{absent_id:true},context).has(absent_id),"transitional_rejects_present":_obs_transition_keys(present_rows,{present_id:true},context).is_empty(),"transitional_requires_lifecycle":_obs_transition_keys([unpaired_row],{absent_id:true},context).is_empty()}

static func _obs_pair_boundaries() -> Dictionary:
 var before={"equipment":[{"id":"host","shoulders":{"template":"shoulder","grade":2,"material":"rope","source":"fixture","pieces":[]}}],"composites":[],"links":[],"special_equipment":[]}
 var checks={}
 for field in ["template","grade","material","source"]:
  var after=before.duplicate(true)
  after.equipment[0].shoulders[field]=3 if field=="grade" else "changed"
  checks[field]=_obs_diff(after,[],_obs_context(before,after))["keys"].has("host")
 var absent=before.duplicate(true)
 absent.equipment[0].erase("shoulders")
 checks["removed"]=_obs_diff(absent,[],_obs_context(before,absent))["keys"].has("host")
 checks["added"]=_obs_diff(before,[],_obs_context(absent,before))["keys"].has("host")
 checks["unchanged"]=_obs_diff(before,[],_obs_context(before,before))["keys"].is_empty()
 return checks

static func _obs_binding_boundary(start: Dictionary) -> Dictionary:
 var g=_obs_clone(preload("res://tests/write_journal_game.gd"),start)
 var host={}
 for piece in g.state.equipment:
  if piece.has("binding") and piece.binding.has("durability") and piece.binding.has("parent_id"):
   host=piece
   break
 if host.is_empty(): return {"ok":false,"target":"absent"}
 var before=g.state.duplicate(true)
 var from=g.journal.size()
 g._write_durability(host.binding,float(host.binding.durability)-0.1,false)
 var rows=g.journal.slice(from)
 var context=_obs_context(before,g.state)
 var diff=_obs_diff(g.state,rows,context)["keys"]
 var log=_obs_log_keys(rows,context)
 var missing=diff.keys().filter(func(id):return not log.has(id))
 var forged=log.keys().filter(func(id):return not diff.has(id))
 return {"ok":rows.size()>0 and diff.has(str(host.id)) and missing.is_empty() and forged.is_empty(),"host":str(host.id),"binding":str(host.binding.id),"missing":missing,"forged":forged,"rows":rows}

static func _obs_x3_boundary() -> bool:
 var before={"equipment":[{"id":"neighbour","binding":{"id":"binding","parent_id":"neighbour"}}],"composites":[],"links":[],"special_equipment":[]}
 var after=before.duplicate(true)
 after.equipment[0].erase("binding")
 after.composites.append({"id":"root","components":[]})
 var context=_obs_context(before,after)
 var absent=_obs_diff(after,[],context)
 var logged=_obs_diff(after,[{"port":"member","change":"added","id":"root"}],context)
 return absent==logged and absent["triggered"].has("X3") and absent["deducted"].get("X3",[])==["neighbour"]

static func _obs_anchors_valid() -> bool:
 for row in OBS_UNJOURNALED_FIELDS:
  var anchor=str(row.get("anchor","")).split("::")
  if anchor.size()!=2: return false
  var source=FileAccess.get_file_as_string("res://"+anchor[0])
  if not source.contains("func "+anchor[1]+"("): return false
 return true

# The first valid payload of one action kind, so a window is driven by the real command table.
static func _obs_payload(g, kind: String) -> Dictionary:
 for fact in g.command_facts():
  if str(fact.payload.kind)==kind and fact.valid: return fact.payload
 return {}

# One window: the pre-state, an optional fixture write inside the window, one real `dispatch`, its journal
# slice and both sides of the state difference. `label` names the window in the segment (the B segment's
# five windows are B0-B4).
static func _obs_window(g, payload: Dictionary, record: bool, extra=null, label: String="") -> Dictionary:
 var before=g.state.duplicate(true) if record else {}
 var from=g.journal.size() if record else 0
 if extra!=null: extra.call()
 var receipt=g.dispatch(g.command(payload,g.state.version),g.state.version)
 if not record:
  return {"label":label,"ok":bool(receipt.get("ok",false)),"receipt":receipt,"mixed":false,"trial":[],"real":[],"rows":[],"diff":{"keys":{},"triggered":{},"deducted":{}},"log":{},"equal":{},"phantom":{},"transitional":{},"before":{},"after":{}}
 var rows=g.journal.slice(from)
 var real=rows.filter(func(row):return not bool(row.get("trial",true)))
 var trial=rows.filter(func(row):return bool(row.get("trial",false)))
 var mixed=not trial.is_empty()
 var context=_obs_context(before,g.state)
 var diff=_obs_diff(g.state,real,context)
 var log=_obs_log_keys(rows if mixed else real,context)
 var equal=_obs_equal_keys(real,context)
 var phantom={}
 for key in log:
  if not diff["keys"].has(key): phantom[key]=true
 var transitional=_obs_transition_keys(real,phantom,context)
 return {"label":label,"ok":bool(receipt.get("ok",false)),"receipt":receipt,"error":str(receipt.get("error","")),"mixed":mixed,"rows":rows,"real":real,"trial":trial,"diff":diff,"log":log,"equal":equal,"phantom":phantom,"transitional":transitional,"before":before,"after":g.state.duplicate(true)}

# A piece a link ends on: releasing it must take the link with it in the same settle.
# The first link a strain card can release: an independent band blocked by a link that covers the same area is
# unlocked by releasing that link first.
static func _obs_link_blocker(g) -> String:
 for link in g.state.links:
  if not _obs_card(g,str(link.id)).is_empty(): return str(link.id)
 return ""
static func _obs_link_end(g) -> Dictionary:
 for link in g.state.links:
  var piece=g._equipment(str(link.ends[0]))
  if not piece.is_empty() and float(piece.durability)>0.0: return piece
 return {}

# The first valid card payload for a target. Two branches of one selector, because the card table has two
# shapes of usable damage: an ordinary preview (`damage>0`) and a reinforcement strap, whose preview damage
# is always zero and whose damage only arrives through `tool_bonus` (rev3.6 plan-delta §2.4).
static func _obs_card(g, target: String, by_bonus: bool=false) -> Dictionary:
 for fact in g.command_facts():
  if str(fact.payload.kind)!="card" or not fact.valid: continue
  if str(fact.payload.get("target",""))!=target: continue
  if by_bonus:
   var bonus=fact.payload.get("tool_bonus",{})
   if bonus is Dictionary and not bonus.is_empty(): return fact.payload
   continue
  if float(fact.payload.get("preview",{}).get("damage",0.0))<=0.0: continue
  return fact.payload
 return {}

# A fixture write that keeps the record legal at the command boundary: a strain card only offers the piece
# whose tightness is the highest on its part, so a released target has to be shrunk instead of zeroed (a zero
# durability record is invalid and every dispatch would be refused before it runs). Everything else -- the
# damage, the release and the settle that removes the record -- stays the product's own.
# A special record keeps its design maximum (validate compares it), so a released strain target is weakened in
# place instead: durability stays legal and the card's own damage finishes the release.
static func _obs_weaken(g, id: String) -> void:
 var record=g._equipment(id)
 if record.is_empty(): return
 record.durability=minf(float(record.durability),1.0)
static func _obs_shrink(g, id: String) -> void:
 var record=g._equipment(id)
 if record.is_empty(): return
 record.maximum=1.0
 record.durability=1.0

# The inline sequence of G-Q7-3' (CC-48): one dispatch per window, with the fixture writes that make the next
# window reach the class it is there for. The plain instance runs the same function, so the transparency
# clause compares the same sequence without a second copy.
static func _obs_run(g) -> Dictionary:
 var record=g.get("journal")!=null
 var run={"windows":[],"receipts":[],"journal":record}
 for stage in [2,3,4,5,6,7]:
  var boss=g.state.enemies[0] if not g.state.enemies.is_empty() else {}
  if boss.is_empty(): break
  boss.stage=stage
  boss.intent=g.EnemyPlans.six_plan(g,boss)
  _obs_push(run,g,_obs_payload(g,"end"))
 var boss=g.state.enemies[0] if not g.state.enemies.is_empty() else {}
 var body={}
 for root in g.state.composites: body=g._composite_body(root)
 if not body.is_empty() and not boss.is_empty():
  body.durability=float(body.maximum)
  boss.intent={"kind":"lock","target":str(body.id),"text":"为一件拘束具上锁","delayed":false}
  _obs_push(run,g,_obs_payload(g,"end"))
 # The release of a link's end: the fixture clears the target's own binding first, so the assembly window
 # below is the one that exercises the cancelled binding (CC-44's X3), and shrinks the target to the top
 # tightness the strain offer requires. The damage, the release and the settle stay the product's own.
 var anchor=_obs_link_end(g)
 if not anchor.is_empty():
  g._equipment(str(anchor.id)).erase("binding")
  _obs_shrink(g,str(anchor.id))
  var cut=_obs_card(g,str(anchor.id))
  if not cut.is_empty():
   _obs_push(run,g,cut)
 # The assembly install runs inside the window: a composite request is a factory call here, not a command, and
 # it is the only path that cancels a neighbour's torso binding (CC-44's X3). The neighbours are otherwise
 # untouched in this window, so the erased field is exactly what the declaration excuses. Bindings are
 # refreshed first because the release window above cleared its own piece's binding.
 for piece in g.state.equipment:
  if g.Binding.eligible(piece): g._refresh_equipment(piece)
 if not boss.is_empty():
  var install=func(): g._install_assembly("glove","short","fixture",2,1)
  _obs_push(run,g,_obs_payload(g,"end"),install)
 # Every component of the first assembly is released so its root leaves as a whole (`root.components` empties
 # and `_member_changed(root,"removed")`). An independent band can be blocked by a link that covers the same
 # area, so the blocking link is released first -- both steps are ordinary strain dispatches.
 var part_ids=[]
 for root in g.state.composites:
  for part in root.components: part_ids.append(str(part.id))
 for id in part_ids:
  _obs_shrink(g,id)
  var cut_part=_obs_card(g,id)
  var tries=0
  while cut_part.is_empty() and tries<8:
   tries+=1
   var blocker=_obs_link_blocker(g)
   if blocker=="": break
   _obs_shrink(g,blocker)
   var cut_link=_obs_card(g,blocker)
   if cut_link.is_empty(): break
   _obs_push(run,g,cut_link)
   _obs_shrink(g,id)
   cut_part=_obs_card(g,id)
  if not cut_part.is_empty():
   _obs_push(run,g,cut_part)
 var plate=g._install_special("negative_plate_lock_medium","special_2_a",3)
 var strap={}
 for item in g.state.special_equipment:
  if g.SpecialEquipment.is_reinforcement(item): strap=item; break
 if not plate.is_empty() and not strap.is_empty():
  _obs_weaken(g,str(strap.id))
  var cut_strap=_obs_card(g,str(strap.id))
  if not cut_strap.is_empty():
   _obs_push(run,g,cut_strap)
 var boss3=g.state.enemies[0] if not g.state.enemies.is_empty() else {}
 if not boss3.is_empty():
  boss3.intent=g.EnemyPlans.six_special(g.Enemies.TYPES[boss3.type],2,1,true)
  _obs_push(run,g,_obs_payload(g,"end"))
 var equal_id=""
 for piece in g.state.equipment:
  if float(piece.durability)>0.0: equal_id=str(piece.id); break
 if equal_id!="":
  var extra=func(): g._write_durability(g._equipment(equal_id),float(g._equipment(equal_id).durability),false)
  _obs_push(run,g,_obs_payload(g,"end"),extra)
 return run

# The wrist piece the B segment frees: an ordinary piece on the wrist with no side and no owner, the widest
# one (highest durability, then highest id) so the choice follows state and never an id literal (§2.1). The
# product settle releases it, which frees the wrist capacity point the glove intent needs.
static func _obs_wrist_piece(g) -> Dictionary:
 var best={}
 for piece in g.state.equipment:
  if str(piece.get("slot",""))!="wrist": continue
  if piece.has("root_id") or piece.has("parent_id"): continue
  if str(piece.get("side",""))!="": continue
  if best.is_empty(): best=piece;continue
  var wider=float(piece.durability)>float(best.durability)
  if is_equal_approx(float(piece.durability),float(best.durability)): wider=str(piece.id)>str(best.id)
  if wider: best=piece
 return best

# One segment's start (G-Q6-6′): the full-restraint state ported into `g_class`, the solo six-bind entrance
# selected and the battle started. Both instances of a segment get the same base, so the transparency
# clause compares the same start.
static func _obs_clone(g_class, base: Dictionary) -> Object:
 var g=g_class.new(42)
 g.state=base.duplicate(true)
 return g

static func _obs_port(g_class, base: Dictionary) -> Object:
 var g=_obs_clone(g_class,base)
 g.state.room_encounters.entrance="six_bind_solo"
 g._start_battle()
 return g

# The reinforcement strap a special piece owns: its `owner_id` points back, so the B fixtures never
# hard-code a strap id.
static func _obs_reinforcement_of(g, owner: Dictionary) -> Dictionary:
 var owner_id=str(owner.get("id",""))
 if owner_id=="": return {}
 for item in g.state.special_equipment:
  if str(item.get("owner_id",""))==owner_id: return item
 return {}

static func _obs_root_by_kind(g, kind: String) -> Dictionary:
 for root in g.state.composites:
  if str(root.get("kind",""))==kind: return root
 return {}

# `strap_followed` (rev3.6 §2.5, new coverage class): a main piece and the reinforcement strap whose
# `owner_id` points at it both leave `special_equipment` in the same window. A whole-piece removal on its
# own is not this class -- the strap has to follow its owner.
static func _obs_strap_followed(before: Dictionary, after: Dictionary) -> bool:
 var after_ids={}
 for item in after.special_equipment: after_ids[str(item.get("id",""))]=true
 for owner in before.special_equipment:
  var owner_id=str(owner.get("id",""))
  if owner_id=="" or after_ids.has(owner_id): continue
  for strap in before.special_equipment:
   if str(strap.get("owner_id",""))!=owner_id: continue
   if not after_ids.has(str(strap.get("id",""))): return true
 return false

# One segment window: a B payload that is missing is recorded by name (so the coverage clause reddens on
# it) instead of being skipped silently; both segments use the same bracket and receipt collection.
static func _obs_push(run: Dictionary, g, payload: Dictionary, extra=null, label: String="") -> void:
 if label!="" and payload.is_empty():
  run["skipped"].append(label+":no_payload")
  return
 var window=_obs_window(g,payload,g.get("journal")!=null,extra,label)
 run["windows"].append(window)
 run["receipts"].append(window["receipt"])
 if label!="": run["labels"].append(label)

# The B segment of G-Q7-3′ (rev3.6 §2): five windows that reach the classes the A segment cannot. Every
# write outside a window is a fixture write through a product entry (special install, lock port, tool gain,
# intent) or a plain field write (durability, relic list); every window is one real `dispatch`, so the same
# function runs on both instance classes for the transparency clause.
# B0 frees a tier-three plate lock through the lock port and releases it whole, so the settle takes the
# reinforcement strap with it (`_strap_follows`) -- the only window that exhibits `strap_followed`.
# B1 cuts a second lock's strap with a real `tool_bonus` card under `tentacle_friend`, so the settle marks
# the surviving owner `reinforcement_state="removed"` (X2); the relic is removed after the window.
# B2 lets the enemy's `assembly` intent install the glove through the end turn, cancelling eight
# neighbours' torso binding (X3) and refilling the energy the two glove windows spend.
# B3/B4 release one glove shoulder strap and then the glove body, so `root.components` empties and the
# whole root follows (removed_root).
static func _obs_run_b(g) -> Dictionary:
 var run={"windows":[],"receipts":[],"labels":[],"skipped":[]}
 var plate0=g._install_special("negative_plate_lock_medium","special_2_a",3)
 var strap0=_obs_reinforcement_of(g,plate0)
 if plate0.is_empty() or strap0.is_empty():
  run["skipped"].append("B0:no_lock")
 else:
  g._write_locked(plate0,false)
  _obs_push(run,g,_obs_card(g,str(plate0.id)),null,"B0")
 var plate1=g._install_special("negative_plate_lock_medium","special_2_a",3)
 var strap=_obs_reinforcement_of(g,plate1)
 if plate1.is_empty() or strap.is_empty():
  run["skipped"].append("B1:no_lock")
 else:
  g.state.relics.append("tentacle_friend")
  g._gain_tool("saw")
  strap.durability=float(g.Tools.TYPES.saw.damage)
  _obs_push(run,g,_obs_card(g,str(strap.id),true),null,"B1")
  g.state.relics.erase("tentacle_friend")
 var boss=g.state.enemies[0] if not g.state.enemies.is_empty() else {}
 if boss.is_empty():
  run["skipped"].append("B2:no_enemy")
 else:
  boss.intent={"kind":"assembly","family":"glove","variant":"short","grade":2,"tier":2,"straps":"straight","name":"短型单手套","text":"施加短型单手套","delayed":false,"source":boss.id}
  _obs_push(run,g,_obs_payload(g,"end"),null,"B2")
 var glove=_obs_root_by_kind(g,"glove")
 if glove.is_empty():
  run["skipped"].append("B3:no_glove")
  run["skipped"].append("B4:no_glove")
 else:
  var glove_id=str(glove.id)
  var side=g._equipment(glove_id+"_left")
  if side.is_empty():
   run["skipped"].append("B3:no_side")
  else:
   side.durability=0.5
   _obs_push(run,g,_obs_card(g,glove_id+"_left"),null,"B3")
  var body=g._equipment(glove_id+"_body")
  if body.is_empty():
   run["skipped"].append("B4:no_body")
  else:
   body.durability=0.5
   _obs_push(run,g,_obs_card(g,glove_id+"_body"),null,"B4")
 return run

static func _obs_run_c(g) -> Dictionary:
 var run={"windows":[],"receipts":[],"labels":[],"skipped":[]}
 var boss=g.state.enemies[0] if not g.state.enemies.is_empty() else {}
 if boss.is_empty():
  run["skipped"].append("C0:no_enemy")
  return run
 boss.intent={"kind":"special_install","type":"urethral_rod_low","slot":"special_2_d","tier":1,"grade":1,"name":"马眼棒","text":"施加马眼棒","delayed":false,"source":boss.id}
 g.state.pressure=g.Pressure.maximum(g)-5.0
 _obs_push(run,g,_obs_payload(g,"end"),null,"C0")
 return run

static func _obs_quiet(g) -> Array:
 var rows=g.get("quiet_settles")
 return rows if rows is Array else []

static func _obs_journal(g) -> Array:
 var rows=g.get("journal")
 return rows if rows is Array else []

# One §3 step: the quiet rows it produced, their sites, and the ports the same step entered.
static func _obs_step(g, from_quiet: int, from_journal: int) -> Dictionary:
 var rows=_obs_quiet(g).slice(from_quiet)
 var ports={}
 for row in _obs_journal(g).slice(from_journal): ports[str(row.get("port",""))]=int(ports.get(str(row.get("port","")),0))+1
 return {"rows":rows.size(),"sites":rows.map(func(row):return str(row.site)),"did_work":rows.map(func(row):return bool(row.did_work)),"left":rows.map(func(row):return row.left),"ports":ports}

# The §3 counting self-check steps (plan-delta §3): install (S18), a new hogtie (S19), a hogtie upgrade (the
# quality port, no row), one replacement plan (the sandbox, no row), and an install after a zeroed piece (an
# S18 row with `did_work` and the piece in `left`). The same function runs on both classes.
static func _obs_zeroed_valid(zeroed: Dictionary) -> bool:
 return int(zeroed.get("rows",-1))==1 and zeroed.get("sites",[])==["S18"] and zeroed.get("did_work",[]).all(func(did):return did) and zeroed.get("left",[]).any(func(left):return str(zeroed.get("victim","")) in left)

static func _obs_master(g) -> Dictionary:
 var out={"steps":{}}
 var boss=g.RopeArt.master(g)
 if boss.is_empty(): return out
 boss.rope_art.stock=99
 var q=_obs_quiet(g).size()
 var j=_obs_journal(g).size()
 g.RopeArt.install(g,boss,g.RopeArt.spec(1,2))
 out["steps"]["install"]=_obs_step(g,q,j)
 q=_obs_quiet(g).size()
 j=_obs_journal(g).size()
 g.RopeArt.hogtie(g,boss,2)
 out["steps"]["hogtie_new"]=_obs_step(g,q,j)
 q=_obs_quiet(g).size()
 j=_obs_journal(g).size()
 var empty_spec=g.RopeArt.spec(1,2)
 empty_spec.templates=[]
 var installed=g.RopeArt.install(g,boss,empty_spec)
 out["steps"]["install_free"]=_obs_step(g,q,j)
 out["steps"]["install_free"]["installed"]=bool(installed)
 q=_obs_quiet(g).size()
 j=_obs_journal(g).size()
 g.RopeArt.hogtie(g,boss,3)
 out["steps"]["hogtie_upgrade"]=_obs_step(g,q,j)
 q=_obs_quiet(g).size()
 j=_obs_journal(g).size()
 # A real plan (the existing `REMOVAL previews_never_leak_join_effects` fixture shape) so the step exercises
 # the sandbox's own `_cleanup(false)` instead of passing on a plan that stops before any write.
 var planned=preload("res://core/equipment_replacement.gd").plan(g,[preload("res://tests/replacement_cases.gd").request("wrist",3,3)],"obs")
 out["steps"]["replacement_plan"]=_obs_step(g,q,j)
 out["steps"]["replacement_plan"]["ok"]=bool(planned.get("ok",false))
 var victim={}
 for piece in g.state.equipment:
  if float(piece.durability)>0.0 and str(piece.template)!="art_hogtie": victim=piece; break
 if not victim.is_empty():
  out["steps"]["pre_zero"]={"victim":str(victim.id)}
  g._equipment(str(victim.id)).durability=0.0
  q=_obs_quiet(g).size()
  j=_obs_journal(g).size()
  g.RopeArt.install(g,boss,g.RopeArt.spec(1,1))
  var step=_obs_step(g,q,j)
  step["victim"]=str(victim.id)
  out["steps"]["pre_zero"]=step
 return out

# One coverage class is the list of windows (or self-check steps) that reached it, in order, without
# duplicates: the acceptance reads a class's window count and its window labels, not a boolean.
static func _obs_bump(counts: Dictionary, name: String, label: String) -> void:
 if not counts.has(name): counts[name]=[]
 if not counts[name].has(label): counts[name].append(label)

# One segment's ledger: the two directions, the declared rows that fired, and the coverage classes with the
# windows each was reached in. `equal` counts equal-value durability rows and `transitional` counts
# transitional keys rather than windows, because the clause asks for hits, not windows, there.
static func _obs_ledger(label: String) -> Dictionary:
 return {"label":label,"windows":0,"labels":[],"skipped":[],"failed":[],"missing":[],"forged":[],"leaks":[],"triggered":{},"coverage":{},"sandbox":0,"equal":0,"transitional":0}

# One segment's judgment (rev3.5 plan-delta §2.3, rev3.6 §2.6): both directions per window, the declared
# rows' fires and leaks (CC-52: a fire is a record that stays on both sides), and the coverage bookkeeping.
static func _obs_judge(run: Dictionary, ledger: Dictionary) -> void:
 for index in range(run["windows"].size()):
  var window=run["windows"][index]
  var label=str(window.get("label",""))
  if label=="": label=str(ledger["label"])+str(index)
  ledger["windows"]=int(ledger["windows"])+1
  ledger["labels"].append(label)
  if not bool(window["ok"]): ledger["failed"].append(label+":"+str(window.get("error","")))
  for key in window["diff"]["keys"]:
   if not window["log"].has(key): ledger["missing"].append(label+":"+str(key))
  for name in window["diff"]["triggered"]:
   for id in window["diff"]["deducted"].get(name,[]):
    ledger["triggered"][name]=int(ledger["triggered"].get(name,0))+1
    if window["log"].has(str(id)) or window["equal"].has(str(id)): ledger["leaks"].append(label+":"+str(name)+":"+str(id))
  var transitional=window["transitional"]
  if not bool(window["mixed"]):
   for key in window["phantom"]:
    if window["equal"].has(key) or transitional.has(key): continue
    ledger["forged"].append(label+":"+str(key))
  if bool(window["mixed"]): ledger["sandbox"]=int(ledger["sandbox"])+1
  if not transitional.is_empty():
   _obs_bump(ledger["coverage"],"transitional",label)
   ledger["transitional"]=int(ledger["transitional"])+transitional.size()
  if _obs_strap_followed(window["before"],window["after"]): _obs_bump(ledger["coverage"],"strap_followed",label)
  for row in window["real"]:
   var port=str(row.get("port",""))
   if port=="durability":
    _obs_bump(ledger["coverage"],"durability_tighten" if bool(row.get("tighten",false)) else "durability_ease",label)
    if _obs_equal_row(row):
     _obs_bump(ledger["coverage"],"equal",label)
     ledger["equal"]=int(ledger["equal"])+1
   elif port in ["quality","tier","join","locked"]: _obs_bump(ledger["coverage"],port,label)
   elif port=="member":
    if str(row.get("change",""))=="added": _obs_bump(ledger["coverage"],"member_added",label)
    else:
     _obs_bump(ledger["coverage"],"member_removed",label)
     if str(row.get("template",""))=="link_rope": _obs_bump(ledger["coverage"],"removed_link",label)
     if window["before"].composites.any(func(root):return str(root.id)==str(row.get("id",""))): _obs_bump(ledger["coverage"],"removed_root",label)
  if not window["trial"].is_empty(): _obs_bump(ledger["coverage"],"trial",label)

# The transparency clause's six items for one segment: same seed, same start state and the same sequence run
# on `tests/game_fixture.gd` and on the journal. A segment without dispatches (the counting self-check's
# master steps) compares two empty receipt lists, which is the vacuous truth for that item.
static func _obs_same(plain, g, replay: Dictionary={}, run: Dictionary={}) -> Dictionary:
 return {"receipts":JSON.stringify(replay.get("receipts",[]))==JSON.stringify(run.get("receipts",[])),"state":Arch.save_text(plain.state)==Arch.save_text(g.state),"logs":JSON.stringify(plain.state.logs)==JSON.stringify(g.state.logs),"rng":JSON.stringify(plain.state.rng)==JSON.stringify(g.state.rng),"epoch":int(plain.write_epoch())==int(g.write_epoch()),"debug":JSON.stringify(plain.debug_check_failures)==JSON.stringify(g.debug_check_failures)}

# G-Q7-3' (A78 blind spot 3; replaces rev3 G-Q7-3): the journal and the state difference of one window agree.
# A window is one real `dispatch` before/after (T4), the same bracket the dirty-piece table uses. The diff
# universe is the four containers plus `root.components`, `host.shoulders.pieces` and `e.binding`; adds and
# removes both count as touched. Attribution is plan-delta §2.3 (CC-47): a binding record belongs to its host,
# and a top-level record added or removed as a whole folds its components and straps into its own id. Two
# directions: the diff keys are a subset of the log keys (no missed write), and the log keys minus the diff
# keys are equal-value durability touches or transitional members (CC-46, no forged write). A window with
# sandbox rows (CC-45) is judged for the first direction alone, with the union of real and sandbox rows.
# The declared blind spots (CC-44) subtract one field each under their own condition and only while the record
# stays on both sides (CC-52); each row must fire at least once and the id it excuses must stay out of the log,
# or the table is a lie. The sequence has two segments (rev3.6 §2.1): A is the WIP dispatch sequence, B adds
# five windows that free a wrist point first and then reach `strap_followed`, X2, X3 and `removed_root`. Both
# segments and the counting self-check's master segment are replayed on `game_fixture` for the transparency
# clause, and the coverage clause names every row class the two segments must reach, so a sequence that stops
# reaching one reddens by name instead of passing on an empty window set.
static func port_journal_matches_state_diff(t) -> void:
 var fixture=_full_restraint()
 var start_a=fixture.game.state.duplicate(true)
 var pair_boundaries=_obs_pair_boundaries()
 var shoulder_fields_complete=pair_boundaries.values().all(func(ok):return bool(ok))
 var binding_boundary=_obs_binding_boundary(start_a)
 var binding_keys_agree=bool(binding_boundary["ok"])
 var x3_state_independent=_obs_x3_boundary()
 var anchors_valid=_obs_anchors_valid()
 var transition_boundary=_obs_transition_boundary(start_a)
 print("OBS Q7 BOUNDARIES shoulders="+str(pair_boundaries)+" binding="+str(binding_boundary)+" X3_state_independent="+str(x3_state_independent)+" anchors_valid="+str(anchors_valid)+" transitional_accepts_absent="+str(transition_boundary["transitional_accepts_absent"])+" transitional_rejects_present="+str(transition_boundary["transitional_rejects_present"])+" transitional_requires_lifecycle="+str(transition_boundary["transitional_requires_lifecycle"]))
 var wrist=_obs_wrist_piece(fixture.game)
 if not wrist.is_empty():
  wrist.durability=0.0
  fixture.game._cleanup()
 var start_b=fixture.game.state.duplicate(true)
 var journal=preload("res://tests/write_journal_game.gd")
 var plain_class=preload("res://tests/game_fixture.gd")
 var g_a=_obs_port(journal,start_a)
 var run_a=_obs_run(g_a)
 var g_b=_obs_port(journal,start_b)
 var run_b=_obs_run_b(g_b)
 var g_c=_obs_port(journal,start_a)
 var run_c=_obs_run_c(g_c)
 var a=_obs_ledger("A")
 var b=_obs_ledger("B")
 var c=_obs_ledger("C")
 b["skipped"]=run_b["skipped"]
 c["skipped"]=run_c["skipped"]
 _obs_judge(run_a,a)
 _obs_judge(run_b,b)
 _obs_judge(run_c,c)
 if not g_a.cleanup_frames.is_empty(): _obs_bump(a["coverage"],"cleanup","frames")
 if not g_b.cleanup_frames.is_empty(): _obs_bump(b["coverage"],"cleanup","frames")
 if not g_c.cleanup_frames.is_empty(): _obs_bump(c["coverage"],"cleanup","frames")
 var master_plain=preload("res://tests/rope_master_cases.gd").encounter()
 var master_state=master_plain.state.duplicate(true)
 var master=_obs_clone(journal,master_state)
 var counted=_obs_master(master)
 _obs_master(master_plain)
 var m=_obs_ledger("M")
 for step in counted["steps"]:
  for port in counted["steps"][step].get("ports",{}): _obs_bump(m["coverage"],str(port),"M:"+str(step))
 var classes=["durability_tighten","durability_ease","quality","tier","member_added","member_removed","removed_root","removed_link","join","locked","trial","equal","transitional","cleanup","strap_followed"]
 var uncovered=classes.filter(func(name):return int(a["coverage"].get(name,[]).size())+int(b["coverage"].get(name,[]).size())+int(c["coverage"].get(name,[]).size())+int(m["coverage"].get(name,[]).size())==0)
 var triggered={}
 for ledger in [a,b,c]:
  for name in ledger["triggered"]: triggered[name]=int(triggered.get(name,0))+int(ledger["triggered"][name])
 for ledger in [a,b,c]:
  print("OBS Q7 COVERAGE "+str(ledger["label"])+" windows="+str(ledger["windows"])+" labels="+str(ledger["labels"])+" sandbox="+str(ledger["sandbox"])+" equal="+str(ledger["equal"])+" transitional="+str(ledger["transitional"])+" coverage="+str(ledger["coverage"])+" triggered="+str(ledger["triggered"]))
 print("OBS Q7 COVERAGE M steps="+str(counted["steps"].size())+" coverage="+str(m["coverage"])+" skipped="+str(b["skipped"])+" uncovered="+str(uncovered)+" triggered="+str(triggered))
 for window in run_c["windows"]:
  print("OBS Q7 C0 ok="+str(window["ok"])+" sandbox="+str(window["mixed"])+" trial_rows="+str(window["trial"].size())+" real_rows="+str(window["real"].size())+" transitional="+str(window["transitional"])+" missing="+str(c["missing"])+" forged="+str(c["forged"])+" skipped="+str(c["skipped"]))
 for segment_index in range(3):
  var segment=[run_a,run_b,run_c][segment_index]
  for window_index in range(segment["windows"].size()):
   var window=segment["windows"][window_index]
   var label=str(window["label"]) if str(window["label"])!="" else ["A","B","C"][segment_index]+str(window_index)
   if not window["diff"]["triggered"].is_empty(): print("OBS Q7 TRIGGERS "+label+" "+str(window["diff"]["deducted"]))
 t.check(a["failed"].is_empty() and b["failed"].is_empty() and c["failed"].is_empty() and a["missing"].is_empty() and b["missing"].is_empty() and c["missing"].is_empty() and shoulder_fields_complete and binding_keys_agree,"OBS port_journal_matches_state_diff: every changed record is journaled -- for every window of both dispatch segments the state difference of the four containers and their nested members is a subset of the log keys, with the three declared fields subtracted only under their own condition and only while the record stays on both sides: windows="+str(a["windows"])+"/"+str(b["windows"])+" failed="+str(a["failed"]+b["failed"]+c["failed"])+" missing="+str(a["missing"]+b["missing"]+c["missing"])+" shoulder_fields_complete="+str(shoulder_fields_complete)+" binding_keys_agree="+str(binding_keys_agree)+" C="+str(c))
 t.check(a["forged"].is_empty() and b["forged"].is_empty() and c["forged"].is_empty() and transition_boundary.values().all(func(ok):return bool(ok)),"OBS port_journal_matches_state_diff: journaled records all changed or were equal-value writes -- in windows without sandbox rows the log keys minus the difference keys are equal-value durability touches or transitional members, so no row invents an id: forged="+str(a["forged"]+b["forged"]+c["forged"])+" C="+str(c)+" transitional_accepts_absent="+str(transition_boundary["transitional_accepts_absent"])+" transitional_rejects_present="+str(transition_boundary["transitional_rejects_present"])+" transitional_requires_lifecycle="+str(transition_boundary["transitional_requires_lifecycle"]))
 t.check(OBS_UNJOURNALED_FIELDS.size()==3 and OBS_UNJOURNALED_FIELDS.all(func(row):return int(triggered.get(str(row.get("name","")),0))>0) and a["leaks"].is_empty() and b["leaks"].is_empty() and c["leaks"].is_empty() and x3_state_independent and anchors_valid,"OBS port_journal_matches_state_diff: declared unjournaled fields are exercised and stay unjournaled -- each of the three declared rows fires at least once in the two segments and the id it excuses is absent from that window's log keys (a row that never fires or excuses a journaled id is a lie): declared="+str(triggered)+" leaks="+str(a["leaks"]+b["leaks"]+c["leaks"])+" X3_state_independent="+str(x3_state_independent)+" anchors_valid="+str(anchors_valid)+" C="+str(c))
 t.check(int(a["windows"])>=7 and int(b["windows"])==5 and b["labels"]==["B0","B1","B2","B3","B4"] and b["skipped"].is_empty() and int(c["windows"])==1 and c["labels"]==["C0"] and c["skipped"].is_empty() and int(c["sandbox"])==0 and int(c["transitional"])>0 and uncovered.is_empty(),"OBS port_journal_matches_state_diff: the dispatch sequence reaches every row class the clause names (both durability intents, the quality port, the tier row, member adds, member removals including a composite root and a link that followed its end, the join row, the lock port, a sandbox window, an equal-value write, a transitional member, the settle, and a main piece whose reinforcement strap leaves with it), so the two directions above are not judged on an empty set: windows="+str(a["windows"])+"/"+str(b["windows"])+" labels="+str(b["labels"])+" skipped="+str(b["skipped"])+" uncovered="+str(uncovered)+" A="+str(a["coverage"])+" B="+str(b["coverage"])+" M="+str(m["coverage"])+" C="+str(c))
 var plain_a=_obs_port(plain_class,start_a)
 var replay_a=_obs_run(plain_a)
 var plain_b=_obs_port(plain_class,start_b)
 var replay_b=_obs_run_b(plain_b)
 var plain_c=_obs_port(plain_class,start_a)
 var replay_c=_obs_run_c(plain_c)
 var same_a=_obs_same(plain_a,g_a,replay_a,run_a)
 var same_b=_obs_same(plain_b,g_b,replay_b,run_b)
 var same_c=_obs_same(plain_c,g_c,replay_c,run_c)
 var same_m=_obs_same(master_plain,master)
 var transparent=same_a.values().all(func(ok):return bool(ok)) and same_b.values().all(func(ok):return bool(ok)) and same_c.values().all(func(ok):return bool(ok)) and same_m.values().all(func(ok):return bool(ok))
 print("OBS Q7 TRANSPARENCY A="+str(same_a)+" B="+str(same_b)+" C="+str(same_c)+" M="+str(same_m))
 t.check(transparent,"OBS port_journal_matches_state_diff: the journal subclass is transparent -- the same seed, start state and sequence on `tests/game_fixture.gd` and on the journal produce equal receipts, `SaveStore.encode(state)`, the state logs, the rng counters, `write_epoch()` and the debug check failures for both segments, and the counting self-check's master steps agree too (they dispatch nothing, so their receipt lists are equal), so no override drops or reorders a `super` call: A="+str(same_a)+" B="+str(same_b)+" M="+str(same_m)+" C="+str(same_c))
 var install=counted["steps"].get("install",{})
 var hogtie=counted["steps"].get("hogtie_new",{})
 var upgrade=counted["steps"].get("hogtie_upgrade",{})
 var planned=counted["steps"].get("replacement_plan",{})
 var zeroed=counted["steps"].get("pre_zero",{})
 var wrong_site=zeroed.duplicate(true)
 wrong_site["sites"]=["S19"]
 var install_free=counted["steps"].get("install_free",{})
 t.check(int(install_free.get("rows",-1))==1 and install_free.get("sites",[])==["S18"] and not bool(install_free.get("installed",true)) and install_free.get("ports",{}).is_empty(),"OBS port_journal_matches_state_diff: a hogtie followed by an install-free settle is S18 -- no member row from the previous cleanup frame may classify this frame: install_free="+str(install_free))
 t.check(int(install.get("rows",-1))==1 and install.get("sites",[]).all(func(site):return site=="S18"),"OBS port_journal_matches_state_diff: a rope-master install produces exactly one quiet settle row and it is S18 -- the site is read from the last real member/added row since the previous settle frame, and nothing settles between the install and its own `_cleanup(false)`: install="+str(install))
 t.check(int(hogtie.get("rows",-1))==1 and hogtie.get("sites",[]).all(func(site):return site=="S19"),"OBS port_journal_matches_state_diff: a new hogtie produces exactly one quiet settle row and it is S19, because its install row carries the art_hogtie template: hogtie="+str(hogtie))
 t.check(int(upgrade.get("rows",-1))==0 and int(upgrade.get("ports",{}).get("quality",0))>0,"OBS port_journal_matches_state_diff: a hogtie upgrade writes the quality port and settles nothing, so it produces no quiet settle row: upgrade="+str(upgrade))
 t.check(int(planned.get("rows",-1))==0,"OBS port_journal_matches_state_diff: one replacement plan settles nothing -- its writes happen in the sandbox and are restored, so the quiet counter does not see them: plan="+str(planned))
 t.check(_obs_zeroed_valid(zeroed) and not _obs_zeroed_valid(wrong_site),"OBS port_journal_matches_state_diff: a quiet settle that releases a zeroed piece reports work and names it -- the S18 row after the install has `did_work` true and the piece in `left`, so the counter is a release witness and not a frame counter: zeroed="+str(zeroed)+" rejects_wrong_site="+str(not _obs_zeroed_valid(wrong_site)))
