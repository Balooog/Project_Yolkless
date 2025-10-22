extends Node
class_name LoggingService

const LOG_DIR := "user://logs"
const LOG_BASENAME := "yolkless.log"
const MAX_SIZE_BYTES := 1024 * 1024
const MAX_ROTATIONS := 3
const MAX_BUFFER_LINES := 200

var _file: FileAccess
var _recent_lines: Array[String] = []
var _redactors: Array[RegEx] = []

func _ready() -> void:
	_init_redactors()
	_prepare_directory()
	_rotate_logs_if_needed()
	_open_log()
	_write_header()

func record(level: String, category: String, message: String, context: Dictionary = {}) -> void:
	var timestamp := Time.get_datetime_string_from_system(true, true)
	var context_str := _format_context(context)
	var line := "%s %s [%s] %s%s" % [timestamp, level, category, _sanitize(message), context_str]
	_write_line(line)
	_push_recent(line)

func get_recent_lines(count: int = 200) -> Array[String]:
	var start := max(_recent_lines.size() - count, 0)
	return _recent_lines.slice(start, _recent_lines.size())

func hash_md5_from_file(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_MD5)
	while not file.eof_reached():
		var chunk := file.get_buffer(4096)
		if chunk.size() > 0:
			ctx.update(chunk)
	file.close()
	return ctx.finish().hex_encode()

func sanitize(text: String) -> String:
	return _sanitize(text)

func _init_redactors() -> void:
	var url := RegEx.new()
	url.compile("https?://\\S+")
	var email := RegEx.new()
	email.compile("[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}")
	var token := RegEx.new()
	token.compile("[A-Za-z0-9]{24,}")
	_redactors = [url, email, token]

func _prepare_directory() -> void:
	if not DirAccess.dir_exists_absolute(LOG_DIR):
		DirAccess.make_dir_recursive_absolute(LOG_DIR)

func _rotate_logs_if_needed() -> void:
	var log_path := LOG_DIR + "/" + LOG_BASENAME
	if not FileAccess.file_exists(log_path):
		return
	var size := FileAccess.get_file_len(log_path)
	if size < MAX_SIZE_BYTES:
		return
	for i in range(MAX_ROTATIONS, 0, -1):
		var src := log_path
		if i > 1:
			src = "%s.%d" % [log_path, i - 1]
		var dst := "%s.%d" % [log_path, i]
		if FileAccess.file_exists(dst):
			DirAccess.remove_absolute(dst)
		if FileAccess.file_exists(src):
			DirAccess.rename_absolute(src, dst)

func _open_log() -> void:
	var path := LOG_DIR + "/" + LOG_BASENAME
	_file = FileAccess.open(path, FileAccess.WRITE_READ)
	if _file == null:
		printerr("Logger: failed to open log file", path)
		return
	_file.seek_end()

func _write_header() -> void:
	var version := Engine.get_version_info()
	var app_version := ProjectSettings.get_setting("application/config/version", "dev")
	var timestamp := Time.get_datetime_string_from_system(true, true)
	var header := "# Yolkless %s | Godot %s.%s.%s | %s" % [
		String(app_version),
		String(version.get("major", 0)),
		String(version.get("minor", 0)),
		String(version.get("patch", 0)),
		timestamp
	]
	_write_line(header)
	_push_recent(header)

func _write_line(line: String) -> void:
	if _file == null:
		return
	_file.store_line(line)
	_file.flush()
	print(line)

func _push_recent(line: String) -> void:
	_recent_lines.append(line)
	if _recent_lines.size() > MAX_BUFFER_LINES:
		_recent_lines = _recent_lines.slice(_recent_lines.size() - MAX_BUFFER_LINES, _recent_lines.size())

func _format_context(context: Dictionary) -> String:
	if context.is_empty():
		return ""
	var parts: Array[String] = []
	for key in context.keys():
		var value := context[key]
		parts.append("%s=%s" % [String(key), _sanitize(String(value))])
	return " " + "; ".join(parts)

func _sanitize(text: String) -> String:
	var result := text
	for regex in _redactors:
		var replacement := "[REDACTED]"
		result = regex.sub(result, replacement, true)
	return result
*** End of File
