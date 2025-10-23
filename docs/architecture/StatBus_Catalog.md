# StatBus Catalog

> Comfort-idle pacing demands consistent stat semantics. This catalog defines the canonical StatBus keys, units, and aggregation rules so every module maintains the same vocabulary.

| Key | Description | Unit | Update Cadence | Stack Rule | Owner |
| --- | ----------- | ---- | -------------- | ---------- | ----- |
| `pps` | Current production rate used for conveyors and UI display. | credits/sec | Economy tick (~10 Hz) | additive | Economy Service |
| `pps_base` | Base production rate before modifiers (prestige, comfort). | credits/sec | Economy tick | additive | Economy Service |
| `ci_bonus` | Comfort Index bonus derived from sandbox serenity. | percent (+/-) | Environment→Sandbox (5 Hz) | additive (capped +5%) | Environment/Sandbox |
| `storage` | Current storage fill relative to capacity. | credits | Economy tick | last-write | Economy Service |
| `storage_capacity` | Max credits before auto shipment triggers. | credits | On unlock/reset | last-write | Economy Service |
| `wisdom_mult` | Prestige-derived production multiplier. | multiplier | On prestige/level up | multiplicative | Prestige System |
| `power_state` | Normalized power load (0-1). | ratio | Power ledger (~5 Hz) | last-write | Power Service |
| `auto_burst_ready` | Indicates autoburst queue status for UI. | bool | Automation tick (5 Hz) | last-write | Automation Service |
| `research_points` | Current RP pool for unlocks. | points | Research tick (1 Hz) | additive | Research Service |
| `comfort_index` | Raw comfort score before conversion to bonus. | 0-1 | Sandbox sim (2 Hz) | weighted average | Sandbox Service |
| `feed_fraction` | Feed tank percentage for HUD and VFX. | percent | Economy tick | last-write | Economy/Eco Feed |
| `event_modifier` | Aggregate modifier from temporary events. | multiplier | Event Director updates | multiplicative | Event Director |
| `offline_multiplier` | Passive production multiplier during offline calc. | multiplier | On save/load | multiplicative | Save/Offline Manager |

## Usage Notes

- **Additive vs Multiplicative:** Modules must respect stack rules; for example, `ci_bonus` adds to other percentage boosts, while `wisdom_mult` multiplies base PPS.
- **Update Cadence:** Keep cadence consistent to avoid jitter. If a system needs a different rate, document it here before implementation.
- **Owner:** The owning service is responsible for validation and signal emission when the stat changes.

## Required References

- PX specs must include a link to this catalog when introducing new stats.
- Telemetry pipelines (see `/docs/quality/Telemetry_Replay.md`) should log stat keys verbatim.
