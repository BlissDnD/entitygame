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

var active_tool_profile: Dictionary = MiningToolProfilesClass.get_profile("starter_pickaxe")
var debug_settings = RuntimeDebugSettingsClass.new()
var world_data = WorldDataClass.new()
var world_renderer = WorldRendererClass.new(world_data)
var mining_runtime = MiningRuntimeClass.new()
var item_drop_data = ItemDropDataClass.new()
var inventory_data = InventoryDataClass.new(
	GameplayTuningClass.INVENTORY_CAPACITY,
	GameplayTuningClass.INVENTORY_WEIGHT_CAPACITY
)
var player_equipment = PlayerEquipmentClass.new()
var backpack_container = BackpackContainerClass.new()
var inventory_runtime = InventoryRuntimeClass.new(inventory_data, player_equipment, backpack_container)
var player_cursor_controller = PlayerCursorControllerClass.new()
var player_world_position: Vector2 = GameplayTuningClass.PLAYER_SPAWN_WORLD_POSITION
var player_velocity: Vector2 = Vector2.ZERO
var hovered_cell: Vector2i = Vector2i.ZERO
var mining_center_cell: Vector2i = Vector2i.ZERO
var debug_enabled: bool = GameplayTuningClass.DEBUG_OVERLAY_DEFAULT_ENABLED
var has_inspected_cell: bool = false
var inspected_cell: Vector2i = Vector2i.ZERO
var block_mining_until_left_released: bool = false
var hovered_drop_index: int = -1
var last_render_stats: Dictionary = {}
var gravity_field_system: GravityFieldSystem = GravityFieldSystemClass.new()
var build_mode_runtime = BuildModeRuntimeClass.new(gravity_field_system)
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

func _ready() -> void:
	debug_settings.apply_tool_profile(active_tool_profile)
	debug_settings.set_godmode_enabled(starts_in_godmode)
	background_controller.configure(BACKGROUND_FADE_DURATION)
	room_rng.randomize()
	_setup_item_debug_components()
	_setup_ui_root()
	item_interaction_controller.bind_scene_dependencies(spawn_manager, world_items)
	world_spawn_controller = WorldSpawnControllerClass.new(
		spawn_manager,
		persistent_followers,
		player_follow_target,
		MAX_ATLAS_WORKER_FOLLOWERS
	)
	time_manager.configure(GameplayTuningClass.ROOM_COUNT, PlanetSunCycleClass.DEFAULT_HOUR_DURATION_SECONDS)
	godmode_ui_controller.configure({
		"backpack_container": backpack_container,
		"console_input": console_input,
		"console_panel": console_panel,
		"debug_settings": debug_settings,
		"equip_backpack_item": Callable(self, "_equip_backpack_item"),
		"get_build_mode_name": Callable(self, "_get_build_mode_name"),
		"get_current_room_index": Callable(world_room_controller, "get_current_room_index"),
		"get_current_room_surface_cell_y": Callable(self, "_get_current_room_surface_cell_y"),
		"get_gravity_field_system": Callable(self, "_get_gravity_field_system"),
		"get_item_drop_data": Callable(self, "_get_item_drop_data"),
		"get_room_world_rect": Callable(self, "_get_room_world_rect"),
		"get_selected_material_name": Callable(self, "_get_selected_material_name"),
		"get_shape_name": Callable(self, "_get_shape_name"),
		"godmode_action_handler": godmode_action_handler,
		"godmode_panel": godmode_panel,
		"godmode_snapshot_builder": godmode_snapshot_builder,
		"inventory_data": inventory_data,
		"inventory_runtime": inventory_runtime,
		"is_player_inside_gravity_field": Callable(self, "_is_player_inside_gravity_field"),
		"map_handler": map_handler,
		"player_cursor_controller": player_cursor_controller,
		"player_equipment": player_equipment,
		"queue_redraw": Callable(self, "queue_redraw"),
		"select_gravity_strength": Callable(self, "_select_gravity_strength"),
		"set_build_mode": Callable(self, "_set_build_mode"),
		"set_debug_enabled": Callable(self, "_set_debug_overlay_enabled"),
		"set_inventory_capacity": Callable(self, "_set_inventory_capacity"),
		"set_inventory_weight_capacity": Callable(self, "_set_inventory_weight_capacity"),
		"start_background_fade": Callable(self, "_start_background_fade"),
		"time_debug_controller": time_debug_controller,
		"time_manager": time_manager,
		"ui_root": ui_root,
		"world_draw_controller": world_draw_controller,
	})
	godmode_ui_controller.connect_signals()
	_apply_view_resolution()
	_generate_rooms()
	camera_2d.ignore_rotation = true
	camera_2d.zoom = Vector2.ONE
	_set_current_room(0)
	_place_crash_ship_in_starting_room()
	player_world_position = _get_room_spawn_position()
	godmode_ui_controller.set_console_visible(false)
	godmode_ui_controller.update_godmode_visibility()
	_update_hover_state()
	_snap_player_to_ground()
	_spawn_initial_backpack_world_item()
	_update_player_follow_target()
	_apply_camera_tracking(-1.0)
	godmode_ui_controller.update_time_hud()
	godmode_ui_controller.refresh_godmode_ui()
	queue_redraw()


