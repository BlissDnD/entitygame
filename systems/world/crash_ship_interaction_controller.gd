class_name CrashShipInteractionController
extends RefCounted

const GameplayTuningClass = preload("res://systems/config/gameplay_tuning.gd")
const WorldUtilsClass = preload("res://systems/world/world_utils.gd")


func get_room_spawn_position(
	current_room_index: int,
	crash_ship: CrashShip,
	room_rect: Rect2,
	player_size: Vector2,
	current_room_surface_cell_y: int
) -> Vector2:
	if current_room_index == 0 and crash_ship != null and crash_ship.visible:
		return crash_ship.get_spawn_position()

	var spawn_center_x: float = room_rect.position.x + (room_rect.size.x * 0.5)
	var spawn_top_y: float = WorldUtilsClass.cell_to_world(Vector2i(0, current_room_surface_cell_y)).y - player_size.y
	return Vector2(spawn_center_x - (player_size.x * 0.5), spawn_top_y)


func place_crash_ship_in_starting_room(crash_ship: CrashShip, room_rect: Rect2, current_room_surface_cell_y: int) -> void:
	if crash_ship == null:
		return

	var surface_world_y: float = WorldUtilsClass.cell_to_world(Vector2i(0, current_room_surface_cell_y)).y
	crash_ship.position = Vector2(room_rect.position.x + (room_rect.size.x * 0.5) - 96.0, surface_world_y - 4.0)


func update_crash_ship_visibility(crash_ship: CrashShip, current_room_index: int) -> void:
	if crash_ship == null:
		return

	crash_ship.visible = current_room_index == 0


func try_interact_with_crash_ship(crash_ship: CrashShip, current_room_index: int, player_rect: Rect2) -> bool:
	if current_room_index != 0:
		return false
	if crash_ship == null or not crash_ship.visible:
		return false
	if not crash_ship.overlaps_world_rect(player_rect):
		return false

	crash_ship.interact()
	return true
