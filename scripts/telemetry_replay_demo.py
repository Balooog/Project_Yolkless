"""Deterministic telemetry harness used for CI artifacts."""
from __future__ import annotations

import argparse
import json
import os
import struct
import zlib
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import List, Sequence, Tuple

ARTIFACT_DIR = Path(os.environ.get("YLK_ARTIFACTS", "artifacts/telemetry"))


@dataclass(frozen=True)
class DemoResult:
    summary: dict
    egg_history: List[float]


def _lcg(prev: int) -> int:
    return (prev * 48271) % 0x7FFFFFFF or 1


def _avg(values: Sequence[float]) -> float:
    return sum(values) / max(len(values), 1)


def _p95(values: Sequence[float]) -> float:
    if not values:
        return 0.0
    ordered = sorted(values)
    index = min(len(ordered) - 1, int(round(0.95 * (len(ordered) - 1))))
    return float(ordered[index])


def _downsample(series: Sequence[Tuple[int, float]], target: int = 120) -> List[dict]:
    if not series:
        return []
    step = max(1, len(series) // target)
    return [{"tick": tick, "eggs": eggs} for idx, (tick, eggs) in enumerate(series) if idx % step == 0 or idx == len(series) - 1]


def generate_demo_summary(seed: int, ticks: int) -> DemoResult:
    dt = 1.0
    state = seed if seed > 0 else seed + 0x7FFFFFFF
    eggs = 0.0
    rate = 1.0
    ci = 50.0
    ci_bonus = 0.0
    ci_delta_history: List[float] = []
    pps_history: List[float] = []
    storage = 20.0
    wallet = 10.0
    active_cells = 64.0
    power_ratio = 1.0
    feed_fraction_history: List[float] = []
    storage_history: List[float] = []
    power_state_history: List[float] = []
    auto_active_history: List[float] = []
    sandbox_ticks: List[float] = []
    economy_ticks: List[float] = []
    environment_ticks: List[float] = []
    automation_ticks: List[float] = []
    power_ticks: List[float] = []
    render_ticks: List[float] = []
    eco_in: List[float] = []
    eco_apply: List[float] = []
    eco_ship: List[float] = []
    eco_research: List[float] = []
    eco_statbus: List[float] = []
    eco_ui: List[float] = []
    fallback_samples: List[int] = []
    shipments = []
    samples = []
    alerts = []
    egg_history: List[float] = []
    series_seed: List[Tuple[int, float]] = []

    for tick in range(max(ticks, 1)):
        state = _lcg(state)
        noise = (state / 0x7FFFFFFF) - 0.5
        rate = max(0.1, rate * (1.0 + noise * 0.02))
        eggs += rate
        wallet = max(0.0, wallet + rate * 0.55)
        storage = max(0.0, storage + rate * 0.45 - 1.1)
        ci_delta = noise * 0.8 + 0.15
        ci = min(100.0, max(0.0, ci + ci_delta))
        ci_bonus = min(30.0, max(0.0, ci_bonus + ci_delta * 0.35 + 0.05))
        active_cells = min(512.0, max(0.0, active_cells + noise * 7.0 + 2.0))
        power_ratio = min(1.1, max(0.5, power_ratio + noise * 0.05))
        feed_fraction = min(1.0, max(0.0, rate / 25.0))
        sandbox_tick = 4.0 + abs(noise) * 2.2
        economy_tick = 3.0 + abs(noise) * 1.8
        environment_tick = 1.4 + abs(noise) * 1.1
        automation_tick = 1.2 + abs(noise)
        power_tick = 0.8 + abs(noise) * 0.9
        render_tick = 2.2 + abs(noise) * 1.4

        sandbox_ticks.append(sandbox_tick)
        economy_ticks.append(economy_tick)
        environment_ticks.append(environment_tick)
        automation_ticks.append(automation_tick)
        power_ticks.append(power_tick)
        render_ticks.append(render_tick)

        eco_in.append(economy_tick * 0.25)
        eco_apply.append(economy_tick * 0.2)
        eco_ship.append(economy_tick * 0.18)
        eco_research.append(economy_tick * 0.16)
        eco_statbus.append(economy_tick * 0.14)
        eco_ui.append(economy_tick * 0.12)

        fallback_samples.append(1 if noise > 0.35 else 0)
        auto_active_history.append(1 if noise > 0.25 else 0)

        ci_delta_history.append(ci_delta)
        pps_history.append(rate)
        storage_history.append(storage)
        feed_fraction_history.append(feed_fraction)
        power_state_history.append(power_ratio)
        egg_history.append(eggs)
        series_seed.append((tick, eggs))

        if tick % max(1, ticks // 5) == 0:
            shipments.append({
                "time": tick * dt,
                "amount": rate * 4.0,
                "wallet": wallet
            })
        if tick % 5 == 0:
            samples.append({
                "time": tick * dt,
                "ci": ci,
                "ci_bonus": ci_bonus,
                "ci_delta": ci_delta,
                "pps": rate,
                "storage": storage,
                "wallet": wallet,
                "active_cells": active_cells,
                "power_ratio": power_ratio
            })

    fallback_ratio = _avg(fallback_samples)
    stats = {
        "sandbox_tick_ms_avg": _avg(sandbox_ticks),
        "sandbox_tick_ms_p95": _p95(sandbox_ticks),
        "sandbox_render_ms_avg": _avg(render_ticks),
        "sandbox_render_ms_p95": _p95(render_ticks),
        "sandbox_render_fallback_ratio": fallback_ratio,
        "sandbox_render_view_mode": "isometric",
        "pps_avg": _avg(pps_history),
        "ci_avg": _avg([sample["ci"] for sample in samples]) if samples else ci,
        "ci_delta_avg": _avg(ci_delta_history),
        "ci_delta_abs_max": max((abs(value) for value in ci_delta_history), default=0.0),
        "power_ratio_avg": _avg(power_state_history),
        "active_cells_max": max(active_cells for active_cells in [s["active_cells"] for s in samples]) if samples else active_cells,
        "automation_tick_ms_avg": _avg(automation_ticks),
        "automation_tick_ms_p95": _p95(automation_ticks),
        "automation_auto_active_avg": _avg(auto_active_history),
        "economy_tick_ms_avg": _avg(economy_ticks),
        "economy_tick_ms_p95": _p95(economy_ticks),
        "economy_pps_avg": _avg(pps_history),
        "economy_storage_avg": _avg(storage_history),
        "economy_feed_fraction_avg": _avg(feed_fraction_history),
        "eco_in_ms_avg": _avg(eco_in),
        "eco_in_ms_p95": _p95(eco_in),
        "eco_apply_ms_avg": _avg(eco_apply),
        "eco_apply_ms_p95": _p95(eco_apply),
        "eco_ship_ms_avg": _avg(eco_ship),
        "eco_ship_ms_p95": _p95(eco_ship),
        "eco_research_ms_avg": _avg(eco_research),
        "eco_research_ms_p95": _p95(eco_research),
        "eco_statbus_ms_avg": _avg(eco_statbus),
        "eco_statbus_ms_p95": _p95(eco_statbus),
        "eco_ui_ms_avg": _avg(eco_ui),
        "eco_ui_ms_p95": _p95(eco_ui),
        "environment_tick_ms_avg": _avg(environment_ticks),
        "environment_tick_ms_p95": _p95(environment_ticks),
        "environment_stage_rebuild_ms_max": max(environment_ticks) * 0.35,
        "environment_stage_rebuild_source_last": "demo",
        "power_tick_ms_avg": _avg(power_ticks),
        "power_tick_ms_p95": _p95(power_ticks),
        "power_state_avg": _avg(power_state_history)
    }

    if stats["sandbox_tick_ms_p95"] > 6.0:
        alerts.append({
            "time": ticks * dt,
            "metric": "sandbox_tick_ms_p95",
            "value": stats["sandbox_tick_ms_p95"],
            "threshold": 6.0
        })
    if fallback_ratio > 0.2:
        alerts.append({
            "time": ticks * dt,
            "metric": "sandbox_render_fallback_ratio",
            "value": fallback_ratio,
            "threshold": 0.2
        })

    summary = {
        "timestamp": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
        "seed": seed,
        "strategy": "demo",
        "duration": float(ticks) * dt,
        "dt": dt,
        "preset": "demo",
        "shipments": shipments,
        "samples": samples,
        "stats": stats,
        "alerts": alerts,
        "final": {
            "ci": ci,
            "ci_bonus": ci_bonus,
            "pps": pps_history[-1] if pps_history else rate,
            "wallet": wallet,
            "storage": storage
        },
        "series": _downsample(series_seed),
        "metadata": {
            "generator": "telemetry_replay_demo.py",
            "ticks": ticks
        }
    }
    return DemoResult(summary=summary, egg_history=egg_history)


def _write_png(width: int, height: int, pixels: bytearray, path: Path) -> None:
    raw = bytearray()
    stride = width * 4
    for y in range(height):
        start = y * stride
        raw.append(0)
        raw.extend(pixels[start:start + stride])

    def _chunk(tag: bytes, data: bytes) -> bytes:
        return (
            struct.pack(">I", len(data))
            + tag
            + data
            + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
        )

    header = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    data = zlib.compress(bytes(raw), level=9)
    png_bytes = b"\x89PNG\r\n\x1a\n" + _chunk(b"IHDR", header) + _chunk(b"IDAT", data) + _chunk(b"IEND", b"")
    path.write_bytes(png_bytes)


def _draw_line(pixels: bytearray, width: int, height: int, x0: int, y0: int, x1: int, y1: int, color: Tuple[int, int, int, int]) -> None:
    dx = abs(x1 - x0)
    dy = -abs(y1 - y0)
    sx = 1 if x0 < x1 else -1
    sy = 1 if y0 < y1 else -1
    err = dx + dy
    while True:
        if 0 <= x0 < width and 0 <= y0 < height:
            idx = (y0 * width + x0) * 4
            pixels[idx:idx + 4] = bytes(color)
        if x0 == x1 and y0 == y1:
            break
        e2 = err * 2
        if e2 >= dy:
            err += dy
            x0 += sx
        if e2 <= dx:
            err += dx
            y0 += sy


def _render_chart(values: Sequence[float], path: Path) -> None:
    if len(values) < 2:
        return
    width, height = 480, 260
    margin = 24
    bg = (248, 249, 255, 255)
    axis = (213, 219, 240, 255)
    line = (78, 119, 212, 255)
    pixels = bytearray(width * height * 4)
    for idx in range(0, len(pixels), 4):
        pixels[idx:idx + 4] = bytes(bg)

    for x in range(margin, width - margin):
        _draw_line(pixels, width, height, x, height - margin, x, height - margin, axis)
    for y in range(margin, height - margin + 1):
        _draw_line(pixels, width, height, margin, y, margin, y, axis)

    max_val = max(values)
    min_val = min(values)
    scale = max(max_val - min_val, 1e-6)
    usable_height = height - 2 * margin
    usable_width = width - 2 * margin

    def _to_screen(idx: int, value: float) -> Tuple[int, int]:
        x = margin + int(round((idx / (len(values) - 1)) * usable_width))
        norm = (value - min_val) / scale
        y = height - margin - int(round(norm * usable_height))
        return x, y

    prev_x, prev_y = _to_screen(0, values[0])
    for idx, value in enumerate(values[1:], start=1):
        x, y = _to_screen(idx, value)
        _draw_line(pixels, width, height, prev_x, prev_y, x, y, line)
        prev_x, prev_y = x, y

    _write_png(width, height, pixels, path)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--ticks", type=int, default=200)
    args = parser.parse_args()

    ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)
    result = generate_demo_summary(args.seed, args.ticks)

    kpi_path = ARTIFACT_DIR / "kpi.json"
    with kpi_path.open("w", encoding="utf-8") as handle:
        json.dump(result.summary, handle, indent=2)

    chart_path = ARTIFACT_DIR / "kpi_chart.png"
    try:
        _render_chart(result.egg_history, chart_path)
    except Exception as exc:  # pragma: no cover - avoid failing demo on image issues
        chart_path = None
        print(f"[telemetry-demo] Chart generation skipped: {exc}")

    paths = [f"{kpi_path}"]
    if chart_path and chart_path.exists():
        paths.append(f"{chart_path}")
    print("Wrote " + ", ".join(paths))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
