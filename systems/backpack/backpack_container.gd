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
	return get_accepted_item_amount(item_definition, amount) >= amount


func get_accepted_item_amount(item_definition: ItemDefinition, amount: int = 1) -> int:
	if backpack_definition == null:
		return 0
	if item_definition == null:
		return 0
	if amount <= 0:
		return 0
	if backpack_definition.allowed_item_categories.is_empty():
		return _get_capacity_limited_amount(item_definition, amount)
	if not backpack_definition.allowed_item_categories.has(item_definition.item_category):
		return 0

	return _get_capacity_limited_amount(item_definition, amount)


func add_placeholder_stack_amount(item_definition: ItemDefinition, amount: int = 1) -> int:
	if item_definition == null:
		print("Backpack add failed: null")
		return 0

	var accepted_amount: int = get_accepted_item_amount(item_definition, amount)
	if accepted_amount <= 0:
		print("Backpack add failed: %s" % [item_definition.id])
		return 0

	var remaining_amount: int = accepted_amount
	var max_stack_size: int = maxi(item_definition.max_stack, 1)

	for item_stack in item_stacks:
		if remaining_amount <= 0:
			break
		if item_stack.item_definition != item_definition:
			continue
		var available_space: int = maxi(max_stack_size - item_stack.amount, 0)
		if available_space <= 0:
			continue
		var stack_added_amount: int = mini(remaining_amount, available_space)
		item_stack.amount += stack_added_amount
		remaining_amount -= stack_added_amount

	while remaining_amount > 0 and item_stacks.size() < backpack_definition.capacity_slots:
		var next_stack_amount: int = mini(remaining_amount, max_stack_size)
		var item_stack = ItemStack.new()
		item_stack.item_definition = item_definition
		item_stack.amount = next_stack_amount
		item_stacks.append(item_stack)
		remaining_amount -= next_stack_amount

	print("Backpack stored placeholder stack: %s x%d" % [item_definition.id, accepted_amount])
	return accepted_amount


func add_placeholder_stack(item_definition: ItemDefinition, amount: int = 1) -> bool:
	return add_placeholder_stack_amount(item_definition, amount) >= amount


func _get_capacity_limited_amount(item_definition: ItemDefinition, requested_amount: int) -> int:
	var weight_limited_amount: int = requested_amount
	if item_definition.weight > 0.0:
		weight_limited_amount = int(floor((backpack_definition.max_weight - _get_total_weight()) / item_definition.weight))
	weight_limited_amount = maxi(weight_limited_amount, 0)

	var stack_limited_amount: int = _get_stack_limited_amount(item_definition)
	return mini(requested_amount, mini(weight_limited_amount, stack_limited_amount))

	
func _get_stack_limited_amount(item_definition: ItemDefinition) -> int:
	var max_stack_size: int = maxi(item_definition.max_stack, 1)
	var available_amount: int = 0

	for item_stack in item_stacks:
		if item_stack.item_definition != item_definition:
			continue
		available_amount += maxi(max_stack_size - item_stack.amount, 0)

	var free_slots: int = maxi(backpack_definition.capacity_slots - item_stacks.size(), 0)
	available_amount += free_slots * max_stack_size
	return available_amount


func _get_total_weight() -> float:
	var total_weight: float = 0.0
	for item_stack in item_stacks:
		total_weight += item_stack.get_total_weight()

	return total_weight
