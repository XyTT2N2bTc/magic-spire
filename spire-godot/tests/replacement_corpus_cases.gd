extends RefCounted

# S0 对拍基座：入库语料（tests/fixtures/replacement-corpus.json）的读取、判据与比较器。
# 被测侧暂时由同一旧预言机 Replacement.plan 驱动（S1 起换成 Assess.legal，见 judge()）；
# 存量 old 结果只是同一预言机的缓存，reoracle 模式重调预言机验证未漂移。
#
# 入口是 `corpus_checks(t)`，由 tests/test_game.gd 的 `replacement` 分支调用。本模块不是注册套件，
# 所以刻意不声明 `static func run(`：tests/check_index.gd 把所有含该签名的 `*_cases.gd` 当作可执行
# 用例文件，要求它有一个注册套件做 owner；注册表（SUITES）不在本片授权面内。
#
# 保型编码（S0c）：语料里每个含数值的载荷——states[*].state，cases[*] 的 step／seed／
# protected_ids／requests／old／filtered_unsafe，application_cases[*] 的 raw／spec／returned，
# 以及 body 的 schema／source——都用 core/save_store.gd::encode 写出：数值叶变成
# {"@integer":"…"}／{"@float":"<16 hex>"}，因此语料正文没有裸数字，JSON.parse_string 读回后
# 不会把整数值 float 压成 int。读入一律经 unseal()（唯一 decode 入口）。本模块不另写任何
# float→int 压缩：那曾把 live 的 8.0 变成 8，而 core/equipment_replacement.gd::_same_loadout
# 用 Dictionary==／Array.find 比较，对 8 与 8.0 判不同，于是 20260906-00006 不可复现、
# 应用层行 20260906-L00384 也不复现。
#
# 默认 `replacement` 套件只跑便宜面（新增耗时预算 ≤ 2 分钟）：
#   1) 语料完整性：逐状态／逐例 sha256、整文件 body sha256、清单计数；
#   2) 保型不变量：正文里没有裸数字（数值叶只能是 @integer／@float 对象）；
#   3) 自检模式：改坏固定小片的一例 old.ok，比较器必须恰好只报这一例；
#   4) 一个固定小切片对拍：固定 case_id／application case_id，不随语料排序漂移；
#   5) S0b 的 12 例构造夹具（tag=fixture）全部对拍。
# 全量对拍是显式命令（S1 重构或验收时跑）：
#   & $env:GODOT_BIN --headless --path . --script res://tests/replacement_corpus_check.gd -- --corpus=res://tests/fixtures/replacement-corpus.json --mode=compare
#   & $env:GODOT_BIN --headless --path . --script res://tests/replacement_corpus_check.gd -- --corpus=res://tests/fixtures/replacement-corpus.json --mode=reoracle
const Replacement=preload("res://core/equipment_replacement.gd")
const Application=preload("res://core/equipment_application.gd")
const Game=preload("res://core/game.gd")
const Special=preload("res://data/special_equipment.gd")
const Store=preload("res://core/save_store.gd")

const DEFAULT_CORPUS="res://tests/fixtures/replacement-corpus.json"
# design.md §7.1 的 11 个覆盖类：S0a 的真实语料覆盖 5 类，S0b 的 12 例构造夹具补齐其余 6 类。
const REQUIRED_CLASSES=["protected","cursed","same_family_special","composite_groups",
 "random_variant","exact_fit","one_short","link_retained","link_lost","shoulder_loss",
 "binding_random_tier3"]
# S0b 构造夹具的固定例数（tag=fixture）；删例或漏并都会让计数判据变红。
const FIXTURE_CASE_COUNT=12
const OLD_KEYS=["ok","reason","removed","installed","lost_links","score","comparisons"]
const AFTER_KEYS=["equipment","composites","special_equipment","links","next_equipment","next_composite"]
# 语料 body 的键：这些键下不允许出现裸数字（manifest 是文件自身清单，不计入 body）。
const BODY_KEYS=["schema","source","states","cases","application_cases"]
# 语料的 type-faithful 编解码就是 core/save_store.gd::encode／decode，不另写第二套。
const CODEC="core/save_store.gd::encode|decode"
# 固定小切片（语料冻结后不改；取早期步 284／296／314，避开 946／957／969／971 的大集合例）。
const SUITE_CASE_IDS=["20260906-00000","20260906-00001","20260906-00002","20260906-00003"]
const SUITE_APPLICATION_IDS=["20260906-L00354","20260906-L00362","20260906-L00373"]
# 自检小片（同上，先于切片选取以控制默认套件耗时）。
const SELFCHECK_CASE_IDS=["20260906-00000","20260906-00001"]

