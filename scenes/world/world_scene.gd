extends Node2D

const GameplayTuningClass = preload("res://systems/config/gameplay_tuning.gd")
const WorldConstantsClass = preload("res://systems/world/world_constants.gd")
const WorldUtilsClass = preload("res://systems/world/world_utils.gd")
const WorldDataClass = preload("res://systems/world/world_data.gd")
const WorldMaterialsClass = preload("res://systems/world/world_materials.gd")
const WorldShapesClass = preload("res://systems/world/world_shapes.gd")
const MiningToolProfilesClass = preload("res://systems/world/mining_tool_profiles.gd")
const MiningProgressDataClass = preload("res://systems/world/mining_progress_data.gd")
const MaterialDropDataClass = preload("res://systems/world/material_drop_data.gd")
const RuntimeDebugSettingsClass = preload("res://systems/world/runtime_debug_settings.gd")
const InventoryDataClass = preload("res://systems/inventory/inventory_data.gd")

var active_tool_profile: Dictionary = MiningToolProfilesClass.get_profile("starter_pickaxe")
var debug_settings: RuntimeDebugSettings = RuntimeDebugSettingsClass.new()
var world_data: WorldData = WorldDataClass.new()
var mining_progress_data: MiningProgressData = MiningProgressDataClass.new()
var material_drop_data: MaterialDropData = MaterialDropDataClass.new()
var inventory_data: InventoryData = InventoryDataClass.new(
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
	_generate_test_terrain()
	player_world_position = _get_planet_surface_spawn_position()
	_set_console_visible(false)
	_update_godmode_visibility()
	_update_hover_state()
	_snap_player_to_ground()
	_update_camera_position()
	_refresh_godmode_ui()
	queue_redraw()


func _process(delta: float) -> void:
	var should_redraw: bool = false

	if not _is_console_open():
		should_redraw = _update_player(delta)
		if _update_mining(delta):
			should_redraw = true

	if _update_hover_state():
		should_redraw = true

	_update_camera_position()

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
	var cell_size: Vector2i = WorldConstantsClass.CELL_SIZE
	var view_origin: Vector2 = _get_view_origin_world()
	var view_size: Vector2 = Vector2(
		GameplayTuningClass.CAMERA_VIEW_CELLS_X * cell_size.x,
		GameplayTuningClass.CAMERA_VIEW_CELLS_Y * cell_size.y
	)

	draw_rect(Rect2(view_origin, view_size), Color(0.07, 0.08, 0.1, 1.0), true)
	_draw_terrain_cells()
	_draw_material_drops()
	_draw_player()
	_draw_carried_material_pile()
	if not _has_hovered_drop():
		_draw_mining_preview()
		_draw_placement_preview()

	if debug_enabled:
		_draw_mining_range()
		if not _has_hovered_drop():
			_draw_hovered_center()
		_draw_labels()

	if _has_hovered_drop():
		_draw_drop_tooltip()


func _update_player(delta: float) -> bool:
	var previous_position: Vector2 = player_world_position
	var input_axis: float = Input.get_axis("move_left", "move_right")
	var player_center: Vector2 = _get_player_center_world()
	var gravity_direction: Vector2 = _get_gravity_direction(player_center)
	var tangent_direction: Vector2 = Vector2(-gravity_direction.y, gravity_direction.x)
	var radial_speed: float = player_velocity.dot(gravity_direction)

	radial_speed += GameplayTuningClass.PLAYER_GRAVITY * delta

	if Input.is_action_just_pressed("move_up") and _is_player_on_floor():
		radial_speed = GameplayTuningClass.PLAYER_JUMP_VELOCITY

	player_velocity = tangent_direction * (input_axis * GameplayTuningClass.PLAYER_MOVE_SPEED)
	player_velocity += gravity_direction * radial_speed
	_move_player(player_velocity * delta)

	if _is_player_on_floor():
		var ground_gravity_direction: Vector2 = _get_gravity_direction(_get_player_center_world())
		var inward_speed: float = player_velocity.dot(ground_gravity_direction)
		if inward_speed > 0.0:
			player_velocity -= ground_gravity_direction * inward_speed

	return player_world_position != previous_position


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
		var progress: float = mining_progress_data.add_progress(cell_position, progress_per_second * delta)
		changed = true

		if progress >= 1.0:
			var accepted_amount: int = inventory_data.add_material(cell_type, 1)
			world_data.remove_cell(cell_position)
			mining_progress_data.remove_progress(cell_position)

			if accepted_amount <= 0:
				material_drop_data.add_drop(
					cell_position,
					cell_type,
					1,
					GameplayTuningClass.DROPPED_MATERIAL_MERGE_RADIUS_CELLS
				)

			_refresh_godmode_ui()

	return changed


func _update_hover_state() -> bool:
	var next_hovered_cell: Vector2i = WorldUtilsClass.world_to_cell(get_global_mouse_position())
	var next_mining_center_cell: Vector2i = next_hovered_cell
	var next_hovered_drop_index: int = material_drop_data.find_nearest_drop_index(next_hovered_cell, 0)

	if next_hovered_cell == hovered_cell and next_mining_center_cell == mining_center_cell and next_hovered_drop_index == hovered_drop_index:
		return false

	hovered_cell = next_hovered_cell
	mining_center_cell = next_mining_center_cell
	hovered_drop_index = next_hovered_drop_index
	return true


func _update_camera_position() -> void:
	camera_2d.position = _get_player_center_world()


func _draw_terrain_cells() -> void:
	for cell_position in world_data.get_used_cells():
		var cell_type: int = world_data.get_cell(cell_position)
		if cell_type == WorldConstantsClass.CellType.AIR:
			continue

		var cell_rect: Rect2 = Rect2(
			WorldUtilsClass.cell_to_world(cell_position),
			Vector2(WorldConstantsClass.CELL_SIZE)
		)
		draw_rect(cell_rect, _get_cell_color(cell_type, cell_position), true)


func _draw_player() -> void:
	var player_rect: Rect2 = Rect2(
		player_world_position,
		_get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS)
	)
	draw_rect(player_rect, GameplayTuningClass.PLAYER_DEBUG_COLOR, true)
	draw_rect(player_rect, GameplayTuningClass.PLAYER_DEBUG_OUTLINE_COLOR, false, 2.0)


