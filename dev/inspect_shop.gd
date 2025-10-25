extends SceneTree

const CONFIG_SCRIPT := preload("res://game/scripts/Config.gd")
const LOGGER_SCRIPT := preload("res://game/scripts/Logger.gd")
const ENV_SERVICE_SCRIPT := preload("res://src/services/EnvironmentService.gd")
const BALANCE_SCRIPT := preload("res://game/scripts/Balance.gd")
const RESEARCH_SCRIPT := preload("res://game/scripts/Research.gd")
const ECONOMY_SCRIPT := preload("res://game/scripts/Economy.gd")
const SHOP_SERVICE_SCRIPT := preload("res://src/shop/ShopService.gd")
const SHOP_DEBUG_SCRIPT := preload("res://src/shop/ShopDebug.gd")

func _initialize() -> void:
	var root := get_root()
	var config := CONFIG_SCRIPT.new()
	config.name = "Config"
	root.add_child(config)
	var logger := LOGGER_SCRIPT.new()
	logger.name = "Logger"
	root.add_child(logger)
	var env_service := ENV_SERVICE_SCRIPT.new()
	env_service.name = "EnvironmentServiceSingleton"
	root.add_child(env_service)
	await process_frame
	config.seed = 12345
	var balance := BALANCE_SCRIPT.new()
	root.add_child(balance)
	balance.load_balance()
	var research := RESEARCH_SCRIPT.new()
	root.add_child(research)
	research.setup(balance)
	var economy := ECONOMY_SCRIPT.new()
	root.add_child(economy)
	economy.setup(balance, research)
	var shop := SHOP_SERVICE_SCRIPT.new()
	root.add_child(shop)
	shop.setup(balance, economy)
	var shop_debug := SHOP_DEBUG_SCRIPT.new()
	root.add_child(shop_debug)
	shop_debug.setup(shop, economy)
	_print_state(shop, economy, "t0")
	economy.soft = 60.0
	_print_state(shop, economy, "soft=60")
	economy.soft = 140.0
	_print_state(shop, economy, "soft=140")
	quit()

func _print_state(shop: ShopService, economy: Economy, label: String) -> void:
	print("--", label, "credits=", economy.soft)
	for id in shop.list_all_items():
		var state := shop.get_item_state(id)
		if not bool(state.get("visible", true)):
			continue
		print("  ", id, " price=", state.get("price"), " enabled=", state.get("enabled"), " reasons=", state.get("reasons"))
