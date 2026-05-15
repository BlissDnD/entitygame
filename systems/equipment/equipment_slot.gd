class_name EquipmentSlot
extends RefCounted

enum SlotType {
	BACKPACK,
	PRIMARY_TOOL,
	PASSIVE_TOOL,
	SECONDARY_TOOL,
	WEAPON,
	SUIT,
}

var slot_type: SlotType = SlotType.PRIMARY_TOOL
var item_definition: ItemDefinition = null


func _init(next_slot_type: SlotType = SlotType.PRIMARY_TOOL) -> void:
	slot_type = next_slot_type


func equip(next_item_definition: ItemDefinition) -> void:
	item_definition = next_item_definition


func unequip() -> ItemDefinition:
	var previous_item_definition: ItemDefinition = item_definition
	item_definition = null
	return previous_item_definition


func is_empty() -> bool:
	return item_definition == null
