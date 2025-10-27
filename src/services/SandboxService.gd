extends Node
class_name SandboxService

signal ci_changed(ci: float, bonus: float)

const UPDATE_INTERVAL := 0.5 # 2 Hz
const BONUS_CAP := 0.05
const INPUT_SMOOTH_ALPHA := 0.2
const TELEMETRY_INTERVAL := 5.0
const CONFIG_PATH := "res://data/environment_config.json"

const StatBus: GDScript = preload("res://src/services/StatBus.gd")
const EnvironmentService: GDScript = preload("res://src/services/EnvironmentService.gd")
const SandboxGrid: GDScript = preload("res://src/sandbox/SandboxGrid.gd")
const StatsProbe: GDScript = preload("res://src/services/StatsProbe.gd")
const YolkLogger: GDScript = preload("res://game/scripts/Logger.gd")
const STABLE_DELTA_THRESHOLD := 0.0002
const STABLE_ACTIVE_THRESHOLD := 0.44
const STABLE_SKIP_LIMIT := 8
const ENV_TARGET_EPS := 0.01
var _environment: EnvironmentService
var _statbus: StatBus
var _grid: SandboxGrid
var _stats_probe: StatsProbe
var _logger_cache: YolkLogger
var _last_comfort: Dictionary = {
	"ci": 0.0,
	"stability": 0.0,
	"diversity": 0.0,
	"entropy": 0.0,
	"active_fraction": 0.0,
	"ci_smoothed": 0.0,
	"active_fraction_smoothed": 0.0,
	"ci_delta": 0.0
}
var _latest_state: Dictionary = {}
var _smoothed_ci: float = 0.0
var _last_active_fraction: float = 0.0
var _last_ci_delta: float = 0.0
var _accumulator: float = 0.0
var _use_scheduler: bool = false
var _telemetry_timer: float = 0.0

var _heat: float = 0.5
var _moisture: float = 0.5
var _breeze: float = 0.5
var _heat_target: float = 0.5
var _moisture_target: float = 0.5
var _breeze_target: float = 0.5
var _heat_velocity: float = 0.0
var _moisture_velocity: float = 0.0
var _breeze_velocity: float = 0.0
var _input_alpha: float = INPUT_SMOOTH_ALPHA
var _ci_window: Array[float] = []
var _ci_window_size: int = 4
var _active_window: Array[float] = []
var _active_window_size: int = 4
var _metrics_double_buffer: bool = false
var _metrics_release_interval: int = 1
var _metrics_release_counter: int = 0
var _metrics_front: Dictionary = {}
var _metrics_back: Dictionary = {}
var _grid_cell_count: float = 0.0
var _stable_tick_counter: int = 0

func _ready() -> void:
	_load_config()
	_initialize_metrics_buffers()
	_environment = _get_environment()
	if _environment and not _environment.environment_updated.is_connected(_on_environment_updated):
		_environment.environment_updated.connect(_on_environment_updated)
	_statbus = _get_statbus()
	_register_statbus_keys()
	_stats_probe = _get_stats_probe()
	_grid = SandboxGrid.new()
	_grid_cell_count = float(SandboxGrid.get_cell_count())
	_grid.seed_grid()
	set_process(true)
	_tick(0.0)

func current_ci() -> float:
	return _smoothed_ci

func current_bonus() -> float:
	return clamp(_smoothed_ci * BONUS_CAP, 0.0, BONUS_CAP)

func get_ci() -> float:
	return current_ci()

func get_ci_bonus() -> float:
	return current_bonus()

func _on_environment_updated(state: Dictionary) -> void:
	var previous_preset: StringName = _latest_state.get("preset", StringName())
	var current_preset: StringName = state.get("preset", StringName())
	if _latest_state.is_empty():
		_latest_state = {}
	else:
		_latest_state.clear()
	_latest_state["preset"] = current_preset
	_latest_state["phase"] = state.get("phase", StringName())
	var preset_changed: bool = current_preset != previous_preset
	_apply_environment_targets(state, preset_changed)
	if preset_changed:
		_smoothed_ci = 0.0
		if _grid:
			_grid.seed_grid()
			set_inputs(_breeze_target, _moisture_target, _heat_target, true)
	# Update on next idle frame so environment tick timing excludes sandbox work.
	call_deferred("_tick", 0.0)
	_accumulator = 0.0

