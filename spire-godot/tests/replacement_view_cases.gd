extends RefCounted

# S2b（D12／C-8）：只读视图 core/equipment_replacement_view.gd 的判据与判定入口的运行时只读不变量。
#
# 入口是 view_checks(t)，由 tests/test_game.gd 的 replacement 分支调用。本模块不是注册套件，
# 刻意不声明 `static func run(`（tests/check_index.gd::declares_run 只认行首真实声明），
# 形态与 tests/replacement_assess_cases.gd／replacement_corpus_cases.gd 相同。
#
# 判据（每条都能变红，敏感性见片报告的手工探针；本文件不登记 tests/mutations.json）：
#   1) view_dependency_edges：视图只依赖 data/* 与 core 谓词模块，不引判定／事务／game.gd；
#      对 g 的调用面双向登记（表外调用红、表内闲置红）；不写 state、不整份拷、不读 live rng、不碰读作用域；
#      不把 g.state 或其容器绑到局部别名（F5b：别名后的写入会绕过路径扫描）。
#   2) view_builds_records_only_through_shared_builders：预览造件只经共用记录构造与准入。
#   3) view_migrated_functions_have_one_implementation：loadout 身份家族只在视图模块有一份实现。
#   4) assessment_leaves_live_state_unchanged：Assess.legal 连续两次后整份 encode(state)、rng、
#      _resource_feedback、_equipment_read、_rope_trial、_rope_observing 全等，g.state 引用未被替换。
#   5) legal_matches_plan_inside_scope：每例在 _begin_equipment_read() 作用域内再判一次，结果与存量 old.ok 相同；
#      切片必须真的含三档固缚例（逐试算重置本地计数的复现路径），否则本条空转。
#   6) view_binding_draw_reproduces_the_live_refresh：视图刷新从 live 的 binding 计数起算、记录与计数推进
#      与 live 刷新相同，且不推进 live rng（A50 R2 的复现面）。
#   7) can_apply_stops_at_the_first_legal_candidate：first_only 是同一判定路径的存在性读取。
#   8) parallel_orchestrations_call_the_shared_rules（A50 R3 从 replacement_assess_cases.gd 迁入）：O1／O2／O3
#      三行编排在两端核对共用规则集合、视图端禁调 live 独有副作用，并按行核对 `# O<n>` 标记。Q8 按 CC-55
#      加 O4 配对行（kind → [live 工厂 token, 视图孪生 token]，按形状分派而非编号）：live 工厂集合与配对表
#      live 列双向相等、视图端每个非空孪生 token 都被调用；第 6 列（live 写口 token）在视图端出现即红。
#      A53 F5a：扫描面先剔除注释与字符串字面量，再按调用形态匹配，并把视图端模块内被调用的本地
#      助手按调用闭包展开——refresh 调 helper、helper 内 g._emit(…) 也红；只写字面量不再误红。
#   9) excluded_hooks_are_not_read_by_the_judgment（A52 F3）：排除钩子表非空、可达，且与 O3 的 live-only
#      token 双向覆盖；声明写键与判定读取集、四容器不相交；门控空操作钩子单列并逐字核对门控行。
#      A53 V4：四容器名单与 Arch.VIEW_FIELDS 的装备容器子集、state 字面量的 [] 初始化互钉。

const Assess=preload("res://core/equipment_replacement_assess.gd")
const View=preload("res://core/equipment_replacement_view.gd")
const Application=preload("res://core/equipment_application.gd")
const Corpus=preload("res://tests/replacement_corpus_cases.gd")
const AssessCases=preload("res://tests/replacement_assess_cases.gd")
const Arch=preload("res://tests/architecture_cases.gd")
const StateReaderScan=preload("res://tests/state_reader_scan.gd")
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
 view_binding_draw_reproduces_the_live_refresh(t,slice)
 can_apply_stops_at_the_first_legal_candidate(t,data.get("application_cases",[]))
 parallel_orchestrations_call_the_shared_rules(t)
 excluded_hooks_are_not_read_by_the_judgment(t)

# A52 F3（design §9 L2／rev3.1 §4.4）：排除钩子在判定里不执行，因此它们写的键不得被判定读取，钩子体也不得
# 写四个装备容器。三向核对：① 表非空、每行可在源侧到达（首跳在本表行或清理骨架里）、清理骨架的每个
# live-only token 都有登记行；② 判定读取集与声明的写键、四容器不相交，且源码扫描无容器写；③ 门控空操作
# 钩子与排除钩子分开登记、门控行逐字存在。读取集＝state_readers.json 的 assess／view 读键 ∪ 判定实际调用的
# <name>_in 别名键 ∪ RopeArt.locked 的 rope_master.master 读键。
static func _judgment_read_keys() -> Array:
 var frozen=StateReaderScan.frozen()
 var code=Arch.source_code("core/equipment_replacement_assess.gd")+Arch.source_code(VIEW_SOURCE)
 var keys={}
 for anchor in frozen.get("owners",{}):
  var parts=String(anchor).split("::")
  if parts.size()<2: continue
  if String(anchor).begins_with("core/equipment_replacement_assess.gd::") or String(anchor).begins_with(VIEW_SOURCE+"::") or (String(parts[1]).ends_with("_in") and code.contains(String(parts[1])+"(")):
   for key in frozen.owners[anchor]: keys[key]=true
 for anchor in frozen.get("aliases",{}):
  var parts=String(anchor).split("::")
  if parts.size()>1 and code.contains(String(parts[1])+"("):
   for key in frozen.aliases[anchor].get("fields",[]): keys[key]=true
 for key in frozen.get("owners",{}).get("core/rope_master.gd::master",{}): keys[key]=true
 return keys.keys()

