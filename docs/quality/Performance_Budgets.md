# Performance Budgets

> Comfort-idle design relies on smooth motion and calm feedback. These budgets set expectations for subsystem cost per frame on target hardware (Steam Deck & mid-range laptops). Terminology: [Glossary](../Glossary.md).

| System | Budget (ms) | Update Rate | Notes |
| ------ | ----------- | ----------- | ----- |
| Economy tick | ≤ 1.5 ms *(provisional)* | 10 Hz | Includes feed drain/refill, stat computations. |
| Sandbox simulation | ≤ 2.0 ms *(provisional)* | 5 Hz | Cellular automata on 32×18 grid; run in pools. (*Latest p95 @2025-10-25: 1.24 ms after downscaling; monitor as content grows*) |
| Sandbox viewport render | ≤ 1.0 ms *(target)* | 60 Hz | `SandboxRenderer` uploads dirty cells, nearest-neighbour upscale. Fallback halves cadence if frame p95 >18 ms for 5 s. |
| EnvironmentService | ≤ 0.5 ms | 5 Hz | Curve sampling + CA inputs. |
| AutomationService | ≤ 1.0 ms *(provisional)* | 5 Hz | Scheduling decisions + mode updates. |
| PowerService | ≤ 0.8 ms | 5 Hz | Ledger recompute and StatBus push. |
| EventDirector | ≤ 0.2 ms | event start/end | Lightweight payload diff only. |
| ConveyorManager visuals | ≤ 1.5 ms *(provisional)* | per frame | Token pooling, interpolation. (*Latest active item count exceeded cap; see below*) |
| UI Prototype updates | ≤ 2.5 ms *(provisional)* | per frame | Includes layout, StatBus binding, token application. |
| Telemetry flush | ≤ 0.5 ms | 1 Hz | Batch writes to file/log. |
| Save autosave | ≤ 10 ms | every 30 s | Run in background thread if possible. |

## Object Pooling Targets

- Conveyor tokens: max 500 active (`FactoryConveyor.tscn`).
- Sandbox cells: reuse buffers; avoid per-frame allocation.
- Feed particle instances: pool size 64 with GPU instancing.

## Monitoring

- Add perf counters to `/docs/quality/Telemetry_Replay.md` scenarios.
- Any module exceeding budgets must file an ADR or PX hotfix referencing this document.
- StatsProbe exports per-service tick metrics (`sandbox/environment/automation/power/economy/ui`) and renderer telemetry (`sandbox_render_ms_avg`, `sandbox_render_ms_p95`, `sandbox_uploads_per_sec`, `sandbox_dirty_pixels_avg`) so nightly telemetry can flag budget regressions automatically.
- UI visual regression harness (PX-010.9) compares baseline screenshots; >1% diff requires review before merge.
- **Latest StatsProbe benchmark (2025-10-25):** `sandbox_tick_ms_p95=1.85 ms`, `active_cells_max≈243`, `pps_avg≈0.94`. Budgets are now satisfied after reducing the sandbox grid footprint and pooling conveyor items; keep an eye on these metrics as belts become busier.

## Memory & Draw Call Targets

| System | Draw Calls (p95) | Memory Budget | Notes |
| --- | --- | --- | --- |
| UI Prototype | ≤ 60 | ≤ 35 MB | Includes panels, sheets, tooltips. Tokenised theme reduces duplication. |
| Sandbox Renderer | ≤ 20 | ≤ 10 MB | Image buffer + texture; fallback halves cadence if exceeded. |
| Conveyor Visuals | ≤ 80 | ≤ 40 MB | Pools belt items; reuse sprite frames. |
| Environment Stage | ≤ 50 | ≤ 25 MB | Procedural background + overlays. |
| Telemetry/StatsProbe | n/a | ≤ 5 MB | CSV buffers + alert queue. |

## Profiling Method
- Measure with Godot Profiler alongside `StatsProbe.gd` for 60 s idle and 60 s burst runs.
- Capture average, p95, and max timings; include snapshots in PRs adjusting budgets.
- Validate conveyor token cap (500) via `/tools/stress_sandbox.gd --tokens=500` before increasing limits. The latest telemetry keeps `active_cells_max` below the cap; re-run after any conveyor tuning.
