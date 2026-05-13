class_name InventoryRuntime
extends RefCounted

const GameplayTuningClass = preload("res://systems/config/gameplay_tuning.gd")
const WorldConstantsClass = preload("res://systems/world/world_constants.gd")
const WorldMaterialsClass = preload("res://systems/world/world_materials.gd")
const EquipmentSlotClass = preload("res://systems/equipment/equipment_slot.gd")

var inventory_data: InventoryData = null
var player_equipment: PlayerEquipment = null
var backpack_container: BackpackContainer = null
var selected_material_id: int = GameplayTuningClass.DEFAULT_SELECTED_MATERIAL


func _init(
	next_inventory_data: InventoryData = null,
	next_player_equipment: PlayerEquipment = null,
	next_backpack_container: BackpackContainer = null
) -> void:
	inventory_data = next_inventory_data
	player_equipment = next_player_equipment
	backpack_container = next_backpack_container


func equip_backpack_item(item_definition: ItemDefinition, log_prefix: String) -> bool:
	if item_definition == null:
		return false
	if not item_definition.is_backpack or not item_definition.can_be_equipped:
		return false
	if player_equipment.get_equipped_backpack() != null:
		print("%s Cannot equip backpack: backpack slot already occupied" % [log_prefix])
		return false
	if not player_equipment.equip_item(item_definition):
		return false

	if item_definition.backpack_definition is BackpackDefinition:
		backpack_container.equip_backpack(item_definition.backpack_definition)
	print("%s Backpack equipped: %s" % [log_prefix, item_definition.id])
	return true


func unequip_backpack_for_drop() -> ItemDefinition:
	var equipped_backpack: ItemDefinition = player_equipment.get_equipped_backpack()
	if equipped_backpack == null:
		print("[Backpack] No backpack equipped")
		return null

	player_equipment.unequip_item(EquipmentSlotClass.SlotType.BACKPACK)
	# TODO: Transfer BackpackContainer contents into dropped world item data once item containers persist.
	backpack_container.unequip_backpack()
	return equipped_backpack


func try_pick_up_drop(item_drop_data, drop_index: int) -> bool:
	if drop_index < 0:
		return false

	var drop_entry: Dictionary = item_drop_data.get_drop_at_index(drop_index)
	var item_kind: String = String(drop_entry.get("item_kind", ""))
	var item_id: int = int(drop_entry.get("item_id", WorldConstantsClass.CellType.AIR))
	var amount: int = int(drop_entry.get("amount", 0))
	var accepted_amount: int = 0
	if item_kind == "material":
		accepted_amount = inventory_data.add_material(item_id, amount)

	if accepted_amount <= 0:
		return false

	item_drop_data.remove_amount_at_index(drop_index, accepted_amount)
	return true


func cycle_selected_material(direction: int) -> bool:
	var material_ids: Array[int] = WorldMaterialsClass.get_placeable_material_ids()
	if material_ids.is_empty():
		return false

	var current_index: int = material_ids.find(selected_material_id)
	if current_index == -1:
		selected_material_id = material_ids[0]
		return true

	var next_index: int = posmod(current_index + direction, material_ids.size())
	selected_material_id = material_ids[next_index]
	return true


func get_selected_material_color() -> Color:
	return WorldMaterialsClass.get_debug_color(selected_material_id)


func get_drop_item_name(drop_entry: Dictionary) -> String:
	var item_kind: String = String(drop_entry.get("item_kind", ""))
	var item_id: int = int(drop_entry.get("item_id", WorldConstantsClass.CellType.AIR))
	if item_kind == "material":
		return WorldMaterialsClass.get_display_name(item_id)

	return "ITEM"


func get_drop_item_color(drop_entry: Dictionary) -> Color:
	var item_kind: String = String(drop_entry.get("item_kind", ""))
	var item_id: int = int(drop_entry.get("item_id", WorldConstantsClass.CellType.AIR))
	if item_kind == "material":
		return WorldMaterialsClass.get_debug_color(item_id)

	return Color(1.0, 1.0, 1.0, 1.0)


func get_dominant_inventory_color() -> Color:
	var material_ids: Array[int] = inventory_data.get_material_ids()
	if material_ids.is_empty():
		return GameplayTuningClass.DIRT_DEBUG_COLOR

	var dominant_material_id: int = selected_material_id
	var dominant_count: int = -1
	var blended_color: Color = Color(0.0, 0.0, 0.0, 0.0)
	var total_count: int = 0

	for material_id in material_ids:
		var material_count: int = inventory_data.get_material_count(material_id)
		total_count += material_count
		if material_count > dominant_count:
			dominant_count = material_count
			dominant_material_id = material_id

	if total_count <= 0:
		return WorldMaterialsClass.get_debug_color(dominant_material_id)

	for material_id in material_ids:
		var material_count: int = inventory_data.get_material_count(material_id)
		var weight: float = float(material_count) / float(total_count)
		var material_color: Color = WorldMaterialsClass.get_debug_color(material_id)
		blended_color.r += material_color.r * weight
		blended_color.g += material_color.g * weight
		blended_color.b += material_color.b * weight
		blended_color.a = 1.0

	return blended_color


func set_inventory_capacity(capacity: int) -> void:
	inventory_data.set_capacity(clampi(capacity, GameplayTuningClass.INVENTORY_CAPACITY_MIN, GameplayTuningClass.INVENTORY_CAPACITY_MAX))


func set_inventory_weight_capacity(weight_capacity: float) -> void:
	inventory_data.set_weight_capacity(clampf(weight_capacity, GameplayTuningClass.INVENTORY_WEIGHT_CAPACITY_MIN, GameplayTuningClass.INVENTORY_WEIGHT_CAPACITY_MAX))


func add_backpack_stack(item_definition: ItemDefinition, amount: int) -> void:
	if backpack_container.backpack_definition == null:
		print("[GodModeItems] Cannot add stack: no backpack equipped")
		return
	if backpack_container.add_placeholder_stack(item_definition, amount):
		print("[GodModeItems] Added stack: %s x%d" % [item_definition.id, amount])


func print_equipment_state(cursor_behavior_name: String) -> void:
	var equipped_tool: ItemDefinition = player_equipment.get_equipped_tool()
	var equipped_backpack: ItemDefinition = player_equipment.get_equipped_backpack()
	print("[GodModeItems] Equipment state:")
	print("  tool: %s" % [equipped_tool.id if equipped_tool != null else "empty"])
	print("  backpack: %s" % [equipped_backpack.id if equipped_backpack != null else "empty"])
	print("  cursor: %s" % [cursor_behavior_name])


func print_backpack_contents() -> void:
	if backpack_container.backpack_definition == null:
		print("[GodModeItems] Backpack contents: no backpack equipped")
		return

	print("[GodModeItems] Backpack contents:")
	if backpack_container.item_stacks.is_empty():
		print("  empty")
		return

	for item_stack in backpack_container.item_stacks:
		print("  %s x%d" % [item_stack.item_definition.id, item_stack.amount])
