class_name BackpackContainer
extends Node

signal backpack_equipped(backpack_definition)
signal backpack_unequipped

var backpack_definition: BackpackDefinition = null
var item_stacks: Array[ItemStack] = []


func equip_backpack(next_backpack_definition: BackpackDefinition) -> void:
	backpack_definition = next_backpack_definition
	item_stacks.clear()
	print("Backpack container equipped: %s" % [backpack_definition.id])
	backpack_equipped.emit(backpack_definition)


func unequip_backpack() -> BackpackDefinition:
	var previous_backpack_definition: BackpackDefinition = backpack_definition
	backpack_definition = null
	item_stacks.clear()
	print("Backpack container unequipped")
	backpack_unequipped.emit()
	return previous_backpack_definition


func can_store_item(item_definition: ItemDefinition) -> bool:
	return can_store_item_amount(item_definition, 1)


func can_store_item_amount(item_definition: ItemDefinition, amount: int = 1) -> bool:
	if backpack_definition == null:
		return false
	if item_definition == null:
		return false
	if item_stacks.size() >= backpack_definition.capacity_slots:
		return false
	if _get_total_weight() + (item_definition.weight * float(amount)) > backpack_definition.max_weight:
		return false
	if backpack_definition.allowed_item_categories.is_empty():
		return true

	return backpack_definition.allowed_item_categories.has(item_definition.item_category)


func add_placeholder_stack(item_definition: ItemDefinition, amount: int = 1) -> bool:
	if item_definition == null:
		print("Backpack add failed: null")
		return false
	if not can_store_item_amount(item_definition, amount):
		print("Backpack add failed: %s" % [item_definition.id])
		return false

	var item_stack = ItemStack.new()
	item_stack.item_definition = item_definition
	item_stack.amount = amount
	item_stacks.append(item_stack)
	print("Backpack stored placeholder stack: %s x%d" % [item_definition.id, amount])
	return true


func _get_total_weight() -> float:
	var total_weight: float = 0.0
	for item_stack in item_stacks:
		total_weight += item_stack.get_total_weight()

	return total_weight
