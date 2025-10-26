# Conveyor Belt Visual Module

The conveyor module simulates item flow for automation set pieces. It pairs on-screen feedback (moving sprites with scroll effects) with throughput tracking that other systems can consume. Coordinate visual pacing with the [Sandbox viewport](sandbox.md) so factory motion and comfort visuals stay harmonised.
Tune belt speeds, easing, and FX against the comfort-idle guardrails in `docs/analysis/IdleGameComparative.md` so the visual loop stays relaxing.

## Components

| Script | Role |
| --- | --- |
| `ConveyorBelt.gd` | Owns the path, segment definitions, and item slots. Handles motion, queueing, and belt visuals. |
| `ConveyorItem.gd` | Lightweight `Node2D` for discrete items travelling along the belt. Stores metadata and draws itself. |
| `ConveyorManager.gd` | Oversees one or more belts, spawns items, aggregates metrics, and emits integration signals. Pools up to 600 items by default so telemetry stays within the comfort budget. |

### Key Signals

- `item_spawned(item_id)` — fired whenever a new item enters the system.
- `item_delivered(item_id, destination)` — sent after an item exits a belt. Hook this into downstream stations.
- `throughput_updated(rate, queue_len)` — broadcast each frame with smoothed items-per-second and queued item count.

## Belt Segments

Call `ConveyorBelt.configure_segments([...])` with dictionaries that describe each run:

```gdscript
belt.configure_segments([
	{ "length": 220.0, "speed": 85.0, "capacity": 8 },
	{ "length": 160.0, "speed": 70.0, "capacity": 5 },
	{ "length": 140.0, "speed": 65.0, "capacity": 3 }
])
```

- `length` — distance in pixels along the baked path.
- `speed` — per-segment PPS; items always respect the slowest of their own speed and segment speed.
- `capacity` — maximum concurrent items per segment (`0` = unlimited).
- `direction` (optional) — `1` (default) or `-1` for future loops.

Segments can be mixed with a `Path2D` spline for visual variation. The stripe renderer scrolls based on average segment speed.

## Spawning & Delivery

Use the manager as the entry point:

```gdscript
var item := manager.spawn_item(&"egg", belt_reference)
if item:
	item.set_tint(Color.hex(0xf7e9a5ff))
```

Set an optional delivery callback via `set_delivery_target(callable)` to hand items off to packagers or storage.

The manager tracks live throughput and exposes `average_travel_time` for dashboards. Every few seconds a log is queued through `YolkLogger` under the `CONVEYOR` category.

## Demo Scene

`res://scenes/demo_conveyor.tscn` wires a belt, timer-driven spawner, and HUD label so designers can inspect queueing and flow rates headlessly. Launch with the usual development run, or instance it inside the main scene for quick smoke validation.

## Main Scene Integration

- The primary game scene instantiates `game/scenes/modules/conveyor/FactoryConveyor.tscn`, which registers its belt with the shared `ConveyorManager`.
- `Main.gd` spawns conveyor items in proportion to `eco.current_pps()`, so visual flow mirrors production rate while keeping metrics in sync with the HUD.
- Toggling the Visual Effects setting hides the belt and clears spawned items; conveyors resume once visuals are re-enabled.

## 2025-10-25 Benchmark Snapshot

Automated telemetry (`$GODOT_BIN --headless --script res://tools/replay_headless.gd --duration=20 --seed=42 --strategy=normal`) surfaced the following:

- `sandbox_tick_ms_p95`: **10.6 ms** (budget ≤2.0 ms). Most of the time is spent in the sandbox/conveyor co-simulation. Profile the CA step and conveyor update loop to identify hotspots.
- `active_cells_max`: **≈243** conveyor/sandbox cells (target ≤500 pooled tokens). Current pooling keeps the population in check; re-validate after adding new belt content.
- `pps_avg`: **≈0.94 credits/s**, matching the balance playbook baseline—no output drift detected.

**Next steps**

1. Cap conveyor token population (or reuse inactive tokens) so StatsProbe never reports more than ~500 active cells.
2. Batch the sandbox/conveyor update or reduce tick cadence to bring `sandbox_tick_ms_p95` back within the 2 ms budget.
3. Capture a Godot-profiler trace on Steam Deck + desktop after the fixes and log the results in this file for future comparisons.
