extends RefCounted
const Impact=preload("res://ui/impact_feedback.gd")

# Named checks for the committed-feedback layer (ui/impact_feedback.gd): the pleasure
# filter, the three-family border (white deep breath / yellow charge-next energy / blue
# mana family) and the impact shake. Trigger derivation, the fixed family priority,
# merge, the fade clock, real pointer clicks through the running effect and the idle
# state are all covered here; rule-level receipt evidence lives in pressure_cases.gd.
# The `*_pixels` checks measure the effects on real window frames (root texture) so a
# parameter change that stops being visible at the lowest intensity turns them red.
# The shake probe displaces the content and compares the displaced peak against the
# settled frame (never the pre-commit frame, which carries the submission's own frame
# changes) and asserts the settled frame is pixel-identical to the pre-effect one.

# Pixel acceptance thresholds for the real-window frames. "Differing" counts a pixel
# whose strongest channel changed by 1/255 or more, so anti-aliased edges count once.
const PIXEL_SHAKE_MAX_DELTA=24
const PIXEL_SHAKE_SHARE=0.02
const PIXEL_FILTER_MEAN_DELTA=3.0
const PIXEL_FILTER_MAX_DELTA=12

static func run(t) -> void:
 await committed_triggers(t)
 await layer_contract(t)
 await teardown(t)
 await merged_receipt(t)
 await real_attack(t)
 await real_pressure(t)
 await real_border(t)
 await passthrough(t)
 await idle(t)
 await pixel_checks(t)

