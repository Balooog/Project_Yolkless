extends Node
class_name VisualDirector

const MODULE_FEED_PARTICLES_ID := "feed_particles"
const UPDATE_INTERVAL := 0.2
const FEED_PARTICLES_SCENE := preload("res://game/scenes/modules/visuals/FeedParticles.tscn")
const VISUAL_HOST_PATH := NodePath("/root/Main/VisualLayer/VisualViewport")
const FEED_ANCHOR_PATHS := [
	NodePath("UI/PrototypeUI/RootMargin/RootStack/BottomBar/TabBar/FeedButton"),
	NodePath("UI/PrototypeUI/RootMargin/RootStack/MainStack/CanvasWrapper/MobileSheetAnchor/SheetOverlay/HomeSheet/HomeMargin/HomeColumn/HomeFeedButton"),
	NodePath("UI/PrototypeUI/RootMargin/RootStack/MainStack/CanvasWrapper/MobileSheetAnchor/SheetOverlay/HomeSheet/HomeMargin/HomeColumn/HomeFeedBar"),
	NodePath("UI/RootMargin/RootColumn/VBox/BurstRow/BurstButton"),
	NodePath("UI/RootMargin/RootColumn/VBox/BurstRow/FeedContainer/FeedBar"),
	NodePath("UI/VBox/BurstRow/FeedContainer/FeedBar")
]

var _eco: Economy
var _strings: StringsCatalog
var _visual_host: Node
var _timer: Timer
var _modules: Dictionary[StringName, Node] = {}
var _module_scenes: Dictionary[StringName, PackedScene] = {
	StringName(MODULE_FEED_PARTICLES_ID): FEED_PARTICLES_SCENE
}
var _last_feed_fraction: float = 0.0
var _last_pps: float = 0.0
var _last_is_feeding: bool = false
var _high_contrast: bool = false

func set_sources(eco: Economy, strings: StringsCatalog = null) -> void:
	if eco == _eco and strings == _strings:
		return
	_disconnect_sources()
	_eco = eco
	_strings = strings
	_ensure_visual_host()
	if _eco:
		_connect_sources()
		_ensure_timer()
		_timer.start()
	_refresh_state()

func activate(id: String, enabled: bool) -> void:
	var key: StringName = StringName(id)
	if enabled:
		if _modules.has(key):
			return
		var scene_variant: Variant = _module_scenes.get(key)
		if scene_variant is PackedScene:
			var scene: PackedScene = scene_variant as PackedScene
			_ensure_visual_host()
			if _visual_host:
				var instance: Node = scene.instantiate()
				_visual_host.add_child(instance)
				_modules[key] = instance
				_apply_module_state(instance)
				_log_activation(key, true)
	else:
		if not _modules.has(key):
			return
		var node: Node = _modules[key]
		if is_instance_valid(node):
			node.queue_free()
		_modules.erase(key)
		_log_activation(key, false)

func update_state(feed_fraction: float, pps: float, is_feeding: bool) -> void:
	_last_feed_fraction = clamp(feed_fraction, 0.0, 1.0)
	_last_pps = max(0.0, pps)
	_last_is_feeding = is_feeding
	var invalid: Array[StringName] = []
	for key in _modules.keys():
		var node := _modules[key]
		if not node or not is_instance_valid(node):
			invalid.append(key)
			continue
		_apply_module_state(node)
	for key in invalid:
		_modules.erase(key)

func set_high_contrast(enabled: bool) -> void:
	if _high_contrast == enabled:
		return
	_high_contrast = enabled
	for node in _modules.values():
		if node and is_instance_valid(node):
			if node is FeedParticles:
				(node as FeedParticles).set_high_contrast(enabled)

func _connect_sources() -> void:
	if not _eco:
		return
	if not _eco.soft_changed.is_connected(_on_soft_changed):
		_eco.soft_changed.connect(_on_soft_changed)
	if not _eco.burst_state.is_connected(_on_burst_state):
		_eco.burst_state.connect(_on_burst_state)

func _disconnect_sources() -> void:
	if _eco:
		if _eco.soft_changed.is_connected(_on_soft_changed):
			_eco.soft_changed.disconnect(_on_soft_changed)
		if _eco.burst_state.is_connected(_on_burst_state):
			_eco.burst_state.disconnect(_on_burst_state)
	if _timer:
		_timer.stop()

func _ensure_visual_host() -> void:
	if _visual_host and is_instance_valid(_visual_host):
		return
	var tree := get_tree()
	if not tree:
		return
	var root := tree.get_root()
	if not root:
		return
	if root.has_node(VISUAL_HOST_PATH):
		_visual_host = root.get_node(VISUAL_HOST_PATH)

func _ensure_timer() -> void:
	if _timer:
		return
	_timer = Timer.new()
	_timer.wait_time = UPDATE_INTERVAL
	_timer.one_shot = false
	add_child(_timer)
	_timer.timeout.connect(_on_timer_timeout)

func _apply_module_state(node: Node) -> void:
	if not node or not is_instance_valid(node):
		return
	if node is FeedParticles:
		var module: FeedParticles = node as FeedParticles
		var anchor := _resolve_feed_anchor()
		module.set_anchor(anchor.get("position", Vector2.ZERO), anchor.get("size", Vector2.ZERO))
		module.set_high_contrast(_high_contrast)
		module.apply(_last_feed_fraction, _last_pps, _last_is_feeding)

func _resolve_feed_anchor() -> Dictionary:
	var result := {
		"position": Vector2.ZERO,
		"size": Vector2.ZERO
	}
	if not _eco:
		return result
	var parent: Node = _eco.get_parent()
	if not parent:
		return result
	for path in FEED_ANCHOR_PATHS:
		if parent.has_node(path):
			var node := parent.get_node(path)
			if node is Control:
				var control: Control = node as Control
				var center: Vector2 = control.global_position + control.size * 0.5
				result.position = center + Vector2(0, -control.size.y * 0.15)
				result.size = control.size
				return result
	return result

func _refresh_state() -> void:
	if not _eco:
		update_state(0.0, 0.0, false)
		return
	var fraction: float = _eco.get_feed_fraction()
	var is_feeding: bool = _eco.is_feeding()
	var pps: float = _eco.current_pps()
	update_state(fraction, pps, is_feeding)

func _on_timer_timeout() -> void:
	_refresh_state()

func _on_soft_changed(_value: float) -> void:
	_refresh_state()

func _on_burst_state(_active: bool) -> void:
	_refresh_state()

func _log_activation(id: StringName, enabled: bool) -> void:
	var logger: YolkLogger = _get_logger()
	if logger:
		var state := "ON" if enabled else "OFF"
		logger.log("INFO", "VISUALS", "%s=%s" % [String(id), state], {})

func _get_logger() -> YolkLogger:
	var node := get_node_or_null("/root/Logger")
	if node is YolkLogger:
		return node as YolkLogger
	return null
