# Modules Index

| Module | Owner Notes | Key Docs | Runtime Entry |
| --- | --- | --- | --- |
| Conveyor Loop | Drives egg production rate, queue fill, and burst payouts. Queue math tuned via `data/balance.tsv`. | `docs/design/Balance_Playbook.md`, `docs/analysis/IdleGameComparative.md` | `src/modules/conveyor/ConveyorProcessor.gd` |
| Automation Service | Manages auto-ship, feed macros, and prestige hooks. Ensure new toggles register with StatBus. | `AGENTS.md`, `docs/dev/build_gotchas.md` | `src/services/AutomationService.gd` |
| Environment Service | Controls comfort modifiers, weather beats, and visual cues; feeds into Comfort Index. | `docs/quality/Performance_Budgets.md`, `docs/qa/Metrics_Dashboard_Spec.md` | `src/services/EnvironmentService.gd` |
| Power Service | Tracks cost scaling for automation circuits; coordinates upgrade unlocks. | `docs/data/Schemas.md`, `docs/design/Upgrade_Families.md` | `src/services/PowerService.gd` |
| Sandbox Service | Provides simulation snapshots for testing; keep `SandboxGrid` API stable per guardrails. | `docs/qa/Test_Strategy.md`, `docs/dev/Tooling.md` | `src/services/SandboxService.gd` |
| StatBus | Central telemetry relay, persists metrics for dashboards and LiveOps. | `docs/architecture/StatBus_Catalog.md`, `docs/quality/Telemetry_Spec.md` | `src/services/StatBus.gd` |
