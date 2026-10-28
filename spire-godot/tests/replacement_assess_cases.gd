extends RefCounted

# S1 加固（中档，A14）：core/equipment_replacement_assess.gd 的纯阶段函数在真实语料上不写入参、
# 不推进随机；Replacement.plan 的事务边界不把草稿泄漏回 live state。
#
# 入口是 assess_checks(t)，由 tests/test_game.gd 的 replacement 分支调用。本模块不是注册套件，
# 刻意不声明 `static func run(`（tests/check_index.gd::declares_run 只认行首真实声明），
# 与 tests/replacement_corpus_cases.gd 同一形态。
#
# 判据与观察面：
#   1) assess_pure_functions_leave_inputs_unchanged：逐语料例直调 assess 的纯函数；调用前后整份
#      g.state（经 core/save_store.gd::encode 后的规范文本）与 g._resource_feedback 相等，
#      g.state 引用未被替换。不再只比选定键：任何 state 键的变化都会让文本不同。
#   2) assess_pure_functions_never_advance_random：同一循环，state.rng 与 state.seed 逐例不变。
#   3) replacement_plan_leaves_live_state_unchanged：逐语料例跑 Replacement.plan；调用前把
#      _resource_feedback 置为可辨认的非 null 值，plan 必须原样恢复它（删除 plan 内的恢复行即红）。
#
# 覆盖计数（F6）：_exercise() 返回本例实际执行到的函数集合；提前 return 的例不计入后续函数。
# 三条判据都在消息里分别报出每个函数的 checked 计数。
#
# 单一入口（语义 → 唯一符号；改路径须同批改本节）：
#   语料读取／解码／Game 复位 → Corpus（replacement_corpus_cases.gd）的 load_corpus／unseal／
#   _fresh_game／_case_state，本模块不复制；快照 → _snapshot()；逐例调用 → _exercise()；
#   差异 → _differences()。判据只由 assess_checks() 注册。

const Replacement=preload("res://core/equipment_replacement.gd")
const Assess=preload("res://core/equipment_replacement_assess.gd")
const Corpus=preload("res://tests/replacement_corpus_cases.gd")
const Store=preload("res://core/save_store.gd")

# _exercise 可能执行到的 assess 纯函数：覆盖计数按这张表逐函数报出。
const STEPS=["normalize","capacity_points","counts","comparison_value","physical_points","loss","pieces","units","sets","compare","assign","transfer_options"]

# 整份 state 的规范文本：encode 把整数/小数/名称区分开，JSON 文本再消除对象同一性。
static func _state_text(state: Dictionary) -> String:
 return JSON.stringify(Store.encode(state))

# 观察面：整份 state 的文本与引用，反馈记录器的内容与引用。
static func _snapshot(g) -> Dictionary:
 return {"text":_state_text(g.state),"state":g.state,"feedback":g._resource_feedback}

static func _tally(total: Dictionary, ran: Dictionary) -> void:
 for name in STEPS:
  if ran.get(name,false): total[name]=int(total.get(name,0))+1

static func _coverage(total: Dictionary, cases: int) -> String:
 var parts=[]
 for name in STEPS: parts.append(name+"="+str(int(total.get(name,0)))+"/"+str(cases))
 return " ".join(parts)

static func assess_checks(t) -> void:
 var data=Corpus.load_corpus()
 assess_pure_functions_leave_inputs_unchanged(t,data)
 assess_pure_functions_never_advance_random(t,data)
 replacement_plan_leaves_live_state_unchanged(t,data)

# case_id 逐条列出第一个差异：整份状态文本、state 引用、反馈三者分开报告，红行能直接判读。
static func _differences(case_id: String, before: Dictionary, after: Dictionary) -> Array:
 var problems=[]
 if before.text!=after.text: problems.append(case_id+":state changed")
 if not is_same(before.state,after.state): problems.append(case_id+":state reference replaced")
 if before.feedback!=after.feedback or not is_same(before.feedback,after.feedback): problems.append(case_id+":resource feedback changed")
 return problems

