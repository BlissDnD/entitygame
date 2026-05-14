class_name WorldStateSyncFacade
extends RefCounted


func apply_room_transition_state(target, state: Dictionary) -> void:
	target.has_inspected_cell = bool(state.has_inspected_cell)
	target.has_won = bool(state.has_won)
	target.hovered_drop_index = int(state.hovered_drop_index)
	target.player_world_position = state.player_position
	target.player_velocity = state.player_velocity
	target.room_transition_lock_time = float(state.room_transition_lock_time)


func apply_void_fall_state(target, state: Dictionary) -> void:
	target.is_handling_void_fall = bool(state.is_handling_void_fall)
	target.player_world_position = state.player_position
	target.player_velocity = state.player_velocity


func set_active_item_drop_data(target, next_item_drop_data: ItemDropData) -> void:
	target.item_drop_data = next_item_drop_data
	target.runtime.item_drop_data = next_item_drop_data
	target.item_interaction_controller.set_item_drop_data(next_item_drop_data)


func set_active_gravity_field_system(target, next_gravity_field_system: GravityFieldSystem) -> void:
	target.gravity_field_system = next_gravity_field_system
	target.runtime.gravity_field_system = next_gravity_field_system
	target.build_mode_runtime.set_gravity_field_system(next_gravity_field_system)


func sync_player_to_ground_after_respawn(target, next_player_position: Vector2, snap_player_to_ground: Callable) -> Vector2:
	target.player_world_position = next_player_position
	target.runtime.player_world_position = next_player_position
	snap_player_to_ground.call()
	return target.player_world_position


func set_player_world_position(target, next_player_world_position: Vector2) -> void:
	target.player_world_position = next_player_world_position
	target.runtime.player_world_position = next_player_world_position


func set_world_spawn_controller(target, next_world_spawn_controller: WorldSpawnController) -> void:
	target.world_spawn_controller = next_world_spawn_controller


func set_player_velocity(target, next_player_velocity: Vector2) -> void:
	target.player_velocity = next_player_velocity
