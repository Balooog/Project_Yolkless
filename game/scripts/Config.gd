extends Node

@export var logging_enabled: bool = true
@export var logging_force_disable: bool = false
@export var seed: int = 0
@export_enum("legacy", "sandbox") var env_renderer: String = "sandbox"
