# Contributing

## Core Practices
- Ship small, focused PRs; branch from `feature/RM-###-slug` when tracking roadmap work.
- Use Conventional Commits (`feat:`, `fix:`, `docs:` ...); include traceability footers (`RM: RM-011`, `PX: PX-011.2`, `Docs: Balance_Playbook`).
- Keep gameplay data typed, follow Godot 4 style guides, and prefer Yolkless helpers (`StatBus`, `YolkLogger`) when available.

## Before You Open a PR
- `python tools/docs_lint/check_structure.py`
- `make validate-contracts`
- `python scripts/telemetry_replay_demo.py --seed 42 --ticks 200` (CI will also upload artifacts)
- Run module checks as needed: `./tools/headless_tick.sh 300`, `$(bash tools/godot_resolver.sh) --headless ...`, profiler budgets, etc.

## Documentation & Artifacts
- Update docs alongside code; link pages in the PR description.
- Capture telemetry artifacts (`kpi.json`, `kpi_chart.png`) plus any supporting screenshots/logs (attach or rely on CI uploads).
- Summarise KPI deltas or balance impacts in the PR notes.

## Release Workflow
- Advancing a roadmap module across phase gates requires checking off [Release Milestones](docs/ops/Release_Milestones.md) and attaching evidence in the PR.
- Production will drive tag creation: once a tag `vX.Y.Z` is pushed, `.github/workflows/release.yml` auto-updates `CHANGELOG.md`—do **not** edit the changelog manually on release branches.
- Include a “Release Readiness” note in PRs that impact milestones, referencing telemetry diffs (`python3 tools/gen_dashboard.py --diff …`) and any outstanding risks recorded in `docs/qa/Risk_Register.md`.
- For hotfixes, use `hotfix/vX.Y.Z-short-slug` branches and coordinate with Production before tagging to keep automation in sync.

## References
- [Developer Handbook](docs/Developer_Handbook.md)
- [Build Cookbook](docs/dev/Build_Cookbook.md)
- [Test Strategy](docs/qa/Test_Strategy.md)
- [Release Playbook](docs/ops/Release_Playbook.md)
- [Roadmap Index](docs/roadmap/INDEX.md)
