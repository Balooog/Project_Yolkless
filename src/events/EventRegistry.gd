extends Node
class_name EventRegistry

# Effect opcodes shared between the registry and runtime engine.
enum EffectType {
	POWER_MULTIPLIER,
	BACKLOG_ADD,
	PAYOUT_ON_COMPLETE
}

# Button semantics for micro-event cards.
enum ButtonType {
	ACK,
	ACCEPT,
	DECLINE
}

const EVENTS := {
	"overcast_day": {
		"title_key": "event_overcast_title",
		"body_key": "event_overcast_body",
		"duration_sec": 60,
		"repeat_cooldown_sec": 300,
		"ui_tint": Color8(97, 97, 97),
		"icon": "cloud",
		"buttons": [
			{"id": "ack", "type": ButtonType.ACK, "label_key": "event_overcast_button_ack"}
		],
		"effects_on_start": [
			{"op": EffectType.POWER_MULTIPLIER, "value": 0.90}
		],
		"effects_on_accept": [],
		"effects_on_complete": [],
		"toast_on_end_key": "event_overcast_toast_end"
	},
	"bulk_order": {
		"title_key": "event_bulk_order_title",
		"body_key": "event_bulk_order_body",
		"duration_sec": -1,
		"repeat_cooldown_sec": 480,
		"ui_tint": Color8(255, 179, 0),
		"icon": "box",
		"buttons": [
			{"id": "accept", "type": ButtonType.ACCEPT, "label_key": "event_bulk_order_button_accept"},
			{"id": "decline", "type": ButtonType.DECLINE, "label_key": "event_bulk_order_button_decline"}
		],
		"effects_on_start": [],
		"effects_on_accept": [
			{"op": EffectType.BACKLOG_ADD, "value_min": 5, "value_from": "economy_rate", "mult": 10.0}
		],
		"effects_on_complete": [
			{"op": EffectType.PAYOUT_ON_COMPLETE, "value_min": 20, "value_from": "accepted_backlog", "mult": 2.0}
		],
		"toast_on_accept_key": "event_bulk_order_toast_accept",
		"toast_on_complete_key": "event_bulk_order_toast_complete"
	}
}

static func get_definition(id: String) -> Dictionary:
	if not EVENTS.has(id):
		return {}
	return EVENTS[id].duplicate(true)
