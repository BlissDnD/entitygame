class_name InventoryComponent
extends Node

signal inventory_changed
signal material_added(material_id: int, amount: int)
signal material_removed(material_id: int, amount: int)

const InventoryDataClass = preload("res://systems/inventory/inventory_data.gd")
const GameplayTuningClass = preload("res://systems/config/gameplay_tuning.gd")

@export var max_capacity: int = GameplayTuningClass.INVENTORY_CAPACITY:
	set(value):
		max_capacity = maxi(value, 0)
		if inventory_data != null:
			inventory_data.set_capacity(max_capacity)

@export var max_weight_capacity: float = GameplayTuningClass.INVENTORY_WEIGHT_CAPACITY:
	set(value):
		max_weight_capacity = maxf(value, 0.0)
		if inventory_data != null:
			inventory_data.set_weight_capacity(max_weight_capacity)

var inventory_data: InventoryData = InventoryDataClass.new(max_capacity, max_weight_capacity)


func _ready() -> void:
	inventory_data.set_capacity(max_capacity)
	inventory_data.set_weight_capacity(max_weight_capacity)


func add_material(material_id: int, amount: int = 1) -> int:
	var accepted_amount: int = inventory_data.add_material(material_id, amount)
	if accepted_amount > 0:
		material_added.emit(material_id, accepted_amount)
		inventory_changed.emit()
	return accepted_amount


func remove_material(material_id: int, amount: int = 1) -> int:
	var removed_amount: int = inventory_data.remove_material(material_id, amount)
	if removed_amount > 0:
		material_removed.emit(material_id, removed_amount)
		inventory_changed.emit()
	return removed_amount


func has_material(material_id: int, amount: int = 1) -> bool:
	return inventory_data.has_material(material_id, amount)


func get_inventory_data() -> InventoryData:
	return inventory_data
