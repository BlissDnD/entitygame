class_name WorldCollisionSurfaceFacade
extends RefCounted

const WorldConstantsClass = preload("res://systems/world/world_constants.gd")
const WorldUtilsClass = preload("res://systems/world/world_utils.gd")


func player_collides_at(world_data, test_position: Vector2, player_size: Vector2, rocks_collide_with_rect: Callable) -> bool:
	var player_rect: Rect2 = Rect2(test_position, player_size)
	return world_data.intersects_solid_rect(player_rect) or rocks_collide_with_rect.call(player_rect)


func is_cell_mining_protected(protected_cells: Dictionary, cell_position: Vector2i) -> bool:
	return protected_cells.has(cell_position)


func rocks_collide_with_rect(surface_props: Array, test_rect: Rect2, get_surface_prop_collision_rect: Callable, surface_prop_rock: String) -> bool:
	for prop_entry in surface_props:
		if String(prop_entry.get("type", "")) != surface_prop_rock:
			continue
		if get_surface_prop_collision_rect.call(prop_entry).intersects(test_rect):
			return true
	return false


func get_surface_prop_collision_rect(prop_entry: Dictionary, get_world_size_from_cells: Callable) -> Rect2:
	var base_cell: Vector2i = Vector2i(prop_entry.get("base_cell", Vector2i.ZERO))
	var width_cells: int = int(prop_entry.get("width_cells", prop_entry.get("footprint_width_cells", 1)))
	var height_cells: int = int(prop_entry.get("height_cells", 1))
	var base_world: Vector2 = WorldUtilsClass.cell_to_world(base_cell)
	var prop_size: Vector2 = get_world_size_from_cells.call(Vector2i(width_cells, height_cells))
	return Rect2(Vector2(base_world.x, base_world.y - prop_size.y), prop_size)


func clear_room_entry_at_position(
	entry_position: Vector2,
	room_transition_controller: RoomTransitionController,
	world_data,
	room_rect: Rect2,
	player_size: Vector2,
	side_padding: float,
	top_padding: float,
	is_cell_inside_room: Callable
) -> void:
	var clear_rect: Rect2 = room_transition_controller.build_room_entry_clear_rect(
		entry_position,
		room_rect,
		player_size,
		side_padding,
		top_padding
	)

	var start_cell: Vector2i = WorldUtilsClass.world_to_cell(clear_rect.position)
	var end_cell: Vector2i = WorldUtilsClass.world_to_cell(clear_rect.end - Vector2.ONE)

	for cell_y in range(start_cell.y, end_cell.y + 1):
		for cell_x in range(start_cell.x, end_cell.x + 1):
			var cell_position: Vector2i = Vector2i(cell_x, cell_y)
			if is_cell_inside_room.call(cell_position):
				world_data.remove_cell(cell_position)
				world_data.remove_damage_progress(cell_position)


func clamp_player_to_room(
	room_transition_controller: RoomTransitionController,
	next_position: Vector2,
	room_rect: Rect2,
	player_size: Vector2,
	is_outer_left_edge: bool,
	is_outer_right_edge: bool
) -> Vector2:
	return room_transition_controller.clamp_player_to_room(
		next_position,
		room_rect,
		player_size,
		is_outer_left_edge,
		is_outer_right_edge
	)


func is_position_beyond_outer_horizontal_edge(
	room_transition_controller: RoomTransitionController,
	position: Vector2,
	room_rect: Rect2,
	player_size: Vector2,
	is_outer_left_edge: bool,
	is_outer_right_edge: bool
) -> bool:
	return room_transition_controller.is_position_beyond_outer_horizontal_edge(
		position,
		room_rect,
		player_size,
		is_outer_left_edge,
		is_outer_right_edge
	)
