extends RefCounted

static func build(ui) -> void:
 var panel=ui.view.reward_panel
 var root=Control.new();root.name="RelicBundleRewards";root.z_index=81
 ui._place(root,Rect2(0,78,1600,822))
 var shade=ColorRect.new();shade.color=Color(0.018,0.026,0.04,0.94)
 ui._place(shade,Rect2(0,0,1600,822),root)
 var title=ui._label(panel.title,36,ui.GOLD);title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 ui._place(title,Rect2(420,83,760,58),root)
 var subtitle=ui._label(panel.destination,18,ui.MUTED);subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 ui._place(subtitle,Rect2(420,144,760,35),root)
 var width=280.0;var gap=28.0
 var left=(1600-panel.entries.size()*width-(panel.entries.size()-1)*gap)/2
 for entry in panel.entries:
  var color=ui.GOLD if entry.status=="pending" else ui.MUTED
  var card=Panel.new();card.name="BundleRelic_"+str(entry.index)
  card.add_theme_stylebox_override("panel",ui.Palette.surface(Color("152530"),color.darkened(0.25),12))
  ui._place(card,Rect2(left+entry.index*(width+gap),212,width,376),root)
  var rarity=ui._label(entry.rarity_label,16,color);rarity.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  ui._place(rarity,Rect2(12,12,256,28),card)
  var icon=preload("res://ui/relic_icon.gd").new();icon.relic=entry
  ui._place(icon,Rect2(92,43,96,96),card)
  var name=ui._label(entry.name,23,color);name.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  ui._place(name,Rect2(12,144,256,40),card)
  var detail=ui._label(entry.detail if entry.reason=="" else entry.reason,18,ui.TEXT if entry.reason=="" else ui.RED)
  detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  ui._place(detail,Rect2(22,191,236,109),card)
  if entry.status=="pending":
   var claim=ui.actions.by_id[entry.claim_id]
   var take=ui._button("领取",func():ui._submit(claim),ui.CYAN);take.disabled=not claim.valid
   take.name="BundleClaim_"+str(entry.index);ui._place(take,Rect2(22,310,144,46),card);ui.candidate_buttons[claim.id]=take
   var skip=ui.actions.by_id[entry.skip_id]
   var pass_button=ui._button("跳过",func():ui._submit(skip),ui.MUTED)
   pass_button.name="BundleSkip_"+str(entry.index);ui._place(pass_button,Rect2(176,310,82,46),card);ui.candidate_buttons[skip.id]=pass_button
  else:
   var status=ui._label("✓ 已领取" if entry.status=="claimed" else "已跳过",20,ui.MUTED)
   status.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;ui._place(status,Rect2(22,315,236,40),card)
 var finish=ui.actions.by_id[panel.continue_id]
 var button=ui._button("完成领取" if panel.entries.all(func(entry):return entry.status!="pending") else "跳过剩余并返回",func():ui._submit(finish),ui.GOLD)
 button.name="BundleContinue";ui._place(button,Rect2(625,641,350,54),root);ui.candidate_buttons[finish.id]=button
