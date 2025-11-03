# UI Matrix — 1280×720 Layout Contract

> Coordinates are absolute pixels relative to the top-left origin.

## 1 · Global

- **Viewport**: `width=1280`, `height=720`
- **Safe Area**: `left=32`, `right=1248`, `top=24`, `bottom=696`
- **HUD Anchor Right**: `(1248, 24)` (safe-area top-right)

## 2 · Regions

| Region        | Rect (x,y,w,h)         |  Z | Notes                                        |
| ------------- | ---------------------- | -: | -------------------------------------------- |
| HUD Dock      | `(928, 24, 288, 128)`  |  2 | Right column dock for slots A–C.             |
| Toast         | `(340, 624, 600, 72)`  |  3 | Centered bottom; hidden baseline.            |
| Tooltip Clamp | `(32, 24, 1216, 672)`  |  4 | Tooltip bounds.                              |
| Modal         | `(240, 120, 800, 480)` |  5 | Hidden baseline.                             |
| FX Overlay    | `(0, 0, 1280, 720)`    |  6 | Disabled baseline.                           |

## 3 · Slots

| Slot | Name                 | Rect (x,y,w,h)        | Anchor        |  Z | Token                   |
| :--: | -------------------- | --------------------- | ------------- | -: | ----------------------- |
|  A   | Power Status         | `(992, 24, 224, 32)`  | top-right     |  2 | `hud_label_{tier}`      |
|  B   | Economy Indicator    | `(992, 64, 224, 32)`  | top-right     |  2 | `hud_label_normal`      |
|  C   | Population Indicator | `(992, 104, 224, 32)` | top-right     |  2 | `hud_label_normal`      |
|  D   | Center Toast         | `(340, 624, 600, 72)` | bottom-center |  3 | `toast_bg` (hidden)     |
|  E   | Modal Buttons Row    | `(440, 560, 400, 48)` | bottom-center |  5 | Hidden baseline         |

Spacing between stacked HUD rows (A→B→C) is 8 px. Text is right-aligned to slot bounds.

## 4 · Typography

- **Font**: YolkHUD Sans, 14 pt regular (critical may use 15 pt semibold)
- **Shadow**: 1 px black @ 60 % opacity
- **Line-Height**: 1.25× font-size

## 5 · Color Tokens

```yaml
colors:
  hud_label_normal:    "#FFFFFFFF"
  hud_label_warning:   "#FFB300FF"
  hud_label_critical:  "#FF1744FF"
  toast_bg:            "rgba(0,0,0,0.55)"
  tooltip_bg:          "rgba(40,40,40,0.85)"
```

## 6 · JSON Contract

```json
{
  "viewport": { "w": 1280, "h": 720 },
  "safe_area": { "left": 32, "top": 24, "right": 1248, "bottom": 696 },
  "regions": {
    "hud_dock": { "x": 928, "y": 24, "w": 288, "h": 128, "z": 2 },
    "toast":    { "x": 340, "y": 624, "w": 600, "h": 72,  "z": 3 },
    "tooltip":  { "x": 32,  "y": 24,  "w": 1216,"h": 672, "z": 4 },
    "modal":    { "x": 240, "y": 120, "w": 800, "h": 480, "z": 5 },
    "fx":       { "x": 0,   "y": 0,   "w": 1280,"h": 720, "z": 6 }
  },
  "slots": {
    "A": { "name": "power",     "x": 992, "y": 24,  "w": 224, "h": 32,  "anchor": "tr", "z": 2 },
    "B": { "name": "economy",   "x": 992, "y": 64,  "w": 224, "h": 32,  "anchor": "tr", "z": 2 },
    "C": { "name": "population","x": 992, "y": 104, "w": 224, "h": 32,  "anchor": "tr", "z": 2 },
    "D": { "name": "toast",     "x": 340, "y": 624, "w": 600, "h": 72,  "anchor": "bc", "z": 3 },
    "E": { "name": "modal_row", "x": 440, "y": 560, "w": 400, "h": 48,  "anchor": "bc", "z": 5 }
  },
  "tokens": {
    "font": { "family": "YolkHUD Sans", "size": 14, "shadow": { "px": 1, "alpha": 0.6 } },
    "colors": {
      "hud_label_normal":   "#FFFFFFFF",
      "hud_label_warning":  "#FFB300FF",
      "hud_label_critical": "#FF1744FF",
      "toast_bg":           "rgba(0,0,0,0.55)",
      "tooltip_bg":         "rgba(40,40,40,0.85)"
    }
  }
}
```

## 7 · Acceptance Checks

- **A1**: Slot rects remain inside the safe area.
- **A2**: Toast/Tooltip regions are empty in baseline imagery.
- **A3**: Baseline PNG RMS delta ≤ 2 % (`tools/ui_compare.sh`).
- **A4**: New HUD elements require slot definition + baseline PNG.

## 8 · Maintenance

- Update this file and regenerate baselines when positions change.
- Keep integer coordinates to avoid sub-pixel jitter.
