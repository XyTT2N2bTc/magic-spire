extends RefCounted

# S0 对拍基座：入库语料（tests/fixtures/replacement-corpus.json）的读取、判据与比较器。
# 判定接缝拆成两个入口（审查 F1／协调者 A9）：被测侧 judge_subject() 本片仍走现行路径，
# S2b 只改这一处；旧预言机 judge_oracle() 恒为 Replacement.plan，reoracle 只用它。
# 存量 old 结果只是同一预言机的缓存，reoracle 模式重调预言机验证未漂移。
#
# 入口是 `corpus_checks(t)`，由 tests/test_game.gd 的 `replacement` 分支调用。本模块不是注册套件，
# 所以刻意不声明 run 签名：tests/check_index.gd::declares_run() 只认行首真实的 static func run(
# 声明（注释与说明文本里的同名片段不计），本模块因此不是可执行用例文件，不要求注册套件做 owner；
# 注册表（SUITES）不在本片授权面内。
#
# 保型编码：语料里每个含数值的载荷——states[*].state，cases[*] 的 step／seed／
# protected_ids／requests／old／filtered_unsafe，application_cases[*] 的 raw／spec／returned，
# 以及 body 的 schema／source——都用 core/save_store.gd::encode 写出：数值叶变成
# {"@integer":"…"}／{"@float":"<16 hex>"}，因此语料正文没有裸数字，JSON.parse_string 读回后
# 不会把整数值 float 压成 int。读入一律经 _decode()（唯一 decode 通道：unseal() 取值、
# payload_issues() 只验可解）。本模块不另写任何
# float→int 压缩：那曾把 live 的 8.0 变成 8，而 core/equipment_replacement_assess.gd::same_loadout
# 用 Dictionary==／Array.find 比较，对 8 与 8.0 判不同，于是 20260906-00006 不可复现、
# 应用层行 20260906-L00384 也不复现。
#
# 入库语料是**判定边界抽样**（D21，规则版本 m2c-sampling/1，见 tmp/s2/m2c/sampling.md）：
# 全量源（3277 例／59 状态／73 应用层行）只留本地 gitignored 的 build/s0/corpus/，
# 其 sha256 与规则版本写在 manifest.sampling（full_source／full_source_sha256／rule／mixed_moments）。
# 抽样按 case_id 排序取边界代表，无随机、无手挑；每组成功例全留、每个失败理由桶留边界一例。
#
# 默认 `replacement` 套件只跑便宜面（新增耗时预算 ≤ 2 分钟）：
#   1) 语料完整性：逐状态／逐例 sha256、整文件 body sha256、清单计数；
#   2) 保型不变量：正文里没有裸数字（数值叶只能是 @integer／@float 对象）；
#   3) 自检模式：改坏固定小片的一例 old.ok，比较器必须恰好只报这一例；
#   4) 一个固定小切片对拍：固定 case_id／application case_id，不随语料排序漂移；
#   5) 21 例构造夹具（tag=fixture）全部对拍；
#   6) 混合时刻判据：全量源里同时有成功与失败例的时刻，入库后两侧都还在（D21 的抽样规则 A 由此可判红）。
# 全量对拍（含非入库例）是显式命令：把 --corpus 指向 build/s0/corpus/m2-full-merged.json；
# 命令与实测耗时只在驱动 tests/replacement_corpus_check.gd 的文件头维护一份，本文件不重复。
#
# 单一入口（语义 → 唯一符号；改路径须同批改本节）：
#   读取语料 → load_corpus()；数值解码 → _decode()（unseal()／payload_issues() 共用）；
#   正文与状态 sha256 → _digest()；深比较 → _json_same()；
#   切片封装 → _envelope()（subset()／fixture_subset() 共用）；比较器的 Game 复位 → _fresh_game()；
#   判定接缝 → judge_subject()（被测侧）／judge_oracle()（旧预言机）。判据名与断言只由 corpus_checks() 注册；本模块不声明 static run(。
const Replacement=preload("res://core/equipment_replacement.gd")
const Assess=preload("res://core/equipment_replacement_assess.gd")
const Application=preload("res://core/equipment_application.gd")
const Game=preload("res://core/game.gd")
const Store=preload("res://core/save_store.gd")

const DEFAULT_CORPUS="res://tests/fixtures/replacement-corpus.json"
# design.md §7.1 的 14 个覆盖类：新语料真实覆盖 5 类，21 例构造夹具补齐其余 9 类
# （含新加的 shackle_value／rope_locked／binding_synced_below_tier3）。
const REQUIRED_CLASSES=["protected","cursed","same_family_special","composite_groups",
 "random_variant","exact_fit","one_short","link_retained","link_lost","shoulder_loss",
 "binding_random_tier3","shackle_value","rope_locked","binding_synced_below_tier3"]
