extends Node

const ASSET_MAP_PATH := "res://assets/AssetMap.json"
const PLACEHOLDER_TOKEN := "/placeholder/"

var _asset_map: Dictionary = {}
var _texture_cache: Dictionary[String, Texture2D] = {}
var _style_cache: Dictionary[String, StyleBox] = {}

func _ready() -> void:
	_reload_asset_map()

func reload() -> void:
	_reload_asset_map()
	_texture_cache.clear()
	_style_cache.clear()

func get_texture(key: String) -> Texture2D:
	if _texture_cache.has(key) and _texture_cache[key] is Texture2D:
		return _texture_cache[key]
	var path: String = _resolve_path_for_key(key)
	var texture: Texture2D = null
	if path != "" and ResourceLoader.exists(path):
		var resource := ResourceLoader.load(path)
		if resource is Texture2D:
			texture = resource as Texture2D
	if texture == null:
		texture = _procedural_texture(key)
	_texture_cache[key] = texture
	return texture

func get_style(key: String, high_contrast: bool = false) -> StyleBox:
	var cache_key: String = "%s|%s" % [key, high_contrast]
	if _style_cache.has(cache_key) and _style_cache[cache_key] is StyleBox:
		return (_style_cache[cache_key] as StyleBox).duplicate(true)
	var path: String = _resolve_path_for_key(key)
	var style: StyleBox = null
	if path != "" and ResourceLoader.exists(path):
		var resource := ResourceLoader.load(path)
		if resource is StyleBox:
			style = (resource as StyleBox).duplicate(true)
	if style == null:
		style = _procedural_style(key, high_contrast)
	if style:
		_style_cache[cache_key] = style.duplicate(true)
		return style.duplicate(true)
	return null

func _reload_asset_map() -> void:
	_asset_map.clear()
	if not FileAccess.file_exists(ASSET_MAP_PATH):
		return
	var file := FileAccess.open(ASSET_MAP_PATH, FileAccess.READ)
	if file == null:
		return
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		for key in (parsed as Dictionary).keys():
			_asset_map[String(key)] = String((parsed as Dictionary)[key])

func _resolve_path_for_key(key: String) -> String:
	var path: String = ""
	if _asset_map.has(key):
		path = String(_asset_map[key])
	var final_candidate: String = _candidate_final_path(path)
	if final_candidate != "" and ResourceLoader.exists(final_candidate):
		return final_candidate
	if path != "" and ResourceLoader.exists(path):
		return path
	return ""

func _candidate_final_path(path: String) -> String:
	if path == "":
		return ""
	var rewritten: String = ""
	if path.contains(PLACEHOLDER_TOKEN):
		rewritten = path.replace(PLACEHOLDER_TOKEN, "/final/")
		if ResourceLoader.exists(rewritten):
			return rewritten
	var filename := path.get_file()
	if filename != "":
		var direct := "res://assets/final/%s" % filename
		if ResourceLoader.exists(direct):
			return direct
	return rewritten if rewritten != "" and ResourceLoader.exists(rewritten) else ""

func _procedural_texture(key: String) -> Texture2D:
	match key:
		"grain_particle":
			return ProceduralFactory.make_grain_texture()
		_:
			var image: Image = Image.create(2, 2, false, Image.FORMAT_RGBA8)
			image.fill(ProceduralFactory.COLOR_PANEL)
			var texture: ImageTexture = ImageTexture.create_from_image(image)
			return texture

func _procedural_style(key: String, high_contrast: bool) -> StyleBox:
	match key:
		"ui_button":
			return ProceduralFactory.make_button_style("normal", high_contrast)
		"ui_button_hover":
			return ProceduralFactory.make_button_style("hover", high_contrast)
		"ui_button_pressed":
			return ProceduralFactory.make_button_style("pressed", high_contrast)
		"ui_panel":
			return ProceduralFactory.make_panel_style(high_contrast)
		"ui_progress_bg":
			return ProceduralFactory.make_panel_style(high_contrast)
		"ui_progress_fill":
			return ProceduralFactory.make_progress_fill_style(ProceduralFactory.COLOR_ACCENT)
		_:
			return ProceduralFactory.make_panel_style(high_contrast)
