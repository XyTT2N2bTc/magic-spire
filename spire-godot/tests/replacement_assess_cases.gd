extends RefCounted

# S1 加固（中档，A14）＋S2a／S2b：core/equipment_replacement_assess.gd 的纯阶段函数在真实语料上不写入参、
# 不推进随机；Replacement.plan 的事务边界不把草稿泄漏回 live state；读作用域索引只认同一对象；随机抽取
# 只有一份算式；贞操锁 special_install 不进只读判定；按输入类登记的回退表默认为空（A58）。
#
# 入口是 assess_checks(t)，由 tests/test_game.gd 的 replacement 分支调用。本模块不是注册套件，刻意不声明
# `static func run(`（tests/check_index.gd::declares_run 只认行首真实声明），与 tests/replacement_corpus_cases.gd 同形。
#
# 判据与观察面（各判据的消息里报出自己的 checked 计数）：
#   1) assess_pure_functions_leave_inputs_unchanged：调用前后整份 SaveStore.encode(state) 与 _resource_feedback 相等、state 引用未换。
#   2) assess_pure_functions_never_advance_random：同一循环，state.rng 与 state.seed 逐例不变。
#   3) replacement_plan_leaves_live_state_unchanged：_resource_feedback 预置可辨认非 null、_sandbox_depth 按例交替预置 0／1，plan 必须原样恢复。
#   4) view_index_only_for_same_state：读作用域索引只认 live state 对象；同内容副本恒走扫描、结果与无作用域扫描逐项相同。
#   5) random_draw_matches_random_index：_random_draw 与 _random_index 在每个随机域 × size{1,2,7} 上返回值与计数推进相同。
#   6) chastity_requests_never_reach_the_judgment（A52 F2）：唯一跳过点在 legal_requests；legal 直接收到贞操锁请求返回 false（防御）。
#   7) fallback_classes_are_declared（A58）：回退类表默认为空；单请求与 random_variant 判定路径只对表内输入类调 _replacement_plan，反向也核对。
#
# 运行面（D21）：只跑固定小切片（21 例构造夹具 + 20260906 段步 199／203／214），不遍历入库语料，replacement
# 套件因此与语料体积脱钩；全量对拍走 tests/replacement_corpus_check.gd（--corpus 指向 build/s0/corpus/ 的全量源）。
# 单一入口（语义 → 唯一符号；改路径须同批改本节）：语料读取／解码／Game 复位 → Corpus.load_corpus／unseal／
# _fresh_game／_case_state，本模块不复制；切片 → _slice()（经 Corpus._envelope）；快照 → _snapshot()；
# 逐例调用 → _exercise()；差异 → _differences()。判据只由 assess_checks() 注册。

const Replacement=preload("res://core/equipment_replacement.gd")
const Assess=preload("res://core/equipment_replacement_assess.gd")
const Corpus=preload("res://tests/replacement_corpus_cases.gd")
const Store=preload("res://core/save_store.gd")
const Game=preload("res://core/game.gd")
const Equipment=preload("res://data/equipment.gd")
const Arch=preload("res://tests/architecture_cases.gd")

# design §9 L2（A52 F3）：live 清理骨架与 _trial 会执行、视图骨架跳过的钩子。行＝[钩子锚点, 声明的写键,
# 视图端禁跑的 live-only token, 到达链（[锚点, token] 对；首跳锚点须是本表行或 core/equipment_removal.gd::settle，
# 末跳 token 须是该钩子的调用）]。判据在 tests/replacement_view_cases.gd::excluded_hooks_are_not_read_by_the_judgment。
const ASSESS_EXCLUDED_HOOKS=[
 ["core/card_effects.gd::restraint_changed",["powers","energy"],"Cards.",[]],
 ["core/pressure.gd::cleanup",["pressure_sources"],"Pressure.",[]],
 ["core/pressure.gd::settle_maximum",["pressure","overloaded","overload_count","overload_energy","overload_total","chastity_climax_factor","slip_ejaculation_turns"],"Pressure.",[]],
 # Q5″：安装路径的回魔调用从工厂内联移到 `_join_hooks`（单位提交之后），故到达链补一跳；行本身不删。
 ["core/relic_effects.gd::_mana_hook",["mana","mana_max","flask_mana"],"Pressure.",
  [["core/pressure.gd::settle_maximum","_apply_overloads("],["core/pressure.gd::_apply_overloads","g.RelicEffects.climax("],["core/relic_effects.gd::climax","_mana_hook("],["core/game.gd::_join_hooks","_mana_hook("]]],
 ["core/game.gd::_emit",["logs","summary"],"_emit(",[]]]
