extends Node
class_name Economy

signal soft_changed(value: float)
signal burst_state(active: bool)
signal tier_changed(tier: int)
signal autosave(reason: String)

var soft: float = 0.0
var total_earned: float = 0.0
var capacity_rank: int = 0
var prod_rank: int = 0
var factory_tier: int = 1

var burst_active := false
var _burst_left := 0.0
var _burst_cd_left := 0.0
var _is_auto_burst := false

var _auto_timer: Timer
var _autosave_timer: Timer

var _balance: Balance
var _research: Research

var _upgrade_levels := {}
var _autosave_interval := 30.0

func setup(balance: Balance, research: Research) -> void:
	_balance = balance
	_research = research
	_balance.reloaded.connect(_on_balance_reload)
	set_process(true)
	_auto_timer = Timer.new()
	_auto_timer.one_shot = false
	add_child(_auto_timer)
	_auto_timer.timeout.connect(_auto_burst_tick)
	_autosave_timer = Timer.new()
	_autosave_timer.one_shot = false
	add_child(_autosave_timer)
	_autosave_timer.timeout.connect(func(): autosave.emit("interval"))
	_update_timers()

func _process(delta: float) -> void:
	if _burst_cd_left > 0:
		_burst_cd_left = max(0.0, _burst_cd_left - delta)
	var pps: float = _current_pps()
	var add: float = pps * delta
	_add_soft(add)
	if burst_active:
		_burst_left -= delta
		if _burst_left <= 0:
			burst_active = false
			burst_state.emit(false)
			_is_auto_burst = false

func try_burst(source_auto: bool = false) -> bool:
	if burst_active:
		return false
	if _burst_cd_left > 0:
		return false
	_is_auto_burst = source_auto
	burst_active = true
	burst_state.emit(true)
	_burst_left = _balance.constants.get("BURST_DURATION", 5.0)
	_burst_cd_left = _balance.constants.get("BURST_COOLDOWN", 10.0)
	return true

func _auto_burst_tick() -> void:
	if not _automation_enabled():
		return
	try_burst(true)

func _add_soft(x: float) -> void:
	var cap := _current_capacity()
	soft = min(soft + x, cap)
	total_earned += x
	soft_changed.emit(soft)

func spend_soft(cost: float) -> bool:
	if soft + 1e-6 < cost:
		return false
	soft -= cost
	soft_changed.emit(soft)
	return true

func buy_upgrade(id: String) -> bool:
	if not _balance.upgrades.has(id):
		return false
	var row: Dictionary = _balance.upgrades[id]
	if not _meets_requirements(row):
		return false
	var level := _get_upgrade_level(id)
	var cost: float = _upgrade_cost(row, level)
	if not spend_soft(cost):
		return false
	_set_upgrade_level(id, level + 1)
	_log("INFO", "ECONOMY", "Upgrade purchased", {
		"id": id,
		"level": level + 1,
		"cost": cost,
		"soft": soft,
		"pps": current_pps()
	})
	autosave.emit("upgrade")
	_update_automation_state()
	return true

func promote_factory() -> bool:
	var next := factory_tier + 1
	if not _balance.factory_tiers.has(next):
		return false
	var cost: float = float(_balance.factory_tiers[next].get("cost", 0.0))
	if not spend_soft(cost):
		return false
	factory_tier = next
	tier_changed.emit(factory_tier)
	_update_timers()
	_update_automation_state()
	_log("INFO", "ECONOMY", "Factory promoted", {
		"tier": factory_tier,
		"cost": cost,
		"name": factory_name(),
		"capacity_mult": _balance.factory_tiers.get(factory_tier, {}).get("cap_mult", 1.0),
		"prod_mult": _balance.factory_tiers.get(factory_tier, {}).get("prod_mult", 1.0)
	})
	autosave.emit("tier")
	return true

func _current_pps() -> float:
	var P0: float = float(_balance.constants.get("P0", 1.0))
	var burst_mult: float = float(_balance.constants.get("BURST_MULT", 6.0))
	var tier_prod: float = float(_balance.factory_tiers.get(factory_tier, {}).get("prod_mult", 1.0))
	var prod_mult: float = _stat_multiplier("mul_prod")
	var burst_factor: float = 1.0
	if burst_active:
		burst_factor = burst_mult
		if _is_auto_burst:
			burst_factor *= float(_balance.automation.get("auto_burst_efficiency", {}).get("value", 1.0))
	var research_mul: float = float(_research.multipliers["mul_prod"])
	return P0 * tier_prod * prod_mult * research_mul * burst_factor

func _current_capacity() -> float:
	var base: float = 50.0
	var cap_mult: float = _stat_multiplier("mul_cap")
	var tier_cap: float = float(_balance.factory_tiers.get(factory_tier, {}).get("cap_mult", 1.0))
	var research_mul: float = float(_research.multipliers["mul_cap"])
	return base * cap_mult * tier_cap * research_mul

func offline_grant(elapsed_seconds: float) -> float:
	var cap_hours: float = float(_balance.constants.get("OFFLINE_CAP_HOURS", 8))
	var eff: float = float(_balance.constants.get("OFFLINE_EFFICIENCY", 0.8))
	var sim_time: float = min(elapsed_seconds, cap_hours * 3600.0)
	var pps: float = _current_pps()
	var grant: float = pps * sim_time * eff
	_add_soft(grant)
	_log("INFO", "OFFLINE", "Grant applied", {
		"elapsed": elapsed_seconds,
		"applied": sim_time,
		"eff": eff,
		"credits": grant
	})
	return grant

