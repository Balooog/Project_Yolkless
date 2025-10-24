extends Node
class_name PowerService

signal power_state_changed(state: float)
signal power_warning(level: StringName)

const StatBus := preload("res://src/services/StatBus.gd")

var _statbus: StatBus
var _current_state: float = 1.0
var _warning_threshold: float = 0.7
var _critical_threshold: float = 0.4

func _ready() -> void:
	_statbus = _get_statbus()
	_register_stat()
	_update_statbus(_current_state)

func set_thresholds(warning: float, critical: float) -> void:
	_warning_threshold = clamp(warning, 0.0, 1.0)
	_critical_threshold = clamp(critical, 0.0, _warning_threshold)

func update_power_state(state: float) -> void:
	var clamped: float = clamp(state, 0.0, 1.5)
	if abs(clamped - _current_state) <= 0.0001:
		return
	_current_state = clamped
	_update_statbus(clamped)
	power_state_changed.emit(clamped)
	if clamped <= _critical_threshold:
		power_warning.emit(StringName("critical"))
	elif clamped <= _warning_threshold:
		power_warning.emit(StringName("warning"))

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
