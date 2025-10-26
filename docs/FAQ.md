# Frequently Asked Questions

## Build & Run

**Q:** Why does Codex fail to execute the Godot Snap package?  
**A:** Snap lacks required permissions for headless capture. Use the shared Windows console build (`/mnt/c/src/godot/Godot_v4.5.1-stable_win64_console.exe`) via the repo `.env` (see [Build Cookbook](dev/Build_Cookbook.md)).

**Q:** Where are screenshots saved?  
**A:** Local captures go to `dev/screenshots/`; CI artifacts live under `artifacts/ui_baseline/` in the pipeline.

**Q:** How do I validate data tables?  
**A:** Run `./tools/validate_tables.py --tables=data/upgrade.tsv,data/research.tsv` before committing.

**Q:** How do I rerun the nightly replay manually?  
**A:** `$GODOT_BIN --headless --script res://tools/replay_headless.gd --duration=300 --seed=42`.

## CI & Automation

**Q:** CI shows pixel diff >1 %. What now?  
**A:** Review `ui_diff_report.html`. If intentional, regenerate baseline via `./tools/ui_baseline.sh` and commit PNG updates after design approval.

**Q:** Where do CI artifacts live?  
**A:** In the pipeline `publish-artifacts` stage—the zipped output includes UILint.txt, StatsProbe alerts, and screenshot diffs.

**Q:** Who owns telemetry alerts?  
**A:** QA automation lead (see [Risk Register](qa/Risk_Register.md)). Escalate via Slack and log mitigation in the register.

## UI & UX

**Q:** UI text escapes the screen. What should I do?  
**A:** Run `uilint_scene.gd` or call `UILint.assert_no_overflow()`; follow [UI Principles](ux/UI_Principles.md) for overflow policy.

**Q:** How are UI fonts and colors managed?  
**A:** Through `/ui/theme/Tokens.tres` documented in [UI Atoms module](modules/ui_atoms.md).

## Sandbox & Systems

**Q:** What drives the Comfort Index?  
**A:** Environment factors feed the sandbox CA grid; see [Environment Playbook](design/Environment_Playbook.md) and [Sandbox module](modules/sandbox.md).

**Q:** Sandbox spikes over budget—where to look?  
**A:** Check StatsProbe metrics (`sandbox_render_ms_p95`) in replay JSON and follow mitigation steps in `Risk_Register.md`.

## Gameplay Design

**Q:** How does prestige affect PPS?  
**A:** Wisdom multipliers follow the compression curve in [Wisdom Multipliers](design/Wisdom_Multipliers.md).

**Q:** How do I add a new upgrade?  
**A:** Follow the mini-PX tutorial in [Contributor Examples](qa/Contributor_Examples.md); update `data/upgrade.tsv`, run validator, and wire UI atoms.

## Miscellaneous

**Q:** Where can I find quick definitions?  
**A:** See the [Glossary](Glossary.md).

**Q:** How do I report bugs or request features?  
**A:** Follow [Bug & Feature Workflow](ops/Bug_and_Feature_Workflow.md).
