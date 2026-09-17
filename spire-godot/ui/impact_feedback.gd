extends Control

# Transient post-commit impacts: one full-screen pass-through layer for the three
# committed-feedback effects (pleasure filter, charge/deep-breath border, impact shake).
#
# Contract: inputs are the committed dispatch receipt (`resource_feedback`) and the
# committed payload plus the post-commit View. The layer never reads state.logs, never
# writes game state, candidates, saves or randomness, and it owns no rule decision.
# Invariants: no _process (one-shot tweens only, hidden when idle) and mouse_filter
# stays IGNORE on every node here, so ordinary clicks keep reaching the layout below.

# ---------------------------------------------------------------------------
# FEEDBACK_* parameter table: the single source of every effect value.
# ---------------------------------------------------------------------------
# Pleasure filter: a soft full-screen vignette. Peak follows the current pressure
# ratio, with a floor relative to this rise so a large gain at low pressure is
# still visible; the fade grows a little for large rises but stays short.
const FEEDBACK_FILTER_ALPHA_BASE=0.06
const FEEDBACK_FILTER_ALPHA_PER_RATIO=0.24
const FEEDBACK_FILTER_ALPHA_MIN=0.06
const FEEDBACK_FILTER_ALPHA_MAX=0.30
const FEEDBACK_FILTER_RISE_ALPHA_FLOOR=0.5
const FEEDBACK_FILTER_FADE_BASE=0.12
const FEEDBACK_FILTER_FADE_PER_RATIO=0.6
const FEEDBACK_FILTER_FADE_MIN=0.12
const FEEDBACK_FILTER_FADE_MAX=0.40
# Charge / deep-breath border. Color carries no meaning here, so the two sources are
# told apart by duration and strength: charge is a resource already loaded for the
# next strike and reads short and firm; a deep breath is a slow deliberate act and
# reads longer and softer.
const FEEDBACK_BORDER_CHARGE_ALPHA=0.50
const FEEDBACK_BORDER_CHARGE_FADE=0.22
const FEEDBACK_BORDER_CALM_ALPHA=0.30
const FEEDBACK_BORDER_CALM_FADE=0.60
# Border extent: the same 1-(d/dmax)^2 weight as the filter, but dmax is this
# fraction of the half short side, so the light stays on the four screen edges.
const FEEDBACK_BORDER_EXTENT=0.18
# Impact shake: amplitude and pulse count encode force; never color, never layout.
const FEEDBACK_SHAKE_BASE_PX=1.2
const FEEDBACK_SHAKE_PER_DAMAGE_PX=0.45
const FEEDBACK_SHAKE_MIN_PX=1.2
const FEEDBACK_SHAKE_MAX_PX=6.0
const FEEDBACK_SHAKE_ATTACK_PULSES=1
const FEEDBACK_SHAKE_STRAIN_PULSES=2
const FEEDBACK_SHAKE_SLIP_PULSES=1
const FEEDBACK_SHAKE_ATTACK_STEP=0.055
const FEEDBACK_SHAKE_STRAIN_STEP=0.06
const FEEDBACK_SHAKE_SLIP_STEP=0.12
# Geometry: band count and the weight below which a band is transparent enough to skip.
const FEEDBACK_VIGNETTE_BANDS=18
const FEEDBACK_BAND_WEIGHT_CUTOFF=0.04
const FEEDBACK_FALLBACK_COLOR=Color("ed82b9")
# Layering stays under every drawer, panel and float so nothing readable is tinted.
const FEEDBACK_Z_INDEX=218

var host
var filter_bands: Control
var border_bands: Control
var shake_host: Control
var filter: Fade
var border: Fade
var border_kind=""
var shake_amplitude=0.0
var shake_pulses=0
var shake_step=0.0
var shake_tween
# Last committed trigger set. Kept after the tweens end so callers and checks can
# read what one submission showed without racing the fade.
var last_impact={}

## Summed committed receipt deltas per field. Several changes inside one submission
## (for example two pressure sources) merge here, so one submission is one effect.
static func deltas(events: Array) -> Dictionary:
 var result={}
 for event in events:
  var field=String(event.get("field",""))
  if field=="": continue
  result[field]=float(result.get(field,0.0))+float(event.get("after",0.0))-float(event.get("before",0.0))
 return result

static func pressure_rise(events: Array) -> float:
 return maxf(0.0,float(deltas(events).get("pressure",0.0)))

## Peak and fade follow the committed pressure ratio, never a forecast.
static func filter_peak(ratio_now: float, ratio_rise: float) -> float:
 var peak=clampf(FEEDBACK_FILTER_ALPHA_BASE+FEEDBACK_FILTER_ALPHA_PER_RATIO*ratio_now,FEEDBACK_FILTER_ALPHA_MIN,FEEDBACK_FILTER_ALPHA_MAX)
 return maxf(peak,FEEDBACK_FILTER_RISE_ALPHA_FLOOR*ratio_rise)

