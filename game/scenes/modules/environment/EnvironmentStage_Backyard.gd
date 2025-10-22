extends EnvironmentStageBase

@onready var sky: ColorRect = %Sky
@onready var ground: ColorRect = %Ground
@onready var haze: ColorRect = %PollutionHaze
@onready var coop_body: ColorRect = %CoopBody
@onready var coop_roof: Polygon2D = %CoopRoof
@onready var reputation_icon: Label = %ReputationIcon
@onready var chickens: Array[Node2D] = [%ChickenA, %ChickenB, %ChickenC]

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

func _ready() -> void:
	set_process(true)
	_base_sky = sky.color
	_base_ground = ground.color
	_base_haze = haze.color
	_base_coop = coop_body.color
	_base_roof = coop_roof.color
	for chicken in chickens:
		_base_positions.append(chicken.position)
		var body := chicken.get_node_or_null("Body")
		if body is ColorRect:
			(body as ColorRect).color = Color(1.0, 0.95, 0.75, 1.0)

func apply_state(pollution: float, stress: float, reputation: float) -> void:
	_pollution = pollution
	_stress = stress
	_reputation = reputation
	_update_colors()
	_update_reputation_icon()

func _process(delta: float) -> void:
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
	var ratio: float = clampf(_pollution / 100.0, 0.0, 1.0)
	sky.color = _base_sky.lerp(Color(0.45, 0.48, 0.52, 1.0), ratio)
	ground.color = _base_ground.lerp(Color(0.36, 0.35, 0.33, 1.0), ratio)
	coop_body.color = _base_coop.lerp(Color(0.52, 0.45, 0.38, 1.0), ratio)
	coop_roof.color = _base_roof.lerp(Color(0.38, 0.28, 0.22, 1.0), ratio)
	var haze_alpha: float = lerpf(_base_haze.a, 0.45, clampf((ratio - 0.4) * 1.4, 0.0, 1.0))
	haze.color = Color(_base_haze.r, _base_haze.g, _base_haze.b, haze_alpha)

func _update_reputation_icon() -> void:
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
