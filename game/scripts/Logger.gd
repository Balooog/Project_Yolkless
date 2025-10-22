extends Node
class_name YolkLogger

const LOG_DIR := "user://logs"
const LOG_FILE := "yolkless.log"
const ROTATED_COUNT := 3
const MAX_FILE_SIZE := 1024 * 1024
const FLUSH_INTERVAL := 0.5
const MAX_QUEUE := 5000

var _enabled: bool = false
var _queue: Array[String] = []
var _recent_lines: Array[String] = []
var _timer: Timer
var _header_written := false
var _force_disabled := false
var _disabled_due_to_error := false
var _error_reported := false
var _session_seed := 0
var _header_context := ""
var _email_regex: RegEx
var _url_regex: RegEx
var _token_regex: RegEx

func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = FLUSH_INTERVAL
	_timer.one_shot = false
	_timer.timeout.connect(_flush)
	add_child(_timer)
	_prepare_directory()
	_init_sanitize_regex()

func setup(enabled: bool, force_disable: bool = false) -> void:
	_force_disabled = force_disable
	if _force_disabled:
		_enabled = false
	else:
		_enabled = enabled
	_disabled_due_to_error = false
	_error_reported = false
	_queue.clear()
	_header_written = false
	if _enabled:
		_timer.start()
		_session_seed = _resolve_active_seed()
		_build_header_context()
		_write_header_if_needed()
	else:
		_timer.stop()

func _record_entry(level: String, category: String, message: String, context: Dictionary = {}) -> void:
	if not _enabled or _force_disabled or _disabled_due_to_error:
		return
	var timestamp := Time.get_datetime_string_from_system(true, true)
	var context_suffix := ""
	if not context.is_empty():
		var parts: Array[String] = []
		for key in context.keys():
			parts.append("%s=%s" % [str(key), str(context[key])])
		context_suffix = " " + "; ".join(parts)
	var line := "%s %s [%s] %s%s" % [timestamp, level, category, message, context_suffix]
	_queue.append(line)
	if _queue.size() > MAX_QUEUE:
		_queue.pop_front()

func log(level: String, category: String, message: String, context: Dictionary = {}) -> void:
	_record_entry(level, category, message, context)

func record(level: String, category: String, message: String, context: Dictionary = {}) -> void:
	_record_entry(level, category, message, context)

func flush_now() -> void:
	_flush()

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

func get_recent_lines(count: int = 200) -> Array[String]:
	var start: int = max(_recent_lines.size() - count, 0)
	return _recent_lines.slice(start, _recent_lines.size())

func sanitize(text: String) -> String:
	var sanitized := text
	if _email_regex:
		sanitized = _email_regex.sub(sanitized, "<email>", true)
	if _url_regex:
		sanitized = _url_regex.sub(sanitized, "<url>", true)
	if _token_regex:
		sanitized = _token_regex.sub(sanitized, "<token>", true)
	return sanitized

func is_logging_enabled() -> bool:
	return _enabled and not _force_disabled and not _disabled_due_to_error

func get_log_stats() -> Dictionary:
	var stats: Dictionary = {
		"path": LOG_DIR + "/" + LOG_FILE,
		"size": 0,
		"rotation_index": 0,
		"enabled": is_logging_enabled()
	}
	var active_path: String = str(stats["path"])
	if FileAccess.file_exists(active_path):
		var size_file := FileAccess.open(active_path, FileAccess.READ)
		if size_file:
			stats["size"] = size_file.get_length()
			size_file.close()
	var dir := DirAccess.open(LOG_DIR)
	if dir:
		for i in range(1, ROTATED_COUNT + 1):
			if dir.file_exists("%s.%d" % [LOG_FILE, i]):
				stats["rotation_index"] = i
	return stats

func _flush() -> void:
	if not _enabled or _force_disabled or _disabled_due_to_error:
		_queue.clear()
		return
	if _queue.is_empty():
		return
	var rotate_err := _rotate_if_needed()
	if rotate_err != OK:
		_handle_flush_failure("rotation failed (%d)" % rotate_err)
		return
	_write_header_if_needed()
	var path := LOG_DIR + "/" + LOG_FILE
	var file := FileAccess.open(path, FileAccess.WRITE_READ)
	if file == null:
		_handle_flush_failure("open failed: %s" % path)
		return
	file.seek_end()
	for line in _queue:
		file.store_line(line)
		if file.get_error() != OK:
			file.close()
			_handle_flush_failure("write failed")
			return
		_push_recent(line)
	file.flush()
	if file.get_error() != OK:
		var flush_error := file.get_error()
		file.close()
		_handle_flush_failure("flush failed (%d)" % flush_error)
		return
	file.close()
	_queue.clear()

func _prepare_directory() -> void:
	if not DirAccess.dir_exists_absolute(LOG_DIR):
		DirAccess.make_dir_recursive_absolute(LOG_DIR)

func _rotate_if_needed() -> int:
	var path := LOG_DIR + "/" + LOG_FILE
	if not FileAccess.file_exists(path):
		return OK
	var size := 0
	var file := FileAccess.open(path, FileAccess.READ)
	if file:
		size = file.get_length()
		file.close()
	else:
		return ERR_CANT_OPEN
	if size < MAX_FILE_SIZE:
		return OK
	var rotated := false
	for i in range(ROTATED_COUNT, 0, -1):
		var src := path if i == 1 else "%s.%d" % [path, i - 1]
		var dst := "%s.%d" % [path, i]
		if FileAccess.file_exists(dst):
			DirAccess.remove_absolute(dst)
		if FileAccess.file_exists(src):
			DirAccess.rename_absolute(src, dst)
			rotated = true
	if rotated:
		_header_written = false
	return OK

func _write_header_if_needed() -> void:
	if _header_written:
		return
	var header := _header_context
	if header == "":
		var version := Engine.get_version_info()
		var timestamp := Time.get_datetime_string_from_system(true, true)
		header = "# Godot %s.%s.%s | %s | seed=%d" % [
			str(version.get("major", 0)),
			str(version.get("minor", 0)),
			str(version.get("patch", 0)),
			timestamp,
			_session_seed
		]
	_queue.insert(0, header)
	_header_written = true

func _push_recent(line: String) -> void:
	_recent_lines.append(line)
	if _recent_lines.size() > MAX_QUEUE:
		_recent_lines.pop_front()

func _handle_flush_failure(reason: String) -> void:
	if _disabled_due_to_error:
		return
	_disabled_due_to_error = true
	_enabled = false
	_timer.stop()
	_queue.clear()
	if not _error_reported:
		push_warning("YolkLogger disabled: %s" % reason)
		print("YolkLogger WARN: %s" % reason)
		_error_reported = true

func _resolve_active_seed() -> int:
	var config := get_node_or_null("/root/Config")
	if config != null and "seed" in config:
		return int(config.seed)
	return 0

func _build_header_context() -> void:
	var version := Engine.get_version_info()
	var timestamp := Time.get_datetime_string_from_system(true, true)
	_header_context = "# Godot %s.%s.%s | %s | seed=%d" % [
		str(version.get("major", 0)),
		str(version.get("minor", 0)),
		str(version.get("patch", 0)),
		timestamp,
		_session_seed
	]

func _init_sanitize_regex() -> void:
	if _email_regex == null:
		_email_regex = RegEx.new()
		_email_regex.compile("[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}")
	if _url_regex == null:
		_url_regex = RegEx.new()
		_url_regex.compile("https?://\\S+")
	if _token_regex == null:
		_token_regex = RegEx.new()
		_token_regex.compile("[A-Za-z0-9]{24,}")
