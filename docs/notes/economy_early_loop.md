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
2. Run `./tools/headless_tick.sh 300` to launch the headless probe (`godot4 --headless res://game/scripts/ci/econ_probe.gd`). The script seeds the run to `12345`, so the numbers above should reproduce within rounding error.
3. To sanity-check shop gating, run `godot4 --headless --path . --script res://dev/inspect_shop.gd`. With the updated `balance.tsv`, `prod_1` unlocks at 50 credits while `cap_1` stays locked until 140, matching PX-011.2 targets.
4. Tail `~/snap/godot4/10/.local/share/godot/app_userdata/Project\ Yolkless/logs/yolkless.log` while running the probe to confirm each auto shipment produces paired entries: `Storage full ...` followed by `Auto shipment processed ...`.
5. Inspect `logs/yolkless.log` for `ECON_PROBE` entries; each scenario logs shipment timestamps plus a summary (wallet, storage, average PPS).

Manual check in-editor: start a new session, idle to the first shipment (~125 s), then play a 2s-on / 10s-off cadence to confirm the HUD pulse, storage percent readout, and overlay seed line.
