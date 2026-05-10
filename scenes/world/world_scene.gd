extends Node2D

const VIEW_CELLS_X := 72
const VIEW_CELLS_Y := 42
const PLAYER_SPEED := 260.0
const JUMP_VELOCITY := -360.0
const GRAVITY := 980.0
const MINING_RANGE_CELLS := 12.0

const WorldConstantsClass = preload("res://systems/world/world_constants.gd")
const WorldUtilsClass = preload("res://systems/world/world_utils.gd")
const WorldDataClass = preload("res://systems/world/world_data.gd")
const WorldMaterialsClass = preload("res://systems/world/world_materials.gd")
const WorldShapesClass = preload("res://systems/world/world_shapes.gd")
const MiningToolProfilesClass = preload("res://systems/world/mining_tool_profiles.gd")
const MiningProgressDataClass = preload("res://systems/world/mining_progress_data.gd")
const RuntimeDebugSettingsClass = preload("res://systems/world/runtime_debug_settings.gd")

var active_tool_profile: Dictionary = MiningToolProfilesClass.get_profile("starter_pickaxe")
var debug_settings: RuntimeDebugSettings = RuntimeDebugSettingsClass.new()
var world_data: WorldData = WorldDataClass.new()
var mining_progress_data: MiningProgressData = MiningProgressDataClass.new()
var player_world_position: Vector2 = Vector2(-12.0, -96.0)
var player_velocity: Vector2 = Vector2.ZERO
var hovered_cell: Vector2i = Vector2i.ZERO
var mining_center_cell: Vector2i = Vector2i.ZERO
var debug_enabled: bool = false
var has_inspected_cell: bool = false
var inspected_cell: Vector2i = Vector2i.ZERO

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


func _ready() -> void:
	debug_settings.apply_tool_profile(active_tool_profile)
	_generate_test_terrain()
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
			queue_redraw()
			return

		if event.button_index == MOUSE_BUTTON_MIDDLE:
			has_inspected_cell = true
			inspected_cell = hovered_cell
			queue_redraw()


func _draw() -> void:
	var cell_size: Vector2i = WorldConstantsClass.CELL_SIZE
	var view_origin: Vector2 = _get_view_origin_world()
	var view_size: Vector2 = Vector2(
		VIEW_CELLS_X * cell_size.x,
		VIEW_CELLS_Y * cell_size.y
	)

	draw_rect(Rect2(view_origin, view_size), Color(0.07, 0.08, 0.1, 1.0), true)
	_draw_terrain_cells()
	_draw_player()
	_draw_mining_preview()

	if debug_enabled:
		_draw_mining_range()
		_draw_hovered_center()
		_draw_labels()


func _update_player(delta: float) -> bool:
	var previous_position: Vector2 = player_world_position
	var input_axis: float = Input.get_axis("move_left", "move_right")

	player_velocity.x = input_axis * PLAYER_SPEED
	player_velocity.y += GRAVITY * delta

	if Input.is_action_just_pressed("move_up") and _is_player_on_floor():
		player_velocity.y = JUMP_VELOCITY

	_move_player_axis(player_velocity.x * delta, true)
	_move_player_axis(player_velocity.y * delta, false)

	return player_world_position != previous_position


func _update_mining(delta: float) -> bool:
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
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

		var falloff_multiplier: float = active_tool_profile.get("mining_falloff_multiplier", 0.45)
		var order_factor: float = lerpf(
			1.0,
			falloff_multiplier,
			float(index) / float(cell_count)
		)
		var progress_per_second: float = (debug_settings.mining_power / resistance) * order_factor
		var progress: float = mining_progress_data.add_progress(cell_position, progress_per_second * delta)
		changed = true

		if progress >= 1.0:
			world_data.remove_cell(cell_position)
			mining_progress_data.remove_progress(cell_position)

	return changed


func _update_hover_state() -> bool:
	var next_hovered_cell: Vector2i = WorldUtilsClass.world_to_cell(get_global_mouse_position())
	var next_mining_center_cell: Vector2i = next_hovered_cell

	if next_hovered_cell == hovered_cell and next_mining_center_cell == mining_center_cell:
		return false

	hovered_cell = next_hovered_cell
	mining_center_cell = next_mining_center_cell
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
		_get_world_size_from_cells(WorldConstantsClass.PLAYER_SIZE_CELLS)
	)
	draw_rect(player_rect, Color(0.98, 0.84, 0.28, 0.92), true)
	draw_rect(player_rect, Color(1.0, 0.96, 0.62, 1.0), false, 2.0)


func _draw_mining_range() -> void:
	var radius_pixels: float = MINING_RANGE_CELLS * WorldConstantsClass.CELL_SIZE.x
	draw_arc(
		_get_player_center_world(),
		radius_pixels,
		0.0,
		TAU,
		96,
		Color(0.34, 0.66, 1.0, 0.72),
		1.5
	)


