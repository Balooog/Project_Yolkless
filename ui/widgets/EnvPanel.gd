extends VBoxContainer
class_name EnvPanel

signal details_toggled(visible: bool)
signal preset_selected(preset: StringName)

const PowerService := preload("res://src/services/PowerService.gd")
const POWER_WARNING_COLOR := Color(0.996, 0.784, 0.318, 1.0)
const POWER_CRITICAL_COLOR := Color(0.984, 0.412, 0.392, 1.0)
const POWER_ICON_NORMAL := "⚡"
const POWER_ICON_WARNING := "⚡!"
const POWER_ICON_CRITICAL := "⚠⚡"

@onready var header_panel: PanelContainer = %HeaderPanel
@onready var phase_label: Label = %PhaseLabel
@onready var summary_label: Label = %SummaryLabel
@onready var toggle_button: Button = %ToggleButton
@onready var preset_selector: OptionButton = %PresetSelector
@onready var weather_icon: TextureRect = %WeatherIcon
@onready var detail_panel: PanelContainer = %DetailPanel
@onready var temp_value: Label = %TemperatureValue
@onready var light_value: Label = %LightValue
@onready var humidity_value: Label = %HumidityValue
@onready var air_value: Label = %AirValue
@onready var pollution_value: Label = %PollutionValue
@onready var stress_value: Label = %StressValue
@onready var reputation_value: Label = %ReputationValue
@onready var feed_value: Label = %FeedValue
@onready var power_value: Label = %PowerValue
@onready var prestige_value: Label = %PrestigeValue
@onready var comfort_value: Label = %ComfortValue
@onready var comfort_bonus_value: Label = %ComfortBonusValue

var _strings: StringsCatalog
var _high_contrast := false
var _last_state: Dictionary = {}
var _preset_ids: Array[StringName] = []
var _suppress_preset_signal := false
var _sandbox_metrics: Dictionary = {}
const DEFAULT_ICON_KEY := "weather_icon_day"
var _power_warning_level: StringName = PowerService.WARNING_NORMAL
var _last_power_modifier: float = 1.0
var _power_ratio_last: float = 1.0
var _power_base_color: Color = ProceduralFactory.COLOR_TEXT

func _ready() -> void:
	toggle_button.toggle_mode = true
	toggle_button.button_pressed = false
	detail_panel.visible = false
	toggle_button.toggled.connect(_on_toggle_details)
	if preset_selector:
		preset_selector.item_selected.connect(_on_preset_item_selected)
	_apply_styles()
	_apply_strings()
	if weather_icon:
		weather_icon.texture = ArtRegistry.get_texture(DEFAULT_ICON_KEY)
		weather_icon.tooltip_text = ""

func set_strings(strings: StringsCatalog) -> void:
	_strings = strings
	_apply_strings()
	_update_state_texts()

func set_high_contrast(enabled: bool) -> void:
	if _high_contrast == enabled:
		return
	_high_contrast = enabled
	_apply_styles()

func update_state(state: Dictionary) -> void:
	_last_state = state.duplicate(true)
	_update_state_texts()

func update_comfort(ci: float, bonus: float, metrics: Dictionary = {}) -> void:
	var clamped_ci: float = clamp(ci, 0.0, 1.0)
	var clamped_bonus: float = max(bonus, 0.0)
	var comfort_data: Dictionary = {
		"ci": clamped_ci,
		"bonus": clamped_bonus
	}
	if not metrics.is_empty():
		for key in metrics.keys():
			comfort_data[key] = metrics[key]
	_sandbox_metrics = comfort_data
	_update_state_texts()

func set_presets(presets: Array) -> void:
	_preset_ids.clear()
	if preset_selector == null:
		return
	_suppress_preset_signal = true
	preset_selector.clear()
	for preset in presets:
		var id := StringName(preset.get("id", ""))
		if id == StringName():
			continue
		var label := String(preset.get("label", String(id)))
		_preset_ids.append(id)
		preset_selector.add_item(label)
	_suppress_preset_signal = false
	var has_multiple := preset_selector.item_count > 1
	preset_selector.visible = has_multiple
	preset_selector.disabled = not has_multiple
	_sync_selector_to_state()

func select_preset(preset: StringName) -> void:
	if preset_selector == null:
		return
	var index := _preset_ids.find(preset)
	if index == -1:
		return
	_suppress_preset_signal = true
	preset_selector.select(index)
	_suppress_preset_signal = false

