extends Node
class_name SandboxService

signal ci_changed(ci: float, bonus: float)

const UPDATE_INTERVAL := 0.5 # 2 Hz
const SMOOTH_ALPHA := 0.25
const BONUS_CAP := 0.05

const StatBus: GDScript = preload("res://src/services/StatBus.gd")
const EnvironmentService: GDScript = preload("res://src/services/EnvironmentService.gd")
const SandboxGrid: GDScript = preload("res://src/sandbox/SandboxGrid.gd")
var _environment: EnvironmentService
var _statbus: StatBus
var _grid: SandboxGrid
var _last_comfort: Dictionary = {"ci": 0.0, "stability": 0.0, "diversity": 0.0, "entropy": 0.0}
var _latest_state: Dictionary = {}
var _smoothed_ci: float = 0.0
var _accumulator: float = 0.0
var _use_scheduler: bool = false

func _ready() -> void:
	_environment = _get_environment()
	if _environment and not _environment.environment_updated.is_connected(_on_environment_updated):
		_environment.environment_updated.connect(_on_environment_updated)
	_statbus = _get_statbus()
	_register_statbus_keys()
	_grid = SandboxGrid.new()
	_grid.seed_grid()
	set_process(true)
	_tick(0.0)

func current_ci() -> float:
	return _smoothed_ci

func current_bonus() -> float:
	return min(_smoothed_ci * BONUS_CAP, BONUS_CAP)

func _on_environment_updated(state: Dictionary) -> void:
	var previous_preset: StringName = _latest_state.get("preset", StringName())
	_latest_state = state.duplicate(true)
	if state.get("preset", StringName()) != previous_preset:
		_smoothed_ci = 0.0
	# Update immediately so UI reflects changes without waiting for next tick.
	_tick(0.0)
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
	var comfort_data: Dictionary = _compute_ci(_latest_state, delta)
	_last_comfort = comfort_data.duplicate(true)
	var raw_ci: float = float(comfort_data.get("ci", 0.0))
	_smoothed_ci = lerp(_smoothed_ci, raw_ci, SMOOTH_ALPHA)
	var bonus: float = current_bonus()
	_update_statbus(_smoothed_ci, bonus)
	emit_signal_ci(_smoothed_ci, bonus)

func emit_signal_ci(ci: float, bonus: float) -> void:
	ci_changed.emit(ci, bonus)

func _compute_ci(state: Dictionary, delta: float) -> Dictionary:
	if _grid == null or state.is_empty():
		return {"ci": 0.0}
	_grid.heat = clamp(float(state.get("temperature_c", 18.0)) / 35.0, 0.0, 1.0)
	_grid.moisture = clamp(float(state.get("humidity_pct", 60.0)) / 100.0, 0.0, 1.0)
	_grid.breeze = clamp(float(state.get("light_pct", 65.0)) / 100.0, 0.0, 1.0)
	if delta > 0.0:
		_grid.step(delta)

	return _grid.compute_comfort()

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

func _get_environment() -> EnvironmentService:
	var node := get_node_or_null("/root/EnvironmentServiceSingleton")
	if node is EnvironmentService:
		return node as EnvironmentService
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
