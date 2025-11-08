extends Node
class_name Economy

const StatBus := preload("res://src/services/StatBus.gd")
const EnvironmentService := preload("res://src/services/EnvironmentService.gd")
const AutomationService := preload("res://src/services/AutomationService.gd")
const PowerService := preload("res://src/services/PowerService.gd")
const StatsProbe := preload("res://src/services/StatsProbe.gd")

signal soft_changed(value: float)
signal storage_changed(value: float, capacity: float)
signal burst_state(active: bool)
signal tier_changed(tier: int)
signal autosave(reason: String)
signal dump_triggered(amount: float, new_balance: float)
signal conveyor_metrics_changed(rate: float, queue_len: int, jam_active: bool)
signal economy_rate_changed(rate: float, label: String)
signal conveyor_backlog_changed(queue_len: int, label: String, tone: StringName)

var soft: float = 0.0
var total_earned: float = 0.0
var storage: float = 0.0
var capacity_rank: int = 0
var prod_rank: int = 0
var factory_tier: int = 1

var feed_capacity: float = 100.0
var feed_current: float = 100.0
var feed_refill_rate: float = 10.0
var feed_consumption_rate: float = 20.0

var burst_active := false
var _is_auto_burst := false

var _autosave_timer: Timer

var _balance: Balance
var _research: Research

var _upgrade_levels := {}
var _autosave_interval := 30.0
var _dump_enabled := false

const FEED_CAPACITY_BASE := 100.0
const FEED_REFILL_BASE := 16.0
const FEED_CONSUMPTION_BASE := 25.0
const AUTOMATION_ENV_THRESHOLD := 0.75
const MANUAL_SHIP_EFFICIENCY := 0.75
const SNAPSHOT_INTERVAL := 20.0
const CONVEYOR_JAM_QUEUE_THRESHOLD := 40
const CONVEYOR_JAM_SECONDS := 2.5

var _feed_efficiency_mult := 1.0
var _feed_reported_empty := false
var _feed_reported_full := false
var _last_offline_passive_mult := 0.0
var _storage_reported_full := false
var _statbus: StatBus
var _automation_service: AutomationService
var _power_service: PowerService
var _use_scheduler := false
var _snapshot_timer: float = 0.0
var _stats_probe: StatsProbe
const PROFILING_PHASE_IN := StringName("eco_in_ms")
const PROFILING_PHASE_APPLY := StringName("eco_apply_ms")
const PROFILING_PHASE_SHIP := StringName("eco_ship_ms")
const PROFILING_PHASE_RESEARCH := StringName("eco_research_ms")
const PROFILING_PHASE_STATBUS := StringName("eco_statbus_ms")
const PROFILING_PHASE_UI := StringName("eco_ui_ms")
const PROFILING_PHASES := [
	PROFILING_PHASE_IN,
	PROFILING_PHASE_APPLY,
	PROFILING_PHASE_SHIP,
	PROFILING_PHASE_RESEARCH,
	PROFILING_PHASE_STATBUS,
	PROFILING_PHASE_UI
]
var _profiling_sections: Dictionary = {}
var _profiling_active: bool = false
var _ship_amortization_enabled: bool = false
var _pending_shipment_logs: Array[Dictionary] = []
var _conveyor_manager: Node
var _conveyor_rate: float = 0.0
var _conveyor_queue: int = 0
var _conveyor_delivered_total: int = 0
var _conveyor_last_update_msec: int = 0
var _conveyor_jam_timer: float = 0.0
var _conveyor_jam_active: bool = false
var _last_economy_rate: float = -1.0
var _last_economy_rate_label: String = "0.0/s"
var _last_conveyor_backlog: int = -1
var _last_conveyor_backlog_label: String = "Queue 0"
var _last_conveyor_backlog_tone: StringName = StringName("normal")

func setup(balance: Balance, research: Research) -> void:
	_balance = balance
	_research = research
	_balance.reloaded.connect(_on_balance_reload)
	_research.changed.connect(_on_research_changed)
	set_process(true)
	_statbus = _statbus_ref()
	_autosave_timer = Timer.new()
	_autosave_timer.one_shot = false
	add_child(_autosave_timer)
	_autosave_timer.timeout.connect(func(): autosave.emit("interval"))
	storage = 0.0
	_recompute_feed_stats()
	_refresh_dump_state()
	_emit_storage_changed()
	_update_timers()
	_bind_services()
	_register_statbus_metrics()
	_stats_probe = _get_stats_probe()
	_profiling_init()
	_refresh_config_flags()
	_update_economy_rate_signal(_current_pps())
	_update_conveyor_backlog_signal()

func _process(delta: float) -> void:
	if _use_scheduler:
		return
	_tick(delta)

