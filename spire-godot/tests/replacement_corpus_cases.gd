extends RefCounted

# S0 对拍基座：入库语料（tests/fixtures/replacement-corpus.json）的读取、判据与比较器。
# 被测侧暂时由同一旧预言机 Replacement.plan 驱动（S1 起换成 Assess.legal，见 judge()）；
# 存量 old 结果只是同一预言机的缓存，reoracle 模式重调预言机验证未漂移。
#
# 入口是 `corpus_checks(t)`，由 tests/test_game.gd 的 `replacement` 分支调用。本模块不是注册套件，
# 所以刻意不声明 `static func run(`：tests/check_index.gd 把所有含该签名的 `*_cases.gd` 当作可执行
# 用例文件，要求它有一个注册套件做 owner；注册表（SUITES）不在本片授权面内。
#
# 默认 `replacement` 套件只跑便宜面（新增耗时预算 ≤ 2 分钟）：
#   1) 语料完整性：逐状态／逐例 sha256、整文件 body sha256、清单计数；
#   2) 自检模式：改坏固定小片的一例 old.ok，比较器必须恰好只报这一例；
#   3) 一个固定小切片对拍：固定 case_id／application case_id，不随语料排序漂移。
# 全量对拍是显式命令（只在 S1 重构或验收时跑；抓取时的过滤双跑证明已逐例重调 Replacement.plan，
# 与一次全量 reoracle 等价，故本片不再重跑）：
#   & $env:GODOT_BIN --headless --path . --script res://tests/replacement_corpus_check.gd -- --corpus=res://tests/fixtures/replacement-corpus.json --mode=compare
#   & $env:GODOT_BIN --headless --path . --script res://tests/replacement_corpus_check.gd -- --corpus=res://tests/fixtures/replacement-corpus.json --mode=reoracle
const Replacement=preload("res://core/equipment_replacement.gd")
const Application=preload("res://core/equipment_application.gd")
const Game=preload("res://core/game.gd")
const Special=preload("res://data/special_equipment.gd")

const DEFAULT_CORPUS="res://tests/fixtures/replacement-corpus.json"
# design.md §7.1 的覆盖类；S0a 真实语料只覆盖前 5 类，后 6 类由 S0b 的构造夹具补齐（人裁 D8）。
const REQUIRED_CLASSES=["protected","cursed","same_family_special","composite_groups",
 "random_variant","exact_fit","one_short","link_retained","link_lost","shoulder_loss",
 "binding_random_tier3"]
const S0B_CLASSES=["cursed","exact_fit","one_short","link_retained","shoulder_loss","binding_random_tier3"]
const OLD_KEYS=["ok","reason","removed","installed","lost_links","score","comparisons"]
const AFTER_KEYS=["equipment","composites","special_equipment","links","next_equipment","next_composite"]
# 抓取行里过滤充分性未成立、因而整例排除的 case_id（计划 §5-S0.3「不得进入过滤语料」）。
# 20260906-00006（step 946）的差来自 JSON 数值往返（float→int 改变整除/比较），不是 logs：
# 保留完整 state 也复现不了生产结果，故整例不入库，只登记在语料 manifest.excluded_unsafe_cases。
const EXCLUDED_UNSAFE_CASES=["20260906-00006"]
# 固定小切片（语料冻结后不改；取早期步 284／296／314，避开 946／957／969／971 的大集合例）。
const SUITE_CASE_IDS=["20260906-00000","20260906-00001","20260906-00002","20260906-00003"]
const SUITE_APPLICATION_IDS=["20260906-L00354","20260906-L00362","20260906-L00373"]
# 自检小片（同上，先于切片选取以控制默认套件耗时）。
const SELFCHECK_CASE_IDS=["20260906-00000","20260906-00001"]

# ---- 语料读取 ----

static func load_corpus(path: String=DEFAULT_CORPUS) -> Dictionary:
 if not FileAccess.file_exists(path): return {}
 var parsed=JSON.parse_string(FileAccess.get_file_as_string(path))
 if not parsed is Dictionary: return {}
 return rehydrate(parsed)

# JSON 数值一律是 float；整数值还原成 int（存档快照与请求里的整数档位都靠它）。
static func rehydrate(value):
 if value is float:
  if is_finite(value) and value==floor(value) and absf(value)<9.0e15: return int(value)
  return value
 if value is Dictionary:
  var result={}
  for key in value: result[key]=rehydrate(value[key])
  return result
 if value is Array:
  var rows=[]
  for item in value: rows.append(rehydrate(item))
  return rows
 return value

# 固定小切片：按显式 id 取子集，顺序沿用语料；缺 id 时子集更小，调用方须断言数量。
static func subset(data: Dictionary, case_ids: Array, application_ids: Array) -> Dictionary:
 var cases=data.get("cases",[]).filter(func(row): return String(row.get("case_id","")) in case_ids)
 var applications=data.get("application_cases",[]).filter(func(row): return String(row.get("case_id","")) in application_ids)
 return {"schema":data.get("schema",1),"source":data.get("source",{}),
  "states":data.get("states",{}),"cases":cases,"application_cases":applications,
  "manifest":data.get("manifest",{})}

# ---- 被测侧接缝 ----
# S0 只有旧预言机；S1 起把 body 换成 `Assess.legal(g,case.requests,case.source,case.protected_ids)`。
# 判定布尔之外的理由字符串不作契约（旧 _legal_choices 不读它）。
static func judge(g, case: Dictionary) -> Dictionary:
 return Replacement.plan(g,case.requests,case.source,case.protected_ids)

