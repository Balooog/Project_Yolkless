PYTHON ?= python3

.PHONY: validate-contracts demo

validate-contracts:
	$(PYTHON) tools/contracts_validate.py || python tools/contracts_validate.py

demo:
	$(PYTHON) scripts/telemetry_replay_demo.py --seed 42 --ticks 200 || python scripts/telemetry_replay_demo.py --seed 42 --ticks 200
