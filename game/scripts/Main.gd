extends Node

const SETTINGS_PANEL_SCENE := preload("res://game/scenes/widgets/SettingsPanel.tscn")
const DEBUG_OVERLAY_SCENE := preload("res://game/scenes/widgets/DebugOverlay.tscn")

const CAPACITY_BACKGROUND_DEFAULT := Color(0.1, 0.1, 0.1, 1)
const CAPACITY_FILL_DEFAULT := Color(0.95, 0.82, 0.18, 1)
const CAPACITY_FONT_DEFAULT := Color(1, 1, 1, 1)
const CAPACITY_BACKGROUND_CONTRAST := Color(0.04, 0.04, 0.04, 1)
const CAPACITY_FILL_CONTRAST := Color(1, 1, 1, 1)
const CAPACITY_FONT_CONTRAST := Color(0.1, 0.1, 0.1, 1)

const FEED_BACKGROUND_DEFAULT := Color(0.08, 0.08, 0.12, 1)
const FEED_FILL_HIGH_DEFAULT := Color(0.2, 0.8, 0.35, 1)
const FEED_FILL_MED_DEFAULT := Color(0.95, 0.68, 0.2, 1)
const FEED_FILL_LOW_DEFAULT := Color(0.9, 0.2, 0.2, 1)
const FEED_BACKGROUND_CONTRAST := Color(0.02, 0.02, 0.02, 1)
const FEED_FILL_HIGH_CONTRAST := Color(0.0, 0.85, 0.2, 1)
const FEED_FILL_MED_CONTRAST := Color(0.98, 0.78, 0.1, 1)
const FEED_FILL_LOW_CONTRAST := Color(1.0, 0.22, 0.22, 1)
const FEED_FONT_DEFAULT := Color(1, 1, 1, 1)
const FEED_FONT_CONTRAST := Color(0.05, 0.05, 0.05, 1)
const FEED_FLASH_COLOR := Color(1, 0.7, 0.7, 1)

@onready var bal: Balance = $Balance
@onready var res: Research = $Research
@onready var eco: Economy = $Economy
@onready var sav: Save = $Save

@onready var root_vbox: VBoxContainer = %VBox
@onready var environment_overlay: PollutionOverlay = %EnvironmentOverlay
@onready var deny_sound: AudioStreamPlayer = %DenySound
@onready var stats_box: HBoxContainer = %StatsBox
@onready var lbl_soft: Label = %SoftLabel
@onready var capacity_label: Label = %CapacityLabel
@onready var capacity_bar: ProgressBar = %CapacityBar
@onready var feed_status_label: Label = %FeedStatus
@onready var feed_bar: ProgressBar = %FeedBar
@onready var lbl_pps: Label = %PPSLabel
@onready var lbl_tier: Label = %TierLabel
@onready var lbl_prestige: Label = %PrestigeLabel
@onready var research_header_label: Label = %ResearchHeader
@onready var lbl_research: Label = %ResearchStatus

@onready var btn_burst: Button = %BurstButton
@onready var btn_prod: Button = %BuyProd
@onready var btn_cap: Button = %BuyCap
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

var text_scale := 1.0
var settings_panel: SettingsPanel
var debug_overlay: CanvasLayer
var high_contrast_enabled := false
var visuals_enabled := true
var environment_director: EnvironmentDirector
var _feed_deny_sound_warned := false

