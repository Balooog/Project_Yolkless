extends Control
class_name AutomationPanelUI

signal automation_panel_opened
signal automation_panel_closed
signal automation_target_changed(target_id: StringName)

const Tokens := preload("res://ui/theme/Tokens.tres")
const StringsPath := "/root/Strings"

@export var tokens: UITokens

@onready var _panel: PanelContainer = %Panel
@onready var _title_label: Label = %AutomationTitle
@onready var _state_label: Label = %AutomationStateLabel
@onready var _economy_value_label: Label = %EconomyValue
@onready var _backlog_value_label: Label = %BacklogValue
@onready var _toggle: CheckButton = %AutomationToggle
@onready var _slider: HSlider = %AutomationSlider
@onready var _slider_value_label: Label = %AutomationSliderValue
@onready var _slider_label: Label = %AutomationSliderLabel
@onready var _target_label: Label = %AutomationTargetLabel
@onready var _target_selector: OptionButton = %TargetSelector
@onready var _hint_label: Label = %AutomationHintLabel
@onready var _close_button: Button = %AutomationCloseButton

var _automation_service: AutomationService
var _economy: Economy
var _conveyor: ConveyorManager
var _strings: Node
var _power_limited := false
var _visible_state := false

func _ready() -> void:
	hide()
	_strings = get_node_or_null(StringsPath)
	_apply_tokens()
	_apply_strings()
	_slider.min_value = 0.0
	_slider.max_value = 100.0
	_slider.step = 1.0
	_toggle.toggled.connect(_on_toggle_toggled)
	_slider.value_changed.connect(_on_slider_changed)
	_target_selector.item_selected.connect(_on_target_selected)
	_close_button.pressed.connect(hide_panel)
	_populate_targets()

func attach_services(economy: Economy, conveyor: ConveyorManager, automation: AutomationService) -> void:
	_economy = economy
	_conveyor = conveyor
	_automation_service = automation
	_sync_from_services()

func show_panel() -> void:
	if _visible_state:
		return
	visible = true
	_visible_state = true
	_sync_from_services()
	automation_panel_opened.emit()

func hide_panel() -> void:
	if not _visible_state:
		return
	visible = false
	_visible_state = false
	automation_panel_closed.emit()

func set_power_limited(limited: bool) -> void:
	_power_limited = limited
	_update_state_label()

func update_economy_rate(label: String) -> void:
	if _economy_value_label:
		_economy_value_label.text = label

func update_backlog(label: String, tone: StringName) -> void:
	if _backlog_value_label:
		_backlog_value_label.text = "%s (%s)" % [label, String(tone)]

func set_slider_ratio(ratio: float) -> void:
	var percent := clamp(ratio, 0.0, 1.0) * 100.0
	_slider.set_value_no_signal(percent)
	_update_slider_value_label(percent)

func set_toggle_state(enabled: bool) -> void:
	_toggle.set_pressed_no_signal(enabled)
	_update_state_label()

func set_hint_percent(percent: float) -> void:
	var rounded := clamp(percent, 0.0, 100.0)
	if _hint_label and _strings:
		var key := "automation_panel_slider_hint"
		var base := String(_strings.call("get_text", key, _hint_label.text if _hint_label.text != "" else "Trigger bursts when feed is above {percent}% capacity."))
		_hint_label.text = base.format({"percent": String.num(rounded, 0)})

func _apply_tokens() -> void:
	if tokens == null:
		tokens = Tokens
	if tokens == null:
		return
	UIHelpers.apply_panel_tokens(_panel, tokens)
	UIHelpers.apply_label_tokens(_title_label, tokens, &"font_l", &"banner_text")
	UIHelpers.apply_label_tokens(_state_label, tokens, &"font_s", &"body_text")
	UIHelpers.apply_label_tokens(_economy_value_label, tokens, &"font_s", &"body_text")
	UIHelpers.apply_label_tokens(_backlog_value_label, tokens, &"font_s", &"body_text")
	UIHelpers.apply_label_tokens(_slider_label, tokens, &"font_s", &"body_text")
	UIHelpers.apply_label_tokens(_target_label, tokens, &"font_s", &"body_text")
	UIHelpers.apply_label_tokens(_hint_label, tokens, &"font_xs", &"muted_text")
	UIHelpers.apply_button_tokens(_close_button, tokens)

