# Service Data Flow Diagram

> High-level view of signal flow between simulation services, StatBus, and UI. Use alongside [Overview](Overview.md) and [Signals & Events](Signals_Events.md).

```mermaid
graph TD
    EnvironmentService((Environment)) -->|factors 10 Hz| SandboxService((Sandbox))
    EnvironmentService -->|modifiers| PowerService((Power))
    PowerService -->|ratio| AutomationService((Automation))
    SandboxService -->|ci_bonus 2 Hz| StatBus[(StatBus)]
    AutomationService -->|auto_states| StatBus
    PowerService -->|power_state| StatBus
    StatBus -->|pull 10 Hz| Economy((Economy))
    Economy -->|metrics| UI[(UI Prototype)]
    Economy -->|shipments| Telemetry[(Telemetry/Replay)]
    UI -->|player input| AutomationService
```

- All nodes run on the main thread unless noted in PX-021.3 for future renderer workers.
- Telemetry pulls StatBus snapshots during replays; see [Telemetry & Replay](../quality/Telemetry_Replay.md).
