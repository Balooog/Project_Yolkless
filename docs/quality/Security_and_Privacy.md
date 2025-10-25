# Security & Privacy Guidelines

> Defines how telemetry logs and replay artifacts are handled. Terms: [Glossary](../Glossary.md).

## Data Retention
- Retain telemetry logs and dashboards for **30 days**.
- Archive older data under `reports/archive/` with anonymised identifiers; delete raw logs beyond retention window.

## Privacy
- No personally identifiable information (PII) is collected.
- Telemetry includes aggregated performance metrics only (PPS, CI, tick timings).
- Before uploading artifacts, scrub user-specific paths and environment variables.

## Access Control
- Limit write access to telemetry directories (`reports/`, `logs/`) to QA automation leads.
- CI artifacts stored in private buckets unless explicitly published (dashboard HTML).

## Incident Response
- If sensitive data is accidentally captured, remove artifacts immediately, notify ops lead, update risk register with remediation steps.

## References
- [Telemetry & Replay](Telemetry_Replay.md)
- [Metrics Dashboard Spec](../qa/Metrics_Dashboard_Spec.md)
- [Risk Register](../qa/Risk_Register.md)
