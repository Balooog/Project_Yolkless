extends Control
class_name UITooltip

@export var tokens: UITokens
@onready var _label: Label = %TooltipLabel

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_tokens()

func set_text(text: String) -> void:
	if _label:
		_label.text = text
		UIHelpers.ensure_overflow_policy(_label, true, 3)

func _apply_tokens() -> void:
	if tokens == null:
		return
	if _label:
		UIHelpers.apply_label_tokens(_label, tokens, &"font_s", &"banner_text")
