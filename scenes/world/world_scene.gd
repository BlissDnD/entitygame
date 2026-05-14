extends Node2D

const GameplayTuningClass = preload("res://systems/config/gameplay_tuning.gd")
const WorldConstantsClass = preload("res://systems/world/world_constants.gd")
const WorldUtilsClass = preload("res://systems/world/world_utils.gd")
const WorldDataClass = preload("res://systems/world/world_data.gd")
const WorldMaterialsClass = preload("res://systems/world/world_materials.gd")
const WorldShapesClass = preload("res://systems/world/world_shapes.gd")
const MiningToolProfilesClass = preload("res://systems/world/mining_tool_profiles.gd")
const ItemDropDataClass = preload("res://systems/items/item_drop_data.gd")
const WorldRendererClass = preload("res://systems/world/world_renderer.gd")
const RuntimeDebugSettingsClass = preload("res://systems/world/runtime_debug_settings.gd")
const WorldBackgroundControllerClass = preload("res://systems/world/world_background_controller.gd")
const MiningRuntimeClass = preload("res://systems/mining/mining_runtime.gd")
const InventoryDataClass = preload("res://systems/inventory/inventory_data.gd")
const InventoryRuntimeClass = preload("res://systems/inventory/inventory_runtime.gd")
const ItemInteractionControllerClass = preload("res://systems/items/item_interaction_controller.gd")
const ItemTypesClass = preload("res://systems/items/item_types.gd")
const EquipmentSlotClass = preload("res://systems/equipment/equipment_slot.gd")
const PlayerEquipmentClass = preload("res://systems/equipment/player_equipment.gd")
const BackpackContainerClass = preload("res://systems/backpack/backpack_container.gd")
const PlayerCursorControllerClass = preload("res://systems/cursor/player_cursor_controller.gd")
const CursorBehaviorDefinitionClass = preload("res://systems/cursor/cursor_behavior_definition.gd")
const PlanetSunCycleClass = preload("res://systems/time/planet_sun_cycle.gd")
const TimeDebugControllerClass = preload("res://systems/time/time_debug_controller.gd")
const GravityInteractionControllerClass = preload("res://systems/gravity/gravity_interaction_controller.gd")
const PlaceablePlacementServiceClass = preload("res://systems/placeables/placeable_placement_service.gd")
const GravityFieldSystemClass = preload("res://systems/world/gravity_field_system.gd")
const WorldDrawControllerClass = preload("res://systems/world/world_draw_controller.gd")
const WorldPlayerControllerClass = preload("res://systems/world/world_player_controller.gd")
const RoomTransitionControllerClass = preload("res://systems/world/room_transition_controller.gd")
const WorldInputInteractionControllerClass = preload("res://systems/world/world_input_interaction_controller.gd")
const WorldRoomFlowControllerClass = preload("res://systems/world/world_room_flow_controller.gd")
const WorldTickPipelineClass = preload("res://systems/world/world_tick_pipeline.gd")
const WorldQueryFacadeClass = preload("res://systems/world/world_query_facade.gd")
const WorldBuildMiningFacadeClass = preload("res://systems/world/world_build_mining_facade.gd")
const WorldDrawContextBuilderClass = preload("res://systems/world/world_draw_context_builder.gd")
const WorldDrawPipelineClass = preload("res://systems/world/world_draw_pipeline.gd")
const WorldStateSyncFacadeClass = preload("res://systems/world/world_state_sync_facade.gd")
const WorldSupportFacadeClass = preload("res://systems/world/world_support_facade.gd")
const WorldCollisionSurfaceFacadeClass = preload("res://systems/world/world_collision_surface_facade.gd")
const WorldRuntimeClass = preload("res://systems/world/world_runtime.gd")
const WorldSceneRefsClass = preload("res://systems/world/world_scene_refs.gd")
const WorldBootstrapClass = preload("res://systems/world/world_bootstrap.gd")
const WorldSceneContextFactoryClass = preload("res://systems/world/world_scene_context_factory.gd")
const WorldGenerationSurfaceControllerClass = preload("res://systems/world/world_generation_surface_controller.gd")
const CrashShipInteractionControllerClass = preload("res://systems/world/crash_ship_interaction_controller.gd")
const WorldRoomControllerClass = preload("res://systems/world/world_room_controller.gd")
const WorldSpawnControllerClass = preload("res://systems/world/world_spawn_controller.gd")
const BuildModeRuntimeClass = preload("res://systems/build/build_mode_runtime.gd")
const GodModeActionHandlerClass = preload("res://systems/debug/godmode_action_handler.gd")
const GodModeSnapshotBuilderClass = preload("res://systems/debug/godmode_snapshot_builder.gd")
const GodModeUiControllerClass = preload("res://systems/debug/godmode_ui_controller.gd")
const PrototypeTreeDefinition = preload("res://resources/placeables/prototype_tree.tres")
const AtlasWorkerSpawnPointScene = preload("res://entity/npc/atlas_worker/atlas_worker_spawn_point.tscn")
const BackpackWorldItemScene = preload("res://entity/items/backpack_world_item.tscn")
const BasicMiningToolDefinition = preload("res://resources/equipment/basic_mining_tool.tres")
const BasicBackpackItemDefinition = preload("res://resources/equipment/basic_backpack.tres")
const StoneItemDefinition = preload("res://resources/items/stone.tres")
const ScrapItemDefinition = preload("res://resources/items/scrap.tres")

