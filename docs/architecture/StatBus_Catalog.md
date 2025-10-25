# StatBus Catalog

> Comfort-idle pacing demands consistent stat semantics. This catalog defines the canonical StatBus keys, units, and aggregation rules so every module maintains the same vocabulary.

| Key | Description | Unit | Update Cadence | Stack Rule | Owner |
| --- | ----------- | ---- | -------------- | ---------- | ----- |
| `pps` | Current production rate used for conveyors and UI display. | credits/sec | Economy tick (~10 Hz) | additive | Economy Service |
| `pps_base` | Base production rate before modifiers (prestige, comfort). | credits/sec | Economy tick | additive | Economy Service |
| `ci_bonus` | Comfort Index bonus derived from sandbox serenity; surfaced in EnvPanel summary and applied to Economy. | percent (+/-) | Environment→Sandbox (5 Hz) | additive (capped +5%) | Environment/Sandbox |
| `storage` | Current storage fill relative to capacity. | credits | Economy tick | last-write | Economy Service |
| `storage_capacity` | Max credits before auto shipment triggers. | credits | On unlock/reset | last-write | Economy Service |
| `wisdom_mult` | Prestige-derived production multiplier. | multiplier | On prestige/level up | multiplicative | Prestige System |
| `power_state` | Normalized power load (0-1). | ratio | Power ledger (~5 Hz) | last-write | Power Service |
| `auto_burst_ready` | Indicates autoburst queue status for UI. | bool | Automation tick (5 Hz) | last-write | Automation Service |
| `research_points` | Current RP pool for unlocks. | points | Research tick (1 Hz) | additive | Research Service |
| `comfort_index` | Raw comfort score before conversion to bonus; shown in EnvPanel detail grid. | 0-1 | Sandbox sim (2 Hz) | weighted average | Sandbox Service |
| `feed_fraction` | Feed tank percentage for HUD and VFX. | percent | Economy tick | last-write | Economy/Eco Feed |
| `event_modifier` | Aggregate modifier from temporary events. | multiplier | Event Director updates | multiplicative | Event Director |
| `offline_multiplier` | Passive production multiplier during offline calc. | multiplier | On save/load | multiplicative | Save/Offline Manager |

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

- StatBus clamps capped values and logs once per minute: `STATBUS: clamp ci_bonus 0.067→0.050`.
- New stats must declare owner and enforcement path before registration.

## Required References

- PX specs must include a link to this catalog when introducing new stats.
- Telemetry pipelines (see `/docs/quality/Telemetry_Replay.md`) should log stat keys verbatim.
- Implementation status tracked in [Architecture Alignment TODO](Implementation_TODO.md).
