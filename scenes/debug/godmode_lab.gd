extends Node2D

const GameplayTuningClass = preload("res://systems/config/gameplay_tuning.gd")
const WorldConstantsClass = preload("res://systems/world/world_constants.gd")
const WorldUtilsClass = preload("res://systems/world/world_utils.gd")
const WorldDataClass = preload("res://systems/world/world_data.gd")
const WorldRendererClass = preload("res://systems/world/world_renderer.gd")
const WorldMaterialsClass = preload("res://systems/world/world_materials.gd")
const WorldShapesClass = preload("res://systems/world/world_shapes.gd")
const RuntimeDebugSettingsClass = preload("res://systems/world/runtime_debug_settings.gd")
const ItemDropDataClass = preload("res://systems/items/item_drop_data.gd")
const InventoryDataClass = preload("res://systems/inventory/inventory_data.gd")
const PlayerEquipmentClass = preload("res://systems/equipment/player_equipment.gd")
const EquipmentSlotClass = preload("res://systems/equipment/equipment_slot.gd")
const BackpackContainerClass = preload("res://systems/backpack/backpack_container.gd")
const PlayerCursorControllerClass = preload("res://systems/cursor/player_cursor_controller.gd")
const PlanetSunCycleClass = preload("res://systems/time/planet_sun_cycle.gd")
const PlaceablePlacementServiceClass = preload("res://systems/placeables/placeable_placement_service.gd")
const BackpackWorldItemScene = preload("res://entity/items/backpack_world_item.tscn")
const PrototypeTreeDefinition = preload("res://resources/placeables/prototype_tree.tres")
const BasicMiningToolDefinition = preload("res://resources/equipment/basic_mining_tool.tres")
const BasicBackpackItemDefinition = preload("res://resources/equipment/basic_backpack.tres")
const StoneItemDefinition = preload("res://resources/items/stone.tres")
const ScrapItemDefinition = preload("res://resources/items/scrap.tres")

const LAB_ROOM_INDEX: int = 0
const LAB_ROOM_COUNT: int = 24
const LAB_TERRAIN_HALF_WIDTH_CELLS: int = 86
const LAB_SURFACE_CELL_Y: int = 14
const LAB_CAMERA_SPEED: float = 520.0
const LAB_PLAYER_MARKER_SIZE: Vector2 = Vector2(18.0, 30.0)

var world_data = WorldDataClass.new()
var world_renderer = WorldRendererClass.new(world_data)
var debug_settings = RuntimeDebugSettingsClass.new()
var item_drop_data = ItemDropDataClass.new()
var inventory_data = InventoryDataClass.new(
	GameplayTuningClass.INVENTORY_CAPACITY,
	GameplayTuningClass.INVENTORY_WEIGHT_CAPACITY
)
var player_equipment = PlayerEquipmentClass.new()
var backpack_container = BackpackContainerClass.new()
var player_cursor_controller = PlayerCursorControllerClass.new()
var planet_sun_cycle = PlanetSunCycleClass.new()
var placeable_placement_service = PlaceablePlacementServiceClass.new()
var selected_material_id: int = WorldConstantsClass.CellType.DIRT
var hovered_cell: Vector2i = Vector2i.ZERO
var lab_player_world_position: Vector2 = Vector2.ZERO

@onready var camera_2d: Camera2D = $camera_2d
@onready var world_objects: Node2D = $world_objects
@onready var placeable_objects: Node2D = $world_objects/placeable_objects
@onready var item_objects: Node2D = $world_objects/item_objects
@onready var godmode_panel: GodModePanel = $debug_layer/godmode_panel
@onready var lab_panel: Panel = $debug_layer/lab_panel
@onready var lab_readout: Label = $debug_layer/lab_panel/lab_readout


func _ready() -> void:
	debug_settings.set_godmode_enabled(true)
	_generate_lab_terrain()
	placeable_placement_service.set_context(world_data, placeable_objects)
	player_cursor_controller.bind_equipment(player_equipment)
	planet_sun_cycle.configure(LAB_ROOM_COUNT, PlanetSunCycleClass.DEFAULT_HOUR_DURATION_SECONDS)
	lab_player_world_position = Vector2(0.0, WorldUtilsClass.cell_to_world(Vector2i(0, LAB_SURFACE_CELL_Y)).y - LAB_PLAYER_MARKER_SIZE.y)
	camera_2d.position = lab_player_world_position + Vector2(0.0, -80.0)
	_connect_godmode_panel()
	_refresh_lab_ui()
	queue_redraw()


