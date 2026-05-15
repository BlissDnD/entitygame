class_name ItemDatabase
extends Resource

@export var items: Array[ItemDefinition] = []


func build_registry() -> ItemRegistry:
	var registry := ItemRegistry.new()

	for item in items:
		registry.register_item(item)

	return registry