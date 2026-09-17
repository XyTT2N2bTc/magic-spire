extends SceneTree

# Plan host for -Changed / -ChangedList (docs/check-routing.md §2.3). Reads the
# frozen index only, prints the ROUTE lines and writes the plan JSON that
# tools/check.ps1 feeds into the rule/UI phases and into summary.route.
# Exit code 0 means the plan is usable (also for -ListOnly); 1 means refusal.

const Index=preload("res://tests/check_index.gd")

func _initialize() -> void:
 var files_path=""
 var plan_path=""
 var list_only=false
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--files="): files_path=arg.trim_prefix("--files=")
  if arg.begins_with("--plan="): plan_path=arg.trim_prefix("--plan=")
  if arg=="--list-only": list_only=true
 if files_path=="":
  print("ROUTE ERROR: --files=<path> is required")
  quit(1);return
 var files=_read_lines(files_path)
 if files.is_empty():
  print("ROUTE ERROR: empty change set in "+files_path+" (committed changes need -Since <ref>)")
  quit(1);return
 var result=Index.suites_for(files,"list" if list_only else "changed")
 for line in result.lines: print(line)
 if not result.ok:
  print("ROUTE ERROR: "+result.error)
  quit(1);return
 if plan_path!="":
  var plan={"schema":1,"mode":result.mode,"files":result.files,"files_sha256":result.files_sha256,
   "index_digest":result.index_digest,"rules":result.rules,"ui":result.ui,"gates":result.gates,
   "unmapped":result.unmapped,"default_files":result.default_files,"blind_files":result.blind_files,
   "declared_none":result.declared_none,"defect_hits":result.defect_hits,"widen":result.widen,
   "widen_candidates":result.widen_candidates,"milestone":result.milestone,"notes":result.notes,"rows":result.rows}
  var file=FileAccess.open(plan_path,FileAccess.WRITE)
  if file==null:
   print("ROUTE ERROR: cannot write "+plan_path)
   quit(1);return
  file.store_string(JSON.stringify(plan,"  ",true))
  file.close()
  print("ROUTE PLAN: "+plan_path)
 if list_only: print("PLAN ONLY: no game tests executed")
 quit(0)

# One repository-root relative path per line; blanks and # comments are ignored.
func _read_lines(path: String) -> Array:
 var out=[]
 var file=FileAccess.open(path,FileAccess.READ)
 if file==null: return out
 for line in file.get_as_text().split("\n"):
  var value=line.strip_edges()
  if value=="" or value.begins_with("#"): continue
  out.append(value)
 file.close()
 return out
