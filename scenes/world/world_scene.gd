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
const InventoryDataClass = preload("res://systems/inventory/inventory_data.gd")

const ROOM_EDGE_NONE: String = ""
const ROOM_EDGE_LEFT: String = "left"
const ROOM_EDGE_RIGHT: String = "right"
const ROOM_EDGE_TOP: String = "top"
const ROOM_EDGE_BOTTOM: String = "bottom"
const SURFACE_PROP_TREE: String = "tree"
const SURFACE_PROP_BUSH: String = "bush"
const SURFACE_PROP_ROCK: String = "rock"

var active_tool_profile: Dictionary = MiningToolProfilesClass.get_profile("starter_pickaxe")
var debug_settings = RuntimeDebugSettingsClass.new()
var world_data = WorldDataClass.new()
var world_renderer = WorldRendererClass.new(world_data)
var item_drop_data = ItemDropDataClass.new()
var inventory_data = InventoryDataClass.new(
	GameplayTuningClass.INVENTORY_CAPACITY,
	GameplayTuningClass.INVENTORY_WEIGHT_CAPACITY
)
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
var current_room_index: int = 0
var room_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var has_won: bool = false
var run_hold_time: float = 0.0
var last_run_direction: int = 0

@onready var camera_2d: Camera2D = $camera_2d
@onready var console_layer: CanvasLayer = $console_layer
@onready var console_panel: Panel = $console_layer/console_panel
@onready var console_input: LineEdit = $console_layer/console_panel/console_input
@onready var godmode_panel: Panel = $console_layer/godmode_panel
@onready var mining_power_slider: HSlider = $console_layer/godmode_panel/mining_power_slider
@onready var mining_power_value: Label = $console_layer/godmode_panel/mining_power_value
@onready var mining_radius_slider: HSlider = $console_layer/godmode_panel/mining_radius_slider
@onready var mining_radius_value: Label = $console_layer/godmode_panel/mining_radius_value
@onready var square_button: Button = $console_layer/godmode_panel/square_button
@onready var circle_button: Button = $console_layer/godmode_panel/circle_button
@onready var selected_material_value: Label = $console_layer/godmode_panel/selected_material_value
@onready var inventory_value: Label = $console_layer/godmode_panel/inventory_value
@onready var material_counts_value: Label = $console_layer/godmode_panel/material_counts_value
@onready var placement_value: Label = $console_layer/godmode_panel/placement_value


func _ready() -> void:
	debug_settings.apply_tool_profile(active_tool_profile)
	room_rng.randomize()
	_apply_view_resolution()
	_generate_rooms()
	camera_2d.ignore_rotation = true
	camera_2d.zoom = Vector2.ONE
	_set_current_room(0)
	player_world_position = _get_room_spawn_position()
	_set_console_visible(false)
	_update_godmode_visibility()
	_update_hover_state()
	_snap_player_to_ground()
	_apply_camera_tracking(-1.0)
	_refresh_godmode_ui()
	queue_redraw()


func _process(delta: float) -> void:
	var should_redraw: bool = false

	if not _is_console_open() and not has_won:
		should_redraw = _update_player(delta)
		if _update_item_drops(delta):
			should_redraw = true
		if _update_mining(delta):
			should_redraw = true

	if _update_hover_state():
		should_redraw = true

	if _try_transition_room():
		should_redraw = true

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

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if _is_pointer_over_debug_ui():
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
			if _try_place_preview_cells():
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

	draw_rect(Rect2(view_origin, view_size), Color(0.07, 0.08, 0.1, 1.0), true)
	last_render_stats = world_renderer.draw_visible_chunks(self, view_origin, view_size)
	_draw_room_bounds()
	_draw_surface_props()
	_draw_item_drops()
	if debug_enabled:
		_draw_mining_range()
		if not _has_hovered_drop():
			_draw_hovered_center()
	if not _has_hovered_drop():
		_draw_mining_preview()
		_draw_placement_preview()

	_draw_player()
	_draw_carried_material_pile()

	if debug_enabled:
		_draw_labels()

	if _has_hovered_drop():
		_draw_drop_tooltip()

	_draw_room_transition_arrow()
	_draw_room_tooltip()

	if has_won:
		draw_rect(Rect2(view_origin, view_size), Color(0.18, 0.9, 0.24, 0.78), true)


func _update_player(delta: float) -> bool:
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
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		block_mining_until_left_released = false
		return false

	if block_mining_until_left_released:
		return false

	if _is_pointer_over_debug_ui():
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
		GameplayTuningClass.DROPPED_ITEM_MERGE_RADIUS_PIXELS
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


