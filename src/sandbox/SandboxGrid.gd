extends RefCounted
class_name SandboxGrid

const WIDTH := 32
const HEIGHT := 18

const MATERIAL_AIR := 0
const MATERIAL_SAND := 1
const MATERIAL_WATER := 2
const MATERIAL_OIL := 3
const MATERIAL_FIRE := 4
const MATERIAL_PLANT := 5
const MATERIAL_STONE := 6
const MATERIAL_STEAM := 7

const MAX_ACTIVE_FRACTION := 0.45
const TOTAL_CELLS := WIDTH * HEIGHT
const CARDINAL_DIRS := [
	Vector2i(0, 1),
	Vector2i(0, -1),
	Vector2i(1, 0),
	Vector2i(-1, 0)
]
const FIRE_SPREAD_OFFSETS := [
	Vector2i(-1, -1),
	Vector2i(0, -1),
	Vector2i(1, -1),
	Vector2i(-1, 0),
	Vector2i(1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1),
	Vector2i(1, 1)
]
const RELAX_TRIM_MAX := 12
const STEP_PHASE_COUNT := 3

static func get_width() -> int:
	return WIDTH

static func get_height() -> int:
	return HEIGHT

static func get_cell_count() -> int:
	return WIDTH * HEIGHT

var heat: float = 0.5
var moisture: float = 0.5
var breeze: float = 0.5

var _current: Array = []
var _next: Array = []
var _previous: Array = []
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _use_override_rng: bool = false
var _fast_seed: int = 1
var _active_fraction_cached: float = 0.0
var _active_fraction_snapshot: float = 0.0
var _step_phase: int = 0

func _init() -> void:
	_reset_buffers()
	_randomize_fast()

func _reset_buffers() -> void:
	_current = []
	_next = []
	_previous = []
	for _y in range(HEIGHT):
		_current.append(_make_row())
		_next.append(_make_row())
		_previous.append(_make_row())
	_active_fraction_cached = 0.0

func _make_row() -> Array[int]:
	var row: Array[int] = []
	row.resize(WIDTH)
	for x in range(WIDTH):
		row[x] = MATERIAL_AIR
	return row

func seed_grid() -> void:
	if _use_override_rng:
		_rng.randomize()
	else:
		_randomize_fast()
	for y in range(HEIGHT):
		var row: Array[int] = _current[y]
		for x in range(WIDTH):
			var roll: float = _randf()
			if roll < 0.02:
				row[x] = MATERIAL_PLANT
			elif roll < 0.05:
				row[x] = MATERIAL_STONE
			else:
				row[x] = MATERIAL_AIR
		_sync_row_to_buffers(y)
	_active_fraction_cached = _compute_active_fraction()

func _sync_row_to_buffers(y: int) -> void:
	var row: Array[int] = _current[y]
	var next_row: Array[int] = _next[y]
	var prev_row: Array[int] = _previous[y]
	for x in range(WIDTH):
		var value: int = row[x]
		next_row[x] = value
		prev_row[x] = value

func step(delta: float) -> void:
	if WIDTH <= 0 or HEIGHT <= 0:
		return
	_active_fraction_snapshot = _active_fraction_cached
	var step_delta: float = delta * float(STEP_PHASE_COUNT)
	for y in range(HEIGHT):
		var current_row: Array[int] = _current[y]
		var next_row: Array[int] = _next[y]
		for x in range(WIDTH):
			var mat := int(current_row[x])
			next_row[x] = mat
			if (x + y + _step_phase) % STEP_PHASE_COUNT != 0:
				continue
			match mat:
				MATERIAL_SAND:
					_apply_sand(x, y)
				MATERIAL_WATER:
					_apply_liquid(x, y, MATERIAL_WATER)
				MATERIAL_OIL:
					_apply_liquid(x, y, MATERIAL_OIL)
				MATERIAL_FIRE:
					_apply_fire(x, y, step_delta)
				MATERIAL_PLANT:
					_apply_plant(x, y, step_delta)
				MATERIAL_STEAM:
					_apply_steam(x, y)
				_:
					pass
	_step_phase = (_step_phase + 1) % STEP_PHASE_COUNT
	_swap_buffers()
	var active_count: int = _count_active_cells()
	if TOTAL_CELLS > 0:
		_active_fraction_cached = float(active_count) / float(TOTAL_CELLS)
	else:
		_active_fraction_cached = 0.0
	_cap_active_cells(active_count)

