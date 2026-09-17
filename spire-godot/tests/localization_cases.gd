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

# docs/event-pipeline-unification.md §17 (ruling A9): the legacy English catalog has to
# match the validator wording this slice rewrote — retired sources deleted, rewritten
# sources translated.
const REMOVED_SOURCES=[
 "事件必须在普通 choices 与多阶段 stages 中选择一种结构。",
  "普通事件需要1—6个选项，allow_refuse 必须为布尔值。",
  "多阶段事件分别在每个阶段填写 allow_refuse。",
  "多阶段事件需要 start_stage 和2—12个阶段。",
  "start_stage 必须引用已有阶段。",
  "阶段 id、标题、介绍、离开设置或选项不正确。",
  "阶段选项不能同时填写 recipe 与 effects。",
  "阶段选项至少需要 effects、recipe 或 outcomes。",
  "阶段选项使用了未知 recipe。",
  "阶段选项 effects 最多12项。",
  "带奖励的阶段选项目前必须结束事件，不能在领奖后继续下一阶段。",
  "阶段结果文案不正确。",
  "阶段预告文案不正确。",
  "阶段选项 id、文案或奖励不正确。",
  "阶段选择器：",
  "阶段条件需要恰好一个事件计数或选择来源，以及 equals/minimum/maximum。",
  "阶段条件的事件计数名无效。",
  "阶段条件的选择来源：",
  "阶段条件计数必须是0—100整数。",
  "选项必须且只能填写 recipe 或 effects 之一。",
  "空 effects 只能用于无奖励离开或战斗选项。",
  "临时保管只允许用于声明了收尾步骤的多阶段事件。",
  "effects 最多8个效果。",
  "未知 recipe。",
  "不支持的 reward。"]

const REQUIRED_SOURCES={
 "事件介绍不能为空或过长。": "The event introduction is empty or too long.",
  "事件必须填写 start_node。": "The event needs start_node.",
  "事件需要1—12个节点。": "An event needs 1-12 nodes.",
  "节点 id 无效或重复。": "A node id is invalid or duplicated.",
  "单节点事件的节点 id 必须为 choice。": "A single-node event has to use the id choice.",
  "单节点事件不得填写 title 或 intro。": "A single-node event must not declare title or intro.",
  "节点标题或介绍不正确。": "A node title or introduction is invalid.",
  "节点必须填写 allow_refuse 布尔值。": "Every node has to declare allow_refuse.",
  "节点的声明取值不正确。": "A node declaration uses an unsupported value.",
  "节点需要1—6个选项。": "A node needs 1-6 options.",
  "start_node 必须引用已有节点。": "start_node has to name an existing node.",
  "选项 id、文案或奖励不正确。": "An option id, label or reward is invalid.",
  "选项不能同时填写 recipe 与 effects。": "An option cannot declare both recipe and effects.",
  "选项至少需要 effects、recipe 或 outcomes。": "An option needs effects, recipe or outcomes.",
  "选项使用了未知 recipe。": "An option uses an unknown recipe.",
  "选项 effects 最多12项。": "An option takes at most 12 effects.",
  "带奖励的选项必须结束事件，不能在领奖后继续下一阶段。": "A rewarded option has to end the event instead of continuing.",
  "选项结果文案不正确。": "An option result text is invalid.",
  "选项预告文案不正确。": "An option preview text is invalid.",
  "选项选择器：": "Option selector: ",
  "选项条件需要恰好一个事件计数或选择来源，以及 equals/minimum/maximum。": "An option condition needs exactly one counter or selector source plus equals/minimum/maximum.",
  "选项条件的事件计数名无效。": "The option condition counter name is invalid.",
  "选项条件的选择来源：": "Option condition source: ",
  "选项条件计数必须是0—100整数。": "An option condition count has to be an integer from 0 to 100.",
  "选项不能同时填写 availability 与 conditions。": "An option cannot declare both availability and conditions.",
  "conditions 需要1—8条条件。": "conditions needs 1-8 entries.",
  "选项 unavailable 只支持 hide 或 disable。": "An option unavailable value supports only hide or disable.",
  "选项不能同时填写 unavailable 与 hide_when_unavailable。": "An option cannot declare both unavailable and hide_when_unavailable.",
  "事件选项同时携带两种状态条件。": "The event option carries both state condition spellings.",
  "条件模式只支持 optional 或 hidden。": "A condition mode supports only optional or hidden.",
  "尚未支持这种状态条件。": "This state condition is not supported yet.",
  "需要条件对象。": "A condition object is required.",
  "reason 需要1—240字的普通说明。": "reason needs 1-240 plain characters.",
  "has_relic 需要已注册的遗物 id。": "has_relic needs a registered relic id.",
 # B5 (A34): the chain-loop gate reason is player-visible, so it needs a manual entry too.
 "这段事件已经走过，不能再回头。": "This event has already happened. You cannot go back."}

