extends Window
class_name SettingsPanel

signal text_scale_selected(scale: float)
signal diagnostics_requested
signal high_contrast_toggled(enabled: bool)
signal color_palette_selected(palette: StringName)
signal visuals_toggled(enabled: bool)
signal reset_requested

@onready var title_label: Label = %TitleLabel
@onready var text_scale_label: Label = %TextScaleLabel
@onready var text_scale_option: OptionButton = %TextScaleOption
@onready var high_contrast_label: Label = %HighContrastLabel
@onready var high_contrast_toggle: CheckButton = %HighContrastToggle
@onready var color_palette_label: Label = %ColorPaletteLabel
@onready var color_palette_option: OptionButton = %ColorPaletteOption
@onready var visuals_label: Label = %VisualsLabel
@onready var visuals_toggle: CheckButton = %VisualsToggle
@onready var copy_button: Button = %CopyDiagnosticsButton
@onready var reset_button: Button = %ResetButton
@onready var close_button: Button = %CloseButton
@onready var reset_dialog: ConfirmationDialog = %ResetConfirm

var _suppress_signal := false
var _current_high_contrast := false
var _current_visuals_enabled := true
var _current_palette: StringName = ProceduralFactory.PALETTE_DEFAULT

func _ready() -> void:
	hide()
	text_scale_option.clear()
	text_scale_option.item_selected.connect(_on_text_scale_option_selected)
	high_contrast_toggle.toggled.connect(_on_high_contrast_toggled)
	color_palette_option.item_selected.connect(_on_color_palette_option_selected)
	visuals_toggle.toggled.connect(_on_visuals_toggled)
	copy_button.pressed.connect(func(): diagnostics_requested.emit())
	reset_button.pressed.connect(_on_reset_pressed)
	close_button.pressed.connect(func(): hide())
	close_requested.connect(func(): hide())
	reset_dialog.confirmed.connect(func(): reset_requested.emit())
	populate_strings()
	populate_text_scale_options(1.0)
	populate_color_palette_options(_current_palette)
	_set_high_contrast_internal(false)
	_set_visuals_internal(true)
	_apply_styles()

func show_panel(current_scale: float, high_contrast: bool, palette: StringName) -> void:
	populate_text_scale_options(current_scale)
	set_high_contrast(high_contrast)
	set_color_palette(palette)
	set_visuals_enabled(_current_visuals_enabled)
	popup_centered()
	grab_focus()

func populate_strings() -> void:
	title_label.text = _strings("settings_title", title_label.text)
	text_scale_label.text = _strings("text_scale_label", text_scale_label.text)
	var labels: Dictionary = {
		100: _strings("text_scale_100", "100%"),
		110: _strings("text_scale_110", "110%"),
		125: _strings("text_scale_125", "125%")
	}
	for i in range(text_scale_option.get_item_count()):
		var meta: Variant = text_scale_option.get_item_metadata(i)
		if meta is float or meta is int:
			var key := int(round(float(meta) * 100))
			if labels.has(key):
				text_scale_option.set_item_text(i, labels[key])
	copy_button.text = _strings("copy_diagnostics", copy_button.text)
	reset_button.text = _strings("reset_save_button", reset_button.text)
	close_button.text = _strings("close_button", close_button.text)
	high_contrast_label.text = _strings("high_contrast_label", high_contrast_label.text)
	high_contrast_toggle.tooltip_text = _strings("high_contrast_tooltip", high_contrast_toggle.tooltip_text)
	color_palette_label.text = _strings("color_palette_label", color_palette_label.text)
	color_palette_option.tooltip_text = _strings("color_palette_tooltip", color_palette_option.tooltip_text)
	_refresh_color_palette_option_labels()
	visuals_label.text = _strings("visuals_label", visuals_label.text)
	visuals_toggle.text = _strings("settings_visuals", visuals_toggle.text)
	visuals_toggle.tooltip_text = _strings("visuals_feed_particles", visuals_toggle.tooltip_text)
	reset_dialog.title = _strings("reset_save_dialog_title", reset_dialog.title)
	reset_dialog.dialog_text = _strings("reset_save_dialog_body", reset_dialog.dialog_text)
	reset_dialog.ok_button_text = _strings("reset_save_dialog_confirm", reset_dialog.ok_button_text)
	reset_dialog.cancel_button_text = _strings("reset_save_dialog_cancel", reset_dialog.cancel_button_text)

func populate_text_scale_options(current_scale: float) -> void:
	_suppress_signal = true
	text_scale_option.clear()
	var options: Array[float] = [1.0, 1.1, 1.25]
	for scale in options:
		var percent := int(round(scale * 100))
		var label := "%d%%" % percent
		match percent:
			100:
				label = _strings("text_scale_100", label)
			110:
				label = _strings("text_scale_110", label)
			125:
				label = _strings("text_scale_125", label)
		text_scale_option.add_item(label)
		text_scale_option.set_item_metadata(text_scale_option.get_item_count() - 1, scale)
	var closest_idx := 0
	var best_diff := INF
	for i in range(text_scale_option.get_item_count()):
		var meta: Variant = text_scale_option.get_item_metadata(i)
		var diff: float = abs(float(meta) - current_scale)
		if diff < best_diff:
			best_diff = diff
			closest_idx = i
	text_scale_option.selected = closest_idx
	_suppress_signal = false

