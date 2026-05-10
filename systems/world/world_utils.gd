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
	var cell_position := world_to_cell(world_position)
	return Vector2i(
		int(floor(float(cell_position.x) / WorldConstantsClass.CHUNK_SIZE_CELLS.x)),
		int(floor(float(cell_position.y) / WorldConstantsClass.CHUNK_SIZE_CELLS.y))
	)


static func chunk_to_world(chunk_position: Vector2i) -> Vector2:
	# Return the world-space top-left origin of a chunk.
	var chunk_cell_origin := Vector2i(
		chunk_position.x * WorldConstantsClass.CHUNK_SIZE_CELLS.x,
		chunk_position.y * WorldConstantsClass.CHUNK_SIZE_CELLS.y
	)
	return cell_to_world(chunk_cell_origin)


static func snap_to_grid(world_position: Vector2) -> Vector2:
	# Snap any world position to the top-left origin of its logical cell.
	return cell_to_world(world_to_cell(world_position))