func _draw_material_drops() -> void:
	for drop_index in range(material_drop_data.get_drops().size()):
		var drop_entry: Dictionary = material_drop_data.get_drop_at_index(drop_index)
		var drop_cell: Vector2i = Vector2i(drop_entry.get("cell_position", Vector2i.ZERO))
		var material_id: int = int(drop_entry.get("material_id", WorldConstantsClass.CellType.AIR))
		var amount: int = int(drop_entry.get("amount", 0))
		if amount <= 0:
			continue

		var base_color: Color = WorldMaterialsClass.get_debug_color(material_id)
		var drop_center: Vector2 = _get_cell_center_world(drop_cell) + Vector2(0.0, WorldConstantsClass.CELL_SIZE.y * 0.12)
		var stack_layers: int = mini(amount, 3)
		var is_hovered_drop: bool = drop_index == hovered_drop_index

		for layer_index in range(stack_layers):
			var radius_scale: float = 1.0 - (float(layer_index) * 0.12)
			if is_hovered_drop:
				radius_scale += 0.12
			var layer_center: Vector2 = drop_center + Vector2(0.0, -GameplayTuningClass.DROPPED_MATERIAL_STACK_OFFSET * float(layer_index))
			var layer_color: Color = Color(
				minf(base_color.r * (1.0 + float(layer_index) * 0.05 + (0.12 if is_hovered_drop else 0.0)), 1.0),
				minf(base_color.g * (1.0 + float(layer_index) * 0.05 + (0.12 if is_hovered_drop else 0.0)), 1.0),
				minf(base_color.b * (1.0 + float(layer_index) * 0.05 + (0.12 if is_hovered_drop else 0.0)), 1.0),
				0.95
			)
			draw_circle(layer_center, GameplayTuningClass.DROPPED_MATERIAL_VISUAL_RADIUS * radius_scale, layer_color)

		if is_hovered_drop:
			var drop_rect: Rect2 = Rect2(
				WorldUtilsClass.cell_to_world(drop_cell),
				Vector2(WorldConstantsClass.CELL_SIZE)
			)
			draw_rect(drop_rect, GameplayTuningClass.DROPPED_MATERIAL_HOVER_OUTLINE_COLOR, false, 1.0)