# 构造夹具的固定例数（tag=fixture）；删例或漏并都会让计数判据变红。
const FIXTURE_CASE_COUNT=21
const OLD_KEYS=["ok","reason","removed","installed","lost_links","score","comparisons"]
const AFTER_KEYS=["equipment","composites","special_equipment","links","next_equipment","next_composite"]
# 语料 body 的键：这些键下不允许出现裸数字（manifest 是文件自身清单，不计入 body）。
const BODY_KEYS=["schema","source","states","cases","application_cases"]
# 固定小切片（语料冻结后不改）：20260906 段最早的判定步 199／203／214／222，
# 含 candidate 与 execute_preview 两种 tag；避开 42 种子大集合例（单步 272–684 例）。
const SUITE_CASE_IDS=["20260906-00000","20260906-00001","20260906-00002","20260906-00003",
 "20260906-00004"]
# 应用层行同取该段全部 4 行（状态分别是步 199／203／214／222 的早步状态）。
const SUITE_APPLICATION_IDS=["20260906-L00289","20260906-L00295","20260906-L00311",
 "20260906-L00322"]
# 自检小片（同上，先于切片选取以控制默认套件耗时；同样取 20260906 段 199／203 两步）。
const SELFCHECK_CASE_IDS=["20260906-00000","20260906-00001"]

# ---- 保型编解码（唯一入口） ----

# 所有数值载荷的唯一 decode 通道：写侧（语料生成器）直接用 core/save_store.gd::encode，
# 本模块只读，故只有一个读入口。report=true 时打印域内错误（unseal 的调用方）；
# payload_issues() 只判可解性，不振铃。
static func _decode(value, what: String, report: bool=false) -> Dictionary:
 var decoded=Store.decode(value)
 if report and not decoded.get("ok",false):
  push_error("replacement corpus: damaged payload ("+what+"): "+String(decoded.get("error","")))
 return decoded

# 取值侧：语料损坏时返回 null 并打印域内错误；
# 判据 corpus_payloads_decode 会先把它变成红色断言。
static func unseal(value, what: String="payload"):
 var decoded=_decode(value,what,true)
 if not decoded.get("ok",false): return null
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

# 切片外壳：subset() 与 fixture_subset() 的唯一封装点。
static func _envelope(data: Dictionary, cases: Array, applications: Array) -> Dictionary:
 return {"schema":data.get("schema",{}),"source":data.get("source",{}),
  "states":data.get("states",{}),"cases":cases,"application_cases":applications,
  "manifest":data.get("manifest",{})}

# 固定小切片：按显式 id 取子集，顺序沿用语料；缺 id 时子集更小，调用方须断言数量。
static func subset(data: Dictionary, case_ids: Array, application_ids: Array) -> Dictionary:
 var cases=data.get("cases",[]).filter(func(row): return String(row.get("case_id","")) in case_ids)
 var applications=data.get("application_cases",[]).filter(func(row): return String(row.get("case_id","")) in application_ids)
 return _envelope(data,cases,applications)

# 构造夹具集合（tag=fixture）：默认套件全部对拍，不看固定 id 清单，新增夹具自动进面。
static func fixture_subset(data: Dictionary) -> Dictionary:
 var cases=data.get("cases",[]).filter(func(row): return String(row.get("tag",""))=="fixture")
 return _envelope(data,cases,[])

# ---- 被测侧接缝 ----
# 两个入口，各自只做一件事：
#   judge_subject  = 被测侧，S1 仍走现行路径；S2b 把 body 换成
#                    `Assess.legal(g,case.requests,case.source,case.protected_ids)` 即完成接线。
#   judge_oracle   = 旧预言机，恒为 Replacement.plan；reoracle 只用它，compare/selfcheck 不经过它。
# 判定布尔之外的理由字符串不作契约（旧 _legal_choices 不读它）。
static func judge_subject(g, case: Dictionary) -> bool:
 # S2b: the built-in judgment is the read-only view (A0-A8); the request normalization is the
 # same one legal_requests applies, so the corpus compares the wired path and not a variant.
 return Assess.legal(g,Application.request_specs(unseal(case.get("requests",[]),"requests")),
  String(case.get("source","")),unseal(case.get("protected_ids",[]),"protected_ids"))

static func judge_oracle(g, case: Dictionary) -> Dictionary:
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