static func locale_legacy_catalog_matches_current_sources(t) -> void:
 var file=FileAccess.open("res://assets/localization/legacy-en_US.json",FileAccess.READ)
 t.check(file!=null,"LOCALE legacy catalog is readable")
 if file==null: return
 var parsed=JSON.parse_string(file.get_as_text())
 t.check(parsed is Dictionary and parsed.get("locale")=="en_US","LOCALE legacy catalog keeps its locale marker")
 var by_source={}
 for message in parsed.get("messages",[]):
  by_source[message.get("source","")]=message
 for source in REMOVED_SOURCES:
  t.check(not by_source.has(source),"LOCALE retired source is deleted from the catalog: "+source)
 for source in REQUIRED_SOURCES:
  t.check(by_source.has(source) and str(by_source[source].get("text","")).strip_edges()!="","LOCALE rewritten source keeps a non-empty translation: "+source)

static func run(t) -> void:
 locale_legacy_catalog_matches_current_sources(t)
 bundled_font(t)
 var l=Localizer.new()
 t.check(l.diagnostics().is_empty() and l.locale=="zh_CN","LOCALE shipped resources load locally and default to Chinese: "+str(l.diagnostics()))
 t.check(l.coverage("zh_CN").total>0 and l.coverage("en_US").missing==0 and l.coverage("ja_JP").translated==0,"LOCALE English is complete for registered IDs while Japanese remains an empty scaffold")
 t.check(l.set_locale("en_US") and l.text("ui.home.title","紧缚尖塔")=="Bound Spire","LOCALE registered English copy resolves through its semantic ID")
 var save_help=l.display(preload("res://data/tutorial.gd").SAVE_HELP)
 t.check(save_help=="Autosaves occur on entering a higher floor, after battle, or after preparation. Continue restores the last saved start; Quick SL restores the current scene start.","LOCALE save help distinguishes automatic disk checkpoints from current-scene Quick SL")
 t.check(l.display("离地0.2米的墙缝")=="Wall crack 0.2 m above the floor" and l.display("离地1.4米的墙缝")=="Wall crack 1.4 m above the floor","LOCALE installed tool labels preserve the actual numeric height")
 t.check(l.display("随使用次数和可用条件变化更新")=="Updates with remaining uses and availability","LOCALE usable item status lifetime translates")
 t.check(l.display("精神集中")=="Mental Focus" and l.display("魔力预备")=="Mana Reserve" and l.display("施法预备")=="Spell Preparation","LOCALE character-two resources keep distinct consistent English terms")
 t.check(l.display("思维侵入")=="Mind Intrusion" and l.display("思维扰乱")=="Mind Disruption" and l.display("思维破坏")=="Mind Shatter" and l.display("吹雪")=="Flurry" and l.display("炎枪术")=="Flame Lance","LOCALE character-two spell names use reviewed English")
 t.check(l.display("\n失败返还本次耗魔的50%，能量照扣。")=="\nFailed casts refund 50% of the Mana spent; Energy is still spent.","LOCALE character-two failure tooltip preserves its leading line break and actual payment rule")
 var capture_copy=l.display("被捕缚时无法移动，先解除捕缚。挣扎／滑脱牌可直接削减进度；除眼罩、口球外没有其他拘束具时伤害翻倍，不受环境加成。上身受限至少按1级计算。同种捕缚不叠加；新种类增加其初始值的一半。降至0全部解除，达到100后下一敌方回合执行收押。")
 t.check(capture_copy.contains("Capture") and not capture_copy.to_lower().contains("catch") and capture_copy.contains("next enemy turn"),"LOCALE capture rules use the reviewed mechanic term and preserve the imprisonment timing")
 t.check(l.display("自缚")=="Self-Binding" and l.display("需要收紧4档，当前最多只能收紧2档；无法完整执行。")=="Requires 4 tiers of tightening, but only 2 are available. The full effect cannot be completed.","LOCALE self-binding name and actual tightening shortfall preserve the numeric rule")
 t.check(l.display("蓄力")=="Charge" and l.display("蓄力2")=="Charge 2","LOCALE legacy bridge translates exact and formatted presentation text")
 t.check(l.display("主体")=="Main piece" and l.display("手胸  2  ›")=="Arms & Chest  2  ›","LOCALE release region count and special equipment role translate without changing numbers")
 t.check(l.display("援军")=="Reinforcements" and l.display("3回合后抵达")=="Arrives in 3 turns" and not l.display("每4回合召来1名警卫。已召来1 / 3名；战斗胜利后停止。").contains("警卫"),"LOCALE reinforcement timer and shared limit translate")
 t.check(l.display("每佩戴2件拘束具，本回合获得1点力量，不足2件不计。")=="For every 2 restraints worn, gain 1 Strength this turn. Fewer than 2 do not count.","LOCALE changed card text translates divisor and incomplete groups in static previews")
 t.check(l.display("每佩戴3件拘束具，恢复1点魔力。\n当前：恢复4魔力。")=="For every 3 restraints worn, restore 1 Mana.\nCurrent: restore 4 Mana.","LOCALE changed card text preserves the actual multiline resource preview")
 t.check(l.display("魔路精通")=="Mana Circuit Mastery" and l.display("0费剩余2次")=="Zero-cost triggers remaining: 2","LOCALE mastery name and live quota translate")
 t.check(l.display("两面互斥：本场已启用「魔路精通」，不能再次启用任一面。").contains("Mutually exclusive"),"LOCALE mutual exclusion explains unavailable face")
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
 legacy_contract(t)
 display_cache(t)
 file_fallbacks(t)

