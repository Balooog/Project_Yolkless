extends SceneTree

const UILINT_SCRIPT := preload("res://ui/core/UILint.gd")

var target_scene: String = ""

func _init() -> void:
	if OS.get_cmdline_user_args().size() > 0:
		target_scene = OS.get_cmdline_user_args()[0]
	call_deferred("_run")

func _run() -> void:
	if target_scene == "":
		printerr("uilint_scene.gd: no scene path provided")
		quit(1)
		return
	var packed: PackedScene = load(target_scene) as PackedScene
	if packed == null:
		printerr("uilint_scene.gd: failed to load %s" % target_scene)
		quit(1)
		return
	var root_instance: Node = packed.instantiate()
	if root_instance == null:
		printerr("uilint_scene.gd: instantiate failed for %s" % target_scene)
		quit(1)
		return
	var tree_root: Node = get_root()
	if tree_root == null:
		printerr("uilint_scene.gd: scene tree root unavailable")
		quit(1)
		return
	tree_root.add_child(root_instance)
	var control_root := root_instance as Control
	if control_root == null:
		printerr("uilint_scene.gd: %s is not a Control root" % target_scene)
		quit(1)
		return
	var lint_variant: Object = UILINT_SCRIPT.new()
	if lint_variant == null:
		printerr("uilint_scene.gd: failed to instantiate UILint")
		quit(1)
		return
	if not lint_variant is Node:
		printerr("uilint_scene.gd: UILint script does not extend Node")
		quit(1)
		return
	var lint_node: Node = lint_variant as Node
	tree_root.add_child(lint_node)
	var result_variant: Variant = lint_node.call("run", control_root)
	if not result_variant is Dictionary:
		printerr("uilint_scene.gd: UILint returned non-dictionary result")
		quit(1)
		return
	var result: Dictionary = result_variant as Dictionary
	print("[UILint] summary for %s: %s" % [target_scene, result])
	var issues := 0
	for key in result.keys():
		var arr := result[key] as Array
		issues += arr.size()
	if issues > 0:
		printerr("[UILint] detected %d issue(s)" % issues)
		quit(1)
	else:
		print("[UILint] no issues detected")
		quit()
