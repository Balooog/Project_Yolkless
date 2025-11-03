# Session Kickoff Checklist

> Run these steps at the start of any work session (Codex + humans).

## 1) Environment
- Python 3.11+ available
- `python -m venv .venv && . .venv/bin/activate` (Windows: `.venv\\Scripts\\activate`)
- `pip install -U pip wheel`
- `pip install -r requirements.txt` (if present)

## 2) Game/Toolchain versions
- Godot (if applicable): `godot --version`
- Verify repo docs: `python tools/docs_lint/check_structure.py`

## 3) Quick Smoke
- `python scripts/telemetry_replay_demo.py --seed 42 --ticks 200`
- Confirm outputs in `./artifacts/telemetry/` (`kpi.json` + `kpi_chart.png`)

## 4) Tests (if present)
- `pytest -q`

## 5) Contracts / Config
- `make validate-contracts` (or `python tools/contracts_validate.py`)
- Copy `config/user_settings.example.yaml` to `config/user_settings.yaml` and edit as needed

## 6) What to commit in PRs
- Link docs changes
- Attach demo artifacts (CI will upload automatically)
- Summarize KPI delta (if any)