func _draw_drop_tooltip() -> void:
	if not _has_hovered_drop():
		return

	var drop_entry: Dictionary = material_drop_data.get_drop_at_index(hovered_drop_index)
	var material_id: int = int(drop_entry.get("material_id", WorldConstantsClass.CellType.AIR))
	var amount: int = int(drop_entry.get("amount", 0))
	var tooltip_text: String = "%s x%d" % [
		_get_cell_type_name(material_id),
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
	var pile_center: Vector2 = player_world_position + Vector2(
		_get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS).x * 0.5,
		GameplayTuningClass.PLAYER_CARRIED_PILE_OFFSET_Y
	)
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

	draw_circle(pile_center + Vector2(-pile_width * 0.18, 0), pile_width * 0.32, Color(dominant_color.r * 0.9, dominant_color.g * 0.9, dominant_color.b * 0.9, 0.9))
	draw_circle(pile_center + Vector2(pile_width * 0.2, -pile_height * 0.2), pile_width * 0.28, Color(dominant_color.r, dominant_color.g, dominant_color.b, 0.95))
	draw_circle(pile_center + Vector2(0, -pile_height * 0.42), pile_width * 0.22, Color(minf(dominant_color.r * 1.08, 1.0), minf(dominant_color.g * 1.08, 1.0), minf(dominant_color.b * 1.08, 1.0), 0.95))


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
	var target_progress: float = mining_progress_data.get_progress(mining_center_cell)
	var target_stage: int = mining_progress_data.get_damage_stage(mining_center_cell) * 25
	var target_text: String = "target (%d,%d) %s shape %s radius %d" % [
		mining_center_cell.x,
		mining_center_cell.y,
		_get_cell_type_name(target_cell_type),
		_get_shape_name(debug_settings.mining_shape),
		debug_settings.mining_radius
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
		material_drop_data.get_total_drop_count(),
		inventory_data.get_material_count(WorldConstantsClass.CellType.DIRT),
		inventory_data.get_material_count(WorldConstantsClass.CellType.STONE)
	]

	draw_string(font, player_label_position, player_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(1, 1, 1, 1))
	draw_string(font, target_label_position, target_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(0.85, 0.95, 1.0, 1.0))
	draw_string(font, target_label_position + Vector2(0, 14), mining_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(0.85, 0.95, 1.0, 1.0))
	draw_string(font, target_label_position + Vector2(0, 28), inventory_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(0.85, 0.95, 1.0, 1.0))

	if has_inspected_cell:
		var inspected_type: int = world_data.get_cell(inspected_cell)
		var inspected_resistance: float = WorldMaterialsClass.get_mining_resistance(inspected_type)
		var inspected_tags: String = ",".join(WorldMaterialsClass.get_material_tags(inspected_type))
		var inspect_text: String = "inspect (%d,%d) %s res %.0f progress %d%% order %d tags %s" % [
			inspected_cell.x,
			inspected_cell.y,
			_get_cell_type_name(inspected_type),
			inspected_resistance,
			int(round(mining_progress_data.get_progress(inspected_cell) * 100.0)),
			_get_traversal_index(inspected_cell),
			inspected_tags
		]
		draw_string(font, player_label_position + Vector2(0, -14), inspect_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(1.0, 0.9, 0.65, 1.0))


func _move_player(motion: Vector2) -> void:
	var remaining_motion: Vector2 = motion
	var remaining_distance: float = remaining_motion.length()

	while remaining_distance > 0.0:
		var step_distance: float = minf(remaining_distance, 1.0)
		var step_motion: Vector2 = remaining_motion.normalized() * step_distance
		var next_position: Vector2 = player_world_position + step_motion

		if _player_collides_at(next_position):
			return

		player_world_position = next_position
		remaining_motion -= step_motion
		remaining_distance = remaining_motion.length()


func _player_collides_at(test_position: Vector2) -> bool:
	var player_rect: Rect2 = Rect2(test_position, _get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS))
	var start_cell: Vector2i = WorldUtilsClass.world_to_cell(player_rect.position)
	var end_cell: Vector2i = WorldUtilsClass.world_to_cell(player_rect.end - Vector2.ONE)

	for cell_x in range(start_cell.x, end_cell.x + 1):
		for cell_y in range(start_cell.y, end_cell.y + 1):
			if world_data.get_cell(Vector2i(cell_x, cell_y)) != WorldConstantsClass.CellType.AIR:
				return true

	return false


func _is_player_on_floor() -> bool:
	var gravity_direction: Vector2 = _get_gravity_direction(_get_player_center_world())
	return _player_collides_at(player_world_position + gravity_direction)


func _snap_player_to_ground() -> void:
	var gravity_direction: Vector2 = _get_gravity_direction(_get_player_center_world())
	var guard_limit: int = 4096
	var guard_steps: int = 0

	while not _is_player_on_floor() and guard_steps < guard_limit:
		player_world_position += gravity_direction
		guard_steps += 1
		gravity_direction = _get_gravity_direction(_get_player_center_world())

	guard_steps = 0
	gravity_direction = _get_gravity_direction(_get_player_center_world())
	while _player_collides_at(player_world_position) and guard_steps < guard_limit:
		player_world_position -= gravity_direction
		guard_steps += 1
		gravity_direction = _get_gravity_direction(_get_player_center_world())


