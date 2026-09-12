extends SceneTree
const Game=preload("res://core/game.gd")
const Catalog=preload("res://core/content_catalog.gd")

func _initialize() -> void:
 # Check against built-ins without first installing the files being checked.
 Catalog.loaded=true
 var game=Game.new(1,false,"equipment",false)
 var path=Catalog.directory()
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--content-dir="): path=arg.trim_prefix("--content-dir=")
 if not DirAccess.dir_exists_absolute(path):
  print("CONTENT FAIL: directory does not exist: "+path);quit(1);return
 var input=Catalog.read_directory(path)
 var errors=input.errors
 if errors.is_empty(): errors=Catalog.compile(game,input.documents).errors
 for error in errors: print(error)
 if not errors.is_empty():
  print("CONTENT FAIL: %d issue(s); no definitions installed" % errors.size());quit(1);return
 print("CONTENT PASS: %d file(s); validated without changing game or saves" % input.documents.size())
 quit(0)