# OLD_KEYS 投影的唯一入口：live 结果（project 后）与存量 old（unseal 后）共用；
# 存量损坏时 unseal 返回 null，这里退化为空投影，由比较判红。
static func old_entry(projected) -> Dictionary:
 var result={}
 if not projected is Dictionary: return result
 for key in OLD_KEYS: result[key]=projected.get(key)
 return result

# ---- 逐例对拍 ----

# 同一语义只有一条深比较路径：reoracle 的逐项结果与应用层返回数组都经它。
static func _json_same(left, right) -> bool:
 return JSON.stringify(left)==JSON.stringify(right)

# 每次对拍前重建 Game 并复位语料读取缓存：两个比较器共用这一个复位点（design.md §7.2）。
static func _fresh_game():
 var g=Game.new(0)
 g._equipment_read={}
 g._resource_feedback=null
 return g

# 状态每次从 encode 后的原文 decode 出新副本：调用方拿到的是独立对象，不需要再 duplicate。
static func _case_state(data: Dictionary, case: Dictionary) -> Dictionary:
 var entry=data.states.get(case.get("state",""),{})
 if not entry is Dictionary: return {}
 var state=unseal(entry.get("state",{}),"state "+String(case.get("state","")))
 return state if state is Dictionary else {}

# mode=compare：只比布尔（S2b 起的新判定契约）；mode=compare-scope：同一比较但每例在
# _begin_equipment_read() 打开的作用域内判定（视图必须绕开 live 索引）；mode=reoracle：逐项深比较旧结果。
# limit<0 表示全量；自检用很小的一片验证比较器能变红。
static func compare_judgments(data: Dictionary, mode: String="compare", limit: int=-1) -> Dictionary:
 var g=_fresh_game()
 var gamed=0
 var mismatches=[]
 var scope_lost=[]
 for case in data.get("cases",[]):
  if limit>=0 and gamed>=limit: break
  gamed+=1
  g.state=_case_state(data,case)
  var expected=case.get("old",{})
  var same=false
  var detail={}
  if mode=="reoracle":
   var actual=old_entry(project(judge_oracle(g,case)))
   var stored=old_entry(unseal(expected,"old"))
   same=_json_same(actual,stored)
   if not same: detail={"expected":stored,"actual":actual}
  elif mode=="compare-scope":
   var previous=g._begin_equipment_read()
   var opened=g._equipment_read
   var actual_ok=judge_subject(g,case)
   if not is_same(g._equipment_read,opened) or bool(g._equipment_read.get("invalid",false)): scope_lost.append(String(case.get("case_id","")))
   g._equipment_read=previous
   same=actual_ok==bool(expected.get("ok",false))
   if not same: detail={"expected":expected.get("ok",false),"actual":actual_ok}
  else:
   var actual_ok=judge_subject(g,case)
   same=actual_ok==bool(expected.get("ok",false))
   if not same: detail={"expected":expected.get("ok",false),"actual":actual_ok}
  if not same:
   mismatches.append({"case_id":String(case.get("case_id","")),"step":row_int(case,"step"),
    "tag":String(case.get("tag","")),"state":String(case.get("state","")),"detail":detail})
 return {"ok":mismatches.is_empty() and scope_lost.is_empty(),"checked":gamed,"mismatches":mismatches,"mode":mode,"scope_lost":scope_lost}

# 应用层结果：同一 (state, raw, spec, source) 上重放合法候选入口 legal_requests，逐项深比较返回数组。
# 被测侧从私有 _legal_choices 改指生产入口（审查 F2），避免只比别名。
static func compare_applications(data: Dictionary, limit: int=-1) -> Dictionary:
 var g=_fresh_game()
 var checked=0
 var mismatches=[]
 for row in data.get("application_cases",[]):
  if limit>=0 and checked>=limit: break
  checked+=1
  g.state=_case_state(data,row)
  var returned=Application.legal_requests(g,unseal(row.get("raw",[]),"raw"),
   unseal(row.get("spec",{}),"spec"),row.get("source",""))
  var expected=unseal(row.get("returned",[]),"returned")
  if not _json_same(returned,expected):
   mismatches.append({"case_id":row.get("case_id",""),"state":row.get("state",""),
    "expected":expected,"actual":returned})
 return {"ok":mismatches.is_empty(),"checked":checked,"mismatches":mismatches,"mode":"application"}

# 自检：改坏固定小片里第一例的 old.ok，要求比较器只报它；干净片必须全等。
# 返回 {ok, mutated, reported, clean_ok, detail}；默认套件与 check 驱动共用。
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

