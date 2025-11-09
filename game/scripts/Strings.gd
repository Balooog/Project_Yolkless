extends Node
class_name StringsCatalog

const PSEUDO_PREFIX := "⟦"
const PSEUDO_SUFFIX := "⟧"
const PSEUDO_PADDING_CHAR := "ː"
const PSEUDO_EXPANSION_RATIO := 0.3
const PSEUDO_ACCENT_MAP := {
	"a": "á",
	"b": "ƀ",
	"c": "ç",
	"d": "đ",
	"e": "ē",
	"f": "ƒ",
	"g": "ğ",
	"h": "ĥ",
	"i": "ī",
	"j": "ĵ",
	"k": "ķ",
	"l": "ĺ",
	"m": "ɱ",
	"n": "ñ",
	"o": "ō",
	"p": "ƥ",
	"q": "ʠ",
	"r": "ř",
	"s": "ş",
	"t": "ŧ",
	"u": "ū",
	"v": "ṽ",
	"w": "ŵ",
	"x": "ẋ",
	"y": "ý",
	"z": "ž",
	"A": "Â",
	"B": "Ḃ",
	"C": "Č",
	"D": "Ď",
	"E": "Ê",
	"F": "Ḟ",
	"G": "Ģ",
	"H": "Ĥ",
	"I": "Į",
	"J": "Ĵ",
	"K": "Ḱ",
	"L": "Ľ",
	"M": "Ḿ",
	"N": "Ñ",
	"O": "Ő",
	"P": "Ṗ",
	"Q": "Ꝗ",
	"R": "Ŕ",
	"S": "Š",
	"T": "Ť",
	"U": "Ū",
	"V": "Ṽ",
	"W": "Ŵ",
	"X": "Ẋ",
	"Y": "Ÿ",
	"Z": "Ẕ",
	"0": "⓪",
	"1": "１",
	"2": "２",
	"3": "３",
	"4": "４",
	"5": "５",
	"6": "６",
	"7": "７",
	"8": "８",
	"9": "９"
}

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
	var resolved := String(_entries.get(key, default_value))
	if _should_pseudo_localize():
		return _pseudo_transform(resolved)
	return resolved

func has_key(key: String) -> bool:
	return _entries.has(key)

func _should_pseudo_localize() -> bool:
	if OS.has_environment("PSEUDO_LOC"):
		var env_value: String = OS.get_environment("PSEUDO_LOC").strip_edges().to_lower()
		if env_value != "":
			return env_value in ["1", "true", "yes", "on"]
	var config := get_node_or_null("/root/Config")
	if config and config.has_method("is_pseudo_localization_enabled"):
		var enabled_variant: Variant = config.call("is_pseudo_localization_enabled")
		return bool(enabled_variant)
	return false

func _pseudo_transform(text: String) -> String:
	if text.is_empty():
		return text
	var accented: String = _pseudo_apply_accents(text)
	var padding_len: int = max(3, int(ceil(float(accented.length()) * PSEUDO_EXPANSION_RATIO)))
	var padding: String = ""
	for _i in range(padding_len):
		padding += PSEUDO_PADDING_CHAR
	return "%s%s%s%s" % [PSEUDO_PREFIX, accented, PSEUDO_SUFFIX, padding]

func _pseudo_apply_accents(text: String) -> String:
	var builder: String = ""
	var i: int = 0
	while i < text.length():
		var current: String = text.substr(i, 1)
		if current == "{":
			var closing: int = text.find("}", i + 1)
			if closing == -1:
				builder += current
				i += 1
				continue
			builder += text.substr(i, closing - i + 1)
			i = closing + 1
			continue
		builder += PSEUDO_ACCENT_MAP.get(current, current)
		i += 1
	return builder
