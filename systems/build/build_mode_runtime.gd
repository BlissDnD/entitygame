class_name BuildModeRuntime
extends RefCounted

const WorldConstantsClass = preload("res://systems/world/world_constants.gd")
const WorldUtilsClass = preload("res://systems/world/world_utils.gd")

const GRAVITY_FIELD_STRENGTH_MILESTONES = [180.0, 320.0, 520.0, 760.0, 980.0]

enum BuildMode {
	NONE,
	GRAVITY_FIELD,
	GRAVITY_POINT,
}

enum BuildClickResult {
	NONE,
	GRAVITY_FIELD_PLACED,
	GRAVITY_POINT_SET,
	GRAVITY_POINT_FAILED,
}

var gravity_field_system: GravityFieldSystem = null
var current_build_mode: int = BuildMode.NONE
var pending_gravity_strength_field: GravityFieldData = null


func _init(next_gravity_field_system: GravityFieldSystem = null) -> void:
	gravity_field_system = next_gravity_field_system


func set_gravity_field_system(next_gravity_field_system: GravityFieldSystem) -> void:
	gravity_field_system = next_gravity_field_system


func is_gravity_build_mode_active() -> bool:
	return current_build_mode == BuildMode.GRAVITY_FIELD or current_build_mode == BuildMode.GRAVITY_POINT


func set_build_mode(next_build_mode: int) -> void:
	current_build_mode = next_build_mode


func clear_build_mode() -> bool:
	if current_build_mode == BuildMode.NONE:
		return false

	current_build_mode = BuildMode.NONE
	return true


func handle_gravity_build_click(mining_center_cell: Vector2i, preview_cells: Array[Vector2i]) -> int:
	if gravity_field_system == null:
		return BuildClickResult.NONE

	if current_build_mode == BuildMode.GRAVITY_FIELD:
		gravity_field_system.create_field(get_gravity_field_preview_rect(mining_center_cell, preview_cells), 0.0)
		clear_build_mode()
		return BuildClickResult.GRAVITY_FIELD_PLACED

	if current_build_mode == BuildMode.GRAVITY_POINT:
		var point_position: Vector2 = get_cell_center_world(mining_center_cell)
		var field: GravityFieldData = gravity_field_system.set_gravity_point(point_position, get_gravity_strength_for_level(1))
		if field == null:
			return BuildClickResult.GRAVITY_POINT_FAILED

		pending_gravity_strength_field = field
		clear_build_mode()
		return BuildClickResult.GRAVITY_POINT_SET

	return BuildClickResult.NONE


func get_gravity_field_preview_rect(mining_center_cell: Vector2i, preview_cells: Array[Vector2i]) -> Rect2:
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


func get_build_mode_name() -> String:
	match current_build_mode:
		BuildMode.GRAVITY_FIELD:
			return "GRAVITY_FIELD"
		BuildMode.GRAVITY_POINT:
			return "GRAVITY_POINT"
		_:
			return "NONE"


func get_gravity_strength_for_level(level_index: int) -> float:
	return float(GRAVITY_FIELD_STRENGTH_MILESTONES[clampi(level_index, 0, GRAVITY_FIELD_STRENGTH_MILESTONES.size() - 1)])


func select_pending_gravity_strength(level_index: int) -> float:
	if pending_gravity_strength_field == null:
		return -1.0

	var strength: float = get_gravity_strength_for_level(level_index)
	pending_gravity_strength_field.strength = strength
	pending_gravity_strength_field = null
	return strength


func get_cell_center_world(cell_position: Vector2i) -> Vector2:
	return WorldUtilsClass.cell_to_world(cell_position) + (Vector2(WorldConstantsClass.CELL_SIZE) * 0.5)
