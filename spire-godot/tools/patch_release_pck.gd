extends SceneTree

# Mount the delivered PCK with --main-pack, then replace only explicitly selected
# compiled scripts from a fresh export. Other concurrent workspace edits stay out.
var options={}
var original_hashes={}

func _initialize() -> void:
 var args=OS.get_cmdline_user_args()
 for i in range(0,args.size(),2):
  if i+1<args.size(): options[args[i]]=args[i+1]
 run.call_deferred()

func require(ok: bool, message: String) -> bool:
 if not ok:
  push_error(message)
  quit(1)
 return ok

func files_at(path: String) -> Array:
 var result=[]
 var directory=DirAccess.open(path)
 if directory==null: return result
 directory.include_hidden=true
 directory.list_dir_begin()
 var name=directory.get_next()
 while name!="":
  if name not in [".",".."]:
   var child=path.path_join(name)
   if directory.current_is_dir(): result.append_array(files_at(child))
   else: result.append(child)
  name=directory.get_next()
 directory.list_dir_end()
 return result

func digest(bytes: PackedByteArray) -> String:
 var hash=HashingContext.new()
 hash.start(HashingContext.HASH_SHA256);hash.update(bytes)
 return hash.finish().hex_encode()

func stage(path: String) -> bool:
 if not require(path.begins_with("res://") and ".." not in path.split("/"),"Invalid resource path"): return false
 var bytes=FileAccess.get_file_as_bytes(path)
 var target=options["--staging"].path_join(path.trim_prefix("res://"))
 if not require(DirAccess.make_dir_recursive_absolute(target.get_base_dir())==OK,"Cannot create staging directory"): return false
 var file=FileAccess.open(target,FileAccess.WRITE)
 if not require(file!=null,"Cannot stage resource: "+path): return false
 file.store_buffer(bytes);file.close()
 return true

func compiled_path(script: String) -> String:
 var config=ConfigFile.new()
 if config.load(script+".remap")!=OK: return ""
 return str(config.get_value("remap","path",""))

func run() -> void:
 for key in ["--updated","--output","--staging","--scripts"]:
  if not require(options.has(key),"Missing argument "+key): return
 if not require(not FileAccess.file_exists("res://project.godot") and FileAccess.file_exists("res://project.binary"),"Base must be the delivered PCK"): return
 if not require(not FileAccess.file_exists(options["--output"]) and not DirAccess.dir_exists_absolute(options["--staging"]),"Patch output or staging already exists"): return
 var paths=files_at("res://")
 var replacements={}
 for script in options["--scripts"].split(",",false):
  var path="res://"+script
  var compiled=compiled_path(path)
  if not require(compiled!="" and compiled in paths,"Missing base compiled script: "+path): return
  replacements[path]=compiled
 for path in paths:
  original_hashes[path]=digest(FileAccess.get_file_as_bytes(path))
  if not stage(path): return
 if not require(ProjectSettings.load_resource_pack(options["--updated"],true),"Cannot mount updated export"): return
 var allowed=[]
 for script in replacements:
  var compiled=compiled_path(script)
  if not require(compiled!="" and FileAccess.file_exists(compiled),"Missing updated compiled script: "+script): return
  var previous=replacements[script]
  if previous!=compiled: paths.erase(previous)
  for path in [script+".remap",compiled]:
   if path not in paths: paths.append(path)
   allowed.append(path)
   if not stage(path): return
 var pack=PCKPacker.new()
 if not require(pack.pck_start(options["--output"])==OK,"Cannot open patch PCK"): return
 var changed=[]
 paths.sort()
 for path in paths:
  var staged=options["--staging"].path_join(path.trim_prefix("res://"))
  var hash=FileAccess.get_sha256(staged)
  if hash!=original_hashes.get(path,""):
   if not require(path in allowed,"Unexpected changed resource: "+path): return
   changed.append({"path":path,"before":original_hashes.get(path,""),"after":hash})
  if not require(pack.add_file(path,staged)==OK,"Cannot pack resource: "+path): return
 if not require(pack.flush()==OK,"Cannot finish patch PCK"): return
 var report=FileAccess.open(options["--output"]+".resources.json",FileAccess.WRITE)
 report.store_string(JSON.stringify({"resources":paths.size(),"scripts":replacements.keys(),"changed":changed},"  "))
 report.close()
 print("PATCH PCK PASS: ",paths.size()," resources; ",changed.size()," changed resources")
 quit(0)
