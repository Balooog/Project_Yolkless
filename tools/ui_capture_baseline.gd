extends SceneTree

const DEFAULT_OUTPUT := "res://dev/screenshots/ui_baseline"
const VIEWPORT_SIZE := Vector2i(1280, 720)
const BASELINE_SCENES := [
	{"path": "res://scenes/ui_baseline/hud_blank_reference.tscn", "out": "hud_blank_reference.png"},
	{"path": "res://scenes/ui_baseline/hud_power_normal.tscn", "out": "hud_power_normal.png"},
	{"path": "res://scenes/ui_baseline/hud_power_warning.tscn", "out": "hud_power_warning.png"},
	{"path": "res://scenes/ui_baseline/hud_power_critical.tscn", "out": "hud_power_critical.png"}
]
const TOAST_RECT := Rect2i(Vector2i(340, 624), Vector2i(600, 72))
const SAFE_AREA := Rect2i(Vector2i(32, 24), Vector2i(1216, 672))

var _output_dir := DEFAULT_OUTPUT
var _root_viewport: Viewport

func _init() -> void:
	_parse_args()
	call_deferred("_run_capture")

func _ready() -> void:
	_ensure_viewport()

func _ensure_viewport() -> void:
	if _root_viewport:
		return
	_root_viewport = get_root()
	_root_viewport.size = VIEWPORT_SIZE
	DisplayServer.window_set_size(VIEWPORT_SIZE)
	_root_viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR

func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			var custom := arg.substr("--output=".length())
			if custom != "":
				_output_dir = custom

func _log(message: String) -> void:
	print("[baseline]", message)

func _absolute_output_dir() -> String:
	return ProjectSettings.globalize_path(_output_dir)

func _prepare_output_dir() -> void:
	var absolute := _absolute_output_dir()
	if DirAccess.make_dir_recursive_absolute(absolute) != OK:
		push_error("Failed to create output directory: %s" % absolute)

func _capture_viewport_image() -> Image:
	await process_frame
	var texture := _root_viewport.get_texture()
	return texture.get_image()

func _clear_scene(instance: Node) -> void:
	if instance:
		instance.queue_free()
	await process_frame

func _save_png(image: Image, filename: String) -> void:
	_mask_toast(image)
	_mask_outside_safe_area(image)
	var absolute := _absolute_output_dir()
	var full_path := absolute.path_join(filename)
	var err := image.save_png(full_path)
	if err != OK:
		push_error("Failed to save %s (err=%d)" % [full_path, err])
	else:
		_log("saved %s" % full_path)

func _load_scene(path: String) -> PackedScene:
	var scene := load(path)
	if scene == null:
		push_error("Missing baseline scene: %s" % path)
	return scene

func _run_capture() -> void:
	_ensure_viewport()
	await _capture_all()
	quit()

func _capture_all() -> void:
	_prepare_output_dir()
	for entry in BASELINE_SCENES:
		var scene_path: String = entry.get("path", "")
		var out_name: String = entry.get("out", "")
		if scene_path == "" or out_name == "":
			continue
		await _capture_scene(scene_path, out_name)

func _capture_scene(scene_path: String, out_name: String) -> void:
	_log("capturing %s" % scene_path)
	var packed := _load_scene(scene_path)
	if packed == null:
		return
	var instance := packed.instantiate()
	if instance == null:
		push_error("Unable to instantiate %s" % scene_path)
		return
	_root_viewport.add_child(instance)
	await process_frame
	await process_frame
	var image := await _capture_viewport_image()
	_save_png(image, out_name)
	await _clear_scene(instance)

func _mask_toast(image: Image) -> void:
	if TOAST_RECT.size == Vector2i.ZERO:
		return
	var bg := image.get_pixel(0, 0)
	var start_x := TOAST_RECT.position.x
	var end_x := TOAST_RECT.position.x + TOAST_RECT.size.x
	var start_y := TOAST_RECT.position.y
	var end_y := TOAST_RECT.position.y + TOAST_RECT.size.y
	for y in range(start_y, end_y):
		for x in range(start_x, end_x):
			image.set_pixel(x, y, bg)

func _mask_outside_safe_area(image: Image) -> void:
	if SAFE_AREA.size == Vector2i.ZERO:
		return
	var bg := image.get_pixel(0, 0)
	var left := SAFE_AREA.position.x
	var right := SAFE_AREA.position.x + SAFE_AREA.size.x
	var top := SAFE_AREA.position.y
	var bottom := SAFE_AREA.position.y + SAFE_AREA.size.y
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if x < left or x >= right or y < top or y >= bottom:
				image.set_pixel(x, y, bg)
