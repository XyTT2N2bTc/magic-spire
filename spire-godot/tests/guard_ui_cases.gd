extends RefCounted

static func run(t) -> void:
 var ui=t.ui
 await t.start_practice("Practice_guard")
 t.check(ui.view.phase=="battle" and ui.view.enemies.size()==1 and ui.view.enemies[0].type=="guard" and ui.view.enemies[0].maximum==90,"GUARD UI practice starts real succubus guard")
 var enemy=ui.view.enemies[0].id
 var picture=ui.find_child("EnemyArt_"+enemy,true,false)
 var expected_path="res://assets/art/enemy-guards-v1/guard-purple-v1.png" if picture.variant=="guard_purple" else "res://assets/art/enemy-guards-v1/guard-brown-v1.png"
 t.check(picture.variant==ui.view.enemies[0].visual_variant and picture.enemy_sprite.texture.resource_path==expected_path,"GUARD UI uses the generated guard portrait variant from the read-only view")
 var group=ui.find_child("EnemyGroup_"+enemy,true,false)
 var select=ui.find_child("EnemySelect_"+enemy,true,false)
 t.check(is_equal_approx(group.position.x+group.size.x/2.0,ui.ENEMY_STAGE_LEFT+ui.ENEMY_STAGE_WIDTH/2.0),"GUARD UI single enemy uses the full stage width without reserving action-log space")
 t.check(absf(picture.get_global_rect().get_center().x-select.get_global_rect().get_center().x)<1.0,"GUARD UI portrait is centered over its name, health and ground marker")
 var initial=ui.game.export_snapshot()
 t.check(ui.find_child("IntentIcon_"+enemy+"_bind",true,false)!=null and ui.find_child("IntentIcon_"+enemy+"_deadline",true,false)==null,"GUARD UI opening shows actual binding intent without removed deadline")
 t.check(ui.find_child("HeroGuardBind",true,false)==null and ui.game.export_snapshot()==initial,"GUARD UI bind meter stays hidden before application and projection is read-only")
 await t.capture("ui-34-guard-intent.png")

 t.check(await t.click("end") and ui.game._enemy(enemy).intent.kind=="bind_prepare","GUARD UI opening resolves before bind preparation")
 t.check(await t.click("end") and ui.game._enemy(enemy).intent.kind=="bind_apply","GUARD UI preparation occupies one enemy action")
 t.check(await t.click("end") and ui.view.guard_bind.value==50.0,"GUARD UI bind application starts at fifty")
 t.check(ui.find_child("HeroGuardBind",true,false)!=null and ui.find_child("HeroGuardBindValue",true,false).text=="50/100" and ui.actor_targets.has("guard_bind"),"GUARD UI compact bind meter appears below mana and accepts card targeting")
 t.check(ui.view.statuses.any(func(status):return status.id=="guard_bind"),"GUARD UI status panel receives the bind rules")
 var bind_bar=ui.find_child("HeroGuardBind",true,false)
 var bind_rect=bind_bar.get_global_rect()
 var snapshot=ui.game.export_snapshot()
 var navigation=preload("res://tests/interface_ui_cases.gd")
 await navigation.press(t,"OpenStatus")
 await preload("res://tests/status_ui_cases.gd").inspect(t,"guard_bind")
 var drawer=ui.find_child("InformationDrawer",true,false)
 t.check(drawer.get_global_rect().encloses(bind_rect),"GUARD UI status window covers the battlefield capture meter in the regression scenario")
 for id in ["HeroGuardBindCaption","HeroGuardBind","HeroGuardBindValue","GuardBindTarget"]:
  var control=ui.find_child(id,true,false)
  t.check(control.z_index<drawer.z_index and not drawer.is_ancestor_of(control),"GUARD UI capture control stays below the status window: "+id)
 var point=ui.actor_targets.guard_bind.get_global_rect().get_center()
 await t.move_mouse(point)
 var hovered=t.root.gui_get_hovered_control()
 t.check(hovered!=null and (hovered==drawer or drawer.is_ancestor_of(hovered)),"GUARD UI covered capture target cannot intercept status-window input")
 await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)
 t.check(ui.show_pressure and ui.game.export_snapshot()==snapshot and bind_bar.get_global_rect()==bind_rect,"GUARD UI reading over the capture meter changes neither its position nor game state")
 await t.move_mouse(Vector2(1550,60));await t.capture("ui-guard-status-layer.png")
 await navigation.press(t,"CloseDrawer")
 await t.move_mouse(point)
 t.check(t.root.gui_get_hovered_control()==ui.actor_targets.guard_bind and ui.find_child("HeroGuardBind",true,false)==bind_bar,"GUARD UI closing status restores the original capture drop target without rebuilding it")

 var cards=ui.view.hand.filter(func(card):return card.type=="strain")
 t.check(not cards.is_empty(),"GUARD UI has a real strain card for bind interaction")
 if not cards.is_empty():
  var before=float(ui.view.guard_bind.value)
  await t.drop_card_on_actor(cards[0].uid,"guard_bind")
  t.check(ui.view.guard_bind.value<before and ui.view.pressure.value>0,"GUARD UI native card drop damages bind and resolves paid-energy stimulation")
 await t.capture("ui-35-guard-bind.png")

 ui.game.state.guard_bind.progress=100.0
 ui.game._enemy(enemy).intent={"kind":"capture","text":"执行收押","delayed":false}
 ui.render();await t.frames()
 var mana=ui.view.mana
 var deck=ui.view.deck_count
 t.check(await t.click("end") and ui.view.phase=="captured" and ui.view.security==1 and ui.view.reward_count==0 and ui.view.mana==mana and ui.view.deck_count==deck,"GUARD UI next enemy action captures at full bind without victory reward")
 t.check(t.visible_text(ui.layout).contains("收押完成") and t.visible_text(ui.layout).contains("开始探索与逃脱"),"GUARD UI capture result offers prison continuation")

 await t.start_practice("Practice_double_guard")
 t.check(ui.view.enemies.size()==2 and ui.view.enemies[0].id!=ui.view.enemies[1].id,"GUARD UI double guards retain independent ids")
 for guard in ui.view.enemies:
  picture=ui.find_child("EnemyArt_"+guard.id,true,false)
  t.check(picture.variant==guard.visual_variant and guard.visual_variant in ["guard_purple","guard_brown"],"GUARD UI paired guard keeps its own registered portrait "+guard.id)
 var first_group=ui.find_child("EnemyGroup_"+ui.view.enemies[0].id,true,false)
 var last_group=ui.find_child("EnemyGroup_"+ui.view.enemies[-1].id,true,false)
 var row_right=last_group.position.x+last_group.size.x*last_group.scale.x
 t.check(is_equal_approx(first_group.position.x-ui.ENEMY_STAGE_LEFT,ui.ENEMY_STAGE_LEFT+ui.ENEMY_STAGE_WIDTH-row_right) and row_right>ui.action_log_panel.position.x,"GUARD UI enemy row stays centered across the stage even when it extends behind the action log")
 var first=ui.view.enemies[0].id
 var second=ui.view.enemies[1].id
 var kick=ui.view.candidates.filter(func(c):return c.payload.kind=="attack" and c.payload.type=="kick" and c.payload.form==0 and c.payload.enemy==second)[0]
 var second_health=ui.game._enemy(second).hp
 await t.drag_control_to(t.action_button("kick"),second)
 t.check(kick.valid and ui.game._enemy(first).hp==90 and ui.game._enemy(second).hp==second_health-kick.payload.damage and not ui.game._enemy(first).intent.delayed and ui.game._enemy(second).intent.delayed==kick.payload.interrupt,"GUARD UI direct attack applies the offered damage and interrupt only to the chosen guard")
 await t.capture("ui-36-double-guard.png")

 var brown_found=false
 for seed in range(12):
  ui.restart(seed,true,"guard");await t.frames()
  if ui.view.enemies[0].visual_variant=="guard_brown":
   picture=ui.find_child("EnemyArt_"+ui.view.enemies[0].id,true,false)
   brown_found=picture.enemy_sprite.texture.resource_path=="res://assets/art/enemy-guards-v1/guard-brown-v1.png"
   await t.capture("ui-guard-brown-portrait.png")
   break
 t.check(brown_found,"GUARD UI registered brown portrait is reachable through formal seeded generation")
