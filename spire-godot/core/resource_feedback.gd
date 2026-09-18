extends RefCounted
# Transient transaction receipt; never saved or used for rule decisions.
const FIELDS={"mana":"魔力","flask_mana":"魔瓶魔力","charge":"蓄力","temporary_mana":"临时魔力","next_energy":"下回合能量","pressure":"快感","witch_focus":"精神集中"}
var previous={}
var events=[]

func capture(state: Dictionary, source: String="") -> void:
 for key in FIELDS:
  # witch_focus exists only on the witch character's state; every other field is
  # always present, so a missing key is skipped instead of aborting the receipt.
  if not state.has(key): continue
  var value=state[key]
  if previous.has(key) and value!=previous[key]:
   events.append({"field":key,"label":FIELDS[key],"before":previous[key],"after":value,"source":source})
  previous[key]=value

func relic(state: Dictionary, source: String) -> void:
 var count=events.size()
 capture(state,source)
 if events.size()==count: events.append({"field":"","label":source,"source":source})