func compute_comfort() -> Dictionary:
	var stability := _calculate_stability()
	var diversity := _calculate_diversity()
	var entropy := _calculate_entropy()
	var comfort: float = clamp(stability * 0.4 + diversity * 0.35 + entropy * 0.25, 0.0, 1.0)
	return {
		"stability": stability,
		"diversity": diversity,
		"entropy": entropy,
		"ci": comfort
	}

func get_snapshot() -> Array:
	var snapshot: Array = []
	for y in range(HEIGHT):
		snapshot.append(_current[y].duplicate())
	return snapshot

func _swap_buffers() -> void:
	_copy_current_into_previous()
	var temp: Array = _current
	_current = _next
	_next = temp

func _apply_sand(x: int, y: int) -> void:
	var below := y + 1
	if below >= HEIGHT:
		return
	if _current[below][x] == MATERIAL_AIR or _current[below][x] == MATERIAL_WATER:
		_move_cell(x, y, x, below)
	else:
		var dir: int = _rand_side()
		var nx: int = int(clamp(x + dir, 0, WIDTH - 1))
		if _current[below][nx] == MATERIAL_AIR:
			_move_cell(x, y, nx, below)

func _apply_liquid(x: int, y: int, material: int) -> void:
	var below := y + 1
	if below < HEIGHT and _current[below][x] == MATERIAL_AIR:
		_move_cell(x, y, x, below)
		return
	var dir: int = _rand_side()
	var nx: int = int(clamp(x + dir, 0, WIDTH - 1))
	if _current[y][nx] == MATERIAL_AIR:
		_move_cell(x, y, nx, y)

func _apply_fire(x: int, y: int, delta: float) -> void:
	var damp: float = clamp(1.0 - moisture, 0.2, 1.0)
	if _randf() < (0.1 + delta * 0.5) * damp:
		_next[y][x] = MATERIAL_AIR
		return
	var samples: int = min(4, FIRE_SPREAD_OFFSETS.size())
	for _i in range(samples):
		var offset: Vector2i = FIRE_SPREAD_OFFSETS[_randi_range(0, FIRE_SPREAD_OFFSETS.size() - 1)]
		var nx: int = x + offset.x
		var ny: int = y + offset.y
		if nx < 0 or nx >= WIDTH or ny < 0 or ny >= HEIGHT:
			continue
		if _current[ny][nx] == MATERIAL_PLANT and _randf() < 0.03 * damp:
			_next[ny][nx] = MATERIAL_FIRE

func _apply_plant(x: int, y: int, _delta: float) -> void:
	if _active_fraction_snapshot >= MAX_ACTIVE_FRACTION:
		return
	var overfill: float = max(_active_fraction_snapshot - MAX_ACTIVE_FRACTION, 0.0)
	var suppression: float = clamp(1.0 - overfill * 3.0, 0.1, 1.0)
	var density_load: float = clamp(1.0 - max(_active_fraction_snapshot - 0.25, 0.0) * 2.5, 0.2, 1.0)
	var grow_chance: float = clamp((0.010 + moisture * 0.02 - heat * 0.008) * suppression * density_load, 0.0, 0.04)
	if _active_fraction_snapshot > 0.32 and _randf() < 0.015:
		_next[y][x] = MATERIAL_AIR
		return
	if _randf() < grow_chance:
		var growth_samples: int = min(2, CARDINAL_DIRS.size())
		for _i in range(growth_samples):
			var dir: Vector2i = CARDINAL_DIRS[_randi_range(0, CARDINAL_DIRS.size() - 1)]
			var nx: int = x + dir.x
			var ny: int = y + dir.y
			if nx < 0 or nx >= WIDTH or ny < 0 or ny >= HEIGHT:
				continue
			if _current[ny][nx] == MATERIAL_AIR:
				_next[ny][nx] = MATERIAL_PLANT
	var water_samples: int = 2
	for _i in range(water_samples):
		var dx: int = _randi_range(-1, 1)
		var nx2: int = x + dx
		var ny2: int = y - 1
		if ny2 >= 0 and nx2 >= 0 and nx2 < WIDTH:
			if _current[ny2][nx2] == MATERIAL_WATER and _randf() < 0.05:
				_next[ny2][nx2] = MATERIAL_PLANT

