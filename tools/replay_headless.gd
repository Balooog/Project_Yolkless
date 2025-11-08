extends SceneTree

const DEFAULT_DURATION := 300.0
const DEFAULT_DT := 0.1
const DEFAULT_STRATEGY := "normal"
const OUTPUT_DIR := "user://logs/telemetry"
const HUD_LABEL_PRINT_INTERVAL := 10.0

const CONFIG_SCRIPT := preload("res://game/scripts/Config.gd")
const LOGGER_SCRIPT := preload("res://game/scripts/Logger.gd")
const BALANCE_SCRIPT := preload("res://game/scripts/Balance.gd")
const RESEARCH_SCRIPT := preload("res://game/scripts/Research.gd")
const ECONOMY_SCRIPT := preload("res://game/scripts/Economy.gd")
const ENVIRONMENT_SERVICE_SCRIPT := preload("res://src/services/EnvironmentService.gd")
const SANDBOX_SERVICE_SCRIPT := preload("res://src/services/SandboxService.gd")
const STATBUS_SCRIPT := preload("res://src/services/StatBus.gd")
const POWER_SERVICE_SCRIPT := preload("res://src/services/PowerService.gd")
const AUTOMATION_SERVICE_SCRIPT := preload("res://src/services/AutomationService.gd")
const STATS_PROBE_SCRIPT := preload("res://src/services/StatsProbe.gd")
const SANDBOX_GRID_SCRIPT := preload("res://src/sandbox/SandboxGrid.gd")

const SANDBOX_CELL_COUNT := SANDBOX_GRID_SCRIPT.WIDTH * SANDBOX_GRID_SCRIPT.HEIGHT

var _duration: float = DEFAULT_DURATION
var _tick_dt: float = DEFAULT_DT
var _strategy: String = DEFAULT_STRATEGY
var _seed: int = 42
var _env_renderer_mode: String = ""
var _economy_amortize_shipment: bool = false

var _logger: YolkLogger
var _environment: EnvironmentService
var _sandbox: SandboxService
var _automation: AutomationService
var _power: PowerService
var _stats_probe: Node

var _shipments: Array[Dictionary] = []
var _samples: Array[Dictionary] = []
var _alerts: Array[Dictionary] = []
var _current_time: float = 0.0
var _hud_economy_rate_label: String = ""
var _hud_conveyor_backlog_label: String = ""
var _next_hud_label_print: float = 0.0

func _initialize() -> void:
	_parse_args()
	await _setup_singletons()
	await process_frame
	_configure_logger()
	var ctx: Dictionary = _create_simulation_context()
	_run_simulation(ctx)
	var summary: Dictionary = _build_summary(ctx)
	_write_summary(summary)
	var stats: Dictionary = summary.get("stats", {})
	if stats.has("economy_tick_ms_p95"):
		var eco_line := "[economy] p95 total=%.3f in=%.3f apply=%.3f ship=%.3f research=%.3f statbus=%.3f ui=%.3f" % [
			float(stats.get("economy_tick_ms_p95", 0.0)),
			float(stats.get("eco_in_ms_p95", 0.0)),
			float(stats.get("eco_apply_ms_p95", 0.0)),
			float(stats.get("eco_ship_ms_p95", 0.0)),
			float(stats.get("eco_research_ms_p95", 0.0)),
			float(stats.get("eco_statbus_ms_p95", 0.0)),
			float(stats.get("eco_ui_ms_p95", 0.0))
		]
		print(eco_line)
	_print_hud_labels_if_needed(true)
	print(JSON.stringify(summary))
	_cleanup_context(ctx)
	if _logger:
		_logger.flush_now()
	if _stats_probe and _stats_probe.has_method("flush_now"):
		_stats_probe.call("flush_now")
	quit()

func _parse_args() -> void:
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--duration="):
			var value: float = float(arg.split("=")[1])
			_duration = max(value, 1.0)
		elif arg.begins_with("--dt="):
			var dt_value: float = float(arg.split("=")[1])
			_tick_dt = clamp(dt_value, 0.01, 1.0)
		elif arg.begins_with("--seed="):
			_seed = int(arg.split("=")[1])
		elif arg.begins_with("--strategy="):
			_strategy = String(arg.split("=")[1]).to_lower()
		elif arg.begins_with("--env_renderer="):
			_env_renderer_mode = String(arg.split("=")[1]).to_lower()
		elif arg.begins_with("--economy_amortize_shipment="):
			_economy_amortize_shipment = _parse_bool(arg.split("=")[1])

