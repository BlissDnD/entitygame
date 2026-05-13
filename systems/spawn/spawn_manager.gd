class_name SpawnManager
extends Node

signal entity_spawned(entity, spawn_id)
signal spawn_group_finished(spawn_id, spawned_entities)

var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()


func spawn_scene(scene: PackedScene, parent: Node, world_position: Vector2, spawn_id: StringName = &"") -> Node:
	if scene == null or parent == null:
		return null

	var entity: Node = scene.instantiate()
	parent.add_child(entity)
	if entity is Node2D:
		entity.global_position = world_position

	entity_spawned.emit(entity, spawn_id)
	return entity


func spawn_from_table(spawn_table: SpawnTable, parent: Node, world_position: Vector2) -> Array[Node]:
	var spawned_entities: Array[Node] = []
	if spawn_table == null:
		return spawned_entities

	var entry: SpawnEntry = spawn_table.pick_entry(rng)
	if entry == null:
		return spawned_entities

	for index in range(entry.get_roll_count(rng)):
		var entity: Node = spawn_scene(entry.scene, parent, world_position, entry.id)
		if entity != null:
			spawned_entities.append(entity)

	spawn_group_finished.emit(entry.id, spawned_entities)
	return spawned_entities
