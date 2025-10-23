# Service & Autoload Topology

This document captures the current (and target) layout of global services so engineers know which singletons exist, their load order, and key dependencies. Update it whenever autoloads move from `game/` into `src/`.

## Autoload Order (Godot `project.godot`)

The current project defines the following singletons (top to bottom):

1. `Config` — runtime flags (`logging_enabled`, seeds, diagnostics toggles)
2. `Balance` — parsed balance tables (hot-reloadable TSVs)
3. `Economy` — core production, storage, and upgrade state
4. `Research` — research points, unlock status
5. `Save` — persistence wrapper (load/save/reset)
6. `YolkLogger` — structured logging queue/flush
7. `StringsCatalog` — localized UI strings
8. `VisualDirector` — lightweight visual effects (feed particles)

## Target Migration

As modules move into `src/`, migrate their scripts and adjust the autoload path accordingly:

- `Economy.gd` → `src/economy/Economy.gd`
- `Research.gd` → `src/research/Research.gd`
- `Save.gd` → `src/save/Save.gd`
- `YolkLogger.gd` → `src/logging/YolkLogger.gd`
- `VisualDirector.gd` → `src/visuals/VisualDirector.gd`
- Future services: `EnvironmentService.gd`, `AutomationService.gd`, `PowerService.gd`

Keep the autoload names identical so existing code does not break; only the path changes.

## Dependency Notes

- `Economy` depends on `Balance` and `Research` (`setup(balance, research)`).
- `Research` pulls data from `Balance` for unlock definitions.
- `Save` reads/writes state for `Economy`, `Research`, `Balance`.
- `YolkLogger` is used by all services; ensure it loads before downstream singletons emit logs.
- `EnvironmentService` (RM-021) will observe `Economy` and `PowerService`, then emit updates consumed by UI and `VisualDirector`.
- `AutomationService` (RM-013) will coordinate `Economy`, `PowerService`, and factory modules.
- `PowerService` (RM-018) should load after `Economy` so it can subscribe to building state changes.

## Actions When Adding/Migrating a Service

1. Move the script into `src/<domain>/ServiceName.gd`.
2. Update `project.godot` autoload path to the new location.
3. Ensure `_ready()` or `setup()` calls respect dependency order (use `await`/`call_deferred` if needed).
4. Run `./tools/check_only.sh` to validate the project after path changes.
5. Update this document and any relevant roadmap prompts to reference the new path.
