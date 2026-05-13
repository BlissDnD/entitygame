class_name MapHandler
extends Node

signal room_changed(room_index)
signal map_rebuilt

const WorldConstantsClass = preload("res://systems/world/world_constants.gd")
const WorldUtilsClass = preload("res://systems/world/world_utils.gd")

var current_room_index: int = 0
var room_size_cells_list: Array[Vector2i] = []
var astar: AStar2D = AStar2D.new()


func configure_rooms(room_sizes: Array[Vector2i]) -> void:
	room_size_cells_list = room_sizes.duplicate()
	current_room_index = clampi(current_room_index, 0, maxi(room_size_cells_list.size() - 1, 0))
	map_rebuilt.emit()


func set_current_room(room_index: int) -> void:
	var next_room_index: int = clampi(room_index, 0, maxi(room_size_cells_list.size() - 1, 0))
	if next_room_index == current_room_index:
		return

	current_room_index = next_room_index
	room_changed.emit(current_room_index)


func get_current_room_size_cells() -> Vector2i:
	if room_size_cells_list.is_empty():
		return Vector2i.ZERO

	return room_size_cells_list[current_room_index]


func get_current_room_world_rect() -> Rect2:
	return Rect2(Vector2.ZERO, get_world_size_from_cells(get_current_room_size_cells()))


func get_room_count() -> int:
	return room_size_cells_list.size()


func get_current_room_index() -> int:
	return current_room_index


func get_current_room_number() -> int:
	return current_room_index + 1


func get_display_room_count() -> int:
	return maxi(get_room_count(), 1)


func has_adjacent_room(room_edge: String) -> bool:
	return get_adjacent_room_index(room_edge) != current_room_index


func get_adjacent_room_index(room_edge: String) -> int:
	match room_edge:
		"left":
			return maxi(current_room_index - 1, 0)
		"right":
			return mini(current_room_index + 1, maxi(room_size_cells_list.size() - 1, 0))
		_:
			return current_room_index


func is_outer_left_edge() -> bool:
	return not has_adjacent_room("left")


func is_outer_right_edge() -> bool:
	return not has_adjacent_room("right")


func get_world_size_from_cells(size_cells: Vector2i) -> Vector2:
	return Vector2(
		size_cells.x * WorldConstantsClass.CELL_SIZE.x,
		size_cells.y * WorldConstantsClass.CELL_SIZE.y
	)


func world_to_cell(world_position: Vector2) -> Vector2i:
	return WorldUtilsClass.world_to_cell(world_position)


func cell_to_world(cell_position: Vector2i) -> Vector2:
	return WorldUtilsClass.cell_to_world(cell_position)


func rebuild_navigation(_solid_cells: Dictionary) -> void:
	astar.clear()
	# TODO: Populate AStar2D once the tile query surface is owned by this handler.
	map_rebuilt.emit()
