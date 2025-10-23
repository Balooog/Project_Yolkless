# Telemetry & Replay Guide

> Ensures balance changes respect comfort-idle pacing by simulating long sessions with consistent metrics.

## Log Formats
- **CSV (`logs/telemetry/*.csv`)**: Columns include `timestamp`, `pps`, `storage`, `ci_bonus`, `event`, `power_state`.
- **JSON (`logs/telemetry/*.json`)**: Batch summaries with averages and percentiles for automation.
- All entries include `scenario` tag (e.g., `hands_off`, `burst_cycle`).

## Headless CLI
```bash
# 5 minute hands-off baseline
./tools/headless_tick.sh 300

# Burst cadence simulation
./tools/headless_tick.sh 300 --strategy=burst
```
- By default writes to `logs/yolkless.log` and `logs/telemetry/`.
- Use `--seconds` flag to extend runs (e.g., 3600 for hour-long soak).

## Key Metrics
| Metric | Source | Purpose |
| ------ | ------ | ------- |
| `pps` | StatBus | Verifies pacing vs Balance Playbook. |
| `ci_bonus` | SandboxService | Tracks serenity gains from environment tuning. |
| `shipment_interval` | Economy dump log | Ensures early shipments stay within comfort bounds. |
| `power_state` | PowerService | Detects stress from power deficits. |
| `event_active` | EventDirector | Confirms events stay gentle and infrequent. |

## Replay Workflow
1. Run headless scenario (hands-off + burst).
2. Import CSV into analysis notebook or spreadsheet.
3. Compare against baseline thresholds (see `Performance_Budgets.md`).
4. Record results in QA checklist (`docs/qa/`).

## Automation Hooks
- CI pipeline can call `./tools/headless_tick.sh` nightly and archive logs.
- Emit summary JSON stats for dashboards (mean PPS, CI percentile, frame cost).

## References
- [Performance Budgets](Performance_Budgets.md)
- [StatBus Catalog](../architecture/StatBus_Catalog.md)
