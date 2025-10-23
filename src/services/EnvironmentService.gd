extends Node
class_name EnvironmentService

const StatBus := preload("res://src/services/StatBus.gd")

signal environment_updated(state: Dictionary)
signal day_phase_changed(phase: StringName)
signal preset_changed(preset: StringName)

const DATA_PATH := "res://data/environment_curves.tsv"
const DEFAULT_PRESET := StringName("temperate")
const MIN_DAY_LENGTH := 120.0
const LOG_INTERVAL := 20.0

const STAGE_PATHS := {
	DEFAULT_PRESET: "res://game/scenes/modules/environment/EnvironmentStage_Backyard.tscn"
}

var _presets: Dictionary = {}
var _preset_order: Array[StringName] = []
var _current_preset_id: StringName = DEFAULT_PRESET
var _current_state: Dictionary = {}
var _current_modifiers: Dictionary = {}
var _time_accumulator: float = 0.0
var _last_emitted_state: Dictionary = {}
var _last_phase: StringName = StringName()
var _log_timer: float = 0.0
var _manual_override: Dictionary = {}
var _paused := false

var _environment_root: Node2D
var _stage_cache: Dictionary = {}
var _stage_instances: Dictionary = {}
var _active_stage: Node2D
var _strings: StringsCatalog
var _statbus: StatBus

func _ready() -> void:
	_load_presets()
	_apply_preset(DEFAULT_PRESET)
	set_process(true)
	_emit_state(true)
	preset_changed.emit(_current_preset_id)
 	_statbus = _statbus_ref()
 	_register_statbus_keys()

func set_strings(strings: StringsCatalog) -> void:
	_strings = strings

func set_paused(paused: bool) -> void:
	_paused = paused

func set_manual_override(override: Dictionary) -> void:
	_manual_override = override.duplicate()
	_emit_state(true)

func clear_manual_override() -> void:
	_manual_override.clear()
	_emit_state(true)

func register_environment_root(root: Node) -> void:
	if root == null:
		return
	if root == _environment_root:
		return
	if _environment_root and is_instance_valid(_environment_root):
		_environment_root = null
	_environment_root = root as Node2D
	_rebuild_stage()

func select_preset(preset: StringName) -> void:
	if _apply_preset(preset):
		_emit_state(true)
		preset_changed.emit(_current_preset_id)

func get_preset() -> StringName:
	return _current_preset_id

func get_state() -> Dictionary:
	return _current_state.duplicate()

func get_modifiers() -> Dictionary:
	return _current_modifiers.duplicate()

func get_day_fraction() -> float:
	return float(_current_state.get("day_fraction", 0.0))

func get_phase() -> StringName:
	return StringName(_current_state.get("phase", StringName()))

func get_modifier(key: StringName, default_value: float = 1.0) -> float:
	var lookup_key := String(key)
	if _current_modifiers.has(lookup_key):
		return float(_current_modifiers[lookup_key])
	return default_value

func get_feed_modifier() -> float:
	return get_modifier(&"feed", 1.0)

func get_power_modifier() -> float:
	return get_modifier(&"power", 1.0)

func get_prestige_modifier() -> float:
	return get_modifier(&"prestige", 1.0)

func get_preset_label(preset: StringName = _current_preset_id) -> String:
	return _preset_label(preset)

func get_active_stage_size() -> Vector2:
	if _active_stage and is_instance_valid(_active_stage) and _active_stage.has_method("get_canvas_size"):
		var result: Variant = _active_stage.call("get_canvas_size")
		if result is Vector2:
			return result as Vector2
	return Vector2.ZERO

func get_preset_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for id in _preset_order:
		options.append({
			"id": id,
			"label": _preset_label(id)
		})
	return options

func cycle_preset(step: int = 1) -> void:
	if _preset_order.is_empty():
		return
	var index := _preset_order.find(_current_preset_id)
	if index == -1:
		index = 0
	index = posmod(index + step, _preset_order.size())
	select_preset(_preset_order[index])

func _process(delta: float) -> void:
	if _paused:
		return
	_advance_time(delta)
	_emit_state()

func _advance_time(delta: float) -> void:
	var preset := _current_preset()
	var day_length: float = max(float(preset.get("day_length", 600.0)), MIN_DAY_LENGTH)
	_time_accumulator = fmod(_time_accumulator + delta, day_length)

