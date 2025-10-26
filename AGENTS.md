# Project Yolkless Agent Primer

## Session Kickoff Checklist
- Confirm `$(bash tools/godot_resolver.sh)` resolves to `./bin/Godot_v4.5.1-stable_linux.x86_64` inside WSL (Windows GPU captures may still point `GODOT_BIN` to `C:\src\godot\Godot_v4.5.1-stable_win64_console.exe`). Use `source .env` and `$GODOT_BIN --version` as outlined in [Build Cookbook](docs/dev/Build_Cookbook.md); expect `Godot Engine v4.5.1.stable.official`.
- Skim `README.md`, `docs/ROADMAP.md`, `docs/SPEC-1.md`, and the [Glossary](docs/Glossary.md) to refresh gameplay loop, terminology (Egg Credits, Comfort Index), and active roadmap beats.
- Review `docs/architecture/Overview.md`, `docs/architecture/Signals_Events.md`, and [Data Flow Diagram](docs/architecture/DataFlow_Diagram.md) before touching services/autoloads to stay aligned with the 10 Hz simulation spine and signal contracts.
- Check `docs/dev/build_gotchas.md` and `docs/dev/Tooling.md` for newly logged Godot pitfalls (typed variables, autoload base classes, ternary syntax changes, version policy).
- For balance/system tasks, open `docs/balance_schema.md` and [Balance Playbook](docs/design/Balance_Playbook.md) alongside relevant TSVs.
- Note current LiveOps state via [Metrics Dashboard Spec](docs/qa/Metrics_Dashboard_Spec.md) and latest telemetry artifacts under `reports/`.

## Default Engagement Workflow
When no explicit request is provided:
1. Get up to speed: review recent commits/telemetry notes, Roadmap module status, and open PX canvases.
2. Identify the next logical task (respecting RM/PX priorities, risk register, and current LiveOps alerts).
3. Execute work in small verified increments: run lint/tests per the Task Validation section, capture artifacts, and update code/docs accordingly.
4. Suggest follow-up tasks or monitoring actions based on project status, especially for telemetry, UI regression, or sandbox performance.
5. Update documentation as you go—prioritize `docs/dev/build_gotchas.md`, module briefs, and changelog entries when new learnings arise.

Always surface assumptions, blockers, and recommended verifications in the final response.

## Implementation Guardrails
- Favor the modern layout: runtime code in `src/`, reusable UI in `ui/`, authored data in `data/`; migrate legacy `game/` scripts only while delivering a related module.
- Autoloads **must** extend `Node`; preload helper classes separately if you need pure data types.
- Type every dictionary/array access and local in GDScript to avoid `Variant` warnings; CI treats warnings as errors.
- Replace legacy `condition ? a : b` with `a if condition else b` and keep indentation consistent (tabs for GDScript).
- `SandboxGrid` stays `RefCounted` until the CA returns; keep its API intact for `SandboxService` preload logic.
- When resizing `SubViewportContainer` children, disable `stretch` once in `_ready()` before assigning sizes (see `docs/dev/build_gotchas.md`).
- Use StatBus for cross-service stats; document new keys in `docs/architecture/StatBus_Catalog.md` and enforce additive vs multiplicative stacking rules.
- Follow UI atom patterns (`ui/components/`, `ui/theme/Tokens.tres`) and tone guides (`docs/theme_map.md`, `docs/design/Narrative_Hooks.md`) before introducing new strings or UI copy.
- Update documentation (Build Gotchas, module briefs, roadmap notes) whenever new constraints or fixes are discovered.

## Testing & Validation
- Default smoke flow:
  ```bash
  source .env && ./tools/check_only_ci.sh
  ./tools/ui_viewport_matrix.sh && ./tools/ui_compare.sh
  $(bash tools/godot_resolver.sh) --headless --script res://tools/replay_headless.gd --duration=300 --seed=42
  ./tools/ui_baseline.sh   # refresh baseline only after design approval
  $(bash tools/godot_resolver.sh) --headless --script res://tools/uilint_scene.gd res://scenes/ui_smoke/MainHUD.tscn
  ```
- Use `tools/nightly_replay.sh` or `tools/gen_dashboard.py` to inspect nightly performance (metrics definitions in `docs/quality/Telemetry_Replay.md`).
- Capture profiler data (avg/p95) when altering core services and compare against `docs/quality/Performance_Budgets.md`.
- After balance or string edits, launch via `./tools/run_dev.sh`, hot reload with `R`, and monitor the debug overlay (`F3`) plus EnvPanel comfort tooltip.
- Keep logs (`logs/yolkless.log`, telemetry CSV/JSON, dashboard HTML) as artifacts for PRs per `CONTRIBUTING.md`.
- Ensure CI pipeline stages (`validate-tables`, `renderer-setup`, `build`, `replay`, `ui-baseline`, `generate-dashboard`, `auto-changelog`) complete successfully before merge.

## Reference Docs to Keep Handy
- `docs/Developer_Handbook.md` — centralized onboarding/workflow summary.
- `docs/Glossary.md` & `docs/FAQ.md` — quick terminology and troubleshooting lookup.
- `docs/dev/Build_Cookbook.md` & `docs/dev/Tooling.md` — build/run commands, Godot policy, CLI helpers.
- `docs/quality/Telemetry_Replay.md` & `docs/qa/Metrics_Dashboard_Spec.md` — replay expectations, dashboard automation, normalization formulas.
- `docs/qa/Test_Strategy.md`, `docs/qa/CI_Pipeline.md`, `docs/qa/Risk_Register.md` — validation layers, CI stages, LiveOps monitoring responsibilities.
- `docs/analysis/IdleGameComparative.md` — comfort-idle benchmarks that guide pacing decisions.
- `docs/roadmap/` & `docs/prompts/` — active specs (RM-###) and driver prompts (PX-###) for module context.
- `docs/ops/Bug_and_Feature_Workflow.md` & `docs/ops/Release_Playbook.md` — issue flow, release and changelog automation.
- `CONTRIBUTING.md` — branch naming, commit footers, validation checklist.
