extends Control
class_name TopDownRenderer

const StatsProbe := preload("res://src/services/StatsProbe.gd")
const SandboxGrid := preload("res://src/sandbox/SandboxGrid.gd")

@export var calm_color: Color = Color(0.286, 0.824, 0.612, 1.0)
@export var stress_color: Color = Color(0.933, 0.345, 0.322, 1.0)
@export var warm_overlay: Color = Color(0.992, 0.741, 0.373, 1.0)
@export var cool_overlay: Color = Color(0.373, 0.643, 0.992, 1.0)
@export var grid_glow_strength: float = 0.25
@export var map_alpha: float = 0.95
@export var max_pps_reference: float = 150.0

var _image: Image
var _texture: ImageTexture
var _stats_probe: StatsProbe
var _active: bool = false
var _environment_state: Dictionary = {}
var _comfort_cache: Dictionary = {}
var _last_hash: int = 0
var _debug_dump_enabled := false
var _debug_dumped := false

const MATERIAL_COLOR_OVERRIDES := {
	SandboxGrid.MATERIAL_FIRE: Color(0.988, 0.549, 0.219, 1.0),
	SandboxGrid.MATERIAL_WATER: Color(0.282, 0.541, 0.925, 1.0),
	SandboxGrid.MATERIAL_PLANT: Color(0.310, 0.741, 0.490, 1.0),
	SandboxGrid.MATERIAL_OIL: Color(0.231, 0.184, 0.192, 1.0),
	SandboxGrid.MATERIAL_STONE: Color(0.560, 0.565, 0.585, 1.0),
	SandboxGrid.MATERIAL_SAND: Color(0.901, 0.792, 0.515, 1.0),
	SandboxGrid.MATERIAL_STEAM: Color(0.882, 0.925, 0.980, 0.9)
}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stats_probe = get_node_or_null("/root/StatsProbeSingleton") as StatsProbe
	visible = false
	_debug_dump_enabled = OS.has_environment("YOLKLESS_DEBUG_MAP") and OS.get_environment("YOLKLESS_DEBUG_MAP") == "1"
	set_process(true)
	_match_parent_bounds()

func set_active(active: bool) -> void:
	_active = active
	visible = active
	if not active:
		_debug_dumped = false

func update_environment_state(state: Dictionary) -> void:
	_environment_state = state.duplicate(true)

func render_snapshot(snapshot: Array, comfort: Dictionary, environment_state: Dictionary, record_stats: bool) -> float:
	if snapshot.is_empty():
		return 0.0
	_environment_state = environment_state.duplicate(true)
	_comfort_cache = comfort.duplicate(true)
	var hash_value := hash(snapshot)
	if hash_value == _last_hash and not record_stats:
		return 0.0
	_last_hash = hash_value
	var start := Time.get_ticks_usec()
	_ensure_buffers(snapshot)
	var height := snapshot.size()
	var width := (snapshot[0] as Array).size()
	var params: Dictionary = _prepare_color_params()
	for y in range(height):
		var row: Array = snapshot[y]
		for x in range(width):
			var material := int(row[x])
			var color := _color_for_cell(material, params, x, y)
			_image.set_pixel(x, y, color)
	_texture.update(_image)
	queue_redraw()
	var render_ms: float = float(Time.get_ticks_usec() - start) / 1000.0
	if _debug_dump_enabled and record_stats and not _debug_dumped:
		var dump_path := "user://map_debug.png"
		var err := _image.save_png(dump_path)
		if err == OK:
			print_debug("[TopDownRenderer] map snapshot saved to %s (%dx%d)" % [dump_path, width, height])
		else:
			push_warning("TopDownRenderer: failed to save %s (err=%d)" % [dump_path, err])
		_debug_dumped = true
	if record_stats:
		_record_stats(render_ms, comfort)
	return render_ms

func _ensure_buffers(snapshot: Array) -> void:
	var height := snapshot.size()
	if height == 0:
		return
	var width := (snapshot[0] as Array).size()
	if _image and _image.get_width() == width and _image.get_height() == height:
		return
	_image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	_texture = ImageTexture.create_from_image(_image)

