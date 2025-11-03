# Telemetry Replay Quickstart

## Goal
Run a deterministic headless session, collect StatBus metrics, and publish artifacts for review.

## Prerequisites
- Godot binary resolved via `source .env && $(bash tools/godot_resolver.sh) --version`.
- Python 3 available for report inspection (optional but recommended).

## Steps
1. `source .env` to populate `GODOT_BIN`.
2. Execute the replay script:
   ```bash
   $(bash tools/godot_resolver.sh) --headless --script res://tools/replay_headless.gd --duration=300 --seed=42
   ```
3. Inspect telemetry output under `reports/nightly/<timestamp>/`; confirm CSV/JSON files exist with the run ID.
4. (Optional) Use `python3 tools/gen_dashboard.py reports/nightly/<timestamp>` to regenerate the metrics dashboard HTML.
5. Log noteworthy comfort or PPS deviations in `docs/roadmap/RM/RM-Index.md` with a link to the artifact folder.

## Verification
- `docs/quality/Telemetry_Spec.md` metrics (`comfort.pct_live`, `pps.instant`, etc.) appear in the run output.
- Any new metrics are added to `docs/architecture/StatBus_Catalog.md` before merging code changes.
