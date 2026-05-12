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
const InventoryDataClass = preload("res://systems/inventory/inventory_data.gd")
const ItemTypesClass = preload("res://systems/items/item_types.gd")
const EquipmentSlotClass = preload("res://systems/equipment/equipment_slot.gd")
const PlayerEquipmentClass = preload("res://systems/equipment/player_equipment.gd")
const BackpackContainerClass = preload("res://systems/backpack/backpack_container.gd")
const PlayerCursorControllerClass = preload("res://systems/cursor/player_cursor_controller.gd")
const CursorBehaviorDefinitionClass = preload("res://systems/cursor/cursor_behavior_definition.gd")
const PlanetSunCycleClass = preload("res://systems/time/planet_sun_cycle.gd")
const PlaceablePlacementServiceClass = preload("res://systems/placeables/placeable_placement_service.gd")
const GravityFieldSystemClass = preload("res://systems/world/gravity_field_system.gd")
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
const GRAVITY_FIELD_STRENGTH_MILESTONES = [180.0, 320.0, 520.0, 760.0, 980.0]

enum BuildMode {
	NONE,
	GRAVITY_FIELD,
	GRAVITY_POINT,
}

@export var starts_in_godmode: bool = false

var active_tool_profile: Dictionary = MiningToolProfilesClass.get_profile("starter_pickaxe")
var debug_settings = RuntimeDebugSettingsClass.new()
var world_data = WorldDataClass.new()
var world_renderer = WorldRendererClass.new(world_data)
var item_drop_data = ItemDropDataClass.new()
var inventory_data = InventoryDataClass.new(
	GameplayTuningClass.INVENTORY_CAPACITY,
	GameplayTuningClass.INVENTORY_WEIGHT_CAPACITY
)
var player_equipment = PlayerEquipmentClass.new()
var backpack_container = BackpackContainerClass.new()
var player_cursor_controller = PlayerCursorControllerClass.new()
var planet_sun_cycle = PlanetSunCycleClass.new()
var player_world_position: Vector2 = GameplayTuningClass.PLAYER_SPAWN_WORLD_POSITION
var player_velocity: Vector2 = Vector2.ZERO
var hovered_cell: Vector2i = Vector2i.ZERO
var mining_center_cell: Vector2i = Vector2i.ZERO
var debug_enabled: bool = GameplayTuningClass.DEBUG_OVERLAY_DEFAULT_ENABLED
var has_inspected_cell: bool = false
var inspected_cell: Vector2i = Vector2i.ZERO
var selected_material_id: int = GameplayTuningClass.DEFAULT_SELECTED_MATERIAL
var block_mining_until_left_released: bool = false
var hovered_drop_index: int = -1
var last_render_stats: Dictionary = {}
var room_world_data_list: Array = []
var room_drop_data_list: Array = []
var room_size_cells_list: Array[Vector2i] = []
var room_surface_props_list: Array = []
var room_protected_cells_list: Array = []
var room_placeable_container_list: Array[Node2D] = []
var room_npc_container_list: Array[Node2D] = []
var room_gravity_field_system_list: Array[GravityFieldSystem] = []
var active_atlas_workers: Array[AtlasWorker] = []
var gravity_field_system: GravityFieldSystem = GravityFieldSystemClass.new()
var current_build_mode: int = BuildMode.NONE
var pending_gravity_strength_field: GravityFieldData = null
var current_room_index: int = 0
var room_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var has_won: bool = false
var is_handling_void_fall: bool = false
var room_transition_lock_time: float = 0.0
var run_hold_time: float = 0.0
var last_run_direction: int = 0
var world_backpack_items: Array[BackpackWorldItem] = []
var has_spawned_initial_backpack: bool = false
var has_printed_missing_mining_tool_warning: bool = false
var background_controller = WorldBackgroundControllerClass.new()

@onready var camera_2d: Camera2D = $camera_2d
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
	planet_sun_cycle.hour_changed.connect(_on_sun_cycle_hour_changed)
	planet_sun_cycle.sun_room_changed.connect(_on_sun_cycle_sun_room_changed)
	planet_sun_cycle.room_time_state_changed.connect(_on_room_time_state_changed)
	planet_sun_cycle.configure(GameplayTuningClass.ROOM_COUNT, PlanetSunCycleClass.DEFAULT_HOUR_DURATION_SECONDS)


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
	if planet_sun_cycle.advance(delta):
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

	draw_rect(Rect2(view_origin, view_size), background_controller.get_current_color(), true)
	_draw_sun()
	last_render_stats = world_renderer.draw_visible_chunks(self, view_origin, view_size)
	_draw_room_bounds()
	_draw_surface_props()
	_draw_item_drops()
	if debug_enabled:
		if _should_show_mining_cone_cursor():
			_draw_mining_range()
		if not _has_hovered_drop():
			_draw_hovered_center()
	if not _has_hovered_drop():
		if _should_show_mining_cone_cursor():
			_draw_mining_preview()
		elif _should_show_place_cursor():
			_draw_placement_preview()

	_draw_player()
	_draw_carried_material_pile()
	_draw_gravity_fields()

	if debug_enabled:
		_draw_labels()

	if _has_hovered_drop():
		_draw_drop_tooltip()

	_draw_room_transition_arrow()
	_draw_room_tooltip()

	if has_won:
		draw_rect(Rect2(view_origin, view_size), Color(0.18, 0.9, 0.24, 0.78), true)


func _update_player(delta: float) -> bool:
	if _is_player_inside_gravity_field():
		return _update_player_in_gravity_field(delta)

	var previous_position: Vector2 = player_world_position
	var input_axis: float = Input.get_axis("move_left", "move_right")
	var is_on_floor: bool = _is_player_on_floor()
	var move_direction: int = int(signf(input_axis))
	var speed_multiplier: float = _update_run_speed_multiplier(delta, move_direction, is_on_floor)
	var horizontal_speed: float = input_axis * GameplayTuningClass.PLAYER_MOVE_SPEED * speed_multiplier

	player_velocity.y += GameplayTuningClass.PLAYER_GRAVITY * delta

	if Input.is_action_just_pressed("move_up") and is_on_floor:
		player_velocity.y = GameplayTuningClass.PLAYER_JUMP_VELOCITY

	if is_on_floor:
		player_velocity.x = 0.0
		var max_step_up_cells: int = GameplayTuningClass.PLAYER_STEP_UP_BASE_CELLS
		if speed_multiplier >= GameplayTuningClass.PLAYER_FAST_STEP_THRESHOLD:
			max_step_up_cells = GameplayTuningClass.PLAYER_STEP_UP_FAST_CELLS
		_move_player_grounded(horizontal_speed * delta, max_step_up_cells * WorldConstantsClass.CELL_SIZE.y)
		if player_velocity.y > 0.0:
			player_velocity.y = 0.0
	else:
		player_velocity.x = horizontal_speed

	if is_on_floor:
		_move_player(Vector2(0.0, player_velocity.y * delta))
	else:
		_move_player(Vector2(player_velocity.x * delta, player_velocity.y * delta))

	if _is_player_on_floor():
		player_velocity.y = minf(player_velocity.y, 0.0)

	return player_world_position != previous_position


func _update_player_in_gravity_field(delta: float) -> bool:
	var previous_position: Vector2 = player_world_position
	var input_axis: float = Input.get_axis("move_left", "move_right")
	var gravity_acceleration: Vector2 = _get_gravity_acceleration_at_player()

	player_velocity += gravity_acceleration * delta
	player_velocity.x += input_axis * GameplayTuningClass.PLAYER_MOVE_SPEED * delta * 2.0

	if Input.is_action_just_pressed("move_up") and gravity_acceleration != Vector2.ZERO:
		player_velocity += -gravity_acceleration.normalized() * absf(GameplayTuningClass.PLAYER_JUMP_VELOCITY)

	var intended_motion: Vector2 = player_velocity * delta
	_move_player(intended_motion)

	if is_equal_approx(player_world_position.x, previous_position.x) and not is_zero_approx(intended_motion.x):
		player_velocity.x = 0.0
	if is_equal_approx(player_world_position.y, previous_position.y) and not is_zero_approx(intended_motion.y):
		player_velocity.y = 0.0

	return player_world_position != previous_position


func _move_player_grounded(surface_distance: float, max_step_up_pixels: int) -> void:
	if is_zero_approx(surface_distance):
		return

	var remaining_distance: float = surface_distance
	var step_sign: float = signf(surface_distance)
	var guard_steps: int = 0
	var guard_limit: int = 4096

	while absf(remaining_distance) > 0.0 and guard_steps < guard_limit:
		var step_distance: float = minf(absf(remaining_distance), 1.0)
		var next_position: Vector2 = _clamp_player_to_room(player_world_position + Vector2(step_sign * step_distance, 0.0))
		var resolved_position: Vector2 = _resolve_grounded_step_position(next_position, max_step_up_pixels)
		if resolved_position == player_world_position:
			break

		player_world_position = resolved_position
		_settle_player_to_floor(WorldConstantsClass.CELL_SIZE.y + 2)
		remaining_distance -= step_distance * step_sign
		guard_steps += 1


func _resolve_grounded_step_position(next_position: Vector2, max_step_up_pixels: int) -> Vector2:
	if not _player_collides_at(next_position):
		return next_position

	for outward_steps in range(1, maxi(max_step_up_pixels, 1) + 1):
		var adjusted_position: Vector2 = next_position + Vector2(0.0, -float(outward_steps))
		if not _player_collides_at(adjusted_position):
			return adjusted_position

	return player_world_position


func _settle_player_to_floor(max_steps: int) -> void:
	for step_index in range(max_steps):
		if _is_player_on_floor():
			return

		var next_position: Vector2 = player_world_position + Vector2.DOWN
		if _player_collides_at(next_position):
			return

		player_world_position = next_position


func _update_mining(delta: float) -> bool:
	if _is_gravity_build_mode_active():
		return false

	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		block_mining_until_left_released = false
		has_printed_missing_mining_tool_warning = false
		return false

	if block_mining_until_left_released:
		return false

	if _is_pointer_over_debug_ui():
		return false

	if not _can_mine_with_equipped_tool():
		if not has_printed_missing_mining_tool_warning:
			print("[Mining] Cannot mine: no mining tool equipped")
			has_printed_missing_mining_tool_warning = true
		return false

	if not _is_mining_target_in_range():
		return false

	var changed: bool = false
	var ordered_cells: Array[Vector2i] = _get_ordered_preview_cells()
	var cell_count: int = maxi(ordered_cells.size() - 1, 1)

	for index in range(ordered_cells.size()):
		var cell_position: Vector2i = ordered_cells[index]
		var cell_type: int = world_data.get_cell(cell_position)
		if cell_type == WorldConstantsClass.CellType.AIR:
			continue
		if _is_cell_mining_protected(cell_position):
			continue

		var material_tags: PackedStringArray = WorldMaterialsClass.get_material_tags(cell_type)
		if not material_tags.has("mineable"):
			continue

		var resistance: float = WorldMaterialsClass.get_mining_resistance(cell_type)
		if resistance <= 0.0:
			continue

		var falloff_multiplier: float = float(active_tool_profile.get("mining_falloff_multiplier", 0.45))
		var order_factor: float = 1.0

		if GameplayTuningClass.MINING_USE_DIRECTIONAL_SPEED_FALLOFF:
			order_factor = lerpf(
				1.0,
				falloff_multiplier,
				float(index) / float(cell_count)
			)

		var progress_per_second: float = (debug_settings.mining_power / resistance) * order_factor
		var progress: float = world_data.add_damage_progress(cell_position, progress_per_second * delta)
		changed = true

		if progress >= 1.0:
			var accepted_amount: int = inventory_data.add_material(cell_type, 1)
			world_data.remove_cell(cell_position)
			world_data.remove_damage_progress(cell_position)

			if accepted_amount <= 0:
				item_drop_data.add_item_stack(
					_get_cell_center_world(cell_position),
					"material",
					cell_type,
					1,
					GameplayTuningClass.DROPPED_ITEM_MERGE_RADIUS_PIXELS
				)

			_refresh_godmode_ui()

	return changed


