class_name MiningRuntime
extends RefCounted

const GameplayTuningClass = preload("res://systems/config/gameplay_tuning.gd")
const WorldConstantsClass = preload("res://systems/world/world_constants.gd")
const WorldShapesClass = preload("res://systems/world/world_shapes.gd")
const WorldMaterialsClass = preload("res://systems/world/world_materials.gd")
const ItemTypesClass = preload("res://systems/items/item_types.gd")
const CursorBehaviorDefinitionClass = preload("res://systems/cursor/cursor_behavior_definition.gd")


func update(delta: float, state: Dictionary, context: Dictionary) -> Dictionary:
	if context.is_gravity_build_mode_active:
		return {
			"changed": false,
			"block_mining_until_left_released": state.block_mining_until_left_released,
			"has_printed_missing_warning": state.has_printed_missing_warning,
			"ui_refresh_needed": false,
		}

	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return {
			"changed": false,
			"block_mining_until_left_released": false,
			"has_printed_missing_warning": false,
			"ui_refresh_needed": false,
		}

	if state.block_mining_until_left_released:
		return {
			"changed": false,
			"block_mining_until_left_released": state.block_mining_until_left_released,
			"has_printed_missing_warning": state.has_printed_missing_warning,
			"ui_refresh_needed": false,
		}

	if context.is_pointer_over_debug_ui:
		return {
			"changed": false,
			"block_mining_until_left_released": state.block_mining_until_left_released,
			"has_printed_missing_warning": state.has_printed_missing_warning,
			"ui_refresh_needed": false,
		}

	if not can_mine_with_equipped_tool(context.player_equipment, context.current_cursor_behavior, context.is_gravity_build_mode_active):
		if not state.has_printed_missing_warning:
			print("[Mining] Cannot mine: no mining tool equipped")
		return {
			"changed": false,
			"block_mining_until_left_released": state.block_mining_until_left_released,
			"has_printed_missing_warning": true,
			"ui_refresh_needed": false,
		}

	if not is_mining_target_in_range(context.player_center_world, context.target_center_world):
		return {
			"changed": false,
			"block_mining_until_left_released": state.block_mining_until_left_released,
			"has_printed_missing_warning": state.has_printed_missing_warning,
			"ui_refresh_needed": false,
		}

	var changed: bool = false
	var ui_refresh_needed: bool = false
	var ordered_cells: Array[Vector2i] = context.ordered_preview_cells
	var cell_count: int = maxi(ordered_cells.size() - 1, 1)

	for index in range(ordered_cells.size()):
		var cell_position: Vector2i = ordered_cells[index]
		var cell_type: int = context.world_data.get_cell(cell_position)
		if cell_type == WorldConstantsClass.CellType.AIR:
			continue
		if context.is_cell_mining_protected.call(cell_position):
			continue

		var material_tags: PackedStringArray = WorldMaterialsClass.get_material_tags(cell_type)
		if not material_tags.has("mineable"):
			continue

		var resistance: float = WorldMaterialsClass.get_mining_resistance(cell_type)
		if resistance <= 0.0:
			continue

		var falloff_multiplier: float = float(context.active_tool_profile.get("mining_falloff_multiplier", 0.45))
		var order_factor: float = 1.0

		if GameplayTuningClass.MINING_USE_DIRECTIONAL_SPEED_FALLOFF:
			order_factor = lerpf(1.0, falloff_multiplier, float(index) / float(cell_count))

		var progress_per_second: float = (context.mining_power / resistance) * order_factor
		var progress: float = context.world_data.add_damage_progress(cell_position, progress_per_second * delta)
		changed = true

		if progress >= 1.0:
			var accepted_amount: int = context.inventory_data.add_material(cell_type, 1)
			context.world_data.remove_cell(cell_position)
			context.world_data.remove_damage_progress(cell_position)

			if accepted_amount <= 0:
				context.item_drop_data.add_item_stack(
					context.get_cell_center_world.call(cell_position),
					"material",
					cell_type,
					1,
					GameplayTuningClass.DROPPED_ITEM_MERGE_RADIUS_PIXELS
				)

			ui_refresh_needed = true

	return {
		"changed": changed,
		"block_mining_until_left_released": state.block_mining_until_left_released,
		"has_printed_missing_warning": state.has_printed_missing_warning,
		"ui_refresh_needed": ui_refresh_needed,
	}


func get_target_world_position(player_center_world: Vector2, mouse_world_position: Vector2) -> Vector2:
	var max_range_pixels: float = GameplayTuningClass.MINING_RANGE_CELLS * WorldConstantsClass.CELL_SIZE.x
	var pointer_offset: Vector2 = mouse_world_position - player_center_world
	var clamped_offset: Vector2 = pointer_offset.limit_length(max_range_pixels)
	return player_center_world + clamped_offset


func get_preview_cells(mining_shape: int, mining_center_cell: Vector2i, mining_radius: int) -> Array[Vector2i]:
	return WorldShapesClass.get_cells_in_shape(mining_shape, mining_center_cell, mining_radius)


func get_ordered_preview_cells(
	mining_shape: int,
	mining_center_cell: Vector2i,
	mining_radius: int,
	player_center_world: Vector2,
	get_cell_center_world: Callable
) -> Array[Vector2i]:
	var preview_cells: Array[Vector2i] = get_preview_cells(mining_shape, mining_center_cell, mining_radius)
	var ordered_cells: Array[Vector2i] = []

	for preview_cell in preview_cells:
		var inserted: bool = false

		for index in range(ordered_cells.size()):
			if _is_cell_before_in_traversal(preview_cell, ordered_cells[index], mining_center_cell, player_center_world, get_cell_center_world):
				ordered_cells.insert(index, preview_cell)
				inserted = true
				break

		if not inserted:
			ordered_cells.append(preview_cell)

	return ordered_cells


