# Power Service Module

> RM-018 reference. Tracks grid load and conditions downstream visuals without touching simulation cadence.

## Purpose
- Maintain generation vs consumption ledger at fixed 10 Hz.
- Publish `power_ratio` and related stats to StatBus, Economy, and telemetry.
- Surface calm visual feedback (tint, ambience) reflecting surplus/deficit.

## Responsibilities
| Area | Details |
| --- | --- |
| Ledger | Aggregate power producers/consumers; emit `power_state_changed`. |
| Modifiers | Provide additive multipliers to Economy throughput while leaving Sandbox tick untouched. |
| Visual cues | Drive tint and ambience shifts (cooler under deficit, warmer on surplus) for Conveyor/Sandbox renderers. |
| Telemetry | Report `power_ratio`, `power_tick_ms`, and alerts into StatsProbe streams. |

## Guardrails
- Never alter SandboxService cadence or CA state—power only feeds additive PPS modifiers via StatBus.
- Conveyor overlay speed stays PPS-driven; power deficits merely desaturate tint.
- AutomationService responds to power warnings with Economy adjustments, not sandbox animation tweaks.
- Reduce Motion mode still applies power tinting but avoids flicker or rapid pulses.

## Signals & Metrics
- Emits `power_state_changed(state: float)` (5 Hz) and optional `power_warning(level: float)` for deficit alerts.
- StatsProbe gathers `power_tick_ms_avg/p95`, `power_ratio`, and logs deficits for nightly dashboards.

## Testing
- Replay scenarios validate power surges keep CA tick constant and tint-only adjustments occur.
- Nightly telemetry compares `power_ratio` to conveyor tint state to ensure guardrails hold.

## Next Steps
- Model per-building generation/consumption once layout placement (RM-019) lands; document tables here.
- Coordinate with UI/Audio (RM-020) on calm warning cues and link assets when approved.
- Add multi-zone grid design notes and telemetry expectations prior to Alpha→Beta gate per [Release Milestones](../ops/Release_Milestones.md).

See also: [Automation Module](automation.md), [Sandbox Module](sandbox.md), [Telemetry Guide](../quality/Telemetry_Replay.md).
