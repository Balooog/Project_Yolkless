# Telemetry Replay Quickstart

## Goal
Run a deterministic headless session, collect StatBus metrics, and publish artifacts for review.

## Prerequisites
- Godot binary resolved via `source .env && $(bash tools/godot_resolver.sh) --version`.
- Python 3 available for report inspection (optional but recommended).

## Steps
1. `source .env` to populate `GODOT_BIN`.
2. Execute the replay script (default PX-020 scenario):
   ```bash
   $(bash tools/godot_resolver.sh) --headless --script res://tools/replay_headless.gd --duration=300 --seed=42
   ```
3. Watch the console for periodic `[hud] economy_rate=… | conveyor_backlog=…` and final `[automation] … panel_vis=…` lines.  These confirm Slots D/F and the automation panel stats are flowing before you even inspect files.
4. Inspect telemetry output under `reports/nightly/<timestamp>/`; confirm CSV/JSON files exist with the run ID (copied from `~/.local/share/godot/app_userdata/Project Yolkless/logs/{perf,telemetry}`).
5. (Optional) Use `python3 tools/gen_dashboard.py reports/nightly/<timestamp>` to regenerate the metrics dashboard HTML.
6. Log noteworthy comfort or PPS deviations in `docs/roadmap/RM/RM-Index.md` with a link to the artifact folder.

## PX-020 HUD + Automation Checks

1. **HUD label samples**  
   `summary.json` now exposes a `hud_labels` array with dictionaries of `{ time, economy_rate { value, label }, conveyor_backlog { count, label, tone } }`.  Grab the tail entry to verify the replay captured human-friendly copy:
   ```bash
   jq '.hud_labels[-1]' reports/nightly/<timestamp>/summary.json
   ```
2. **StatsProbe CSV columns**  
   Ensure the newest `tick_*.csv` includes the PX-020 columns appended to the header:
   ```
   ...,eco_statbus_ms,eco_ui_ms,economy_rate,economy_rate_label,conveyor_backlog,conveyor_backlog_label,automation_target,automation_target_label,automation_panel_visible
   ```
   Spot-check a few rows (`tail -n 3 <file>.csv`) to confirm labels and counts are populated (labels default to the last seen HUD strings if the service supplied an empty string).
3. **JSON summary fields**  
   The replay summary inherits StatsProbe aggregates and now reports:
   - `economy_rate_avg`, `economy_rate_label_last`
   - `conveyor_backlog_avg`, `conveyor_backlog_label_last`
   - `automation_target_last`, `automation_panel_visible_ratio`
   - `hud_labels` (see above)

   QA reviewers reference these values instead of running the game locally.  Attach the JSON/CSV pair plus the console snippet with `[hud]` / `[automation]` lines to every PX-020 PR per [PX-020.4 Telemetry Replay](../px/PX-020.4_Telemetry_Replay.md).

## Verification
- `docs/quality/Telemetry_Spec.md` metrics (`comfort.pct_live`, `pps.instant`, etc.) appear in the run output.
- PX-020 metrics (`economy_rate`, `conveyor_backlog`, `automation_target`) appear in both CSV and JSON summary, and `hud_labels` shows at least one entry.
- Any new metrics are added to `docs/architecture/StatBus_Catalog.md` before merging code changes.
