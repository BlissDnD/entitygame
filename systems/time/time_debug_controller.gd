class_name TimeDebugController
extends RefCounted


func build_time_hud_text(time_manager: TimeManager, map_handler: MapHandler) -> String:
	return "H%02d %s" % [
		time_manager.get_current_hour(),
		time_manager.get_room_time_state_name(map_handler.get_current_room_index()),
	]


func build_status_text(map_handler: MapHandler, build_mode_name: String) -> String:
	return "Room %d  %s" % [map_handler.get_current_room_number(), build_mode_name]


func update_hud(ui_root: UIRoot, time_manager: TimeManager, map_handler: MapHandler, build_mode_name: String) -> void:
	if ui_root == null:
		return

	ui_root.set_time_text(build_time_hud_text(time_manager, map_handler))
	ui_root.set_status_text(build_status_text(map_handler, build_mode_name))


func format_sun_room_changed_message(new_room_index: int, sun_visual_position_text: String, player_room_index: int) -> String:
	return "[SunCycle] sun room changed: %d visual position %s player room %d" % [
		new_room_index,
		sun_visual_position_text,
		player_room_index,
	]


func format_room_time_state_changed_message(time_manager: TimeManager, room_index: int, old_state: int, new_state: int) -> String:
	return "[SunCycle] room %d time state changed: %s -> %s" % [
		room_index,
		time_manager.get_time_state_name(old_state),
		time_manager.get_time_state_name(new_state),
	]


func format_player_room_time_state_message(time_manager: TimeManager, new_state: int) -> String:
	return "[SunCycle] player room time state: %s" % time_manager.get_time_state_name(new_state)
