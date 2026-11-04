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
#      _resource_feedback 置为可辨认的非 null 值，plan 必须原样恢复它（删除 plan 内的恢复行即红）；
#      _rope_trial 按例交替预置 false／true，plan 必须恢复预置值（删恢复行→预置 false 的例红，
#      写成固定 =false→预置 true 的例红）。事务边界字段的全集是 TRANSACTION_RUNTIME_FIELDS。
#   4) view_index_only_for_same_state（S2a-1）：读作用域的索引只认 live state 对象；同内容副本恒走扫描，
#      结果与无作用域扫描逐项相同，索引不被重建或泄漏。
#   5) random_draw_matches_random_index（S2a-1）：_random_draw 与 _random_index 在每个随机域 × size{1,2,7}
#      上返回值与计数推进相同；本地计数调用不碰 state.rng。
#
# 覆盖计数（F6）：_exercise() 返回本例实际执行到的函数集合；提前 return 的例不计入后续函数。
# 三条判据都在消息里分别报出每个函数的 checked 计数。
#
# 运行面（D21）：这三条不变量只跑固定小切片，不遍历入库语料、更不遍历全量源——日常门禁的
# replacement 套件因此与语料体积脱钩。切片＝21 例构造夹具（tag=fixture，覆盖镣铐／绳艺锁／
# 固缚同步等构造路径）+ 20260906 段步 199／203／214 的 3 个失败例（单例 ≤ 5 ms，含装配请求被
# 覆盖规则拒绝的早退路径）。切片按 SLICE_CASE_IDS 与 tag 取，不随语料排序漂移；新增夹具自动进面。
# 全量对拍走显式命令（驱动 tests/replacement_corpus_check.gd，--corpus 指向 build/s0/corpus/ 的全量源）。
#
# 单一入口（语义 → 唯一符号；改路径须同批改本节）：
#   语料读取／解码／Game 复位 → Corpus（replacement_corpus_cases.gd）的 load_corpus／unseal／
#   _fresh_game／_case_state，本模块不复制；切片 → _slice()（经 Corpus._envelope）；
#   快照 → _snapshot()；逐例调用 → _exercise()；差异 → _differences()。判据只由 assess_checks() 注册。

const Replacement=preload("res://core/equipment_replacement.gd")
const Assess=preload("res://core/equipment_replacement_assess.gd")
const Corpus=preload("res://tests/replacement_corpus_cases.gd")
const Store=preload("res://core/save_store.gd")
const Game=preload("res://core/game.gd")
const Equipment=preload("res://data/equipment.gd")

# _exercise 可能执行到的 assess 纯函数：覆盖计数按这张表逐函数报出。
const STEPS=["normalize","capacity_points","counts","replacement_value","physical_points","loss","pieces","units","sets","compare","assign","transfer_options"]

# 事务边界要保存并恢复的运行时字段（Replacement.plan／force_special：保存→置位→恢复）：state 换成草稿对象、
# _resource_feedback 置 null、_rope_trial 置 true。判定域（assess）既不读也不写它们（ARCH assess_dependency_edges）。
const TRANSACTION_RUNTIME_FIELDS=["state","_resource_feedback","_rope_trial"]

# 固定小切片（D21）：20260906 段步 199／203／214 的 3 个判定例（都是失败例、单例 ≤ 5 ms；
# 各自是「包裹前该侧手掌与手指必须没有装备」的装配早退路径，与夹具的镣铐／绳艺锁／固缚路径互补）。
const SLICE_CASE_IDS=["20260906-00000","20260906-00001","20260906-00002"]

# 切片：固定 id ∪ tag=fixture；封装走 Corpus._envelope（切片外壳的唯一入口）。
static func _slice(data: Dictionary) -> Dictionary:
 var keep=func(row): return String(row.get("case_id","")) in SLICE_CASE_IDS or String(row.get("tag",""))=="fixture"
 var cases=data.get("cases",[]).filter(keep)
 return Corpus._envelope(data,cases,[])

# 整份 state 的规范文本：encode 把整数/小数/名称区分开，JSON 文本再消除对象同一性。
static func _state_text(state: Dictionary) -> String:
 return JSON.stringify(Store.encode(state))

# 观察面：整份 state 的规范文本，加上事务边界字段（对象按引用、布尔按值，is_same 一并比较）。
static func _snapshot(g) -> Dictionary:
 var fields={}
 for name in TRANSACTION_RUNTIME_FIELDS: fields[name]=g.get(name)
 return {"text":_state_text(g.state),"fields":fields}

static func _tally(total: Dictionary, ran: Dictionary) -> void:
 for name in STEPS:
  if ran.get(name,false): total[name]=int(total.get(name,0))+1

