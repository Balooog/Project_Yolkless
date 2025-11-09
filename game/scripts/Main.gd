extends Node

const SETTINGS_PANEL_SCENE := preload("res://game/scenes/widgets/SettingsPanel.tscn")
const DEBUG_OVERLAY_SCENE := preload("res://game/scenes/widgets/DebugOverlay.tscn")

const ShopService := preload("res://src/shop/ShopService.gd")
const ShopDebug := preload("res://src/shop/ShopDebug.gd")
const EnvPanel := preload("res://ui/widgets/EnvPanel.gd")
const EnvironmentService := preload("res://src/services/EnvironmentService.gd")
const FactoryConveyor := preload("res://game/scripts/conveyor/FactoryConveyor.gd")
const UIArchitecturePrototype := preload("res://ui/prototype/UIArchitecturePrototype.gd")
const SandboxCanvasScene := preload("res://scenes/sandbox/SandboxCanvas.tscn")

const FEED_FLASH_COLOR := Color(1, 0.7, 0.7, 1)
const DEFAULT_ENV_STAGE_SIZE := Vector2(640, 360)
const POWER_WARNING_COLOR := Color(0.996, 0.784, 0.318, 1.0)
const POWER_CRITICAL_COLOR := Color(0.984, 0.412, 0.392, 1.0)
const POWER_WARNING_CLIP := preload("res://assets/placeholder/audio/power_warning_low.wav")
const POWER_CRITICAL_CLIP := preload("res://assets/placeholder/audio/power_warning_critical.wav")
const CONVEYOR_JAM_WARNING_THRESHOLD := 40
const AUTOMATION_BUTTON_TARGETS := {
	StringName("auto_1"): StringName("economy_feed_autoburst")
}
const StatBus := preload("res://src/services/StatBus.gd")
const TOOLTIP_SCENE := preload("res://ui/components/Tooltip.tscn")
const TIER1_POWER_SECONDS := 90.0
const TIER1_RATE_THRESHOLD := 1.2
const TIER1_CONVEYOR_BONUS := 0.10

@onready var bal: Balance = $Balance
@onready var res: Research = $Research
@onready var eco: Economy = $Economy
@onready var sav: Save = $Save
@onready var environment_root_node: Node2D = %EnvironmentRoot
@onready var legacy_ui_root: MarginContainer = %RootMargin

@onready var root_vbox: VBoxContainer = %VBox
var environment_panel: EnvPanel
@onready var deny_sound: AudioStreamPlayer = %DenySound
@onready var power_warning_sound: AudioStreamPlayer = %PowerWarningSound
@onready var stats_box: HBoxContainer = %StatsBox
@onready var lbl_soft: Label = %SoftLabel
@onready var lbl_conveyor: Label = %ConveyorLabel
@onready var capacity_label: Label = %CapacityLabel
@onready var capacity_bar: ProgressBar = %CapacityBar
@onready var btn_ship_now: Button = %ShipNowButton
@onready var capacity_container: VBoxContainer = capacity_label.get_parent() as VBoxContainer
@onready var capacity_pulse_label: Label = %CapPulseLabel
@onready var feed_status_label: Label = %FeedStatus
@onready var feed_bar: ProgressBar = %FeedBar
@onready var lbl_pps: Label = %PPSLabel
@onready var lbl_power: Label = %PowerLabel
@onready var lbl_tier: Label = %TierLabel
@onready var lbl_prestige: Label = %PrestigeLabel
@onready var research_header_label: Label = %ResearchHeader
@onready var lbl_research: Label = %ResearchStatus

@onready var btn_burst: Button = %BurstButton
@onready var btn_prod: Button = %BuyProd
@onready var btn_cap: Button = %BuyCap
@onready var btn_feed: Button = %BuyFeed
@onready var btn_auto: Button = %BuyAuto
@onready var btn_promote: Button = %Promote
@onready var btn_prestige: Button = %PrestigeButton
@onready var btn_export: Button = %Export
@onready var btn_import: Button = %Import
@onready var btn_settings: Button = %SettingsButton
@onready var btn_r_prod: Button = %ResearchBuyProd
@onready var btn_r_cap: Button = %ResearchBuyCap
@onready var btn_r_auto: Button = %ResearchBuyAuto

@onready var offline_popup: PopupPanel = %OfflinePopup
@onready var offline_label: Label = %OfflineLabel
@onready var offline_close: Button = %OfflineClose
@onready var feed_hint_label: Label = %FeedHint
@onready var toast_label: Label = %ToastLabel
@onready var conveyor_manager: ConveyorManager = %ConveyorManager
@onready var conveyor_layer := %ConveyorLayer
@onready var ui_prototype := %PrototypeUI as UIArchitecturePrototype
@onready var ui_layer: CanvasLayer = $UI
@onready var btn_automation_panel: Button = %AutomationPanelButton
@onready var automation_panel_ui: AutomationPanelUI = %AutomationPanel
@onready var micro_event_card: PanelContainer = %MicroEventCard
@onready var micro_event_title: Label = %MicroEventTitle
@onready var micro_event_body: Label = %MicroEventBody
@onready var micro_event_timer_label: Label = %MicroEventTimer
@onready var micro_event_primary_button: Button = %MicroEventDismiss
@onready var micro_event_secondary_button: Button = %MicroEventSecondary

var text_scale := 1.0
var shop_service: ShopService
var shop_debug: ShopDebug
var settings_panel: SettingsPanel
var debug_overlay: CanvasLayer
var high_contrast_enabled := false
var visuals_enabled := true
var color_palette: StringName = ProceduralFactory.PALETTE_DEFAULT
var environment_service: EnvironmentService
var power_service: PowerService
var automation_service: AutomationService
var sandbox_service: SandboxService
var sandbox_canvas: Control
var sandbox_renderer: SandboxRenderer
var _feed_deny_sound_warned := false
var _toast_tween: Tween
var _show_cap_pulse := true
var _conveyor_rate: float = 0.0
var _conveyor_queue: int = 0
var _conveyor_jam: bool = false
var _conveyor_spawn_accumulator: float = 0.0
var _conveyor_color_index: int = 0
var _conveyor_colors: Array[Color] = [
	Color(0.968, 0.913, 0.647, 1.0),
	Color(1.0, 0.753, 0.275, 1.0),
	Color(0.757, 0.486, 0.455, 1.0)
]
var _automation_refresh_timer: float = 0.0
var _prototype_metrics := {
	"credits": "₡ 0",
	"storage": "Storage 0 / 0",
	"pps": "0 PPS",
	"research": "0 RP"
}
var _prototype_status := {
	"power": {"value": "Load n/a", "tone": StringName("normal")},
	"economy": {"value": "₡ 0", "tone": StringName("normal")},
	"population": {"value": "0 hens", "tone": StringName("normal")},
	"economy_rate": {"value": "0.0/s", "tone": StringName("normal")},
	"conveyor_backlog": {"value": "Queue 0", "tone": StringName("normal")}
}
var _prototype_feed_status := "Feed silo ready"
var _prototype_feed_fraction := 0.0
var _prototype_feed_queue := 0
var _comfort_index: float = 0.0
var _comfort_bonus: float = 0.0
var factory_viewport: SubViewport
var env_renderer_mode: String = "legacy"
var _power_warning_level: StringName = PowerService.WARNING_NORMAL
var _power_warning_sound_warned := false
var _statbus: StatBus
var _power_tooltip: UITooltip
var _economy_tooltip: UITooltip
var _backlog_tooltip: UITooltip
var _economy_tone: StringName = StringName("normal")
var _backlog_tone_runtime: StringName = StringName("normal")
var _tier_one_unlocked := false
var _stable_power_seconds := 0.0
var _economy_rate_avg := 0.0
var _tier_rate_samples := 0
var _micro_event_active_id: String = ""
var _micro_event_time_left := 0.0
var _micro_event_current: Dictionary = {}
var _micro_event_primary_action: String = ""
var _micro_event_secondary_action: String = ""

