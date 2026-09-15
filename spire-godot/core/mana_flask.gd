extends RefCounted
const TRANSFER=10.0
const DEPOSITS=2

static func available(g) -> bool:
 return g.state.phase not in ["cleared","prison_end"]

static func withdrawal(g) -> Dictionary:
 var room=maxf(0,g.state.mana_max-g.state.mana)
 var limit=minf(TRANSFER,g.state.flask_mana)
 var drawn=minf(limit,room)
 if g.occupied("mouth"):
  drawn=limit
  # At most ten doses; ask the shared potion formula instead of duplicating its rounding.
  for step in range(1,ceili(limit)+1):
   var dose=minf(float(step),limit)
   if minf(dose,g.Consumables.potion_amount(g,dose))>=room:
    drawn=dose;break
 var restored=minf(minf(drawn,g.Consumables.potion_amount(g,drawn)),room)
 return {"drawn":drawn,"restored":restored}

static func candidates(g, out: Array, withdrawal_only: bool=false) -> void:
 if not available(g): return
 var amount=minf(TRANSFER,g.state.mana)
 var reason="本回合已存入2次。" if g.state.flask_deposits>=DEPOSITS else ("没有可存入的魔力。" if amount<=0 else "")
 if not withdrawal_only and g.state.phase!="rest_choice":
  var deposit_args={"amount":amount,"remaining":maxi(0,DEPOSITS-g.state.flask_deposits)}
  g._candidate(out,{"kind":"flask","op":"deposit"},"存入",{"kind":"mana_flask.deposit","args":deposit_args,"fallback":deposit_detail(g,deposit_args)},0,0,reason,"","flask")
 var result=withdrawal(g)
 reason=g.Consumables.reason(g,"mana_potion")
 if g.state.flask_mana<=0: reason="魔瓶中没有魔力。"
 elif reason=="" and result.restored<=0: reason="魔瓶余量不足以在嘴部减效后恢复魔力。"
 var withdraw_args={"drawn":result.drawn,"restored":result.restored}
 g._candidate(out,{"kind":"flask","op":"withdraw"},"取出",{"kind":"mana_flask.withdraw","args":withdraw_args,"fallback":withdraw_detail(g,withdraw_args)},0,0,reason,"","flask")

# R1（docs/ondemand-copy.md §11.5）：生产者提交「类别 + 参数」，正文仍留本模块，路由只做分派。
static func deposit_detail(g, args: Dictionary) -> String:
 return "存入%s魔力，本回合剩余%d次。" % [g.number(float(args.get("amount",0.0))),int(args.get("remaining",0))]

static func withdraw_detail(g, args: Dictionary) -> String:
 return "取出%s魔力，恢复自身%s魔力。" % [g.number(float(args.get("drawn",0.0))),g.number(float(args.get("restored",0.0)))]

static func execute(g, p: Dictionary) -> void:
 if p.op=="deposit":
  var amount=minf(TRANSFER,g.state.mana)
  g.state.mana-=amount;g.state.flask_mana+=amount;g.state.flask_deposits+=1
  g._emit("event","向贴身魔瓶存入%s魔力。" % g.number(amount))
 else:
  var result=withdrawal(g)
  g.state.flask_mana-=result.drawn;g.state.mana+=result.restored
  g._emit("event","从贴身魔瓶取出%s魔力，恢复%s魔力。" % [g.number(result.drawn),g.number(result.restored)])

static func view(g) -> Dictionary:
 return {"mana":g.state.flask_mana,"remaining":maxi(0,DEPOSITS-g.state.flask_deposits),"available":available(g)}
