extends Control
class_name SandboxRenderer

signal fallback_state_changed(active: bool)

const SandboxService := preload("res://src/services/SandboxService.gd")
const SANDBOX_SERVICE_PATH := "/root/SandboxServiceSingleton"
const SandboxGrid := preload("res://src/sandbox/SandboxGrid.gd")
const StatsProbe := preload("res://src/services/StatsProbe.gd")
const SandboxEraLibrary := preload("res://src/sandbox/SandboxEraLibrary.gd")
const EnvironmentService := preload("res://src/services/EnvironmentService.gd")
const TopDownRenderer := preload("res://src/sandbox/TopDownRenderer.gd")
const PALETTE_KEYS := ["sky_top", "sky_bottom", "ground", "ground_horizon", "structure_body", "structure_roof", "detail", "haze_color"]

@export var target_fps: float = 30.0
@export var idle_fps: float = 10.0
@export var fallback_fps: float = 15.0
@export var smoothing_delta_threshold: float = 0.0002
@export var idle_threshold_samples: int = 8
@export var fallback_threshold_ms: float = 18.0
@export var fallback_resume_ms: float = 12.0
@export var fallback_trigger_seconds: float = 5.0
@export var fallback_recover_seconds: float = 5.0
@export var palette_transition_speed: float = 3.0
@export var comfort_lerp_speed: float = 2.0
@export var camera_transition_speed: float = 2.0
@export var particle_reseed_interval: float = 12.0
@export var view_mode: StringName = &"diorama"

var _sandbox_service: SandboxService
var _stats_probe: StatsProbe
var _environment_service: EnvironmentService
var _timer: float = 0.0
var _frame_interval: float = 1.0 / 30.0
var _idle_interval: float = 1.0 / 10.0
var _fallback_interval: float = 1.0 / 15.0
var _stable_sample_counter: int = 0
var _texture_rect: TextureRect
var _comfort_overlay_rect: ColorRect
var _viewport_root: Control
var _background_root: Control
var _midground_root: Control
var _particle_layer: Control
var _topdown_renderer: TopDownRenderer
var _prop_root: Control
var _sky_rect: ColorRect
var _sky_bottom_rect: ColorRect
var _haze_rect: ColorRect
var _ground_rect: ColorRect
var _ground_horizon_rect: ColorRect
var _structure_rect: ColorRect
var _structure_roof_rect: ColorRect
var _detail_rect: ColorRect
var _image: Image
var _texture: ImageTexture
var _last_hash: int = 0
var _fallback_active: bool = false
var _fallback_timer: float = 0.0
var _fallback_recovery_timer: float = 0.0
var _last_interval: float = 0.0
var _cached_target_fps: float = 30.0
var _cached_idle_fps: float = 10.0
var _cached_fallback_fps: float = 15.0
var _environment_state: Dictionary = {}
var _pollution_pct: float = 0.0
var _breeze_norm: float = 0.0
var _comfort_smoothed: float = 0.0
var _material_palette_current: Dictionary = {}
var _material_palette_target: Dictionary = {}
var _palette_current: Dictionary = {}
var _palette_target: Dictionary = {}
var _overlay_calm: Color = Color.WHITE
var _overlay_stressed: Color = Color(0, 0, 0, 0.2)
var _overlay_target_calm: Color = Color.WHITE
var _overlay_target_stressed: Color = Color(0, 0, 0, 0.2)
var _particle_nodes: Array[Dictionary] = []
var _particle_timer: float = 0.0
var _particle_amount: int = 0
var _particle_target_amount: int = 0
var _particle_color: Color = Color(1, 1, 1, 0.4)
var _particle_target_color: Color = Color(1, 1, 1, 0.4)
var _parallax_time: float = 0.0
var _parallax_amplitude: Vector2 = Vector2.ZERO
var _parallax_target_amplitude: Vector2 = Vector2.ZERO
var _parallax_speed: float = 0.2
var _parallax_target_speed: float = 0.2
var _structure_base_position: Vector2 = Vector2.ZERO
var _structure_roof_base_position: Vector2 = Vector2.ZERO
var _structure_size: Vector2 = Vector2.ZERO
var _detail_base_position: Vector2 = Vector2.ZERO
var _camera_zoom: float = 1.0
var _camera_target_zoom: float = 1.0
var _camera_offset: Vector2 = Vector2.ZERO
var _camera_target_offset: Vector2 = Vector2.ZERO
var _current_era: StringName = SandboxEraLibrary.era_for_preset(StringName("early_farm"))
var _target_era: StringName = SandboxEraLibrary.era_for_preset(StringName("early_farm"))
var _current_era_label: String = SandboxEraLibrary.default_label()
var _era_config_current: Dictionary = {}
var _era_config_target: Dictionary = {}
var _current_metrics: Dictionary = {}
var _random := RandomNumberGenerator.new()
var _era_initialized: bool = false
var _prop_nodes: Array[Dictionary] = []
var _progress_context: Dictionary = {
	"tier": 1,
	"research_count": 0,
	"research_nodes": PackedStringArray()
}

const MATERIAL_COLORS := {
	SandboxGrid.MATERIAL_AIR: Color(0.0, 0.0, 0.0, 0.0),
	SandboxGrid.MATERIAL_SAND: Color(0.894, 0.792, 0.561, 1.0),
	SandboxGrid.MATERIAL_WATER: Color(0.349, 0.541, 0.819, 0.95),
	SandboxGrid.MATERIAL_OIL: Color(0.203, 0.141, 0.090, 0.95),
	SandboxGrid.MATERIAL_FIRE: Color(0.984, 0.529, 0.215, 1.0),
	SandboxGrid.MATERIAL_PLANT: Color(0.278, 0.647, 0.392, 1.0),
	SandboxGrid.MATERIAL_STONE: Color(0.541, 0.533, 0.522, 1.0),
	SandboxGrid.MATERIAL_STEAM: Color(0.847, 0.886, 0.929, 0.85)
}

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_layout()

