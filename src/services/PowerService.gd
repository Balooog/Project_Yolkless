extends Node
class_name PowerService

signal power_state_changed(state: float)
signal power_warning(level: StringName)

const StatBus := preload("res://src/services/StatBus.gd")
const StatsProbe := preload("res://src/services/StatsProbe.gd")
const POWER_CONFIG_PATH := "res://data/power_config.json"

const WARNING_NORMAL := StringName("normal")
const WARNING_WARNING := StringName("warning")
const WARNING_CRITICAL := StringName("critical")

var _statbus: StatBus
var _current_state: float = 1.0
var _base_state: float = 1.0
var _warning_threshold: float = 0.7
var _critical_threshold: float = 0.4
var _stats_probe: StatsProbe
var _current_warning_level: StringName = WARNING_NORMAL
var _power_multiplier: float = 1.0
var _warning_episode_active := false
var _warning_episode_start_msec: int = 0
var _warning_episode_min_ratio: float = 1.0
var _warning_episode_count: int = 0
var _last_warning_min_ratio: float = 1.0
var _warning_episode_level: StringName = WARNING_NORMAL

func _ready() -> void:
	_load_config()
	_statbus = _get_statbus()
	_register_stats()
	_update_power_state_stat(_current_state)
	_update_warning_stat(_current_warning_level)
	_stats_probe = _get_stats_probe()

func set_thresholds(warning: float, critical: float) -> void:
	_warning_threshold = clamp(warning, 0.0, 1.0)
	_critical_threshold = clamp(critical, 0.0, _warning_threshold)
	_apply_warning_state(_current_state, true)

func update_power_state(state: float) -> void:
	var tick_start := Time.get_ticks_usec()
	_base_state = clamp(state, 0.0, 1.5)
	var scaled := _scaled_state()
	var delta: float = abs(scaled - _current_state)
	if delta > 0.0001:
		_current_state = scaled
		_update_power_state_stat(scaled)
		power_state_changed.emit(scaled)
	_apply_warning_state(scaled, false)
	_record_stats_probe(float(Time.get_ticks_usec() - tick_start) / 1000.0, scaled)

func current_state() -> float:
	return _current_state

func set_power_multiplier(mult: float) -> void:
	var clamped = clamp(mult, 0.0, 2.0)
	if abs(clamped - _power_multiplier) <= 0.0001:
		return
	_power_multiplier = clamped
	_reapply_power_multiplier()

func get_power_multiplier() -> float:
	return _power_multiplier

func current_warning_level() -> StringName:
	return _current_warning_level

func reset() -> void:
	_current_state = 1.0
	_base_state = 1.0
	_power_multiplier = 1.0
	_current_warning_level = WARNING_NORMAL
	_warning_episode_active = false
	_warning_episode_start_msec = 0
	_warning_episode_min_ratio = 1.0
	_last_warning_min_ratio = 1.0
	_warning_episode_count = 0
	_warning_episode_level = WARNING_NORMAL
	_update_power_state_stat(_current_state)
	_update_warning_stat(_current_warning_level)
	_update_warning_episode_stat()

func _register_stats() -> void:
	_statbus = _get_statbus()
	if _statbus == null:
		return
	_statbus.register_stat(&"power_state", {"stack": "replace", "default": 1.0})
	_statbus.register_stat(&"power_warning_level", {"stack": "replace", "default": 0.0})
	_statbus.register_stat(&"power_warning_episodes", {"stack": "replace", "default": 0.0})

func _update_power_state_stat(value: float) -> void:
	_statbus = _get_statbus()
	if _statbus == null:
		return
	_statbus.set_stat(&"power_state", value, "PowerService")

func _update_warning_stat(level: StringName) -> void:
	_statbus = _get_statbus()
	if _statbus == null:
		return
	_statbus.set_stat(&"power_warning_level", _warning_level_value(level), "PowerService")

func _update_warning_episode_stat() -> void:
	_statbus = _get_statbus()
	if _statbus == null:
		return
	_statbus.set_stat(&"power_warning_episodes", float(_warning_episode_count), "PowerService")

func _get_statbus() -> StatBus:
	if _statbus and is_instance_valid(_statbus):
		return _statbus
	var node := get_node_or_null("/root/StatBusSingleton")
	if node is StatBus:
		_statbus = node as StatBus
		return _statbus
	return null

