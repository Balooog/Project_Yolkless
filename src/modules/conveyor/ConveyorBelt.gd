extends Node2D
class_name ConveyorBelt

const DEFAULT_CAPACITY := 0
const DEFAULT_SPEED := 60.0

class Segment:
	var length: float
	var speed: float
	var capacity: int
	var direction: int
	var start: float
	var end: float

	func _init(length_value: float, speed_value: float, capacity_value: int, direction_value: int, start_distance: float) -> void:
		length = max(length_value, 0.01)
		speed = max(speed_value, 0.0)
		capacity = max(capacity_value, 0)
		direction = -1 if direction_value < 0 else 1
		start = start_distance
		end = start + length

@export var belt_width: float = 36.0
@export var belt_color: Color = Color.hex(0x2f3640ff)
@export var stripe_color: Color = Color.hex(0xf9c80eff)
@export var stripe_spacing: float = 48.0
@export var easing_time: float = 0.25

var segments: Array[Segment] = []
var manager: ConveyorManager

var _items: Array[ConveyorItem] = []
var _item_velocity: Dictionary = {}
var _curve: Curve2D
var _total_length: float = 0.0
var _stripe_offset: float = 0.0
var _pending_curve_rebuild := false

func _ready() -> void:
	_resolve_curve()
	if segments.is_empty():
		# Default straight segment if none configured via editor.
		add_segment(200.0, DEFAULT_SPEED, DEFAULT_CAPACITY)

func set_manager(conveyor_manager: ConveyorManager) -> void:
	manager = conveyor_manager

func clear_segments() -> void:
	segments.clear()
	_total_length = 0.0
	queue_redraw()

func configure_segments(segment_defs: Array[Dictionary]) -> void:
	clear_segments()
	var start: float = 0.0
	for def in segment_defs:
		var length_value: float = float(def.get("length", 200.0))
		var speed_value: float = float(def.get("speed", DEFAULT_SPEED))
		var capacity_value: int = int(def.get("capacity", DEFAULT_CAPACITY))
		var direction_value: int = int(def.get("direction", 1))
		var segment: Segment = Segment.new(length_value, speed_value, capacity_value, direction_value, start)
		segments.append(segment)
		start = segment.end
	_total_length = start
	queue_redraw()

func add_segment(length_value: float, speed_value: float, capacity_value: int = DEFAULT_CAPACITY, direction_value: int = 1) -> void:
	var start: float = 0.0
	if not segments.is_empty():
		start = segments[segments.size() - 1].end
	var segment: Segment = Segment.new(length_value, speed_value, capacity_value, direction_value, start)
	segments.append(segment)
	_total_length = segment.end
	queue_redraw()

func attach_item(item: ConveyorItem) -> void:
	if item == null:
		return
	add_child(item)
	item.position = _sample_at_distance(0.0)
	item.rotation = 0.0
	_items.append(item)
	_item_velocity[item.item_id] = 0.0

func remove_item(item: ConveyorItem, queue_free_item: bool = false) -> void:
	if item == null:
		return
	_items.erase(item)
	_item_velocity.erase(item.item_id)
	if item.get_parent() == self:
		remove_child(item)
	if queue_free_item:
		item.queue_free()

func clear_items() -> void:
	for item in _items:
		if manager:
			manager.recycle_item(item)
		else:
			if item.get_parent() == self:
				remove_child(item)
			item.queue_free()
	_items.clear()
	_item_velocity.clear()

func get_queue_length() -> int:
	var queued: int = 0
	for item in _items:
		if item.state == ConveyorItem.STATE_QUEUED:
			queued += 1
	return queued

func step(delta: float) -> Dictionary:
	if _items.is_empty():
		_scroll_visual(delta)
		return {
			"delivered": [],
			"queue_len": 0,
			"delivered_count": 0
		}
	_resolve_curve()
	if _curve == null:
		return {
			"delivered": [],
			"queue_len": 0,
			"delivered_count": 0
		}
	var delivered: Array[ConveyorItem] = []
	var occupancy: Dictionary = _build_segment_occupancy()
	var sorted_items: Array[ConveyorItem] = []
	sorted_items.append_array(_items)
	_sort_items_desc(sorted_items)
	for item in sorted_items:
		var segment_index: int = _segment_for_distance(item.distance)
		if segment_index < 0:
			continue
		var segment: Segment = segments[segment_index]
		var target_speed: float = _resolve_item_speed(item, segment)
		var current_speed: float = float(_item_velocity.get(item.item_id, target_speed))
		var ease_factor: float = clamp(delta / max(easing_time, 0.0001), 0.0, 1.0)
		if item.state == ConveyorItem.STATE_QUEUED:
			current_speed = lerp(current_speed, 0.0, ease_factor)
		else:
			current_speed = lerp(current_speed, target_speed, ease_factor)
		_item_velocity[item.item_id] = current_speed
		var remaining: float = current_speed * delta
		var new_state: String = ConveyorItem.STATE_MOVING if remaining > 0.0 else item.state
		var current_distance: float = item.distance
		var index: int = segment_index
		while remaining > 0.0:
			segment = segments[index]
			var segment_end: float = segment.end
			var distance_to_end: float = segment_end - current_distance
			if remaining <= distance_to_end:
				current_distance += remaining
				remaining = 0.0
				break
			var next_index: int = index + segment.direction
			var carry: float = remaining - distance_to_end
			if next_index < 0 or next_index >= segments.size():
				# Delivered
				delivered.append(item)
				current_distance = _total_length
				new_state = ConveyorItem.STATE_PROCESSED
				remaining = 0.0
				break
			var next_segment: Segment = segments[next_index]
			var capacity: int = next_segment.capacity
			var next_occupancy: int = int(occupancy.get(next_index, 0))
			if capacity > 0 and next_occupancy >= capacity:
				# Queue at boundary
				current_distance = segment_end - 0.001
				new_state = ConveyorItem.STATE_QUEUED
				remaining = 0.0
				break
			# Move into next segment
			var current_occupancy: int = int(occupancy.get(index, 0))
			occupancy[index] = max(current_occupancy - 1, 0)
			index = next_index
			occupancy[index] = next_occupancy + 1
			current_distance = next_segment.start + 0.0005
			remaining = carry
		item.set_distance(clamp(current_distance, 0.0, _total_length))
		item.set_state(new_state)
		_update_item_transform(item)
	_scroll_visual(delta)
	queue_redraw()
	return {
		"delivered": delivered,
		"queue_len": get_queue_length(),
		"delivered_count": delivered.size()
	}

