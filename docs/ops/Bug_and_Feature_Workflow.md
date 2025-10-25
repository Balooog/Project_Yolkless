# Bug & Feature Workflow

> Standard process for triaging, developing, and closing issues. See [Glossary](../Glossary.md) for terminology.

## Labels
Use combinations of:
`bug`, `feature`, `docs`, `performance`, `ui`, `sandbox`, `automation`, `blocked`, `needs-design`, `needs-qa`.

## Branch Naming
- Bug fixes: `fix/<short-description>` (e.g., `fix/sandbox-fallback`).
- Feature work: `feature/RM-###-slug` (e.g., `feature/RM-021-sandbox-renderer`).
- Documentation: `docs/<topic>` when standalone.

## Process
1. **Open Issue:** Include reproduction steps or design brief; tag relevant RM/PX.
2. **Scope PX:** Codex drafts or engineer authors PX canvas with acceptance criteria.
3. **Implementation:** Follow PX tasks, run smoke flow (check_only_ci, UI compare, replay).
4. **Testing:** Attach relevant artifacts (UI diff, replay JSON, UILint output).
5. **Review:** Peer review ensures doc updates + tests included.
6. **Merge:** Require green CI. Use commit footers `RM: ###`, `PX: ###` when applicable.
7. **Closure:** Link merged PR to issue, note follow-up actions if any.

## Triage Cadence
- Weekly triage meeting (or Codex summary) to prioritise backlog.
- Priority scale: P1 Critical (build breakage), P2 High, P3 Medium, P4 Polish.
- Track status via project board, link to RM/PX for visibility.

## QA Handoff
- Bugs: Verify fix with `tools/replay_headless.gd` or targeted integration tests.
- UI changes: Provide `ui_diff_report.html` and UILint results.
- Sandbox/perf: Attach StatsProbe CSV + risk register update if thresholds exceed budgets.

## References
- [Developer Handbook](../Developer_Handbook.md)
- [CI Pipeline](../qa/CI_Pipeline.md)
- [Test Strategy](../qa/Test_Strategy.md)
- [Risk Register](../qa/Risk_Register.md)
