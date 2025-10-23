# Directory Conventions & Migration Checklist

This project is standardising around a clearer separation of concerns. Use this guide when adding new code or migrating existing scripts.

## Canonical Layout

- `src/` — runtime scripts and services  
  - Group by domain (`src/economy/`, `src/shop/`, `src/ci/`, `src/services/…`)
- `ui/` — reusable UI scenes/widgets and their scripts  
  - `ui/widgets/`, `ui/hud/`, `ui/panels/`, etc.
- `data/` — TSV/JSON configuration tables not managed by Godot’s importer  
  - `data/balance.tsv`, `data/events.tsv`, `data/buildings/…`
- `game/` — legacy Godot scenes/autoloads; migrate files out as roadmap work progresses

When you create a new feature, prefer the `src/`, `ui/`, and `data/` folders and add subdirectories as needed. Keep related tests or utilities alongside feature code (`src/economy/tests/…`).

## Migration Checklist

1. **Move files**  
   - Use `git mv` or your editor to relocate scripts/scenes from `game/…` into the new folder.
   - Preserve relative namespaces (e.g., `game/scripts/shop/ShopService.gd` → `src/shop/ShopService.gd`).

2. **Update Godot references**  
   - Open `project.godot` and adjust `autoload` paths or script references if they point to the old location.
   - For scenes, fix script attachments via the Godot editor or by editing the `.tscn` file.

3. **Fix imports & preloads**  
   - Search for `preload("res://game/...")` or `load("res://game/...")` and update to the new path (`res://src/...`, `res://ui/...`, `res://data/...`).

4. **Run `--check-only`**  
   - Execute `./tools/check_only.sh` (or `godot4 --headless --check-only project.godot`) to ensure paths resolve and scripts compile.

5. **Update documentation**  
   - Adjust roadmap prompts, README sections, and any developer notes that reference the old path.

6. **Commit with context**  
   - Note the RM/PX in the commit footer and mention the migration in the PR summary so reviewers know to expect path changes.

## Tips

- Migrate code incrementally alongside feature work rather than as a giant repo-wide refactor.
- When moving autoload scripts, verify the order and singleton names remain unchanged.
- If the move introduces breaking changes for branches in progress, coordinate with the owners before merging.

Keeping the layout consistent makes roadmap deliverables predictable and avoids path churn in future specs.