func _update_state_texts() -> void:
	if _last_state.is_empty():
		return
	var phase := String(_last_state.get("phase", ""))
	var preset_label := String(_last_state.get("label", ""))
	var phase_display := _display_phase(phase)
	if preset_label == "":
		preset_label = phase_display
	phase_label.text = "%s — %s" % [phase_display, preset_label]

	var temp_c := float(_last_state.get("temperature_c", 0.0))
	var temp_f := float(_last_state.get("temperature_f", 32.0))
	var light_pct := float(_last_state.get("light_pct", 0.0))
	var humidity_pct := float(_last_state.get("humidity_pct", 0.0))
	var air_pct := float(_last_state.get("air_quality_pct", 0.0))
	var modifiers: Dictionary = _last_state.get("modifiers", {})
	var comfort_ci: float = float(_sandbox_metrics.get("ci", _last_state.get("comfort_index", 0.0)))
	var comfort_bonus: float = float(_sandbox_metrics.get("bonus", _last_state.get("ci_bonus", 0.0)))

	summary_label.text = "%s  |  %s" % [
		_format_temp_summary(temp_c),
		_format_air_summary(air_pct)
	]
	var comfort_summary := _format_comfort_summary(comfort_bonus)
	var summary_parts: Array[String] = []
	summary_parts.append(_format_temp_summary(temp_c))
	summary_parts.append(_format_air_summary(air_pct))
	if comfort_summary != "":
		summary_parts.append(comfort_summary)
	var era_label_text := String(_sandbox_metrics.get("era_label", ""))
	if era_label_text != "":
		summary_parts.append("Era: %s" % era_label_text)
	summary_label.text = "  |  ".join(summary_parts)

	if weather_icon:
		var icon_key := _weather_icon_key(phase, air_pct)
		weather_icon.texture = ArtRegistry.get_texture(icon_key)
		weather_icon.tooltip_text = _format_weather_tooltip(phase_display, temp_c, air_pct)

	temp_value.text = "%0.1f °C  /  %0.1f °F" % [temp_c, temp_f]
	light_value.text = "%0.0f%%" % light_pct
	humidity_value.text = "%0.0f%%" % humidity_pct
	air_value.text = "%0.0f%%" % air_pct
	pollution_value.text = "%0.0f" % float(_last_state.get("pollution", 0.0))
	stress_value.text = "%0.0f" % float(_last_state.get("stress", 0.0))
	reputation_value.text = "%0.0f" % float(_last_state.get("reputation", 0.0))
	feed_value.text = "%0.1f×" % float(modifiers.get("feed", 1.0))
	_last_power_modifier = float(modifiers.get("power", 1.0))
	_power_ratio_last = float(_last_state.get("power_ratio", _last_power_modifier))
	_refresh_power_value_text()
	prestige_value.text = "%0.1f×" % float(modifiers.get("prestige", 1.0))
	var comfort_percent: float = clamp(comfort_ci * 100.0, 0.0, 100.0)
	comfort_value.text = "%0.0f%%" % comfort_percent
	var bonus_percent: float = max(comfort_bonus * 100.0, 0.0)
	comfort_bonus_value.text = "+%0.1f%%" % bonus_percent
	if comfort_value:
		var tooltip_parts: Array[String] = ["Comfort %.2f%%" % comfort_percent]
		if era_label_text != "":
			tooltip_parts.append("Era: %s" % era_label_text)
		if bool(_sandbox_metrics.get("fallback_active", false)):
			tooltip_parts.append("Renderer fallback")
		comfort_value.tooltip_text = " — ".join(tooltip_parts)
		if comfort_bonus_value:
			comfort_bonus_value.tooltip_text = comfort_value.tooltip_text

	_sync_selector_to_state()