# 钩子锚点 → 函数体（注释剔除）：与 architecture_cases 共用同一实现，不在此重抄一遍剔除循环。
static func _hook_body(anchor: String) -> String:
 var parts=String(anchor).split("::")
 return "" if parts.size()<2 else Arch.code_of_function(String(parts[0]),String(parts[1]))

# The live cleanup skeleton's anchor (Q6'a moved member-layer settlement into its own module, so the source
# function follows it; CC-36). The empty-chain token and the first hop both point here: one constant, two uses,
# so the same anchor is not written twice.
const LIVE_CLEANUP_SKELETON="core/equipment_removal.gd::settle"
# Live cleanup skeleton files: after Q6'a `_cleanup` is one delegation and the traversal order and bare
# predicate calls live in the new module; both files are the live end, so O3 must not fall into the
# transaction-trial branch just because the file was renamed (A166).
const LIVE_CLEANUP_SKELETON_FILES=["core/game.gd","core/equipment_removal.gd"]

static func _declared_hook(anchor: String) -> bool:
 for row in AssessCases.ASSESS_EXCLUDED_HOOKS:
  if String(row[0])==anchor: return true
 return false

# 四容器的写：赋值、索引赋值与就地增删。容器名单取自 AssessCases.EQUIPMENT_CONTAINERS，不在此重抄。
static func _container_write_hits(body: String) -> bool:
 var names="|".join(PackedStringArray(AssessCases.EQUIPMENT_CONTAINERS))
 var pattern="(?<![A-Za-z0-9_])(?:g\\.)?state\\s*(?:\\.\\s*(?:"+names+")|\\[\\s*\"(?:"+names+")\"\\s*\\])\\s*(?:\\.\\s*(?:erase|append|append_array|clear|remove_at|insert|sort|shuffle|push_back)\\s*\\(|(?:[-+*/]|<<|>>)?=(?!=))"
 return RegEx.create_from_string(pattern).search(body)!=null

# 到达：空链要求 token 出现在清理骨架里；非空链逐跳核对 token，首跳锚点须是登记行或清理骨架，末跳是该钩子的调用。
static func _hook_reachable(row: Array) -> bool:
 var name=String(row[0]).split("::")[1]
 var chain=row[3]
 if (chain as Array).is_empty(): return _hook_body(LIVE_CLEANUP_SKELETON).contains(String(row[2]))
 for i in range(chain.size()):
  var hop=chain[i]
  if not _hook_body(String(hop[0])).contains(String(hop[1])): return false
  if i==0 and String(hop[0])!=LIVE_CLEANUP_SKELETON and not _declared_hook(String(hop[0])): return false
 return String(chain[chain.size()-1][1])==name+"("

# A53 V4：EQUIPMENT_CONTAINERS 是容器写扫描（_container_write_hits）与排除钩子互钉的宽度来源。
# 名单只改一处（例如把 equipment 改名）会让扫描静默缩面，所以与两处权威声明互钉：
# ① architecture_cases::VIEW_FIELDS 去掉 next_* 计数键后的装备容器子集；② core/game.gd::_init 的
# state 字面量里逐个声明为 []（state 的装备容器就在那里初始化）。两处任一改名都会让本条红。
static func _equipment_containers_pin() -> Dictionary:
 var declared=[]
 for key in Arch.VIEW_FIELDS:
  if not String(key).begins_with("next_"): declared.append(String(key))
 declared.sort()
 var configured=AssessCases.EQUIPMENT_CONTAINERS.duplicate()
 configured.sort()
 var state_code=Arch.code_of_function("core/game.gd","_init")
 var uninitialized=[]
 for name in configured:
  var pattern=RegEx.new()
  if pattern.compile("\""+String(name)+"\"\\s*:\\s*\\[\\s*\\]")!=OK or pattern.search(state_code)==null: uninitialized.append(String(name))
 return {"declared":declared,"configured":configured,"uninitialized":uninitialized}