func _ready() -> void:
	_configure_input_actions()

	res.setup(bal)
	eco.setup(bal, res)
	sav.setup(eco, res)

	shop_service = ShopService.new()
	add_child(shop_service)
	shop_service.setup(bal, eco)
	shop_service.state_changed.connect(_on_shop_state_changed)

	shop_debug = ShopDebug.new()
	add_child(shop_debug)
	shop_debug.setup(shop_service, eco)

	bal.reloaded.connect(_on_balance_reload)
	res.changed.connect(_update_research_view)
	eco.soft_changed.connect(_on_soft_changed)
	eco.storage_changed.connect(_on_storage_changed)
	eco.tier_changed.connect(func(_tier: int) -> void: _update_factory_view())
	eco.burst_state.connect(_on_feed_state_changed)
	eco.dump_triggered.connect(_on_dump_triggered)
	if not eco.economy_rate_changed.is_connected(_on_economy_rate_changed):
		eco.economy_rate_changed.connect(_on_economy_rate_changed)
	if not eco.conveyor_backlog_changed.is_connected(_on_conveyor_backlog_changed):
		eco.conveyor_backlog_changed.connect(_on_conveyor_backlog_changed)
	btn_burst.button_down.connect(_on_feed_button_down)
	btn_burst.button_up.connect(_on_feed_button_up)
	btn_prod.pressed.connect(func(): _attempt_upgrade("prod_1"))
	btn_cap.pressed.connect(func(): _attempt_upgrade("cap_1"))
	btn_feed.pressed.connect(func(): _attempt_upgrade("feed_storage"))
	btn_auto.pressed.connect(func(): _attempt_upgrade("auto_1"))
	btn_promote.pressed.connect(_attempt_promote)
	btn_prestige.pressed.connect(_attempt_prestige)
	btn_export.pressed.connect(func(): sav.export_to_clipboard())
	btn_import.pressed.connect(func(): sav.import_from_clipboard())
	btn_settings.pressed.connect(_on_settings_pressed)
	btn_r_prod.pressed.connect(func(): _attempt_research("r_prod_1"))
	btn_r_cap.pressed.connect(func(): _attempt_research("r_cap_1"))
	btn_r_auto.pressed.connect(func(): _attempt_research("r_auto_1"))
	offline_close.pressed.connect(func(): offline_popup.hide())
	btn_ship_now.pressed.connect(_on_ship_now_pressed)
	if btn_automation_panel:
		btn_automation_panel.pressed.connect(_on_automation_panel_button_pressed)
	_setup_status_tooltips()
	if micro_event_card:
		micro_event_card.visible = false
	if micro_event_primary_button:
		micro_event_primary_button.pressed.connect(_on_micro_event_primary_pressed)
	if micro_event_secondary_button:
		micro_event_secondary_button.pressed.connect(_on_micro_event_secondary_pressed)

	var config_node := get_node_or_null("/root/Config")
	var logging_enabled := true
	var logging_force_disable := false
	var seed := 0
	if config_node:
		logging_enabled = config_node.logging_enabled
		logging_force_disable = config_node.logging_force_disable
		seed = int(config_node.seed)
		var env_value: Variant = config_node.get("env_renderer")
		if env_value != null:
			var mode := String(env_value).to_lower()
			if mode == "sandbox" or mode == "legacy":
				env_renderer_mode = mode

	if ui_prototype:
		if not ui_prototype.feed_requested.is_connected(_on_prototype_feed_requested):
			ui_prototype.feed_requested.connect(_on_prototype_feed_requested)
		if not ui_prototype.feed_hold_started.is_connected(_on_prototype_feed_hold_started):
			ui_prototype.feed_hold_started.connect(_on_prototype_feed_hold_started)
		if not ui_prototype.feed_hold_ended.is_connected(_on_prototype_feed_hold_ended):
			ui_prototype.feed_hold_ended.connect(_on_prototype_feed_hold_ended)
		if not ui_prototype.promote_requested.is_connected(_on_prototype_promote_requested):
			ui_prototype.promote_requested.connect(_on_prototype_promote_requested)
		if not ui_prototype.upgrade_requested.is_connected(_on_prototype_upgrade_requested):
			ui_prototype.upgrade_requested.connect(_on_prototype_upgrade_requested)
		if not ui_prototype.research_requested.is_connected(_on_prototype_research_requested):
			ui_prototype.research_requested.connect(_on_prototype_research_requested)
		if not ui_prototype.prestige_requested.is_connected(_on_prototype_prestige_requested):
			ui_prototype.prestige_requested.connect(_on_prototype_prestige_requested)
		if not ui_prototype.save_export_requested.is_connected(_on_prototype_export_requested):
			ui_prototype.save_export_requested.connect(_on_prototype_export_requested)
		if not ui_prototype.save_import_requested.is_connected(_on_prototype_import_requested):
			ui_prototype.save_import_requested.connect(_on_prototype_import_requested)
		if not ui_prototype.settings_requested.is_connected(_on_settings_pressed):
			ui_prototype.settings_requested.connect(_on_settings_pressed)
		if not ui_prototype.layout_changed.is_connected(_on_prototype_layout_changed):
			ui_prototype.layout_changed.connect(_on_prototype_layout_changed)
		if not ui_prototype.automation_panel_opened.is_connected(_on_prototype_automation_panel_opened):
			ui_prototype.automation_panel_opened.connect(_on_prototype_automation_panel_opened)
		if not ui_prototype.automation_panel_closed.is_connected(_on_prototype_automation_panel_closed):
			ui_prototype.automation_panel_closed.connect(_on_prototype_automation_panel_closed)
		if not ui_prototype.automation_target_changed.is_connected(_on_prototype_automation_target_changed):
			ui_prototype.automation_target_changed.connect(_on_prototype_automation_target_changed)
		var proto_env := ui_prototype.get_environment_panel()
		if proto_env is EnvPanel:
			environment_panel = proto_env
		factory_viewport = ui_prototype.get_factory_viewport()
		if factory_viewport:
			if env_renderer_mode == "sandbox":
				_setup_sandbox_canvas(factory_viewport)
				if environment_root_node:
					environment_root_node.visible = false
			else:
				_move_environment_into_viewport(factory_viewport)
				if environment_root_node:
					environment_root_node.visible = true
			_update_factory_viewport_bounds()
		_set_prototype_visible(true)
	else:
		if legacy_ui_root:
			legacy_ui_root.visible = true
		environment_panel = get_node_or_null("%EnvironmentPanel") as EnvPanel
	if env_renderer_mode == "sandbox":
		if not sandbox_canvas or not is_instance_valid(sandbox_canvas):
			sandbox_canvas = SandboxCanvasScene.instantiate()
			add_child(sandbox_canvas)
			sandbox_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
			sandbox_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
			sandbox_renderer = sandbox_canvas as SandboxRenderer
			if sandbox_renderer and not sandbox_renderer.fallback_state_changed.is_connected(_on_sandbox_fallback_changed):
				sandbox_renderer.fallback_state_changed.connect(_on_sandbox_fallback_changed)
		if environment_root_node:
			environment_root_node.visible = false
	else:
		if environment_root_node:
			environment_root_node.visible = true
		sandbox_renderer = null

	if conveyor_manager:
		eco.register_conveyor_manager(conveyor_manager)
		if not eco.conveyor_metrics_changed.is_connected(_on_conveyor_metrics_changed):
			eco.conveyor_metrics_changed.connect(_on_conveyor_metrics_changed)
		var initial_queue := 0
		for belt in conveyor_manager.belts:
			if belt:
				initial_queue += belt.get_queue_length()
		_update_conveyor_view(conveyor_manager.items_per_second, initial_queue, false)
	else:
		eco.register_conveyor_manager(null)
		_update_conveyor_view(0.0, 0, false)

	settings_panel = SETTINGS_PANEL_SCENE.instantiate()
	add_child(settings_panel)
	settings_panel.hide()
	settings_panel.text_scale_selected.connect(_on_text_scale_selected)
	settings_panel.diagnostics_requested.connect(_on_diagnostics_requested)
	settings_panel.high_contrast_toggled.connect(_on_high_contrast_toggled)
	settings_panel.color_palette_selected.connect(_on_color_palette_selected)
	settings_panel.visuals_toggled.connect(_on_visuals_toggled)
	settings_panel.reset_requested.connect(_on_reset_requested)
	settings_panel.set_color_palette(color_palette)
	ArtRegistry.set_palette(color_palette)
	ProceduralFactory.set_palette(color_palette)
	settings_panel.set_high_contrast(high_contrast_enabled)
	settings_panel.set_visuals_enabled(visuals_enabled)

	if environment_panel and not environment_panel.preset_selected.is_connected(_on_environment_preset_selected):
		environment_panel.preset_selected.connect(_on_environment_preset_selected)

	debug_overlay = DEBUG_OVERLAY_SCENE.instantiate()
	add_child(debug_overlay)
	debug_overlay.visible = false
	debug_overlay.configure(eco, res, sav, bal)

	var logger := _get_logger()
	if logger:
		logger.setup(logging_enabled, logging_force_disable)
	text_scale = 1.0
	_log("INFO", "CONFIG", "Active seed", {"seed": seed, "logging_enabled": logging_enabled, "force_disabled": logging_force_disable})

	var strings := _get_strings()
	if strings:
		strings.load("res://game/data/strings_egg.tsv")
	if environment_panel:
		environment_panel.set_strings(strings)

	var director := _get_visual_director()
	if director:
		director.set_sources(eco, strings)
		director.set_high_contrast(high_contrast_enabled)
		director.activate("feed_particles", visuals_enabled)

	environment_service = _get_environment_service()
	power_service = _get_power_service()
	automation_service = _get_automation_service()
	sandbox_service = _get_sandbox_service()
	if sandbox_service:
		sandbox_service.register_gameplay_services(power_service, eco)
		_connect_sandbox_event_signals()
	if automation_panel_ui:
		automation_panel_ui.attach_services(eco, conveyor_manager, automation_service)
		if not automation_panel_ui.automation_panel_opened.is_connected(_on_prototype_automation_panel_opened):
			automation_panel_ui.automation_panel_opened.connect(_on_prototype_automation_panel_opened)
		if not automation_panel_ui.automation_panel_closed.is_connected(_on_prototype_automation_panel_closed):
			automation_panel_ui.automation_panel_closed.connect(_on_prototype_automation_panel_closed)
		if not automation_panel_ui.automation_target_changed.is_connected(_on_prototype_automation_target_changed):
			automation_panel_ui.automation_target_changed.connect(_on_prototype_automation_target_changed)
	if environment_service:
		environment_service.set_strings(strings)
		var env_root := environment_root_node
		if env_root:
			environment_service.register_environment_root(env_root)
			_center_environment_root()
			var viewport := get_viewport()
			if viewport and not viewport.size_changed.is_connected(_on_viewport_size_changed):
				viewport.size_changed.connect(_on_viewport_size_changed)
		if not environment_service.environment_updated.is_connected(_on_environment_state_changed):
			environment_service.environment_updated.connect(_on_environment_state_changed)
		if not environment_service.day_phase_changed.is_connected(_on_environment_phase_changed):
			environment_service.day_phase_changed.connect(_on_environment_phase_changed)
		if not environment_service.preset_changed.is_connected(_on_environment_preset_changed):
			environment_service.preset_changed.connect(_on_environment_preset_changed)
		if environment_panel:
			environment_panel.set_presets(environment_service.get_preset_options())
			environment_panel.select_preset(environment_service.get_preset())
		var env_state: Dictionary = environment_service.get_state()
		if not env_state.is_empty():
			_on_environment_state_changed(env_state)
	if power_service:
		if not power_service.power_state_changed.is_connected(_on_power_state_changed):
			power_service.power_state_changed.connect(_on_power_state_changed)
		if not power_service.power_warning.is_connected(_on_power_warning):
			power_service.power_warning.connect(_on_power_warning)
		_power_warning_level = power_service.current_warning_level()
		_apply_power_warning_visuals(_power_warning_level)
	if sandbox_service and not sandbox_service.ci_changed.is_connected(_on_ci_changed):
		sandbox_service.ci_changed.connect(_on_ci_changed)
	if environment_panel and sandbox_service:
		environment_panel.update_comfort(sandbox_service.current_ci(), sandbox_service.current_bonus(), sandbox_service.last_comfort_components())

	if ui_prototype:
		_sync_prototype_all()

	sav.load_state()
	_tier_one_unlocked = sav.tier_progress >= 1
	_apply_tier_progression()
	_sync_automation_panel_from_economy()
	_update_telemetry_context()
	var offline_summary: Dictionary = sav.apply_offline_rewards()
	if float(offline_summary.get("grant", 0.0)) > 0.0:
		_show_offline_popup(offline_summary)

	apply_text_scale(text_scale)
	_apply_contrast_theme()
	_apply_strings()
	_apply_hud_flags()
	_update_all_views()
	_update_feed_ui()
	if feed_hint_label:
		feed_hint_label.visible = false
	if toast_label:
		toast_label.visible = false
		toast_label.modulate = Color(1, 1, 1, 0)
	if capacity_pulse_label:
		capacity_pulse_label.visible = false
		capacity_pulse_label.modulate = Color(1, 1, 1, 0)

		_log("INFO", "THEME", "Theme applied", {
			"currency": "Egg Credits",
			"prestige": "Reputation Stars"
		})
	_log("INFO", "STRINGS", "UI copy refreshed", {"scene": "Main"})
	sav.save("startup")

func _process(delta: float) -> void:
	_update_feed_ui()
	_update_conveyor_spawn(delta)
	_update_tier_progress(delta)
	_update_micro_events(delta)
	_automation_refresh_timer += delta
	if _automation_refresh_timer >= 0.5:
		_automation_refresh_timer = 0.0
		_refresh_prototype_automation_sheet()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if settings_panel and settings_panel.visible:
			settings_panel.hide()
			get_tree().set_input_as_handled()
			return
		if ui_prototype and ui_prototype.get_current_tab() != "home":
			ui_prototype.show_tab("home")
			get_tree().set_input_as_handled()
			return
	if event.is_action_pressed("feed_hold") or event.is_action_pressed("burst_hold"):
		_attempt_feed_start("input")
	if event.is_action_released("feed_hold") or event.is_action_released("burst_hold"):
		eco.stop_burst("input")
		_update_feed_ui()
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == Key.KEY_F3:
			debug_overlay.visible = not debug_overlay.visible
		elif event.keycode == Key.KEY_ESCAPE and settings_panel.visible:
			settings_panel.hide()

func _on_balance_reload() -> void:
	_log("INFO", "BALANCE", "Hot reload acknowledged", {
		"md5": _hash_from_logger("res://data/balance.tsv")
	})
	_apply_strings()
	_apply_hud_flags()
	_update_all_views()

func _on_shop_state_changed(_id: String) -> void:
	_update_upgrade_buttons()

func _on_soft_changed(value: float) -> void:
	_update_soft_view(value)
	_update_prestige_view()
	_update_upgrade_buttons()

