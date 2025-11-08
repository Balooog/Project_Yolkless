# Shipping Implementation Plan - Non-Stubbed Dependencies

> Snapshot: 2025-10-28. Aligns release gates in `docs/ops/Release_Milestones.md` with remaining feature specs and architecture TODOs. Focus is on work that cannot be faked or stubbed without blocking a ship-ready build.

## Solo Execution Sequence

| Order | Target Window | PX | Task | Notes |
| --- | --- | --- | --- | --- |
| 1 | Sprint 1 | PX-007.1 | Finish offline passive production | Complete 2025-11-02 - catch-up math, snapshot telemetry, and summary popup live. |
| 2 | Sprint 1 | PX-011.3 | Wire conveyor throughput into Economy and StatBus | Complete 2025-11-02 - StatBus metrics, jam warnings, and delivery telemetry wired. |
| 3 | Sprint 2 | PX-013.2 | Surface automation scheduling and status UI | Expose queue telemetry and control toggles. |
| 4 | Sprint 2 | PX-014.4 | Complete StatsProbe diff dashboards | Complete 2025-11-02 - `tools/gen_dashboard.py --diff` prints metric deltas for reviewers. |
| 5 | Sprint 2 | PX-018.5 | UI Baseline: real engine capture + CI assert | Complete 2025-11-07 - `tools/run_headless_godot.sh` captures Godot HUD scenes (xvfb/llvmpipe fallback) and `ui_assert_baseline` enforces toast/safe-area contract. |
| 6 | Sprint 3 | PX-018.3 | Document and test power warnings | Ensure deficits produce calm feedback and logs. |
| 7 | Sprint 4 | PX-021.4 / PX-021.5 | Ship diorama evolution and map toggle | Establish shared renderer pipeline ahead of beta polish. |
| 8 | Sprint 4 | PX-021.6 | Author environment milestone profiles and tier swaps | Data must be ready before prestige and layout hooks. |
| 9 | Sprint 5 | PX-019.1 | Bind conveyor deliveries with layout adjacency economy bonuses | Requires environment tiers and power ledger to be stable. |
| 10 | Sprint 5 | PX-016.2 | Implement event and risk system loops | Builds on automation, power, and layout. |
| 11 | Sprint 6 | PX-015.1 | Prestige theming and HUD wisdom surfacing | Needs environment tiers and event hooks available. |
| 12 | Sprint 6 | PX-020.1 / PX-010.13 | Finalize art/audio pipeline and accessibility passes | Coordinate with prestige theming and automation UI. |
| 13 | Sprint 7 | PX-022.1 | Localization dry-run and pipeline docs | Run once UI copy and tokens are stable. |
| 14 | Sprint 7 | PX-014.3 | Automate nightly telemetry replay and timelapse capture | Depends on map toggle and diff dashboards. |
| 15 | Sprint 8 | PX-018.2 / PX-017.2 | Harden release automation and build exports | Execute when telemetry automation is proven. |
| 16 | Sprint 8 | PX-017.3 / PX-016.3 | LiveOps monitoring, risk cadence, and post-launch hooks | Final gating before launch sign-off. |

## Phase A - Alpha Hardening (Systems Backbone)

**Objective:** Deliver reliable simulation, automation, and telemetry so Alpha exit criteria are provable without hand-waving.

| PX | Task | Blocking Dependencies | Required Outputs | Verification |
| --- | --- | --- | --- | --- |
| PX-007.1 | Finish offline passive production (RM-007) | Save system v1, Economy loop, UI sheets | Deterministic catch-up calc, summary popup, save stamp migration | 8 h headless replay, manual quit/relaunch smoke, telemetry delta log |
| PX-011.3 | Wire conveyor throughput into Economy + StatBus (RM-009, RM-011) | Conveyor manager signals, Economy shipment hooks | Items-per-second -> shipment yield linkage, queue alerts surfaced in HUD | Replay profile showing conveyor and shipment parity, CI baseline check |
| PX-013.2 | Surface automation scheduling + status UI (RM-013) | Automation Service timers, HUD sheets | Tab exposes mode previews, autoburst queue telemetry, toggle safety rails | Controller pass plus ui_lint scene, automation metrics in nightly dashboards |
| PX-014.4 | Complete StatsProbe diff dashboards (RM-014) | Telemetry CSV/JSON exports, DocOps pipeline | Dashboard diff script, docs quickstart, PR artifact review checklist | `tools/gen_dashboard.py` diff run in CI, docs lint passes |
| PX-018.3 | Document and test power warnings (RM-018) | PowerService ratios, EnvPanel bindings | Warning palette and audio hooks, StatBus + telemetry wiring, module brief update | Replay showing power deficit -> tint/audio response, StatBus entry updated |

