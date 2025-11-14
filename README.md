# Project Yolkless Scaffold

Idle game prototype built with Godot 4.x. This scaffold provides:

- Balance-driven systems with hot-reloadable TSV configuration
- Node-based economy/research/save singletons wired through the main scene
- Tooling scripts for running the project, running headless simulations, and building Linux exports

## Requirements

- Linux CLI: run `source .env` and `bash tools/bootstrap_godot.sh` to install **Godot_v4.5.1-stable_linux.x86_64** into `./bin/`; `tools/godot_resolver.sh` uses this path for WSL, native Linux, and CI (lavapipe software Vulkan).
- Windows capture stations (optional): keep `C:\src\godot\Godot_v4.5.1-stable_win64_console.exe` for hardware screenshots and set `GODOT_BIN` manually when needed.

## Project Structure

We are standardising on a split between Godot scene assets under `game/` and feature code/data in top-level folders:

- `src/` — runtime scripts and services (e.g., `src/modules/conveyor`, `src/services/AutomationService.gd`)
- `ui/` — reusable UI scenes/widgets (e.g., `ui/widgets/EnvPanel.tscn`)
- `data/` — authored TSV/JSON curves and configuration outside the Godot import pipeline
- `game/` — existing scenes, autoload singletons, and legacy scripts (migrated over time)

When adding new systems, prefer the `src/`, `ui/`, and `data/` layout and migrate legacy `game/scripts` as part of module-focused work.

## Quickstarts
- [Gameplay loop walkthrough](docs/quickstarts/gameplay_loop_quickstart.md) — ship the first crates and confirm comfort responses.
- [Telemetry replay workflow](docs/quickstarts/telemetry_replay_quickstart.md) — record StatBus metrics and update dashboards.

## Usage

- `./tools/run_dev.sh` launches the playable prototype. Press `R` in-game to hot-reload `data/balance.tsv` after tweaking numbers.
- Core loop preview: hold the Burst button or press `Space`, buy upgrades, promote the farm, prestige to earn research points, and purchase research nodes.
- Naming, icons, and copy follow `docs/theme_map.md` (Egg Credits, Reputation Stars, Innovation Lab, etc.).
- Strings and balance data hot-reload together; editing `strings_egg.tsv` + tapping `R` updates live UI text.
- Set `Config.seed` in the inspector to a non-zero value to enable deterministic RNG for repeatable PPS/burst timing runs.
- Early game now starts at 0/50 credits; Feeding Efficiency (`prod_1`, 50 🥚) unlocks after the first shipment, Feed Silo (`feed_storage`, 90 🥚) is reachable within five minutes, and the new **Ship Now** button lets you cash in crates instantly at a reduced payout.
- CI smoke tests: run `source .env && ./tools/ci_smoke.sh` for a sub-second load check; if the import cache is cold it performs a one-time `--import` warmup first. When a deeper pass is required, use `./tools/check_only.sh`, which resolves the Linux CLI automatically and streams `--check-only` output to `logs/godot-check.log`; give it up to 600 s on fresh workspaces.

## Ship cycle (WSL quick flow)

```bash
# 1) work on a roadmap item
git switch -c feature/RM-021-environment

# 2) stage & commit (include RM/PX footers)
git add -A && git commit -m "feat(environment): scaffold service layer\n\nRM: RM-021\nPX: PX-021.1"

# 3) publish & open PR (use gh if installed; otherwise push and open the link)
git push -u origin HEAD
# gh pr create --fill --title "RM-021 Environment Layer (PX-021.1)" --body-file docs/roadmap/RM/RM-021.md

# Save the driver text as a PX file
code docs/prompts/PX-021.1.md   # paste canvas text
```

## Art Placeholders

- All current visuals are procedural or simple SVG stand-ins documented in `docs/ART_POLICY.md`. Asset keys map through `assets/AssetMap.json`; drop a final file into `assets/final/`, update the JSON, and Godot will load it without code changes.

## Logging & Strings

- Logging is enabled by default and writes to `user://logs/yolkless.log`, rotating at ~1 MB with three historical segments (`yolkless.log.1`…).
- The autoload `YolkLogger` buffers entries and flushes every 0.5 s; set `Config.logging_enabled=false` or `logging_force_disable=true` to stop emission safely.
- Press `F3` to open the diagnostics overlay for live PPS, research multipliers, log status/size, and the latest tail lines.
- Edit `game/data/strings_egg.tsv` to tweak player-facing copy. Press `R` in-game to hot-reload both balance numbers and these strings.
- Each session begins with a single header containing the Godot build, timestamp, and active seed; tail exports redact URLs, emails, and tokens automatically.

## UI Enhancements

- Capacity bar tracks Egg Credits versus storage and hot-reloads with balance tweaks (`R`).
- Feed button now shows a live Feed Supply meter that drains while held and refills when idle.
- The Feed FX now live entirely inside the UI prototype’s `FeedEffectLayer` (a clipped Control anchored to the Feed buttons) so bursts never bleed across the HUD.
- Feed FX inherit the UI layout transforms directly, so no extra background CanvasLayers or fullscreen viewports are needed to keep visuals aligned.
- The prototype exposes the same feed data everywhere; pressing `R` refreshes both numbers and copy.
- All player-facing strings are driven via `game/data/strings_egg.tsv`; pressing `R` refreshes both numbers and copy.
- The top stats row now surfaces conveyor throughput (`items/sec` and queue) straight from the ConveyorManager.
- Storage panel includes a **Ship Now** button (75 % payout) plus a tooltip that explains when to launch shipments manually.
- Press `F3` to toggle the debug overlay with live PPS, capacity, burst state, tier, research multipliers, hashes, and log context.

