#!/usr/bin/env python3
"""
Generate telemetry dashboards or diff key metrics between two replay summaries.

Usage:
    python3 tools/gen_dashboard.py --input reports/nightly --output reports/dashboard/index.html
    python3 tools/gen_dashboard.py --diff reports/nightly/latest.json artifacts/telemetry/kpi.json
"""

from __future__ import annotations

import argparse
import json
import math
import statistics
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Tuple


MetricValue = Optional[float]


@dataclass
class RunRecord:
	timestamp: datetime
	label: str
	source_dir: Path
	stats: Dict[str, float]
	final_ci: float
	final_bonus: float
	final_pps: float
	render_view: str = ""

	@property
	def iso_label(self) -> str:
		return self.timestamp.isoformat(sep=" ", timespec="seconds")


def parse_args() -> argparse.Namespace:
	parser = argparse.ArgumentParser(description="Generate telemetry dashboard HTML or diff replay summaries.")
	parser.add_argument("--input", type=Path, help="Directory containing nightly replay folders.")
	parser.add_argument("--output", type=Path, help="Output HTML file.")
	parser.add_argument(
		"--diff",
		nargs=2,
		metavar=("BASELINE", "CANDIDATE"),
		type=Path,
		help="Compare two summary JSON files (baseline -> candidate) and print metric deltas.",
	)
	args = parser.parse_args()
	if args.diff:
		if args.input or args.output:
			parser.error("--diff cannot be combined with --input/--output.")
	else:
		if args.input is None or args.output is None:
			parser.error("--input and --output are required unless using --diff.")
	return args


def gather_run_directories(base_path: Path) -> List[Path]:
	if not base_path.exists():
		raise FileNotFoundError(f"Input directory not found: {base_path}")
	dirs = sorted([p for p in base_path.iterdir() if p.is_dir()])
	return dirs


def load_summary(summary_path: Path) -> Dict:
	with summary_path.open("r", encoding="utf-8") as handle:
		return json.load(handle)


def _collect_numeric_values(source: Dict[str, object], prefix: str = "") -> Dict[str, float]:
    metrics: Dict[str, float] = {}
    for key, value in source.items():
        if isinstance(value, (int, float)):
            name = f"{prefix}{key}" if prefix else str(key)
            metrics[name] = float(value)
    return metrics


def collect_metrics(payload: Dict) -> Dict[str, float]:
    metrics: Dict[str, float] = {}

    stats = payload.get("stats")
    if isinstance(stats, dict):
        metrics.update(_collect_numeric_values(stats))

    final_block = payload.get("final")
    if isinstance(final_block, dict):
        for key, value in final_block.items():
            if isinstance(value, (int, float)):
                metrics[f"final_{key}"] = float(value)

    summary_block = payload.get("summary")
    if isinstance(summary_block, dict):
        metrics.update({f"summary_{k}": v for k, v in _collect_numeric_values(summary_block).items()})

    metadata_block = payload.get("metadata")
    if isinstance(metadata_block, dict):
        metrics.update({f"meta_{k}": v for k, v in _collect_numeric_values(metadata_block).items()})

    return metrics


def collect_alert_strings(payload: Dict) -> List[str]:
	alerts_raw = payload.get("alerts")
	alerts: List[str] = []
	if isinstance(alerts_raw, list):
		for entry in alerts_raw:
			if isinstance(entry, dict):
				metric = str(entry.get("metric", "metric"))
				value = entry.get("value")
				threshold = entry.get("threshold")
				time_value = entry.get("time")
				alerts.append(
					f"{metric} value={value} threshold={threshold} t={time_value}"
				)
			else:
				alerts.append(str(entry))
	return alerts


def format_number(value: Optional[float], precision: int = 4) -> str:
	if value is None:
		return "—"
	if isinstance(value, float) and (math.isnan(value) or math.isinf(value)):
		return "—"
	return f"{value:.{precision}f}"


def format_percent(value: Optional[float], precision: int = 2) -> str:
	if value is None:
		return "—"
	if isinstance(value, float) and (math.isnan(value) or math.isinf(value)):
		return "—"
	return f"{value:.{precision}f}%"


