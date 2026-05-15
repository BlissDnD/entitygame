class_name ItemDatabase
extends Resource

@export var items: Array[ItemDefinition] = []

func build_registry() -> ItemRegistry:
	var registry := ItemRegistry.new()

	for item in items:
		if item == null:
			print("[ItemDatabase] null item")
			continue

		print("[ItemDatabase] register: ", item.id, " / ", item.resource_path)
		registry.register_item(item)

	print("[ItemDatabase] registered ids: ", registry.items_by_id.keys())

	return registry