extends HBoxContainer
const Catalog=preload("res://data/encyclopedia.gd")
const RelicIcon=preload("res://ui/relic_icon.gd")
var host
var rows=[]
var category="equipment"
var query=""
var group=""
var grade=0
var rarity=""
var selected=""
var list: VBoxContainer
var detail: VBoxContainer
var groups: OptionButton
var grades: OptionButton
var count: Label

func setup(ui) -> void:
 host=ui;rows=Catalog.entries();name="Encyclopedia"
 size_flags_vertical=Control.SIZE_EXPAND_FILL;add_theme_constant_override("separation",20)
 var sidebar=VBoxContainer.new();sidebar.custom_minimum_size.x=160;add_child(sidebar)
 for id in Catalog.CATEGORIES:
  var button=host._button(Catalog.CATEGORIES[id],func():category=id;group="";grade=0;rarity="";selected="";update_filters();refresh(),host.GOLD)
  button.name="EncyclopediaCategory_"+id;sidebar.add_child(button)
 var middle=VBoxContainer.new();middle.custom_minimum_size.x=360;add_child(middle)
 var search=LineEdit.new();search.name="EncyclopediaSearch";search.placeholder_text="搜索名称、部位或效果";search.clear_button_enabled=true;middle.add_child(search)
 search.text_changed.connect(func(value):query=value;selected="";refresh())
 var filters=HBoxContainer.new();middle.add_child(filters)
 groups=OptionButton.new();groups.name="EncyclopediaGroup";groups.size_flags_horizontal=Control.SIZE_EXPAND_FILL;filters.add_child(groups)
 groups.item_selected.connect(func(index):group=str(groups.get_item_metadata(index));selected="";refresh())
 grades=OptionButton.new();grades.name="EncyclopediaGrade";filters.add_child(grades)
 for label in ["全部品质","初级","中级","高级"]: grades.add_item(label)
 grades.item_selected.connect(func(index):
  if category in ["cards","relics"]: rarity=str(grades.get_item_metadata(index))
  else: grade=index
  selected="";refresh())
 count=host._label("",14,host.MUTED);count.name="EncyclopediaCount";middle.add_child(count)
 list=host._scroll(middle);list.name="EncyclopediaEntries"
 var right=VBoxContainer.new();right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;add_child(right)
 detail=host._scroll(right);detail.name="EncyclopediaDetail"
 update_filters();refresh()

func update_filters() -> void:
 groups.clear();groups.add_item("全部分支");groups.set_item_metadata(0,"")
 var names=[]
 if category=="cards": names=Catalog.Cards.TYPES.values().map(func(label):return label+"牌")
 elif category=="enemies": names=["弱怪","强怪","精英"]
 for entry in rows:
  if entry.category==category and entry.group not in names: names.append(entry.group)
 for label in names:
  groups.add_item(label);groups.set_item_metadata(groups.item_count-1,label)
 grades.clear()
 if category in ["cards","relics"]:
  grades.add_item("全部稀有度");grades.set_item_metadata(0,"")
  var rarities=Catalog.Relics.RARITIES if category=="relics" else Catalog.Cards.RARITIES
  for id in rarities:
   grades.add_item(rarities[id]);grades.set_item_metadata(grades.item_count-1,id)
 else:
  for label in ["全部品质","初级","中级","高级"]: grades.add_item(label)
 grades.visible=category in ["equipment","special","cards","relics"];grades.select(0)

func clear_children(parent: Node) -> void:
 for child in parent.get_children(): parent.remove_child(child);child.queue_free()

func refresh() -> void:
 clear_children(list)
 var matching=rows.filter(func(e):return e.category==category and (group=="" or e.group==group) and (grade==0 or e.grade==grade) and (rarity=="" or e.get("rarity","")==rarity) and (query.strip_edges()=="" or (e.title+e.text+e.group+e.get("search_text","")).containsn(query.strip_edges())))
 count.text=Catalog.CATEGORIES[category]+" · %d条" % matching.size()
 for entry in matching:
  var label=entry.title+(" · "+entry.rarity_name if entry.has("rarity_name") else (" · "+Catalog.E.GRADES[entry.grade] if entry.grade>0 else ""))
  var button=host._button(label,func():selected=entry.id;show_entry(entry),host.GOLD)
  if entry.category=="relics" and RelicIcon.ART.has(entry.id):
   button.icon=RelicIcon.ART[entry.id];button.expand_icon=true
   button.add_theme_constant_override("icon_max_width",40)
   button.icon_alignment=HORIZONTAL_ALIGNMENT_LEFT
  if entry.get("image","")!="":
   button.icon=load(entry.image);button.expand_icon=true
   button.add_theme_constant_override("icon_max_width",40)
   button.icon_alignment=HORIZONTAL_ALIGNMENT_LEFT
  button.name="EncyclopediaEntry_"+entry.id;button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;list.add_child(button)
 if matching.is_empty():
  clear_children(detail);detail.add_child(host._label("此分支暂无条目，或没有符合筛选条件的内容。",18,host.MUTED));return
 var chosen=matching.filter(func(e):return e.id==selected)
 show_entry(chosen[0] if not chosen.is_empty() else matching[0])

