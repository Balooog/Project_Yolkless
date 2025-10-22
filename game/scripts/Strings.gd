extends Node
class_name StringsRegistry

signal reloaded

@export var strings_path := "res://game/data/strings_egg.tsv"

var _entries: Dictionary = {}

func _ready() -> void:
	reload()

func reload() -> void:
	_entries.clear()
	var file := FileAccess.open(strings_path, FileAccess.READ)
	if file == null:
		var logger := get_node_or_null("/root/Logger")
		if logger:
			logger.call("record", "WARN", "STRINGS", "Failed to open strings file", {"path": strings_path})
		reloaded.emit()
		return
	while not file.eof_reached():
		var raw := file.get_line()
		if raw.strip_edges() == "" or raw.begins_with("#"):
			continue
		var cols: PackedStringArray = raw.split("\t", false)
		if cols.size() < 2:
			continue
		var key := cols[0]
		var values := cols.duplicate()
		values.remove_at(0)
		var value := values.join("\t")
		_entries[key] = value
	file.close()
	var logger := get_node_or_null("/root/Logger")
	if logger:
		logger.call("record", "INFO", "STRINGS", "Strings reloaded", {
			"count": _entries.size(),
			"md5": logger.call("hash_md5_from_file", strings_path)
		})
	reloaded.emit()

func get_string(key: String, default_value: String = "") -> String:
	return String(_entries.get(key, default_value))

func has_string(key: String) -> bool:
	return _entries.has(key)
*** End of File
