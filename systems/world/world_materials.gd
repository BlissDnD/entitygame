class_name WorldMaterials
extends RefCounted

const WorldConstantsClass = preload("res://systems/world/world_constants.gd")
const GameplayTuningClass = preload("res://systems/config/gameplay_tuning.gd")

const MATERIALS := {
	WorldConstantsClass.CellType.DIRT: {
		"display_name": "DIRT",
		"mining_resistance": GameplayTuningClass.DIRT_MINING_RESISTANCE,
		"inventory_weight": GameplayTuningClass.DIRT_INVENTORY_WEIGHT,
		"debug_color": GameplayTuningClass.DIRT_DEBUG_COLOR,
		"material_tags": ["solid", "dirt", "mineable"],
	},
	WorldConstantsClass.CellType.STONE: {
		"display_name": "STONE",
		"mining_resistance": GameplayTuningClass.STONE_MINING_RESISTANCE,
		"inventory_weight": GameplayTuningClass.STONE_INVENTORY_WEIGHT,
		"debug_color": GameplayTuningClass.STONE_DEBUG_COLOR,
		"material_tags": ["solid", "stone", "mineable"],
	},
}


static func get_material(cell_type: int) -> Dictionary:
	return MATERIALS.get(cell_type, {
		"display_name": "AIR",
		"mining_resistance": 0.0,
		"inventory_weight": 0.0,
		"debug_color": Color(0.07, 0.08, 0.1, 1.0),
	})


static func get_display_name(cell_type: int) -> String:
	var material: Dictionary = get_material(cell_type)
	return String(material.get("display_name", "AIR"))


static func get_mining_resistance(cell_type: int) -> float:
	var material: Dictionary = get_material(cell_type)
	return float(material.get("mining_resistance", 0.0))


static func get_debug_color(cell_type: int) -> Color:
	var material: Dictionary = get_material(cell_type)
	return material.get("debug_color", Color(0.07, 0.08, 0.1, 1.0)) as Color


static func get_inventory_weight(cell_type: int) -> float:
	var material: Dictionary = get_material(cell_type)
	return float(material.get("inventory_weight", 0.0))


static func get_material_tags(cell_type: int) -> PackedStringArray:
	var material: Dictionary = get_material(cell_type)
	return PackedStringArray(material.get("material_tags", []))


static func get_material_id_by_name(material_name: String) -> int:
	var normalized_name := material_name.strip_edges().to_upper()

	for material_id in MATERIALS.keys():
		if get_display_name(int(material_id)) == normalized_name:
			return int(material_id)

	return WorldConstantsClass.CellType.AIR


static func get_placeable_material_ids() -> Array[int]:
	var material_ids: Array[int] = []

	for material_id in MATERIALS.keys():
		var typed_material_id := int(material_id)
		if get_material_tags(typed_material_id).has("mineable"):
			material_ids.append(typed_material_id)

	return material_ids