func _draw_hovered_center() -> void:
	var hovered_rect: Rect2 = Rect2(
		WorldUtilsClass.cell_to_world(hovered_cell),
		Vector2(WorldConstantsClass.CELL_SIZE)
	)
	draw_rect(hovered_rect, Color(1.0, 1.0, 1.0, 0.16), false, 1.0)


func _draw_mining_preview() -> void:
	var ordered_cells: Array[Vector2i] = _get_ordered_preview_cells()
	var cell_count: int = maxi(ordered_cells.size() - 1, 1)
	var preview_base: Color = Color(0.2, 0.95, 1.0, 0.28)
	var preview_line: Color = Color(0.2, 0.95, 1.0, 0.95)

	if not _is_mining_target_in_range():
		preview_base = Color(1.0, 0.25, 0.25, 0.28)
		preview_line = Color(1.0, 0.35, 0.35, 0.95)

	for index in range(ordered_cells.size()):
		var cell_position: Vector2i = ordered_cells[index]
		var traversal_t: float = float(index) / float(cell_count)
		var brightness: float = lerpf(1.0, 0.42, traversal_t)
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

	draw_string(font, player_label_position, player_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(1, 1, 1, 1))
	draw_string(font, target_label_position, target_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(0.85, 0.95, 1.0, 1.0))
	draw_string(font, target_label_position + Vector2(0, 14), mining_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(0.85, 0.95, 1.0, 1.0))

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


func _move_player_axis(motion: float, is_horizontal: bool) -> void:
	var remaining_motion: float = motion
	var step_direction: float = signf(remaining_motion)

	while absf(remaining_motion) > 0.0:
		var step_size: float = minf(absf(remaining_motion), 1.0) * step_direction
		var next_position: Vector2 = player_world_position

		if is_horizontal:
			next_position.x += step_size
		else:
			next_position.y += step_size

		if _player_collides_at(next_position):
			if is_horizontal:
				player_velocity.x = 0.0
			else:
				player_velocity.y = 0.0
			return

		player_world_position = next_position
		remaining_motion -= step_size


func _player_collides_at(test_position: Vector2) -> bool:
	var player_rect: Rect2 = Rect2(test_position, _get_world_size_from_cells(WorldConstantsClass.PLAYER_SIZE_CELLS))
	var start_cell: Vector2i = WorldUtilsClass.world_to_cell(player_rect.position)
	var end_cell: Vector2i = WorldUtilsClass.world_to_cell(player_rect.end - Vector2.ONE)

	for cell_x in range(start_cell.x, end_cell.x + 1):
		for cell_y in range(start_cell.y, end_cell.y + 1):
			if world_data.get_cell(Vector2i(cell_x, cell_y)) != WorldConstantsClass.CellType.AIR:
				return true

	return false


func _is_player_on_floor() -> bool:
	return _player_collides_at(player_world_position + Vector2(0.0, 1.0))


func _snap_player_to_ground() -> void:
	while not _is_player_on_floor():
		player_world_position.y += 1.0

	while _player_collides_at(player_world_position):
		player_world_position.y -= 1.0


func _generate_test_terrain() -> void:
	world_data.clear()
	mining_progress_data.clear()

	for x in range(-48, 49):
		world_data.set_cell(Vector2i(x, 8), WorldConstantsClass.CellType.DIRT)
		world_data.set_cell(Vector2i(x, 9), WorldConstantsClass.CellType.DIRT)
		world_data.set_cell(Vector2i(x, 10), WorldConstantsClass.CellType.DIRT)

	for x in range(-50, 51):
		for y in range(11, 24):
			world_data.set_cell(Vector2i(x, y), WorldConstantsClass.CellType.STONE)


func _get_view_origin_world() -> Vector2:
	var cell_size: Vector2i = WorldConstantsClass.CELL_SIZE
	return _get_player_center_world() - Vector2(
		(VIEW_CELLS_X * cell_size.x) * 0.5,
		(VIEW_CELLS_Y * cell_size.y) * 0.5
	)


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
	return player_center_world.distance_to(target_center_world) <= MINING_RANGE_CELLS * WorldConstantsClass.CELL_SIZE.x


func _get_player_center_world() -> Vector2:
	return player_world_position + (_get_world_size_from_cells(WorldConstantsClass.PLAYER_SIZE_CELLS) * 0.5)


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
			return 0.88
		2:
			return 0.72
		3:
			return 0.56
		_:
			return 1.0


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
	mining_power_slider.value = debug_settings.mining_power
	mining_power_value.text = "Power %d" % int(round(debug_settings.mining_power))
	mining_radius_slider.value = debug_settings.mining_radius
	mining_radius_value.text = "Size %d" % debug_settings.mining_radius
	square_button.button_pressed = debug_settings.mining_shape == WorldConstantsClass.ToolShape.SQUARE
	circle_button.button_pressed = debug_settings.mining_shape == WorldConstantsClass.ToolShape.CIRCLE


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
