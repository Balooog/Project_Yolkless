extends Node
class_name Balance

signal reloaded

var constants := {}
var upgrades := {}
var factory_tiers := {}
var automation := {}
var research := {}
var prestige := {}

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

	var file := FileAccess.open(balance_path, FileAccess.READ)
	if file == null:
		push_error("Balance: cannot open %s" % balance_path)
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
	file.close()
	print("Balance loaded: %d upgrades, %d tiers, %d research" % [upgrades.size(), factory_tiers.size(), research.size()])
	reloaded.emit()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			load_balance()

func _to_number(s: String) -> float:
	var v := s.to_float()
	return v
