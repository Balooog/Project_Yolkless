extends Button
class_name UIButton

@export var tokens: UITokens
@export var size_token: StringName = &"font_m"

func _ready() -> void:
	_apply_tokens()

func _apply_tokens() -> void:
	if tokens == null:
		return
	clip_text = true
	add_theme_color_override("font_color", tokens.colour(&"button_primary_text"))
	add_theme_font_size_override("font_size", tokens.font_size(size_token))
