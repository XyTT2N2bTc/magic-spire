extends RefCounted

# Presentation tokens only; no gameplay state or eligibility lives here.
const GOLD=Color("c9ad79")
const CYAN=Color("89d6d2")
const TEXT=Color("eee8d9")
const MUTED=Color("a5b3bd")
const RED=Color("ed9393")
const INK=Color("111d29")
# Committed-feedback border tokens (ui/impact_feedback.gd): one per trigger family,
# so a colour is never written inline at the effect site.
const BORDER_CALM=Color("f2ede0")
const BORDER_CHARGE=Color("e8c47b")
const BORDER_MANA=Color("8fd3ee")
const UI_FONT=preload("res://assets/fonts/NotoSansCJKsc-Regular.otf")

static func surface(bg: Color=INK, border: Color=GOLD.darkened(0.5), radius: int=8) -> StyleBoxFlat:
 var s=StyleBoxFlat.new()
 s.bg_color=bg;s.border_color=border
 s.set_border_width_all(1)
 s.set_corner_radius_all(radius)
 s.content_margin_left=12;s.content_margin_right=12
 s.content_margin_top=8;s.content_margin_bottom=8
 s.shadow_color=Color(0.015,0.022,0.035,0.45)
 s.shadow_size=4;s.shadow_offset=Vector2(0,2)
 return s

static func window_frame() -> StyleBoxTexture:
 var s=StyleBoxTexture.new();s.texture=preload("res://assets/ui/window-frame.svg")
 for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: s.set_texture_margin(side,24)
 s.content_margin_left=12;s.content_margin_right=12;s.content_margin_top=8;s.content_margin_bottom=8
 return s

static func button_style(state: String, accent: Color=GOLD) -> StyleBoxFlat:
 var backgrounds={"normal":Color("182733"),"hover":Color("29434c"),"pressed":Color("244b52"),"disabled":Color("121d27"),"focus":Color(0,0,0,0)}
 var edge=accent.darkened(0.42) if state=="normal" else (Color("394750") if state=="disabled" else accent)
 var s=surface(backgrounds[state],edge,8)
 s.shadow_size=2 if state=="normal" else 0
 if state in ["hover","pressed"]: s.border_width_left=3
 return s

static func controls() -> Theme:
 var t=Theme.new();t.default_font=UI_FONT;t.default_font_size=16
 for type in ["Button","OptionButton"]:
  for state in ["normal","hover","pressed","disabled","focus"]: t.set_stylebox(state,type,button_style(state))
  t.set_color("font_color",type,TEXT);t.set_color("font_hover_color",type,TEXT);t.set_color("font_pressed_color",type,TEXT)
  t.set_color("font_disabled_color",type,MUTED.darkened(0.2))
 for state in ["normal","read_only"]:
  var input=surface(Color("0d1923"),Color("46595f"),6);input.shadow_size=0
  t.set_stylebox(state,"LineEdit",input)
 t.set_stylebox("focus","LineEdit",button_style("focus",CYAN))
 t.set_color("font_color","LineEdit",TEXT);t.set_color("font_placeholder_color","LineEdit",MUTED)
 t.set_color("caret_color","LineEdit",CYAN);t.set_color("selection_color","LineEdit",Color("33585f"))
 t.set_stylebox("panel","PopupMenu",surface(INK,GOLD.darkened(0.5),8))
 t.set_stylebox("hover","PopupMenu",button_style("hover",CYAN))
 t.set_color("font_color","PopupMenu",TEXT);t.set_color("font_hover_color","PopupMenu",TEXT)
 for type in ["HSeparator","VSeparator"]:
  var line=StyleBoxLine.new();line.color=Color("48514c");line.thickness=1;line.vertical=type=="VSeparator"
  t.set_stylebox("separator",type,line)
 for type in ["VScrollBar","HScrollBar"]:
  var track=StyleBoxFlat.new();track.bg_color=Color("0a141e");track.set_corner_radius_all(4)
  track.content_margin_left=4;track.content_margin_right=4;track.content_margin_top=4;track.content_margin_bottom=4
  t.set_stylebox("scroll",type,track)
  for state in ["grabber","grabber_highlight","grabber_pressed"]:
   var grip=track.duplicate();grip.bg_color=Color("536b70") if state=="grabber" else CYAN.darkened(0.25)
   t.set_stylebox(state,type,grip)
 return t