# rev3.1 §4.4：与上表区分——事务内由门控变成空操作的钩子，判定不执行它们与事务完全等价，故不进上表。
# 行＝[锚点, 门控行原文, live 端调用 token, 该调用所在的 live 文件]。
const TRANSACTION_NOOP_HOOKS=[
 ["core/rope_master.gd::track","if g._sandbox_depth>0: return","RopeArt.track(","core/game.gd"],
 ["core/rope_master.gd::observe","if g._sandbox_depth>0: return","RopeArt.observe(","core/capture_bind.gd"],
 ["core/game.gd::_equipment_feedback","if _resource_feedback!=null:","_equipment_feedback(","core/game.gd"]]
const EQUIPMENT_CONTAINERS=["equipment","composites","special_equipment","links"]

# design §7 前置条件（A52 F2）：贞操锁 special_install 不进只读判定。唯一跳过点在 legal_requests 的
# replace 分支；legal 对直接调用返回 false（防御）。语料侧由 Corpus.judge_subject 回落到 S2b 前的预言机；
# 类型名单不在此重抄，取 data/special_equipment.gd::CHASTITY_TYPES（判据遍历该声明）。
const CHASTITY_SKIP_TOKEN="is_chastity_type(request.get(\"type\",\"\")): continue"

# design §9 回退（A58）：回退＝第③类处理，按输入类登记、默认空。贞操锁 special_install 是跳过
# （chastity_requests_never_reach_the_judgment），_groups／_covering_plan 叶子是 S3 前的既定旧路径
# （ARCH legal_requests_is_the_only_judgment_entry 的漏斗计数）；回退类只由本表登记，不得按运行时猜测。
const FALLBACK_CLASSES=[]

# _exercise 可能执行到的 assess 纯函数：覆盖计数按这张表逐函数报出。
const STEPS=["normalize","capacity_points","counts","replacement_value","physical_points","loss","pieces","units","sets","compare","assign","transfer_options"]

# 事务边界要保存并恢复的运行时字段（Replacement.plan／force_special 经 Game._sandbox_begin／_sandbox_end：
# 保存→置位→恢复）：state 换成草稿对象、_resource_feedback 置 null、_sandbox_depth 加一（QX6：原 _rope_trial
# 并入沙盒深度）。判定域（assess）既不读也不写它们（ARCH assess_dependency_edges）。
const TRANSACTION_RUNTIME_FIELDS=["state","_resource_feedback","_sandbox_depth"]

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
 chastity_requests_never_reach_the_judgment(t)
 fallback_classes_are_declared(t)

# A52 F2（design §7）：贞操锁 special_install 是判定域外输入。三向：唯一跳过点在 legal_requests 且只出现一次；
# legal 直接收到时返回 false（防御）；语料接缝把该类交给 S2b 之前的预言机。跳过点被删或判定放行即红。
static func chastity_requests_never_reach_the_judgment(t) -> void:
 var application=Arch.source_code("core/equipment_application.gd")
 var assessment=Arch.source_code("core/equipment_replacement_assess.gd")
 var skipped=Arch.source_function_body("core/equipment_application.gd","legal_requests")
 var refused=[]
 var g=Game.new(42)
 for type in g.SpecialEquipment.CHASTITY_TYPES:
  var request={"kind":"special_install","type":type,"slot":g.SpecialEquipment.DESIGNS[type].slots[0],"tier":2}
  if Assess.legal(g,[request],"fixture",[]): refused.append(type)
 var seam=Arch.source_function_body("tests/replacement_corpus_cases.gd","judge_subject")
 t.check(application.count(CHASTITY_SKIP_TOKEN)==1 and skipped.contains(CHASTITY_SKIP_TOKEN) and assessment.count(CHASTITY_SKIP_TOKEN)==0,"ASSESS chastity_requests_never_reach_the_judgment: the one skip point for a chastity special_install stays inside legal_requests (and nowhere in the judgment module), so the judgment is never handed one by the wired path: application_lines=%d in_legal_requests=%s assessment_lines=%d" % [application.count(CHASTITY_SKIP_TOKEN),str(skipped.contains(CHASTITY_SKIP_TOKEN)),assessment.count(CHASTITY_SKIP_TOKEN)])
 t.check(refused.is_empty() and seam.contains("is_chastity_type"),"ASSESS chastity_requests_never_reach_the_judgment: the judgment refuses every chastity type handed to it directly (defensive false, not the transaction verdict) and the corpus seam judges that class with the pre-S2b oracle path: refused="+str(refused))

