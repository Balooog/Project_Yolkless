extends Control
class_name BottomTabs

signal tab_selected(tab_id: StringName)

@export var tokens: UITokens
@onready var _container: HBoxContainer = %TabsContainer
@onready var _buttons: Dictionary = {
	&"home": %HomeTab,
	&"store": %StoreTab,
	&"research": %ResearchTab,
	&"automation": %AutomationTab,
	&"prestige": %PrestigeTab
}

func _ready() -> void:
	UIHelpers.set_fill_expand(self, true, false)
	_apply_tokens()
	for id in _buttons.keys():
		var button := _buttons[id]
		if button:
			button.pressed.connect(_on_button_pressed.bind(id))

func _apply_tokens() -> void:
	if tokens == null:
		return
	for button in _buttons.values():
		if button is Button:
			var cast_button := button as Button
			cast_button.clip_text = true
			cast_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _on_button_pressed(id: StringName) -> void:
	tab_selected.emit(id)
