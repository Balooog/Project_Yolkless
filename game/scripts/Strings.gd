extends Node
class_name StringsCatalog

var _entries: Dictionary = {}

func load(path: String) -> void:
	_entries.clear()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return
	while not file.eof_reached():
		var line := file.get_line()
		if line.strip_edges() == "" or line.begins_with("#"):
			continue
		var cols := line.split("\t", false)
		if cols.size() < 2:
			continue
		var key := cols[0]
		var value := ""
		for i in range(1, cols.size()):
			if i > 1:
				value += "\t"
			value += cols[i]
		_entries[key] = value
	file.close()

func get_text(key: String, fallback: String = "") -> String:
	var default_value := fallback if fallback != "" else key
	return String(_entries.get(key, default_value))

func has_key(key: String) -> bool:
	return _entries.has(key)

