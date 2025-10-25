extends SceneTree

var scenes: Array[String] = []
var viewport_sizes: Array[Vector2i] = [
	Vector2i(640, 360),
	Vector2i(1280, 720),
	Vector2i(1920, 1080)
]
var output_dir: String = "user://ui_screenshots"

func _init() -> void:
	call_deferred("_execute")

func _execute() -> void:
	# Stub implementation; PX-010.9 will flesh out capture workflow.
	print("ui_screenshots.gd placeholder — scenes=%s output=%s" % [scenes, output_dir])
	quit()