func _ready() -> void:
	_set_frame_interval(target_fps, idle_fps)
	_random.randomize()
	_build_visual_layers()
	_build_viewport_layer()
	_sandbox_service = get_node_or_null(SANDBOX_SERVICE_PATH) as SandboxService
	_stats_probe = get_node_or_null("/root/StatsProbeSingleton") as StatsProbe
	_environment_service = get_node_or_null("/root/EnvironmentServiceSingleton") as EnvironmentService
	_initialize_era_state()
	_connect_environment_signals()
	set_process(true)

func _set_frame_interval(active_fps: float, idle_fps_value: float) -> void:
	var active_value: float = max(active_fps, 1.0)
	var idle_value: float = max(idle_fps_value, 1.0)
	var fallback_value: float = clamp(fallback_fps, 1.0, active_value)
	_frame_interval = 1.0 / active_value
	_idle_interval = 1.0 / idle_value
	_fallback_interval = 1.0 / fallback_value
	_cached_target_fps = target_fps
	_cached_idle_fps = idle_fps
	_cached_fallback_fps = fallback_fps

func _build_visual_layers() -> void:
	if _background_root and is_instance_valid(_background_root):
		_background_root.queue_free()
	if _particle_layer and is_instance_valid(_particle_layer):
		_particle_layer.queue_free()
	_background_root = Control.new()
	_background_root.name = "BackgroundRoot"
	_background_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_background_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_background_root.z_index = 0
	add_child(_background_root)

	_sky_rect = _make_color_rect("SkyTop")
	_sky_rect.z_index = 0
	_background_root.add_child(_sky_rect)
	_sky_bottom_rect = _make_color_rect("SkyBottom")
	_sky_bottom_rect.z_index = 1
	_background_root.add_child(_sky_bottom_rect)
	_haze_rect = _make_color_rect("Haze")
	_haze_rect.z_index = 2
	_background_root.add_child(_haze_rect)

	_midground_root = Control.new()
	_midground_root.name = "MidgroundRoot"
	_midground_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_midground_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_midground_root.z_index = 1
	_background_root.add_child(_midground_root)

	_ground_rect = _make_color_rect("Ground")
	_ground_rect.z_index = 3
	_midground_root.add_child(_ground_rect)
	_ground_horizon_rect = _make_color_rect("GroundHorizon")
	_ground_horizon_rect.z_index = 4
	_midground_root.add_child(_ground_horizon_rect)
	_structure_rect = _make_color_rect("StructureBody")
	_structure_rect.z_index = 5
	_midground_root.add_child(_structure_rect)
	_structure_roof_rect = _make_color_rect("StructureRoof")
	_structure_roof_rect.z_index = 6
	_midground_root.add_child(_structure_roof_rect)
	_detail_rect = _make_color_rect("DetailStrip")
	_detail_rect.z_index = 7
	_midground_root.add_child(_detail_rect)
	_prop_root = Control.new()
	_prop_root.name = "PropLayer"
	_prop_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prop_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_prop_root.z_index = 8
	_midground_root.add_child(_prop_root)

	_particle_layer = Control.new()
	_particle_layer.name = "ParticleLayer"
	_particle_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_particle_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_particle_layer.z_index = 8
	_background_root.add_child(_particle_layer)

	_update_layout()

func _build_viewport_layer() -> void:
	if _viewport_root and is_instance_valid(_viewport_root):
		_viewport_root.queue_free()
	_viewport_root = Control.new()
	_viewport_root.name = "ViewportRoot"
	_viewport_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewport_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_viewport_root.z_index = 10
	add_child(_viewport_root)
	_texture_rect = TextureRect.new()
	_texture_rect.name = "ViewportTexture"
	_texture_rect.expand = true
	_texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_texture_rect.z_index = 11
	_viewport_root.add_child(_texture_rect)
	_comfort_overlay_rect = ColorRect.new()
	_comfort_overlay_rect.name = "ComfortOverlay"
	_comfort_overlay_rect.color = Color(0, 0, 0, 0)
	_comfort_overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_comfort_overlay_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_comfort_overlay_rect.z_index = 12
	_viewport_root.add_child(_comfort_overlay_rect)
	if _topdown_renderer and is_instance_valid(_topdown_renderer):
		_topdown_renderer.queue_free()
	_topdown_renderer = TopDownRenderer.new()
	_topdown_renderer.name = "TopDownRenderer"
	_topdown_renderer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_topdown_renderer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_topdown_renderer.z_index = 1000
	_topdown_renderer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_topdown_renderer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_topdown_renderer.visible = false
	add_child(_topdown_renderer)
	_sync_topdown_renderer_bounds()
	_update_view_mode_visibility(false)

func _initialize_era_state() -> void:
	var preset: StringName = StringName("early_farm")
	if _environment_service and is_instance_valid(_environment_service):
		preset = _environment_service.get_preset()
	_set_target_era(preset, true)

func _connect_environment_signals() -> void:
	if _environment_service == null or not is_instance_valid(_environment_service):
		return
	if not _environment_service.environment_updated.is_connected(_on_environment_state_changed):
		_environment_service.environment_updated.connect(_on_environment_state_changed)
	if not _environment_service.preset_changed.is_connected(_on_environment_preset_changed):
		_environment_service.preset_changed.connect(_on_environment_preset_changed)
	var state: Dictionary = _environment_service.get_state()
	if not state.is_empty():
		_on_environment_state_changed(state)

