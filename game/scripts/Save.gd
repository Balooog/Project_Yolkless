extends Node
class_name Save

@export var save_path := "user://save.json"

const AutomationService := preload("res://src/services/AutomationService.gd")
const SandboxService := preload("res://src/services/SandboxService.gd")
const StatBus := preload("res://src/services/StatBus.gd")
const StatsProbe := preload("res://src/services/StatsProbe.gd")
const OfflineService := preload("res://src/economy/OfflineService.gd")

var _eco: Economy
var _res: Research
var _automation: AutomationService
var _sandbox: SandboxService
var _statbus: StatBus
var _stats_probe: StatsProbe
const SaveMigrator := preload("res://src/persistence/SaveMigrator.gd")
const CURRENT_VERSION := SaveMigrator.CURRENT_VERSION
var _migrator: SaveMigrator = SaveMigrator.new()
var _offline_service: OfflineService = OfflineService.new()
var _last_snapshot: Dictionary = {}

func setup(
		eco: Economy,
		res: Research,
		automation: AutomationService = null,
		sandbox: SandboxService = null,
		statbus: StatBus = null) -> void:
	_eco = eco
	_res = res
	_automation = automation
	_sandbox = sandbox
	_statbus = statbus
	_stats_probe = _stats_probe_ref()
	_eco.autosave.connect(_on_autosave)
	_res.changed.connect(func(): save("research"))
	_ensure_statbus_registration()

func save(reason: String = "manual") -> void:
	_ensure_statbus_registration()
	var timestamp := Time.get_unix_time_from_system()
	var snapshot := _build_snapshot(timestamp, true)
	var payload_dict := {
		"save_version": CURRENT_VERSION,
		"ts": timestamp,
		"eco": {
			"soft": _eco.soft,
			"storage": _eco.storage,
			"total_earned": _eco.total_earned,
			"capacity_rank": _eco.capacity_rank,
			"prod_rank": _eco.prod_rank,
			"factory_tier": _eco.factory_tier,
			"feed": _eco.feed_current,
		},
		"snapshot": snapshot,
		"upgrades": _eco._upgrade_levels,
		"research": {
			"owned": _res.owned.keys(),
			"pp": _res.prestige_points,
		},
	}
	var payload := JSON.stringify(payload_dict)
	var hash := _hash_md5(payload)
	var wrapper := {"hash": hash, "payload": payload}
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(wrapper))
		file.close()
	_log("INFO", "SAVE", "Save written", {
		"reason": reason,
		"soft": _eco.soft,
		"storage": _eco.storage,
		"prestige": _res.prestige_points,
		"tier": _eco.factory_tier,
		"hash": hash
	})

func load_state() -> void:
	if not FileAccess.file_exists(save_path):
		_log("INFO", "SAVE", "No save file found", {"path": save_path})
		_eco.soft = 0.0
		_eco.storage = 0.0
		return
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		_log("ERROR", "SAVE", "Failed to open save file", {"path": save_path})
		return
	var text := file.get_as_text()
	file.close()
	var wrapper_variant: Variant = JSON.parse_string(text)
	if wrapper_variant == null or typeof(wrapper_variant) != TYPE_DICTIONARY:
		_log("WARN", "SAVE", "Malformed save wrapper", {"path": save_path})
		return
	var wrapper: Dictionary = wrapper_variant
	var payload_variant: Variant = wrapper.get("payload", "")
	var payload := String(payload_variant)
	var expected := String(wrapper.get("hash", ""))
	var actual := _hash_md5(payload)
	if expected != "" and expected != actual:
		_log("WARN", "SAVE", "Checksum mismatch", {"expected": expected, "actual": actual})
		return
	var save_data_variant: Variant = JSON.parse_string(payload)
	if save_data_variant == null or typeof(save_data_variant) != TYPE_DICTIONARY:
		_log("WARN", "SAVE", "Malformed save data", {"path": save_path})
		return
	var save_data: Dictionary = save_data_variant
	if _migrator:
		save_data = _migrator.migrate(save_data)
	_last_snapshot = _extract_snapshot(save_data)
	var eco_variant: Variant = save_data.get("eco", {})
	var eco_data: Dictionary = eco_variant if eco_variant is Dictionary else {}
	_eco.soft = float(eco_data.get("soft", 0.0))
	_eco.storage = float(eco_data.get("storage", 0.0))
	_eco.total_earned = float(eco_data.get("total_earned", 0.0))
	_eco.factory_tier = int(eco_data.get("factory_tier", 1))
	var upgrades_variant: Variant = save_data.get("upgrades", {})
	if upgrades_variant is Dictionary:
		_eco._upgrade_levels = (upgrades_variant as Dictionary).duplicate(true)
	else:
		_eco._upgrade_levels.clear()
	if eco_data.has("feed"):
		_eco.feed_current = float(eco_data.get("feed", _eco.feed_current))
	else:
		_eco.feed_current = _eco.feed_capacity
	_res.owned.clear()
	var research_variant: Variant = save_data.get("research", {})
	var research_data: Dictionary = research_variant if research_variant is Dictionary else {}
	var owned_variant: Variant = research_data.get("owned", [])
	if owned_variant is Array:
		for id_variant in owned_variant:
			var id: String = String(id_variant)
			_res.owned[id] = true
	_res.prestige_points = int(research_data.get("pp", 0))
	_res.reapply_all()
	_eco.refresh_after_load()
	_eco.soft_changed.emit(_eco.soft)
	_eco.tier_changed.emit(_eco.factory_tier)
	_log("INFO", "SAVE", "Save loaded", {
		"soft": _eco.soft,
		"storage": _eco.storage,
		"prestige": _res.prestige_points,
		"tier": _eco.factory_tier,
		"hash": actual
	})