const ROOM_EDGE_NONE: String = ""
const ROOM_EDGE_LEFT: String = "left"
const ROOM_EDGE_RIGHT: String = "right"
const ROOM_EDGE_TOP: String = "top"
const ROOM_EDGE_BOTTOM: String = "bottom"
const SURFACE_PROP_BUSH: String = "bush"
const SURFACE_PROP_ROCK: String = "rock"
const MAX_ATLAS_WORKER_FOLLOWERS: int = 10
const BACKGROUND_FADE_DURATION: float = 1.4
const SUN_VISUAL_RADIUS: float = 20.0

@export var starts_in_godmode: bool = false

var runtime = WorldRuntimeClass.new()
var active_tool_profile: Dictionary = MiningToolProfilesClass.get_profile("starter_pickaxe")
var debug_settings = runtime.debug_settings
var world_data = runtime.world_data
var world_renderer = runtime.world_renderer
var mining_runtime = runtime.mining_runtime
var item_drop_data = runtime.item_drop_data
var inventory_data = runtime.inventory_data
var player_equipment = runtime.player_equipment
var backpack_container = runtime.backpack_container
var inventory_runtime = runtime.inventory_runtime
var player_cursor_controller = runtime.player_cursor_controller
var player_world_position: Vector2 = runtime.player_world_position
var player_velocity: Vector2 = Vector2.ZERO
var hovered_cell: Vector2i = Vector2i.ZERO
var mining_center_cell: Vector2i = Vector2i.ZERO
var debug_enabled: bool = GameplayTuningClass.DEBUG_OVERLAY_DEFAULT_ENABLED
var has_inspected_cell: bool = false
var inspected_cell: Vector2i = Vector2i.ZERO
var block_mining_until_left_released: bool = false
var hovered_drop_index: int = -1
var last_render_stats: Dictionary = {}
var gravity_field_system: GravityFieldSystem = runtime.gravity_field_system
var build_mode_runtime = runtime.build_mode_runtime
var gravity_interaction_controller = GravityInteractionControllerClass.new()
var godmode_action_handler = GodModeActionHandlerClass.new()
var time_debug_controller = TimeDebugControllerClass.new()
var godmode_snapshot_builder = GodModeSnapshotBuilderClass.new()
var godmode_ui_controller = GodModeUiControllerClass.new()
var world_draw_controller = WorldDrawControllerClass.new()
var world_player_controller = WorldPlayerControllerClass.new()
var room_transition_controller = RoomTransitionControllerClass.new()
var world_input_interaction_controller = WorldInputInteractionControllerClass.new()
var world_room_flow_controller = WorldRoomFlowControllerClass.new()
var world_tick_pipeline = WorldTickPipelineClass.new()
var world_query_facade = WorldQueryFacadeClass.new()
var world_build_mining_facade = WorldBuildMiningFacadeClass.new()
var world_draw_context_builder = WorldDrawContextBuilderClass.new()
var world_draw_pipeline = WorldDrawPipelineClass.new()
var world_state_sync_facade = WorldStateSyncFacadeClass.new()
var world_support_facade = WorldSupportFacadeClass.new()
var world_collision_surface_facade = WorldCollisionSurfaceFacadeClass.new()
var world_generation_surface_controller = WorldGenerationSurfaceControllerClass.new()
var crash_ship_interaction_controller = CrashShipInteractionControllerClass.new()
var world_room_controller = WorldRoomControllerClass.new()
var world_spawn_controller: WorldSpawnController = null
var room_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var has_won: bool = false
var is_handling_void_fall: bool = false
var room_transition_lock_time: float = 0.0
var run_hold_time: float = 0.0
var last_run_direction: int = 0
var item_interaction_controller = ItemInteractionControllerClass.new(item_drop_data, inventory_runtime, player_equipment)
var has_printed_missing_mining_tool_warning: bool = false
var background_controller = WorldBackgroundControllerClass.new()
var world_bootstrap = WorldBootstrapClass.new()
var world_scene_context_factory = WorldSceneContextFactoryClass.new()

