extends RefCounted
signal art_changed(category: String, id: String)

const FORMAL_ART={"cards":{"crossed_legs":"res://assets/art/card-crossed-legs-formal-v1.png"},"enemies":{
 "six_bind":"res://assets/art/enemy-six-bind-formal-v1.png",
 "puppeteer":"res://assets/art/enemy-puppeteer-formal-v1.png",
 "puppet":"res://assets/art/enemy-puppet-formal-v1.png",
}}
var art_choices={}
var fixed_hero_portrait=false
var chastity_locks_enabled=false
var chastity_lock_chance=25
var cursed_plate_start=false
var cursed_plate_masochist_mode=false
var first_battle_tutorial_seen=false
var card_music_enabled=true
var card_music_volume=0.2

const MODES=["窗口","无边框窗口","全屏"]
const FRAME_LIMITS=[60,120,240,0]
var frame_limit=60
var vsync_enabled=true
const Localization=preload("res://ui/localization.gd")
var locale=Localization.DEFAULT_LOCALE
const RESOLUTIONS=[Vector2i(1280,720),Vector2i(1440,810),Vector2i(1600,900),Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(3840,2160)]
var mode=0
var resolution=Vector2i(1440,810)
var path="user://display-settings.cfg"
var persistence_enabled=true
var save_error=""
var window: Window
var mobile=OS.has_feature("android")

func choices() -> Array:
 var sizes=RESOLUTIONS.duplicate()
 if resolution.x>=640 and resolution.y>=360 and resolution.x<=3840 and resolution.y<=2160 and resolution not in sizes:
  sizes.append(resolution);sizes.sort_custom(func(a,b):return a.x<b.x)
 return sizes

func initialize(target: Window, persist: bool=true) -> void:
 window=target;persistence_enabled=persist
 locale=Localization.DEFAULT_LOCALE
 art_choices.clear()
 fixed_hero_portrait=false
 chastity_locks_enabled=false
 chastity_lock_chance=25
 cursed_plate_start=false
 cursed_plate_masochist_mode=false
 first_battle_tutorial_seen=false
 card_music_enabled=true;card_music_volume=0.2
 frame_limit=60;vsync_enabled=true
 _apply_frame_settings()
 mode=2 if window.mode in [Window.MODE_FULLSCREEN,Window.MODE_EXCLUSIVE_FULLSCREEN] else (1 if window.borderless else 0)
 resolution=window.size
 if not persistence_enabled: return
 var config=ConfigFile.new()
 if config.load(path)!=OK: return
 var saved_locale=config.get_value("localization","locale",Localization.DEFAULT_LOCALE)
 if Localization.supported(saved_locale): locale=saved_locale
 var saved_music=config.get_value("audio","card_music_enabled",true)
 var saved_volume=config.get_value("audio","card_music_volume",0.2)
 if saved_music is bool: card_music_enabled=saved_music
 if (saved_volume is float or saved_volume is int) and is_finite(float(saved_volume)):
  card_music_volume=clampf(float(saved_volume),0.0,1.0)
 var saved_fixed=config.get_value("art","fixed_hero_portrait",false)
 if saved_fixed is bool: fixed_hero_portrait=saved_fixed
 var saved_chastity=config.get_value("gameplay","chastity_locks_enabled",false)
 var saved_chance=config.get_value("gameplay","chastity_lock_chance",25)
 if saved_chastity is bool: chastity_locks_enabled=saved_chastity
 if saved_chance is int and saved_chance>=0 and saved_chance<=100 and saved_chance%5==0: chastity_lock_chance=maxi(5,saved_chance)
 if fixed_hero_portrait: chastity_locks_enabled=false
 var saved_start=config.get_value("gameplay","cursed_plate_start",false)
 if saved_start is bool: cursed_plate_start=saved_start and chastity_locks_enabled
 var saved_masochist=config.get_value("gameplay","cursed_plate_masochist_mode",false)
 if saved_masochist is bool: cursed_plate_masochist_mode=saved_masochist and chastity_locks_enabled
 var saved_tutorial=config.get_value("onboarding","first_battle_tutorial_seen",false)
 if saved_tutorial is bool: first_battle_tutorial_seen=saved_tutorial
 var saved_art=config.get_value("art","choices",{})
 if saved_art is Dictionary:
  for category in FORMAL_ART:
   var choices_for_category=saved_art.get(category,{})
   if not choices_for_category is Dictionary: continue
   for id in choices_for_category:
    if id is String and choices_for_category[id] in ["test","formal"]:
     if not art_choices.has(category): art_choices[category]={}
     art_choices[category][id]=choices_for_category[id]
 var saved_mode=config.get_value("display","mode",mode)
 var saved_limit=config.get_value("display","frame_limit",60)
 var saved_vsync=config.get_value("display","vsync_enabled",true)
 if saved_limit is int and saved_limit in FRAME_LIMITS: frame_limit=saved_limit
 if saved_vsync is bool: vsync_enabled=saved_vsync
 var saved_size=config.get_value("display","resolution",resolution)
 if saved_mode is int and saved_mode in range(MODES.size()): mode=saved_mode
 if saved_size is Vector2i and saved_size.x>=640 and saved_size.y>=360: resolution=saved_size
 if resolution not in choices(): resolution=choices().back()
 apply()