# ---- 保型编解码（唯一入口） ----

# 写侧：语料生成器用同一个 encode；数值叶落成 @integer／@float 对象。
static func seal(value):
 return Store.encode(value)

# 读侧：所有数值载荷的唯一 decode。语料损坏时返回 null 并打印域内错误；
# 判据 corpus_payloads_decode 会先把它变成红色断言。
static func unseal(value, what: String="payload"):
 var decoded=Store.decode(value)
 if not decoded.get("ok",false):
  push_error("replacement corpus: damaged payload ("+what+"): "+String(decoded.get("error","")))
  return null
 return decoded.value

# 逐行数值元数据（step／seed／filtered_unsafe）与载荷走同一 codec；缺键或损坏时取兜底值。
static func row_int(row: Dictionary, key: String, fallback: int=-1) -> int:
 var value=unseal(row.get(key,{}),key)
 return value if value is int else fallback

# ---- 语料读取 ----

# 语料在磁盘上就是工作形态（数值叶已 encode），因此不做任何转换：manifest 的
# file_sha256 直接对同一份正文重算，也不需要把 int 还原成 int。
static func load_corpus(path: String=DEFAULT_CORPUS) -> Dictionary:
 if not FileAccess.file_exists(path): return {}
 var parsed=JSON.parse_string(FileAccess.get_file_as_string(path))
 if not parsed is Dictionary: return {}
 return parsed

# 固定小切片：按显式 id 取子集，顺序沿用语料；缺 id 时子集更小，调用方须断言数量。
static func subset(data: Dictionary, case_ids: Array, application_ids: Array) -> Dictionary:
 var cases=data.get("cases",[]).filter(func(row): return String(row.get("case_id","")) in case_ids)
 var applications=data.get("application_cases",[]).filter(func(row): return String(row.get("case_id","")) in application_ids)
 return {"schema":data.get("schema",{}),"source":data.get("source",{}),
  "states":data.get("states",{}),"cases":cases,"application_cases":applications,
  "manifest":data.get("manifest",{})}

# 构造夹具集合（tag=fixture）：默认套件全部对拍，不看固定 id 清单，新增夹具自动进面。
static func fixture_subset(data: Dictionary) -> Dictionary:
 var cases=data.get("cases",[]).filter(func(row): return String(row.get("tag",""))=="fixture")
 return {"schema":data.get("schema",{}),"source":data.get("source",{}),
  "states":data.get("states",{}),"cases":cases,"application_cases":[],
  "manifest":data.get("manifest",{})}

# ---- 被测侧接缝 ----
# S0 只有旧预言机；S1 起把 body 换成 `Assess.legal(g,case.requests,case.source,case.protected_ids)`。
# 判定布尔之外的理由字符串不作契约（旧 _legal_choices 不读它）。
static func judge(g, case: Dictionary) -> Dictionary:
 return Replacement.plan(g,unseal(case.get("requests",[]),"requests"),
  String(case.get("source","")),unseal(case.get("protected_ids",[]),"protected_ids"))

# 结果投影：installed 只留件字段（不含 _before／_after 整状态）；
# after 限定到判定可观察的容器与 rng.binding（design.md §5）。保留 live 的数值类型。
static func project(result: Dictionary) -> Dictionary:
 var installed=[]
 for item in result.get("installed",[]):
  if not item is Dictionary:
   installed.append(item)
   continue
  var copy=item.duplicate(true)
  copy.erase("_before")
  copy.erase("_after")
  installed.append(copy)
 var after={}
 var raw=result.get("_after",{})
 if raw is Dictionary and not raw.is_empty():
  for key in AFTER_KEYS: after[key]=raw.get(key)
  var rng=raw.get("rng",{})
  after["rng_binding"]=rng.get("binding",0) if rng is Dictionary else 0
 return {"ok":result.get("ok",false),"reason":result.get("reason",""),
  "removed":result.get("removed",[]),"installed":installed,
  "lost_links":result.get("lost_links",[]),"score":result.get("score",0),
  "comparisons":result.get("comparisons",[]),"after":after}

static func old_entry(projected: Dictionary) -> Dictionary:
 var result={}
 for key in OLD_KEYS: result[key]=projected.get(key)
 return result

# ---- 逐例对拍 ----

static func _prepare(data: Dictionary) -> Dictionary:
 return {"cases":data.get("cases",[]),"application_cases":data.get("application_cases",[]),
  "states":data.get("states",{})}

