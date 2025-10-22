# Project Yolkless – Comprehensive Feature Roadmap

*(Version 2025.10 — consolidated from design sessions)*

---

## 🥚 Core Gameplay Loops

| System                                       | Status        | Description / Notes                                                                              |
| -------------------------------------------- | ------------- | ------------------------------------------------------------------------------------------------ |
| **Feed System (PR-006)**                     | ✅ Complete    | Hold-to-feed mechanic with feed bar, drain/refill loop, and capacity/refill/efficiency upgrades. |
| **Offline Passive Rate (PR-007)**            | ⏳ Planned     | Offline production at reduced efficiency (≈25% base PPS). Automation adds a multiplier.          |
| **VisualDirector & Feed Particles (PR-008)** | ⏳ In Progress | Reactive particle effects while feeding; foundation for later modules.                           |
| **Logging + Diagnostics (PR-005)**           | ✅ Active      | YolkLogger with queued writes, Diagnostics overlay, and clipboard export.                        |
| **Environment Simulation (PR-010)**          | ⏳ Prototype   | Dynamic ecosystem reacting to pollution, stress, and reputation. Evolves with production tiers.  |
| **Prestige / Rebrand Loop**                  | ✅ Implemented | Converts Reputation Stars to permanent production multipliers; “Rebrand & Advance” transition.   |

---

## 🌿 Environment Simulation Stages

| Tier                        | Environment                     | Visual Focus                       | Dynamic Factors / Impact                            |
| --------------------------- | ------------------------------- | ---------------------------------- | --------------------------------------------------- |
| **T1 – Backyard Coop**      | Hand-drawn yard with hens       | Warm colors, subtle feed particles | Minimal pollution; rep baseline high.               |
| **T2 – Regional Farm**      | Small barns, local trucks       | Dust trails, mild odor             | Introduces noise & odor penalties.                  |
| **T3 – Commercial Farm**    | Conveyor barns, vehicles        | Conveyor motion, exhaust haze      | Soil/groundwater pollution; stress rises faster.    |
| **T4 – Industrial Factory** | Steel barns, smokestacks        | Smog overlay, desaturation         | Heavy pollution; welfare research mitigates stress. |
| **T5 – Biotech Facility**   | Robotic feeders, cleanrooms     | Cool lighting, sterile glow        | Low pollution; high energy cost.                    |
| **T6 – Synthetic Lab**      | Holographic vats, floating eggs | Particle fog, plasma arcs          | Pollution replaced by synthetic ethics variable.    |

---

## 🧰 Visual & System Modules

| Module                              | Description                                    | PR     | Notes                                     |
| ----------------------------------- | ---------------------------------------------- | ------ | ----------------------------------------- |
| **FeedParticles**                   | Grain-like particles reacting to feed_fraction | PR-008 | Active visual feedback.                   |
| **Conveyor Belt System**            | Visual egg transport tied to PPS               | PR-009 | Expands motion midgame.                   |
| **Pollution Overlay UI**            | Displays pollution, stress, reputation         | PR-010 | Integrates with EnvironmentDirector.      |
| **Weather & Day/Night Cycle**       | Ambient variation, pollution clearing          | PR-012 | Aesthetic depth.                          |
| **Wildlife Return / Green Revival** | Birds & vegetation restore at high rep         | PR-013 | Ethical prestige reward.                  |
| **Mitigation Structures**           | Bio-filters, composters, solar panels          | PR-014 | Visually and numerically lower pollution. |

---

## 🪄 Minigames / Active Layers