func _apply_styles() -> void:
	var panel_style := ArtRegistry.get_style("ui_panel", _high_contrast)
	if panel_style:
		header_panel.add_theme_stylebox_override("panel", panel_style.duplicate(true))
		detail_panel.add_theme_stylebox_override("panel", panel_style.duplicate(true))
	var label_color := ProceduralFactory.COLOR_TEXT
	_power_base_color = label_color
	for label in [
		phase_label,
		summary_label,
		%TemperatureLabel,
		%LightLabel,
		%HumidityLabel,
		%AirLabel,
		%PollutionLabel,
		%StressLabel,
		%ReputationLabel,
		%FeedLabel,
		%PowerLabel,
		%PrestigeLabel,
		%ComfortLabel,
		%ComfortBonusLabel,
		temp_value,
		light_value,
		humidity_value,
		air_value,
		pollution_value,
		stress_value,
		reputation_value,
		feed_value,
		power_value,
		prestige_value,
		comfort_value,
		comfort_bonus_value
	]:
		label.add_theme_color_override("font_color", label_color)
	var normal := ArtRegistry.get_style("ui_button", _high_contrast)
	var hover := ArtRegistry.get_style("ui_button_hover", _high_contrast)
	var pressed := ArtRegistry.get_style("ui_button_pressed", _high_contrast)
	if normal:
		toggle_button.add_theme_stylebox_override("normal", normal)
		if preset_selector:
			preset_selector.add_theme_stylebox_override("normal", normal)
	if hover:
		toggle_button.add_theme_stylebox_override("hover", hover)
		if preset_selector:
			preset_selector.add_theme_stylebox_override("hover", hover)
	if pressed:
		toggle_button.add_theme_stylebox_override("pressed", pressed)
		if preset_selector:
			preset_selector.add_theme_stylebox_override("pressed", pressed)
	toggle_button.add_theme_color_override("font_color", label_color)
	if preset_selector:
		preset_selector.add_theme_color_override("font_color", label_color)
		var focus_style := ArtRegistry.get_style("ui_button_hover", _high_contrast)
		if focus_style:
			preset_selector.add_theme_stylebox_override("focus", focus_style)

func set_power_warning_state(level: StringName, ratio: float) -> void:
	_power_warning_level = level
	_power_ratio_last = ratio
	_refresh_power_value_text()

func _refresh_power_value_text() -> void:
	if power_value == null:
		return
	var icon := _power_icon_for(_power_warning_level)
	var multiplier_text := "%0.1f×" % _last_power_modifier
	if icon != "":
		power_value.text = "%s %s" % [icon, multiplier_text]
	else:
		power_value.text = multiplier_text
	var swatch := _power_base_color
	match _power_warning_level:
		PowerService.WARNING_CRITICAL:
			swatch = POWER_CRITICAL_COLOR
		PowerService.WARNING_WARNING:
			swatch = POWER_WARNING_COLOR
	power_value.add_theme_color_override("font_color", swatch)
	var tooltip_base := power_value.tooltip_text
	if _strings:
		tooltip_base = _strings.get_text("environment_power_modifier_tooltip", tooltip_base)
	var ratio_percent: float = clamp(_power_ratio_last * 100.0, 0.0, 200.0)
	power_value.tooltip_text = "%s — %0.0f%%" % [tooltip_base, ratio_percent]

func _power_icon_for(level: StringName) -> String:
	match level:
		PowerService.WARNING_CRITICAL:
			return POWER_ICON_CRITICAL
		PowerService.WARNING_WARNING:
			return POWER_ICON_WARNING
		_:
			return POWER_ICON_NORMAL

func _apply_strings() -> void:
	if _strings == null:
		return
	%HeaderTitle.text = _strings.get_text("environment_title", %HeaderTitle.text)
	toggle_button.text = _strings.get_text("environment_toggle_details", toggle_button.text)
	if preset_selector:
		preset_selector.tooltip_text = _strings.get_text("environment_preset_selector_tooltip", "Switch environment preset")
	%TemperatureLabel.text = _strings.get_text("environment_temperature", %TemperatureLabel.text)
	%LightLabel.text = _strings.get_text("environment_light", %LightLabel.text)
	%HumidityLabel.text = _strings.get_text("environment_humidity", %HumidityLabel.text)
	%AirLabel.text = _strings.get_text("environment_air_quality", %AirLabel.text)
	%PollutionLabel.text = _strings.get_text("environment_pollution", %PollutionLabel.text)
	%StressLabel.text = _strings.get_text("environment_stress", %StressLabel.text)
	%ReputationLabel.text = _strings.get_text("environment_reputation", %ReputationLabel.text)
	%FeedLabel.text = _strings.get_text("environment_feed_modifier", %FeedLabel.text)
	%PowerLabel.text = _strings.get_text("environment_power_modifier", %PowerLabel.text)
	%PrestigeLabel.text = _strings.get_text("environment_prestige_modifier", %PrestigeLabel.text)
	%ComfortLabel.text = _strings.get_text("environment_comfort_index", %ComfortLabel.text)
	%ComfortBonusLabel.text = _strings.get_text("environment_comfort_bonus", %ComfortBonusLabel.text)
	_apply_tooltips()

