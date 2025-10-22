# Project Yolkless Scaffold

Idle game prototype built with Godot 4.x. This scaffold provides:

- Balance-driven systems with hot-reloadable TSV configuration
- Node-based economy/research/save singletons wired through the main scene
- Tooling scripts for running the project, running headless simulations, and building Linux exports

## Requirements

- Godot 4.2+ CLI available as `godot4`

## Usage

- `./tools/run_dev.sh` launches the playable prototype. Press `R` in-game to hot-reload `game/data/balance.tsv` after tweaking numbers.
- Core loop preview: hold the Burst button or press `Space`, buy upgrades, promote the farm, prestige to earn research points, and purchase research nodes.
- Naming, icons, and copy follow `docs/theme_map.md` (Egg Credits, Reputation Stars, Innovation Lab, etc.).
- Strings and balance data hot-reload together; editing `strings_egg.tsv` + tapping `R` updates live UI text.
- Set `Config.seed` in the inspector to a non-zero value to enable deterministic RNG for repeatable PPS/burst timing runs.

## Logging & Strings

- Logging is enabled by default and writes to `user://logs/yolkless.log`, rotating at ~1 MB with three historical segments (`yolkless.log.1`…).
- The autoload `YolkLogger` buffers entries and flushes every 0.5 s; set `Config.logging_enabled=false` or `logging_force_disable=true` to stop emission safely.
- Press `F3` to open the diagnostics overlay for live PPS, research multipliers, log status/size, and the latest tail lines.
- Edit `game/data/strings_egg.tsv` to tweak player-facing copy. Press `R` in-game to hot-reload both balance numbers and these strings.
- Each session begins with a single header containing the Godot build, timestamp, and active seed; tail exports redact URLs, emails, and tokens automatically.

## UI Enhancements

- Capacity bar tracks Egg Credits versus storage and hot-reloads with balance tweaks (`R`).
- Feed button now shows a live Feed Supply meter that drains while held and refills when idle.
- A lightweight VisualDirector autoload drives feed particle visuals that ramp with Feed Supply and PPS; disable them via the Settings → Visual Effects toggle.
- All player-facing strings are driven via `game/data/strings_egg.tsv`; pressing `R` refreshes both numbers and copy.
- Press `F3` to toggle the debug overlay with live PPS, capacity, burst state, tier, research multipliers, hashes, and log context.

## Hold-to-Feed Meter

- Holding the Feed button (or `feed_hold` action) drains a dedicated Feed Supply bar; releasing stops feeding instantly.
- The bar refills automatically when idle, and three feed upgrades—storage, refill, efficiency—expand capacity, speed, and output.
- Meter colours shift from green → amber → red as reserves drop, with an optional High Contrast mode in Settings.

## Environment Simulation

- EnvironmentDirector orchestrates pollution, stress, and reputation curves, updating every few frames and feeding values into the prestige multiplier.
- The Backyard stage reacts in real time: skies desaturate under heavy pollution, chickens relax or stall based on stress, and a reputation icon mirrors public sentiment.
- A Pollution/Stress/Reputation overlay appears above the playfield with colour-coded bars and localised tooltips sourced from the StringsCatalog.
- Future tiers will swap in new environment stages automatically as the factory promotes, building toward a Regional → Industrial → Synthetic Lab progression mapped in `docs/ROADMAP.md`.

## Accessibility & Diagnostics

- Open the in-game **Settings** panel to choose 100 % / 110 % / 125 % text scale, enable High Contrast UI, and copy Diagnostics to the clipboard.
- The new Visual Effects checkbox toggles the Feed Particles module (default ON) for lower-spec or distraction-free play.
- Diagnostics export includes build/seed metadata, tier state, upgrade/research snapshots, constants, and the last 200 log lines (sanitised).
- The High Contrast toggle applies WCAG AA compliant themes to the storage bar and feed meter for both dark and light backgrounds.
- Offline resumes surface a single popup per session summarising Egg Credits earned while away.

## Offline Behavior

- Farms simulate at a passive rate while the game is closed, using base PPS scaled by `OFFLINE_EFFICIENCY` and `OFFLINE_PASSIVE_MULT`.
- Feed boosts only apply when you are actively online; unlocking automation grants the `OFFLINE_AUTOMATION_BONUS` multiplier during those passive ticks.
- Offline earnings still respect the cap window (`OFFLINE_CAP_HOURS`) and clamp to the current storage capacity.

## Scripts

- `tools/run_dev.sh` — launch the game (set `NO_WINDOW=1` to use headless mode)
- `tools/headless_tick.sh <seconds>` — placeholder helper printed for future CLI sims
- `tools/build_linux.sh` — export a Linux build (requires configured export preset)

Make scripts executable: `chmod +x tools/*.sh`.

## Balance Data

- `game/data/balance.tsv` — master table defining constants, upgrades, factory tiers, automation rules, research nodes, and prestige math. Press `R` during a session to reload.
