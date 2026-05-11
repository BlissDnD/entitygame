class_name NpcBase
extends Node2D

var velocity: Vector2 = Vector2.ZERO


func set_velocity(next_velocity: Vector2) -> void:
	velocity = next_velocity
