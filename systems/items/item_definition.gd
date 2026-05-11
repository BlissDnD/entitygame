class_name ItemDefinition
extends Resource

const ItemTypesClass = preload("res://systems/items/item_types.gd")
const CursorBehaviorDefinitionClass = preload("res://systems/cursor/cursor_behavior_definition.gd")

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var world_scene: PackedScene
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

@export_group("Optional References")
@export var placeable_definition: Resource
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
