\## Theme: “Yolkless — From Coop to Synthetic Perfection”



A grounded idle game about modernizing egg production: from backyard coops to fully automated synthetic-protein labs.

Players manage efficiency, ethics, and innovation to reach the ultimate goal—creating the perfect \*yolkless egg.\*

Comfort-idle tone, pacing, and visual cues should remain consistent with `docs/analysis/IdleGameComparative.md`.



---



\### 1. Currencies



| Key                 | Display Name         | Icon | Description                                                                                  |

| ------------------- | -------------------- | ---- | -------------------------------------------------------------------------------------------- |

| `soft\_currency`     | \*\*Egg Credits\*\*      | 🥚   | Primary income; earned from selling eggs.                                                    |

| `prestige\_currency` | \*\*Reputation Stars\*\* | 🌟   | Represents public legacy and technological reputation; permanent multipliers on future runs. |



---



\### 2. Production \& Upgrades



| Key         | Display Name                  | Description                                          |

| ----------- | ----------------------------- | ---------------------------------------------------- |

| `prod\_\*`    | \*\*Feeding Efficiency Lv X\*\*   | Increases base production per hen.                   |

| `cap\_\*`     | \*\*Coop Capacity Lv X\*\*        | Expands maximum storage before overflow.             |

| `auto\_\*`    | \*\*Auto-Feeder System Lv X\*\*   | Automates bursts using timed feeding cycles.         |

| `hygiene\_\*` | \*\*Sanitation Protocols Lv X\*\* | Reduces stress penalties at higher industrial tiers. |

| `quality\_\*` | \*\*Quality Control Lv X\*\*      | Boosts egg sale value (mid-game).                    |



---



\### 3. Factory Tiers (Progression Path)



| Tier ID | Stage                 | Description                                        | Unlocks                                                  |

| ------- | --------------------- | -------------------------------------------------- | -------------------------------------------------------- |

| 1       | \*\*Backyard Coop\*\*     | Family-run hobby setup.                            | Manual bursts only.                                      |

| 2       | \*\*Community Farm\*\*    | Local cooperative.                                 | First automation upgrade.                                |

| 3       | \*\*Regional Farm\*\*     | Commercial operation.                              | Vehicle speed, branding.                                 |

| 4       | \*\*Factory Farm\*\*      | Mass-scale production; introduces welfare debuffs. | “Ethical Dilemma” node in research.                      |

| 5 a     | \*\*Organic Sanctuary\*\* | Humane, eco-friendly branch.                       | Green research, improved conversion.                     |

| 5 b     | \*\*Hyper Factory\*\*     | Industrial efficiency branch.                      | Overclocked automation, pollution risk.                  |

| 6       | \*\*Synthetic Egg Lab\*\* | The Yolkless frontier—lab-grown protein eggs.      | Unlocks \*Synthetic Research\* tree and new prestige tier. |



---



\### 4. Research Branches



| Branch Key   | Branch Title                   | Example Nodes                                            |

| ------------ | ------------------------------ | -------------------------------------------------------- |

| `production` | \*\*Husbandry Science\*\*          | Feed Conversion R\&D, Selective Breeding Optimizers       |

| `capacity`   | \*\*Infrastructure Engineering\*\* | Modular Coops, Climate Control                           |

| `automation` | \*\*Smart Farming Tech\*\*         | Drone Feeders, Predictive Incubators                     |

| `ethics`     | \*\*Animal Welfare \& Branding\*\*  | Stress Monitoring, Eco-Label Marketing                   |

| `synthetic`  | \*\*Biofabrication Research\*\*    | Synthetic Albumen, Protein Scaffolding, Yolkless Culture |



---



\### 5. Prestige \& Meta



| Key               | Display Name         | Description                                                            |

| ----------------- | -------------------- | ---------------------------------------------------------------------- |

| `prestige\_screen` | \*\*Legacy Dashboard\*\* | Summarizes production stats, ethics rating, and innovation milestones. |

| `prestige\_points` | \*\*Reputation Stars\*\* | Permanent multiplier affecting base earnings and prestige conversion.  |



