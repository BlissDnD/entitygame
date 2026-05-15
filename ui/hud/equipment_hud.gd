class_name EquipmentHUD
extends PanelContainer

const EquipmentSlotClass = preload("res://systems/equipment/equipment_slot.gd")

var player_equipment: PlayerEquipment = null

@onready var backpack_slot: ItemIconSlot = $HBoxContainer/backpack_slot
@onready var primary_tool_slot: ItemIconSlot = $HBoxContainer/primary_tool_slot
@onready var passive_tool_slot: ItemIconSlot = $HBoxContainer/passive_tool_slot
@onready var weapon_slot: ItemIconSlot = $HBoxContainer/weapon_slot


func _ready() -> void:
	_refresh_slots()


func bind_equipment(next_player_equipment: PlayerEquipment) -> void:
	if player_equipment != null and player_equipment.equipped_item_changed.is_connected(_on_equipped_item_changed):
		player_equipment.equipped_item_changed.disconnect(_on_equipped_item_changed)

	player_equipment = next_player_equipment
	if player_equipment != null and not player_equipment.equipped_item_changed.is_connected(_on_equipped_item_changed):
		player_equipment.equipped_item_changed.connect(_on_equipped_item_changed)

	_refresh_slots()


func _on_equipped_item_changed(_slot_type, _item_definition) -> void:
	_refresh_slots()


func _refresh_slots() -> void:
	if backpack_slot == null:
		return
	if player_equipment == null:
		backpack_slot.set_item(null)
		primary_tool_slot.set_item(null)
		passive_tool_slot.set_item(null)
		weapon_slot.set_item(null)
		return

	backpack_slot.set_item(player_equipment.get_equipped_backpack())
	primary_tool_slot.set_item(player_equipment.get_equipped_tool())
	passive_tool_slot.set_item(player_equipment.get_equipped_passive_item())
	weapon_slot.set_item(player_equipment.weapon_slot.item_definition)
