class_name CrashShip
extends Node2D

signal interacted
signal salvaged

@export var is_salvaged: bool = false

@onready var spawn_point: Marker2D = $SpawnPoint
@onready var interaction_collision_shape: CollisionShape2D = $InteractionArea/CollisionShape2D


func get_spawn_position() -> Vector2:
	return spawn_point.global_position


func can_interact(user: Node = null, interaction_context: InteractionContext = null) -> bool:
	if interaction_context == null:
		return false
	if interaction_context.current_room_index != 0:
		return false
	if not visible:
		return false
	return overlaps_world_rect(interaction_context.get_player_rect())


func interact(user: Node = null, interaction_context: InteractionContext = null) -> void:
	interacted.emit()

	if not is_salvaged:
		is_salvaged = true
		salvaged.emit()
		print("Ship salvaged: basic tool acquired")
	else:
		print("Nothing else to salvage")


func get_interaction_rect() -> Rect2:
	var shape: Shape2D = interaction_collision_shape.shape
	if shape is RectangleShape2D:
		var rectangle_shape: RectangleShape2D = shape
		return Rect2(
			interaction_collision_shape.global_position - (rectangle_shape.size * 0.5),
			rectangle_shape.size
		)
	return Rect2(global_position - Vector2(16.0, 16.0), Vector2(32.0, 32.0))


func overlaps_world_rect(world_rect: Rect2) -> bool:
	return get_interaction_rect().intersects(world_rect)