func _setup_item_debug_components() -> void:
	player_equipment.name = "player_equipment"
	backpack_container.name = "backpack_container"
	player_cursor_controller.name = "player_cursor_controller"
	add_child(player_equipment)
	add_child(backpack_container)
	add_child(player_cursor_controller)
	player_cursor_controller.cursor_behavior_changed.connect(_on_cursor_behavior_changed)
	player_cursor_controller.bind_equipment(player_equipment)


func _setup_ui_root() -> void:
	if ui_root == null:
		return
	ui_root.bind_equipment(player_equipment)
	ui_root.bind_cursor_controller(player_cursor_controller)


func _process(delta: float) -> void:
	var should_redraw: bool = false
	if background_controller.update(delta):
		should_redraw = true
	if time_manager.advance(delta):
		should_redraw = true
		godmode_ui_controller.refresh_godmode_ui()
	var was_transition_locked: bool = room_transition_lock_time > 0.0
	room_transition_lock_time = maxf(room_transition_lock_time - delta, 0.0)
	if was_transition_locked and room_transition_lock_time <= 0.0:
		print("player input unlocked; player movement enabled")

	if not godmode_ui_controller.is_console_open() and not has_won and room_transition_lock_time <= 0.0:
		if _update_player(delta):
			should_redraw = true
		if _update_item_drops(delta):
			should_redraw = true
		if _update_mining(delta):
			should_redraw = true
	elif room_transition_lock_time > 0.0:
		player_velocity = Vector2.ZERO

	if _update_hover_state():
		should_redraw = true

	if _check_void_fall():
		should_redraw = true
	elif _try_transition_room():
		should_redraw = true

	_update_player_follow_target()
	_update_active_atlas_worker_grounding()
	_apply_camera_tracking(delta)

	if should_redraw:
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	var state := {
		"block_mining_until_left_released": block_mining_until_left_released,
		"has_inspected_cell": has_inspected_cell,
		"hovered_cell": hovered_cell,
		"hovered_drop_index": hovered_drop_index,
		"inspected_cell": inspected_cell,
	}
	var result: Dictionary = world_input_interaction_controller.handle_unhandled_input(event, state, {
		"backpack_world_item_scene": BackpackWorldItemScene,
		"clear_build_mode": Callable(self, "_clear_build_mode"),
		"crash_ship": crash_ship,
		"crash_ship_interaction_controller": crash_ship_interaction_controller,
		"current_room_index": world_room_controller.get_current_room_index(),
		"drop_hover_radius_pixels": GameplayTuningClass.DROPPED_ITEM_HOVER_RADIUS_PIXELS,
		"get_player_ground_world": Callable(self, "_get_player_ground_world"),
		"get_world_size_from_cells": Callable(self, "_get_world_size_from_cells"),
		"handle_gravity_build_click": Callable(self, "_handle_gravity_build_click"),
		"inventory_runtime": inventory_runtime,
		"is_console_open": Callable(godmode_ui_controller, "is_console_open"),
		"is_gravity_build_mode_active": Callable(self, "_is_gravity_build_mode_active"),
		"is_pointer_over_debug_ui": Callable(self, "_is_pointer_over_debug_ui_now"),
		"item_interaction_controller": item_interaction_controller,
		"mouse_world_position": get_global_mouse_position(),
		"move_left_pressed": Input.is_action_pressed("move_left"),
		"player_size_cells": GameplayTuningClass.PLAYER_SIZE_CELLS,
		"player_world_position": player_world_position,
		"refresh_godmode_ui": Callable(godmode_ui_controller, "refresh_godmode_ui"),
		"should_show_place_cursor": Callable(self, "_should_show_place_cursor"),
		"toggle_console": Callable(godmode_ui_controller, "toggle_console"),
		"try_place_preview_cells": Callable(self, "_try_place_preview_cells"),
	})
	block_mining_until_left_released = bool(state.block_mining_until_left_released)
	has_inspected_cell = bool(state.has_inspected_cell)
	hovered_drop_index = int(state.hovered_drop_index)
	inspected_cell = state.inspected_cell
	if bool(result.get("queue_redraw", false)):
		queue_redraw()
	if bool(result.get("input_handled", false)):
		get_viewport().set_input_as_handled()


