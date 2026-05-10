class_name WorldData
extends RefCounted

const WorldConstantsClass = preload("res://systems/world/world_constants.gd")
const WorldUtilsClass = preload("res://systems/world/world_utils.gd")
const ChunkDataClass = preload("res://systems/world/chunk_data.gd")
const DirtyChunkSystemClass = preload("res://systems/world/dirty_chunk_system.gd")

var chunks: Dictionary = {}
var dirty_chunk_system = DirtyChunkSystemClass.new()


func get_chunk(chunk_position: Vector2i):
	if not chunks.has(chunk_position):
		return null

	return chunks[chunk_position]


func has_chunk(chunk_position: Vector2i) -> bool:
	return chunks.has(chunk_position)


func get_or_create_chunk(chunk_position: Vector2i):
	var existing_chunk = get_chunk(chunk_position)
	if existing_chunk != null:
		return existing_chunk

	var next_chunk = ChunkDataClass.new(chunk_position)
	chunks[chunk_position] = next_chunk
	dirty_chunk_system.mark_chunk_dirty(chunk_position)
	return next_chunk


func get_cell(cell_position: Vector2i) -> int:
	var chunk_position: Vector2i = WorldUtilsClass.cell_to_chunk(cell_position)
	var chunk_data = get_chunk(chunk_position)
	if chunk_data == null:
		return WorldConstantsClass.CellType.AIR

	return chunk_data.get_cell(WorldUtilsClass.cell_to_local_in_chunk(cell_position))


func has_cell(cell_position: Vector2i) -> bool:
	return get_cell(cell_position) != WorldConstantsClass.CellType.AIR


func set_cell(cell_position: Vector2i, cell_type: int) -> void:
	var chunk_position: Vector2i = WorldUtilsClass.cell_to_chunk(cell_position)
	var local_cell_position: Vector2i = WorldUtilsClass.cell_to_local_in_chunk(cell_position)
	var chunk_data = get_or_create_chunk(chunk_position)
	if not chunk_data.set_cell(local_cell_position, cell_type):
		return

	dirty_chunk_system.mark_chunk_dirty(chunk_position)
	_cleanup_chunk_if_empty(chunk_position, chunk_data)


func remove_cell(cell_position: Vector2i) -> void:
	var chunk_position: Vector2i = WorldUtilsClass.cell_to_chunk(cell_position)
	var chunk_data = get_chunk(chunk_position)
	if chunk_data == null:
		return

	var local_cell_position: Vector2i = WorldUtilsClass.cell_to_local_in_chunk(cell_position)
	if not chunk_data.remove_cell(local_cell_position):
		return

	dirty_chunk_system.mark_chunk_dirty(chunk_position)
	_cleanup_chunk_if_empty(chunk_position, chunk_data)


func set_damage_progress(cell_position: Vector2i, progress: float) -> float:
	var chunk_position: Vector2i = WorldUtilsClass.cell_to_chunk(cell_position)
	var local_cell_position: Vector2i = WorldUtilsClass.cell_to_local_in_chunk(cell_position)
	var chunk_data = get_or_create_chunk(chunk_position)
	var next_progress: float = chunk_data.set_damage_progress(local_cell_position, progress)
	dirty_chunk_system.mark_chunk_dirty(chunk_position)
	_cleanup_chunk_if_empty(chunk_position, chunk_data)
	return next_progress


func add_damage_progress(cell_position: Vector2i, amount: float) -> float:
	var chunk_position: Vector2i = WorldUtilsClass.cell_to_chunk(cell_position)
	var local_cell_position: Vector2i = WorldUtilsClass.cell_to_local_in_chunk(cell_position)
	var chunk_data = get_or_create_chunk(chunk_position)
	var next_progress: float = chunk_data.add_damage_progress(local_cell_position, amount)
	dirty_chunk_system.mark_chunk_dirty(chunk_position)
	return next_progress


func get_damage_progress(cell_position: Vector2i) -> float:
	var chunk_position: Vector2i = WorldUtilsClass.cell_to_chunk(cell_position)
	var chunk_data = get_chunk(chunk_position)
	if chunk_data == null:
		return 0.0

	return chunk_data.get_damage_progress(WorldUtilsClass.cell_to_local_in_chunk(cell_position))


func remove_damage_progress(cell_position: Vector2i) -> void:
	var chunk_position: Vector2i = WorldUtilsClass.cell_to_chunk(cell_position)
	var chunk_data = get_chunk(chunk_position)
	if chunk_data == null:
		return

	if not chunk_data.remove_damage_progress(WorldUtilsClass.cell_to_local_in_chunk(cell_position)):
		return

	dirty_chunk_system.mark_chunk_dirty(chunk_position)
	_cleanup_chunk_if_empty(chunk_position, chunk_data)


func get_damage_stage(cell_position: Vector2i) -> int:
	var chunk_position: Vector2i = WorldUtilsClass.cell_to_chunk(cell_position)
	var chunk_data = get_chunk(chunk_position)
	if chunk_data == null:
		return 0

	return chunk_data.get_damage_stage(WorldUtilsClass.cell_to_local_in_chunk(cell_position))


func get_existing_chunk_positions_in_rect(chunk_min: Vector2i, chunk_max: Vector2i) -> Array[Vector2i]:
	var visible_chunk_positions: Array[Vector2i] = []

	for chunk_y in range(chunk_min.y, chunk_max.y + 1):
		for chunk_x in range(chunk_min.x, chunk_max.x + 1):
			var chunk_position: Vector2i = Vector2i(chunk_x, chunk_y)
			if chunks.has(chunk_position):
				visible_chunk_positions.append(chunk_position)

	return visible_chunk_positions


func get_used_cells() -> Array[Vector2i]:
	var used_cells: Array[Vector2i] = []

	for chunk_position in chunks.keys():
		var chunk_data = chunks[chunk_position]
		for local_cell_position in chunk_data.get_used_local_cells():
			used_cells.append(WorldUtilsClass.local_cell_to_cell(Vector2i(chunk_position), local_cell_position))

	return used_cells


func get_chunk_count() -> int:
	return chunks.size()


func get_dirty_chunk_count() -> int:
	return dirty_chunk_system.get_dirty_chunk_count()


func clear_chunk_dirty(chunk_position: Vector2i) -> void:
	dirty_chunk_system.clear_chunk_dirty(chunk_position)
	var chunk_data = get_chunk(chunk_position)
	if chunk_data != null:
		chunk_data.dirty = false


func clear() -> void:
	chunks.clear()
	dirty_chunk_system.clear()


func _cleanup_chunk_if_empty(chunk_position: Vector2i, chunk_data) -> void:
	if not chunk_data.is_empty():
		return

	chunks.erase(chunk_position)
	dirty_chunk_system.clear_chunk_dirty(chunk_position)
