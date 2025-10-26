# Economy Early Loop Checks (PX-011.1)

Summary of early-game flow with the PX-011.1 tuning. All simulations use `Config.seed = 12345`, base passive PPS 0.40, manual burst ×6, feed tank 100 (25/s drain, 16/s refill), storage capacity 50, and auto-dump enabled.
Compare each revision against the pacing targets described in `docs/analysis/IdleGameComparative.md` to ensure the loop stays within comfort-idle bounds.

## Scenario timings (300 s window)

| Strategy            | First Dump (s) | Dumps in 300 s | Wallet @ 300 s | Avg PPS |
|---------------------|----------------|----------------|----------------|---------|
| Idle (no feed)      | 122.6          | 2              | 100            | 0.41    |
| Pulse 2s / 12s      | 62.4           | 4              | 200            | 0.75    |
| Pulse 1s / 8s       | 73.0           | 3              | 150            | 0.67    |
| Aggressive hold \*  | 38.4           | 7              | 350            | 1.17    |

\*Assumes perfect re-triggering the moment the feed tank refills. Real play requires re-pressing after the tank empties, so QA focuses on the pulse cadences, which keep first-cap within ~60–75 s and the wallet under 250 credits after five minutes.

## Reproducing

1. Set `Config.seed` to `12345` (Inspector or via the Config autoload).
2. Run `./tools/headless_tick.sh 300` to launch the headless replay harness (`$GODOT_BIN --headless res://tools/replay_headless.gd`). The script uses the seeded run (`--seed` default 12345) so the numbers above should reproduce within rounding error.
3. To sanity-check shop gating, run `source .env && $GODOT_BIN --headless --path . --script res://dev/inspect_shop.gd`. With the updated `balance.tsv`, `prod_1` unlocks at 50 credits while `cap_1` stays locked until 140, matching PX-011.2 targets.
4. Tail `%APPDATA%\Godot\app_userdata\Project Yolkless\logs\yolkless.log` (or the WSL mirror under `~/.local/share/godot/app_userdata/Project\ Yolkless/logs/yolkless.log`) while running the probe to confirm each auto shipment produces paired entries: `Storage full ...` followed by `Auto shipment processed ...`.
5. Inspect `logs/yolkless.log` for `ECON_PROBE` entries; each scenario logs shipment timestamps plus a summary (wallet, storage, average PPS).
6. Runtime sessions now emit an `ECONOMY snapshot` log roughly every 20 s with live `pps`, storage, wallet, and environment modifiers, so you can compare live play against the headless probe output.
7. Test the **Ship Now** button once storage passes 50 %; confirm the manual shipment log shows a 25 % reduction (payout = stored × 0.75) and the tooltip communicates the efficiency.

Manual check in-editor: start a new session, idle to the first shipment (~125 s), then play a 2s-on / 10s-off cadence to confirm the HUD pulse, storage percent readout, and overlay seed line.
