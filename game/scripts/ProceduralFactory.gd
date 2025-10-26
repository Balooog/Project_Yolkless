extends Node

const PALETTE_DEFAULT := StringName("default")
const PALETTE_DEUTERANOPIA := StringName("deuteranopia")
const PALETTE_PROTANOPIA := StringName("protanopia")

const PALETTE_LABEL_KEYS := {
	PALETTE_DEFAULT: "color_palette_default",
	PALETTE_DEUTERANOPIA: "color_palette_deuteranopia",
	PALETTE_PROTANOPIA: "color_palette_protanopia"
}

const _PALETTES := {
	PALETTE_DEFAULT: {
		"bg": Color("2e2e2e"),
		"panel": Color("3a3a3a"),
		"text": Color("f2f2f2"),
		"accent": Color("e3b341"),
		"feed": {
			"normal": {
				"high": Color(0.2, 0.8, 0.35, 1.0),
				"medium": Color(0.95, 0.68, 0.2, 1.0),
				"low": Color(0.9, 0.2, 0.2, 1.0)
			},
			"high": {
				"high": Color(0.0, 0.85, 0.2, 1.0),
				"medium": Color(0.98, 0.78, 0.1, 1.0),
				"low": Color(1.0, 0.22, 0.22, 1.0)
			}
		}
	},
	PALETTE_DEUTERANOPIA: {
		"bg": Color("2e2e2e"),
		"panel": Color("3a3a3a"),
		"text": Color("f2f2f2"),
		"accent": Color(0.43, 0.68, 0.94, 1.0),
		"feed": {
			"normal": {
				"high": Color(0.12, 0.62, 0.78, 1.0),
				"medium": Color(0.95, 0.71, 0.26, 1.0),
				"low": Color(0.56, 0.37, 0.74, 1.0)
			},
			"high": {
				"high": Color(0.0, 0.72, 0.86, 1.0),
				"medium": Color(0.99, 0.83, 0.4, 1.0),
				"low": Color(0.68, 0.43, 0.82, 1.0)
			}
		}
	},
	PALETTE_PROTANOPIA: {
		"bg": Color("2e2e2e"),
		"panel": Color("3a3a3a"),
		"text": Color("f2f2f2"),
		"accent": Color(0.64, 0.54, 0.92, 1.0),
		"feed": {
			"normal": {
				"high": Color(0.18, 0.65, 0.74, 1.0),
				"medium": Color(0.97, 0.74, 0.28, 1.0),
				"low": Color(0.58, 0.43, 0.74, 1.0)
			},
			"high": {
				"high": Color(0.0, 0.74, 0.78, 1.0),
				"medium": Color(0.99, 0.84, 0.43, 1.0),
				"low": Color(0.69, 0.48, 0.82, 1.0)
			}
		}
	}
}

static var _palette: StringName = PALETTE_DEFAULT
static var COLOR_BG: Color = _PALETTES[PALETTE_DEFAULT]["bg"]
static var COLOR_PANEL: Color = _PALETTES[PALETTE_DEFAULT]["panel"]
static var COLOR_TEXT: Color = _PALETTES[PALETTE_DEFAULT]["text"]
static var COLOR_ACCENT: Color = _PALETTES[PALETTE_DEFAULT]["accent"]

static func color_with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, clamp(alpha, 0.0, 1.0))

static func supported_palettes() -> Array[StringName]:
	return [
		PALETTE_DEFAULT,
		PALETTE_DEUTERANOPIA,
		PALETTE_PROTANOPIA
	]

static func ensure_palette(palette: StringName) -> StringName:
	return palette if _PALETTES.has(palette) else PALETTE_DEFAULT

static func set_palette(palette: StringName) -> void:
	var resolved := ensure_palette(palette)
	if _palette == resolved:
		return
	_palette = resolved
	var data: Dictionary = _PALETTES[_palette]
	COLOR_BG = data["bg"]
	COLOR_PANEL = data["panel"]
	COLOR_TEXT = data["text"]
	COLOR_ACCENT = data["accent"]

static func current_palette() -> StringName:
	return _palette

static func palette_label_key(palette: StringName) -> String:
	var resolved := ensure_palette(palette)
	return PALETTE_LABEL_KEYS.get(resolved, "color_palette_default")

