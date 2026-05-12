class_name KeybindHintWidget
extends PanelContainer

const InputActionDisplayClass = preload("res://systems/ui/input_action_display.gd")

@export var action_name: StringName = &"":
	set(value):
		action_name = value
		refresh()

@export var label_text: String = "":
	set(value):
		label_text = value
		refresh()

@export var icon_texture: Texture2D:
	set(value):
		icon_texture = value
		if icon_rect != null:
			icon_rect.texture = value
			icon_rect.visible = value != null

@onready var key_label: Label = $HBoxContainer/key_label
@onready var text_label: Label = $HBoxContainer/text_label
@onready var icon_rect: TextureRect = $HBoxContainer/icon_rect


func _ready() -> void:
	refresh()


func refresh() -> void:
	if key_label == null or text_label == null:
		return

	key_label.text = InputActionDisplayClass.get_action_label(action_name)
	text_label.text = label_text
	if icon_rect != null:
		icon_rect.texture = icon_texture
		icon_rect.visible = icon_texture != null
