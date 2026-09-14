extends Control

const ActorScene=preload("res://ui/elements/arena.tscn")
const EnemyScene=preload("res://ui/elements/enemy_group.tscn")
const BodyScene=preload("res://ui/shell/body_sidebar.tscn")

var hero: Control
var body: PanelContainer
var enemies: Dictionary={}
var used: Array[Node]=[]

func begin_frame(home: bool) -> void:
 used.clear()
 $MoonlitGallery.visible=not home
 for child in get_children():
  if child==$MoonlitGallery or child==hero or child==body or child in enemies.values():continue
  remove_child(child)
  child.queue_free()

func hero_portrait(view: Dictionary, fixed: bool, rect: Rect2) -> Control:
 if not is_instance_valid(hero):
  hero=ActorScene.instantiate()
  hero.name="HeroArt"
  hero.configure_hero(view,fixed)
  add_child(hero)
 else:
  hero.configure_hero(view,fixed)
 hero.position=rect.position;hero.size=rect.size
 used.append(hero)
 return hero

func enemy_group(enemy: Dictionary, settings) -> Control:
 var group=enemies.get(enemy.id)
 if not is_instance_valid(group):
  group=EnemyScene.instantiate()
  group.name="EnemyGroup_"+enemy.id
  group.get_child(0).name="EnemyArt_"+enemy.id
  group.get_child(0).configure_enemy(enemy,settings)
  add_child(group)
  enemies[enemy.id]=group
 else:
  for child in group.get_children():
   if child==group.get_child(0):continue
   group.remove_child(child)
   child.queue_free()
  group.get_child(0).configure_enemy(enemy,settings)
 used.append(group)
 return group

func body_sidebar(ui) -> void:
 if not is_instance_valid(body):
  body=BodyScene.instantiate()
  add_child(body)
 # Godot mouse picking follows sibling order, independently of z_index.
 move_child(body,-1)
 body.configure(ui)
 used.append(body)

func end_frame() -> void:
 if is_instance_valid(hero):hero.visible=hero in used
 if is_instance_valid(body) and body not in used:
  remove_child(body)
  body.queue_free()
  body=null
 for id in enemies.keys():
  var group=enemies[id]
  if group not in used:
   enemies.erase(id)
   remove_child(group)
   group.queue_free()
