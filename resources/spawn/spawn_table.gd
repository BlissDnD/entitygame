class_name SpawnTable
extends Resource

@export var id: StringName = &""
@export var entries: Array[SpawnEntry] = []


func pick_entry(rng: RandomNumberGenerator) -> SpawnEntry:
	if entries.is_empty():
		return null

	var total_weight: float = 0.0
	for entry in entries:
		if entry == null:
			continue
		total_weight += maxf(entry.weight, 0.0)

	if total_weight <= 0.0:
		return entries[0]

	var roll: float = rng.randf_range(0.0, total_weight) if rng != null else 0.0
	var cursor: float = 0.0
	for entry in entries:
		if entry == null:
			continue
		cursor += maxf(entry.weight, 0.0)
		if roll <= cursor:
			return entry

	return entries.back()
