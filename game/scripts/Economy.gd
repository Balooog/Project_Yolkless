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

var feed_capacity: float = 100.0
var feed_current: float = 100.0
var feed_refill_rate: float = 10.0
var feed_consumption_rate: float = 20.0

var burst_active := false
var _is_auto_burst := false

var _auto_timer: Timer
var _autosave_timer: Timer

var _balance: Balance
var _research: Research

var _upgrade_levels := {}
var _autosave_interval := 30.0

const FEED_CAPACITY_BASE := 100.0
const FEED_REFILL_BASE := 10.0
const FEED_CONSUMPTION_BASE := 20.0

var _feed_efficiency_mult := 1.0
var _feed_reported_empty := false
var _feed_reported_full := false

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
	_recompute_feed_stats()
	_update_timers()

func _process(delta: float) -> void:
	if _balance == null or _research == null:
		return
	var previous_feed := feed_current

	if burst_active:
		feed_current = max(feed_current - feed_consumption_rate * delta, 0.0)
		if feed_current <= 0.0:
			feed_current = 0.0
			_stop_feeding("empty")
			_log_feed_empty()
	else:
		if feed_current < feed_capacity:
			feed_current = min(feed_current + feed_refill_rate * delta, feed_capacity)
			if feed_current >= feed_capacity:
				feed_current = feed_capacity
				_log_feed_full()

	if feed_current > 0.0 and previous_feed <= 0.0:
		_feed_reported_empty = false
	if feed_current < feed_capacity:
		_feed_reported_full = false

	var pps: float = _current_pps()
	var gained: float = pps * delta
	_add_soft(gained)

func try_burst(source_auto: bool = false) -> bool:
	if burst_active:
		return true
	if feed_current <= 0.0:
		return false
	_is_auto_burst = source_auto
	burst_active = true
	burst_state.emit(true)
	_log_feed_start(source_auto)
	return true

func stop_burst(reason: String = "manual") -> void:
	_stop_feeding(reason)

func _auto_burst_tick() -> void:
	if not _automation_enabled():
		return
	if feed_current <= 0.0:
		return
	try_burst(true)

func _stop_feeding(reason: String) -> void:
	if not burst_active:
		return
	burst_active = false
	burst_state.emit(false)
	_is_auto_burst = false
	_log_feed_stop(reason)

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
	_recompute_feed_stats()
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
	_recompute_feed_stats()
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
	if _balance == null or _research == null:
		return 0.0
	var base_pps := _base_pps()
	if not burst_active:
		return base_pps
	var burst_mult: float = float(_balance.constants.get("BURST_MULT", 6.0))
	var total_multiplier := burst_mult * _feed_efficiency_mult
	if _is_auto_burst:
		total_multiplier *= float(_balance.automation.get("auto_burst_efficiency", {}).get("value", 1.0))
	return base_pps * total_multiplier

func _base_pps() -> float:
	if _balance == null or _research == null:
		return 0.0
	var P0: float = float(_balance.constants.get("P0", 1.0))
	var tier_prod: float = float(_balance.factory_tiers.get(factory_tier, {}).get("prod_mult", 1.0))
	var prod_mult: float = _stat_multiplier("mul_prod")
	var research_mul: float = float(_research.multipliers["mul_prod"])
	return P0 * tier_prod * prod_mult * research_mul

func _current_capacity() -> float:
	if _balance == null or _research == null:
		return 0.0
	var base: float = 50.0
	var cap_mult: float = _stat_multiplier("mul_cap")
	var tier_cap: float = float(_balance.factory_tiers.get(factory_tier, {}).get("cap_mult", 1.0))
	var research_mul: float = float(_research.multipliers["mul_cap"])
	return base * cap_mult * tier_cap * research_mul

func offline_grant(elapsed_seconds: float) -> float:
	var cap_hours: float = float(_balance.constants.get("OFFLINE_CAP_HOURS", 8))
	var eff: float = float(_balance.constants.get("OFFLINE_EFFICIENCY", 0.8))
	var sim_time: float = min(elapsed_seconds, cap_hours * 3600.0)
	var pps: float = _base_pps()
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
	var base := K * pow(max(total_earned, 0.0), ALPHA)
	var multiplier := _environment_prestige_multiplier()
	return int(floor(base * multiplier))

func do_prestige() -> int:
	var earned := prestige_points_earned()
	_research.prestige_points += earned
	soft = 0.0
	total_earned = 0.0
	_upgrade_levels.clear()
	factory_tier = 1
	_recompute_feed_stats()
	feed_current = feed_capacity
	burst_active = false
	soft_changed.emit(soft)
	tier_changed.emit(factory_tier)
	_update_automation_state()
	var env_state := _environment_state()
	var env_multiplier := _environment_prestige_multiplier()
	_log("INFO", "ECONOMY", "Prestige performed", {
		"gained": earned,
		"prestige_total": _research.prestige_points,
		"env_multiplier": env_multiplier,
		"env_pollution": float(env_state.get("pollution", 0.0)),
		"env_stress": float(env_state.get("stress", 0.0)),
		"env_reputation": float(env_state.get("reputation", 0.0))
	})
	autosave.emit("prestige")
	return earned