@onready var camera_2d: Camera2D = $camera_2d
@onready var time_manager: TimeManager = $time_manager
@onready var spawn_manager: SpawnManager = $spawn_manager
@onready var map_handler: MapHandler = $map_handler
@onready var crash_ship: CrashShip = $crash_ship
@onready var placeable_objects: Node2D = $placeable_objects
@onready var world_items: Node2D = $world_items
@onready var npc_objects: Node2D = $npc_objects
@onready var persistent_followers: Node2D = $npc_objects/persistent_followers
@onready var player_follow_target: Node2D = $player_follow_target
@onready var console_layer: CanvasLayer = $console_layer
@onready var console_panel: Panel = $console_layer/console_panel
@onready var console_input: LineEdit = $console_layer/console_panel/console_input
@onready var godmode_panel: GodModePanel = $console_layer/godmode_panel
@onready var ui_root: UIRoot = $UIRoot
@onready var scene_refs: WorldSceneRefs = WorldSceneRefsClass.capture(self)

func _ready() -> void:
	world_bootstrap.run(world_scene_context_factory.build_ready_context(self))


func _process(delta: float) -> void:
	var state := {
		"has_won": has_won,
		"hovered_cell": hovered_cell,
		"hovered_drop_index": hovered_drop_index,
		"mining_center_cell": mining_center_cell,
		"room_transition_lock_time": room_transition_lock_time,
	}
	var result: Dictionary = world_tick_pipeline.process(delta, state, world_scene_context_factory.build_process_context(self))
	has_won = bool(state.has_won)
	hovered_cell = state.hovered_cell
	hovered_drop_index = int(state.hovered_drop_index)
	mining_center_cell = state.mining_center_cell
	room_transition_lock_time = float(state.room_transition_lock_time)
	if bool(result.get("should_redraw", false)):
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	var state := {
		"block_mining_until_left_released": block_mining_until_left_released,
		"has_inspected_cell": has_inspected_cell,
		"hovered_cell": hovered_cell,
		"hovered_drop_index": hovered_drop_index,
		"inspected_cell": inspected_cell,
	}
	var result: Dictionary = world_input_interaction_controller.handle_unhandled_input(event, state, world_scene_context_factory.build_input_context(self))
	block_mining_until_left_released = bool(state.block_mining_until_left_released)
	has_inspected_cell = bool(state.has_inspected_cell)
	hovered_drop_index = int(state.hovered_drop_index)
	inspected_cell = state.inspected_cell
	if bool(result.get("queue_redraw", false)):
		queue_redraw()
	if bool(result.get("input_handled", false)):
		get_viewport().set_input_as_handled()


func _draw() -> void:
	var draw_result: Dictionary = world_draw_pipeline.draw(self, world_scene_context_factory.build_draw_context(self))
	last_render_stats = draw_result.get("last_render_stats", last_render_stats)


func _start_background_fade(next_color: Color, reason: String) -> void:
	if background_controller.get_target_color() == next_color and background_controller.is_fading():
		return

	background_controller.start_fade(next_color, reason, time_manager.get_room_time_state_name(world_room_controller.get_current_room_index()))
	queue_redraw()


func _update_hover_state() -> bool:
	var state := {
		"hovered_cell": hovered_cell,
		"hovered_drop_index": hovered_drop_index,
		"mining_center_cell": mining_center_cell,
	}
	var changed: bool = world_tick_pipeline.update_hover_state(state, {
		"drop_hover_radius_pixels": GameplayTuningClass.DROPPED_ITEM_HOVER_RADIUS_PIXELS,
		"get_target_world_position": func(): return world_build_mining_facade.get_target_world_position(mining_runtime, world_query_facade.get_player_center_world(world_player_controller, player_world_position), get_global_mouse_position()),
		"item_interaction_controller": item_interaction_controller,
		"mouse_world_position": Callable(self, "get_global_mouse_position"),
		"world_to_cell": Callable(WorldUtilsClass, "world_to_cell"),
	})
	hovered_cell = state.hovered_cell
	hovered_drop_index = int(state.hovered_drop_index)
	mining_center_cell = state.mining_center_cell
	return changed