func _apply_strings() -> void:
	if _strings == null:
		return
	_title_label.text = String(_strings.call("get_text", "automation_panel_title", _title_label.text))
	_state_label.text = String(_strings.call("get_text", "automation_panel_state_label", _state_label.text))
	_slider_label.text = String(_strings.call("get_text", "automation_panel_slider_label", _slider_label.text))
	_target_label.text = String(_strings.call("get_text", "automation_panel_target_label", _target_label.text))
	_close_button.text = String(_strings.call("get_text", "automation_panel_close_button", _close_button.text))
	var hint_template := String(_strings.call("get_text", "automation_panel_slider_hint", _hint_label.text))
	_hint_label.text = hint_template.format({"percent": String.num(50, 0)})

func _populate_targets() -> void:
	_target_selector.clear()
	var catalog := _strings
	var auto_label := "Auto-feed bursts"
	var auto_tooltip := "Automatically trigger Feed bursts when production dips below the sweet spot."
	if catalog:
		auto_label = String(catalog.call("get_text", "automation_target_autoburst", auto_label))
		auto_tooltip = String(catalog.call("get_text", "automation_target_autoburst_tooltip", auto_tooltip))
	var manual_label := "Manual cadence"
	var manual_tooltip := "Stay hands-on."
	if catalog:
		manual_label = String(catalog.call("get_text", "automation_target_manual", manual_label))
		manual_tooltip = String(catalog.call("get_text", "automation_target_manual_tooltip", manual_tooltip))
	_target_selector.add_item(auto_label, 0)
	_target_selector.set_item_metadata(0, StringName("economy_feed_autoburst"))
	_target_selector.add_item(manual_label, 1)
	_target_selector.set_item_metadata(1, StringName())
	_target_selector.set_item_tooltip(0, auto_tooltip)
	_target_selector.set_item_tooltip(1, manual_tooltip)
	_target_selector.select(0)

func _sync_from_services() -> void:
	if _automation_service:
		set_toggle_state(_automation_service.is_global_enabled())
	if _economy:
		set_slider_ratio(_economy.automation_feed_threshold())
		set_hint_percent(_slider.value)
	if _conveyor:
		_conveyor.set_user_speed_bias(_slider.value / 100.0)
	_update_state_label()

func _update_state_label() -> void:
	if _strings == null:
		return
	var key := "automation_state_enabled" if _toggle.button_pressed else "automation_state_disabled"
	var text := String(_strings.call("get_text", key, _state_label.text))
	if _power_limited:
		var suffix := String(_strings.call("get_text", "automation_state_power_limited", " — limited by power"))
		text += suffix
	_state_label.text = text

func _on_toggle_toggled(pressed: bool) -> void:
	if _automation_service:
		_automation_service.set_global_enabled(pressed)
	_update_state_label()

func _on_slider_changed(value: float) -> void:
	var ratio := clamp(value / 100.0, 0.0, 1.0)
	_update_slider_value_label(value)
	set_hint_percent(value)
	if _economy:
		_economy.set_automation_feed_threshold(ratio)
	if _conveyor:
		_conveyor.set_user_speed_bias(ratio)

func _update_slider_value_label(value: float) -> void:
	if _slider_value_label and _strings:
		var template := String(_strings.call("get_text", "automation_panel_slider_value", "{percent}%"))
		_slider_value_label.text = template.format({"percent": String.num(value, 0)})
	elif _slider_value_label:
		_slider_value_label.text = "%d%%" % int(round(value))

func _on_target_selected(index: int) -> void:
	var metadata: Variant = _target_selector.get_item_metadata(index)
	var target_id: StringName = metadata if metadata is StringName else StringName()
	automation_target_changed.emit(target_id)

