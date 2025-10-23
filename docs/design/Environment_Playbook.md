# Environment Playbook

> Guides EnvironmentService presets, sandbox mapping, and Comfort Index smoothing.

## Preset Profiles
| Profile | Description | Comfort Cap | Notes |
| ------- | ----------- | ----------- | ----- |
| `temperate` | Default backyard climate with mild swings. | +5% | Balanced day/night cycle. |
| `arid` | Dry, bright; increases feed drain slightly. | +4% | Unlock later; ensure humidity penalties stay gentle. |
| `space_colony` | Prestige preset with controlled climate. | +6% | Minimal variance; unlock via Wisdom. |

## Milestone Transitions
- Tier promotions trigger preset swaps; ensure 10 s crossfade to avoid abrupt changes.
- Wisdom prestige grants access to `space_colony`; apply linear interpolation over 30 s.

## Sandbox Input Mapping
| Factor | Sandbox Input | Range | Effect |
| ------ | ------------- | ----- | ------ |
| Temperature | `heat` | 0.2–0.8 | Higher heat increases cell energy, raising comfort until threshold. |
| Humidity | `moisture` | 0.3–0.7 | Supports vegetation visuals; extremes reduce comfort. |
| Light | `breeze` | 0.2–0.9 | Drives particle flow speed. |

## Comfort Index Formula (provisional)
```
CI = clamp(
  0.45 * stability_score      # inverse of rapid state changes
  + 0.35 * diversity_score    # distinct material coverage 15–45%
  + 0.20 * entropy_score      # pattern entropy within target band
, 0.0, 1.0)

ci_bonus = clamp(CI * 0.05, 0.0, 0.05)
```
- Log `CI`, components, and preset at 1 Hz in dev builds.
- Adjust weights to keep average CI ≈ 0.6 under temperate profile.
- TODO: implement SandboxService pipeline emitting these values (see [Architecture Alignment TODO](../architecture/Implementation_TODO.md)).

## Smoothing Strategies
- Apply exponential smoothing (`alpha = 0.25`) to comfort output before updating StatBus.
- Emit signals at 2 Hz to avoid UI jitter.

## Sanity Checks
- Ensure environment curves never exceed 0–1 range.
- Validate Comfort Index stays within ±0.02 frame-to-frame under steady conditions.
- Telemetry must log `ci`, `ci_bonus`, and preset name.

## References
- Architecture flow: [Overview](../architecture/Overview.md)
- StatBus fields: [StatBus Catalog](../architecture/StatBus_Catalog.md)