func _apply_camera_tracking(_delta: float) -> void:
	world_tick_pipeline.apply_camera_tracking({
		"apply_view_resolution": func():
			world_support_facade.apply_view_resolution(
				get_tree().root,
				world_query_facade.get_target_internal_resolution(
					get_viewport_rect().size,
					GameplayTuningClass.CAMERA_VIEW_CELLS_X * WorldConstantsClass.CELL_SIZE.x
				)
			),
		"camera_2d": camera_2d,
		"get_camera_center_world": func():
			return world_query_facade.get_camera_center_world(
				world_query_facade.get_room_world_rect(map_handler),
				world_query_facade.get_viewport_world_size(
					world_query_facade.get_target_internal_resolution(
						get_viewport_rect().size,
						GameplayTuningClass.CAMERA_VIEW_CELLS_X * WorldConstantsClass.CELL_SIZE.x
					)
				),
				GameplayTuningClass.VOID_CAMERA_MARGIN_CELLS * WorldConstantsClass.CELL_SIZE.x,
				world_room_controller.is_outer_left_edge(),
				world_room_controller.is_outer_right_edge(),
				world_query_facade.get_player_center_world(world_player_controller, player_world_position)
			),
	})


func _player_collides_at(test_position: Vector2) -> bool:
	return world_collision_surface_facade.player_collides_at(
		world_data,
		test_position,
		world_query_facade.get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS, WorldConstantsClass.CELL_SIZE),
		func(test_rect):
			return world_collision_surface_facade.rocks_collide_with_rect(
				world_query_facade.get_current_room_surface_props(world_room_controller),
				test_rect,
				func(prop_entry):
					return world_collision_surface_facade.get_surface_prop_collision_rect(
						prop_entry,
						func(size_cells): return world_query_facade.get_world_size_from_cells(size_cells, WorldConstantsClass.CELL_SIZE)
					),
				SURFACE_PROP_ROCK
			)
	)


func _snap_player_to_ground() -> void:
	var player_state := {
		"position": player_world_position,
	}
	world_player_controller.snap_player_to_ground(player_state, Callable(self, "_player_collides_at"))
	player_world_position = player_state.position


func _generate_rooms() -> void:
	world_room_controller.reset()
	inventory_data.clear()
	map_handler.configure_rooms([])
	has_won = false

	var generated_rooms: Array[Dictionary] = world_generation_surface_controller.generate_rooms({
		"active_room_index": world_room_controller.get_current_room_index(),
		"create_atlas_worker_spawn_point": func(room_index, room_size_cells, room_npc_container):
			world_support_facade.create_atlas_worker_spawn_point_for_room(
				world_spawn_controller,
				AtlasWorkerSpawnPointScene,
				room_index,
				room_size_cells,
				room_npc_container,
				GameplayTuningClass.SURFACE_PROP_EDGE_MARGIN_CELLS,
				world_query_facade.get_surface_cell_y_for_room(world_room_controller, room_size_cells)
			),
		"get_surface_cell_y_for_room": func(room_size_cells): return world_query_facade.get_surface_cell_y_for_room(world_room_controller, room_size_cells),
		"gravity_field_system_class": GravityFieldSystemClass,
		"item_drop_data_class": ItemDropDataClass,
		"npc_objects": npc_objects,
		"persistent_followers": persistent_followers,
		"placeable_objects": placeable_objects,
		"prototype_tree_definition": PrototypeTreeDefinition,
		"room_count": GameplayTuningClass.ROOM_COUNT,
		"room_rng": room_rng,
		"surface_prop_bush": SURFACE_PROP_BUSH,
		"surface_prop_rock": SURFACE_PROP_ROCK,
		"viewport_world_size": world_query_facade.get_viewport_world_size(world_query_facade.get_target_internal_resolution(get_viewport_rect().size, GameplayTuningClass.CAMERA_VIEW_CELLS_X * WorldConstantsClass.CELL_SIZE.x)),
		"world_data_class": WorldDataClass,
	})

	for room_entry in generated_rooms:
		world_room_controller.add_room(
			Vector2i(room_entry.get("room_size_cells", Vector2i.ZERO)),
			room_entry.get("world_data", null),
			room_entry.get("drop_data", null),
			room_entry.get("surface_props", []),
			room_entry.get("protected_cells", {}),
			room_entry.get("placeable_container", null),
			room_entry.get("npc_container", null),
			room_entry.get("gravity_field_system", null)
		)
	map_handler.configure_rooms(world_room_controller.get_room_size_cells_list())


