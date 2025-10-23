# RM-010 Wireframes — UI & Control Architecture

## Overview
These notes capture the reference wireframes that back the prototype scene `scenes/prototype/ui_architecture.tscn`. They document structural groupings, responsive breakpoints, and control affordances for mobile-first play with desktop parity. The live project now boots with this HUD by default, keeping the legacy HUD hidden in the scene tree for fallback.

## Shared Layout Tokens
- **Banner height:** 96 px base, scales to 112 px at ≥1280 px width.
- **Canvas padding:** 24 px margin from viewport edges to preserve gesture gutters.
- **Sheet radius:** 12 px corner rounding for overlay panels (applied in theme pass).
- **Tab hit target:** 96 px width, 64 px height minimum (meets 48 px WCAG target).

## Portrait (≤ 640 px width)
```
┌─────────────────────────────────────────┐
│ Top Banner                              │
│ ├ Credits ─ Storage ─ PPS ─ Research ─ ⚠ │
└┬───────────────────────────────────────┬┘
 │                                       │
 │           Factory Canvas              │
 │     (feed gestures & overlays)        │
 │                                       │
 └───────────────────────────────────────┘
 ┌───────────────────────────────────────┐
 │ Bottom Tabs: Home · Store · Feed · …  │
 └┬──────────────────────────────────────┘
  │ Slide-up Sheet (active tab)          │
  │ Content scrolls while banner stays   │
  └──────────────────────────────────────┘
```
- Feed button remains centered; quick tap toggles `Store` sheet.
- Sheet overlay consumes lower 360 px, leaving canvas touch area exposed.

## Tablet (641–899 px width)
```
┌────────────────────────────────────────────────┐
│ Banner with expanded spacing                   │
├────────────────────────────────────────────────┤
│ Factory Canvas (left focus)                    │
│ ┌────────────────────────────────────────────┐ │
│ │ Bottom sheet floats at 320 px height       │ │
│ └────────────────────────────────────────────┘ │
├────────────────────────────────────────────────┤
│ Tabs compress to 88 px min width; feed stays │
│ centered with left/right flexible spacers    │
└────────────────────────────────────────────────┘
```
- Hotkeys mirror mobile order (1–5). Controller navigation cycles left-to-right.
- Sheet overlay remains bottom-docked but reveals more context above fold.
- Environment panel stays hidden on portrait mobile and slides back in from the right rail once the tablet breakpoint is reached.

## Desktop (≥ 900 px width)
```
┌────────────────────────────────────────────────────────────┐
│ Metrics Banner + Alert pill                                │
├───────────────┬────────────────────────────────────────────┤
│ Side Dock     │ Factory Canvas                             │
│ Home   [1]    │                                            │
│ Store  [2]    │ ┌────────────────────────────────────────┐ │
│ Research [3]  │ │ Right-docked sheet for active tab      │ │
│ Automation[4] │ │ (hotkeys + click selection)            │ │
│ Prestige [5]  │ └────────────────────────────────────────┘ │
├────────────────────────────────────────────────────────────┤
│ Bottom bar hidden; dock owns focus order                   │
└────────────────────────────────────────────────────────────┘
```
- Sheet repositions to the right edge (320 px min width) to free canvas for zoom/inspect.
- Environment panel docks along the far-right column, exposing phase/weather summary and preset selector without covering the canvas.
- Feed quick action remains available through `F` hotkey and future HUD icon.

## Interaction Notes
1. **Focus order:** Banner -> Dock/Bottom tabs -> Sheet controls -> Canvas (wrap).
2. **Controller mapping:** D-pad / left stick navigates dock; `A`/`Space` activates; `B` triggers sheet dismiss (implemented later).
3. **Accessibility:** Alert pill reserves high-contrast palette; fonts scale with project dynamic font tokens.

## Next Design Tasks
- Capture final art direction variants (day/night themes) once RM-020 assets land.
- Produce click-through prototype for tutorial overlays leveraging this scaffold.
- Validate localization expansion (longer strings) against layout padding.