func _on_storage_changed(value: float, capacity: float) -> void:
	_update_storage_view(value, capacity)

func _on_dump_triggered(amount: float, _new_balance: float) -> void:
	if not _show_cap_pulse:
		return
	if eco == null:
		return
	if capacity_bar == null:
		return
	if amount <= 0.0:
		return
	var template := _strings_get("storage_dump_message", "Shipment sent! +{amount}")
	var message := template.format({"amount": _format_num(amount)})
	if capacity_bar and capacity_bar.has_method("play_dump_pulse"):
		capacity_bar.call("play_dump_pulse", eco.dump_animation_ms(), message)

func _on_ship_now_pressed() -> void:
	if eco == null:
		return
	var _payout := eco.manual_ship_now()

func _apply_strings() -> void:
	btn_settings.text = _strings_get("settings_button", btn_settings.text)
	btn_export.text = _strings_get("export_button", btn_export.text)
	btn_import.text = _strings_get("import_button", btn_import.text)
	btn_ship_now.text = _strings_get("ship_now_button", btn_ship_now.text)
	if btn_automation_panel:
		btn_automation_panel.text = _strings_get("automation_panel_open_button", btn_automation_panel.text)
	research_header_label.text = _strings_get("research_header_title", research_header_label.text)
	var close_text := _strings_get("close_button", offline_close.text)
	offline_close.text = close_text
	btn_burst.text = _strings_get("burst_button", btn_burst.text)
	settings_panel.populate_strings()
	var strings := _get_strings()
	if strings and environment_panel:
		environment_panel.set_strings(strings)
	_update_conveyor_view(_conveyor_rate, _conveyor_queue, _conveyor_jam)

func _apply_hud_flags() -> void:
	if bal == null:
		return
	var show_pps: bool = bool(bal.hud_flags.get("SHOW_PPS_LABEL", true))
	if lbl_pps:
		lbl_pps.visible = show_pps
	var show_storage: bool = bool(bal.hud_flags.get("SHOW_STORAGE_BAR", true))
	if capacity_container:
		capacity_container.visible = show_storage
	var show_cap: bool = bool(bal.hud_flags.get("SHOW_CAP_PULSE", true))
	_show_cap_pulse = show_cap
	if capacity_bar and capacity_bar.has_method("set_pulse_enabled"):
		capacity_bar.call("set_pulse_enabled", show_cap)
	if not show_cap and capacity_pulse_label:
		capacity_pulse_label.visible = false
		capacity_pulse_label.modulate = Color(1, 1, 1, 0)

func _update_all_views() -> void:
	_update_soft_view(eco.soft)
	_update_storage_view()
	_update_prestige_view()
	_update_upgrade_buttons()
	_update_factory_view()
	_update_research_view()
	_update_feed_ui()
	_update_conveyor_view(_conveyor_rate, _conveyor_queue, _conveyor_jam)
	_update_power_label()

func _update_soft_view(value: float) -> void:
	var soft_template := _strings_get("soft_label_wallet", "Egg Credits: {value}")
	lbl_soft.text = soft_template.format({
		"value": _format_num(value)
	})
	_set_prototype_status("economy", "₡ %s" % _format_num(value))
	var pps_template := _strings_get("pps_label", "Egg Flow: {pps}/s")
	lbl_pps.text = pps_template.format({
		"pps": _format_num(eco.current_pps(), 1)
	})
	_update_power_label()
	_prototype_metrics["credits"] = "₡ " + _format_num(value)
	_prototype_metrics["pps"] = _format_num(eco.current_pps(), 1) + " PPS"
	_commit_prototype_metrics()
	_refresh_prototype_home_sheet()

func _update_prestige_view() -> void:
	var next: int = eco.prestige_points_earned()
	var prestige_template := _strings_get("prestige_label", "Reputation Stars: {prestige} (Next Rebrand: +{next})")
	lbl_prestige.text = prestige_template.format({
		"prestige": res.prestige_points,
		"next": next
	})
	btn_prestige.disabled = next <= 0
	var prestige_key := "prestige_button_locked"
	if next > 0:
		prestige_key = "prestige_button_ready"
	btn_prestige.text = _strings_get(prestige_key, btn_prestige.text)
	_refresh_prototype_home_sheet()
	_refresh_prototype_prestige_sheet()

func _update_factory_view() -> void:
	var name: String = eco.factory_name()
	var stage_template := _strings_get("farm_stage", "Farm Stage: {name}")
	lbl_tier.text = stage_template.format({"name": name})
	var next_cost: float = eco.next_factory_cost()
	var next_name: String = eco.factory_name(eco.factory_tier + 1)
	if next_cost <= 0.0:
		btn_promote.text = _strings_get("promote_disabled", "Stage Mastered")
		btn_promote.disabled = true
	else:
		var label_name: String = next_name
		if label_name == "":
			label_name = _strings_get("promote", "Next Stage")
		var promote_template := _strings_get("promote_button", "Upgrade to {name} ({cost} 🥚)")
		btn_promote.text = promote_template.format({
			"name": label_name,
			"cost": _format_num(next_cost)
		})
		btn_promote.disabled = eco.soft + 1e-6 < next_cost
	var population_estimate := int(round(eco.feed_capacity))
	_set_prototype_status("population", "%s hens" % _format_num(float(population_estimate), 0))
	_refresh_prototype_home_sheet()

func _update_conveyor_view(rate: float, queue_len: int, jam_active: bool = false) -> void:
	_conveyor_rate = rate
	_conveyor_queue = queue_len
	_conveyor_jam = jam_active
	if lbl_conveyor == null:
		return
	var template_key := "conveyor_label"
	var fallback := "Conveyor: {rate}/s | Queue {queue}"
	if jam_active:
		template_key = "conveyor_label_warning"
		fallback = "Conveyor: {rate}/s | Queue {queue} ⚠"
	var template := _strings_get(template_key, fallback)
	lbl_conveyor.text = template.format({
		"rate": _format_num(rate, 1),
		"queue": queue_len
	})
	if jam_active:
		lbl_conveyor.add_theme_color_override("font_color", Color(1.0, 0.5, 0.0))
	else:
		lbl_conveyor.remove_theme_color_override("font_color")
	_update_power_label()

func _update_conveyor_spawn(delta: float) -> void:
	if not visuals_enabled:
		return
	if conveyor_manager == null or conveyor_manager.belts.is_empty():
		return
	var belt: ConveyorBelt = conveyor_manager.belts[0]
	if belt == null:
		return
	var pps: float = max(eco.current_pps(), 0.0)
	if pps <= 0.0:
		return
	_conveyor_spawn_accumulator += pps * delta
	var spawn_count := int(_conveyor_spawn_accumulator)
	if spawn_count <= 0:
		return
	_conveyor_spawn_accumulator -= spawn_count
	var max_spawns := 40
	if spawn_count > max_spawns:
		spawn_count = max_spawns
	for _i in range(spawn_count):
		var item := conveyor_manager.spawn_item(&"egg", belt)
		if item:
			if _conveyor_colors.size() > 0:
				var color: Color = _conveyor_colors[_conveyor_color_index % _conveyor_colors.size()]
				item.set_tint(color)
				_conveyor_color_index = (_conveyor_color_index + 1) % _conveyor_colors.size()

func _update_upgrade_buttons() -> void:
	if shop_service == null:
		_update_upgrade_buttons_legacy()
		return
	_apply_shop_button(btn_prod, "prod_1", "buy_prod")
	_apply_shop_button(btn_cap, "cap_1", "buy_cap")
	_apply_shop_button(btn_feed, "feed_storage", "buy_feed")
	_apply_auto_button()
	_refresh_prototype_store_sheet()
	_refresh_prototype_automation_sheet()

func _update_upgrade_buttons_legacy() -> void:
	var prod_data: Dictionary = {}
	if bal.upgrades.has("prod_1"):
		prod_data = bal.upgrades["prod_1"]
	var cap_data: Dictionary = {}
	if bal.upgrades.has("cap_1"):
		cap_data = bal.upgrades["cap_1"]
	var feed_data: Dictionary = {}
	if bal.upgrades.has("feed_storage"):
		feed_data = bal.upgrades["feed_storage"]
	var prod_cost: float = eco.upgrade_cost("prod_1")
	var cap_cost: float = eco.upgrade_cost("cap_1")
	var feed_cost: float = eco.upgrade_cost("feed_storage")
	var auto_cost: float = eco.upgrade_cost("auto_1")
	var prod_template: String = _strings_get("buy_prod", btn_prod.text)
	var cap_template: String = _strings_get("buy_cap", btn_cap.text)
	var feed_template: String = _strings_get("buy_feed", btn_feed.text)
	var prod_visible: bool = bool(prod_data.get("visible", true))
	var cap_visible: bool = bool(cap_data.get("visible", true))
	var feed_visible: bool = bool(feed_data.get("visible", true))
	btn_prod.visible = prod_visible
	btn_cap.visible = cap_visible
	btn_feed.visible = feed_visible
	var prod_text: String = prod_template.format({"cost": _format_num(prod_cost)})
	var cap_text: String = cap_template.format({"cost": _format_num(cap_cost)})
	var feed_text: String = feed_template.format({"cost": _format_num(feed_cost)})
	if prod_visible:
		btn_prod.text = prod_text
	else:
		btn_prod.tooltip_text = ""
	if cap_visible:
		btn_cap.text = cap_text
	else:
		btn_cap.tooltip_text = ""
	if feed_visible:
		btn_feed.text = feed_text
	else:
		btn_feed.tooltip_text = ""
	var auto_allowed: bool = eco.can_purchase_upgrade("auto_1")
	if prod_visible:
		btn_prod.disabled = (not eco.can_purchase_upgrade("prod_1")) or eco.soft + 1e-6 < prod_cost
		btn_prod.tooltip_text = prod_text
	else:
		btn_prod.disabled = true
	if cap_visible:
		btn_cap.disabled = (not eco.can_purchase_upgrade("cap_1")) or eco.soft + 1e-6 < cap_cost
		btn_cap.tooltip_text = cap_text
	else:
		btn_cap.disabled = true
	if feed_visible:
		btn_feed.disabled = (not eco.can_purchase_upgrade("feed_storage")) or eco.soft + 1e-6 < feed_cost
		btn_feed.tooltip_text = feed_text
	else:
		btn_feed.disabled = true
	var auto_requires: String = String(bal.upgrades.get("auto_1", {}).get("requires", "-"))
	var requirement_text: String = ""
	if not auto_allowed and auto_requires.begins_with("factory>="):
		var parts: PackedStringArray = auto_requires.split(">=")
		if parts.size() >= 2:
			var need: int = int(parts[1])
			var stage_name: String = eco.factory_name(need)
			if stage_name != "":
				requirement_text = _strings_get("buy_auto_requirement", " — Requires {stage}").format({"stage": stage_name})
	btn_auto.text = _strings_get("buy_auto", btn_auto.text).format({
		"cost": _format_num(auto_cost),
		"requirement": requirement_text
	})
	btn_auto.disabled = (not auto_allowed) or eco.soft + 1e-6 < auto_cost
	btn_auto.tooltip_text = btn_auto.text
	_refresh_prototype_store_sheet()
	_refresh_prototype_automation_sheet()