func _set_current_room(room_index: int) -> void:
	var result: Dictionary = world_room_flow_controller.set_current_room(room_index, {
		"clear_build_mode": Callable(self, "_clear_build_mode"),
		"map_handler": map_handler,
		"print_world_boundary_debug": func():
			world_room_flow_controller.print_world_boundary_debug({
				"current_room_index": map_handler.get_current_room_index(),
				"get_room_world_rect": func(): return world_query_facade.get_room_world_rect(map_handler),
				"get_void_fall_rect": func():
					return world_query_facade.get_void_fall_rect(
						room_transition_controller,
						world_query_facade.get_room_world_rect(map_handler),
						GameplayTuningClass.VOID_FALL_MARGIN_CELLS * WorldConstantsClass.CELL_SIZE.x,
						GameplayTuningClass.VOID_FALL_DEPTH_CELLS * WorldConstantsClass.CELL_SIZE.y
					),
				"is_outer_left_edge": world_room_controller.is_outer_left_edge(),
				"is_outer_right_edge": world_room_controller.is_outer_right_edge(),
			}),
		"refresh_godmode_ui": Callable(godmode_ui_controller, "refresh_godmode_ui"),
		"set_gravity_field_system": func(next_gravity_field_system): world_state_sync_facade.set_active_gravity_field_system(self, next_gravity_field_system),
		"set_item_drop_data": func(next_item_drop_data): world_state_sync_facade.set_active_item_drop_data(self, next_item_drop_data),
		"set_world_renderer_data": Callable(world_renderer, "set_world_data"),
		"start_background_fade": Callable(self, "_start_background_fade"),
		"time_manager": time_manager,
		"update_crash_ship_visibility": func(): world_support_facade.update_crash_ship_visibility(crash_ship_interaction_controller, crash_ship, world_room_controller.get_current_room_index()),
		"update_room_npc_visibility": func(): world_support_facade.update_room_npc_visibility(world_room_controller),
		"update_room_placeable_visibility": func(): world_support_facade.update_room_placeable_visibility(world_room_controller),
		"update_time_hud": Callable(godmode_ui_controller, "update_time_hud"),
		"world_room_controller": world_room_controller,
	})
	world_data = result.world_data
	item_drop_data = result.item_drop_data
	gravity_field_system = result.gravity_field_system


func _get_room_spawn_position() -> Vector2:
	return crash_ship_interaction_controller.get_room_spawn_position(
		world_room_controller.get_current_room_index(),
		crash_ship,
		world_query_facade.get_room_world_rect(map_handler),
		world_query_facade.get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS, WorldConstantsClass.CELL_SIZE),
		world_query_facade.get_current_room_surface_cell_y(world_room_controller, GameplayTuningClass.ROOM_MIN_SIZE_CELLS)
	)


func _place_crash_ship_in_starting_room() -> void:
	world_support_facade.place_crash_ship_in_starting_room(
		crash_ship_interaction_controller,
		crash_ship,
		world_query_facade.get_room_world_rect(map_handler),
		world_query_facade.get_current_room_surface_cell_y(world_room_controller, GameplayTuningClass.ROOM_MIN_SIZE_CELLS),
		func(): world_support_facade.update_crash_ship_visibility(crash_ship_interaction_controller, crash_ship, world_room_controller.get_current_room_index())
	)


func _update_crash_ship_visibility() -> void:
	world_support_facade.update_crash_ship_visibility(crash_ship_interaction_controller, crash_ship, world_room_controller.get_current_room_index())


func _spawn_initial_backpack_world_item() -> void:
	world_support_facade.spawn_initial_backpack_world_item(item_interaction_controller, world_query_facade.get_player_ground_world(world_player_controller, player_world_position), BasicBackpackItemDefinition, BackpackWorldItemScene)


func _equip_backpack_item(item_definition: ItemDefinition, log_prefix: String) -> bool:
	return world_support_facade.equip_backpack_item(inventory_runtime, item_definition, log_prefix, Callable(godmode_ui_controller, "refresh_godmode_ui"))


