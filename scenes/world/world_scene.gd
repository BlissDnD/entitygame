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
const WorldGenerationSurfaceControllerClass = preload("res://systems/world/world_generation_surface_controller.gd")
const CrashShipInteractionControllerClass = preload("res://systems/world/crash_ship_interaction_controller.gd")
const WorldRoomControllerClass = preload("res://systems/world/world_room_controller.gd")
const WorldSpawnControllerClass = preload("res://systems/world/world_spawn_controller.gd")
const BuildModeRuntimeClass = preload("res://systems/build/build_mode_runtime.gd")
const GodModeActionHandlerClass = preload("res://systems/debug/godmode_action_handler.gd")
const GodModeSnapshotBuilderClass = preload("res://systems/debug/godmode_snapshot_builder.gd")
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
var world_draw_controller = WorldDrawControllerClass.new()
var world_player_controller = WorldPlayerControllerClass.new()
var room_transition_controller = RoomTransitionControllerClass.new()
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
	_setup_sun_cycle()
	_setup_godmode_panel()
	item_interaction_controller.bind_scene_dependencies(spawn_manager, world_items)
	world_spawn_controller = WorldSpawnControllerClass.new(
		spawn_manager,
		persistent_followers,
		player_follow_target,
		MAX_ATLAS_WORKER_FOLLOWERS
	)
	_apply_view_resolution()
	_generate_rooms()
	camera_2d.ignore_rotation = true
	camera_2d.zoom = Vector2.ONE
	_set_current_room(0)
	_place_crash_ship_in_starting_room()
	player_world_position = _get_room_spawn_position()
	_set_console_visible(false)
	_update_godmode_visibility()
	_update_hover_state()
	_snap_player_to_ground()
	_spawn_initial_backpack_world_item()
	_update_player_follow_target()
	_apply_camera_tracking(-1.0)
	_update_time_hud()
	_refresh_godmode_ui()
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


func _setup_sun_cycle() -> void:
	time_manager.hour_changed.connect(_on_sun_cycle_hour_changed)
	time_manager.sun_room_changed.connect(_on_sun_cycle_sun_room_changed)
	time_manager.room_time_state_changed.connect(_on_room_time_state_changed)
	time_manager.configure(GameplayTuningClass.ROOM_COUNT, PlanetSunCycleClass.DEFAULT_HOUR_DURATION_SECONDS)


func _setup_godmode_panel() -> void:
	godmode_panel.mining_power_changed.connect(_on_godmode_mining_power_changed)
	godmode_panel.mining_radius_changed.connect(_on_godmode_mining_radius_changed)
	godmode_panel.mining_shape_changed.connect(_on_godmode_mining_shape_changed)
	godmode_panel.equip_tool_requested.connect(_on_equip_tool_button_pressed)
	godmode_panel.unequip_tool_requested.connect(_on_unequip_tool_button_pressed)
	godmode_panel.equip_backpack_requested.connect(_on_equip_backpack_button_pressed)
	godmode_panel.unequip_backpack_requested.connect(_on_unequip_backpack_button_pressed)
	godmode_panel.add_stone_requested.connect(_on_add_stone_button_pressed)
	godmode_panel.add_scrap_requested.connect(_on_add_scrap_button_pressed)
	godmode_panel.print_equipment_requested.connect(_on_print_equipment_button_pressed)
	godmode_panel.print_backpack_requested.connect(_on_print_backpack_button_pressed)
	godmode_panel.gravity_field_mode_requested.connect(_on_gravity_field_mode_requested)
	godmode_panel.gravity_point_mode_requested.connect(_on_gravity_point_mode_requested)
	godmode_panel.gravity_strength_selected.connect(_on_gravity_strength_selected)
	godmode_panel.time_forward_requested.connect(_on_time_forward_requested)
	godmode_panel.time_backward_requested.connect(_on_time_backward_requested)


