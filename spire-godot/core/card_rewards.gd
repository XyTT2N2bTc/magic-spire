extends RefCounted
const Rules=preload("res://data/card_rules.gd")

# Roll each displayed slot in order. Negative rare probability also reduces
# the uncommon band; clamping the first threshold would change the distribution.
static func rarity(source: String, offset: int, roll: int) -> String:
 if source=="boss": return "rare"
 var rate=Rules.REWARD_RATES[source]
 if roll<rate.rare+offset: return "rare"
 if roll<rate.rare+offset+rate.uncommon: return "uncommon"
 return "common"

static func next_offset(offset: int, tier: String) -> int:
 if tier=="rare": return Rules.RARE_OFFSET_INITIAL
 return mini(Rules.RARE_OFFSET_MAX,offset+1) if tier=="common" else offset

static func offer(g, pool: Array, source: String, rng=null, count: int=3) -> Array:
 var available=pool.duplicate()
 var chosen=[]
 while not available.is_empty() and chosen.size()<count:
  var tier=""
  if source!="fixed":
   var roll=g._random_index("reward",100) if rng==null else rng.randi_range(0,99)
   tier=rarity(source,g.state.rare_offset,roll)
  var candidates=available if tier=="" else available.filter(func(id):return Rules.SPECS[id].rarity==tier)
  # Formal weighted pools contain at least three cards of every tier.
  assert(not candidates.is_empty(),"Reward pool lacks the selected rarity")
  if candidates.is_empty(): return []
  var index=g._random_index("reward",candidates.size()) if rng==null else rng.randi_range(0,candidates.size()-1)
  var type=candidates[index]
  chosen.append(type);available.erase(type)
  if source!="fixed": g.state.rare_offset=next_offset(g.state.rare_offset,tier)
 return chosen
