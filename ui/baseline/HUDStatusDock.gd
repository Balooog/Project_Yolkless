extends Control
class_name HUDStatusDock

const TOKENS := preload("res://ui/theme/Tokens.tres")
const STATUS_TONES := {
	StringName("normal"): StringName("hud_label_normal"),
	StringName("warning"): StringName("hud_label_warning"),
	StringName("critical"): StringName("hud_label_critical")
}

@export var background_color: Color = Color(0.078, 0.094, 0.122, 1.0)

@export var power_visible: bool = true
@export var power_value: String = "Load Stable"
@export var power_tone: String = "normal"

@export var economy_visible: bool = true
@export var economy_value: String = "₡ 0"
@export var economy_tone: String = "normal"

@export var population_visible: bool = true
@export var population_value: String = "0 hens"
@export var population_tone: String = "normal"

@onready var _background: ColorRect = %Background
@onready var _panel: PanelContainer = %DockPanel
@onready var _power_row: HBoxContainer = %PowerRow
@onready var _power_title: Label = %PowerTitle
@onready var _power_value_label: Label = %PowerValue
@onready var _power_icon: ColorRect = %PowerIcon
@onready var _economy_row: HBoxContainer = %EconomyRow
@onready var _economy_title: Label = %EconomyTitle
@onready var _economy_value_label: Label = %EconomyValue
@onready var _economy_icon: ColorRect = %EconomyIcon
@onready var _population_row: HBoxContainer = %PopulationRow
@onready var _population_title: Label = %PopulationTitle
@onready var _population_value_label: Label = %PopulationValue
@onready var _population_icon: ColorRect = %PopulationIcon

func _ready() -> void:
	_apply_background()
	_apply_panel_style()
	_apply_static_tokens()
	_apply_status_row(
		_power_row,
		_power_title,
		_power_value_label,
		_power_icon,
		power_visible,
		power_value,
		power_tone
	)
	_apply_status_row(
		_economy_row,
		_economy_title,
		_economy_value_label,
		_economy_icon,
		economy_visible,
		economy_value,
		economy_tone
	)
	_apply_status_row(
		_population_row,
		_population_title,
		_population_value_label,
		_population_icon,
		population_visible,
		population_value,
		population_tone
	)

func _apply_background() -> void:
	if _background:
		_background.color = background_color

func _apply_panel_style() -> void:
	if _panel == null or TOKENS == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = TOKENS.colour(&"banner_bg")
	var radius := int(round(TOKENS.radius(&"corner_md")))
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = int(round(TOKENS.spacing_value(&"space_lg")))
	style.content_margin_right = int(round(TOKENS.spacing_value(&"space_lg")))
	style.content_margin_top = int(round(TOKENS.spacing_value(&"space_md")))
	style.content_margin_bottom = int(round(TOKENS.spacing_value(&"space_md")))
	_panel.add_theme_stylebox_override("panel", style)

func _apply_static_tokens() -> void:
	if TOKENS == null:
		return
	var titles := [
		_power_title,
		_economy_title,
		_population_title
	]
	for title in titles:
		UIHelpers.apply_label_tokens(title, TOKENS, &"font_s", &"text_muted")
		UIHelpers.ensure_overflow_policy(title, false)
	var values := [
		_power_value_label,
		_economy_value_label,
		_population_value_label
	]
	for value_label in values:
		UIHelpers.apply_label_tokens(value_label, TOKENS, &"font_l", &"hud_label_normal")
		UIHelpers.ensure_overflow_policy(value_label, false)

func _apply_status_row(
	row: HBoxContainer,
	title_label: Label,
	value_label: Label,
	icon_rect: ColorRect,
	visible: bool,
	value_text: String,
	tone: String
) -> void:
	if row == null:
		return
	row.visible = visible
	if not visible:
		return
	var tone_key := StringName(tone)
	if not STATUS_TONES.has(tone_key):
		tone_key = StringName("normal")
	var token_key: StringName = STATUS_TONES[tone_key]
	if value_label:
		UIHelpers.apply_label_tokens(value_label, TOKENS, &"font_l", token_key)
		value_label.text = value_text
		value_label.tooltip_text = value_text
	if icon_rect:
		icon_rect.color = TOKENS.colour(token_key)
	if title_label:
		title_label.tooltip_text = title_label.text
