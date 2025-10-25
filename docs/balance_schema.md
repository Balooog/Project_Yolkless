# Yolkless Balance TSV Schema

**File:** `res://data/balance.tsv` (TSV; `\t` separated).  
**Sections** are bracketed headers. Comment lines start with `#`.

## [CONSTANTS]
| key                | value (float) | Notes                         |
|--------------------|---------------|-------------------------------|
| P0                 | 0.4           | Base production per second    |
| BURST_MULT         | 6.0           | Burst multiplier              |
| BURST_DURATION     | 5.0           | Seconds                       |
| BURST_COOLDOWN     | 10.0          | Seconds                       |
| OFFLINE_CAP_HOURS  | 8             | Max offline sim window        |
| OFFLINE_EFFICIENCY | 0.8           | Fraction of simulated output  |
| OFFLINE_PASSIVE_MULT | 0.25        | Fraction of base PPS used offline |
| OFFLINE_AUTOMATION_BONUS | 1.5     | Passive multiplier with automation |
| AUTOSAVE_SECONDS   | 30            | Interval for autosave         |
| STORAGE_SOFTCAP_CURVE | 0.0        | Pre-upgrade decay curve (0 disables) |
| DUMP_ON_FULL       | 1             | 1 auto-sells storage at 100 % |
| DUMP_ANIM_MS       | 300           | HUD pulse duration in ms      |
| FEED_SUPPLY_MAX    | 100           | Manual feed capacity          |
| FEED_SUPPLY_DRAIN_RATE | 25        | Feed drain rate while held    |
| FEED_SUPPLY_REFILL_RATE | 16       | Feed refill rate when idle    |

## [UPGRADES] (soft-currency, per-run)
`id  kind  stat  mult_add  mult_mul  base_cost  growth  requires`
- `kind`: `prod|cap|auto|misc`
- `stat`: name the effect. Examples:
  - `mul_prod` (multiplicative to PPS)
  - `mul_cap`  (multiplicative to Capacity)
  - `unlock_autoburst` (boolean unlock when level ≥ 1)
- `requires`: gate like `factory>=3` or `-`.

**Cost:** `cost(level) = base_cost * growth^level` (level starts at 0).

## [FACTORY_TIERS]
`tier  display_name  cap_mult  prod_mult  unlocks  cost`
- `unlocks`: free-form flags (`auto`, `research_tab`, etc.)
- `cost`: Soft required to promote to this tier.

## [AUTOMATION]
`id  type  value  description`
- `auto_burst` → `tick_seconds`
- `auto_burst_efficiency` → `mult` (e.g., 0.85 vs manual)

## [RESEARCH] (prestige-only, permanent)
`id  branch  stat  mult_add  mult_mul  cost  prereq`
- `branch`: `production|capacity|automation|misc`
- `stat`: e.g., `mul_prod`, `mul_cap`, `auto_cd` (seconds, additive, negatives speed up)
- `cost`: Prestige points.

## [PRESTIGE]
| key   | value | Notes                            |
|-------|-------|----------------------------------|
| K     | 0.01  | Scaling constant                 |
| ALPHA | 0.6   | Exponent in `floor(K * earned^a)`|

## [PRICES]
`id  type  price  visible  notes`
- `type`: currently `UPGRADE` rows gate early-shop entries.
- `visible`: `1` keeps the upgrade in the UI; `0` hides it until future beats.
- When present, `price` overrides the upgrade's `base_cost` from `[UPGRADES]`.

## [HUD_FLAGS]
`key  value`
- Flags (0/1) toggling HUD features (PPS label, storage bar visibility, dump pulse).
- Useful when iterating on UI scaffolding without code edits.
