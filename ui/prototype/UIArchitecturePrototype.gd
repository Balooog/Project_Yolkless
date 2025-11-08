extends Control
class_name UIArchitecturePrototype

signal feed_requested
signal tab_selected(tab_id: String)
signal feed_hold_started
signal feed_hold_ended
signal promote_requested
signal upgrade_requested(upgrade_id: String)
signal research_requested(research_id: String)
signal prestige_requested
signal save_export_requested
signal save_import_requested
signal settings_requested
signal layout_changed
signal automation_panel_opened
signal automation_panel_closed
signal automation_target_changed(target_id: StringName)

const PHONE_BREAKPOINT := 600.0
const TABLET_BREAKPOINT := 900.0
const DESKTOP_BREAKPOINT := 1280.0
const BREAKPOINT_FUZZ := 40.0
const SHEET_HEIGHT_DESKTOP := 420.0
const SHEET_HEIGHT_TABLET := 320.0
const SHEET_HEIGHT_MOBILE := 360.0
const UI_TOKENS_RESOURCE := preload("res://ui/theme/Tokens.tres")
const TAB_SEQUENCE: Array[String] = ["home", "store", "research", "automation", "prestige"]
const FOCUS_LEFT := StringName("left")
const FOCUS_RIGHT := StringName("right")
const FOCUS_UP := StringName("up")
const FOCUS_DOWN := StringName("down")

var _current_tab := "home"
var _feed_queue_count := 0
var _feed_active := false
var _custom_canvas_hint := ""
var _custom_canvas_message := ""
var _metrics := {
	"credits": "₡ 0",
	"storage": "Storage 0 / 0",
	"pps": "0 PPS",
	"research": "0 RP"
}
var _status := {
	StringName("power"): {"value": "Load n/a", "tone": StringName("normal")},
	StringName("economy"): {"value": "₡ 0", "tone": StringName("normal")},
	StringName("population"): {"value": "0 hens", "tone": StringName("normal")},
	StringName("economy_rate"): {"value": "0.0/s", "tone": StringName("normal")},
	StringName("conveyor_backlog"): {"value": "Queue 0", "tone": StringName("normal")}
}
var _home_feed_default_text := "Hold to Feed"
var _is_desktop_layout := false

@onready var _root_margin_container: MarginContainer = $RootMargin
@onready var _bottom_bar: MarginContainer = $RootMargin/RootStack/BottomBar
@onready var _bottom_tab_container: HBoxContainer = $RootMargin/RootStack/BottomBar/TabBar
@onready var _main_stack: HBoxContainer = $RootMargin/RootStack/MainStack
@onready var _side_dock: Control = $RootMargin/RootStack/MainStack/SideDock
@onready var _sheet_overlay: Control = $RootMargin/RootStack/MainStack/CanvasWrapper/MobileSheetAnchor/SheetOverlay
@onready var _canvas_wrapper: Control = $RootMargin/RootStack/MainStack/CanvasWrapper
@onready var _canvas_panel: Control = $RootMargin/RootStack/MainStack/CanvasWrapper/CanvasPanel
@onready var _canvas_info: Label = $RootMargin/RootStack/MainStack/CanvasWrapper/CanvasPanel/CanvasInfo
@onready var _canvas_message: Label = $RootMargin/RootStack/MainStack/CanvasWrapper/CanvasPanel/CanvasMessage
@onready var _canvas_placeholder: ColorRect = $RootMargin/RootStack/MainStack/CanvasWrapper/CanvasPanel/CanvasPlaceholder
@onready var _feed_button: Button = $RootMargin/RootStack/BottomBar/TabBar/FeedButton
@onready var _environment_wrapper: Control = $RootMargin/RootStack/MainStack/EnvironmentWrapper
@onready var _environment_panel: Control = $RootMargin/RootStack/MainStack/EnvironmentWrapper/EnvironmentPanel
@onready var _mobile_sheet_anchor: Control = $RootMargin/RootStack/MainStack/CanvasWrapper/MobileSheetAnchor
@onready var _desktop_sheet_anchor: Control = $RootMargin/RootStack/MainStack/EnvironmentWrapper/DesktopSheetAnchor

@onready var _home_soft_label: Label = $RootMargin/RootStack/MainStack/CanvasWrapper/MobileSheetAnchor/SheetOverlay/HomeSheet/HomeMargin/HomeColumn/HomeSummaryRow/HomeSoftLabel
@onready var _home_storage_label: Label = $RootMargin/RootStack/MainStack/CanvasWrapper/MobileSheetAnchor/SheetOverlay/HomeSheet/HomeMargin/HomeColumn/HomeSummaryRow/HomeStorageLabel
@onready var _home_stage_label: Label = $RootMargin/RootStack/MainStack/CanvasWrapper/MobileSheetAnchor/SheetOverlay/HomeSheet/HomeMargin/HomeColumn/HomeStageLabel
@onready var _home_prestige_label: Label = $RootMargin/RootStack/MainStack/CanvasWrapper/MobileSheetAnchor/SheetOverlay/HomeSheet/HomeMargin/HomeColumn/HomePrestigeLabel
@onready var _home_feed_status_label: Label = $RootMargin/RootStack/MainStack/CanvasWrapper/MobileSheetAnchor/SheetOverlay/HomeSheet/HomeMargin/HomeColumn/HomeFeedStatusLabel
@onready var _home_feed_bar: ProgressBar = $RootMargin/RootStack/MainStack/CanvasWrapper/MobileSheetAnchor/SheetOverlay/HomeSheet/HomeMargin/HomeColumn/HomeFeedBar
@onready var _home_feed_hint_label: Label = $RootMargin/RootStack/MainStack/CanvasWrapper/MobileSheetAnchor/SheetOverlay/HomeSheet/HomeMargin/HomeColumn/HomeFeedHintLabel
@onready var _home_feed_queue_label: Label = $RootMargin/RootStack/MainStack/CanvasWrapper/MobileSheetAnchor/SheetOverlay/HomeSheet/HomeMargin/HomeColumn/HomeFeedQueueLabel
@onready var _home_feed_button: Button = $RootMargin/RootStack/MainStack/CanvasWrapper/MobileSheetAnchor/SheetOverlay/HomeSheet/HomeMargin/HomeColumn/HomeFeedButton
@onready var _home_promote_button: Button = $RootMargin/RootStack/MainStack/CanvasWrapper/MobileSheetAnchor/SheetOverlay/HomeSheet/HomeMargin/HomeColumn/HomePromoteButton
@onready var _home_copy_button: Button = $RootMargin/RootStack/MainStack/CanvasWrapper/MobileSheetAnchor/SheetOverlay/HomeSheet/HomeMargin/HomeColumn/HomeUtilityRow/HomeCopyButton
@onready var _home_paste_button: Button = $RootMargin/RootStack/MainStack/CanvasWrapper/MobileSheetAnchor/SheetOverlay/HomeSheet/HomeMargin/HomeColumn/HomeUtilityRow/HomePasteButton
@onready var _home_settings_button: Button = $RootMargin/RootStack/MainStack/CanvasWrapper/MobileSheetAnchor/SheetOverlay/HomeSheet/HomeMargin/HomeColumn/HomeUtilityRow/HomeSettingsButton
@onready var _factory_viewport_container: Control = $RootMargin/RootStack/MainStack/CanvasWrapper/CanvasPanel/FactoryViewportContainer
@onready var _factory_viewport: SubViewport = $RootMargin/RootStack/MainStack/CanvasWrapper/CanvasPanel/FactoryViewportContainer/FactoryViewport

@onready var _tokens = UI_TOKENS_RESOURCE
@onready var _top_banner_panel: PanelContainer = $RootMargin/RootStack/TopBanner
@onready var _top_banner_component: TopBanner = $RootMargin/RootStack/TopBanner/TopBanner as TopBanner
@onready var _bottom_tab_buttons_by_id: Dictionary = {
	&"home": $RootMargin/RootStack/BottomBar/TabBar/HomeButton as Button,
	&"store": $RootMargin/RootStack/BottomBar/TabBar/StoreButton as Button,
	&"research": $RootMargin/RootStack/BottomBar/TabBar/ResearchButton as Button,
	&"automation": $RootMargin/RootStack/BottomBar/TabBar/AutomationButton as Button,
	&"prestige": $RootMargin/RootStack/BottomBar/TabBar/PrestigeButton as Button
}

