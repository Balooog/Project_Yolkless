# Gameplay Loop Quickstart

## Goal
Get a local build running, ship the first crates, and observe comfort responses within 10 minutes.

## Prerequisites
- Linux or WSL shell with access to `bash` and `wget`.
- Godot binary bootstrapped via `source .env && bash tools/bootstrap_godot.sh`.

## Steps
1. `source .env` to load `GODOT_BIN` and project paths.
2. Launch the prototype: `./tools/run_dev.sh`.
3. In-game:
   - Hold `Space` or click **Burst Feed** to build Egg Credits.
   - Ship a crate, unlock **Feeding Efficiency**, then purchase **Feed Silo** within five minutes.
   - Use **Ship Now** for quick payouts and watch the Comfort Index react.
4. Press `F3` to open the debug overlay; confirm PPS and Comfort metrics update every 10 Hz tick.
5. Edit `data/balance.tsv` (e.g., tweak `prod_1` cost), press `R` in the running client, and confirm hot-reload without restarting.

## Verification
- Logs appear under `logs/yolkless.log` with the current seed.
- Comfort Index stays above 85 % after the first automation unlock; otherwise capture details in `docs/roadmap/ROADMAP_TASKS.md`.
