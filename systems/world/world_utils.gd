class_name WorldUtils
extends RefCounted

const WorldConstantsClass = preload("res://systems/world/world_constants.gd")


static func world_to_cell(world_position: Vector2) -> Vector2i:
	# Convert a world position to the top-left logical cell it occupies.
	return Vector2i(
		int(floor(world_position.x / WorldConstantsClass.CELL_SIZE.x)),
		int(floor(world_position.y / WorldConstantsClass.CELL_SIZE.y))
	)


static func cell_to_world(cell_position: Vector2i) -> Vector2:
	# Return the world-space top-left origin of a logical cell.
	return Vector2(
		cell_position.x * WorldConstantsClass.CELL_SIZE.x,
		cell_position.y * WorldConstantsClass.CELL_SIZE.y
	)


static func world_to_chunk(world_position: Vector2) -> Vector2i:
	# Convert a world position into the chunk that contains its cell.
	return cell_to_chunk(world_to_cell(world_position))


static func cell_to_chunk(cell_position: Vector2i) -> Vector2i:
	# Convert a logical cell position into its chunk coordinate.
	return Vector2i(
		int(floor(float(cell_position.x) / WorldConstantsClass.CHUNK_SIZE_CELLS.x)),
		int(floor(float(cell_position.y) / WorldConstantsClass.CHUNK_SIZE_CELLS.y))
	)


static func chunk_to_world(chunk_position: Vector2i) -> Vector2:
	# Return the world-space top-left origin of a chunk.
	return cell_to_world(chunk_to_cell(chunk_position))


static func chunk_to_cell(chunk_position: Vector2i) -> Vector2i:
	# Return the logical cell origin of a chunk.
	return Vector2i(
		chunk_position.x * WorldConstantsClass.CHUNK_SIZE_CELLS.x,
		chunk_position.y * WorldConstantsClass.CHUNK_SIZE_CELLS.y
	)


static func cell_to_local_in_chunk(cell_position: Vector2i) -> Vector2i:
	# Convert a world cell to a local chunk-relative cell.
	var chunk_position: Vector2i = cell_to_chunk(cell_position)
	var chunk_origin: Vector2i = chunk_to_cell(chunk_position)
	return cell_position - chunk_origin


static func local_cell_to_cell(chunk_position: Vector2i, local_cell_position: Vector2i) -> Vector2i:
	# Convert a chunk-local cell back into world cell coordinates.
	return chunk_to_cell(chunk_position) + local_cell_position


static func snap_to_grid(world_position: Vector2) -> Vector2:
	# Snap any world position to the top-left origin of its logical cell.
	return cell_to_world(world_to_cell(world_position))
