extends Resource
class_name UITokens

@export var colors: Dictionary = {
	"banner_bg": Color8(20, 26, 32, 255),
	"banner_text": Color8(232, 239, 245, 255),
	"banner_alert": Color8(255, 194, 69, 255),
	"panel_bg": Color8(26, 32, 38, 255),
    "sheet_mobile_bg": Color8(40, 48, 60, 255),
	"panel_border": Color8(62, 78, 92, 255),
	"button_primary": Color8(214, 157, 64, 255),
	"button_primary_text": Color8(26, 20, 10, 255),
	"button_secondary": Color8(54, 64, 74, 255),
	"button_secondary_text": Color8(230, 236, 244, 255),
	"text_muted": Color8(164, 180, 192, 255),
	"focus_outline": Color8(116, 196, 246, 255)
}

@export var radii: Dictionary = {
	"corner_sm": 6.0,
	"corner_md": 12.0,
	"corner_lg": 18.0
}

@export var spacing: Dictionary = {
	"space_xs": 4.0,
	"space_sm": 8.0,
	"space_md": 12.0,
	"space_lg": 16.0,
	"space_xl": 24.0
}

@export var typography: Dictionary = {
	"font_xs": 11,
	"font_s": 13,
	"font_m": 15,
	"font_l": 18,
	"font_xl": 22,
	"font_xxl": 28
}

@export var breakpoints: Dictionary = {
	"small_max": 719,
	"medium_min": 720,
	"medium_max": 1199,
	"large_min": 1200
}

func font_size(token: StringName) -> int:
	return int(typography.get(String(token), 15))

func colour(token: StringName) -> Color:
	return colors.get(String(token), Color.WHITE)

func radius(token: StringName) -> float:
	return float(radii.get(String(token), 6.0))

func spacing_value(token: StringName) -> float:
	return float(spacing.get(String(token), 12.0))

func breakpoint_value(token: StringName) -> int:
	return int(breakpoints.get(String(token), 0))
