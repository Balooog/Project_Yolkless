# Build Gotchas (Godot 4)

Quick reference for the recurring issues we've tripped over while bringing Yolkless up under Godot 4.x. Review these before your next build to avoid fighting the same fires twice.

## Autoload scripts must stay `Node`
- Autoloads (`project.godot > [autoload]`) still expect classes that extend `Node`. If you need reference-only helpers, preload them separately instead of changing the autoload base type.
- Example fix: `SimulationClock.gd` previously used `class_name` with an incompatible base which prevented the singleton from instantiating.

## Typed GDScript + `--warnings-as-errors`
- Godot 4 infers `Variant` when variables lack explicit types and the value comes from a dynamic dictionary/array. With warnings promoted to errors in CI, scripts fail to compile.
- Always annotate locals when accessing dictionaries (`var next_cost: float = ...`) and reuse typed cached members instead of relying on inference.
- Arrays default to `Array` (Variant) when untyped. For nested buffers (e.g. `SandboxGrid`'s 2‑D grid), declare them as `Array[Array]` and type any duplicated locals (`var row: Array = _current[y]`) to avoid Variant bleed-through and accidental aliasing.
- Files that have mixed indentation (tabs + spaces) also fail to parse; stick with tabs for GDScript.
- StatsProbe hooks are particularly sensitive to this—always type locals (e.g. `var avg: float`) and avoid mixing tabs/spaces or the autoload will refuse to preload, breaking the entire service chain.

## No more `condition ? a : b`
- Godot 4 dropped the C-style ternary operator. Scripts that still use `foo ? bar : baz` fail to preload with “Unexpected `?`” parse errors.
- Rewrite ternaries using the new syntax: `bar if foo else baz`. This applies even inside helper expressions (`var dir := -1 if rng.randf() < 0.5 else 1`).
- Spot-check legacy utility scripts before enabling `--warnings-as-errors`; the parser surfaces this as a hard error even when the code path is rarely executed.

## Comfort sandbox placeholder
- `SandboxService` preloads `src/sandbox/SandboxGrid.gd`. During development we use a lightweight stub (`extends RefCounted`) until the full cellular automata returns.
- If you tweak `SandboxGrid` ensure it stays loadable (no `extends Node` unless you update the autoload wiring) and that `seed_grid`, `step`, `compute_comfort` still exist.

## Accessing child nodes
- `has_variable()` is not a generic way to check child availability. Prefer `get_node_or_null()` for nodes exposed through the scene tree (`Main.get_node_or_null("Economy")`).

## Prototype SubViewport resizing
- The prototype UI resizes `FactoryViewport`. Godot blocks manual sizing when the parent `SubViewportContainer.stretch` is `true`.
- Disable stretching once at `_ready()`:
  ```gdscript
  if container is SubViewportContainer:
      container.stretch = false
  ```
- After that, `_factory_viewport.size = Vector2i(...)` is safe.

## Logging and instrumentation overhead
- Any heavy logging in `_process`/`step` needs to be deferred (`call_deferred`) or offloaded, otherwise the extra dictionary duplication shows up as >0.5 ms environment ticks. This was caught during the PX-021 telemetry pass—defer the work before filing perf bugs.

## Prototype resolution sweep
- Use `tools/run_resolutions.sh` to open the project at 480×960, 600×360, 800×600, 1024×768, 1280×720, 1600×900, and 1920×1080 in sequence; close each window to advance.
- The script resolves the lavapipe CLI via `tools/godot_resolver.sh`. Override with `GODOT_BIN` if you temporarily test another build; pass extra flags via `GODOT_ARGS` when needed.
- Breakpoint logic must read the actual window size via `DisplayServer.window_get_size()`. The project stretches with `keep_width`, so `Control.size.x` stays at the design width (1280) even when the window is narrower—leading to tablets/phones being misdetected. The desktop breakpoint is tuned at 1150 px with ±40 px tolerance so the default 1280×720 window (after decorations) still registers as desktop.

## UI smoke scenes & lint harness
- `tools/uilint_scene.gd` expects UI smoke entries under `scenes/ui_smoke/` (e.g. `MainHUD.tscn`, `StoreHUD.tscn`). Keep these lightweight scenes in sync with the prototype or the lint pass will load the wrong layout.
- Invoke the lint runner with the resolver:  
  `source .env && $(bash tools/godot_resolver.sh) --headless --script res://tools/uilint_scene.gd -- res://scenes/ui_smoke/MainHUD.tscn`
- Godot 4 deprecates `Label.ellipsis`/`Label.autowrap`—use `text_overrun_behavior` and `autowrap_mode` instead.

Keep this list updated whenever a CI failure exposes another “gotcha”. A short note now saves everyone a debugging session later.
