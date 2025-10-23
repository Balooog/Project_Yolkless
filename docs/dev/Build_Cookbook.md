# Build & Run Cookbook

> Quick commands for contributors to run, test, and gather assets without breaking serenity.

## Daily Workflow
```bash
# Run game with prototype HUD
./tools/run_dev.sh

# Hot reload balance data
# (press R in running client)
```

## Godot CLI
```bash
# Headless simulation (used in telemetry guides)
godot4 --headless --path . --script res://game/scripts/ci/econ_probe.gd --seconds=300

# Export Linux build
./tools/build_linux.sh
```

## Diagnostics
- Press `F3` for debug overlay (tier, PPS, storage, seed).
- `F9` captures screenshots to `logs/screenshots/`.
- Use `Copy Diagnostics` button (prototype Home sheet) for clipboard summary.

## Testing Recipes
- Economy regression: `./tools/headless_tick.sh 300 --strategy=burst`.
- Conveyor stress: enable debug scene `scenes/demo_conveyor.tscn`.

## References
- Contribution flow: [`CONTRIBUTING.md`](../../CONTRIBUTING.md)
- Telemetry instructions: [Telemetry & Replay](../quality/Telemetry_Replay.md)