func export_to_clipboard() -> void:
	if not FileAccess.file_exists(save_path):
		_log("WARN", "SAVE", "Cannot export missing save", {"path": save_path})
		return
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		_log("ERROR", "SAVE", "Failed to open save for export", {"path": save_path})
		return
	var text := file.get_as_text()
	file.close()
	DisplayServer.clipboard_set(Marshalls.raw_to_base64(text.to_utf8_buffer()))
	_log("INFO", "SAVE", "Save exported to clipboard", {
		"bytes": text.length(),
		"hash": _hash_md5(text)
	})

func import_from_clipboard() -> void:
	var b64 := DisplayServer.clipboard_get()
	if b64 == "":
		_log("WARN", "SAVE", "Clipboard empty on import")
		return
	var bytes := Marshalls.base64_to_raw(b64)
	var text := bytes.get_string_from_utf8()
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(text)
		file.close()
	_log("INFO", "SAVE", "Save imported from clipboard", {
		"bytes": text.length(),
		"hash": _hash_md5(text)
	})
	load_state()

func apply_offline_rewards() -> Dictionary:
	var summary := {
		"grant": 0.0,
		"elapsed_seconds": 0.0,
		"applied_seconds": 0.0,
		"overflow_seconds": 0.0,
		"passive_multiplier": 0.0,
		"clamped": false,
		"saved_timestamp": 0,
		"current_timestamp": Time.get_unix_time_from_system(),
		"comfort_before": {},
		"comfort_after": {},
		"automation_before": {},
		"automation_after": {},
		"economy_before": {},
		"economy_after": {},
		"soft_delta": 0.0,
		"storage_delta": 0.0
	}
	var before_snapshot := _last_snapshot.duplicate(true)
	var last_timestamp := int(before_snapshot.get("timestamp", 0))
	summary["saved_timestamp"] = last_timestamp
	var now_timestamp := Time.get_unix_time_from_system()
	summary["current_timestamp"] = now_timestamp
	var elapsed := max(now_timestamp - last_timestamp, 0)
	summary["elapsed_seconds"] = float(elapsed)
	summary["comfort_before"] = before_snapshot.get("comfort", {})
	summary["automation_before"] = before_snapshot.get("automation", {})
	summary["economy_before"] = before_snapshot.get("economy", {})
	if last_timestamp <= 0 or elapsed <= 5:
		summary["comfort_after"] = _current_comfort_snapshot()
		summary["automation_after"] = _current_automation_snapshot()
		summary["economy_after"] = _current_economy_snapshot()
		return summary
	var params := {
		"economy": _eco,
		"elapsed_seconds": float(elapsed),
		"base_pps": _eco.current_base_pps()
	}
	var result := _offline_service.apply(params)
	summary["grant"] = float(result.get("grant", 0.0))
	summary["applied_seconds"] = float(result.get("applied_seconds", summary["elapsed_seconds"]))
	summary["overflow_seconds"] = float(result.get("overflow_seconds", 0.0))
	summary["passive_multiplier"] = float(result.get("passive_multiplier", 0.0))
	summary["clamped"] = bool(result.get("clamped", false))
	var after_snapshot := _build_snapshot(now_timestamp, false)
	summary["comfort_after"] = after_snapshot.get("comfort", {})
	summary["automation_after"] = after_snapshot.get("automation", {})
	summary["economy_after"] = after_snapshot.get("economy", {})
	var soft_before := float(summary["economy_before"].get("soft", _eco.soft))
	var storage_before := float(summary["economy_before"].get("storage", _eco.storage))
	var economy_after: Dictionary = summary["economy_after"]
	var soft_after := float(economy_after.get("soft", _eco.soft))
	var storage_after := float(economy_after.get("storage", _eco.storage))
	summary["soft_delta"] = soft_after - soft_before
	summary["storage_delta"] = storage_after - storage_before
	_last_snapshot = after_snapshot.duplicate(true)
	_ensure_statbus_registration()
	if _statbus:
		_statbus.set_stat(&"offline_multiplier", summary["passive_multiplier"], "OfflineService")
	var context := {
		"elapsed": summary["elapsed_seconds"],
		"applied": summary["applied_seconds"],
		"grant": summary["grant"],
		"passive_multiplier": summary["passive_multiplier"],
		"clamped": summary["clamped"],
		"automation_active_after": int(summary["automation_after"].get("active_targets", 0)),
		"automation_global_after": bool(summary["automation_after"].get("global_enabled", true))
	}
	_log("INFO", "OFFLINE", "Offline rewards applied", context)
	var probe := _stats_probe_ref()
	if probe:
		var payload := {
			"service": "offline",
			"tick_ms": 0.0,
			"elapsed": summary["elapsed_seconds"],
			"applied": summary["applied_seconds"],
			"grant": summary["grant"],
			"passive_multiplier": summary["passive_multiplier"],
			"clamped": summary["clamped"] ? 1.0 : 0.0,
			"storage": storage_after,
			"pps": float(economy_after.get("pps", 0.0)),
			"ci": float(summary["comfort_after"].get("ci", 0.0)),
			"ci_delta": float(summary["comfort_after"].get("ci_delta", 0.0)),
			"power_ratio": float(economy_after.get("power_ratio", 0.0))
		}
		probe.record_tick(payload)
	return summary

