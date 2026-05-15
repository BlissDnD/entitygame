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
	if not item_definition.is_backpack_item() or not item_definition.can_be_equipped:
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
	var amount: int = int(drop_entry.get("amount", 0))
	var accepted_amount: int = 0
	if item_kind == "material":
		var item_id: int = int(drop_entry.get("item_id", WorldConstantsClass.CellType.AIR))
		accepted_amount = inventory_data.add_material(item_id, amount)
	elif item_kind == "item":
		var item_definition: ItemDefinition = drop_entry.get("item_definition", null)
		var current_state: StringName = StringName(drop_entry.get("world_state", &""))
		if item_definition == null or not item_definition.allows_world_action(&"pickup", current_state):
			return false
		accepted_amount = add_backpack_stack_amount(item_definition, amount)

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
	if item_kind == "material":
		var item_id: int = int(drop_entry.get("item_id", WorldConstantsClass.CellType.AIR))
		return WorldMaterialsClass.get_display_name(item_id)
	if item_kind == "item":
		var item_definition: ItemDefinition = drop_entry.get("item_definition", null)
		if item_definition != null and not item_definition.display_name.is_empty():
			return item_definition.display_name
		if item_definition != null:
			return String(item_definition.id)

	return "ITEM"


func get_drop_item_color(drop_entry: Dictionary) -> Color:
	var item_kind: String = String(drop_entry.get("item_kind", ""))
	if item_kind == "material":
		var item_id: int = int(drop_entry.get("item_id", WorldConstantsClass.CellType.AIR))
		return WorldMaterialsClass.get_debug_color(item_id)
	if item_kind == "item":
		var item_definition: ItemDefinition = drop_entry.get("item_definition", null)
		if item_definition != null and item_definition.item_category == 0:
			return Color(0.64, 0.46, 0.24, 1.0)
		if item_definition != null and item_definition.get_equipment_slot_type() >= 0:
			return Color(0.9, 0.82, 0.32, 1.0)
		return Color(0.85, 0.85, 0.88, 1.0)

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


func add_backpack_stack_amount(item_definition: ItemDefinition, amount: int) -> int:
	if backpack_container.backpack_definition == null:
		print("[GodModeItems] Cannot add stack: no backpack equipped")
		return 0
	var accepted_amount: int = backpack_container.add_placeholder_stack_amount(item_definition, amount)
	if accepted_amount > 0:
		print("[GodModeItems] Added stack: %s x%d" % [item_definition.id, accepted_amount])
	return accepted_amount


func add_backpack_stack(item_definition: ItemDefinition, amount: int) -> bool:
	return add_backpack_stack_amount(item_definition, amount) >= amount


func print_equipment_state(cursor_behavior_name: String) -> void:
	var equipped_tool: ItemDefinition = player_equipment.get_equipped_tool()
	var equipped_backpack: ItemDefinition = player_equipment.get_equipped_backpack()
	var equipped_passive_item: ItemDefinition = player_equipment.get_equipped_passive_item()
	print("[GodModeItems] Equipment state:")
	print("  tool: %s" % [equipped_tool.id if equipped_tool != null else "empty"])
	print("  passive: %s" % [equipped_passive_item.id if equipped_passive_item != null else "empty"])
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
