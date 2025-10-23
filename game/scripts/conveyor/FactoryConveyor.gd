extends Node2D
class_name FactoryConveyor

@export var manager_path: NodePath
@export var segment_defs: Array[Dictionary] = []

@onready var belt: ConveyorBelt = %ConveyorBelt

var _manager: ConveyorManager
var _registered: bool = false

func _ready() -> void:
	_manager = _resolve_manager()
	_ensure_curve()
	if belt and not segment_defs.is_empty():
		belt.configure_segments(segment_defs)
	if _manager and belt:
		_manager.register_belt(belt)
		_registered = true
	else:
		push_warning("FactoryConveyor could not locate ConveyorManager; belt inactive.")

func _exit_tree() -> void:
	if _registered and _manager and belt:
		_manager.unregister_belt(belt)
		_registered = false

func _ensure_curve() -> void:
	if belt == null:
		return
	var path := belt.get_node_or_null("Path2D") as Path2D
	if path == null:
		path = Path2D.new()
		path.name = "Path2D"
		belt.add_child(path)
	if path.curve == null or path.curve.get_point_count() < 2:
		var curve := Curve2D.new()
		curve.bake_interval = 16.0
		curve.add_point(Vector2.ZERO, Vector2.ZERO, Vector2(120, 0))
		curve.add_point(Vector2(220, -20), Vector2(-80, 0), Vector2(80, 0))
		curve.add_point(Vector2(440, 10), Vector2(-60, -10), Vector2(0, 0))
		path.curve = curve
		belt.mark_curve_dirty()

func _resolve_manager() -> ConveyorManager:
	if manager_path != NodePath():
		var node := get_node_or_null(manager_path)
		if node is ConveyorManager:
			return node as ConveyorManager
	if get_tree():
		var root := get_tree().current_scene
		if root:
			var candidate := root.get_node_or_null("ConveyorManager")
			if candidate is ConveyorManager:
				manager_path = candidate.get_path()
				return candidate as ConveyorManager
	return null