static func _coverage(total: Dictionary, cases: int) -> String:
 var parts=[]
 for name in STEPS: parts.append(name+"="+str(int(total.get(name,0)))+"/"+str(cases))
 return " ".join(parts)

static func assess_checks(t) -> void:
 var full=Corpus.load_corpus()
 var data=_slice(full)
 print("ASSESS SLICE cases=%d fixtures=%d fixed_ids=%d full_corpus=%d" % [data.get("cases",[]).size(),data.get("cases",[]).filter(func(row): return String(row.get("tag",""))=="fixture").size(),SLICE_CASE_IDS.size(),full.get("cases",[]).size()])
 assess_pure_functions_leave_inputs_unchanged(t,data)
 assess_pure_functions_never_advance_random(t,data)
 replacement_plan_leaves_live_state_unchanged(t,data)
 view_index_only_for_same_state(t)
 random_draw_matches_random_index(t)
 parallel_orchestrations_call_the_shared_rules(t)

# case_id 逐条列出第一个差异：整份状态文本与每个事务边界字段分开报告，红行能直接判读。
static func _differences(case_id: String, before: Dictionary, after: Dictionary) -> Array:
 var problems=[]
 if before.text!=after.text: problems.append(case_id+":state changed")
 for name in TRANSACTION_RUNTIME_FIELDS:
  if not is_same(before.fields[name],after.fields[name]): problems.append(case_id+":"+name+" not restored")
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
  Assess.replacement_value(g,owned[0])
  Assess.physical_points(g,owned[0])
  ran.counts=true;ran.replacement_value=true;ran.physical_points=true
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
  # 绳艺试算标记按例交替预置 false／true：缺恢复行时预置 false 的例红，写成固定 =false 时预置 true 的例红。
  g._rope_trial=checked%2==1
  var before=_snapshot(g)
  var result=Replacement.plan(g,Corpus.unseal(case.get("requests",[]),"requests"),
   String(case.get("source","")),Corpus.unseal(case.get("protected_ids",[]),"protected_ids"))
  checked+=1
  if not result is Dictionary or not result.has("ok"): problems.append(String(case.get("case_id",""))+":result shape")
  elif result.ok: accepted+=1
  problems.append_array(_differences(String(case.get("case_id","")),before,_snapshot(g)))
 t.check(problems.is_empty() and checked==cases.size(),"ASSESS replacement_plan_leaves_live_state_unchanged: Replacement.plan restores every transaction runtime field (state object, resource feedback, rope-trial flag) and leaves the whole encoded state unchanged (plan calls %d/%d; accepted %d; feedback seeded and rope-trial flag alternately preset false/true before every call): %s" % [checked,cases.size(),accepted,str(problems.slice(0,3))])

# S2a-1（gherkin「索引只认同一对象」；design §3.1-3）：读作用域里的索引只对 live state 这一对象生效；
# 同内容不同对象的视图恒走扫描。做法：打开作用域后把索引四条边换成可辨认的探针件，分别以 state 与
# state 的副本求值——索引分支须看得见探针，副本须看不见，且副本结果与无作用域扫描逐项相同。
static func view_index_only_for_same_state(t) -> void:
 var g=Game.new(42)
 g._equipment_read={}
 g._resource_feedback=null
 g.add_fixture("upper_arm",7.0,10.0)
 g.add_fixture("wrist",7.0,10.0)
 var piece=g.state.equipment[0]
 var slot="upper_arm"
 var point=String(Equipment.capacity_points(piece)[0])
 var live_id=String(piece.id)
 # 无作用域的扫描参照（同一次调用里先取，再开作用域）。
 var plain_pieces=JSON.stringify(g.physical_pieces())
 var plain_slot=JSON.stringify(g.equipment_at(slot))
 var plain_count=g._point_count(point)
 var plain_equipment=String(g._equipment(live_id).get("id",""))
 var previous=g._begin_equipment_read()
 var scope=g._equipment_read
 var probe={"id":"probe_view_piece","template":"rope_wrist","variant":0,"slot":"wrist","name":"probe","durability":5.0,"maximum":10.0,"locked":false,"material":"rope","source":"probe","grade":1,"layer":0,"coverage":["wrist"],"points":[point]}
 scope.pieces=[probe]
 scope.slots={slot:[probe]}
 scope.capacity_points={point:[probe]}
 scope.physical_points={point:[probe]}
 scope.ids={"probe_view_piece":probe}
 # 同一对象：四条查询都必须来自索引（看得见探针）。
 var index_answers=[]
 if JSON.stringify(g.physical_pieces_in(g.state))!=JSON.stringify([probe]): index_answers.append("physical_pieces")
 if JSON.stringify(g.equipment_at_in(g.state,slot))!=JSON.stringify([probe]): index_answers.append("equipment_at")
 if g._point_count_in(g.state,point)!=1: index_answers.append("_point_count")
 if not is_same(g._equipment_in(g.state,"probe_view_piece"),probe): index_answers.append("_equipment")
 # 不同对象：视图必须绕过索引，结果等于无作用域扫描，且看不到探针。
 var view=g.state.duplicate(true)
 var view_answers=[]
 if JSON.stringify(g.physical_pieces_in(view))!=plain_pieces: view_answers.append("physical_pieces")
 if JSON.stringify(g.equipment_at_in(view,slot))!=plain_slot: view_answers.append("equipment_at")
 if g._point_count_in(view,point)!=plain_count: view_answers.append("_point_count")
 if String(g._equipment_in(view,live_id).get("id",""))!=plain_equipment: view_answers.append("_equipment")
 if not g._equipment_in(view,"probe_view_piece").is_empty(): view_answers.append("probe-visible")
 # 调用前后索引不被重建或泄漏：同一容器、探针仍在。
 var leaked=[]
 if not is_same(g._equipment_read,scope): leaked.append("scope-replaced")
 if (g._equipment_read.get("pieces",[]) as Array).size()!=1 or String(g._equipment_read.pieces[0].id)!="probe_view_piece": leaked.append("probe-edge-lost")
 g._equipment_read=previous
 t.check(index_answers.is_empty() and leaked.is_empty(),"ASSESS view_index_only_for_same_state: the live state object answers from the batch index and the index is neither rebuilt nor leaked around the call (index=%s scope=%s)" % [str(index_answers),str(leaked)])
 t.check(view_answers.is_empty(),"ASSESS view_index_only_for_same_state: a same-content view object always scans and equals the no-scope reference (probe invisible, same items in the same order): %s" % str(view_answers))
 t.check(g._equipment_read.is_empty(),"ASSESS view_index_only_for_same_state: the read scope is restored to its previous value after the views are evaluated: "+str(g._equipment_read))

