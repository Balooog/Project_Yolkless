extends SceneTree

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
	var packed := load(target_scene)
	if packed == null:
		printerr("uilint_scene.gd: failed to load %s" % target_scene)
		quit(1)
		return
	var root := packed.instantiate()
	if root == null:
		printerr("uilint_scene.gd: instantiate failed for %s" % target_scene)
		quit(1)
		return
	add_child(root)
	var lint := UILint.new()
	var result := lint.run(root)
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