func _get_stats_probe() -> StatsProbe:
	var node := get_node_or_null("/root/StatsProbeSingleton")
	if node is StatsProbe:
		return node as StatsProbe
	return null

func _record_stats_probe(tick_ms: float, state: float) -> void:
	if _stats_probe == null or not is_instance_valid(_stats_probe):
		_stats_probe = _get_stats_probe()
	if _stats_probe == null:
		return
	_stats_probe.record_tick({
		"service": "power",
		"tick_ms": tick_ms,
		"power_state": state,
		"power_warning_level": _warning_level_value(_current_warning_level),
		"power_warning_label": str(_current_warning_level),
		"power_warning_count": _warning_episode_count,
		"power_warning_duration": _current_warning_duration(),
		"power_warning_min_ratio": _current_warning_min_ratio()
	})

func _apply_warning_state(state: float, force_emit: bool) -> void:
	var level: StringName = _calculate_warning_level(state)
	var changed: bool = level != _current_warning_level
	if changed:
		_handle_warning_transition(level, state)
		_current_warning_level = level
		_update_warning_stat(level)
		power_warning.emit(level)
	elif force_emit:
		_update_warning_stat(level)
	if _warning_episode_active:
		_warning_episode_min_ratio = min(_warning_episode_min_ratio, state)

func _handle_warning_transition(level: StringName, state: float) -> void:
	if level == WARNING_NORMAL:
		if _warning_episode_active:
			_finalize_warning_episode()
		return
	if not _warning_episode_active:
		_start_warning_episode(level, state)
	else:
		_warning_episode_level = level

func _start_warning_episode(level: StringName, state: float) -> void:
	_warning_episode_active = true
	_warning_episode_start_msec = Time.get_ticks_msec()
	_warning_episode_min_ratio = state
	_warning_episode_level = level
	_warning_episode_count += 1
	_update_warning_episode_stat()

func _finalize_warning_episode() -> void:
	var duration := _current_warning_duration()
	var min_ratio := _warning_episode_min_ratio
	_warning_episode_active = false
	_warning_episode_min_ratio = 1.0
	_last_warning_min_ratio = min_ratio
	_record_warning_event(_warning_episode_level, duration, min_ratio)
	_warning_episode_level = WARNING_NORMAL

func _calculate_warning_level(state: float) -> StringName:
	if state <= _critical_threshold:
		return WARNING_CRITICAL
	if state <= _warning_threshold:
		return WARNING_WARNING
	return WARNING_NORMAL

func _warning_level_value(level: StringName) -> float:
	match level:
		WARNING_CRITICAL:
			return 2.0
		WARNING_WARNING:
			return 1.0
		_:
			return 0.0

func _current_warning_duration() -> float:
	if not _warning_episode_active:
		return 0.0
	return float(Time.get_ticks_msec() - _warning_episode_start_msec) / 1000.0

func _current_warning_min_ratio() -> float:
	if _warning_episode_active:
		return _warning_episode_min_ratio
	return _last_warning_min_ratio

func _scaled_state() -> float:
	return clamp(_base_state * _power_multiplier, 0.0, 1.5)

func _reapply_power_multiplier() -> void:
	var scaled := _scaled_state()
	if abs(scaled - _current_state) <= 0.0001:
		return
	_current_state = scaled
	_update_power_state_stat(_current_state)
	power_state_changed.emit(_current_state)
	_apply_warning_state(_current_state, true)
	_record_stats_probe(0.0, _current_state)

func _record_warning_event(level: StringName, duration: float, min_ratio: float) -> void:
	if duration <= 0.0:
		return
	if _stats_probe == null or not is_instance_valid(_stats_probe):
		_stats_probe = _get_stats_probe()
	if _stats_probe == null:
		return
	_stats_probe.event_log({
		"event_id": "power_warning_%s" % String(level),
		"kind": "duration=%.2f|min=%.2f" % [duration, min_ratio],
		"ts": Time.get_unix_time_from_system()
	})

func _load_config() -> void:
	var file := FileAccess.open(POWER_CONFIG_PATH, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var data: Dictionary = parsed
	var warning_value: float = clamp(float(data.get("warning_threshold", _warning_threshold)), 0.0, 1.0)
	var critical_value: float = clamp(float(data.get("critical_threshold", _critical_threshold)), 0.0, warning_value)
	_warning_threshold = warning_value
	_critical_threshold = critical_value