func show_entry(entry: Dictionary) -> void:
 host._hide_term()
 selected=entry.id;clear_children(detail)
 detail.add_child(host._label(entry.title,24,host.GOLD))
 detail.add_child(host._label(entry.group+(" · "+entry.rarity_name if entry.has("rarity_name") else (" · "+Catalog.E.GRADES[entry.grade] if entry.grade>0 else "")),15,host.CYAN))
 if entry.category in ["cards","enemies"]: _art_selector(entry)
 if entry.has("card"):
  _card_family(entry)
 else:
  if entry.category=="relics":
   var icon=RelicIcon.new();icon.relic={"id":entry.id}
   icon.name="EncyclopediaRelicIcon";icon.custom_minimum_size=Vector2(112,112)
   icon.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;detail.add_child(icon)
  if entry.has("item"):
   var icon=preload("res://ui/shop_glyph.gd").new();icon.kind="tool";icon.symbol="return_scroll" if entry.item=="return_seal" else entry.item
   icon.name="EncyclopediaItemIcon";icon.custom_minimum_size=Vector2(80,80);icon.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;detail.add_child(icon)
  if entry.get("image","")!="":
   var picture=TextureRect.new();picture.name="EncyclopediaEquipmentImage"
   picture.texture=load(entry.image);picture.custom_minimum_size=Vector2(220,190)
   picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
   picture.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;picture.mouse_filter=Control.MOUSE_FILTER_IGNORE
   picture.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;detail.add_child(picture)
  if entry.has("visual"):
   var picture=preload("res://ui/arena.gd").new();picture.mode=entry.visual;picture.custom_minimum_size=Vector2(240,300)
   picture.name="EncyclopediaEnemyImage";picture.template=entry.id;picture.art_settings=host.display_settings
   picture.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;detail.add_child(picture)
  detail.add_child(host._label(entry.text,17,host.TEXT))
 detail.get_parent().scroll_vertical=0

func _card_family(entry: Dictionary) -> void:
 var related=entry.get("related_cards",[])
 var flow=HFlowContainer.new();flow.name="EncyclopediaCardFamily"
 flow.add_theme_constant_override("h_separation",18);flow.add_theme_constant_override("v_separation",20)
 detail.add_child(flow)
 for type in [entry.card]+related:
  var column=VBoxContainer.new();column.custom_minimum_size.x=226
  column.name="EncyclopediaCardSection_"+type;flow.add_child(column)
  if not related.is_empty():
   var label="当前卡牌" if type==entry.card else Catalog.VARIANT_SOURCES.get(type,"衍生牌")
   column.add_child(host._label(label,15,host.CYAN if type==entry.card else host.GOLD))
  host._display_card(type,column,Callable(),"encyclopedia_"+type)
  var note=Catalog.card(type).note
  if note!="":
   var text=host._label(note,14,host.MUTED);text.custom_minimum_size.x=226
   text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(text)

func _art_selector(entry: Dictionary) -> void:
 var settings=host.display_settings
 var picker=OptionButton.new();picker.name="EncyclopediaArtStyle"
 picker.add_item("测试版画风");picker.add_item("正式版立绘")
 picker.set_item_disabled(1,not settings.has_formal_art(entry.category,entry.id))
 picker.select(1 if settings.art_style(entry.category,entry.id)=="formal" else 0)
 picker.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN;detail.add_child(picker)
 var note=host._label("正式版立绘未添加" if not settings.has_formal_art(entry.category,entry.id) else "",14,host.MUTED)
 note.name="EncyclopediaArtNote";note.visible=not note.text.is_empty();detail.add_child(note)
 picker.item_selected.connect(func(index):
  settings.set_art_style(entry.category,entry.id,"formal" if index==1 else "test")
  note.text=settings.save_error if not settings.save_error.is_empty() else ("正式版立绘未添加" if not settings.has_formal_art(entry.category,entry.id) else "")
  note.visible=not note.text.is_empty())
