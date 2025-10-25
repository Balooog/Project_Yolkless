extends Node
class_name PowerService

signal power_state_changed(state: float)
signal power_warning(level: StringName)

const StatBus := preload("res://src/services/StatBus.gd")
const StatsProbe := preload("res://src/services/StatsProbe.gd")

var _statbus: StatBus
var _current_state: float = 1.0
var _warning_threshold: float = 0.7
var _critical_threshold: float = 0.4
var _stats_probe: StatsProbe

func _ready() -> void:
	_statbus = _get_statbus()
	_register_stat()
	_update_statbus(_current_state)
	_stats_probe = _get_stats_probe()

func set_thresholds(warning: float, critical: float) -> void:
	_warning_threshold = clamp(warning, 0.0, 1.0)
	_critical_threshold = clamp(critical, 0.0, _warning_threshold)

func update_power_state(state: float) -> void:
	var tick_start := Time.get_ticks_usec()
	var clamped: float = clamp(state, 0.0, 1.5)
	if abs(clamped - _current_state) <= 0.0001:
		_record_stats_probe(float(Time.get_ticks_usec() - tick_start) / 1000.0, clamped)
		return
	_current_state = clamped
	_update_statbus(clamped)
	power_state_changed.emit(clamped)
	if clamped <= _critical_threshold:
		power_warning.emit(StringName("critical"))
	elif clamped <= _warning_threshold:
		power_warning.emit(StringName("warning"))
	_record_stats_probe(float(Time.get_ticks_usec() - tick_start) / 1000.0, clamped)

func current_state() -> float:
	return _current_state

func reset() -> void:
	_current_state = 1.0
	_update_statbus(_current_state)

func _register_stat() -> void:
	_statbus = _get_statbus()
	if _statbus == null:
		return
	_statbus.register_stat(&"power_state", {"stack": "replace", "default": 1.0})

func _update_statbus(value: float) -> void:
	_statbus = _get_statbus()
	if _statbus == null:
		return
	_statbus.set_stat(&"power_state", value, "PowerService")

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
		"power_state": state
	})