# 回退调用点的输入类归属：只认「kind=="X" 守卫行 + 其下至多 4 行内的 _replacement_plan 调用」；
# 未归属的调用由总计数差（calls != sites）抓住，不靠旁路漏扫。
static func _fallback_sites(body: String) -> Array:
 var sites=[]
 var guarded=RegEx.create_from_string("kind[^=\\n]{0,16}==\\s*\"([a-z_]+)\"[^\\n]*\\n(?:[ \\t]+[^\\n]*\\n){0,3}[ \\t]+[^\\n]*_replacement_plan\\(")
 for hit in guarded.search_all(body): sites.append(hit.get_string(1))
 sites.sort()
 return sites

# A58（design §9 回退；dependencies「回退类默认为空」）：源侧扫描 legal_requests 的函数体（random_variant
# 与单请求两个判定分支都在其中）：判定走 Assess.legal，_replacement_plan 只许出现在表内输入类下；表空即
# 零回退；反向核对（登记了类却无对应回退调用即红）。贞操锁跳过与 _groups 叶子不得登记成回退类。
static func fallback_classes_are_declared(t) -> void:
 var body=""
 for line in Arch.source_function_body("core/equipment_application.gd","legal_requests").split("\n"): body+=String(line).split("#")[0]+"\n"
 var classes=FALLBACK_CLASSES.duplicate()
 var sites=_fallback_sites(body)
 var undeclared=sites.filter(func(name):return name not in classes)
 var missing=classes.filter(func(name):return not sites.has(name))
 var leaf=Arch.source_function_body("core/equipment_application.gd","_covering_plan").contains("_replacement_plan(") and Arch.source_function_body("core/equipment_application.gd","_groups").contains("_covering_plan(")
 print("ASSESS FALLBACK CLASSES declared=%d sites=%d classes=%s" % [classes.size(),sites.size(),str(sites)])
 t.check(not body.is_empty() and body.count("Assess.legal(")==2 and leaf,"ASSESS fallback_classes_are_declared: the random_variant and single-request branches judge through Assess.legal while the only remaining plan call is the pre-S3 group leaf _groups -> _covering_plan -- never a fallback class: legal_calls=%d leaf=%s" % [body.count("Assess.legal("),str(leaf)])
 t.check(classes.all(func(name):return name is String and name!="") and body.count("_replacement_plan(")==sites.size() and undeclared.is_empty() and missing.is_empty(),"ASSESS fallback_classes_are_declared: legal_requests plans through the transaction only for the input classes this table registers -- an empty table means zero _replacement_plan calls in the judgment path, and a registered class without its source fallback is red too (never register the chastity skip or the group leaf): table=%s calls=%d undeclared=%s missing=%s" % [str(FALLBACK_CLASSES),body.count("_replacement_plan("),str(undeclared),str(missing)])

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
  Assess.transfer_options(g,g.state,g.state.links,owned,g.link_anchors(),g.state.links)
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
  # 沙盒深度按例交替预置 0／1：缺恢复行时预置 0 的例红，写成固定归零时预置 1 的例红。
  g._sandbox_depth=checked%2
  var before=_snapshot(g)
  var result=Replacement.plan(g,Corpus.unseal(case.get("requests",[]),"requests"),
   String(case.get("source","")),Corpus.unseal(case.get("protected_ids",[]),"protected_ids"))
  checked+=1
  if not result is Dictionary or not result.has("ok"): problems.append(String(case.get("case_id",""))+":result shape")
  elif result.ok: accepted+=1
  problems.append_array(_differences(String(case.get("case_id","")),before,_snapshot(g)))
 t.check(problems.is_empty() and checked==cases.size(),"ASSESS replacement_plan_leaves_live_state_unchanged: Replacement.plan restores every transaction runtime field (state object, resource feedback, sandbox depth) and leaves the whole encoded state unchanged (plan calls %d/%d; accepted %d; feedback seeded and sandbox depth alternately preset 0/1 before every call): %s" % [checked,cases.size(),accepted,str(problems.slice(0,3))])

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