func _update_run_speed_multiplier(delta: float, move_direction: int, is_on_floor: bool) -> float:
	if not is_on_floor or move_direction == 0:
		run_hold_time = 0.0
		last_run_direction = move_direction
		return 1.0

	if move_direction != last_run_direction:
		run_hold_time = 0.0

	run_hold_time = minf(run_hold_time + delta, GameplayTuningClass.PLAYER_RUN_BOOST_TIME)
	last_run_direction = move_direction

	var boost_t: float = 1.0
	if GameplayTuningClass.PLAYER_RUN_BOOST_TIME > 0.0:
		boost_t = clampf(run_hold_time / GameplayTuningClass.PLAYER_RUN_BOOST_TIME, 0.0, 1.0)

	return lerpf(1.0, GameplayTuningClass.PLAYER_RUN_BOOST_MULTIPLIER, boost_t)


func _update_item_drops(delta: float) -> bool:
	var previous_drop_count: int = item_drop_data.get_drops().size()
	item_drop_data.update_physics(
		world_data,
		delta,
		_get_room_world_rect(),
		GameplayTuningClass.DROPPED_ITEM_GRAVITY,
		GameplayTuningClass.DROPPED_ITEM_PULL_RADIUS_PIXELS,
		GameplayTuningClass.DROPPED_ITEM_MERGE_RADIUS_PIXELS,
		gravity_field_system
	)
	return previous_drop_count != item_drop_data.get_drops().size() or previous_drop_count > 0


func _update_hover_state() -> bool:
	var next_hovered_cell: Vector2i = WorldUtilsClass.world_to_cell(get_global_mouse_position())
	var next_mining_center_cell: Vector2i = WorldUtilsClass.world_to_cell(_get_target_world_position())
	var next_hovered_drop_index: int = item_drop_data.find_nearest_drop_index(
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


func _draw_player() -> void:
	var player_size: Vector2 = _get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS)
	var player_center: Vector2 = _get_player_center_world()
	var player_rect: Rect2 = Rect2(player_center - (player_size * 0.5), player_size)
	draw_rect(player_rect, GameplayTuningClass.PLAYER_DEBUG_COLOR, true)
	draw_rect(player_rect, GameplayTuningClass.PLAYER_DEBUG_OUTLINE_COLOR, false, 2.0)


func _draw_room_bounds() -> void:
	draw_rect(_get_room_world_rect(), GameplayTuningClass.ROOM_EDGE_COLOR, false, 2.0)


func _draw_room_transition_arrow() -> void:
	var room_edge: String = _get_room_transition_edge()
	if room_edge == ROOM_EDGE_NONE:
		return

	var player_center: Vector2 = _get_player_center_world()
	var room_rect: Rect2 = _get_room_world_rect()
	var arrow_size: Vector2 = Vector2(18.0, 14.0)
	var arrow_points: PackedVector2Array = PackedVector2Array()

	match room_edge:
		ROOM_EDGE_LEFT:
			var left_center: Vector2 = Vector2(room_rect.position.x + 16.0, player_center.y)
			arrow_points = PackedVector2Array([
				left_center + Vector2(-arrow_size.x * 0.5, 0.0),
				left_center + Vector2(arrow_size.x * 0.5, -arrow_size.y * 0.5),
				left_center + Vector2(arrow_size.x * 0.5, arrow_size.y * 0.5),
			])
		ROOM_EDGE_RIGHT:
			var right_center: Vector2 = Vector2(room_rect.end.x - 16.0, player_center.y)
			arrow_points = PackedVector2Array([
				right_center + Vector2(arrow_size.x * 0.5, 0.0),
				right_center + Vector2(-arrow_size.x * 0.5, -arrow_size.y * 0.5),
				right_center + Vector2(-arrow_size.x * 0.5, arrow_size.y * 0.5),
			])
		ROOM_EDGE_TOP:
			var top_center: Vector2 = Vector2(player_center.x, room_rect.position.y + 16.0)
			arrow_points = PackedVector2Array([
				top_center + Vector2(0.0, -arrow_size.x * 0.5),
				top_center + Vector2(-arrow_size.y * 0.5, arrow_size.x * 0.5),
				top_center + Vector2(arrow_size.y * 0.5, arrow_size.x * 0.5),
			])
		ROOM_EDGE_BOTTOM:
			var bottom_center: Vector2 = Vector2(player_center.x, room_rect.end.y - 16.0)
			arrow_points = PackedVector2Array([
				bottom_center + Vector2(0.0, arrow_size.x * 0.5),
				bottom_center + Vector2(-arrow_size.y * 0.5, -arrow_size.x * 0.5),
				bottom_center + Vector2(arrow_size.y * 0.5, -arrow_size.x * 0.5),
			])

	if not arrow_points.is_empty():
		draw_colored_polygon(arrow_points, GameplayTuningClass.ROOM_TRANSITION_ARROW_COLOR)


