# Save Schema v1

> Defines the JSON payload produced by `Save.gd`. Versioned for forward compatibility to keep calm replays intact.

```json
{
  "save_version": 1,
  "timestamp": "2025-10-24T18:30:00Z",
  "economy": {
    "soft": 245.0,
    "storage": 12.5,
    "capacity": 60.0,
    "pps": 1.15,
    "wisdom": 3,
    "upgrades": {"prod_1": 1, "cap_1": 0}
  },
  "research": {
    "points": 4,
    "owned": ["r_prod_1"]
  },
  "automation": {
    "modes": {"auto_feeder": 2},
    "queue": 0
  },
  "environment": {
    "preset": "temperate",
    "day_fraction": 0.35,
    "ci": 0.72
  },
  "events": {
    "active": null,
    "history": []
  }
}
```

## Fields
- `save_version` (int): Bumps when schema changes. Loader must migrate lower versions forward.
- `economy`: Core loop state; floats in credits/sec with precision ≤0.01.
- `research`: RP pool and unlocked nodes.
- `automation`: Current automation modes (0=off,1=manual,2=auto) and queued bursts.
- `environment`: Snapshot for EnvironmentService to resume curves without jumps.
- `events`: Optional; include active transient event ID when RM-016 lands.

## Migration Policy
1. Loader reads `save_version`. If `< 1`, reject with gentle UX message (beta period only).
2. Future versions append optional fields; never remove existing keys without migration.
3. Prefer additive migrations with defaults instead of destructive rewrites.
4. Document migrations in new ADRs and update this file.

### Migration Process
```
Process:
1) On load, read save_version (default 0).
2) While save_version < CURRENT_VERSION, run migration N→N+1 script from /src/persistence/migrations/.
3) After applying migrations, validate via SaveValidator and persist with CURRENT_VERSION.
Tests:
- /tests/persistence/test_migrations.gd runs fixtures through migration pipeline.
```
- TODO: hook this pipeline into `Save.gd` and add initial migration scripts (see [Architecture Alignment TODO](../architecture/Implementation_TODO.md)).

## Compatibility Notes
- Use `Config.seed` only for deterministic QA; do not persist in save payloads.
- Keep floats within reasonable ranges to avoid JSON bloat; compression handled externally.
- Telemetry replays should ingest save snapshots to reproduce serenity loops; see `/docs/quality/Telemetry_Replay.md`.