# S2a-1（gherkin「随机抽取一份实现（X3）」；design §3.4）：_random_draw 是唯一的抽取算式，_random_index 只是
# 把 live seed 与 counter 字典交给它。两个方向都要成立：本地计数调用不碰 state.rng，且同 seed／同计数下
# 两者的返回值与计数推进逐项相同（含 size<=1 不递增）。
static func random_draw_matches_random_index(t) -> void:
 var g=Game.new(42)
 var domains=[]
 for domain in g.B.RNG_SALTS.keys(): domains.append(String(domain))
 domains.sort()
 var untouched=[]
 var problems=[]
 var checked=0
 for domain in domains:
  for size in [1,2,7]:
   var before=JSON.stringify(g.state.rng)
   g._random_draw(g.state.seed,domain,{domain:0},size)
   if JSON.stringify(g.state.rng)!=before: untouched.append(domain+"/"+str(size))
   var local={}
   local[domain]=int(g.state.rng[domain])
   var expected=g._random_draw(g.state.seed,domain,local,size)
   var live_before=int(g.state.rng[domain])
   var live=g._random_index(domain,size)
   var live_after=int(g.state.rng[domain])
   var delta=0 if size<=1 else 1
   if expected!=live: problems.append(domain+"/"+str(size)+":value")
   if live_after-live_before!=delta: problems.append(domain+"/"+str(size)+":live counter +"+str(live_after-live_before))
   if int(local[domain])-live_before!=delta: problems.append(domain+"/"+str(size)+":local counter +"+str(int(local[domain])-live_before))
   checked+=1
 print("ASSESS RANDOM DRAW domains=%d checked=%d counters=%s" % [domains.size(),checked,JSON.stringify(g.state.rng)])
 t.check(untouched.is_empty(),"ASSESS random_draw_matches_random_index: a local counter dictionary is the only thing _random_draw advances -- state.rng is byte-identical before and after (domains=%d sizes=1,2,7): %s" % [domains.size(),str(untouched)])
 t.check(problems.is_empty() and checked==domains.size()*3,"ASSESS random_draw_matches_random_index: the live entry and the shared draw return the same value and advance exactly one counter step for every registered domain and size in {1,2,7} (size<=1 does not advance): checked=%d/%d %s" % [checked,domains.size()*3,str(problems.slice(0,6))])

# design §5「编排登记」：O3 的 live 端已存在（遍历顺序由 ARCH factory_records_have_one_builder 钉住），
# 视图端 cleanup_model 属 S2b。本行＝[编号, live 锚点, 视图锚点, 共用规则名单, 视图端是否尚未实现, live 独有副作用]：
# 名单非空且与 live 骨架的共用谓词调用双向相等；视图端出现须调同一名单并同批翻标记；第 6 列在视图端出现即红。
const PARALLEL_ORCHESTRATIONS=[["O3","core/game.gd::_cleanup","core/equipment_replacement_assess.gd::cleanup_model",["_released","_strap_follows","_strap_orphaned","_piece_released","_root_head_orphaned","_component_kept","_link_anchor_lost"],true,["RopeArt.track(","_emit(","Pressure.","Cards.","_equipment_feedback("]]]