func _draw_surface_props() -> void:
	for prop_entry in _get_current_room_surface_props():
		var prop_type: String = String(prop_entry.get("type", ""))
		var base_cell: Vector2i = Vector2i(prop_entry.get("base_cell", Vector2i.ZERO))
		var base_world: Vector2 = WorldUtilsClass.cell_to_world(base_cell)

		match prop_type:
			SURFACE_PROP_TREE:
				var trunk_width_cells: int = int(prop_entry.get("trunk_width_cells", 1))
				var trunk_height_cells: int = int(prop_entry.get("trunk_height_cells", 3))
				var canopy_width_cells: int = int(prop_entry.get("canopy_width_cells", 3))
				var canopy_height_cells: int = int(prop_entry.get("canopy_height_cells", 2))
				var trunk_size: Vector2 = _get_world_size_from_cells(Vector2i(trunk_width_cells, trunk_height_cells))
				var trunk_x: float = base_world.x + ((float(WorldConstantsClass.CELL_SIZE.x) * float(maxi(int(prop_entry.get("footprint_width_cells", trunk_width_cells)), 1))) - trunk_size.x) * 0.5
				var trunk_rect: Rect2 = Rect2(
					Vector2(trunk_x, base_world.y - trunk_size.y),
					trunk_size
				)
				draw_rect(trunk_rect, GameplayTuningClass.TREE_TRUNK_COLOR, true)
				var canopy_size: Vector2 = _get_world_size_from_cells(Vector2i(canopy_width_cells, canopy_height_cells))
				var canopy_center: Vector2 = trunk_rect.position + Vector2(trunk_rect.size.x * 0.5, 0.0)
				var canopy_rect: Rect2 = Rect2(
					canopy_center + Vector2(-canopy_size.x * 0.5, -canopy_size.y * 0.92),
					canopy_size
				)
				draw_circle(canopy_rect.get_center(), canopy_size.x * 0.32, GameplayTuningClass.TREE_LEAF_COLOR)
				draw_circle(canopy_rect.get_center() + Vector2(-canopy_size.x * 0.18, canopy_size.y * 0.05), canopy_size.x * 0.24, GameplayTuningClass.TREE_LEAF_COLOR)
				draw_circle(canopy_rect.get_center() + Vector2(canopy_size.x * 0.18, canopy_size.y * 0.02), canopy_size.x * 0.24, GameplayTuningClass.TREE_LEAF_COLOR)
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
	room_world_data_list.clear()
	room_drop_data_list.clear()
	room_size_cells_list.clear()
	room_surface_props_list.clear()
	room_protected_cells_list.clear()
	inventory_data.clear()
	current_room_index = 0
	has_won = false

	for _room_index in range(GameplayTuningClass.ROOM_COUNT):
		var room_size_cells: Vector2i = _generate_room_size_cells()
		room_size_cells_list.append(room_size_cells)
		room_world_data_list.append(_create_room_world_data(room_size_cells))
		room_drop_data_list.append(ItemDropDataClass.new())
		var room_surface_props: Array = _generate_surface_props_for_room(room_size_cells)
		room_surface_props_list.append(room_surface_props)
		room_protected_cells_list.append(_build_protected_cells_for_props(room_surface_props))


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
	world_renderer.set_world_data(world_data)
	_refresh_godmode_ui()


func _get_room_spawn_position() -> Vector2:
	var player_size: Vector2 = _get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS)
	var room_rect: Rect2 = _get_room_world_rect()
	var spawn_center_x: float = room_rect.position.x + (room_rect.size.x * 0.5)
	var spawn_top_y: float = WorldUtilsClass.cell_to_world(Vector2i(0, _get_current_room_surface_cell_y())).y - player_size.y
	return Vector2(spawn_center_x - (player_size.x * 0.5), spawn_top_y)


func _try_transition_room() -> bool:
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

	_set_current_room(next_room_index)
	_place_player_at_room_entry(room_edge)
	hovered_drop_index = -1
	has_inspected_cell = false
	_update_hover_state()
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


func _is_cell_inside_room(cell_position: Vector2i) -> bool:
	var room_size_cells: Vector2i = _get_current_room_size_cells()
	return cell_position.x >= 0 and cell_position.y >= 0 and cell_position.x < room_size_cells.x and cell_position.y < room_size_cells.y


func _clamp_player_to_room(next_position: Vector2) -> Vector2:
	var room_rect: Rect2 = _get_room_world_rect()
	var player_size: Vector2 = _get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS)
	return Vector2(
		clampf(next_position.x, room_rect.position.x, room_rect.end.x - player_size.x),
		clampf(next_position.y, room_rect.position.y, room_rect.end.y - player_size.y)
	)


