extends Node

@onready var bal: Balance = $Balance
@onready var res: Research = $Research
@onready var eco: Economy = $Economy
@onready var sav: Save = $Save

@onready var lbl_soft: Label = %SoftLabel
@onready var lbl_pps: Label = %PPSLabel
@onready var lbl_tier: Label = %TierLabel
@onready var lbl_prestige: Label = %PrestigeLabel
@onready var lbl_research: Label = %ResearchStatus

@onready var btn_burst: Button = %BurstButton
@onready var btn_prod: Button = %BuyProd
@onready var btn_cap: Button = %BuyCap
@onready var btn_auto: Button = %BuyAuto
@onready var btn_promote: Button = %Promote
@onready var btn_prestige: Button = %PrestigeButton
@onready var btn_export: Button = %Export
@onready var btn_import: Button = %Import
@onready var btn_r_prod: Button = %ResearchBuyProd
@onready var btn_r_cap: Button = %ResearchBuyCap
@onready var btn_r_auto: Button = %ResearchBuyAuto

@onready var offline_popup: PopupPanel = %OfflinePopup
@onready var offline_label: Label = %OfflineLabel
@onready var offline_close: Button = %OfflineClose

func _ready() -> void:
	res.setup(bal)
	eco.setup(bal, res)
	sav.setup(eco, res)

	bal.reloaded.connect(_on_balance_reload)
	res.changed.connect(_update_research_view)
	eco.soft_changed.connect(_on_soft_changed)
	eco.tier_changed.connect(func(_: int): _update_factory_view())

	btn_burst.button_down.connect(func(): eco.try_burst())
	btn_prod.pressed.connect(func(): _attempt_upgrade("prod_1"))
	btn_cap.pressed.connect(func(): _attempt_upgrade("cap_1"))
	btn_auto.pressed.connect(func(): _attempt_upgrade("auto_1"))
	btn_promote.pressed.connect(_attempt_promote)
	btn_prestige.pressed.connect(_attempt_prestige)
	btn_export.pressed.connect(func(): sav.export_to_clipboard())
	btn_import.pressed.connect(func(): sav.import_from_clipboard())
	btn_r_prod.pressed.connect(func(): _attempt_research("r_prod_1"))
	btn_r_cap.pressed.connect(func(): _attempt_research("r_cap_1"))
	btn_r_auto.pressed.connect(func(): _attempt_research("r_auto_1"))
	offline_close.pressed.connect(func(): offline_popup.hide())
	btn_prestige.text = "Rebrand & Advance to Next Generation"
	btn_burst.text = "HOLD TO FEED"

	sav.load()
	var offline_gain := sav.grant_offline()
	if offline_gain > 0.0:
		_show_offline_popup(offline_gain)

	_update_all_views()
	sav.save()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("burst_hold"):
		eco.try_burst()

func _on_balance_reload() -> void:
	print("Balance hot reload acknowledged in Main.gd")
	_update_all_views()

func _on_soft_changed(value: float) -> void:
	_update_soft_view(value)
	_update_prestige_view()
	_update_upgrade_buttons()

func _update_all_views() -> void:
	_update_soft_view(eco.soft)
	_update_prestige_view()
	_update_upgrade_buttons()
	_update_factory_view()
	_update_research_view()

func _update_soft_view(value: float) -> void:
	var capacity := eco.current_capacity()
	lbl_soft.text = "🥚 Egg Credits: %s / %s" % [_format_num(value), _format_num(capacity)]
	lbl_pps.text = "Egg Flow: %s /s" % _format_num(eco.current_pps(), 1)

func _update_prestige_view() -> void:
	var next := eco.prestige_points_earned()
	lbl_prestige.text = "🌟 Reputation Stars: %d (Next Rebrand: +%d)" % [res.prestige_points, next]
	btn_prestige.disabled = next <= 0
	btn_prestige.text = next > 0 ? "Rebrand & Advance to Next Generation" : "Rebrand & Advance"

func _update_factory_view() -> void:
	var name := eco.factory_name()
	lbl_tier.text = "Farm Stage: %s" % name
	var next_cost := eco.next_factory_cost()
	var next_name := eco.factory_name(eco.factory_tier + 1)
	if next_cost <= 0.0:
		btn_promote.text = "Stage Mastered"
		btn_promote.disabled = true
	else:
		var label_name := next_name if next_name != "" else "Next Stage"
		btn_promote.text = "Upgrade to %s (%s 🥚)" % [label_name, _format_num(next_cost)]
		btn_promote.disabled = eco.soft + 1e-6 < next_cost

func _update_upgrade_buttons() -> void:
	var prod_cost := eco.upgrade_cost("prod_1")
	var cap_cost := eco.upgrade_cost("cap_1")
	var auto_cost := eco.upgrade_cost("auto_1")
	btn_prod.text = "Feeding Efficiency (%s 🥚)" % _format_num(prod_cost)
	btn_cap.text = "Coop Capacity (%s 🥚)" % _format_num(cap_cost)
	var auto_allowed := eco.can_purchase_upgrade("auto_1")
	btn_prod.disabled = (not eco.can_purchase_upgrade("prod_1")) or eco.soft + 1e-6 < prod_cost
	btn_cap.disabled = (not eco.can_purchase_upgrade("cap_1")) or eco.soft + 1e-6 < cap_cost
	var auto_requires := bal.upgrades.get("auto_1", {}).get("requires", "-")
	var auto_requirement_text := ""
	if not auto_allowed and typeof(auto_requires) == TYPE_STRING and auto_requires.begins_with("factory>="):
		var parts := auto_requires.split(">=")
		if parts.size() >= 2:
			var need := int(parts[1])
			var stage := eco.factory_name(need)
			if stage != "":
				auto_requirement_text = " — Requires %s" % stage
	btn_auto.text = "Auto-Feeder System (%s 🥚)%s" % [_format_num(auto_cost), auto_requirement_text]
	btn_auto.disabled = (not auto_allowed) or eco.soft + 1e-6 < auto_cost

func _update_research_view() -> void:
	lbl_research.text = "Innovation Lab — Research Points: %d" % res.prestige_points
	var nodes = [
		{"id": "r_prod_1", "label": "Feed Conversion R&D", "button": btn_r_prod},
		{"id": "r_cap_1", "label": "Modular Coops", "button": btn_r_cap},
		{"id": "r_auto_1", "label": "Drone Feeders", "button": btn_r_auto},
	]
	for entry in nodes:
		var node_id: String = entry["id"]
		var button: Button = entry["button"]
		if res.owned.has(node_id):
			button.text = "%s ✅" % entry["label"]
			button.disabled = true
		else:
			var cost := _research_cost(node_id)
			button.text = "%s (%d 🌟)" % [entry["label"], cost]
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
	if gained > 0:
		print("Rebrand complete — gained %d 🌟" % gained)
	_update_all_views()

func _show_offline_popup(amount: float) -> void:
	offline_label.text = "While you were away: +%s Egg Credits" % _format_num(amount)
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
