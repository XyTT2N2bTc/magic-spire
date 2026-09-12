extends RefCounted

# Presentation only. Never receives Game, state, candidates, or RNG.
signal locale_changed(locale: String)
const DEFAULT_LOCALE="zh_CN"
const LOCALES=["zh_CN","ja_JP"]
const DIRECTORY="res://assets/localization"
const DISPLAY_ERROR="文字暂时无法显示。"
const MAX_BYTES=4*1024*1024
var locale=DEFAULT_LOCALE
var _source: Dictionary={}
var _translations: Dictionary={}
var _diagnostics: Array=[]

func _init() -> void:
 load_directory()

static func supported(value: Variant) -> bool:
 return value is String and value in LOCALES

func set_locale(value: String) -> bool:
 if not supported(value): return false
 if locale!=value:
  locale=value
  locale_changed.emit(locale)
 return true

func diagnostics() -> Array:
 return _diagnostics.duplicate(true)

func _record(code: String, key: String="") -> void:
 var issue={"code":code,"key":key}
 if issue not in _diagnostics and _diagnostics.size()<256: _diagnostics.append(issue)

static func _shape(value: Variant, names: Array) -> bool:
 return value is Dictionary and value.size()==names.size() and names.all(func(key):return value.has(key))

static func _identifier(value: Variant) -> bool:
 if not value is String or value.is_empty(): return false
 for part in value.split("."):
  if part.is_empty() or not part.is_valid_identifier() or part!=part.to_lower(): return false
 for i in range(value.length()):
  if value.unicode_at(i)>127: return false
 return true

# Tokenize before substitution so parameter contents are always literal text.
static func _template(value: String) -> Dictionary:
 var tokens=[];var parameters={};var buffer="";var i=0
 while i<value.length():
  var ch=value[i]
  if ch in ["{","}"] and i+1<value.length() and value[i+1]==ch:
   buffer+=ch;i+=2;continue
  if ch=="}": return {"ok":false}
  if ch!="{": buffer+=ch;i+=1;continue
  var end=value.find("}",i+1)
  if end<0: return {"ok":false}
  var key=value.substr(i+1,end-i-1)
  if not _identifier(key) or key.contains("."): return {"ok":false}
  tokens.append({"literal":buffer});buffer=""
  tokens.append({"parameter":key});parameters[key]=parameters.get(key,0)+1
  i=end+1
 tokens.append({"literal":buffer})
 return {"ok":true,"tokens":tokens,"parameters":parameters}

static func _header(document: Variant, language: String) -> bool:
 return _shape(document,["schema_version","locale","messages"]) and document.schema_version==1 and document.locale==language and document.messages is Dictionary

func install_source(document: Variant) -> bool:
 if not _header(document,DEFAULT_LOCALE) or document.messages.is_empty():
  _record("invalid_source");return false
 var staged={}
 for key in document.messages:
  var entry=document.messages[key]
  if not _identifier(key) or not _shape(entry,["text","context"]) or not entry.text is String or entry.text.strip_edges().is_empty() or not entry.context is String or entry.context.strip_edges().is_empty():
   _record("invalid_source_entry",str(key));return false
  if not _template(entry.text).ok:
   _record("invalid_source_template",key);return false
  staged[key]=entry.duplicate(true)
 _source=staged
 # Existing translations must be validated against the new source version.
 _translations.clear()
 return true

func install_translation(language: String, document: Variant) -> bool:
 if not supported(language) or language==DEFAULT_LOCALE or not _header(document,language):
  _record("invalid_translation");return false
 var staged={}
 for key in document.messages:
  var entry=document.messages[key]
  if not _source.has(key) or not _shape(entry,["source","text"]) or not entry.source is String or not entry.text is String:
   _record("invalid_translation_entry",str(key));return false
  if entry.source!=_source[key].text:
   _record("stale_translation",key);return false
  if entry.text.strip_edges().is_empty(): continue
  var parsed=_template(entry.text)
  if not parsed.ok or parsed.parameters!=_template(entry.source).parameters:
   _record("translation_parameters",key);return false
  staged[key]=entry.text
 _translations[language]=staged
 return true

func _read(path: String) -> Variant:
 if not FileAccess.file_exists(path):
  _record("missing_file",path);return null
 var file=FileAccess.open(path,FileAccess.READ)
 if file==null:
  _record("unreadable_file",path);return null
 if file.get_length()>MAX_BYTES:
  _record("oversized_file",path);return null
 var json=JSON.new()
 if json.parse(file.get_as_text())!=OK:
  _record("invalid_json",path);return null
 return json.data

func load_directory(directory: String=DIRECTORY) -> bool:
 _diagnostics.clear()
 if not install_source(_read(directory.path_join(DEFAULT_LOCALE+".json"))): return false
 var valid=true
 for language in LOCALES:
  if language==DEFAULT_LOCALE: continue
  if not install_translation(language,_read(directory.path_join(language+".json"))): valid=false
 return valid

func coverage(language: String) -> Dictionary:
 var total=_source.size()
 var translated=total if language==DEFAULT_LOCALE else _translations.get(language,{}).size()
 return {"total":total,"translated":translated,"missing":total-translated}

func text(key: String, fallback: String, params: Dictionary={}) -> String:
 var selected=fallback
 if not _source.has(key): _record("unknown_key",key)
 elif _source[key].text!=fallback: _record("stale_callsite",key)
 else: selected=_translations.get(locale,{}).get(key,_source[key].text)
 var parsed=_template(selected)
 if not parsed.ok or params.size()!=parsed.parameters.size():
  _record("call_parameters",key);return DISPLAY_ERROR
 for name in parsed.parameters:
  if not params.has(name) or not (params[name] is String or params[name] is int or params[name] is float or params[name] is bool):
   _record("call_parameters",key);return DISPLAY_ERROR
  if params[name] is float and not is_finite(params[name]):
   _record("call_parameters",key);return DISPLAY_ERROR
 var result=""
 for token in parsed.tokens:
  result+=token.literal if token.has("literal") else str(params[token.parameter])
 return result

func font_names() -> PackedStringArray:
 if locale=="ja_JP": return PackedStringArray(["Yu Gothic UI","Meiryo","Noto Sans CJK JP","Microsoft YaHei UI","sans-serif"])
 return PackedStringArray(["Microsoft YaHei UI","Microsoft YaHei","sans-serif"])
