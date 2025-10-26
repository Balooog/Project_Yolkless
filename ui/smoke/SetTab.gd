extends Control

@export var prototype_path: NodePath = NodePath("Prototype")
@export var tab_id: String = "home"

func _ready() -> void:
	var prototype := get_node_or_null(prototype_path)
	if prototype == null:
		push_warning("SetTab.gd: prototype not found at %s" % [prototype_path])
		return
	if prototype.has_method("show_tab"):
		prototype.call("show_tab", tab_id)
	else:
		push_warning("SetTab.gd: node at %s lacks show_tab()" % [prototype_path])
