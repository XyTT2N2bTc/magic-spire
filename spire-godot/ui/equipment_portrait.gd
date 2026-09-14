extends TextureRect

# Display mapping only. Actual coverage comes from the read-only view.
const FREE=preload("res://assets/art/equipment-portrait-cutout-v1.png")
const BATTLE_FREE=preload("res://assets/art/hero-stand-cutout-v2.png")
const WITCH_SIDEBAR=preload("res://assets/art/witch-sidebar-cutout-v1.png")
const BOUND_BASE=preload("res://assets/art/equipment-body-sliced-v3.png")
const BOUND_FLAT_LOCK=preload("res://assets/art/equipment-body-flat-lock-v1.png")
const BOUND_SINGLE_GLOVE=preload("res://assets/art/equipment-body-single-glove-v1.png")
const BOUND_SINGLE_GLOVE_FLAT_LOCK=preload("res://assets/art/equipment-body-single-glove-flat-lock-v1.png")
const FLAT_LOCK_THIGH={
 "bound":preload("res://assets/art/equipment-leg-thigh_root-flat-lock-v1.png"),
 "free":preload("res://assets/art/equipment-leg-thigh_root-flat-lock-free-v1.png")}
const SINGLE_GLOVE_THIGH={
 "bound":preload("res://assets/art/equipment-leg-thigh_root-single-glove-v1.png"),
 "free":preload("res://assets/art/equipment-leg-thigh_root-single-glove-free-v1.png"),
 "flat_lock_bound":preload("res://assets/art/equipment-leg-thigh_root-single-glove-flat-lock-v1.png"),
 "flat_lock_free":preload("res://assets/art/equipment-leg-thigh_root-single-glove-flat-lock-free-v1.png")}
const LAYERS={
 "mouth":{"texture":preload("res://assets/art/equipment-overlay-mouth-v1.png"),"origin":Vector2(655,374)},
 "eyes":{"texture":preload("res://assets/art/equipment-overlay-eyes-v1.png"),"origin":Vector2(590,238)}}
const SPECIAL_LAYERS={
 "flat_lock_reinforcement":{"texture":preload("res://assets/art/equipment-overlay-flat-lock-reinforcement-v1.png"),"origin":Vector2(656,928)},
 "urethral_rod":{"texture":preload("res://assets/art/equipment-overlay-urethral-rod-v1.png"),"origin":Vector2(873,1147)}}
const FREE_SPECIAL_LAYERS={
 "flat_lock":{"texture":preload("res://assets/art/hero-overlay-flat-lock-free-v1.png"),"origin":Vector2(774,894)},
 "flat_lock_reinforcement":{"texture":preload("res://assets/art/hero-overlay-flat-lock-reinforcement-free-v1.png"),"origin":Vector2(634,956)}}
const BOUND_CROP=Vector2(390,90)
const FREE_CROP=Vector2(463,164)
const BATTLE_FREE_CROP=Vector2(349,60)
const BOUND_EYE=Vector2(895,329)
const FREE_EYE=Vector2(823,383)
const FREE_FACE_SCALE=0.907
const FREE_FACE_ROTATION=-0.1035
var variant=-1
var fixed_portrait=false
var battle_free_portrait=false
var witch_portrait=false
var equipped_mouth=false
var equipped_eyes=false
var active_leg_layers: Array=[]
var active_special_layers: Array=[]
var active_composite_layers: Array=[]
static var leg_layers: Dictionary=_load_leg_layers()
var appearance: Array=[]

# Shared display policy for the arena and sidebar; never query the live game here.
static func uses_fixed_portrait(view: Dictionary, preferred: bool) -> bool:
 return preferred and view.get("character_id","original")!="witch"

# Owners retain only the fields consumed by this renderer, never actions or full state.
static func snapshot(view: Dictionary) -> Dictionary:
 return {"character_id":view.get("character_id","original"),
  "has_restraint_level":view.has_restraint_level,
  "equipment_portrait_layers":view.get("equipment_portrait_layers",[]).duplicate(),
  "composite_portrait_layers":view.get("composite_portrait_layers",[]).duplicate(),
  "body_coverage":view.body_coverage.duplicate(true),
  "bodies":view.bodies.map(func(body):return {"id":body.id,"occupied":body.occupied})}

static func visual_facts(view: Dictionary) -> Array:
 var legs=[]
 for key in leg_layers:
  var spec=leg_layers[key]
  if spec.value in view.get("body_coverage",{}).get(spec.field,[]):legs.append(key)
 var bodies=view.get("bodies",[])
 return [view.get("has_restraint_level",false),view.get("equipment_portrait_layers",[]).duplicate(),view.get("composite_portrait_layers",[]).duplicate(),legs,
  bodies.any(func(body):return body.id=="mouth" and body.occupied),
  bodies.any(func(body):return body.id=="eyes" and body.occupied)]

static func _load_leg_layers() -> Dictionary:
 var entries=JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/equipment-leg-layers.json"))
 var result={}
 for entry in entries:
  result[entry.id]={"texture":load(entry.texture),"free_texture":load(entry.free_texture),"origin":Vector2(entry.origin[0],entry.origin[1]),"field":entry.field,"value":entry.value}
 return result

