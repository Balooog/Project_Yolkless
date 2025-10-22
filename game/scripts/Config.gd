extends Node
class_name YolklessConfig

@export var seed: int = 0

var rng: RandomNumberGenerator

func _ready() -> void:
	rng = RandomNumberGenerator.new()
	if seed != 0:
		rng.seed = seed
		_log("INFO", "CONFIG", "Using deterministic seed", {"seed": seed})
	else:
		rng.randomize()
		_log("INFO", "CONFIG", "Random seed generated", {"seed": rng.seed})

func get_seed() -> int:
	return seed

func get_rng() -> RandomNumberGenerator:
	return rng

func _log(level: String, category: String, message: String, context: Dictionary = {}) -> void:
	var logger := get_node_or_null("/root/Logger")
	if logger:
		logger.call("record", level, category, message, context)