@onready var _store_buttons: Dictionary = {
	"prod_1": $RootMargin/RootStack/MainStack/CanvasWrapper/MobileSheetAnchor/SheetOverlay/StoreSheet/StoreMargin/StoreColumn/StoreProdButton,
	"cap_1": $RootMargin/RootStack/MainStack/CanvasWrapper/MobileSheetAnchor/SheetOverlay/StoreSheet/StoreMargin/StoreColumn/StoreCapButton,
	"auto_1": $RootMargin/RootStack/MainStack/CanvasWrapper/MobileSheetAnchor/SheetOverlay/StoreSheet/StoreMargin/StoreColumn/StoreAutoButton
}
@onready var _research_title_label: Label = $RootMargin/RootStack/MainStack/CanvasWrapper/MobileSheetAnchor/SheetOverlay/ResearchSheet/ResearchMargin/ResearchColumn/ResearchTitle
@onready var _research_summary_label: Label = $RootMargin/RootStack/MainStack/CanvasWrapper/MobileSheetAnchor/SheetOverlay/ResearchSheet/ResearchMargin/ResearchColumn/ResearchSummaryLabel
@onready var _research_buttons: Dictionary = {
	"r_prod_1": $RootMargin/RootStack/MainStack/CanvasWrapper/MobileSheetAnchor/SheetOverlay/ResearchSheet/ResearchMargin/ResearchColumn/ResearchProdButton,
	"r_cap_1": $RootMargin/RootStack/MainStack/CanvasWrapper/MobileSheetAnchor/SheetOverlay/ResearchSheet/ResearchMargin/ResearchColumn/ResearchCapButton,
	"r_auto_1": $RootMargin/RootStack/MainStack/CanvasWrapper/MobileSheetAnchor/SheetOverlay/ResearchSheet/ResearchMargin/ResearchColumn/ResearchAutoButton
}
@onready var _automation_info_label: Label = $RootMargin/RootStack/MainStack/CanvasWrapper/MobileSheetAnchor/SheetOverlay/AutomationSheet/AutomationMargin/AutomationColumn/AutomationInfoLabel
@onready var _automation_title_label: Label = $RootMargin/RootStack/MainStack/CanvasWrapper/MobileSheetAnchor/SheetOverlay/AutomationSheet/AutomationMargin/AutomationColumn/AutomationTitle
@onready var _automation_buttons: Dictionary = {
	"auto_1": $RootMargin/RootStack/MainStack/CanvasWrapper/MobileSheetAnchor/SheetOverlay/AutomationSheet/AutomationMargin/AutomationColumn/AutomationAutoButton
}
@onready var _prestige_status_label: Label = $RootMargin/RootStack/MainStack/CanvasWrapper/MobileSheetAnchor/SheetOverlay/PrestigeSheet/PrestigeMargin/PrestigeColumn/PrestigeStatusLabel
@onready var _prestige_button: Button = $RootMargin/RootStack/MainStack/CanvasWrapper/MobileSheetAnchor/SheetOverlay/PrestigeSheet/PrestigeMargin/PrestigeColumn/PrestigeButton

var _banner_content: HBoxContainer
var _banner_metric_title_labels: Array[Label] = []
var _banner_metric_columns: Array[VBoxContainer] = []
var _alert_pill: Label
var _metric_labels: Dictionary = {}
var _tab_buttons: Array[BaseButton] = []
var _dock_buttons: Array[BaseButton] = []
var _sheets: Array[Control] = []
var _current_root_margin: float = 24.0
var _current_column_separation: float = 12.0
var _factory_design_width: float = 960.0
var _factory_design_height: float = 720.0
var _focus_map: FocusMap
var _focus_nodes: Dictionary = {}
var _current_sheet_focus_ids: Array[StringName] = []
var _current_sheet_primary_id: StringName = StringName()
var _focus_current_id: StringName = StringName()

func _ready() -> void:
	_register_tab_buttons()
	_register_sheets()
	if _factory_viewport_container is SubViewportContainer:
		var container := _factory_viewport_container as SubViewportContainer
		container.stretch = false
	if _canvas_wrapper:
		_canvas_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_feed_button.pressed.connect(_on_feed_pressed)
	_feed_button.button_down.connect(_on_feed_hold_button_down)
	_feed_button.button_up.connect(_on_feed_hold_button_up)
	_home_feed_button.button_down.connect(_on_feed_hold_button_down)
	_home_feed_button.button_up.connect(_on_feed_hold_button_up)
	_home_promote_button.pressed.connect(func(): promote_requested.emit())
	_home_copy_button.pressed.connect(func(): save_export_requested.emit())
	_home_paste_button.pressed.connect(func(): save_import_requested.emit())
	_home_settings_button.pressed.connect(func(): settings_requested.emit())
	for id in _store_buttons.keys():
		var button := _store_buttons[id] as Button
		if button:
			button.pressed.connect(_on_upgrade_button_pressed.bind(id))
	for id in _research_buttons.keys():
		var r_button := _research_buttons[id] as Button
		if r_button:
			r_button.pressed.connect(_on_research_button_pressed.bind(id))
	for id in _automation_buttons.keys():
		var a_button := _automation_buttons[id] as Button
		if a_button:
			a_button.pressed.connect(_on_upgrade_button_pressed.bind(id))
			a_button.pressed.connect(_on_automation_button_pressed.bind(id))
	_prestige_button.pressed.connect(func(): prestige_requested.emit())
	resized.connect(_update_layout)
	_initialize_banner_references()
	_apply_ui_tokens()
	if _canvas_panel and not _canvas_panel.resized.is_connected(_sync_factory_viewport_size):
		_canvas_panel.resized.connect(_sync_factory_viewport_size)
	_home_feed_default_text = _home_feed_button.text
	set_metrics(_metrics)
	set_status(_status)
	_sync_factory_viewport_size()
	_update_layout()
	_setup_focus_modes()
	_initialize_focus_map()
	_show_tab(_current_tab)
	_apply_automation_copy()

func _initialize_banner_references() -> void:
	_banner_content = null
	_alert_pill = null
	_banner_metric_title_labels.clear()
	_banner_metric_columns.clear()
	_metric_labels.clear()
	if _top_banner_component:
		_banner_content = _top_banner_component.content_container()
		_banner_metric_columns = _top_banner_component.metric_columns()
		_banner_metric_title_labels = _top_banner_component.metric_title_labels()
		_metric_labels = _top_banner_component.metric_labels()
		_alert_pill = _top_banner_component.get_alert_label()
	else:
		var legacy_content := _top_banner_panel.get_node_or_null("BannerContent") as HBoxContainer
		if legacy_content:
			_banner_content = legacy_content
			var legacy_columns: Array[VBoxContainer] = []
			for segment in ["CreditsBox", "StorageBox", "PpsBox", "ResearchBox"]:
				var column := legacy_content.get_node_or_null(segment) as VBoxContainer
				if column:
					legacy_columns.append(column)
			_banner_metric_columns = legacy_columns
			var title_labels: Array[Label] = []
			var metric_map: Dictionary = {}
			var mappings := {
				&"credits": "CreditsBox/CreditsValue",
				&"storage": "StorageBox/StorageValue",
				&"pps": "PpsBox/PpsValue",
				&"research": "ResearchBox/ResearchValue"
			}
			for key in mappings.keys():
				var label_path := String(mappings[key])
				var value_label := legacy_content.get_node_or_null(label_path) as Label
				if value_label:
					metric_map[key] = value_label
					var title_path := label_path.replace("Value", "Label")
					var title_label := legacy_content.get_node_or_null(title_path) as Label
					if title_label and not title_labels.has(title_label):
						title_labels.append(title_label)
			_banner_metric_title_labels = title_labels
			_metric_labels = metric_map
			_alert_pill = legacy_content.get_node_or_null("AlertPill") as Label
	if _banner_metric_columns.is_empty() and _top_banner_component:
		_banner_metric_columns = _top_banner_component.metric_columns()
	if _banner_metric_title_labels.is_empty() and _top_banner_component:
		_banner_metric_title_labels = _top_banner_component.metric_title_labels()
	if _metric_labels.is_empty() and _top_banner_component:
		_metric_labels = _top_banner_component.metric_labels()
	if _alert_pill == null and _top_banner_component:
		_alert_pill = _top_banner_component.get_alert_label()
	if _banner_content == null and _top_banner_component:
		_banner_content = _top_banner_component.content_container()

func set_metrics(metrics: Dictionary) -> void:
	for key in _metrics.keys():
		if metrics.has(key):
			var value := String(metrics[key])
			_metrics[key] = value
			var metric_key := StringName(key)
			if _top_banner_component:
				_top_banner_component.set_metric(metric_key, value)
			else:
				var label := _metric_labels.get(metric_key, null) as Label
				if label:
					label.text = value
					label.tooltip_text = value

