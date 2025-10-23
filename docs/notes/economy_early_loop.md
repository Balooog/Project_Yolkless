# Economy Early Loop Checks (PX-011.1)

Summary of early-game flow with the PX-011.1 tuning. All simulations use `Config.seed = 12345`, base passive PPS 0.40, manual burst ×6, feed tank 100 (25/s drain, 16/s refill), storage capacity 50, and auto-dump enabled.

## Scenario timings (300 s window)

| Strategy            | First Dump (s) | Dumps in 300 s | Wallet @ 300 s | Avg PPS |
|---------------------|----------------|----------------|----------------|---------|
| Idle (no feed)      | 125            | 2              | 100            | 0.40    |
| Pulse 2s / 12s      | 64.7           | 4              | 200            | 0.67    |
| Pulse 1s / 8s       | 74.9           | 3              | 150            | 0.50    |
| Aggressive hold \*  | 38.4           | 7              | 350            | 1.17    |

\*Assumes perfect re-triggering the moment the feed tank refills. Real play requires re-pressing after the tank empties, so QA focuses on the pulse cadences, which keep first-cap within 60–75 s and the wallet under 250 credits after five minutes.

## Reproducing

1. Set `Config.seed` to `12345` (Inspector or via the Config autoload).
2. Run `./tools/headless_tick.sh 300` to launch the headless probe (`godot4 --headless res://game/scripts/ci/econ_probe.gd`).
3. Inspect `logs/yolkless.log` for `ECON_PROBE` entries; each scenario logs dump timestamps plus a summary (wallet, storage, average PPS).

Manual check in-editor: start a new session, idle to the first dump (~125 s), then play a 2s-on / 10s-off cadence to confirm the HUD pulse, storage percent readout, and overlay seed line.
