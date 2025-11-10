# Telemetry & Replay Guide

> Ensures balance changes respect comfort-idle pacing by simulating long sessions with consistent metrics. See [Glossary](../Glossary.md) for terminology.

## Log Formats
- **CSV (`logs/perf/tick_*.csv`)**: StatsProbe now appends PX-020 columns to each row:  
  `...,eco_statbus_ms,eco_ui_ms,economy_rate,economy_rate_label,conveyor_backlog,conveyor_backlog_label,automation_target,automation_target_label,automation_panel_visible`.  
  These rows join the existing `pps`, `storage`, `ci_bonus`, `power_state`, `sandbox_render_*`, and minigame fields so a single CSV captures both performance budgets and HUD copy context.
- **JSON (`logs/telemetry/replay_*.json`)**: Batch summaries with averages/percentiles plus per-scenario arrays for shipments, comfort samples (`{ "time", "ci", "bonus" }`), and the new `hud_labels` array (see **PX-020 HUD Label Samples**).  StatsProbe aggregates (`economy_rate_avg`, `conveyor_backlog_avg`, `automation_target_last`, etc.) land under the `stats` key.
- **Console (`headless.log`)**: Every replay prints `[hud] economy_rate=… | conveyor_backlog=…` every ~10 s and `[automation] p95=… panel_vis=…` after StatsProbe flushes.  Capture these lines when attaching artifacts.
- All entries include a `scenario` tag (e.g., `hands_off`, `burst_cycle`).

## Headless CLI
```bash
# 5 minute hands-off baseline
godot --headless --path . --script res://tools/replay_headless.gd --duration=300 --seed=12345 --strategy=idle --env_renderer=sandbox --sandbox_view=diorama

# Map-view perf soak
godot --headless --path . --script res://tools/replay_headless.gd --duration=300 --seed=12345 --strategy=idle --env_renderer=sandbox --sandbox_view=map

# Spread shipment bookkeeping over two frames
godot --headless --path . --script res://tools/replay_headless.gd --duration=300 --economy_amortize_shipment=true
```
- Outputs human-readable log to `logs/yolkless.log` and summary JSON at `logs/telemetry/replay_YYYYMMDD_HHMM.json`.
- Command flags: `--duration` (seconds), `--seed`, `--dt` (tick size, default 0.1), `--strategy` (`normal|burst|idle|pulse`), `--env_renderer` (`legacy|sandbox`), `--sandbox_view` (`diorama|map`), `--economy_amortize_shipment` (true/false, defaults to false).
- StatsProbe writes additional CSV snapshots to `logs/perf/tick_<timestamp>.csv`, ignores `ci_delta` alerts for the first ~2 s of sampling to avoid warm-up spikes, and clamps alerts to tighter budgets (`tick_ms > 1.9`, `active_cells > 400`, `|ci_delta| > 0.05`, `sandbox_render_ms_p95 > 1.0`, renderer frame p95 > 18 ms sustained for ≥5 s).

## Key Metrics
| Metric | Source | Purpose |
| ------ | ------ | ------- |
| `pps` | StatBus / StatsProbe | Verifies pacing vs Balance Playbook. |
| `ci_bonus` / `ci` | SandboxService / StatsProbe | Tracks serenity gains from environment tuning. |
| `shipment_interval` | Economy dump log | Ensures early shipments stay within comfort bounds. |
| `power_state` | PowerService | Detects stress from power deficits. |
| `power_warning_level` | PowerService | Enum severity mapped from StatBus (0 normal, 1 warning, 2 critical). |
| `power_warning_label` | PowerService | String label mirroring severity for dashboards. |
| `power_warning_count` | PowerService | Running total of warning episodes, useful for correlating automation throttles vs. deficits. |
| `power_warning_duration` | PowerService | Duration (seconds) of the active warning episode (0 when stable). |
| `power_warning_min_ratio` | PowerService | Lowest power ratio observed during the active episode (or last completed episode). |
| `sandbox_tick_ms_p95` | StatsProbe | Guards the ≤1.9 ms sandbox budget at 10 Hz. |
| `sandbox_render_ms_p95` | StatsProbe | Flags viewport render cost breaching the 1.0 ms target. |
| `sandbox_render_ms_avg` | StatsProbe | Tracks steady-state renderer cost for trend analysis. |
| `sandbox_render_fallback_ratio` | StatsProbe | Measures how often the renderer halves its cadence (target ≈0 %). |
| `belt_anim_ms_p95` / `_avg` | StatsProbe | Confirms conveyor overlay stays under the 0.2 ms budget even during bursts. |
| `conveyor_rate` / `conveyor_queue` | StatBus / Economy | Verifies conveyor flow vs shipments and surfaces jam pressure. |
| `conveyor_jam_active` | StatBus / Economy | Flags sustained queue overflow so UI and alerts stay honest. |
| `environment_tick_ms_p95` | StatsProbe | Confirms EnvironmentService stays under the 0.5 ms budget while updating curves. |
| `automation_tick_ms_p95` | StatsProbe | Tracks AutomationService scheduling cost vs the 1.0 ms target. |
| `automation_next_remaining` | StatsProbe | Shows time until the next scheduled automation action. |
| `power_tick_ms_p95` | StatsProbe | Ensures PowerService updates remain beneath the 0.8 ms threshold. |
| `economy_tick_ms_p95` | StatsProbe | Verifies the Economy loop respects the 1.5 ms budget (see `economy_pps_avg` for pacing). |
| `eco_ship_ms_p95` / `_avg` | StatsProbe | Attributes shipment/auto-dump work; alerts when p95 exceeds 7 ms. |
| `eco_in_ms_p95` / `_avg` | StatsProbe | Measures feed/refill polling cost ahead of shipment logic. |
| `eco_apply_ms_p95` / `_avg` | StatsProbe | Tracks multiplier application and bonus stacking. |
| `eco_research_ms_p95` / `_avg` | StatsProbe | Captures research/automation updates triggered by Economy. |
| `eco_statbus_ms_p95` / `_avg` | StatsProbe | Quantifies StatBus writes/reads from the economy tick. |
| `eco_ui_ms_p95` / `_avg` | StatsProbe | Surfaces UI/broadcast signal overhead (storage, burst state, logs). |
| `active_cells_max` | StatsProbe | Surfaces sandbox load spikes (SandboxGrid coverage). |
| `ci_delta_abs_max` | StatsProbe | Flags sudden comfort swings that may indicate instability. |
| `minigame_active` / `minigame_duration` | Replay controller | Ensures mini-game cooldown rules remain isolated from Credits/RP. |
| `sandbox_render_view_mode` | StatsProbe | Tracks active renderer view (`diorama`, `map`, etc.) for guardrail coverage. |
| `economy_rate_avg` / `economy_rate_label_last` | StatsProbe (Economy) | Quantifies steady PPS and the HUD-ready copy for Slot D. |
| `conveyor_backlog_avg` / `conveyor_backlog_label_last` | StatsProbe (Economy) | Shows average queue pressure plus the exact label used for Slot F. |
| `automation_target_last` / `automation_panel_visible_ratio` | StatsProbe (Automation) | Verifies which automation target UI selected and how often the panel is visible. |
| `hud_labels[]` | Replay summary | Array of timestamped HUD samples (`economy_rate`, `conveyor_backlog`, tone) used for DocOps review without screenshots. |