func _draw() -> void:
	var view_origin: Vector2 = _get_view_origin_world()
	var view_size: Vector2 = _get_viewport_world_size()
	var draw_stats_ref := {"value": last_render_stats}
	world_draw_controller.draw_world(self, {
		"background_controller": background_controller,
		"build_mode_name": _get_build_mode_name(),
		"can_place_any_preview_cells": _can_place_any_preview_cells(),
		"can_place_cell": Callable(self, "_can_place_cell"),
		"current_build_mode": build_mode_runtime.current_build_mode,
		"current_hour": time_manager.get_current_hour(),
		"current_room_index": world_room_controller.get_current_room_index(),
		"current_room_surface_cell_y": _get_current_room_surface_cell_y(),
		"current_room_surface_props": _get_current_room_surface_props(),
		"debug_enabled": debug_enabled,
		"display_room_count": map_handler.get_display_room_count(),
		"get_cell_center_world": Callable(self, "_get_cell_center_world"),
		"get_cell_type_name": Callable(self, "_get_cell_type_name"),
		"get_dominant_inventory_color": Callable(self, "_get_dominant_inventory_color"),
		"get_drop_item_color": Callable(self, "_get_drop_item_color"),
		"get_drop_item_name": Callable(self, "_get_drop_item_name"),
		"get_material_tags": Callable(WorldMaterialsClass, "get_material_tags"),
		"get_mining_resistance": Callable(WorldMaterialsClass, "get_mining_resistance"),
		"get_selected_material_color": Callable(self, "_get_selected_material_color"),
		"get_shape_name": Callable(self, "_get_shape_name"),
		"get_traversal_index": Callable(self, "_get_traversal_index"),
		"get_world_size_from_cells": Callable(self, "_get_world_size_from_cells"),
		"godmode_enabled": debug_settings.godmode_enabled,
		"gravity_field_build_mode": BuildModeRuntimeClass.BuildMode.GRAVITY_FIELD,
		"gravity_field_preview_rect": _get_gravity_field_preview_rect(),
		"gravity_field_system": gravity_field_system,
		"gravity_point_build_mode": BuildModeRuntimeClass.BuildMode.GRAVITY_POINT,
		"has_inspected_cell": has_inspected_cell,
		"has_won": has_won,
		"hovered_cell": hovered_cell,
		"hovered_drop_index": hovered_drop_index,
		"inspected_cell": inspected_cell,
		"inventory_data": inventory_data,
		"is_mining_target_in_range": _is_mining_target_in_range(),
		"item_drop_data": item_drop_data,
		"last_render_stats": draw_stats_ref,
		"mining_center_cell": mining_center_cell,
		"mining_power": debug_settings.mining_power,
		"mining_radius": debug_settings.mining_radius,
		"mining_shape": debug_settings.mining_shape,
		"ordered_preview_cells": _get_ordered_preview_cells(),
		"player_center_world": _get_player_center_world(),
		"player_world_position": player_world_position,
		"room_edge_bottom": ROOM_EDGE_BOTTOM,
		"room_edge_left": ROOM_EDGE_LEFT,
		"room_edge_none": ROOM_EDGE_NONE,
		"room_edge_right": ROOM_EDGE_RIGHT,
		"room_edge_top": ROOM_EDGE_TOP,
		"room_number": map_handler.get_current_room_number(),
		"room_rect": _get_room_world_rect(),
		"room_time_state_name": time_manager.get_room_time_state_name(world_room_controller.get_current_room_index()),
		"room_transition_edge": _get_room_transition_edge(),
		"selected_material_id": inventory_runtime.selected_material_id,
		"should_show_mining_cone_cursor": _should_show_mining_cone_cursor(),
		"should_show_place_cursor": _should_show_place_cursor(),
		"sun_visual_radius": SUN_VISUAL_RADIUS,
		"surface_prop_bush": SURFACE_PROP_BUSH,
		"surface_prop_rock": SURFACE_PROP_ROCK,
		"time_manager": time_manager,
		"view_origin": view_origin,
		"view_size": view_size,
		"world_data": world_data,
		"world_renderer": world_renderer,
	})
	last_render_stats = draw_stats_ref.value


func _update_player(delta: float) -> bool:
	var player_state := {
		"position": player_world_position,
		"velocity": player_velocity,
	}
	var moved: bool = world_player_controller.update(delta, player_state, {
		"clamp_player_to_room": Callable(self, "_clamp_player_to_room"),
		"collides_at": Callable(self, "_player_collides_at"),
		"get_world_size_from_cells": Callable(self, "_get_world_size_from_cells"),
		"gravity_field_system": gravity_field_system,
	})
	player_world_position = player_state.position
	player_velocity = player_state.velocity
	return moved


func _update_mining(delta: float) -> bool:
	var result: Dictionary = mining_runtime.update(delta, {
		"block_mining_until_left_released": block_mining_until_left_released,
		"has_printed_missing_warning": has_printed_missing_mining_tool_warning,
	}, {
		"active_tool_profile": active_tool_profile,
		"current_cursor_behavior": player_cursor_controller.get_current_cursor_behavior(),
		"debug_settings": debug_settings,
		"get_cell_center_world": Callable(self, "_get_cell_center_world"),
		"inventory_data": inventory_data,
		"is_cell_mining_protected": Callable(self, "_is_cell_mining_protected"),
		"is_gravity_build_mode_active": _is_gravity_build_mode_active(),
		"is_pointer_over_debug_ui": godmode_ui_controller.is_pointer_over_debug_ui(get_viewport().get_mouse_position()),
		"item_drop_data": item_drop_data,
		"mining_power": debug_settings.mining_power,
		"ordered_preview_cells": _get_ordered_preview_cells(),
		"player_center_world": _get_player_center_world(),
		"player_equipment": player_equipment,
		"target_center_world": _get_cell_center_world(mining_center_cell),
		"world_data": world_data,
	})
	block_mining_until_left_released = bool(result.get("block_mining_until_left_released", block_mining_until_left_released))
	has_printed_missing_mining_tool_warning = bool(result.get("has_printed_missing_warning", has_printed_missing_mining_tool_warning))
	if bool(result.get("ui_refresh_needed", false)):
		godmode_ui_controller.refresh_godmode_ui()
	return bool(result.get("changed", false))


