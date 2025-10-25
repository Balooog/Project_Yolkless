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
- [ ] Define file format for exported strings (`/locale/*.po`).
- [ ] Add pseudo-loc CI job referencing [Test Strategy](../qa/Test_Strategy.md).
- [ ] Document right-to-left layout considerations.
- [ ] Coordinate with UI atoms to ensure font fallbacks.

## Extraction Script
- Planned script: `tools/export_strings.gd` → outputs `/i18n/strings.pot`.
- Command example (once implemented):
  ```bash
  $GODOT_BIN --headless --script res://tools/export_strings.gd --output i18n/strings.pot
  ```
- Update localization docs and CI once the script lands.

## References
- [UI Principles](../ux/UI_Principles.md)
- [RM-010 UI Checklist](../qa/RM-010-ui-checklist.md)
- [Developer Handbook](../Developer_Handbook.md)
