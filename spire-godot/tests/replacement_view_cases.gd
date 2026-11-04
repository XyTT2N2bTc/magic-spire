extends RefCounted

# S2b（D12／C-8）：只读视图 core/equipment_replacement_view.gd 的判据与判定入口的运行时只读不变量。
#
# 入口是 view_checks(t)，由 tests/test_game.gd 的 replacement 分支调用。本模块不是注册套件，
# 刻意不声明 `static func run(`（tests/check_index.gd::declares_run 只认行首真实声明），
# 形态与 tests/replacement_assess_cases.gd／replacement_corpus_cases.gd 相同。
#
# 判据（每条都能变红，敏感性见片报告的手工探针；本文件不登记 tests/mutations.json）：
#   1) view_dependency_edges：视图只依赖 data/* 与 core 谓词模块，不引判定／事务／game.gd；
#      对 g 的调用面双向登记（表外调用红、表内闲置红）；不写 state、不整份拷、不读 live rng、不碰读作用域。
#   2) view_builds_records_only_through_shared_builders：预览造件只经共用记录构造与准入。
#   3) view_migrated_functions_have_one_implementation：loadout 身份家族只在视图模块有一份实现。
#   4) assessment_leaves_live_state_unchanged：Assess.legal 连续两次后整份 encode(state)、rng、
#      _resource_feedback、_equipment_read、_rope_trial、_rope_observing 全等，g.state 引用未被替换。
#   5) legal_matches_plan_inside_scope：每例在 _begin_equipment_read() 作用域内再判一次，结果与存量 old.ok 相同。
#   6) can_apply_stops_at_the_first_legal_candidate：first_only 是同一判定路径的存在性读取。

const Assess=preload("res://core/equipment_replacement_assess.gd")
const View=preload("res://core/equipment_replacement_view.gd")
const Application=preload("res://core/equipment_application.gd")
const Corpus=preload("res://tests/replacement_corpus_cases.gd")
const AssessCases=preload("res://tests/replacement_assess_cases.gd")
const Arch=preload("res://tests/architecture_cases.gd")
const Store=preload("res://core/save_store.gd")
const Game=preload("res://core/game.gd")

const VIEW_SOURCE="core/equipment_replacement_view.gd"
# 视图模块预加载白名单（D12）：data/* 与三个 core 谓词模块；判定、事务与 game.gd 都不可达。
const VIEW_ALLOWED_EDGES=["res://data/equipment.gd","res://data/composites.gd","res://data/special_equipment.gd","res://data/links.gd","res://data/balance.gd","res://core/shoulder_links.gd","res://core/torso_binding.gd","res://core/witch_character.gd"]
const VIEW_FORBIDDEN_TOKENS=["res://core/game.gd","res://core/equipment_replacement_assess.gd","res://core/equipment_replacement.gd","res://ui","res://tests"]
# 视图对 g 的只读实例方法：预览造件、容器查询、随机复现与清理谓词。写入者（_cleanup／_install_*／
# _emit／_equipment_feedback／_random_index）都在表外。
const VIEW_INSTANCE_METHODS=["_component_kept","_composite_body","_equipment_in","_link_anchor_lost","_piece_released","_plan_assembly_in","_prepare_installation_in","_random_draw","_reinforcement_strap","_released","_root_head_orphaned","_special_install_reason_in","_special_piece","_strap_follows","_strap_orphaned","_template_piece","link_anchors_in","tier"]
# 共用记录构造与准入：视图只许经这些函数造件，别处出现字段表就是第二份实现。
const SHARED_BUILDERS=["_template_piece(","_special_piece(","_reinforcement_strap(","_plan_assembly_in(","_prepare_installation_in(","_special_install_reason_in(","Binding.resolve(","Binding.cancels(","Shoulders.pair_pieces("]

static func view_checks(t) -> void:
 var data=Corpus.load_corpus()
 # 固定切片沿用 tests/replacement_assess_cases.gd::_slice（同一实现，不另写外壳）。
 var slice=AssessCases._slice(data)
 print("VIEW SLICE cases=%d full_corpus=%d" % [slice.get("cases",[]).size(),data.get("cases",[]).size()])
 view_dependency_edges(t)
 view_builds_records_only_through_shared_builders(t)
 view_migrated_functions_have_one_implementation(t)
 assessment_leaves_live_state_unchanged(t,slice)
 legal_matches_plan_inside_scope(t,slice)
 can_apply_stops_at_the_first_legal_candidate(t,data.get("application_cases",[]))

