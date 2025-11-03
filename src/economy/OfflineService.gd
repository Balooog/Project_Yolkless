extends RefCounted
class_name OfflineService

func apply(params: Dictionary) -> Dictionary:
	var eco: Economy = params.get("economy", null)
	if eco == null:
		return {}
	var elapsed_seconds: float = max(float(params.get("elapsed_seconds", 0.0)), 0.0)
	var base_pps: float = float(params.get("base_pps", eco.current_base_pps()))
	var applied_seconds: float = elapsed_seconds
	var grant: float = 0.0
	if elapsed_seconds > 0.0:
		grant = eco.offline_grant(elapsed_seconds)
	var passive_multiplier: float = eco.last_offline_passive_multiplier()
	var passive_pps: float = base_pps * passive_multiplier
	if passive_pps > 0.0:
		applied_seconds = min(elapsed_seconds, grant / passive_pps)
	var overflow_seconds: float = max(elapsed_seconds - applied_seconds, 0.0)
	return {
		"elapsed_seconds": elapsed_seconds,
		"applied_seconds": applied_seconds,
		"overflow_seconds": overflow_seconds,
		"grant": grant,
		"passive_multiplier": passive_multiplier,
		"clamped": overflow_seconds > 1.0
	}