**Notes**
- Update `docs/architecture/Implementation_TODO.md` after each landing.
- Capture assumptions and new StatBus keys in `docs/architecture/StatBus_Catalog.md` alongside instrumentation commits.

## Phase B - Beta Cohesion (World, Progression, Presentation)

**Objective:** Make the farm feel alive and consistent across systems; remove placeholder visuals/audio and deliver the layout gameplay promised in specs.

| PX | Task | Blocking Dependencies | Required Outputs | Verification |
| --- | --- | --- | --- | --- |
| PX-021.4 / PX-021.5 | Ship diorama evolution + map toggle | Shared sandbox buffers, art staging assets | Era props per tier, instant Diorama/Map toggle, timelapse-ready snapshots | UI baseline run with both views, StatsProbe fallback ratio <5% |
| PX-021.6 | Author environment milestone profiles and tier swaps (RM-021) | `data/environment_profiles.tsv`, prestige milestones | Tier-based profile data, EnvPanel branching, designer notes | Hot-reload review, replay capturing tier promotion transitions |
| PX-019.1 | Bind conveyor deliveries + layout adjacency economy bonuses (RM-019) | Factory grid data, power ledger | Placement UX, adjacency modifiers routed to StatBus/Economy, save payload updates | Placement integration smoke, StatBus additive rule validation |
| PX-016.2 | Implement event and risk system loops (RM-016) | Automation and power hooks, HUD overlays | Weighted scheduler, calm feedback, telemetry coverage | Replay stress scenarios, risk log update with new event class |
| PX-015.1 | Prestige theming + HUD wisdom surfacing (RM-015) | Art/audio pipeline, EnvPanel, save schema | Prestige ceremony, wisdom panel, Balance Playbook update | Narrative copy review, telemetry parity run matched against targets |
| PX-020.1 / PX-010.13 | Finalize art/audio pipeline and accessibility passes (RM-020, RM-010) | Asset tokens, automation/power signals | Tokenized palettes, layered ambience, controller/accessibility sign-off | `tools/ui_viewport_matrix.sh`, accessibility checklist closure, audio soak |
| PX-022.1 | Localization dry-run + pipeline docs | Strings TSV, DocOps lint | Pseudo-loc build, pipeline doc, overflow QA issues logged | Localization check per Release Milestones, regression smoke |

**Notes**
- Balance changes must be logged in `docs/design/Balance_Playbook.md` and `data/balance.tsv` updates go through `tools/validate_tables.py`.
- New telemetry metrics or StatBus keys require catalog updates and QA checklist revisions.

## Phase C - Launch Operations (LiveOps & Release Readiness)

**Objective:** Automate monitoring, finalize exports, and close the loop from build to live metrics.

| PX | Task | Blocking Dependencies | Required Outputs | Verification |
| --- | --- | --- | --- | --- |
| PX-014.3 | Automate nightly telemetry replay + timelapse capture | Map renderer, replay scripts, storage artifacts | Scheduled job, timelapse assets archived, dashboard trend diffs | Cron job dry-run, dashboard diff appended to reports, doc updates |
| PX-018.2 | Harden release automation (RM-017) | Git tag workflow, DocOps pipeline | Branch/tag policy in `CONTRIBUTING.md`, release checklist automation, artifact retention plan | Dry-run release using staging tag, QA checklist sign-off |
| PX-017.2 | Export platform builds and smoke tests | Godot CLI resolver, build presets | Linux/Windows builds archived under `releases/`, hash log, smoke reports | `tools/build_linux.sh` run, WSL and Windows capture validation |
| PX-017.3 | LiveOps monitoring and risk register cadence | Metrics dashboard, risk register doc | Monitoring runbook, on-call rotation notes, updated risk entries | Risk register review, dashboard links embedded in Release Playbook |
| PX-016.3 | Post-launch content hooks | Event system, telemetry, StatBus | Sandbox for LiveOps toggles, dashboard guardrail alerts, content rollout checklist | Live toggle dry-run, metrics alerts fired under test seeds |

**Notes**
- Keep `docs/qa/Risk_Register.md` and `reports/dashboard/` artifacts aligned per release.
- Archive telemetry, timelapse, and changelog outputs under `reports/releases/` for audit.

## Ongoing Hygiene
- Re-run `python3 tools/docs_lint/check_structure.py` after editing this file or related docs.
- Stick to typed GDScript and Godot 4 syntax guardrails from `docs/dev/build_gotchas.md`.
- When adding services, ensure autoload base classes remain `Node` and document new signals.
