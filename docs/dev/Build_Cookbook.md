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
# Launch editor or run scene
godot --path . --editor

# Headless telemetry replay (Linux/WSL)
godot --headless --path . --script res://tools/replay_headless.gd --duration=300 --seed=12345

# Export debug build
godot --export-debug "Linux/X11" build/yolkless-debug.x86_64
```

## Diagnostics
- Press `F3` for debug overlay (tier, PPS, storage, seed).
- `F9` captures screenshots to `logs/screenshots/`.
- Use `Copy Diagnostics` button (prototype Home sheet) for clipboard summary.

## Testing Recipes
- Economy regression: `godot --headless --path . --script res://game/scripts/ci/econ_probe.gd --seconds=300`.
- Conveyor stress: open `scenes/demo_conveyor.tscn` in-editor and run.
- TODO: replace `ci/econ_probe.gd` usage with `tools/replay_headless.gd` once implemented (see [Architecture Alignment TODO](../architecture/Implementation_TODO.md)).

## References
- Contribution flow: [`CONTRIBUTING.md`](../../CONTRIBUTING.md)
- Telemetry instructions: [Telemetry & Replay](../quality/Telemetry_Replay.md)