func _emit_state(force_emit: bool = false) -> void:
	var state := _calculate_state()
	_current_state = state.duplicate(true)
	var modifiers_variant: Variant = _current_state.get("modifiers", {})
	if modifiers_variant is Dictionary:
		_current_modifiers = (modifiers_variant as Dictionary).duplicate(true)
	else:
		_current_modifiers = {}
	_apply_state_to_stage(_current_state)
	_update_statbus_state(_current_state)
	var phase := StringName(_current_state.get("phase", ""))
	if phase != _last_phase:
		_last_phase = phase
		day_phase_changed.emit(phase)
	var should_emit := force_emit
	if not should_emit and not _last_emitted_state.is_empty():
		should_emit = _differs_from_last(_current_state)
	if should_emit:
		_last_emitted_state = _current_state.duplicate(true)
		environment_updated.emit(_current_state.duplicate(true))
	_log_timer += get_process_delta_time()
	if _log_timer >= LOG_INTERVAL:
		_log_timer = 0.0
		_log_snapshot()

func _calculate_state() -> Dictionary:
	var preset := _current_preset()
	var day_length: float = max(float(preset.get("day_length", 600.0)), MIN_DAY_LENGTH)
	var fraction: float = 0.0
	if day_length > 0.0:
		fraction = _time_accumulator / day_length
	var trig := sin(fraction * TAU)
	var temp_c: float = _value_from_curve(preset, "temp", trig)
	var light_pct: float = _value_from_curve(preset, "light", trig, 0.0, 100.0)
	var humidity_pct: float = _value_from_curve(preset, "humidity", trig, 0.0, 100.0)
	var air_pct: float = _value_from_curve(preset, "air", trig, 0.0, 100.0)

	var temp_norm: float = clamp(temp_c / 35.0, 0.0, 1.0)
	var light_norm: float = clamp(light_pct / 100.0, 0.0, 1.0)
	var humidity_norm: float = clamp(humidity_pct / 100.0, 0.0, 1.0)
	var air_norm: float = clamp(air_pct / 100.0, 0.0, 1.0)

	var comfort: float = clamp(1.0 - abs(temp_norm - 0.55) * 0.9 - abs(humidity_norm - 0.55) * 0.7, 0.0, 1.0)
	var stress: float = clamp((1.0 - comfort) * 100.0, 0.0, 100.0)
	var pollution: float = clamp((1.0 - air_norm) * 100.0, 0.0, 100.0)
	var reputation: float = clamp((air_norm * 0.5 + light_norm * 0.3 + comfort * 0.2) * 100.0, 0.0, 100.0)

	var feed_modifier: float = clamp(1.0 + (comfort - 0.5) * 0.2 - pollution * 0.001, 0.8, 1.2)
	var power_modifier: float = clamp(1.0 + (light_norm - 0.5) * 0.3 - temp_norm * 0.05, 0.7, 1.3)
	var prestige_modifier: float = clamp(1.0 + (reputation - 50.0) * 0.01 - pollution * 0.003, 0.6, 1.4)
	var comfort_bonus: float = clamp(comfort * 0.05, 0.0, 0.05)

	var phase := _phase_for_fraction(fraction)
	var label := _preset_label(_current_preset_id)

	var state := {
		"preset": _current_preset_id,
		"label": label,
		"day_length": day_length,
		"day_fraction": fraction,
		"phase": phase,
		"temperature_c": temp_c,
		"temperature_f": temp_c * 9.0 / 5.0 + 32.0,
		"light_pct": light_pct,
		"humidity_pct": humidity_pct,
		"air_quality_pct": air_pct,
		"pollution": pollution,
		"stress": stress,
		"reputation": reputation,
		"comfort_index": comfort,
		"ci_bonus": comfort_bonus,
		"modifiers": {
			"feed": feed_modifier,
			"power": power_modifier,
			"prestige": prestige_modifier
		}
	}

	if not _manual_override.is_empty():
		for key in _manual_override.keys():
			state[key] = _manual_override[key]

	return state

