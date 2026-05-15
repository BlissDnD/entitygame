class_name GodModeActionHandler
extends RefCounted

const WorldConstantsClass = preload("res://systems/world/world_constants.gd")
const WorldMaterialsClass = preload("res://systems/world/world_materials.gd")
const EquipmentSlotClass = preload("res://systems/equipment/equipment_slot.gd")


func handle_console_command(command: String, context: Dictionary) -> Dictionary:
	if command == "close":
		return {
			"handled": true,
			"close_console": true,
			"clear_console": false,
			"queue_redraw": false,
		}

	if command == "debug 1":
		context.set_debug_enabled.call(true)
		return _handled_result(false, true)

	if command == "debug 0":
		context.set_debug_enabled.call(false)
		return _handled_result(false, true)

	if command.begins_with("mining_power "):
		apply_mining_power(command.trim_prefix("mining_power ").to_float(), context.debug_settings)
		return _handled_result(true, true)

	if command.begins_with("mining_radius "):
		apply_mining_radius(command.trim_prefix("mining_radius ").to_int(), context.debug_settings)
		return _handled_result(true, true)

	if command == "mining_shape square":
		apply_mining_shape(WorldConstantsClass.ToolShape.SQUARE, context.debug_settings)
		return _handled_result(true, true)

	if command == "mining_shape circle":
		apply_mining_shape(WorldConstantsClass.ToolShape.CIRCLE, context.debug_settings)
		return _handled_result(true, true)

	if command == "godmode 1":
		context.debug_settings.set_godmode_enabled(true)
		return _handled_result(true, true)

	if command == "godmode 0":
		context.debug_settings.set_godmode_enabled(false)
		return _handled_result(true, true)

	if command == "clear_inventory":
		context.inventory_data.clear()
		return _handled_result(true, true)

	if command.begins_with("set_inventory_capacity "):
		context.set_inventory_capacity.call(command.trim_prefix("set_inventory_capacity ").to_int())
		return _handled_result(false, false)

	if command.begins_with("set_inventory_weight_capacity "):
		context.set_inventory_weight_capacity.call(command.trim_prefix("set_inventory_weight_capacity ").to_float())
		return _handled_result(false, false)

	if command.begins_with("give_material "):
		var material_parts: PackedStringArray = command.split(" ", false)
		if material_parts.size() >= 3:
			var material_id: int = WorldMaterialsClass.get_material_id_by_name(material_parts[1])
			var amount: int = material_parts[2].to_int()
			if material_id != WorldConstantsClass.CellType.AIR and amount > 0:
				context.inventory_data.add_material(material_id, amount)
				return _handled_result(true, true)
		return _handled_result(false, false)

	var item_result: Dictionary = handle_item_command(command, context)
	if bool(item_result.get("handled", false)):
		return item_result

	return {
		"handled": false,
		"clear_console": true,
		"queue_redraw": false,
	}


func handle_item_command(command: String, context: Dictionary) -> Dictionary:
	match command:
		"equip_mining_tool", "equip basic mining tool":
			context.player_equipment.equip_item(context.basic_mining_tool_definition)
			print("[GodModeItems] Equipped mining tool: %s" % [context.basic_mining_tool_definition.id])
			return _handled_result(true, true)
		"unequip_mining_tool", "unequip mining tool":
			context.player_equipment.unequip_item(EquipmentSlotClass.SlotType.PRIMARY_TOOL)
			print("[GodModeItems] Unequipped mining tool")
			return _handled_result(true, true)
		"equip_backpack", "equip basic backpack":
			context.equip_backpack_item.call(context.basic_backpack_item_definition, "[GodModeItems]")
			return _handled_result(true, true)
		"equip_axe", "equip basic axe":
			context.player_equipment.equip_item(context.basic_axe_item_definition)
			print("[GodModeItems] Equipped passive axe: %s" % [context.basic_axe_item_definition.id])
			return _handled_result(true, true)
		"unequip_axe", "unequip axe":
			context.player_equipment.unequip_item(EquipmentSlotClass.SlotType.PASSIVE_TOOL)
			print("[GodModeItems] Unequipped passive axe")
			return _handled_result(true, true)
		"unequip_backpack", "unequip backpack":
			context.player_equipment.unequip_item(EquipmentSlotClass.SlotType.BACKPACK)
			context.backpack_container.unequip_backpack()
			print("[GodModeItems] Unequipped backpack")
			return _handled_result(true, true)
		"add_stone", "add 10 stone":
			context.inventory_runtime.add_backpack_stack(context.stone_item_definition, 10)
			return _handled_result(true, true)
		"add_scrap", "add 5 scrap":
			context.inventory_runtime.add_backpack_stack(context.scrap_item_definition, 5)
			return _handled_result(true, true)
		"print_equipment", "print equipment state":
			context.inventory_runtime.print_equipment_state(context.player_cursor_controller.get_current_cursor_behavior_name())
			return _handled_result(true, true)
		"print_backpack", "print backpack contents":
			context.inventory_runtime.print_backpack_contents()
			return _handled_result(true, true)
		"print_cursor", "print current cursor behavior":
			print("[Cursor] Cursor behavior: %s" % [context.player_cursor_controller.get_current_cursor_behavior_name()])
			return _handled_result(true, true)
		"advance_hour", "advance one hour":
			context.time_manager.advance_one_hour()
			return _handled_result(true, true)
		"reset_sun_cycle", "reset sun cycle":
			context.time_manager.reset_to_midnight()
			context.start_background_fade.call(context.time_manager.get_room_light_color(context.current_room_index), "sun cycle reset")
			return _handled_result(true, true)
		_:
			return {
				"handled": false,
				"clear_console": false,
				"queue_redraw": false,
			}


func apply_mining_power(value: float, debug_settings) -> void:
	debug_settings.set_mining_power(value)


func apply_mining_radius(value: int, debug_settings) -> void:
	debug_settings.set_mining_radius(value)


func apply_mining_shape(shape: int, debug_settings) -> void:
	debug_settings.set_mining_shape(shape)


func handle_time_forward(time_manager: TimeManager, start_background_fade: Callable, current_room_index: int) -> Dictionary:
	time_manager.advance_one_hour()
	start_background_fade.call(time_manager.get_room_light_color(current_room_index), "debug time forward")
	return {
		"refresh_ui": true,
		"queue_redraw": true,
		"update_time_hud": true,
	}


func handle_time_backward() -> Dictionary:
	print("[GodModeTime] Time- is unsupported by the current sun-cycle system; no time change applied")
	return {
		"refresh_ui": true,
		"queue_redraw": false,
		"update_time_hud": false,
	}


func _handled_result(refresh_ui: bool, queue_redraw: bool) -> Dictionary:
	return {
		"handled": true,
		"clear_console": true,
		"refresh_ui": refresh_ui,
		"queue_redraw": queue_redraw,
	}
