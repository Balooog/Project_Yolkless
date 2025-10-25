# Contributor Examples

> Mini tutorials showing how to contribute safely. Pair with [Developer Handbook](../Developer_Handbook.md) and [Bug & Feature Workflow](../ops/Bug_and_Feature_Workflow.md).

## Mini PX: Add a New Upgrade

1. **Scope PX:** Draft acceptance criteria (e.g., “Add Tier 2 feed upgrade increasing feed_rate by 10 %”).
2. **Data:** Update `data/upgrade.tsv` with new row; run `./tools/validate_tables.py`.
3. **Narrative:** Add flavor line to [`docs/design/Narrative_Hooks.md`](../design/Narrative_Hooks.md) and entry in `docs/design/Upgrade_Families.md` if needed.
4. **UI Binding:** Ensure UI atoms reference the new upgrade ID (e.g., button in Store sheet).
5. **Testing:**
   - Run `GODOT_BIN=... ./tools/check_only_ci.sh`
   - `./tools/ui_viewport_matrix.sh` + `./tools/ui_compare.sh`
   - `$GODOT_BIN --headless --script res://tools/replay_headless.gd --duration=120`
6. **Docs:** Mention changes in relevant docs (Balance Playbook, Upgrade Families).
7. **PR:** Include `RM:` / `PX:` footers, attach artifacts (validator output, UI diff).

## Example Validator Output
```
[validate] upgrade.tsv: 0 errors, 0 warnings
SUCCESS  tables validated in 0.09s
```

## References
- [Build Cookbook](../dev/Build_Cookbook.md)
- [UI Principles](../ux/UI_Principles.md)
- [Test Strategy](Test_Strategy.md)
- [Bug & Feature Workflow](../ops/Bug_and_Feature_Workflow.md)
