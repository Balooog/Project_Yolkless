extends Node
class_name StatsProbe

signal stats_probe_alert(metric: StringName, value: float, threshold: float)

const OUTPUT_DIR := "user://logs/perf"
const DEFAULT_FLUSH_INTERVAL := 10.0
const CI_DELTA_WARMUP_SAMPLES := 20 # Ignore first ~2 seconds (10 Hz) before flagging CI spikes.
const SANDBOX_TICK_WARMUP_SAMPLES := 12
const SERVICE_SANDBOX := "sandbox"
const SERVICE_ENVIRONMENT := "environment"
const SERVICE_AUTOMATION := "automation"
const SERVICE_POWER := "power"
const SERVICE_ECONOMY := "economy"

var _buffer: Array[Dictionary] = []
var _flush_interval := DEFAULT_FLUSH_INTERVAL
var _last_flush_timestamp := 0.0
var _thresholds := {
	"tick_ms": 1.9,
	"active_cells": 400.0,
	"ci_delta": 0.05
}
var _total_samples := 0
var _service_sample_counts: Dictionary = {}
var _service_thresholds := {
	SERVICE_SANDBOX: 1.9,
	SERVICE_ENVIRONMENT: 0.5,
	SERVICE_AUTOMATION: 1.0,
	SERVICE_POWER: 0.8,
	SERVICE_ECONOMY: 1.5
}
var _pending_writes: Array = []
var _write_scheduled := false

func _ready() -> void:
	set_process(false)

func configure(thresholds: Dictionary = {}, flush_interval: float = DEFAULT_FLUSH_INTERVAL) -> void:
	for key in thresholds.keys():
		_thresholds[key] = thresholds[key]
	_flush_interval = max(1.0, flush_interval)

func record_tick(payload: Dictionary) -> void:
	# Expected payload keys: tick_ms, pps, ci, active_cells, power_ratio, ci_delta
	var service := String(payload.get("service", SERVICE_SANDBOX))
	payload["service"] = service
	_buffer.append(payload)
	_total_samples += 1
	var service_count: int = int(_service_sample_counts.get(service, 0))
	_service_sample_counts[service] = service_count + 1
	_check_thresholds(payload)

func process(delta: float) -> void:
	_last_flush_timestamp += delta
	if _last_flush_timestamp >= _flush_interval and not _buffer.is_empty():
		_flush_buffer()
		_last_flush_timestamp = 0.0

func flush_now() -> void:
	if _buffer.is_empty():
		return
	_flush_buffer()
	_last_flush_timestamp = 0.0

func _check_thresholds(payload: Dictionary) -> void:
	var service := String(payload.get("service", SERVICE_SANDBOX))
	var sample_count: int = int(_service_sample_counts.get(service, 0))
	if payload.has("tick_ms"):
		var service_threshold: float = float(_service_thresholds.get(service, _thresholds["tick_ms"]))
		var within_warmup: bool = service == SERVICE_SANDBOX and sample_count <= SANDBOX_TICK_WARMUP_SAMPLES
		if payload["tick_ms"] > service_threshold and not within_warmup:
			var metric_name := "%s_tick_ms" % service
			stats_probe_alert.emit(StringName(metric_name), payload["tick_ms"], service_threshold)
	if service == SERVICE_SANDBOX:
		if payload.has("active_cells") and payload["active_cells"] > _thresholds["active_cells"]:
			stats_probe_alert.emit("active_cells", payload["active_cells"], _thresholds["active_cells"])
		if payload.has("ci_delta"):
			if sample_count > CI_DELTA_WARMUP_SAMPLES and abs(payload["ci_delta"]) > _thresholds["ci_delta"]:
				stats_probe_alert.emit("ci_delta", payload["ci_delta"], _thresholds["ci_delta"])


func _flush_buffer() -> void:
	var dir := DirAccess.open(OUTPUT_DIR)
	if dir == null:
		DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
	var timestamp := Time.get_datetime_string_from_system(true, true).replace(":", "")
	var path := "%s/tick_%s.csv" % [OUTPUT_DIR, timestamp]
	var rows: Array = []
	for row in _buffer:
		rows.append((row as Dictionary).duplicate(true))
	var payload := {
		"path": path,
		"rows": rows
	}
	_pending_writes.append(payload)
	_buffer.clear()
	_service_sample_counts.clear()
	if not _write_scheduled:
		_write_scheduled = true
		call_deferred("_process_pending_writes")

