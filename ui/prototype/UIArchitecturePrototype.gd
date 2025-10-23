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

const DESKTOP_BREAKPOINT := 900.0
const TABLET_BREAKPOINT := 640.0
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

@onready var _bottom_bar: Control = $RootMargin/RootStack/BottomBar
@onready var _side_dock: Control = $RootMargin/RootStack/MainStack/SideDock
@onready var _sheet_overlay: Control = $RootMargin/RootStack/MainStack/CanvasWrapper/MobileSheetAnchor/SheetOverlay
@onready var _canvas_panel: Control = $RootMargin/RootStack/MainStack/CanvasWrapper/CanvasPanel
@onready var _canvas_info: Label = $RootMargin/RootStack/MainStack/CanvasWrapper/CanvasPanel/CanvasInfo
@onready var _canvas_message: Label = $RootMargin/RootStack/MainStack/CanvasWrapper/CanvasPanel/CanvasMessage
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
@onready var _factory_viewport_container: ViewportContainer = $RootMargin/RootStack/MainStack/CanvasWrapper/CanvasPanel/FactoryViewportContainer
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

func _ready() -> void:
	_register_tab_buttons()
	_register_sheets()
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
	if _custom_canvas_message == "":
		_canvas_message.text = "Interact here with pinch, pan, and keyboard navigation."
	else:
		_canvas_message.text = _custom_canvas_message

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
		var hint = String(data["feed_hint"])
		_home_feed_hint_label.visible = hint != ""
		if hint != "":
			_home_feed_hint_label.text = hint
			_home_feed_hint_label.tooltip_text = hint
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
		var queue = int(data["queue"])
		if queue > 0:
			_home_feed_queue_label.visible = true
			_home_feed_queue_label.text = "Queue: %d" % queue
		else:
			_home_feed_queue_label.visible = false
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
	if _feed_queue_count > 0:
		_home_feed_queue_label.visible = true
		_home_feed_queue_label.text = "Queue: %d" % _feed_queue_count
	else:
		_home_feed_queue_label.visible = false

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

func get_environment_panel() -> Control:
	return _environment_panel

func get_factory_viewport() -> SubViewport:
	return _factory_viewport

func get_factory_viewport_container() -> ViewportContainer:
	return _factory_viewport_container

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
		accept_event()
	elif event.is_action_pressed("ui_tab_store"):
		_show_tab("store")
		accept_event()
	elif event.is_action_pressed("ui_tab_research"):
		_show_tab("research")
		accept_event()
	elif event.is_action_pressed("ui_tab_automation"):
		_show_tab("automation")
		accept_event()
	elif event.is_action_pressed("ui_tab_prestige"):
		_show_tab("prestige")
		accept_event()
	elif event.is_action_pressed("ui_tab_feed"):
		_on_feed_pressed()
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

func _update_layout() -> void:
	var viewport_width := size.x
	var is_desktop := viewport_width >= DESKTOP_BREAKPOINT
	var is_tablet := viewport_width >= TABLET_BREAKPOINT
	_is_desktop_layout = is_desktop
	_bottom_bar.visible = not is_desktop
	_side_dock.visible = is_desktop
	var show_environment := viewport_width >= TABLET_BREAKPOINT
	if _environment_wrapper:
		_environment_wrapper.visible = show_environment
		if show_environment:
			_environment_wrapper.custom_minimum_size = Vector2(280.0, 0.0)
			_environment_wrapper.size_flags_horizontal = 1
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
	_configure_sheet_position(sheet_height, is_desktop)
	_apply_canvas_hint()
	_sync_factory_viewport_size()
	layout_changed.emit()

func _configure_sheet_position(sheet_height: float, is_desktop: bool) -> void:
	var margin := 16.0
	if is_desktop:
		_move_sheet_to_anchor(_desktop_sheet_anchor)
		if _desktop_sheet_anchor:
			_desktop_sheet_anchor.visible = true
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
			_sheet_overlay.custom_minimum_size = Vector2(0.0, 0.0)
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

func _apply_canvas_hint() -> void:
	if _custom_canvas_hint != "":
		_canvas_info.text = _custom_canvas_hint
		return
	if _side_dock.visible:
		_canvas_info.text = "Factory Canvas — Desktop dock active (hotkeys 1-5)"
	else:
		_canvas_info.text = "Factory Canvas — Tab sheets overlay (hotkeys 1-5, feed = F)"

func _update_feed_button_label() -> void:
	if _feed_active:
		_feed_button.text = "Feeding..."
		_feed_button.disabled = true
	else:
		_feed_button.disabled = false
		if _feed_queue_count > 1:
			_feed_button.text = "Feed x" + str(_feed_queue_count)
		elif _feed_queue_count == 1:
			_feed_button.text = "Feed x1"
		else:
			_feed_button.text = "Feed"
	if _feed_active:
		_home_feed_button.text = "Feeding..."
		_home_feed_button.disabled = true
	else:
		_home_feed_button.text = _home_feed_default_text
		_home_feed_button.disabled = false

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