static func view_dependency_edges(t) -> void:
 var text=Arch.source_code(VIEW_SOURCE)
 t.check(text.strip_edges()!="","VIEW view_dependency_edges: "+VIEW_SOURCE+" exists")
 # 载入探针：模块在套件里可加载并作答，源码判据不会在编译不过的脚本上全绿。
 t.check(View.empty(Game.new(1),0,{})["equipment"]==[],"VIEW view_dependency_edges: the view module loads from the suite and builds an empty prototype")
 var edges=[]
 var pattern=RegEx.new()
 pattern.compile("preload\\(\\s*\"([^\"]+)\"\\s*\\)")
 for hit in pattern.search_all(text): edges.append(hit.get_string(1))
 var extra=edges.filter(func(path):return not String(path) in VIEW_ALLOWED_EDGES)
 var forbidden=VIEW_FORBIDDEN_TOKENS.filter(func(token):return text.contains(String(token)))
 t.check(extra.is_empty() and forbidden.is_empty(),"VIEW view_dependency_edges: the view preloads only declared read-only edges and never names the judgment, the transaction, game.gd, ui/ or tests/: edges="+str(edges)+" extra="+str(extra)+" forbidden="+str(forbidden))
 var impure=[]
 for token in ["g.state=",".state.duplicate(","state.rng","_random_index(","_begin_equipment_read(","_equipment_read"]:
  if text.contains(token): impure.append(token)
 t.check(impure.is_empty(),"VIEW view_dependency_edges: the view never writes or copies live state, never reads the live rng and never touches the read scope (its draws go through a local counter copy): "+str(impure))
 var call=RegEx.new()
 call.compile("(?<![A-Za-z0-9_])g\\.([A-Za-z_][A-Za-z0-9_]*)\\s*\\(")
 var outside=[]
 var used=[]
 for hit in call.search_all(text):
  if not hit.get_string(1) in used: used.append(hit.get_string(1))
  if not hit.get_string(1) in VIEW_INSTANCE_METHODS and not hit.get_string(1) in outside: outside.append(hit.get_string(1))
 var idle=VIEW_INSTANCE_METHODS.filter(func(name):return not used.has(String(name)))
 t.check(outside.is_empty() and idle.is_empty(),"VIEW view_dependency_edges: every instance method the view calls is declared read-only and every declared method is really called, so the table is the observed surface: outside="+str(outside)+" idle="+str(idle))
 # 模块调用白名单与判定共用同一张表（ARCH ASSESS_MODULE_CALLS）：视图新增写入者必然表外。
 var module_call=RegEx.new()
 module_call.compile("(?<![A-Za-z0-9_])g\\.([A-Z][A-Za-z0-9_]*)\\.([A-Za-z_][A-Za-z0-9_]*)\\s*\\(")
 var undeclared=[]
 for hit in module_call.search_all(text):
  var allowed=Arch.ASSESS_MODULE_CALLS.get(hit.get_string(1),[])
  if not "*" in allowed and not hit.get_string(2) in allowed: undeclared.append(hit.get_string(1)+"."+hit.get_string(2))
 t.check(undeclared.is_empty(),"VIEW view_dependency_edges: the view's module calls are the same declared set as the judgment's (ASSESS_MODULE_CALLS); a write-capable function outside it is a write path: outside="+str(undeclared))

static func view_builds_records_only_through_shared_builders(t) -> void:
 var code=Arch.source_code(VIEW_SOURCE)
 var missing=SHARED_BUILDERS.filter(func(token):return not code.contains(String(token)))
 var literals=[]
 for token in Arch.FACTORY_RULE_TOKENS:
  if code.contains(String(token)): literals.append(token)
 t.check(missing.is_empty() and literals.is_empty(),"VIEW view_builds_records_only_through_shared_builders: the preview builds pieces through the shared record builders and admission functions only, and restates no record id prefix: missing="+str(missing)+" literals="+str(literals))

static func view_migrated_functions_have_one_implementation(t) -> void:
 var view=Arch.source_code(VIEW_SOURCE)
 var problems=[]
 for pair in Arch.VIEW_MIGRATED_PURE_FUNCTIONS:
  if not view.contains("static func "+String(pair[1])+"("): problems.append("view:"+pair[1])
  for other in ["core/equipment_replacement_assess.gd","core/equipment_replacement.gd"]:
   var text=Arch.source_code(other)
   if text.contains("func "+String(pair[0])+"(") or text.contains("func "+String(pair[1])+"("): problems.append(other+"::"+pair[1])
 t.check(not Arch.VIEW_MIGRATED_PURE_FUNCTIONS.is_empty() and problems.is_empty(),"VIEW view_migrated_functions_have_one_implementation: the loadout identity family lives only in the view module (the judgment and the transaction keep no body under the old or the new name): problems="+str(problems))

