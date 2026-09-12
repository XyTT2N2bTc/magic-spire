extends RefCounted
const Selection=preload("res://tests/suite_selection.gd")

static func run(t) -> void:
 ownership(t)
 t.check(Selection.stage("home_persistence").begins_with("deferred") and Selection.stage("normal_play").begins_with("milestone"),"RUNNER deferred saves and long playthroughs remain explicitly scheduled")
 for name in ["card_power","card_expansion","relics"]:
  t.check(Selection.resolve(t.SUITES.keys(),[name]).selected==[name],"RUNNER current feature has its own complete scope "+name)
  for area in Selection.CROSS_AREAS.rewards:
   if area not in ["card_power","card_expansion","relics"]:
    t.check(name in Selection.resolve(t.SUITES.keys(),[area],true).selected,"RUNNER extracted feature keeps its former reward integration coverage: "+name+" / "+area)
 t.check(t.SUITES.values().all(func(suite):return suite==null or suite is String),"RUNNER registries contain resource paths so unselected suites are never preloaded")
 var names=t.SUITES.keys()
 var direct=Selection.resolve(names,["casting","casting"])
 t.check(direct.ok and direct.selected==["casting"] and direct.reasons.casting=="requested","RUNNER focus mode executes only the named complete suite once")
 t.check(not Selection.resolve(names,["contact"]).ok and Selection.resolve(names,["contact"],true).ok,"RUNNER synthetic areas require explicit impact expansion")
 t.check(Selection.resolve(names,["runner","architecture"]).selected.size()==2,"RUNNER default fast checks never expand into gameplay or long runs")
 var saved=Selection.resolve(names,["persistence"],true).selected
 t.check("persistence" in saved and "special_equipment" in saved and "prison" in saved and "tower_progression" in saved and "normal_play" not in saved,"RUNNER save checks include prison and continued-run persistence without recursive expansion")
 var casting=Selection.resolve(names,["casting"],true).selected
 t.check("prison" in casting and "status" in casting and "rewards" in casting and "tower_progression" not in casting,"RUNNER related cross coverage included without recursive expansion")
 var a=Selection.resolve(names,["contact"],true).selected
 var b=Selection.resolve(names,["casting"],true).selected
 var merged=Selection.resolve(names,["contact","casting","contact"],true).selected
 t.check(merged.size()==merged.reduce(func(acc,x):acc[x]=true;return acc,{}).size() and (a+b).all(func(x):return x in merged),"RUNNER overlapping scopes execute every related suite exactly once")
 t.check(Selection.resolve(names,["all"],true).selected==names and not Selection.resolve(names,["all","typo"],true).ok and not Selection.resolve(names,[],true).ok,"RUNNER full coverage preserved and invalid selection rejected")
 var plan=Selection.resolve(names,["enemies"],true)
 t.check(plan.reasons.enemies=="requested" and plan.reasons.content=="cross: enemies" and plan.selected==plan.reasons.keys(),"RUNNER plan explains every selected module without changing scope")
 for area in ["core","enemies","equipment"]:
  var selected=Selection.resolve(names,[area],true).selected
  t.check("basic_attacks" in selected and "battle_saturation" in selected,"RUNNER attack and battle completion checks follow their affected area "+area)
 t.check("battle_saturation" in Selection.resolve(names,["application"],true).selected,"RUNNER installation changes include battle saturation coverage")
 var combined=Selection.resolve(names,["core","enemies","application"],true).selected
 t.check(combined.count("basic_attacks")==1 and combined.count("battle_saturation")==1,"RUNNER shared battle cases execute once across overlapping scopes")
 for id in Selection.SEED_SETS:
  var spec=Selection.SEED_SETS[id]
  var full=Selection.seeds(id,true);var daily=Selection.seeds(id,false)
  t.check(full==range(spec.count)+spec.get("extra",[]) and daily.size()>0 and daily.size()<full.size(),"RUNNER complete historical seed matrix retained "+id)
  t.check(daily.all(func(seed):return seed in full) and daily.size()==daily.reduce(func(acc,x):acc[x]=true;return acc,{}).size(),"RUNNER daily seeds form a deterministic unique subset "+id)
  var original=daily.duplicate();daily.clear()
  t.check(Selection.seeds(id,false)==original,"RUNNER sample calls cannot mutate the registry "+id)

# Follow actual run calls, not helper imports. A case must have exactly one owner.
static func ownership(t) -> void:
 var paths=t.SUITES.values().filter(func(path):return path is String)
 var ui=FileAccess.get_file_as_string("res://tests/ui_smoke.gd").split("func module_checks")[0]
 var registry=RegEx.new();registry.compile('"[^"\\n]+":\\s*"(res://tests/[^"\\n]+)"')
 for entry in registry.search_all(ui): paths.append(entry.get_string(1))
 var calls=RegEx.new();calls.compile(r'preload\("(res://tests/[^"]+)"\)\.run\(t(?:,|\))')
 var owners={}
 for path in paths: visit(t,path,path,owners,calls)
 var directory=DirAccess.open("res://tests")
 for file in directory.get_files():
  if file.ends_with("_cases.gd"):
   var path="res://tests/"+file
   if FileAccess.get_file_as_string(path).contains("static func run("):
    t.check(owners.has(path),"RUNNER executable test file has a registered owner: "+file)

static func visit(t,path: String,owner: String,owners: Dictionary,calls: RegEx) -> void:
 t.check(not owners.has(path),"RUNNER test executes only once across all categories: "+path)
 if owners.has(path): return
 owners[path]=owner
 for call in calls.search_all(FileAccess.get_file_as_string(path)):
  visit(t,call.get_string(1),owner,owners,calls)
