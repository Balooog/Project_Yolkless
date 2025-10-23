# Style Guide

> Visual tone for comfort-idle gameplay: warm, calm, and readable.

## Palette
| Token | Hex | Usage |
| ----- | --- | ----- |
| `bg_dawn` | `#2F3540` | Night backdrop, low-light panels. |
| `bg_day` | `#3E4A5C` | Daytime canvas background. |
| `accent_warm` | `#E3B341` | Feed highlights, alert pill text. |
| `accent_cool` | `#7FC8F8` | Comfort tooltips, environment highlights. |
| `success_soft` | `#4FB477` | Shipment confirmation pulses. |
| `warning_soft` | `#F3A25B` | Gentle alerts (power dip). |

- Palette export script: `./tools/export_palette.gd` reads `/data/materials.tsv` and writes `/art/palettes/cozy_palette.png` and JSON metadata.
- Asset token naming: `mat_<id>_<tier>.png` sourced from `materials.tsv`; keep palettes in sync before committing art.
- TODO: implement palette export tooling and source data (see [Architecture Alignment TODO](../architecture/Implementation_TODO.md)).

## Lighting Curves
- Day/night transitions over 6–8 minutes, easing in/out with cubic curves.
- Peak brightness limited to 0.85 gamma to avoid harsh glare.
- Night scenes retain silhouette visibility (min 0.35 luminance).

## Particles & VFX
- Feed particles: max 64 instances, velocity 120 px/s, fade within 0.6 s.
- Weather overlays: use low alpha (<0.25) and slow drift speeds.
- Comfort blooms should be subtle pulses, not flashing bursts.

## Audio Layering
- Base ambience loop (coop noises) at -18 dB.
- Add wind/bird layers when Comfort Index >0.6.
- Feed button SFX: soft granular pour, -12 dB base volume.

## Typography
- Primary font: open-source rounded sans (e.g., Nunito). Sizes 18–22 for HUD.
- Use uppercase sparingly; prefer sentence case for serenity.

## References
- UI ergonomics: [UI Principles](../ux/UI_Principles.md)
- Environment tuning: [Environment Playbook](../design/Environment_Playbook.md)
