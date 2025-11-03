# Project Yolkless — UI Baseline Layout Spec

> Establishes the reference layout for HUD captures used by `tools/ui_viewport_matrix.sh` and `tools/ui_compare.sh`.

## 1 · Purpose

Provide a deterministic HUD composition so automated screenshot diffs can enforce layout stability. Feature PXs that alter HUD composition must refresh baselines through this matrix.

## 2 · Viewport Matrix

| Layer                    | Anchor                       | Z-Order | Description                                                                                                      |
| ------------------------ | --------------------------- | ------: | ---------------------------------------------------------------------------------------------------------------- |
| **Background World**     | full-screen                 |       0 | Scene render (EnvironmentStage). Mockups may use a blurred crop, but **baseline images must not depend on art**. |
| **UI Root Canvas**       | full-screen                 |       1 | Godot `CanvasLayer 0`. All HUD children attach here.                                                             |
| **HUD Region**           | 32 px margin from top/right |       2 | Persistent stats, meters, icons (e.g., Power, Money, Population).                                                |
| **Alert Region (Toast)** | bottom-center               |       3 | Timed alerts. Hidden in baseline captures.                                                                       |
| **Tooltip Region**       | under active HUD element    |       4 | Context details, auto-wrap 250 px. Hidden in baseline.                                                           |
| **Modal Layer**          | centered                    |       5 | Pause/settings/dialogs; hidden in baseline.                                                                      |
| **FX Overlay**           | full-screen                 |       6 | Global tints/vignettes; disabled in baseline.                                                                    |
| **Cursor/UI Debug**      | n/a                         |       7 | Off in production and baseline.                                                                                  |

## 3 · Baseline Camera & Resolution

| Parameter        | Value                    |
| ---------------- | ------------------------ |
| Resolution       | **1280×720** (16:9)      |
| UI Scale         | **1.00**                 |
| Canvas Transform | Origin (0,0); no zoom    |
| Safe Area        | 32 px horizontal margins, 24 px vertical margins |

Run-time config for automated captures:

```bash
timeout 45s $(bash tools/godot_resolver.sh) --headless --check-only --quit project.godot
```

## 4 · Typography & Color Tokens

| Token                | Value                   | Use              |
| -------------------- | ----------------------- | ---------------- |
| `hud_label_normal`   | #FFFFFFFF               | Default HUD text |
| `hud_label_warning`  | #FFB300FF               | Warning tier     |
| `hud_label_critical` | #FF1744FF               | Critical tier    |
| `toast_bg`           | rgba(0,0,0,0.55)        | Toast backdrop   |
| `tooltip_bg`         | rgba(40,40,40,0.85)     | Tooltip panel    |
| Font                 | “YolkHUD Sans” 12–18 pt | HUD labels       |
| Outline              | 1 px black shadow       | Anti-alias edge  |

## 5 · Toast & Tooltip Layout

- **Toast**: bottom-center; max width 600 px; max height 96 px; 12 px padding; fade 300 ms; hidden in baseline.
- **Tooltip**: attaches to HUD origin + (0, label.height + 6 px); clamps within viewport; hidden in baseline.

## 6 · HUD Grid Template

| Row | Column | Slot | Content                                 |
| --- | :----: | :--: | ---------------------------------------- |
| 1   |   R    |  A   | Power status label + icon                |
| 1   |   R    |  B   | Economy indicator                        |
| 1   |   R    |  C   | Population indicator                     |
| 2   |   C    |  D   | Toast alerts (hidden baseline)           |
| 3   |   C    |  E   | Modal launch buttons (hidden baseline)   |

## 7 · Baseline Files & Folders

```
dev/
  screenshots/
    ui_baseline/
      hud_blank_reference.png
      hud_power_normal.png
      hud_power_warning.png
      hud_power_critical.png
docs/
  ui_baselines/
    README_UI_BASELINE_LAYOUT.md
    ui_matrix.md
```

## 8 · Automated Validation Rules

1. HUD elements remain within the safe-area rectangle.
2. Toast/Tooltip regions are empty (alpha = 0) in baseline captures.
3. Baseline PNG RMS delta must remain ≤ 2 % during CI (`tools/ui_compare.sh`).
4. New HUD elements require a matching baseline PNG before merge.
5. Toast and Tooltip regions remain hidden in baseline.

## 9 · Capture Workflow

```bash
./tools/ui_viewport_matrix.sh --baseline
```

## 10 · Notes

- Baselines are layout contracts, not final art direction.
- HUD realignment requires updating `ui_matrix.md` and regenerating baselines.
- Tokens must match palette dossiers in `ui/theme/Tokens.tres`.
