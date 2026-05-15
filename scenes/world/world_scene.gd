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
const InteractionManagerClass = preload("res://systems/interactions/interaction_manager.gd")
const InteractionContextClass = preload("res://systems/interactions/interaction_context.gd")
const InteractionRegistryClass = preload("res://systems/interactions/interaction_registry.gd")
const PlayerHandInteractionProviderClass = preload("res://systems/interactions/player/player_hand_interaction_provider.gd")
const PrototypeTreeDefinition = preload("res://resources/placeables/prototype_tree.tres")
const AtlasWorkerSpawnPointScene = preload("res://entity/npc/atlas_worker/atlas_worker_spawn_point.tscn")
const BackpackWorldItemScene = preload("res://entity/items/backpack_world_item.tscn")
const BasicMiningToolDefinition = preload("res://resources/items/equipment/tools/basic_mining_tool.tres")
const BasicBackpackItemDefinition = preload("res://resources/items/equipment/backpacks/basic_backpack.tres")
const StoneItemDefinition = preload("res://resources/items/materials/stone.tres")
const ScrapItemDefinition = preload("res://resources/items/salvage/scrap.tres")
const ItemDatabaseResource = preload("res://resources/items/item_database.tres")

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
var interaction_manager = InteractionManagerClass.new()
var interaction_context = InteractionContextClass.new()
var interaction_registry = InteractionRegistryClass.new()
var player_hand_interaction_provider = PlayerHandInteractionProviderClass.new()
var has_printed_missing_mining_tool_warning: bool = false
var background_controller = WorldBackgroundControllerClass.new()
var world_bootstrap = WorldBootstrapClass.new()
var world_scene_context_factory = WorldSceneContextFactoryClass.new()
var item_registry: ItemRegistry

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
	item_registry = ItemDatabaseResource.build_registry()
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


func _has_adjacent_room(room_edge: String) -> bool:
	return world_room_controller.has_adjacent_room(room_edge)


func _get_adjacent_room_index(room_edge: String) -> int:
	return world_room_controller.get_adjacent_room_index(room_edge)


func _should_show_place_cursor() -> bool:
	return world_build_mining_facade.should_show_place_cursor(player_cursor_controller, world_build_mining_facade.is_gravity_build_mode_active(build_mode_runtime))


func _is_gravity_build_mode_active() -> bool:
	return world_build_mining_facade.is_gravity_build_mode_active(build_mode_runtime)


func _is_player_inside_gravity_field() -> bool:
	return world_build_mining_facade.is_player_inside_gravity_field(world_player_controller, player_world_position, gravity_field_system, func(size_cells): return world_query_facade.get_world_size_from_cells(size_cells, WorldConstantsClass.CELL_SIZE))


func _get_world_size_from_cells(size_cells: Vector2i) -> Vector2:
	return world_query_facade.get_world_size_from_cells(size_cells, WorldConstantsClass.CELL_SIZE)


func _get_cell_type_name(cell_type: int) -> String:
	return WorldMaterialsClass.get_display_name(cell_type)


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
