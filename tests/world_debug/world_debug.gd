extends Node2D

const GRID_CELLS_X := 40
const GRID_CELLS_Y := 25
const CAMERA_SPEED := 240.0

const WorldConstantsClass = preload("res://systems/world/world_constants.gd")
const WorldUtilsClass = preload("res://systems/world/world_utils.gd")
const WorldDataClass = preload("res://systems/world/world_data.gd")

var grid_origin_cell := Vector2i(-20, -12)
var hovered_cell := Vector2i.ZERO
var world_data = WorldDataClass.new()

@onready var camera_2d: Camera2D = $camera_2d


func _ready() -> void:
	_generate_test_terrain()
	queue_redraw()


func _process(delta: float) -> void:
	var should_redraw := _update_hovered_cell()

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


func _draw() -> void:
	var cell_size := WorldConstantsClass.CELL_SIZE

	var grid_pixel_size := Vector2(
		GRID_CELLS_X * cell_size.x,
		GRID_CELLS_Y * cell_size.y
	)

	var grid_world_origin := WorldUtilsClass.cell_to_world(grid_origin_cell)

	var grid_rect := Rect2(
		grid_world_origin,
		grid_pixel_size
	)

	draw_rect(
		grid_rect,
		Color(0.08, 0.08, 0.1, 1.0),
		true
	)

	_draw_terrain_cells()
	_draw_origin_cell()
	_draw_hovered_cell()
	_draw_grid_lines(
		grid_world_origin,
		grid_pixel_size,
		cell_size
	)

	_draw_origin_label()
	_draw_hovered_label()


func _draw_origin_cell() -> void:
	var origin_rect := Rect2(
		WorldUtilsClass.cell_to_world(Vector2i.ZERO),
		Vector2(WorldConstantsClass.CELL_SIZE)
	)

	draw_rect(
		origin_rect,
		Color(0.95, 0.35, 0.25, 0.8),
		true
	)


func _draw_hovered_cell() -> void:
	var hovered_rect := Rect2(
		WorldUtilsClass.cell_to_world(hovered_cell),
		Vector2(WorldConstantsClass.CELL_SIZE)
	)

	draw_rect(
		hovered_rect,
		Color(0.35, 0.8, 1.0, 0.3),
		true
	)

	draw_rect(
		hovered_rect,
		Color(0.35, 0.8, 1.0, 0.95),
		false,
		1.0
	)


func _draw_terrain_cells() -> void:
	for cell_position in world_data.get_used_cells():
		var cell_type: int = world_data.get_cell(cell_position)

		if cell_type == WorldConstantsClass.CellType.AIR:
			continue

		var cell_rect := Rect2(
			WorldUtilsClass.cell_to_world(cell_position),
			Vector2(WorldConstantsClass.CELL_SIZE)
		)

		draw_rect(
			cell_rect,
			_get_cell_color(cell_type),
			true
		)


func _draw_grid_lines(
	grid_world_origin: Vector2,
	grid_pixel_size: Vector2,
	cell_size: Vector2i
) -> void:

	var normal_line_color := Color(0.38, 0.42, 0.48, 0.85)
	var axis_line_color := Color(0.82, 0.82, 0.88, 0.95)

	for x in range(GRID_CELLS_X + 1):
		var x_position := grid_world_origin.x + (x * cell_size.x)

		var from := Vector2(
			x_position,
			grid_world_origin.y
		)

		var to := Vector2(
			x_position,
			grid_world_origin.y + grid_pixel_size.y
		)

		var line_color := normal_line_color

		if x_position == 0.0:
			line_color = axis_line_color

		draw_line(
			from,
			to,
			line_color,
			1.0
		)

	for y in range(GRID_CELLS_Y + 1):
		var y_position := grid_world_origin.y + (y * cell_size.y)

		var from := Vector2(
			grid_world_origin.x,
			y_position
		)

		var to := Vector2(
			grid_world_origin.x + grid_pixel_size.x,
			y_position
		)

		var line_color := normal_line_color

		if y_position == 0.0:
			line_color = axis_line_color

		draw_line(
			from,
			to,
			line_color,
			1.0
		)


func _draw_origin_label() -> void:
	var font := ThemeDB.fallback_font

	if font == null:
		return

	var font_size := ThemeDB.fallback_font_size

	var label_position := (
		WorldUtilsClass.cell_to_world(Vector2i.ZERO)
		+ Vector2(2, -4)
	)

	draw_string(
		font,
		label_position,
		"(0,0)",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size,
		Color(1, 1, 1, 1)
	)


func _draw_hovered_label() -> void:
	var font := ThemeDB.fallback_font

	if font == null:
		return

	var font_size := ThemeDB.fallback_font_size

	var label_position := (
		WorldUtilsClass.cell_to_world(hovered_cell)
		+ Vector2(2, WorldConstantsClass.CELL_SIZE.y + 12)
	)

	var cell_type := world_data.get_cell(hovered_cell)

	var label_text := "(%d,%d) %s" % [
		hovered_cell.x,
		hovered_cell.y,
		_get_cell_type_name(cell_type)
	]

	draw_string(
		font,
		label_position,
		label_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size,
		Color(0.85, 0.95, 1.0, 1.0)
	)


func _update_hovered_cell() -> bool:
	var next_hovered_cell := WorldUtilsClass.world_to_cell(
		get_global_mouse_position()
	)

	if next_hovered_cell == hovered_cell:
		return false

	hovered_cell = next_hovered_cell
	return true


func _generate_test_terrain() -> void:
	world_data.clear()

	for x in range(-12, 13):
		world_data.set_cell(
			Vector2i(x, 2),
			WorldConstantsClass.CellType.DIRT
		)

		world_data.set_cell(
			Vector2i(x, 3),
			WorldConstantsClass.CellType.DIRT
		)

		world_data.set_cell(
			Vector2i(x, 4),
			WorldConstantsClass.CellType.STONE
		)

		world_data.set_cell(
			Vector2i(x, 5),
			WorldConstantsClass.CellType.STONE
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