func _on_environment_state_changed(state: Dictionary) -> void:
	_environment_state = state.duplicate(true)
	if _topdown_renderer and is_instance_valid(_topdown_renderer):
		_topdown_renderer.update_environment_state(_environment_state)
	var preset_variant: Variant = state.get("preset", _current_era)
	var preset: StringName
	if preset_variant is StringName:
		preset = preset_variant
	else:
		preset = StringName(String(preset_variant))
	_pollution_pct = float(state.get("pollution", _pollution_pct))
	_breeze_norm = clamp(float(state.get("breeze_norm", _breeze_norm)), 0.0, 1.0)
	_set_target_era(preset, not _era_initialized)

func _on_environment_preset_changed(preset: StringName) -> void:
	_set_target_era(preset, not _era_initialized)

func _set_target_era(preset: StringName, immediate: bool = false) -> void:
	var era_id: StringName = SandboxEraLibrary.era_for_preset(preset)
	if immediate or not _era_initialized:
		_era_initialized = true
		_current_era = era_id
		_target_era = era_id
		_era_config_current = SandboxEraLibrary.config_for_era(era_id)
		_era_config_target = _era_config_current.duplicate(true)
		_apply_palette_from_config(_era_config_current, true)
		_apply_material_palette(_era_config_current, true)
		_apply_overlay_from_config(_era_config_current, true)
		_apply_parallax_from_config(_era_config_current, true)
		_apply_camera_from_config(_era_config_current, true)
		_configure_particles(_era_config_current, true)
		_configure_props(_era_config_current, true)
		_current_era_label = String(_era_config_current.get("label", SandboxEraLibrary.default_label()))
		_refresh_current_metrics()
		_update_palette_nodes()
		return
	if era_id == _target_era and _era_config_target.is_empty() == false:
		return
	_target_era = era_id
	_era_config_target = SandboxEraLibrary.config_for_era(era_id)
	_apply_palette_from_config(_era_config_target, false)
	_apply_material_palette(_era_config_target, false)
	_apply_overlay_from_config(_era_config_target, false)
	_apply_parallax_from_config(_era_config_target, false)
	_apply_camera_from_config(_era_config_target, false)
	_configure_particles(_era_config_target, false)
	_configure_props(_era_config_target, false)
	_current_era_label = String(_era_config_target.get("label", SandboxEraLibrary.default_label()))
	_refresh_current_metrics()

func set_view_mode(mode: StringName) -> void:
	var normalized := _normalize_view_mode(mode)
	var changed := view_mode != normalized
	view_mode = normalized
	_update_view_mode_visibility(changed)

func _normalize_view_mode(mode: StringName) -> StringName:
	return StringName("map") if mode == StringName("map") else StringName("diorama")

func _update_view_mode_visibility(log_change: bool = true) -> void:
	var show_diorama := view_mode != StringName("map")
	if _background_root:
		_background_root.visible = show_diorama
	if _viewport_root:
		_viewport_root.visible = show_diorama
	if _texture_rect:
		_texture_rect.visible = not show_diorama  # show only in map mode
	if _comfort_overlay_rect:
		_comfort_overlay_rect.visible = show_diorama
	if _topdown_renderer and is_instance_valid(_topdown_renderer):
		_topdown_renderer.set_active(not show_diorama)
		_sync_topdown_renderer_bounds()
	if log_change:
		_print_view_mode_debug(show_diorama)

func _print_view_mode_debug(show_diorama: bool) -> void:
	var map_visible := false
	if _topdown_renderer and is_instance_valid(_topdown_renderer):
		map_visible = _topdown_renderer.visible
	print("[SandboxView] view=%s diorama.visible=%s topdown.visible=%s" % [
		String(view_mode),
		str(show_diorama),
		str(map_visible)
	])

func _refresh_current_metrics() -> void:
	_current_metrics["era_label"] = _current_era_label
	_current_metrics["era_id"] = String(_target_era)

func _apply_palette_from_config(config: Dictionary, immediate: bool) -> void:
	var palette_config: Dictionary = config.get("palette", {})
	var target_palette: Dictionary = {}
	for key_variant in PALETTE_KEYS:
		var key: String = String(key_variant)
		var color_variant: Variant = palette_config.get(key, _palette_target.get(key, _palette_current.get(key, Color(1, 1, 1, 1))))
		var color_value: Color
		if color_variant is Color:
			color_value = color_variant
		else:
			color_value = Color(color_variant)
		target_palette[key] = color_value
		if immediate or not _palette_current.has(key):
			_palette_current[key] = color_value
	_palette_target = target_palette

func _default_material_palette() -> Dictionary:
	var palette: Dictionary = {}
	for key in MATERIAL_COLORS.keys():
		var material_id: int = int(key)
		palette[material_id] = MATERIAL_COLORS[key]
	return palette

func _apply_material_palette(config: Dictionary, immediate: bool) -> void:
	var overrides: Dictionary = config.get("material_palette", {})
	var target_palette: Dictionary = _default_material_palette()
	for mat_key in overrides.keys():
		var material_id: int = int(mat_key)
		var override_value: Variant = overrides[mat_key]
		var color_override: Color
		if override_value is Color:
			color_override = override_value
		else:
			color_override = Color(override_value)
		target_palette[material_id] = color_override
	_material_palette_target = target_palette
	if immediate or _material_palette_current.is_empty():
		_material_palette_current = target_palette.duplicate(true)

func _apply_overlay_from_config(config: Dictionary, immediate: bool) -> void:
	var overlay_cfg: Dictionary = config.get("comfort_overlay", {})
	var calm_variant: Variant = overlay_cfg.get("calm", _overlay_target_calm)
	var stressed_variant: Variant = overlay_cfg.get("stressed", _overlay_target_stressed)
	var calm_color: Color = calm_variant if calm_variant is Color else Color(calm_variant)
	var stressed_color: Color = stressed_variant if stressed_variant is Color else Color(stressed_variant)
	_overlay_target_calm = calm_color
	_overlay_target_stressed = stressed_color
	if immediate:
		_overlay_calm = calm_color
		_overlay_stressed = stressed_color

