class_name ItemIconSlot
extends PanelContainer

@onready var icon_rect: TextureRect = $MarginContainer/Stack/icon_rect
@onready var fallback_label: Label = $MarginContainer/Stack/fallback_label


func _ready() -> void:
	set_item(null)


func set_item(item_definition: ItemDefinition) -> void:
	if icon_rect == null or fallback_label == null:
		return

	if item_definition == null:
		icon_rect.texture = null
		icon_rect.visible = false
		fallback_label.visible = true
		fallback_label.text = "-"
		return

	if item_definition.icon != null:
		icon_rect.texture = item_definition.icon
		icon_rect.visible = true
		fallback_label.visible = false
		return

	icon_rect.texture = null
	icon_rect.visible = false
	fallback_label.visible = true
	if not item_definition.display_name.is_empty():
		fallback_label.text = item_definition.display_name.left(3).to_upper()
	else:
		fallback_label.text = String(item_definition.id).left(3).to_upper()
