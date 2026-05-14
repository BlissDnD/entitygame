class_name WorldInputInteractionController
extends RefCounted


func handle_unhandled_input(event: InputEvent, state: Dictionary, context: Dictionary) -> Dictionary:
	if event.is_action_pressed("toggle_console"):
		context.toggle_console.call()
		return {"input_handled": true}

	if context.is_console_open.call():
		return {"input_handled": false}

	if event.is_action_pressed("interact"):
		if try_interact(state, context):
			return {
				"input_handled": true,
				"queue_redraw": true,
			}
		return {"input_handled": false}

	if event.is_action_pressed("drop_backpack"):
		drop_equipped_backpack(context)
		return {
			"input_handled": true,
			"queue_redraw": true,
		}

	if event is InputEventMouseButton and event.pressed:
		return _handle_mouse_button_event(event, state, context)

	return {"input_handled": false}


func try_interact(state: Dictionary, context: Dictionary) -> bool:
	if _try_interact_with_backpack_world_item(state, context):
		return true
	return _try_interact_with_crash_ship(context)


func drop_equipped_backpack(context: Dictionary) -> void:
	if context.item_interaction_controller.drop_equipped_backpack(
		context.get_player_ground_world.call(),
		context.move_left_pressed,
		context.backpack_world_item_scene
	):
		context.refresh_godmode_ui.call()


func try_pick_up_hovered_drops(state: Dictionary, context: Dictionary) -> bool:
	var result: Dictionary = context.item_interaction_controller.try_pick_up_hovered_drop(
		state.hovered_drop_index,
		context.mouse_world_position,
		context.drop_hover_radius_pixels
	)
	var picked_any: bool = bool(result.get("picked_any", false))
	if picked_any:
		state.hovered_drop_index = int(result.get("hovered_drop_index", state.hovered_drop_index))
		context.refresh_godmode_ui.call()

	return picked_any


func cycle_selected_material(direction: int, context: Dictionary) -> void:
	if context.inventory_runtime.cycle_selected_material(direction):
		context.refresh_godmode_ui.call()


func _try_interact_with_backpack_world_item(state: Dictionary, context: Dictionary) -> bool:
	var player_rect: Rect2 = Rect2(
		context.player_world_position,
		context.get_world_size_from_cells.call(context.player_size_cells)
	)
	var result: Dictionary = context.item_interaction_controller.try_interact_with_backpack_world_item(player_rect)
	if bool(result.get("did_change_inventory", false)):
		context.refresh_godmode_ui.call()
	return bool(result.get("handled", false))


func _try_interact_with_crash_ship(context: Dictionary) -> bool:
	var player_rect: Rect2 = Rect2(
		context.player_world_position,
		context.get_world_size_from_cells.call(context.player_size_cells)
	)
	return context.crash_ship_interaction_controller.try_interact_with_crash_ship(
		context.crash_ship,
		context.current_room_index,
		player_rect
	)


func _handle_mouse_button_event(event: InputEventMouseButton, state: Dictionary, context: Dictionary) -> Dictionary:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if context.is_pointer_over_debug_ui.call():
			return {"input_handled": false}
		if context.is_gravity_build_mode_active.call():
			context.handle_gravity_build_click.call()
			return {
				"input_handled": true,
				"queue_redraw": true,
			}
		if try_pick_up_hovered_drops(state, context):
			state.block_mining_until_left_released = true
			return {"queue_redraw": true}
		return {"queue_redraw": true}

	if event.button_index == MOUSE_BUTTON_RIGHT:
		if context.is_pointer_over_debug_ui.call():
			return {"input_handled": false}
		if context.is_gravity_build_mode_active.call():
			context.clear_build_mode.call()
			return {
				"input_handled": true,
				"queue_redraw": true,
			}
		if context.should_show_place_cursor.call() and context.try_place_preview_cells.call():
			return {"queue_redraw": true}
		return {"input_handled": false}

	if event.button_index == MOUSE_BUTTON_MIDDLE:
		if context.is_pointer_over_debug_ui.call():
			return {"input_handled": false}
		state.has_inspected_cell = true
		state.inspected_cell = state.hovered_cell
		return {"queue_redraw": true}

	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		if context.is_pointer_over_debug_ui.call():
			return {"input_handled": false}
		cycle_selected_material(-1, context)
		return {"queue_redraw": true}

	if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		if context.is_pointer_over_debug_ui.call():
			return {"input_handled": false}
		cycle_selected_material(1, context)
		return {"queue_redraw": true}

	return {"input_handled": false}
