# Automation Service Module

> RM-013 reference. Coordinates autoburst cadence and machine toggles while respecting fixed sandbox timing.

## Purpose
- Schedule automated feed bursts, promotions, and machine states at 10 Hz.
- Apply additive modifiers from StatBus (Comfort, Power, Events) directly to Economy throughput.
- Surface automation status to UI and telemetry without introducing jitter.

## Responsibilities
| Area | Details |
| --- | --- |
| Scheduling | Manage autoburst cooldowns, queue lengths, and promotions. |
| Economy hooks | Apply throughput changes, never mutating Sandbox or CA buffers. |
| Power conditioning | Respond to `power_ratio` warnings by adjusting Economy goals, not render cadence. |
| Telemetry | Emit automation tick metrics, queue lengths, and mode changes. |

## Guardrails
- SandboxService cadence is immutable; automation must not slow or speed CA updates or conveyor visuals.
- Conveyor speed mirrors PPS and burst state only; automation never feeds alternative speed multipliers.
- Mini-games and accessibility toggles that halve motion apply **after** automation calculations so deterministic results remain.
- PPS bonuses from mini-games stack additively with Comfort Index; no multiplicative stacking allowed.

## Signals & Metrics
- Consumes `power_state_changed`, `ci_changed`, and Economy burst events.
- Emits `mode_changed(building_id, mode)` and `auto_burst_enqueued()`.
- StatsProbe records `automation_tick_ms_avg/p95`, queue depth, and autoburst cadence.

## Testing
- Integration tests verify automation toggles do not impact sandbox render cadence (check `sandbox_render_ms_*`).
- Mini-game replay runs confirm PPS bursts remain deterministic with automation active.

See also: [Power Module](power.md), [Sandbox Module](sandbox.md), [Test Strategy](../qa/Test_Strategy.md).