func _process(delta: float) -> void:
	if _use_scheduler:
		return
	step(delta)

func step(delta: float) -> void:
	_accumulator += delta
	while _accumulator >= UPDATE_INTERVAL:
		_accumulator -= UPDATE_INTERVAL
		_tick(UPDATE_INTERVAL)

func set_scheduler_enabled(enabled: bool) -> void:
	_use_scheduler = enabled

func _tick(delta: float) -> void:
	if _grid == null:
		return
	var tick_start := Time.get_ticks_usec()
	_blend_inputs()
	_grid.heat = _heat
	_grid.moisture = _moisture
	_grid.breeze = _breeze
	var skip_step := false
	var comfort_data: Dictionary
	if delta > 0.0:
		skip_step = _should_skip_step()
		if skip_step and not _last_comfort.is_empty():
			comfort_data = _last_comfort.duplicate(true)
		else:
			if skip_step:
				skip_step = false
			_grid.step(delta)
			comfort_data = _compute_ci()
	else:
		comfort_data = _compute_ci()
	var raw_ci: float = float(comfort_data.get("ci", 0.0))
	var raw_active: float = float(comfort_data.get("active_fraction", 0.0))
	_push_window_sample(_ci_window, _ci_window_size, raw_ci)
	_push_window_sample(_active_window, _active_window_size, raw_active)
	var previous_ci: float = _smoothed_ci
	_smoothed_ci = _window_average(_ci_window, raw_ci)
	if _ci_window.size() <= 1:
		_last_ci_delta = 0.0
	else:
		_last_ci_delta = _smoothed_ci - previous_ci
	_last_active_fraction = _window_average(_active_window, raw_active)
	comfort_data["ci_smoothed"] = _smoothed_ci
	comfort_data["active_fraction_smoothed"] = _last_active_fraction
	comfort_data["ci_delta"] = _last_ci_delta
	_last_comfort = comfort_data.duplicate(true)
	var bonus: float = current_bonus()
	_store_metrics(_build_metrics(_smoothed_ci, bonus))
	_update_statbus(_smoothed_ci, bonus)
	emit_signal_ci(_smoothed_ci, bonus)
	var tick_ms: float = float(Time.get_ticks_usec() - tick_start) / 1000.0
	_record_stats_probe(tick_ms, _smoothed_ci, _last_active_fraction, _last_ci_delta)
	_log_telemetry(delta, _smoothed_ci, bonus)
	if skip_step:
		_stable_tick_counter = min(_stable_tick_counter + 1, STABLE_SKIP_LIMIT)
	else:
		_stable_tick_counter = 0

func emit_signal_ci(ci: float, bonus: float) -> void:
	ci_changed.emit(ci, bonus)

func _compute_ci() -> Dictionary:
	if _grid == null:
		return {"ci": 0.0, "active_fraction": 0.0}
	var comfort: Dictionary = _grid.compute_comfort()
	comfort["active_fraction"] = _grid.active_cell_fraction()
	return comfort

func _register_statbus_keys() -> void:
	_statbus = _get_statbus()
	if _statbus == null:
		return
	_statbus.register_stat(&"comfort_index", {"stack": "replace", "default": 0.0})
	_statbus.register_stat(&"ci_bonus", {"stack": "add", "cap": BONUS_CAP, "default": 0.0})

func _update_statbus(ci: float, bonus: float) -> void:
	_statbus = _get_statbus()
	if _statbus == null:
		return
	_statbus.set_stat(&"comfort_index", ci, "Sandbox")
	_statbus.set_stat(&"ci_bonus", bonus, "Sandbox")

func set_inputs(breeze: float, moisture: float, heat: float, immediate: bool = false) -> void:
	_breeze_target = clamp(breeze, 0.0, 1.0)
	_moisture_target = clamp(moisture, 0.0, 1.0)
	_heat_target = clamp(heat, 0.0, 1.0)
	if immediate:
		_breeze = _breeze_target
		_moisture = _moisture_target
		_heat = _heat_target
		_heat_velocity = 0.0
		_moisture_velocity = 0.0
		_breeze_velocity = 0.0

