extends RefCounted

# Accepted stages, save labels and heading templates have a single source.
const DEFINITIONS={
 "departure":{"name":"出发前","caption":"第0层 · 开局选择"},
 "shop":{"name":"魔力商店","caption":"用魔力交易 · 随时可离开"},
 "treasure":{"name":"遗物宝箱","caption":"宝箱房 · 一次奖励"},
 "battle":{"name":"战斗","caption":"第{round}回合  ·  {order_label}"},
 "reward":{"name":"选择奖励","caption":"遭遇完成  ·  选择奖励"},
 "prepare":{"name":"战后整备","caption":"战后整备  ·  剩余{prepare_left}回合"},
 "rest":{"name":"休息","caption":"休息房 · 剩余{rest_left}回合"},
 "rest_choice":{"name":"休息前选择","caption":"选择增益后开始休息 · 最多{rest_left}回合"},
 "pack":{"name":"整理道具","caption":"整理随身道具"},
 "map":{"name":"选择路线","caption":"选择下一房间"},
 "travel":{"name":"房间移动","caption":"前往下一房间"},
 "event":{"name":"事件","caption":"事件选择 · 结果进入时固定"},
 "captured":{"name":"入狱结果","caption":"收押完成 · 安全等级{security}"},
 "prison":{"name":"牢房","caption":"牢房回合 · 安全等级{security}"},
 "inspection":{"name":"狱警巡视","caption":"狱警巡视 · 安全等级{security}"},
 "prison_end":{"name":"逃脱结束","caption":"安全等级5 · 本次逃脱失败"},
 "cleared":{"name":"阶段完成","caption":"当前阶段完成"}}

static func caption(state: Dictionary) -> String:
 var fields={"round":state.round,"order_label":"你先行动" if state.order=="first" else "敌人先行动","prepare_left":state.prepare_left,"rest_left":state.rest_left,"security":state.security}
 var phase=DEFINITIONS[state.phase].caption.format(fields)
 if state.phase=="reward" and state.get("room_event",{}).get("stage","")=="loot": phase="搜索完成 · 选择道具"
 if state.practice and state.phase=="cleared": phase="本次装备练习结束"
 elif state.practice and state.phase=="rest": phase="装备练习 · 剩余%d回合" % state.rest_left
 return phase
