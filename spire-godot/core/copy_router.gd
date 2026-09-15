extends RefCounted
# 文案路由（docs/ondemand-copy.md §11.2）：生产者提交「类别 + 参数」，路由按 kind 分派到已登记的 builder。
# 全 static；builder 本体留在各自模块（本文件不搬中文），路由只做分派与共享片段。
# 消费者侧不直连本模块：UI 只经 Game 的只读入口（live_card_text／candidate_detail）再由 §3 helper 取用。
# 失败三态（必须区分）：① 字符串直传原样返回，行为与迁移前逐字节相同；② descriptor 命中 builder 返回
# 其结果；③ 未知 kind／无效 builder／结果类型不符 → 在游戏实例上记一条 copy_router_failures（含 kind、
# 入口、失败点与涉事 descriptor；不进 state、不进 View、不进存档、不渲染、不做成计数器），并返回
# descriptor 自带的 fallback；没有 fallback 时返回空值并记录，绝不"空白且无记录"。
# 语言限制：GDScript 无异常捕获，builder 内部的引擎错误由套件当作失败处理（不再是静默空值）。
const Cards=preload("res://core/card_effects.gd")
const Catalog=preload("res://data/encyclopedia.gd")
const ManaFlask=preload("res://core/mana_flask.gd")
const DemoExit=preload("res://core/demo_exit.gd")

static var _table: Dictionary={}

# 类别 → builder(g, args)。卡面实时与静态两条实现、各模块的文案构建函数都在原地保留（§11.4 不合并两份实现）。
static func _builders() -> Dictionary:
 if _table.is_empty():
  _table["card.face"]=func(g,args): return Cards.text_entry(g,String(args.get("type","")),String(args.get("uid","")))
  _table["card.catalog"]=func(g,args): return Catalog.card(String(args.get("type","")))
  _table["card.target"]=Callable(Cards,"target_detail")
  _table["mana_flask.deposit"]=Callable(ManaFlask,"deposit_detail")
  _table["mana_flask.withdraw"]=Callable(ManaFlask,"withdraw_detail")
  _table["demo_exit.end"]=Callable(DemoExit,"end_detail")
  _table["demo_exit.continue"]=Callable(DemoExit,"continue_detail")
 return _table

# 可枚举的类别清单；未迁移的生产者走字符串直传通道，不在此列（§11.7 据此核对已收口范围）。
static func categories() -> Array:
 var names=_builders().keys()
 names.sort()
 return names

# 字符串类文案的唯一分派入口。
static func text(g, copy) -> String:
 var built=_render(g,copy,false)
 return built if built is String else ""

# 字典类文案（卡面条目）的唯一分派入口；与 text() 同一三态。
static func entry(g, copy) -> Dictionary:
 var built=_render(g,copy,true)
 return built if built is Dictionary else {}

# 共享片段：两面拼接（§11.3 实测的三处同一流程，只此一处实现）。
static func two_face(g, type: String) -> String:
 return Cards.face_text(g,type,false)+"\n"+Cards.face_text(g,type,true)

# 只读取用：该实例的失败记录（不渲染、不进存档、不做成计数器）。
static func failures(g) -> Array:
 return g.copy_router_failures

static func _render(g, copy, dictionary: bool) -> Variant:
 if copy is String: return copy
 var described=copy is Dictionary
 var kind=String(copy.get("kind","")) if described else ""
 var fallback=copy.get("fallback",{} if dictionary else "") if described else ({} if dictionary else "")
 var builder=_builders().get(kind,null)
 if builder is Callable and builder.is_valid():
  var result=builder.call(g,copy.get("args",{}) if described else {})
  var typed=result is Dictionary if dictionary else result is String
  if typed: return result
  _record(g,kind,"text" if not dictionary else "entry","result",copy)
  return fallback
 _record(g,kind,"text" if not dictionary else "entry","kind" if kind!="" else "shape",copy)
 return fallback

static func _record(g, kind: String, entry: String, stage: String, copy) -> void:
 if not (g is Object) or not ("copy_router_failures" in g): return
 g.copy_router_failures.append({"kind":kind,"entry":entry,"stage":stage,"copy":copy})
