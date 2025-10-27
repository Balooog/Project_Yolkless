# Telemetry & Replay Guide

> Ensures balance changes respect comfort-idle pacing by simulating long sessions with consistent metrics. See [Glossary](../Glossary.md) for terminology.

## Log Formats
- **CSV (`logs/telemetry/*.csv`)**: Columns include `timestamp`, `pps`, `storage`, `ci_bonus`, `event`, `power_state`, `active_cells`, `sandbox_render_view_mode`, `sandbox_render_fallback_active`, `minigame_active`.
- **JSON (`logs/telemetry/*.json`)**: Batch summaries with averages/percentiles plus per-scenario arrays for shipments and comfort samples (`{ "time", "ci", "bonus" }`).
- All entries include `scenario` tag (e.g., `hands_off`, `burst_cycle`).

## Headless CLI
```bash
# 5 minute hands-off baseline
godot --headless --path . --script res://tools/replay_headless.gd --duration=300 --seed=12345 --strategy=idle --env_renderer=sandbox
```
- Outputs human-readable log to `logs/yolkless.log` and summary JSON at `logs/telemetry/replay_YYYYMMDD_HHMM.json`.
- Command flags: `--duration` (seconds), `--seed`, `--dt` (tick size, default 0.1), `--strategy` (`normal|burst|idle|pulse`).
- StatsProbe writes additional CSV snapshots to `logs/perf/tick_<timestamp>.csv`, ignores `ci_delta` alerts for the first ~2 s of sampling to avoid warm-up spikes, and clamps alerts to tighter budgets (`tick_ms > 1.9`, `active_cells > 400`, `|ci_delta| > 0.05`, `sandbox_render_ms_p95 > 1.0`, renderer frame p95 > 18 ms sustained for ≥5 s).

## Key Metrics
| Metric | Source | Purpose |
| ------ | ------ | ------- |
| `pps` | StatBus / StatsProbe | Verifies pacing vs Balance Playbook. |
| `ci_bonus` / `ci` | SandboxService / StatsProbe | Tracks serenity gains from environment tuning. |
| `shipment_interval` | Economy dump log | Ensures early shipments stay within comfort bounds. |
| `power_state` | PowerService | Detects stress from power deficits. |
| `sandbox_tick_ms_p95` | StatsProbe | Guards the ≤1.9 ms sandbox budget at 10 Hz. |
| `sandbox_render_ms_p95` | StatsProbe | Flags viewport render cost breaching the 1.0 ms target. |
| `sandbox_render_ms_avg` | StatsProbe | Tracks steady-state renderer cost for trend analysis. |
| `sandbox_render_fallback_ratio` | StatsProbe | Measures how often the renderer halves its cadence (target ≈0 %). |
| `belt_anim_ms_p95` / `_avg` | StatsProbe | Confirms conveyor overlay stays under the 0.2 ms budget even during bursts. |
| `environment_tick_ms_p95` | StatsProbe | Confirms EnvironmentService stays under the 0.5 ms budget while updating curves. |
| `automation_tick_ms_p95` | StatsProbe | Tracks AutomationService scheduling cost vs the 1.0 ms target. |
| `power_tick_ms_p95` | StatsProbe | Ensures PowerService updates remain beneath the 0.8 ms threshold. |
| `economy_tick_ms_p95` | StatsProbe | Verifies the Economy loop respects the 1.5 ms budget (see `economy_pps_avg` for pacing). |
| `active_cells_max` | StatsProbe | Surfaces sandbox load spikes (SandboxGrid coverage). |
| `ci_delta_abs_max` | StatsProbe | Flags sudden comfort swings that may indicate instability. |
| `minigame_active` / `minigame_duration` | Replay controller | Ensures mini-game cooldown rules remain isolated from Credits/RP. |
| `sandbox_render_view_mode` | StatsProbe | Tracks active renderer view (`diorama`, `map`, etc.) for guardrail coverage. |

## Replay Workflow
1. Run headless scenario (hands-off + burst).
2. Import CSV into analysis notebook or spreadsheet.
3. Compare against baseline thresholds (see `Performance_Budgets.md`).
4. Record results in QA checklist (`docs/qa/`).

## Automation Hooks
- CI job `nightly-replay` runs:
  ```bash
  godot --headless --path . --script res://tools/replay_headless.gd --duration=300 --seed=42
  ```
  capturing StatsProbe CSV + JSON summary under `/reports/nightly/<date>/`.
- Replay summary aggregates StatsProbe alerts (tick_ms, active_cells, ci delta) and flags ±15 % drift as “⚠️ Perf drift” in Codex dashboards.
- Validator job `validate-tables` must pass before telemetry runs to ensure data consistency.
- Local dry-runs can use `./tools/nightly_replay.sh` (honours `GODOT_BIN`, `DURATION`, `SEED`, `STRATEGY`) to mirror the CI workflow and snapshot artifacts into `reports/nightly/<timestamp>/`.

## Instrumentation Fields
- `service`, `tick_ms`, `pps`, `ci`, `active_cells`, `power_ratio`, `ci_delta`, `storage`, `feed_fraction`, `power_state`, `auto_active`, `minigame_active`, `minigame_duration` sampled at 10 Hz (fields populate per service).
- Renderer stream adds 1 Hz aggregates: `sandbox_render_ms_avg`, `sandbox_render_ms_p95`, `sandbox_render_fallback_ratio`, `belt_anim_ms_avg`, `belt_anim_ms_p95`, `sandbox_render_view_mode`.
- Alerts emitted through `stats_probe_alert(metric, value, threshold)` and copied into replay JSON under `alerts`.
- CSV naming convention: `logs/perf/tick_<timestamp>.csv`; JSON graph exported to `/reports/nightly/<date>.json` with companion PNG trend. JSON summaries now include `sandbox_tick_ms_p95`, `sandbox_render_ms_p95`, `sandbox_render_ms_avg`, `sandbox_render_fallback_ratio`, `sandbox_render_view_mode`, `active_cells_max`, and `ci_delta_abs_max` for regression tracking.

## Metric Normalization Formulas
```
perf_score = (target_ms / max(actual_ms, 0.0001)) * 100
ci_stability = 1 - abs(ci_delta_avg)
```
- Targets: sandbox render ≤1.0 ms, environment tick ≤0.5 ms, economy tick ≤1.5 ms (see [Performance Budgets](Performance_Budgets.md)).
- `perf_score < 80` triggers StatsProbe `performance_warning` alerts; investigate replay CSVs.
- `ci_stability < 0.9` indicates oscillations; cross-check Environment profiles and Comfort tuning.

## Alert Routing
- StatsProbe alerts populate replay JSON `alerts` array; each record includes `metric`, `value`, `threshold`, and `timestamp`.
- CI `publish-artifacts` stage attaches `alerts.json` plus screenshot diffs for quick triage.
- Future Pager/Slack integrations will consume the same payload; keep field names stable.

## Sample JSON Output
```json
{
  "tick_ms_p95": 4.6,
  "pps_avg": 3.12,
  "ci_avg": 0.61,
  "power_ratio_avg": 0.95,
  "alerts": []
}
```
See also: [Metrics Dashboard Spec](../qa/Metrics_Dashboard_Spec.md) for nightly aggregation.

## References
- [Performance Budgets](Performance_Budgets.md)
- [StatBus Catalog](../architecture/StatBus_Catalog.md)