func _process(delta: float) -> void:
	var should_redraw: bool = false
	if background_controller.update(delta):
		should_redraw = true
	if time_manager.advance(delta):
		should_redraw = true
		_refresh_godmode_ui()
	var was_transition_locked: bool = room_transition_lock_time > 0.0
	room_transition_lock_time = maxf(room_transition_lock_time - delta, 0.0)
	if was_transition_locked and room_transition_lock_time <= 0.0:
		print("player input unlocked; player movement enabled")

	if not _is_console_open() and not has_won and room_transition_lock_time <= 0.0:
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
	if event.is_action_pressed("toggle_console"):
		_toggle_console()
		get_viewport().set_input_as_handled()
		return

	if _is_console_open():
		return

	if event.is_action_pressed("interact"):
		if _try_interact_with_backpack_world_item() or _try_interact_with_crash_ship():
			queue_redraw()
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("drop_backpack"):
		_drop_equipped_backpack()
		queue_redraw()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if _is_pointer_over_debug_ui():
				return
			if _is_gravity_build_mode_active():
				_handle_gravity_build_click()
				get_viewport().set_input_as_handled()
				queue_redraw()
				return
			if _try_pick_up_hovered_drops():
				block_mining_until_left_released = true
				queue_redraw()
				return
			queue_redraw()
			return

		if event.button_index == MOUSE_BUTTON_RIGHT:
			if _is_pointer_over_debug_ui():
				return
			if _is_gravity_build_mode_active():
				_clear_build_mode()
				get_viewport().set_input_as_handled()
				queue_redraw()
				return
			if _should_show_place_cursor() and _try_place_preview_cells():
				queue_redraw()
			return

		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if _is_pointer_over_debug_ui():
				return
			has_inspected_cell = true
			inspected_cell = hovered_cell
			queue_redraw()
			return

		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if _is_pointer_over_debug_ui():
				return
			_cycle_selected_material(-1)
			queue_redraw()
			return

		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if _is_pointer_over_debug_ui():
				return
			_cycle_selected_material(1)
			queue_redraw()


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
		"is_pointer_over_debug_ui": _is_pointer_over_debug_ui(),
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
		_refresh_godmode_ui()
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
	var current_room_index: int = world_room_controller.set_current_room(room_index)
	map_handler.set_current_room(current_room_index)
	world_data = world_room_controller.get_current_room_world_data()
	item_drop_data = world_room_controller.get_current_room_drop_data()
	gravity_field_system = world_room_controller.get_current_room_gravity_field_system()
	world_renderer.set_world_data(world_data)
	item_interaction_controller.set_item_drop_data(item_drop_data)
	build_mode_runtime.set_gravity_field_system(gravity_field_system)
	_clear_build_mode()
	_update_crash_ship_visibility()
	_update_room_placeable_visibility()
	_update_room_npc_visibility()
	_print_world_boundary_debug()
	print("[SunCycle] current player room time state: %s" % time_manager.get_room_time_state_name(current_room_index))
	_start_background_fade(time_manager.get_room_light_color(current_room_index), "room changed")
	_update_time_hud()
	_refresh_godmode_ui()


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


func _try_interact_with_crash_ship() -> bool:
	var player_rect: Rect2 = Rect2(player_world_position, _get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS))
	return crash_ship_interaction_controller.try_interact_with_crash_ship(
		crash_ship,
		world_room_controller.get_current_room_index(),
		player_rect
	)


func _spawn_initial_backpack_world_item() -> void:
	item_interaction_controller.spawn_initial_backpack_world_item(
		_get_player_ground_world(),
		BasicBackpackItemDefinition,
		BackpackWorldItemScene
	)


func _try_interact_with_backpack_world_item() -> bool:
	var player_rect: Rect2 = Rect2(player_world_position, _get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS))
	var result: Dictionary = item_interaction_controller.try_interact_with_backpack_world_item(player_rect)
	if bool(result.get("did_change_inventory", false)):
		_refresh_godmode_ui()
	return bool(result.get("handled", false))


func _equip_backpack_item(item_definition: ItemDefinition, log_prefix: String) -> bool:
	var did_equip: bool = inventory_runtime.equip_backpack_item(item_definition, log_prefix)
	if did_equip:
		_refresh_godmode_ui()
	return did_equip