static func display_cache(t) -> void:
 var l=Localizer.new();l.set_locale("en_US")
 var pack={"schema_version":1,"locale":"en_US","messages":[
  {"id":"legacy.remaining","source":"余量%d点","text":"Remaining {p0}"},
  {"id":"legacy.ascii","source":"HP","text":"Health"}]}
 t.check(l.install_legacy_translation("en_US",pack) and l.display("HP")=="Health" and l.display("Mana 42 / 100")=="Mana 42 / 100","LOCALE non-Chinese fast path preserves registered exact translations and untouched numeric text")
 for i in range(3): t.check(l.display("余量7点")=="Remaining 7","LOCALE repeated dynamic display keeps identical output")
 pack.messages[0].text="Left {p0}"
 t.check(l.install_legacy_translation("en_US",pack) and l.display("余量7点")=="Left 7","LOCALE accepted replacement invalidates previously displayed dynamic text")
 var invalid=pack.duplicate(true);invalid.messages[0].text="Missing parameter"
 t.check(not l.install_legacy_translation("en_US",invalid) and l.display("余量7点")=="Left 7","LOCALE rejected translation keeps accepted cached output")
 var japanese=pack.duplicate(true);japanese.locale="ja_JP";japanese.messages[0].text="JP {p0}"
 t.check(l.install_legacy_translation("ja_JP",japanese) and l.set_locale("ja_JP") and l.display("余量7点")=="JP 7","LOCALE language switch cannot reuse another language's cached text")
 l.set_locale("en_US")
 t.check(l.display("余量7点")=="Left 7","LOCALE switching back restores the correct catalog")
 for i in range(l.MAX_DISPLAY_ENTRIES+5): l.display("未知短句"+str(i))
 t.check(l._display_cache.size()<=l.MAX_DISPLAY_ENTRIES and l.display("余量7点")=="Left 7","LOCALE varied text has bounded entries and evicted results still resolve correctly")
 for i in range(40): l.display("文".repeat(2048)+str(i))
 t.check(l._display_cache_characters<=l.MAX_DISPLAY_CHARACTERS and l._display_cache.size()<40,"LOCALE long display strings obey the total character budget before the entry limit")
 var count=l._display_cache.size();var huge="文".repeat(l.MAX_DISPLAY_CHARACTERS+1)
 t.check(l.display(huge)==huge and l._display_cache.size()==count,"LOCALE oversized text remains intact without retaining it in the display cache")