def run_diff(baseline_path: Path, candidate_path: Path) -> None:
	if not baseline_path.exists():
		raise SystemExit(f"Baseline summary not found: {baseline_path}")
	if not candidate_path.exists():
		raise SystemExit(f"Candidate summary not found: {candidate_path}")
	baseline_data = load_summary(baseline_path)
	candidate_data = load_summary(candidate_path)
	baseline_metrics = collect_metrics(baseline_data)
	candidate_metrics = collect_metrics(candidate_data)
	all_keys = sorted(set(baseline_metrics.keys()) | set(candidate_metrics.keys()))
	if not all_keys:
		print("No comparable numeric metrics found between inputs.")
	else:
		print(f"Telemetry diff\nBaseline : {baseline_path}\nCandidate: {candidate_path}\n")
		header = f"{'Metric':<32} {'Baseline':>12} {'Candidate':>12} {'Δ':>12} {'Δ%':>12}"
		print(header)
		print("-" * len(header))
		for key in all_keys:
			base_value = baseline_metrics.get(key)
			cand_value = candidate_metrics.get(key)
			delta: Optional[float] = None
			delta_pct: Optional[float] = None
			if base_value is not None and cand_value is not None:
				delta = cand_value - base_value
				if base_value != 0:
					delta_pct = (delta / base_value) * 100.0
			print(
				f"{key:<32} "
				f"{format_number(base_value):>12} "
				f"{format_number(cand_value):>12} "
				f"{format_number(delta):>12} "
				f"{format_percent(delta_pct):>12}"
			)

	baseline_alerts = collect_alert_strings(baseline_data)
	candidate_alerts = collect_alert_strings(candidate_data)
	print("\nAlerts:")
	print(f"- Baseline ({len(baseline_alerts)}):")
	if baseline_alerts:
		for entry in baseline_alerts:
			print(f"    • {entry}")
	else:
		print("    • None")
	print(f"- Candidate ({len(candidate_alerts)}):")
	if candidate_alerts:
		for entry in candidate_alerts:
			print(f"    • {entry}")
	else:
		print("    • None")
	new_alerts = sorted(set(candidate_alerts) - set(baseline_alerts))
	if new_alerts:
		print("\nNew alerts introduced:")
		for entry in new_alerts:
			print(f"    • {entry}")

def parse_timestamp(raw: str) -> datetime:
	# Examples: "2025-10-26 15:50:35"
	return datetime.strptime(raw, "%Y-%m-%d %H:%M:%S")


def build_run_record(folder: Path) -> Optional[RunRecord]:
	summary_file = folder / "summary.json"
	if not summary_file.exists():
		return None
	data = load_summary(summary_file)
	stats_raw = data.get("stats")
	if not isinstance(stats_raw, dict):
		return None
	render_view = str(stats_raw.get("sandbox_render_view_mode", "") or "")
	stats_converted: Dict[str, float] = {
		k: float(v) for k, v in stats_raw.items() if isinstance(v, (int, float))
	}
	timestamp_raw = data.get("timestamp")
	if not isinstance(timestamp_raw, str):
		return None
	try:
		timestamp = parse_timestamp(timestamp_raw.strip())
	except ValueError:
		return None
	label = folder.name
	final = data.get("final", {})
	return RunRecord(
		timestamp=timestamp,
		label=label,
		source_dir=folder,
		stats=stats_converted,
		final_ci=float(final.get("ci", 0.0) or 0.0),
		final_bonus=float(final.get("ci_bonus", 0.0) or 0.0),
		final_pps=float(final.get("pps", 0.0) or 0.0),
		render_view=render_view,
	)


def load_runs(base_path: Path) -> List[RunRecord]:
	records: List[RunRecord] = []
	for folder in gather_run_directories(base_path):
		record = build_run_record(folder)
		if record:
			records.append(record)
	return sorted(records, key=lambda run: run.timestamp)


