# Data Schemas Reference

> Central contract for TSV/JSON inputs. Keep balance data hot-reloadable and comfort-idle friendly by validating against these schemas.

## Validation Workflow
- Run the validator before committing balance or progression updates:
  ```bash
  ./tools/validate_tables.py --tables=data/upgrade.tsv,data/research.tsv --schema=docs/data/Schemas.md
  ```
- CI job `validate-tables` executes the same command on every change under `data/` and publishes logs to `logs/validation/YYYYMMDD.log`.

## `data/balance.tsv`
| Column | Type | Notes |
| ------ | ---- | ----- |
| `P0` | float | Base passive PPS; aligns with Balance Playbook first-session pacing. |
| `BURST_MULT` | float | Manual boost multiplier; ensure tap cadence remains relaxing. |
| `CAPACITY_BASE` | float | Starting storage cap before shipments trigger. |
| `DUMP_ON_FULL` | int (0/1) | Enables auto shipment logic. |
| `FEED_SUPPLY_*` | floats | Feed tank max/drain/refill values. |

### Section: `[UPGRADES]`
| Column | Type | Notes |
| ------ | ---- | ----- |
| `id` | string | Unique key (`prod_1`, `cap_1`). |
| `kind` | enum (`prod/cap/auto/...`) | Drives UI labelling. |
| `stat` | string | StatBus key affected. |
| `mult_add` | float | Additive bonus component. |
| `mult_mul` | float | Multiplicative bonus component. |
| `base_cost` | float | Price before growth. |
| `growth` | float | Exponential growth factor. |
| `requires` | string | Requirement DSL (`factory>=3`). |

## `game/data/research.tsv` (future split)
| Column | Type | Notes |
| ------ | ---- | ----- |
| `id` | string | Unique research node. |
| `branch` | enum | See Environment/Balance playbooks. |
| `stat` | string | StatBus key. |
| `mult_add/mult_mul` | float | Research impact. |
| `cost` | int | RP cost. |
| `prereq` | string/null | Unlock gating. |

**Parser Notes (TODO PX-016.1):** Loader `ResearchService._load_table(path)` expects DAG—validate with `/tools/validate_tables.py`. Pending columns: `name`, `desc`, `cost_rp:int`, `requires:csv`, `unlocks:csv`, `effect_key`, `effect_val:float`.

## `data/environment_profiles.tsv`
| Column | Type | Notes |
| ------ | ---- | ----- |
| `profile_id` | string | Unique preset key (e.g. `early_farm`, `colony_alpha`). |
| `label` | string | Designer-friendly display name. |
| `daylen` | float | Seconds per day cycle (≥120). |
| `temp_min` / `temp_max` | float | Temperature bounds (normalized 0–1) converted to °C. |
| `humidity_mean` / `humidity_swing` | float | Mean humidity and swing amplitude (0–1) mapped to percent. |
| `light_mean` / `light_swing` | float | Mean light level and swing amplitude (0–1). |
| `air_mean` / `air_swing` | float | Mean air quality and swing amplitude (0–1). |
| `wind_mean` | float | Average breeze strength (0–1) used for sandbox inputs. |
| `theme` | string | Theme token used for visuals/audio lookup. |
| `tier_min` | int | Minimum factory tier that unlocks the preset. |

**Parser Notes (TODO PX-021.2):** Loader `EnvironmentService._load_profiles(path)` consumes these columns, clamps ranges, and applies EMA smoothing configured via `data/environment_config.json`.

## `data/environment_config.json`
| Key | Type | Notes |
| --- | ---- | ----- |
| `ema_alpha` | float (0–1) | Exponential smoothing factor for environment input blending. |
| `hidden_tick_fraction` | float | Fraction of internal ticks skipped when the sandbox runs faster than UI refresh (reserved for GPU path). |
| `ci_window_size` | int (≥1) | Rolling window size for Comfort Index smoothing. |
| `active_window_size` | int (≥1) | Rolling window size for active cell coverage smoothing. |
| `metrics_double_buffer` | bool | Enables front/back buffering of sandbox metrics so consumers read stable snapshots. |
| `metrics_release_interval` | int (≥1) | Number of sandbox ticks to accumulate before swapping buffers (applies when double buffering is enabled). |

## `data/materials.tsv`
| Column | Type | Notes |
| ------ | ---- | ----- |
| `material_id` | string | Reusable palette tokens for art pipeline. |
| `hex` | string | Hex color; ensure WCAG contrast in Style Guide. |
| `usage` | string | e.g. `ui_panel`, `environment_haze`. |
| `contrast_hint` | string | Guidance for text pairing (`light_text`, `dark_text`, `toggle_safe`). |

## `docs/data/upgrade_families.tsv`
| Column | Type | Notes |
| --- | --- | --- |
| `id` | string | Unique upgrade tier id (matches Narrative Hooks key). |
| `family` | enum | One of `feed_optimization`, `shipment_tech`, `coop_automation`, `power_efficiency`, `comfort_tuning`. |
| `tier` | int | 0–3 progression tier. |
| `tier_name` | string | Display name (see Upgrade Families doc). |
| `flavor` | string | Flavor line (mirrors Narrative Hooks). |
| `stat` | string | Primary stat impacted (feed_rate, shipment_yield, etc.). |
| `base_mult` | float | Baseline multiplier applied at tier unlock. |
| `increment` | float | Per-upgrade scaling. |
| `cost_formula` | string | Human-readable cost function (future automation). |
| `unlock_via` | enum | `shop`, `research`, or `wisdom`. |

## Example Rows

### `balance.tsv`
```
# P0	BURST_MULT	CAPACITY_BASE	DUMP_ON_FULL
0.42	2.5	120.0	1
```

### `upgrade.tsv`
```
# id	kind	stat	mult_add	mult_mul	base_cost	growth	requires
prod_1	prod	pps	0.0	0.20	50	1.15	shipment_grade>=1
```

### `research.tsv`
```
# id	branch	stat	mult_add	mult_mul	cost	prereq
feed_automixer	utility	feed_rate	0.0	0.15	75	prod_1
```

### `environment_profiles.tsv`
```
# profile_id	label	daylen	temp_min	temp_max	humidity_mean	humidity_swing	light_mean	light_swing	air_mean	air_swing	wind_mean	theme	tier_min
early_farm	Backyard Dawn	420	0.35	0.68	0.55	0.18	0.62	0.20	0.78	0.08	0.40	temperate	1
```

### `environment_config.json`
```json
{
  "ema_alpha": 0.25,
  "ci_window_size": 4,
  "active_window_size": 4,
  "metrics_double_buffer": true,
  "metrics_release_interval": 2
}
```

## Sample Validator Output
```
$ ./tools/validate_tables.py --tables=data/upgrade.tsv --schema=docs/data/Schemas.md
[validate] upgrade.tsv: 0 errors, 0 warnings
[32mSUCCESS[0m  tables validated in 0.21s
```

## Validation Notes
- TSV files are parsed by `Balance.gd` and must use tab separators with comment lines starting `#`.
- New columns require parser updates and tests; document in ADR when altering schema.
- Environment profiles rely on EMA smoothing to avoid flicker—ensure config values stay between 0 and 1.
- Validation helpers live in `/tools/validate_tables.py`; the CI `validate-tables` job calls it automatically.

See also: [Save Schema v1](SaveSchema_v1.md) for persistence rules.