func simulate_tick(delta: float) -> void:
	_tick(delta)

func set_scheduler_enabled(enabled: bool) -> void:
	_use_scheduler = enabled

func register_conveyor_manager(manager: Node) -> void:
	if manager == _conveyor_manager:
		return
	if _conveyor_manager and is_instance_valid(_conveyor_manager):
		_detach_conveyor_signals(_conveyor_manager)
	_conveyor_manager = manager
	if _conveyor_manager == null or not is_instance_valid(_conveyor_manager):
		_conveyor_rate = 0.0
		_conveyor_queue = 0
		_conveyor_jam_timer = 0.0
		_conveyor_jam_active = false
		_conveyor_last_update_msec = 0
		_update_conveyor_statbus()
		conveyor_metrics_changed.emit(_conveyor_rate, _conveyor_queue, _conveyor_jam_active)
		_update_conveyor_backlog_signal()
		_conveyor_manager = null
		return
	if _conveyor_manager.has_signal("throughput_updated"):
		var callable := Callable(self, "_on_conveyor_throughput_updated")
		if not _conveyor_manager.is_connected("throughput_updated", callable):
			_conveyor_manager.connect("throughput_updated", callable)
	if _conveyor_manager.has_signal("item_delivered"):
		var delivered_callable := Callable(self, "_on_conveyor_item_delivered")
		if not _conveyor_manager.is_connected("item_delivered", delivered_callable):
			_conveyor_manager.connect("item_delivered", delivered_callable)
	_update_conveyor_statbus()
	conveyor_metrics_changed.emit(_conveyor_rate, _conveyor_queue, _conveyor_jam_active)
	_update_conveyor_backlog_signal()
	_update_conveyor_backlog_signal()

func _tick(delta: float) -> void:
	if _balance == null or _research == null:
		return
	_profiling_reset()
	_process_deferred_shipments()
	var tick_start := Time.get_ticks_usec()
	var input_start := tick_start
	var previous_feed: float = feed_current
	var env_feed_modifier: float = _environment_feed_modifier()
	_update_power_service(_environment_power_modifier())
	var consumption_rate: float = feed_consumption_rate / max(env_feed_modifier, 0.1)
	var refill_rate: float = feed_refill_rate * clamp(env_feed_modifier, 0.5, 1.5)

	if burst_active:
		feed_current = max(feed_current - consumption_rate * delta, 0.0)
		if feed_current <= 0.0:
			feed_current = 0.0
			_stop_feeding("empty")
			_log_feed_empty()
	else:
		if feed_current < feed_capacity:
			feed_current = min(feed_current + refill_rate * delta, feed_capacity)
			if feed_current >= feed_capacity:
				feed_current = feed_capacity
				_log_feed_full()

	if feed_current > 0.0 and previous_feed <= 0.0:
		_feed_reported_empty = false
	if feed_current < feed_capacity:
		_feed_reported_full = false
	_profiling_accumulate(PROFILING_PHASE_IN, Time.get_ticks_usec() - input_start)

	var apply_start := Time.get_ticks_usec()
	var base_pps := _base_pps()
	var pps: float = _current_pps()
	_profiling_accumulate(PROFILING_PHASE_APPLY, Time.get_ticks_usec() - apply_start)

	var statbus_start := Time.get_ticks_usec()
	_update_statbus_pps(base_pps, pps)
	_update_feed_fraction_stat()
	_profiling_accumulate(PROFILING_PHASE_STATBUS, Time.get_ticks_usec() - statbus_start)

	var gained: float = pps * delta
	var ship_start := Time.get_ticks_usec()
	_apply_income(gained)
	_profiling_accumulate(PROFILING_PHASE_SHIP, Time.get_ticks_usec() - ship_start)

	_refresh_automation_binding()
	_snapshot_timer += delta
	if _snapshot_timer >= SNAPSHOT_INTERVAL:
		_snapshot_timer = 0.0
		_log_economy_snapshot(base_pps, pps)
	var tick_ms := float(Time.get_ticks_usec() - tick_start) / 1000.0
	var feed_fraction := 0.0
	if feed_capacity > 0.0:
		feed_fraction = clamp(feed_current / feed_capacity, 0.0, 1.0)
	_update_economy_rate_signal(pps)
	_record_stats_probe(tick_ms, pps, base_pps, feed_fraction)
	_profiling_finish()