def compute_alerts(records: List[RunRecord], threshold: float = 0.15) -> List[str]:
	alerts: List[str] = []
	if len(records) < 2:
		pass
	key_metrics = [
		("sandbox_tick_ms_p95", "Sandbox p95 tick"),
		("sandbox_render_ms_p95", "Sandbox render p95"),
		("sandbox_render_fallback_ratio", "Sandbox fallback ratio"),
		("environment_tick_ms_p95", "Environment p95 tick"),
		("pps_avg", "Average PPS"),
		("ci_avg", "Average Comfort Index"),
	]
	if len(records) >= 2:
		for prev, current in zip(records[:-1], records[1:]):
			for key, label in key_metrics:
				prev_value = prev.stats.get(key)
				curr_value = current.stats.get(key)
				if prev_value in (None, 0.0):
					continue
				if curr_value is None:
					continue
				diff_ratio = (curr_value - prev_value) / prev_value
				if abs(diff_ratio) >= threshold:
					direction = "increase" if diff_ratio > 0 else "decrease"
					if key == "sandbox_render_fallback_ratio":
						prev_display = prev_value * 100.0
						curr_display = curr_value * 100.0
						alerts.append(
							f"{current.label}: {label} {direction} of {diff_ratio * 100:.1f}% (prev {prev_display:.2f}% → current {curr_display:.2f}%)"
						)
					else:
						alerts.append(
							f"{current.label}: {label} {direction} of {diff_ratio * 100:.1f}% (prev {prev_value:.3f} → current {curr_value:.3f})"
						)
	for run in records:
		eco_tick = run.stats.get("economy_tick_ms_p95")
		if eco_tick is not None and eco_tick > 10.0:
			alerts.append(f"{run.label}: Economy tick p95 {eco_tick:.2f} ms exceeds 10 ms budget")
		eco_ship = run.stats.get("eco_ship_ms_p95")
		if eco_ship is not None and eco_ship > 7.0:
			alerts.append(f"{run.label}: Economy shipment p95 {eco_ship:.2f} ms exceeds 7 ms budget")
	return alerts


def render_metric_cell(value: MetricValue, unit: str = "", precision: int = 3) -> str:
	if value is None:
		return "<td class=\"metric\">—</td>"
	formatted = f"{value:.{precision}f}"
	if unit:
		formatted = f"{formatted} {unit}"
	return f"<td class=\"metric\">{formatted}</td>"


def render_text_cell(value: Optional[str]) -> str:
	if value is None or value.strip() == "":
		return "<td class=\"label\">—</td>"
	return f"<td class=\"label\">{value}</td>"


def build_table_rows(records: Iterable[RunRecord]) -> str:
	rows: List[str] = []
	for run in records:
		fallback_ratio = run.stats.get("sandbox_render_fallback_ratio")
		fallback_percent = fallback_ratio * 100.0 if fallback_ratio is not None else None
		cells = [
			f"<td class=\"label\">{run.label}</td>",
			f"<td class=\"label\">{run.iso_label}</td>",
			render_metric_cell(run.stats.get("sandbox_tick_ms_p95"), "ms"),
			render_metric_cell(run.stats.get("sandbox_render_ms_p95"), "ms"),
			render_metric_cell(fallback_percent, "%", 1),
			render_text_cell(run.render_view),
			render_metric_cell(run.stats.get("environment_tick_ms_p95"), "ms"),
			render_metric_cell(run.stats.get("economy_tick_ms_p95"), "ms"),
			render_metric_cell(run.stats.get("eco_ship_ms_p95"), "ms"),
			render_metric_cell(run.stats.get("pps_avg")),
			render_metric_cell(run.stats.get("ci_avg")),
			render_metric_cell(run.stats.get("power_ratio_avg")),
			render_metric_cell(run.final_ci),
			render_metric_cell(run.final_bonus * 100.0, "%", 2),
			render_metric_cell(run.final_pps),
		]
		rows.append("<tr>" + "".join(cells) + "</tr>")
	return "\n".join(rows)


def build_metric_summary(records: List[RunRecord], key: str) -> Dict[str, float]:
	values = [run.stats.get(key) for run in records if run.stats.get(key) is not None]
	if not values:
		return {"min": math.nan, "max": math.nan, "avg": math.nan}
	return {
		"min": min(values),
		"max": max(values),
		"avg": statistics.fmean(values),
	}