func _value_from_curve(preset: Dictionary, prefix: String, trig: float, min_value: float = -INF, max_value: float = INF) -> float:
	var base_key := "%s_base" % prefix
	var amp_key := "%s_amp" % prefix
	var base_value := float(preset.get(base_key, 0.0))
	var amplitude := float(preset.get(amp_key, 0.0))
	var value := base_value + amplitude * trig
	if min_value != -INF or max_value != INF:
		value = clamp(value, min_value, max_value)
	return value

func _phase_for_fraction(fraction: float) -> StringName:
	var frac := fposmod(fraction, 1.0)
	if frac < 0.25:
		return StringName("dawn")
	if frac < 0.5:
		return StringName("day")
	if frac < 0.75:
		return StringName("dusk")
	return StringName("night")

func _differs_from_last(state: Dictionary) -> bool:
	var keys := ["temperature_c", "light_pct", "humidity_pct", "air_quality_pct", "pollution", "stress", "reputation"]
	for key in keys:
		var prev := float(_last_emitted_state.get(key, -9999.0))
		var curr := float(state.get(key, 0.0))
		if abs(prev - curr) >= 0.35:
			return true
	return false

func _load_presets() -> void:
	_presets.clear()
	_preset_order.clear()
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		_register_preset(DEFAULT_PRESET, _default_preset(DEFAULT_PRESET, "Temperate Meadow"))
		return
	var header: PackedStringArray = []
	while file.get_position() < file.get_length():
		var raw := file.get_line()
		if raw.strip_edges() == "" or raw.begins_with("#"):
			continue
		var cols := raw.split("\t", false)
		if header.is_empty():
			header = cols
			continue
		var row: Dictionary = {}
		for i in range(min(header.size(), cols.size())):
			row[header[i]] = cols[i]
		var preset := _preset_from_row(row)
		if preset.is_empty():
			continue
		var id := StringName(preset.get("id", ""))
		if id == StringName():
			continue
		_register_preset(id, preset)
	file.close()
	if not _presets.has(DEFAULT_PRESET):
		_register_preset(DEFAULT_PRESET, _default_preset(DEFAULT_PRESET, "Temperate Meadow"))

func _preset_from_row(row: Dictionary) -> Dictionary:
	if not row.has("season"):
		return {}
	var id := StringName(String(row.get("season", "")).strip_edges())
	if id == StringName():
		return {}
	var preset := {
		"id": id,
		"label": String(row.get("label", String(id).capitalize())),
		"day_length": _to_number(row.get("day_length", "600")),
		"temp_base": _to_number(row.get("temp_base_c", "18")),
		"temp_amp": _to_number(row.get("temp_amp_c", "4")),
		"light_base": _to_number(row.get("light_base_pct", "65")),
		"light_amp": _to_number(row.get("light_amp_pct", "20")),
		"humidity_base": _to_number(row.get("humidity_base_pct", "60")),
		"humidity_amp": _to_number(row.get("humidity_amp_pct", "15")),
		"air_base": _to_number(row.get("air_base_pct", "85")),
		"air_amp": _to_number(row.get("air_amp_pct", "8"))
	}
	return preset

func _default_preset(id: StringName, label: String) -> Dictionary:
	return {
		"id": id,
		"label": label,
		"day_length": 600.0,
		"temp_base": 18.0,
		"temp_amp": 4.0,
		"light_base": 65.0,
		"light_amp": 20.0,
		"humidity_base": 60.0,
		"humidity_amp": 15.0,
		"air_base": 85.0,
		"air_amp": 8.0
	}

func _register_preset(id: StringName, preset: Dictionary) -> void:
	_presets[id] = preset
	if not _preset_order.has(id):
		_preset_order.append(id)

func _apply_preset(preset: StringName) -> bool:
	var id := preset
	if id == StringName() or not _presets.has(id):
		id = DEFAULT_PRESET
	var changed := id != _current_preset_id
	_current_preset_id = id
	_time_accumulator = 0.0
	_rebuild_stage()
	return changed

func _preset_label(preset: StringName) -> String:
	if _presets.has(preset):
		return String(_presets[preset].get("label", String(preset).capitalize()))
	return String(preset).capitalize()

func _current_preset() -> Dictionary:
	if _presets.has(_current_preset_id):
		return _presets[_current_preset_id]
	return _presets.get(DEFAULT_PRESET, _default_preset(DEFAULT_PRESET, "Temperate Meadow"))