static func excluded_hooks_are_not_read_by_the_judgment(t) -> void:
 var phantom=[]
 var unreachable=[]
 var declared={}
 var container_writes=[]
 for row in AssessCases.ASSESS_EXCLUDED_HOOKS:
  var body=_hook_body(String(row[0]))
  if body.strip_edges()=="": phantom.append(String(row[0]))
  for key in row[1]: declared[String(key)]=true
  if _container_write_hits(body): container_writes.append(String(row[0]))
  if not _hook_reachable(row): unreachable.append(String(row[0]))
 var noop={}
 var gated=[]
 for row in AssessCases.TRANSACTION_NOOP_HOOKS:
  noop[String(row[0])]=true
  if not _hook_body(String(row[0])).contains(String(row[1])): gated.append(String(row[0]))
  if not Arch.source_code(String(row[3])).contains(String(row[2])): gated.append(String(row[0])+":uncalled")
 var live_only={}
 var unowned=[]
 for row in PARALLEL_ORCHESTRATIONS:
  if String(row[0])!="O3": continue
  for token in row[5]: live_only[String(token)]=true
 for row in AssessCases.ASSESS_EXCLUDED_HOOKS:
  if not live_only.has(String(row[2])): unowned.append(String(row[0])+":"+String(row[2]))
 var shared=noop.keys().filter(func(anchor):return _declared_hook(String(anchor)))
 var read_keys=_judgment_read_keys()
 var pin=_equipment_containers_pin()
 print("EXCLUDED HOOKS rows=%d noop=%d read_keys=%d live_only=%d containers=%s" % [AssessCases.ASSESS_EXCLUDED_HOOKS.size(),AssessCases.TRANSACTION_NOOP_HOOKS.size(),read_keys.size(),live_only.size(),str(pin.configured)])
 t.check(not AssessCases.ASSESS_EXCLUDED_HOOKS.is_empty() and phantom.is_empty() and unreachable.is_empty() and unowned.is_empty(),"VIEW excluded_hooks_are_not_read_by_the_judgment: the excluded-hook table is non-empty and every row resolves to a real body reachable from the live cleanup skeleton, while every live-only token of O3 is owned by a declared row (both directions): phantom="+str(phantom)+" unreachable="+str(unreachable)+" unowned="+str(unowned))
 var overlap=read_keys.filter(func(key):return declared.has(String(key)))
 var containers=AssessCases.EQUIPMENT_CONTAINERS.filter(func(key):return declared.has(String(key)))
 t.check(overlap.is_empty() and containers.is_empty() and container_writes.is_empty(),"VIEW excluded_hooks_are_not_read_by_the_judgment: no excluded hook writes a key the judgment reads or any of the four equipment containers (declared keys vs the derived read set, plus a source scan of each hook body for container writes): overlap="+str(overlap)+" containers="+str(containers)+" writes="+str(container_writes))
 t.check(not AssessCases.TRANSACTION_NOOP_HOOKS.is_empty() and gated.is_empty() and shared.is_empty(),"VIEW excluded_hooks_are_not_read_by_the_judgment: the transaction-noop hooks stay a separate table (gated no-ops are equivalent to not running them) and each gate line is present verbatim in its body: gated="+str(gated)+" shared="+str(shared))
 t.check(not pin.configured.is_empty() and pin.configured==pin.declared and pin.uninitialized.is_empty(),"VIEW excluded_hooks_are_not_read_by_the_judgment: EQUIPMENT_CONTAINERS equals the equipment containers of Arch.VIEW_FIELDS and each is declared as an empty array in the live state literal, so renaming a container on either side is red instead of silently narrowing the write scan: configured="+str(pin.configured)+" declared="+str(pin.declared)+" uninitialized="+str(pin.uninitialized))

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
 # A50 R2「禁写不禁读」：随机条款只禁写——索引形态写（state.rng[）与任何 g.state 路径赋值都红；
 # 读 state.rng.binding 计数以复现绑定抽取是允许的（视图现在经传入的本地计数副本复现，不读 live）。
 # 禁读会把复现路径本身变成不可能。_random_index( 仍是禁调项：它推进 live 计数。
 var impure=[]
 for token in ["g.state=",".state.duplicate(","state.rng[","_random_index(","_begin_equipment_read(","_equipment_read"]:
  if text.contains(token): impure.append(token)
 var writes=[]
 var write=RegEx.new()
 if write.compile("(?<![A-Za-z0-9_])g\\s*\\.\\s*state\\b(?:\\.[A-Za-z_][A-Za-z0-9_]*|\\[[^\\]]*\\])*\\s*(?:\\*\\*|<<|>>|\\+|-|\\*|/|%|&|\\||\\^)?=(?!=)")==OK:
  for hit in write.search_all(text): writes.append(hit.get_string().strip_edges())
 t.check(impure.is_empty() and writes.is_empty(),"VIEW view_dependency_edges: the view never writes or copies live state, never advances the live random entry and never touches the read scope (a g.state path assignment is a write; reading the binding count is allowed, its draws still go through a local counter copy): impure="+str(impure)+" writes="+str(writes))
 # A53 F5b：别名洗白。把 g.state 整份或它的容器直接绑到局部变量后，经别名的赋值与变异调用不再
 # 出现在 `g.state…` 路径上；故直接绑定一律红（与 ARCH assess_dependency_edges 共用同一实现）。
 # 从容器派生的副本（g.state.links.filter(...) 的返回值）不是 live 别名，保持允许。
 var aliases=Arch.state_alias_lines(text)
 t.check(aliases.is_empty(),"VIEW view_dependency_edges: the view never binds g.state or one of its equipment containers to a local alias (a write through the alias, var s=g.state then s.equipment=[], would be invisible to the path scan; derived filter/map copies stay allowed): "+str(aliases))
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
# 复现面（A50 R2）：判定把 live 的 binding 计数交给每个试算的本地副本；本条要求切片真的含
# 三档且带固缚记录的例（tier3_binding>0），否则「每个试算从 live 计数重置」无从被对拍覆盖。
static func legal_matches_plan_inside_scope(t, data: Dictionary) -> void:
 var mismatched=[]
 var scope_lost=[]
 var tier3_binding=0
 var checked=0
 for case in data.get("cases",[]):
  var g=Corpus._fresh_game()
  g.state=Corpus._case_state(data,case)
  for piece in g.state.equipment+g.state.special_equipment:
   if piece is Dictionary and piece.has("binding") and g.tier(piece.durability,piece.maximum)==3:
    tier3_binding+=1;break
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
 t.check(mismatched.is_empty() and checked>0 and tier3_binding>0,"VIEW legal_matches_plan_inside_scope: inside an open read scope the judgment returns the stored verdict for every case (the view never answers from the live index), and the slice really carries tier-three cases with a binding record so the per-trial counter reset is exercised: checked=%d tier3_binding=%d mismatched=%s" % [checked,tier3_binding,str(mismatched.slice(0,5))])
 t.check(scope_lost.is_empty(),"VIEW legal_matches_plan_inside_scope: the read scope is neither rebuilt nor replaced around the judgment and is restored to its previous value: "+str(scope_lost.slice(0,5)))

