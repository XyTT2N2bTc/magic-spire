extends RefCounted

static func run(t) -> void:
 await infusion(t)
 await justice_opening(t)
 await bound_kick(t)
 t.ui.restart(42);t.ui.game.state.round=2;t.ui.render();await t.frames()
 var ui=t.ui
 var kick=ui.find_child("BasicAttack_kick",true,false)
 var choice=ui.actions.find("attack",{"type":"kick","form":0,"enemy":ui.selected_enemy})
 t.check(t.visible_text(kick).contains("正义飞踢") and choice.cost==2 and ui.find_child("BasicAttackDetail_kick",true,false).text=="18 伤害","JUSTICE UI displays official name two-energy cost and eighteen damage")
 ui.game.state.pressure=40;ui.render();await t.frames()
 var rail=ui.find_child("BasicActionRail",true,false)
 var slots=[ui.find_child("BasicAttack_strike",true,false),ui.find_child("BasicAttack_heavy",true,false),ui.find_child("BasicAttack_kick",true,false),ui.find_child("BasicAttack_fireball",true,false),ui.find_child("DeepBreath",true,false)]
 t.check(rail.position.x==384 and rail.size.x==1195 and rail.position.y+rail.size.y<630,"BASIC UI rail fills the battle column and clears the hand")
 t.check(slots.all(func(b):return rail.get_global_rect().encloses(b.get_global_rect()) and is_equal_approx(b.size.x,slots[0].size.x)),"BASIC UI five equal action tiles stay inside the rail")
 t.check(is_equal_approx(slots[0].position.x,rail.position.x+10) and is_equal_approx(slots[-1].position.x+slots[-1].size.x,rail.position.x+rail.size.x-10),"BASIC UI equal end margins leave no unused action slot")
 for type in ["strike","heavy","kick","fireball"]:
  var c=ui.actions.find("attack",{"type":type,"form":0,"enemy":ui.selected_enemy})
  var label=ui.find_child("BasicAttackDetail_"+type,true,false)
  t.check(label.text==c.brief and not label.text.contains(ui.view.enemies[0].name),"BASIC UI compact damage uses the authoritative preview without target prose")
 await t.capture("ui-basic-action-rail.png")
 for type in ["strike","heavy","kick"]:
  ui.restart(42);await t.frames()
  var before=ui.game.export_snapshot()
  var button=ui.find_child("BasicAttack_"+type,true,false)
  var point=button.get_global_rect().get_center()
  await t.mouse_button(point,MOUSE_BUTTON_RIGHT,true)
  await t.mouse_button(point,MOUSE_BUTTON_RIGHT,false)
  t.check(ui.attack_forms[type]==1 and ui.game.export_snapshot()==before,"BASIC UI right click flips form without cost or randomness")
  button=ui.find_child("BasicAttack_"+type,true,false)
  t.check(button.drag_payload.form==1,"BASIC UI drag payload preserves selected form")
  var c=ui.actions.find("attack",{"type":type,"form":1,"enemy":ui.selected_enemy})
  t.check(ui.candidate_buttons.has(c.id) and t.visible_text(button).contains(c.label),"BASIC UI flipped form uses its actual candidate")
  if type=="heavy":
   t.check(button.size.x<240 and t.visible_text(button).contains("6 × 3 伤害"),"BASIC UI multi-hit short strike fits its action slot")
   await t.capture("ui-basic-attack-forms.png")
  var old_energy=ui.game.state.energy
  t.check(await t.click("attack",{"type":type,"form":1,"enemy":ui.selected_enemy}) and ui.game.state.energy==old_energy-c.cost,"BASIC UI selected form submits once")
  if type=="kick":
   t.check(ui.game.state.enemies.all(func(enemy):return enemy.hp==enemy.max_hp-5),"BASIC UI sweep damages all enemies")
   t.check(await t.click("attack",{"type":type,"form":1,"enemy":ui.selected_enemy}),"BASIC UI sweep can immediately repeat")
 ui.restart(42);ui.game.state.energy=0;ui.render();await t.frames()
 var fire=ui.find_child("BasicAttack_fireball",true,false)
 t.check(fire.disabled and t.visible_text(fire).contains("1能量"),"FIREBALL UI first use shows one energy and blocks at zero")
 ui.game.state.energy=1;ui.render();await t.frames()
 var mana=ui.view.mana
 t.check(await t.click("attack",{"type":"fireball","enemy":ui.selected_enemy}) and ui.view.energy==0 and ui.view.mana==mana-10,"FIREBALL UI first click pays one energy and mana once")
 fire=ui.find_child("BasicAttack_fireball",true,false)
 t.check(not fire.disabled and t.visible_text(fire).contains("0能量"),"FIREBALL UI later use switches to zero energy")
 t.check(await t.click("attack",{"type":"fireball","enemy":ui.selected_enemy}) and ui.view.energy==0 and ui.view.mana==mana-20,"FIREBALL UI second click works at zero energy")
 var button=ui.find_child("BasicAttack_heavy",true,false)
 var point=button.get_global_rect().get_center()
 await t.mouse_button(point,MOUSE_BUTTON_RIGHT,true);await t.mouse_button(point,MOUSE_BUTTON_RIGHT,false)
 t.check(ui.attack_forms.get("heavy",0)==1 and ui.find_child("BasicAttack_heavy",true,false).disabled,"BASIC UI disabled attack can still change form")
 await third_kick(t)