## Hold-to-Feed Meter

- Holding the Feed button (or `feed_hold` action) drains a dedicated Feed Supply bar; releasing stops feeding instantly.
- The bar refills automatically when idle, and three feed upgrades—storage, refill, efficiency—expand capacity, speed, and output.
- Meter colours shift from green → amber → red as reserves drop, with an optional High Contrast mode in Settings.

## Environment Simulation

- `src/services/EnvironmentService.gd` runs as an autoload, streaming seasonal curves from `data/environment_profiles.tsv` and emitting feed/power/prestige modifiers.
- Feed drain/refill and autoburst availability respect the live feed modifier; the power modifier flows straight into the economy's base PPS for downstream systems.
- `ui/widgets/EnvPanel.tscn` replaces the legacy pollution overlay with a header summary, preset selector, and expandable detail grid fed by the service.
- Upcoming SandboxService listens to environment factor signals, runs the comfort index simulation, and grants a capped +5 % PPS “Comfort Bonus”.
- Use the preset dropdown in the panel header to cycle seasonal/debug presets without leaving the main scene.
- Legacy `EnvironmentDirector` notes remain archived in `docs/prompts/RM-010.md` for reference; the scripts were removed in favour of the unified `EnvironmentService`.

## Accessibility & Diagnostics

- Open the in-game **Settings** panel to choose 100 % / 110 % / 125 % text scale, enable High Contrast UI, and copy Diagnostics to the clipboard.
- The Visual Effects checkbox now simply enables/disables the button-local Feed FX layer (default ON) for lower-spec or distraction-free play.
- A Reset Save button (with confirmation) clears `user://save.json` and reloads the session instantly.
- Diagnostics export includes build/seed metadata, tier state, upgrade/research snapshots, constants, and the last 200 log lines (sanitised).
- The High Contrast toggle applies WCAG AA compliant themes to the storage bar and feed meter for both dark and light backgrounds.
- Offline resumes surface a single popup per session summarising Egg Credits earned while away.

## Offline Behavior

- Farms simulate at a passive rate while the game is closed, using base PPS scaled by `OFFLINE_EFFICIENCY` and `OFFLINE_PASSIVE_MULT`.
- Feed boosts only apply when you are actively online; unlocking automation grants the `OFFLINE_AUTOMATION_BONUS` multiplier during those passive ticks.
- Offline earnings still respect the cap window (`OFFLINE_CAP_HOURS`) and clamp to the current storage capacity.

## Conveyor Module

- `src/modules/conveyor/` houses the Conveyor Manager, Belt, and Item scripts. Belts chain configurable segments with per-run speed and capacity caps, pushing items forward with easing when queues clear.
- `ConveyorManager` exposes `item_spawned`, `item_delivered`, and `throughput_updated` signals while logging smoothed items/sec plus queue depth via `YolkLogger`.
- `scenes/demo_conveyor.tscn` includes a timer-driven spawner and HUD label so designers can watch flow, jams, and delivery cadence without wiring the full farm.
- `game/scenes/modules/conveyor/FactoryConveyor.tscn` is instanced in the main scene so belts animate above the farm, spawning tokens at the live PPS rate for quick readability.
- Full usage notes live in `docs/modules/conveyor.md`; clone the segment template there to embed belts in future factory stages.

## Scripts

- `tools/run_dev.sh` — launch the game (set `NO_WINDOW=1` to use headless mode); resolves the Linux CLI automatically.
- `tools/ci_smoke.sh` — warm imports if needed, then run the fast CI smoke script with lavapipe defaults.
- `tools/bootstrap_godot.sh` — downloads/verifies the 4.5.1 Linux CLI tarball into `./bin/`.
- `tools/check_only.sh` — verbose `--check-only` wrapper that tees logs to `logs/godot-check.log`.
- `tools/check_only_ci.sh` — CI-friendly wrapper that emits ✅/❌ around `tools/check_only.sh`.
- `tools/headless_tick.sh <seconds>` — runs the replay harness (`res://tools/replay_headless.gd`) in headless mode and writes telemetry to `logs/telemetry/`.
- `tools/ui_viewport_matrix.sh` — capture UI across S/M/L viewports (pass `--capture` to emit PNGs via `$GODOT_BIN`)
- `tools/ui_baseline.sh` — refresh baseline PNGs before committing visual changes
- `tools/sync_ui_screenshots.sh` — copy captured PNGs from Godot’s user directory into `dev/screenshots/ui_current/`
- `tools/export_palette.gd` — generate palette PNG + JSON from `data/materials.tsv` to keep UI colors in sync
- `tools/build_linux.sh` — export a Linux build via `$GODOT_BIN` (requires configured export preset)
- `tools/export_strings.gd` — build `i18n/strings.pot` from `game/data/strings_egg.tsv` for localization partners
- `tools/localization_export_check.sh` — CI helper that regenerates the POT and fails when `i18n/strings.pot` is stale
- `tools/pseudo_loc_smoke.sh` — runs UILint + viewport captures with `PSEUDO_LOC=1` to stress HUD layouts

Make scripts executable: `chmod +x tools/*.sh`.

## Balance Data

- `data/balance.tsv` — master table defining constants, upgrades, factory tiers, automation rules, research nodes, and prestige math. Press `R` during a session to reload.
