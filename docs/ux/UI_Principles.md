# UI Principles (RM-010)

> UX guardrails that keep the prototype HUD serene, legible, and consistent across devices.

## Top Banner
- Always surface `Credits`, `Storage`, `PPS`, and `Research` with compact labels.
- Use calm accent colors (`Style_Guide.md`) and avoid flashing animations.
- Alert pill mirrors feed/environment status; limit to one-line messages.

## Feed Controls
- Bottom bar (mobile) and side dock (desktop) must expose the feed button centrally.
- Hold-to-feed uses press/hold/release semantics with 50 ms debounce to prevent jitter.
- Display queue counts (`Feed xN`) without aggressive color changes.

## Sheet Layout
- Mobile: sheets slide from bottom, occupying ≤360 px height to preserve canvas visibility.
- Desktop: sheets dock right inside `CanvasWrapper`; ensure keyboard focus order matches tab order.
- Provide quick hints (CanvasInfo) summarizing interaction patterns.

## Canvas Integration
- Factory/environment visuals render inside the dedicated viewport panel.
- Always maintain ≥16 px padding between canvas edge and UI overlays.
- Zoom/pan gestures should respect calm motion speeds; no sudden jumps.
- Sandbox (environment stage) stays above the conveyor belt so both remain visible across breakpoints.

## Accessibility
- Support text scale presets (100/110/125%).
- Maintain 4.5:1 contrast ratios for buttons and labels.
- All controls require keyboard focus and tooltips.
- Provide color-blind safe palettes (deuteranopia / protanopia); avoid red-green pairings.
- Controller input:
  - D-pad/left stick moves focus between tabs and sheet controls.
  - `A`/Enter activates; `B`/Esc closes sheets; `Y` opens Store; `X` opens Research.
  - Feed action bound to `RT`/Space; sheets must not block feed activation.
- TODO: implement controller navigation and palette swaps (see [Architecture Alignment TODO](../architecture/Implementation_TODO.md)).

## Links
- Architecture context: [Overview](../architecture/Overview.md)
- Art palette: [Style Guide](../art/Style_Guide.md)
