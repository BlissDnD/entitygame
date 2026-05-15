class_name WorldSceneOperationHelpers
extends RefCounted


func update_player(scene, delta: float) -> bool:
	var player_state := {
		"position": scene.player_world_position,
		"velocity": scene.player_velocity,
	}
	var moved: bool = scene.world_player_controller.update(delta, player_state, {
		"clamp_player_to_room": func(next_position):
			return scene.world_collision_surface_facade.clamp_player_to_room(
				scene.room_transition_controller,
				next_position,
				scene.world_query_facade.get_room_world_rect(scene.map_handler),
				get_world_size_from_cells(scene, scene.GameplayTuningClass.PLAYER_SIZE_CELLS),
				scene.world_room_controller.is_outer_left_edge(),
				scene.world_room_controller.is_outer_right_edge()
			),
		"collides_at": Callable(scene, "_player_collides_at"),
		"get_world_size_from_cells": func(size_cells): return get_world_size_from_cells(scene, size_cells),
		"gravity_field_system": scene.gravity_field_system,
	})
	scene.player_world_position = player_state.position
	scene.player_velocity = player_state.velocity
	return moved


func update_mining(scene, delta: float) -> bool:
	var result: Dictionary = scene.mining_runtime.update(delta, {
		"block_mining_until_left_released": scene.block_mining_until_left_released,
		"has_printed_missing_warning": scene.has_printed_missing_mining_tool_warning,
	}, {
		"active_tool_profile": scene.active_tool_profile,
		"current_cursor_behavior": scene.player_cursor_controller.get_current_cursor_behavior(),
		"debug_settings": scene.debug_settings,
		"get_cell_center_world": func(cell_position): return get_cell_center_world(scene, cell_position),
		"inventory_data": scene.inventory_data,
		"is_cell_mining_protected": func(cell_position):
			return scene.world_collision_surface_facade.is_cell_mining_protected(
				scene.world_query_facade.get_current_room_protected_cells(scene.world_room_controller),
				cell_position
			),
		"is_gravity_build_mode_active": scene.world_build_mining_facade.is_gravity_build_mode_active(scene.build_mode_runtime),
		"is_pointer_over_debug_ui": scene.godmode_ui_controller.is_pointer_over_debug_ui(scene.get_viewport().get_mouse_position()),
		"item_drop_data": scene.item_drop_data,
		"mining_power": scene.debug_settings.mining_power,
		"ordered_preview_cells": get_ordered_preview_cells(scene),
		"player_center_world": get_player_center_world(scene),
		"player_equipment": scene.player_equipment,
		"target_center_world": get_cell_center_world(scene, scene.mining_center_cell),
		"world_data": scene.world_data,
	})
	scene.block_mining_until_left_released = bool(result.get("block_mining_until_left_released", scene.block_mining_until_left_released))
	scene.has_printed_missing_mining_tool_warning = bool(result.get("has_printed_missing_warning", scene.has_printed_missing_mining_tool_warning))
	if bool(result.get("ui_refresh_needed", false)):
		scene.godmode_ui_controller.refresh_godmode_ui()
	return bool(result.get("changed", false))