static func committed_triggers(t) -> void:
 var rising=[{"field":"pressure","label":"快感","before":70.0,"after":90.0,"source":""}]
 t.check(Impact.pressure_rise(rising)==20.0 and Impact.will_play(rising,{"kind":"card"}),"IMPACT FILTER committed pressure rise asks for the filter")
 t.check(Impact.pressure_rise([])==0.0 and not Impact.will_play([],{"kind":"posture","dest":"sit"}),"IMPACT NO-OP a selection-only submission with an empty receipt asks for nothing")
 var falling=[{"field":"pressure","label":"快感","before":90.0,"after":82.0,"source":""}]
 t.check(Impact.pressure_rise(falling)==0.0 and not Impact.will_play(falling,{"kind":"end"}),"IMPACT FILTER falling pressure never asks for the filter")
 var merged=[{"field":"pressure","before":10.0,"after":13.0},{"field":"pressure","before":13.0,"after":17.0}]
 t.check(Impact.pressure_rise(merged)==7.0,"IMPACT FILTER one submission merges every rise into a single trigger")
 var mixed=[{"field":"pressure","before":10.0,"after":13.0},{"field":"pressure","before":13.0,"after":5.0},{"field":"mana","before":100.0,"after":90.0}]
 t.check(Impact.pressure_rise(mixed)==0.0,"IMPACT FILTER a submission whose net pressure falls drives no filter")
 t.check(is_equal_approx(Impact.filter_peak(0.5,0.0),0.265),"IMPACT FILTER peak follows the committed pressure ratio")
 t.check(is_equal_approx(Impact.filter_peak(0.0,0.4),0.2),"IMPACT FILTER a large rise at low pressure keeps the rise floor")
 t.check(is_equal_approx(Impact.filter_peak(1.0,0.0),Impact.FEEDBACK_FILTER_ALPHA_MAX) and is_equal_approx(Impact.FEEDBACK_FILTER_ALPHA_MAX,0.38),"IMPACT FILTER peak is capped at 0.38")
 t.check(is_equal_approx(Impact.filter_peak(0.0,0.0),Impact.FEEDBACK_FILTER_ALPHA_MIN) and is_equal_approx(Impact.FEEDBACK_FILTER_ALPHA_MIN,0.14),"IMPACT FILTER the lowest intensity sits on the 0.14 alpha floor")
 t.check(is_equal_approx(Impact.filter_peak(1.0,1.0),0.5),"IMPACT FILTER the rise floor may exceed the ratio cap on a full maximum rise")
 t.check(is_equal_approx(Impact.filter_fade(0.0),Impact.FEEDBACK_FILTER_FADE_MIN) and is_equal_approx(Impact.filter_fade(1.0),Impact.FEEDBACK_FILTER_FADE_MAX) and is_equal_approx(Impact.filter_fade(0.2),0.24),"IMPACT FILTER fade stays inside 0.12-0.40s")
 t.check(Impact.border_kind_of([{"field":"charge","before":0,"after":2}],{"kind":"end"})=="charge","IMPACT BORDER a charge rise lights the yellow border")
 t.check(Impact.border_kind_of([{"field":"next_energy","before":0,"after":1}],{"kind":"end"})=="charge","IMPACT BORDER a deferred-energy rise lights the same yellow border")
 t.check(Impact.border_kind_of([],{"kind":"status_toggle","status":"charge","enabled":true})=="charge","IMPACT BORDER the charge-all toggle lights the border from the committed payload alone")
 t.check(Impact.border_kind_of([{"field":"pressure","before":90.0,"after":70.0}],{"kind":"calm"})=="calm","IMPACT BORDER a deep breath lights the white border")
 t.check(Impact.border_kind_of([{"field":"mana","before":10,"after":14}],{"kind":"end"})=="mana" and Impact.border_kind_of([{"field":"temporary_mana","before":0,"after":4}],{"kind":"end"})=="mana" and Impact.border_kind_of([{"field":"witch_focus","before":0,"after":2}],{"kind":"end"})=="mana","IMPACT BORDER the mana / reserve-mana / focus family lights the blue border")
 t.check(Impact.border_kind_of([{"field":"mana","before":10,"after":4}],{"kind":"end"})=="" and Impact.border_kind_of([{"field":"witch_focus","before":3,"after":0}],{"kind":"end"})=="" and Impact.border_kind_of([{"field":"next_energy","before":1,"after":0}],{"kind":"end"})=="","IMPACT BORDER a net fall of any family lights nothing")
 t.check(Impact.border_kind_of([],{"kind":"end"})=="" and Impact.border_kind_of([],{"kind":"posture","dest":"sit"})=="","IMPACT BORDER ordinary actions and selection clicks light nothing")
 # One border per submission: several families rising together resolve by the fixed
 # priority calm(white) > charge/next_energy(yellow) > mana family(blue).
 t.check(Impact.border_kind_of([{"field":"next_energy","before":0,"after":1},{"field":"mana","before":0,"after":5},{"field":"witch_focus","before":0,"after":1}],{"kind":"end"})=="charge","IMPACT BORDER one submission shows a single border and yellow outranks the blue family")
 t.check(Impact.border_kind_of([{"field":"mana","before":0,"after":5},{"field":"temporary_mana","before":0,"after":2}],{"kind":"calm"})=="calm","IMPACT BORDER the deep-breath payload outranks every field family in the same submission")
 t.check(Impact.will_play([{"field":"witch_focus","before":0,"after":1}],{"kind":"end"}),"IMPACT BORDER a lone focus rise still asks for the layer")
 var Palette=preload("res://ui/visual_theme.gd")
 t.check(Impact.border_row("calm").color==Palette.BORDER_CALM and Impact.border_row("charge").color==Palette.BORDER_CHARGE and Impact.border_row("mana").color==Palette.BORDER_MANA,"IMPACT BORDER each family reads its colour from the palette token, never an inline hex")
 t.check(Palette.BORDER_CALM!=Palette.BORDER_CHARGE and Palette.BORDER_CHARGE!=Palette.BORDER_MANA and Palette.BORDER_MANA!=Palette.BORDER_CALM,"IMPACT BORDER the three family tokens are distinct colours")
 t.check(float(Impact.border_row("charge").fade)<float(Impact.border_row("calm").fade) and float(Impact.border_row("charge").alpha)>float(Impact.border_row("calm").alpha),"IMPACT BORDER charge is shorter and firmer than the deep breath")
 # Real payload shapes: card payloads carry `mode` and only damage cards carry
 # `preview.damage`, while basic attacks carry a flat `damage`. The modes below come
 # from the registered specs, so a synthetic payload cannot drift from card data.
 var Rules=preload("res://data/card_rules.gd")
 t.check(Rules.face_mode("strain",false)=="strain" and Rules.face_mode("slip",false)=="slip" and Rules.face_mode("magic_slip",false)=="magic_slip" and Rules.damage_type("magic_hand",false)=="","IMPACT SHAKE the modes under test come from the registered card specs")
 var g=preload("res://tests/game_fixture.gd").new(42)
 g.add_fixture("wrist",4,10)
 var real=g.candidates().filter(func(row):return String(row.payload.get("kind",""))=="card" and row.payload.has("preview") and float(row.payload.preview.get("damage",0.0))>0.0)
 t.check(not real.is_empty(),"IMPACT SHAKE the fixture exposes a real damage-card candidate with preview damage")
 if not real.is_empty():
  t.check(real[0].payload.has("mode") and Impact.damage_of(real[0].payload)==float(real[0].payload.preview.damage) and int(Impact.shake_spec(real[0].payload).get("pulses",0))>0,"IMPACT SHAKE the committed candidate payload shape is what the layer reads")
 var strain={"kind":"card","type":"strain","slot":"wrist","target":"fixture","free":false,"mode":Rules.face_mode("strain",false),"preview":{"damage":6.0}}
 var slip={"kind":"card","type":"slip","slot":"wrist","target":"fixture","free":false,"mode":Rules.face_mode("slip",false),"preview":{"damage":6.0}}
 var magic_slip={"kind":"card","type":"magic_slip","slot":"wrist","target":"fixture","free":false,"mode":Rules.face_mode("magic_slip",false),"preview":{"damage":5.0}}
 var attack={"kind":"attack","type":"strike","form":0,"damage":8.0}
 t.check(int(Impact.shake_spec(attack).get("pulses",0))==1 and int(Impact.shake_spec(strain).get("pulses",0))==2 and int(Impact.shake_spec(slip).get("pulses",0))==1,"IMPACT SHAKE a basic attack is one pulse, strain two, slip one")
 t.check(float(Impact.shake_spec(slip).get("step",0.0))>float(Impact.shake_spec(strain).get("step",0.0)),"IMPACT SHAKE the single slip pulse is longer than a strain pulse")
 t.check(int(Impact.shake_spec(magic_slip).get("pulses",0))==1 and is_equal_approx(float(Impact.shake_spec(magic_slip).get("step",0.0)),float(Impact.shake_spec(slip).get("step",0.0))),"IMPACT SHAKE the real magic slip card shares the single longer slip pulse")
 t.check(Impact.shake_spec({"kind":"card","type":"magic_hand","slot":"wrist","target":"fixture","free":false,"mode":Rules.face_mode("magic_hand",false),"after":3.0}).is_empty() and Impact.shake_spec({"kind":"card","type":"strain","mode":Rules.face_mode("strain",false),"preview":{"damage":0.0}}).is_empty(),"IMPACT NO-OP the lower-mode card and a zero-damage hit shake nothing")
 t.check(Impact.damage_of({"preview":{"damage":4.0}})==4.0 and Impact.damage_of(attack)==8.0,"IMPACT SHAKE damage is read from the committed card preview and the flat attack amount")
 t.check(is_equal_approx(Impact.shake_amplitude_for(0.0),Impact.FEEDBACK_SHAKE_MIN_PX) and is_equal_approx(Impact.shake_amplitude_for(999.0),Impact.FEEDBACK_SHAKE_MAX_PX) and Impact.FEEDBACK_SHAKE_MIN_PX>=4.0,"IMPACT SHAKE amplitude stays in the 4-9px perceptibility band for every damage")

