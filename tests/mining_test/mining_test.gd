extends Node2D

const GRID_CELLS_X := 64
const GRID_CELLS_Y := 36
const CAMERA_SPEED := 240.0
const MINING_RANGE_CELLS := 12.0
const MINING_SHAPE_SIZE_CELLS := Vector2i(5, 5)

const WorldConstantsClass = preload("res://systems/world/world_constants.gd")
const WorldUtilsClass = preload("res://systems/world/world_utils.gd")
const WorldDataClass = preload("res://systems/world/world_data.gd")

var grid_origin_cell := Vector2i(-24, -18)
var player_cell := Vector2i.ZERO
var hovered_cell := Vector2i.ZERO
var mining_center_cell := Vector2i.ZERO
var world_data = WorldDataClass.new()

@onready var camera_2d: Camera2D = $camera_2d


func _ready() -> void:
	_generate_test_terrain()
	_update_hover_state()
	queue_redraw()


func _process(delta: float) -> void:
	var should_redraw := _update_hover_state()
	var input_direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	if input_direction != Vector2.ZERO:
		camera_2d.position += input_direction * CAMERA_SPEED * delta
		should_redraw = true

	if should_redraw:
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		if _is_mining_target_in_range():
			_mine_preview_cells()
			queue_redraw()


func _draw() -> void:
	var cell_size := WorldConstantsClass.CELL_SIZE
	var grid_pixel_size := Vector2(
		GRID_CELLS_X * cell_size.x,
		GRID_CELLS_Y * cell_size.y
	)
	var grid_world_origin := WorldUtilsClass.cell_to_world(grid_origin_cell)
	var grid_rect := Rect2(grid_world_origin, grid_pixel_size)

	draw_rect(grid_rect, Color(0.08, 0.08, 0.1, 1.0), true)
	_draw_terrain_cells()
	_draw_player()
	_draw_mining_range()
	_draw_hovered_center()
	_draw_mining_preview()
	_draw_grid_lines(grid_world_origin, grid_pixel_size, cell_size)
	_draw_labels()


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
		WorldUtilsClass.cell_to_world(player_cell),
		_get_world_size_from_cells(WorldConstantsClass.PLAYER_SIZE_CELLS)
	)
	draw_rect(player_rect, Color(1.0, 0.8, 0.25, 0.85), true)
	draw_rect(player_rect, Color(1.0, 0.95, 0.5, 1.0), false, 2.0)


func _draw_mining_range() -> void:
	var radius_pixels := MINING_RANGE_CELLS * WorldConstantsClass.CELL_SIZE.x
	draw_arc(
		_get_player_center_world(),
		radius_pixels,
		0.0,
		TAU,
		96,
		Color(0.45, 0.7, 1.0, 0.75),
		1.5
	)


func _draw_hovered_center() -> void:
	var hovered_rect := Rect2(
		WorldUtilsClass.cell_to_world(hovered_cell),
		Vector2(WorldConstantsClass.CELL_SIZE)
	)
	draw_rect(hovered_rect, Color(1.0, 1.0, 1.0, 0.1), false, 1.0)


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


func _draw_grid_lines(
	grid_world_origin: Vector2,
	grid_pixel_size: Vector2,
	cell_size: Vector2i
) -> void:
	var normal_line_color := Color(0.38, 0.42, 0.48, 0.65)
	var axis_line_color := Color(0.82, 0.82, 0.88, 0.9)

	for x in range(GRID_CELLS_X + 1):
		var x_position := grid_world_origin.x + (x * cell_size.x)
		var from := Vector2(x_position, grid_world_origin.y)
		var to := Vector2(x_position, grid_world_origin.y + grid_pixel_size.y)
		var line_color := normal_line_color

		if x_position == 0.0:
			line_color = axis_line_color

		draw_line(from, to, line_color, 1.0)

	for y in range(GRID_CELLS_Y + 1):
		var y_position := grid_world_origin.y + (y * cell_size.y)
		var from := Vector2(grid_world_origin.x, y_position)
		var to := Vector2(grid_world_origin.x + grid_pixel_size.x, y_position)
		var line_color := normal_line_color

		if y_position == 0.0:
			line_color = axis_line_color

		draw_line(from, to, line_color, 1.0)


func _draw_labels() -> void:
	var font := ThemeDB.fallback_font
	if font == null:
		return

	var font_size := ThemeDB.fallback_font_size
	var player_label_position := WorldUtilsClass.cell_to_world(player_cell) + Vector2(2, -4)
	var target_label_position := WorldUtilsClass.cell_to_world(mining_center_cell) + Vector2(2, WorldConstantsClass.CELL_SIZE.y + 12)
	var target_text := "target (%d,%d) %s" % [
		mining_center_cell.x,
		mining_center_cell.y,
		_get_cell_type_name(world_data.get_cell(mining_center_cell))
	]

	draw_string(
		font,
		player_label_position,
		"player (0,0)",
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


func _update_hover_state() -> bool:
	var next_hovered_cell := WorldUtilsClass.world_to_cell(get_global_mouse_position())
	var next_mining_center_cell := next_hovered_cell

	if next_hovered_cell == hovered_cell and next_mining_center_cell == mining_center_cell:
		return false

	hovered_cell = next_hovered_cell
	mining_center_cell = next_mining_center_cell
	return true


func _generate_test_terrain() -> void:
	world_data.clear()

	for x in range(-28, 29):
		world_data.set_cell(Vector2i(x, 6), WorldConstantsClass.CellType.DIRT)
		world_data.set_cell(Vector2i(x, 7), WorldConstantsClass.CellType.DIRT)

	for x in range(-30, 31):
		for y in range(8, 16):
			world_data.set_cell(Vector2i(x, y), WorldConstantsClass.CellType.STONE)


func _mine_preview_cells() -> void:
	var preview_origin := _get_preview_origin_cell()

	for x in range(MINING_SHAPE_SIZE_CELLS.x):
		for y in range(MINING_SHAPE_SIZE_CELLS.y):
			world_data.remove_cell(preview_origin + Vector2i(x, y))


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
	var player_world_origin := WorldUtilsClass.cell_to_world(player_cell)
	var player_size_world := _get_world_size_from_cells(WorldConstantsClass.PLAYER_SIZE_CELLS)
	return player_world_origin + (player_size_world * 0.5)


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
			return Color(0.08, 0.08, 0.1, 1.0)


func _get_cell_type_name(cell_type: int) -> String:
	match cell_type:
		WorldConstantsClass.CellType.DIRT:
			return "DIRT"
		WorldConstantsClass.CellType.STONE:
			return "STONE"
		_:
			return "AIR"
