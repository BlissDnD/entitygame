class_name WorldRoomController
extends RefCounted

var room_world_data_list: Array = []
var room_drop_data_list: Array = []
var room_size_cells_list: Array[Vector2i] = []
var room_surface_props_list: Array = []
var room_protected_cells_list: Array = []
var room_placeable_container_list: Array[Node2D] = []
var room_npc_container_list: Array[Node2D] = []
var room_gravity_field_system_list: Array[GravityFieldSystem] = []
var current_room_index: int = 0


func reset() -> void:
	room_world_data_list.clear()
	room_drop_data_list.clear()
	room_size_cells_list.clear()
	room_surface_props_list.clear()
	room_protected_cells_list.clear()
	room_placeable_container_list.clear()
	room_npc_container_list.clear()
	room_gravity_field_system_list.clear()
	current_room_index = 0


func add_room(
	room_size_cells: Vector2i,
	room_world_data,
	room_drop_data: ItemDropData,
	room_surface_props: Array,
	room_protected_cells: Dictionary,
	room_placeable_container: Node2D,
	room_npc_container: Node2D,
	room_gravity_field_system: GravityFieldSystem
) -> void:
	room_size_cells_list.append(room_size_cells)
	room_world_data_list.append(room_world_data)
	room_drop_data_list.append(room_drop_data)
	room_surface_props_list.append(room_surface_props)
	room_protected_cells_list.append(room_protected_cells)
	room_placeable_container_list.append(room_placeable_container)
	room_npc_container_list.append(room_npc_container)
	room_gravity_field_system_list.append(room_gravity_field_system)


func get_room_count() -> int:
	return room_world_data_list.size()


func set_current_room(room_index: int) -> int:
	current_room_index = clampi(room_index, 0, maxi(get_room_count() - 1, 0))
	return current_room_index


func get_current_room_index() -> int:
	return current_room_index


func get_current_room_world_data():
	if current_room_index < 0 or current_room_index >= room_world_data_list.size():
		return null
	return room_world_data_list[current_room_index]


func get_current_room_drop_data() -> ItemDropData:
	if current_room_index < 0 or current_room_index >= room_drop_data_list.size():
		return null
	return room_drop_data_list[current_room_index]


func get_current_room_gravity_field_system() -> GravityFieldSystem:
	if current_room_index < 0 or current_room_index >= room_gravity_field_system_list.size():
		return null
	return room_gravity_field_system_list[current_room_index]


func get_room_size_cells_list() -> Array[Vector2i]:
	return room_size_cells_list


func get_current_room_size_cells(fallback_size_cells: Vector2i = Vector2i.ZERO) -> Vector2i:
	if current_room_index >= 0 and current_room_index < room_size_cells_list.size():
		return room_size_cells_list[current_room_index]
	return fallback_size_cells


func get_current_room_surface_props() -> Array:
	if current_room_index >= 0 and current_room_index < room_surface_props_list.size():
		return room_surface_props_list[current_room_index]
	return []


func get_current_room_protected_cells() -> Dictionary:
	if current_room_index >= 0 and current_room_index < room_protected_cells_list.size():
		return room_protected_cells_list[current_room_index]
	return {}


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
			return mini(current_room_index + 1, maxi(get_room_count() - 1, 0))
		_:
			return current_room_index


func is_outer_left_edge() -> bool:
	return not has_adjacent_room("left")


func is_outer_right_edge() -> bool:
	return not has_adjacent_room("right")


func get_surface_cell_y_for_room(room_size_cells: Vector2i) -> int:
	return maxi(int(floor(float(room_size_cells.y) * 0.5)), 0)


func get_current_room_surface_cell_y(fallback_size_cells: Vector2i = Vector2i.ZERO) -> int:
	return get_surface_cell_y_for_room(get_current_room_size_cells(fallback_size_cells))


func update_room_placeable_visibility() -> void:
	for room_index in range(room_placeable_container_list.size()):
		var room_placeable_container: Node2D = room_placeable_container_list[room_index]
		if room_placeable_container != null:
			room_placeable_container.visible = room_index == current_room_index


func update_room_npc_visibility() -> void:
	for room_index in range(room_npc_container_list.size()):
		var room_npc_container: Node2D = room_npc_container_list[room_index]
		if room_npc_container != null:
			var is_active_room: bool = room_index == current_room_index
			room_npc_container.visible = is_active_room
			room_npc_container.process_mode = Node.PROCESS_MODE_INHERIT if is_active_room else Node.PROCESS_MODE_DISABLED
