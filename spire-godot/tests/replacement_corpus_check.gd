extends SceneTree

# S0 语料对拍驱动（headless，独立于测试套件；默认套件不跑全量）：
#   --corpus=<path> --mode=compare   逐例被测侧（S0＝同一 Replacement.plan）vs 存量 old.ok，
#                                    并对拍应用层行的 returned（acceptance.md §4 的 compare 口径）
#   --corpus=<path> --mode=reoracle  重调旧预言机 Replacement.plan vs 存量逐项旧结果（只判定例：
#                                    design.md §7.2 把应用层返回划给 compare，reoracle 检的是预言机漂移）
#   --corpus=<path> --mode=selfcheck 在内存里改坏一例的 old.ok，要求比较器只报这一例
# 退出码：compare／reoracle 全等＝0，有差异＝1，语料缺失／参数错＝2；
# selfcheck 按 acceptance.md §2.2 以「恰好一例红」为非 0（1），比较器失灵＝2。
#
# 显式全量命令（保型语料 101 例／19 应用层行上实测：compare 191.6 s、reoracle 83.8 s；
# 默认 `replacement` 套件只跑完整性＋自检＋固定小切片＋12 例构造夹具）：
#   $env:GODOT_BIN='C:\1\Tools\Godot\v4.7.2-stable\Godot_v4.7.2-stable_win64_console.exe'
#   & $env:GODOT_BIN --headless --path . --script res://tests/replacement_corpus_check.gd -- --corpus=res://tests/fixtures/replacement-corpus.json --mode=compare
#   & $env:GODOT_BIN --headless --path . --script res://tests/replacement_corpus_check.gd -- --corpus=res://tests/fixtures/replacement-corpus.json --mode=reoracle
#   & $env:GODOT_BIN --headless --path . --script res://tests/replacement_corpus_check.gd -- --corpus=res://tests/fixtures/replacement-corpus.json --mode=selfcheck
#   --limit=N 截断判定例；--cases-only 只比判定例（应用层 0 行；reoracle 恒为此口径）。
const Cases=preload("res://tests/replacement_corpus_cases.gd")

func _init() -> void:
 var corpus=Cases.DEFAULT_CORPUS
 var mode="compare"
 var limit=-1
 var cases_only=false
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--corpus="): corpus=arg.trim_prefix("--corpus=")
  elif arg.begins_with("--mode="): mode=arg.trim_prefix("--mode=")
  elif arg.begins_with("--limit="): limit=int(arg.trim_prefix("--limit="))
  elif arg=="--cases-only": cases_only=true
 var data=Cases.load_corpus(corpus)
 if data.is_empty():
  print("CORPUS RESULT mode=%s ok=false error=corpus missing or unparsable path=%s" % [mode,corpus])
  quit(2)
  return
 var cases=data.get("cases",[])
 var applications=data.get("application_cases",[])
 print("CORPUS LOAD path=%s cases=%d application_cases=%d states=%d file_sha256=%s" % [corpus,cases.size(),applications.size(),data.get("states",{}).size(),String(data.get("manifest",{}).get("file_sha256",""))])
 if mode=="selfcheck":
  _selfcheck(data,limit)
  return
 var result={}
 if mode=="reoracle":
  result=Cases.compare_judgments(data,"reoracle",limit)
 else:
  result=Cases.compare_judgments(data,"compare",limit)
 # 应用层返回属 compare 口径（acceptance.md §4）；reoracle 只验旧预言机在判定例上未漂移。
 var application_result={"ok":true,"checked":0,"mismatches":[]}
 if mode!="reoracle" and not cases_only:
  application_result=Cases.compare_applications(data,limit)
 var ok=result.ok and application_result.ok
 print("CORPUS RESULT mode=%s ok=%s checked=%d mismatches=%d application_checked=%d application_mismatches=%d" % [mode,str(ok),result.checked,result.mismatches.size(),application_result.checked,application_result.mismatches.size()])
 if not result.mismatches.is_empty():
  print("CORPUS FIRST DIFF "+JSON.stringify(result.mismatches[0]))
 if not application_result.mismatches.is_empty():
  print("CORPUS FIRST APPLICATION DIFF "+JSON.stringify(application_result.mismatches[0]))
 quit(0 if ok else 1)

func _selfcheck(data: Dictionary, limit: int) -> void:
 var take=limit if limit>0 else 2
 var ids=[]
 for case in data.get("cases",[]).slice(0,take): ids.append(String(case.get("case_id","")))
 var result=Cases.selfcheck(data,ids)
 print("CORPUS RESULT mode=selfcheck ok=%s mutated=%s reported=%s clean_slice=%s" % [str(result.ok),String(result.mutated),JSON.stringify(result.reported),str(result.clean_ok)])
 if not result.detail.is_empty():
  print("CORPUS SELF DIFF "+JSON.stringify(result.detail))
 quit(1 if result.ok else 2)
