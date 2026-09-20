extends RefCounted
const Cases=preload("res://tests/membership_card_cases.gd")
const Pointer=preload("res://tests/target_sidebar_ui_cases.gd")

static func run(t) -> void:
 var ui=t.ui
 ui.restart(42);ui.game=Cases.shop()
 t.check(ui.game!=null,"MEMBERSHIP UI seeded store contains membership card")
 if ui.game==null: return
 ui.game.state.mana=100;ui.game.state.flask_mana=500;ui.shop_payment="flask"
 ui.render();await t.frames()
 var row=ui.view.shop.stock.filter(func(v):return v.type==Cases.TYPE)[0]
 var button=ui.find_child("ShopOffer%d" % row.index,true,false)
 t.check(button.disabled and t.visible_text(button).contains("仅可使用自身魔力购买") and row.price==100,"MEMBERSHIP UI shows original price and purchase-only payment restriction")
 await Pointer.press(t,ui.find_child("ShopPayment_self",true,false))
 await Pointer.press(t,ui.find_child("ShopOffer%d" % row.index,true,false))
 t.check(ui.view.mana==0 and ui.find_child("RelicShortcut_membership_card",true,false)!=null,"MEMBERSHIP UI real purchase grants icon after full self payment")
 await Pointer.press(t,ui.find_child("ShopPaymentContinue",true,false))
 await Pointer.press(t,ui.find_child("ShopPayment_flask",true,false))
 var card=ui.view.shop.stock.filter(func(v):return v.kind=="card" and not v.taken)[0]
 button=ui.find_child("ShopOffer%d" % card.index,true,false)
 t.check(not button.disabled and card.price==ui.game.room_data(ui.game.state.room).stock[card.index].price/2.0,"MEMBERSHIP UI existing goods immediately show half price and allow bottle payment")
 await Pointer.press(t,button)
 t.check(ui.view.mana_flask.mana==500-card.price and ui.view.mana==0,"MEMBERSHIP UI next purchase pays the displayed half price from bottle only")
 ui.restart(42);await t.frames()
