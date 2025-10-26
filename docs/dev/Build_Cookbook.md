# Build & Run Cookbook

> Copy-paste friendly runbook for local development, CI mirrors, and UI validation.

Supported platforms: **WSL/Ubuntu**, **desktop Linux**, and **Windows** (via PowerShell/WSL). macOS is unofficial—use the same commands with the macOS Godot binary.

## Prerequisites
- The repo now ships with a **dual-path Godot setup**:
  - `tools/godot_resolver.sh` auto-selects the Linux CLI (`./bin/Godot_v4.5.1-stable_linux.x86_64`) for WSL, native Linux, and CI.
  - Designers on Windows may keep the renderer-enabled console build at `C:\src\godot\Godot_v4.5.1-stable_win64_console.exe` for GPU captures (set `GODOT_BIN` manually when using it).
- `tools/bootstrap_godot.sh` downloads and unpacks the Linux tarball automatically; no manual install required for WSL/CI.
- `.env` exports `GODOT_BIN=./bin/Godot_v4.5.1-stable_linux.x86_64` and `VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.x86_64.json`; `source .env` once per shell to pull these defaults.
- Install dependencies listed in `CONTRIBUTING.md` (Python, git-lfs, etc.).
- **Do not** rely on Snap packages for CI; use the bundled tarball via the resolver.

### Renderer Setup (WSL)
Lavapipe provides software Vulkan for UI captures:

```bash
sudo apt-get update
sudo apt-get install -y mesa-vulkan-drivers vulkan-tools libvulkan1 curl unzip
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/lvp_icd.x86_64.json
```

For persistent shells add the `VK_ICD_FILENAMES` export to your profile or reuse the value from `.env`.

## Common Commands
```bash
# Load shared env once per shell
source .env

# Headless sanity (warnings as errors)
./tools/check_only.sh

# Launch editor / project (resolver determines the right binary)
$(bash tools/godot_resolver.sh) --path . --editor
$(bash tools/godot_resolver.sh) --headless --path . --quit

# CI wrapper (prints ✅/❌ summary)
./tools/check_only_ci.sh
```

## UI Harness
Baseline capture + compare for the PX-010 UI program.
```bash
# Capture/update baseline PNGs (writes dev/screenshots/ui_baseline/)
./tools/ui_baseline.sh

# Sweep S/M/L viewports and capture screenshots
# Uses Vulkan (lavapipe) inside WSL to render into the Godot user:// workspace
./tools/ui_viewport_matrix.sh

# Sync captured PNGs into dev/screenshots/ui_current/
source .env && ./tools/sync_ui_screenshots.sh

# Compare current captures vs baseline; fails on any pixel diff (threshold TBD)
./tools/ui_compare.sh dev/screenshots/ui_baseline dev/screenshots/ui_current
```

## UILint
Runtime lint runs automatically in dev builds; use the headless helper for scenes.
```bash
# In-game dev build prints UILint summary in console.

# One-off lint for a scene
$(bash tools/godot_resolver.sh) --headless --script res://tools/uilint_scene.gd res://scenes/ui_smoke/MainHUD.tscn
```

## Replay & Telemetry
Headless performance/telemetry capture (see [Telemetry & Replay](../quality/Telemetry_Replay.md)).
```bash
# Five-minute replay with seed 42
$(bash tools/godot_resolver.sh) --headless --path . --script res://tools/replay_headless.gd --duration=300 --seed=42
# Outputs:
#   logs/telemetry/replay_YYYYMMDD_HHMM.json
#   logs/perf/tick_<timestamp>.csv
#   reports/nightly/<date>/*.png (if enabled)
```
- Review summary JSON for `sandbox_tick_ms_p95`, `sandbox_render_ms_p95`, `ci_delta_abs_max`, `sandbox_uploads_per_sec`.
- Compare against [Performance Budgets](../quality/Performance_Budgets.md).

## Smoke Flow (local PR checklist)
1. `source .env && ./tools/check_only_ci.sh` → ensure ✅ output.
2. `./tools/ui_viewport_matrix.sh` then `./tools/ui_compare.sh` → expect zero diffs (or review intentional deltas).
3. `$(bash tools/godot_resolver.sh) --headless --script res://tools/replay_headless.gd --duration=300 --seed=42` → inspect JSON/CSV p95 metrics.
4. Optional: run `./tools/ui_baseline.sh` to refresh baseline after approved UI changes (commit PNG updates).

## Troubleshooting
- **“command not found: $GODOT_BIN”** — run `bash tools/godot_resolver.sh`; if it fails, rerun `tools/bootstrap_godot.sh` to reinstall the tarball.
- **Permission errors writing screenshots** — verify `dev/screenshots/` exists and is writable; create with `mkdir -p`.
- **Snap/AppArmor blocks** — remove Snap installs; use the tarball binary.
- **Headless/Vulkan errors** — confirm `VK_ICD_FILENAMES` points to lavapipe (`/usr/share/vulkan/icd.d/lvp_icd.x86_64.json`) and that `mesa-vulkan-drivers` is installed.
- **Visual regression diffs >1%** — update baseline only after designer approval; store new PNGs in git.
- **UILint violations** — run the scene lint command with `GODOT_BIN` set; fix overflow, missing size flags, or unlabeled buttons per [UI Principles](../ux/UI_Principles.md).

## References
- Contribution flow: [`CONTRIBUTING.md`](../../CONTRIBUTING.md)
- UI tokens & principles: [UI Principles](../ux/UI_Principles.md)
- Telemetry workflow: [Telemetry & Replay](../quality/Telemetry_Replay.md)
- Performance targets: [Performance Budgets](../quality/Performance_Budgets.md)
- Module briefs: [Sandbox Renderer](../modules/sandbox.md), [UI Atoms](../modules/ui_atoms.md), [Conveyor](../modules/conveyor.md)