func _draw_room_tooltip() -> void:
	var font: Font = ThemeDB.fallback_font
	if font == null:
		return

	var font_size: int = ThemeDB.fallback_font_size
	var tooltip_text: String = "Room %d / %d" % [
		current_room_index + 1,
		maxi(room_world_data_list.size(), 1)
	]
	tooltip_text += "  %s H%02d" % [
		planet_sun_cycle.get_room_time_state_name(current_room_index),
		planet_sun_cycle.get_current_hour()
	]
	var text_size: Vector2 = font.get_string_size(tooltip_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	var view_origin: Vector2 = _get_view_origin_world()
	var view_size: Vector2 = _get_viewport_world_size()
	var padding: Vector2 = Vector2(8.0, 5.0)
	var tooltip_rect: Rect2 = Rect2(
		Vector2(
			view_origin.x + (view_size.x - text_size.x - (padding.x * 2.0)) * 0.5,
			view_origin.y + 10.0
		),
		text_size + (padding * 2.0)
	)

	draw_rect(tooltip_rect, Color(0.08, 0.09, 0.12, 0.9), true)
	draw_rect(tooltip_rect, GameplayTuningClass.ROOM_EDGE_COLOR, false, 1.0)
	draw_string(
		font,
		tooltip_rect.position + Vector2(padding.x, padding.y + font_size),
		tooltip_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size,
		Color(1.0, 1.0, 1.0, 1.0)
	)


func _start_background_fade(next_color: Color, reason: String) -> void:
	if background_controller.get_target_color() == next_color and background_controller.is_fading():
		return

	background_controller.start_fade(next_color, reason, planet_sun_cycle.get_room_time_state_name(current_room_index))
	queue_redraw()


func _set_background_color_immediate(next_color: Color) -> void:
	background_controller.set_color_immediate(next_color)


func _draw_sun() -> void:
	if not _is_sun_visual_in_current_room():
		return

	var sun_position: Vector2 = _get_sun_visual_world_position()

	draw_circle(sun_position, SUN_VISUAL_RADIUS * 1.45, Color(1.0, 0.82, 0.18, 0.16))
	draw_circle(sun_position, SUN_VISUAL_RADIUS, Color(1.0, 0.88, 0.16, 1.0))
	draw_arc(sun_position, SUN_VISUAL_RADIUS + 2.0, 0.0, TAU, 48, Color(1.0, 0.98, 0.45, 0.95), 2.0)


func _get_sun_visual_world_position() -> Vector2:
	var room_rect: Rect2 = _get_room_world_rect()
	var surface_world_y: float = WorldUtilsClass.cell_to_world(Vector2i(0, _get_current_room_surface_cell_y())).y
	return Vector2(
		room_rect.position.x + (room_rect.size.x * 0.5),
		maxf(room_rect.position.y + 42.0, surface_world_y - 118.0)
	)


func _is_sun_visual_in_current_room() -> bool:
	return planet_sun_cycle.get_sun_room_index() == current_room_index


func _draw_surface_props() -> void:
	for prop_entry in _get_current_room_surface_props():
		var prop_type: String = String(prop_entry.get("type", ""))
		var base_cell: Vector2i = Vector2i(prop_entry.get("base_cell", Vector2i.ZERO))
		var base_world: Vector2 = WorldUtilsClass.cell_to_world(base_cell)

		match prop_type:
			SURFACE_PROP_BUSH:
				var bush_width_cells: int = int(prop_entry.get("width_cells", 3))
				var bush_height_cells: int = int(prop_entry.get("height_cells", 1))
				var bush_size: Vector2 = _get_world_size_from_cells(Vector2i(bush_width_cells, bush_height_cells))
				var bush_center: Vector2 = base_world + Vector2(bush_size.x * 0.5, 0.0)
				draw_circle(bush_center + Vector2(-bush_size.x * 0.2, -bush_size.y * 0.35), bush_size.x * 0.22, GameplayTuningClass.BUSH_COLOR)
				draw_circle(bush_center + Vector2(0.0, -bush_size.y * 0.5), bush_size.x * 0.26, GameplayTuningClass.BUSH_COLOR)
				draw_circle(bush_center + Vector2(bush_size.x * 0.22, -bush_size.y * 0.34), bush_size.x * 0.2, GameplayTuningClass.BUSH_COLOR)
			SURFACE_PROP_ROCK:
				var rock_width_cells: int = int(prop_entry.get("width_cells", 2))
				var rock_height_cells: int = int(prop_entry.get("height_cells", 1))
				var rock_size: Vector2 = _get_world_size_from_cells(Vector2i(rock_width_cells, rock_height_cells))
				var rock_rect: Rect2 = Rect2(
					Vector2(base_world.x, base_world.y - rock_size.y),
					rock_size
				)
				var rock_points: PackedVector2Array = PackedVector2Array([
					rock_rect.position + Vector2(rock_rect.size.x * 0.08, rock_rect.size.y),
					rock_rect.position + Vector2(rock_rect.size.x * 0.22, rock_rect.size.y * 0.22),
					rock_rect.position + Vector2(rock_rect.size.x * 0.56, 0.0),
					rock_rect.position + Vector2(rock_rect.size.x * 0.9, rock_rect.size.y * 0.18),
					rock_rect.position + Vector2(rock_rect.size.x, rock_rect.size.y * 0.76),
					rock_rect.position + Vector2(rock_rect.size.x * 0.72, rock_rect.size.y),
				])
				draw_colored_polygon(rock_points, GameplayTuningClass.ROCK_COLOR)


func _draw_item_drops() -> void:
	for drop_index in range(item_drop_data.get_drops().size()):
		var drop_entry: Dictionary = item_drop_data.get_drop_at_index(drop_index)
		var item_id: int = int(drop_entry.get("item_id", WorldConstantsClass.CellType.AIR))
		var amount: int = int(drop_entry.get("amount", 0))
		if amount <= 0:
			continue

		var base_color: Color = _get_drop_item_color(drop_entry)
		var drop_center: Vector2 = Vector2(drop_entry.get("world_position", Vector2.ZERO))
		var stack_layers: int = mini(amount, 3)
		var is_hovered_drop: bool = drop_index == hovered_drop_index
		var amount_ratio: float = clampf(
			float(amount) / float(maxi(GameplayTuningClass.DROPPED_ITEM_PILE_MAX_VISUAL_COUNT, 1)),
			0.0,
			1.0
		)
		var pile_scale: float = lerpf(
			GameplayTuningClass.DROPPED_ITEM_PILE_MIN_SCALE,
			GameplayTuningClass.DROPPED_ITEM_PILE_MAX_SCALE,
			amount_ratio
		)

		for layer_index in range(stack_layers):
			var radius_scale: float = (1.0 - (float(layer_index) * 0.12)) * pile_scale
			if is_hovered_drop:
				radius_scale += 0.12
			var layer_center: Vector2 = drop_center + Vector2(
				0.0,
				-GameplayTuningClass.DROPPED_MATERIAL_STACK_OFFSET * pile_scale * float(layer_index)
			)
			var layer_color: Color = Color(
				minf(base_color.r * (1.0 + float(layer_index) * 0.05 + (0.12 if is_hovered_drop else 0.0)), 1.0),
				minf(base_color.g * (1.0 + float(layer_index) * 0.05 + (0.12 if is_hovered_drop else 0.0)), 1.0),
				minf(base_color.b * (1.0 + float(layer_index) * 0.05 + (0.12 if is_hovered_drop else 0.0)), 1.0),
				0.95
			)
			draw_circle(layer_center, GameplayTuningClass.DROPPED_MATERIAL_VISUAL_RADIUS * radius_scale, layer_color)

		if is_hovered_drop:
			var drop_rect: Rect2 = Rect2(
				drop_center - Vector2(WorldConstantsClass.CELL_SIZE.x * 0.5, WorldConstantsClass.CELL_SIZE.y * 0.5),
				Vector2(WorldConstantsClass.CELL_SIZE)
			)
			draw_rect(drop_rect, GameplayTuningClass.DROPPED_MATERIAL_HOVER_OUTLINE_COLOR, false, 1.0)


func _draw_gravity_fields() -> void:
	if not debug_settings.godmode_enabled:
		return

	for field in gravity_field_system.get_fields():
		var field_color: Color = Color(0.4, 0.65, 1.0, 0.12)
		var outline_color: Color = Color(0.45, 0.75, 1.0, 0.85)
		draw_rect(field.bounds, field_color, true)
		draw_rect(field.bounds, outline_color, false, 2.0)
		if field.has_gravity_point:
			draw_circle(field.gravity_point, 5.0, Color(0.25, 0.95, 1.0, 0.95))
			draw_line(field.bounds.get_center(), field.gravity_point, Color(0.25, 0.95, 1.0, 0.45), 1.0)

	if current_build_mode == BuildMode.GRAVITY_FIELD:
		var preview_rect: Rect2 = _get_gravity_field_preview_rect()
		draw_rect(preview_rect, Color(0.35, 0.7, 1.0, 0.14), true)
		draw_rect(preview_rect, Color(0.35, 0.7, 1.0, 0.88), false, 2.0)
	elif current_build_mode == BuildMode.GRAVITY_POINT:
		var point_position: Vector2 = _get_cell_center_world(mining_center_cell)
		var valid_color: Color = Color(0.2, 1.0, 0.75, 0.95)
		if gravity_field_system.find_field_at(point_position) == null:
			valid_color = Color(1.0, 0.28, 0.25, 0.9)
		draw_circle(point_position, 7.0, valid_color)


func _draw_drop_tooltip() -> void:
	if not _has_hovered_drop():
		return

	var drop_entry: Dictionary = item_drop_data.get_drop_at_index(hovered_drop_index)
	var amount: int = int(drop_entry.get("amount", 0))
	var tooltip_text: String = "%s x%d" % [
		_get_drop_item_name(drop_entry),
		amount
	]
	var font: Font = ThemeDB.fallback_font
	if font == null:
		return

	var font_size: int = ThemeDB.fallback_font_size
	var text_size: Vector2 = font.get_string_size(tooltip_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	var tooltip_position: Vector2 = get_global_mouse_position() + Vector2(12.0, -18.0)
	var padding: Vector2 = Vector2(6.0, 4.0)
	var tooltip_rect: Rect2 = Rect2(tooltip_position, text_size + padding * 2.0)

	draw_rect(tooltip_rect, GameplayTuningClass.DROPPED_MATERIAL_TOOLTIP_FILL_COLOR, true)
	draw_rect(tooltip_rect, GameplayTuningClass.DROPPED_MATERIAL_TOOLTIP_OUTLINE_COLOR, false, 1.0)
	draw_string(
		font,
		tooltip_rect.position + Vector2(padding.x, padding.y + font_size),
		tooltip_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size,
		Color(1.0, 1.0, 1.0, 1.0)
	)


func _draw_carried_material_pile() -> void:
	var total_count: int = inventory_data.get_total_count()
	if total_count <= 0:
		return

	var count_ratio: float = clampf(float(total_count) / float(maxi(inventory_data.max_capacity, 1)), 0.0, 1.0)
	var weight_ratio: float = 0.0
	if inventory_data.max_weight_capacity > 0.0:
		weight_ratio = clampf(inventory_data.get_total_weight() / inventory_data.max_weight_capacity, 0.0, 1.0)
	var capacity_ratio: float = maxf(count_ratio, weight_ratio)
	var dominant_color: Color = _get_dominant_inventory_color()
	var player_center: Vector2 = _get_player_center_world()
	var pile_center: Vector2 = player_center + Vector2(0.0, GameplayTuningClass.PLAYER_CARRIED_PILE_OFFSET_Y)
	var pile_width: float = lerpf(
		GameplayTuningClass.PLAYER_CARRIED_PILE_MIN_WIDTH,
		GameplayTuningClass.PLAYER_CARRIED_PILE_MAX_WIDTH,
		capacity_ratio
	)
	var pile_height: float = lerpf(
		GameplayTuningClass.PLAYER_CARRIED_PILE_MIN_HEIGHT,
		GameplayTuningClass.PLAYER_CARRIED_PILE_MAX_HEIGHT,
		capacity_ratio
	)

	draw_circle(pile_center + Vector2(-pile_width * 0.18, 0.0), pile_width * 0.32, Color(dominant_color.r * 0.9, dominant_color.g * 0.9, dominant_color.b * 0.9, 0.9))
	draw_circle(pile_center + Vector2(pile_width * 0.2, -pile_height * 0.2), pile_width * 0.28, Color(dominant_color.r, dominant_color.g, dominant_color.b, 0.95))
	draw_circle(pile_center + Vector2(0.0, -pile_height * 0.42), pile_width * 0.22, Color(minf(dominant_color.r * 1.08, 1.0), minf(dominant_color.g * 1.08, 1.0), minf(dominant_color.b * 1.08, 1.0), 0.95))


func _draw_mining_range() -> void:
	var radius_pixels: float = GameplayTuningClass.MINING_RANGE_CELLS * WorldConstantsClass.CELL_SIZE.x
	draw_arc(
		_get_player_center_world(),
		radius_pixels,
		0.0,
		TAU,
		96,
		GameplayTuningClass.MINING_RANGE_COLOR,
		1.5
	)


func _draw_hovered_center() -> void:
	var hovered_rect: Rect2 = Rect2(
		WorldUtilsClass.cell_to_world(hovered_cell),
		Vector2(WorldConstantsClass.CELL_SIZE)
	)
	draw_rect(hovered_rect, GameplayTuningClass.DEBUG_HOVER_CELL_COLOR, false, 1.0)


func _draw_mining_preview() -> void:
	var ordered_cells: Array[Vector2i] = _get_ordered_preview_cells()
	var cell_count: int = maxi(ordered_cells.size() - 1, 1)
	var preview_base: Color = GameplayTuningClass.MINING_PREVIEW_VALID_FILL_COLOR
	var preview_line: Color = GameplayTuningClass.MINING_PREVIEW_VALID_OUTLINE_COLOR

	if not _is_mining_target_in_range():
		preview_base = GameplayTuningClass.MINING_PREVIEW_INVALID_FILL_COLOR
		preview_line = GameplayTuningClass.MINING_PREVIEW_INVALID_OUTLINE_COLOR

	for index in range(ordered_cells.size()):
		var cell_position: Vector2i = ordered_cells[index]
		var traversal_t: float = float(index) / float(cell_count)
		var brightness: float = lerpf(
			GameplayTuningClass.MINING_PREVIEW_NEAR_BRIGHTNESS,
			GameplayTuningClass.MINING_PREVIEW_FAR_BRIGHTNESS,
			traversal_t
		)
		var fill_color: Color = Color(
			preview_base.r * brightness,
			preview_base.g * brightness,
			preview_base.b * brightness,
			preview_base.a
		)
		var line_color: Color = Color(
			preview_line.r * brightness,
			preview_line.g * brightness,
			preview_line.b * brightness,
			preview_line.a
		)
		var cell_rect: Rect2 = Rect2(
			WorldUtilsClass.cell_to_world(cell_position),
			Vector2(WorldConstantsClass.CELL_SIZE)
		)

		draw_rect(cell_rect, fill_color, true)
		draw_rect(cell_rect, line_color, false, 1.0)


func _draw_placement_preview() -> void:
	var ordered_cells: Array[Vector2i] = _get_ordered_preview_cells()
	var material_color: Color = _get_selected_material_color()
	var valid_fill: Color = GameplayTuningClass.PLACEMENT_PREVIEW_VALID_FILL_COLOR
	var valid_outline: Color = GameplayTuningClass.PLACEMENT_PREVIEW_VALID_OUTLINE_COLOR
	var invalid_fill: Color = GameplayTuningClass.PLACEMENT_PREVIEW_INVALID_FILL_COLOR
	var invalid_outline: Color = GameplayTuningClass.PLACEMENT_PREVIEW_INVALID_OUTLINE_COLOR
	var can_place: bool = _can_place_any_preview_cells()

	for cell_position in ordered_cells:
		var cell_rect: Rect2 = Rect2(
			WorldUtilsClass.cell_to_world(cell_position),
			Vector2(WorldConstantsClass.CELL_SIZE)
		)
		var fill_color: Color = valid_fill
		var outline_color: Color = valid_outline

		if not can_place or not _can_place_cell(cell_position):
			fill_color = invalid_fill
			outline_color = invalid_outline
		else:
			fill_color = Color(material_color.r, material_color.g, material_color.b, valid_fill.a)
			outline_color = Color(material_color.r, material_color.g, material_color.b, valid_outline.a)

		draw_rect(cell_rect, fill_color, true)
		draw_rect(cell_rect.grow(-1.0), outline_color, false, 1.0)


func _draw_labels() -> void:
	var font: Font = ThemeDB.fallback_font
	if font == null:
		return

	var font_size: int = ThemeDB.fallback_font_size
	var player_cell: Vector2i = WorldUtilsClass.world_to_cell(player_world_position)
	var player_label_position: Vector2 = player_world_position + Vector2(2, -4)
	var target_label_position: Vector2 = WorldUtilsClass.cell_to_world(mining_center_cell) + Vector2(2, WorldConstantsClass.CELL_SIZE.y + 12)
	var target_cell_type: int = world_data.get_cell(mining_center_cell)
	var target_progress: float = world_data.get_damage_progress(mining_center_cell)
	var target_stage: int = world_data.get_damage_stage(mining_center_cell) * 25
	var target_text: String = "target (%d,%d) %s shape %s radius %d" % [
		mining_center_cell.x,
		mining_center_cell.y,
		_get_cell_type_name(target_cell_type),
		_get_shape_name(debug_settings.mining_shape),
		debug_settings.mining_radius
	]
	var room_text: String = "room %d/%d edge %s" % [
		current_room_index + 1,
		maxi(room_world_data_list.size(), 1),
		_get_room_transition_edge()
	]
	var player_text: String = "player (%d,%d) mining_power %.0f" % [
		player_cell.x,
		player_cell.y,
		debug_settings.mining_power
	]
	var mining_text: String = "progress %d%% stage %d%% order %d" % [
		int(round(target_progress * 100.0)),
		target_stage,
		_get_traversal_index(mining_center_cell)
	]
	var inventory_text: String = "selected %s inv %d/%d weight %.1f/%.1f drops %d dirt %d stone %d" % [
		_get_cell_type_name(selected_material_id),
		inventory_data.get_total_count(),
		inventory_data.max_capacity,
		inventory_data.get_total_weight(),
		inventory_data.max_weight_capacity,
		item_drop_data.get_total_drop_count(),
		inventory_data.get_material_count(WorldConstantsClass.CellType.DIRT),
		inventory_data.get_material_count(WorldConstantsClass.CellType.STONE)
	]

	draw_string(font, player_label_position, room_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(1, 1, 1, 1))
	draw_string(font, player_label_position + Vector2(0, 14), player_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(1, 1, 1, 1))
	draw_string(font, target_label_position, target_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(0.85, 0.95, 1.0, 1.0))
	draw_string(font, target_label_position + Vector2(0, 14), mining_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(0.85, 0.95, 1.0, 1.0))
	draw_string(font, target_label_position + Vector2(0, 28), inventory_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(0.85, 0.95, 1.0, 1.0))
	var profiling_text: String = "chunks vis %d draw %d cells %d dirty %d rebuild %d frame %.2fms" % [
		int(last_render_stats.get("visible_chunk_count", 0)),
		int(last_render_stats.get("rendered_chunk_count", 0)),
		int(last_render_stats.get("visible_cell_count", 0)),
		int(last_render_stats.get("dirty_chunk_count", 0)),
		int(last_render_stats.get("chunk_rebuild_count", 0)),
		float(last_render_stats.get("estimated_frame_time_ms", 0.0))
	]
	draw_string(font, target_label_position + Vector2(0, 42), profiling_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(0.75, 0.9, 0.72, 1.0))

	if has_inspected_cell:
		var inspected_type: int = world_data.get_cell(inspected_cell)
		var inspected_resistance: float = WorldMaterialsClass.get_mining_resistance(inspected_type)
		var inspected_tags: String = ",".join(WorldMaterialsClass.get_material_tags(inspected_type))
		var inspect_text: String = "inspect (%d,%d) %s res %.0f progress %d%% order %d tags %s" % [
			inspected_cell.x,
			inspected_cell.y,
			_get_cell_type_name(inspected_type),
			inspected_resistance,
			int(round(world_data.get_damage_progress(inspected_cell) * 100.0)),
			_get_traversal_index(inspected_cell),
			inspected_tags
		]
		draw_string(font, player_label_position + Vector2(0, -14), inspect_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(1.0, 0.9, 0.65, 1.0))


func _move_player(motion: Vector2) -> void:
	_move_player_axis(Vector2(motion.x, 0.0), true)
	_move_player_axis(Vector2(0.0, motion.y), false)


func _move_player_axis(axis_motion: Vector2, allow_step_assist: bool) -> void:
	if axis_motion == Vector2.ZERO:
		return

	var remaining_distance: float = axis_motion.length()
	var direction: Vector2 = axis_motion.normalized()

	while remaining_distance > 0.0:
		var step_distance: float = minf(remaining_distance, 1.0)
		var step_motion: Vector2 = direction * step_distance
		var next_position: Vector2 = _clamp_player_to_room(player_world_position + step_motion)

		if _player_collides_at(next_position):
			if allow_step_assist and absf(step_motion.x) > 0.0:
				var assisted_position: Vector2 = _get_wall_step_assisted_position(next_position)
				if assisted_position != player_world_position:
					player_world_position = assisted_position
					remaining_distance -= step_distance
					continue
			return

		player_world_position = next_position
		remaining_distance -= step_distance


func _get_wall_step_assisted_position(next_position: Vector2) -> Vector2:
	for step_pixels in range(1, GameplayTuningClass.PLAYER_WALL_STEP_ASSIST_PIXELS + 1):
		var adjusted_position: Vector2 = _clamp_player_to_room(next_position + Vector2(0.0, -float(step_pixels)))
		if not _player_collides_at(adjusted_position):
			return adjusted_position

	return player_world_position


func _player_collides_at(test_position: Vector2) -> bool:
	var player_rect: Rect2 = Rect2(test_position, _get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS))
	return world_data.intersects_solid_rect(player_rect) or _rocks_collide_with_rect(player_rect)


func _is_player_on_floor() -> bool:
	return _player_collides_at(player_world_position + Vector2.DOWN)


func _snap_player_to_ground() -> void:
	var guard_limit: int = 4096
	var guard_steps: int = 0

	while not _is_player_on_floor() and guard_steps < guard_limit:
		player_world_position += Vector2.DOWN
		guard_steps += 1

	guard_steps = 0
	while _player_collides_at(player_world_position) and guard_steps < guard_limit:
		player_world_position += Vector2.UP
		guard_steps += 1


func _generate_rooms() -> void:
	_clear_room_placeable_containers()
	_clear_room_npc_containers()
	room_world_data_list.clear()
	room_drop_data_list.clear()
	room_size_cells_list.clear()
	room_surface_props_list.clear()
	room_protected_cells_list.clear()
	room_gravity_field_system_list.clear()
	inventory_data.clear()
	current_room_index = 0
	has_won = false
	print("Old direct tree placement disabled; using PlaceablePlacementService for surface trees")

	for room_index in range(GameplayTuningClass.ROOM_COUNT):
		var room_size_cells: Vector2i = _generate_room_size_cells()
		var room_world_data = _create_room_world_data(room_size_cells)
		var room_placeable_container: Node2D = _create_room_placeable_container(room_index)
		var room_npc_container: Node2D = _create_room_npc_container(room_index)
		room_size_cells_list.append(room_size_cells)
		room_world_data_list.append(room_world_data)
		room_drop_data_list.append(ItemDropDataClass.new())
		room_gravity_field_system_list.append(GravityFieldSystemClass.new())
		room_placeable_container_list.append(room_placeable_container)
		room_npc_container_list.append(room_npc_container)
		var tree_placement_stats: Dictionary = _create_tree_placement_stats(room_index)
		var room_surface_props: Array = _generate_surface_props_for_room(
			room_size_cells,
			room_world_data,
			room_placeable_container,
			tree_placement_stats
		)
		room_surface_props_list.append(room_surface_props)
		room_protected_cells_list.append(_build_protected_cells_for_props(room_surface_props))
		_create_atlas_worker_spawn_point_for_room(room_index, room_size_cells, room_npc_container)
		_print_tree_placement_stats(tree_placement_stats)


func _create_room_world_data(room_size_cells: Vector2i):
	var room_world_data = WorldDataClass.new()
	var surface_cell_y: int = _get_surface_cell_y_for_room(room_size_cells)
	var dirt_end_y: int = mini(surface_cell_y + GameplayTuningClass.SURFACE_DEPTH, room_size_cells.y)

	for cell_y in range(surface_cell_y, dirt_end_y):
		for cell_x in range(0, room_size_cells.x):
			room_world_data.set_cell(Vector2i(cell_x, cell_y), WorldConstantsClass.CellType.DIRT)

	for cell_y in range(dirt_end_y, room_size_cells.y):
		for cell_x in range(0, room_size_cells.x):
			room_world_data.set_cell(Vector2i(cell_x, cell_y), WorldConstantsClass.CellType.STONE)

	return room_world_data


func _generate_room_size_cells() -> Vector2i:
	var viewport_size: Vector2 = _get_viewport_world_size()
	var min_viewport_width_cells: int = int(ceili(viewport_size.x / float(WorldConstantsClass.CELL_SIZE.x)))
	var min_viewport_height_cells: int = int(ceili(viewport_size.y / float(WorldConstantsClass.CELL_SIZE.y)))
	var min_size: Vector2i = GameplayTuningClass.ROOM_MIN_SIZE_CELLS
	var max_size: Vector2i = GameplayTuningClass.ROOM_MAX_SIZE_CELLS
	var width_min: int = maxi(min_size.x, min_viewport_width_cells)
	var width_max: int = maxi(width_min, max_size.x)
	var fixed_height: int = maxi(min_size.y, min_viewport_height_cells)

	return Vector2i(
		room_rng.randi_range(width_min, width_max),
		fixed_height
	)


func _set_current_room(room_index: int) -> void:
	current_room_index = clampi(room_index, 0, room_world_data_list.size() - 1)
	world_data = room_world_data_list[current_room_index]
	item_drop_data = room_drop_data_list[current_room_index]
	gravity_field_system = room_gravity_field_system_list[current_room_index]
	world_renderer.set_world_data(world_data)
	_clear_build_mode()
	_update_crash_ship_visibility()
	_update_room_placeable_visibility()
	_update_room_npc_visibility()
	_print_world_boundary_debug()
	print("[SunCycle] current player room time state: %s" % planet_sun_cycle.get_room_time_state_name(current_room_index))
	_start_background_fade(planet_sun_cycle.get_room_light_color(current_room_index), "room changed")
	_update_time_hud()
	_refresh_godmode_ui()


func _get_room_spawn_position() -> Vector2:
	if current_room_index == 0 and crash_ship != null and crash_ship.visible:
		return crash_ship.get_spawn_position()

	var player_size: Vector2 = _get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS)
	var room_rect: Rect2 = _get_room_world_rect()
	var spawn_center_x: float = room_rect.position.x + (room_rect.size.x * 0.5)
	var spawn_top_y: float = WorldUtilsClass.cell_to_world(Vector2i(0, _get_current_room_surface_cell_y())).y - player_size.y
	return Vector2(spawn_center_x - (player_size.x * 0.5), spawn_top_y)


