# Tooling Guide

> Reference for Godot version policy, plugins, and maintenance workflow. Use alongside [Build & Run Cookbook](Build_Cookbook.md) and [Developer Handbook](../Developer_Handbook.md).

## Godot Version Policy
- Current standard: **Godot 4.2.2-stable**.
- Upgrade cadence: evaluate new patch releases quarterly; log decision in ADR.
- Requirements for upgrading:
  1. Run `tools/check_only_ci.sh` on new binary.
  2. Validate UI baseline and replay metrics on reference hardware (Steam Deck, mid-range laptop).
  3. Update `GODOT_BIN` references in docs and CI.
  4. Notify team via release notes.

## Plugins & Extensions
- **Reshade-free**: no post-processing plugins to preserve deterministic visuals.
- **CSV/JSON Parsers**: custom scripts under `tools/`; keep pure GDScript for portability.
- **Editor helpers**: optional editor-only scripts live under `dev/`. Document usage in README before adding.
- Propose new plugins via ADR with performance impact analysis.

## Tool Maintenance
- Scripts live under `tools/`; ensure each has executable bit (`chmod +x`).
- Unit-test helpers placed in `tests/` with clear naming (`test_*`).
- When adding new CLI scripts, document them in [Build & Run Cookbook](Build_Cookbook.md) and relevant module briefs.

## Automated Tooling
- `check_only.sh` / `check_only_ci.sh`: compile-time sanity.
- `ui_baseline.sh`, `ui_compare.sh`: visual regression harness.
- `ui_viewport_matrix.sh`: viewport sweep for S/M/L breakpoints.
- `uilint_scene.gd`: headless lint for UI scenes.
- `replay_headless.gd` / `nightly_replay.sh`: telemetry capture.
- `validate_tables.py`: schema validation for TSV/JSON assets.

## References
- [Developer Handbook](../Developer_Handbook.md)
- [CI Pipeline](../qa/CI_Pipeline.md)
- [Performance Budgets](../quality/Performance_Budgets.md)
