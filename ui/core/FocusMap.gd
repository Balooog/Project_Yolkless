extends Node
class_name FocusMap

var _graph: Dictionary = {}
var _actions: Dictionary = {}

func register_node(id: StringName, control: Control, neighbours: Dictionary = {}) -> void:
	if control == null:
		return
	_graph[id] = {
		"node": control,
		"neighbours": neighbours.duplicate(true)
	}

func clear() -> void:
	_graph.clear()
	_actions.clear()

func set_neighbour(id: StringName, direction: StringName, target_id: StringName) -> void:
	if not _graph.has(id):
		return
	var node_data_variant: Variant = _graph[id]
	if not (node_data_variant is Dictionary):
		return
	var node_data: Dictionary = node_data_variant
	var neighbours_value: Variant = node_data.get("neighbours", {})
	var neighbours: Dictionary = neighbours_value if neighbours_value is Dictionary else {}
	neighbours[direction] = target_id
	node_data["neighbours"] = neighbours
	_graph[id] = node_data

func add_action(action: StringName, callback: Callable) -> void:
	_actions[action] = callback

func focus(id: StringName) -> void:
	var node_data_variant: Variant = _graph.get(id, {})
	if not (node_data_variant is Dictionary):
		return
	var node_data: Dictionary = node_data_variant
	var control_variant: Variant = node_data.get("node", null)
	if control_variant is Control:
		var control: Control = control_variant as Control
		if not control.is_visible_in_tree():
			return
		if control.focus_mode == Control.FOCUS_NONE:
			return
		control.grab_focus()

func move(current_id: StringName, direction: StringName) -> StringName:
	var node_data_variant: Variant = _graph.get(current_id, {})
	if not (node_data_variant is Dictionary):
		return current_id
	var node_data: Dictionary = node_data_variant
	var neighbours_variant: Variant = node_data.get("neighbours", {})
	var neighbours: Dictionary = neighbours_variant if neighbours_variant is Dictionary else {}
	if neighbours.has(direction):
		var target_variant: Variant = neighbours[direction]
		if target_variant is StringName:
			var target_id: StringName = target_variant
			focus(target_id)
			return target_id
	return current_id

func trigger(action: StringName) -> void:
	if _actions.has(action):
		var callback: Callable = _actions[action]
		if callback.is_valid():
			callback.call()

func validate() -> bool:
	for id in _graph.keys():
		var node_data_variant: Variant = _graph[id]
		if not (node_data_variant is Dictionary):
			return false
		var node_data: Dictionary = node_data_variant
		if not node_data.has("node"):
			return false
	return true
