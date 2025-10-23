# Data Schemas Reference

> Central contract for TSV/JSON inputs. Keep balance data hot-reloadable and comfort-idle friendly by validating against these schemas.

## `game/data/balance.tsv`
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

## `data/environment_profiles.tsv`
| Column | Type | Notes |
| ------ | ---- | ----- |
| `profile_id` | string | e.g. `temperate`, `space_colony`. |
| `season_curve` | Curve resource path | Points to `.tres` for temperature cycle. |
| `light_curve`, `humidity_curve`, `air_quality_curve` | Curve path | Must be normalized 0‑1. |
| `comfort_cap` | float | Max comfort contribution; reference Environment Playbook. |

## `data/materials.tsv`
| Column | Type | Notes |
| ------ | ---- | ----- |
| `material_id` | string | Reusable palette tokens for art pipeline. |
| `hex` | string | Hex color; ensure WCAG contrast in Style Guide. |
| `usage` | string | e.g. `ui_panel`, `environment_haze`. |

## Validation Notes
- TSV files are parsed by `Balance.gd` and must use tab separators with comment lines starting `#`.
- New columns require parser updates and tests; document in ADR when altering schema.
- Curves referenced by environment profiles should be checked during load to prevent runtime asserts.

See also: [Save Schema v1](SaveSchema_v1.md) for persistence rules.
