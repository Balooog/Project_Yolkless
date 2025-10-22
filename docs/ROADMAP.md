# Project Yolkless – Comprehensive Feature Roadmap

*(Version 2025.10 — consolidated from design sessions)*

> Major prompts are archived in `docs/prompts/` (roadmap specs as `RM-###.md`, driver attempts as `PX-###.x.md`).

---

## 🥚 Core Gameplay Loops

| Feature (Spec)                      | Status        | Description / Notes                                                                              | Next PX Target                                                        |
| ----------------------------------- | ------------- | ------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------- |
| **RM-005 – Logging & Diagnostics**  | ✅ Active      | YolkLogger with queued writes, Diagnostics overlay, and clipboard export.                        | —                                                                     |
| **RM-006 – Feed System**            | ✅ Complete    | Hold-to-feed mechanic with feed bar, drain/refill loop, and capacity/refill/efficiency upgrades. | —                                                                     |
| **RM-007 – Offline Passive Rate**   | ⏳ Planned     | Offline production at reduced efficiency (≈25% base PPS). Automation adds a multiplier.          | PX-007.1 – Offline baseline sim (Target Sprint 2025.11)               |
| **RM-008 – VisualDirector & FX**    | ⏳ In Progress | Reactive particle effects while feeding; foundation for later modules.                           | PX-008.2 – Particle tuning & gating (Target Sprint 2025.12)           |
| **RM-010 – Environment Simulation** | ⏳ Prototype   | Dynamic ecosystem reacting to pollution, stress, and reputation. Evolves with production tiers.  | PX-010.3 – Backyard polish & overlay stability (Target Sprint 2025.11) |
| **Prestige / Rebrand Loop**         | ✅ Implemented | Converts Reputation Stars to permanent production multipliers; “Rebrand & Advance” transition.   | —                                                                     |

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

| Module                              | Linked RM | Description                                    | Next PX Target                                               |
| ----------------------------------- | --------- | ---------------------------------------------- | ------------------------------------------------------------ |
| **FeedParticles**                   | RM-008    | Grain-like particles reacting to feed_fraction | PX-008.2 – Particle tuning & gating (Target Sprint 2025.12)  |
| **Conveyor Belt System**            | RM-009    | Visual egg transport tied to PPS               | PX-009.1 – Conveyor prototype pass (Target Sprint 2026.01)   |
| **Pollution Overlay UI**            | RM-010    | Displays pollution, stress, reputation         | PX-010.3 – Overlay stability polish (Target Sprint 2025.11)  |
| **Weather & Day/Night Cycle**       | RM-012    | Ambient variation, pollution clearing          | PX-012.1 – Lighting baseline (Target Sprint 2026.02)         |
| **Wildlife Return / Green Revival** | RM-013    | Birds & vegetation restore at high rep         | PX-013.1 – Wildlife loop prototype (Target Sprint 2026.03)   |
| **Mitigation Structures**           | RM-014    | Bio-filters, composters, solar panels          | PX-014.1 – Mitigation build-out (Target Sprint 2026.03)      |

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

| Layer                        | Linked RM            | Timeline     | Notes / Next PX Target                                             |
| ---------------------------- | -------------------- | ------------ | ------------------------------------------------------------------ |
| **Feed Bar & Particles**     | RM-006, RM-008       | ✅ Complete   | —                                                                  |
| **Environment Backdrops**    | RM-010→RM-014        | On deck      | PX-010.3 – Backyard polish kickoff (Target Sprint 2025.11)         |
| **Dynamic Color Grading**    | RM-011               | Planned      | PX-011.1 – Color grading prototype (Target Sprint 2026.02)         |
| **Camera Motion / Parallax** | RM-012               | Planned      | PX-012.2 – Camera sweep pass (Target Sprint 2026.02)               |
| **Placeholder Art Policy**   | RM-012               | Ongoing      | PX-012.3 – Asset pipeline refresh checklist (Target Sprint 2025.12) |
| **UI Polish**                | —                    | Continuous   | Micro PX as needed; no major driver scheduled                      |

---

## 🧩 Technical & Tooling

| Task                       | Goal                                        | Status     |
| -------------------------- | ------------------------------------------- | ---------- |
| **CI Smoke Test**          | `godot4 --headless --check-only` validation | 🔜         |
| **Performance Budget**     | ≤5% GPU load idle                           | Ongoing    |
| **Accessibility Audit**    | WCAG AA compliance                          | Ongoing    |
| **Save/Load Versioning**   | Persist environment variables               | 🔜         |
| **Deterministic .uid IDs** | Stable resource references                  | ✅          |
| **Roadmap Maintenance**    | Update after each RM/PX delivery            | Continuous |

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

* Update this file after each major RM or PX delivery.
* Reference RM/PX identifiers in changelogs and README.
* Keep all environment & visual modules modular under `/game/scenes/modules/`.
* Future narrative and ethics expansions extend this roadmap instead of separate notes.

---

*(End of Roadmap v2025.10)*
