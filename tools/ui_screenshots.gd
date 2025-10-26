extends SceneTree

var scenes: Array[String] = [
	"res://scenes/ui_smoke/MainHUD.tscn",
	"res://scenes/ui_smoke/StoreHUD.tscn",
	"res://scenes/ui_smoke/ResearchHUD.tscn",
	"res://scenes/ui_smoke/AutomationHUD.tscn",
	"res://scenes/ui_smoke/PrestigeHUD.tscn"
]
var output_dir: String = "user://ui_screenshots"

var _viewport_override: Vector2i = Vector2i(1280, 720)
var _capture_enabled: bool = false

func _init() -> void:
	_parse_args()
	call_deferred("_execute")

func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--viewport="):
			var dims := arg.substr("--viewport=".length()).split("x", false)
			if dims.size() == 2:
				var width := dims[0].to_int()
				var height := dims[1].to_int()
				if width > 0 and height > 0:
					_viewport_override = Vector2i(width, height)
		elif arg == "--capture" or arg == "--capture=true":
			_capture_enabled = true

func _execute() -> void:
	var root_viewport := get_root()
	root_viewport.size = _viewport_override
	DisplayServer.window_set_size(_viewport_override)
	var absolute_output := ProjectSettings.globalize_path(output_dir)
	if DirAccess.make_dir_recursive_absolute(absolute_output) != OK:
		printerr("ui_screenshots.gd: failed to create output directory %s" % [absolute_output])

	for scene_path in scenes:
		await _capture_scene(scene_path, absolute_output)

	quit()

func _capture_scene(scene_path: String, absolute_output: String) -> void:
	var packed := load(scene_path) as PackedScene
	if packed == null:
		printerr("ui_screenshots.gd: cannot load %s" % scene_path)
		return

	if not _capture_enabled:
		print("ui_screenshots.gd: capture disabled; skipping %s" % scene_path)
		return

	if OS.has_feature("headless"):
		print("ui_screenshots.gd: headless renderer, skipping capture for %s" % scene_path)
		return

	var instance := packed.instantiate()
	if instance == null:
		printerr("ui_screenshots.gd: cannot instantiate %s" % scene_path)
		return

	instance.name = "SceneUnderTest"
	get_root().add_child(instance)

	# Allow layout to settle across a couple of frames.
	await process_frame
	await process_frame

	var viewport := get_root()
	var texture := viewport.get_texture()
	if texture == null:
		printerr("ui_screenshots.gd: viewport texture unavailable for %s" % scene_path)
		instance.queue_free()
		await process_frame
		return
	var texture_rid := texture.get_rid()
	if not texture_rid.is_valid():
		printerr("ui_screenshots.gd: viewport texture invalid for %s" % scene_path)
		instance.queue_free()
		await process_frame
		return

	var image := texture.get_image()
	if image == null:
		printerr("ui_screenshots.gd: failed to grab image for %s" % scene_path)
		instance.queue_free()
		await process_frame
		return

	image.flip_y()
	var file_base := _scene_basename(scene_path)
	var filename := "%s_%dx%d.png" % [file_base, _viewport_override.x, _viewport_override.y]
	var file_path := absolute_output.path_join(filename)
	var save_result := image.save_png(file_path)
	if save_result != OK:
		printerr("ui_screenshots.gd: failed to save %s (error %d)" % [file_path, save_result])
	else:
		print("ui_screenshots.gd: captured %s" % file_path)

	instance.queue_free()
	await process_frame

func _scene_basename(scene_path: String) -> String:
	var slash := scene_path.rfind("/")
	var dot := scene_path.rfind(".")
	if slash == -1:
		slash = -1
	if dot == -1 or dot < slash:
		dot = scene_path.length()
	return scene_path.substr(slash + 1, dot - slash - 1)