# The shoulder half of one case. A newly installed host carries no pair, so both sides are missing: the
# view refresh and the live refresh then read the one pair-record builder and the one missing-side
# rule. `filled` says the live end really built the left and the right piece, so the comparison cannot
# pass on an empty pair.
static func _shoulder_pair_differences(g, data: Dictionary, case: Dictionary, host: Dictionary) -> Dictionary:
 var view_host=host.duplicate(true)
 view_host.erase("shoulders")
 View.refresh(g,View.live(g,g.state.seed,{"binding":int(g.state.rng.binding)}),view_host)
 var g2=Corpus._fresh_game()
 g2.state=Corpus._case_state(data,case)
 var live_host=host.duplicate(true)
 live_host.erase("shoulders")
 g2.Shoulders.refresh(g2,live_host)
 if not view_host.has("shoulders") or not live_host.has("shoulders"): return {"filled":false,"differences":["no shoulder pair built"]}
 var differences=[]
 var view_pair: Dictionary=view_host.shoulders.duplicate(true)
 var live_pair: Dictionary=live_host.shoulders.duplicate(true)
 var view_pieces: Array=view_pair.pieces
 var live_pieces: Array=live_pair.pieces
 view_pair.erase("pieces");live_pair.erase("pieces")
 if JSON.stringify(view_pair)!=JSON.stringify(live_pair): differences.append("shoulder pair record differs")
 var view_sides=view_pieces.map(func(e):return e.side)
 var live_sides=live_pieces.map(func(e):return e.side)
 if view_sides!=live_sides: differences.append("shoulder sides "+str(view_sides)+"/"+str(live_sides))
 for side in g.Shoulders.SIDES:
  if JSON.stringify(view_pieces.filter(func(e):return e.side==side))!=JSON.stringify(live_pieces.filter(func(e):return e.side==side)): differences.append("shoulder "+side+" piece differs")
 return {"filled":live_sides==g.Shoulders.SIDES,"differences":differences}

# 随机复现面（A50 R2／中档加固「随机不推进＋binding 复现」）：视图刷新必须从 live 的 binding 计数起算，
# 复现 live 刷新的抽取结果，且不推进 live 计数。取切片里三档、可固缚的件并清掉它已有的固缚记录
# （新装件没有固缚，只有这个形状会真的抽 binding）：视图端 View.refresh 用 View.live 的本地计数副本，
# live 端 Binding.refresh 走 g._random_index；两端的记录逐字节相同、计数推进量相同，且视图端前后 live 的
# state.rng 不动。legal 的每次 trial 都新建 counts（{"binding":int(g.state.rng.binding)}），本条钉住这条接缝。
# CC-63 (G-Q9-2'): the same refresh also builds the tier-three shoulder pair, so the judgment compares
# the pair record and both side pieces of the view against the live Shoulders.refresh, item by item.
static func view_binding_draw_reproduces_the_live_refresh(t, data: Dictionary) -> void:
 var problems=[]
 var checked=0
 var draws=0
 var pair_problems=[]
 var hosts=0
 var pairs=0
 for case in data.get("cases",[]):
  var id=String(case.get("case_id",""))
  var g=Corpus._fresh_game()
  g.state=Corpus._case_state(data,case)
  var host={}
  for candidate in g.state.equipment:
   if candidate is Dictionary and g.tier(candidate.durability,candidate.maximum)==3 and g.Shoulders.eligible(candidate):
    host=candidate;break
  if not host.is_empty():
   hosts+=1
   var pair=_shoulder_pair_differences(g,data,case,host)
   if pair.filled: pairs+=1
   for difference in pair.differences: pair_problems.append(id+":"+difference)
  var piece={}
  for candidate in g.state.equipment:
   if not candidate is Dictionary: continue
   if g.tier(candidate.durability,candidate.maximum)!=3: continue
   if not g.Binding.eligible(candidate): continue
   piece=candidate;break
  if piece.is_empty(): continue
  checked+=1
  var start=int(g.state.rng.binding)
  var view=View.live(g,g.state.seed,{"binding":start})
  # A newly installed piece carries no binding record; only that shape draws (resolve keeps an old kind).
  var view_piece=piece.duplicate(true)
  view_piece.erase("binding")
  View.refresh(g,view,view_piece)
  if int(g.state.rng.binding)!=start: problems.append(id+":live rng advanced by the view refresh")
  var viewed=int(view.counters.get("binding",start))-start
  var g2=Corpus._fresh_game()
  g2.state=Corpus._case_state(data,case)
  var live_piece=piece.duplicate(true)
  live_piece.erase("binding")
  g2.Binding.refresh(g2,live_piece)
  var lived=int(g2.state.rng.binding)-start
  if not view_piece.has("binding") or not live_piece.has("binding"): problems.append(id+":no binding drawn")
  else:
   draws+=1
   if JSON.stringify(view_piece.binding)!=JSON.stringify(live_piece.binding): problems.append(id+":binding record differs")
  if viewed!=lived: problems.append(id+":counter delta "+str(viewed)+"/"+str(lived))
 print("VIEW BINDING DRAW checked=%d draws=%d" % [checked,draws])
 t.check(problems.is_empty() and checked>0 and draws>0,"VIEW view_binding_draw_reproduces_the_live_refresh: the view refresh starts every draw from the live binding counter, returns the same binding record as the live refresh and advances only its own counter (the live rng is untouched); the slice really carries tier-three pieces without a binding so a draw happens: checked=%d draws=%d problems=%s" % [checked,draws,str(problems.slice(0,5))])
 print("VIEW SHOULDER PAIR hosts=%d pairs=%d" % [hosts,pairs])
 t.check(pair_problems.is_empty() and hosts>0 and pairs==hosts,"VIEW view_binding_draw_reproduces_the_live_refresh: the same view refresh builds the tier-three shoulder pair the live refresh builds, with the pair record, the side order and the left and right pieces equal item by item; the slice really carries tier-three shoulder hosts and the live end fills both sides of each: hosts=%d pairs=%d problems=%s" % [hosts,pairs,str(pair_problems.slice(0,5))])

