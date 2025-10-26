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

func _ready() -> void:
	UIHelpers.set_fill_expand(self, true, false)
	_apply_tokens()

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