func _apply_steam(x: int, y: int) -> void:
	var up := y - 1
	if up >= 0 and _current[up][x] == MATERIAL_AIR:
		_move_cell(x, y, x, up)
		return
	var dir: int = _rand_side()
	var nx: int = int(clamp(x + dir, 0, WIDTH - 1))
	if _current[y][nx] == MATERIAL_AIR:
		_move_cell(x, y, nx, y)

func _move_cell(x: int, y: int, nx: int, ny: int) -> void:
	var mat := int(_current[y][x])
	_next[ny][nx] = mat
	_next[y][x] = MATERIAL_AIR

func _copy_current_into_previous() -> void:
	for y in range(HEIGHT):
		var source: Array[int] = _current[y]
		var target: Array[int] = _previous[y]
		for x in range(WIDTH):
			target[x] = source[x]

func _calculate_stability() -> float:
	if _previous.is_empty():
		return 1.0
	var total := WIDTH * HEIGHT
	var unchanged := 0
	for y in range(HEIGHT):
		var curr_row: Array = _current[y]
		var prev_row: Array = _previous[y]
		for x in range(WIDTH):
			if curr_row[x] == prev_row[x]:
				unchanged += 1
	return float(unchanged) / max(float(total), 1.0)

func _calculate_diversity() -> float:
	var counts: Dictionary = {}
	for y in range(HEIGHT):
		var row: Array = _current[y]
		for x in range(WIDTH):
			var mat := int(row[x])
			counts[mat] = int(counts.get(mat, 0)) + 1
	return clamp(float(counts.size()) / 8.0, 0.0, 1.0)

func _calculate_entropy() -> float:
	var total := float(WIDTH * HEIGHT)
	if total <= 0.0:
		return 0.0
	var buckets: Dictionary = {}
	for y in range(HEIGHT):
		var row: Array = _current[y]
		for x in range(WIDTH):
			var mat := int(row[x])
			buckets[mat] = int(buckets.get(mat, 0)) + 1
	var entropy := 0.0
	for value in buckets.values():
		var count := float(value)
		if count <= 0.0:
			continue
		var p := count / total
		entropy -= p * log(p)
	return clamp(entropy / 4.0, 0.0, 1.0)

func set_random_number_generator(rng: RandomNumberGenerator) -> void:
	if rng == null:
		return
	_rng = rng
	_use_override_rng = true

func active_cell_fraction() -> float:
	return _active_fraction_cached

func relax_density(target_fraction: float, max_trim: int = RELAX_TRIM_MAX) -> void:
	if TOTAL_CELLS <= 0:
		return
	var clamped_target: float = clamp(target_fraction, 0.0, MAX_ACTIVE_FRACTION)
	if clamped_target <= 0.0:
		return
	var current_fraction: float = _active_fraction_cached
	if current_fraction <= clamped_target:
		return
	var active_estimate: int = int(round(current_fraction * float(TOTAL_CELLS)))
	var target_active: int = int(round(clamped_target * float(TOTAL_CELLS)))
	var to_trim: int = max(active_estimate - target_active, 0)
	if to_trim <= 0:
		return
	var trim_limit: int = clamp(max_trim, 1, TOTAL_CELLS)
	var trimmed: int = _remove_random_cells(min(to_trim, trim_limit))
	if trimmed > 0:
		_active_fraction_cached = _compute_active_fraction()

