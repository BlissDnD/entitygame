class_name GravityFieldData
extends RefCounted

var bounds: Rect2 = Rect2()
var gravity_point: Vector2 = Vector2.ZERO
var has_gravity_point: bool = false
var enabled: bool = true
var strength: float = 980.0


func _init(next_bounds: Rect2 = Rect2(), next_strength: float = 980.0) -> void:
	bounds = next_bounds
	strength = next_strength


func contains(world_position: Vector2) -> bool:
	return enabled and bounds.has_point(world_position)


func intersects(world_rect: Rect2) -> bool:
	return enabled and bounds.intersects(world_rect)


func get_acceleration(world_position: Vector2) -> Vector2:
	if not has_gravity_point or not contains(world_position):
		return Vector2.ZERO

	var direction: Vector2 = gravity_point - world_position
	if direction == Vector2.ZERO:
		return Vector2.ZERO

	return direction.normalized() * strength


func set_gravity_point(world_position: Vector2, next_strength: float) -> void:
	gravity_point = world_position
	strength = next_strength
	has_gravity_point = true