func generate_rooms(scene) -> void:
	scene.world_room_controller.reset()
	scene.inventory_data.clear()
	var empty_room_sizes: Array[Vector2i] = []
	scene.map_handler.configure_rooms(empty_room_sizes)
	scene.has_won = false

	var generated_rooms: Array[Dictionary] = scene.world_generation_surface_controller.generate_rooms({
		"active_room_index": scene.world_room_controller.get_current_room_index(),
		"create_atlas_worker_spawn_point": func(room_index, room_size_cells, room_npc_container):
			scene.world_support_facade.create_atlas_worker_spawn_point_for_room(
				scene.world_spawn_controller,
				scene.AtlasWorkerSpawnPointScene,
				room_index,
				room_size_cells,
				room_npc_container,
				scene.GameplayTuningClass.SURFACE_PROP_EDGE_MARGIN_CELLS,
				scene.world_query_facade.get_surface_cell_y_for_room(scene.world_room_controller, room_size_cells)
			),
		"get_surface_cell_y_for_room": func(room_size_cells): return scene.world_query_facade.get_surface_cell_y_for_room(scene.world_room_controller, room_size_cells),
		"gravity_field_system_class": scene.GravityFieldSystemClass,
		"item_drop_data_class": scene.ItemDropDataClass,
		"npc_objects": scene.npc_objects,
		"persistent_followers": scene.persistent_followers,
		"placeable_objects": scene.placeable_objects,
		"prototype_tree_definition": scene.PrototypeTreeDefinition,
		"room_count": scene.GameplayTuningClass.ROOM_COUNT,
		"room_rng": scene.room_rng,
		"surface_prop_bush": scene.SURFACE_PROP_BUSH,
		"surface_prop_rock": scene.SURFACE_PROP_ROCK,
		"viewport_world_size": scene.world_query_facade.get_viewport_world_size(scene.world_query_facade.get_target_internal_resolution(scene.get_viewport_rect().size, scene.GameplayTuningClass.CAMERA_VIEW_CELLS_X * scene.WorldConstantsClass.CELL_SIZE.x)),
		"world_data_class": scene.WorldDataClass,
	})

	for room_entry in generated_rooms:
		scene.world_room_controller.add_room(
			Vector2i(room_entry.get("room_size_cells", Vector2i.ZERO)),
			room_entry.get("world_data", null),
			room_entry.get("drop_data", null),
			room_entry.get("surface_props", []),
			room_entry.get("protected_cells", {}),
			room_entry.get("placeable_container", null),
			room_entry.get("npc_container", null),
			room_entry.get("gravity_field_system", null)
		)
	scene.map_handler.configure_rooms(scene.world_room_controller.get_room_size_cells_list())


func set_current_room(scene, room_index: int) -> void:
	var result: Dictionary = scene.world_room_flow_controller.set_current_room(room_index, {
		"clear_build_mode": func(): clear_build_mode(scene),
		"map_handler": scene.map_handler,
		"print_world_boundary_debug": func():
			scene.world_room_flow_controller.print_world_boundary_debug({
				"current_room_index": scene.map_handler.get_current_room_index(),
				"get_room_world_rect": func(): return scene.world_query_facade.get_room_world_rect(scene.map_handler),
				"get_void_fall_rect": func():
					return scene.world_query_facade.get_void_fall_rect(
						scene.room_transition_controller,
						scene.world_query_facade.get_room_world_rect(scene.map_handler),
						scene.GameplayTuningClass.VOID_FALL_MARGIN_CELLS * scene.WorldConstantsClass.CELL_SIZE.x,
						scene.GameplayTuningClass.VOID_FALL_DEPTH_CELLS * scene.WorldConstantsClass.CELL_SIZE.y
					),
				"is_outer_left_edge": scene.world_room_controller.is_outer_left_edge(),
				"is_outer_right_edge": scene.world_room_controller.is_outer_right_edge(),
			}),
		"refresh_godmode_ui": Callable(scene.godmode_ui_controller, "refresh_godmode_ui"),
		"set_gravity_field_system": func(next_gravity_field_system): scene.world_state_sync_facade.set_active_gravity_field_system(scene, next_gravity_field_system),
		"set_item_drop_data": func(next_item_drop_data): scene.world_state_sync_facade.set_active_item_drop_data(scene, next_item_drop_data),
		"set_world_renderer_data": Callable(scene.world_renderer, "set_world_data"),
		"start_background_fade": Callable(scene, "_start_background_fade"),
		"time_manager": scene.time_manager,
		"update_crash_ship_visibility": func(): update_crash_ship_visibility(scene),
		"update_room_npc_visibility": func(): scene.world_support_facade.update_room_npc_visibility(scene.world_room_controller),
		"update_room_placeable_visibility": func(): scene.world_support_facade.update_room_placeable_visibility(scene.world_room_controller),
		"update_time_hud": Callable(scene.godmode_ui_controller, "update_time_hud"),
		"world_room_controller": scene.world_room_controller,
	})
	scene.world_data = result.world_data
	scene.item_drop_data = result.item_drop_data
	scene.gravity_field_system = result.gravity_field_system


