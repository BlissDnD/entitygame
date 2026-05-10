class_name WorldData
extends RefCounted

const WorldConstantsClass = preload("res://systems/world/world_constants.gd")

var cells: Dictionary = {}


func set_cell(cell_position: Vector2i, cell_type: int) -> void:
	if cell_type == WorldConstantsClass.CellType.AIR:
		remove_cell(cell_position)
		return

	cells[cell_position] = cell_type


func get_cell(cell_position: Vector2i) -> int:
	return cells.get(cell_position, WorldConstantsClass.CellType.AIR)


func has_cell(cell_position: Vector2i) -> bool:
	return cells.has(cell_position)


func get_used_cells() -> Array[Vector2i]:
	var used_cells: Array[Vector2i] = []

	for cell_position in cells.keys():
		used_cells.append(cell_position)

	return used_cells


func remove_cell(cell_position: Vector2i) -> void:
	cells.erase(cell_position)


func clear() -> void:
	cells.clear()
