# UX Principles

## Comfort-First Surfaces
- Always expose the Comfort Index, Egg Credits, and queue health in the top HUD (`scenes/ui_smoke/MainHUD.tscn`).
- Use warm, legible color tokens from `ui/theme/Tokens.tres`; avoid introducing custom palettes without art approval.

## Guided Experimentation
- Reinforce hotkeys and debug tools (`F3`, `R`, Ship Now) in tooltips and quickstarts so players feel safe iterating.
- Prefer progressive disclosure—show depth (automation, research) only after the player completes early shipments.

## Responsive Layouts
- Resize UI through `SubViewportContainer` best practices documented in `docs/dev/build_gotchas.md`; disable `stretch` in `_ready()` before custom sizing.
- Reuse UI atoms from `ui/components/` to preserve spacing, padding, and haptic patterns across screens.

## Honest Feedback
- Pair every automated action with log or overlay feedback (`logs/yolkless.log`, debug overlay) and keep error copy actionable.
- Mirror telemetry names between StatBus metrics and on-screen labels to reduce translation errors during LiveOps.
