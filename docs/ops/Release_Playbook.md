# Release Playbook

> Fast reference for getting a tag out safely. Detailed guidance follows below.

## Quick Release Flow
1. Ensure `main` is green; docs-lint passes.
2. Tag release locally or via GitHub UI: `vX.Y.Z` (SemVer).
3. Push tag → `release.yml` updates `CHANGELOG.md` and pushes to `main`.
4. Create GitHub Release; attach any extra artifacts if needed.
5. Review [Release Milestones](Release_Milestones.md) to confirm phase gate evidence is archived.

---

> Guides versioning, changelog preparation, and release execution for Project Yolkless.

## Versioning Scheme
- Semantic core (`MAJOR.MINOR.PATCH`) combined with date tag (`YYYYMMDD`). Example: `0.4.0-20251205`.
- Increment rules:
  - **MAJOR:** Breaking save format / architectural overhaul.
  - **MINOR:** New gameplay module, UI overhaul, or significant feature flag.
  - **PATCH:** Bug fixes, balance tweaks, documentation-only releases.
- Tag releases with `vMAJOR.MINOR.PATCH` and annotate date in changelog heading.

## Changelog Workflow
1. Collect merged PR summaries since last release (use `git log --oneline origin/main..<current>`).
2. Categorise entries under *Gameplay*, *UI*, *Systems*, *Balance*, *Docs*, *QA*.
3. Call out telemetry baseline changes, new PX coverage, and performance summary (p95 metrics).
4. Store changelog in `reports/releases/<version>.md` and link from `README` if public.
5. Trigger CI job `auto-changelog` after tagging to publish the generated notes.

### Generation Example
```bash
python tools/gen_changelog.py --from v0.4.0 --to v0.5.0 > CHANGELOG.md
```

## Release Checklist
- [ ] CI pipeline green (see [CI Pipeline](../qa/CI_Pipeline.md)).
- [ ] Telemetry replay (5 min and 30 min soak) within [Performance Budgets](../quality/Performance_Budgets.md).
- [ ] UI baseline diffs reviewed/approved; new baseline committed if required.
- [ ] Risk register updated with post-release monitoring plan.
- [ ] Version bump committed (`project.godot`, docs) and tag created.
- [ ] Build artifacts (Linux, Windows) exported via Godot CLI and stored under `releases/`.
- [ ] Release notes circulated to team (Slack/email) with timeline and rollback plan.

## Rollback Procedure
- Keep previous release builds in `releases/previous/` with matching changelog.
- To rollback:
  1. Restore prior tag branch.
  2. Re-run CI smoke + replay to ensure stability.
  3. Communicate rollback to team; update risk register with root-cause investigation owner.

## References
- [Developer Handbook](../Developer_Handbook.md)
- [Risk Register](../qa/Risk_Register.md)
- [Localization Pipeline](Localization_Pipeline.md)
