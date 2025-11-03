# Common Errors & Fixes

## Godot CLI Not Found
- **Symptom:** `./tools/check_only_ci.sh` fails with `command not found: Godot`.
- **Fix:** Run `source .env && bash tools/bootstrap_godot.sh` to install `Godot_v4.5.1-stable_linux.x86_64` into `./bin/`. Confirm with `$(bash tools/godot_resolver.sh) --version`.

## Variant Warnings in CI
- **Symptom:** CI reports `Variant` type warnings during `--check-only`.
- **Fix:** Add explicit types for locals, arrays, and dictionary lookups in GDScript. Promote helper data structures into typed resources when possible.

## Legacy Ternary Syntax
- **Symptom:** Parser errors referencing `?:`.
- **Fix:** Replace `condition ? a : b` with `a if condition else b`; tabs only for indentation.

## SubViewport Layout Stretching
- **Symptom:** UI atoms appear double-scaled after resizing.
- **Fix:** In any `SubViewportContainer` child scene, call `sub_viewport.stretch = false` in `_ready()` before assigning custom sizes. Reference `docs/dev/build_gotchas.md`.

## SandboxGrid Lifecycle
- **Symptom:** `SandboxService` crashes when tests instantiate mock grids.
- **Fix:** Keep `SandboxGrid` as `RefCounted` per guardrail; avoid converting it to `Node` or freeing grid references inside signal callbacks.