func _apply_shop_button(button: Button, id: String, template_key: String) -> void:
	var state: Dictionary = shop_service.get_item_state(id)
	var visible: bool = bool(state.get("visible", true))
	button.visible = visible
	if not visible:
		button.disabled = true
		button.tooltip_text = ""
		return
	var price_text: String = _format_num(float(state.get("price", 0.0)))
	var template: String = _strings_get(template_key, button.text)
	var label: String = template.format({"cost": price_text})
	button.text = label
	var enabled: bool = bool(state.get("enabled", false))
	button.disabled = not enabled
	var tooltip: String = label
	var reason_text: String = String(state.get("reason_text", ""))
	if not enabled and reason_text != "":
		tooltip += "\n" + reason_text
	button.tooltip_text = tooltip

func _apply_auto_button() -> void:
	var state: Dictionary = shop_service.get_item_state("auto_1")
	var visible: bool = bool(state.get("visible", true))
	btn_auto.visible = visible
	if not visible:
		btn_auto.disabled = true
		btn_auto.tooltip_text = ""
		return
	var requirement_text: String = ""
	if int(state.get("stage_required", 0)) > 0 and not bool(state.get("stage_ok", true)):
		var stage_name: String = String(state.get("stage_name", ""))
		if stage_name == "":
			stage_name = shop_service.stage_display_name(int(state.get("stage_required", 0)))
		var requirement_template := _strings_get("buy_auto_requirement", " — Requires {stage}")
		requirement_text = requirement_template.format({"stage": stage_name})
	var label_template := _strings_get("buy_auto", btn_auto.text)
	btn_auto.text = label_template.format({
		"cost": _format_num(state.get("price", 0.0)),
		"requirement": requirement_text
	})
	var enabled: bool = bool(state.get("enabled", false))
	btn_auto.disabled = not enabled
	var tooltip: String = btn_auto.text
	var reason_text: String = String(state.get("reason_text", ""))
	if not enabled and reason_text != "":
		tooltip += "\n" + reason_text
	btn_auto.tooltip_text = tooltip

func _update_research_view() -> void:
	lbl_research.text = _strings_get("research_header", "Innovation Lab — Research Points: {points}").format({
		"points": res.prestige_points
	})
	var mapping: Dictionary = {
		"r_prod_1": _strings_get("research_prod_label", "Feed Conversion R&D"),
		"r_cap_1": _strings_get("research_cap_label", "Modular Coops"),
		"r_auto_1": _strings_get("research_auto_label", "Drone Feeders")
	}
	var nodes: Array[Dictionary] = [
		{"id": "r_prod_1", "button": btn_r_prod},
		{"id": "r_cap_1", "button": btn_r_cap},
		{"id": "r_auto_1", "button": btn_r_auto},
	]
	for entry in nodes:
		var entry_dict: Dictionary = entry
		var node_id := String(entry_dict.get("id", ""))
		var button := entry_dict.get("button", null) as Button
		if button == null:
			continue
		var label: String = String(mapping.get(node_id, node_id))
		if res.owned.has(node_id):
			button.text = _strings_get("research_owned", "{label} ✅").format({"label": label})
			button.disabled = true
		else:
			var cost: int = _research_cost(node_id)
			button.text = _strings_get("research_available", "{label} ({cost} 🌟)").format({
				"label": label,
				"cost": cost
			})
			button.disabled = not res.can_buy(node_id)
	_prototype_metrics["research"] = _format_num(res.prestige_points, 0) + " RP"
	_commit_prototype_metrics()
	_refresh_prototype_research_sheet()

func _update_storage_view(storage_value: float = -1.0, capacity: float = -1.0) -> void:
	if eco == null:
		return
	var cap: float = capacity if capacity >= 0.0 else eco.get_capacity_limit()
	var storage: float = storage_value if storage_value >= 0.0 else eco.current_storage()
	if capacity_bar:
		capacity_bar.max_value = max(cap, 1.0)
		capacity_bar.value = clamp(storage, 0.0, capacity_bar.max_value)
	var percent: float = 0.0
	if cap > 0.0:
		percent = clamp(storage / cap * 100.0, 0.0, 100.0)
	var capacity_template: String = _strings_get("storage_label", "Storage: {storage} / {capacity} ({percent}%)")
	var formatted: String = capacity_template.format({
		"storage": _format_num(storage, 1),
		"capacity": _format_num(cap, 1),
		"percent": _format_num(percent, 0)
	})
	if capacity_label:
		capacity_label.text = formatted
		capacity_label.tooltip_text = formatted
		if capacity_bar:
			capacity_bar.tooltip_text = formatted
		if btn_ship_now:
			var efficiency_pct: float = eco.manual_ship_efficiency() * 100.0
			var efficiency_precision: int = 0 if efficiency_pct >= 10.0 else 1
			var efficiency_formatted: String = _format_num(efficiency_pct, efficiency_precision)
			var ready_tooltip_template: String = _strings_get("ship_now_tooltip_ready", btn_ship_now.tooltip_text)
			var ready_tooltip: String = ready_tooltip_template.format({"efficiency": efficiency_formatted})
			if storage <= 0.5:
				btn_ship_now.disabled = true
				btn_ship_now.tooltip_text = _strings_get("ship_now_tooltip_empty", ready_tooltip)
			else:
				btn_ship_now.disabled = false
				btn_ship_now.tooltip_text = ready_tooltip
	_prototype_metrics["storage"] = formatted
	_commit_prototype_metrics()
	_refresh_prototype_home_sheet()

func _update_feed_ui() -> void:
	var fraction: float = eco.get_feed_fraction()
	feed_bar.max_value = 1.0
	feed_bar.value = fraction
	var percent: int = int(round(fraction * 100.0))
	var status: String = ""
	if eco.is_feeding():
		var bonus: float = max(0.0, eco.current_pps() - eco.current_base_pps())
		status = _strings_get("feeding_now", feed_status_label.text).format({"pps": _format_num(bonus, 1)})
	elif fraction <= 0.001:
		status = _strings_get("feed_empty", feed_status_label.text)
	elif percent >= 100:
		status = _strings_get("feed_bar_label", feed_status_label.text)
	else:
		status = _strings_get("feed_refilling", feed_status_label.text).format({"pct": percent})
	feed_status_label.text = status
	feed_status_label.tooltip_text = status
	feed_bar.tooltip_text = status
	if feed_hint_label:
		if eco.is_feeding():
			var boost: float = max(eco.current_pps() - eco.current_base_pps(), 0.0)
			if boost > 0.0:
				var hint_template: String = _strings_get("feed_hint_boost", "+{pps}/s boost")
				var hint_text: String = hint_template.format({"pps": _format_num(boost, 1)})
				feed_hint_label.text = hint_text
				feed_hint_label.tooltip_text = hint_text
				feed_hint_label.visible = true
			else:
				feed_hint_label.visible = false
				feed_hint_label.tooltip_text = ""
		else:
			feed_hint_label.visible = false
			feed_hint_label.tooltip_text = ""
	var fill_style: StyleBox = ArtRegistry.get_style("ui_progress_fill", high_contrast_enabled)
	if fill_style is StyleBoxFlat:
		(fill_style as StyleBoxFlat).bg_color = ProceduralFactory.feed_fill_color(fraction, high_contrast_enabled)
	feed_bar.add_theme_stylebox_override("fill", fill_style)
	if feed_bar.modulate != Color.WHITE:
		feed_bar.modulate = Color.WHITE
	_prototype_feed_status = status
	_prototype_feed_fraction = fraction
	if eco.is_feeding():
		_prototype_feed_queue = 1
	elif eco.feed_current <= 0.0:
		_prototype_feed_queue = 0
	else:
		_prototype_feed_queue = 0
	if _prototype_available():
		ui_prototype.set_feed_status(status, fraction, eco.is_feeding())
		ui_prototype.set_feed_queue(_prototype_feed_queue)
		ui_prototype.set_canvas_message(status)
	_update_power_label()
	_refresh_prototype_home_sheet()

func _prototype_available() -> bool:
	return ui_prototype != null

func _commit_prototype_metrics() -> void:
	if not _prototype_available():
		return
	ui_prototype.set_metrics(_prototype_metrics)
	_commit_prototype_status()

func _commit_prototype_status() -> void:
	if not _prototype_available():
		return
	ui_prototype.set_status(_prototype_status)


func _set_prototype_status(key: String, value: String, tone: String = "normal", tooltip: String = "") -> void:
	_prototype_status[key] = {
		"value": value,
		"tone": StringName(tone),
		"tooltip": tooltip
	}
	_commit_prototype_status()

func _sync_prototype_all() -> void:
	_commit_prototype_metrics()
	_refresh_prototype_home_sheet()
	_refresh_prototype_store_sheet()
	_refresh_prototype_research_sheet()
	_refresh_prototype_prestige_sheet()
	_refresh_prototype_automation_sheet()
	if _prototype_available():
		var feeding: bool = eco != null and eco.is_feeding()
		ui_prototype.set_feed_status(_prototype_feed_status, _prototype_feed_fraction, feeding)
		ui_prototype.set_feed_queue(_prototype_feed_queue)
		ui_prototype.set_canvas_message(_prototype_feed_status)

func _set_prototype_visible(visible: bool) -> void:
	if legacy_ui_root:
		legacy_ui_root.visible = not visible
	if _prototype_available():
		ui_prototype.visible = visible
		if visible:
			_sync_prototype_all()
			_center_environment_root()
func _prototype_button_state(button: Button) -> Dictionary:
	if button == null:
		return {}
	return {
		"text": button.text,
		"disabled": button.disabled,
		"tooltip": button.tooltip_text,
		"visible": button.visible
	}

func _refresh_prototype_home_sheet() -> void:
	if not _prototype_available():
		return
	var utilities := {
		"export": _prototype_button_state(btn_export),
		"import": _prototype_button_state(btn_import),
		"settings": _prototype_button_state(btn_settings)
	}
	var hint_text := ""
	if feed_hint_label and feed_hint_label.visible:
		hint_text = feed_hint_label.text
	var home_payload := {
		"soft": lbl_soft.text,
		"storage": capacity_label.text,
		"stage": lbl_tier.text,
		"prestige": lbl_prestige.text,
		"feed_status": feed_status_label.text,
		"feed_hint": hint_text,
		"feed_fraction": _prototype_feed_fraction,
		"feed_style": feed_bar.get_theme_stylebox("fill"),
		"queue": _prototype_feed_queue,
		"feed_button": _prototype_button_state(btn_burst),
		"promote_button": _prototype_button_state(btn_promote),
		"utilities": utilities
	}
	ui_prototype.update_home(home_payload)

func _refresh_prototype_store_sheet() -> void:
	if not _prototype_available():
		return
	var buttons := {
		"prod_1": _prototype_button_state(btn_prod),
		"cap_1": _prototype_button_state(btn_cap),
		"auto_1": _prototype_button_state(btn_auto)
	}
	ui_prototype.update_store(buttons)

func _refresh_prototype_research_sheet() -> void:
	if not _prototype_available():
		return
	var buttons := {
		"r_prod_1": _prototype_button_state(btn_r_prod),
		"r_cap_1": _prototype_button_state(btn_r_cap),
		"r_auto_1": _prototype_button_state(btn_r_auto)
	}
	var payload := {
		"summary": lbl_research.text,
		"buttons": buttons
	}
	ui_prototype.update_research(payload)

func _refresh_prototype_prestige_sheet() -> void:
	if not _prototype_available():
		return
	var payload := {
		"status": lbl_prestige.text,
		"button": _prototype_button_state(btn_prestige)
	}
	ui_prototype.update_prestige(payload)