## Replay Workflow
1. Run headless scenario (hands-off + burst).
2. Import CSV into analysis notebook or spreadsheet.
3. Compare against baseline thresholds (see `Performance_Budgets.md`).
4. Record results in QA checklist (`docs/qa/`).

## PX-020 HUD Label Samples
- `hud_labels` mirrors every `[hud]` console print with `{ "time": seconds, "economy_rate": { "value", "label" }, "conveyor_backlog": { "count", "label", "tone" } }`.
- Use `jq '.hud_labels[-1]' replay_<timestamp>.json` to confirm the final label set matches the HUD copy catalog (PX-020.3) and Spot D/F safe-area rules.
- Designers can quote these records directly in release notes or telemetry dashboards without rerunning Godot.

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
- `service`, `tick_ms`, `pps`, `ci`, `active_cells`, `power_ratio`, `ci_delta`, `storage`, `feed_fraction`, `conveyor_rate`, `conveyor_queue`, `economy_rate`, `economy_rate_label`, `conveyor_backlog`, `conveyor_backlog_label`, `automation_target`, `automation_target_label`, `automation_panel_visible`, `power_state`, `power_warning_level`, `power_warning_label`, `power_warning_count`, `power_warning_duration`, `power_warning_min_ratio`, `auto_active`, `global_enabled`, `next_remaining`, `minigame_active`, `minigame_duration` sampled at 10 Hz (fields populate per service; Economy owns the rate/backlog columns and Automation owns the automation columns).
- Use `python3 tools/gen_dashboard.py --diff <baseline.json> <candidate.json>` to compare replay summaries (new metrics and alert deltas print to stdout).
- Offline catch-up emits a single `service=offline` row per session with `elapsed`, `applied`, `grant`, and `passive_multiplier` columns to document capped awards.
- Renderer stream adds 1 Hz aggregates: `sandbox_render_ms_avg`, `sandbox_render_ms_p95`, `sandbox_render_fallback_ratio`, `belt_anim_ms_avg`, `belt_anim_ms_p95`, `sandbox_render_view_mode`, plus the economy sub-phase metrics (`eco_in_ms_p95`, `eco_apply_ms_p95`, `eco_ship_ms_p95`, `eco_research_ms_p95`, `eco_statbus_ms_p95`, `eco_ui_ms_p95`).
- Alerts emitted through `stats_probe_alert(metric, value, threshold)` and copied into replay JSON under `alerts`.
- CSV naming convention: `logs/perf/tick_<timestamp>.csv`; JSON graph exported to `/reports/nightly/<date>.json` with companion PNG trend. JSON summaries now include `sandbox_tick_ms_p95`, `sandbox_render_ms_p95`, `sandbox_render_ms_avg`, `sandbox_render_fallback_ratio`, `sandbox_render_view_mode`, `active_cells_max`, `ci_delta_abs_max`, `economy_rate_avg`, `conveyor_backlog_avg`, `automation_target_last`, `automation_panel_visible_ratio`, and the `hud_labels` array for regression tracking.

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
