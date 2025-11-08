---
title: Project Yolkless Docs
layout: default
---

# 🐣 Project Yolkless Documentation · v19.1 (Baseline Stable)

> **Build:** `{{ site.github.build_revision | slice:0,7 }}`  
> **Last Updated:** {{ site.time | date: "%Y-%m-%d %H:%M UTC" }}  
> **Branch:** {{ site.github.branch }}  
> **Maintainer:** Alex Balog · Lead Geophysicist · THG Geophysics

---

## 📘 PX Series Roadmap
| PX ID | Title | Status |
|:------|:------|:------:|
| PX-018 | HUD Baseline / Power Warnings | ✅ Complete |
| PX-019 | Sandbox Visual Integration | 🟡 In Progress |
| PX-020 | Economy / Conveyor + GUI Integration | 🧭 Drafting |

---

### 📄 Key Documents
- [UI Baseline Layout Spec](ui_baselines/README_UI_BASELINE_LAYOUT.md)
- [UI Matrix Map](ui_baselines/ui_matrix.md)
- [PX-020 Series Roadmap](roadmap/PX_20_Series_Roadmap.md)
- [PX-020.1 GUI Wiring](px/PX-020.1_GUI_Wiring.md)
- [PX-020.2 Automation Panel](px/PX-020.2_Interaction_AutomationPanel.md)

---

### 🧩 Architecture
- [Signals & Events](architecture/Signals_Events.md)
- [StatBus Catalog](architecture/StatBus_Catalog.md)
- [Telemetry Replay Guidance](quality/Telemetry_Replay.md)

---

### 🧪 Developer Guides
- [Build Cookbook](dev/Build_Cookbook.md)
- [QA Checklist (UI)](qa/RM-010-ui-checklist.md)

---

## 🧭 Version History
| Version | Date | Summary |
|:--------|:------|:---------|
| 19.1 | {{ site.time | date: "%Y-%m-%d" }} | Baseline stable · headless captures · CI linter added |
| 19.0 | 2025-10-?? | HUD baseline established · PX-018 complete |
| 18.x | 2025-?? | Early prototype builds |

---

<footer style="font-size:0.9em;opacity:0.75;margin-top:2em;">
© {{ "now" | date: "%Y" }} THG Geophysics · Project Yolkless Docs · Built from commit {{ site.github.build_revision | slice:0,7 }} on branch {{ site.github.branch }}.  
Powered by GitHub Pages + Jekyll.
</footer>
