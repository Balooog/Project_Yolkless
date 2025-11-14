# Architecture Alignment TODO

Track items required to bring the current codebase in line with the high-level documentation. Owners should update this checklist as work lands; reference relevant RM/PX when filing tasks.

## Execution Sequence (Roadmap-Aligned)
- [ ] **Phase 0 - Alpha Hardening (solo plan)** *(PX-007.1, PX-011.3, PX-013.2, PX-014.4, PX-018.3)*
  - [x] PX-007.1 offline passive production flow and summary popup.
  - [x] PX-011.3 conveyor throughput integration with Economy and StatBus.
  - [ ] PX-013.2 automation HUD exposure plus scheduling preview.
  - [x] PX-014.4 telemetry diff dashboards in CI.
  - [x] PX-018.3 power warning feedback loop (tint, audio, telemetry).
- [ ] **Phase 1 — Stabilize Simulation Backbone** *(RM-021, docs/architecture/Overview.md, docs/design/Environment_Playbook.md)*
  - [x] Complete `SandboxService` CA implementation, telemetry mapping, and StatBus integration so comfort bonuses flow end-to-end (see `docs/prompts/PX-021.1.md`). *(Comfort bonus now hooked through EnvPanel and StatBus clamps in Economy.)*
  - [x] Author `data/environment_profiles.tsv` plus loader/preset wiring to unlock seasonal tuning (see `docs/data/Schemas.md`).
  - [x] Add sandbox double-buffering/perf smoothing to prep GPU paths while keeping within `docs/quality/Performance_Budgets.md`. *(SandboxService now buffers metrics with configurable release cadence.)*
  - [x] PX-021.2 follow-up: add adaptive sandbox tick skipping when `ci_delta` remains within ±0.0002 for ≥8 samples to cut p95 below 1 ms; throttle plant growth when `active_cells` stays maxed for multiple ticks. *(Skip logic + plant clamp in `SandboxService`/`SandboxGrid` bring sandbox p95 to ≈0.74 ms.)*
  - [x] PX-021.4 — Diorama era evolution (assets, camera, tint modulation) without resetting the sim. *(SandboxRenderer now applies era-specific camera/props; EnvPanel tooltip updated.)*
  - [x] PX-021.5 — Top-down map renderer + toggle (shared CA buffer, instant switch). *(View toggle + idle drift wired; map renderer feeds StatsProbe + CLI flag).*
  - [ ] PX-014.3 — Sandbox timelapse capture + nightly dashboard hook.
- [ ] **Phase 2 — Telemetry & Validation Foundation** *(docs/quality/Telemetry_Replay.md, docs/dev/Build_Cookbook.md)*
  - [x] Implement `tools/replay_headless.gd`, replace ad-hoc `ci/econ_probe.gd` usage, and document the workflow.
  - [x] Build `tools/validate_tables.py`, hook it into CI, and enforce schema checks for TSV/JSON assets. *(Script in place; CI hook tracked under telemetry follow-up.)*
  - [x] Add StatsProbe-style instrumentation to core services, surfacing budget adherence in telemetry dumps. *(Environment, Automation, Power, Economy now report tick metrics alongside Sandbox.)*
- [ ] **Phase 3 — Save Durability & Migration** *(docs/data/SaveSchema_v1.md)*
  - [x] Introduce `save_version`, wire migrations via `/src/persistence/migrations`, and update load paths.
  - [x] Write initial migration scripts with coverage in `tests/persistence/test_migrations.gd`; document rollback expectations.
- [ ] **Phase 4 — UX & Accessibility Polish** *(docs/ux/UI_Principles.md, docs/analysis/IdleGameComparative.md)*
  - [ ] Ship controller navigation + accessibility toggles promised in UI principles.
  - [x] Implement palette export tooling, populate `data/materials.tsv`, and sync art tokens (docs/art/Style_Guide.md).
  - [x] Audit UI copy against `docs/theme_map.md` and refresh prompts/strings where drifted; archive diffs in `docs/prompts/`.
- [ ] **Phase 5 — Systems Stress & Automation** *(docs/roadmap/, docs/quality/Playtest_Scenarios.md)*
  - [ ] Automate nightly telemetry replays (headless + log archival) and capture deltas/timelapse assets for dashboarding (PX-014.2, PX-014.3).
  - [ ] Re-benchmark Conveyor/Environment modules versus budgets and update `docs/modules/conveyor.md` and related ADRs as limits shift.
  - [ ] Extend QA checklists with comfort metrics, map-view coverage, and scripted playtest flows in `docs/qa/`.

## Core Simulation Spine
- [x] Introduce `StatBus` service with pull-by-default API, optional signal push, and cap enforcement/logging (see `StatBus_Catalog.md`).
- [x] Extract `SandboxService` implementing the Comfort Index loop and emitting `ci_changed`; wire to Economy for `ci_bonus`. *(Telemetry, StatBus, and EnvPanel display complete under PX-021.1 follow-up work.)*
- [x] Add `PowerService` and `AutomationService` as standalone autoloads; move automation timers out of `Economy`. *(Economy now delegates to these services; file PX for RM-013 behaviour layer.)*
- [x] Implement fixed 10 Hz update scheduler calling Environment → Sandbox → Economy (Power/Automation hooks stubbed). *(SimulationClock autoload handles cadence; refine ordering and power ledger next.)*

## Environment & Comfort
- [x] Extend `EnvironmentService` to emit Comfort Index components needed for sandbox inputs (heat/moisture/light).
- [x] Create environment profile data (`data/environment_profiles.tsv`) and loader. *(Prepare PX for RM-021 profile authoring when schema is drafted.)*

## Telemetry & Performance
- [x] Implement `tools/replay_headless.gd` matching CLI usage in `Telemetry_Replay.md`.
- [x] Add performance instrumentation (`StatsProbe.gd` or similar) to collect avg/p95 timings and log breaches of `Performance_Budgets.md`.
- [x] Build `/tools/validate_tables.py` referenced in `Schemas.md` and integrate with CI.

## Save & Persistence
- [x] Update save payload to include `save_version` and run migrations from `/src/persistence/migrations`. *(File PX for RM-save-schema when migration strategy is finalised.)*
- [x] Write initial migration scripts and tests (`/tests/persistence/test_migrations.gd`). *(Part of save-schema PX.)*
- [ ] File PX for save-schema migration once versioned format is designed.

## UX / Art
- [x] Implement controller navigation and color-blind palettes per `UI_Principles.md`. *(FocusMap wiring and palette toggles landed under RM-010.)*
- [ ] Create palette export script `tools/export_palette.gd` and populate `materials.tsv`. *(Tie to art pipeline PX.)*

## Reference
- Architecture docs: [Overview](Overview.md)
- Quality docs: [Performance_Budgets](../quality/Performance_Budgets.md), [Telemetry_Replay](../quality/Telemetry_Replay.md)
