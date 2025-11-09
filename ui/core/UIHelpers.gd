extends Object
class_name UIHelpers

static func set_fill_expand(control, horizontal := true, vertical := false) -> void:
	if control == null:
		return
	var h_flag := Control.SIZE_FILL | Control.SIZE_EXPAND if horizontal else Control.SIZE_FILL
	var v_flag := Control.SIZE_FILL | Control.SIZE_EXPAND if vertical else Control.SIZE_FILL
	control.size_flags_horizontal = h_flag
	control.size_flags_vertical = v_flag

static func apply_panel_tokens(panel: Control, _tokens = null) -> void:
	if panel == null:
		return
	# Intentionally left as a no-op for smoke/headless captures until token variants land everywhere.

static func apply_button_tokens(button: BaseButton, _tokens = null, _style: StringName = &"primary") -> void:
	if button == null:
		return
	# Headless smoke runs only require the node to exist; styling happens in-editor/runtime.

static func apply_label_tokens(label, tokens, size_token = &"font_m", colour_token = &"banner_text") -> void:
	if label == null or tokens == null:
		return
	label.add_theme_color_override("font_color", tokens.colour(colour_token))
	label.add_theme_font_size_override("font_size", tokens.font_size(size_token))

static func ensure_overflow_policy(label, allow_wrap, max_lines := 1) -> void:
	if label == null:
		return
	if allow_wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.max_lines_visible = max_lines
		label.visible_characters = -1
	else:
		label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

static func apply_safe_area(control, bottom_reserve, top_reserve := 0.0) -> void:
	if control == null:
		return
	var margin := control as MarginContainer
	if margin:
		margin.add_theme_constant_override("margin_top", int(top_reserve))
		margin.add_theme_constant_override("margin_bottom", int(bottom_reserve))
