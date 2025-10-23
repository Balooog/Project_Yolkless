# Simulation & Update Cadence

Understanding when systems tick helps avoid double-counting updates or introducing race conditions. Use this quick reference when wiring new services.

## Frame Loop (Godot 4)

1. **Input** — Godot processes input events; `_unhandled_input` hooks fire (e.g., `Main.gd` handles feed presses).
2. **Physics** (`_physics_process`) — currently unused for economy systems.
3. **Process** (`_process(delta)`) — per-frame updates:
   - `Economy._process(delta)` → `_tick(delta)` applies PPS, feed drain/refill, storage auto-dump, and reevaluates automation against environment modifiers.
   - `Main._process(delta)` updates HUD feed meter; environment visuals now rely on the autoloaded `EnvironmentService`.
   - `EnvironmentService` advances seasonal curves, emits modifiers, and feeds the active stage/background.
   - Visual effects (e.g., `VisualDirector`) respond here while consuming the latest environment state.
4. **Timers** — Godot timers hooked to `Economy` drive auto-burst cadence and autosave intervals.

## Headless Simulation

- `Economy.simulate_tick(delta)` mirrors `_process(delta)` for deterministic headless runs from `ci/econ_probe.gd`.
- `tools/headless_tick.sh` should call into the headless probe, which advances the economy in fixed steps (e.g., 0.1s).

## Service Hooks

- **AutomationService (RM-013)**  
  - Should expose `tick(delta)` or subscribe to an `Economy.tick_completed` signal.
  - Runs after Economy applies income so automation can react to updated storage/feed state.

- **PowerService (RM-018)**  
  - Evaluate power ledger after Economy tick (consumption) and before Automation toggles run.
  - Emits `power_state_changed` for UI overlays and EnvironmentService adjustments.

- **EnvironmentService (RM-021)**  
  - Advances seasonal curves each frame, manages stage swaps, and raises `environment_updated` for UI, `Economy`, and `VisualDirector`.

- **Telemetry (RM-014)**  
  - Subscribes to per-tick signals and flushes aggregated metrics on a slower cadence (e.g., every second).

## Ordering Guideline

When wiring new services, aim for this order each frame:

1. Economy tick (`Economy._tick`)
2. Power ledger update (`PowerService.tick`)  
3. Automation decisions (`AutomationService.tick`)
4. Environment update (`EnvironmentService.update`) — modifiers ripple to economy/automation on the same frame
5. UI refresh (HUD, overlays)
6. Telemetry/log flush (if interval elapsed)

Use signals or a central dispatcher if the order becomes complex; avoid long `_process` chains inside `Main.gd`.
