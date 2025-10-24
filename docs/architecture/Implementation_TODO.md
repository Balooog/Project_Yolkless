# Architecture Alignment TODO

Track items required to bring the current codebase in line with the high-level documentation. Owners should update this checklist as work lands; reference relevant RM/PX when filing tasks.

## Core Simulation Spine
- [x] Introduce `StatBus` service with pull-by-default API, optional signal push, and cap enforcement/logging (see `StatBus_Catalog.md`).
- [ ] Extract `SandboxService` implementing the Comfort Index loop and emitting `ci_changed`; wire to Economy for `ci_bonus`. *(Partial: smoothing stub in place.)*
    - TODO: File PX (RM-021) for sandbox CA implementation, telemetry mapping, and StatBus integration.
 - [x] Add `PowerService` and `AutomationService` as standalone autoloads; move automation timers out of `Economy`. *(Economy now delegates to these services; file PX for RM-013 behaviour layer.)*
- [x] Implement fixed 10 Hz update scheduler calling Environment → Sandbox → Economy (Power/Automation hooks stubbed). *(SimulationClock autoload handles cadence; refine ordering and power ledger next.)*

## Environment & Comfort
- [x] Extend `EnvironmentService` to emit Comfort Index components needed for sandbox inputs (heat/moisture/light).
- [ ] Create environment profile data (`data/environment_profiles.tsv`) and loader. *(Prepare PX for RM-021 profile authoring when schema is drafted.)*
- [ ] Implement smoothing/double-buffer strategy for GPU sandbox work. *(Bundle with sandbox CA PX.)*

## Telemetry & Performance
- [ ] Implement `tools/replay_headless.gd` matching CLI usage in `Telemetry_Replay.md`.
- [ ] Add performance instrumentation (`StatsProbe.gd` or similar) to collect avg/p95 timings and log breaches of `Performance_Budgets.md`.
- [ ] Build `/tools/validate_tables.py` referenced in `Schemas.md` and integrate with CI.

## Save & Persistence
- [ ] Update save payload to include `save_version` and run migrations from `/src/persistence/migrations`. *(File PX for RM-save-schema when migration strategy is finalised.)*
- [ ] Write initial migration scripts and tests (`/tests/persistence/test_migrations.gd`). *(Part of save-schema PX.)*
- [ ] File PX for save-schema migration once versioned format is designed.

## UX / Art
- [ ] Implement controller navigation and color-blind palettes per `UI_Principles.md`. *(Bundle into forthcoming RM-010 PX.)*
- [ ] Create palette export script `tools/export_palette.gd` and populate `materials.tsv`. *(Tie to art pipeline PX.)*

## Reference
- Architecture docs: [Overview](Overview.md)
- Quality docs: [Performance_Budgets](../quality/Performance_Budgets.md), [Telemetry_Replay](../quality/Telemetry_Replay.md)
