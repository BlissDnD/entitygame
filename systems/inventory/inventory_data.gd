class_name InventoryData
extends RefCounted

const WorldMaterialsClass = preload("res://systems/world/world_materials.gd")

var material_counts: Dictionary = {}
var max_capacity: int = 0
var max_weight_capacity: float = 0.0


func _init(capacity: int = 0, weight_capacity: float = 0.0) -> void:
	max_capacity = capacity
	max_weight_capacity = maxf(weight_capacity, 0.0)


func set_capacity(capacity: int) -> void:
	max_capacity = maxi(capacity, 0)


func set_weight_capacity(weight_capacity: float) -> void:
	max_weight_capacity = maxf(weight_capacity, 0.0)


func add_material(material_id: int, amount: int = 1) -> int:
	if amount <= 0:
		return 0

	var accepted_amount: int = mini(amount, get_remaining_capacity())
	accepted_amount = mini(accepted_amount, get_remaining_amount_for_material(material_id))
	if accepted_amount <= 0:
		return 0

	material_counts[material_id] = get_material_count(material_id) + accepted_amount
	return accepted_amount


func remove_material(material_id: int, amount: int = 1) -> int:
	if amount <= 0:
		return 0

	var removed_amount: int = mini(amount, get_material_count(material_id))
	if removed_amount <= 0:
		return 0

	var next_amount: int = get_material_count(material_id) - removed_amount
	if next_amount <= 0:
		material_counts.erase(material_id)
	else:
		material_counts[material_id] = next_amount

	return removed_amount


func has_material(material_id: int, amount: int = 1) -> bool:
	return get_material_count(material_id) >= amount


func get_material_count(material_id: int) -> int:
	return int(material_counts.get(material_id, 0))


func get_total_count() -> int:
	var total_count: int = 0

	for count in material_counts.values():
		total_count += int(count)

	return total_count


func get_remaining_capacity() -> int:
	return maxi(max_capacity - get_total_count(), 0)


func get_total_weight() -> float:
	var total_weight: float = 0.0

	for material_id in material_counts.keys():
		var typed_material_id: int = int(material_id)
		total_weight += float(get_material_count(typed_material_id)) * WorldMaterialsClass.get_inventory_weight(typed_material_id)

	return total_weight


func get_remaining_weight_capacity() -> float:
	return maxf(max_weight_capacity - get_total_weight(), 0.0)


func get_remaining_amount_for_material(material_id: int) -> int:
	var material_weight: float = WorldMaterialsClass.get_inventory_weight(material_id)
	if material_weight <= 0.0:
		return get_remaining_capacity()

	return int(floor(get_remaining_weight_capacity() / material_weight))


func is_full() -> bool:
	return get_total_count() >= max_capacity or get_remaining_weight_capacity() <= 0.0


func get_material_ids() -> Array[int]:
	var material_ids: Array[int] = []

	for material_id in material_counts.keys():
		material_ids.append(int(material_id))

	return material_ids


func clear() -> void:
	material_counts.clear()