static func feed_fill_color(fraction: float, high_contrast: bool) -> Color:
	var palette_data_variant: Variant = _PALETTES.get(_palette, _PALETTES[PALETTE_DEFAULT])
	var palette_data: Dictionary = palette_data_variant if palette_data_variant is Dictionary else _PALETTES[PALETTE_DEFAULT]
	var feed_data_variant: Variant = palette_data.get("feed", {})
	var feed_data: Dictionary = feed_data_variant if feed_data_variant is Dictionary else {}
	var variant_key := "high" if high_contrast else "normal"
	var variant_variant: Variant = feed_data.get(variant_key, {})
	var variant: Dictionary = variant_variant if variant_variant is Dictionary else {}
	if variant.is_empty():
		var fallback_feed_variant: Variant = _PALETTES[PALETTE_DEFAULT].get("feed", {})
		var fallback_feed: Dictionary = fallback_feed_variant if fallback_feed_variant is Dictionary else {}
		var fallback_variant_variant: Variant = fallback_feed.get(variant_key, {})
		var fallback_variant: Dictionary = fallback_variant_variant if fallback_variant_variant is Dictionary else {}
		variant = fallback_variant
	var level_key := "low"
	if fraction >= 0.66:
		level_key = "high"
	elif fraction >= 0.33:
		level_key = "medium"
	if variant.has(level_key):
		var color_value: Variant = variant[level_key]
		if color_value is Color:
			return color_value
	# Fall back to accent for safety.
	return COLOR_ACCENT

