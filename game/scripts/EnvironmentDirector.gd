extends Node
class_name EnvironmentDirector

signal state_changed(pollution: float, stress: float, reputation: float)

const UPDATE_INTERVAL := 0.2
const DEFAULT_STAGE := StringName("backyard")

const STAGE_PATHS := {
	DEFAULT_STAGE: "res://game/scenes/modules/environment/EnvironmentStage_Backyard.tscn"
}

var _eco: Economy
var _research: Research
var _strings: StringsCatalog
var _environment_root: Node

var _pollution: float = 12.0
var _stress: float = 8.0
var _reputation: float = 72.0

var _accumulator: float = 0.0
var _current_stage_id: StringName = DEFAULT_STAGE
var _stage_nodes: Dictionary[StringName, EnvironmentStageBase] = {}
var _stage_cache: Dictionary[StringName, PackedScene] = {}
var _active_stage: EnvironmentStageBase
var _last_emitted: Vector3 = Vector3(-INF, -INF, -INF)

func set_sources(eco: Economy, research: Research, strings: StringsCatalog) -> void:
	if eco == _eco and research == _research and strings == _strings:
		return
	_disconnect_sources()
	_eco = eco
	_research = research
	_strings = strings
	_accumulator = 0.0
	_resolve_environment_root()
	_connect_sources()
	var tier := 1
	if _eco:
		tier = _eco.factory_tier
	_switch_stage_internal(_stage_for_tier(tier))
	_emit_state(true)

func update_environment(delta: float) -> void:
	if _eco == null:
		return
	_accumulator += delta
	while _accumulator >= UPDATE_INTERVAL:
		_accumulator -= UPDATE_INTERVAL
		_simulate_step(UPDATE_INTERVAL)

func switch_stage(stage_id: String) -> void:
	var key := StringName(stage_id)
	if key == StringName():
		key = DEFAULT_STAGE
	_switch_stage_internal(key)

func get_state() -> Dictionary:
	return {
		"pollution": _pollution,
		"stress": _stress,
		"reputation": _reputation
	}

func _connect_sources() -> void:
	if _eco:
		if not _eco.soft_changed.is_connected(_on_soft_changed):
			_eco.soft_changed.connect(_on_soft_changed)
		if not _eco.burst_state.is_connected(_on_burst_state):
			_eco.burst_state.connect(_on_burst_state)
		if not _eco.tier_changed.is_connected(_on_tier_changed):
			_eco.tier_changed.connect(_on_tier_changed)

func _disconnect_sources() -> void:
	if _eco:
		if _eco.soft_changed.is_connected(_on_soft_changed):
			_eco.soft_changed.disconnect(_on_soft_changed)
		if _eco.burst_state.is_connected(_on_burst_state):
			_eco.burst_state.disconnect(_on_burst_state)
		if _eco.tier_changed.is_connected(_on_tier_changed):
			_eco.tier_changed.disconnect(_on_tier_changed)

func _simulate_step(delta: float) -> void:
	var pollution_rate: float = _compute_pollution_rate()
	var mitigation_rate: float = _compute_mitigation_rate()
	var welfare_level: float = _compute_welfare_level()
	var ethics_bonus: float = _compute_ethics_bonus()
	var production: float = _eco.current_pps()

	_pollution = clamp(_pollution + production * pollution_rate * delta - mitigation_rate * delta, 0.0, 100.0)
	_stress = clamp(_stress + (_pollution * 0.01 - welfare_level) * delta, 0.0, 100.0)
	_reputation = clamp(_reputation + ((-_pollution * 0.05 - _stress * 0.03 + ethics_bonus) * delta), 0.0, 100.0)
	_emit_state()

func _emit_state(force_emit: bool = false) -> void:
	var current := Vector3(_pollution, _stress, _reputation)
	var delta_vec := current - _last_emitted
	var should_emit := force_emit or _last_emitted.x == -INF or delta_vec.length() >= 0.5
	_apply_state_to_stage()
	if should_emit:
		_last_emitted = current
		state_changed.emit(_pollution, _stress, _reputation)

func _apply_state_to_stage() -> void:
	if _active_stage and is_instance_valid(_active_stage):
		_active_stage.apply_state(_pollution, _stress, _reputation)

func _compute_pollution_rate() -> float:
	var feed_fraction: float = _eco.get_feed_fraction()
	var automation_penalty: float = 0.005 if _automation_active() else 0.0
	var burst_penalty: float = 0.01 if _eco.is_feeding() else 0.0
	var rate: float = 0.003 + automation_penalty + burst_penalty
	rate += (1.0 - feed_fraction) * 0.004
	return rate