static func third_kick(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames()
 for form in [1,2]:
  var point=ui.find_child("BasicAttack_kick",true,false).get_global_rect().get_center()
  await t.mouse_button(point,MOUSE_BUTTON_RIGHT,true);await t.mouse_button(point,MOUSE_BUTTON_RIGHT,false)
  t.check(ui.attack_forms.kick==form,"KICK UI cycles through all three formal alternatives")
 var button=ui.find_child("BasicAttack_kick",true,false)
 t.check(button.drag_payload.form==2 and t.visible_text(button).contains("站着踢") and ui.find_child("BasicAttackDetail_kick",true,false).text=="8 伤害","KICK UI third form carries standing name, damage and drag identity")
 t.check(await t.click("attack",{"type":"kick","form":2,"enemy":ui.selected_enemy}) and ui.view.energy==2,"KICK UI standing ordinary kick pays one energy")
 t.check(await t.click("posture",{"dest":"sit","wall":false}),"KICK UI changes to actual sitting posture")
 button=ui.find_child("BasicAttack_kick",true,false)
 t.check(ui.attack_forms.kick==2 and t.visible_text(button).contains("坐着踢") and ui.find_child("BasicAttackDetail_kick",true,false).text=="6 伤害","KICK UI current third form automatically updates after posture change")
 t.check(await t.click("attack",{"type":"kick","form":2,"enemy":ui.selected_enemy}),"KICK UI ordinary sitting kick remains reusable after standing kick")
 ui.game.add_fixture("ankle",4);ui.game.add_fixture("foot",4);ui.render();await t.frames()
 t.check(ui.find_child("BasicAttackDetail_kick",true,false).text=="2.4 伤害","KICK UI level-three sitting preview reads shared damage")
 for slot in ["thigh","calf","toes"]: ui.game.add_fixture(slot,4)
 ui.render();await t.frames()
 t.check(ui.find_child("BasicAttack_kick",true,false).disabled and t.visible_text(ui.find_child("BasicAttack_kick",true,false)).contains("4级"),"KICK UI full leg restraint shows specific disabled reason")
 var before=ui.game.export_snapshot()
 for form in [0,1,2]:
  var point=ui.find_child("BasicAttack_kick",true,false).get_global_rect().get_center()
  await t.mouse_button(point,MOUSE_BUTTON_RIGHT,true);await t.mouse_button(point,MOUSE_BUTTON_RIGHT,false)
  t.check(ui.attack_forms.kick==form and ui.game.export_snapshot()==before,"KICK UI disabled forms still cycle without spending resources or resetting cooldown")

static func justice_opening(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game.state.energy=6
 ui.game.state.enemies[0].hp=100;ui.game.state.enemies[0].max_hp=100
 ui.render();await t.frames()
 var button=ui.find_child("BasicAttack_kick",true,false)
 t.check(not button.disabled and ui.game.state.round==1 and not t.visible_text(button).contains("打断"),"JUSTICE UI first-round action is available without innate interrupt")
 t.check(await t.click("attack",{"type":"kick","form":0,"enemy":ui.selected_enemy}) and ui.game.state.kick_last==-10,"JUSTICE UI actual click does not start cooldown")
 t.check(await t.click("attack",{"type":"kick","form":0,"enemy":ui.selected_enemy}) and ui.view.energy==2,"JUSTICE UI can immediately repeat")
 ui.game.add_fixture("thigh",4);ui.render();await t.frames()
 t.check(ui.find_child("BasicAttack_kick",true,false).disabled and t.visible_text(ui.find_child("BasicAttack_kick",true,false)).contains("双腿活动自由"),"JUSTICE UI leg restriction explains the real reason")
static func bound_kick(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game.state.posture="sit";ui.game.add_fixture("ankle",4);ui.render();await t.frames()
 var c=ui.actions.find("attack",{"type":"kick","form":0,"enemy":ui.selected_enemy})
 t.check(c.valid and c.payload.fall and c.detail.contains("3回合冷却") and c.risk.contains("躺下") and ui.find_child("BasicAttackDetail_kick",true,false).text.contains("3 伤害"),"BOUND KICK UI shows reduced seated damage shared cooldown and fall cost")
 t.check(await t.click("attack",{"type":"kick","form":0,"enemy":ui.selected_enemy}) and ui.view.posture=="lie","BOUND KICK UI actual seated kick leaves the player lying down")
 t.check(await t.click("posture",{"dest":"sit","wall":false}),"BOUND KICK UI recovers through actual posture action")
 c=ui.actions.find("attack",{"type":"kick","form":0,"enemy":ui.selected_enemy})
 t.check(not c.valid and c.reason.contains("冷却") and ui.find_child("BasicAttack_kick",true,false).disabled and ui.view.statuses.any(func(s):return s.id=="kick_cooldown" and s.detail.contains("共用冷却")),"BOUND KICK UI displays cooldown in both actual action and status after sitting up")

static func infusion(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game._discard_end();ui.game.state.energy=6
 var card=preload("res://tests/curse_cases.gd").give(ui.game,"infusion")
 ui.card_faces[card.uid]=false;ui.render();await t.frames()
 var face=ui.card_buttons[card.uid];var c=ui.actions.find("card",{"uid":card.uid,"free":false})
 t.check(face.rarity=="rare" and t.visible_text(face).contains("腿部体术") and c.cost==2 and c.mana==10,"INFUSION UI rare bound face shows leg preparation and actual prices")
 var before=ui.game.export_snapshot();await t.flip(card.uid)
 face=ui.card_buttons[card.uid];c=ui.actions.find("card",{"uid":card.uid,"free":true})
 t.check(ui.game.state==before and t.visible_text(face).contains("手部体术") and c.cost==1 and c.mana==20,"INFUSION UI flip shows hand preparation without spending resources")
 await t.capture("ui-infusion.png")
 await preload("res://tests/curse_ui_cases.gd").click_card(t,card.uid);await t.frames()
 t.check("infusion_free" in ui.game.state.card_buffs and ui.view.energy==5 and ui.view.mana==80 and t.visible_text(ui.find_child("BasicAttack_strike",true,false)).contains("打断"),"INFUSION UI actual card use adds interruption to the matching action preview")
 t.check(await t.click("attack",{"type":"strike","form":0,"enemy":ui.selected_enemy}) and "infusion_free" not in ui.game.state.card_buffs and ui.game.state.enemies[0].intent.delayed,"INFUSION UI actual attack consumes the buff and delays intent")
