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

func set_neighbour(id: StringName, direction: StringName, target_id: StringName) -> void:
	if not _graph.has(id):
		return
	var node_data := _graph[id]
	var neighbours: Dictionary = node_data.get("neighbours", {})
	neighbours[direction] = target_id
	node_data["neighbours"] = neighbours
	_graph[id] = node_data

func add_action(action: StringName, callback: Callable) -> void:
	_actions[action] = callback

func focus(id: StringName) -> void:
	var node_data := _graph.get(id, {})
	var control := node_data.get("node", null)
	if control is Control:
		(control as Control).grab_focus()

func move(current_id: StringName, direction: StringName) -> StringName:
	var node_data := _graph.get(current_id, {})
	var neighbours: Dictionary = node_data.get("neighbours", {})
	if neighbours.has(direction):
		var target_id: StringName = neighbours[direction]
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
		var node_data := _graph[id]
		if not node_data.has("node"):
			return false
	return true