func set_mode(value: int) -> void:
 if mobile: return
 if value not in range(MODES.size()): return
 mode=value;apply();save()

func set_resolution(value: Vector2i) -> void:
 if mobile: return
 if mode==2 or value not in choices(): return
 resolution=value;apply();save()

func apply() -> void:
 _apply_frame_settings()
 if mobile: return
 if mode==2:
  window.mode=Window.MODE_FULLSCREEN
  return
 window.mode=Window.MODE_WINDOWED
 # Fullscreen also sets this flag, so explicitly clear it when returning to a framed window.
 window.borderless=mode==1
 window.size=resolution
 var screen=DisplayServer.screen_get_usable_rect(window.current_screen)
 var offset=Vector2i(maxi(0,(screen.size.x-resolution.x)/2),maxi(0,(screen.size.y-resolution.y)/2))
 window.position=screen.position+offset

func _apply_frame_settings() -> void:
 Engine.max_fps=frame_limit
 DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED,window.get_window_id())

func set_frame_limit(value: int) -> bool:
 if value not in FRAME_LIMITS: return false
 frame_limit=value;_apply_frame_settings();save()
 return true

func set_vsync(enabled: bool) -> void:
 vsync_enabled=enabled;_apply_frame_settings();save()

func save() -> void:
 save_error=""
 if not persistence_enabled: return
 var config=ConfigFile.new()
 config.set_value("display","mode",mode)
 config.set_value("display","frame_limit",frame_limit)
 config.set_value("display","vsync_enabled",vsync_enabled)
 config.set_value("localization","locale",locale)
 config.set_value("display","resolution",resolution)
 config.set_value("art","choices",art_choices)
 config.set_value("art","fixed_hero_portrait",fixed_hero_portrait)
 config.set_value("gameplay","chastity_locks_enabled",chastity_locks_enabled)
 config.set_value("gameplay","chastity_lock_chance",chastity_lock_chance)
 config.set_value("gameplay","cursed_plate_start",cursed_plate_start)
 config.set_value("gameplay","cursed_plate_masochist_mode",cursed_plate_masochist_mode)
 config.set_value("onboarding","first_battle_tutorial_seen",first_battle_tutorial_seen)
 config.set_value("audio","card_music_enabled",card_music_enabled)
 config.set_value("audio","card_music_volume",card_music_volume)
 if config.save(path)!=OK: save_error="设置未能保存，下次启动时需要重新选择。"

func set_locale(value: String) -> bool:
 if not Localization.supported(value): return false
 locale=value;save()
 return true

func set_card_music(enabled: bool, volume: float) -> void:
 card_music_enabled=enabled;card_music_volume=clampf(volume,0.0,1.0)
 save()

func set_fixed_hero_portrait(enabled: bool) -> void:
 fixed_hero_portrait=enabled
 if enabled: chastity_locks_enabled=false
 if not chastity_locks_enabled:
  cursed_plate_start=false
  cursed_plate_masochist_mode=false
 save()

func set_chastity_locks(enabled: bool) -> void:
 chastity_locks_enabled=enabled and not fixed_hero_portrait
 if not chastity_locks_enabled:
  cursed_plate_start=false
  cursed_plate_masochist_mode=false
 save()

func set_cursed_plate_start(enabled: bool) -> void:
 cursed_plate_start=enabled and chastity_locks_enabled and not fixed_hero_portrait
 save()

func set_cursed_plate_masochist_mode(enabled: bool) -> void:
 cursed_plate_masochist_mode=enabled and chastity_locks_enabled and not fixed_hero_portrait
 save()

func adjust_chastity_chance(delta: int) -> void:
 if fixed_hero_portrait or not chastity_locks_enabled: return
 chastity_lock_chance=clampi(chastity_lock_chance+delta,5,100)
 chastity_lock_chance=int(round(float(chastity_lock_chance)/5.0))*5
 save()

func mark_first_battle_tutorial_seen() -> void:
 first_battle_tutorial_seen=true
 save()

func has_formal_art(category: String, id: String) -> bool:
 return FORMAL_ART.get(category,{}).has(id)

func art_style(category: String, id: String) -> String:
 if not has_formal_art(category,id): return "test"
 return art_choices.get(category,{}).get(id,"formal")

func art_texture(category: String, id: String) -> Texture2D:
 if art_style(category,id)!="formal": return null
 return load(FORMAL_ART[category][id])

func set_art_style(category: String, id: String, style: String) -> void:
 if not FORMAL_ART.has(category) or id.is_empty() or style not in ["formal","test"]: return
 if style=="formal" and not has_formal_art(category,id): return
 if not art_choices.has(category): art_choices[category]={}
 art_choices[category][id]=style
 save();art_changed.emit(category,id)