func try_burst(source_auto: bool = false) -> bool:
	if burst_active:
		return true
	if feed_current <= 0.0:
		return false
	_is_auto_burst = source_auto
	burst_active = true
	var ui_start := Time.get_ticks_usec()
	burst_state.emit(true)
	_profiling_accumulate(PROFILING_PHASE_UI, Time.get_ticks_usec() - ui_start)
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
	var ui_start := Time.get_ticks_usec()
	burst_state.emit(false)
	_profiling_accumulate(PROFILING_PHASE_UI, Time.get_ticks_usec() - ui_start)
	_is_auto_burst = false
	_log_feed_stop(reason)

func _apply_income(amount: float) -> void:
	if amount <= 0.0:
		return
	total_earned += amount
	_route_income_to_storage(amount)

func _route_income_to_storage(amount: float) -> void:
	var remaining: float = amount
	var safety := 0
	while remaining > 0.0 and safety < 128:
		safety += 1
		var capacity: float = _current_capacity()
		if capacity <= 0.0:
			return
		var space: float = capacity - storage
		if space > 1e-6:
			_storage_reported_full = false
		if space <= 1e-6:
			_log_storage_full("no_space_before_chunk", capacity)
			if _dump_enabled:
				_perform_dump("auto")
				continue
			storage = clamp(storage, 0.0, capacity)
			_emit_storage_changed()
			return
		var chunk: float = min(space, remaining)
		storage += chunk
		remaining -= chunk
		_emit_storage_changed()
		if storage < capacity - 1e-6:
			_storage_reported_full = false
		elif _dump_enabled:
			_log_storage_full("auto_dump_trigger", capacity)
			_perform_dump("auto")
	if safety >= 128 and remaining > 0.0:
		_log("WARN", "ECONOMY", "Income routing safety limit reached", {
			"remaining": remaining,
			"storage": storage,
			"capacity": _current_capacity()
		})

func _deposit_soft(amount: float, reason: String = "income") -> void:
	if amount <= 0.0:
		return
	soft = max(0.0, soft + amount)
	var ui_start := Time.get_ticks_usec()
	soft_changed.emit(soft)
	_profiling_accumulate(PROFILING_PHASE_UI, Time.get_ticks_usec() - ui_start)

func _perform_dump(reason: String = "auto") -> void:
	if storage <= 0.0:
		return
	if _ship_amortization_enabled:
		_perform_dump_internal(reason, false, true)
	else:
		_perform_dump_internal(reason, true, false)

func _perform_dump_internal(reason: String = "auto", log_immediately: bool = true, amortized: bool = false) -> void:
	var amount: float = storage
	if amount <= 0.0:
		return
	storage = 0.0
	_storage_reported_full = false
	_emit_storage_changed()
	_deposit_soft(amount, reason)
	var ui_start := Time.get_ticks_usec()
	dump_triggered.emit(amount, soft)
	_profiling_accumulate(PROFILING_PHASE_UI, Time.get_ticks_usec() - ui_start)
	var context := {
		"shipped": amount,
		"balance": soft,
		"capacity": _current_capacity(),
		"reason": reason
	}
	if amortized:
		context["amortized"] = true
	if log_immediately or not _ship_amortization_enabled:
		_log("INFO", "ECONOMY", "Auto shipment processed", context)
	else:
		_queue_shipment_log(context)

func _emit_storage_changed() -> void:
	var capacity := _current_capacity()
	if capacity <= 0.0:
		capacity = 0.0
	if storage > capacity:
		storage = capacity
	if storage < 0.0:
		storage = 0.0
	var ui_start := Time.get_ticks_usec()
	storage_changed.emit(storage, capacity)
	_profiling_accumulate(PROFILING_PHASE_UI, Time.get_ticks_usec() - ui_start)
	_update_statbus_storage(storage, capacity)

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
	_emit_storage_changed()
	_log("INFO", "ECONOMY", "Upgrade purchased", {
		"id": id,
		"level": level + 1,
		"cost": cost,
		"soft": soft,
		"pps": current_pps()
	})
	autosave.emit("upgrade")
	_refresh_automation_binding()
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
	_refresh_automation_binding()
	_emit_storage_changed()
	_log("INFO", "ECONOMY", "Factory promoted", {
		"tier": factory_tier,
		"cost": cost,
		"name": factory_name(),
		"capacity_mult": _balance.factory_tiers.get(factory_tier, {}).get("cap_mult", 1.0),
		"prod_mult": _balance.factory_tiers.get(factory_tier, {}).get("prod_mult", 1.0)
	})
	autosave.emit("tier")
	return true

func _current_pps(feed_boost: bool = true) -> float:
	if _balance == null or _research == null:
		return 0.0
	var base_pps: float = _base_pps()
	if not feed_boost:
		return base_pps
	if not burst_active:
		return base_pps
	var burst_mult: float = float(_balance.constants.get("BURST_MULT", 6.0))
	var feed_efficiency: float = max(_feed_efficiency_mult - 1.0, 0.0)
	var total_multiplier: float = burst_mult * (1.0 + feed_efficiency)
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
	var env_power: float = _environment_power_modifier()
	var comfort_bonus: float = 1.0 + _statbus_value(&"ci_bonus", 0.0)
	return P0 * tier_prod * prod_mult * research_mul * env_power * comfort_bonus

