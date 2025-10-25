extends RefCounted
class_name SaveMigrator

const CURRENT_VERSION := 1
const MIGRATIONS := [
	{
		"from": 0,
		"script": preload("res://src/persistence/migrations/Migration_0_to_1.gd")
	}
]

func migrate(save_data: Dictionary) -> Dictionary:
	var working: Dictionary = save_data.duplicate(true)
	var version: int = int(working.get("save_version", 0))
	while version < CURRENT_VERSION:
		var migration := _find_migration(version)
		if migration == null:
			push_warning("SaveMigrator: missing migration for version %d" % version)
			break
		working = migration.migrate(working)
		version = int(working.get("save_version", version + 1))
	working["save_version"] = CURRENT_VERSION
	return working

func _find_migration(version: int) -> RefCounted:
	for entry in MIGRATIONS:
		var from_version: int = int(entry.get("from", -1))
		if from_version != version:
			continue
		var script: GDScript = entry.get("script")
		if script == null:
			continue
		var instance: RefCounted = script.new()
		if instance.has_method("migrate"):
			return instance
	return null
