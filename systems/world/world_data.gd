class_name WorldData
extends RefCounted

const WorldConstantsClass = preload("res://systems/world/world_constants.gd")
const WorldUtilsClass = preload("res://systems/world/world_utils.gd")
const ChunkDataClass = preload("res://systems/world/chunk_data.gd")
const DirtyChunkSystemClass = preload("res://systems/world/dirty_chunk_system.gd")
var chunks: Dictionary = {}
var dirty_chunk_system = DirtyChunkSystemClass.new()
var ramp_type_cache: Dictionary = {}
var ramp_cells_by_chunk_cache: Dictionary = {}


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

	_mark_terrain_change_dirty(cell_position)
	_cleanup_chunk_if_empty(chunk_position, chunk_data)


func remove_cell(cell_position: Vector2i) -> void:
	var chunk_position: Vector2i = WorldUtilsClass.cell_to_chunk(cell_position)
	var chunk_data = get_chunk(chunk_position)
	if chunk_data == null:
		return

	var local_cell_position: Vector2i = WorldUtilsClass.cell_to_local_in_chunk(cell_position)
	if not chunk_data.remove_cell(local_cell_position):
		return

	_mark_terrain_change_dirty(cell_position)
	_cleanup_chunk_if_empty(chunk_position, chunk_data)


func set_damage_progress(cell_position: Vector2i, progress: float) -> float:
	var chunk_position: Vector2i = WorldUtilsClass.cell_to_chunk(cell_position)
	var local_cell_position: Vector2i = WorldUtilsClass.cell_to_local_in_chunk(cell_position)
	var chunk_data = get_or_create_chunk(chunk_position)
	var next_progress: float = chunk_data.set_damage_progress(local_cell_position, progress)
	_mark_visual_change_dirty(cell_position)
	_cleanup_chunk_if_empty(chunk_position, chunk_data)
	return next_progress


func add_damage_progress(cell_position: Vector2i, amount: float) -> float:
	var chunk_position: Vector2i = WorldUtilsClass.cell_to_chunk(cell_position)
	var local_cell_position: Vector2i = WorldUtilsClass.cell_to_local_in_chunk(cell_position)
	var chunk_data = get_or_create_chunk(chunk_position)
	var next_progress: float = chunk_data.add_damage_progress(local_cell_position, amount)
	_mark_visual_change_dirty(cell_position)
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

	_mark_visual_change_dirty(cell_position)
	_cleanup_chunk_if_empty(chunk_position, chunk_data)


func get_damage_stage(cell_position: Vector2i) -> int:
	var chunk_position: Vector2i = WorldUtilsClass.cell_to_chunk(cell_position)
	var chunk_data = get_chunk(chunk_position)
	if chunk_data == null:
		return 0

	return chunk_data.get_damage_stage(WorldUtilsClass.cell_to_local_in_chunk(cell_position))


func is_solid_at_world(world_position: Vector2) -> bool:
	return _is_point_inside_solid_shape(world_position)


func intersects_solid_rect(world_rect: Rect2) -> bool:
	var start_cell: Vector2i = WorldUtilsClass.world_to_cell(world_rect.position)
	var end_cell: Vector2i = WorldUtilsClass.world_to_cell(world_rect.end - Vector2.ONE)

	for cell_y in range(start_cell.y, end_cell.y + 1):
		for cell_x in range(start_cell.x, end_cell.x + 1):
			var cell_position: Vector2i = Vector2i(cell_x, cell_y)
			if get_cell(cell_position) != WorldConstantsClass.CellType.AIR:
				return true
			if _rect_intersects_ramp(world_rect, cell_position):
				return true

	return false


func get_ramp_type(cell_position: Vector2i) -> int:
	if ramp_type_cache.has(cell_position):
		return int(ramp_type_cache[cell_position])

	var ramp_type: int = _calculate_ramp_type(cell_position)
	ramp_type_cache[cell_position] = ramp_type
	return ramp_type


func _calculate_ramp_type(cell_position: Vector2i) -> int:
	if get_cell(cell_position) != WorldConstantsClass.CellType.AIR:
		return WorldConstantsClass.RampType.NONE

	var below_cell: Vector2i = cell_position + Vector2i.DOWN
	if get_cell(below_cell) == WorldConstantsClass.CellType.AIR:
		return WorldConstantsClass.RampType.NONE

	var has_left_support: bool = get_cell(cell_position + Vector2i.LEFT) != WorldConstantsClass.CellType.AIR
	var has_right_support: bool = get_cell(cell_position + Vector2i.RIGHT) != WorldConstantsClass.CellType.AIR
	var has_down_left_support: bool = get_cell(cell_position + Vector2i(-1, 1)) != WorldConstantsClass.CellType.AIR
	var has_down_right_support: bool = get_cell(cell_position + Vector2i(1, 1)) != WorldConstantsClass.CellType.AIR

	if has_right_support and has_down_right_support and not has_left_support:
		return WorldConstantsClass.RampType.UP_RIGHT

	if has_left_support and has_down_left_support and not has_right_support:
		return WorldConstantsClass.RampType.UP_LEFT

	return WorldConstantsClass.RampType.NONE