func _current_capacity() -> float:
	if _balance == null or _research == null:
		return 0.0
	var base: float = float(_balance.constants.get("CAPACITY_BASE", 50.0))
	var cap_mult: float = _stat_multiplier("mul_cap")
	var tier_cap: float = float(_balance.factory_tiers.get(factory_tier, {}).get("cap_mult", 1.0))
	var research_mul: float = float(_research.multipliers["mul_cap"])
	return base * cap_mult * tier_cap * research_mul

func offline_grant(elapsed_seconds: float) -> float:
	var cap_hours: float = float(_balance.constants.get("OFFLINE_CAP_HOURS", 8))
	var eff: float = float(_balance.constants.get("OFFLINE_EFFICIENCY", 0.8))
	var passive_mult: float = float(_balance.constants.get("OFFLINE_PASSIVE_MULT", 0.25))
	var automation_bonus: float = float(_balance.constants.get("OFFLINE_AUTOMATION_BONUS", 1.5))
	var sim_time: float = min(elapsed_seconds, cap_hours * 3600.0)
	var base_pps: float = _current_pps(false)
	var passive_pps: float = base_pps * eff * passive_mult
	var has_automation: bool = _automation_enabled()
	if has_automation:
		passive_pps *= automation_bonus
	var grant: float = passive_pps * sim_time
	_last_offline_passive_mult = 0.0
	if base_pps > 0.0:
		_last_offline_passive_mult = passive_pps / base_pps
	_apply_income(grant)
	var log_line: String = "dt=%d passive_mult=%.2f auto=%s grant=%.1f" % [
		int(sim_time),
		_last_offline_passive_mult,
		("yes" if has_automation else "no"),
		grant
	]
	_log("INFO", "OFFLINE", log_line, {})
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
	storage = 0.0
	_upgrade_levels.clear()
	factory_tier = 1
	_recompute_feed_stats()
	_refresh_dump_state()
	_emit_storage_changed()
	feed_current = feed_capacity
	burst_active = false
	soft_changed.emit(soft)
	tier_changed.emit(factory_tier)
	_refresh_automation_binding()
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
	_autosave_interval = _balance.constants.get("AUTOSAVE_SECONDS", 30.0)
	_autosave_timer.wait_time = _autosave_interval
	if not _autosave_timer.is_stopped():
		_autosave_timer.stop()
	_autosave_timer.start()
	_refresh_automation_interval()
	_refresh_automation_binding()

func _automation_interval() -> float:
	if _balance == null:
		return 10.0
	var base_cd: float = float(_balance.constants.get("BURST_COOLDOWN", 10.0))
	var auto_tick: float = float(_balance.automation.get("auto_burst", {}).get("value", base_cd))
	var auto_cd_adjust: float = float(_research.multipliers.get("auto_cd", 0.0))
	return clamp(auto_tick + auto_cd_adjust, 0.1, 999.0)

func _refresh_dump_state() -> void:
	if _balance == null:
		_dump_enabled = false
		return
	_dump_enabled = int(_balance.constants.get("DUMP_ON_FULL", 0)) != 0

func _on_balance_reload() -> void:
	_recompute_feed_stats()
	_refresh_dump_state()
	_emit_storage_changed()
	_update_timers()

func _on_research_changed() -> void:
	_refresh_automation_interval()
	_refresh_automation_binding()

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

func last_offline_passive_multiplier() -> float:
	return _last_offline_passive_mult

func current_base_pps() -> float:
	return _base_pps()

func current_capacity() -> float:
	return _current_capacity()

func get_capacity_limit() -> float:
	return _current_capacity()

func current_storage() -> float:
	return storage

func storage_fill_fraction() -> float:
	var capacity := _current_capacity()
	if capacity <= 0.0:
		return 0.0
	return clamp(storage / capacity, 0.0, 1.0)

func manual_ship_efficiency() -> float:
	return MANUAL_SHIP_EFFICIENCY

func manual_ship_now() -> float:
	if storage <= 0.0:
		return 0.0
	var shipped: float = storage
	storage = 0.0
	_storage_reported_full = false
	_emit_storage_changed()
	var payout: float = shipped * MANUAL_SHIP_EFFICIENCY
	_deposit_soft(payout, "manual")
	dump_triggered.emit(payout, soft)
	_log("INFO", "ECONOMY", "Manual shipment processed", {
		"stored": shipped,
		"payout": payout,
		"efficiency": MANUAL_SHIP_EFFICIENCY,
		"capacity": _current_capacity()
	})
	return payout

