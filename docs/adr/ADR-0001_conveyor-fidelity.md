# ADR-0001: Conveyor Fidelity Strategy

- **Status:** Accepted (2025-10-24)
- **Context:** RM-009 requires smooth conveyors that feel alive without stressing frame budgets.

## Decision
Use pooled logic with sampled visuals:
- Maintain a lightweight logic layer handling queueing and throughput at 60 FPS.
- Render items via pooled `ConveyorItem` sprites with lerped positions.
- Cap active tokens at 500 and reuse sprites to avoid allocations.

## Rationale
- Aligns with comfort-idle pacing—smooth motion without jitter.
- Keeps performance within the 1.5 ms conveyor budget (see `Performance_Budgets.md`).
- Enables telemetry sampling of throughput without per-item events.

## Consequences
- Requires object pool maintenance when adding new belt skins.
- Visual fidelity improvements must respect pool limits.
- Telemetry should derive from manager stats, not per-item logs.

## References
- [Conveyor Module Doc](../modules/conveyor.md)
- [StatBus Catalog](../architecture/StatBus_Catalog.md)
