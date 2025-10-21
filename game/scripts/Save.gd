extends Node
class_name Save

@export var save_path := "user://save.json"

var _eco: Economy
var _res: Research

func setup(eco: Economy, res: Research) -> void:
	_eco = eco
	_res = res
	_eco.autosave.connect(save)
	_res.changed.connect(save)

func save() -> void:
	var data := {
		"ts": Time.get_unix_time_from_system(),
		"eco": {
			"soft": _eco.soft,
			"total_earned": _eco.total_earned,
			"capacity_rank": _eco.capacity_rank,
			"prod_rank": _eco.prod_rank,
			"factory_tier": _eco.factory_tier,
		},
		"upgrades": _eco._upgrade_levels,
		"research": {
			"owned": _res.owned.keys(),
			"pp": _res.prestige_points,
		},
	}
	var s := JSON.stringify(data)
	var hash := Crypto.hash(Crypto.HASH_MD5, s.to_utf8_buffer()).hex_encode()
	var wrapper := {"hash": hash, "payload": s}
	var ok := FileAccess.open(save_path, FileAccess.WRITE)
	if ok:
		ok.store_string(JSON.stringify(wrapper))
		ok.close()

func load() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var f := FileAccess.open(save_path, FileAccess.READ)
	if f == null:
		return
	var text := f.get_as_text()
	f.close()
	var wrapper := JSON.parse_string(text)
	if wrapper == null:
		return
	var s: String = wrapper.get("payload", "")
	var expect := wrapper.get("hash", "")
	var got := Crypto.hash(Crypto.HASH_MD5, s.to_utf8_buffer()).hex_encode()
	if got != expect:
		push_warning("Save: hash mismatch; ignoring.")
		return
	var data := JSON.parse_string(s)
	if data == null:
		return
	var eco_data := data.get("eco", {})
	_eco.soft = float(eco_data.get("soft", 0.0))
	_eco.total_earned = float(eco_data.get("total_earned", 0.0))
	_eco.factory_tier = int(eco_data.get("factory_tier", 1))
	var upgrades := data.get("upgrades", {})
	if typeof(upgrades) == TYPE_DICTIONARY:
		_eco._upgrade_levels = upgrades.duplicate()
	_res.owned.clear()
	var research_data := data.get("research", {})
	var owned := research_data.get("owned", [])
	if typeof(owned) == TYPE_ARRAY:
		for id in owned:
			_res.owned[id] = true
	_res.prestige_points = int(research_data.get("pp", 0))
	_res.reapply_all()
	_eco.refresh_after_load()
	_eco.soft_changed.emit(_eco.soft)
	_eco.tier_changed.emit(_eco.factory_tier)

func export_to_clipboard() -> void:
	var f := FileAccess.open(save_path, FileAccess.READ)
	if f == null:
		return
	var text := f.get_as_text()
	DisplayServer.clipboard_set(Marshalls.raw_to_base64(text.to_utf8_buffer()))

func import_from_clipboard() -> void:
	var b64 := DisplayServer.clipboard_get()
	if b64 == "":
		return
	var bytes := Marshalls.base64_to_raw(b64)
	var text := bytes.get_string_from_utf8()
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f:
		f.store_string(text)
		f.close()
	load()

func grant_offline() -> float:
	var last := 0
	if FileAccess.file_exists(save_path):
		var f := FileAccess.open(save_path, FileAccess.READ)
		if f:
			var text := f.get_as_text()
			f.close()
			var wrapper := JSON.parse_string(text)
			if wrapper:
				var data := JSON.parse_string(wrapper.get("payload", ""))
				if data:
					last = int(data.get("ts", 0))
	var dt := Time.get_unix_time_from_system() - last
	if dt > 5:
		var gain := _eco.offline_grant(dt)
		print("Offline Egg Credits granted:", gain)
		return gain
	return 0.0
