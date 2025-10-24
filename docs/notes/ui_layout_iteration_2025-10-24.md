# UI Layout Iteration — 2025-10-24

This session chased the desktop layout for the Prototype HUD (`scenes/prototype/ui_architecture.tscn`).  The changes that survived are already reflected in the scene + `UIArchitecturePrototype.gd`, but the path there was noisy.  Future work should avoid the detours below.

## What Finally Stuck
- Environment rail + sheet anchor trimmed to 220 px defaults; canvas width now computed from design-space units in `_adjust_canvas_width`.
- Root left/right margins are re-balanced after every layout pass so the four UI groups stay separated even when the window is wider than 1280.
- Scene graph includes the top-level HBox separation tweak only (no spacer controls); everything else lives in `UIArchitecturePrototype.gd`.
- Debug logging (`UI layout -> …`) provides quick visibility into the sizing math when testing new resolutions.

## Missteps to Skip Next Time
1. **Mixing window pixels with design width**  
   - I tried to drive breakpoints from `DisplayServer.window_get_size()`, which ignores the project’s `keep_width` stretch.  
   - Result: the layout thought it had ~1350 px when the HUD still renders at 1280, so everything drifted offscreen.  
   - Fix: stick to the design width (`ProjectSettings.display/window/size/viewport_width`) and only adjust via margins.

2. **Overriding root margins directly**  
   - Several passes rewrote `RootMargin` constants in `_adjust_canvas_width`, which made the layout snap back to the default offset at odd times.  
   - The correct fix is to keep base margins stable and only distribute the extra width after the rail/canvas math.

3. **Resizing the environment column ad-hoc**  
   - Cutting the panel widths inside the script while the scene still had 280 px defaults caused double-counted padding.  
   - Always change the source scene (`scenes/prototype/ui_architecture.tscn`) first, then mirror the limits in code.

4. **Variant inference → build breaks**  
   - GDScript with `--warnings-as-errors` treats inferred floats as Variant.  Several iterations failed because locals were untyped.  
   - Prefer explicit `: float` declarations or call `maxf()` to keep everything typed.

5. **Temporary spacer controls**  
   - Inserting `MainSpacerLeft` / `MainSpacerRight` bloated the scene and complicated centering logic.  
   - Removing them and balancing through margins keeps the tree clean and easier to reason about.

## Follow-up Checklist
- Re-run `tools/run_resolutions.sh` once the layout is revisited; keep the debug log around for quick verification.
- If we experiment with stretch modes (`keep` vs `keep_width`), audit every breakpoint doc (RM-010, QA checklist) before landing changes.
- Add visual guides (maybe a debug overlay) earlier when centering UI to avoid guesswork.

Keep this note handy whenever we dive back into the prototype HUD—no need to replay the same mistakes.
