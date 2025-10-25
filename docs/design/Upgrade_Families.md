# Upgrade Families

> See [Glossary](../Glossary.md) for terminology.

> Layered upgrade groups that deliver clear emotional beats across shop, research, and prestige loops.

Each family intentionally mirrors comfort-idle inspirations (Egg Inc.’s fleets, research labs, and silo upgrades) while grounding the fantasy in Project Yolkless’ serene farm. Use these families when authoring roadmap specs, PX briefs, or TSV data; every upgrade should belong to exactly one family.

| Family | Stat | Tier Names | Emotion Arc | Unlock Channel |
| --- | --- | --- | --- | --- |
| Feed Optimization | `feed_rate`, `feed_capacity` | Hand Mix → Auto Mixer → Feed Synth → Nutrient Printer | Curiosity → Mastery | Shop → Research |
| Shipment Tech | `shipment_yield`, `shipment_speed` | Crate → Drone → Freighter → Hyperloop | Anticipation → Awe | Shop |
| Coop Automation | `tick_rate`, `auto_ready` | Hand Feeder → Auto Feeder → Smart Coop → Self‑aware Roost | Agency → Serenity | Research / Wisdom |
| Power Efficiency | `power_ratio`, `power_reserve` | Candle → Solar → Fusion → Zero‑Point Grid | Progress → Control | Research |
| Comfort Tuning | `ci_cap`, `ci_gain` | Windchimes → Zen Garden → Orb Projector → Dream Synth | Calm → Harmony | Research / Prestige |

## Design Notes

- **Stacking Rules:** Early tiers should feel immediately useful (≤2 min feedback). Later tiers compound: e.g., `Nutrient Printer` raises burst length and unlocks research synergies.
- **Sensory Feedback:** Tie each tier to a visual or audio flourish (shipment hyperloop animation, Dream Synth ambient hum). Add these hooks to UI copy via `Narrative_Hooks.md`.
- **Economy Hooks:** Shipment Tech tiers scale crate quality (see Balance Playbook “Shipment Grades”), while Power Efficiency prevents automation penalties in RM‑018.
- **Prestige Interaction:** Wisdom multipliers accelerate how fast players re-unlock these tiers; Self-aware Roost assumes prestige level ≥2.

## Visual Progression

| Family | Tier | Color Palette | Icon Style | Sound Cue | Feel |
| --- | --- | --- | --- | --- | --- |
| Feed Optimization | 1 | Warm browns, soft cream accents | Rustic hand tools | Gentle clank | Handmade |
| Feed Optimization | 2 | Burnished copper + brass | Mechanical mixers | Rhythmic whirr | Purposeful |
| Feed Optimization | 3 | Cool brushed steel | Lab instruments | Low hum | Precise |
| Feed Optimization | 4 | Iridescent teal | Futuristic nozzle | Harmonised chime | Effortless |
| Shipment Tech | 1 | Cardboard neutrals | Simple crate glyph | Soft thunk | Local |
| Shipment Tech | 2 | Sky blue + white | Drone silhouette | Bright ping | Aerial |
| Shipment Tech | 3 | Amber + chrome | Freight container motif | Distant horn | Industrial |
| Shipment Tech | 4 | Neon magenta streaks | Hyperloop rail | Doppler sweep | Sci-fi |
| Coop Automation | 1 | Harvest orange | Hand crank | Wooden clatter | Familiar |
| Coop Automation | 2 | Steel grey | Servo arm | Soft servo click | Assured |
| Coop Automation | 3 | Midnight blue | Sensor array | Pulsed synth | Mindful |
| Coop Automation | 4 | Luminous violet | Abstract waveform | Whispered chorus | Sentient |
| Power Efficiency | 1 | Candlelight amber | Wax icon | Crackle | Cozy |
| Power Efficiency | 2 | Sunlit gold | Solar panel grid | Gentle shimmer | Sustainable |
| Power Efficiency | 3 | Sapphire + white | Containment ring | Resonant chord | Controlled |
| Power Efficiency | 4 | Pale cyan glow | Zero-point lattice | Soft air hiss | Weightless |
| Comfort Tuning | 1 | Forest green | Wind chime | Breeze rustle | Natural |
| Comfort Tuning | 2 | Sage + sand | Zen stone | Water ripple | Restorative |
| Comfort Tuning | 3 | Lavender haze | Orb icon | Bell drone | Dreamlike |
| Comfort Tuning | 4 | Ether blue | Harmonic wave | Choir swell | Transcendent |

## Cross References

- Data source: `/docs/data/upgrade_families.tsv`
- Research synergies: `/docs/design/Research_Tree.md`
- Prestige pacing: `/docs/design/Wisdom_Multipliers.md`
- Flavor copy: `/docs/design/Narrative_Hooks.md`
- UI integration: [UI Atoms module](../modules/ui_atoms.md)
- Stat routing: [StatBus Catalog](../architecture/StatBus_Catalog.md)
