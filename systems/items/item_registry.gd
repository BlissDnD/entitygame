class_name ItemRegistry
extends RefCounted

var items_by_id: Dictionary = {}


func register_item(item_definition: ItemDefinition) -> void:
	if item_definition == null:
		return
	if item_definition.id == &"":
		push_warning("Cannot register item without id")
		return

	items_by_id[item_definition.id] = item_definition


func get_item(item_id: StringName) -> ItemDefinition:
	return items_by_id.get(item_id, null)


func has_item(item_id: StringName) -> bool:
	return items_by_id.has(item_id)


func get_all_items() -> Array:
	return items_by_id.values()