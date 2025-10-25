# Wisdom Multipliers

> Defines prestige math, pacing, and sensory feedback for the Wisdom system (RM‑015 / PX‑015.1).

## Multiplier Formula

- Base multiplier: `run_multiplier = 1.00 × (1 + 0.10 × wisdom_level)`
- Wisdom level increases by 1 per prestige run when the player meets shipment + research milestones.
- Diminishing returns: after level 10, additional levels grant +0.05 to preserve serenity pacing.

### Example Table

| Wisdom Level | Multiplier | Expected Time to Parity (next run) | Notes |
| --- | --- | --- | --- |
| 0 | ×1.00 | 12 min | Baseline tutorial run. |
| 1 | ×1.10 | 10 min | First prestige should feel noticeably snappier. |
| 3 | ×1.30 | 8 min | Unlocks Stellar Shipment grade. |
| 5 | ×1.50 | 6.5 min | Automation fully online; comfort bonuses stack. |
| 10 | ×2.00 | 5 min | End of first “chapter.” Unlock Space Colony farm. |
| 15 | ×2.25 | 4.5 min | Post-cap gentle slope. |

## Run Compression Curve

| Wisdom Level | Expected Run Duration | Notes |
| --- | --- | --- |
| 0 | 30 min | Tutorial baseline; no compression applied. |
| 1 | 21 min | First prestige should feel 30 % faster; aligns with `0.70 ^ level` target. |
| 2 | 15 min | Comfort bonus + automation combine to halve run length vs baseline. |
| 3 | 11 min | Research Tier 2 unlocked; PPS ×1.3 via scaling formulas. |
| 4 | 9 min | Comfort cap expanded; maintain serenity while progressing faster. |
| 5 | 7 min | Pre-Wisdom-10 plateau; ensure replay remains relaxing, not frantic. |

## Emotional Beats

- **Initiation:** Soft bell + warm color shift when prestige button becomes available; tooltip quotes from `Narrative_Hooks.md`.
- **Activation:** Cinematic pan of shipments leaving the farm; UI dim, then brighten to signify a fresh start.
- **Return:** Upon regaining previous PPS, display toast “Wisdom echoes back—production restored in {time}.”
- **Mastery:** At level milestones (1, 5, 10) unlock ambient tracks or environment presets.

## Interaction With Other Systems

- Speeds up re-acquisition of upgrade families: multiplier applies to base PPS, shipment yield, and research point generation.
- Reduces feed refill wait by applying multiplier to `feed_rate` (capped to maintain relaxing cadence).
- Required input for Research Tier 3 nodes (see `/docs/design/Research_Tree.md`).

## Cross References

- Upgrade families: `/docs/design/Upgrade_Families.md`
- Research pacing: `/docs/design/Research_Tree.md`
- Flavor copy: `/docs/design/Narrative_Hooks.md`
- Performance verification: [Telemetry & Replay](../quality/Telemetry_Replay.md)