func configure(view: Dictionary, fixed: bool=false, battle_free: bool=false) -> void:
 var next_witch=view.get("character_id","original")=="witch"
 var next_appearance=[next_witch,fixed,battle_free,[] if fixed or next_witch else visual_facts(view)]
 if appearance==next_appearance:return
 appearance=next_appearance
 fixed_portrait=fixed
 battle_free_portrait=battle_free
 witch_portrait=next_witch
 variant=0 if view.has_restraint_level and not fixed and not witch_portrait else -1
 active_special_layers.assign(view.get("equipment_portrait_layers",[]))
 active_composite_layers.assign(view.get("composite_portrait_layers",[]))
 var has_flat_lock="flat_lock" in active_special_layers
 var has_single_glove="single_glove" in active_composite_layers
 texture=WITCH_SIDEBAR if witch_portrait else ((BATTLE_FREE if battle_free_portrait else FREE) if variant<0 else (BOUND_SINGLE_GLOVE_FLAT_LOCK if has_flat_lock and has_single_glove else (BOUND_FLAT_LOCK if has_flat_lock else (BOUND_SINGLE_GLOVE if has_single_glove else BOUND_BASE))))
 active_leg_layers.clear()
 for key in leg_layers:
  var spec=leg_layers[key]
  if spec.value in view.body_coverage[spec.field]: active_leg_layers.append(key)
 equipped_mouth=view.bodies.any(func(b):return b.id=="mouth" and b.occupied)
 equipped_eyes=view.bodies.any(func(b):return b.id=="eyes" and b.occupied)
 expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 if is_node_ready(): _align_layers()

func _ready() -> void:
 if texture==null:texture=FREE
 var layers=LAYERS.merged(leg_layers)
 for key in layers:
  var layer=TextureRect.new();layer.name="Overlay_"+key;layer.texture=layers[key].texture
  layer.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;layer.mouse_filter=Control.MOUSE_FILTER_IGNORE
  add_child(layer)
 for key in SPECIAL_LAYERS:
  var layer=TextureRect.new();layer.name="Overlay_"+key;layer.texture=SPECIAL_LAYERS[key].texture
  layer.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;layer.mouse_filter=Control.MOUSE_FILTER_IGNORE
  add_child(layer)
 for key in FREE_SPECIAL_LAYERS:
  var layer=TextureRect.new();layer.name="Overlay_free_"+key;layer.texture=FREE_SPECIAL_LAYERS[key].texture
  layer.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;layer.mouse_filter=Control.MOUSE_FILTER_IGNORE
  add_child(layer)
 resized.connect(_align_layers);_align_layers()

func _align_layers() -> void:
 var factor=minf(size.x/texture.get_width(),size.y/texture.get_height())
 var offset=(size-texture.get_size()*factor)/2
 var layers=LAYERS.merged(leg_layers)
 for key in layers:
  var layer=get_node("Overlay_"+key)
  layer.visible=not witch_portrait and not fixed_portrait and not (battle_free_portrait and variant<0) and (equipped_mouth if key=="mouth" else (equipped_eyes if key=="eyes" else variant>=0))
  if key in leg_layers:
   if key=="thigh_root" and "single_glove" in active_composite_layers:
    var thigh_key=("flat_lock_" if "flat_lock" in active_special_layers else "")+("bound" if key in active_leg_layers else "free")
    layer.texture=SINGLE_GLOVE_THIGH[thigh_key]
   elif key=="thigh_root" and "flat_lock" in active_special_layers:
    layer.texture=FLAT_LOCK_THIGH.bound if key in active_leg_layers else FLAT_LOCK_THIGH.free
   else: layer.texture=leg_layers[key].texture if key in active_leg_layers else leg_layers[key].free_texture
  var position_in_source=layers[key].origin-BOUND_CROP
  var layer_factor=1.0;var angle=0.0
  if variant<0 and key in LAYERS:
   position_in_source=FREE_EYE+(LAYERS[key].origin-BOUND_EYE).rotated(FREE_FACE_ROTATION)*FREE_FACE_SCALE-FREE_CROP
   layer_factor=FREE_FACE_SCALE;angle=FREE_FACE_ROTATION
  layer.position=offset+position_in_source*factor
  layer.size=layer.texture.get_size()*factor*layer_factor;layer.rotation=angle
 for key in SPECIAL_LAYERS:
  var layer=get_node("Overlay_"+key)
  layer.visible=not witch_portrait and variant>=0 and not fixed_portrait and key in active_special_layers
  layer.position=offset+(SPECIAL_LAYERS[key].origin-BOUND_CROP)*factor
  layer.size=layer.texture.get_size()*factor
 for key in FREE_SPECIAL_LAYERS:
  var layer=get_node("Overlay_free_"+key)
  layer.visible=not witch_portrait and battle_free_portrait and variant<0 and not fixed_portrait and key in active_special_layers
  layer.position=offset+(FREE_SPECIAL_LAYERS[key].origin-BATTLE_FREE_CROP)*factor
  layer.size=layer.texture.get_size()*factor
