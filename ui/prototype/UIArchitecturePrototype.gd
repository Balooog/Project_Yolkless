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

const PHONE_BREAKPOINT := 600.0
const TABLET_BREAKPOINT := 900.0
const DESKTOP_BREAKPOINT := 1280.0
const BREAKPOINT_FUZZ := 40.0
const SHEET_HEIGHT_DESKTOP := 420.0
const SHEET_HEIGHT_TABLET := 320.0
const SHEET_HEIGHT_MOBILE := 360.0

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
var _home_feed_default_text := "Hold to Feed"
var _is_desktop_layout := false

@onready var _root_margin_container: MarginContainer = $RootMargin
@onready var _bottom_bar: Control = $RootMargin/RootStack/BottomBar
@onready var _main_stack: HBoxContainer = $RootMargin/RootStack/MainStack
@onready var _side_dock: Control = $RootMargin/RootStack/MainStack/SideDock
@onready var _sheet_overlay: Control = $RootMargin/RootStack/MainStack/CanvasWrapper/MobileSheetAnchor/SheetOverlay
@onready var _canvas_wrapper: Control = $RootMargin/RootStack/MainStack/CanvasWrapper
@onready var _canvas_panel: Control = $RootMargin/RootStack/MainStack/CanvasWrapper/CanvasPanel
@onready var _canvas_info: Label = $RootMargin/RootStack/MainStack/CanvasWrapper/CanvasPanel/CanvasInfo
@onready var _canvas_message: Label = $RootMargin/RootStack/MainStack/CanvasWrapper/CanvasPanel/CanvasMessage
@onready var _canvas_placeholder: ColorRect = $RootMargin/RootStack/MainStack/CanvasWrapper/CanvasPanel/CanvasPlaceholder
@onready var _feed_button: Button = $RootMargin/RootStack/BottomBar/TabBar/FeedButton
@onready var _alert_pill: Label = $RootMargin/RootStack/TopBanner/BannerContent/AlertPill
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
@onready var _automation_buttons: Dictionary = {
	"auto_1": $RootMargin/RootStack/MainStack/CanvasWrapper/MobileSheetAnchor/SheetOverlay/AutomationSheet/AutomationMargin/AutomationColumn/AutomationAutoButton
}
@onready var _prestige_status_label: Label = $RootMargin/RootStack/MainStack/CanvasWrapper/MobileSheetAnchor/SheetOverlay/PrestigeSheet/PrestigeMargin/PrestigeColumn/PrestigeStatusLabel
@onready var _prestige_button: Button = $RootMargin/RootStack/MainStack/CanvasWrapper/MobileSheetAnchor/SheetOverlay/PrestigeSheet/PrestigeMargin/PrestigeColumn/PrestigeButton

var _metric_labels: Dictionary
var _tab_buttons: Array[BaseButton] = []
var _dock_buttons: Array[BaseButton] = []
var _sheets: Array[Control] = []
var _current_root_margin: float = 24.0
var _current_column_separation: float = 12.0
var _factory_design_width: float = 960.0
var _factory_design_height: float = 720.0

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
	_prestige_button.pressed.connect(func(): prestige_requested.emit())
	resized.connect(_update_layout)
	_metric_labels = {
		"credits": $RootMargin/RootStack/TopBanner/BannerContent/CreditsBox/CreditsValue,
		"storage": $RootMargin/RootStack/TopBanner/BannerContent/StorageBox/StorageValue,
		"pps": $RootMargin/RootStack/TopBanner/BannerContent/PpsBox/PpsValue,
		"research": $RootMargin/RootStack/TopBanner/BannerContent/ResearchBox/ResearchValue
	}
	if _canvas_panel and not _canvas_panel.resized.is_connected(_sync_factory_viewport_size):
		_canvas_panel.resized.connect(_sync_factory_viewport_size)
	_home_feed_default_text = _home_feed_button.text
	set_metrics(_metrics)
	_sync_factory_viewport_size()
	_update_layout()
	_setup_focus_modes()
	_show_tab(_current_tab)

func set_metrics(metrics: Dictionary) -> void:
	for key in _metrics.keys():
		if metrics.has(key):
			_metrics[key] = String(metrics[key])
			var label := _metric_labels.get(key, null) as Label
			if label:
				label.text = _metrics[key]

func set_alert_message(message: String) -> void:
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

func _focus_default_for_tab(tab_id: String) -> void:
	match tab_id:
		"home":
			if _home_feed_button:
				_home_feed_button.grab_focus()
			elif _feed_button:
				_feed_button.grab_focus()
		"store":
			if not _grab_first_button(_store_buttons) and _feed_button:
				_feed_button.grab_focus()
		"research":
			if not _grab_first_button(_research_buttons) and _feed_button:
				_feed_button.grab_focus()
		"automation":
			if not _grab_first_button(_automation_buttons) and _feed_button:
				_feed_button.grab_focus()
		"prestige":
			if _prestige_button:
				_prestige_button.grab_focus()
			elif _feed_button:
				_feed_button.grab_focus()
		_:
			if _feed_button:
				_feed_button.grab_focus()

func _grab_first_button(collection: Dictionary) -> bool:
	for value in collection.values():
		if value is Button:
			(value as Button).grab_focus()
			return true
	return false

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

func _on_research_button_pressed(action_id: String) -> void:
	research_requested.emit(action_id)

func _show_tab(tab_id: String) -> void:
	_current_tab = tab_id
	for button in _tab_buttons:
		button.button_pressed = _button_tab_id(button) == tab_id
	for button in _dock_buttons:
		button.button_pressed = _button_tab_id(button) == tab_id
	for sheet in _sheets:
		sheet.visible = sheet.get_meta("tab_id") == tab_id
	_sheet_overlay.visible = true
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
	_configure_sheet_position(sheet_height, use_side_anchor, side_sheet_width)
	_adjust_canvas_width(window_size.x, environment_column_width)
	_apply_canvas_hint()
	_refresh_canvas_message_visibility()
	_sync_factory_viewport_size()
	layout_changed.emit()

func _configure_sheet_position(sheet_height: float, use_side_anchor: bool, side_width: float) -> void:
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
	var margin_container := _bottom_bar as MarginContainer
	if margin_container == null:
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
	_set_margin(margin_container, horizontal, top, horizontal, 0.0)

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