func _parse_bool(raw: String) -> bool:
	var lowered := String(raw).strip_edges().to_lower()
	return lowered in ["1", "true", "yes", "on"]

func _setup_singletons() -> void:
	var root := get_root()
	var config_node: Node = _ensure_node(root, "Config", CONFIG_SCRIPT)
	if config_node:
		config_node.set("seed", _seed)
		if _env_renderer_mode != "":
			config_node.set("env_renderer", _env_renderer_mode)
		config_node.set("economy_amortize_shipment", _economy_amortize_shipment)
	_logger = _ensure_node(root, "Logger", LOGGER_SCRIPT) as YolkLogger
	_ensure_node(root, "StatBusSingleton", STATBUS_SCRIPT)
	_environment = _ensure_node(root, "EnvironmentServiceSingleton", ENVIRONMENT_SERVICE_SCRIPT) as EnvironmentService
	if _environment:
		_environment.set_scheduler_enabled(true)
	_sandbox = _ensure_node(root, "SandboxServiceSingleton", SANDBOX_SERVICE_SCRIPT) as SandboxService
	if _sandbox:
		_sandbox.set_scheduler_enabled(true)
		_sandbox.set_random_seed(_seed)
	_power = _ensure_node(root, "PowerServiceSingleton", POWER_SERVICE_SCRIPT) as PowerService
	_automation = _ensure_node(root, "AutomationServiceSingleton", AUTOMATION_SERVICE_SCRIPT) as AutomationService
	if _automation:
		_automation.set_scheduler_enabled(true)
	var stats_probe_node: Node = root.get_node_or_null("StatsProbeSingleton")
	if stats_probe_node == null:
		var probe_instance := STATS_PROBE_SCRIPT.new()
		probe_instance.name = "StatsProbeSingleton"
		root.add_child(probe_instance)
		stats_probe_node = probe_instance
	_stats_probe = stats_probe_node
	if _stats_probe:
		_stats_probe.set_process(true)
		_stats_probe.connect("stats_probe_alert", Callable(self, "_on_stats_probe_alert"))

func _configure_logger() -> void:
	if _logger:
		_logger.setup(true, false)

func _create_simulation_context() -> Dictionary:
	var balance: Balance = BALANCE_SCRIPT.new()
	get_root().add_child(balance)
	balance.load_balance()
	var research: Research = RESEARCH_SCRIPT.new()
	get_root().add_child(research)
	research.setup(balance)
	var economy: Economy = ECONOMY_SCRIPT.new()
	get_root().add_child(economy)
	economy.setup(balance, research)
	economy.soft = 0.0
	economy.storage = 0.0
	economy.dump_triggered.connect(func(amount: float, wallet: float) -> void:
		_shipments.append({
			"time": _current_time,
			"amount": amount,
			"wallet": wallet
		})
	)
	if not economy.economy_rate_changed.is_connected(_on_replay_economy_rate_changed):
		economy.economy_rate_changed.connect(_on_replay_economy_rate_changed)
	if not economy.conveyor_backlog_changed.is_connected(_on_replay_conveyor_backlog_changed):
		economy.conveyor_backlog_changed.connect(_on_replay_conveyor_backlog_changed)
	return {
		"balance": balance,
		"research": research,
		"economy": economy
	}

func _cleanup_context(ctx: Dictionary) -> void:
	for node_variant in ctx.values():
		if node_variant is Node:
			var node: Node = node_variant
			if node.get_parent():
				node.queue_free()

