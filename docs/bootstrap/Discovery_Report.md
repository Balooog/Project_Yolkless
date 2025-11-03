# Discovery Report — Project Yolkless

## Repository Snapshot
- **Primary runtime:** Godot 4.5 (`project.godot` lists `config/features=PackedStringArray("4.5")`) targeting the desktop editor with headless tooling under `tools/`.
- **Languages & tooling:** GDScript for runtime (`src/`, `game/`, `scenes/`), shell helpers (`tools/*.sh`), and focused Python utilities (`tools/validate_tables.py`, `tools/gen_dashboard.py`).
- **Assets & data:** Authored TSVs in `data/`, UI assets under `ui/`, and telemetry exports archived in `reports/`.
- **Docs footprint:** Rich `docs/` tree already covers architecture, balance, QA, and LiveOps specs; no `docs/bootstrap/` artifacts existed prior to this run.

## Product Shape
- **Profile heuristic:** Godot simulation with a 10 Hz loop, StatBus instrumentation, and telemetry playback → classify as **Game/Simulation**.
- **LiveOps focus:** Metrics dashboard specification (`docs/qa/Metrics_Dashboard_Spec.md`) and nightly replay tooling show active operations cadence.
- **Domain vocabulary:** Comfort Index, Egg Credits, and sandbox terminology dominate the glossary and design docs.

## Automation & Validation
- **CI workflows:** `.github/workflows/ci.yml` runs table validation (`tools/validate_tables.py`) and a scheduled nightly replay job; no dedicated docs stage exists yet.
- **Local validation:** Godot headless replays, UI screenshot diffing (`tools/ui_viewport_matrix.sh`, `tools/ui_compare.sh`), and smoke runs (`./tools/check_only_ci.sh`) are documented in AGENTS.md.
- **Telemetry artifacts:** Nightly reports stored under `reports/nightly/` with replay seeds defined in scripts.

## Discovery Notes
- No contradictory tech signals detected (no Flutter/Android manifests, no web package managers).
- Clarification log created at `docs/bootstrap/Clarifications.md`; no unanswered questions at discovery time.
