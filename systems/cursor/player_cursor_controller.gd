class_name PlayerCursorController
extends Node

signal cursor_behavior_changed(cursor_behavior)

const CursorBehaviorDefinitionClass = preload("res://systems/cursor/cursor_behavior_definition.gd")
const EquipmentSlotClass = preload("res://systems/equipment/equipment_slot.gd")

var current_cursor_behavior: CursorBehaviorDefinitionClass.CursorBehavior = CursorBehaviorDefinitionClass.CursorBehavior.HAND


func bind_equipment(player_equipment: PlayerEquipment) -> void:
	if player_equipment == null:
		return

	player_equipment.equipped_item_changed.connect(_on_equipped_item_changed)
	_apply_item(player_equipment.get_equipped_tool())


func set_cursor_behavior(next_cursor_behavior: int) -> void:
	if current_cursor_behavior == next_cursor_behavior:
		return

	current_cursor_behavior = next_cursor_behavior
	print("Cursor behavior changed to: %s" % [_get_cursor_behavior_name(current_cursor_behavior)])
	cursor_behavior_changed.emit(current_cursor_behavior)


func get_current_cursor_behavior_name() -> String:
	return _get_cursor_behavior_name(current_cursor_behavior)


func get_current_cursor_behavior() -> int:
	return current_cursor_behavior


func uses_targeting_preview() -> bool:
	return current_cursor_behavior == CursorBehaviorDefinitionClass.CursorBehavior.MINE_CONE or current_cursor_behavior == CursorBehaviorDefinitionClass.CursorBehavior.PLACE


func _on_equipped_item_changed(slot_type, item_definition: ItemDefinition) -> void:
	if slot_type == EquipmentSlotClass.SlotType.BACKPACK:
		return

	_apply_item(item_definition)


func _apply_item(item_definition: ItemDefinition) -> void:
	if item_definition == null:
		set_cursor_behavior(CursorBehaviorDefinitionClass.CursorBehavior.HAND)
		return

	print("Equipped item: %s" % [item_definition.id])
	if item_definition.cursor_behavior != null:
		set_cursor_behavior(item_definition.cursor_behavior.behavior)
		return

	set_cursor_behavior(CursorBehaviorDefinitionClass.CursorBehavior.HAND)


func _get_cursor_behavior_name(cursor_behavior: int) -> String:
	match cursor_behavior:
		CursorBehaviorDefinitionClass.CursorBehavior.NONE:
			return "NONE"
		CursorBehaviorDefinitionClass.CursorBehavior.INTERACT:
			return "INTERACT"
		CursorBehaviorDefinitionClass.CursorBehavior.MINE_CONE:
			return "MINE_CONE"
		CursorBehaviorDefinitionClass.CursorBehavior.MELEE:
			return "MELEE"
		CursorBehaviorDefinitionClass.CursorBehavior.RANGED:
			return "RANGED"
		CursorBehaviorDefinitionClass.CursorBehavior.PLACE:
			return "PLACE"
		CursorBehaviorDefinitionClass.CursorBehavior.SCAN:
			return "SCAN"
		CursorBehaviorDefinitionClass.CursorBehavior.HAND:
			return "HAND"
		_:
			return "UNKNOWN"
