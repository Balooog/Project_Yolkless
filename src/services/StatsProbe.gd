extends Node
class_name StatsProbe

signal stats_probe_alert(metric: StringName, value: float, threshold: float)

const OUTPUT_DIR := "user://logs/perf"
const EVENT_LOG_PATH := OUTPUT_DIR + "/event_log.csv"
const DEFAULT_FLUSH_INTERVAL := 10.0
const CI_DELTA_WARMUP_SAMPLES := 20 # Ignore first ~2 seconds (10 Hz) before flagging CI spikes.
const SANDBOX_TICK_WARMUP_SAMPLES := 12
const SERVICE_SANDBOX := "sandbox"
const SERVICE_ENVIRONMENT := "environment"
const SERVICE_AUTOMATION := "automation"
const SERVICE_POWER := "power"
const SERVICE_ECONOMY := "economy"
const SERVICE_SANDBOX_RENDER := "sandbox_render"

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
	SERVICE_ECONOMY: 1.5,
	SERVICE_SANDBOX_RENDER: 1.0
}
var _pending_writes: Array = []
var _write_scheduled := false
var _event_log_queue: Array[Dictionary] = []
var _event_log_write_scheduled := false

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

func event_log(payload: Dictionary) -> void:
	var entry = {
		"ts": payload.get("ts", Time.get_unix_time_from_system()),
		"event_id": String(payload.get("event_id", "")),
		"kind": String(payload.get("kind", "")),
	}
	_event_log_queue.append(entry)
	if not _event_log_write_scheduled:
		_event_log_write_scheduled = true
		call_deferred("_flush_event_log")

func _check_thresholds(payload: Dictionary) -> void:
	var service := String(payload.get("service", SERVICE_SANDBOX))
	var sample_count: int = int(_service_sample_counts.get(service, 0))
	if payload.has("tick_ms"):
		var service_threshold: float = float(_service_thresholds.get(service, _thresholds["tick_ms"]))
		var within_warmup: bool = service == SERVICE_SANDBOX or service == SERVICE_SANDBOX_RENDER
		if within_warmup:
			within_warmup = sample_count <= SANDBOX_TICK_WARMUP_SAMPLES
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
		file.store_line("service,tick_ms,pps,ci,active_cells,power_ratio,ci_delta,storage,feed_fraction,power_state,power_warning_level,power_warning_label,power_warning_count,power_warning_duration,power_warning_min_ratio,auto_active,sandbox_render_view_mode,sandbox_render_fallback_active,stage_rebuild_ms,stage_rebuild_source,eco_in_ms,eco_apply_ms,eco_ship_ms,eco_research_ms,eco_statbus_ms,eco_ui_ms,economy_rate,economy_rate_label,conveyor_backlog,conveyor_backlog_label,automation_target,automation_target_label,automation_panel_visible,tier,event_id")
		for row_variant in rows:
			var row_dict: Dictionary = row_variant
			var fallback_flag: int = 1 if row_dict.get("sandbox_render_fallback_active", false) else 0
			var view_mode_value: String = String(row_dict.get("sandbox_render_view_mode", ""))
			var economy_rate_value: float = float(row_dict.get("economy_rate", row_dict.get("pps", 0.0)))
			var economy_rate_label_value: String = String(row_dict.get("economy_rate_label", ""))
			if economy_rate_label_value == "":
				economy_rate_label_value = _format_rate_label(economy_rate_value)
			var backlog_value: float = float(row_dict.get("conveyor_backlog", row_dict.get("conveyor_queue", 0.0)))
			var backlog_label_value: String = String(row_dict.get("conveyor_backlog_label", ""))
			if backlog_label_value == "":
				backlog_label_value = _format_backlog_label(backlog_value)
			var automation_target_value: float = float(row_dict.get("automation_target", 0.0))
			var automation_target_label_value: String = String(row_dict.get("automation_target_label", ""))
			var automation_panel_visible_value: float = float(row_dict.get("automation_panel_visible", 0.0))
			var tier_value: int = int(row_dict.get("tier", 0))
			var event_id_value: String = String(row_dict.get("event_id", ""))
			var csv_fields: Array = [
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
				row_dict.get("power_warning_level", 0.0),
				row_dict.get("power_warning_label", ""),
				row_dict.get("power_warning_count", 0.0),
				row_dict.get("power_warning_duration", 0.0),
				row_dict.get("power_warning_min_ratio", 0.0),
				row_dict.get("auto_active", 0),
				view_mode_value,
				fallback_flag,
				row_dict.get("stage_rebuild_ms", 0.0),
				row_dict.get("stage_rebuild_source", ""),
				row_dict.get("eco_in_ms", 0.0),
				row_dict.get("eco_apply_ms", 0.0),
				row_dict.get("eco_ship_ms", 0.0),
				row_dict.get("eco_research_ms", 0.0),
				row_dict.get("eco_statbus_ms", 0.0),
				row_dict.get("eco_ui_ms", 0.0),
				economy_rate_value,
				economy_rate_label_value,
				backlog_value,
				backlog_label_value,
				automation_target_value,
				automation_target_label_value,
				automation_panel_visible_value,
				tier_value,
				event_id_value
			]
			file.store_line(_csv_join(csv_fields))
		file.close()
	_write_scheduled = false
	if _event_log_write_scheduled:
		_flush_event_log()

