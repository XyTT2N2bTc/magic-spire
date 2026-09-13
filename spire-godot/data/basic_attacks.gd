extends RefCounted
const TYPES={
 "strike":[{"name":"肘击","cost":1,"damage":8.0,"hits":1},{"name":"肘击 · 连击","cost":1,"damage":4.0,"hits":2}],
 "heavy":[{"name":"近身短打","cost":2,"damage":18.0,"hits":1},{"name":"近身短打 · 连击","cost":2,"damage":6.0,"hits":3}],
 "kick":[{"name":"正义飞踢","cost":2,"bound_cost":1,"seated_cost":1,"hits":1,"cooldown_turns":2},{"name":"横扫","cost":1,"damage":5.0,"hits":1,"all":true},{"name":"站着踢","cost":1,"hits":1,"postures":{"stand":{"name":"站着踢","damage":8.0,"max_level":0},"sit":{"name":"坐着踢","damage":6.0,"max_level":3}}}],
 "fireball":[{"name":"火球术","cost":0,"first_use_cost":1,"hits":1,"uses_per_turn":2}]}

static func energy_cost(g, type: String, form: int=0) -> int:
 var spec=TYPES[type][form]
 return int(spec.first_use_cost) if spec.has("first_use_cost") and not g.state.combat.attack_started.has(type) else int(spec.cost)

static func cost_description(type: String) -> String:
 var spec=TYPES[type][0]
 return ("每回合首发%d能量，之后%d能量。" % [spec.first_use_cost,spec.cost]+("施法失败不消耗次数。" if type=="fireball" else "")) if spec.has("first_use_cost") else ""

static func kick_cooldown(g) -> int:
 return maxi(0,g.state.kick_last+int(TYPES.kick[0].cooldown_turns)+1-g.state.round)

static func fireball_damage(g) -> float:
 var base=g.B.FIREBALL if g.hand_cast_reason()!="" or g.Cards.spell_power(g,"fireball").get("disable_gesture",false) else g.B.FIREBALL_ASSISTED
 return (base+g.state.spell_base_bonuses.get("fireball",0)+g.Cards.spell_power(g,"fireball").get("base_bonus",0.0))*g.Cards.damage_multiplier(g,"fireball")

static func usage(g, type: String) -> Dictionary:
 var base=int(TYPES[type][0].get("uses_per_turn",0))
 var limit=base+int(g.Cards.spell_power(g,type).get("extra_uses",0)) if base>0 else 0
 var used=int(g.state.combat.attack_uses.get(type,0))
 return {"limit":limit,"used":used,"remaining":maxi(0,limit-used)}
