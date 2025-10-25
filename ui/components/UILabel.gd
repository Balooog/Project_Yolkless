extends Label
class_name UILabel

@export var tokens: UITokens
@export var size_token: StringName = &"font_m"
@export var wrap: bool = false
@export var max_lines: int = 1

func _ready() -> void:
	_apply_tokens()

func _apply_tokens() -> void:
	if tokens:
		UIHelpers.apply_label_tokens(self, tokens, size_token, &"banner_text")
	UIHelpers.ensure_overflow_policy(self, wrap, max_lines)