func get_room_spawn_position(scene) -> Vector2:
	return scene.crash_ship_interaction_controller.get_room_spawn_position(
		scene.world_room_controller.get_current_room_index(),
		scene.crash_ship,
		scene.world_query_facade.get_room_world_rect(scene.map_handler),
		get_world_size_from_cells(scene, scene.GameplayTuningClass.PLAYER_SIZE_CELLS),
		scene.world_query_facade.get_current_room_surface_cell_y(scene.world_room_controller, scene.GameplayTuningClass.ROOM_MIN_SIZE_CELLS)
	)


func place_crash_ship_in_starting_room(scene) -> void:
	scene.world_support_facade.place_crash_ship_in_starting_room(
		scene.crash_ship_interaction_controller,
		scene.crash_ship,
		scene.world_query_facade.get_room_world_rect(scene.map_handler),
		scene.world_query_facade.get_current_room_surface_cell_y(scene.world_room_controller, scene.GameplayTuningClass.ROOM_MIN_SIZE_CELLS),
		func(): update_crash_ship_visibility(scene)
	)


func update_crash_ship_visibility(scene) -> void:
	scene.world_support_facade.update_crash_ship_visibility(scene.crash_ship_interaction_controller, scene.crash_ship, scene.world_room_controller.get_current_room_index())


func spawn_initial_backpack_world_item(scene) -> void:
	scene.world_support_facade.spawn_initial_backpack_world_item(scene.item_interaction_controller, get_player_ground_world(scene), scene.BasicBackpackItemDefinition, scene.BackpackWorldItemScene)


func equip_backpack_item(scene, item_definition: ItemDefinition, log_prefix: String) -> bool:
	return scene.world_support_facade.equip_backpack_item(scene.inventory_runtime, item_definition, log_prefix, Callable(scene.godmode_ui_controller, "refresh_godmode_ui"))