static func filter_fade(ratio_rise: float) -> float:
 return clampf(FEEDBACK_FILTER_FADE_BASE+FEEDBACK_FILTER_FADE_PER_RATIO*ratio_rise,FEEDBACK_FILTER_FADE_MIN,FEEDBACK_FILTER_FADE_MAX)

# Damage already exists in the committed payload: damage-dealing cards carry
# preview.damage, basic attacks carry a flat damage amount.
static func damage_of(payload: Dictionary) -> float:
 if payload.has("preview"): return float(payload.preview.get("damage",0.0))
 return float(payload.get("damage",0.0))

## Shake shape per committed payload, empty when this action has no impact.
static func shake_spec(payload: Dictionary) -> Dictionary:
 var kind=String(payload.get("kind",""))
 if kind=="attack": return {"pulses":FEEDBACK_SHAKE_ATTACK_PULSES,"step":FEEDBACK_SHAKE_ATTACK_STEP,"damage":damage_of(payload)}
 if kind!="card": return {}
 var damage=damage_of(payload)
 if damage<=0.0: return {}
 var mode=String(payload.get("mode",""))
 if mode=="strain": return {"pulses":FEEDBACK_SHAKE_STRAIN_PULSES,"step":FEEDBACK_SHAKE_STRAIN_STEP,"damage":damage}
 if mode in ["slip","magic_slip"]: return {"pulses":FEEDBACK_SHAKE_SLIP_PULSES,"step":FEEDBACK_SHAKE_SLIP_STEP,"damage":damage}
 return {}

## Border source per committed submission: "charge", "calm" or "".
static func border_kind_of(events: Array, payload: Dictionary) -> String:
 if float(deltas(events).get("charge",0.0))>0.0: return "charge"
 var kind=String(payload.get("kind",""))
 # The right-click charge toggle only flips charge_all and changes no receipt field,
 # so the committed payload is the only evidence that charge was loaded.
 if kind=="status_toggle" and String(payload.get("status","")) in ["charge","charge_all"]: return "charge"
 if kind=="calm": return "calm"
 return ""

static func will_play(events: Array, payload: Dictionary) -> bool:
 return pressure_rise(events)>0.0 or border_kind_of(events,payload)!="" or not shake_spec(payload).is_empty()

static func shake_amplitude_for(damage: float) -> float:
 return clampf(FEEDBACK_SHAKE_BASE_PX+FEEDBACK_SHAKE_PER_DAMAGE_PX*damage,FEEDBACK_SHAKE_MIN_PX,FEEDBACK_SHAKE_MAX_PX)

func _ready() -> void:
 name="ImpactFeedback"
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 z_index=FEEDBACK_Z_INDEX
 set_process(false)
 var tint=FEEDBACK_FALLBACK_COLOR if host==null else host.OVERLOAD_COLOR
 shake_host=Control.new()
 shake_host.name="ImpactShakeHost"
 shake_host.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(shake_host)
 shake_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 filter_bands=Bands.new(1.0,tint,FEEDBACK_VIGNETTE_BANDS,FEEDBACK_BAND_WEIGHT_CUTOFF)
 border_bands=Bands.new(FEEDBACK_BORDER_EXTENT,tint,FEEDBACK_VIGNETTE_BANDS,FEEDBACK_BAND_WEIGHT_CUTOFF)
 shake_host.add_child(filter_bands)
 shake_host.add_child(border_bands)
 filter=Fade.new(filter_bands)
 border=Fade.new(border_bands)
 filter.finished=_effect_finished
 border.finished=_effect_finished
 hide()

## One committed submission enters here; a submission with nothing to show is a no-op.
func play(events: Array, payload: Dictionary, snapshot: Dictionary) -> void:
 if not will_play(events,payload): return
 show()
 set_process(false)
 var rise=pressure_rise(events)
 if rise>0.0: _play_filter(rise,snapshot)
 var kind=border_kind_of(events,payload)
 if kind!="": _play_border(kind)
 var shake=shake_spec(payload)
 if not shake.is_empty(): _play_shake(shake)
 last_impact={"rise":rise,"filter_peak":0.0 if rise<=0.0 else filter.peak,"filter_fade":0.0 if rise<=0.0 else filter.fade,
  "border_kind":kind,"border_peak":0.0 if kind=="" else border.peak,"border_fade":0.0 if kind=="" else border.fade,
  "shake_pulses":shake_pulses,"shake_step":shake_step,"shake_amplitude":shake_amplitude}

func _play_filter(rise: float, snapshot: Dictionary) -> void:
 var pressure=snapshot.get("pressure",{})
 var maximum=float(pressure.get("maximum",0.0))
 if maximum<=0.0: return
 var ratio_now=clampf(float(pressure.get("value",0.0))/maximum,0.0,1.0)
 var ratio_rise=rise/maximum
 # A rise arriving mid-fade only refreshes strength: the clock and the original fade
 # length stay, so repeated gains inside one turn never flash twice.
 if filter.active(): filter.refresh(filter_peak(ratio_now,ratio_rise))
 else: filter.start(filter_peak(ratio_now,ratio_rise),filter_fade(ratio_rise))

