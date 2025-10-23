extends SceneTree

func _initialize() -> void:
	if root is Window:
		(root as Window).size = Vector2i(1280, 720)
	var scene = load("res://game/scenes/Main.tscn")
	if scene == null:
		push_error("Failed to load Main scene")
		quit(1)
		return
	var main = scene.instantiate()
	if main == null:
		push_error("Failed to instantiate Main scene")
		quit(1)
		return
	root.add_child(main)
	for i in range(6):
		await process_frame
	var proto = main.get("ui_prototype")
	if proto == null:
		print("Prototype UI missing")
		quit()
		return
	var nodes := {
		"canvas": proto.get_node("RootMargin/RootStack/MainStack/CanvasWrapper/CanvasPanel"),
		"sheet_overlay": proto.get_node("RootMargin/RootStack/MainStack/CanvasWrapper/MobileSheetAnchor/SheetOverlay"),
		"home_sheet": proto.get_node("RootMargin/RootStack/MainStack/CanvasWrapper/MobileSheetAnchor/SheetOverlay/HomeSheet"),
		"env": proto.get_environment_panel(),
		"side_dock": proto.get_node("RootMargin/RootStack/MainStack/SideDock")
	}
	for name in nodes.keys():
		var node = nodes[name]
		if node == null:
			print(name, ": missing")
		elif node is Control:
			var rect := (node as Control).get_global_rect()
			print(name, ": position=", rect.position, " size=", rect.size)

	quit()
