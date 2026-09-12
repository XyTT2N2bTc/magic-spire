extends SceneTree

# Run with the editor executable and --main-pack pointing at the release PCK.
# Official templates disable script overrides; the actual release gets a separate startup test.
var failures: Array[String]=[]

func check(ok: bool, message: String) -> void:
 if not ok:
  failures.append(message)
  push_error(message)

func _initialize() -> void:
 run.call_deferred()

func run() -> void:
 check(not FileAccess.file_exists("res://project.godot"),"Probe must load exported project.binary, not source files")
 check(ProjectSettings.get_setting("application/config/version","")=="0.15","Release version must be 0.15")
 check(not ResourceLoader.exists("res://tests/test_game.gd") and not ResourceLoader.exists("res://tools/check_content.gd"),"Development scripts must not be exported")
 var scene=load("res://main.tscn")
 check(scene!=null,"Main scene must be present in PCK")
 if scene==null:
  finish();return
 var catalog=load("res://core/content_catalog.gd")
 var game_class=load("res://core/game.gd")
 var fixture=game_class.new(42)
 if catalog.report.directory!=OS.get_environment("SPIRE_PROBE_CONTENT"):
  catalog.loaded=false
  catalog.ensure(fixture,OS.get_environment("SPIRE_PROBE_CONTENT"))
 var ui=scene.instantiate()
 ui.persistence_enabled=false
 root.add_child(ui)
 await process_frame
 await process_frame
 check(ui.show_home,"Standalone release opens its home screen")
 check(catalog.report.ok and catalog.report.files==12,"Standalone release loads all 12 distributed content packs")
 if not catalog.report.ok: print("RELEASE CONTENT ERRORS: ",catalog.report.errors)
 check(catalog.report.directory==OS.get_environment("SPIRE_PROBE_CONTENT"),"Content must come from the verified distribution path")
 var layer_data=JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/equipment-leg-layers.json"))
 check(layer_data is Array and not layer_data.is_empty(),"Dynamic equipment layer metadata must be included")
 if layer_data is Array:
  for entry in layer_data:
   check(load(entry.texture)!=null and load(entry.free_texture)!=null,"Dynamic equipment texture missing: "+str(entry.id))
 ui.restart(42)
 await process_frame
 await process_frame
 check(ui.game.validate()=="" and not ui.game.candidates().is_empty(),"New game has valid state and formal actions")
 var store=load("res://core/save_store.gd").new(OS.get_environment("SPIRE_PROBE_SAVES"))
 check(store.directory!="","Smoke saves need an explicit isolated directory")
 if store.directory!="":
  var saved=store.write_game(ui.game)
  check(saved.ok,"Exported release can save a scene checkpoint")
  var restored=store.read_slot(ui.game.state.save_slot)
  check(restored.ok,"Exported release can read its saved checkpoint")
  if restored.ok:
   var game=load("res://core/game.gd").new(7)
   check(game.restore_snapshot(restored.snapshot).ok and game.validate()=="","Exported release can restore its saved checkpoint")
 ui.restart(42,true,"equipment")
 await process_frame
 check(ui.view.practice and ui.game.validate()=="","Exported practice loads equipment and real action rules")
 print("RELEASE CONTENT PACKS: ",catalog.report.files)
 ui.queue_free()
 await process_frame
 finish()

func finish() -> void:
 if failures.is_empty(): print("RELEASE PROBE PASS")
 else: print("RELEASE PROBE FAIL: ",failures.size())
 quit(0 if failures.is_empty() else 1)
