# Test Strategy

> Layered validation plan covering unit logic through player experience checks. Reference this alongside [Glossary](../Glossary.md), [CI Pipeline](CI_Pipeline.md), and [Build Cookbook](../dev/Build_Cookbook.md).

| Layer | Scope | Frequency | Owner |
| --- | --- | --- | --- |
| Unit | Single class/service (`SandboxGrid`, `StatBus`) | On commit / pre-PR | Dev |
| Integration | Subsystem workflow (Environment→Sandbox, Economy→UI) | Nightly | QA |
| Replay | Headless 5-minute run using `tools/replay_headless.gd` | Nightly | CI |
| Visual | Screenshot diff (`ui_viewport_matrix.sh`, `ui_compare.sh`) | Nightly | CI |
| Localization | POT sync + pseudo-loc UILint (`tools/localization_export_check.sh`, `tools/pseudo_loc_smoke.sh`) | On commit / pre-PR | CI |
| Soak | 1-hour stability run with telemetry logging | Weekly | QA |
| Manual | UX/feel regression checklist (`RM-010` HUD) | Milestone / release | Design |

## Exit Criteria per Layer
- **Unit:** 100 % pass in `tests/unit/`, no warnings; new behaviour requires tests.
- **Integration:** Replay JSON shows `sandbox_tick_ms_p95 ≤ 1.9 ms`, `ci_delta_abs_max ≤ 0.05`.
- **Replay:** CI artifacts include CSV/JSON; failures block merge.
- **Visual:** Pixel diff ≤1 % and UILint violations = 0.
- **Soak:** No crashes, memory steady (<5 % drift), StatsProbe alerts cleared.
- **Manual:** Checklist signed by design lead; qualitative notes stored under `logs/playtest_notes/`.

## Feature Guardrails
- **Mini-game isolation (future RM-0XX):** Run replay with a forced mini-game session; confirm PPS bonus arrives via Insight/Reputation, Sandbox visuals throttle to ¼ speed, and CA tick metrics remain unchanged.
- **Reduce Motion sweep:** Execute CI pipeline once with `Config.reduce_sandbox_motion=true`; verify conveyor/map/diorama disable speedlines/camera pan and telemetry still exports `belt_anim_ms_*`.
- **View parity:** Follow [RM-021 sandbox checklist](RM-021-sandbox-checklist.md) after renderer changes to ensure Diorama/Map guardrails hold.

## Tooling References
- [Build Cookbook](../dev/Build_Cookbook.md)
- [Telemetry & Replay](../quality/Telemetry_Replay.md)
- [Performance Budgets](../quality/Performance_Budgets.md)
- [RM-010 UI Checklist](RM-010-ui-checklist.md)
- [Sandbox Module Brief](../modules/sandbox.md)
