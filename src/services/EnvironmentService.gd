extends Node
class_name EnvironmentService

signal environment_updated(state: Dictionary)
signal day_phase_changed(phase: StringName)
signal preset_changed(preset: StringName)

const DATA_PATH := "res://data/environment_profiles.tsv"
const DEFAULT_PRESET := StringName("early_farm")
const MIN_DAY_LENGTH := 120.0
const LOG_INTERVAL := 20.0
const StatsProbe := preload("res://src/services/StatsProbe.gd")

const STAGE_PATHS := {
	StringName("early_farm"): "res://game/scenes/modules/environment/EnvironmentStage_Backyard.tscn"
}

const TEMP_RANGE_C := Vector2(-5.0, 40.0)
const LIGHT_BASE_RANGE := Vector2(30.0, 95.0)
const HUMIDITY_BASE_RANGE := Vector2(35.0, 90.0)
const AIR_BASE_RANGE := Vector2(60.0, 98.0)
const MIN_TEMP_SWING := 2.0
const MIN_LIGHT_SWING := 5.0
const MIN_HUMIDITY_SWING := 5.0
const MIN_AIR_SWING := 2.5

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
var _use_scheduler := false
var _stats_probe: StatsProbe

func _ready() -> void:
	_load_presets()
	_apply_preset(DEFAULT_PRESET)
	set_process(true)
	_emit_state(true)
	preset_changed.emit(_current_preset_id)
	_stats_probe = _get_stats_probe()

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

func preset_for_tier(tier: int) -> StringName:
	var best: StringName = DEFAULT_PRESET
	var best_tier := -1
	for id in _preset_order:
		var preset: Dictionary = _presets.get(id, {})
		var tier_min := int(preset.get("tier_min", 1))
		if tier >= tier_min and tier_min > best_tier:
			best = id
			best_tier = tier_min
	return best

func apply_preset_for_tier(tier: int) -> void:
	var target := preset_for_tier(tier)
	select_preset(target)

func reload_profiles() -> void:
	var target_preset: StringName = _current_preset_id
	_load_presets()
	if not _presets.has(target_preset):
		target_preset = DEFAULT_PRESET
	_apply_preset(target_preset)
	_emit_state(true)
	preset_changed.emit(_current_preset_id)

func get_preset() -> StringName:
	return _current_preset_id

func get_state() -> Dictionary:
	return _current_state.duplicate()

