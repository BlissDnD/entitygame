class_name ItemDropData
extends RefCounted

const WorldConstantsClass = preload("res://systems/world/world_constants.gd")
const WorldUtilsClass = preload("res://systems/world/world_utils.gd")

var drops: Array[Dictionary] = []


func add_item_stack(world_position: Vector2, item_kind: String, item_id, amount: int = 1, merge_radius_pixels: float = 0.0) -> void:
	if amount <= 0:
		return

	for drop_index in range(drops.size()):
		var drop_entry: Dictionary = drops[drop_index]
		if String(drop_entry.get("item_kind", "")) != item_kind:
			continue
		if drop_entry.get("item_id", -1) != item_id:
			continue

		var drop_position: Vector2 = Vector2(drop_entry.get("world_position", world_position))
		if drop_position.distance_to(world_position) <= merge_radius_pixels:
			drop_entry["amount"] = int(drop_entry.get("amount", 0)) + amount
			drop_entry["velocity"] = Vector2.ZERO
			drops[drop_index] = drop_entry
			return

	drops.append({
		"item_kind": item_kind,
		"item_id": item_id,
		"amount": amount,
		"world_position": world_position,
		"velocity": Vector2.ZERO,
	})


func add_item_definition_stack(world_position: Vector2, item_definition: ItemDefinition, amount: int = 1, merge_radius_pixels: float = 0.0) -> void:
	if item_definition == null:
		return
	add_item_stack(world_position, "item", String(item_definition.id), amount, merge_radius_pixels)
	var drop_index: int = drops.size() - 1
	for index in range(drops.size()):
		var drop_entry: Dictionary = drops[index]
		if String(drop_entry.get("item_kind", "")) != "item":
			continue
		if drop_entry.get("item_id", "") != String(item_definition.id):
			continue
		var drop_position: Vector2 = Vector2(drop_entry.get("world_position", world_position))
		if drop_position.distance_to(world_position) > merge_radius_pixels:
			continue
		drop_index = index
		break
	var merged_entry: Dictionary = drops[drop_index]
	merged_entry["item_definition"] = item_definition
	merged_entry["world_state"] = item_definition.get_default_world_state()
	merged_entry["world_interaction_conditions"] = item_definition.world_interaction_conditions.duplicate()
	merged_entry["lifespan_remaining"] = item_definition.get_max_world_lifespan_seconds()
	drops[drop_index] = merged_entry


func update_physics(world_data, delta: float, room_rect: Rect2, gravity: float, pull_radius_pixels: float, merge_radius_pixels: float, gravity_field_system = null) -> void:
	_update_lifespans(delta)
	_apply_gravity(world_data, delta, room_rect, gravity, gravity_field_system)
	_pull_and_merge_matching_items(delta, room_rect, pull_radius_pixels, merge_radius_pixels)


func get_drops() -> Array[Dictionary]:
	return drops


func get_drop_at_index(drop_index: int) -> Dictionary:
	if drop_index < 0 or drop_index >= drops.size():
		return {}

	return drops[drop_index]


func find_nearest_drop_index(world_position: Vector2, max_distance_pixels: float = 0.0) -> int:
	var nearest_index: int = -1
	var nearest_distance: float = INF

	for drop_index in range(drops.size()):
		var drop_entry: Dictionary = drops[drop_index]
		var drop_position: Vector2 = Vector2(drop_entry.get("world_position", Vector2.ZERO))
		var distance_to_drop: float = drop_position.distance_to(world_position)
		if max_distance_pixels > 0.0 and distance_to_drop > max_distance_pixels:
			continue

		if distance_to_drop < nearest_distance:
			nearest_distance = distance_to_drop
			nearest_index = drop_index

	return nearest_index


func remove_amount_at_index(drop_index: int, amount: int) -> int:
	if drop_index < 0 or drop_index >= drops.size():
		return 0

	if amount <= 0:
		return 0

	var drop_entry: Dictionary = drops[drop_index]
	var removed_amount: int = mini(amount, int(drop_entry.get("amount", 0)))
	if removed_amount <= 0:
		return 0

	var next_amount: int = int(drop_entry.get("amount", 0)) - removed_amount
	if next_amount <= 0:
		drops.remove_at(drop_index)
	else:
		drop_entry["amount"] = next_amount
		drops[drop_index] = drop_entry

	return removed_amount


func get_total_drop_count() -> int:
	var total_count: int = 0

	for drop_entry in drops:
		total_count += int(drop_entry.get("amount", 0))

	return total_count


func clear() -> void:
	drops.clear()


func _update_lifespans(delta: float) -> void:
	var drop_index: int = drops.size() - 1
	while drop_index >= 0:
		var drop_entry: Dictionary = drops[drop_index]
		var lifespan_remaining: float = float(drop_entry.get("lifespan_remaining", -1.0))
		if lifespan_remaining < 0.0:
			drop_index -= 1
			continue

		lifespan_remaining -= delta
		if lifespan_remaining <= 0.0:
			drops.remove_at(drop_index)
			drop_index -= 1
			continue

		drop_entry["lifespan_remaining"] = lifespan_remaining
		drops[drop_index] = drop_entry
		drop_index -= 1


