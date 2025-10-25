# UI Atoms Module

Shared UI components implementing the PX-010 roadmap: banner, tabs, sheets, panels, buttons, labels, and tooltips. These atoms ensure consistent layout, accessibility, and performance across the prototype HUD.

## Purpose
- Provide a reusable library of UI controls wired to token-driven themes.
- Enforce layout guardrails (containers first, safe areas, breakpoints).
- Centralise accessibility features (focus map, tooltip coverage, colour tokens).
- Support automated linting, visual regression, and controller parity.

## Responsibilities
| Area | Details |
| --- | --- |
| Theming | `/ui/theme/Tokens.tres` + `Tokens.gd` define colours, radii, spacing, typography. |
| Layout | `UIHelpers.gd` sets size flags, overflow policy, safe-area padding, breakpoint checks. |
| Components | `TopBanner`, `BottomTabs`, `Sheet`, `Panel`, `UIButton`, `UILabel`, `UITooltip` scenes/scripts. |
| Accessibility | `FocusMap.gd` for controller navigation; tooltips on hover/focus/long-press; UILint scans for issues. |
| Performance | Throttle counters at 5 Hz (PX-010.12), pool list items, avoid per-frame allocations. |
| Automation | Works with `ui_baseline.sh`, `ui_compare.sh`, and UILint to gate regressions. |

## File Map
| Path | Role |
| --- | --- |
| `ui/theme/Tokens.tres` / `Tokens.gd` | Token resource and script exposing accessor functions. |
| `ui/core/UIHelpers.gd` | Helpers for size flags, overflow policy, safe-area padding. |
| `ui/core/FocusMap.gd` | Controller focus graph utilities. |
| `ui/core/UILint.gd` | Runtime lint detecting overflow, missing size flags, unlabeled buttons. |
| `ui/components/TopBanner.*` | Metrics banner atom. |
| `ui/components/BottomTabs.*` | Mobile tab bar. |
| `ui/components/Sheet.*` | Sheet wrapper for tab content. |
| `ui/components/Panel.*` | Tokenised panel container. |
| `ui/components/UIButton.*` | Token-aware button control. |
| `ui/components/UILabel.*` | Token-aware label with overflow policy. |
| `ui/components/Tooltip.*` | Tooltip atom. |

## Layout Rules
- **Containers first:** All atoms expect to sit inside `VBoxContainer`, `HBoxContainer`, `GridContainer`, or `MarginContainer`.
- **Size flags:** Use `UIHelpers.set_fill_expand()`; avoid magic `offset_*`.
- **Breakpoints:** `UIHelpers.within_breakpoint(width, tokens, breakpoint)` (S < 720, M 720–1199, L ≥ 1200). Adjust banner height, sheet docks, tab placement per breakpoint.
- **Safe areas:** Reserve bottom 96 px on mobile, preserve top banner margin via `apply_safe_area`.
- **Overflow policy:** `UIHelpers.ensure_overflow_policy(label, allow_wrap, max_lines)` ensures `clip_text` or `autowrap` + ellipsis.

## Accessibility & Input
- **Focus map:** `FocusMap.gd` registers nodes with directional neighbours; `LB/RB` cycle tabs, `Y` opens Store, `X` opens Research, `RT` triggers feed, `B/Esc` dismisses sheets/dialogs.
- **Contrast:** Token colours chosen for ≥4.5:1 ratio; high contrast themes plug in via tokens.
- **Tooltips:** `UITooltip` anchors away from banner, supports hover, focus, long-press activation.
- **Keyboard & controller parity:** All atoms expose `focus_mode` and signals for navigation hooks.

## Performance Targets
| Metric | Budget | Notes |
| --- | --- | --- |
| UI frame cost (p95) | ≤ 2.5 ms | Aggregate of layout, token application, stat binding. |
| Counter refresh | 5 Hz | Throttle to avoid GC spikes (PX-010.12). |
| GC spikes | < 2 ms | Pool list items, avoid per-frame instancing. |

## Testing & Automation
- **UILint:** Run in dev builds or via `tools/uilint_scene.gd` to catch overflow/missing flags/unlabeled buttons.
- **Visual regression:** Baseline/compare scripts (`ui_baseline.sh`, `ui_viewport_matrix.sh`, `ui_compare.sh`) capture S/M/L breakpoints.
- **Controller pass:** Validate FocusMap coverage using physical or emulated gamepad.
- **Pseudo-localisation:** PX-010.7 adds string expansion; ensure atoms respect overflow policy.

## Signals & Hooks
| Component | Signal | Payload | Description |
| --- | --- | --- | --- |
| `BottomTabs` | `tab_selected(tab_id)` | `StringName` | Routed to `UIArchitecturePrototype` for sheet swaps. |
| `TopBanner` | *(uses data binding)* | — | Metrics labels bound via tokens helpers. |
| `Sheet` | *(content placeholder)* | — | Host for specific panels (Store, Research, etc.). |
| `UILint` | `lint_completed(summary)` | `Dictionary` | Allows tooling to assert zero issues. |

## Cross References
- Roadmap: [RM-010 — UI & Control Architecture](../roadmap/RM-010.md)
- Prompts: [PX-010.3](../prompts/PX-010.3.md) – [PX-010.12](../prompts/PX-010.12.md)
- UI guardrails: [UI Principles](../ux/UI_Principles.md)
- Visual regression: [Build Cookbook](../dev/Build_Cookbook.md), [QA checklist](../qa/RM-010-ui-checklist.md)
- Sandbox integration: [Sandbox module brief](sandbox.md) (shared viewport)
