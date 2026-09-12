extends RefCounted
# Prices paid as currency, never as a spell.
const CARD_PRICES={"common":15.0,"uncommon":25.0,"rare":40.0}
const RELIC_PRICES={"common":45.0,"uncommon":65.0,"rare":90.0,"special":45.0}
const PRICES={"shard":10.0,"saw":15.0,"picks":18.0,"remove":25.0,"mana_potion":15.0,"energy_potion":15.0,"charge_potion":15.0,"draw_scroll":15.0,"mana_scroll":15.0,"casting_scroll":15.0,"lubricant_potion":15.0}
const TOOLS=["shard","saw","picks","mana_potion","energy_potion","charge_potion","draw_scroll","mana_scroll","casting_scroll","lubricant_potion"]
const CARD_SLOTS={"common":2,"uncommon":2,"rare":1}
const TOOL_SLOTS=4
const RELIC_SLOTS=3

# Merchant labor is currency payment, not spell/energy use. Surcharges stack once per job.
const RELEASE={"base":20.0,"composite":15.0,"locked":10.0}