func _refresh_prototype_automation_sheet() -> void:
	if not _prototype_available():
		return
	var payload := {
		"info": _automation_info_text(),
		"buttons": {
			"auto_1": _prototype_button_state(btn_auto)
		}
	}
	ui_prototype.update_automation(payload)

func _automation_info_text() -> String:
	if automation_service == null or not is_instance_valid(automation_service):
		automation_service = _get_automation_service()
	if automation_service == null:
		return _strings_get("automation_info_unavailable", "Automation service unavailable")
	var snapshot: Dictionary = automation_service.snapshot()
	var lines: Array[String] = []
	var global_enabled := bool(snapshot.get("global_enabled", true))
	var power_ok := bool(snapshot.get("power_ok", true))
	var state_key := "automation_state_enabled" if global_enabled else "automation_state_disabled"
	var state_text := _strings_get(state_key, "Automation enabled" if global_enabled else "Automation paused")
	if not power_ok:
		var power_suffix := _strings_get("automation_state_power_limited", " — limited by power")
		state_text += power_suffix
	lines.append(state_text)
	var targets_variant: Variant = snapshot.get("targets", {})
	if targets_variant is Dictionary:
		var targets_dict: Dictionary = targets_variant
		for key_variant in targets_dict.keys():
			var target_data: Dictionary = targets_dict[key_variant]
			var name := _automation_target_label(String(key_variant))
			var mode := int(target_data.get("mode", AutomationService.MODE_MANUAL))
			var interval := float(target_data.get("interval", 0.0))
			var remaining := float(target_data.get("remaining", interval))
			var mode_label := _automation_mode_label(mode)
			var line := "%s: %s" % [name, mode_label]
			if mode == AutomationService.MODE_AUTO and global_enabled and power_ok and interval > 0.0:
				var decimals := 0 if remaining >= 10.0 else 1
				line += " — " + _strings_get("automation_next_action", "next in {seconds}s").format({"seconds": _format_num(remaining, decimals)})
			lines.append(line)
	return "\n".join(lines)

func _automation_target_label(key: String) -> String:
	var mapping := {
		"economy_feed_autoburst": _strings_get("automation_target_autoburst", "Auto-feed bursts")
	}
	return String(mapping.get(key, key.capitalize()))

func _automation_mode_label(mode: int) -> String:
	match mode:
		AutomationService.MODE_AUTO:
			return _strings_get("automation_mode_auto", "Auto")
		AutomationService.MODE_MANUAL:
			return _strings_get("automation_mode_manual", "Manual")
		AutomationService.MODE_OFF:
			return _strings_get("automation_mode_off", "Off")
		_:
			return str(mode)

func _on_prototype_feed_requested() -> void:
	_attempt_feed_start("prototype")

func _on_prototype_feed_hold_started() -> void:
	_on_feed_button_down()

func _on_prototype_feed_hold_ended() -> void:
	_on_feed_button_up()

func _on_prototype_promote_requested() -> void:
	_attempt_promote()

func _on_prototype_upgrade_requested(upgrade_id: String) -> void:
	_attempt_upgrade(upgrade_id)

func _on_prototype_research_requested(research_id: String) -> void:
	_attempt_research(research_id)

func _on_prototype_prestige_requested() -> void:
	_attempt_prestige()

func _on_prototype_export_requested() -> void:
	sav.export_to_clipboard()

func _on_prototype_import_requested() -> void:
	sav.import_from_clipboard()

func _on_prototype_layout_changed() -> void:
	_update_factory_viewport_bounds()
	_center_environment_root()

func _on_automation_panel_button_pressed() -> void:
	if automation_panel_ui:
		automation_panel_ui.show_panel()

func _on_prototype_automation_panel_opened() -> void:
	var service := _get_automation_service()
	if service:
		service.set_panel_visible(true)
		if automation_panel_ui:
			automation_panel_ui.set_toggle_state(service.is_global_enabled())
	_sync_automation_panel_from_economy()

func _on_prototype_automation_panel_closed() -> void:
	var service := _get_automation_service()
	if service:
		service.set_panel_visible(false)

func _on_prototype_automation_target_changed(button_id: StringName) -> void:
	var target_variant: Variant = AUTOMATION_BUTTON_TARGETS.get(button_id, button_id)
	var target: StringName = StringName(target_variant)
	var service := _get_automation_service()
	if service:
		service.set_panel_target(target)

func _on_high_contrast_toggled(enabled: bool) -> void:
	high_contrast_enabled = enabled
	_apply_contrast_theme()
	var director := _get_visual_director()
	if director:
		director.set_high_contrast(enabled)
	if environment_panel:
		environment_panel.set_high_contrast(enabled)
	if settings_panel:
		settings_panel.set_high_contrast(high_contrast_enabled)

func _on_color_palette_selected(palette: StringName) -> void:
	_apply_palette_change(palette)

func _on_feed_state_changed(_active: bool) -> void:
	_update_feed_ui()

func _on_conveyor_metrics_changed(rate: float, queue_len: int, jam_active: bool) -> void:
	_update_conveyor_view(rate, queue_len, jam_active)

func _on_economy_rate_changed(rate: float, label: String) -> void:
	var decimals := 0 if abs(rate) >= 10.0 else 1
	var formatted_value := _format_num(rate, decimals)
	var slot_label: String = _strings_get("hud_slot_d_economy_rate", label).format({"value": formatted_value})
	var tooltip: String = _strings_get("hud_slot_d_tooltip", slot_label)
	var tone := StringName("normal")
	if rate < 0.1:
		tone = StringName("critical")
	elif rate < 0.5:
		tone = StringName("warning")
	_economy_tone = tone
	_set_prototype_status("economy_rate", slot_label, String(tone), tooltip)
	if lbl_pps:
		lbl_pps.text = slot_label
		lbl_pps.tooltip_text = tooltip
	if ui_prototype:
		ui_prototype.set_status(StringName("economy_rate"), slot_label, tooltip)
	if automation_panel_ui:
		automation_panel_ui.update_economy_rate(slot_label)
	if _tier_rate_samples == 0:
		_economy_rate_avg = rate
	else:
		_economy_rate_avg = lerp(_economy_rate_avg, rate, 0.1)
	_tier_rate_samples = min(_tier_rate_samples + 1, 100000)

func _on_conveyor_backlog_changed(queue_len: int, label: String, tone: StringName) -> void:
	var tone_string := String(tone)
	var value_key := "hud_slot_f_backlog_warning" if tone_string == "warning" else "hud_slot_f_backlog_normal"
	var tooltip_key := "hud_slot_f_tooltip_warning" if tone_string == "warning" else "hud_slot_f_tooltip"
	var slot_label: String = _strings_get(value_key, label).format({"count": queue_len})
	var tooltip: String = _strings_get(tooltip_key, label).format({
		"count": queue_len,
		"threshold": CONVEYOR_JAM_WARNING_THRESHOLD
	})
	_set_prototype_status("conveyor_backlog", slot_label, tone_string, tooltip)
	_backlog_tone_runtime = tone
	if lbl_conveyor:
		lbl_conveyor.text = slot_label
		lbl_conveyor.tooltip_text = tooltip
	if automation_panel_ui:
		automation_panel_ui.update_backlog(slot_label, tone)

func _on_ci_changed(ci: float, bonus: float) -> void:
	_comfort_index = clamp(ci, 0.0, 1.0)
	_comfort_bonus = max(bonus, 0.0)
	if environment_panel:
		var metrics: Dictionary = {}
		if sandbox_service:
			metrics = sandbox_service.last_comfort_components()
		if sandbox_renderer and is_instance_valid(sandbox_renderer):
			var renderer_metrics: Dictionary = sandbox_renderer.get_renderer_metrics()
			for key in renderer_metrics.keys():
				metrics[key] = renderer_metrics[key]
		environment_panel.update_comfort(_comfort_index, _comfort_bonus, metrics)
	_update_power_label()
	if _prototype_available():
		var bonus_text: String = _format_num(_comfort_bonus * 100.0, 1)
		ui_prototype.set_canvas_hint("Comfort bonus +%s%%" % bonus_text)

func _on_sandbox_fallback_changed(_active: bool) -> void:
	if environment_panel == null:
		return
	var metrics: Dictionary = {}
	if sandbox_service:
		metrics = sandbox_service.last_comfort_components()
	if sandbox_renderer and is_instance_valid(sandbox_renderer):
		var renderer_metrics: Dictionary = sandbox_renderer.get_renderer_metrics()
		for key in renderer_metrics.keys():
			metrics[key] = renderer_metrics[key]
	environment_panel.update_comfort(_comfort_index, _comfort_bonus, metrics)

func _on_power_state_changed(state: float) -> void:
	_update_power_label()
	if automation_service:
		automation_service.set_power_state(state)

func _on_power_warning(level: StringName) -> void:
	_log("WARN", "POWER", "power_warning", {"level": str(level)})
	if level == _power_warning_level:
		return
	_power_warning_level = level
	_apply_power_warning_visuals(level)
	_update_power_label()
	_play_power_warning_sound(level)
	if level == PowerService.WARNING_CRITICAL:
		_show_toast(_strings_get("power_warning_critical", "Power grid critical!"))
	elif level == PowerService.WARNING_WARNING:
		_show_toast(_strings_get("power_warning_low", "Power grid unstable."))
	else:
		_show_toast(_strings_get("power_warning_recovered", "Power grid stabilized."))

func _on_visuals_toggled(enabled: bool) -> void:
	visuals_enabled = enabled
	var director := _get_visual_director()
	if director:
		director.activate("feed_particles", enabled)
	if conveyor_layer:
		conveyor_layer.visible = enabled
		if not enabled and conveyor_layer is FactoryConveyor:
			var fc := conveyor_layer as FactoryConveyor
			if fc.belt:
				fc.belt.clear_items()
	if not enabled:
		_conveyor_spawn_accumulator = 0.0

func _apply_power_warning_visuals(level: StringName) -> void:
	if lbl_power == null:
		return
	match level:
		PowerService.WARNING_CRITICAL:
			lbl_power.add_theme_color_override("font_color", POWER_CRITICAL_COLOR)
		PowerService.WARNING_WARNING:
			lbl_power.add_theme_color_override("font_color", POWER_WARNING_COLOR)
		_:
			lbl_power.remove_theme_color_override("font_color")

func _play_power_warning_sound(level: StringName) -> void:
	if power_warning_sound == null:
		return
	var clip: AudioStream = POWER_CRITICAL_CLIP if level == PowerService.WARNING_CRITICAL else POWER_WARNING_CLIP
	if clip == null:
		if not _power_warning_sound_warned:
			_power_warning_sound_warned = true
			_log("INFO", "AUDIO", "power_warning_sound_missing", {"level": str(level)})
		return
	if power_warning_sound.stream != clip:
		power_warning_sound.stream = clip
	if power_warning_sound.playing:
		power_warning_sound.stop()
	power_warning_sound.pitch_scale = 1.0
	power_warning_sound.play()

func _on_environment_state_changed(state: Dictionary) -> void:
	if environment_panel:
		environment_panel.update_state(state)

func _on_environment_phase_changed(_phase: StringName) -> void:
	if environment_service:
		var state: Dictionary = environment_service.get_state()
		if not state.is_empty():
			_on_environment_state_changed(state)

func _on_environment_preset_selected(preset_value: Variant) -> void:
	if environment_service == null:
		return
	var preset := StringName(preset_value)
	if preset == StringName():
		return
	environment_service.select_preset(preset)

func _on_environment_preset_changed(preset: StringName) -> void:
	if environment_panel:
		environment_panel.select_preset(preset)
	_center_environment_root()

