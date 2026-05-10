class_name MiningProgressData
extends RefCounted

var progress_by_cell: Dictionary = {}


func add_progress(cell_position: Vector2i, amount: float) -> float:
	var next_progress: float = clampf(get_progress(cell_position) + amount, 0.0, 1.0)

	if next_progress <= 0.0:
		remove_progress(cell_position)
		return 0.0

	if next_progress >= 1.0:
		remove_progress(cell_position)
		return 1.0

	progress_by_cell[cell_position] = next_progress
	return next_progress


func get_progress(cell_position: Vector2i) -> float:
	return progress_by_cell.get(cell_position, 0.0)


func has_progress(cell_position: Vector2i) -> bool:
	return progress_by_cell.has(cell_position)


func is_cell_damaged(cell_position: Vector2i) -> bool:
	return get_progress(cell_position) > 0.0


func get_damage_stage(cell_position: Vector2i) -> int:
	return get_damage_stage_from_progress(get_progress(cell_position))


func get_damage_stage_from_progress(progress: float) -> int:
	if progress >= 1.0:
		return 4
	if progress >= 0.75:
		return 3
	if progress >= 0.5:
		return 2
	if progress >= 0.25:
		return 1
	return 0


func remove_progress(cell_position: Vector2i) -> void:
	progress_by_cell.erase(cell_position)


func get_damaged_cells() -> Array[Vector2i]:
	var damaged_cells: Array[Vector2i] = []

	for cell_position in progress_by_cell.keys():
		damaged_cells.append(cell_position)

	return damaged_cells


func clear() -> void:
	progress_by_cell.clear()