# 状态每次从 encode 后的原文 decode 出新副本：调用方拿到的是独立对象，不需要再 duplicate。
static func _case_state(data: Dictionary, case: Dictionary) -> Dictionary:
 var entry=data.states.get(case.get("state",""),{})
 if not entry is Dictionary: return {}
 var state=unseal(entry.get("state",{}),"state "+String(case.get("state","")))
 return state if state is Dictionary else {}

# mode=compare：只比布尔（S2 起的新判定契约）；mode=reoracle：逐项深比较旧结果。
# limit<0 表示全量；自检用很小的一片验证比较器能变红。
static func compare_judgments(data: Dictionary, mode: String="compare", limit: int=-1) -> Dictionary:
 var corpus=_prepare(data)
 var g=Game.new(0)
 var gamed=0
 var mismatches=[]
 g._equipment_read={}
 g._resource_feedback=null
 for case in corpus.get("cases",[]):
  if limit>=0 and gamed>=limit: break
  gamed+=1
  g.state=_case_state(corpus,case)
  var judged=judge(g,case)
  var expected=case.get("old",{})
  var same=false
  var detail={}
  if mode=="reoracle":
   var actual=old_entry(project(judged))
   same=JSON.stringify(actual)==JSON.stringify(_old_view(expected))
   if not same: detail={"expected":_old_view(expected),"actual":actual}
  else:
   same=bool(judged.get("ok",false))==bool(expected.get("ok",false))
   if not same: detail={"expected":expected.get("ok",false),"actual":judged.get("ok",false)}
  if not same:
   mismatches.append({"case_id":String(case.get("case_id","")),"step":row_int(case,"step"),
    "tag":String(case.get("tag","")),"state":String(case.get("state","")),"detail":detail})
 return {"ok":mismatches.is_empty(),"checked":gamed,"mismatches":mismatches,"mode":mode}

# 存量 old 全部经同一 decode 还原；理由与数值逐项按 live 类型比较。
static func _old_view(expected: Dictionary) -> Dictionary:
 var result={}
 var value=unseal(expected,"old")
 if not value is Dictionary: return result
 for key in OLD_KEYS: result[key]=value.get(key)
 return result

# 应用层结果：同一 (state, raw, spec, source) 上重放 _legal_choices，逐项深比较返回数组。
static func compare_applications(data: Dictionary, limit: int=-1) -> Dictionary:
 var corpus=_prepare(data)
 var g=Game.new(0)
 var checked=0
 var mismatches=[]
 g._equipment_read={}
 g._resource_feedback=null
 for row in corpus.get("application_cases",[]):
  if limit>=0 and checked>=limit: break
  checked+=1
  g.state=_case_state(corpus,row)
  var returned=Application._legal_choices(g,unseal(row.get("raw",[]),"raw"),
   unseal(row.get("spec",{}),"spec"),row.get("source",""))
  var expected=unseal(row.get("returned",[]),"returned")
  if JSON.stringify(returned)!=JSON.stringify(expected):
   mismatches.append({"case_id":row.get("case_id",""),"state":row.get("state",""),
    "expected":expected,"actual":returned})
 return {"ok":mismatches.is_empty(),"checked":checked,"mismatches":mismatches,"mode":"application"}

# 自检：改坏固定小片里第一例的 old.ok，要求比较器只报它；干净片必须全等。
# 返回 {ok, mutated, reported, clean_ok, detail}；S0a 默认套件与 check 驱动共用。
static func selfcheck(data: Dictionary, case_ids: Array=[]) -> Dictionary:
 var ids=case_ids.duplicate()
 if ids.is_empty():
  for case in data.get("cases",[]).slice(0,2): ids.append(String(case.get("case_id","")))
 var target=subset(data,ids,[])
 if target.get("cases",[]).is_empty():
  return {"ok":false,"mutated":"","reported":[],"clean_ok":false,"detail":{"error":"no cases"}}
 var clean=compare_judgments(target,"reoracle")
 var broken=target.duplicate(true)
 broken.cases=broken.cases.slice(0,1)
 var first=broken.cases[0]
 # old 是 encode 后的对象；ok 是布尔叶，翻转它不改其它字段。
 first.old.ok=not bool(first.old.ok)
 var detected=compare_judgments(broken,"reoracle")
 var reported=detected.mismatches.map(func(row): return String(row.case_id))
 var wanted=String(first.case_id)
 var ok=clean.ok and reported.size()==1 and reported[0]==wanted and reported[0]!=""
 return {"ok":ok,"mutated":wanted,"reported":reported,"clean_ok":clean.ok,
  "detail":detected.mismatches[0] if not detected.mismatches.is_empty() else {}}

# ---- 语料自证判据 ----

