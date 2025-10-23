# Contributing to Project Yolkless

Thank you for helping build a cozy idle experience. Follow these practices to keep the project serene and maintainable.

## Branching & Commits
- Use feature branches: `feature/RM-###-short-slug` (e.g., `feature/RM-011-early-upgrade`).
- Commit early, keep messages concise.
- Include footers for traceability:
  - `RM: RM-011`
  - `PX: PX-011.2`
  - `Docs: StatBus_Catalog`
- Example commit:
  ```
  feat: adjust early shipment pacing

  - lower prod_1 cost to 50 credits
  - update telemetry scenario to log shipments

  RM: RM-011
  PX: PX-011.2
  Docs: Balance_Playbook
  ```

## PR Checklist
- [ ] Link relevant RM/PX and ADRs in description.
- [ ] Reference comfort-idle guidance (`docs/analysis/IdleGameComparative.md`).
- [ ] Include validation evidence (screens, logs, headless output).
- [ ] Update documentation if schema, signals, or stats change.
- [ ] Performance check: attach profiler snapshot vs `Performance_Budgets.md`.
- [ ] Headless replay run (e.g., `replay_headless.gd`) with logs attached.
- [ ] Request review from owner (see Roadmap modules).

## Coding Standards
- GDScript 4 style, use signal connections in `_ready`.
- Keep data in TSV; avoid magic numbers.
- Use `YolkLogger` for structured logs.

## Testing
- Run `./tools/headless_tick.sh 300` for economy regressions.
- Check performance budgets if touching core loops.
- Ensure comfort metrics (`ci_bonus`) remain within +5% cap.

## Documentation
- Add new stats to [StatBus Catalog](docs/architecture/StatBus_Catalog.md).
- Update [Signals Matrix](docs/architecture/Signals_Events.md) when emitting new signals.
- Record architecture choices via ADR template (`docs/templates/ADR_Template.md`).

Welcome to the farm!
