extends EnvironmentStageBase

const CANVAS_SIZE := Vector2(640, 360)

@export var sky_top_color: Color = Color(0.74, 0.9, 1.0, 1.0)
@export var sky_bottom_color: Color = Color(0.94, 0.98, 1.0, 1.0)
@export var haze_color: Color = Color(0.3, 0.33, 0.35, 0.05)
@export var ground_color: Color = Color(0.58, 0.78, 0.45, 1.0)
@export var horizon_color: Color = Color(0.46, 0.68, 0.40, 1.0)
@export var stripe_color: Color = Color(0.46, 0.68, 0.4, 1.0)
@export var fence_color: Color = Color(0.9, 0.83, 0.65, 1.0)
@export var structure_body_color: Color = Color(0.78, 0.58, 0.4, 1.0)
@export var structure_roof_color: Color = Color(0.78, 0.32, 0.28, 1.0)
@export var structure_detail_color: Color = Color(0.52, 0.45, 0.38, 1.0)
@export var chicken_body_color: Color = Color(1.0, 0.95, 0.75, 1.0)
@export var chicken_wing_color: Color = Color(0.95, 0.82, 0.6, 1.0)
@export var chicken_head_color: Color = Color(0.98, 0.88, 0.65, 1.0)
@export var chicken_beak_color: Color = Color(0.95, 0.6, 0.2, 1.0)
@export var tree_canopy_color: Color = Color(0.48, 0.72, 0.38, 1.0)
@export var tree_trunk_color: Color = Color(0.4, 0.25, 0.2, 1.0)
@export var spawn_chickens: bool = true
@export var spawn_tree_row: bool = true
@export var prop_configs: Array = []

var sky: ColorRect
var ground: ColorRect
var haze: ColorRect
var coop_body: ColorRect
var coop_roof: Polygon2D
var reputation_icon: Label
var chickens: Array[Node2D] = []
var _custom_props: Array[Node] = []
var _custom_props_state: Array[Dictionary] = []

var _base_sky: Color
var _base_ground: Color
var _base_haze: Color
var _base_coop: Color
var _base_roof: Color
var _base_positions: Array[Vector2] = []
var _pollution: float = 0.0
var _stress: float = 0.0
var _reputation: float = 0.0
var _time: float = 0.0
var _env_root: Node2D
var _canvas_size: Vector2 = CANVAS_SIZE

func _ready() -> void:
	_build_environment()
	set_process(true)

func apply_state(pollution: float, stress: float, reputation: float) -> void:
	_ensure_stage_nodes()
	_pollution = pollution
	_stress = stress
	_reputation = reputation
	_update_colors()
	_update_reputation_icon()

func _process(delta: float) -> void:
	_ensure_stage_nodes()
	_time += delta * _chicken_speed()
	if spawn_chickens:
		var stress_ratio: float = clampf(_stress / 100.0, 0.0, 1.0)
		var amplitude: float = lerpf(6.0, 1.5, stress_ratio)
		for i in range(chickens.size()):
			var chicken := chickens[i]
			if chicken:
				var base_pos := _base_positions[i]
				var phase := _time + float(i)
				var offset := Vector2(sin(phase) * amplitude, sin(phase * 1.7) * amplitude * 0.25)
				chicken.position = base_pos + offset

func _update_colors() -> void:
	if sky == null or ground == null or coop_body == null or coop_roof == null or haze == null:
		return
	var ratio: float = clampf(_pollution / 100.0, 0.0, 1.0)
	var stress_ratio: float = clampf(_stress / 100.0, 0.0, 1.0)
	sky.color = _base_sky.lerp(_base_sky.darkened(0.35), ratio)
	ground.color = _base_ground.lerp(_base_ground.darkened(0.28), ratio)
	coop_body.color = _base_coop.lerp(_base_coop.darkened(0.32), ratio)
	coop_roof.color = _base_roof.lerp(_base_roof.darkened(0.34), ratio)
	var haze_alpha: float = lerpf(_base_haze.a, min(0.65, _base_haze.a + 0.35), ratio)
	haze.color = Color(_base_haze.r, _base_haze.g, _base_haze.b, haze_alpha)
	if spawn_chickens:
		for i in range(chickens.size()):
			var base_pos := _base_positions[i]
			var chicken := chickens[i]
			if chicken:
				var amplitude: float = lerpf(6.0, 1.5, stress_ratio)
				var phase := _time + float(i)
				var offset := Vector2(sin(phase) * amplitude, sin(phase * 1.7) * amplitude * 0.25)
				chicken.position = base_pos + offset
	_update_tree_colors(ratio)
	_update_custom_props_colors(ratio)

func _update_reputation_icon() -> void:
	if reputation_icon == null:
		return
	var icon := ":)"
	var color := Color(0.1, 0.6, 0.2, 1.0)
	if _reputation < 30.0:
		icon = ":("
		color = Color(0.7, 0.25, 0.25, 1.0)
	elif _reputation < 60.0:
		icon = ":|"
		color = Color(0.8, 0.65, 0.2, 1.0)
	reputation_icon.text = icon
	reputation_icon.add_theme_color_override("font_color", color)
	reputation_icon.tooltip_text = "Reputation %.0f" % _reputation