func _drop_equipped_backpack() -> void:
	if item_interaction_controller.drop_equipped_backpack(
		_get_player_ground_world(),
		Input.is_action_pressed("move_left"),
		BackpackWorldItemScene
	):
		_refresh_godmode_ui()


func _try_transition_room() -> bool:
	if room_transition_lock_time > 0.0:
		return false

	var room_edge: String = _get_room_transition_edge()
	if room_edge == ROOM_EDGE_NONE:
		return false

	var should_transition: bool = room_transition_controller.should_transition_for_edge(
		room_edge,
		Input.is_action_pressed("move_left"),
		Input.is_action_pressed("move_right"),
		Input.is_action_pressed("move_up"),
		Input.is_action_pressed("move_down")
	)

	if not should_transition:
		return false

	if room_edge == ROOM_EDGE_TOP or room_edge == ROOM_EDGE_BOTTOM:
		has_won = true
		player_velocity = Vector2.ZERO
		queue_redraw()
		return true

	var next_room_index: int = _get_adjacent_room_index(room_edge)
	if next_room_index == world_room_controller.get_current_room_index():
		return false

	print("room transition started from room %d to room %d via %s" % [world_room_controller.get_current_room_index(), next_room_index, room_edge])
	room_transition_lock_time = 0.12
	print("player input locked; player movement disabled")
	_set_current_room(next_room_index)
	_place_player_at_room_entry(room_edge)
	_reposition_active_atlas_workers_after_transition(room_edge)
	hovered_drop_index = -1
	has_inspected_cell = false
	_update_hover_state()
	print("transition completed in room %d at %s" % [world_room_controller.get_current_room_index(), player_world_position])
	queue_redraw()
	return true


func _place_player_at_room_entry(exit_edge: String) -> void:
	var room_rect: Rect2 = _get_room_world_rect()
	var player_size: Vector2 = _get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS)
	var entry_inset_pixels: float = GameplayTuningClass.ROOM_ENTRY_INSET_CELLS * WorldConstantsClass.CELL_SIZE.x
	var next_position: Vector2 = room_transition_controller.get_room_entry_position(
		exit_edge,
		room_rect,
		player_size,
		entry_inset_pixels,
		player_world_position
	)

	next_position = _clamp_player_to_room(next_position)
	if exit_edge == ROOM_EDGE_LEFT or exit_edge == ROOM_EDGE_RIGHT:
		_clear_room_entry_at_position(next_position)
	player_world_position = next_position
	player_velocity = Vector2.ZERO
	_resolve_player_after_room_transition()


func _resolve_player_after_room_transition() -> void:
	var guard_limit: int = WorldConstantsClass.CELL_SIZE.y * 8
	var guard_steps: int = 0

	while _player_collides_at(player_world_position) and guard_steps < guard_limit:
		player_world_position += Vector2.UP
		guard_steps += 1

	if guard_steps > 0:
		print("player transition collision resolved upward by %d px" % guard_steps)
	if _player_collides_at(player_world_position):
		print("player transition collision still blocked after resolve guard")


func _check_void_fall() -> bool:
	if is_handling_void_fall:
		return false

	var room_rect: Rect2 = _get_room_world_rect()
	var player_rect: Rect2 = Rect2(player_world_position, _get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS))
	var void_margin: float = GameplayTuningClass.VOID_FALL_MARGIN_CELLS * WorldConstantsClass.CELL_SIZE.x
	var void_depth: float = GameplayTuningClass.VOID_FALL_DEPTH_CELLS * WorldConstantsClass.CELL_SIZE.y
	if not room_transition_controller.should_trigger_void_fall(
		room_rect,
		player_rect,
		void_margin,
		void_depth,
		_is_outer_left_edge(),
		_is_outer_right_edge()
	):
		return false

	print(
		"Player fell off the planet edge at %s; void trigger left %.1f right %.1f below %.1f" % [
			player_world_position,
			room_rect.position.x - void_margin,
			room_rect.end.x + void_margin,
			room_rect.end.y + void_depth,
		]
	)
	on_fell_into_void()
	return true