func get_total_length() -> float:
	return _total_length

func get_item_count() -> int:
	return _items.size()

func _scroll_visual(delta: float) -> void:
	if segments.is_empty():
		return
	var base_speed: float = _average_speed()
	if base_speed <= 0.0:
		return
	_stripe_offset = fposmod(_stripe_offset + base_speed * delta, max(stripe_spacing, 1.0))
	queue_redraw()

func _average_speed() -> float:
	if segments.is_empty():
		return DEFAULT_SPEED
	var total: float = 0.0
	for seg in segments:
		total += seg.speed
	return total / float(segments.size())

func _segment_for_distance(distance: float) -> int:
	if segments.is_empty():
		return -1
	var clamped_distance: float = clamp(distance, 0.0, _total_length)
	for i in range(segments.size()):
		var seg: Segment = segments[i]
		if clamped_distance >= seg.start and clamped_distance <= seg.end:
			return i
	# fallback
	return segments.size() - 1

func _build_segment_occupancy() -> Dictionary:
	var occupancy: Dictionary = {}
	for item in _items:
		var index: int = _segment_for_distance(item.distance)
		if index < 0:
			continue
		occupancy[index] = occupancy.get(index, 0) + 1
	return occupancy

func _resolve_item_speed(item: ConveyorItem, segment: Segment) -> float:
	if item == null:
		return segment.speed
	if item.speed > 0.0:
		return min(item.speed, segment.speed)
	return segment.speed

func _update_item_transform(item: ConveyorItem) -> void:
	if _curve == null:
		return
	var distance: float = clamp(item.distance, 0.0, _total_length)
	var position: Vector2 = _sample_at_distance(distance)
	item.position = position
	var ahead_distance: float = clamp(distance + 4.0, 0.0, _total_length)
	var ahead: Vector2 = _sample_at_distance(ahead_distance)
	item.rotation = (ahead - position).angle()

func _sample_at_distance(distance: float) -> Vector2:
	if _curve == null:
		return Vector2.ZERO
	var clamped: float = clamp(distance, 0.0, _total_length)
	return _curve.sample_baked(clamped)

func _sort_items_desc(items: Array[ConveyorItem]) -> void:
	items.sort_custom(Callable(self, "_compare_items"))

func _compare_items(a: ConveyorItem, b: ConveyorItem) -> bool:
	return a.distance > b.distance

func _resolve_curve() -> void:
	if _curve != null and not _pending_curve_rebuild:
		return
	var path: Path2D = get_node_or_null(NodePath("Path2D")) as Path2D
	if path:
		_curve = path.curve
	elif _curve == null:
		_curve = Curve2D.new()
		_curve.add_point(Vector2.ZERO)
		_curve.add_point(Vector2(200, 0))
	if segments.is_empty():
		_total_length = max(_curve.get_baked_length(), 0.01)
	else:
		_total_length = segments[segments.size() - 1].end
	_pending_curve_rebuild = false

func mark_curve_dirty() -> void:
	_pending_curve_rebuild = true

func _draw() -> void:
	_resolve_curve()
	if _curve == null:
		return
	var points: PackedVector2Array = _curve.get_baked_points()
	if points.size() < 2:
		return
	var width: float = max(belt_width, 1.0)
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], belt_color, width, true)
	var length: float = max(_curve.get_baked_length(), 1.0)
	var spacing: float = max(stripe_spacing, 8.0)
	var offset: float = fposmod(_stripe_offset, spacing)
	var t: float = offset
	while t < length:
		var start_point: Vector2 = _curve.sample_baked(t)
		var end_point: Vector2 = _curve.sample_baked(min(t + spacing * 0.35, length))
		draw_line(start_point, end_point, stripe_color, width * 0.6, true)
		t += spacing
