# UI Principles (RM-010)

> UX guardrails that keep the prototype HUD serene, legible, and consistent across devices.

## Top Banner
- Always surface `Credits`, `Storage`, `PPS`, and `Research` with compact labels.
- Use calm accent colors (`Style_Guide.md`) and avoid flashing animations.
- Alert pill mirrors feed/environment status; limit to one-line messages.
- Banner height locked via token table; never allow other elements to overlap or occlude it.
- Tooltips must expose full metric values on hover, focus, or long-press.

## Token System
- All UI colours, radii, spacing, and font sizes originate from `/ui/theme/Tokens.tres`.
- Typography tokens (logical px):
  - XS = 11, S = 13, M = 15, L = 18, XL = 22, XXL = 28.
- Apply tokens through `UIHelpers.apply_label_tokens` / `UIButton` / `UILabel` components; inline hex codes are prohibited.

## Breakpoint Table
- **S (mobile):** width < 720 — bottom tab bar, safe-area reserve 96 px.
- **M (tablet):** 720 ≤ width ≤ 1199 — hybrid layout, optional side dock.
- **L (desktop):** width ≥ 1200 — right-docked sheets, side dock tabs, banner expands to 112 px.
- Use `UIHelpers.within_breakpoint()` in layout scripts to adjust spacing and sheet anchoring.

## Overflow & Ellipsis Policy
- Every single-line label sets `clip_text=true` and `ellipsis=true`.
- Multi-line content uses `autowrap_mode=WORD_SMART`, `max_lines`, and ellipsis to prevent bleed.
- UILint reports overflow offences; PX-010.7 pseudo-localisation expands strings by 30% to catch regressions.
- Tooltips provide full-text fallbacks for any truncated label.

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
- Provide a serene **View Toggle** between Diorama and Map modes:
  - Toggle button sits in the sandbox header (`View: Diorama ▸ Map`).
  - Auto-idle drift to Map after 5 minutes of inactivity; any interaction returns to Diorama with a soft fade.
  - Prestige transition pans from Diorama to Map, then fades into the next era assets.
  - Both views must surface Comfort tooltip (+X.XX %) and era/map legends.
  - Swap completes in ≤100 ms and must not reset the CA sim, conveyor overlay, or EnvPanel bindings.
- Map view uses a fixed CI/PPS legend or heatmap palette visible across breakpoints; Diorama continues to apply era LUTs and prop palettes.
- CI tint normalization stays aligned between Map legend bands and Diorama LUT thresholds for each era.
- **Conveyor overlay feedback**: belt scroll accelerates within 150 ms on feed hold, decays within 300 ms on release, and pulses warmly on shipments; apply EMA tinting from Comfort Index so transitions stay calm.
- Mirror conveyor sound and tint to match Sandbox palette per era; never allow bursts to exceed the calm motion thresholds above.

## Accessibility
- Support text scale presets (100/110/125%).
- Maintain 4.5:1 contrast ratios for buttons and labels.
- All controls require keyboard focus and tooltips.
- Provide color-blind safe palettes (deuteranopia / protanopia); avoid red-green pairings.
- Controller focus map (PX-010.8) defines deterministic traversal:
  - Banner → Dock/Tabs → Sheet controls → Canvas → Feed button (wrap).
  - `LB/RB` cycle tabs, `Y` opens Store, `X` opens Research, `RT` triggers feed, `B`/`Esc` dismiss sheets/dialogs.
- UILint must pass with zero overflow, missing size flags, or unlabeled buttons across S/M/L breakpoints.
- Controller input:
  - D-pad/left stick moves focus between tabs and sheet controls.
  - `A`/Enter activates; `B`/Esc closes sheets; `Y` opens Store; `X` opens Research.
  - Feed action bound to `RT`/Space; sheets must not block feed activation.
- Controller navigation is handled via `FocusMap` (LB/RB cycling, RT feed) and Settings exposes color-blind palettes.
- Global **Reduce Motion** flag persists via `Config.gd`; UI, Sandbox, Conveyor, and Map layers must halve burst speed, disable speedlines/camera pan, and retain legible tint cues when enabled.

## Links
- Architecture context: [Overview](../architecture/Overview.md)
- Art palette: [Style Guide](../art/Style_Guide.md)
