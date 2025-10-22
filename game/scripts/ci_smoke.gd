extends SceneTree

func _initialize():
	var ok := true
	if FileAccess.open("res://game/data/balance.tsv", FileAccess.READ) == null:
		push_error("balance.tsv missing")
		ok = false
	if FileAccess.open("res://game/data/strings_egg.tsv", FileAccess.READ) == null:
		push_error("strings_egg.tsv missing")
		ok = false
	print("SMOKE_OK")
	quit(0 if ok else 1)