func _flush_event_log() -> void:
	if _event_log_queue.is_empty():
		_event_log_write_scheduled = false
		return
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
	var file_exists = FileAccess.file_exists(EVENT_LOG_PATH)
	var open_mode := FileAccess.READ_WRITE if file_exists else FileAccess.WRITE
	var file := FileAccess.open(EVENT_LOG_PATH, open_mode)
	if file == null:
		push_warning("StatsProbe: Failed to open %s for event log" % EVENT_LOG_PATH)
		_event_log_queue.clear()
		_event_log_write_scheduled = false
		return
	if file_exists:
		file.seek_end()
	else:
		file.store_line("ts,event_id,kind")
	for entry in _event_log_queue:
		var ts_value = entry.get("ts", Time.get_unix_time_from_system())
		var event_id = _sanitize_csv_field(String(entry.get("event_id", "")))
		var kind = _sanitize_csv_field(String(entry.get("kind", "")))
		file.store_line("%s,%s,%s" % [ts_value, event_id, kind])
	file.close()
	_event_log_queue.clear()
	_event_log_write_scheduled = false

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
				"auto_active_accum": 0.0,
				"fallback_samples": 0,
				"fallback_active_samples": 0,
				"view_mode_last": "",
				"stage_rebuild_ms_max": 0.0,
				"stage_rebuild_source_last": "",
				"eco_in_values": [],
				"eco_apply_values": [],
				"eco_ship_values": [],
				"eco_research_values": [],
				"eco_statbus_values": [],
				"eco_ui_values": [],
				"economy_rate_values": [],
				"conveyor_backlog_values": [],
				"economy_rate_label_last": "",
				"conveyor_backlog_label_last": "",
				"automation_target_values": [],
				"automation_target_label_last": "",
				"automation_panel_visible_samples": 0,
				"tier_last": 0,
				"event_id_last": ""
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
		elif service == SERVICE_ENVIRONMENT:
			var stage_ms: float = float(entry.get("stage_rebuild_ms", 0.0))
			if stage_ms > float(group.get("stage_rebuild_ms_max", 0.0)):
				group["stage_rebuild_ms_max"] = stage_ms
				group["stage_rebuild_source_last"] = String(entry.get("stage_rebuild_source", group.get("stage_rebuild_source_last", "")))
		elif service == SERVICE_ECONOMY:
			group["pps_accum"] += entry.get("pps", 0.0)
			group["storage_accum"] += entry.get("storage", 0.0)
			group["feed_fraction_accum"] += entry.get("feed_fraction", 0.0)
			var econ_value: float = float(entry.get("economy_rate", entry.get("pps", 0.0)))
			var backlog_value: float = float(entry.get("conveyor_backlog", entry.get("conveyor_queue", 0.0)))
			(group["economy_rate_values"] as Array).append(econ_value)
			(group["conveyor_backlog_values"] as Array).append(backlog_value)
			var econ_label: String = String(entry.get("economy_rate_label", group.get("economy_rate_label_last", "")))
			if econ_label == "":
				econ_label = _format_rate_label(econ_value)
			group["economy_rate_label_last"] = econ_label
			var backlog_label: String = String(entry.get("conveyor_backlog_label", group.get("conveyor_backlog_label_last", "")))
			if backlog_label == "":
				backlog_label = _format_backlog_label(backlog_value)
			group["conveyor_backlog_label_last"] = backlog_label
			(group["eco_in_values"] as Array).append(float(entry.get("eco_in_ms", 0.0)))
			(group["eco_apply_values"] as Array).append(float(entry.get("eco_apply_ms", 0.0)))
			(group["eco_ship_values"] as Array).append(float(entry.get("eco_ship_ms", 0.0)))
			(group["eco_research_values"] as Array).append(float(entry.get("eco_research_ms", 0.0)))
			(group["eco_statbus_values"] as Array).append(float(entry.get("eco_statbus_ms", 0.0)))
			(group["eco_ui_values"] as Array).append(float(entry.get("eco_ui_ms", 0.0)))
			group["tier_last"] = int(entry.get("tier", group.get("tier_last", 0)))
			group["event_id_last"] = String(entry.get("event_id", group.get("event_id_last", "")))
		elif service == SERVICE_POWER:
			group["power_state_accum"] += entry.get("power_state", entry.get("power_ratio", 0.0))
		elif service == SERVICE_AUTOMATION:
			group["auto_active_accum"] += entry.get("auto_active", 0)
			var target_value: float = float(entry.get("automation_target", 0.0))
			(group["automation_target_values"] as Array).append(target_value)
			var target_label: String = String(entry.get("automation_target_label", group.get("automation_target_label_last", "")))
			group["automation_target_label_last"] = target_label
			if float(entry.get("automation_panel_visible", 0.0)) > 0.5:
				group["automation_panel_visible_samples"] = int(group.get("automation_panel_visible_samples", 0)) + 1
		elif service == SERVICE_SANDBOX_RENDER:
			group["fallback_samples"] = int(group["fallback_samples"]) + 1
			if entry.get("sandbox_render_fallback_active", false):
				group["fallback_active_samples"] = int(group["fallback_active_samples"]) + 1
			group["view_mode_last"] = String(entry.get("sandbox_render_view_mode", group["view_mode_last"]))
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
				summary["environment_stage_rebuild_ms_max"] = float(group.get("stage_rebuild_ms_max", 0.0))
				summary["environment_stage_rebuild_source_last"] = String(group.get("stage_rebuild_source_last", ""))
			SERVICE_AUTOMATION:
				summary["automation_tick_ms_p95"] = p95
				summary["automation_tick_ms_avg"] = avg
				summary["automation_auto_active_avg"] = float(group["auto_active_accum"]) / count_float
				var target_values := group["automation_target_values"] as Array
				if target_values.is_empty():
					summary["automation_target_value_last"] = 0.0
				else:
					summary["automation_target_value_last"] = float(target_values[target_values.size() - 1])
				summary["automation_target_last"] = String(group.get("automation_target_label_last", ""))
				var visible_samples := float(group.get("automation_panel_visible_samples", 0))
				summary["automation_panel_visible_ratio"] = visible_samples / count_float
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
				var eco_in_values := group["eco_in_values"] as Array
				var eco_apply_values := group["eco_apply_values"] as Array
				var eco_ship_values := group["eco_ship_values"] as Array
				var eco_research_values := group["eco_research_values"] as Array
				var eco_statbus_values := group["eco_statbus_values"] as Array
				var eco_ui_values := group["eco_ui_values"] as Array
				summary["eco_in_ms_p95"] = _profiling_p95(eco_in_values)
				summary["eco_in_ms_avg"] = _profiling_avg(eco_in_values)
				summary["eco_apply_ms_p95"] = _profiling_p95(eco_apply_values)
				summary["eco_apply_ms_avg"] = _profiling_avg(eco_apply_values)
				summary["eco_ship_ms_p95"] = _profiling_p95(eco_ship_values)
				summary["eco_ship_ms_avg"] = _profiling_avg(eco_ship_values)
				summary["eco_research_ms_p95"] = _profiling_p95(eco_research_values)
				summary["eco_research_ms_avg"] = _profiling_avg(eco_research_values)
				summary["eco_statbus_ms_p95"] = _profiling_p95(eco_statbus_values)
				summary["eco_statbus_ms_avg"] = _profiling_avg(eco_statbus_values)
				summary["eco_ui_ms_p95"] = _profiling_p95(eco_ui_values)
				summary["eco_ui_ms_avg"] = _profiling_avg(eco_ui_values)
				summary["economy_rate_avg"] = _profiling_avg(group["economy_rate_values"])
				summary["economy_rate_label_last"] = String(group.get("economy_rate_label_last", ""))
				summary["conveyor_backlog_avg"] = _profiling_avg(group["conveyor_backlog_values"])
				summary["conveyor_backlog_label_last"] = String(group.get("conveyor_backlog_label_last", ""))
				summary["tier_progress_last"] = int(group.get("tier_last", 0))
				summary["event_id_last"] = String(group.get("event_id_last", ""))
			SERVICE_SANDBOX_RENDER:
				summary["sandbox_render_ms_p95"] = p95
				summary["sandbox_render_ms_avg"] = avg
				var render_samples: float = max(float(group["fallback_samples"]), 1.0)
				summary["sandbox_render_fallback_ratio"] = float(group["fallback_active_samples"]) / render_samples
				summary["sandbox_render_view_mode"] = String(group["view_mode_last"])
			_:
				summary["%s_tick_ms_p95" % service] = p95
				summary["%s_tick_ms_avg" % service] = avg
	return summary

