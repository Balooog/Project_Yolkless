extends Node2D

const ITEM_TYPES := [
	&"egg",
	&"crate",
	&"yolk"
]

const ITEM_COLORS := {
	&"egg": Color.hex(0xf7e9a5ff),
	&"crate": Color.hex(0xc17c74ff),
	&"yolk": Color.hex(0xffc046ff)
}

@onready var manager: ConveyorManager = %ConveyorManager
@onready var belt: ConveyorBelt = %ConveyorBelt
@onready var spawn_timer: Timer = %Spawner
@onready var stats_label: Label = %StatsLabel

func _ready() -> void:
	randomize()
	if belt:
		belt.configure_segments([
			{
				"length": 220.0,
				"speed": 80.0,
				"capacity": 8
			},
			{
				"length": 180.0,
				"speed": 70.0,
				"capacity": 5
			},
			{
				"length": 160.0,
				"speed": 65.0,
				"capacity": 3
			}
		])
	if manager:
		manager.register_belt(belt)
		manager.throughput_updated.connect(_on_throughput_updated)
	if spawn_timer:
		spawn_timer.timeout.connect(_spawn_tick)
	_spawn_tick()

func _spawn_tick() -> void:
	if manager == null or belt == null:
		return
	var item_type := ITEM_TYPES[randi() % ITEM_TYPES.size()]
	var item := manager.spawn_item(item_type, belt)
	if item:
		item.set_tint(ITEM_COLORS.get(item_type, Color.WHITE))
	if spawn_timer:
		spawn_timer.start(randf_range(0.35, 0.65))

func _on_throughput_updated(rate: float, queue_len: int) -> void:
	if stats_label == null or manager == null:
		return
	stats_label.text = "Rate: %.1f/s | Queue: %d | Avg travel: %.2fs" % [
		rate,
		queue_len,
		manager.average_travel_time
	]
