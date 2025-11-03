#!/usr/bin/env python3
"""Validate sample payloads against project JSON Schemas."""
from __future__ import annotations

import json
import sys
import hashlib
from pathlib import Path

try:
    from jsonschema import Draft202012Validator, validate
except ModuleNotFoundError as exc:  # pragma: no cover - guidance for local runs
    print("Missing dependency 'jsonschema'. Install via `pip install jsonschema`.", file=sys.stderr)
    raise SystemExit(1) from exc


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

try:
    from scripts.telemetry_replay_demo import generate_demo_summary  # type: ignore
except Exception:  # pragma: no cover - fallback if script import fails
    generate_demo_summary = None


SCHEMAS = {
    "save": ROOT / "contracts/save.schema.json",
    "telemetry": ROOT / "contracts/telemetry.schema.json",
}


def _load(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def _build_save_sample() -> dict:
    payload = {
        "save_version": 3,
        "ts": 1_735_689_600,
        "eco": {
            "soft": 1250.0,
            "storage": 480.0,
            "total_earned": 34210.5,
            "capacity_rank": 4,
            "prod_rank": 5,
            "factory_tier": 2,
            "feed": 7.5,
        },
        "upgrades": {
            "conveyor_speed": 3,
            "hen_capacity": 5,
            "auto_ship": 2,
        },
        "research": {
            "owned": ["auto_feed", "night_shift"],
            "pp": 12,
        },
    }
    payload_json = json.dumps(payload, separators=(",", ":"), sort_keys=True)
    payload_hash = hashlib.md5(payload_json.encode("utf-8")).hexdigest()
    return {"hash": payload_hash, "payload": payload}


def _encode_save_payload(wrapper: dict) -> dict:
    encoded = dict(wrapper)
    payload = encoded.get("payload")
    if not isinstance(payload, dict):
        return encoded
    encoded["payload"] = json.dumps(payload, separators=(",", ":"), sort_keys=True)
    return encoded


def _fallback_telemetry_sample() -> dict:
    return {
        "timestamp": "2025-01-01T00:00:00Z",
        "seed": 42,
        "strategy": "demo",
        "duration": 200.0,
        "dt": 1.0,
        "preset": "demo",
        "shipments": [
            {"time": 0.0, "amount": 4.0, "wallet": 10.0}
        ],
        "samples": [
            {
                "time": 0.0,
                "ci": 52.0,
                "ci_bonus": 1.0,
                "ci_delta": 0.2,
                "pps": 1.0,
                "storage": 20.0,
                "wallet": 10.0,
                "active_cells": 66.0,
                "power_ratio": 1.0
            }
        ],
        "stats": {
            "sandbox_tick_ms_avg": 5.0,
            "sandbox_tick_ms_p95": 6.1,
            "sandbox_render_ms_avg": 2.5,
            "sandbox_render_ms_p95": 3.0,
            "sandbox_render_fallback_ratio": 0.1,
            "sandbox_render_view_mode": "isometric",
            "pps_avg": 1.0,
            "ci_avg": 52.0,
            "ci_delta_avg": 0.2,
            "ci_delta_abs_max": 0.2,
            "power_ratio_avg": 1.0,
            "active_cells_max": 66.0,
            "automation_tick_ms_avg": 1.2,
            "automation_tick_ms_p95": 1.6,
            "automation_auto_active_avg": 0.3,
            "economy_tick_ms_avg": 3.5,
            "economy_tick_ms_p95": 4.2,
            "economy_pps_avg": 1.0,
            "economy_storage_avg": 20.0,
            "economy_feed_fraction_avg": 0.2,
            "eco_in_ms_avg": 0.9,
            "eco_in_ms_p95": 1.1,
            "eco_apply_ms_avg": 0.8,
            "eco_apply_ms_p95": 1.0,
            "eco_ship_ms_avg": 0.7,
            "eco_ship_ms_p95": 0.9,
            "eco_research_ms_avg": 0.6,
            "eco_research_ms_p95": 0.8,
            "eco_statbus_ms_avg": 0.5,
            "eco_statbus_ms_p95": 0.7,
            "eco_ui_ms_avg": 0.4,
            "eco_ui_ms_p95": 0.6,
            "environment_tick_ms_avg": 1.5,
            "environment_tick_ms_p95": 1.8,
            "environment_stage_rebuild_ms_max": 0.6,
            "environment_stage_rebuild_source_last": "demo",
            "power_tick_ms_avg": 0.9,
            "power_tick_ms_p95": 1.2,
            "power_state_avg": 1.0
        },
        "alerts": [],
        "final": {
            "ci": 52.0,
            "ci_bonus": 1.0,
            "pps": 1.0,
            "wallet": 15.0,
            "storage": 18.0
        },
        "series": [
            {"tick": 0, "eggs": 1.0},
            {"tick": 10, "eggs": 12.0}
        ],
        "metadata": {"generator": "fallback"}
    }


def _build_telemetry_sample() -> dict:
    if generate_demo_summary is None:
        return _fallback_telemetry_sample()
    demo = generate_demo_summary(seed=42, ticks=120)
    return demo.summary


SAMPLE_BUILDERS = {
    "save": _build_save_sample,
    "telemetry": _build_telemetry_sample,
}


def main() -> int:
    errors: list[str] = []
    for name, schema_path in SCHEMAS.items():
        if not schema_path.exists():
            errors.append(f"{name}: schema not found at {schema_path}")
            continue

        schema = _load(schema_path)
        Draft202012Validator.check_schema(schema)
        sample = SAMPLE_BUILDERS[name]()
        try:
            validate(instance=sample, schema=schema)
        except Exception as exc:  # noqa: BLE001 - show precise validation failure
            errors.append(f"{name}: {exc}")
            continue

        if name == "save":
            encoded_sample = _encode_save_payload(sample)
            try:
                validate(instance=encoded_sample, schema=schema)
            except Exception as exc:
                errors.append(f"{name} (encoded payload): {exc}")

    if errors:
        print("Schema validation failed:\n - " + "\n - ".join(errors))
        return 1

    print("All schemas validated against samples.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