func get_ramp_source_cell(cell_position: Vector2i) -> Vector2i:
	var ramp_type: int = get_ramp_type(cell_position)
	if ramp_type == WorldConstantsClass.RampType.UP_RIGHT:
		return cell_position + Vector2i.DOWN
	if ramp_type == WorldConstantsClass.RampType.UP_LEFT:
		return cell_position + Vector2i.DOWN

	return cell_position


func get_existing_chunk_positions_in_rect(chunk_min: Vector2i, chunk_max: Vector2i) -> Array[Vector2i]:
	var visible_chunk_positions: Array[Vector2i] = []

	for chunk_y in range(chunk_min.y, chunk_max.y + 1):
		for chunk_x in range(chunk_min.x, chunk_max.x + 1):
			var chunk_position: Vector2i = Vector2i(chunk_x, chunk_y)
			if chunks.has(chunk_position):
				visible_chunk_positions.append(chunk_position)

	return visible_chunk_positions


func chunk_has_render_content(chunk_position: Vector2i) -> bool:
	if has_chunk(chunk_position):
		return true

	return not get_ramp_cells_for_chunk(chunk_position).is_empty()


func get_render_chunk_positions_in_rect(chunk_min: Vector2i, chunk_max: Vector2i) -> Array[Vector2i]:
	var render_chunk_positions: Array[Vector2i] = []

	for chunk_y in range(chunk_min.y, chunk_max.y + 1):
		for chunk_x in range(chunk_min.x, chunk_max.x + 1):
			var chunk_position: Vector2i = Vector2i(chunk_x, chunk_y)
			if has_chunk(chunk_position) or _has_chunk_in_neighborhood(chunk_position):
				render_chunk_positions.append(chunk_position)

	return render_chunk_positions


func get_ramp_cells_for_chunk(chunk_position: Vector2i) -> Array[Vector2i]:
	if ramp_cells_by_chunk_cache.has(chunk_position):
		return ramp_cells_by_chunk_cache[chunk_position].duplicate()

	var ramp_cells: Array[Vector2i] = []
	var chunk_origin: Vector2i = WorldUtilsClass.chunk_to_cell(chunk_position)

	for local_y in range(WorldConstantsClass.CHUNK_SIZE_CELLS.y):
		for local_x in range(WorldConstantsClass.CHUNK_SIZE_CELLS.x):
			var cell_position: Vector2i = chunk_origin + Vector2i(local_x, local_y)
			if get_ramp_type(cell_position) == WorldConstantsClass.RampType.NONE:
				continue

			ramp_cells.append(cell_position)

	ramp_cells_by_chunk_cache[chunk_position] = ramp_cells.duplicate()
	return ramp_cells


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
	ramp_type_cache.clear()
	ramp_cells_by_chunk_cache.clear()


func _mark_terrain_change_dirty(cell_position: Vector2i) -> void:
	for offset_y in range(-1, 2):
		for offset_x in range(-1, 2):
			var dirty_cell_position: Vector2i = cell_position + Vector2i(offset_x, offset_y)
			dirty_chunk_system.mark_chunk_dirty(WorldUtilsClass.cell_to_chunk(dirty_cell_position))
			ramp_type_cache.erase(dirty_cell_position)
			ramp_cells_by_chunk_cache.erase(WorldUtilsClass.cell_to_chunk(dirty_cell_position))


func _mark_visual_change_dirty(cell_position: Vector2i) -> void:
	dirty_chunk_system.mark_chunk_dirty(WorldUtilsClass.cell_to_chunk(cell_position))
	dirty_chunk_system.mark_chunk_dirty(WorldUtilsClass.cell_to_chunk(cell_position + Vector2i.UP))


func _cleanup_chunk_if_empty(chunk_position: Vector2i, chunk_data) -> void:
	if not chunk_data.is_empty():
		return

	chunks.erase(chunk_position)
	dirty_chunk_system.clear_chunk_dirty(chunk_position)
	ramp_cells_by_chunk_cache.erase(chunk_position)


func _has_chunk_in_neighborhood(chunk_position: Vector2i) -> bool:
	for offset_y in range(-1, 2):
		for offset_x in range(-1, 2):
			if offset_x == 0 and offset_y == 0:
				continue
			if has_chunk(chunk_position + Vector2i(offset_x, offset_y)):
				return true

	return false


func _is_point_inside_solid_shape(world_position: Vector2) -> bool:
	var cell_position: Vector2i = WorldUtilsClass.world_to_cell(world_position)
	if get_cell(cell_position) != WorldConstantsClass.CellType.AIR:
		return true

	return _is_point_inside_ramp(world_position, cell_position)