func _update_item_drops(delta: float) -> bool:
	return item_interaction_controller.update_item_drops(
		world_data,
		delta,
		_get_room_world_rect(),
		GameplayTuningClass.DROPPED_ITEM_GRAVITY,
		GameplayTuningClass.DROPPED_ITEM_PULL_RADIUS_PIXELS,
		GameplayTuningClass.DROPPED_ITEM_MERGE_RADIUS_PIXELS,
		gravity_field_system
	)


func _update_hover_state() -> bool:
	var next_hovered_cell: Vector2i = WorldUtilsClass.world_to_cell(get_global_mouse_position())
	var next_mining_center_cell: Vector2i = WorldUtilsClass.world_to_cell(_get_target_world_position())
	var next_hovered_drop_index: int = item_interaction_controller.find_hovered_drop_index(
		get_global_mouse_position(),
		GameplayTuningClass.DROPPED_ITEM_HOVER_RADIUS_PIXELS
	)

	if next_hovered_cell == hovered_cell and next_mining_center_cell == mining_center_cell and next_hovered_drop_index == hovered_drop_index:
		return false

	hovered_cell = next_hovered_cell
	mining_center_cell = next_mining_center_cell
	hovered_drop_index = next_hovered_drop_index
	return true


func _apply_camera_tracking(_delta: float) -> void:
	_apply_view_resolution()
	camera_2d.zoom = Vector2.ONE
	camera_2d.position = _get_camera_center_world()
	camera_2d.rotation = 0.0


func _start_background_fade(next_color: Color, reason: String) -> void:
	if background_controller.get_target_color() == next_color and background_controller.is_fading():
		return

	background_controller.start_fade(next_color, reason, time_manager.get_room_time_state_name(world_room_controller.get_current_room_index()))
	queue_redraw()


func _set_background_color_immediate(next_color: Color) -> void:
	background_controller.set_color_immediate(next_color)


func _player_collides_at(test_position: Vector2) -> bool:
	var player_rect: Rect2 = Rect2(test_position, _get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS))
	return world_data.intersects_solid_rect(player_rect) or _rocks_collide_with_rect(player_rect)


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
		"create_atlas_worker_spawn_point": Callable(self, "_create_atlas_worker_spawn_point_for_room"),
		"get_surface_cell_y_for_room": Callable(self, "_get_surface_cell_y_for_room"),
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
		"viewport_world_size": _get_viewport_world_size(),
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
		"print_world_boundary_debug": Callable(self, "_print_world_boundary_debug"),
		"refresh_godmode_ui": Callable(godmode_ui_controller, "refresh_godmode_ui"),
		"set_gravity_field_system": Callable(self, "_set_active_gravity_field_system"),
		"set_item_drop_data": Callable(self, "_set_active_item_drop_data"),
		"set_world_renderer_data": Callable(world_renderer, "set_world_data"),
		"start_background_fade": Callable(self, "_start_background_fade"),
		"time_manager": time_manager,
		"update_crash_ship_visibility": Callable(self, "_update_crash_ship_visibility"),
		"update_room_npc_visibility": Callable(self, "_update_room_npc_visibility"),
		"update_room_placeable_visibility": Callable(self, "_update_room_placeable_visibility"),
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
		_get_room_world_rect(),
		_get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS),
		_get_current_room_surface_cell_y()
	)


func _place_crash_ship_in_starting_room() -> void:
	crash_ship_interaction_controller.place_crash_ship_in_starting_room(
		crash_ship,
		_get_room_world_rect(),
		_get_current_room_surface_cell_y()
	)
	_update_crash_ship_visibility()


func _update_crash_ship_visibility() -> void:
	crash_ship_interaction_controller.update_crash_ship_visibility(
		crash_ship,
		world_room_controller.get_current_room_index()
	)


func _spawn_initial_backpack_world_item() -> void:
	item_interaction_controller.spawn_initial_backpack_world_item(
		_get_player_ground_world(),
		BasicBackpackItemDefinition,
		BackpackWorldItemScene
	)


func _equip_backpack_item(item_definition: ItemDefinition, log_prefix: String) -> bool:
	var did_equip: bool = inventory_runtime.equip_backpack_item(item_definition, log_prefix)
	if did_equip:
		godmode_ui_controller.refresh_godmode_ui()
	return did_equip


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
		"clear_room_entry_at_position": Callable(self, "_clear_room_entry_at_position"),
		"clamp_player_to_room": Callable(self, "_clamp_player_to_room"),
		"current_room_index": world_room_controller.get_current_room_index(),
		"entry_inset_pixels": GameplayTuningClass.ROOM_ENTRY_INSET_CELLS * WorldConstantsClass.CELL_SIZE.x,
		"get_adjacent_room_index": Callable(self, "_get_adjacent_room_index"),
		"get_current_room_index": Callable(world_room_controller, "get_current_room_index"),
		"get_room_transition_edge": Callable(self, "_get_room_transition_edge"),
		"get_room_world_rect": Callable(self, "_get_room_world_rect"),
		"get_world_size_from_cells": Callable(self, "_get_world_size_from_cells"),
		"player_collides_at": Callable(self, "_player_collides_at"),
		"player_size_cells": GameplayTuningClass.PLAYER_SIZE_CELLS,
		"queue_redraw": Callable(self, "queue_redraw"),
		"reposition_active_atlas_workers_after_transition": Callable(self, "_reposition_active_atlas_workers_after_transition"),
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
	has_inspected_cell = bool(state.has_inspected_cell)
	has_won = bool(state.has_won)
	hovered_drop_index = int(state.hovered_drop_index)
	player_world_position = state.player_position
	player_velocity = state.player_velocity
	room_transition_lock_time = float(state.room_transition_lock_time)
	return bool(result.get("handled", false))


