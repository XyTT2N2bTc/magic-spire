extends RefCounted
const Game=preload("res://tests/game_fixture.gd")

static func hit(t,g,type: String,target: Dictionary) -> Dictionary:
 var card=t.hand_card(g,type)
 return t.action(g,"card",{"uid":card.uid,"target":target.id,"slot":target.slot})

static func run(t) -> void:
 for grade in [1,2,3]:
  var g=Game.new(42)
  var host=g._install_template("rope","upper_arm",g.Equipment.maximum(grade),g.Equipment.maximum(grade),false,"fixture",grade)
  var pair=g.Shoulders.attached(g,host)
  t.check(pair.size()==2 and pair[0].id!=pair[1].id,"SHOULDER auto pair grade "+str(grade))
  t.check(pair.all(func(e):return g.tier(e.durability,e.maximum)==grade and e.layer==0 and e.slot=="shoulder"),"SHOULDER own tier follows grade, actual contact at shoulder")
  t.check(g.capacity_used("upper_arm")==1 and g.level("arms")==1 and g.targets_at("shoulder").size()==2,"SHOULDER not ordinary capacity or arm debuff")
  t.check(g.targets_at("upper_arm").all(func(e):return not g.Equipment.is_shoulder(e)),"SHOULDER not selectable at host upper arm")
  t.check(g.escape_preview(pair[0],"strain",5).reason!="","SHOULDER no strain")
  t.check(g.escape_preview(host,"magic_slip",5).reason.contains("肩带"),"SHOULDER two paths block host magic slip")
  var before=g.export_snapshot();g.get_view();g.command_facts()
  t.check(before==g.export_snapshot(),"SHOULDER previews preserve pair and RNG")
  t.check(not g.Shoulders.install(g,host,"belt",2,"fixture") and g.export_snapshot()==before,"SHOULDER extra pair rejected atomically")
  var restored=Game.new(88)
  t.check(restored.restore_snapshot(before).ok and restored.state.equipment==g.state.equipment,"SHOULDER full snapshot roundtrip")
  var broken=before.duplicate(true);broken.equipment[0].shoulders.pieces.append(broken.equipment[0].shoulders.pieces[0].duplicate(true))
  var old=restored.export_snapshot()
  t.check(not restored.restore_snapshot(broken).ok and restored.export_snapshot()==old,"SHOULDER malformed duplicate rejects without mutation")
  host.durability=host.maximum*0.4
  g._cleanup()
  t.check(g.Shoulders.attached(g,host).size()==2 and g.tier(pair[0].durability,pair[0].maximum)==grade,"SHOULDER parent tier changes do not alter independent pieces")
  pair[0].durability=0;g._cleanup()
  var half=g.escape_preview(host,"magic_slip",5)
  t.check(half.reason=="" and half.penalty==0.5,"SHOULDER one remaining means half host slip")
  var surviving=pair[1].duplicate(true)
  host.durability=host.maximum;g._refresh_equipment(host)
  t.check(g.Shoulders.attached(g,host).size()==2 and g._equipment(surviving.id)==surviving,"SHOULDER reinforcement refills only missing side")
  t.check(g.validate()=="","SHOULDER normal state validates")
  host.durability=0;g._cleanup()
  t.check(g.targets_at("shoulder").is_empty(),"SHOULDER host deletion cascades")
 var g=Game.new(42,true,"shoulder_links")
 var host=g.state.equipment[0]
 var left=host.shoulders.pieces[0];var right=host.shoulders.pieces[1]
 t.check(not host.has("binding") and g.tier(host.durability,host.maximum)==2,"SHOULDER extra source can attach below auto threshold")
 left.durability=1;g._cleanup()
 var collateral=g.escape_preview(right,"slip",g.Cards.Rules.SPECS.slip.base*0.5,[],false,false,false,true).damage
 var cost=g.state.energy;var version=g.state.version
 t.check(hit(t,g,"slip",left).ok and g.state.version==version+1 and g.state.energy==cost-1,"SHOULDER actual card pays and removes selected left")
 host=g._equipment(host.id);right=g._equipment(right.id)
 t.check(g.Shoulders.attached(g,host).size()==1 and is_equal_approx(right.durability,12.0-collateral),"SHOULDER right survives left slip with same-group splash")
 var half=g.escape_preview(host,"magic_slip",5)
 right.durability=0;g._cleanup()
 var full=g.escape_preview(host,"magic_slip",5)
 t.check(is_equal_approx(full.damage,half.damage*2),"SHOULDER zero sides restore normal effect")
 var before=g.export_snapshot();g.get_view();g._cleanup()
 t.check(g.state.equipment==before.equipment,"SHOULDER no regeneration during cleanup")
 host.durability=host.maximum*0.8
 g._enemy_operation(Game.new(42,true,"guard").state.enemies[0],{"kind":"tighten","target":host.id,"text":"加固","delayed":false})
 t.check(g.Shoulders.attached(g,g._equipment(host.id)).size()==2,"SHOULDER formal enemy two-to-three refills")
 # Cross hysteresis and material tool route, independent from host ratio.
 g=Game.new(42,true,"shoulder_auto");host=g.state.equipment[0]
 left=host.shoulders.pieces[0];right=host.shoulders.pieces[1]
 t.check(left.crossed and not t.find_action(g,"hook",{"target":left.id}).valid,"SHOULDER cross blocks hook")
 g.state.items[0].mount="high_wall"
 t.check(g.InstalledTools.reason(g,g.state.items[0],left)=="" and not t.find_action(g,"item_use",{"item":g.state.items[0].id,"target":left.id}).valid,"SHOULDER cutter reaches shoulder but requires a matching legal card")
 left=g._equipment(left.id)
 t.check(left.durability==right.durability and left.crossed,"SHOULDER viewing crossed shoulder does not spend cutter or damage either side")
 left.durability=left.maximum*0.8;g._cleanup()
 t.check(left.crossed and g._slip_reason(left,"magic_slip")!="","SHOULDER crossing persists at tier2 even for magic")
 var saved=g.export_snapshot();var copy=Game.new(9)
 t.check(copy.restore_snapshot(saved).ok and copy._equipment(left.id).crossed,"SHOULDER saves crossing history at tier2")
 left.durability=left.maximum*0.4;g._cleanup()
 t.check(not left.crossed and g._slip_reason(left)=="","SHOULDER tier1 restores own slip")
 left.durability=left.maximum;g._refresh_equipment(left)
 t.check(left.crossed,"SHOULDER reinforcement reenters crossing")
 # Unlimited shoulder count still means exactly one pair per physical host.
 g=Game.new(12)
 for i in range(3):
  host=g._install_template("rope","upper_arm",10,10,false,"fixture",1,0,0,"above_elbow")
 t.check(g.targets_at("shoulder").size()==6 and g.validate()=="","SHOULDER three pairs coexist on same layer")
 for i in range(3):
  g._install_template("rope","upper_arm",10,10,false,"fixture",1,0,0,"upper_arm_top")
 var neck_group=g.get_view().body_groups.filter(func(body):return body.id=="neck")[0]
 t.check(neck_group.name=="颈肩" and neck_group.count==12 and neck_group.targets.size()==12,"SHOULDER six hosts project twelve unique shoulder pieces in the combined group")
 t.check(neck_group.sections[0].equipment.is_empty() and neck_group.sections[1].equipment.size()==12 and g.capacity_used("neck")==0 and g.validate()=="","SHOULDER grouped count does not imply neck occupancy or consume neck capacity")
 # Both glove styles use the same independent shoulder and host-slip rules.
 for configuration in [["short","straight"],["short","cross"],["long","straight"],["long","cross"]]:
  var style=configuration[1]
  g=Game.new(42)
  var root=g._install_assembly("glove",configuration[0],"fixture",3,2,{},style)
  host=g._composite_body(root);left=root.components[1];right=root.components[2]
  t.check(root.components.size()==3 and left.crossed and right.crossed,"SHOULDER glove independent left/right "+style)
  left.durability=left.maximum*0.4;g._cleanup()
  t.check(not left.crossed and right.crossed and g._effective_ratio(right)==1.0,"SHOULDER glove own ratio and independent crossing")
  left.durability=0;g._cleanup()
  t.check(g._equipment(left.id).is_empty(),"SHOULDER removed glove strap leaves the target list")
  t.check(g.escape_preview(host,"magic_slip",5).penalty==0.5 and g._slip_reason(host)=="","SHOULDER glove one side half effect")
  var remaining=right.durability
  host.durability=host.maximum;g._refresh_equipment(host)
  t.check(g.Shoulders.attached(g,host).size()==1 and right.durability==remaining,"SHOULDER composite tier3 never restores missing shoulder or heals survivor")
  t.check(not g.Shoulders.missing(g,host) and g._can_tighten(host)==g._reinforcement_locks(host) and not g.Binding.present(host),"SHOULDER composite tier3 can only lock, never restore missing shoulder")
  saved=g.export_snapshot();copy=Game.new(9)
  t.check(copy.restore_snapshot(saved).ok and copy.Shoulders.attached(copy,copy._equipment(host.id)).size()==1,"SHOULDER removed composite shoulder remains removed after restore")
  right.durability=0;g._cleanup();g._refresh_equipment(host)
  t.check(g.Shoulders.attached(g,host).is_empty(),"SHOULDER bare composite stays without shoulders at tier3")
  t.check(g.validate()=="","SHOULDER glove validates new schema")
 # A real guard plan can apply the independent link source and restore its published intent.
 g=Game.new(42,true,"guard")
 host=g._install_template("rope","upper_arm",4,10,false,"fixture")
 var offers=g.EquipmentOffers.options(g).filter(func(o):return o.kind=="shoulder")
 t.check(not offers.is_empty(),"SHOULDER guard extra source is in formal offers")
 var enemy=g.state.enemies[0]
 var plan=g.Application.choose(g,{"pool":"ordinary","templates":g.Shoulders.BASES,"shoulders":true,"slot":"shoulder","grade":2,"tier":2},enemy.id)
 plan.text="施加中级肩带 · 二档";plan.delayed=false
 t.check(plan.kind=="shoulder" and plan.tier==plan.grade,"SHOULDER published pair uses grade tier")
 enemy.intent={"kind":"guard_sequence","operations":[plan],"priority":false,"text":plan.text,"delayed":false}
 saved=g.export_snapshot();copy=Game.new(9)
 t.check(copy.restore_snapshot(saved).ok,"SHOULDER published shoulder intent restores")
 g._enemy_operation(enemy,plan)
 t.check(g.Shoulders.attached(g,g._equipment(host.id)).size()==2 and g.validate()=="","SHOULDER guard executes published pair")

 # Material capabilities remain inherited; pair failures preserve complete state.
 for template in g.Shoulders.BASES:
  var material_game=Game.new(17)
  var anchor=material_game._install_template("rope","upper_arm",4,10,false,"fixture")
  var old=material_game.export_snapshot()
  t.check(not material_game.Shoulders.install(material_game,anchor,"missing",2,"fixture") and material_game.export_snapshot()==old,"SHOULDER invalid pair has no partial side or events")
  t.check(material_game.Shoulders.install(material_game,anchor,template,1,"fixture"),"SHOULDER extra base material "+template)
  var piece=anchor.shoulders.pieces[0]
  t.check(not material_game.Equipment.allows(piece,"strain") and material_game.Equipment.allows(piece,"manual")== (template in ["rope","cord","belt","fine_belt"]),"SHOULDER basic manual method follows material "+template)
  t.check(material_game.Equipment.allows(piece,"lock")== (template in ["belt","fine_belt"]),"SHOULDER lock compatibility "+template)
  t.check(material_game.validate()=="","SHOULDER material state validates "+template)

 pair_fill_unchanged(t)
 pair_record_and_missing_sides_edges(t)