static func layer_contract(t) -> void:
 var ui=t.ui
 var layer=Impact.new()
 layer.host=ui
 ui.add_child(layer)
 await t.frames()
 var snapshot={"pressure":{"value":6.5,"maximum":130.0}}
 layer.play([{"field":"pressure","before":0.0,"after":10.0}],{"kind":"end"},snapshot)
 var first_ends=layer.filter.ends
 t.check(layer.visible and layer.filter.active() and is_equal_approx(layer.filter_bands.modulate.a,layer.filter.peak),"IMPACT FILTER a committed rise draws the vignette at its peak")
 t.check(is_equal_approx(layer.filter.peak,0.1525) and is_equal_approx(layer.filter.fade,Impact.filter_fade(10.0/130.0)),"IMPACT FILTER low pressure follows the ratio formula and its own fade length")
 t.check(layer.filter_bands.color==ui.OVERLOAD_COLOR and layer.border_bands.color==Impact.border_row("calm").color,"IMPACT FILTER the filter keeps the climax tint while the border wears its family token")
 t.check(layer.border_kind=="" and not layer.border.active() and layer.shake_pulses==0,"IMPACT NO-OP a pressure-only submission starts nothing else")
 layer.play([{"field":"pressure","before":0.0,"after":60.0}],{"kind":"end"},snapshot)
 t.check(is_equal_approx(layer.filter.peak,Impact.filter_peak(0.05,60.0/130.0)),"IMPACT FILTER a rise during the fade refreshes the intensity")
 t.check(absf(layer.filter.ends-first_ends)<=20.0 and is_equal_approx(layer.filter.fade,Impact.filter_fade(10.0/130.0)) and layer.filter.starts==2,"IMPACT FILTER the refreshed rise re-arms the envelope but keeps its clock and length")
 layer.play([],{"kind":"calm"},snapshot)
 t.check(layer.filter.active() and layer.border.active() and layer.border_kind=="calm","IMPACT BORDER the border and the filter coexist in one frame without cancelling each other")
 t.check(is_equal_approx(layer.border.peak,float(Impact.border_row("calm").alpha)) and is_equal_approx(layer.border.fade,float(Impact.border_row("calm").fade)) and layer.border_bands.color==Impact.border_row("calm").color,"IMPACT BORDER a deep breath uses the long soft white parameters")
 var calm_ends=layer.border.ends
 layer.play([],{"kind":"status_toggle","status":"charge","enabled":true},snapshot)
 t.check(layer.border_kind=="charge" and is_equal_approx(layer.border.peak,float(Impact.border_row("charge").alpha)) and layer.border_bands.color==Impact.border_row("charge").color,"IMPACT BORDER the charge toggle raises the border to the firm yellow peak")
 t.check(absf(layer.border.ends-calm_ends)<=20.0 and is_equal_approx(layer.border.fade,float(Impact.border_row("calm").fade)),"IMPACT BORDER a new border trigger keeps the running fade clock instead of restarting")
 layer.play([{"field":"witch_focus","before":0,"after":1}],{"kind":"end"},snapshot)
 t.check(layer.border_kind=="mana" and layer.border_bands.color==Impact.border_row("mana").color,"IMPACT BORDER a focus rise retints the running border blue")
 layer.play([],{"kind":"card","type":"strain","mode":"strain","preview":{"damage":6.0}},snapshot)
 t.check(layer.shake_pulses==2 and is_equal_approx(layer.shake_step,Impact.FEEDBACK_SHAKE_STRAIN_STEP) and layer.shake_amplitude>0.0,"IMPACT SHAKE a strain payload double-pulses inside the same layer")
 t.check(layer.border.active() and layer.visible,"IMPACT SHAKE the shake joins the running effects instead of cancelling them")
 # A second shake while the first pulse is still running merges into it: the recorded
 # origin must stay the first, pre-effect position and the swing must restart from that
 # origin, so two overlapping shakes never add their amplitudes together.
 await t.frames(1,false)
 var shake_origin=layer.shake_origin
 layer.play([],{"kind":"attack","type":"strike","form":0,"damage":8.0},snapshot)
 var merged_amplitude=Impact.shake_amplitude_for(8.0)
 t.check(layer.shake_origin==shake_origin and ui.layout.position==shake_origin,"IMPACT SHAKE a second shake keeps the first recorded origin and restarts from it")
 var merged_peak=0.0
 for i in range(90):
  await t.frames(1,false)
  merged_peak=maxf(merged_peak,absf(ui.layout.position.x-shake_origin.x))
  if layer.shake_pulses==0: break
 t.check(merged_peak>=merged_amplitude-0.5 and merged_peak<=merged_amplitude+0.5,"IMPACT SHAKE the merged shake reaches its own amplitude and never accumulates displacement: peak=%.2f amplitude=%.2f" % [merged_peak,merged_amplitude])
 await t.frames(60)
 t.check(layer.shake_pulses==0 and layer.shake_target==ui.layout and ui.layout.position==layer.shake_origin,"IMPACT SHAKE the pulse settles the content container back to its recorded origin")
 layer.queue_free()
 await t.frames()

