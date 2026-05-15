class_name ItemPickup
extends Area2D

signal picked_up(item_definition: ItemDefinition, picker: Node)

@export var item_definition: ItemDefinition:
	set(value):
		item_definition = value
		_refresh_visual()

@export var amount: int = 1

@onready var icon_rect: Sprite2D = $Icon
@onready var fallback_label: Label = $Label


func _ready() -> void:
	_refresh_visual()


func can_interact(user: Node = null, interaction_context: InteractionContext = null) -> bool:
	if interaction_context == null:
		return false
	return get_interaction_rect().intersects(interaction_context.get_player_rect())


func interact(user: Node = null, interaction_context: InteractionContext = null) -> void:
	picked_up.emit(item_definition, user)
	queue_free()


func get_interaction_rect() -> Rect2:
	return Rect2(global_position - Vector2(12.0, 12.0), Vector2(24.0, 24.0))


func _refresh_visual() -> void:
	if icon_rect == null or fallback_label == null:
		return

	if item_definition == null:
		icon_rect.texture = null
		fallback_label.text = "?"
		return

	if item_definition.icon != null:
		icon_rect.texture = item_definition.icon
		fallback_label.text = ""
		return

	icon_rect.texture = null
	if not item_definition.display_name.is_empty():
		fallback_label.text = item_definition.display_name.left(3).to_upper()
	else:
		fallback_label.text = String(item_definition.id).left(3).to_upper()
