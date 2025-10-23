# Balance Playbook

> Targets for early, mid, and prestige loops. Align tuning changes with the comfort-idle pacing in `docs/analysis/IdleGameComparative.md`.

## Early Loop Benchmarks
| Milestone | Target Time | Notes |
| --------- | ----------- | ----- |
| First shipment | 110–130 s | Hands-off idle run. |
| First upgrade (`prod_1`) | Immediately after first shipment (≤150 s) | Price fixed at 50 credits. |
| Second shipment post-upgrade | +60–80 s | Ensure visible improvement.
| Manual burst cadence | 4 s hold / 6 s refill cycles | Maintain relaxed rhythm; no rapid taps required.

## Mid Loop (10–30 min)
- Auto-feeder unlock (Tier 2) around 12–15 min.
- Research unlocks ramp RP intake to 1 RP/min average.
- Comfort Index contributes up to +3% PPS; no single boost beyond +5%.

### Target Table (pending telemetry confirmation)
| Milestone | Hands-off target | With bursts | Notes |
| --------- | ---------------- | ----------- | ----- |
| First shipment | 120–180 s | 60–120 s | RM-011 baseline. |
| First purchase | n/a | 2–3 min | PX-011.2 ensures immediate agency. |
| Wisdom parity | 10–15 min | 10–12 min | RM-015 pacing goal. |
| Double run delta | 20–30 min | 18–25 min | Prestiged run target. |

- Validate via 50 headless runs per build; outliers beyond ±15% trigger a tuning PX.
- TODO: automate telemetry collection via headless replay (see [Architecture Alignment TODO](../architecture/Implementation_TODO.md)).

## Prestige Loop
- Wisdom reset target run length: 25–30 min for double throughput.
- Prestige multiplier (`wisdom_mult`) stacks multiplicatively; ensure diminishing returns beyond level 5.
- Preserve serenity: no sudden difficulty spikes post-prestige.

## Dos & Don’ts
- **Do** keep base PPS modifications in `balance.tsv`; avoid hardcoding.
- **Do** use telemetry replays to confirm timings after adjustments.
- **Don’t** gate early upgrades behind multiple shipments; players should feel immediate agency.
- **Don’t** introduce punitive sinks (negative credits) in early tiers.

## References
- Stat definitions: [StatBus Catalog](../architecture/StatBus_Catalog.md)
- Telemetry workflow: [Telemetry & Replay](../quality/Telemetry_Replay.md)
