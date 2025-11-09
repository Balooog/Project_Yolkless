# Power Service Module

> RM-018 reference. Tracks grid load and conditions downstream visuals without touching simulation cadence.

## Purpose
- Maintain generation vs consumption ledger at fixed 10 Hz.
- Publish `power_ratio` and related stats to StatBus, Economy, and telemetry.
- Surface calm visual feedback (tint, icon, ambience) reflecting surplus/deficit.
- Load warning tier configuration from `data/power_config.json` so balancing can adjust thresholds without editing scripts.

## Responsibilities
| Area | Details |
| --- | --- |
| Ledger | Aggregate power producers/consumers; emit `power_state_changed`. |
| Modifiers | Provide additive multipliers to Economy throughput while leaving Sandbox tick untouched. |
| Visual cues | Drive tint and ambience shifts (cooler under deficit, warmer on surplus) for Conveyor/Sandbox renderers. |
| Telemetry | Report `power_ratio`, `power_tick_ms`, warning counts/durations, and alerts into StatsProbe streams. |

## Guardrails
- Never alter SandboxService cadence or CA state—power only feeds additive PPS modifiers via StatBus.
- Conveyor overlay speed stays PPS-driven; power deficits merely desaturate tint.
- AutomationService responds to power warnings with Economy adjustments, not sandbox animation tweaks.
- Reduce Motion mode still applies power tinting but avoids flicker or rapid pulses.

## Signals & Metrics
- Emits `power_state_changed(state: float)` (5 Hz) and `power_warning(level: StringName)` on level transitions (`normal` → `warning` → `critical`).
- StatBus surfaces `power_state`, `power_warning_level`, and `power_warning_episodes` (running episode count) for HUD/Automation gating.
- StatsProbe batches include `power_warning_level`, `power_warning_label`, `power_warning_count`, `power_warning_duration`, and `power_warning_min_ratio` so dashboards can chart duration and severity alongside tick timing.

## Testing
- Replay scenarios validate power surges keep CA tick constant and tint-only adjustments occur.
- Nightly telemetry compares `power_ratio` to conveyor tint state to ensure guardrails hold.

## Next Steps
- Model per-building generation/consumption once layout placement (RM-019) lands; document tables here.
- Coordinate with UI/Audio (RM-020) on calm warning cues and link assets when approved; replace placeholder clips (`power_warning_low/critical.wav`) once final mix lands.
- Add multi-zone grid design notes and telemetry expectations prior to Alpha→Beta gate per [Release Milestones](../ops/Release_Milestones.md).
- Extend `data/power_config.json` when new warning tiers or hysteresis behaviour land so the service remains data-driven.

See also: [Automation Module](automation.md), [Sandbox Module](sandbox.md), [Telemetry Guide](../quality/Telemetry_Replay.md).
