class_name WorldBuildMiningFacade
extends RefCounted

const CursorBehaviorDefinitionClass = preload("res://systems/cursor/cursor_behavior_definition.gd")
const BuildModeRuntimeClass = preload("res://systems/build/build_mode_runtime.gd")


func get_target_world_position(mining_runtime: MiningRuntime, player_center_world: Vector2, mouse_world_position: Vector2) -> Vector2:
	return mining_runtime.get_target_world_position(player_center_world, mouse_world_position)


func get_preview_cells(mining_runtime: MiningRuntime, mining_shape: int, mining_center_cell: Vector2i, mining_radius: int) -> Array[Vector2i]:
	return mining_runtime.get_preview_cells(mining_shape, mining_center_cell, mining_radius)


func get_ordered_preview_cells(
	mining_runtime: MiningRuntime,
	mining_shape: int,
	mining_center_cell: Vector2i,
	mining_radius: int,
	player_center_world: Vector2,
	get_cell_center_world: Callable
) -> Array[Vector2i]:
	return mining_runtime.get_ordered_preview_cells(
		mining_shape,
		mining_center_cell,
		mining_radius,
		player_center_world,
		get_cell_center_world
	)


func get_traversal_index(
	mining_runtime: MiningRuntime,
	cell_position: Vector2i,
	mining_shape: int,
	mining_center_cell: Vector2i,
	mining_radius: int,
	player_center_world: Vector2,
	get_cell_center_world: Callable
) -> int:
	return mining_runtime.get_traversal_index(
		cell_position,
		mining_shape,
		mining_center_cell,
		mining_radius,
		player_center_world,
		get_cell_center_world
	)


func is_mining_target_in_range(mining_runtime: MiningRuntime, player_center_world: Vector2, target_center_world: Vector2) -> bool:
	return mining_runtime.is_mining_target_in_range(player_center_world, target_center_world)


func should_show_mining_cone_cursor(player_cursor_controller: PlayerCursorController, is_gravity_build_mode_active: bool) -> bool:
	if is_gravity_build_mode_active:
		return false
	return player_cursor_controller.get_current_cursor_behavior() == CursorBehaviorDefinitionClass.CursorBehavior.MINE_CONE


func should_show_place_cursor(player_cursor_controller: PlayerCursorController, is_gravity_build_mode_active: bool) -> bool:
	if is_gravity_build_mode_active:
		return false
	return player_cursor_controller.get_current_cursor_behavior() == CursorBehaviorDefinitionClass.CursorBehavior.PLACE


func is_gravity_build_mode_active(build_mode_runtime: BuildModeRuntime) -> bool:
	return build_mode_runtime.is_gravity_build_mode_active()


func is_player_inside_gravity_field(world_player_controller: WorldPlayerController, player_world_position: Vector2, gravity_field_system: GravityFieldSystem, get_world_size_from_cells: Callable) -> bool:
	return world_player_controller.is_player_inside_gravity_field(player_world_position, gravity_field_system, get_world_size_from_cells)


func get_gravity_acceleration_at_player(world_player_controller: WorldPlayerController, player_world_position: Vector2, gravity_field_system: GravityFieldSystem, get_world_size_from_cells: Callable) -> Vector2:
	return world_player_controller.get_gravity_acceleration_at_player(player_world_position, gravity_field_system, get_world_size_from_cells)


func set_build_mode(gravity_interaction_controller: GravityInteractionController, build_mode_runtime: BuildModeRuntime, next_build_mode: int) -> Dictionary:
	return gravity_interaction_controller.set_build_mode(build_mode_runtime, next_build_mode)


func clear_build_mode(gravity_interaction_controller: GravityInteractionController, build_mode_runtime: BuildModeRuntime) -> Dictionary:
	return gravity_interaction_controller.clear_build_mode(build_mode_runtime)


func handle_gravity_build_click(
	gravity_interaction_controller: GravityInteractionController,
	build_mode_runtime: BuildModeRuntime,
	mining_center_cell: Vector2i,
	ordered_preview_cells: Array[Vector2i],
	get_gravity_field_preview_rect: Callable,
	get_cell_center_world: Callable
) -> Dictionary:
	return gravity_interaction_controller.handle_gravity_build_click(
		build_mode_runtime,
		mining_center_cell,
		ordered_preview_cells,
		get_gravity_field_preview_rect,
		get_cell_center_world
	)


func get_gravity_field_preview_rect(build_mode_runtime: BuildModeRuntime, mining_center_cell: Vector2i, ordered_preview_cells: Array[Vector2i]) -> Rect2:
	return build_mode_runtime.get_gravity_field_preview_rect(mining_center_cell, ordered_preview_cells)


func get_build_mode_name(build_mode_runtime: BuildModeRuntime) -> String:
	return build_mode_runtime.get_build_mode_name()


func get_gravity_strength_for_level(build_mode_runtime: BuildModeRuntime, level_index: int) -> float:
	return build_mode_runtime.get_gravity_strength_for_level(level_index)


func can_mine_with_equipped_tool(mining_runtime: MiningRuntime, player_equipment: PlayerEquipment, current_cursor_behavior: int, is_gravity_build_mode_active: bool) -> bool:
	return mining_runtime.can_mine_with_equipped_tool(player_equipment, current_cursor_behavior, is_gravity_build_mode_active)


func get_shape_name(mining_runtime: MiningRuntime, shape_type: int) -> String:
	return mining_runtime.get_shape_name(shape_type)


func try_place_preview_cells(mining_runtime: MiningRuntime, context: Dictionary) -> Dictionary:
	return mining_runtime.try_place_preview_cells(context)


func can_place_any_preview_cells(mining_runtime: MiningRuntime, context: Dictionary) -> bool:
	return mining_runtime.can_place_any_preview_cells(context)


func can_place_cell(mining_runtime: MiningRuntime, cell_position: Vector2i, world_data, is_cell_inside_room: Callable, player_contains_cell: Callable) -> bool:
	return mining_runtime.can_place_cell(cell_position, world_data, is_cell_inside_room, player_contains_cell)
