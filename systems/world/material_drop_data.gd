class_name MaterialDropData
extends RefCounted

const WorldConstantsClass = preload("res://systems/world/world_constants.gd")

var drops: Array[Dictionary] = []


func add_drop(cell_position: Vector2i, material_id: int, amount: int = 1, merge_radius_cells: int = 0) -> void:
	if amount <= 0:
		return

	for drop_index in range(drops.size()):
		var drop_entry: Dictionary = drops[drop_index]
		var drop_cell: Vector2i = Vector2i(drop_entry.get("cell_position", Vector2i.ZERO))
		var drop_material_id: int = int(drop_entry.get("material_id", WorldConstantsClass.CellType.AIR))
		if drop_material_id != material_id:
			continue

		if drop_cell == cell_position or drop_cell.distance_to(cell_position) <= merge_radius_cells:
			drop_entry["amount"] = int(drop_entry.get("amount", 0)) + amount
			drops[drop_index] = drop_entry
			return

	drops.append({
		"cell_position": cell_position,
		"material_id": material_id,
		"amount": amount,
	})


func get_drops() -> Array[Dictionary]:
	return drops


func get_drop_indices_at_cell(cell_position: Vector2i) -> Array[int]:
	var matching_indices: Array[int] = []

	for drop_index in range(drops.size()):
		var drop_entry: Dictionary = drops[drop_index]
		if Vector2i(drop_entry.get("cell_position", Vector2i.ZERO)) == cell_position:
			matching_indices.append(drop_index)

	return matching_indices


func get_drop_at_index(drop_index: int) -> Dictionary:
	if drop_index < 0 or drop_index >= drops.size():
		return {}

	return drops[drop_index]


func find_nearest_drop_index(cell_position: Vector2i, max_distance_cells: int = 0) -> int:
	var nearest_index: int = -1
	var nearest_distance: float = INF

	for drop_index in range(drops.size()):
		var drop_entry: Dictionary = drops[drop_index]
		var drop_cell: Vector2i = Vector2i(drop_entry.get("cell_position", Vector2i.ZERO))
		var distance_to_cell: float = drop_cell.distance_to(cell_position)
		if distance_to_cell > max_distance_cells:
			continue

		if distance_to_cell < nearest_distance:
			nearest_distance = distance_to_cell
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