static func _source(relative: String) -> String:
 var file=FileAccess.open("res://"+relative,FileAccess.READ)
 return "" if file==null else file.get_as_text()

# 函数体文本（签名之后、下一个声明之前），注释剔除：判据只看代码。
static func _function_code(site: String) -> String:
 var parts=site.split("::")
 if parts.size()<2: return ""
 var text=_source(String(parts[0]))
 var declaration=RegEx.new()
 if declaration.compile("(?m)^(?:static\\s+)?func\\s+"+String(parts[1])+"\\s*\\(")!=OK: return ""
 var hit=declaration.search(text)
 if hit==null: return ""
 var following=RegEx.new()
 if following.compile("(?m)^(?:static\\s+)?func\\s+")!=OK: return ""
 var next=following.search(text,hit.get_end())
 var end=text.length() if next==null else next.get_start()
 var lines=[]
 for line in text.substr(hit.get_end(),end-hit.get_end()).split("\n"): lines.append(String(line).split("#")[0])
 return "\n".join(lines)

# 共用清理规则＝live 骨架里裸调用的、在 core/game.gd 内为单行纯谓词的本地函数：与登记表双向对照的源侧枚举。
static func _shared_rule_calls(body: String) -> Array:
 var names=[]; var call=RegEx.new(); if call.compile("(?<![.\\w])(_[a-z][a-z0-9_]*)\\(")!=OK: return names
 for hit in call.search_all(body):
  var rest=Array(_function_code("core/game.gd::"+hit.get_string(1)).split("\n",false,1))
  var code=String(rest[1]).strip_edges() if rest.size()>1 else ""
  if not hit.get_string(1) in names and code.begins_with("return ") and not code.contains("\n") and not code.contains("_in(") and not code.contains("state."): names.append(hit.get_string(1))
 names.sort(); return names

static func parallel_orchestrations_call_the_shared_rules(t) -> void:
 var malformed=[]; var uncalled=[]; var pending=[]; var aligned=[]; var live_only=[]
 for row in PARALLEL_ORCHESTRATIONS:
  if row.size()<6: malformed.append("row-size"); continue
  var declared=Array(row[3]).duplicate(); declared.sort(); if declared.is_empty() or Array(row[5]).is_empty(): malformed.append(String(row[0])+":row")
  var live=_function_code(String(row[1])); var called=_shared_rule_calls(live) if live.strip_edges()!="" else []
  if live.strip_edges()=="" or called!=declared: uncalled.append(String(row[1])+": called="+str(called)+" declared="+str(declared))
  var view=_function_code(String(row[2])); var declare_pending=bool(row[4])
  if view.strip_edges()=="":
   if not declare_pending: uncalled.append(String(row[2])+":missing")
  else:
   if declare_pending: pending.append(String(row[0])+" -> "+String(row[2]))
   for name in declared:
    if not view.contains(String(name)+"("): uncalled.append(String(row[2])+":"+String(name))
   for token in row[5]:
    if view.contains(String(token)): live_only.append(String(row[2])+":"+String(token))
   aligned.append(String(row[0]))
 print("PARALLEL ORCHESTRATIONS aligned=%s pending_view=%s rows=%d" % [str(aligned),str(pending),PARALLEL_ORCHESTRATIONS.size()])
 t.check(not PARALLEL_ORCHESTRATIONS.is_empty() and malformed.is_empty() and uncalled.is_empty(),"ASSESS parallel_orchestrations_call_the_shared_rules: the table is never empty, every row declares a shared-rule list and its live-only side effects, and the live end of each row calls exactly the shared cleanup predicates its row lists (a deleted row, an emptied list, a deleted call or an unlisted predicate is red): rows="+str(PARALLEL_ORCHESTRATIONS.size())+" malformed="+str(malformed)+" uncalled="+str(uncalled))
 t.check(live_only.is_empty(),"ASSESS parallel_orchestrations_call_the_shared_rules: the view end of an orchestration never runs a side effect that belongs to the live end alone (rope counting, events, pressure and card settlement, equipment feedback): live_only="+str(live_only))
 t.check(pending.is_empty(),"ASSESS parallel_orchestrations_call_the_shared_rules: a row declared as pending on the view side must not have that side yet -- S2b must flip the marker in the same batch that adds cleanup_model, so the two skeletons cannot silently drift: appeared="+str(pending))
