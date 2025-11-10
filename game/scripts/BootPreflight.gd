extends Node

const SHADER_CACHE_SETTING_KEYS := [
	"rendering/shader_compilation/cache/enable",
	"rendering/shader_compilation/cache/enabled",
	"rendering/shader_compilation/shader_cache/enable",
	"rendering/shader_compilation/shader_cache/enabled",
	"rendering/shaders/shader_cache/enable",
	"rendering/shaders/shader_cache/enabled"
]

static func ensure_user_dirs() -> void:
	var dirs := [
		"user://",
		"user://logs",
		"user://telemetry",
		"user://perf",
		"user://screenshots/ui_baseline",
		"user://screenshots/ui_current",
		"user://cache/godot/shader_cache"
	]
	for dir_path in dirs:
		var absolute_path := ProjectSettings.globalize_path(dir_path)
		var err := DirAccess.make_dir_recursive_absolute(absolute_path)
		if err != OK:
			push_error("BootPreflight: failed to ensure %s (err=%d)" % [absolute_path, err])

static func configure_runtime_overrides() -> void:
	if OS.get_environment("YOLKLESS_DISABLE_SHADER_CACHE") == "1":
		_disable_shader_cache()

static func _disable_shader_cache() -> void:
	var key := _resolve_shader_cache_setting_key()
	if key == "":
		return
	ProjectSettings.set_setting(key, false)
	if OS.is_debug_build():
		print_debug("BootPreflight: shader cache disabled via %s" % key)

static func _resolve_shader_cache_setting_key() -> String:
	for key in SHADER_CACHE_SETTING_KEYS:
		if ProjectSettings.has_setting(key):
			return key
	return SHADER_CACHE_SETTING_KEYS[0] if SHADER_CACHE_SETTING_KEYS.size() > 0 else ""