| Concept                               | Yolkless Theme                            | Purpose                     | Priority                 |
| ------------------------------------- | ----------------------------------------- | --------------------------- | ------------------------ |
| **Brick-Breaker “Feed Mixer”**        | Smash feed pellets for efficiency         | Midgame active bonus        | 🔜                       |
| **Merge / Gravity “Droplet Reactor”** | Merge protein spheres in lab              | Late-game prestige visual   | 🔜                       |
| **Drone / Delivery Mini-Sim**         | Delivery vans / drones drop shipments     | Short burst rewards         | Optional                 |
| **Tower Defense “Bio-Security”**      | Sanitation bots defend from contamination | Timed reputation event      | Optional                 |
| **Exploration / Expansion Map**       | Expanding regional franchises             | Post-prestige meta layer    | Future                   |
| **Ecosystem / Evolution Sim**         | Living environment reacts to ethics       | Continuous background layer | 🌟 Core Long-Term Vision |

---

## 🌎 Narrative & Prestige Paths

| Branch                           | Trigger                               | Theme                          | Outcome                           |
| -------------------------------- | ------------------------------------- | ------------------------------ | --------------------------------- |
| **Industrial Efficiency**        | Focus on automation upgrades          | Profit & speed over welfare    | Classic idle loop.                |
| **Ethical Sustainability**       | Welfare & mitigation research         | Green tech & moral growth      | Wildlife visuals; rep multiplier. |
| **Synthetic Ascension**          | Synthetic Lab mastery                 | Post-organic efficiency        | Infinite scaling meta.            |
| **Restoration Path (Ecosystem)** | Final prestige choice “Restore Earth” | Environmental regrowth sandbox | Narrative endgame.                |

---

## 🧠 Research & Meta Systems

* **Tech Tree:** Branches for Production, Capacity, Automation, Ethics, Synthetic Biology, Environment.
* **Skill-Tree Nodes:** Unlock visuals, mitigation upgrades, and automation tiers.
* **Reputation Influence:** Environment variables modify prestige yield.
* **Automation AI:** Later unlocks manage feed and upgrades automatically; visually represented as robotic workers.

---

## 🎨 Art & Presentation

| Layer                        | Description                | Timeline   |
| ---------------------------- | -------------------------- | ---------- |
| **Feed Bar & Particles**     | Player feedback core       | ✅ Complete |
| **Environment Backdrops**    | Modular 2D scenes per tier | PR-010→014 |
| **Dynamic Color Grading**    | Pollution → hue shift      | PR-011     |
| **Camera Motion / Parallax** | Tier transitions           | PR-012     |
| **UI Polish**                | WCAG AA, tooltips, icons   | Continuous |

---

## 🧩 Technical & Tooling

| Task                       | Goal                                        | Status     |
| -------------------------- | ------------------------------------------- | ---------- |
| **CI Smoke Test**          | `godot4 --headless --check-only` validation | 🔜         |
| **Performance Budget**     | ≤5% GPU load idle                           | Ongoing    |
| **Accessibility Audit**    | WCAG AA compliance                          | Ongoing    |
| **Save/Load Versioning**   | Persist environment variables               | 🔜         |
| **Deterministic .uid IDs** | Stable resource references                  | ✅          |
| **Roadmap Maintenance**    | Update after each PR merge                  | Continuous |

---

## 📅 Long-Term Vision Milestones

| Milestone                      | Description                          | Target  |
| ------------------------------ | ------------------------------------ | ------- |
| **M1 – Living Coop**           | Feed + Backyard environment reactive | Q4 2025 |
| **M2 – Factory Automation**    | Conveyor visuals + Pollution system  | Q1 2026 |
| **M3 – Synthetic Lab Era**     | Merge/Gravity Reactor visual layer   | Q2 2026 |
| **M4 – Ecosystem Restoration** | Environmental regrowth sandbox       | Q3 2026 |
| **M5 – Full Release / Steam**  | Feature-complete, optimized build    | Q4 2026 |

---

### Maintenance Notes

* Update this file with each major PR merge.
* Reference PR numbers in changelogs and README.
* Keep all environment & visual modules modular under `/game/scenes/modules/`.
* Future narrative and ethics expansions extend this roadmap instead of separate notes.

---

*(End of Roadmap v2025.10)*