# A37：can_apply 只做存在性读取——同一路径的首个合法即停，不另写第二套判定。
# 抽样＝应用层前 12 行 ∪ 每个 spec.pool 的前 3 行（A50 存在性早停「多规格、多局面」）：
# 逐行比较「完整枚举」与「首个即停」——首项相同、空集一致；并要求样本真的跨池、跨状态、有非空例，
# 否则本条只在一种规格上空转。全量 73 行由驱动 --mode=compare 覆盖（应用层返回逐项深比较）。
static func _application_sample(applications: Array) -> Array:
 var picked=[]
 var seen={}
 var ids={}
 for row in applications.slice(0,12):
  picked.append(row);ids[String(row.get("case_id",""))]=true
 for row in applications:
  var spec=Corpus.unseal(row.get("spec",{}),"spec")
  var pool=String(spec.get("pool","")) if spec is Dictionary else "<bad>"
  var count=int(seen.get(pool,0))
  if count>=3: continue
  seen[pool]=count+1
  if ids.has(String(row.get("case_id",""))): continue
  picked.append(row);ids[String(row.get("case_id",""))]=true
 return picked

static func can_apply_stops_at_the_first_legal_candidate(t, applications: Array) -> void:
 var problems=[]
 var nonempty=0
 var checked=0
 var pools={}
 var states={}
 var rows=_application_sample(applications)
 var corpus=Corpus.load_corpus()
 for row in rows:
  var g=Corpus._fresh_game()
  g.state=Corpus._case_state(corpus,row)
  var raw=Corpus.unseal(row.get("raw",[]),"raw")
  var spec=Corpus.unseal(row.get("spec",{}),"spec")
  var source=String(row.get("source",""))
  pools[String(spec.get("pool",""))]=true
  states[String(row.get("state",""))]=true
  var full=Application.legal_requests(g,raw,spec,source)
  var stop=Application.legal_requests(g,raw,spec,source,true)
  checked+=1
  if not full.is_empty(): nonempty+=1
  if stop.size()!=mini(1,full.size()): problems.append(String(row.get("case_id",""))+":size "+str(stop.size())+"/"+str(full.size()))
  elif not stop.is_empty() and JSON.stringify(stop[0])!=JSON.stringify(full[0]): problems.append(String(row.get("case_id",""))+":head differs")
 var body=Arch.source_function_body("core/equipment_application.gd","can_apply")
 t.check(problems.is_empty() and checked==rows.size() and nonempty>1 and pools.size()>=2 and states.size()>1 and body.contains("_choice_bands(g,spec,source,true)"),"VIEW can_apply_stops_at_the_first_legal_candidate: the existence read walks the same judgment and returns the first legal candidate of the full enumeration (or the same empty set), across spec pools and states, and can_apply asks only for the first band: checked=%d nonempty=%d pools=%s states=%d problems=%s" % [checked,nonempty,JSON.stringify(pools.keys()),states.size(),str(problems.slice(0,5))])

