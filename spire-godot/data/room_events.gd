extends RefCounted

# Recipes freeze into explicit effects on arrival. No gameplay logic in UI text.
static var TYPES={}

static func pool() -> Array:
 return TYPES.keys().filter(func(id):return TYPES[id].get("pool",true))
const REFUSAL_MANA=10.0
const Cards=preload("res://data/card_rules.gd")
# Event rewards use the same three rarity names shown on cards.
const CARD_POOLS={"common":Cards.COMMON,"uncommon":Cards.UNCOMMON,"rare":Cards.RARE}
const LEGACY_CARD_REWARDS={"advanced":"uncommon"}

static func card_reward_kind(kind: String) -> String:
 return LEGACY_CARD_REWARDS.get(kind,kind)

static func is_card_reward(kind: String) -> bool:
 return CARD_POOLS.has(card_reward_kind(kind))

static func card_pool(kind: String) -> Array:
 return CARD_POOLS.get(card_reward_kind(kind),[])