func _place_crash_ship_in_starting_room() -> void:
	if crash_ship == null:
		return

	var room_rect: Rect2 = _get_room_world_rect()
	var surface_world_y: float = WorldUtilsClass.cell_to_world(Vector2i(0, _get_current_room_surface_cell_y())).y
	crash_ship.position = Vector2(room_rect.position.x + (room_rect.size.x * 0.5) - 96.0, surface_world_y - 4.0)
	_update_crash_ship_visibility()


func _update_crash_ship_visibility() -> void:
	if crash_ship == null:
		return

	crash_ship.visible = current_room_index == 0


func _try_interact_with_crash_ship() -> bool:
	if current_room_index != 0:
		return false
	if crash_ship == null or not crash_ship.visible:
		return false

	var player_rect: Rect2 = Rect2(player_world_position, _get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS))
	if not crash_ship.overlaps_world_rect(player_rect):
		return false

	crash_ship.interact()
	return true


func _spawn_initial_backpack_world_item() -> void:
	if has_spawned_initial_backpack:
		return

	var spawn_position: Vector2 = _get_player_ground_world() + Vector2(42.0, 0.0)
	_spawn_backpack_world_item(spawn_position, BasicBackpackItemDefinition)
	has_spawned_initial_backpack = true


func _try_interact_with_backpack_world_item() -> bool:
	var player_rect: Rect2 = Rect2(player_world_position, _get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS))
	for backpack_item in world_backpack_items:
		if not is_instance_valid(backpack_item):
			continue
		if not backpack_item.overlaps_world_rect(player_rect):
			continue

		if player_equipment.get_equipped_backpack() != null:
			print("[Backpack] Cannot equip backpack: backpack slot already occupied")
			return true

		var item_definition: ItemDefinition = backpack_item.item_definition
		if _equip_backpack_item(item_definition, "[Backpack]"):
			world_backpack_items.erase(backpack_item)
			backpack_item.queue_free()
		return true

	return false


func _equip_backpack_item(item_definition: ItemDefinition, log_prefix: String) -> bool:
	if item_definition == null:
		return false
	if not item_definition.is_backpack or not item_definition.can_be_equipped:
		return false
	if player_equipment.get_equipped_backpack() != null:
		print("%s Cannot equip backpack: backpack slot already occupied" % [log_prefix])
		return false
	if not player_equipment.equip_item(item_definition):
		return false

	if item_definition.backpack_definition is BackpackDefinition:
		backpack_container.equip_backpack(item_definition.backpack_definition)
	print("%s Backpack equipped: %s" % [log_prefix, item_definition.id])
	_refresh_godmode_ui()
	return true


func _drop_equipped_backpack() -> void:
	var equipped_backpack: ItemDefinition = player_equipment.get_equipped_backpack()
	if equipped_backpack == null:
		print("[Backpack] No backpack equipped")
		return

	player_equipment.unequip_item(EquipmentSlotClass.SlotType.BACKPACK)
	# TODO: Transfer BackpackContainer contents into dropped world item data once item containers persist.
	backpack_container.unequip_backpack()
	_spawn_backpack_world_item(_get_backpack_drop_position(), equipped_backpack)
	print("[Backpack] Backpack dropped")
	_refresh_godmode_ui()


