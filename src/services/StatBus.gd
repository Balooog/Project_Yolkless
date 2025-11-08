extends Node
class_name StatBus

signal stat_changed(key: StringName, value: Variant, previous: Variant, source: StringName)

const DEFAULT_STACK := "replace"
const CLAMP_LOG_INTERVAL := 60.0

var _registry: Dictionary = {}
var _values: Dictionary = {}
var _last_clamp_log: Dictionary = {}

func register_stat(key: Variant, config: Dictionary = {}) -> void:
	var stat_key: StringName = StringName(key)
	var merged: Dictionary = (_registry.get(stat_key, {}) as Dictionary).duplicate(true)
	for c_key in config.keys():
		merged[c_key] = config[c_key]
	if not merged.has("stack"):
		merged["stack"] = DEFAULT_STACK
	_registry[stat_key] = merged
	if merged.has("default") and not _values.has(stat_key):
		_values[stat_key] = merged["default"]
	elif not _values.has(stat_key):
		_values[stat_key] = 0.0

func get_stat(key: Variant, default_value: float = 0.0) -> float:
	var stat_key: StringName = StringName(key)
	if _values.has(stat_key):
		var stored := _values[stat_key]
		if stored is float or stored is int:
			return float(stored)
	return default_value

func set_stat(key: Variant, value: Variant, source: Variant = StringName()) -> Variant:
	var stat_key: StringName = StringName(key)
	if not _registry.has(stat_key):
		register_stat(stat_key, {})
	var config: Dictionary = _registry[stat_key]
	var target_value: Variant = value
	if config.has("cap") and (target_value is float or target_value is int):
		var cap_value: float = float(config["cap"])
		var numeric_value: float = float(target_value)
		if numeric_value > cap_value:
			if _should_log_clamp(stat_key):
				_log("INFO", "STATBUS", "clamp %s %.3f→%.3f" % [String(stat_key), numeric_value, cap_value], {
					"source": String(source)
				})
			numeric_value = cap_value
		target_value = numeric_value
	var previous: Variant = _values.get(stat_key, null)
	if previous == target_value:
		return target_value
	_values[stat_key] = target_value
	stat_changed.emit(stat_key, target_value, previous, StringName(source))
	return target_value

func add_stat(key: Variant, delta: float, source: Variant = StringName()) -> float:
	var stat_key: StringName = StringName(key)
	var current := get_stat(stat_key, 0.0)
	return set_stat(stat_key, current + delta, source)

func reset_stat(key: Variant) -> void:
	var stat_key: StringName = StringName(key)
	if not _registry.has(stat_key):
		return
	var default_value := _registry[stat_key].get("default", 0.0)
	set_stat(stat_key, default_value, "reset")

func all_stats() -> Dictionary:
	return _values.duplicate(true)

func _should_log_clamp(stat_key: StringName) -> bool:
	var now := Time.get_ticks_usec() / 1_000_000.0
	var last := float(_last_clamp_log.get(stat_key, -INF))
	if now - last >= CLAMP_LOG_INTERVAL:
		_last_clamp_log[stat_key] = now
		return true
	return false

func _log(level: String, category: String, message: String, context: Dictionary = {}) -> void:
	var logger := get_node_or_null("/root/Logger")
	if logger is YolkLogger:
		(logger as YolkLogger).log(level, category, message, context)