func _process_pending_writes() -> void:
	while not _pending_writes.is_empty():
		var entry: Dictionary = _pending_writes[0] as Dictionary
		_pending_writes.remove_at(0)
		var path: String = String(entry.get("path", ""))
		var rows: Array = entry.get("rows", [])
		if path == "" or rows.is_empty():
			continue
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			push_warning("StatsProbe: Failed to open %s for writing" % path)
			continue
		file.store_line("service,tick_ms,pps,ci,active_cells,power_ratio,ci_delta,storage,feed_fraction,power_state,auto_active")
		for row_variant in rows:
			var row_dict: Dictionary = row_variant
			var csv := "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s" % [
				row_dict.get("service", SERVICE_SANDBOX),
				row_dict.get("tick_ms", 0.0),
				row_dict.get("pps", 0.0),
				row_dict.get("ci", 0.0),
				row_dict.get("active_cells", 0.0),
				row_dict.get("power_ratio", 0.0),
				row_dict.get("ci_delta", 0.0),
				row_dict.get("storage", 0.0),
				row_dict.get("feed_fraction", 0.0),
				row_dict.get("power_state", 0.0),
				row_dict.get("auto_active", 0)
			]
			file.store_line(csv)
		file.close()
	_write_scheduled = false

func summarize() -> Dictionary:
	# Lightweight statistics for telemetry aggregation.
	if _buffer.is_empty():
		return {}
	var grouped: Dictionary = {}
	for entry in _buffer:
		var service := String(entry.get("service", SERVICE_SANDBOX))
		if not grouped.has(service):
			grouped[service] = {
				"tick_values": [],
				"tick_sum": 0.0,
				"count": 0,
				"pps_accum": 0.0,
				"ci_accum": 0.0,
				"power_accum": 0.0,
				"ci_delta_accum": 0.0,
				"ci_delta_abs_max": 0.0,
				"active_cells_max": 0.0,
				"storage_accum": 0.0,
				"feed_fraction_accum": 0.0,
				"power_state_accum": 0.0,
				"auto_active_accum": 0.0
			}
		var group: Dictionary = grouped[service]
		var tick_value: float = float(entry.get("tick_ms", 0.0))
		group["tick_values"].append(tick_value)
		group["tick_sum"] += tick_value
		group["count"] = int(group["count"]) + 1
		if service == SERVICE_SANDBOX:
			group["pps_accum"] += entry.get("pps", 0.0)
			group["ci_accum"] += entry.get("ci", 0.0)
			group["power_accum"] += entry.get("power_ratio", 0.0)
			group["active_cells_max"] = max(group["active_cells_max"], entry.get("active_cells", 0.0))
			var delta_value: float = entry.get("ci_delta", 0.0)
			group["ci_delta_accum"] += delta_value
			group["ci_delta_abs_max"] = max(group["ci_delta_abs_max"], abs(delta_value))
		elif service == SERVICE_ECONOMY:
			group["pps_accum"] += entry.get("pps", 0.0)
			group["storage_accum"] += entry.get("storage", 0.0)
			group["feed_fraction_accum"] += entry.get("feed_fraction", 0.0)
		elif service == SERVICE_POWER:
			group["power_state_accum"] += entry.get("power_state", entry.get("power_ratio", 0.0))
		elif service == SERVICE_AUTOMATION:
			group["auto_active_accum"] += entry.get("auto_active", 0)
		grouped[service] = group

	var summary := {}
	for service in grouped.keys():
		var group: Dictionary = grouped[service]
		var tick_values: Array = group["tick_values"] as Array
		tick_values.sort()
		var p95: float = 0.0
		if tick_values.size() > 0:
			var index := int(round(0.95 * (tick_values.size() - 1)))
			p95 = float(tick_values[index])
		var count_float: float = max(float(group["count"]), 1.0)
		var avg: float = float(group["tick_sum"]) / count_float
		match service:
			SERVICE_SANDBOX:
				summary["sandbox_tick_ms_p95"] = p95
				summary["sandbox_tick_ms_avg"] = avg
				summary["pps_avg"] = float(group["pps_accum"]) / count_float
				summary["ci_avg"] = float(group["ci_accum"]) / count_float
				summary["power_ratio_avg"] = float(group["power_accum"]) / count_float
				summary["active_cells_max"] = float(group["active_cells_max"])
				summary["ci_delta_abs_max"] = float(group["ci_delta_abs_max"])
				summary["ci_delta_avg"] = float(group["ci_delta_accum"]) / count_float
			SERVICE_ENVIRONMENT:
				summary["environment_tick_ms_p95"] = p95
				summary["environment_tick_ms_avg"] = avg
			SERVICE_AUTOMATION:
				summary["automation_tick_ms_p95"] = p95
				summary["automation_tick_ms_avg"] = avg
				summary["automation_auto_active_avg"] = float(group["auto_active_accum"]) / count_float
			SERVICE_POWER:
				summary["power_tick_ms_p95"] = p95
				summary["power_tick_ms_avg"] = avg
				summary["power_state_avg"] = float(group["power_state_accum"]) / count_float
			SERVICE_ECONOMY:
				summary["economy_tick_ms_p95"] = p95
				summary["economy_tick_ms_avg"] = avg
				summary["economy_pps_avg"] = float(group["pps_accum"]) / count_float
				summary["economy_storage_avg"] = float(group["storage_accum"]) / count_float
				summary["economy_feed_fraction_avg"] = float(group["feed_fraction_accum"]) / count_float
			_:
				summary["%s_tick_ms_p95" % service] = p95
				summary["%s_tick_ms_avg" % service] = avg
	return summary