# design §5「编排登记」：每行＝[编号, live 锚点, 视图锚点, 共用规则名单, 视图端是否尚未实现, live 独有副作用]。
# 名单非空且与 live 骨架的共用规则集合双向相等；视图端出现须调同一名单并同批翻标记；第 6 列在视图端出现即红。
# S2b 扩为多行（O1 判定试算、O2 视图刷新、O3 清理骨架）并按 A47 做逐行覆盖核对：每行在视图端或登记表所在
# 模块带 `# O<n>` 标记，标记集合与表的行号集合双向相等——删掉一行而表非空、或加了视图骨架却漏登记，都会红。
# A50 R3：O2 的视图端标记只能落在本模块（本片产品面只读，标记不写进 core）；两端的规则核对仍按 O1／O3 同形。
# A50 R1：本判据由 replacement_assess_cases.gd 迁入（它是 S2b 新增的视图类内容，C-8 把视图判据放本文件）。
const PARALLEL_ORCHESTRATIONS=[
 ["O1","core/equipment_replacement.gd::_trial","core/equipment_replacement_assess.gd::trial",
  ["action_targets(","pieces(","transfer_options(","compare(","same_loadout(","Equipment.validate(","Binding.validate(","Composites.validate(","Shoulders.validate","SpecialEquipment.validate(","Links.validate(","_capacity_issue(","link_anchors"],
  false,["_emit(","RopeArt.track(","_equipment_feedback(","Pressure.","Cards.","g._cleanup(","g._install(","g._write_durability(","_join_hooks("]],
 # O2 视图刷新：live _refresh_equipment 的口部命名、绑定记录与三档肩带在视图 refresh 上重放；反馈、事件
 # 与绳索追踪属 live 独有（RopeArt.track 见第 6 列），故共用规则集合按所属模块记账（两端都只经它们办这件事）。
 ["O2","core/game.gd::_refresh_equipment","core/equipment_replacement_view.gd::refresh",
  ["Binding.","Equipment.","Shoulders."],
  false,["RopeArt.track(","_emit(","_equipment_feedback(","Pressure.","Cards.","_tier_consequences(","_write_durability("]],
 ["O3",LIVE_CLEANUP_SKELETON,"core/equipment_replacement_view.gd::cleanup",
  ["_released","_strap_follows","_strap_orphaned","_piece_released","_root_head_orphaned","_component_kept","_link_anchor_lost"],
  false,["RopeArt.track(","_emit(","Pressure.","Cards.","_equipment_feedback(","_special_append(","_special_erase(","_member_changed("]],
 # O4 派发编排：live core/game.gd::_install_request 与视图 core/equipment_replacement_view.gd::install 按 kind
 # 配对（工厂 ↔ 准入孪生，CC-55）；link 的视图孪生为空，标「视图端无」。第 6 列同「视图端禁调 live 写口」。
 ["O4","core/game.gd::_install_request","core/equipment_replacement_view.gd::install",
  {"install":["_install_template(",["_prepare_installation_in(","_template_piece("]],
   "assembly":["_install_assembly(",["_plan_assembly_in("]],
   "special_install":["_install_special(",["_special_install_reason_in(","_special_piece("]],
   "link":["_install_link(",[]]},
  false,["_emit(","_equipment_feedback(","RopeArt.track(","_write_durability(","_special_erase(","_special_append(","_member_changed("]]]

# 登记表所在模块：O2 的行标记（A50 R3）与 O1／O3 的产品侧标记一起参与逐行覆盖核对。
const ORCHESTRATION_SOURCE="tests/replacement_view_cases.gd"

static func _source(relative: String) -> String:
 var file=FileAccess.open("res://"+relative,FileAccess.READ)
 return "" if file==null else file.get_as_text()

# A53 F5a：判据只看可执行的调用形态。注释与字符串字面量先剔除（字面量折成一个空格，保持 token
# 边界），于是函数体里写一句 "g.RopeArt.track(" 不再算调用；模块内被调用的本地助手按调用闭包
# 展开（最多 HELPER_EXPANSION_DEPTH 层，seen 防环），refresh -> helper -> g._emit( 也算 refresh 的调用面。
const HELPER_EXPANSION_DEPTH=3

static func _code_text(text: String) -> String:
 var out=[]
 var index=0
 var size=text.length()
 while index<size:
  var ch=text[index]
  if ch=="#":
   var end=text.find("\n",index)
   if end<0: break
   index=end
   continue
  if ch=="\"" or ch=="'":
   var quote=ch
   if text.substr(index,3)==quote+quote+quote:
    var close=text.find(quote+quote+quote,index+3)
    index=size if close<0 else close+3
   else:
    index+=1
    while index<size:
     var inner=text[index]
     if inner=="\\": index+=2; continue
     index+=1
     if inner==quote or inner=="\n": break
   out.append(" ")
   continue
  out.append(ch)
  index+=1
 return "".join(PackedStringArray(out))

# 函数体代码面（签名之后、下一个声明之前），注释与字符串字面量剔除。
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
 return _code_text(text.substr(hit.get_end(),end-hit.get_end()))

static func _declares_function(relative: String, name: String) -> bool:
 var declaration=RegEx.new()
 if declaration.compile("(?m)^(?:static\\s+)?func\\s+"+name+"\\s*\\(")!=OK: return false
 return declaration.search(_source(relative))!=null

# 调用闭包：本模块内被调用的顶层助手一并并入扫描面（深度受限，seen 防环）。
static func _expanded_code(relative: String, name: String, depth: int, seen: Dictionary) -> String:
 var code=_function_code(relative+"::"+name)
 if depth<=0: return code
 var call=RegEx.new()
 if call.compile("(?<![A-Za-z0-9_])([A-Za-z_][A-Za-z0-9_]*)\\s*\\(")!=OK: return code
 var extra=[]
 for hit in call.search_all(code):
  var helper=hit.get_string(1)
  if seen.has(helper) or not _declares_function(relative,helper): continue
  seen[helper]=true
  extra.append(_expanded_code(relative,helper,depth-1,seen))
 if extra.is_empty(): return code
 return code+"\n"+"\n".join(PackedStringArray(extra))

