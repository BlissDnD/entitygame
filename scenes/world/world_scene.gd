extends Node2D

const VIEW_CELLS_X := 72
const VIEW_CELLS_Y := 42
const PLAYER_SPEED := 260.0
const JUMP_VELOCITY := -360.0
const GRAVITY := 980.0
const MINING_RANGE_CELLS := 12.0
const MINING_SHAPE_SIZE_CELLS := Vector2i(5, 5)

const WorldConstantsClass = preload("res://systems/world/world_constants.gd")
const WorldUtilsClass = preload("res://systems/world/world_utils.gd")
const WorldDataClass = preload("res://systems/world/world_data.gd")

var world_data = WorldDataClass.new()
var player_world_position := Vector2(-12.0, -96.0)
var player_velocity := Vector2.ZERO
var hovered_cell := Vector2i.ZERO
var mining_center_cell := Vector2i.ZERO
var debug_enabled := false

@onready var camera_2d: Camera2D = $camera_2d
@onready var console_layer: CanvasLayer = $console_layer
@onready var console_panel: Panel = $console_layer/console_panel
@onready var console_input: LineEdit = $console_layer/console_panel/console_input


func _ready() -> void:
	_generate_test_terrain()
	_set_console_visible(false)
	_update_hover_state()
	_snap_player_to_ground()
	_update_camera_position()
	queue_redraw()


func _process(delta: float) -> void:
	var should_redraw := false

	if not _is_console_open():
		should_redraw = _update_player(delta)

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

	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed \
	and _is_mining_target_in_range():
		_mine_preview_cells()
		queue_redraw()