func is_dump_enabled() -> bool:
	return _dump_enabled

func dump_animation_ms() -> int:
	if _balance == null:
		return 300
	return int(_balance.constants.get("DUMP_ANIM_MS", 300))

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

func _automation_conditions_met() -> bool:
	if _balance == null:
		return false
	return _has_autoburst_unlock() and _tier_allows_auto()

func _automation_environment_ok() -> bool:
	return _environment_feed_modifier() >= AUTOMATION_ENV_THRESHOLD

func _automation_enabled() -> bool:
	return _automation_conditions_met() and _automation_environment_ok()

func _handle_autoburst_request() -> bool:
	if not _automation_conditions_met():
		return false
	if not _automation_environment_ok():
		return false
	if feed_current <= 0.0:
		return false
	return try_burst(true)

func _has_autoburst_unlock() -> bool:
	if _balance == null:
		return false
	for id in _balance.upgrades.keys():
		var row: Dictionary = _balance.upgrades[id]
		if row.get("stat", "") != "unlock_autoburst":
			continue
		if _get_upgrade_level(id) > 0:
			return true
	return false

func _tier_allows_auto() -> bool:
	if _balance == null:
		return false
	var unlocks := String(_balance.factory_tiers.get(factory_tier, {}).get("unlocks", ""))
	return unlocks.find("auto") != -1

func refresh_after_load() -> void:
	_recompute_feed_stats()
	_refresh_dump_state()
	_emit_storage_changed()
	_update_timers()
	_refresh_automation_binding()

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
	var base_capacity := _base_feed_capacity()
	var base_refill := _base_feed_refill_rate()
	var base_consumption := _base_feed_consumption_rate()
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
	feed_capacity = max(1.0, (base_capacity + capacity_bonus) * capacity_scale)
	feed_refill_rate = max(0.0, (base_refill + refill_bonus) * refill_scale)
	feed_consumption_rate = base_consumption
	_feed_efficiency_mult = max(0.0, (1.0 + efficiency_bonus) * efficiency_scale)
	feed_current = clamp(feed_current, 0.0, feed_capacity)
	if feed_current <= 0.0:
		_feed_reported_empty = true
	if feed_current >= feed_capacity:
		_feed_reported_full = true
	_refresh_automation_binding()
	_update_feed_fraction_stat()

func _base_feed_capacity() -> float:
	if _balance == null:
		return FEED_CAPACITY_BASE
	return float(_balance.constants.get("FEED_SUPPLY_MAX", FEED_CAPACITY_BASE))

func _base_feed_refill_rate() -> float:
	if _balance == null:
		return FEED_REFILL_BASE
	return float(_balance.constants.get("FEED_SUPPLY_REFILL_RATE", FEED_REFILL_BASE))

func _base_feed_consumption_rate() -> float:
	if _balance == null:
		return FEED_CONSUMPTION_BASE
	return float(_balance.constants.get("FEED_SUPPLY_DRAIN_RATE", FEED_CONSUMPTION_BASE))

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

func _log_economy_snapshot(base_pps: float, pps: float) -> void:
	_log("INFO", "ECONOMY", "snapshot", {
		"pps_base": base_pps,
		"pps": pps,
		"storage": storage,
		"capacity": _current_capacity(),
		"wallet": soft,
		"feed_pct": get_feed_fraction(),
		"burst_active": burst_active,
		"automation_ready": _automation_enabled(),
		"automation_unlocked": _has_autoburst_unlock(),
		"env_feed_modifier": _environment_feed_modifier(),
		"env_power_modifier": _environment_power_modifier()
	})

func _log_storage_full(reason: String, capacity: float) -> void:
	if _storage_reported_full:
		return
	_storage_reported_full = true
	_log("INFO", "ECONOMY", "Storage full", {
		"reason": reason,
		"capacity": capacity,
		"dump_enabled": _dump_enabled
	})

func _environment_state() -> Dictionary:
	var service: EnvironmentService = _environment_service()
	if service:
		return service.get_state()
	return {}

func _environment_modifiers() -> Dictionary:
	var service: EnvironmentService = _environment_service()
	if service:
		return service.get_modifiers()
	var state := _environment_state()
	if state.is_empty():
		return {}
	var modifiers_variant: Variant = state.get("modifiers", {})
	if modifiers_variant is Dictionary:
		return modifiers_variant
	return {}

func _environment_feed_modifier() -> float:
	var modifiers := _environment_modifiers()
	if modifiers.has("feed"):
		return clamp(float(modifiers.get("feed", 1.0)), 0.1, 3.0)
	return 1.0

