extends SceneTree

const REQUIRED_DATA := [
	"res://game/data/balance.tsv",
	"res://game/data/strings_egg.tsv",
]

const CRITICAL_SCRIPTS := [
	"res://game/scripts/Main.gd",
	"res://game/scripts/DebugOverlay.gd",
	"res://game/scripts/ProceduralFactory.gd",
	"res://game/scenes/modules/environment/PollutionOverlay.gd",
]

func _initialize():
	var ok := true
	for path in REQUIRED_DATA:
		if FileAccess.open(path, FileAccess.READ) == null:
			push_error("%s missing" % path)
			ok = false

	for script_path in CRITICAL_SCRIPTS:
		if not _assert_resource_loads(script_path):
			ok = false

	if not _exercise_procedural_styles():
		ok = false

	if not _instantiate_pollution_overlay():
		ok = false

	if ok:
		print("SMOKE_OK")
	quit(0 if ok else 1)

func _assert_resource_loads(path: String) -> bool:
	var resource := load(path)
	if resource == null:
		push_error("failed to load %s" % path)
		return false
	return true

func _exercise_procedural_styles() -> bool:
	var factory_script := load("res://game/scripts/ProceduralFactory.gd")
	if factory_script == null:
		push_error("ProceduralFactory.gd did not load")
		return false
	var ok := true
	var panel_style = factory_script.make_panel_style(false, false)
	if panel_style == null or not (panel_style is StyleBoxFlat):
		push_error("make_panel_style() did not return a StyleBoxFlat")
		ok = false
	var progress_style = factory_script.make_progress_fill_style(Color.WHITE)
	if progress_style == null or not (progress_style is StyleBoxFlat):
		push_error("make_progress_fill_style() did not return a StyleBoxFlat")
		ok = false
	return ok

func _instantiate_pollution_overlay() -> bool:
	var scene := load("res://game/scenes/modules/environment/PollutionOverlay.tscn")
	if scene == null or not (scene is PackedScene):
		push_error("failed to load PollutionOverlay scene")
		return false
	var instance = scene.instantiate()
	if instance == null:
		push_error("failed to instantiate PollutionOverlay")
		return false
	get_root().add_child(instance)
	get_root().remove_child(instance)
	instance.queue_free()
	return true