func set_status(status: Dictionary) -> void:
	for key in _status.keys():
		if status.has(key):
			var status_key := StringName(key)
			var entry_variant: Variant = status[key]
			var entry_dict: Dictionary
			if entry_variant is Dictionary:
				entry_dict = (entry_variant as Dictionary).duplicate(true)
			else:
				entry_dict = {"value": String(entry_variant), "tone": StringName("normal")}
			var tone_variant: Variant = entry_dict.get("tone", StringName("normal"))
			entry_dict["tone"] = StringName(tone_variant)
			_status[status_key] = entry_dict
	if _top_banner_component:
		_top_banner_component.set_status(_status)
	else:
		for key in _status.keys():
			var row: Dictionary = _status_rows.get(key, {})
			var entry: Dictionary = _status[key]
			var value_label := row.get("value", null) as Label
			if value_label:
				var display_value := String(entry.get("value", value_label.text))
				value_label.text = display_value
				var tooltip_text := String(entry.get("tooltip", display_value))
				value_label.tooltip_text = tooltip_text

func set_alert_message(message: String) -> void:
	if _top_banner_component:
		_top_banner_component.set_alert(message)
	elif _alert_pill:
		_alert_pill.text = message
		_alert_pill.tooltip_text = message

func set_canvas_hint(hint: String) -> void:
	_custom_canvas_hint = hint
	_apply_canvas_hint()

func set_canvas_message(message: String) -> void:
	_custom_canvas_message = message
	if not _canvas_message:
		return
	if _custom_canvas_message == "":
		_canvas_message.text = ""
		_canvas_message.tooltip_text = ""
		_canvas_message.visible = false
	else:
		_canvas_message.text = _custom_canvas_message
		_canvas_message.tooltip_text = _custom_canvas_message
	_refresh_canvas_message_visibility()

func _apply_ui_tokens() -> void:
	if _tokens == null:
		return
	_apply_banner_tokens()
	_apply_bottom_bar_tokens()
	_apply_label_overflow_defaults()


func _apply_banner_tokens() -> void:
	if _tokens == null:
		return
	if _top_banner_panel:
		var banner_style := StyleBoxFlat.new()
		banner_style.bg_color = _token_colour(&"banner_bg")
		var corner_radius := int(round(_token_radius(&"corner_md")))
		banner_style.corner_radius_top_left = corner_radius
		banner_style.corner_radius_top_right = corner_radius
		banner_style.corner_radius_bottom_left = corner_radius
		banner_style.corner_radius_bottom_right = corner_radius
		banner_style.content_margin_left = int(round(_token_spacing(&"space_lg")))
		banner_style.content_margin_right = int(round(_token_spacing(&"space_lg")))
		banner_style.content_margin_top = int(round(_token_spacing(&"space_md")))
		banner_style.content_margin_bottom = int(round(_token_spacing(&"space_md")))
		_top_banner_panel.add_theme_stylebox_override("panel", banner_style)
	if _banner_content:
		_banner_content.add_theme_constant_override("separation", int(round(_token_spacing(&"space_lg"))))
	for column in _banner_metric_columns:
		if column:
			column.add_theme_constant_override("separation", int(round(_token_spacing(&"space_xs"))))
	for title_label in _banner_metric_title_labels:
		if title_label:
			_apply_label_tokens(title_label, &"font_s", &"text_muted")
			_ensure_label_overflow(title_label, false)
	for metric_label_value in _metric_labels.values():
		var metric_label: Label = metric_label_value
		if metric_label:
			_apply_label_tokens(metric_label, &"font_l", &"banner_text")
			_ensure_label_overflow(metric_label, false)
	if _alert_pill:
		_apply_label_tokens(_alert_pill, &"font_m", &"banner_alert")
		_ensure_label_overflow(_alert_pill, false)

func _apply_bottom_bar_tokens() -> void:
	if _tokens == null:
		return
	if _bottom_bar:
		var horizontal: float = _token_spacing(&"space_md")
		var top_margin: float = _token_spacing(&"space_md")
		_set_margin(_bottom_bar, horizontal, top_margin, horizontal, 0.0)
	if _bottom_tab_container:
		_bottom_tab_container.add_theme_constant_override("separation", int(round(_token_spacing(&"space_md"))))
	for button_value in _bottom_tab_buttons_by_id.values():
		var tab_button: Button = button_value
		if tab_button:
			_style_tab_button(tab_button, false)
	if _feed_button:
		_style_tab_button(_feed_button, true)

func _style_tab_button(button: Button, is_primary: bool) -> void:
	if button == null or _tokens == null:
		return
	var background_token := &"button_primary" if is_primary else &"button_secondary"
	var text_token := &"button_primary_text" if is_primary else &"button_secondary_text"
	var base_color: Color = _token_colour(background_token)
	var text_color: Color = _token_colour(text_token)
	var hover_color: Color = base_color.lightened(0.08)
	var pressed_color: Color = base_color.darkened(0.12)
	var disabled_color: Color = base_color.darkened(0.35)
	var focus_border: Color = _token_colour(&"focus_outline")
	_set_fill_expand(button, true, false)
	button.focus_mode = Control.FOCUS_ALL
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var font_size: int = _token_font_size(&"font_m")
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_focus_color", text_color)
	button.add_theme_color_override("font_disabled_color", text_color.darkened(0.25))
	button.add_theme_stylebox_override("normal", _create_button_stylebox(base_color))
	button.add_theme_stylebox_override("hover", _create_button_stylebox(hover_color))
	button.add_theme_stylebox_override("pressed", _create_button_stylebox(pressed_color))
	button.add_theme_stylebox_override("disabled", _create_button_stylebox(disabled_color))
	button.add_theme_stylebox_override("focus", _create_button_stylebox(base_color, focus_border, 2))

