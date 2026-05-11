class_name ChunkRenderer
extends RefCounted

const WorldConstantsClass = preload("res://systems/world/world_constants.gd")
const WorldUtilsClass = preload("res://systems/world/world_utils.gd")
const WorldMaterialsClass = preload("res://systems/world/world_materials.gd")
const GameplayTuningClass = preload("res://systems/config/gameplay_tuning.gd")


func rebuild_chunk_texture(world_data, chunk_position: Vector2i, chunk_data = null) -> Dictionary:
	var chunk_pixel_size: Vector2i = Vector2i(
		WorldConstantsClass.CHUNK_SIZE_CELLS.x * WorldConstantsClass.CELL_SIZE.x,
		WorldConstantsClass.CHUNK_SIZE_CELLS.y * WorldConstantsClass.CELL_SIZE.y
	)
	var chunk_image: Image = Image.create(chunk_pixel_size.x, chunk_pixel_size.y, false, Image.FORMAT_RGBA8)
	chunk_image.fill(Color(0.0, 0.0, 0.0, 0.0))
	var chunk_world_origin: Vector2 = WorldUtilsClass.chunk_to_world(chunk_position)

	var visible_cell_count: int = 0
	if chunk_data != null:
		for local_cell_position in chunk_data.get_used_local_cells():
			var cell_type: int = chunk_data.get_cell(local_cell_position)
			if cell_type == WorldConstantsClass.CellType.AIR:
				continue

			visible_cell_count += 1
			var cell_color: Color = _get_cell_color(chunk_data, local_cell_position, cell_type)
			var pixel_origin_x: int = local_cell_position.x * WorldConstantsClass.CELL_SIZE.x
			var pixel_origin_y: int = local_cell_position.y * WorldConstantsClass.CELL_SIZE.y

			for local_y in range(WorldConstantsClass.CELL_SIZE.y):
				for local_x in range(WorldConstantsClass.CELL_SIZE.x):
					chunk_image.set_pixel(pixel_origin_x + local_x, pixel_origin_y + local_y, cell_color)

	var chunk_origin_cell: Vector2i = WorldUtilsClass.chunk_to_cell(chunk_position)
	for world_cell_position in world_data.get_ramp_cells_for_chunk(chunk_position):
		var local_cell_position: Vector2i = world_cell_position - chunk_origin_cell
		var ramp_type: int = world_data.get_ramp_type(world_cell_position)
		if ramp_type == WorldConstantsClass.RampType.NONE:
			continue

		visible_cell_count += 1
		var ramp_color: Color = _get_ramp_color(world_data, world_cell_position)
		var ramp_pixel_origin_x: int = local_cell_position.x * WorldConstantsClass.CELL_SIZE.x
		var ramp_pixel_origin_y: int = local_cell_position.y * WorldConstantsClass.CELL_SIZE.y
		_draw_ramp_pixels(chunk_image, ramp_pixel_origin_x, ramp_pixel_origin_y, ramp_type, ramp_color)

	var chunk_texture: ImageTexture = ImageTexture.create_from_image(chunk_image)
	return {
		"texture": chunk_texture,
		"visible_cell_count": visible_cell_count,
		"world_position": chunk_world_origin,
	}


func _get_cell_color(chunk_data, local_cell_position: Vector2i, cell_type: int) -> Color:
	var base_color: Color = WorldMaterialsClass.get_debug_color(cell_type)
	var brightness: float = _get_damage_stage_brightness(chunk_data.get_damage_stage(local_cell_position))
	return Color(
		base_color.r * brightness,
		base_color.g * brightness,
		base_color.b * brightness,
		base_color.a
	)


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


func _get_ramp_color(world_data, cell_position: Vector2i) -> Color:
	var source_cell_position: Vector2i = world_data.get_ramp_source_cell(cell_position)
	var source_cell_type: int = world_data.get_cell(source_cell_position)
	var base_color: Color = WorldMaterialsClass.get_debug_color(source_cell_type)
	var brightness: float = _get_damage_stage_brightness(world_data.get_damage_stage(source_cell_position))
	return Color(
		base_color.r * brightness,
		base_color.g * brightness,
		base_color.b * brightness,
		base_color.a
	)


func _draw_ramp_pixels(chunk_image: Image, pixel_origin_x: int, pixel_origin_y: int, ramp_type: int, ramp_color: Color) -> void:
	var cell_width: int = WorldConstantsClass.CELL_SIZE.x
	var cell_height: int = WorldConstantsClass.CELL_SIZE.y

	for local_y in range(cell_height):
		for local_x in range(cell_width):
			if not _should_fill_ramp_pixel(local_x, local_y, ramp_type, cell_width, cell_height):
				continue

			chunk_image.set_pixel(pixel_origin_x + local_x, pixel_origin_y + local_y, ramp_color)


func _should_fill_ramp_pixel(local_x: int, local_y: int, ramp_type: int, cell_width: int, cell_height: int) -> bool:
	var pixel_center_x: float = float(local_x) + 0.5
	var pixel_center_y: float = float(local_y) + 0.5

	if ramp_type == WorldConstantsClass.RampType.UP_RIGHT:
		var surface_y: float = float(cell_height) - ((pixel_center_x / float(cell_width)) * float(cell_height))
		return pixel_center_y >= surface_y

	var opposite_surface_y: float = (pixel_center_x / float(cell_width)) * float(cell_height)
	return pixel_center_y >= opposite_surface_y