# 清单冻结：每个 state 的 sha256 等于键名；整文件 body sha256 等于 manifest.file_sha256；
# 每条 case／application 行引用的 state 存在；清单计数与内容一致。
static func manifest_issues(data: Dictionary) -> Array:
 var issues=[]
 var states=data.get("states",{})
 for digest in states:
  var entry=states[digest]
  var state=entry.get("state",{}) if entry is Dictionary else {}
  var computed=JSON.stringify(state).sha256_text()
  if computed!=String(digest): issues.append("state "+String(digest)+" recomputes to "+computed)
  var dropped=entry.get("dropped_keys",[]) if entry is Dictionary else []
  if not dropped.has("logs") or (state is Dictionary and state.has("logs") and not state.get("logs",[]).is_empty()):
   issues.append("state "+String(digest)+" did not drop logs to []")
 for case in data.get("cases",[]):
  if not states.has(case.get("state","")):
   issues.append("case "+String(case.get("case_id",""))+" references a missing state")
 for row in data.get("application_cases",[]):
  if not states.has(row.get("state","")):
   issues.append("application case "+String(row.get("case_id",""))+" references a missing state")
 var body={}
 for key in BODY_KEYS: body[key]=data.get(key)
 var digest=JSON.stringify(body).sha256_text()
 var manifest=data.get("manifest",{})
 if String(manifest.get("file_sha256",""))!=digest: issues.append("file_sha256 mismatch: "+digest)
 if int(manifest.get("case_count",-1))!=data.get("cases",[]).size(): issues.append("case_count mismatch")
 if int(manifest.get("application_case_count",-1))!=data.get("application_cases",[]).size(): issues.append("application_case_count mismatch")
 if int(manifest.get("state_count",-1))!=states.size(): issues.append("state_count mismatch")
 var fixtures=data.get("cases",[]).filter(func(row): return String(row.get("tag",""))=="fixture")
 if int(manifest.get("fixture_case_count",-1))!=fixtures.size(): issues.append("fixture_case_count mismatch")
 return issues

# 保型不变量：正文（schema／source／states／cases／application_cases）里不得出现裸数字。
# 裸数字会在 JSON.parse_string 后变成 float，整数值因此丢失类型，正是 S0c 修的缺陷。
static func body_number_issues(data: Dictionary) -> Array:
 var issues=[]
 for key in BODY_KEYS: _scan_numbers(data.get(key),key,issues)
 return issues

static func _scan_numbers(value, path: String, issues: Array) -> void:
 if issues.size()>=8: return
 if value is int or value is float:
  issues.append(path)
  return
 if value is Dictionary:
  for key in value: _scan_numbers(value[key],path+"."+String(key),issues)
 elif value is Array:
  for index in value.size(): _scan_numbers(value[index],"%s[%d]" % [path,index],issues)

# 每个数值载荷都能用同一 codec 还原（语料损坏时这里先红，而不是在逐例对拍里抛错）。
static func payload_issues(data: Dictionary) -> Array:
 var issues=[]
 for digest in data.get("states",{}):
  var entry=data.states[digest]
  var state=entry.get("state",{}) if entry is Dictionary else {}
  if not Store.decode(state).get("ok",false): issues.append("state "+String(digest))
 for case in data.get("cases",[]):
  for key in ["requests","protected_ids","old","step","seed","filtered_unsafe"]:
   if not Store.decode(case.get(key,{})).get("ok",false):
    issues.append("case "+String(case.get("case_id",""))+"."+key)
 for row in data.get("application_cases",[]):
  for key in ["raw","spec","returned"]:
   if not Store.decode(row.get(key,{})).get("ok",false):
    issues.append("application case "+String(row.get("case_id",""))+"."+key)
 return issues

# 过滤充分性：抓取时每例都跑过「完整 live state／只剔 logs 的 state／保型往返 state」三次
# 预言机，这里读记录；缺证或任一例 filtered_unsafe=1 即红。
static func filter_issues(data: Dictionary) -> Array:
 var issues=[]
 for case in data.get("cases",[]):
  if not case.has("filtered_unsafe"): issues.append("case "+String(case.get("case_id",""))+" has no filter proof")
  elif row_int(case,"filtered_unsafe",1)!=0: issues.append("case "+String(case.get("case_id",""))+" is filtered_unsafe")
 var manifest=data.get("manifest",{})
 if manifest.has("filtered_unsafe") and int(manifest.filtered_unsafe)!=0:
  issues.append("manifest filtered_unsafe="+str(manifest.filtered_unsafe))
 return issues

