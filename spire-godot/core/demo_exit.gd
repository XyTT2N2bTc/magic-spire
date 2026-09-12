extends RefCounted

const HEALTH=[1.0,1.5,2.0]

static func health_multiplier(state: Dictionary) -> float:
 return HEALTH[state.demo_cycle]

static func at_exit(g) -> bool:
 return not g.state.practice and g.state.phase=="cleared" and g.room_data(g.state.room).get("kind","")=="exit"

static func candidates(g, out: Array) -> void:
 if not at_exit(g) or g.state.demo_finished: return
 g._candidate(out,{"kind":"demo_end"},"结束并返回菜单","结束本次游玩。",0,0,"","","demo_exit")
 if g.state.demo_cycle<2:
  g._candidate(out,{"kind":"demo_continue"},"继续游玩","保留卡组、遗物和成长，开启全新塔路。怪物基础生命×%s；解除可解除的装备并补满魔力。" % g.number(HEALTH[g.state.demo_cycle+1]),0,0,"","","demo_exit")

static func continue_run(g) -> void:
 for target in g.action_targets():
  if g.cursed_eyes(target) or g.cursed_plate(target): continue
  target.locked=false
  g._apply_manual_release(target,0.0)
 g._cleanup()
 g.CaptureBind.clear_bind(g)
 g.Cards.end_powers(g);g.Cards.purge_temporary(g)
 g.RelicEffects.end_combat(g)
 g.state.demo_cycle+=1
 g._restart_tower(true)
 g.state.encounter=0;g.state.reward_count=0;g.state.reward_claimed={};g.state.battle_relic_drop=""
 g.state.boss_relic_options=[]
 g.state.mana=g.state.mana_max
 g.state.pending_retain=false;g.state.retain_left=0;g.state.retain_draw_after=0;g.Cards.cancel_chain(g)
 g._clear_charge();g.state.temporary_mana=0.0;g.state.next_energy=0;g.state.sure_cast=false;g.state.weakness_turns=0
 g._reset_piles()
 g._emit("event","新的塔路已展开。第%s阶段：怪物基础生命×%s，可解除的装备已解除，魔力已补满。" % [["一","二","三"][g.state.demo_cycle],g.number(health_multiplier(g.state))],{"demo_cycle":g.state.demo_cycle})

static func validate(state: Dictionary) -> String:
 if not state.get("demo_cycle") is int or state.demo_cycle<0 or state.demo_cycle>2 or not state.get("demo_finished") is bool: return "游玩阶段记录不正确。"
 if state.demo_finished and (state.get("phase")!="cleared" or state.get("practice")!=false or state.get("room")!="exit"): return "已结束的游戏必须位于出口。"
 if state.get("practice",false) and state.demo_cycle!=0: return "练习不能进入后续阶段。"
 return ""
