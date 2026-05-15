class_name WorldBootstrap
extends RefCounted


func run(context: Dictionary) -> void:
	var refs: WorldSceneRefs = context.refs
	var runtime: WorldRuntime = context.runtime

	runtime.debug_settings.apply_tool_profile(context.active_tool_profile)
	runtime.debug_settings.set_godmode_enabled(context.starts_in_godmode)
	context.background_controller.configure(context.background_fade_duration)
	context.room_rng.randomize()

	_setup_item_debug_components(runtime, context.add_child_callback, context.cursor_behavior_changed_callback)
	_setup_ui_root(refs, runtime)

	context.item_interaction_controller.bind_scene_dependencies(refs.spawn_manager, refs.world_items)
	context.item_interaction_controller.set_interaction_registry(context.interaction_registry)
	context.interaction_registry.register_interactable(refs.crash_ship)
	context.player_hand_interaction_provider.configure({
		"interaction_registry": context.interaction_registry,
	})
	context.interaction_context.configure({
		"crash_ship": refs.crash_ship,
		"crash_ship_interaction_controller": context.crash_ship_interaction_controller,
		"interaction_registry": context.interaction_registry,
		"get_world_size_from_cells": context.get_world_size_from_cells,
		"get_hand_interaction_candidates": Callable(context.player_hand_interaction_provider, "get_candidates"),
		"item_interaction_controller": context.item_interaction_controller,
		"inventory_runtime": runtime.inventory_runtime,
		"player_equipment": runtime.player_equipment,
		"player_cursor_controller": runtime.player_cursor_controller,
		"refresh_godmode_ui": Callable(context.godmode_ui_controller, "refresh_godmode_ui"),
	})
	context.set_world_spawn_controller.call(context.create_world_spawn_controller.call(
		refs.spawn_manager,
		refs.persistent_followers,
		refs.player_follow_target,
		context.max_atlas_worker_followers
	))

	refs.time_manager.configure(context.room_count, context.default_hour_duration_seconds)
	context.godmode_ui_controller.configure({
		"backpack_container": runtime.backpack_container,
		"item_registry": context.item_registry,
		"console_input": refs.console_input,
		"console_panel": refs.console_panel,
		"debug_settings": runtime.debug_settings,
		"equip_backpack_item": context.equip_backpack_item,
		"get_build_mode_name": context.get_build_mode_name,
		"get_current_room_index": context.get_current_room_index,
		"get_current_room_surface_cell_y": context.get_current_room_surface_cell_y,
		"get_gravity_field_system": context.get_gravity_field_system,
		"get_item_drop_data": context.get_item_drop_data,
		"get_room_world_rect": context.get_room_world_rect,
		"get_selected_material_name": context.get_selected_material_name,
		"get_shape_name": context.get_shape_name,
		"godmode_action_handler": context.godmode_action_handler,
		"godmode_panel": refs.godmode_panel,
		"godmode_snapshot_builder": context.godmode_snapshot_builder,
		"inventory_data": runtime.inventory_data,
		"inventory_runtime": runtime.inventory_runtime,
		"is_player_inside_gravity_field": context.is_player_inside_gravity_field,
		"map_handler": refs.map_handler,
		"player_cursor_controller": runtime.player_cursor_controller,
		"player_equipment": runtime.player_equipment,
		"queue_redraw": context.queue_redraw,
		"select_gravity_strength": context.select_gravity_strength,
		"set_build_mode": context.set_build_mode,
		"set_debug_enabled": context.set_debug_enabled,
		"set_inventory_capacity": context.set_inventory_capacity,
		"set_inventory_weight_capacity": context.set_inventory_weight_capacity,
		"start_background_fade": context.start_background_fade,
		"time_debug_controller": context.time_debug_controller,
		"time_manager": refs.time_manager,
		"ui_root": refs.ui_root,
		"world_draw_controller": context.world_draw_controller,
	})
	context.godmode_ui_controller.connect_signals()
	context.apply_view_resolution.call()
	context.generate_rooms.call()
	_register_interactables_in_tree(refs.placeable_objects, context.interaction_registry)
	refs.camera_2d.ignore_rotation = true
	refs.camera_2d.zoom = Vector2.ONE
	context.set_current_room.call(0)
	context.place_crash_ship_in_starting_room.call()
	context.set_player_world_position.call(context.get_room_spawn_position.call())
	context.godmode_ui_controller.set_console_visible(false)
	context.godmode_ui_controller.update_godmode_visibility()
	context.update_hover_state.call()
	context.snap_player_to_ground.call()
	context.spawn_initial_backpack_world_item.call()
	context.update_player_follow_target.call()
	context.apply_camera_tracking.call(-1.0)
	context.godmode_ui_controller.update_time_hud()
	context.godmode_ui_controller.refresh_godmode_ui()
	context.queue_redraw.call()


func _setup_item_debug_components(runtime: WorldRuntime, add_child_callback: Callable, cursor_behavior_changed_callback: Callable) -> void:
	runtime.player_equipment.name = "player_equipment"
	runtime.backpack_container.name = "backpack_container"
	runtime.player_cursor_controller.name = "player_cursor_controller"
	add_child_callback.call(runtime.player_equipment)
	add_child_callback.call(runtime.backpack_container)
	add_child_callback.call(runtime.player_cursor_controller)
	runtime.player_cursor_controller.cursor_behavior_changed.connect(cursor_behavior_changed_callback)
	runtime.player_cursor_controller.bind_equipment(runtime.player_equipment)


func _setup_ui_root(refs: WorldSceneRefs, runtime: WorldRuntime) -> void:
	if refs.ui_root == null:
		return
	refs.ui_root.bind_equipment(runtime.player_equipment)
	refs.ui_root.bind_cursor_controller(runtime.player_cursor_controller)


func _register_interactables_in_tree(root: Node, interaction_registry: InteractionRegistry) -> void:
	if root == null or interaction_registry == null:
		return
	for child in root.get_children():
		if child.has_method("can_interact") and child.has_method("interact"):
			interaction_registry.register_interactable(child)
		_register_interactables_in_tree(child, interaction_registry)
