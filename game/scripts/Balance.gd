extends Node
class_name Balance

signal reloaded

var constants := {}
var upgrades := {}
var factory_tiers := {}
var automation := {}
var research := {}
var prestige := {}
var prices := {}
var hud_flags := {}

@export var balance_path := "res://game/data/balance.tsv"

func _ready() -> void:
	load_balance()
	Input.set_custom_mouse_cursor(null)

func load_balance() -> void:
	constants.clear()
	upgrades.clear()
	factory_tiers.clear()
	automation.clear()
	research.clear()
	prestige.clear()
	prices.clear()
	hud_flags.clear()

	var file := FileAccess.open(balance_path, FileAccess.READ)
	if file == null:
		_log("ERROR", "BALANCE", "Failed to open balance file", {"path": balance_path})
		return

	var section := ""
	while file.get_position() < file.get_length():
		var raw := file.get_line()
		if raw.strip_edges() == "" or raw.begins_with("#"):
			continue
		if raw.begins_with("[") and raw.ends_with("]"):
			section = raw.substr(1, raw.length() - 2)
			continue
		var cols := raw.split("\t")
		match section:
			"CONSTANTS":
				if cols.size() >= 2:
					constants[cols[0]] = _to_number(cols[1])
			"UPGRADES":
				if cols[0] == "id":
					continue
				var d := {
					"id": cols[0],
					"kind": cols[1],
					"stat": cols[2],
					"mult_add": _to_number(cols[3]),
					"mult_mul": _to_number(cols[4]),
					"base_cost": _to_number(cols[5]),
					"growth": _to_number(cols[6]),
					"requires": cols[7],
					"visible": true,
				}
				upgrades[d["id"]] = d
			"FACTORY_TIERS":
				if cols[0] == "tier":
					continue
				var tier := int(cols[0])
				factory_tiers[tier] = {
					"tier": tier,
					"name": cols[1],
					"cap_mult": _to_number(cols[2]),
					"prod_mult": _to_number(cols[3]),
					"unlocks": cols[4],
					"cost": _to_number(cols[5]),
				}
			"AUTOMATION":
				if cols[0] == "id":
					continue
				automation[cols[0]] = {
					"id": cols[0],
					"type": cols[1],
					"value": _to_number(cols[2]),
					"desc": cols[3],
				}
			"RESEARCH":
				if cols[0] == "id":
					continue
				research[cols[0]] = {
					"id": cols[0],
					"branch": cols[1],
					"stat": cols[2],
					"mult_add": _to_number(cols[3]),
					"mult_mul": _to_number(cols[4]),
					"cost": int(_to_number(cols[5])),
					"prereq": cols[6],
				}
			"PRESTIGE":
				if cols.size() >= 2:
					prestige[cols[0]] = _to_number(cols[1])
			"PRICES":
				if cols[0] == "id" or cols[0] == "ID":
					continue
				if cols.size() >= 4:
					var row := {
						"id": cols[0],
						"type": cols[1],
						"price": _to_number(cols[2]),
						"visible": _to_bool(cols[3]),
						"notes": ""
					}
					if cols.size() >= 5:
						row["notes"] = cols[4]
					prices[row["id"]] = row
			"HUD_FLAGS":
				if cols.size() >= 2:
					hud_flags[cols[0]] = _to_bool(cols[1])
	file.close()
	_apply_price_overrides()
	var md5 := _hash_from_logger(balance_path)
	_log("INFO", "BALANCE", "Balance data reloaded", {
		"upgrades": upgrades.size(),
		"tiers": factory_tiers.size(),
		"research": research.size(),
		"prices": prices.size(),
		"hud_flags": hud_flags.size(),
		"md5": md5
	})
	reloaded.emit()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			load_balance()
			var strings_node := get_node_or_null("/root/Strings")
			if strings_node is StringsCatalog:
				(strings_node as StringsCatalog).load("res://game/data/strings_egg.tsv")

func _to_number(s: String) -> float:
	var v := s.to_float()
	return v

func _to_bool(s: String) -> bool:
	if s == "":
		return false
	var lowered := s.strip_edges().to_lower()
	return lowered == "1" or lowered == "true" or lowered == "yes" or lowered == "on"

func _log(level: String, category: String, message: String, context: Dictionary = {}) -> void:
	var logger_node := get_node_or_null("/root/Logger")
	if logger_node is YolkLogger:
		(logger_node as YolkLogger).log(level, category, message, context)

func _hash_from_logger(path: String) -> String:
	var logger_node := get_node_or_null("/root/Logger")
	if logger_node is YolkLogger:
		return (logger_node as YolkLogger).hash_md5_from_file(path)
	return ""

func _apply_price_overrides() -> void:
	for id in prices.keys():
		if not upgrades.has(id):
			continue
		var upgrade: Dictionary = upgrades[id]
		var price_row: Dictionary = prices[id]
		if price_row.get("type", "") != "UPGRADE":
			continue
		var override_price: float = float(price_row.get("price", upgrade.get("base_cost", 0.0)))
		upgrade["base_cost"] = override_price
		var visible_override: bool = price_row.get("visible", true)
		upgrade["visible"] = visible_override
		if price_row.get("notes", "") != "":
			upgrade["notes"] = price_row["notes"]
		upgrades[id] = upgrade
