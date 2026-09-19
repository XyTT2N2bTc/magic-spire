extends RefCounted

const Dialogue=preload("res://data/doubao_dialogue.gd")
const Navigation=preload("res://tests/interface_ui_cases.gd")
const Settings=preload("res://ui/display_settings.gd")

static func run(t) -> void:
 var ui=t.ui;var presenter=ui.takeover_presenter
 ui.restart(42);await t.frames()
 var before=ui.game.export_snapshot()
 var paths=[];var broken=[]
 for cue in Dialogue.LINES:
  for variant in range(2):
   var entry=Dialogue.entry(cue,variant)
   var clip=load(entry.voice) as AudioStreamWAV
   if clip==null or clip.get_length()<3.0 or clip.loop_mode!=AudioStreamWAV.LOOP_DISABLED or entry.voice in paths: broken.append(entry.voice)
   paths.append(entry.voice)
 t.check(paths.size()==40 and broken.is_empty(),"VOICE all forty distinct supplied recordings import as finite nonlooping audio: "+str(broken))
 t.check(absf(load(Dialogue.entry("start",0).voice).get_length()-4.92)<0.01 and absf(load(Dialogue.entry("start",1).voice).get_length()-7.32)<0.01 and absf(load(Dialogue.entry("failed",1).voice).get_length()-7.84)<0.01,"VOICE A/B intro and long failure lengths match the supplied recordings")
 for cue in ["chain","retain","retain_skip"]:
  t.check(Dialogue.entry(cue,0)==Dialogue.entry("choice",0) and Dialogue.entry(cue,1)==Dialogue.entry("choice",1),"VOICE extra-choice fallback keeps subtitle and recording paired: "+cue)
 for variant in range(2):
  presenter.variant=variant
  for cue in Dialogue.LINES:
   presenter._say(cue);await t.frames()
   var entry=Dialogue.entry(cue,variant)
   t.check(presenter.voice.playing and presenter.voice.stream.resource_path==entry.voice and presenter.speech.text==ui.localization.display(entry.text) and presenter.voice.max_polyphony==1,"VOICE actual speaker matches subtitle for "+cue+" variant "+str(variant))
 presenter.variant=1;presenter._say("failed");await t.frames()
 t.check(presenter._reading_time()>7.4 and presenter.expires-Time.get_ticks_msec()>7800,"VOICE long clip extends pacing and bubble beyond former five/six-second cutoffs")
 presenter.voice.seek(1.0);await t.frames(4)
 var stream=presenter.voice.stream
 ui.render();await t.frames()
 t.check(presenter.voice.stream==stream and presenter.voice.get_playback_position()>=1.0,"VOICE ordinary refresh never restarts current sentence")
 presenter._say("relic_control_done");presenter.voice.seek(1.0);await t.frames(4)
 presenter.outcome({"ok":true},ui.view,ui.view,{"payload":{"kind":"relic_control_done"}})
 t.check(presenter.voice.get_playback_position()>=1.0,"VOICE handing control back does not speak the same line twice")
 presenter.voice.seek(presenter.voice.stream.get_length()-0.05);presenter.read_until=0
 await t.create_timer(0.3).timeout
 t.check(not presenter.voice.playing and is_zero_approx(presenter._reading_time()),"VOICE clip finishes naturally and releases its pacing wait")
 await t.open_menu();await Navigation.press(t,"OpenOptions");await Navigation.press(t,"SettingsTab_audio")
 var toggle=ui.find_child("DoubaoVoiceEnabled",true,false)
 var volume=ui.find_child("DoubaoVoiceVolume",true,false)
 t.check(toggle.button_pressed and volume.value==32,"VOICE sound settings expose independent enabled and thirty-two-percent defaults")
 presenter._say("start");volume.value=35
 t.check(is_equal_approx(presenter.voice.volume_linear,0.35) and ui.find_child("DoubaoVoiceVolumeLabel",true,false).text.contains("35%") and is_equal_approx(ui.display_settings.card_music_volume,0.2),"VOICE volume changes immediately without changing card music volume")
 toggle.button_pressed=false;await t.frames()
 t.check(not presenter.voice.playing and presenter.voice.stream==null,"VOICE disabling immediately cancels current recording")
 presenter._say("failed")
 t.check(presenter.speech.text==Dialogue.entry("failed",1).text and not presenter.voice.playing and presenter._reading_time()<=5.0,"VOICE disabled speech preserves subtitles and normal reading time")
 toggle.button_pressed=true;await t.frames()
 t.check(not presenter.voice.playing,"VOICE enabling never replays a stale line")
 presenter._say("start");await t.frames()
 t.check(presenter.voice.playing,"VOICE next sentence plays after reenabling")
 await t.capture("ui-doubao-voice-settings.png")
 await t.close_information();ui.options_tab="display"
 t.check(ui.game.export_snapshot()==before,"VOICE playback, settings and redraw never mutate game state or random cursors")
 var path="res://build/doubao-voice-settings-%s.cfg" % OS.get_process_id()
 var prefs=Settings.new();prefs.path=path;prefs.initialize(t.root,false);prefs.persistence_enabled=true
 prefs.set_doubao_voice(false,0.35)
 var restored=Settings.new();restored.path=path;restored.initialize(t.root)
 t.check(not restored.doubao_voice_enabled and is_equal_approx(restored.doubao_voice_volume,0.35),"VOICE preferences round-trip outside gameplay saves")
 var config=ConfigFile.new();config.set_value("audio","doubao_voice_enabled","invalid");config.set_value("audio","doubao_voice_volume","invalid");config.save(path)
 restored.initialize(t.root)
 t.check(restored.doubao_voice_enabled and is_equal_approx(restored.doubao_voice_volume,0.32),"VOICE missing or malformed saved settings use safe defaults")
 DirAccess.remove_absolute(path)
 presenter._say("start");ui._return_home();await t.frames()
 t.check(not presenter.voice.playing and presenter.voice.stream==null,"VOICE returning home stops old speech")
 ui.display_settings.set_doubao_voice(true,0.32);presenter.configure_voice()
 ui.restart(42);await t.frames()