func set_random_seed(seed: int) -> void:
	if _grid == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = int(seed)
	_grid.set_random_number_generator(rng)
	_grid.seed_grid()

func latest_metrics() -> Dictionary:
	if _metrics_front.is_empty():
		return _build_metrics(_smoothed_ci, current_bonus())
	return _metrics_front.duplicate(true)

func current_snapshot() -> Array:
	if _grid == null:
		return []
	return _grid.get_snapshot()

func _apply_environment_targets(state: Dictionary, immediate: bool) -> void:
	if state.is_empty():
		return
	var breeze_target: float = 0.0
	if state.has("breeze_norm"):
		breeze_target = clamp(float(state.get("breeze_norm", 0.0)), 0.0, 1.0)
	else:
		breeze_target = clamp(float(state.get("light_pct", 65.0)) / 100.0, 0.0, 1.0)
	var moisture_target: float = clamp(float(state.get("humidity_pct", 60.0)) / 100.0, 0.0, 1.0)
	var temperature_c: float = float(state.get("temperature_c", 18.0))
	var heat_target: float = clamp(temperature_c / 35.0, 0.0, 1.0)
	set_inputs(breeze_target, moisture_target, heat_target, immediate)

func _blend_inputs() -> void:
	_heat_velocity = lerp(_heat_velocity, _heat_target - _heat, _input_alpha)
	_moisture_velocity = lerp(_moisture_velocity, _moisture_target - _moisture, _input_alpha)
	_breeze_velocity = lerp(_breeze_velocity, _breeze_target - _breeze, _input_alpha)
	_heat = clamp(_heat + _heat_velocity * 0.5, 0.0, 1.0)
	_moisture = clamp(_moisture + _moisture_velocity * 0.5, 0.0, 1.0)
	_breeze = clamp(_breeze + _breeze_velocity * 0.5, 0.0, 1.0)

func _log_telemetry(delta: float, ci: float, bonus: float) -> void:
	if delta <= 0.0:
		return
	_telemetry_timer += delta
	if _telemetry_timer < TELEMETRY_INTERVAL:
		return
	_telemetry_timer = 0.0
	var logger := _logger()
	if logger == null:
		return
	logger.log("INFO", "SANDBOX", "comfort", {
		"ci": "%.3f" % ci,
		"bonus": "%.3f" % bonus,
		"heat": "%.3f" % _heat,
		"moisture": "%.3f" % _moisture,
		"breeze": "%.3f" % _breeze,
		"active": "%.3f" % _last_active_fraction,
		"ci_delta": "%.3f" % _last_ci_delta,
		"preset": String(_latest_state.get("preset", "")),
		"phase": String(_latest_state.get("phase", ""))
	})

func _logger() -> YolkLogger:
	if _logger_cache and is_instance_valid(_logger_cache):
		return _logger_cache
	var node := get_node_or_null("/root/Logger")
	if node is YolkLogger:
		_logger_cache = node as YolkLogger
		return _logger_cache
	return null

func _push_window_sample(buffer: Array[float], size: int, value: float) -> void:
	buffer.append(value)
	while buffer.size() > max(size, 1):
		buffer.remove_at(0)

func _window_average(buffer: Array[float], fallback: float) -> float:
	if buffer.is_empty():
		return fallback
	var sum := 0.0
	for value in buffer:
		sum += value
	return sum / buffer.size()

func _load_config() -> void:
	if not FileAccess.file_exists(CONFIG_PATH):
		return
	var text := FileAccess.get_file_as_string(CONFIG_PATH)
	if text == "":
		return
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		var config: Dictionary = parsed
		if config.has("ema_alpha"):
			_input_alpha = clamp(float(config["ema_alpha"]), 0.01, 1.0)
		if config.has("ci_window_size"):
			_ci_window_size = max(int(config["ci_window_size"]), 1)
		if config.has("active_window_size"):
			_active_window_size = max(int(config["active_window_size"]), 1)
		if config.has("metrics_double_buffer"):
			_metrics_double_buffer = bool(config["metrics_double_buffer"])
		if config.has("metrics_release_interval"):
			_metrics_release_interval = max(int(config["metrics_release_interval"]), 1)
	_ci_window.clear()
	_active_window.clear()
	_last_ci_delta = 0.0
	_last_active_fraction = 0.0
	_smoothed_ci = 0.0
	_stable_tick_counter = 0
	_initialize_metrics_buffers()

