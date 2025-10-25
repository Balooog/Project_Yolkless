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
| Rendering | Maintain `Image`/`ImageTexture` buffers, update dirty cells only, upscale via nearest-neighbour to viewport size. |
| Simulation bridge | Pull double-buffered grid snapshots from `SandboxService`, respect smoothing windows. |
| Performance | Logic ≤ 2 ms, render ≤ 1 ms. Half-rate fallback when frame p95 > 18 ms for five consecutive seconds. |
| Telemetry | Emit StatsProbe metrics (`sandbox_render_ms_avg`, `sandbox_render_ms_p95`, `sandbox_uploads_per_sec`, `sandbox_dirty_pixels_avg`). |
| Integration | Replace legacy `EnvironmentRoot` when `Config.env_renderer == "sandbox"`; expose comfort tooltip data via EnvPanel. |

## Inputs
- `EnvironmentService.environment_updated(state: Dictionary)` — drives tone/colour adjustments.
- `SandboxService.get_front_buffer()` / `SandboxService.ci_changed(ci, bonus)` — supply CA grid data + metrics.
- Config: `Config.env_renderer` flag and `data/environment_config.json` smoothing parameters.

## Outputs
- `ci_changed(ci: float, bonus: float)` — forwarded from SandboxService to StatBus/Economy/UI.
- StatsProbe stream (1 Hz) capturing render timing, upload counts, dirty pixel averages.
- UI hooks for EnvPanel (`Comfort +X.XX %` tooltip) and sandbox debug overlays.

## Performance Targets
| Metric | Budget | Notes |
| --- | --- | --- |
| Sandbox logic tick | ≤ 2 ms | Maintained by `SandboxService`. |
| Sandbox render | ≤ 1 ms | Renderer updates & uploads. |
| Frame p95 threshold | 18 ms | Trigger half-rate render fallback until stable. |
| Active cells | ≤ 400 | Mirrors CA budget; track via StatsProbe. |

## File Map
| Path | Role |
| --- | --- |
| `scenes/sandbox/SandboxCanvas.tscn` | Viewport + script mounting the renderer. |
| `scenes/sandbox/SandboxCanvas.gd` | Scene script wiring inputs/outputs, fallback logic. |
| `src/sandbox/SandboxRenderer.gd` | Core renderer with buffer management and dirty-cell uploads. |
| `ui/components/EnvPanel.tscn` | Tooltip integration (Comfort bonus). |
| `data/environment_config.json` | Smoothing and cadence configuration. |

## Signals & Metrics
| Signal | Payload | Consumers |
| --- | --- | --- |
| `ci_changed(ci: float, bonus: float)` | `{ ci, bonus }` | StatBus, Economy, EnvPanel. |
| `render_fallback_changed(active: bool)` | `{ active }` *(planned)* | Telemetry/Debug overlay to note half-rate mode. |

| Metric | Source | Description |
| --- | --- | --- |
| `sandbox_render_ms_avg` | StatsProbe | Average render cost. |
| `sandbox_render_ms_p95` | StatsProbe | p95 render cost (alerts > 1 ms). |
| `sandbox_uploads_per_sec` | StatsProbe | Upload cadence (expect ≥20 at full rate). |
| `sandbox_dirty_pixels_avg` | StatsProbe | Dirty coverage monitor (flags unusual churn). |

## Testing & Validation
- **Scene smoke:** Instantiate `scenes/sandbox/SandboxCanvas.tscn` headless to ensure buffers load.
- **Perf soak:** Run `tools/replay_headless.gd` with sandbox enabled; confirm `sandbox_render_ms_p95 ≤ 1.0 ms`.
- **Determinism capture:** Hash successive frames for identical seeds/presets to guarantee reproducibility (±1 pixel).
- **Visual regression:** Include sandbox viewport in UI baseline screenshots (PX-010.9).

## Cross References
- Roadmap: [RM-021 — Environmental Simulation Layer](../roadmap/RM-021.md)
- Prompts: [PX-021.3 — Sandbox Viewport Renderer Integration](../prompts/PX-021.3.md)
- UI Integration: [UI Atoms module brief](ui_atoms.md), [UI Principles](../ux/UI_Principles.md)
- Performance: [Performance Budgets](../quality/Performance_Budgets.md), [Telemetry & Replay](../quality/Telemetry_Replay.md)
- Related module: [Conveyor Belt Visual Module](conveyor.md)
