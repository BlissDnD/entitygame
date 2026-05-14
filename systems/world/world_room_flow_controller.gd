class_name WorldRoomFlowController
extends RefCounted


func set_current_room(room_index: int, context: Dictionary) -> Dictionary:
	var current_room_index: int = context.world_room_controller.set_current_room(room_index)
	context.map_handler.set_current_room(current_room_index)

	var world_data = context.world_room_controller.get_current_room_world_data()
	var item_drop_data: ItemDropData = context.world_room_controller.get_current_room_drop_data()
	var gravity_field_system: GravityFieldSystem = context.world_room_controller.get_current_room_gravity_field_system()

	context.set_world_renderer_data.call(world_data)
	context.set_item_drop_data.call(item_drop_data)
	context.set_gravity_field_system.call(gravity_field_system)
	context.clear_build_mode.call()
	context.update_crash_ship_visibility.call()
	context.update_room_placeable_visibility.call()
	context.update_room_npc_visibility.call()
	context.print_world_boundary_debug.call()
	print("[SunCycle] current player room time state: %s" % context.time_manager.get_room_time_state_name(current_room_index))
	context.start_background_fade.call(context.time_manager.get_room_light_color(current_room_index), "room changed")
	context.update_time_hud.call()
	context.refresh_godmode_ui.call()

	return {
		"current_room_index": current_room_index,
		"gravity_field_system": gravity_field_system,
		"item_drop_data": item_drop_data,
		"world_data": world_data,
	}


func try_transition_room(state: Dictionary, context: Dictionary) -> Dictionary:
	if state.room_transition_lock_time > 0.0:
		return {"handled": false}

	var room_edge: String = context.get_room_transition_edge.call()
	if room_edge == context.room_edge_none:
		return {"handled": false}

	var should_transition: bool = context.room_transition_controller.should_transition_for_edge(
		room_edge,
		context.wants_left,
		context.wants_right,
		context.wants_up,
		context.wants_down
	)
	if not should_transition:
		return {"handled": false}

	if room_edge == context.room_edge_top or room_edge == context.room_edge_bottom:
		state.has_won = true
		state.player_velocity = Vector2.ZERO
		context.queue_redraw.call()
		return {"handled": true}

	var next_room_index: int = context.get_adjacent_room_index.call(room_edge)
	if next_room_index == context.current_room_index:
		return {"handled": false}

	print("room transition started from room %d to room %d via %s" % [context.current_room_index, next_room_index, room_edge])
	state.room_transition_lock_time = 0.12
	print("player input locked; player movement disabled")
	context.set_current_room.call(next_room_index)

	var placement_result: Dictionary = place_player_at_room_entry({
		"player_position": state.player_position,
		"player_velocity": state.player_velocity,
	}, {
		"clear_room_entry_at_position": context.clear_room_entry_at_position,
		"clamp_player_to_room": context.clamp_player_to_room,
		"current_position": state.player_position,
		"entry_inset_pixels": context.entry_inset_pixels,
		"exit_edge": room_edge,
		"get_room_world_rect": context.get_room_world_rect,
		"get_world_size_from_cells": context.get_world_size_from_cells,
		"player_size_cells": context.player_size_cells,
		"player_collides_at": context.player_collides_at,
		"resolve_guard_limit": context.resolve_guard_limit,
		"room_edge_left": context.room_edge_left,
		"room_edge_right": context.room_edge_right,
		"room_transition_controller": context.room_transition_controller,
	})
	state.player_position = placement_result.player_position
	state.player_velocity = placement_result.player_velocity

	context.reposition_active_atlas_workers_after_transition.call(room_edge)
	state.hovered_drop_index = -1
	state.has_inspected_cell = false
	context.update_hover_state.call()
	print("transition completed in room %d at %s" % [context.get_current_room_index.call(), state.player_position])
	context.queue_redraw.call()
	return {"handled": true}


func place_player_at_room_entry(state: Dictionary, context: Dictionary) -> Dictionary:
	var room_rect: Rect2 = context.get_room_world_rect.call()
	var player_size: Vector2 = context.get_world_size_from_cells.call(context.player_size_cells)
	var next_position: Vector2 = context.room_transition_controller.get_room_entry_position(
		context.exit_edge,
		room_rect,
		player_size,
		context.entry_inset_pixels,
		context.current_position
	)

	next_position = context.clamp_player_to_room.call(next_position)
	if context.exit_edge == context.room_edge_left or context.exit_edge == context.room_edge_right:
		context.clear_room_entry_at_position.call(next_position)

	state.player_position = next_position
	state.player_velocity = Vector2.ZERO
	resolve_player_after_room_transition(state, context.player_collides_at, context.resolve_guard_limit)
	return state


func resolve_player_after_room_transition(state: Dictionary, player_collides_at: Callable, guard_limit: int) -> void:
	var guard_steps: int = 0

	while player_collides_at.call(state.player_position) and guard_steps < guard_limit:
		state.player_position += Vector2.UP
		guard_steps += 1

	if guard_steps > 0:
		print("player transition collision resolved upward by %d px" % guard_steps)
	if player_collides_at.call(state.player_position):
		print("player transition collision still blocked after resolve guard")


func check_void_fall(state: Dictionary, context: Dictionary) -> Dictionary:
	if state.is_handling_void_fall:
		return {"handled": false}

	var room_rect: Rect2 = context.get_room_world_rect.call()
	var player_rect: Rect2 = Rect2(state.player_position, context.get_world_size_from_cells.call(context.player_size_cells))
	if not context.room_transition_controller.should_trigger_void_fall(
		room_rect,
		player_rect,
		context.void_margin,
		context.void_depth,
		context.is_outer_left_edge,
		context.is_outer_right_edge
	):
		return {"handled": false}

	print(
		"Player fell off the planet edge at %s; void trigger left %.1f right %.1f below %.1f" % [
			state.player_position,
			room_rect.position.x - context.void_margin,
			room_rect.end.x + context.void_margin,
			room_rect.end.y + context.void_depth,
		]
	)
	handle_void_fall(state, context)
	return {"handled": true}


func handle_void_fall(state: Dictionary, context: Dictionary) -> void:
	state.is_handling_void_fall = true
	state.player_velocity = Vector2.ZERO
	state.player_position = context.get_room_spawn_position.call()
	state.player_position = context.snap_player_to_ground.call(state.player_position)
	context.update_hover_state.call()
	print("Player respawned from void at %s" % [state.player_position])
	state.is_handling_void_fall = false


func print_world_boundary_debug(context: Dictionary) -> void:
	var room_rect: Rect2 = context.get_room_world_rect.call()
	var void_rect: Rect2 = context.get_void_fall_rect.call()
	print(
		"World horizontal bounds room %d: left %.1f right %.1f; outer left %s outer right %s; void trigger left %.1f right %.1f below %.1f" % [
			context.current_room_index,
			room_rect.position.x,
			room_rect.end.x,
			str(context.is_outer_left_edge),
			str(context.is_outer_right_edge),
			void_rect.position.x,
			void_rect.end.x,
			void_rect.end.y,
		]
	)
