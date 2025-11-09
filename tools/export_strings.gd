extends SceneTree

const DEFAULT_INPUT := "res://game/data/strings_egg.tsv"
const DEFAULT_OUTPUT := "res://i18n/strings.pot"

var _input_path: String = DEFAULT_INPUT
var _output_path: String = DEFAULT_OUTPUT

func _initialize() -> void:
	_parse_args()
	var entries: Array[Dictionary] = _load_string_rows(_input_path)
	if entries.is_empty():
		push_error("String export aborted: no rows loaded from %s" % _input_path)
		quit(1)
		return
	if not _ensure_output_directory(_output_path):
		quit(1)
		return
	if not _write_pot(entries, _output_path):
		quit(1)
		return
	print("Exported %d strings to %s" % [entries.size(), _output_path])
	quit()

func _parse_args() -> void:
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--input="):
			var parts: PackedStringArray = arg.split("=", false, 1)
			if parts.size() > 1:
				_input_path = parts[1]
		elif arg.begins_with("--output="):
			var output_parts: PackedStringArray = arg.split("=", false, 1)
			if output_parts.size() > 1:
				_output_path = output_parts[1]

func _load_string_rows(path: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Unable to open strings TSV: %s" % path)
		return rows
	var line_number: int = 0
	while not file.eof_reached():
		var raw_line: String = file.get_line()
		line_number += 1
		var trimmed_all: String = raw_line.strip_edges()
		if trimmed_all.is_empty():
			continue
		if trimmed_all.begins_with("#"):
			continue
		var columns: PackedStringArray = raw_line.split("\t", false)
		if columns.size() < 2:
			push_warning("Skipping line %d (expected key and value)." % line_number)
			continue
		var key := String(columns[0]).strip_edges()
		if key.is_empty():
			push_warning("Skipping line %d (empty key)." % line_number)
			continue
		var value_builder: String = ""
		for i in range(1, columns.size()):
			if i > 1:
				value_builder += "\t"
			value_builder += columns[i]
		var value: String = value_builder.strip_edges(false, true)
		var entry: Dictionary = {"key": key, "value": value}
		rows.append(entry)
	file.close()
	return rows

func _ensure_output_directory(path: String) -> bool:
	var dir_path: String = path.get_base_dir()
	if dir_path.is_empty():
		return true
	var abs_path: String = ProjectSettings.globalize_path(dir_path)
	if DirAccess.dir_exists_absolute(abs_path):
		return true
	var result: int = DirAccess.make_dir_recursive_absolute(abs_path)
	if result != OK:
		push_error("Failed to create directory %s (err %d)" % [abs_path, result])
		return false
	return true

func _write_pot(entries: Array[Dictionary], output_path: String) -> bool:
	var file: FileAccess = FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open %s for writing." % output_path)
		return false
	_write_header(file)
	for entry in entries:
		var key := String(entry.get("key", ""))
		var value := String(entry.get("value", ""))
		if value.is_empty():
			continue
		file.store_line("#: %s" % key)
		file.store_line('msgctxt "%s"' % _escape_po_string(key))
		file.store_line('msgid "%s"' % _escape_po_string(value))
		file.store_line('msgstr ""')
		file.store_line("")
	file.close()
	return true

func _write_header(file: FileAccess) -> void:
	var timestamp: String = Time.get_datetime_string_from_system(true, true)
	file.store_line('msgid ""')
	file.store_line('msgstr ""')
	file.store_line('"Project-Id-Version: Project Yolkless\\n"')
	file.store_line('"POT-Creation-Date: %s\\n"' % timestamp)
	file.store_line('"Language-Team: \\n"')
	file.store_line('"MIME-Version: 1.0\\n"')
	file.store_line('"Content-Type: text/plain; charset=UTF-8\\n"')
	file.store_line('"Content-Transfer-Encoding: 8bit\\n"')
	file.store_line("")

func _escape_po_string(text: String) -> String:
	var escaped: String = text.replace("\\", "\\\\")
	escaped = escaped.replace("\"", "\\\"")
	escaped = escaped.replace("\n", "\\n")
	escaped = escaped.replace("\t", "\\t")
	return escaped