func _check_void_fall() -> bool:
	var state := {
		"is_handling_void_fall": is_handling_void_fall,
		"player_position": player_world_position,
		"player_velocity": player_velocity,
	}
	var result: Dictionary = world_room_flow_controller.check_void_fall(state, {
		"get_room_spawn_position": Callable(self, "_get_room_spawn_position"),
		"get_room_world_rect": Callable(self, "_get_room_world_rect"),
		"get_world_size_from_cells": Callable(self, "_get_world_size_from_cells"),
		"is_outer_left_edge": _is_outer_left_edge(),
		"is_outer_right_edge": _is_outer_right_edge(),
		"player_size_cells": GameplayTuningClass.PLAYER_SIZE_CELLS,
		"room_transition_controller": room_transition_controller,
		"snap_player_to_ground": Callable(self, "_sync_player_to_ground_after_respawn"),
		"update_hover_state": Callable(self, "_update_hover_state"),
		"void_depth": GameplayTuningClass.VOID_FALL_DEPTH_CELLS * WorldConstantsClass.CELL_SIZE.y,
		"void_margin": GameplayTuningClass.VOID_FALL_MARGIN_CELLS * WorldConstantsClass.CELL_SIZE.x,
	})
	is_handling_void_fall = bool(state.is_handling_void_fall)
	player_world_position = state.player_position
	player_velocity = state.player_velocity
	return bool(result.get("handled", false))


func _get_room_transition_edge() -> String:
	var room_rect: Rect2 = _get_room_world_rect()
	var player_rect: Rect2 = Rect2(player_world_position, _get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS))
	var margin_pixels: float = GameplayTuningClass.ROOM_TRANSITION_MARGIN_CELLS * WorldConstantsClass.CELL_SIZE.x
	return room_transition_controller.get_room_transition_edge(
		room_rect,
		player_rect,
		margin_pixels,
		_has_adjacent_room(ROOM_EDGE_LEFT),
		_has_adjacent_room(ROOM_EDGE_RIGHT),
		ROOM_EDGE_NONE,
		ROOM_EDGE_LEFT,
		ROOM_EDGE_RIGHT,
		ROOM_EDGE_TOP,
		ROOM_EDGE_BOTTOM
	)


func _get_room_world_rect() -> Rect2:
	return map_handler.get_current_room_world_rect()


func _get_void_fall_rect() -> Rect2:
	var room_rect: Rect2 = _get_room_world_rect()
	var void_margin: float = GameplayTuningClass.VOID_FALL_MARGIN_CELLS * WorldConstantsClass.CELL_SIZE.x
	var void_depth: float = GameplayTuningClass.VOID_FALL_DEPTH_CELLS * WorldConstantsClass.CELL_SIZE.y
	return room_transition_controller.get_void_fall_rect(
		room_rect,
		void_margin,
		void_depth
	)


func _is_outer_left_edge() -> bool:
	return world_room_controller.is_outer_left_edge()


func _is_outer_right_edge() -> bool:
	return world_room_controller.is_outer_right_edge()


func _print_world_boundary_debug() -> void:
	world_room_flow_controller.print_world_boundary_debug({
		"current_room_index": map_handler.get_current_room_index(),
		"get_room_world_rect": Callable(self, "_get_room_world_rect"),
		"get_void_fall_rect": Callable(self, "_get_void_fall_rect"),
		"is_outer_left_edge": _is_outer_left_edge(),
		"is_outer_right_edge": _is_outer_right_edge(),
	})


func _is_cell_inside_room(cell_position: Vector2i) -> bool:
	var room_size_cells: Vector2i = _get_current_room_size_cells()
	return cell_position.x >= 0 and cell_position.y >= 0 and cell_position.x < room_size_cells.x and cell_position.y < room_size_cells.y


func _clamp_player_to_room(next_position: Vector2) -> Vector2:
	var room_rect: Rect2 = _get_room_world_rect()
	var player_size: Vector2 = _get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS)
	return room_transition_controller.clamp_player_to_room(
		next_position,
		room_rect,
		player_size,
		_is_outer_left_edge(),
		_is_outer_right_edge()
	)


func _is_position_beyond_outer_horizontal_edge(position: Vector2) -> bool:
	var room_rect: Rect2 = _get_room_world_rect()
	var player_size: Vector2 = _get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS)
	return room_transition_controller.is_position_beyond_outer_horizontal_edge(
		position,
		room_rect,
		player_size,
		_is_outer_left_edge(),
		_is_outer_right_edge()
	)