func _ready() -> void:
	res.setup(bal)
	eco.setup(bal, res)
	sav.setup(eco, res)

	bal.reloaded.connect(_on_balance_reload)
	res.changed.connect(_update_research_view)
	eco.soft_changed.connect(_on_soft_changed)
	eco.tier_changed.connect(func(_tier: int) -> void: _update_factory_view())
	eco.burst_state.connect(_on_feed_state_changed)
	btn_burst.button_down.connect(_on_feed_button_down)
	btn_burst.button_up.connect(_on_feed_button_up)
	btn_prod.pressed.connect(func(): _attempt_upgrade("prod_1"))
	btn_cap.pressed.connect(func(): _attempt_upgrade("cap_1"))
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

	settings_panel = SETTINGS_PANEL_SCENE.instantiate()
	add_child(settings_panel)
	settings_panel.hide()
	settings_panel.text_scale_selected.connect(_on_text_scale_selected)
	settings_panel.diagnostics_requested.connect(_on_diagnostics_requested)
	settings_panel.high_contrast_toggled.connect(_on_high_contrast_toggled)
	settings_panel.visuals_toggled.connect(_on_visuals_toggled)
	settings_panel.set_high_contrast(high_contrast_enabled)
	settings_panel.set_visuals_enabled(visuals_enabled)

	debug_overlay = DEBUG_OVERLAY_SCENE.instantiate()
	add_child(debug_overlay)
	debug_overlay.visible = false
	debug_overlay.configure(eco, res, sav, bal)

	var logger := _get_logger()
	var config := get_node_or_null("/root/Config")
	var logging_enabled := true
	var logging_force_disable := false
	var seed := 0
	if config:
		logging_enabled = bool(config.logging_enabled)
		logging_force_disable = bool(config.logging_force_disable)
		seed = int(config.seed)
	if logger:
		logger.setup(logging_enabled, logging_force_disable)
	text_scale = 1.0
	_log("INFO", "CONFIG", "Active seed", {"seed": seed, "logging_enabled": logging_enabled, "force_disabled": logging_force_disable})

	var strings := _get_strings()
	if strings:
		strings.load("res://game/data/strings_egg.tsv")
		environment_overlay.set_strings(strings)

	var director := _get_visual_director()
	if director:
		director.set_sources(eco, strings)
		director.set_high_contrast(high_contrast_enabled)
		director.activate("feed_particles", visuals_enabled)

	environment_director = _get_environment_director()
	if environment_director:
		environment_director.set_sources(eco, res, strings)
		if not environment_director.state_changed.is_connected(_on_environment_state_changed):
			environment_director.state_changed.connect(_on_environment_state_changed)
		var env_state := environment_director.get_state()
		_on_environment_state_changed(
			float(env_state.get("pollution", 0.0)),
			float(env_state.get("stress", 0.0)),
			float(env_state.get("reputation", 0.0))
		)

	sav.load_state()
	var offline_gain: float = sav.grant_offline()
	if offline_gain > 0.0:
		_show_offline_popup(offline_gain)

	apply_text_scale(text_scale)
	_apply_contrast_theme()
	_apply_strings()
	_update_all_views()
	_update_feed_ui()

	_log("INFO", "THEME", "Theme applied", {
		"currency": "Egg Credits",
		"prestige": "Reputation Stars"
	})
	_log("INFO", "STRINGS", "UI copy refreshed", {"scene": "Main"})
	sav.save("startup")

func _process(_delta: float) -> void:
	_update_capacity_bar()
	_update_feed_ui()
	if environment_director:
		environment_director.update_environment(_delta)


func _unhandled_input(event: InputEvent) -> void:
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
		"md5": _hash_from_logger("res://game/data/balance.tsv")
	})
	_update_all_views()
	_apply_strings()

func _on_soft_changed(value: float) -> void:
	_update_soft_view(value)
	_update_prestige_view()
	_update_upgrade_buttons()

func _apply_strings() -> void:
	btn_settings.text = _strings_get("settings_button", btn_settings.text)
	btn_export.text = _strings_get("export_button", btn_export.text)
	btn_import.text = _strings_get("import_button", btn_import.text)
	research_header_label.text = _strings_get("research_header_title", research_header_label.text)
	var close_text := _strings_get("close_button", offline_close.text)
	offline_close.text = close_text
	btn_burst.text = _strings_get("burst_button", btn_burst.text)
	settings_panel.populate_strings()
	var strings := _get_strings()
	if strings:
		environment_overlay.set_strings(strings)
	_update_capacity_bar()
	_update_feed_ui()

func _update_all_views() -> void:
	_update_soft_view(eco.soft)
	_update_prestige_view()
	_update_upgrade_buttons()
	_update_factory_view()
	_update_research_view()
	_update_feed_ui()

func _update_soft_view(value: float) -> void:
	var capacity: float = eco.get_capacity_limit()
	var soft_template := _strings_get("soft_label", "Egg Credits: {value} / {capacity}")
	lbl_soft.text = soft_template.format({
		"value": _format_num(value),
		"capacity": _format_num(capacity)
	})
	var pps_template := _strings_get("pps_label", "Egg Flow: {pps}/s")
	lbl_pps.text = pps_template.format({
		"pps": _format_num(eco.current_pps(), 1)
	})
	_update_capacity_bar()
	_update_feed_ui()

func _update_prestige_view() -> void:
	var next := eco.prestige_points_earned()
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