func _apply_gravity(world_data, delta: float, room_rect: Rect2, gravity: float, gravity_field_system = null) -> void:
	for drop_index in range(drops.size()):
		var drop_entry: Dictionary = drops[drop_index]
		var world_position: Vector2 = Vector2(drop_entry.get("world_position", Vector2.ZERO))
		var velocity: Vector2 = Vector2(drop_entry.get("velocity", Vector2.ZERO))

		var gravity_acceleration: Vector2 = Vector2(0.0, gravity)
		if gravity_field_system != null and gravity_field_system.has_method("get_gravity_acceleration"):
			gravity_acceleration = gravity_field_system.get_gravity_acceleration(world_position, gravity)

		velocity += gravity_acceleration * delta
		var next_position: Vector2 = world_position + (velocity * delta)
		next_position.x = clampf(next_position.x, room_rect.position.x, room_rect.end.x)
		next_position.y = clampf(next_position.y, room_rect.position.y, room_rect.end.y)

		if _is_using_downward_gravity(gravity_acceleration):
			if _is_drop_supported(world_data, next_position):
				velocity.y = 0.0
				next_position.y = _get_supported_world_y(world_data, world_position, next_position.y)
		elif world_data.is_solid_at_world(next_position):
			velocity = Vector2.ZERO
			next_position = world_position

		drop_entry["world_position"] = next_position
		drop_entry["velocity"] = velocity
		drops[drop_index] = drop_entry


func _is_using_downward_gravity(gravity_acceleration: Vector2) -> bool:
	return gravity_acceleration.y > 0.0 and absf(gravity_acceleration.y) >= absf(gravity_acceleration.x)


func _pull_and_merge_matching_items(delta: float, room_rect: Rect2, pull_radius_pixels: float, merge_radius_pixels: float) -> void:
	var drop_index: int = 0
	while drop_index < drops.size():
		var drop_entry: Dictionary = drops[drop_index]
		var item_kind: String = String(drop_entry.get("item_kind", ""))
		var item_id = drop_entry.get("item_id", -1)
		var world_position: Vector2 = Vector2(drop_entry.get("world_position", Vector2.ZERO))
		var merge_target_index: int = -1
		var merge_target_distance: float = INF

		for other_index in range(drops.size()):
			if other_index == drop_index:
				continue

			var other_entry: Dictionary = drops[other_index]
			if String(other_entry.get("item_kind", "")) != item_kind:
				continue
			if other_entry.get("item_id", -1) != item_id:
				continue
			if int(other_entry.get("amount", 0)) < int(drop_entry.get("amount", 0)):
				continue

			var other_position: Vector2 = Vector2(other_entry.get("world_position", Vector2.ZERO))
			var distance_to_other: float = world_position.distance_to(other_position)
			if distance_to_other > pull_radius_pixels:
				continue

			if distance_to_other < merge_target_distance:
				merge_target_distance = distance_to_other
				merge_target_index = other_index
		if merge_target_index == -1:
			drop_index += 1
			continue

		var target_entry: Dictionary = drops[merge_target_index]
		var target_position: Vector2 = Vector2(target_entry.get("world_position", world_position))
		var pull_direction: Vector2 = target_position - world_position
		if pull_direction != Vector2.ZERO:
			world_position += pull_direction.normalized() * minf(pull_direction.length(), pull_radius_pixels * 2.4 * delta)
			world_position.x = clampf(world_position.x, room_rect.position.x, room_rect.end.x)
			world_position.y = clampf(world_position.y, room_rect.position.y, room_rect.end.y)
			drop_entry["world_position"] = world_position
			drops[drop_index] = drop_entry

		if world_position.distance_to(target_position) <= merge_radius_pixels:
			target_entry["amount"] = int(target_entry.get("amount", 0)) + int(drop_entry.get("amount", 0))
			target_entry["velocity"] = Vector2.ZERO
			drops[merge_target_index] = target_entry
			drops.remove_at(drop_index)
			if merge_target_index > drop_index:
				merge_target_index -= 1
			continue

		drop_index += 1


func _is_drop_supported(world_data, world_position: Vector2) -> bool:
	return world_data.is_solid_at_world(world_position + Vector2(0.0, WorldConstantsClass.CELL_SIZE.y * 0.5))


func _get_supported_world_y(world_data, previous_position: Vector2, target_y: float) -> float:
	var test_position: Vector2 = Vector2(previous_position.x, previous_position.y)
	var direction: float = signf(target_y - previous_position.y)
	if direction == 0.0:
		return previous_position.y

	while direction > 0.0 and test_position.y < target_y:
		test_position.y += 1.0
		if _is_drop_supported(world_data, test_position):
			return test_position.y - 1.0

	return target_y