static func _expanded_function_code(site: String) -> String:
 var parts=site.split("::")
 if parts.size()<2: return ""
 var seen={String(parts[1]):true}
 return _expanded_code(String(parts[0]),String(parts[1]),HELPER_EXPANSION_DEPTH,seen)

# 声明项 -> 调用形态正则：`name(` 同名调用；`Module.` 模块前缀；`Module.func` 名称前缀
# （validate 对 validate_in）；裸名认同名或同族助手调用（link_anchors 对 link_anchors_in）。
static func _call_regex(token: String) -> RegEx:
 var text=String(token)
 var prefix="(?<![A-Za-z0-9_])"
 var pattern=""
 if text.ends_with("("): pattern=prefix+_regex_escape(text.trim_suffix("("))+"\\s*\\("
 elif text.ends_with("."): pattern=prefix+_regex_escape(text)+"[A-Za-z_][A-Za-z0-9_]*\\s*\\("
 elif text.contains("."): pattern=prefix+_regex_escape(text)+"[A-Za-z0-9_]*\\s*\\("
 else: pattern=prefix+_regex_escape(text)+"[A-Za-z0-9_]*\\s*\\("
 var regex=RegEx.new()
 return regex if regex.compile(pattern)==OK else null

static func _regex_escape(text: String) -> String:
 var escaped=""
 for index in range(text.length()):
  var ch=text[index]
  escaped+=("\\"+ch) if ch in [".","+","*","?","(",")","[","]","{","}","^","$","|","\\","/"] else ch
 return escaped

static func _declared_called(code: String, token: String) -> bool:
 var regex=_call_regex(token)
 return regex!=null and regex.search(code)!=null

# Shared cleanup rules = local functions the live skeleton calls bare and that are single-line pure predicates
# in core/game.gd: the source-side enumeration cross-checked both ways with the declared table. Since Q6'a the
# skeleton lives in its own module and calls predicates with the `g.` receiver (`g._released(`): strip that one
# receiver and resolve the bare name as before; the predicate body is still read from core/game.gd, so the
# single-line pure-predicate rule is unchanged (A166). Other receivers (`x._released(`) are not bare calls.
static func _shared_rule_calls(body: String) -> Array:
 var names=[]; var call=RegEx.new(); if call.compile("(?<![A-Za-z0-9_.])(?:g\\.)?(_[a-z][a-z0-9_]*)\\s*\\(")!=OK: return names
 for hit in call.search_all(body):
  var rest=Array(_function_code("core/game.gd::"+hit.get_string(1)).split("\n",false,1))
  var code=String(rest[1]).strip_edges() if rest.size()>1 else ""
  if not hit.get_string(1) in names and code.begins_with("return ") and not code.contains("\n") and not code.contains("_in(") and not code.contains("state."): names.append(hit.get_string(1))
 names.sort(); return names

# 行内 `Assess.<阶段>(` 的符号集：非 game.gd 侧的 live 骨架（O1 事务试算）用它与名单双向核对。
# failure 是失败形状构造，不是规则，单独豁免。
static func _assess_calls(body: String) -> Array:
 var names=[]; var call=RegEx.new()
 if call.compile("Assess\\.([A-Za-z_][A-Za-z0-9_]*)\\s*\\(")!=OK: return names
 for hit in call.search_all(body):
  if not hit.get_string(1) in names: names.append(hit.get_string(1))
 names.sort(); return names

# game.gd 侧 live 骨架的共用规则集合：裸谓词调用（O3 清理骨架）优先；没有裸谓词时（O2 刷新骨架把口部
# 命名、绑定与肩带交给所属模块）取去重后的 `Module.` 前缀。第 6 列的 live 独有副作用不是共用规则，剔除。
static func _live_shared_rules(body: String, live_only: Array) -> Array:
 var bare=_shared_rule_calls(body)
 if not bare.is_empty(): return bare
 var names=[]
 var call=RegEx.new()
 if call.compile("(?<![A-Za-z0-9_])([A-Z][A-Za-z0-9_]*)\\.[A-Za-z_][A-Za-z0-9_]*\\s*\\(")!=OK: return names
 for hit in call.search_all(body):
  var match_text=hit.get_string(0)
  if live_only.any(func(token):return _declared_called(match_text,String(token))): continue
  var token=String(hit.get_string(1))+"."
  if not token in names: names.append(token)
 names.sort(); return names

# 编排登记标记（A47 的逐行覆盖锚点）：产品侧骨架与登记表所在模块的 `# O<n>` 行注释。
static func _orchestration_marks() -> Array:
 var marks=[]
 var mark=RegEx.new()
 if mark.compile("(?m)^\\s*# (O[0-9]+)\\b")!=OK: return marks
 for relative in ["core/game.gd","core/equipment_replacement.gd","core/equipment_replacement_assess.gd","core/equipment_replacement_view.gd",ORCHESTRATION_SOURCE]:
  for hit in mark.search_all(_source(relative)):
   if not hit.get_string(1) in marks: marks.append(hit.get_string(1))
 marks.sort(); return marks

