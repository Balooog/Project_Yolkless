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

## Comfort Index Formula
```
ci = clamp(0.0, 1.0, base + vegetation_bonus - stress_penalty)
ci_bonus = min(0.05, ci * 0.05)
```
- `base`: weighted average of heat/moisture/light.
- `vegetation_bonus`: sandbox flora density.
- `stress_penalty`: small deduction when power deficits or events active.

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
