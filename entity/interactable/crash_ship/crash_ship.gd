class_name CrashShip
extends Node2D

signal interacted
signal salvaged

@export var is_salvaged: bool = false

@onready var spawn_point: Marker2D = $SpawnPoint
@onready var interaction_collision_shape: CollisionShape2D = $InteractionArea/CollisionShape2D


func get_spawn_position() -> Vector2:
	return spawn_point.global_position


func interact() -> void:
	interacted.emit()

	if not is_salvaged:
		is_salvaged = true
		salvaged.emit()
		print("Ship salvaged: basic tool acquired")
	else:
		print("Nothing else to salvage")


func overlaps_world_rect(world_rect: Rect2) -> bool:
	var shape: Shape2D = interaction_collision_shape.shape
	if shape is RectangleShape2D:
		var rectangle_shape: RectangleShape2D = shape
		var interaction_rect: Rect2 = Rect2(
			interaction_collision_shape.global_position - (rectangle_shape.size * 0.5),
			rectangle_shape.size
		)
		return interaction_rect.intersects(world_rect)

	return false