func _environment_power_modifier() -> float:
	var modifiers := _environment_modifiers()
	if modifiers.has("power"):
		return clamp(float(modifiers.get("power", 1.0)), 0.5, 1.5)
	return 1.0

func _environment_prestige_multiplier(state: Dictionary = {}) -> float:
	var env_state: Dictionary = state
	if env_state.is_empty():
		env_state = _environment_state()
	if env_state.is_empty():
		return 1.0
	var modifiers_variant: Variant = env_state.get("modifiers", {})
	if modifiers_variant is Dictionary:
		var modifiers_dict: Dictionary = modifiers_variant as Dictionary
		if modifiers_dict.has("prestige"):
			return clamp(float(modifiers_dict.get("prestige", 1.0)), 0.5, 1.5)
	var pollution := float(env_state.get("pollution", 0.0))
	var stress := float(env_state.get("stress", 0.0))
	var reputation := float(env_state.get("reputation", 0.0))
	var modifier := reputation * 0.002 - pollution * 0.001 - stress * 0.0012
	return clamp(1.0 + modifier, 0.5, 1.5)

func _register_statbus_metrics() -> void:
	_statbus_ref()
	if _statbus == null:
		return
	_statbus.register_stat(&"pps_base", {"stack": "replace", "default": 0.0})
	_statbus.register_stat(&"pps", {"stack": "replace", "default": 0.0})
	_statbus.register_stat(&"storage", {"stack": "replace", "default": storage})
	_statbus.register_stat(&"storage_capacity", {"stack": "replace", "default": _current_capacity()})
	_statbus.register_stat(&"feed_fraction", {"stack": "replace", "default": get_feed_fraction()})
	_statbus.register_stat(&"conveyor_rate", {"stack": "replace", "default": 0.0})
	_statbus.register_stat(&"conveyor_queue", {"stack": "replace", "default": 0.0})
	_statbus.register_stat(&"conveyor_delivered_total", {"stack": "replace", "default": 0.0})
	_statbus.register_stat(&"conveyor_jam_active", {"stack": "replace", "default": 0.0})
	_update_statbus_storage(storage, _current_capacity())
	_update_statbus_pps(_base_pps(), _current_pps())
	_update_feed_fraction_stat()
	_update_conveyor_statbus()

func _update_statbus_pps(base_pps: float, pps: float) -> void:
	var phase_start := Time.get_ticks_usec()
	_statbus_ref()
	if _statbus == null:
		_profiling_accumulate(PROFILING_PHASE_STATBUS, Time.get_ticks_usec() - phase_start)
		return
	_statbus.set_stat(&"pps_base", base_pps, "Economy")
	_statbus.set_stat(&"pps", pps, "Economy")
	_profiling_accumulate(PROFILING_PHASE_STATBUS, Time.get_ticks_usec() - phase_start)

func _update_statbus_storage(current_storage: float, capacity: float) -> void:
	var phase_start := Time.get_ticks_usec()
	_statbus_ref()
	if _statbus == null:
		_profiling_accumulate(PROFILING_PHASE_STATBUS, Time.get_ticks_usec() - phase_start)
		return
	_statbus.set_stat(&"storage", current_storage, "Economy")
	_statbus.set_stat(&"storage_capacity", capacity, "Economy")
	_profiling_accumulate(PROFILING_PHASE_STATBUS, Time.get_ticks_usec() - phase_start)

func _update_feed_fraction_stat() -> void:
	var phase_start := Time.get_ticks_usec()
	_statbus_ref()
	if _statbus == null:
		_profiling_accumulate(PROFILING_PHASE_STATBUS, Time.get_ticks_usec() - phase_start)
		return
	_statbus.set_stat(&"feed_fraction", get_feed_fraction(), "Economy")
	_profiling_accumulate(PROFILING_PHASE_STATBUS, Time.get_ticks_usec() - phase_start)

func _update_power_service(value: float) -> void:
	var service := _get_power_service()
	if service:
		service.update_power_state(value)
	var auto_service := _get_automation_service()
	if auto_service:
		auto_service.set_power_state(value)

func _statbus_value(key: StringName, default_value: float = 0.0) -> float:
	_statbus_ref()
	if _statbus == null:
		return default_value
	return _statbus.get_stat(key, default_value)

func _process_deferred_shipments() -> void:
	if _pending_shipment_logs.is_empty():
		return
	var start := Time.get_ticks_usec()
	for entry in _pending_shipment_logs:
		_log("INFO", "ECONOMY", "Auto shipment processed", entry)
	_pending_shipment_logs.clear()
	_profiling_accumulate(PROFILING_PHASE_SHIP, Time.get_ticks_usec() - start)