func _update_factory_view() -> void:
	var name := eco.factory_name()
	var stage_template := _strings_get("farm_stage", "Farm Stage: {name}")
	lbl_tier.text = stage_template.format({"name": name})
	var next_cost := eco.next_factory_cost()
	var next_name := eco.factory_name(eco.factory_tier + 1)
	if next_cost <= 0.0:
		btn_promote.text = _strings_get("promote_disabled", "Stage Mastered")
		btn_promote.disabled = true
	else:
		var label_name := next_name
		if label_name == "":
			label_name = _strings_get("promote", "Next Stage")
		var promote_template := _strings_get("promote_button", "Upgrade to {name} ({cost} 🥚)")
		btn_promote.text = promote_template.format({
			"name": label_name,
			"cost": _format_num(next_cost)
		})
		btn_promote.disabled = eco.soft + 1e-6 < next_cost

func _update_upgrade_buttons() -> void:
	var prod_cost: float = eco.upgrade_cost("prod_1")
	var cap_cost: float = eco.upgrade_cost("cap_1")
	var auto_cost: float = eco.upgrade_cost("auto_1")
	btn_prod.text = _strings_get("buy_prod", btn_prod.text).format({"cost": _format_num(prod_cost)})
	btn_cap.text = _strings_get("buy_cap", btn_cap.text).format({"cost": _format_num(cap_cost)})
	var auto_allowed: bool = eco.can_purchase_upgrade("auto_1")
	btn_prod.disabled = (not eco.can_purchase_upgrade("prod_1")) or eco.soft + 1e-6 < prod_cost
	btn_cap.disabled = (not eco.can_purchase_upgrade("cap_1")) or eco.soft + 1e-6 < cap_cost
	var auto_requires: String = String(bal.upgrades.get("auto_1", {}).get("requires", "-"))
	var requirement_text: String = ""
	if not auto_allowed and auto_requires.begins_with("factory>="):
		var parts: PackedStringArray = auto_requires.split(">=")
		if parts.size() >= 2:
			var need := int(parts[1])
			var stage_name := eco.factory_name(need)
			if stage_name != "":
				requirement_text = _strings_get("buy_auto_requirement", " — Requires {stage}").format({"stage": stage_name})
	btn_auto.text = _strings_get("buy_auto", btn_auto.text).format({
		"cost": _format_num(auto_cost),
		"requirement": requirement_text
	})
	btn_auto.disabled = (not auto_allowed) or eco.soft + 1e-6 < auto_cost

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

func _update_capacity_bar() -> void:
	var capacity: float = eco.get_capacity_limit()
	var soft_value: float = eco.soft
	capacity_bar.max_value = max(capacity, 1.0)
	capacity_bar.value = min(soft_value, capacity)
	var capacity_template := _strings_get("capacity_bar_label", "Storage: {value} / {capacity}")
	var formatted := capacity_template.format({
		"value": _format_num(soft_value),
		"capacity": _format_num(capacity)
	})
	capacity_label.text = formatted
	capacity_bar.tooltip_text = formatted

func _update_feed_ui() -> void:
	var fraction: float = eco.get_feed_fraction()
	feed_bar.max_value = 1.0
	feed_bar.value = fraction
	var percent := int(round(fraction * 100.0))
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
	var feed_background := FEED_BACKGROUND_DEFAULT
	var feed_font := FEED_FONT_DEFAULT
	if high_contrast_enabled:
		feed_background = FEED_BACKGROUND_CONTRAST
		feed_font = FEED_FONT_CONTRAST
	feed_bar.add_theme_color_override("background", feed_background)
	feed_bar.add_theme_color_override("font_color", feed_font)
	feed_bar.add_theme_color_override("fill", _get_feed_fill_color(fraction))
	feed_status_label.add_theme_color_override("font_color", feed_font)
	if feed_bar.modulate != Color.WHITE:
		feed_bar.modulate = Color.WHITE

func _get_feed_fill_color(fraction: float) -> Color:
	if high_contrast_enabled:
		if fraction >= 0.66:
			return FEED_FILL_HIGH_CONTRAST
		if fraction >= 0.33:
			return FEED_FILL_MED_CONTRAST
		return FEED_FILL_LOW_CONTRAST
	if fraction >= 0.66:
		return FEED_FILL_HIGH_DEFAULT
	if fraction >= 0.33:
		return FEED_FILL_MED_DEFAULT
	return FEED_FILL_LOW_DEFAULT