# Q9′：pair_record 的四个字段各有独立位置（交换 grade／variant 即红），install 固定 variant 0、refresh 取宿主
# variant；missing_sides 的阈值（>0.000001）、SIDES 次序与已释放件各自有运行时判据。合成对记录只带 pieces，
# 让阈值两侧的取值与左右形状互不掩盖；真实入口的两条用例同时钉住 install／refresh 的映射。
static func pair_record_and_missing_sides_edges(t) -> void:
 var g=Game.new(42)
 var record=g.Shoulders.pair_record("belt",2,1,"probe")
 t.check(record.template=="belt" and record.grade==2 and record.variant==1 and record.source=="probe" and record.pieces.is_empty(),"SHOULDER pair_record_and_missing_sides_edges: every pair record field keeps its own position and the record starts with no pieces")
 var install_game=Game.new(42)
 var install_host=install_game._install_template("rope","upper_arm",install_game._tier_durability(install_game.Equipment.maximum(2),2),install_game.Equipment.maximum(2),false,"fixture",2,-1,1)
 t.check(install_host.variant==1 and install_game.tier(install_host.durability,install_host.maximum)==2 and not install_host.has("shoulders"),"SHOULDER pair_record_and_missing_sides_edges: the install host carries a non-zero variant at tier two without a pair")
 t.check(install_game.Shoulders.install(install_game,install_host,"belt",2,"fixture") and install_host.shoulders.template=="belt" and install_host.shoulders.grade==2 and install_host.shoulders.variant==0 and install_host.shoulders.source=="fixture","SHOULDER pair_record_and_missing_sides_edges: install builds the pair at variant zero from its own template, grade and source")
 t.check(install_host.shoulders.pieces.all(func(e):return e.variant==0),"SHOULDER pair_record_and_missing_sides_edges: the installed pieces inherit the install variant zero")
 var refresh_game=Game.new(42)
 var refresh_host=refresh_game._install_template("rope","upper_arm",refresh_game._tier_durability(refresh_game.Equipment.maximum(2),2),refresh_game.Equipment.maximum(2),false,"fixture",2,-1,1)
 t.check(refresh_host.variant==1 and not refresh_host.has("shoulders"),"SHOULDER pair_record_and_missing_sides_edges: the refresh host carries a non-zero variant without a pair")
 refresh_host.durability=refresh_host.maximum
 refresh_game._refresh_equipment(refresh_host)
 t.check(refresh_host.has("shoulders") and refresh_host.shoulders.template=="rope" and refresh_host.shoulders.grade==2 and refresh_host.shoulders.variant==1 and refresh_host.shoulders.source=="fixture","SHOULDER pair_record_and_missing_sides_edges: the tier-three refresh builds the pair from the host template, grade, variant and source")
 t.check(refresh_host.shoulders.pieces.all(func(e):return e.variant==1),"SHOULDER pair_record_and_missing_sides_edges: the refreshed pieces inherit the host variant")
 var pair={"pieces":[{"side":"left","durability":10.0},{"side":"right","durability":10.0}]}
 t.check(g.Shoulders.missing_sides(pair).is_empty(),"SHOULDER pair_record_and_missing_sides_edges: a pair with both sides present misses nothing")
 pair["pieces"][1]["durability"]=0
 t.check(g.Shoulders.missing_sides(pair)==["right"],"SHOULDER pair_record_and_missing_sides_edges: a released right side is the only missing side")
 pair["pieces"][0]["durability"]=0
 t.check(g.Shoulders.missing_sides(pair)==["left","right"],"SHOULDER pair_record_and_missing_sides_edges: both released sides read missing in SIDES order")
 pair["pieces"][1]["durability"]=10.0
 pair["pieces"][0]["durability"]=0.0000001
 t.check(g.Shoulders.missing_sides(pair)==["left"],"SHOULDER pair_record_and_missing_sides_edges: a hairline side below the threshold still reads missing")
 pair["pieces"][0]["durability"]=0.000001
 t.check(g.Shoulders.missing_sides(pair)==["left"],"SHOULDER pair_record_and_missing_sides_edges: a side exactly at the threshold still reads missing")
 pair["pieces"][0]["durability"]=0.000002
 t.check(g.Shoulders.missing_sides(pair).is_empty(),"SHOULDER pair_record_and_missing_sides_edges: a side just above the threshold counts as present")

