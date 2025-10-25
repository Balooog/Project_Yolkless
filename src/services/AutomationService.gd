extends Node
class_name AutomationService

signal mode_changed(building_id: StringName, mode: int)
signal auto_burst_enqueued()

const MODE_OFF := 0
const MODE_MANUAL := 1
const MODE_AUTO := 2

const StatBus := preload("res://src/services/StatBus.gd")
const StatsProbe := preload("res://src/services/StatsProbe.gd")

var _statbus: StatBus
var _targets: Dictionary = {}
var _global_enabled := true
var _power_ok := true
var _use_scheduler := false
var _stats_probe: StatsProbe

func _ready() -> void:
	_statbus = _get_statbus()
	_register_stat()
	_stats_probe = _get_stats_probe()
	set_process(true)

func register_autoburst(id: Variant, interval: float, callable: Callable, initial_mode: int = MODE_MANUAL) -> void:
	var key := StringName(id)
	_targets[key] = {
		"mode": clamp(initial_mode, MODE_OFF, MODE_AUTO),
		"interval": max(interval, 0.1),
		"elapsed": 0.0,
		"callable": callable
	}
	_emit_mode(key)
	_update_statbus()

func has_target(id: Variant) -> bool:
	return _targets.has(StringName(id))

func update_interval(id: Variant, interval: float) -> void:
	var key := StringName(id)
	if not _targets.has(key):
		return
	_targets[key]["interval"] = max(interval, 0.1)

func set_mode(id: Variant, mode: int) -> void:
	var key := StringName(id)
	if not _targets.has(key):
		return
	var clamped: int = clamp(mode, MODE_OFF, MODE_AUTO)
	if int(_targets[key]["mode"]) == clamped:
		return
	_targets[key]["mode"] = clamped
	_emit_mode(key)
	_update_statbus()

func get_mode(id: Variant) -> int:
	var key := StringName(id)
	if not _targets.has(key):
		return MODE_OFF
	return int(_targets[key]["mode"])

func set_global_enabled(enabled: bool) -> void:
	_global_enabled = enabled
	_update_statbus()

func is_global_enabled() -> bool:
	return _global_enabled

func set_power_state(state: float) -> void:
	var ok: bool = state >= 0.5
	if ok == _power_ok:
		return
	_power_ok = ok
	_update_statbus()

func set_scheduler_enabled(enabled: bool) -> void:
	_use_scheduler = enabled
	set_process(not _use_scheduler)

func step(delta: float) -> void:
	_process_tick(delta)

func _process(delta: float) -> void:
	if _use_scheduler:
		return
	_process_tick(delta)

func _process_tick(delta: float) -> void:
	var tick_start := Time.get_ticks_usec()
	if _global_enabled and _power_ok:
		for key_variant in _targets.keys():
			var key: StringName = StringName(key_variant)
			var target: Dictionary = _targets[key] as Dictionary
			if int(target["mode"]) != MODE_AUTO:
				continue
			var interval: float = float(target["interval"])
			var elapsed: float = float(target["elapsed"]) + delta
			while elapsed >= interval:
				elapsed -= interval
				var callable: Callable = target["callable"] as Callable
				if callable.is_valid():
					var result: Variant = callable.call()
					if result == null or (typeof(result) == TYPE_BOOL and result):
						auto_burst_enqueued.emit()
				else:
					break
			target["elapsed"] = elapsed
			_targets[key] = target
	var tick_ms := float(Time.get_ticks_usec() - tick_start) / 1000.0
	_record_stats_probe(tick_ms)

func _emit_mode(key: StringName) -> void:
	mode_changed.emit(key, int(_targets[key]["mode"]))

func _register_stat() -> void:
	_statbus = _get_statbus()
	if _statbus == null:
		return
	_statbus.register_stat(&"auto_burst_ready", {"stack": "replace", "default": 0.0})

func _update_statbus() -> void:
	_statbus = _get_statbus()
	if _statbus == null:
		return
	var active_auto: int = _active_auto_count()
	var value: float = 1.0 if _global_enabled and _power_ok and active_auto > 0 else 0.0
	_statbus.set_stat(&"auto_burst_ready", value, "AutomationService")

func _get_statbus() -> StatBus:
	if _statbus and is_instance_valid(_statbus):
		return _statbus
	var node := get_node_or_null("/root/StatBusSingleton")
	if node is StatBus:
		_statbus = node as StatBus
		return _statbus
	return null

func _active_auto_count() -> int:
	var active_auto := 0
	for target_variant in _targets.values():
		var target: Dictionary = target_variant as Dictionary
		if int(target["mode"]) == MODE_AUTO:
			active_auto += 1
	return active_auto

func _get_stats_probe() -> StatsProbe:
	var node := get_node_or_null("/root/StatsProbeSingleton")
	if node is StatsProbe:
		return node as StatsProbe
	return null

func _record_stats_probe(tick_ms: float) -> void:
	if _stats_probe == null or not is_instance_valid(_stats_probe):
		_stats_probe = _get_stats_probe()
	if _stats_probe == null:
		return
	_stats_probe.record_tick({
		"service": "automation",
		"tick_ms": tick_ms,
		"auto_active": _active_auto_count(),
		"power_state": 1.0 if _power_ok else 0.0
	})
