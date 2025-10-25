# Build & Run Cookbook

> Copy-paste friendly runbook for local development, CI mirrors, and UI validation.

Supported platforms: **WSL/Ubuntu**, **desktop Linux**, and **Windows** (via PowerShell/WSL). macOS is unofficial—use the same commands with the macOS Godot binary.

## Prerequisites
- Download the Godot 4.2.x CLI binary (tarball/zip). Recommended layout:
  ```
  bin/
    Godot_v4.2.2-stable_linux.x86_64
  ```
- Export `GODOT_BIN` when running scripts:
  ```bash
  export GODOT_BIN=./bin/Godot_v4.2.2-stable_linux.x86_64
  ```
- **Do not** rely on Snap packages for CI; they lack required capabilities for headless capture.
- Install dependencies listed in `CONTRIBUTING.md` (Python, git-lfs, etc.).

## Common Commands
```bash
# Headless sanity (warnings as errors)
GODOT_BIN=./bin/Godot_v4.2.2-stable_linux.x86_64 ./tools/check_only.sh

# Launch editor / project
$GODOT_BIN --path . --editor
$GODOT_BIN --path . --headless --quit

# CI wrapper (prints ✅/❌ summary)
GODOT_BIN=./bin/Godot_v4.2.2-stable_linux.x86_64 ./tools/check_only_ci.sh
```

## UI Harness
Baseline capture + compare for the PX-010 UI program.
```bash
# Capture/update baseline PNGs (writes dev/screenshots/ui_baseline/)
./tools/ui_baseline.sh

# Sweep S/M/L viewports and capture screenshots
./tools/ui_viewport_matrix.sh

# Compare current captures vs baseline; fails on any pixel diff (threshold TBD)
./tools/ui_compare.sh dev/screenshots/ui_baseline dev/screenshots/ui_current
```

## UILint
Runtime lint runs automatically in dev builds; use the headless helper for scenes.
```bash
# In-game dev build prints UILint summary in console.

# One-off lint for a scene
$GODOT_BIN --headless --script res://tools/uilint_scene.gd res://scenes/ui_smoke/MainHUD.tscn
```

## Replay & Telemetry
Headless performance/telemetry capture (see [Telemetry & Replay](../quality/Telemetry_Replay.md)).
```bash
# Five-minute replay with seed 42
$GODOT_BIN --headless --path . --script res://tools/replay_headless.gd --duration=300 --seed=42
# Outputs:
#   logs/telemetry/replay_YYYYMMDD_HHMM.json
#   logs/perf/tick_<timestamp>.csv
#   reports/nightly/<date>/*.png (if enabled)
```
- Review summary JSON for `sandbox_tick_ms_p95`, `sandbox_render_ms_p95`, `ci_delta_abs_max`, `sandbox_uploads_per_sec`.
- Compare against [Performance Budgets](../quality/Performance_Budgets.md).

## Smoke Flow (local PR checklist)
1. `GODOT_BIN=... ./tools/check_only_ci.sh` → ensure ✅ output.
2. `./tools/ui_viewport_matrix.sh` then `./tools/ui_compare.sh` → expect zero diffs (or review intentional deltas).
3. `$GODOT_BIN --headless --script res://tools/replay_headless.gd --duration=300 --seed=42` → inspect JSON/CSV p95 metrics.
4. Optional: run `./tools/ui_baseline.sh` to refresh baseline after approved UI changes (commit PNG updates).

## Troubleshooting
- **“command not found: $GODOT_BIN”** — ensure the env var points to an executable; check `chmod +x`.
- **Permission errors writing screenshots** — verify `dev/screenshots/` exists and is writable; create with `mkdir -p`.
- **Snap/AppArmor blocks** — remove Snap installs; use the tarball binary.
- **Headless display errors** — pass `--headless` and `--render-thread 1` if necessary; ensure `libgbm` is installed on WSL.
- **Visual regression diffs >1%** — update baseline only after designer approval; store new PNGs in git.
- **UILint violations** — run the scene lint command with `GODOT_BIN` set; fix overflow, missing size flags, or unlabeled buttons per [UI Principles](../ux/UI_Principles.md).

## References
- Contribution flow: [`CONTRIBUTING.md`](../../CONTRIBUTING.md)
- UI tokens & principles: [UI Principles](../ux/UI_Principles.md)
- Telemetry workflow: [Telemetry & Replay](../quality/Telemetry_Replay.md)
- Performance targets: [Performance Budgets](../quality/Performance_Budgets.md)
- Module briefs: [Sandbox Renderer](../modules/sandbox.md), [UI Atoms](../modules/ui_atoms.md), [Conveyor](../modules/conveyor.md)
