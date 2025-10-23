extends ProgressBar
class_name HudStorageBar

@export var pulse_label_path: NodePath
@export var pulse_scale: Vector2 = Vector2(1.08, 1.12)

var pulse_enabled: bool = true

var _pulse_label: Label
var _scale_tween: Tween
var _label_tween: Tween

func _ready() -> void:
	_resolve_pulse_label()
	_set_pivot_to_center()
	if _pulse_label:
		_pulse_label.visible = false

func play_dump_pulse(duration_ms: int = 300, message: String = "") -> void:
	if not pulse_enabled:
		return
	var duration: float = max(duration_ms, 60) / 1000.0
	_set_pivot_to_center()
	_reset_scale()
	_stop_tween(_scale_tween)
	_scale_tween = null
	_scale_tween = create_tween()
	_scale_tween.tween_property(self, "scale", pulse_scale, duration * 0.45)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_scale_tween.tween_property(self, "scale", Vector2.ONE, duration * 0.55)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_scale_tween.finished.connect(func() -> void:
		_scale_tween = null
	)
	if _pulse_label:
		if message != "":
			_pulse_label.text = message
		_pulse_label.visible = true
		_pulse_label.modulate = Color(1, 1, 1, 0)
		_stop_tween(_label_tween)
		_label_tween = null
		_label_tween = create_tween()
		_label_tween.tween_property(_pulse_label, "modulate", Color(1, 1, 1, 1), duration * 0.25)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_label_tween.tween_property(_pulse_label, "modulate", Color(1, 1, 1, 0), duration * 0.4)\
			.set_delay(duration * 0.35)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_label_tween.finished.connect(func() -> void:
			if _pulse_label:
				_pulse_label.visible = false
				_pulse_label.modulate = Color(1, 1, 1, 0)
			_label_tween = null
		)

func set_pulse_enabled(enabled: bool) -> void:
	pulse_enabled = enabled
	if not pulse_enabled:
		_stop_tween(_scale_tween)
		_scale_tween = null
		_stop_tween(_label_tween)
		_label_tween = null
		_reset_scale()
		if _pulse_label:
			_pulse_label.visible = false
			_pulse_label.modulate = Color(1, 1, 1, 0)

func pulse_message_visible() -> bool:
	return _pulse_label != null and _pulse_label.visible

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_set_pivot_to_center()

func _resolve_pulse_label() -> void:
	if pulse_label_path == NodePath():
		return
	var node := get_node_or_null(pulse_label_path)
	if node is Label:
		_pulse_label = node as Label

func _set_pivot_to_center() -> void:
	pivot_offset = size * 0.5

func _reset_scale() -> void:
	scale = Vector2.ONE

func _stop_tween(tween: Tween) -> void:
	if tween != null and is_instance_valid(tween):
		tween.kill()
