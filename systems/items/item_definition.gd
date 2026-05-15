class_name ItemDefinition
extends Resource

const ItemTypesClass = preload("res://systems/items/item_types.gd")
const CursorBehaviorDefinitionClass = preload("res://systems/cursor/cursor_behavior_definition.gd")
const EquipmentSlotClass = preload("res://systems/equipment/equipment_slot.gd")

enum WorldBehavior {
	INVENTORY_ONLY,
	DATA_DROP,
	SCENE_DROP,
	PLACED_OBJECT,
}

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var world_scene: PackedScene

@export_group("Type")
@export var item_category: ItemTypesClass.ItemCategory = ItemTypesClass.ItemCategory.MISC
@export var max_stack: int = 1
@export var weight: float = 0.0
@export var value: int = 0

@export_group("Capabilities")
@export var can_be_carried: bool = true
@export var can_be_placed: bool = false
@export var can_be_used: bool = false
@export var can_be_consumed: bool = false
@export var can_be_equipped: bool = false

@export_group("Specialization")
@export var is_tool: bool = false
@export var is_weapon: bool = false
@export var is_backpack: bool = false
@export var is_passive_equipment: bool = false

@export_group("World Behavior")
@export var can_exist_in_world: bool = true
@export var world_behavior: WorldBehavior = WorldBehavior.DATA_DROP
@export var is_world_interactable: bool = true
@export var world_interaction_conditions: Array[StringName] = []
@export var default_world_state: StringName = &"default"
@export var max_world_lifespan_seconds: float = -1.0

@export_group("World Phase References")
@export var placeable_definition: Resource
@export var dropped_world_scene: PackedScene

@export_group("System Links")
@export var equipment_slot_type: int = -1
@export var cursor_behavior: CursorBehaviorDefinition
@export var backpack_definition: Resource


func use_item(user: Node) -> void:
	if not can_be_used:
		return

	# TODO: Route to future item behavior resources/scripts.
	print("Use item placeholder: %s by %s" % [id, user])


func consume_item(user: Node) -> void:
	if not can_be_consumed:
		return

	# TODO: Route to future consumption/removal behavior.
	print("Consume item placeholder: %s by %s" % [id, user])


func get_dropped_world_scene() -> PackedScene:
	if dropped_world_scene != null:
		return dropped_world_scene
	return world_scene


func supports_world_drop() -> bool:
	return can_be_carried and can_exist_in_world and world_behavior != WorldBehavior.INVENTORY_ONLY


func uses_scene_world_drop() -> bool:
	return supports_world_drop() and world_behavior == WorldBehavior.SCENE_DROP and get_dropped_world_scene() != null


func uses_data_world_drop() -> bool:
	return supports_world_drop() and world_behavior == WorldBehavior.DATA_DROP


func is_placeable_item() -> bool:
	return can_be_placed and placeable_definition != null


func is_world_interactable_item() -> bool:
	return supports_world_drop() and is_world_interactable


func has_world_interaction_condition(condition_id: StringName) -> bool:
	return world_interaction_conditions.has(condition_id)


func get_default_world_state() -> StringName:
	return default_world_state


func get_max_world_lifespan_seconds() -> float:
	return max_world_lifespan_seconds


func allows_world_action(action_id: StringName, current_state: StringName = &"") -> bool:
	if not is_world_interactable_item():
		return false

	var resolved_state: StringName = current_state
	if resolved_state == &"":
		resolved_state = default_world_state
	if resolved_state == &"disabled" or resolved_state == &"destroyed":
		return false

	if world_interaction_conditions.is_empty():
		return true
	return world_interaction_conditions.has(action_id)


func get_equipment_slot_type() -> int:
	if equipment_slot_type >= 0:
		return equipment_slot_type
	if is_backpack:
		return EquipmentSlotClass.SlotType.BACKPACK
	if is_weapon:
		return EquipmentSlotClass.SlotType.WEAPON
	if is_passive_equipment:
		return EquipmentSlotClass.SlotType.PASSIVE_TOOL
	if is_tool:
		return EquipmentSlotClass.SlotType.PRIMARY_TOOL
	return -1


func is_backpack_item() -> bool:
	return get_equipment_slot_type() == EquipmentSlotClass.SlotType.BACKPACK


func is_tool_item() -> bool:
	return get_equipment_slot_type() == EquipmentSlotClass.SlotType.PRIMARY_TOOL


func is_passive_equipment_item() -> bool:
	return get_equipment_slot_type() == EquipmentSlotClass.SlotType.PASSIVE_TOOL


func is_weapon_item() -> bool:
	return get_equipment_slot_type() == EquipmentSlotClass.SlotType.WEAPON