func _get_view_origin_world() -> Vector2:
	return _get_camera_center_world() - (_get_viewport_world_size() * 0.5)


func _get_camera_center_world() -> Vector2:
	var room_rect: Rect2 = _get_room_world_rect()
	var half_view_size: Vector2 = _get_viewport_world_size() * 0.5
	var min_center: Vector2 = room_rect.position + half_view_size
	var max_center: Vector2 = room_rect.end - half_view_size
	var void_camera_margin: float = GameplayTuningClass.VOID_CAMERA_MARGIN_CELLS * WorldConstantsClass.CELL_SIZE.x
	if _is_outer_left_edge():
		min_center.x -= void_camera_margin
	if _is_outer_right_edge():
		max_center.x += void_camera_margin
	var player_center: Vector2 = _get_player_center_world()

	return Vector2(
		clampf(player_center.x, min_center.x, max_center.x),
		clampf(player_center.y, min_center.y, max_center.y)
	)


func _get_viewport_world_size() -> Vector2:
	return Vector2(_get_target_internal_resolution())


func _get_target_internal_resolution() -> Vector2i:
	var target_world_width: float = GameplayTuningClass.CAMERA_VIEW_CELLS_X * WorldConstantsClass.CELL_SIZE.x
	var viewport_size: Vector2 = get_viewport_rect().size
	var viewport_width: float = maxf(viewport_size.x, 1.0)
	var viewport_height: float = maxf(viewport_size.y, 1.0)
	var aspect_ratio: float = viewport_height / viewport_width
	var target_world_height: float = target_world_width * aspect_ratio
	return Vector2i(
		int(round(target_world_width)),
		int(round(target_world_height))
	)


func _update_room_placeable_visibility() -> void:
	world_room_controller.update_room_placeable_visibility()


func _update_room_npc_visibility() -> void:
	world_room_controller.update_room_npc_visibility()


func _create_atlas_worker_spawn_point_for_room(room_index: int, room_size_cells: Vector2i, room_npc_container: Node2D) -> void:
	if world_spawn_controller == null:
		return

	world_spawn_controller.create_atlas_worker_spawn_point_for_room(
		AtlasWorkerSpawnPointScene,
		room_index,
		room_size_cells,
		room_npc_container,
		GameplayTuningClass.SURFACE_PROP_EDGE_MARGIN_CELLS,
		_get_surface_cell_y_for_room(room_size_cells)
	)


func _reposition_active_atlas_workers_after_transition(exit_edge: String) -> void:
	if world_spawn_controller == null:
		return

	world_spawn_controller.reposition_active_atlas_workers_after_transition(exit_edge, _get_player_ground_world())


func _update_active_atlas_worker_grounding() -> void:
	if world_spawn_controller == null:
		return

	world_spawn_controller.update_active_atlas_worker_grounding(_get_player_ground_world(), WorldConstantsClass.CELL_SIZE.y)


func _apply_view_resolution() -> void:
	var root_window: Window = get_tree().root
	root_window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root_window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root_window.content_scale_size = _get_target_internal_resolution()


func _get_current_room_size_cells() -> Vector2i:
	return world_room_controller.get_current_room_size_cells(GameplayTuningClass.ROOM_MIN_SIZE_CELLS)


func _get_current_room_surface_props() -> Array:
	return world_room_controller.get_current_room_surface_props()


func _get_current_room_protected_cells() -> Dictionary:
	return world_room_controller.get_current_room_protected_cells()


func _get_surface_cell_y_for_room(room_size_cells: Vector2i) -> int:
	return world_room_controller.get_surface_cell_y_for_room(room_size_cells)


func _get_current_room_surface_cell_y() -> int:
	return world_room_controller.get_current_room_surface_cell_y(GameplayTuningClass.ROOM_MIN_SIZE_CELLS)


func _is_cell_mining_protected(cell_position: Vector2i) -> bool:
	return _get_current_room_protected_cells().has(cell_position)


func _rocks_collide_with_rect(test_rect: Rect2) -> bool:
	for prop_entry in _get_current_room_surface_props():
		if String(prop_entry.get("type", "")) != SURFACE_PROP_ROCK:
			continue

		if _get_surface_prop_collision_rect(prop_entry).intersects(test_rect):
			return true

	return false


func _get_surface_prop_collision_rect(prop_entry: Dictionary) -> Rect2:
	var base_cell: Vector2i = Vector2i(prop_entry.get("base_cell", Vector2i.ZERO))
	var width_cells: int = int(prop_entry.get("width_cells", prop_entry.get("footprint_width_cells", 1)))
	var height_cells: int = int(prop_entry.get("height_cells", 1))
	var base_world: Vector2 = WorldUtilsClass.cell_to_world(base_cell)
	var prop_size: Vector2 = _get_world_size_from_cells(Vector2i(width_cells, height_cells))
	return Rect2(
		Vector2(base_world.x, base_world.y - prop_size.y),
		prop_size
	)


