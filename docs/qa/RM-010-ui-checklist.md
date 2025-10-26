# RM-010 UI Regression Checklist

## Smoke
- Load `scenes/prototype/ui_architecture.tscn` and verify all panels render without errors in the Godot editor.
- Switch tabs via bottom bar and confirm the matching sheet becomes visible while others hide.
- Activate Feed button (click + `F`) and ensure the Store sheet opens and the alert pill text updates.
- Run `game/scenes/Main.tscn` and verify the prototype HUD is visible on load while the legacy HUD stays hidden; confirm live metrics continue to update in the prototype banner.
- On desktop width, confirm the Environment panel appears on the right rail, updates phase/weather text, and still allows preset switching and detail toggling.
- Run sandbox renderer path (`Config.env_renderer="sandbox"`) to confirm the viewport replaces the placeholder, Comfort tooltip updates, and StatBus values populate.

## Responsive Behaviour
- Resize viewport to ≤ 600 px: side dock hides, bottom bar remains, sheet anchors to bottom at 360 px height, Environment panel collapses.
- Resize viewport to 601–899 px: confirm bottom bar layout persists and sheet height trims to 320 px while canvas hint reflects touch controls.
- Resize viewport to 900–1279 px: Environment column appears with right-rail sheet (≈240–300 px) while bottom bar stays active.
- Resize viewport to ≥ 1280 px: bottom bar hides, side dock tabs appear, sheet and environment share the right rail with expanded widths.

## Input Mapping
- Keyboard: `1`–`5` change tabs Home→Prestige in order, `F` triggers feed action.
- Gamepad: verify face buttons map per design — `A` activates, `B` backs to Home, `Y` opens Store, `X` opens Research, RT (`feed_hold`) begins bursts. Confirm D-pad moves focus across dock/bottom-bar buttons.
- Gamepad shoulder shortcuts: `LB/RB` cycle tabs (Home→Prestige), ensure cycling preserves focus in the new sheet.
- Focus traversal: cycle forward (`Tab`) and backward (`Shift+Tab`) keeps banner focusable, then tabs, then sheet content.
- Controller-only pass: navigate all sheets, dismiss with `B/Esc`, ensure feed remains on RT/Space; verify focus highlight meets contrast targets from [UI Principles](../ux/UI_Principles.md).

## Accessibility & UX
- Minimum button size remains ≥ 64 px height in all breakpoints (inspect via control gizmos).
- Alert pill retains contrast against banner background (check with Greyscale/Simulate protanopia tools).
- Canvas placeholder remains interactive (mouse/touch) when sheets are hidden.
- Tooltips appear on hover/focus/long-press for truncated labels; confirm they avoid covering the banner.
- Settings palette selector switches between Default, Deuteranopia, and Protanopia friendly palettes; verify progress bars/buttons update immediately.

## Integration Hooks
- Validate exported metrics labels (`CreditsValue`, `StorageValue`, `PpsValue`, `ResearchValue`) remain accessible for data-binding scripts.
- Ensure sheet nodes expose `tab_id` metadata after instancing (inspect with Remote Scene Tree).
- Confirm added input actions are present in `project.godot` after import and do not clobber existing gameplay bindings.
- With the prototype HUD active, verify each sheet mirrors the live button/label text from the underlying systems (credits, storage, store buttons, research queue, automation unlocks, prestige state).

## Telemetry Spot Check
- Run a short replay harness pass to capture comfort metrics: `source .env && $GODOT_BIN --headless --path . --script res://tools/replay_headless.gd --duration=60 --seed=42 --strategy=normal`.
- Confirm the JSON summary reports `sandbox_tick_ms_p95 ≤ 1.9 ms`, `active_cells_max ≤ 400`, and `ci_delta_abs_max ≤ 0.05` after the built-in ~2 s warm-up (StatsProbe ignores early samples automatically). Escalate to engineering if thresholds are exceeded beyond that window.

## Automated Gates
- **UI Baseline Capture/Compare**
  ```bash
  ./tools/ui_baseline.sh                    # refresh baseline if changes approved
  ./tools/ui_viewport_matrix.sh             # capture current S/M/L shots
  ./tools/ui_compare.sh dev/screenshots/ui_baseline dev/screenshots/ui_current
  ```
  Script fails on any pixel delta (threshold TBD). Review differences and attach new PNGs if intentional.
- **UILint**
  ```bash
  $GODOT_BIN --headless --script res://tools/uilint_scene.gd res://scenes/ui_smoke/MainHUD.tscn
  ```
  Ensure summary reports **0** overflow, missing size flags, and unlabeled buttons. Dev build console must also print zero violations.
- **CI Jobs**
  - `ui-baseline-compare` → archives current screenshots and fails on >1 % diff.
  - `ui-lint` → runs scene lint suite; artifacts list offending node paths.
  - `ci-smoke` → wraps `check_only_ci.sh` + replay sanity. Confirm logs attach to PR.

## References
- Runbook: [Build & Run Cookbook](../dev/Build_Cookbook.md)
- UI guardrails & tokens: [UI Principles](../ux/UI_Principles.md)
- Sandbox renderer brief: [Sandbox module](../modules/sandbox.md)
- Visual thresholds: see table below.

## Screenshot & Lint Thresholds

| Metric | Threshold | Artifact |
| --- | --- | --- |
| Pixel Diff | ≤1 % (or approved override) | `ui_diff_report.html` |
| Overflow Violations | 0 | `UILint.txt` |
| Missing Size Flags | 0 | `UILint.txt` |
| Unlabeled Buttons | 0 | `UILint.txt` |