func _try_transition_room() -> bool:
	var state := {
		"has_inspected_cell": has_inspected_cell,
		"has_won": has_won,
		"hovered_drop_index": hovered_drop_index,
		"player_position": player_world_position,
		"player_velocity": player_velocity,
		"room_transition_lock_time": room_transition_lock_time,
	}
	var result: Dictionary = world_room_flow_controller.try_transition_room(state, {
		"clear_room_entry_at_position": func(entry_position):
			world_collision_surface_facade.clear_room_entry_at_position(
				entry_position,
				room_transition_controller,
				world_data,
				world_query_facade.get_room_world_rect(map_handler),
				world_query_facade.get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS, WorldConstantsClass.CELL_SIZE),
				float(WorldConstantsClass.CELL_SIZE.x),
				float(WorldConstantsClass.CELL_SIZE.y * 2),
				func(cell_position): return world_query_facade.is_cell_inside_room(world_query_facade.get_current_room_size_cells(world_room_controller, GameplayTuningClass.ROOM_MIN_SIZE_CELLS), cell_position)
			),
		"clamp_player_to_room": func(next_position):
			return world_collision_surface_facade.clamp_player_to_room(
				room_transition_controller,
				next_position,
				world_query_facade.get_room_world_rect(map_handler),
				world_query_facade.get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS, WorldConstantsClass.CELL_SIZE),
				world_room_controller.is_outer_left_edge(),
				world_room_controller.is_outer_right_edge()
			),
		"current_room_index": world_room_controller.get_current_room_index(),
		"entry_inset_pixels": GameplayTuningClass.ROOM_ENTRY_INSET_CELLS * WorldConstantsClass.CELL_SIZE.x,
		"get_adjacent_room_index": Callable(self, "_get_adjacent_room_index"),
		"get_current_room_index": Callable(world_room_controller, "get_current_room_index"),
		"get_room_transition_edge": Callable(self, "_get_room_transition_edge"),
		"get_room_world_rect": func(): return world_query_facade.get_room_world_rect(map_handler),
		"get_world_size_from_cells": func(size_cells): return world_query_facade.get_world_size_from_cells(size_cells, WorldConstantsClass.CELL_SIZE),
		"player_collides_at": Callable(self, "_player_collides_at"),
		"player_size_cells": GameplayTuningClass.PLAYER_SIZE_CELLS,
		"queue_redraw": Callable(self, "queue_redraw"),
		"reposition_active_atlas_workers_after_transition": func(exit_edge):
			world_support_facade.reposition_active_atlas_workers_after_transition(
				world_spawn_controller,
				exit_edge,
				world_query_facade.get_player_ground_world(world_player_controller, player_world_position)
			),
		"resolve_guard_limit": WorldConstantsClass.CELL_SIZE.y * 8,
		"room_edge_bottom": ROOM_EDGE_BOTTOM,
		"room_edge_left": ROOM_EDGE_LEFT,
		"room_edge_none": ROOM_EDGE_NONE,
		"room_edge_right": ROOM_EDGE_RIGHT,
		"room_edge_top": ROOM_EDGE_TOP,
		"room_transition_controller": room_transition_controller,
		"set_current_room": Callable(self, "_set_current_room"),
		"update_hover_state": Callable(self, "_update_hover_state"),
		"wants_down": Input.is_action_pressed("move_down"),
		"wants_left": Input.is_action_pressed("move_left"),
		"wants_right": Input.is_action_pressed("move_right"),
		"wants_up": Input.is_action_pressed("move_up"),
	})
	world_state_sync_facade.apply_room_transition_state(self, state)
	return bool(result.get("handled", false))


func _check_void_fall() -> bool:
	var state := {
		"is_handling_void_fall": is_handling_void_fall,
		"player_position": player_world_position,
		"player_velocity": player_velocity,
	}
	var result: Dictionary = world_room_flow_controller.check_void_fall(state, {
		"get_room_spawn_position": func():
			return crash_ship_interaction_controller.get_room_spawn_position(
				world_room_controller.get_current_room_index(),
				crash_ship,
				world_query_facade.get_room_world_rect(map_handler),
				world_query_facade.get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS, WorldConstantsClass.CELL_SIZE),
				world_query_facade.get_current_room_surface_cell_y(world_room_controller, GameplayTuningClass.ROOM_MIN_SIZE_CELLS)
			),
		"get_room_world_rect": func(): return world_query_facade.get_room_world_rect(map_handler),
		"get_world_size_from_cells": func(size_cells): return world_query_facade.get_world_size_from_cells(size_cells, WorldConstantsClass.CELL_SIZE),
		"is_outer_left_edge": world_room_controller.is_outer_left_edge(),
		"is_outer_right_edge": world_room_controller.is_outer_right_edge(),
		"player_size_cells": GameplayTuningClass.PLAYER_SIZE_CELLS,
		"room_transition_controller": room_transition_controller,
		"snap_player_to_ground": func(next_player_position):
			return world_state_sync_facade.sync_player_to_ground_after_respawn(
				self,
				next_player_position,
				func():
					var player_state := {"position": player_world_position}
					world_player_controller.snap_player_to_ground(
						player_state,
						func(test_position):
							return world_collision_surface_facade.player_collides_at(
								world_data,
								test_position,
								world_query_facade.get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS, WorldConstantsClass.CELL_SIZE),
								func(test_rect):
									return world_collision_surface_facade.rocks_collide_with_rect(
										world_query_facade.get_current_room_surface_props(world_room_controller),
										test_rect,
										func(prop_entry):
											return world_collision_surface_facade.get_surface_prop_collision_rect(
												prop_entry,
												func(size_cells): return world_query_facade.get_world_size_from_cells(size_cells, WorldConstantsClass.CELL_SIZE)
											),
										SURFACE_PROP_ROCK
									)
							)
					)
					player_world_position = player_state.position
			),
		"update_hover_state": Callable(self, "_update_hover_state"),
		"void_depth": GameplayTuningClass.VOID_FALL_DEPTH_CELLS * WorldConstantsClass.CELL_SIZE.y,
		"void_margin": GameplayTuningClass.VOID_FALL_MARGIN_CELLS * WorldConstantsClass.CELL_SIZE.x,
	})
	world_state_sync_facade.apply_void_fall_state(self, state)
	return bool(result.get("handled", false))


