extends SceneTree

# Index generator and zero-drift verifier (headless), driven by tools/check-index.ps1.
#  --verify (default): compare CheckIndex.derive() with tests/check_index.json and
#                      exit 1 on the first difference (the judgement path is read-only).
#  --write           : re-derive and overwrite the frozen file; only -Write may do it,
#                      and the result must be committed with the source change.

const Index=preload("res://tests/check_index.gd")

func _initialize() -> void:
 var write=false
 for arg in OS.get_cmdline_user_args():
  if arg=="--write": write=true
 if write: _write();return
 _verify()

func _verify() -> void:
 var failure=Index.frozen_error()
 if failure!="":
  print("CHECK INDEX FAIL: "+failure)
  quit(1);return
 var derived=Index.derive()
 var comparison=Index.compare(derived,Index.frozen())
 if not comparison.ok:
  print("CHECK INDEX FAIL: frozen index is not the derivation, first difference at %s" % comparison.first_diff)
  print("CHECK INDEX ACTION: rerun tools/check-index.ps1 -Write and commit tests/check_index.json with the source change.")
  quit(1);return
 print("CHECK INDEX PASS: frozen index equals the derivation (digest %s)" % derived.digest)
 quit(0)

func _write() -> void:
 var derived=Index.derive()
 var file=FileAccess.open(Index.FROZEN_PATH,FileAccess.WRITE)
 if file==null:
  print("CHECK INDEX FAIL: cannot write "+Index.FROZEN_PATH)
  quit(1);return
 file.store_string(JSON.stringify(derived,"  ",true)+"\n")
 file.close()
 print("CHECK INDEX WRITE: %s" % Index.FROZEN_PATH)
 print("CHECK INDEX DIGEST: %s" % derived.digest)
 print("CHECK INDEX GENERATED FROM: %s" % derived.generated_from)
 print("CHECK INDEX STATS: %s" % JSON.stringify(derived.stats))
 quit(0)