func _build_snapshot(timestamp: int, update_store: bool) -> Dictionary:
	var snapshot := {
		"timestamp": timestamp,
		"comfort": _current_comfort_snapshot(),
		"automation": _current_automation_snapshot(),
		"economy": _current_economy_snapshot(),
		"stats": _current_stat_snapshot()
	}
	if update_store:
		_last_snapshot = snapshot.duplicate(true)
	return snapshot

func _current_comfort_snapshot() -> Dictionary:
	var sandbox := _sandbox_ref()
	if sandbox:
		var comfort := sandbox.comfort_snapshot()
		return {
			"ci": float(comfort.get("ci_smoothed", comfort.get("ci", sandbox.current_ci()))),
			"ci_bonus": sandbox.current_bonus(),
			"ci_delta": float(comfort.get("ci_delta", 0.0)),
			"active_fraction": float(comfort.get("active_fraction_smoothed", comfort.get("active_fraction", 0.0)))
		}
	var statbus := _statbus_ref()
	var comfort_index := 0.0
	var comfort_bonus := 0.0
	if statbus:
		comfort_index = statbus.get_stat(&"comfort_index", 0.0)
		comfort_bonus = statbus.get_stat(&"ci_bonus", 0.0)
	return {
		"ci": comfort_index,
		"ci_bonus": comfort_bonus,
		"ci_delta": 0.0,
		"active_fraction": 0.0
	}

func _current_automation_snapshot() -> Dictionary:
	var automation := _automation_ref()
	var statbus := _statbus_ref()
	var auto_ready := 0.0
	if statbus:
		auto_ready = statbus.get_stat(&"auto_burst_ready", 0.0)
	var global_enabled := automation.is_global_enabled() if automation else true
	var active_targets := automation.active_auto_count() if automation else 0
	return {
		"global_enabled": global_enabled,
		"active_targets": active_targets,
		"auto_ready": auto_ready
	}

func _current_economy_snapshot() -> Dictionary:
	var statbus := _statbus_ref()
	var power_ratio := 1.0
	if statbus:
		power_ratio = statbus.get_stat(&"power_ratio", power_ratio)
	return {
		"soft": _eco.soft,
		"storage": _eco.storage,
		"pps": _eco.current_pps(),
		"base_pps": _eco.current_base_pps(),
		"feed_fraction": _eco.get_feed_fraction(),
		"power_ratio": power_ratio
	}

