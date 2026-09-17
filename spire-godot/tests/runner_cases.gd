extends RefCounted
const Selection=preload("res://tests/suite_selection.gd")
const Index=preload("res://tests/check_index.gd")
const IndexEdges=preload("res://tests/check_index_edges.gd")

static func run(t) -> void:
 ownership(t)
 index(t)
 t.check(Selection.stage("home_persistence").begins_with("deferred") and Selection.stage("normal_play").begins_with("milestone"),"RUNNER deferred saves and long playthroughs remain explicitly scheduled")
 for name in ["card_power","card_expansion","relics"]:
  t.check(Selection.resolve(t.SUITES.keys(),[name]).selected==[name],"RUNNER current feature has its own complete scope "+name)
  for area in Selection.CROSS_AREAS.rewards:
   if area not in ["card_power","card_expansion","relics"]:
    t.check(name in Selection.resolve(t.SUITES.keys(),[area],true).selected,"RUNNER extracted feature keeps its former reward integration coverage: "+name+" / "+area)
 t.check(t.SUITES.values().all(func(suite):return suite==null or suite is String),"RUNNER registries contain resource paths so unselected suites are never preloaded")
 var names=t.SUITES.keys()
 t.check(Selection.resolve(names,["witch_character"]).selected==["witch_character"],"RUNNER witch character rules have an executable complete scope")
 for area in Selection.CROSS_AREAS.witch_character:
  t.check("witch_character" in Selection.resolve(names,[area],true).selected,"RUNNER witch character follows its affected boundary "+area)
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

# Derived check index self-check (docs/check-routing.md §3.4 i-viii and §6-G3).
# One derive() call feeds every check below, so the double coverage scan and the
# zero-drift comparison share a single pass over the corpus.
static func index(t) -> void:
 var derived=Index.derive()
 var frozen=Index.frozen()
 var failure=Index.frozen_error()
 t.check(failure=="","RUNNER index: frozen tests/check_index.json is readable with schema 1: "+failure)
 var comparison=Index.compare(derived,frozen)
 t.check(comparison.ok,"RUNNER index_matches_regeneration: frozen index equals the derivation; first difference: "+comparison.first_diff)
 var writer=derived.generated_from==String(frozen.get("generated_from","")) and derived.digest==String(frozen.get("digest",""))
 t.check(writer,"RUNNER index_regeneration_is_the_only_writer: digest and generated_from match the current inputs")
 _index_case_coverage(t,derived)
 var covered={}
 for suite in derived.suite_files.keys():
  for target in derived.suite_files[suite].keys():
   t.check(_index_target_exists(String(target)),"RUNNER index_targets_exist: "+String(target))
   covered[target]=true
 for path in derived.domains.keys(): covered[path]=true
 for path in derived.blind: covered[path]=true
 t.check(covered.size()>=int(derived.stats.sources_with_edges),"RUNNER index_skips_no_source_file: %d classified source targets" % covered.size())
 var exempt={}
 for entry in IndexEdges.SUITE_EXEMPT: exempt[String(entry.suite)]=true
 for kind in ["rule","ui"]:
  for name in derived.registries.get(kind,[]):
   var key=kind+":"+String(name)
   var reachable=derived.suite_files.has(key) and not derived.suite_files[key].is_empty()
   t.check(reachable or exempt.has(key),"RUNNER index_suites_are_all_reachable: "+key+" has derived edges or a documented exemption")
 var declared={}
 for entry in IndexEdges.BLIND_BY_DESIGN: declared[String(entry.path)]=true
 for path in derived.blind:
  t.check(declared.has(path),"RUNNER index_skips_no_source_file: "+path+" is blind and carries a BLIND_BY_DESIGN reason")
 for entry in IndexEdges.DOMAINS:
  for word in entry.domains:
   t.check(derived.domain_words.has(word) and derived.domain_words[word].size()>0,"RUNNER index_declared_domains_exist: DOMAINS word %s (%s) is used by the corpus" % [word,entry.path])
 for entry in IndexEdges.WIDEN:
  var add=String(entry.add)
  if not add.begins_with("impact:"): continue
  var area=add.trim_prefix("impact:")
  t.check(t.SUITES.has(area) or Selection.CROSS_AREAS.has(area) or area=="contact","RUNNER index_declared_domains_exist: WIDEN impact area is registered: "+area)
 var closed=true
 for entry in IndexEdges.INDEX_DEFECTS:
  closed=closed and String(entry.get("added",""))!="" and derived.domains.has(String(entry.path))
 t.check(closed,"RUNNER index_defects_stay_closed: every INDEX_DEFECTS entry still carries its added edge or domain")
 _index_route_examples(t)

static func _index_target_exists(target: String) -> bool:
 return FileAccess.file_exists("res://"+target.trim_prefix("spire-godot/"))

