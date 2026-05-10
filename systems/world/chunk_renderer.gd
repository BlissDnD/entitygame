class_name ChunkRenderer
extends RefCounted

const WorldConstantsClass = preload("res://systems/world/world_constants.gd")
const WorldUtilsClass = preload("res://systems/world/world_utils.gd")
const WorldMaterialsClass = preload("res://systems/world/world_materials.gd")
const GameplayTuningClass = preload("res://systems/config/gameplay_tuning.gd")


func rebuild_chunk_texture(chunk_data) -> Dictionary:
	var chunk_pixel_size: Vector2i = Vector2i(
		WorldConstantsClass.CHUNK_SIZE_CELLS.x * WorldConstantsClass.CELL_SIZE.x,
		WorldConstantsClass.CHUNK_SIZE_CELLS.y * WorldConstantsClass.CELL_SIZE.y
	)
	var chunk_image: Image = Image.create(chunk_pixel_size.x, chunk_pixel_size.y, false, Image.FORMAT_RGBA8)
	chunk_image.fill(Color(0.0, 0.0, 0.0, 0.0))

	var visible_cell_count: int = 0
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

	var chunk_texture: ImageTexture = ImageTexture.create_from_image(chunk_image)
	return {
		"texture": chunk_texture,
		"visible_cell_count": visible_cell_count,
		"world_position": WorldUtilsClass.chunk_to_world(chunk_data.chunk_position),
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