func _on_text_scale_option_selected(index: int) -> void:
	if _suppress_signal:
		return
	var meta: Variant = text_scale_option.get_item_metadata(index)
	if meta is float or meta is int:
		text_scale_selected.emit(float(meta))

func _on_high_contrast_toggled(pressed: bool) -> void:
	if _suppress_signal:
		return
	_current_high_contrast = pressed
	high_contrast_toggled.emit(pressed)

func set_high_contrast(enabled: bool) -> void:
	_set_high_contrast_internal(enabled)

func _set_high_contrast_internal(enabled: bool) -> void:
	_suppress_signal = true
	_current_high_contrast = enabled
	high_contrast_toggle.button_pressed = enabled
	_suppress_signal = false
	_apply_styles()

func _on_visuals_toggled(pressed: bool) -> void:
	if _suppress_signal:
		return
	_current_visuals_enabled = pressed
	visuals_toggled.emit(pressed)

func _on_reset_pressed() -> void:
	reset_dialog.popup_centered()

func set_visuals_enabled(enabled: bool) -> void:
	_set_visuals_internal(enabled)

func _set_visuals_internal(enabled: bool) -> void:
	_suppress_signal = true
	_current_visuals_enabled = enabled
	visuals_toggle.button_pressed = enabled
	_suppress_signal = false

func on_strings_reloaded() -> void:
	populate_strings()

func set_color_palette(palette: StringName) -> void:
	populate_color_palette_options(palette)

func populate_color_palette_options(current_palette: StringName) -> void:
	_suppress_signal = true
	color_palette_option.clear()
	_current_palette = ProceduralFactory.ensure_palette(current_palette)
	var palettes: Array[StringName] = ProceduralFactory.supported_palettes()
	var selected_index := 0
	for palette_id in palettes:
		var label_key := ProceduralFactory.palette_label_key(palette_id)
		var label_text := _strings(label_key, String(palette_id).capitalize())
		color_palette_option.add_item(label_text)
		var item_index := color_palette_option.get_item_count() - 1
		color_palette_option.set_item_metadata(item_index, palette_id)
		if palette_id == _current_palette:
			selected_index = item_index
	color_palette_option.select(selected_index)
	_suppress_signal = false
	_refresh_color_palette_option_labels()

func _refresh_color_palette_option_labels() -> void:
	if color_palette_option == null:
		return
	for i in range(color_palette_option.get_item_count()):
		var meta: Variant = color_palette_option.get_item_metadata(i)
		if meta is StringName:
			var palette_id: StringName = meta
			var label_key := ProceduralFactory.palette_label_key(palette_id)
			var label_text := _strings(label_key, color_palette_option.get_item_text(i))
			color_palette_option.set_item_text(i, label_text)

func _on_color_palette_option_selected(index: int) -> void:
	if _suppress_signal:
		return
	var meta: Variant = color_palette_option.get_item_metadata(index)
	if meta is StringName:
		var palette_id: StringName = ProceduralFactory.ensure_palette(meta)
		_current_palette = palette_id
		color_palette_selected.emit(palette_id)

func _apply_styles() -> void:
	var panel := get_node_or_null("Panel")
	if panel is PanelContainer:
		(panel as PanelContainer).add_theme_stylebox_override("panel", ArtRegistry.get_style("ui_panel", _current_high_contrast))
	var text_color := ProceduralFactory.COLOR_TEXT
	for label in [title_label, text_scale_label, high_contrast_label, color_palette_label, visuals_label]:
		if label:
			label.add_theme_color_override("font_color", text_color)
	var buttons := [copy_button, reset_button, close_button, color_palette_option]
	for button in buttons:
		if button:
			button.add_theme_stylebox_override("normal", ArtRegistry.get_style("ui_button", _current_high_contrast))
			button.add_theme_stylebox_override("hover", ArtRegistry.get_style("ui_button_hover", _current_high_contrast))
			button.add_theme_stylebox_override("pressed", ArtRegistry.get_style("ui_button_pressed", _current_high_contrast))
			button.add_theme_color_override("font_color", text_color)
	if reset_dialog:
		var ok_button := reset_dialog.get_ok_button()
		var cancel_button := reset_dialog.get_cancel_button()
		for dialog_button in [ok_button, cancel_button]:
			if dialog_button:
				dialog_button.add_theme_stylebox_override("normal", ArtRegistry.get_style("ui_button", _current_high_contrast))
				dialog_button.add_theme_stylebox_override("hover", ArtRegistry.get_style("ui_button_hover", _current_high_contrast))
				dialog_button.add_theme_stylebox_override("pressed", ArtRegistry.get_style("ui_button_pressed", _current_high_contrast))
				dialog_button.add_theme_color_override("font_color", text_color)

func _strings(key: String, fallback: String) -> String:
	var strings_node := get_node_or_null("/root/Strings")
	if strings_node is StringsCatalog:
		return (strings_node as StringsCatalog).get_text(key, fallback)
	return fallback
