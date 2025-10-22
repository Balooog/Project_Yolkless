# Project Yolkless — Art & Audio Policy

## Licensing & Ownership

- **Code:** MIT License (existing project license).
- **Art & Audio Placeholders:** © Project Yolkless. These temporary assets ship only with the repository build and are not licensed for redistribution outside of this project.
- **No AI-Generated Assets:** All visual and audio content must be hand-crafted or procedurally generated. Automated AI synthesis is not permitted for any deliverable.

## Source Requirements

- Provide layered or editable sources for every committed asset:
  - Vector artwork as `.svg`.
  - Pixel artwork and animations as Aseprite `.ase` files.
  - Procedural assets should document their generator script.
- Include attribution inside `docs/ART_POLICY.md` (below) for any third-party CC0 material, even if used as reference.

## Placeholder vs Final Assets

- Temporary placeholders live in `res://assets/placeholder/`.
- Production-ready replacements belong in `res://assets/final/`.
- Logical asset keys map to resource files in `assets/AssetMap.json`. Swap a placeholder by dropping the final asset under `assets/final/` and updating the JSON entry—no code changes required.

```
res://assets/
  ├── placeholder/   # Hand-made or procedural stand-ins
  ├── final/         # Approved production art/audio
  └── AssetMap.json  # Logical key → resource path
```

## Replacement Workflow

1. Create or update the high-resolution source (SVG/Aseprite/etc.).
2. Export a Godot-ready resource into `assets/final/`.
3. Update the relevant key in `assets/AssetMap.json` to point at the new file.
4. Verify in-game (hot reload or restart) that the art loads without code edits.

## Accessibility Palette

All UI placeholders adhere to a WCAG AA-compliant palette:

| Role | Hex |
| ---- | ---- |
| Background | `#2E2E2E` |
| Panel | `#3A3A3A` |
| Text | `#F2F2F2` |
| Accent | `#E3B341` |

Designers may expand the palette as long as contrast targets are met.

## Attribution Log

*(Add entries here when third-party CC0 resources are introduced.)*
