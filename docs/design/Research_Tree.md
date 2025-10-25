# Research Tree

> Terms defined in [Glossary](../Glossary.md)

> Blueprint for the R&D lab (RM‑012) detailing tiers, synergy nodes, and emotional beats. Aligns with Upgrade Families and Wisdom pacing.

## Tier Overview

| Tier | Unlock Requirement | RP Cost Range | Emotion Goal | Example Unlocks |
| --- | --- | --- | --- | --- |
| Tier 0 – “Blueprints” | Tutorial completion | 5 – 15 | Curiosity | Feed Optimization Hand Mix, Shipment Crate tuning |
| Tier 1 – “Workshop” | 3 Contract Crates shipped | 25 – 60 | Momentum | Auto Mixer feed upgrade, Drone routing |
| Tier 2 – “Lab” | Promote to Community Farm | 90 – 180 | Agency | Smart Coop automation, Solar array |
| Tier 3 – “Think Tank” | Earn 3 Wisdom | 220 – 400 | Mastery | Hyperloop shipment tech, Dream Synth comfort tuning |

## Synergy Nodes

| Node | Prereqs | Bonus | Flavor Hook | Notes |
| --- | --- | --- | --- | --- |
| **Logistics Mesh** | Shipment Tech T1 + Coop Automation T1 | Shipment yield +2 % per automation tier | “Every crate leaves on a whisper.” | Keeps manual shipment button relevant. |
| **Nutrient Recirculator** | Feed Optimization T2 + Power Efficiency T1 | Feed consumption −8 % | “Nothing is wasted; hens breathe calm.” | Softens feed drain to lengthen bursts. |
| **Serenity Loop** | Comfort Tuning T2 + Wisdom ≥ 2 | CI bonus cap +1 % | “Harmony resonates through the roost.” | Ties prestige progression to comfort. |
| **Night Shift Automation** | Coop Automation T3 + Power Efficiency T2 | Auto-burst cooldown −1 s | “The coop learns when to rest.” | Requires power surplus; warns if grid unstable. |

## Node Template

Use this format when expanding the tree:

```markdown
- **Node Name** (`id`): Requirements (RP cost, shipment grade, wisdom level)
  - Bonus: +X to stat (see Upgrade Families)
  - Emotion: “Flavor line” (link to Narrative Hooks)
  - UI: Icon / tooltip suggestion
```

## Pacing Targets

- Players hit Tier 1 within 6–8 minutes when engaging bursts.
- Tier 2 unlocks by run minute 15 once Contract Crates + research synergy aligned.
- Tier 3 requires at least one prestige loop; aim for second run completion ~25 minutes.

## Cross References

- Upgrade families: `/docs/design/Upgrade_Families.md`
- Prestige multipliers: `/docs/design/Wisdom_Multipliers.md`
- Flavor copy: `/docs/design/Narrative_Hooks.md`
- Stats integration: [StatBus Catalog](../architecture/StatBus_Catalog.md)
- QA telemetry: [Telemetry & Replay](../quality/Telemetry_Replay.md)

## Branch Archetypes & Synergies

- **Utility Spine**
  - Example chain: `feed_handmix` → `feed_automixer` → `nutrient_recirculator`.
  - Synergy: Reduces feed drain while unlocking automation efficiency; pair with Power Tier 1 to avoid overload alerts.
- **Economy Core**
  - Example chain: `shipment_crate` → `shipment_drone` → `logistics_mesh`.
  - Synergy: Throughput bonuses stack with Wisdom multipliers; ensure StatBus `pps` telemetry reflects +50 % within 10 min window.
- **Comfort Loop**
  - Example chain: `comfort_chimes` → `comfort_orb` → `serenity_loop`.
  - Synergy: Raises Comfort Index cap and broadens sandbox palette; tie to EnvPanel tooltip to signal serenity gains.
- **Hybrid Nodes**
  - `nutrient_recirculator` (Utility + Comfort) smooths burst cadence by 8 %.
  - `night_shift_automation` (Economy + Utility) shortens autoburst cooldown when power reserve > 0.7.
- Ensure each branch lists dependent upgrade families in `research.tsv` and cross-check with [StatBus Catalog](../architecture/StatBus_Catalog.md) when adding new modifiers.
