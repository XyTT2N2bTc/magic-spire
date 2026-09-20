extends RefCounted
# This controller chooses existing commands; payment and effects remain in dispatch.
static func mode(g) -> Dictionary:
 return g.Relics.FIRST_TURN_MODES[int(g.state.relic_counters.get("doubao",0))]

static func _eligible(g, selected_mode: int) -> bool:
 return g.state.combat.active and g.state.phase in g.RelicEffects.COMBAT_PHASES and (selected_mode!=0 or g.state.phase!="prepare")

static func begin_turn(g) -> void:
 if "doubao" not in g.state.relics or not _eligible(g,int(g.state.relic_counters.get("doubao",0))): return
 var seen=g.state.combat.get("first_turn_control",{}).get("seen",[]).duplicate()
 if g.state.phase in seen: return
 seen.append(g.state.phase)
 g.state.combat.first_turn_control={"seen":seen,"phase":g.state.phase,"tick":g.state.tick,"mode":int(g.state.relic_counters.get("doubao",0)),"stage":0,"remaining":-1,"cursor":0,"attempted":[]}
 if g.state.combat.first_turn_control.mode==1:
  g.state.energy=0
  g.state.combat.first_turn_control.stage=6
  g._emit("event","大肥鱼吃掉了你的白饭")

static func active(g) -> bool:
 var d=g.state.combat.get("first_turn_control",{})
 return not d.is_empty() and d.mode==0 and _eligible(g,d.mode) and d.phase==g.state.phase and d.tick==g.state.tick and d.stage<6

static func toggle(g) -> void:
 g.state.relic_counters.doubao=1-int(g.state.relic_counters.get("doubao",0))
 g._emit("event","切换为"+mode(g).name+"。")

static func commit(g, c: Dictionary) -> void:
 if not c.has("control_next"): return
 g.state.combat.first_turn_control=c.control_next.duplicate(true)

# Each preview reconstructs its own random stream. Only a committed command advances it.
static func _roll(g, d: Dictionary, count: int) -> int:
 var rng=RandomNumberGenerator.new()
 rng.seed=hash("first_turn_control:%s:%s:%s:%s" % [g.state.seed,g.state.combat.serial,d.tick,d.cursor])
 d.cursor+=1
 return rng.randi_range(0,count-1)

static func _pick(g, d: Dictionary, choices: Array) -> Dictionary:
 return {} if choices.is_empty() else choices[_roll(g,d,choices.size())]

static func _tag(c: Dictionary, d: Dictionary) -> Dictionary:
 var result=c.duplicate(true)
 result.automated=true
 result.control_next=d.duplicate(true)
 return result

static func select(g, candidates: Array) -> Array:
 if not active(g): return candidates
 var d=g.state.combat.first_turn_control.duplicate(true)
 var valid=candidates.filter(func(c):return c.valid)
 var selected={}
 # Resolve consequences of the last committed action before proceeding to its next stage.
 var pending=valid.filter(func(c):return c.payload.kind in ["chain","retain","retain_skip"])
 if not pending.is_empty(): selected=_pick(g,d,pending)
 elif g.state.overloaded: d.stage=5
 while selected.is_empty() and d.stage<5:
  match d.stage:
   0:
    d.stage=1
    if _roll(g,d,2)==1: selected=_pick(g,d,valid.filter(func(c):return c.payload.kind=="posture"))
   1:
    d.stage=2
    if _roll(g,d,2)==1: selected=_pick(g,d,valid.filter(func(c):return c.payload.kind=="wall_move" and c.payload.direction=="toward"))
   2:
    if d.remaining<0: d.remaining=1+_roll(g,d,2)
    selected=_pick(g,d,valid.filter(func(c):return c.payload.kind=="attack"))
    d.remaining-=1
    if selected.is_empty() or d.remaining<=0: d.stage=3;d.remaining=-1
   3:
    if g.state.energy>0:
     for card in g.state.hand:
      var token=card.uid+":"+str(card.get("draw_serial",0))
      if token in d.attempted: continue
      d.attempted.append(token)
      var choices=valid.filter(func(c):return c.payload.kind in ["card","prison"] and c.payload.get("uid","")==card.uid)
      if choices.is_empty(): continue
      var faces=[]
      for c in choices:
       var face=c.payload.get("free",false)
       if face not in faces: faces.append(face)
      var face=faces[_roll(g,d,faces.size())]
      selected=_pick(g,d,choices.filter(func(c):return c.payload.get("free",false)==face))
      break
    if selected.is_empty(): d.stage=4
   4:
    if d.remaining<0: d.remaining=_roll(g,d,4)
    if d.remaining>0:
     selected=_pick(g,d,valid.filter(func(c):return c.payload.kind=="flask"))
     d.remaining-=1
    if selected.is_empty() or d.remaining<=0: d.stage=5
 if selected.is_empty():
  selected=_pick(g,d,valid.filter(func(c):return c.payload.kind=="end"))
  d.stage=6
 if selected.is_empty():
  # A card can forbid ending the turn. Return control without bypassing that restriction.
  var finish=[]
  g._candidate(finish,{"kind":"relic_control_done"},"接管结束",{"kind":"relic.control_done","args":{}},0,0,"","","relic")
  selected=finish[0]
 var result=[_tag(selected,d)]
 # Keep the full layout available to the presenter, but only the chosen command can commit.
 for c in candidates:
  if c.id==selected.id: continue
  var blocked=c.duplicate(true)
  blocked.valid=false;blocked.reason="豆包接管中"
  result.append(blocked)
 return result

static func view(g, candidates: Array) -> Dictionary:
 var d=g.state.combat.get("first_turn_control",{})
 if not d.is_empty() and d.mode==1 and g.state.combat.active and d.phase==g.state.phase and d.tick==g.state.tick:
  return {"name":"大肥鱼吃掉了你的白饭","locked":false,"candidate":{},"key":"%s:%s" % [d.phase,d.tick]}
 if not active(g): return {}
 var next=candidates.filter(func(c):return c.get("automated",false))
 return {"name":"豆包接管中","locked":true,"candidate":next[0] if not next.is_empty() else {},"key":"%s:%s" % [d.phase,d.tick]}

static func validate(g) -> String:
 if not g.state.combat.has("first_turn_control"): return ""
 var d=g.state.combat.first_turn_control
 if not g.Snapshot.fields(d,"seen:z phase:s tick:i mode:i stage:i remaining:i cursor:i attempted:z"): return "首回合接管记录不完整。"
 if "doubao" not in g.state.relics or d.phase not in g.RelicEffects.COMBAT_PHASES or d.phase not in d.seen or d.seen.any(func(p):return p not in g.RelicEffects.COMBAT_PHASES or d.seen.count(p)!=1): return "首回合接管阶段不正确。"
 if d.mode<0 or d.mode>=g.Relics.FIRST_TURN_MODES.size() or d.stage<0 or d.stage>6 or d.remaining< -1 or d.remaining>3 or d.tick<0 or d.tick>g.state.tick or d.cursor<0: return "首回合接管进度不正确。"
 if d.mode==1 and d.stage!=6: return "首回合接管进度不正确。"
 if d.attempted.any(func(token):return d.attempted.count(token)!=1): return "首回合接管手牌记录不正确。"
 return ""
