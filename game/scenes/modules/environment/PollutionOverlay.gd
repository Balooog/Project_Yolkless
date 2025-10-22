extends HBoxContainer
class_name PollutionOverlay

@onready var pollution_label: Label = %PollutionLabel
@onready var pollution_bar: ProgressBar = %PollutionBar
@onready var stress_label: Label = %StressLabel
@onready var stress_bar: ProgressBar = %StressBar
@onready var reputation_label: Label = %ReputationLabel
@onready var reputation_bar: ProgressBar = %ReputationBar

var _strings: StringsCatalog
var _high_contrast := false

func _ready() -> void:
	_apply_styles()

func set_strings(strings: StringsCatalog) -> void:
	_strings = strings
	_apply_strings()

func set_high_contrast(enabled: bool) -> void:
	if _high_contrast == enabled:
		return
	_high_contrast = enabled
	_apply_styles()

func update_state(pollution: float, stress: float, reputation: float) -> void:
	_set_bar(pollution_bar, pollution_label, pollution, _pollution_color(pollution))
	_set_bar(stress_bar, stress_label, stress, _stress_color(stress))
	_set_bar(reputation_bar, reputation_label, reputation, _reputation_color(reputation))

func _apply_strings() -> void:
	if _strings == null:
		return
	pollution_label.text = _strings.get_text("pollution_label", pollution_label.text)
	stress_label.text = _strings.get_text("stress_label", stress_label.text)
	reputation_label.text = _strings.get_text("reputation_label", reputation_label.text)
	var env_label: String = _strings.get_text("environment_label", "")
	if env_label != "":
		tooltip_text = env_label

func _apply_styles() -> void:
	var background := ArtRegistry.get_style("ui_progress_bg", _high_contrast)
	var labels := [pollution_label, stress_label, reputation_label]
	for label in labels:
		label.add_theme_color_override("font_color", ProceduralFactory.COLOR_TEXT)
	for bar in [pollution_bar, stress_bar, reputation_bar]:
		if background:
			bar.add_theme_stylebox_override("background", background.duplicate(true))
		bar.add_theme_stylebox_override("fill", ArtRegistry.get_style("ui_progress_fill", _high_contrast))

func _set_bar(bar: ProgressBar, label: Label, value: float, color: Color) -> void:
	bar.max_value = 100.0
	bar.value = clamp(value, 0.0, 100.0)
	var fill_style := ArtRegistry.get_style("ui_progress_fill", _high_contrast)
	if fill_style is StyleBoxFlat:
		(fill_style as StyleBoxFlat).bg_color = color
	bar.add_theme_stylebox_override("fill", fill_style)
	bar.add_theme_color_override("font_color", ProceduralFactory.COLOR_BG)
	bar.tooltip_text = "%s: %.0f" % [label.text, value]

func _pollution_color(value: float) -> Color:
	var ratio: float = clamp(value / 100.0, 0.0, 1.0)
	return Color(lerp(0.2, 0.8, ratio), lerp(0.6, 0.2, ratio), 0.15, 1.0)

func _stress_color(value: float) -> Color:
	var ratio: float = clamp(value / 100.0, 0.0, 1.0)
	return Color(0.85, lerp(0.8, 0.25, ratio), lerp(0.3, 0.2, ratio), 1.0)

func _reputation_color(value: float) -> Color:
	var ratio: float = clamp(value / 100.0, 0.0, 1.0)
	return Color(lerp(0.7, 0.1, ratio), lerp(0.2, 0.7, ratio), 0.2, 1.0)
