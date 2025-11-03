extends Control
class_name TopBanner

@export var tokens: UITokens

@onready var _container: HBoxContainer = %BannerContainer
@onready var _metric_columns: Array[VBoxContainer] = [
	%CreditsBox,
	%StorageBox,
	%PpsBox,
	%ResearchBox
]
@onready var _metric_title_labels: Array[Label] = [
    %CreditsLabel,
    %StorageLabel,
    %PpsLabel,
    %ResearchLabel
]
@onready var _metric_labels: Dictionary[StringName, Label] = {
	&"credits": %CreditsValue,
	&"storage": %StorageValue,
	&"pps": %PpsValue,
	&"research": %ResearchValue
}
@onready var _alert_pill: Label = %AlertPill
@onready var _status_rows: Dictionary[StringName, Dictionary] = {
	&"power": {"title": %PowerTitle, "value": %PowerValue, "icon": %PowerIcon},
	&"economy": {"title": %EconomyTitle, "value": %EconomyValue, "icon": %EconomyIcon},
	&"population": {"title": %PopulationTitle, "value": %PopulationValue, "icon": %PopulationIcon}
}

var _status_state: Dictionary[StringName, Dictionary] = {
	&"power": {"value": "Load Stable", "tone": StringName("normal")},
	&"economy": {"value": "₡ 0", "tone": StringName("normal")},
	&"population": {"value": "0 hens", "tone": StringName("normal")}
}

const STATUS_TONE_TOKENS := {
	&"normal": &"hud_label_normal",
	&"warning": &"hud_label_warning",
	&"critical": &"hud_label_critical"
}

func _ready() -> void:
	UIHelpers.set_fill_expand(self, true, false)
	_apply_tokens()
	_apply_status_state()

func _apply_tokens() -> void:
	if tokens == null:
		return
	add_theme_constant_override("separation", int(tokens.spacing_value(&"space_lg")))
	for label in _metric_labels.values():
		UIHelpers.apply_label_tokens(label, tokens, &"font_m", &"banner_text")
		UIHelpers.ensure_overflow_policy(label, false)
	if _alert_pill:
		UIHelpers.apply_label_tokens(_alert_pill, tokens, &"font_s", &"banner_alert")
		UIHelpers.ensure_overflow_policy(_alert_pill, false)
	_apply_status_tokens()

func metric_columns() -> Array[VBoxContainer]:
	return _metric_columns.duplicate()

func metric_title_labels() -> Array[Label]:
	return _metric_title_labels.duplicate()

func metric_labels() -> Dictionary:
	return _metric_labels.duplicate()

func get_metric_label(metric: StringName) -> Label:
	return _metric_labels.get(metric, null) as Label

func set_metric(metric: StringName, value: String) -> void:
	var label := get_metric_label(metric)
	if label:
		label.text = value
		label.tooltip_text = value

func get_alert_label() -> Label:
	return _alert_pill

func set_alert(message: String) -> void:
	if _alert_pill:
		_alert_pill.text = message
		_alert_pill.tooltip_text = message

func content_container() -> HBoxContainer:
	return _container


func set_status(status: Dictionary) -> void:
	for key_variant in _status_rows.keys():
		var status_key: StringName = key_variant
		var entry_variant: Variant = status.get(String(status_key), status.get(status_key, null))
		if entry_variant == null:
			continue
		var entry_dict: Dictionary
		if entry_variant is Dictionary:
			entry_dict = (entry_variant as Dictionary).duplicate(true)
		else:
			entry_dict = {"value": entry_variant}
		if not entry_dict.has("tone"):
			entry_dict["tone"] = StringName("normal")
		else:
			entry_dict["tone"] = StringName(entry_dict.get("tone", "normal"))
		_status_state[status_key] = entry_dict
	_apply_status_state()

func _apply_status_state() -> void:
	for key_variant in _status_rows.keys():
		var status_key: StringName = key_variant
		var state: Dictionary = _status_state.get(status_key, {})
		var row: Dictionary = _status_rows[status_key]
		var value_label := row.get("value", null) as Label
		if value_label:
			value_label.text = String(state.get("value", value_label.text))
			value_label.tooltip_text = value_label.text
	_apply_status_tokens()

func _apply_status_tokens() -> void:
	if tokens == null:
		return
	for key_variant in _status_rows.keys():
		var status_key: StringName = key_variant
		var state: Dictionary = _status_state.get(status_key, {"tone": StringName("normal")})
		var tone_variant: Variant = state.get("tone", StringName("normal"))
		var tone_key: StringName = StringName(tone_variant)
		var tone_token: StringName = STATUS_TONE_TOKENS.get(tone_key, &"hud_label_normal") as StringName
		var row: Dictionary = _status_rows[status_key]
		var title_label := row.get("title", null) as Label
		var value_label := row.get("value", null) as Label
		var icon_rect: Variant = row.get("icon", null)
		if title_label:
			UIHelpers.apply_label_tokens(title_label, tokens, &"font_s", &"text_muted")
		if value_label:
			UIHelpers.apply_label_tokens(value_label, tokens, &"font_l", tone_token)
		if icon_rect and icon_rect is ColorRect:
			(icon_rect as ColorRect).color = tokens.colour(tone_token)
