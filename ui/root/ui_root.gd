class_name UIRoot
extends CanvasLayer

var registered_widgets: Dictionary = {}

@onready var hud_layer: Control = $HUDLayer
@onready var overlay_layer: Control = $OverlayLayer
@onready var menu_layer: Control = $MenuLayer
@onready var tooltip_layer: Control = $TooltipLayer
@onready var debug_layer: Control = $DebugLayer
@onready var hud = $HUDLayer/HUD


func _ready() -> void:
	register_widget(&"hud", hud)


func show_hud() -> void:
	set_hud_visible(true)


func hide_hud() -> void:
	set_hud_visible(false)


func set_hud_visible(value: bool) -> void:
	hud_layer.visible = value


func register_widget(widget_id: StringName, widget: Control) -> void:
	if widget == null:
		return
	registered_widgets[widget_id] = widget


func get_widget(widget_id: StringName) -> Control:
	return registered_widgets.get(widget_id, null)


func bind_equipment(player_equipment: PlayerEquipment) -> void:
	_forward_binding("bind_equipment", player_equipment)


func bind_cursor_controller(cursor_controller: PlayerCursorController) -> void:
	_forward_binding("bind_cursor_controller", cursor_controller)


func set_time_text(text: String) -> void:
	if hud != null and hud.has_method("set_time_text"):
		hud.set_time_text(text)


func set_status_text(text: String) -> void:
	if hud != null and hud.has_method("set_status_text"):
		hud.set_status_text(text)


func _forward_binding(method_name: StringName, value) -> void:
	for widget in registered_widgets.values():
		if widget != null and widget.has_method(method_name):
			widget.call(method_name, value)
	_forward_binding_recursive(hud_layer, method_name, value)
	_forward_binding_recursive(overlay_layer, method_name, value)
	_forward_binding_recursive(menu_layer, method_name, value)
	_forward_binding_recursive(tooltip_layer, method_name, value)
	_forward_binding_recursive(debug_layer, method_name, value)


func _forward_binding_recursive(node: Node, method_name: StringName, value) -> void:
	for child in node.get_children():
		if child.has_method(method_name):
			child.call(method_name, value)
		_forward_binding_recursive(child, method_name, value)