func _clear_room_entry_at_position(entry_position: Vector2) -> void:
	var player_size: Vector2 = _get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS)
	var room_rect: Rect2 = _get_room_world_rect()
	var side_padding: float = float(WorldConstantsClass.CELL_SIZE.x)
	var top_padding: float = float(WorldConstantsClass.CELL_SIZE.y * 2)
	var clear_rect: Rect2 = room_transition_controller.build_room_entry_clear_rect(
		entry_position,
		room_rect,
		player_size,
		side_padding,
		top_padding
	)

	var start_cell: Vector2i = WorldUtilsClass.world_to_cell(clear_rect.position)
	var end_cell: Vector2i = WorldUtilsClass.world_to_cell(clear_rect.end - Vector2.ONE)

	for cell_y in range(start_cell.y, end_cell.y + 1):
		for cell_x in range(start_cell.x, end_cell.x + 1):
			var cell_position: Vector2i = Vector2i(cell_x, cell_y)
			if _is_cell_inside_room(cell_position):
				world_data.remove_cell(cell_position)
				world_data.remove_damage_progress(cell_position)


func _has_adjacent_room(room_edge: String) -> bool:
	return world_room_controller.has_adjacent_room(room_edge)


func _get_adjacent_room_index(room_edge: String) -> int:
	return world_room_controller.get_adjacent_room_index(room_edge)


func _get_target_world_position() -> Vector2:
	return mining_runtime.get_target_world_position(_get_player_center_world(), get_global_mouse_position())


func _get_preview_cells() -> Array[Vector2i]:
	return mining_runtime.get_preview_cells(
		debug_settings.mining_shape,
		mining_center_cell,
		debug_settings.mining_radius
	)


func _get_ordered_preview_cells() -> Array[Vector2i]:
	return mining_runtime.get_ordered_preview_cells(
		debug_settings.mining_shape,
		mining_center_cell,
		debug_settings.mining_radius,
		_get_player_center_world(),
		Callable(self, "_get_cell_center_world")
	)


func _get_traversal_index(cell_position: Vector2i) -> int:
	return mining_runtime.get_traversal_index(
		cell_position,
		debug_settings.mining_shape,
		mining_center_cell,
		debug_settings.mining_radius,
		_get_player_center_world(),
		Callable(self, "_get_cell_center_world")
	)


func _is_mining_target_in_range() -> bool:
	return mining_runtime.is_mining_target_in_range(
		_get_player_center_world(),
		_get_cell_center_world(mining_center_cell)
	)


func _should_show_mining_cone_cursor() -> bool:
	if _is_gravity_build_mode_active():
		return false
	return player_cursor_controller.get_current_cursor_behavior() == CursorBehaviorDefinitionClass.CursorBehavior.MINE_CONE


func _should_show_place_cursor() -> bool:
	if _is_gravity_build_mode_active():
		return false
	return player_cursor_controller.get_current_cursor_behavior() == CursorBehaviorDefinitionClass.CursorBehavior.PLACE


func _is_gravity_build_mode_active() -> bool:
	return build_mode_runtime.is_gravity_build_mode_active()


func _is_player_inside_gravity_field() -> bool:
	return world_player_controller.is_player_inside_gravity_field(
		player_world_position,
		gravity_field_system,
		Callable(self, "_get_world_size_from_cells")
	)


func _get_gravity_acceleration_at_player() -> Vector2:
	return world_player_controller.get_gravity_acceleration_at_player(
		player_world_position,
		gravity_field_system,
		Callable(self, "_get_world_size_from_cells")
	)


func _set_build_mode(next_build_mode: int) -> void:
	var result: Dictionary = gravity_interaction_controller.set_build_mode(build_mode_runtime, next_build_mode)
	block_mining_until_left_released = bool(result.get("block_mining_until_left_released", true))
	print("[GodModeGravity] build mode: %s" % String(result.get("build_mode_name", _get_build_mode_name())))
	godmode_ui_controller.update_time_hud()
	godmode_ui_controller.refresh_godmode_ui()
	queue_redraw()


func _clear_build_mode() -> void:
	var result: Dictionary = gravity_interaction_controller.clear_build_mode(build_mode_runtime)
	if not bool(result.get("changed", false)):
		return
	block_mining_until_left_released = bool(result.get("block_mining_until_left_released", true))
	godmode_ui_controller.update_time_hud()
	godmode_ui_controller.refresh_godmode_ui()


func _handle_gravity_build_click() -> void:
	var result: Dictionary = gravity_interaction_controller.handle_gravity_build_click(
		build_mode_runtime,
		mining_center_cell,
		_get_ordered_preview_cells(),
		Callable(self, "_get_gravity_field_preview_rect"),
		Callable(self, "_get_cell_center_world")
	)
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
	return build_mode_runtime.get_gravity_field_preview_rect(mining_center_cell, _get_ordered_preview_cells())


func _get_build_mode_name() -> String:
	return build_mode_runtime.get_build_mode_name()


func _get_gravity_strength_for_level(level_index: int) -> float:
	return build_mode_runtime.get_gravity_strength_for_level(level_index)


func _can_mine_with_equipped_tool() -> bool:
	return mining_runtime.can_mine_with_equipped_tool(
		player_equipment,
		player_cursor_controller.get_current_cursor_behavior(),
		_is_gravity_build_mode_active()
	)