func try_transition_room(scene) -> bool:
	var state := {
		"has_inspected_cell": scene.has_inspected_cell,
		"has_won": scene.has_won,
		"hovered_drop_index": scene.hovered_drop_index,
		"player_position": scene.player_world_position,
		"player_velocity": scene.player_velocity,
		"room_transition_lock_time": scene.room_transition_lock_time,
	}
	var result: Dictionary = scene.world_room_flow_controller.try_transition_room(state, {
		"clear_room_entry_at_position": func(entry_position):
			scene.world_collision_surface_facade.clear_room_entry_at_position(
				entry_position,
				scene.room_transition_controller,
				scene.world_data,
				scene.world_query_facade.get_room_world_rect(scene.map_handler),
				get_world_size_from_cells(scene, scene.GameplayTuningClass.PLAYER_SIZE_CELLS),
				float(scene.WorldConstantsClass.CELL_SIZE.x),
				float(scene.WorldConstantsClass.CELL_SIZE.y * 2),
				func(cell_position): return scene.world_query_facade.is_cell_inside_room(scene.world_query_facade.get_current_room_size_cells(scene.world_room_controller, scene.GameplayTuningClass.ROOM_MIN_SIZE_CELLS), cell_position)
			),
		"clamp_player_to_room": func(next_position):
			return scene.world_collision_surface_facade.clamp_player_to_room(
				scene.room_transition_controller,
				next_position,
				scene.world_query_facade.get_room_world_rect(scene.map_handler),
				get_world_size_from_cells(scene, scene.GameplayTuningClass.PLAYER_SIZE_CELLS),
				scene.world_room_controller.is_outer_left_edge(),
				scene.world_room_controller.is_outer_right_edge()
			),
		"current_room_index": scene.world_room_controller.get_current_room_index(),
		"entry_inset_pixels": scene.GameplayTuningClass.ROOM_ENTRY_INSET_CELLS * scene.WorldConstantsClass.CELL_SIZE.x,
		"get_adjacent_room_index": Callable(scene, "_get_adjacent_room_index"),
		"get_current_room_index": Callable(scene.world_room_controller, "get_current_room_index"),
		"get_room_transition_edge": func(): return get_room_transition_edge(scene),
		"get_room_world_rect": func(): return scene.world_query_facade.get_room_world_rect(scene.map_handler),
		"get_world_size_from_cells": func(size_cells): return get_world_size_from_cells(scene, size_cells),
		"player_collides_at": Callable(scene, "_player_collides_at"),
		"player_size_cells": scene.GameplayTuningClass.PLAYER_SIZE_CELLS,
		"queue_redraw": Callable(scene, "queue_redraw"),
		"reposition_active_atlas_workers_after_transition": func(exit_edge):
			scene.world_support_facade.reposition_active_atlas_workers_after_transition(
				scene.world_spawn_controller,
				exit_edge,
				get_player_ground_world(scene)
			),
		"resolve_guard_limit": scene.WorldConstantsClass.CELL_SIZE.y * 8,
		"room_edge_bottom": scene.ROOM_EDGE_BOTTOM,
		"room_edge_left": scene.ROOM_EDGE_LEFT,
		"room_edge_none": scene.ROOM_EDGE_NONE,
		"room_edge_right": scene.ROOM_EDGE_RIGHT,
		"room_edge_top": scene.ROOM_EDGE_TOP,
		"room_transition_controller": scene.room_transition_controller,
		"set_current_room": func(room_index): set_current_room(scene, room_index),
		"update_hover_state": Callable(scene, "_update_hover_state"),
		"wants_down": Input.is_action_pressed("move_down"),
		"wants_left": Input.is_action_pressed("move_left"),
		"wants_right": Input.is_action_pressed("move_right"),
		"wants_up": Input.is_action_pressed("move_up"),
	})
	scene.world_state_sync_facade.apply_room_transition_state(scene, state)
	return bool(result.get("handled", false))


func check_void_fall(scene) -> bool:
	var state := {
		"is_handling_void_fall": scene.is_handling_void_fall,
		"player_position": scene.player_world_position,
		"player_velocity": scene.player_velocity,
	}
	var result: Dictionary = scene.world_room_flow_controller.check_void_fall(state, {
		"get_room_spawn_position": func(): return get_room_spawn_position(scene),
		"get_room_world_rect": func(): return scene.world_query_facade.get_room_world_rect(scene.map_handler),
		"get_world_size_from_cells": func(size_cells): return get_world_size_from_cells(scene, size_cells),
		"is_outer_left_edge": scene.world_room_controller.is_outer_left_edge(),
		"is_outer_right_edge": scene.world_room_controller.is_outer_right_edge(),
		"player_size_cells": scene.GameplayTuningClass.PLAYER_SIZE_CELLS,
		"room_transition_controller": scene.room_transition_controller,
		"snap_player_to_ground": func(next_player_position):
			return scene.world_state_sync_facade.sync_player_to_ground_after_respawn(
				scene,
				next_player_position,
				func():
					var player_state := {"position": scene.player_world_position}
					scene.world_player_controller.snap_player_to_ground(player_state, Callable(scene, "_player_collides_at"))
					scene.player_world_position = player_state.position
			),
		"update_hover_state": Callable(scene, "_update_hover_state"),
		"void_depth": scene.GameplayTuningClass.VOID_FALL_DEPTH_CELLS * scene.WorldConstantsClass.CELL_SIZE.y,
		"void_margin": scene.GameplayTuningClass.VOID_FALL_MARGIN_CELLS * scene.WorldConstantsClass.CELL_SIZE.x,
	})
	scene.world_state_sync_facade.apply_void_fall_state(scene, state)
	return bool(result.get("handled", false))


