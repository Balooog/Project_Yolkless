extends Node
class_name Save

@export var save_path := "user://save.json"

var _eco: Economy
var _res: Research

func setup(eco: Economy, res: Research) -> void:
	_eco = eco
	_res = res
	_eco.autosave.connect(_on_autosave)
	_res.changed.connect(func(): save("research"))

func save(reason: String = "manual") -> void:
	var payload_dict := {
		"ts": Time.get_unix_time_from_system(),
		"eco": {
			"soft": _eco.soft,
			"total_earned": _eco.total_earned,
			"capacity_rank": _eco.capacity_rank,
			"prod_rank": _eco.prod_rank,
			"factory_tier": _eco.factory_tier,
			"feed": _eco.feed_current,
		},
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
		"prestige": _res.prestige_points,
		"tier": _eco.factory_tier,
		"hash": hash
	})

func load_state() -> void:
	if not FileAccess.file_exists(save_path):
		_log("INFO", "SAVE", "No save file found", {"path": save_path})
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
	var eco_variant: Variant = save_data.get("eco", {})
	var eco_data: Dictionary = eco_variant if eco_variant is Dictionary else {}
	_eco.soft = float(eco_data.get("soft", 0.0))
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

func grant_offline() -> float:
	var last_timestamp := 0
	if FileAccess.file_exists(save_path):
		var file := FileAccess.open(save_path, FileAccess.READ)
		if file:
			var text := file.get_as_text()
			file.close()
			var wrapper_variant: Variant = JSON.parse_string(text)
			if wrapper_variant and typeof(wrapper_variant) == TYPE_DICTIONARY:
				var wrapper: Dictionary = wrapper_variant
				var payload_variant: Variant = wrapper.get("payload", "")
				var payload := String(payload_variant)
				var data_variant: Variant = JSON.parse_string(payload)
				if data_variant and typeof(data_variant) == TYPE_DICTIONARY:
					var data_dict: Dictionary = data_variant
					last_timestamp = int(data_dict.get("ts", 0))
	var elapsed := Time.get_unix_time_from_system() - last_timestamp
	if elapsed <= 5:
		return 0.0
	var grant := _eco.offline_grant(elapsed)
	_log("INFO", "OFFLINE", "Offline resume", {
		"elapsed": elapsed,
		"grant": grant
	})
	return grant

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