func _chicken_speed() -> float:
	var stress_ratio: float = clampf(_stress / 100.0, 0.0, 1.0)
	return lerpf(1.3, 0.35, stress_ratio)

func _build_environment() -> void:
	if _env_root:
		_env_root.queue_free()
	var size := _canvas_size
	_env_root = ProceduralFactory.make_env_bg(size)
	_env_root.position = Vector2(0.0, -size.y * 0.12)
	add_child(_env_root)
	sky = _env_root.get_node_or_null("Sky") as ColorRect
	ground = _env_root.get_node_or_null("Ground") as ColorRect
	haze = _env_root.get_node_or_null("PollutionHaze") as ColorRect
	var coop := _env_root.get_node_or_null("Coop")
	if coop:
		coop_body = coop.get_node_or_null("CoopBody") as ColorRect
		coop_roof = coop.get_node_or_null("CoopRoof") as Polygon2D
	reputation_icon = _env_root.get_node_or_null("ReputationIcon") as Label
	chickens.clear()
	for name in ["ChickenA", "ChickenB", "ChickenC"]:
		var chicken := _env_root.get_node_or_null(name)
		if chicken is Node2D and spawn_chickens:
			var chicken_node := chicken as Node2D
			chickens.append(chicken_node)
		else:
			if chicken and chicken.get_parent():
				chicken.queue_free()
	if not spawn_chickens:
		chickens.clear()
	if not spawn_tree_row:
		var trees_node := _env_root.get_node_or_null("Trees")
		if trees_node and trees_node.get_parent():
			trees_node.queue_free()
	_apply_palette()
	_clear_custom_props()
	_spawn_custom_props()
	_cache_base_state()

func _apply_palette() -> void:
	if sky:
		sky.color = sky_top_color
	if _env_root:
		var stripe := _env_root.get_node_or_null("GroundStripe") as ColorRect
		if stripe:
			stripe.color = stripe_color
		var fence := _env_root.get_node_or_null("Fence") as ColorRect
		if fence:
			fence.color = fence_color
	var sky_bottom := _env_root.get_node_or_null("SkyBottom") as ColorRect
	if sky_bottom:
		sky_bottom.color = sky_bottom_color
	if haze:
		haze.color = haze_color
	if ground:
		ground.color = ground_color
	var ground_horizon := _env_root.get_node_or_null("GroundHorizon") as ColorRect
	if ground_horizon:
		ground_horizon.color = horizon_color
	if coop_body:
		coop_body.color = structure_body_color
		var door := coop_body.get_parent().get_node_or_null("CoopDoor")
		if door is ColorRect:
			(door as ColorRect).color = structure_detail_color
	if coop_roof:
		coop_roof.color = structure_roof_color
	if reputation_icon:
		reputation_icon.add_theme_color_override("font_color", structure_detail_color)
	_tint_tree_row(1.0)
	if spawn_chickens:
		for chicken in chickens:
			var body := chicken.get_node_or_null("Body")
			if body is ColorRect:
				(body as ColorRect).color = chicken_body_color
			var wing := body.get_node_or_null("Wing") if body else null
			if wing is ColorRect:
				(wing as ColorRect).color = chicken_wing_color
			var head := chicken.get_node_or_null("Head")
			if head is ColorRect:
				(head as ColorRect).color = chicken_head_color
			var beak := chicken.get_node_or_null("Beak")
			if beak is ColorRect:
				(beak as ColorRect).color = chicken_beak_color

func _tint_tree_row(intensity: float) -> void:
	if not spawn_tree_row:
		return
	var trees := _env_root.get_node_or_null("Trees")
	if trees == null:
		return
	for child in trees.get_children():
		if not (child is Node2D):
			continue
		var branch_index := 0
		for branch in child.get_children():
			if branch is Polygon2D:
				var polygon := branch as Polygon2D
				if branch_index == 0:
					polygon.color = tree_trunk_color
				else:
					polygon.color = tree_canopy_color
				branch_index += 1

func _update_tree_colors(ratio: float) -> void:
	if not spawn_tree_row:
		return
	var trees := _env_root.get_node_or_null("Trees")
	if trees == null:
		return
	var canopy_dark := tree_canopy_color.darkened(0.3)
	var trunk_dark := tree_trunk_color.darkened(0.35)
	for child in trees.get_children():
		if not (child is Node2D):
			continue
		var branch_index := 0
		for branch in child.get_children():
			if branch is Polygon2D:
				var polygon := branch as Polygon2D
				if branch_index == 0:
					polygon.color = tree_trunk_color.lerp(trunk_dark, ratio)
				else:
					polygon.color = tree_canopy_color.lerp(canopy_dark, ratio)
				branch_index += 1

