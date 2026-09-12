extends AudioStreamPlayer

const TRACKS={"rain_love":"res://assets/audio/rain-love.ogg","mandarin_duck_play":"res://assets/audio/mandarin-duck-play-61s.ogg"}
const FADE_IN_SECONDS=0.65
const FADE_OUT_SECONDS=4.0
const REPLACE_FADE_SECONDS=0.6
var enabled=true
var track_id=""
var scope=""
var music_volume=0.2
var fade_gain=1.0:
 set(value):
  fade_gain=value
  volume_linear=music_volume*fade_gain
var fade: Tween
var ending=false
var pending={}

func _ready() -> void:
 name="CardMusic"
 max_polyphony=1
 finished.connect(_finish_transition)

func configure(allowed: bool, volume: float) -> void:
 enabled=allowed
 music_volume=clampf(volume,0.0,1.0)
 volume_linear=music_volume*fade_gain
 if not enabled and ending:
  stop_music();return
 stream_paused=not enabled
 if fade!=null and fade.is_valid():
  if enabled: fade.play()
  else: fade.pause()

func consume(events: Array, phase: String, home: bool=false) -> void:
 for event in events:
  if not home and event.phase==phase:
   play_track(event.track,event.phase,event.loop)

func play_track(id: String, phase: String, looping: bool) -> void:
 if not enabled or not TRACKS.has(id): return
 if id==track_id and phase==scope and stream!=null and not ending: return
 if not pending.is_empty() and pending.track==id and pending.phase==phase: return
 if stream!=null:
  pending={"track":id,"phase":phase,"loop":looping}
  _fade_out(REPLACE_FADE_SECONDS);return
 _start_track(id,phase,looping)

func _start_track(id: String, phase: String, looping: bool) -> void:
 # Duplicate loop metadata rather than mutating Godot's shared resource cache.
 var song=load(TRACKS[id]).duplicate() as AudioStreamOggVorbis
 song.loop=looping
 stop_music()
 stream=song;track_id=id;scope=phase
 stream_paused=false
 fade_gain=0.0
 play()
 _fade_to(1.0,FADE_IN_SECONDS)

func sync_phase(phase: String, home: bool=false) -> void:
 if home:
  stop_music();return
 var expected_scope=pending.get("phase",scope)
 if not expected_scope.is_empty() and expected_scope!=phase:
  pending.clear()
  _fade_out()

func _fade_to(target: float, seconds: float) -> void:
 if fade!=null: fade.kill()
 fade=create_tween()
 fade.tween_property(self,"fade_gain",target,seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _fade_out(seconds: float=FADE_OUT_SECONDS) -> void:
 if not enabled or stream==null:
  stop_music();return
 if ending: return
 ending=true
 _fade_to(0.0,seconds)
 fade.tween_callback(_finish_transition)

func _finish_transition() -> void:
 var next=pending.duplicate()
 stop_music()
 if enabled and not next.is_empty(): _start_track(next.track,next.phase,next.loop)

func stop_music() -> void:
 if fade!=null: fade.kill();fade=null
 pending.clear();ending=false
 stop()
 stream_paused=false
 stream=null;track_id="";scope=""
 fade_gain=1.0
