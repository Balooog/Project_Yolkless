extends CanvasLayer

@export var update_frequency := 0.25
const LOG_TAIL_REFRESH := 5.0

@onready var stats_label: Label = %StatsLabel
@onready var panel: PanelContainer = %Panel

var _economy: Economy
var _research: Research
var _save: Save
var _balance: Balance
var _time_accumulator := 0.0
var _log_refresh_accumulator := 0.0
var _tail_dirty := true
var _log_tail_cache: Array[String] = []

func configure(economy: Economy, research: Research, save: Save, balance: Balance) -> void:
	_economy = economy
	_research = research
	_save = save
	_balance = balance

func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.05, 0.9)
	style.set_border_width_all(1)
	style.border_color = Color(0.8, 0.8, 0.8, 0.4)
	panel.add_theme_stylebox_override("panel", style)
	stats_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))

func _process(delta: float) -> void:
	if not visible:
		return
	_time_accumulator += delta
	_log_refresh_accumulator += delta
	if _log_refresh_accumulator >= LOG_TAIL_REFRESH:
		_log_refresh_accumulator = 0.0
		_tail_dirty = true
	if _time_accumulator >= update_frequency:
		_time_accumulator = 0.0
		var refresh_tail := _tail_dirty
		_tail_dirty = false
		_refresh(refresh_tail)

func _refresh(refresh_tail: bool) -> void:
	if _economy == null or _research == null:
		return
	var title := _get_string("debug_overlay_title", "DEBUG OVERLAY")
	var balance_md5: String = ""
	var logger_node := get_node_or_null("/root/Logger")
	if logger_node is YolkLogger:
		balance_md5 = (logger_node as YolkLogger).hash_md5_from_file("res://game/data/balance.tsv")
	var save_hash: String = _save.get_current_hash() if _save != null else ""
	var capacity: float = _economy.get_capacity_limit()
	var soft_value: float = _economy.soft
	var feed_fraction: float = _economy.get_feed_fraction()
	var feed_seconds: float = _economy.get_feed_seconds_to_full()
	var feeding := _economy.is_feeding()
	var research_mult: Dictionary = _research.multipliers
	var logging_status := "OFF"
	var log_size := "0 B"
	var log_rotations := 0
	if logger_node is YolkLogger:
		var stats: Dictionary = (logger_node as YolkLogger).get_log_stats()
		if stats.get("enabled", false):
			logging_status = "ON"
		else:
			logging_status = "OFF"
		log_size = _format_bytes(int(stats.get("size", 0)))
		log_rotations = int(stats.get("rotation_index", 0))
		if refresh_tail:
			var tail_lines := (logger_node as YolkLogger).get_recent_lines(10)
			_log_tail_cache = []
			for line in tail_lines:
				_log_tail_cache.append((logger_node as YolkLogger).sanitize(line))
	elif refresh_tail:
		_log_tail_cache = []
	var content: Array[String] = []
	content.append(title)
	content.append("PPS: %.2f" % _economy.current_pps())
	content.append("Capacity: %.1f / %.1f" % [soft_value, capacity])
	var feed_state_text := "OFF"
	if feeding:
		feed_state_text = "ON"
	content.append("Feed: %.0f%% | State %s | Refill %.1fs" % [feed_fraction * 100.0, feed_state_text, feed_seconds])
	content.append("Tier: %d (%s)" % [_economy.factory_tier, _economy.factory_name()])
	content.append("Research multipliers: prod=%.3f cap=%.3f auto_cd=%.3f" % [float(research_mult.get("mul_prod", 1.0)), float(research_mult.get("mul_cap", 1.0)), float(research_mult.get("auto_cd", 0.0))])
	content.append("Total earned: %.1f" % _economy.get_total_earned())
	content.append("Reputation: %d (+%d)" % [_research.prestige_points, _economy.prestige_points_earned()])
	content.append("Logging: %s | size %s | rotations %d" % [logging_status, log_size, log_rotations])
	content.append("Balance md5: %s" % balance_md5)
	content.append("Save hash: %s" % save_hash)
	if _log_tail_cache.size() > 0:
		content.append("--- Log Tail ---")
		for line in _log_tail_cache:
			content.append(line)
	stats_label.text = "\n".join(content)

func _get_string(key: String, fallback: String) -> String:
	var strings_node := get_node_or_null("/root/Strings")
	if strings_node is StringsCatalog:
		return (strings_node as StringsCatalog).get_text(key, fallback)
	return fallback

func _format_bytes(size: int) -> String:
	if size >= 1024 * 1024:
		return "%.2f MB" % (float(size) / 1048576.0)
	if size >= 1024:
		return "%.1f KB" % (float(size) / 1024.0)
	return "%d B" % size
