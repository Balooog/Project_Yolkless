extends RefCounted

const FROM_VERSION := 0
const TO_VERSION := 1

func migrate(data: Dictionary) -> Dictionary:
	var working: Dictionary = data.duplicate(true)
	var eco_variant: Variant = working.get("eco", {})
	if eco_variant is Dictionary:
		working["eco"] = (eco_variant as Dictionary).duplicate(true)
	else:
		working["eco"] = {}
	var research_variant: Variant = working.get("research", {})
	var research_dict: Dictionary = {}
	if research_variant is Dictionary:
		research_dict = (research_variant as Dictionary).duplicate(true)
	else:
		research_dict = {}
	var owned_variant: Variant = research_dict.get("owned", [])
	if owned_variant is Dictionary:
		research_dict["owned"] = (owned_variant as Dictionary).keys()
	elif owned_variant is Array:
		research_dict["owned"] = owned_variant.duplicate(true)
	else:
		research_dict["owned"] = []
	if not research_dict.has("pp"):
		research_dict["pp"] = 0
	working["research"] = research_dict
	working["save_version"] = TO_VERSION
	return working
