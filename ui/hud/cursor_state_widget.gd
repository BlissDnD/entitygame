class_name CursorStateWidget
extends PanelContainer

var cursor_controller: PlayerCursorController = null

@onready var cursor_label: Label = $HBoxContainer/cursor_label


func _ready() -> void:
	_set_cursor_text("HAND")


func bind_cursor_controller(next_cursor_controller: PlayerCursorController) -> void:
	if cursor_controller != null and cursor_controller.cursor_behavior_changed.is_connected(_on_cursor_behavior_changed):
		cursor_controller.cursor_behavior_changed.disconnect(_on_cursor_behavior_changed)

	cursor_controller = next_cursor_controller
	if cursor_controller != null:
		if not cursor_controller.cursor_behavior_changed.is_connected(_on_cursor_behavior_changed):
			cursor_controller.cursor_behavior_changed.connect(_on_cursor_behavior_changed)
		_set_cursor_text(cursor_controller.get_current_cursor_behavior_name())
	else:
		_set_cursor_text("HAND")


func _on_cursor_behavior_changed(_cursor_behavior) -> void:
	if cursor_controller == null:
		return
	_set_cursor_text(cursor_controller.get_current_cursor_behavior_name())


func _set_cursor_text(text: String) -> void:
	if cursor_label != null:
		cursor_label.text = text