func _apply_palette_change(palette: StringName) -> void:
	var resolved := ProceduralFactory.ensure_palette(palette)
	if color_palette == resolved:
		return
	color_palette = resolved
	ArtRegistry.set_palette(color_palette)
	ProceduralFactory.set_palette(color_palette)
	if settings_panel:
		settings_panel.set_color_palette(color_palette)
	_apply_contrast_theme()

func _apply_contrast_theme() -> void:
	ArtRegistry.set_palette(color_palette)
	ProceduralFactory.set_palette(color_palette)
	var panel_style := ArtRegistry.get_style("ui_panel", high_contrast_enabled)
	if panel_style:
		stats_box.add_theme_stylebox_override("panel", panel_style)
	var capacity_background := ArtRegistry.get_style("ui_progress_bg", high_contrast_enabled)
	var capacity_fill := ArtRegistry.get_style("ui_progress_fill", high_contrast_enabled)
	if capacity_fill is StyleBoxFlat:
		(capacity_fill as StyleBoxFlat).bg_color = ProceduralFactory.COLOR_ACCENT
	if capacity_background:
		capacity_bar.add_theme_stylebox_override("background", capacity_background)
	if capacity_fill:
		capacity_bar.add_theme_stylebox_override("fill", capacity_fill)
	var feed_background := ArtRegistry.get_style("ui_progress_bg", high_contrast_enabled)
	if feed_background:
		feed_bar.add_theme_stylebox_override("background", feed_background)
	var text_color := ProceduralFactory.COLOR_TEXT
	for label in [lbl_soft, capacity_label, feed_status_label, lbl_pps, lbl_tier, lbl_prestige, lbl_research, lbl_conveyor]:
		label.add_theme_color_override("font_color", text_color)
	if feed_hint_label:
		feed_hint_label.add_theme_color_override("font_color", text_color)
	_apply_button_styles()
	if environment_panel:
		environment_panel.set_high_contrast(high_contrast_enabled)
	_update_feed_ui()

func _apply_button_styles() -> void:
	var normal_style := ArtRegistry.get_style("ui_button", high_contrast_enabled)
	var hover_style := ArtRegistry.get_style("ui_button_hover", high_contrast_enabled)
	var pressed_style := ArtRegistry.get_style("ui_button_pressed", high_contrast_enabled)
	var font_color := ProceduralFactory.COLOR_TEXT
	var buttons: Array[Button] = [
		btn_burst,
		btn_prod,
		btn_cap,
		btn_auto,
		btn_promote,
		btn_prestige,
		btn_export,
		btn_import,
		btn_settings,
		btn_r_prod,
		btn_r_cap,
		btn_r_auto,
		offline_close
	]
	for button in buttons:
		if button == null:
			continue
		if normal_style:
			button.add_theme_stylebox_override("normal", normal_style)
		if hover_style:
			button.add_theme_stylebox_override("hover", hover_style)
		if pressed_style:
			button.add_theme_stylebox_override("pressed", pressed_style)
		button.add_theme_color_override("font_color", font_color)
	if _prototype_available():
		for proto_button in ui_prototype.get_action_buttons():
			if proto_button == null:
				continue
			if normal_style:
				proto_button.add_theme_stylebox_override("normal", normal_style)
			if hover_style:
				proto_button.add_theme_stylebox_override("hover", hover_style)
			if pressed_style:
				proto_button.add_theme_stylebox_override("pressed", pressed_style)
			proto_button.add_theme_color_override("font_color", font_color)

func _on_feed_button_down() -> void:
	_attempt_feed_start("button")

func _on_feed_button_up() -> void:
	eco.stop_burst("button")
	_update_feed_ui()

func _attempt_feed_start(source: String) -> void:
	if eco.feed_current <= 0.0:
		_handle_feed_denied()
		return
	var started: bool = eco.try_burst(source == "auto")
	if not started and not eco.is_feeding():
		_handle_feed_denied()
	_update_feed_ui()

func _handle_feed_denied() -> void:
	_flash_feed_bar()
	_play_feed_denied_sound()
	_log("WARN", "FEED", "start_denied", {
		"feed": eco.feed_current,
		"capacity": eco.feed_capacity
	})

func _flash_feed_bar() -> void:
	var tween := create_tween()
	tween.tween_property(feed_bar, "modulate", FEED_FLASH_COLOR, 0.1)
	tween.tween_property(feed_bar, "modulate", Color(1, 1, 1, 1), 0.25)

func _play_feed_denied_sound() -> void:
	if deny_sound == null:
		return
	if deny_sound.stream == null:
		if not _feed_deny_sound_warned:
			_feed_deny_sound_warned = true
			_log("INFO", "AUDIO", "feed_denied_sound_missing", {})
		return
	if deny_sound.playing:
		deny_sound.stop()
	deny_sound.play()

func _attempt_upgrade(id: String) -> void:
	if eco.buy_upgrade(id):
		_update_upgrade_buttons()
		_show_upgrade_toast(id)

func _attempt_research(id: String) -> void:
	if res.buy(id):
		eco.refresh_after_load()
		_update_research_view()
		_update_prestige_view()
		_update_upgrade_buttons()

func _attempt_promote() -> void:
	if eco.promote_factory():
		_update_factory_view()

func _attempt_prestige() -> void:
	var gained: int = eco.do_prestige()
	_log("INFO", "ECONOMY", "Prestige accepted", {"gained": gained})
	_update_all_views()

func _show_upgrade_toast(id: String) -> void:
	var key := _upgrade_toast_key(id)
	if key == "":
		return
	var message: String = _strings_get(key, "")
	if message == "":
		return
	_show_toast(message)

func _upgrade_toast_key(id: String) -> String:
	match id:
		"prod_1":
			return "toast_upgrade_prod"
		"cap_1":
			return "toast_upgrade_cap"
		"feed_storage":
			return "toast_upgrade_feed_storage"
		"feed_refill":
			return "toast_upgrade_feed_refill"
		"feed_efficiency":
			return "toast_upgrade_feed_efficiency"
		"auto_1":
			return "toast_upgrade_auto"
		_:
			return ""

func _show_toast(message: String) -> void:
	if toast_label == null:
		return
	toast_label.text = message
	toast_label.visible = true
	if _toast_tween and _toast_tween.is_running():
		_toast_tween.kill()
	var tween: Tween = create_tween()
	_toast_tween = tween
	toast_label.modulate = Color(1, 1, 1, 0)
	tween.tween_property(toast_label, "modulate:a", 1.0, 0.1)
	tween.tween_interval(0.8)
	tween.tween_property(toast_label, "modulate:a", 0.0, 0.1)
	tween.finished.connect(Callable(self, "_hide_toast"))

func _hide_toast() -> void:
	if toast_label:
		toast_label.visible = false
		toast_label.modulate = Color(1, 1, 1, 0)
	_toast_tween = null

func _show_offline_popup(summary: Dictionary) -> void:
	var amount: float = float(summary.get("grant", 0.0))
	var passive_pct: float = float(summary.get("passive_multiplier", eco.last_offline_passive_multiplier())) * 100.0
	var decimals: int = 1 if passive_pct < 10.0 else 0
	var pct_text: String = String.num(passive_pct, decimals)
	var title: String = _strings_get("offline_summary_title", "While you were away…")
	var body_template: String = _strings_get(
		"offline_summary_body",
		"Your farm produced {amount} at {pct}% passive efficiency. Feed to boost output!"
	)
	var amount_text := "+%s" % _format_num(amount)
	var body: String = body_template.format({"amount": amount_text, "pct": pct_text})
	var duration_sim: float = float(summary.get("applied_seconds", summary.get("elapsed_seconds", 0.0)))
	var duration_total: float = float(summary.get("elapsed_seconds", duration_sim))
	var comfort_before: Dictionary = summary.get("comfort_before", {})
	var comfort_after: Dictionary = summary.get("comfort_after", {})
	var before_bonus: float = float(comfort_before.get("ci_bonus", 0.0)) * 100.0
	var after_bonus: float = float(comfort_after.get("ci_bonus", 0.0)) * 100.0
	var bonus_delta: float = after_bonus - before_bonus
	var automation_after: Dictionary = summary.get("automation_after", {})
	var automation_enabled: bool = bool(automation_after.get("global_enabled", true))
	var automation_targets: int = int(automation_after.get("active_targets", 0))
	var lines: Array[String] = [body]
	if duration_sim > 0.0:
		if bool(summary.get("clamped", false)) and duration_total > duration_sim + 1.0:
			var clamped_template := _strings_get("offline_summary_duration_clamped", "Simulated {applied} of {total} offline")
			lines.append(clamped_template.format({"applied": _format_duration(duration_sim), "total": _format_duration(duration_total)}))
		else:
			var duration_template := _strings_get("offline_summary_duration", "Simulated {duration} offline")
			lines.append(duration_template.format({"duration": _format_duration(duration_total)}))
	var comfort_template := _strings_get(
		"offline_summary_comfort",
		"Comfort bonus: {before}% → {after}% ({delta}% change)"
	)
	lines.append(comfort_template.format({
		"before": String.num(before_bonus, 2),
		"after": String.num(after_bonus, 2),
		"delta": String.num(bonus_delta, 2)
	}))
	var automation_state: String
	if automation_enabled and automation_targets > 0:
		automation_state = _strings_get("offline_summary_automation_ready", "Automation ready ({count} routines)").format({"count": automation_targets})
	elif automation_enabled:
		automation_state = _strings_get("offline_summary_automation_available", "Automation available")
	else:
		automation_state = _strings_get("offline_summary_automation_paused", "Automation paused")
	lines.append(automation_state)
	var overflow_seconds: float = float(summary.get("overflow_seconds", 0.0))
	if overflow_seconds > 1.0:
		var cap_template := _strings_get("offline_summary_cap_notice", "Cap reached: extra {overflow} held for telemetry")
		lines.append(cap_template.format({"overflow": _format_duration(overflow_seconds)}))
	var detail_text := "\n".join(lines)
	offline_label.text = "%s\n%s" % [title, detail_text]
	offline_popup.popup_centered()

func _format_num(value: float, decimals: int = 0) -> String:
	var abs_val: float = abs(value)
	if abs_val >= 1_000_000.0:
		return "%.2fM" % (value / 1_000_000.0)
	if abs_val >= 1_000.0:
		return "%.1fk" % (value / 1_000.0)
	return String.num(value, decimals)

func _format_duration(seconds: float) -> String:
	var total: int = max(int(round(seconds)), 0)
	var hours: int = total / 3600
	var minutes: int = (total % 3600) / 60
	var secs: int = total % 60
	var parts: Array[String] = []
	if hours > 0:
		parts.append("%dh" % hours)
	if minutes > 0:
		parts.append("%dm" % minutes)
	if hours == 0 and minutes == 0:
		parts.append("%ds" % secs)
	return " ".join(parts)

func _research_cost(id: String) -> int:
	var node: Dictionary = bal.research.get(id, {})
	return int(node.get("cost", 0))

func _on_settings_pressed() -> void:
	settings_panel.populate_strings()
	settings_panel.set_high_contrast(high_contrast_enabled)
	settings_panel.set_visuals_enabled(visuals_enabled)
	settings_panel.show_panel(text_scale, high_contrast_enabled, color_palette)

func apply_text_scale(scale: float) -> void:
	text_scale = scale
	root_vbox.scale = Vector2(scale, scale)

