# Performance Budgets

> Comfort-idle design relies on smooth motion and calm feedback. These budgets set expectations for subsystem cost per frame on target hardware (Steam Deck & mid-range laptops).

| System | Budget (ms) | Update Rate | Notes |
| ------ | ----------- | ----------- | ----- |
| Economy tick | ≤ 1.5 ms | 10 Hz | Includes feed drain/refill, stat computations. |
| Sandbox simulation | ≤ 2.0 ms | 5 Hz | Cellular automata on 128×72 grid; run in pools. |
| EnvironmentService | ≤ 0.5 ms | 5 Hz | Curve sampling + CA inputs. |
| AutomationService | ≤ 1.0 ms | 5 Hz | Scheduling decisions + mode updates. |
| PowerService | ≤ 0.8 ms | 5 Hz | Ledger recompute and StatBus push. |
| EventDirector | ≤ 0.2 ms | event start/end | Lightweight payload diff only. |
| ConveyorManager visuals | ≤ 1.5 ms | per frame | Token pooling, interpolation. |
| UI Prototype updates | ≤ 2.5 ms | per frame | Includes layout, StatBus binding. |
| Telemetry flush | ≤ 0.5 ms | 1 Hz | Batch writes to file/log. |
| Save autosave | ≤ 10 ms | every 30 s | Run in background thread if possible. |

## Object Pooling Targets

- Conveyor tokens: max 500 active (`FactoryConveyor.tscn`).
- Sandbox cells: reuse buffers; avoid per-frame allocation.
- Feed particle instances: pool size 64 with GPU instancing.

## Monitoring

- Add perf counters to `/docs/quality/Telemetry_Replay.md` scenarios.
- Any module exceeding budgets must file an ADR or PX hotfix referencing this document.
