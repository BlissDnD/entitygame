class_name BackpackWorldItem
extends Node2D

@export var item_definition: ItemDefinition


func setup(next_item_definition: ItemDefinition) -> void:
	item_definition = next_item_definition


func overlaps_world_rect(world_rect: Rect2) -> bool:
	var interaction_rect: Rect2 = Rect2(global_position + Vector2(-18.0, -24.0), Vector2(36.0, 28.0))
	return interaction_rect.intersects(world_rect)