func _on_text_scale_selected(scale: float) -> void:
	apply_text_scale(scale)
	_log("INFO", "UI", "Text scale updated", {"scale": scale})

func _on_diagnostics_requested() -> void:
	_copy_diagnostics()

func _on_reset_requested() -> void:
	settings_panel.hide()
	var absolute_path := ProjectSettings.globalize_path(sav.save_path)
	var removed := false
	if FileAccess.file_exists(sav.save_path):
		var result := DirAccess.remove_absolute(absolute_path)
		if result == OK:
			removed = true
			_log("INFO", "SAVE", "Save file deleted", {"path": sav.save_path})
		else:
			_log("ERROR", "SAVE", "Save delete failed", {"path": sav.save_path, "code": result})
	if not removed and not FileAccess.file_exists(sav.save_path):
		_log("INFO", "SAVE", "Reset with no existing save", {"path": sav.save_path})
	get_tree().reload_current_scene()

func _copy_diagnostics() -> void:
	var version := Engine.get_version_info()
	var platform := OS.get_name()
	var seed := _get_config_seed()
	var lines: Array[String] = []
	lines.append("Yolkless Diagnostics")
	lines.append("Build: %s.%s.%s" % [version.get("major", 0), version.get("minor", 0), version.get("patch", 0)])
	lines.append("Platform: %s" % platform)
	lines.append("Seed: %d" % seed)
	lines.append("Tier: %d (%s)" % [eco.factory_tier, eco.factory_name()])
	lines.append("PPS: %.2f" % eco.current_pps())
	lines.append("Storage: %.1f / %.1f" % [eco.current_storage(), eco.get_capacity_limit()])
	lines.append("Credits: %.1f" % eco.soft)
	lines.append("Feed: %.1f / %.1f (%.0f%%)" % [eco.feed_current, eco.feed_capacity, eco.get_feed_fraction() * 100.0])
	lines.append("Feed refill seconds: %.2f" % eco.get_feed_seconds_to_full())
	lines.append("Research owned: %s" % ", ".join(res.owned.keys()))
	var upgrades: Dictionary = eco.get_upgrade_levels()
	lines.append("Upgrades: %s" % JSON.stringify(upgrades))
	var constants_subset: Dictionary = {
		"P0": bal.constants.get("P0", 1.0),
		"BURST_MULT": bal.constants.get("BURST_MULT", 1.0),
		"BURST_COOLDOWN": bal.constants.get("BURST_COOLDOWN", 10.0)
	}
	lines.append("Constants: %s" % JSON.stringify(constants_subset))
	var logger := _get_logger()
	var balance_md5: String = ""
	if logger:
		balance_md5 = logger.hash_md5_from_file("res://data/balance.tsv")
	lines.append("Balance md5: %s" % balance_md5)
	lines.append("Save hash: %s" % sav.get_current_hash())
	lines.append("--- Last Log Lines ---")
	var recent_lines: Array[String] = []
	if logger:
		recent_lines = logger.get_recent_lines(200)
	for line in recent_lines:
		lines.append(_sanitize_log_line(line))
	var summary := "\n".join(lines)
	DisplayServer.clipboard_set(summary)
	_log("INFO", "UI", "Diagnostics copied", {"lines": lines.size()})

func _configure_input_actions() -> void:
	_configure_action_events("ui_accept", [Key.KEY_ENTER, Key.KEY_KP_ENTER], [JOY_BUTTON_A])
	_configure_action_events("ui_cancel", [Key.KEY_ESCAPE], [JOY_BUTTON_B])
	_configure_action_events("ui_up", [Key.KEY_UP, Key.KEY_W], [JOY_BUTTON_DPAD_UP])
	_configure_action_events("ui_down", [Key.KEY_DOWN, Key.KEY_S], [JOY_BUTTON_DPAD_DOWN])
	_configure_action_events("ui_left", [Key.KEY_LEFT, Key.KEY_A], [JOY_BUTTON_DPAD_LEFT])
	_configure_action_events("ui_right", [Key.KEY_RIGHT, Key.KEY_D], [JOY_BUTTON_DPAD_RIGHT])
	_configure_action_events("ui_tab_store", [], [JOY_BUTTON_Y])
	_configure_action_events("ui_tab_research", [], [JOY_BUTTON_X])
	_configure_action_events("ui_tab_prev", [], [JOY_BUTTON_LEFT_SHOULDER])
	_configure_action_events("ui_tab_next", [], [JOY_BUTTON_RIGHT_SHOULDER])
	_configure_action_events("feed_hold", [], [])
	_add_joy_axis_event("feed_hold", JOY_AXIS_TRIGGER_RIGHT, 0.5)

