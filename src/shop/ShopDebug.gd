extends Node
class_name ShopDebug

var shop: ShopService
var economy: Economy
var _probe_scheduled: bool = false

func setup(shop_service: ShopService, economy_ref: Economy) -> void:
	shop = shop_service
	economy = economy_ref
	if shop != null and not shop.state_changed.is_connected(_on_shop_state_changed):
		shop.state_changed.connect(_on_shop_state_changed)
	call_deferred("probe_all")

func probe_all() -> void:
	if shop == null:
		push_warning("[ShopDebug] ShopService unavailable; skipping probe.")
		return
	var ids: Array = shop.list_all_items()
	ids.sort()
	var credits: float = economy.soft if economy != null else 0.0
	for id in ids:
		var state: Dictionary = shop.get_item_state(id)
		var reasons_value: Variant = state.get("reasons", PackedStringArray())
		var reasons: PackedStringArray = reasons_value if reasons_value is PackedStringArray else PackedStringArray(reasons_value)
		var reasons_text: String = "ok"
		if reasons.size() > 0:
			reasons_text = ""
			for index in range(reasons.size()):
				if index > 0:
					reasons_text += ", "
				reasons_text += reasons[index]
		var price: float = float(state.get("price", 0.0))
		var enabled: bool = bool(state.get("enabled", false))
		print("[ShopDebug] %s -> price=%s, credits=%.1f, enabled=%s, reasons=[%s]" % [
			shop.display_name(id),
			_format_price(price),
			credits,
			str(enabled),
			reasons_text
		])

func _on_shop_state_changed(_id: String) -> void:
	if _probe_scheduled:
		return
	_probe_scheduled = true
	call_deferred("_flush_probe")

func _flush_probe() -> void:
	_probe_scheduled = false
	probe_all()

func _format_price(value: float) -> String:
	if value <= 0.0:
		return "0"
	if value >= 1000.0:
		return String.num(value, 0)
	var rounded: int = int(round(value))
	if abs(value - float(rounded)) <= 0.05:
		return str(rounded)
	return String.num(value, 1)