func get_traversal_index(
	cell_position: Vector2i,
	mining_shape: int,
	mining_center_cell: Vector2i,
	mining_radius: int,
	player_center_world: Vector2,
	get_cell_center_world: Callable
) -> int:
	var ordered_cells: Array[Vector2i] = get_ordered_preview_cells(
		mining_shape,
		mining_center_cell,
		mining_radius,
		player_center_world,
		get_cell_center_world
	)

	for index in range(ordered_cells.size()):
		if ordered_cells[index] == cell_position:
			return index

	return -1


func is_mining_target_in_range(player_center_world: Vector2, target_center_world: Vector2) -> bool:
	return player_center_world.distance_to(target_center_world) <= GameplayTuningClass.MINING_RANGE_CELLS * WorldConstantsClass.CELL_SIZE.x


func can_mine_with_equipped_tool(player_equipment: PlayerEquipment, current_cursor_behavior: int, is_gravity_build_mode_active: bool) -> bool:
	if is_gravity_build_mode_active:
		return false
	if current_cursor_behavior != CursorBehaviorDefinitionClass.CursorBehavior.MINE_CONE:
		return false

	var equipped_tool: ItemDefinition = player_equipment.get_equipped_tool()
	if equipped_tool == null:
		return false
	if equipped_tool.item_category != ItemTypesClass.ItemCategory.EQUIPMENT:
		return false
	if not equipped_tool.is_tool:
		return false
	if equipped_tool.cursor_behavior == null:
		return false

	return equipped_tool.cursor_behavior.behavior == CursorBehaviorDefinitionClass.CursorBehavior.MINE_CONE


func try_place_preview_cells(context: Dictionary) -> Dictionary:
	if not is_mining_target_in_range(context.player_center_world, context.target_center_world):
		return {
			"placed_any": false,
			"ui_refresh_needed": false,
		}

	if not context.inventory_data.has_material(context.selected_material_id):
		return {
			"placed_any": false,
			"ui_refresh_needed": false,
		}

	var placed_any: bool = false

	for cell_position in context.ordered_preview_cells:
		if not context.inventory_data.has_material(context.selected_material_id):
			break

		if not can_place_cell(cell_position, context.world_data, context.is_cell_inside_room, context.player_contains_cell):
			continue

		if context.inventory_data.remove_material(context.selected_material_id, 1) <= 0:
			break

		context.world_data.set_cell(cell_position, context.selected_material_id)
		context.world_data.remove_damage_progress(cell_position)
		placed_any = true

	return {
		"placed_any": placed_any,
		"ui_refresh_needed": placed_any,
	}


func can_place_any_preview_cells(context: Dictionary) -> bool:
	if not is_mining_target_in_range(context.player_center_world, context.target_center_world):
		return false

	if not context.inventory_data.has_material(context.selected_material_id):
		return false

	for cell_position in context.ordered_preview_cells:
		if can_place_cell(cell_position, context.world_data, context.is_cell_inside_room, context.player_contains_cell):
			return true

	return false


func can_place_cell(cell_position: Vector2i, world_data, is_cell_inside_room: Callable, player_contains_cell: Callable) -> bool:
	if not is_cell_inside_room.call(cell_position):
		return false
	if world_data.has_cell(cell_position):
		return false

	return not player_contains_cell.call(cell_position)


func get_shape_name(shape_type: int) -> String:
	if shape_type == WorldConstantsClass.ToolShape.CIRCLE:
		return "circle"
	return "square"


func _is_cell_before_in_traversal(
	cell_a: Vector2i,
	cell_b: Vector2i,
	mining_center_cell: Vector2i,
	player_center_world: Vector2,
	get_cell_center_world: Callable
) -> bool:
	var score_a: Vector3 = _get_traversal_score(cell_a, mining_center_cell, player_center_world, get_cell_center_world)
	var score_b: Vector3 = _get_traversal_score(cell_b, mining_center_cell, player_center_world, get_cell_center_world)

	if score_a.x != score_b.x:
		return score_a.x < score_b.x
	if score_a.y != score_b.y:
		return score_a.y < score_b.y
	if score_a.z != score_b.z:
		return score_a.z < score_b.z
	if cell_a.x != cell_b.x:
		return cell_a.x < cell_b.x

	return cell_a.y < cell_b.y


func _get_traversal_score(
	cell_position: Vector2i,
	mining_center_cell: Vector2i,
	player_center_world: Vector2,
	get_cell_center_world: Callable
) -> Vector3:
	var target_center: Vector2 = get_cell_center_world.call(mining_center_cell)
	var direction: Vector2 = (target_center - player_center_world).normalized()

	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT

	var perpendicular: Vector2 = Vector2(-direction.y, direction.x)
	var cell_vector: Vector2 = get_cell_center_world.call(cell_position) - player_center_world
	var forward_distance: float = cell_vector.dot(direction)
	var lateral_distance: float = absf(cell_vector.dot(perpendicular))
	var total_distance: float = cell_vector.length()
	return Vector3(forward_distance, lateral_distance, total_distance)