func on_fell_into_void() -> void:
	is_handling_void_fall = true
	player_velocity = Vector2.ZERO
	player_world_position = _get_room_spawn_position()
	_snap_player_to_ground()
	_update_hover_state()
	print("Player respawned from void at %s" % [player_world_position])
	is_handling_void_fall = false


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
	var room_rect: Rect2 = _get_room_world_rect()
	var void_rect: Rect2 = _get_void_fall_rect()
	print(
		"World horizontal bounds room %d: left %.1f right %.1f; outer left %s outer right %s; void trigger left %.1f right %.1f below %.1f" % [
			map_handler.get_current_room_index(),
			room_rect.position.x,
			room_rect.end.x,
			str(_is_outer_left_edge()),
			str(_is_outer_right_edge()),
			void_rect.position.x,
			void_rect.end.x,
			void_rect.end.y,
		]
	)


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
	_update_time_hud()
	_refresh_godmode_ui()
	queue_redraw()


func _clear_build_mode() -> void:
	var result: Dictionary = gravity_interaction_controller.clear_build_mode(build_mode_runtime)
	if not bool(result.get("changed", false)):
		return
	block_mining_until_left_released = bool(result.get("block_mining_until_left_released", true))
	_update_time_hud()
	_refresh_godmode_ui()


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
		_update_time_hud()
	if bool(result.get("show_strength_popup", false)):
		godmode_panel.show_gravity_strength_popup()
	_refresh_godmode_ui()


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
		_refresh_godmode_ui()
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


func _try_pick_up_hovered_drops() -> bool:
	var result: Dictionary = item_interaction_controller.try_pick_up_hovered_drop(
		hovered_drop_index,
		get_global_mouse_position(),
		GameplayTuningClass.DROPPED_ITEM_HOVER_RADIUS_PIXELS
	)
	var picked_any: bool = bool(result.get("picked_any", false))
	if picked_any:
		hovered_drop_index = int(result.get("hovered_drop_index", hovered_drop_index))
		_refresh_godmode_ui()

	return picked_any


func _has_hovered_drop() -> bool:
	return hovered_drop_index >= 0


func _player_contains_cell(cell_position: Vector2i) -> bool:
	var player_rect: Rect2 = Rect2(player_world_position, _get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS))
	var cell_rect: Rect2 = Rect2(WorldUtilsClass.cell_to_world(cell_position), Vector2(WorldConstantsClass.CELL_SIZE))
	return player_rect.intersects(cell_rect)


func _cycle_selected_material(direction: int) -> void:
	if inventory_runtime.cycle_selected_material(direction):
		_refresh_godmode_ui()


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
	_refresh_godmode_ui()
	queue_redraw()


func _set_inventory_weight_capacity(weight_capacity: float) -> void:
	inventory_runtime.set_inventory_weight_capacity(weight_capacity)
	_refresh_godmode_ui()
	queue_redraw()


func _on_cursor_behavior_changed(cursor_behavior: int) -> void:
	match cursor_behavior:
		CursorBehaviorDefinitionClass.CursorBehavior.MINE_CONE:
			print("[Cursor] Mining cone cursor active")
		CursorBehaviorDefinitionClass.CursorBehavior.PLACE:
			print("[Cursor] Placement cursor active")
		_:
			print("[Cursor] Default cursor active")

	_refresh_godmode_ui()
	queue_redraw()


func _on_sun_cycle_hour_changed(new_hour: int) -> void:
	print("[SunCycle] hour changed: %d" % new_hour)
	_update_time_hud()


func _on_sun_cycle_sun_room_changed(new_room_index: int) -> void:
	print(time_debug_controller.format_sun_room_changed_message(
		new_room_index,
		str(world_draw_controller.get_sun_visual_world_position(_get_room_world_rect(), _get_current_room_surface_cell_y())) if world_draw_controller.is_sun_visual_in_current_room(time_manager, world_room_controller.get_current_room_index()) else "offscreen",
		world_room_controller.get_current_room_index()
	))


