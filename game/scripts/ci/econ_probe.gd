extends SceneTree

const DEFAULT_SECONDS := 300.0
const TICK_DT := 0.05

var _logger: YolkLogger
var _next_tick_time := 0.0

func _initialize() -> void:
	_logger = get_root().get_node_or_null("/root/Logger") as YolkLogger
	_configure_seed_and_logging()
	var seconds := _parse_seconds()
	var scenarios := [
		{"id": "idle", "name": "Idle", "callable": Callable(self, "_strategy_idle")},
		{"id": "pulse_2_12", "name": "Pulse 2s / 12s", "callable": Callable(self, "_strategy_pulse_2_12")},
		{"id": "pulse_1_8", "name": "Pulse 1s / 8s", "callable": Callable(self, "_strategy_pulse_1_8")},
	]
	var summaries: Array[Dictionary] = []
	for scenario in scenarios:
		var summary := _run_scenario(scenario.get("name", "Scenario"), seconds, scenario.get("callable"))
		if not summary.is_empty():
			summary["id"] = scenario.get("id", "unknown")
			summaries.append(summary)
			_log_summary(summary)
	for summary in summaries:
		print(JSON.stringify(summary))
	if _logger:
		_logger.flush_now()
	quit()

func _configure_seed_and_logging() -> void:
	var config_node := get_root().get_node_or_null("/root/Config")
	if config_node:
		config_node.set("seed", 12345)
	if _logger:
		var enabled: bool = true
		var force_disable: bool = false
		if config_node and config_node.has_method("get"):
			enabled = config_node.get("logging_enabled", true)
			force_disable = config_node.get("logging_force_disable", false)
		_logger.setup(enabled, force_disable)
		_logger.log("INFO", "ECON_PROBE", "logger_ready", {
			"seed": config_node.get("seed") if config_node else 0,
			"enabled": enabled
		})

func _parse_seconds() -> float:
	var seconds := DEFAULT_SECONDS
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--seconds="):
			var parts := arg.split("=")
			if parts.size() >= 2:
				var value := float(parts[1])
				if value > 0.0:
					seconds = value
	return seconds

func _run_scenario(name: String, seconds: float, strategy: Callable) -> Dictionary:
	if not strategy.is_valid():
		return {}
	var ctx := _create_economy_context()
	var balance: Balance = ctx["balance"]
	var research: Research = ctx["research"]
	var economy: Economy = ctx["economy"]
	var dumps: Array[Dictionary] = []
	_next_tick_time = 0.0
	economy.dump_triggered.connect(func(amount: float, wallet: float) -> void:
		dumps.append({
			"time": _next_tick_time,
			"amount": amount,
			"wallet": wallet
		})
		if _logger:
			_logger.log("INFO", "ECON_PROBE", "dump", {
				"scenario": name,
				"time": _next_tick_time,
				"amount": amount,
				"wallet": wallet
			})
	)
	var total_time := 0.0
	var tick_count := 0
	while total_time < seconds:
		var tick := min(TICK_DT, seconds - total_time)
		var should_feed: bool = strategy.call([total_time, economy])
		if should_feed and not economy.is_feeding():
			economy.try_burst(false)
		elif not should_feed and economy.is_feeding():
			economy.stop_burst("probe")
		_next_tick_time = total_time + tick
		economy.simulate_tick(tick)
		total_time = _next_tick_time
		tick_count += 1
	var summary := {
		"scenario": name,
		"seconds": seconds,
		"ticks": tick_count,
		"avg_pps": economy.get_total_earned() / max(seconds, 0.001),
		"wallet": economy.soft,
		"storage": economy.current_storage(),
		"dumps": dumps,
		"dump_count": dumps.size(),
		"first_dump_s": dumps[0].get("time", 0.0) if dumps.size() > 0 else -1.0,
		"constants": {
			"P0": balance.constants.get("P0", 0.0),
			"BURST_MULT": balance.constants.get("BURST_MULT", 0.0),
			"FEED_SUPPLY_MAX": balance.constants.get("FEED_SUPPLY_MAX", 0.0),
			"FEED_SUPPLY_DRAIN_RATE": balance.constants.get("FEED_SUPPLY_DRAIN_RATE", 0.0),
			"FEED_SUPPLY_REFILL_RATE": balance.constants.get("FEED_SUPPLY_REFILL_RATE", 0.0),
			"CAPACITY_BASE": balance.constants.get("CAPACITY_BASE", 0.0),
		}
	}
	_cleanup_context(ctx)
	return summary

func _create_economy_context() -> Dictionary:
	var balance := Balance.new()
	get_root().add_child(balance)
	balance.load_balance()
	var research := Research.new()
	get_root().add_child(research)
	research.setup(balance)
	var economy := Economy.new()
	get_root().add_child(economy)
	economy.setup(balance, research)
	economy.soft = 0.0
	economy.storage = 0.0
	return {
		"balance": balance,
		"research": research,
		"economy": economy
	}

func _cleanup_context(ctx: Dictionary) -> void:
	for key in ctx.keys():
		var node := ctx[key]
		if node is Node:
			(node as Node).queue_free()

func _log_summary(summary: Dictionary) -> void:
	if _logger == null:
		return
	var summary_copy := summary.duplicate(true)
	# Low volume summary log
	_logger.log("INFO", "ECON_PROBE", "summary", summary_copy)

func _strategy_idle(_time: float, _economy: Economy) -> bool:
	return false

func _strategy_pulse_2_12(time: float, economy: Economy) -> bool:
	return fmod(time, 12.0) < 2.0 and economy.feed_current > 0.0

func _strategy_pulse_1_8(time: float, economy: Economy) -> bool:
	return fmod(time, 8.0) < 1.0 and economy.feed_current > 0.0
