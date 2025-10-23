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
	var storage_value: float = _economy.current_storage()
	var wallet_value: float = _economy.soft
	var seed_value: int = 0
	var config_node := get_node_or_null("/root/Config")
	if config_node:
		var seed_variant: Variant = config_node.get("seed")
		if typeof(seed_variant) == TYPE_INT or typeof(seed_variant) == TYPE_FLOAT:
			seed_value = int(seed_variant)
	var feed_fraction: float = _economy.get_feed_fraction()
	var feed_seconds: float = _economy.get_feed_seconds_to_full()
	var feeding := _economy.is_feeding()
	var feed_state_key := "debug_overlay_feed_on" if feeding else "debug_overlay_feed_off"
	var feed_state_text := _get_string(feed_state_key, "ON" if feeding else "OFF")
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
	var seed_text := _get_string("debug_overlay_seed", "Seed: {seed}").format({
		"seed": seed_value
	})
	content.append(seed_text)
	var pps_text := _get_string("debug_overlay_pps", "PPS: {pps}").format({
		"pps": String.num(_economy.current_pps(), 2)
	})
	content.append(pps_text)
	var percent := 0.0
	if capacity > 0.0:
		percent = clamp(storage_value / capacity * 100.0, 0.0, 100.0)
	var storage_text := _get_string("debug_overlay_storage", "Storage: {storage} / {capacity} ({percent}%)").format({
		"storage": String.num(storage_value, 1),
		"capacity": String.num(capacity, 1),
		"percent": String.num(percent, 0)
	})
	content.append(storage_text)
	var wallet_text := _get_string("debug_overlay_wallet", "Credits: {wallet}").format({
		"wallet": String.num(wallet_value, 1)
	})
	content.append(wallet_text)
	var feed_text := _get_string("debug_overlay_feed", "Feed: {pct}% | State {state} | Refill {seconds}s").format({
		"pct": String.num(feed_fraction * 100.0, 0),
		"state": feed_state_text,
		"seconds": String.num(feed_seconds, 1)
	})
	content.append(feed_text)
	var tier_text := _get_string("debug_overlay_tier", "Tier: {tier} ({name})").format({
		"tier": _economy.factory_tier,
		"name": _economy.factory_name()
	})
	content.append(tier_text)
	var research_text := _get_string("debug_overlay_research", "Research multipliers: prod={prod} cap={cap} auto_cd={auto}").format({
		"prod": String.num(float(research_mult.get("mul_prod", 1.0)), 3),
		"cap": String.num(float(research_mult.get("mul_cap", 1.0)), 3),
		"auto": String.num(float(research_mult.get("auto_cd", 0.0)), 3)
	})
	content.append(research_text)
	var total_text := _get_string("debug_overlay_total", "Total earned: {total}").format({
		"total": String.num(_economy.get_total_earned(), 1)
	})
	content.append(total_text)
	var reputation_text := _get_string("debug_overlay_reputation", "Reputation: {stars} (+{next})").format({
		"stars": _research.prestige_points,
		"next": _economy.prestige_points_earned()
	})
	content.append(reputation_text)
	var logging_text := _get_string("debug_overlay_logging", "Logging: {status} | size {size} | rotations {rotations}").format({
		"status": logging_status,
		"size": log_size,
		"rotations": log_rotations
	})
	content.append(logging_text)
	var balance_text := _get_string("debug_overlay_balance_md5", "Balance md5: {hash}").format({
		"hash": balance_md5
	})
	content.append(balance_text)
	var save_text := _get_string("debug_overlay_save_hash", "Save hash: {hash}").format({
		"hash": save_hash
	})
	content.append(save_text)
	if _log_tail_cache.size() > 0:
		content.append(_get_string("debug_overlay_tail_title", "--- Log Tail ---"))
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