func _spawn_backpack_world_item(world_position: Vector2, item_definition: ItemDefinition) -> BackpackWorldItem:
	var scene: PackedScene = BackpackWorldItemScene
	if item_definition != null and item_definition.world_scene != null:
		scene = item_definition.world_scene

	var backpack_item: BackpackWorldItem = scene.instantiate() as BackpackWorldItem
	if backpack_item == null:
		return null
	backpack_item.setup(item_definition)
	backpack_item.global_position = world_position
	world_items.add_child(backpack_item)
	world_backpack_items.append(backpack_item)
	return backpack_item


func _get_backpack_drop_position() -> Vector2:
	var drop_offset_x: float = 28.0
	if Input.is_action_pressed("move_left"):
		drop_offset_x = -28.0
	return _get_player_ground_world() + Vector2(drop_offset_x, 0.0)


func _try_transition_room() -> bool:
	if room_transition_lock_time > 0.0:
		return false

	var room_edge: String = _get_room_transition_edge()
	if room_edge == ROOM_EDGE_NONE:
		return false

	var should_transition: bool = false
	match room_edge:
		ROOM_EDGE_LEFT:
			should_transition = Input.is_action_pressed("move_left")
		ROOM_EDGE_RIGHT:
			should_transition = Input.is_action_pressed("move_right")
		ROOM_EDGE_TOP:
			should_transition = Input.is_action_pressed("move_up")
		ROOM_EDGE_BOTTOM:
			should_transition = Input.is_action_pressed("move_down")

	if not should_transition:
		return false

	if room_edge == ROOM_EDGE_TOP or room_edge == ROOM_EDGE_BOTTOM:
		has_won = true
		player_velocity = Vector2.ZERO
		queue_redraw()
		return true

	var next_room_index: int = _get_adjacent_room_index(room_edge)
	if next_room_index == current_room_index:
		return false

	print("room transition started from room %d to room %d via %s" % [current_room_index, next_room_index, room_edge])
	room_transition_lock_time = 0.12
	print("player input locked; player movement disabled")
	_set_current_room(next_room_index)
	_place_player_at_room_entry(room_edge)
	_reposition_active_atlas_workers_after_transition(room_edge)
	hovered_drop_index = -1
	has_inspected_cell = false
	_update_hover_state()
	print("transition completed in room %d at %s" % [current_room_index, player_world_position])
	queue_redraw()
	return true


func _place_player_at_room_entry(exit_edge: String) -> void:
	var room_rect: Rect2 = _get_room_world_rect()
	var player_size: Vector2 = _get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS)
	var entry_inset_pixels: float = GameplayTuningClass.ROOM_ENTRY_INSET_CELLS * WorldConstantsClass.CELL_SIZE.x
	var next_position: Vector2 = player_world_position

	match exit_edge:
		ROOM_EDGE_LEFT:
			next_position.x = room_rect.end.x - player_size.x - entry_inset_pixels
		ROOM_EDGE_RIGHT:
			next_position.x = room_rect.position.x + entry_inset_pixels
		ROOM_EDGE_TOP:
			next_position.y = room_rect.end.y - player_size.y - entry_inset_pixels
		ROOM_EDGE_BOTTOM:
			next_position.y = room_rect.position.y + entry_inset_pixels

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
	var fell_left: bool = _is_outer_left_edge() and player_rect.end.x < room_rect.position.x - void_margin
	var fell_right: bool = _is_outer_right_edge() and player_rect.position.x > room_rect.end.x + void_margin
	var fell_below: bool = player_rect.position.y > room_rect.end.y + void_depth

	if not fell_left and not fell_right and not fell_below:
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

	if player_rect.position.x <= room_rect.position.x + margin_pixels and _has_adjacent_room(ROOM_EDGE_LEFT):
		return ROOM_EDGE_LEFT
	if player_rect.end.x >= room_rect.end.x - margin_pixels and _has_adjacent_room(ROOM_EDGE_RIGHT):
		return ROOM_EDGE_RIGHT
	if player_rect.position.y <= room_rect.position.y + margin_pixels:
		return ROOM_EDGE_TOP
	if player_rect.end.y >= room_rect.end.y - margin_pixels:
		return ROOM_EDGE_BOTTOM

	return ROOM_EDGE_NONE


func _get_room_world_rect() -> Rect2:
	return Rect2(Vector2.ZERO, _get_world_size_from_cells(_get_current_room_size_cells()))


func _get_void_fall_rect() -> Rect2:
	var room_rect: Rect2 = _get_room_world_rect()
	var void_margin: float = GameplayTuningClass.VOID_FALL_MARGIN_CELLS * WorldConstantsClass.CELL_SIZE.x
	var void_depth: float = GameplayTuningClass.VOID_FALL_DEPTH_CELLS * WorldConstantsClass.CELL_SIZE.y
	return Rect2(
		Vector2(room_rect.position.x - void_margin, room_rect.position.y),
		Vector2(room_rect.size.x + (void_margin * 2.0), room_rect.size.y + void_depth)
	)


func _is_outer_left_edge() -> bool:
	return not _has_adjacent_room(ROOM_EDGE_LEFT)


func _is_outer_right_edge() -> bool:
	return not _has_adjacent_room(ROOM_EDGE_RIGHT)


