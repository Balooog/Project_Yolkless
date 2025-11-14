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
	var env_value := OS.get_environment("YOLKLESS_DISABLE_SHADER_CACHE")
	var should_disable := env_value != "0"
	var cache_disabled := false
	if should_disable:
		cache_disabled = _disable_shader_cache()
	_ensure_user_dirs()
	_write_probe(cache_disabled, env_value)

func _disable_shader_cache() -> bool:
	var touched := false
	for key in CACHE_KEYS:
		if ProjectSettings.has_setting(key):
			ProjectSettings.set_setting(key, false)
			touched = true
	return touched

func _ensure_user_dirs() -> void:
	for dir_path in USER_DIRS:
		var absolute_path := ProjectSettings.globalize_path(dir_path)
		DirAccess.make_dir_recursive_absolute(absolute_path)

func _write_probe(cache_disabled: bool, env_value: String) -> void:
	var probe_path := ProjectSettings.globalize_path("user://logs/earlyboot_probe.log")
	DirAccess.make_dir_recursive_absolute(probe_path.get_base_dir())
	var file := FileAccess.open(probe_path, FileAccess.WRITE)
	if file:
		file.store_line("[EarlyBoot] cache_env=%s cache_disabled=%s" % [env_value if env_value != "" else "<unset>", str(cache_disabled)])
		file.close()
