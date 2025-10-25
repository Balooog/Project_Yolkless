extends Object
class_name UIHelpers

static func set_fill_expand(control: Control, horizontal: bool = true, vertical: bool = false) -> void:
	if control == null:
		return
	var h_flag := Control.SIZE_FILL | Control.SIZE_EXPAND if horizontal else Control.SIZE_FILL
	var v_flag := Control.SIZE_FILL | Control.SIZE_EXPAND if vertical else Control.SIZE_FILL
	control.size_flags_horizontal = h_flag
	control.size_flags_vertical = v_flag

static func apply_label_tokens(label: Label, tokens: UITokens, size_token: StringName = &"font_m", colour_token: StringName = &"banner_text") -> void:
	if label == null or tokens == null:
		return
	label.add_theme_color_override("font_color", tokens.colour(colour_token))
	label.add_theme_font_size_override("font_size", tokens.font_size(size_token))

static func ensure_overflow_policy(label: Label, allow_wrap: bool, max_lines: int = 1) -> void:
	if label == null:
		return
	if allow_wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.autowrap = true
		label.max_lines_visible = max_lines
		label.visible_characters = -1
		label.ellipsis = true
	else:
		label.clip_text = true
		label.ellipsis = true

static func apply_safe_area(control: Control, bottom_reserve: float, top_reserve: float = 0.0) -> void:
	if control == null:
		return
	var margin := control as MarginContainer
	if margin:
		margin.add_theme_constant_override("margin_top", int(top_reserve))
		margin.add_theme_constant_override("margin_bottom", int(bottom_reserve))

static func within_breakpoint(width: float, tokens: UITokens, breakpoint: StringName) -> bool:
	if tokens == null:
		return false
	var w := int(width)
	match breakpoint:
		&"small":
			return w <= tokens.breakpoint(&"small_max")
		&"medium":
			return w >= tokens.breakpoint(&"medium_min") and w <= tokens.breakpoint(&"medium_max")
		&"large":
			return w >= tokens.breakpoint(&"large_min")
		_:
			return false
