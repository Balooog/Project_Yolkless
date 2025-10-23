# Architecture Alignment TODO

Track items required to bring the current codebase in line with the high-level documentation.  Owners should update this checklist as work lands; reference relevant RM/PX when filing tasks.

## Core Simulation Spine
- [ ] Introduce `StatBus` service with pull-by-default API, optional signal push, and cap enforcement/logging (see `StatBus_Catalog.md`).
- [ ] Extract `SandboxService` implementing Comfort Index loop and emitting `ci_changed`; wire to Economy for `ci_bonus`.
- [ ] Add `PowerService` and `AutomationService` as standalone autoloads; move automation timers out of `Economy`.
- [ ] Implement fixed 10 Hz update scheduler that calls Environment → Power → Sandbox → Automation → Economy in order.

## Environment & Comfort
- [ ] Extend `EnvironmentService` to emit Comfort Index components needed for sandbox inputs (heat/moisture/light).
- [ ] Create environment profile data (`data/environment_profiles.tsv`) and loader.
- [ ] Implement smoothing/double-buffer strategy for any GPU sandbox work.

## Telemetry & Performance
- [ ] Implement `tools/replay_headless.gd` matching CLI usage in `Telemetry_Replay.md`.
- [ ] Add performance instrumentation (`StatsProbe.gd` or similar) to collect avg/p95 timings and log breaches of `Performance_Budgets.md`.
- [ ] Build `/tools/validate_tables.py` referenced in `Schemas.md` and integrate with CI.

## Save & Persistence
- [ ] Update save payload to include `save_version` and run migrations from `/src/persistence/migrations`.
- [ ] Write initial migration scripts and tests (`/tests/persistence/test_migrations.gd`).

## UX / Art
- [ ] Implement controller navigation and color-blind palettes per `UI_Principles.md`.
- [ ] Create palette export script `tools/export_palette.gd` and `materials.tsv`.

## Reference
- Architecture docs: [Overview](Overview.md)
- Quality docs: [Performance_Budgets](../quality/Performance_Budgets.md), [Telemetry_Replay](../quality/Telemetry_Replay.md)