func get_room_transition_edge(scene) -> String:
	var room_rect: Rect2 = scene.world_query_facade.get_room_world_rect(scene.map_handler)
	var player_rect: Rect2 = Rect2(scene.player_world_position, get_world_size_from_cells(scene, scene.GameplayTuningClass.PLAYER_SIZE_CELLS))
	var margin_pixels: float = scene.GameplayTuningClass.ROOM_TRANSITION_MARGIN_CELLS * scene.WorldConstantsClass.CELL_SIZE.x
	return scene.room_transition_controller.get_room_transition_edge(
		room_rect,
		player_rect,
		margin_pixels,
		scene.world_room_controller.has_adjacent_room(scene.ROOM_EDGE_LEFT),
		scene.world_room_controller.has_adjacent_room(scene.ROOM_EDGE_RIGHT),
		scene.ROOM_EDGE_NONE,
		scene.ROOM_EDGE_LEFT,
		scene.ROOM_EDGE_RIGHT,
		scene.ROOM_EDGE_TOP,
		scene.ROOM_EDGE_BOTTOM
	)


func get_target_world_position(scene) -> Vector2:
	return scene.world_build_mining_facade.get_target_world_position(scene.mining_runtime, get_player_center_world(scene), scene.get_global_mouse_position())


func get_ordered_preview_cells(scene) -> Array[Vector2i]:
	return scene.world_build_mining_facade.get_ordered_preview_cells(scene.mining_runtime, scene.debug_settings.mining_shape, scene.mining_center_cell, scene.debug_settings.mining_radius, get_player_center_world(scene), func(cell_position): return get_cell_center_world(scene, cell_position))


func get_traversal_index(scene, cell_position: Vector2i) -> int:
	return scene.world_build_mining_facade.get_traversal_index(scene.mining_runtime, cell_position, scene.debug_settings.mining_shape, scene.mining_center_cell, scene.debug_settings.mining_radius, get_player_center_world(scene), func(next_cell_position): return get_cell_center_world(scene, next_cell_position))


func should_show_place_cursor(scene) -> bool:
	return scene.world_build_mining_facade.should_show_place_cursor(scene.player_cursor_controller, scene.world_build_mining_facade.is_gravity_build_mode_active(scene.build_mode_runtime))


func set_build_mode(scene, next_build_mode: int) -> void:
	var result: Dictionary = scene.world_build_mining_facade.set_build_mode(scene.gravity_interaction_controller, scene.build_mode_runtime, next_build_mode)
	scene.block_mining_until_left_released = bool(result.get("block_mining_until_left_released", true))
	print("[GodModeGravity] build mode: %s" % String(result.get("build_mode_name", scene.world_build_mining_facade.get_build_mode_name(scene.build_mode_runtime))))
	scene.godmode_ui_controller.update_time_hud()
	scene.godmode_ui_controller.refresh_godmode_ui()
	scene.queue_redraw()


func clear_build_mode(scene) -> void:
	var result: Dictionary = scene.world_build_mining_facade.clear_build_mode(scene.gravity_interaction_controller, scene.build_mode_runtime)
	if not bool(result.get("changed", false)):
		return
	scene.block_mining_until_left_released = bool(result.get("block_mining_until_left_released", true))
	scene.godmode_ui_controller.update_time_hud()
	scene.godmode_ui_controller.refresh_godmode_ui()


func handle_gravity_build_click(scene) -> void:
	var result: Dictionary = scene.world_build_mining_facade.handle_gravity_build_click(scene.gravity_interaction_controller, scene.build_mode_runtime, scene.mining_center_cell, get_ordered_preview_cells(scene), func(): return get_gravity_field_preview_rect(scene), func(cell_position): return get_cell_center_world(scene, cell_position))
	var log_message: String = String(result.get("log_message", ""))
	var click_result: int = int(result.get("click_result", scene.BuildModeRuntimeClass.BuildClickResult.NONE))
	if not log_message.is_empty():
		print(log_message)
	if bool(result.get("block_mining_until_left_released", false)):
		scene.block_mining_until_left_released = true
	if click_result != scene.BuildModeRuntimeClass.BuildClickResult.NONE:
		scene.godmode_ui_controller.update_time_hud()
	if bool(result.get("show_strength_popup", false)):
		scene.godmode_panel.show_gravity_strength_popup()
	scene.godmode_ui_controller.refresh_godmode_ui()