func _get_player_center_world() -> Vector2:
	return world_player_controller.get_player_center_world(
		player_world_position,
		Callable(self, "_get_world_size_from_cells")
	)


func _get_player_world_rect() -> Rect2:
	return world_player_controller.get_player_world_rect(
		player_world_position,
		Callable(self, "_get_world_size_from_cells")
	)


func _get_player_ground_world() -> Vector2:
	return world_player_controller.get_player_ground_world(
		player_world_position,
		Callable(self, "_get_world_size_from_cells")
	)


func _update_player_follow_target() -> void:
	if world_spawn_controller == null:
		return

	world_spawn_controller.update_player_follow_target(_get_player_ground_world())


func _get_cell_center_world(cell_position: Vector2i) -> Vector2:
	return WorldUtilsClass.cell_to_world(cell_position) + (Vector2(WorldConstantsClass.CELL_SIZE) * 0.5)


func _get_world_size_from_cells(size_cells: Vector2i) -> Vector2:
	return Vector2(
		size_cells.x * WorldConstantsClass.CELL_SIZE.x,
		size_cells.y * WorldConstantsClass.CELL_SIZE.y
	)
func _get_cell_type_name(cell_type: int) -> String:
	return WorldMaterialsClass.get_display_name(cell_type)


func _get_shape_name(shape_type: int) -> String:
	return mining_runtime.get_shape_name(shape_type)


func _try_place_preview_cells() -> bool:
	var result: Dictionary = mining_runtime.try_place_preview_cells({
		"inventory_data": inventory_data,
		"is_cell_inside_room": Callable(self, "_is_cell_inside_room"),
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


func _can_place_any_preview_cells() -> bool:
	return mining_runtime.can_place_any_preview_cells({
		"inventory_data": inventory_data,
		"is_cell_inside_room": Callable(self, "_is_cell_inside_room"),
		"ordered_preview_cells": _get_ordered_preview_cells(),
		"player_center_world": _get_player_center_world(),
		"player_contains_cell": Callable(self, "_player_contains_cell"),
		"selected_material_id": inventory_runtime.selected_material_id,
		"target_center_world": _get_cell_center_world(mining_center_cell),
		"world_data": world_data,
	})


func _can_place_cell(cell_position: Vector2i) -> bool:
	return mining_runtime.can_place_cell(
		cell_position,
		world_data,
		Callable(self, "_is_cell_inside_room"),
		Callable(self, "_player_contains_cell")
	)


func _has_hovered_drop() -> bool:
	return hovered_drop_index >= 0


func _player_contains_cell(cell_position: Vector2i) -> bool:
	var player_rect: Rect2 = Rect2(player_world_position, _get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS))
	var cell_rect: Rect2 = Rect2(WorldUtilsClass.cell_to_world(cell_position), Vector2(WorldConstantsClass.CELL_SIZE))
	return player_rect.intersects(cell_rect)


func _get_selected_material_color() -> Color:
	return inventory_runtime.get_selected_material_color()


func _get_drop_item_name(drop_entry: Dictionary) -> String:
	return inventory_runtime.get_drop_item_name(drop_entry)


func _get_drop_item_color(drop_entry: Dictionary) -> Color:
	return inventory_runtime.get_drop_item_color(drop_entry)


func _get_dominant_inventory_color() -> Color:
	return inventory_runtime.get_dominant_inventory_color()


func _set_inventory_capacity(capacity: int) -> void:
	inventory_runtime.set_inventory_capacity(capacity)
	godmode_ui_controller.refresh_godmode_ui()
	queue_redraw()


func _set_inventory_weight_capacity(weight_capacity: float) -> void:
	inventory_runtime.set_inventory_weight_capacity(weight_capacity)
	godmode_ui_controller.refresh_godmode_ui()
	queue_redraw()


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


func _get_item_drop_data() -> ItemDropData:
	return item_drop_data


func _get_gravity_field_system() -> GravityFieldSystem:
	return gravity_field_system


func _set_active_item_drop_data(next_item_drop_data: ItemDropData) -> void:
	item_drop_data = next_item_drop_data
	item_interaction_controller.set_item_drop_data(item_drop_data)


func _set_active_gravity_field_system(next_gravity_field_system: GravityFieldSystem) -> void:
	gravity_field_system = next_gravity_field_system
	build_mode_runtime.set_gravity_field_system(gravity_field_system)


func _sync_player_to_ground_after_respawn(next_player_position: Vector2) -> Vector2:
	player_world_position = next_player_position
	_snap_player_to_ground()
	return player_world_position


func _is_pointer_over_debug_ui_now() -> bool:
	return godmode_ui_controller.is_pointer_over_debug_ui(get_viewport().get_mouse_position())


func _get_selected_material_name() -> String:
	return _get_cell_type_name(inventory_runtime.selected_material_id)


func _select_gravity_strength(level_index: int) -> Dictionary:
	return gravity_interaction_controller.select_gravity_strength(build_mode_runtime, level_index)


func _set_debug_overlay_enabled(is_enabled: bool) -> void:
	debug_enabled = is_enabled
