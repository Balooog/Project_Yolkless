extends SceneTree

const SandboxGrid: GDScript = preload("res://src/sandbox/SandboxGrid.gd")

var _had_failure: bool = false

func _init() -> void:
	_run()

func _run() -> void:
	_test_buffers_are_distinct()
	_test_sand_falls()
	_test_liquid_falls()
	_test_compute_comfort_components()
	if _had_failure:
		print("SandboxGrid suite: failures detected")
		quit(1)
	print("SandboxGrid suite: all checks passed")
	quit()

func _test_buffers_are_distinct() -> void:
	var grid: SandboxGrid = SandboxGrid.new()
	grid._reset_buffers()
	grid._current[0][0] = SandboxGrid.MATERIAL_SAND
	_assert_eq(
		grid._next[0][0],
		SandboxGrid.MATERIAL_AIR,
		"next buffer should not alias current buffer"
	)

func _test_sand_falls() -> void:
	var grid: SandboxGrid = SandboxGrid.new()
	grid._reset_buffers()
	grid._current[0][0] = SandboxGrid.MATERIAL_SAND
	grid.step(0.016)
	_assert_eq(
		grid._current[1][0],
		SandboxGrid.MATERIAL_SAND,
		"sand should settle one cell down"
	)
	_assert_eq(
		grid._current[0][0],
		SandboxGrid.MATERIAL_AIR,
		"sand origin should be cleared after falling"
	)

func _test_liquid_falls() -> void:
	var grid: SandboxGrid = SandboxGrid.new()
	grid._reset_buffers()
	grid._current[0][0] = SandboxGrid.MATERIAL_WATER
	grid.step(0.016)
	_assert_eq(
		grid._current[1][0],
		SandboxGrid.MATERIAL_WATER,
		"liquid should fall into the cell below when open"
	)
	_assert_eq(
		grid._current[0][0],
		SandboxGrid.MATERIAL_AIR,
		"source cell should clear after liquid descends"
	)

func _test_compute_comfort_components() -> void:
	var grid: SandboxGrid = SandboxGrid.new()
	grid._reset_buffers()
	grid._current[0][0] = SandboxGrid.MATERIAL_PLANT
	grid._current[0][1] = SandboxGrid.MATERIAL_STONE
	var report: Dictionary = grid.compute_comfort()
	_assert_almost(
		report.get("stability", 0.0),
		1.0,
		0.001,
		"stability should be 1.0 when no step has run"
	)
	_assert_true(
		report.get("diversity", 0.0) > 0.0,
		"diversity should reflect multiple materials"
	)
	_assert_true(
		report.get("ci", 0.0) >= 0.0 and report.get("ci", 0.0) <= 1.0,
		"comfort index must be normalized"
	)

func _assert_eq(actual, expected, message: String) -> void:
	if actual != expected:
		_fail("%s (expected=%s, actual=%s)" % [message, expected, actual])

func _assert_almost(actual: float, expected: float, epsilon: float, message: String) -> void:
	if abs(actual - expected) > epsilon:
		_fail("%s (expected≈%.4f, actual=%.4f)" % [message, expected, actual])

func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)

func _fail(message: String) -> void:
	push_error(message)
	_had_failure = true