func prestige_points_earned() -> int:
	var K: float = float(_balance.prestige.get("K", 0.01))
	var ALPHA: float = float(_balance.prestige.get("ALPHA", 0.6))
	return int(floor(K * pow(max(total_earned, 0.0), ALPHA)))

func do_prestige() -> int:
	var earned := prestige_points_earned()
	_research.prestige_points += earned
	soft = 0.0
	total_earned = 0.0
	_upgrade_levels.clear()
	factory_tier = 1
	burst_active = false
	soft_changed.emit(soft)
	tier_changed.emit(factory_tier)
	_update_automation_state()
	_log("INFO", "ECONOMY", "Prestige performed", {
		"gained": earned,
		"prestige_total": _research.prestige_points
	})
	autosave.emit("prestige")
	return earned

func _update_timers() -> void:
	var base_cd: float = float(_balance.constants.get("BURST_COOLDOWN", 10.0))
	_burst_cd_left = min(_burst_cd_left, base_cd)
	var auto_tick: float = float(_balance.automation.get("auto_burst", {}).get("value", base_cd))
	var adj := clamp(auto_tick + float(_research.multipliers["auto_cd"]), 1.0, 999.0)
	_auto_timer.wait_time = adj
	_autosave_interval = _balance.constants.get("AUTOSAVE_SECONDS", 30.0)
	_autosave_timer.wait_time = _autosave_interval
	if not _autosave_timer.is_stopped():
		_autosave_timer.stop()
	_autosave_timer.start()
	_update_automation_state()

func _on_balance_reload() -> void:
	_update_timers()

func _get_upgrade_level(id: String) -> int:
	return int(_upgrade_levels.get(id, 0))

func _set_upgrade_level(id: String, lvl: int) -> void:
	_upgrade_levels[id] = lvl

func _stat_multiplier(stat: String) -> float:
	var mul := 1.0
	var add := 0.0
	for id in _balance.upgrades.keys():
		var row: Dictionary = _balance.upgrades[id]
		if row.get("stat", "") != stat:
			continue
		var lvl := _get_upgrade_level(id)
		if lvl <= 0:
			continue
		var mult_mul: float = float(row.get("mult_mul", 1.0))
		var mult_add: float = float(row.get("mult_add", 0.0))
		mul *= pow(mult_mul, lvl)
		add += mult_add * lvl
	return mul * (1.0 + add)

func _upgrade_cost(row: Dictionary, level: int) -> float:
	var base_cost: float = float(row.get("base_cost", 0.0))
	var growth: float = float(row.get("growth", 1.0))
	return base_cost * pow(growth, level)

func current_pps() -> float:
	return _current_pps()

func current_capacity() -> float:
	return _current_capacity()

func upgrade_cost(id: String) -> float:
	if not _balance.upgrades.has(id):
		return 0.0
	var row: Dictionary = _balance.upgrades[id]
	return _upgrade_cost(row, _get_upgrade_level(id))

func can_purchase_upgrade(id: String) -> bool:
	if not _balance.upgrades.has(id):
		return false
	return _meets_requirements(_balance.upgrades[id])

func next_factory_cost() -> float:
	var next := factory_tier + 1
	if not _balance.factory_tiers.has(next):
		return 0.0
	return float(_balance.factory_tiers[next].get("cost", 0.0))

func factory_name(tier: int = -1) -> String:
	var query := tier
	if query < 0:
		query = factory_tier
	return _balance.factory_tiers.get(query, {}).get("name", "")

func get_burst_cooldown_left() -> float:
	return _burst_cd_left

func get_burst_cooldown_total() -> float:
	return float(_balance.constants.get("BURST_COOLDOWN", 10.0))

func get_capacity_limit() -> float:
	return _current_capacity()

func get_offline_efficiency() -> float:
	return float(_balance.constants.get("OFFLINE_EFFICIENCY", 0.8))

func get_total_earned() -> float:
	return total_earned

func get_upgrade_levels() -> Dictionary:
	return _upgrade_levels.duplicate(true)

func _automation_enabled() -> bool:
	return _has_autoburst_unlock() and _tier_allows_auto()

func _has_autoburst_unlock() -> bool:
	for id in _balance.upgrades.keys():
		var row: Dictionary = _balance.upgrades[id]
		if row.get("stat", "") != "unlock_autoburst":
			continue
		if _get_upgrade_level(id) > 0:
			return true
	return false

func _tier_allows_auto() -> bool:
	var unlocks := String(_balance.factory_tiers.get(factory_tier, {}).get("unlocks", ""))
	return unlocks.find("auto") != -1

func _update_automation_state() -> void:
	if _automation_enabled():
		if _auto_timer.is_stopped():
			_auto_timer.start()
	else:
		if not _auto_timer.is_stopped():
			_auto_timer.stop()

func refresh_after_load() -> void:
	_update_timers()
	_update_automation_state()

func _meets_requirements(row: Dictionary) -> bool:
	var requires := row.get("requires", "-")
	if requires == "-" or requires == "":
		return true
	if requires.begins_with("factory>="):
		var parts: PackedStringArray = requires.split(">=")
		if parts.size() >= 2:
			var need := int(parts[1])
			return factory_tier >= need
	return true

func _log(level: String, category: String, message: String, context: Dictionary = {}) -> void:
	var logger := get_node_or_null("/root/Logger")
	if logger:
		logger.call("record", level, category, message, context)
