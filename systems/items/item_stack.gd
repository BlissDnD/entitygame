class_name ItemStack
extends Resource

@export var item_definition: ItemDefinition
@export var amount: int = 1


func is_empty() -> bool:
	return item_definition == null or amount <= 0


func get_total_weight() -> float:
	if item_definition == null:
		return 0.0

	return item_definition.weight * float(amount)
