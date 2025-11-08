# Economy Module Brief

The Economy service owns soft-currency generation, feed/burst pacing, and StatBus surface area for HUD + telemetry consumers.  PX-020 introduces explicit `economy_rate` visibility so production pace stays transparent from the HUD to headless replays.

## Responsibilities
- Calculate `current_pps()` each tick, applying comfort, automation, and power modifiers documented in [architecture/Overview](../architecture/Overview.md).
- Manage feed/burst state, storage caps, and shipment events surfaced through existing signals (`soft_changed`, `storage_changed`, `dump_triggered`).
- Emit PX-020 signals and StatBus values so HUD Slot D, automation panels, and telemetry can render consistent copy.

## Key Signals
| Signal | Payload | Notes |
| --- | --- | --- |
| `economy_rate_changed(rate: float, label: String)` | PPS (post-mod) plus formatted label (e.g., `3.2/s`) | Fired ≤10 Hz.  HUD Slot D + Top Banner listen; telemetry prints labels every 10 s. |
| `conveyor_backlog_changed(queue: int, label: String, tone: StringName)` | Queue depth, formatted copy (`"Queue 12"`, `"Queue 45 ⚠"`), tone token (`normal`/`warning`) | Mirrors jam heuristics from Conveyor module.  Feeds Slot F + tooltips.
| `conveyor_metrics_changed(rate: float, queue: int, jam: bool)` | Existing signal kept for panel/automation consumers | Documented here so PX-020 readers see the lineage.

Reference the full signal table in [Signals & Events](../architecture/Signals_Events.md).

## StatBus Keys
| Key | Unit | Stack Rule | Owner | Notes |
| --- | --- | --- | --- | --- |
| `economy_rate` | credits/sec | replace | Economy | Smoothed PPS (EMA with 0.2 weight).  Mirrors `current_pps()` after modifiers. |
| `economy_rate_label` | string | replace | UIPrototype | Formatted text used by HUD/panel; logged so telemetry snapshots stay human-readable. |
| `conveyor_backlog` | items | replace | Economy | Raw queue length derived from ConveyorManager. |
| `conveyor_backlog_label` | string | replace | UIPrototype | Copy identical to Slot F label for dashboards. |

See [StatBus Catalog](../architecture/StatBus_Catalog.md) for stack-governance details.

## Rate Smoothing & Thresholds
- PPS smoothing uses an exponential moving average (EMA) with `alpha = 0.2` to avoid flicker while still reacting within ~5 HUD frames.
- Backlog warnings trigger when queue ≥40 for ≥2.5 seconds.  Tone escalates to `warning` and tooltips append the jam note defined in [PX-020.3](../px/PX-020.3_Tooltips_Copy.md).
- Automation throttling (PX-013.2/PX-020.2) can temporarily clamp rate; `economy_rate_changed` still fires so panels update instantly.

## Integration Points
- **HUD:** Slots D/F defined in [UI Matrix](../ui_baselines/ui_matrix.md).  Labels pull directly from the signals above.
- **Automation Panel:** Uses `automation_target_changed` plus `economy_rate` deltas to preview the impact of auto-modes.
- **Telemetry:** `tools/replay_headless.gd` records both numeric rates and labels; CSV columns reside after the economy profiling columns.

## Acceptance Guardrails
- Any change that affects PPS or conveyor backlog must update this file, the StatBus catalog, and PX-020 docs simultaneously.
- The economy service must continue emitting typed values (floats/ints) to avoid Variant warnings—CI treats warnings as errors per [docs/dev/build_gotchas.md](../dev/build_gotchas.md).
