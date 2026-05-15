class_name BackpackWorldItem
extends Node2D

@export var item_definition: ItemDefinition


func setup(next_item_definition: ItemDefinition) -> void:
	item_definition = next_item_definition


func overlaps_world_rect(world_rect: Rect2) -> bool:
	var interaction_rect: Rect2 = Rect2(global_position + Vector2(-18.0, -24.0), Vector2(36.0, 28.0))
	return interaction_rect.intersects(world_rect)


func can_interact(user: Node = null, interaction_context: InteractionContext = null) -> bool:
	if interaction_context == null:
		return false
	if not overlaps_world_rect(interaction_context.get_player_rect()):
		return false
	if interaction_context.player_equipment == null:
		return false
	return interaction_context.player_equipment.get_equipped_backpack() == null


func interact(user: Node = null, interaction_context: InteractionContext = null) -> bool:
	if not can_interact(user, interaction_context):
		return false
	if interaction_context.inventory_runtime == null:
		return false

	var did_equip: bool = interaction_context.inventory_runtime.equip_backpack_item(item_definition, "[Backpack]")
	if not did_equip:
		return false

	if interaction_context.item_interaction_controller != null:
		interaction_context.item_interaction_controller.unregister_backpack_world_item(self)
	if interaction_context.refresh_godmode_ui.is_valid():
		interaction_context.refresh_godmode_ui.call()
	queue_free()
	return true


func get_interaction_rect() -> Rect2:
	return Rect2(global_position + Vector2(-18.0, -24.0), Vector2(36.0, 28.0))