static func parallel_orchestrations_call_the_shared_rules(t) -> void:
 var malformed=[]; var uncalled=[]; var pending=[]; var aligned=[]; var live_only=[]
 for row in PARALLEL_ORCHESTRATIONS:
  if row.size()<6: malformed.append("row-size"); continue
  var pairing=row[3] is Dictionary
  var declared=[]
  if pairing:
   if (row[3] as Dictionary).is_empty(): malformed.append(String(row[0])+":row")
   for kind in (row[3] as Dictionary): declared.append_array(Array((row[3] as Dictionary)[kind][1]))
  else:
   declared=Array(row[3]).duplicate(); declared.sort(); if declared.is_empty(): malformed.append(String(row[0])+":row")
  if Array(row[5]).is_empty(): malformed.append(String(row[0])+":row")
  var live=_function_code(String(row[1])); var declare_pending=bool(row[4])
  if live.strip_edges()=="": malformed.append(String(row[1])+":missing")
  elif pairing:
   var live_factories=[]
   for kind in (row[3] as Dictionary): live_factories.append(String((row[3] as Dictionary)[kind][0]))
   for token in live_factories:
    if not _declared_called(live,String(token)): uncalled.append(String(row[1])+":"+String(token))
   for token in Arch._install_factory_tokens():
    if _declared_called(live,String(token)) and not live_factories.has(String(token)): uncalled.append(String(row[1])+":undeclared "+String(token))
  elif String(row[1]).split("::")[0] in LIVE_CLEANUP_SKELETON_FILES:
   # live 端是 game.gd 的编排骨架：共用规则集合与名单双向相等（O3 裸谓词、O2 模块前缀）。
   var called=_live_shared_rules(live,Array(row[5]))
   if called!=declared: uncalled.append(String(row[1])+": called="+str(called)+" declared="+str(declared))
  else:
   # live 端是事务试算：名单项须真被调用，且它调到的每个共用阶段都在名单内（failure 除外）。
   for token in declared:
    if not _declared_called(live,String(token)): uncalled.append(String(row[1])+":"+String(token))
   for name in _assess_calls(live):
    if name!="failure" and not declared.has(name+"("): uncalled.append(String(row[1])+":undeclared "+name)
  var view=_function_code(String(row[2]))
  if view.strip_edges()=="":
   if not declare_pending: uncalled.append(String(row[2])+":missing")
  else:
   if declare_pending: pending.append(String(row[0])+" -> "+String(row[2]))
   # A53 F5a：视图端按调用闭包展开（本模块助手一并计入），声明项与第 6 列都只认调用形态，
   # 字面量与注释不参与，所以新增 helper -> g._emit( 会红、仅写字面量 "g.RopeArt.track(" 不会红。
   var scanned=_expanded_function_code(String(row[2]))
   for name in declared:
    # 名单项既可以是函数名（补 "("）也可以是两端共有的前缀（例如 Shoulders.validate 对 live 的
    # validate( 与视图的 validate_in(；O2 的 Binding./Equipment./Shoulders. 同形）；两端都必须出现。
    if not _declared_called(scanned,String(name)): uncalled.append(String(row[2])+":"+String(name))
   for token in row[5]:
    if _declared_called(scanned,String(token)): live_only.append(String(row[2])+":"+String(token))
   var view_file=String(row[2]).split("::")[0]
   if not _source(view_file).contains("# "+String(row[0])) and not _source(ORCHESTRATION_SOURCE).contains("# "+String(row[0])): uncalled.append(String(row[2])+":mark")
   aligned.append(String(row[0]))
 var rows=[]
 for row in PARALLEL_ORCHESTRATIONS: rows.append(String(row[0]))
 rows.sort()
 var marks=_orchestration_marks()
 print("PARALLEL ORCHESTRATIONS aligned=%s pending_view=%s rows=%d marks=%s" % [str(aligned),str(pending),PARALLEL_ORCHESTRATIONS.size(),str(marks)])
 t.check(not PARALLEL_ORCHESTRATIONS.is_empty() and malformed.is_empty() and uncalled.is_empty(),"ASSESS parallel_orchestrations_call_the_shared_rules: the table is never empty, every row declares a shared-rule list and its live-only side effects, and each end of a row calls the rules its row lists (an emptied list, a deleted call or an unlisted rule is red): rows="+str(PARALLEL_ORCHESTRATIONS.size())+" malformed="+str(malformed)+" uncalled="+str(uncalled))
 t.check(live_only.is_empty(),"ASSESS parallel_orchestrations_call_the_shared_rules: the view end of an orchestration never runs a side effect that belongs to the live end alone (rope counting, events, pressure and card settlement, equipment feedback): live_only="+str(live_only))
 t.check(pending.is_empty(),"ASSESS parallel_orchestrations_call_the_shared_rules: a row declared as pending on the view side must not have that side yet -- S2b flips the marker in the same batch that adds the view skeleton, so the two skeletons cannot silently drift: appeared="+str(pending))
 # A47 逐行覆盖：每个登记标记都有一行、每行都有标记（产品侧骨架或登记表模块）；删一行而表非空同样红。
 t.check(marks==rows and aligned.size()==PARALLEL_ORCHESTRATIONS.size(),"ASSESS parallel_orchestrations_call_the_shared_rules: every registered orchestration is checked row by row and carries exactly one registration mark (deleting a row while the table stays non-empty, or adding a view skeleton without a row, is red): rows="+str(rows)+" marks="+str(marks)+" aligned="+str(aligned.size()))
