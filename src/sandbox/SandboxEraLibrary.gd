extends RefCounted
class_name SandboxEraLibrary

const DEFAULT_ERA := StringName("backyard")

const SandboxGrid := preload("res://src/sandbox/SandboxGrid.gd")

const PRESET_TO_ERA := {
	StringName("early_farm"): StringName("backyard"),
	StringName("mid_growth"): StringName("small_farm"),
	StringName("industrial_push"): StringName("industrial"),
	StringName("eco_revival"): StringName("eco_revival"),
	StringName("colony_alpha"): StringName("off_world")
}

const ERA_CONFIG := {
	StringName("backyard"): {
		"label": "Backyard Coop",
		"camera": {
			"zoom": 1.0,
			"offset": Vector2(0.0, -6.0)
		},
		"parallax": {
			"amplitude": Vector2(8.0, 4.0),
			"speed": 0.18
		},
		"palette": {
			"sky_top": Color(0.70, 0.88, 1.0, 1.0),
			"sky_bottom": Color(0.94, 0.98, 1.0, 1.0),
			"ground": Color(0.55, 0.78, 0.45, 1.0),
			"ground_horizon": Color(0.46, 0.68, 0.40, 1.0),
			"structure_body": Color(0.78, 0.58, 0.40, 1.0),
			"structure_roof": Color(0.78, 0.32, 0.28, 1.0),
			"detail": Color(0.88, 0.73, 0.55, 1.0),
			"haze_color": Color(0.73, 0.88, 0.93, 0.05)
		},
		"comfort_overlay": {
			"calm": Color(0.96, 0.99, 0.96, 0.10),
			"stressed": Color(0.42, 0.20, 0.20, 0.16)
		},
		"particle": {
			"color": Color(1.0, 0.96, 0.82, 0.42),
			"amount": 18,
			"speed": 0.35
		},
		"material_palette": {
			SandboxGrid.MATERIAL_SAND: Color(0.88, 0.81, 0.57, 1.0),
			SandboxGrid.MATERIAL_PLANT: Color(0.30, 0.69, 0.42, 1.0)
		},
		"props": [
			{
				"id": "coop_block",
				"color": Color(0.78, 0.58, 0.40, 1.0),
				"size": Vector2(0.26, 0.28),
				"position": Vector2(0.32, 0.73),
				"corner_radius": 12,
				"requires_tier": 1
			},
			{
				"id": "tree_canopy",
				"color": Color(0.42, 0.68, 0.42, 1.0),
				"size": Vector2(0.28, 0.36),
				"position": Vector2(0.72, 0.58),
				"corner_radius": 48,
				"requires_research_count": 1
			},
			{
				"id": "lantern_post",
				"color": Color(0.98, 0.92, 0.60, 0.85),
				"size": Vector2(0.05, 0.18),
				"position": Vector2(0.58, 0.48),
				"corner_radius": 6,
				"requires_research_count": 3
			}
		]
	},
	StringName("small_farm"): {
		"label": "Small Farm",
		"camera": {
			"zoom": 0.97,
			"offset": Vector2(0.0, -10.0)
		},
		"parallax": {
			"amplitude": Vector2(10.0, 5.0),
			"speed": 0.22
		},
		"palette": {
			"sky_top": Color(0.78, 0.86, 0.98, 1.0),
			"sky_bottom": Color(1.0, 0.96, 0.82, 1.0),
			"ground": Color(0.63, 0.72, 0.36, 1.0),
			"ground_horizon": Color(0.54, 0.66, 0.32, 1.0),
			"structure_body": Color(0.78, 0.62, 0.44, 1.0),
			"structure_roof": Color(0.78, 0.40, 0.22, 1.0),
			"detail": Color(0.92, 0.80, 0.50, 1.0),
			"haze_color": Color(0.86, 0.78, 0.48, 0.08)
		},
		"comfort_overlay": {
			"calm": Color(0.98, 0.97, 0.88, 0.10),
			"stressed": Color(0.45, 0.26, 0.20, 0.18)
		},
		"particle": {
			"color": Color(1.0, 0.92, 0.72, 0.40),
			"amount": 22,
			"speed": 0.42
		},
		"material_palette": {
			SandboxGrid.MATERIAL_SAND: Color(0.92, 0.78, 0.52, 1.0),
			SandboxGrid.MATERIAL_PLANT: Color(0.42, 0.72, 0.35, 1.0),
			SandboxGrid.MATERIAL_WATER: Color(0.38, 0.56, 0.86, 0.92)
		},
		"props": [
			{
				"id": "farm_barn",
				"color": Color(0.78, 0.46, 0.32, 1.0),
				"size": Vector2(0.30, 0.32),
				"position": Vector2(0.34, 0.70),
				"corner_radius": 10,
				"requires_tier": 3
			},
			{
				"id": "farm_silo",
				"color": Color(0.86, 0.78, 0.48, 1.0),
				"size": Vector2(0.12, 0.34),
				"position": Vector2(0.68, 0.62),
				"corner_radius": 20,
				"requires_tier": 3
			},
			{
				"id": "farm_tractor",
				"color": Color(1.0, 0.68, 0.30, 1.0),
				"size": Vector2(0.12, 0.10),
				"position": Vector2(0.52, 0.78),
				"corner_radius": 8,
				"requires_research_count": 4
			}
		]
	},
	StringName("industrial"): {
		"label": "Industrial Plant",
		"camera": {
			"zoom": 0.92,
			"offset": Vector2(0.0, -18.0)
		},
		"parallax": {
			"amplitude": Vector2(14.0, 6.0),
			"speed": 0.28
		},
		"palette": {
			"sky_top": Color(0.48, 0.54, 0.62, 1.0),
			"sky_bottom": Color(0.66, 0.66, 0.72, 1.0),
			"ground": Color(0.40, 0.42, 0.36, 1.0),
			"ground_horizon": Color(0.36, 0.38, 0.34, 1.0),
			"structure_body": Color(0.52, 0.56, 0.60, 1.0),
			"structure_roof": Color(0.36, 0.38, 0.44, 1.0),
			"detail": Color(0.76, 0.68, 0.54, 1.0),
			"haze_color": Color(0.40, 0.42, 0.46, 0.28)
		},
		"comfort_overlay": {
			"calm": Color(0.70, 0.82, 0.84, 0.12),
			"stressed": Color(0.32, 0.18, 0.18, 0.24)
		},
		"particle": {
			"color": Color(1.0, 0.66, 0.32, 0.55),
			"amount": 28,
			"speed": 0.55
		},
		"material_palette": {
			SandboxGrid.MATERIAL_SAND: Color(0.58, 0.54, 0.46, 1.0),
			SandboxGrid.MATERIAL_OIL: Color(0.22, 0.18, 0.12, 0.96),
			SandboxGrid.MATERIAL_PLANT: Color(0.32, 0.54, 0.28, 1.0),
			SandboxGrid.MATERIAL_FIRE: Color(1.0, 0.52, 0.18, 1.0)
		},
		"props": [
			{
				"id": "stack_a",
				"color": Color(0.46, 0.48, 0.52, 1.0),
				"size": Vector2(0.10, 0.40),
				"position": Vector2(0.28, 0.60),
				"corner_radius": 6,
				"requires_tier": 4
			},
			{
				"id": "stack_b",
				"color": Color(0.40, 0.42, 0.46, 1.0),
				"size": Vector2(0.08, 0.36),
				"position": Vector2(0.38, 0.58),
				"corner_radius": 6,
				"requires_tier": 4
			},
			{
				"id": "cooling_tower",
				"color": Color(0.62, 0.64, 0.70, 1.0),
				"size": Vector2(0.20, 0.32),
				"position": Vector2(0.65, 0.66),
				"corner_radius": 18,
				"requires_research_count": 5
			}
		]
	},
	StringName("eco_revival"): {
		"label": "Eco Revival",
		"camera": {
			"zoom": 0.94,
			"offset": Vector2(0.0, -14.0)
		},
		"parallax": {
			"amplitude": Vector2(12.0, 6.0),
			"speed": 0.24
		},
		"palette": {
			"sky_top": Color(0.54, 0.74, 0.96, 1.0),
			"sky_bottom": Color(0.84, 0.96, 0.92, 1.0),
			"ground": Color(0.38, 0.70, 0.52, 1.0),
			"ground_horizon": Color(0.34, 0.64, 0.48, 1.0),
			"structure_body": Color(0.72, 0.88, 0.82, 1.0),
			"structure_roof": Color(0.32, 0.64, 0.62, 1.0),
			"detail": Color(0.90, 0.96, 0.78, 1.0),
			"haze_color": Color(0.58, 0.84, 0.74, 0.09)
		},
		"comfort_overlay": {
			"calm": Color(0.76, 0.98, 0.90, 0.12),
			"stressed": Color(0.28, 0.32, 0.28, 0.14)
		},
		"particle": {
			"color": Color(0.82, 1.0, 0.90, 0.48),
			"amount": 24,
			"speed": 0.38
		},
		"material_palette": {
			SandboxGrid.MATERIAL_PLANT: Color(0.32, 0.78, 0.48, 1.0),
			SandboxGrid.MATERIAL_WATER: Color(0.30, 0.66, 0.86, 0.92),
			SandboxGrid.MATERIAL_STONE: Color(0.56, 0.60, 0.58, 1.0)
		},
		"props": [
			{
				"id": "vertical_garden",
				"color": Color(0.32, 0.78, 0.48, 1.0),
				"size": Vector2(0.18, 0.34),
				"position": Vector2(0.30, 0.60),
				"corner_radius": 25,
				"requires_tier": 5
			},
			{
				"id": "glass_dome",
				"color": Color(0.70, 0.92, 0.88, 1.0),
				"size": Vector2(0.24, 0.26),
				"position": Vector2(0.62, 0.68),
				"corner_radius": 30,
				"requires_tier": 5
			},
			{
				"id": "solar_stack",
				"color": Color(0.90, 0.96, 0.78, 1.0),
				"size": Vector2(0.16, 0.12),
				"position": Vector2(0.50, 0.80),
				"corner_radius": 8,
				"requires_research_count": 6
			}
		]
	},
	StringName("off_world"): {
		"label": "Off-World Habitat",
		"camera": {
			"zoom": 0.88,
			"offset": Vector2(0.0, -20.0)
		},
		"parallax": {
			"amplitude": Vector2(16.0, 6.0),
			"speed": 0.32
		},
		"palette": {
			"sky_top": Color(0.32, 0.28, 0.58, 1.0),
			"sky_bottom": Color(0.58, 0.38, 0.68, 1.0),
			"ground": Color(0.36, 0.28, 0.50, 1.0),
			"ground_horizon": Color(0.30, 0.24, 0.46, 1.0),
			"structure_body": Color(0.72, 0.76, 0.92, 1.0),
			"structure_roof": Color(0.48, 0.64, 0.92, 1.0),
			"detail": Color(0.92, 0.82, 0.96, 1.0),
			"haze_color": Color(0.32, 0.30, 0.52, 0.20)
		},
		"comfort_overlay": {
			"calm": Color(0.70, 0.74, 0.96, 0.16),
			"stressed": Color(0.24, 0.18, 0.42, 0.22)
		},
		"particle": {
			"color": Color(0.84, 0.90, 1.0, 0.52),
			"amount": 20,
			"speed": 0.46
		},
		"material_palette": {
			SandboxGrid.MATERIAL_WATER: Color(0.48, 0.72, 0.98, 0.92),
			SandboxGrid.MATERIAL_PLANT: Color(0.48, 0.86, 0.78, 1.0),
			SandboxGrid.MATERIAL_STONE: Color(0.58, 0.60, 0.68, 1.0),
			SandboxGrid.MATERIAL_FIRE: Color(0.92, 0.56, 0.96, 1.0)
		},
		"props": [
			{
				"id": "hab_tower",
				"color": Color(0.72, 0.76, 0.92, 1.0),
				"size": Vector2(0.16, 0.40),
				"position": Vector2(0.32, 0.58),
				"corner_radius": 20,
				"requires_tier": 6
			},
			{
				"id": "orbital_spire",
				"color": Color(0.48, 0.64, 0.92, 1.0),
				"size": Vector2(0.12, 0.36),
				"position": Vector2(0.54, 0.56),
				"corner_radius": 18,
				"requires_tier": 6
			},
			{
				"id": "light_array",
				"color": Color(0.92, 0.82, 0.96, 1.0),
				"size": Vector2(0.28, 0.16),
				"position": Vector2(0.66, 0.74),
				"corner_radius": 40,
				"requires_research_count": 7
			}
		]
	}
}

static func era_for_preset(preset: StringName) -> StringName:
	var era: StringName = PRESET_TO_ERA.get(preset, DEFAULT_ERA)
	return era

static func config_for_preset(preset: StringName) -> Dictionary:
	return config_for_era(era_for_preset(preset))

static func config_for_era(era: StringName) -> Dictionary:
	if not ERA_CONFIG.has(era):
		return (ERA_CONFIG[DEFAULT_ERA] as Dictionary).duplicate(true)
	return (ERA_CONFIG[era] as Dictionary).duplicate(true)

static func default_label() -> String:
	var config := config_for_era(DEFAULT_ERA)
	return String(config.get("label", "Backyard Coop"))
