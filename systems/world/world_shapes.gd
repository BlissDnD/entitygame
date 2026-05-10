class_name WorldShapes
extends RefCounted

const WorldConstantsClass = preload("res://systems/world/world_constants.gd")


static func get_cells_in_square(center_cell: Vector2i, radius: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []

	for x in range(center_cell.x - radius, center_cell.x + radius + 1):
		for y in range(center_cell.y - radius, center_cell.y + radius + 1):
			cells.append(Vector2i(x, y))

	return cells


static func get_cells_in_circle(center_cell: Vector2i, radius: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var radius_squared := radius * radius

	for x in range(center_cell.x - radius, center_cell.x + radius + 1):
		for y in range(center_cell.y - radius, center_cell.y + radius + 1):
			var offset := Vector2i(x, y) - center_cell
			if (offset.x * offset.x) + (offset.y * offset.y) <= radius_squared:
				cells.append(Vector2i(x, y))

	return cells


static func get_cells_in_shape(shape_type: int, center_cell: Vector2i, radius: int) -> Array[Vector2i]:
	match shape_type:
		WorldConstantsClass.ToolShape.CIRCLE:
			return get_cells_in_circle(center_cell, radius)
		_:
			return get_cells_in_square(center_cell, radius)