func _print_world_boundary_debug() -> void:
	var room_rect: Rect2 = _get_room_world_rect()
	var void_rect: Rect2 = _get_void_fall_rect()
	print(
		"World horizontal bounds room %d: left %.1f right %.1f; outer left %s outer right %s; void trigger left %.1f right %.1f below %.1f" % [
			current_room_index,
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
	var min_x: float = -INF
	var max_x: float = INF
	var max_y: float = room_rect.end.y - player_size.y
	if not _is_outer_left_edge():
		min_x = room_rect.position.x
	if not _is_outer_right_edge():
		max_x = room_rect.end.x - player_size.x
	if _is_position_beyond_outer_horizontal_edge(next_position):
		max_y = INF

	return Vector2(
		clampf(next_position.x, min_x, max_x),
		clampf(next_position.y, room_rect.position.y, max_y)
	)


func _is_position_beyond_outer_horizontal_edge(position: Vector2) -> bool:
	var room_rect: Rect2 = _get_room_world_rect()
	var player_size: Vector2 = _get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS)
	if _is_outer_left_edge() and position.x + player_size.x < room_rect.position.x:
		return true
	if _is_outer_right_edge() and position.x > room_rect.end.x:
		return true

	return false


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


func _clear_room_placeable_containers() -> void:
	room_placeable_container_list.clear()
	if placeable_objects == null:
		return

	for child in placeable_objects.get_children():
		child.queue_free()


func _create_room_placeable_container(room_index: int) -> Node2D:
	var room_placeable_container: Node2D = Node2D.new()
	room_placeable_container.name = "room_%d_placeables" % room_index
	room_placeable_container.visible = room_index == current_room_index
	placeable_objects.add_child(room_placeable_container)
	return room_placeable_container


func _update_room_placeable_visibility() -> void:
	for room_index in range(room_placeable_container_list.size()):
		var room_placeable_container: Node2D = room_placeable_container_list[room_index]
		if room_placeable_container != null:
			room_placeable_container.visible = room_index == current_room_index


func _clear_room_npc_containers() -> void:
	room_npc_container_list.clear()
	if npc_objects == null:
		return

	for child in npc_objects.get_children():
		if child == persistent_followers:
			continue
		child.queue_free()


func _create_room_npc_container(room_index: int) -> Node2D:
	var room_npc_container: Node2D = Node2D.new()
	room_npc_container.name = "room_%d_npcs" % room_index
	room_npc_container.visible = room_index == current_room_index
	room_npc_container.process_mode = Node.PROCESS_MODE_INHERIT if room_index == current_room_index else Node.PROCESS_MODE_DISABLED
	npc_objects.add_child(room_npc_container)
	return room_npc_container


func _update_room_npc_visibility() -> void:
	for room_index in range(room_npc_container_list.size()):
		var room_npc_container: Node2D = room_npc_container_list[room_index]
		if room_npc_container != null:
			var is_active_room: bool = room_index == current_room_index
			room_npc_container.visible = is_active_room
			room_npc_container.process_mode = Node.PROCESS_MODE_INHERIT if is_active_room else Node.PROCESS_MODE_DISABLED


func _create_atlas_worker_spawn_point_for_room(room_index: int, room_size_cells: Vector2i, room_npc_container: Node2D) -> void:
	if AtlasWorkerSpawnPointScene == null:
		return
	if room_npc_container == null:
		return

	var spawn_point = AtlasWorkerSpawnPointScene.instantiate()
	if not spawn_point is AtlasWorkerSpawnPoint:
		return

	var atlas_spawn_point: AtlasWorkerSpawnPoint = spawn_point
	var surface_cell_y: int = _get_surface_cell_y_for_room(room_size_cells)
	var spawn_cell: Vector2i = Vector2i(
		clampi(room_size_cells.x / 2 + (room_index * 9) - 9, GameplayTuningClass.SURFACE_PROP_EDGE_MARGIN_CELLS, room_size_cells.x - GameplayTuningClass.SURFACE_PROP_EDGE_MARGIN_CELLS),
		surface_cell_y - 6
	)
	atlas_spawn_point.global_position = WorldUtilsClass.cell_to_world(spawn_cell)
	atlas_spawn_point.set_player_target(player_follow_target)
	atlas_spawn_point.group_activated.connect(_on_atlas_worker_group_activated)
	room_npc_container.add_child(atlas_spawn_point)
	print("room %d received AtlasWorker spawn point at %s" % [room_index, atlas_spawn_point.global_position])


func _on_atlas_worker_group_activated(_spawn_point, workers: Array) -> void:
	var added_count: int = 0
	var overflow_count: int = 0

	for worker in workers:
		if worker == null or not worker is AtlasWorker:
			continue
		var atlas_worker: AtlasWorker = worker

		if active_atlas_workers.size() >= MAX_ATLAS_WORKER_FOLLOWERS:
			atlas_worker.deactivate_group()
			overflow_count += 1
			continue

		atlas_worker.reparent(persistent_followers, true)
		active_atlas_workers.append(atlas_worker)
		added_count += 1

	if added_count > 0:
		_assign_active_atlas_worker_follow_chain()

	print(
		"AtlasWorker followers updated: added %d, total %d/%d, non-followers left in place %d" % [
			added_count,
			active_atlas_workers.size(),
			MAX_ATLAS_WORKER_FOLLOWERS,
			overflow_count,
		]
	)


func _assign_active_atlas_worker_follow_chain() -> void:
	for index in range(active_atlas_workers.size()):
		var atlas_worker: AtlasWorker = active_atlas_workers[index]
		if atlas_worker == null:
			continue
		if index == 0:
			atlas_worker.follow_target = player_follow_target
		else:
			atlas_worker.follow_target = active_atlas_workers[index - 1]
		atlas_worker.activation_target = player_follow_target
		atlas_worker.activate_group()

	print("persistent AtlasWorker follow chain assigned")


func _reposition_active_atlas_workers_after_transition(exit_edge: String) -> void:
	if active_atlas_workers.is_empty():
		return

	var direction_sign: float = 1.0
	if exit_edge == ROOM_EDGE_RIGHT:
		direction_sign = -1.0

	var player_ground_position: Vector2 = _get_player_ground_world()
	for index in range(active_atlas_workers.size()):
		var atlas_worker: AtlasWorker = active_atlas_workers[index]
		if atlas_worker == null:
			continue
		atlas_worker.global_position = player_ground_position + Vector2(direction_sign * float(26 + (index * 18)), 0.0)
		atlas_worker.velocity = Vector2.ZERO

	_assign_active_atlas_worker_follow_chain()
	print("AtlasWorkers repositioned after room transition")


func _update_active_atlas_worker_grounding() -> void:
	for atlas_worker in active_atlas_workers:
		if atlas_worker == null:
			continue
		if atlas_worker.global_position.y > _get_player_ground_world().y + WorldConstantsClass.CELL_SIZE.y:
			atlas_worker.global_position.y = _get_player_ground_world().y


func _create_tree_placement_stats(room_index: int) -> Dictionary:
	return {
		"room_index": room_index,
		"valid_surface_positions": 0,
		"placed_count": 0,
		"failure_count": 0,
	}


func _try_place_surface_tree(placement_service, surface_cell: Vector2i, tree_placement_stats: Dictionary) -> void:
	var placement_tile: Vector2i = Vector2i(
		surface_cell.x,
		surface_cell.y - PrototypeTreeDefinition.footprint_tiles.y
	)

	if placement_service.can_place(PrototypeTreeDefinition, placement_tile, PrototypeTreeDefinition.placement_mode):
		tree_placement_stats["valid_surface_positions"] = int(tree_placement_stats.get("valid_surface_positions", 0)) + 1
	else:
		tree_placement_stats["failure_count"] = int(tree_placement_stats.get("failure_count", 0)) + 1
		print("Tree placement failed at surface cell %s: invalid FLOOR position" % [surface_cell])
		return

	var placed_tree: Node = placement_service.place_object(PrototypeTreeDefinition, placement_tile, PrototypeTreeDefinition.placement_mode)
	if placed_tree == null:
		tree_placement_stats["failure_count"] = int(tree_placement_stats.get("failure_count", 0)) + 1
		print("Tree placement failed at surface cell %s: PlaceablePlacementService returned null" % [surface_cell])
		return

	tree_placement_stats["placed_count"] = int(tree_placement_stats.get("placed_count", 0)) + 1


func _print_tree_placement_stats(tree_placement_stats: Dictionary) -> void:
	print(
		"Room %d tree placeables: valid surface positions %d, placed %d, failures %d" % [
			int(tree_placement_stats.get("room_index", 0)),
			int(tree_placement_stats.get("valid_surface_positions", 0)),
			int(tree_placement_stats.get("placed_count", 0)),
			int(tree_placement_stats.get("failure_count", 0)),
		]
	)


func _apply_view_resolution() -> void:
	var root_window: Window = get_tree().root
	root_window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root_window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root_window.content_scale_size = _get_target_internal_resolution()


func _get_current_room_size_cells() -> Vector2i:
	if current_room_index >= 0 and current_room_index < room_size_cells_list.size():
		return room_size_cells_list[current_room_index]

	return GameplayTuningClass.ROOM_MIN_SIZE_CELLS


func _get_current_room_surface_props() -> Array:
	if current_room_index >= 0 and current_room_index < room_surface_props_list.size():
		return room_surface_props_list[current_room_index]

	return []


func _get_current_room_protected_cells() -> Dictionary:
	if current_room_index >= 0 and current_room_index < room_protected_cells_list.size():
		return room_protected_cells_list[current_room_index]

	return {}


func _get_surface_cell_y_for_room(room_size_cells: Vector2i) -> int:
	return maxi(int(floor(float(room_size_cells.y) * 0.5)), 0)


func _get_current_room_surface_cell_y() -> int:
	return _get_surface_cell_y_for_room(_get_current_room_size_cells())


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
	var player_rect: Rect2 = Rect2(
		entry_position + Vector2(-side_padding, -top_padding),
		player_size + Vector2(side_padding * 2.0, top_padding)
	)
	var player_center: Vector2 = player_rect.get_center()
	var distance_left: float = absf(player_center.x - room_rect.position.x)
	var distance_right: float = absf(room_rect.end.x - player_center.x)
	var distance_top: float = absf(player_center.y - room_rect.position.y)
	var distance_bottom: float = absf(room_rect.end.y - player_center.y)
	var minimum_distance: float = minf(minf(distance_left, distance_right), minf(distance_top, distance_bottom))
	var clear_rect: Rect2 = player_rect

	if is_equal_approx(distance_left, minimum_distance):
		clear_rect = clear_rect.merge(Rect2(
			Vector2(room_rect.position.x, player_rect.position.y),
			Vector2(player_rect.end.x - room_rect.position.x, player_rect.size.y)
		))

	if is_equal_approx(distance_right, minimum_distance):
		clear_rect = clear_rect.merge(Rect2(
			Vector2(player_rect.position.x, player_rect.position.y),
			Vector2(room_rect.end.x - player_rect.position.x, player_rect.size.y)
		))

	if is_equal_approx(distance_top, minimum_distance):
		clear_rect = clear_rect.merge(Rect2(
			Vector2(player_rect.position.x, room_rect.position.y),
			Vector2(player_rect.size.x, player_rect.end.y - room_rect.position.y)
		))

	if is_equal_approx(distance_bottom, minimum_distance):
		clear_rect = clear_rect.merge(Rect2(
			Vector2(player_rect.position.x, player_rect.position.y),
			Vector2(player_rect.size.x, room_rect.end.y - player_rect.position.y)
		))

	var start_cell: Vector2i = WorldUtilsClass.world_to_cell(clear_rect.position)
	var end_cell: Vector2i = WorldUtilsClass.world_to_cell(clear_rect.end - Vector2.ONE)

	for cell_y in range(start_cell.y, end_cell.y + 1):
		for cell_x in range(start_cell.x, end_cell.x + 1):
			var cell_position: Vector2i = Vector2i(cell_x, cell_y)
			if _is_cell_inside_room(cell_position):
				world_data.remove_cell(cell_position)
				world_data.remove_damage_progress(cell_position)


func _generate_surface_props_for_room(room_size_cells: Vector2i, room_world_data, room_placeable_container: Node2D, tree_placement_stats: Dictionary) -> Array:
	var props: Array = []
	var tree_placement_service = PlaceablePlacementServiceClass.new(room_world_data, room_placeable_container)
	var surface_cell_y: int = _get_surface_cell_y_for_room(room_size_cells)
	var cell_x: int = GameplayTuningClass.SURFACE_PROP_EDGE_MARGIN_CELLS
	var max_cell_x: int = room_size_cells.x - GameplayTuningClass.SURFACE_PROP_EDGE_MARGIN_CELLS

	while cell_x < max_cell_x:
		if room_rng.randf() > GameplayTuningClass.SURFACE_PROP_DENSITY:
			cell_x += 1
			continue

		var prop_roll: float = room_rng.randf()
		var prop_entry: Dictionary = {}
		if prop_roll < 0.58:
			var tree_footprint_width: int = PrototypeTreeDefinition.footprint_tiles.x
			if cell_x + tree_footprint_width >= max_cell_x:
				break

			_try_place_surface_tree(
				tree_placement_service,
				Vector2i(cell_x, surface_cell_y),
				tree_placement_stats
			)
			cell_x += tree_footprint_width + GameplayTuningClass.SURFACE_PROP_SPACING_MIN_CELLS + room_rng.randi_range(0, 2)
			continue
		elif prop_roll < 0.82:
			prop_entry = {
				"type": SURFACE_PROP_BUSH,
				"base_cell": Vector2i(cell_x, surface_cell_y),
				"footprint_width_cells": room_rng.randi_range(2, 4),
				"width_cells": room_rng.randi_range(2, 4),
				"height_cells": room_rng.randi_range(1, 2),
			}
		else:
			prop_entry = {
				"type": SURFACE_PROP_ROCK,
				"base_cell": Vector2i(cell_x, surface_cell_y),
				"footprint_width_cells": room_rng.randi_range(2, 4),
				"width_cells": room_rng.randi_range(2, 4),
				"height_cells": room_rng.randi_range(1, 2),
			}

		var footprint_width: int = int(prop_entry.get("footprint_width_cells", 1))
		if cell_x + footprint_width >= max_cell_x:
			break

		props.append(prop_entry)
		cell_x += footprint_width + GameplayTuningClass.SURFACE_PROP_SPACING_MIN_CELLS + room_rng.randi_range(0, 2)

	return props


func _build_protected_cells_for_props(surface_props: Array) -> Dictionary:
	var protected_cells: Dictionary = {}

	for prop_entry in surface_props:
		var base_cell: Vector2i = Vector2i(prop_entry.get("base_cell", Vector2i.ZERO))
		var footprint_width_cells: int = int(prop_entry.get("footprint_width_cells", 1))
		for offset_x in range(footprint_width_cells):
			for depth in range(GameplayTuningClass.SURFACE_PROP_PROTECTED_DEPTH_CELLS):
				protected_cells[Vector2i(base_cell.x + offset_x, base_cell.y + depth)] = true

	return protected_cells


func _has_adjacent_room(room_edge: String) -> bool:
	return _get_adjacent_room_index(room_edge) != current_room_index


func _get_adjacent_room_index(room_edge: String) -> int:
	match room_edge:
		ROOM_EDGE_LEFT:
			return maxi(current_room_index - 1, 0)
		ROOM_EDGE_RIGHT:
			return mini(current_room_index + 1, maxi(room_world_data_list.size() - 1, 0))
		_:
			return current_room_index


func _get_target_world_position() -> Vector2:
	var player_center: Vector2 = _get_player_center_world()
	var max_range_pixels: float = GameplayTuningClass.MINING_RANGE_CELLS * WorldConstantsClass.CELL_SIZE.x
	var pointer_offset: Vector2 = get_global_mouse_position() - player_center
	var clamped_offset: Vector2 = pointer_offset.limit_length(max_range_pixels)
	return player_center + clamped_offset


func _get_preview_cells() -> Array[Vector2i]:
	return WorldShapesClass.get_cells_in_shape(
		debug_settings.mining_shape,
		mining_center_cell,
		debug_settings.mining_radius
	)


func _get_ordered_preview_cells() -> Array[Vector2i]:
	var preview_cells: Array[Vector2i] = _get_preview_cells()
	var ordered_cells: Array[Vector2i] = []

	for preview_cell in preview_cells:
		var inserted: bool = false

		for index in range(ordered_cells.size()):
			if _is_cell_before_in_traversal(preview_cell, ordered_cells[index]):
				ordered_cells.insert(index, preview_cell)
				inserted = true
				break

		if not inserted:
			ordered_cells.append(preview_cell)

	return ordered_cells


func _is_cell_before_in_traversal(cell_a: Vector2i, cell_b: Vector2i) -> bool:
	var score_a: Vector3 = _get_traversal_score(cell_a)
	var score_b: Vector3 = _get_traversal_score(cell_b)

	if score_a.x != score_b.x:
		return score_a.x < score_b.x

	if score_a.y != score_b.y:
		return score_a.y < score_b.y

	if score_a.z != score_b.z:
		return score_a.z < score_b.z

	if cell_a.x != cell_b.x:
		return cell_a.x < cell_b.x

	return cell_a.y < cell_b.y


func _get_traversal_score(cell_position: Vector2i) -> Vector3:
	var player_center: Vector2 = _get_player_center_world()
	var target_center: Vector2 = _get_cell_center_world(mining_center_cell)
	var direction: Vector2 = (target_center - player_center).normalized()

	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT

	var perpendicular: Vector2 = Vector2(-direction.y, direction.x)
	var cell_vector: Vector2 = _get_cell_center_world(cell_position) - player_center
	var forward_distance: float = cell_vector.dot(direction)
	var lateral_distance: float = absf(cell_vector.dot(perpendicular))
	var total_distance: float = cell_vector.length()
	return Vector3(forward_distance, lateral_distance, total_distance)


func _get_traversal_index(cell_position: Vector2i) -> int:
	var ordered_cells: Array[Vector2i] = _get_ordered_preview_cells()

	for index in range(ordered_cells.size()):
		if ordered_cells[index] == cell_position:
			return index

	return -1


func _is_mining_target_in_range() -> bool:
	var player_center_world: Vector2 = _get_player_center_world()
	var target_center_world: Vector2 = _get_cell_center_world(mining_center_cell)
	return player_center_world.distance_to(target_center_world) <= GameplayTuningClass.MINING_RANGE_CELLS * WorldConstantsClass.CELL_SIZE.x


func _should_show_mining_cone_cursor() -> bool:
	if _is_gravity_build_mode_active():
		return false
	return player_cursor_controller.get_current_cursor_behavior() == CursorBehaviorDefinitionClass.CursorBehavior.MINE_CONE


func _should_show_place_cursor() -> bool:
	if _is_gravity_build_mode_active():
		return false
	return player_cursor_controller.get_current_cursor_behavior() == CursorBehaviorDefinitionClass.CursorBehavior.PLACE


func _is_gravity_build_mode_active() -> bool:
	return current_build_mode == BuildMode.GRAVITY_FIELD or current_build_mode == BuildMode.GRAVITY_POINT


func _is_player_inside_gravity_field() -> bool:
	return gravity_field_system.find_active_field_intersecting(_get_player_world_rect()) != null


func _get_gravity_acceleration_at_player() -> Vector2:
	return gravity_field_system.get_gravity_acceleration(
		_get_player_center_world(),
		GameplayTuningClass.PLAYER_GRAVITY
	)


func _set_build_mode(next_build_mode: int) -> void:
	current_build_mode = next_build_mode
	block_mining_until_left_released = true
	print("[GodModeGravity] build mode: %s" % _get_build_mode_name())
	_update_time_hud()
	_refresh_godmode_ui()
	queue_redraw()


func _clear_build_mode() -> void:
	if current_build_mode == BuildMode.NONE:
		return
	current_build_mode = BuildMode.NONE
	block_mining_until_left_released = true
	_update_time_hud()
	_refresh_godmode_ui()


func _handle_gravity_build_click() -> void:
	if current_build_mode == BuildMode.GRAVITY_FIELD:
		var field_bounds: Rect2 = _get_gravity_field_preview_rect()
		gravity_field_system.create_field(field_bounds, 0.0)
		print("[GodModeGravity] gravity field placed: %s" % field_bounds)
		_clear_build_mode()
		_refresh_godmode_ui()
		return

	if current_build_mode == BuildMode.GRAVITY_POINT:
		var point_position: Vector2 = _get_cell_center_world(mining_center_cell)
		var field: GravityFieldData = gravity_field_system.set_gravity_point(point_position, _get_gravity_strength_for_level(1))
		if field != null:
			pending_gravity_strength_field = field
			print("[GodModeGravity] gravity point set: %s" % point_position)
			_clear_build_mode()
			godmode_panel.show_gravity_strength_popup()
		else:
			print("[GodModeGravity] Cannot place gravity point outside a gravity field")
		_refresh_godmode_ui()


func _get_gravity_field_preview_rect() -> Rect2:
	var preview_cells: Array[Vector2i] = _get_ordered_preview_cells()
	if preview_cells.is_empty():
		var cell_size: Vector2 = Vector2(WorldConstantsClass.CELL_SIZE)
		return Rect2(WorldUtilsClass.cell_to_world(mining_center_cell), cell_size)

	var min_cell: Vector2i = preview_cells[0]
	var max_cell: Vector2i = preview_cells[0]
	for cell_position in preview_cells:
		min_cell.x = mini(min_cell.x, cell_position.x)
		min_cell.y = mini(min_cell.y, cell_position.y)
		max_cell.x = maxi(max_cell.x, cell_position.x)
		max_cell.y = maxi(max_cell.y, cell_position.y)

	var top_left: Vector2 = WorldUtilsClass.cell_to_world(min_cell)
	var bottom_right: Vector2 = WorldUtilsClass.cell_to_world(max_cell + Vector2i.ONE)
	return Rect2(top_left, bottom_right - top_left)


func _get_build_mode_name() -> String:
	match current_build_mode:
		BuildMode.GRAVITY_FIELD:
			return "GRAVITY_FIELD"
		BuildMode.GRAVITY_POINT:
			return "GRAVITY_POINT"
		_:
			return "NONE"


func _get_gravity_strength_for_level(level_index: int) -> float:
	return float(GRAVITY_FIELD_STRENGTH_MILESTONES[clampi(level_index, 0, GRAVITY_FIELD_STRENGTH_MILESTONES.size() - 1)])


func _can_mine_with_equipped_tool() -> bool:
	if not _should_show_mining_cone_cursor():
		return false

	var equipped_tool: ItemDefinition = player_equipment.get_equipped_tool()
	if equipped_tool == null:
		return false
	if equipped_tool.item_category != ItemTypesClass.ItemCategory.EQUIPMENT:
		return false
	if not equipped_tool.is_tool:
		return false
	if equipped_tool.cursor_behavior == null:
		return false

	return equipped_tool.cursor_behavior.behavior == CursorBehaviorDefinitionClass.CursorBehavior.MINE_CONE


func _get_player_center_world() -> Vector2:
	return player_world_position + (_get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS) * 0.5)


