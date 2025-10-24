extends Node

const TICK_INTERVAL := 0.1
const MAX_CATCHUP := 0.3

const EnvironmentService := preload("res://src/services/EnvironmentService.gd")
const SandboxService := preload("res://src/services/SandboxService.gd")
const Economy := preload("res://game/scripts/Economy.gd")
const AutomationService := preload("res://src/services/AutomationService.gd")
const PowerService := preload("res://src/services/PowerService.gd")

# NOTE: Placeholder scheduler keeping Environment → Sandbox → Economy order.
# PowerService and AutomationService integration currently handled inside Economy; update once dedicated ticks are available.

var _accumulator: float = 0.0
var _environment: EnvironmentService
var _sandbox: SandboxService
var _economy: Economy
var _automation: AutomationService
var _power: PowerService

func _ready() -> void:
	set_process(true)
	_ensure_references()

func _process(delta: float) -> void:
	_ensure_references()
	_accumulator += delta
	if _accumulator > MAX_CATCHUP:
		_accumulator = MAX_CATCHUP
	while _accumulator >= TICK_INTERVAL:
		_accumulator -= TICK_INTERVAL
		_step(TICK_INTERVAL)

func _step(dt: float) -> void:
	if _environment:
		_environment.step(dt)
	if _sandbox:
		_sandbox.step(dt)
	if _automation:
		_automation.step(dt)
	if _economy:
		_economy.simulate_tick(dt)

func _ensure_references() -> void:
	if _environment == null or not is_instance_valid(_environment):
		var env_node := get_node_or_null("/root/EnvironmentServiceSingleton")
		if env_node is EnvironmentService:
			_environment = env_node as EnvironmentService
	if _environment:
		_environment.set_scheduler_enabled(true)
	if _sandbox == null or not is_instance_valid(_sandbox):
		var sandbox_node := get_node_or_null("/root/SandboxServiceSingleton")
		if sandbox_node is SandboxService:
			_sandbox = sandbox_node as SandboxService
	if _sandbox:
		_sandbox.set_scheduler_enabled(true)
	if _automation == null or not is_instance_valid(_automation):
		var automation_node := get_node_or_null("/root/AutomationServiceSingleton")
		if automation_node is AutomationService:
			_automation = automation_node as AutomationService
	if _automation:
		_automation.set_scheduler_enabled(true)
	if _power == null or not is_instance_valid(_power):
		var power_node := get_node_or_null("/root/PowerServiceSingleton")
		if power_node is PowerService:
			_power = power_node as PowerService
	if _economy == null or not is_instance_valid(_economy):
		var main := get_tree().get_root().get_node_or_null("Main")
		if main:
			var eco_node := main.get_node_or_null("Economy")
			if eco_node is Economy:
				_economy = eco_node
	if _economy:
		_economy.set_scheduler_enabled(true)
