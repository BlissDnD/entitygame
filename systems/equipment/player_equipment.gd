class_name PlayerEquipment
extends Node

signal equipped_item_changed(slot_type, item_definition)

const EquipmentSlotClass = preload("res://systems/equipment/equipment_slot.gd")

var backpack_slot = EquipmentSlotClass.new(EquipmentSlotClass.SlotType.BACKPACK)
var primary_tool_slot = EquipmentSlotClass.new(EquipmentSlotClass.SlotType.PRIMARY_TOOL)
var passive_tool_slot = EquipmentSlotClass.new(EquipmentSlotClass.SlotType.PASSIVE_TOOL)
var secondary_tool_slot = EquipmentSlotClass.new(EquipmentSlotClass.SlotType.SECONDARY_TOOL)
var weapon_slot = EquipmentSlotClass.new(EquipmentSlotClass.SlotType.WEAPON)


func equip_item(item_definition: ItemDefinition) -> bool:
	if item_definition == null:
		return false
	if not item_definition.can_be_equipped:
		print("Equip failed: %s is not equipment" % [item_definition.id])
		return false

	var slot = _get_slot_for_item(item_definition)
	if slot == null:
		print("Equip failed: no slot for %s" % [item_definition.id])
		return false

	slot.equip(item_definition)
	print("Equipped item: %s" % [item_definition.id])
	if item_definition.is_backpack_item():
		print("Equipped backpack: %s" % [item_definition.id])
	equipped_item_changed.emit(slot.slot_type, item_definition)
	return true


func unequip_item(slot_type: int) -> ItemDefinition:
	var slot = _get_slot(slot_type)
	if slot == null:
		return null

	var previous_item_definition: ItemDefinition = slot.unequip()
	if previous_item_definition != null:
		if previous_item_definition.is_backpack_item():
			print("Backpack unequipped")
		equipped_item_changed.emit(slot_type, null)

	return previous_item_definition


func get_equipped_tool() -> ItemDefinition:
	return primary_tool_slot.item_definition


func get_equipped_backpack() -> ItemDefinition:
	return backpack_slot.item_definition


func get_equipped_passive_item() -> ItemDefinition:
	return passive_tool_slot.item_definition


func _get_slot_for_item(item_definition: ItemDefinition):
	var resolved_slot_type: int = item_definition.get_equipment_slot_type()
	match resolved_slot_type:
		EquipmentSlotClass.SlotType.BACKPACK:
			return backpack_slot
		EquipmentSlotClass.SlotType.WEAPON:
			return weapon_slot
		EquipmentSlotClass.SlotType.PASSIVE_TOOL:
			return passive_tool_slot
		EquipmentSlotClass.SlotType.PRIMARY_TOOL:
			return primary_tool_slot
		EquipmentSlotClass.SlotType.SECONDARY_TOOL:
			return secondary_tool_slot
		_:
			pass

	if item_definition.is_backpack_item():
		return backpack_slot
	if item_definition.is_weapon_item():
		return weapon_slot
	if item_definition.is_passive_equipment_item():
		return passive_tool_slot
	if item_definition.is_tool_item():
		return primary_tool_slot

	return primary_tool_slot


func _get_slot(slot_type: int):
	match slot_type:
		EquipmentSlotClass.SlotType.BACKPACK:
			return backpack_slot
		EquipmentSlotClass.SlotType.PRIMARY_TOOL:
			return primary_tool_slot
		EquipmentSlotClass.SlotType.PASSIVE_TOOL:
			return passive_tool_slot
		EquipmentSlotClass.SlotType.SECONDARY_TOOL:
			return secondary_tool_slot
		EquipmentSlotClass.SlotType.WEAPON:
			return weapon_slot
		_:
			return null
