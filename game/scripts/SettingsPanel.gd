extends Window
class_name SettingsPanel

signal text_scale_selected(scale: float)
signal diagnostics_requested

@onready var title_label: Label = %TitleLabel
@onready var text_scale_label: Label = %TextScaleLabel
@onready var text_scale_option: OptionButton = %TextScaleOption
@onready var copy_button: Button = %CopyDiagnosticsButton
@onready var close_button: Button = %CloseButton

var _suppress_signal := false

func _ready() -> void:
	hide()
	text_scale_option.clear()
	text_scale_option.item_selected.connect(_on_text_scale_option_selected)
	copy_button.pressed.connect(func(): diagnostics_requested.emit())
	close_button.pressed.connect(func(): hide())
	close_requested.connect(func(): hide())
	populate_strings()
	populate_text_scale_options(1.0)

func show_panel(current_scale: float) -> void:
	populate_text_scale_options(current_scale)
	popup_centered()
	grab_focus()

func populate_strings() -> void:
	title_label.text = _strings("settings_title", title_label.text)
	text_scale_label.text = _strings("text_scale_label", text_scale_label.text)
	var labels := {
		100: _strings("text_scale_100", "100%"),
		110: _strings("text_scale_110", "110%"),
		125: _strings("text_scale_125", "125%")
	}
	for i in range(text_scale_option.get_item_count()):
		var meta := text_scale_option.get_item_metadata(i)
		if meta is float or meta is int:
			var key := int(round(float(meta) * 100))
			if labels.has(key):
				text_scale_option.set_item_text(i, labels[key])
	copy_button.text = _strings("copy_diagnostics", copy_button.text)
	close_button.text = _strings("close_button", close_button.text)

func populate_text_scale_options(current_scale: float) -> void:
	_suppress_signal = true
	text_scale_option.clear()
	var options := [1.0, 1.1, 1.25]
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
		var meta := text_scale_option.get_item_metadata(i)
		var diff := abs(float(meta) - current_scale)
		if diff < best_diff:
			best_diff = diff
			closest_idx = i
	text_scale_option.selected = closest_idx
	_suppress_signal = false

func _on_text_scale_option_selected(index: int) -> void:
	if _suppress_signal:
		return
	var meta := text_scale_option.get_item_metadata(index)
	if meta is float or meta is int:
		text_scale_selected.emit(float(meta))

func on_strings_reloaded() -> void:
	populate_strings()

func _strings(key: String, fallback: String) -> String:
	var strings := get_node_or_null("/root/Strings")
	if strings:
		return strings.call("get_string", key, fallback)
	return fallback
*** End of File