# 判定前后整份状态与运行时字段全等：Assess.legal 是只读事务。
static func assessment_leaves_live_state_unchanged(t, data: Dictionary) -> void:
 var problems=[]
 var checked=0
 var cases=data.get("cases",[])
 for case in cases:
  if problems.size()>=3: break
  var g=Corpus._fresh_game()
  g.state=Corpus._case_state(data,case)
  var trial_flag=checked%2==1
  var observing_flag=checked%2==0
  g._resource_feedback={"texts":["assess-legal-probe"]}
  g._rope_trial=trial_flag
  g._rope_observing=observing_flag
  var reference=g.state
  var text=JSON.stringify(Store.encode(g.state))
  var rng=JSON.stringify(g.state.rng)
  var read_scope=g._equipment_read
  var id=String(case.get("case_id",""))
  var requests=Corpus.unseal(case.get("requests",[]),"requests")
  var source=String(case.get("source",""))
  var protected_ids=Corpus.unseal(case.get("protected_ids",[]),"protected_ids")
  Assess.legal(g,requests,source,protected_ids)
  Assess.legal(g,requests,source,protected_ids)
  checked+=1
  if JSON.stringify(Store.encode(g.state))!=text: problems.append(id+":state changed")
  if JSON.stringify(g.state.rng)!=rng: problems.append(id+":rng changed")
  if g._resource_feedback!={"texts":["assess-legal-probe"]}: problems.append(id+":feedback changed")
  if not is_same(g._equipment_read,read_scope): problems.append(id+":read scope replaced")
  if g._rope_trial!=trial_flag: problems.append(id+":rope trial flag changed")
  if g._rope_observing!=observing_flag: problems.append(id+":rope observing flag changed")
  if not is_same(g.state,reference): problems.append(id+":state object replaced")
 t.check(problems.is_empty() and checked==cases.size() and checked>0,"VIEW assessment_leaves_live_state_unchanged: two Assess.legal calls leave the whole encoded state, the rng, the resource feedback, the read scope, the rope-trial and rope-observing flags unchanged and the state object by reference (checked %d/%d; feedback seeded and the two flags alternately preset): %s" % [checked,cases.size(),str(problems.slice(0,3))])

# 作用域内再判一次：视图恒走扫描，结果必须与存量 old.ok 相同；作用域不被重建，退出后复原。
static func legal_matches_plan_inside_scope(t, data: Dictionary) -> void:
 var mismatched=[]
 var scope_lost=[]
 var checked=0
 for case in data.get("cases",[]):
  var g=Corpus._fresh_game()
  g.state=Corpus._case_state(data,case)
  var requests=Corpus.unseal(case.get("requests",[]),"requests")
  var source=String(case.get("source",""))
  var protected_ids=Corpus.unseal(case.get("protected_ids",[]),"protected_ids")
  var expected=bool(case.get("old",{}).get("ok",false))
  var previous=g._begin_equipment_read()
  var opened=g._equipment_read
  var inside=Assess.legal(g,requests,source,protected_ids)
  var scope_kept=is_same(g._equipment_read,opened)
  g._equipment_read=previous
  checked+=1
  if inside!=expected: mismatched.append(String(case.get("case_id","")))
  if not scope_kept or JSON.stringify(g._equipment_read)!=JSON.stringify(previous): scope_lost.append(String(case.get("case_id","")))
 t.check(mismatched.is_empty() and checked>0,"VIEW legal_matches_plan_inside_scope: inside an open read scope the judgment returns the stored verdict for every case (the view never answers from the live index): checked=%d mismatched=%s" % [checked,str(mismatched.slice(0,5))])
 t.check(scope_lost.is_empty(),"VIEW legal_matches_plan_inside_scope: the read scope is neither rebuilt nor replaced around the judgment and is restored to its previous value: "+str(scope_lost.slice(0,5)))

# A37：can_apply 只做存在性读取——同一路径的首个合法即停，不另写第二套判定。
# 在应用层行的固定前 12 行上比较「完整枚举」与「首个即停」：首项相同、空集一致，且确有非空例；
# 全量 73 行由驱动 --mode=compare 覆盖（应用层返回逐项深比较）。
static func can_apply_stops_at_the_first_legal_candidate(t, applications: Array) -> void:
 var problems=[]
 var nonempty=0
 var checked=0
 var rows=applications.slice(0,12)
 var corpus=Corpus.load_corpus()
 for row in rows:
  var g=Corpus._fresh_game()
  g.state=Corpus._case_state(corpus,row)
  var raw=Corpus.unseal(row.get("raw",[]),"raw")
  var spec=Corpus.unseal(row.get("spec",{}),"spec")
  var source=String(row.get("source",""))
  var full=Application.legal_requests(g,raw,spec,source)
  var stop=Application.legal_requests(g,raw,spec,source,true)
  checked+=1
  if not full.is_empty(): nonempty+=1
  if stop.size()!=mini(1,full.size()): problems.append(String(row.get("case_id",""))+":size "+str(stop.size())+"/"+str(full.size()))
  elif not stop.is_empty() and JSON.stringify(stop[0])!=JSON.stringify(full[0]): problems.append(String(row.get("case_id",""))+":head differs")
 var body=Arch.source_function_body("core/equipment_application.gd","can_apply")
 t.check(problems.is_empty() and checked==rows.size() and nonempty>0 and body.contains("_choice_bands(g,spec,source,true)"),"VIEW can_apply_stops_at_the_first_legal_candidate: the existence read walks the same judgment and returns the first legal candidate of the full enumeration (or the same empty set) on every sampled application row, and can_apply asks only for the first band: checked=%d nonempty=%d problems=%s" % [checked,nonempty,str(problems.slice(0,5))])