func _play_border(kind: String) -> void:
 border_kind=kind
 var peak=FEEDBACK_BORDER_CHARGE_ALPHA if kind=="charge" else FEEDBACK_BORDER_CALM_ALPHA
 if border.active(): border.refresh(peak)
 else: border.start(peak,FEEDBACK_BORDER_CHARGE_FADE if kind=="charge" else FEEDBACK_BORDER_CALM_FADE)

func _play_shake(spec: Dictionary) -> void:
 shake_amplitude=shake_amplitude_for(float(spec.get("damage",0.0)))
 shake_pulses=int(spec.get("pulses",1))
 shake_step=float(spec.get("step",FEEDBACK_SHAKE_ATTACK_STEP))
 if shake_tween!=null and shake_tween.is_valid(): shake_tween.kill()
 shake_host.position=Vector2.ZERO
 # Only this container moves; the layout and every committed control stay in place.
 shake_tween=create_tween()
 for index in range(shake_pulses):
  var amplitude=shake_amplitude*(1.0-0.35*float(index))
  shake_tween.tween_property(shake_host,"position:x",amplitude,shake_step).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
  shake_tween.tween_property(shake_host,"position:x",-amplitude,shake_step).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
 shake_tween.tween_property(shake_host,"position:x",0.0,shake_step).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
 shake_tween.tween_callback(_shake_finished)

func _shake_finished() -> void:
 shake_host.position=Vector2.ZERO
 shake_pulses=0
 shake_amplitude=0.0
 _hide_when_idle()

func _effect_finished() -> void:
 _hide_when_idle()

func _hide_when_idle() -> void:
 if filter.active() or border.active() or shake_pulses>0: return
 hide()
 set_process(false)

# ---------------------------------------------------------------------------
# Band rendering: concentric frames from the screen edge inward, each weighted by
# 1-(d/dmax)^2 over its own extent. Drawn once per effect because modulate carries the
# fade, so an idle layer never redraws.
# ---------------------------------------------------------------------------
class Bands extends Control:
 var reach_ratio=1.0
 var bands=1
 var color=Color("ed82b9")
 var weight_cutoff=0.04

 func _init(extent: float, tint: Color, count: int, cutoff: float) -> void:
  reach_ratio=extent
  color=tint
  bands=maxi(1,count)
  weight_cutoff=cutoff

 func _ready() -> void:
  mouse_filter=Control.MOUSE_FILTER_IGNORE
  set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  modulate.a=0.0
  resized.connect(queue_redraw)
  hide()

 func _draw() -> void:
  var half=maxf(1.0,minf(size.x,size.y)*0.5)
  var reach=maxf(2.0,half*clampf(reach_ratio,0.02,1.0))
  var width=reach/float(bands)
  for index in range(bands):
   var distance=width*(float(index)+0.5)
   var weight=1.0-pow(distance/reach,2.0)
   if weight<weight_cutoff: break
   var inset=width*float(index)
   draw_rect(Rect2(inset,inset,maxf(0.0,size.x-2.0*inset),maxf(0.0,size.y-2.0*inset)),Color(color,color.a*weight),false,width,true)

# ---------------------------------------------------------------------------
# Fade: peak-then-quadratic-decay envelope (alpha(t) = peak * (1-(t/fade)^2)) over one
# one-shot tween. `ends` is the wall clock of the running fade: a refresh raises the
# peak without moving it, which is what keeps a repeated trigger from restarting.
# ---------------------------------------------------------------------------
class Fade:
 var node: Control
 var peak=0.0
 var fade=0.0
 var ends=0.0
 var tween
 var finished=Callable()

 func _init(target: Control) -> void:
  node=target

 func active() -> bool:
  return ends>0.0 and Time.get_ticks_msec()<int(ends)

 func start(new_peak: float, new_fade: float) -> void:
  peak=new_peak
  fade=new_fade
  ends=float(Time.get_ticks_msec())+new_fade*1000.0
  run(new_fade)

 func refresh(new_peak: float) -> void:
  if new_peak<=peak: return
  peak=new_peak
  run(maxf((ends-float(Time.get_ticks_msec()))/1000.0,0.01))

 func run(duration: float) -> void:
  if tween!=null and tween.is_valid(): tween.kill()
  node.show()
  node.modulate.a=peak
  node.queue_redraw()
  tween=node.create_tween()
  tween.tween_property(node,"modulate:a",0.0,duration).from(peak).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
  tween.tween_callback(finish)

 func finish() -> void:
  node.hide()
  node.modulate.a=0.0
  peak=0.0
  ends=0.0
  if finished.is_valid(): finished.call()