func _draw() -> void:
	var cell_size := WorldConstantsClass.CELL_SIZE
	var view_origin := _get_view_origin_world()
	var view_size := Vector2(
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
	var previous_position := player_world_position
	var input_axis := Input.get_axis("move_left", "move_right")

	player_velocity.x = input_axis * PLAYER_SPEED
	player_velocity.y += GRAVITY * delta

	if Input.is_action_just_pressed("move_up") and _is_player_on_floor():
		player_velocity.y = JUMP_VELOCITY

	_move_player_axis(player_velocity.x * delta, true)
	_move_player_axis(player_velocity.y * delta, false)

	return player_world_position != previous_position


func _update_hover_state() -> bool:
	var next_hovered_cell := WorldUtilsClass.world_to_cell(get_global_mouse_position())
	var next_mining_center_cell := next_hovered_cell

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

		var cell_rect := Rect2(
			WorldUtilsClass.cell_to_world(cell_position),
			Vector2(WorldConstantsClass.CELL_SIZE)
		)
		draw_rect(cell_rect, _get_cell_color(cell_type), true)


func _draw_player() -> void:
	var player_rect := Rect2(
		player_world_position,
		_get_world_size_from_cells(WorldConstantsClass.PLAYER_SIZE_CELLS)
	)
	draw_rect(player_rect, Color(0.98, 0.84, 0.28, 0.92), true)
	draw_rect(player_rect, Color(1.0, 0.96, 0.62, 1.0), false, 2.0)


func _draw_mining_range() -> void:
	var radius_pixels := MINING_RANGE_CELLS * WorldConstantsClass.CELL_SIZE.x
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
	var hovered_rect := Rect2(
		WorldUtilsClass.cell_to_world(hovered_cell),
		Vector2(WorldConstantsClass.CELL_SIZE)
	)
	draw_rect(hovered_rect, Color(1.0, 1.0, 1.0, 0.12), false, 1.0)


func _draw_mining_preview() -> void:
	var preview_rect := Rect2(
		WorldUtilsClass.cell_to_world(_get_preview_origin_cell()),
		_get_world_size_from_cells(MINING_SHAPE_SIZE_CELLS)
	)
	var preview_color := Color(0.2, 0.95, 1.0, 0.28)
	var preview_outline := Color(0.2, 0.95, 1.0, 0.95)

	if not _is_mining_target_in_range():
		preview_color = Color(1.0, 0.25, 0.25, 0.28)
		preview_outline = Color(1.0, 0.35, 0.35, 0.95)

	draw_rect(preview_rect, preview_color, true)
	draw_rect(preview_rect, preview_outline, false, 2.0)


func _draw_labels() -> void:
	var font := ThemeDB.fallback_font
	if font == null:
		return

	var font_size := ThemeDB.fallback_font_size
	var player_cell := WorldUtilsClass.world_to_cell(player_world_position)
	var player_label_position := player_world_position + Vector2(2, -4)
	var target_label_position := WorldUtilsClass.cell_to_world(mining_center_cell) + Vector2(2, WorldConstantsClass.CELL_SIZE.y + 12)
	var target_text := "target (%d,%d) %s" % [
		mining_center_cell.x,
		mining_center_cell.y,
		_get_cell_type_name(world_data.get_cell(mining_center_cell))
	]
	var player_text := "player (%d,%d)" % [player_cell.x, player_cell.y]

	draw_string(
		font,
		player_label_position,
		player_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size,
		Color(1, 1, 1, 1)
	)
	draw_string(
		font,
		target_label_position,
		target_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size,
		Color(0.85, 0.95, 1.0, 1.0)
	)


func _mine_preview_cells() -> void:
	var preview_origin := _get_preview_origin_cell()

	for x in range(MINING_SHAPE_SIZE_CELLS.x):
		for y in range(MINING_SHAPE_SIZE_CELLS.y):
			world_data.remove_cell(preview_origin + Vector2i(x, y))


func _move_player_axis(motion: float, is_horizontal: bool) -> void:
	var remaining_motion := motion
	var step_direction := signf(remaining_motion)

	while absf(remaining_motion) > 0.0:
		var step_size := minf(absf(remaining_motion), 1.0) * step_direction
		var next_position := player_world_position

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
	var player_rect := Rect2(test_position, _get_world_size_from_cells(WorldConstantsClass.PLAYER_SIZE_CELLS))
	var start_cell := WorldUtilsClass.world_to_cell(player_rect.position)
	var end_cell := WorldUtilsClass.world_to_cell(player_rect.end - Vector2.ONE)

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

	for x in range(-48, 49):
		world_data.set_cell(Vector2i(x, 8), WorldConstantsClass.CellType.DIRT)
		world_data.set_cell(Vector2i(x, 9), WorldConstantsClass.CellType.DIRT)
		world_data.set_cell(Vector2i(x, 10), WorldConstantsClass.CellType.DIRT)

	for x in range(-50, 51):
		for y in range(11, 24):
			world_data.set_cell(Vector2i(x, y), WorldConstantsClass.CellType.STONE)


func _get_view_origin_world() -> Vector2:
	var cell_size := WorldConstantsClass.CELL_SIZE
	return _get_player_center_world() - Vector2(
		(VIEW_CELLS_X * cell_size.x) * 0.5,
		(VIEW_CELLS_Y * cell_size.y) * 0.5
	)


func _get_preview_origin_cell() -> Vector2i:
	return mining_center_cell - Vector2i(
		MINING_SHAPE_SIZE_CELLS.x / 2,
		MINING_SHAPE_SIZE_CELLS.y / 2
	)


func _is_mining_target_in_range() -> bool:
	var player_center_world := _get_player_center_world()
	var target_center_world := _get_cell_center_world(mining_center_cell)
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


func _get_cell_color(cell_type: int) -> Color:
	match cell_type:
		WorldConstantsClass.CellType.DIRT:
			return Color(0.56, 0.35, 0.22, 1.0)
		WorldConstantsClass.CellType.STONE:
			return Color(0.5, 0.54, 0.6, 1.0)
		_:
			return Color(0.07, 0.08, 0.1, 1.0)


func _get_cell_type_name(cell_type: int) -> String:
	match cell_type:
		WorldConstantsClass.CellType.DIRT:
			return "DIRT"
		WorldConstantsClass.CellType.STONE:
			return "STONE"
		_:
			return "AIR"


func _toggle_console() -> void:
	_set_console_visible(not _is_console_open())
	queue_redraw()


func _set_console_visible(is_visible: bool) -> void:
	console_layer.visible = is_visible
	console_panel.visible = is_visible

	if is_visible:
		console_input.text = ""
		console_input.grab_focus()
	else:
		console_input.release_focus()


func _is_console_open() -> bool:
	return console_layer.visible


func _on_console_input_text_submitted(new_text: String) -> void:
	var command := new_text.strip_edges().to_lower()

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

	console_input.text = ""