func _compute_mitigation_rate() -> float:
	var mitigation: float = 0.05
	if _research:
		mitigation += _research.owned.size() * 0.01
	var upgrades := _eco.get_upgrade_levels()
	mitigation += int(upgrades.get("feed_storage", 0)) * 0.015
	mitigation += int(upgrades.get("feed_refill", 0)) * 0.012
	mitigation += int(upgrades.get("feed_efficiency", 0)) * 0.01
	return mitigation

func _compute_welfare_level() -> float:
	var base := 0.4
	base += _eco.get_feed_fraction() * 0.6
	if _automation_active():
		base -= 0.1
	return clamp(base, 0.0, 1.0)

func _compute_ethics_bonus() -> float:
	var bonus: float = 0.4
	if _research:
		bonus += _research.owned.size() * 0.02
	if not _automation_active():
		bonus += 0.25
	if _eco.get_feed_fraction() >= 0.8:
		bonus += 0.3
	return clamp(bonus, 0.0, 5.0)

func _automation_active() -> bool:
	if _eco == null:
		return false
	return _eco.is_feeding() and _eco.get_feed_fraction() < 0.5

func _resolve_environment_root() -> void:
	if _environment_root and is_instance_valid(_environment_root):
		return
	if _eco:
		var parent := _eco.get_parent()
		if parent and parent.has_node("EnvironmentRoot"):
			_environment_root = parent.get_node("EnvironmentRoot")

func _switch_stage_internal(stage_id: StringName) -> void:
	if stage_id == StringName():
		stage_id = DEFAULT_STAGE
	if stage_id == _current_stage_id and _active_stage and is_instance_valid(_active_stage):
		_apply_state_to_stage()
		return
	_current_stage_id = stage_id
	var stage := _get_or_create_stage(stage_id)
	if stage == null:
		return
	_activate_stage(stage)
	_log_stage_state()
	_emit_state(true)

func _get_or_create_stage(stage_id: StringName) -> EnvironmentStageBase:
	if _stage_nodes.has(stage_id):
		var cached := _stage_nodes[stage_id]
		if cached and is_instance_valid(cached):
			return cached
	_stage_nodes.erase(stage_id)
	var scene := _get_stage_scene(stage_id)
	if scene == null:
		return null
	if _environment_root == null:
		_resolve_environment_root()
	if _environment_root == null:
		return null
	var instance := scene.instantiate()
	if instance is EnvironmentStageBase:
		var stage := instance as EnvironmentStageBase
		_environment_root.add_child(stage)
		stage.position = Vector2.ZERO
		_stage_nodes[stage_id] = stage
		return stage
	instance.queue_free()
	return null

func _get_stage_scene(stage_id: StringName) -> PackedScene:
	if _stage_cache.has(stage_id):
		return _stage_cache[stage_id]
	var path_variant := STAGE_PATHS.get(stage_id, "")
	if String(path_variant) == "":
		return null
	var scene := ResourceLoader.load(String(path_variant))
	if scene is PackedScene:
		_stage_cache[stage_id] = scene
		return scene
	return null

func _activate_stage(stage: EnvironmentStageBase) -> void:
	for existing in _stage_nodes.values():
		if existing and is_instance_valid(existing):
			existing.visible = existing == stage
	_active_stage = stage
	_apply_state_to_stage()

func _stage_for_tier(tier: int) -> StringName:
	if tier <= 1:
		return DEFAULT_STAGE
	return DEFAULT_STAGE

func _on_soft_changed(_value: float) -> void:
	_emit_state(true)

func _on_burst_state(_active: bool) -> void:
	_emit_state(true)

func _on_tier_changed(tier: int) -> void:
	_switch_stage_internal(_stage_for_tier(tier))

func _log_stage_state() -> void:
	var logger := _get_logger()
	if logger:
		var stage_label := _stage_label(_current_stage_id)
		var message := "stage=%s pollution=%.1f stress=%.1f rep=%.1f" % [
			stage_label,
			_pollution,
			_stress,
			_reputation
		]
		logger.log("INFO", "ENV", message, {})

func _stage_label(stage_id: StringName) -> String:
	var key := "environment_stage_%s" % String(stage_id)
	if _strings:
		return _strings.get_text(key, String(stage_id).capitalize())
	return String(stage_id).capitalize()

func _get_logger() -> YolkLogger:
	var node := get_node_or_null("/root/Logger")
	if node is YolkLogger:
		return node as YolkLogger
	return null
