class_name ChunkData
extends RefCounted

const WorldConstantsClass = preload("res://systems/world/world_constants.gd")
const WorldUtilsClass = preload("res://systems/world/world_utils.gd")

var chunk_position: Vector2i = Vector2i.ZERO
var cells: Dictionary = {}
var damage_by_cell: Dictionary = {}
var dirty: bool = true


func _init(next_chunk_position: Vector2i = Vector2i.ZERO) -> void:
	chunk_position = next_chunk_position


func set_cell(local_cell_position: Vector2i, cell_type: int) -> bool:
	if cell_type == WorldConstantsClass.CellType.AIR:
		return remove_cell(local_cell_position)

	if int(cells.get(local_cell_position, WorldConstantsClass.CellType.AIR)) == cell_type:
		return false

	cells[local_cell_position] = cell_type
	dirty = true
	return true


func get_cell(local_cell_position: Vector2i) -> int:
	return int(cells.get(local_cell_position, WorldConstantsClass.CellType.AIR))


func has_cell(local_cell_position: Vector2i) -> bool:
	return cells.has(local_cell_position)


func remove_cell(local_cell_position: Vector2i) -> bool:
	if not cells.has(local_cell_position):
		return false

	cells.erase(local_cell_position)
	damage_by_cell.erase(local_cell_position)
	dirty = true
	return true


func set_damage_progress(local_cell_position: Vector2i, progress: float) -> float:
	var next_progress: float = clampf(progress, 0.0, 1.0)

	if next_progress <= 0.0:
		remove_damage_progress(local_cell_position)
		return 0.0

	damage_by_cell[local_cell_position] = next_progress
	dirty = true
	return next_progress


func add_damage_progress(local_cell_position: Vector2i, amount: float) -> float:
	return set_damage_progress(local_cell_position, get_damage_progress(local_cell_position) + amount)


func get_damage_progress(local_cell_position: Vector2i) -> float:
	return float(damage_by_cell.get(local_cell_position, 0.0))


func has_damage_progress(local_cell_position: Vector2i) -> bool:
	return damage_by_cell.has(local_cell_position)


func remove_damage_progress(local_cell_position: Vector2i) -> bool:
	if not damage_by_cell.has(local_cell_position):
		return false

	damage_by_cell.erase(local_cell_position)
	dirty = true
	return true


func get_damage_stage(local_cell_position: Vector2i) -> int:
	var progress: float = get_damage_progress(local_cell_position)
	if progress >= 1.0:
		return 4
	if progress >= 0.75:
		return 3
	if progress >= 0.5:
		return 2
	if progress >= 0.25:
		return 1
	return 0


func is_empty() -> bool:
	return cells.is_empty() and damage_by_cell.is_empty()


func get_used_local_cells() -> Array[Vector2i]:
	var used_local_cells: Array[Vector2i] = []

	for local_cell_position in cells.keys():
		used_local_cells.append(local_cell_position)

	return used_local_cells


func get_used_cell_count() -> int:
	return cells.size()


func get_world_cell_position(local_cell_position: Vector2i) -> Vector2i:
	return WorldUtilsClass.local_cell_to_cell(chunk_position, local_cell_position)