func _get_player_world_rect() -> Rect2:
	return Rect2(player_world_position, _get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS))


func _get_player_ground_world() -> Vector2:
	var player_size: Vector2 = _get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS)
	return player_world_position + Vector2(player_size.x * 0.5, player_size.y)


func _update_player_follow_target() -> void:
	if player_follow_target == null:
		return

	player_follow_target.global_position = _get_player_ground_world()


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
	if shape_type == WorldConstantsClass.ToolShape.CIRCLE:
		return "circle"

	return "square"


func _try_place_preview_cells() -> bool:
	if not _is_mining_target_in_range():
		return false

	if not inventory_data.has_material(selected_material_id):
		return false

	var placed_any: bool = false

	for cell_position in _get_ordered_preview_cells():
		if not inventory_data.has_material(selected_material_id):
			break

		if not _can_place_cell(cell_position):
			continue

		if inventory_data.remove_material(selected_material_id, 1) <= 0:
			break

		world_data.set_cell(cell_position, selected_material_id)
		world_data.remove_damage_progress(cell_position)
		placed_any = true

	if placed_any:
		_refresh_godmode_ui()

	return placed_any


func _can_place_any_preview_cells() -> bool:
	if not _is_mining_target_in_range():
		return false

	if not inventory_data.has_material(selected_material_id):
		return false

	for cell_position in _get_ordered_preview_cells():
		if _can_place_cell(cell_position):
			return true

	return false


func _can_place_cell(cell_position: Vector2i) -> bool:
	if not _is_cell_inside_room(cell_position):
		return false

	if world_data.has_cell(cell_position):
		return false

	return not _player_contains_cell(cell_position)


func _try_pick_up_hovered_drops() -> bool:
	if not _has_hovered_drop():
		return false

	var drop_entry: Dictionary = item_drop_data.get_drop_at_index(hovered_drop_index)
	var item_kind: String = String(drop_entry.get("item_kind", ""))
	var item_id: int = int(drop_entry.get("item_id", WorldConstantsClass.CellType.AIR))
	var amount: int = int(drop_entry.get("amount", 0))
	var accepted_amount: int = 0
	if item_kind == "material":
		accepted_amount = inventory_data.add_material(item_id, amount)
	var picked_any: bool = false

	if accepted_amount > 0:
		item_drop_data.remove_amount_at_index(hovered_drop_index, accepted_amount)
		hovered_drop_index = item_drop_data.find_nearest_drop_index(
			get_global_mouse_position(),
			GameplayTuningClass.DROPPED_ITEM_HOVER_RADIUS_PIXELS
		)
		picked_any = true

	if picked_any:
		_refresh_godmode_ui()

	return picked_any


func _has_hovered_drop() -> bool:
	return hovered_drop_index >= 0


func _player_contains_cell(cell_position: Vector2i) -> bool:
	var player_rect: Rect2 = Rect2(player_world_position, _get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS))
	var cell_rect: Rect2 = Rect2(WorldUtilsClass.cell_to_world(cell_position), Vector2(WorldConstantsClass.CELL_SIZE))
	return player_rect.intersects(cell_rect)


func _cycle_selected_material(direction: int) -> void:
	var material_ids: Array[int] = WorldMaterialsClass.get_placeable_material_ids()
	if material_ids.is_empty():
		return

	var current_index: int = material_ids.find(selected_material_id)
	if current_index == -1:
		selected_material_id = material_ids[0]
		_refresh_godmode_ui()
		return

	var next_index: int = posmod(current_index + direction, material_ids.size())
	selected_material_id = material_ids[next_index]
	_refresh_godmode_ui()


func _get_selected_material_color() -> Color:
	return WorldMaterialsClass.get_debug_color(selected_material_id)


func _get_drop_item_name(drop_entry: Dictionary) -> String:
	var item_kind: String = String(drop_entry.get("item_kind", ""))
	var item_id: int = int(drop_entry.get("item_id", WorldConstantsClass.CellType.AIR))
	if item_kind == "material":
		return _get_cell_type_name(item_id)

	return "ITEM"


func _get_drop_item_color(drop_entry: Dictionary) -> Color:
	var item_kind: String = String(drop_entry.get("item_kind", ""))
	var item_id: int = int(drop_entry.get("item_id", WorldConstantsClass.CellType.AIR))
	if item_kind == "material":
		return WorldMaterialsClass.get_debug_color(item_id)

	return Color(1.0, 1.0, 1.0, 1.0)


func _get_dominant_inventory_color() -> Color:
	var material_ids: Array[int] = inventory_data.get_material_ids()
	if material_ids.is_empty():
		return GameplayTuningClass.DIRT_DEBUG_COLOR

	var dominant_material_id: int = selected_material_id
	var dominant_count: int = -1
	var blended_color: Color = Color(0.0, 0.0, 0.0, 0.0)
	var total_count: int = 0

	for material_id in material_ids:
		var material_count: int = inventory_data.get_material_count(material_id)
		total_count += material_count
		if material_count > dominant_count:
			dominant_count = material_count
			dominant_material_id = material_id

	if total_count <= 0:
		return WorldMaterialsClass.get_debug_color(dominant_material_id)

	for material_id in material_ids:
		var material_count: int = inventory_data.get_material_count(material_id)
		var weight: float = float(material_count) / float(total_count)
		var material_color: Color = WorldMaterialsClass.get_debug_color(material_id)
		blended_color.r += material_color.r * weight
		blended_color.g += material_color.g * weight
		blended_color.b += material_color.b * weight
		blended_color.a = 1.0

	return blended_color


func _set_inventory_capacity(capacity: int) -> void:
	inventory_data.set_capacity(clampi(capacity, GameplayTuningClass.INVENTORY_CAPACITY_MIN, GameplayTuningClass.INVENTORY_CAPACITY_MAX))
	_refresh_godmode_ui()
	queue_redraw()


func _set_inventory_weight_capacity(weight_capacity: float) -> void:
	inventory_data.set_weight_capacity(clampf(weight_capacity, GameplayTuningClass.INVENTORY_WEIGHT_CAPACITY_MIN, GameplayTuningClass.INVENTORY_WEIGHT_CAPACITY_MAX))
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
	print(
		"[SunCycle] sun room changed: %d visual position %s player room %d" % [
			new_room_index,
			_get_sun_visual_world_position() if _is_sun_visual_in_current_room() else "offscreen",
			current_room_index,
		]
	)


func _on_room_time_state_changed(room_index: int, old_state: int, new_state: int) -> void:
	print(
		"[SunCycle] room %d time state changed: %s -> %s" % [
			room_index,
			planet_sun_cycle.get_time_state_name(old_state),
			planet_sun_cycle.get_time_state_name(new_state),
		]
	)
	if room_index == current_room_index:
		print("[SunCycle] player room time state: %s" % planet_sun_cycle.get_time_state_name(new_state))
		_start_background_fade(planet_sun_cycle.get_room_light_color(current_room_index), "room time state changed")
		_update_time_hud()


