extends Node2D
class_name FeedParticles

const MIN_PARTICLES := 24
const MAX_PARTICLES := 180

@onready var emitter: GPUParticles2D = %Emitter

var _high_contrast: bool = false
var _anchor: Vector2 = Vector2.ZERO

func _ready() -> void:
	_configure_particles()

func apply(feed_fraction: float, pps: float, is_feeding: bool) -> void:
	var fraction: float = clamp(feed_fraction, 0.0, 1.0)
	var base_pps: float = max(pps, 0.0)
	var pps_factor: float = clamp(sqrt(base_pps), 0.0, 16.0)
	var strength: float = 0.0
	if is_feeding:
		var feed_boost: float = lerp(0.35, 1.0, fraction)
		var pps_boost: float = max(0.25, pps_factor * 0.12)
		strength = clamp(feed_boost * pps_boost, 0.0, 1.2)
	else:
		strength = clamp(fraction * 0.25, 0.0, 0.4)
	var intensity: float = clamp(strength, 0.0, 1.0)
	var particle_target: int = int(round(lerp(float(MIN_PARTICLES), float(MAX_PARTICLES), intensity)))
	if is_feeding or particle_target > MIN_PARTICLES / 2:
		emitter.emitting = true
		emitter.amount = max(MIN_PARTICLES, particle_target)
		emitter.speed_scale = 0.9 + intensity * 0.8
	else:
		emitter.emitting = false
		emitter.amount = MIN_PARTICLES
		emitter.speed_scale = 0.8

func set_anchor(position: Vector2) -> void:
	if position == Vector2.ZERO and _anchor != Vector2.ZERO:
		return
	_anchor = position
	global_position = position

func set_high_contrast(enabled: bool) -> void:
	if _high_contrast == enabled:
		return
	_high_contrast = enabled
	_update_contrast()

func _configure_particles() -> void:
	if emitter.process_material == null:
		var material: ParticleProcessMaterial = ParticleProcessMaterial.new()
		material.gravity = Vector3.ZERO
		material.initial_velocity_min = 18.0
		material.initial_velocity_max = 30.0
		material.direction = Vector3(0, -1, 0)
		material.spread = 25.0
		material.scale_min = 0.5
		material.scale_max = 0.85
		material.color_ramp = _build_color_ramp_texture()
		emitter.process_material = material
	if emitter.texture == null:
		emitter.texture = _build_particle_texture()
	emitter.emitting = false
	emitter.amount = MIN_PARTICLES
	emitter.speed_scale = 0.8
	_update_contrast()

func _build_color_ramp_texture() -> Texture2D:
	var ramp: GradientTexture1D = GradientTexture1D.new()
	var gradient: Gradient = Gradient.new()
	gradient.add_point(0.0, Color(1.0, 0.95, 0.65, 0.0))
	gradient.add_point(0.2, Color(1.0, 0.9, 0.4, 0.6))
	gradient.add_point(1.0, Color(0.95, 0.6, 0.1, 0.0))
	ramp.gradient = gradient
	return ramp

func _build_particle_texture() -> Texture2D:
	var gradient: Gradient = Gradient.new()
	gradient.add_point(0.0, Color(1.0, 0.9, 0.3, 0.0))
	gradient.add_point(0.4, Color(1.0, 0.85, 0.25, 0.7))
	gradient.add_point(1.0, Color(1.0, 0.65, 0.1, 0.0))
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 64
	return texture

func _update_contrast() -> void:
	var material: ParticleProcessMaterial = emitter.process_material as ParticleProcessMaterial
	if material:
		var color: Color = Color(1.0, 0.95, 0.55, 0.95) if _high_contrast else Color(1.0, 0.9, 0.45, 0.7)
		material.color = color