func _get_room_transition_edge() -> String:
	var room_rect: Rect2 = world_query_facade.get_room_world_rect(map_handler)
	var player_rect: Rect2 = Rect2(player_world_position, world_query_facade.get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS, WorldConstantsClass.CELL_SIZE))
	var margin_pixels: float = GameplayTuningClass.ROOM_TRANSITION_MARGIN_CELLS * WorldConstantsClass.CELL_SIZE.x
	return room_transition_controller.get_room_transition_edge(
		room_rect,
		player_rect,
		margin_pixels,
		world_room_controller.has_adjacent_room(ROOM_EDGE_LEFT),
		world_room_controller.has_adjacent_room(ROOM_EDGE_RIGHT),
		ROOM_EDGE_NONE,
		ROOM_EDGE_LEFT,
		ROOM_EDGE_RIGHT,
		ROOM_EDGE_TOP,
		ROOM_EDGE_BOTTOM
	)




func _has_adjacent_room(room_edge: String) -> bool:
	return world_room_controller.has_adjacent_room(room_edge)


func _get_adjacent_room_index(room_edge: String) -> int:
	return world_room_controller.get_adjacent_room_index(room_edge)


func _get_target_world_position() -> Vector2:
	return world_build_mining_facade.get_target_world_position(mining_runtime, world_query_facade.get_player_center_world(world_player_controller, player_world_position), get_global_mouse_position())


func _get_ordered_preview_cells() -> Array[Vector2i]:
	return world_build_mining_facade.get_ordered_preview_cells(mining_runtime, debug_settings.mining_shape, mining_center_cell, debug_settings.mining_radius, world_query_facade.get_player_center_world(world_player_controller, player_world_position), func(cell_position): return world_query_facade.get_cell_center_world(cell_position, WorldConstantsClass.CELL_SIZE))


func _get_traversal_index(cell_position: Vector2i) -> int:
	return world_build_mining_facade.get_traversal_index(mining_runtime, cell_position, debug_settings.mining_shape, mining_center_cell, debug_settings.mining_radius, world_query_facade.get_player_center_world(world_player_controller, player_world_position), func(next_cell_position): return world_query_facade.get_cell_center_world(next_cell_position, WorldConstantsClass.CELL_SIZE))


func _should_show_place_cursor() -> bool:
	return world_build_mining_facade.should_show_place_cursor(player_cursor_controller, world_build_mining_facade.is_gravity_build_mode_active(build_mode_runtime))


func _is_gravity_build_mode_active() -> bool:
	return world_build_mining_facade.is_gravity_build_mode_active(build_mode_runtime)


func _is_player_inside_gravity_field() -> bool:
	return world_build_mining_facade.is_player_inside_gravity_field(world_player_controller, player_world_position, gravity_field_system, func(size_cells): return world_query_facade.get_world_size_from_cells(size_cells, WorldConstantsClass.CELL_SIZE))


func _set_build_mode(next_build_mode: int) -> void:
	var result: Dictionary = world_build_mining_facade.set_build_mode(gravity_interaction_controller, build_mode_runtime, next_build_mode)
	block_mining_until_left_released = bool(result.get("block_mining_until_left_released", true))
	print("[GodModeGravity] build mode: %s" % String(result.get("build_mode_name", world_build_mining_facade.get_build_mode_name(build_mode_runtime))))
	godmode_ui_controller.update_time_hud()
	godmode_ui_controller.refresh_godmode_ui()
	queue_redraw()


func _clear_build_mode() -> void:
	var result: Dictionary = world_build_mining_facade.clear_build_mode(gravity_interaction_controller, build_mode_runtime)
	if not bool(result.get("changed", false)):
		return
	block_mining_until_left_released = bool(result.get("block_mining_until_left_released", true))
	godmode_ui_controller.update_time_hud()
	godmode_ui_controller.refresh_godmode_ui()