---



\### 6. UI Strings / Labels



| Key               | Label                                      |

| ----------------- | ------------------------------------------ |

| `burst\_button`    | \*\*“Feed the Hens! (hold)”\*\*                |

| `capacity\_bar`    | \*\*“Coop Capacity”\*\*                        |

| `tier\_label`      | \*\*“Farm Tier”\*\*                            |

| `research\_tab`    | \*\*“Innovation Lab”\*\*                       |

| `prestige\_button` | \*\*“Rebrand \& Advance to Next Generation”\*\* |



---



\## 7. Late-Game Synthetic Transition



Once players prestige into Tier 6 (\*\*Synthetic Egg Lab\*\*):



| Mechanic               | Change                                                                            |

| ---------------------- | --------------------------------------------------------------------------------- |

| \*\*Currency Name Swap\*\* | `soft\_currency` → “Bio-Credits”; icons shift to ⚗️                                |

| \*\*Research Tree\*\*      | `synthetic` branch activates; older branches remain as legacy tech.               |

| \*\*Visual Tone\*\*        | Warm farm colors gradually fade into sterile lab whites \& pastels.                |

| \*\*Soundscape\*\*         | Adds low synth hums, lab ambience, glass-clink feedback.                          |

| \*\*Meta Hook\*\*          | Enables infinite prestige scaling (“Generation Index”) to sustain long-term play. |



---



\## 8. Behavioral Loop — How It Keeps You Playing



| Loop Layer           | Duration | What You Do                                          | Why It Feels Good                           |

| -------------------- | -------- | ---------------------------------------------------- | ------------------------------------------- |

| \*\*Burst Cycle\*\*      | Seconds  | Hold to burst, see numbers spike.                    | Immediate feedback; tactile clicker fun.    |

| \*\*Upgrade Cycle\*\*    | Minutes  | Buy upgrades, optimize ratios.                       | Feels like smart optimization; short wins.  |

| \*\*Tier Cycle\*\*       | Hours    | Reach next Farm Tier / Egg Type.                     | Visual \& mechanical payoff; new art, music. |

| \*\*Prestige Cycle\*\*   | Days     | Rebrand, spend Reputation on meta upgrades.          | Faster rebuild, visible mastery.            |

| \*\*Innovation Cycle\*\* | Weeks+   | Transition into Synthetic Era; endless tech scaling. | Fresh systems, no hard end.                 |



\### Progression Acceleration Logic



\* Prestige gives +X % global multiplier per Reputation Star.

\* Early meta research (e.g., \*Public Relations\*, \*Startup Efficiency\*) reduces early-tier cost multipliers.

\* This means each new run reaches Synthetic Egg tech sooner — the \*“faster to fun”\* loop that re-hooks returning players.

\* Optional \*\*tasks/trophies\*\* (future layer):



&nbsp; \* “Reach Factory Farm in 10 min”

&nbsp; \* “Maintain 100% Stress Free for 5 min”

&nbsp; \* Reward: +1 temporary multiplier or cosmetic badge.

&nbsp;   These guide efficient play and scratch that optimization itch.



---



\## 9. Implementation Notes for Codex Prompt 2



\* Theme strings live in `game/data/strings\_egg.tsv` (`key display description`).

\* `Config.gd` → `THEME\_EGG` flag loads this mapping.

\* Future alternate themes (e.g., Communal) will mirror this schema in `strings\_commune.tsv`.

\* Balance math unchanged; only names, icons, and colors vary.

\* Tier 6 synthetic content can extend via extra `\[FACTORY\_TIERS]` rows and a new `synthetic` branch in `\[RESEARCH]`.



---



\### ✅ Summary



“Yolkless — Ethical Eggs to Synthetic Future”

combines:



\* \*\*Grounded early realism\*\* (backyard → factory → ethical split)

\* \*\*Optimization satisfaction\*\* (efficiency math, prestige speed-up)

\* \*\*Evergreen late-game\*\* (synthetic tech ladder).



Every restart feels smoother and more efficient, makes dopamine loop—without breaking your coherent theme.



