class_name WorldDrawController
extends RefCounted

const GameplayTuningClass = preload("res://systems/config/gameplay_tuning.gd")
const WorldConstantsClass = preload("res://systems/world/world_constants.gd")
const WorldUtilsClass = preload("res://systems/world/world_utils.gd")


func draw_world(target: Node2D, context: Dictionary) -> void:
	var view_origin: Vector2 = context.view_origin
	var view_size: Vector2 = context.view_size
	var background_controller = context.background_controller
	target.draw_rect(Rect2(view_origin, view_size), background_controller.get_current_color(), true)

	_draw_sun(target, context)
	var last_render_stats_ref: Dictionary = context.last_render_stats
	last_render_stats_ref["value"] = context.world_renderer.draw_visible_chunks(target, view_origin, view_size)
	_draw_room_bounds(target, context)
	_draw_surface_props(target, context)
	_draw_item_drops(target, context)

	if context.debug_enabled:
		if context.should_show_mining_cone_cursor:
			_draw_mining_range(target, context)
		if not _has_hovered_drop(context):
			_draw_hovered_center(target, context)

	if not _has_hovered_drop(context):
		if context.should_show_mining_cone_cursor:
			_draw_mining_preview(target, context)
		elif context.should_show_place_cursor:
			_draw_placement_preview(target, context)

	_draw_player(target, context)
	_draw_carried_material_pile(target, context)
	_draw_gravity_fields(target, context)

	if context.debug_enabled:
		_draw_labels(target, context)

	if _has_hovered_drop(context):
		_draw_drop_tooltip(target, context)

	_draw_room_transition_arrow(target, context)
	_draw_room_tooltip(target, context)

	if context.has_won:
		target.draw_rect(Rect2(view_origin, view_size), Color(0.18, 0.9, 0.24, 0.78), true)


func get_sun_visual_world_position(room_rect: Rect2, surface_cell_y: int) -> Vector2:
	var surface_world_y: float = WorldUtilsClass.cell_to_world(Vector2i(0, surface_cell_y)).y
	return Vector2(
		room_rect.position.x + (room_rect.size.x * 0.5),
		maxf(room_rect.position.y + 42.0, surface_world_y - 118.0)
	)


func is_sun_visual_in_current_room(time_manager: TimeManager, current_room_index: int) -> bool:
	return time_manager.get_sun_room_index() == current_room_index


func _draw_player(target: Node2D, context: Dictionary) -> void:
	var player_size: Vector2 = context.get_world_size_from_cells.call(GameplayTuningClass.PLAYER_SIZE_CELLS)
	var player_center: Vector2 = context.player_center_world
	var player_rect: Rect2 = Rect2(player_center - (player_size * 0.5), player_size)
	target.draw_rect(player_rect, GameplayTuningClass.PLAYER_DEBUG_COLOR, true)
	target.draw_rect(player_rect, GameplayTuningClass.PLAYER_DEBUG_OUTLINE_COLOR, false, 2.0)


func _draw_room_bounds(target: Node2D, context: Dictionary) -> void:
	target.draw_rect(context.room_rect, GameplayTuningClass.ROOM_EDGE_COLOR, false, 2.0)


