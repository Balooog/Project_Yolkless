extends Node2D
class_name ConveyorItem

const STATE_MOVING := "moving"
const STATE_QUEUED := "queued"
const STATE_PROCESSED := "processed"

var item_id: int = -1
var item_type: StringName = &""
var spawn_time: float = 0.0
var speed: float = 0.0
var state: String = STATE_MOVING
var distance: float = 0.0
var metadata: Dictionary = {}

@export var radius: float = 8.0
@export var tint: Color = Color.hex(0xf7d046ff) # warm yolk tone

func setup(id: int, type_name: StringName, spawn: float, move_speed: float, extra: Dictionary = {}) -> void:
	item_id = id
	item_type = type_name
	spawn_time = spawn
	speed = move_speed
	metadata = extra.duplicate(true)
	state = STATE_MOVING
	distance = 0.0
	queue_redraw()

func set_state(new_state: String) -> void:
	if state == new_state:
		return
	state = new_state
	queue_redraw()

func set_distance(new_distance: float) -> void:
	distance = new_distance

func set_tint(color: Color) -> void:
	tint = color
	queue_redraw()

func _draw() -> void:
	var base_color: Color = tint
	match state:
		STATE_MOVING:
			base_color = tint
		STATE_QUEUED:
			base_color = tint.darkened(0.25)
		STATE_PROCESSED:
			base_color = tint.lightened(0.35)
	draw_circle(Vector2.ZERO, radius, base_color)
	var inner_color := Color(Color.WHITE, 0.4)
	draw_circle(Vector2.ZERO, radius * 0.45, inner_color)