static func make_grain_texture() -> Texture2D:
	var gradient := Gradient.new()
	gradient.add_point(0.0, color_with_alpha(COLOR_ACCENT, 0.95))
	gradient.add_point(0.5, color_with_alpha(COLOR_ACCENT, 0.6))
	gradient.add_point(1.0, color_with_alpha(COLOR_ACCENT, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 64
	texture.height = 64
	texture.fill = GradientTexture2D.FILL_RADIAL
	return texture

static func make_panel_style(high_contrast: bool, accent_border: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var bg_color := COLOR_PANEL
	var border_color := COLOR_BG
	if high_contrast:
		bg_color = COLOR_BG.lightened(0.15)
		border_color = COLOR_TEXT
	style.bg_color = bg_color
	style.set_corner_radius_all(6)
	style.set_border_width_all(1)
	style.border_color = COLOR_ACCENT if accent_border else border_color
	style.shadow_color = Color.TRANSPARENT
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style

static func make_progress_fill_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(6)
	style.set_border_width_all(0)
	return style

static func make_button_style(state: String, high_contrast: bool) -> StyleBoxFlat:
	var base := COLOR_PANEL
	if state == "hover":
		base = COLOR_PANEL.lightened(0.1)
	elif state == "pressed":
		base = COLOR_PANEL.darkened(0.15)
	var outline := COLOR_ACCENT
	if high_contrast:
		base = base.lightened(0.2)
	var style := make_panel_style(high_contrast, true)
	style.bg_color = base
	style.border_color = outline
	return style

static func make_weather_icon_circle(fill_color: Color, outline_color: Color) -> Texture2D:
	var size: int = 40
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var center := Vector2((size - 1) * 0.5, (size - 1) * 0.5)
	var radius := float(size) * 0.32
	for y in range(size):
		for x in range(size):
			var point := Vector2(float(x), float(y))
			var distance := point.distance_to(center)
			if distance <= radius:
				image.set_pixel(x, y, fill_color)
			elif distance <= radius + 1.3:
				image.set_pixel(x, y, outline_color)
	return ImageTexture.create_from_image(image)

static func make_weather_icon_triangle(fill_color: Color, outline_color: Color) -> Texture2D:
	var size: int = 40
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var top: int = 4
	var bottom: int = size - 4
	for y in range(top, bottom):
		var t := float(y - top) / float(bottom - top)
		var half_width := (1.0 - t) * (size * 0.42)
		var min_x: int = int(round(size * 0.5 - half_width))
		var max_x: int = int(round(size * 0.5 + half_width))
		for x in range(min_x, max_x + 1):
			var clamped_x: int = min(max(x, 0), size - 1)
			var color := fill_color
			if x == min_x or x == max_x or y == bottom - 1:
				color = outline_color
			image.set_pixel(clamped_x, y, color)
	var column := int(size * 0.5)
	for y in range(top + 6, bottom - 6):
		image.set_pixel(column, y, outline_color)
	image.set_pixel(column, bottom - 4, outline_color)
	return ImageTexture.create_from_image(image)

static func make_env_bg(size: Vector2) -> Node2D:
	var root := Node2D.new()
	root.name = "EnvironmentProceduralRoot"
	var half := size * 0.5
	var sky := _make_color_rect("Sky", Vector2(-half.x, -half.y), size, Color(0.74, 0.9, 1.0, 1.0))
	root.add_child(sky)
	var ground_height := size.y * 0.33
	var ground := _make_color_rect("Ground", Vector2(-half.x, half.y - ground_height), Vector2(size.x, ground_height), Color(0.58, 0.78, 0.45, 1.0))
	root.add_child(ground)
	var haze := _make_color_rect("PollutionHaze", Vector2(-half.x, -half.y), size, Color(0.3, 0.33, 0.35, 0.05))
	root.add_child(haze)

	var stripe := _make_color_rect("GroundStripe", Vector2(-half.x, half.y - ground_height - 12), Vector2(size.x, 18), Color(0.46, 0.68, 0.4, 1.0))
	root.add_child(stripe)
	var fence := _make_color_rect("Fence", Vector2(-half.x, half.y - ground_height - 30), Vector2(size.x, 6), Color(0.9, 0.83, 0.65, 1.0))
	root.add_child(fence)

	var coop := Node2D.new()
	coop.name = "Coop"
	coop.position = Vector2(-size.x * 0.22, half.y - ground_height - 12)
	root.add_child(coop)

	var coop_body := _make_color_rect("CoopBody", Vector2(-36, -60), Vector2(96, 72), Color(0.78, 0.58, 0.4, 1.0))
	coop.add_child(coop_body)
	var coop_door := _make_color_rect("CoopDoor", Vector2(12, -28), Vector2(30, 40), Color(0.26, 0.16, 0.1, 1.0))
	coop.add_child(coop_door)
	var coop_roof := Polygon2D.new()
	coop_roof.name = "CoopRoof"
	coop_roof.position = Vector2(12, -64)
	coop_roof.polygon = PackedVector2Array([Vector2(-60, 24), Vector2(60, 24), Vector2(0, -12)])
	coop_roof.color = Color(0.78, 0.32, 0.28, 1.0)
	coop.add_child(coop_roof)

	var trees := _make_tree_row(size)
	root.add_child(trees)

	var chicken_positions := [
		{"name": "ChickenA", "pos": Vector2(-60, half.y - ground_height + 20)},
		{"name": "ChickenB", "pos": Vector2(20, half.y - ground_height + 28)},
		{"name": "ChickenC", "pos": Vector2(100, half.y - ground_height + 16)}
	]
	for entry in chicken_positions:
		var chicken := _make_chicken(entry["name"], entry["pos"])
		root.add_child(chicken)

	var reputation_icon := Label.new()
	reputation_icon.name = "ReputationIcon"
	reputation_icon.position = Vector2(size.x * 0.34, -half.y + 30)
	reputation_icon.text = ":)"
	reputation_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reputation_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	reputation_icon.add_theme_font_size_override("font_size", 26)
	root.add_child(reputation_icon)

	return root

static func _make_color_rect(name: String, position: Vector2, size: Vector2, color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.name = name
	rect.position = position
	rect.size = size
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

static func _make_tree_row(size: Vector2) -> Node2D:
	var row := Node2D.new()
	row.name = "Trees"
	var half_width := size.x * 0.5
	var base_y := -size.y * 0.08
	for i in range(-2, 3):
		var tree := Node2D.new()
		tree.name = "Tree%d" % (i + 3)
		tree.position = Vector2(i * 80, base_y)
		var trunk := Polygon2D.new()
		trunk.polygon = PackedVector2Array([Vector2(-6, 20), Vector2(6, 20), Vector2(4, -20), Vector2(-4, -20)])
		trunk.color = Color(0.4, 0.25, 0.2, 1.0)
		tree.add_child(trunk)
		var canopy := Polygon2D.new()
		canopy.polygon = PackedVector2Array([Vector2(0, -48), Vector2(28, -12), Vector2(20, 18), Vector2(-20, 18), Vector2(-28, -12)])
		canopy.color = Color(0.48, 0.72, 0.38, 1.0)
		tree.add_child(canopy)
		row.add_child(tree)
	return row

static func _make_chicken(name: String, position: Vector2) -> Node2D:
	var chicken := Node2D.new()
	chicken.name = name
	chicken.position = position
	var body := _make_color_rect("Body", Vector2(-12, -10), Vector2(26, 20), Color(1.0, 0.95, 0.75, 1.0))
	chicken.add_child(body)
	var wing := _make_color_rect("Wing", Vector2(6, 4), Vector2(10, 6), Color(0.95, 0.82, 0.6, 1.0))
	body.add_child(wing)
	var head := _make_color_rect("Head", Vector2(16, -10), Vector2(10, 10), Color(0.98, 0.88, 0.65, 1.0))
	chicken.add_child(head)
	var beak := _make_color_rect("Beak", Vector2(24, -4), Vector2(6, 4), Color(0.95, 0.6, 0.2, 1.0))
	chicken.add_child(beak)
	return chicken