static func missing_classes(data: Dictionary) -> Array:
 var seen={}
 for case in data.get("cases",[]):
  for name in case.get("classes",[]): seen[name]=true
 for row in data.get("application_cases",[]):
  for name in row.get("classes",[]): seen[String(name)]=true
 var missing=[]
 for name in REQUIRED_CLASSES:
  if not seen.has(name): missing.append(name)
 return missing

# ---- 套件注册 ----

static func corpus_checks(t) -> void:
 var started=Time.get_ticks_msec()
 var data=load_corpus()
 var present=not data.is_empty()
 t.check(present,"CORPUS corpus_file_is_present: corpus file is present and parses: "+DEFAULT_CORPUS)
 if not present: return
 var integrity_started=Time.get_ticks_msec()
 var manifest=manifest_issues(data)
 t.check(manifest.is_empty(),"CORPUS corpus_manifest_is_frozen: state hashes, state references and file body hash match the manifest: "+str(manifest))
 var numbers=body_number_issues(data)
 t.check(numbers.is_empty(),"CORPUS corpus_body_is_type_faithful: every number in the corpus body is a SaveStore @integer/@float leaf, so JSON round-trips keep int and float apart: "+str(numbers))
 var payloads=payload_issues(data)
 t.check(payloads.is_empty(),"CORPUS corpus_payloads_decode: every numeric payload decodes through SaveStore.decode: "+str(payloads))
 var filters=filter_issues(data)
 t.check(filters.is_empty(),"CORPUS corpus_filter_is_sufficient: every case carries a three-way full/filtered/round-trip proof: "+str(filters))
 var missing=missing_classes(data)
 t.check(missing.is_empty(),"CORPUS corpus_covers_required_classes: all 11 design classes have at least one case: "+str(missing))
 var integrity_ms=Time.get_ticks_msec()-integrity_started
 var selfcheck_started=Time.get_ticks_msec()
 var picked=run_selfcheck(data)
 t.check(picked.ok,"CORPUS corpus_comparator_detects_mismatch: a deliberately broken old result is the only red case (mutated %s, reported %s)" % [String(picked.mutated),str(picked.reported)])
 var selfcheck_ms=Time.get_ticks_msec()-selfcheck_started
 var compare_started=Time.get_ticks_msec()
 var slice=subset(data,SUITE_CASE_IDS,SUITE_APPLICATION_IDS)
 t.check(slice.get("cases",[]).size()==SUITE_CASE_IDS.size(),"CORPUS corpus_slice_is_complete: fixed judgment slice has %d/%d cases" % [slice.get("cases",[]).size(),SUITE_CASE_IDS.size()])
 t.check(slice.get("application_cases",[]).size()==SUITE_APPLICATION_IDS.size(),"CORPUS corpus_slice_is_complete: fixed application slice has %d/%d cases" % [slice.get("application_cases",[]).size(),SUITE_APPLICATION_IDS.size()])
 var judgments=compare_judgments(slice,"compare")
 t.check(judgments.ok,"CORPUS corpus_matches_old_judgment (fixed slice): every fixed-slice boolean equals the stored oracle result (checked %d): %s" % [judgments.checked,str(judgments.mismatches.slice(0,3))])
 var applications=compare_applications(slice)
 t.check(applications.ok,"CORPUS application_results_match (fixed slice): every fixed-slice application row deep-equals the stored return value (checked %d): %s" % [applications.checked,str(applications.mismatches.slice(0,3))])
 var compare_ms=Time.get_ticks_msec()-compare_started
 var fixtures_started=Time.get_ticks_msec()
 var fixtures=fixture_subset(data)
 t.check(fixtures.get("cases",[]).size()==FIXTURE_CASE_COUNT,"CORPUS corpus_fixtures_are_present: the committed corpus carries all %d constructed fixtures (found %d)" % [FIXTURE_CASE_COUNT,fixtures.get("cases",[]).size()])
 var fixture_judgments=compare_judgments(fixtures,"compare")
 t.check(fixture_judgments.ok,"CORPUS corpus_fixtures_match_old_judgment: every constructed fixture boolean equals the stored oracle result (checked %d): %s" % [fixture_judgments.checked,str(fixture_judgments.mismatches.slice(0,3))])
 var fixture_ms=Time.get_ticks_msec()-fixtures_started
 print("CORPUS SUITE ms=%d integrity_ms=%d selfcheck_ms=%d compare_ms=%d fixture_ms=%d cases=%d application_cases=%d fixtures=%d classes=%s" % [Time.get_ticks_msec()-started,integrity_ms,selfcheck_ms,compare_ms,fixture_ms,judgments.checked,applications.checked,fixture_judgments.checked,str(missing)])

static func run_selfcheck(data: Dictionary) -> Dictionary:
 return selfcheck(data,SELFCHECK_CASE_IDS)