func _display_phase(phase: String) -> String:
	var key := "environment_phase_%s" % phase
	if _strings:
		var localized := _strings.get_text(key, "")
		if localized != "":
			return localized
	return phase.to_upper()

func _format_temp_summary(temp_c: float) -> String:
	return "%0.1f °C" % temp_c

func _format_air_summary(air_pct: float) -> String:
	return "%0.0f%% Air" % air_pct

func _format_comfort_summary(comfort_bonus: float) -> String:
	var bonus_percent: float = max(comfort_bonus * 100.0, 0.0)
	return "Comfort +%0.1f%%" % bonus_percent

func _weather_icon_key(phase: String, air_pct: float) -> String:
	if air_pct < 55.0:
		return "weather_icon_hazard"
	match phase:
		"dawn":
			return "weather_icon_dawn"
		"dusk":
			return "weather_icon_dusk"
		"night":
			return "weather_icon_night"
		_:
			return DEFAULT_ICON_KEY

func _format_weather_tooltip(phase_label: String, temp_c: float, air_pct: float) -> String:
	return "%s — %0.1f °C • %0.0f%% Air" % [phase_label, temp_c, air_pct]

func _apply_tooltips() -> void:
	_set_tooltip(%TemperatureLabel, "environment_temperature_tooltip")
	_set_tooltip(temp_value, "environment_temperature_tooltip")
	_set_tooltip(%LightLabel, "environment_light_tooltip")
	_set_tooltip(light_value, "environment_light_tooltip")
	_set_tooltip(%HumidityLabel, "environment_humidity_tooltip")
	_set_tooltip(humidity_value, "environment_humidity_tooltip")
	_set_tooltip(%AirLabel, "environment_air_quality_tooltip")
	_set_tooltip(air_value, "environment_air_quality_tooltip")
	_set_tooltip(%PollutionLabel, "environment_pollution_tooltip")
	_set_tooltip(pollution_value, "environment_pollution_tooltip")
	_set_tooltip(%StressLabel, "environment_stress_tooltip")
	_set_tooltip(stress_value, "environment_stress_tooltip")
	_set_tooltip(%ReputationLabel, "environment_reputation_tooltip")
	_set_tooltip(reputation_value, "environment_reputation_tooltip")
	_set_tooltip(%FeedLabel, "environment_feed_modifier_tooltip")
	_set_tooltip(feed_value, "environment_feed_modifier_tooltip")
	_set_tooltip(%PowerLabel, "environment_power_modifier_tooltip")
	_set_tooltip(power_value, "environment_power_modifier_tooltip")
	_set_tooltip(%PrestigeLabel, "environment_prestige_modifier_tooltip")
	_set_tooltip(prestige_value, "environment_prestige_modifier_tooltip")
	_set_tooltip(%ComfortLabel, "environment_comfort_index_tooltip")
	_set_tooltip(comfort_value, "environment_comfort_index_tooltip")
	_set_tooltip(%ComfortBonusLabel, "environment_comfort_bonus_tooltip")
	_set_tooltip(comfort_bonus_value, "environment_comfort_bonus_tooltip")

func _set_tooltip(control: Control, key: String) -> void:
	if control == null:
		return
	var fallback := control.tooltip_text
	if _strings:
		control.tooltip_text = _strings.get_text(key, fallback)

func _on_toggle_details(pressed: bool) -> void:
	detail_panel.visible = pressed
	details_toggled.emit(pressed)

func _on_preset_item_selected(index: int) -> void:
	if _suppress_preset_signal:
		return
	if index < 0 or index >= _preset_ids.size():
		return
	preset_selected.emit(_preset_ids[index])

func _sync_selector_to_state() -> void:
	if preset_selector == null or _last_state.is_empty():
		return
	var preset := StringName(_last_state.get("preset", StringName()))
	if preset == StringName():
		return
	var index := _preset_ids.find(preset)
	if index == -1:
		return
	_suppress_preset_signal = true
	preset_selector.select(index)
	_suppress_preset_signal = false
