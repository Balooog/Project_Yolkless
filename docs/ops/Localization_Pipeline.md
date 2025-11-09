# Localization Pipeline (Placeholder)

> Outline for future translation workflow. Tracks pseudo-localisation passes and eventual string extraction.

## Current State
- English-only strings stored in `game/data/strings_egg.tsv`.
- Pseudo-localisation available via PX-010.7 tooling (string expansion + accent injection).
- UILint + baseline screenshots ensure overflow regressions show up early.

## Planned Workflow
1. Extract translatable strings into `.po`/CSV format (tooling TBD).
2. Integrate localisation middleware (Godot translation server) with dynamic reload.
3. Automate pseudo-loc run in CI (nightly) to catch clipping issues.
4. Add translators handbook covering tone guidelines (see [Narrative Hooks](../design/Narrative_Hooks.md)).

## TODOs
- [x] Define file format for exported strings (`/i18n/strings.pot`).
- [x] Add pseudo-loc CI job referencing [Test Strategy](../qa/Test_Strategy.md).
- [ ] Document right-to-left layout considerations.
- [ ] Coordinate with UI atoms to ensure font fallbacks.

## Extraction Script
- Script: `tools/export_strings.gd` (headless `SceneTree` tool).
- Default output: `res://i18n/strings.pot` (GNU gettext template with `msgctxt` mirroring TSV keys).
- Command example (WSL/Linux):
  ```bash
  source .env
  $(bash tools/godot_resolver.sh) --headless --path "$(pwd)" --script res://tools/export_strings.gd --output res://i18n/strings.pot
  ```
- The exporter reads `res://game/data/strings_egg.tsv`, skips comment/blank lines, preserves placeholder braces (e.g., `{value}`), and escapes emoji plus control characters.
- Run `tools/localization_export_check.sh` (also invoked by CI) to regenerate the POT and fail if the checked-in template drifts from the TSV.
- Check the generated POT into source control whenever the TSV changes so translators can diff updates alongside gameplay/UI changes.

## Pseudo-Localization Smoke
- Toggle pseudo-localization by setting `PSEUDO_LOC=1` (overrides the editor flag exposed on the `Config` autoload).
- Script: `tools/pseudo_loc_smoke.sh` – runs UILint against `res://scenes/ui_smoke/MainHUD.tscn` and captures viewport screenshots into `dev/screenshots/ui_pseudo_loc/`.
- CI calls this script after the normal `check_only` build; run it locally before touching HUD layout to catch overflow issues early:
  ```bash
  PSEUDO_LOC=1 tools/pseudo_loc_smoke.sh
  ```
- Artifacts: UILint console summary + pseudo-localized screenshots for design/QA review.

## References
- [UI Principles](../ux/UI_Principles.md)
- [RM-010 UI Checklist](../qa/RM-010-ui-checklist.md)
- [Developer Handbook](../Developer_Handbook.md)
