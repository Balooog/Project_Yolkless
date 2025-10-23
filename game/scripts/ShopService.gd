extends Node
class_name ShopService

signal state_changed(id: String)

var balance: Balance
var economy: Economy

var _state_cache: Dictionary = {}

const DISPLAY_NAMES := {
	"prod_1": "Feeding Efficiency L1",
	"cap_1": "Coop Capacity L1",
	"auto_1": "Auto-Feeder System",
	"feed_storage": "Feed Storage L1",
	"feed_refill": "Feed Refill L1",
	"feed_efficiency": "Feed Efficiency L1",
}

func setup(balance_ref: Balance, economy_ref: Economy) -> void:
	balance = balance_ref
	economy = economy_ref
	_state_cache.clear()
	_connect_sources()
	_broadcast_all()

func list_all_items() -> Array:
	if balance == null:
		return []
	var ids: Array = balance.upgrades.keys()
	ids.sort()
	return ids

func get_price(id: String) -> float:
	if economy == null:
		return 0.0
	return economy.upgrade_cost(id)

func is_visible(id: String) -> bool:
	if balance == null or not balance.upgrades.has(id):
		return false
	return bool(balance.upgrades[id].get("visible", true))

func required_stage(id: String) -> int:
	if balance == null or not balance.upgrades.has(id):
		return 0
	return _parse_factory_requirement(String(balance.upgrades[id].get("requires", "-")))

func stage_ok(id: String, tier: int = -1) -> bool:
	var required: int = required_stage(id)
	if required <= 0:
		return true
	var active_tier: int = tier
	if active_tier < 0 and economy != null:
		active_tier = economy.factory_tier
	return active_tier >= required

func display_name(id: String) -> String:
	if DISPLAY_NAMES.has(id):
		return DISPLAY_NAMES[id]
	return id

func stage_display_name(tier: int) -> String:
	if tier <= 0:
		return ""
	if economy != null:
		var econ_name: String = economy.factory_name(tier)
		if econ_name != "":
			return econ_name
	if balance != null and balance.factory_tiers.has(tier):
		return String(balance.factory_tiers[tier].get("name", "Stage %d" % tier))
	return "Stage %d" % tier

func get_item_state(id: String) -> Dictionary:
	return _build_state(id)

func requirement_text(id: String) -> String:
	var state: Dictionary = get_item_state(id)
	if int(state.get("stage_required", 0)) <= 0:
		return ""
	if bool(state.get("stage_ok", true)):
		return ""
	var stage_name: String = String(state.get("stage_name", ""))
	if stage_name == "":
		stage_name = "Stage %d" % int(state.get("stage_required", 0))
	return "Requires %s" % stage_name

func _connect_sources() -> void:
	if balance != null and not balance.reloaded.is_connected(_on_balance_reloaded):
		balance.reloaded.connect(_on_balance_reloaded)
	if economy != null:
		if not economy.soft_changed.is_connected(_on_soft_changed):
			economy.soft_changed.connect(_on_soft_changed)
		if not economy.tier_changed.is_connected(_on_tier_changed):
			economy.tier_changed.connect(_on_tier_changed)

func _on_balance_reloaded() -> void:
	_state_cache.clear()
	_broadcast_all()

func _on_soft_changed(_value: float) -> void:
	_broadcast_all()

func _on_tier_changed(_tier: int) -> void:
	_broadcast_all()

func _broadcast_all() -> void:
	for id in list_all_items():
		if _refresh_state(id):
			state_changed.emit(id)

func _refresh_state(id: String) -> bool:
	var state: Dictionary = _build_state(id)
	var last: Variant = _state_cache.get(id, null)
	if last == null or last != state:
		_state_cache[id] = state.duplicate(true)
		return true
	return false

func _build_state(id: String) -> Dictionary:
	var state: Dictionary = {
		"id": id,
		"visible": false,
		"price": 0.0,
		"enabled": false,
		"reasons": PackedStringArray(),
		"reason_text": "",
		"stage_required": 0,
		"stage_name": "",
		"stage_ok": true,
		"missing_amount": 0,
	}
	if balance == null or economy == null:
		state["reasons"] = PackedStringArray(["uninitialized"])
		state["reason_text"] = "Locked: uninitialized"
		return state
	if not balance.upgrades.has(id):
		state["reasons"] = PackedStringArray(["unknown upgrade"])
		state["reason_text"] = "Locked: unknown upgrade"
		return state
	var upgrade: Dictionary = balance.upgrades[id]
	var visible: bool = bool(upgrade.get("visible", true))
	state["visible"] = visible
	var price: float = economy.upgrade_cost(id)
	state["price"] = price
	var stage_required: int = _parse_factory_requirement(String(upgrade.get("requires", "-")))
	state["stage_required"] = stage_required
	var stage_name: String = stage_display_name(stage_required)
	state["stage_name"] = stage_name
	var stage_ok: bool = stage_required <= 0 or economy.factory_tier >= stage_required
	state["stage_ok"] = stage_ok
	var price_valid: bool = price > 0.0
	var affordable: bool = price_valid and (economy.soft + 1e-6 >= price)
	var reasons: PackedStringArray = PackedStringArray()
	if not visible:
		reasons.append("hidden")
	if stage_required > 0 and not stage_ok:
		if stage_name != "":
			reasons.append("requires %s" % stage_name)
		else:
			reasons.append("requires stage %d" % stage_required)
	if not price_valid:
		reasons.append("price=0 (not bound)")
	if price_valid and not affordable:
		var missing: int = int(ceil(max(price - economy.soft, 0.0)))
		if missing > 0:
			state["missing_amount"] = missing
			reasons.append("need %d more" % missing)
	if reasons.is_empty():
		if not economy.can_purchase_upgrade(id):
			reasons.append("requirements unmet")
	var enabled: bool = reasons.is_empty()
	state["enabled"] = enabled
	state["reasons"] = reasons
	state["reason_text"] = "" if enabled else "Locked: " + _join_reasons(reasons)
	return state

func _parse_factory_requirement(raw: String) -> int:
	if raw == "" or raw == "-":
		return 0
	if raw.begins_with("factory>="):
		var parts: PackedStringArray = raw.split(">=")
		if parts.size() >= 2:
			return int(parts[1])
	return 0

func _join_reasons(reasons: PackedStringArray) -> String:
	var summary: String = ""
	for i in range(reasons.size()):
		if i > 0:
			summary += ", "
		summary += reasons[i]
	return summary