# Q9′（G-Q9-2′；CC-50）：三档自动补肩带的行为不变——大臂绳到 3 档补出左右各一条，id 与名称仍由
# pair_pieces 的派生规则给出，缺侧判断按 SIDES 序返回（live fill 与视图 refresh 共用同一规则）。
static func pair_fill_unchanged(t) -> void:
 var g=Game.new(42)
 var host=g._install_template("rope","upper_arm",g._tier_durability(g.Equipment.maximum(2),2),g.Equipment.maximum(2),false,"fixture",2)
 t.check(g.tier(host.durability,host.maximum)==2 and not host.has("shoulders") and g.Shoulders.missing_sides({"pieces":[]})==["left","right"],"SHOULDER pair_fill_unchanged: a tier-2 upper-arm rope has no pair and both sides read as missing")
 host.durability=host.maximum
 g._refresh_equipment(host)
 var pieces=host.shoulders.pieces
 t.check(pieces.size()==2 and pieces[0].side=="left" and pieces[1].side=="right","SHOULDER pair_fill_unchanged: reaching tier three fills exactly the left then the right side")
 t.check(pieces.map(func(e):return e.id)==[host.id+"_shoulder_left",host.id+"_shoulder_right"],"SHOULDER pair_fill_unchanged: the filled pieces keep the derived ids")
 t.check(pieces.map(func(e):return e.name)==[g.Shoulders.label("rope","left"),g.Shoulders.label("rope","right")],"SHOULDER pair_fill_unchanged: the filled pieces keep the derived names")
 t.check(g.Shoulders.missing_sides(host.shoulders).is_empty(),"SHOULDER pair_fill_unchanged: a complete pair reads no missing side")
 pieces[0].durability=0
 t.check(g.Shoulders.missing_sides(host.shoulders)==["left"],"SHOULDER pair_fill_unchanged: a released side reads back as the only missing side, in SIDES order")