func get_gravity_field_preview_rect(scene) -> Rect2:
	return scene.world_build_mining_facade.get_gravity_field_preview_rect(scene.build_mode_runtime, scene.mining_center_cell, get_ordered_preview_cells(scene))


func get_player_center_world(scene) -> Vector2:
	return scene.world_query_facade.get_player_center_world(scene.world_player_controller, scene.player_world_position)


func get_player_ground_world(scene) -> Vector2:
	return scene.world_query_facade.get_player_ground_world(scene.world_player_controller, scene.player_world_position)


func update_player_follow_target(scene) -> void:
	scene.world_support_facade.update_player_follow_target(scene.world_spawn_controller, get_player_ground_world(scene))


func update_active_atlas_worker_grounding(scene) -> void:
	scene.world_support_facade.update_active_atlas_worker_grounding(scene.world_spawn_controller, get_player_ground_world(scene), scene.WorldConstantsClass.CELL_SIZE.y)


func get_cell_center_world(scene, cell_position: Vector2i) -> Vector2:
	return scene.world_query_facade.get_cell_center_world(cell_position, scene.WorldConstantsClass.CELL_SIZE)


func get_world_size_from_cells(scene, size_cells: Vector2i) -> Vector2:
	return scene.world_query_facade.get_world_size_from_cells(size_cells, scene.WorldConstantsClass.CELL_SIZE)


func try_place_preview_cells(scene) -> bool:
	var result: Dictionary = scene.world_build_mining_facade.try_place_preview_cells(scene.mining_runtime, {
		"inventory_data": scene.inventory_data,
		"is_cell_inside_room": func(cell_position): return scene.world_query_facade.is_cell_inside_room(scene.world_query_facade.get_current_room_size_cells(scene.world_room_controller, scene.GameplayTuningClass.ROOM_MIN_SIZE_CELLS), cell_position),
		"ordered_preview_cells": get_ordered_preview_cells(scene),
		"player_center_world": get_player_center_world(scene),
		"player_contains_cell": func(cell_position): return player_contains_cell(scene, cell_position),
		"selected_material_id": scene.inventory_runtime.selected_material_id,
		"target_center_world": get_cell_center_world(scene, scene.mining_center_cell),
		"world_data": scene.world_data,
	})
	if bool(result.get("ui_refresh_needed", false)):
		scene.godmode_ui_controller.refresh_godmode_ui()
	return bool(result.get("placed_any", false))


func can_place_cell(scene, cell_position: Vector2i) -> bool:
	return scene.world_build_mining_facade.can_place_cell(
		scene.mining_runtime,
		cell_position,
		scene.world_data,
		func(next_cell_position): return scene.world_query_facade.is_cell_inside_room(scene.world_query_facade.get_current_room_size_cells(scene.world_room_controller, scene.GameplayTuningClass.ROOM_MIN_SIZE_CELLS), next_cell_position),
		func(next_cell_position): return player_contains_cell(scene, next_cell_position)
	)


func player_contains_cell(scene, cell_position: Vector2i) -> bool:
	var player_rect: Rect2 = Rect2(scene.player_world_position, get_world_size_from_cells(scene, scene.GameplayTuningClass.PLAYER_SIZE_CELLS))
	var cell_rect: Rect2 = Rect2(scene.WorldUtilsClass.cell_to_world(cell_position), Vector2(scene.WorldConstantsClass.CELL_SIZE))
	return player_rect.intersects(cell_rect)
