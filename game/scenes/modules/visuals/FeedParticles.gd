extends Node2D
class_name FeedParticles

const MIN_PARTICLES := 24
const MAX_PARTICLES := 180
const BASE_EMISSION_SIZE := Vector2(96, 64)

@onready var vp: Viewport = get_viewport()
@onready var ps: GPUParticles2D = %Emitter

var _high_contrast: bool = false
var _anchor: Vector2 = Vector2.ZERO
var _last_intensity: float = 0.0
var _last_is_feeding: bool = false
var _anchor_size: Vector2 = BASE_EMISSION_SIZE

func _ready() -> void:
	_configure_particles()
	_resize_to_view()
	if vp:
		var resize_callable := Callable(self, "_resize_to_view")
		if not vp.size_changed.is_connected(resize_callable):
			vp.size_changed.connect(resize_callable)

func _resize_to_view() -> void:
	if not vp:
		return
	_update_anchor_position()
	_update_emission_shape(_last_intensity)

func apply(feed_fraction: float, pps: float, is_feeding: bool) -> void:
	_configure_particles()
	_update_anchor_position()
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
	_last_intensity = intensity
	var should_emit := is_feeding and intensity > 0.02
	if should_emit:
		ps.emitting = true
		ps.amount = max(MIN_PARTICLES, particle_target)
		ps.speed_scale = 1.1 + intensity * 0.9
		_update_emission_shape(intensity)
		_update_emission_velocity(intensity)
		if not _last_is_feeding:
			ps.restart()
	else:
		if ps.emitting:
			ps.emitting = false
		ps.amount = MIN_PARTICLES
		ps.speed_scale = 0.6
	_update_emission_shape(intensity if should_emit else 0.0)
	_last_is_feeding = is_feeding

func set_anchor(position: Vector2, size: Vector2 = Vector2.ZERO) -> void:
	_anchor = position
	if size.x > 0.0 and size.y > 0.0:
		_anchor_size = size
	_update_anchor_position()

func set_high_contrast(enabled: bool) -> void:
	if _high_contrast == enabled:
		return
	_high_contrast = enabled
	_update_contrast()

func _configure_particles() -> void:
	if ps.process_material == null:
		var material: ParticleProcessMaterial = ParticleProcessMaterial.new()
		material.gravity = Vector3.ZERO
		material.initial_velocity_min = 90.0
		material.initial_velocity_max = 140.0
		material.direction = Vector3(0, -1, 0)
		material.spread = 8.0
		material.scale_min = 0.5
		material.scale_max = 0.85
		material.color_ramp = _build_color_ramp_texture()
		material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		material.emission_box_extents = Vector3(BASE_EMISSION_SIZE.x * 0.5, BASE_EMISSION_SIZE.y * 0.5, 0.0)
		ps.process_material = material
	if ps.texture == null:
		ps.texture = ArtRegistry.get_texture("grain_particle")
	ps.emitting = false
	ps.amount = MIN_PARTICLES
	ps.speed_scale = 0.8
	ps.local_coords = true
	_update_contrast()

func _update_anchor_position() -> void:
	if not is_inside_tree():
		return
	if _anchor == Vector2.ZERO:
		if vp:
			var rect := vp.get_visible_rect()
			global_position = rect.size * 0.5
		return
	global_position = _anchor

func _update_emission_shape(intensity: float) -> void:
	var material := ps.process_material as ParticleProcessMaterial
	if material == null:
		return
	var base_width: float = max(_anchor_size.x * 0.6, BASE_EMISSION_SIZE.x)
	var base_height: float = max(_anchor_size.y * 0.45, BASE_EMISSION_SIZE.y * 0.6)
	var width: float = float(lerp(base_width, base_width * 1.4, intensity))
	var height: float = float(lerp(base_height, base_height * 1.6, intensity))
	material.emission_box_extents = Vector3(width * 0.5, height * 0.5, 0.0)

func _update_emission_velocity(intensity: float) -> void:
	var material := ps.process_material as ParticleProcessMaterial
	if material == null:
		return
	material.initial_velocity_min = float(lerp(110.0, 180.0, intensity))
	material.initial_velocity_max = float(lerp(180.0, 260.0, intensity))
	material.spread = float(lerp(6.0, 18.0, intensity))

func _build_color_ramp_texture() -> Texture2D:
	var ramp: GradientTexture1D = GradientTexture1D.new()
	var gradient: Gradient = Gradient.new()
	gradient.add_point(0.0, ProceduralFactory.color_with_alpha(ProceduralFactory.COLOR_ACCENT, 0.0))
	gradient.add_point(0.2, ProceduralFactory.color_with_alpha(ProceduralFactory.COLOR_ACCENT, 0.45))
	gradient.add_point(1.0, ProceduralFactory.color_with_alpha(ProceduralFactory.COLOR_ACCENT, 0.0))
	ramp.gradient = gradient
	return ramp

func _update_contrast() -> void:
	var material: ParticleProcessMaterial = ps.process_material as ParticleProcessMaterial
	if material:
		var color: Color = Color(1.0, 0.95, 0.55, 0.95) if _high_contrast else Color(1.0, 0.9, 0.45, 0.7)
		material.color = color