func _should_skip_step() -> bool:
	if _last_comfort.is_empty():
		return false
	if _is_environment_adjusting():
		return false
	if _stable_tick_counter >= STABLE_SKIP_LIMIT:
		return false
	if abs(_last_ci_delta) > STABLE_DELTA_THRESHOLD:
		return false
	if _last_active_fraction < STABLE_ACTIVE_THRESHOLD:
		return false
	return true

func _is_environment_adjusting() -> bool:
	if abs(_heat_target - _heat) > ENV_TARGET_EPS:
		return true
	if abs(_moisture_target - _moisture) > ENV_TARGET_EPS:
		return true
	if abs(_breeze_target - _breeze) > ENV_TARGET_EPS:
		return true
	return false

func _record_stats_probe(tick_ms: float, smoothed_ci: float, active_fraction: float, ci_delta: float) -> void:
	if _stats_probe == null or not is_instance_valid(_stats_probe):
		_stats_probe = _get_stats_probe()
	if _stats_probe == null:
		return
	if _grid_cell_count <= 0.0:
		_grid_cell_count = float(SandboxGrid.get_cell_count())
	var active_cells: float = active_fraction * _grid_cell_count
	var pps: float = 0.0
	var power_ratio: float = 1.0
	if _statbus == null or not is_instance_valid(_statbus):
		_statbus = _get_statbus()
	if _statbus:
		pps = _statbus.get_stat(&"pps", 0.0)
		power_ratio = _statbus.get_stat(&"power_state", 1.0)
	_stats_probe.record_tick({
		"tick_ms": tick_ms,
		"pps": pps,
		"ci": smoothed_ci,
		"active_cells": active_cells,
		"power_ratio": power_ratio,
		"ci_delta": ci_delta
	})

func _initialize_metrics_buffers() -> void:
	_metrics_front.clear()
	_metrics_back.clear()
	_metrics_release_counter = 0

func _build_metrics(ci: float, bonus: float) -> Dictionary:
	return {
		"ci": ci,
		"bonus": bonus,
		"preset": _latest_state.get("preset", ""),
		"heat": _heat,
		"heat_target": _heat_target,
		"moisture": _moisture,
		"moisture_target": _moisture_target,
		"breeze": _breeze,
		"breeze_target": _breeze_target,
		"active_fraction": _last_active_fraction,
		"ci_delta": _last_ci_delta,
		"stability": float(_last_comfort.get("stability", 0.0)),
		"diversity": float(_last_comfort.get("diversity", 0.0)),
		"entropy": float(_last_comfort.get("entropy", 0.0)),
		"raw_ci": float(_last_comfort.get("ci", 0.0))
	}

func _store_metrics(metrics: Dictionary) -> void:
	if _metrics_double_buffer:
		_metrics_back = metrics.duplicate(true)
		_metrics_release_counter += 1
		if _metrics_release_counter >= _metrics_release_interval or _metrics_front.is_empty():
			_metrics_release_counter = 0
			_metrics_front = _metrics_back.duplicate(true)
	else:
		_metrics_front = metrics.duplicate(true)

func _get_environment() -> EnvironmentService:
	var node := get_node_or_null("/root/EnvironmentServiceSingleton")
	if node is EnvironmentService:
		return node as EnvironmentService
	return null

func _get_stats_probe() -> StatsProbe:
	var node := get_node_or_null("/root/StatsProbeSingleton")
	if node is StatsProbe:
		return node as StatsProbe
	return null

func _get_statbus() -> StatBus:
	if _statbus and is_instance_valid(_statbus):
		return _statbus
	var node := get_node_or_null("/root/StatBusSingleton")
	if node is StatBus:
		_statbus = node as StatBus
		return _statbus
	return null

func last_comfort_components() -> Dictionary:
	return _last_comfort.duplicate(true)
