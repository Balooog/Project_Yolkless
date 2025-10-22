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

## Logging

- Runtime logs stream to `user://logs/yolkless.log`; rotation keeps three 1 MB backups (`yolkless.log.1`…`.3`).
- Every session writes a build header line, and emits structured entries such as `INFO [OFFLINE] elapsed=900 applied=28800 eff=0.8 credits=1420`.
- Use `Logger.copy_diagnostics_to_clipboard()` (or the forthcoming Settings action) for a redacted clipboard bundle.
- Crash dumps land in `user://logs/crash_dump.txt` with the latest 200 log lines and stack trace.

## UI Enhancements

- Capacity bar (Storage) and burst cooldown indicator occupy the top HUD, using high-contrast colors that meet WCAG AA targets.
- All player-facing strings are driven via `game/data/strings_egg.tsv`; pressing `R` refreshes both numbers and copy.
- Press `F3` to toggle the debug overlay with live PPS, capacity, burst state, tier, research multipliers, hashes, and log context.

## Accessibility & Diagnostics

- Open the in-game **Settings** panel to choose 100 % / 110 % / 125 % text scale and to copy Diagnostics to the clipboard.
- Diagnostics export includes build/seed metadata, tier state, upgrade/research snapshots, constants, and the last 200 log lines (sanitised).
- Offline resumes surface a single popup per session summarising Egg Credits earned while away.

## Scripts

- `tools/run_dev.sh` — launch the game (set `NO_WINDOW=1` to use headless mode)
- `tools/headless_tick.sh <seconds>` — placeholder helper printed for future CLI sims
- `tools/build_linux.sh` — export a Linux build (requires configured export preset)

Make scripts executable: `chmod +x tools/*.sh`.

## Balance Data

- `game/data/balance.tsv` — master table defining constants, upgrades, factory tiers, automation rules, research nodes, and prestige math. Press `R` during a session to reload.
