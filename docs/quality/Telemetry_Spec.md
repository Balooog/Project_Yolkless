# Telemetry Spec

## Metrics Sources
- **StatBus autoload (`src/services/StatBus.gd`):** authoritative event router; all new metrics must flow through typed `emit_counter`/`emit_gauge` helpers and be documented in `docs/architecture/StatBus_Catalog.md`.
- **Headless replay (`tools/replay_headless.gd`):** nightly job seeds deterministic runs (default `--seed=42`) and writes aggregates into `reports/nightly/<run_id>/`.
- **UI overlay (`F3` debug panel):** surfaces Comfort Index, PPS, automation toggles, and recent StatBus packets for manual verification.

## Required Metrics
- `comfort.pct_live` — percent comfort after environment modifiers.
- `pps.instant` — eggs per second at the current tick.
- `sandbox.snapshot_ms` — latency for snapshot generation during automation runs.
- `ui.hud_latency_ms` — time from StatBus update to HUD redraw; keep <16 ms at 60 fps.
- `run.seed` — RNG seed attached to the session; must match replay artifacts.

## Retention & Dashboards
- Nightly replay artifacts archived for 14 days in `reports/nightly/`.
- Metrics dashboard spec lives in `docs/qa/Metrics_Dashboard_Spec.md`; add new metrics to both the spec and `docs/architecture/StatBus_Catalog.md`.
- LiveOps monitors comfort thresholds at least once per day. Trigger RM follow-ups in `docs/roadmap/ROADMAP_TASKS.md` when comfort dips below 85 %.

## Validation Workflow
1. Run `$(bash tools/godot_resolver.sh) --headless --script res://tools/replay_headless.gd --duration=300 --seed=42`.
2. Inspect generated CSV/JSON under `reports/nightly/<timestamp>/`.
3. Update `docs/qa/Metrics_Dashboard_Spec.md` if new columns or thresholds are introduced.
4. Capture anomalies in `docs/roadmap/RM/RM-Index.md` with linked StatBus snapshots.