func _process(delta: float) -> void:
	var should_redraw: bool = false
	if _update_camera(delta):
		should_redraw = true
	if planet_sun_cycle.advance(delta):
		should_redraw = true
		_refresh_lab_ui()
	if _update_hovered_cell():
		should_redraw = true
	if _update_lab_mining(delta):
		should_redraw = true

	if should_redraw:
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if _is_pointer_over_debug_ui():
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_try_place_selected_material()
			queue_redraw()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_cycle_selected_material(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_cycle_selected_material(1)


func _draw() -> void:
	var view_size: Vector2 = _get_viewport_world_size()
	var view_origin: Vector2 = _get_view_origin_world()
	draw_rect(Rect2(view_origin, view_size), planet_sun_cycle.get_room_light_color(LAB_ROOM_INDEX), true)
	world_renderer.draw_visible_chunks(self, view_origin, view_size)
	_draw_lab_bounds()
	_draw_hovered_cell()
	_draw_mining_preview()
	_draw_item_drops()
	_draw_player_marker()
	_draw_lab_title()


func _connect_godmode_panel() -> void:
	godmode_panel.mining_power_changed.connect(_on_godmode_mining_power_changed)
	godmode_panel.mining_radius_changed.connect(_on_godmode_mining_radius_changed)
	godmode_panel.mining_shape_changed.connect(_on_godmode_mining_shape_changed)
	godmode_panel.equip_tool_requested.connect(_on_equip_tool_requested)
	godmode_panel.unequip_tool_requested.connect(_on_unequip_tool_requested)
	godmode_panel.equip_backpack_requested.connect(_on_equip_backpack_requested)
	godmode_panel.unequip_backpack_requested.connect(_on_unequip_backpack_requested)
	godmode_panel.add_stone_requested.connect(_on_add_stone_requested)
	godmode_panel.add_scrap_requested.connect(_on_add_scrap_requested)
	godmode_panel.print_equipment_requested.connect(_on_print_equipment_requested)
	godmode_panel.print_backpack_requested.connect(_on_print_backpack_requested)


func _generate_lab_terrain() -> void:
	world_data.clear()
	for cell_x in range(-LAB_TERRAIN_HALF_WIDTH_CELLS, LAB_TERRAIN_HALF_WIDTH_CELLS + 1):
		var surface_offset: int = int(round(sin(float(cell_x) * 0.11) * 2.0))
		var surface_y: int = LAB_SURFACE_CELL_Y + surface_offset
		for cell_y in range(surface_y, surface_y + 5):
			world_data.set_cell(Vector2i(cell_x, cell_y), WorldConstantsClass.CellType.DIRT)
		for cell_y in range(surface_y + 5, surface_y + 18):
			world_data.set_cell(Vector2i(cell_x, cell_y), WorldConstantsClass.CellType.STONE)

	for cell_x in range(-10, -5):
		world_data.remove_cell(Vector2i(cell_x, LAB_SURFACE_CELL_Y - 1))


func _update_camera(delta: float) -> bool:
	var previous_position: Vector2 = camera_2d.position
	var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector != Vector2.ZERO:
		camera_2d.position += input_vector * LAB_CAMERA_SPEED * delta

	return camera_2d.position != previous_position


func _update_hovered_cell() -> bool:
	var previous_hovered_cell: Vector2i = hovered_cell
	hovered_cell = WorldUtilsClass.world_to_cell(get_global_mouse_position())
	return hovered_cell != previous_hovered_cell


func _update_lab_mining(delta: float) -> bool:
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return false
	if _is_pointer_over_debug_ui():
		return false
	if player_equipment.get_equipped_tool() == null:
		return false

	var changed: bool = false
	for cell_position in _get_preview_cells():
		var cell_type: int = world_data.get_cell(cell_position)
		if cell_type == WorldConstantsClass.CellType.AIR:
			continue
		var resistance: float = WorldMaterialsClass.get_mining_resistance(cell_type)
		if resistance <= 0.0:
			continue

		var progress: float = world_data.add_damage_progress(cell_position, (debug_settings.mining_power / resistance) * delta)
		changed = true
		if progress >= 1.0:
			inventory_data.add_material(cell_type, 1)
			world_data.remove_cell(cell_position)
			world_data.remove_damage_progress(cell_position)

	if changed:
		_refresh_lab_ui()
	return changed


func _try_place_selected_material() -> void:
	if world_data.get_cell(hovered_cell) != WorldConstantsClass.CellType.AIR:
		return
	world_data.set_cell(hovered_cell, selected_material_id)
	_refresh_lab_ui()


func _get_preview_cells() -> Array[Vector2i]:
	return WorldShapesClass.get_cells_in_shape(debug_settings.mining_shape, hovered_cell, debug_settings.mining_radius)


func _draw_lab_bounds() -> void:
	var left_x: float = WorldUtilsClass.cell_to_world(Vector2i(-LAB_TERRAIN_HALF_WIDTH_CELLS, 0)).x
	var right_x: float = WorldUtilsClass.cell_to_world(Vector2i(LAB_TERRAIN_HALF_WIDTH_CELLS, 0)).x
	var top_y: float = WorldUtilsClass.cell_to_world(Vector2i(0, LAB_SURFACE_CELL_Y - 20)).y
	var bottom_y: float = WorldUtilsClass.cell_to_world(Vector2i(0, LAB_SURFACE_CELL_Y + 24)).y
	draw_rect(Rect2(Vector2(left_x, top_y), Vector2(right_x - left_x, bottom_y - top_y)), Color(0.9, 0.95, 1.0, 0.25), false, 2.0)


func _draw_hovered_cell() -> void:
	var cell_rect: Rect2 = Rect2(WorldUtilsClass.cell_to_world(hovered_cell), Vector2(WorldConstantsClass.CELL_SIZE))
	draw_rect(cell_rect, Color(1.0, 1.0, 1.0, 0.16), false, 1.0)


func _draw_mining_preview() -> void:
	var fill_color: Color = Color(0.2, 0.95, 1.0, 0.18)
	var outline_color: Color = Color(0.2, 0.95, 1.0, 0.8)
	if player_equipment.get_equipped_tool() == null:
		fill_color = Color(1.0, 0.35, 0.25, 0.11)
		outline_color = Color(1.0, 0.35, 0.25, 0.55)

	for cell_position in _get_preview_cells():
		var cell_rect: Rect2 = Rect2(WorldUtilsClass.cell_to_world(cell_position), Vector2(WorldConstantsClass.CELL_SIZE))
		draw_rect(cell_rect, fill_color, true)
		draw_rect(cell_rect, outline_color, false, 1.0)


func _draw_item_drops() -> void:
	for drop_entry in item_drop_data.get_drops():
		var drop_position: Vector2 = Vector2(drop_entry.get("world_position", Vector2.ZERO))
		draw_circle(drop_position, 4.0, Color(0.96, 0.84, 0.38, 0.95))


func _draw_player_marker() -> void:
	var marker_rect: Rect2 = Rect2(lab_player_world_position, LAB_PLAYER_MARKER_SIZE)
	draw_rect(marker_rect, Color(1.0, 0.84, 0.28, 0.95), true)
	draw_rect(marker_rect, Color(1.0, 1.0, 0.75, 1.0), false, 2.0)


func _draw_lab_title() -> void:
	var font: Font = ThemeDB.fallback_font
	if font == null:
		return
	draw_string(font, _get_view_origin_world() + Vector2(18.0, 28.0), "GodMode Lab Sandbox", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 18, Color(1.0, 1.0, 1.0, 0.95))


func _refresh_lab_ui() -> void:
	godmode_panel.set_visible_state(true)
	godmode_panel.refresh(_build_godmode_snapshot())
	lab_readout.text = _build_lab_readout()


func _build_godmode_snapshot() -> Dictionary:
	return {
		"mining_power": debug_settings.mining_power,
		"mining_power_min": GameplayTuningClass.MINING_POWER_MIN,
		"mining_power_max": GameplayTuningClass.MINING_POWER_MAX,
		"mining_radius": debug_settings.mining_radius,
		"mining_radius_min": GameplayTuningClass.MINING_RADIUS_MIN,
		"mining_radius_max": GameplayTuningClass.MINING_RADIUS_MAX,
		"mining_shape": debug_settings.mining_shape,
		"square_shape": WorldConstantsClass.ToolShape.SQUARE,
		"circle_shape": WorldConstantsClass.ToolShape.CIRCLE,
		"selected_material_text": "Inventory selected %s" % WorldMaterialsClass.get_display_name(selected_material_id),
		"inventory_text": "Inventory %d/%d  Weight %.1f/%.1f  Drops %d" % [
			inventory_data.get_total_count(),
			inventory_data.max_capacity,
			inventory_data.get_total_weight(),
			inventory_data.max_weight_capacity,
			item_drop_data.get_total_drop_count(),
		],
		"material_counts_text": "DIRT %d  STONE %d" % [
			inventory_data.get_material_count(WorldConstantsClass.CellType.DIRT),
			inventory_data.get_material_count(WorldConstantsClass.CellType.STONE),
		],
		"placement_text": "Placement %s size %d" % [_get_shape_name(debug_settings.mining_shape), debug_settings.mining_radius],
		"equipment_text": "Equipment: Tool %s  Bag %s  Cursor %s" % [
			_get_equipped_tool_label(),
			_get_equipped_backpack_label(),
			player_cursor_controller.get_current_cursor_behavior_name(),
		],
		"backpack_text": "Backpack: %s" % _get_backpack_contents_summary(),
		"sun_cycle_text": "Sun Cycle: H%02d  Sun R%d  Room %s" % [
			planet_sun_cycle.get_current_hour(),
			planet_sun_cycle.get_sun_room_index() + 1,
			planet_sun_cycle.get_room_time_state_name(LAB_ROOM_INDEX),
		],
		"world_laws_text": "World Laws: not implemented yet",
	}


func _build_lab_readout() -> String:
	return "Lab room %d | chunks %d | placeables %d | NPCs 0\nhover %s | material %s | drops %d" % [
		LAB_ROOM_INDEX,
		world_data.get_chunk_count(),
		placeable_objects.get_child_count(),
		hovered_cell,
		WorldMaterialsClass.get_display_name(selected_material_id),
		item_drop_data.get_total_drop_count(),
	]


func _get_equipped_tool_label() -> String:
	var equipped_tool: ItemDefinition = player_equipment.get_equipped_tool()
	if equipped_tool == null:
		return "empty"
	return String(equipped_tool.id)


func _get_equipped_backpack_label() -> String:
	var equipped_backpack: ItemDefinition = player_equipment.get_equipped_backpack()
	if equipped_backpack == null:
		return "empty"
	return String(equipped_backpack.id)


func _get_backpack_contents_summary() -> String:
	if backpack_container.backpack_definition == null:
		return "none"
	if backpack_container.item_stacks.is_empty():
		return "empty"
	var stack_labels: PackedStringArray = PackedStringArray()
	for item_stack in backpack_container.item_stacks:
		if item_stack.item_definition != null:
			stack_labels.append("%s x%d" % [item_stack.item_definition.id, item_stack.amount])
	return ", ".join(stack_labels)


func _get_shape_name(shape_type: int) -> String:
	if shape_type == WorldConstantsClass.ToolShape.CIRCLE:
		return "circle"
	return "square"


func _cycle_selected_material(direction: int) -> void:
	var material_ids: Array[int] = WorldMaterialsClass.get_placeable_material_ids()
	if material_ids.is_empty():
		return
	var current_index: int = material_ids.find(selected_material_id)
	if current_index < 0:
		current_index = 0
	selected_material_id = material_ids[posmod(current_index + direction, material_ids.size())]
	_refresh_lab_ui()
	queue_redraw()


func _is_pointer_over_debug_ui() -> bool:
	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	return godmode_panel.get_global_rect().has_point(mouse_position) or lab_panel.get_global_rect().has_point(mouse_position)


func _get_viewport_world_size() -> Vector2:
	return get_viewport_rect().size


func _get_view_origin_world() -> Vector2:
	return camera_2d.position - (_get_viewport_world_size() * 0.5)


func _on_godmode_mining_power_changed(value: float) -> void:
	debug_settings.set_mining_power(value)
	_refresh_lab_ui()


func _on_godmode_mining_radius_changed(value: int) -> void:
	debug_settings.set_mining_radius(value)
	_refresh_lab_ui()
	queue_redraw()


func _on_godmode_mining_shape_changed(shape: int) -> void:
	debug_settings.set_mining_shape(shape)
	_refresh_lab_ui()
	queue_redraw()


func _on_equip_tool_requested() -> void:
	player_equipment.equip_item(BasicMiningToolDefinition)
	_refresh_lab_ui()


func _on_unequip_tool_requested() -> void:
	player_equipment.unequip_item(EquipmentSlotClass.SlotType.PRIMARY_TOOL)
	_refresh_lab_ui()


func _on_equip_backpack_requested() -> void:
	if player_equipment.get_equipped_backpack() == null:
		player_equipment.equip_item(BasicBackpackItemDefinition)
		if BasicBackpackItemDefinition.backpack_definition is BackpackDefinition:
			backpack_container.equip_backpack(BasicBackpackItemDefinition.backpack_definition)
	_refresh_lab_ui()


func _on_unequip_backpack_requested() -> void:
	player_equipment.unequip_item(EquipmentSlotClass.SlotType.BACKPACK)
	if backpack_container.backpack_definition != null:
		backpack_container.unequip_backpack()
	_refresh_lab_ui()


func _on_add_stone_requested() -> void:
	_add_item_to_backpack_or_inventory(StoneItemDefinition, WorldConstantsClass.CellType.STONE, 10)


func _on_add_scrap_requested() -> void:
	_add_item_to_backpack_or_inventory(ScrapItemDefinition, WorldConstantsClass.CellType.AIR, 5)


func _add_item_to_backpack_or_inventory(item_definition: ItemDefinition, fallback_material_id: int, amount: int) -> void:
	if backpack_container.backpack_definition != null:
		backpack_container.add_placeholder_stack(item_definition, amount)
	elif fallback_material_id != WorldConstantsClass.CellType.AIR:
		inventory_data.add_material(fallback_material_id, amount)
	else:
		print("[GodModeLab] Cannot add %s: equip backpack first" % item_definition.id)
	_refresh_lab_ui()


func _on_print_equipment_requested() -> void:
	print("[GodModeLab] equipment tool=%s backpack=%s cursor=%s" % [
		_get_equipped_tool_label(),
		_get_equipped_backpack_label(),
		player_cursor_controller.get_current_cursor_behavior_name(),
	])


func _on_print_backpack_requested() -> void:
	print("[GodModeLab] backpack %s" % _get_backpack_contents_summary())


func _on_spawn_backpack_button_pressed() -> void:
	var backpack_item = BackpackWorldItemScene.instantiate()
	item_objects.add_child(backpack_item)
	if backpack_item is Node2D:
		backpack_item.global_position = lab_player_world_position + Vector2(48.0, LAB_PLAYER_MARKER_SIZE.y)
	if backpack_item.has_method("setup"):
		backpack_item.setup(BasicBackpackItemDefinition)
	_refresh_lab_ui()


func _on_spawn_placeable_button_pressed() -> void:
	var tile_position: Vector2i = _find_placeable_floor_tile(PrototypeTreeDefinition, 12)
	var placed_object: Node = placeable_placement_service.place_object(PrototypeTreeDefinition, tile_position, PrototypeTreeDefinition.placement_mode)
	if placed_object == null:
		print("[GodModeLab] prototype placeable spawn failed at %s" % tile_position)
	_refresh_lab_ui()


func _find_placeable_floor_tile(definition: PlaceableObjectDefinition, preferred_x: int) -> Vector2i:
	for offset in range(0, 32):
		for direction in [-1, 1]:
			var cell_x: int = preferred_x + (offset * direction)
			for cell_y in range(LAB_SURFACE_CELL_Y - 8, LAB_SURFACE_CELL_Y + 8):
				var tile_position: Vector2i = Vector2i(cell_x, cell_y)
				if placeable_placement_service.can_place(definition, tile_position, definition.placement_mode):
					return tile_position
	return Vector2i(preferred_x, LAB_SURFACE_CELL_Y - definition.footprint_tiles.y)


func _on_advance_hour_button_pressed() -> void:
	planet_sun_cycle.advance_one_hour()
	_refresh_lab_ui()
	queue_redraw()


func _on_reset_sun_button_pressed() -> void:
	planet_sun_cycle.reset_to_midnight()
	_refresh_lab_ui()
	queue_redraw()


func _on_print_inventory_button_pressed() -> void:
	print("[GodModeLab] inventory count=%d weight=%.1f drops=%d" % [
		inventory_data.get_total_count(),
		inventory_data.get_total_weight(),
		item_drop_data.get_total_drop_count(),
	])


func _on_toggle_material_button_pressed() -> void:
	_cycle_selected_material(1)
