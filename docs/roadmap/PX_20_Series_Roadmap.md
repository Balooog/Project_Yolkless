# PX-020 Series Roadmap — Economy / Conveyor + GUI Integration

> Tracks the documentation-first effort for PX-020.  Align with [PR-020](PR-020.md) and RM notes under `docs/roadmap/RM/RM-020*.md`.

## Status Table
| PX | Focus | Owner | Status | Notes |
| --- | --- | --- | --- | --- |
| PX-020.0 | Series overview & planning | DocOps / Systems | 🧭 Drafting | Anchor doc + Mermaid flow published. |
| PX-020.1 | HUD wiring (Slots D/F + StatBus) | Systems | ✅ Complete | HUD layout, signals, StatBus, replay logging documented. |
| PX-020.2 | Automation Panel interaction | UI / Systems | 🟡 In Progress | Need to finalize automation panel signals + StatBus mirroring. |
| PX-020.3 | Tooltip + copy alignment | Narrative | 🧭 Drafting | Copy catalog + tooltip guidelines pending review. |
| PX-020.4 | Telemetry & replay coverage | QA / Systems | 🧭 Drafting | Replay steps + CI gating doc, ties to Telemetry Replay spec. |

## Milestones & Cross-Refs
- **UI Contracts:** Slots D/F documented in [UI Matrix](../ui_baselines/ui_matrix.md) with links back to [PX-020.1](../px/PX-020.1_GUI_Wiring.md).
- **Signals & Stats:** `docs/architecture/Signals_Events.md` and `docs/architecture/StatBus_Catalog.md` enumerate all PX-020 additions; reference these before editing runtime scripts.
- **Modules:** [Economy](../modules/economy.md) and [Conveyor](../modules/conveyor.md) capture the smoothing/backlog semantics required by both HUD and automation flows.
- **Telemetry:** [PX-020.4 Telemetry Replay](../px/PX-020.4_Telemetry_Replay.md) ties into `docs/quality/Telemetry_Replay.md` for CI-ready guidance.

## Acceptance Checklist
- Table above stays in sync with the individual PX docs and the [Shipping Implementation Plan](Shipping_Implementation_Plan.md).
- Each PX doc links back here (see “Key Documents” on the site index) so contributors can navigate without opening PR-020 manually.
- Status emojis match roadmap conventions (`✅`, `🟡`, `🧭`) and are updated when work lands.
