extends EnvironmentStageBase

const CANVAS_SIZE := Vector2(640, 360)

var sky: ColorRect
var ground: ColorRect
var haze: ColorRect
var coop_body: ColorRect
var coop_roof: Polygon2D
var reputation_icon: Label
var chickens: Array[Node2D] = []

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
	sky.color = _base_sky.lerp(Color(0.45, 0.48, 0.52, 1.0), ratio)
	ground.color = _base_ground.lerp(Color(0.36, 0.35, 0.33, 1.0), ratio)
	coop_body.color = _base_coop.lerp(Color(0.52, 0.45, 0.38, 1.0), ratio)
	coop_roof.color = _base_roof.lerp(Color(0.38, 0.28, 0.22, 1.0), ratio)
	var haze_alpha: float = lerpf(_base_haze.a, 0.45, clampf((ratio - 0.4) * 1.4, 0.0, 1.0))
	haze.color = Color(_base_haze.r, _base_haze.g, _base_haze.b, haze_alpha)

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
		if chicken is Node2D:
			chickens.append(chicken as Node2D)
	_cache_base_state()

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
			(body as ColorRect).color = Color(1.0, 0.95, 0.75, 1.0)

func get_canvas_size() -> Vector2:
	return _canvas_size

func _ensure_stage_nodes() -> void:
	if _env_root == null or not is_instance_valid(_env_root) or sky == null or not is_instance_valid(sky):
		_build_environment()
