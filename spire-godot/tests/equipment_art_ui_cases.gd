extends RefCounted
const Game=preload("res://tests/game_fixture.gd")
const Portrait=preload("res://ui/equipment_portrait.gd")

static func region_fixture(g,region: String,level: int) -> void:
 var slots=g.B.ARM_SLOTS if region=="arms" else g.B.LEG_SLOTS
 var indices=[[],[0],[2],[2,3],[0,1,2,3,4]][level]
 for index in indices: g.add_fixture(slots[index],4)

static func run(t) -> void:
 var ui=t.ui
 # All combinations distinguish occupied locations, even when they have the same level.
 var slots=["thigh","calf","ankle","foot"]
 var layers=[["thigh_root"],["below_knee"],["ankle"],["foot"]]
 for mask in range(16):
  ui.game=Game.new(42)
  var expected: Array=[]
  for bit in range(4):
   if mask & (1<<bit):
    ui.game.add_fixture(slots[bit],4);expected.append_array(layers[bit])
  var before=ui.game.export_snapshot()
  ui.render();await t.frames()
  var portrait=ui.find_child("EquipmentPortrait",true,false)
  t.check(portrait.texture==(Portrait.FREE if mask==0 else Portrait.BOUND_BASE),"PORTRAIT shared base depends on actual limb occupancy")
  for key in Portrait.leg_layers:
   t.check(portrait.get_node("Overlay_"+key).visible==(mask!=0) and portrait.get_node("Overlay_"+key).texture==(Portrait.leg_layers[key].texture if key in expected else Portrait.leg_layers[key].free_texture),"PORTRAIT actual occupied locations select independent layer %d/%s" % [mask,key])
  t.check(ui.game.export_snapshot()==before,"PORTRAIT layers do not change state or random cursor")
  if mask in [1,2,4,8,15]: await t.capture("ui-94-equipment-parts-%d.png" % mask)
 ui.game=Game.new(42);ui.game.add_fixture("toes",4)
 ui.render();await t.frames()
 t.check(ui.find_child("EquipmentPortrait",true,false).active_leg_layers.is_empty(),"PORTRAIT toes alone never create a foot or ankle rope")
 # Face slots are independent of body level and of one another.
 ui.game=Game.new(42)
 var eye=ui.game.add_fixture("eyes",4)
 ui.render();await t.frames()
 var eyes_only=ui.find_child("EquipmentPortrait",true,false)
 t.check(eyes_only.get_node("Overlay_eyes").visible and not eyes_only.get_node("Overlay_mouth").visible,"PORTRAIT eye-only equipment never imports the mouth shown in source image seven")
 await t.capture("ui-91-equipment-eyes-only.png")
 var mouth=ui.game.add_fixture("mouth",4)
 ui.render();await t.frames()
 var p=ui.find_child("EquipmentPortrait",true,false)
 t.check(p.variant==-1 and p.get_node("Overlay_mouth").visible and p.get_node("Overlay_eyes").visible,"PORTRAIT both face overlays work on the free-body base")
 await t.capture("ui-89-equipment-free-face.png")
 await t.inspect_body("eyes")
 t.check(await t.click("manual",{"target":eye.id}),"PORTRAIT remove eye equipment through actual action")
 p=ui.find_child("EquipmentPortrait",true,false)
 t.check(not p.get_node("Overlay_eyes").visible and p.get_node("Overlay_mouth").visible,"PORTRAIT removing eyes preserves independent mouth layer")
 await t.inspect_body("mouth")
 t.check(await t.click("manual",{"target":mouth.id}),"PORTRAIT remove mouth equipment through actual action")
 p=ui.find_child("EquipmentPortrait",true,false)
 t.check(not p.get_node("Overlay_eyes").visible and not p.get_node("Overlay_mouth").visible and p.texture==Portrait.FREE,"PORTRAIT clearing face slots restores base without stale patches")
 ui.game=Game.new(42)
 region_fixture(ui.game,"arms",1);region_fixture(ui.game,"legs",4)
 ui.game.add_fixture("eyes",4);ui.game.add_fixture("mouth",4)
 ui.render();await t.frames()
 p=ui.find_child("EquipmentPortrait",true,false)
 t.check(p.variant==0 and p.active_leg_layers.size()==4 and p.equipped_eyes and p.equipped_mouth,"PORTRAIT body variant composes with both actual face slots")
 await t.capture("ui-90-equipment-bound-face.png")
 var thigh=ui.game.equipment_at("thigh")[0]
 await t.inspect_body("thigh")
 t.check(await t.click("manual",{"target":thigh.id}),"PORTRAIT actual release changes leg restriction level")
 p=ui.find_child("EquipmentPortrait",true,false)
 t.check(ui.view.legs==3 and not "thigh_root" in p.active_leg_layers and not "mid_thigh" in p.active_leg_layers and not "above_knee" in p.active_leg_layers and "ankle" in p.active_leg_layers and p.equipped_eyes and p.equipped_mouth,"PORTRAIT body reduction refreshes variant without clearing face equipment")

 # Active short and long single-glove assemblies share the supplied local arm replacement.
 for practice in ["glove_short","glove_long"]:
  ui.game=Game.new(42,true,practice)
  var before=ui.game.export_snapshot()
  ui.render();await t.frames();p=ui.find_child("EquipmentPortrait",true,false)
  t.check(p.texture==Portrait.BOUND_SINGLE_GLOVE and p.active_composite_layers==["single_glove"],"PORTRAIT %s selects the supplied single-glove replacement from the real composite" % practice)
  t.check(p.get_node("Overlay_thigh_root").texture==Portrait.SINGLE_GLOVE_THIGH.free,"PORTRAIT single glove keeps the matching free thigh-root slice")
  t.check(ui.game.export_snapshot()==before,"PORTRAIT single-glove display does not change state or random cursor")
 await t.capture("ui-equipment-single-glove.png")

 ui.game._install_special("negative_plate_lock_medium","special_2_a",2)
 ui.render();await t.frames();p=ui.find_child("EquipmentPortrait",true,false)
 t.check(p.texture==Portrait.BOUND_SINGLE_GLOVE_FLAT_LOCK and p.get_node("Overlay_thigh_root").texture==Portrait.SINGLE_GLOVE_THIGH.flat_lock_free,"PORTRAIT single glove and flat lock select their combined replacement without restoring old arm pixels")
 await t.capture("ui-equipment-single-glove-flat-lock.png")

 # Special-equipment differences are read-only layers on the bound standing art.
 ui.game=Game.new(42);ui.game.add_fixture("wrist",4)
 ui.game._install_special("negative_plate_lock_medium","special_2_a",2)
 ui.render();await t.frames();p=ui.find_child("EquipmentPortrait",true,false)
 t.check(p.texture==Portrait.BOUND_FLAT_LOCK and p.active_special_layers==["flat_lock"],"PORTRAIT a worn flat lock selects the local replacement on the bound standing art")
 t.check(not p.get_node("Overlay_flat_lock_reinforcement").visible and not p.get_node("Overlay_urethral_rod").visible,"PORTRAIT plain flat lock does not invent reinforcement or a urethral rod")
 await t.capture("ui-equipment-flat-lock.png")

 ui.game=Game.new(42);ui.game.add_fixture("wrist",4)
 ui.game._install_special("negative_vibrator_lock_catheter_high","special_2_a",3)
 ui.render();await t.frames();p=ui.find_child("EquipmentPortrait",true,false)
 t.check(p.active_special_layers==["flat_lock","flat_lock_reinforcement","urethral_rod"] and p.get_node("Overlay_flat_lock_reinforcement").visible and p.get_node("Overlay_urethral_rod").visible,"PORTRAIT reinforced catheter flat lock composes all three verified differences")
 await t.capture("ui-equipment-flat-lock-reinforced-rod.png")

 ui.game=Game.new(42);ui.game.add_fixture("wrist",4)
 ui.game._install_special("urethral_rod_low","special_2_d")
 ui.render();await t.frames();p=ui.find_child("EquipmentPortrait",true,false)
 t.check(p.texture==Portrait.BOUND_BASE and p.active_special_layers.is_empty() and not p.get_node("Overlay_urethral_rod").visible,"PORTRAIT a standalone urethral rod has no flat-lock-specific difference")

 ui.game=Game.new(42);ui.game.add_fixture("wrist",4)
 ui.game._install_special("negative_plate_lock_medium","special_2_a",2)
 ui.game._install_special("urethral_rod_low","special_2_d")
 ui.render();await t.frames();p=ui.find_child("EquipmentPortrait",true,false)
 t.check(p.texture==Portrait.BOUND_FLAT_LOCK and p.active_special_layers==["flat_lock","urethral_rod"] and p.get_node("Overlay_urethral_rod").visible,"PORTRAIT a separate urethral rod uses its difference only together with a worn flat lock")

 ui.game=Game.new(42)
 ui.game._install_special("negative_vibrator_lock_catheter_high","special_2_a",3)
 ui.render();await t.frames();p=ui.find_child("EquipmentPortrait",true,false)
 t.check(not ui.view.has_restraint_level and p.texture==Portrait.FREE and p.get_children().all(func(node):return not node.visible),"PORTRAIT special differences stay hidden when the standing portrait is not the bound variant")

 # A remaining physical band at the knee must not invent whole-thigh rope groups.
 ui.game=Game.new(42,true,"leg_upper")
 var root=ui.game.state.composites[0]
 var body=root.components.filter(func(e):return e.part=="body")[0]
 body.durability=1
 var item=ui.game.state.items[0].id
 ui.render();await t.frames()
 ui.show_items=true;ui.selected_item=item;ui.render();await t.frames()
 t.check(await t.click("item_use",{"item":item,"target":body.id}),"PORTRAIT real cutting removes leg sleeve while retaining outer bands")
 p=ui.find_child("EquipmentPortrait",true,false)
 t.check("thigh_root" in p.active_leg_layers and "above_knee" in p.active_leg_layers and not "mid_thigh" in p.active_leg_layers,"PORTRAIT real independent thigh bands exclude middle layer")
 await t.close_information();await t.inspect_body("thigh")
 var band=root.components.filter(func(e):return e.part=="thigh_root")[0]
 t.check(await t.click("manual",{"target":band.id}),"PORTRAIT actual root-band removal")
 p=ui.find_child("EquipmentPortrait",true,false)
 t.check(p.active_leg_layers==["above_knee"],"PORTRAIT remaining knee band renders only its physical anchor")
 await t.capture("ui-95-equipment-knee-band.png")
