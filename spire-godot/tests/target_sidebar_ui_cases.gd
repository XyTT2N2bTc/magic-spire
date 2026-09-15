extends RefCounted
const Navigation=preload("res://tests/interface_ui_cases.gd")

static func query_contract(t) -> void:
 var queries=preload("res://ui/target_queries.gd")
 var index=preload("res://ui/action_index.gd")
 var make=func(id,slot,free,valid):return {"id":id,"group":"card","valid":valid,"reason":id,"payload":{"kind":"card","uid":"card","slot":slot,"target":"gear","free":free,"mode":"strain"}}
 var left=make.call("left-blocked","left",false,false)
 var right=make.call("right-ready","right",false,true)
 var second=make.call("second-face","left",true,true)
 var gear={"id":"gear"}
 var body={"id":"hands","slots":["left","right"],"targets":{"gear":gear},"sections":[{"name":"左手","equipment":[gear]},{"name":"右手","equipment":[gear]}]}
 var candidates=[left,right,second];var actions=index.new(candidates)
 var before=candidates.duplicate(true);var body_before=body.duplicate(true)
 var data={"card_uid":"card","free":false,"version":7}
 var grouped=queries.body_cards(actions,body,"card")
 t.check(grouped==[right,second] and is_same(grouped[0],actions.by_id[right.id]),"TARGET QUERY body merge keeps both faces and the original usable candidate for one physical target")
 t.check(queries.single_body_card(actions,body,"card",false)==right and queries.single_equipment_card(actions,[body],"card",false)==right,"TARGET QUERY single-equipment click uses the same physical target as body selection")
 t.check(queries.release_candidate(actions,body,"gear",data,7)==right,"TARGET QUERY quick release selects the same original bound candidate")
 var free=data.duplicate();free.free=true
 t.check(queries.release_candidate(actions,body,"gear",free,7)==second and queries.payload_candidates(actions,free,7)==[second],"TARGET QUERY face switch is reflected without a new version")
 t.check(queries.release_candidate(actions,body,"other",data,7).is_empty(),"TARGET QUERY missing explicit target cannot fall back to another equipment")
 t.check(queries.equipment_choices(actions,data,7,body)==[left],"TARGET QUERY generic drag preserves its first-per-target rejection policy")
 var entries=queries.equipment_entries(body);entries.gear.locations.clear();entries.clear();grouped.clear()
 t.check(queries.equipment_entries(body).gear.locations==["左手","右手"] and candidates==before and body==body_before,"TARGET QUERY result containers do not mutate source candidates or body sections")
 for version in [6,8]:
  t.check(queries.payload_candidates(actions,data,version).is_empty() and queries.release_choices(actions,body,data,version).is_empty(),"TARGET QUERY mismatched version blocks drag and quick selection: "+str(version))
 var missing=data.duplicate();missing.erase("version")
 t.check(queries.payload_candidates(actions,missing,7).is_empty() and queries.release_candidate(actions,body,"gear",missing,7).is_empty(),"TARGET QUERY missing version cannot acquire an action")
 var blocked=right.duplicate(true);blocked.valid=false
 var rejected=index.new([left,blocked])
 t.check(queries.first_usable([left,blocked])==left and rejected.first_usable("card")==blocked and rejected.find("card")==left,"TARGET QUERY first and last rejection policies remain distinct")
 var capture=right.duplicate(true);capture.id="capture";capture.payload.target="guard_bind"
 t.check(queries.single_equipment_card(index.new([right,capture]),[body],"card",false).is_empty(),"TARGET QUERY capture alongside one equipment still requires explicit choice")
 var hand_a=left.duplicate(true);hand_a.payload.hand_uid="hand-a"
 var hand_b=hand_a.duplicate(true);hand_b.id="hand-b";hand_b.payload.hand_uid="hand-b";hand_b.valid=true
 var self_card=hand_b.duplicate(true);self_card.id="self";self_card.payload.self_target=true
 var door={"id":"door","group":"prison","valid":true,"payload":{"kind":"prison","action":"unlock","uid":"card"}}
 var drag_actions=index.new([hand_a,hand_b,self_card,second,door])
 t.check(queries.payload_candidates(drag_actions,data,7)==[hand_a,self_card,door],"TARGET QUERY hand-target dedup keeps first choice and retains self-target and prison unlock entries")
 t.check(queries.payload_candidates(drag_actions,free,7)==[second],"TARGET QUERY the other face cannot acquire a prison unlock action")
 var ids={"candidate_ids":["missing","second-face","door","second-face"],"version":7}
 t.check(queries.payload_candidates(drag_actions,ids,7)==[second,door,second],"TARGET QUERY explicit IDs retain caller order and duplicates while dropping missing IDs")
 var fire={"id":"fire","group":"attack","valid":true,"payload":{"kind":"attack","type":"fireball","form":0,"target":"gear"}}
 var attacks=index.new([fire]);var fire_data={"action_type":"fireball","version":7}
 t.check(queries.payload_candidates(attacks,fire_data,7)==[fire] and queries.release_candidate(attacks,body,"gear",fire_data,7)==fire,"TARGET QUERY fireball drag and exact equipment selection share the formal action")
 t.check(queries.release_candidate(attacks,body,"gear",fire_data,8).is_empty(),"TARGET QUERY stale fireball cannot retain a previously usable action")

