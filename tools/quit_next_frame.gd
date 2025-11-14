extends SceneTree

var _main_scene_instance: Node

func _initialize() -> void:
	_boot_main_scene()
	call_deferred("_write_probe_and_quit")

func _boot_main_scene() -> void:
	var main_scene_path: String = str(ProjectSettings.get_setting("application/run/main_scene", ""))
	if main_scene_path == "":
		return
	if !ResourceLoader.exists(main_scene_path):
		push_error("quit_next_frame: main scene not found: %s" % main_scene_path)
		return
	var packed: Resource = load(main_scene_path)
	if packed is PackedScene:
		_main_scene_instance = packed.instantiate()
		root.add_child(_main_scene_instance)

func _write_probe_and_quit() -> void:
	await process_frame
	var path: String = ProjectSettings.globalize_path("user://logs/window_probe.log")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_line("window_smoke ok")
		file.close()
	quit()
