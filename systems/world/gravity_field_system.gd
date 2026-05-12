class_name GravityFieldSystem
extends RefCounted

const GravityFieldDataClass = preload("res://systems/world/gravity_field_data.gd")

var fields: Array[GravityFieldData] = []


func create_field(bounds: Rect2, strength: float) -> GravityFieldData:
	var merged_bounds: Rect2 = bounds
	var inherited_gravity_point: Vector2 = Vector2.ZERO
	var inherited_strength: float = strength
	var inherited_has_gravity_point: bool = false
	var did_merge: bool = true

	while did_merge:
		did_merge = false
		for field_index in range(fields.size() - 1, -1, -1):
			var field: GravityFieldData = fields[field_index]
			if not _rects_touch_or_overlap(merged_bounds, field.bounds):
				continue

			merged_bounds = merged_bounds.merge(field.bounds)
			if not inherited_has_gravity_point and field.has_gravity_point:
				inherited_gravity_point = field.gravity_point
				inherited_strength = field.strength
				inherited_has_gravity_point = true
			fields.remove_at(field_index)
			did_merge = true

	var field: GravityFieldData = GravityFieldDataClass.new(bounds, inherited_strength)
	field.bounds = merged_bounds
	if inherited_has_gravity_point:
		field.set_gravity_point(inherited_gravity_point, inherited_strength)
	fields.append(field)
	return field


func get_field_count() -> int:
	return fields.size()


func get_fields() -> Array[GravityFieldData]:
	return fields


func find_field_at(world_position: Vector2) -> GravityFieldData:
	for field in fields:
		if field.contains(world_position):
			return field
	return null


func find_field_intersecting(world_rect: Rect2) -> GravityFieldData:
	for field in fields:
		if field.intersects(world_rect):
			return field
	return null


func find_active_field_intersecting(world_rect: Rect2) -> GravityFieldData:
	for field in fields:
		if field.has_gravity_point and field.intersects(world_rect):
			return field
	return null


func set_gravity_point(world_position: Vector2, strength: float) -> GravityFieldData:
	var field: GravityFieldData = find_field_at(world_position)
	if field == null:
		return null

	field.set_gravity_point(world_position, strength)
	return field


func get_gravity_acceleration(world_position: Vector2, fallback_gravity: float) -> Vector2:
	var field: GravityFieldData = find_field_at(world_position)
	if field == null:
		return Vector2(0.0, fallback_gravity)
	if not field.has_gravity_point:
		return Vector2(0.0, fallback_gravity)

	var acceleration: Vector2 = field.get_acceleration(world_position)
	if acceleration == Vector2.ZERO:
		return Vector2.ZERO

	return acceleration


func get_active_field_count() -> int:
	var active_count: int = 0
	for field in fields:
		if field.has_gravity_point:
			active_count += 1
	return active_count


func _rects_touch_or_overlap(rect_a: Rect2, rect_b: Rect2) -> bool:
	return rect_a.intersects(rect_b, true)
