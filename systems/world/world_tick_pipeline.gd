class_name WorldTickPipeline
extends RefCounted


func process(delta: float, state: Dictionary, context: Dictionary) -> Dictionary:
	var should_redraw: bool = false
	if context.background_controller.update(delta):
		should_redraw = true
	if context.time_manager.advance(delta):
		should_redraw = true
		context.refresh_godmode_ui.call()

	var was_transition_locked: bool = state.room_transition_lock_time > 0.0
	state.room_transition_lock_time = maxf(state.room_transition_lock_time - delta, 0.0)
	if was_transition_locked and state.room_transition_lock_time <= 0.0:
		print("player input unlocked; player movement enabled")

	if not context.is_console_open.call() and not state.has_won and state.room_transition_lock_time <= 0.0:
		if context.update_player.call(delta):
			should_redraw = true
		if update_item_drops(delta, context):
			should_redraw = true
		if context.update_mining.call(delta):
			should_redraw = true
	elif state.room_transition_lock_time > 0.0:
		context.set_player_velocity.call(Vector2.ZERO)

	if update_hover_state(state, context):
		should_redraw = true

	if context.check_void_fall.call():
		should_redraw = true
	elif context.try_transition_room.call():
		should_redraw = true

	context.update_player_follow_target.call()
	context.update_active_atlas_worker_grounding.call()
	apply_camera_tracking(context)

	return {"should_redraw": should_redraw}


func update_item_drops(delta: float, context: Dictionary) -> bool:
	return context.item_interaction_controller.update_item_drops(
		context.world_data,
		delta,
		context.get_room_world_rect.call(),
		context.dropped_item_gravity,
		context.dropped_item_pull_radius_pixels,
		context.dropped_item_merge_radius_pixels,
		context.gravity_field_system
	)


func update_hover_state(state: Dictionary, context: Dictionary) -> bool:
	var next_hovered_cell: Vector2i = context.world_to_cell.call(context.mouse_world_position.call())
	var next_mining_center_cell: Vector2i = context.world_to_cell.call(context.get_target_world_position.call())
	var next_hovered_drop_index: int = context.item_interaction_controller.find_hovered_drop_index(
		context.mouse_world_position.call(),
		context.drop_hover_radius_pixels
	)

	if next_hovered_cell == state.hovered_cell and next_mining_center_cell == state.mining_center_cell and next_hovered_drop_index == state.hovered_drop_index:
		return false

	state.hovered_cell = next_hovered_cell
	state.mining_center_cell = next_mining_center_cell
	state.hovered_drop_index = next_hovered_drop_index
	return true


func apply_camera_tracking(context: Dictionary) -> void:
	context.apply_view_resolution.call()
	context.camera_2d.zoom = Vector2.ONE
	context.camera_2d.position = context.get_camera_center_world.call()
	context.camera_2d.rotation = 0.0