func _rebuild_stage() -> void:
	if _environment_root == null or not is_instance_valid(_environment_root):
		return
	var target_stage_id := _stage_for_preset(_current_preset_id)
	var stage := _get_stage_instance(target_stage_id)
	if stage == null:
		return
	_activate_stage(stage)

func _stage_for_preset(preset: StringName) -> StringName:
	if STAGE_PATHS.has(preset):
		return preset
	return DEFAULT_PRESET

func _get_stage_instance(stage_id: StringName) -> Node2D:
	if _stage_instances.has(stage_id):
		var cached_variant: Variant = _stage_instances[stage_id]
		if cached_variant is Node2D:
			var cached: Node2D = cached_variant
			if is_instance_valid(cached):
				return cached
	_stage_instances.erase(stage_id)
	var scene := _get_stage_scene(stage_id)
	if scene == null:
		return null
	var instance := scene.instantiate()
	if instance is Node2D:
		var node2d := instance as Node2D
		_environment_root.add_child(node2d)
		node2d.position = Vector2.ZERO
		_stage_instances[stage_id] = node2d
		return node2d
	instance.queue_free()
	return null

func _get_stage_scene(stage_id: StringName) -> PackedScene:
	if _stage_cache.has(stage_id):
		return _stage_cache[stage_id] as PackedScene
	var path := String(STAGE_PATHS.get(stage_id, ""))
	if path == "":
		return null
	var scene := ResourceLoader.load(path)
	if scene is PackedScene:
		_stage_cache[stage_id] = scene
		return scene
	return null

func _activate_stage(stage: Node2D) -> void:
	for key in _stage_instances.keys():
		var inst := _stage_instances[key] as Node2D
		if inst and is_instance_valid(inst):
			inst.visible = inst == stage
	_active_stage = stage
	_apply_state_to_stage(_current_state)

func _apply_state_to_stage(state: Dictionary) -> void:
	if _active_stage == null or not is_instance_valid(_active_stage):
		return
	if _active_stage.has_method("apply_state"):
		_active_stage.call(
			"apply_state",
			float(state.get("pollution", 0.0)),
			float(state.get("stress", 0.0)),
			float(state.get("reputation", 0.0))
		)

func _register_statbus_keys() -> void:
	_statbus_ref()
	if _statbus == null:
		return
	_statbus.register_stat(&"comfort_index", {"stack": "replace", "default": 0.0})
	_statbus.register_stat(&"ci_bonus", {"stack": "add", "cap": 0.05, "default": 0.0})

func _update_statbus_state(state: Dictionary) -> void:
	_register_statbus_keys()
	if _statbus == null:
		return
	var comfort := float(state.get("comfort_index", 0.0))
	var ci_bonus := float(state.get("ci_bonus", 0.0))
	_statbus.set_stat(&"comfort_index", comfort, "Environment")
	_statbus.set_stat(&"ci_bonus", ci_bonus, "Environment")

func _statbus_ref() -> StatBus:
	if _statbus and is_instance_valid(_statbus):
		return _statbus
	var node := get_node_or_null("/root/StatBusSingleton")
	if node is StatBus:
		_statbus = node as StatBus
		return _statbus
	return null

func _log_snapshot() -> void:
	var logger := _logger()
	if logger == null or _current_state.is_empty():
		return
	var modifiers: Dictionary = _current_modifiers
	logger.log("INFO", "ENV", "state", {
		"preset": String(_current_preset_id),
		"label": _preset_label(_current_preset_id),
		"phase": String(_current_state.get("phase", "")),
		"temp_c": _current_state.get("temperature_c", 0.0),
		"light": _current_state.get("light_pct", 0.0),
		"humidity": _current_state.get("humidity_pct", 0.0),
		"air": _current_state.get("air_quality_pct", 0.0),
		"feed": modifiers.get("feed", 1.0),
		"power": modifiers.get("power", 1.0),
		"prestige": modifiers.get("prestige", 1.0)
	})

func _logger() -> YolkLogger:
	var node := get_node_or_null("/root/Logger")
	if node is YolkLogger:
		return node as YolkLogger
	return null

func _to_number(value: Variant) -> float:
	if value is float:
		return value
	return String(value).to_float()