func _on_room_time_state_changed(room_index: int, old_state: int, new_state: int) -> void:
	print(time_debug_controller.format_room_time_state_changed_message(time_manager, room_index, old_state, new_state))
	if room_index == world_room_controller.get_current_room_index():
		print(time_debug_controller.format_player_room_time_state_message(time_manager, new_state))
		_start_background_fade(time_manager.get_room_light_color(world_room_controller.get_current_room_index()), "room time state changed")
		_update_time_hud()


func _get_time_hud_text() -> String:
	return time_debug_controller.build_time_hud_text(time_manager, map_handler)


func _update_time_hud() -> void:
	time_debug_controller.update_hud(ui_root, time_manager, map_handler, _get_build_mode_name())


func _toggle_console() -> void:
	_set_console_visible(not _is_console_open())
	queue_redraw()


func _set_console_visible(is_visible: bool) -> void:
	console_panel.visible = is_visible

	if is_visible:
		console_input.text = ""
		console_input.grab_focus()
	else:
		console_input.release_focus()


func _is_console_open() -> bool:
	return console_panel.visible


func _is_pointer_over_debug_ui() -> bool:
	if console_panel.visible and console_panel.get_global_rect().has_point(get_viewport().get_mouse_position()):
		return true

	if godmode_panel.visible and godmode_panel.get_global_rect().has_point(get_viewport().get_mouse_position()):
		return true

	return false


func _update_godmode_visibility() -> void:
	godmode_panel.set_visible_state(debug_settings.godmode_enabled)


func _refresh_godmode_ui() -> void:
	_update_godmode_visibility()
	godmode_panel.refresh(_build_godmode_snapshot())


func _build_godmode_snapshot() -> Dictionary:
	return godmode_snapshot_builder.build_snapshot(
		debug_settings,
		inventory_runtime,
		inventory_data,
		item_drop_data,
		gravity_field_system,
		player_equipment,
		backpack_container,
		player_cursor_controller,
		time_manager,
		map_handler,
		_get_build_mode_name(),
		_is_player_inside_gravity_field(),
		_get_cell_type_name(inventory_runtime.selected_material_id),
		_get_shape_name(debug_settings.mining_shape),
		_get_time_hud_text()
	)


func _get_equipped_tool_label() -> String:
	return godmode_snapshot_builder.get_equipped_tool_label(player_equipment)


func _get_equipped_backpack_label() -> String:
	return godmode_snapshot_builder.get_equipped_backpack_label(player_equipment)


func _get_backpack_contents_summary() -> String:
	return godmode_snapshot_builder.get_backpack_contents_summary(backpack_container)


func _on_console_input_text_submitted(new_text: String) -> void:
	var command: String = new_text.strip_edges().to_lower()
	var result: Dictionary = godmode_action_handler.handle_console_command(command, {
		"backpack_container": backpack_container,
		"basic_backpack_item_definition": BasicBackpackItemDefinition,
		"basic_mining_tool_definition": BasicMiningToolDefinition,
		"current_room_index": world_room_controller.get_current_room_index(),
		"debug_settings": debug_settings,
		"equip_backpack_item": Callable(self, "_equip_backpack_item"),
		"inventory_data": inventory_data,
		"inventory_runtime": inventory_runtime,
		"player_cursor_controller": player_cursor_controller,
		"player_equipment": player_equipment,
		"scrap_item_definition": ScrapItemDefinition,
		"set_debug_enabled": Callable(self, "_set_debug_overlay_enabled"),
		"set_inventory_capacity": Callable(self, "_set_inventory_capacity"),
		"set_inventory_weight_capacity": Callable(self, "_set_inventory_weight_capacity"),
		"start_background_fade": Callable(self, "_start_background_fade"),
		"stone_item_definition": StoneItemDefinition,
		"time_manager": time_manager,
	})
	if bool(result.get("close_console", false)):
		_set_console_visible(false)
	if bool(result.get("refresh_ui", false)):
		_refresh_godmode_ui()
	if bool(result.get("clear_console", true)):
		console_input.text = ""
	if bool(result.get("queue_redraw", false)):
		queue_redraw()


