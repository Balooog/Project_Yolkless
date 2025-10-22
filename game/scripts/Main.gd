extends Node

const SETTINGS_PANEL_SCENE := preload("res://game/scenes/widgets/SettingsPanel.tscn")
const DEBUG_OVERLAY_SCENE := preload("res://game/scenes/widgets/DebugOverlay.tscn")

@onready var bal: Balance = $Balance
@onready var res: Research = $Research
@onready var eco: Economy = $Economy
@onready var sav: Save = $Save

@onready var root_vbox: VBoxContainer = %VBox
@onready var stats_box: HBoxContainer = %StatsBox
@onready var lbl_soft: Label = %SoftLabel
@onready var lbl_cooldown: Label = %CooldownLabel
@onready var capacity_label: Label = %CapacityLabel
@onready var capacity_bar: ProgressBar = %CapacityBar
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

func _ready() -> void:
	res.setup(bal)
	eco.setup(bal, res)
	sav.setup(eco, res)

	bal.reloaded.connect(_on_balance_reload)
	res.changed.connect(_update_research_view)
	eco.soft_changed.connect(_on_soft_changed)
	eco.tier_changed.connect(func(_tier: int) -> void: _update_factory_view())
	var strings_node := _get_strings()
	if strings_node:
		strings_node.connect("reloaded", Callable(self, "_on_strings_reloaded"))

	btn_burst.button_down.connect(func(): eco.try_burst())
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

	debug_overlay = DEBUG_OVERLAY_SCENE.instantiate()
	add_child(debug_overlay)
	debug_overlay.visible = false
	debug_overlay.configure(eco, res, sav, bal)

	sav.load_state()
	var offline_gain := sav.grant_offline()
	if offline_gain > 0.0:
		_show_offline_popup(offline_gain)

	apply_text_scale(text_scale)
	_apply_strings()
	_update_all_views()

	_log("INFO", "THEME", "Theme applied", {
		"currency": "Egg Credits",
		"prestige": "Reputation Stars"
	})
	_log("INFO", "STRINGS", "UI copy refreshed", {
		"scene": "Main",
		"stage": eco.factory_name()
	})
	var seed := _get_config_seed()
	_log("INFO", "CONFIG", "Active seed", {"seed": seed})
	sav.save("startup")

func _process(_delta: float) -> void:
	var capacity := eco.get_capacity_limit()
	capacity_bar.max_value = max(capacity, 1.0)
	capacity_bar.value = min(eco.soft, capacity)
	capacity_bar.tooltip_text = "%s / %s" % [_format_num(eco.soft), _format_num(capacity)]
	var capacity_template := _strings_get("capacity_bar_label", "Storage: {value} / {capacity}")
	capacity_label.text = capacity_template.format({
		"value": _format_num(eco.soft),
		"capacity": _format_num(capacity)
	})
	var cooldown_template := _strings_get("cooldown_label", "Burst Cooldown: {seconds}s")
	var seconds := max(eco.get_burst_cooldown_left(), 0.0)
	lbl_cooldown.text = cooldown_template.format({
		"seconds": String.num(seconds, 1)
	})

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("burst_hold"):
		eco.try_burst()
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

func _on_strings_reloaded() -> void:
	_apply_strings()
	_update_all_views()

func _update_all_views() -> void:
	_update_soft_view(eco.soft)
	_update_prestige_view()
	_update_upgrade_buttons()
	_update_factory_view()
	_update_research_view()

func _update_soft_view(value: float) -> void:
	var capacity := eco.get_capacity_limit()
	var soft_template := _strings_get("soft_label", "Egg Credits: {value} / {capacity}")
	lbl_soft.text = soft_template.format({
		"value": _format_num(value),
		"capacity": _format_num(capacity)
	})
	var pps_template := _strings_get("pps_label", "Egg Flow: {pps}/s")
	lbl_pps.text = pps_template.format({
		"pps": _format_num(eco.current_pps(), 1)
	})

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
	var prod_cost := eco.upgrade_cost("prod_1")
	var cap_cost := eco.upgrade_cost("cap_1")
	var auto_cost := eco.upgrade_cost("auto_1")
	btn_prod.text = _strings_get("buy_prod", btn_prod.text).format({"cost": _format_num(prod_cost)})
	btn_cap.text = _strings_get("buy_cap", btn_cap.text).format({"cost": _format_num(cap_cost)})
	var auto_allowed := eco.can_purchase_upgrade("auto_1")
	btn_prod.disabled = (not eco.can_purchase_upgrade("prod_1")) or eco.soft + 1e-6 < prod_cost
	btn_cap.disabled = (not eco.can_purchase_upgrade("cap_1")) or eco.soft + 1e-6 < cap_cost
	var auto_requires := bal.upgrades.get("auto_1", {}).get("requires", "-")
	var requirement_text := ""
	if not auto_allowed and typeof(auto_requires) == TYPE_STRING and auto_requires.begins_with("factory>=" ):
		var parts := auto_requires.split(">=")
		if parts.size() >= 2:
			var need := int(parts[1])
			var stage := eco.factory_name(need)
		if stage != "":
			requirement_text = _strings_get("buy_auto_requirement", " — Requires {stage}").format({"stage": stage})
	btn_auto.text = _strings_get("buy_auto", btn_auto.text).format({
		"cost": _format_num(auto_cost),
		"requirement": requirement_text
	})
	btn_auto.disabled = (not auto_allowed) or eco.soft + 1e-6 < auto_cost

