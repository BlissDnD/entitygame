extends Node2D

const GRID_CELLS_X := 40
const GRID_CELLS_Y := 25
const CAMERA_SPEED := 240.0

var grid_origin_cell := Vector2i(-20, -12)

@onready var camera_2d: Camera2D = $camera_2d


func _ready() -> void:
	print("WORLD DEBUG STARTED")
	queue_redraw()

func _process(delta: float) -> void:
	var input_direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	if input_direction == Vector2.ZERO:
		return

	camera_2d.position += input_direction * CAMERA_SPEED * delta


func _draw() -> void:
	var cell_size := WorldConstants.CELL_SIZE
	var grid_pixel_size := Vector2(
		GRID_CELLS_X * cell_size.x,
		GRID_CELLS_Y * cell_size.y
	)
	var grid_world_origin := WorldUtils.cell_to_world(grid_origin_cell)
	var grid_rect := Rect2(grid_world_origin, grid_pixel_size)

	draw_rect(grid_rect, Color(0.08, 0.08, 0.1, 1.0), true)
	_draw_origin_cell()
	_draw_grid_lines(grid_world_origin, grid_pixel_size, cell_size)
	_draw_origin_label()


func _draw_origin_cell() -> void:
	var origin_rect := Rect2(
		WorldUtils.cell_to_world(Vector2i.ZERO),
		Vector2(WorldConstants.CELL_SIZE)
	)
	draw_rect(origin_rect, Color(0.95, 0.35, 0.25, 0.8), true)


func _draw_grid_lines(grid_world_origin: Vector2, grid_pixel_size: Vector2, cell_size: Vector2i) -> void:
	var normal_line_color := Color(0.38, 0.42, 0.48, 0.85)
	var axis_line_color := Color(0.82, 0.82, 0.88, 0.95)

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


func _draw_origin_label() -> void:
	var font := ThemeDB.fallback_font
	if font == null:
		return

	var font_size := ThemeDB.fallback_font_size
	var label_position := WorldUtils.cell_to_world(Vector2i.ZERO) + Vector2(2, -4)
	draw_string(font, label_position, "(0,0)", HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(1, 1, 1, 1))