func _configure_action_events(action: String, keycodes: Array[int], joy_buttons: Array[int]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for keycode in keycodes:
		if not _action_has_key(action, keycode):
			var key_event := InputEventKey.new()
			key_event.keycode = keycode
			key_event.physical_keycode = keycode
			InputMap.action_add_event(action, key_event)
	for button in joy_buttons:
		if not _action_has_joypad_button(action, button):
			var joy_event := InputEventJoypadButton.new()
			joy_event.button_index = button
			InputMap.action_add_event(action, joy_event)

func _action_has_key(action: String, keycode: int) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and event.keycode == keycode:
			return true
	return false

func _add_joy_axis_event(action: String, axis: int, threshold: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	InputMap.action_set_deadzone(action, clamp(abs(threshold), 0.0, 1.0))
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion and event.axis == axis and is_equal_approx(event.axis_value, threshold):
			return
	var joy_event := InputEventJoypadMotion.new()
	joy_event.axis = axis
	joy_event.axis_value = threshold
	InputMap.action_add_event(action, joy_event)

func _action_has_joypad_button(action: String, button_index: int) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and event.button_index == button_index:
			return true
	return false

func _hash_from_logger(path: String) -> String:
	var logger := _get_logger()
	if logger:
		return logger.hash_md5_from_file(path)
	return ""

func _get_config_seed() -> int:
	var config := get_node_or_null("/root/Config")
	if config:
		return int(config.seed)
	return 0

func _log(level: String, category: String, message: String, context: Dictionary) -> void:
	var logger := _get_logger()
	if logger:
		logger.log(level, category, message, context)

func _strings_get(key: String, fallback: String) -> String:
	var catalog := _get_strings()
	if catalog:
		return catalog.get_text(key, fallback)
	return fallback

func _get_logger() -> YolkLogger:
	var node := get_node_or_null("/root/Logger")
	if node is YolkLogger:
		return node as YolkLogger
	return null

func _get_visual_director() -> VisualDirector:
	var node := get_node_or_null("/root/VisualDirectorSingleton")
	if node is VisualDirector:
		return node as VisualDirector
	return null

func _get_environment_service() -> EnvironmentService:
	var node := get_node_or_null("/root/EnvironmentServiceSingleton")
	if node is EnvironmentService:
		return node as EnvironmentService
	return null

func _get_power_service() -> PowerService:
	var node := get_node_or_null("/root/PowerServiceSingleton")
	if node is PowerService:
		return node as PowerService
	return null

func _get_automation_service() -> AutomationService:
	var node := get_node_or_null("/root/AutomationServiceSingleton")
	if node is AutomationService:
		return node as AutomationService
	return null

func _get_sandbox_service() -> SandboxService:
	var node := get_node_or_null("/root/SandboxServiceSingleton")
	if node is SandboxService:
		return node as SandboxService
	return null

func _center_environment_root() -> void:
	if environment_root_node == null:
		return
	environment_root_node.position = _environment_root_target_position()

func _environment_root_target_position() -> Vector2:
	if environment_root_node:
		var parent := environment_root_node.get_parent()
		if parent is SubViewport:
			var viewport := parent as SubViewport
			var vsize := Vector2(viewport.size.x, viewport.size.y)
			if vsize != Vector2.ZERO:
				return vsize * 0.5
	var rect := Rect2()
	if _prototype_available() and ui_prototype.visible:
		rect = ui_prototype.get_canvas_rect()
	if rect.size == Vector2.ZERO and root_vbox:
		rect = root_vbox.get_global_rect()
	if rect.size == Vector2.ZERO:
		var fallback := _get_environment_stage_size()
		if fallback == Vector2.ZERO:
			fallback = DEFAULT_ENV_STAGE_SIZE
		return fallback * 0.5
	return Vector2(
		rect.position.x + rect.size.x * 0.5,
		rect.position.y + rect.size.y * 0.5
	)

func _on_viewport_size_changed() -> void:
	_update_factory_viewport_bounds()
	_center_environment_root()

func _get_environment_stage_size() -> Vector2:
	if environment_service:
		var size := environment_service.get_active_stage_size()
		if size != Vector2.ZERO:
			return size
	return DEFAULT_ENV_STAGE_SIZE

func _move_environment_into_viewport(viewport: SubViewport) -> void:
	if environment_root_node == null or viewport == null:
		return
	if environment_root_node.get_parent() == viewport:
		return
	var previous_parent := environment_root_node.get_parent()
	if previous_parent:
		previous_parent.remove_child(environment_root_node)
	viewport.add_child(environment_root_node)
	if viewport.size != Vector2i.ZERO:
		environment_root_node.position = Vector2(viewport.size.x, viewport.size.y) * 0.5
	if _prototype_available():
		ui_prototype.mark_canvas_ready()

func _setup_sandbox_canvas(viewport: SubViewport) -> void:
	if sandbox_canvas and is_instance_valid(sandbox_canvas):
		return
	sandbox_canvas = SandboxCanvasScene.instantiate()
	viewport.add_child(sandbox_canvas)
	sandbox_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	sandbox_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sandbox_renderer = sandbox_canvas as SandboxRenderer
	if sandbox_renderer and not sandbox_renderer.fallback_state_changed.is_connected(_on_sandbox_fallback_changed):
		sandbox_renderer.fallback_state_changed.connect(_on_sandbox_fallback_changed)

func _update_factory_viewport_bounds() -> void:
	if factory_viewport == null:
		return
	var target_size := Vector2.ZERO
	if _prototype_available() and ui_prototype.visible:
		target_size = ui_prototype.get_canvas_rect().size
	if target_size == Vector2.ZERO and root_vbox:
		target_size = root_vbox.get_global_rect().size
	if target_size == Vector2.ZERO:
		return
	var viewport_size := Vector2i(max(1, int(round(target_size.x))), max(1, int(round(target_size.y))))
	if factory_viewport.size != viewport_size:
		factory_viewport.size = viewport_size

func _get_strings() -> StringsCatalog:
	var node := get_node_or_null("/root/Strings")
	if node is StringsCatalog:
		return node as StringsCatalog
	return null

func _get_statbus() -> StatBus:
	if _statbus and is_instance_valid(_statbus):
		return _statbus
	var node := get_node_or_null("/root/StatBusSingleton")
	if node is StatBus:
		_statbus = node as StatBus
		return _statbus
	return null

func _apply_tier_progression() -> void:
	var multiplier := 1.0
	if _tier_one_unlocked:
		multiplier += TIER1_CONVEYOR_BONUS
	if conveyor_manager:
		conveyor_manager.set_speed_multiplier(multiplier)

func _sync_automation_panel_from_economy() -> void:
	if automation_panel_ui and eco:
		var ratio := eco.automation_feed_threshold()
		automation_panel_ui.set_slider_ratio(ratio)
		automation_panel_ui.set_hint_percent(ratio * 100.0)
		automation_panel_ui.set_toggle_state(automation_service.is_global_enabled() if automation_service else true)
	if conveyor_manager and eco:
		conveyor_manager.set_user_speed_bias(eco.automation_feed_threshold())

func _update_telemetry_context() -> void:
	if eco:
		eco.set_telemetry_context(sav.tier_progress, _micro_event_active_id)

func _connect_sandbox_event_signals() -> void:
	if sandbox_service == null:
		return
	if not sandbox_service.event_started.is_connected(_on_sandbox_event_started):
		sandbox_service.event_started.connect(_on_sandbox_event_started)
	if not sandbox_service.event_completed.is_connected(_on_sandbox_event_completed):
		sandbox_service.event_completed.connect(_on_sandbox_event_completed)
	if not sandbox_service.event_declined.is_connected(_on_sandbox_event_declined):
		sandbox_service.event_declined.connect(_on_sandbox_event_declined)
	if not sandbox_service.event_accepted.is_connected(_on_sandbox_event_accepted):
		sandbox_service.event_accepted.connect(_on_sandbox_event_accepted)
	if not sandbox_service.event_toast_requested.is_connected(_on_sandbox_event_toast_requested):
		sandbox_service.event_toast_requested.connect(_on_sandbox_event_toast_requested)

func _setup_status_tooltips() -> void:
	if ui_layer == null:
		return
	if _power_tooltip == null:
		_power_tooltip = _create_tooltip()
	if _economy_tooltip == null:
		_economy_tooltip = _create_tooltip()
	if _backlog_tooltip == null:
		_backlog_tooltip = _create_tooltip()
	if lbl_power and not lbl_power.mouse_entered.is_connected(_on_power_label_hovered):
		lbl_power.mouse_entered.connect(_on_power_label_hovered)
		lbl_power.mouse_exited.connect(func(): _hide_tooltip(_power_tooltip))
	if lbl_pps and not lbl_pps.mouse_entered.is_connected(_on_economy_label_hovered):
		lbl_pps.mouse_entered.connect(_on_economy_label_hovered)
		lbl_pps.mouse_exited.connect(func(): _hide_tooltip(_economy_tooltip))
	if lbl_conveyor and not lbl_conveyor.mouse_entered.is_connected(_on_backlog_label_hovered):
		lbl_conveyor.mouse_entered.connect(_on_backlog_label_hovered)
		lbl_conveyor.mouse_exited.connect(func(): _hide_tooltip(_backlog_tooltip))

func _create_tooltip() -> UITooltip:
	if ui_layer == null:
		return null
	var tooltip := TOOLTIP_SCENE.instantiate() as UITooltip
	if tooltip == null:
		return null
	ui_layer.add_child(tooltip)
	tooltip.visible = false
	return tooltip

func _on_power_label_hovered() -> void:
	if _power_tooltip == null or lbl_power == null:
		return
	var text := _tooltip_copy("tooltip_power", _power_warning_level, lbl_power.tooltip_text)
	_show_tooltip(_power_tooltip, text, lbl_power)

func _on_economy_label_hovered() -> void:
	if _economy_tooltip == null or lbl_pps == null:
		return
	var text := _tooltip_copy("tooltip_economy", _economy_tone, lbl_pps.tooltip_text)
	_show_tooltip(_economy_tooltip, text, lbl_pps)

func _on_backlog_label_hovered() -> void:
	if _backlog_tooltip == null or lbl_conveyor == null:
		return
	var text := _tooltip_copy("tooltip_conveyor", _backlog_tone_runtime, lbl_conveyor.tooltip_text)
	_show_tooltip(_backlog_tooltip, text, lbl_conveyor)

func _tooltip_copy(prefix: String, tone: StringName, fallback: String) -> String:
	var key := "%s_%s" % [prefix, String(tone)]
	return _strings_get(key, fallback)

func _show_tooltip(tooltip: UITooltip, text: String, anchor: Control) -> void:
	if tooltip == null or anchor == null:
		return
	tooltip.set_text(text)
	var anchor_pos := anchor.get_global_position()
	var offset := Vector2(0, anchor.size.y + 8.0)
	var pos := anchor_pos + offset
	tooltip.position = Vector2(round(pos.x), round(pos.y))
	tooltip.visible = true

func _hide_tooltip(tooltip: UITooltip) -> void:
	if tooltip:
		tooltip.visible = false

func _update_micro_events(_delta: float) -> void:
	if _micro_event_active_id == "" or sandbox_service == null:
		return
	_micro_event_time_left = sandbox_service.get_event_time_remaining(_micro_event_active_id)
	_update_micro_event_timer_label()

func _show_micro_event_card(event_data: Dictionary) -> void:
	if micro_event_card == null:
		return
	var tint_variant := event_data.get("ui_tint", event_data.get("tint", Color(1, 1, 1, 1)))
	micro_event_card.self_modulate = tint_variant if tint_variant is Color else Color(1, 1, 1, 1)
	var title_key := String(event_data.get("title_key", ""))
	var body_key := String(event_data.get("body_key", ""))
	if micro_event_title:
		micro_event_title.text = _strings_get(title_key, title_key)
	if micro_event_body:
		micro_event_body.text = _strings_get(body_key, body_key)
	_configure_micro_event_buttons(event_data.get("buttons", []))
	micro_event_card.visible = true
	_update_micro_event_timer_label()

func _configure_micro_event_buttons(buttons: Array) -> void:
	_micro_event_primary_action = ""
	_micro_event_secondary_action = ""
	if micro_event_primary_button:
		micro_event_primary_button.visible = false
	if micro_event_secondary_button:
		micro_event_secondary_button.visible = false
	if buttons.is_empty():
		return
	_apply_micro_event_button(buttons[0], true)
	if buttons.size() > 1:
		_apply_micro_event_button(buttons[1], false)

func _apply_micro_event_button(button_data: Dictionary, primary: bool) -> void:
	var button := micro_event_primary_button if primary else micro_event_secondary_button
	if button == null:
		return
	var label_key := String(button_data.get("label_key", ""))
	if label_key != "":
		button.text = _strings_get(label_key, button.text)
	button.visible = true
	var action := String(button_data.get("id", "ack"))
	if primary:
		_micro_event_primary_action = action
	else:
		_micro_event_secondary_action = action

func _update_micro_event_timer_label() -> void:
	if micro_event_timer_label:
		if _micro_event_time_left < 0.0:
			micro_event_timer_label.text = "--"
		else:
			var remaining := int(ceil(_micro_event_time_left))
			var text := "%ds" % max(remaining, 0)
			micro_event_timer_label.text = text

func _clear_micro_event_state() -> void:
	_micro_event_active_id = ""
	_micro_event_time_left = 0.0
	_micro_event_current.clear()
	_micro_event_primary_action = ""
	_micro_event_secondary_action = ""
	_hide_micro_event_card()
	_update_telemetry_context()

func _on_micro_event_primary_pressed() -> void:
	_handle_micro_event_action(_micro_event_primary_action)

func _on_micro_event_secondary_pressed() -> void:
	_handle_micro_event_action(_micro_event_secondary_action)

func _handle_micro_event_action(action: String) -> void:
	if action == "" or sandbox_service == null or _micro_event_active_id == "":
		return
	match action:
		"decline":
			sandbox_service.decline_event(_micro_event_active_id)
			_hide_micro_event_card()
		_:
			sandbox_service.accept_event(_micro_event_active_id)
			_hide_micro_event_card()

func _hide_micro_event_card() -> void:
	if micro_event_card:
		micro_event_card.visible = false

func _on_sandbox_event_started(event_id: String, definition: Dictionary) -> void:
	_micro_event_active_id = event_id
	_micro_event_current = definition.duplicate(true)
	_show_micro_event_card(_micro_event_current)
	_update_telemetry_context()

func _on_sandbox_event_completed(event_id: String, _definition: Dictionary) -> void:
	if event_id != _micro_event_active_id:
		return
	_clear_micro_event_state()

func _on_sandbox_event_declined(event_id: String, _definition: Dictionary) -> void:
	if event_id != _micro_event_active_id:
		return
	_clear_micro_event_state()

func _on_sandbox_event_accepted(event_id: String, _definition: Dictionary) -> void:
	if event_id != _micro_event_active_id:
		return
	_hide_micro_event_card()

func _on_sandbox_event_toast_requested(key: String) -> void:
	var message := _strings_get(key, key)
	if message != "":
		_show_toast(message)


func _update_power_label() -> void:
	if lbl_power == null:
		return
	if power_service == null:
		lbl_power.text = "Power Load: n/a"
		lbl_power.tooltip_text = "Power service offline"
		return
	var warning_level := _power_warning_level
	if power_service != null:
		var service_level := power_service.current_warning_level()
		if warning_level != service_level:
			warning_level = service_level
			_power_warning_level = service_level
	var ratio: float = clamp(power_service.current_state(), 0.0, 1.3)
	var ratio_text: String = _format_num(ratio * 100.0, 0)
	var label: String = "Power Load: %s%%" % ratio_text
	if warning_level == PowerService.WARNING_CRITICAL:
		label += " ⚠"
	elif warning_level == PowerService.WARNING_WARNING:
		label += " ⚡"
	var status_tone := "normal"
	if warning_level == PowerService.WARNING_CRITICAL:
		status_tone = "critical"
	elif warning_level == PowerService.WARNING_WARNING:
		status_tone = "warning"
	_set_prototype_status("power", "%s%% load" % ratio_text, status_tone)
	if _comfort_bonus > 0.0:
		var comfort_text: String = _format_num(_comfort_bonus * 100.0, 1)
		label += " | Comfort +%s%%" % comfort_text
	lbl_power.text = label
	var tooltip_lines: Array[String] = ["Power ratio %.2f" % ratio]
	if _comfort_bonus > 0.0:
		tooltip_lines.append("Comfort bonus +%.2f%%" % (_comfort_bonus * 100.0))
	if warning_level == PowerService.WARNING_CRITICAL:
		tooltip_lines.append(_strings_get("power_warning_tooltip_critical", "Power deficit critical — expect outages."))
	elif warning_level == PowerService.WARNING_WARNING:
		tooltip_lines.append(_strings_get("power_warning_tooltip_warning", "Power grid unstable — efficiency reduced."))
	else:
		tooltip_lines.append(_strings_get("power_warning_tooltip_normal", "Power grid stable."))
	lbl_power.tooltip_text = "\n".join(tooltip_lines)
	_apply_power_warning_visuals(warning_level)
	if automation_panel_ui:
		automation_panel_ui.set_power_limited(warning_level != PowerService.WARNING_NORMAL)

func _update_tier_progress(delta: float) -> void:
	if _tier_one_unlocked:
		return
	if _power_warning_level == PowerService.WARNING_NORMAL:
		_stable_power_seconds += delta
	else:
		_stable_power_seconds = max(_stable_power_seconds - delta, 0.0)
	if _tier_one_unlocked:
		return
	if _stable_power_seconds >= TIER1_POWER_SECONDS and _economy_rate_avg >= TIER1_RATE_THRESHOLD:
		_complete_tier_one_unlock()

func _complete_tier_one_unlock() -> void:
	if _tier_one_unlocked:
		return
	_tier_one_unlocked = true
	if sav:
		sav.tier_progress = max(sav.tier_progress, 1)
	_apply_tier_progression()
	_update_telemetry_context()
	_show_toast(_strings_get("tier_unlocked_1_body", "Tier 1 Unlocked — automation efficiency +10%."))
	sav.save("tier_progress")

func _sanitize_log_line(line: String) -> String:
	var logger := _get_logger()
	if logger:
		return logger.sanitize(line)
	return line
