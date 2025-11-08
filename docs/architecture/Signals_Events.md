# Signals & Events Matrix

> Single source of truth for cross-service communication. Emitters must document payloads before merging.

| Emitter | Signal | Payload | Primary Listeners | Frequency |
| ------- | ------ | ------- | ----------------- | -------- |
| `Economy` | `soft_changed(value: float)` | `{ value: credits }` | UI prototype, telemetry, VisualDirector | on every balance change (~10 Hz) |
| `Economy` | `storage_changed(value: float, capacity: float)` | `{ storage, capacity }` | HUD storage bar, StatBus | on storage delta |
| `Economy` | `dump_triggered(amount: float, new_balance: float)` | `{ amount, balance }` | HUD pulse, telemetry, analytics | when auto shipment fires |
| `Economy` | `burst_state(active: bool)` | `{ active }` | VisualDirector, AutomationService | on feed start/stop |
| `Economy` | `economy_rate_changed(rate: float, label: String)` | `{ rate, label }` | HUD Slot D, telemetry probes | on PPS delta (≤10 Hz) |
| `Economy` | `conveyor_backlog_changed(queue_len: int, label: String, tone: StringName)` | `{ queue, label, tone }` | HUD Slot F, StatBus dashboards, Alerts | on conveyor queue delta |
| `EnvironmentService` | `environment_updated(state: Dictionary)` | `{ temperature, light, humidity, modifiers, ci }` | SandboxService, UI EnvPanel, StatBus | 5 Hz |
| `EnvironmentService` | `day_phase_changed(phase: StringName)` | `{ phase }` | Lighting, Audio | phase transitions |
| `EnvironmentService` | `preset_changed(preset: StringName)` | `{ preset }` | UI dropdown, telemetry | on preset swap |
| `UIPrototype` | `feed_hold_started()` | `{}` | Main, Sandbox ConveyorOverlay, AudioService | user input press |
| `UIPrototype` | `feed_hold_ended()` | `{}` | Main, Sandbox ConveyorOverlay, AudioService | user input release |
| `UIPrototype` | `feed_burst(mult: float)` | `{ mult }` | ConveyorOverlay, AudioService, StatsProbe (planned) | per Economy burst |
| `SandboxService` | `ci_changed(ci: float, bonus: float)` | `{ ci, bonus }` | Economy StatBus, Telemetry | 2 Hz |
| `SandboxRenderer` | `fallback_state_changed(active: bool)` | `{ active }` | Telemetry, EnvPanel tooltip, debug overlay | on fallback enter/exit |
| `AutomationService` | `mode_changed(building_id: StringName, mode: int)` | `{ building_id, mode }` | UI overlays, save system | when automation toggles |
| `AutomationService` | `auto_burst_enqueued()` | `{}` | HUD queue indicator, telemetry | when queue increments |
| `PowerService` | `power_state_changed(state: float)` | `{ state }` | UI, AutomationService | 5 Hz |
| `EventDirector` | `event_started(event_id: StringName, data: Dictionary)` | `{ id, modifiers, duration }` | UI popups, telemetry | event start |
| `EventDirector` | `event_ended(event_id: StringName)` | `{ id }` | UI popups, telemetry | event completion |
| `ShopService` | `state_changed(id: StringName)` | `{ id, state }` | UI buttons, ShopDebug | on price/lock change |
| `Research` | `changed()` | `{}` | UI sheets, telemetry | on RP spend |
| `ConveyorManager` | `throughput_updated(rate: float, queue_len: int)` | `{ rate, queue }` | Economy, HUD, StatBus | per frame |
| `Save` | `autosave_started()` | `{}` | UI toast | on autosave |
| `Save` | `autosave_completed(result: bool)` | `{ ok }` | UI toast | on autosave |

## Event Metadata Guidelines

- Payloads should be flat dictionaries for easy serialization.
- If emitting high-frequency signals (>10 Hz), ensure listeners can throttle updates.
- When adding a new signal, update this table and cross-link related PXs.
- Implementation status tracked in [Architecture Alignment TODO](Implementation_TODO.md).

## Listener Map & Throttling
| Signal | Emitter Path | Typical Hz | Listeners | Throttle Rule |
| ------ | ------------- | ---------- | --------- | ------------- |
| `environment_changed(factors)` | `/root/EnvironmentService` | 10 | PowerService `/root/PowerService`, SandboxService `/root/SandboxService`, HUD `/root/Main/UI` | HUD throttled to 5 Hz |
| `ci_changed(ci, bonus)` | `/root/SandboxService` | 2 | StatBus `/root/StatBus`, HUD comfort widget | none |
| `power_warning(level)` | `/root/PowerService` | burst | HUD `/root/Main/UI`, AutomationService `/root/AutomationService` | Transitions only; service dedupes normal → warning → critical |
| `throughput_updated(rate, queue)` | `/root/Main/ConveyorManager` | 60 | Economy `/root/Main/Economy`, HUD stats, Telemetry probe | HUD samples at 10 Hz; Economy smooths and clamps |
| `feed_hold_started/ended` | `/root/Main/UIPrototype` | user input | Main, ConveyorOverlay, AudioService | none; reacts instantly |
| `feed_burst(mult)` | `/root/Main/UIPrototype` | burst | ConveyorOverlay, AudioService, StatsProbe | clamp burst spam to ≤30 Hz upstream |

## Signal Lifetimes & Context

| Signal | Thread | Emission Timing | Notes |
| --- | --- | --- | --- |
| `environment_updated` | Main thread | End of EnvironmentService tick | Safe to mutate StatBus/SceneTree. |
| `ci_changed` | Main thread | After SandboxService smoothing (2 Hz) | Renderer metrics may dispatch separately via StatsProbe worker in future PX-021.3. |
| `power_state_changed` | Main thread | Immediately after power ledger recompute | Listener must avoid heavy work; throttle in UI. |
| `power_warning` | Main thread | Immediately after warning level transitions | Levels: `normal`, `warning`, `critical`; StatBus exposes numeric level for dashboards. |
| `auto_burst_enqueued` | Main thread | Within AutomationService tick | Emits during queue increments; avoid expensive logging. |
| `throughput_updated` | Main thread | Every frame (60 Hz) | Downstream should sample at ≤10 Hz to avoid UI spam. |
| `stats_probe_alert` *(future)* | Worker thread | After StatsProbe batch flush | Must `call_deferred` to interact with UI/SceneTree. |
| `feed_burst` | Main thread | After Economy confirms burst multiplier | Deterministic timing; overlay applies EMA before anim kicks. |
| `feed_hold_started/ended` | Main thread | Immediate on input press/release | Keep work lightweight to avoid UI hitching; use deferred audio triggers if needed. |
