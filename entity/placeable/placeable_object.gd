class_name PlaceableObject
extends Node2D

const WorldConstantsClass = preload("res://systems/world/world_constants.gd")

@export var definition: PlaceableObjectDefinition
@export var has_collision: bool = false

@onready var debug_label: Label = $DebugLabel


func _ready() -> void:
	if definition != null:
		setup_from_definition(definition)
	else:
		_apply_collision_state()


func setup_from_definition(new_definition: PlaceableObjectDefinition) -> void:
	definition = new_definition
	has_collision = definition.has_collision
	if debug_label != null:
		debug_label.text = definition.display_name
	_apply_collision_state()


func _apply_collision_state() -> void:
	_apply_collision_state_recursive(self)


func _apply_collision_state_recursive(node: Node) -> void:
	if node is CollisionShape2D:
		var collision_shape: CollisionShape2D = node
		collision_shape.disabled = not has_collision
	if node is CollisionPolygon2D:
		var collision_polygon: CollisionPolygon2D = node
		collision_polygon.disabled = not has_collision

	for child in node.get_children():
		_apply_collision_state_recursive(child)


func can_interact(user: Node = null, interaction_context: InteractionContext = null) -> bool:
	if definition == null or interaction_context == null:
		return false
	if not definition.interaction_enabled:
		return false
	if not visible:
		return false
	if not get_interaction_rect().has_point(interaction_context.mouse_world_position):
		return false
	if not get_interaction_rect().intersects(interaction_context.get_player_rect()):
		return false
	if not _has_required_passive_items(interaction_context.player_equipment):
		return false
	return true


func interact(user: Node = null, interaction_context: InteractionContext = null) -> bool:
	if not can_interact(user, interaction_context):
		return false

	if definition.interaction_yield_item != null and interaction_context.inventory_runtime != null:
		var yield_amount: int = maxi(definition.interaction_yield_amount, 1)
		var accepted_amount: int = interaction_context.inventory_runtime.add_backpack_stack_amount(
			definition.interaction_yield_item,
			yield_amount
		)
		var remaining_amount: int = yield_amount - accepted_amount
		if remaining_amount > 0 and interaction_context.item_interaction_controller != null and interaction_context.item_interaction_controller.item_drop_data != null:
			interaction_context.item_interaction_controller.item_drop_data.add_item_definition_stack(
				global_position,
				definition.interaction_yield_item,
				remaining_amount,
				18.0
			)
			print("[Interact] %s dropped %s x%d on the floor" % [
				definition.display_name if definition != null else name,
				definition.interaction_yield_item.id,
				remaining_amount
			])
		if interaction_context.refresh_godmode_ui.is_valid():
			interaction_context.refresh_godmode_ui.call()

	print("[Interact] %s used" % [definition.display_name if definition != null else name])
	if definition.interaction_consumes_object:
		if interaction_context.interaction_registry != null:
			interaction_context.interaction_registry.unregister_interactable(self)
		queue_free()
	return true


func get_interaction_rect() -> Rect2:
	if definition == null:
		return Rect2(global_position - Vector2(8.0, 8.0), Vector2(16.0, 16.0))

	var footprint_world_size: Vector2 = Vector2(
		float(definition.footprint_tiles.x * WorldConstantsClass.CELL_SIZE.x),
		float(definition.footprint_tiles.y * WorldConstantsClass.CELL_SIZE.y)
	)
	return Rect2(
		global_position - Vector2(footprint_world_size.x * 0.5, footprint_world_size.y),
		footprint_world_size
	)


func _has_required_passive_items(player_equipment: PlayerEquipment) -> bool:
	if definition == null or definition.required_passive_item_ids.is_empty():
		return true
	if player_equipment == null:
		return false
	var equipped_passive_item: ItemDefinition = player_equipment.get_equipped_passive_item()
	if equipped_passive_item == null:
		return false
	return definition.required_passive_item_ids.has(equipped_passive_item.id)
