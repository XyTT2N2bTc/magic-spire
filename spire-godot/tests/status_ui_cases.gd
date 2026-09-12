extends RefCounted
const Navigation=preload("res://tests/interface_ui_cases.gd")

static func inspect(t, id: String) -> String:
 var button=t.ui.find_child("Status_"+id.validate_node_name(),true,false)
 if button==null: t.check(false,"STATUS inspect target exists: "+id);return ""
 var parent=button.get_parent()
 while parent!=null and not parent is ScrollContainer: parent=parent.get_parent()
 if parent!=null: parent.ensure_control_visible(button);await t.frames()
 await Navigation.press(t,button.name)
 return t.visible_text(t.ui.find_child("StatusDetail",true,false))

static func run(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames()
 var before=JSON.stringify(ui.game.state)
 t.check(not t.visible_text(ui.layout).contains("上身束缚等级") and ui.find_child("OpenPressure",true,false)==null,"STATUS duplicated character/environment/pressure labels removed from battlefield")
 await Navigation.press(t,"OpenStatus")
 t.check(ui.find_child("Status_arms",true,false)!=null and ui.find_child("Status_legs",true,false)!=null,"STATUS real top button opens body levels even when zero")
 t.check(JSON.stringify(ui.game.state)==before,"STATUS opening is read-only")
 t.check(ui.find_child("StatusFilter_relic",true,false)==null and ui.view.statuses.all(func(e):return e.category!="relic"),"STATUS relics no longer duplicate their own interface")
 await t.capture("ui-74-status-overview.png")
 await Navigation.press(t,"StatusFilter_benefit")
 t.check(ui.find_child("Status_against_wall",true,false)!=null and t.visible_text(ui.layout).contains("贴墙"),"STATUS contact buff appears in benefit group")
 await Navigation.press(t,"CloseDrawer")
 ui.game.state.charge=2;ui.game.state.temporary_mana=5;ui.game.state.next_energy=1
 ui.render();await t.frames()
 t.check(ui.find_child("MainManaValue",true,false).text.contains("临时5"),"TEMP UI shows temporary pool alongside permanent mana")
 await Navigation.press(t,"OpenStatus")
 t.check((await inspect(t,"temporary_mana")).contains("整备结束最多保留20点"),"TEMP UI selected status explains independent point balance and lifetime")
 t.check(ui.find_child("Status_charge",true,false)!=null and ui.find_child("Status_temporary_mana",true,false)!=null,"STATUS stacked buffs appear using current projection")
 var grid=ui.find_child("StatusGrid",true,false)
 var scroll=grid.get_parent().get_parent()
 t.check(grid.get_children().all(func(tile):return scroll.get_global_rect().encloses(tile.get_global_rect())),"STATUS single-row overview keeps the entire card and value visible")
 await t.capture("ui-status-icons-overview.png")
 await Navigation.press(t,"OpenItems")
 t.check(ui.show_items and not ui.show_pressure,"STATUS uses existing mutually exclusive panel navigation")
 await t.start_practice("Practice_pressure")
 await Navigation.press(t,"OpenStatus");await Navigation.press(t,"StatusFilter_pressure")
 var source=ui.view.statuses.filter(func(e):return e.id.begins_with("pressure_"))[0]
 var description=await inspect(t,source.id)
 t.check(description.contains("身体与训练垫的摩擦") and description.contains("持续"),"STATUS pleasure effects show source and lifetime on selection")
 var old=ui.view.pressure.value
 t.check(await t.click("calm") and ui.view.pressure.value<old and ui.find_child("Status_pressure",true,false)!=null,"STATUS calm action updates panel through formal command")
 await t.capture("ui-76-status-pressure.png")

 await t.start_practice("Practice_pressure_battle")
 var breath=ui.find_child("DeepBreath",true,false)
 t.check(breath!=null and t.visible_text(breath).strip_edges().begins_with("深呼吸") and not ui.show_pressure,"STATUS deep breath is available without opening status")
 for type in ["strike","heavy","kick","fireball"]:
  var attack=ui.find_child("BasicAttack_"+type,true,false)
  t.check(attack.get_global_rect().end.x<=breath.get_global_rect().position.x and is_equal_approx(attack.position.y,breath.position.y),"STATUS deep breath sits right of each attack on same row")
 ui.game.state.pressure=70;ui.render();await t.frames()
 var energy=ui.view.energy;var mana=ui.view.mana
 await Navigation.press(t,"DeepBreath")
 t.check(ui.view.pressure.value==45 and ui.view.energy==energy-1 and ui.view.mana==mana,"STATUS native deep breath reduces pressure and spends only one energy")
 await t.capture("ui-116-deep-breath-action.png")
 ui.game.state.pressure=0;ui.render();await t.frames()
 t.check(ui.find_child("DeepBreath",true,false).disabled and ui.find_child("DeepBreathDetail",true,false).text.contains("当前快感已经降到最低"),"STATUS zero pleasure reason is visible beside disabled action")
 await icons(t)
 await charge_toggle(t)

static func charge_toggle(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game._gain_charge(7);ui.game.state.temporary_mana=35.0;ui.render();await t.frames()
 var before=ui.game.export_snapshot()
 var button=ui.find_child("StatusIcon_charge",true,false)
 var point=button.get_global_rect().get_center()
 await t.move_mouse(point)
 await t.mouse_button(point,MOUSE_BUTTON_RIGHT,true);await t.mouse_button(point,MOUSE_BUTTON_RIGHT,false)
 t.check(ui.game.state.charge_all and ui.game.state.charge==7 and not ui.show_pressure,"CHARGE UI native right-click arms all stacks without opening the status drawer")
 var after=ui.game.export_snapshot()
 for key in ["version","logs","summary","charge_all"]: before.erase(key);after.erase(key)
 var changed=before.keys().filter(func(key):return before[key]!=after.get(key))
 t.check(before==after,"CHARGE UI mode switch spends no turn, energy, mana or stacks; changed: "+str(changed))
 button=ui.find_child("StatusIcon_charge",true,false)
 var icon=button.get_children().filter(func(child):return child.get_script()==preload("res://ui/status_icon.gd"))[0]
 t.check(icon.status.emphasized and icon.badge.text=="7","CHARGE UI all-stack mode visibly highlights the icon and retains its count")
 await t.move_mouse(Vector2(1500,700));await t.move_mouse(button.get_global_rect().get_center())
 var text=t.visible_text(ui.find_child("TermExplanation",true,false))
 t.check(text.contains("全量蓄力") and text.contains("21") and text.contains("整备结束最多保留2层"),"SHELL UI without relic explains the two-stack retention cap")
 ui.game.RelicEffects.gain(ui.game,"turtle_shell");ui.render();await t.frames()
 button=ui.find_child("StatusIcon_charge",true,false)
 await t.move_mouse(Vector2(1500,700));await t.move_mouse(button.get_global_rect().get_center())
 text=t.visible_text(ui.find_child("TermExplanation",true,false))
 t.check(text.contains("整备结束最多保留4层"),"SHELL UI gaining relic updates charge lifetime without changing stack counts")
 var row=ui.view.relics.filter(func(r):return r.id=="turtle_shell")[0]
 t.check(row.rarity=="rare" and row.current.contains("4层") and row.current.contains("30点临时魔力") and preload("res://ui/relic_icon.gd").ART.has("turtle_shell"),"SHELL UI shared relic strip has rare metadata, actual retained count and dedicated art")
 await t.capture("ui-charge-all.png")
 await Navigation.press(t,"StatusIcon_charge")
 t.check(ui.show_pressure and ui.find_child("Status_charge",true,false)!=null,"CHARGE UI left-click still opens status details")
 point=ui.find_child("Status_charge",true,false).get_global_rect().get_center()
 await t.move_mouse(point)
 await t.mouse_button(point,MOUSE_BUTTON_RIGHT,true);await t.mouse_button(point,MOUSE_BUTTON_RIGHT,false)
 t.check(not ui.game.state.charge_all and ui.game.state.charge==7 and ui.show_pressure,"CHARGE UI detail card right-click restores ordinary mode without closing details")

static func icons(t) -> void:
 var ui=t.ui
 await t.start_practice("Practice_trader_solo")
 ui.game.state.charge=3;ui.game.state.temporary_mana=15
 ui.game.state.card_buffs=["echo_cast_free","embers_free"]
 ui.game.state.relics.append("break_bracer")
 ui.game.state.relic_used["break_bracer:turn"]=ui.game.state.tick
 var enemy=ui.game.state.enemies[0];enemy.ready_layers=2
 ui.render();await t.frames()
 await t.move_mouse(Vector2(782,140));await t.mouse_button(Vector2(782,140),MOUSE_BUTTON_LEFT,true);await t.mouse_button(Vector2(782,140),MOUSE_BUTTON_LEFT,false)
 var before=ui.game.state.duplicate(true)
 var hero=ui.find_child("StatusStrip_hero",true,false)
 var enemy_strip=ui.find_child("StatusStrip_"+enemy.id,true,false)
 t.check(hero!=null and enemy_strip!=null and hero.find_child("StatusIcon_ready_*",true,false)==null,"STATUS hero and enemy icons stay with their actual owner")
 t.check(Rect2(0,0,1600,900).encloses(hero.get_global_rect()) and enemy_strip.get_global_rect().end.y<=ui.find_child("BasicAttack_strike",true,false).get_global_rect().position.y,"STATUS strips stay in the viewport and above the action bar")
 var charge=ui.find_child("StatusIcon_charge",true,false)
 t.check(charge!=null and charge.find_child("StatusCount",true,false).text=="3","STATUS icon counter reads actual charge layers")
 await t.move_mouse(charge.get_global_rect().get_center());await t.frames()
 t.check(ui.term_popup!=null and t.visible_text(ui.term_popup).contains("整备结束最多保留2层"),"STATUS hovering the compact icon shows the default lifetime without turtle shell")
 await Navigation.press(t,"StatusIcon_charge")
 t.check(ui.show_pressure and ui.selected_status=="charge" and t.visible_text(ui.find_child("StatusDetail",true,false)).contains("3层"),"STATUS compact icon opens its current details")
 t.check(ui.game.state==before,"STATUS hover and selection do not change state or random streams")
 await Navigation.press(t,"CloseDrawer")
 var relic=ui.find_child("RelicShortcut_break_bracer",true,false)
 await t.move_mouse(relic.get_global_rect().get_center());await t.frames()
 t.check(ui.term_popup!=null and t.visible_text(ui.term_popup).contains("本次机会已使用"),"STATUS relic hover includes its own spent trigger")
 await t.move_mouse(Vector2(1550,60));await t.frames()
 await t.capture("ui-status-icons-battle.png")
