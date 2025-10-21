# Yolkless Balance TSV Schema

**File:** `res://game/data/balance.tsv` (TSV; `\t` separated).  
**Sections** are bracketed headers. Comment lines start with `#`.

## [CONSTANTS]
| key                | value (float) | Notes                         |
|--------------------|---------------|-------------------------------|
| P0                 | 1.0           | Base production per second    |
| BURST_MULT         | 6.0           | Burst multiplier              |
| BURST_DURATION     | 5.0           | Seconds                       |
| BURST_COOLDOWN     | 10.0          | Seconds                       |
| OFFLINE_CAP_HOURS  | 8             | Max offline sim window        |
| OFFLINE_EFFICIENCY | 0.8           | Fraction of simulated output  |
| AUTOSAVE_SECONDS   | 30            | Interval for autosave         |

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