func _update_timers() -> void:
	if _balance == null:
		return
	var base_cd: float = float(_balance.constants.get("BURST_COOLDOWN", 10.0))
	var auto_tick: float = float(_balance.automation.get("auto_burst", {}).get("value", base_cd))
	var auto_cd_adjust: float = float(_research.multipliers.get("auto_cd", 0.0))
	var adj: float = clamp(auto_tick + auto_cd_adjust, 0.1, 999.0)
	_auto_timer.wait_time = adj
	_autosave_interval = _balance.constants.get("AUTOSAVE_SECONDS", 30.0)
	_autosave_timer.wait_time = _autosave_interval
	if not _autosave_timer.is_stopped():
		_autosave_timer.stop()
	_autosave_timer.start()
	_update_automation_state()

func _on_balance_reload() -> void:
	_recompute_feed_stats()
	_update_timers()

func _get_upgrade_level(id: String) -> int:
	return int(_upgrade_levels.get(id, 0))

func _set_upgrade_level(id: String, lvl: int) -> void:
	_upgrade_levels[id] = lvl

func _stat_multiplier(stat: String) -> float:
	if _balance == null:
		return 1.0
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

func current_base_pps() -> float:
	return _base_pps()

func current_capacity() -> float:
	return _current_capacity()

func get_capacity_limit() -> float:
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

func get_feed_fraction() -> float:
	if feed_capacity <= 0.0:
		return 0.0
	return clamp(feed_current / feed_capacity, 0.0, 1.0)

func get_feed_seconds_to_full() -> float:
	if feed_current >= feed_capacity - 1e-6:
		return 0.0
	if feed_refill_rate <= 0.0:
		return INF
	return (feed_capacity - feed_current) / feed_refill_rate

func is_feeding() -> bool:
	return burst_active

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
	_recompute_feed_stats()
	_update_timers()
	_update_automation_state()

func _meets_requirements(row: Dictionary) -> bool:
	var requires: String = String(row.get("requires", "-"))
	if requires == "-" or requires == "":
		return true
	if requires.begins_with("factory>="):
		var parts: PackedStringArray = requires.split(">=")
		if parts.size() >= 2:
			var need := int(parts[1])
			return factory_tier >= need
	return true

func _recompute_feed_stats() -> void:
	if _balance == null:
		feed_capacity = FEED_CAPACITY_BASE
		feed_refill_rate = FEED_REFILL_BASE
		feed_consumption_rate = FEED_CONSUMPTION_BASE
		_feed_efficiency_mult = 1.0
		return
	var capacity_bonus := 0.0
	var capacity_scale := 1.0
	var refill_bonus := 0.0
	var refill_scale := 1.0
	var efficiency_bonus := 0.0
	var efficiency_scale := 1.0
	for id in _balance.upgrades.keys():
		var row: Dictionary = _balance.upgrades[id]
		var stat := String(row.get("stat", ""))
		var lvl := _get_upgrade_level(id)
		if lvl <= 0:
			continue
		var add := float(row.get("mult_add", 0.0))
		var mul := float(row.get("mult_mul", 1.0))
		match stat:
			"feed_capacity":
				capacity_bonus += add * lvl
				capacity_scale *= pow(mul, lvl)
			"feed_refill":
				refill_bonus += add * lvl
				refill_scale *= pow(mul, lvl)
			"feed_efficiency":
				efficiency_bonus += add * lvl
				efficiency_scale *= pow(mul, lvl)
	feed_capacity = max(1.0, (FEED_CAPACITY_BASE + capacity_bonus) * capacity_scale)
	feed_refill_rate = max(0.0, (FEED_REFILL_BASE + refill_bonus) * refill_scale)
	feed_consumption_rate = FEED_CONSUMPTION_BASE
	_feed_efficiency_mult = max(0.0, (1.0 + efficiency_bonus) * efficiency_scale)
	feed_current = clamp(feed_current, 0.0, feed_capacity)
	if feed_current <= 0.0:
		_feed_reported_empty = true
	if feed_current >= feed_capacity:
		_feed_reported_full = true

func _log_feed_start(auto_start: bool) -> void:
	_log("INFO", "FEED", "start", {
		"auto": auto_start,
		"current": feed_current,
		"capacity": feed_capacity
	})

func _log_feed_stop(reason: String) -> void:
	_log("INFO", "FEED", "stop", {
		"reason": reason,
		"current": feed_current,
		"capacity": feed_capacity
	})

func _log_feed_empty() -> void:
	if _feed_reported_empty:
		return
	_feed_reported_empty = true
	_log("INFO", "FEED", "empty", {
		"refill_seconds": get_feed_seconds_to_full()
	})

func _log_feed_full() -> void:
	if _feed_reported_full:
		return
	_feed_reported_full = true
	_log("INFO", "FEED", "full", {
		"capacity": feed_capacity
	})

func _environment_state() -> Dictionary:
	var node := get_node_or_null("/root/EnvironmentDirectorSingleton")
	if node is EnvironmentDirector:
		return (node as EnvironmentDirector).get_state()
	return {}

func _environment_prestige_multiplier(state: Dictionary = {}) -> float:
	var env_state := state
	if env_state.is_empty():
		env_state = _environment_state()
	if env_state.is_empty():
		return 1.0
	var pollution := float(env_state.get("pollution", 0.0))
	var stress := float(env_state.get("stress", 0.0))
	var reputation := float(env_state.get("reputation", 0.0))
	var modifier := reputation * 0.002 - pollution * 0.001 - stress * 0.0012
	return clamp(1.0 + modifier, 0.5, 1.5)

func _log(level: String, category: String, message: String, context: Dictionary = {}) -> void:
	var logger_node := get_node_or_null("/root/Logger")
	if logger_node is YolkLogger:
		(logger_node as YolkLogger).log(level, category, message, context)
