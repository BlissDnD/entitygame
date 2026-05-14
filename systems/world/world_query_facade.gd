class_name WorldQueryFacade
extends RefCounted

const WorldConstantsClass = preload("res://systems/world/world_constants.gd")
const WorldUtilsClass = preload("res://systems/world/world_utils.gd")


func get_room_world_rect(map_handler: MapHandler) -> Rect2:
	return map_handler.get_current_room_world_rect()


func get_void_fall_rect(room_transition_controller: RoomTransitionController, room_rect: Rect2, void_margin: float, void_depth: float) -> Rect2:
	return room_transition_controller.get_void_fall_rect(room_rect, void_margin, void_depth)


func is_cell_inside_room(room_size_cells: Vector2i, cell_position: Vector2i) -> bool:
	return cell_position.x >= 0 and cell_position.y >= 0 and cell_position.x < room_size_cells.x and cell_position.y < room_size_cells.y


func get_view_origin_world(camera_center_world: Vector2, viewport_world_size: Vector2) -> Vector2:
	return camera_center_world - (viewport_world_size * 0.5)


func get_camera_center_world(room_rect: Rect2, viewport_world_size: Vector2, void_camera_margin: float, is_outer_left_edge: bool, is_outer_right_edge: bool, player_center_world: Vector2) -> Vector2:
	var half_view_size: Vector2 = viewport_world_size * 0.5
	var min_center: Vector2 = room_rect.position + half_view_size
	var max_center: Vector2 = room_rect.end - half_view_size
	if is_outer_left_edge:
		min_center.x -= void_camera_margin
	if is_outer_right_edge:
		max_center.x += void_camera_margin
	return Vector2(
		clampf(player_center_world.x, min_center.x, max_center.x),
		clampf(player_center_world.y, min_center.y, max_center.y)
	)


func get_viewport_world_size(target_internal_resolution: Vector2i) -> Vector2:
	return Vector2(target_internal_resolution)


func get_target_internal_resolution(viewport_size: Vector2, target_world_width: float) -> Vector2i:
	var viewport_width: float = maxf(viewport_size.x, 1.0)
	var viewport_height: float = maxf(viewport_size.y, 1.0)
	var aspect_ratio: float = viewport_height / viewport_width
	var target_world_height: float = target_world_width * aspect_ratio
	return Vector2i(int(round(target_world_width)), int(round(target_world_height)))


func get_current_room_size_cells(world_room_controller: WorldRoomController, fallback_size_cells: Vector2i) -> Vector2i:
	return world_room_controller.get_current_room_size_cells(fallback_size_cells)


func get_current_room_surface_props(world_room_controller: WorldRoomController) -> Array:
	return world_room_controller.get_current_room_surface_props()


func get_current_room_protected_cells(world_room_controller: WorldRoomController) -> Dictionary:
	return world_room_controller.get_current_room_protected_cells()


func get_surface_cell_y_for_room(world_room_controller: WorldRoomController, room_size_cells: Vector2i) -> int:
	return world_room_controller.get_surface_cell_y_for_room(room_size_cells)


func get_current_room_surface_cell_y(world_room_controller: WorldRoomController, fallback_size_cells: Vector2i) -> int:
	return world_room_controller.get_current_room_surface_cell_y(fallback_size_cells)


func get_player_center_world(world_player_controller: WorldPlayerController, player_world_position: Vector2) -> Vector2:
	return world_player_controller.get_player_center_world(player_world_position, Callable(self, "get_world_size_from_cells"))


func get_player_world_rect(world_player_controller: WorldPlayerController, player_world_position: Vector2) -> Rect2:
	return world_player_controller.get_player_world_rect(player_world_position, Callable(self, "get_world_size_from_cells"))


func get_player_ground_world(world_player_controller: WorldPlayerController, player_world_position: Vector2) -> Vector2:
	return world_player_controller.get_player_ground_world(player_world_position, Callable(self, "get_world_size_from_cells"))


func get_cell_center_world(cell_position: Vector2i, cell_size: Vector2i) -> Vector2:
	return WorldUtilsClass.cell_to_world(cell_position) + (Vector2(cell_size) * 0.5)


func get_world_size_from_cells(size_cells: Vector2i, cell_size: Vector2i = WorldConstantsClass.CELL_SIZE) -> Vector2:
	return Vector2(size_cells.x * cell_size.x, size_cells.y * cell_size.y)