func _draw_room_transition_arrow(target: Node2D, context: Dictionary) -> void:
	var room_edge: String = context.room_transition_edge
	if room_edge == context.room_edge_none:
		return

	var player_center: Vector2 = context.player_center_world
	var room_rect: Rect2 = context.room_rect
	var arrow_size: Vector2 = Vector2(18.0, 14.0)
	var arrow_points: PackedVector2Array = PackedVector2Array()

	match room_edge:
		context.room_edge_left:
			var left_center: Vector2 = Vector2(room_rect.position.x + 16.0, player_center.y)
			arrow_points = PackedVector2Array([
				left_center + Vector2(-arrow_size.x * 0.5, 0.0),
				left_center + Vector2(arrow_size.x * 0.5, -arrow_size.y * 0.5),
				left_center + Vector2(arrow_size.x * 0.5, arrow_size.y * 0.5),
			])
		context.room_edge_right:
			var right_center: Vector2 = Vector2(room_rect.end.x - 16.0, player_center.y)
			arrow_points = PackedVector2Array([
				right_center + Vector2(arrow_size.x * 0.5, 0.0),
				right_center + Vector2(-arrow_size.x * 0.5, -arrow_size.y * 0.5),
				right_center + Vector2(-arrow_size.x * 0.5, arrow_size.y * 0.5),
			])
		context.room_edge_top:
			var top_center: Vector2 = Vector2(player_center.x, room_rect.position.y + 16.0)
			arrow_points = PackedVector2Array([
				top_center + Vector2(0.0, -arrow_size.x * 0.5),
				top_center + Vector2(-arrow_size.y * 0.5, arrow_size.x * 0.5),
				top_center + Vector2(arrow_size.y * 0.5, arrow_size.x * 0.5),
			])
		context.room_edge_bottom:
			var bottom_center: Vector2 = Vector2(player_center.x, room_rect.end.y - 16.0)
			arrow_points = PackedVector2Array([
				bottom_center + Vector2(0.0, arrow_size.x * 0.5),
				bottom_center + Vector2(-arrow_size.y * 0.5, -arrow_size.x * 0.5),
				bottom_center + Vector2(arrow_size.y * 0.5, -arrow_size.x * 0.5),
			])

	if not arrow_points.is_empty():
		target.draw_colored_polygon(arrow_points, GameplayTuningClass.ROOM_TRANSITION_ARROW_COLOR)