static func bundled_font(t) -> void:
 var path="res://assets/fonts/NotoSansCJKsc-Regular.otf"
 var font=load(path) as FontFile
 t.check(font!=null,"LOCALE Chinese font ships as a loadable resource")
 if font==null: return
 var isolated=font.duplicate() as FontFile
 isolated.allow_system_fallback=false
 isolated.fallbacks=[]
 var missing=[]
 for ch in "紧缚尖塔開始遊戲設定繁體中文魔力回合あいうえおカタカナABCxyz0123456789，。！？＋－×％":
  if not isolated.has_char(ch.unicode_at(0)): missing.append(ch)
 t.check(missing.is_empty(),"LOCALE bundled font covers Chinese, traditional Chinese, kana and Latin without installed fonts: "+str(missing))
 var supported={}
 for ch in isolated.get_supported_chars(): supported[ch]=true
 var absent={}
 for file in ["res://assets/localization/zh_CN.json","res://assets/localization/legacy-en_US.json","res://data/balance.gd","res://ui/main.gd"]:
  for ch in FileAccess.get_file_as_string(file):
   var cp=ch.unicode_at(0)
   if cp>=0x3400 and cp<=0x9fff and not supported.has(ch): absent[ch]=true
 t.check(absent.is_empty(),"LOCALE authored Chinese UI and card copy has no missing bundled glyphs: "+str(absent.keys()))
 t.check(ProjectSettings.get_setting("gui/theme/custom_font","")==path,"LOCALE project default also supplies Chinese to unthemed popup controls")
 var presets=ConfigFile.new()
 t.check(presets.load("res://export_presets.cfg")==OK,"LOCALE export presets are readable")
 for section in ["preset.0","preset.1"]:
  t.check("assets/fonts/OFL" in str(presets.get_value(section,"include_filter","")),"LOCALE font license is included in "+section)

static func legacy_contract(t) -> void:
 var l=Localizer.new();l.set_locale("en_US")
 var document={"schema_version":1,"locale":"en_US","messages":[
  {"id":"legacy.turn","source":"第%d回合：%s","text":"Turn {p0}: {p1}"},
  {"id":"legacy.action","source":"行动","text":"Action"},
  {"id":"legacy.start","source":"开始","text":"Begin"},
  {"id":"legacy.end","source":"结束","text":"End"}]}
 t.check(l.install_legacy_translation("en_US",document) and l.display("第12回合：行动")=="Turn 12: Action","LOCALE compatibility templates localize nested display values without changing their source data")
 t.check(l.display("开始 / 结束")=="Begin / End","LOCALE compatibility fragments translate old UI concatenation without changing its source value")
 for bad in [null,{}, {"schema_version":1,"locale":"en_US","messages":[{"id":"legacy.turn","source":"第%d回合","text":"Turn"}]}, {"schema_version":1,"locale":"en_US","messages":[{"id":"legacy.same","source":"甲","text":"A"},{"id":"legacy.same","source":"乙","text":"B"}]}]:
  t.check(not l.install_legacy_translation("en_US",bad) and l.display("第3回合：等待")=="Turn 3: 等待","LOCALE invalid compatibility catalog is rejected atomically")
 document.messages.append({"id":"legacy.symbols","source":"%s / %s","text":"UNRELATED {p0} and {p1}"})
 document.messages.append({"id":"legacy.short","source":"第%d!","text":"UNRELATED {p0}"})
 t.check(l.install_legacy_translation("en_US",document),"LOCALE weak legacy templates can be skipped without discarding valid entries")
 t.check(l.display("12 / 30")=="12 / 30" and l.display("第12!")=="第12!","LOCALE punctuation and one Chinese character cannot qualify a dynamic translation template")
 t.check(l.display("第12回合：行动")=="Turn 12: Action","LOCALE constrained Chinese templates still translate their nested values")

static func file_fallbacks(t) -> void:
 var folder="res://build/localization-fixture-%s" % OS.get_process_id()
 DirAccess.make_dir_recursive_absolute(folder)
 var base_path=folder.path_join("zh_CN.json")
 var target_path=folder.path_join("ja_JP.json")
 var l=Localizer.new()
 l.set_locale("en_US");l.display("蓄力2")
 # Isolated build fixtures exercise IO failures, never the shipped assets.
 var file=FileAccess.open(base_path,FileAccess.WRITE)
 file.store_string(JSON.stringify(source()));file.close()
 t.check(not l.load_directory(folder) and l.diagnostics().any(func(d):return d.code=="missing_file"),"LOCALE absent target file is diagnosed without throwing a runtime error")
 l.set_locale("en_US")
 t.check(l.display("蓄力")=="蓄力" and l.display("蓄力2")=="蓄力2","LOCALE reloading a directory without its legacy pack clears accepted exact, template and fragment translations")
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
