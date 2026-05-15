class_name GodModeSnapshotBuilder
extends RefCounted

const GameplayTuningClass = preload("res://systems/config/gameplay_tuning.gd")
const WorldConstantsClass = preload("res://systems/world/world_constants.gd")
const WorldMaterialsClass = preload("res://systems/world/world_materials.gd")


func build_snapshot(
	debug_settings,
	inventory_runtime: InventoryRuntime,
	inventory_data: InventoryData,
	item_drop_data: ItemDropData,
	gravity_field_system: GravityFieldSystem,
	player_equipment: PlayerEquipment,
	backpack_container: BackpackContainer,
	player_cursor_controller: PlayerCursorController,
	time_manager: TimeManager,
	map_handler: MapHandler,
	build_mode_name: String,
	is_player_inside_gravity_field: bool,
	selected_material_name: String,
	placement_shape_name: String,
	current_time_text: String
) -> Dictionary:
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
		"selected_material_text": "Inventory selected %s" % selected_material_name,
		"inventory_text": "Inventory %d/%d  Weight %.1f/%.1f  Drops %d" % [
			inventory_data.get_total_count(),
			inventory_data.max_capacity,
			inventory_data.get_total_weight(),
			inventory_data.max_weight_capacity,
			item_drop_data.get_total_drop_count(),
		],
		"material_counts_text": "DIRT %d (%.1f)  STONE %d (%.1f)" % [
			inventory_data.get_material_count(WorldConstantsClass.CellType.DIRT),
			WorldMaterialsClass.get_inventory_weight(WorldConstantsClass.CellType.DIRT),
			inventory_data.get_material_count(WorldConstantsClass.CellType.STONE),
			WorldMaterialsClass.get_inventory_weight(WorldConstantsClass.CellType.STONE),
		],
		"placement_text": "Placement %s size %d" % [
			placement_shape_name,
			debug_settings.mining_radius,
		],
		"build_mode_text": "Mode %s" % build_mode_name,
		"gravity_text": "Gravity fields %d/%d  Player %s" % [
			gravity_field_system.get_active_field_count(),
			gravity_field_system.get_field_count(),
			"local" if is_player_inside_gravity_field else "global",
		],
		"equipment_text": "Equipment: Passive %s  Tool %s  Bag %s  Cursor %s" % [
			get_equipped_passive_label(player_equipment),
			get_equipped_tool_label(player_equipment),
			get_equipped_backpack_label(player_equipment),
			player_cursor_controller.get_current_cursor_behavior_name(),
		],
		"backpack_text": "Backpack: %s" % get_backpack_contents_summary(backpack_container),
		"sun_cycle_text": "Sun Cycle: H%02d  Sun R%d  Room %s" % [
			time_manager.get_current_hour(),
			time_manager.get_sun_room_index() + 1,
			time_manager.get_room_time_state_name(map_handler.get_current_room_index()),
		],
		"current_time_text": current_time_text,
		"world_laws_text": "World Laws: not implemented yet",
	}


func get_equipped_tool_label(player_equipment: PlayerEquipment) -> String:
	var equipped_tool: ItemDefinition = player_equipment.get_equipped_tool()
	if equipped_tool == null:
		return "empty"

	return String(equipped_tool.id)


func get_equipped_backpack_label(player_equipment: PlayerEquipment) -> String:
	var equipped_backpack: ItemDefinition = player_equipment.get_equipped_backpack()
	if equipped_backpack == null:
		return "empty"

	return String(equipped_backpack.id)


func get_equipped_passive_label(player_equipment: PlayerEquipment) -> String:
	var equipped_passive: ItemDefinition = player_equipment.get_equipped_passive_item()
	if equipped_passive == null:
		return "empty"

	return String(equipped_passive.id)


func get_backpack_contents_summary(backpack_container: BackpackContainer) -> String:
	if backpack_container.backpack_definition == null:
		return "none"
	if backpack_container.item_stacks.is_empty():
		return "empty"

	var stack_labels: PackedStringArray = PackedStringArray()
	for item_stack in backpack_container.item_stacks:
		if item_stack.item_definition == null:
			continue
		stack_labels.append("%s x%d" % [item_stack.item_definition.id, item_stack.amount])

	return ", ".join(stack_labels)