func _sanitize_csv_field(value: String) -> String:
	if value.find("\"") != -1:
		value = value.replace("\"", "\"\"")
	if value.find(",") != -1:
		value = "\"%s\"" % value
	return value

func _profiling_p95(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var sorted := values.duplicate()
	sorted.sort()
	var index := int(round(0.95 * float(sorted.size() - 1)))
	return float(sorted[index])

func _profiling_avg(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var sum := 0.0
	for value in values:
		sum += float(value)
	return sum / float(values.size())

func _format_rate_label(value: float) -> String:
	var decimals := 1
	if abs(value) >= 10.0:
		decimals = 0
	return "%s/s" % String.num(value, decimals)

func _format_backlog_label(value: float) -> String:
	return "Queue %d" % int(round(value))

func _csv_join(fields: Array) -> String:
	var segments := PackedStringArray()
	for value in fields:
		var text := _normalize_csv_field(value)
		if text.find("\"") != -1:
			text = text.replace("\"", "\"\"")
		if text.find(",") != -1 or text.find("\n") != -1 or text.find("\r") != -1:
			text = "\"%s\"" % text
		segments.append(text)
	return ",".join(segments)

func _normalize_csv_field(value: Variant) -> String:
	match typeof(value):
		TYPE_NIL:
			return ""
		TYPE_STRING_NAME:
			return String(value)
		TYPE_DICTIONARY, TYPE_ARRAY:
			return JSON.stringify(value)
		_:
			return str(value)