func _is_point_inside_ramp(world_position: Vector2, cell_position: Vector2i) -> bool:
	var ramp_type: int = get_ramp_type(cell_position)
	if ramp_type == WorldConstantsClass.RampType.NONE:
		return false

	var cell_world: Vector2 = WorldUtilsClass.cell_to_world(cell_position)
	var local_position: Vector2 = world_position - cell_world
	var cell_width: float = float(WorldConstantsClass.CELL_SIZE.x)
	var cell_height: float = float(WorldConstantsClass.CELL_SIZE.y)

	if local_position.x < 0.0 or local_position.x > cell_width or local_position.y < 0.0 or local_position.y > cell_height:
		return false

	if ramp_type == WorldConstantsClass.RampType.UP_RIGHT:
		var surface_y: float = cell_height - ((local_position.x / cell_width) * cell_height)
		return local_position.y >= surface_y

	var opposite_surface_y: float = (local_position.x / cell_width) * cell_height
	return local_position.y >= opposite_surface_y


func _rect_intersects_ramp(world_rect: Rect2, cell_position: Vector2i) -> bool:
	var ramp_type: int = get_ramp_type(cell_position)
	if ramp_type == WorldConstantsClass.RampType.NONE:
		return false

	var triangle_points: PackedVector2Array = _get_ramp_triangle_points(cell_position, ramp_type)
	var rect_points: PackedVector2Array = PackedVector2Array([
		world_rect.position,
		Vector2(world_rect.end.x, world_rect.position.y),
		world_rect.end,
		Vector2(world_rect.position.x, world_rect.end.y),
	])

	for rect_point in rect_points:
		if _point_in_triangle(rect_point, triangle_points[0], triangle_points[1], triangle_points[2]):
			return true

	for triangle_point in triangle_points:
		if world_rect.has_point(triangle_point):
			return true

	var triangle_edges: Array = [
		[triangle_points[0], triangle_points[1]],
		[triangle_points[1], triangle_points[2]],
		[triangle_points[2], triangle_points[0]],
	]
	var rect_edges: Array = [
		[rect_points[0], rect_points[1]],
		[rect_points[1], rect_points[2]],
		[rect_points[2], rect_points[3]],
		[rect_points[3], rect_points[0]],
	]

	for triangle_edge in triangle_edges:
		for rect_edge in rect_edges:
			if _segments_intersect(triangle_edge[0], triangle_edge[1], rect_edge[0], rect_edge[1]):
				return true

	return false


func _get_ramp_triangle_points(cell_position: Vector2i, ramp_type: int) -> PackedVector2Array:
	var cell_world: Vector2 = WorldUtilsClass.cell_to_world(cell_position)
	var cell_size: Vector2 = Vector2(WorldConstantsClass.CELL_SIZE)
	var top_left: Vector2 = cell_world
	var top_right: Vector2 = cell_world + Vector2(cell_size.x, 0.0)
	var bottom_left: Vector2 = cell_world + Vector2(0.0, cell_size.y)
	var bottom_right: Vector2 = cell_world + cell_size

	if ramp_type == WorldConstantsClass.RampType.UP_RIGHT:
		return PackedVector2Array([bottom_left, top_right, bottom_right])

	return PackedVector2Array([top_left, bottom_left, bottom_right])


func _point_in_triangle(point: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	var edge_ab: float = _signed_triangle_area(point, a, b)
	var edge_bc: float = _signed_triangle_area(point, b, c)
	var edge_ca: float = _signed_triangle_area(point, c, a)
	var has_negative: bool = edge_ab < 0.0 or edge_bc < 0.0 or edge_ca < 0.0
	var has_positive: bool = edge_ab > 0.0 or edge_bc > 0.0 or edge_ca > 0.0
	return not (has_negative and has_positive)


func _signed_triangle_area(point_a: Vector2, point_b: Vector2, point_c: Vector2) -> float:
	return ((point_a.x - point_c.x) * (point_b.y - point_c.y)) - ((point_b.x - point_c.x) * (point_a.y - point_c.y))


func _segments_intersect(a1: Vector2, a2: Vector2, b1: Vector2, b2: Vector2) -> bool:
	var denominator: float = ((a2.x - a1.x) * (b2.y - b1.y)) - ((a2.y - a1.y) * (b2.x - b1.x))
	if is_zero_approx(denominator):
		return false

	var ua: float = (((b2.x - b1.x) * (a1.y - b1.y)) - ((b2.y - b1.y) * (a1.x - b1.x))) / denominator
	var ub: float = (((a2.x - a1.x) * (a1.y - b1.y)) - ((a2.y - a1.y) * (a1.x - b1.x))) / denominator
	return ua >= 0.0 and ua <= 1.0 and ub >= 0.0 and ub <= 1.0