func _draw_room_tooltip(target: Node2D, context: Dictionary) -> void:
	var font: Font = ThemeDB.fallback_font
	if font == null:
		return

	var font_size: int = ThemeDB.fallback_font_size
	var tooltip_text: String = "Room %d / %d" % [
		context.room_number,
		context.display_room_count
	]
	tooltip_text += "  %s H%02d" % [
		context.room_time_state_name,
		context.current_hour
	]
	var text_size: Vector2 = font.get_string_size(tooltip_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	var view_origin: Vector2 = context.view_origin
	var view_size: Vector2 = context.view_size
	var padding: Vector2 = Vector2(8.0, 5.0)
	var tooltip_rect: Rect2 = Rect2(
		Vector2(
			view_origin.x + (view_size.x - text_size.x - (padding.x * 2.0)) * 0.5,
			view_origin.y + 10.0
		),
		text_size + (padding * 2.0)
	)

	target.draw_rect(tooltip_rect, Color(0.08, 0.09, 0.12, 0.9), true)
	target.draw_rect(tooltip_rect, GameplayTuningClass.ROOM_EDGE_COLOR, false, 1.0)
	target.draw_string(
		font,
		tooltip_rect.position + Vector2(padding.x, padding.y + font_size),
		tooltip_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size,
		Color(1.0, 1.0, 1.0, 1.0)
	)


func _draw_sun(target: Node2D, context: Dictionary) -> void:
	if not is_sun_visual_in_current_room(context.time_manager, context.current_room_index):
		return

	var sun_position: Vector2 = get_sun_visual_world_position(context.room_rect, context.current_room_surface_cell_y)
	target.draw_circle(sun_position, context.sun_visual_radius * 1.45, Color(1.0, 0.82, 0.18, 0.16))
	target.draw_circle(sun_position, context.sun_visual_radius, Color(1.0, 0.88, 0.16, 1.0))
	target.draw_arc(sun_position, context.sun_visual_radius + 2.0, 0.0, TAU, 48, Color(1.0, 0.98, 0.45, 0.95), 2.0)


func _draw_surface_props(target: Node2D, context: Dictionary) -> void:
	for prop_entry in context.current_room_surface_props:
		var prop_type: String = String(prop_entry.get("type", ""))
		var base_cell: Vector2i = Vector2i(prop_entry.get("base_cell", Vector2i.ZERO))
		var base_world: Vector2 = WorldUtilsClass.cell_to_world(base_cell)

		match prop_type:
			context.surface_prop_bush:
				var bush_width_cells: int = int(prop_entry.get("width_cells", 3))
				var bush_height_cells: int = int(prop_entry.get("height_cells", 1))
				var bush_size: Vector2 = context.get_world_size_from_cells.call(Vector2i(bush_width_cells, bush_height_cells))
				var bush_center: Vector2 = base_world + Vector2(bush_size.x * 0.5, 0.0)
				target.draw_circle(bush_center + Vector2(-bush_size.x * 0.2, -bush_size.y * 0.35), bush_size.x * 0.22, GameplayTuningClass.BUSH_COLOR)
				target.draw_circle(bush_center + Vector2(0.0, -bush_size.y * 0.5), bush_size.x * 0.26, GameplayTuningClass.BUSH_COLOR)
				target.draw_circle(bush_center + Vector2(bush_size.x * 0.22, -bush_size.y * 0.34), bush_size.x * 0.2, GameplayTuningClass.BUSH_COLOR)
			context.surface_prop_rock:
				var rock_width_cells: int = int(prop_entry.get("width_cells", 2))
				var rock_height_cells: int = int(prop_entry.get("height_cells", 1))
				var rock_size: Vector2 = context.get_world_size_from_cells.call(Vector2i(rock_width_cells, rock_height_cells))
				var rock_rect: Rect2 = Rect2(
					Vector2(base_world.x, base_world.y - rock_size.y),
					rock_size
				)
				var rock_points: PackedVector2Array = PackedVector2Array([
					rock_rect.position + Vector2(rock_rect.size.x * 0.08, rock_rect.size.y),
					rock_rect.position + Vector2(rock_rect.size.x * 0.22, rock_rect.size.y * 0.22),
					rock_rect.position + Vector2(rock_rect.size.x * 0.56, 0.0),
					rock_rect.position + Vector2(rock_rect.size.x * 0.9, rock_rect.size.y * 0.18),
					rock_rect.position + Vector2(rock_rect.size.x, rock_rect.size.y * 0.76),
					rock_rect.position + Vector2(rock_rect.size.x * 0.72, rock_rect.size.y),
				])
				target.draw_colored_polygon(rock_points, GameplayTuningClass.ROCK_COLOR)


func _draw_item_drops(target: Node2D, context: Dictionary) -> void:
	for drop_index in range(context.item_drop_data.get_drops().size()):
		var drop_entry: Dictionary = context.item_drop_data.get_drop_at_index(drop_index)
		var amount: int = int(drop_entry.get("amount", 0))
		if amount <= 0:
			continue

		var base_color: Color = context.get_drop_item_color.call(drop_entry)
		var drop_center: Vector2 = Vector2(drop_entry.get("world_position", Vector2.ZERO))
		var stack_layers: int = mini(amount, 3)
		var is_hovered_drop: bool = drop_index == context.hovered_drop_index
		var amount_ratio: float = clampf(
			float(amount) / float(maxi(GameplayTuningClass.DROPPED_ITEM_PILE_MAX_VISUAL_COUNT, 1)),
			0.0,
			1.0
		)
		var pile_scale: float = lerpf(
			GameplayTuningClass.DROPPED_ITEM_PILE_MIN_SCALE,
			GameplayTuningClass.DROPPED_ITEM_PILE_MAX_SCALE,
			amount_ratio
		)

		for layer_index in range(stack_layers):
			var radius_scale: float = (1.0 - (float(layer_index) * 0.12)) * pile_scale
			if is_hovered_drop:
				radius_scale += 0.12
			var layer_center: Vector2 = drop_center + Vector2(
				0.0,
				-GameplayTuningClass.DROPPED_MATERIAL_STACK_OFFSET * pile_scale * float(layer_index)
			)
			var layer_color: Color = Color(
				minf(base_color.r * (1.0 + float(layer_index) * 0.05 + (0.12 if is_hovered_drop else 0.0)), 1.0),
				minf(base_color.g * (1.0 + float(layer_index) * 0.05 + (0.12 if is_hovered_drop else 0.0)), 1.0),
				minf(base_color.b * (1.0 + float(layer_index) * 0.05 + (0.12 if is_hovered_drop else 0.0)), 1.0),
				0.95
			)
			target.draw_circle(layer_center, GameplayTuningClass.DROPPED_MATERIAL_VISUAL_RADIUS * radius_scale, layer_color)

		if is_hovered_drop:
			var drop_rect: Rect2 = Rect2(
				drop_center - Vector2(WorldConstantsClass.CELL_SIZE.x * 0.5, WorldConstantsClass.CELL_SIZE.y * 0.5),
				Vector2(WorldConstantsClass.CELL_SIZE)
			)
			target.draw_rect(drop_rect, GameplayTuningClass.DROPPED_MATERIAL_HOVER_OUTLINE_COLOR, false, 1.0)


func _draw_gravity_fields(target: Node2D, context: Dictionary) -> void:
	if not context.godmode_enabled:
		return

	for field in context.gravity_field_system.get_fields():
		var field_color: Color = Color(0.4, 0.65, 1.0, 0.12)
		var outline_color: Color = Color(0.45, 0.75, 1.0, 0.85)
		target.draw_rect(field.bounds, field_color, true)
		target.draw_rect(field.bounds, outline_color, false, 2.0)
		if field.has_gravity_point:
			target.draw_circle(field.gravity_point, 5.0, Color(0.25, 0.95, 1.0, 0.95))
			target.draw_line(field.bounds.get_center(), field.gravity_point, Color(0.25, 0.95, 1.0, 0.45), 1.0)

	if context.current_build_mode == context.gravity_field_build_mode:
		var preview_rect: Rect2 = context.gravity_field_preview_rect
		target.draw_rect(preview_rect, Color(0.35, 0.7, 1.0, 0.14), true)
		target.draw_rect(preview_rect, Color(0.35, 0.7, 1.0, 0.88), false, 2.0)
	elif context.current_build_mode == context.gravity_point_build_mode:
		var point_position: Vector2 = context.get_cell_center_world.call(context.mining_center_cell)
		var valid_color: Color = Color(0.2, 1.0, 0.75, 0.95)
		if context.gravity_field_system.find_field_at(point_position) == null:
			valid_color = Color(1.0, 0.28, 0.25, 0.9)
		target.draw_circle(point_position, 7.0, valid_color)


func _draw_drop_tooltip(target: Node2D, context: Dictionary) -> void:
	if not _has_hovered_drop(context):
		return

	var drop_entry: Dictionary = context.item_drop_data.get_drop_at_index(context.hovered_drop_index)
	var amount: int = int(drop_entry.get("amount", 0))
	var tooltip_text: String = "%s x%d" % [
		context.get_drop_item_name.call(drop_entry),
		amount
	]
	var font: Font = ThemeDB.fallback_font
	if font == null:
		return

	var font_size: int = ThemeDB.fallback_font_size
	var text_size: Vector2 = font.get_string_size(tooltip_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	var tooltip_position: Vector2 = target.get_global_mouse_position() + Vector2(12.0, -18.0)
	var padding: Vector2 = Vector2(6.0, 4.0)
	var tooltip_rect: Rect2 = Rect2(tooltip_position, text_size + padding * 2.0)

	target.draw_rect(tooltip_rect, GameplayTuningClass.DROPPED_MATERIAL_TOOLTIP_FILL_COLOR, true)
	target.draw_rect(tooltip_rect, GameplayTuningClass.DROPPED_MATERIAL_TOOLTIP_OUTLINE_COLOR, false, 1.0)
	target.draw_string(
		font,
		tooltip_rect.position + Vector2(padding.x, padding.y + font_size),
		tooltip_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		font_size,
		Color(1.0, 1.0, 1.0, 1.0)
	)


func _draw_carried_material_pile(target: Node2D, context: Dictionary) -> void:
	var inventory_data = context.inventory_data
	var total_count: int = inventory_data.get_total_count()
	if total_count <= 0:
		return

	var count_ratio: float = clampf(float(total_count) / float(maxi(inventory_data.max_capacity, 1)), 0.0, 1.0)
	var weight_ratio: float = 0.0
	if inventory_data.max_weight_capacity > 0.0:
		weight_ratio = clampf(inventory_data.get_total_weight() / inventory_data.max_weight_capacity, 0.0, 1.0)
	var capacity_ratio: float = maxf(count_ratio, weight_ratio)
	var dominant_color: Color = context.get_dominant_inventory_color.call()
	var player_center: Vector2 = context.player_center_world
	var pile_center: Vector2 = player_center + Vector2(0.0, GameplayTuningClass.PLAYER_CARRIED_PILE_OFFSET_Y)
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

	target.draw_circle(pile_center + Vector2(-pile_width * 0.18, 0.0), pile_width * 0.32, Color(dominant_color.r * 0.9, dominant_color.g * 0.9, dominant_color.b * 0.9, 0.9))
	target.draw_circle(pile_center + Vector2(pile_width * 0.2, -pile_height * 0.2), pile_width * 0.28, Color(dominant_color.r, dominant_color.g, dominant_color.b, 0.95))
	target.draw_circle(pile_center + Vector2(0.0, -pile_height * 0.42), pile_width * 0.22, Color(minf(dominant_color.r * 1.08, 1.0), minf(dominant_color.g * 1.08, 1.0), minf(dominant_color.b * 1.08, 1.0), 0.95))


func _draw_mining_range(target: Node2D, context: Dictionary) -> void:
	var radius_pixels: float = GameplayTuningClass.MINING_RANGE_CELLS * WorldConstantsClass.CELL_SIZE.x
	target.draw_arc(
		context.player_center_world,
		radius_pixels,
		0.0,
		TAU,
		96,
		GameplayTuningClass.MINING_RANGE_COLOR,
		1.5
	)


func _draw_hovered_center(target: Node2D, context: Dictionary) -> void:
	var hovered_rect: Rect2 = Rect2(
		WorldUtilsClass.cell_to_world(context.hovered_cell),
		Vector2(WorldConstantsClass.CELL_SIZE)
	)
	target.draw_rect(hovered_rect, GameplayTuningClass.DEBUG_HOVER_CELL_COLOR, false, 1.0)


func _draw_mining_preview(target: Node2D, context: Dictionary) -> void:
	var ordered_cells: Array[Vector2i] = context.ordered_preview_cells
	var cell_count: int = maxi(ordered_cells.size() - 1, 1)
	var preview_base: Color = GameplayTuningClass.MINING_PREVIEW_VALID_FILL_COLOR
	var preview_line: Color = GameplayTuningClass.MINING_PREVIEW_VALID_OUTLINE_COLOR

	if not context.is_mining_target_in_range:
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

		target.draw_rect(cell_rect, fill_color, true)
		target.draw_rect(cell_rect, line_color, false, 1.0)


func _draw_placement_preview(target: Node2D, context: Dictionary) -> void:
	var ordered_cells: Array[Vector2i] = context.ordered_preview_cells
	var material_color: Color = context.get_selected_material_color.call()
	var valid_fill: Color = GameplayTuningClass.PLACEMENT_PREVIEW_VALID_FILL_COLOR
	var valid_outline: Color = GameplayTuningClass.PLACEMENT_PREVIEW_VALID_OUTLINE_COLOR
	var invalid_fill: Color = GameplayTuningClass.PLACEMENT_PREVIEW_INVALID_FILL_COLOR
	var invalid_outline: Color = GameplayTuningClass.PLACEMENT_PREVIEW_INVALID_OUTLINE_COLOR
	var can_place: bool = context.can_place_any_preview_cells

	for cell_position in ordered_cells:
		var cell_rect: Rect2 = Rect2(
			WorldUtilsClass.cell_to_world(cell_position),
			Vector2(WorldConstantsClass.CELL_SIZE)
		)
		var fill_color: Color = valid_fill
		var outline_color: Color = valid_outline

		if not can_place or not context.can_place_cell.call(cell_position):
			fill_color = invalid_fill
			outline_color = invalid_outline
		else:
			fill_color = Color(material_color.r, material_color.g, material_color.b, valid_fill.a)
			outline_color = Color(material_color.r, material_color.g, material_color.b, valid_outline.a)

		target.draw_rect(cell_rect, fill_color, true)
		target.draw_rect(cell_rect.grow(-1.0), outline_color, false, 1.0)


func _draw_labels(target: Node2D, context: Dictionary) -> void:
	var font: Font = ThemeDB.fallback_font
	if font == null:
		return

	var font_size: int = ThemeDB.fallback_font_size
	var player_cell: Vector2i = WorldUtilsClass.world_to_cell(context.player_world_position)
	var player_label_position: Vector2 = context.player_world_position + Vector2(2, -4)
	var target_label_position: Vector2 = WorldUtilsClass.cell_to_world(context.mining_center_cell) + Vector2(2, WorldConstantsClass.CELL_SIZE.y + 12)
	var target_cell_type: int = context.world_data.get_cell(context.mining_center_cell)
	var target_progress: float = context.world_data.get_damage_progress(context.mining_center_cell)
	var target_stage: int = context.world_data.get_damage_stage(context.mining_center_cell) * 25
	var target_text: String = "target (%d,%d) %s shape %s radius %d" % [
		context.mining_center_cell.x,
		context.mining_center_cell.y,
		context.get_cell_type_name.call(target_cell_type),
		context.get_shape_name.call(context.mining_shape),
		context.mining_radius
	]
	var room_text: String = "room %d/%d edge %s" % [
		context.room_number,
		context.display_room_count,
		context.room_transition_edge
	]
	var player_text: String = "player (%d,%d) mining_power %.0f" % [
		player_cell.x,
		player_cell.y,
		context.mining_power
	]
	var mining_text: String = "progress %d%% stage %d%% order %d" % [
		int(round(target_progress * 100.0)),
		target_stage,
		context.get_traversal_index.call(context.mining_center_cell)
	]
	var inventory_data = context.inventory_data
	var inventory_text: String = "selected %s inv %d/%d weight %.1f/%.1f drops %d dirt %d stone %d" % [
		context.get_cell_type_name.call(context.selected_material_id),
		inventory_data.get_total_count(),
		inventory_data.max_capacity,
		inventory_data.get_total_weight(),
		inventory_data.max_weight_capacity,
		context.item_drop_data.get_total_drop_count(),
		inventory_data.get_material_count(WorldConstantsClass.CellType.DIRT),
		inventory_data.get_material_count(WorldConstantsClass.CellType.STONE)
	]

	target.draw_string(font, player_label_position, room_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(1, 1, 1, 1))
	target.draw_string(font, player_label_position + Vector2(0, 14), player_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(1, 1, 1, 1))
	target.draw_string(font, target_label_position, target_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(0.85, 0.95, 1.0, 1.0))
	target.draw_string(font, target_label_position + Vector2(0, 14), mining_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(0.85, 0.95, 1.0, 1.0))
	target.draw_string(font, target_label_position + Vector2(0, 28), inventory_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(0.85, 0.95, 1.0, 1.0))
	var last_render_stats: Dictionary = context.last_render_stats["value"]
	var profiling_text: String = "chunks vis %d draw %d cells %d dirty %d rebuild %d frame %.2fms" % [
		int(last_render_stats.get("visible_chunk_count", 0)),
		int(last_render_stats.get("rendered_chunk_count", 0)),
		int(last_render_stats.get("visible_cell_count", 0)),
		int(last_render_stats.get("dirty_chunk_count", 0)),
		int(last_render_stats.get("chunk_rebuild_count", 0)),
		float(last_render_stats.get("estimated_frame_time_ms", 0.0))
	]
	target.draw_string(font, target_label_position + Vector2(0, 42), profiling_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(0.75, 0.9, 0.72, 1.0))

	if context.has_inspected_cell:
		var inspected_type: int = context.world_data.get_cell(context.inspected_cell)
		var inspected_resistance: float = context.get_mining_resistance.call(inspected_type)
		var inspected_tags: String = ",".join(context.get_material_tags.call(inspected_type))
		var inspect_text: String = "inspect (%d,%d) %s res %.0f progress %d%% order %d tags %s" % [
			context.inspected_cell.x,
			context.inspected_cell.y,
			context.get_cell_type_name.call(inspected_type),
			inspected_resistance,
			int(round(context.world_data.get_damage_progress(context.inspected_cell) * 100.0)),
			context.get_traversal_index.call(context.inspected_cell),
			inspected_tags
		]
		target.draw_string(font, player_label_position + Vector2(0, -14), inspect_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(1.0, 0.9, 0.65, 1.0))


func _has_hovered_drop(context: Dictionary) -> bool:
	return context.hovered_drop_index >= 0
