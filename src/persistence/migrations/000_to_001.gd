extends Node
## Placeholder migration: version 0 -> 1
## Future migrations should implement `apply(data: Dictionary) -> Dictionary`.

func apply(data: Dictionary) -> Dictionary:
	# No-op for initial schema.  Keep structure for future upgrades.
	return data