func get_profile_data(preset: StringName = _current_preset_id) -> Dictionary:
	if _presets.has(preset):
		return (_presets[preset] as Dictionary).duplicate(true)
	return {}

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
		var preset: Dictionary = _presets.get(id, {})
		options.append({
			"id": id,
			"label": _preset_label(id),
			"tier_min": int(preset.get("tier_min", 1))
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
	if _use_scheduler:
		return
	_step(delta)

func step(delta: float) -> void:
	_step(delta)

func set_scheduler_enabled(enabled: bool) -> void:
	_use_scheduler = enabled

func _step(delta: float) -> void:
	if _paused:
		return
	var tick_start := Time.get_ticks_usec()
	_advance_time(delta)
	_emit_state()
	var tick_ms := float(Time.get_ticks_usec() - tick_start) / 1000.0
	_record_stats_probe(tick_ms)

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
	var phase := StringName(_current_state.get("phase", ""))
	if phase != _last_phase:
		_last_phase = phase
		day_phase_changed.emit(phase)
	var should_emit := force_emit
	if not should_emit and not _last_emitted_state.is_empty():
		should_emit = _differs_from_last(_current_state)
	if should_emit:
		_apply_state_to_stage(_current_state)
		_last_emitted_state = _current_state.duplicate(true)
		environment_updated.emit(_current_state.duplicate(true))
	_log_timer += get_process_delta_time()
	if _log_timer >= LOG_INTERVAL:
		_log_timer = 0.0
		var state_copy := _current_state.duplicate(true)
		var modifiers_copy := _current_modifiers.duplicate(true)
		call_deferred("_log_snapshot_deferred", state_copy, modifiers_copy)

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
	var wind_mean: float = clamp(float(preset.get("wind_mean", 0.3)), 0.0, 1.0)
	var breeze_amp: float = clamp(float(preset.get("light_amp", 20.0)) / 100.0 * 0.5, 0.02, 0.25)
	var breeze_norm: float = clamp(wind_mean + breeze_amp * trig, 0.0, 1.0)

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
		"breeze_norm": breeze_norm,
		"breeze_pct": breeze_norm * 100.0,
		"theme": preset.get("theme", "temperate"),
		"tier_min": int(preset.get("tier_min", 1)),
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
	if _preset_order.size() > 1:
		_preset_order.sort_custom(Callable(self, "_compare_preset_order"))

func _preset_from_row(row: Dictionary) -> Dictionary:
	if not row.has("profile_id"):
		return {}
	var id_string: String = String(row.get("profile_id", "")).strip_edges()
	if id_string == "":
		return {}
	var id: StringName = StringName(id_string)
	var label: String = String(row.get("label", id_string.capitalize()))
	var day_length: float = max(_to_number(row.get("daylen", "600")), MIN_DAY_LENGTH)
	var temp_min_norm: float = _clamp_norm(_to_number(row.get("temp_min", "0.45")))
	var temp_max_norm: float = _clamp_norm(_to_number(row.get("temp_max", "0.65")))
	var temperature_curve: Dictionary = _temperature_curve(temp_min_norm, temp_max_norm)
	var humidity_mean_norm: float = _clamp_norm(_to_number(row.get("humidity_mean", "0.60")))
	var humidity_swing_norm: float = max(absf(_to_number(row.get("humidity_swing", "0.14"))), 0.0)
	var humidity_curve: Dictionary = _percent_curve(humidity_mean_norm, humidity_swing_norm, HUMIDITY_BASE_RANGE, MIN_HUMIDITY_SWING)
	var light_mean_norm: float = _clamp_norm(_to_number(row.get("light_mean", "0.65")))
	var light_swing_norm: float = max(absf(_to_number(row.get("light_swing", "0.20"))), 0.0)
	var light_curve: Dictionary = _percent_curve(light_mean_norm, light_swing_norm, LIGHT_BASE_RANGE, MIN_LIGHT_SWING)
	var air_mean_norm: float = _clamp_norm(_to_number(row.get("air_mean", "0.85")))
	var air_swing_norm: float = max(absf(_to_number(row.get("air_swing", "0.08"))), 0.0)
	var air_curve: Dictionary = _percent_curve(air_mean_norm, air_swing_norm, AIR_BASE_RANGE, MIN_AIR_SWING)
	var wind_mean_norm: float = _clamp_norm(_to_number(row.get("wind_mean", "0.3")))
	var theme: String = String(row.get("theme", "temperate"))
	var tier_min: int = int(_to_number(row.get("tier_min", "1")))
	return {
		"id": id,
		"label": label,
		"day_length": day_length,
		"temp_base": temperature_curve["base"],
		"temp_amp": temperature_curve["amp"],
		"light_base": light_curve["base"],
		"light_amp": light_curve["amp"],
		"humidity_base": humidity_curve["base"],
		"humidity_amp": humidity_curve["amp"],
		"air_base": air_curve["base"],
		"air_amp": air_curve["amp"],
		"wind_mean": wind_mean_norm,
		"theme": theme,
		"tier_min": tier_min
	}

func _default_preset(id: StringName, label: String) -> Dictionary:
	return {
		"id": id,
		"label": label,
		"day_length": 600.0,
		"temp_base": 18.0,
		"temp_amp": 6.0,
		"light_base": 68.0,
		"light_amp": 22.0,
		"humidity_base": 60.0,
		"humidity_amp": 15.0,
		"air_base": 86.0,
		"air_amp": 8.0,
		"wind_mean": 0.28,
		"theme": "temperate",
		"tier_min": 1
	}

func _clamp_norm(value: float) -> float:
	return clamp(value, 0.0, 1.0)

func _temperature_curve(min_norm: float, max_norm: float) -> Dictionary:
	var min_capped: float = _clamp_norm(min_norm)
	var max_capped: float = _clamp_norm(max_norm)
	if max_capped < min_capped:
		var swap_value: float = min_capped
		min_capped = max_capped
		max_capped = swap_value
	var min_celsius: float = lerp(TEMP_RANGE_C.x, TEMP_RANGE_C.y, min_capped)
	var max_celsius: float = lerp(TEMP_RANGE_C.x, TEMP_RANGE_C.y, max_capped)
	var base: float = (min_celsius + max_celsius) * 0.5
	var amp: float = max(absf(max_celsius - min_celsius) * 0.5, MIN_TEMP_SWING)
	return {"base": base, "amp": amp}

func _percent_curve(mean_norm: float, swing_norm: float, base_range: Vector2, min_swing: float, max_swing: float = 100.0) -> Dictionary:
	var clamped_mean: float = _clamp_norm(mean_norm)
	var base: float = clamp(clamped_mean * 100.0, base_range.x, base_range.y)
	var span_down: float = base - base_range.x
	var span_up: float = base_range.y - base
	var allowed_max: float = min(max(span_down, span_up), max_swing)
	allowed_max = max(allowed_max, min_swing)
	var swing: float = clamp(absf(swing_norm) * 100.0, min_swing, allowed_max)
	return {"base": base, "amp": swing}

func _compare_preset_order(a: Variant, b: Variant) -> bool:
	var preset_a: Dictionary = _presets.get(a, {})
	var preset_b: Dictionary = _presets.get(b, {})
	var tier_a: int = int(preset_a.get("tier_min", 0))
	var tier_b: int = int(preset_b.get("tier_min", 0))
	if tier_a == tier_b:
		return String(a) < String(b)
	return tier_a < tier_b

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


func _log_snapshot_deferred(state: Dictionary, modifiers: Dictionary) -> void:
	var logger := _logger()
	if logger == null or state.is_empty():
		return
	var preset_id := StringName(state.get("preset", _current_preset_id))
	logger.log("INFO", "ENV", "state", {
		"preset": String(preset_id),
		"label": _preset_label(preset_id),
		"phase": String(state.get("phase", "")),
		"temp_c": state.get("temperature_c", 0.0),
		"light": state.get("light_pct", 0.0),
		"humidity": state.get("humidity_pct", 0.0),
		"air": state.get("air_quality_pct", 0.0),
		"breeze": state.get("breeze_pct", 0.0),
		"theme": state.get("theme", ""),
		"feed": modifiers.get("feed", 1.0),
		"power": modifiers.get("power", 1.0),
		"prestige": modifiers.get("prestige", 1.0)
	})

func _logger() -> YolkLogger:
	var node := get_node_or_null("/root/Logger")
	if node is YolkLogger:
		return node as YolkLogger
	return null

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
	var modifiers: Dictionary = _current_modifiers
	_stats_probe.record_tick({
		"service": "environment",
		"tick_ms": tick_ms,
		"power_state": float(modifiers.get("power", 1.0)),
		"feed_fraction": float(modifiers.get("feed", 1.0))
	})

func _to_number(value: Variant) -> float:
	if value is float:
		return value
	return String(value).to_float()