func _get_view_origin_world() -> Vector2:
	return _get_camera_center_world() - (_get_viewport_world_size() * 0.5)


func _get_camera_center_world() -> Vector2:
	var room_rect: Rect2 = _get_room_world_rect()
	var half_view_size: Vector2 = _get_viewport_world_size() * 0.5
	var min_center: Vector2 = room_rect.position + half_view_size
	var max_center: Vector2 = room_rect.end - half_view_size
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


func _generate_surface_props_for_room(room_size_cells: Vector2i) -> Array:
	var props: Array = []
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
			var tree_scale: float = GameplayTuningClass.TREE_SIZE_MULTIPLIER
			var footprint_width_cells: int = maxi(int(round(float(room_rng.randi_range(2, 4)) * tree_scale)), 2)
			prop_entry = {
				"type": SURFACE_PROP_TREE,
				"base_cell": Vector2i(cell_x, surface_cell_y),
				"footprint_width_cells": footprint_width_cells,
				"trunk_width_cells": maxi(int(round(float(room_rng.randi_range(1, 2)) * tree_scale)), 1),
				"trunk_height_cells": maxi(int(round(float(room_rng.randi_range(3, 6)) * tree_scale)), 3),
				"canopy_width_cells": maxi(int(round(float(room_rng.randi_range(3, 6)) * tree_scale)), 3),
				"canopy_height_cells": maxi(int(round(float(room_rng.randi_range(2, 4)) * tree_scale)), 2),
			}
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


func _get_player_center_world() -> Vector2:
	return player_world_position + (_get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS) * 0.5)


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
	godmode_panel.visible = debug_settings.godmode_enabled


func _refresh_godmode_ui() -> void:
	_update_godmode_visibility()
	mining_power_slider.min_value = GameplayTuningClass.MINING_POWER_MIN
	mining_power_slider.max_value = GameplayTuningClass.MINING_POWER_MAX
	mining_radius_slider.min_value = GameplayTuningClass.MINING_RADIUS_MIN
	mining_radius_slider.max_value = GameplayTuningClass.MINING_RADIUS_MAX
	mining_power_slider.value = debug_settings.mining_power
	mining_power_value.text = "Power %d" % int(round(debug_settings.mining_power))
	mining_radius_slider.value = debug_settings.mining_radius
	mining_radius_value.text = "Size %d" % debug_settings.mining_radius
	square_button.button_pressed = debug_settings.mining_shape == WorldConstantsClass.ToolShape.SQUARE
	circle_button.button_pressed = debug_settings.mining_shape == WorldConstantsClass.ToolShape.CIRCLE
	selected_material_value.text = "Selected %s" % _get_cell_type_name(selected_material_id)
	inventory_value.text = "Inventory %d/%d  Weight %.1f/%.1f  Drops %d" % [
		inventory_data.get_total_count(),
		inventory_data.max_capacity,
		inventory_data.get_total_weight(),
		inventory_data.max_weight_capacity,
		item_drop_data.get_total_drop_count()
	]
	material_counts_value.text = "DIRT %d (%.1f)  STONE %d (%.1f)" % [
		inventory_data.get_material_count(WorldConstantsClass.CellType.DIRT),
		WorldMaterialsClass.get_inventory_weight(WorldConstantsClass.CellType.DIRT),
		inventory_data.get_material_count(WorldConstantsClass.CellType.STONE),
		WorldMaterialsClass.get_inventory_weight(WorldConstantsClass.CellType.STONE)
	]
	placement_value.text = "Placement %s size %d" % [
		_get_shape_name(debug_settings.mining_shape),
		debug_settings.mining_radius
	]


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

	console_input.text = ""


func _on_mining_power_slider_value_changed(value: float) -> void:
	debug_settings.set_mining_power(value)
	_refresh_godmode_ui()
	queue_redraw()


func _on_mining_radius_slider_value_changed(value: float) -> void:
	debug_settings.set_mining_radius(int(round(value)))
	_refresh_godmode_ui()
	queue_redraw()


func _on_square_button_pressed() -> void:
	debug_settings.set_mining_shape(WorldConstantsClass.ToolShape.SQUARE)
	_refresh_godmode_ui()
	queue_redraw()


func _on_circle_button_pressed() -> void:
	debug_settings.set_mining_shape(WorldConstantsClass.ToolShape.CIRCLE)
	_refresh_godmode_ui()
	queue_redraw()
