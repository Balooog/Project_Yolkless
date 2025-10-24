extends SceneTree

const SandboxGrid: GDScript = preload("res://src/sandbox/SandboxGrid.gd")

var _had_failure: bool = false

func _init() -> void:
	_run()

func _run() -> void:
	_test_buffers_are_distinct()
	_test_sand_falls()
	_test_liquid_falls()
	_test_liquid_slides_left_when_blocked()
	_test_liquid_slides_right_when_blocked()
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

func _test_liquid_slides_left_when_blocked() -> void:
	var grid: SandboxGrid = SandboxGrid.new()
	grid.set_random_number_generator(_rng_for_direction(true))
	grid._reset_buffers()
	grid._current[0][1] = SandboxGrid.MATERIAL_WATER
	grid._current[1][1] = SandboxGrid.MATERIAL_STONE
	grid._current[0][0] = SandboxGrid.MATERIAL_AIR
	grid._current[0][2] = SandboxGrid.MATERIAL_STONE
	grid.step(0.016)
	_assert_eq(
		grid._current[0][0],
		SandboxGrid.MATERIAL_WATER,
		"liquid should slide left when below is blocked and left is open"
	)
	_assert_eq(
		grid._current[0][1],
		SandboxGrid.MATERIAL_AIR,
		"origin cell should clear after lateral slide"
	)

func _test_liquid_slides_right_when_blocked() -> void:
	var grid: SandboxGrid = SandboxGrid.new()
	grid.set_random_number_generator(_rng_for_direction(false))
	grid._reset_buffers()
	grid._current[0][1] = SandboxGrid.MATERIAL_WATER
	grid._current[1][1] = SandboxGrid.MATERIAL_STONE
	grid._current[0][0] = SandboxGrid.MATERIAL_STONE
	grid._current[0][2] = SandboxGrid.MATERIAL_AIR
	grid.step(0.016)
	_assert_eq(
		grid._current[0][2],
		SandboxGrid.MATERIAL_WATER,
		"liquid should slide right when below is blocked and right is open"
	)
	_assert_eq(
		grid._current[0][1],
		SandboxGrid.MATERIAL_AIR,
		"origin cell should clear after lateral slide"
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

func _rng_for_direction(want_left: bool) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	for seed in range(1, 1000):
		rng.seed = seed
		var sample: float = rng.randf()
		var satisfied: bool = sample < 0.5 if want_left else sample >= 0.5
		if satisfied:
			rng.seed = seed
			return rng
	_fail("Could not find RNG seed for direction (want_left=%s)" % want_left)
	return rng

func _fail(message: String) -> void:
	push_error(message)
	_had_failure = true
