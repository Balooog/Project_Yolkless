# RM-010 UI Regression Checklist

## Smoke
- Load `scenes/prototype/ui_architecture.tscn` and verify all panels render without errors in the Godot editor.
- Switch tabs via bottom bar and confirm the matching sheet becomes visible while others hide.
- Activate Feed button (click + `F`) and ensure the Store sheet opens and the alert pill text updates.
- Run `game/scenes/Main.tscn` and verify the prototype HUD is visible on load while the legacy HUD stays hidden; confirm live metrics continue to update in the prototype banner.
- On desktop width, confirm the Environment panel appears on the right rail, updates phase/weather text, and still allows preset switching and detail toggling.

## Responsive Behaviour
- Resize viewport to ≤ 640 px: side dock hides, bottom bar remains, sheet anchors to bottom with 360 px height.
- Resize viewport to 641–899 px: sheet height adjusts to 320 px and canvas hint updates to tablet messaging.
- Resize viewport to ≥ 900 px: bottom bar hides, side dock appears, sheet moves to right edge with 320 px width.

## Input Mapping
- Keyboard: `1`–`5` change tabs Home→Prestige in order, `F` triggers feed action.
- Gamepad: any mapped face button triggers the first available tab (placeholder) without errors; confirm no crashes if unmapped.
- Focus traversal: cycle forward (`Tab`) and backward (`Shift+Tab`) keeps banner focusable, then tabs, then sheet content.

## Accessibility & UX
- Minimum button size remains ≥ 64 px height in all breakpoints (inspect via control gizmos).
- Alert pill retains contrast against banner background (check with Greyscale/Simulate protanopia tools).
- Canvas placeholder remains interactive (mouse/touch) when sheets are hidden.

## Integration Hooks
- Validate exported metrics labels (`CreditsValue`, `StorageValue`, `PpsValue`, `ResearchValue`) remain accessible for data-binding scripts.
- Ensure sheet nodes expose `tab_id` metadata after instancing (inspect with Remote Scene Tree).
- Confirm added input actions are present in `project.godot` after import and do not clobber existing gameplay bindings.
- With the prototype HUD active, verify each sheet mirrors the live button/label text from the underlying systems (credits, storage, store buttons, research queue, automation unlocks, prestige state).
