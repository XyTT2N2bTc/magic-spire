extends RefCounted

# Pure backend arithmetic. Callers supply their domain's tightness (zero is valid).
# Locks, broken links and fixed-value equipment are replacement-specific rules.
static func from_profile(grade: int, tightness: int) -> int:
 return grade+tightness

# Tightness tiers are one ladder: tier n covers (TIER_RATIOS[n-1],TIER_RATIOS[n]] of durability/maximum.
# The two upper bounds carry a 1e-8 slack because damage arithmetic lands a hair above the exact edge.
# This module is the only place the ladder and its bounds are written; callers ask for a tier or a
# durability through the two functions below instead of re-listing the factors.
const TIER_RATIOS=[0.0,0.4,0.8,1.0]
const TIER_UPPER_1=0.40000001
const TIER_UPPER_2=0.80000001

# Tier-to-durability. Tier 0 is the released record and keeps its zero durability.
static func durability_for(maximum: float, tier: int) -> float:
 return maximum*TIER_RATIOS[tier]

# Ratio-to-tier. Zero durability reads as tier 0 regardless of maximum.
static func tier_for(durability: float, maximum: float) -> int:
 if durability<=0.000001: return 0
 var ratio=durability/maximum
 if ratio<=TIER_UPPER_1: return 1
 if ratio<=TIER_UPPER_2: return 2
 return 3

# Ascending grade order preserves existing self-binding candidates and RNG draws.
# Concrete template/slot legality and random selection belong to Application.
static func profiles(restraint_value: int) -> Array:
 var result=[]
 for grade in [1,2,3]:
  var tier=restraint_value-grade
  if tier>=1 and tier<=3: result.append({"grade":grade,"tier":tier})
 return result