static func press(t, control: Control) -> void:
 var point=control.get_global_rect().get_center()
 await t.move_mouse(point)
 await t.mouse_button(point,MOUSE_BUTTON_LEFT,true)
 await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)

# Real pointer drag onto a body region: returns every drop strip entry, every drag hint text and
# the hint ids, so a missing projection can be compared against the complete one.
static func copy_drag_text(t, uid: String, slot: String) -> Dictionary:
 var ui=t.ui
 var point=t.card_point(uid)
 await t.move_mouse(point)
 await t.mouse_button(point,MOUSE_BUTTON_LEFT,true)
 await t.move_mouse(point+Vector2(0,-42),true)
 await t.move_mouse(ui.body_buttons[slot].get_global_rect().get_center(),true)
 var strip=""
 for target in ui.drop_targets.values(): strip+=str(target.get_meta("preview_detail",""))+"\n"
 var hints=""
 for hint in ui.drag_hints: hints+=t.visible_text(hint)
 var ids=ui.drag_hints.map(func(hint):return hint.get_meta("target_id",""))
 await t.move_mouse(Vector2(1550,70),true)
 await t.mouse_button(Vector2(1550,70),MOUSE_BUTTON_LEFT,false)
 return {"strip":strip,"hints":hints,"ids":ids}