func _on_high_contrast_toggled(enabled: bool) -> void:
	high_contrast_enabled = enabled
	_apply_contrast_theme()
	var director := _get_visual_director()
	if director:
		director.set_high_contrast(enabled)

func _on_feed_state_changed(_active: bool) -> void:
	_update_feed_ui()

func _on_visuals_toggled(enabled: bool) -> void:
	visuals_enabled = enabled
	var director := _get_visual_director()
	if director:
		director.activate("feed_particles", enabled)

func _on_environment_state_changed(pollution: float, stress: float, reputation: float) -> void:
	environment_overlay.update_state(pollution, stress, reputation)

func _apply_contrast_theme() -> void:
	var background_color := CAPACITY_BACKGROUND_DEFAULT
	var fill_color := CAPACITY_FILL_DEFAULT
	var font_color := CAPACITY_FONT_DEFAULT
	if high_contrast_enabled:
		background_color = CAPACITY_BACKGROUND_CONTRAST
		fill_color = CAPACITY_FILL_CONTRAST
		font_color = CAPACITY_FONT_CONTRAST
	capacity_bar.add_theme_color_override("background", background_color)
	capacity_bar.add_theme_color_override("fill", fill_color)
	capacity_bar.add_theme_color_override("font_color", font_color)
	var feed_background := FEED_BACKGROUND_DEFAULT
	var feed_font := FEED_FONT_DEFAULT
	if high_contrast_enabled:
		feed_background = FEED_BACKGROUND_CONTRAST
		feed_font = FEED_FONT_CONTRAST
	feed_bar.add_theme_color_override("background", feed_background)
	feed_bar.add_theme_color_override("font_color", feed_font)
	feed_status_label.add_theme_color_override("font_color", feed_font)
	_update_feed_ui()

func _on_feed_button_down() -> void:
	_attempt_feed_start("button")

func _on_feed_button_up() -> void:
	eco.stop_burst("button")
	_update_feed_ui()

func _attempt_feed_start(source: String) -> void:
	if eco.feed_current <= 0.0:
		_handle_feed_denied()
		return
	var started := eco.try_burst(source == "auto")
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
	var gained := eco.do_prestige()
	_log("INFO", "ECONOMY", "Prestige accepted", {"gained": gained})
	_update_all_views()

func _show_offline_popup(amount: float) -> void:
	var title := _strings_get("offline_title", "Offline Egg Credits")
	offline_label.text = "%s: +%s" % [title, _format_num(amount)]
	offline_popup.popup_centered()

func _format_num(value: float, decimals: int = 0) -> String:
	var abs_val: float = abs(value)
	if abs_val >= 1_000_000.0:
		return "%.2fM" % (value / 1_000_000.0)
	if abs_val >= 1_000.0:
		return "%.1fk" % (value / 1_000.0)
	return String.num(value, decimals)

func _research_cost(id: String) -> int:
	var node: Dictionary = bal.research.get(id, {})
	return int(node.get("cost", 0))

func _on_settings_pressed() -> void:
	settings_panel.populate_strings()
	settings_panel.set_high_contrast(high_contrast_enabled)
	settings_panel.set_visuals_enabled(visuals_enabled)
	settings_panel.show_panel(text_scale, high_contrast_enabled)

func apply_text_scale(scale: float) -> void:
	text_scale = scale
	root_vbox.scale = Vector2(scale, scale)

func _on_text_scale_selected(scale: float) -> void:
	apply_text_scale(scale)
	_log("INFO", "UI", "Text scale updated", {"scale": scale})

func _on_diagnostics_requested() -> void:
	_copy_diagnostics()

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
	lines.append("Capacity: %.1f / %.1f" % [eco.soft, eco.get_capacity_limit()])
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
		balance_md5 = logger.hash_md5_from_file("res://game/data/balance.tsv")
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

func _get_environment_director() -> EnvironmentDirector:
	var node := get_node_or_null("/root/EnvironmentDirectorSingleton")
	if node is EnvironmentDirector:
		return node as EnvironmentDirector
	return null

func _get_strings() -> StringsCatalog:
	var node := get_node_or_null("/root/Strings")
	if node is StringsCatalog:
		return node as StringsCatalog
	return null

func _sanitize_log_line(line: String) -> String:
	var logger := _get_logger()
	if logger:
		return logger.sanitize(line)
	return line
