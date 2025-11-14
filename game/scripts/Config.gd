extends Node

@export var logging_enabled: bool = true
@export var logging_force_disable: bool = false
@export var seed: int = 0
@export_enum("legacy", "sandbox") var env_renderer: String = "sandbox"
@export_enum("diorama", "map") var sandbox_view: String = "diorama"
@export var economy_amortize_shipment: bool = false
@export var pseudo_localization_enabled: bool = false

func is_pseudo_localization_enabled() -> bool:
	if OS.has_environment("PSEUDO_LOC"):
		var raw := OS.get_environment("PSEUDO_LOC").strip_edges().to_lower()
		if raw != "":
			return raw in ["1", "true", "yes", "on"]
	return pseudo_localization_enabled
