extends Node
class_name EventEngine

signal event_started(id: String, definition: Dictionary)
signal event_accepted(id: String, definition: Dictionary)
signal event_declined(id: String, definition: Dictionary)
signal event_completed(id: String, definition: Dictionary)
signal toast_requested(string_key: String)

const EventRegistry := preload("res://src/events/EventRegistry.gd")
const StatBus := preload("res://src/services/StatBus.gd")
const StatsProbe := preload("res://src/services/StatsProbe.gd")
const YolkLogger := preload("res://game/scripts/Logger.gd")

var _active: Dictionary = {}
var _cooldowns: Dictionary = {}
var _power_service: Node
var _economy_service: Node
var _conveyor_service: Node
var _statbus: StatBus
var _logger: YolkLogger
var _stats_probe: StatsProbe

func _ready() -> void:
	_statbus = _statbus_ref()
	_logger = _logger_ref()
	_stats_probe = _stats_probe_ref()
	set_process(true)

func setup(power: Node = null, economy: Node = null, conveyor: Node = null, statbus: StatBus = null, stats_probe: StatsProbe = null) -> void:
	_power_service = power
	_economy_service = economy
	_conveyor_service = conveyor
	if statbus:
		_statbus = statbus
	if stats_probe:
		_stats_probe = stats_probe

func can_trigger(id: String) -> bool:
	if _active.has(id):
		return false
	if _cooldowns.has(id):
		var now_msec := Time.get_ticks_msec()
		if now_msec < int(_cooldowns[id]):
			return false
	return true

func trigger(id: String) -> bool:
	if not can_trigger(id):
		return false
	var def := EventRegistry.get_definition(id)
	if def.is_empty():
		return false
	var state := {
		"def": def,
		"elapsed": 0.0,
		"accepted": false,
		"accepted_backlog": 0,
		"pending_payout": 0
	}
	_active[id] = state
	_apply_effects(id, def.get("effects_on_start", []), state)
	_set_statbus_event(id)
	_record_event("started", id)
	event_started.emit(id, def)
	return true

func accept(id: String) -> void:
	if not _active.has(id):
		return
	var state: Dictionary = _active[id]
	if state.get("accepted", false):
		return
	state["accepted"] = true
	var def: Dictionary = state.get("def", {})
	_apply_effects(id, def.get("effects_on_accept", []), state)
	var toast_key := String(def.get("toast_on_accept_key", ""))
	if toast_key != "":
		toast_requested.emit(toast_key)
	_record_event("accepted", id)
	event_accepted.emit(id, def)

func decline(id: String) -> void:
	if not _active.has(id):
		return
	var def: Dictionary = _active[id].get("def", {})
	_finish_event(id, true)
	_record_event("declined", id)
	event_declined.emit(id, def)

func complete(id: String) -> void:
	if not _active.has(id):
		return
	_finish_event(id, false)

func active_state(id: String) -> Dictionary:
	if not _active.has(id):
		return {}
	return (_active[id] as Dictionary).duplicate(true)

func _process(delta: float) -> void:
	if delta <= 0.0 or _active.is_empty():
		return
	var to_complete: Array[String] = []
	for id in _active.keys():
		var state: Dictionary = _active[id]
		var def: Dictionary = state.get("def", {})
		var duration: int = int(def.get("duration_sec", -1))
		if duration <= 0:
			continue
		state["elapsed"] = float(state.get("elapsed", 0.0)) + delta
		if state["elapsed"] >= duration:
			to_complete.append(id)
	for id in to_complete:
		_finish_event(id, false)

func _finish_event(id: String, declined: bool) -> void:
	if not _active.has(id):
		return
	var state: Dictionary = _active[id]
	var def: Dictionary = state.get("def", {})
	if not declined:
		_apply_effects(id, def.get("effects_on_complete", []), state)
	var toast_key := ""
	if declined:
		toast_key = String(def.get("toast_on_decline_key", ""))
	else:
		toast_key = String(def.get("toast_on_end_key", def.get("toast_on_complete_key", "")))
	if toast_key != "":
		toast_requested.emit(toast_key)
	var cooldown_ms := int(def.get("repeat_cooldown_sec", 300)) * 1000
	_cooldowns[id] = Time.get_ticks_msec() + cooldown_ms
	_active.erase(id)
	if _active.is_empty():
		_set_statbus_event("")
	event_completed.emit(id, def)
	_record_event("completed", id)

