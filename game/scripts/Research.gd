extends Node
class_name Research

signal changed

var owned: Dictionary = {}
var multipliers := {
	"mul_prod": 1.0,
	"mul_cap": 1.0,
	"auto_cd": 0.0,
}

var prestige_points := 0

var _balance: Balance

func setup(balance: Balance) -> void:
	_balance = balance
	_balance.reloaded.connect(_recalc)

func can_buy(id: String) -> bool:
	if not _balance.research.has(id):
		return false
	if owned.has(id):
		return false
	var node := _balance.research[id]
	var prereq := node.get("prereq", "-")
	if prereq != "-" and not owned.has(prereq):
		return false
	return prestige_points >= int(node.get("cost", 0))

func buy(id: String) -> bool:
	if not can_buy(id):
		return false
	var node := _balance.research[id]
	var cost := int(node.get("cost", 0))
	prestige_points -= cost
	owned[id] = true
	_apply_node(node)
	changed.emit()
	return true

func _apply_node(node: Dictionary) -> void:
	var stat := node.get("stat", "")
	var mult_mul := float(node.get("mult_mul", 1.0))
	var mult_add := float(node.get("mult_add", 0.0))
	match stat:
		"mul_prod":
			multipliers["mul_prod"] *= mult_mul
			multipliers["mul_prod"] += mult_add
		"mul_cap":
			multipliers["mul_cap"] *= mult_mul
			multipliers["mul_cap"] += mult_add
		"auto_cd":
			multipliers["auto_cd"] += mult_add
		_:
			push_warning("Research: unhandled stat %s" % stat)

func _recalc() -> void:
	multipliers = {"mul_prod": 1.0, "mul_cap": 1.0, "auto_cd": 0.0}
	for id in owned.keys():
		if _balance.research.has(id):
			_apply_node(_balance.research[id])
	changed.emit()

func reapply_all() -> void:
	_recalc()