def render_summary_block(records: List[RunRecord]) -> str:
	metrics = [
		("sandbox_tick_ms_p95", "Sandbox Tick p95 (ms)", False),
		("sandbox_render_ms_p95", "Sandbox Render p95 (ms)", False),
		("sandbox_render_fallback_ratio", "Sandbox Fallback (%)", True),
		("environment_tick_ms_p95", "Environment Tick p95 (ms)", False),
		("pps_avg", "PPS Avg", False),
		("ci_avg", "Comfort Index Avg", False),
		("economy_tick_ms_p95", "Economy Tick p95 (ms)", False),
		("eco_ship_ms_p95", "Economy Ship p95 (ms)", False),
	]
	rows: List[str] = []
	for key, label, is_percent in metrics:
		summary = build_metric_summary(records, key)
		if math.isnan(summary["avg"]):
			value_text = "n/a"
		else:
			if is_percent:
				value_text = (
					f"min {summary['min'] * 100.0:.2f}% / "
					f"max {summary['max'] * 100.0:.2f}% / "
					f"avg {summary['avg'] * 100.0:.2f}%"
				)
			else:
				value_text = (
					f"min {summary['min']:.3f} / max {summary['max']:.3f} / avg {summary['avg']:.3f}"
				)
		rows.append(f"<li><strong>{label}:</strong> {value_text}</li>")
	return "<ul class=\"summary-list\">" + "".join(rows) + "</ul>"


def render_alerts(alerts: List[str]) -> str:
	if not alerts:
		return "<p class=\"ok\">No alerts triggered (±15% threshold).</p>"
	items = "".join(f"<li>{entry}</li>" for entry in alerts)
	return f"<ul class=\"alert-list\">{items}</ul>"


def render_dashboard(records: List[RunRecord], alerts: List[str]) -> str:
	headers = [
		"Run ID",
		"Timestamp",
		"Sandbox Tick p95 (ms)",
		"Sandbox Render p95 (ms)",
		"Sandbox Fallback (%)",
		"Sandbox View",
		"Environment p95 (ms)",
		"Economy Tick p95 (ms)",
		"Economy Ship p95 (ms)",
		"PPS Avg",
		"CI Avg",
		"Power Ratio Avg",
		"Final CI",
		"CI Bonus (%)",
		"Final PPS",
	]
	header_html = "".join(f"<th>{title}</th>" for title in headers)
	rows = build_table_rows(records)
	summary_block = render_summary_block(records)
	alert_block = render_alerts(alerts)
	generated_at = datetime.now(UTC).isoformat(timespec="seconds")
	return f"""<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="utf-8">
	<title>Project Yolkless – Nightly Dashboard</title>
	<style>
		body {{ font-family: Arial, sans-serif; margin: 24px; color: #222; background: #f5f5f5; }}
		h1 {{ margin-bottom: 0.2em; }}
		.subtitle {{ color: #666; margin-top: 0; }}
		section {{ background: #fff; padding: 16px 20px; border-radius: 8px; box-shadow: 0 1px 2px rgba(0,0,0,0.08); margin-bottom: 20px; }}
		table {{ width: 100%; border-collapse: collapse; }}
		th, td {{ text-align: left; padding: 8px 10px; }}
		th {{ background: #ececec; font-weight: 600; }}
		tr:nth-child(even) {{ background: #fafafa; }}
		.metric {{ text-align: right; white-space: nowrap; }}
		.label {{ white-space: nowrap; }}
		.ok {{ color: #1f7f3d; font-weight: 600; }}
		.alert-list {{ color: #a94442; }}
		.summary-list {{ margin: 0; padding-left: 20px; }}
	</style>
</head>
<body>
	<h1>Project Yolkless – Nightly Dashboard</h1>
	<p class="subtitle">Generated at {generated_at} UTC • Records: {len(records)}</p>

	<section>
		<h2>Summary</h2>
		<p class="subtitle">Economy budgets: tick ≤ 10&nbsp;ms p95, shipments ≤ 7&nbsp;ms p95.</p>
		{summary_block}
	</section>

	<section>
		<h2>Alerts</h2>
		{alert_block}
	</section>

	<section>
		<h2>Run History</h2>
		<table>
			<thead>
				<tr>
					{header_html}
				</tr>
			</thead>
			<tbody>
				{rows}
			</tbody>
		</table>
	</section>
</body>
</html>
"""


def main() -> None:
	args = parse_args()
	if args.diff:
		run_diff(args.diff[0], args.diff[1])
		return
	records = load_runs(args.input)
	if not records:
		raise SystemExit(f"No replay summaries found under {args.input}")
	alerts = compute_alerts(records)
	html = render_dashboard(records, alerts)
	args.output.parent.mkdir(parents=True, exist_ok=True)
	args.output.write_text(html, encoding="utf-8")


if __name__ == "__main__":
	main()