# 结果投影：installed 只留件字段（不含 _before／_after 整状态）；
# after 限定到判定可观察的容器与 rng.binding（design.md §5）。
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
 return rehydrate({"ok":result.get("ok",false),"reason":result.get("reason",""),
  "removed":result.get("removed",[]),"installed":installed,
  "lost_links":result.get("lost_links",[]),"score":result.get("score",0),
  "comparisons":result.get("comparisons",[]),"after":after})

static func old_entry(projected: Dictionary) -> Dictionary:
 var result={}
 for key in OLD_KEYS: result[key]=projected.get(key)
 return result

# ---- 逐例对拍 ----

static func _prepare(data: Dictionary) -> Dictionary:
 var states={}
 for digest in data.get("states",{}):
  var entry=data.states[digest]
  states[digest]=entry.get("state",{}) if entry is Dictionary else {}
 return {"cases":data.get("cases",[]),"application_cases":data.get("application_cases",[]),
  "states":states}

static func _case_state(data: Dictionary, case: Dictionary) -> Dictionary:
 var entry=data.states.get(case.get("state",""),{})
 return entry.duplicate(true) if entry is Dictionary else {}

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
   mismatches.append({"case_id":case.get("case_id",""),"step":case.get("step",-1),
    "tag":case.get("tag",""),"state":case.get("state",""),"detail":detail})
 return {"ok":mismatches.is_empty(),"checked":gamed,"mismatches":mismatches,"mode":mode}

static func _old_view(expected: Dictionary) -> Dictionary:
 var result={}
 for key in OLD_KEYS: result[key]=expected.get(key)
 return revivify(result)

static func revivify(value):
 return rehydrate(value)

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
  var returned=Application._legal_choices(g,row.get("raw",[]),row.get("spec",{}),row.get("source",""))
  var expected=revivify(row.get("returned",[]))
  if JSON.stringify(revivify(returned))!=JSON.stringify(expected):
   mismatches.append({"case_id":row.get("case_id",""),"state":row.get("state",""),
    "expected":expected,"actual":revivify(returned)})
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
  if not dropped.has("logs") or (state.has("logs") and not state.get("logs",[]).is_empty()):
   issues.append("state "+String(digest)+" did not drop logs to []")
 for case in data.get("cases",[]):
  if not states.has(case.get("state","")):
   issues.append("case "+String(case.get("case_id",""))+" references a missing state")
 for row in data.get("application_cases",[]):
  if not states.has(row.get("state","")):
   issues.append("application case "+String(row.get("case_id",""))+" references a missing state")
 var body={"schema":data.get("schema",1),"source":data.get("source",{}),
  "states":data.get("states",{}),"cases":data.get("cases",[]),
  "application_cases":data.get("application_cases",[])}
 var digest=JSON.stringify(body).sha256_text()
 var manifest=data.get("manifest",{})
 if String(manifest.get("file_sha256",""))!=digest: issues.append("file_sha256 mismatch: "+digest)
 if int(manifest.get("case_count",-1))!=data.get("cases",[]).size(): issues.append("case_count mismatch")
 if int(manifest.get("application_case_count",-1))!=data.get("application_cases",[]).size(): issues.append("application_case_count mismatch")
 if int(manifest.get("state_count",-1))!=states.size(): issues.append("state_count mismatch")
 return issues

# 过滤充分性：抓取时每例都跑过「完整 state 与只剔 logs 的 state」两次预言机，这里读记录；
# 缺证或任一例 filtered_unsafe=1 即红。
static func filter_issues(data: Dictionary) -> Array:
 var issues=[]
 for case in data.get("cases",[]):
  if not case.has("filtered_unsafe"): issues.append("case "+String(case.get("case_id",""))+" has no filter proof")
  elif int(case.filtered_unsafe)!=0: issues.append("case "+String(case.get("case_id",""))+" is filtered_unsafe")
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
 var filters=filter_issues(data)
 t.check(filters.is_empty(),"CORPUS corpus_filter_is_sufficient: every case carries a full/filtered double-run proof: "+str(filters))
 var missing=missing_classes(data)
 var undeclared=missing.filter(func(name): return not S0B_CLASSES.has(String(name)))
 t.check(undeclared.is_empty(),"CORPUS corpus_covers_required_classes: only the declared S0b class gap is allowed: "+str(undeclared))
 var declared_unsafe=EXCLUDED_UNSAFE_CASES
 var excluded=Array(data.get("manifest",{}).get("excluded_unsafe_cases",[])).map(func(row): return String(row.get("case_id","")))
 t.check(excluded==declared_unsafe,"CORPUS corpus_exclusions_are_declared: the only capture rows kept out of the filtered corpus are the declared ones: "+str(excluded))
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
 print("CORPUS SUITE ms=%d integrity_ms=%d selfcheck_ms=%d compare_ms=%d cases=%d application_cases=%d excluded=%d declared_gap=%s" % [Time.get_ticks_msec()-started,integrity_ms,selfcheck_ms,compare_ms,judgments.checked,applications.checked,excluded.size(),str(missing)])

static func run_selfcheck(data: Dictionary) -> Dictionary:
 return selfcheck(data,SELFCHECK_CASE_IDS)