func _detach_conveyor_signals(manager: Node) -> void:
	if manager == null or not is_instance_valid(manager):
		return
	var throughput_cb := Callable(self, "_on_conveyor_throughput_updated")
	if manager.has_signal("throughput_updated") and manager.is_connected("throughput_updated", throughput_cb):
		manager.disconnect("throughput_updated", throughput_cb)
	var delivered_cb := Callable(self, "_on_conveyor_item_delivered")
	if manager.has_signal("item_delivered") and manager.is_connected("item_delivered", delivered_cb):
		manager.disconnect("item_delivered", delivered_cb)

func _on_conveyor_throughput_updated(rate: float, queue_len: int) -> void:
	_conveyor_rate = max(rate, 0.0)
	_conveyor_queue = max(queue_len, 0)
	var now_msec := Time.get_ticks_msec()
	var delta_seconds := 0.0
	if _conveyor_last_update_msec > 0:
		delta_seconds = max(float(now_msec - _conveyor_last_update_msec) / 1000.0, 0.0)
	_conveyor_last_update_msec = now_msec
	if _conveyor_queue >= CONVEYOR_JAM_QUEUE_THRESHOLD:
		_conveyor_jam_timer += delta_seconds
	else:
		_conveyor_jam_timer = max(_conveyor_jam_timer - delta_seconds, 0.0)
	var jam_active := _conveyor_jam_timer >= CONVEYOR_JAM_SECONDS
	if jam_active != _conveyor_jam_active:
		_conveyor_jam_active = jam_active
	_update_conveyor_statbus()
	conveyor_metrics_changed.emit(_conveyor_rate, _conveyor_queue, _conveyor_jam_active)

func _on_conveyor_item_delivered(_item_id: int, _destination: Node) -> void:
	_conveyor_delivered_total += 1
	_update_conveyor_statbus()
	_update_conveyor_backlog_signal()

func _update_conveyor_statbus() -> void:
	var bus := _statbus_ref()
	if bus == null:
		return
	bus.set_stat(&"conveyor_rate", _conveyor_rate, "Economy")
	bus.set_stat(&"conveyor_queue", float(_conveyor_queue), "Economy")
	bus.set_stat(&"conveyor_delivered_total", float(_conveyor_delivered_total), "Economy")
	var jam_value := 1.0 if _conveyor_jam_active else 0.0
	bus.set_stat(&"conveyor_jam_active", jam_value, "Economy")

func _update_conveyor_backlog_signal() -> void:
	var tone := StringName("warning") if _conveyor_jam_active else StringName("normal")
	var label := _format_backlog_label(_conveyor_queue, _conveyor_jam_active)
	if _conveyor_queue == _last_conveyor_backlog and label == _last_conveyor_backlog_label and tone == _last_conveyor_backlog_tone:
		return
	_last_conveyor_backlog = _conveyor_queue
	_last_conveyor_backlog_label = label
	_last_conveyor_backlog_tone = tone
	conveyor_backlog_changed.emit(_conveyor_queue, label, tone)

func _format_backlog_label(queue_len: int, jam_active: bool) -> String:
	var label: String = "Queue %d" % queue_len
	if jam_active:
		label += " ⚠"
	return label

func _update_economy_rate_signal(rate: float) -> void:
	var label: String = _format_rate_label(rate)
	if is_equal_approx(rate, _last_economy_rate) and label == _last_economy_rate_label:
		return
	_last_economy_rate = rate
	_last_economy_rate_label = label
	economy_rate_changed.emit(rate, label)

func _format_rate_label(rate: float) -> String:
	var abs_rate: float = abs(rate)
	var decimals := 1
	if abs_rate >= 10.0:
		decimals = 0
	return "%s/s" % String.num(rate, decimals)

func _bind_services() -> void:
	_power_service = _get_power_service()
	_automation_service = _get_automation_service()
	_update_power_service(_environment_power_modifier())
	_refresh_automation_interval()
	_refresh_automation_binding()

func _refresh_automation_binding() -> void:
	var phase_start := Time.get_ticks_usec()
	var service := _get_automation_service()
	if service == null:
		_profiling_accumulate(PROFILING_PHASE_RESEARCH, Time.get_ticks_usec() - phase_start)
		return
	if not service.has_target(_automation_target_id()):
		service.register_autoburst(_automation_target_id(), _automation_interval(), Callable(self, "_handle_autoburst_request"), AutomationService.MODE_MANUAL)
	var mode := AutomationService.MODE_OFF
	if _automation_conditions_met():
		mode = AutomationService.MODE_MANUAL
		if _automation_environment_ok():
			mode = AutomationService.MODE_AUTO
	service.set_mode(_automation_target_id(), mode)
	_profiling_accumulate(PROFILING_PHASE_RESEARCH, Time.get_ticks_usec() - phase_start)