func _create_button_stylebox(base_color: Color, border_color: Color = Color.TRANSPARENT, border_width: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = base_color
	style.border_color = border_color
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	var corner_radius := int(round(_token_radius(&"corner_md")))
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	var horizontal_margin := int(round(_token_spacing(&"space_md")))
	var vertical_margin := int(round(_token_spacing(&"space_sm")))
	style.content_margin_left = horizontal_margin
	style.content_margin_right = horizontal_margin
	style.content_margin_top = vertical_margin
	style.content_margin_bottom = vertical_margin
	return style

func _apply_label_tokens(label: Label, size_token: StringName, colour_token: StringName) -> void:
	if label == null or _tokens == null:
		return
	label.add_theme_color_override("font_color", _token_colour(colour_token))
	label.add_theme_font_size_override("font_size", _token_font_size(size_token))

func _ensure_label_overflow(label: Label, allow_wrap: bool, max_lines: int = 1) -> void:
	if label == null:
		return
	if allow_wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.max_lines_visible = max_lines
		label.visible_characters = -1
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	else:
		label.clip_text = true
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

func _set_fill_expand(control: Control, horizontal: bool = true, vertical: bool = false) -> void:
	if control == null:
		return
	var horizontal_flag: int = Control.SIZE_FILL | Control.SIZE_EXPAND if horizontal else Control.SIZE_FILL
	var vertical_flag: int = Control.SIZE_FILL | Control.SIZE_EXPAND if vertical else Control.SIZE_FILL
	control.size_flags_horizontal = horizontal_flag
	control.size_flags_vertical = vertical_flag

func _apply_label_overflow_defaults() -> void:
	var queue: Array[Node] = []
	queue.append(self)
	while not queue.is_empty():
		var node: Node = queue.pop_back()
		if node is Label:
			var label: Label = node
			var allow_wrap: bool = label.autowrap_mode != TextServer.AUTOWRAP_OFF
			_ensure_label_overflow(label, allow_wrap)
		for child in node.get_children():
			queue.append(child)

func _token_colour(token: StringName) -> Color:
	var colour_value: Color = Color.WHITE
	if _tokens != null and _tokens.has_method("colour"):
		var result: Variant = _tokens.call("colour", token)
		if result is Color:
			colour_value = result
	return colour_value

func _token_font_size(token: StringName) -> int:
	var size_value: int = 15
	if _tokens != null and _tokens.has_method("font_size"):
		var result: Variant = _tokens.call("font_size", token)
		if result is int:
			size_value = result
		elif result is float:
			size_value = int(round(result))
	return size_value

func _token_spacing(token: StringName) -> float:
	var spacing_value: float = 12.0
	if _tokens != null and _tokens.has_method("spacing_value"):
		var result: Variant = _tokens.call("spacing_value", token)
		if result is float:
			spacing_value = result
		elif result is int:
			spacing_value = float(result)
	return spacing_value

func _token_radius(token: StringName) -> float:
	var radius_value: float = 6.0
	if _tokens != null and _tokens.has_method("radius"):
		var result: Variant = _tokens.call("radius", token)
		if result is float:
			radius_value = result
		elif result is int:
			radius_value = float(result)
	return radius_value

func update_home(data: Dictionary) -> void:
	if data.has("soft"):
		_home_soft_label.text = String(data["soft"])
	if data.has("storage"):
		_home_storage_label.text = String(data["storage"])
	if data.has("stage"):
		_home_stage_label.text = String(data["stage"])
	if data.has("prestige"):
		_home_prestige_label.text = String(data["prestige"])
	if data.has("feed_status"):
		var status = String(data["feed_status"])
		_home_feed_status_label.text = status
		_home_feed_status_label.tooltip_text = status
	if data.has("feed_hint"):
		var hint: String = String(data["feed_hint"])
		var has_hint: bool = not hint.is_empty()
		if has_hint:
			_home_feed_hint_label.text = hint
			_home_feed_hint_label.tooltip_text = hint
			_home_feed_hint_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		else:
			_home_feed_hint_label.text = " "
			_home_feed_hint_label.tooltip_text = ""
			_home_feed_hint_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	if data.has("feed_fraction"):
		var fraction = clamp(float(data.get("feed_fraction", 0.0)), 0.0, 1.0)
		_home_feed_bar.max_value = 1.0
		_home_feed_bar.value = fraction
	if data.has("feed_style"):
		var style = data.get("feed_style")
		if style is StyleBox:
			var copy = (style as StyleBox).duplicate(true)
			_home_feed_bar.add_theme_stylebox_override("fill", copy)
	if data.has("queue"):
		var queue: int = int(data["queue"])
		if queue > 0:
			var queue_text := "Queue: %d" % queue
			_home_feed_queue_label.text = queue_text
			_home_feed_queue_label.tooltip_text = queue_text
			_home_feed_queue_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		else:
			_home_feed_queue_label.text = " "
			_home_feed_queue_label.tooltip_text = ""
			_home_feed_queue_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	if data.has("feed_button"):
		var feed_state = data.get("feed_button")
		if feed_state is Dictionary:
			_apply_button_state(_home_feed_button, feed_state)
			_home_feed_default_text = _home_feed_button.text
	if data.has("promote_button"):
		var promote_state = data.get("promote_button")
		if promote_state is Dictionary:
			_apply_button_state(_home_promote_button, promote_state)
	if data.has("utilities"):
		var utility_state = data.get("utilities")
		if utility_state is Dictionary:
			_apply_button_state(_home_copy_button, utility_state.get("export", {}))
			_apply_button_state(_home_paste_button, utility_state.get("import", {}))
			_apply_button_state(_home_settings_button, utility_state.get("settings", {}))
	_update_feed_button_label()

func update_store(buttons: Dictionary) -> void:
	for id in _store_buttons.keys():
		var button = _store_buttons[id] as Button
		if button:
			var state = buttons.get(id, {})
			_apply_button_state(button, state)

func update_research(data: Dictionary) -> void:
	if data.has("title"):
		_research_title_label.text = String(data["title"])
	if data.has("summary"):
		_research_summary_label.text = String(data["summary"])
	if data.has("buttons"):
		var states = data.get("buttons")
		if states is Dictionary:
			for id in _research_buttons.keys():
				var button = _research_buttons[id] as Button
				if button:
					_apply_button_state(button, states.get(id, {}))

func update_automation(data: Dictionary) -> void:
	if data.has("info"):
		_automation_info_label.text = String(data["info"])
	if data.has("buttons"):
		var states = data.get("buttons")
		if states is Dictionary:
			for id in _automation_buttons.keys():
				var button = _automation_buttons[id] as Button
				if button:
					_apply_button_state(button, states.get(id, {}))

func update_prestige(data: Dictionary) -> void:
	if data.has("status"):
		_prestige_status_label.text = String(data["status"])
	if data.has("button"):
		var state = data.get("button")
		if state is Dictionary:
			_apply_button_state(_prestige_button, state)

func set_feed_queue(count: int) -> void:
	_feed_queue_count = max(count, 0)
	_update_feed_button_label()
	if _home_feed_queue_label == null:
		return
	if _feed_queue_count > 0:
		var queue_text := "Queue: %d" % _feed_queue_count
		_home_feed_queue_label.text = queue_text
		_home_feed_queue_label.tooltip_text = queue_text
		_home_feed_queue_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		_home_feed_queue_label.text = " "
		_home_feed_queue_label.tooltip_text = ""
		_home_feed_queue_label.modulate = Color(1.0, 1.0, 1.0, 0.0)

func set_feed_status(status_text: String, fraction: float, active: bool) -> void:
	_feed_active = active
	set_alert_message(status_text)
	_canvas_panel.tooltip_text = status_text
	_feed_button.tooltip_text = status_text
	_home_feed_button.tooltip_text = status_text
	_home_feed_status_label.text = status_text
	_home_feed_status_label.tooltip_text = status_text
	_home_feed_bar.value = clamp(fraction, 0.0, 1.0)
	_update_feed_button_label()

func show_tab(tab_id: String) -> void:
	_show_tab(tab_id)

func get_action_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	for candidate in [
		_home_feed_button,
		_home_promote_button,
		_home_copy_button,
		_home_paste_button,
		_home_settings_button,
		_prestige_button,
		_feed_button
	]:
		if candidate:
			buttons.append(candidate)
	for value in _store_buttons.values():
		if value is Button:
			buttons.append(value)
	for value in _research_buttons.values():
		if value is Button:
			buttons.append(value)
	for value in _automation_buttons.values():
		if value is Button:
			buttons.append(value)
	return buttons

func get_current_tab() -> String:
	return _current_tab

func get_environment_panel() -> Control:
	return _environment_panel

func get_factory_viewport() -> SubViewport:
	return _factory_viewport

func get_factory_viewport_container() -> Control:
	return _factory_viewport_container

func mark_canvas_ready() -> void:
	if _canvas_placeholder:
		_canvas_placeholder.visible = false
	if _canvas_info:
		_canvas_info.visible = false
	if _canvas_message and _custom_canvas_message == "":
		_canvas_message.visible = false

func get_canvas_rect() -> Rect2:
	if _canvas_panel:
		return _canvas_panel.get_global_rect()
	return Rect2()

func is_desktop_layout() -> bool:
	return _is_desktop_layout

func _move_sheet_to_anchor(anchor: Control) -> void:
	if anchor == null or _sheet_overlay == null:
		return
	if _sheet_overlay.get_parent() != anchor:
		var previous := _sheet_overlay.get_parent()
		if previous:
			previous.remove_child(_sheet_overlay)
		anchor.add_child(_sheet_overlay)
		anchor.move_child(_sheet_overlay, anchor.get_child_count() - 1)
	_sheet_overlay.anchor_left = 0.0
	_sheet_overlay.anchor_right = 1.0
	_sheet_overlay.anchor_top = 0.0
	_sheet_overlay.anchor_bottom = 1.0
	_sheet_overlay.offset_left = 0.0
	_sheet_overlay.offset_right = 0.0
	_sheet_overlay.offset_top = 0.0
	_sheet_overlay.offset_bottom = 0.0
	_sheet_overlay.size_flags_horizontal = 3
	_sheet_overlay.size_flags_vertical = 3

func _setup_focus_modes() -> void:
	for button in get_action_buttons():
		button.focus_mode = Control.FOCUS_ALL
	for button in _tab_buttons:
		button.focus_mode = Control.FOCUS_ALL
	for button in _dock_buttons:
		button.focus_mode = Control.FOCUS_ALL
	if _feed_button:
		_feed_button.focus_mode = Control.FOCUS_ALL
	if _canvas_panel:
		_canvas_panel.focus_mode = Control.FOCUS_ALL

func _initialize_focus_map() -> void:
	if _focus_map == null:
		_focus_map = FocusMap.new()
		_focus_map.name = "FocusMap"
		add_child(_focus_map)
	if not layout_changed.is_connected(_on_layout_changed_for_focus):
		layout_changed.connect(_on_layout_changed_for_focus)

func _register_focus_node(id: StringName, control: Control) -> StringName:
	if _focus_map == null or control == null:
		return StringName()
	if not control.is_inside_tree() or not control.is_visible_in_tree():
		return StringName()
	if control is BaseButton and (control as BaseButton).disabled:
		return StringName()
	control.focus_mode = Control.FOCUS_ALL
	control.set_meta("focus_id", id)
	if not control.focus_entered.is_connected(_on_focus_target_focused):
		control.focus_entered.connect(_on_focus_target_focused.bind(id))
	_focus_nodes[id] = control
	_focus_map.register_node(id, control)
	return id

func _focus_id_for_control(control: Control) -> StringName:
	if control == null:
		return StringName()
	if not control.has_meta("focus_id"):
		return StringName()
	var meta: Variant = control.get_meta("focus_id")
	return meta if meta is StringName else StringName()

func _owns_control(control: Control) -> bool:
	return control != null and control.is_inside_tree() and is_ancestor_of(control)

func _on_focus_target_focused(id: StringName) -> void:
	_focus_current_id = id

func _on_layout_changed_for_focus() -> void:
	_rebuild_focus_graph()
	if _focus_current_id == StringName():
		_focus_default_for_tab(_current_tab)

func _rebuild_focus_graph(preserve_focus: bool = true) -> void:
	if _focus_map == null:
		return
	var previous_id: StringName = _focus_current_id if preserve_focus else StringName()
	_focus_map.clear()
	_focus_nodes.clear()
	_current_sheet_focus_ids.clear()
	_current_sheet_primary_id = StringName()
	var tab_focus_ids: Dictionary = {}
	var tab_order: Array[StringName] = []
	if _is_desktop_layout:
		tab_order = _register_dock_focus(tab_focus_ids)
	else:
		tab_order = _register_bottom_focus(tab_focus_ids)
	var sheet_ids: Array[StringName] = _register_sheet_focus(tab_focus_ids)
	var canvas_id: StringName = _register_canvas_focus(sheet_ids)
	if _is_desktop_layout:
		_link_vertical(tab_order)
	else:
		_link_horizontal(tab_order, true)
	_link_vertical(sheet_ids)
	_current_sheet_focus_ids = sheet_ids
	if preserve_focus and previous_id != StringName() and _focus_nodes.has(previous_id):
		_focus_map.focus(previous_id)
		return
	if not preserve_focus:
		_focus_current_id = StringName()

func _register_bottom_focus(tab_focus_ids: Dictionary) -> Array[StringName]:
	var order: Array[StringName] = []
	var home_button_variant: Variant = _bottom_tab_buttons_by_id.get(&"home")
	var home_id: StringName = _register_tab_focus_button("home", home_button_variant)
	if home_id != StringName():
		tab_focus_ids[StringName("home")] = home_id
		order.append(home_id)
	var store_button_variant: Variant = _bottom_tab_buttons_by_id.get(&"store")
	var store_id: StringName = _register_tab_focus_button("store", store_button_variant)
	if store_id != StringName():
		tab_focus_ids[StringName("store")] = store_id
		order.append(store_id)
	var feed_id: StringName = _register_focus_node(StringName("tab_feed"), _feed_button)
	if feed_id != StringName():
		order.append(feed_id)
	var research_button_variant: Variant = _bottom_tab_buttons_by_id.get(&"research")
	var research_id: StringName = _register_tab_focus_button("research", research_button_variant)
	if research_id != StringName():
		tab_focus_ids[StringName("research")] = research_id
		order.append(research_id)
	var automation_button_variant: Variant = _bottom_tab_buttons_by_id.get(&"automation")
	var automation_id: StringName = _register_tab_focus_button("automation", automation_button_variant)
	if automation_id != StringName():
		tab_focus_ids[StringName("automation")] = automation_id
		order.append(automation_id)
	var prestige_button_variant: Variant = _bottom_tab_buttons_by_id.get(&"prestige")
	var prestige_id: StringName = _register_tab_focus_button("prestige", prestige_button_variant)
	if prestige_id != StringName():
		tab_focus_ids[StringName("prestige")] = prestige_id
		order.append(prestige_id)
	return order

func _register_tab_focus_button(tab_id: String, button_variant: Variant) -> StringName:
	if button_variant is BaseButton:
		return _register_focus_node(StringName("tab_%s" % tab_id), button_variant as BaseButton)
	return StringName()

func _register_dock_focus(tab_focus_ids: Dictionary) -> Array[StringName]:
	var order: Array[StringName] = []
	for button in _dock_buttons:
		if button == null or not button.visible:
			continue
		var tab_id: String = _button_tab_id(button)
		var focus_id: StringName = _register_focus_node(StringName("tab_%s" % tab_id), button)
		if focus_id != StringName():
			tab_focus_ids[StringName(tab_id)] = focus_id
			order.append(focus_id)
	return order

func _register_sheet_focus(tab_focus_ids: Dictionary) -> Array[StringName]:
	var sheet_ids: Array[StringName] = []
	match _current_tab:
		"home":
			sheet_ids = _register_home_sheet_focus()
		"store":
			sheet_ids = _register_store_sheet_focus()
		"research":
			sheet_ids = _register_research_sheet_focus()
		"automation":
			sheet_ids = _register_automation_sheet_focus()
		"prestige":
			sheet_ids = _register_prestige_sheet_focus()
		_:
			sheet_ids = []
	if sheet_ids.is_empty():
		return sheet_ids
	_current_sheet_primary_id = sheet_ids[0]
	var tab_key := StringName(_current_tab)
	if tab_focus_ids.has(tab_key):
		var tab_focus_id: StringName = tab_focus_ids[tab_key]
		_focus_map.set_neighbour(tab_focus_id, FOCUS_DOWN, sheet_ids[0])
		_focus_map.set_neighbour(sheet_ids[0], FOCUS_UP, tab_focus_id)
	if _current_tab == "home" and _focus_nodes.has(StringName("tab_feed")):
		_focus_map.set_neighbour(StringName("tab_feed"), FOCUS_UP, sheet_ids[0])
	return sheet_ids

func _register_home_sheet_focus() -> Array[StringName]:
	var vertical_ids: Array[StringName] = []
	var util_ids: Array[StringName] = []
	var feed_id: StringName = _register_focus_node(StringName("sheet_home_feed"), _home_feed_button)
	if feed_id != StringName():
		vertical_ids.append(feed_id)
	var promote_id: StringName = _register_focus_node(StringName("sheet_home_promote"), _home_promote_button)
	if promote_id != StringName():
		vertical_ids.append(promote_id)
	var copy_id: StringName = _register_focus_node(StringName("sheet_home_copy"), _home_copy_button)
	if copy_id != StringName():
		vertical_ids.append(copy_id)
		util_ids.append(copy_id)
	var paste_id: StringName = _register_focus_node(StringName("sheet_home_paste"), _home_paste_button)
	if paste_id != StringName():
		util_ids.append(paste_id)
	var settings_id: StringName = _register_focus_node(StringName("sheet_home_settings"), _home_settings_button)
	if settings_id != StringName():
		util_ids.append(settings_id)
	_link_vertical(vertical_ids)
	if util_ids.size() > 1:
		_link_row(util_ids)
	if promote_id != StringName():
		for util_id in util_ids:
			_focus_map.set_neighbour(util_id, FOCUS_UP, promote_id)
	var ids: Array[StringName] = []
	for id in vertical_ids:
		if id != StringName() and not ids.has(id):
			ids.append(id)
	for util_id in util_ids:
		if util_id != StringName() and not ids.has(util_id):
			ids.append(util_id)
	return ids

func _register_store_sheet_focus() -> Array[StringName]:
	var ids: Array[StringName] = []
	var prod_button: Variant = _store_buttons.get("prod_1")
	if prod_button is Button:
		var focus_id: StringName = _register_focus_node(StringName("sheet_store_prod"), prod_button as Button)
		if focus_id != StringName():
			ids.append(focus_id)
	var cap_button: Variant = _store_buttons.get("cap_1")
	if cap_button is Button:
		var focus_id: StringName = _register_focus_node(StringName("sheet_store_cap"), cap_button as Button)
		if focus_id != StringName():
			ids.append(focus_id)
	var auto_button: Variant = _store_buttons.get("auto_1")
	if auto_button is Button:
		var focus_id: StringName = _register_focus_node(StringName("sheet_store_auto"), auto_button as Button)
		if focus_id != StringName():
			ids.append(focus_id)
	_link_vertical(ids)
	return ids

func _register_research_sheet_focus() -> Array[StringName]:
	var ids: Array[StringName] = []
	var prod_button: Variant = _research_buttons.get("r_prod_1")
	if prod_button is Button:
		var focus_id: StringName = _register_focus_node(StringName("sheet_research_prod"), prod_button as Button)
		if focus_id != StringName():
			ids.append(focus_id)
	var cap_button: Variant = _research_buttons.get("r_cap_1")
	if cap_button is Button:
		var focus_id: StringName = _register_focus_node(StringName("sheet_research_cap"), cap_button as Button)
		if focus_id != StringName():
			ids.append(focus_id)
	var auto_button: Variant = _research_buttons.get("r_auto_1")
	if auto_button is Button:
		var focus_id: StringName = _register_focus_node(StringName("sheet_research_auto"), auto_button as Button)
		if focus_id != StringName():
			ids.append(focus_id)
	_link_vertical(ids)
	return ids

func _register_automation_sheet_focus() -> Array[StringName]:
	var ids: Array[StringName] = []
	var auto_button: Variant = _automation_buttons.get("auto_1")
	if auto_button is Button:
		var focus_id: StringName = _register_focus_node(StringName("sheet_automation_auto"), auto_button as Button)
		if focus_id != StringName():
			ids.append(focus_id)
	_link_vertical(ids)
	return ids

func _register_prestige_sheet_focus() -> Array[StringName]:
	var ids: Array[StringName] = []
	var focus_id: StringName = _register_focus_node(StringName("sheet_prestige_button"), _prestige_button)
	if focus_id != StringName():
		ids.append(focus_id)
	_link_vertical(ids)
	return ids

func _register_canvas_focus(sheet_ids: Array[StringName]) -> StringName:
	if _canvas_panel == null:
		return StringName()
	var canvas_id: StringName = _register_focus_node(StringName("canvas_panel"), _canvas_panel)
	if canvas_id == StringName():
		return StringName()
	if not sheet_ids.is_empty():
		var last_id: StringName = sheet_ids[sheet_ids.size() - 1]
		_focus_map.set_neighbour(last_id, FOCUS_DOWN, canvas_id)
		_focus_map.set_neighbour(canvas_id, FOCUS_UP, last_id)
	else:
		var tab_id: StringName = _tab_focus_id(_current_tab)
		if tab_id != StringName() and _focus_nodes.has(tab_id):
			_focus_map.set_neighbour(canvas_id, FOCUS_UP, tab_id)
	if not _is_desktop_layout and _focus_nodes.has(StringName("tab_feed")):
		_focus_map.set_neighbour(canvas_id, FOCUS_DOWN, StringName("tab_feed"))
		_focus_map.set_neighbour(StringName("tab_feed"), FOCUS_UP, canvas_id)
	elif _is_desktop_layout:
		var tab_id: StringName = _tab_focus_id(_current_tab)
		if tab_id != StringName() and _focus_nodes.has(tab_id):
			_focus_map.set_neighbour(canvas_id, FOCUS_DOWN, tab_id)
	return canvas_id

func _tab_focus_id(tab_id: String) -> StringName:
	return StringName("tab_%s" % tab_id)

func _tab_button_available(tab_id: String) -> bool:
	if _is_desktop_layout:
		var button: Variant = _find_dock_button(tab_id)
		return button != null and button.is_visible_in_tree()
	var button_variant: Variant = _bottom_tab_buttons_by_id.get(StringName(tab_id))
	if button_variant is BaseButton:
		var button := button_variant as BaseButton
		return button.is_visible_in_tree()
	return false

func _find_dock_button(tab_id: String) -> BaseButton:
	for button in _dock_buttons:
		if button and _button_tab_id(button) == tab_id:
			return button
	return null

func _link_horizontal(ids: Array[StringName], wrap: bool) -> void:
	var filtered: Array[StringName] = []
	for id in ids:
		if id != StringName() and _focus_nodes.has(id):
			filtered.append(id)
	var count := filtered.size()
	if count <= 1:
		return
	for i in range(count - 1):
		var current := filtered[i]
		var next_id := filtered[i + 1]
		_focus_map.set_neighbour(current, FOCUS_RIGHT, next_id)
		_focus_map.set_neighbour(next_id, FOCUS_LEFT, current)
	if wrap:
		var first := filtered[0]
		var last := filtered[count - 1]
		if first != last:
			_focus_map.set_neighbour(last, FOCUS_RIGHT, first)
			_focus_map.set_neighbour(first, FOCUS_LEFT, last)

func _link_vertical(ids: Array[StringName]) -> void:
	var filtered: Array[StringName] = []
	for id in ids:
		if id != StringName() and _focus_nodes.has(id):
			filtered.append(id)
	for i in range(filtered.size() - 1):
		var current := filtered[i]
		var next_id := filtered[i + 1]
		_focus_map.set_neighbour(current, FOCUS_DOWN, next_id)
		_focus_map.set_neighbour(next_id, FOCUS_UP, current)

func _link_row(ids: Array[StringName]) -> void:
	var filtered: Array[StringName] = []
	for id in ids:
		if id != StringName() and _focus_nodes.has(id):
			filtered.append(id)
	for i in range(filtered.size() - 1):
		var current := filtered[i]
		var next_id := filtered[i + 1]
		_focus_map.set_neighbour(current, FOCUS_RIGHT, next_id)
		_focus_map.set_neighbour(next_id, FOCUS_LEFT, current)

func _cycle_tab(step: int) -> void:
	var available: Array[String] = []
	for tab_id in TAB_SEQUENCE:
		if _tab_button_available(tab_id):
			available.append(tab_id)
	if available.is_empty():
		return
	var current_index := available.find(_current_tab)
	if current_index == -1:
		current_index = 0
	var next_index := (current_index + step) % available.size()
	if next_index < 0:
		next_index += available.size()
	var target := available[next_index]
	if target == _current_tab:
		return
	_show_tab(target)
	tab_selected.emit(target)

func _handle_focus_direction(direction: StringName) -> bool:
	if _focus_map == null:
		return false
	var focus_owner := get_viewport().gui_get_focus_owner()
	if focus_owner == null or not (focus_owner is Control):
		return _focus_default_to_current_tab()
	var control := focus_owner as Control
	if not _owns_control(control):
		return false
	var focus_id := _focus_id_for_control(control)
	if focus_id == StringName():
		return false
	var next_id := _focus_map.move(focus_id, direction)
	if next_id != focus_id:
		_focus_current_id = next_id
		return true
	return false

func _focus_default_to_current_tab() -> bool:
	_focus_default_for_tab(_current_tab)
	return _focus_current_id != StringName()

func _focus_default_for_tab(tab_id: String) -> void:
	if _focus_map == null:
		return
	if _current_sheet_primary_id != StringName() and _focus_nodes.has(_current_sheet_primary_id):
		_focus_map.focus(_current_sheet_primary_id)
		return
	var tab_focus_id := _tab_focus_id(tab_id)
	if tab_focus_id != StringName() and _focus_nodes.has(tab_focus_id):
		_focus_map.focus(tab_focus_id)
		return
	if _focus_nodes.has(StringName("tab_feed")):
		_focus_map.focus(StringName("tab_feed"))

func _register_tab_buttons() -> void:
	var bottom_bar := $RootMargin/RootStack/BottomBar/TabBar
	for child in bottom_bar.get_children():
		if child == _feed_button:
			continue
		if child is BaseButton:
			var button := child as BaseButton
			var tab_id := _button_tab_id(button)
			button.toggle_mode = true
			button.pressed.connect(_on_tab_pressed.bind(tab_id))
			_tab_buttons.append(button)
	var dock := $RootMargin/RootStack/MainStack/SideDock
	for child in dock.get_children():
		if child is BaseButton:
			var dock_button := child as BaseButton
			var dock_tab := _button_tab_id(dock_button)
			dock_button.toggle_mode = true
			dock_button.pressed.connect(_on_tab_pressed.bind(dock_tab))
			_dock_buttons.append(dock_button)

func _register_sheets() -> void:
	for child in _sheet_overlay.get_children():
		if child is Control:
			var sheet: Control = child
			var tab_id: String = String(sheet.get_meta("tab_id", ""))
			if tab_id.is_empty():
				tab_id = sheet.name.trim_suffix("Sheet").to_lower()
				sheet.set_meta("tab_id", tab_id)
			_sheets.append(sheet)

func _button_tab_id(button: BaseButton) -> String:
	var tab_value := String(button.get_meta("tab_id", ""))
	if not tab_value.is_empty():
		return tab_value
	var inferred: String = button.name
	if inferred.ends_with("Button"):
		inferred = inferred.left(inferred.length() - "Button".length())
	if inferred.ends_with("Dock"):
		inferred = inferred.left(inferred.length() - "Dock".length())
	return inferred.to_lower()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event.is_action_pressed("ui_tab_prev"):
		_cycle_tab(-1)
		accept_event()
		return
	elif event.is_action_pressed("ui_tab_next"):
		_cycle_tab(1)
		accept_event()
		return
	elif event.is_action_pressed("ui_left"):
		if _handle_focus_direction(FOCUS_LEFT):
			accept_event()
			return
	elif event.is_action_pressed("ui_right"):
		if _handle_focus_direction(FOCUS_RIGHT):
			accept_event()
			return
	elif event.is_action_pressed("ui_up"):
		if _handle_focus_direction(FOCUS_UP):
			accept_event()
			return
	elif event.is_action_pressed("ui_down"):
		if _handle_focus_direction(FOCUS_DOWN):
			accept_event()
			return
	if event.is_action_pressed("ui_tab_home"):
		_show_tab("home")
		tab_selected.emit("home")
		accept_event()
	elif event.is_action_pressed("ui_tab_store"):
		_show_tab("store")
		tab_selected.emit("store")
		accept_event()
	elif event.is_action_pressed("ui_tab_research"):
		_show_tab("research")
		tab_selected.emit("research")
		accept_event()
	elif event.is_action_pressed("ui_tab_automation"):
		_show_tab("automation")
		tab_selected.emit("automation")
		accept_event()
	elif event.is_action_pressed("ui_tab_prestige"):
		_show_tab("prestige")
		tab_selected.emit("prestige")
		accept_event()
	elif event.is_action_pressed("ui_tab_feed"):
		_on_feed_pressed()
		accept_event()
	elif event.is_action_pressed("ui_cancel"):
		if _current_tab != "home":
			_show_tab("home")
			tab_selected.emit("home")
			accept_event()

func _on_tab_pressed(tab_id: String) -> void:
	_show_tab(tab_id)
	tab_selected.emit(tab_id)

func _on_feed_pressed() -> void:
	feed_requested.emit()

func _on_feed_hold_button_down() -> void:
	feed_hold_started.emit()

func _on_feed_hold_button_up() -> void:
	feed_hold_ended.emit()

func _on_upgrade_button_pressed(action_id: String) -> void:
	upgrade_requested.emit(action_id)

func _on_automation_button_pressed(action_id: String) -> void:
	var target := StringName(action_id)
	automation_target_changed.emit(target)

func _strings_catalog() -> Node:
	if _strings_cache and is_instance_valid(_strings_cache):
		return _strings_cache
	var node := get_node_or_null("/root/Strings")
	if node and node.has_method("get_text"):
		_strings_cache = node
		return node
	return null

func _apply_automation_copy() -> void:
	var catalog := _strings_catalog()
	if catalog == null:
		return
	if _automation_title_label:
		var title_text := String(catalog.call("get_text", "automation_panel_title", _automation_title_label.text))
		_automation_title_label.text = title_text
		_automation_title_label.tooltip_text = String(catalog.call("get_text", "automation_panel_title_tooltip", title_text))
	for key in _automation_buttons.keys():
		var button := _automation_buttons[key] as Button
		if button == null:
			continue
		if key == "auto_1":
			var button_text := String(catalog.call("get_text", "automation_target_autoburst", button.text))
			button.text = button_text
			button.tooltip_text = String(catalog.call("get_text", "automation_target_autoburst_tooltip", button.tooltip_text))

func _on_research_button_pressed(action_id: String) -> void:
	research_requested.emit(action_id)

func _show_tab(tab_id: String) -> void:
	var previous := _current_tab
	_current_tab = tab_id
	if tab_id == "automation" and previous != "automation":
		automation_panel_opened.emit()
	elif previous == "automation" and tab_id != "automation":
		automation_panel_closed.emit()
	for button in _tab_buttons:
		button.button_pressed = _button_tab_id(button) == tab_id
	for button in _dock_buttons:
		button.button_pressed = _button_tab_id(button) == tab_id
	for sheet in _sheets:
		sheet.visible = sheet.get_meta("tab_id") == tab_id
	_sheet_overlay.visible = true
	_rebuild_focus_graph(false)
	_focus_default_for_tab(tab_id)

func _update_layout() -> void:
	var window_size: Vector2 = _current_window_size()
	var viewport_width: float = window_size.x
	var is_desktop: bool = viewport_width >= DESKTOP_BREAKPOINT - BREAKPOINT_FUZZ
	var is_tablet: bool = viewport_width >= TABLET_BREAKPOINT - BREAKPOINT_FUZZ
	_update_root_margins(viewport_width)
	_apply_bottom_bar_spacing(viewport_width, is_desktop)
	_apply_column_spacing(is_desktop, is_tablet)
	_is_desktop_layout = is_desktop
	_bottom_bar.visible = not is_desktop
	_side_dock.visible = is_desktop
	var show_environment: bool = viewport_width >= TABLET_BREAKPOINT - BREAKPOINT_FUZZ
	var side_sheet_width: float = _side_sheet_width(viewport_width)
	var environment_column_width: float = min(420.0, max(_environment_column_width(viewport_width), side_sheet_width))
	if _environment_wrapper:
		_environment_wrapper.visible = show_environment
		if show_environment:
			_environment_wrapper.custom_minimum_size = Vector2(environment_column_width, 0.0)
			_environment_wrapper.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		else:
			_environment_wrapper.custom_minimum_size = Vector2(0.0, 0.0)
			_environment_wrapper.size_flags_horizontal = 0
	if _environment_panel:
		_environment_panel.visible = show_environment
	var sheet_height := SHEET_HEIGHT_MOBILE
	if is_desktop:
		sheet_height = SHEET_HEIGHT_DESKTOP
	elif is_tablet:
		sheet_height = SHEET_HEIGHT_TABLET
	var use_side_anchor := show_environment
	_configure_sheet_position(sheet_height, use_side_anchor, side_sheet_width, window_size.x)
	_adjust_canvas_width(window_size.x, environment_column_width)
	_apply_canvas_hint()
	_refresh_canvas_message_visibility()
	_sync_factory_viewport_size()
	layout_changed.emit()

func _configure_sheet_position(sheet_height: float, use_side_anchor: bool, side_width: float, viewport_width: float) -> void:
	var margin := 16.0
	if use_side_anchor:
		_move_sheet_to_anchor(_desktop_sheet_anchor)
		if _desktop_sheet_anchor:
			_desktop_sheet_anchor.visible = true
			_desktop_sheet_anchor.custom_minimum_size = Vector2(side_width, 0.0)
			_desktop_sheet_anchor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if _mobile_sheet_anchor:
			_mobile_sheet_anchor.visible = false
			_mobile_sheet_anchor.anchor_left = 0.0
			_mobile_sheet_anchor.anchor_right = 1.0
			_mobile_sheet_anchor.anchor_top = 1.0
			_mobile_sheet_anchor.anchor_bottom = 1.0
			_mobile_sheet_anchor.offset_left = 0.0
			_mobile_sheet_anchor.offset_right = 0.0
			_mobile_sheet_anchor.offset_top = 0.0
			_mobile_sheet_anchor.offset_bottom = 0.0
		if _sheet_overlay:
			_sheet_overlay.anchor_left = 0.0
			_sheet_overlay.anchor_right = 1.0
			_sheet_overlay.anchor_top = 0.0
			_sheet_overlay.anchor_bottom = 1.0
			_sheet_overlay.offset_left = 0.0
			_sheet_overlay.offset_right = 0.0
			_sheet_overlay.offset_top = 0.0
			_sheet_overlay.offset_bottom = 0.0
			_sheet_overlay.custom_minimum_size = Vector2(side_width, 0.0)
			_sheet_overlay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		_move_sheet_to_anchor(_mobile_sheet_anchor)
		if _desktop_sheet_anchor:
			_desktop_sheet_anchor.visible = false
		if _mobile_sheet_anchor:
			_mobile_sheet_anchor.visible = true
			_mobile_sheet_anchor.anchor_left = 0.0
			_mobile_sheet_anchor.anchor_right = 1.0
			_mobile_sheet_anchor.anchor_top = 1.0
			_mobile_sheet_anchor.anchor_bottom = 1.0
			_mobile_sheet_anchor.offset_left = margin
			_mobile_sheet_anchor.offset_right = -margin
			_mobile_sheet_anchor.offset_top = -sheet_height - margin
			_mobile_sheet_anchor.offset_bottom = -margin
	if _sheet_overlay:
		_sheet_overlay.anchor_left = 0.0
		_sheet_overlay.anchor_right = 1.0
		_sheet_overlay.anchor_top = 0.0
		_sheet_overlay.anchor_bottom = 1.0
		_sheet_overlay.offset_left = 0.0
		_sheet_overlay.offset_right = 0.0
		_sheet_overlay.offset_top = 0.0
		_sheet_overlay.offset_bottom = 0.0
		_sheet_overlay.custom_minimum_size = Vector2(0.0, 0.0)
		_sheet_overlay.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_apply_sheet_layout(use_side_anchor, side_width, margin, sheet_height, viewport_width)

func _apply_sheet_layout(use_side_anchor: bool, side_width: float, margin: float, sheet_height: float, viewport_width: float) -> void:
	var margin_int := int(round(margin))
	for sheet_control in _sheets:
		if sheet_control == null:
			continue
		var sheet := sheet_control as Control
		if sheet == null:
			continue
		sheet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sheet.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if use_side_anchor:
			sheet.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			sheet.custom_minimum_size = Vector2(side_width, 0.0)
			sheet.offset_left = 0.0
			sheet.offset_right = 0.0
			sheet.offset_top = 0.0
			sheet.offset_bottom = 0.0
			if sheet.has_theme_stylebox_override("panel"):
				sheet.remove_theme_stylebox_override("panel")
		else:
			sheet.anchor_left = 0.0
			sheet.anchor_right = 1.0
			sheet.anchor_top = 0.0
			sheet.anchor_bottom = 1.0
			sheet.offset_left = 0.0
			sheet.offset_right = 0.0
			sheet.offset_top = 0.0
			sheet.offset_bottom = 0.0
			sheet.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			var desired_width := clampf(viewport_width - (margin * 2.0), 320.0, 520.0)
			var capped_height := minf(sheet_height, 280.0)
			sheet.custom_minimum_size = Vector2(desired_width, capped_height)
			if sheet is PanelContainer and _tokens:
				var style := StyleBoxFlat.new()
				style.bg_color = _tokens.colour(&"sheet_mobile_bg")
				style.border_width_left = 1
				style.border_width_right = 1
				style.border_width_top = 1
				style.border_width_bottom = 1
				style.border_color = _tokens.colour(&"panel_border")
				style.set_corner_radius_all(int(round(_tokens.radius(&"corner_md"))))
				(sheet as PanelContainer).add_theme_stylebox_override("panel", style)

func _environment_column_width(viewport_width: float) -> float:
	if viewport_width >= 1600.0:
		return 280.0
	if viewport_width >= 1400.0:
		return 260.0
	if viewport_width >= 1200.0:
		return 240.0
	if viewport_width >= 1024.0:
		return 220.0
	if viewport_width >= TABLET_BREAKPOINT - BREAKPOINT_FUZZ:
		return 220.0
	return 0.0

func _side_sheet_width(viewport_width: float) -> float:
	if viewport_width >= 1600.0:
		return 280.0
	if viewport_width >= 1400.0:
		return 260.0
	if viewport_width >= 1200.0:
		return 240.0
	if viewport_width >= 1024.0:
		return 220.0
	if viewport_width >= TABLET_BREAKPOINT - BREAKPOINT_FUZZ:
		return 220.0
	return 0.0

func _current_window_size() -> Vector2:
	var window_size: Vector2 = Vector2(size.x, size.y)
	var window := get_window()
	if window:
		var win_size_vec := Vector2(float(window.size.x), float(window.size.y))
		if win_size_vec.x > 0.0 and win_size_vec.y > 0.0:
			window_size = win_size_vec
	else:
		var viewport := get_viewport()
		if viewport:
			var visible := viewport.get_visible_rect()
			if visible.size.x > 0.0 and visible.size.y > 0.0:
				window_size = visible.size
	return window_size

func _update_root_margins(viewport_width: float) -> void:
	if _root_margin_container == null:
		return
	var margin := 24.0
	if viewport_width < TABLET_BREAKPOINT:
		margin = 18.0
	if viewport_width < PHONE_BREAKPOINT:
		margin = 12.0
	_current_root_margin = margin
	_set_margin(_root_margin_container, margin, margin, margin, margin)

func _apply_bottom_bar_spacing(viewport_width: float, is_desktop: bool) -> void:
	if _bottom_bar == null:
		return
	var horizontal := 12.0
	var top := 16.0
	if viewport_width < TABLET_BREAKPOINT:
		horizontal = 10.0
		top = 14.0
	if viewport_width < PHONE_BREAKPOINT:
		horizontal = 8.0
		top = 12.0
	if is_desktop:
		top = 0.0
	_set_margin(_bottom_bar, horizontal, top, horizontal, 0.0)

func _set_margin(container: MarginContainer, left: float, top: float, right: float, bottom: float) -> void:
	container.add_theme_constant_override("margin_left", int(round(left)))
	container.add_theme_constant_override("margin_top", int(round(top)))
	container.add_theme_constant_override("margin_right", int(round(right)))
	container.add_theme_constant_override("margin_bottom", int(round(bottom)))

func _set_root_side_margins(left: float, right: float) -> void:
	if _root_margin_container == null:
		return
	_root_margin_container.add_theme_constant_override("margin_left", int(round(left)))
	_root_margin_container.add_theme_constant_override("margin_right", int(round(right)))

func _apply_column_spacing(is_desktop: bool, is_tablet: bool) -> void:
	if _main_stack == null:
		return
	var separation := 12
	if is_desktop:
		separation = 12
	elif is_tablet:
		separation = 12
	_main_stack.add_theme_constant_override("separation", separation)
	_current_column_separation = separation

func _adjust_canvas_width(window_width: float, environment_width: float) -> void:
	if _canvas_wrapper == null:
		return
	var side_dock_width: float = 0.0
	if _side_dock and _side_dock.visible:
		if _side_dock.custom_minimum_size.x > 0.0:
			side_dock_width = _side_dock.custom_minimum_size.x
		else:
			side_dock_width = _side_dock.size.x
	var layout_width: float = float(ProjectSettings.get_setting("display/window/size/viewport_width"))
	var env_min: float = environment_width
	if _environment_wrapper:
		env_min = max(env_min, float(_environment_wrapper.custom_minimum_size.x))
	var dock_min: float = side_dock_width
	if _side_dock:
		dock_min = max(dock_min, float(_side_dock.custom_minimum_size.x))
	var env_width: float = env_min
	var dock_width: float = dock_min
	var gutter: float = maxf(_current_column_separation, 16.0)
	var reserved: float = env_width + dock_width + (_current_root_margin * 2.0) + gutter
	var min_canvas: float = maxf(layout_width - reserved, 640.0)
	var occupied: float = env_width + dock_width + gutter + min_canvas
	var extra: float = maxf(layout_width - occupied, 0.0)
	_canvas_wrapper.custom_minimum_size = Vector2(min_canvas, 0.0)
	var side_margin: float = _current_root_margin + extra * 0.5
	_set_root_side_margins(side_margin, side_margin)
	if OS.is_debug_build():
		var msg := "UI layout -> window: %.1f env: %.1f dock: %.1f min_canvas: %.1f" % [
			layout_width,
			env_width,
			dock_width,
			min_canvas
		]
		print_debug(msg)

func _apply_canvas_hint() -> void:
	if _canvas_info == null:
		return
	if _custom_canvas_hint != "":
		_canvas_info.text = _custom_canvas_hint
		_canvas_info.visible = true
		return
	if _side_dock.visible:
		_canvas_info.text = "Factory Canvas — Desktop dock active (hotkeys 1-5)"
	else:
		_canvas_info.text = "Factory Canvas — Tab sheets overlay (hotkeys 1-5, feed = F)"
	_canvas_info.visible = not _canvas_placeholder or _canvas_placeholder.visible

func _update_feed_button_label() -> void:
	# Keep buttons enabled so release events (button_up) still fire while feeding.
	_feed_button.disabled = false
	_home_feed_button.disabled = false
	if _feed_active:
		_feed_button.text = "Feeding..."
		_home_feed_button.text = "Feeding..."
	else:
		if _feed_queue_count > 1:
			_feed_button.text = "Feed x" + str(_feed_queue_count)
		elif _feed_queue_count == 1:
			_feed_button.text = "Feed x1"
		else:
			_feed_button.text = "Feed"
		_home_feed_button.text = _home_feed_default_text

func _sync_factory_viewport_size() -> void:
	if _factory_viewport == null:
		return
	var panel_size := Vector2.ZERO
	if _canvas_panel:
		panel_size = _canvas_panel.get_rect().size
	if panel_size == Vector2.ZERO:
		return
	_factory_viewport.size = Vector2i(max(1, int(round(panel_size.x))), max(1, int(round(panel_size.y))))

func _apply_button_state(button: Button, state: Dictionary) -> void:
	if button == null:
		return
	if state.has("visible"):
		button.visible = bool(state["visible"])
	if not button.visible:
		return
	if state.has("text"):
		button.text = String(state["text"])
	if state.has("disabled"):
		button.disabled = bool(state["disabled"])
	if state.has("tooltip"):
		button.tooltip_text = String(state["tooltip"])

func _refresh_canvas_message_visibility() -> void:
	if not _canvas_message:
		return
	if _custom_canvas_message == "":
		_canvas_message.visible = false
	else:
		_canvas_message.visible = not _is_desktop_layout
var _strings_cache: Node
