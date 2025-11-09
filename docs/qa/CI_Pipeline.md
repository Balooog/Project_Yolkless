# CI Pipeline

> Stages executed on every PR and nightly build. Aligns with [Glossary](../Glossary.md), [Test Strategy](Test_Strategy.md), and [Build Cookbook](../dev/Build_Cookbook.md).

## Stage Overview
1. `docs-lint` — run `python3 tools/docs_lint/check_structure.py` and upload `docs-lint-report.txt` so DocOps drift is caught early.
2. `validate-tables` — run schema checks via `tools/validate_tables.py`.
3. `renderer-setup` — install lavapipe dependencies (`mesa-vulkan-drivers`, `vulkan-tools`, `libvulkan1`) and source `.env` for `VK_ICD_FILENAMES`.
4. `build` — call `tools/check_only_ci.sh` to ensure warnings-as-errors clean build.
5. `localization` — triggered inside `check_only_ci.sh`; runs `tools/localization_export_check.sh` (fails on stale `i18n/strings.pot`) and `tools/pseudo_loc_smoke.sh` (UILint + viewport capture with `PSEUDO_LOC=1`).
6. `replay` — execute headless replay (`tools/replay_headless.gd`) and publish JSON/CSV artifacts (optional `ECONOMY_AMORTIZE_SHIPMENT=1` for profiling-only runs; stay disabled for CI baselines).
7. `ui-baseline` — capture viewport matrix using Vulkan, compare against baseline PNGs.
8. `publish-artifacts` — upload logs, diffs, and telemetry summaries.
9. `generate-dashboard` — build nightly metrics HTML (see [Metrics Dashboard Spec](Metrics_Dashboard_Spec.md)) via `tools/generate_dashboard.sh`.
10. (Release tags) `auto-changelog` — generate changelog via `tools/gen_changelog.py` and attach to release (see [Release Playbook](../ops/Release_Playbook.md)).

## Pipeline Diagram

```mermaid
graph LR
    D[docs-lint] --> A[validate-tables]
    A --> B[renderer-setup]
    B --> C[build]
    C --> L[localization]
    L --> E[replay]
    E --> F[ui-baseline]
    F --> G[publish-artifacts]
    G --> H[generate-dashboard]
    G --> I[auto-changelog (tags)]
```

## Artifacts
| Stage | Artifact | Notes |
| --- | --- | --- |
| docs-lint | `docs-lint-report.txt` | Snapshot of DocOps structure check output; inspect when lint fails. |
| validate-tables | `logs/validation/*.log` | Parser errors/warnings. |
| renderer-setup | `logs/renderer-setup.txt` | Apt output for lavapipe install + resolver diagnostics. |
| localization | `i18n/strings.pot`, `dev/screenshots/ui_pseudo_loc/*.png` | POT must match TSV; pseudo-loc screenshots/UILint console output attach to PRs when regressions appear. |
| replay | `reports/nightly/*.json`, `logs/perf/*.csv` | Feed into [Telemetry & Replay](../quality/Telemetry_Replay.md); includes economy sub-phase metrics (`eco_*`) for p95 budgeting. |
| ui-baseline | `ui_diff_report.html`, screenshot PNGs | Reviewed against [RM-010 UI checklist](RM-010-ui-checklist.md). |
| publish-artifacts | `artifacts/*.zip` | Contains UILint.txt, StatsProbe alerts, baseline diff summary. |
| generate-dashboard | `reports/dashboard/index.html` | Produced by `tools/generate_dashboard.sh`; attached for LiveOps review. |

## Failure Handling
- Any stage failure blocks merge.
- Replay failures must include relevant JSON snippet + StatsProbe alert screenshot in PR discussion.
- UI baseline diffs >1 % require design sign-off before updating baseline.
- UILint violations must be resolved before rerun; do not override thresholds.

## References
- [Test Strategy](Test_Strategy.md)
- [Build & Run Cookbook](../dev/Build_Cookbook.md)
- [Performance Budgets](../quality/Performance_Budgets.md)
