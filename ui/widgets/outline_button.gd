class_name OutlineButton
extends Button

@export var label_text: String = "":
	set(value):
		label_text = value
		text = value

@export var icon_texture: Texture2D:
	set(value):
		icon_texture = value
		icon = value


func _ready() -> void:
	text = label_text
	icon = icon_texture
