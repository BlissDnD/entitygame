class_name HUD
extends Control

@onready var equipment_hud: EquipmentHUD = $MarginContainer/HBoxContainer/EquipmentHUD
@onready var cursor_state_widget: CursorStateWidget = $MarginContainer/HBoxContainer/CursorStateWidget
@onready var time_label: Label = $MarginContainer/HBoxContainer/time_label
@onready var status_label: Label = $MarginContainer/HBoxContainer/status_label


func bind_equipment(player_equipment: PlayerEquipment) -> void:
	equipment_hud.bind_equipment(player_equipment)


func bind_cursor_controller(cursor_controller: PlayerCursorController) -> void:
	cursor_state_widget.bind_cursor_controller(cursor_controller)


func set_time_text(text: String) -> void:
	if time_label != null:
		time_label.text = text


func set_status_text(text: String) -> void:
	if status_label != null:
		status_label.text = text
