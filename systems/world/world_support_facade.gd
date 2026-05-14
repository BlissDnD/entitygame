class_name WorldSupportFacade
extends RefCounted


func place_crash_ship_in_starting_room(crash_ship_interaction_controller: CrashShipInteractionController, crash_ship: CrashShip, room_rect: Rect2, surface_cell_y: int, update_visibility: Callable) -> void:
	crash_ship_interaction_controller.place_crash_ship_in_starting_room(crash_ship, room_rect, surface_cell_y)
	update_visibility.call()


func update_crash_ship_visibility(crash_ship_interaction_controller: CrashShipInteractionController, crash_ship: CrashShip, current_room_index: int) -> void:
	crash_ship_interaction_controller.update_crash_ship_visibility(crash_ship, current_room_index)


func spawn_initial_backpack_world_item(item_interaction_controller: ItemInteractionController, player_ground_world: Vector2, backpack_item_definition: ItemDefinition, backpack_world_item_scene: PackedScene) -> void:
	item_interaction_controller.spawn_initial_backpack_world_item(player_ground_world, backpack_item_definition, backpack_world_item_scene)


func equip_backpack_item(inventory_runtime: InventoryRuntime, item_definition: ItemDefinition, log_prefix: String, refresh_godmode_ui: Callable) -> bool:
	var did_equip: bool = inventory_runtime.equip_backpack_item(item_definition, log_prefix)
	if did_equip:
		refresh_godmode_ui.call()
	return did_equip


func update_room_placeable_visibility(world_room_controller: WorldRoomController) -> void:
	world_room_controller.update_room_placeable_visibility()


func update_room_npc_visibility(world_room_controller: WorldRoomController) -> void:
	world_room_controller.update_room_npc_visibility()


func create_atlas_worker_spawn_point_for_room(world_spawn_controller: WorldSpawnController, atlas_worker_spawn_point_scene: PackedScene, room_index: int, room_size_cells: Vector2i, room_npc_container: Node2D, edge_margin_cells: int, surface_cell_y: int) -> void:
	if world_spawn_controller == null:
		return
	world_spawn_controller.create_atlas_worker_spawn_point_for_room(atlas_worker_spawn_point_scene, room_index, room_size_cells, room_npc_container, edge_margin_cells, surface_cell_y)


func reposition_active_atlas_workers_after_transition(world_spawn_controller: WorldSpawnController, exit_edge: String, player_ground_world: Vector2) -> void:
	if world_spawn_controller == null:
		return
	world_spawn_controller.reposition_active_atlas_workers_after_transition(exit_edge, player_ground_world)


func update_active_atlas_worker_grounding(world_spawn_controller: WorldSpawnController, player_ground_world: Vector2, cell_height: int) -> void:
	if world_spawn_controller == null:
		return
	world_spawn_controller.update_active_atlas_worker_grounding(player_ground_world, cell_height)


func update_player_follow_target(world_spawn_controller: WorldSpawnController, player_ground_world: Vector2) -> void:
	if world_spawn_controller == null:
		return
	world_spawn_controller.update_player_follow_target(player_ground_world)


func apply_view_resolution(root_window: Window, target_internal_resolution: Vector2i) -> void:
	root_window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root_window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root_window.content_scale_size = target_internal_resolution
