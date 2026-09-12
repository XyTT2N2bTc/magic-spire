extends RefCounted
const Localizer=preload("res://ui/localization.gd")

static func source() -> Dictionary:
 return {"schema_version":1,"locale":"zh_CN","messages":{
  "test.line":{"text":"{name}：剩余{count}次（{name}）","context":"参数边界测试"},
  "test.braces":{"text":"{{名称}}：{name}","context":"字面大括号测试"},
  "test.other":{"text":"中文回退","context":"缺译测试"}
 }}

static func translation(messages: Dictionary) -> Dictionary:
 return {"schema_version":1,"locale":"ja_JP","messages":messages}

static func run(t) -> void:
 var l=Localizer.new()
 t.check(l.diagnostics().is_empty() and l.locale=="zh_CN","LOCALE shipped resources load locally and default to Chinese")
 t.check(l.coverage("zh_CN").total>0 and l.coverage("ja_JP").translated==0,"LOCALE Japanese scaffold contains no translated copy")
 t.check(l.set_locale("ja_JP") and l.text("ui.home.title","紧缚尖塔")=="紧缚尖塔","LOCALE empty Japanese resource uses the original Chinese")
 t.check(not l.set_locale("../../invalid") and l.locale=="ja_JP","LOCALE invalid language is rejected without changing preference")
 var spec=source()
 t.check(l.install_source(spec),"LOCALE accepts complete named source templates")
 var base=spec.messages["test.line"].text
 var values={"name":"测试","count":2.5}
 # Deliberately artificial text tests reordering; this is not a Japanese translation.
 var translated="{count} | {name} / {name}"
 t.check(l.install_translation("ja_JP",translation({"test.line":{"source":base,"text":translated}})),"LOCALE accepts reordered parameters with preserved occurrences")
 t.check(l.text("test.line",base,values)=="2.5 | 测试 / 测试","LOCALE names and decimal values survive reordering")
 spec.messages["test.line"].text="外部修改"
 t.check(l.text("test.line",base,values)=="2.5 | 测试 / 测试","LOCALE installed catalog does not retain writable source aliases")
 t.check(l.text("test.other","中文回退")=="中文回退" and l.coverage("ja_JP")=={"total":3,"translated":1,"missing":2},"LOCALE per-key fallback and coverage stay explicit")
 t.check(l.text("test.braces","{{名称}}：{name}",{"name":"{count}"})=="{名称}：{count}","LOCALE escape braces and substituted values are interpreted only once")
 t.check(l.text("test.line","新正文{count}",{"count":7})=="新正文7","LOCALE stale callsite uses its current original text, never old translation")
 t.check(l.text("unknown.id","保留原文")=="保留原文","LOCALE unknown IDs cannot leak to the player")
 for invalid in [{"name":"test"},{"name":"test","count":2,"extra":1},{"name":[],"count":2},{"name":"test","count":INF}]:
  t.check(l.text("test.line",base,invalid)==Localizer.DISPLAY_ERROR,"LOCALE invalid call parameters yield a safe display result")
 for bad in [null,{}, {"schema_version":2,"locale":"ja_JP","messages":{}}, translation({"unknown.id":{"source":"中文","text":"TEST"}}), translation({"test.line":{"source":"旧文","text":translated}}),translation({"test.line":{"source":base,"text":"{name} {count}"}}),translation({"test.line":{"source":base,"text":"{name} {count} {name} {extra}"}}),translation({"test.line":{"source":base,"text":"{name"}}),translation({"test.line":{"source":base,"text":12}})]:
  t.check(not l.install_translation("ja_JP",bad) and l.text("test.line",base,values)=="2.5 | 测试 / 测试","LOCALE invalid pack is rejected atomically without replacing accepted copy")
 var invalid_source=source();invalid_source.messages["test.other"].text="坏{"
 t.check(not l.install_source(invalid_source) and l.text("test.line",base,values)=="2.5 | 测试 / 测试","LOCALE invalid base is rejected atomically")
 t.check(l.install_translation("ja_JP",translation({"test.line":{"source":base,"text":""}})) and l.text("test.line",base,values)=="测试：剩余2.5次（测试）","LOCALE empty draft remains an untranslated key")
 var notes=l.diagnostics();notes.clear()
 t.check(not l.diagnostics().is_empty(),"LOCALE diagnostics are detached from the display and returned by copy")
 t.check(l.install_source(source()) and l.coverage("ja_JP").translated==0,"LOCALE a new source load invalidates previously loaded translation versions")
 file_fallbacks(t)

static func file_fallbacks(t) -> void:
 var folder="res://build/localization-fixture-%s" % OS.get_process_id()
 DirAccess.make_dir_recursive_absolute(folder)
 var base_path=folder.path_join("zh_CN.json")
 var target_path=folder.path_join("ja_JP.json")
 var l=Localizer.new()
 # Isolated build fixtures exercise IO failures, never the shipped assets.
 var file=FileAccess.open(base_path,FileAccess.WRITE)
 file.store_string(JSON.stringify(source()));file.close()
 t.check(not l.load_directory(folder) and l.diagnostics().any(func(d):return d.code=="missing_file"),"LOCALE absent target file is diagnosed without throwing a runtime error")
 l.set_locale("ja_JP")
 t.check(l.text("test.other","中文回退")=="中文回退","LOCALE absent target file leaves the loaded Chinese catalog usable")
 file=FileAccess.open(target_path,FileAccess.WRITE)
 file.store_string("{ invalid JSON");file.close()
 t.check(not l.load_directory(folder) and l.text("test.other","中文回退")=="中文回退","LOCALE malformed target JSON still displays Chinese")
 file=FileAccess.open(base_path,FileAccess.WRITE)
 file.store_string("[]");file.close()
 t.check(not l.load_directory(folder) and l.text("test.other","中文回退")=="中文回退","LOCALE invalid source file preserves the last accepted catalog")
 DirAccess.remove_absolute(base_path);DirAccess.remove_absolute(target_path);DirAccess.remove_absolute(folder)
 t.check(not l.load_directory(folder) and l.text("unregistered.message","调用处原文")=="调用处原文","LOCALE missing entire directory still uses inline original text")
