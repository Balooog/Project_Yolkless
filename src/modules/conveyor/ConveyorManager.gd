extends Node
class_name ConveyorManager

signal item_spawned(item_id: int)
signal item_delivered(item_id: int, destination: Node)
signal throughput_updated(rate: float, queue_len: int)

@export var default_belt_path: NodePath
@export var throughput_smoothing: float = 0.2
@export var log_interval: float = 2.0
@export var active_item_cap: int = 600
@export var pool_size_cap: int = 800

var belts: Array[ConveyorBelt] = []
var items_per_second: float = 0.0
var average_travel_time: float = 0.0

var _item_sequence: int = 0
var _log_timer: float = 0.0
var _pending_delivery_target: Callable = Callable()
var _spawn_container: Node
var _item_pool: Array[ConveyorItem] = []
var _active_items: int = 0

func _ready() -> void:
	set_process(true)
	_spawn_container = Node.new()
	_spawn_container.name = "ConveyorPool"
	add_child(_spawn_container)
	if default_belt_path != NodePath():
		var belt: ConveyorBelt = get_node_or_null(default_belt_path) as ConveyorBelt
		if belt:
			register_belt(belt)

func register_belt(belt: ConveyorBelt) -> void:
	if belt == null:
		return
	if belt in belts:
		return
	belts.append(belt)
	belt.set_manager(self)

func unregister_belt(belt: ConveyorBelt) -> void:
	if belt == null:
		return
	belts.erase(belt)

func set_delivery_target(callback: Callable) -> void:
	_pending_delivery_target = callback

func spawn_item(item_type: StringName, belt: ConveyorBelt = null, speed: float = -1.0, extra: Dictionary = {}) -> ConveyorItem:
	if belts.is_empty() and belt == null:
		push_warning("ConveyorManager has no registered belts; spawn ignored.")
		return null
	if active_item_cap > 0 and _active_items >= active_item_cap:
		return null
	var target_belt: ConveyorBelt = belt
	if target_belt == null:
		target_belt = belts[0]
	if target_belt == null:
		return null
	var item := _obtain_item()
	_item_sequence += 1
	var spawn_time: float = Time.get_ticks_msec() / 1000.0
	item.setup(_item_sequence, item_type, spawn_time, speed, extra)
	target_belt.attach_item(item)
	emit_signal("item_spawned", item.item_id)
	_active_items += 1
	return item

func deliver_item(item: ConveyorItem, destination: Node) -> void:
	if _pending_delivery_target.is_valid():
		_pending_delivery_target.call(item, destination)

func recycle_item(item: ConveyorItem) -> void:
	_recycle_item(item)

func _process(delta: float) -> void:
	if belts.is_empty():
		return
	var total_queue: int = 0
	var delivered_total: int = 0
	var delivered_pairs: Array[Dictionary] = []
	for belt in belts:
		var result: Dictionary = belt.step(delta)
		total_queue += int(result.get("queue_len", 0))
		var delivered: Array = result.get("delivered", [])
		delivered_total += delivered.size()
		for item in delivered:
			delivered_pairs.append({
				"belt": belt,
				"item": item
			})
	var instant_rate: float = 0.0
	if delta > 0.0001:
		instant_rate = delivered_total / delta
		items_per_second = lerp(items_per_second, instant_rate, throughput_smoothing)
	var now: float = Time.get_ticks_msec() / 1000.0
	for pair in delivered_pairs:
		var belt: ConveyorBelt = pair["belt"]
		var item: ConveyorItem = pair["item"]
		belt.remove_item(item)
		var travel_time: float = max(now - item.spawn_time, 0.0)
		if average_travel_time == 0.0:
			average_travel_time = travel_time
		else:
			average_travel_time = lerp(average_travel_time, travel_time, 0.2)
		emit_signal("item_delivered", item.item_id, belt)
		deliver_item(item, belt)
		_recycle_item(item)
	_log_timer += delta
	if _log_timer >= log_interval:
		_log_timer = 0.0
		var context: Dictionary = {
			"rate": "%.2f" % items_per_second,
			"queue": total_queue,
			"avg_travel": "%.2f" % average_travel_time,
			"belts": belts.size()
		}
		var logger: YolkLogger = _get_logger()
		if logger:
			logger.log("INFO", "CONVEYOR", "throughput update", context)
	emit_signal("throughput_updated", items_per_second, total_queue)

func _get_logger() -> YolkLogger:
	var node: Node = get_node_or_null("/root/Logger")
	if node is YolkLogger:
		return node as YolkLogger
	return null

func _obtain_item() -> ConveyorItem:
	if not _item_pool.is_empty():
		return _item_pool.pop_back()
	var item := ConveyorItem.new()
	if _spawn_container:
		_spawn_container.add_child(item)
	return item

func _recycle_item(item: ConveyorItem) -> void:
	if item == null:
		return
	if _active_items > 0:
		_active_items -= 1
	item.reset_for_pool()
	if _spawn_container and item.get_parent() != _spawn_container:
		_spawn_container.add_child(item)
	if pool_size_cap <= 0 or _item_pool.size() < pool_size_cap:
		_item_pool.append(item)
	else:
		item.queue_free()
