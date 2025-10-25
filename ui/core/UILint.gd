extends Node
class_name UILint

signal lint_completed(summary: Dictionary)

var _issues: Dictionary = {
	"overflow": [],
	"missing_size_flags": [],
	"unlabeled_button": []
}

func run(root: Control) -> Dictionary:
	_clear()
	if root:
		_scan(root)
	lint_completed.emit(_issues)
	return _issues.duplicate(true)

func assert_no_overflow(root: Control) -> void:
	var results := run(root)
	if not (results.get("overflow", []) as Array).is_empty():
		push_error("UILint overflow issues detected: %s" % [results["overflow"]])

func _clear() -> void:
	for key in _issues.keys():
		_issues[key] = []

func _scan(control: Control) -> void:
	_check_size_flags(control)
	_check_overflow(control)
	_check_button_label(control)
	for child in control.get_children():
		if child is Control:
			_scan(child as Control)

func _check_size_flags(control: Control) -> void:
	if control == null:
		return
	if control.get_parent() is Container:
		return
	if control.size_flags_horizontal == 0 or control.size_flags_vertical == 0:
		(_issues["missing_size_flags"] as Array).append(control.get_path())

func _check_overflow(control: Control) -> void:
	if control is Label:
		var label := control as Label
		if not label.clip_text and not label.autowrap:
			(_issues["overflow"] as Array).append(label.get_path())

func _check_button_label(control: Control) -> void:
	if control is BaseButton:
		var button := control as BaseButton
		if button.text.strip_edges() == "" and button.tooltip_text.strip_edges() == "":
			(_issues["unlabeled_button"] as Array).append(button.get_path())