func _generate_test_terrain() -> void:
	world_data.clear()
	mining_progress_data.clear()
	material_drop_data.clear()
	inventory_data.clear()
	_refresh_godmode_ui()
	var center_cell: Vector2i = GameplayTuningClass.PLANET_CENTER_CELL
	var outer_radius: int = GameplayTuningClass.PLANET_RADIUS_CELLS
	var dirt_depth: int = GameplayTuningClass.PLANET_DIRT_DEPTH_CELLS
	var outer_radius_sq: int = outer_radius * outer_radius
	var dirt_inner_radius: int = maxi(outer_radius - dirt_depth, 0)
	var dirt_inner_radius_sq: int = dirt_inner_radius * dirt_inner_radius

	for cell_x in range(center_cell.x - outer_radius, center_cell.x + outer_radius + 1):
		for cell_y in range(center_cell.y - outer_radius, center_cell.y + outer_radius + 1):
			var local_x: int = cell_x - center_cell.x
			var local_y: int = cell_y - center_cell.y
			var distance_sq: int = (local_x * local_x) + (local_y * local_y)

			if distance_sq > outer_radius_sq:
				continue

			if distance_sq >= dirt_inner_radius_sq:
				world_data.set_cell(Vector2i(cell_x, cell_y), WorldConstantsClass.CellType.DIRT)
			else:
				world_data.set_cell(Vector2i(cell_x, cell_y), WorldConstantsClass.CellType.STONE)


func _get_view_origin_world() -> Vector2:
	var cell_size: Vector2i = WorldConstantsClass.CELL_SIZE
	return _get_player_center_world() - Vector2(
		(GameplayTuningClass.CAMERA_VIEW_CELLS_X * cell_size.x) * 0.5,
		(GameplayTuningClass.CAMERA_VIEW_CELLS_Y * cell_size.y) * 0.5
	)


func _get_planet_center_world() -> Vector2:
	return _get_cell_center_world(GameplayTuningClass.PLANET_CENTER_CELL)


func _get_gravity_direction(world_position: Vector2) -> Vector2:
	var gravity_vector: Vector2 = _get_planet_center_world() - world_position
	if gravity_vector == Vector2.ZERO:
		return Vector2.DOWN

	return gravity_vector.normalized()


func _get_planet_surface_spawn_position() -> Vector2:
	var player_size: Vector2 = _get_world_size_from_cells(GameplayTuningClass.PLAYER_SIZE_CELLS)
	var center_world: Vector2 = _get_planet_center_world()
	var spawn_center: Vector2 = center_world + Vector2(0.0, -GameplayTuningClass.PLANET_RADIUS_CELLS * WorldConstantsClass.CELL_SIZE.y)
	return spawn_center - (player_size * 0.5)


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


func _get_cell_color(cell_type: int, cell_position: Vector2i) -> Color:
	var base_color: Color = WorldMaterialsClass.get_debug_color(cell_type)
	var damage_stage: int = mining_progress_data.get_damage_stage(cell_position)
	var brightness: float = _get_damage_stage_brightness(damage_stage)
	return Color(
		base_color.r * brightness,
		base_color.g * brightness,
		base_color.b * brightness,
		base_color.a
	)


func _get_cell_type_name(cell_type: int) -> String:
	return WorldMaterialsClass.get_display_name(cell_type)


func _get_shape_name(shape_type: int) -> String:
	if shape_type == WorldConstantsClass.ToolShape.CIRCLE:
		return "circle"

	return "square"


func _get_damage_stage_brightness(damage_stage: int) -> float:
	match damage_stage:
		1:
			return GameplayTuningClass.DAMAGE_STAGE_25_BRIGHTNESS
		2:
			return GameplayTuningClass.DAMAGE_STAGE_50_BRIGHTNESS
		3:
			return GameplayTuningClass.DAMAGE_STAGE_75_BRIGHTNESS
		_:
			return 1.0


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
		mining_progress_data.remove_progress(cell_position)
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
	if world_data.has_cell(cell_position):
		return false

	return not _player_contains_cell(cell_position)


func _try_pick_up_hovered_drops() -> bool:
	if not _has_hovered_drop():
		return false

	var drop_entry: Dictionary = material_drop_data.get_drop_at_index(hovered_drop_index)
	var material_id: int = int(drop_entry.get("material_id", WorldConstantsClass.CellType.AIR))
	var amount: int = int(drop_entry.get("amount", 0))
	var accepted_amount: int = inventory_data.add_material(material_id, amount)
	var picked_any: bool = false

	if accepted_amount > 0:
		material_drop_data.remove_amount_at_index(hovered_drop_index, accepted_amount)
		hovered_drop_index = material_drop_data.find_nearest_drop_index(hovered_cell, 0)
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
		material_drop_data.get_total_drop_count()
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
