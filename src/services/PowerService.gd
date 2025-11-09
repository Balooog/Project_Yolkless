extends Node
class_name PowerService

signal power_state_changed(state: float)
signal power_warning(level: StringName)

const StatBus := preload("res://src/services/StatBus.gd")
const StatsProbe := preload("res://src/services/StatsProbe.gd")

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

func _ready() -> void:
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
	_update_power_state_stat(_current_state)
	_update_warning_stat(_current_warning_level)

func _register_stats() -> void:
	_statbus = _get_statbus()
	if _statbus == null:
		return
	_statbus.register_stat(&"power_state", {"stack": "replace", "default": 1.0})
	_statbus.register_stat(&"power_warning_level", {"stack": "replace", "default": 0.0})

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
		"power_warning_label": str(_current_warning_level)
	})

func _apply_warning_state(state: float, force_emit: bool) -> void:
	var level: StringName = _calculate_warning_level(state)
	var changed: bool = level != _current_warning_level
	if changed:
		_current_warning_level = level
		_update_warning_stat(level)
		power_warning.emit(level)
	elif force_emit:
		_update_warning_stat(level)

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
