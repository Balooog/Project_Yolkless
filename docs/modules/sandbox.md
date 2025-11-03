# Sandbox Viewport Module

The sandbox renderer visualises the Comfort Index cellular automata (CA) grid, translating environment factors into a serene viewport while feeding Metrics and StatBus telemetry.

## Purpose
- Render the sandbox CA grid (target 128×72 logical cells) inside the prototype HUD viewport.
- Map EnvironmentService factors (temperature, humidity, light) to colour/tone.
- Publish Comfort Index (`ci`, `ci_bonus`) to StatBus/Economy and expose metrics to UI.
- Provide deterministic frames for telemetry, visual regression, and future GPU experiments.

## Responsibilities
| Area | Details |
| --- | --- |
| Rendering | Diorama: layered backgrounds, sprites, parallax. Map: shader/palette projection of CA cells. |
| Simulation bridge | Pull snapshots from `SandboxService.current_snapshot()`, respect shared smoothing/skip cadence. |
| Performance | Logic ≤ 2 ms, render ≤ 1 ms; auto lowers draw cadence when p95 >18 ms for 5 s. |
| Telemetry | Emit StatsProbe metrics (`sandbox_render_ms_avg`, `sandbox_render_ms_p95`) plus active view mode. |
| Integration | Replace legacy `EnvironmentRoot` when `Config.env_renderer == "sandbox"`; host Diorama⇄Map toggle; expose comfort tooltip data via EnvPanel. |

## Conveyor Overlay Layer
- Adds a `ConveyorOverlay` node above the sandbox viewport to render scrolling belts, crates, and comfort-tint accents.
- Drives belt speed and tint from feed interaction signals (`feed_hold_started()`, `feed_hold_ended()`, `feed_burst(mult)`) and Comfort Index smoothing.
- Responds to `shipment_triggered()` pulses for auto-dump flashes and subtle camera nudges without mutating the simulation buffers.
- Clamps speed ≤ 2.5× baseline regardless of PPS or Wisdom multipliers, debounces shipment pulses to ≥ 400 ms, and keeps CA tick independent from visual cadence.
- Power ratio only affects tint (cooler when `power_ratio<1.0`, warmer on surplus); animation speed remains linked to PPS and burst state.
- Sends timing metrics (`belt_anim_ms_avg`, `belt_anim_ms_p95`) to StatBus/telemetry and honours `Settings.reduce_sandbox_motion` by halving burst intensity, disabling speedlines/micro-pan, and respecting accessibility palettes.
- Shares sprite palettes with era assets (`art/conveyor/`) so Diorama evolution remains cohesive across eras and mirrors Sandbox palette swaps.

## Inputs
- `EnvironmentService.environment_updated(state: Dictionary)` — drives tone/colour adjustments.
- `SandboxService.get_front_buffer()` / `SandboxService.ci_changed(ci, bonus)` — supply CA grid data + metrics.
- Config: `Config.env_renderer` flag and `data/environment_config.json` smoothing parameters.

## Outputs
- `ci_changed(ci: float, bonus: float)` — forwarded from SandboxService to StatBus/Economy/UI.
- StatsProbe stream (1 Hz) capturing render timing, upload counts, dirty pixel averages.
- UI hooks for EnvPanel (`Comfort +X.XX %` tooltip) and sandbox debug overlays.

## View Modes & Guardrails
- Diorama and Map views share the same CA front buffer; toggling the view swaps presentation only and must complete ≤ 100 ms without touching sim cadence.
- Diorama uses era-specific LUTs, props, and conveyor accents; Map view uses a fixed legend/heatmap palette with an always-visible CI/PPS legend.
- CI ranges are normalized per era so tint thresholds line up between Diorama props and Map legend.
- When `Config.reduce_sandbox_motion` is enabled, both views disable camera pan/drift, halve burst-linked motion, and keep tint changes low-frequency.

## Mini-Game Interaction Constraints
- Mini-games (future RM-0XX) never touch Credits/RP directly; any bonus routes through the Reputation reward channel documented in the Balance Playbook.
- While a mini-game is active, Sandbox visualization (Diorama + Conveyor overlay) ticks visuals at ¼ speed for calmness while the core CA simulation continues at the standard cadence to preserve determinism.
- Telemetry records `minigame_active` and `minigame_duration` alongside render metrics so throttled sessions remain traceable.

## Performance Targets
| Metric | Budget | Notes |
| --- | --- | --- |
| Sandbox logic tick | ≤ 2 ms | Maintained by `SandboxService`. |
| Sandbox render | ≤ 1 ms | Renderer updates & uploads. |
| Frame p95 threshold | 18 ms | Trigger half-rate render fallback until stable. |
| Active cells | ≤ 400 | Mirrors CA budget; track via StatsProbe. |

