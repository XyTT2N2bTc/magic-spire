extends RefCounted

# S1 加固（中档）：core/equipment_replacement_assess.gd 的纯阶段函数在真实语料上不写入参、
# 不推进随机；Replacement.plan 的事务边界不把草稿泄漏回 live state。
#
# 入口是 assess_checks(t)，由 tests/test_game.gd 的 replacement 分支调用。本模块不是注册套件，
# 刻意不声明 `static func run(`（tests/check_index.gd::declares_run 只认行首真实声明），
# 与 tests/replacement_corpus_cases.gd 同一形态。
#
# 判据与观察面：
#   1) assess_pure_functions_leave_inputs_unchanged：逐语料例直调 assess 的纯函数，容器就是
#      g.state 的四个容器与 before.links（transfer_options／loss／compare 的 links 参数）；
#      调用前后深比较相同，且容器引用未被替换（不是「复制一份相等的」）。
#   2) assess_pure_functions_never_advance_random：同一循环，state.rng 与 state.seed 逐例不变。
#   3) replacement_plan_leaves_live_state_unchanged：逐语料例跑 Replacement.plan，live 容器、
#      links、rng、seed 与 g.state 引用不变。plan 自身的草稿交换属事务（design.md §7），
#      本判据只观察调用边界；全语料对拍另由 --mode=reoracle 承担。
#
# 单一入口（语义 → 唯一符号；改路径须同批改本节）：
#   语料读取／解码／Game 复位 → Corpus（replacement_corpus_cases.gd）的 load_corpus／unseal／
#   _fresh_game／_case_state，本模块不复制；快照 → _snapshot()；逐例调用 → _exercise()；
#   差异 → _differences()。判据只由 assess_checks() 注册。

const Replacement=preload("res://core/equipment_replacement.gd")
const Assess=preload("res://core/equipment_replacement_assess.gd")
const Corpus=preload("res://tests/replacement_corpus_cases.gd")

# 只读面：四个装备容器＋links＋logs 的内容与引用，随机流与种子。
const CONTAINERS=["equipment","special_equipment","composites","links","logs"]

static func assess_checks(t) -> void:
 var data=Corpus.load_corpus()
 assess_pure_functions_leave_inputs_unchanged(t,data)
 assess_pure_functions_never_advance_random(t,data)
 replacement_plan_leaves_live_state_unchanged(t,data)

static func _snapshot(g) -> Dictionary:
 var refs={"state":g.state}
 var content={}
 for key in CONTAINERS:
  refs[key]=g.state[key]
  content[key]=g.state[key].duplicate(true)
 content.seed=g.state.seed
 content.rng=g.state.rng.duplicate(true)
 return {"content":content,"refs":refs}

# case_id 逐条列出第一个差异：内容、引用、随机三者分开报告，红行能直接判读是哪条不变量。
static func _differences(case_id: String, before: Dictionary, after: Dictionary) -> Array:
 var problems=[]
 for key in CONTAINERS:
  if before.content[key]!=after.content[key]: problems.append(case_id+":"+key+" changed")
  if not is_same(before.refs[key],after.refs[key]): problems.append(case_id+":"+key+" reference replaced")
 if before.content.seed!=after.content.seed: problems.append(case_id+":seed changed")
 if before.content.rng!=after.content.rng: problems.append(case_id+":rng changed")
 return problems

