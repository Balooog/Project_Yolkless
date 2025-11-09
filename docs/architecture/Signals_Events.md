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
| `AutomationPanel` | `automation_panel_opened()` | `{}` | AutomationService, UIPrototype, telemetry | on panel open (tab switches into Automation sheet) |
| `AutomationPanel` | `automation_panel_closed()` | `{}` | AutomationService, UIPrototype | on panel close (tab leaves Automation sheet) |
| `AutomationPanel` | `automation_target_changed(target_id: StringName)` | `{ target }` | AutomationService, StatBus/Telemetry | on target swap |
| `SandboxService` | `ci_changed(ci: float, bonus: float)` | `{ ci, bonus }` | Economy StatBus, Telemetry | 2 Hz |
| `SandboxService` | `event_started(event_id: String, definition: Dictionary)` | `{ id, ui_copy, buttons, duration, effects }` | Main HUD micro-event card, StatsProbe | when an event enters the active queue |
| `SandboxService` | `event_accepted(event_id: String, definition: Dictionary)` | `{ id, ui_copy }` | HUD (hide card), Economy (apply accept effects) | on player accept |
| `SandboxService` | `event_declined(event_id: String, definition: Dictionary)` | `{ id }` | HUD (clear), Economy/Power rollback | on player decline |
| `SandboxService` | `event_completed(event_id: String, definition: Dictionary)` | `{ id, elapsed }` | HUD (clear), telemetry review (StatsProbe log) | on timer/callback completion |
| `SandboxService` | `event_toast_requested(string_key: String)` | `{ key }` | HUD toast system, Audio cues | when events request follow-up messaging |
| `SandboxRenderer` | `fallback_state_changed(active: bool)` | `{ active }` | Telemetry, EnvPanel tooltip, debug overlay | on fallback enter/exit |
| `AutomationService` | `mode_changed(building_id: StringName, mode: int)` | `{ building_id, mode }` | UI overlays, save system | when automation toggles |
| `AutomationService` | `auto_burst_enqueued()` | `{}` | HUD queue indicator, telemetry | when queue increments |
| `PowerService` | `power_state_changed(state: float)` | `{ state }` | UI, AutomationService | 5 Hz |
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
| `automation_panel_opened/closed` | `/root/Main/UIPrototype/AutomationPanel` | user input | AutomationService, UIPrototype, telemetry logger | telemetry logs only once per open/close pair |
| `automation_target_changed(target)` | `/root/Main/UIPrototype/AutomationPanel` | per selection | AutomationService, Economy | emit immediately; StatBus uses replace stacking |

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
| `automation_panel_opened` | Main thread | On Automation Panel show animation start | Use for StatBus/telemetry; do not block UI transitions. |
| `automation_panel_closed` | Main thread | After panel exits and focus returns | Fired even if no target changed to keep telemetry balanced. |
| `automation_target_changed` | Main thread | When user selects a new automation target | Economy should debounce costly recomputations; StatBus writes replace data. |
