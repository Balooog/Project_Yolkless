# StatBus Catalog

> Comfort-idle pacing demands consistent stat semantics. This catalog defines the canonical StatBus keys, units, and aggregation rules so every module maintains the same vocabulary.

| Key | Description | Unit | Update Cadence | Stack Rule | Owner |
| --- | ----------- | ---- | -------------- | ---------- | ----- |
| `pps` | Current production rate used for conveyors and UI display. | credits/sec | Economy tick (~10 Hz) | additive | Economy Service |
| `pps_base` | Base production rate before modifiers (prestige, comfort). | credits/sec | Economy tick | additive | Economy Service |
| `ci_bonus` | Comfort Index bonus derived from sandbox serenity; surfaced in EnvPanel summary and applied to Economy. | percent (+/-) | Environment→Sandbox (5 Hz) | additive (capped +5%) | Environment/Sandbox |
| `storage` | Current storage fill relative to capacity. | credits | Economy tick | last-write | Economy Service |
| `storage_capacity` | Max credits before auto shipment triggers. | credits | On unlock/reset | last-write | Economy Service |
| `conveyor_rate` | Smoothed items-per-second delivered by the active conveyor loop. | items/sec | Conveyor manager tick (~60 Hz) | replace | Economy Service |
| `conveyor_queue` | Current conveyor queue depth (items waiting to exit). | items | Conveyor manager tick | replace | Economy Service |
| `conveyor_delivered_total` | Total conveyor deliveries since session start. | items | On delivery | additive | Economy Service |
| `conveyor_jam_active` | 1 when the conveyor queue exceeds the jam threshold for ≥2.5 s. | bool | Conveyor manager tick | replace | Economy Service |
| `conveyor_backlog` | Mirror of current queue depth used for HUD Slot F. | items | Economy tick (≤10 Hz) | replace | Economy Service |
| `conveyor_backlog_label` | Localized copy for backlog status (e.g., `\"Queue 12\"`). | string | Economy tick | replace | UI Prototype |
| `wisdom_mult` | Prestige-derived production multiplier. | multiplier | On prestige/level up | multiplicative | Prestige System |
| `power_state` | Normalized power load (0-1). | ratio | Power ledger (~5 Hz) | last-write | Power Service |
| `power_warning_level` | Warning severity (`0` normal, `1` warning, `2` critical). | enum | Power ledger transitions | replace | Power Service |
| `power_warning_episodes` | Count of warning episodes triggered since session start. | count | Power ledger transitions | replace | Power Service |
| `auto_burst_ready` | Indicates autoburst queue status for UI. | bool | Automation tick (5 Hz) | last-write | Automation Service |
| `research_points` | Current RP pool for unlocks. | points | Research tick (1 Hz) | additive | Research Service |
| `comfort_index` | Raw comfort score before conversion to bonus; shown in EnvPanel detail grid. | 0-1 | Sandbox sim (2 Hz) | weighted average | Sandbox Service |
| `feed_fraction` | Feed tank percentage for HUD and VFX. | percent | Economy tick | last-write | Economy/Eco Feed |
| `event_modifier` | Aggregate modifier from temporary events. | multiplier | Event Director updates | multiplicative | Event Director |
| `offline_multiplier` | Passive production multiplier during offline calc. | multiplier | On save/load | multiplicative | Save/Offline Manager |
| `economy_rate` | PPS after all modifiers, smoothed for HUD Slot D. | credits/sec | Economy tick (≤10 Hz) | replace | Economy Service |
| `economy_rate_label` | Localized HUD copy for Slot D (e.g., `\"3.4/s\"`). | string | Economy tick | replace | UI Prototype |
| `automation_target` | Current automation mode/target selected in the Automation Panel (string enum). | string | On selection | replace | Automation Service |

## Usage Notes

- **Additive vs Multiplicative:** Modules must respect stack rules; for example, `ci_bonus` adds to other percentage boosts, while `wisdom_mult` multiplies base PPS.
- **Update Cadence:** Keep cadence consistent to avoid jitter. If a system needs a different rate, document it here before implementation.
- **Owner:** The owning service is responsible for validation and signal emission when the stat changes.

### Registration Example

```gdscript
var statbus := _get_statbus()
if statbus:
    statbus.register_modifier("sandbox", "ci_bonus", 0.05)
    statbus.set_stat(&"ci_bonus", bonus, "Sandbox")
```

### Stacking Rules

| Type | Combine Rule | Example |
| --- | --- | --- |
| additive | Sum contributions | `ci_bonus`, event `percent_boost` |
| multiplicative | Multiply modifiers | `pps_mult`, `wisdom_mult` |
| replace | Last writer wins | `storage_capacity`, `feed_fraction` |

## Governance & Caps
| Key | Unit | Stack Rule | Cap | Owner RM/PX | Enforced In |
| --- | ---- | ---------- | --- | ----------- | ----------- |
| `pps_base` | credits/sec | replace | n/a | RM-011 | `Economy.gd` |
| `ci_bonus` | multiplier (add) | additive | ≤ 0.05 | RM-021 / PX-021.1 | StatBus clamp |
| `event_modifier` | multiplier (add) | additive | ≤ 0.10 | RM-016 | StatBus clamp |
| `auto_burst_ready` | bool | replace | n/a | RM-013 | `AutomationService.gd` |
| `conveyor_rate` | items/sec | replace | n/a | PX-011.3 | `Economy.gd` |
| `conveyor_queue` | items | replace | Jam threshold 40 | PX-011.3 | `Economy.gd` |
| `conveyor_jam_active` | bool | replace | n/a | PX-011.3 | `Economy.gd` |
| `conveyor_backlog` | items | replace | Jam threshold 40 | PX-020.1 | `Economy.gd` |
| `conveyor_backlog_label` | string | replace | n/a | PX-020.1 | `UIPrototype` |
| `power_warning_level` | enum (0-2) | replace | n/a | PX-018.3 | `PowerService.gd` |
| `power_warning_episodes` | count | replace | n/a | PX-018.3 | `PowerService.gd` |
| `economy_rate` | credits/sec | replace | n/a | PX-020.1 | `Economy.gd` |
| `economy_rate_label` | string | replace | n/a | PX-020.1 | `UIPrototype` |
| `automation_target` | enum (string) | replace | n/a | PX-020.2 | `AutomationService.gd` |
| `micro_event_id` | Active micro-event identifier mirrored to StatsProbe’s event log (`event_id/kind/ts`). | string | replace | n/a | PX-016.2 | `SandboxService.gd` |

- StatBus clamps capped values and logs once per minute: `STATBUS: clamp ci_bonus 0.067→0.050`.
- New stats must declare owner and enforcement path before registration.

## Required References

- PX specs must include a link to this catalog when introducing new stats.
- Telemetry pipelines (see `/docs/quality/Telemetry_Replay.md`) should log stat keys verbatim.
- Implementation status tracked in [Architecture Alignment TODO](Implementation_TODO.md).
