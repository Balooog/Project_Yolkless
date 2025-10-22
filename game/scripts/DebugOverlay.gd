extends CanvasLayer

@export var update_frequency := 0.25

@onready var stats_label: Label = %StatsLabel
@onready var panel: PanelContainer = %Panel

var _economy: Economy
var _research: Research
var _save: Save
var _balance: Balance
var _time_accumulator := 0.0

func configure(economy: Economy, research: Research, save: Save, balance: Balance) -> void:
	_economy = economy
	_research = research
	_save = save
	_balance = balance

func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.05, 0.9)
	style.border_width_all = 1
	style.border_color = Color(0.8, 0.8, 0.8, 0.4)
	panel.add_theme_stylebox_override("panel", style)
	stats_label.theme_override_colors.font_color = Color(1, 1, 1, 1)

func _process(delta: float) -> void:
	if not visible:
		return
	_time_accumulator += delta
	if _time_accumulator >= update_frequency:
		_time_accumulator = 0.0
		_refresh()

func _refresh() -> void:
	if _economy == null or _research == null:
		return
	var title := _get_string("debug_overlay_title", "DEBUG OVERLAY")
	var balance_md5 := ""
	var logger := get_node_or_null("/root/Logger")
	if logger:
		balance_md5 = logger.call("hash_md5_from_file", "res://game/data/balance.tsv")
	var save_hash := _save.get_current_hash() if _save != null else ""
	var capacity := _economy.get_capacity_limit()
	var soft_value := _economy.soft
	var cooldown_left := _economy.get_burst_cooldown_left()
	var cooldown_total := _economy.get_burst_cooldown_total()
	var research_mult := _research.multipliers
	var content: Array[String] = []
	content.append(title)
	content.append("PPS: %.2f" % _economy.current_pps())
	content.append("Capacity: %.1f / %.1f" % [soft_value, capacity])
	content.append("Burst: %s | Cooldown %.2fs / %.2fs" % [_economy.burst_active, cooldown_left, cooldown_total])
	content.append("Tier: %d (%s)" % [_economy.factory_tier, _economy.factory_name()])
	content.append("Research multipliers: prod=%.3f cap=%.3f auto_cd=%.3f" % [float(research_mult.get("mul_prod", 1.0)), float(research_mult.get("mul_cap", 1.0)), float(research_mult.get("auto_cd", 0.0))])
	content.append("Total earned: %.1f" % _economy.get_total_earned())
	content.append("Reputation: %d (+%d)" % [_research.prestige_points, _economy.prestige_points_earned()])
	content.append("Balance md5: %s" % balance_md5)
	content.append("Save hash: %s" % save_hash)
	stats_label.text = "\n".join(content)

func _get_string(key: String, fallback: String) -> String:
	var strings := get_node_or_null("/root/Strings")
	if strings:
		return strings.call("get_string", key, fallback)
	return fallback
*** End of File
