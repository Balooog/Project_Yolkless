# Balance Playbook

> Terminology reference: [Glossary](../Glossary.md)

> Targets for early, mid, and prestige loops. Align tuning changes with the comfort-idle pacing in `docs/analysis/IdleGameComparative.md`.

## Early Loop Benchmarks
| Milestone | Target Time | Notes |
| --------- | ----------- | ----- |
| First shipment | 110–130 s | Hands-off idle run. |
| First upgrade (`prod_1`) | Immediately after first shipment (≤150 s) | Price fixed at 50 credits. |
| Second shipment post-upgrade | +60–80 s | Ensure visible improvement.
| Manual burst cadence | 4 s hold / 6 s refill cycles | Maintain relaxed rhythm; no rapid taps required.

## Shipment Grades

| Grade | Unlock | Reward Mult | Target Time (min) | Flavor |
| --- | --- | --- | --- | --- |
| Basic Crate | Default | ×1 | 1–2 | “The starter box.” |
| Contract Crate | Storage L2 | ×2 | 3–5 | “Local grocers notice your efficiency.” |
| Export Crate | Research Tier 1 | ×4 | 6–8 | “Trucks queue at dawn.” |
| Stellar Shipment | Wisdom Level 3 | ×8 | 10+ | “Your eggs reach orbit.” |

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

## Reward Channel Matrix

| Reward | Earned From | Feeds Into | Emotion |
| --- | --- | --- | --- |
| Credits | Shipments (grade multipliers) | Shop upgrades | Progress |
| Reputation | Shipment quality milestones | Research unlock thresholds | Pride |
| Comfort | Sandbox stability & comfort tuning upgrades | PPS bonus (`ci_bonus`) | Serenity |
| Wisdom | Prestige resets | Faster runs & narrative rewards | Renewal |
| Insight *(mini-game placeholder)* | Mini-game sessions (RM-0XX) | Temporary PPS bonus (+2–3 % for 2–3 min, ≥10 min cooldown) | Flow |

- Mini-game rewards stay on their own track (Insight/Reputation) and never inject Credits/RP directly; PPS boosts are additive with CI and capped by the cooldown.
- When mini-games trigger, throttle Sandbox visual playback (Conveyor + Diorama) to ¼ speed while keeping the CA tick constant to preserve deterministic economy results.

## Scaling Curves & Example Formulas

| Metric | Formula | Notes |
| ------- | ------- | ----- |
| Upgrade Cost | `base_cost * (1.15 ^ level)` | Applies to shop tiers 1–3; clamp level ≥ 0. |
| Research Cost | `base_cost * (1.12 ^ tier)` | Tier corresponds to column in `research.tsv`; gated by shipment milestones. |
| PPS Growth | `base_pps * (1 + 0.10 * research_tier)` | Target overall +50 % PPS per research tier (caps at Tier 5). |
| Wisdom Compression | `run_time * (0.70 ^ wisdom_level)` | Expected parity ≈10 min by second run (Wisdom Level 1). |

### Target PPS per Milestone

| Playtime Window | Target PPS (idle) | Target PPS (with bursts) | Notes |
| --------------- | ----------------- | ------------------------ | ----- |
| 0–5 min | 0.6–0.9 | 0.9–1.2 | First shipment, prod_1 purchased. |
| 5–10 min | 1.0–1.4 | 1.4–1.8 | Contract Crate unlocked; Store tab highlights upgrades. |
| 10–15 min | 1.5–2.2 | 2.2–2.8 | Auto-feeder online; Comfort bonus steady ~+3 %. |

## References
- Stat definitions: [StatBus Catalog](../architecture/StatBus_Catalog.md)
- Telemetry workflow: [Telemetry & Replay](../quality/Telemetry_Replay.md)
