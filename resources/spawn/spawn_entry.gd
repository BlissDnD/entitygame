class_name SpawnEntry
extends Resource

@export var id: StringName = &""
@export var scene: PackedScene
@export var weight: float = 1.0
@export var min_count: int = 1
@export var max_count: int = 1
@export var tags: PackedStringArray = PackedStringArray()


func get_roll_count(rng: RandomNumberGenerator) -> int:
	if rng == null:
		return mini(min_count, max_count)

	return rng.randi_range(mini(min_count, max_count), maxi(min_count, max_count))
