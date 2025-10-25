# CI Pipeline

> Stages executed on every PR and nightly build. Aligns with [Glossary](../Glossary.md), [Test Strategy](Test_Strategy.md), and [Build Cookbook](../dev/Build_Cookbook.md).

## Stage Overview
1. `validate-tables` — run schema checks via `tools/validate_tables.py`.
2. `build` — call `tools/check_only_ci.sh` to ensure warnings-as-errors clean build.
3. `replay` — execute headless replay (`tools/replay_headless.gd`) and publish JSON/CSV artifacts.
4. `ui-baseline` — capture viewport matrix, compare against baseline PNGs.
5. `publish-artifacts` — upload logs, diffs, and telemetry summaries.
6. `generate-dashboard` — build nightly metrics HTML (see [Metrics Dashboard Spec](Metrics_Dashboard_Spec.md)).
7. (Release tags) `auto-changelog` — generate changelog via `tools/gen_changelog.py` and attach to release (see [Release Playbook](../ops/Release_Playbook.md)).

## Pipeline Diagram

```mermaid
graph LR
    A[validate-tables] --> B[build]
    B --> C[replay]
    C --> D[ui-baseline]
    D --> E[publish-artifacts]
    E --> F[generate-dashboard]
    E --> G[auto-changelog (tags)]
```

## Artifacts
| Stage | Artifact | Notes |
| --- | --- | --- |
| validate-tables | `logs/validation/*.log` | Parser errors/warnings. |
| replay | `reports/nightly/*.json`, `logs/perf/*.csv` | Feed into [Telemetry & Replay](../quality/Telemetry_Replay.md). |
| ui-baseline | `ui_diff_report.html`, screenshot PNGs | Reviewed against [RM-010 UI checklist](RM-010-ui-checklist.md). |
| publish-artifacts | `artifacts/*.zip` | Contains UILint.txt, StatsProbe alerts, baseline diff summary.

## Failure Handling
- Any stage failure blocks merge.
- Replay failures must include relevant JSON snippet + StatsProbe alert screenshot in PR discussion.
- UI baseline diffs >1 % require design sign-off before updating baseline.
- UILint violations must be resolved before rerun; do not override thresholds.

## References
- [Test Strategy](Test_Strategy.md)
- [Build & Run Cookbook](../dev/Build_Cookbook.md)
- [Performance Budgets](../quality/Performance_Budgets.md)
