# RM-000: DocOps Bootstrap Execution

- **PR Link:** `PR-000`
- **PX Drivers:** PX-000.2, PX-004.1 (DocOps bootstrap + docs lint enablement)

## Goals
- Scaffold `docs/bootstrap/` discovery, profile, and adapter notes.
- Align documentation folders with the Game/Simulation baseline and add missing quickstarts.
- Provide roadmap navigation (`RM-Index`, `ROADMAP_TASKS.md`) and ensure quickstarts + AGENTS reference docops artifacts.
- Add a docs lint script + CI job to keep structure enforceable.

## Recent Actions
- [2025-10-28] Migrated legacy RM logs into `docs/roadmap/RM/` and created `RM-Index.md`.
- [2025-10-28] Authored quickstarts + Product Pillars/UX Principles to align with doc profile.
- [2025-10-28] Drafted docs lint script and CI stage (pending validation).

## Next Steps
- Wire telemetry metric diffs into RM change logs whenever nightly replays diverge.
- Collect clarifications on comfort thresholds and LiveOps SLAs for future adapters (if hospitality or seasonal beats require them).