func _refresh_automation_interval() -> void:
	var service := _get_automation_service()
	if service == null:
		return
	if not service.has_target(_automation_target_id()):
		service.register_autoburst(_automation_target_id(), _automation_interval(), Callable(self, "_handle_autoburst_request"), AutomationService.MODE_MANUAL)
	else:
		service.update_interval(_automation_target_id(), _automation_interval())

func _automation_target_id() -> StringName:
	return StringName("economy_feed_autoburst")

func _statbus_ref() -> StatBus:
	if _statbus and is_instance_valid(_statbus):
		return _statbus
	var node := get_node_or_null("/root/StatBusSingleton")
	if node is StatBus:
		_statbus = node as StatBus
		return _statbus
	return null

func _get_automation_service() -> AutomationService:
	if _automation_service and is_instance_valid(_automation_service):
		return _automation_service
	var node := get_node_or_null("/root/AutomationServiceSingleton")
	if node is AutomationService:
		_automation_service = node as AutomationService
		return _automation_service
	return null

func _get_power_service() -> PowerService:
	if _power_service and is_instance_valid(_power_service):
		return _power_service
	var node := get_node_or_null("/root/PowerServiceSingleton")
	if node is PowerService:
		_power_service = node as PowerService
		return _power_service
	return null

func _get_stats_probe() -> StatsProbe:
	var node := get_node_or_null("/root/StatsProbeSingleton")
	if node is StatsProbe:
		return node as StatsProbe
	return null

func _profiling_init() -> void:
	for phase in PROFILING_PHASES:
		_profiling_sections[phase] = 0.0
	_profiling_active = false

func _profiling_reset() -> void:
	for phase in PROFILING_PHASES:
		_profiling_sections[phase] = 0.0
	_profiling_active = true

func _profiling_finish() -> void:
	_profiling_active = false

func _profiling_accumulate(phase: StringName, duration_usec: int) -> void:
	if not _profiling_active:
		return
	var duration_ms: float = float(duration_usec) / 1000.0
	var current := float(_profiling_sections.get(phase, 0.0))
	_profiling_sections[phase] = current + duration_ms

func _queue_shipment_log(context: Dictionary) -> void:
	var entry := context.duplicate(true)
	_pending_shipment_logs.append(entry)

func _refresh_config_flags() -> void:
	var config := get_node_or_null("/root/Config")
	if config:
		_ship_amortization_enabled = bool(config.get("economy_amortize_shipment"))
	else:
		_ship_amortization_enabled = false

func _record_stats_probe(tick_ms: float, pps: float, base_pps: float, feed_fraction: float) -> void:
	if _stats_probe == null or not is_instance_valid(_stats_probe):
		_stats_probe = _get_stats_probe()
	if _stats_probe == null:
		return
	_stats_probe.record_tick({
		"service": "economy",
		"tick_ms": tick_ms,
		"pps": pps,
		"storage": storage,
		"feed_fraction": feed_fraction,
		"conveyor_rate": _conveyor_rate,
		"conveyor_queue": _conveyor_queue,
		"conveyor_jam_active": 1.0 if _conveyor_jam_active else 0.0,
		"conveyor_delivered_total": _conveyor_delivered_total,
		"economy_rate": pps,
		"economy_rate_label": _last_economy_rate_label,
		"conveyor_backlog": float(_conveyor_queue),
		"conveyor_backlog_label": _last_conveyor_backlog_label,
		"eco_in_ms": float(_profiling_sections.get(PROFILING_PHASE_IN, 0.0)),
		"eco_apply_ms": float(_profiling_sections.get(PROFILING_PHASE_APPLY, 0.0)),
		"eco_ship_ms": float(_profiling_sections.get(PROFILING_PHASE_SHIP, 0.0)),
		"eco_research_ms": float(_profiling_sections.get(PROFILING_PHASE_RESEARCH, 0.0)),
		"eco_statbus_ms": float(_profiling_sections.get(PROFILING_PHASE_STATBUS, 0.0)),
		"eco_ui_ms": float(_profiling_sections.get(PROFILING_PHASE_UI, 0.0))
	})

func _log(level: String, category: String, message: String, context: Dictionary = {}) -> void:
	var logger_node := get_node_or_null("/root/Logger")
	if logger_node is YolkLogger:
		(logger_node as YolkLogger).log(level, category, message, context)

func _environment_service() -> EnvironmentService:
	var node := get_node_or_null("/root/EnvironmentServiceSingleton")
	if node is EnvironmentService:
		return node as EnvironmentService
	return null