# 唯一的 sha256：逐状态摘要与整文件 body 摘要都走这里（manifest.file_sha256 按同一正文重算）。
static func _digest(value) -> String:
 return JSON.stringify(value).sha256_text()

# 清单冻结：每个 state 的 sha256 等于键名；整文件 body sha256 等于 manifest.file_sha256；
# 每条 case／application 行引用的 state 存在；清单计数与内容一致。
static func manifest_issues(data: Dictionary) -> Array:
 var issues=[]
 var states=data.get("states",{})
 for digest in states:
  var entry=states[digest]
  var state=entry.get("state",{}) if entry is Dictionary else {}
  var computed=_digest(state)
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
 var digest=_digest(body)
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
  if not _decode(state,"state "+String(digest)).get("ok",false): issues.append("state "+String(digest))
 for case in data.get("cases",[]):
  for key in ["requests","protected_ids","old","step","seed","filtered_unsafe"]:
   if not _decode(case.get(key,{}),"case "+String(case.get("case_id",""))+"."+key).get("ok",false):
    issues.append("case "+String(case.get("case_id",""))+"."+key)
 for row in data.get("application_cases",[]):
  for key in ["raw","spec","returned"]:
   if not _decode(row.get(key,{}),"application case "+String(row.get("case_id",""))+"."+key).get("ok",false):
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
  for name in case.get("classes",[]): seen[String(name)]=true
 for row in data.get("application_cases",[]):
  for name in row.get("classes",[]): seen[String(name)]=true
 var missing=[]
 for name in REQUIRED_CLASSES:
  if not seen.has(name): missing.append(name)
 return missing

# D21 敏感性判据：manifest.sampling.mixed_moments 是全量源里「同一判定时刻既有成功例又有失败例」的时刻清单。
# 入库语料必须在这每个时刻各保留 ≥1 成功与 ≥1 失败；抽样规则去掉「每组保留全部 ok=true」后这些时刻只剩失败例，
# 本判据即红。只对全量源里真有两种结果的时刻提要求（42:418／519／530 与 20260906:199／203／214 在全量源里
# 只有失败例，20260906:222 只有成功例，任何语料都满足不了「每个时刻都有两种结果」，故不按字面写）。
# 清单缺省或为空同样判红——否则本判据会被一份空清单悄悄废掉。
static func mixed_moment_issues(data: Dictionary) -> Array:
 var sampling=data.get("manifest",{}).get("sampling",{})
 var listed=sampling.get("mixed_moments",[]) if sampling is Dictionary else []
 if not listed is Array or listed.is_empty(): return ["manifest.sampling.mixed_moments is missing"]
 var shapes={}
 for case in data.get("cases",[]):
  var key="%d:%d" % [row_int(case,"seed"),row_int(case,"step")]
  if not shapes.has(key): shapes[key]={"ok":0,"fail":0}
  shapes[key]["ok" if bool(case.get("old",{}).get("ok",false)) else "fail"]+=1
 var issues=[]
 for key in listed:
  var shape=shapes.get(String(key),{"ok":0,"fail":0})
  if int(shape.ok)<1 or int(shape.fail)<1:
   issues.append("%s: ok=%d fail=%d" % [String(key),int(shape.ok),int(shape.fail)])
 return issues

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
 t.check(missing.is_empty(),"CORPUS corpus_covers_required_classes: all %d design classes have at least one case: %s" % [REQUIRED_CLASSES.size(),str(missing)])
 var mixed=mixed_moment_issues(data)
 var mixed_moments=Array(data.get("manifest",{}).get("sampling",{}).get("mixed_moments",[]))
 t.check(mixed.is_empty(),"CORPUS corpus_keeps_mixed_moments: every judgment moment that has both an accepted and a rejected case in the full source keeps at least one of each in the committed corpus (mixed moments %d, sampling rule %s): %s" % [mixed_moments.size(),String(data.get("manifest",{}).get("sampling",{}).get("rule","")),str(mixed)])
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
 print("CORPUS SUITE ms=%d integrity_ms=%d selfcheck_ms=%d compare_ms=%d fixture_ms=%d cases=%d application_cases=%d fixtures=%d mixed_moments=%d classes=%s" % [Time.get_ticks_msec()-started,integrity_ms,selfcheck_ms,compare_ms,fixture_ms,judgments.checked,applications.checked,fixture_judgments.checked,mixed_moments.size(),str(missing)])

static func run_selfcheck(data: Dictionary) -> Dictionary:
 return selfcheck(data,SELFCHECK_CASE_IDS)
