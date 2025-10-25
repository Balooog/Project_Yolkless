extends SceneTree

const MATERIALS_PATH := "res://data/materials.tsv"
const OUTPUT_DIR := "res://art/palettes"
const OUTPUT_IMAGE := OUTPUT_DIR + "/cozy_palette.png"
const OUTPUT_JSON := OUTPUT_DIR + "/cozy_palette.json"
const SWATCH_SIZE := 64

func _initialize() -> void:
	var materials := _load_material_rows()
	if materials.is_empty():
		push_error("Palette export aborted: no material rows found at %s" % MATERIALS_PATH)
		quit(1)
		return
	_ensure_output_directory()
	_write_palette_image(materials)
	_write_palette_metadata(materials)
	print("Palette exported (%d entries)" % materials.size())
	quit()

func _load_material_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var file := FileAccess.open(MATERIALS_PATH, FileAccess.READ)
	if file == null:
		push_error("Unable to open materials TSV: %s" % MATERIALS_PATH)
		return rows
	var header: PackedStringArray = []
	while not file.eof_reached():
		var raw_line := file.get_line()
		var line := raw_line.strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		var columns := raw_line.split("\t", false)
		if header.is_empty():
			header = PackedStringArray(columns)
			continue
		var entry: Dictionary = {}
		for i in range(min(header.size(), columns.size())):
			entry[header[i]] = columns[i].strip_edges()
		rows.append(entry)
	file.close()
	return rows

func _ensure_output_directory() -> void:
	var abs_path := ProjectSettings.globalize_path(OUTPUT_DIR)
	if not DirAccess.dir_exists_absolute(abs_path):
		DirAccess.make_dir_recursive_absolute(abs_path)

func _write_palette_image(materials: Array[Dictionary]) -> void:
	var width: int = max(materials.size(), 1) * SWATCH_SIZE
	var image: Image = Image.create(width, SWATCH_SIZE, false, Image.FORMAT_RGBA8)
	for index in range(materials.size()):
		var row: Dictionary = materials[index]
		var hex_string := String(row.get("hex", "#FFFFFF"))
		var color: Color = Color.from_string(hex_string, Color.WHITE)
		var x_start: int = index * SWATCH_SIZE
		for x in range(x_start, x_start + SWATCH_SIZE):
			for y in range(SWATCH_SIZE):
				image.set_pixel(x, y, color)
	var save_result := image.save_png(OUTPUT_IMAGE)
	if save_result != OK:
		push_error("Failed to save palette image (%s): %d" % [OUTPUT_IMAGE, save_result])

func _write_palette_metadata(materials: Array[Dictionary]) -> void:
	var payload := {
		"generated_at": Time.get_datetime_string_from_system(true, true),
		"materials": []
	}
	for row in materials:
		var record := {
			"id": String(row.get("material_id", "")),
			"hex": String(row.get("hex", "#FFFFFF")),
			"usage": String(row.get("usage", "")),
			"contrast_hint": String(row.get("contrast_hint", ""))
		}
		payload["materials"].append(record)
	var json_string := JSON.stringify(payload, "\t")
	var file := FileAccess.open(OUTPUT_JSON, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open palette metadata file for writing: %s" % OUTPUT_JSON)
		return
	file.store_string(json_string)
	file.close()
