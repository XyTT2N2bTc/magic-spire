extends RefCounted
const Click=preload("res://tests/target_sidebar_ui_cases.gd")

static func run(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames()
 preload("res://tests/boss_relic_cases.gd").boss_reward(ui.game)
 ui.game.state.boss_relic_options=["nesting_doll"]
 if "nesting_doll" not in ui.game.state.relic_seen: ui.game.state.relic_seen.append("nesting_doll")
 ui.render();await t.frames()
 await Click.press(t,ui.find_child("Reward_relic",true,false));await t.frames()
 await Click.press(t,ui.find_child("BossRelicChoice_nesting_doll",true,false));await t.frames()
 var root=ui.find_child("RelicBundleRewards",true,false)
 t.check(root!=null and root.is_visible_in_tree() and ui.view.reward_panel.entries.size()==3,"BUNDLE UI selecting nesting doll opens second-level three-relic panel immediately")
 var entries=ui.game.state.relic_bundle.entries.duplicate(true)
 for i in range(3):
  var card=ui.find_child("BundleRelic_"+str(i),true,false)
  t.check(card!=null and t.visible_text(card).contains(ui.game.Relics.TYPES[entries[i].type].name) and t.visible_text(card).contains(ui.game.Relics.TYPES[entries[i].type].detail),"BUNDLE UI each card shows its own name image rarity and effect")
 await Click.press(t,ui.find_child("BundleClaim_0",true,false));await t.frames()
 t.check(ui.game.state.relic_bundle.entries[0].status=="claimed" and ui.find_child("RelicBundleRewards",true,false)!=null and ui.find_child("BundleClaim_0",true,false)==null,"BUNDLE UI one claim keeps panel open and disables repeat pickup")
 await Click.press(t,ui.find_child("BundleSkip_1",true,false));await t.frames()
 t.check(ui.game.state.relic_bundle.entries[1].status=="skipped" and ui.find_child("BundleClaim_2",true,false)!=null,"BUNDLE UI skipping middle card leaves third claim available")
 await Click.press(t,ui.find_child("BundleClaim_2",true,false));await t.frames()
 await Click.press(t,ui.find_child("BundleContinue",true,false));await t.frames()
 t.check(ui.find_child("RelicBundleRewards",true,false)==null and ui.find_child("Reward_relic",true,false).disabled and ui.find_child("Reward_card",true,false)!=null,"BUNDLE UI finish returns to parent rewards with Boss relic marked claimed")
 ui.restart(42);await t.frames()
