extends RefCounted

static func run(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames()
 var ids=preload("res://tests/lewd_relic_cases.gd").IDS
 ui.game.state.relics=ids.duplicate();ui.game.state.relics.append("desire_cube_pro_max")
 ui.game.state.pressure=50;ui.game.state.charge=0
 for enemy in ui.game.state.enemies: enemy.intent.delayed=true
 ui.render();await t.frames()
 for id in ids:
  var icon=ui.find_child("RelicShortcut_"+id,true,false)
  t.check(icon!=null and preload("res://ui/relic_icon.gd").ART.has(id),"LEWD RELICS UI dedicated icon: "+id)
  await t.move_mouse(icon.get_global_rect().get_center());await t.frames()
  t.check(ui.term_popup!=null and t.visible_text(ui.term_popup).contains(ui.game.Relics.TYPES[id].detail),"LEWD RELICS UI tooltip shows current rules: "+id)
 t.check(await t.click("calm") and ui.view.pressure.value==42,"LEWD RELICS UI calm loss triggers hairpin and earrings once")
 var enemy=ui.game.state.enemies[0]
 t.check(await t.click("attack",{"type":"fireball","enemy":enemy.id,"form":0}) and ui.view.pressure.value==49,"LEWD RELICS UI guaranteed glove spell grants five plus two pressure")
 t.check(await t.click("end") and ui.game.state.charge==1,"LEWD RELICS UI next turn grants bodysuit charge")
 ui.localization.set_locale("en_US")
 for id in ids:
  var source=ui.game.Relics.TYPES[id]
  t.check(ui.localization.display(source.name)!=source.name and ui.localization.display(source.detail)!=source.detail,"LEWD RELICS UI name and rules have English copies: "+id)
 ui.localization.set_locale("zh_CN")