func _cap_active_cells(active: int, max_fraction: float = MAX_ACTIVE_FRACTION) -> void:
	if TOTAL_CELLS <= 0:
		return
	var limit_fraction: float = clamp(max_fraction, 0.0, 1.0)
	var limit: int = int(round(limit_fraction * float(TOTAL_CELLS)))
	if active <= limit:
		return
	var to_remove: int = active - limit
	var removed: int = 0
	var start_index: int = 0
	if TOTAL_CELLS > 0:
		start_index = _randi_range(0, TOTAL_CELLS - 1)
	for i in range(TOTAL_CELLS):
		if removed >= to_remove:
			break
		var index: int = (start_index + i) % TOTAL_CELLS
		var x: int = index % WIDTH
		var y: int = index / WIDTH
		var mat: int = int(_current[y][x])
		if mat == MATERIAL_AIR or mat == MATERIAL_STONE:
			continue
		_current[y][x] = MATERIAL_AIR
		_next[y][x] = MATERIAL_AIR
		_previous[y][x] = MATERIAL_AIR
		removed += 1
	if removed < to_remove:
		var remaining: int = to_remove - removed
		for y in range(HEIGHT):
			var row: Array[int] = _current[y]
			for x in range(WIDTH):
				if remaining <= 0:
					break
				var mat := int(row[x])
				if mat == MATERIAL_AIR or mat == MATERIAL_STONE:
					continue
				row[x] = MATERIAL_AIR
				_next[y][x] = MATERIAL_AIR
				_previous[y][x] = MATERIAL_AIR
				remaining -= 1
				removed += 1
			if remaining <= 0:
				break
	_active_fraction_cached = _compute_active_fraction()

func _remove_random_cells(count: int) -> int:
	if count <= 0 or TOTAL_CELLS <= 0:
		return 0
	var removed: int = 0
	var attempts: int = 0
	var max_attempts: int = min(count * 6, TOTAL_CELLS * 3)
	while removed < count and attempts < max_attempts:
		var index: int = _randi_range(0, TOTAL_CELLS - 1)
		var x: int = index % WIDTH
		var y: int = index / WIDTH
		var mat: int = int(_current[y][x])
		if mat == MATERIAL_AIR or mat == MATERIAL_STONE:
			attempts += 1
			continue
		_current[y][x] = MATERIAL_AIR
		_next[y][x] = MATERIAL_AIR
		_previous[y][x] = MATERIAL_AIR
		removed += 1
		attempts += 1
	return removed

func _count_active_cells() -> int:
	if TOTAL_CELLS <= 0:
		return 0
	var active := 0
	for y in range(HEIGHT):
		var row: Array[int] = _current[y]
		for x in range(WIDTH):
			if row[x] != MATERIAL_AIR:
				active += 1
	return active

func _randomize_fast() -> void:
	var seed_source: int = int(Time.get_ticks_usec()) & 0x7fffffff
	if seed_source == 0:
		seed_source = 1
	_fast_seed = seed_source

func _randf() -> float:
	if _use_override_rng:
		return _rng.randf()
	_fast_seed = int((_fast_seed * 1103515245 + 12345) & 0x7fffffff)
	return float(_fast_seed) / 2147483647.0

func _rand_side() -> int:
	return -1 if _randf() < 0.5 else 1

func _randi_range(min_value: int, max_value: int) -> int:
	if _use_override_rng:
		return _rng.randi_range(min_value, max_value)
	var span: int = max_value - min_value + 1
	if span <= 0:
		return min_value
	var value: int = int(floor(_randf() * float(span)))
	return min_value + clamp(value, 0, span - 1)

func _compute_active_fraction() -> float:
	if TOTAL_CELLS <= 0:
		return 0.0
	return float(_count_active_cells()) / float(TOTAL_CELLS)