# docs/ondemand-copy.md §4.1/§6 scenario 0: a test-side copy of the View with a deleted
# card_texts key or without the card group's detail must render the drag sections without an
# engine error, keep the recomputed text and leave a named record instead of a silent blank.
static func copy_missing_key_never_crashes(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game.state.equipment.clear();ui.game.state.wall="normal"
 ui.game.add_fixture("wrist",4,10,false);ui.game.add_fixture("wrist",4,10,false)
 var card=preload("res://tests/curse_cases.gd").give(ui.game,"strain")
 ui.render();await t.frames()
 var free_detail=ui.actions.find("card",{"uid":card.uid,"free":true}).detail
 var before=ui.game.export_snapshot()
 var baseline={}
 for free_face in [false,true]:
  ui.card_faces[card.uid]=free_face
  ui.render();await t.frames()
  baseline[free_face]=await copy_drag_text(t,card.uid,"thigh")
 t.check(baseline[false].strip.contains("请右键切换到"),"COPY bound-face drag renders the drop strip face hint")
 t.check(baseline[true].ids.has("hero") and baseline[true].hints.contains(free_detail),"COPY free-face drag renders the hover hint with the candidate detail")
 t.check(ui.game.export_snapshot()==before and ui.projection_misses.is_empty(),"COPY complete projection renders no miss record and pays nothing")
 var copy=ui.game.get_view().duplicate(true)
 copy.card_texts.erase(card.type)
 var erased_misses=[]
 for free_face in [false,true]:
  ui.card_faces[card.uid]=free_face
  ui.render(copy);await t.frames()
  var erased=await copy_drag_text(t,card.uid,"thigh")
  erased_misses.append_array(ui.projection_misses)
  t.check(erased==baseline[free_face],"COPY deleted card_texts key keeps the drop strip and hint text identical for face "+str(free_face))
 t.check(erased_misses.any(func(entry):return entry.point=="card_entry" and entry.key.begins_with(card.type)),"COPY deleted card key is recomputed through the single entry and recorded: "+str(erased_misses))
 var detail_copy=ui.game.get_view().duplicate(true)
 var removed=0
 for candidate in detail_copy.candidates:
  if candidate.payload.get("kind","")=="card": candidate.erase("detail");removed+=1
 t.check(removed>0,"COPY fixture removes detail from the card candidate group")
 for free_face in [false,true]:
  ui.card_faces[card.uid]=free_face
  ui.render(detail_copy);await t.frames()
  var recomputed=await copy_drag_text(t,card.uid,"thigh")
  t.check(recomputed==baseline[free_face],"COPY removed candidate detail is recomputed byte-identically for face "+str(free_face))
 t.check(ui.projection_misses.any(func(entry):return entry.point=="detail_of"),"COPY removed candidate detail is recorded instead of silently blank: "+str(ui.projection_misses))
 t.check(ui.projection_misses.all(func(entry):return entry.view_version==ui.view.version),"COPY miss records name the render they belong to")
 t.check(ui.game.export_snapshot()==before,"COPY missing-key rendering never changes state or random cursors")

static func run(t) -> void:
 query_contract(t)
 await unavailable_body_hint(t)
 await bound_face_hint(t)
 await automatic_targets(t)
 await hand_targets(t)
 await copy_missing_key_never_crashes(t)
 var ui=t.ui
 ui.restart(42);await t.frames()
 t.check(not ui.action_log_open and not ui.action_log_panel.visible and ui.action_log_toggle.visible,"SIDEBAR new session starts collapsed with a visible manual entry")
 ui.render();await t.frames()
 t.check(not ui.action_log_open and not ui.action_log_panel.visible,"SIDEBAR ordinary refresh does not reopen the default collapsed log")
 await Navigation.press(t,"OpenActionLog")
 var before=ui.game.export_snapshot()
 var second=ui.view.enemies[1].id
 var layout_id=ui.layout.get_instance_id();var card_id=ui.card_buttons.values()[0].get_instance_id()
 var log_id=ui.action_log_panel.get_instance_id();var reads=ui.game.view_reads
 await press(t,ui.actor_targets[second])
 t.check(ui.selected_enemy==second and ui.game.export_snapshot()==before,"TARGET sprite click selects enemy without action or random change")
 t.check(ui.layout.get_instance_id()==layout_id and ui.card_buttons.values()[0].get_instance_id()==card_id and ui.action_log_panel.get_instance_id()==log_id and ui.game.view_reads==reads,"TARGET selection updates attacks without rebuilding scene/cards/log or reprojecting rules")
 t.check(not ui.action_log_open and not ui.action_log_panel.visible and ui.action_log_toggle.visible,"SIDEBAR outside click collapses without swallowing enemy selection")
 var attacks=ui.view.candidates.filter(func(c):return c.group=="attack" and ui.candidate_buttons.has(c.id))
 t.check(attacks.size()==4 and attacks.all(func(c):return c.payload.enemy==second),"TARGET all four rendered attacks now reference clicked enemy")
 await Navigation.press(t,"OpenActionLog")
 t.check(ui.action_log_panel.visible,"SIDEBAR collapsed entry reopens")
 await press(t,ui.action_log_panel.get_child(0).get_child(1))
 t.check(ui.action_log_open,"SIDEBAR reading within panel does not dismiss it")
 await Navigation.press(t,"PinActionLog")
 await press(t,ui.actor_targets[ui.view.enemies[0].id])
 t.check(ui.action_log_pinned and ui.action_log_panel.visible,"SIDEBAR pinned panel survives another target selection")
 await Navigation.press(t,"CloseActionLog")
 t.check(not ui.action_log_panel.visible and ui.action_log_pinned,"SIDEBAR manual close remains available while pinned")
 await Navigation.press(t,"OpenActionLog")
 await Navigation.press(t,"PinActionLog")
 await press(t,t.action_button("strike"))
 t.check(not ui.action_log_open and ui.view.energy==2,"SIDEBAR unpinned outside attack both dismisses and executes once")
 for type in ["strike","heavy","kick","fireball"]:
  ui.restart(42);ui.game.state.round=2;ui.render();await t.frames()
  second=ui.view.enemies[1].id
  await press(t,ui.actor_targets[second])
  var first_hp=ui.view.enemies[0].hp;var second_hp=ui.view.enemies[1].hp
  await press(t,t.action_button(type))
  t.check(ui.view.enemies[0].hp==first_hp and ui.view.enemies[1].hp<second_hp,"TARGET clicked "+type+" attacks only selected enemy")
 # A name click switches the same selection back; a subsequent drag can still aim elsewhere.
 await Navigation.press(t,"EnemySelect_"+ui.view.enemies[0].id)
 t.check(ui.selected_enemy==ui.view.enemies[0].id,"TARGET name and sprite share selection")
 await Navigation.press(t,"OpenActionLog");await Navigation.press(t,"PinActionLog")
 var old=ui.view.enemies[1].hp
 await t.drag_control_to(t.action_button("strike"),second)
 t.check(ui.view.enemies[1].hp<old and ui.action_log_open,"TARGET drag retains actual drop target and pinned sidebar")
 await Navigation.press(t,"EnemySelect_"+second)
 await t.capture("ui-81-pinned-log-selected-target.png")
 await Navigation.press(t,"PinActionLog")
 await press(t,ui.actor_targets[second])
 await t.capture("ui-82-collapsed-action-log.png")
 # Rejections stay beside the hovered target; legal actor hints appear together.
 ui.restart(42);await t.frames()
 before=ui.game.export_snapshot()
 second=ui.view.enemies[1].id
 for stale in [true,false]:
  var button=t.action_button("fireball")
  button.drag_payload.version=ui.view.version-1 if stale else ui.view.version
  var point=button.get_global_rect().get_center()
  await t.move_mouse(point)
  await t.mouse_button(point,MOUSE_BUTTON_LEFT,true)
  await t.move_mouse(point+Vector2(0,-42),true)
  await t.move_mouse(ui.actor_targets[second].get_global_rect().get_center(),true)
  t.check(t.root.gui_is_dragging(),"TARGET fireball uses native drag for current and expired requests")
  t.check(ui.drag_hints.size()==(0 if stale else ui.view.enemies.filter(func(e):return not e.gone).size()),"TARGET all and only legal enemy hints are visible together")
  if stale:
   t.check(is_instance_valid(ui.term_popup) and ui.term_anchor==ui.actor_targets[second] and t.visible_text(ui.term_popup).contains("行动已失效"),"TARGET expired drag shows rejection beside its actual target")
   var popup_id=ui.term_popup.get_instance_id() if is_instance_valid(ui.term_popup) else 0
   await t.frames()
   t.check(is_instance_valid(ui.term_popup) and ui.term_popup.get_instance_id()==popup_id,"TARGET repeated drag validation reuses rejection popup")
   point=Vector2(770,200)
   await t.move_mouse(point,true)
   await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)
   t.check(not is_instance_valid(ui.term_popup) or (not ui.term_popup.has_meta("drag_reason") and ui.term_anchor!=ui.actor_targets[second]),"TARGET leaving and cancelling expired drag clears its target rejection; unrelated hover tips remain allowed")
   t.check(ui.game.export_snapshot()==before,"TARGET cancelling expired drag spends nothing")
  else:
   t.check(not is_instance_valid(ui.term_popup) and ui.game.export_snapshot()==before,"TARGET valid drag has no repeated battlefield explanation and no advance payment")
   t.check(ui.drag_hints.all(func(hint):return hint.size.y<=90 and is_equal_approx(hint.size.y,hint.get_combined_minimum_size().y)),"TARGET short enemy hints shrink to wrapped content instead of retaining initial tall layout")
   await t.capture("ui-drag-clean-battlefield.png")
   var health=ui.view.enemies[1].hp;var mana=ui.view.mana;var energy=ui.view.energy
   var attack=ui.actions.find("attack",{"type":"fireball","enemy":second})
   await t.mouse_button(ui.actor_targets[second].get_global_rect().get_center(),MOUSE_BUTTON_LEFT,false)
   t.check(ui.view.enemies[1].hp<health and ui.view.mana==mana-attack.mana_payment.mana and ui.view.energy==energy-attack.cost,"TARGET clean fireball drop still damages the actual target and pays its current cost once")

