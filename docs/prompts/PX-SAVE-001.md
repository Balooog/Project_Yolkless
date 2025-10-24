# PX-SAVE-001 — Save Version Migration System
**Targets:** SaveSchema_v1 / Data Persistence  
**Date:** 2025-10-24  
**Outcome:** Planned  

## Scope
Introduce a formal migration pipeline for save files so future schema changes can be rolled out safely, with tests and tooling to validate conversions.

## Objectives
1. Implement `/src/persistence/MigrationManager.gd` that loads `save_version`, runs sequential migrations, and updates the version field.  
2. Define migration script format (e.g., `res://src/persistence/migrations/###_to_###.gd` with `apply(data: Dictionary) -> Dictionary`).  
3. Add initial stub migration `000_to_001.gd` (no-op) and sanity-check logging.  
4. Update `Save.gd` to call `MigrationManager` during load before populating Economy/Research.  
5. Add `/tests/persistence/test_migrations.gd` with fixtures covering legacy payloads.  
6. Document migration workflow in `docs/data/SaveSchema_v1.md`.  

## Deliverables
- `/src/persistence/MigrationManager.gd` + migration scripts.  
- `/tests/persistence/test_migrations.gd`.  
- Updated docs: `SaveSchema_v1.md`, `Implementation_TODO.md`.  

## Validation
- Legacy v0 payload upgrades to v1 without data loss (credits, upgrades, research).  
- Failed migration triggers warning log but does not crash loader.  
- Test suite covers forward/backwards compatibility scenarios.  
- Save file written with new `save_version` and hash.  