func _update_custom_props_colors(ratio: float) -> void:
	if _custom_props_state.is_empty():
		return
	for entry in _custom_props_state:
		var node_variant := entry.get("node")
		var base_color_variant := entry.get("base_color", Color(0.6, 0.6, 0.6, 1.0))
		var base_color: Color = base_color_variant if base_color_variant is Color else Color(base_color_variant)
		var target_color := base_color.lerp(base_color.darkened(0.35), ratio)
		if node_variant is Polygon2D:
			(node_variant as Polygon2D).color = target_color

func _clear_custom_props() -> void:
	for node in _custom_props:
		if node and node.get_parent():
			node.queue_free()
	_custom_props.clear()
	_custom_props_state.clear()

func _spawn_custom_props() -> void:
	if prop_configs.is_empty():
		return
	for config_variant in prop_configs:
		if not (config_variant is Dictionary):
			continue
		var config: Dictionary = config_variant
		var type := String(config.get("type", "box")).to_lower()
		var position: Vector2 = config.get("position", Vector2.ZERO)
		var size: Vector2 = config.get("size", Vector2(40, 40))
		var color_variant := config.get("color", Color(0.6, 0.6, 0.6, 1.0))
		var color: Color = color_variant if color_variant is Color else Color(color_variant)
		var rotation_deg: float = float(config.get("rotation_deg", 0.0))
		var z_index: int = int(config.get("z_index", 5))
		var points_variant := config.get("points", [])
		var prop_node := Node2D.new()
		prop_node.position = position
		prop_node.rotation = deg_to_rad(rotation_deg)
		prop_node.z_index = z_index
		prop_node.z_as_relative = false
		var shape: CanvasItem = null
		match type:
			"box":
				shape = _create_rect_polygon(size, color)
			"polygon":
				shape = _create_polygon(points_variant, color, size)
			"bar":
				shape = _create_rect_polygon(Vector2(size.x, size.y * 0.2), color)
				shape.position = Vector2(-size.x * 0.5, -size.y)
			"triangle":
				shape = _create_triangle(size, color)
			_: 
				shape = _create_rect_polygon(size, color)
		if shape == null:
			continue
		prop_node.add_child(shape)
		if shape is CanvasItem:
			(shape as CanvasItem).z_index = z_index
		_env_root.add_child(prop_node)
		_custom_props.append(prop_node)
		_custom_props_state.append({"node": shape, "base_color": color})

func _create_rect_polygon(size: Vector2, color: Color) -> Polygon2D:
	var poly := Polygon2D.new()
	var half := size * 0.5
	poly.polygon = PackedVector2Array([
		Vector2(-half.x, -size.y),
		Vector2(half.x, -size.y),
		Vector2(half.x, 0.0),
		Vector2(-half.x, 0.0)
	])
	poly.color = color
	return poly

func _create_polygon(points_variant: Variant, color: Color, fallback_size: Vector2) -> Polygon2D:
	var poly := Polygon2D.new()
	var points_array := PackedVector2Array()
	if points_variant is Array:
		for pt in points_variant:
			if pt is Vector2:
				points_array.append(pt)
		if points_array.is_empty():
			points_array = PackedVector2Array([
				Vector2(-fallback_size.x * 0.5, -fallback_size.y),
				Vector2(fallback_size.x * 0.5, -fallback_size.y),
				Vector2(fallback_size.x * 0.5, 0.0),
				Vector2(-fallback_size.x * 0.5, 0.0)
			])
	else:
		points_array = PackedVector2Array([
			Vector2(-fallback_size.x * 0.5, -fallback_size.y),
			Vector2(fallback_size.x * 0.5, -fallback_size.y),
			Vector2(fallback_size.x * 0.5, 0.0),
			Vector2(-fallback_size.x * 0.5, 0.0)
		])
	poly.polygon = points_array
	poly.color = color
	return poly

func _create_triangle(size: Vector2, color: Color) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(-size.x * 0.5, 0.0),
		Vector2(size.x * 0.5, 0.0),
		Vector2(0.0, -size.y)
	])
	poly.color = color
	return poly

func _cache_base_state() -> void:
	_base_positions.clear()
	if sky:
		_base_sky = sky.color
	if ground:
		_base_ground = ground.color
	if haze:
		_base_haze = haze.color
	if coop_body:
		_base_coop = coop_body.color
	if coop_roof:
		_base_roof = coop_roof.color
	for chicken in chickens:
		_base_positions.append(chicken.position)
		var body := chicken.get_node_or_null("Body")
		if body is ColorRect:
			(body as ColorRect).color = chicken_body_color
		var wing := body.get_node_or_null("Wing") if body else null
		if wing is ColorRect:
			(wing as ColorRect).color = chicken_wing_color
		var head := chicken.get_node_or_null("Head")
		if head is ColorRect:
			(head as ColorRect).color = chicken_head_color
		var beak := chicken.get_node_or_null("Beak")
		if beak is ColorRect:
			(beak as ColorRect).color = chicken_beak_color

func get_canvas_size() -> Vector2:
	return _canvas_size

func _ensure_stage_nodes() -> void:
	if _env_root == null or not is_instance_valid(_env_root) or sky == null or not is_instance_valid(sky):
		_build_environment()
		return
	if _custom_props.is_empty() and not prop_configs.is_empty():
		_spawn_custom_props()