static func _index_case_coverage(t,derived: Dictionary) -> void:
 var directory=DirAccess.open("res://tests")
 if directory==null:
  t.check(false,"RUNNER index_covers_every_case_file: res://tests is not readable")
  return
 for file in directory.get_files():
  if not file.ends_with("_cases.gd"): continue
  if not FileAccess.get_file_as_string("res://tests/"+file).contains("static func run("): continue
  var key="spire-godot/tests/"+file
  t.check(derived.case_files.has(key),"RUNNER index_covers_every_case_file: "+file+" is in the frozen index")
  if not derived.case_files.has(key): continue
  var owner=String(derived.case_files[key].owner)
  var parts=owner.split(":")
  var registered=parts.size()==2 and Array(derived.registries.get(parts[0],[])).has(parts[1])
  t.check(registered,"RUNNER index_covers_every_case_file: %s has owner %s from the registries" % [file,owner])

# §6-G3, pinned to the measured derivation; these are the routing contract's examples.
static func _index_route_examples(t) -> void:
 var save=Index.suites_for(["spire-godot/core/save_store.gd"])
 t.check("persistence" in save.rules,"RUNNER route-save: an indexed save store selects persistence in the rule scope")
 t.check(["home","home_persistence","persistence"].all(func(name):return name in save.ui),"RUNNER route-save: an indexed save store selects the home and persistence UI modules")
 t.check(save.rows[0].signals.has("preload"),"RUNNER route-save: the preload signal is recorded for core/save_store.gd")
 t.check("architecture" in save.rules and "runner" in save.rules,"RUNNER route-core-append: core/** adds architecture and runner on top of the index edges")
 var ui_only=Index.suites_for(["spire-godot/ui/main.gd"])
 t.check(ui_only.rules.is_empty() and not ui_only.ui.is_empty(),"RUNNER route-ui-only: a UI file selects UI modules and no rule suite")
 var pack=Index.suites_for(["spire-godot/content/packs/abandoned_storeroom.json"])
 t.check("content" in pack.rules and pack.ui.is_empty() and "content" in pack.gates,"RUNNER route-content: a content pack selects its consumers plus the content gate, and no UI module")
 var owner=Index.suites_for(["spire-godot/tests/runner_cases.gd"])
 t.check(owner.rules==["runner"],"RUNNER route-owner: a case file routes to its owning suite")
 var domain=Index.suites_for(["spire-godot/core/snapshot.gd"])
 t.check("persistence" in domain.rules,"RUNNER route-snapshot-domain: the SAVE domain resolves a blind save file to persistence")
 var all_dev=Index.suites_for(["spire-godot/project.godot"])
 var blind=Index.suites_for(["spire-godot/core/tool_rules.gd"])
 t.check(blind.default_files.has("spire-godot/core/tool_rules.gd") and blind.rules==all_dev.rules,"RUNNER route-blind-closure: a BLIND_BY_DESIGN file falls to the core/** closure (all-dev) and is printed")
 t.check(not all_dev.ui.is_empty(),"RUNNER route-blind-closure: the module root closure also selects all-dev-ui")
 var docs=Index.suites_for(["docs/check-routing.md"])
 t.check(docs.ok and docs.rules.is_empty() and docs.ui.is_empty() and docs.declared_none.size()==1,"RUNNER route-declared-none: documentation changes select no suite and are never a pass")
 var unknown=Index.suites_for(["spire-godot/newdir/x.gd"])
 t.check(unknown.unmapped.has("spire-godot/newdir/x.gd") and unknown.rules==all_dev.rules and not unknown.ui.is_empty(),"RUNNER route-unmapped-fail-closed: an unknown directory is listed as unmapped and fail-closed to all-dev plus all-dev-ui")
 var outside=Index.suites_for(["outputs/build.zip"])
 t.check(not outside.ok and outside.error!="","RUNNER route-scope: a path outside spire-godot/ is refused before any engine phase")
 var empty=Index.suites_for([])
 t.check(not empty.ok,"RUNNER route-scope: an empty change set is refused instead of running nothing")
 t.check(not Index.suites_for(["spire-godot/core/save_store.gd"]).milestone.has("normal_play"),"RUNNER route-milestone: milestone suites never enter a routed scope")
 var unmapped=Index.suites_for(["spire-godot/newdir/x.gd"])
 t.check(not unmapped.rules.has("normal_play") and not unmapped.ui.has("baseline") and not unmapped.ui.has("normal_play"),"RUNNER route-milestone: all-dev and all-dev-ui are printed without milestone suites")
 t.check(unmapped.lines.any(func(line):return String(line).begins_with("ROUTE MILESTONE: declared baseline,normal_play;")),"RUNNER route-milestone: every plan prints the declared milestone list it deducts from")
 t.check(Index.suites_for(["spire-godot/ui/main.gd"]).milestone==["normal_play"],"RUNNER route-milestone: an index edge to a milestone suite is deducted and listed in the plan")
 t.check(Index.suites_for(["spire-godot/core/game.gd"]).notes.size()>0,"RUNNER route-oracle-note: oracle notes are attached to the files that need them")
