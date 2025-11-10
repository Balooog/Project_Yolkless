extends SceneTree

func _initialize() -> void:
	call_deferred("_write_probe_and_quit")

func _write_probe_and_quit() -> void:
	await get_tree().process_frame
	var path := ProjectSettings.globalize_path("user://logs/window_probe.log")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_line("window_smoke ok")
		file.close()
	quit()