static func teardown(t) -> void:
 # Freeing the layer mid-effect must not leave the content container displaced: the
 # tween dies with the node, so _exit_tree restores the recorded origin exactly.
 var ui=t.ui
 var layer=Impact.new()
 layer.host=ui
 ui.add_child(layer)
 await t.frames()
 var origin=ui.layout.position
 layer.play([],{"kind":"card","type":"strain","mode":"strain","preview":{"damage":6.0}},{"pressure":{"value":0.0,"maximum":130.0}})
 await t.frames(2,false)
 t.check(layer.shake_pulses>0 and ui.layout.position!=origin,"IMPACT SHAKE a running pulse displaces the container before teardown")
 layer.queue_free()
 await t.frames()
 t.check(ui.layout.position==origin,"IMPACT SHAKE tearing the layer down mid-effect restores the content container exactly")

static func merged_receipt(t) -> void:
 # The UI layer must merge a multi-event receipt itself: one submission, one envelope
 # arm, one fade clock, peak and fade taken from the summed rise.
 var ui=t.ui
 var layer=Impact.new()
 layer.host=ui
 ui.add_child(layer)
 await t.frames()
 var events=[{"field":"pressure","before":0.0,"after":25.0},{"field":"pressure","before":25.0,"after":65.0},{"field":"mana","before":100.0,"after":90.0}]
 layer.play(events,{"kind":"end"},{"pressure":{"value":0.0,"maximum":130.0}})
 t.check(float(layer.last_impact.get("rise",0.0))==65.0 and layer.filter.starts==1,"IMPACT FILTER one multi-event receipt arms the filter exactly once")
 t.check(is_equal_approx(layer.filter.peak,Impact.filter_peak(0.0,65.0/130.0)),"IMPACT FILTER the merged peak uses the summed rise of every receipt event")
 t.check(is_equal_approx(layer.filter.fade,Impact.filter_fade(65.0/130.0)) and absf(layer.filter.ends-float(Time.get_ticks_msec())-Impact.filter_fade(65.0/130.0)*1000.0)<=20.0,"IMPACT FILTER the merged submission starts one full fade and never restarts it")
 layer.queue_free()
 await t.frames()

