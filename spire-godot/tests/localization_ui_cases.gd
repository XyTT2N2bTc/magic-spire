extends RefCounted
const Navigation=preload("res://tests/interface_ui_cases.gd")
const Settings=preload("res://ui/display_settings.gd")

static func choose(t, locale: String) -> void:
 var picker=t.ui.find_child("LanguageSelection",true,false)
 t.check(picker!=null,"LOCALE UI language selector exists in shared settings")
 if picker==null: return
 var index=t.ui.localization.LOCALES.find(locale)
 picker.select(index);picker.item_selected.emit(index)
 await t.frames()

static func run(t) -> void:
 var ui=t.ui
 ui.options_tab="display"
 ui._return_home();await t.frames()
 var before=ui.game.export_snapshot()
 var candidates=ui.view.candidates.duplicate(true)
 await Navigation.press(t,"HomeOptions")
 var picker=ui.find_child("LanguageSelection",true,false)
 t.check(picker.item_count==2 and picker.get_item_text(1)=="日语（待翻译）","LOCALE UI does not present the empty Japanese pack as finished")
 await choose(t,"ja_JP")
 t.check(ui.localization.locale=="ja_JP" and ui.display_settings.locale=="ja_JP" and ui.find_child("HomeTitle",true,false).text=="紧缚尖塔","LOCALE UI real language selection uses Chinese fallback")
 t.check(ui.game.export_snapshot()==before and ui.view.candidates==candidates,"LOCALE UI switching keeps game state, candidates, RNG and version unchanged")
 var panel=ui.find_child("InformationDrawer",true,false)
 t.check(panel.get_global_rect().encloses(ui.find_child("FeedbackSpeed",true,false).get_global_rect()),"LOCALE UI language row and final display setting fit inside the window")
 # In-memory pseudo copy proves that wired controls actually read the resource.
 var sample={"schema_version":1,"locale":"ja_JP","messages":{
  "ui.home.title":{"source":"紧缚尖塔","text":"[TEST TITLE]"},
  "ui.settings.music_volume":{"source":"音乐音量 · {percent}%","text":"{percent}% [TEST VOLUME]"}
 }}
 t.check(ui.localization.install_translation("ja_JP",sample),"LOCALE UI isolated pseudo catalog loads without changing shipped Japanese file")
 ui.render(ui.view);await t.frames()
 t.check(ui.find_child("HomeTitle",true,false).text=="[TEST TITLE]","LOCALE UI static caption uses selected language resource")
 await Navigation.press(t,"SettingsTab_audio")
 var volume=ui.find_child("CardMusicVolume",true,false)
 var old_volume=volume.value
 volume.value=37;await t.frames()
 t.check(ui.find_child("CardMusicVolumeLabel",true,false).text=="37% [TEST VOLUME]","LOCALE UI dynamic caption resolves reordered named parameter after slider update")
 volume.value=old_volume
 await Navigation.press(t,"SettingsTab_display")
 await choose(t,"zh_CN")
 t.check(ui.find_child("HomeTitle",true,false).text=="紧缚尖塔" and ui.game.export_snapshot()==before,"LOCALE UI switch back restores Chinese without altering game")
 ui.localization.load_directory()
 await t.capture("ui-localization-framework.png")
 await t.close_information()
 # Only test settings files; never the player's preferences or saves.
 var path="res://build/localization-settings-%s.cfg" % OS.get_process_id()
 var settings=Settings.new();settings.path=path;settings.initialize(t.root,false);settings.persistence_enabled=true
 t.check(settings.set_locale("ja_JP") and settings.save_error.is_empty(),"LOCALE preference saves through the existing display settings store")
 var restored=Settings.new();restored.path=path;restored.initialize(t.root)
 t.check(restored.locale=="ja_JP" and not restored.set_locale("unknown") and restored.locale=="ja_JP","LOCALE preference reloads and rejects unsupported languages")
 var config=ConfigFile.new();config.load(path);config.set_value("localization","locale",99);config.save(path)
 restored.initialize(t.root)
 t.check(restored.locale=="zh_CN","LOCALE malformed saved language falls back to Chinese")
 config.erase_section("localization");config.save(path);restored.initialize(t.root)
 t.check(restored.locale=="zh_CN","LOCALE existing settings without a language remain valid Chinese defaults")
 DirAccess.remove_absolute(path)
 ui.restart(42);await t.frames()
 before=ui.game.export_snapshot();candidates=ui.view.candidates.duplicate(true)
 await t.open_menu();await Navigation.press(t,"OpenOptions")
 await choose(t,"ja_JP");await choose(t,"zh_CN")
 t.check(ui.game.export_snapshot()==before and ui.view.candidates==candidates,"LOCALE in-game settings use the same selector without restarting or submitting an action")
 t.check(ui.localization.diagnostics().is_empty(),"LOCALE wired screens resolve every registered template without silent errors")
 await t.close_information()
