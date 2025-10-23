# Data Catalog

This directory houses authored TSV/JSON files that feed the game’s balance, events, and narrative systems. Keep schemas documented here so designers know what to edit and engineers can validate migrations.

## Files & Owners

- `balance.tsv` — Economy constants, upgrade tables, factory tiers, automation, research, prestige.  
  - **Owner:** Economy Design (RM-011, RM-012)  
  - **Reload:** Press `R` in-game or call `Balance.load_balance()`.

- `strings_egg.tsv` (to be migrated) — Player-facing copy.  
  - **Owner:** Narrative/UI  
  - **Reload:** Press `R` (strings + balance).

- `strings_prestige.tsv` — Prestige-specific copy (RM-015).  
  - **Owner:** Progression Design  
  - **Reload:** `StringsCatalog.reload()` (hooked to `R` once migrated).

- `events.tsv` — Event scheduler configuration (RM-016).  
  - **Owner:** Systems Design  
  - **Reload:** Planned hot-reload via `EventDirector.reload_config()`.

- `environment_curves.tsv` — Temperature, light, humidity, air-quality curves (RM-021).  
  - **Owner:** World Atmosphere Team  
  - **Reload:** `EnvironmentService.reload_curves()` (to implement).

- `buildings/` — Building blueprint definitions for factory layout (RM-019).  
  - **Owner:** Factory Systems  
  - **Reload:** via `FactoryGrid.reload_blueprints()` (future work).

## Editing Guidelines

- TSV files use tabs as separators; keep headers in ALL_CAPS for constants or camelCase for field names.
- Document new columns in this README and in relevant roadmap prompts.
- Run `./tools/check_only.sh` after edits to ensure parsers still work.
- For large changes, provide sample diffs or before/after plots in `docs/notes/`.