func _get_time_hud_text() -> String:
	return "H%02d %s" % [
		planet_sun_cycle.get_current_hour(),
		planet_sun_cycle.get_room_time_state_name(current_room_index),
	]


func _update_time_hud() -> void:
	if ui_root != null:
		ui_root.set_time_text(_get_time_hud_text())
		ui_root.set_status_text("Room %d  %s" % [current_room_index + 1, _get_build_mode_name()])


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
	return {
		"mining_power": debug_settings.mining_power,
		"mining_power_min": GameplayTuningClass.MINING_POWER_MIN,
		"mining_power_max": GameplayTuningClass.MINING_POWER_MAX,
		"mining_radius": debug_settings.mining_radius,
		"mining_radius_min": GameplayTuningClass.MINING_RADIUS_MIN,
		"mining_radius_max": GameplayTuningClass.MINING_RADIUS_MAX,
		"mining_shape": debug_settings.mining_shape,
		"square_shape": WorldConstantsClass.ToolShape.SQUARE,
		"circle_shape": WorldConstantsClass.ToolShape.CIRCLE,
		"selected_material_text": "Inventory selected %s" % _get_cell_type_name(selected_material_id),
		"inventory_text": "Inventory %d/%d  Weight %.1f/%.1f  Drops %d" % [
			inventory_data.get_total_count(),
			inventory_data.max_capacity,
			inventory_data.get_total_weight(),
			inventory_data.max_weight_capacity,
			item_drop_data.get_total_drop_count(),
		],
		"material_counts_text": "DIRT %d (%.1f)  STONE %d (%.1f)" % [
			inventory_data.get_material_count(WorldConstantsClass.CellType.DIRT),
			WorldMaterialsClass.get_inventory_weight(WorldConstantsClass.CellType.DIRT),
			inventory_data.get_material_count(WorldConstantsClass.CellType.STONE),
			WorldMaterialsClass.get_inventory_weight(WorldConstantsClass.CellType.STONE),
		],
		"placement_text": "Placement %s size %d" % [
			_get_shape_name(debug_settings.mining_shape),
			debug_settings.mining_radius,
		],
		"build_mode_text": "Mode %s" % _get_build_mode_name(),
		"gravity_text": "Gravity fields %d/%d  Player %s" % [
			gravity_field_system.get_active_field_count(),
			gravity_field_system.get_field_count(),
			"local" if _is_player_inside_gravity_field() else "global",
		],
		"equipment_text": "Equipment: Tool %s  Bag %s  Cursor %s" % [
			_get_equipped_tool_label(),
			_get_equipped_backpack_label(),
			player_cursor_controller.get_current_cursor_behavior_name(),
		],
		"backpack_text": "Backpack: %s" % _get_backpack_contents_summary(),
		"sun_cycle_text": "Sun Cycle: H%02d  Sun R%d  Room %s" % [
			planet_sun_cycle.get_current_hour(),
			planet_sun_cycle.get_sun_room_index() + 1,
			planet_sun_cycle.get_room_time_state_name(current_room_index),
		],
		"current_time_text": _get_time_hud_text(),
		"world_laws_text": "World Laws: not implemented yet",
	}


func _get_equipped_tool_label() -> String:
	var equipped_tool: ItemDefinition = player_equipment.get_equipped_tool()
	if equipped_tool == null:
		return "empty"

	return String(equipped_tool.id)


func _get_equipped_backpack_label() -> String:
	var equipped_backpack: ItemDefinition = player_equipment.get_equipped_backpack()
	if equipped_backpack == null:
		return "empty"

	return String(equipped_backpack.id)


func _get_backpack_contents_summary() -> String:
	if backpack_container.backpack_definition == null:
		return "none"
	if backpack_container.item_stacks.is_empty():
		return "empty"

	var stack_labels: PackedStringArray = PackedStringArray()
	for item_stack in backpack_container.item_stacks:
		if item_stack.item_definition == null:
			continue
		stack_labels.append("%s x%d" % [item_stack.item_definition.id, item_stack.amount])

	return ", ".join(stack_labels)


func _on_console_input_text_submitted(new_text: String) -> void:
	var command: String = new_text.strip_edges().to_lower()

	if command == "close":
		_set_console_visible(false)
		return

	if command == "debug 1":
		debug_enabled = true
		console_input.text = ""
		queue_redraw()
		return

	if command == "debug 0":
		debug_enabled = false
		console_input.text = ""
		queue_redraw()
		return

	if command.begins_with("mining_power "):
		var raw_power: float = command.trim_prefix("mining_power ").to_float()
		debug_settings.set_mining_power(raw_power)
		_refresh_godmode_ui()
		console_input.text = ""
		queue_redraw()
		return

	if command.begins_with("mining_radius "):
		var raw_radius: int = command.trim_prefix("mining_radius ").to_int()
		debug_settings.set_mining_radius(raw_radius)
		_refresh_godmode_ui()
		console_input.text = ""
		queue_redraw()
		return

	if command == "mining_shape square":
		debug_settings.set_mining_shape(WorldConstantsClass.ToolShape.SQUARE)
		_refresh_godmode_ui()
		console_input.text = ""
		queue_redraw()
		return

	if command == "mining_shape circle":
		debug_settings.set_mining_shape(WorldConstantsClass.ToolShape.CIRCLE)
		_refresh_godmode_ui()
		console_input.text = ""
		queue_redraw()
		return

	if command == "godmode 1":
		debug_settings.set_godmode_enabled(true)
		_refresh_godmode_ui()
		console_input.text = ""
		queue_redraw()
		return

	if command == "godmode 0":
		debug_settings.set_godmode_enabled(false)
		_refresh_godmode_ui()
		console_input.text = ""
		queue_redraw()
		return

	if command == "clear_inventory":
		inventory_data.clear()
		_refresh_godmode_ui()
		console_input.text = ""
		queue_redraw()
		return

	if command.begins_with("set_inventory_capacity "):
		var raw_capacity: int = command.trim_prefix("set_inventory_capacity ").to_int()
		_set_inventory_capacity(raw_capacity)
		console_input.text = ""
		return

	if command.begins_with("set_inventory_weight_capacity "):
		var raw_weight_capacity: float = command.trim_prefix("set_inventory_weight_capacity ").to_float()
		_set_inventory_weight_capacity(raw_weight_capacity)
		console_input.text = ""
		return

	if command.begins_with("give_material "):
		var material_parts: PackedStringArray = command.split(" ", false)
		if material_parts.size() >= 3:
			var material_id: int = WorldMaterialsClass.get_material_id_by_name(material_parts[1])
			var amount: int = material_parts[2].to_int()
			if material_id != WorldConstantsClass.CellType.AIR and amount > 0:
				inventory_data.add_material(material_id, amount)
				_refresh_godmode_ui()
				queue_redraw()
		console_input.text = ""
		return

	if _handle_godmode_item_command(command):
		_refresh_godmode_ui()
		console_input.text = ""
		queue_redraw()
		return

	console_input.text = ""


func _handle_godmode_item_command(command: String) -> bool:
	match command:
		"equip_mining_tool", "equip basic mining tool":
			player_equipment.equip_item(BasicMiningToolDefinition)
			print("[GodModeItems] Equipped mining tool: %s" % [BasicMiningToolDefinition.id])
			return true
		"unequip_mining_tool", "unequip mining tool":
			player_equipment.unequip_item(EquipmentSlotClass.SlotType.PRIMARY_TOOL)
			print("[GodModeItems] Unequipped mining tool")
			return true
		"equip_backpack", "equip basic backpack":
			_equip_backpack_item(BasicBackpackItemDefinition, "[GodModeItems]")
			return true
		"unequip_backpack", "unequip backpack":
			player_equipment.unequip_item(EquipmentSlotClass.SlotType.BACKPACK)
			backpack_container.unequip_backpack()
			print("[GodModeItems] Unequipped backpack")
			return true
		"add_stone", "add 10 stone":
			_godmode_add_backpack_stack(StoneItemDefinition, 10)
			return true
		"add_scrap", "add 5 scrap":
			_godmode_add_backpack_stack(ScrapItemDefinition, 5)
			return true
		"print_equipment", "print equipment state":
			_print_equipment_state()
			return true
		"print_backpack", "print backpack contents":
			_print_backpack_contents()
			return true
		"print_cursor", "print current cursor behavior":
			print("[Cursor] Cursor behavior: %s" % [player_cursor_controller.get_current_cursor_behavior_name()])
			return true
		"advance_hour", "advance one hour":
			planet_sun_cycle.advance_one_hour()
			_refresh_godmode_ui()
			queue_redraw()
			return true
		"reset_sun_cycle", "reset sun cycle":
			planet_sun_cycle.reset_to_midnight()
			_start_background_fade(planet_sun_cycle.get_room_light_color(current_room_index), "sun cycle reset")
			_refresh_godmode_ui()
			queue_redraw()
			return true
		_:
			return false


func _godmode_add_backpack_stack(item_definition: ItemDefinition, amount: int) -> void:
	if backpack_container.backpack_definition == null:
		print("[GodModeItems] Cannot add stack: no backpack equipped")
		return
	if backpack_container.add_placeholder_stack(item_definition, amount):
		print("[GodModeItems] Added stack: %s x%d" % [item_definition.id, amount])
	_refresh_godmode_ui()


func _print_equipment_state() -> void:
	var equipped_tool: ItemDefinition = player_equipment.get_equipped_tool()
	var equipped_backpack: ItemDefinition = player_equipment.get_equipped_backpack()
	print("[GodModeItems] Equipment state:")
	print("  tool: %s" % [equipped_tool.id if equipped_tool != null else "empty"])
	print("  backpack: %s" % [equipped_backpack.id if equipped_backpack != null else "empty"])
	print("  cursor: %s" % [player_cursor_controller.get_current_cursor_behavior_name()])


func _print_backpack_contents() -> void:
	if backpack_container.backpack_definition == null:
		print("[GodModeItems] Backpack contents: no backpack equipped")
		return

	print("[GodModeItems] Backpack contents:")
	if backpack_container.item_stacks.is_empty():
		print("  empty")
		return

	for item_stack in backpack_container.item_stacks:
		print("  %s x%d" % [item_stack.item_definition.id, item_stack.amount])


func _on_godmode_mining_power_changed(value: float) -> void:
	debug_settings.set_mining_power(value)
	_refresh_godmode_ui()
	queue_redraw()


func _on_godmode_mining_radius_changed(value: int) -> void:
	debug_settings.set_mining_radius(value)
	_refresh_godmode_ui()
	queue_redraw()


func _on_godmode_mining_shape_changed(shape: int) -> void:
	debug_settings.set_mining_shape(shape)
	_refresh_godmode_ui()
	queue_redraw()


func _run_godmode_item_ui_command(command: String) -> void:
	_handle_godmode_item_command(command)
	_refresh_godmode_ui()
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
	_set_build_mode(BuildMode.GRAVITY_FIELD)


func _on_gravity_point_mode_requested() -> void:
	_set_build_mode(BuildMode.GRAVITY_POINT)


func _on_gravity_strength_selected(level_index: int) -> void:
	if pending_gravity_strength_field == null:
		print("[GodModeGravity] No pending gravity point to tune")
		return

	var strength: float = _get_gravity_strength_for_level(level_index)
	pending_gravity_strength_field.strength = strength
	print("[GodModeGravity] gravity point strength: level %d/5 %.0f" % [level_index + 1, strength])
	pending_gravity_strength_field = null
	_refresh_godmode_ui()
	queue_redraw()


func _on_time_forward_requested() -> void:
	planet_sun_cycle.advance_one_hour()
	_start_background_fade(planet_sun_cycle.get_room_light_color(current_room_index), "debug time forward")
	_update_time_hud()
	_refresh_godmode_ui()
	queue_redraw()


func _on_time_backward_requested() -> void:
	print("[GodModeTime] Time- is unsupported by the current sun-cycle system; no time change applied")
	_refresh_godmode_ui()