func _apply_parallax_from_config(config: Dictionary, immediate: bool) -> void:
	var parallax_cfg: Dictionary = config.get("parallax", {})
	var amplitude_variant: Variant = parallax_cfg.get("amplitude", _parallax_target_amplitude)
	var amplitude: Vector2
	if amplitude_variant is Vector2:
		amplitude = amplitude_variant
	else:
		amplitude = Vector2(float(amplitude_variant), float(amplitude_variant))
	var speed: float = float(parallax_cfg.get("speed", _parallax_target_speed))
	_parallax_target_amplitude = amplitude
	_parallax_target_speed = speed
	if immediate:
		_parallax_amplitude = amplitude
		_parallax_speed = speed

func _apply_camera_from_config(config: Dictionary, immediate: bool) -> void:
	var camera_cfg: Dictionary = config.get("camera", {})
	var zoom_value: float = float(camera_cfg.get("zoom", _camera_target_zoom))
	var offset_variant: Variant = camera_cfg.get("offset", _camera_target_offset)
	var offset: Vector2 = _vector2_from_variant(offset_variant, _camera_target_offset)
	_camera_target_zoom = max(zoom_value, 0.5)
	_camera_target_offset = offset
	if immediate:
		_camera_zoom = _camera_target_zoom
		_camera_offset = _camera_target_offset
		_apply_camera_transform()

func _configure_particles(config: Dictionary, immediate: bool) -> void:
	var particle_cfg: Dictionary = config.get("particle", {})
	var amount: int = int(particle_cfg.get("amount", _particle_target_amount if _particle_target_amount > 0 else 20))
	var color_variant: Variant = particle_cfg.get("color", _particle_target_color)
	var color_value: Color = color_variant if color_variant is Color else Color(color_variant)
	_particle_target_color = color_value
	_particle_target_amount = amount
	_rebuild_particles(amount, color_value)

func _configure_props(config: Dictionary, _immediate: bool) -> void:
	_clear_prop_nodes()
	if _prop_root == null or not is_instance_valid(_prop_root):
		return
	var props_variant: Variant = config.get("props", [])
	var props: Array = props_variant if props_variant is Array else []
	for prop_variant in props:
		if prop_variant is Dictionary:
			var prop_config: Dictionary = (prop_variant as Dictionary).duplicate(true)
			var node := _create_prop_node(prop_config)
			if node:
				_prop_root.add_child(node)
				_prop_nodes.append({
					"node": node,
					"config": prop_config
				})
	_update_props_layout(get_size())
	_refresh_prop_visibility()

func _clear_prop_nodes() -> void:
	if _prop_nodes.is_empty():
		return
	for entry in _prop_nodes:
		var node := entry.get("node") as Control
		if node and is_instance_valid(node):
			node.queue_free()
	_prop_nodes.clear()

func _create_prop_node(config: Dictionary) -> Control:
	var color: Color = _color_from_variant(config.get("color", Color(1, 1, 1, 1)))
	var corner_radius: int = int(config.get("corner_radius", 8))
	var panel := PanelContainer.new()
	panel.name = String(config.get("id", "Prop"))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = 0.0
	panel.offset_top = 0.0
	panel.offset_right = 0.0
	panel.offset_bottom = 0.0
	panel.z_index = int(config.get("z", 9))
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(corner_radius)
	style.set_border_width_all(0)
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _update_props_layout(size: Vector2) -> void:
	if _prop_nodes.is_empty() or size == Vector2.ZERO:
		return
	for entry in _prop_nodes:
		var node := entry.get("node") as Control
		if node == null:
			continue
		var config: Dictionary = entry.get("config", {})
		var norm_size: Vector2 = _vector2_from_variant(config.get("size", Vector2(0.15, 0.2)), Vector2(0.15, 0.2))
		var norm_position: Vector2 = _vector2_from_variant(config.get("position", Vector2(0.5, 0.5)), Vector2(0.5, 0.5))
		var pixel_size := Vector2(norm_size.x * size.x, norm_size.y * size.y)
		node.size = pixel_size
		node.position = Vector2(norm_position.x * size.x - pixel_size.x * 0.5, norm_position.y * size.y - pixel_size.y * 0.5)

func _refresh_prop_visibility() -> void:
	if _prop_nodes.is_empty():
		return
	var tier := int(_progress_context.get("tier", 1))
	var research_count := int(_progress_context.get("research_count", 0))
	var research_nodes: Variant = _progress_context.get("research_nodes", PackedStringArray())
	for entry in _prop_nodes:
		var node := entry.get("node") as Control
		if node == null:
			continue
		var config: Dictionary = entry.get("config", {})
		var requires_tier: int = int(config.get("requires_tier", 0))
		var requires_research_count: int = int(config.get("requires_research_count", 0))
		var requires_id: String = String(config.get("requires_research_id", ""))
		var visible := true
		if requires_tier > 0 and tier < requires_tier:
			visible = false
		if requires_research_count > 0 and research_count < requires_research_count:
			visible = false
		if requires_id != "" and not _progress_nodeset_contains(research_nodes, requires_id):
			visible = false
		if node.visible != visible:
			node.visible = visible

func set_progress_context(context: Dictionary) -> void:
	var tier_value: int = int(context.get("tier", _progress_context.get("tier", 1)))
	var research_count_value: int = int(context.get("research_count", _progress_context.get("research_count", 0)))
	var nodes_variant: Variant = context.get("research_nodes", _progress_context.get("research_nodes", PackedStringArray()))
	var packed_nodes := _ensure_packed_string_array(nodes_variant)
	_progress_context = {
		"tier": tier_value,
		"research_count": research_count_value,
		"research_nodes": packed_nodes
	}
	_refresh_prop_visibility()