func _update_research_view() -> void:
	lbl_research.text = _strings_get("research_header", "Innovation Lab — Research Points: {points}").format({
		"points": res.prestige_points
	})
	var mapping := {
		"r_prod_1": _strings_get("research_prod_label", "Feed Conversion R&D"),
		"r_cap_1": _strings_get("research_cap_label", "Modular Coops"),
		"r_auto_1": _strings_get("research_auto_label", "Drone Feeders")
	}
	var nodes = [
		{"id": "r_prod_1", "button": btn_r_prod},
		{"id": "r_cap_1", "button": btn_r_cap},
		{"id": "r_auto_1", "button": btn_r_auto},
	]
	for entry in nodes:
		var node_id: String = entry["id"]
		var button: Button = entry["button"]
		var label := mapping.get(node_id, node_id)
		if res.owned.has(node_id):
			button.text = _strings_get("research_owned", "{label} ✅").format({"label": label})
			button.disabled = true
		else:
			var cost := _research_cost(node_id)
			button.text = _strings_get("research_available", "{label} ({cost} 🌟)").format({
				"label": label,
				"cost": cost
			})
			button.disabled = not res.can_buy(node_id)

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
	var abs_val := abs(value)
	if abs_val >= 1_000_000.0:
		return "%.2fM" % (value / 1_000_000.0)
	if abs_val >= 1_000.0:
		return "%.1fk" % (value / 1_000.0)
	return String.num(value, decimals)

func _research_cost(id: String) -> int:
	var node := bal.research.get(id, {})
	return int(node.get("cost", 0))

func _on_settings_pressed() -> void:
	settings_panel.populate_strings()
	settings_panel.show_panel(text_scale)

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
	lines.append("Research owned: %s" % ", ".join(res.owned.keys()))
	var upgrades := eco.get_upgrade_levels()
	lines.append("Upgrades: %s" % JSON.stringify(upgrades))
	var constants_subset := {
		"P0": bal.constants.get("P0", 1.0),
		"BURST_MULT": bal.constants.get("BURST_MULT", 1.0),
		"BURST_COOLDOWN": bal.constants.get("BURST_COOLDOWN", 10.0)
	}
	lines.append("Constants: %s" % JSON.stringify(constants_subset))
	var logger := _get_logger()
	var balance_md5 := ""
	if logger:
		balance_md5 = logger.call("hash_md5_from_file", "res://game/data/balance.tsv")
	lines.append("Balance md5: %s" % balance_md5)
	lines.append("Save hash: %s" % sav.get_current_hash())
	lines.append("--- Last Log Lines ---")
	var recent_lines: Array[String] = []
	if logger:
		recent_lines = logger.call("get_recent_lines", 200)
	for line in recent_lines:
		var sanitized_line := line
		if logger:
			sanitized_line = logger.call("sanitize", line)
		lines.append(sanitized_line)
	var summary := "\n".join(lines)
	DisplayServer.clipboard_set(summary)
	_log("INFO", "UI", "Diagnostics copied", {"lines": lines.size()})

func _hash_from_logger(path: String) -> String:
	var logger := _get_logger()
	if logger:
		return logger.call("hash_md5_from_file", path)
	return ""

func _get_config_seed() -> int:
	var config := get_node_or_null("/root/Config")
	if config:
		return int(config.call("get_seed"))
	return 0

func _log(level: String, category: String, message: String, context: Dictionary) -> void:
	var logger := _get_logger()
	if logger:
		logger.call("record", level, category, message, context)

func _strings_get(key: String, fallback: String) -> String:
	var node := _get_strings()
	if node:
		return node.call("get_string", key, fallback)
	return fallback

func _get_logger() -> Node:
	return get_node_or_null("/root/Logger")

func _get_strings() -> Node:
	return get_node_or_null("/root/Strings")

*** End of File
