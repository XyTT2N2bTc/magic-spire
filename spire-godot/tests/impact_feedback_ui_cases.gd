extends RefCounted
const Impact=preload("res://ui/impact_feedback.gd")

# Named checks for the committed-feedback layer (ui/impact_feedback.gd): the pleasure
# filter, the charge/deep-breath border and the impact shake. Trigger derivation,
# merge, the fade clock, real pointer clicks through the running effect and the idle
# state are all covered here; rule-level receipt evidence lives in pressure_cases.gd.

static func run(t) -> void:
 await committed_triggers(t)
 await layer_contract(t)
 await real_attack(t)
 await real_pressure(t)
 await real_border(t)
 await passthrough(t)
 await idle(t)

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
 t.check(is_equal_approx(Impact.filter_peak(0.5,0.0),0.18),"IMPACT FILTER peak follows the committed pressure ratio")
 t.check(is_equal_approx(Impact.filter_peak(0.0,0.4),0.2),"IMPACT FILTER a large rise at low pressure keeps the rise floor")
 t.check(is_equal_approx(Impact.filter_peak(1.0,0.0),Impact.FEEDBACK_FILTER_ALPHA_MAX),"IMPACT FILTER peak is capped at 0.30")
 t.check(is_equal_approx(Impact.filter_peak(1.0,1.0),0.5),"IMPACT FILTER the rise floor may exceed the ratio cap on a full maximum rise")
 t.check(is_equal_approx(Impact.filter_fade(0.0),Impact.FEEDBACK_FILTER_FADE_MIN) and is_equal_approx(Impact.filter_fade(1.0),Impact.FEEDBACK_FILTER_FADE_MAX) and is_equal_approx(Impact.filter_fade(0.2),0.24),"IMPACT FILTER fade stays inside 0.12-0.40s")
 t.check(Impact.border_kind_of([{"field":"charge","before":0,"after":2}],{"kind":"end"})=="charge","IMPACT BORDER a charge rise lights the border")
 t.check(Impact.border_kind_of([],{"kind":"status_toggle","status":"charge","enabled":true})=="charge","IMPACT BORDER the charge-all toggle lights the border from the committed payload alone")
 t.check(Impact.border_kind_of([{"field":"pressure","before":90.0,"after":70.0}],{"kind":"calm"})=="calm","IMPACT BORDER a deep breath lights the border")
 t.check(Impact.border_kind_of([],{"kind":"end"})=="" and Impact.border_kind_of([],{"kind":"posture","dest":"sit"})=="","IMPACT BORDER ordinary actions and selection clicks light nothing")
 t.check(Impact.FEEDBACK_BORDER_CHARGE_FADE<Impact.FEEDBACK_BORDER_CALM_FADE and Impact.FEEDBACK_BORDER_CHARGE_ALPHA>Impact.FEEDBACK_BORDER_CALM_ALPHA,"IMPACT BORDER charge is shorter and firmer than the deep breath")
 var strain={"kind":"card","type":"strain","mode":"strain","preview":{"damage":6.0}}
 var slip={"kind":"card","type":"slip","mode":"slip","preview":{"damage":6.0}}
 var attack={"kind":"attack","type":"strike","form":0,"damage":8.0}
 t.check(int(Impact.shake_spec(attack).get("pulses",0))==1 and int(Impact.shake_spec(strain).get("pulses",0))==2 and int(Impact.shake_spec(slip).get("pulses",0))==1,"IMPACT SHAKE a basic attack is one pulse, strain two, slip one")
 t.check(float(Impact.shake_spec(slip).get("step",0.0))>float(Impact.shake_spec(strain).get("step",0.0)),"IMPACT SHAKE the single slip pulse is longer than a strain pulse")
 t.check(int(Impact.shake_spec({"kind":"card","type":"magic_hand","mode":"magic_slip","preview":{"damage":3.0}}).get("pulses",0))==1,"IMPACT SHAKE magic slip shares the single slip pulse")
 t.check(Impact.shake_spec({"kind":"card","type":"casting","mode":"lower","after":3.0}).is_empty() and Impact.shake_spec({"kind":"card","type":"strain","mode":"strain","preview":{"damage":0.0}}).is_empty(),"IMPACT NO-OP a durability-only card or a zero-damage hit shakes nothing")
 t.check(Impact.damage_of({"preview":{"damage":4.0}})==4.0 and Impact.damage_of({"damage":9.0})==9.0,"IMPACT SHAKE damage is read from the committed card preview and the flat attack amount")
 t.check(is_equal_approx(Impact.shake_amplitude_for(0.0),Impact.FEEDBACK_SHAKE_MIN_PX) and is_equal_approx(Impact.shake_amplitude_for(999.0),Impact.FEEDBACK_SHAKE_MAX_PX),"IMPACT SHAKE amplitude stays between the pixel bounds for every damage")

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
 t.check(is_equal_approx(layer.filter.peak,0.072) and is_equal_approx(layer.filter.fade,Impact.filter_fade(10.0/130.0)),"IMPACT FILTER low pressure follows the ratio formula and its own fade length")
 t.check(layer.filter_bands.color==ui.OVERLOAD_COLOR and layer.border_bands.color==ui.OVERLOAD_COLOR,"IMPACT FILTER both effects reuse the climax color and never a new palette entry")
 t.check(layer.border_kind=="" and not layer.border.active() and layer.shake_pulses==0,"IMPACT NO-OP a pressure-only submission starts nothing else")
 layer.play([{"field":"pressure","before":0.0,"after":60.0}],{"kind":"end"},snapshot)
 t.check(is_equal_approx(layer.filter.peak,Impact.filter_peak(0.05,60.0/130.0)),"IMPACT FILTER a rise during the fade refreshes the intensity")
 t.check(absf(layer.filter.ends-first_ends)<=20.0 and is_equal_approx(layer.filter.fade,Impact.filter_fade(10.0/130.0)),"IMPACT FILTER the refreshed rise keeps the running fade clock and length")
 layer.play([],{"kind":"calm"},snapshot)
 t.check(layer.filter.active() and layer.border.active() and layer.border_kind=="calm","IMPACT BORDER the border and the filter coexist in one frame without cancelling each other")
 t.check(is_equal_approx(layer.border.peak,Impact.FEEDBACK_BORDER_CALM_ALPHA) and is_equal_approx(layer.border.fade,Impact.FEEDBACK_BORDER_CALM_FADE),"IMPACT BORDER a deep breath uses the long soft parameters")
 var calm_ends=layer.border.ends
 layer.play([],{"kind":"status_toggle","status":"charge","enabled":true},snapshot)
 t.check(layer.border_kind=="charge" and is_equal_approx(layer.border.peak,Impact.FEEDBACK_BORDER_CHARGE_ALPHA),"IMPACT BORDER the charge toggle raises the border to the firm peak")
 t.check(absf(layer.border.ends-calm_ends)<=20.0 and is_equal_approx(layer.border.fade,Impact.FEEDBACK_BORDER_CALM_FADE),"IMPACT BORDER a new border trigger keeps the running fade clock instead of restarting")
 layer.play([],{"kind":"card","type":"strain","mode":"strain","preview":{"damage":6.0}},snapshot)
 t.check(layer.shake_pulses==2 and is_equal_approx(layer.shake_step,Impact.FEEDBACK_SHAKE_STRAIN_STEP) and layer.shake_amplitude>0.0,"IMPACT SHAKE a strain payload double-pulses inside the same layer")
 t.check(layer.border.active() and layer.visible,"IMPACT SHAKE the shake joins the running effects instead of cancelling them")
 await t.frames(60)
 t.check(layer.shake_pulses==0 and layer.shake_host.position==Vector2.ZERO,"IMPACT SHAKE the pulse settles the container back to its origin")
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
 await press_candidate(t,strike)
 var layer=ui.impact_feedback
 t.check(ui.view.energy<energy and is_instance_valid(layer),"IMPACT SHAKE a real strike click commits")
 if not is_instance_valid(layer): return
 t.check(int(layer.last_impact.get("shake_pulses",0))==1 and is_equal_approx(float(layer.last_impact.get("shake_step",0.0)),Impact.FEEDBACK_SHAKE_ATTACK_STEP),"IMPACT SHAKE the committed strike plays exactly one pulse")
 t.check(float(layer.last_impact.get("shake_amplitude",0.0))>=Impact.FEEDBACK_SHAKE_MIN_PX and float(layer.last_impact.get("shake_amplitude",0.0))<=Impact.FEEDBACK_SHAKE_MAX_PX and ui.layout.position==layout_origin,"IMPACT SHAKE the pulse stays inside the pixel bound and never moves the layout")
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
 t.check(is_equal_approx(float(layer.last_impact.get("border_peak",0.0)),Impact.FEEDBACK_BORDER_CALM_ALPHA) and is_equal_approx(float(layer.last_impact.get("border_fade",0.0)),Impact.FEEDBACK_BORDER_CALM_FADE),"IMPACT BORDER the deep breath border uses the long soft parameters")
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
 t.check(is_equal_approx(float(layer.last_impact.get("border_peak",0.0)),Impact.FEEDBACK_BORDER_CHARGE_ALPHA) and is_equal_approx(float(layer.last_impact.get("border_fade",0.0)),Impact.FEEDBACK_BORDER_CHARGE_FADE),"IMPACT BORDER the charge toggle uses the short firm parameters")
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
 t.check(layer.get_global_rect().has_point(point) and layer.mouse_filter==Control.MOUSE_FILTER_IGNORE and layer.shake_host.mouse_filter==Control.MOUSE_FILTER_IGNORE,"IMPACT INPUT the full-screen layer covers the clicked control and ignores the mouse")
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
