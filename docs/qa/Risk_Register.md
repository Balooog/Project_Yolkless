# Risk Register

> Tracks systemic risks across gameplay, performance, and operations. Review monthly with engineering, design, and ops stakeholders. Terminology: [Glossary](../Glossary.md).

## Probability × Impact Matrix

| Probability \ Impact | Low | Medium | High |
| --- | --- | --- | --- |
| Low | Monitor in backlog | Monitor; add telemetry guard | Add mitigation owner |
| Medium | Add to sprint radar | Assign PX/bug + fallback plan | Fast-track mitigation; alert leads |
| High | Escalate in stand-up | Create incident checklist | Immediate strike team |

## Active Risks

| Risk | Probability | Impact | Owner | Mitigation |
| --- | --- | --- | --- | --- |
| Sandbox render fallback triggers frequently | Medium | High | Graphics engineer | Profiling + renderer optimisation (PX-021.3). |
| UI baseline diffs exceed threshold | Medium | Medium | UI lead | Strengthen visual regression pipeline, review tokens usage. |
| Balance regression post-upgrade | Low | High | Design | Replay-based regression tests; see [Test Strategy](Test_Strategy.md). |
| Localization string overflow | Medium | Medium | Ops / UX | Pseudo-loc pass (Localization Pipeline) before release. |
| Save migration errors | Low | High | Tools engineer | Expand persistence tests, ensure rollback path documented. |

## Review Cadence
- Monthly QA/Design sync (attach updated matrix).
- Pre-release go/no-go includes risk register sign-off.
- Archive previous registers under `reports/risk/` for audit trail.

## References
- [Test Strategy](Test_Strategy.md)
- [CI Pipeline](CI_Pipeline.md)
- [Performance Budgets](../quality/Performance_Budgets.md)
