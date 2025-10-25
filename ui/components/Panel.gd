extends PanelContainer
class_name UIPanel

@export var tokens: UITokens

func _ready() -> void:
	UIHelpers.set_fill_expand(self, true, true)
	_apply_tokens()

func _apply_tokens() -> void:
	if tokens == null:
		return
	add_theme_constant_override("margin_left", int(tokens.spacing_value(&"space_lg")))
	add_theme_constant_override("margin_right", int(tokens.spacing_value(&"space_lg")))
	add_theme_constant_override("margin_top", int(tokens.spacing_value(&"space_md")))
	add_theme_constant_override("margin_bottom", int(tokens.spacing_value(&"space_md")))