func _prepare_color_params() -> Dictionary:
	var ci_value: float = clamp(float(_comfort_cache.get("ci_smoothed", _comfort_cache.get("ci", 0.0))), 0.0, 1.0)
	var stress_ratio: float = clamp(1.0 - ci_value, 0.0, 1.0)
	var pps_value: float = max(float(_comfort_cache.get("pps", 0.0)), 0.0)
	var pps_norm: float = clamp(pps_value / max(max_pps_reference, 1.0), 0.0, 1.0)
	var temp_c: float = float(_environment_state.get("temperature_c", 20.0))
	var temp_ratio: float = clamp((temp_c - 20.0) / 20.0, -1.0, 1.0)
	var pollution: float = clamp(float(_environment_state.get("pollution", 0.0)) / 100.0, 0.0, 1.0)
	var time_phase: float = float(Time.get_ticks_msec()) * 0.001
	return {
		"stress_ratio": stress_ratio,
		"pps_norm": pps_norm,
		"temp_ratio": temp_ratio,
		"pollution": pollution,
		"time_phase": time_phase
	}

func _color_for_cell(material: int, params: Dictionary, x: int, y: int) -> Color:
	var stress_ratio: float = float(params.get("stress_ratio", 0.5))
	var base_color: Color = calm_color.lerp(stress_color, stress_ratio)
	var highlight_variant: Variant = MATERIAL_COLOR_OVERRIDES.get(material, base_color)
	var highlight: Color = highlight_variant if highlight_variant is Color else Color(highlight_variant)
	var mix_strength: float = 0.0
	if material != SandboxGrid.MATERIAL_AIR:
		mix_strength = 0.35
	base_color = base_color.lerp(highlight, mix_strength)
	var temp_ratio: float = float(params.get("temp_ratio", 0.0))
	if temp_ratio > 0.01:
		base_color = base_color.lerp(warm_overlay, clamp(temp_ratio, 0.0, 1.0) * 0.35)
	elif temp_ratio < -0.01:
		base_color = base_color.lerp(cool_overlay, clamp(abs(temp_ratio), 0.0, 1.0) * 0.35)
	var pps_norm: float = float(params.get("pps_norm", 0.0))
	var grid_speed: float = float(params.get("time_phase", 0.0))
	var grid_wave: float = sin(float(x) * 0.18 + grid_speed) * cos(float(y) * 0.16 + grid_speed * 0.6)
	var grid_intensity: float = abs(grid_wave) * (0.2 + pps_norm * 0.6)
	base_color = base_color.lerp(Color.WHITE, grid_intensity * grid_glow_strength)
	var halo_wave: float = sin((float(x) + float(y)) * 0.05 + grid_speed * 0.3)
	base_color = base_color.lightened(clamp(halo_wave, 0.0, 1.0) * pps_norm * 0.35)
	var pollution_ratio: float = float(params.get("pollution", 0.0))
	if pollution_ratio > 0.0:
		var noise: float = sin(float(x) * 0.33 + grid_speed * 1.3) * cos(float(y) * 0.27 + grid_speed * 0.8)
		var pollution_dark: float = clamp(pollution_ratio * 0.4 + abs(noise) * 0.2, 0.0, 0.6)
		base_color = base_color.darkened(pollution_dark)
	return Color(base_color.r, base_color.g, base_color.b, map_alpha)

func _record_stats(render_ms: float, comfort: Dictionary) -> void:
	if _stats_probe == null or not is_instance_valid(_stats_probe):
		_stats_probe = get_node_or_null("/root/StatsProbeSingleton") as StatsProbe
	if _stats_probe == null:
		return
	_stats_probe.record_tick({
		"service": StatsProbe.SERVICE_SANDBOX_RENDER,
		"tick_ms": render_ms,
		"ci": float(comfort.get("ci_smoothed", comfort.get("ci", 0.0))),
		"active_cells": float(comfort.get("active_fraction_smoothed", comfort.get("active_fraction", 0.0))) * float(SandboxGrid.get_cell_count()),
		"sandbox_render_view_mode": "map",
		"sandbox_render_fallback_active": false
	})

func _process(_delta: float) -> void:
	_match_parent_bounds()

func _match_parent_bounds() -> void:
	if not is_inside_tree():
		return
	var target := _target_bounds()
	if target == Vector2.ZERO:
		return
	if not size.is_equal_approx(target):
		size = target
		set_deferred("size", target)
	queue_redraw()
	custom_minimum_size = target

func _target_bounds() -> Vector2:
	var parent_control := get_parent()
	if parent_control is Control:
		return (parent_control as Control).get_size()
	if get_viewport():
		return get_viewport_rect().size
	return get_size()

func _draw() -> void:
	if _texture == null:
		return
	draw_texture_rect(_texture, Rect2(Vector2.ZERO, size), false)