func _current_stat_snapshot() -> Dictionary:
	var statbus := _statbus_ref()
	if statbus == null:
		return {}
	return {
		"comfort_index": statbus.get_stat(&"comfort_index", 0.0),
		"ci_bonus": statbus.get_stat(&"ci_bonus", 0.0),
		"auto_burst_ready": statbus.get_stat(&"auto_burst_ready", 0.0),
		"offline_multiplier": statbus.get_stat(&"offline_multiplier", 0.0),
		"power_ratio": statbus.get_stat(&"power_ratio", 1.0)
	}

func _extract_snapshot(save_data: Dictionary) -> Dictionary:
	var snapshot_variant: Variant = save_data.get("snapshot", {})
	var snapshot: Dictionary = {}
	if snapshot_variant is Dictionary:
		snapshot = snapshot_variant.duplicate(true)
	var timestamp := int(save_data.get("ts", 0))
	if not snapshot.has("timestamp"):
		snapshot["timestamp"] = timestamp
	else:
		snapshot["timestamp"] = int(snapshot.get("timestamp", timestamp))
	if not snapshot.has("comfort") or not (snapshot["comfort"] is Dictionary):
		snapshot["comfort"] = {
			"ci": float(save_data.get("ci", 0.0)),
			"ci_bonus": float(save_data.get("ci_bonus", 0.0)),
			"ci_delta": 0.0,
			"active_fraction": 0.0
		}
	if not snapshot.has("automation") or not (snapshot["automation"] is Dictionary):
		snapshot["automation"] = {
			"global_enabled": true,
			"active_targets": 0,
			"auto_ready": 0.0
		}
	else:
		var automation_dict: Dictionary = snapshot["automation"]
		if not automation_dict.has("global_enabled"):
			automation_dict["global_enabled"] = true
		if not automation_dict.has("active_targets"):
			automation_dict["active_targets"] = 0
		if not automation_dict.has("auto_ready"):
			automation_dict["auto_ready"] = 0.0
		snapshot["automation"] = automation_dict
	if not snapshot.has("economy") or not (snapshot["economy"] is Dictionary):
		var eco_variant: Variant = save_data.get("eco", {})
		var eco_data: Dictionary = eco_variant if eco_variant is Dictionary else {}
		snapshot["economy"] = {
			"soft": float(eco_data.get("soft", 0.0)),
			"storage": float(eco_data.get("storage", 0.0)),
			"pps": 0.0,
			"base_pps": 0.0,
			"feed_fraction": 0.0,
			"power_ratio": 1.0
		}
	if not snapshot.has("stats") or not (snapshot["stats"] is Dictionary):
		snapshot["stats"] = {}
	return snapshot

func _automation_ref() -> AutomationService:
	if _automation and is_instance_valid(_automation):
		return _automation
	var node := get_node_or_null("/root/AutomationServiceSingleton")
	if node is AutomationService:
		_automation = node
	return _automation

func _sandbox_ref() -> SandboxService:
	if _sandbox and is_instance_valid(_sandbox):
		return _sandbox
	var node := get_node_or_null("/root/SandboxServiceSingleton")
	if node is SandboxService:
		_sandbox = node
	return _sandbox

func _statbus_ref() -> StatBus:
	if _statbus and is_instance_valid(_statbus):
		return _statbus
	var node := get_node_or_null("/root/StatBusSingleton")
	if node is StatBus:
		_statbus = node
	return _statbus

func _stats_probe_ref() -> StatsProbe:
	if _stats_probe and is_instance_valid(_stats_probe):
		return _stats_probe
	var node := get_node_or_null("/root/StatsProbeSingleton")
	if node is StatsProbe:
		_stats_probe = node
	return _stats_probe

func _ensure_statbus_registration() -> void:
	var statbus := _statbus_ref()
	if statbus:
		statbus.register_stat(&"offline_multiplier", {"stack": "replace", "default": 0.0})

func _on_autosave(reason: String) -> void:
	save(reason)

func _hash_md5(text: String) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_MD5)
	ctx.update(text.to_utf8_buffer())
	return ctx.finish().hex_encode()

func get_current_hash() -> String:
	if not FileAccess.file_exists(save_path):
		return ""
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return _hash_md5(text)

func _log(level: String, category: String, message: String, context: Dictionary = {}) -> void:
	var logger_node := get_node_or_null("/root/Logger")
	if logger_node is YolkLogger:
		(logger_node as YolkLogger).log(level, category, message, context)
