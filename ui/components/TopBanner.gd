extends Control
class_name TopBanner

@export var tokens: UITokens

@onready var _container: HBoxContainer = %BannerContainer
@onready var _metric_labels: Array[Label] = [
	%CreditsValue,
	%StorageValue,
	%PpsValue,
	%ResearchValue
]
@onready var _alert_pill: Label = %AlertPill

func _ready() -> void:
	UIHelpers.set_fill_expand(self, true, false)
	_apply_tokens()

func _apply_tokens() -> void:
	if tokens == null:
		return
	add_theme_constant_override("separation", int(tokens.spacing_value(&"space_lg")))
	for label in _metric_labels:
		UIHelpers.apply_label_tokens(label, tokens, &"font_m", &"banner_text")
		UIHelpers.ensure_overflow_policy(label, false)
	if _alert_pill:
		UIHelpers.apply_label_tokens(_alert_pill, tokens, &"font_s", &"banner_alert")
		UIHelpers.ensure_overflow_policy(_alert_pill, false)
