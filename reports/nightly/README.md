# Nightly Replay Artifacts

`nightly-replay` CI job publishes JSON summaries and PNG graphs here. Each run creates a dated subfolder (`YYYYMMDD`) containing:

- `summary.json` — combined telemetry + StatsProbe metrics
- `performance.png` — quick-look chart for dashboards

Do not commit large binaries; prune obsolete runs as part of release housekeeping.