func _on_godmode_mining_power_changed(value: float) -> void:
	godmode_action_handler.apply_mining_power(value, debug_settings)
	_refresh_godmode_ui()
	queue_redraw()


func _on_godmode_mining_radius_changed(value: int) -> void:
	godmode_action_handler.apply_mining_radius(value, debug_settings)
	_refresh_godmode_ui()
	queue_redraw()


func _on_godmode_mining_shape_changed(shape: int) -> void:
	godmode_action_handler.apply_mining_shape(shape, debug_settings)
	_refresh_godmode_ui()
	queue_redraw()


func _run_godmode_item_ui_command(command: String) -> void:
	var result: Dictionary = godmode_action_handler.handle_item_command(command, {
		"backpack_container": backpack_container,
		"basic_backpack_item_definition": BasicBackpackItemDefinition,
		"basic_mining_tool_definition": BasicMiningToolDefinition,
		"current_room_index": world_room_controller.get_current_room_index(),
		"equip_backpack_item": Callable(self, "_equip_backpack_item"),
		"inventory_runtime": inventory_runtime,
		"player_cursor_controller": player_cursor_controller,
		"player_equipment": player_equipment,
		"scrap_item_definition": ScrapItemDefinition,
		"start_background_fade": Callable(self, "_start_background_fade"),
		"stone_item_definition": StoneItemDefinition,
		"time_manager": time_manager,
	})
	if bool(result.get("refresh_ui", false)):
		_refresh_godmode_ui()
	if bool(result.get("queue_redraw", false)):
		queue_redraw()


func _on_equip_tool_button_pressed() -> void:
	_run_godmode_item_ui_command("equip_mining_tool")


func _on_unequip_tool_button_pressed() -> void:
	_run_godmode_item_ui_command("unequip_mining_tool")


func _on_equip_backpack_button_pressed() -> void:
	_run_godmode_item_ui_command("equip_backpack")


func _on_unequip_backpack_button_pressed() -> void:
	_run_godmode_item_ui_command("unequip_backpack")


func _on_add_stone_button_pressed() -> void:
	_run_godmode_item_ui_command("add_stone")


func _on_add_scrap_button_pressed() -> void:
	_run_godmode_item_ui_command("add_scrap")


func _on_print_equipment_button_pressed() -> void:
	_run_godmode_item_ui_command("print_equipment")


func _on_print_backpack_button_pressed() -> void:
	_run_godmode_item_ui_command("print_backpack")


func _on_gravity_field_mode_requested() -> void:
	_set_build_mode(BuildModeRuntimeClass.BuildMode.GRAVITY_FIELD)


func _on_gravity_point_mode_requested() -> void:
	_set_build_mode(BuildModeRuntimeClass.BuildMode.GRAVITY_POINT)


func _on_gravity_strength_selected(level_index: int) -> void:
	var result: Dictionary = gravity_interaction_controller.select_gravity_strength(build_mode_runtime, level_index)
	print(String(result.get("log_message", "")))
	if not bool(result.get("success", false)):
		return
	_refresh_godmode_ui()
	queue_redraw()


func _on_time_forward_requested() -> void:
	var result: Dictionary = godmode_action_handler.handle_time_forward(
		time_manager,
		Callable(self, "_start_background_fade"),
		world_room_controller.get_current_room_index()
	)
	if bool(result.get("update_time_hud", false)):
		_update_time_hud()
	if bool(result.get("refresh_ui", false)):
		_refresh_godmode_ui()
	if bool(result.get("queue_redraw", false)):
		queue_redraw()


func _on_time_backward_requested() -> void:
	var result: Dictionary = godmode_action_handler.handle_time_backward()
	if bool(result.get("update_time_hud", false)):
		_update_time_hud()
	if bool(result.get("refresh_ui", false)):
		_refresh_godmode_ui()
	if bool(result.get("queue_redraw", false)):
		queue_redraw()


func _set_debug_overlay_enabled(is_enabled: bool) -> void:
	debug_enabled = is_enabled
