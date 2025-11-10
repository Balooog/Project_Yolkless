extends Node

const CACHE_KEYS := [
	"rendering/shader_compilation/cache/enable",
	"rendering/shader_compilation/cache/enabled",
	"rendering/shader_compilation/shader_cache/enable",
	"rendering/shader_compilation/shader_cache/enabled",
	"rendering/shader_compilation/disk_cache/enable",
	"rendering/shaders/shader_cache/enable",
	"rendering/shaders/shader_cache/enabled"
]

const USER_DIRS := [
	"user://logs",
	"user://telemetry",
	"user://perf",
	"user://screenshots/ui_baseline",
	"user://screenshots/ui_current",
	"user://cache/godot/shader_cache"
]

func _enter_tree() -> void:
	_disable_shader_cache()
	_ensure_user_dirs()
	_write_probe()

func _disable_shader_cache() -> void:
	for key in CACHE_KEYS:
		if ProjectSettings.has_setting(key):
			ProjectSettings.set_setting(key, false)

func _ensure_user_dirs() -> void:
	for dir_path in USER_DIRS:
		var absolute_path := ProjectSettings.globalize_path(dir_path)
		DirAccess.make_dir_recursive_absolute(absolute_path)

func _write_probe() -> void:
	var probe_path := ProjectSettings.globalize_path("user://logs/earlyboot_probe.log")
	DirAccess.make_dir_recursive_absolute(probe_path.get_base_dir())
	var file := FileAccess.open(probe_path, FileAccess.WRITE)
	if file:
		file.store_line("[EarlyBoot] cache_disabled=true")
		file.close()