# 对每例的语料容器直调迁入 assess 的纯函数：参数就是 live 容器，不给函数任何副本。
static func _exercise(g, case: Dictionary) -> void:
 var requests=Corpus.unseal(case.get("requests",[]),"requests")
 if requests is Array: Assess.normalize(g,requests)
 var owned=g.state.equipment+g.state.special_equipment
 var deficit={}
 for piece in owned:
  for point in Assess.capacity_points(g,piece):
   deficit[point]=1
   break
  if not deficit.is_empty(): break
 if deficit.is_empty():
  for root in g.state.composites:
   for piece in root.components:
    for point in Assess.capacity_points(g,piece):
     deficit[point]=1
     break
    if not deficit.is_empty(): break
   if not deficit.is_empty(): break
 if not owned.is_empty():
  Assess.counts(g,owned)
  Assess.counts(g,g.state.special_equipment)
  Assess.comparison_value(g,owned[0])
  Assess.physical_points(g,owned[0])
 if not deficit.is_empty() and not owned.is_empty():
  Assess.loss(g,owned[0],deficit.keys()[0],{"composite":false,"pieces":[owned[0]]},g.state.links,[])
 for root in g.state.composites: Assess.pieces(root)
 var units=Assess.units(g,g.state.equipment,g.state.special_equipment,g.state.composites,deficit)
 if units.is_empty(): return
 # 覆盖搜索与分配只需证明入参不被改写；切片与最小深度把耗时钉在毫秒级。
 Assess.sets(units.slice(0,4),deficit.duplicate(),[],{"minimum":2,"sets":[],"seen":{}})
 Assess.compare(g,units.slice(0,2),g.state.equipment,deficit,g.state.links,[])
 var row={"old_id":String(units[0].id),"unit":String(units[0].id),"point":deficit.keys()[0],
  "old_value":0,"lost_link_bonus":0,"composite":false}
 Assess.assign(g,[row],g.state.equipment,{},0,{},{},[])
 if not g.state.links.is_empty():
  Assess.transfer_options(g,g.state.links,owned,g.link_anchors(),g.state.links)

static func assess_pure_functions_leave_inputs_unchanged(t, data: Dictionary) -> void:
 var problems=[]
 var checked=0
 for case in data.get("cases",[]):
  if problems.size()>=3: break
  var g=Corpus._fresh_game()
  g.state=Corpus._case_state(data,case)
  var before=_snapshot(g)
  _exercise(g,case)
  checked+=1
  problems.append_array(_differences(String(case.get("case_id","")),before,_snapshot(g)))
 t.check(problems.is_empty(),"ASSESS assess_pure_functions_leave_inputs_unchanged: every corpus case keeps the four state containers and the links passed to transfer_options/loss/compare intact and by reference (checked %d/%d): %s" % [checked,data.get("cases",[]).size(),str(problems.slice(0,3))])

static func assess_pure_functions_never_advance_random(t, data: Dictionary) -> void:
 var problems=[]
 var checked=0
 for case in data.get("cases",[]):
  if problems.size()>=3: break
  var g=Corpus._fresh_game()
  g.state=Corpus._case_state(data,case)
  var rng=g.state.rng.duplicate(true)
  var seed_value=g.state.seed
  _exercise(g,case)
  checked+=1
  if g.state.rng!=rng or g.state.seed!=seed_value: problems.append(String(case.get("case_id","")))
 t.check(problems.is_empty(),"ASSESS assess_pure_functions_never_advance_random: the migrated assess functions never advance state.rng or state.seed on any corpus case (checked %d/%d): %s" % [checked,data.get("cases",[]).size(),str(problems.slice(0,3))])

static func replacement_plan_leaves_live_state_unchanged(t, data: Dictionary) -> void:
 var problems=[]
 var checked=0
 for case in data.get("cases",[]):
  if problems.size()>=3: break
  var g=Corpus._fresh_game()
  g.state=Corpus._case_state(data,case)
  var before=_snapshot(g)
  var result=Replacement.plan(g,Corpus.unseal(case.get("requests",[]),"requests"),
   String(case.get("source","")),Corpus.unseal(case.get("protected_ids",[]),"protected_ids"))
  checked+=1
  if not result is Dictionary or not result.has("ok"): problems.append(String(case.get("case_id",""))+":result shape")
  if not is_same(g.state,before.refs.state): problems.append(String(case.get("case_id",""))+":state reference replaced")
  problems.append_array(_differences(String(case.get("case_id","")),before,_snapshot(g)))
 t.check(problems.is_empty() and checked==data.get("cases",[]).size(),"ASSESS replacement_plan_leaves_live_state_unchanged: Replacement.plan restores the live state object and leaves equipment/special_equipment/composites/links/logs, rng and seed unchanged (checked %d/%d): %s" % [checked,data.get("cases",[]).size(),str(problems.slice(0,3))])