func _ensure_packed_string_array(value: Variant) -> PackedStringArray:
	if value is PackedStringArray:
		return value
	var result := PackedStringArray()
	if value is Array:
		var array_value: Array = value
		for entry in array_value:
			result.push_back(String(entry))
	elif value is StringName or value is String:
		result.push_back(String(value))
	return result

func _progress_nodeset_contains(source: Variant, id: String) -> bool:
	if id == "":
		return true
	if source is PackedStringArray:
		return (source as PackedStringArray).has(id)
	if source is Array:
		return (source as Array).has(id)
	return false

func _vector2_from_variant(value: Variant, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value
	if value is Array:
		var arr: Array = value
		if arr.size() >= 2:
			return Vector2(float(arr[0]), float(arr[1]))
	if value is Dictionary:
		var dict_value: Dictionary = value
		if dict_value.has("x") and dict_value.has("y"):
			return Vector2(float(dict_value.get("x", fallback.x)), float(dict_value.get("y", fallback.y)))
	if value is float or value is int:
		var scalar: float = float(value)
		return Vector2(scalar, scalar)
	return fallback

func _color_from_variant(value: Variant, fallback: Color = Color(1, 1, 1, 1)) -> Color:
	if value is Color:
		return value
	if value is String or value is StringName:
		return Color(value)
	return fallback if value == null else Color(value)

func _rebuild_particles(target_amount: int, color: Color) -> void:
	if _particle_layer == null or not is_instance_valid(_particle_layer):
		_particle_nodes.clear()
		_particle_amount = 0
		_particle_target_amount = target_amount
		_particle_color = color
		_particle_target_color = color
		return
	for i in range(_particle_nodes.size() - 1, target_amount - 1, -1):
		var entry: Dictionary = _particle_nodes[i]
		var node := entry.get("node") as ColorRect
		if node:
			node.queue_free()
		_particle_nodes.remove_at(i)
	var canvas_size: Vector2 = get_size()
	while _particle_nodes.size() < target_amount:
		var node := ColorRect.new()
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.anchor_left = 0.0
		node.anchor_top = 0.0
		node.anchor_right = 0.0
		node.anchor_bottom = 0.0
		node.size = Vector2(4.0, 4.0)
		node.color = color
		node.modulate = color
		node.z_index = 9
		_particle_layer.add_child(node)
		var base := _random_position_for_particle(canvas_size)
		node.position = base
		var entry := {
			"node": node,
			"base": base,
			"phase": _random.randf_range(0.0, TAU),
			"speed": _random.randf_range(0.6, 1.3)
		}
		_particle_nodes.append(entry)
	for i in range(_particle_nodes.size()):
		var entry: Dictionary = _particle_nodes[i]
		var node := entry.get("node") as ColorRect
		if node:
			node.color = color
			node.modulate = color
	_particle_amount = _particle_nodes.size()
	_particle_target_amount = target_amount
	_particle_color = color
	_particle_target_color = color
	_particle_timer = 0.0

func _update_visual_state(delta: float, comfort: Dictionary) -> void:
	_update_palette_transition(delta)
	_update_material_palette_transition(delta)
	_update_overlay_colors(delta, comfort)
	_update_parallax_nodes(delta)
	_update_particles(delta)
	_update_haze_color_from_palette()
	_update_camera_transform(delta)

func _update_palette_transition(delta: float) -> void:
	if _palette_target.is_empty():
		return
	var blend: float = clamp(delta * palette_transition_speed, 0.0, 1.0)
	for key_variant in PALETTE_KEYS:
		var key: String = String(key_variant)
		if not _palette_current.has(key) or not _palette_target.has(key):
			continue
		var current_color: Color = _palette_current[key]
		var target_color: Color = _palette_target[key]
		_palette_current[key] = current_color.lerp(target_color, blend)
	_update_palette_nodes()

func _update_material_palette_transition(delta: float) -> void:
	if _material_palette_target.is_empty():
		return
	var blend: float = clamp(delta * palette_transition_speed, 0.0, 1.0)
	for key in _material_palette_target.keys():
		var material_id: int = int(key)
		var target_color: Color = _material_palette_target[material_id]
		var current_color: Color = _material_palette_current.get(material_id, target_color)
		_material_palette_current[material_id] = current_color.lerp(target_color, blend)

func _update_overlay_colors(delta: float, comfort: Dictionary) -> void:
	var blend: float = clamp(delta * palette_transition_speed, 0.0, 1.0)
	_overlay_calm = _overlay_calm.lerp(_overlay_target_calm, blend)
	_overlay_stressed = _overlay_stressed.lerp(_overlay_target_stressed, blend)
	var ci_value: float = 0.0
	if comfort.has("ci_smoothed"):
		ci_value = float(comfort.get("ci_smoothed", 0.0))
	else:
		ci_value = float(comfort.get("ci", _comfort_smoothed))
	ci_value = clamp(ci_value, 0.0, 1.0)
	var comfort_blend: float = clamp(delta * comfort_lerp_speed, 0.0, 1.0)
	_comfort_smoothed = lerp(_comfort_smoothed, ci_value, comfort_blend)
	if _comfort_overlay_rect:
		var overlay_color: Color = _overlay_stressed.lerp(_overlay_calm, _comfort_smoothed)
		_comfort_overlay_rect.color = overlay_color

func _update_parallax_nodes(delta: float) -> void:
	var blend: float = clamp(delta * palette_transition_speed, 0.0, 1.0)
	_parallax_amplitude = _parallax_amplitude.lerp(_parallax_target_amplitude, blend)
	_parallax_speed = lerp(_parallax_speed, _parallax_target_speed, blend)
	_parallax_time += delta * _parallax_speed
	var offset := Vector2(sin(_parallax_time) * _parallax_amplitude.x, cos(_parallax_time * 0.8) * _parallax_amplitude.y)
	if _structure_rect:
		_structure_rect.position = _structure_base_position + offset
	if _structure_roof_rect:
		_structure_roof_rect.position = _structure_roof_base_position + offset
	if _detail_rect:
		var detail_offset := Vector2(cos(_parallax_time * 1.3) * _parallax_amplitude.x * 0.5, sin(_parallax_time * 1.1) * _parallax_amplitude.y * 0.35)
		_detail_rect.position = _detail_base_position + detail_offset

func _update_particles(delta: float) -> void:
	if _particle_nodes.is_empty():
		return
	var blend: float = clamp(delta * palette_transition_speed, 0.0, 1.0)
	_particle_color = _particle_color.lerp(_particle_target_color, blend)
	_particle_timer += delta
	var size: Vector2 = get_size()
	var breeze_scale: float = lerp(0.6, 1.6, _breeze_norm)
	for i in range(_particle_nodes.size()):
		var entry: Dictionary = _particle_nodes[i]
		var node := entry.get("node") as ColorRect
		if node == null:
			continue
		var base_speed: float = float(entry.get("speed", 1.0))
		var phase: float = float(entry.get("phase", 0.0)) + base_speed * breeze_scale * delta
		entry["phase"] = phase
		var base_pos: Vector2 = entry.get("base", node.position)
		var offset := Vector2(sin(phase) * _parallax_amplitude.x * 0.12, cos(phase * 0.9) * _parallax_amplitude.y * 0.16)
		node.position = base_pos + offset
		node.color = _particle_color
		node.modulate = _particle_color
	if particle_reseed_interval > 0.0 and _particle_timer >= particle_reseed_interval:
		_particle_timer = 0.0
		_reset_particle_positions(size)

func _update_camera_transform(delta: float) -> void:
	if _viewport_root == null or not is_instance_valid(_viewport_root):
		return
	var blend: float = clamp(delta * camera_transition_speed, 0.0, 1.0)
	_camera_zoom = lerp(_camera_zoom, _camera_target_zoom, blend)
	_camera_offset = _camera_offset.lerp(_camera_target_offset, blend)
	_apply_camera_transform()

func _apply_camera_transform() -> void:
	if _viewport_root == null or not is_instance_valid(_viewport_root):
		return
	var zoom_value: float = max(_camera_zoom, 0.1)
	_viewport_root.scale = Vector2(zoom_value, zoom_value)
	var size: Vector2 = get_size()
	if size == Vector2.ZERO:
		_viewport_root.position = Vector2.ZERO
		return
	var center := size * 0.5
	var scaled_center := center * zoom_value
	var offset_pixels := _camera_offset
	_viewport_root.position = center - scaled_center + offset_pixels

func _update_palette_nodes() -> void:
	if _palette_current.is_empty():
		return
	if _sky_rect and _palette_current.has("sky_top"):
		_sky_rect.color = _palette_current["sky_top"]
	if _sky_bottom_rect and _palette_current.has("sky_bottom"):
		var bottom_color: Color = _palette_current["sky_bottom"]
		_sky_bottom_rect.color = bottom_color
	if _ground_rect and _palette_current.has("ground"):
		_ground_rect.color = _palette_current["ground"]
	if _ground_horizon_rect and _palette_current.has("ground_horizon"):
		_ground_horizon_rect.color = _palette_current["ground_horizon"]
	if _structure_rect and _palette_current.has("structure_body"):
		_structure_rect.color = _palette_current["structure_body"]
	if _structure_roof_rect and _palette_current.has("structure_roof"):
		_structure_roof_rect.color = _palette_current["structure_roof"]
	if _detail_rect and _palette_current.has("detail"):
		_detail_rect.color = _palette_current["detail"]

func _update_haze_color_from_palette() -> void:
	if _haze_rect == null:
		return
	var haze_color: Color = _palette_current.get("haze_color", _haze_rect.color)
	var pollution_ratio: float = clamp(_pollution_pct / 100.0, 0.0, 1.0)
	var base_alpha: float = clamp(haze_color.a, 0.0, 1.0)
	var max_alpha: float = clamp(base_alpha + 0.35, 0.0, 0.65)
	var adjusted_alpha: float = lerp(base_alpha, max_alpha, pollution_ratio)
	_haze_rect.color = Color(haze_color.r, haze_color.g, haze_color.b, adjusted_alpha)

func _material_color_for(material: int) -> Color:
	if _material_palette_current.has(material):
		return _material_palette_current[material]
	if MATERIAL_COLORS.has(material):
		return MATERIAL_COLORS[material]
	return Color(0.1, 0.1, 0.1, 1.0)

func get_renderer_metrics() -> Dictionary:
	var metrics: Dictionary = _current_metrics.duplicate(true)
	metrics["fallback_active"] = _fallback_active
	metrics["pollution_pct"] = _pollution_pct
	metrics["comfort"] = _comfort_smoothed
	metrics["camera_zoom"] = _camera_zoom
	metrics["progress_tier"] = int(_progress_context.get("tier", 1))
	metrics["view_mode"] = String(view_mode)
	return metrics

func is_fallback_active() -> bool:
	return _fallback_active

func _update_layout() -> void:
	var size: Vector2 = get_size()
	if size.x <= 0.0 or size.y <= 0.0:
		return
	if _sky_rect:
		_sky_rect.anchor_left = 0.0
		_sky_rect.anchor_right = 1.0
		_sky_rect.anchor_top = 0.0
		_sky_rect.anchor_bottom = 1.0
		_sky_rect.offset_left = 0.0
		_sky_rect.offset_top = 0.0
		_sky_rect.offset_right = 0.0
		_sky_rect.offset_bottom = 0.0
	if _sky_bottom_rect:
		_sky_bottom_rect.anchor_left = 0.0
		_sky_bottom_rect.anchor_right = 1.0
		_sky_bottom_rect.anchor_top = 0.38
		_sky_bottom_rect.anchor_bottom = 1.0
		_sky_bottom_rect.offset_left = 0.0
		_sky_bottom_rect.offset_top = 0.0
		_sky_bottom_rect.offset_right = 0.0
		_sky_bottom_rect.offset_bottom = 0.0
	if _haze_rect:
		_haze_rect.anchor_left = 0.0
		_haze_rect.anchor_right = 1.0
		_haze_rect.anchor_top = 0.0
		_haze_rect.anchor_bottom = 1.0
		_haze_rect.offset_left = 0.0
		_haze_rect.offset_top = 0.0
		_haze_rect.offset_right = 0.0
		_haze_rect.offset_bottom = 0.0
	if _ground_rect:
		_ground_rect.anchor_left = 0.0
		_ground_rect.anchor_right = 1.0
		_ground_rect.anchor_top = 0.62
		_ground_rect.anchor_bottom = 1.0
		_ground_rect.offset_left = 0.0
		_ground_rect.offset_top = 0.0
		_ground_rect.offset_right = 0.0
		_ground_rect.offset_bottom = 0.0
	if _ground_horizon_rect:
		_ground_horizon_rect.anchor_left = 0.0
		_ground_horizon_rect.anchor_right = 1.0
		_ground_horizon_rect.anchor_top = 0.58
		_ground_horizon_rect.anchor_bottom = 0.62
		_ground_horizon_rect.offset_left = 0.0
		_ground_horizon_rect.offset_top = 0.0
		_ground_horizon_rect.offset_right = 0.0
		_ground_horizon_rect.offset_bottom = 0.0
	var width: float = size.x
	var height: float = size.y
	var structure_width: float = width * 0.24
	var structure_height: float = height * 0.24
	if _structure_rect:
		_structure_rect.anchor_left = 0.0
		_structure_rect.anchor_top = 0.0
		_structure_rect.anchor_right = 0.0
		_structure_rect.anchor_bottom = 0.0
		_structure_rect.position = Vector2(width * 0.24, height * 0.48)
		_structure_rect.size = Vector2(structure_width, structure_height)
		_structure_base_position = _structure_rect.position
		_structure_size = _structure_rect.size
	if _structure_roof_rect:
		_structure_roof_rect.anchor_left = 0.0
		_structure_roof_rect.anchor_top = 0.0
		_structure_roof_rect.anchor_right = 0.0
		_structure_roof_rect.anchor_bottom = 0.0
		_structure_roof_rect.position = Vector2(_structure_base_position.x - 8.0, _structure_base_position.y - structure_height * 0.35)
		_structure_roof_rect.size = Vector2(structure_width + 16.0, structure_height * 0.34)
		_structure_roof_base_position = _structure_roof_rect.position
	if _detail_rect:
		_detail_rect.anchor_left = 0.0
		_detail_rect.anchor_top = 0.0
		_detail_rect.anchor_right = 0.0
		_detail_rect.anchor_bottom = 0.0
		_detail_rect.position = Vector2(width * 0.08, height * 0.64)
		_detail_rect.size = Vector2(width * 0.64, height * 0.05)
		_detail_base_position = _detail_rect.position
	if _prop_root:
		_prop_root.anchor_left = 0.0
		_prop_root.anchor_top = 0.0
		_prop_root.anchor_right = 1.0
		_prop_root.anchor_bottom = 1.0
		_prop_root.offset_left = 0.0
		_prop_root.offset_top = 0.0
		_prop_root.offset_right = 0.0
		_prop_root.offset_bottom = 0.0
	if _particle_layer:
		_particle_layer.anchor_left = 0.0
		_particle_layer.anchor_right = 1.0
		_particle_layer.anchor_top = 0.0
		_particle_layer.anchor_bottom = 1.0
		_particle_layer.offset_left = 0.0
		_particle_layer.offset_top = 0.0
		_particle_layer.offset_right = 0.0
		_particle_layer.offset_bottom = 0.0
	if _viewport_root:
		_viewport_root.anchor_left = 0.0
		_viewport_root.anchor_top = 0.0
		_viewport_root.anchor_right = 1.0
		_viewport_root.anchor_bottom = 1.0
		_viewport_root.offset_left = 0.0
		_viewport_root.offset_top = 0.0
		_viewport_root.offset_right = 0.0
		_viewport_root.offset_bottom = 0.0
	if _topdown_renderer:
		_sync_topdown_renderer_bounds()
	_reset_particle_positions(size)
	_update_props_layout(size)
	_apply_camera_transform()

func _reset_particle_positions(size: Vector2) -> void:
	if _particle_nodes.is_empty():
		return
	for i in range(_particle_nodes.size()):
		var entry: Dictionary = _particle_nodes[i]
		var node := entry.get("node") as ColorRect
		if node == null:
			continue
		var base_position := _random_position_for_particle(size)
		entry["base"] = base_position
		node.position = base_position
	_particle_amount = _particle_nodes.size()

func _random_position_for_particle(size: Vector2) -> Vector2:
	var min_y: float = size.y * 0.18
	var max_y: float = size.y * 0.72
	return Vector2(_random.randf_range(0.0, max(size.x, 1.0)), _random.randf_range(min_y, max_y))

func _make_color_rect(name: String) -> ColorRect:
	var rect := ColorRect.new()
	rect.name = name
	rect.color = Color(1, 1, 1, 1)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.position = Vector2.ZERO
	rect.z_index = 0
	return rect

func _sync_topdown_renderer_bounds() -> void:
	if _topdown_renderer == null or not is_instance_valid(_topdown_renderer):
		return
	_topdown_renderer.anchor_left = 0.0
	_topdown_renderer.anchor_top = 0.0
	_topdown_renderer.anchor_right = 1.0
	_topdown_renderer.anchor_bottom = 1.0
	_topdown_renderer.offset_left = 0.0
	_topdown_renderer.offset_top = 0.0
	_topdown_renderer.offset_right = 0.0
	_topdown_renderer.offset_bottom = 0.0
	var bounds := get_size()
	if bounds != Vector2.ZERO:
		_topdown_renderer.custom_minimum_size = bounds
		_topdown_renderer.set_deferred("size", bounds)


func _process(delta: float) -> void:
	if not is_equal_approx(_cached_target_fps, target_fps) or not is_equal_approx(_cached_idle_fps, idle_fps) or not is_equal_approx(_cached_fallback_fps, fallback_fps):
		_set_frame_interval(target_fps, idle_fps)
	if _sandbox_service == null or not is_instance_valid(_sandbox_service):
		_sandbox_service = get_node_or_null(SANDBOX_SERVICE_PATH) as SandboxService
	var comfort: Dictionary = {}
	if _sandbox_service and is_instance_valid(_sandbox_service):
		comfort = _sandbox_service.last_comfort_components()
	_update_visual_state(delta, comfort)
	if _sandbox_service == null or not is_instance_valid(_sandbox_service):
		return
	var ci_delta: float = float(comfort.get("ci_delta", 0.0))
	var base_interval := _fallback_interval if _fallback_active else _frame_interval
	var interval := base_interval
	if abs(ci_delta) <= smoothing_delta_threshold:
		_stable_sample_counter += 1
		if _stable_sample_counter >= idle_threshold_samples:
			interval = max(_idle_interval, base_interval)
	else:
		_stable_sample_counter = 0
	interval = max(interval, 0.0001)
	_last_interval = interval
	_timer += delta
	if _timer < interval:
		return
	_timer -= interval
	_render_grid(comfort)

func _render_grid(comfort: Dictionary) -> void:
	var start := Time.get_ticks_usec()
	var snapshot: Array = _sandbox_service.current_snapshot()
	if snapshot.is_empty():
		return
	var height := snapshot.size()
	if height <= 0:
		return
	var row0_variant: Variant = snapshot[0]
	if not (row0_variant is Array):
		return
	var row0: Array = row0_variant
	var width := row0.size()
	if width == 0:
		return
	_ensure_buffers(width, height)
	var hash_value := hash(snapshot)
	if hash_value == _last_hash:
		return
	_last_hash = hash_value
	for y in range(height):
		var row: Array = snapshot[y]
		for x in range(width):
			var material := int(row[x])
			var color: Color = _material_color_for(material)
			_image.set_pixel(x, y, color)
	_texture.update(_image)
	var render_ms: float = float(Time.get_ticks_usec() - start) / 1000.0
	var map_active := view_mode == StringName("map")
	if _topdown_renderer and is_instance_valid(_topdown_renderer):
		_topdown_renderer.update_environment_state(_environment_state)
		_topdown_renderer.render_snapshot(snapshot, comfort, _environment_state, map_active)
	if not map_active:
		_record_stats(render_ms, comfort)
	_update_fallback_state(render_ms, _last_interval)
	_stable_sample_counter = 0

func _ensure_buffers(width: int, height: int) -> void:
	if _image and _image.get_width() == width and _image.get_height() == height:
		return
	_image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	if _texture == null:
		_texture = ImageTexture.create_from_image(_image)
	else:
		_texture.update(_image)
	if _texture_rect:
		_texture_rect.texture = _texture

func _record_stats(render_ms: float, comfort: Dictionary) -> void:
	if _stats_probe == null or not is_instance_valid(_stats_probe):
		_stats_probe = get_node_or_null("/root/StatsProbeSingleton") as StatsProbe
	if _stats_probe == null:
		return
	_stats_probe.record_tick({
		"service": StatsProbe.SERVICE_SANDBOX_RENDER,
		"tick_ms": render_ms,
		"ci": float(comfort.get("ci_smoothed", comfort.get("ci", 0.0)) ),
		"active_cells": float(comfort.get("active_fraction_smoothed", comfort.get("active_fraction", 0.0))) * float(SandboxGrid.get_cell_count()),
		"sandbox_render_view_mode": String(view_mode),
		"sandbox_render_fallback_active": _fallback_active,
		"sandbox_render_era": String(_current_era)
	})

func _update_fallback_state(render_ms: float, interval: float) -> void:
	if interval <= 0.0:
		return
	var trigger_threshold: float = max(fallback_threshold_ms, 0.0)
	var resume_threshold: float = clamp(fallback_resume_ms, 0.0, trigger_threshold)
	var trigger_duration: float = max(fallback_trigger_seconds, 0.0)
	var recover_duration: float = max(fallback_recover_seconds, 0.0)
	if _fallback_active:
		if render_ms <= resume_threshold:
			_fallback_recovery_timer += interval
			if _fallback_recovery_timer >= recover_duration:
				_set_fallback_active(false)
		else:
			_fallback_recovery_timer = 0.0
	else:
		if render_ms > trigger_threshold:
			_fallback_timer += interval
			if _fallback_timer >= trigger_duration:
				_set_fallback_active(true)
		else:
			_fallback_timer = 0.0

func _set_fallback_active(active: bool) -> void:
	if _fallback_active == active:
		return
	_fallback_active = active
	_fallback_timer = 0.0
	_fallback_recovery_timer = 0.0
	_timer = 0.0
	fallback_state_changed.emit(_fallback_active)