### Simulation Cadence
- `SandboxService` keeps the CA grid warm between environment presets; density relax trims active cells toward ~22 % when they exceed 27 % to stay under the 2 ms budget without reseeding.
- `SandboxGrid` advances the automata in three interleaved phases (one third of the cells per tick, scaled by delta) so the visual state remains fluid while reducing per-tick cost.
- Plant growth becomes self-thinning under high density, and fire spread samples a reduced neighbourhood set; both changes tame runaway activity while preserving variety.
- Replay validation target: `replay_2025-10-27_020546.json` (seed 42) reports `sandbox_tick_ms_p95 ≈ 1.06 ms`, no sandbox alerts, with only a single environment tick spike (0.52 ms) to monitor.

## File Map
| Path | Role |
| --- | --- |
| `scenes/sandbox/SandboxCanvas.tscn` | Diorama viewport host (SubViewportContainer). |
| `game/scenes/modules/environment/EnvironmentStage_Backyard.tscn` | Era 1 placeholder (backyard coop). |
| `game/scenes/modules/environment/EnvironmentStage_SmallFarm.tscn` | Era 2 placeholder (small farm). |
| `game/scenes/modules/environment/EnvironmentStage_Industrial.tscn` | Era 3 placeholder (industrial plant). |
| `game/scenes/modules/environment/EnvironmentStage_EcoRevival.tscn` | Era 4 placeholder (eco revival). |
| `game/scenes/modules/environment/EnvironmentStage_OffWorld.tscn` | Era 5 placeholder (off-world habitat). |
| `scenes/sandbox/TopDownCanvas.tscn` | Map view host (Control + shader). |
| `src/sandbox/SandboxRenderer.gd` | Diorama renderer (CPU buffers, parallax, StatsProbe). |
| `src/sandbox/TopDownRenderer.gd` | Map renderer (palette/shader). |
| `ui/widgets/EnvPanel.tscn` | Tooltip + map legend integration. |
| `data/environment_config.json` | Smoothing and cadence configuration. |

## Signals & Metrics
| Signal | Payload | Consumers |
| --- | --- | --- |
| `ci_changed(ci: float, bonus: float)` | `{ ci, bonus }` | StatBus, Economy, EnvPanel. |
| `fallback_state_changed(active: bool)` | `{ active }` | Telemetry hooks, EnvPanel tooltip, runtime log.

| Metric | Source | Description |
| --- | --- | --- |
| `sandbox_render_ms_avg` | StatsProbe | Average render cost (current view). |
| `sandbox_render_ms_p95` | StatsProbe | p95 render cost (alerts > 1 ms). |
| `sandbox_render_fallback_ratio` | StatsProbe | Fraction of samples spent in half-rate fallback (0–1). |
| `sandbox_render_view_mode` | StatsProbe/Dashboard | Last active view label (`diorama`, `map`, etc.). |
| `belt_anim_ms_avg/p95` | StatsProbe | Conveyor overlay animation timing under PPS bursts and throttles. |

## Testing & Validation
- **Scene smoke:** Instantiate `scenes/sandbox/SandboxCanvas.tscn` headless to ensure buffers load.
- **Perf soak:** Run `tools/replay_headless.gd` with sandbox enabled; confirm `sandbox_render_ms_p95 ≤ 1.0 ms`.
- **Fallback share:** Inspect replay summary `sandbox_render_fallback_ratio`; keep sustained fallback below 0.05 (≤5 %) absent GPU experiments.
- **Determinism capture:** Hash successive frames for identical seeds/presets to guarantee reproducibility (±1 pixel).
- **Visual regression:** Include sandbox viewport in UI baseline screenshots (PX-010.9).
- **Era sweep:** Capture a run that promotes through tiers to confirm basic placeholder props appear for each stage and log replacement needs (see table above).

## Cross References
- Roadmap: [RM-021 — Environmental Simulation Layer](../roadmap/RM-021.md)
- Prompts: [PX-021.3 — Sandbox Viewport Renderer Integration](../prompts/PX-021.3.md)
- UI Integration: [UI Atoms module brief](ui_atoms.md), [UI Principles](../ux/UI_Principles.md)
- Performance: [Performance Budgets](../quality/Performance_Budgets.md), [Telemetry & Replay](../quality/Telemetry_Replay.md)
- Related module: [Conveyor Belt Visual Module](conveyor.md)