static func bound_face_hint(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game._discard_end();ui.game.state.equipment.clear()
 var target=ui.game.add_fixture("ankle",300,1000)
 var card=preload("res://tests/curse_cases.gd").give(ui.game,"concentration")
 ui.render();await t.frames()
 if not ui.card_faces.get(card.uid,false): await t.flip(card.uid)
 var before=ui.game.export_snapshot();var point=t.card_point(card.uid)
 await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.move_mouse(point+Vector2(0,-42),true)
 await t.move_mouse(ui.body_buttons.ankle.get_global_rect().get_center(),true)
 t.check(t.root.gui_is_dragging() and ui.active_drag.get("free",false) and ui.drop_targets.keys().any(func(id):return ui.actions.by_id[id].payload.target==target.id),"TARGET second bound face exposes its real equipment target")
 t.check(not ui.drag_hints.any(func(hint):return hint.get_meta("target_id","")=="hero"),"TARGET second bound face never labels equipment damage as a self effect")
 await t.move_mouse(Vector2(1550,70),true);await t.mouse_button(Vector2(1550,70),MOUSE_BUTTON_LEFT,false)
 t.check(ui.game.export_snapshot()==before and ui.drag_hints.is_empty(),"TARGET cancelling second-bound-face drag preserves the full state")

static func automatic_targets(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game.state.equipment.clear();ui.game.state.wall="normal"
 var wrist=ui.game.add_fixture("wrist",8);var ankle=ui.game.add_fixture("ankle",8)
 ui.render();await t.frames()
 var before=ui.game.export_snapshot()
 await t.move_mouse(ui.actor_targets.hero.get_global_rect().get_center())
 t.check(ui.actor_targets.hero.get_theme_stylebox("hover") is StyleBoxEmpty and ui.drop_targets.is_empty() and ui.drag_hints.is_empty(),"TARGET idle hero has no noninteractive highlight or target window")
 await t.move_mouse(ui.body_buttons.wrist.get_global_rect().get_center())
 t.check(ui.drop_targets.is_empty() and ui.game.export_snapshot()==before,"TARGET ordinary body hover does not open action targets")
 var card=ui.view.hand.filter(func(c):return c.type=="strain")[0]
 if ui.card_faces.get(card.uid,false): await t.flip(card.uid)
 var point=t.card_point(card.uid)
 await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.move_mouse(point+Vector2(0,-42),true)
 t.check(t.root.gui_is_dragging() and ui.drop_targets.is_empty(),"TARGET dragging does not open a combined equipment strip")
 for slot in ["wrist","ankle","wrist"]:
  await t.move_mouse(ui.body_buttons[slot].get_global_rect().get_center(),true)
  var ids=ui.drop_targets.keys().map(func(id):return ui.actions.by_id[id].payload.target)
  var expected=wrist.id if slot=="wrist" else ankle.id
  var anchor=ui.layout.get_global_transform().affine_inverse()*ui.body_buttons[slot].get_global_rect()
  t.check(ids==[expected] and ui.drop_panel.get_meta("body_id")==ui.body_buttons[slot].get_meta("body_id"),"TARGET aiming at a different region replaces the strip without other regions")
  t.check(is_equal_approx(ui.drop_panel.position.x,anchor.end.x+3) and is_equal_approx(ui.drop_panel.position.y,anchor.position.y),"TARGET strip aligns beside the aimed body in canvas coordinates")
 t.check(ui.game.export_snapshot()==before,"TARGET aiming and changing body groups never pays or changes RNG")
 await t.capture("ui-body-local-drag-targets.png")
 await t.move_mouse(Vector2(1550,70),true);await t.mouse_button(Vector2(1550,70),MOUSE_BUTTON_LEFT,false)
 t.check(ui.drop_targets.is_empty() and ui.active_drag.is_empty() and ui.drag_hints.is_empty() and ui.game.export_snapshot()==before,"TARGET cancel removes every target window without changing state")
 # Existing targeted option rows expose sibling candidates, retaining the original item.
 ui.game.state.equipment.clear();wrist=ui.game.add_fixture("thigh",8)
 ui.game._gain_tool("shard");ui.render();await t.frames()
 var tool=ui.game.state.items.back().id
 await Navigation.press(t,"OpenItems");await Navigation.press(t,"ToolItem_"+tool);await Navigation.press(t,"ToolSlot_thigh")
 var choice=ui.actions.find("item",{"kind":"item_use","item":tool,"target":wrist.id})
 var button=ui.candidate_buttons[choice.id]
 point=button.get_global_rect().get_center();before=ui.game.export_snapshot()
 await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.move_mouse(point+Vector2(0,-42),true)
 t.check(ui.drop_targets.is_empty(),"TARGET item drag also waits for a body region instead of merging equipment")
 await t.move_mouse(ui.body_buttons.thigh.get_global_rect().get_center(),true)
 t.check(t.root.gui_is_dragging() and ui.drop_targets.has(choice.id) and ui.game.export_snapshot()==before,"TARGET native item option drag opens its legal target without spending a use")
 var amount=ui.game._equipment(wrist.id).durability;var uses=ui.game._item(tool).uses
 await t.release_target(await t.reveal_drop_target(choice.id))
 t.check(ui.game._equipment(wrist.id).durability<amount and ui.game._item(tool).uses==uses-1 and ui.active_drag.is_empty(),"TARGET option drop submits original item candidate once and clears windows")

static func hand_targets(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames();ui.game._discard_end()
 var cards=preload("res://tests/curse_cases.gd")
 var source=cards.give(ui.game,"ready_to_strike");var chosen=cards.give(ui.game,"sensitive");var peer=cards.give(ui.game,"sensitive")
 ui.render();await t.frames()
 var before=ui.game.export_snapshot();var point=t.card_point(source.uid)
 await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.move_mouse(point+Vector2(0,-42),true)
 var first=ui.find_child("HandDragTarget_"+chosen.uid,true,false);var second=ui.find_child("HandDragTarget_"+peer.uid,true,false)
 t.check(first!=null and second!=null and ui.find_child("HandDragTarget_"+source.uid,true,false)==null and ui.game.export_snapshot()==before,"TARGET hand choice shows both legal physical cards and excludes source without payment")
 if first==null:
  await t.mouse_button(Vector2(1550,70),MOUSE_BUTTON_LEFT,false);return
 point=first.get_global_rect().get_center();await t.move_mouse(point,true);await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)
 t.check(ui.game.state.exhaust.any(func(c):return c.uid==chosen.uid) and ui.game.state.hand.any(func(c):return c.uid==peer.uid) and ui.view.energy==2 and ui.view.mana==90 and ui.drag_hints.is_empty(),"TARGET native hand target drop exhausts exactly the selected card and pays once")

static func unavailable_body_hint(t) -> void:
 var ui=t.ui
 for scaled in [false,true]:
  ui.restart(42);ui.game.state.equipment.clear();ui.game.state.composites.clear();ui.game.state.links.clear()
  for enemy in ui.game.state.enemies: enemy.hp=0;enemy.gone=true
  ui.game._finish_battle();ui.render();await t.frames()
  t.check(await t.click("reward",{"type":"skip"}),"TARGET unavailable-body fixture enters real preparation")
  ui.game._discard_end()
  var card=preload("res://tests/curse_cases.gd").give(ui.game,"strain")
  ui.render();await t.frames()
  if not ui.card_faces.get(card.uid,false): await t.flip(card.uid)
  if scaled:
   ui.layout.scale=Vector2(0.85,0.85);ui.layout.position=Vector2(35,25);await t.frames()
  var unavailable=ui.view.body_regions.filter(func(body):return ui._body_card_actions(body.id,card.uid).is_empty())
  var available=ui.view.body_regions.filter(func(body):return ui._body_card_actions(body.id,card.uid).any(func(c):return c.valid and c.payload.free))
  t.check(not unavailable.is_empty() and not available.is_empty(),"TARGET fixture has both unavailable and legal free region targets")
  if unavailable.is_empty() or available.is_empty(): continue
  var before=ui.game.export_snapshot();var point=t.card_point(card.uid)
  await t.move_mouse(point);await t.mouse_button(point,MOUSE_BUTTON_LEFT,true);await t.move_mouse(point+Vector2(0,-42),true)
  var ghost=t.root.find_child("CardDragPreview",true,false)
  t.check(ghost!=null and ghost.z_index>ui.find_child("BodyEquipmentPanel",true,false).z_index and ghost.mouse_filter==Control.MOUSE_FILTER_IGNORE and t.visible_text(ghost).contains("自由"),"TARGET card drag preview stays above body sidebar and does not intercept drops")
  for body in unavailable.slice(0,2):
   var anchor=ui.body_buttons[body.id]
   await t.move_mouse(anchor.get_global_rect().get_center(),true)
   var popup=ui.term_popup
   t.check(t.root.gui_is_dragging() and not anchor.get_meta("target_selectable",true) and ui.drop_panel==null and ui.drop_targets.is_empty(),"TARGET unavailable region remains dim and never creates an empty equipment grid")
   t.check(is_instance_valid(popup) and t.visible_text(popup).strip_edges()=="这张牌不能用于%s。" % body.name and popup.size.x>=140 and popup.size.y<90,"TARGET rejection wraps horizontally with complete body-specific reason and no scroll strip")
   if is_instance_valid(popup):
    var local_anchor=ui.layout.get_global_transform().affine_inverse()*anchor.get_global_rect()
    t.check(is_equal_approx(popup.position.x,local_anchor.end.x+12) and is_equal_approx(popup.position.y,local_anchor.position.y),"TARGET rejection uses the same canvas coordinates as its body anchor, including scaled layouts")
    var popup_id=popup.get_instance_id()
    await t.move_mouse(anchor.get_global_rect().get_center(),true)
    t.check(ui.term_popup.get_instance_id()==popup_id,"TARGET stationary invalid hover reuses one popup")
  if not scaled: await t.capture("ui-unavailable-body-drag.png")
  var legal=ui.body_buttons[available[0].id]
  await t.move_mouse(legal.get_global_rect().get_center(),true)
  t.check(ui.drop_panel!=null and not ui.drop_targets.is_empty() and (not is_instance_valid(ui.term_popup) or not ui.term_popup.has_meta("drag_reason")),"TARGET moving to a legal region replaces rejection with real targets")
  await t.move_mouse(ui.body_buttons[unavailable[0].id].get_global_rect().get_center(),true)
  t.check(ui.drop_panel==null and is_instance_valid(ui.term_popup),"TARGET returning to unavailable region removes previous legal strip and restores reason")
  await t.mouse_button(ui.body_buttons[unavailable[0].id].get_global_rect().get_center(),MOUSE_BUTTON_LEFT,false)
  t.check(ui.game.export_snapshot()==before and ui.drop_panel==null and ui.drop_targets.is_empty() and (not is_instance_valid(ui.term_popup) or not ui.term_popup.has_meta("drag_reason")),"TARGET rejected drop clears hints without spending cards, energy, turns or RNG")
 ui.restart(42);await t.frames()
