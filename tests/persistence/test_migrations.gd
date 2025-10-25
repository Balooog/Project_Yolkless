extends SceneTree

const SaveMigrator := preload("res://src/persistence/SaveMigrator.gd")

var _had_failure: bool = false

func _init() -> void:
	_run()

func _run() -> void:
	_test_sets_version_when_missing()
	_test_converts_dictionary_owned_to_array()
	if _had_failure:
		print("SaveMigrator suite: failures detected")
		quit(1)
	print("SaveMigrator suite: all checks passed")
	quit()

func _test_sets_version_when_missing() -> void:
	var migrator: SaveMigrator = SaveMigrator.new()
	var raw_save := {
		"eco": {},
		"research": {
			"owned": [],
			"pp": 0
		}
	}
	var migrated := migrator.migrate(raw_save)
	_assert_eq(
		int(migrated.get("save_version", -1)),
		SaveMigrator.CURRENT_VERSION,
		"Migrated save should include current save_version"
	)

func _test_converts_dictionary_owned_to_array() -> void:
	var migrator: SaveMigrator = SaveMigrator.new()
	var raw_save := {
		"eco": {},
		"research": {
			"owned": {
				"r_alpha": true,
				"r_beta": true
			}
		}
	}
	var migrated := migrator.migrate(raw_save)
	var research_variant: Variant = migrated.get("research", {})
	var research_data: Dictionary = research_variant if research_variant is Dictionary else {}
	var owned_variant: Variant = research_data.get("owned", [])
	_assert_true(
		owned_variant is Array,
		"Owned research entries should be converted to an array"
	)
	if owned_variant is Array:
		var owned: Array = owned_variant
		_assert_true("r_alpha" in owned, "Converted owned array should contain r_alpha")
		_assert_true("r_beta" in owned, "Converted owned array should contain r_beta")

func _assert_eq(actual, expected, message: String) -> void:
	if actual != expected:
		_fail("%s (expected=%s, actual=%s)" % [message, expected, actual])

func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_fail(message)

func _fail(message: String) -> void:
	push_error(message)
	_had_failure = true
