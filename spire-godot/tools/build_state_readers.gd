extends SceneTree

# State-reader table generator and zero-drift verifier (headless), mirroring
# tools/build_check_index.gd:
#  --verify (default): compare StateReaderScan.scan() with tests/state_readers.json and exit 1
#                      on the first difference (the judgement path is read-only; the judgments
#                      themselves are the three STATEREAD checks in tests/architecture_cases.gd).
#  --write           : re-derive and overwrite the frozen file; this is the only writer, and the
#                      result must be committed with the source change in the same commit.
# docs/spec/state-readers.md documents the scan口径 and the regeneration rule.

const Scan=preload("res://tests/state_reader_scan.gd")

func _initialize() -> void:
 var write=false
 for arg in OS.get_cmdline_user_args():
  if arg=="--write": write=true
 if write: _write();return
 _verify()

func _verify() -> void:
 var failure=Scan.frozen_error()
 if failure!="":
  print("STATE READERS FAIL: "+failure)
  quit(1);return
 var derived=Scan.scan()
 var comparison=Scan.compare(derived,Scan.frozen())
 if not comparison.ok:
  print("STATE READERS FAIL: frozen table is not the derivation, first difference at %s" % comparison.first_diff)
  print("STATE READERS ACTION: rerun tools/build_state_readers.gd --write and commit tests/state_readers.json with the source change.")
  print("STATE READERS STATS: %s" % Scan.canonical(derived.stats))
  quit(1);return
 var stats=derived.stats
 print("STATE READERS PASS: frozen table equals the derivation (sha256 %s)" % Scan.canonical(derived).sha256_text())
 print("STATE READERS STATS: %s" % Scan.canonical(stats))
 _report(derived)

func _write() -> void:
 var derived=Scan.scan()
 var file=FileAccess.open(Scan.FROZEN_PATH,FileAccess.WRITE)
 if file==null:
  print("STATE READERS FAIL: cannot write "+Scan.FROZEN_PATH)
  quit(1);return
 file.store_string(JSON.stringify(Scan.body(derived),"  ",true)+"\n")
 file.close()
 print("STATE READERS WRITE: %s" % Scan.FROZEN_PATH)
 print("STATE READERS STATS: %s" % Scan.canonical(derived.stats))
 _report(derived)

func _report(derived: Dictionary) -> void:
 var face=Scan.failure_face()
 print("STATE FAILURE FACE fields=%d cells=%d kinds=%d sites=%d" % [face.fields,face.cells,face.kinds,face.sites])
 for row in face.rows:
  if String(row[0])=="all": continue
  print("STATE FAILURE FACE kind=%s fields=%d cells=%d sites=%d" % [row[0],row[1].fields,row[1].cells,row[1].sites])
 print("STATE READERS REGISTRATIONS whole_state=%d aliases=%d schema_fields=%d unread=%s unknown=%d" % [derived.whole_state.size(),derived.aliases.size(),derived.schema_strings.size(),str(derived.unread_fields),derived.unknown.size()])
 quit(0)
