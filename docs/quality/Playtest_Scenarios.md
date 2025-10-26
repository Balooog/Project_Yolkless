# Playtest Scenarios

Qualitative checks that ensure the economy feels fun, comprehensible, and emotionally resonant. Run these alongside automated telemetry (RM‑014).

## Moment-to-Moment

- **Ship Now vs Auto-Dump:** Build to 70 % storage, press Ship Now. Does the burst feel rewarding, or like losing progress? Capture quotes.
- **Burst Cadence:** Hold feed for 10 s, release for 10 s. Does the refill pacing feel relaxing or impatient?
- **Comfort Feedback:** Trigger a Comfort Tuning upgrade; note visual/auditory response. Is serenity communicated?

## Mid-Run (5–15 min)

- **First Feed Upgrade:** Can testers afford and understand the first feed upgrade within 5 min? Do they notice longer bursts?
- **Shipment Grade Recognition:** After unlocking Contract Crates, ask players what changed. Do they connect grade → reward → emotion?
- **Automation Toggle:** Switch Auto-Feeder on/off; does manual override feel respected?

## Meta-Run / Prestige

- **Prestige Readiness:** At the moment the prestige button unlocks, do players feel excited or anxious? Record expectation quotes.
- **Return-to-Parity Clock:** Time how long it takes to reach prior PPS. Does the toast message land?
- **Wisdom Fantasy:** After level ups, do new ambient cues feel earned?

## Reporting Notes

- Log qualitative feedback in `logs/playtest_notes/*.md` with timestamp, scenario, player mood, and actionable insight.
- Cross-reference telemetry (snapshot logs) to validate whether feelings map to numbers (e.g., shipment burst duration).
- After each session, run a short telemetry capture to ground observations:
  ```bash
  source .env && $GODOT_BIN --headless --path . --script res://tools/replay_headless.gd --duration=60 --seed=42 --strategy=normal
  ```
  Note the resulting `sandbox_tick_ms_p95`, `ci_delta_abs_max`, and `active_cells_max` (from the JSON summary) and attach highlights to playtest notes. Large `ci_delta` spikes or repeated StatsProbe alerts should be flagged alongside qualitative comments.