static func real_attack(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames()
 var enemy=ui.view.enemies.filter(func(e):return not e.gone)[0]
 var strike=ui.actions.find("attack",{"type":"strike","form":0,"enemy":enemy.id})
 t.check(not strike.is_empty() and strike.valid,"IMPACT SHAKE the battle fixture exposes a real strike candidate")
 if strike.is_empty() or not strike.valid: return
 var energy=ui.view.energy
 var layout_origin=ui.layout.position
 await commit_click(t,strike)
 var layer=ui.impact_feedback
 t.check(ui.view.energy<energy and is_instance_valid(layer),"IMPACT SHAKE a real strike click commits")
 if not is_instance_valid(layer): return
 t.check(int(layer.last_impact.get("shake_pulses",0))==1 and is_equal_approx(float(layer.last_impact.get("shake_step",0.0)),Impact.FEEDBACK_SHAKE_ATTACK_STEP),"IMPACT SHAKE the committed strike plays exactly one pulse")
 t.check(float(layer.last_impact.get("shake_amplitude",0.0))>=Impact.FEEDBACK_SHAKE_MIN_PX and float(layer.last_impact.get("shake_amplitude",0.0))<=Impact.FEEDBACK_SHAKE_MAX_PX,"IMPACT SHAKE the pulse stays inside the pixel bound")
 # "The layout must not change" means the container returns to its recorded origin
 # exactly; the pulse itself has to move the visible content, so both directions are
 # asserted: displaced while running, byte-identical position after it settles.
 var observed=await watch_shake(t,layer,layout_origin)
 t.check(observed.moved and observed.peak_offset>0.0,"IMPACT SHAKE the committed strike displaces the content container during the pulse")
 t.check(observed.restored and ui.layout.position==layout_origin,"IMPACT SHAKE the content container is restored to its recorded origin exactly after the pulse")
 t.check(layer.last_impact.get("border_kind","")=="" and float(layer.last_impact.get("filter_peak",0.0))==0.0,"IMPACT NO-OP an attack with no pressure or charge change starts nothing else")
 t.check(not layer.is_processing(),"IMPACT IDLE the running effect is tween driven and owns no per-frame process")

static func real_pressure(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames()
 # Deterministic rise: one committed turn_end source, the same receipt path as play.
 ui.game.state.pressure_sources=[preload("res://tests/pressure_cases.gd").source("ui_rise","turn_end",8)]
 for enemy in ui.game.state.enemies: enemy.intent.delayed=true
 ui.render();await t.frames()
 var before=ui.view.pressure.value
 var end=ui.actions.find("flow",{"kind":"end"})
 t.check(not end.is_empty() and end.valid and ui.candidate_buttons.has(end.id),"IMPACT FILTER the real end-turn button is available")
 if not end.valid: return
 await press_candidate(t,end)
 var layer=ui.impact_feedback
 var after=ui.view.pressure.value
 t.check(after>before and is_instance_valid(layer) and float(layer.last_impact.get("filter_peak",0.0))>0.0,"IMPACT FILTER a real rising submission draws the filter")
 if not is_instance_valid(layer): return
 var ratio_rise=(after-before)/ui.view.pressure.maximum
 t.check(is_equal_approx(float(layer.last_impact.get("filter_peak",0.0)),Impact.filter_peak(after/ui.view.pressure.maximum,ratio_rise)) and is_equal_approx(float(layer.last_impact.get("filter_fade",0.0)),Impact.filter_fade(ratio_rise)),"IMPACT FILTER the committed peak and fade equal the receipt formula")
 t.check(layer.last_impact.get("border_kind","")=="" and int(layer.last_impact.get("shake_pulses",0))==0,"IMPACT NO-OP a cooling end turn starts no border and no shake")
 t.check(layer.mouse_filter==Control.MOUSE_FILTER_IGNORE,"IMPACT INPUT the full-screen layer ignores the mouse in every state")
 await t.frames(60)
 ui.game.state.pressure_sources=[]
 ui.render();await t.frames()
 var target=ui.view.enemies.filter(func(e):return not e.gone)[0].id
 var spell=ui.actions.find("attack",{"type":"fireball","form":0,"enemy":target})
 t.check(not spell.is_empty() and spell.valid,"IMPACT FILTER the battle fixture exposes a real mana-paying spell")
 if spell.is_empty() or not spell.valid: return
 var mana=ui.view.mana
 await press_candidate(t,spell)
 layer=ui.impact_feedback
 t.check(ui.view.mana<mana and is_instance_valid(layer) and int(layer.last_impact.get("shake_pulses",0))==1,"IMPACT FILTER a mana-paying spell shakes like any attack")
 t.check(is_instance_valid(layer) and float(layer.last_impact.get("filter_peak",0.0))==0.0 and layer.last_impact.get("border_kind","")=="","IMPACT FILTER a mana receipt without a pressure rise never draws the filter")

static func real_border(t) -> void:
 var ui=t.ui
 await t.start_practice("Practice_pressure")
 var belt=ui.game.equipment_at("wrist")[0].id
 var uid=ui.view.hand.filter(func(c):return c.type=="strain")[0].uid
 var card=ui.actions.find("card",{"uid":uid,"slot":"wrist","target":belt})
 t.check(not card.is_empty() and card.valid,"IMPACT SHAKE the pressure practice exposes a real strain drag")
 if card.is_empty() or not card.valid: return
 await t.start_drag(uid,"wrist")
 await t.release_target(await t.reveal_drop_target(card.id))
 var layer=ui.impact_feedback
 t.check(is_instance_valid(layer) and int(layer.last_impact.get("shake_pulses",0))==2 and is_equal_approx(float(layer.last_impact.get("shake_step",0.0)),Impact.FEEDBACK_SHAKE_STRAIN_STEP),"IMPACT SHAKE a real strain drag double-pulses")
 t.check(is_instance_valid(layer) and float(layer.last_impact.get("filter_peak",0.0))>0.0,"IMPACT FILTER the same strain commit raises pressure and asks for the filter")
 await t.frames(60)
 var before=ui.view.pressure.value
 await t.click("calm")
 layer=ui.impact_feedback
 t.check(is_instance_valid(layer) and ui.view.pressure.value<before and layer.last_impact.get("border_kind","")=="calm","IMPACT BORDER a real deep breath lights the border")
 if not is_instance_valid(layer): return
 t.check(is_equal_approx(float(layer.last_impact.get("border_peak",0.0)),float(Impact.border_row("calm").alpha)) and is_equal_approx(float(layer.last_impact.get("border_fade",0.0)),float(Impact.border_row("calm").fade)) and layer.border_bands.color==Impact.border_row("calm").color,"IMPACT BORDER the deep breath border uses the long soft white parameters")
 t.check(float(layer.last_impact.get("filter_peak",0.0))==0.0,"IMPACT FILTER a deep breath lowers pressure and never draws the filter")
 await t.frames(60)
 ui.game.state.charge=1
 ui.render();await t.frames()
 var toggle=ui.view.candidates.filter(func(c):return c.payload.kind=="status_toggle" and c.valid)
 t.check(not toggle.is_empty(),"IMPACT BORDER the charge-all toggle is a real candidate")
 if toggle.is_empty(): return
 var charge_before=ui.game.state.charge
 ui._submit(toggle[0])
 layer=ui.impact_feedback
 t.check(is_instance_valid(layer) and ui.game.state.charge==charge_before and layer.last_impact.get("border_kind","")=="charge","IMPACT BORDER the committed toggle changes no amount and still lights the border")
 if not is_instance_valid(layer): return
 t.check(is_equal_approx(float(layer.last_impact.get("border_peak",0.0)),float(Impact.border_row("charge").alpha)) and is_equal_approx(float(layer.last_impact.get("border_fade",0.0)),float(Impact.border_row("charge").fade)) and layer.border_bands.color==Impact.border_row("charge").color,"IMPACT BORDER the charge toggle uses the short firm yellow parameters")
 t.check(float(layer.last_impact.get("filter_peak",0.0))==0.0 and int(layer.last_impact.get("shake_pulses",0))==0,"IMPACT NO-OP the payload-only toggle starts no filter and no shake")

static func passthrough(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames()
 # The deep-breath border runs for the longest committed window here, so the real
 # pointer press below provably happens inside a running effect.
 ui.game.state.pressure=40
 ui.render();await t.frames()
 var end=ui.actions.find("flow",{"kind":"end"})
 t.check(not end.is_empty() and end.valid and ui.candidate_buttons.has(end.id),"IMPACT INPUT the real end-turn button is available")
 if not end.valid: return
 var point=ui.candidate_buttons[end.id].get_global_rect().get_center()
 await t.move_mouse(point)
 await t.click("calm")
 var layer=ui.impact_feedback
 t.check(is_instance_valid(layer) and layer.visible and layer.last_impact.get("border_kind","")=="calm" and layer.border.active(),"IMPACT INPUT a real deep breath starts the running border")
 if not is_instance_valid(layer): return
 t.check(layer.get_global_rect().has_point(point) and layer.mouse_filter==Control.MOUSE_FILTER_IGNORE and layer.bands_host.mouse_filter==Control.MOUSE_FILTER_IGNORE,"IMPACT INPUT the full-screen layer covers the clicked control and ignores the mouse")
 var round_before=ui.view.round
 var press_at=Time.get_ticks_msec()
 await t.mouse_button(point,MOUSE_BUTTON_LEFT,true)
 t.check(press_at<layer.border.ends,"IMPACT INPUT the real pointer press happens inside the running effect")
 await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)
 t.check(ui.view.round>round_before,"IMPACT INPUT a real pointer press inside the running effect still reaches its control")

static func idle(t) -> void:
 var layer=t.ui.impact_feedback
 t.check(is_instance_valid(layer),"IMPACT IDLE the committed submission path owns a live layer to inspect")
 if not is_instance_valid(layer): return
 await t.frames(80)
 t.check(not layer.visible,"IMPACT IDLE the layer hides itself once every effect is done")
 t.check(not layer.is_processing() and not layer.filter.active() and not layer.border.active() and layer.shake_pulses==0,"IMPACT IDLE no resident process, no running fade and no pending pulse")
 t.check(layer.filter.tween==null or not layer.filter.tween.is_valid(),"IMPACT IDLE the finished fade keeps no live tween")

# ---------------------------------------------------------------------------
# Pixel visibility checks. Every probe captures real window frames with
# root.get_texture().get_image() and asserts measured deltas; the numbers are
# printed so the check log carries them even when the probe passes.
# ---------------------------------------------------------------------------

static func pixel_checks(t) -> void:
 await filter_pixels(t)
 await border_pixels(t)
 await shake_pixels(t)
 await restore_pixels(t)

static func filter_pixels(t) -> void:
 # Lowest intended intensity: a small rise at low pressure sits on the alpha floor.
 var layer=await settled_layer(t)
 var baseline=await grab(t)
 layer.play([{"field":"pressure","label":"快感","before":0.0,"after":2.0}],{"kind":"end"},{"pressure":{"value":2.0,"maximum":130.0}})
 var peak=await grab(t)
 var expected=Impact.filter_peak(2.0/130.0,2.0/130.0)
 var stats=edge_band_stats(baseline,peak,band_pixels(baseline))
 report_pixels("FILTER floor",stats)
 t.check(is_equal_approx(float(layer.last_impact.get("filter_peak",0.0)),expected) and expected<=Impact.FEEDBACK_FILTER_ALPHA_MIN+0.01,"IMPACT FILTER PIXELS the probe is the lowest intended intensity (alpha floor %.3f)" % expected)
 t.check(stats.max>=PIXEL_FILTER_MAX_DELTA and stats.mean>=PIXEL_FILTER_MEAN_DELTA,"IMPACT FILTER PIXELS the floor filter is visible inside the edge band: mean=%.2f max=%d share=%.4f" % [stats.mean,stats.max,stats.share])
 layer.queue_free()
 await t.frames()

static func border_pixels(t) -> void:
 # One probe per border family at its only strength: the family is what the trigger
 # selects, so the weakest trigger of that family is the lowest intended intensity. The
 # calm probe carries the real deep-breath receipt shape (a next_energy rise) to prove
 # in the render path that calm outranks the yellow family. The blue family is probed
 # twice because both named sources must reach the blue token: the reserve mana of
 # 魔法预备 (temporary_mana) and the 精神集中 stack gain (witch_focus).
 await border_probe(t,"BORDER calm",[{"field":"next_energy","before":0,"after":1}],{"kind":"calm"},"calm")
 await border_probe(t,"BORDER charge",[{"field":"charge","before":0,"after":1}],{"kind":"end"},"charge")
 await border_probe(t,"BORDER mana reserve",[{"field":"temporary_mana","before":0,"after":4}],{"kind":"end"},"mana")
 await border_probe(t,"BORDER mana focus",[{"field":"witch_focus","before":0,"after":2}],{"kind":"end"},"mana")

## One border family on a settled frame: the effect must fire its family, wear the
## family palette token and be visible inside the edge band of the real window frame.
static func border_probe(t, label: String, events: Array, payload: Dictionary, kind: String) -> void:
 var layer=await settled_layer(t)
 var baseline=await grab(t)
 layer.play(events,payload,{"pressure":{"value":40.0,"maximum":130.0}})
 var peak=await grab(t)
 var stats=edge_band_stats(baseline,peak,band_pixels(baseline))
 report_pixels(label,stats)
 var row=Impact.border_row(kind)
 t.check(layer.last_impact.get("border_kind","")==kind and layer.border_bands.color==row.color and is_equal_approx(float(layer.last_impact.get("border_peak",0.0)),float(row.alpha)),"IMPACT BORDER PIXELS %s fires its family and wears its palette token" % label)
 t.check(stats.max>=PIXEL_FILTER_MAX_DELTA and stats.mean>=PIXEL_FILTER_MEAN_DELTA,"IMPACT BORDER PIXELS %s is visible inside the edge band: mean=%.2f max=%d share=%.4f" % [label,stats.mean,stats.max,stats.share])
 layer.queue_free()
 await t.frames()

static func shake_pixels(t) -> void:
 var ui=t.ui
 ui.restart(42);await t.frames()
 freeze_decoration(t)
 var enemy=ui.view.enemies.filter(func(e):return not e.gone)[0]
 var strike=ui.actions.find("attack",{"type":"strike","form":0,"enemy":enemy.id})
 t.check(not strike.is_empty() and strike.valid,"IMPACT SHAKE PIXELS the battle fixture exposes a real strike candidate")
 var button=ui.candidate_buttons.get(strike.get("id","")) if not strike.is_empty() else null
 t.check(button!=null,"IMPACT SHAKE PIXELS the strike candidate has a real button")
 if button==null: return
 var origin=ui.layout.position
 var point=button.get_global_rect().get_center()
 await t.move_mouse(point)
 t.root.push_input(pointer_event(point,true),true)
 await t.frames(1,false)
 t.root.push_input(pointer_event(point,false),true)
 var observed=await watch_shake(t,ui.impact_feedback,origin)
 report_offset("SHAKE content",observed.peak_offset)
 t.check(observed.moved and observed.peak_offset>0.0,"IMPACT SHAKE PIXELS the committed strike displaces the content container: peak=%.1fpx" % observed.peak_offset)
 t.check(observed.restored,"IMPACT SHAKE PIXELS the content container is restored to the recorded origin exactly")
 if observed.peak_image==null: return
 # Isolated pair: the displaced peak frame and the settled frame below share the same
 # committed state (energy, HP and candidate rows are already updated in both), so the
 # submission's own frame changes cancel out and the remaining difference is the
 # content displacement. Authoritative evidence stays `peak_offset` plus this exact
 # restore; the share below is auxiliary magnitude, never proof of displacement.
 var restored=await grab(t)
 var band=band_pixels(restored)
 var content=Rect2i(band,band,restored.get_width()-2*band,restored.get_height()-2*band)
 var stats=region_stats(observed.peak_image,restored,content)
 report_pixels("SHAKE displaced vs restored",stats)
 t.check(stats.max>=PIXEL_SHAKE_MAX_DELTA,"IMPACT SHAKE PIXELS the content area visibly moves between the displaced and the settled frame: mean=%.2f max=%d share=%.4f" % [stats.mean,stats.max,stats.share])

static func restore_pixels(t) -> void:
 # A real commit also changes energy, HP and the candidate row, so the pre-effect
 # frame is only directly comparable while the shake is the only change. This probe
 # runs the real play() entry on a settled state, so the settled frame is asserted
 # pixel-identical to the pre-effect frame; the displaced-peak vs settled comparison
 # below is therefore the isolated displacement criterion (the real-click probe above
 # reports the same pair while the submission's own frame changes have cancelled out).
 var layer=await settled_layer(t)
 var origin=t.ui.layout.position
 var baseline=await grab(t)
 layer.play([],{"kind":"card","type":"strain","mode":"strain","preview":{"damage":6.0}},{"pressure":{"value":0.0,"maximum":130.0}})
 var observed=await watch_shake(t,layer,origin)
 report_offset("SHAKE restore",observed.peak_offset)
 t.check(observed.moved and observed.peak_offset>0.0,"IMPACT SHAKE PIXELS the direct pulse displaces the content container: peak=%.1fpx" % observed.peak_offset)
 t.check(observed.restored and t.ui.layout.position==origin,"IMPACT SHAKE PIXELS the direct pulse restores the recorded origin exactly")
 var after=await grab(t)
 var restored_stats=region_stats(baseline,after,Rect2i(Vector2i.ZERO,baseline.get_size()))
 report_pixels("SHAKE restore",restored_stats)
 t.check(restored_stats.max==0 and restored_stats.share==0.0,"IMPACT SHAKE PIXELS the post-effect frame is pixel-identical to the pre-effect frame: max=%d share=%.4f" % [restored_stats.max,restored_stats.share])
 if observed.peak_image!=null:
  var band=band_pixels(baseline)
  var content=Rect2i(band,band,baseline.get_width()-2*band,baseline.get_height()-2*band)
  var displaced=region_stats(observed.peak_image,after,content)
  report_pixels("SHAKE displaced vs restored isolated",displaced)
  t.check(displaced.max>=PIXEL_SHAKE_MAX_DELTA and displaced.share>=PIXEL_SHAKE_SHARE,"IMPACT SHAKE PIXELS the isolated displaced frame differs from the pixel-identical settled frame: mean=%.2f max=%d share=%.4f (need max>=%d share>=%.2f)" % [displaced.mean,displaced.max,displaced.share,PIXEL_SHAKE_MAX_DELTA,PIXEL_SHAKE_SHARE])
 layer.queue_free()
 await t.frames()

## A fresh committed state with every animation settled and one inert layer wired to
## it: two frames that differ only by the effect under test are the clean baseline.
static func settled_layer(t):
 var ui=t.ui
 ui.restart(42)
 await t.frames(4)
 freeze_decoration(t)
 await t.frames(2)
 var layer=Impact.new()
 layer.host=ui
 ui.add_child(layer)
 await t.frames()
 return layer

static func freeze_decoration(t) -> void:
 # The gallery dust animates at 30 fps; pixel probes need frames that differ only by
 # the effect under test. Decoration only, no rule meaning.
 var dust=t.ui.layout.find_child("AmbientDust",true,false)
 if dust!=null: dust.hide()

static func grab(t) -> Image:
 await RenderingServer.frame_post_draw
 return t.root.get_texture().get_image()

## Edge band thickness the overlay draws into, in window pixels: the same fraction of
## the half short side the layer uses for FEEDBACK_EDGE_EXTENT.
static func band_pixels(image: Image) -> int:
 return maxi(4,int(minf(float(image.get_width()),float(image.get_height()))*0.5*Impact.FEEDBACK_EDGE_EXTENT))

static func report_pixels(label: String, stats: Dictionary) -> void:
 print("PIXEL %s: mean=%.3f max=%d share=%.4f pixels=%d" % [label,stats.mean,stats.max,stats.share,stats.pixels])

## Observed displacement of the content container, in window pixels, so the shake
## amplitude is part of the check log even when the probe passes.
static func report_offset(label: String, offset: float) -> void:
 print("PIXEL %s: peak_offset=%.1fpx" % [label,offset])

static func pointer_event(point: Vector2, pressed: bool) -> InputEventMouseButton:
 var event=InputEventMouseButton.new()
 event.position=point
 event.global_position=point
 event.button_index=MOUSE_BUTTON_LEFT
 event.pressed=pressed
 event.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0
 return event

## Real pointer click that returns in the commit frame: press_candidate waits two
## frames and can return after a short pulse already settled.
static func commit_click(t, candidate: Dictionary) -> void:
 var button=t.ui.candidate_buttons.get(candidate.id)
 if button==null: return
 var point=button.get_global_rect().get_center()
 await t.move_mouse(point)
 t.root.push_input(pointer_event(point,true),true)
 await t.frames(1,false)
 t.root.push_input(pointer_event(point,false),true)

## Observe the displaced content container until the pulse settles: whether it left the
## origin, the peak offset and the frame drawn at that offset, and whether the final
## position equals the recorded origin exactly.
static func watch_shake(t, layer, origin: Vector2, max_frames: int=120) -> Dictionary:
 var moved=false
 var peak_offset=0.0
 var peak_image=null
 for i in range(max_frames):
  await RenderingServer.frame_post_draw
  var offset=(t.ui.layout.position-origin).length()
  if offset>0.0: moved=true
  if peak_image==null or offset>peak_offset:
   peak_offset=offset
   peak_image=t.root.get_texture().get_image()
  if not is_instance_valid(layer) or layer.shake_pulses==0: break
 return {"moved":moved,"restored":t.ui.layout.position==origin,"peak_offset":peak_offset,"peak_image":peak_image}

## Per-pixel statistics of two window frames inside `rect`: mean and max per-channel
## delta on the 0-255 scale plus the share of pixels with any changed channel.
static func region_stats(a: Image, b: Image, rect: Rect2i) -> Dictionary:
 var clipped=rect.intersection(Rect2i(Vector2i.ZERO,a.get_size()))
 if clipped.size.x<=0 or clipped.size.y<=0: return {"mean":0.0,"max":0,"share":0.0,"pixels":0}
 var left=a.get_region(clipped)
 var right=b.get_region(clipped)
 if left.get_format()!=Image.FORMAT_RGBA8: left.convert(Image.FORMAT_RGBA8)
 if right.get_format()!=Image.FORMAT_RGBA8: right.convert(Image.FORMAT_RGBA8)
 var pa=left.get_data()
 var pb=right.get_data()
 var pixels=clipped.size.x*clipped.size.y
 var sum=0
 var maximum=0
 var changed=0
 var index=0
 while index<pa.size():
  var dr=absi(int(pa[index])-int(pb[index]))
  var dg=absi(int(pa[index+1])-int(pb[index+1]))
  var db=absi(int(pa[index+2])-int(pb[index+2]))
  var delta=maxi(dr,maxi(dg,db))
  if delta>0: changed+=1
  if delta>maximum: maximum=delta
  sum+=dr+dg+db
  index+=4
 return {"mean":float(sum)/(3.0*float(pixels)),"max":maximum,"share":float(changed)/float(pixels),"pixels":pixels}

## The four edge strips the overlay band covers, without double counting the corners.
static func edge_band_stats(a: Image, b: Image, band: int) -> Dictionary:
 var size=a.get_size()
 var strips=[Rect2i(0,0,size.x,band),Rect2i(0,size.y-band,size.x,band),Rect2i(0,band,band,size.y-2*band),Rect2i(size.x-band,band,band,size.y-2*band)]
 var pixels=0
 var sum=0.0
 var maximum=0
 var changed=0.0
 for strip in strips:
  var stats=region_stats(a,b,strip)
  pixels+=int(stats.pixels)
  sum+=float(stats.mean)*3.0*float(stats.pixels)
  maximum=maxi(maximum,int(stats.max))
  changed+=float(stats.share)*float(stats.pixels)
 return {"mean":sum/(3.0*float(pixels)),"max":maximum,"share":changed/float(pixels),"pixels":pixels}

static func press_candidate(t, candidate: Dictionary) -> void:
 # Real pointer click on the committed candidate button: the effect layer must never
 # swallow it, so the checks below observe the commit, not only the visible node.
 var button=t.ui.candidate_buttons.get(candidate.id)
 t.check(button!=null,"IMPACT INPUT candidate button exists for a real click: "+String(candidate.payload.get("kind","")))
 if button==null: return
 var point=button.get_global_rect().get_center()
 await t.move_mouse(point)
 await t.mouse_button(point,MOUSE_BUTTON_LEFT,true)
 await t.mouse_button(point,MOUSE_BUTTON_LEFT,false)