func _handle_gravity_build_click() -> void:
	var result: Dictionary = world_build_mining_facade.handle_gravity_build_click(gravity_interaction_controller, build_mode_runtime, mining_center_cell, _get_ordered_preview_cells(), Callable(self, "_get_gravity_field_preview_rect"), Callable(self, "_get_cell_center_world"))
	var log_message: String = String(result.get("log_message", ""))
	var click_result: int = int(result.get("click_result", BuildModeRuntimeClass.BuildClickResult.NONE))
	if not log_message.is_empty():
		print(log_message)
	if bool(result.get("block_mining_until_left_released", false)):
		block_mining_until_left_released = true
	if click_result != BuildModeRuntimeClass.BuildClickResult.NONE:
		godmode_ui_controller.update_time_hud()
	if bool(result.get("show_strength_popup", false)):
		godmode_panel.show_gravity_strength_popup()
	godmode_ui_controller.refresh_godmode_ui()


func _get_gravity_field_preview_rect() -> Rect2:
	return world_build_mining_facade.get_gravity_field_preview_rect(build_mode_runtime, mining_center_cell, _get_ordered_preview_cells())


func _get_player_center_world() -> Vector2:
	return world_query_facade.get_player_center_world(world_player_controller, player_world_position)


func _get_player_ground_world() -> Vector2:
	return world_query_facade.get_player_ground_world(world_player_controller, player_world_position)


func _update_player_follow_target() -> void:
	world_support_facade.update_player_follow_target(world_spawn_controller, world_query_facade.get_player_ground_world(world_player_controller, player_world_position))


func _update_active_atlas_worker_grounding() -> void:
	world_support_facade.update_active_atlas_worker_grounding(
		world_spawn_controller,
		world_query_facade.get_player_ground_world(world_player_controller, player_world_position),
		WorldConstantsClass.CELL_SIZE.y
	)


func _get_cell_center_world(cell_position: Vector2i) -> Vector2:
	return world_query_facade.get_cell_center_world(cell_position, WorldConstantsClass.CELL_SIZE)


func _get_world_size_from_cells(size_cells: Vector2i) -> Vector2:
	return world_query_facade.get_world_size_from_cells(size_cells, WorldConstantsClass.CELL_SIZE)


func _get_cell_type_name(cell_type: int) -> String:
	return WorldMaterialsClass.get_display_name(cell_type)


func _try_place_preview_cells() -> bool:
	var result: Dictionary = world_build_mining_facade.try_place_preview_cells(mining_runtime, {
		"inventory_data": inventory_data,
		"is_cell_inside_room": func(cell_position): return world_query_facade.is_cell_inside_room(world_query_facade.get_current_room_size_cells(world_room_controller, GameplayTuningClass.ROOM_MIN_SIZE_CELLS), cell_position),
		"ordered_preview_cells": _get_ordered_preview_cells(),
		"player_center_world": _get_player_center_world(),
		"player_contains_cell": Callable(self, "_player_contains_cell"),
		"selected_material_id": inventory_runtime.selected_material_id,
		"target_center_world": _get_cell_center_world(mining_center_cell),
		"world_data": world_data,
	})
	if bool(result.get("ui_refresh_needed", false)):
		godmode_ui_controller.refresh_godmode_ui()
	return bool(result.get("placed_any", false))


func _can_place_cell(cell_position: Vector2i) -> bool:
	return world_build_mining_facade.can_place_cell(
		mining_runtime,
		cell_position,
		world_data,
		func(next_cell_position): return world_query_facade.is_cell_inside_room(world_query_facade.get_current_room_size_cells(world_room_controller, GameplayTuningClass.ROOM_MIN_SIZE_CELLS), next_cell_position),
		Callable(self, "_player_contains_cell")
	)


func _player_contains_cell(cell_position: Vector2i) -> bool:
	var player_rect: Rect2 = Rect2(player_world_position, _get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS))
	var cell_rect: Rect2 = Rect2(WorldUtilsClass.cell_to_world(cell_position), Vector2(WorldConstantsClass.CELL_SIZE))
	return player_rect.intersects(cell_rect)


func _on_cursor_behavior_changed(cursor_behavior: int) -> void:
	match cursor_behavior:
		CursorBehaviorDefinitionClass.CursorBehavior.MINE_CONE:
			print("[Cursor] Mining cone cursor active")
		CursorBehaviorDefinitionClass.CursorBehavior.PLACE:
			print("[Cursor] Placement cursor active")
		_:
			print("[Cursor] Default cursor active")

	godmode_ui_controller.refresh_godmode_ui()
	queue_redraw()


func _select_gravity_strength(level_index: int) -> Dictionary:
	return gravity_interaction_controller.select_gravity_strength(build_mode_runtime, level_index)
