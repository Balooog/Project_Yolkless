extends RefCounted
class_name SandboxGrid

const WIDTH := 128
const HEIGHT := 72

const MATERIAL_AIR := 0
const MATERIAL_SAND := 1
const MATERIAL_WATER := 2
const MATERIAL_OIL := 3
const MATERIAL_FIRE := 4
const MATERIAL_PLANT := 5
const MATERIAL_STONE := 6
const MATERIAL_STEAM := 7

var heat: float = 0.5
var moisture: float = 0.5
var breeze: float = 0.5

var _current: Array[Array] = []
var _next: Array[Array] = []
var _previous: Array[Array] = []
var _rng := RandomNumberGenerator.new()

func _init() -> void:
	_reset_buffers()

func _reset_buffers() -> void:
	_current = []
	_next = []
	_previous = []
	for _y in range(HEIGHT):
		var row: Array = []
		row.resize(WIDTH)
		for x in range(WIDTH):
			row[x] = MATERIAL_AIR
		var fresh: Array = row.duplicate()
		_current.append(fresh)
		_next.append(fresh.duplicate())
		_previous.append(fresh.duplicate())

func seed_grid() -> void:
	_rng.randomize()
	for y in range(HEIGHT):
		var row: Array = _current[y]
		for x in range(WIDTH):
			var roll: float = _rng.randf()
			if roll < 0.02:
				row[x] = MATERIAL_PLANT
			elif roll < 0.05:
				row[x] = MATERIAL_STONE
			else:
				row[x] = MATERIAL_AIR
		var duplicate_row: Array = row.duplicate()
		_current[y] = duplicate_row
		_next[y] = duplicate_row.duplicate()
		_previous[y] = duplicate_row.duplicate()

func step(delta: float) -> void:
	if WIDTH <= 0 or HEIGHT <= 0:
		return
	for y in range(HEIGHT):
		var source: Array = _current[y]
		var target: Array = _next[y]
		for x in range(WIDTH):
			target[x] = source[x]
		_next[y] = target
	for y in range(HEIGHT):
		for x in range(WIDTH):
			var mat := int(_current[y][x])
			match mat:
				MATERIAL_SAND:
					_apply_sand(x, y)
				MATERIAL_WATER:
					_apply_liquid(x, y, MATERIAL_WATER)
				MATERIAL_OIL:
					_apply_liquid(x, y, MATERIAL_OIL)
				MATERIAL_FIRE:
					_apply_fire(x, y, delta)
				MATERIAL_PLANT:
					_apply_plant(x, y, delta)
				MATERIAL_STEAM:
					_apply_steam(x, y)
				_:
					pass
	_swap_buffers()

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
	_previous = []
	for y in range(HEIGHT):
		_previous.append(_current[y].duplicate())
	var temp: Array[Array] = _current
	_current = _next
	_next = temp
	for y in range(HEIGHT):
		_next[y] = _current[y].duplicate()

func _apply_sand(x: int, y: int) -> void:
	var below := y + 1
	if below >= HEIGHT:
		return
	if _current[below][x] == MATERIAL_AIR or _current[below][x] == MATERIAL_WATER:
		_move_cell(x, y, x, below)
	else:
		var dir: int = -1 if _rng.randf() < 0.5 else 1
		var nx: int = int(clamp(x + dir, 0, WIDTH - 1))
		if _current[below][nx] == MATERIAL_AIR:
			_move_cell(x, y, nx, below)

func _apply_liquid(x: int, y: int, material: int) -> void:
	var below := y + 1
	if below < HEIGHT and _current[below][x] == MATERIAL_AIR:
		_move_cell(x, y, x, below)
		return
	var dir: int = -1 if _rng.randf() < 0.5 else 1
	var nx: int = int(clamp(x + dir, 0, WIDTH - 1))
	if _current[y][nx] == MATERIAL_AIR:
		_move_cell(x, y, nx, y)

func _apply_fire(x: int, y: int, delta: float) -> void:
	var damp: float = clamp(1.0 - moisture, 0.2, 1.0)
	if _rng.randf() < (0.1 + delta * 0.5) * damp:
		_next[y][x] = MATERIAL_AIR
		return
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx: int = x + dx
			var ny: int = y + dy
			if nx < 0 or nx >= WIDTH or ny < 0 or ny >= HEIGHT:
				continue
			if _current[ny][nx] == MATERIAL_PLANT and _rng.randf() < 0.03 * damp:
				_next[ny][nx] = MATERIAL_FIRE

func _apply_plant(x: int, y: int, _delta: float) -> void:
	var grow_chance: float = clamp(0.015 + moisture * 0.04 - heat * 0.012, 0.0, 0.06)
	if _rng.randf() < grow_chance:
		for dir in [[0, 1], [0, -1], [1, 0], [-1, 0]]:
			var nx: int = x + dir[0]
			var ny: int = y + dir[1]
			if nx < 0 or nx >= WIDTH or ny < 0 or ny >= HEIGHT:
				continue
			if _current[ny][nx] == MATERIAL_AIR:
				_next[ny][nx] = MATERIAL_PLANT
	for dx in range(-1, 2):
		var nx2: int = x + dx
		var ny2: int = y - 1
		if ny2 >= 0 and nx2 >= 0 and nx2 < WIDTH:
			if _current[ny2][nx2] == MATERIAL_WATER and _rng.randf() < 0.1:
				_next[ny2][nx2] = MATERIAL_PLANT

func _apply_steam(x: int, y: int) -> void:
	var up := y - 1
	if up >= 0 and _current[up][x] == MATERIAL_AIR:
		_move_cell(x, y, x, up)
		return
	var dir: int = -1 if _rng.randf() < 0.5 else 1
	var nx: int = int(clamp(x + dir, 0, WIDTH - 1))
	if _current[y][nx] == MATERIAL_AIR:
		_move_cell(x, y, nx, y)

func _move_cell(x: int, y: int, nx: int, ny: int) -> void:
	var mat := int(_current[y][x])
	_next[ny][nx] = mat
	_next[y][x] = MATERIAL_AIR

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