# 对每例的语料容器直调迁入 assess 的纯函数：参数就是 live 容器，不给函数任何副本。
# 返回本例实际执行到的函数集合；提前 return 之前的函数才算已覆盖。
static func _exercise(g, case: Dictionary) -> Dictionary:
 var ran={}
 var requests=Corpus.unseal(case.get("requests",[]),"requests")
 if requests is Array:
  Assess.normalize(g,requests)
  ran.normalize=true
 var owned=g.state.equipment+g.state.special_equipment
 var deficit={}
 for piece in owned:
  for point in Assess.capacity_points(g,piece):
   deficit[point]=1
   ran.capacity_points=true
   break
  if not deficit.is_empty(): break
 if deficit.is_empty():
  for root in g.state.composites:
   for piece in root.components:
    for point in Assess.capacity_points(g,piece):
     deficit[point]=1
     ran.capacity_points=true
     break
    if not deficit.is_empty(): break
   if not deficit.is_empty(): break
 if not owned.is_empty():
  Assess.counts(g,owned)
  Assess.counts(g,g.state.special_equipment)
  Assess.comparison_value(g,owned[0])
  Assess.physical_points(g,owned[0])
  ran.counts=true;ran.comparison_value=true;ran.physical_points=true
 if not deficit.is_empty() and not owned.is_empty():
  Assess.loss(g,owned[0],deficit.keys()[0],{"composite":false,"pieces":[owned[0]]},g.state.links,[])
  ran.loss=true
 for root in g.state.composites:
  Assess.pieces(root)
  ran.pieces=true
 var units=Assess.units(g,g.state.equipment,g.state.special_equipment,g.state.composites,deficit)
 ran.units=true
 if units.is_empty(): return ran
 # 覆盖搜索与分配只需证明入参不被改写；切片与最小深度把耗时钉在毫秒级。
 Assess.sets(units.slice(0,4),deficit.duplicate(),[],{"minimum":2,"sets":[],"seen":{}})
 Assess.compare(g,units.slice(0,2),g.state.equipment,deficit,g.state.links,[])
 var row={"old_id":String(units[0].id),"unit":String(units[0].id),"point":deficit.keys()[0],
  "old_value":0,"lost_link_bonus":0,"composite":false}
 Assess.assign(g,[row],g.state.equipment,{},0,{},{},[])
 ran.sets=true;ran.compare=true;ran.assign=true
 if not g.state.links.is_empty():
  Assess.transfer_options(g,g.state.links,owned,g.link_anchors(),g.state.links)
  ran.transfer_options=true
 return ran

static func assess_pure_functions_leave_inputs_unchanged(t, data: Dictionary) -> void:
 var problems=[]
 var total={}
 var checked=0
 var cases=data.get("cases",[])
 for case in cases:
  if problems.size()>=3: break
  var g=Corpus._fresh_game()
  g.state=Corpus._case_state(data,case)
  var before=_snapshot(g)
  _tally(total,_exercise(g,case))
  checked+=1
  problems.append_array(_differences(String(case.get("case_id","")),before,_snapshot(g)))
 t.check(problems.is_empty() and int(total.get("units",0))==checked,"ASSESS assess_pure_functions_leave_inputs_unchanged: every corpus case keeps the whole encoded state and the resource feedback unchanged and the state object by reference (checked %d/%d; calls per function: %s): %s" % [checked,cases.size(),_coverage(total,cases.size()),str(problems.slice(0,3))])

static func assess_pure_functions_never_advance_random(t, data: Dictionary) -> void:
 var problems=[]
 var total={}
 var checked=0
 var cases=data.get("cases",[])
 for case in cases:
  if problems.size()>=3: break
  var g=Corpus._fresh_game()
  g.state=Corpus._case_state(data,case)
  var rng=g.state.rng.duplicate(true)
  var seed_value=g.state.seed
  _tally(total,_exercise(g,case))
  checked+=1
  if g.state.rng!=rng or g.state.seed!=seed_value: problems.append(String(case.get("case_id","")))
 t.check(problems.is_empty() and int(total.get("units",0))==checked,"ASSESS assess_pure_functions_never_advance_random: the migrated assess functions never advance state.rng or state.seed on any corpus case (checked %d/%d; calls per function: %s): %s" % [checked,cases.size(),_coverage(total,cases.size()),str(problems.slice(0,3))])

static func replacement_plan_leaves_live_state_unchanged(t, data: Dictionary) -> void:
 var problems=[]
 var checked=0
 var accepted=0
 var cases=data.get("cases",[])
 for case in cases:
  if problems.size()>=3: break
  var g=Corpus._fresh_game()
  g.state=Corpus._case_state(data,case)
  # 可辨认的非 null 反馈：plan 的「置空→恢复」两半都可观测，删除恢复行即红（F5）。
  g._resource_feedback={"texts":["assess-plan-probe"]}
  var before=_snapshot(g)
  var result=Replacement.plan(g,Corpus.unseal(case.get("requests",[]),"requests"),
   String(case.get("source","")),Corpus.unseal(case.get("protected_ids",[]),"protected_ids"))
  checked+=1
  if not result is Dictionary or not result.has("ok"): problems.append(String(case.get("case_id",""))+":result shape")
  elif result.ok: accepted+=1
  problems.append_array(_differences(String(case.get("case_id","")),before,_snapshot(g)))
 t.check(problems.is_empty() and checked==cases.size(),"ASSESS replacement_plan_leaves_live_state_unchanged: Replacement.plan restores the live state object and the resource feedback and leaves the whole encoded state unchanged (plan calls %d/%d; accepted %d; feedback seeded before every call): %s" % [checked,cases.size(),accepted,str(problems.slice(0,3))])