func _apply_effects(id: String, effects: Array, state: Dictionary) -> void:
	for eff in effects:
		var effect_dict: Dictionary = eff
		var op := int(effect_dict.get("op", -1))
		var value := _resolve_effect_value(effect_dict, state)
		match op:
			EventRegistry.EffectType.POWER_MULTIPLIER:
				_apply_power_multiplier(value)
			EventRegistry.EffectType.BACKLOG_ADD:
				state["accepted_backlog"] = int(value)
				_enqueue_backlog(int(value))
			EventRegistry.EffectType.PAYOUT_ON_COMPLETE:
				_credit_payment(int(value), id)
			_:
				_log("WARN", "EVENT", "unhandled_effect", {"id": id, "effect": effect_dict})

func _resolve_effect_value(def: Dictionary, state: Dictionary) -> float:
	if def.has("value"):
		return float(def["value"])
	var source := String(def.get("value_from", ""))
	var mult := float(def.get("mult", 1.0))
	var min_value := float(def.get("value_min", 0.0))
	var base := 0.0
	match source:
		"economy_rate":
			if _economy_service and _economy_service.has_method("get_economy_rate"):
				base = float(_economy_service.call("get_economy_rate"))
		"accepted_backlog":
			base = float(state.get("accepted_backlog", 0))
	var scaled = max(min_value, round(base * mult))
	return scaled

func _set_statbus_event(id: String) -> void:
	var bus := _statbus_ref()
	if bus == null:
		return
	bus.register_stat(&"micro_event_id", {"stack": "replace", "default": ""})
	bus.set_stat(&"micro_event_id", id, "EventEngine")

func _statbus_ref() -> StatBus:
	if _statbus and is_instance_valid(_statbus):
		return _statbus
	var node := get_node_or_null("/root/StatBusSingleton")
	if node is StatBus:
		_statbus = node as StatBus
	return _statbus

func _stats_probe_ref() -> StatsProbe:
	if _stats_probe and is_instance_valid(_stats_probe):
		return _stats_probe
	var node := get_node_or_null("/root/StatsProbeSingleton")
	if node is StatsProbe:
		_stats_probe = node as StatsProbe
	return _stats_probe

func _logger_ref() -> YolkLogger:
	if _logger and is_instance_valid(_logger):
		return _logger
	var node := get_node_or_null("/root/Logger")
	if node is YolkLogger:
		_logger = node as YolkLogger
	return _logger

func _log(level: String, category: String, message: String, context: Dictionary) -> void:
	var logger := _logger_ref()
	if logger:
		logger.log(level, category, message, context)

func _apply_power_multiplier(value: float) -> void:
	if _power_service and _power_service.has_method("set_power_multiplier"):
		_power_service.call("set_power_multiplier", float(value))

func _enqueue_backlog(count: int) -> void:
	if _conveyor_service and _conveyor_service.has_method("enqueue_backlog"):
		_conveyor_service.call("enqueue_backlog", int(count))

func _credit_payment(amount: int, id: String) -> void:
	if _economy_service and _economy_service.has_method("credit_payment"):
		_economy_service.call("credit_payment", float(amount), "event_%s" % id)

func time_remaining(id: String) -> float:
	var state = active_state(id)
	if state.is_empty():
		return 0.0
	var def: Dictionary = state.get("def", {})
	var duration = float(def.get("duration_sec", -1.0))
	if duration <= 0.0:
		return -1.0
	var elapsed = float(state.get("elapsed", 0.0))
	return max(duration - elapsed, 0.0)

func _record_event(kind: String, id: String) -> void:
	var probe = _stats_probe_ref()
	if probe == null:
		return
	probe.event_log({
		"kind": kind,
		"event_id": id,
		"ts": Time.get_unix_time_from_system()
	})