func _run_simulation(ctx: Dictionary) -> void:
	var economy: Economy = ctx["economy"]
	var duration_remaining: float = _duration
	var sample_timer: float = 0.0
	var last_ci: float = _sandbox.current_ci() if _sandbox else 0.0
	_current_time = 0.0
	while duration_remaining > 0.0:
		var step_dt: float = min(_tick_dt, duration_remaining)
		var should_feed: bool = _should_feed(_current_time)
		if should_feed and not economy.is_feeding():
			economy.try_burst(false)
		elif not should_feed and economy.is_feeding():
			economy.stop_burst("replay")
		var tick_start := Time.get_ticks_usec()
		if _environment:
			_environment.step(step_dt)
		if _sandbox:
			_sandbox.step(step_dt)
		if _automation:
			_automation.step(step_dt)
		economy.simulate_tick(step_dt)
		var tick_end := Time.get_ticks_usec()
		var tick_ms: float = float(tick_end - tick_start) / 1000.0
		var ci: float = _sandbox.current_ci() if _sandbox else 0.0
		var ci_delta: float = ci - last_ci
		last_ci = ci
		var active_cells: float = 0.0
		if _sandbox:
			var metrics: Dictionary = _sandbox.latest_metrics()
			active_cells = float(metrics.get("active_fraction", 0.0)) * SANDBOX_CELL_COUNT
			ci_delta = float(metrics.get("ci_delta", ci_delta))
		var pps: float = economy.current_pps()
		var power_ratio: float = _power.current_state() if _power else 1.0
		if _stats_probe:
			_stats_probe.call("process", step_dt)
		sample_timer += step_dt
		_current_time += step_dt
		duration_remaining -= step_dt
		if sample_timer >= 1.0:
			sample_timer -= 1.0
			_samples.append({
				"time": _current_time,
				"ci": ci,
				"ci_bonus": _sandbox.current_bonus() if _sandbox else 0.0,
				"ci_delta": ci_delta,
				"pps": pps,
				"storage": economy.current_storage(),
				"wallet": economy.soft,
				"active_cells": active_cells,
				"power_ratio": power_ratio
			})

func _build_summary(ctx: Dictionary) -> Dictionary:
	var economy: Economy = ctx["economy"]
	var stats: Dictionary = {}
	if _stats_probe and _stats_probe.has_method("summarize"):
		stats = _stats_probe.call("summarize")
	return {
		"timestamp": Time.get_datetime_string_from_system(true, true),
		"seed": _seed,
		"strategy": _strategy,
		"duration": _duration,
		"dt": _tick_dt,
		"preset": String(_environment.get_preset()) if _environment else "",
		"shipments": _shipments,
		"samples": _samples,
		"stats": stats,
		"alerts": _alerts,
		"final": {
			"ci": _sandbox.current_ci() if _sandbox else 0.0,
			"ci_bonus": _sandbox.current_bonus() if _sandbox else 0.0,
			"pps": economy.current_pps(),
			"wallet": economy.soft,
			"storage": economy.current_storage()
		}
	}

func _write_summary(summary: Dictionary) -> void:
	if not DirAccess.dir_exists_absolute(OUTPUT_DIR):
		DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
	var stamp: String = Time.get_datetime_string_from_system(true, true).replace(":", "").replace(" ", "_")
	var path := "%s/replay_%s.json" % [OUTPUT_DIR, stamp]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(summary, "\t"))
		file.close()

func _should_feed(time_value: float) -> bool:
	match _strategy:
		"idle":
			return false
		"burst":
			return true
		"pulse":
			return fmod(time_value, 8.0) < 1.5
		_:
			return fmod(time_value, 12.0) < 2.0

func _ensure_node(root: Node, name: String, script: GDScript) -> Node:
	var node := root.get_node_or_null(name)
	if node:
		return node
	var instance: Node = script.new()
	instance.name = name
	root.add_child(instance)
	return instance

func _on_stats_probe_alert(metric: StringName, value: float, threshold: float) -> void:
	_alerts.append({
		"time": _current_time,
		"metric": String(metric),
		"value": value,
		"threshold": threshold
	})

func _on_replay_economy_rate_changed(_rate: float, label: String) -> void:
	_hud_economy_rate_label = label
	_print_hud_labels_if_needed()

func _on_replay_conveyor_backlog_changed(_queue_len: int, label: String, _tone: StringName) -> void:
	_hud_conveyor_backlog_label = label
	_print_hud_labels_if_needed()

func _print_hud_labels_if_needed(force: bool = false) -> void:
	if not force and _current_time < _next_hud_label_print:
		return
	if _hud_economy_rate_label == "" and _hud_conveyor_backlog_label == "":
		return
	print("[hud] economy_rate=%s | conveyor_backlog=%s" % [
		_hud_economy_rate_label,
		_hud_conveyor_backlog_label
	])
	_next_hud_label_print = _current_time + HUD_LABEL_PRINT_INTERVAL
