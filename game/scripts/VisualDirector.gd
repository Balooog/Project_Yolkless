extends Node
class_name VisualDirector

# VisualDirector previously hosted fullscreen feed blur modules.
# The updated UI handles localized feed effects directly, so this
# autoload now acts as a no-op placeholder to preserve the API
# expected by Main.gd and future visual modules.

func set_sources(_eco: Economy = null, _strings: StringsCatalog = null) -> void:
	pass


func activate(_id: String, _enabled: bool) -> void:
	pass


func set_high_contrast(_enabled: bool) -> void:
	pass
